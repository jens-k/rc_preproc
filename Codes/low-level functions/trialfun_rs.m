function [trl, events] = trialfun_rs(cfg)
% cfg.trialdef.explength        int; expected length of recording in sec (optional)
% cfg.trialdef.post_start       int; how much after the on trigger should we start (in sec)
% cfg.trialdef.pre_end			int; how much before the off trigger should we start (in sec)
% cfg.trialdef.pre_break/post_break int; how long before/after break trigger should we stop/start again (in sec)
% cfg.trialdef.cut_breaks		int; should we cut out breaks at all? (logical)
% cfg.trialdef.segment_length   int; length of time window to cut data to (in sec)
%                               returns one continuous trial if set to 0
% cfg.dataset                   string; path to dataset

% Comments on particlar datasets:
% s30_n2_rs1	two recording start triggers because user triggers didnt
%				work right away (see lab book) - no manual action required
% s41_n1_rs3	lacks begin and end trigger - special handling below

%% Setup
% Check for required fields in the configuration data
requiredFields = {'trialdef', 'dataset'};
for i = requiredFields
	if ~isfield(cfg,i)
		error(['Required field missing in cfg: ' i{1} ' (%s).'], cfg.id);
	end
end
if ~isfield(cfg.trialdef, 'explength') || isempty(cfg.trialdef.explength)
	cfg.trialdef.explength     = 0;
	fprintf('No expected length specified (%s, counter %s).\n', cfg.id, num2str(cfg.counter))
end
if ~isfield(cfg.trialdef, 'segment_length') || isempty(cfg.trialdef.segment_length)
	cfg.trialdef.segment_length = 0;
	fprintf('No segment length specified. Will return one continuous trial (%s, counter %s).\n', cfg.id, num2str(cfg.counter))
end
if ~isfield(cfg.trialdef, 'post_start')
	cfg.trialdef.post_start = 0;
	fprintf('No trialdef.post_start specified. Starting right at the start trigger (%s, counter %s).\n', cfg.id, num2str(cfg.counter))
end
if ~isfield(cfg.trialdef, 'pre_end')
	cfg.trialdef.pre_end = 0;
	fprintf('No trialdef.pre_end specified. Ending right at the end trigger (%s, counter %s).\n', cfg.id, num2str(cfg.counter))
end
if ~isfield(cfg.trialdef, 'cut_breaks')
	cfg.trialdef.cut_breaks = false;
	fprintf('No trialdef.cut_breaks specified. Will ignore breaks (%s, counter %s).\n', cfg.id, num2str(cfg.counter))
end
if ~isfield(cfg.trialdef, 'pre_break')
	cfg.trialdef.pre_break = 10;
	fprintf('No trialdef.pre_break specified. Discarding %s s before potential break triggers (%s, counter %s).\n', num2str(cfg.trialdef.pre_break), cfg.id, num2str(cfg.counter))
end
if ~isfield(cfg.trialdef, 'post_break')
	cfg.trialdef.post_break = 10;
	fprintf('No trialdef.post_break specified. Discarding %s s after potential break triggers (%s, counter %s).\n', num2str(cfg.trialdef.post_break), cfg.id, num2str(cfg.counter))
end

%% Load and check data
hdr                 = ft_read_header(cfg.dataset);
events              = ft_read_event(cfg.dataset);

% Special handling of particular datasets
if strcmp(cfg.id, 's41_n1_rs3')	% add missing triggers (see above), decided based on recording length and experimenter's notes
	tempevent.type		= 'Posthoc_Start'; 
	tempevent.sample	= 5.8 * hdr.Fs;  % seconds to begin after recording start
	tempevent.offset	= 0; 
	tempevent.duration	= 1e-3; 
	tempevent.value		= 'DIN1'; 
	tempevent.orig		= [];
	events = [events tempevent];
	
	tempevent.type		= 'Posthoc_End'; 
	tempevent.sample	= hdr.nSamples - 4 * hdr.Fs; % seconds to stop before recording end
	tempevent.value		= 'DIN2'; 
	events = [events tempevent];
end

trigger_recstart    = events(strcmp('epoch', {events.type}));
trigger_start       = events(strcmp('DIN1', {events.value}));
trigger_end         = events(strcmp('DIN2', {events.value}));
trigger_break		= events(strcmp('6___', {events.value}));

% Some sanity checks on the found triggers
if numel(trigger_recstart) ~= 1
	warning('There are more than one EGI recording start triggers in this dataset. You might want to double-check (%s, counter %s).\n', cfg.id, num2str(cfg.counter))
end
if numel(trigger_start) ~= 1 || numel(trigger_end) ~= 1
	error('Unexpected number of DIN1 or DIN2 triggers. (%s, counter %s).\n', cfg.id, num2str(cfg.counter))
end
if numel(trigger_break) ~= 0 % TODO: That should be done without a loop
	for i = 1:numel(trigger_break)
		if ~strcmp(trigger_break(i).orig.label, 'RS Interruption')
			error('Some identified break triggers weren''t actually ones. Please check! (%s, counter %s).\n', cfg.id, num2str(cfg.counter))
		end
	end
	temp_list = ['(min:'];
	for i = 1:numel(trigger_break)
		temp_list = [temp_list ' ' num2str(trigger_break(i).sample / (hdr.Fs * 60))];
	end
	temp_list = [temp_list ')'];
	warning('There were break triggers in the recording %s. You might wanna check if we cut the recording properly (%s, counter %s).\n', temp_list, cfg.id, num2str(cfg.counter))
end

% Did we identify all triggers?
if numel(trigger_recstart) + numel(trigger_start) + numel(trigger_end) + numel(trigger_break) ~= numel(events)
	error('Some events could not be identified (%s, counter %s).\n', cfg.id, num2str(cfg.counter))
end

% Check if the recording length is in the expected range
if (cfg.trialdef.explength ~= 0) && ...
		((trigger_end.sample - trigger_start.sample) / hdr.Fs > cfg.trialdef.explength + 0.1 || ...
		(trigger_end.sample - trigger_start.sample) / hdr.Fs < cfg.trialdef.explength - 0.1)
	error('Recording is of unexpected length (substantially different from %d s).\n', cfg.trialdef.explength)
end

%% Do the actual work
% Make one long trial OR cut that long trial intro segments of desired
% length. We will fill the time from the back to the front, so that
% discarded time will be taken from the beginning of the recording (we
% assume the beginning to be more non-stationary)

if cfg.trialdef.segment_length == 0
	
	begin	= trigger_start.sample+cfg.trialdef.post_start*hdr.Fs;	% start
	finish	= trigger_end.sample-cfg.trialdef.pre_end*hdr.Fs;		% end
	
	if numel(trigger_break) == 0 || ~cfg.trialdef.cut_breaks	% it's easy without breaks
		trl = [begin, finish, 0];
	else							% ...and more complicated with breaks
		breaks		= [trigger_break.sample];
		before		= cfg.trialdef.pre_break*hdr.Fs; % samples before each break
		after		= cfg.trialdef.post_break*hdr.Fs; % samples after each break
		trl			= zeros(numel(breaks)+1, 3);
		
		trl(1,1)	= begin;
		for iBreak = 1:numel(breaks)
			
			trl(iBreak,2)		= breaks(iBreak) - before;	% col 2 of current line
			trl(iBreak+1,1)		= breaks(iBreak) + after;	% col 1 of next line
			
			if iBreak == numel(breaks) % if this is the last break, enter last sample in second column
				trl(iBreak+1,2)	= finish;
			end
		end
		
		% Sanity checks
		del = [];
		for iTrial = 1:size(trl, 1)
			if trl(iTrial, 1) < begin
				trl(iTrial, 1) = begin;
			end
			if trl(iTrial, 2) > finish
				trl(iTrial, 2) = finish;
			end
			if trl(iTrial, 1) > trl(iTrial, 2)	% if two breaks are too close to each other they may lead to trials of negative length
				del = [del iTrial]; % mark for deletion
			end
		end
		trl(del,:)=[]; % delete marked trials
	end
else
	length_smpl         = cfg.trialdef.segment_length*hdr.Fs;
	temp_end            = trigger_end.sample - cfg.trialdef.pre_end*hdr.Fs;
	temp_start          = temp_end - length_smpl+1;
	trl                 = [];
	newtrl              = [];
	endreached          = false;
	inbreak             = false;
	disc_pre_smpl       = discard_pre * hdr.Fs; % samples discarded before a break trigger
	disc_post_smpl      = discard_post * hdr.Fs; % samples discarded after a break trigger
	while ~endreached
		for iBreak = 1:numel(trigger_break)
			% If the current segment overlaps with a break, it is shifted
			% to the break's end
			if (temp_start > (trigger_break(iBreak) - disc_pre_smpl) && temp_start < (trigger_break(iBreak) + disc_post_smpl)) || ...
					(temp_end > (trigger_break(iBreak) - disc_pre_smpl) && (temp_end < trigger_break(iBreak) + disc_post_smpl))
				temp_end      = trigger_break(iBreak)- disc_pre_smpl;
				temp_start    = temp_end - length_smpl + 1;
				inbreak       = true;
			end
		end
		
		if inbreak
			inbreak = false;
			continue
		end
		newtrl          = [temp_start temp_end 0];
		trl             = [newtrl; trl];    % this order makes it ascendend in the end
		
		% Prepare for next iteration
		temp_end        = temp_end - length_smpl;
		temp_start      = temp_start - length_smpl;
		if temp_start < trigger_start.sample + cfg.trialdef.post_start*hdr.Fs
			endreached  = true;
		end
	end
end





