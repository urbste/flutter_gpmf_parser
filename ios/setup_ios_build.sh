#!/bin/bash

# Download iOS CMake toolchain
curl -L https://raw.githubusercontent.com/leetal/ios-cmake/master/ios.toolchain.cmake -o ios.toolchain.cmake

# Create build directory
mkdir -p ../build/ios

# Initial CMake configuration
cmake -B ../build/ios \
      -S . \
      -G Xcode \
      -DCMAKE_TOOLCHAIN_FILE=ios.toolchain.cmake \
      -DPLATFORM=OS64 \
      -DENABLE_BITCODE=0 \
      -DENABLE_ARC=1 \
      -DENABLE_VISIBILITY=1 \
      -DDEPLOYMENT_TARGET=11.0

echo "iOS build environment setup complete" 