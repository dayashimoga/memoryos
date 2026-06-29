# Changelog

All notable changes to MemoryOS are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

## [1.0.0] — 2024-01-01

### Added
- Initial production-ready scaffold
- Flutter cross-platform UI with Material 3
- Rust workspace with 5 crates:
  - `core-engine`: SQLite, encryption, FFI, file monitoring
  - `ocr-engine`: Tesseract + PaddleOCR integration
  - `search-engine`: FTS5 + sqlite-vec vector search
  - `ai-engine`: llama.cpp + ONNX Runtime, model manager
  - `duplicate-engine`: SHA-256 + pHash deduplication
- AES-256-GCM vault encryption with Argon2id key derivation
- Adaptive shell (sidebar desktop, bottom nav mobile)
- All core pages: Home, Search, Timeline, Collections, Chat, Vault, Learning, Settings, Models
- Animated onboarding flow
- BLoC state management
- GoRouter navigation
- 7 GitHub Actions workflows: CI, PR validation, Release, Nightly, Docs, Security, Dependency updates
- Docker Compose development environment
- VS Code Dev Container support
- Complete documentation suite (15+ documents)
- Apache 2.0 license
