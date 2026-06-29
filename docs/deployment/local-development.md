# Local Development Guide

## Prerequisites

You only need two tools:
1. **Docker Desktop** — https://docker.com/products/docker-desktop
2. **Git** — https://git-scm.com

## Quick Start

```bash
git clone https://github.com/your-org/memoryos.git
cd memoryos
docker compose up
```

Services:
- **Flutter Web Preview**: http://localhost:3000
- **Documentation**: http://localhost:8000

## Development Workflow

### Run all tests
```bash
docker compose run --rm tester
```

### Enter development shell
```bash
docker compose run --rm builder bash
```

Inside the shell:
```bash
cargo test --workspace          # Rust tests
cargo clippy --all-targets      # Rust linting
cargo fmt                       # Rust formatting
cd apps/flutter_app
flutter test                    # Flutter tests
flutter analyze                 # Flutter linting
```

### VS Code Dev Containers

1. Install [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. Open the project: `code .`
3. Click "Reopen in Container" when prompted

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RUST_LOG` | `info` | Rust logging level |
| `MEMORYOS_DATA_DIR` | `~/.memoryos` | Data directory |

## Database

The SQLite database is created at `$MEMORYOS_DATA_DIR/metadata.db` on first run.

To reset the database:
```bash
rm ~/.memoryos/metadata.db
```

## AI Models

Models are stored in `$MEMORYOS_DATA_DIR/models/`. Download via the app's Settings → AI Models page.

Manual download:
```bash
# Qwen 2.5 1.5B (smallest, good for testing)
curl -L -o ~/.memoryos/models/qwen2.5-1.5b-instruct-q4_k_m.gguf \
  "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf"
```
