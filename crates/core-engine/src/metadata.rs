#![allow(unused_imports, dead_code)]

//! Metadata extraction from files (EXIF, PDF info, audio tags, etc.)

use crate::error::CoreError;
use crate::models::{FileEntry, FileType};
use std::fs;
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

    // Use file system created time (when available)
    if let Ok(created) = metadata.created() {
        use chrono::{DateTime, Utc};
        entry.created_at = DateTime::<Utc>::from(created);
    }

    debug!(path = %entry.path, file_type = ?entry.file_type, size = entry.size_bytes, "Metadata extracted");
    Ok(())
}

/// Extract text content from readable file types for search indexing.
/// Returns the text content that can be used for OCR text field and categorization.
pub fn extract_text_content(path: &str) -> Option<String> {
    let file_path = Path::new(path);
    if !file_path.exists() {
        return None;
    }

    let ext = file_path
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("")
        .to_lowercase();

    match ext.as_str() {
        // Plain text files — read directly
        "txt" | "log" | "conf" | "ini" | "env" | "csv" => read_text_file(path, 50_000),

        // Markdown files — read directly (markdown is readable as-is)
        "md" | "markdown" | "mdx" | "rst" => read_text_file(path, 50_000),

        // HTML files — strip tags and extract text
        "html" | "htm" => read_text_file(path, 100_000).map(|html| strip_html_tags(&html)),

        // Code files — read as text for indexing
        "py" | "js" | "ts" | "dart" | "rs" | "go" | "java" | "kt" | "swift" | "c" | "cpp"
        | "h" | "cs" | "rb" | "php" | "sh" | "bash" | "json" | "yaml" | "yml" | "toml"
        | "xml" | "css" | "sql" | "tf" => read_text_file(path, 30_000),

        _ => None,
    }
}

/// Read text file content up to a maximum number of bytes.
fn read_text_file(path: &str, max_bytes: usize) -> Option<String> {
    match fs::read(path) {
        Ok(bytes) => {
            let truncated = if bytes.len() > max_bytes {
                &bytes[..max_bytes]
            } else {
                &bytes
            };
            String::from_utf8(truncated.to_vec()).ok().or_else(|| {
                // Try lossy conversion for non-UTF8 files
                Some(String::from_utf8_lossy(truncated).into_owned())
            })
        }
        Err(_) => None,
    }
}

/// Strip HTML tags and return plain text.
fn strip_html_tags(html: &str) -> String {
    let mut result = String::with_capacity(html.len());
    let mut in_tag = false;

    for c in html.chars() {
        if c == '<' {
            in_tag = true;
        } else if c == '>' {
            in_tag = false;
            result.push(' ');
        } else if !in_tag {
            result.push(c);
        }
    }

    // Collapse whitespace
    let mut prev_space = false;
    let collapsed: String = result
        .chars()
        .filter(|c| {
            if c.is_whitespace() {
                if prev_space {
                    return false;
                }
                prev_space = true;
            } else {
                prev_space = false;
            }
            true
        })
        .collect();

    collapsed.trim().to_string()
}

/// Generate a brief text summary from content (first N words).
/// This is a fast offline summary that doesn't require an AI model.
pub fn generate_excerpt(text: &str, max_words: usize) -> String {
    let words: Vec<&str> = text.split_whitespace().collect();
    if words.len() <= max_words {
        words.join(" ")
    } else {
        format!("{}…", words[..max_words].join(" "))
    }
}

/// Determine MIME type from file extension.
pub fn mime_from_extension(ext: &str) -> &'static str {
    match ext.to_lowercase().as_str() {
        "jpg" | "jpeg" => "image/jpeg",
        "png" => "image/png",
        "gif" => "image/gif",
        "webp" => "image/webp",
        "bmp" => "image/bmp",
        "tiff" | "tif" => "image/tiff",
        "heic" | "heif" => "image/heif",
        "svg" => "image/svg+xml",
        "pdf" => "application/pdf",
        "docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "pptx" => "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        "epub" => "application/epub+zip",
        "mp4" => "video/mp4",
        "mkv" => "video/x-matroska",
        "avi" => "video/x-msvideo",
        "mov" => "video/quicktime",
        "webm" => "video/webm",
        "mp3" => "audio/mpeg",
        "wav" => "audio/wav",
        "flac" => "audio/flac",
        "aac" => "audio/aac",
        "ogg" => "audio/ogg",
        "m4a" => "audio/mp4",
        "txt" => "text/plain",
        "md" | "markdown" => "text/markdown",
        "html" | "htm" => "text/html",
        "css" => "text/css",
        "json" => "application/json",
        "xml" => "application/xml",
        "zip" => "application/zip",
        "tar" => "application/x-tar",
        "gz" => "application/gzip",
        "7z" => "application/x-7z-compressed",
        "rar" => "application/vnd.rar",
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

    #[test]
    fn test_strip_html_tags() {
        let html = "<h1>Title</h1><p>Hello <strong>world</strong></p>";
        let text = strip_html_tags(html);
        assert!(text.contains("Title"));
        assert!(text.contains("Hello"));
        assert!(text.contains("world"));
        assert!(!text.contains("<"));
    }

    #[test]
    fn test_generate_excerpt() {
        let text = "The quick brown fox jumps over the lazy dog and runs away";
        let excerpt = generate_excerpt(text, 5);
        assert_eq!(excerpt, "The quick brown fox jumps…");
    }

    #[test]
    fn test_generate_excerpt_short_text() {
        let text = "Hello world";
        let excerpt = generate_excerpt(text, 10);
        assert_eq!(excerpt, "Hello world");
    }
}
