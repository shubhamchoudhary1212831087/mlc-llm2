#!/usr/bin/env bash
set -e
# Strict Step 4 implementation
echo "Verifying build artifacts..."
[ -f "/workspace/build/libmlc_llm.so" ] || { echo "MLC Lib missing"; exit 1; }
[ -f "/workspace/build/libtvm_runtime.so" ] || { echo "TVM Runtime missing"; exit 1; }

echo "Verifying Python entrypoints..."
mlc_llm chat -h
python -c "import mlc_llm; print('SUCCESS: ' + str(mlc_llm))"
