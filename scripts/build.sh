#!/usr/bin/env bash
# build.sh — Build all Rust crates and Flutter app.
set -euo pipefail

TARGET="${1:-debug}"
echo "🔨 Building MemoryOS ($TARGET)..."

if [ "$TARGET" == "release" ]; then
    cargo build --workspace --release
    cd apps/flutter_app
    flutter clean
    flutter build linux --release
    mkdir -p build/linux/x64/release/bundle/lib
    cp ../../target/release/libcore_engine.so build/linux/x64/release/bundle/lib/
    cd ../..
else
    cargo build --workspace
fi

echo ""
echo "✅ Build complete!"
