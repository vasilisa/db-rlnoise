function [expe] = gen_expe_online(subj,generate_train)
%  GEN_EXPE  Generate experiment structure
% Modified from the original by VS January 2020 for the ONLINE RLVAR experiment

% ========================================================

%  Usage: [expe] = GEN_EXPE(subj)
%
%  where subj is the subject number and generate_train is a boolean
%  indicating whether the training data are generated or the main testing
%  sessions.

%        expe is the generated experiment structure
%
%  The experiment structure expe contains the following fields:
%    * cfg   - configuration structure
%    * type  - block type ('training' or 'test')
%    * vm    - bandit means, 2 by-n(trials) array
%    * vs    - bandit samples, 2 or 4-by-n(trials) array
%    * shape - bandit shapes, 2 or 4 -by-1 array
%    * color - bandit colors, 2 or 4 -by-1 array
%    * act -   1: if the choice trial and 0 if forced choice trial
%    * obsrsp - for the observational trials only: wheather it will repeat the subjects previous choice or make a switch to the alternative (1/2 of the observational trials) randomizied
%             1 = repeat, 2 = switch and 0 for the choice trials
%
%  The configuration structure cfg contains the three experimental factors:
%    * tau_samp - bandit sampling stability: same across all blocks set to 1.5
%    * anticorr - bandit anti-correlation? (FALSE for all blocks)
%    * feedback - bandit feedback (1: PARTIAL 2:COMPLETE chosen+unchosen COMPLETE FOR 1/2 BLOCKS)
%    * COMPLETE block is repeated TWICE the same, so there is only 1
%    complete feedback block generated.

% All subjects start with the complete feedback training session. The order of the main sessions is randomizied as a function of subject number:
% Odd subjects start with the complete feedback and the even - with the partial feedback block

%  The experiment contains 2 training blocks, followed by 4 test blocks.

%  Each training block contains 48 trials, each test block 56 trials. 96 trials are generated and then the sequence is cut

% Shapes and colors are changed across blocks.

% Timing is the same for training and fMRI sessions

% check input arguments
if nargin < 1
    error('Missing subject number!');
elseif nargin < 2
    generate_train = 0; % false
end

% add toolboxes to path
addpath('./Toolboxes/Rand');

% initialize random number generator
RandStream.setGlobalStream(RandStream('mt19937ar','Seed','shuffle'));

fprintf('\n');
if generate_train == 1
    fprintf('GENERATING TRAINING DATA\n');
    fprintf('\n');
    
    expe = [];
    
    % set bandit fluctuation parameters
    % defaults: epimin = 8, epimax = 32, tau_fluc = 3
    % this produces exponentially-distributed episodes of 16 trials on average
    cfg_trn          = [];
    cfg_trn.epimin   = 6;  % default 8 minimum episode length
    cfg_trn.epimax   = 24; % default 32  maximum episode length
    cfg_trn.tau_fluc = 3;  % bandit fluctuation stability (=volatility) it is the same for testing and training
    
    cfg_trn.nepi     = 3;    % number of episodes
    cfg_trn.ntrl     = 96; % number of trials
    cfg_trn.realntrl = 48;   % the number of actual trials to be used
    
    cfg_trn.tau_samp = 3;  % bandit sampling stability: easier for the training blocks
    cfg_trn.anticorr = 0;  % uncorrelated blocks only
    
    % generate training blocks
    feedbck_trn  = [1,2]; %% partial always comes first for TRAINING
    
    for i = 1:2
        fprintf('GENERATING TRAINING BLOCK %d/2\n',i);
        % set condition for training block
        cfg_trn.feedback = feedbck_trn(i);
        
        % generate training block with lower generation precision
        blck = gen_blck_online(setfield(cfg_trn,'pgen',0.05));
        
        % store configuration parameters
        expe(i).cfg  = cfg_trn;
        expe(i).type = 'training';
        
        % store bandit means: theoretical values
        expe(i).vm(1,:) = blck.pp;
        expe(i).vm(2,:) = blck.qq;
        % store bandit samples
        expe(i).vs(1,:) = blck.ps;
        expe(i).vs(2,:) = blck.qs;
        
        % store bandit positions
        expe(i).pos = blck.pos; % a 1x ntrl vector for 2 bandit condition: 1 = first bandit on the left side
        
        fprintf('\n');
    end
else
    
    fprintf('GENERATING MAIN DATA\n');
    fprintf('\n');
    
    fprintf('LOADING THE TRAINING DATA FIRST\n');
    load('../Data/RLVARONLINE_training_expe.mat');
    
    
    % set bandit fluctuation parameters
    % defaults: epimin = 8, epimax = 32, tau_fluc = 3
    % this produces exponentially-distributed episodes of 16 trials on average
    cfg          = [];
    cfg.epimin   = 8;  % default 8 minimum episode length
    cfg.epimax   = 18; % default 32  maximum episode length
    cfg.tau_fluc = 3;  % bandit fluctuation stability (=volatility) it is the same for testing and training
    cfg.nepi     = 8; % default 6
    cfg.realntrl = 56;
    cfg.ntrl     = 96;  % number of trials generated
    cfg.tau_samp = 2.0; % original in fMRI study 1.5
    cfg.anticorr = 0; % uncorrelated only
    cfg.pgen     = 0.005; % the default 
    
    %% Generate the TEST blocks
    % create the order of the test blocks for each subject:: based on the subject number : 1 = complete feedback , 0 = partial feedback
    f = mod(subj,2) == [1,0,1,0];
    nblck = length(f);
    
    nb_train                   = 2;
    expe(nb_train).meanmaxperf = 0;
    expe(nb_train).meanchance  = 0;
    expe(nb_train).meanwsls    = 0;
    
    
    for i = 1:4 % 2 partial feedback and 1 complete feedback blocks
        fprintf('GENERATING TEST BLOCK %d/4\n',i);
        
        % set condition for test block
        cfg.feedback = f(1,i)+1;
        
        % Check if the block already exists
        if f(1,i) == 1 && i > 2 % complete feedback and not the first complete block
            if f(1) == 1
                orig_complete = 1+nb_train; % either the 3d one
            else
                orig_complete = 2+nb_train; % or the 4th block
            end
            fprintf('Replicating the complete feedback block %d\n',orig_complete-nb_train);
            % repeat the sequence:
            expe(i+nb_train).cfg = expe(orig_complete).cfg;
            expe(i+nb_train).vm  = expe(orig_complete).vm;
            expe(i+nb_train).vs  = expe(orig_complete).vs;
            expe(i+nb_train).type = 'test';
            
            % performance:
            expe(i+nb_train).maxperf   = expe(orig_complete).maxperf;
            expe(i+nb_train).chance    = expe(orig_complete).chance;
            expe(i+nb_train).wsls      = expe(orig_complete).wsls;   % average reward with the WSLS performance
            expe(i+nb_train).check     = expe(orig_complete).check;
            
            expe(i+nb_train).meanmaxperf = expe(orig_complete).meanmaxperf;
            expe(i+nb_train).meanchance  = expe(orig_complete).meanchance;
            expe(i+nb_train).meanwsls    = expe(orig_complete).meanwsls;
            
            % generate a new sequence of positions to make the blocks less
            % similar:
            tic
            % generate bandit positions
            fprintf('generating bandit positions...\n');
            vm  = expe(orig_complete).vm; 
            vs  = expe(orig_complete).vs; 
            pos = [];
            
            pos_sub = kron([1,2],ones(1,8));
            nsub = ceil(cfg.realntrl/16);
            for isub = 1:nsub
                while true
                    pos_tmp = [pos,pos_sub(randperm(16))];
                    ntmp = min(numel(pos_tmp),cfg.realntrl);
                    i1 = sub2ind(size(vm),pos_tmp(1:ntmp),1:ntmp); % look-up indices for left bandit
                    i2 = sub2ind(size(vm),3-pos_tmp(1:ntmp),1:ntmp); % look-up indices for right bandit
                    if ...
                            ~HasConsecutiveValues(pos_tmp,4) % bandit positions
                        break
                    end
                end
                pos = pos_tmp;
            end
            toc
            expe(i+nb_train).pos = pos(1:cfg.realntrl);
            
        else
            fprintf('GENERATING TEST BLOCK %d/4\n',i);
            
            while true
                blck = gen_blck_online(cfg);
                
                expe(i+nb_train).cfg = cfg;
                expe(i+nb_train).type = 'test';
                
                expe(i+nb_train).vm(1,:) = blck.pp(1:cfg.realntrl);
                expe(i+nb_train).vm(2,:) = blck.qq(1:cfg.realntrl);
                % store bandit samples
                expe(i+nb_train).vs(1,:) = blck.ps(1:cfg.realntrl);
                expe(i+nb_train).vs(2,:) = blck.qs(1:cfg.realntrl);
                
                % store bandit positions : left and right
                expe(i+nb_train).pos = blck.pos;
                
                % check impact of 1st response
                s_vm = [ ...
                    getfield(sim_model_ref(expe,i+nb_train,1),'s_vm'), ...
                    getfield(sim_model_ref(expe,i+nb_train,2),'s_vm')];
                
                s_vm_chance = [ ...
                    getfield(sim_model_ref(expe,i+nb_train,1),'s_vm_chance'), ...
                    getfield(sim_model_ref(expe,i+nb_train,2),'s_vm_chance')];
                
                s_vm_wsls = [ ...
                    getfield(sim_model_ref(expe,i+nb_train,1),'s_vm_wsls'), ...
                    getfield(sim_model_ref(expe,i+nb_train,2),'s_vm_wsls')];
                
                check = [ ...
                    getfield(sim_model_ref(expe,i+nb_train,1),'check'), ...
                    getfield(sim_model_ref(expe,i+nb_train,2),'check')];
                
                % Compute the reward that could be won per block if always
                % choosing the most rewarding arm wih the learning rate 0.5:
                
                if abs(diff(s_vm)/sum(s_vm)) < 0.05
                    
                    % Fill in the criterions for later evaluation of the
                    % performance:
                    expe(i+nb_train).maxperf   = mean(s_vm);        % average across 2 starting points: a relative reward that could be won
                    expe(i+nb_train).chance    = mean(s_vm_chance); % average reward with the random performance
                    expe(i+nb_train).wsls      = mean(s_vm_wsls);   % average reward with the WSLS performance
                    expe(i+nb_train).check     = mean(check);
                    break
                end
            end % while
            
            % Compute a running average performance characterisitcs across all main test blocks
            expe(i+nb_train).meanmaxperf = expe(i+nb_train).maxperf/4 + expe(i+nb_train-1).meanmaxperf;
            expe(i+nb_train).meanchance  = expe(i+nb_train).chance/4  + expe(i+nb_train-1).meanchance;
            expe(i+nb_train).meanwsls    = expe(i+nb_train).wsls/4    + expe(i+nb_train-1).meanwsls;
            
            fprintf('\n');
            
        end % feedback repetition loop
        
    end % block loop
    
    
end % generate_train

%% Generate pairs of shape/color combinations for the TEST ONLY, for the training they are identical for all users
% shape = 0:circle, 1:diamond, 2:star,  3:plus
% color = 0:blue,   1:orange,  2:green, 3:red
if generate_train == 0
    % for 10 blocks total generate 6 diff shape/color per block
    fprintf('GENERATING PAIRS OF SHAPE-COLOR COMBINATIONS\n');
    
    shape_lst = kron(1:4,ones(1,4)); % sequence of 4 for each digit 0 to 3 total 16
    color_lst = repmat(1:4,[1,4]);
    
    for i = 3:nblck+2
        
        while true
            nnn = randperm(16);
            expe(i).shape = shape_lst(nnn(1:2));
            expe(i).color = color_lst(nnn(1:2));
            
            if ...
                    max(hist(expe(i).shape,unique(expe(i).shape))) <= 1 && ...
                    max(hist(expe(i).color,unique(expe(i).color))) <= 1
                break
            end
        end
        
        expe(i).shape = expe(i).shape(:)-1;
        expe(i).color = expe(i).color(:)-1;
    end
    
else
    for i = 1:2
        expe(i).shape = NaN;
        expe(i).color = NaN;
    end
    
    
    fprintf('\n');
    
    
    %% Plot the four bandits: observed and theoretical rewards
    
    
    
end