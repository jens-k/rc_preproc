%% Common filters test

%% Beamformer tutorial - some minor changes
% to get the data incl. headmodel needed for the beamformer example

datadir = 'C:\Users\Jens Klinzing\Downloads\Fieldtrip dataset';
cd(datadir)

% find the interesting segments of data
cfg = [];                                           % empty configuration
cfg.dataset                 = 'Subject01.ds';       % name of CTF dataset  
cfg.trialdef.eventtype      = 'backpanel trigger';
cfg.trialdef.prestim        = 1;
cfg.trialdef.poststim       = 2;
cfg.trialdef.eventvalue     = 3;                    % event value of FIC
cfg = ft_definetrial(cfg);            
  
% remove the trials that have artifacts from the trl
cfg.trl([15, 36, 39, 42, 43, 49, 50, 81, 82, 84],:) = [];

% preprocess the data
cfg.channel   = {'MEG', '-MLP31', '-MLO12'};        % read all MEG channels except MLP31 and MLO12
cfg.demean    = 'yes';                              % do baseline correction with the complete trial

dataFIC = ft_preprocessing(cfg);

cfg = [];                                           
cfg.toilim = [-0.5 0];                       
dataA = ft_redefinetrial(cfg, dataFIC);
   
cfg.toilim = [0.8 1.3];                       
dataB = ft_redefinetrial(cfg, dataFIC);


% head model
load segmentedmri
cfg = [];
cfg.method = 'singleshell';
vol = ft_prepare_headmodel(cfg, segmentedmri);

cfg                 = [];
cfg.grad            = dataA.grad;
cfg.headmodel       = vol;
cfg.reducerank      = 2;
cfg.channel         = {'MEG','-MLP31', '-MLO12'};
cfg.grid.resolution = 1;   % use a 3-D grid with a 1 cm resolution
cfg.grid.unit       = 'cm';
[grid] = ft_prepare_leadfield(cfg);


%% Common filters example

% append the two conditions and remember the design %
data = ft_appenddata([], dataA, dataB);
design = [ones(1,length(dataA.trial)) ones(1,length(dataB.trial))*2]; % only necessary if you are interested in reconstructing single trial data


% freqanalysis %
cfg=[];
cfg.method      = 'wavelet';
cfg.output      = 'fourier';  % gives power and cross-spectral density matrices
cfg.foilim      = [60 60];      % analyse 40-80 Hz (60 Hz +/- 20 Hz smoothing)
% cfg.taper       = 'dpss';
cfg.toi = data.time{1}(75);
cfg.trials = 1:20;
% cfg.tapsmofrq   = 20;
cfg.width=3;
cfg.keeptrials  = 'yes';        % in order to separate the conditions again afterwards, we need to keep the trials. This is not otherwise necessary to compute the common filter
% cfg.keeptapers  = 'no';

freq = ft_freqanalysis(cfg, data);


% compute common spatial filter %
cfg=[];
cfg.method      = 'pcc';
cfg.grid        = grid;         % previously computed grid
cfg.headmodel   = vol;          % previously computed volume conduction model
cfg.frequency   = 60;
% cfg.pcc.keepfilter  = 'yes';        % remember the filter
cfg.keeptrials='yes';
cfg.fixedori = 'yes';
source = ft_sourceanalysis(cfg, freq);


% project all trials through common spatial filter %
cfg=[];
cfg.method      = 'dics';
cfg.grid        = grid;       % previously computed grid
cfg.headmodel   = vol;        % previously computed volume conduction model
cfg.grid.filter = source.avg.filter; % use the common filter computed in the previous step!
cfg.frequency   = 60;
cfg.rawtrial    = 'yes';      % project each single trial through the filter. Only necessary if you are interested in reconstructing single trial data

source = ft_sourceanalysis(cfg, freq); % contains the source estimates for all trials/both conditions


% calculate average for each condition %

% This step is only necessary if you need to reconstruct single trial data

A = find(design==1); % find trial numbers belonging to condition A
B = find(design==2); % find trial numbers belonging to condition B

sourceA = source;
sourceA.trial(B) = [];
sourceA.cumtapcnt(B) = [];
sourceA.df = length(A);
sourceA = ft_sourcedescriptives([], sourceA); % compute average source reconstruction for condition A

sourceB=source;
sourceB.trial(A) = [];
sourceB.cumtapcnt(A) = [];
sourceB.df = length(B);
sourceB = ft_sourcedescriptives([], sourceB); % compute average source reconstruction for condition B



%% ORIGINAL CODE FROM FREQANALYSIS

% ft_freqanalysis %
cfg=[];
cfg.method      = 'mtmfft';
cfg.output      = 'fourier';  % gives the complex Fourier spectra
cfg.foilim      = [60 60];    % analyse 40-80 Hz (60 Hz +/- 20 Hz smoothing)
cfg.taper       = 'dpss';
cfg.tapsmofrq   = 20;
cfg.keeptrials  = 'yes';      % in order to separate the conditions again afterwards, we need to keep the trials. This is not otherwise necessary to compute the common filter
cfg.keeptapers  = 'yes';

freq = ft_freqanalysis(cfg, data);


% compute common spatial filter AND project all trials through it %
cfg=[]; 
cfg.method      = 'pcc';
cfg.grid        = grid;       % previously computed grid
cfg.headmodel   = vol;        % previously computed volume conduction model
% cfg.frequency   = 60;
cfg.keeptrials  = 'yes';      % keep single trials. Only necessary if you are interested in reconstructing single trial data
cfg.pcc.keepfilter = 'yes';
cfg.pcc.realfilter = 'yes';
cfg.fixedori = 'yes';
source = ft_sourceanalysis(cfg, freq); 

cfg=[];cfg.trials=1:5;dat2 = ft_selectdata(cfg,dat);
getdimord(sourcef2,'mom')

% This step only works with my data if keetrials=no
% here it works also with keeptrials=yes
% in my data keeptrials=yes make that in line 628 size(Cf) = 101 101 while
% it should be 1 101 101...