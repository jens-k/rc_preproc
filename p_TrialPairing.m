% Script that pairs odor and vehicle trials

% Input
%   - AllEvents (as put out by Andrea) structure with fields
%       [ Field name ]           [ Used ]
%       - sample
%       - offset
%       - description
%       - label
%       - mffkey_cidx
%       - mffkey_gidx
%       - SleepStage
%       - stimulation               Yes
%       - Distance2NextTrigger
%       - Rejected
%       - ReasonForRejection        Yes
%
% Output
%   - TrialPairing      cell
%                       - {dataset name}
%                       - {Pairing array}:
%                               [odor trials, vehicle trials]
%
% Parameters
file_AllEvents = 'EventsDescription.mat';


% -------------------------------------------------------------------------

load(file_AllEvents);
originalSrate = 1000;

AllKeptEvents = AllEvents;

for recording = 1:size(AllEvents, 2)
    
    %get the events for this specific recording
    RecordEvents            = AllEvents{2, recording};

    %create a new table/structure with the events that were kept (and the
    %events that are part of the final preprocessed recording)
    
    KeptEvent_idx          = find([RecordEvents.Rejected] == 0);
    KeptEvents              = RecordEvents(KeptEvent_idx);
    
    %Give the kept events a new ID in order to be able to identify the
    %proper pairing with the events that are part of the final preprocessed
    %recording
  
    New_Events_ID           = num2cell(1:numel(KeptEvents));
    [KeptEvents.NewID]      = New_Events_ID{:};
    
    
    % Find the Odor and vehicle stimulations Indexes in order to start
    % checking the pairing between them
    Stimulations            = {KeptEvents.stimulation};
    OdorStim_Idx            = find(strcmp(Stimulations, 'ODOR'));
    VehicleStim_Idx         = find(strcmp(Stimulations, 'VEHICLE'));

    pairing = zeros(numel(OdorStim_Idx),2);
    
    pairing(:,1) = [KeptEvents(OdorStim_Idx).NewID];
    
    odorcount = 1;
    for odorstim = OdorStim_Idx
        
        % find next available vehicle
        Next_vehicles       = find(VehicleStim_Idx > odorstim);
        
        if ~isempty(Next_vehicles)
            NextVehicle_Idx     = VehicleStim_Idx(Next_vehicles(1));
            
            %stimulations distance
            idx_Diff = NextVehicle_Idx - odorstim;
            
            % is it a subsequent stimulation?
            if idx_Diff == 1
                
                %time distance
                time_Diff  = (KeptEvents(NextVehicle_Idx).sample-...
                    KeptEvents(odorstim).sample)/originalSrate;
                
                % are they relatively close in time?
                if time_Diff < 35
                    pairing(odorcount,2) = KeptEvents(NextVehicle_Idx).NewID;
                end
                
            end
        end
        
        odorcount = odorcount+1;
    end
    
    %keep only the events that have pairing (for the output array)
    pairing_idx = find(pairing(:,2)~=0);
    
    PairingAll{recording,1} = AllEvents{1,recording};
    PairingAll{recording,2} = pairing(pairing_idx,:);
    
    AllKeptEvents{2,recording} = KeptEvents;
end

% clearvars -except PairingAll
%% ------------------------------------------------------------------------
% Later for checking when doing the pairing
% -------------------------------------------------------------------------
% path = '/mnt/disk1/sleep/German_Study/Data/FT_Preprocessing_250/';

% files = dir(strcat(path,'*.mat'));

% for file = 1:numel(files)
    
%     load(strcat(path,files(file).name))
    
%     recording = find(strcmp(PairingAll(:,1), files(file).name(1:6)));
    
%     %check that stims correspond to 1 and 0 in the trialinfo
%     pairs = PairingAll{recording,2};
%     idxOdors        = pairs(:,1);
%     idxVehicles     = pairs(:,2);
    
%     if data_downsamp_250.trialinfo(idxOdors)~= 1
%         error('indexes are wrong')
%         disp(files(file).name(1:6))
%     end
    
%     if data_downsamp_250.trialinfo(idxVehicles)~= 0
%         error('indexes are wrong')
%         disp(files(file).name(1:6))
%     end
    
% end

% disp('done')
