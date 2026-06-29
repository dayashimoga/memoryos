# Functional Requirements

## FR-001: File Ingestion
- FR-001.1: Support images (JPEG, PNG, GIF, WebP, HEIC, TIFF)
- FR-001.2: Support documents (PDF, DOCX, DOC, ODT, RTF)
- FR-001.3: Support spreadsheets (XLSX, XLS, CSV, ODS)
- FR-001.4: Support video (MP4, MKV, AVI, MOV)
- FR-001.5: Support audio (MP3, WAV, FLAC, AAC, OGG, M4A)
- FR-001.6: Support text (TXT, MD, HTML, LOG)
- FR-001.7: Support archives (ZIP, TAR, 7Z)
- FR-001.8: Support email exports (EML, MBOX)
- FR-001.9: Support chat exports (JSON format)

## FR-002: OCR
- FR-002.1: Extract text from images using Tesseract
- FR-002.2: Extract text from images using PaddleOCR
- FR-002.3: Auto-select best OCR backend based on confidence score
- FR-002.4: Return bounding boxes for detected text regions

## FR-003: Search
- FR-003.1: Full-text search across all indexed content
- FR-003.2: Semantic/vector search using embeddings
- FR-003.3: Filter by file type, date range, tags, collections
- FR-003.4: Natural language query parsing
- FR-003.5: Search suggestions and history

## FR-004: AI Features
- FR-004.1: Automatic file summarization
- FR-004.2: Automatic categorization and tagging
- FR-004.3: Conversational AI chat over knowledge base
- FR-004.4: Flashcard generation from documents
- FR-004.5: Quiz generation for learning
- FR-004.6: Model download and management within app

## FR-005: Organization
- FR-005.1: Auto-create collections from related files
- FR-005.2: User-defined tags and collections
- FR-005.3: Knowledge graph auto-building
- FR-005.4: Timeline view (chronological browser)

## FR-006: Duplicate Detection
- FR-006.1: Exact duplicate detection via SHA-256
- FR-006.2: Perceptual duplicate detection via pHash
- FR-006.3: Near-duplicate detection via embedding similarity
- FR-006.4: Blurry image detection
- FR-006.5: Smart cleanup recommendations

## FR-007: Secure Vault
- FR-007.1: AES-256-GCM encryption for vault files
- FR-007.2: Biometric authentication (fingerprint, Face ID)
- FR-007.3: Password-based fallback authentication
- FR-007.4: Secure delete (overwrite-before-delete)

## FR-008: File Monitoring
- FR-008.1: Watch user-defined directories for new files
- FR-008.2: Auto-index new and modified files
- FR-008.3: Handle file renames and deletions

## FR-009: Settings
- FR-009.1: Configure watched directories
- FR-009.2: Select active AI model
- FR-009.3: Toggle OCR, AI, duplicate detection
- FR-009.4: Language and theme preferences
