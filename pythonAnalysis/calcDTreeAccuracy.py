#!/usr/bin/env python3
import argparse
import pandas as pd
import time
import numpy as np
import glob
import matplotlib.pyplot as plt
from cv2.ml import DTrees_load

def autolabel(ax, rects):
    """Attach a text label above each bar in *rects*, displaying its height."""
    for rect in rects:
        height = rect.get_height()
        ax.annotate('%.2f'%(height),
                    xy=(rect.get_x() + rect.get_width() / 2, height),
                    xytext=(0, 3),  # 3 points vertical offset
                    textcoords="offset points",
                    ha='center', va='bottom')

def read_csv(dir, model, csv_map):
    globlist = glob.glob('%s/trace*%s*.csv' % (dir, model))
    nfiles = len(globlist)
    for i, f in enumerate(globlist):
        print('\r=== Reading %-100s %06d/%06d' %
            (f, i+1, nfiles), flush=True, end='')
        try:
            csv_map[f] = pd.read_csv(f, sep=' ', header=0)
        except pd.errors.EmptyDataError:
            print('Warning: no data in', f)

def compute_execution_time(rank, data, xtime_per_pol, init_model, trained_model = None):
    num_regions = 0
    xtimes = data.loc[ \
            (data['rankid']==rank) & \
            (data['training']==init_model) \
            ]['xtime']
    xtime_init_model = sum(xtimes)
    num_regions += len(xtimes.index)

    if trained_model:
        xtimes = data.loc[ \
                (data['rankid']==rank) & \
                (data['training']==trained_model) \
                ]['xtime']
        xtime_trained_model = sum(xtimes)
        num_regions += len(xtimes.index)
    else:
        xtime_trained_model = 0

    xtime_per_pol[init_model] = (xtime_init_model, xtime_trained_model)
    print('len', num_regions,
            'Rank %d %s=%.6f/%s=%.6f xtime %.6f' %
            (rank, init_model, xtime_per_pol[init_model][0], trained_model, xtime_per_pol[init_model][1],
             xtime_per_pol[init_model][0]+xtime_per_pol[init_model][1]))

def compute_speedup(xtime_per_pol, model, min_xtime_static_pol):
    print('%s speedup vs defaults (Static,0 / %s): %.2f'%
          (
              model,
              model,
              sum(xtime_per_pol['Static,0'])/sum(xtime_per_pol[model]),
          )
    )
    print('%s speedup vs best static (%s / %s): %.2f'%
          (
              model,
              min_xtime_static_pol,
              model,
              sum(xtime_per_pol[min_xtime_static_pol]) /
              sum(xtime_per_pol[model]),
          )
    )

def compute_accuracy(rank, data, opt_data, npolicies, DIFF_PCT, init_model, trained_model):
    # Create dataframes indexed by region, idx to match with isin() in opt (avoids index mismatch).
    data_region_idx = data.loc[(data['rankid'] == rank) & \
        #(data['training'].str.contains('RoundRobin|DecisionTree', regex=True))] \
        (data['training'].str.contains(trained_model))] \
        [['region', 'idx', 'policy', 'xtime']].set_index( \
        ['region', 'idx']).sort_index()
    opt_region_idx = opt_data[['policy', 'xtime']]
    #print('=== DATA RR ===')
    #print(data_rr_region_idx[['policy']][0:10])
    #input('cont')
    #print('=== DATA OPT ===')
    #print(opt_region_idx[['policy']][0:10])
    #input('cont')

    cond = data_region_idx[['policy']].isin(opt_region_idx[['policy']])

    nrows = len(cond.index)
    nmatch = cond[cond['policy'] == True].count()
    print('= %s|%s'%(init_model, trained_model))
    print('Rank %d %s|%s accuracy %.2f%%'%(rank, init_model, trained_model, (nmatch*100.0)/nrows))
    #input('cont')

    (hist, bins) = np.histogram(opt_region_idx['policy'], bins=np.arange(npolicies))
    print('Rank %d Opt'%(rank), *list(zip(bins[:-1], hist)))
    (hist, bins) = np.histogram(data_region_idx['policy'], bins=np.arange(npolicies))
    print('Rank %d %s|%s'%(rank, init_model, trained_model), *list(zip(bins[:-1], hist)))

    # Compute relaxed accuracy +/- 10% of optimal
    # Exclude matching policy indices for relaxed accuracy
    data_region_idx = data_region_idx[~data_region_idx.index\
            .isin(cond[cond['policy'] == True].index)]
    opt_region_idx = opt_region_idx[~opt_region_idx.index.isin(cond[cond['policy'] == True].index)]

    if int(nmatch) < nrows:
        diff_opt_rr = abs(opt_region_idx['xtime'] - data_region_idx['xtime'])*100.0 / opt_region_idx['xtime']
        try:
            nrelaxed = diff_opt_rr.le(DIFF_PCT).value_counts()[True]
        except KeyError:
            nrelaxed = 0
        #print('le than %.2f%% %d'%( DIFF_PCT, nrelaxed))
        #input('cont')
        nrelaxed += nmatch
    else:
        nrelaxed = nmatch
    print('Rank %d %s|%s relaxed accuracy %.2f%% (+/- %.2f%% optimal)'%(rank, init_model, trained_model,
        (nrelaxed*100.0)/nrows, DIFF_PCT))

    print('===')
    return (nmatch, nrelaxed, nrows)

def compute_time_weighted_accuracy(rank, data, opt_data, npolicies, DIFF_PCT, init_model, trained_model):
    # Create dataframes indexed by region, idx to match with isin() in opt (avoids index mismatch).
    # This df contains the run information while using the decision trees
    data_region_idx = data.loc[(data['rankid'] == rank) & \
        #(data['training'].str.contains('RoundRobin|DecisionTree', regex=True))] \
        (data['training'].str.contains(trained_model))] \
        [['region', 'idx', 'policy', 'xtime']].set_index( \
        ['region', 'idx']).sort_index()

    # This df contains the optimal policy for each step of the execution
    opt_region_idx = opt_data[['policy', 'xtime']]

    # This DF contains the indicators of optimal execution or not 
    cond = data_region_idx[['policy']].isin(opt_region_idx[['policy']])

    nrows = len(cond.index)
    nmatch = cond[cond['policy'] == True].count()
    print('= %s|%s'%(init_model, trained_model))
    print('Rank %d %s|%s accuracy %.2f%%'%(rank, init_model, trained_model, (nmatch*100.0)/nrows))
    #input('cont')

    (hist, bins) = np.histogram(opt_region_idx['policy'], bins=np.arange(npolicies))
    print('Rank %d Opt'%(rank), *list(zip(bins[:-1], hist)))
    (hist, bins) = np.histogram(data_region_idx['policy'], bins=np.arange(npolicies))
    print('Rank %d %s|%s'%(rank, init_model, trained_model), *list(zip(bins[:-1], hist)))

    # Compute relaxed accuracy +/- 10% of optimal
    # Exclude matching policy indices for relaxed accuracy
    data_region_idx = data_region_idx[~data_region_idx.index\
            .isin(cond[cond['policy'] == True].index)]
    opt_region_idx = opt_region_idx[~opt_region_idx.index.isin(cond[cond['policy'] == True].index)]

    if int(nmatch) < nrows:
        diff_opt_rr = abs(opt_region_idx['xtime'] - data_region_idx['xtime'])*100.0 / opt_region_idx['xtime']
        try:
            nrelaxed = diff_opt_rr.le(DIFF_PCT).value_counts()[True]
        except KeyError:
            nrelaxed = 0
        #print('le than %.2f%% %d'%( DIFF_PCT, nrelaxed))
        #input('cont')
        nrelaxed += nmatch
    else:
        nrelaxed = nmatch
    print('Rank %d %s|%s relaxed accuracy %.2f%% (+/- %.2f%% optimal)'%(rank, init_model, trained_model,
        (nrelaxed*100.0)/nrows, DIFF_PCT))

    print('===')
    return (nmatch, nrelaxed, nrows)



# This function evaluates all the oracle data on the 
# decision trees in the provided directory. 
# ASSUMPTIONS:
# - all the regions listen in the oracle dataset have a corresponding dtree
# - the oracle dataset was made using the same policy count as the dtrees were trained on
# - the accuracy is the total_correct_pred_x_time/total_x_time
def compute_acc_for_dtrees(oracle, dtreeDir):
    print('=== Reading in DTrees in dir', dtreeDir)
    tree_map = {}

    t = time.perf_counter()
    # Only grab the latest trees
    yamlfiles = list(glob.glob('%s/*latest*.yaml' % (dtreeDir)))
    #print(yamlfiles)

    for yamlFile in yamlfiles:
        # Extract the region name from the yaml file
        idx = yamlFile.find('lulesh.cc.apollo')
        regName = yamlFile[idx:-5]
        #print(regName)

        tree = DTrees_load(yamlFile)
        #print('Tree maxDepth', tree.getMaxDepth())
        #print('Tree maxCatgeories', tree.getMaxCategories())
        #print('Tree varcount', tree.getVarCount())
        #print('')

        # Map the region name to the tree
        tree_map[regName] = tree

        #if tree.getVarCount() == 1:
        #    a,b = tree.predict(np.array([[27000],[200]]).astype('float32'))
        #    print(a,b)

    elapsed_time = time.perf_counter() - t
    print('=== Read in DTree YAML files in', int(elapsed_time), 'second(s)')

    # Get the feature column names (they all start with 'f')
    featCols = []
    for name in oracle.columns:
       if 'f' in name:
           featCols.append(name) 

    t = time.perf_counter()

    oracle['isCorrectPred'] = False
    oracle['featArr'] = oracle[featCols].values.tolist()
    oracle['featArr'] = oracle['featArr'].apply(lambda x: np.array([i for i in x if i != -1]).astype('float32'))

    elapsed_time = time.perf_counter() - t
    print('=== Created proper feat array column in ', int(elapsed_time), 'second(s)')
    
    # Now let's go through each tree and do a grouped prediction
    # of all the data using that tree
    for region in tree_map.keys():
        t = time.perf_counter()
        subset = oracle.loc[oracle['region'] == region]
        subsetToPred = np.array(subset['featArr'].values.tolist())
        truthLabels = np.array(subset['policy'].values.tolist()).astype('float')
        retval, preds = tree_map[region].predict(subsetToPred)
        preds = preds.flatten()
        #print(preds)
        #print(truthLabels)
        
        #print((preds == truthLabels))
        oracle.loc[subset.index, 'isCorrectPred'] = (preds == truthLabels)
        #print(oracle.loc[subset.index].head())

        elapsed_time = time.perf_counter() - t
        print('=== \t Processed', region, ' in', int(elapsed_time), 'second(s)')

    print('=== Completed isCorrectPred column')

    # Now that we have the 'isCorrectPred' column, we can calculate the 
    # accuracy score of the entire execution using the provided trees.
    # gather all the mispredictions and correct predictions
    mispreds = oracle.loc[oracle['isCorrectPred'] == False]
    corpreds = oracle.loc[oracle['isCorrectPred'] == True]

    totalXTime = oracle['xtime'].sum()
    mispredXTime = mispreds['xtime'].sum()
    corpredXTime = corpreds['xtime'].sum()

    acc = corpredXTime/totalXTime

    print('=== Total (Optimal) Exec Time:', totalXTime, 'seconds')
    print('=== Accuracy:', acc)

    return acc


# This function evaluates all the oracle data on the 
# CSV data in the provided directory. 
# ASSUMPTIONS:
# - all the regions listen in the oracle dataset have a corresponding CSV trace file
# - the oracle dataset was made using the same policy count as the dtrees were trained on
# - the accuracy is the total_correct_pred_x_time/total_x_time
# - Only samples with training='DecisionTree' are considered
def compute_acc_for_traces(oracle, traceDir):

    print('=== Reading in CSVs in dir', traceDir)

    # Only grab the CSV trace files
    tracefiles = list(glob.glob('%s/*lulesh.cc.apollo*.csv' % (traceDir)))
    tracefiles.sort()

    # This will store the summary data about each region that we examine
    region_map = {}

    for csvFile in tracefiles:
        #print('raw file name:', csvFile)
        t = time.perf_counter()
        # Extract the region name from the trace file name
        idx = csvFile.find('lulesh.cc.apollo')
        endIdx = csvFile.find('-rank-0.csv')
        regName = csvFile[idx:endIdx]
        print('Working on region:[' + str(regName)+']')

        data = pd.read_csv(csvFile, sep=' ', header=0)
        #print(oracle['region'].unique().tolist())
        # reset the index to line up traces
        regionData = oracle.loc[oracle['region'] == regName].copy().reset_index()

        #print(data.shape[0], regionData.shape[0])
        assert data.shape[0] == regionData.shape[0]

        # Select only the traces executed with the model,
        # exclude the training samples
        #data = data.loc[data['training'] == 'DecisionTree']
        #regionData = regionData.iloc[data.index]
        #assert data.shape[0] == regionData.shape[0]

        regionData['isCorrectPred'] = False

        #print(regionData.head(10)['policy'])
        #print(data.head(10))

        # Now let's compare the policy columns of both
        regionData['isCorrectPred'] = (data['policy'] == regionData['policy'])
        #print(regionData.head(10))

        mispreds = regionData.loc[regionData['isCorrectPred'] == False]
        corpreds = regionData.loc[regionData['isCorrectPred'] == True]

        totalXTime = regionData['xtime'].sum()
        mispredXTime = mispreds['xtime'].sum()
        corpredXTime = corpreds['xtime'].sum()

        acc = corpredXTime/totalXTime

        region_map[regName] = [totalXTime, mispredXTime, corpredXTime]
        elapsed_time = time.perf_counter() - t

        print('=== Region (Optimal) Exec Time:', totalXTime, 'seconds')
        print('=== Region Accuracy:', acc)
        print('=== Processed region', regName, 'in', int(elapsed_time), 'second(s)')

    summaryData = np.array(list(region_map.values()))
    #print(summaryData)

    totalXTime   = summaryData[:,0].sum()
    mispredXTime = summaryData[:,1].sum()
    corpredXTime = summaryData[:,2].sum()

    acc = corpredXTime/totalXTime
    print('=== Total (Optimal) Exec Time:', totalXTime, 'seconds')
    print('=== Accuracy:', acc)

    return

# NOTE: We assume the problem size of the Oracle matches that of the 
# DTrees we want to calculate accuracy for. We also assume that the
# oracle datasets were made with 3 policies, (0: 36 threads, 1: 18 threads, 2: 1 thread)
# and that the dtrees passed in were trained using 3 policies
def main():
    parser = argparse.ArgumentParser(description='Take an Oracle Dataset and DTree files, then compute DTree Accuracy.')
    parser.add_argument('--oracleFile', type=str, help='the CSV oracle file for a given problem size', required=True)
    parser.add_argument('--dtreeDir', type=str, help='the dir where all the dtree YAML files are', required=False)
    parser.add_argument('--csvTraceDir', type=str, help='the dir where all the CSV trace files are', required=False)
    args = parser.parse_args()

    if args.oracleFile == None:
        print('Missing Oracle File as required input')
        return

    print('=== Reading in Oracle CSV file...')

    t = time.perf_counter()

    # Read in the Oracle dataset
    #oracle = pd.read_csv(args.oracleFile, sep=' ', header=0, nrows=1000)
    oracle = pd.read_csv(args.oracleFile, sep=' ', header=0)

    elapsed_time = time.perf_counter() - t
    print('Read in Oracle CSV file in', int(elapsed_time), 'second(s)')
    print('Oracle CSV file shape: ', oracle.shape)


    if args.dtreeDir != None:
        print('dtreeDir activated!')
        compute_acc_for_dtrees(oracle, args.dtreeDir)

    if args.csvTraceDir != None:
        print('csvTrace activated!')
        compute_acc_for_traces(oracle, args.csvTraceDir)

    return

    if args.nstatic > 0:
        csv_map= {}
        for p in range(0, args.nstatic):
            read_csv(args.dir, 'Static,%d'%(p), csv_map)
        data_map['Static'] = pd.concat(csv_map.values(), ignore_index=True, sort=True)

    if args.rr:
        csv_map={}
        read_csv(args.dir, 'RoundRobin', csv_map)
        data_map['RoundRobin'] = pd.concat(csv_map.values(), ignore_index=True, sort=True)

    if args.random:
        csv_map={}
        read_csv(args.dir, 'Random', csv_map)
        data_map['Random'] = pd.concat(csv_map.values(), ignore_index=True, sort=True)

    if args.load:
        csv_map={}
        read_csv(args.dir, 'Load', csv_map)
        data_map['Load'] = pd.concat(csv_map.values(), ignore_index=True, sort=True)

    if args.opt:
        csv_map={}
        read_csv(args.dir, 'Optimal', csv_map)
        data_map['Optimal'] = pd.concat(csv_map.values(), ignore_index=True, sort=True)


    print()
    xtime_per_pol = {}
    for i in range(args.nranks):
        # Print execution time for Static training.
        for j in range(args.nstatic):
            compute_execution_time(i, data_map['Static'], xtime_per_pol, 'Static,%d'%(j))
        # Print execution time for RoundRobin training plus DecisionTree execution.
        if args.rr:
            compute_execution_time(i, data_map['RoundRobin'], xtime_per_pol, 'RoundRobin', 'DecisionTree')
        # Print execution time for Random training plus DecisionTree execution.
        if args.random:
            compute_execution_time(i, data_map['Random'], xtime_per_pol, 'Random', 'DecisionTree')
        if args.load:
            compute_execution_time(i, data_map['Load'], xtime_per_pol, 'Load')
        if args.opt:
            compute_execution_time(i, data_map['Optimal'], xtime_per_pol, 'Optimal')

    print()
    print('=== Computing optimal policy selection...')
    for i in range(args.nranks):
        t1 = time.perf_counter()
        # Find optimal policy selection (fastest way): select by rank equals i and training equals to Static;
        # sort by xtime;
        # drop_duplicates grouped by region, idx to keep minimum;
        # set index to (region, idx) as the unique identifier
        # sort by index for easy visualization and comparison

            #&(data_map['Static']['training'].str.contains('Static'))]\
        opt = data_map['Static'].loc[(data_map['Static']['rankid'] == i)]\
            .sort_values(by=['xtime'])\
            .drop_duplicates(['region', 'idx'], keep='first')\
            .set_index(['region', 'idx'])\
            .sort_index()

        t2 = time.perf_counter()
        #print('=========== OPT =============\n', opt.to_string(), '\n=============================',
        #        file=open('opt.txt','w'))
        #print(len(opt.index))
        #print(len(data_map['Static'].index)/args.nstatic)
        #print(len(data_map['Static'].index), args.nstatic)
        #print(opt.shape[0])
        #print(data_map['Static'].shape[0])
        assert len(opt.index) == len(data_map['Static'].index)/args.nstatic, 'Data error'

        print('=== Writing out optimal policy selection...')
        if args.write_opt:
            index_set = set(opt.index.get_level_values(0))
            for region in index_set:
                opt_policies = [str(x) for x in opt.loc[region, 'policy']]
                with open('opt-%s-rank-%s.txt'%(region, i), 'w') as f:
                    f.write(','.join(opt_policies))

        #print('opt-rank-%d time %.6f s' % (i, t2-t1))
        print('opt-rank-%d xtime %.6f'%(i, sum(opt['xtime'])))
        min_xtime_static_pol = min(
            {k: v for k, v in xtime_per_pol.items() if 'Static' in k}, key=xtime_per_pol.get)

        # Create as a tuple to match (init_model, trained_model) tuples of actual policies.
        xtime_per_pol['Opt'] = (sum(opt['xtime']), 0)
        compute_speedup(xtime_per_pol, 'Opt', min_xtime_static_pol)

        if args.rr:
            compute_speedup(xtime_per_pol, 'RoundRobin', min_xtime_static_pol)
        if args.random:
            compute_speedup(xtime_per_pol, 'Random', min_xtime_static_pol)

        print('=== Compute accuracy...')

        accuracy= {}
        DIFF_PCT = 10.0
        if args.rr:
            accuracy['RoundRobin'] =\
                compute_accuracy(i, data_map['RoundRobin'], opt, args.nstatic+1, DIFF_PCT, 'RoundRobin', 'DecisionTree')
        if args.random:
            accuracy['Random'] =\
                compute_accuracy(i, data_map['Random'], opt, args.nstatic+1, DIFF_PCT, 'Random', 'DecisionTree')
        if args.load:
            accuracy['Load'] =\
                compute_accuracy(i, data_map['Load'], opt, args.nstatic+1, DIFF_PCT, 'Load', 'Load')
        if args.opt:
            accuracy['Optimal'] =\
                compute_accuracy(i, data_map['Optimal'], opt, args.nstatic+1, DIFF_PCT, 'Optimal', 'Optimal')

        if args.plot:
            fig, ax = plt.subplots(figsize=(10, 6))
            plt.title(args.dir)
            plt.ylabel('Execution time (s)')
            plt.xlabel('Policy')
            rect = ax.bar(np.arange(len(xtime_per_pol)), xtime_per_pol.values())
            plt.xticks(np.arange(len(xtime_per_pol)), xtime_per_pol.keys(), rotation=-90)
            textstr = '\n'.join((
                r'Speedup (default) Static,0 / Opt = %.2f'%(xtime_per_pol['Static,0']/xtime_per_pol['Opt']),
                r'Speedup (best) %s / Opt = %.2f'%(min_xtime_static_pol, xtime_per_pol[min_xtime_static_pol]/xtime_per_pol['Opt'])))
            accuracy_print = [
                r'%s Accuracy strict = %.2f%%|relaxed (+/- %.2f%%) %.2f%%'%
                    (k, (v[0]*100.0)/v[2], DIFF_PCT, (v[1]*100.0)/v[2])
                    for k, v in accuracy.items()
            ]
            textstr = '\n'.join(accuracy_print)
            props = dict(boxstyle='round', facecolor='wheat', alpha=0.5)
            ax.text(0.5, 0.95, textstr, transform=ax.transAxes, fontsize=10,
                    verticalalignment='top', bbox=props)
            autolabel(ax, rect)
            plt.tight_layout()
            plt.savefig('%s.pdf'%(args.dir))

if __name__ == "__main__":
    main()
