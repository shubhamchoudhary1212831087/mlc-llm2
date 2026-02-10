# File: .devops/Dockerfile
FROM ubuntu:22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive \
    CONDA_DIR=/opt/conda \
    PATH=/opt/conda/envs/mlc-chat-venv/bin:/opt/conda/bin:/usr/local/bin:$PATH

# Install system essentials
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git wget curl ca-certificates cmake \
    libssl-dev libtinfo-dev zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

# Install Miniforge (Conda)
RUN wget -q https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O /tmp/miniforge.sh && \
    bash /tmp/miniforge.sh -b -p $CONDA_DIR && \
    rm /tmp/miniforge.sh

# Create environment first (Caching Layer)
RUN conda create -y -n mlc-chat-venv -c conda-forge \
    python=3.13 cmake rust git pip && \
    conda clean -afy

WORKDIR /workspace

# Copy automation scripts
COPY .devops/scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*

# Default to interactive shell for Dev
CMD ["bash"]
