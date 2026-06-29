//! Duplicate Detection Engine — SHA256 exact + pHash perceptual + embedding similarity.

pub mod error;
pub mod phash;
pub mod types;

pub use error::DuplicateError;
pub use types::{DuplicateGroup, DuplicateReport, DuplicateType};

use crate::phash::compute_phash;
use sha2::{Digest, Sha256};
use std::path::Path;
use tracing::debug;

/// Compute SHA-256 hash of a file.
pub fn sha256_file(path: &str) -> Result<String, DuplicateError> {
    let data = std::fs::read(path).map_err(DuplicateError::Io)?;
    let mut hasher = Sha256::new();
    hasher.update(&data);
    Ok(format!("{:x}", hasher.finalize()))
}

/// Compare two files for duplicate status.
pub fn compare_files(path_a: &str, path_b: &str) -> Result<DuplicateType, DuplicateError> {
    // Level 1: Exact hash match
    let hash_a = sha256_file(path_a)?;
    let hash_b = sha256_file(path_b)?;
    if hash_a == hash_b {
        return Ok(DuplicateType::Exact);
    }

    // Level 2: pHash for images
    let ext = Path::new(path_a)
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("")
        .to_lowercase();
    if matches!(
        ext.as_str(),
        "jpg" | "jpeg" | "png" | "gif" | "bmp" | "webp"
    ) {
        let ph_a = compute_phash(path_a)?;
        let ph_b = compute_phash(path_b)?;
        let distance = hamming_distance(ph_a, ph_b);
        debug!(path_a, path_b, distance, "pHash comparison");
        if distance == 0 {
            return Ok(DuplicateType::PerceptualExact);
        } else if distance <= 10 {
            return Ok(DuplicateType::PerceptualSimilar);
        }
    }

    Ok(DuplicateType::NotDuplicate)
}

/// Compute Hamming distance between two 64-bit hashes.
pub fn hamming_distance(a: u64, b: u64) -> u32 {
    (a ^ b).count_ones()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hamming_distance_identical() {
        assert_eq!(hamming_distance(0xDEADBEEF, 0xDEADBEEF), 0);
    }

    #[test]
    fn test_hamming_distance_one_bit() {
        assert_eq!(hamming_distance(0b1000, 0b0000), 1);
    }

    #[test]
    fn test_hamming_distance_max() {
        assert_eq!(hamming_distance(0u64, u64::MAX), 64);
    }

    #[test]
    fn test_sha256_nonexistent_file() {
        let result = sha256_file("/tmp/nonexistent_xyz.bin");
        assert!(result.is_err());
    }
}
