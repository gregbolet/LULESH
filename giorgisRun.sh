#!/bin/bash

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
        APOLLO_TRACE_CSV=1 OMP_PROC_BIND=true OMP_PLACES=cores  \
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
        #perf stat -e LLC-load-misses $PROG |& tee log-rr-$BIND.txt
done
}

for B in $(seq 0 $BLIM); do
    for C in $(seq 0 $CLIM); do
        PROG="../lulesh2.0 -s 30 -r 100 -b $B -c $C -i 1000"
        mkdir -p "B$B-C$C"

        pushd "B$B-C$C"
        #run_static
	run_random
        run_rr
        popd
    done
done

ANALY_DIR=~/workspace/apollo/src/python/analysis
CSV_DIR=~/workspace/lulesh/build/B0-C0/trace-lulesh

# Do the trace analysis
$ANALY_DIR/./analyze-traces.py --dir $CSV_DIR --rr --random --nstatic 2 --nranks 1
