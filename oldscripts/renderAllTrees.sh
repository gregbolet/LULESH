#!/bin/bash

SEARCH_DIR=$(pwd)

echo $SEARCH_DIR

for fullpath in "$SEARCH_DIR/dtree-latest-"*.yaml
do
	filename=$(basename $fullpath .yaml)
	dotfile=$SEARCH_DIR/$filename.dot
	pdffile=$SEARCH_DIR/$filename.pdf

	echo $fullpath
	echo $filename
	echo $dotfile
	echo $pdffile

	~/workspace/apollo/src/python/analysis/rtree2dot.py -i $fullpath -o $dotfile 

	dot -Tpdf $dotfile >> $pdffile

	rm $dotfile
done

rm $SEARCH_DIR/trees.zip

# Zip up all the files in the end
zip $SEARCH_DIR/trees.zip $SEARCH_DIR/*.pdf

rm $SEARCH_DIR/*.pdf