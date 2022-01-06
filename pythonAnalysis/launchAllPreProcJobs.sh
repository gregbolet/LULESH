#!/bin/bash

cd /g/g15/bolet1/workspace/lulesh-region-fix-correct/LULESH/pythonAnalysis/
ANALY_SCRIPT="preprocOneDataDir.py"

NUM_JOBS_LAUNCHED=0

function launchJob {

	sbatch \
	--job-name="preprocData" \
	--output="./runlogs/preproc-${APOLLO_TYPE}-${XPLR_POL}-${IMBAL}-${NUM_POLS}-${TREE_DEPTH}-${TRAIN_SIZE}.log" \
	--open-mode=truncate \
	--ntasks=1 \
	--time=02:00:00 \
	--export=ALL \
	./runPreProcScript.sh

	#--partition=pdebug \

	NUM_JOBS_LAUNCHED=$((NUM_JOBS_LAUNCHED+1))
}

# Let's go through all the desired combinations of test configurations
#pava=("VA_RegionMod" "PA_RegionMod" "PA_SingleMod" "NoApollo")
#pava=("VA_RegionMod" "PA_RegionMod" "PA_SingleMod")
pava=("PA_MEMAWARE_RegionMod" "PA_MEMAWARE_SingleMod")
explrPol=("Random" "RoundRobin")
#imbals=(0 8)
imbals=(8)
numPols=(3)
#treeDepths=(2 4)
treeDepths=(4)
trainSizes=(30 55 80)

for APOLLO_TYPE in ${pava[@]}; do
	export APOLLO_TYPE=${APOLLO_TYPE}
	for IMBAL in ${imbals[@]}; do
		export IMBAL=${IMBAL}
		if [ $APOLLO_TYPE == "NoApollo" ]; then # If we are going to run vanilla lulesh
  		launchJob
			continue
		fi
		for XPLR_POL in ${explrPol[@]}; do
			export XPLR_POL=${XPLR_POL}
			for NUM_POLS in ${numPols[@]}; do
				export NUM_POLS=${NUM_POLS}
				for TREE_DEPTH in ${treeDepths[@]}; do
					export TREE_DEPTH=${TREE_DEPTH}
					for TRAIN_SIZE in ${trainSizes[@]}; do
						export TRAIN_SIZE=${TRAIN_SIZE}
						launchJob
					done
				done
			done
		done
	done
done

echo "NUM JOBS LAUNCHED ${NUM_JOBS_LAUNCHED}"