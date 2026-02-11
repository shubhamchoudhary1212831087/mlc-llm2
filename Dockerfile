# MLC-LLM Multipurpose Docker Image
# Serves as both Development Environment and Build Environment
#
# Usage:
#   Development (interactive): docker run -it --rm -v $(pwd):/workspace mlc-llm:latest /bin/bash
#   Build (non-interactive):   docker run --rm -v $(pwd):/workspace mlc-llm:latest
#
# Build args:
#   GPU: cpu (default), cuda-12.8, vulkan
#   PYTHON_VERSION: 3.10 (default), 3.11, 3.12

ARG BASE_IMAGE=ubuntu:22.04

# =============================================================================
# Stage 1: Base image with common dependencies
# =============================================================================
FROM ${BASE_IMAGE} AS base

ARG DEBIAN_FRONTEND=noninteractive
ARG PYTHON_VERSION=3.10
ARG GPU=cpu

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install base system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build essentials
    build-essential \
    cmake \
    ninja-build \
    git \
    curl \
    wget \
    ca-certificates \
    pkg-config \
    # Python
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-venv \
    python3-pip \
    # Rust (for tokenizers-cpp)
    rustc \
    cargo \
    # Vulkan dependencies
    libvulkan-dev \
    libvulkan1 \
    vulkan-tools \
    glslang-tools \
    spirv-tools \
    # Development tools
    gdb \
    valgrind \
    ccache \
    clang-format \
    # Utilities
    vim \
    less \
    htop \
    tree \
    jq \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Set Python as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1

# Upgrade pip and install essential Python packages
RUN python -m pip install --upgrade pip setuptools wheel

# =============================================================================
# Stage 2: Development dependencies
# =============================================================================
FROM base AS dev-deps

# Install development and testing tools
RUN python -m pip install \
    # Build tools
    scikit-build-core>=0.10.0 \
    auditwheel \
    patchelf \
    # Testing
    pytest \
    pytest-cov \
    pytest-xdist \
    # Linting and formatting
    black \
    isort \
    pylint \
    mypy \
    # Documentation
    sphinx \
    sphinx-rtd-theme \
    # Development utilities
    ipython \
    rich \
    httpx

# Install project dependencies (excluding flashinfer which requires special handling)
RUN python -m pip install \
    apache-tvm-ffi \
    datasets \
    fastapi \
    "ml_dtypes>=0.5.1" \
    openai \
    pandas \
    prompt_toolkit \
    requests \
    safetensors \
    sentencepiece \
    shortuuid \
    tiktoken \
    torch --index-url https://download.pytorch.org/whl/cpu \
    tqdm \
    transformers \
    uvicorn

# =============================================================================
# Stage 3: Final multipurpose image
# =============================================================================
FROM dev-deps AS final

ARG GPU=cpu

# Create workspace directory
WORKDIR /workspace

# Configure ccache
ENV CCACHE_DIR=/ccache \
    CCACHE_COMPILERCHECK=content \
    CCACHE_NOHASHDIR=1 \
    PATH="/usr/lib/ccache:${PATH}"

# Create ccache directory
RUN mkdir -p /ccache && chmod 777 /ccache

# Create entrypoint script for build mode
COPY <<'EOF' /usr/local/bin/build-entrypoint.sh
#!/bin/bash
set -eo pipefail

# Default values
: ${NUM_THREADS:=$(nproc)}
: ${GPU:="cpu"}
: ${BUILD_WHEEL:="1"}
: ${RUN_TESTS:="0"}

echo "=== MLC-LLM Build Environment ==="
echo "GPU: ${GPU}"
echo "Threads: ${NUM_THREADS}"
echo "Build wheel: ${BUILD_WHEEL}"
echo "Run tests: ${RUN_TESTS}"
echo "================================="

cd /workspace

# Configure CMake based on GPU
rm -f config.cmake
if [[ ${GPU} == cuda* ]]; then
    echo 'set(USE_VULKAN ON)' >> config.cmake
    echo 'set(USE_CUDA ON)' >> config.cmake
    echo 'set(USE_CUBLAS ON)' >> config.cmake
    echo 'set(USE_NCCL ON)' >> config.cmake
    echo 'set(CMAKE_CUDA_ARCHITECTURES "80;90;100;120")' >> config.cmake
elif [[ ${GPU} == vulkan ]]; then
    echo 'set(USE_VULKAN ON)' >> config.cmake
else
    echo 'set(USE_VULKAN ON)' >> config.cmake
fi

echo "CMake config:"
cat config.cmake

# Build wheel if requested
if [[ ${BUILD_WHEEL} == "1" ]]; then
    echo "Building wheel..."
    rm -rf dist build/wheel
    pip wheel --no-deps -w dist . -v
    
    # Repair wheel for manylinux if on Linux
    if [[ "$(uname)" == "Linux" ]]; then
        mkdir -p wheels
        AUDITWHEEL_OPTS="--plat manylinux_2_28_x86_64 -w wheels/"
        AUDITWHEEL_OPTS="--exclude libtvm --exclude libtvm_runtime --exclude libtvm_ffi --exclude libvulkan ${AUDITWHEEL_OPTS}"
        if [[ ${GPU} == cuda* ]]; then
            AUDITWHEEL_OPTS="--exclude libcuda --exclude libcudart --exclude libnvrtc --exclude libcublas --exclude libcublasLt ${AUDITWHEEL_OPTS}"
        fi
        auditwheel repair ${AUDITWHEEL_OPTS} dist/*.whl || mv dist/*.whl wheels/
    else
        mkdir -p wheels
        mv dist/*.whl wheels/
    fi
    
    echo "Wheel built successfully:"
    ls -la wheels/
fi

# Run tests if requested
if [[ ${RUN_TESTS} == "1" ]]; then
    echo "Running tests..."
    pip install wheels/*.whl --force-reinstall
    python -m pytest -v tests/python/ -m unittest
fi

echo "Build completed successfully!"
EOF
RUN chmod +x /usr/local/bin/build-entrypoint.sh

# Create development shell initialization
COPY <<'EOF' /usr/local/bin/dev-init.sh
#!/bin/bash
echo "=== MLC-LLM Development Environment ==="
echo "Python: $(python --version)"
echo "CMake: $(cmake --version | head -1)"
echo "Rust: $(rustc --version)"
echo ""
echo "Quick commands:"
echo "  build-entrypoint.sh    - Build the project"
echo "  pytest tests/python/   - Run tests"
echo "  black python/          - Format code"
echo "  pylint python/         - Lint code"
echo "========================================"
EOF
RUN chmod +x /usr/local/bin/dev-init.sh

# Add dev init to bashrc for interactive shells
RUN echo 'source /usr/local/bin/dev-init.sh' >> /etc/bash.bashrc

# Labels for container metadata
LABEL org.opencontainers.image.source="https://github.com/mlc-ai/mlc-llm"
LABEL org.opencontainers.image.description="MLC-LLM Development and Build Environment"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL maintainer="MLC LLM Contributors"

# Default entrypoint for build mode (non-interactive)
# Override with /bin/bash for development mode (interactive)
ENTRYPOINT ["/usr/local/bin/build-entrypoint.sh"]

# Default command (can be overridden)
CMD []
