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

% Parameters --------------------------------------------------------------
DataPath = 'D:\germanStudyData\datasetsANDREA\WholeDatasets';
SavePath                    = strcat(cd, filesep, 'PrePro_Andrea');

Epoching                    = 0;    % [0, 1] for No or Yes. "0" will 
                                    % produce whole datasets (non-epoched)
Pairing                     = 0;    % [0, 1] for Off or On, respectively. 
                                    % Rejecting all trials can do not fit 
                                    % into a complete stimulation cycle.


% Prepare userland --------------------------------------------------------
Events                      = load('EventsDescription.mat');

Files                       = dir(DataPath);
Files                       = Files(3:end); % Rejecting OS elements
if isfolder(SavePath) == 0
    mkdir(SavePath)
end

for iFile = 1:numel(Files)
    
    % File input ----------------------------------------------------------
    File                    = Files(iFile).name;
    
    fprintf(strcat('Processing:', File, '\n'))
    load(strcat(DataPath, filesep, File))
    
    % Extract dataset information for output ------------------------------
    SubjectCode             = cfg_trial.id;
    Times                   = data_downsamp_250.time{1, 1};
    if Epoching ==1
        Times               = Times(Times < 15);
    end
    SamplingRate            = data_downsamp_250.fsample;
    Electrodes              = data_downsamp_250.label;
    
    % Define trials and conditions ----------------------------------------
    if Epoching == 1
        IdxSubj                 = strcmp(Events.AllEvents(1, :), SubjectCode);
        SubjectEvents           = Events.AllEvents{2, IdxSubj};
        
        ValidTrials             = ([SubjectEvents.Rejected] == 0);
        ValidTrials             = SubjectEvents(ValidTrials);
        
        IdxOdorTrials           = find(strcmp({ValidTrials.stimulation}, 'ODOR'));
        IdxVehicleTrials        = find(strcmp({ValidTrials.stimulation}, 'VEHICLE'));
        
        if Pairing == 1
            
            TheoreticalVehicle  = IdxOdorTrials + 1;
            TheoreticalOdor     = IdxVehicleTrials - 1;
            
            IdxOdorTrials       = IdxOdorTrials(ismember(IdxOdorTrials, ...
                TheoreticalOdor));
            IdxVehicleTrials    = IdxVehicleTrials(ismember(IdxVehicleTrials, ...
                TheoreticalVehicle));
            
            if numel(IdxOdorTrials) ~= numel(IdxVehicleTrials)
                % Sanity check: Paired trials?
                error('Trials are not paired between conditions')
            end
        else
            fprintf('No pairing of trials...\n')
        end
        
        VehicleTrials       = data_downsamp_250.trial(IdxVehicleTrials);
        OdorTrials          = data_downsamp_250.trial(IdxOdorTrials);
        
    else
        
        UniqueTrial         = data_downsamp_250.trial(1);
        
    end
    
        
    % Final output preparation --------------------------------------------
    nSamples                = numel(Times);
    nChans                  = numel(Electrodes);
    Fs                      = SamplingRate;
    label                   = Electrodes(:);
    
    if Epoching == 1
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
        Vehicle.data            = NaN(nChans, nSamples, numel(VehicleTrials));
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
    
    else
        
        Whole.hdr.nSamples       = nSamples;
        Whole.hdr.nChans         = nChans;
        Whole.hdr.Fs             = Fs;
        Whole.hdr.label          = label;
        Whole.hdr.nTrials        = numel(UniqueTrial);
        % Expected field in detection code:
        Whole.hdr.orig.lst_changes = {'Andrea Pre-processing 2022'};
        
        WholeFile                = strrep(File, '.mat', '_WHOLE.mat');
        
        data = UniqueTrial{:, 1:nSamples};
        hdr  = Whole.hdr;
        save([SavePath, filesep, WholeFile], 'hdr', 'data', '-nocompression', '-v7');
        
    end
end

