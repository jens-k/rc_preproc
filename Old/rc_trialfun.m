function trl = rc_trialfun(cfg)
% You need to change this function in a way that it spits out a variable
% 'trl' that contains one row per trial and at least three colums. See more
% info here:
% https://www.fieldtriptoolbox.org/example/making_your_own_trialfun_for_conditional_trial_definition/
%
% You can add further columns to the trl output, these will then later be
% represented in the data as a field .trialinfo
% More info here:
% https://www.fieldtriptoolbox.org/faq/is_it_possible_to_keep_track_of_trial-specific_information_in_my_fieldtrip_analysis_pipeline/

%% MY OLD TRIAL FUNCTION
% Requires these inputs
% cfg.trialdef.post_start       int; how much after the on trigger should we start (in sec)
% cfg.trialdef.pre_end			int; how much before the off trigger should we start (in sec)
% cfg.dataset                   string; path to dataset
% cfg.hypnogram					string; path to hypnogram
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


%% DO THE ACTUAL TRIAL CUTTING HERE

% define the trl variable here (Accoridng to script or links above)


%% ANOTHER EXAMPLE TRIAL FUNCTION
% Here is another example trial function taken from here:
% https://www.fieldtriptoolbox.org/tutorial/preprocessing/#use-your-own-function-for-trial-selection

% this function requires the following fields to be specified
% cfg.dataset
% cfg.trialdef.eventtype
% cfg.trialdef.eventvalue
% cfg.trialdef.prestim
% cfg.trialdef.poststim

hdr   = ft_read_header(cfg.dataset);
event = ft_read_event(cfg.dataset);

trl = [];

for i=1:length(event)
	if strcmp(event(i).type, cfg.trialdef.eventtype)
		% it is a trigger, see whether it has the right value
		if ismember(event(i).value, cfg.trialdef.eventvalue)
			% add this to the trl definition
			begsample     = event(i).sample - cfg.trialdef.prestim*hdr.Fs;
			endsample     = event(i).sample + cfg.trialdef.poststim*hdr.Fs - 1;
			offset        = -cfg.trialdef.prestim*hdr.Fs;
			trigger       = event(i).value; % remember the trigger (=condition) for each trial
			if isempty(trl)
				prevtrigger = nan;
			else
				prevtrigger   = trl(end, 4); % the condition of the previous trial
			end
			trl(end+1, :) = [round([begsample endsample offset])  trigger prevtrigger];
		end
	end
end

samecondition = trl(:,4)==trl(:,5); % find out which trials were preceded by a trial of the same condition
trl(samecondition,:) = []; % delete those trials