addpath(genpath('C:\Users\asanch24\Documents\Github\rc_preproc'))
%% General comments
% I wrote this code example down there without ever running it; please
% think of it as a broad pointer into the right direction.

%% ------     FIRST-TIME SETUP
% init_rc;
paths                       = [];
paths.root                  = 'D:\Sleep\DataDownload';
paths.data                  = 'D:\Sleep\DataDownload\Recordings';
paths.sl_hypnograms         = 'D:\Sleep\DataDownload\Hypnograms';


%% Get trial description

cfg						= [];
cfg.dataformat          = 'egi_mff_v2'; 
cfg.headerformat        = 'egi_mff_v2';
cfg.dataset             = 'D:\Sleep\DataDownload\Recordings\RC_121_sleep.mff';%Doing now with subject 12, session 1
cfg.trialdef.pre		= -5; % all the .trialdef fields are just forwarded to the cfg.trialfun
cfg.trialdef.post	    = 15;
cfg.epoch_length_sec    = 30;
cfg.hypnogram			= fullfile(paths.sl_hypnograms,'s12_n1.txt');%Doing now with subject 12, session 1
%cfg.trialfun            = 'rc_trialfun_2021'; % does the actual work - DOES NOT ACTUALLY WORK RIGHT NOW, CHECK FUNCTION!
%cfg						= ft_definetrial(cfg);

%% --------------------------------------------------------------
% Trial function inside
%%---------------------------------------------------------------

% Load and check data
if ~exist('hdr')
    hdr         = ft_read_header(cfg.dataset);  end
if ~exist('events')
    events      = ft_read_event(cfg.dataset);   end

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

% Remove fields of the structure that are not relevant
Events = rmfield(Events, ...
    {'value','offset','begintime','classid','code','duration','name','relativebegintime',...
    'sourcedevice','type','tracktype','mffkeys','tracktype'});

% Remove the events that appear to be empty
cidx_all                                = {Events.mffkey_cidx};
Events(cellfun('isempty',cidx_all))     = [];

