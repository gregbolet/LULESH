#!/bin/bash
#SBATCH --job-name=luleshMPITest
#SBATCH --output=luleshMPIRun.log
#SBATCH --ntasks=8
#SBATCH --time=1:00:00

export OMP_PLACES=cores
export OMP_NUM_THREADS=36
export OMP_WAIT_POLICY=active
export OMP_PROC_BIND=close

export APOLLO_COLLECTIVE_TRAINING=1
export APOLLO_LOCAL_TRAINING=0
export APOLLO_RETRAIN_ENABLE=0
export APOLLO_SINGLE_MODEL=0
export APOLLO_REGION_MODEL=1
export APOLLO_STORE_MODELS=0
export APOLLO_TRACE_MEASURES=0
export APOLLO_TRACE_CSV=1
export APOLLO_GLOBAL_TRAIN_PERIOD=10000
export APOLLO_INIT_MODEL=Static,0

# May want to try mpiexec instead -- we'll see
srun ~/workspace/lulesh/build/lulesh2.0 -s 30 -i 100 -r 100 -b 0 -c 0