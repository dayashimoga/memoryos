# Frequently Asked Questions

## General

**Q: Is MemoryOS really 100% offline?**
A: Yes. All AI inference, OCR, search, and storage runs locally. The only network request is when you explicitly download an AI model.

**Q: What data does MemoryOS collect?**
A: None. No telemetry, no analytics, no crash reports. Your data never leaves your device.

**Q: Does MemoryOS work on mobile?**
A: Yes. Android and iOS are supported. The UI adapts to mobile with a bottom navigation bar.

## AI Models

**Q: Which model should I download first?**
A: Start with **Qwen 2.5 1.5B** (~900 MB). It's the smallest and works well for most tasks. For better quality, try **Gemma 2 2B** or **Phi 3.5 Mini**.

**Q: Can I use my own GGUF models?**
A: Not in v1.0. Custom model import is planned for v1.3.

## Search

**Q: Why aren't my files showing in search?**
A: Check that the directory is added in Settings → Watch Directories and indexing is complete (progress shown on home screen).

**Q: Is semantic search available without an AI model?**
A: No. Semantic vector search requires an embedding model. Without it, full-text search (FTS5) is used instead.

## Security

**Q: Can I lose my vault files if I forget my password?**
A: Yes. The vault uses AES-256-GCM with no recovery mechanism. Keep your password safe.

**Q: Where is the database stored?**
A: `~/.memoryos/metadata.db` on Linux/macOS, `%APPDATA%\MemoryOS\metadata.db` on Windows.
