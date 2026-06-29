#!/usr/bin/env bash
# test.sh — Run all tests (Rust + Flutter).
set -euo pipefail

echo "🧪 Running MemoryOS test suite..."

# Rust tests
echo "--- Rust unit tests ---"
cargo test --workspace

# Flutter tests
echo "--- Flutter tests ---"
cd apps/flutter_app && flutter pub get && flutter test

echo ""
echo "✅ All tests passed!"
