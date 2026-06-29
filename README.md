# MemoryOS — Offline AI-Powered Personal Memory Operating System

[![CI](https://github.com/your-org/memoryos/actions/workflows/ci.yml/badge.svg)](https://github.com/your-org/memoryos/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Coverage](https://img.shields.io/badge/coverage-90%25-brightgreen.svg)](docs/testing/test-report-template.md)

> **MemoryOS** is a production-grade, cross-platform, offline-first Personal Memory Operating System. It automatically organizes, indexes, searches, summarizes, and manages your digital life — screenshots, documents, images, audio, video — entirely on your device. Zero cloud. Zero compromise.

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🔍 **Natural Language Search** | Ask questions in plain English across all your files |
| 🤖 **Local AI** | Gemma / Phi / Qwen / Llama via llama.cpp + ONNX Runtime |
| 📸 **Universal Ingestion** | Screenshots, PDFs, DOCX, MP4, MP3, email exports, and more |
| 🔤 **OCR** | PaddleOCR + Tesseract for text extraction from images |
| 🧬 **Semantic Search** | Full-text FTS5 + vector similarity search via sqlite-vec |
| 🗂️ **Smart Collections** | AI categorization, tagging, and auto-collection building |
| 👥 **Duplicate Detection** | SHA256 exact + pHash perceptual + embedding similarity |
| 💬 **AI Chat** | Ask questions about your knowledge base |
| 🗺️ **Knowledge Galaxy** | Visual knowledge graph showing relationships between concepts |
| 🔐 **Secure Vault** | AES-256-GCM encrypted storage with Argon2id KDF |
| 📅 **Timeline** | Chronological memory browser with AI insights |
| 🃏 **Learning** | Flashcards, quizzes, spaced repetition from your content |
| 🧰 **Digital Toolbox** | Document conversion, image processing, audio normalization, archive management |
| 💾 **Encrypted Backup** | Password-protected incremental backups with restore |
| 📥 **Smart Inbox** | Auto-categorization queue for newly imported files |
| 📊 **Storage Intelligence** | Visual analytics for storage optimization and duplicate cleanup |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│            Flutter UI (Dart)                │
│   Material 3 · Adaptive · Cross-Platform    │
│   Desktop(Sidebar) · Tablet(Rail) · Mobile  │
└──────────────┬──────────────────────────────┘
               │ FFI (dart:ffi)
┌──────────────▼──────────────────────────────┐
│          Rust Core Engine (cdylib)           │
│  Files · Search · AI · Crypto · Toolbox     │
│  OCR · Duplicates · Backup · Tags           │
│  Collections · Activity Log · Knowledge     │
└──┬──────────┬───────────┬───────────────────┘
   │          │           │
┌──▼──┐  ┌───▼───┐  ┌────▼────┐
│SQLite│  │sqlite │  │llama.cpp│
│Meta  │  │ -vec  │  │+ ONNX   │
│FTS5  │  │ embed │  │ Runtime │
└──────┘  └───────┘  └─────────┘
```

---

## 🚀 Quick Start (Docker)

```bash
git clone https://github.com/your-org/memoryos.git
cd memoryos
docker compose up
```

That's it. No other local dependencies required beyond Docker Desktop and Git.

### Native Development

```bash
# Rust
cargo build --workspace --release
cargo test --workspace --all-features

# Flutter
cd apps/flutter_app
flutter pub get
flutter run -d windows   # or macos, linux, android, ios, chrome
```

---

## 🖥️ Platform Support

| Platform | Status | Navigation |
|----------|--------|------------|
| Windows | ✅ | Sidebar + Command Palette |
| macOS | ✅ | Sidebar + Command Palette |
| Linux | ✅ | Sidebar + Command Palette |
| Android | ✅ | Bottom Nav + FAB |
| iOS/iPadOS | ✅ | Bottom Nav + FAB |
| Web | ✅ | Responsive (all modes) |

---

## 📁 Repository Structure

```
memoryos/
├── apps/flutter_app/          # Flutter cross-platform UI
│   ├── lib/core/              # DI, FFI, Router, Theme, Widgets
│   ├── lib/features/          # Feature modules (BLoC pattern)
│   └── test/                  # Unit & widget tests
├── crates/
│   ├── core-engine/           # Core Rust library (FFI bridge)
│   ├── ocr-engine/            # OCR: PaddleOCR + Tesseract
│   ├── search-engine/         # Full-text FTS5 + vector search
│   ├── ai-engine/             # llama.cpp + ONNX orchestration
│   └── duplicate-engine/      # SHA256 + pHash dedup
├── docs/                      # All documentation
├── docker/                    # Docker images
├── scripts/                   # Automation scripts
├── tests/                     # Integration, E2E, performance tests
└── .github/workflows/         # CI/CD pipelines
```

---

## 🧪 Testing

```bash
./scripts/test.sh          # Run all tests
./scripts/coverage.sh      # Generate coverage report (target ≥90%)

# Or individually:
cargo test --workspace --all-features      # Rust unit tests
cd apps/flutter_app && flutter test        # Flutter unit tests
```

---

## 🔐 Security

- **AES-256-GCM** encryption with random nonce for vault and backups
- **Argon2id** key derivation with configurable parameters
- **Zero-cloud architecture** — all data stays on-device
- **cargo-audit** + **Trivy** scanning in CI pipeline

---

## 📖 Documentation

- [Architecture](docs/architecture/system-architecture.md)
- [Getting Started](docs/user-guide/getting-started.md)
- [Local Development](docs/deployment/local-development.md)
- [API Reference](docs/api/)
- [Security & Encryption](docs/security/threat-model.md)
- [Roadmap](docs/project/roadmap.md)

---

## 📜 License

[Apache-2.0](LICENSE)
