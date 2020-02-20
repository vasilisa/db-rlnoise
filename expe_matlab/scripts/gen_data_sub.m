% Script to generate subject sequences for RLVAR ONLINE VERSION 
% January 2020 by VS 

% STRUCTURE 
% Partial and Complete feedback 2 blocks each of 54 trials 
% 2 training sessions of 48 trials IDENTICAL TO ALL THE PARTICIPANTS 
% Volatility and Sampling noise are identical to the RLVARFMRI version
% UNCORRELATED BLOCKS ONLY 

%  =====================================================================

clear all 
clear java  
close all hidden
clc

% add toolboxes
addpath ./Toolboxes/Rand/
addpath ./Toolboxes/Stimuli/Visual/
addpath ./Toolboxes/IO/

% generate the training blocks IDENTICAL for all users
generate_train    = 0; % if 0 then load existing training sessions and fill them into subjects data before generating the real experiment

if generate_train == 1
    subj           = 0;
    sprintf('generating TRAINING data for all Subjects');
    gen_expe_subj(subj,generate_train);
    
elseif generate_train == 0
    sublst = 21:100; 
    
    tic
    for subj = sublst
        sprintf('generating data for Subject %d',subj);
        gen_expe_subj(subj,generate_train);
        
    end
    
    toc
end



