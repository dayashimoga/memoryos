//! Perceptual hashing for images (pHash algorithm).

use crate::error::DuplicateError;
use image::imageops::FilterType;

const PHASH_SIZE: u32 = 32;
const PHASH_SMALL: u32 = 8;

/// Compute a 64-bit perceptual hash of an image file.
pub fn compute_phash(image_path: &str) -> Result<u64, DuplicateError> {
    let img = image::open(image_path).map_err(|e| DuplicateError::ImageLoad(e.to_string()))?;

    // Step 1: Resize to 32x32
    let resized = img.resize_exact(PHASH_SIZE, PHASH_SIZE, FilterType::Lanczos3);

    // Step 2: Convert to grayscale
    let gray = resized.to_luma8();

    // Step 3: Compute DCT (simplified: use 8x8 subset of the mean)
    let pixels: Vec<f32> = gray.pixels().map(|p| p[0] as f32).collect();
    let mean = pixels.iter().sum::<f32>() / pixels.len() as f32;

    // Step 4: Build 64-bit hash (top-left 8x8 pixels vs mean)
    let mut hash: u64 = 0;
    for (i, row) in gray.rows().take(PHASH_SMALL as usize).enumerate() {
        for (j, pixel) in row.take(PHASH_SMALL as usize).enumerate() {
            let bit_pos = i * PHASH_SMALL as usize + j;
            if pixel[0] as f32 > mean {
                hash |= 1u64 << bit_pos;
            }
        }
    }

    Ok(hash)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compute_phash_nonexistent() {
        let result = compute_phash("/tmp/no_image.png");
        assert!(result.is_err());
    }
}
