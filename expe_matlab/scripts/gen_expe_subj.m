function gen_expe_subj(subj,generate_train)
%  GEN_EXPE_SUBJ  Generate and save experiment structure
% Modified for RLVAR ONLINE VERSION by VS January 2020 

% =====================================================

%  Usage: GEN_EXPE_SUBJ(subj)
%
%  where subj is the subject number
%
%  The function plots condition-wise scores for the reference learning model,
%  corresponding to a comparative reinforcement-learning model with a learning
%  rate of 0.5. Scores correspond to mean-wise relative values (chosen minus
%  unchosen). The generated blocks have *not* been constrained w.r.t. model-
%  predicted scores.
%
%  Valentin Wyart <valentin.wyart@ens.fr> - Jan. 2016

% initialize random number generator
RandStream.setGlobalStream(RandStream('mt19937ar','Seed','shuffle'));

% generate experiment structure
expe = gen_expe_online(subj,generate_train);

% save experiment structure
if generate_train == 1
    filename = sprintf('../Data_tausamp_2_truncated/RLVARONLINE_training_expe.mat');
else
    filename = sprintf('../Data_tausamp_2_truncated/RLVARONLINE_S%02d_expe.mat',subj);
end

save(filename,'expe','-v6');

end