%% Source localization pipeline
error('Dude, don''t just run this file...'); 1;

%% ------     FIRST-TIME SETUP
% init_rc;
% pipeline_name               = 'sourceanalysis 1.2';
% paths                       = [];
% paths.root                  = get_pathroot;
% paths.data                  = get_pathdata;
% paths.home                  = enpath(fullfile(paths.root, 'homes', pipeline_name));
% paths.headmodels            = abpath('$root/homes/headmodels 1.2');
% paths.elecs                 = fullfile(paths.headmodels, 'projected electrodes'); % already projected
% paths.grids			      = fullfile(paths.headmodels, 'subject-specific grids');
% paths.meta				  =	enpath(fullfile(paths.home, 'meta'));
% paths.sl_hypnograms		  = fullfile(paths.data, 'Hypnograms');
% saveall(paths);
    
%% ------     SETUP
% Loads all needed paths and variables into workspace
pipeline_name               = 'sourceanalysis 1.2';
paths                       = abpath(load_file(fullfile(get_pathroot, 'homes', pipeline_name, 'meta', 'paths.mat')));
subjdata                    = rc_subjectdata;
channels_min                = {'all', '-E49', '-E48', '-E43', '-E127', '-E126', '-E17', '-E128', '-E32', '-E25', '-E21', '-E14', '-E8', '-E1', '-E125', '-E120', '-E119', '-E113', '-E56', '-E63', '-E68', '-E73', '-E81', '-E88', '-E94', '-E99', '-E107', '-E57', '-E100'};
channels_min_noref			= {'all', '-VREF', '-E49', '-E48', '-E43', '-E127', '-E126', '-E17', '-E128', '-E32', '-E25', '-E21', '-E14', '-E8', '-E1', '-E125', '-E120', '-E119', '-E113', '-E56', '-E63', '-E68', '-E73', '-E81', '-E88', '-E94', '-E99', '-E107', '-E57', '-E100'};
freqs						= 2.^[-0.5:0.5:6];		% Hipp2012 did: 2.^[-0.5:0.25:7] = 25 freqs between .7 and 128 Hz	
sdf							= freqs/5.83;			% spectral SD of wavelet at a frequency when using 5.83 cycles (leading to 1/2 octave spacings)
sdt							= 1 ./ (2 * pi * sdf);	% temporal SD, e.g. at 16Hz: 1/(2*pi*(16/5.83)) = .056 s
stepsize					= sdt/2;
stepsize(stepsize < .02)	= .02; % stepsize is half a temporal SD, but not smaller than .02 s !!!! ---- ASK MARKUS SIEGEL IF THAT'S OK!! ---- !!!!!

%% ------     START WITH CLEANED DATA
% ...from the newest preprocessing home
paths.rs_clean              = fullfile(paths.root, 'homes', 'preprocessing 1.2', 'resting-state', 'clean');
paths.rs_home				= enpath(fullfile(paths.home, 'resting-state'));
paths.sl_clean              = fullfile(paths.root, 'homes', 'preprocessing 1.2', 'sleep', 'clean');
paths.sl_home				= enpath(fullfile(paths.home, 'sleep'));

%% ------     RS: CHANNEL REJECTION, RE-REFERENCING TO AVERAGE, AND DOWNSAMPLING 
path_origin             = paths.rs_clean;
path_result             = paths.rs_home;

files = get_filenames(path_origin, 'full');
for iFile = 1:numel(files)
	data                    = load_file(files{iFile});
    [s,n,~]                 = idparts(files{iFile}); % get current subject and night 
    sj                      = rc_subjectdata(s);
    
	temp_id					= data.id;
	cfg                     = [];
	cfg.channel             = {channels_min{:}, sj.channel{n}{:}};
	data                  	= ft_selectdata(cfg, data);
	data.id					= temp_id; clear temp_id
	
	cfg                     = [];
	cfg.reref               = 'yes';
	cfg.refchannel          = 'all'; % = average reference
	cfg.implicitref			= 'VREF'; % TODO: Rename this to Cz? (also in the electrode files, transfer matrices etc.)
	cfg.dftfilter			= 'yes'; % just in case later analysis frequency windows overlap with 50 Hz
	data_re                 = ft_preprocessing(cfg, data);
	data_re.id				= data.id;
	
	% Data is already filtered at 180 Hz so we can safely downsample to 500
	% samples/s	
	cfg						= [];
	cfg.resamplefs          = 500;			
	cfg.resamplemethod      = 'downsample';   % = no lpfiltering before downsampling; default: resample
	cfg.detrend             = 'no';
	data_rsmpl				= ft_resampledata(cfg, data_re);
	data_rsmpl.id			= data.id;
	
	%  	cfg=[];cfg.viewmode = 'vertical'; cfg.channel=1:3:120; ft_databrowser(cfg, data_rsmpl)
	filename = [data.id, '_prep', '.mat'];
	realsave(fullfile(path_result, filename), data_re);
end

%% ------     SL: CHANNEL REJECTION, RE-REFERENCING TO AVERAGE, AND DOWNSAMPLING
% In contrast to RS, this now includes fixing the timeline after resampling
path_origin             = paths.sl_clean;
path_result             = paths.sl_home;

files = get_filenames(path_origin, 'full');
for iFile = 1:numel(files)
	data                    = load_file(files{iFile});
    [s,n,~]                 = idparts(files{iFile}); % get current subject and night 
    sj                      = rc_subjectdata(s);
    
	temp_id					= data.id;
	cfg                     = [];
	cfg.channel             = {channels_min{:}, sj.channel{n}{:}};
	data                  	= ft_selectdata(cfg, data);
	data.id					= temp_id; clear temp_id
	
	cfg                     = [];
	cfg.reref               = 'yes';
	cfg.refchannel          = 'all'; % = average reference
	cfg.implicitref			= 'VREF'; % TODO: Rename this to Cz? (also in the electrode files, transfer matrices etc.)
	cfg.dftfilter			= 'yes'; % just in case later analysis frequency windows overlap with 50 Hz
	data_re                 = ft_preprocessing(cfg, data);
	data_re.id				= data.id;
	clear data
	
	% Let's add a channel to the data which keeps track of the samples, so
	% we can reconstruct exact sample timing later on
	data_re.label{end+1} = 'sample';
	for iTrial=1:size(data_re.sampleinfo,1)
		% this works for one or more trials
		data_re.trial{iTrial}(end+1,:) = data_re.sampleinfo(iTrial,1):data_re.sampleinfo(iTrial,2);
	end
	
	% Data is already filtered at 180 Hz so we can safely downsample to 500
	% samples/s	
 	cfg						= [];
 	cfg.resamplefs          = 500;			
 	cfg.resamplemethod      = 'downsample';   % = no lpfiltering before downsampling; default: resample
 	cfg.detrend             = 'no';
 	data_rsmpl				= ft_resampledata(cfg, data_re);
 	data_rsmpl.id			= data_re.id;
	
	% Let's correct the time array and get rid of the sample channel
	for iTrial=1:numel(data_rsmpl.time)
		data_rsmpl.time{iTrial} 	= data_rsmpl.trial{iTrial}(end, :) / data_re.fsample;
		data_rsmpl.trial{iTrial}	= data_rsmpl.trial{iTrial}(1:end-1,:);
	end
	data_rsmpl.label = data_rsmpl.label(1:end-1);  
	
	filename = [data_re.id, '_prep', '.mat'];
	realsave(fullfile(path_result, filename), data_rsmpl);
	clear data_re data_rsmpl
end

%% ------     CREATE CHANNEL LISTS FOR EACH NIGHT
% needed because one transition matrix will be created for each night, I
% want the same for all RS recordings; different ones for the sleep
% recording
paths.finalchannels_rs		= enpath(fullfile(paths.meta, 'finalchannels_rs'));
paths.finalchannels_sl		= enpath(fullfile(paths.meta, 'finalchannels_sl'));
path_result_rs				= paths.finalchannels_rs;
path_result_sl				= paths.finalchannels_sl;

for iSj = 1:numel(subjdata)
	for iNi = 1:2
		files_rs = cell(3,1); 
		
		files_rs{1} = get_filenames(paths.rs_home, [subjdata(iSj).nid{iNi}, '_rs1'], 'full');
		files_rs{2} = get_filenames(paths.rs_home, [subjdata(iSj).nid{iNi}, '_rs2'], 'full');
		files_rs{3} = get_filenames(paths.rs_home, [subjdata(iSj).nid{iNi}, '_rs3'], 'full');
		files_sl	= get_filenames(paths.sl_home, [subjdata(iSj).nid{iNi}, '_sl'], 'full');
		
		% Extract only those channels present in all datasets
		channels_rs = [];
		channels_sl = [];
		for iFile = 1:numel(files_rs)
			data                = load_file(files_rs{iFile});
			if iFile == 1
				channels_rs		= data.label;
			else
				channels_rs		= intersect(channels_rs, data.label, 'stable');
			end
			clear data
		end
		data                = load_file(files_sl);
		channels_sl			= data.label;
		clear data

% 		realsave(fullfile(path_result_rs, subjdata(iSj).nid{iNi}), channels_rs);
		realsave(fullfile(path_result_sl, subjdata(iSj).nid{iNi}), channels_sl);
	end
end
		
%% ------     PREPARE FEM HEADMODELS - CALCULATE SIMBIO TRANSFER MATRICES  	QSUB
% We cannot do it much earlier because only after a completed artifact
% rejection do we know the exact channels that we're gonna use. One cannot
% subselect channels after the transfer matrix is computed... (just
% practically, theoretically it should be possible). That also means that
% we need one transfer matrix per night.
% 
% We have to precompute the matrices due to a "bug" in Fieldtrip that
% creates the transfer matrix every time ft_sourceanalysis is executed. The
% series of calls is ft_sourceanalysis - prepare_headmodel -
% ft_prepare_vol_sens - sb_transfer.... I altered prepare_headmodel so that
% ft_prepare_vol_sens is not called again if a transfer matrix already
% exists. Here this matrix is created.
paths.headmodels_prep_rs   = enpath(fullfile(paths.meta, 'headmodels prepared rs'));
paths.headmodels_prep_sl   = enpath(fullfile(paths.meta, 'headmodels prepared sl'));
paths.elecs_prep_rs        = enpath(fullfile(paths.meta, 'electrodes prepared rs'));
paths.elecs_prep_sl        = enpath(fullfile(paths.meta, 'electrodes prepared sl'));
skip_existing	= true;

addpath(abpath('$root/fieldtrip/qsub'));
cd(abpath(fullfile(path_root, '/../qsub')))

% Create a cfg that can be handed over to a wrapper function
cnt = 1; cfg = {};
for iSj = 1:numel(subjdata)
	for iNi = 1:2
		vol_file				= get_filenames(paths.headmodels, subjdata(iSj).id, 'full');
		
% 		% Resting State
% 		elec_file				= get_filenames(paths.elecs, subjdata(iSj).id, 'full');
% 		cfg{cnt}.vol_path		= vol_file;  % we don't load this yet to save memory on the head node
% 		cfg{cnt}.elec           = load_file(elec_file); % we need to load this already to make sure the labels are correct
% 		cfg{cnt}.elec.label     = upper(cfg{cnt}.elec.label);
% 		cfg{cnt}.nid			= subjdata(iSj).nid{iNi};
% 		cfg{cnt}.channel		= load_file(paths.finalchannels_rs, subjdata(iSj).nid{iNi}); % ft_channelselection({channels_min_noref{:} subjdata(iSj).channel{iNi}{:}}, cfg{cnt}.elec)
% 		[~, vol_name, ~]        = fileparts(vol_file);
% 		[~, elec_name, ~]       = fileparts(elec_file);
% 		splitidx                = strfind(vol_name, '_');
% 		cfg{cnt}.result_vol		= fullfile(paths.headmodels_prep_rs, [subjdata(iSj).nid{iNi} vol_name(splitidx(1):end) '_prep_rs.mat']);
% 		cfg{cnt}.result_elec	= fullfile(paths.elecs_prep_rs, [subjdata(iSj).nid{iNi} elec_name(splitidx(1):end) '_prep_rs.mat']);
% 		if exist(cfg{cnt}.result_vol, 'file') && skip_existing
% 			cfg{cnt} = [];
% 		else
% 			cnt = cnt + 1;
% 		end
		
		% Sleep
		elec_file				= get_filenames(paths.elecs, subjdata(iSj).id, 'full');
		cfg{cnt}.vol_path		= vol_file;  % we don't load this yet to save memory on the head node
		cfg{cnt}.elec           = load_file(elec_file); % we need to load this already to make sure the labels are correct
		cfg{cnt}.elec.label     = upper(cfg{cnt}.elec.label);
		cfg{cnt}.nid			= subjdata(iSj).nid{iNi};
		cfg{cnt}.channel		= load_file(paths.finalchannels_sl, subjdata(iSj).nid{iNi}); 
		[~, vol_name, ~]        = fileparts(vol_file);
		[~, elec_name, ~]       = fileparts(elec_file);
		splitidx                = strfind(vol_name, '_');
		cfg{cnt}.result_vol		= fullfile(paths.headmodels_prep_sl, [subjdata(iSj).nid{iNi} vol_name(splitidx(1):end) '_prep_sl.mat']);
		cfg{cnt}.result_elec	= fullfile(paths.elecs_prep_sl, [subjdata(iSj).nid{iNi} elec_name(splitidx(1):end) '_prep_sl.mat']);
		if exist(cfg{cnt}.result_vol, 'file') && skip_existing
			cfg{cnt} = [];
		else
			cnt = cnt + 1;
		end
	end
end
if  isempty(cfg{end}), cfg(end) = [];end % #unelegantprogramming

qsubcellfun(@rc_transfermatrix, cfg, 'matlabcmd', '/usr/local/MATLAB/R2016a/bin/matlab', 'memreq', 12 * 1024^3, 'timreq', 40 * 60 * 60, 'UniformOutput', false, 'backend', 'torque', 'StopOnError', false)
cd(abpath(paths.root));

%% ------     RS: TIME-FREQUENCY TRANSFORMATION					- M
% TODO: Ask Markus if using those TFR windows is legit
% .. shouldnt we use canonical frequency windows at least during sleep? SO,
% delta, spindle fa/sl, beta?
%
% TFR parameters were mostly taken from Siems2016 / Hipp2012, for further
% explanations see mails with Marcus Siems. With a stepsize of 1/2 of a
% temporal SD and a wavelet that is estimated +/- 3 temporal SDs (gwidth),
% we expect to loose 6 steps at the beginning and end of each trial. I
% guess because of rounding sometimes at the end the last window still
% contained NaNs so I choose to drop one sample more on each side (see
% cfg.toi).
% Also joins given data sets and rearranges the result so that it looks
% like independent observations. 
paths.rs_tfr	= enpath(fullfile(paths.rs_home, 'tfr'));
path_origin		= paths.rs_home;
path_result     = paths.rs_tfr;

addpath(abpath('$root/fieldtrip/qsub'));
cd(abpath(fullfile(path_root, '/../qsub')))

% Create a cfg that can be handed over to a wrapper function
cnt = 1; cfg = {};
for iSj = 1:numel(subjdata) % subjToAnalyze %:numel(subjdata)
	for iNi = 1:2
		% Process all datasets together in order to create a common spatial filter
		files = cell(3,1);
		try
			files{1} = get_filenames(path_origin, [subjdata(iSj).nid{iNi}, '_rs1'], 'full');
			files{2} = get_filenames(path_origin, [subjdata(iSj).nid{iNi}, '_rs2'], 'full');
			files{3} = get_filenames(path_origin, [subjdata(iSj).nid{iNi}, '_rs3'], 'full');
		catch
			warning(['Couldn''t find all files for subject ' subjdata(iSj).id '. Skipping...']);
			return
		end
		
		% Parameters for wrapper function
		cfg{cnt}.params.channel		= load_file(paths.finalchannels_rs, subjdata(iSj).nid{iNi}); % we only use channels for which there is a headmodel 
		cfg{cnt}.params.freq		= freqs;
		cfg{cnt}.params.stepsize	= stepsize; % must be of same dimensions as freqs
		cfg{cnt}.params.inputfile	= files;
		cfg{cnt}.params.outputfile	= fullfile(path_result, [subjdata(iSj).nid{iNi} '_rs1-3_tfr']);
		cfg{cnt}.params.nid			= subjdata(iSj).nid{iNi};
		cfg{cnt}.params.id			= subjdata(iSj).id;
		
		% Parameters for ft_freqanalysis
		cfg{cnt}.method				= 'wavelet';    % mtmfft = multitaper frequency transformation, no time dimension!
		cfg{cnt}.keeptrials			= 'yes';
		cfg{cnt}.width				= 5.83;             % (Hipp2012) length of wavelet (in cycles) as the SD of the underlying Gaussian
		cfg{cnt}.gwidth				= 3;                % (Hipp2012) how much of the wavelet is estimated, in +/- SD (does not change spectral smoothing but accuracy)
		cfg{cnt}.pad				= 'nextpow2';		% although padding shouldnt be needed
		cfg{cnt}.output				= 'fourier'; % 'fourier' / 'powandcsd';
		
		cnt = cnt + 1;
	end
end

qsubcellfun(@rc_freqanalysis, cfg, 'matlabcmd', '/usr/local/MATLAB/R2016a/bin/matlab', 'memreq', 12 * 1024^3, 'timreq', 4 * 60 * 60, 'UniformOutput', false, 'backend', 'torque', 'StopOnError', false)
cd(abpath(paths.root));

%% ------     SL: GATHER STIMULATION EVENTS
% ... so that we do not need java on the clusters (there java memory is not
% set to high enough value)
eventfile = fullfile(paths.meta, 'sleep_stimulation_events.mat');

cnt = 1; events = {};
for iSj = 1:numel(subjdata)
	for iNi = 1:2
		events{cnt} = ft_read_event(abpath(subjdata(iSj).sleep{iNi}));
		cnt = cnt + 1;
	end
end
realsave(eventfile, events);

%% ------     SL: TIME-FREQUENCY TRANSFORMATION					
% more comments see RS above
% This one is a bit more complicated, because we gotta sort out timepoints
% for each condition (odor vs. vehicle)
paths.sl_tfr	= enpath(fullfile(paths.sl_home, 'tfr'));
path_origin		= paths.sl_home;
path_result     = paths.sl_tfr;
events			= load_file(fullfile(paths.meta, 'sleep_stimulation_events.mat')); % those have the same order as the subjdata below (Sj(Ni))

addpath(abpath('$root/fieldtrip/qsub'));
cd(abpath(fullfile(path_root, '/../qsub')));
	
% Create a cfg that can be handed over to a wrapper function
cnt = 1; cfg = {};
for iSj = 1:numel(subjdata)
	for iNi = 1:2
		try
			file = get_filenames(path_origin, [subjdata(iSj).nid{iNi}, '_sl'], 'full');
		catch
			warning(['Couldn''t find all files for subject ' subjdata(iSj).id '. Skipping...']);
			return
		end
		
		% Parameters for wrapper function
		cfg{cnt}.params.events		= events{cnt};		% for sorting out odor/vehicle
		cfg{cnt}.params.originalfs	= 1000; % sampling rate of original recordings (on which event samples are based on)
		cfg{cnt}.params.hypno		= get_filenames(paths.sl_hypnograms, subjdata(iSj).nid{iNi}, 'full');

		cfg{cnt}.params.channel		= load_file(paths.finalchannels_sl, subjdata(iSj).nid{iNi}); % we only use channels for which there is a headmodel 
		cfg{cnt}.params.freq		= freqs;
		cfg{cnt}.params.stepsize	= stepsize; % must be of same dimensions as freqs
		cfg{cnt}.params.sdt			= sdt;
		cfg{cnt}.params.inputfile	= file;
		cfg{cnt}.params.outputfile	= fullfile(path_result, [subjdata(iSj).nid{iNi} '_sleep_tfr']);
		cfg{cnt}.params.nid			= subjdata(iSj).nid{iNi};
		cfg{cnt}.params.id			= subjdata(iSj).id;
		cfg{cnt}.params.skip_existing	= false; % checks whether outputfile exists (incl. freq suffix) and skips if it does
		
		% Parameters for ft_freqanalysis
		cfg{cnt}.method				= 'wavelet';    % mtmfft = multitaper frequency transformation, no time dimension!
		cfg{cnt}.keeptrials			= 'yes';
		cfg{cnt}.width				= 5.83;             % (Hipp2012) length of wavelet (in cycles) as the SD of the underlying Gaussian
		cfg{cnt}.gwidth				= 3;                % (Hipp2012) how much of the wavelet is estimated, in +/- SD (does not change spectral smoothing but accuracy)
		cfg{cnt}.pad				= 'nextpow2';		% although padding shouldnt be needed
		cfg{cnt}.output				= 'fourier'; % 'fourier' / 'powandcsd';
		cnt = cnt + 1;
	end
end

qsubcellfun(@rc_freqanalysis_sleep, cfg, 'matlabcmd', '/usr/local/MATLAB/R2016b/bin/matlab', 'memreq', 16 * 1024^3, 'timreq', 24 * 60 * 60, 'UniformOutput', false, 'backend', 'torque', 'StopOnError', false)
cd(abpath(paths.root));

%% ------     PRE-CALCULATE LEADFIELDS
% ft_prepare_leadfield needs actual data (although leadfields only depend 
% on anatomy and electrode positions) to gather some metadata.
paths.leadfields_rs = enpath(fullfile(paths.meta, 'leadfields rs'));
paths.leadfields_sl = enpath(fullfile(paths.meta, 'leadfields sl'));

addpath(abpath('$root/fieldtrip/qsub'));
cd(abpath(fullfile(path_root, '/../qsub')))

% Create a cfg that can be handed over to a wrapper function
cnt = 1; cfg = {};
for iSj = 1:numel(subjdata)
	for iNi = 1:2	
% 		% Resting State
% 		cfg{cnt}					= [];
% 		cfg{cnt}.normalize			= 'yes';			% set to 'yes' later on
% 		
% 		cfg{cnt}.params.data		= get_filenames(paths.rs_tfr, subjdata(iSj).nid{iNi}, 1, 'full');  % take the first of all files matching that subject
% 		cfg{cnt}.params.grid		= get_filenames(paths.grids, subjdata(iSj).id, 'full');
% 		cfg{cnt}.params.headmodel			= get_filenames(paths.headmodels_prep_rs, subjdata(iSj).nid{iNi}, 'full');
% 		cfg{cnt}.params.elec		= get_filenames(paths.elecs_prep_rs, subjdata(iSj).nid{iNi}, 'full');
% 		cfg{cnt}.params.outputfile	= fullfile(paths.leadfields_rs, [subjdata(iSj).nid{iNi} '_rs_leadfield.mat']);
% 		cnt = cnt +1;
		
		% Sleep
		cfg{cnt}					= [];
		cfg{cnt}.normalize			= 'yes';			% set to 'yes' later on
		cfg{cnt}.channel			= 'all';
		
		cfg{cnt}.params.data		= get_filenames(paths.sl_tfr, subjdata(iSj).nid{iNi}, 1, 'full');  % take the first of all files matching that subject
		cfg{cnt}.params.grid		= get_filenames(paths.grids, subjdata(iSj).id, 'full');
		cfg{cnt}.params.headmodel	= get_filenames(paths.headmodels_prep_sl, subjdata(iSj).nid{iNi}, 'full');
		cfg{cnt}.params.elec		= get_filenames(paths.elecs_prep_sl, subjdata(iSj).nid{iNi}, 'full');
		cfg{cnt}.params.outputfile	= fullfile(paths.leadfields_sl, [subjdata(iSj).nid{iNi} '_sl_leadfield.mat']);
		cnt = cnt +1;
	end
end

qsubcellfun(@rc_prepare_leadfield, cfg, 'matlabcmd', '/usr/local/MATLAB/R2016a/bin/matlab', 'memreq', 12 * 1024^3, 'timreq', 40 * 60 * 60, 'UniformOutput', false, 'backend', 'torque', 'StopOnError', false)
cd(abpath(paths.root));

%% ------     SPATIAL FILTERING
% PCC is identical to dics (checked: identical results), just that it can
% operate on fourier data If a problem occurs in ft_sourceanalysis, check
% bug #3029#c9.
%
% Output used to be given un-separated by condition but I had to split it
% because only one CSD per call to ft_sourceanalysis is being computed and
% later power is computed based on that CSD (not on .mom which continues to
% exist for each trial). So if you want condition-specific power (or NAI)
% you need to call ft_sourceanalysis once per condition...
paths.rs_sources		= enpath(fullfile(paths.rs_home, 'sources')); % for convenience, this output location will be re-calculated again 
paths.sl_sources		= enpath(fullfile(paths.sl_home, 'sources')); % ... at the very bottom (because we process all files at the same time)

addpath(abpath('$root/fieldtrip/qsub'));

% Resting State
% Create a cfg that can be handed over to a wrapper function
cnt = 1; cfg = {};
skip_existing	= false;			

files			= get_filenames(paths.rs_tfr, 'full'); 
for iFile = 1:numel(files)
	[s,n,rec]					= idparts(files{iFile});
	[~,name,~]					= fileparts(files{iFile});
	outputfile					= fullfile(paths.rs_sources, [name '_source_pcc.mat']);
	
	if exist(outputfile, 'file') && skip_existing, warning(['Dataset ' name ' has already been processed. Skipping...']), continue, end	

	cfg{cnt}					= [];
	cfg{cnt}.params.outputfile	= outputfile;
	cfg{cnt}.params.data		= files{iFile};
	cfg{cnt}.params.headmodel	= get_filenames(paths.headmodels_prep_rs, [s '_n' num2str(n)], 'full');
	cfg{cnt}.params.elec		= get_filenames(paths.elecs_prep_rs, [s '_n' num2str(n)], 'full');
	cfg{cnt}.params.grid		= get_filenames(paths.leadfields_rs, [s '_n' num2str(n)], 'full');
	cfg{cnt}.params.filtersep	= false;
	
	cfg{cnt}.method				= 'pcc';
 	cfg{cnt}.pcc.keepfilter		= 'yes';        % remember the filter, only needed for sanity checks; can be set to 'no' later on
	cfg{cnt}.pcc.realfilter		= 'yes';		% use only the real part of the filter
	cfg{cnt}.pcc.fixedori		= 'yes';        % TODO: check if that actually changes the filter and how hipp did it
	cfg{cnt}.pcc.lambda			= '5%';
	cfg{cnt}.pcc.projectnoise	= 'yes';		
	cnt = cnt + 1;
end

cd(abpath(fullfile(path_root, '/../qsub')))
qsubcellfun(@rc_sourceanalysis, cfg, 'matlabcmd', '/usr/local/MATLAB/R2016b/bin/matlab', 'memreq', 40 * 1024^3, 'timreq', 4 * 60 * 60, 'UniformOutput', false, 'backend', 'torque', 'StopOnError', false)
cd(abpath(paths.root));

% Sleep
% Create a cfg that can be handed over to a wrapper function
cnt = 1; cfg = {};

skip_existing	= false;					
files = get_filenames(paths.sl_tfr, 'full');
for iFile = 1:numel(files)
	[s,n,rec]					= idparts(files{iFile});
	[~,name,~]					= fileparts(files{iFile});
	outputfile					= fullfile(paths.sl_sources, [name '_source_pcc.mat']);
	
	if exist(outputfile, 'file') && skip_existing, warning(['Dataset ' name ' has already been processed. Skipping...']), continue, end	

	cfg{cnt}					= [];
	cfg{cnt}.params.outputfile	= outputfile;
	cfg{cnt}.params.data		= files{iFile};
	cfg{cnt}.params.headmodel	= get_filenames(paths.headmodels_prep_sl, [s '_n' num2str(n)], 'full');
	cfg{cnt}.params.elec		= get_filenames(paths.elecs_prep_sl, [s '_n' num2str(n)], 'full');
	cfg{cnt}.params.grid		= get_filenames(paths.leadfields_sl, [s '_n' num2str(n)], 'full');
	cfg{cnt}.params.filtersep	= false;
	
	cfg{cnt}.method				= 'pcc';
 	cfg{cnt}.pcc.keepfilter		= 'yes';        % remember the filter, only needed for sanity checks; can be set to 'no' later on
	cfg{cnt}.pcc.realfilter		= 'yes';		% use only the real part of the filter
	cfg{cnt}.pcc.fixedori		= 'yes';        % TODO: check if that actually changes the filter and how hipp did it
	cfg{cnt}.pcc.lambda			= '5%';
	cfg{cnt}.pcc.projectnoise	= 'yes';		
	cnt = cnt + 1;
end

cd(abpath(fullfile(path_root, '/../qsub')))
qsubcellfun(@rc_sourceanalysis, cfg, 'matlabcmd', '/usr/local/MATLAB/R2016a/bin/matlab', 'memreq', 90 * 1024^3, 'timreq', 2 * 60 * 60, 'UniformOutput', false, 'backend', 'torque', 'StopOnError', false)
cd(abpath(paths.root));
	
%% ------     ONE MORE SANITY CHECK - PLOT NAIs 
% RESTING STATE
path_origin		= paths.rs_sources;
files			= get_filenames(path_origin, 'full');

% Only particular frequencies
idx = find(not(cellfun('isempty', strfind(files, '11.31'))));
idx = [idx; find(not(cellfun('isempty', strfind(files, '64.00'))))];
files = files(idx);

for iFile = 1:numel(files)
	sources						= load_file(files{iFile});
	[sourcepath, sourcename,~]	= fileparts(files{iFile});
	plotpath					= enpath(fullfile(path_origin, 'plot nai'));
	
	for iPart = 1:numel(sources)
		cfg_sd					= []; 
		cfg_sd.keepcsd			= 'yes'; 
		cfg_sd.keepnoisecsd		= 'yes';
		sources{iPart}			= ft_sourcedescriptives(cfg_sd,sources{iPart}); % computes the NAI and power averaged across trials (might fail if ispccdata in ft_descriptives is not triggered
	end
		
	% Plot some results
	for iSource = 1:numel(sources)
		sourcemodel				= load_file(fullfile(paths.root,'fieldtrip','template','sourcemodel','standard_sourcemodel3d10mm.mat'));
		mri						= ft_read_mri(fullfile(paths.root,'fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));
		sources{iSource}.pos	= sourcemodel.pos;
		
		cfg_int             = [];
		cfg_int.downsample  = 1;           % default: 1 (no downsampling)
		cfg_int.parameter   = 'all';
		source_int			= ft_sourceinterpolate(cfg_int, sources{iSource}, mri);
		
		cfg					= []; 
		cfg.funparameter	= 'nai'; 
		cfg.method			= 'slice'; 
		ft_sourceplot(cfg, source_int)
		
		export_fig(fullfile(plotpath, [sourcename '_rs' num2str(iSource) '.png']), '-nocrop', '-a2', '-m2');
		close all
	end
end
	
% SLEEP
path_origin		= paths.sl_sources;
files			= get_filenames(path_origin, 'full');

% Only particular frequencies
idx = find(not(cellfun('isempty', strfind(files, '11.31'))));
idx = [idx; find(not(cellfun('isempty', strfind(files, '64.00'))))];
files = files(idx);

for iFile = 1:numel(files)
	sources						= load_file(files{iFile});
	[sourcepath, sourcename,~]	= fileparts(files{iFile});
	plotpath					= enpath(fullfile(path_origin, 'plot nai'));
	
	cfg_sd					= [];
	cfg_sd.keepcsd			= 'yes';
	cfg_sd.keepnoisecsd		= 'yes';
	sources					= ft_sourcedescriptives(cfg_sd,sources); % computes the NAI and power averaged across trials (might fail if ispccdata in ft_descriptives is not triggered	
	
	% Plot some results
	sourcemodel				= load_file(fullfile(paths.root,'fieldtrip','template','sourcemodel','standard_sourcemodel3d10mm.mat'));
	mri						= ft_read_mri(fullfile(paths.root,'fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));
	sources.pos				= sourcemodel.pos;
	
	cfg_int             = [];
	cfg_int.downsample  = 1;           % default: 1 (no downsampling)
	cfg_int.parameter   = 'all';
	source_int			= ft_sourceinterpolate(cfg_int, sources, mri);
	
	cfg					= [];
	cfg.funparameter	= 'nai';
	cfg.method			= 'slice';
	ft_sourceplot(cfg, source_int)
	
	export_fig(fullfile(plotpath, [sourcename '.png']), '-nocrop', '-a2', '-m2');
	close all
end

%% ------     RS: CONNECTIVITY ANALYSIS
% Do the connectivity analysis for each condition using the Hipp trick.
% TODO: Unselect grid points that are not in anatomical areas.
addpath(abpath('$root/../fieldtrip/qsub'));

paths.rs_conn	= enpath(fullfile(paths.rs_sources, 'connectivities'));
skip_existing	= true;	
path_result		= paths.rs_conn;

files			= get_filenames(paths.rs_sources, 'full');
cfg = {}; cnt = 1;
for iFile = 1:numel(files)
	[~, filename, ~]			= fileparts(files{iFile});
	outputfile					= fullfile(path_result, [filename '_conns.mat']);
	if exist(outputfile) == 2 && skip_existing, warning(['Dataset ' filename ' has already been processed. Skipping...']), continue, end	

	cfg{cnt}					= [];
	cfg{cnt}.params.outputfile	= outputfile;
	cfg{cnt}.params.inputfile	= files{iFile};
	cfg{cnt}.method				= 'powcorr_ortho';
	cnt = cnt + 1;
end

cd(abpath(fullfile(path_root, '/../qsub')))
qsubcellfun(@rc_connectivityanalysis, cfg, 'matlabcmd', '/usr/local/MATLAB/R2016a/bin/matlab', 'memreq', 42 * 1024^3, 'timreq', 180 * 60 * 60, 'UniformOutput', false, 'backend', 'torque', 'StopOnError', false)
cd(abpath(paths.root));

%% ------     SL: CONNECTIVITY ANALYSIS
% Do the connectivity analysis for each condition using the Hipp trick.
addpath(abpath('$root/../fieldtrip/qsub'));

paths.sl_conn	= enpath(fullfile(paths.sl_sources, 'connectivities'));
skip_existing	= true;	
path_result		= paths.sl_conn;

files			= get_filenames(paths.sl_sources, 'full');
cfg = {}; cnt = 1;
for iFile = 1:numel(files)
	[~, filename, ~]			= fileparts(files{iFile});
	outputfile					= fullfile(path_result, [filename '_conns.mat']);
	if exist(outputfile) == 2 && skip_existing, warning(['Dataset ' filename ' has already been processed. Skipping...']), continue, end	

	cfg{cnt}					= [];
	cfg{cnt}.params.outputfile	= outputfile;
	cfg{cnt}.params.inputfile	= files{iFile};
	cfg{cnt}.method				= 'powcorr_ortho';
	cnt = cnt + 1;
end

cd(abpath(fullfile(path_root, '/../qsub')))
qsubcellfun(@rc_connectivityanalysis, cfg, 'matlabcmd', '/usr/local/MATLAB/R2016a/bin/matlab', 'memreq', 32 * 1024^3, 'timreq', 120 * 60 * 60, 'UniformOutput', false, 'backend', 'torque', 'StopOnError', false)
cd(abpath(paths.root));

%% ------     OLD ----  SL: CONNECTIVITY ANALYSIS					- M
% TODO: Ask Markus if the wavelet extraction is legit
addpath(abpath('$root/fieldtrip/qsub'));

paths.sl_conn	= enpath(fullfile(paths.sl_sources, 'connectivities'));
skip_existing	= true;	
path_result 	= paths.sl_conn;

files			= get_filenames(paths.sl_sources, 'full');
epoch_length	= 30; % in s

% Turn frequencies into rounded strings (will allow extraction of frequency
% from file name because that's how the file names were generated in 
% rc_freqanalysis...)
% clear freqs_str
% for iFreq = 1:numel(freqs)
% 	freqs_str{iFreq} = num2str(freqs(iFreq),'%4.2f');
% end

% Based on the events for that recording, extract all odor and vehicle
% times and sort TFRs into those conditions
cfg = {}; cnt = 1; toks_last = []; orig_data = [];
for iFile = 1:numel(files)
	[~, filename, ~]	= fileparts(files{iFile});
	[sid, nid, ~]		= idparts(filename);
	sjdata_temp			= subjdata(cellfun(@(x) strcmp(x, sid), {subjdata.id}))
	events				= ft_read_event(abpath(sjdata_temp.sleep{nid}));
	
	cidx_all								= {events.mffkey_cidx}; % mmfkey_cidx is the same number for on and off (gidx is one for on, one for off)
	cidx_all(cellfun('isempty',cidx_all))	= [];
	cidx_all								= cellfun(@str2double,cidx_all);
	cidx_unique								= sort(unique(cidx_all)); 
	hypno									= load_hypnogram(get_filenames(paths.sl_hypnograms, [sid '_n' num2str(nid)], 'full'));
	hypno(hypno(:,2) == 1, 1)				= 0; % get rid of all movement times
	for cidx = numel(cidx_unique):-1:1
		idx = find(strcmp({events.mffkey_cidx}, num2str(cidx_unique(cidx)))); % where in the event structure are we
		
		% For each unique event, check whether it occurs exactly twice
		if sum(cidx_all == cidx_unique(cidx)) ~= 2
			cidx_unique(cidx) = [];
			warning('Deleting a stimulation because it doesnt have a start and end.')
		
		% ...whether first is a start and second an end trigger
		elseif ~strcmp(events(idx(1)).value, 'DIN1') || ~strcmp(events(idx(2)).value, 'DIN2')
			cidx_unique(cidx) = [];
			warning('Deleting a stimulation because its too short or too long.')
			
		% ...whether it is about 15 s long
		elseif events(idx(2)).sample - events(idx(1)).sample < 15 * fs || events(idx(2)).sample - events(idx(1)).sample > 15.1 * fs
			cidx_unique(cidx) = [];
			warning('Deleting a stimulation because its too short or too long.')
			
		% ...and whether it is in SWS
		elseif all(hypno(ceil(events(idx(1)).sample / (epoch_length * fs)), 1) ~= [3, 4]) || ...
				all(hypno(ceil(events(idx(2)).sample / (epoch_length * fs)), 1) ~= [3, 4])
			cidx_unique(cidx) = [];
			warning('Deleting a stimulation because its not in SWS or during MT.')
		end
	end
	
	% Now all events are valid, all uneven ones are odor, all even ones are
	% vehicle
	cidx_odor			= cidx_unique(mod(cidx_unique,2) ~= 0);
	cidx_vehicle		= cidx_unique(mod(cidx_unique,2) == 0);
	
	% Load data before freq analysis in order to reconstruct time points
	% for every wavelet. This information unfortunately got lost on the
	% way (mostly because checkconfig clears large cfg fields)
	toks				= tokenize(filename, '_');
	tok_freq			= toks{5};
	
	% Only if data has changed (and not just the frequency) do we want to
	% re-load the data.
	if isempty(orig_data) || isempty(toks_last) || ~strcmp(toks{1}, toks_last{1}) || ~strcmp(toks{2}, toks_last{2})
		orig_data			= load_file(paths.sl_home, [toks{1} '_' toks{2}]);
	end
	toks_last			= toks;
	
	% Reconstruct all time points 
	cur_stepsize		= stepsize(find(strcmp(freqs_str, tok_freq)));
	tois = [];
	for iTrial = 1:numel(orig_data.trial)
		% Translate data to frequency domain, keep the individual trials
		% CAUTION: gwidth has to be the one used in "SL: TIME-FREQUENCY % TRANSFORMATION"
		gwidth = 3;
		tois                 = [tois orig_data.time{iTrial}(1)+((gwidth*2)*cur_stepsize)+1 : cur_stepsize : orig_data.time{iTrial}(end)-((gwidth*2)*cur_stepsize+1)]; 
	end
	
	% ----------------------------- FROM HERE !!!!
	
	% Map each tfr onto its condition
	sources			= load_file(files{iFile});
	if numel(tois) ~= numel(sources.cumtapcnt)
		error('Number of TFR timestamps does not match number of source estimates.')
	end
	clear tfr
	
	cur_sdt				= sdt(find(strcmp(freqs_str, tok_freq)));
	
	trialdefs_start		= trialdefs{cellfun(@(x) strcmp(x.id, [sid '_n' num2str(nid) '_sl']), trialdefs)}.trl(1) / fs
	
	tfr_odor			= []; 
	tfr_vehicle			= [];
	tfr_none			= [];
	for iTime = 1:numel(tois)
		t_start			= trialdefs_start + tois(iTime) - cur_sdt * 2;
		t_end			= trialdefs_start + tois(iTime) + cur_sdt * 2;
		if ~(t_start < t_end), error('Start after end.'), end
		
		% Check if its during a odor or vehicle stimulation
		found = false;
		for i = 1:numel(cidx_unique)
			idx = find(strcmp({events.mffkey_cidx}, num2str(cidx_unique(i))));
			if t_start > events(idx(1)).sample / fs && t_end < events(idx(2)).sample / fs
				if any(cidx_unique(i) == cidx_odor)
					tfr_odor	= [tfr_odor iTime];
					found		= true;
				elseif any(cidx_unique(i) == cidx_vehicle)
					tfr_vehicle	= [tfr_vehicle iTime];
					found		= true;
				end
			end
			if found, break, end
		end
							
		% ... or neither
		if ~found
			tfr_none = [tfr_none iTime];
		end
	end
	
	% HERE
	% TODO: CHECK ABOVE CODE!!
	
	% Use those tfr indices to extract the correct source estimates for
	% each condition; ft_selectdata doesn't do a good job on this
	sources_odor				= sources;
	sources_vehicle				= sources;
	sources_odor.avg.mom		= cell(size(sources.avg.mom)); % 6804 locations (many of them outside)
	sources_vehicle.avg.mom		= cell(size(sources.avg.mom));
	
	% Go through source locations and for each, take over data for the
	% correct condition
	for iLoc = 1:numel(sources.avg.mom)
		if ~isempty(sources.avg.mom{iLoc})
			sources_odor.avg.mom{iLoc} = sources.avg.mom{iLoc}(tfr_odor);
			sources_vehicle.avg.mom{iLoc} = sources.avg.mom{iLoc}(tfr_vehicle);
		end
	end
end

	
	
	
	% TODO: 
	% start two connectivity analysis _odor _vehicle	
	
	outputfile					= fullfile(path_result, [filename '_conns.mat']);
	if exist(outputfile) == 2 && skip_existing, warning(['Dataset ' filename ' has already been processed. Skipping...']), continue, end	

	cfg{cnt}					= [];
	cfg{cnt}.params.outputfile	= outputfile;
	cfg{cnt}.params.inputfile	= files{iFile};
	cfg{cnt}.method				= 'powcorr_ortho';
	cnt = cnt + 1;


cd(abpath(fullfile(path_root, '/../qsub')))
qsubcellfun(@rc_connectivityanalysis, cfg, 'matlabcmd', '/usr/local/MATLAB/R2016a/bin/matlab', 'memreq', 20 * 1024^3, 'timreq', 120 * 60 * 60, 'UniformOutput', false, 'backend', 'torque', 'StopOnError', false)
cd(abpath(paths.root));

%% --- TODO: ATLAS LOOKUP	Gets rid of source points not in cortical areas 
% TODO: Could be further reduced to outer areas..
sourcemodel_mni = load_file('Y:\Jens\Reactivated Connectivity\fieldtrip\template\sourcemodel\standard_sourcemodel3d10mm.mat');
atlas			= ft_read_atlas(fullfile(paths.meta, 'atlas_MMP1.0_4k.mat'));
% atlas			= ft_read_atlas(fullfile(path_root, 'fieldtrip/template/atlas/aal/ROI_MNI_V4.nii'));

cfg					= []; 
cfg.interpmethod	= 'nearest'; 
cfg.parameter		= 'parcellation'; 
% cfg.parameter		= 'tissue'; % for old aal atlas
atlas_intmni		= ft_sourceinterpolate(cfg, atlas, sourcemodel_mni);

% Some changes have to be done on atlas and connectiviy structure to make
% them similar to the ones in the tutorial
atlas_intmni.parcellationlabel = atlas.parcellationlabel; % got lost during interpolation
sum(sum(sum(~isnan(atlas_intmni.parcellation)))) == sum(sum(sum(sourcemodel_mni.inside))) % just checking
atlas_intmni.parcellation(isnan(atlas_intmni.parcellation)) = 0 % make NaNs to 0s
atlas_intmni.pos	= sourcemodel_mni.pos; % ft_sourceparcellate requires that


% Get those grid points in our sourcemodel that correspond to any of our
% recognized cortical areas
labels = atlas_intmni.parcellationlabel(~contains(atlas_intmni.parcellationlabel, 'L_???'));
labels = labels(~contains(labels, 'R_???'));

cfg					= [];
cfg.atlas			= atlas_intmni;
cfg.atlas.coordsys	= 'mni';
cfg.roi				= labels; % atlas_intmni.parcellationlabel; % {'L_???', 'R_???'}; % aal: atlas_intmni.tissuelabel;
cfg.inputcoord		= 'mni';
mask				= ft_volumelookup(cfg,sourcemodel_mni);

% create temporary mask according to the atlas entries
tmp                  = repmat(sourcemodel_mni.inside,1,1); % ?
tmp(tmp==1)          = 0;
tmp(mask)            = 1;

% define inside locations according to the atlas based mask
sourcemodel_mni.inside = tmp;

figure;
ft_plot_mesh(sourcemodel_mni.pos(sourcemodel_mni.inside,:));
% hold on
% ft_plot_vol(vol_stand,  'facecolor', 'cortex', 'edgecolor', 'none');alpha 0.5; camlight;

%% ------     NETWORK ANALYSIS
% Based on
% http://www.fieldtriptoolbox.org/tutorial/networkanalysis#connectivity_analysis_and_parcellation
% In the tutorial they use a cortical sheet sourcemodel (sourcemodel_4k),
% we use a volume sourcemodel, therefore we need to nuse a volume-based
% atlas.

% Parcellate the connectivity based on the atlas from Glasser et al. 2016, Nature
% retrieved from ftp://ftp.fieldtriptoolbox.org/pub/fieldtrip/tutorial/networkanalysis/
% cannot be used easily: ft_read_atlas(fullfile(paths.meta, 'atlas_MMP1.0_4k.mat'));
atlas				= ft_read_atlas(fullfile(paths.root, 'fieldtrip', 'template', 'atlas', 'brainnetome', 'BNA_MPM_thr25_1.25mm.nii'));
sourcemodel_mni		= load_file('Y:\Jens\Reactivated Connectivity\fieldtrip\template\sourcemodel\standard_sourcemodel3d10mm.mat');
mri					= ft_read_mri(abpath('Y:\Jens\Reactivated Connectivity\fieldtrip\template\anatomy\single_subj_T1_1mm.nii'));

% Interpolate atlas to our sourcemodel
% TODO: This highly reduces fidality of atlas. Is this necessary?
atlas				= ft_convert_units(atlas,'cm');
cfg					= []; 
cfg.interpmethod	= 'nearest'; 
cfg.parameter		= 'tissue'; 
atlas_int			= ft_sourceinterpolate(cfg, atlas, sourcemodel_mni);
atlas_int.pos		= sourcemodel_mni.pos;

path_origin			= paths.rs_conn;

files = get_filenames(path_origin, 'full');
for iFile = 37 % :numel(files)
	data		= load_file(files{iFile});
	clear data_parc
	
	% Parcellate connectivity matrix into brain areas
	for iCond = 1:numel(data)
		data{iCond}.pos		= sourcemodel_mni.pos;
		cfg					= [];
		cfg.parcellation	= 'tissue';
		cfg.parameter		= 'powcorrspctrm';
		data_parc{iCond}	= ft_sourceparcellate(cfg, data{iCond}, atlas_int);
	end

% iCond = 3; figure;imagesc(data_parc{iCond}.powcorrspctrm)
% iCond = 3; figure;imagesc(data{iCond}.powcorrspctrm)

% Graph-theoretical network analysis
cfg					= [];
cfg.method			= 'degrees'; % 'betweenness' 'degrees'; % degrees requires threshold?
cfg.parameter		= 'powcorrspctrm';
cfg.threshold		= median(nanmedian(data_parc{iCond}.powcorrspctrm)); % TODO: Find a good value!
network_full		= ft_networkanalysis(cfg,data{iCond});
network_parc		= ft_networkanalysis(cfg,data_parc{iCond});

% Manually transform data into source grid representation so that we can
% get rid of NaNs
network_parc_source = ft_checkdata(network_parc, 'datatype', {'source', 'volume'}, 'feedback', 'yes', 'hasunit', 'yes');
network_parc_source.degrees(isnan(network_parc_source.degrees)) = 0;

cfg               = [];
cfg.method        = 'surface'; % 'slice'
cfg.funparameter  = 'degrees';
ft_sourceplot(cfg, network_parc_source);

% TODO: Why can't I properly use the atlas as a ROI or plot it in slice
% view?
cfg               = [];
cfg.method        = 'slice'; %'surface'; % 'slice'
cfg.funparameter  = 'tissue';
% cfg.funcolormap   = 'jet';
cfg.atlas			= atlas_int;
cfg.roi				= {'MTG, Right Middle Temporal Gyrus A21c, caudal area 21';
	'MTG, Left Middle Temporal Gyrus A21c, caudal area 21';
	'MTG, Right Middle Temporal Gyrus A21r, rostral area 21';
	'MTG, Left Middle Temporal Gyrus A21r, rostral area 21';
	'MTG, Right Middle Temporal Gyrus A37dl, dorsolateral area37';
	'MTG, Left Middle Temporal Gyrus A37dl, dorsolateral area37';
	'MTG, Right Middle Temporal Gyrus aSTS, anterior superior temporal sulcus';
	'MTG, Left Middle Temporal Gyrus aSTS, anterior superior temporal sulcus'; 
	'Hipp, Right Hippocampus rHipp, rostral hippocampus';
	'Hipp, Left Hippocampus rHipp, rostral hippocampus';
	'Hipp, Right Hippocampus cHipp, caudal hippocampus';
	'Hipp, Left Hippocampus cHipp, caudal hippocampus'};
atlas_int.coordsys = 'mni';
cfg.atlas.coordsys = 'mni';
ft_sourceplot(cfg, atlas_int);


% TODO: Try connectivity viewer with tutorial code
% Prepare data for  viewer
data_parc_source = data_parc{1}; %ft_checkdata(data_parc{1}, 'datatype', {'source', 'volume'}, 'feedback', 'yes', 'hasunit', 'yes');
data_parc_source.brainordinate.parcellationlabel = data_parc_source.brainordinate.tissuelabel;
data_parc_source.brainordinate.parcellation = data_parc_source.brainordinate.tissue;
connectivityviewer(data_parc_source, 'powcorrspctrm', [0 0.1]);
connectivityviewer(data_parc_source, 'powcorrspctrm', 'vertexcolor', 'none');

end



%% OLD
% old network stuff


% for current dataset
sourcemodel		= load_file(fullfile(paths.grids, 's5_grid_10mm.mat'));



% Plot and compare to tutorial
ft_plot_vol(hdm, 'edgecolor', 'none'); alpha 0.4           
ft_plot_mesh(ft_convert_units(sourcemodel, 'cm'));
ft_plot_sens(dataclean.grad);
view([0 -90 0])


% atlas_norm		= ft_read_atlas(abpath('Y:\Jens\Reactivated Connectivity\fieldtrip\template\atlas\aal\ROI_MNI_V4.nii'));
% source			= load_file(abpath('Y:\Jens\Reactivated Connectivity\homes\sourceanalysis 1.0\rs_tfr\sources\s5_n1_rs1-3_tfr_sources_freq5.mat'));

hdm				= load_file(fullfile(paths.headmodels, 's5_scalp.15_simbio_fem.mat'));

% Interpolate atlas to our sourcemodel
cfg					= []; 
cfg.interpmethod	= 'nearest'; 
cfg.parameter		= 'parcellation'; 
atlas_intmni		= ft_sourceinterpolate(cfg, atlas, sourcemodel_mni);

% Some changes have to be done on atlas and connectiviy structure to make
% them similar to the ones in the tutorial
atlas_intmni.parcellationlabel = atlas.parcellationlabel; % got lost during interpolation
sum(sum(sum(~isnan(atlas_int.parcellation)))) == sum(sum(sum(sourcemodel.inside))) % just checking
atlas_intmni.parcellation(isnan(atlas_intmni.parcellation)) = 0 % make NaNs to 0s
atlas_intmni.pos	= sourcemodel_mni.pos; % ft_sourceparcellate requires that

source_conn.pos		= sourcemodel_mni.pos;
source_conn.powcorrspctrmdimord	= 'pos_pos_freq'; % getdimord fails otherwise
source_conn			= rmfield(source_conn, {'cond', 'nid'}); % this confuses ft_sourceparcellate

% Lets do the same with the normal AAL atlas
% cfg					= []; 
% cfg.interpmethod	= 'nearest'; 
% cfg.parameter		= 'tissue'; 
% % atlas_norm_int		= ft_sourceinterpolate(cfg, atlas_norm, sourcemodel);
% atlas_norm_intmni   = ft_sourceinterpolate(cfg, atlas_norm, sourcemodel_mni);
% % atlas_norm_int.tissuelabel = atlas_norm.tissuelabel;
% atlas_norm_intmni.tissuelabel = atlas_norm.tissuelabel;

% The following parcellation fails because there is a problem with inside
% and outside i think.
cfg					= [];
cfg.parcellation	= 'parcellation';
cfg.parameter		= 'powcorrspctrm';
parc_conn			= ft_sourceparcellate(cfg, source_conn, atlas_intmni); % doesnt work

cfg					= [];
cfg.parcellation	= 'tissue';
cfg.parameter		= 'powcorrspctrm';
parcnorm_conn		= ft_sourceparcellate(cfg, source_conn, atlas_norm_intmni); % doesnt work

% Ok lets make sure it is a problem of powcorrortho and not just something
% with my own data.
% the only important difference between the tutorial source and mine is
% that mine does have outside fields, the tutorial source doesnt.
cfg         = [];
cfg.method  = 'coh';
cfg.complex = 'absimag';
source_conn_coh = ft_connectivityanalysis(cfg, source);

cfg         = [];
cfg.method  = 'powcorr_ortho';
source_conn_powcorr_ortho  = ft_connectivityanalysis(cfg, source);

% Parcellate coherence conn
source_conn_coh.pos		= sourcemodel_mni.pos;
cfg					= [];
cfg.parcellation	= 'parcellation';
cfg.parameter		= 'cohspctrm';
parcnorm_conn_coh		= ft_sourceparcellate(cfg, source_conn_coh, atlas_intmni); % doesnt work

% Parcellate powcorr_ortho conn
source_conn_powcorr_ortho.pos		= sourcemodel_mni.pos;
cfg					= [];
cfg.parcellation	= 'parcellation';
cfg.parameter		= 'powcorrspctrm';
parcnorm_conn_powcorrspctrm		= ft_sourceparcellate(cfg, source_conn_powcorr_ortho, atlas_intmni); % doesnt work

% ------------- other stuff

cfg					= [];
cfg.parcellation	= 'tissue';
cfg.parameter		= 'powcorrspctrm';
parcnormmni_conn    = ft_sourceparcellate(cfg, source_conn, atlas_norm_intmni); % doesnt work


cfg					= [];
cfg.method			= 'ortho';
cfg.funparameter	= 'parcellation';
% cfg.funcolormap  ='jet';
% ft_sourceplot(cfg, natlas)
% cfg.atlas = atlas_int;
ft_sourceplot(cfg, atlas_int)



% the following can create a .nai field if noise has been estimated
cfg=[]; cfg.powmethod = 'lambda1';
datad		= ft_sourcedescriptives(cfg, data);

% mom to power
for i = 1:length(data.avg.mom)
	if ~isempty(data.avg.mom{i})
		data.pow{i} = mean(arrayfun(@(x) real(x)^2, data.avg.mom{i}));
	else
		data.pow{i} = NaN;
	end
end

	
% interpolate the atlas to: fieldtrip\template\anatomy\single_subj_T1_1mm.nii?
% NO ! Interpolate atlas to our sourcemodel
% cfg = [];
% cfg.parameter = 'parcellation';
% cfg.method = 'nearest';
% atlas_int = ft_sourceinterpolate(cfg, atlas, mri) 



% TODO: Find a way to interpolate the data to the parcellation or the other
% way around. How does ft_sourceplot do it when you proide an atlas? Can I
% give it the MNI MRI and it will smooth it to it?
% atlas.pos = data.pos; % otherwise the parcellation won't work <- IMPOSSIBLE BEFORE WE DONT HAVE THE SAME NUMBER OF GRID POINTS; it recommends to nuse ft_sourceinterpolate



% What about this?
cfg = []; % ...nope
cfg.atlas = atlas_int;
cfg.roi = atlas_int.parcellationlabel;
cfg.inputcoord = 'mni';
mask = ft_volumelookup(cfg,mri);




figure;imagesc(parc_conn.cohspctrm);

% This here is important, gives you one scalar per grid point based on
% graphtheoretical measures
cfg					= [];
cfg.method			= 'degrees';
cfg.parameter		= 'powcorrspctrm';
cfg.threshold		= .1;
network_full		= ft_networkanalysis(cfg,conn);
% network_parc		= ft_networkanalysis(cfg,parc_conn);

network_full.pos	= sourcemodel.pos(sourcemodel.inside,:);
network_full.dim	= sourcemodel.dim;
network_full.inside = true(size(network_full.degrees));

cfg_int                      = [];
cfg_int.downsample           = 1;           % default: 1 (no downsampling)
cfg_int.parameter            = 'degrees';
network_full_int                 = ft_sourceinterpolate(cfg_int, network_full, mri);



% visualize with sourceplot
cfg               = [];
cfg.method        = 'surface';
cfg.funparameter  = 'degrees';
cfg.funcolormap   = 'jet';
% cfg.location      = 'max';

ft_sourceplot(cfg, network_full);
view([-150 30]);

ft_sourceplot(cfg, network_parc);
view([-150 30]);


% Plot the source
data.pos = sourcemodel.pos;

cfg_int                      = [];
cfg_int.downsample           = 1;           % default: 1 (no downsampling)
cfg_int.parameter            = 'avg.pow';
data_int                 = ft_sourceinterpolate(cfg_int, data, mri);

cfg               = [];
cfg.method        = 'surface';
cfg.funparameter  = 'filter';
cfg.funcolormap   = 'jet';
% cfg.location      = 'max';
ft_sourceplot(cfg, data_int);


% create a fancy mask
% taken from http://www.fieldtriptoolbox.org/tutorial/networkanalysis#source_reconstruction_of_low_and_high_alpha_activity_epochs
source_ratio.mask = (1+tanh(2.*(source_ratio.pow./max(source_ratio.pow(:))-0.5)))./2; 

%% ------     SL: TFR time point sanity check
% Code snippets used to test fixing of the timeline after resampling
% 0 in the TFRs points to the time relative to the trial start at initial 
% preprocessing as given in:
% Y:\Jens\Reactivated Connectivity\homes\preprocessing 1.2\sleep\meta\sl_trialdefs.mat
% ... i.e.: (trialdefs{1}.trl(1) / 1000)
%
% Sometimes preprocessed data does not start with 0, because more data was
% cut out during artifact rejection.
trialdefs = load_file(fullfile(paths.home, '..', 'preprocessing 1.2', 'sleep', 'meta', 'sl_trialdefs'));

iDs = 9
	
	% data after preprocessing
	data_clean				= load_file(fullfile(paths.home, '..', 'preprocessing 1.2', 'sleep', 'clean'), trialdefs{iDs}.id);
	cfg                     = [];
	cfg.channel				= {'E20', 'E40', 'E106', 'E108'};
	data_clean				= ft_selectdata(cfg, data_clean);
	
	% data before preprocessing
	cfg                     = [];
	cfg.dataset				= abpath(trialdefs{iDs}.dataset);
	% cfg.channel				= {'E106', 'E108'};
	cfg.hpfilter			= 'yes';
	cfg.hpfreq				= 2;
	data_raw				= ft_preprocessing(cfg);
	
% 	start_time				= (trialdefs{iDs}.trl(1) / 1000) + data_clean.time{1}(1); % time of trial start in trialdefs plus later cut out time due to artifacts
	
	% Cut away from raw data: Time before sleep + potential additional cuts
	% due to artifacts
	cfg                     = [];
% 	cfg.latency				= [start_time start_time + 600]
	cfg.channel				= {'E20', 'E40', 'E106', 'E108'};
	data_raw				= ft_selectdata(cfg, data_raw);
	
	events					= abpath(trialdefs{iDs}.dataset);
	
	% Now raw and clean data should start at the same time point
	cfg                     = [];
	cfg.viewmode            = 'vertical';
	cfg.ylim				= [-100 100];
	cfg.continuous			= 'yes';
	cfg.blocksize			= 30;
	% cfg.channel             = data.label(1:30); % check all channels though (e.g. on the way back)!
	cfg.preproc.detrend     = 'yes';
	cfg.preproc.bsfilter    = 'yes';
	cfg.preproc.bsfreq		= [48 52];
	cfg.preproc.hpfilter	= 'no';
% 	cfg.preproc.hpfreq		= 2;
% 	cfg.plotevents			= 'yes';
% 	cfg.event				= events;
	cfg.channel				= {'E20', 'E40', 'E106', 'E108'};
	
% 	cfg.position = [0 0 1600 500]
	cfg.continuous			= 'no';
	ft_databrowser(cfg, data_raw);
	
	cfg.preproc.hpfilter	= 'yes';
	cfg.preproc.hpfreq		= 2;
	ft_databrowser(cfg, data);
% 	export_fig('test.pdf', '-nocrop', '-append');
% 	cfg.position = [0 500 1600 500]
	ft_databrowser(cfg, data_clean);
% 	export_fig(fullfile(plotpath, [sourcename '_rs' num2str(iSource) '.png']), '-nocrop', '-a2', '-m2');


%% -----------------
% Calculate average for each condition
% This step is only necessary if you need to reconstruct single trial data
idx_rs1                  = find(condition_index == 1); % find trial numbers belonging to condition A
idx_rs2                  = find(condition_index == 2); % find trial numbers belonging to condition B
idx_rs3                  = find(condition_index == 3); % find trial numbers belonging to condition B

source_rs1                  = source_trials;
source_rs1.trial([idx_rs2 idx_rs3])        = [];
source_rs1.cumtapcnt([idx_rs2 idx_rs3])    = [];
source_rs1.df               = length(idx_rs1);
source_rs1                  = ft_sourcedescriptives([], source_rs1); % compute average source reconstruction for condition rs1





source_rs2                  = source_trials;
source_rs2.trial([idx_rs2 idx_rs3])        = [];
source_rs2.cumtapcnt([idx_rs2 idx_rs3])    = [];
source_rs2.df               = length(idx_rs1);
source_rs2                  = ft_sourcedescriptives([], source_rs1); % compute average source reconstruction for condition rs2

source_rs3                  = source_trials;
source_rs3.trial([idx_rs2 idx_rs3])        = [];
source_rs3.cumtapcnt([idx_rs2 idx_rs3])    = [];
source_rs3.df               = length(idx_rs1);
source_rs3                  = ft_sourcedescriptives([], source_rs1); % compute average source reconstruction for condition rs3

