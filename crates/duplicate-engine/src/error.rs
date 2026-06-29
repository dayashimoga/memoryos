//! Duplicate engine error types.

use thiserror::Error;

#[derive(Debug, Error)]
pub enum DuplicateError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Image loading error: {0}")]
    ImageLoad(String),

    #[error("Hash computation error: {0}")]
    Hash(String),
}
