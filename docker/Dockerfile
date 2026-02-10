# Use NVIDIA CUDA base for GPU support
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# 1. SETUP BUILD TOOLS & ADD VULKAN SDK REPO (LunarG)
# This fixes the "missing package" errors from before
RUN apt-get update && \
    apt-get install -y wget gnupg ca-certificates software-properties-common && \
    wget -qO - https://packages.lunarg.com/lunarg-signing-key-pub.asc | apt-key add - && \
    wget -qO /etc/apt/sources.list.d/lunarg-vulkan-jammy.list https://packages.lunarg.com/vulkan/lunarg-vulkan-jammy.list && \
    apt-get update

# 2. INSTALL DEPENDENCIES
RUN apt-get install -y \
    build-essential \
    cmake \
    git \
    python3-dev \
    python3-pip \
    python3-setuptools \
    vulkan-sdk \
    curl \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# 3. INSTALL RUST
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# 4. PRE-INSTALL PYTHON DEPS
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

# 5. CRITICAL FIX: ENSURE CUDA IS IN PATH
ENV PATH=/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

# 6. SETUP ENTRYPOINT
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /mlc-llm
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
