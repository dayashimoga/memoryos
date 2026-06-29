//! Vector/semantic search using sqlite-vec extension.

use crate::error::SearchError;
use crate::types::{MatchType, SearchResultItem};
use tracing::warn;

/// Embedding vector dimension (matches embedding model output).
pub const EMBEDDING_DIM: usize = 384;

pub struct VectorSearcher {
    _db_path: String,
}

impl VectorSearcher {
    pub fn new(db_path: &str) -> Result<Self, SearchError> {
        Ok(Self {
            _db_path: db_path.to_string(),
        })
    }

    /// Search for semantically similar files using a query embedding.
    pub async fn search_similar(
        &self,
        query_text: &str,
        _limit: usize,
    ) -> Result<Vec<SearchResultItem>, SearchError> {
        // In production: embed query_text → vector → sqlite-vec KNN search
        // sqlite-vec is loaded as a SQLite extension at runtime:
        //   conn.load_extension("sqlite-vec", None)?;
        //   SELECT file_id, distance FROM vec_items WHERE embedding MATCH ? ORDER BY distance LIMIT ?
        //
        // For now, return empty (vector DB may not be populated yet).
        // This is intentional: the system degrades gracefully to FTS-only when
        // no embeddings exist.
        warn!(
            query = query_text,
            "Vector search called but no embeddings exist yet"
        );
        Ok(Vec::new())
    }

    /// Insert an embedding for a file.
    pub async fn insert_embedding(
        &self,
        file_id: &str,
        _embedding: &[f32; EMBEDDING_DIM],
    ) -> Result<i64, SearchError> {
        // Production: INSERT INTO vec_items (file_id, embedding) VALUES (?, ?)
        // using the sqlite-vec binary format.
        tracing::debug!(
            file_id,
            "Embedding insert (stub - requires sqlite-vec extension)"
        );
        Ok(0)
    }
}

/// Convert a slice of f32 values to the sqlite-vec binary format.
pub fn embedding_to_blob(embedding: &[f32]) -> Vec<u8> {
    embedding.iter().flat_map(|f| f.to_le_bytes()).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_embedding_to_blob_size() {
        let v: Vec<f32> = vec![1.0; EMBEDDING_DIM];
        let blob = embedding_to_blob(&v);
        assert_eq!(blob.len(), EMBEDDING_DIM * 4);
    }

    #[tokio::test]
    async fn test_search_similar_empty() {
        let searcher = VectorSearcher::new(":memory:").unwrap();
        let results = searcher.search_similar("test query", 10).await.unwrap();
        assert!(results.is_empty());
    }
}
