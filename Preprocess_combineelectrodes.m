

% Preprocess_combineelectrodes.m combines single iEEG files to make them
% fieldtrip compatible. 
%
% _______________________________________________________________________
% 
% (C) 2014-2016 A. Tzovara (UZH)https://github.com/aath0/iEEG


%% Initial parameters:
p.path='D:\Data\Intracranial\2015-03-05_10-07-32\';
code = '05';
s_id = '103';


downs = 4; % down-sampling (if desired, or set to 1 for no downsampling)
bip = 1; % compute bipolar reference (recommended)
nSamples = 2500; %number of time-points in the post-stimulus interval (after downsampling)
nSamplesPre = 1000; %number of time-points in the baseline (after downsampling)

%% Load data:
load([p.path, 'm_list'])
load([p.path, 'Behavior\AAA_', code, '_MEG_Sno_', s_id,'.mat']) %behavioral file, contains the real triggers

labels_all = [];
iEEG_all = [];
%combine data from all contact files:
for cc = 1:size(contacts_list,1)
   
    load([p.path, 'Data\triggers_', code, '_S', s_id])
    nameChan = contacts_list{cc,:};
    load([p.path, 'Data\',nameChan,'.mat'])
    
    n_chan = size(d,2);
    
    %combine pre- with post- intervals:
    epoch = size(d(1,1).samplesTrigger,1); %epoch length in time-frames
    basel = size(d(1,1).samplesBaseline,1); %baseline length in time-frames
    n_epochs = size(d(1,1).samplesBaseline,2); %number of epochs
    signal = zeros(epoch+basel, n_epochs, n_chan);
    for i = 1:n_chan
        signal(:,:,i) = [d(1,i).samplesBaseline; d(1,i).samplesTrigger];
    end
    
    %Find which epochs to keep - because we have some dummy triggers:
    tri_rec= TTLs(find(TTLs>0)); %these are the triggers that neuralynx has recorded - excluding zeros
    tri_real = tri; %these are the triggers that we sent through cogent.
    
    
    tr2exclude = find(tri_rec== 24); %trigger 25 corresponds to the end of the trial, 24 to the beginning of a block
    tri_rec(tr2exclude) = [];
    
    tr2keep = zeros(1,size(tri_rec,2));
    tr2keep2 = tr2keep;
    j = 1; %index for tri_real
    for i = 1:length(tri_rec)
        
        if tri_rec(i) == tri_real(j)
            tr2keep(i) = 1;
            tr2keep2(i) = j;
            j = j+1;
        end
        
    end
    
    signal(:,find(tr2keep == 0),:) = [];
    
    %create iEEG structure:
    
    %check if we need bipolar reference:
    if bip
        iEEGb = zeros(size(signal,1)/downs,size(signal,2),size(signal,3)-1);
        
        for kk = 1:size(signal,3)-1
            
            %down-sample + compute bipolar reference:
            iEEGb(:,:,kk) = downsample(signal(:,:,kk),downs)-downsample(signal(:,:,kk+1),downs);
            channel_label{kk} = [nameChan, num2str(kk), ' - ', nameChan, num2str(kk+1)];
        end
        
    else
        
        iEEGb = zeros(size(signal,1)/downs,size(signal,2),size(signal,3));
        
        for kk = 1:size(signal,3)
            
            %just down-sample:
            iEEGb(:,:,kk) = downsample(signal(:,:,kk),downs);
            channel_label{kk} = [nameChan, num2str(kk)];
        end
       
    end
    

    
    iEEG_all = cat(3,iEEG_all,iEEGb);
    labels_all = cat(1,labels_all,channel_label')
    clear iEEGb n_chan n_epochs basel NBLOCKS sig signal trigger tri_rec tri_real ts TTLs tr2keep tr2exclude d
end

%iEEG_all contains all contacts:
save([p.path, 'ft_data_', code, '_S', s_id],'iEEG_all','labels_all','tri')

%% now prepare fieldtrip format:

%header info:
iEEG.hdr.Fs = Fs;
iEEG.hdr.nChans = size(iEEG_all,3);
iEEG.hdr.nSamples = nSamples;
iEEG.hdr.nSamplesPre = nSamplesPre;
iEEG.hdr.nTrials = size(iEEG_all,2);
iEEG.hdr.label = labels_all
iEEG.hdr.orig = [];
iEEG.hdr.grad = [];

iEEG.label = labels_all;

base = -nSamplesPre/Fs;
epoch = nSamples/Fs;
time_v = [base:1/Fs:epoch]; % time-vector (used for plots etc)
time_v(end) = [];

%initialisation:
kk = 1;
iEEG.time{1,kk} = time_v; %fieldtrip requires the time-vector to be saved for each trial
iEEG.trial{1,kk} = squeeze(iEEG_all(:,kk,:))';
iEEG.sampleinfo(kk,:) = [0 length(time_v)];

for kk = 2:size(iEEG_all,2)
    
    iEEG.time{1,kk} = time_v; %fieldtrip requires the time-vector to be saved for each trial
    iEEG.trial{1,kk} = squeeze(iEEG_all(:,kk,:))';
    iEEG.sampleinfo(kk,:) = iEEG.sampleinfo(kk-1,:) + [0 length(time_v)];
end

iEEG.fsample = Fs;
iEEG.trialinfo = tri';
iEEG.grad = [];
iEEG.cfg = [];

save([p.path, 'ft_data_', code, '_S', s_id,'_ftFromat'], 'iEEG')

