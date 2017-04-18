p_id = 'M';

filep_g = 'D:\Data\old_studies\Intracranial_GMMN\'
filep = [filep_g, p_id, '\models\'];

bb = 1;
%load fieldtrip data:
load([filep,'iEEG_bip_block', num2str(bb),'_f.mat'])

%total number of contacts
nchan = length(iEEGf.label);
strip_length = 7; % contacts per stripe (after bipolar ref, if appropriate)

connectivity = zeros(nchan,nchan);

for ch = 1:nchan
    
    neighbours(ch).label = iEEGf.label{ch};
    
    if mod(ch,strip_length) == 0 %end of stripe
        neighbours(ch).neighblabel = {iEEGf.label(ch-1) iEEGf.label(ch-2)};
        connectivity(ch,[ch-1 ch-1]) = 1;
        
    else if mod(ch,strip_length) == 1 %beginning for stripe
            neighbours(ch).neighblabel = {iEEGf.label(ch+1) iEEGf.label(ch+2)};
            connectivity(ch,[ch+1 ch+2]) = 1;
            
        else %all the other cases:
            if mod(ch,strip_length) == 2
                
                neighbours(ch).neighblabel = {iEEGf.label(ch-1) iEEGf.label(ch+1) iEEGf.label(ch+2)};
                connectivity(ch,[ch-1]) = 1;
                connectivity(ch,[ch+2 ch+1]) = 1;
                
            else
                if mod(ch,strip_length) == 6
                    
                    neighbours(ch).neighblabel = { iEEGf.label(ch-2) iEEGf.label(ch-1) iEEGf.label(ch+1)};
                    connectivity(ch,[ch+1]) = 1;
                    connectivity(ch,[ch-2 ch-1]) = 1;
                    
                else
                    neighbours(ch).neighblabel = {iEEGf.label(ch-1) iEEGf.label(ch-2) iEEGf.label(ch+1) iEEGf.label(ch+2)};
                    connectivity(ch,[ch-2 ch-1]) = 1;
                    connectivity(ch,[ch+2 ch+1]) = 1;
                end
            end
        end
    end
end

save([filep,'channels_connectivity.mat'],'neighbours','connectivity')




