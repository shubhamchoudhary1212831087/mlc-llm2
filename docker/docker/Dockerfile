# ============================================================
# Base Image
# ============================================================
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# System Dependencies
RUN apt-get update && apt-get install -y \
    build-essential cmake ninja-build git curl ca-certificates \
    python3 python3-dev python3-pip llvm llvm-dev clang \
    libedit-dev libxml2-dev zlib1g-dev libzstd-dev \
    && rm -rf /var/lib/apt/lists/*

# Python Dependencies
RUN pip3 install --upgrade pip setuptools wheel && \
    pip3 install numpy decorator attrs psutil cloudpickle scipy tornado typing-extensions pybind11

WORKDIR /mlc-llm
COPY . /mlc-llm

# ============================================================
# Step 1: Build TVM (as per mlc-ai/tvm requirements)
# ============================================================
RUN cd 3rdparty/tvm && \
    mkdir -p build && cd build && \
    cmake .. -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DUSE_LLVM=ON \
      -DUSE_CUDA=OFF && \
    ninja

# Set Envs for TVM
ENV TVM_HOME=/mlc-llm/3rdparty/tvm
ENV PYTHONPATH=$TVM_HOME/python:${PYTHONPATH}

# ============================================================
# Step 2: Build MLC-LLM Native Libraries (CRITICAL MISSING STEP)
# ============================================================
RUN mkdir -p build && cd build && \
    # Official docs: generate config first
    python3 ../cmake/gen_cmake_config.py && \
    cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release && \
    ninja

# Link the built library
ENV LD_LIBRARY_PATH=/mlc-llm/build:/mlc-llm/3rdparty/tvm/build:${LD_LIBRARY_PATH}

# ============================================================
# Step 3: Install MLC-LLM Python Package
# ============================================================
RUN cd python && \
    python3 setup.py bdist_wheel && \
    pip install dist/*.whl

# Hard Validation
RUN python3 -c "import tvm; import mlc_llm; print('TVM Version:', tvm.__version__); print('MLC File:', mlc_llm.__file__)"

CMD ["/bin/bash"]
