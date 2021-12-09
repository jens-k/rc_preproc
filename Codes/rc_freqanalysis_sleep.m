function rc_freqanalysis_sleep(cfg)
% Wrapper function for ft_freqanalysis for use with qsub. Very
% custom-build for the reactivated connectivity project.
%
% Also rearranges the result so that it looks like independent 
% observations. Takes a hypnogram in order to only frequency-transform time
% points in SWS. Further takes the events of the original recording to
% split tfr into odor and vehicle.
%
% Only time points are analyzed for which +/- 2 temporal SDs of the wavelet 
% are within the stimulation (odor / vehicle) time window.
% Condition coding: odor = 1; vehicle = 2
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
% cfg.params.hypno			string, path to hypnogram
% cfg.params.events			events extracted from original dataset using
%							ft_read_event
% cfg.params.originalfs		sampling rate of original raw data
% cfg.params.skip_existing	logical; optional, skips tfr if output file
%							already exists

%% ---------- SETUP ----------
if ~isfield(cfg.params, 'channel'), cfg.params.channel = []; end
requiredFields = {'channel', 'freq', 'stepsize', 'inputfile', 'outputfile', 'hypno', 'events', 'originalfs'};
for i = requiredFields
	if ~isfield(cfg.params,i)
		error(['Required field missing in cfg: ' i{1} '.']);
	end
end

if ~isfield(cfg.params, 'skip_existing'), cfg.params.skip_existing = false; end


% HYPNOGRAM
hypno						= load_hypnogram(cfg.params.hypno);
hypno(hypno(:,2) == 1, 1)	= 0; 
epoch_length				= 30; % we assume a hypnogram epoch length of 30 s

% STIMULATION EVENTS	- depends only on events and hypnograms
events									= cfg.params.events; % stimulation events
fs										= cfg.params.originalfs;
cidx_all								= {events.mffkey_cidx}; % mmfkey_cidx is the same number for on and off (gidx is one for on, one for off)
cidx_all(cellfun('isempty',cidx_all))	= [];
cidx_all								= cellfun(@str2double,cidx_all);
cidx_unique								= sort(unique(cidx_all));

for cidx = numel(cidx_unique):-1:1
	idx = find(strcmp({events.mffkey_cidx}, num2str(cidx_unique(cidx)))); % where in the event structure are we
	
	% For each event, check whether it occurs exactly twice (start/end)
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

% Now all events are valid, all odd ones are odor, all even ones are vehicle
cidx_odor			= cidx_unique(mod(cidx_unique,2) ~= 0);
cidx_vehicle		= cidx_unique(mod(cidx_unique,2) == 0);

% For filtering out all events that are not within the stimulation
% time range
stim_start	= find(strcmp({events.mffkey_cidx}, num2str(cidx_unique(1))));
stim_start	= events(stim_start(1)).sample / cfg.params.originalfs;
stim_end	= find(strcmp({events.mffkey_cidx}, num2str(cidx_unique(end))));
stim_end	= events(stim_end(2)).sample / cfg.params.originalfs;

% DATA
% Take care of the channels
data				= load_file(cfg.params.inputfile);
cfg_sel				= [];
cfg_sel.channel		= cfg.params.channel;
data				= ft_selectdata(cfg_sel, data);
% id					= data.id;


%% ---------- START ----------
for iFreq = 1:numel(cfg.params.freq)
	temp	= cell(numel(data.trial),1);	% to collect single trials for later concatenation
	conds	= cell(numel(data.trial),1);	% to keep track of conditions; 1 = odor; 2 = vehicle; 0 = none

	outputfile = [cfg.params.outputfile '_' num2str(cfg.params.freq(iFreq),'%4.2f') '.mat'];
	if exist(outputfile, 'file') && cfg.params.skip_existing, warning('Frequency has already been processed. Skipping...'), continue, end	

	for iTrial = 1:numel(data.trial)
		% Get potential time points in trial and test them for whether they
		% are during odor, vehicle, or neither of those; gwidth is the size
		% to which the wavelet is going to be estimated in sdt
		
		% Make sure no sample is ever beyond the temporal borders of the
		% trial; +100/data.fsample adds 100 samples to the margins, that's
		% needed because fieldtrip may adjust the frequency slightly which
		% occasionally led to NaNs. Alternatively one could check for NaNs
		% and through away the first spectrial estimate.
		tois         = data.time{iTrial}(1)+(cfg.gwidth*cfg.params.sdt(iFreq))+100/data.fsample : cfg.params.stepsize(iFreq) : data.time{iTrial}(end)-(cfg.gwidth*cfg.params.sdt(iFreq)+100/data.fsample);
		
		if ~isempty(tois)
			% For each toi, let's make sure the wavelet is fully within the
			% stimulation time window
			for iToi = 1:numel(tois)
				% using a margin of 2 SDs
				t_start = tois(iToi) - (2*cfg.params.sdt(iFreq) + 1/data.fsample); % start of time window
				t_end	= tois(iToi) + (2*cfg.params.sdt(iFreq) + 1/data.fsample); % end of time window
				if ~(t_start < t_end), error('Start after end.'), end
				conds{iTrial}(iToi) = 0;
				
				% If toi is inside the broad stimulation time period, let's
				% check if it is right during a stimulation
				if tois(iToi) > stim_start && tois(iToi) < stim_end
					for i = 1:numel(cidx_unique)
						idx = find(strcmp({events.mffkey_cidx}, num2str(cidx_unique(i))));
						if t_start > (events(idx(1)).sample / cfg.params.originalfs) && t_end < (events(idx(2)).sample / cfg.params.originalfs)
							if any(cidx_unique(i) == cidx_odor)
								conds{iTrial}(iToi) = 1;
							elseif any(cidx_unique(i) == cidx_vehicle)
								conds{iTrial}(iToi) = 2;
							end
						end
						if conds{iTrial}(iToi) ~= 0; break, end
					end
				end
			end
			
			% Take out all no-condition time points from condition
			% bookkeeping and tois
			tois(conds{iTrial} == 0) = [];
			conds{iTrial}(conds{iTrial} == 0) = [];
			
			% Translate data to frequency domain, keep the individual trials
			cfg.foi                 = cfg.params.freq(iFreq);
			cfg.trials              = iTrial;
			cfg.toi					= tois;
			if ~isempty(cfg.toi)
				disp('If 5 analysis steps before, there were more trials than now, ft_freqanalysis might throw a warning. I don''t think there is an actual problem though.')
				temp{iTrial}        = [];
				temp{iTrial}		= ft_freqanalysis(cfg, data);
				if sum(sum(isnan(temp{iTrial}.fourierspctrm(1,:,1,:)))) ~= 0, error('Results contains NANS!!'),end
			end
		end
	end

	% Concatenate all trials
	freq	= {};
	for iTrial = 1:numel(temp)
		if ~isempty(temp{iTrial})
			if isempty(freq) % take the first non-empty trial as template
				freq = temp{iTrial};
				freq.cond = conds{iTrial};
			else
				freq.fourierspctrm = cat(4, freq.fourierspctrm, temp{iTrial}.fourierspctrm);
				freq.time = [freq.time temp{iTrial}.time];
				freq.cond = [freq.cond conds{iTrial}];
			end
		end
	end
	freq.cfg.timealignedto = 'rawdata';
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
	freq.origtime		 = freq.time;
	freq                 = rmfield(freq, 'time');
	realsave(outputfile, freq);
end
		
		


%% ------------- OLD CODE FOR FIXING THE DATA TIMELINE --------------
% ... which is now done right at the time when data is re-sampled

% Fix trial timelines 
% For each original trl (trials originally created by the trialfun),
% fieldtrip resets the timeline to 0 (as if they were actual trials). We
% need to fix this. We do this by looking for time resets and hope no full
% trials were ever discarded during preprocessing.
% trl_book	= [];
% cur_trl		= 1; trl_book(1,1) = cur_trl;
% last_end	= data.time{1}(end); % we assume the first trial belong to the first trl
% 
% for iTrial = 2:numel(data.time)
% 	% if the timing was reset, we are in the next trl
% 	if data.time{iTrial}(1) < last_end
% 		cur_trl = cur_trl + 1;
% 	end
% 	trl_book(iTrial,1) = cur_trl;
% 	last_end = data.time{iTrial}(end);
% end
% 
% % All this might not have worked, e.g. if a whole trl was discarded during
% % artifact rejection, then we gotta go into the data manually
% if max(trl_book) ~= size(cfg.params.trl, 1)
% 	error('Uff, this dataset does have very unexpected trial times.')
% end
% 
% % Let's fix trial times so that they are fully in line with the events
% % and hypnogram
% for iTrial = 1:numel(data.time)
% 	% Add offset of current trl to all time points
% 	data.time{iTrial} = data.time{iTrial} + (cfg.params.trl(trl_book(iTrial), 1) / cfg.params.originalfs); 
% end