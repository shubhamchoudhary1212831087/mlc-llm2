FROM nvidia/cuda:12.1.1-devel-ubuntu22.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# 1. SETUP REPOSITORIES (Critical Fix)
# We install software-properties-common first, then enable 'universe', then update.
# This ensures 'libspirv-tools-dev' can be found in the next step.
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository universe && \
    apt-get update

# 2. INSTALL DEPENDENCIES
# Added 'libspirv-tools-dev' which fixes the "_spirv-NOTFOUND" CMake error.
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

# 5. SETUP ENTRYPOINT
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /mlc-llm
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
