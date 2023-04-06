#!/bin/bash
#LLVM_INSTALL=/g/g15/bolet1/workspace/clang-apollo/llvm-project/build-release-quartz-no-argmemonly/install

# correct flags
#LLVM_INSTALL=/g/g15/bolet1/workspace/clang-apollo/llvm-project/build-release-quartz/install
#APOLLO_INSTALL=/g/g15/bolet1/workspace/apollo/build/install

#APOLLO_INSTALL=/g/g15/bolet1/workspace/apollo/buildVA/install
#APOLLO_INSTALL=/g/g15/bolet1/workspace/apollo/buildMemIntensityAware/install
#APOLLO_INSTALL=/p/vast1/ggeorgak/projects/apollo/apollo/build-quartz-nompi/install

# Below CXX FLAGS is for without PERFCNTR Support
#export CXXFLAGS="-fsave-optimization-record -fopenmp -Xclang -load -Xclang ${LLVM_INSTALL}/../lib/LLVMApollo.so -mllvm --apollo-omp-numthreads=36,16,8,4,2,1 -mllvm --apollo-enable-thread-instrumentation -march=native"

# correct flag
#export CXXFLAGS="-fsave-optimization-record -fopenmp -Xclang -load -Xclang ${LLVM_INSTALL}/../lib/LLVMApollo.so -mllvm --apollo-omp-numthreads=36,18,1 -mllvm --apollo-enable-thread-instrumentation -march=native"

#export CXXFLAGS="-fsave-optimization-record -fopenmp -Xclang -load -Xclang ${LLVM_INSTALL}/../lib/LLVMApollo.so -mllvm --apollo-omp-numthreads=36,1 -mllvm --apollo-enable-thread-instrumentation -march=native"
#export CXXFLAGS="-fsave-optimization-record -fopenmp -Xclang -load -Xclang ${LLVM_INSTALL}/../lib/LLVMApollo.so -mllvm --apollo-omp-numthreads=36,18,1 -march=native"
#export CXXFLAGS="-fsave-optimization-record -fopenmp -Xclang -load -Xclang ${LLVM_INSTALL}/../lib/LLVMApollo.so -mllvm --apollo-omp-numthreads=36,1 -march=native"
#export CXXFLAGS="-fsave-optimization-record -fopenmp -Xclang -load -Xclang ${LLVM_INSTALL}/../lib/LLVMApollo.so -mllvm --apollo-omp-numthreads=36,16,8,4,2,1 -march=native"
#export CXXFLAGS="-fsave-optimization-record -fopenmp"

#correct flag
#export LDFLAGS="-L ${APOLLO_INSTALL}/lib -Wl,--rpath,${APOLLO_INSTALL}/lib -lapollo -Wl,--rpath,${LLVM_INSTALL}/lib"

#export LDFLAGS="-Wl,--rpath,${LLVM_INSTALL}/lib"
#export LDFLAGS="-L ${APOLLO_INSTALL}/lib -Wl,--rpath,${APOLLO_INSTALL}/lib -lapollo -Wl,--rpath,${LLVM_INSTALL}/lib"
    #-DCMAKE_CXX_FLAGS=${CXXFLAGS} \
#cmake --verbose \

#export CXXFLAGS="$CXXFLAGS -Wl,--enable-new-dtags"

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=${LLVM_INSTALL}/bin/clang++ \
    -DCMAKE_C_COMPILER=${LLVM_INSTALL}/bin/clang \
    -DWITH_MPI=off \
    -DWITH_OPENMP=on \
    -DCMAKE_EXE_LINKER_FLAGS="-L ${LLVM_INSTALL}/lib -Wl,--rpath,${LLVM_INSTALL}/lib" \
    ..
    #-DCMAKE_EXE_LINKER_FLAGS="-L ${LLVM_INSTALL}/lib -Wl,-rpath,${LLVM_INSTALL}/lib" \
    #-DCMAKE_EXE_LINKER_FLAGS="-L ${LLVM_INSTALL}/lib -Wl,--rpath,${LLVM_INSTALL}/lib" \