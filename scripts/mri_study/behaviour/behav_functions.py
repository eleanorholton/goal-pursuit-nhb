"""
Eleanor Holton
Date: 9/8/2023
"""
# PyTorch libraries
import numpy as np
import pandas as pd
import statsmodels.api as sm
import matplotlib.pyplot as plt

## Function to quantify persistence 
 
def find_indifference_point(df,p):
    
    endog = df.loc[(df["sampler_switch_value"].notna()) & (df["participant"]==p),"switch_trial"]
    exog = sm.add_constant(df.loc[(df["sampler_switch_value"].notna()) & (df["participant"]==p),"sampler_switch_value"])
    
    binom_fit = sm.GLM(endog, exog, family=sm.families.Binomial()).fit()
    
    # get parameters
    bias_const = binom_fit.params.const
    sampler_beta = binom_fit.params.sampler_switch_value
    
    # Find indifference point
    IP = -binom_fit.params.const / binom_fit.params.sampler_switch_value
    
    return IP, bias_const, sampler_beta


## Function to preprocess spatial data 

def categorise_previous_trial(df):
    
    # prepare magnitudes of options on previous trial
    mag_df = df.iloc[:-1, [df.columns.get_loc(c) for c in ['magnitudes_1','magnitudes_2','magnitudes_3']]]

    # columns to add
    df['prevBest'] = np.nan
    df['prevWorst'] = np.nan
    df['prevChoice'] = np.nan
    df['prevBest_mag'] = np.nan
    df['prevWorst_mag'] = np.nan
    df['prevChoice_mag'] = np.nan
    df['prevSamplerVal'] = np.nan
    df['prevSwitch'] = np.nan
    
    # iterate over trials, categorising the options in the previous trial to fill information on t+1 (index+1)
    for index, row in mag_df.iterrows(): 
        
        # Skip first trials of block 
        if df['trial_number'].values[index+1]==1:
            continue 

        # Add chosen item index (0,1,2) and offers/values 
        df.iloc[index+1, df.columns.get_loc('prevChoice')] = df.choice[index]-1 # subtract 1 to convert to item index 0,1,2
        df.iloc[index+1, df.columns.get_loc('prevChoice_mag')] = row[df.choice[index]-1] # index from magnitudes 

        # Get maximum and minimum of previous non-chosen options ('best' and 'worst' alternative, retrospectively)
        row[df.choice[index]-1] = np.nan # set previous choice to nan, to max over alternatives 
        ymax = row.reset_index(drop=True).idxmax(axis=0, skipna=True)
        ymin = row.reset_index(drop=True).idxmin(axis=0, skipna=True)

        df.iloc[index+1, df.columns.get_loc('prevBest')] = ymax
        df.iloc[index+1, df.columns.get_loc('prevWorst')] = ymin

        # Add magnitudes and values
        df.iloc[index+1, df.columns.get_loc('prevBest_mag')] = row[ymax]
        df.iloc[index+1, df.columns.get_loc('prevWorst_mag')] = row[ymin]

        # add whether the previous trial was a switch trial/sampler value of switching
        df.iloc[index+1, df.columns.get_loc('prevSamplerVal')] = df.sampler_switch_value[index]
        df.iloc[index+1, df.columns.get_loc('prevSwitch')] = df.switch_trial[index]
        
    return df

def add_spatial_contrasts (df, demeaned=0):
    
    participants = df['participant'].unique()
    nParticipants = len(participants)

    # Add de-meaned error 
    mean_acc_vals = np.empty([nParticipants])
    df['demeaned_error_1'], df['demeaned_error_2'], df['demeaned_error_3'] = [np.nan, np.nan, np.nan]

    mean_rt_vals = np.empty([nParticipants])
    df['demeaned_rt_1'], df['demeaned_rt_2'], df['demeaned_rt_3'] = [np.nan, np.nan, np.nan]

    for p,idx in zip(participants,range(nParticipants)):
        
        # Demean accuracy per participant
        mean_acc_vals[idx] = df.loc[df["participant"]==p,['itm1_err','itm2_err','itm3_err']].values.mean()
        df.loc[df.participant==p,'demeaned_error_1'] = df.loc[df.participant==p,'itm1_err'] - mean_acc_vals[idx]
        df.loc[df.participant==p,'demeaned_error_2'] = df.loc[df.participant==p,'itm2_err'] - mean_acc_vals[idx]
        df.loc[df.participant==p,'demeaned_error_3'] = df.loc[df.participant==p,'itm3_err'] - mean_acc_vals[idx]
        
        # Demean rt per participant 
        mean_rt_vals[idx] = df.loc[df["participant"]==p,['itm1_RT','itm2_RT','itm3_RT']].apply(lambda x: x*1000).values.mean() # convert to ms before taking mean
        df.loc[df.participant==p,'demeaned_rt_1'] = df.loc[df.participant==p,'itm1_RT'].apply(lambda x: x*1000) - mean_rt_vals[idx]
        df.loc[df.participant==p,'demeaned_rt_2'] = df.loc[df.participant==p,'itm2_RT'].apply(lambda x: x*1000) - mean_rt_vals[idx]
        df.loc[df.participant==p,'demeaned_rt_3'] = df.loc[df.participant==p,'itm3_RT'].apply(lambda x: x*1000) - mean_rt_vals[idx]
        
        
    # Choose whether to look at demeaned (per participant) error or raw error
    
    if demeaned==1:
        err_array = df[['demeaned_error_1','demeaned_error_2','demeaned_error_3']].to_numpy()
        rt_array = df[['demeaned_rt_1','demeaned_rt_2','demeaned_rt_3']].to_numpy()
    else:
        err_array = df[['itm1_err','itm2_err','itm3_err']].to_numpy()
        rt_array = df[['itm1_RT','itm2_RT','itm3_RT']].to_numpy()

    # Indices of chosen and alternative elements
    ord = df[['prevChoice','prevBest','prevWorst']].to_numpy(dtype=np.int8)

    # Order error values by status (chosen, alt)
    ordered_err = np.take_along_axis(err_array, ord, axis=1)
    ordered_err[df["trial_number"]==1,:] = np.nan # No status on first trial
    err_df = pd.DataFrame(ordered_err, columns = ['netitem_err','prevBA_err','prevWA_err'])

    # Order rt values by status (chosen, alt)
    ordered_rt = np.take_along_axis(rt_array, ord, axis=1)
    ordered_rt[df["trial_number"]==1,:] = np.nan # No status on first trial
    rt_df = pd.DataFrame(ordered_rt, columns = ['netitem_rt','prevBA_rt','prevWA_rt'])

    df = pd.concat([df, err_df,rt_df], axis=1) 

    # Add contrast columns between net item and alternatives
    df['alts_err'] =  df[['prevBA_err','prevWA_err']].mean(axis=1).values
    df['errDiff_net_best'] =  df['prevBA_err'].values - df['netitem_err'].values
    df['errDiff_net_avg'] =  df[['prevBA_err','prevWA_err']].mean(axis=1) - df['netitem_err'].values

    df['alts_rt'] =  df[['prevBA_rt','prevWA_rt']].mean(axis=1).values
    df['rtDiff_net_best'] =  df['prevBA_rt'].values - df['netitem_rt'].values
    df['rtDiff_net_avg'] =  df[['prevBA_rt','prevWA_rt']].mean(axis=1) - df['netitem_rt'].values

    return df


## additional plotting/statistical functions

def convert_pvalue_to_asterisks(pvalue):
    if pvalue <= 0.0001:
        return "****"
    elif pvalue <= 0.001:
        return "***"
    elif pvalue <= 0.01:
        return "**"
    elif pvalue <= 0.05:
        return "*"
    return "ns"


def cohen_d_ind(group1, group2):
    diff = np.mean(group1)-np.mean(group2)
    sd_pooled = np.sqrt(((np.std(group1)**2) + (np.std(group2)**2)) / 2)
    d = diff / sd_pooled
    return d

def cohen_d_paired(m1, m2):
    diff = m1 - m2 
    d = np.mean(diff) / np.std(diff)
    return d


def barplot_annotate_brackets(num1, num2, data, center, height, yerr=None, dh=.05, barh=.05, fs=None, maxasterix=None):
    """ 
    Annotate barplot with p-values.

    :param num1: number of left bar to put bracket over
    :param num2: number of right bar to put bracket over
    :param data: string to write or number for generating asterixes
    :param center: centers of all bars (like plt.bar() input)
    :param height: heights of all bars (like plt.bar() input)
    :param yerr: yerrs of all bars (like plt.bar() input)
    :param dh: height offset over bar / bar + yerr in axes coordinates (0 to 1)
    :param barh: bar height in axes coordinates (0 to 1)
    :param fs: font size
    :param maxasterix: maximum number of asterixes to write (for very small p-values)
    """

    if type(data) is str:
        text = data
    else:
        # * is p < 0.05
        # ** is p < 0.005
        # *** is p < 0.0005
        # etc.
        text = ''
        p = .05

        while data < p:
            text += '*'
            p /= 10.

            if maxasterix and len(text) == maxasterix:
                break

        if len(text) == 0:
            text = 'n. s.'

    lx, ly = center[num1], height[num1]
    rx, ry = center[num2], height[num2]

    if yerr:
        ly += yerr[num1]
        ry += yerr[num2]

    ax_y0, ax_y1 = plt.gca().get_ylim()
    dh *= (ax_y1 - ax_y0)
    barh *= (ax_y1 - ax_y0)

    y = max(ly, ry) + dh

    barx = [lx, lx, rx, rx]
    bary = [y, y+barh, y+barh, y]
    mid = ((lx+rx)/2, y+barh)

    plt.plot(barx, bary, c='black')

    kwargs = dict(ha='center', va='bottom')#,fontsize=16)
    if fs is not None:
        kwargs['fontsize'] = fs

    plt.text(*mid, text, **kwargs)