

% Stats_TimeLocked.m compares statistically two experimental conditions,
% across trials, based on fieldtrip.
%
% _______________________________________________________________________
% 
% (C) 2014-2016 A. Tzovara (UZH) https://github.com/aath0/iEEG


%% Patient 105:
p.path='H:\Data\Intracranial\2016-03-04_15-11-49\';
code = '05';
s_id = '105';

load([p.path, 'ft_data_', code, '_S', s_id,'_ftFromat_l1_l3_clean'])


%% Compute mean data - and keep single-trials (useful for statistics):

cfg = [];
cfg.keeptrials = 'yes';
iEEG_TimeLock_1 = ft_timelockanalysis(cfg, iEEG1); 
iEEG_TimeLock_3 = ft_timelockanalysis(cfg, iEEG3);

%% Statistics:

%time-window where we want to compute the statistics (sec):
t_window = [-0.1 0.5];
%Define the design matrix:
design = [ones(1,size(iEEG_TimeLock_1.trial,1)) 2*ones(1,size(iEEG_TimeLock_3.trial,1))]; 

cfg = [];
cfg.channel     = 'all'; %now all channels
cfg.latency     = t_window;
cfg.avgovertime = 'no';
cfg.method      = 'analytic';
cfg.statistic   = 'ft_statfun_indepsamplesT';
cfg.alpha       = 0.05;
cfg.correctm    = 'fdr'; %correction for multiple comparisons ( 'no', 'max', cluster', 'bonferroni', 'holm', 'hochberg', 'fdr' )
cfg.design      = design;
cfg.ivar        = 1;
 
stat = ft_timelockstatistics(cfg,iEEG_TimeLock_1,iEEG_TimeLock_3);

figure, imagesc(stat.mask) % plot the statistical mask to get an overview of statistical effects.
%(stat.mask is already corrected, according to cfg.correctm)
