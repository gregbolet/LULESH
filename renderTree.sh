#!/bin/bash

~/workspace/apollo/src/python/analysis/rtree2dot.py -i ~/workspace/lulesh/build/dtree-latest-rank-0-CalcElemVolumeDerivative--hourglass.yaml \
	-o ~/workspace/lulesh/build/treefile.dot

dot -Tpdf treefile.dot >> treefile.pdf

