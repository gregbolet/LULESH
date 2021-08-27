#!/bin/bash
#SBATCH --job-name=luleshApolloTest
#SBATCH --output=../runlogs/VA_C_API_unrolledLoops_VariabilityStudyRunData.log
#SBATCH --open-mode=truncate
#SBATCH --ntasks=1
#SBATCH --time=2:00:00
#SBATCH --export=ALL

DATA_DIR_NAME="VA_C_API_unrolledLoops"
SUFFIX="lulesh"
BLIM=0
CLIM=0
MAX_POL=1
BINDINGS="close"
APOLLO_PERIOD=10000
THREAD_CAP=36
ENABLE_PERF_CNTRS=0
PERF_CNTRS="PAPI_DP_OPS,PAPI_SP_OPS"
MLTPX_ENABLED=1

function run_static() {
for P in $(seq 0 $MAX_POL); do
    APOLLO_TRACE_CSV_FOLDER_SUFFIX="-$SUFFIX" \
    APOLLO_COLLECTIVE_TRAINING=0 \
    APOLLO_LOCAL_TRAINING=1 \
    OMP_NUM_THREADS=$THREAD_CAP \
    OMP_WAIT_POLICY=active \
    APOLLO_RETRAIN_ENABLE=0 \
    APOLLO_INIT_MODEL=Static,$P \
    APOLLO_TRACE_CSV=1  \
    OMP_PROC_BIND=close \
    OMP_PLACES=cores \
    APOLLO_ENABLE_PERF_CNTRS=$ENABLE_PERF_CNTRS \
    APOLLO_PERF_CNTRS=$PERF_CNTRS \
    APOLLO_PERF_CNTRS_MLTPX=$MLTPX_ENABLED \
    srun -n1 -N1 --export=ALL \
    $PROG 
done
}
function run_rr() {
for BIND in $BINDINGS; do
    echo $BIND
    APOLLO_TRACE_CSV_FOLDER_SUFFIX="-$SUFFIX" \
    APOLLO_COLLECTIVE_TRAINING=0 \
    APOLLO_LOCAL_TRAINING=1 \
    OMP_NUM_THREADS=$THREAD_CAP \
    OMP_WAIT_POLICY=active \
    APOLLO_RETRAIN_ENABLE=0 \
    APOLLO_INIT_MODEL=RoundRobin  \
    APOLLO_GLOBAL_TRAIN_PERIOD=$APOLLO_PERIOD \
    APOLLO_STORE_MODELS=0 \
    APOLLO_TRACE_CSV=1 \
    OMP_PROC_BIND=$BIND \
    OMP_PLACES=cores \
    APOLLO_ENABLE_PERF_CNTRS=$ENABLE_PERF_CNTRS \
    APOLLO_PERF_CNTRS=$PERF_CNTRS \
    APOLLO_PERF_CNTRS_MLTPX=$MLTPX_ENABLED \
    srun -n1 -N1 --export=ALL \
    $PROG
done
}
function run_random() {
for BIND in $BINDINGS; do
    echo $BIND
    APOLLO_TRACE_CSV_FOLDER_SUFFIX="-$SUFFIX" \
    APOLLO_COLLECTIVE_TRAINING=0 \
    APOLLO_LOCAL_TRAINING=1 \
    OMP_NUM_THREADS=$THREAD_CAP \
    OMP_WAIT_POLICY=active \
    APOLLO_RETRAIN_ENABLE=0 \
    APOLLO_INIT_MODEL=Random \
    APOLLO_GLOBAL_TRAIN_PERIOD=$APOLLO_PERIOD \
    APOLLO_STORE_MODELS=0 \
    APOLLO_TRACE_CSV=1 \
    OMP_PROC_BIND=$BIND \
    OMP_PLACES=cores \
    APOLLO_ENABLE_PERF_CNTRS=$ENABLE_PERF_CNTRS \
    APOLLO_PERF_CNTRS=$PERF_CNTRS \
    APOLLO_PERF_CNTRS_MLTPX=$MLTPX_ENABLED \
    srun -n1 -N1 --export=ALL \
    $PROG
done
}

ANALY_DIR=~/workspace/apollo/src/python/analysis
ROOT_DATA_DIR=~/workspace/lulesh/runData

DATA_DIR=$ROOT_DATA_DIR/$DATA_DIR_NAME

mkdir -p "$DATA_DIR"

for i in $(seq 1 20); do
    echo $(pwd)
    PROG="../../../build/lulesh2.0 -s 30 -r 100 -b 0 -c 0 -i 1000"

    RUN_DATA_DIR="$DATA_DIR/run_$i"
    mkdir -p "$RUN_DATA_DIR"

    pushd "$RUN_DATA_DIR"
    run_static
    run_random
    run_rr
    popd

    echo "[$DATA_DIR_NAME] Just finished run $i"
    # Do the trace analysis
    srun -n 1 $ANALY_DIR/./analyze-traces.py --dir "$RUN_DATA_DIR/trace-lulesh" --rr --random --nstatic 2 --nranks 1
done
