//! File system monitoring using platform-native watchers.

use crate::error::CoreError;
use crate::models::{FileEntry, FileType};
use std::path::Path;
use std::sync::mpsc::{channel, Receiver, Sender};
use std::thread;
use std::time::Duration;
use tracing::{debug, error, info, warn};

/// An event emitted by the file monitor.
#[derive(Debug, Clone)]
pub enum FileEvent {
    Created(String),
    Modified(String),
    Deleted(String),
    Renamed { from: String, to: String },
}

/// Configuration for the file monitor.
pub struct MonitorConfig {
    pub watch_dirs: Vec<String>,
    pub poll_interval_ms: u64,
    pub extensions_filter: Vec<String>,
}

impl Default for MonitorConfig {
    fn default() -> Self {
        Self {
            watch_dirs: Vec::new(),
            poll_interval_ms: 1000,
            extensions_filter: Vec::new(),
        }
    }
}

/// File system monitor (polling-based for cross-platform compatibility).
pub struct FileMonitor {
    config: MonitorConfig,
    tx: Sender<FileEvent>,
}

impl FileMonitor {
    pub fn new(config: MonitorConfig) -> (Self, Receiver<FileEvent>) {
        let (tx, rx) = channel();
        (Self { config, tx }, rx)
    }

    /// Start monitoring in a background thread.
    pub fn start(self) -> thread::JoinHandle<()> {
        thread::spawn(move || {
            info!("File monitor started, watching {} directories", self.config.watch_dirs.len());
            let mut known_files: std::collections::HashMap<String, std::time::SystemTime> =
                std::collections::HashMap::new();

            loop {
                for dir in &self.config.watch_dirs {
                    if let Err(e) = self.scan_directory(dir, &mut known_files) {
                        warn!(dir = %dir, error = %e, "Failed to scan directory");
                    }
                }
                thread::sleep(Duration::from_millis(self.config.poll_interval_ms));
            }
        })
    }

    fn scan_directory(
        &self,
        dir: &str,
        known: &mut std::collections::HashMap<String, std::time::SystemTime>,
    ) -> Result<(), CoreError> {
        let path = Path::new(dir);
        if !path.exists() {
            return Ok(());
        }

        let entries = std::fs::read_dir(path)?;
        let mut seen = std::collections::HashSet::new();

        for entry in entries.flatten() {
            let file_path = entry.path();
            if !file_path.is_file() {
                continue;
            }
            let path_str = file_path.to_string_lossy().to_string();

            // Extension filter
            if !self.config.extensions_filter.is_empty() {
                let ext = file_path
                    .extension()
                    .and_then(|e| e.to_str())
                    .unwrap_or("")
                    .to_lowercase();
                if !self.config.extensions_filter.contains(&ext) {
                    continue;
                }
            }

            seen.insert(path_str.clone());

            if let Ok(meta) = entry.metadata() {
                if let Ok(modified) = meta.modified() {
                    match known.get(&path_str) {
                        None => {
                            debug!(path = %path_str, "New file detected");
                            known.insert(path_str.clone(), modified);
                            let _ = self.tx.send(FileEvent::Created(path_str));
                        }
                        Some(&prev) if modified > prev => {
                            debug!(path = %path_str, "Modified file detected");
                            known.insert(path_str.clone(), modified);
                            let _ = self.tx.send(FileEvent::Modified(path_str));
                        }
                        _ => {}
                    }
                }
            }
        }

        // Detect deletions
        let deleted: Vec<String> = known
            .keys()
            .filter(|p| p.starts_with(dir) && !seen.contains(*p))
            .cloned()
            .collect();
        for path in deleted {
            debug!(path = %path, "Deleted file detected");
            known.remove(&path);
            let _ = self.tx.send(FileEvent::Deleted(path));
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_monitor_config_default() {
        let cfg = MonitorConfig::default();
        assert_eq!(cfg.poll_interval_ms, 1000);
        assert!(cfg.watch_dirs.is_empty());
    }

    #[test]
    fn test_monitor_creates_channel() {
        let cfg = MonitorConfig::default();
        let (_monitor, rx) = FileMonitor::new(cfg);
        // Channel should be usable
        drop(rx);
    }
}
