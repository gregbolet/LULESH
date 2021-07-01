#!/bin/bash

export APOLLO_COLLECTIVE_TRAINING=0
export APOLLO_LOCAL_TRAINING=1
#export APOLLO_SINGLE_MODEL=1
export APOLLO_SINGLE_MODEL=0
export APOLLO_REGION_MODEL=1
#export APOLLO_STORE_MODELS=1
export APOLLO_STORE_MODELS=0
#export APOLLO_TRACE_MEASURES=1
export APOLLO_TRACE_MEASURES=0
export APOLLO_TRACE_CSV=1
#export APOLLO_TRACE_CSV_FOLDER_SUFFIX=
export OMP_WAIT_POLICY=passive
#export OMP_WAIT_POLICY=active
export OMP_PROC_BIND=true
#export OMP_PROC_BIND=false

EXEC_DIR=~/workspace/lulesh/build
TRACE_DIR=$EXEC_DIR/trace
ANALY_DIR=~/workspace/apollo/src/python/analysis
echo $EXEC_DIR, $TRACE_DIR

PROB_SIZE="-s 30"
#NUM_ITERS="-i 100"
NUM_TIERS=
NUM_REGIONS="-r 100"

cd $EXEC_DIR
rm -rf $TRACE_DIR

POLICIES=(0 1 2 3 4 5 6)

for policy in ${POLICIES[@]}; do
	export APOLLO_INIT_MODEL=Static,$policy
	$EXEC_DIR/./lulesh2.0 $PROB_SIZE $NUM_ITERS $NUM_REGIONS
done

export APOLLO_INIT_MODEL=RoundRobin
$EXEC_DIR/./lulesh2.0 $PROB_SIZE $NUM_ITERS $NUM_REGIONS

export APOLLO_INIT_MODEL=Random
$EXEC_DIR/./lulesh2.0 $PROB_SIZE $NUM_ITERS $NUM_REGIONS

# Do the trace analysis
$ANALY_DIR/./analyze-traces.py --dir $TRACE_DIR --rr --random -nstatic 7 -nranks 1