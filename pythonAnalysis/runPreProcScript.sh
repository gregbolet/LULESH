#!/bin/bash

cd /g/g15/bolet1/workspace/lulesh-region-fix-correct/LULESH/pythonAnalysis/
ANALY_SCRIPT="preprocOneDataDir.py"

srun -n1 -N1 \
--export=ALL \
python3 ./${ANALY_SCRIPT} \
--apolloType ${APOLLO_TYPE} \
--xplrPol ${XPLR_POL} \
--imbal ${IMBAL} \
--numPol ${NUM_POLS} \
--depth ${TREE_DEPTH} \
--trainSize ${TRAIN_SIZE}