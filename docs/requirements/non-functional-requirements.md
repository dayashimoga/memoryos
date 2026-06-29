# Non-Functional Requirements

## NFR-001: Performance
- NFR-001.1: File indexing throughput ≥ 100 files/minute on modern hardware
- NFR-001.2: Search latency < 200ms for queries on 100,000 files
- NFR-001.3: OCR latency < 5s per image (Tesseract, standard resolution)
- NFR-001.4: AI inference latency < 10s for 500-token response (Q4 model, 8-core CPU)
- NFR-001.5: Application startup time < 3s on modern hardware

## NFR-002: Scalability
- NFR-002.1: Support libraries of up to 1,000,000 files
- NFR-002.2: Support AI models up to 7B parameters (quantized)

## NFR-003: Security
- NFR-003.1: Vault encryption: AES-256-GCM
- NFR-003.2: Key derivation: Argon2id (time=2, memory=65536, parallelism=4)
- NFR-003.3: No network requests for core functionality
- NFR-003.4: No telemetry or analytics collection

## NFR-004: Reliability
- NFR-004.1: MTBF > 720 hours continuous operation
- NFR-004.2: Graceful degradation when AI model not available
- NFR-004.3: Database corruption recovery via WAL mode

## NFR-005: Usability
- NFR-005.1: WCAG 2.1 Level AA accessibility compliance
- NFR-005.2: Support 6 languages at launch
- NFR-005.3: Adaptive layout for screens from 320px to 3840px

## NFR-006: Maintainability
- NFR-006.1: Test coverage ≥ 90% (line coverage)
- NFR-006.2: Zero lint warnings policy (clippy + flutter analyze)
- NFR-006.3: All PRs must include tests for new functionality

## NFR-007: Portability
- NFR-007.1: Single Flutter codebase targets all 5 platforms
- NFR-007.2: Rust core engine compiles on Windows, macOS, Linux, Android (NDK), iOS
- NFR-007.3: Docker-first development (no host-level dependencies beyond Docker + Git)

## NFR-008: Observability
- NFR-008.1: Structured JSON logging (tracing crate)
- NFR-008.2: Local performance metrics (indexing throughput, AI latency)
- NFR-008.3: Detailed error messages with contextual information
