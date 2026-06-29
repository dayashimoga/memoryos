# Changelog

All notable changes to MemoryOS are documented in this file.

## [Unreleased] — Production Completion

### 🔴 Security Fixes
- **CRITICAL**: Fixed AES-GCM nonce reuse in `perform_backup` — replaced hardcoded `b"unique_nonce"` with random 12-byte nonce generated via `getrandom`. Nonce is prepended to ciphertext and read back during restore.
- Added backward-incompatible format detection for legacy backup files (< 12 bytes = invalid).

### 🟢 New Features
- **Tag CRUD via FFI**: `memoryos_tag_list`, `memoryos_tag_create`, `memoryos_tag_file` — full tag management through the native bridge.
- **Collection CRUD via FFI**: `memoryos_collection_list`, `memoryos_collection_create`, `memoryos_collection_add_file` — collection management wired to SQLite.
- **Large file detection**: `memoryos_get_large_files(min_size_mb)` — returns files above a size threshold for storage optimization.
- **SHA-256 hash computation**: `memoryos_hash_file(file_id)` — computes and persists file hash for duplicate detection.
- **Real storage analytics**: `memoryos_storage_stats` now queries real database totals (total_bytes, indexed_files, pending_files, duplicate_count, duplicate_bytes, large_file_count) instead of returning zeros.
- **Activity logging**: `MetadataDb.log_activity()` tracks file operations, searches, and other events with timestamps.
- **FTS5 indexed search**: Search engine now uses FTS5 `MATCH` with BM25 ranking for O(log n) lookups, falling back to LIKE when FTS5 index is unpopulated.
- **FTS5 index population**: `FtsSearcher.ensure_fts_populated()` bulk-populates the FTS5 index from existing file data.

### 🔧 Improvements
- **FfiCollectionRepository**: Replaced `StubCollectionRepository` in service locator with real FFI-backed implementation.
- **FfiFileRepository.getLargeFiles**: Now queries Rust engine for large files instead of returning empty list.
- **Database expansion**: Added `get_duplicate_groups`, `get_large_files`, `get_files_by_date_range`, `update_file_hash`, `insert_tag`, `list_tags`, `add_tag_to_file`, `get_tags_for_file`, `insert_collection`, `list_collections`, `delete_collection`, `add_file_to_collection`, `get_files_in_collection`, `log_activity` to `MetadataDb`.
- **Removed blanket lint suppressions**: Workspace `Cargo.toml` no longer suppresses `unused_imports` and `dead_code` warnings.
- **Flutter FFI bindings**: Added 8 new FFI bindings for tags, collections, large files, and hash computation with proper memory management.

### 🧪 Testing
- **Entity unit tests**: 25+ tests covering FileType classification (all extensions), FileEntry formatting, StorageStats, Collection, Tag.
- **FFI fallback tests**: 20+ tests verifying RustFfi returns safe defaults when native library is unavailable.
- **Repository stub tests**: 15+ tests for all Stub repository implementations verifying interface contracts.

### 📚 Documentation
- **README**: Updated with new features table, enhanced architecture diagram, security section, native development quickstart, platform navigation table.
- **System Architecture**: Complete rewrite with Mermaid diagram, component reference tables, 30+ FFI export catalog, database schema, platform adaptation matrix, security model.

## [0.1.0] — Initial Release

### Added
- Core Rust engine with SQLite database, FTS5 search, file monitoring, OCR, AI summarization
- Flutter cross-platform application with adaptive UI (Desktop/Tablet/Mobile)
- Docker-first development environment with 12 service definitions
- GitHub Actions CI/CD with 7 jobs covering Rust, Flutter, security, and multi-platform builds
- 15 feature modules: Home, Search, Timeline, Collections, Chat, Vault, Learning, Duplicates, Models, Settings, Inbox, Galaxy, Toolbox, File Detail, Onboarding
