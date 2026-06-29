# System Architecture

## Overview

MemoryOS is a clean-architecture, offline-first personal memory operating system. All processing occurs locally on the user's device.

```mermaid
graph TD
    subgraph "Presentation Layer"
        UI[Flutter UI<br/>Material 3 · Adaptive · a11y]
    end

    subgraph "Application Layer"
        AB[App BLoCs<br/>State Management]
        SR[Service Router]
    end

    subgraph "Domain Layer"
        FM[File Manager]
        SM[Search Manager]
        AM[AI Manager]
        DM[Duplicate Manager]
        VM[Vault Manager]
    end

    subgraph "Infrastructure Layer"
        FFI[Rust FFI Bridge]
    end

    subgraph "Rust Core Engine"
        CE[core-engine<br/>Config · Crypto · DB · FFI]
        OE[ocr-engine<br/>Tesseract · PaddleOCR]
        SE[search-engine<br/>FTS5 · sqlite-vec]
        AE[ai-engine<br/>llama.cpp · ONNX]
        DE[duplicate-engine<br/>SHA256 · pHash]
    end

    subgraph "Storage"
        DB[(SQLite<br/>Metadata)]
        VDB[(sqlite-vec<br/>Vectors)]
        VT[(Vault<br/>AES-256-GCM)]
        MF[Model Files<br/>GGUF · ONNX]
    end

    UI --> AB
    AB --> SR
    SR --> FM & SM & AM & DM & VM
    FM & SM & AM & DM & VM --> FFI
    FFI --> CE
    CE --> OE & SE & AE & DE
    CE --> DB
    SE --> VDB
    VM --> VT
    AE --> MF
```

## Clean Architecture Layers

### 1. Presentation Layer
- **Flutter** (Dart) for all platforms
- Material 3 design system
- BLoC pattern for state management
- GoRouter for navigation
- Adaptive layout (sidebar on desktop, bottom nav on mobile)

### 2. Application Layer
- BLoC events and state
- Use case orchestration
- Cross-cutting concerns (logging, error handling)

### 3. Domain Layer
- Pure Dart entities
- Repository interfaces
- Business rules

### 4. Infrastructure Layer
- Rust FFI implementations
- SQLite repositories
- File system adapters

## Rust Crate Architecture

```mermaid
graph LR
    CE[core-engine] --> OE[ocr-engine]
    CE --> SE[search-engine]
    CE --> AE[ai-engine]
    CE --> DE[duplicate-engine]

    OE --> |Tesseract CLI| T[tesseract binary]
    OE --> |PaddleOCR CLI| P[paddleocr binary]
    AE --> |HTTP API| L[llama.cpp server]
    AE --> |ONNX Runtime| O[ONNX models]
    SE --> |Extension| V[sqlite-vec]
```

## Data Flow: File Ingestion

```mermaid
sequenceDiagram
    participant F as Flutter UI
    participant R as Rust Core
    participant O as OCR Engine
    participant A as AI Engine
    participant S as Search Engine
    participant D as Database

    F->>R: ingest_file(path)
    R->>R: compute_sha256()
    R->>D: check_duplicate()
    alt Not a duplicate
        R->>O: extract_text(path)
        O-->>R: OcrResult{text, confidence}
        R->>A: categorize(text)
        A-->>R: categories, tags
        R->>A: summarize(text)
        A-->>R: summary
        R->>A: embed(text)
        A-->>R: embedding[384]
        R->>S: index(file_id, text, embedding)
        R->>D: insert_file(FileEntry)
        R-->>F: FileEntry{id, tags, summary}
    else Duplicate detected
        R-->>F: DuplicateFound{original_id}
    end
```

## Technology Stack

| Component | Technology |
|-----------|-----------|
| UI Framework | Flutter 3.x + Dart |
| UI Design | Material 3 |
| State Management | flutter_bloc |
| Navigation | go_router |
| Core Engine | Rust (stable) |
| Metadata DB | SQLite (rusqlite) |
| Vector Search | sqlite-vec |
| OCR | Tesseract + PaddleOCR |
| AI Runtime | llama.cpp (GGUF) + ONNX Runtime |
| AI Models | Gemma 2, Phi 3.5, Qwen 2.5, Llama |
| Encryption | AES-256-GCM + Argon2id |
| Hashing | SHA-256 (exact) + pHash (perceptual) |
| CI/CD | GitHub Actions |
| Containers | Docker + Docker Compose |
| Documentation | MkDocs Material |

## Platform Support Matrix

```mermaid
graph TD
    APP[MemoryOS] --> WIN[Windows<br/>MSIX / EXE]
    APP --> MAC[macOS<br/>DMG]
    APP --> LIN[Linux<br/>AppImage]
    APP --> AND[Android<br/>APK / AAB]
    APP --> IOS[iOS / iPadOS<br/>IPA]
```
