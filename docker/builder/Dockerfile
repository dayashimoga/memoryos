# syntax=docker/dockerfile:1.6
FROM rust:1.87-slim-bookworm AS base


# System dependencies for Rust + rusqlite (bundled) + Flutter Linux
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    libssl-dev \
    cmake \
    ninja-build \
    git \
    curl \
    wget \
    unzip \
    xz-utils \
    clang \
    libgtk-3-dev \
    libblkid-dev \
    liblzma-dev \
    libglib2.0-dev \
    libpango1.0-dev \
    libatk1.0-dev \
    libgdk-pixbuf2.0-dev \
    libcairo2-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Rust tools
RUN rustup component add rustfmt clippy
RUN cargo install cargo-tarpaulin --locked || true

# Flutter SDK
ENV FLUTTER_VERSION=3.24.3
ENV FLUTTER_HOME=/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone https://github.com/flutter/flutter.git ${FLUTTER_HOME} \
    --branch 3.24.3 \
    --single-branch \
    --depth 1 && \
    flutter config --no-analytics && \
    flutter precache --linux --web && \
    flutter --version

WORKDIR /workspace

# Pre-cache Cargo dependencies (layer cache)
# Cargo.lock is optional at this stage (generated on first build)
COPY Cargo.toml ./
COPY --chown=root:root crates/ crates/
RUN cargo fetch 2>/dev/null || cargo fetch --no-deps 2>/dev/null || true

CMD ["/bin/bash"]
