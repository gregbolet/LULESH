#!/bin/bash

# This script will zip up the trace CSV data for extraction to a Google Colab notebook

EXE_DIR_BASE="../../"

cd /g/g15/bolet1/workspace/lulesh-region-fix-correct/LULESH

# These will be constant across runs
# The PerfCntr vars get ignored by VA
export NUM_TRIALS=3

filesToZip=()

function getCSVs {

	#echo $DATA_DIR_NAME
	DATA_DIR="./runData/$DATA_DIR_NAME"
	runlog="./runlogs/${DATA_DIR_NAME}.log"
	for ((i=30;i<=80;i+=10)); do
	    PROBLEM_SIZE=$i
	    for ((j=1;j<=$NUM_TRIALS;j+=1)); do
	    	RUN_DATA_DIR="$DATA_DIR/run_size${i}_$j"
		CSV_DIR="${RUN_DATA_DIR}/trace-lulesh-${DATA_DIR_NAME}"
		pushd "${CSV_DIR}"
			filesToZip+=($(pwd))
		popd
	    done
	done

}

# Lists of all the variables we can sweep through
#numPolicies=(0 2 3 6)
numPolicies=(3)
treeDepths=(2 4)
luleshImbalance=(0 8)
apolloType=("VA" "PA")
trainSize=(30 55 80)
policyExplore=("RoundRobin" "Random")

for IMBAL in ${luleshImbalance[@]}; do
	export IMBAL=${IMBAL}
	for POL in ${numPolicies[@]}; do
		if ((POL == 0)); then # If we are going to run vanilla lulesh
			export DATA_DIR_NAME="NoApollo_c${IMBAL}"
			export EXE_DIR="${EXE_DIR_BASE}buildNoApollo"
			getCSVs
		else #otherwise we are running VA/PA
			for APOLLO in ${apolloType[@]}; do
				export EXE_DIR="${EXE_DIR_BASE}build${APOLLO}${POL}Policies"
			for EXPLORE_POLICY in ${policyExplore[@]}; do
				export EXPLORE_POLICY=$EXPLORE_POLICY
			for TREE_DEPTH in ${treeDepths[@]}; do
				export DTREE_DEPTH=$TREE_DEPTH
			for TRAINSIZE in ${trainSize[@]}; do
				export TRAIN_SIZE=$TRAINSIZE
				# Let's do a region model run
				export DATA_DIR_NAME="${APOLLO}_RegionMod_explr${EXPLORE_POLICY}_c${IMBAL}_pol${POL}_depth${TREE_DEPTH}_trainSize${TRAINSIZE}"
				export USE_SINGLE_MODEL=0
				export USE_REGION_MODEL=1
				getCSVs	

				if [ $APOLLO == "PA" ]; then # If it's PA, also do a Single model run
					export DATA_DIR_NAME="${APOLLO}_SingleMod_explr${EXPLORE_POLICY}_c${IMBAL}_pol${POL}_depth${TREE_DEPTH}_trainSize${TRAINSIZE}"
					export USE_SINGLE_MODEL=1
					export USE_REGION_MODEL=0
					getCSVs	
				fi
			done
			done
			done
			done
		fi
	done
done

echo "${filesToZip[@]}"


# For each directory of interest, zip up the csv files
