function [out] = sim_model_ref(expe,iblck,resp0)
%  SIM_MODEL_REF  Simulate reference model on block of interest
%
%  Usage: [out] = SIM_MODEL_REF(expe,iblck,resp0)
%
%  where expe is an existing experiment structure
%        iblck is the index of the block of interest
%        resp0 is the first response
%        out is the output structure
%
%  The output structure out contains the following fields:
%    * blck        - block of interest
%    * alpha       - learning rate
%    * qval        - trial-wise Q-value
%    * resp        - trial-wise response
%    * s_vs        - average sample-wise score
%    * s_vm        - average mean-wise score
%    * s_vm_chance - average mean-wise scroe for the random choices 
%
%  Valentin Wyart <valentin.wyart@ens.fr> - Jan. 2016

% check input arguments
if nargin < 3
    resp0 = 1;
end
if nargin < 2
    error('Missing input arguments!');
end

alpha = 0.5; % learning rate for reference model (default: 0.5)

% extract block of interest
blck = expe(iblck);
ntrl = size(blck.vm,2);

% trial-wise scores
s_vs = zeros(1,ntrl); % sample-wise score
s_vm = zeros(1,ntrl); % mean-wise score
check = 0; 

% model-predicted variables
qval = zeros(1,ntrl); % trial-wise Q-value
resp = zeros(1,ntrl); % trial-wise response

% first trial
qval(1) = 50;
resp(1) = resp0; % first response

% subsequent trials
for itrl = 2:ntrl
    r = resp(itrl-1);
    % compute score from previous trial
    s_vs(itrl-1) = blck.vs(r,itrl-1)-blck.vs(3-r,itrl-1);
    s_vm(itrl-1) = blck.vm(r,itrl-1)-blck.vm(3-r,itrl-1);
    check = check + (blck.vm(r,itrl-1)-blck.vm(3-r,itrl-1))/56

    % update Q-value
    if blck.cfg.feedback == 1
        qval(itrl) = qval(itrl-1)+alpha*((3-r*2)*(blck.vs(r,itrl-1)*2-100)-qval(itrl-1));
    else
        qval(itrl) = qval(itrl-1)+alpha*(blck.vs(1,itrl-1)-blck.vs(2,itrl-1)-qval(itrl-1));
    end
    % compute response
    resp(itrl) = 1+(qval(itrl) < 0);
end
% last trial
r = resp(end);
s_vs(end) = blck.vs(r,end)-blck.vs(3-r,end);
s_vm(end) = blck.vm(r,end)-blck.vm(3-r,end);
check     = check + (blck.vm(r,end)-blck.vm(3-r,end))/56; 
% Compute the random performance:
% trial-wise scores
s_vs_chance = zeros(1,ntrl); % sample-wise score
s_vm_chance = zeros(1,ntrl); % mean-wise score

% model-predicted variables
qval_chance = zeros(1,ntrl); % trial-wise Q-value
resp_chance = zeros(1,ntrl); % trial-wise response

% first trial
qval_chance(1) = 50;
resp_chance(1) = resp0; % first response

for itrl = 2:ntrl
    r = resp_chance(itrl-1);
    % compute score from previous trial
    s_vs_chance(itrl-1) = blck.vs(r,itrl-1)-blck.vs(3-r,itrl-1);
    s_vm_chance(itrl-1) = blck.vm(r,itrl-1)-blck.vm(3-r,itrl-1);
    
    % update Q-value
    if blck.cfg.feedback == 1
        qval_chance(itrl) = qval_chance(itrl-1)+alpha*((3-r*2)*(blck.vs(r,itrl-1)*2-100)-qval_chance(itrl-1));
    else
        qval_chance(itrl) = qval_chance(itrl-1)+alpha*(blck.vs(1,itrl-1)-blck.vs(2,itrl-1)-qval_chance(itrl-1));
    end
    % compute response
    resp_chance(itrl) = randi([1,2],1); 
end


% Compute the performance for WSLS - alpha = 1
alpha_wsls = 1.0; 

% trial-wise scores
s_vs_wsls = zeros(1,ntrl); % sample-wise score
s_vm_wsls = zeros(1,ntrl); % mean-wise score

% model-predicted variables
qval_wsls = zeros(1,ntrl); % trial-wise Q-value
resp_wsls = zeros(1,ntrl); % trial-wise response

% first trial
qval_wsls(1) = 50;
resp_wsls(1) = resp0; % first response

% subsequent trials
for itrl = 2:ntrl
    r = resp_wsls(itrl-1);
    % compute score from previous trial
    s_vs_wsls(itrl-1) = blck.vs(r,itrl-1)-blck.vs(3-r,itrl-1);
    s_vm_wsls(itrl-1) = blck.vm(r,itrl-1)-blck.vm(3-r,itrl-1);
    % update Q-value
    if blck.cfg.feedback == 1
        qval_wsls(itrl) = qval_wsls(itrl-1)+alpha_wsls*((3-r*2)*(blck.vs(r,itrl-1)*2-100)-qval_wsls(itrl-1));
    else
        qval_wsls(itrl) = qval_wsls(itrl-1)+alpha_wsls*(blck.vs(1,itrl-1)-blck.vs(2,itrl-1)-qval_wsls(itrl-1));
    end
    % compute response
    resp_wsls(itrl) = 1+(qval_wsls(itrl) < 0);
end
% last trial
r = resp_wsls(end);
s_vs_wsls(end) = blck.vs(r,end)-blck.vs(3-r,end);
s_vm_wsls(end) = blck.vm(r,end)-blck.vm(3-r,end);


% create output structure
out       = [];
out.blck  = blck; % block of interest
out.alpha = alpha; % learning rate
out.qval  = qval; % trial-wise Q-value
out.resp  = resp; % trial-wise response
out.s_vs  = mean(s_vs); % average sample-wise score
out.s_vm  = mean(s_vm); % average mean-wise score
out.check = check; 

out.s_vs_chance = mean(s_vs_chance); % average sample-wise score
out.s_vm_chance = mean(s_vm_chance); % average mean-wise score
out.s_vs_wsls   = mean(s_vs_wsls); % average sample-wise score
out.s_vm_wsls   = mean(s_vm_wsls); % average mean-wise score


end