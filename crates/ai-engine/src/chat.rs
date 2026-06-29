//! AI Chat — conversational interface over the user's knowledge base.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatMessage {
    pub role: ChatRole,
    pub content: String,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum ChatRole {
    User,
    Assistant,
    System,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatSession {
    pub id: String,
    pub messages: Vec<ChatMessage>,
    pub created_at: DateTime<Utc>,
}

impl ChatSession {
    pub fn new() -> Self {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            messages: vec![ChatMessage {
                role: ChatRole::System,
                content: "You are MemoryOS AI, a personal knowledge assistant. \
                         Answer questions based on the user's indexed files, screenshots, and documents. \
                         Be helpful, accurate, and cite relevant files when possible.".to_string(),
                timestamp: Utc::now(),
            }],
            created_at: Utc::now(),
        }
    }

    pub fn add_user_message(&mut self, content: impl Into<String>) {
        self.messages.push(ChatMessage {
            role: ChatRole::User,
            content: content.into(),
            timestamp: Utc::now(),
        });
    }

    pub fn add_assistant_message(&mut self, content: impl Into<String>) {
        self.messages.push(ChatMessage {
            role: ChatRole::Assistant,
            content: content.into(),
            timestamp: Utc::now(),
        });
    }

    /// Build a prompt from the conversation history for llama.cpp.
    pub fn build_prompt(&self) -> String {
        let mut prompt = String::new();
        for msg in &self.messages {
            match msg.role {
                ChatRole::System => {
                    prompt.push_str(&format!("<|system|>\n{}\n", msg.content));
                }
                ChatRole::User => {
                    prompt.push_str(&format!("<|user|>\n{}\n", msg.content));
                }
                ChatRole::Assistant => {
                    prompt.push_str(&format!("<|assistant|>\n{}\n", msg.content));
                }
            }
        }
        prompt.push_str("<|assistant|>\n");
        prompt
    }
}

impl Default for ChatSession {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_new_session_has_system_message() {
        let session = ChatSession::new();
        assert_eq!(session.messages.len(), 1);
        assert_eq!(session.messages[0].role, ChatRole::System);
    }

    #[test]
    fn test_add_messages() {
        let mut session = ChatSession::new();
        session.add_user_message("What did I learn about Kubernetes?");
        session.add_assistant_message("Based on your files...");
        assert_eq!(session.messages.len(), 3);
    }

    #[test]
    fn test_build_prompt_contains_roles() {
        let mut session = ChatSession::new();
        session.add_user_message("Hello");
        let prompt = session.build_prompt();
        assert!(prompt.contains("<|system|>"));
        assert!(prompt.contains("<|user|>"));
        assert!(prompt.contains("Hello"));
    }
}
