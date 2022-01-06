#!/bin/bash
# NOTE: We only STORE_MODELS for training the model, then don't STORE_MODELS for testing

# ENV VARS we expect to be set before executing this script
## USE_REGION_MODEL
## USE_SINGLE_MODEL
## DATA_DIR_NAME
## EXE_DIR
## ENABLE_PERF_CNTRS
## ENABLE_MLTPX
## PERF_CNTRS
## DTREE_DEPTH
## APOLLO_PERIOD
## IMBAL 
## EXPLORE_POLICY
## TRAIN_SIZE
## TRACE_CSV
## NUM_TRIALS

SUFFIX="lulesh-${DATA_DIR_NAME}"
PROC_BIND="close"
PLACES=cores
WAIT_POL="active"
THREAD_CAP=36
POLICY=$EXPLORE_POLICY
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
srun -n1 -N1 \
--export=ALL \
./$EXE_DIR/lulesh2.0 -s ${TRAIN_SIZE} -r 100 -b 0 -c ${IMBAL} -i 1000

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
	srun \
	-n1 -N1 \
	--export=ALL \
	$PROG
}

#	--partition=pdebug \

# Don't store yaml
# Comment this out when doing full TRACE_CSV runs
#STORE_MODELS=0

# This will open up each region's respective model for testing
# If we did region training, all the models will be different
# If we did single trianing, all the models will be the same
POLICY="Load"

# Let's run 1 trial of 10 different inputs using this model
# We sweep through the size '-s' parameter on lulesh
for ((i=30;i<=80;i+=10)); do
    PROBLEM_SIZE=$i
    PROG="./../$EXE_DIR/lulesh2.0 -s ${PROBLEM_SIZE} -r 100 -b 0 -c ${IMBAL} -i 1000"
    for ((j=1;j<=$NUM_TRIALS;j+=1)); do
    	RUN_DATA_DIR="$DATA_DIR/run_size${i}_$j"
    	mkdir -p "$RUN_DATA_DIR"
    	cp ${DATA_DIR}/*.yaml ${RUN_DATA_DIR}/
    	pushd "$RUN_DATA_DIR"
    		doRunWithYAML
    	popd
    done
done

