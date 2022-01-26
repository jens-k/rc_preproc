% init_rc
channels_min                = {'all', '-E49', '-E48', '-E43', '-E127', '-E126', '-E17', '-E128', '-E32', '-E25', '-E21', '-E14', '-E8', '-E1', '-E125', '-E120', '-E119', '-E113', '-E56', '-E63', '-E68', '-E73', '-E81', '-E88', '-E94', '-E99', '-E107', '-E57', '-E100'};

cfg                     = [];
cfg.dataset				= abpath(sdata(15).rs2{1}); % abpath(sdata(1).learn{1}); %abpath(sdata(1).rs1{1}); % 'Y:\Jens\*******.mff'; %'Y:\Jens\Buckettest_1_20180822_123637.mff'; % abpath(subjdata(5).rs1{1});
% cfg.reref               = 'yes';
% cfg.refchannel          = 'all'; % = average reference
% cfg.implicitref			= 'VREF'; % TODO: Rename this to Cz? (also in the electrode files, transfer matrices etc.)
% cfg.dftfilter			= 'yes'; % just in case later analysis frequency windows overlap with 50 Hz
data					= ft_preprocessing(cfg);
events					= ft_read_event(cfg.dataset);

% cfg						= [];
% cfg.channel				= channels_min{:};
% data					= ft_selectdata(cfg, data);

cfg					= [];
cfg.latency			= [100 180];
data					= ft_selectdata(cfg, data);

% cfg						= [];
% cfg.resamplefs          = 500;
% cfg.detrend             = 'no';
% data					= ft_resampledata(cfg, data);

cfg                     = [];
cfg.viewmode            = 'vertical';
% cfg.ylim				= [-35 35];
cfg.continuous			= 'yes';
cfg.blocksize			= 30;
cfg.channel             = data.label(1:30); % check all channels though (e.g. on the way back)!
cfg.preproc.detrend     = 'yes';
cfg.preproc.hpfilter    = 'yes';
cfg.preproc.hpfreq		= .6;
cfg.preproc.bsfilter    = 'yes';
cfg.preproc.bsfreq		= [48 52];
cfg.plotevents			= 'yes';
% cfg.event				= events;
ft_databrowser(cfg, data);

freq			= 35;
sdf				= freq/5.83;			% spectral SD of wavelet at a frequency when using 5.83 cycles (leading to 1/2 octave spacings)
sdt				= 1 ./ (2 * pi * sdf);	% temporal SD, e.g. at 16Hz: 1/(2*pi*(16/5.83)) = .056 s
stepsize		= sdt/2;


data_freq			= [];
temp				= cell(numel(data.trial),1); % to collect single trials for later concatenation

for iTrial = 1:numel(data.trial)
	% Translate data to frequency domain, keep the individual trials
	cfg                     = [];
	cfg.method              = 'wavelet';    % mtmfft = multitaper frequency transformation, no time dimension!
	cfg.keeptrials          = 'yes';
	cfg.width               = 5.83;             % (Hipp2012) length of wavelet (in cycles) as the SD of the underlying Gaussian
	cfg.gwidth              = 3;                % (Hipp2012) how much of the wavelet is estimated, in +/- SD (does not change spectral smoothing but accuracy)
	cfg.pad					= 'nextpow2';		% although padding shouldnt be needed
	cfg.foi                 = freq;
	cfg.toi                 = data.time{iTrial}(1)+((cfg.gwidth*2)*stepsize)+1 : stepsize : data.time{iTrial}(end)-((cfg.gwidth*2)*stepsize+1); % see above
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
% clear temp

% Plot the results
data_des = ft_freqdescriptives([], data_freq);

cfg					= [];
cfg.layout			= 'egi_corrected.sfp';
cfg.interplimits	= 'head'; % 'head' (default) or 'electrodes'
cfg.style			= 'straight'; %default: both
cfg.colorbar		= 'EastOutside';
cfg.zlim			= 'zeromax';
figure; ft_topoplotTFR(cfg, data_des);

export_fig(fullfile(path_result, data.id), '-nocrop', '-a2', '-m2');
close all





clear data_des data_freq
clear data
