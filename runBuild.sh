#!/bin/bash

BUILD_DIR=~/workspace/lulesh/build

rm -rf $BUILD_DR
mkdir $BUILD_DIR
cd $BUILD_DIR

# Use clang@12.0.0
export CC=$(which clang)
export CXX=$(which clang++)
export MPI_C=$(which mpicc)
export MPI_CXX=$(which mpicxx)

cmake -DWITH_MPI=On -DWITH_OPENMP=On \
      -DCMAKE_BUILD_TYPE=Release \
      -DWITH_APOLLO=On \
      -DAPOLLO_DIR=/g/g15/bolet1/workspace/apollo/ \
      -DWITH_CALIPER=Off \
      -DCALIPER_DIR=/usr/WS2/bolet1/spack/opt/spack/linux-rhel7-broadwell/gcc-10.2.1/caliper-2.5.0-bqvkflizcmjjpbjtwnatgwjpikgajjgd/ \
      ../

#     -DCMAKE_BUILD_TYPE=Debug \