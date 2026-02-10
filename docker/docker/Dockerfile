# We need the devel image to get 'nvcc' for compilation
# even if the runner has no GPU.
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies (Matches your Golden Reference)
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    ninja-build \
    build-essential \
    llvm \
    clang \
    curl \
    ca-certificates \
    python3 \
    python3-pip \
    python3-dev \
    libtinfo-dev \
    zlib1g-dev \
    libxml2-dev \
    libedit-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python deps
RUN python3 -m pip install --upgrade pip setuptools wheel && \
    pip3 install --no-cache-dir \
    numpy \
    scipy \
    psutil \
    decorator \
    attrs \
    cloudpickle \
    typing-extensions

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /mlc-llm
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
