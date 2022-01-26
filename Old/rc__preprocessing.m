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
% addpath(abpath('$root/fieldtrip/qsub'));
paths.rs                    = enpath(fullfile(paths.home, 'resting-state'));
paths.rs_meta               = enpath(fullfile(paths.rs, 'meta'));

% For each subject, night, and session
cfg = {}; counter = 1;
for iSj = 1:numel(subjdata)
	for iNi = 1:2
		for iSe = 1:3
			% cfg{iSj,iNi,iSe}
			cfg{counter}.dataformat                  = 'egi_mff_v2';
			cfg{counter}.headerformat                = 'egi_mff_v2';
			cfg{counter}.dataset                     = abpath(subjdata(iSj).(['rs' num2str(iSe)]){iNi});
			cfg{counter}.continuous                  = 'yes';
			
			cfg{counter}.trialfun                    = 'trialfun_rs';
			cfg{counter}.trialdef.post_start         = 4;        % secs to start after the start trigger
			cfg{counter}.trialdef.pre_end            = 4;        % secs to end before end trigger
			cfg{counter}.trialdef.segment_length     = 0;        % length of time window to cut data to (in sec)
			cfg{counter}.trialdef.explength          = 60 * 10;  % expected length of recording in sec (optional)
			cfg{counter}.trialdef.cut_breaks		 = false;	 % cut out breaks (do not if you handle them later as artifacts)
			cfg{counter}.trialdef.pre_break			 = 10;		 % secs to stop before break trigger
			cfg{counter}.trialdef.post_break		 = 10;		 % secs to start again after break trigger
			
			cfg{counter}.id                          = [subjdata(iSj).id '_n' num2str(iNi) '_rs' num2str(iSe)]; % unique recording ID for future reference
			cfg{counter}.counter					 = counter;	 % to easier find the dataset again later on
			counter = counter + 1;
		end
	end
end

% Define trials and collect all cmd window output
[T, cfg]	= evalc('cellfun(@ft_definetrial, cfg, ''UniformOutput'', false)');

% Extract all warnings from evalc's output and get rid of a common irrelevant warning
warnings	= regexp(T, 'Warning.*?(\)\.(?=\n)|(?=]))', 'match')';
warnings	= warnings(cellfun(@isempty, strfind(warnings, 'discont')));

% Load old cfgs and warnings and make sure we are not processing already processed datasets
cfg_old = load_file(fullfile(paths.rs_meta, 'rs_trialdefs'));
if ~isempty(cfg_old)
	for i=1:numel(cfg)
		if any(cellfun(@(x) strcmp(cfg{i}.id,x.id), cfg_old)), error('Datasets overlap with already processed ones!'); end
	end
end
cfg = [cfg_old cfg];	

warnings_old = load_file(fullfile(paths.rs_meta, 'rs_definetrial_warnings'))
warnings = [warnings_old warnings];

% Save the result for later inspection
realsave(fullfile(paths.rs_meta, 'rs_definetrial_warnings'), warnings)
realsave(fullfile(paths.rs_meta, 'rs_trialdefs'), cfg)

%% ------     ARTIFACT DETECTION
% Take the cfg from above to define the trials to look for artifacts in the
% data on disk. This way filter padding can be done. Creates a file for
% each entry in the preprocessing cfg that contains all artifact
% information. Every artifact procedure will save its data in this file. In
% the end they can all be rejected together.
%
% The end goal is to have pairs/triplets of preprocessed data:
% . raw data before artifact rejection ('raw')
% . an artifact definition for each data set ('artifacts')
% . artifact-free data that was also ICA-cleaned ('clean')
% Further preprocessing (e.g. face-channel rejection, re-referencing) will
% be done in the respective follow-up pipeline.
cfg							= load_file(fullfile(paths.rs_meta, 'rs_trialdefs'));
paths.rs_artifacts          = enpath(fullfile(abpath(paths.rs), 'artifacts'));
delete_existing_arts		= false;

% --------------- Set up artifact structure ---------------
path_result                 = paths.rs_artifacts;
for iEntry = 1:numel(cfg)
	cfg_art                 = [];
	cfg_art.id              = cfg{iEntry}.id;
	cfg_art.continuous      = 'yes';
	cfg_art.trl             = cfg{iEntry}.trl;
	cfg_art.dataset         = cfg{iEntry}.dataset;
	cfg_art.artfctdef       = [];
    
	% Load potential existing artifact definitions and take over artifacts
	temp = get_filenames(paths.rs_artifacts, cfg{iEntry}.id, 'full');
	if ~isempty(temp) && ~delete_existing_arts
		disp(['Taking over existing artifacts (' cfg{iEntry}.id ').'])
		temp = load_file(temp);
        if isfield(temp, 'artfctdef')
            cfg_art.artfctdef = temp.artfctdef;
        end
	end
	
	realsave(fullfile(path_result, [cfg{iEntry}.id, '.mat']), cfg_art)
end

% --------------- Breaks (trigger-based) ---------------
path_arts                   = paths.rs_artifacts;
pre_break					= 8; % how long before break triggers should we stop (in sec)
post_break					= 6; % how long after break triggers should we start again (in sec)
for iEntry = 1:numel(cfg)
	
	% Load triggers
	events								= ft_read_event(abpath(cfg{iEntry}.headerfile));
	hdr									= ft_read_header(abpath(cfg{iEntry}.headerfile));
	
	% Extract breaks (after some sanity checks)
	artfctdef = [];
	trigger_break		= events(strcmp('6___', {events.value}));
	if numel(trigger_break) ~= 0 % TODO: That should be done without a loop
		for i = 1:numel(trigger_break)
			if ~strcmp(trigger_break(i).orig.label, 'RS Interruption')
				error('Some identified break triggers weren''t actually ones. Please check! (%s, counter %s).\n', cfg{iEntry}.id, num2str(iEntry))
			end
		end
		temp_list = '(min:';
		for i = 1:numel(trigger_break)
			temp_list = [temp_list ' ' num2str(trigger_break(i).sample / (hdr.Fs * 60))];
		end
		temp_list = [temp_list ')'];
		warning('There were break triggers in the recording %s. You might wanna check if we cut the recording properly (%s, counter %s).\n', temp_list, cfg{iEntry}.id, num2str(iEntry))
		
		breaks		= [trigger_break.sample];
		for iBreak = 1:numel(breaks)
			artfctdef(iBreak,:) = [breaks(iBreak)-pre_break*hdr.Fs breaks(iBreak)+post_break*hdr.Fs];
		end
	end
	
	% Load potential existing artifact definitions and take over
	% everything but break artifacts
	filename = get_filenames(path_arts, cfg{iEntry}.id, 'full');
	if ~isempty(filename)
		disp('Taking over existing non-break artifacts.')
		cfg_art = load_file(filename);
		if isfield(cfg_art, 'artfctdef') && isfield(cfg_art.artfctdef, 'breaks'), cfg_art.artfctdef = rmfield(cfg_art.artfctdef, 'breaks'); end
	else
		error('No artifact structure found.')
	end
	
	cfg_art.artfctdef.breaks.artifact                    = artfctdef; % add interesting parts of current detection
	realsave(filename, cfg_art, 0)
end

% --------------- Muscle (automatic, z-value-based) ---------------
path_arts                 = paths.rs_artifacts;
for iEntry = 1:numel(cfg)
	
	% Load potential existing artifact definitions and take over
	% everything but zvalue artifacts
	filename = get_filenames(paths.rs_artifacts, cfg{iEntry}.id, 'full');
	if ~isempty(filename)
		disp('Taking over existing non-zvalue artifacts.')
		cfg_art = load_file(filename);
		if isfield(cfg_art, 'artfctdef') && isfield(cfg_art.artfctdef, 'zvalue'), cfg_art.artfctdef = rmfield(cfg_art.artfctdef, 'zvalue'); end
	else
		error('No artifact structure found.')
	end
	
	% Settings
	cfg_art.dataset						 = abpath(cfg_art.dataset);
	cfg_art.artfctdef.zvalue.channel     = channels_wo_face; % dont incorporate artifact-prone frontal channels
	cfg_art.artfctdef.zvalue.cutoff      = 6;
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
	
	% Lets do the artifact detection and collect all important information
	% in one structure
	disp(['Showing you data with ID: ' cfg{iEntry}.id '.'])
	arts                                 = ft_artifact_zvalue(cfg_art); % the second output equals cfg.artfctdef.zvalue.artifact
	
	cfg_art.artfctdef                    = arts.artfctdef; % add interesting parts of current detection
	realsave(filename, cfg_art, 0)
end

% --------------- Visual (databrowser) ---------------
% This should be always the last step after all automatic artifact
% detection algorithms. If artifacts of the type "visual2" are shown, they
% come from a post-ica check of an earlier run
path_arts                   = paths.rs_artifacts;
for iEntry = 1:numel(cfg)
	% Load potential existing artifact definitions and take over
	% everything but zvalue artifacts
	filename = get_filenames(path_arts, cfg{iEntry}.id, 'full');
	if ~isempty(filename)
		disp('Taking over existing artifacts.')
		arts = load_file(filename);
	else
		error('No artifact structure found.')
	end
	
	% Load data (makes handling in databrowser easier)
	cfg_t                   = [];
	cfg_t.dataset           = abpath(arts.dataset);
	cfg_t.channel           = channels_wo_face;     % without artifact-prone channels
	data                    = ft_preprocessing(cfg_t);
	
	cfg_art                 = rmfield(arts, 'dataset'); % copy artifacts without dataset field
	cfg_art.viewmode        = 'vertical';
	cfg_art.channel         = 1:4:110;     % show some random channels
	cfg_art.blocksize       = 200;
	cfg_art.ylim            = [-120 120];
	cfg_art.selectmode      = 'markartifact';
	cfg_art.preproc.demean  = 'yes';
	cfg_art.preproc.detrend = 'yes';
	cfg_art.event           = ft_read_event(abpath(arts.dataset));
	disp(['Showing you data with ID: ' cfg_art.id '.'])
	cfg_art                 = ft_databrowser(cfg_art, data);
	
	arts.artfctdef			= cfg_art.artfctdef; % put the result in our existing artifact structure
	
	% Put the artifact file back where it came from
	realsave(filename, arts, 0);
end

%% -------    ARTIFACT REJECTION and PREPROCESSING 
% We will use all discovererd artifacts, combine them, and cut them out. 
paths.rs_artreject          = enpath(fullfile(abpath(paths.rs), 'arts_rejected'));
path_origin                 = paths.rs_artifacts;
path_result                 = paths.rs_artreject;

files                       = get_filenames(path_origin, 'full'); 
parpool('local', 6) % delete(gcp('nocreate'))
parfor iFile = 1:numel(files)
	cfg                     = load_file(files{iFile});
	cfg.dataset				= abpath(cfg.dataset);
	cfg.artfctdef.reject    = 'partial';
	cfg.artfctdef.feedback  = 'no';         % yes gives you a nice plot, maybe use one day
	cfg                     = ft_rejectartifact(cfg);
	
	% "Preprocess" the data while getting rid of the reference channel
	% (full of zeros) which creates a problem during later ICA
    cfg.channel              = {'all', '-VREF'};
    cfg.bpfilter             = 'yes';
	cfg.bpfreq               = [0.2 180];
	cfg.bpfilttype           = 'fir';
	cfg.bpfiltdir            = 'twopass';
	cfg.padding              = 600;     % = maximal length of trial used for filtering = expected length of recording (its very long for most trials, but we dont know the trial length yet)
    data                     = ft_preprocessing(cfg);
	
	data.id = cfg.id;
	realsave(fullfile(path_result, [data.id, '_' num2str(cfg.bpfreq(1)) '-' num2str(cfg.bpfreq(2)) '_artrej.mat']), data);
end

%% ------     VISUAL SUMMARY AND CHANNEL INSPECTION ON ART-REJECTED DATA
% Single channels or trials may still go haywire. The following procedure
% gives better insight into the data and helps gathering a list of a)
% channels that will be rejected in the next step (before ICA because they
% can lead to problems there), b) trials that should be particularly
% checked during post-ICA visual inspection. No actual data is rejected
% here.
%
% REJECTION RULES: Here we reject CHANNELS with very high variance, if its
% not just one trial that brings the variance up. In that case the trial is
% marked. If a channel is still bad after that, it finally is rejected.
% Rejected channels and trials are automatically noted in separate files
% (one per dataset). Channels will be excluded before the ICA, trials will
% remain in the data (because in this step we cannot know if a trial is 5
% seconds or half the dataset) and reviewed during the last post-ICA visual
% check.
%
% During later processing steps we may reject an additional fixed set of
% channels for which we do not expect usable data (e.g. face channels for
% source localization).
paths.rs_suspchannels		= enpath(fullfile(paths.rs_meta, 'suspicious_channels'));
paths.rs_susptrials			= enpath(fullfile(paths.rs_meta, 'suspicious_trials'));

skip_existing				= false;
path_origin                 = paths.rs_artreject;
path_result                 = paths.rs_suspchannels;
path_result_trials			= paths.rs_susptrials;
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
paths.rs_chanreject         = enpath(fullfile(paths.rs_artreject, 'chans_rejected'));
path_result                 = paths.rs_chanreject;
path_origin                 = paths.rs_artreject;

files                       = get_filenames(path_origin, 'full');
parpool('local', 6)
parfor iFile = 1:numel(files)
	data                = load_file(files{iFile});
	
	% Do the rejection only if the dataset has already been processed in
	% the last step
	filename = get_filenames(paths.rs_suspchannels, data.id, 'full');
	if isempty(filename), warning(['No list of suspicous channels available for ' data.id '. Skipping...']), continue, end
	
	rejchannel          = load_file(filename); % from previous visual summary step
	cfg                 = [];
	cfg.channel         = {channels_wo_face_with_eog{:}, rejchannel{:}};
	data_rej            = ft_selectdata(cfg, data);
	
	data_rej.id = data.id;
	[~,name,~] = fileparts(files{iFile});
	realsave(fullfile(path_result, [name '_chrej.mat']), data_rej);
	clear data_rej data
end

%% ------     QSUB: ICA   (for remaining ECG and EOG artifacts)		-  RUN ON HEAD NODE!
% http://www.fieldtriptoolbox.org/example/use_independent_component_analysis_ica_to_remove_eog_artifacts
% rc_componentanalysis prepares the data (downsampling and high-pass
% filtering) before doing the actual ICA.
paths.rs_ica                = enpath(fullfile(paths.rs_chanreject, 'ica'));

path_origin                 = paths.rs_chanreject;
path_result                 = paths.rs_ica;
files                       = get_filenames(path_origin, 'full');

files_to_process			= [45 46 47 48 74 75 76 77] % 133:numel(files);
cfg = {}; 
for iFile = files_to_process %1:numel(files)
	[~, name, ~]            = fileparts(files{iFile});	
	cfg{iFile}              = [];
	cfg{iFile}.in			= files{iFile};
	cfg{iFile}.out			= fullfile(path_result, [name, '_ica.mat']);
	cfg{iFile}.resamplefs   = 500;
	cfg{iFile}.hpfreq		= 1;
	cfg{iFile}.padding		= 600;
end
cfg = cfg(files_to_process);

% On a single node
for iEntry = 1:numel(cfg)
	rc_componentanalysis(cfg{iEntry});
end

% Using qsub
% addpath(abpath(fullfile(path_root, 'fieldtrip', 'qsub')))
% cd(abpath(fullfile(path_root, '/../qsub')))
% qsubcellfun(@rc_componentanalysis, cfg, 'matlabcmd', '/usr/local/MATLAB/R2016a/bin/matlab', 'memreq', 4 * 1024^3, 'timreq', 360 * 60, 'UniformOutput', false, 'backend', 'torque', 'StopOnError', false)

%% ------     ICA VISUAL INSPECTION
% Rejection rules
% Rejected are components that show one or more of these features:
% 1)	lack of a 1/f behavior (especially high power plateau in high 
%		frequencies = muscles)
% 2)	strict topography around the eyes  -> EYE
% 3)	obvious heart artifacts (broad diagonal pattern) -> MISC
% 4)	non-stationary in time (generally chaotic or only a few but more 
%		than one high-variance peaks), but only if at least a trend for 
%		one of the other rules
% 5)	a non-physiological time series.
% 6)	Those components with strict topography over 1 channel, which get
%		most of their variance from occasional large deflections, are  
%		rejected as JUMPS if they have:
%       - no obvious peaks in the 1/f curve, and
%		- almost no structure over the rest of the head, and
%		- more than one jump over a variance of 2 distributed across the 
%		  recording, so that you cannot cut them out visually later
%		- ...while one of above critera can be violated if the time series
%		  looks particularly brutal.
%		If they have only 1 high or small jumps, or if there is sufficient 
%		structure apart from the one channel, they go to STRICT.

paths.rs_rejcomponents		= enpath(fullfile(paths.rs_ica, 'suspicious_comps'));
path_origin                 = paths.rs_ica;
path_dataeog                = paths.rs_downsampled;
path_result					= paths.rs_rejcomponents;
skip_existing				= false;					
files                       = get_filenames(path_origin, 'full');
for iFile = 1:numel(files)		
	data                    = load_file(files{iFile});
	
	resultfile				= fullfile(path_result, [data.id '_rejcomponents.mat']);
	if exist(resultfile) == 2 && skip_existing, warning(['Dataset ' data.id ' has already been processed. Skipping...']), continue, end	
	if exist(resultfile) == 2 && ~skip_existing, warning(['Dataset ' data.id ' has already been processed, taking over suspicious components...']), end	
	
	cfg						= [];
	cfg.layout				= 'egi_corrected.sfp';
	cfg.outputfile			= resultfile;
	if exist(resultfile) == 2
		cfg.inputrej			= resultfile;
	end
	rc_icabrowser(cfg, data);
end

%% ------     ICA REJECT COMPONENTS
paths.rs_icareject			= enpath(fullfile(paths.rs_chanreject, 'ica_rejected'));

path_ica					= paths.rs_ica; % decomposed data, needed for unmixing matrix
path_comps					= paths.rs_rejcomponents; % component IDs saved by the ICA browser above
path_data					= paths.rs_chanreject; % data with artifact epochs and channels rejected (original sample rate)
path_result					= paths.rs_icareject;

files                       = get_filenames(path_ica, 'full');

parpool('local', 6)
files = files([45 46 47 48 43 44 97 74 75 76 77 98 99]);
parfor iFile = 1:numel(files)
	ica				= load_file(files{iFile});
	compsfile		= get_filenames(path_comps, ica.id, 'full');
	if isempty(compsfile), warning(['No suspicious comps found for dataset ' ica.id '. Skipping...']), continue, end	

	data			= load_file(path_data, ica.id); 
	comps			= load(compsfile); 
	
	% Reject all artifacts that are of category 1-4 (5 being "strict")
	reject_comps = find(comps.rej_comp == 1 | comps.rej_comp == 2 | comps.rej_comp == 3 | comps.rej_comp == 4);

	% Decompose the original data (as it was prior to downsampling)
	cfg                     = [];
	cfg.unmixing            = ica.unmixing;
	cfg.topolabel           = ica.topolabel;
	data_comp               = ft_componentanalysis(cfg, data);
	
	% The original data can now be reconstructed, excluding those components
	%   (It might be possible to skip the above step and call
	%   data_rej                = ft_rejectcomponent(cfg, ica, data);
	%   I asked that on the ft mailinglist .. no answers.)
	cfg                     = [];
	cfg.component           = reject_comps;
	data_rej                = ft_rejectcomponent(cfg, data_comp, data);
	data_rej.id             = data.id;
	
	[~,name,~]   = fileparts(get_filenames(path_data, ica.id));
	realsave(fullfile(path_result, [name '_icarej.mat']), data_rej);
end

%% ------     ICA STATISTICS
path_comps					= paths.rs_rejcomponents; % component IDs saved by the ICA browser above
files                       = get_filenames(path_comps, 'full');

allcomps = nan(numel(files)/6,6);
for iFile = 1:numel(files)
		comps			= load(get_filenames(path_comps, iFile, 'full')); 
		no_comps		= numel(find(comps.rej_comp == 1 | comps.rej_comp == 2 | comps.rej_comp == 3 | comps.rej_comp == 4));
		allcomps(floor((iFile-1) / size(allcomps, 2))+1, mod((iFile-1), size(allcomps, 2))+1) = no_comps;	
end

means_n1	= [mean(allcomps(:,1)), mean(allcomps(:,2)), mean(allcomps(:,3))];
means_n2	= [mean(allcomps(:,4)), mean(allcomps(:,5)), mean(allcomps(:,6))];
err_n1		= [std(allcomps(:,1)), std(allcomps(:,2)), std(allcomps(:,3))] / sqrt(size(allcomps, 1));
err_n2		= [std(allcomps(:,4)), std(allcomps(:,5)), std(allcomps(:,6))] / sqrt(size(allcomps, 1));

errorbar(1:3, means_n1, err_n1), hold; errorbar(1:3, means_n2, err_n2)
ylim([0 max([means_n1 means_n2]+10)])

%% ------     LAST VISUAL CHECK & ARTIFACT REJECTION  
% Check out the resulting data (without eye and face channels), reject some
% last artifacts and manually note down additional channels to be rejected
% in the subjectdata. This results in the final clean data.
paths.rs_clean          = enpath(fullfile(paths.rs, 'clean'));

path_origin             = paths.rs_icareject;
path_arts				= paths.rs_artifacts;
path_result             = paths.rs_clean;
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
		cfg.ylim				= [-35 35];
		cfg.continuous			= 'yes';
		cfg.blocksize			= 100;
		cfg.channel             = data_temp.label(1:30); % check all channels though (e.g. on the way back)!
		cfg.artfctdef			= arts.artfctdef;
		cfg.selectfeature		= 'visual2';
		temparts                = ft_databrowser(cfg, data_temp);
		clear data_temp
		
		if ~isempty(temparts.artfctdef.visual2.artifact)
			arts.artfctdef.visual2  = temparts.artfctdef.visual2;
			realsave(artsfile, arts, 0);
		end
		
		% Ask for further channels to reject
		suspchans_fname			= get_filenames(paths.rs_suspchannels, data_rej.id, 'full');
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
		if ~isempty(suspchans_new{:})
			% Save new channels to old suspected channel list
			suspchans_new			= strcat('-E', strsplit(suspchans_new{:}));
			warning(['Adding ' [suspchans_new{:}] ' to existing suspected channels ' [suspchans{:}] '.']);
			suspchans				= [suspchans; suspchans_new'];
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
	clear data_clean 
	close all
end



%% LEGACY CODE

%% OLD ICA INSPECTION

% components{1}               = 1:20;
% components{2}               = 21:40;
% components{3}               = 41:60;
% components{4}               = 61:80; % further components are inspected by timeline only

for iFile = 1:numel(files)
	data                     = load_file(files{iFile});
	data_eog                 = load_file(path_dataeog, data.id);
	
	
	% 	% Eye channel correlation
	% 	% Currently does not work: https://github.com/fieldtrip/fieldtrip/commit/e9cd4d8b41caa901a76be52c76fd058d85e7f17a#commitcomment-23138752
	%     for iFake = 1       % just so we can fold it
	%         cfg                     = [];
	%         cfg.reref               = 'yes';
	%
	%         cfg.channel             = {'E25', 'E8'};
	%         cfg.refchannel          = 'E25';
	%         data_eogh               = ft_preprocessing(cfg, data_eog);
	%         chidx                   = find(strcmp(data_eogh.label, 'E8'));
	%         data_eogh.label{chidx}  = 'EOG_H';
	%
	%         cfg.channel             = {'E14', 'E126'};
	%         cfg.refchannel          = 'E14';
	%         data_eogv               = ft_preprocessing(cfg, data_eog);
	%         chidx                   = find(strcmp(data_eogv.label, 'E126'));
	%         data_eogv.label{chidx}  = 'EOG_V';
	%
	%         cfg                     = [];
	%         cfg.channel             = {'EOG_H'};
	%         data_eogh                = ft_selectdata(cfg, data_eogh);
	%         cfg.channel             = {'EOG_V'};
	%         data_eogv                = ft_selectdata(cfg, data_eogv);
	%
	%         data_app                = ft_appenddata([], data_eogv, data_eogh, data)
	%
	%         cfg                     = [];  % lets cut the data in 4s-trials to calculate coherence
	%         cfg.length              = 4;
	%         data_red                = ft_redefinetrial(cfg, data_app)
	%
	%         cfg                     = [];
	%         cfg.method              = 'mtmfft';
	%         cfg.output              = 'fourier';
	%         cfg.foi                 = [0.4:0.2:2];
	%         cfg.taper               = 'hanning';
	%         cfg.pad                 = 'maxperlen';
	%         freq                    = ft_freqanalysis(cfg, data_red);
	%
	%         cfg                     = [];
	%         cfg.channelcmb          = {'all' 'EOG_V'; 'all' 'EOG_H'};
	%         cfg.method              = 'coh';
	%         %     cfg.complex             = 'real';   % because zero-lag connectivity will be represented in the real part of coherence
	%         fdcomp                  = ft_connectivityanalysis(cfg, freq);
	%
	%         % Lets separate the PPCs with one and the other channel and plot them in order
	%         spctrm_a        = abs(fdcomp.cohspctrm(strcmp(fdcomp.labelcmb(:,2), 'EOG_V')));
	%         spctrm_labels_a = (fdcomp.labelcmb(strcmp(fdcomp.labelcmb(:,2), 'EOG_V')));
	%         spctrm_b        = abs(fdcomp.cohspctrm(strcmp(fdcomp.labelcmb(:,2), 'EOG_H')));
	%         spctrm_labels_b = (fdcomp.labelcmb(strcmp(fdcomp.labelcmb(:,2), 'EOG_H')));
	%         [~,a]           = sort(mean(spctrm_a,2), 'descend'); % get sorted indices
	%         [~,b]           = sort(mean(spctrm_b,2), 'descend');
	%
	%         % Show the coherence values for both EOG channels
	%         clear labels_a values_a labels_b values_b
	%         for i = 1:numel(a)
	%             labels_a{i} = spctrm_labels_a{a(i)};    % labels in order
	%             values_a(i) = spctrm_a(a(i));           % values in order
	%         end
	%         for i = 1:numel(b)
	%             labels_b{i} = spctrm_labels_b{b(i)};
	%             values_b(i) = spctrm_b(b(i));
	%         end
	%
	%         figure
	%         subplot(2,2,1)
	%         bar(values_a(1:15))
	%         set(gca,'xticklabel',labels_a(1:15))
	%         set(gca,'XTickLabelRotation', 90);
	%         title('Top 15 Coh with EOG_V')
	%
	%         subplot(2,2,3)
	%         bar(values_b(1:15))
	%         set(gca,'xticklabel',labels_b(1:15))
	%         set(gca,'XTickLabelRotation', 90);
	%         title('Top 15 Coh with EOG_H')
	%
	%         subplot(2,2,2)
	%         bar(values_a)
	%         title('All Coh with EOG_V')
	%
	%         subplot(2,2,4)
	%         bar(values_b)
	%         title('All Coh with EOG_H')
	%
	%         set(gcf, 'Position', get(0,'Screensize')); % maximize figure
	%     end
	
	% Plot 20 components at a time (topos, timelines, eog channels)
	for iComps = 1:numel(components)
		for i =1 % just so we can fold it
			% Plot topoplots
			figure
			cfg                         = [];
			cfg.component               = components{iComps};  % specify the component(s) that should be plotted
			cfg.layout                  = 'egi_corrected.sfp'; % specify the layout file that should be used for plotting
			cfg.comment                 = 'no';
			cfg.marker                  = 'off';
			cfg.gridscale               = 200;
			ft_topoplotIC(cfg, data);
			h{1} = gcf;
			
			screen                      = get(0, 'ScreenSize');
			borders                     = get(gcf,'OuterPosition') - get(gcf,'Position');
			edge                        = -borders(1)/2;
			pos_topo                    =   [edge,...                 % from left
				35,...                    % from bottom
				screen(3)/2 - 100 - edge,...    % width
				screen(4)-40];            % height
			set(h{1},'OuterPosition', pos_topo)
			
			% Plot timelines
			cfg                         = [];
			cfg.viewmode                = 'component';
			cfg.ylim					= [-7 7];
			cfg.layout                  = 'egi_corrected.sfp';
			cfg.channel                 = components{iComps};
			cfg.blocksize               = 12;
			ft_databrowser(cfg, data);
			h{2} = gcf;
			
			borders                     = get(gcf,'OuterPosition') - get(gcf,'Position');
			edge                        = -borders(1)/2;
			pos_compo                   =   [pos_topo(1) + pos_topo(3) + edge,...
				screen(4)/4 + 10,...
				screen(3)/2 + 100 - edge,...
				screen(4)*3/4 - 10];
			set(h{2},'OuterPosition',pos_compo), for t = 1:50000, t; end, pause(0.2);
			set(h{2},'OuterPosition',pos_compo)
			
			% Plot EOG timelines
			cfg_eog                    = [];
			cfg_eog.layout             = 'egi_corrected.sfp';
			cfg_eog.ylim               = [-80 80];
			cfg_eog.viewmode           = 'vertical';
			cfg_eog.channel            = {'EOG_V', 'EOG_H'};
			cfg_eog.blocksize          = 12;
			ft_databrowser(cfg_eog, data_app); % pause(0.4)
			h{3} = gcf;
			
			borders                     = get(h{3},'OuterPosition') - get(h{3},'Position');
			edge                        = -borders(1)/2;
			pos_peri                    = [pos_topo(1) + pos_topo(3) + edge + 65,...     % from left
				35,...                                       % from bottom
				screen(3)/2 - edge + 100 - 65,...            % width
				screen(4)/4 - 25];                           % height
			set(h{3},'OuterPosition',pos_peri)
			for t = 1:50000, t; end
			set(h{3},'OuterPosition',pos_peri)
			for t = 1:50000, t; end
			set(h{3},'OuterPosition',pos_peri)
			for t = 1:50000, t; end, pause(0.2);
			
			set(h{3},'OuterPosition',pos_peri)
			for t = 1:50000, t; end
			set(h{3},'OuterPosition',pos_peri)
			for t = 1:50000, t; end
			set(h{3},'OuterPosition',pos_peri)
			
			disp(['Showing file ' get_filenames(path_origin, iFile)])
			set(h{3},'OuterPosition',pos_peri)
			
			input('Press ENTER to go on.')
			close(h{1}); close(h{2}); close(h{3}); clear h
		end
	end
	%clear data_eogh data_eogv data_eog data data_red freq fdcomp data_app data_red
end

%% ------     PREPROCESSING          -  STILL NECESSARY?
% addpath(abpath(fullfile(path_root, 'fieldtrip', 'qsub')))
% cfg = load_file(fullfile(paths.rs_meta, 'rs_trialdefs'));
% 
% cd(abpath(fullfile(path_root, '/../qsub')))
% 
% qsubcellfun('ft_preprocessing', cfg, 'matlabcmd', '/usr/local/MATLAB/R2015b/bin/matlab', 'memreq', 6 * 1024^3, 'timreq', 360 * 60, 'UniformOutput', false, 'backend', 'torque', 'StopOnError', false)

% parpool('local', 3);
% for i=1:numel(cfg_row)
%     cfg_row(i).dataset  = abpath(cfg_row(i).dataset);
%     cfg_row(i).writeto  = abpath(cfg_row(i).writeto);
%     data                = ft_preprocessing(cfg_row(i));
%     data.id             = cfg_row(i).id;       % note the recording ID
%     realsave(cfg_row(i).writeto, data);
% end

%% ------     VISUAL (databrowser)   - CURRENTLY NOT DONE - KEEP IT OUT?
% This should be always the last step after all automatic artifact
% detection algorithms
% path_origin                 = paths.rs_artifacts;
% files                       = get_filenames(path_origin, 'full'); % we'll doublecheck all previously collected artifacts
% for iFile = 1:numel(files)
%     
%     disp('Taking over existing artifacts.')
%     cfg_art = load_file(files{iFile});
%     arts = cfg_art;         % we need this later to turn back all changes we made along the way
%     
% 	% Load data to rename the channels; unfortunately the channel order
% 	% cannot be changed
% 	cfg_t                   = [];
% 	cfg_t.dataset           = abpath(arts.dataset);
% 	cfg_t.channel           = channels_wo_face;     % without artifact-prone channels
% 	data                    = ft_preprocessing(cfg_t);
% 	
% 	cfg_art                  = rmfield(cfg_art, 'dataset'); % needs to be gone if data is provided
% 	cfg_art.viewmode         = 'vertical';
% 	cfg_art.channel          = 20:3:100;     % show some random channels
% 	cfg_art.blocksize        = 30;
% 	cfg_art.ylim             = [-120 120];
% 	cfg_art.selectmode       = 'markartifact';
% 	cfg_art.preproc.demean   = 'yes';
% 	cfg_art.preproc.detrend  = 'yes';
% 	cfg_art.event            = ft_read_event(abpath(arts.dataset));
% 	disp(['Showing you data with ID: ' arts.id '.'])
% 	cfg_art                  = ft_databrowser(cfg_art, data);
% 	
% 	arts.artfctdef           = cfg_art.artfctdef; % put the result in our artifact structure
% 	
% 	% Put the artifact file back where it came from
% 	realsave(files{iFile}, arts, 0);
% end

%% OTHER
%     data.label(strcmp(data.label, 'E8'))    = {'EOG1'}; % hope these channel names are correct
%     data.label(strcmp(data.label, 'E127'))  = {'EOG2'};
%     data.label(strcmp(data.label, 'E43'))   = {'EMG1'};
%     data.label(strcmp(data.label, 'E120'))  = {'EMG2'};
%     data.label(strcmp(data.label, 'E24'))   = {'F3'};
%     data.label(strcmp(data.label, 'E124'))  = {'F4'};
%     data.label(strcmp(data.label, 'E36'))   = {'C3'};
%     data.label(strcmp(data.label, 'E104'))  = {'C4'};
%     data.label(strcmp(data.label, 'E45'))   = {'T3'};
%     data.label(strcmp(data.label, 'E108'))  = {'T4'};
%     data.label(strcmp(data.label, 'E52'))   = {'P3'};
%     data.label(strcmp(data.label, 'E92'))   = {'P4'};
%     data.label(strcmp(data.label, 'E15'))   = {'E15front'};
%     data.label(strcmp(data.label, 'E75'))   = {'Oz'};
%     data.label(strcmp(data.label, 'E58'))   = {'T5'};
%     data.label(strcmp(data.label, 'E96'))   = {'T6'};

%
% comps                   = [];
% comps.eyes              = [1 5];   % components that most certainly eye movments
% comps.eyes_hard         = [12 22]; % additional components that are probably eye artifacts
% comps.heart             = [35];
% comps.other             = [11 14 17 19 70];
% realsave(fullfile(paths.ica_rejectcomps, 'data_01_n1_rs1_0.2-140hz_rjctd_300hz_ica.mat'), comps);
%
% comps                   = [];
% comps.eyes              = [2 5 8 10 11 14 16 24 25 28 33 37 39 41 51 57 58];
% comps.eyes_hard         = [9 22 26 29 38 42 44 47 50];
% comps.heart             = [59];
% comps.other             = [6 23 46];
% realsave(fullfile(paths.ica_rejectcomps, 'data_01_n1_rs2_0.2-140hz_rjctd_300hz_ica.mat'), comps);
%
% comps                   = [];
% comps.eyes              = [12 28];
% comps.eyes_hard         = [33];
% comps.heart             = [39];
% comps.other             = [9 45];
% realsave(fullfile(paths.ica_rejectcomps, 'data_01_n1_rs3_0.2-140hz_rjctd_300hz_ica.mat'), comps);
%
% comps                   = [];
% comps.eyes              = [2 9 10 27 36];
% comps.eyes_hard         = [8 47];
% comps.heart             = [38];
% comps.other             = [18 33 69];
% realsave(fullfile(paths.ica_rejectcomps, 'data_01_n2_rs1_0.2-140hz_rjctd_300hz_ica.mat'), comps);
%
% comps                   = [];
% comps.eyes              = [1 10 14];
% comps.eyes_hard         = [41];
% comps.heart             = [29];
% comps.other             = [];
% realsave(fullfile(paths.ica_rejectcomps, 'data_01_n2_rs2_0.2-140hz_rjctd_300hz_ica.mat'), comps);
%
% comps                   = [];
% comps.eyes              = [3 5 10 24];
% comps.eyes_hard         = [21];
% comps.heart             = [44];
% comps.other             = [];
% realsave(fullfile(paths.ica_rejectcomps, 'data_01_n2_rs3_0.2-140hz_rjctd_300hz_ica.mat'), comps);

