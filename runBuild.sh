#!/bin/bash

BUILD_DIR=~/workspace/lulesh/build

cd $BUILD_DIR


# Use clang@12.0.0
module load clang/12.0.0
export CC=$(which clang)
export CXX=$(which clang++)

#module load gcc/10.2.1 
#export CC=$(which gcc)
#export CXX=$(which g++)

LLVM_INSTALL=/g/g15/bolet1/workspace/clang-apollo/llvm-project/build-release-quartz/install

export CXXFLAGS="-fopenmp" 
export LDFLAGS="-Wl,--rpath,${LLVM_INSTALL}/lib"

cmake -DWITH_MPI=Off -DWITH_OPENMP=On \
      -DCMAKE_BUILD_TYPE=Release \
      -DWITH_APOLLO=On \
      -DCMAKE_CXX_COMPILER=${LLVM_INSTALL}/bin/clang++ \
      -DCMAKE_C_COMPILER=${LLVM_INSTALL}/bin/clang \
      -DAPOLLO_DIR=/g/g15/bolet1/workspace/apollo/ \
      -DWITH_CALIPER=Off \
      -DCALIPER_DIR=/usr/WS2/bolet1/spack/opt/spack/linux-rhel7-broadwell/gcc-10.2.1/caliper-2.5.0-bqvkflizcmjjpbjtwnatgwjpikgajjgd/ \
      ../

#     -DCMAKE_BUILD_TYPE=Debug \