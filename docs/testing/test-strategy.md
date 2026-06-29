# Test Strategy

## Objectives
- Achieve ≥ 90% line coverage across all Rust crates and Flutter code
- Maintain 100% test pass rate in CI
- Prevent security regressions via automated scanning

## Testing Pyramid

```mermaid
pyramid
```

```
         /\
        /  \     E2E Tests (Flutter Integration Tests)
       /────\
      /      \   Integration Tests (Cross-crate, DB)
     /────────\
    /          \ Unit Tests (Rust + Flutter BLoC)
   /────────────\
  / Property-Based\ Tests (proptest, Rust)
 /────────────────\
```

## Test Levels

### Unit Tests
**Rust**: `cargo test --workspace`
- All domain models
- All service functions
- Crypto operations
- Database CRUD
- OCR parsing
- Search logic
- Duplicate detection algorithms

**Flutter**: `flutter test`
- BLoC state transitions
- Widget rendering
- Router configuration
- Theme application
- Service locator

### Integration Tests
Located in `tests/integration/`
- Database + file monitor integration
- OCR + indexing pipeline
- AI engine + search round-trip

### End-to-End Tests
Located in `tests/e2e/`
- Full file ingestion flow
- Natural language search
- AI chat session
- Vault encrypt/decrypt

### Golden UI Tests
- Visual regression via `golden_toolkit`
- Run on every PR

### Property-Based Tests
**Rust** with `proptest`:
- SHA-256 uniqueness properties
- pHash Hamming distance properties
- Encryption round-trip properties

### Performance Benchmarks
**Rust** with `criterion`:
- File indexing throughput
- Search query latency
- OCR processing time

## Coverage Gates

| Gate | Threshold | Enforcement |
|------|-----------|------------|
| Rust line coverage | ≥ 90% | CI fails |
| Flutter line coverage | ≥ 90% | CI fails |
| Lint warnings | 0 | CI fails |
| Security vulns (HIGH+) | 0 | CI fails |

## Tools

| Tool | Purpose |
|------|---------|
| `cargo test` | Rust unit tests |
| `cargo-tarpaulin` | Rust coverage |
| `proptest` | Rust property tests |
| `criterion` | Rust benchmarks |
| `cargo-mutants` | Mutation testing |
| `flutter test` | Flutter unit tests |
| `golden_toolkit` | Flutter golden tests |
| `integration_test` | Flutter E2E |
| `cargo-audit` | Rust security |
| `trivy` | Container security |
| `CodeQL` | Static analysis |
