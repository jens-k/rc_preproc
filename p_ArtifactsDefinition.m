cnt = 0;


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_051_sleep';
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};

cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_052_sleep';
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};



cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_091_sleep';
artifacts.artifacts{cnt}  = {{30,{'E118'}},{31,{'E118'}},{32,{'E118'}},...
    {38,{'E2', 'E9', 'E10', 'E15', 'E56', 'E108', 'E122', 'E123','E124'}},...%removed from the list E3, is is not son bad and is affecting the repairing of channel E2
    {40,{'E2', 'E9', 'E10', 'E15', 'E56', 'E108', 'E122', 'E123','E124'}},...%removed E3, is is not son bad and is affecting the repairing of channel E2
    {41,{'E2', 'E9', 'E10', 'E15', 'E56', 'E108', 'E122', 'E123','E124'}},...%removed E3, is is not son bad and is affecting the repairing of channel E2
    {42,{'E2', 'E9', 'E10', 'E15', 'E56', 'E108', 'E122', 'E123','E124'}},...%removed E3, is is not son bad and is affecting the repairing of channel E2
    {43,{'E2', 'E9', 'E10', 'E15', 'E56', 'E108', 'E122', 'E123','E124'}},...%removed E3, is is not son bad and is affecting the repairing of channel E2
    {44,{'E2', 'E9', 'E10', 'E15', 'E56', 'E108', 'E122', 'E123','E124'}},...%removed E3, is is not son bad and is affecting the repairing of channel E2
    {45,{'E2', 'E9', 'E10', 'E15', 'E56', 'E108', 'E122', 'E123','E124'}},...%removed E3, is is not son bad and is affecting the repairing of channel E2
    {46,{'E2', 'E9', 'E10', 'E15', 'E56', 'E108', 'E122', 'E123','E124'}},...%removed E3, is is not son bad and is affecting the repairing of channel E2
    };
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};



cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_092_sleep';
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {'E33', 'E38', 'E57',... %Mastoid %removed E56, is is not son bad and it doesnt have good neighbors
    'E63', 'E99', 'E107','E122'};
artifacts.reref{cnt}      = {'E50', 'E100'}; %chose E50, since E56 is still a bit noisy




cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_121_sleep';
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {24};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_122_sleep';
artifacts.artifacts{cnt}  = {{19,{'E39', 'E122'}}};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};



cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_131_sleep';
% artifacts.artifacts{cnt}  = {{27,{'E1','E8'}},{34,{'E8','E21','E25'}},...
%     {37,{'E8','E21','E25'}},{39,'E8'}};
% E1,E8,E21,E25 are face channels, so we don't care about them since they are
% going to be removed
artifacts.artifacts{cnt}  = {{27,{'E22'}},{34,{'E22'}},{36,{'E22'}},{37,{'E22'}},{38,{'E22'}}}; 
artifacts.badtrials{cnt}  = {42};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_132_sleep';
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {44};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};



cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_141_sleep';
% artifacts.artifacts{cnt}  = {{20,'E1'}};
% E1 is face channel, so we don't care about it since it is
% going to be removed
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {33,39};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_142_sleep';
% artifacts.artifacts{cnt}  = {{13,'E1'}};
% E1 is face channel, so we don't care about it since it is
% going to be removed
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {34};
artifacts.badchans{cnt}   = {'E45', 'E56', 'E63', 'E90', 'E99', 'E100',... %Mastoid
    'E101', 'E108'};
artifacts.reref{cnt}      = {'E57', 'E100'};




cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_161_sleep';
artifacts.artifacts{cnt}  = {{14,{'E114','E116','E121','E122','E124'}},...
    {15,{'E56'}},{20,{'E56'}},{34,{'E56'}},{43, {'E114', 'E115', 'E117',...
    'E123', 'E124'}},{47,{'E9','E39','E107'}}};
artifacts.badtrials{cnt}  = {19,29};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_162_sleep';
artifacts.artifacts{cnt}  = {{40,{'E87','E108'}},{49,{'E59'}}};
artifacts.badtrials{cnt}  = {55};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};



cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_171_sleep';
artifacts.artifacts{cnt}  = {{18,{'E114'}}};
artifacts.badtrials{cnt}  = {48};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_172_sleep';
artifacts.artifacts{cnt}  = {{59, {'E63', 'E68'}}};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {'E15', 'E22', 'E26', 'E27', 'E39', 'E56'};
artifacts.reref{cnt}      = {'E57', 'E100'};



cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_201_sleep';
% artifacts.artifacts{cnt}  = {{43,{'E9','E14','E21','E22'}}};
% E21 and E14 is face channel, so we don't care about it since it is
% going to be removed
artifacts.artifacts{cnt}  = {{43,{'E9','E22'}}};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_202_sleep';
artifacts.artifacts{cnt}  = {{27,{'E16'}}};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};



cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_241_sleep';
artifacts.artifacts{cnt}  = {{35,{'E123'}},{46,{'E123'}},{51,{'E34'}}};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_242_sleep';
artifacts.artifacts{cnt}  = {{27,{'E5'}},{28,{'E27'}},{29,{'E5'}},...
    {33,{'E116'}}};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};




cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_251_sleep';
% artifacts.artifacts{cnt}  = {{17,{'E1','E32'}},{30,'E2'}};
% E1,E32 are face channels, so we don't care about them since they are
% going to be removed
artifacts.artifacts{cnt}  = {{30,{'E2'}}};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {'E99', 'E100'}; %Mastoid %removed E107
artifacts.reref{cnt}      = {'E57', 'E101'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_252_sleep';
artifacts.artifacts{cnt}  = {{13,{'E99'}}};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};




cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_261_sleep';
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {35};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_262_sleep';
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};




cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_281_sleep';
artifacts.artifacts{cnt}  = {{39,{'E33','E108'}},{40,{'E77'}}};
artifacts.badtrials{cnt}  = {38};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_282_sleep';
% artifacts.artifacts{cnt}  = {{12,{'E8','E21','E25'}},{20,'E8'},...
%     {54,{'E8','E21','E25'}},{79,{'E1','E8'}}};
% E8,E21,E25 are face channels, so we don't care about them since they are
% going to be removed
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {79};
artifacts.badchans{cnt}   = {'E39', 'E45','E57','E108'}; %Mastoid
artifacts.reref{cnt}      = {'E56', 'E100'};




cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_291_sleep';
artifacts.artifacts{cnt}  = {{30,{'E107'}}};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_292_sleep';
% artifacts.artifacts{cnt}  = {{9,{'E8','E14'}}};
% E8,E14 are face channels, so we don't care about them since they are
% going to be removed
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {6,59};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};




cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_301_sleep';
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {'E100','E108'}; %Mastoid
artifacts.reref{cnt}      = {'E57', 'E107'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_302_sleep';
% artifacts.artifacts{cnt}  = {{1,{'E4','E6','E8','E9','E17','E21','E22','E32',...
%     'E49','E107','E110'}}};
artifacts.artifacts{cnt}  = {{1,{'E4', 'E6', 'E9', 'E22',...
    'E103', 'E104', 'E110', 'E111', 'E116'}},...
    {27,{'E105'}},{52,{'E2','E26','E121','E122'}},{53,{'E45'}},{54,{'E45'}}};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {'E2', 'E9', 'E56', 'E57', 'E100', 'E107', 'E124'}; %Mastoids
artifacts.reref{cnt}      = {'E50', 'E100'};




cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_391_sleep';
artifacts.artifacts{cnt}  = {...
    {31,{'E9', 'E63','E94', 'E99'}},...
    {32,{'E9', 'E63','E94', 'E99'}},...
    {33,{'E9', 'E63','E94', 'E99'}},...
    {34,{'E9', 'E63','E94', 'E99'}},...
    {35,{'E9', 'E63','E94', 'E99'}},...
    {36,{'E9', 'E63','E94', 'E99'}},...
    {37,{'E9', 'E63','E94', 'E99'}},...
    {38,{'E9', 'E63','E94', 'E99'}},...
    {39,{'E9', 'E63','E94', 'E99'}},...
    {40,{'E9', 'E63','E94', 'E99'}},...
    {41,{'E9', 'E63','E94', 'E99'}},...
    {42,{'E2', 'E3', 'E9', 'E63','E94', 'E99'}},...
    {43,{'E2', 'E3', 'E9', 'E63','E94', 'E99'}},...
    {44,{'E2', 'E3', 'E9', 'E63','E94', 'E99'}},...
    {45,{'E2', 'E3', 'E9', 'E63','E94', 'E99'}},...
    {46,{'E2', 'E3', 'E9', 'E63','E94', 'E99'}},...
    {47,{'E2', 'E3', 'E9', 'E63','E94', 'E99'}},...
    {48,{'E2', 'E3', 'E9', 'E63','E94', 'E99'}},...
    {49,{'E2', 'E3', 'E9', 'E63','E94', 'E99'}},...
    {50,{'E2', 'E3', 'E9', 'E63','E94', 'E99'}},...
    {51,{'E2', 'E3', 'E9', 'E63','E94', 'E99'}},...
    {52,{'E2', 'E3', 'E9', 'E63','E94', 'E99'}},...
    {53,{'E2', 'E3', 'E9', 'E63','E94', 'E99'}},...
    {54,{'E2', 'E3', 'E9', 'E63','E94', 'E99'}},...
    {55,{'E2', 'E3', 'E9', 'E63','E94', 'E99'}},...
    {56,{'E2', 'E3', 'E9', 'E63','E94', 'E99'}},...
    };
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_392_sleep';
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};




cnt = cnt+1;
artifacts.dataset{cnt}   = 'RC_411_sleep';
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {41};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_412_sleep';
artifacts.artifacts{cnt}  = {{33,{'E3'}},{36,{'E2','E3','E23','E26','E29'}}};
artifacts.badtrials{cnt}  = {1};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};




cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_441_sleep';
artifacts.artifacts{cnt}  = {{75,{'E114','E121','E122'}}};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {'E107'};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_442_sleep';
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};




cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_451_sleep';
artifacts.artifacts{cnt}  = {{15,{'E22','E23','E26'}},...
    {16,{'E22','E23','E26'}},...
    {26,{'E6', 'E9', 'E11', 'E15', 'E16', 'E22', 'E78', 'E87'}},...
    {27,{'E22','E72','E87','E99'}},{39,{'E33','E72'}},{41,{'E22','E26','E72'}}};
artifacts.badtrials{cnt}  = {43,44,45,53};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_452_sleep';
artifacts.artifacts{cnt}  = {{11,{'E22'}}};
artifacts.badtrials{cnt}  = {36,44,45,46,47,48,49,50,51,52,53,54,55,56,...
    57,58,59,60,61,62,63,64,65,66,67};
artifacts.badchans{cnt}   = {'E2', 'E3', 'E9', 'E23', 'E26', 'E50',...
    'E56', 'E57', 'E62', 'E64', 'E88', 'E101', 'E108', 'E116', 'E122'}; %Mastoid
artifacts.reref{cnt}      = {'E63', 'E100'};




cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_461_sleep';
artifacts.artifacts{cnt}  = {{38,{'E56','E77','E114'}}};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_462_sleep';
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};




cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_471_sleep';
artifacts.artifacts{cnt}  = {{24,{'E9'}}};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_472_sleep';
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};




cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_481_sleep';
artifacts.artifacts{cnt}  = {{59,{'E66','E71','E72','E82'}},...
    {60,{'E66','E71','E72','E82'}}};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_482_sleep';
artifacts.artifacts{cnt}  = {{39,{'E3','E4','E124','E11','E15',...
    'E18','E19'}}};
artifacts.badtrials{cnt}  = {55};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};




cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_491_sleep';
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_492_sleep';
artifacts.artifacts{cnt}  = {{58,{'E3', 'E9', 'E10', 'E15', 'E22', 'E23',...
    'E26', 'E57', 'E107', 'E108', 'E114'}}};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};




cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_511_sleep';
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {63,64};
artifacts.badchans{cnt}   = {'E39', 'E57', 'E100', 'E101', 'E107', 'E108'}; %Mastoids
artifacts.reref{cnt}      = {'E56', 'E99'};


cnt = cnt+1;
artifacts.dataset{cnt}    = 'RC_512_sleep';
artifacts.artifacts{cnt}  = {};
artifacts.badtrials{cnt}  = {};
artifacts.badchans{cnt}   = {};
artifacts.reref{cnt}      = {'E57', 'E100'};


%% Count noisy channels

Nrecordings = numel(artifacts.badchans);
percBadchans = [];
for recording = 1:Nrecordings
    badchans = artifacts.badchans{recording};

    if isempty(badchans)
        percBadchans(recording) = 0;
    else
        percBadchans(recording) = numel(badchans)/111;
    end
end

meanpercBadchans = mean(percBadchans)*100;
stdpercBadchans = std(percBadchans)*100;

%% Count noisy epochs

load('EventsDescription.mat')
percBadtrials = [];

for recording = 1:Nrecordings
    RecEvents = AllEvents{2,recording};
    totalEvents = numel(RecEvents);
    totaleventsOFF = sum(strcmp({RecEvents.stimulation},'OFF'));
    
    totalValidEvents = totalEvents-totaleventsOFF;
    
    if isempty(artifacts.badtrials{recording})
        percBadtrials(recording) = 0;
    else
        percBadtrials(recording) = numel(artifacts.badtrials{recording})/totalValidEvents;
    end
end

meanpercBadtrials = mean(percBadtrials)*100;
stdpercBadtrials = std(percBadtrials)*100;

%% Count epochs with specific noisy channels

percBadSpecific = [];

for recording = 1:Nrecordings
    
    RecEvents = AllEvents{2,recording};
    totalEvents = numel(RecEvents);
    totaleventsOFF = sum(strcmp({RecEvents.stimulation},'OFF'));
    
    totalValidEvents = totalEvents-totaleventsOFF;

    Artifacts = artifacts.artifacts{recording};
    
    if isempty(Artifacts)
        percBadSpecific(recording) = 0;
    else
        percBadSpecific(recording) = numel(artifacts.artifacts{recording})/totalValidEvents;
    end
end

meanpercBadSpecific = mean(percBadSpecific)*100;
stdpercBBadSpecific = std(percBadSpecific)*100;

%% Count incomplete stimulations 

percIncompleteStims = [];

for recording = 1:Nrecordings
    
    RecEvents = AllEvents{2,recording};
    totalEvents = numel(RecEvents);
    totaleventsOFF = sum(strcmp({RecEvents.stimulation},'OFF'));
    
    totalValidEvents = totalEvents-totaleventsOFF;
    
    IncompleteStims = sum(strcmp({RecEvents.ReasonForRejection},'too short 12'))+...
        sum(strcmp({RecEvents.ReasonForRejection},'too short 15'));

    percIncompleteStims(recording) = IncompleteStims/totalValidEvents;
    
end

meanpercIncompleteStimsc = mean(percIncompleteStims)*100;
stdpercIncompleteStims = std(percIncompleteStims)*100;