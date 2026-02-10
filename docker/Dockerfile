# ---------- Base image ----------
FROM ubuntu:22.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# ---------- System dependencies ----------
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    curl \
    ca-certificates \
    ninja-build \
    pkg-config \
    software-properties-common \
    # Vulkan / SPIR-V tooling
    libvulkan-dev \
    vulkan-tools \
    spirv-tools \
    glslang-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ---------- Python ----------
RUN python3 -m pip install --upgrade pip

# ---------- Default workdir ----------
WORKDIR /workspace

CMD ["/bin/bash"]
