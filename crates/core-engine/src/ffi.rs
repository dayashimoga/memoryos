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

/// Index a single file at the given path. Returns 0 on success, -1 on error.
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

    let ext = file_path.extension().and_then(|e| e.to_str()).unwrap_or("");
    let file_type = FileType::from_extension(ext);
    let size_bytes = metadata.len();
    let entry = FileEntry::new(path_str, file_type, size_bytes);

    let mut guard = DB.lock().unwrap();
    match guard.as_mut() {
        Some(db) => {
            // Check for duplicates before inserting
            match db.get_file_by_path(path_str) {
                Ok(Some(_)) => {
                    // Already indexed — skip
                    0
                }
                Ok(None) => match db.insert_file(&entry) {
                    Ok(_) => 0,
                    Err(e) => {
                        error!(error = %e, "Failed to insert file");
                        -1
                    }
                },
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

// ── Favorites ──────────────────────────────────────────────────────────────

/// Toggle favorite status for a file. Returns 0 on success.
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

/// List favorite files as JSON array.
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
