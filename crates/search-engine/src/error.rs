//! Search engine error types.

use thiserror::Error;

#[derive(Debug, Error)]
pub enum SearchError {
    #[error("Database error: {0}")]
    Database(String),

    #[error("Index error: {0}")]
    Index(String),

    #[error("Embedding error: {0}")]
    Embedding(String),

    #[error("Query parse error: {0}")]
    QueryParse(String),
}
