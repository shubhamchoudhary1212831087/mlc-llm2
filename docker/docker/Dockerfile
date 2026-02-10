# ============================================================
# Base Image (CUDA runtime-capable, CI-safe)
# ============================================================
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# ============================================================
# System Dependencies
# ============================================================
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    git \
    curl \
    ca-certificates \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    llvm-14 \
    llvm-14-dev \
    clang-14 \
    libedit-dev \
    libxml2-dev \
    zlib1g-dev \
    libzstd-dev \
    && rm -rf /var/lib/apt/lists/*

# TVM expects llvm-config
RUN ln -s /usr/bin/llvm-config-14 /usr/bin/llvm-config

# ============================================================
# Python Dependencies (runtime only)
# ============================================================
RUN pip3 install --upgrade pip && \
    pip3 install \
        numpy \
        decorator \
        attrs \
        psutil \
        cloudpickle \
        scipy \
        tornado \
        typing-extensions \
        pybind11

# ============================================================
# Workspace
# ============================================================
WORKDIR /mlc-llm
COPY . /mlc-llm

# ============================================================
# Build TVM (CPU-only, CI-safe)
# ============================================================
RUN cd 3rdparty/tvm && \
    mkdir -p build && \
    cd build && \
    cmake .. \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DUSE_CUDA=OFF \
      -DUSE_CUDNN=OFF \
      -DUSE_CUTLASS=OFF \
      -DUSE_FLASH_ATTENTION=OFF \
      -DUSE_LLVM=ON \
      -DLLVM_DIR=/usr/lib/llvm-14/lib/cmake/llvm \
      -DTVM_BUILD_TESTS=OFF \
      -DTVM_BUILD_EXAMPLES=OFF \
      -DTVM_BUILD_TUTORIALS=OFF && \
    ninja

# ============================================================
# 🔑 REGISTER TVM RUNTIME (CRITICAL FIX)
# ============================================================
RUN echo "/mlc-llm/3rdparty/tvm/build" > /etc/ld.so.conf.d/tvm.conf && ldconfig

# ============================================================
# Install TVM Python
# ============================================================
RUN cd 3rdparty/tvm/python && pip3 install -e .

# ============================================================
# Build & Install MLC-LLM Python
# ============================================================
RUN cd python && \
    python3 setup.py bdist_wheel && \
    pip3 install --no-deps dist/*.whl

# ============================================================
# Validation (FAIL FAST)
# ============================================================
RUN python3 - <<'EOF'
import tvm
import mlc_llm
print("TVM OK:", tvm.__version__)
print("MLC LLM OK")
EOF

# ============================================================
# Default
# ============================================================
CMD ["/bin/bash"]
