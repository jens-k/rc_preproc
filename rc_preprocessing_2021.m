addpath(genpath('C:\Users\asanch24\Documents\Github\rc_preproc\'))
ft_defaults
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
cnt = 1;

cfg						= [];
cfg.dataformat          = 'egi_mff_v2'; 
cfg.headerformat        = 'egi_mff_v2';
cfg.dataset             = 'D:\Sleep\DataDownload\Recordings\RC_121_sleep.mff';%Doing now with subject 12, session 1
cfg.trialdef.pre		= -5; % all the .trialdef fields are just forwarded to the cfg.trialfun
cfg.trialdef.post	    = 15;
cfg.epoch_length_sec    = 30;
cfg.hypnogram			= fullfile(paths.sl_hypnograms,'s12_n1.txt');%Doing now with subject 12, session 1
cfg.trialfun            = 'rc_trialfun_2021'; % does the actual work - DOES NOT ACTUALLY WORK RIGHT NOW, CHECK FUNCTION!
%cfg.id                  = sdata(iSj).id; % unique recording ID for future reference
cfg.counter				= cnt;		% to easier find the dataset again later on
cfg						= ft_definetrial(cfg);

cnt                     = cnt + 1;