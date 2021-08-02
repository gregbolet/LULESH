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

cmake -DWITH_MPI=Off -DWITH_OPENMP=On \
      -DCMAKE_BUILD_TYPE=Release \
      -DWITH_APOLLO=On \
      -DAPOLLO_DIR=/g/g15/bolet1/workspace/apollo/ \
      -DWITH_CALIPER=Off \
      -DCALIPER_DIR=/usr/WS2/bolet1/spack/opt/spack/linux-rhel7-broadwell/gcc-10.2.1/caliper-2.5.0-bqvkflizcmjjpbjtwnatgwjpikgajjgd/ \
      ../

#     -DCMAKE_BUILD_TYPE=Debug \