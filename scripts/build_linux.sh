#!/bin/bash

# Create build directory
mkdir -p build/linux

# Configure and build
cd build/linux
cmake ../../linux
make -j$(nproc)

# Copy library to the correct location
mkdir -p ../../build
cp libgpmf.so ../../build/ 