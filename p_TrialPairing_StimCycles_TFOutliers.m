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


load('/research/rgs01/home/clusterHome/asanch24/ReactivatedConnectivity/Github/TimeFrequency_ReactivatedMemoryProject/NewPreprocessingAnalysis/keeptrialsAll.mat');
load('/research/rgs01/home/clusterHome/asanch24/ReactivatedConnectivity/Github/TimeFrequency_ReactivatedMemoryProject/NewPreprocessingAnalysis/PairingTrials_NoOutliers.mat')
% -------------------------------------------------------------------------

load(file_AllEvents);
originalSrate = 1000;

AllKeptEvents = AllEvents;

for recording = 1:size(AllEvents, 2)
    pairing = [];
    %get the events for this specific recording
    RecordEvents            = AllEvents{2, recording};

    %create a new table/structure with the events that were kept (and the
    %events that are part of the final preprocessed recording)
    
    KeptEvent_idx           = find([RecordEvents.Rejected] == 0);
    KeptEvents              = RecordEvents(KeptEvent_idx);
    
    %Give the kept events a new ID in order to be able to identify the
    %proper pairing with the events that are part of the final preprocessed
    %recording
  
    New_Events_ID           = num2cell(1:numel(KeptEvents));
    [KeptEvents.NewID]      = New_Events_ID{:};
    
    
    % Find the Odor and vehicle stimulations Indexes in order to start
    % checking the pairing between them
    pairs_idx = strcmp(PairingAll(:,1), AllEvents{1, recording});
    pairs = PairingAll{pairs_idx,2};
    
    OdorStim_Idx = pairs(:,1);
    VehicleStim_Idx = pairs(:,2);
    
    pairing(:,1) = [KeptEvents(OdorStim_Idx).NewID];
    
    odorcount = 1;
    
    v_cycles = zeros(1,size(KeptEvents,2));
    v_cycleStim = zeros(1,size(KeptEvents,2));
    
    cycle = 0;
    for  stim = 1:length(OdorStim_Idx)
        
        odorstim = OdorStim_Idx(stim);
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
                    cycle = cycle+1;
                    % assign to each event the number of the complete stimulation cycle 
                    % that it belongs to: assigned in thw column cycleStim
                    v_cycles(KeptEvents(odorstim).NewID) = cycle;
                    v_cycles(KeptEvents(NextVehicle_Idx).NewID) = cycle;
                end
                
            end
        end
        
        odorcount = odorcount+1;
    end
    
    %keep only the events that have pairing (for the output array)
    pairing_idx = find(pairing(:,2)~=0);
    
    PairingAll{recording,1} = AllEvents{1,recording};
    PairingAll{recording,2} = pairing(pairing_idx,:);
    
    v_cycles = num2cell(v_cycles);
    
    [KeptEvents.cycle] = v_cycles{:};
    
    i = 1;
    stimIdx = find([KeptEvents.cycle]==i,1,'first');
    LatencyLast = KeptEvents(stimIdx).sample;
    cyclecount = 1;
    
    % Here we identify if cycles are too far away to restar the count of
    % consecutive stimulation cycles
    
    v_cycleStim(stimIdx) = cyclecount;
    v_cycleStim(stimIdx+1) = cyclecount;
    
    for i = 2:max([KeptEvents.cycle])
        
        stimIdx = find([KeptEvents.cycle]==i,1,'first');
        LatencyNew = KeptEvents(stimIdx).sample;
        
        Distance = (LatencyNew-LatencyLast)/originalSrate;
        
        if Distance < 65
            cyclecount = cyclecount +1;
        else
            %restart counting because events are too far away
            cyclecount = 1;
        end
        
        v_cycleStim(stimIdx) = cyclecount;
        v_cycleStim(stimIdx+1) = cyclecount;
        
        LatencyLast = LatencyNew;
        
    end
    
    v_cycleStim = num2cell(v_cycleStim);
    [KeptEvents.cycleStim] = v_cycleStim{:};
    
    AllKeptEvents{2,recording} = KeptEvents;

end

%% calculating how many cycles we can use to evaluate

for recording = 1:size(AllKeptEvents, 2)
    
    Rec_EventCycles = [AllKeptEvents{2,recording}.cycleStim];
    
    % obtain the longest stimulation cycle by maximum number of
    % stimulations
    MaxEvents(recording) = max(Rec_EventCycles);
end

shorterCycleStims = min(MaxEvents);

%% Define which cycle to use per subject for evolution over trials

% MaxCycle = shorterCycleStims;

for recording = 1:size(AllKeptEvents, 2)
    KeptEvents = AllKeptEvents{2,recording};
    
    Rec_EventCycles = [KeptEvents.cycleStim];
    
    % number of stimulations for the longest stimulation cycle
    MaxCycle =  shorterCycleStims;%max(Rec_EventCycles); %
    
    %get the index in which the last stimulation of the longest cycle is
    %located
    MaxEvents_idx = find(Rec_EventCycles == MaxCycle ,1,'first');
    
    %get the index in which the first stimulation of the longest cycle is
    %located
    FirstEvent_idx = MaxEvents_idx - ((MaxCycle-1)*2);
    
    NewRec_EventCycles = Rec_EventCycles;
    
    
    % assign zero, to those stimulations before the longest stimulation
    % cycle
    if FirstEvent_idx >1
        NewRec_EventCycles(1:FirstEvent_idx-1) = 0;
    end
    
    % assign zero, to those stimulations after the longest stimulation
    % cycle
    NewRec_EventCycles(FirstEvent_idx+MaxCycle*2:end) = 0;
    NewRec_EventCycles = num2cell(NewRec_EventCycles);
    
    [KeptEvents.CutCycleStim] = NewRec_EventCycles{:};
    
    AllKeptEvents{2,recording} = KeptEvents;
    
end


clearvars -except AllKeptEvents PairingAll