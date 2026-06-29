//! AI engine error types.

use thiserror::Error;

#[derive(Debug, Error)]
pub enum AiError {
    #[error("Model not loaded: {model_id}")]
    ModelNotLoaded { model_id: String },

    #[error("Inference error: {0}")]
    Inference(String),

    #[error("Model download error: {0}")]
    Download(String),

    #[error("Unsupported model family: {family}")]
    UnsupportedFamily { family: String },

    #[error("Context too long: {tokens} tokens (max {max})")]
    ContextTooLong { tokens: usize, max: usize },

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Network error: {0}")]
    Network(String),
}
