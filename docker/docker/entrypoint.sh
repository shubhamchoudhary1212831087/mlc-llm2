#!/bin/bash
set -e

# activate nvcc/cuda path just in case
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Check if arguments were passed
if [ "$#" -gt 0 ]; then
    # Build Mode: Execute the command passed by CI
    exec "$@"
else
    # Dev Mode: Drop into interactive shell
    echo "=================================================================="
    echo "  Welcome to the MLC-LLM Dev Environment"
    echo "  - Source mounted at: /mlc-llm"
    echo "  - Tools available: cmake, rustc, cargo, nvcc, python3"
    echo "=================================================================="
    exec /bin/bash
fi
