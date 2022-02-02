% Convert files so that they are readable by event detection code.
% 1.) .mat datasets separately for each subject and condition organized as
%     follows:
%       - "data" matrix [electrodes x datapoints x trials]
%           (single or double numerical)
%       - "hdr" structure with the following fields:
%           - Fs        = sampling rate of recording (scalar)
%           - nChans    = number of electrodes (scalar)
%           - nSamples  = samples per trial (scalar)
%           - nTrials   = number of trials for subject (scalar)
%           - label     = electrode labels [electrodes x 1] which will help
%                         to define "ROIs" variable needed for the code to 
%                         extract electrode datapoints for detection (cell 
%                         array of char)

DataPath = 'D:\germanStudyData\datasetsSETS\AndreaPreprocessing2022\FieldtripOut';

SavePath                    = strcat(cd, filesep, 'PrePro_Andrea');
mkdir(SavePath)

Events                      = load('EventsDescription.mat');

Files                       = dir(DataPath);
Files                       = Files(3:end); % Rejecting OS elements

for iFile = 1:numel(Files)
    
    % File input ----------------------------------------------------------
    File                    = Files(iFile).name;
    
    fprintf(strcat('Processing:', File, '\n'))
    load(strcat(DataPath, filesep, File))
    
    % Extract dataset information for output ------------------------------
    SubjectCode             = cfg_trial.id;
    Times                   = data_downsamp_250.time{1, 1};
    Times                   = Times(Times < 15);
    SamplingRate            = data_downsamp_250.fsample;
    Electrodes              = data_downsamp_250.label;
    
    % Define trials and conditions ----------------------------------------
    IdxSubj                 = strcmp(Events.AllEvents(1, :), SubjectCode);
    SubjectEvents           = Events.AllEvents{2, IdxSubj};

    Reasons                 = {SubjectEvents.ReasonForRejection};
    Stimulations            = {SubjectEvents.stimulation};
    
    % Get rid of Off periods
    IdxTrialsOff            = find(strcmp(Stimulations, 'OFF'));
    Stimulations(IdxTrialsOff) = [];
    Reasons(IdxTrialsOff)      = [];

    IdxTrialsOdor           = find(strcmp(Stimulations, 'ODOR'));
    IdxTrialsVehicle        = find(strcmp(Stimulations, 'VEHICLE'));
    
    
    if IdxTrialsOdor(end) > IdxTrialsVehicle(end)
        IdxTrialsOdor(end)  = [];
    end
        
    IdxBadBecauseShort      = find(strcmp(Reasons, 'too short'));
    IdxBadBecauseArtifact   = find(strcmp(Reasons, 'artifact'));
    IdxBadTrial             = sort([IdxBadBecauseShort, IdxBadBecauseArtifact]);
    
    % Build complete cycles matrix
    CompleteCycles          = [];
    for iOdor = 1:numel(IdxTrialsOdor)
        if iOdor == numel(IdxTrialsOdor)
            CompleteCycles(iOdor, :) = IdxTrialsOdor(iOdor):IdxTrialsOdor(iOdor)+1;
        else
            CompleteCycles(iOdor, :) = IdxTrialsOdor(iOdor):IdxTrialsOdor(iOdor+1)-1;
        end
    end
    
    % Sanity check: Every second element in a cycle is vehicle?
    for iVeh = 1:numel(IdxTrialsVehicle)
        if IdxTrialsVehicle(iVeh) ~= CompleteCycles(iVeh, 2)
            error('Trials are non-alternating')
        end
    end

    % Reject trials respecting complete cycles
    for iCycle = size(CompleteCycles, 1):-1:1
        if any(ismember(IdxBadTrial, CompleteCycles(iCycle, :))) % Any
            CompleteCycles(iCycle, :) = [];
            IdxTrialsOdor(iCycle)     = [];
            IdxTrialsVehicle(iCycle)  = [];
        end
    end
    
    VehicleTrials           = data_downsamp_250.trial(IdxTrialsVehicle);
    OdorTrials              = data_downsamp_250.trial(IdxTrialsOdor);
    
    % Sanity check: Paired trials?
    if numel(OdorTrials) ~= numel(VehicleTrials)
        error('Trials are not paired between conditions')
    end
        
    % Final output preparation --------------------------------------------
    nSamples                = numel(Times);
    nChans                  = numel(Electrodes);
    Fs                      = SamplingRate;
    label                   = Electrodes(:);
    
    % Odor dataset
    Odor.data               = NaN(nChans, nSamples, numel(OdorTrials));
    for iTrial = 1:numel(OdorTrials)
        Trial               = OdorTrials{iTrial};
        Odor.data(:, :, iTrial) = Trial(:, 1:nSamples);
    end
    
    Odor.hdr.nSamples       = nSamples;
    Odor.hdr.nChans         = nChans;
    Odor.hdr.Fs             = Fs;
    Odor.hdr.label          = label;
    Odor.hdr.nTrials        = numel(OdorTrials);
    % Expected field in detection code:
    Odor.hdr.orig.lst_changes = {'Andrea Pre-processing 2022'};
    
    OdorFile                = strrep(File, '.mat', '_TRIALS_OFF_ON_Odor.mat');
    
    
    % Vehicle dataset
    Vehicle.data            = NaN(nChans, nSamples, numel(OdorTrials));
    for iTrial = 1:numel(VehicleTrials)
        Trial               = VehicleTrials{iTrial};
        Vehicle.data(:, :, iTrial) = Trial(:, 1:nSamples);
    end
    
    Vehicle.hdr.nSamples    = nSamples;
    Vehicle.hdr.nChans      = nChans;
    Vehicle.hdr.Fs          = Fs;
    Vehicle.hdr.label       = label;
    Vehicle.hdr.nTrials     = numel(VehicleTrials);
    % Expected field in detection code:
    Vehicle.hdr.orig.lst_changes = {'Andrea Pre-processing 2022'}; 
    
    VehicleFile             = strrep(File, '.mat', '_TRIALS_OFF_ON_Sham.mat');
    
    
    % Save datasets (Version 7 so that files can be handled in GNU Octave)
    data = Odor.data;
    hdr  = Odor.hdr;
    save([SavePath, filesep, OdorFile], 'hdr', 'data', '-nocompression', '-v7');
    
    data = Vehicle.data;
    hdr  = Vehicle.hdr;
    save([SavePath, filesep, VehicleFile], 'hdr', 'data', '-nocompression', '-v7');
    
end

