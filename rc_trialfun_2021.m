function trl = rc_trialfun_2021(cfg)
%% --------------------------------------------------------------
% Trial function inside
%%---------------------------------------------------------------
if isfile('C:\Users\lanan\Documents\Github\rc_preproc\EventsDescription.mat')
     load('C:\Users\lanan\Documents\Github\rc_preproc\EventsDescription.mat')
end

% Load artifacts
p_ArtifactsDefinition

% Load and check data

hdr         = ft_read_header(cfg.dataset);
events      = ft_read_event(cfg.dataset);

hyp					= load_hypnogram(cfg.hypnogram);
epoch_length_smpl	= cfg.epoch_length_sec * hdr.Fs;

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
	warning('There are more than one EGI recording start triggers in this dataset. You might want to double-check')
end
if numel(trigger_start) ~= 1 || numel(trigger_end) ~= 1
	warning('Unexpected number of lights on / off triggers')
end
if numel(trigger_on) ~=  numel(trigger_off)
	warning('Unequal number of odor on and off triggers (DIN1/2)')
end

% Did we identify all triggers?
if numel(trigger_recstart) + numel(trigger_start) + numel(trigger_end) + numel(trigger_on) + numel(trigger_off) + numel(trigger_tests) + numel(trigger_misc) ~= numel(events)
	warning('Some events could not be identified')
end

%% Specific sanity checks to store in table

% Create new structure as copy of the original events
Events = events;

% Remove fields of the structure that are not relevant.

% Events = rmfield(Events, ...
%     {'value','duration','classid','code','relativebegintime',...
%     'sourcedevice','type','mffkeys'});


% Remove the events that appear to be empty
cidx_all                                = {Events.mffkey_cidx};
Events(cellfun('isempty',cidx_all))     = [];

%% Identify sleep stage and add to table

column_of_interest  = 1;        % Which column contains the scoring values

v_sleepStages       = hyp(:,column_of_interest);

% Get latencies vector in seconds
latencies_scoring = [Events.sample]/hdr.Fs;

% Divide latencies by 30 seconds, to identify in which sleep scoring block
% they are
latencies_scoring = floor(latencies_scoring/30);

sleepStage = num2cell(v_sleepStages(latencies_scoring));

[Events.SleepStage] = sleepStage{:};

%% Assigning the stimulation type (ODOR/VEHICLE/OFF) in the table


StimulationTypes = {Events.label};
cidx_all         = {Events.mffkey_cidx};
cidx_all         = cellfun(@str2double,cidx_all);

StimulationTypes(mod(cidx_all,2)==1) = {'ODOR'};
StimulationTypes(mod(cidx_all,2)==0) = {'VEHICLE'};

StimulationTypes(strcmp({Events.label},'DIN2')) = {'OFF'};

[Events.stimulation] = StimulationTypes{:};

%% Calculate distance to next trigger and add to table

LatencyDiff = [Events(2:end).sample]- [Events(1:end-1).sample];
LatencyDiff = round([LatencyDiff 0]/hdr.Fs);
LatencyDiff = num2cell(LatencyDiff);

[Events.Distance2NextTrigger] = LatencyDiff{:};

%% --------------------------------------------------------------
% Reject for different reasons and add to table
%--------------------------------------------------------------
clear will_be_rejected

for event = 1:numel(Events)
    
    will_be_rejected(event) = 0;
    Reason = '';
    
    % For each event, check whether it occurs exactly twice (start/end)
    if sum(strcmp({Events.mffkey_cidx},Events(event).mffkey_cidx)) ~= 2
        will_be_rejected = 1;
        Reason = 'No start and end';
        
        % ...whether the Stimulation period is about 15 s long
    elseif event < numel(Events) && (Events(event+1).sample - Events(event).sample ...
            < 15 * hdr.Fs)
        will_be_rejected(event) = 1;
        Reason = 'too short';
    end
    
    if strcmp(Events(event).stimulation,'OFF')
        will_be_rejected(event) = 1;
        Reason = 'OFF Period';
    end
    
    ReasonforRejection{event}=Reason;
    
end

will_be_rejected_cell   = num2cell(will_be_rejected);
[Events.Rejected]       = will_be_rejected_cell{:};

[Events.ReasonForRejection] = ReasonforRejection{:};


%%
% Taking all the events that are not rejected until now (that were later
% visually inspected, we need to reject the ones that were noisy by visual
% inspection)

NonRejectedEvents = find([Events.Rejected]==0);

%------------------------------------------------
% see artifacts from the artifact definition. 
%------------------------------------------------

%make sure we are taking the same dataset
dataset = find(strcmp(artifacts.dataset,[cfg.id,'_sleep']));

badtrials = artifacts.badtrials(dataset);

if ~isempty(badtrials)
    badtrials = cell2mat(badtrials{:});
    original_badtrials = NonRejectedEvents(badtrials);
    
    for badtrial = original_badtrials
        Events(badtrial).Rejected = 1;
        Events(badtrial).ReasonForRejection = 'artifact';
    end
end

AllEvents{1,cfg.counter} = cfg.id;
AllEvents{2,cfg.counter} = Events;


save('EventsDescription.mat','AllEvents')

% Table = struct2table(Events);
% 
% warning('off','MATLAB:xlswrite:AddSheet'); %optional
% writetable(Table,'Events_RC.xlsx','Sheet',cfg.counter);

%% Trials that are selected 

% It is important to 

%trial description looks like this:
% 1000 2000 500 2 11
% 3500 4500 500 2 12
% 1000 2000 500 2 21
% ...
% 
% This would be a trl structure for 3 trials, each 1000 samples long, with
% the 0 point right in the middle. I added another column for the sleep
% stage at the beginning of the trial and the condition (one could use a
% code like: vehicle off period 11, vehicle on period 12, odor off period 21, odor on period 22)
% odor 2, just as an example).

% Is is important to have this trial definition as numerical values,
% otherwise the ft_artifact_zvalue function will give problems

final_trials = Events(~will_be_rejected);

trl_startTime   = round([final_trials.sample]')-cfg.trialdef.pre*hdr.Fs;
trl_EndTime     = round([final_trials.sample]')+cfg.trialdef.post*hdr.Fs;
trl_ZeroPoint   = [final_trials.offset]'-cfg.trialdef.pre*hdr.Fs;

trl_condition(strcmp({final_trials.stimulation},'ODOR'))  = 1;
trl_condition(strcmp({final_trials.stimulation},'VEHICLE'))  = 0;

%add 4th column called trial ID, or something saying either this is Odor or
%vehicle. later this is going to be saved in the 'trialinfo' parameter 
% (this needs to be given in numbers, I can use 1 for Odor, 0 for vehicle

trl = [trl_startTime,trl_EndTime,trl_ZeroPoint,trl_condition'];