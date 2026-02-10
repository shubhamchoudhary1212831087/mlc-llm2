Run # Safety Check: Ensure Rust is actually working
  # Safety Check: Ensure Rust is actually working
  if ! command -v cargo &> /dev/null; then
     echo "❌ CRITICAL ERROR: Cargo not found. Docker build failed to install Rust."
     exit 1
  fi
  echo "✅ Cargo version: $(cargo --version)"
  
  mkdir -p build && cd build
  
  # Exact flags from your Golden Reference
  cmake .. \
    -DUSE_CUDA=ON \
    -DUSE_CUBLAS=ON \
    -DUSE_CUTLASS=ON \
    -DUSE_THRUST=OFF \
    -DCMAKE_CUDA_ARCHITECTURES="80;86"
    
  make -j$(nproc)
  
  echo "✅ MLC Build Complete."
  shell: sh -e {0}
  env:
    REGISTRY: ghcr.io
❌ CRITICAL ERROR: Cargo not found. Docker build failed to install Rust.
/usr/local/cargo/bin/cargo
Error: Process completed with exit code 1.
