#!/usr/bin/env bash
# coverage.sh — Generate coverage reports for Rust and Flutter.
set -euo pipefail

echo "📊 Generating coverage reports..."

# Rust coverage via tarpaulin
cargo tarpaulin --workspace --out Html --output-dir coverage/rust/

# Flutter coverage
cd apps/flutter_app
flutter test --coverage
genhtml coverage/lcov.info -o ../../coverage/flutter/
cd ../..

echo ""
echo "✅ Coverage reports generated:"
echo "  Rust:    coverage/rust/tarpaulin-report.html"
echo "  Flutter: coverage/flutter/index.html"
