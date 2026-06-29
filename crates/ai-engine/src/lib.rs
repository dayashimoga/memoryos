//! AI Engine — Local AI inference via llama.cpp and ONNX Runtime.

pub mod error;
pub mod model_manager;
pub mod summarizer;
pub mod categorizer;
pub mod chat;
pub mod embedder;
pub mod types;

pub use error::AiError;
pub use types::{AiModel, AiModelFamily, GenerateRequest, GenerateResponse};
