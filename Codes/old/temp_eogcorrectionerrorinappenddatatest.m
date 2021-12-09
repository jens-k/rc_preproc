% ft_preprocessing of example dataset
cfg = [];
cfg.dataset = 'ArtifactRemoval.ds'; 
cfg.trialdef.eventtype = 'trial';
cfg = ft_definetrial(cfg);

cfg = ft_artifact_jump(cfg);
cfg = ft_rejectartifact(cfg);
cfg.trl([3 11 23],:) = []; % quick removal of trials with muscle artifacts, works only for this dataset! 

cfg.channel            = {'MEG', 'EEG058'}; % channel 'EEG058' contains the ECG recording
cfg.continuous         = 'yes';
data = ft_preprocessing(cfg);
% split the ECG and MEG datasets, since ICA will be performed on MEG data but not on ECG channel
% 1 - ECG dataset
cfg              = [];
cfg.channel      = {'EEG'};
ecg              = ft_selectdata(cfg, data); 
ecg.label{:}     = 'ECG'; % for clarity and consistency rename the label of the ECG channel
% 2 - MEG dataset
cfg              = [];
cfg.channel      = {'MEG'};
data              = ft_selectdata(cfg, data); 

data_orig = data; %save the original data for later use
cfg            = [];
cfg.resamplefs = 150;
cfg.detrend    = 'no';
data           = ft_resampledata(cfg, data);

cfg            = [];
cfg.method     = 'runica';
comp           = ft_componentanalysis(cfg, data);

% cfg           = [];
% cfg.component = [1:20];       % specify the component(s) that should be plotted
% cfg.layout    = 'CTF275.lay'; % specify the layout file that should be used for plotting
% cfg.comment   = 'no';
% ft_topoplotIC(cfg, comp)

% cfg          = [];
% cfg.channel  = [2:5 15:18]; % components to be plotted
% cfg.viewmode = 'component';
% cfg.layout   = 'CTF275.lay'; % specify the layout file that should be used for plotting
% ft_databrowser(cfg, comp)


% go back to the raw data on disk and detect the peaks in the ECG channel, i.e. the QRS-complex
cfg                       = [];
cfg.trl                   = data_orig.cfg.previous.trl;
cfg.dataset               = data_orig.cfg.previous.dataset;
cfg.continuous            = 'yes';
cfg.artfctdef.ecg.pretim  = 0.25;
cfg.artfctdef.ecg.psttim  = 0.50-1/1200;
cfg.channel               = {'ECG'};
cfg.artfctdef.ecg.inspect = {'ECG'};
[cfg, artifact]           = ft_artifact_ecg(cfg, ecg);

% preproces the data around the QRS-complex, i.e. read the segments of raw data containing the ECG artifact
cfg            = [];
cfg.dataset    = data_orig.cfg.previous.dataset;
cfg.continuous = 'yes';
cfg.padding    = 10;
cfg.dftfilter  = 'yes';
cfg.demean     = 'yes';
cfg.trl        = [artifact zeros(size(artifact,1),1)];
cfg.channel    = {'MEG'};
data_ecg       = ft_preprocessing(cfg);
cfg.channel    = {'EEG058'};
ecg            = ft_preprocessing(cfg);
ecg.channel{:} = 'ECG'; % renaming is purely for clarity and consistency

% resample to speed up the decomposition and frequency analysis, especially usefull for 1200Hz MEG data
cfg            = [];
cfg.resamplefs = 300;
cfg.detrend    = 'no';
data_ecg       = ft_resampledata(cfg, data_ecg);
ecg            = ft_resampledata(cfg, ecg);

% decompose the ECG-locked datasegments into components, using the previously found (un)mixing matrix
cfg           = [];
cfg.unmixing  = comp.unmixing;
cfg.topolabel = comp.topolabel;
comp_ecg      = ft_componentanalysis(cfg, data_ecg);

% append the ecg channel to the data structure;
comp_ecg      = ft_appenddata([], ecg, comp_ecg);

