//! Domain error types for the core engine.

use thiserror::Error;

#[derive(Debug, Error)]
pub enum CoreError {
    #[error("Database error: {0}")]
    Database(#[from] rusqlite::Error),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),

    #[error("Encryption error: {0}")]
    Encryption(String),

    #[error("File not found: {path}")]
    FileNotFound { path: String },

    #[error("Invalid input: {message}")]
    InvalidInput { message: String },

    #[error("Not initialized")]
    NotInitialized,

    #[error("Operation cancelled")]
    Cancelled,

    #[error("Internal error: {0}")]
    Internal(String),
}
