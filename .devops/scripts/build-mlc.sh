#!/usr/bin/env bash
set -e

echo "🚀 Starting MLC-LLM Build..."

# Create build directory
mkdir -p /workspace/build && cd /workspace/build

# Generate config (passing 'n' to defaults)
python3 ../cmake/gen_cmake_config.py <<EOF
n
n
n
n
n
n
EOF

# Build runtime libraries
cmake .. -G "Unix Makefiles"
make -j$(nproc)

# Step 3: Install via Python
echo "📦 Installing Python Package..."
cd /workspace/python
pip install --no-cache-dir .

echo "✅ Build Complete."
