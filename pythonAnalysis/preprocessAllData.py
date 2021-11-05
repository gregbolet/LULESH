import os
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import glob

# Let's go through all the data directories
data_dir_base = '/g/g15/bolet1/workspace/lulesh-region-fix-correct/LULESH/runData'
logfile_dir_base = '/g/g15/bolet1/workspace/lulesh-region-fix-correct/LULESH/runlogs'
output_csvs_dir = '/g/g15/bolet1/workspace/lulesh-region-fix-correct/LULESH/preprocData'

os.chdir(data_dir_base)

def readCSVList(csvList):
	df = pd.DataFrame()
	for csv_file in csvList:
		csvdf = pd.read_csv(csv_file, sep=' ')
		df = df.append(csvdf, sort=True)
	return df

def gatherAllCSVs(apolloType, xplrPol, imbal, numPol, depth, trainSize):
	apolloType = apolloType + '_'
	xplrPol = 'explr' + str(xplrPol) + '_'
	imbal = 'c' + str(imbal) + '_'
	numPol = 'pol' + str(numPol) + '_'
	depth = 'depth'+str(depth)+'_'
	trainSize = 'trainSize' + str(trainSize)
	data_dir = ''
	data_dir_name = ''

	# Set the dir name we want to go into
	if 'NoApollo' in apolloType:
		data_dir = apolloType + imbal
	else:
		data_dir_name = apolloType + xplrPol + imbal + numPol + depth + trainSize
		data_dir = data_dir_base + '/' + data_dir_name

	print('Going into:', data_dir)

	# Go into the requested folder
	# if it doesn't exist, break
	try:
		os.chdir(data_dir)
	except:
		return data_dir_name, pd.DataFrame()

	# Get all the run folders
	allRunDirs = sorted(list(glob.glob("run_size*")))
	print(allRunDirs)

	allRunDirData = pd.DataFrame()

	for runDir in allRunDirs:
		runsize = runDir.replace('run_size','')
		runsize = int(runsize[:2])
		csv_dir = data_dir + '/' + runDir + '/trace-lulesh-' + data_dir_name
		print(csv_dir)
		print('Runsize:', runsize)

		runDirCSVs = sorted(list(glob.glob(csv_dir+"/*.csv")))
		#print(runDirCSVs)

		rundf = readCSVList(runDirCSVs)
		rundf['runsize'] = runsize

		allRunDirData = allRunDirData.append(rundf, sort=True)

	allRunDirData['pava'] = apolloType
	allRunDirData['xplrPol'] = xplrPol
	allRunDirData['imbal'] = imbal
	allRunDirData['numPol'] = numPol
	allRunDirData['depth'] = depth
	allRunDirData['trainsize'] = trainSize
	print(allRunDirData.shape)


	os.chdir(data_dir_base)
	return (data_dir_name, allRunDirData)

# Let's go through all the desired combinations of test configurations
pava = ['VA_RegionMod', 'PA_RegionMod', 'PA_SingleMod',
				'NoApollo', 'PA_MEMAWARE_RegionMod', 'PA_MEMAWARE_SingleMod']
explrPol = ['Random', 'RoundRobin']
imbals = [0, 8]
numPols = [3]
treeDepths = [2, 4]
trainSizes = [30, 55, 80]

def tryAllCombinations():
	for apolloType in pava:
		for xplrPol in explrPol:
			for imbal in imbals:
				for numPol in numPols:
					for depth in treeDepths:
						for trainSize in trainSizes:
							print('Gathering data for: ', apolloType, xplrPol, imbal, numPol, depth, trainSize)
							data_dir_name, dfAllData = gatherAllCSVs(apolloType, xplrPol, imbal, numPol, depth, trainSize)

							# If the requested directory was actually found and data gathered
							# (i.e: if the output df is large enough)
							if dfAllData.shape[0] > 100:	
								output_csv_name = data_dir_name + '.csv'
								dfAllData.to_csv(output_csvs_dir+'/'+output_csv_name, index=False)
							else:
								print('Data failed to gather for:', data_dir_name)

							return
	return

tryAllCombinations()

