#!/usr/bin/env bash
# lint.sh — Run all linters.
set -euo pipefail

echo "🔍 Running linters..."

echo "--- cargo fmt ---"
cargo fmt --all -- --check

echo "--- cargo clippy ---"
cargo clippy --all-targets --all-features -- -D warnings

echo "--- flutter analyze ---"
cd apps/flutter_app && flutter analyze --fatal-infos

echo "--- dart format ---"
dart format --set-exit-if-changed .

echo ""
echo "✅ All linters passed!"
