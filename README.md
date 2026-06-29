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
| 🧬 **Semantic Search** | Vector similarity search via sqlite-vec |
| 🗂️ **Auto-Organization** | AI categorization, tagging, and collection building |
| 👥 **Duplicate Detection** | SHA256 + pHash + embedding-based similarity |
| 💬 **AI Chat** | Ask questions about your knowledge base |
| 🗺️ **Knowledge Graph** | Auto-built relationships between concepts, people, projects |
| 🔐 **Secure Vault** | Encrypted storage with biometric unlock |
| 📅 **Timeline** | Chronological memory browser |
| 🃏 **Learning** | Flashcards, quizzes, spaced repetition |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│           Flutter UI (Dart)             │
│     Material 3 · Adaptive · a11y        │
└──────────────┬──────────────────────────┘
               │ FFI
┌──────────────▼──────────────────────────┐
│         Rust Core Engine                │
│  OCR · Search · AI · Crypto · Files     │
└──┬──────────┬───────────┬──────────────┘
   │          │           │
┌──▼──┐  ┌───▼───┐  ┌────▼────┐
│SQLite│  │sqlite │  │llama.cpp│
│Meta  │  │ -vec  │  │+ ONNX   │
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

---

## 🖥️ Platform Support

| Platform | Status |
|----------|--------|
| Windows | ✅ |
| macOS | ✅ |
| Linux | ✅ |
| Android | ✅ |
| iOS/iPadOS | ✅ |

---

## 📁 Repository Structure

```
memoryos/
├── apps/flutter_app/          # Flutter cross-platform UI
├── crates/
│   ├── core-engine/           # Core Rust library (FFI)
│   ├── ocr-engine/            # OCR: PaddleOCR + Tesseract
│   ├── search-engine/         # Full-text + vector search
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
```

---

## 📖 Documentation

- [Architecture](docs/architecture/system-architecture.md)
- [Getting Started](docs/user-guide/getting-started.md)
- [Local Development](docs/deployment/local-development.md)
- [API Reference](docs/api/)
- [Security](docs/security/threat-model.md)
- [Roadmap](docs/project/roadmap.md)

---

## 📜 License

[Apache-2.0](LICENSE)
