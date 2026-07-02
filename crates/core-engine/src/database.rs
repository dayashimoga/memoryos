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
        // v1.2 migration: add is_favorite column if not exists
        let _ = self
            .conn
            .execute_batch("ALTER TABLE files ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0;");
        info!("Database migrations applied");
        Ok(())
    }

    // ── FileEntry operations ──────────────────────────────────────────────────

    pub fn insert_file(&self, entry: &FileEntry) -> Result<(), CoreError> {
        self.conn.execute(
            r#"INSERT INTO files (
                id, path, filename, extension, file_type, size_bytes,
                sha256_hash, phash, ocr_text, summary, embedding_id,
                is_encrypted, is_favorite, indexing_status, created_at, modified_at, indexed_at
            ) VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14,?15,?16,?17)"#,
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
                entry.is_favorite,
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

    /// Update the SHA-256 hash for a file.
    pub fn update_file_hash(&self, id: &Uuid, hash: &str) -> Result<(), CoreError> {
        self.conn.execute(
            "UPDATE files SET sha256_hash = ?1 WHERE id = ?2",
            params![hash, id.to_string()],
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

    /// Get groups of duplicate files (same SHA-256 hash).
    pub fn get_duplicate_groups(&self) -> Result<Vec<(String, Vec<String>)>, CoreError> {
        let mut stmt = self.conn.prepare(
            r#"SELECT sha256_hash, GROUP_CONCAT(path, '\n') as paths
               FROM files
               WHERE sha256_hash IS NOT NULL AND sha256_hash != ''
               GROUP BY sha256_hash
               HAVING COUNT(*) > 1"#,
        )?;
        let groups = stmt
            .query_map([], |row| {
                let hash: String = row.get(0)?;
                let paths_str: String = row.get(1)?;
                let paths: Vec<String> = paths_str.split('\n').map(String::from).collect();
                Ok((hash, paths))
            })?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(groups)
    }

    /// Get files larger than the given threshold (bytes).
    pub fn get_large_files(&self, min_bytes: u64) -> Result<Vec<FileEntry>, CoreError> {
        let mut stmt = self.conn.prepare(
            "SELECT * FROM files WHERE size_bytes >= ?1 ORDER BY size_bytes DESC LIMIT 200",
        )?;
        let entries = stmt
            .query_map(params![min_bytes as i64], Self::row_to_file_entry)?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(entries)
    }

    /// Get files within a date range.
    pub fn get_files_by_date_range(
        &self,
        from: &str,
        to: &str,
    ) -> Result<Vec<FileEntry>, CoreError> {
        let mut stmt = self.conn.prepare(
            "SELECT * FROM files WHERE created_at >= ?1 AND created_at <= ?2 ORDER BY created_at DESC LIMIT 500",
        )?;
        let entries = stmt
            .query_map(params![from, to], Self::row_to_file_entry)?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(entries)
    }

    // ── Tag operations ────────────────────────────────────────────────────────

    /// Insert a tag.
    pub fn insert_tag(&self, tag: &crate::models::Tag) -> Result<(), CoreError> {
        self.conn.execute(
            "INSERT OR IGNORE INTO tags (id, name, color, created_at) VALUES (?1, ?2, ?3, ?4)",
            params![
                tag.id.to_string(),
                tag.name,
                tag.color,
                tag.created_at.to_rfc3339()
            ],
        )?;
        Ok(())
    }

    /// List all tags.
    pub fn list_tags(&self) -> Result<Vec<crate::models::Tag>, CoreError> {
        let mut stmt = self
            .conn
            .prepare("SELECT id, name, color, created_at FROM tags ORDER BY name")?;
        let tags = stmt
            .query_map([], |row| {
                let id_str: String = row.get(0)?;
                let created_str: String = row.get(3)?;
                Ok(crate::models::Tag {
                    id: uuid::Uuid::parse_str(&id_str).unwrap_or_default(),
                    name: row.get(1)?,
                    color: row.get(2)?,
                    created_at: chrono::DateTime::parse_from_rfc3339(&created_str)
                        .map(|d| d.with_timezone(&Utc))
                        .unwrap_or_else(|_| Utc::now()),
                })
            })?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(tags)
    }

    /// Add a tag to a file.
    pub fn add_tag_to_file(
        &self,
        file_id: &uuid::Uuid,
        tag_id: &uuid::Uuid,
    ) -> Result<(), CoreError> {
        self.conn.execute(
            "INSERT OR IGNORE INTO file_tags (file_id, tag_id) VALUES (?1, ?2)",
            params![file_id.to_string(), tag_id.to_string()],
        )?;
        Ok(())
    }

    /// Get tags for a file.
    pub fn get_tags_for_file(&self, file_id: &uuid::Uuid) -> Result<Vec<String>, CoreError> {
        let mut stmt = self.conn.prepare(
            "SELECT t.name FROM tags t INNER JOIN file_tags ft ON t.id = ft.tag_id WHERE ft.file_id = ?1",
        )?;
        let tags = stmt
            .query_map(params![file_id.to_string()], |row| row.get::<_, String>(0))?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(tags)
    }

    // ── Collection operations ─────────────────────────────────────────────────

    /// Insert a collection.
    pub fn insert_collection(&self, col: &Collection) -> Result<(), CoreError> {
        self.conn.execute(
            "INSERT INTO collections (id, name, description, icon, file_count, created_at, updated_at) VALUES (?1,?2,?3,?4,?5,?6,?7)",
            params![
                col.id.to_string(),
                col.name,
                col.description,
                col.icon,
                col.file_count as i64,
                col.created_at.to_rfc3339(),
                col.updated_at.to_rfc3339()
            ],
        )?;
        Ok(())
    }

    /// List all collections.
    pub fn list_collections(&self) -> Result<Vec<Collection>, CoreError> {
        let mut stmt = self.conn.prepare(
            "SELECT id, name, description, icon, file_count, created_at, updated_at FROM collections ORDER BY updated_at DESC",
        )?;
        let cols = stmt
            .query_map([], |row| {
                let id_str: String = row.get(0)?;
                let created_str: String = row.get(5)?;
                let updated_str: String = row.get(6)?;
                Ok(Collection {
                    id: uuid::Uuid::parse_str(&id_str).unwrap_or_default(),
                    name: row.get(1)?,
                    description: row.get(2)?,
                    icon: row.get(3)?,
                    file_count: row.get::<_, i64>(4)? as usize,
                    created_at: chrono::DateTime::parse_from_rfc3339(&created_str)
                        .map(|d| d.with_timezone(&Utc))
                        .unwrap_or_else(|_| Utc::now()),
                    updated_at: chrono::DateTime::parse_from_rfc3339(&updated_str)
                        .map(|d| d.with_timezone(&Utc))
                        .unwrap_or_else(|_| Utc::now()),
                })
            })?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(cols)
    }

    /// Delete a collection.
    pub fn delete_collection(&self, id: &uuid::Uuid) -> Result<usize, CoreError> {
        let affected = self.conn.execute(
            "DELETE FROM collections WHERE id = ?1",
            params![id.to_string()],
        )?;
        Ok(affected)
    }

    /// Add a file to a collection.
    pub fn add_file_to_collection(
        &self,
        collection_id: &uuid::Uuid,
        file_id: &uuid::Uuid,
    ) -> Result<(), CoreError> {
        self.conn.execute(
            "INSERT OR IGNORE INTO collection_files (collection_id, file_id, added_at) VALUES (?1, ?2, ?3)",
            params![collection_id.to_string(), file_id.to_string(), Utc::now().to_rfc3339()],
        )?;
        // Update file count
        self.conn.execute(
            "UPDATE collections SET file_count = (SELECT COUNT(*) FROM collection_files WHERE collection_id = ?1) WHERE id = ?1",
            params![collection_id.to_string()],
        )?;
        Ok(())
    }

    /// Get files in a collection.
    pub fn get_files_in_collection(
        &self,
        collection_id: &uuid::Uuid,
    ) -> Result<Vec<FileEntry>, CoreError> {
        let mut stmt = self.conn.prepare(
            "SELECT f.* FROM files f INNER JOIN collection_files cf ON f.id = cf.file_id WHERE cf.collection_id = ?1 ORDER BY cf.added_at DESC",
        )?;
        let entries = stmt
            .query_map(params![collection_id.to_string()], Self::row_to_file_entry)?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(entries)
    }

    // ── Activity logging ──────────────────────────────────────────────────────

    /// Log an activity event.
    pub fn log_activity(
        &self,
        event_type: &str,
        file_id: Option<&uuid::Uuid>,
        detail: Option<&str>,
    ) -> Result<(), CoreError> {
        self.conn.execute(
            "INSERT INTO activity_log (event_type, file_id, detail, occurred_at) VALUES (?1, ?2, ?3, ?4)",
            params![
                event_type,
                file_id.map(|id| id.to_string()),
                detail,
                Utc::now().to_rfc3339()
            ],
        )?;
        Ok(())
    }

    // ── Favorites ──────────────────────────────────────────────────────────────

    /// Toggle the favorite flag for a file.
    pub fn toggle_favorite(&self, id: &Uuid) -> Result<(), CoreError> {
        self.conn.execute(
            "UPDATE files SET is_favorite = CASE WHEN is_favorite = 0 THEN 1 ELSE 0 END WHERE id = ?1",
            params![id.to_string()],
        )?;
        Ok(())
    }

    /// List all favorited files.
    pub fn list_favorites(&self) -> Result<Vec<FileEntry>, CoreError> {
        let mut stmt = self
            .conn
            .prepare("SELECT * FROM files WHERE is_favorite = 1 ORDER BY modified_at DESC")?;
        let entries = stmt
            .query_map([], Self::row_to_file_entry)?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(entries)
    }

    // ── Recent files ──────────────────────────────────────────────────────────

    /// Get the most recently modified files.
    pub fn recent_files(&self, limit: usize) -> Result<Vec<FileEntry>, CoreError> {
        let mut stmt = self
            .conn
            .prepare("SELECT * FROM files ORDER BY modified_at DESC LIMIT ?1")?;
        let entries = stmt
            .query_map(params![limit as i64], Self::row_to_file_entry)?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(entries)
    }

    // ── OCR & Summary updates ─────────────────────────────────────────────────

    /// Update OCR text for a file.
    pub fn update_ocr_text(&self, id: &Uuid, text: &str) -> Result<(), CoreError> {
        self.conn.execute(
            "UPDATE files SET ocr_text = ?1 WHERE id = ?2",
            params![text, id.to_string()],
        )?;
        Ok(())
    }

    /// Update AI summary for a file.
    pub fn update_summary(&self, id: &Uuid, summary: &str) -> Result<(), CoreError> {
        self.conn.execute(
            "UPDATE files SET summary = ?1 WHERE id = ?2",
            params![summary, id.to_string()],
        )?;
        Ok(())
    }

    // ── FTS search ────────────────────────────────────────────────────────────

    /// Search files using FTS5 full-text index.
    /// Falls back to LIKE search if FTS query fails.
    pub fn search_fts(&self, query: &str) -> Result<Vec<FileEntry>, CoreError> {
        // Try FTS5 first
        let fts_result: Result<Vec<FileEntry>, rusqlite::Error> = (|| {
            let mut stmt = self.conn.prepare(
                r#"SELECT f.* FROM files f
                   INNER JOIN files_fts fts ON f.id = fts.id
                   WHERE files_fts MATCH ?1
                   ORDER BY rank
                   LIMIT 100"#,
            )?;
            let entries = stmt
                .query_map(params![query], Self::row_to_file_entry)?
                .collect::<Result<Vec<FileEntry>, rusqlite::Error>>()?;
            Ok(entries)
        })();

        match fts_result {
            Ok(entries) if !entries.is_empty() => Ok(entries),
            _ => {
                // Fallback to LIKE search
                self.search_files_by_text(query)
            }
        }
    }

    // ── Categories ────────────────────────────────────────────────────────────

    /// Get or create a category by name, returning its UUID.
    pub fn get_or_create_category(&self, name: &str) -> Result<Uuid, CoreError> {
        // Try to find existing
        let existing: Result<String, _> = self.conn.query_row(
            "SELECT id FROM categories WHERE name = ?1",
            params![name],
            |row| row.get(0),
        );

        if let Ok(id_str) = existing {
            return Ok(Uuid::parse_str(&id_str).unwrap_or_default());
        }

        // Create new
        let id = Uuid::new_v4();
        self.conn.execute(
            "INSERT OR IGNORE INTO categories (id, name, created_at) VALUES (?1, ?2, ?3)",
            params![id.to_string(), name, Utc::now().to_rfc3339()],
        )?;
        Ok(id)
    }

    /// Add a category to a file.
    pub fn add_category_to_file(
        &self,
        file_id: &Uuid,
        category_id: &Uuid,
    ) -> Result<(), CoreError> {
        self.conn.execute(
            "INSERT OR IGNORE INTO file_categories (file_id, category_id) VALUES (?1, ?2)",
            params![file_id.to_string(), category_id.to_string()],
        )?;
        Ok(())
    }

    /// Get categories for a file.
    pub fn get_categories_for_file(&self, file_id: &Uuid) -> Result<Vec<String>, CoreError> {
        let mut stmt = self.conn.prepare(
            "SELECT c.name FROM categories c INNER JOIN file_categories fc ON c.id = fc.category_id WHERE fc.file_id = ?1",
        )?;
        let cats = stmt
            .query_map(params![file_id.to_string()], |row| {
                row.get::<_, String>(0)
            })?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(cats)
    }

    /// Get files in a category by name.
    pub fn get_files_by_category(&self, category_name: &str) -> Result<Vec<FileEntry>, CoreError> {
        let mut stmt = self.conn.prepare(
            r#"SELECT f.* FROM files f
               INNER JOIN file_categories fc ON f.id = fc.file_id
               INNER JOIN categories c ON c.id = fc.category_id
               WHERE c.name = ?1
               ORDER BY f.created_at DESC LIMIT 200"#,
        )?;
        let entries = stmt
            .query_map(params![category_name], Self::row_to_file_entry)?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(entries)
    }

    /// List all categories with file counts.
    pub fn list_categories(&self) -> Result<Vec<(String, String, usize)>, CoreError> {
        let mut stmt = self.conn.prepare(
            r#"SELECT c.id, c.name, COUNT(fc.file_id) as cnt
               FROM categories c
               LEFT JOIN file_categories fc ON c.id = fc.category_id
               GROUP BY c.id, c.name
               ORDER BY cnt DESC"#,
        )?;
        let cats = stmt
            .query_map([], |row| {
                let id: String = row.get(0)?;
                let name: String = row.get(1)?;
                let count: i64 = row.get(2)?;
                Ok((id, name, count as usize))
            })?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(cats)
    }

    // ── Timeline ──────────────────────────────────────────────────────────────

    /// Get files grouped by date for timeline view.
    pub fn get_timeline_entries(
        &self,
        from: &str,
        to: &str,
        limit: usize,
    ) -> Result<Vec<FileEntry>, CoreError> {
        let mut stmt = self.conn.prepare(
            "SELECT * FROM files WHERE created_at >= ?1 AND created_at <= ?2 ORDER BY created_at DESC LIMIT ?3",
        )?;
        let entries = stmt
            .query_map(params![from, to, limit as i64], Self::row_to_file_entry)?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(entries)
    }

    // ── Search history ────────────────────────────────────────────────────────

    /// Save a search query for history.
    pub fn save_search_query(&self, query: &str, result_count: usize) -> Result<(), CoreError> {
        self.conn.execute(
            "INSERT INTO search_history (query, result_count, searched_at) VALUES (?1, ?2, ?3)",
            params![query, result_count as i64, Utc::now().to_rfc3339()],
        )?;
        Ok(())
    }

    /// Get recent search history.
    pub fn get_search_history(&self, limit: usize) -> Result<Vec<String>, CoreError> {
        let mut stmt = self.conn.prepare(
            "SELECT DISTINCT query FROM search_history ORDER BY searched_at DESC LIMIT ?1",
        )?;
        let history = stmt
            .query_map(params![limit as i64], |row| row.get::<_, String>(0))?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(history)
    }

    // ── Processing queue ──────────────────────────────────────────────────────

    /// Enqueue a file for processing.
    pub fn enqueue_processing(&self, file_id: &Uuid) -> Result<(), CoreError> {
        self.conn.execute(
            "INSERT OR IGNORE INTO processing_queue (file_id, stage, queued_at) VALUES (?1, 'pending', ?2)",
            params![file_id.to_string(), Utc::now().to_rfc3339()],
        )?;
        Ok(())
    }

    /// Update processing stage for a file.
    pub fn update_processing_stage(
        &self,
        file_id: &Uuid,
        stage: &str,
        progress: i32,
    ) -> Result<(), CoreError> {
        self.conn.execute(
            "UPDATE processing_queue SET stage = ?1, progress = ?2, started_at = COALESCE(started_at, ?3) WHERE file_id = ?4 AND completed_at IS NULL",
            params![stage, progress, Utc::now().to_rfc3339(), file_id.to_string()],
        )?;
        Ok(())
    }

    /// Mark processing as completed.
    pub fn complete_processing(&self, file_id: &Uuid) -> Result<(), CoreError> {
        self.conn.execute(
            "UPDATE processing_queue SET stage = 'completed', progress = 100, completed_at = ?1 WHERE file_id = ?2 AND completed_at IS NULL",
            params![Utc::now().to_rfc3339(), file_id.to_string()],
        )?;
        Ok(())
    }

    /// Get pending processing count.
    pub fn pending_processing_count(&self) -> Result<usize, CoreError> {
        let count: i64 = self.conn.query_row(
            "SELECT COUNT(*) FROM processing_queue WHERE completed_at IS NULL",
            [],
            |row| row.get(0),
        )?;
        Ok(count as usize)
    }

    /// Get files by type.
    pub fn get_files_by_type(&self, file_type: &str, limit: usize) -> Result<Vec<FileEntry>, CoreError> {
        let mut stmt = self.conn.prepare(
            "SELECT * FROM files WHERE file_type = ?1 ORDER BY created_at DESC LIMIT ?2",
        )?;
        let entries = stmt
            .query_map(params![file_type, limit as i64], Self::row_to_file_entry)?
            .collect::<Result<Vec<_>, _>>()?;
        Ok(entries)
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
            is_favorite: row.get("is_favorite")?,
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

    #[test]
    fn test_toggle_favorite() {
        let db = test_db();
        let entry = FileEntry::new("/fav.txt", FileType::Text, 100);
        db.insert_file(&entry).unwrap();

        // Initially no favorites
        assert!(db.list_favorites().unwrap().is_empty());

        // Toggle on
        db.toggle_favorite(&entry.id).unwrap();
        let favs = db.list_favorites().unwrap();
        assert_eq!(favs.len(), 1);
        assert_eq!(favs[0].id, entry.id);

        // Toggle off
        db.toggle_favorite(&entry.id).unwrap();
        assert!(db.list_favorites().unwrap().is_empty());
    }

    #[test]
    fn test_recent_files() {
        let db = test_db();
        db.insert_file(&FileEntry::new("/old.txt", FileType::Text, 10))
            .unwrap();
        db.insert_file(&FileEntry::new("/new.txt", FileType::Text, 20))
            .unwrap();

        let recent = db.recent_files(1).unwrap();
        assert_eq!(recent.len(), 1);

        let recent_all = db.recent_files(10).unwrap();
        assert_eq!(recent_all.len(), 2);
    }

    #[test]
    fn test_delete_file() {
        let db = test_db();
        let entry = FileEntry::new("/delete_me.txt", FileType::Text, 10);
        db.insert_file(&entry).unwrap();
        assert_eq!(db.count_files().unwrap(), 1);

        db.delete_file(&entry.id).unwrap();
        assert_eq!(db.count_files().unwrap(), 0);
    }

    #[test]
    fn test_set_encrypted() {
        let db = test_db();
        let entry = FileEntry::new("/secret.txt", FileType::Text, 10);
        db.insert_file(&entry).unwrap();

        db.set_encrypted(&entry.id, true).unwrap();
        let encrypted = db.list_encrypted_files().unwrap();
        assert_eq!(encrypted.len(), 1);

        db.set_encrypted(&entry.id, false).unwrap();
        assert!(db.list_encrypted_files().unwrap().is_empty());
    }

    #[test]
    fn test_tags_crud() {
        let db = test_db();
        let tag = crate::models::Tag::new("important");
        db.insert_tag(&tag).unwrap();

        let tags = db.list_tags().unwrap();
        assert_eq!(tags.len(), 1);
        assert_eq!(tags[0].name, "important");

        // Tag a file
        let entry = FileEntry::new("/tagged.txt", FileType::Text, 10);
        db.insert_file(&entry).unwrap();
        db.add_tag_to_file(&entry.id, &tag.id).unwrap();

        let file_tags = db.get_tags_for_file(&entry.id).unwrap();
        assert_eq!(file_tags.len(), 1);
        assert_eq!(file_tags[0], "important");
    }

    #[test]
    fn test_collections_crud() {
        let db = test_db();
        let col = crate::models::Collection::new("My Collection");
        db.insert_collection(&col).unwrap();

        let cols = db.list_collections().unwrap();
        assert_eq!(cols.len(), 1);
        assert_eq!(cols[0].name, "My Collection");

        let entry = FileEntry::new("/in_collection.txt", FileType::Text, 10);
        db.insert_file(&entry).unwrap();
        db.add_file_to_collection(&col.id, &entry.id).unwrap();

        let files = db.get_files_in_collection(&col.id).unwrap();
        assert_eq!(files.len(), 1);

        db.delete_collection(&col.id).unwrap();
        assert!(db.list_collections().unwrap().is_empty());
    }

    #[test]
    fn test_get_large_files() {
        let db = test_db();
        db.insert_file(&FileEntry::new("/small.txt", FileType::Text, 100))
            .unwrap();
        db.insert_file(&FileEntry::new("/big.bin", FileType::Unknown, 100_000_000))
            .unwrap();

        let large = db.get_large_files(50_000_000).unwrap();
        assert_eq!(large.len(), 1);
        assert_eq!(large[0].filename, "big.bin");
    }

    #[test]
    fn test_total_size_bytes() {
        let db = test_db();
        db.insert_file(&FileEntry::new("/a.txt", FileType::Text, 100))
            .unwrap();
        db.insert_file(&FileEntry::new("/b.txt", FileType::Text, 200))
            .unwrap();
        assert_eq!(db.total_size_bytes().unwrap(), 300);
    }

    #[test]
    fn test_activity_log() {
        let db = test_db();
        db.log_activity("file_opened", None, Some("test detail"))
            .unwrap();
        // Activity log is write-only in this API; just verify no panic
    }

    #[test]
    fn test_update_file_hash() {
        let db = test_db();
        let entry = FileEntry::new("/hashme.txt", FileType::Text, 10);
        db.insert_file(&entry).unwrap();

        db.update_file_hash(&entry.id, "abc123hash").unwrap();
        let updated = db.get_file_by_id(&entry.id).unwrap().unwrap();
        assert_eq!(updated.sha256_hash, Some("abc123hash".to_string()));
    }
}
