
function [] = ft_multiplot_time_intracr(iEEG1,iEEG3)

% ft_multiplot_time_intracr.m plots average iEEG for two conditions by stripe (7
% contacts each), for quality control.
%
% _______________________________________________________________________
% 
% (C) 2014-2016 A. Tzovara (UZH) https://github.com/aath0/iEEG

figure, hold on;
sub1 = 7;
nu_ch = length(iEEG1.label)
sub2 = round(nu_ch/sub1);


%baseline correction?


for kk = 1:size(iEEG1.trial,2)
    data_toplot1(:,kk,:) = iEEG1.trial{1,kk};
    
end
for kk = 1:size(iEEG3.trial,2)
    
    data_toplot3(:,kk,:) = iEEG3.trial{1,kk};
end
data1_mean = squeeze(mean(data_toplot1,2));
data3_mean = squeeze(mean(data_toplot3,2));

%apply stats mask:
tt = iEEG1.time{1,1};
for el = 1:nu_ch
    
    subplot(sub2,sub1,el)
    hold on,
    plot(tt,data1_mean(el,:),'b');
    plot(tt,data3_mean(el,:),'r')
    xlim([-0.5 1])
    
    title(iEEG1.label{el,1})
    
end