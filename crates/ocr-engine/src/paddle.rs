//! PaddleOCR backend integration.
//!
//! Calls the `paddleocr` Python CLI or REST server (bundled).
//! Falls back gracefully if PaddleOCR is not available.

use crate::error::OcrError;
use crate::types::{OcrBackend, OcrResult, TextRegion};
use std::time::Instant;
use tracing::debug;

/// Extract text from an image file using PaddleOCR.
pub async fn extract(image_path: &str) -> Result<OcrResult, OcrError> {
    let start = Instant::now();

    if !std::path::Path::new(image_path).exists() {
        return Err(OcrError::Io(std::io::Error::new(
            std::io::ErrorKind::NotFound,
            format!("File not found: {}", image_path),
        )));
    }

    // Call PaddleOCR CLI: paddleocr --image_dir <path> --type structure --output json
    let output = tokio::process::Command::new("paddleocr")
        .arg("--image_dir")
        .arg(image_path)
        .arg("--use_angle_cls")
        .arg("true")
        .arg("--lang")
        .arg("en")
        .arg("--output")
        .arg("json")
        .output()
        .await
        .map_err(|e| OcrError::BackendUnavailable {
            backend: format!("paddleocr: {}", e),
        })?;

    let elapsed_ms = start.elapsed().as_millis() as u64;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(OcrError::Processing(stderr.to_string()));
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let result = parse_paddle_output(&stdout, elapsed_ms)?;

    debug!(
        path = image_path,
        text_len = result.text.len(),
        elapsed_ms,
        "PaddleOCR extraction complete"
    );

    Ok(result)
}

/// Parse PaddleOCR JSON output into OcrResult.
fn parse_paddle_output(output: &str, elapsed_ms: u64) -> Result<OcrResult, OcrError> {
    // PaddleOCR outputs JSONL: each line is [[box_points], [text, confidence]]
    let mut all_text = Vec::new();
    let mut bboxes = Vec::new();
    let mut total_conf = 0.0f32;
    let mut count = 0usize;

    for line in output.lines() {
        let line = line.trim();
        if line.is_empty() {
            continue;
        }
        if let Ok(parsed) = serde_json::from_str::<serde_json::Value>(line) {
            if let Some(arr) = parsed.as_array() {
                for item in arr {
                    if let Some(parts) = item.as_array() {
                        if parts.len() >= 2 {
                            if let Some(text_conf) = parts[1].as_array() {
                                if text_conf.len() >= 2 {
                                    let text = text_conf[0].as_str().unwrap_or("").to_string();
                                    let conf = text_conf[1].as_f64().unwrap_or(0.0) as f32;
                                    all_text.push(text.clone());
                                    total_conf += conf;
                                    count += 1;

                                    // Extract bounding box
                                    if let Some(box_arr) = parts[0].as_array() {
                                        if box_arr.len() == 4 {
                                            let x = box_arr[0][0].as_f64().unwrap_or(0.0) as u32;
                                            let y = box_arr[0][1].as_f64().unwrap_or(0.0) as u32;
                                            let x2 = box_arr[2][0].as_f64().unwrap_or(0.0) as u32;
                                            let y2 = box_arr[2][1].as_f64().unwrap_or(0.0) as u32;
                                            bboxes.push(TextRegion {
                                                text,
                                                confidence: conf,
                                                x,
                                                y,
                                                width: x2.saturating_sub(x),
                                                height: y2.saturating_sub(y),
                                            });
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    let avg_confidence = if count > 0 {
        total_conf / count as f32
    } else {
        0.0
    };

    Ok(OcrResult {
        text: all_text.join(" "),
        confidence: avg_confidence,
        backend: OcrBackend::Paddle,
        language: Some("en".to_string()),
        bounding_boxes: bboxes,
        processing_ms: elapsed_ms,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_paddle_output_empty() {
        let result = parse_paddle_output("", 0).unwrap();
        assert!(result.text.is_empty());
        assert_eq!(result.confidence, 0.0);
    }

    #[tokio::test]
    async fn test_extract_nonexistent_file() {
        let result = extract("/tmp/no_such_file.png").await;
        assert!(result.is_err());
    }
}
