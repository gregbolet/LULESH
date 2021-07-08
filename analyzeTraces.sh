#!/bin/bash

EXEC_DIR=~/workspace/lulesh/build
TRACE_DIR=$EXEC_DIR/trace
ANALY_DIR=~/workspace/apollo/src/python/analysis

POLICIES=(0 1)

# Do the trace analysis
$ANALY_DIR/./analyze-traces.py --dir $TRACE_DIR --rr --random --nstatic ${#POLICIES[@]} --nranks 1