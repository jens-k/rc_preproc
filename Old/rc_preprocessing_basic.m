
%% General comments
% I wrote this code example down there without ever running it; please
% think of it as a broad pointer into the right direction.


%% Get trial description

% These paths are usually retrieved via a subject description
% function that returns this path and other information for each subject
% (you find mine for this project on the Tuebingen server).
% Please rename these variables as you please.
path_dsfolder			= "asdasd/asdasd";
path_dataset			= fullfile(path_dsfolder, "xxxxx.xyz2");
path_trl				= fullfile(path_dsfolder, "ttttt.xyz2");
path_hypnogram			= fullfile(path_dsfolder, "yyyyy.txt");
path_artifactdef		= fullfile(path_dsfolder, "zzzzz.mat"); % will be created later

cfg						= [];
cfg.dataformat          = 'egi_mff_v2'; 
cfg.headerformat        = 'egi_mff_v2';
cfg.dataset             = path_dataset;
cfg.continuous          = 'no';
cfg.trialdef.pre		= -2; % all the .trialdef fields are just forwarded to the cfg.trialfun
cfg.trialdef.post	    = 6;
cfg.hypnogram			= get_filenames(paths.hypnogram, sdata(iSj).id, 'full');
cfg.trialfun            = 'rc_trialfun'; % does the actual work - DOES NOT ACTUALLY WORK RIGHT NOW, CHECK FUNCTION!
cfg.id                  = sdata(iSj).id; % unique recording ID for future reference
cfg.counter				= cnt;		% to easier find the dataset again later on
cfg						= ft_definetrial(cfg);
save(cfg, path_trl);

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

%% Artifact detection
% Usually I have some code here that checks if that artifact structure
% already exists and loads it if desired or at least warns you that you
% might overwrite something. Not needed for now.

% Set up artifact structure, then we can use different ways to detect
% artifacts, all will be saved into cfg_art.artfctdef.xxxx.artifact (with
% xxx being the type of artifact) in the form of sample ranges with bad
% data. Artifactual changes can be returned by some functions but - last
% time I used this - you gotta take care of them manually
cfg_art					= [];
cfg_art.id              = cfg.id; % Take this info from cfg created above
cfg_art.continuous      = 'yes';
cfg_art.trl             = cfg.trl;
cfg_art.dataset         = cfg.dataset;
cfg_art.artfctdef       = [];

% Z-value based rejection
% This is the one from here: https://www.fieldtriptoolbox.org/tutorial/automatic_artifact_rejection/#examples-for-getting-started
% All those parameters are just what worked for me at some point, dont use
% them necessarily
cfg_art.artfctdef.zvalue.channel     = channels_wo_face; % dont incorporate artifact-prone frontal channels
cfg_art.artfctdef.zvalue.trlpadding  = 0;
cfg_art.artfctdef.zvalue.fltpadding  = 1;   % only used for filtering before artifact detection (tutorial: .1)
cfg_art.artfctdef.zvalue.artpadding  = 0.4; % window around artifacts still rejected
cfg_art.artfctdef.zvalue.detrend     = 'yes';
cfg_art.artfctdef.zvalue.bpfilter    = 'yes';
cfg_art.artfctdef.zvalue.bpfreq      = [55 80]; % check tutorals for optimal values
cfg_art.artfctdef.zvalue.bpfiltord   = 8;
cfg_art.artfctdef.zvalue.bpfilttype  = 'but';
cfg_art.artfctdef.zvalue.hilbert     = 'yes';         % ?
cfg_art.artfctdef.zvalue.boxcar      = 0.2;           % ?
cfg_art.artfctdef.zvalue.interactive = 'yes';
cfg_art                 = ft_artifact_zvalue(cfg_art);

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

save(cfg_art, path_artifactdef);


