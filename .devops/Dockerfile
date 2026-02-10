FROM ubuntu:22.04

# 1. Environment Setup
ENV DEBIAN_FRONTEND=noninteractive \
    CONDA_DIR=/opt/conda \
    PATH=/opt/conda/envs/mlc-chat-venv/bin:/opt/conda/bin:/usr/local/bin:$PATH

# 2. System Dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git wget curl ca-certificates cmake \
    libssl-dev libtinfo-dev zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

# 3. Conda & Python 3.13 (Per Requirements)
RUN wget -q https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O /tmp/miniforge.sh && \
    bash /tmp/miniforge.sh -b -p $CONDA_DIR && \
    rm /tmp/miniforge.sh

RUN conda create -y -n mlc-chat-venv -c conda-forge \
    python=3.13 cmake rust git pip && \
    conda clean -afy

WORKDIR /workspace

# 4. Inject Automation Scripts
# This assumes you run 'docker build' from the repo root
COPY .devops/scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh && \
    ln -s /usr/local/bin/build-mlc.sh /usr/local/bin/build-mlc && \
    ln -s /usr/local/bin/validate-mlc.sh /usr/local/bin/validate-mlc

# Default to interactive shell
CMD ["bash"]
