#!/bin/bash
# NOTE: We will NOT use TRACE_CSV as these I/O ops add time to the execution
# NOTE: We only STORE_MODELS for training the model, then don't STORE_MODELS for testing
# NOTE: Pretty much all test runs have no file writing to save execution time

# ENV VARS we expect to be set before executing this script
# USE_REGION_MODEL
# USE_SINGLE_MODEL
# DATA_DIR_NAME
# EXE_DIR
# ENABLE_PERF_CNTRS
# ENABLE_MLTPX
# PERF_CNTRS
# DTREE_DEPTH

SUFFIX="lulesh-data"
MAX_POL=1
PROC_BIND="close"
PLACES=cores
WAIT_POL="active"
APOLLO_PERIOD=2100728
THREAD_CAP=36
POLICY="RoundRobin"
STORE_MODELS=1

# Setup the data directory where we will store YAML files
DATA_DIR="./runData/$DATA_DIR_NAME"

# Go into the data directory
mkdir -p "$DATA_DIR"
pushd "$DATA_DIR"

# Create a single model from training with ALL iterations
OMP_NUM_THREADS=$THREAD_CAP \
OMP_WAIT_POLICY=$WAIT_POL \
OMP_PROC_BIND=$PROC_BIND \
OMP_PLACES=$PLACES \
APOLLO_DTREE_DEPTH=$DTREE_DEPTH \
APOLLO_TRACE_CSV_FOLDER_SUFFIX="-$SUFFIX" \
APOLLO_COLLECTIVE_TRAINING=0 \
APOLLO_LOCAL_TRAINING=1 \
APOLLO_RETRAIN_ENABLE=0 \
APOLLO_INIT_MODEL=$POLICY \
APOLLO_STORE_MODELS=$STORE_MODELS \
APOLLO_TRACE_CSV=$TRACE_CSV \
APOLLO_SINGLE_MODEL=$USE_SINGLE_MODEL \
APOLLO_REGION_MODEL=$USE_REGION_MODEL \
APOLLO_GLOBAL_TRAIN_PERIOD=$APOLLO_PERIOD \
APOLLO_ENABLE_PERF_CNTRS=$ENABLE_PERF_CNTRS \
APOLLO_PERF_CNTRS_MLTPX=$ENABLE_MLTPX \
APOLLO_PERF_CNTRS=$PERF_CNTRS \
srun -n1 -N1 --export=ALL \
./$EXE_DIR/lulesh2.0 -s 30 -r 100 -b 0 -c 0 -i 1000

popd

function doRunWithYAML {

	# Run with the specified YAML file
	OMP_NUM_THREADS=$THREAD_CAP \
	OMP_WAIT_POLICY=$WAIT_POL \
	OMP_PROC_BIND=$PROC_BIND \
	OMP_PLACES=$PLACES \
	APOLLO_TRACE_CSV_FOLDER_SUFFIX="-$SUFFIX" \
	APOLLO_COLLECTIVE_TRAINING=0 \
	APOLLO_LOCAL_TRAINING=1 \
	APOLLO_RETRAIN_ENABLE=0 \
	APOLLO_INIT_MODEL=$POLICY \
	APOLLO_STORE_MODELS=$STORE_MODELS \
	APOLLO_TRACE_CSV=$TRACE_CSV \
	APOLLO_SINGLE_MODEL=$USE_SINGLE_MODEL \
	APOLLO_REGION_MODEL=$USE_REGION_MODEL \
	APOLLO_GLOBAL_TRAIN_PERIOD=$APOLLO_PERIOD \
	APOLLO_ENABLE_PERF_CNTRS=$ENABLE_PERF_CNTRS \
	APOLLO_PERF_CNTRS_MLTPX=$ENABLE_MLTPX \
	APOLLO_PERF_CNTRS=$PERF_CNTRS \
	srun -n1 -N1 --export=ALL \
	$PROG
}

# Don't store or trace anything
STORE_MODELS=0

# This will open up each region's respective model for testing
# If we did region training, all the models will be different
# If we did single trianing, all the models will be the same
POLICY="Load"

# Let's run 1 trial of 10 different inputs using this model
# We sweep through the size '-s' parameter on lulesh
for ((i=30;i<=80;i+=5)); do
    PROBLEM_SIZE=$i
    PROG="./$EXE_DIR/lulesh2.0 -s $PROBLEM_SIZE -r 100 -b 0 -c 0 -i 1000"
    pushd "$DATA_DIR"
    for ((j=1;j<=$NUM_TRIALS;j+=1)); do
    	doRunWithYAML
    done
    popd
done

