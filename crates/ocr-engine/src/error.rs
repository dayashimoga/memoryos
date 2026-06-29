//! OCR error types.

use thiserror::Error;

#[derive(Debug, Error)]
pub enum OcrError {
    #[error("Image loading error: {0}")]
    ImageLoad(String),

    #[error("OCR backend unavailable: {backend}")]
    BackendUnavailable { backend: String },

    #[error("Processing error: {0}")]
    Processing(String),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Unsupported image format: {format}")]
    UnsupportedFormat { format: String },
}
