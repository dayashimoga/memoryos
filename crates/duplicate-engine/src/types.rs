//! Duplicate detection types.

use serde::{Deserialize, Serialize};

/// Type of duplicate relationship.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum DuplicateType {
    Exact,
    PerceptualExact,
    PerceptualSimilar,
    Blurry,
    Empty,
    NotDuplicate,
}

/// A group of duplicate files.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DuplicateGroup {
    pub duplicate_type: DuplicateType,
    pub file_paths: Vec<String>,
    pub similarity_score: f32,
    pub size_bytes_wasted: u64,
}

/// Full duplicate scan report.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DuplicateReport {
    pub total_files_scanned: usize,
    pub duplicate_groups: Vec<DuplicateGroup>,
    pub total_wasted_bytes: u64,
    pub scan_duration_ms: u64,
}

impl DuplicateReport {
    pub fn new() -> Self {
        Self {
            total_files_scanned: 0,
            duplicate_groups: Vec::new(),
            total_wasted_bytes: 0,
            scan_duration_ms: 0,
        }
    }

    pub fn add_group(&mut self, group: DuplicateGroup) {
        self.total_wasted_bytes += group.size_bytes_wasted;
        self.duplicate_groups.push(group);
    }
}

impl Default for DuplicateReport {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_report_add_group() {
        let mut report = DuplicateReport::new();
        report.add_group(DuplicateGroup {
            duplicate_type: DuplicateType::Exact,
            file_paths: vec!["/a.png".to_string(), "/b.png".to_string()],
            similarity_score: 1.0,
            size_bytes_wasted: 1024,
        });
        assert_eq!(report.duplicate_groups.len(), 1);
        assert_eq!(report.total_wasted_bytes, 1024);
    }
}
