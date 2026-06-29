#![allow(unused_imports, dead_code)]

//! Event-driven file system watcher using the `notify` crate.
//!
//! Replaces the previous polling-based watcher with OS-native file events
//! (inotify on Linux, FSEvents on macOS, ReadDirectoryChangesW on Windows).

use crate::error::CoreError;
use crossbeam_channel::{bounded, Receiver, Sender};
use notify::{
    Config as NotifyConfig, Event, EventKind, RecommendedWatcher, RecursiveMode, Watcher,
};
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use std::thread;
use tracing::{debug, error, info, warn};

/// Events emitted by the file monitor.
#[derive(Debug, Clone)]
pub enum FileEvent {
    /// A new file was created or appeared in a watched directory.
    Created(PathBuf),
    /// An existing file was modified.
    Modified(PathBuf),
    /// A file was removed.
    Removed(PathBuf),
    /// A file was renamed. (from, to)
    Renamed(PathBuf, PathBuf),
}

/// OS-native file system monitor.
///
/// Uses the `notify` crate for efficient, cross-platform event delivery.
pub struct FileMonitor {
    watcher: Option<RecommendedWatcher>,
    sender: Sender<FileEvent>,
    receiver: Arc<Mutex<Receiver<FileEvent>>>,
    watched_dirs: Vec<PathBuf>,
}

impl FileMonitor {
    /// Create a new file monitor. Events are delivered via the returned receiver.
    pub fn new() -> Result<(Self, Receiver<FileEvent>), CoreError> {
        let (tx, rx) = bounded::<FileEvent>(1024);
        let rx_clone = rx.clone();
        let monitor = FileMonitor {
            watcher: None,
            sender: tx,
            receiver: Arc::new(Mutex::new(rx)),
            watched_dirs: Vec::new(),
        };
        Ok((monitor, rx_clone))
    }

    /// Start watching a directory recursively.
    pub fn watch_dir<P: AsRef<Path>>(&mut self, dir: P) -> Result<(), CoreError> {
        let path = dir.as_ref().to_path_buf();

        if !path.exists() {
            return Err(CoreError::Io(std::io::Error::new(
                std::io::ErrorKind::NotFound,
                format!("Directory not found: {}", path.display()),
            )));
        }

        let tx = self.sender.clone();

        // Build the watcher on first call
        if self.watcher.is_none() {
            let watcher = RecommendedWatcher::new(
                move |res: notify::Result<Event>| match res {
                    Ok(event) => {
                        let fe = Self::map_event(event);
                        for e in fe {
                            if tx.send(e).is_err() {
                                error!("FileMonitor channel closed");
                            }
                        }
                    }
                    Err(e) => warn!(error = %e, "Watch error"),
                },
                NotifyConfig::default(),
            )
            .map_err(|e| CoreError::Internal(e.to_string()))?;
            self.watcher = Some(watcher);
        }

        if let Some(watcher) = self.watcher.as_mut() {
            watcher
                .watch(&path, RecursiveMode::Recursive)
                .map_err(|e| CoreError::Internal(e.to_string()))?;
        }

        info!(dir = %path.display(), "Started watching directory");
        self.watched_dirs.push(path);
        Ok(())
    }

    /// Stop watching a directory.
    pub fn unwatch_dir<P: AsRef<Path>>(&mut self, dir: P) -> Result<(), CoreError> {
        let path = dir.as_ref();
        if let Some(watcher) = self.watcher.as_mut() {
            watcher
                .unwatch(path)
                .map_err(|e| CoreError::Internal(e.to_string()))?;
        }
        self.watched_dirs.retain(|d| d != path);
        Ok(())
    }

    /// Returns the list of currently watched directories.
    pub fn watched_dirs(&self) -> &[PathBuf] {
        &self.watched_dirs
    }

    /// Map a `notify::Event` to zero or more `FileEvent`s.
    fn map_event(event: Event) -> Vec<FileEvent> {
        match event.kind {
            EventKind::Create(_) => event.paths.into_iter().map(FileEvent::Created).collect(),
            EventKind::Modify(_) => event.paths.into_iter().map(FileEvent::Modified).collect(),
            EventKind::Remove(_) => event.paths.into_iter().map(FileEvent::Removed).collect(),
            EventKind::Access(_) => vec![],
            EventKind::Any | EventKind::Other => {
                // Could be a rename — emit Modified for each path
                event.paths.into_iter().map(FileEvent::Modified).collect()
            }
        }
    }
}

impl Default for FileMonitor {
    fn default() -> Self {
        let (tx, rx) = bounded(1024);
        FileMonitor {
            watcher: None,
            sender: tx,
            receiver: Arc::new(Mutex::new(rx)),
            watched_dirs: Vec::new(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use tempfile::TempDir;

    #[test]
    fn test_monitor_creation() {
        let result = FileMonitor::new();
        assert!(result.is_ok());
    }

    #[test]
    fn test_watch_nonexistent_dir() {
        let (mut monitor, _rx) = FileMonitor::new().unwrap();
        let result = monitor.watch_dir("/nonexistent/path/that/does/not/exist");
        assert!(result.is_err());
    }

    #[test]
    fn test_watch_existing_dir() {
        let tmp = TempDir::new().unwrap();
        let (mut monitor, _rx) = FileMonitor::new().unwrap();
        let result = monitor.watch_dir(tmp.path());
        assert!(result.is_ok());
        assert_eq!(monitor.watched_dirs().len(), 1);
    }

    #[test]
    fn test_map_event_create() {
        use notify::{event::CreateKind, EventKind};
        let event = Event {
            kind: EventKind::Create(CreateKind::File),
            paths: vec![PathBuf::from("/tmp/test.txt")],
            attrs: Default::default(),
        };
        let mapped = FileMonitor::map_event(event);
        assert_eq!(mapped.len(), 1);
        assert!(matches!(mapped[0], FileEvent::Created(_)));
    }
}
