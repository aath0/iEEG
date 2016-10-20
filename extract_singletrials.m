 
% extract_singletrials.m Splits iEEG data to experimental conditions.
% Additionally, it does some basic pre-processing by
% calling fieldtrip functions.
%
% _______________________________________________________________________
% 
% (C) 2014-2016 A. Tzovara (UZH) https://github.com/aath0/iEEG


%Patient 105:
p.path='H:\Data\Intracranial\2016-03-04_15-11-49\';
code = '05';
s_id = '105';


%% Parameters for pre-processing: 
notch_f = [48 52]; %notch filter, implemented as bandstop, between 48 and 52 Hz.
band_f = [0.5 80]; %bandpass filter, in Hz
art_reject_latency = [-1 1]; % the window used for visual artifact rejection, in sec


%% Load data:
load([p.path,'triggers_', code,'_S',s_id,'.mat'])
load([p.path, 'ft_data_', code, '_S', s_id,'_ftFromat'])
load([p.path, 'ft_data_', code, '_S', s_id])


%% Split data to conditions:
iEEG_all = iEEG_all_to;
%split trials to conditions :
l1 = find(tri == 1);
l3 = find(tri == 3);

%split iEEG in two conditions:
iEEG1 = iEEG;
iEEG3 = iEEG;

iEEG1.hdr.nTrials = length(l1);
iEEG3.hdr.nTrials = length(l3);
iEEG1.sampleinfo = iEEG.sampleinfo(l1,:);
iEEG3.sampleinfo = iEEG.sampleinfo(l3,:);

iEEG1.time = [];
iEEG1.trial = [];
iEEG1.trialinfo = [];
for kk = 1:length(l1)
    
    iEEG1.time{1,kk} = iEEG.time{l1(kk)};
    iEEG1.trial{1,kk} = squeeze(iEEG_all(:,l1(kk),:))';
    iEEG1.trialinfo(kk) = 1; %this is the trigger code for condition 1
end

iEEG3.time = [];
iEEG3.trial = [];
iEEG3.trialinfo = [];
for kk = 1:length(l3)
    
    iEEG3.time{1,kk} = time_v;
    iEEG3.trial{1,kk} = squeeze(iEEG_all(:,l3(kk),:))';
    iEEG3.trialinfo(kk) = 3; %this is the trigger code for condition 3
end

save([p.path, 'ft_data_', code, '_S', s_id,'_ftFromat_l1_l3'], 'iEEG1','iEEG3')


%% Preprocess: 

% filters:
ft_defaults % initialise fieldtrip

cfg = [];
cfg.bsfreq = notch_f;
cfg.bsfilter = 'yes';
iEEG1 = ft_preprocessing(cfg,iEEG1)

cfg = [];
cfg.bsfreq = notch_f;
cfg.bsfilter = 'yes';
iEEG3 = ft_preprocessing(cfg,iEEG3)

cfg = [];
cfg.bpfreq = band_f;
cfg.bpfilter = 'yes';
cfg.detrend = 'yes';
iEEG1 = ft_preprocessing(cfg,iEEG1)

cfg = [];
cfg.bpfreq = band_f;
cfg.bpfilter = 'yes';
cfg.detrend = 'yes';
iEEG3 = ft_preprocessing(cfg,iEEG3)


%% Visual artifact rejection:
cfg = [];
cfg.method   = 'trial';
cfg.alim     = 300; 
cfg.latency = art_reject_latency;
iEEG1       = ft_rejectvisual(cfg,iEEG1);

cfg = [];
cfg.method   = 'trial';
cfg.alim     = 300; 
cfg.latency = art_reject_latency;
iEEG3       = ft_rejectvisual(cfg,iEEG3);


%% Baseline-correction 
cfg.demean          = 'yes';
cfg.baselinewindow  = [-1 0]; %in sec

iEEG1 = ft_preprocessing(cfg, iEEG1);
iEEG3 = ft_preprocessing(cfg, iEEG3);

save([p.path, 'ft_data_', code, '_S', s_id,'_ftFromat_l1_l3_clean'], 'iEEG1','iEEG3')

ft_multiplot_time_intracr(iEEG1,iEEG3)
