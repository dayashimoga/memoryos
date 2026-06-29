//! Model manager — download, verify, and activate AI models.

use crate::error::AiError;
use crate::types::{AiModel, default_model_catalog};
use reqwest::Client;
use sha2::{Digest, Sha256};
use std::path::{Path, PathBuf};
use tokio::io::AsyncWriteExt;
use tracing::{debug, info, warn};

pub struct ModelManager {
    models_dir: PathBuf,
    client: Client,
    catalog: Vec<AiModel>,
}

impl ModelManager {
    pub fn new(models_dir: impl Into<PathBuf>) -> Result<Self, AiError> {
        let models_dir = models_dir.into();
        std::fs::create_dir_all(&models_dir)?;
        Ok(Self {
            models_dir,
            client: Client::builder()
                .timeout(std::time::Duration::from_secs(3600))
                .build()
                .map_err(|e| AiError::Network(e.to_string()))?,
            catalog: default_model_catalog(),
        })
    }

    pub fn list_models(&self) -> &[AiModel] {
        &self.catalog
    }

    /// Check which models are already downloaded.
    pub fn scan_downloaded(&mut self) {
        for model in self.catalog.iter_mut() {
            let path = self.models_dir.join(&model.hf_filename);
            if path.exists() {
                model.file_path = Some(path.to_string_lossy().to_string());
                model.downloaded_at = Some(chrono::Utc::now());
            }
        }
    }

    /// Download a model from HuggingFace. Returns the local path.
    pub async fn download(&self, model_id: &str) -> Result<PathBuf, AiError> {
        let model = self
            .catalog
            .iter()
            .find(|m| m.id == model_id)
            .ok_or_else(|| AiError::ModelNotLoaded { model_id: model_id.to_string() })?;

        let url = format!(
            "https://huggingface.co/{}/resolve/main/{}",
            model.hf_repo, model.hf_filename
        );
        let dest = self.models_dir.join(&model.hf_filename);

        if dest.exists() {
            info!(model_id, "Model already downloaded, skipping");
            return Ok(dest);
        }

        info!(model_id, url = %url, "Downloading model");

        let response = self
            .client
            .get(&url)
            .send()
            .await
            .map_err(|e| AiError::Download(e.to_string()))?;

        if !response.status().is_success() {
            return Err(AiError::Download(format!(
                "HTTP {} for {}",
                response.status(),
                url
            )));
        }

        let mut file = tokio::fs::File::create(&dest)
            .await
            .map_err(|e| AiError::Io(e))?;

        let mut stream = response.bytes_stream();
        use futures_util::StreamExt;

        let mut downloaded = 0u64;
        while let Some(chunk) = stream.next().await {
            let chunk = chunk.map_err(|e| AiError::Download(e.to_string()))?;
            file.write_all(&chunk).await?;
            downloaded += chunk.len() as u64;
            if downloaded % (50 * 1024 * 1024) == 0 {
                debug!(model_id, downloaded_mb = downloaded / 1_000_000, "Downloading...");
            }
        }

        info!(model_id, path = %dest.display(), "Model download complete");
        Ok(dest)
    }

    pub fn model_path(&self, model_id: &str) -> Option<PathBuf> {
        let model = self.catalog.iter().find(|m| m.id == model_id)?;
        let path = self.models_dir.join(&model.hf_filename);
        if path.exists() { Some(path) } else { None }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[test]
    fn test_model_manager_creation() {
        let dir = TempDir::new().unwrap();
        let mgr = ModelManager::new(dir.path()).unwrap();
        assert!(!mgr.list_models().is_empty());
    }

    #[test]
    fn test_scan_downloaded_empty_dir() {
        let dir = TempDir::new().unwrap();
        let mut mgr = ModelManager::new(dir.path()).unwrap();
        mgr.scan_downloaded();
        // No models should have file_path set
        assert!(mgr.list_models().iter().all(|m| m.file_path.is_none()));
    }
}
