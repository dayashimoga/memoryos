//! OCR types and results.

use serde::{Deserialize, Serialize};

/// OCR backend selection.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum OcrBackend {
    Tesseract,
    Paddle,
    Auto,
}

/// Result of an OCR operation.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OcrResult {
    pub text: String,
    pub confidence: f32,
    pub backend: OcrBackend,
    pub language: Option<String>,
    pub bounding_boxes: Vec<TextRegion>,
    pub processing_ms: u64,
}

impl OcrResult {
    pub fn empty(backend: OcrBackend) -> Self {
        Self {
            text: String::new(),
            confidence: 0.0,
            backend,
            language: None,
            bounding_boxes: Vec::new(),
            processing_ms: 0,
        }
    }
}

/// A detected text region with coordinates.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TextRegion {
    pub text: String,
    pub confidence: f32,
    pub x: u32,
    pub y: u32,
    pub width: u32,
    pub height: u32,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ocr_result_empty() {
        let r = OcrResult::empty(OcrBackend::Tesseract);
        assert!(r.text.is_empty());
        assert_eq!(r.confidence, 0.0);
        assert!(r.bounding_boxes.is_empty());
    }
}
