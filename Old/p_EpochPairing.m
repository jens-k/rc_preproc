path = 'E:\Sleep\OdorD_Night\';

files = dir(strcat(path,'*.set'));

load('C:\Users\asanch24\Documents\Github\EEG_pre_processing\data_specific\GermanData\period_rejection_info.mat');

for file = 1:numel(files)
    
    
    
    addpath(genpath('C:\Users\asanch24\Documents\MATLAB\eeglab2019_1'))
    EEG     = pop_loadset(files(file).name,path);
    %EEG_flt = eeglab2fieldtrip(EEG,'raw');
    rmpath(genpath('C:\Users\asanch24\Documents\MATLAB\eeglab2019_1'))
    
    % Here, we extract the string of the subject number and the recording
    % session
    % |===USER INPUT===|
    str_subj            = extractAfter(files(file).name, 'RC_');
    str_subj            = extractBefore(str_subj, '_');
    
    str_session         = str_subj(3);      % Number of session
    str_subjnum     	= str_subj(1:2);    % Number of subject
    % |=END USER INPUT=|
    
    %% Organize new events structure
    
    % Create new structure as copy of the original events
    Events = EEG.event;
    
    % Remove fields of the structure that are not relevant
    Events = rmfield(Events, ...
        {'begintime','classid','code','duration','relativebegintime',...
        'sourcedevice','type','mffkeys','mffkeysbackup'});
    
    % Remove the events that appear to be empty
    cidx_all                                = {Events.mffkey_cidx};
    Events(cellfun('isempty',cidx_all))     = [];
    
    %% Identify sleep stage and add to table
    
    pathSleepScore      = 'C:\Users\asanch24\Documents\Github\EEG_pre_processing\data_specific\GermanData\Hypnograms\';
    % String of file path to the mother stem folder containing the files of
    % sleep scoring of the subjects. LEAVE EMPTY ("''") IF DOES NOT APPLY
    
    dataTypeScore       = '%f %f';  % Type of data content of file
    column_of_interest  = 1;        % Which column contains the scoring values
    str_delimiter       = ' ';
    % We define structure of sleep scoring file and then import values
    
    chunk_scoring       = 30; % scalar (s)
    % What was the scoring interval (in seconds)
    
    % -------------------------------------------------------------------------
    % This will be used to establish the time points to extract from EEG.data
    pnts_scoring            = chunk_scoring * EEG.srate;
    
    % -------------------------------------------------------------------------
    % Here we set up the list of sleep scoring files that will be processed in
    % the script
    
    ls_score        = dir(pathSleepScore);
    
    % "dir" is also listing the command to browse current folder (".") and step
    % out of folder (".."), so we reject these here
    rej_dot         = find(strcmp({ls_score.name}, '.'));
    rej_doubledot   = find(strcmp({ls_score.name}, '..'));
    rej             = [rej_dot rej_doubledot];
    
    ls_score(rej)   = [];
    
    
    % Avoid potential errors
    if strcmp(pathSleepScore(end), filesep)
        pathSleepScore(end) = [];
    end
    
    
    
    % Here, we look for the sleep scoring file corresponding to the subject and
    % session of recording
    
    % |===USER INPUT===|
    str_subjscore       = strcat('s', str_subjnum);
    str_sessionscore    = strcat('n', str_session);
    % |=END USER INPUT=|
    
    
    % Locate the file of sleep scoring for subject
    idx_subj            = find(contains({ls_score.name}, str_subjscore));
    idx_session         = find(contains({ls_score.name}, str_sessionscore));
    idx_score           = intersect(idx_subj, idx_session);
    
    
    if numel(idx_score) > 1 % Avoid mismatches in file processing
        error('Name of sleep scoring file not sufficiently defined')
    end
    % We need to create a file identifier in order to scan it
    fid_score           = fopen(...
        [pathSleepScore filesep ls_score(idx_score).name]);
    
    [v_sleepStages]     = textscan(fid_score, dataTypeScore, ...
        'Delimiter', str_delimiter, 'CollectOutput', 1, 'Headerlines', 0);
    % Sleep stage values now stored in columns of cell array
    
    
    v_sleepStages       = cell2mat(v_sleepStages);
    v_sleepStages       = v_sleepStages(:,column_of_interest);
    
    
    
    % Get latencies vector in seconds
    latencies_scoring = [Events.latency]/EEG.srate;
    
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
    
    LatencyDiff = [Events(2:end).latency]- [Events(1:end-1).latency];
    LatencyDiff = round([LatencyDiff 0]/EEG.srate);
    LatencyDiff = num2cell(LatencyDiff);
    
    [Events.Distance2NextTrigger] = LatencyDiff{:};
    
    %% Identify if artifacts occur during the stimulation period and add to table
    
    record_idx = find(strcmp(strcat('RC_',str_subjnum,str_session,'_sleep'),period_rejection(:,1)));
    artifacts = period_rejection{record_idx,2};
    
    Event_artifacts = zeros(numel(Events),1);
    
    for artefacto = 1:size(artifacts,1)
        
        Interval_1 = [artifacts(artefacto,1),artifacts(artefacto,2)];
        
        for event = 1:numel(Events)
            
            lat = Events(event).latency/EEG.srate;
            Interval_2 = [lat,lat+15];
            
            Artifact_output = range_intersection(Interval_1,Interval_2);
            
            if ~isempty(Artifact_output)
                Event_artifacts(event) = 1;
            end
            
        end
    end
    
    validStimulations = find(Event_artifacts==0);
    
    Event_artifacts = num2cell(Event_artifacts);
    [Events.Event_artifacts] = Event_artifacts{:};
    
    %% Calculate closer opposite stimulus and add to table
    
    Valid_OdorStimulations_idx = find(strcmp({Events(validStimulations).stimulation},'ODOR'));
    Valid_VehiStimulations_idx = find(strcmp({Events(validStimulations).stimulation},'VEHICLE'));
    
    OdorStimulations_idx = validStimulations(Valid_OdorStimulations_idx);
    VehiStimulations_idx = validStimulations(Valid_VehiStimulations_idx);
    
    
    for stim = 1:numel(OdorStimulations_idx)
        OdorStim = OdorStimulations_idx(stim);
        Diff_Latencies_Vehic = abs(Events(OdorStim).latency-[Events(VehiStimulations_idx).latency]);
        [~,closer_vehic] = min(Diff_Latencies_Vehic);
        
        if abs(Events(OdorStim).latency - Events(VehiStimulations_idx(closer_vehic)).latency) < 32*EEG.srate
            closer_stim(OdorStim) = {Events(VehiStimulations_idx(closer_vehic)).mffkey_gidx};
        else
            closer_stim(OdorStim) = {'none'};
        end
    end
    
    
    for stim = 1:numel(VehiStimulations_idx)
        VehicStim = VehiStimulations_idx(stim);
        Diff_Latencies_Vehic = abs(Events(VehicStim).latency-[Events(OdorStimulations_idx).latency]);
        [~,closer_odor] = min(Diff_Latencies_Vehic);
        
        if abs(Events(VehicStim).latency - Events(OdorStimulations_idx(closer_odor)).latency) < 32*EEG.srate
            closer_stim(VehicStim) = {Events(OdorStimulations_idx(closer_odor)).mffkey_gidx};
        else
            closer_stim(VehicStim) = {'none'};
        end
    end
    
    if strcmp(Events(end).stimulation,'OFF')
        closer_stim(numel(Events)) = {' '};
    end
    
    [Events.CloserStimRef_gidx] = closer_stim{:};
    
    %%
    %--------------------------------------------------------------
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
        elseif event < numel(Events) && (Events(event+1).latency - Events(event).latency ...
                < 15 * EEG.srate)
            will_be_rejected(event) = 1;
            Reason = 'too short';
        end
        
        if Events(event).Event_artifacts == 1
            will_be_rejected(event) = 1;
            Reason = 'artifact';
        end
        
        if strcmp(Events(event).CloserStimRef_gidx,'none')
            will_be_rejected(event) = 1;
            Reason = 'no close stim to compare';
        end
        
        ReasonforRejection{event}=Reason;
        
    end
    will_be_rejected = num2cell(will_be_rejected);
    [Events.Rejected] = will_be_rejected{:};
    
    [Events.ReasonForRejection] = ReasonforRejection{:};
    
    Table = struct2table(Events);
    
    warning('off','MATLAB:xlswrite:AddSheet'); %optional
    writetable(Table,'Events_DNight.xlsx','Sheet',file);
end

%% 


