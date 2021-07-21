#!/bin/bash

BUILD_DIR=~/workspace/lulesh-region-fix-correct/LULESH/build

cd $BUILD_DIR

# Use clang@12.0.0
export CC=$(which clang)
export CXX=$(which clang++)

cmake -DWITH_MPI=Off -DWITH_OPENMP=On \
      -DCMAKE_BUILD_TYPE=Release \
      ../

#     -DCMAKE_BUILD_TYPE=Debug \