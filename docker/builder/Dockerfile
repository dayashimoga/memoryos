FROM rust:1.75-slim-bookworm AS builder

RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    libsqlite3-dev \
    cmake \
    ninja-build \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /flutter --branch stable --depth 1
ENV PATH="/flutter/bin:${PATH}"
RUN flutter precache --linux

WORKDIR /workspace

# Pre-cache Cargo dependencies
COPY Cargo.toml Cargo.lock ./
COPY crates/ crates/
RUN cargo fetch

CMD ["/bin/bash"]
