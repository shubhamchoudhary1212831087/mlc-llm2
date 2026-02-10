# ============================================================
# Base Image (CI-safe, CPU only)
# ============================================================
FROM ubuntu:22.04

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
    llvm \
    llvm-dev \
    clang \
    libedit-dev \
    libxml2-dev \
    zlib1g-dev \
    libzstd-dev \
    && rm -rf /var/lib/apt/lists/*

# Verify llvm-config exists
RUN llvm-config --version

# ============================================================
# Python Dependencies
# ============================================================
RUN python3 -m pip install --upgrade pip && \
    pip install \
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
      -DTVM_BUILD_TESTS=OFF \
      -DTVM_BUILD_EXAMPLES=OFF \
      -DTVM_BUILD_TUTORIALS=OFF && \
    ninja

# ============================================================
# Runtime Environment
# ============================================================
ENV TVM_HOME=/mlc-llm/3rdparty/tvm
ENV PYTHONPATH=/mlc-llm/3rdparty/tvm/python
ENV LD_LIBRARY_PATH=/mlc-llm/3rdparty/tvm/build

# ============================================================
# Install TVM Python
# ============================================================
RUN cd 3rdparty/tvm/python && pip install -e .

# ============================================================
# Build & Install MLC-LLM
# ============================================================
RUN cd python && \
    python3 setup.py bdist_wheel && \
    pip install --no-deps dist/*.whl

# ============================================================
# HARD VALIDATION (CORRECT HEREDOC)
# ============================================================
RUN python3 <<EOF
import tvm
import mlc_llm
print("TVM OK:", tvm.__version__)
print("MLC OK:", mlc_llm.__file__)
EOF

# ============================================================
# Default
# ============================================================
CMD ["/bin/bash"]
