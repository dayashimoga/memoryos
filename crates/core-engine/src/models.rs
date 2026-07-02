//! Domain models for MemoryOS.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Represents a file entry tracked by MemoryOS.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileEntry {
    pub id: Uuid,
    pub path: String,
    pub filename: String,
    pub extension: String,
    pub file_type: FileType,
    pub size_bytes: u64,
    pub sha256_hash: Option<String>,
    pub phash: Option<String>,
    pub ocr_text: Option<String>,
    pub summary: Option<String>,
    pub embedding_id: Option<i64>,
    pub tags: Vec<String>,
    pub collection_ids: Vec<Uuid>,
    pub is_encrypted: bool,
    pub is_favorite: bool,
    pub indexing_status: IndexingStatus,
    pub created_at: DateTime<Utc>,
    pub modified_at: DateTime<Utc>,
    pub indexed_at: Option<DateTime<Utc>>,
}

impl FileEntry {
    pub fn new(path: impl Into<String>, file_type: FileType, size_bytes: u64) -> Self {
        let path = path.into();
        let filename = std::path::Path::new(&path)
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or(&path)
            .to_string();
        let extension = std::path::Path::new(&path)
            .extension()
            .and_then(|e| e.to_str())
            .unwrap_or("")
            .to_lowercase();

        Self {
            id: Uuid::new_v4(),
            path,
            filename,
            extension,
            file_type,
            size_bytes,
            sha256_hash: None,
            phash: None,
            ocr_text: None,
            summary: None,
            embedding_id: None,
            tags: Vec::new(),
            collection_ids: Vec::new(),
            is_encrypted: false,
            is_favorite: false,
            indexing_status: IndexingStatus::Pending,
            created_at: Utc::now(),
            modified_at: Utc::now(),
            indexed_at: None,
        }
    }
}

/// File type classification.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum FileType {
    Image,
    Screenshot,
    Document,
    Spreadsheet,
    Video,
    Audio,
    Archive,
    Email,
    Chat,
    Markdown,
    Html,
    Text,
    Unknown,
}

impl FileType {
    pub fn from_extension(ext: &str) -> Self {
        match ext.to_lowercase().as_str() {
            "jpg" | "jpeg" | "png" | "gif" | "bmp" | "webp" | "heic" | "tiff" => Self::Image,
            "pdf" => Self::Document,
            "docx" | "doc" | "odt" | "rtf" => Self::Document,
            "xlsx" | "xls" | "csv" | "ods" => Self::Spreadsheet,
            "mp4" | "mkv" | "avi" | "mov" | "webm" => Self::Video,
            "mp3" | "wav" | "flac" | "aac" | "ogg" | "m4a" => Self::Audio,
            "zip" | "tar" | "gz" | "7z" | "rar" => Self::Archive,
            "eml" | "mbox" => Self::Email,
            "md" | "markdown" => Self::Markdown,
            "html" | "htm" => Self::Html,
            "txt" | "log" => Self::Text,
            _ => Self::Unknown,
        }
    }
}

/// Indexing status for a file.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum IndexingStatus {
    Pending,
    InProgress,
    Completed,
    Failed,
    Skipped,
}

/// A user-defined or AI-generated tag.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Tag {
    pub id: Uuid,
    pub name: String,
    pub color: Option<String>,
    pub created_at: DateTime<Utc>,
}

impl Tag {
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            id: Uuid::new_v4(),
            name: name.into(),
            color: None,
            created_at: Utc::now(),
        }
    }
}

/// A collection of related files.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Collection {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub icon: Option<String>,
    pub file_count: usize,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl Collection {
    pub fn new(name: impl Into<String>) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4(),
            name: name.into(),
            description: None,
            icon: None,
            file_count: 0,
            created_at: now,
            updated_at: now,
        }
    }
}

/// Application-wide user settings.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserSettings {
    pub watch_directories: Vec<String>,
    pub auto_index: bool,
    pub ocr_enabled: bool,
    pub ai_enabled: bool,
    pub duplicate_detection: bool,
    pub vault_enabled: bool,
    pub theme: Theme,
    pub language: String,
    pub ai_model: Option<String>,
    pub max_index_threads: usize,
}

impl Default for UserSettings {
    fn default() -> Self {
        Self {
            watch_directories: Vec::new(),
            auto_index: true,
            ocr_enabled: true,
            ai_enabled: true,
            duplicate_detection: true,
            vault_enabled: false,
            theme: Theme::System,
            language: "en".to_string(),
            ai_model: None,
            max_index_threads: num_cpus(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Theme {
    Light,
    Dark,
    System,
}

fn num_cpus() -> usize {
    std::thread::available_parallelism()
        .map(|n| n.get().min(4))
        .unwrap_or(2)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_file_type_from_extension() {
        assert_eq!(FileType::from_extension("png"), FileType::Image);
        assert_eq!(FileType::from_extension("PDF"), FileType::Document);
        assert_eq!(FileType::from_extension("mp3"), FileType::Audio);
        assert_eq!(FileType::from_extension("mp4"), FileType::Video);
        assert_eq!(FileType::from_extension("xyz"), FileType::Unknown);
    }

    #[test]
    fn test_file_entry_new() {
        let entry = FileEntry::new("/home/user/doc.pdf", FileType::Document, 1024);
        assert_eq!(entry.filename, "doc.pdf");
        assert_eq!(entry.extension, "pdf");
        assert_eq!(entry.indexing_status, IndexingStatus::Pending);
        assert!(!entry.is_encrypted);
    }

    #[test]
    fn test_tag_new() {
        let tag = Tag::new("AWS");
        assert_eq!(tag.name, "AWS");
        assert!(tag.color.is_none());
    }

    #[test]
    fn test_collection_new() {
        let col = Collection::new("Chess Learning");
        assert_eq!(col.name, "Chess Learning");
        assert_eq!(col.file_count, 0);
    }

    #[test]
    fn test_user_settings_default() {
        let settings = UserSettings::default();
        assert!(settings.auto_index);
        assert!(settings.ocr_enabled);
        assert_eq!(settings.language, "en");
    }
}
