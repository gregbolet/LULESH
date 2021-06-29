#!/bin/bash

cd ./build

cmake -DCMAKE_BUILD_TYPE=Release -DWITH_MPI=Off -DWITH_OPENMP=On \
      -DWITH_APOLLO=On \
      -DAPOLLO_DIR=/g/g15/bolet1/workspace/apollo/ \
      -DWITH_CALIPER=On \
      -DCALIPER_DIR=/usr/WS2/bolet1/spack/opt/spack/linux-rhel7-broadwell/gcc-10.2.1/caliper-2.5.0-bqvkflizcmjjpbjtwnatgwjpikgajjgd/ \
      ../
