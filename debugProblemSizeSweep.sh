#!/bin/bash

EXE_DIR_BASE="../../"

cd /g/g15/bolet1/workspace/lulesh-region-fix-correct/LULESH

# These will be constant across runs
# The PerfCntr vars get ignored by VA
export ENABLE_PERF_CNTRS=1
export PERF_CNTRS="PAPI_DP_OPS,PAPI_TOT_INS,PAPI_L3_TCM"
export ENABLE_MLTPX=1
export NUM_TRIALS=3
export TRACE_CSV=0
export STORE_MODELS=1

NUM_JOBS_LAUNCHED=0

function launchJob {

	if ((IMBAL == 0)) && (( TRAIN_SIZE == 30)); then
		export APOLLO_PERIOD=2100728
	elif ((IMBAL == 0)) && ((TRAIN_SIZE == 55)); then
		export APOLLO_PERIOD=2255000
	elif ((IMBAL == 0)) && ((TRAIN_SIZE == 80)); then
		export APOLLO_PERIOD=2255000
	elif ((IMBAL == 8)) && ((TRAIN_SIZE == 30)); then
		export APOLLO_PERIOD=10600568
	elif ((IMBAL == 8)) && ((TRAIN_SIZE == 55)); then
		export APOLLO_PERIOD=11375000
	elif ((IMBAL == 8)) && ((TRAIN_SIZE == 80)); then
		export APOLLO_PERIOD=11375000
	else
		export APOLLO_PERIOD=2100728
	fi

	#echo "${APOLLO_PERIOD} is the period"

	sbatch \
	--job-name="lulesh${DATA_DIR_NAME}"\
	--output="./runlogs/${DATA_DIR_NAME}.log" \
	--open-mode=truncate \
	--ntasks=1 \
	--time=03:00:00 \
	--export=ALL \
	./problemSizeSweep.sh

	echo $DATA_DIR_NAME

	NUM_JOBS_LAUNCHED=$((NUM_JOBS_LAUNCHED+1))
}

# --partition=pdebug \

# Lists of all the variables we can sweep through
numPolicies=(3)
treeDepths=(4)
luleshImbalance=(8)
apolloType=("PA")
trainSize=(80 55 30)
policyExplore=("RoundRobin" "Random")

for IMBAL in ${luleshImbalance[@]}; do
	export IMBAL=${IMBAL}
	for POL in ${numPolicies[@]}; do
		if ((POL == 0)); then # If we are going to run vanilla lulesh
			export DATA_DIR_NAME="NoApollo_c${IMBAL}"
			export EXE_DIR="${EXE_DIR_BASE}buildNoApollo"
  			launchJob
		else #otherwise we are running VA/PA
			for APOLLO in ${apolloType[@]}; do
				#export EXE_DIR="${EXE_DIR_BASE}build${APOLLO}${POL}Policies"
				export EXE_DIR="${EXE_DIR_BASE}buildPA3PoliciesMemIntenAware"
			for EXPLORE_POLICY in ${policyExplore[@]}; do
				export EXPLORE_POLICY=$EXPLORE_POLICY
			for TREE_DEPTH in ${treeDepths[@]}; do
				export DTREE_DEPTH=$TREE_DEPTH
			for TRAINSIZE in ${trainSize[@]}; do
				export TRAIN_SIZE=$TRAINSIZE
				# Let's do a region model run
				export DATA_DIR_NAME="${APOLLO}_MEMAWARE_RegionMod_explr${EXPLORE_POLICY}_c${IMBAL}_pol${POL}_depth${TREE_DEPTH}_trainSize${TRAINSIZE}"
				export USE_SINGLE_MODEL=0
				export USE_REGION_MODEL=1
				launchJob

				if [ $APOLLO == "PA" ]; then # If it's PA, also do a Single model run
					export DATA_DIR_NAME="${APOLLO}_MEMAWARE_SingleMod_explr${EXPLORE_POLICY}_c${IMBAL}_pol${POL}_depth${TREE_DEPTH}_trainSize${TRAINSIZE}"
					export USE_SINGLE_MODEL=1
					export USE_REGION_MODEL=0
					launchJob
				fi
			done
			done
			done
			done
		fi
	done
done

echo "Num jobs launched: $NUM_JOBS_LAUNCHED"

#export DATA_DIR_NAME="PA_DP-OPS_TOT-INS_No-Mltpx_SingleModelReuse-TreeDepth4-3policies"
#export EXE_DIR="../../buildPA3Policies"
#export USE_SINGLE_MODEL=1
#export USE_REGION_MODEL=0
#export ENABLE_PERF_CNTRS=1
#export ENABLE_MLTPX=0
#export PERF_CNTRS="PAPI_DP_OPS,PAPI_TOT_INS"
#export NUM_TRIALS=10
#export DTREE_DEPTH=4
#
#sbatch \
#--job-name=luleshPASingleModel \
#--output="./runlogs/$DATA_DIR_NAME.log" \
#--open-mode=truncate \
#--ntasks=1 \
#--time=2:00:00 \
#--export=ALL \
#./problemSizeSweep.sh
#
#export DATA_DIR_NAME="PA_DP-OPS_TOT-INS_No-Mltpx_RegionModelReuse-TreeDepth4-3policies"
#export EXE_DIR="../../buildPA3Policies"
#sbatch \
#--job-name=luleshPARegionModel \
#--output="./runlogs/$DATA_DIR_NAME.log" \
#--open-mode=truncate \
#--ntasks=1 \
#--time=2:00:00 \
#--export=ALL \
#./problemSizeSweep.sh
#
#export DATA_DIR_NAME="VA_RegionModelReuse-TreeDepth4-3policies"
#export EXE_DIR="../../buildVA3Policies"
#export USE_SINGLE_MODEL=0
#export USE_REGION_MODEL=1
#export ENABLE_PERF_CNTRS=0
#sbatch \
#--job-name=luleshVARegionModel \
#--output="./runlogs/$DATA_DIR_NAME.log" \
#--open-mode=truncate \
#--ntasks=1 \
#--time=2:00:00 \
#--export=ALL \
#./problemSizeSweep.sh
#
##export DATA_DIR_NAME="Vanilla_Lulesh_No_Apollo"
##export EXE_DIR="../../buildNoApollo"
##sbatch \
##--job-name=luleshNoApollo \
##--output="./runlogs/$DATA_DIR_NAME.log" \
##--open-mode=truncate \
##--ntasks=1 \
##--time=2:00:00 \
##--export=ALL \
##./problemSizeSweep.sh
#