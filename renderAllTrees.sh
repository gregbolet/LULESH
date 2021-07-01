#!/bin/bash

SEARCH_DIR=~/workspace/lulesh/build

echo $SEARCH_DIR

for fullpath in "$SEARCH_DIR"/*.yaml
do
	filename=$(basename $fullpath .yaml)
	echo $fullpath
	echo $filename

	dotfile=$SEARCH_DIR/$(filename).dot
	pdffile=$SEARCH_DIR/$(filename).pdf

	~/workspace/apollo/src/python/analysis/rtree2dot.py -i $fullpath -o $dotfile 

	dot -Tpdf $dotfile >> $pdffile

	rm $dotfile
done

# Zip up all the files in the end
zip $SEARCH_DIR/trees.zip $SEARCH_DIR/*.pdf