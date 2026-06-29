################################################################################
# MemoryOS — Developer Makefile
# All commands run inside Docker (no local toolchain required).
# Usage: make <target>
################################################################################

COMPOSE = docker compose
BUILD_SVC = rust-build
CHECK_SVC = rust-check
TEST_SVC = rust-test
COV_SVC = rust-coverage
FLUTTER_WEB = flutter-web
FLUTTER_TEST = flutter-test
FLUTTER_ANALYZE = flutter-analyze
FLUTTER_BUILD = flutter-build-web
TESTER = tester

.PHONY: help build check test coverage flutter-web flutter-test flutter-analyze \
        flutter-build-web flutter-build-linux all-tests clean logs shell \
        security docs

# ─── Default ──────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo " MemoryOS Docker Commands"
	@echo " ─────────────────────────────────────────────"
	@echo " make build              → Rust workspace release build"
	@echo " make check              → Rust fmt + clippy + type check"
	@echo " make test               → Rust workspace tests"
	@echo " make coverage           → Rust test coverage (Tarpaulin)"
	@echo " make flutter-analyze    → Flutter analyze + format check"
	@echo " make flutter-test       → Flutter unit + widget tests + coverage gate"
	@echo " make flutter-web        → Flutter web dev server (localhost:3000)"
	@echo " make flutter-build-web  → Flutter web production build"
	@echo " make flutter-build-linux→ Flutter Linux desktop build"
	@echo " make all-tests          → Rust + Flutter tests in one container"
	@echo " make security           → cargo-audit security scan"
	@echo " make docs               → MkDocs server (localhost:8000)"
	@echo " make shell              → Interactive Rust/Flutter dev shell"
	@echo " make clean              → Remove built images + volumes"
	@echo ""

# ─── Rust ─────────────────────────────────────────────────────────────────────
build:
	@echo "🔨 Building Rust workspace..."
	$(COMPOSE) run --rm $(BUILD_SVC)

check:
	@echo "🔍 Running Rust checks (fmt + clippy + check)..."
	$(COMPOSE) run --rm $(CHECK_SVC)

test:
	@echo "🧪 Running Rust tests..."
	$(COMPOSE) run --rm $(TEST_SVC)

coverage:
	@echo "📊 Generating Rust coverage report..."
	$(COMPOSE) run --rm $(COV_SVC)

# ─── Flutter ──────────────────────────────────────────────────────────────────
flutter-analyze:
	@echo "🔍 Running Flutter analyze..."
	$(COMPOSE) run --rm $(FLUTTER_ANALYZE)

flutter-test:
	@echo "🧪 Running Flutter tests..."
	$(COMPOSE) run --rm $(FLUTTER_TEST)

flutter-web:
	@echo "🌐 Starting Flutter web dev server at http://localhost:3000 ..."
	$(COMPOSE) up $(FLUTTER_WEB)

flutter-build-web:
	@echo "📦 Building Flutter web production bundle..."
	$(COMPOSE) run --rm $(FLUTTER_BUILD)

flutter-build-linux:
	@echo "🐧 Building Flutter Linux desktop binary..."
	$(COMPOSE) run --rm flutter-build-linux

# ─── Combined ─────────────────────────────────────────────────────────────────
all-tests:
	@echo "🚀 Running all tests (Rust + Flutter)..."
	$(COMPOSE) run --rm $(TESTER)

# ─── Infrastructure ───────────────────────────────────────────────────────────
security:
	@echo "🔒 Running security audit..."
	$(COMPOSE) run --rm security

docs:
	@echo "📚 Starting documentation server at http://localhost:8000 ..."
	$(COMPOSE) up docs

shell:
	@echo "🐚 Opening interactive dev shell..."
	$(COMPOSE) run --rm -it builder bash

logs:
	$(COMPOSE) logs -f

clean:
	@echo "🧹 Cleaning Docker resources..."
	$(COMPOSE) down --volumes --remove-orphans
	docker image rm memoryos-builder:latest memoryos-flutter:latest memoryos-docs:latest 2>/dev/null || true
	@echo "Done."

# ─── Image rebuild ────────────────────────────────────────────────────────────
rebuild-images:
	@echo "🔄 Rebuilding all Docker images (no cache)..."
	$(COMPOSE) build --no-cache
