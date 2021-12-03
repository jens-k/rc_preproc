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
cfg.dataset             = fullfile(paths.data, 'RC_121_sleep.mff');%Doing now with subject 12, session 1
cfg.trialdef.pre		= -5; % all the .trialdef fields are just forwarded to the cfg.trialfun
cfg.trialdef.post	    = 15;
cfg.epoch_length_sec    = 30;
cfg.hypnogram			= fullfile(paths.sl_hypnograms,'s12_n1.txt');%Doing now with subject 12, session 1
cfg.trialfun            = 'rc_trialfun_2021'; % does the actual work - DOES NOT ACTUALLY WORK RIGHT NOW, CHECK FUNCTION!
%cfg.id                  = sdata(iSj).id; % unique recording ID for future reference
cfg.counter				= cnt;		% to easier find the dataset again later on
cfg						= ft_definetrial(cfg);

cnt                     = cnt + 1;

%% Artifact detection

cfg_art					= [];
% cfg_art.id              = cfg.id; % Take this info from cfg created above
cfg_art.continuous      = 'yes';
cfg_art.trl             = cfg.trl;
cfg_art.dataset         = cfg.dataset;
cfg_art.artfctdef       = [];

% Z-value based rejection
% This is the one from here: https://www.fieldtriptoolbox.org/tutorial/automatic_artifact_rejection/#examples-for-getting-started
% All those parameters are just what worked for me at some point, dont use
% them necessarily

channels_wo_face   = {'all', '-E49', '-E48', '-E43', '-E127', '-E126', '-E17', '-E128', '-E32', '-E25', '-E21', '-E14', '-E8', '-E1', '-E125', '-E120', '-E119', '-E113'};

cfg_art.artfctdef.zvalue.channel     = channels_wo_face; % dont incorporate artifact-prone frontal channels
cfg_art.artfctdef.zvalue.trlpadding  = 0;
cfg_art.artfctdef.zvalue.fltpadding  = 1;   % only used for filtering before artifact detection (tutorial: .1)
cfg_art.artfctdef.zvalue.artpadding  = 0.4; % window around artifacts still rejected
cfg_art.artfctdef.zvalue.detrend     = 'yes';
cfg_art.artfctdef.zvalue.bpfilter    = 'yes';
cfg_art.artfctdef.zvalue.bpfreq      = [1 30]; % check tutorals for optimal values
cfg_art.artfctdef.zvalue.bpfiltord   = 8;
cfg_art.artfctdef.zvalue.bpfilttype  = 'but';
cfg_art.artfctdef.zvalue.hilbert     = 'yes';         % ?
cfg_art.artfctdef.zvalue.boxcar      = 0.2;           % ?
cfg_art.artfctdef.zvalue.interactive = 'yes';
cfg_art                              = ft_artifact_zvalue(cfg_art);

% There is also the one from here: 
% https://www.fieldtriptoolbox.org/tutorial/visual_artifact_rejection/#manual-artifact-rejection---display-a-summary
% ...which looks cool but it works differencely than all the
% ft_artifact_xxx functions. It needs data and gives you back lists of
% rejectable trials and channels I think.
% cfg          = [];
% cfg.method   = 'summary';
% cfg.ylim     = [-1e-12 1e-12];
% dummy        = ft_rejectvisual(cfg,dataFIC);

% And then there is a fully manual way of detection artifacts, by marking
% them in the databrowser. Here you can also see all the previously
% determined artifacts and doublecheck them. There might be a few mistakes
% in this code, didnt double check:
cfg_db.viewmode        = 'vertical';
cfg_db.channel         = 1:4:110;     % show some random channels (all is too crowded)
cfg_db.blocksize       = 30;		
cfg_db.ylim            = [-120 120];
cfg_db.selectmode      = 'markartifact';
cfg_db.artfctdef	   = arts.artfctdef;
cfg_art                = ft_databrowser(cfg_db);

%save(cfg_art, path_artifactdef);