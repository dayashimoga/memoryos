#!/usr/bin/env bash
# bootstrap.sh — Set up the development environment.
set -euo pipefail

echo "🚀 MemoryOS Bootstrap"
echo "====================="

# Check prerequisites
command -v docker &>/dev/null || { echo "ERROR: Docker not found. Install Docker Desktop."; exit 1; }
command -v git &>/dev/null || { echo "ERROR: Git not found."; exit 1; }

echo "✅ Prerequisites OK"

# Build Docker images
echo "🐳 Building Docker images..."
docker compose build

echo ""
echo "✅ Bootstrap complete!"
echo ""
echo "Run: docker compose up"
echo "Docs: http://localhost:8000"
echo "App:  http://localhost:3000"
