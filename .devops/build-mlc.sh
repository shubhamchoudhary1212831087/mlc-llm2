#!/usr/bin/env bash
set -e

echo "🚀 Starting MLC-LLM Build..."

# Create build directory
mkdir -p /workspace/build && cd /workspace/build

# Standardize config generation:
# 1st input: Leave empty for default TVM path (3rdparty/tvm)
# 2nd-7th: 'n' for CUDA, ROCm, Vulkan, Metal, OpenCL, etc.
python3 ../cmake/gen_cmake_config.py <<EOF

n
n
n
n
n
n
EOF

# Verify the config was generated correctly before building
echo "--- Generated config.cmake ---"
cat config.cmake

# Build runtime libraries
cmake .. -G "Unix Makefiles"
make -j$(nproc)

# Step 3: Install via Python
echo "📦 Installing Python Package..."
cd /workspace/python
pip install --no-cache-dir .

echo "✅ Build Complete."
