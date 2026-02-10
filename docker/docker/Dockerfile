# ============================================================
# Base Image
# ============================================================
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# ============================================================
# System Dependencies
# ============================================================
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    ca-certificates \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    ninja-build \
    llvm-14 \
    llvm-14-dev \
    clang-14 \
    libedit-dev \
    libxml2-dev \
    zlib1g-dev \
    libzstd-dev \
    && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/llvm-config-14 /usr/bin/llvm-config

# ============================================================
# Python Dependencies
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
# Environment
# ============================================================
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

ENV TVM_HOME=/mlc-llm/3rdparty/tvm
ENV PYTHONPATH=/mlc-llm/3rdparty/tvm/python
ENV LD_LIBRARY_PATH=/mlc-llm/3rdparty/tvm/build:${LD_LIBRARY_PATH}

# ============================================================
# Workspace
# ============================================================
WORKDIR /mlc-llm
COPY . /mlc-llm

# ============================================================
# Build TVM (CI-safe: CUDA OFF by default)
# ============================================================
ARG USE_CUDA=OFF

RUN cd 3rdparty/tvm && \
    mkdir -p build && \
    cd build && \
    cmake .. \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DUSE_CUDA=${USE_CUDA} \
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
# Install TVM Python (editable, matches built runtime)
# ============================================================
RUN cd 3rdparty/tvm/python && pip3 install -e .

# ============================================================
# Sanity Check (TVM only)
# ============================================================
RUN python3 - <<'EOF'
import tvm
print("TVM OK:", tvm.__version__)
EOF

CMD ["/bin/bash"]
