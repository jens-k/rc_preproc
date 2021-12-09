function rc_freqanalysis(cfg)
% Wrapper function for ft_freqanalysis for use with qsub. Very
% custom-build for the reactivated connectivity project.
%
% Also joins given data sets and rearranges the result so that it looks
% like independent observations. 
%
% INPUT VARIABLES:
% cfg		cfg to be forwarded to wrapped functions.
%
% The cfg must have additional fields with parameters for this wrapper
% function:
% cfg.params.channel		optional; cell array of strings
% cfg.params.freq			frequencies to be analyzed (each frequency will
%							be computed and saved separately)
% cfg.params.stepsize		stepsize for each frequency
% cfg.params.inputfile		string, filename to process, can be a cell
%							array of inputfilenames, those will be appended 
%							before wrapped function is called
% cfg.params.outputfile

% SETUP
if ~isfield(cfg.params, 'channel'), cfg.params.channel = []; end
requiredFields = {'channel', 'freq', 'stepsize', 'inputfile', 'outputfile'};
for i = requiredFields
	if ~isfield(cfg.params,i)
		error(['Required field missing in cfg: ' i{1} '.']);
	end
end
if ~iscell(cfg.params.inputfile), cfg.params.inputfile = {cfg.params.inputfile}; end

% START
data_sep = cell(numel(cfg.params.inputfile),1);
condition_index     = [];	% keeps track of which trial belongs to which resting-state recording. 
for iFile = 1:numel(cfg.params.inputfile)
		data_sep{iFile}		= load_file(cfg.params.inputfile{iFile});
		cfg_sel				= []; 
		cfg_sel.channel		= cfg.params.channel;
		data_sep{iFile}		= ft_selectdata(cfg_sel, data_sep{iFile});
		condition_index		= [condition_index, ones(1,length(data_sep{iFile}.trial)) * iFile];
end
condition_index		= int8(condition_index); % lets save some memory
data				= ft_appenddata([], data_sep{:});  % combine the datasets
id					= data_sep{1}.id;
clear data_sep

temp	= cell(numel(data.trial),1);	% to collect single trials for later concatenation
for iFreq = 1:numel(cfg.params.freq)
	for iTrial = 1:numel(data.trial)
		% Translate data to frequency domain, keep the individual trials
		cfg.foi                 = cfg.params.freq(iFreq);
		cfg.toi                 = data.time{iTrial}(1)+((cfg.gwidth*2)*cfg.params.stepsize(iFreq))+1 : cfg.params.stepsize(iFreq) : data.time{iTrial}(end)-((cfg.gwidth*2)*cfg.params.stepsize(iFreq)+1); % TODO I think this could be + 1 / sampling frequency; currently we're losing a whole second (?)
		cfg.trials              = iTrial;
		
		if ~isempty(cfg.toi)
			temp{iTrial}        = [];
			temp{iTrial}		= ft_freqanalysis(cfg, data);
			
			temp{iTrial}.cond(1:size(temp{iTrial}.time,2)) = condition_index(iTrial);   % keep track in which the current trial is
			if sum(sum(isnan(temp{iTrial}.fourierspctrm(1,:,1,:)))) ~= 0, error('Results contains NANS!!'),end % TODO: Replace by 'any'?
		end
	end
	
	% Concatenate all trials
	freq	= {};
	for iTrial = 1:numel(temp)
		if ~isempty(temp{iTrial})
			if isempty(freq) % take the first non-empty trial as template
				freq = temp{iTrial};
			else
				freq.fourierspctrm = cat(4, freq.fourierspctrm, temp{iTrial}.fourierspctrm);
				freq.time = [freq.time temp{iTrial}.time];
				freq.cond = [freq.cond temp{iTrial}.cond];
			end
		end
	end
	clear temp
	
	% Remember whos data this is
	if isfield(cfg.params, 'nid')
		freq.nid = cfg.params.nid;
	end
	if isfield(cfg.params, 'id')
		freq.id = cfg.params.id;
	end
	
	% Lets rearrange our data in a way that every wavelet is considered
	% an independent observation (repetition) instead of a time point.
	% Rearrangement checked and works
	% Alternatively, we could bring everything in a .trial(n) type of
	% structure to use ft_sourcedescriptives' trial selection later on
	
	freq.fourierspctrm   = permute(freq.fourierspctrm, [4 2 3 1]);
	freq.dimord          = 'rpttap_chan_freq'; % rpt_chan_freq leads to terrible fieldtrip failure (ft_sourceanalysis, line 630) and hours of troubleshooting..
	freq.cumtapcnt       = ones(size(freq.fourierspctrm,1),1);
	freq                 = rmfield(freq, 'time');

	realsave([cfg.params.outputfile '_' num2str(cfg.params.freq(iFreq),'%4.2f') '.mat'], freq);
end
		
		
	



		
		