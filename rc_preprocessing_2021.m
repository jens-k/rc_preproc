addpath(genpath('C:\Users\asanch24\Documents\Github\rc_preproc\'))
% ft_defaults

addpath(genpath('C:\Users\asanch24\Documents\MATLAB\fieldtrip'))
%% General comments
% I wrote this code example down there without ever running it; please
% think of it as a broad pointer into the right direction.

%% ------     FIRST-TIME SETUP
% init_rc;
paths                       = [];
paths.root                  = 'D:\Sleep\DataDownload';
paths.data                  = 'D:\Sleep\DataDownload\Recordings\DNight';
paths.sl_hypnograms         = 'D:\Sleep\DataDownload\Hypnograms';

files = dir(strcat(paths.data,filesep,'*.mff'));

%% Get trial description

for subj = 1:numel(files)
cnt = 1;

data_filename   = files(subj).name;
hyp_filename    = strcat('s',data_filename(4:5),'_n',data_filename(6),'.txt');


cfg_trial{subj}						= [];
cfg_trial{subj}.dataset             = fullfile(paths.data, data_filename);%Doing now with subject 12, session 1
cfg_trial{subj}.trialdef.pre		= 5; % all the .trialdef fields are just forwarded to the cfg.trialfun
cfg_trial{subj}.trialdef.post	    = 15;
cfg_trial{subj}.epoch_length_sec    = 30;
cfg_trial{subj}.hypnogram			= fullfile(paths.sl_hypnograms,hyp_filename);%Doing now with subject 12, session 1
cfg_trial{subj}.trialfun            = 'rc_trialfun_2021'; % 
%cfg.id                  = sdata(iSj).id; % unique recording ID for future reference
cfg_trial{subj}.counter				= cnt;		% to easier find the dataset again later on
cfg_trial{subj}						= ft_definetrial(cfg_trial{subj});

cnt                     = cnt + 1;

%% Preprocessing: filtering

channels_wo_face   = {'all', '-E49', '-E48', '-E43', '-E127', '-E126', '-E17', '-E128', '-E32', '-E25', '-E21', '-E14', '-E8', '-E1', '-E125', '-E120', '-E119', '-E113','-VREF'};

% The output of ft_definetrial can be used for ft_preprocessing, so we dont
% have to preprocess and filter the whole dataset, and we save time.

cfg_preproc{subj}					  = cfg_trial{subj};
cfg_preproc{subj}.channel             = 'all';
cfg_preproc{subj}.bpfilter            = 'no';
cfg_preproc{subj}.detrend             = 'yes';

data_preproc                          = ft_preprocessing(cfg_preproc{subj});

%% Bad channels detection


cfg_bchan{subj}                = [];
cfg_bchan{subj} .metric        = 'zvalue';
cfg_bchan{subj} .channel       = channels_wo_face;
cfg_bchan{subj} .threshold     = 6;

cfg_bchan{subj}                = ft_badchannel(cfg_bchan{subj},data_preproc);

end


% %% Artifact detection
% 
% cfg_art					= [];
% % cfg_art.id              = cfg.id; % Take this info from cfg created above
% cfg_art.continuous      = 'yes';
% cfg_art.trl             = cfg.trl;
% cfg_art.dataset         = cfg.dataset;
% cfg_art.artfctdef       = [];
% 
% % Z-value based rejection
% % This is the one from here: https://www.fieldtriptoolbox.org/tutorial/automatic_artifact_rejection/#examples-for-getting-started
% % All those parameters are just what worked for me at some point, dont use
% % them necessarily
% 
% 
% cfg_art.artfctdef.zvalue.channel     = channels_wo_face; % dont incorporate artifact-prone frontal channels
% cfg_art.artfctdef.zvalue.trlpadding  = 0;
% cfg_art.artfctdef.zvalue.fltpadding  = 1;   % only used for filtering before artifact detection (tutorial: .1)
% cfg_art.artfctdef.zvalue.artpadding  = 0.4; % window around artifacts still rejected
% cfg_art.artfctdef.zvalue.detrend     = 'yes';
% cfg_art.artfctdef.zvalue.bpfilter    = 'yes';
% cfg_art.artfctdef.zvalue.bpfreq      = [55 80]; % check tutorals for optimal values
% cfg_art.artfctdef.zvalue.bpfiltord   = 3;
% cfg_art.artfctdef.zvalue.bpfilttype  = 'but';
% cfg_art.artfctdef.zvalue.hilbert     = 'yes';         % ?
% cfg_art.artfctdef.zvalue.boxcar      = 0.2;           % ?
% cfg_art.artfctdef.zvalue.interactive = 'yes';
% cfg_art.artfctdef.zvalue.cutoff      = 20;
% cfg_art.feedback                     = 'yes';
% cfg_art                              = ft_artifact_zvalue(cfg_art);
% 
% % There is also the one from here: 
% % https://www.fieldtriptoolbox.org/tutorial/visual_artifact_rejection/#manual-artifact-rejection---display-a-summary
% % ...which looks cool but it works differencely than all the
% % ft_artifact_xxx functions. It needs data and gives you back lists of
% % rejectable trials and channels I think.
% % cfg          = [];
% % cfg.method   = 'summary';
% % cfg.ylim     = [-1e-12 1e-12];
% % dummy        = ft_rejectvisual(cfg,dataFIC);
% 
% % And then there is a fully manual way of detection artifacts, by marking
% % them in the databrowser. Here you can also see all the previously
% % determined artifacts and doublecheck them. There might be a few mistakes
% % in this code, didnt double check:
% cfg_db                 = [];
% cfg_db.viewmode        = 'vertical';
% cfg_db.channel         = channels_wo_face;
% % cfg_db.data            = data_preproc;%fullfile(paths.data, 'RC_121_sleep.mff');%Doing now with subject 12, session 1
% % cfg_db.blocksize       = 30;		
% cfg_db.ylim            = [-120 120];
% % cfg_db.selectmode      = 'markartifact';
% % cfg_db.artfctdef	   = cfg_art.artfctdef;
% cfg_db                 = ft_databrowser(cfg_db, data_preproc);
% 
% %save(cfg_art, path_artifactdef);