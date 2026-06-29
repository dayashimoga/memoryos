# Privacy Model

## Privacy Principles

1. **Data Minimization**: Only metadata required for functionality is stored.
2. **Local Processing**: All AI inference runs on-device.
3. **No Telemetry**: Zero analytics, crash reporting, or usage data collected.
4. **User Control**: Users can delete any file, collection, or all data.
5. **Transparency**: All data flows are documented and auditable.

## Data Inventory

| Data | Purpose | Retention | Deletion |
|------|---------|-----------|---------|
| File paths | Indexing | Until file deleted | On-demand |
| OCR text | Search | Until file deleted | On-demand |
| Embeddings | Semantic search | Until file deleted | On-demand |
| AI summaries | Knowledge base | Until file deleted | On-demand |
| Vault files | Secure storage | Until explicitly deleted | Secure delete |
| Activity log | Audit | 90 days (configurable) | On-demand |

## Network Access

MemoryOS makes network requests only for:
1. **Model Downloads**: HTTPS to HuggingFace CDN (user-initiated)
2. **Nothing else**: All search, OCR, AI, indexing is local

## GDPR Compliance

- Right to erasure: Implemented via "Delete All Data" in settings
- Right to access: All data viewable within the application
- Data portability: Export functionality (future roadmap)
- No data processor: Data stays on user's device
