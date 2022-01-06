#!/bin/bash

# Let's launch buildVA3Policies in a static manner
# for the 0 (36 threads), 1 (18 threads), and 2 (1 thread)
# policies. We want to use this data to build an oracle

cd /g/g15/bolet1/workspace/lulesh-region-fix-correct/LULESH

export EXE_DIR="../../buildVA3Policies"
export USE_SINGLE_MODEL=0
export USE_REGION_MODEL=1
export ENABLE_PERF_CNTRS=0
export NUM_TRIALS=3
export DTREE_DEPTH=4
export TRACE_CSV=1

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
  --job-name=luleshVAStatic \
  --output="./runlogs/${DATA_DIR_NAME}.log" \
  --open-mode=truncate \
  --ntasks=1 \
  --time=03:00:00 \
  --export=ALL \
  ./problemSizeSweep.sh

	echo $DATA_DIR_NAME

	NUM_JOBS_LAUNCHED=$((NUM_JOBS_LAUNCHED+1))
}

treeDepths=(4)
luleshImbalance=(8)
apolloType=("VA")
trainSize=(30 55 80)
staticPolicies=("Static,0" "Static,1" "Static,2")

#numPolicies=(0 3)
#treeDepths=(2)
#luleshImbalance=(0)
#apolloType=("VA" "PA")
#trainSize=(30 55)
#policyExplore=("RoundRobin")

for IMBAL in ${luleshImbalance[@]}; do
	export IMBAL=${IMBAL}
	for EXPLORE_POLICY in ${staticPolicies[@]}; do
		export EXPLORE_POLICY=$EXPLORE_POLICY
	for TREE_DEPTH in ${treeDepths[@]}; do
		export DTREE_DEPTH=$TREE_DEPTH
	for TRAINSIZE in ${trainSize[@]}; do
		export TRAIN_SIZE=$TRAINSIZE
		# Let's do a region model run
		export DATA_DIR_NAME="VA_RegionMod_explr${EXPLORE_POLICY}_c${IMBAL}_pol3_depth${TREE_DEPTH}_trainSize${TRAINSIZE}"
		launchJob
	done
	done
	done
done

echo "Num jobs launched: $NUM_JOBS_LAUNCHED"


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
