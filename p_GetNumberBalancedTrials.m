% Script that checks fow many trials would be removed if we consider only
% trials that are part of a complete stimulation cycle [Odor, Vehicle]

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
%   - TotalTrials   Total number of events per condition
%   - ValidTrials   Number of trials per condition part of a complete cycle
%   - VerbalOutput  Cell:
%                   {Name of dataset, "ValidTrials/TotalTrials", Percentage
%                   of rejected trials}
%
% Parameters
file_AllEvents = 'EventsDescription.mat';


% -------------------------------------------------------------------------

load(file_AllEvents);
                  

TotalTrials     = zeros(size(AllEvents, 2), 1);
RjectTrials     = zeros(size(AllEvents, 2), 1);
VerbalOutput    = cell(size(AllEvents, 2), 4);
VariablesOut    = {'Dataset', 'Total (#)', 'Rejected (%)', 'Rejected (#)', ...
    'Incomplete cycles (#)', 'Complete cycles (#)', ...
    'Rej. bc artifact (Cycles, #)', 'Rej. bc short (Cycles, #)', ...
    'Valid trials (#)'};

for iSubj = 1:size(AllEvents, 2)
    
    SubjectEvents           = AllEvents{2, iSubj};

    Reasons                 = {SubjectEvents.ReasonForRejection};
    Stimulations            = {SubjectEvents.stimulation};

    IdxTrialsOdor           = find(strcmp(Stimulations, 'ODOR'));
    IdxTrialsVehicle        = find(strcmp(Stimulations, 'VEHICLE'));
    IdxTrialsOff            = find(strcmp(Stimulations, 'OFF'));
    
    if IdxTrialsOdor(end) > IdxTrialsVehicle(end)
        IdxTrialsOdor(end) = [];
    end
    
    NumberTrials            = min([numel(IdxTrialsOdor), numel(IdxTrialsVehicle)]);
    
    IdxBadBecauseShort      = find(strcmp(Reasons, 'too short'));
    IdxBadBecauseArtifact   = find(strcmp(Reasons, 'artifact'));
    IdxBadTrial             = sort([IdxBadBecauseShort, IdxBadBecauseArtifact]);
%     IdxBadTrial             = sort([IdxBadBecauseArtifact]);
    
    % Build complete cycles matrix
    CompleteCycles          = [];
    for iOdor = 1:numel(IdxTrialsOdor)
        if iOdor == numel(IdxTrialsOdor)
            CompleteCycles(iOdor, :) = IdxTrialsOdor(iOdor):IdxTrialsOdor(iOdor)+3;
        else
            CompleteCycles(iOdor, :) = IdxTrialsOdor(iOdor):IdxTrialsOdor(iOdor+1)-1;
    
        end
    end
    
    RejectedIncomplete = 0;
    RejectedComplete   = 0;
    RejectedShort      = 0;
    RejectedArtifact   = 0;
    for iCycle = 1:size(CompleteCycles, 1)
        if any(ismember(IdxBadTrial, CompleteCycles(iCycle, :))) % Any
            if sum(ismember(IdxBadTrial, CompleteCycles(iCycle, :))) > 1
                RejectedComplete = RejectedComplete + 1;
            else
                RejectedIncomplete = RejectedIncomplete + 1;
            end
            
            if any(ismember(IdxBadBecauseShort, CompleteCycles(iCycle, :)))
                RejectedShort = RejectedShort + 1;
            end
            if any(ismember(IdxBadBecauseArtifact, CompleteCycles(iCycle, :)))
                RejectedArtifact = RejectedArtifact + 1;
            end
            
        end
    end
    RejectedCycles = RejectedIncomplete + RejectedComplete;
    
    % Subject's information
    TotalTrials(iSubj)      = NumberTrials;
    RjectTrials(iSubj)      = RejectedCycles;
    
    
    VerbalOutput{iSubj, 1}  = AllEvents{1, iSubj};
    VerbalOutput{iSubj, 2}  = NumberTrials;
    VerbalOutput{iSubj, 3}  = ceil(RejectedCycles * 100 / NumberTrials);
    VerbalOutput{iSubj, 4}  = RejectedCycles;
    VerbalOutput{iSubj, 5}  = RejectedIncomplete;
    VerbalOutput{iSubj, 6}  = RejectedComplete;
    VerbalOutput{iSubj, 7}  = RejectedArtifact;
    VerbalOutput{iSubj, 8}  = RejectedShort;
    VerbalOutput{iSubj, 9}  = NumberTrials - RejectedCycles;

end

ToPrint = cell2table(VerbalOutput, 'VariableNames', VariablesOut)
