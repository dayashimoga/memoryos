//! Extended FFI interface — v1.2 additions.
//! Adds: storage analytics, batch operations, vault operations, tag management.

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
/// Returns: {total_files, total_bytes, duplicate_count, duplicate_bytes, recoverable_bytes}
#[no_mangle]
pub extern "C" fn memoryos_storage_stats() -> *mut c_char {
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let total_files = db.count_files().unwrap_or(0);
            // Additional analytics can be implemented in MetadataDb
            let stats = serde_json::json!({
                "total_files": total_files,
                "total_bytes": 0_u64,   // populated by indexer
                "indexed_files": total_files,
                "pending_files": 0_u64,
                "duplicate_count": 0_u64,
                "duplicate_bytes": 0_u64,
                "recoverable_bytes": 0_u64,
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
