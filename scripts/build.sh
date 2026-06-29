#!/usr/bin/env bash
# build.sh — Build all Rust crates and Flutter app.
set -euo pipefail

TARGET="${1:-debug}"
echo "🔨 Building MemoryOS ($TARGET)..."

if [ "$TARGET" == "release" ]; then
    cargo build --workspace --release
    cd apps/flutter_app && flutter build linux --release
else
    cargo build --workspace
fi

echo ""
echo "✅ Build complete!"
