function [trl, events] = trialfun_sl(cfg)
% cfg.trialdef.post_start       int; how much after the on trigger should we start (in sec)
% cfg.trialdef.pre_end			int; how much before the off trigger should we start (in sec)
% cfg.dataset                   string; path to dataset
% cfg.hypnogram					string; path to hypnogram
%
% Comments on particlar datasets:
% s44_n2_sl		does not have a lights on trigger -> skipped trigger sanity checks

%% Setup
% Check for required fields in the configuration data
requiredFields = {'trialdef', 'dataset', 'hypnogram'};
for i = requiredFields
	if ~isfield(cfg,i)
		error(['Required field missing in cfg: ' i{1} ' (%s).'], cfg.id);
	end
end

epoch_length_sec		= 30;       % length of epochs in hypnogram in s


%% Load and check data
hdr                 = ft_read_header(cfg.dataset);
events              = ft_read_event(cfg.dataset);
hyp					= load_hypnogram(cfg.hypnogram);
epoch_length_smpl	= epoch_length_sec * hdr.Fs;

% Deal with manual and odor triggers
trigger_recstart    = events(strcmp('epoch', {events.type}));
trigger_start       = events(strcmp('4___', {events.value})); % lights out
trigger_end			= events(strcmp('5___', {events.value})); % lights on
trigger_on			= events(strcmp('DIN1', {events.value})); % odor on
trigger_off			= events(strcmp('DIN2', {events.value})); % odor off
trigger_tests		= events(strcmp('1___', {events.value}) | strcmp('2___', {events.value}) | strcmp('3___', {events.value}));
trigger_misc		= events(strcmp('net', {events.value}));

%% Sanity checks
% Data shouldn't be more than one (+1) epoch longer than the hypnogram
% (incomplete epochs are dropped by SchlafAUS) and never be shorter

% Special treatment for some particular datasets
if ~strcmp(cfg.id, 's44_n2_sl') && ~strcmp(cfg.id, 's47_n1_sl') && ~strcmp(cfg.id, 's51_n1_sl') 
	if hdr.nSamples > (length(hyp)+1) * epoch_length_smpl || hdr.nSamples < length(hyp) * epoch_length_smpl
		error('Data header and hypnogram do not match.')
	end
	
	% Sanity checks on the triggers
	if numel(trigger_recstart) ~= 1
		warning('There are more than one EGI recording start triggers in this dataset. You might want to double-check (%s, counter %s).\n', cfg.id, num2str(cfg.counter))
	end
	if numel(trigger_start) ~= 1 || numel(trigger_end) ~= 1
		warning('Unexpected number of lights on / off triggers. (%s, counter %s).\n', cfg.id, num2str(cfg.counter))
	end
	if numel(trigger_on) ~=  numel(trigger_off)
		warning('Unequal number of odor on and off triggers (DIN1/2). (%s, counter %s).\n', cfg.id, num2str(cfg.counter))
	end
	
	% Did we identify all triggers?
	if numel(trigger_recstart) + numel(trigger_start) + numel(trigger_end) + numel(trigger_on) + numel(trigger_off) + numel(trigger_tests) + numel(trigger_misc) ~= numel(events)
		warning('Some events could not be identified (%s, counter %s).\n', cfg.id, num2str(cfg.counter))
	end
end

%% Do the actual work

% Get S2/3/4 epochs, cut data accordingly
trl			= []; % trial = time window of consecutive sleep epochs
insleep		= false;
newtrl		= nan(1,3);
for iEpoch = 1:length(hyp)
	if any(hyp(iEpoch, 1) == [2 3 4]) % if we have sleep
		if ~insleep % if the last epoch was NOT sleep we start a trial
			newtrl(1) = (iEpoch-1)*epoch_length_smpl+1; % first sample of this epoch starts the trial
			insleep = true;
		end
		if iEpoch == length(hyp) % if this is the last epoch the trial ends
			newtrl(2) = iEpoch*epoch_length_smpl;
		end
	else % if we do NOT have sleep
		if insleep % if the last epoch was a sleep epoch
			newtrl(2) = (iEpoch-1)*epoch_length_smpl; % last epoch's last sample ends the trial
			insleep = false;
		end
	end
	
	% If the trial has ended, add to trl structure
	if ~isnan(newtrl(2))
		newtrl(3) = 0;
		trl = [trl; newtrl];
		newtrl = nan(1,3);
	end
end

end