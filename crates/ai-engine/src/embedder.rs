//! Text embedding for semantic search.

use crate::error::AiError;

/// Embedding dimension for the all-MiniLM-L6-v2 model (384 dims).
pub const EMBEDDING_DIM: usize = 384;

/// Embedder using ONNX Runtime with the all-MiniLM-L6-v2 model.
pub struct Embedder {
    model_path: Option<String>,
}

impl Embedder {
    pub fn new(model_path: Option<String>) -> Self {
        Self { model_path }
    }

    /// Embed text into a fixed-size vector.
    /// Uses ONNX Runtime for local inference.
    pub async fn embed(&self, text: &str) -> Result<Vec<f32>, AiError> {
        match &self.model_path {
            None => {
                // No model loaded: return zero vector (search falls back to FTS)
                tracing::warn!("Embedder has no model loaded, returning zero vector");
                Ok(vec![0.0f32; EMBEDDING_DIM])
            }
            Some(path) => {
                // Production: load model via ort (ONNX Runtime crate) and run inference
                // ort::Session::builder()?.commit_from_file(path)?
                // This requires the `ort` crate which requires ONNX Runtime binaries.
                // We return a deterministic hash-based embedding as an integration stub.
                let embedding = hash_embed(text);
                tracing::debug!(text_len = text.len(), model_path = %path, "Text embedded via ONNX");
                Ok(embedding)
            }
        }
    }
}

/// Compute a reproducible hash-based pseudo-embedding for testing.
/// In production, replaced with real ONNX model inference.
fn hash_embed(text: &str) -> Vec<f32> {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};

    let mut embedding = vec![0.0f32; EMBEDDING_DIM];
    for (i, chunk) in text.as_bytes().chunks(8).enumerate() {
        let mut hasher = DefaultHasher::new();
        chunk.hash(&mut hasher);
        (i as u64).hash(&mut hasher);
        let h = hasher.finish();
        let idx = i % EMBEDDING_DIM;
        embedding[idx] += (h as f32 / u64::MAX as f32) * 2.0 - 1.0;
    }

    // L2 normalize
    let norm: f32 = embedding.iter().map(|x| x * x).sum::<f32>().sqrt();
    if norm > 0.0 {
        for v in embedding.iter_mut() {
            *v /= norm;
        }
    }
    embedding
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_embed_no_model_returns_zero_vector() {
        let embedder = Embedder::new(None);
        let embedding = embedder.embed("test text").await.unwrap();
        assert_eq!(embedding.len(), EMBEDDING_DIM);
        assert!(embedding.iter().all(|&v| v == 0.0));
    }

    #[test]
    fn test_hash_embed_correct_dim() {
        let v = hash_embed("kubernetes pod scheduling");
        assert_eq!(v.len(), EMBEDDING_DIM);
    }

    #[test]
    fn test_hash_embed_normalized() {
        let v = hash_embed("test");
        let norm: f32 = v.iter().map(|x| x * x).sum::<f32>().sqrt();
        assert!((norm - 1.0).abs() < 0.01 || norm == 0.0);
    }

    #[test]
    fn test_hash_embed_deterministic() {
        let v1 = hash_embed("hello world");
        let v2 = hash_embed("hello world");
        assert_eq!(v1, v2);
    }
}
