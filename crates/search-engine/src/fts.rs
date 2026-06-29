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
        // Try FTS5 first for O(log n) indexed search
        match self.search_fts5(query, limit) {
            Ok(results) if !results.is_empty() => return Ok(results),
            _ => {} // Fall through to LIKE search
        }

        // Fallback: LIKE search (works when FTS5 table not populated)
        self.search_like(query, limit)
    }

    /// FTS5 indexed search using MATCH operator with BM25 ranking.
    fn search_fts5(&self, query: &str, limit: usize) -> Result<Vec<SearchResultItem>, SearchError> {
        let sql = r#"
            SELECT f.id, f.filename, f.path,
                   rank * -1.0 as score,
                   SUBSTR(COALESCE(f.ocr_text, f.summary, ''), 1, 200) as snippet
            FROM files_fts fts
            JOIN files f ON f.id = fts.id
            WHERE files_fts MATCH ?1
            ORDER BY rank
            LIMIT ?2
        "#;

        // Escape FTS5 query: wrap terms in double quotes for exact matching
        let fts_query = query
            .split_whitespace()
            .map(|w| format!("\"{}\"", w.replace('"', "")))
            .collect::<Vec<_>>()
            .join(" ");

        let mut stmt = self
            .conn
            .prepare(sql)
            .map_err(|e| SearchError::Database(e.to_string()))?;

        let results = stmt
            .query_map(params![fts_query, limit as i64], |row| {
                Ok(SearchResultItem {
                    file_id: row.get::<_, String>(0)?,
                    filename: row.get::<_, String>(1)?,
                    path: row.get::<_, String>(2)?,
                    score: row.get::<_, f64>(3)? as f32,
                    snippet: row.get::<_, Option<String>>(4)?.unwrap_or_default(),
                    match_type: MatchType::FullText,
                })
            })
            .map_err(|e| SearchError::Database(e.to_string()))?
            .filter_map(|r| r.ok())
            .collect();

        Ok(results)
    }

    /// LIKE-based fallback search (no index required).
    fn search_like(&self, query: &str, limit: usize) -> Result<Vec<SearchResultItem>, SearchError> {
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
        let mut stmt = self
            .conn
            .prepare(sql)
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

    /// Populate FTS5 index from existing files table data.
    pub fn ensure_fts_populated(&self) -> Result<usize, SearchError> {
        // Insert any files not yet in FTS index
        let sql = r#"
            INSERT OR IGNORE INTO files_fts(id, filename, ocr_text, summary)
            SELECT id, filename, COALESCE(ocr_text, ''), COALESCE(summary, '')
            FROM files
            WHERE id NOT IN (SELECT id FROM files_fts)
        "#;
        let affected = self
            .conn
            .execute(sql, [])
            .map_err(|e| SearchError::Database(e.to_string()))?;
        Ok(affected)
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
            );",
        )
        .unwrap();

        let searcher = FtsSearcher { conn };
        let results = searcher.search("kubernetes", 10).unwrap();
        assert!(results.is_empty());
    }
}
