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
    
    cfg_trn.nepi     = 3;  % number of episodes
    cfg_trn.ntrl     = 48; % number of trials
    cfg_trn.realntrl = 48; % the number of actual trials to be used
    
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
    cfg.epimin   = 6;  % default 8 minimum episode length
    cfg.epimax   = 24; % default 32  maximum episode length
    cfg.tau_fluc = 3;  % bandit fluctuation stability (=volatility) it is the same for testing and training
    cfg.nepi     = 4; % default 6
    cfg.ntrl     = 56;
    cfg.realntrl = 56;
    cfg.tau_samp = 1.5;
    cfg.anticorr = 0; % uncorrelated only
    
    %% Generate the TEST blocks
    % create the order of the test blocks for each subject:: based on the subject number : 1 = complete feedback , 0 = partial feedback
    f = mod(subj,2) == [1,0,1,0];
    nblck = length(f);
    
    expe(2).meanmaxperf = 0;  
    expe(2).meanchance  = 0;  
    expe(2).meanwsls    = 0;  
    
    
    for i = 1:4
        fprintf('GENERATING TEST BLOCK %d/4\n',i);
        
        % set condition for test block
        cfg.feedback = f(1,i)+1;
        
        while true
            blck = gen_blck_online(cfg);
            
            expe(i+2).cfg = cfg;
            expe(i+2).type = 'test';
            
            expe(i+2).vm(1,:) = blck.pp(1:cfg.realntrl);
            expe(i+2).vm(2,:) = blck.qq(1:cfg.realntrl);
            % store bandit samples
            expe(i+2).vs(1,:) = blck.ps(1:cfg.realntrl);
            expe(i+2).vs(2,:) = blck.qs(1:cfg.realntrl);
            
            % store bandit positions : left and right
            expe(i+2).pos = blck.pos;
            
            % check impact of 1st response
            s_vm = [ ...
                getfield(sim_model_ref(expe,i+2,1),'s_vm'), ...
                getfield(sim_model_ref(expe,i+2,2),'s_vm')];
            
            s_vm_chance = [ ...
                getfield(sim_model_ref(expe,i+2,1),'s_vm_chance'), ...
                getfield(sim_model_ref(expe,i+2,2),'s_vm_chance')];
            
            s_vm_wsls = [ ...
                getfield(sim_model_ref(expe,i+2,1),'s_vm_wsls'), ...
                getfield(sim_model_ref(expe,i+2,2),'s_vm_wsls')];
            
           check = [ ...
                getfield(sim_model_ref(expe,i+2,1),'check'), ...
                getfield(sim_model_ref(expe,i+2,2),'check')];
            
            % Compute the reward that could be won per block if always
            % choosing the most rewarding arm wih the learning rate 0.5: 
            
            if abs(diff(s_vm)/sum(s_vm)) < 0.05
                
                % Fill in the criterions for later evaluation of the
                % performance: 
                expe(i+2).maxperf   = mean(s_vm);        % average across 2 starting points: a relative reward that could be won  
                expe(i+2).chance    = mean(s_vm_chance); % average reward with the random performance 
                expe(i+2).wsls      = mean(s_vm_wsls);   % average reward with the WSLS performance 
                expe(i+2).check     = mean(check);
                break
            end
        end
        
        % Compute a running average performance characterisitcs across all main test blocks
        expe(i+2).meanmaxperf = expe(i+2).maxperf/4 + expe(i+1).meanmaxperf; 
        expe(i+2).meanchance  = expe(i+2).chance/4 + expe(i+1).meanchance; 
        expe(i+2).meanwsls    = expe(i+2).wsls/4 + expe(i+1).meanwsls; 

        fprintf('\n');
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

end