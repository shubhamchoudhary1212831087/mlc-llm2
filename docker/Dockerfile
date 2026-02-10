# 1️⃣ Base Image (Matches your requirement: NVIDIA CUDA dev)
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# 2️⃣ System Dependencies
# Added 'pkg-config' and 'libssl-dev' which are critical for Rust compilation
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    ninja-build \
    build-essential \
    llvm \
    clang \
    curl \
    ca-certificates \
    python3 \
    python3-pip \
    python3-dev \
    libtinfo-dev \
    zlib1g-dev \
    libxml2-dev \
    libedit-dev \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 3️⃣ CRITICAL: Install Rust (Globally available)
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain stable && \
    chmod -R a+w /usr/local/cargo

# 4️⃣ Python Setup
RUN python3 -m pip install --upgrade pip setuptools wheel && \
    pip3 install --no-cache-dir \
    numpy \
    scipy \
    psutil \
    decorator \
    attrs \
    cloudpickle \
    typing-extensions

# 5️⃣ Git Safety (Fixes "dubious ownership" errors in CI)
RUN git config --global --add safe.directory '*'

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /mlc-llm
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
