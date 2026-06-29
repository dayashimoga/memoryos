//! Tesseract OCR backend integration.
//!
//! Calls the system `tesseract` binary via subprocess.
//! Tesseract must be installed separately or bundled with the app.

use crate::error::OcrError;
use crate::types::{OcrBackend, OcrResult};
use std::time::Instant;
use tracing::{debug, warn};

/// Extract text from an image file using Tesseract OCR.
pub async fn extract(image_path: &str) -> Result<OcrResult, OcrError> {
    let start = Instant::now();

    // Verify file exists
    if !std::path::Path::new(image_path).exists() {
        return Err(OcrError::Io(std::io::Error::new(
            std::io::ErrorKind::NotFound,
            format!("File not found: {}", image_path),
        )));
    }

    // Run tesseract as subprocess: tesseract <input> stdout --psm 3 -l eng
    let output = tokio::process::Command::new("tesseract")
        .arg(image_path)
        .arg("stdout")
        .arg("--psm")
        .arg("3")
        .arg("-l")
        .arg("eng")
        .output()
        .await
        .map_err(|e| OcrError::BackendUnavailable {
            backend: format!("tesseract: {}", e),
        })?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        warn!(path = image_path, stderr = %stderr, "Tesseract returned non-zero exit");
        return Err(OcrError::Processing(stderr.to_string()));
    }

    let text = String::from_utf8_lossy(&output.stdout).to_string();
    let elapsed_ms = start.elapsed().as_millis() as u64;

    debug!(
        path = image_path,
        text_len = text.len(),
        elapsed_ms,
        "Tesseract extraction complete"
    );

    // Estimate confidence: Tesseract stdout doesn't include confidence directly.
    // We use a heuristic: non-empty text with reasonable character density = high confidence.
    let confidence = if text.trim().is_empty() {
        0.0
    } else {
        let printable_ratio = text
            .chars()
            .filter(|c| c.is_alphanumeric() || c.is_whitespace())
            .count() as f32
            / text.len().max(1) as f32;
        (printable_ratio * 0.95).min(1.0)
    };

    Ok(OcrResult {
        text: text.trim().to_string(),
        confidence,
        backend: OcrBackend::Tesseract,
        language: Some("eng".to_string()),
        bounding_boxes: Vec::new(), // Requires hOCR output for bounding boxes
        processing_ms: elapsed_ms,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_extract_nonexistent_file() {
        let result = extract("/tmp/nonexistent_file_xyz.png").await;
        assert!(result.is_err());
    }
}
