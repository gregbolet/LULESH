#!/bin/bash

cd /g/g15/bolet1/workspace/lulesh-region-fix-correct/LULESH

export DATA_DIR_NAME="PA_DP-OPS_TOT-INS_No-Mltpx_SingleModelReuse-TreeDepth4-3policies"
export EXE_DIR="../../buildPA3Policies"
export USE_SINGLE_MODEL=1
export USE_REGION_MODEL=0
export ENABLE_PERF_CNTRS=1
export ENABLE_MLTPX=0
export PERF_CNTRS="PAPI_DP_OPS,PAPI_TOT_INS"
export NUM_TRIALS=10
export DTREE_DEPTH=4

sbatch \
--job-name=luleshPASingleModel \
--output="./runlogs/$DATA_DIR_NAME.log" \
--open-mode=truncate \
--ntasks=1 \
--time=2:00:00 \
--export=ALL \
./problemSizeSweep.sh

export DATA_DIR_NAME="PA_DP-OPS_TOT-INS_No-Mltpx_RegionModelReuse-TreeDepth4-3policies"
export EXE_DIR="../../buildPA3Policies"
sbatch \
--job-name=luleshPARegionModel \
--output="./runlogs/$DATA_DIR_NAME.log" \
--open-mode=truncate \
--ntasks=1 \
--time=2:00:00 \
--export=ALL \
./problemSizeSweep.sh

export DATA_DIR_NAME="VA_RegionModelReuse-TreeDepth4-3policies"
export EXE_DIR="../../buildVA3Policies"
export USE_SINGLE_MODEL=0
export USE_REGION_MODEL=1
export ENABLE_PERF_CNTRS=0
sbatch \
--job-name=luleshVARegionModel \
--output="./runlogs/$DATA_DIR_NAME.log" \
--open-mode=truncate \
--ntasks=1 \
--time=2:00:00 \
--export=ALL \
./problemSizeSweep.sh

#export DATA_DIR_NAME="Vanilla_Lulesh_No_Apollo"
#export EXE_DIR="../../buildNoApollo"
#sbatch \
#--job-name=luleshNoApollo \
#--output="./runlogs/$DATA_DIR_NAME.log" \
#--open-mode=truncate \
#--ntasks=1 \
#--time=2:00:00 \
#--export=ALL \
#./problemSizeSweep.sh
