#!/bin/bash

export APOLLO_COLLECTIVE_TRAINING=0
export APOLLO_LOCAL_TRAINING=1
export APOLLO_RETRAIN_ENABLE=0
#export APOLLO_SINGLE_MODEL=1
export APOLLO_SINGLE_MODEL=0
export APOLLO_REGION_MODEL=1
#export APOLLO_STORE_MODELS=1
export APOLLO_STORE_MODELS=0
#export APOLLO_TRACE_MEASURES=1
export APOLLO_TRACE_MEASURES=0
export APOLLO_TRACE_CSV=1
#export APOLLO_TRACE_CSV_FOLDER_SUFFIX=
#export OMP_WAIT_POLICY=passive
export OMP_WAIT_POLICY=active
export OMP_PROC_BIND=close
#export OMP_PROC_BIND=false
#export OMP_PROC_BIND=true
export OMP_PLACES=cores
export OMP_NUM_THREADS=36
export APOLLO_PER_REGION_TRAIN_PERIOD=0

EXEC_DIR=~/workspace/lulesh/build
TRACE_DIR=$EXEC_DIR/trace
ANALY_DIR=~/workspace/apollo/src/python/analysis
echo $EXEC_DIR, $TRACE_DIR

PROB_SIZE="-s 30"
NUM_ITERS="-i 1000"
#NUM_TIERS=
NUM_REGIONS="-r 100 -b 0 -c 0"

cd $EXEC_DIR
rm -rf $TRACE_DIR
mkdir trace

POLICIES=(0 1)

#Try out the static policies as baseline
for policy in ${POLICIES[@]}; do
	export APOLLO_INIT_MODEL=Static,$policy
	$EXEC_DIR/./lulesh2.0 $PROB_SIZE $NUM_ITERS $NUM_REGIONS
done

# Try out different training intervals
TRAIN_INTERVALS=(10000)
#TRAIN_INTERVALS=(1 2 4 8 10 15 30 50 100 200 300 500 1000)
#TRAIN_INTERVALS=(1500 2000 3000 5000 10000 15000 20000 30000 50000 100000 150000)
for interval in ${TRAIN_INTERVALS[@]}; do
	export APOLLO_GLOBAL_TRAIN_PERIOD=$interval
	export APOLLO_INIT_MODEL=RoundRobin
	$EXEC_DIR/./lulesh2.0 $PROB_SIZE $NUM_ITERS $NUM_REGIONS

	export APOLLO_INIT_MODEL=Random
	$EXEC_DIR/./lulesh2.0 $PROB_SIZE $NUM_ITERS $NUM_REGIONS

	# Do the trace analysis
	$ANALY_DIR/./analyze-traces.py --dir $TRACE_DIR --rr --random --nstatic ${#POLICIES[@]} --nranks 1
	echo "Used APOLLO_GLOBAL_TRAIN_PERIOD: " $interval
done
