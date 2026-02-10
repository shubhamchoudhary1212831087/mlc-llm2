#!/usr/bin/env bash
set -e
# Strict Step 2 implementation
mkdir -p build && cd build
printf "n\nn\nn\nn\nn\nn\n" | python ../cmake/gen_cmake_config.py
cmake .. && make -j $(nproc)
cd ../python && pip install .
