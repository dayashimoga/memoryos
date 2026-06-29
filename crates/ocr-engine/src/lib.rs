//! OCR Engine — wraps PaddleOCR and Tesseract for text extraction.

pub mod error;
pub mod paddle;
pub mod tesseract;
pub mod types;

pub use error::OcrError;
pub use types::{OcrResult, OcrBackend};

/// Extract text from an image file using the specified backend.
pub async fn extract_text(
    image_path: &str,
    backend: OcrBackend,
) -> Result<OcrResult, OcrError> {
    match backend {
        OcrBackend::Tesseract => tesseract::extract(image_path).await,
        OcrBackend::Paddle => paddle::extract(image_path).await,
        OcrBackend::Auto => {
            // Try Tesseract first, fall back to Paddle
            match tesseract::extract(image_path).await {
                Ok(result) if result.confidence > 0.5 => Ok(result),
                _ => paddle::extract(image_path).await,
            }
        }
    }
}
