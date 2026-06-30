# syntax=docker/dockerfile:1.6
# MemoryOS Android build image — Rust + NDK + Flutter
FROM rust:1.87-slim-bookworm AS base

# System dependencies for Android, Flutter, and general build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    git \
    curl \
    unzip \
    zip \
    xz-utils \
    wget \
    openjdk-17-jdk-headless \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Android SDK Environment Setup
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/build-tools/35.0.0"

# Download Android Command Line Tools (version 11076708 = 2024.x)
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d /tmp && \
    mv /tmp/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm -f /tmp/cmdline-tools.zip

# Accept Licenses and Install SDK, NDK, and CMake dependencies
# NDK 27.0.12077973 matches build.gradle ndkVersion pin
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" \
               "platforms;android-35" \
               "build-tools;35.0.0" \
               "ndk;27.0.12077973" \
               "cmake;3.22.1"

# Set Android NDK Home to match build.gradle ndkVersion exactly
ENV ANDROID_NDK_HOME=${ANDROID_HOME}/ndk/27.0.12077973
ENV ANDROID_NDK_ROOT=${ANDROID_HOME}/ndk/27.0.12077973

# Add Rust compilation targets for all Android ABIs and install cargo-ndk
RUN rustup target add \
        aarch64-linux-android \
        armv7-linux-androideabi \
        x86_64-linux-android \
        i686-linux-android && \
    cargo install cargo-ndk --locked

# Install Flutter SDK
ENV FLUTTER_VERSION=3.24.3
ENV FLUTTER_HOME=/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone https://github.com/flutter/flutter.git ${FLUTTER_HOME} \
    --branch 3.24.3 \
    --single-branch \
    --depth 1 && \
    flutter config --no-analytics && \
    flutter config --enable-android && \
    flutter precache --android && \
    flutter doctor -v || true

WORKDIR /workspace

CMD ["/bin/bash"]
