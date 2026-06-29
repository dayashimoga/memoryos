//! Text summarization using the active local AI model.

use crate::error::AiError;
use crate::types::{GenerateRequest, GenerateResponse};
use tracing::debug;

/// Summarize a block of text using the local AI model.
pub async fn summarize(
    text: &str,
    model_id: &str,
    max_words: usize,
) -> Result<String, AiError> {
    if text.trim().is_empty() {
        return Ok(String::new());
    }

    let prompt = format!(
        "Summarize the following text in at most {} words. Be concise and informative.\n\nText:\n{}\n\nSummary:",
        max_words, text
    );

    let request = GenerateRequest {
        model_id: model_id.to_string(),
        prompt,
        system_prompt: Some(
            "You are a helpful assistant that summarizes documents concisely.".to_string(),
        ),
        max_tokens: max_words * 2,
        temperature: 0.3,
        stop_sequences: vec!["\n\n".to_string()],
    };

    let response = run_inference(request).await?;
    Ok(response.text.trim().to_string())
}

/// Generate flashcards from text content.
pub async fn generate_flashcards(
    text: &str,
    model_id: &str,
    count: usize,
) -> Result<Vec<(String, String)>, AiError> {
    let prompt = format!(
        "Generate {} flashcard question-answer pairs from the following text.\n\
        Format each as: Q: <question>\\nA: <answer>\\n---\n\nText:\n{}\n\nFlashcards:",
        count, text
    );

    let request = GenerateRequest {
        model_id: model_id.to_string(),
        prompt,
        system_prompt: Some(
            "You create educational flashcards. Each card tests a key concept.".to_string(),
        ),
        max_tokens: count * 100,
        temperature: 0.5,
        stop_sequences: Vec::new(),
    };

    let response = run_inference(request).await?;
    let cards = parse_flashcards(&response.text);
    Ok(cards)
}

fn parse_flashcards(text: &str) -> Vec<(String, String)> {
    let mut cards = Vec::new();
    for block in text.split("---") {
        let mut q = String::new();
        let mut a = String::new();
        for line in block.lines() {
            if let Some(question) = line.strip_prefix("Q:") {
                q = question.trim().to_string();
            } else if let Some(answer) = line.strip_prefix("A:") {
                a = answer.trim().to_string();
            }
        }
        if !q.is_empty() && !a.is_empty() {
            cards.push((q, a));
        }
    }
    cards
}

/// Run inference via llama.cpp server (HTTP API at localhost:8080).
async fn run_inference(request: GenerateRequest) -> Result<GenerateResponse, AiError> {
    let start = std::time::Instant::now();

    // llama.cpp server API: POST /completion
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(120))
        .build()
        .map_err(|e| AiError::Network(e.to_string()))?;

    let body = serde_json::json!({
        "prompt": request.prompt,
        "n_predict": request.max_tokens,
        "temperature": request.temperature,
        "stop": request.stop_sequences,
    });

    let response = client
        .post("http://localhost:8080/completion")
        .json(&body)
        .send()
        .await
        .map_err(|e| AiError::Inference(format!("llama.cpp server not available: {}", e)))?;

    if !response.status().is_success() {
        return Err(AiError::Inference(format!(
            "llama.cpp returned HTTP {}",
            response.status()
        )));
    }

    let json: serde_json::Value = response
        .json()
        .await
        .map_err(|e| AiError::Inference(e.to_string()))?;

    let text = json["content"]
        .as_str()
        .unwrap_or("")
        .to_string();

    Ok(GenerateResponse {
        text,
        prompt_tokens: json["tokens_evaluated"].as_u64().unwrap_or(0) as usize,
        completion_tokens: json["tokens_predicted"].as_u64().unwrap_or(0) as usize,
        latency_ms: start.elapsed().as_millis() as u64,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_flashcards_valid() {
        let text = "Q: What is Kubernetes?\nA: Container orchestration system\n---\nQ: What is a Pod?\nA: Smallest deployable unit\n---";
        let cards = parse_flashcards(text);
        assert_eq!(cards.len(), 2);
        assert_eq!(cards[0].0, "What is Kubernetes?");
        assert_eq!(cards[1].1, "Smallest deployable unit");
    }

    #[test]
    fn test_parse_flashcards_empty() {
        let cards = parse_flashcards("");
        assert!(cards.is_empty());
    }
}
