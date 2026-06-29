//! FFI interface exposing Rust APIs to Flutter via dart:ffi.

use crate::config::Config;
use crate::database::MetadataDb;
use crate::models::{FileEntry, FileType};
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int, c_longlong};
use std::sync::Mutex;
use tracing::error;

// ── Global state ──────────────────────────────────────────────────────────────

static DB: Mutex<Option<MetadataDb>> = Mutex::new(None);

// ── Helpers ───────────────────────────────────────────────────────────────────

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

// ── Exported FFI functions ────────────────────────────────────────────────────

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

/// Count total indexed files. Returns count or -1 on error.
#[no_mangle]
pub extern "C" fn memoryos_count_files() -> c_longlong {
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => db.count_files().unwrap_or(0) as c_longlong,
        None => -1,
    }
}

/// Search files by text. Returns JSON array string. Caller must free with memoryos_free_string.
#[no_mangle]
pub extern "C" fn memoryos_search(query: *const c_char) -> *mut c_char {
    let q = unsafe { str_from_ptr(query) }.unwrap_or("");
    let guard = DB.lock().unwrap();
    match guard.as_ref() {
        Some(db) => {
            let results = db.search_files_by_text(q).unwrap_or_default();
            let json = serde_json::to_string(&results).unwrap_or_else(|_| "[]".to_string());
            cstring_or_empty(&json)
        }
        None => cstring_or_empty("[]"),
    }
}

/// Free a string allocated by MemoryOS FFI.
#[no_mangle]
pub extern "C" fn memoryos_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe { drop(CString::from_raw(ptr)) };
    }
}

/// Get engine version string. Caller must free with memoryos_free_string.
#[no_mangle]
pub extern "C" fn memoryos_version() -> *mut c_char {
    cstring_or_empty(env!("CARGO_PKG_VERSION"))
}
