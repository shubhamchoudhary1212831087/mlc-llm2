# ============================================================
# Base Image (CUDA toolkit present, driver not required)
# ============================================================
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# ============================================================
# Install Base + Vulkan Repo
# ============================================================
RUN apt-get update && \
    apt-get install -y \
        wget \
        gnupg \
        ca-certificates \
        software-properties-common && \
    wget -qO - https://packages.lunarg.com/lunarg-signing-key-pub.asc | apt-key add - && \
    wget -qO /etc/apt/sources.list.d/lunarg-vulkan-jammy.list \
        https://packages.lunarg.com/vulkan/lunarg-vulkan-jammy.list && \
    apt-get update

# ============================================================
# Build Dependencies (LLVM INCLUDED)
# ============================================================
RUN apt-get install -y \
        build-essential \
        cmake \
        git \
        python3-dev \
        python3-pip \
        python3-setuptools \
        vulkan-sdk \
        llvm-dev \
        libllvm-dev \
        clang \
        curl \
        ninja-build && \
    rm -rf /var/lib/apt/lists/*

# ============================================================
# Install Rust
# ============================================================
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y

# ============================================================
# Python Dependencies
# ============================================================
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

# ============================================================
# CUDA Path Safety
# ============================================================
ENV PATH=/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/lib64/stubs:${LD_LIBRARY_PATH}

# ============================================================
# Entrypoint
# ============================================================
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /mlc-llm

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
