%addpath(genpath('/home/andrea/Documents/Github/rc_preproc/'))
addpath(genpath('/research/rgs01/home/clusterHome/asanch24/ReactivatedConnectivity/Github/rc_preproc/')) % for stjude server
% addpath(genpath('Z:\ResearchHome\ClusterHome\asanch24\ReactivatedConnectivity\Github\rc_preproc\')) % for stjude computer


% ft_defaults

% addpath(genpath('C:\Users\lanan\Documents\MATLAB\fieldtrip\'))
% addpath('/home/andrea/Documents/MatlabFunctions/fieldtrip/') % chilean server
addpath('/research/rgs01/home/clusterHome/asanch24/ReactivatedConnectivity/Github/fieldtrip/') % stjude server
% addpath('Z:\ResearchHome\ClusterHome\asanch24\ReactivatedConnectivity\Github\fieldtrip/') % stjude computer


ft_defaults

%% ------     FIRST-TIME SETUP

%server
% paths                       = [];
% paths.root                  = '/mnt/disk1/sleep/German_Study/Data/MFF/Sleep';
% paths.data                  = '/mnt/disk1/sleep/German_Study/Data/MFF/Sleep';
% paths.sl_hypnograms         = '/mnt/disk1/sleep/German_Study/Data/Hypnograms';
% paths.save                  = '/mnt/disk1/sleep/German_Study/Data/FT_Preprocessing_250/';
% 
% for stjude server
% paths                       = [];
% paths.root                  = '/research/rgs01/home/clusterHome/asanch24/ReactivatedConnectivity/SleepData';
% paths.data                  = '/research/rgs01/home/clusterHome/asanch24/ReactivatedConnectivity/SleepData';
% paths.sl_hypnograms         = '/research/rgs01/home/clusterHome/asanch24/ReactivatedConnectivity/Hypnograms';
% paths.save                  = '/research/rgs01/home/clusterHome/asanch24/ReactivatedConnectivity/FT_Preprocessing_250/';

% % for stjude computer
paths                       = [];
paths.root                  = 'Z:\ResearchHome\ClusterHome\asanch24\ReactivatedConnectivity\SleepData';
paths.data                  = 'Z:\ResearchHome\ClusterHome\asanch24\ReactivatedConnectivity\SleepData';
paths.sl_hypnograms         = 'Z:\ResearchHome\ClusterHome\asanch24\ReactivatedConnectivity\Hypnograms';
paths.save                  = 'Z:\ResearchHome\ClusterHome\asanch24\ReactivatedConnectivity\FT_Preprocessing_250/';

files = dir(strcat(paths.data,filesep,'*.mff'));
%%
for file = 1:numel(files)

    data_filename   = files(file).name;
    hyp_filename    = strcat('s',data_filename(4:5),'_n',data_filename(6),'.txt');

    cfg_trial					= [];
    cfg_trial.dataset           = fullfile(paths.data, data_filename);% Doing now with subject 12, session 1
    
    hdr         = ft_read_header(cfg_trial.dataset);
    Events      = ft_read_event(cfg_trial.dataset);
    
    cidx_all                                = {Events.mffkey_cidx};
    Events(cellfun('isempty',cidx_all))     = [];
    
    AllEvents{1,file} = data_filename(1:6);
    AllEvents{2,file} = Events;

end

save('EventsDescription_withTimes.mat','AllEvents')

%% Comparing previous and new Event Description file
Previous_events = load('EventsDescription.mat');
New_Events = load('EventsDescription_withTimes.mat');

for recording = 1:size(Previous_events.AllEvents,2)

    subj_Previous_events = Previous_events.AllEvents{2,recording};
    subj_New_Events = New_Events.AllEvents{2,recording};

    if size(subj_New_Events)~=size(subj_Previous_events)
        disp(files(file).name(1:6))
    end
end

%% assigning the begin time to the event table

Previous_events = load('EventsDescription.mat');
New_Events = load('EventsDescription_withTimes.mat');

for recording = 1:size(Previous_events.AllEvents,2)

    subj_Previous_events = Previous_events.AllEvents{2,recording};
    subj_New_Events = New_Events.AllEvents{2,recording};

    [subj_Previous_events.time] = subj_New_Events.begintime;

    AllEvents_withTime{1,recording} = files(recording).name(1:6);
    AllEvents_withTime{2,recording} = subj_Previous_events;
end

save('EventsDescription_withTimesMerged.mat','AllEvents_withTime')

%% keeping only the important time

for  recording = 1:size(AllEvents_withTime,2)
    
    SubjEvents = AllEvents_withTime{2,recording};
    originalTimes = {SubjEvents.time};

    for event = 1:numel(originalTimes)
        SepT = strsplit(originalTimes{event},'T');
        AfterT = SepT{2};

        Sep_plus = strsplit(AfterT,'+');
        Before_plus = Sep_plus{1};

        Sep_h_m_s = strsplit(Before_plus,':');

        hour(event) = num2cell(str2double(Sep_h_m_s{1}));
        minute(event) = num2cell(str2double(Sep_h_m_s{2}));
        sec(event) = num2cell(str2double(Sep_h_m_s{3})); 
    end
    
    [SubjEvents.hour] = hour{:};
    [SubjEvents.minute] = minute{:};
    [SubjEvents.second] = hour{:};

    AllEvents_with_h_m_s{1,recording}= files(recording).name(1:6);
    AllEvents_with_h_m_s{2,recording} = SubjEvents;

end

save('EventsDescription_withTimes_h_m_s.mat','AllEvents_with_h_m_s')


