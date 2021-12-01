
%% General comments
% I wrote this code example down there without ever running it; please
% think of it as a broad pointer into the right direction.

%% ------     FIRST-TIME SETUP
% init_rc;
paths                       = [];
paths.root                  = 'D:\Sleep\DataDownload';
paths.data                  = 'D:\Sleep\DataDownload\Recordings';
paths.sl_hypnograms         = 'D:\Sleep\DataDownload\Hypnograms';


%% Get trial description

cfg						= [];
cfg.dataformat          = 'egi_mff_v2'; 
cfg.headerformat        = 'egi_mff_v2';
cfg.dataset             = 'D:\Sleep\DataDownload\Recordings\RC_121_sleep.mff';%Doing now with subject 12, session 1
cfg.trialdef.pre		= -5; % all the .trialdef fields are just forwarded to the cfg.trialfun
cfg.trialdef.post	    = 15;
cfg.epoch_length        = 30;
cfg.hypnogram			= fullfile(paths.sl_hypnograms,'s12_n1.txt');%Doing now with subject 12, session 1
cfg.trialfun            = 'rc_trialfun'; % does the actual work - DOES NOT ACTUALLY WORK RIGHT NOW, CHECK FUNCTION!
cfg						= ft_definetrial(cfg);


cfg:with:only_good_trials_plus_plus pairing = check_trials(cfg)
% Now, cfg contains a field .trl containing a trial description that looks like this:
% 1000 2000 500 2 11
% 3500 4500 500 2 12
% 1000 2000 500 2 21
% ...
% 
% This would be a trl structure for 3 trials, each 1000 samples long, with
% the 0 point right in the middle. I added another column for the sleep
% stage at the beginning of the trial and the condition (one could use a
% code like: vehicle off period 11, vehicle on period 12, odor off period 21, odor on period 22)
% odor 2, just as an example).

% Based on this trial definition, we can now to artifact detection. Please
% not that, because we did not cut out any actual data (or even load any
% into memory) yet, we still can do padding of the trials as much as we like.

