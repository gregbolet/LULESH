#!/bin/bash
#SBATCH --job-name=luleshPATest
#SBATCH --output=PASkip_Cntrs_variabilityStudyRunData.log
#SBATCH --ntasks=1
#SBATCH --time=2:00:00
#SBATCH --export=ALL

SUFFIX="lulesh"
BLIM=0
CLIM=0
MAX_POL=1
BINDINGS="close"
APOLLO_PERIOD=10000
THREAD_CAP=36

function run_static() {
for P in $(seq 0 $MAX_POL); do
    APOLLO_TRACE_CSV_FOLDER_SUFFIX="-$SUFFIX" OMP_NUM_THREADS=$THREAD_CAP OMP_WAIT_POLICY=active \
        APOLLO_RETRAIN_ENABLE=0 \
        APOLLO_INIT_MODEL=Static,$P \
        APOLLO_TRACE_CSV=1 OMP_PROC_BIND=close OMP_PLACES=cores  \
        $PROG 
	#|& tee log-static-$P.txt
    	#perf record --call-graph fp -- 
done
}
function run_rr() {
for BIND in $BINDINGS; do
    echo $BIND
    APOLLO_TRACE_CSV_FOLDER_SUFFIX="-$SUFFIX" OMP_NUM_THREADS=$THREAD_CAP OMP_WAIT_POLICY=active \
        APOLLO_RETRAIN_ENABLE=0 \
        APOLLO_INIT_MODEL=RoundRobin APOLLO_GLOBAL_TRAIN_PERIOD=$APOLLO_PERIOD \
        APOLLO_STORE_MODELS=0 \
        APOLLO_TRACE_CSV=1 OMP_PROC_BIND=$BIND OMP_PLACES=cores \
	$PROG
        #perf stat -e LLC-load-misses $PROG |& tee log-rr-$BIND.txt
done
}
function run_random() {
for BIND in $BINDINGS; do
    echo $BIND
    APOLLO_TRACE_CSV_FOLDER_SUFFIX="-$SUFFIX" OMP_NUM_THREADS=$THREAD_CAP OMP_WAIT_POLICY=active \
        APOLLO_RETRAIN_ENABLE=0 \
        APOLLO_INIT_MODEL=Random APOLLO_GLOBAL_TRAIN_PERIOD=$APOLLO_PERIOD \
        APOLLO_STORE_MODELS=0 \
        APOLLO_TRACE_CSV=1 OMP_PROC_BIND=$BIND OMP_PLACES=cores \
	$PROG
done
}

ANALY_DIR=~/workspace/apollo/src/python/analysis
DATA_DIR=~/workspace/lulesh/build/runData

mkdir -p "$DATA_DIR"

for i in $(seq 1 20); do
    PROG="srun -n 1 ../../lulesh2.0 -s 30 -r 100 -b 0 -c 0 -i 1000"

    RUN_DATA_DIR="$DATA_DIR/run_$i"
    mkdir -p "$RUN_DATA_DIR"

    pushd "$RUN_DATA_DIR"
    run_static
    run_random
    run_rr
    popd

    echo "[Variability Runs] Just finished run $i"
    # Do the trace analysis
    srun -n 1 $ANALY_DIR/./analyze-traces.py --dir "$RUN_DATA_DIR/trace-lulesh" --rr --random --nstatic 2 --nranks 1
done
