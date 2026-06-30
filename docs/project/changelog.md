# Changelog

All notable changes to MemoryOS are documented in this file.

## [1.2.0] — Build Stabilization & Feature Expansion

### 🔴 Build Fixes (Critical)
- **dynamic_color pinned to 1.7.0**: Version 1.8.1 used `Color.toARGB32()` requiring Flutter ≥3.27, breaking Linux/macOS/iOS builds on Flutter 3.24.3.
- **Android Gradle downgraded**: AGP 9.0.1→8.1.0, Kotlin 2.3.20→1.9.0, Gradle 9.1.0→8.3 to match Flutter 3.24.3 tooling.
- **Docker builder aligned**: Pinned builder Dockerfile from `--branch stable` (3.44.4) to `--branch 3.24.3`.
- **CI build matrix fixed**: Scoped `flutter create` bootstrap per-platform; added Windows desktop config step.
- **Removed Flutter 3.44-specific flags**: `android.newDsl` and `android.builtInKotlin` removed from gradle.properties.

### 🟢 New Features
- **AI categorization FFI**: `memoryos_categorize_text` — keyword-based text categorization across 14 categories (Cloud, Security, Development, Finance, Medical, Legal, etc.) via FFI, no external model required.
- **Favorites FFI**: `memoryos_toggle_favorite`, `memoryos_list_favorites` — toggle and query favorite files via SQLite `is_favorite` column.
- **Recent files FFI**: `memoryos_recent_files(limit)` — query most recently modified files.
- **Flutter FFI bindings**: `categorizeText`, `toggleFavorite`, `listFavorites`, `recentFiles` added to `RustFfi` class.

### 🔧 Improvements
- **Database migration**: Added `is_favorite` column via ALTER TABLE migration (backward compatible).
- **Schema v1.2**: `toggle_favorite`, `list_favorites`, `recent_files` database methods added to `MetadataDb`.

### 🧪 Testing
- **10 new Rust database tests**: toggle_favorite, recent_files, delete_file, set_encrypted, tags_crud, collections_crud, get_large_files, total_size_bytes, activity_log, update_file_hash.
- **69 total Rust tests passing** across 5 crates (up from ~55).
- **140 Flutter tests passing** with no analysis issues.

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
