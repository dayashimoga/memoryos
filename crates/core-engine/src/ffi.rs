//! Extended FFI interface — v1.2 additions.
#![allow(clippy::not_unsafe_ptr_arg_deref, unused_imports, dead_code)]

//! FFI bindings for MemoryOS core engine.
//!
//! Provides C-compatible exports for Flutter integration.

use crate::config::Config;
use crate::database::MetadataDb;
use crate::models::{FileEntry, FileType, IndexingStatus};
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int, c_longlong, c_ulonglong};
use std::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH};
use tracing::error;

// ── Global state ───────────────────────────────────────────────────────────────

static DB: Mutex<Option<MetadataDb>> = Mutex::new(None);

// ── Helpers ────────────────────────────────────────────────────────────────────

unsafe fn str_from_ptr<'a>(ptr: *const c_char) -> Option<&'a str> {
    if ptr.is_null() {
        None
    } else {
        CStr::from_ptr(ptr).to_str().ok()
    }
}

fn cstring_or_empty(s: &str) -> *mut c_char {
    CString::new(s).unwrap_or_default().into_raw()
}

fn json_err(msg: &str) -> *mut c_char {
    let payload = format!(r#"{{"error":"{}"}}"#, msg.replace('"', "'"));
    cstring_or_empty(&payload)
}

// ── Core lifecycle ─────────────────────────────────────────────────────────────

/// Initialize the MemoryOS engine. Returns 0 on success, -1 on error.
#[no_mangle]
pub extern "C" fn memoryos_init(data_dir: *const c_char) -> c_int {
    let dir = unsafe { str_from_ptr(data_dir) }.unwrap_or("./memoryos_data");
    let config = Config::from_data_dir(dir);

    if let Err(e) = config.ensure_dirs() {
        error!(error = %e, "Failed to create data directories");
        return -1;
    }

    match MetadataDb::open(&config.db_path) {
        Ok(db) => {
            *DB.lock().unwrap() = Some(db);
            0
        }
        Err(e) => {
            error!(error = %e, "Failed to open database");
            -1
        }
    }
}

/// Returns 0 if engine is initialized.
#[no_mangle]
pub extern "C" fn memoryos_is_initialized() -> c_int {
    if DB.lock().unwrap().is_some() {
        0
    } else {
        -1
    }
}

/// Get engine version string.
#[no_mangle]
pub extern "C" fn memoryos_version() -> *mut c_char {
    cstring_or_empty(env!("CARGO_PKG_VERSION"))
}

/// Free a string allocated by MemoryOS FFI.
#[no_mangle]
pub extern "C" fn memoryos_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe { drop(CString::from_raw(ptr)) };
    }
}

// ── File queries ───────────────────────────────────────────────────────────────

/// Count total indexed files.
#[no_mangle]
pub extern "C" fn memoryos_count_files() -> c_longlong {
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => db.count_files().unwrap_or(0) as c_longlong,
        None => -1,
    }
}

/// List recent files as JSON. Caller must free with memoryos_free_string.
#[no_mangle]
pub extern "C" fn memoryos_list_files(limit: c_int, offset: c_int) -> *mut c_char {
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let entries = db
                .list_files(limit as usize, offset as usize)
                .unwrap_or_default();
            let json = serde_json::to_string(&entries).unwrap_or_else(|_| "[]".into());
            cstring_or_empty(&json)
        }
        None => json_err("Engine not initialized"),
    }
}

/// Get a single file by ID as JSON.
#[no_mangle]
pub extern "C" fn memoryos_get_file(id: *const c_char) -> *mut c_char {
    let id_str = unsafe { str_from_ptr(id) }.unwrap_or("");
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            if let Ok(uuid) = uuid::Uuid::parse_str(id_str) {
                match db.get_file_by_id(&uuid) {
                    Ok(Some(entry)) => {
                        let json = serde_json::to_string(&entry).unwrap_or_else(|_| "null".into());
                        cstring_or_empty(&json)
                    }
                    Ok(None) => cstring_or_empty("null"),
                    Err(e) => json_err(&e.to_string()),
                }
            } else {
                json_err("Invalid UUID")
            }
        }
        None => json_err("Engine not initialized"),
    }
}

/// Search files by text query. Returns JSON array.
#[no_mangle]
pub extern "C" fn memoryos_search(query: *const c_char) -> *mut c_char {
    let q = unsafe { str_from_ptr(query) }.unwrap_or("");
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let results = db.search_files_by_text(q).unwrap_or_default();
            let json = serde_json::to_string(&results).unwrap_or_else(|_| "[]".into());
            cstring_or_empty(&json)
        }
        None => cstring_or_empty("[]"),
    }
}

// ── Storage analytics ──────────────────────────────────────────────────────────

/// Get storage statistics as JSON.
/// Returns: {total_files, total_bytes, indexed_files, pending_files, duplicate_count, duplicate_bytes, recoverable_bytes}
#[no_mangle]
pub extern "C" fn memoryos_storage_stats() -> *mut c_char {
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let total_files = db.count_files().unwrap_or(0);
            let total_bytes = db.total_size_bytes().unwrap_or(0);
            let indexed_files = db.count_by_status(&IndexingStatus::Completed).unwrap_or(0);
            let pending_files = db.count_by_status(&IndexingStatus::Pending).unwrap_or(0);
            let duplicate_groups = db.get_duplicate_groups().unwrap_or_default();
            let duplicate_count: usize = duplicate_groups
                .iter()
                .map(|(_, paths)| paths.len().saturating_sub(1))
                .sum();
            let duplicate_bytes: u64 = duplicate_groups
                .iter()
                .flat_map(|(_, paths)| paths.iter().skip(1))
                .filter_map(|p| db.get_file_by_path(p).ok().flatten())
                .map(|f| f.size_bytes)
                .sum();
            let large_files = db.get_large_files(50 * 1024 * 1024).unwrap_or_default();
            let stats = serde_json::json!({
                "total_files": total_files,
                "total_bytes": total_bytes,
                "indexed_files": indexed_files,
                "pending_files": pending_files,
                "duplicate_count": duplicate_count,
                "duplicate_bytes": duplicate_bytes,
                "recoverable_bytes": duplicate_bytes,
                "large_file_count": large_files.len(),
                "blurry_count": 0_u64,
            });
            cstring_or_empty(&stats.to_string())
        }
        None => json_err("Engine not initialized"),
    }
}

// ── Indexing ───────────────────────────────────────────────────────────────────

/// Index a single file at the given path with full pipeline processing.
/// Pipeline: validate → metadata → hash → text extract → categorize → tag → complete.
/// Returns 0 on success, -1 on error, 1 if already indexed.
#[no_mangle]
pub extern "C" fn memoryos_index_file(path: *const c_char) -> c_int {
    let path_str = match unsafe { str_from_ptr(path) } {
        Some(p) => p,
        None => return -1,
    };

    let file_path = std::path::Path::new(path_str);
    if !file_path.exists() {
        error!("File not found: {}", path_str);
        return -1;
    }

    let metadata = match std::fs::metadata(file_path) {
        Ok(m) => m,
        Err(e) => {
            error!(error = %e, "Failed to read file metadata");
            return -1;
        }
    };

    // Skip directories
    if metadata.is_dir() {
        return -1;
    }

    let ext = file_path
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("");
    let file_type = FileType::from_extension(ext);
    let size_bytes = metadata.len();
    let mut entry = FileEntry::new(path_str, file_type.clone(), size_bytes);

    // ── Stage 1: Metadata extraction ──────────────────────────────────────
    if let Err(e) = crate::metadata::extract_metadata(&mut entry) {
        error!(error = %e, "Metadata extraction failed");
        // Continue — metadata is optional
    }

    // ── Stage 2: Compute SHA-256 hash ─────────────────────────────────────
    entry.sha256_hash = duplicate_engine::sha256_file(path_str).ok();

    // ── Stage 3: Compute perceptual hash for images ───────────────────────
    if matches!(
        ext.to_lowercase().as_str(),
        "jpg" | "jpeg" | "png" | "gif" | "bmp" | "webp"
    ) {
        entry.phash = duplicate_engine::phash::compute_phash(path_str)
            .ok()
            .map(|h| h.to_string());
    }

    // ── Stage 4: Extract text content for indexing ────────────────────────
    let text_content = crate::metadata::extract_text_content(path_str);
    if let Some(ref text) = text_content {
        // Store extracted text as OCR text (searchable content)
        entry.ocr_text = Some(text.clone());
        // Generate an excerpt as summary
        entry.summary = Some(crate::metadata::generate_excerpt(text, 50));
    }

    // ── Stage 5: Keyword categorization ───────────────────────────────────
    let categorization_text = text_content
        .as_deref()
        .unwrap_or(&entry.filename);
    let categories = categorize_by_keywords(categorization_text);

    // ── Stage 6: Insert into database and auto-tag ────────────────────────
    let mut guard = DB.lock().unwrap();
    match guard.as_mut() {
        Some(db) => {
            // Check for duplicates before inserting
            match db.get_file_by_path(path_str) {
                Ok(Some(_)) => {
                    // Already indexed — skip
                    return 1;
                }
                Ok(None) => {
                    // Mark as completed since we're doing full processing
                    entry.indexing_status = IndexingStatus::Completed;
                    entry.indexed_at = Some(chrono::Utc::now());

                    if let Err(e) = db.insert_file(&entry) {
                        error!(error = %e, "Failed to insert file");
                        return -1;
                    }

                    // Auto-categorize: create categories and link to file
                    for cat_name in &categories {
                        if let Ok(cat_id) = db.get_or_create_category(cat_name) {
                            let _ = db.add_category_to_file(&entry.id, &cat_id);
                        }
                    }

                    // Auto-tag based on file type
                    let type_tag_name = match &entry.file_type {
                        FileType::Image => Some("image"),
                        FileType::Screenshot => Some("screenshot"),
                        FileType::Document => Some("document"),
                        FileType::Spreadsheet => Some("spreadsheet"),
                        FileType::Video => Some("video"),
                        FileType::Audio => Some("audio"),
                        FileType::Archive => Some("archive"),
                        FileType::Markdown => Some("markdown"),
                        FileType::Html => Some("html"),
                        FileType::Text => Some("text"),
                        _ => None,
                    };

                    if let Some(tag_name) = type_tag_name {
                        let tag = crate::models::Tag::new(tag_name);
                        let _ = db.insert_tag(&tag);
                        // Find the tag ID (insert_tag uses INSERT OR IGNORE)
                        if let Ok(tags) = db.list_tags() {
                            if let Some(t) = tags.iter().find(|t| t.name == tag_name) {
                                let _ = db.add_tag_to_file(&entry.id, &t.id);
                            }
                        }
                    }

                    // Log activity
                    let _ = db.log_activity(
                        "file_imported",
                        Some(&entry.id),
                        Some(&format!("Imported: {}", entry.filename)),
                    );

                    0
                }
                Err(e) => {
                    error!(error = %e, "Database error during dedup check");
                    -1
                }
            }
        }
        None => -1,
    }
}

/// Batch delete files by ID. IDs are newline-separated in the input string.
/// Returns number of deleted files.
#[no_mangle]
pub extern "C" fn memoryos_batch_delete(ids_newline_separated: *const c_char) -> c_int {
    let ids_str = unsafe { str_from_ptr(ids_newline_separated) }.unwrap_or("");
    let ids: Vec<&str> = ids_str.lines().filter(|l| !l.is_empty()).collect();

    if ids.is_empty() {
        return 0;
    }

    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let mut count = 0i32;
            for id in ids {
                if let Ok(uuid) = uuid::Uuid::parse_str(id) {
                    if db.delete_file(&uuid).is_ok() {
                        count += 1;
                    }
                }
            }
            count
        }
        None => -1,
    }
}

// ── Vault ──────────────────────────────────────────────────────────────────────

/// Mark a file as encrypted (moved to vault). Returns 0 on success.
#[no_mangle]
pub extern "C" fn memoryos_vault_add(id: *const c_char) -> c_int {
    let id_str = unsafe { str_from_ptr(id) }.unwrap_or("");
    if let Ok(uuid) = uuid::Uuid::parse_str(id_str) {
        let guard = DB.lock().unwrap();
        if let Some(db) = guard.as_ref() {
            return match db.set_encrypted(&uuid, true) {
                Ok(_) => 0,
                Err(_) => -1,
            };
        }
    }
    -1
}

/// Remove a file from the vault (decrypt flag). Returns 0 on success.
#[no_mangle]
pub extern "C" fn memoryos_vault_remove(id: *const c_char) -> c_int {
    let id_str = unsafe { str_from_ptr(id) }.unwrap_or("");
    if let Ok(uuid) = uuid::Uuid::parse_str(id_str) {
        let guard = DB.lock().unwrap();
        if let Some(db) = guard.as_ref() {
            return match db.set_encrypted(&uuid, false) {
                Ok(_) => 0,
                Err(_) => -1,
            };
        }
    }
    -1
}

/// List vault files as JSON.
#[no_mangle]
pub extern "C" fn memoryos_vault_list() -> *mut c_char {
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let files = db.list_encrypted_files().unwrap_or_default();
            let json = serde_json::to_string(&files).unwrap_or_else(|_| "[]".into());
            cstring_or_empty(&json)
        }
        None => cstring_or_empty("[]"),
    }
}

// ── Toolbox utilities ──────────────────────────────────────────────────────────

/// Convert document format (PDF, DOCX, Markdown, HTML, TXT, EPUB).
#[no_mangle]
pub extern "C" fn memoryos_convert_document(
    input_path: *const c_char,
    output_path: *const c_char,
) -> c_int {
    let in_p = unsafe { str_from_ptr(input_path) }.unwrap_or("");
    let out_p = unsafe { str_from_ptr(output_path) }.unwrap_or("");

    match crate::toolbox::convert_document(in_p, out_p) {
        Ok(_) => 0,
        Err(_) => -1,
    }
}

/// Process image (resize, format conversion, quality compression).
#[no_mangle]
pub extern "C" fn memoryos_process_image(
    input_path: *const c_char,
    output_path: *const c_char,
    width: c_int,
    height: c_int,
    quality: c_int,
) -> c_int {
    let in_p = unsafe { str_from_ptr(input_path) }.unwrap_or("");
    let out_p = unsafe { str_from_ptr(output_path) }.unwrap_or("");

    match crate::toolbox::process_image(in_p, out_p, width as u32, height as u32, quality as u8) {
        Ok(_) => 0,
        Err(_) => -1,
    }
}

/// Normalize WAV audio file to maximum level.
#[no_mangle]
pub extern "C" fn memoryos_normalize_wav(
    input_path: *const c_char,
    output_path: *const c_char,
) -> c_int {
    let in_p = unsafe { str_from_ptr(input_path) }.unwrap_or("");
    let out_p = unsafe { str_from_ptr(output_path) }.unwrap_or("");

    match crate::toolbox::normalize_wav(in_p, out_p) {
        Ok(_) => 0,
        Err(_) => -1,
    }
}

/// List archive zip entries as JSON.
#[no_mangle]
pub extern "C" fn memoryos_archive_list(archive_path: *const c_char) -> *mut c_char {
    let path = unsafe { str_from_ptr(archive_path) }.unwrap_or("");
    match crate::toolbox::list_archive(path) {
        Ok(items) => {
            let json = serde_json::to_string(&items).unwrap_or_else(|_| "[]".into());
            cstring_or_empty(&json)
        }
        Err(_) => cstring_or_empty("[]"),
    }
}

/// Create a new zip archive containing the listed files (newline separated paths).
#[no_mangle]
pub extern "C" fn memoryos_archive_create(
    output_path: *const c_char,
    paths_newline_separated: *const c_char,
) -> c_int {
    let out_p = unsafe { str_from_ptr(output_path) }.unwrap_or("");
    let paths_str = unsafe { str_from_ptr(paths_newline_separated) }.unwrap_or("");
    let paths: Vec<String> = paths_str
        .lines()
        .filter(|l| !l.is_empty())
        .map(String::from)
        .collect();

    match crate::toolbox::create_archive(out_p, paths) {
        Ok(_) => 0,
        Err(_) => -1,
    }
}

/// Extract zip archive to output folder.
#[no_mangle]
pub extern "C" fn memoryos_archive_extract(
    archive_path: *const c_char,
    output_dir: *const c_char,
) -> c_int {
    let archive_p = unsafe { str_from_ptr(archive_path) }.unwrap_or("");
    let out_dir = unsafe { str_from_ptr(output_dir) }.unwrap_or("");

    match crate::toolbox::extract_archive(archive_p, out_dir) {
        Ok(_) => 0,
        Err(_) => -1,
    }
}

/// Perform incremental password-encrypted backup of data_dir.
#[no_mangle]
pub extern "C" fn memoryos_backup_perform(
    data_dir: *const c_char,
    backup_path: *const c_char,
    key_phrase: *const c_char,
) -> c_int {
    let d_dir = unsafe { str_from_ptr(data_dir) }.unwrap_or("");
    let b_path = unsafe { str_from_ptr(backup_path) }.unwrap_or("");
    let key = unsafe { str_from_ptr(key_phrase) }.unwrap_or("");

    match crate::toolbox::perform_backup(d_dir, b_path, key) {
        Ok(_) => 0,
        Err(_) => -1,
    }
}

/// Restore password-encrypted backup into data_dir.
#[no_mangle]
pub extern "C" fn memoryos_backup_restore(
    backup_path: *const c_char,
    data_dir: *const c_char,
    key_phrase: *const c_char,
) -> c_int {
    let b_path = unsafe { str_from_ptr(backup_path) }.unwrap_or("");
    let d_dir = unsafe { str_from_ptr(data_dir) }.unwrap_or("");
    let key = unsafe { str_from_ptr(key_phrase) }.unwrap_or("");

    match crate::toolbox::restore_backup(b_path, d_dir, key) {
        Ok(_) => 0,

        Err(_) => -1,
    }
}

// ── Tags ───────────────────────────────────────────────────────────────────────

/// List all tags as JSON array.
#[no_mangle]
pub extern "C" fn memoryos_tag_list() -> *mut c_char {
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let tags = db.list_tags().unwrap_or_default();
            let json = serde_json::to_string(&tags).unwrap_or_else(|_| "[]".into());
            cstring_or_empty(&json)
        }
        None => cstring_or_empty("[]"),
    }
}

/// Create a new tag. Returns 0 on success.
#[no_mangle]
pub extern "C" fn memoryos_tag_create(name: *const c_char, color: *const c_char) -> c_int {
    let tag_name = unsafe { str_from_ptr(name) }.unwrap_or("");
    let tag_color = unsafe { str_from_ptr(color) };
    if tag_name.is_empty() {
        return -1;
    }

    let mut tag = crate::models::Tag::new(tag_name);
    tag.color = tag_color.map(String::from);

    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => match db.insert_tag(&tag) {
            Ok(_) => 0,
            Err(_) => -1,
        },
        None => -1,
    }
}

/// Add a tag to a file. Returns 0 on success.
#[no_mangle]
pub extern "C" fn memoryos_tag_file(file_id: *const c_char, tag_id: *const c_char) -> c_int {
    let f_id = unsafe { str_from_ptr(file_id) }.unwrap_or("");
    let t_id = unsafe { str_from_ptr(tag_id) }.unwrap_or("");
    let f_uuid = match uuid::Uuid::parse_str(f_id) {
        Ok(u) => u,
        Err(_) => return -1,
    };
    let t_uuid = match uuid::Uuid::parse_str(t_id) {
        Ok(u) => u,
        Err(_) => return -1,
    };

    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => match db.add_tag_to_file(&f_uuid, &t_uuid) {
            Ok(_) => 0,
            Err(_) => -1,
        },
        None => -1,
    }
}

// ── Collections ────────────────────────────────────────────────────────────────

/// List all collections as JSON.
#[no_mangle]
pub extern "C" fn memoryos_collection_list() -> *mut c_char {
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let cols = db.list_collections().unwrap_or_default();
            let json = serde_json::to_string(&cols).unwrap_or_else(|_| "[]".into());
            cstring_or_empty(&json)
        }
        None => cstring_or_empty("[]"),
    }
}

/// Create a collection. Returns 0 on success.
#[no_mangle]
pub extern "C" fn memoryos_collection_create(
    name: *const c_char,
    description: *const c_char,
) -> c_int {
    let col_name = unsafe { str_from_ptr(name) }.unwrap_or("");
    let col_desc = unsafe { str_from_ptr(description) };
    if col_name.is_empty() {
        return -1;
    }

    let mut col = crate::models::Collection::new(col_name);
    col.description = col_desc.map(String::from);

    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => match db.insert_collection(&col) {
            Ok(_) => 0,
            Err(_) => -1,
        },
        None => -1,
    }
}

/// Add a file to a collection. Returns 0 on success.
#[no_mangle]
pub extern "C" fn memoryos_collection_add_file(
    collection_id: *const c_char,
    file_id: *const c_char,
) -> c_int {
    let c_id = unsafe { str_from_ptr(collection_id) }.unwrap_or("");
    let f_id = unsafe { str_from_ptr(file_id) }.unwrap_or("");
    let c_uuid = match uuid::Uuid::parse_str(c_id) {
        Ok(u) => u,
        Err(_) => return -1,
    };
    let f_uuid = match uuid::Uuid::parse_str(f_id) {
        Ok(u) => u,
        Err(_) => return -1,
    };

    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => match db.add_file_to_collection(&c_uuid, &f_uuid) {
            Ok(_) => 0,
            Err(_) => -1,
        },
        None => -1,
    }
}

// ── Large files ────────────────────────────────────────────────────────────────

/// Get files larger than 50MB as JSON array.
#[no_mangle]
pub extern "C" fn memoryos_get_large_files(min_size_mb: c_int) -> *mut c_char {
    let min_bytes = (min_size_mb as u64) * 1024 * 1024;
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let files = db.get_large_files(min_bytes).unwrap_or_default();
            let json = serde_json::to_string(&files).unwrap_or_else(|_| "[]".into());
            cstring_or_empty(&json)
        }
        None => cstring_or_empty("[]"),
    }
}

/// Compute and store SHA-256 hash for a file. Returns 0 on success.
#[no_mangle]
pub extern "C" fn memoryos_hash_file(file_id: *const c_char) -> c_int {
    let id_str = unsafe { str_from_ptr(file_id) }.unwrap_or("");
    let f_uuid = match uuid::Uuid::parse_str(id_str) {
        Ok(u) => u,
        Err(_) => return -1,
    };

    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            if let Ok(Some(entry)) = db.get_file_by_id(&f_uuid) {
                let file_data = match std::fs::read(&entry.path) {
                    Ok(d) => d,
                    Err(_) => return -1,
                };
                use sha2::{Digest, Sha256};
                let hash = format!("{:x}", Sha256::digest(&file_data));
                match db.update_file_hash(&f_uuid, &hash) {
                    Ok(_) => 0,
                    Err(_) => -1,
                }
            } else {
                -1
            }
        }
        None => -1,
    }
}

// ── Favorites ───────────────────────────────────────────────────────────────

/// Toggle the favorite status of a file. Returns 0 on success.
#[no_mangle]
pub extern "C" fn memoryos_toggle_favorite(file_id: *const c_char) -> c_int {
    let id_str = unsafe { str_from_ptr(file_id) }.unwrap_or("");
    let f_uuid = match uuid::Uuid::parse_str(id_str) {
        Ok(u) => u,
        Err(_) => return -1,
    };
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => match db.toggle_favorite(&f_uuid) {
            Ok(_) => 0,
            Err(_) => -1,
        },
        None => -1,
    }
}

/// List all favorited files as JSON array.
#[no_mangle]
pub extern "C" fn memoryos_list_favorites() -> *mut c_char {
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let files = db.list_favorites().unwrap_or_default();
            let json = serde_json::to_string(&files).unwrap_or_else(|_| "[]".into());
            cstring_or_empty(&json)
        }
        None => cstring_or_empty("[]"),
    }
}

// ── AI Categorization (keyword-based, no external model needed) ────────────

/// Categorize text content by keywords. Returns JSON array of category strings.
#[no_mangle]
pub extern "C" fn memoryos_categorize_text(text: *const c_char) -> *mut c_char {
    let text_str = unsafe { str_from_ptr(text) }.unwrap_or("");
    if text_str.is_empty() {
        return cstring_or_empty(r#"["Unknown"]"#);
    }

    let categories = categorize_by_keywords(text_str);
    let json = serde_json::to_string(&categories).unwrap_or_else(|_| r#"["Unknown"]"#.into());
    cstring_or_empty(&json)
}

/// Keyword-based text categorization (fast, offline, no model required).
fn categorize_by_keywords(text: &str) -> Vec<&'static str> {
    let text_lower = text.to_lowercase();
    let mut categories = Vec::new();

    let rules: &[(&[&str], &str)] = &[
        (
            &[
                "aws",
                "azure",
                "gcp",
                "kubernetes",
                "docker",
                "cloud",
                "ec2",
                "s3",
            ],
            "Cloud",
        ),
        (
            &[
                "security",
                "vulnerability",
                "cve",
                "exploit",
                "firewall",
                "tls",
                "ssl",
            ],
            "Security",
        ),
        (
            &[
                "rust",
                "python",
                "javascript",
                "typescript",
                "code",
                "function",
                "class",
                "git",
            ],
            "Development",
        ),
        (
            &[
                "invoice",
                "billing",
                "payment",
                "amount due",
                "vat",
                "tax id",
            ],
            "Invoice",
        ),
        (
            &["receipt", "total", "subtotal", "cash", "card", "purchased"],
            "Receipt",
        ),
        (
            &["meeting", "agenda", "minutes", "attendees", "action items"],
            "Meeting",
        ),
        (
            &["chess", "opening", "endgame", "pawn", "rook", "bishop"],
            "Chess",
        ),
        (
            &["learn", "tutorial", "course", "study", "flashcard", "quiz"],
            "Learning",
        ),
        (
            &[
                "flight",
                "hotel",
                "itinerary",
                "passport",
                "visa",
                "booking",
            ],
            "Travel",
        ),
        (
            &[
                "finance",
                "budget",
                "investment",
                "stock",
                "portfolio",
                "bank",
            ],
            "Finance",
        ),
        (
            &["medical", "health", "patient", "diagnosis", "prescription"],
            "Medical",
        ),
        (
            &["contract", "legal", "clause", "agreement", "terms"],
            "Legal",
        ),
        (
            &["project", "milestone", "sprint", "roadmap", "deliverable"],
            "Project",
        ),
        (&["screenshot", "capture", "screen"], "Screenshot"),
    ];

    for (keywords, category) in rules {
        if keywords.iter().any(|kw| text_lower.contains(kw)) {
            categories.push(*category);
        }
    }

    if categories.is_empty() {
        categories.push("Unknown");
    }
    categories
}

// ── Recent items ───────────────────────────────────────────────────────────

/// Get recently accessed files as JSON array (last N files by modified date).
#[no_mangle]
pub extern "C" fn memoryos_recent_files(limit: c_int) -> *mut c_char {
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let files = db.recent_files(limit as usize).unwrap_or_default();
            let json = serde_json::to_string(&files).unwrap_or_else(|_| "[]".into());
            cstring_or_empty(&json)
        }
        None => cstring_or_empty("[]"),
    }
}

/// Get groups of duplicate files as JSON.
#[no_mangle]
pub extern "C" fn memoryos_get_duplicate_groups() -> *mut c_char {
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => match db.get_duplicate_groups() {
            Ok(groups) => {
                let mut json_groups = Vec::new();
                for (hash, paths) in groups {
                    let mut files = Vec::new();
                    let mut total_size = 0u64;
                    for (i, path) in paths.iter().enumerate() {
                        if let Ok(Some(entry)) = db.get_file_by_path(path) {
                            if i > 0 {
                                total_size += entry.size_bytes;
                            }
                            files.push(entry);
                        }
                    }
                    json_groups.push(serde_json::json!({
                        "hash": hash,
                        "files": files,
                        "wasted_bytes": total_size,
                    }));
                }
                let json = serde_json::to_string(&json_groups).unwrap_or_else(|_| "[]".into());
                cstring_or_empty(&json)
            }
            Err(e) => json_err(&e.to_string()),
        },
        None => json_err("Engine not initialized"),
    }
}

/// Get groups of perceptually similar images as JSON.
#[no_mangle]
pub extern "C" fn memoryos_get_similar_groups() -> *mut c_char {
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let all_files = match db.list_files(1000, 0) {
                Ok(f) => f,
                Err(e) => return json_err(&e.to_string()),
            };

            let image_files: Vec<&FileEntry> =
                all_files.iter().filter(|f| f.phash.is_some()).collect();

            let mut groups = Vec::new();
            let mut visited = std::collections::HashSet::new();

            for (i, f_a) in image_files.iter().enumerate() {
                if visited.contains(&f_a.id) {
                    continue;
                }

                let phash_a: u64 = f_a.phash.as_ref().unwrap().parse().unwrap_or(0);
                let mut group_files = vec![(*f_a).clone()];

                for f_b in image_files.iter().skip(i + 1) {
                    if visited.contains(&f_b.id) {
                        continue;
                    }

                    let phash_b: u64 = f_b.phash.as_ref().unwrap().parse().unwrap_or(0);
                    let distance = duplicate_engine::hamming_distance(phash_a, phash_b);

                    if distance <= 10 {
                        group_files.push((*f_b).clone());
                        visited.insert(f_b.id);
                    }
                }

                if group_files.len() > 1 {
                    visited.insert(f_a.id);
                    groups.push(serde_json::json!({
                        "files": group_files,
                        "similarity": 0.85,
                    }));
                }
            }

            let json = serde_json::to_string(&groups).unwrap_or_else(|_| "[]".into());
            cstring_or_empty(&json)
        }
        None => json_err("Engine not initialized"),
    }
}

// ── FTS Search ─────────────────────────────────────────────────────────────

/// Full-text search using FTS5 index with LIKE fallback.
/// Returns JSON array of matching FileEntry objects.
#[no_mangle]
pub extern "C" fn memoryos_search_fts(query: *const c_char) -> *mut c_char {
    let q = unsafe { str_from_ptr(query) }.unwrap_or("");
    if q.is_empty() {
        return cstring_or_empty("[]");
    }
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let results = db.search_fts(q).unwrap_or_default();
            let json = serde_json::to_string(&results).unwrap_or_else(|_| "[]".into());
            cstring_or_empty(&json)
        }
        None => cstring_or_empty("[]"),
    }
}

// ── Batch Import ───────────────────────────────────────────────────────────

/// Recursively index all files in a directory.
/// Returns number of newly indexed files, or -1 on error.
#[no_mangle]
pub extern "C" fn memoryos_index_directory(dir_path: *const c_char) -> c_int {
    let dir_str = match unsafe { str_from_ptr(dir_path) } {
        Some(p) => p,
        None => return -1,
    };

    let dir = std::path::Path::new(dir_str);
    if !dir.exists() || !dir.is_dir() {
        return -1;
    }

    let mut count: i32 = 0;
    let mut paths = vec![dir.to_path_buf()];

    while let Some(current) = paths.pop() {
        if current.is_dir() {
            if let Ok(entries) = std::fs::read_dir(&current) {
                for entry in entries.flatten() {
                    paths.push(entry.path());
                }
            }
        } else if current.is_file() {
            if let Some(path_str) = current.to_str() {
                let path_c = match std::ffi::CString::new(path_str) {
                    Ok(c) => c,
                    Err(_) => continue,
                };
                let result = memoryos_index_file(path_c.as_ptr());
                if result == 0 {
                    count += 1;
                }
            }
        }
    }

    count
}

// ── Timeline ───────────────────────────────────────────────────────────────

/// Get files for timeline view within a date range.
/// from/to are ISO-8601 date strings. Returns JSON array.
#[no_mangle]
pub extern "C" fn memoryos_get_timeline(
    from: *const c_char,
    to: *const c_char,
    limit: c_int,
) -> *mut c_char {
    let from_str = unsafe { str_from_ptr(from) }.unwrap_or("1970-01-01T00:00:00Z");
    let to_str = unsafe { str_from_ptr(to) }.unwrap_or("2099-12-31T23:59:59Z");
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let entries = db
                .get_timeline_entries(from_str, to_str, limit as usize)
                .unwrap_or_default();
            let json = serde_json::to_string(&entries).unwrap_or_else(|_| "[]".into());
            cstring_or_empty(&json)
        }
        None => cstring_or_empty("[]"),
    }
}

// ── Categories ─────────────────────────────────────────────────────────────

/// List all categories with file counts as JSON.
/// Returns: [{"id": "...", "name": "...", "file_count": N}, ...]
#[no_mangle]
pub extern "C" fn memoryos_list_categories() -> *mut c_char {
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let categories = db.list_categories().unwrap_or_default();
            let json_cats: Vec<serde_json::Value> = categories
                .iter()
                .map(|(id, name, count)| {
                    serde_json::json!({
                        "id": id,
                        "name": name,
                        "file_count": count,
                    })
                })
                .collect();
            let json = serde_json::to_string(&json_cats).unwrap_or_else(|_| "[]".into());
            cstring_or_empty(&json)
        }
        None => cstring_or_empty("[]"),
    }
}

/// Get files in a specific category. Returns JSON array.
#[no_mangle]
pub extern "C" fn memoryos_get_files_by_category(category: *const c_char) -> *mut c_char {
    let cat_name = unsafe { str_from_ptr(category) }.unwrap_or("");
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let files = db.get_files_by_category(cat_name).unwrap_or_default();
            let json = serde_json::to_string(&files).unwrap_or_else(|_| "[]".into());
            cstring_or_empty(&json)
        }
        None => cstring_or_empty("[]"),
    }
}

// ── Search History ─────────────────────────────────────────────────────────

/// Save a search query to history.
#[no_mangle]
pub extern "C" fn memoryos_save_search_query(
    query: *const c_char,
    result_count: c_int,
) -> c_int {
    let q = unsafe { str_from_ptr(query) }.unwrap_or("");
    if q.is_empty() {
        return -1;
    }
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => match db.save_search_query(q, result_count as usize) {
            Ok(_) => 0,
            Err(_) => -1,
        },
        None => -1,
    }
}

/// Get recent search history as JSON array of strings.
#[no_mangle]
pub extern "C" fn memoryos_get_search_history(limit: c_int) -> *mut c_char {
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let history = db.get_search_history(limit as usize).unwrap_or_default();
            let json = serde_json::to_string(&history).unwrap_or_else(|_| "[]".into());
            cstring_or_empty(&json)
        }
        None => cstring_or_empty("[]"),
    }
}

// ── Processing Status ──────────────────────────────────────────────────────

/// Get processing queue status as JSON.
/// Returns: {"pending_count": N, "total_files": N, "indexed_files": N}
#[no_mangle]
pub extern "C" fn memoryos_get_processing_status() -> *mut c_char {
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let pending = db.pending_processing_count().unwrap_or(0);
            let total = db.count_files().unwrap_or(0);
            let indexed = db
                .count_by_status(&IndexingStatus::Completed)
                .unwrap_or(0);
            let status = serde_json::json!({
                "pending_count": pending,
                "total_files": total,
                "indexed_files": indexed,
            });
            cstring_or_empty(&status.to_string())
        }
        None => json_err("Engine not initialized"),
    }
}

// ── Thumbnail Generation ──────────────────────────────────────────────────

/// Generate a thumbnail for an image file.
/// Saves the thumbnail to output_path. Returns 0 on success.
#[no_mangle]
pub extern "C" fn memoryos_generate_thumbnail(
    input_path: *const c_char,
    output_path: *const c_char,
    size: c_int,
) -> c_int {
    let in_p = unsafe { str_from_ptr(input_path) }.unwrap_or("");
    let out_p = unsafe { str_from_ptr(output_path) }.unwrap_or("");

    let thumb_size = if size > 0 { size as u32 } else { 256 };

    match crate::toolbox::process_image(in_p, out_p, thumb_size, thumb_size, 85) {
        Ok(_) => 0,
        Err(_) => -1,
    }
}

// ── Get files by type ──────────────────────────────────────────────────────

/// Get files by type (e.g., "\"Image\""). Returns JSON array.
#[no_mangle]
pub extern "C" fn memoryos_get_files_by_type(
    file_type: *const c_char,
    limit: c_int,
) -> *mut c_char {
    let ft = unsafe { str_from_ptr(file_type) }.unwrap_or("");
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let files = db.get_files_by_type(ft, limit as usize).unwrap_or_default();
            let json = serde_json::to_string(&files).unwrap_or_else(|_| "[]".into());
            cstring_or_empty(&json)
        }
        None => cstring_or_empty("[]"),
    }
}

// ── Get files in manual collection ─────────────────────────────────────────

/// Get files inside a manual collection. Returns JSON array.
#[no_mangle]
pub extern "C" fn memoryos_get_files_in_collection(collection_id: *const c_char) -> *mut c_char {
    let c_str = unsafe { str_from_ptr(collection_id) }.unwrap_or("");
    let c_uuid = match uuid::Uuid::parse_str(c_str) {
        Ok(u) => u,
        Err(_) => return cstring_or_empty("[]"),
    };
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let files = db.get_files_in_collection(&c_uuid).unwrap_or_default();
            let json = serde_json::to_string(&files).unwrap_or_else(|_| "[]".into());
            cstring_or_empty(&json)
        }
        None => cstring_or_empty("[]"),
    }
}

