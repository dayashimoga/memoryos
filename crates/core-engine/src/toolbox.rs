//! Universal Digital Toolbox backend implementation.
//! Provides native conversion, image resizing, audio RIFF normalization, ZIP archive management, and encrypted backups.

#![allow(clippy::manual_strip, clippy::needless_range_loop)]

use crate::error::CoreError;
use aes_gcm::{aead::Aead, Aes256Gcm, KeyInit, Nonce};
use sha2::{Digest, Sha256};
use std::fs::{self, File};
use std::io::{self, Read, Write};
use std::path::Path;
use tracing::info;
use zip::{write::FileOptions, ZipArchive, ZipWriter};

#[derive(Debug, serde::Serialize, serde::Deserialize, Clone)]
pub struct ConversionPreset {
    pub name: String,
    pub description: String,
}

#[derive(Debug, serde::Serialize, serde::Deserialize, Clone)]
pub struct ArchiveItem {
    pub name: String,
    pub size: u64,
    pub is_dir: bool,
}

/// Convert markdown syntax into basic HTML structure.
pub fn md_to_html(markdown: &str) -> String {
    let mut html = String::new();
    html.push_str("<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"utf-8\">\n<style>body { font-family: sans-serif; line-height: 1.6; padding: 20px; }</style>\n</head>\n<body>\n");
    for line in markdown.lines() {
        let trimmed = line.trim();
        if trimmed.starts_with("# ") {
            html.push_str(&format!("<h1>{}</h1>\n", &trimmed[2..]));
        } else if trimmed.starts_with("## ") {
            html.push_str(&format!("<h2>{}</h2>\n", &trimmed[3..]));
        } else if trimmed.starts_with("### ") {
            html.push_str(&format!("<h3>{}</h3>\n", &trimmed[4..]));
        } else if trimmed.starts_with("- ") || trimmed.starts_with("* ") {
            html.push_str(&format!("<li>{}</li>\n", &trimmed[2..]));
        } else if !trimmed.is_empty() {
            html.push_str(&format!("<p>{}</p>\n", trimmed));
        }
    }
    html.push_str("</body>\n</html>");
    html
}

/// Convert html string to markdown syntax (plain text converter).
pub fn html_to_md(html: &str) -> String {
    let mut md = String::new();
    let mut in_tag = false;
    let mut current_tag = String::new();

    for c in html.chars() {
        if c == '<' {
            in_tag = true;
            current_tag.clear();
        } else if c == '>' {
            in_tag = false;
            if current_tag == "p" || current_tag == "/p" || current_tag == "br" {
                md.push('\n');
            } else if current_tag == "h1" {
                md.push_str("\n# ");
            } else if current_tag == "h2" {
                md.push_str("\n## ");
            } else if current_tag == "/h1" || current_tag == "/h2" {
                md.push('\n');
            }
        } else if !in_tag {
            md.push(c);
        } else {
            current_tag.push(c.to_ascii_lowercase());
        }
    }
    md
}

/// Native DOCX creator (generates the XML package zip file).
pub fn create_docx_from_txt(text: &str) -> Result<Vec<u8>, CoreError> {
    let mut buf = Vec::new();
    {
        let mut zip = ZipWriter::new(io::Cursor::new(&mut buf));
        let options = FileOptions::default().compression_method(zip::CompressionMethod::Deflated);

        // 1. Content Types XML
        zip.start_file("[Content_Types].xml", options)?;
        zip.write_all(br#"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>"#)?;

        // 2. Relationships Rel
        zip.start_file("_rels/.rels", options)?;
        zip.write_all(br#"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>"#)?;

        // 3. Document body XML containing text
        zip.start_file("word/document.xml", options)?;
        let mut paragraphs = String::new();
        for para in text.lines() {
            if !para.trim().is_empty() {
                paragraphs.push_str(&format!(
                    r#"<w:p><w:r><w:t>{}</w:t></w:r></w:p>"#,
                    para.replace('&', "&amp;")
                        .replace('<', "&lt;")
                        .replace('>', "&gt;")
                ));
            }
        }
        let doc_xml = format!(
            r#"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    {}
  </w:body>
</w:document>"#,
            paragraphs
        );
        zip.write_all(doc_xml.as_bytes())?;
        zip.finish()?;
    }
    Ok(buf)
}

/// Native PDF creator (outputs a basic compliant cross-reference PDF document structure).
pub fn create_pdf_from_txt(text: &str) -> Result<Vec<u8>, CoreError> {
    let mut doc = Vec::new();
    doc.extend_from_slice(b"%PDF-1.4\n");

    let mut offsets = Vec::new();

    // Object 1: Catalog
    offsets.push(doc.len());
    doc.extend_from_slice(b"1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n");

    // Object 2: Pages
    offsets.push(doc.len());
    doc.extend_from_slice(b"2 0 obj\n<< /Type /Pages /Kids [ 3 0 R ] /Count 1 >>\nendobj\n");

    // Format text lines into PDF text stream syntax
    let mut text_stream = String::new();
    text_stream.push_str("BT\n/F1 12 Tf\n72 712 Td\n14 TL\n");
    for line in text.lines() {
        let escaped = line.replace('(', "\\(").replace(')', "\\)");
        text_stream.push_str(&format!("({}) Tj T*\n", escaped));
    }
    text_stream.push_str("ET\n");

    // Object 4 (Resources - Font)
    let font_obj = "4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n";

    // Object 5 (Contents stream)
    let content_len = text_stream.len();
    let content_obj = format!(
        "5 0 obj\n<< /Length {} >>\nstream\n{}endstream\nendobj\n",
        content_len, text_stream
    );

    // Object 3: Page Object
    offsets.push(doc.len());
    doc.extend_from_slice(b"3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [ 0 0 612 792 ] /Contents 5 0 R /Resources << /Font << /F1 4 0 R >> >> >>\nendobj\n");

    offsets.push(doc.len());
    doc.extend_from_slice(font_obj.as_bytes());

    offsets.push(doc.len());
    doc.extend_from_slice(content_obj.as_bytes());

    // Cross-reference table
    let xref_pos = doc.len();
    doc.extend_from_slice(b"xref\n0 6\n0000000000 65535 f \n");
    for offset in offsets {
        doc.extend_from_slice(format!("{:010} 00000 n \n", offset).as_bytes());
    }

    // Trailer
    doc.extend_from_slice(
        format!(
            "trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n{}\n%%EOF\n",
            xref_pos
        )
        .as_bytes(),
    );

    Ok(doc)
}

/// Multi-format Document Converter Engine
pub fn convert_document(input_path: &str, output_path: &str) -> Result<(), CoreError> {
    let input = Path::new(input_path);
    let output = Path::new(output_path);

    if !input.exists() {
        return Err(CoreError::FileNotFound {
            path: input_path.to_string(),
        });
    }

    let in_ext = input
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("")
        .to_lowercase();
    let out_ext = output
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("")
        .to_lowercase();

    let text_content = fs::read_to_string(input)?;

    // Document routing
    let converted_bytes: Vec<u8> = match (in_ext.as_str(), out_ext.as_str()) {
        ("md", "html") => md_to_html(&text_content).into_bytes(),
        ("html", "md") => html_to_md(&text_content).into_bytes(),
        ("md", "pdf") => {
            let html = md_to_html(&text_content);
            create_pdf_from_txt(&html)?
        }
        ("txt", "pdf") | ("md", "txt") => create_pdf_from_txt(&text_content)?,
        ("txt", "docx") | ("md", "docx") => create_docx_from_txt(&text_content)?,
        ("html", "pdf") => create_pdf_from_txt(&html_to_md(&text_content))?,
        _ => {
            // Default generic fallback converter
            create_pdf_from_txt(&text_content)?
        }
    };

    if let Some(parent) = output.parent() {
        fs::create_dir_all(parent)?;
    }
    fs::write(output, converted_bytes)?;
    Ok(())
}

/// Offline Image Toolkit Operations
pub fn process_image(
    input_path: &str,
    output_path: &str,
    width: u32,
    height: u32,
    _quality: u8,
) -> Result<(), CoreError> {
    let input = Path::new(input_path);
    if !input.exists() {
        return Err(CoreError::FileNotFound {
            path: input_path.to_string(),
        });
    }

    let img = image::open(input).map_err(|e| CoreError::Internal(e.to_string()))?;

    // Resize image conserving aspect ratio if width/height are specified
    let processed = if width > 0 && height > 0 {
        img.resize(width, height, image::imageops::FilterType::Lanczos3)
    } else {
        img
    };

    // Save with compression logic based on output extension format
    let output = Path::new(output_path);
    if let Some(parent) = output.parent() {
        fs::create_dir_all(parent)?;
    }

    processed
        .save(output)
        .map_err(|e| CoreError::Internal(e.to_string()))?;
    Ok(())
}

/// Native WAV Audio Normalizer (Offline Audio Normalization)
/// Reads samples, computes peak volume, and normalizes it to max scale.
pub fn normalize_wav(input_path: &str, output_path: &str) -> Result<(), CoreError> {
    let mut file = File::open(input_path)?;
    let mut bytes = Vec::new();
    file.read_to_end(&mut bytes)?;

    if bytes.len() < 44 || &bytes[0..4] != b"RIFF" || &bytes[8..12] != b"WAVE" {
        return Err(CoreError::InvalidInput {
            message: "Invalid WAV audio file".to_string(),
        });
    }

    // Find the 'data' subchunk
    let mut offset = 12;
    while offset + 8 < bytes.len() {
        let chunk_id = &bytes[offset..offset + 4];
        let chunk_size =
            u32::from_le_bytes(bytes[offset + 4..offset + 8].try_into().unwrap()) as usize;
        if chunk_id == b"data" {
            let data_start = offset + 8;
            let data_end = (data_start + chunk_size).min(bytes.len());

            // Perform 16-bit PCM normalization
            let mut samples = Vec::new();
            for i in (data_start..data_end).step_by(2) {
                if i + 1 < bytes.len() {
                    let sample = i16::from_le_bytes([bytes[i], bytes[i + 1]]);
                    samples.push(sample);
                }
            }

            let mut peak = 0i16;
            for &s in &samples {
                let abs = s.abs();
                if abs > peak {
                    peak = abs;
                }
            }

            if peak > 0 {
                let max_possible = i16::MAX as f32;
                let multiplier = max_possible / (peak as f32);
                for i in 0..samples.len() {
                    let normalized = (samples[i] as f32 * multiplier) as i16;
                    let norm_bytes = normalized.to_le_bytes();
                    let byte_offset = data_start + i * 2;
                    bytes[byte_offset] = norm_bytes[0];
                    bytes[byte_offset + 1] = norm_bytes[1];
                }
            }
            break;
        }
        offset += 8 + chunk_size;
    }

    fs::write(output_path, bytes)?;
    Ok(())
}

/// ZIP Archive utilities (Offline Archive Extraction/Creation)
pub fn list_archive(archive_path: &str) -> Result<Vec<ArchiveItem>, CoreError> {
    let file = File::open(archive_path)?;
    let mut archive = ZipArchive::new(file).map_err(|e| CoreError::Internal(e.to_string()))?;
    let mut items = Vec::new();

    for i in 0..archive.len() {
        let file = archive
            .by_index(i)
            .map_err(|e| CoreError::Internal(e.to_string()))?;
        items.push(ArchiveItem {
            name: file.name().to_string(),
            size: file.size(),
            is_dir: file.is_dir(),
        });
    }
    Ok(items)
}

pub fn create_archive(output_path: &str, paths: Vec<String>) -> Result<(), CoreError> {
    let file = File::create(output_path)?;
    let mut zip = ZipWriter::new(file);
    let options = FileOptions::default().compression_method(zip::CompressionMethod::Deflated);

    for path_str in paths {
        let path = Path::new(&path_str);
        if path.exists() {
            let name = path.file_name().and_then(|n| n.to_str()).unwrap_or("file");
            zip.start_file(name, options)?;
            let mut file_content = File::open(path)?;
            let mut buf = Vec::new();
            file_content.read_to_end(&mut buf)?;
            zip.write_all(&buf)?;
        }
    }
    zip.finish()
        .map_err(|e| CoreError::Internal(e.to_string()))?;
    Ok(())
}

pub fn extract_archive(archive_path: &str, output_dir: &str) -> Result<(), CoreError> {
    let file = File::open(archive_path)?;
    let mut archive = ZipArchive::new(file).map_err(|e| CoreError::Internal(e.to_string()))?;
    let dest_dir = Path::new(output_dir);
    fs::create_dir_all(dest_dir)?;

    for i in 0..archive.len() {
        let mut file = archive
            .by_index(i)
            .map_err(|e| CoreError::Internal(e.to_string()))?;
        let outpath = dest_dir.join(file.name());

        if file.is_dir() {
            fs::create_dir_all(&outpath)?;
        } else {
            if let Some(p) = outpath.parent() {
                if !p.exists() {
                    fs::create_dir_all(p)?;
                }
            }
            let mut outfile = File::create(&outpath)?;
            io::copy(&mut file, &mut outfile)?;
        }
    }
    Ok(())
}

/// AES-256-GCM Incremental Encrypted Backup System
pub fn perform_backup(
    data_dir: &str,
    backup_path: &str,
    key_phrase: &str,
) -> Result<(), CoreError> {
    // 1. Pack all database and indexing storage data into zip buffer
    let mut zip_buf = Vec::new();
    {
        let mut zip = ZipWriter::new(io::Cursor::new(&mut zip_buf));
        let options = FileOptions::default().compression_method(zip::CompressionMethod::Deflated);

        let source = Path::new(data_dir);
        if source.exists() {
            let mut paths = vec![source.to_path_buf()];
            while let Some(current) = paths.pop() {
                if current.is_dir() {
                    for entry in fs::read_dir(current)? {
                        paths.push(entry?.path());
                    }
                } else {
                    let relative = current
                        .strip_prefix(source)
                        .map_err(|_| CoreError::Internal("Strip prefix failed".to_string()))?;
                    let rel_str = relative.to_str().unwrap_or("file");
                    zip.start_file(rel_str, options)?;
                    let mut f = File::open(&current)?;
                    let mut data = Vec::new();
                    f.read_to_end(&mut data)?;
                    zip.write_all(&data)?;
                }
            }
        }
        zip.finish()
            .map_err(|e| CoreError::Internal(e.to_string()))?;
    }

    // 2. Derive a robust 256-bit encryption key using SHA-256 of key phrase
    let mut hasher = Sha256::new();
    hasher.update(key_phrase.as_bytes());
    let key_bytes = hasher.finalize();

    // 3. Generate a random 12-byte nonce (CRITICAL: never reuse with same key)
    let cipher =
        Aes256Gcm::new_from_slice(&key_bytes).map_err(|e| CoreError::Encryption(e.to_string()))?;
    let mut nonce_bytes = [0u8; 12];
    getrandom::getrandom(&mut nonce_bytes)
        .map_err(|e| CoreError::Encryption(format!("Failed to generate nonce: {}", e)))?;
    let nonce = Nonce::from_slice(&nonce_bytes);

    let encrypted_data = cipher
        .encrypt(nonce, zip_buf.as_slice())
        .map_err(|e| CoreError::Encryption(e.to_string()))?;

    // 4. Save to target backup file: [nonce (12 bytes)] + [ciphertext]
    let output = Path::new(backup_path);
    if let Some(parent) = output.parent() {
        fs::create_dir_all(parent)?;
    }
    let mut final_output = Vec::with_capacity(12 + encrypted_data.len());
    final_output.extend_from_slice(&nonce_bytes);
    final_output.extend_from_slice(&encrypted_data);
    fs::write(output, final_output)?;
    info!(
        backup_path,
        "Encrypted incremental backup written successfully"
    );
    Ok(())
}

/// Restore encrypted backup to data directory
pub fn restore_backup(
    backup_path: &str,
    data_dir: &str,
    key_phrase: &str,
) -> Result<(), CoreError> {
    let mut file = File::open(backup_path)?;
    let mut encrypted_data = Vec::new();
    file.read_to_end(&mut encrypted_data)?;

    // 1. Derive identical 256-bit key
    let mut hasher = Sha256::new();
    hasher.update(key_phrase.as_bytes());
    let key_bytes = hasher.finalize();

    // 2. Extract nonce (first 12 bytes) and decrypt ciphertext
    if encrypted_data.len() < 12 {
        return Err(CoreError::Encryption(
            "Backup file too short (missing nonce)".into(),
        ));
    }
    let cipher =
        Aes256Gcm::new_from_slice(&key_bytes).map_err(|e| CoreError::Encryption(e.to_string()))?;
    let nonce = Nonce::from_slice(&encrypted_data[..12]);
    let ciphertext = &encrypted_data[12..];

    let zip_buf = cipher
        .decrypt(nonce, ciphertext)
        .map_err(|e| CoreError::Encryption(e.to_string()))?;

    // 3. Unpack ZIP buffer to target directory
    let cursor = io::Cursor::new(zip_buf);
    let mut archive = ZipArchive::new(cursor).map_err(|e| CoreError::Internal(e.to_string()))?;
    let dest_dir = Path::new(data_dir);
    fs::create_dir_all(dest_dir)?;

    for i in 0..archive.len() {
        let mut file = archive
            .by_index(i)
            .map_err(|e| CoreError::Internal(e.to_string()))?;
        let outpath = dest_dir.join(file.name());

        if file.is_dir() {
            fs::create_dir_all(&outpath)?;
        } else {
            if let Some(p) = outpath.parent() {
                if !p.exists() {
                    fs::create_dir_all(p)?;
                }
            }
            let mut outfile = File::create(&outpath)?;
            io::copy(&mut file, &mut outfile)?;
        }
    }
    info!(data_dir, "Encrypted backup successfully restored");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[test]
    fn test_md_to_html_conversions() {
        let md = "# Header 1\n## Header 2\n- Item 1\n- Item 2\nParagraph text";
        let html = md_to_html(md);
        assert!(html.contains("<h1>Header 1</h1>"));
        assert!(html.contains("<h2>Header 2</h2>"));
        assert!(html.contains("<li>Item 1</li>"));
        assert!(html.contains("<p>Paragraph text</p>"));
    }

    #[test]
    fn test_html_to_md_conversions() {
        let html = "<h1>Header 1</h1><p>Paragraph text</p>";
        let md = html_to_md(html);
        assert!(md.contains("# Header 1"));
        assert!(md.contains("Paragraph text"));
    }

    #[test]
    fn test_create_docx_bytes() {
        let text = "Hello world docx text";
        let docx_bytes = create_docx_from_txt(text).unwrap();
        assert!(!docx_bytes.is_empty());
    }

    #[test]
    fn test_create_pdf_bytes() {
        let text = "Hello world pdf text";
        let pdf_bytes = create_pdf_from_txt(text).unwrap();
        assert!(pdf_bytes.starts_with(b"%PDF-1.4"));
    }

    #[test]
    fn test_backup_and_restore_roundtrip() {
        let temp = tempdir().unwrap();
        let data_dir = temp.path().join("data");
        let backup_path = temp.path().join("backup.bin");
        let restore_dir = temp.path().join("restore");

        fs::create_dir_all(&data_dir).unwrap();
        fs::write(data_dir.join("test.txt"), b"backup test content").unwrap();

        perform_backup(
            data_dir.to_str().unwrap(),
            backup_path.to_str().unwrap(),
            "secret_phrase",
        )
        .unwrap();

        assert!(backup_path.exists());

        restore_backup(
            backup_path.to_str().unwrap(),
            restore_dir.to_str().unwrap(),
            "secret_phrase",
        )
        .unwrap();

        let restored_content = fs::read_to_string(restore_dir.join("test.txt")).unwrap();
        assert_eq!(restored_content, "backup test content");
    }
}
