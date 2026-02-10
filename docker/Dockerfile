# Use NVIDIA CUDA base for GPU support
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# 1. Update and Enable Universe (Required for SPIRV tools)
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update

# 2. Install System Dependencies
# FIX: Removed 'spirv-headers' (does not exist in apt)
# KEPT: 'libspirv-tools-dev' and 'spirv-tools' (exist in universe)
RUN apt-get install -y \
    build-essential \
    cmake \
    git \
    python3-dev \
    python3-pip \
    python3-setuptools \
    libvulkan-dev \
    vulkan-tools \
    spirv-tools \
    glslang-tools \
    libspirv-tools-dev \
    curl \
    ca-certificates \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# 3. Install Rust
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# 4. Pre-install Python Dependencies
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir \
    numpy \
    decorator \
    scipy \
    tornado \
    psutil \
    xgboost \
    cloudpickle \
    attrs \
    typing-extensions \
    pybind11

# 5. Setup Entrypoint
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 6. Configuration
WORKDIR /mlc-llm
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
