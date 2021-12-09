%% ------     FIRST-TIME SETUP
% init_rc;
% pipeline_name               = 'sanitycheck 1.0';
% paths                       = [];
% paths.root                  = get_pathroot;
% paths.data                  = get_pathdata;
% paths.home                  = enpath(fullfile(paths.root, 'homes', pipeline_name));
% paths.headmodels_rs         = abpath('$root/homes/sourceanalysis 1.2/meta/headmodels prepared rs');
% paths.elecs_rs              = abpath('$root/homes/sourceanalysis 1.2/meta/electrodes prepared rs');
% paths.headmodels_sl         = abpath('$root/homes/sourceanalysis 1.2/meta/headmodels prepared sl');
% paths.elecs_sl              = abpath('$root/homes/sourceanalysis 1.2/meta/electrodes prepared sl');
% paths.grids			      = fullfile(paths.headmodels, 'subject-specific grids');
% paths.meta				  =	enpath(fullfile(paths.home, 'meta'));
% saveall(paths);

%% ------     SETUP
pipeline_name               = 'sanitycheck 1.0';
paths                       = abpath(load_file(fullfile(get_pathroot, 'homes', pipeline_name, 'meta', 'paths.mat')));
subjdata                    = rc_subjectdata;
channels_min                = {'all', '-E49', '-E48', '-E43', '-E127', '-E126', '-E17', '-E128', '-E32', '-E25', '-E21', '-E14', '-E8', '-E1', '-E125', '-E120', '-E119', '-E113', '-E56', '-E63', '-E68', '-E73', '-E81', '-E88', '-E94', '-E99', '-E107', '-E57', '-E100'};
channels_min_noref			= {'all', '-VREF', '-E49', '-E48', '-E43', '-E127', '-E126', '-E17', '-E128', '-E32', '-E25', '-E21', '-E14', '-E8', '-E1', '-E125', '-E120', '-E119', '-E113', '-E56', '-E63', '-E68', '-E73', '-E81', '-E88', '-E94', '-E99', '-E107', '-E57', '-E100'};
paths.rs_clean              = fullfile(paths.root, 'homes', 'preprocessing 1.2', 'resting-state', 'clean');
paths.rs_home				= enpath(fullfile(paths.root, 'homes', 'sourceanalysis 1.2', 'resting-state')); % after last channel rejection and re-referenced to avg, potentially downsampled
paths.sl_clean              = fullfile(paths.root, 'homes', 'preprocessing 1.2', 'sleep', 'clean');
paths.sl_home				= enpath(fullfile(paths.root, 'homes', 'sourceanalysis 1.2', 'sleep')); % after last channel rejection and re-referenced to avg, potentially downsampled

%% ------     RS - SENSOR
paths.rs_sensorcheck	= fullfile(paths.home, 'sensorcheck resting-state');
path_origin				= paths.rs_home;

freqs			= [2 10 25 40 65];
sdf				= freqs/5.83;			% spectral SD of wavelet at a frequency when using 5.83 cycles (leading to 1/2 octave spacings)
sdt				= 1 ./ (2 * pi * sdf);	% temporal SD, e.g. at 16Hz: 1/(2*pi*(16/5.83)) = .056 s
stepsize		= sdt/2;

% Load all data corresponding to one subject and night and pool it
for iSj = 1:numel(subjdata)
	for iNi = 1:2
		files = cell(3,1);
		try
			files{1} = get_filenames(path_origin, [subjdata(iSj).nid{iNi}, '_rs1'], 'full');
			files{2} = get_filenames(path_origin, [subjdata(iSj).nid{iNi}, '_rs2'], 'full');
			files{3} = get_filenames(path_origin, [subjdata(iSj).nid{iNi}, '_rs3'], 'full');
		catch
			warning(['Couldn''t find all files for subject ' subjdata(iSj).id '. Skipping...']);
			return
		end
		
		for iFile = 1:numel(files)
			data                = load_file(files{iFile});
			
			for iFreq = 1:numel(freqs)
				data_freq			= [];
				temp				= cell(numel(data.trial),1); % to collect single trials for later concatenation
				freq				= freqs(iFreq);
				path_result			= enpath([paths.rs_sensorcheck ' ' num2str(freq) ' Hz']);
				
				for iTrial = 1:numel(data.trial)
					% Translate data to frequency domain, keep the individual trials
					cfg                     = [];
					cfg.method              = 'wavelet';    % mtmfft = multitaper frequency transformation, no time dimension!
					cfg.keeptrials          = 'yes';
					cfg.width               = 5.83;             % (Hipp2012) length of wavelet (in cycles) as the SD of the underlying Gaussian
					cfg.gwidth              = 3;                % (Hipp2012) how much of the wavelet is estimated, in +/- SD (does not change spectral smoothing but accuracy)
					cfg.pad					= 'nextpow2';		% although padding shouldnt be needed
					cfg.foi                 = freq;
					cfg.toi                 = data.time{iTrial}(1)+((cfg.gwidth*2)*stepsize(iFreq))+1 : stepsize(iFreq) : data.time{iTrial}(end)-((cfg.gwidth*2)*stepsize(iFreq)+1); % see above
					cfg.trials              = iTrial;
					cfg.output              = 'fourier'; % 'fourier' / 'powandcsd';
					if ~isempty(cfg.toi)
						temp{iTrial}        = [];
						temp{iTrial}		= ft_freqanalysis(cfg, data);
						if sum(sum(isnan(temp{iTrial}.fourierspctrm(1,:,1,:)))) ~= 0, error('Results contains NANS!!'),end % TODO: Replace by 'any'?
					end
				end
				
				% Concatenate all trials
				for iTrial = 1:numel(temp)
					if ~isempty(temp{iTrial}) % take the first non-empty trial as template
						if isempty(data_freq)
							data_freq = temp{iTrial};
						else
							data_freq.fourierspctrm = cat(4, data_freq.fourierspctrm, temp{iTrial}.fourierspctrm);
							data_freq.time = [data_freq.time temp{iTrial}.time];
						end
					end
				end
				clear temp
				data_freq.id = data.id; % remember whos data this is
				
				% Plot the results
				data_des = ft_freqdescriptives([], data_freq);
				
				cfg					= [];
				cfg.layout			= 'egi_corrected.sfp';
				cfg.interplimits	= 'head'; % 'head' (default) or 'electrodes'
				cfg.style			= 'straight'; %default: both
				cfg.colorbar		= 'EastOutside';
				cfg.zlim			= 'zeromax';
				% 				cfg.colormap		= 'jet';
				figure; ft_topoplotTFR(cfg, data_des);
				export_fig(fullfile(path_result, data.id), '-nocrop', '-a2', '-m2');
				close all
				clear data_des data_freq
			end
			clear data
		end
	end
end

%% ------     SLEEP - SENSOR
% THIS TAKES THE DATA AFTER RE-REFERENCING IN RC__SOURCEANALYSIS !!
% YOU GOTTA RUN THAT STEP AGAIN IF YOU CHANGE THE DATA, OTHERWISE YOUR
% CHANGES WONT HAVE ANY EFFECT
paths.sl_sensorcheck	= fullfile(paths.home, 'sensorcheck sleep');
path_origin				= paths.sl_home;

freqs			= [2 10 25 40 65];
sdf				= freqs/5.83;			% spectral SD of wavelet at a frequency when using 5.83 cycles (leading to 1/2 octave spacings)
sdt				= 1 ./ (2 * pi * sdf);	% temporal SD, e.g. at 16Hz: 1/(2*pi*(16/5.83)) = .056 s
stepsize		= sdt/2;

% Load all data corresponding to one subject and night and pool it
for iSj = 1:numel(subjdata)
	for iNi = 1:2
		files = {};
		try
			files{1} = get_filenames(path_origin, [subjdata(iSj).nid{iNi}, '_sl'], 'full');
		catch
			warning(['Couldn''t find all files for subject ' subjdata(iSj).id '. Skipping...']);
			return
		end
		
		for iFile = 1:numel(files)
			data                = load_file(files{iFile});

			for iFreq = 1:numel(freqs)
				data_freq		= [];
				temp			= cell(numel(data.trial),1); % to collect single trials for later concatenation
				freq			= freqs(iFreq);
				path_result		= enpath([paths.sl_sensorcheck ' ' num2str(freq) ' Hz']);
				
				for iTrial = 1:numel(data.trial)
					% Translate data to frequency domain, keep the individual trials
					cfg                     = [];
					cfg.method              = 'wavelet';    % mtmfft = multitaper frequency transformation, no time dimension!
					cfg.keeptrials          = 'yes';
					cfg.width               = 5.83;             % (Hipp2012) length of wavelet (in cycles) as the SD of the underlying Gaussian
					cfg.gwidth              = 3;                % (Hipp2012) how much of the wavelet is estimated, in +/- SD (does not change spectral smoothing but accuracy)
					cfg.pad					= 'nextpow2';		% although padding shouldnt be needed
					cfg.foi                 = freq;
					cfg.toi                 = data.time{iTrial}(1)+((cfg.gwidth*2)*stepsize(iFreq))+1 : stepsize(iFreq) : data.time{iTrial}(end)-((cfg.gwidth*2)*stepsize(iFreq)+1); % see above
					cfg.trials              = iTrial;
					cfg.output              = 'fourier'; % 'fourier' / 'powandcsd';
					if ~isempty(cfg.toi)
						temp{iTrial}        = [];
						temp{iTrial}		= ft_freqanalysis(cfg, data);
						if sum(sum(isnan(temp{iTrial}.fourierspctrm(1,:,1,:)))) ~= 0, error('Results contains NANS!!'),end % TODO: Replace by 'any'?
					end
				end
				
				% Concatenate all trials
				for iTrial = 1:numel(temp)
					if ~isempty(temp{iTrial}) % take the first non-empty trial as template
						if isempty(data_freq)
							data_freq = temp{iTrial};
						else
							data_freq.fourierspctrm = cat(4, data_freq.fourierspctrm, temp{iTrial}.fourierspctrm);
							data_freq.time = [data_freq.time temp{iTrial}.time];
						end
					end
				end
				clear temp
				data_freq.id = data.id; % remember whos data this is
				% 			realsave(fullfile(path_result, [data_freq.id '_tfr_' num2str(freq) '_Hz.mat']), data_freq);
				
				% Plot the results
				data_des = ft_freqdescriptives([], data_freq);
				
				cfg					= [];
				cfg.layout			= 'egi_corrected.sfp';
				cfg.interplimits	= 'head'; % 'head' (default) or 'electrodes'
				cfg.style			= 'straight'; %default: both
				cfg.colorbar		= 'EastOutside';
				cfg.zlim			= 'zeromax';
% 				cfg.colormap		= 'jet';
				figure; ft_topoplotTFR(cfg, data_des);
				export_fig(fullfile(path_result, data.id), '-nocrop', '-a2', '-m2');
				close all
				clear data_freq data_des
			end
			clear data
		end
	end
end

%% ------     RS - SANITY CHECK SOURCE	
% Problem: s05 n1 rs1 data_freq has electrode 4 which is not in elec ; elec has electrode which is not in data_freq
% Calculate a median split of unilateral alpha activity and beam that to
% source level; we use a single spatial filter for each recording here, to
% sot potential problems. Later common filters will be used.
path_origin		= paths.rs_home;
path_sourceplot	= enpath(fullfile(paths.home, 'sourcecheck resting-state alpha'));

freqs			= [10];
sdf				= freqs/5.83;			% spectral SD of wavelet at a frequency when using 5.83 cycles (leading to 1/2 octave spacings)
sdt				= 1 ./ (2 * pi * sdf);	% temporal SD, e.g. at 16Hz: 1/(2*pi*(16/5.83)) = .056 s
stepsize		= sdt/2;

% Load all data corresponding to one subject and night and pool it
for iSj = 1:numel(subjdata)
	for iNi = 1:2
		files = cell(3,1);
		try
			files{1} = get_filenames(path_origin, [subjdata(iSj).nid{iNi}, '_rs1'], 'full');
			files{2} = get_filenames(path_origin, [subjdata(iSj).nid{iNi}, '_rs2'], 'full');
			files{3} = get_filenames(path_origin, [subjdata(iSj).nid{iNi}, '_rs3'], 'full');
		catch
			warning(['Couldn''t find all files for subject ' subjdata(iSj).id '. Skipping...']);
			return
		end
		
		grid						= load_file(paths.grids, subjdata(iSj).id);        % previously computed grid
		vol							= load_file(paths.headmodels_rs, subjdata(iSj).nid{iNi});   % previously computed volume conduction model
		elec						= load_file(paths.elecs_rs, subjdata(iSj).nid{iNi});		% Caution: The number here and above may lead to an error if not all frequencies were compute
	
		for iFile = 1:numel(files)
			data                = load_file(files{iFile});
			[~,name,~]			= fileparts(files{iFile});
			
			iFreq				= 1;
			data_freq			= [];
			temp				= cell(numel(data.trial),1); % to collect single trials for later concatenation
			freq				= freqs(iFreq);
			path_result			= path_sourceplot;
			
			for iTrial = 1:numel(data.trial)
				% Translate data to frequency domain, keep the individual trials
				cfg                     = [];
				cfg.method              = 'wavelet';    % mtmfft = multitaper frequency transformation, no time dimension!
				cfg.keeptrials          = 'yes';
				cfg.width               = 5.83;             % (Hipp2012) length of wavelet (in cycles) as the SD of the underlying Gaussian
				cfg.gwidth              = 3;                % (Hipp2012) how much of the wavelet is estimated, in +/- SD (does not change spectral smoothing but accuracy)
				cfg.pad					= 'nextpow2';		% although padding shouldnt be needed
				cfg.foi                 = freq;
				cfg.toi                 = data.time{iTrial}(1)+((cfg.gwidth*2)*stepsize(iFreq))+1 : stepsize(iFreq) : data.time{iTrial}(end)-((cfg.gwidth*2)*stepsize(iFreq)+1); % see above
				cfg.trials              = iTrial;
				cfg.output              = 'fourier'; % 'fourier' / 'powandcsd';
				if ~isempty(cfg.toi)
					temp{iTrial}        = [];
					temp{iTrial}		= ft_freqanalysis(cfg, data);
					if sum(sum(isnan(temp{iTrial}.fourierspctrm(1,:,1,:)))) ~= 0, error('Results contains NANS!!'),end % TODO: Replace by 'any'?
				end
			end
			
			% Concatenate all trials
			for iTrial = 1:numel(temp)
				if ~isempty(temp{iTrial}) % take the first non-empty trial as template
					if isempty(data_freq)
						data_freq = temp{iTrial};
					else
						data_freq.fourierspctrm = cat(4, data_freq.fourierspctrm, temp{iTrial}.fourierspctrm);
						data_freq.time = [data_freq.time temp{iTrial}.time];
					end
				end
			end
			clear temp
			data_freq.id = data.id; % remember whos data this is
			
			data_freq.fourierspctrm		= permute(data_freq.fourierspctrm, [4 2 3 1]);
			data_freq.dimord			= 'rpttap_chan_freq'; % rpt_chan_freq leads to terrible fieldtrip failure (ft_sourceanalysis, line 630) and hours of troubleshooting..
			data_freq.cumtapcnt			= ones(size(data_freq.fourierspctrm,1),1);
			data_freq					= rmfield(data_freq, 'time');
			
			cfg							= [];
			cfg.keeptrials				= 'yes';
			tmp							= ft_freqdescriptives(cfg, data_freq);
			
			chanind						= find(mean(tmp.powspctrm,1)==max(mean(tmp.powspctrm,1)));  % find the sensor where power is max
			indlow						= find(tmp.powspctrm(:,chanind)<=median(tmp.powspctrm(:,chanind)));
			indhigh						= find(tmp.powspctrm(:,chanind)>=median(tmp.powspctrm(:,chanind)));
			
			cfg							= [];
			cfg.grid					= grid;
			cfg.headmodel				= vol;
			cfg.elec					= elec;
			cfg.normalize				= 'no';			% set to 'yes' later on
			cfg.channel					= 'all';
			lf							= ft_prepare_leadfield(cfg, data_freq);		% data can be any frequency, leadfield is not data-dependent
			
			cfg							= [];
			cfg.method					= 'pcc';
			cfg.grid					= lf;
			cfg.headmodel				= vol;			% the actual leadfield is computed quickly on the fly if not provided
			cfg.elec					= elec;
			cfg.keeptrials				= 'yes';
			cfg.pcc.keepfilter			= 'yes';        % remember the filter, only needed for sanity checks; can be set to 'no' later on
			cfg.pcc.realfilter			= 'yes';		% use only the real part of the filter
			% cfg.pcc.fixedori			= 'yes';        % TODO: check if that actually changes the filter and how hipp did it
			cfg.pcc.lambda				= '5%';
			cfg.pcc.projectnoise		= 'yes';		% Project noise - Then we can calculate the NAI later...
			sources						= ft_sourceanalysis(cfg, data_freq);
			
			tmp_low						= data_freq;
			tmp_low.fourierspctrm		= data_freq.fourierspctrm(indlow,:);
			tmp_low.cumtapcnt			= data_freq.cumtapcnt(indlow,:);
			
			tmp_high					= data_freq;
			tmp_high.fourierspctrm		= data_freq.fourierspctrm(indhigh,:);
			tmp_high.cumtapcnt			= data_freq.cumtapcnt(indhigh,:);
			
			cfg.grid.filter				= sources.avg.filter;
			sources_low					= ft_sourceanalysis(cfg, tmp_low);
			sources_high				= ft_sourceanalysis(cfg, tmp_high);
			
			cfg_sd = []; cfg_sd.keepcsd = 'yes'; cfg_sd.keepnoisecsd = 'yes';
			sources_high				= ft_sourcedescriptives(cfg_sd,sources_high);
			sources_low				= ft_sourcedescriptives(cfg_sd,sources_low);
			
			cfg							= [];
			cfg.operation				= 'log10(x1)-log10(x2)';
			cfg.parameter				= 'pow';
			source_ratio				= ft_math(cfg, sources_high, sources_low);
			
			% create a fancy mask
			source_ratio.mask = (1+tanh(2.*(source_ratio.pow./max(source_ratio.pow(:))-0.5)))./2;
			
			sourcemodel					= load_file('standard_sourcemodel3d10mm.mat');
			mri							= ft_read_mri('single_subj_T1_1mm.nii');
			source_ratio.pos			= sourcemodel.pos;
			sources_high.pos			= sourcemodel.pos;
			
			cfg_int						= [];
			cfg_int.downsample			= 1;           % default: 1 (no downsampling)
			cfg_int.parameter			= {'pow' 'nai' 'noise'};
			source_highd_int			= ft_sourceinterpolate(cfg_int, sources_high, mri);
			cfg_int.parameter			= {'pow'};
			source_ratio_int			= ft_sourceinterpolate(cfg_int, source_ratio, mri);
			
			cfg							= [];
			cfg.method					= 'slice';
			cfg.funparameter			= 'pow';
			cfg.funcolorlim				= 'zeromax';
			cfg.surfdownsample			= 4;
			ft_sourceplot(cfg, source_highd_int);
			export_fig(fullfile(path_sourceplot, [data.id '_high']), '-nocrop', '-a2', '-m2');
			close all
			ft_sourceplot(cfg, source_ratio_int);
			export_fig(fullfile(path_sourceplot, [data.id '_ratio']), '-nocrop', '-a2', '-m2');
			close all
		end
	end
end

%% ------     TODO: SLEEP - SANITY CHECK SOURCE	
% Problem: s05 n1 rs1 data_freq has electrode 4 which is not in elec ; elec has electrode which is not in data_freq
% Calculate a median split of unilateral alpha activity and beam that to
% source level; we use a single spatial filter for each recording here, to
% sot potential problems. Later common filters will be used.
path_origin		= paths.sl_home;
path_sourceplot	= enpath(fullfile(paths.home, 'sourcecheck sleep alpha'));

freqs			= [10];
sdf				= freqs/5.83;			% spectral SD of wavelet at a frequency when using 5.83 cycles (leading to 1/2 octave spacings)
sdt				= 1 ./ (2 * pi * sdf);	% temporal SD, e.g. at 16Hz: 1/(2*pi*(16/5.83)) = .056 s
stepsize		= sdt/2;

% Load all data corresponding to one subject and night and pool it
for iSj = 13:numel(subjdata)
	for iNi = 1:2
		files = cell(1,1);
		try
			files{1} = get_filenames(path_origin, [subjdata(iSj).nid{iNi}, '_sl'], 'full');
		catch
			warning(['Couldn''t find file for ' subjdata(iSj).id '. Skipping...']);
			return
		end
		
		grid						= load_file(paths.grids, subjdata(iSj).id);        % previously computed grid
		vol							= load_file(paths.headmodels_sl, subjdata(iSj).nid{iNi});   % previously computed volume conduction model
		elec						= load_file(paths.elecs_sl, subjdata(iSj).nid{iNi});		% Caution: The number here and above may lead to an error if not all frequencies were compute
	
		for iFile = 1:numel(files)
			data                = load_file(files{iFile});
			[~,name,~]			= fileparts(files{iFile});
			
			iFreq				= 1;
			data_freq			= [];
			temp				= cell(numel(data.trial),1); % to collect single trials for later concatenation
			freq				= freqs(iFreq);
			path_result			= path_sourceplot;
			
			for iTrial = 1:numel(data.trial)
				% Translate data to frequency domain, keep the individual trials
				cfg                     = [];
				cfg.method              = 'wavelet';    % mtmfft = multitaper frequency transformation, no time dimension!
				cfg.keeptrials          = 'yes';
				cfg.width               = 5.83;             % (Hipp2012) length of wavelet (in cycles) as the SD of the underlying Gaussian
				cfg.gwidth              = 3;                % (Hipp2012) how much of the wavelet is estimated, in +/- SD (does not change spectral smoothing but accuracy)
				cfg.pad					= 'nextpow2';		% although padding shouldnt be needed
				cfg.foi                 = freq;
				cfg.toi                 = data.time{iTrial}(1)+((cfg.gwidth*2)*stepsize(iFreq))+1 : stepsize(iFreq) : data.time{iTrial}(end)-((cfg.gwidth*2)*stepsize(iFreq)+1); % see above
				cfg.trials              = iTrial;
				cfg.output              = 'fourier'; % 'fourier' / 'powandcsd';
				if ~isempty(cfg.toi)
					temp{iTrial}        = [];
					temp{iTrial}		= ft_freqanalysis(cfg, data);
					if sum(sum(isnan(temp{iTrial}.fourierspctrm(1,:,1,:)))) ~= 0, error('Results contains NANS!!'),end % TODO: Replace by 'any'?
				end
			end
			
			% Concatenate all trials
			for iTrial = 1:numel(temp)
				if ~isempty(temp{iTrial}) % take the first non-empty trial as template
					if isempty(data_freq)
						data_freq = temp{iTrial};
					else
						data_freq.fourierspctrm = cat(4, data_freq.fourierspctrm, temp{iTrial}.fourierspctrm);
						data_freq.time = [data_freq.time temp{iTrial}.time];
					end
				end
			end
			clear temp
			data_freq.id = data.id; % remember whos data this is
			
			data_freq.fourierspctrm		= permute(data_freq.fourierspctrm, [4 2 3 1]);
			data_freq.dimord			= 'rpttap_chan_freq'; % rpt_chan_freq leads to terrible fieldtrip failure (ft_sourceanalysis, line 630) and hours of troubleshooting..
			data_freq.cumtapcnt			= ones(size(data_freq.fourierspctrm,1),1);
			data_freq					= rmfield(data_freq, 'time');
			
			cfg							= [];
			cfg.keeptrials				= 'yes';
			tmp							= ft_freqdescriptives(cfg, data_freq);
			
			chanind						= find(mean(tmp.powspctrm,1)==max(mean(tmp.powspctrm,1)));  % find the sensor where power is max
			indlow						= find(tmp.powspctrm(:,chanind)<=median(tmp.powspctrm(:,chanind)));
			indhigh						= find(tmp.powspctrm(:,chanind)>=median(tmp.powspctrm(:,chanind)));
			
			cfg							= [];
			cfg.grid					= grid;
			cfg.headmodel				= vol;
			cfg.elec					= elec;
			cfg.normalize				= 'no';			% set to 'yes' later on
			cfg.channel					= 'all';
			lf							= ft_prepare_leadfield(cfg, data_freq);		% data can be any frequency, leadfield is not data-dependent
			
			cfg							= [];
			cfg.method					= 'pcc';
			cfg.grid					= lf;
			cfg.headmodel				= vol;			% the actual leadfield is computed quickly on the fly if not provided
			cfg.elec					= elec;
			cfg.keeptrials				= 'yes';
			cfg.pcc.keepfilter			= 'yes';        % remember the filter, only needed for sanity checks; can be set to 'no' later on
			cfg.pcc.realfilter			= 'yes';		% use only the real part of the filter
			% cfg.pcc.fixedori			= 'yes';        % TODO: check if that actually changes the filter and how hipp did it
			cfg.pcc.lambda				= '5%';
			cfg.pcc.projectnoise		= 'yes';		% Project noise - Then we can calculate the NAI later...
			sources						= ft_sourceanalysis(cfg, data_freq);
			
			% Take over the common filter
			cfg.grid.filter				= sources.avg.filter;
			clear sources
			
			tmp_low						= data_freq;
			tmp_low.fourierspctrm		= data_freq.fourierspctrm(indlow,:);
			tmp_low.cumtapcnt			= data_freq.cumtapcnt(indlow,:);
			
			tmp_high					= data_freq;
			tmp_high.fourierspctrm		= data_freq.fourierspctrm(indhigh,:);
			tmp_high.cumtapcnt			= data_freq.cumtapcnt(indhigh,:);
			clear data_freq
			
			sources_low					= ft_sourceanalysis(cfg, tmp_low);
			sources_high				= ft_sourceanalysis(cfg, tmp_high);
			clear tmp_low tmp_high
			
			cfg_sd = []; cfg_sd.keepcsd = 'yes'; cfg_sd.keepnoisecsd = 'yes';
			sources_high				= ft_sourcedescriptives(cfg_sd,sources_high);
			sources_low					= ft_sourcedescriptives(cfg_sd,sources_low);
			
			cfg							= [];
			cfg.operation				= 'log10(x1)-log10(x2)';
			cfg.parameter				= 'pow';
			source_ratio				= ft_math(cfg, sources_high, sources_low);
			
			% create a fancy mask
			source_ratio.mask = (1+tanh(2.*(source_ratio.pow./max(source_ratio.pow(:))-0.5)))./2;
			
			sourcemodel					= load_file('standard_sourcemodel3d10mm.mat');
			mri							= ft_read_mri('single_subj_T1_1mm.nii');
			source_ratio.pos			= sourcemodel.pos;
			sources_high.pos			= sourcemodel.pos;
			
			cfg_int						= [];
			cfg_int.downsample			= 1;           % default: 1 (no downsampling)
			cfg_int.parameter			= {'pow' 'nai' 'noise'};
			source_highd_int			= ft_sourceinterpolate(cfg_int, sources_high, mri);
			cfg_int.parameter			= {'pow'};
			source_ratio_int			= ft_sourceinterpolate(cfg_int, source_ratio, mri);
			
			cfg							= [];
			cfg.method					= 'slice';
			cfg.funparameter			= 'pow';
			cfg.funcolorlim				= 'zeromax';
			cfg.surfdownsample			= 4;
			ft_sourceplot(cfg, source_highd_int);
			export_fig(fullfile(path_sourceplot, [data.id '_high']), '-nocrop', '-a2', '-m2');
			close all
			ft_sourceplot(cfg, source_ratio_int);
			export_fig(fullfile(path_sourceplot, [data.id '_ratio']), '-nocrop', '-a2', '-m2');
			close all
			clear sources_high source_ratio source_ratio_int source_highd_int
		end
	end
end
