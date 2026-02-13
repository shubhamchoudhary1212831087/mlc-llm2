# MLC-LLM Multipurpose Docker Image
# ===================================
# Aligned with official "Build from Source" documentation:
#   https://llm.mlc.ai/docs/install/mlc_llm.html#option-2-build-from-source
#
# Steps: Step 1 (dependencies) → Step 2 (configure & build) → Step 3 (pip install) → Step 4 (validate)
#
# Serves as BOTH:
#   1. Development environment (interactive shell, source mounted, dev tools)
#   2. Build environment (non-interactive entrypoint for compile + validate)
#
# Usage (run from mlc-llm repo root so /workspace has CMakeLists.txt):
#   Development (interactive; skip build script):
#     docker run -it --rm --entrypoint /bin/bash -v $(pwd):/workspace IMAGE
#   Build (non-interactive; runs Step 2–4):
#     docker run --rm -v $(pwd):/workspace IMAGE
#
# Build args:
#   MLC_BACKEND: vulkan (default) | cuda   (per doc: Vulkan or CUDA >= 11.8)
#   PYTHON_VERSION: 3.10 (default; doc also references 3.13)

ARG BASE_IMAGE=ubuntu:22.04

# =============================================================================
# Step 1. Set up build dependency (per doc)
# =============================================================================
# Doc: CMake >= 3.24, Git, Rust/Cargo, one of CUDA | Metal | Vulkan
FROM ${BASE_IMAGE} AS base

ARG DEBIAN_FRONTEND=noninteractive
ARG PYTHON_VERSION=3.10

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# System deps: build-essential, ninja, git, Python, Rust/Cargo (Hugging Face tokenizer), Vulkan
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ninja-build \
    git \
    curl \
    wget \
    ca-certificates \
    pkg-config \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-venv \
    python3-pip \
    rustc \
    cargo \
    libvulkan-dev \
    libvulkan1 \
    vulkan-tools \
    glslang-tools \
    glslang-dev \
    spirv-tools \
    spirv-headers \
    gdb \
    ccache \
    clang-format \
    vim \
    less \
    htop \
    tree \
    jq \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1

# CMake >= 3.24 (per doc)
RUN python -m pip install --upgrade pip setuptools wheel \
    && pip install "cmake>=3.24" ninja

RUN echo "=== Step 1 verified ===" \
    && cmake --version \
    && git --version \
    && rustc --version \
    && cargo --version \
    && python --version

# =============================================================================
# Dev tools + Python deps + TVM runtime
# =============================================================================
FROM base AS dev-deps

RUN pip install \
    pytest pytest-cov pytest-xdist \
    black isort pylint mypy \
    build wheel auditwheel patchelf \
    ipython rich

RUN pip install \
    datasets fastapi "ml_dtypes>=0.5.1" openai pandas prompt_toolkit \
    requests safetensors sentencepiece shortuuid tiktoken tqdm transformers uvicorn \
    && pip install torch --extra-index-url https://download.pytorch.org/whl/cpu

# TVM runtime required by mlc_llm Python package (per MLC wheels)
RUN pip install --pre -U -f https://mlc.ai/wheels mlc-ai-nightly-cpu

# =============================================================================
# Final image: workspace, entrypoint, dev-init
# =============================================================================
FROM dev-deps AS final

# Per doc: one of Vulkan | CUDA | Metal. We support vulkan (default) and cuda.
ARG MLC_BACKEND=vulkan
ENV MLC_BACKEND=${MLC_BACKEND}

WORKDIR /workspace

ENV CCACHE_DIR=/ccache \
    CCACHE_COMPILERCHECK=content \
    CCACHE_NOHASHDIR=1 \
    PATH="/usr/lib/ccache:${PATH}"

RUN mkdir -p /ccache && chmod 777 /ccache

# =============================================================================
# Step 2–4: Build entrypoint (per doc; non-interactive config.cmake)
# =============================================================================
# Doc Step 2: mkdir build, python ../cmake/gen_cmake_config.py, cmake .. && make
# We use config.cmake directly for non-interactive CI/Docker (gen_cmake_config.py is interactive).
COPY <<'EOF' /usr/local/bin/build-entrypoint.sh
#!/bin/bash
set -eo pipefail

: ${NUM_THREADS:=$(nproc)}
: ${MLC_BACKEND:=vulkan}
: ${RUN_TESTS:="0"}

echo "=============================================="
echo "  MLC-LLM Build (per doc Build from Source)"
echo "  https://llm.mlc.ai/docs/install/mlc_llm.html"
echo "=============================================="
echo "Backend: ${MLC_BACKEND}"
echo "Threads: ${NUM_THREADS}"
echo "=============================================="

cd /workspace

# --- Step 2. Configure and build (per doc) ---
echo ""
echo "=== Step 2: Configure and build ==="
mkdir -p build && cd build

# Non-interactive config (doc recommends gen_cmake_config.py for interactive use)
cat > config.cmake << CMAKECFG
set(TVM_SOURCE_DIR 3rdparty/tvm)
set(CMAKE_BUILD_TYPE RelWithDebInfo)
set(USE_CUDA OFF)
set(USE_CUTLASS OFF)
set(USE_CUBLAS OFF)
set(USE_ROCM OFF)
set(USE_METAL OFF)
set(USE_OPENCL OFF)
CMAKECFG

if [[ ${MLC_BACKEND} == "cuda" ]]; then
  echo "set(USE_CUDA ON)" >> config.cmake
  echo "set(USE_CUBLAS ON)" >> config.cmake
  echo "set(USE_CUTLASS ON)" >> config.cmake
else
  echo "set(USE_VULKAN ON)" >> config.cmake
fi

cat config.cmake
cmake .. -G Ninja
ninja -j ${NUM_THREADS}
cd ..

# --- Step 3. Install via Python (per doc) ---
echo ""
echo "=== Step 3: Install via Python ==="
cd python
pip install -e . --no-deps
cd ..

# --- Step 4. Validate installation (per doc) ---
echo ""
echo "=== Step 4: Validate installation ==="
echo "Expected: libmlc_llm.so and libtvm_runtime.so"
ls -l ./build/*.so 2>/dev/null || find ./build -name "*.so" -type f | head -10

echo ""
echo "Expected: help message"
mlc_llm chat -h

echo ""
echo "Expected: path to build from source"
python -c "import mlc_llm; print(mlc_llm)"

echo ""
echo "=== Build and validation completed successfully ==="

if [[ ${RUN_TESTS} == "1" ]]; then
  echo ""
  echo "=== Running tests ==="
  python -m pytest -v tests/python/ -m unittest \
    --ignore=tests/python/integration/ \
    --ignore=tests/python/op/
fi

if [[ -n ${BUILD_WHEEL} ]]; then
  echo ""
  echo "=== Building wheel ==="
  cd python && pip wheel --no-deps -w ../wheels . && cd ..
  ls -la wheels/
fi
EOF

RUN chmod +x /usr/local/bin/build-entrypoint.sh

COPY <<'EOF' /usr/local/bin/dev-init.sh
#!/bin/bash
cat << 'BANNER'
==============================================
  MLC-LLM Development Environment
  Build from Source: https://llm.mlc.ai/docs/install/mlc_llm.html
==============================================
BANNER
echo "Python: $(python --version) | CMake: $(cmake --version | head -1) | Rust: $(rustc --version)"
echo ""
echo "Build first (required for mlc_llm CLI):"
echo "  /usr/local/bin/build-entrypoint.sh"
echo ""
echo "Or manual (per doc):"
echo "  mkdir -p build && cd build"
echo "  python ../cmake/gen_cmake_config.py   # interactive"
echo "  cmake .. && make -j \$(nproc) && cd .."
echo "  cd python && pip install -e . --no-deps"
echo ""
echo "Then: mlc_llm chat -h | pytest tests/python/ -m unittest | black python/"
echo "=============================================="
EOF

RUN chmod +x /usr/local/bin/dev-init.sh
RUN echo 'source /usr/local/bin/dev-init.sh' >> /etc/bash.bashrc

LABEL org.opencontainers.image.source="https://github.com/mlc-ai/mlc-llm"
LABEL org.opencontainers.image.description="MLC-LLM Build from Source (Vulkan/CUDA)"
LABEL org.opencontainers.image.licenses="Apache-2.0"

ENTRYPOINT ["/usr/local/bin/build-entrypoint.sh"]
CMD []
