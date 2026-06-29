FROM memoryos-builder:latest AS tester

RUN cargo install cargo-tarpaulin cargo-audit

CMD ["bash", "-c", "cargo test --workspace && flutter test apps/flutter_app"]
