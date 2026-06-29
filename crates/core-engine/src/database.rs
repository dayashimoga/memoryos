#![allow(unused_imports, dead_code)]

//! SQLite database layer for MemoryOS metadata storage.

use crate::error::CoreError;
use crate::models::{Collection, FileEntry, FileType, IndexingStatus, Tag, UserSettings};
use chrono::{DateTime, Utc};
use rusqlite::{params, Connection};
use std::path::Path;
use tracing::{debug, info};
use uuid::Uuid;

/// Manages the SQLite metadata database.
pub struct MetadataDb {
    conn: Connection,
}

impl MetadataDb {
    /// Open (or create) the metadata database at the given path.
    pub fn open(db_path: impl AsRef<Path>) -> Result<Self, CoreError> {
        let conn = Connection::open(db_path)?;
        // Enable WAL mode for concurrent reads
        conn.execute_batch("PRAGMA journal_mode=WAL; PRAGMA foreign_keys=ON;")?;
        let db = Self { conn };
        db.run_migrations()?;
        Ok(db)
    }

    /// Open an in-memory database (for testing).
    pub fn open_in_memory() -> Result<Self, CoreError> {
        let conn = Connection::open_in_memory()?;
        conn.execute_batch("PRAGMA foreign_keys=ON;")?;
        let db = Self { conn };
        db.run_migrations()?;
        Ok(db)
    }

    fn run_migrations(&self) -> Result<(), CoreError> {
        self.conn.execute_batch(include_str!("sql/schema.sql"))?;
        info!("Database migrations applied");
        Ok(())
    }

    // ── FileEntry operations ──────────────────────────────────────────────────

    pub fn insert_file(&self, entry: &FileEntry) -> Result<(), CoreError> {
        self.conn.execute(
            r#"INSERT INTO files (
                id, path, filename, extension, file_type, size_bytes,
                sha256_hash, phash, ocr_text, summary, embedding_id,
                is_encrypted, indexing_status, created_at, modified_at, indexed_at
            ) VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14,?15,?16)"#,
            params![
                entry.id.to_string(),
                entry.path,
                entry.filename,
                entry.extension,
                serde_json::to_string(&entry.file_type)?,
                entry.size_bytes as i64,
                entry.sha256_hash,
                entry.phash,
                entry.ocr_text,
                entry.summary,
                entry.embedding_id,
                entry.is_encrypted,
                serde_json::to_string(&entry.indexing_status)?,
                entry.created_at.to_rfc3339(),
                entry.modified_at.to_rfc3339(),
                entry.indexed_at.map(|d| d.to_rfc3339()),
            ],
        )?;
        debug!(id = %entry.id, path = %entry.path, "File entry inserted");
        Ok(())
    }

    pub fn get_file_by_id(&self, id: &Uuid) -> Result<Option<FileEntry>, CoreError> {
        let result = self.conn.query_row(
            "SELECT * FROM files WHERE id = ?1",
            params![id.to_string()],
            Self::row_to_file_entry,
        );
        match result {
            Ok(entry) => Ok(Some(entry)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(CoreError::Database(e)),
        }
    }

    pub fn get_file_by_path(&self, path: &str) -> Result<Option<FileEntry>, CoreError> {
        let result = self.conn.query_row(
            "SELECT * FROM files WHERE path = ?1",
            params![path],
            Self::row_to_file_entry,
        );
        match result {
            Ok(entry) => Ok(Some(entry)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(CoreError::Database(e)),
        }
    }

    pub fn list_files(&self, limit: usize, offset: usize) -> Result<Vec<FileEntry>, CoreError> {
        let mut stmt = self
            .conn
            .prepare("SELECT * FROM files ORDER BY created_at DESC LIMIT ?1 OFFSET ?2")?;
        let entries = stmt
            .query_map(
                params![limit as i64, offset as i64],
                Self::row_to_file_entry,
            )?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(entries)
    }

    pub fn search_files_by_text(&self, query: &str) -> Result<Vec<FileEntry>, CoreError> {
        let mut stmt = self.conn.prepare(
            r#"SELECT * FROM files
               WHERE filename LIKE ?1 OR ocr_text LIKE ?1 OR summary LIKE ?1
               ORDER BY created_at DESC LIMIT 100"#,
        )?;
        let pattern = format!("%{}%", query);
        let entries = stmt
            .query_map(params![pattern], Self::row_to_file_entry)?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(entries)
    }

    pub fn update_indexing_status(
        &self,
        id: &Uuid,
        status: &IndexingStatus,
    ) -> Result<(), CoreError> {
        self.conn.execute(
            "UPDATE files SET indexing_status = ?1, indexed_at = ?2 WHERE id = ?3",
            params![
                serde_json::to_string(status)?,
                Utc::now().to_rfc3339(),
                id.to_string()
            ],
        )?;
        Ok(())
    }

    pub fn count_files(&self) -> Result<usize, CoreError> {
        let count: i64 = self
            .conn
            .query_row("SELECT COUNT(*) FROM files", [], |row| row.get(0))?;
        Ok(count as usize)
    }

    /// Delete a file entry by its UUID.
    pub fn delete_file(&self, id: &Uuid) -> Result<usize, CoreError> {
        let affected = self
            .conn
            .execute("DELETE FROM files WHERE id = ?1", params![id.to_string()])?;
        Ok(affected)
    }

    /// Set or clear the encrypted flag for a file.
    pub fn set_encrypted(&self, id: &Uuid, encrypted: bool) -> Result<(), CoreError> {
        self.conn.execute(
            "UPDATE files SET is_encrypted = ?1 WHERE id = ?2",
            params![encrypted, id.to_string()],
        )?;
        Ok(())
    }

    /// List all files marked as encrypted (vault members).
    pub fn list_encrypted_files(&self) -> Result<Vec<FileEntry>, CoreError> {
        let mut stmt = self
            .conn
            .prepare("SELECT * FROM files WHERE is_encrypted = 1 ORDER BY modified_at DESC")?;
        let entries = stmt
            .query_map([], Self::row_to_file_entry)?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(entries)
    }

    /// Count files by indexing status.
    pub fn count_by_status(&self, status: &IndexingStatus) -> Result<usize, CoreError> {
        let status_str = serde_json::to_string(status)?;
        let count: i64 = self.conn.query_row(
            "SELECT COUNT(*) FROM files WHERE indexing_status = ?1",
            params![status_str],
            |row| row.get(0),
        )?;
        Ok(count as usize)
    }

    /// Get total size of all indexed files.
    pub fn total_size_bytes(&self) -> Result<u64, CoreError> {
        let total: i64 = self.conn.query_row(
            "SELECT COALESCE(SUM(size_bytes), 0) FROM files",
            [],
            |row| row.get(0),
        )?;
        Ok(total as u64)
    }

    fn row_to_file_entry(row: &rusqlite::Row<'_>) -> rusqlite::Result<FileEntry> {
        let file_type_str: String = row.get("file_type")?;
        let status_str: String = row.get("indexing_status")?;
        let id_str: String = row.get("id")?;
        let created_str: String = row.get("created_at")?;
        let modified_str: String = row.get("modified_at")?;
        let indexed_str: Option<String> = row.get("indexed_at")?;

        Ok(FileEntry {
            id: Uuid::parse_str(&id_str).unwrap_or_default(),
            path: row.get("path")?,
            filename: row.get("filename")?,
            extension: row.get("extension")?,
            file_type: serde_json::from_str(&file_type_str).unwrap_or(FileType::Unknown),
            size_bytes: row.get::<_, i64>("size_bytes")? as u64,
            sha256_hash: row.get("sha256_hash")?,
            phash: row.get("phash")?,
            ocr_text: row.get("ocr_text")?,
            summary: row.get("summary")?,
            embedding_id: row.get("embedding_id")?,
            tags: Vec::new(), // loaded separately via join
            collection_ids: Vec::new(),
            is_encrypted: row.get("is_encrypted")?,
            indexing_status: serde_json::from_str(&status_str).unwrap_or(IndexingStatus::Pending),
            created_at: DateTime::parse_from_rfc3339(&created_str)
                .map(|d| d.with_timezone(&Utc))
                .unwrap_or_else(|_| Utc::now()),
            modified_at: DateTime::parse_from_rfc3339(&modified_str)
                .map(|d| d.with_timezone(&Utc))
                .unwrap_or_else(|_| Utc::now()),
            indexed_at: indexed_str.and_then(|s| {
                DateTime::parse_from_rfc3339(&s)
                    .map(|d| d.with_timezone(&Utc))
                    .ok()
            }),
        })
    }
} // end impl MetadataDb

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::{FileEntry, FileType};

    fn test_db() -> MetadataDb {
        MetadataDb::open_in_memory().expect("in-memory db")
    }

    #[test]
    fn test_insert_and_retrieve_file() {
        let db = test_db();
        let entry = FileEntry::new("/home/user/test.png", FileType::Image, 4096);
        db.insert_file(&entry).unwrap();

        let retrieved = db.get_file_by_id(&entry.id).unwrap();
        assert!(retrieved.is_some());
        let retrieved = retrieved.unwrap();
        assert_eq!(retrieved.filename, "test.png");
        assert_eq!(retrieved.size_bytes, 4096);
    }

    #[test]
    fn test_get_file_by_path() {
        let db = test_db();
        let entry = FileEntry::new("/docs/readme.md", FileType::Markdown, 512);
        db.insert_file(&entry).unwrap();

        let found = db.get_file_by_path("/docs/readme.md").unwrap();
        assert!(found.is_some());
    }

    #[test]
    fn test_count_files() {
        let db = test_db();
        assert_eq!(db.count_files().unwrap(), 0);
        db.insert_file(&FileEntry::new("/a.txt", FileType::Text, 10))
            .unwrap();
        db.insert_file(&FileEntry::new("/b.txt", FileType::Text, 20))
            .unwrap();
        assert_eq!(db.count_files().unwrap(), 2);
    }

    #[test]
    fn test_search_by_text() {
        let db = test_db();
        let mut entry = FileEntry::new("/notes/kubernetes.md", FileType::Markdown, 200);
        entry.ocr_text = Some("Kubernetes pod scheduling".to_string());
        db.insert_file(&entry).unwrap();

        let results = db.search_files_by_text("kubernetes").unwrap();
        assert!(!results.is_empty());
    }

    #[test]
    fn test_update_indexing_status() {
        let db = test_db();
        let entry = FileEntry::new("/video.mp4", FileType::Video, 10_000_000);
        db.insert_file(&entry).unwrap();
        db.update_indexing_status(&entry.id, &IndexingStatus::Completed)
            .unwrap();

        let updated = db.get_file_by_id(&entry.id).unwrap().unwrap();
        assert_eq!(updated.indexing_status, IndexingStatus::Completed);
    }
}
