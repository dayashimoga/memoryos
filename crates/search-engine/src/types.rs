//! Search types.

use serde::{Deserialize, Serialize};

/// A search query from the user.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchQuery {
    pub text: String,
    pub limit: usize,
    pub offset: usize,
    pub file_types: Vec<String>,
    pub date_from: Option<String>,
    pub date_to: Option<String>,
    pub tags: Vec<String>,
    pub collection_id: Option<String>,
}

impl SearchQuery {
    pub fn simple(text: impl Into<String>) -> Self {
        Self {
            text: text.into(),
            limit: 50,
            offset: 0,
            file_types: Vec::new(),
            date_from: None,
            date_to: None,
            tags: Vec::new(),
            collection_id: None,
        }
    }
}

/// A single search result item.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchResultItem {
    pub file_id: String,
    pub filename: String,
    pub path: String,
    pub score: f32,
    pub snippet: String,
    pub match_type: MatchType,
}

/// Type of match that produced this result.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum MatchType {
    FullText,
    Semantic,
    Filename,
    Tag,
}

/// Aggregated search result set.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchResult {
    pub query: String,
    pub total: usize,
    pub items: Vec<SearchResultItem>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_search_query_simple() {
        let q = SearchQuery::simple("kubernetes");
        assert_eq!(q.text, "kubernetes");
        assert_eq!(q.limit, 50);
        assert!(q.file_types.is_empty());
    }
}
