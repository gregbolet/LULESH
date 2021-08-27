#!/bin/bash

OPTDIR=/g/g15/bolet1/workspace/faros/FAROS/opt-viewer

OPTVIEWER=$OPTDIR/optviewer.py
OPTDIFF=$OPTDIR/optdiff.py
OPTSTATS=$OPTDIR/opt-stats.py

SRCDIR_A=/g/g15/bolet1/workspace/lulesh
SRCYAML_A=$SRCDIR_A/build/CMakeFiles/lulesh2.0.dir

SRCDIR_B=/g/g15/bolet1/workspace/lulesh-region-fix-correct/LULESH
SRCYAML_B=$SRCDIR_B/build/CMakeFiles/lulesh2.0.dir

OUTPUTDIR=/g/g15/bolet1/workspace/lulesh/optimRemarkViz
OUTPUTFILE=$OUTPUTDIR/luleshOptimDiffOutput

mkdir -p "$OUTPUTDIR/CI"
mkdir -p "$OUTPUTDIR/MI"

#python3 $OPTVIEWER --output-dir $OUTPUTDIR $SRCYAML_A $SRCYAML_B

python3 $OPTVIEWER --output-dir $OUTPUTDIR/MI --source-dir $SRCDIR_A $SRCYAML_A/lulesh.cc.opt.yaml 
python3 $OPTVIEWER --output-dir $OUTPUTDIR/CI --source-dir $SRCDIR_B $SRCYAML_B/lulesh.cc.opt.yaml 
python3 $OPTSTATS $SRCYAML_A/lulesh.cc.opt.yaml
python3 $OPTSTATS $SRCYAML_B/lulesh.cc.opt.yaml
#python3 $OPTVIEWER --output-dir $OUTPUTDIR $OUTPUTFILE

rm viz.zip
zip -r viz.zip $OUTPUTDIR


#dd if=$SRCYAML_A/lulesh.cc.opt.yaml bs=1 count=2777262