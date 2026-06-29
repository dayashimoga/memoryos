//! AI engine types.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// Supported AI model families.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum AiModelFamily {
    Gemma,
    Phi,
    Qwen,
    Llama,
}

impl AiModelFamily {
    pub fn as_str(&self) -> &'static str {
        match self {
            AiModelFamily::Gemma => "gemma",
            AiModelFamily::Phi => "phi",
            AiModelFamily::Qwen => "qwen",
            AiModelFamily::Llama => "llama",
        }
    }
}

/// An AI model descriptor.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AiModel {
    pub id: String,
    pub name: String,
    pub family: AiModelFamily,
    pub size_bytes: u64,
    pub context_length: usize,
    pub quantization: String,
    pub file_path: Option<String>,
    pub is_active: bool,
    pub downloaded_at: Option<DateTime<Utc>>,
    pub hf_repo: String,
    pub hf_filename: String,
}

/// Well-known bundled model catalog.
pub fn default_model_catalog() -> Vec<AiModel> {
    vec![
        AiModel {
            id: "gemma-2-2b-it-q4".to_string(),
            name: "Gemma 2 2B Instruct (Q4_K_M)".to_string(),
            family: AiModelFamily::Gemma,
            size_bytes: 1_600_000_000,
            context_length: 8192,
            quantization: "Q4_K_M".to_string(),
            file_path: None,
            is_active: false,
            downloaded_at: None,
            hf_repo: "bartowski/gemma-2-2b-it-GGUF".to_string(),
            hf_filename: "gemma-2-2b-it-Q4_K_M.gguf".to_string(),
        },
        AiModel {
            id: "phi-3.5-mini-instruct-q4".to_string(),
            name: "Phi 3.5 Mini Instruct (Q4_K_M)".to_string(),
            family: AiModelFamily::Phi,
            size_bytes: 2_200_000_000,
            context_length: 131072,
            quantization: "Q4_K_M".to_string(),
            file_path: None,
            is_active: false,
            downloaded_at: None,
            hf_repo: "bartowski/Phi-3.5-mini-instruct-GGUF".to_string(),
            hf_filename: "Phi-3.5-mini-instruct-Q4_K_M.gguf".to_string(),
        },
        AiModel {
            id: "qwen2.5-1.5b-instruct-q4".to_string(),
            name: "Qwen 2.5 1.5B Instruct (Q4_K_M)".to_string(),
            family: AiModelFamily::Qwen,
            size_bytes: 900_000_000,
            context_length: 32768,
            quantization: "Q4_K_M".to_string(),
            file_path: None,
            is_active: false,
            downloaded_at: None,
            hf_repo: "Qwen/Qwen2.5-1.5B-Instruct-GGUF".to_string(),
            hf_filename: "qwen2.5-1.5b-instruct-q4_k_m.gguf".to_string(),
        },
    ]
}

/// A generation request to the local AI model.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenerateRequest {
    pub model_id: String,
    pub prompt: String,
    pub system_prompt: Option<String>,
    pub max_tokens: usize,
    pub temperature: f32,
    pub stop_sequences: Vec<String>,
}

impl GenerateRequest {
    pub fn new(model_id: impl Into<String>, prompt: impl Into<String>) -> Self {
        Self {
            model_id: model_id.into(),
            prompt: prompt.into(),
            system_prompt: None,
            max_tokens: 512,
            temperature: 0.7,
            stop_sequences: Vec::new(),
        }
    }
}

/// A generation response from the local AI model.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenerateResponse {
    pub text: String,
    pub prompt_tokens: usize,
    pub completion_tokens: usize,
    pub latency_ms: u64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_catalog_not_empty() {
        let catalog = default_model_catalog();
        assert!(!catalog.is_empty());
        assert!(catalog.iter().any(|m| m.family == AiModelFamily::Gemma));
    }

    #[test]
    fn test_generate_request_defaults() {
        let req = GenerateRequest::new("gemma", "summarize this");
        assert_eq!(req.temperature, 0.7);
        assert_eq!(req.max_tokens, 512);
    }
}
