#!/bin/bash

cd ./build

cmake -DCMAKE_BUILD_TYPE=Release -DWITH_MPI=Off -DWITH_APOLLO=On -DWITH_OPENMP=On \
      -DAPOLLO_DIR=/g/g15/bolet1/workspace/apollo/ ../

