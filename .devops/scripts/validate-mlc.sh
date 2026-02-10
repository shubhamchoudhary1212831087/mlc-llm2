#!/usr/bin/env bash
set -e

echo "🔍 Validating Build Artifacts..."

# Check for required shared libraries
if [ -f "/workspace/build/libmlc_llm.so" ] && [ -f "/workspace/build/libtvm_runtime.so" ]; then
    echo "✅ Shared libraries found."
else
    echo "❌ Missing build artifacts in /workspace/build"
    exit 1
fi

# Verify CLI
echo "🔍 Testing MLC-LLM CLI..."
mlc_llm chat -h > /dev/null

# Verify Python Import
echo "🔍 Testing Python Import..."
python3 -c "import mlc_llm; print('✅ MLC-LLM successfully imported. Version:', mlc_llm.__version__)"
