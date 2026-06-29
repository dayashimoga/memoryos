//! AI-powered file categorization.

use crate::error::AiError;
use serde::{Deserialize, Serialize};

/// Predefined category taxonomy.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum Category {
    Cloud,
    Security,
    Development,
    Finance,
    Medical,
    Legal,
    Learning,
    Chess,
    Travel,
    Personal,
    Work,
    Receipt,
    Invoice,
    Meeting,
    Project,
    Screenshot,
    Unknown,
}

impl Category {
    pub fn as_str(&self) -> &'static str {
        match self {
            Category::Cloud => "Cloud",
            Category::Security => "Security",
            Category::Development => "Development",
            Category::Finance => "Finance",
            Category::Medical => "Medical",
            Category::Legal => "Legal",
            Category::Learning => "Learning",
            Category::Chess => "Chess",
            Category::Travel => "Travel",
            Category::Personal => "Personal",
            Category::Work => "Work",
            Category::Receipt => "Receipt",
            Category::Invoice => "Invoice",
            Category::Meeting => "Meeting",
            Category::Project => "Project",
            Category::Screenshot => "Screenshot",
            Category::Unknown => "Unknown",
        }
    }

    /// Classify text using keyword heuristics (fast path before AI).
    pub fn classify_by_keywords(text: &str) -> Vec<Self> {
        let text_lower = text.to_lowercase();
        let mut categories = Vec::new();

        let rules: &[(&[&str], Category)] = &[
            (
                &[
                    "aws",
                    "azure",
                    "gcp",
                    "kubernetes",
                    "docker",
                    "cloud",
                    "ec2",
                    "s3",
                ],
                Category::Cloud,
            ),
            (
                &[
                    "security",
                    "vulnerability",
                    "cve",
                    "exploit",
                    "firewall",
                    "tls",
                    "ssl",
                ],
                Category::Security,
            ),
            (
                &[
                    "rust",
                    "python",
                    "javascript",
                    "typescript",
                    "code",
                    "function",
                    "class",
                ],
                Category::Development,
            ),
            (
                &[
                    "invoice",
                    "billing",
                    "payment",
                    "amount due",
                    "vat",
                    "tax id",
                ],
                Category::Invoice,
            ),
            (
                &["receipt", "total", "subtotal", "cash", "card"],
                Category::Receipt,
            ),
            (
                &["meeting", "agenda", "minutes", "attendees", "action items"],
                Category::Meeting,
            ),
            (
                &[
                    "chess", "opening", "endgame", "pawn", "rook", "bishop", "queen", "king",
                ],
                Category::Chess,
            ),
            (
                &["learn", "tutorial", "course", "study", "flashcard", "quiz"],
                Category::Learning,
            ),
            (
                &[
                    "flight",
                    "hotel",
                    "itinerary",
                    "passport",
                    "visa",
                    "booking",
                ],
                Category::Travel,
            ),
        ];

        for (keywords, category) in rules {
            if keywords.iter().any(|kw| text_lower.contains(kw)) {
                categories.push(category.clone());
            }
        }

        if categories.is_empty() {
            categories.push(Category::Unknown);
        }
        categories
    }
}

/// Categorize a file based on its text content.
/// Uses keyword heuristics first, then AI for ambiguous cases.
pub async fn categorize(text: &str, _model_id: Option<&str>) -> Result<Vec<Category>, AiError> {
    // Fast path: keyword-based classification
    let keyword_cats = Category::classify_by_keywords(text);

    // If keyword classification is confident (not Unknown), return it
    if !keyword_cats.iter().all(|c| c == &Category::Unknown) {
        return Ok(keyword_cats);
    }

    // TODO: AI-based classification for ambiguous cases
    // This would call the summarizer's run_inference with a classification prompt
    Ok(vec![Category::Unknown])
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_classify_aws_screenshot() {
        let text = "EC2 instance running in us-east-1 region, attached S3 bucket for logs";
        let cats = Category::classify_by_keywords(text);
        assert!(cats.contains(&Category::Cloud));
    }

    #[test]
    fn test_classify_chess() {
        let text = "The bishop controls the diagonal while the queen dominates the board";
        let cats = Category::classify_by_keywords(text);
        assert!(cats.contains(&Category::Chess));
    }

    #[test]
    fn test_classify_invoice() {
        let text = "Invoice #1234, Amount Due: $500.00, Payment due in 30 days";
        let cats = Category::classify_by_keywords(text);
        assert!(cats.contains(&Category::Invoice));
    }

    #[test]
    fn test_classify_unknown() {
        let text = "hello world";
        let cats = Category::classify_by_keywords(text);
        assert!(cats.contains(&Category::Unknown));
    }

    #[tokio::test]
    async fn test_categorize_returns_result() {
        let result = categorize("AWS EC2 instance management", None).await;
        assert!(result.is_ok());
        assert!(!result.unwrap().is_empty());
    }
}
