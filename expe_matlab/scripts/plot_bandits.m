clear all; close all; clear Java;
for subj = 1000; % :10

    if subj == 1000
        load('../Data/RLVARONLINE_training_expe.mat');
    elseif subj < 10
        load(sprintf('../Data/RLVARONLINE_S0%d_expe.mat',subj));
    else
        load(sprintf('../Data/RLVARONLINE_S%d_expe.mat',subj));
    end


f = figure('Name',sprintf('subject %d',subj),'Color','white');

hold on

count_f = 0;
if subj == 1000
    blcks = [1:2]; 
else
    blcks = [3:6]; 
end

for i_block = blcks
    
    count_f = count_f + 1;
    subplot(2,2,count_f);
    
    if expe(i_block).cfg.feedback  == 1
        
        plot(expe(i_block).vm(1,:),'r','LineWidth',1); hold on;
        plot(expe(i_block).vm(2,:),'b','LineWidth',1);
        
        plot(expe(i_block).vs(1,:),'r--'); hold on;
        plot(expe(i_block).vs(2,:),'b--');
        xlabel('trials');
        ylabel('rewards');
        ylim([0 100]);
        xlim([0 length(expe(i_block).vm(1,:))]);
        title(sprintf('Partial block %d, sampling noise %0.2f',i_block-2,expe(i_block).cfg.tau_samp));
        drawnow;
        
    elseif expe(i_block).cfg.feedback  == 2
        
        plot(expe(i_block).vm(1,:),'r','LineWidth',1); hold on;
        plot(expe(i_block).vm(2,:),'b','LineWidth',1);
        
        plot(expe(i_block).vs(1,:),'r--'); hold on;
        plot(expe(i_block).vs(2,:),'b--');
        xlabel('trials');
        ylabel('rewards');
        ylim([0 100]);
        xlim([0 length(expe(i_block).vm(1,:))]);
        title(sprintf('Complete block %d, sampling noise %0.2f',i_block-2,expe(i_block).cfg.tau_samp));
        drawnow;
        
    end
end

% if subj < 10
%     filenamefig = sprintf('../Data_tausamp_2_truncated/bandits_%0.1f_subject%d.png',expe(i_block).cfg.tau_samp,subj);
% else
%     filenamefig = sprintf('../Data_tausamp_2_truncated/bandits_%0.1f_subject%d.png',expe(i_block).cfg.tau_samp,subj);
% end

saveas(f,filenamefig)
close all
end


