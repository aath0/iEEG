

% Correct_Neuralynx_Triggers.m corrects the neuralynx triggers according to
% a ground truth trigger file (coming for example from cogent or psychotoolbox)
%
% _______________________________________________________________________
% 
% (C) 2014-2016 A. Tzovara (UZH) https://github.com/aath0/iEEG


%% Load files:

p.path='D:\Data\Intracranial\2015-01-16_16-56-44\';
s_id = '101';


load([p.path, 'm_list'])
load([p.path, 'triggers_', code, '_S', s_id]) %a file containing the ground truth triggers (tri)
cc = 1; %load a random contact file (they all contain the neuralynx data, TTLs)
nameChan = contacts_list{cc,:};
load([p.path, ,nameChan,'.mat'])
clear sig

%% Find which epochs to keep - because we have some dummy triggers:
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

%tr2keep contains 1 if the trigger is real and corresponds to an
%experimental trigger. we keep this info for re-loading the data and making
%a correspondence with TimeStamps.
save([p.path, 'triggers_Token_correction.mat'],'tr2keep')
