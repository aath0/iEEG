
% Import_Neuralynx.m Imports neuralynx files
%
% _______________________________________________________________________
% 
% (C) 2014-2016 A. Tzovara (UZH) https://github.com/aath0/iEEG

%% Initial parameters:

p.path = 'H:\Data\Intracranial\2016-03-04_15-11-49\'; % the forlder where the neuralynx data are
p.timeTarget='15:11:59'; % beginning of recording (roughly)
p.windowWidth = 3000; % in sec, desired interval to be read (from the whole iEEG recording

p.nChan = 8; %number of contacts per stripe
p.fs = 4000; % desired sampling frequency (data will be downsampled to this frequency, in Hz)

p.eventlength = 2500; % in ms, desired interval of single trials, after the trigger
p.baselinelength = 1000; % in ms, desired interval for baseline before the trigger
NBLOCKS = 30; %Number of blocks to be read per trial (used for memory pre-allocation)


%% Loop over stripes:
addpath(p.path)

%loop across all contacts:
load([p.path, 'm_list.mat']) %m_list.mat contains a list of all contacts to be imported

Fs = p.fs;
for cc = 1:size(contacts_list,1)
    
    
   load([p.path, 'm_list.mat'])
   
    p.nameChan = contacts_list{cc,1}
    
    p.filename=[p.nameChan, '1.ncs']; % name for the first file
    p.filenameevents='Events.nev';
   
    
    % Find timestamps range from timetarget
    % find main parameters of the recordings
    
    % read only first sample
    [Timestamps,SampleFrequencies, samples, Header] = Nlx2MatCSC( [p.path p.filename], [1 0 1 0 1], 1, 2, [1 2]);
    
    % ------------------------------------------------------------
    % Read variables in header
    HeadDateTimeOpen = textscan(Header{3}, '%*s %*s %*s %*s %s %*s %s');
    
    deltaR = diff(Timestamps(1:2)); % Delta between 2 timestamps (Time recordings) in microseconds
    SampleL = size(samples,1); % Number of samples between 2 timestamps
    deltaT = deltaR/SampleL; % in microseconds \mus -  in time between two consecutive samples
    FS = SampleFrequencies(1); %FS = 1/deltaT*1000000;
    
    datefopen = datenum(sprintf('%s %s', HeadDateTimeOpen{1,1}{1,1}, HeadDateTimeOpen{1,2}{1,1}));
    datetimeTarget=datenum(sprintf('%s %s', HeadDateTimeOpen{1,1}{1,1}, p.timeTarget));
    timeShift  = etime(datevec(datetimeTarget),datevec(datefopen)); % etime returns shift in seconds
    
    % shift from the start of recording to the desired timestart
    sampleshift = timeShift*1e6/deltaR; % in microseconds
    
    % find the sample0 for the p.timeTarget, sample1 for p.timeTarget+p.windowWidth
    sample0 = ceil(sampleshift); % going to the closest Integer to the right (positive direction)
    sample1 = floor(sampleshift + (p.windowWidth*1e6/deltaR)); % going to the closest Integer to the left (negative)
    
    [Timestamps]=Nlx2MatCSC( [p.path p.filename], [1 0 0 0 0], 0, 2, [sample0 sample1]);
    
    % the range in Timestamps between sample0 and sample1
    ts.timeStampsRange=[Timestamps(1) Timestamps(end)];
    ts.deltaTS = deltaR;
    clearvars -except p ts j d
    
   
    % Find timestamps for trigger events
    [TimeStamps, EventIDs, TTLs, Extras, EventStrings, Header] = Nlx2MatEV( [p.path p.filenameevents], [1 1 1 1 1], 1,1 );
   
    trigger=find(TTLs>0); % find all trigger points  -CHANGE CODE FOR THE TRIGGER
    
    
    ts.timestamps = TimeStamps(trigger); % find all timestamps associated with triggers
    ts.timestamps((ts.timestamps<ts.timeStampsRange(1)) | (ts.timestamps>ts.timeStampsRange(2)))=[]; % find trigger timestamps in the desired range
    
    % Loop for all contacts within a stripe:
    % extract all single trials with length = p.eventlength after the trigger
    % additionally, extract baseline for each single trial before the trigger
    tic
   
    
   
    
    for j=1:p.nChan
        % loop by channels
        p.filename=[p.nameChan, num2str(j),'.ncs'];
        
        
        % -------------------------------------------------------------------------
        % Read signals around trigger
        % read and save first timestamp, which defines the beginning of the recording
        [Timestamps] = Nlx2MatCSC( [p.path p.filename], [1 0 0 0 0], 0, 2, [1 2]);
        TS1 = Timestamps(1);
        
       
        for curTS = 1:length(ts.timestamps)-0
            % loop for all triggers
            
            Nrecord = floor((ts.timestamps(curTS)- TS1)/ts.deltaTS)+1; % number of the block we need
            
            % find the Record inside of which the ts.timestamps(curTS) is located
            [Timestamps, ValidSamples, Samples, Header]...
                = Nlx2MatCSC( [p.path p.filename], [1 0 0 1 1], 1, 2,...
                [Nrecord-NBLOCKS  Nrecord+NBLOCKS ]); % for baseline
            % read Records: Record(-1)-priory to the record having the ts.timestamps(curTS)
            % Record R(0)- Record inside of which the ts.timestamps(curTS) is located
            % Record(+1) - next Record
            
            HeadADBitVolts = Header{16} ;
            ADBitVoltscell = textscan(HeadADBitVolts, '%*s %n');
            ADBitVolts = ADBitVoltscell{1,1};
            
            Samples = Samples*ADBitVolts*1000000;
            
            
            if ValidSamples==512*ones(1,(1+2*NBLOCKS))
           
                % check if the length of extracted samples is = 512*3
                
                p.timestampsDelta(curTS) = ts.timestamps(curTS)-Timestamps(2);
                               
                % the shift of the trigger in the Record(0)
                s.samples(:,curTS)= Samples(:); %concatinate all bins of 512 data-points.
                
                % save samples around trigger , read according to the
                % shift p.timestampsDelta(curTS)
                % s.samples contains one single-trial.
                 
                sig.samplesTrigger(:,curTS) = s.samples(round(512*p.timestampsDelta(curTS)/ts.deltaTS) +512 ...
                    :round(512*p.timestampsDelta(curTS)/ts.deltaTS)+p.eventlength*p.fs/1000-1 + 512, curTS);
                
                % save baseline:
                sig.samplesBaseline(:,curTS)=s.samples(512+round(512*p.timestampsDelta(curTS)/ts.deltaTS)-p.baselinelength*p.fs/p.baselinelength...
                    :512+round(512*p.timestampsDelta(curTS)/ts.deltaTS)-(0)*p.fs/p.baselinelength-1 , curTS);
            end
            
        end
        % erase all samples with timestamps below zero
        % (wrong timestamps)
        eraseEv=find(p.timestampsDelta<=0);
        p.timestampsDelta(eraseEv)=[];
        sig.samplesTrigger(:,eraseEv)=[];
        
        clearvars -except p ts sig j d data NBLOCKS trigger TTLs
        
        clear Timestamps
       
        % Averaging
        % over contacts
        sig.samplesTriggerAverage = mean(sig.samplesTrigger,2);
        sig.samplesBaselineAverage = mean(sig.samplesBaseline,2);
        
        %% save all channels
        
        if j>1 % is used to combine all channels into a single structure
            d=[d, sig];
        else
            d=sig;
        end
        
        
    end
    
    %save data:
    save([p.path, '',p.nameChan,'.mat'])
end
