function [blck] = gen_blck_online(cfg)

% GEN_BLCK  Generate block structure
% Modified for RLVAR ONLINE version
% January 2020 by VS 
% =====================================================================
%
%  Usage: [blck] = GEN_BLCK(cfg)
%
%  where cfg is a configuration structure
%        blck is the generated block structure
%
%  The configuration structure cfg contains the following fields:
%    * epimin   - minimum episode length
%    * epimax   - maximum episode length
%    * nepi     - number of episodes
%    * ntrl     - number of trials (optional)
%    * ngen     - number of episodes to choose from (optional)
%    * pgen     - generation precision (optional)
%    * tau_fluc - bandit fluctuation stability
%    * tau_samp - bandit sampling stability
%    * anticorr - bandit anti-correlation? (true or false)
%    * feedback - feedback type (1:partial or 2:complete)
%    * fscal    - scaling factor (optional)

%  Original:: Valentin Wyart <valentin.wyart@ens.fr> - Jan. 2016

% check configuration structure
if ~all(isfield(cfg,{'epimin','epimax','nepi','tau_fluc','tau_samp','anticorr','feedback'}))
    error('Incomplete configuration structure!');
end
if ~isfield(cfg,'ngen')
    cfg.ngen = 1e4; % default: 10,000 episodes to choose from
end
if ~isfield(cfg,'pgen')
    cfg.pgen = 0.005; % default: 0.005
end
if ~isfield(cfg,'ntrl')
    cfg.ntrl = []; % default: no constraint on number of trials
end
if ~isfield(cfg,'fscal')
    cfg.fscal = []; % default: estimate scaling factor on-the-fly
end

if ~isfield(cfg,'realntrl')
    cfg.realntrl = cfg.ntrl; % default: no constraint on number of actual trials
    % in the fMRI version only 56 out of 96 trials are used
end


% add toolboxes to path
addpath('./Toolboxes/Rand');

% get configuration parameters
epimin   = cfg.epimin; % minimum episode length
epimax   = cfg.epimax; % maximum episode length
nepi     = cfg.nepi; % number of episodes
ntrl     = cfg.ntrl; % number of trials (optional)
ngen     = cfg.ngen; % number of episodes to choose from (optional)
pgen     = cfg.pgen; % generation precision (optional)
tau_fluc = cfg.tau_fluc; % bandit fluctuation stability
tau_samp = cfg.tau_samp; % bandit sampling stability
anticorr = cfg.anticorr; % bandit anti-correlation? (true or false)
feedback = cfg.feedback; % bandit feedback type (1:partial or 2:complete)
fscal    = cfg.fscal; % scaling factor (optional)

realntrl = cfg.realntrl;

blck = [];

tic
% define bandit sampling function
get_pr = @(p,t)betarnd(1+p*exp(t),1+(1-p)*exp(t));

% generate episodes
fprintf('generating episodes...\n');
pr_all = cell(ngen,1);
pr = zeros(1,epimax+2);
for i = 1:ngen
    while true
        pr(:) = 0;
        pr(1) = get_pr(0.5,tau_fluc);
        if pr(1) < 0.5
            pr(1) = 1-pr(1);
        end
        for j = 2:epimax+2
            pr(j) = get_pr(pr(j-1),tau_fluc);
            if pr(j) < 0.5
                break
            end
        end
        epilen = j-1;
        if epilen >= epimin && epilen <= epimax
            break
        end
    end
    pr_all{i} = pr(1:j-1);
end

% check requested number of trials
if ~isempty(ntrl)
    pr_len = cellfun(@length,pr_all);
    if ntrl/nepi < quantile(pr_len,0.25) || ntrl/nepi > quantile(pr_len,0.75)
        warning('requested number of trials out of comfort zone!');
    end
end

% compute average distance from 0.5
pf_avg = mean(cat(2,pr_all{:})-0.5);

% compute average difference between two uncorrelated bandits
n = cellfun(@length,pr_all);

pp_all = zeros(1,sum(n)); igen_pp = randperm(ngen); j_pp = 0;
qq_all = zeros(1,sum(n)); igen_qq = randperm(ngen); j_qq = 0;

for i = 1:ngen
    k_pp = j_pp+(1:n(igen_pp(i)));
    k_qq = j_qq+(1:n(igen_qq(i)));
    if mod(i,2) == 0
        pp_all(k_pp) = 1-pr_all{igen_pp(i)};
        qq_all(k_qq) = 1-pr_all{igen_qq(i)};
    else
        pp_all(k_pp) = pr_all{igen_pp(i)};
        qq_all(k_qq) = pr_all{igen_qq(i)};
    end
    j_pp = j_pp+n(igen_pp(i));
    j_qq = j_qq+n(igen_qq(i));
end
df_avg = mean(abs(pp_all-qq_all));
% compute average difference between two anti-correlated bandits
df_cor = mean(abs(pp_all*2-1));

% generate first bandit
fprintf('generating 1st bandit...\n');
while true
    igen = randperm(ngen,nepi);
    pp = pr_all{igen(1)};
    for i = 2:nepi
        if mod(i,2) == 0
            pp = cat(2,pp,1-pr_all{igen(i)});
        else
            pp = cat(2,pp,pr_all{igen(i)});
        end
    end
    if isempty(ntrl) || length(pp) == ntrl
        if ... % verify following constraints
                abs(mean(abs(pp-0.5))-pf_avg) < pgen &&  ... % bandit distance from 0.5
                abs(mean(pp)-0.5) < pgen % bandit value
            break
        end
    end
end
% fix number of trials
ntrl = length(pp);

% generate second bandit
fprintf('generating 2nd bandit...\n');
if anticorr
    % imply second bandit from first bandit
    qq = 1-pp;
    % rescale bandits to control inter-bandit distance
    if isempty(fscal)
        % estimate scaling factor on-the-fly
        fscal = df_avg/df_cor;
        fprintf('  => scaling factor estimate: %.3f\n',fscal);
    end
    pp = (pp-0.5)*fscal+0.5;
    qq = (qq-0.5)*fscal+0.5;
else
    % remove used episodes
    pr_all(igen) = [];
    % generate second bandit
    while true
        igen = randperm(ngen-nepi,nepi);
        qq = pr_all{igen(1)};
        for i = 2:nepi
            if mod(i,2) == 0
                qq = cat(2,qq,1-pr_all{igen(i)});
            else
                qq = cat(2,qq,pr_all{igen(i)});
            end
        end
        if length(qq) == ntrl
            if ... % verify following constraints
                    abs(mean(abs(qq-0.5))-pf_avg) < pgen && ... % bandit distance from 0.5
                    abs(mean(qq)-0.5) < pgen && ... % bandit value
                    abs(mean(abs(pp-qq))-df_avg) < pgen && ... % inter-bandit distance
                    abs(mean(pp-qq)) < pgen && ... % inter-bandit value difference
                    abs(corr(pp(:),qq(:))) < pgen % inter-bandit correlation
                break
            end
        end
    end
end

% sample bandits
fprintf('sampling bandits...\n');

ps_all = get_pr(repmat(pp,[ngen,1]),tau_samp);
qs_all = get_pr(repmat(qq,[ngen,1]),tau_samp);
% simulate reference model
alpha = 0.5; % reference learning rate (do not change!)
qval = zeros(ngen,ntrl);
resp = zeros(ngen,ntrl);
vabs = zeros(ngen,ntrl); % absolute chosen value
vrel = zeros(ngen,ntrl); % relative chosen value
% first trial
qval(:,1) = 50;
resp(:,1) = 1; % assume first response = 1
% subsequent trials
for itrl = 2:ntrl
    % if previous response = 1
    igen = resp(:,itrl-1) == 1;
    vabs(igen,itrl-1) = ps_all(igen,itrl-1);
    vrel(igen,itrl-1) = ps_all(igen,itrl-1)-qs_all(igen,itrl-1);
    if feedback == 1 % partial feedback
        qval(igen,itrl) = qval(igen,itrl-1)+alpha*(ps_all(igen,itrl-1)*2-100-qval(igen,itrl-1));
    else % complete feedback
        qval(igen,itrl) = qval(igen,itrl-1)+alpha*(ps_all(igen,itrl-1)-qs_all(igen,itrl-1)-qval(igen,itrl-1));
    end
    % if previous response = 2
    igen = resp(:,itrl-1) == 2;
    vabs(igen,itrl-1) = qs_all(igen,itrl-1);
    vrel(igen,itrl-1) = qs_all(igen,itrl-1)-ps_all(igen,itrl-1);
    
    if feedback == 1 % partial feedback
        qval(igen,itrl) = qval(igen,itrl-1)+alpha*(100-qs_all(igen,itrl-1)*2-qval(igen,itrl-1));
    else % complete feedback
        qval(igen,itrl) = qval(igen,itrl-1)+alpha*(ps_all(igen,itrl-1)-qs_all(igen,itrl-1)-qval(igen,itrl-1));
    end
    % current response
    resp(:,itrl) = 1+(qval(:,itrl) < 0);
end
% last trial
igen = resp(:,end) == 1;
vabs(igen,end) = ps_all(igen,end);
vrel(igen,end) = ps_all(igen,end)-qs_all(igen,end);
igen = resp(:,end) == 2;
vrel(igen,end) = qs_all(igen,end);
vrel(igen,end) = qs_all(igen,end)-ps_all(igen,end);
% average chosen value across trials
vabs = mean(vabs,2);
vrel = mean(vrel,2);

% choose most average sample chain: the correlation between observed outcomes is also minimizied 
[~,~,vabs_rnk] = unique(abs(zscore(vabs))); % rank for absolute chosen value
[~,~,vrel_rnk] = unique(abs(zscore(vrel))); % rank for relative chosen value
rcor = nan(ngen,1);
for igen = 1:ngen
    rcor(igen) = corr(ps_all(igen,:)',qs_all(igen,:)');
end
[~,~,rcor_rnk] = unique(abs(rcor));
[~,i] = min(vabs_rnk+vrel_rnk+rcor_rnk); % minimize sum of ranks
ps = ps_all(i,:);
qs = qs_all(i,:);
    
% add bandits to block structure
blck.pp = pp*100;
blck.qq = qq*100;
blck.ps = min(max(round(ps*100),1),99);
blck.qs = min(max(round(qs*100),1),99);

% generate bandit positions
fprintf('generating bandit positions...\n');
vm = [pp;qq]; % mean bandit values
vs = [ps;qs]; % sampled bandit values
pos = [];
pos_sub = kron([1,2],ones(1,8));
nsub = ceil(ntrl/16);
for isub = 1:nsub
    while true
        pos_tmp = [pos,pos_sub(randperm(16))];
        ntmp = min(numel(pos_tmp),ntrl);
        i1 = sub2ind(size(vm),pos_tmp(1:ntmp),1:ntmp); % look-up indices for left bandit
        i2 = sub2ind(size(vm),3-pos_tmp(1:ntmp),1:ntmp); % look-up indices for right bandit
        if ...
                ~HasConsecutiveValues(pos_tmp,4) && ... % bandit positions
                abs(mean(vm(i1)-vm(i2))) < pgen && ... % mean bandit values at left/right positions
                abs(mean(vs(i1)-vs(i2))) < pgen % sampled bandit values at left/right positions
            break
        end
    end
    pos = pos_tmp;
end
blck.pos = pos(1:ntrl);

%% supplementary functions
    function [paird] = meanpairdiff(x)
        % x is a 1 x n vector
        % to compute the pairwise differences for
        dimx = size(x,2);
        d = nchoosek(1:dimx,2); % all combinations of 2 positions without repetition: total 6 for 4 bandits
        
        dd = 0;
        for i=1:size(d,1)
            dd = dd + (x(d(i,1)) - x(d(i,2)))*0.5;
        end
        paird = dd;
    end

toc
end % function