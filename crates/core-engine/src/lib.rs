//! MemoryOS Core Engine
//!
//! Provides foundational types, database access, file monitoring,
//! encryption, and FFI interface for the Flutter application.

pub mod config;
pub mod crypto;
pub mod database;
pub mod error;
pub mod ffi;
pub mod file_monitor;
pub mod metadata;
pub mod models;

use tracing_subscriber::{fmt, prelude::*, EnvFilter};

/// Initialize the core engine. Must be called once before any other operations.
pub fn initialize(data_dir: &str) -> anyhow::Result<()> {
    // Initialize structured logging
    tracing_subscriber::registry()
        .with(fmt::layer().json())
        .with(EnvFilter::from_default_env())
        .init();

    tracing::info!(data_dir = data_dir, "MemoryOS core engine initializing");

    // Ensure data directory exists
    std::fs::create_dir_all(data_dir)?;

    tracing::info!("MemoryOS core engine ready");
    Ok(())
}

pub use error::CoreError;
pub use models::{Collection, FileEntry, Tag, UserSettings};
