//! AES-256-GCM encryption for the Secure Vault feature.

use crate::error::CoreError;
use aes_gcm::{
    aead::{Aead, AeadCore, KeyInit, OsRng},
    Aes256Gcm, Key, Nonce,
};
use argon2::{password_hash::SaltString, Argon2, PasswordHasher};
use sha2::{Digest, Sha256};

const NONCE_SIZE: usize = 12;
const SALT_SIZE: usize = 16;

/// Derive a 256-bit key from a password using Argon2id.
pub fn derive_key(password: &str, salt: &[u8]) -> Result<[u8; 32], CoreError> {
    let mut key = [0u8; 32];
    Argon2::default()
        .hash_password_into(password.as_bytes(), salt, &mut key)
        .map_err(|e| CoreError::Encryption(e.to_string()))?;
    Ok(key)
}

/// Generate a random 16-byte salt.
pub fn generate_salt() -> [u8; SALT_SIZE] {
    let mut salt = [0u8; SALT_SIZE];
    use std::io::Read;
    // Use OsRng for cryptographically secure randomness
    getrandom::getrandom(&mut salt).unwrap_or_else(|_| {
        // Fallback: use timestamp + counter (not recommended for production)
        let t = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_nanos();
        let bytes = t.to_le_bytes();
        salt[..bytes.len().min(SALT_SIZE)].copy_from_slice(&bytes[..bytes.len().min(SALT_SIZE)]);
    });
    salt
}

/// Encrypt data using AES-256-GCM.
/// Returns: [salt (16 bytes)] + [nonce (12 bytes)] + [ciphertext]
pub fn encrypt(plaintext: &[u8], password: &str) -> Result<Vec<u8>, CoreError> {
    let salt = generate_salt();
    let key_bytes = derive_key(password, &salt)?;
    let key = Key::<Aes256Gcm>::from_slice(&key_bytes);
    let cipher = Aes256Gcm::new(key);
    let nonce = Aes256Gcm::generate_nonce(&mut OsRng);

    let ciphertext = cipher
        .encrypt(&nonce, plaintext)
        .map_err(|e| CoreError::Encryption(e.to_string()))?;

    let mut output = Vec::with_capacity(SALT_SIZE + NONCE_SIZE + ciphertext.len());
    output.extend_from_slice(&salt);
    output.extend_from_slice(nonce.as_slice());
    output.extend_from_slice(&ciphertext);
    Ok(output)
}

/// Decrypt data previously encrypted with [`encrypt`].
pub fn decrypt(ciphertext: &[u8], password: &str) -> Result<Vec<u8>, CoreError> {
    if ciphertext.len() < SALT_SIZE + NONCE_SIZE {
        return Err(CoreError::Encryption("ciphertext too short".into()));
    }
    let salt = &ciphertext[..SALT_SIZE];
    let nonce_bytes = &ciphertext[SALT_SIZE..SALT_SIZE + NONCE_SIZE];
    let data = &ciphertext[SALT_SIZE + NONCE_SIZE..];

    let key_bytes = derive_key(password, salt)?;
    let key = Key::<Aes256Gcm>::from_slice(&key_bytes);
    let cipher = Aes256Gcm::new(key);
    let nonce = Nonce::from_slice(nonce_bytes);

    cipher
        .decrypt(nonce, data)
        .map_err(|e| CoreError::Encryption(e.to_string()))
}

/// Compute SHA-256 hash of data, returning hex string.
pub fn sha256_hex(data: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data);
    format!("{:x}", hasher.finalize())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sha256_hex_deterministic() {
        let a = sha256_hex(b"hello world");
        let b = sha256_hex(b"hello world");
        assert_eq!(a, b);
        assert_eq!(a.len(), 64);
    }

    #[test]
    fn test_sha256_hex_different_for_different_input() {
        let a = sha256_hex(b"hello");
        let b = sha256_hex(b"world");
        assert_ne!(a, b);
    }

    #[test]
    fn test_encrypt_decrypt_roundtrip() {
        let plaintext = b"MemoryOS secure vault test data";
        let password = "test-password-123";
        let encrypted = encrypt(plaintext, password).unwrap();
        let decrypted = decrypt(&encrypted, password).unwrap();
        assert_eq!(plaintext.as_slice(), decrypted.as_slice());
    }

    #[test]
    fn test_decrypt_wrong_password_fails() {
        let plaintext = b"secret data";
        let encrypted = encrypt(plaintext, "correct-password").unwrap();
        let result = decrypt(&encrypted, "wrong-password");
        assert!(result.is_err());
    }

    #[test]
    fn test_derive_key_deterministic_with_same_salt() {
        let salt = [0u8; 16];
        let key1 = derive_key("password", &salt).unwrap();
        let key2 = derive_key("password", &salt).unwrap();
        assert_eq!(key1, key2);
    }

    #[test]
    fn test_encrypted_output_contains_salt_and_nonce() {
        let encrypted = encrypt(b"test", "pw").unwrap();
        assert!(encrypted.len() > SALT_SIZE + NONCE_SIZE);
    }
}
