%% Preprocessing pipeline
error('Don''t run this file by accidentally pressing F5.'); 1==1;
delete(gcf)

%% ------     FIRST-TIME SETUP
% init_rc;
% pipeline_name               = 'preprocessing 1.2';
% paths                       = [];
% paths.root                  = get_pathroot;
% paths.data                  = get_pathdata;
% paths.home                  = enpath(fullfile(paths.root, 'homes', pipeline_name));
% paths.meta                  = enpath(fullfile(paths.home, 'meta'))
% paths.headmodels            = fullfile(paths.root, 'homes', 'headmodels 1.2', 'prepared');
% paths.electrodes            = fullfile(paths.root, 'homes', 'headmodels 1.2', 'projected electrodes', 'prepared');
% paths.grids                 = fullfile(paths.root, 'homes', 'headmodels 1.2', 'subject-specific grids');
% paths.sl_hypnograms		  = fullfile(path_data, 'Hypnograms');
% saveall(paths);

%% ------     SETUP
% channels_wo_face      excludes all channels in the face
% ...with_eog           like channels_wo_face but keeps the ones needed to
%                       calculate horizontal and vertical eye movements
%                       (4 + 2 for symmetry)
% channels_min          excludes all edge and face channels and the
%                       mastoids
% channels_min          = {'all', '-E49', '-E48', '-E43', '-E127', '-E126', '-E17', '-E128', '-E32', '-E25', '-E21', '-E14', '-E8', '-E1', '-E125', '-E120', '-E119', '-E113', '-E56', '-E63', '-E68', '-E73', '-E81', '-E88', '-E94', '-E99', '-E107', '-E57', '-E100'};
paths                       = [];
pipeline_name               = 'preprocessing 1.2';  % has to be the same as above
paths                       = abpath(load_file(fullfile(get_pathroot, 'homes', pipeline_name, 'meta', 'paths.mat')));
channels_wo_face            = {'all', '-E49', '-E48', '-E43', '-E127', '-E126', '-E17', '-E128', '-E32', '-E25', '-E21', '-E14', '-E8', '-E1', '-E125', '-E120', '-E119', '-E113'};
channels_wo_face_with_eog   = {'all', '-E49', '-E48', '-E43',                   '-E17', '-E128', '-E32',                                '-E1', '-E125', '-E120', '-E119', '-E113'};

%% ------     CREATE CFG for artifact definition
% For each subject, artifact information will accumulate in this cfg until
% in the very end, all artifacts will be rejected. Steps can be repeated
% and refined, in all cases the existing cfg will be loaded, altered, and
% saved again.
% addpath(abpath('$root/fieldtrip/qsub'));
paths.sl                    = enpath(fullfile(paths.home, 'sleep'));
paths.sl_meta               = enpath(fullfile(paths.sl, 'meta'));

% For each subject, night, and session
cfg = {}; cnt = 1;
for iSj = 1:numel(subjdata)
	for iNi = 1:2
		cfg{cnt}.dataformat                 = 'egi_mff_v2';
		cfg{cnt}.headerformat               = 'egi_mff_v2';
		cfg{cnt}.dataset                    = abpath(subjdata(iSj).sleep{iNi});
		cfg{cnt}.continuous                 = 'yes';

		cfg{cnt}.hypnogram					= get_filenames(paths.sl_hypnograms, [subjdata(iSj).id '_n' num2str(iNi)], 'full');	
		cfg{cnt}.trialfun                   = 'trialfun_sl'; % cuts out sleep stages 2,3,4 (after sleep onset) based on SchlafAUS scorings
		cfg{cnt}.trialdef.post_start        = 0;        % secs to start after the start trigger
		cfg{cnt}.trialdef.pre_end           = 0;        % secs to end before end trigger
		cfg{cnt}.trialdef.segment_length    = 0;        % length of time window to cut data to (in sec)

		cfg{cnt}.id                         = [subjdata(iSj).id '_n' num2str(iNi) '_sl']; % unique recording ID for future reference
		cfg{cnt}.counter					= cnt;		% to easier find the dataset again later on
		cnt = cnt + 1;
	end
end

% Define trials and collect all cmd window output
[T, cfg]	= evalc('cellfun(@ft_definetrial, cfg, ''UniformOutput'', false)');

% Extract all warnings from evalc's output and get rid of a common irrelevant warning
warnings	= regexp(T, 'Warning.*?(\)\.(?=\n)|(?=]))', 'match')';
warnings	= warnings(cellfun(@isempty, strfind(warnings, 'discont')));

% Load old cfgs and warnings and make sure we are not processing already processed datasets
file_cfg_old = fullfile(paths.sl_meta, 'sl_trialdefs.mat');
if exist(file_cfg_old) == 2
	cfg_old = load_file(file_cfg_old);
	if ~isempty(cfg_old)
		for i=1:numel(cfg)
			if any(cellfun(@(x) strcmp(cfg{i}.id,x.id), cfg_old)), error('Datasets overlap with already processed ones!'); end
		end
	end
	cfg = [cfg_old cfg];
end

file_warnings_old = fullfile(paths.sl_meta, 'sl_definetrial_warnings.mat');
if exist(file_warnings_old) == 2
	warnings_old = load_file(file_warnings_old)
	warnings = [warnings_old warnings];
end

% Save the results
realsave(fullfile(paths.sl_meta, 'sl_definetrial_warnings'), warnings)
realsave(fullfile(paths.sl_meta, 'sl_trialdefs'), cfg)

% - Double-check datasets based on the collected warning!
% - Do that by re-running the definetrial again while debugging
%   the trialfun: ft_definetrial(cfg{counter})

%% ------     PREPROCESSING			START ON HEADNODE FOR QSUB
% This is done here already because larger parts of the data will not be
% used (e.g. everything before sleep onset) and is full of artifacts which
% will skew artifact detection.
% One should probably filter out line noise here so that it doesn't
% occupy so many ICA components
paths.sl_rawnrem			= enpath(fullfile(paths.sl, 'rawnrem'));
path_result                 = paths.sl_rawnrem;

cfg_all						= load_file(fullfile(paths.sl_meta, 'sl_trialdefs'));
cfg							= {};
addpath(abpath('$root/fieldtrip/qsub'));
cd(abpath(fullfile(path_root, '/../qsub')))
for iEntry = 1:numel(cfg_all)
	cfg{iEntry}						= cfg_all{iEntry};
	cfg{iEntry}.dataset				= abpath(cfg{iEntry}.dataset);
	cfg{iEntry}.hypnogram			= abpath(cfg{iEntry}.hypnogram);
	cfg{iEntry}.datafile			= abpath(cfg{iEntry}.datafile);
	cfg{iEntry}.headerfile			= abpath(cfg{iEntry}.headerfile);
	cfg{iEntry}.channel             = {'all', '-VREF'};
    cfg{iEntry}.bpfilter            = 'yes';
	cfg{iEntry}.bpfreq              = [0.2 180];
	cfg{iEntry}.bpfilttype          = 'fir';
	cfg{iEntry}.bpfiltdir           = 'twopass';
	cfg{iEntry}.padding             = 0;  
	cfg{iEntry}.outputfile			= fullfile(path_result, [cfg{iEntry}.id, '_' num2str(cfg{iEntry}.bpfreq(1)) '-' num2str(cfg{iEntry}.bpfreq(2)) '_nrem.mat']);
end
qsubcellfun(@ft_preprocessing, cfg, 'matlabcmd', '/usr/local/MATLAB/R2016a/bin/matlab', 'memreq', 10 * 1024^3, 'timreq', 20 * 60 * 60, 'UniformOutput', false, 'backend', 'torque', 'StopOnError', false)
cd(abpath(paths.root));

%% ------     ARTIFACT DETECTION
% Takes the trialdefinition cfg from above and reads in unpreprocessed data
% from disk. This allows padding of the trials (e.g. for filtering).
% Creates a file for each entry in the preprocessing cfg that contains all
% artifact information. Every artifact procedure will save its data in this
% file. In the end they can all be rejected together.
%
% The end goal is to have pairs/triplets of preprocessed data:
% . raw data before artifact rejection ('raw')
% . an artifact definition for each data set ('artifacts')
% . artifact-free data that was also ICA-cleaned ('clean')
% Further preprocessing (e.g. face-channel rejection, re-referencing) will
% be done in the respective follow-up pipeline (sensor-level, source-level 
% etc.).
cfg							= load_file(fullfile(paths.sl_meta, 'sl_trialdefs'));
paths.sl_artifacts          = enpath(fullfile(abpath(paths.sl), 'artifacts'));
delete_existing_arts		= false;

% --------------- Set up artifact structure ---------------
path_result                 = paths.sl_artifacts;
for iEntry = 1:numel(cfg)
	cfg_art                 = [];
	cfg_art.id              = cfg{iEntry}.id;
	cfg_art.continuous      = 'yes';
	cfg_art.trl             = cfg{iEntry}.trl;
	cfg_art.dataset         = cfg{iEntry}.dataset;
	cfg_art.artfctdef       = [];
    
	% Load potential existing artifact definitions and take over artifacts
	temp = get_filenames(paths.sl_artifacts, cfg{iEntry}.id, 'full');
	if ~isempty(temp) && ~delete_existing_arts
		disp(['Taking over existing artifacts (' cfg{iEntry}.id ').'])
		temp = load_file(temp);
        if isfield(temp, 'artfctdef')
            cfg_art.artfctdef = temp.artfctdef;
        end
	end
	realsave(fullfile(path_result, [cfg{iEntry}.id, '.mat']), cfg_art)
end

% --------------- Movement Arousals (hypnogram-based)
epoch_length_sec			= 30;
path_arts                   = paths.sl_artifacts;
for iEntry = 1:numel(cfg)
	
	hyp								= load_hypnogram(abpath(cfg{iEntry}.hypnogram));
	hdr								= ft_read_header(abpath(cfg{iEntry}.headerfile));
	epoch_length_smpl				= epoch_length_sec * hdr.Fs;
	
	% Extract MAs if we are in sleep and MA has been scored
	artfctdef = [];
	for iEpoch = 1:length(hyp)
		if any(hyp(iEpoch, 1) == [2 3 4]) && hyp(iEpoch, 2) == 1
			artfctdef	= [artfctdef; (iEpoch-1)*epoch_length_smpl+1 iEpoch*epoch_length_smpl];
		end
	end

	% Load potential existing artifact definitions and take over
	% everything but MA artifacts
	filename = get_filenames(path_arts, cfg{iEntry}.id, 'full');
	if ~isempty(filename)
		disp('Taking over existing non-MA artifacts.')
		cfg_art = load_file(filename);
		if isfield(cfg_art, 'artfctdef') && isfield(cfg_art.artfctdef, 'MA'), cfg_art.artfctdef = rmfield(cfg_art.artfctdef, 'MA'); end
	else
		error('No artifact structure found.')
	end
	
	cfg_art.artfctdef.MA.artifact = artfctdef; % add interesting parts of current detection
	realsave(filename, cfg_art, 0)
end

% --------------- Muscle (automatic, z-value-based) --------------- 
% It would be better to take the cut and filtered data here but for some
% reason the z-values are just much much higher there (i checked data
% before and after filtering, that's not the problem).
overwrite				= false;
path_arts               = paths.sl_artifacts;
for iEntry = 1:numel(cfg)
	
	% Load potential existing artifact definitions and take over
	% everything but zvalue artifacts
	filename = get_filenames(paths.sl_artifacts, cfg{iEntry}.id, 'full');
	if ~isempty(filename)
		cfg_art = load_file(filename);
		if overwrite
			disp('Taking over existing non-zvalue artifacts.')
			if isfield(cfg_art, 'artfctdef') && isfield(cfg_art.artfctdef, 'zvalue'), cfg_art.artfctdef = rmfield(cfg_art.artfctdef, 'zvalue'); end
		else
			disp('Taking over all existing  artifacts.')
		end
	else
		error('No artifact structure found.')
	end
	
	% Settings
 	cfg_art.dataset						 = abpath(cfg_art.dataset);
	if ~isfield(cfg_art.artfctdef, 'zvalue') % only if there is no
		cfg_art.artfctdef.zvalue.cutoff      = 6;
	end
	
	cfg_art.artfctdef.zvalue.channel     = channels_wo_face; % dont incorporate artifact-prone frontal channels
	cfg_art.artfctdef.zvalue.trlpadding  = 0;
	cfg_art.artfctdef.zvalue.fltpadding  = 1;   % only used for filtering before artifact detection (tutorial: .1)
	cfg_art.artfctdef.zvalue.artpadding  = 0.4; % window around artifacts still rejected
	cfg_art.artfctdef.zvalue.detrend     = 'yes';
	cfg_art.artfctdef.zvalue.bpfilter    = 'yes';
	cfg_art.artfctdef.zvalue.bpfreq      = [110 140];
	cfg_art.artfctdef.zvalue.bpfiltord   = 8;
	cfg_art.artfctdef.zvalue.bpfilttype  = 'but';
	cfg_art.artfctdef.zvalue.hilbert     = 'yes';         % ?
	cfg_art.artfctdef.zvalue.boxcar      = 0.2;           % ?
	cfg_art.artfctdef.zvalue.interactive = 'yes';

	cfg_art.artfctdef.zvalue = rmfield(cfg_art.artfctdef.zvalue, 'artifact'); % has to be removed to work
	disp(['Showing you data with ID: ' cfg{iEntry}.id '.'])
	arts                                 = ft_artifact_zvalue(cfg_art); % the second output equals cfg.artfctdef.zvalue.artifact
	
	cfg_art.artfctdef                    = arts.artfctdef; % add interesting parts of current detection
	realsave(filename, cfg_art, 0)
end

% --------------- Visual (databrowser) ---------------
% This should be always the last step after other automatic artifact
% detection algorithms. If artifacts of the type "visual2" are shown, they
% come from a post-ica check of an earlier run
overwrite				= false;
path_arts               = paths.sl_artifacts;
path_origin				= paths.sl_rawnrem;
for iEntry = 1:numel(cfg)
	% Load potential existing artifact definitions
	filename = get_filenames(path_arts, cfg{iEntry}.id, 'full');
	if ~isempty(filename)
		disp('Taking over existing artifacts.')
		arts = load_file(filename);
	else
		error('No artifact structure found.')
	end
	
	data					= load_file(path_origin, arts.id);
	cfg_t                   = [];
	cfg_t.channel           = channels_wo_face;
	data_temp               = ft_selectdata(cfg_t, data);
	
	cfg_art                 = rmfield(arts, 'dataset'); % copy artifacts without dataset field
	cfg_art.viewmode        = 'vertical';
	cfg_art.channel         = 1:4:110;     % show some random channels
	cfg_art.blocksize       = 300;
	cfg_art.ylim            = [-120 120];
	cfg_art.selectmode      = 'markartifact';
	cfg_art.event           = ft_read_event(abpath(arts.dataset));
	disp(['Showing you data with ID: ' cfg_art.id '.'])
	cfg_art                 = ft_databrowser(cfg_art, data_temp);
	
	arts.artfctdef			= cfg_art.artfctdef; % put the result in our existing artifact structure
	
	% Put the artifact file back where it came from
	realsave(filename, arts, 0);
end

%% -------    ARTIFACT REJECTION
% We will use all discovererd artifacts, combine them, and cut them out. 
paths.sl_artreject          = enpath(fullfile(abpath(paths.sl), 'arts_rejected'));
path_data					= paths.sl_rawnrem;
path_origin                 = paths.sl_artifacts;
path_result                 = paths.sl_artreject;

files                       = get_filenames(path_origin, 'full'); 
parpool('local', 6) % delete(gcp('nocreate')) 
parfor iFile = 1:numel(files)
	
	cfg                     = load_file(files{iFile});
	data					= load_file(path_data, cfg.id);
	
	cfg						= rmfield(cfg, 'dataset');
	cfg.artfctdef			= rmfield(cfg.artfctdef, 'MA');
	cfg.artfctdef.reject    = 'partial';
	cfg.artfctdef.feedback  = 'no';         % yes gives you a nice plot, maybe use one day
	data_rej				= ft_rejectartifact(cfg, data);
	
	data_rej.id				= cfg.id;
	realsave(fullfile(path_result, [data_rej.id, '_artrej.mat']), data_rej);
end

%% ------     VISUAL SUMMARY AND CHANNEL INSPECTION ON ART-REJECTED DATA
% Single channels or trials may still go haywire. The following procedure
% gives better insight into the data and helps gathering a list of a)
% channels that will be rejected in the next step (before ICA because they
% can lead to problems there), b) trials that should be particularly
% checked during post-ICA visual inspection. No data is actually rejected
% here.
%
% REJECTION RULES: 
% Channels are rejected if they show very high (outlier-level) variance for
% that particular dataset. No absolute thresholds. Rejection only if its
% not just one trial that brings the variance up. In that case the trial is
% marked. If a channel is still bad after that, it finally is rejected.
% Rejected channels and trials are automatically noted in separate files
% (one per dataset). Channels will be excluded before the ICA, trials will
% remain in the data (because in this step we cannot know if a trial is 5
% seconds or half the dataset) and reviewed during the last post-ICA visual
% check. Not that particularly error-prone channels (edge and face
% channels) are automatically marked as 'rejected' (though not saved as
% such) so that they dont skew the user's perception of the overall
% variance.
%
% During later processing steps we may reject an additional set of
% channels for which we do not expect usable data (e.g. face channels for
% source localization).
paths.sl_suspchannels		= enpath(fullfile(paths.sl_meta, 'suspicious_channels'));
paths.sl_susptrials			= enpath(fullfile(paths.sl_meta, 'suspicious_trials'));

skip_existing				= false;
path_origin                 = paths.sl_artreject;
path_result                 = paths.sl_suspchannels;
path_result_trials			= paths.sl_susptrials;
files                       = get_filenames(path_origin, 'full'); % we'll doublecheck all previously collected artifacts
for iFile = 1:numel(files)
	data                    = load_file(files{iFile});
	channels				= channels_wo_face;
	resultfile_channels		= fullfile(path_result, [data.id '_suspiciouschannels.mat']);
	if exist(resultfile_channels) == 2 && skip_existing
		warning(['Dataset ' data.id ' has already been processed. Skipping...']), 
		continue
	elseif exist(resultfile_channels) == 2 && ~skip_existing
		temp = load_file(resultfile_channels)';
		channels = ft_channelselection([channels_wo_face temp], data);
		disp('Channel rejection file found, showing data incorporating previous rejections.')
	end
		
	[~,name,~] = fileparts(files{iFile});
	disp(['Showing file ' name])
	cfg                     = [];
	cfg.method              = 'summary';
	cfg.layout              = 'egi_corrected.sfp';
	cfg.channel             = channels;
	cfg.keeptrial			= 'nan';
	cfg.alim                = 1e-12;
	data_rej = ft_rejectvisual(cfg, data);       
	
	% Gather and save trials that should be checked as well as rejected channels
	check_trial = []; 
	for iTrial = 1:numel(data_rej.trial)
		if isnan(data_rej.trial{iTrial}(1))
			check_trial = [check_trial iTrial]; 
		end
	end
	realsave(fullfile(path_result_trials, [data.id '_suspicioustrials.mat']), check_trial);

	all_chans = ft_channelselection(channels_wo_face, data);
	rejected = ~ismember(all_chans, data_rej.label);
	rejected_channel = strcat('-', all_chans(rejected)); 
	realsave(resultfile_channels, rejected_channel);
	
	disp(['Saved ' num2str(numel(check_trial)) ' suspicious trials and ' num2str(numel(rejected_channel)) ' rejected channels for ' data.id ' (' rejected_channel{:} ').'])
	close all
end

%% ------     CHANNEL REJECTION
% rejects face channels plus the ones noted in the previous step
paths.sl_chanreject         = enpath(fullfile(paths.sl_artreject, 'chans_rejected'));
path_result                 = paths.sl_chanreject;
path_origin                 = paths.sl_artreject;

files                       = get_filenames(path_origin, 'full');
parpool('local', 4)
parfor iFile = 1:numel(files)
	data                = load_file(files{iFile});
	
	% Do the rejection only if the dataset has already been processed in
	% the last step
	filename = get_filenames(paths.sl_suspchannels, data.id, 'full');
	if isempty(filename), warning(['No list of suspicous channels available for ' data.id '. Skipping...']), continue, end
	
	rejchannel          = load_file(filename); % from previous visual summary step
	cfg                 = [];
	cfg.channel         = {channels_wo_face_with_eog{:}, rejchannel{:}};
	data_rej            = ft_selectdata(cfg, data);
	
	data_rej.id = data.id;
	[~,name,~] = fileparts(files{iFile});
	realsave(fullfile(path_result, [name '_chrej.mat']), data_rej);
	%clear data_rej data
end

%% ------     ICA   (for remaining ECG and EOG artifacts)		-  QSUB: RUN ON HEAD NODE!
% http://www.fieldtriptoolbox.org/example/use_independent_component_analysis_ica_to_remove_eog_artifacts
% rc_componentanalysis prepares the data (downsampling and high-pass
% filtering) before doing the actual ICA.
paths.sl_ica                = enpath(fullfile(paths.sl_chanreject, 'ica'));

path_origin                 = paths.sl_chanreject;
path_result                 = paths.sl_ica;
files                       = get_filenames(path_origin, 'full');

% files_to_process			= 1:numel(files);
files_to_process = [47];
cfg = {}; 
for iFile = files_to_process %1:numel(files)
	[~, name, ~]            = fileparts(files{iFile});	
	cfg{iFile}              = [];
	cfg{iFile}.in			= files{iFile};
	cfg{iFile}.out			= fullfile(path_result, [name, '_ica.mat']);
	cfg{iFile}.resamplefs   = 500;
	cfg{iFile}.hpfreq		= 1;
% 	cfg{iFile}.padding		= 600;
end
cfg = cfg(files_to_process);

% On a single node
for iEntry = 1:numel(cfg)
	rc_componentanalysis(cfg{iEntry});
end

% Using qsub
addpath(abpath(fullfile(path_root, 'fieldtrip', 'qsub')))
cd(abpath(fullfile(path_root, '/../qsub')))
qsubcellfun(@rc_componentanalysis, cfg, 'matlabcmd', '/usr/local/MATLAB/R2016a/bin/matlab', 'memreq', 4 * 1024^3, 'timreq', 360 * 60, 'UniformOutput', false, 'backend', 'torque', 'StopOnError', false)

%% ------     ICA VISUAL INSPECTION
% Rejection rules
% Rejected are components that show one or more of these features:
% Strict criteria (one is enough):
% 1)	lack of a 1/f behavior (especially high power plateau in high 
%		frequencies = muscles)
% 2)	strict topography around the eyes  -> EYE
% 3)	obvious heart artifacts (broad diagonal pattern) -> MISC
%
% Mild criteria (at least two necessary):
% 4)	non-stationary in time (generally chaotic or only a few but more 
%		than one high-variance peaks),
% 5)	a non-physiological time series,
% 6)	strict topography over 1 channel
% 7)    most variance from occasional large deflections -> JUMP, if:
%       - no obvious peaks in the 1/f curve, and
%		- almost no structure over the rest of the head, and
%		If they have only 1 high or small jumps, or if there is sufficient 
%		structure apart from the one channel -> STRICT.
paths.sl_rejcomponents		= enpath(fullfile(paths.sl_ica, 'suspicious_comps'));
path_origin                 = paths.sl_ica;
path_result					= paths.sl_rejcomponents;
skip_existing				= false;					
files                       = get_filenames(path_origin, 'full');
for iFile = 1:numel(files)		
	data                    = load_file(files{iFile});
	
	resultfile				= fullfile(path_result, [data.id '_rejcomponents.mat']);
	if exist(resultfile) == 2 && skip_existing, warning(['Dataset ' data.id ' has already been processed. Skipping...']), continue, end	
	
	cfg						= [];
	cfg.layout				= 'egi_corrected.sfp';
	cfg.outputfile			= resultfile;
	if exist(resultfile) == 2
		cfg.inputrej			= resultfile;
	end
	rc_icabrowser(cfg, data);
end

%% ------     ICA REJECT COMPONENTS
paths.sl_icareject			= enpath(fullfile(paths.sl_chanreject, 'ica_rejected'));

path_ica					= paths.sl_ica; % decomposed data, needed for unmixing matrix
path_comps					= paths.sl_rejcomponents; % component IDs saved by the ICA browser above
path_data					= paths.sl_chanreject; % data with artifact epochs and channels rejected (original sample rate)
path_result					= paths.sl_icareject;

files                       = get_filenames(path_ica, 'full');
for iFile = 1:numel(files)
	ica				= load_file(files{iFile});
	compsfile		= get_filenames(path_comps, ica.id, 'full');
	if isempty(compsfile), warning(['No suspicious comps found for dataset ' ica.id '. Skipping...']), continue, end	

	comps			= load(compsfile); 
	data			= load_file(path_data, ica.id); 
	
	reject_comps = find(comps.rej_comp == 1 | comps.rej_comp == 2 | comps.rej_comp == 3 | comps.rej_comp == 4);

	% Decompose the original data (as it was prior to downsampling)
	cfg                     = [];
	cfg.unmixing            = ica.unmixing;
	cfg.topolabel           = ica.topolabel;
	data_comp               = ft_componentanalysis(cfg, data);
	
	% The original data can now be reconstructed, excluding those components
	%   (It might be possible to skip the above step and call
	%   data_rej                = ft_rejectcomponent(cfg, ica, data);
	%   I asked that on the ft mailinglist .. waiting for answers.)
	cfg                     = [];
	cfg.component           = reject_comps;
	data_rej                = ft_rejectcomponent(cfg, data_comp, data);
	data_rej.id             = data.id;
	
	[~,name,~]   = fileparts(get_filenames(path_data, ica.id));
	realsave(fullfile(path_result, [name '_icarej.mat']), data_rej);
end

%% ------     LAST VISUAL CHECK & ARTIFACT REJECTION  
% Check out the resulting data (without eye and face channels), reject some
% last artifacts and manually note down additional channels to be rejected
% in the subjectdata. This results in the final clean data.
paths.sl_clean          = enpath(fullfile(paths.sl, 'clean'));

path_origin             = paths.sl_icareject;
path_arts				= paths.sl_artifacts;
path_result             = paths.sl_clean;
skip_visual				= false;

files = get_filenames(path_origin, 'full');
for iFile = 1:numel(files)
	data_rej                 = load_file(files{iFile});
	artsfile                 = get_filenames(path_arts, data_rej.id, 'full');
	arts                     = load_file(artsfile);
	
	if ~skip_visual
		% Don't show the eye channels (data_rej has channels_wo_face_with_eog, so 6 channels more)
		cfg                      = [];
		cfg.channel              = channels_wo_face;
		data_temp                = ft_selectdata(cfg, data_rej);
		
		% Visually inspect the data and save new artifacts
		% 	channel					= ft_channelselection(channels_wo_face, data_rej.label)
		cfg                     = [];
		cfg.viewmode            = 'vertical';
		cfg.channel             = data_temp.label(1:60); % check all channels though!
		temparts                = ft_databrowser(cfg, data_temp);
		
		if ~isempty(temparts.artfctdef.visual.artifact)
			arts.artfctdef.visual2  = temparts.artfctdef.visual;
			realsave(artsfile, arts, 0);
		end
		
		% Ask for further channels to reject
		suspchans_fname			= get_filenames(paths.sl_suspchannels, data_rej.id, 'full');
		suspchans				= load_file(suspchans_fname);
		suspchans_new			= inputdlg('Enter space-separated numbers (without the E):', 'Which channels to reject?', [1 50]);
		
		% Deal with new artifacts
		cfg                     = [];
		cfg.artfctdef           = arts.artfctdef;
		cfg.artfctdef.reject    = 'partial';
		cfg.artfctdef.feedback  = 'no';         % yes gives you a nice plot, maybe use one day
		data_clean              = ft_rejectartifact(cfg, data_rej);
		data_clean.id           = data_rej.id;
		
		% Deal with new artifactual channels
		if ~isempty(suspchans_new)
			% Save new channels to old suspected channel list
			suspchans_new			= strcat('-E', strsplit(suspchans_new{:}));
			input(['Adding ' [suspchans_new{:}] ' to existing suspected channels ' [suspchans{:}] '. Press Enter to confirm.']);
			suspchans				= [suspchans; suspchans_new];
			realsave(suspchans_fname, suspchans, 0);
			
			% Actually get rid of the channel in the cleaned data
			cfg                     = [];
			cfg.channel             = ft_channelselection({'all', suspchans_new{:}}, data_clean.label);
			data_clean              = ft_selectdata(cfg, data_clean);
		end
	else
		data_clean = data_rej;
		clear data_rej
	end
	
	% Keep only trials longer than a certain length
	min_length					= 2;   % minimum length of acceptable trials in seconds
	keep_trials					= true(size(data_clean.sampleinfo, 1),1);
	for iTrial = 1:size(data_clean.sampleinfo, 1)
		if data_clean.sampleinfo(iTrial, 2) - data_clean.sampleinfo(iTrial, 1) < 2 * data_clean.fsample
			keep_trials(iTrial)	= false;
		end
	end
	if any(~keep_trials) % if there are trials to be dropped
		warning(['Getting rid of ' num2str(sum(keep_trials == false)) ' trials because they are too short (<' num2str(min_length) 's).'])  
		temp_id					= data_clean.id;
		cfg                     = [];
		cfg.trials              = keep_trials; % if length(keep_trials) == length(data_clean.id), ft_selectdata will kick outl letters of that id #weird #wasfuntodebug
		data_clean				= ft_selectdata(cfg, data_clean);
		data_clean.id			= temp_id;
		clear temp_id
	elseif ~any(keep_trials) % if there are no trials to be kept
		error('No trials survived your rejection. Don''t be so harsh!')
	end
	
	% Save it
	[~,name,~]					 = fileparts(files{iFile});
	realsave(fullfile(path_result, [name '_clean.mat']), data_clean, 0);
	clear data_clean data_rej data_temp
end



%% ------     TODO: SO AND SPINDLE DETECTION
% TODO: Call spisop directly from here

%% ------     TODO: EXTRACT ODOR TRIGGERS

%% -------    TODO: QUALITY CHECKS
% TODO: print a quality check over the whole recording, incl. 
% - sleep stages in color
% - movement arousal epochs
% - each artifact type
% - detected slow oscillations and spindles
% - odor stimulations
% > check hh_plotHeadmotions for that
