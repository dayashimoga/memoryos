# Threat Model

## Overview

MemoryOS is an offline-first application. The primary threats are local rather than network-based.

## STRIDE Analysis

### Spoofing
- **Vault Authentication Bypass**: Mitigated by Argon2id key derivation and AES-256-GCM authenticated encryption.
- **Biometric Bypass**: Relies on platform biometric APIs (Android BiometricPrompt, iOS LocalAuthentication) with secure enclave.

### Tampering
- **Database Modification**: SQLite WAL mode; vault files are AES-GCM authenticated (any tampering detected).
- **Model File Substitution**: SHA-256 verification of downloaded model files.

### Repudiation
- **Audit Log**: Activity log in SQLite for all file ingestion and access events.

### Information Disclosure
- **File Content Leakage**: No network egress of file content. AI inference is local.
- **Vault Contents**: Protected by AES-256-GCM; requires authentication.
- **Temporary Files**: OCR temp files cleaned up immediately after processing.

### Denial of Service
- **Infinite Indexing Loop**: File monitor uses polling with deduplication; no event storm possible.
- **Large File Handling**: Streaming reads for large files; no full-file in-memory loads.

### Elevation of Privilege
- **No root/admin required**: MemoryOS operates entirely in user space.

## Mitigations Summary

| Threat | Mitigation |
|--------|-----------|
| Vault access without auth | AES-256-GCM + Argon2id + biometric |
| Network data exfiltration | Zero mandatory network calls; network only for model downloads |
| Malicious model files | SHA-256 verification before loading |
| SQL injection | Parameterized queries throughout |
| Path traversal | `std::path::Path` canonicalization |
| Dependency vulnerabilities | `cargo-audit` + Dependabot + weekly scans |

## Data Classification

| Data | Classification | Storage |
|------|---------------|---------|
| File content | Private | Local only |
| OCR text | Private | SQLite (plaintext unless vaulted) |
| AI summaries | Private | SQLite |
| Vault files | Confidential | AES-256-GCM |
| User settings | Internal | SQLite |
| Activity logs | Internal | SQLite |
