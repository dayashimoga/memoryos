//! Metadata extraction from files (EXIF, PDF info, audio tags, etc.)

use crate::error::CoreError;
use crate::models::{FileEntry, FileType};
use std::path::Path;
use tracing::debug;

/// Extract metadata from a file and populate fields on the FileEntry.
pub fn extract_metadata(entry: &mut FileEntry) -> Result<(), CoreError> {
    let path = Path::new(&entry.path);

    if !path.exists() {
        return Err(CoreError::FileNotFound {
            path: entry.path.clone(),
        });
    }

    let metadata = std::fs::metadata(path)?;
    entry.size_bytes = metadata.len();

    // Use file system modified time
    if let Ok(modified) = metadata.modified() {
        use chrono::{DateTime, Utc};
        entry.modified_at = DateTime::<Utc>::from(modified);
    }

    debug!(path = %entry.path, file_type = ?entry.file_type, "Metadata extracted");
    Ok(())
}

/// Determine MIME type from file extension.
pub fn mime_from_extension(ext: &str) -> &'static str {
    match ext.to_lowercase().as_str() {
        "jpg" | "jpeg" => "image/jpeg",
        "png" => "image/png",
        "gif" => "image/gif",
        "webp" => "image/webp",
        "pdf" => "application/pdf",
        "docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "mp4" => "video/mp4",
        "mp3" => "audio/mpeg",
        "wav" => "audio/wav",
        "txt" => "text/plain",
        "md" => "text/markdown",
        "html" | "htm" => "text/html",
        _ => "application/octet-stream",
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mime_from_extension() {
        assert_eq!(mime_from_extension("jpg"), "image/jpeg");
        assert_eq!(mime_from_extension("PDF"), "application/pdf");
        assert_eq!(mime_from_extension("mp4"), "video/mp4");
        assert_eq!(mime_from_extension("xyz"), "application/octet-stream");
    }
}
