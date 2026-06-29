//! Integration test: Full file ingestion pipeline.

use core_engine::{
    config::Config,
    database::MetadataDb,
    models::{FileEntry, FileType, IndexingStatus},
};
use std::io::Write;
use tempfile::TempDir;

fn setup() -> (TempDir, MetadataDb) {
    let dir = TempDir::new().expect("create temp dir");
    let db = MetadataDb::open_in_memory().expect("in-memory db");
    (dir, db)
}

#[test]
fn test_full_ingestion_pipeline() {
    let (dir, db) = setup();

    // Create a test file
    let file_path = dir.path().join("test_document.md");
    {
        let mut f = std::fs::File::create(&file_path).unwrap();
        writeln!(f, "# Kubernetes Guide\nPod scheduling and resource management.").unwrap();
    }

    // Create and insert FileEntry
    let mut entry = FileEntry::new(
        file_path.to_str().unwrap(),
        FileType::Markdown,
        42,
    );
    entry.ocr_text = Some("Kubernetes Guide Pod scheduling and resource management.".to_string());
    entry.tags = vec!["kubernetes".to_string(), "cloud".to_string()];

    db.insert_file(&entry).expect("insert file");

    // Verify it's searchable
    let results = db.search_files_by_text("kubernetes").expect("search");
    assert!(!results.is_empty(), "Search should find the file");
    assert_eq!(results[0].filename, "test_document.md");

    // Update indexing status
    db.update_indexing_status(&entry.id, &IndexingStatus::Completed)
        .expect("update status");

    // Verify status
    let updated = db.get_file_by_id(&entry.id).unwrap().unwrap();
    assert_eq!(updated.indexing_status, IndexingStatus::Completed);
}

#[test]
fn test_duplicate_detection_integration() {
    let (dir, db) = setup();

    // Create two identical files
    let content = b"identical content for duplicate detection";
    let path_a = dir.path().join("file_a.txt");
    let path_b = dir.path().join("file_b.txt");
    std::fs::write(&path_a, content).unwrap();
    std::fs::write(&path_b, content).unwrap();

    // Compute hashes
    let hash_a = core_engine::crypto::sha256_hex(content);
    let hash_b = core_engine::crypto::sha256_hex(content);

    assert_eq!(hash_a, hash_b, "Identical files should have same hash");

    // Insert both files
    let mut entry_a = FileEntry::new(path_a.to_str().unwrap(), FileType::Text, content.len() as u64);
    entry_a.sha256_hash = Some(hash_a.clone());

    let mut entry_b = FileEntry::new(path_b.to_str().unwrap(), FileType::Text, content.len() as u64);
    entry_b.sha256_hash = Some(hash_b);

    db.insert_file(&entry_a).unwrap();
    db.insert_file(&entry_b).unwrap();

    assert_eq!(db.count_files().unwrap(), 2);
}

#[test]
fn test_encryption_round_trip_integration() {
    use core_engine::crypto::{decrypt, encrypt};

    let original = b"This is my secret vault data - financial records 2024";
    let password = "super-secret-password-123";

    let encrypted = encrypt(original, password).expect("encrypt");
    assert!(encrypted.len() > original.len(), "Encrypted should be larger");

    let decrypted = decrypt(&encrypted, password).expect("decrypt");
    assert_eq!(original.as_slice(), decrypted.as_slice(), "Round-trip should be lossless");

    // Verify wrong password fails
    assert!(decrypt(&encrypted, "wrong-password").is_err());
}
