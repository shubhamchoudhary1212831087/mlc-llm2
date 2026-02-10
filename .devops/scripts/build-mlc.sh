#!/usr/bin/env bash
set -e

echo "🚀 Starting MLC-LLM Build..."

# 1. Prepare Build Directory
mkdir -p /workspace/build && cd /workspace/build

# 2. Generate Configuration (MANUAL OVERRIDE)
# This bypasses the interactive python script entirely.
echo "📝 Writing config.cmake manually..."
cat > config.cmake <<EOF
set(TVM_SOURCE_DIR /workspace/3rdparty/tvm)
set(CMAKE_BUILD_TYPE RelWithDebInfo)
set(USE_CUDA OFF)
set(USE_ROCM OFF)
set(USE_VULKAN OFF)
set(USE_METAL OFF)
set(USE_OPENCL OFF)
EOF

# 3. Build C++ Runtime
echo "🔨 Compiling with CMake..."
cmake .. -G "Unix Makefiles"

# 🟢 FIX: Limit to 2 cores to prevent Out-Of-Memory crashes
make -j2 

# 4. Install Python Bindings
echo "📦 Installing Python Packages..."
cd /workspace/python
pip install --no-cache-dir .

echo "✅ Build Complete."
