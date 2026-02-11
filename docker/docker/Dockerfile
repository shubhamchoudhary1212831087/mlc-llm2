# ============================================================
# Base Image & System Dependencies
# ============================================================
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential cmake ninja-build git python3 python3-dev python3-pip \
    llvm llvm-dev clang libedit-dev libxml2-dev zlib1g-dev libzstd-dev \
    ca-certificates curl && rm -rf /var/lib/apt/lists/*

RUN pip3 install --upgrade pip setuptools wheel && \
    pip3 install numpy decorator attrs psutil cloudpickle scipy tornado typing-extensions pybind11

# ============================================================
# Workspace & Source
# ============================================================
WORKDIR /mlc-llm
COPY . .

# ============================================================
# STEP 1: Build TVM (Dependency)
# ============================================================
RUN cd 3rdparty/tvm && \
    mkdir -p build && cd build && \
    cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DUSE_LLVM=ON -DUSE_CUDA=OFF && \
    ninja

# Set Environment Variables for TVM
ENV TVM_HOME=/mlc-llm/3rdparty/tvm
ENV PYTHONPATH=$TVM_HOME/python:${PYTHONPATH}

# ============================================================
# STEP 2: Build MLC-LLM Native Core (The "Missing Link")
# ============================================================
RUN mkdir -p build && cd build && \
    # Documentation step: Generate the config for CMake
    python3 ../cmake/gen_cmake_config.py && \
    cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release && \
    ninja

# Link the libraries so Python can find them during the wheel build
ENV LD_LIBRARY_PATH=/mlc-llm/build:/mlc-llm/3rdparty/tvm/build:${LD_LIBRARY_PATH}

# ============================================================
# STEP 3: Build & Install Python Package
# ============================================================
RUN cd python && \
    python3 setup.py bdist_wheel && \
    pip install dist/*.whl

# Hard Validation
RUN python3 -c "import tvm; import mlc_llm; print('TVM Version:', tvm.__version__); print('MLC Path:', mlc_llm.__file__)"

CMD ["/bin/bash"]
