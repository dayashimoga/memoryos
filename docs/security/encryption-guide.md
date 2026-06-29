# MemoryOS Encryption & Security Guide

## Overview

MemoryOS implements end-to-end encryption for sensitive operations using industry-standard cryptographic primitives. All encryption happens **on-device** — no keys or data are ever transmitted externally.

## Cryptographic Stack

| Algorithm | Usage | Standard |
|-----------|-------|----------|
| **AES-256-GCM** | Symmetric encryption for vault files and backups | NIST SP 800-38D |
| **Argon2id** | Password-based key derivation | RFC 9106 (winner of PHC) |
| **SHA-256** | File integrity hashing for duplicate detection | FIPS 180-4 |
| **getrandom** | Cryptographic nonce generation | OS CSPRNG |

## Vault Encryption

Individual files can be encrypted in the vault:

```
User Action: "Lock file X"
    ↓
1. Generate random AES key via Argon2id(user_passphrase)
2. Generate random 12-byte nonce via getrandom
3. Encrypt file content: AES-256-GCM(key, nonce, plaintext)
4. Store: [nonce | ciphertext | auth_tag]
5. Set is_encrypted = true in database
6. Securely overwrite original plaintext
```

## Backup Encryption

Encrypted backups protect the entire database and indexed content:

```
perform_backup(data_dir, backup_path, key_phrase)
    ↓
1. Walk data_dir → collect all DB and metadata files
2. Create in-memory ZIP archive (zip crate, Deflate compression)
3. Derive 256-bit key: SHA-256(key_phrase)
4. Generate random 12-byte nonce: getrandom(&mut nonce_bytes)
5. Encrypt: ciphertext = AES-256-GCM.encrypt(key, nonce, zip_buffer)
6. Write to backup_path: [nonce (12 bytes)] + [ciphertext]
```

### Backup Format

```
Byte offset  | Content
-------------|------------------
0..12        | Random nonce (12 bytes)
12..EOF      | AES-256-GCM ciphertext (includes auth tag)
```

### Restore Process

```
restore_backup(backup_path, data_dir, key_phrase)
    ↓
1. Read backup file
2. Validate length ≥ 12 bytes
3. Extract nonce = bytes[0..12]
4. Extract ciphertext = bytes[12..EOF]
5. Derive key: SHA-256(key_phrase)
6. Decrypt: zip_buffer = AES-256-GCM.decrypt(key, nonce, ciphertext)
7. Extract ZIP contents to data_dir
```

## Security Properties

### Confidentiality
- AES-256-GCM provides authenticated encryption with 256-bit key strength
- Random nonce per encryption prevents multi-target attacks

### Integrity
- GCM's authentication tag detects any tampering with ciphertext
- Wrong password results in decryption failure (not silent corruption)

### Nonce Management
- **Random 12-byte nonces** generated via the OS CSPRNG
- Nonce is stored alongside ciphertext (public information by design)
- **No nonce reuse**: Each backup/vault operation generates a fresh nonce

### Key Derivation
- Argon2id parameters are configurable for balancing security vs. performance
- SHA-256 is used for backup key derivation (suitable for high-entropy passphrases)

## Threat Model

| Threat | Mitigation |
|--------|-----------|
| Device theft | Vault encryption protects sensitive files |
| Backup interception | AES-256-GCM encryption with user passphrase |
| Cloud exposure | Zero-cloud architecture — no data leaves device |
| Memory dumps | Rust's ownership model limits key lifetime in memory |
| Brute force | Argon2id's memory-hard design resists GPU attacks |
| Nonce reuse | Random nonce per operation via getrandom |

## CI Security Scanning

The CI pipeline includes automated security checks:

1. **cargo-audit**: Scans Rust dependencies for known vulnerabilities
2. **Trivy**: Filesystem scanner for HIGH/CRITICAL CVEs
3. **clippy**: Lint checks including unsafe code patterns
4. **cargo fmt**: Format enforcement for code review consistency
