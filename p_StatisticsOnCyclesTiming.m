load('EventsDescription_Cycles.mat')

for recording = 1:size(AllKeptEvents,2)
    
    recEvents = AllKeptEvents{2,recording};
    cycleEvents = [recEvents.CutCycleStim] ~= 0;
    
    cycleEvents = recEvents(cycleEvents);
    
    firstStim_idx = find([cycleEvents.CutCycleStim] == 1,1,'first');
    
    firstStim_sample(recording)= cycleEvents(firstStim_idx).sample;
    
    if cycleEvents(firstStim_idx).hour == 23
        firstStim_hour(recording) = 11;
    elseif cycleEvents(firstStim_idx).hour == 0
        firstStim_hour(recording) = 12;
    elseif cycleEvents(firstStim_idx).hour == 1
        firstStim_hour(recording) = 13; 
    end
    firstStim_minute(recording) = cycleEvents(firstStim_idx).minute;
    
end


table(:,1)    = AllKeptEvents(1,:);
table(:,2)    = num2cell(firstStim_sample/(1000*60));
table(:,3)    = num2cell(firstStim_hour);
table(:,4)    = num2cell(firstStim_minute);
table(:,5)    = num2cell(firstStim_minute+(firstStim_hour*60));

