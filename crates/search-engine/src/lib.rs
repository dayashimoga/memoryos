//! Search Engine — full-text + vector semantic search via SQLite FTS5 and sqlite-vec.

pub mod error;
pub mod fts;
pub mod types;
pub mod vector;

pub use error::SearchError;
pub use types::{SearchQuery, SearchResult, SearchResultItem};

use crate::fts::FtsSearcher;
use crate::vector::VectorSearcher;

/// Unified search engine combining FTS5 and vector search.
pub struct SearchEngine {
    fts: FtsSearcher,
    vector: VectorSearcher,
}

impl SearchEngine {
    pub fn new(db_path: &str, vector_db_path: &str) -> Result<Self, SearchError> {
        Ok(Self {
            fts: FtsSearcher::new(db_path)?,
            vector: VectorSearcher::new(vector_db_path)?,
        })
    }

    /// Hybrid search: combines FTS and vector results ranked by relevance.
    pub async fn search(&self, query: &SearchQuery) -> Result<SearchResult, SearchError> {
        let fts_results = self.fts.search(&query.text, query.limit)?;
        let vector_results = self.vector.search_similar(&query.text, query.limit).await?;

        // Merge and deduplicate by file_id, preferring higher scores
        let mut merged: std::collections::HashMap<String, SearchResultItem> =
            std::collections::HashMap::new();

        for item in fts_results.into_iter().chain(vector_results) {
            merged
                .entry(item.file_id.clone())
                .and_modify(|existing| {
                    existing.score = existing.score.max(item.score);
                    if !item.snippet.is_empty() && existing.snippet.is_empty() {
                        existing.snippet = item.snippet.clone();
                    }
                })
                .or_insert(item);
        }

        let mut items: Vec<SearchResultItem> = merged.into_values().collect();
        items.sort_by(|a, b| {
            b.score
                .partial_cmp(&a.score)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
        items.truncate(query.limit);

        Ok(SearchResult {
            query: query.text.clone(),
            total: items.len(),
            items,
        })
    }
}
