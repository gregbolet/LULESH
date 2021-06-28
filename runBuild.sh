#!/bin/bash

cd ./build

cmake -DCMAKE_BUILD_TYPE=Release -DWITH_MPI=Off WITH_OPENMP=On ../

