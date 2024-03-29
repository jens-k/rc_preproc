addpath(genpath('D:\Gits\rc_preproc\'))
% ft_defaults

% addpath(genpath('C:\Users\lanan\Documents\MATLAB\fieldtrip\'))

% addpath('/home/andrea/Documents/MatlabFunctions/fieldtrip/')
ft_defaults
%% General comments
% I wrote this code example down there without ever running it; please
% think of it as a broad pointer into the right direction.

%% ------     FIRST-TIME SETUP
% init_rc;
% paths                       = [];
% paths.root                  = 'D:\Sleep\DataDownload';
% paths.data                  = 'D:\Sleep\DataDownload\Recordings\Both';
% paths.sl_hypnograms         = 'D:\Sleep\DataDownload\Hypnograms';
% paths.save                  = 'D:\Sleep\DataDownload\Preprocessing_ReRef\';

%server
paths                       = [];
paths.root                  = 'D:\germanStudyData\datasetsSETS\Ori_CueNight';
paths.data                  = 'D:\germanStudyData\datasetsSETS\Ori_CueNight';
paths.sl_hypnograms         = 'D:\Gits\EEG_pre_processing\data_specific\GermanData\Hypnograms';
paths.save                  = 'D:\FT_Preprocessing_250_WHOLE\';

mkdir(paths.save)


files = dir(strcat(paths.data,filesep,'*.mff'));


%% Get trial description
% load('D:\Sleep\DataDownload\Recordings\cfg_trial.mat')

p_ArtifactsDefinition

for file = 1:numel(files)
    
    data_filename   = files(file).name;
    hyp_filename    = strcat('s',data_filename(4:5),'_n',data_filename(6),'.txt');
    
    % Here I may want to include some seconds extra before and after,
    % thinking of the futher analysis (i.e. TF)
    cfg_trial					= [];
    cfg_trial.dataset           = fullfile(paths.data, data_filename);% Doing now with subject 12, session 1
    cfg_trial.trialdef.pre		= 15;%5; % all the .trialdef fields are just forwarded to the cfg.trialfun
    cfg_trial.trialdef.post	    = 20;%15;
    cfg_trial.epoch_length_sec  = 30;
    cfg_trial.hypnogram			= fullfile(paths.sl_hypnograms,hyp_filename); % Doing now with subject 12, session 1
    cfg_trial.trialfun          = 'rc_trialfun_2021'; %
    cfg_trial.id                = data_filename(1:6); % unique recording ID for future reference
    cfg_trial.counter           = file;		% to easier find the dataset again later on
    cfg_trial                   = ft_definetrial(cfg_trial);
    
    
    %% Preprocessing: filtering
    
    channels_wo_face   = {'all', '-E49', '-E48', '-E43', '-E127', '-E126', '-E17', '-E128', '-E32', '-E25', '-E21', '-E14', '-E8', '-E1', '-E125', '-E120', '-E119', '-E113','-VREF', '-E129'};

    % The output of ft_definetrial can be used for ft_preprocessing, so we dont
    % have to preprocess and filter the whole dataset, and we save time.
    
    cfg_preproc                     = [];
    cfg_preproc.dataset             = fullfile(paths.data, data_filename);
    cfg_preproc.channel             = channels_wo_face;
    cfg_preproc.detrend             = 'yes';
    cfg_preproc.lpfilter            = 'yes';
    cfg_preproc.lpfilttype          = 'fir';
    cfg_preproc.lpfreq              = 30;
    
    warning('Median filter is disabled')
    
    cfg_preproc.medianfilter        = 'no';
    cfg_preproc.medianfiltord       = 30;
    
    data_preproc                    = ft_preprocessing(cfg_preproc);
    

    %% Preprocessing: interpolation of bad channels
    
    dataset = find(strcmp(artifacts.dataset,[cfg_trial.id,'_sleep']));
    badchannels = artifacts.badchans{dataset};
    
    if ~isempty(badchannels)
        cfg_fixchan                = [];
        cfg_fixchan.method         = 'weighted';
        cfg_fixchan.badchannel     = badchannels;
        cfg_neighb.elec            = 'GSN-HydroCel-128.sfp';%sensors;
        cfg_neighb.method          = 'distance';
        cfg_fixchan.neighbours     = ft_prepare_neighbours(cfg_neighb);
        cfg_fixchan.trials         = 'all';
        
        data_preproc = ft_channelrepair(cfg_fixchan, data_preproc);
    end
   
    %% Re-reference data
    
    cfg_ref                 = [];
    cfg_ref.channel         = 'all'; % this is the default
    cfg_ref.reref           = 'yes';
    cfg_ref.refmethod       = 'avg';
    cfg_ref.refchannel      = artifacts.reref{dataset};
    data_preproc            = ft_preprocessing(cfg_ref, data_preproc);
    
    
    %% Downsampling
    
    cfg_downsample                 =[];
    cfg_downsample.resamplefs      = 250;
    data_downsamp_250              = ft_resampledata(cfg_downsample, data_preproc);
    
    
    newPath = paths.save;%'D:\Sleep\DataDownload\Preprocessing_250Hz\';
    save(strcat(newPath,data_filename(1:12),'.mat'),'cfg_trial','data_downsamp_250','-v7.3')


end