%% This script prepares EGI-recorded data to be read by BrainVision Analyzer
% ...in order to be exported for sleep scoring in SchlafAUS
%
% The script basically reads in the required channels, re-references them
% (EEG to average mastoids and bipolar referencing for EMG and EOG), and
% saves them with new channel names to a structure that can be opened in
% BrainVision Analyzer.
%
% In order to be opened by SchlafAUS the result of this script has to be
% read in with BrainVision Analyzer and exported again with the following
% options (or just use the BVA tree that comes with this script):
% File extension: .dat
% Write header file: yes
% Format: BINARY
% Orientation: MULTIPLEXED
% Line Delimiter: CRLF (PC style)
% Binary format: 16-Bit signed integer format
% Set resolution manually: no
% Individually optimized resolution for each channel: no
% Convert to big-endian order: no
% Export all channels: yes
%
% The reason is that SchlafAUS expects 16-bit signed integers while
% fieldtrip only exports IEEE32-bit (even if converted to single
% precision). SchlafAUS shows the data correctly but assumes the data to be
% twice as long (probably based on bytes).
%
% This script requires FieldTrip, see http://www.fieldtriptoolbox.org
%
% Author: Jens Klinzing, jens.klinzing@uni-tuebingen.de

%% SETUP
init_rc;
path_files		= fullfile(path_data, 'EEG');
path_result 	= enpath(fullfile(path_data, 'EEG BVA', 'raw'));
files			= {};
i				= 1;


% Files to be processed. Once they are converted, they can be commented out
% files{i} = get_filenames(path_files, 'RC_051_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_052_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_091_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_092_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_121_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_122_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_131_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_132_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_141_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_142_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_161_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_162_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_171_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_172_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_201_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_202_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_241_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_242_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_251_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_252_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_261_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_262_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_281_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_282_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_291_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_292_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_301_sleep', 'full'); i = i+1; % Manually re-referenced to only one mastoid (E57) because the other one was broken
% files{i} = get_filenames(path_files, 'RC_302_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_351_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_352_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_391_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_392_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_411_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_412_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_441_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_442_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_451_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_452_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_461_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_462_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_471_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_472_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_481_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_482_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_491_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_492_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_511_sleep', 'full'); i = i+1;
% files{i} = get_filenames(path_files, 'RC_512_sleep', 'full'); i = i+1;

%% START
for iFile = 1:numel(files)
	
	% Read in eeg and other data (with different filter properties)
	cfg								= [];
	cfg.dataformat					= 'egi_mff_v2';
	cfg.headerformat                = 'egi_mff_v2';
	cfg.dataset                     = files{iFile};
	cfg.continuous                  = 'yes';
	cfg.bpfilter                    = 'yes';
    cfg.bpfilttype                  = 'but';
    cfg.bpfiltord                   = 4;
	cfg.bpfreq                      = [0.5 40]; % < 36 is unstable (??)
	cfg.channel						= {'E36', 'E104', 'E57', 'E100', 'E43', 'E120', 'E126', 'E25'};  % C3, C4, LM, RM, EMGs, EOGs (don't remember why i put EMG and EOG in here) 
	data_eeg						= ft_preprocessing(cfg);
	% cfg=[];cfg.viewmode='vertical'; ft_databrowser(cfg,data_eeg)
	
	cfg.bpfilter                    = 'yes';
	cfg.bpfreq                      = [0.2 70];
	cfg.bsfilter                    = 'yes';
	cfg.bsfreq                      = [45 55];
	cfg.channel 					= {'E43', 'E120', 'E126', 'E25'}; % EMGs, EOGs
	data							= ft_preprocessing(cfg);
	
	cfg								= [];
	cfg.resamplefs					= 200;
	cfg.resamplemethod				= 'downsample';   % = no lpfiltering before downsampling (we did that above); default: resample
	cfg.detrend						= 'no';
	data_eeg						= ft_resampledata(cfg, data_eeg);
	data							= ft_resampledata(cfg, data);
	
	% Re-reference EEG to average mastoids, bipolar derivations for EOG and EMG
	% and append the results into one data structure
	cfg                     = [];
	cfg.reref               = 'yes';
	cfg.channel             = {'E36', 'E104', 'E57', 'E100'}; % % C3, C4, LM, RM
	cfg.refchannel          = {'E57', 'E100'}; % LM, RM    -   if s30, n1, dann nur E57
	data_eeg                = ft_preprocessing(cfg, data_eeg);
	
	cfg                     = [];
	cfg.reref               = 'yes';
	cfg.channel             = {'E43', 'E120'}; % EMGs
	cfg.refchannel          = {'E120'};
	data_emg                = ft_preprocessing(cfg, data);
	
	cfg.channel             = {'E126', 'E25'}; % EOGs (diagonal)
	cfg.refchannel          = {'E25'};
	data_eog                = ft_preprocessing(cfg, data);
	
	data					= ft_appenddata([], data_eeg, data_eog, data_emg);
	
	% Rename channels
	chidx                   = find(strcmp(data.label, 'E36'));
	data.label{chidx}		= 'C3';
	chidx                   = find(strcmp(data.label, 'E104'));
	data.label{chidx}		= 'C4';
	chidx                   = find(strcmp(data.label, 'E43'));
	data.label{chidx}		= 'EMG';
	chidx                   = find(strcmp(data.label, 'E126'));
	data.label{chidx}		= 'EOG';
	
	cfg						= [];
	cfg.channel				= {'C3', 'C4', 'EMG', 'EOG'};
	data					= ft_selectdata(cfg, data);
% 	data                    = ft_struct2single(data);
    
	% cfg=[]; cfg.blocksize = 30; cfg.viewmode='vertical'; ft_databrowser(cfg,data)
    hdr                     = [];
	hdr.label				= data.label;
	hdr.chantype			= {'eeg', 'eeg', 'eeg', 'eeg'};
	hdr.Fs					= data.fsample;
	hdr.nChans				= 4;
    hdr.nSamples            = size(data.time{1},2);
	hdr.chanunit			= {'uV', 'uV', 'uV', 'uV'};
    hdr.nSamplesPre         = 0;
    hdr.nTrials             = 1;

    [~, name, ~]  = fileparts(files{iFile});
	ft_write_data(fullfile(path_result, name), data.trial{:}, 'header', hdr, 'dataformat', 'brainvision_eeg');
    clear data hdr
    clear global % ...to deal with a fieldtrip screwup...
end

