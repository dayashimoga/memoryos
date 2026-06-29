# syntax=docker/dockerfile:1.6
# Lightweight Flutter-only image (no Rust toolchain)
FROM debian:bookworm-slim AS base

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    unzip \
    xz-utils \
    wget \
    ca-certificates \
    libgtk-3-dev \
    libglib2.0-dev \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Flutter SDK
ENV FLUTTER_VERSION=3.22.2
ENV FLUTTER_HOME=/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone https://github.com/flutter/flutter.git ${FLUTTER_HOME} \
    --branch stable \
    --single-branch \
    --depth 1 && \
    flutter config --no-analytics && \
    flutter precache --web && \
    flutter --version

EXPOSE 3000

WORKDIR /flutter_app
