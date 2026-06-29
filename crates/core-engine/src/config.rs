//! Application configuration.

use serde::{Deserialize, Serialize};
use std::path::PathBuf;

/// Runtime configuration for the MemoryOS core engine.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    /// Root directory for all MemoryOS data.
    pub data_dir: PathBuf,

    /// Path to the SQLite metadata database.
    pub db_path: PathBuf,

    /// Path to the vector store database.
    pub vector_db_path: PathBuf,

    /// Directory for AI model storage.
    pub models_dir: PathBuf,

    /// Directory for the encrypted vault.
    pub vault_dir: PathBuf,

    /// Maximum number of indexing worker threads.
    pub index_threads: usize,

    /// Batch size for indexing operations.
    pub index_batch_size: usize,

    /// Enable debug mode.
    pub debug: bool,
}

impl Config {
    pub fn from_data_dir(data_dir: impl Into<PathBuf>) -> Self {
        let data_dir = data_dir.into();
        Self {
            db_path: data_dir.join("metadata.db"),
            vector_db_path: data_dir.join("vectors.db"),
            models_dir: data_dir.join("models"),
            vault_dir: data_dir.join("vault"),
            index_threads: std::thread::available_parallelism()
                .map(|n| n.get().min(4))
                .unwrap_or(2),
            index_batch_size: 32,
            debug: false,
            data_dir,
        }
    }

    pub fn ensure_dirs(&self) -> std::io::Result<()> {
        std::fs::create_dir_all(&self.data_dir)?;
        std::fs::create_dir_all(&self.models_dir)?;
        std::fs::create_dir_all(&self.vault_dir)?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_config_from_data_dir() {
        let cfg = Config::from_data_dir("/tmp/memoryos");
        assert_eq!(cfg.db_path, PathBuf::from("/tmp/memoryos/metadata.db"));
        assert_eq!(cfg.models_dir, PathBuf::from("/tmp/memoryos/models"));
        assert!(cfg.index_threads >= 1);
    }
}
