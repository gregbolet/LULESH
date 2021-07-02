#!/bin/bash

export OMP_WAIT_POLICY=passive
#export OMP_WAIT_POLICY=active
export OMP_PROC_BIND=true
#export OMP_PROC_BIND=false
export OMP_PLACES=core

EXEC_DIR=~/workspace/lulesh/build
echo $EXEC_DIR
cd $EXEC_DIR

PROB_SIZE="-s 30"
NUM_ITERS="-i 500"
NUM_REGIONS="-r 100"

export OMP_NUM_THREADS=36
$EXEC_DIR/./lulesh2.0 $PROB_SIZE $NUM_ITERS $NUM_REGIONS

export OMP_NUM_THREADS=1
$EXEC_DIR/./lulesh2.0 $PROB_SIZE $NUM_ITERS $NUM_REGIONS