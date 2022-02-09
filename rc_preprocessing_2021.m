addpath(genpath('/home/andrea/Documents/Github/rc_preproc/'))
% ft_defaults

% addpath(genpath('C:\Users\lanan\Documents\MATLAB\fieldtrip\'))

addpath('/home/andrea/Documents/MatlabFunctions/fieldtrip/')
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
paths.root                  = '/mnt/disk1/sleep/German_Study/Data/MFF/Sleep';
paths.data                  = '/mnt/disk1/sleep/German_Study/Data/MFF/Sleep';
paths.sl_hypnograms         = '/mnt/disk1/sleep/German_Study/Data/Hypnograms';
paths.save                  = '/mnt/disk1/sleep/Datasets/TrialDef/Preprocessing_250Hz/';

files = dir(strcat(paths.data,filesep,'*.mff'));


%% Get trial description
% load('D:\Sleep\DataDownload\Recordings\cfg_trial.mat')

p_ArtifactsDefinition

for file = 19%1:numel(files)
    
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
    
    cfg_preproc                     = cfg_trial;
    cfg_preproc.channel             = channels_wo_face;
    cfg_preproc.detrend             = 'yes';
    cfg_preproc.lpfilter            = 'yes';
    cfg_preproc.lpfilttype          = 'fir';
    cfg_preproc.lpfreq              = 30;
    cfg_preproc.medianfilter        = 'yes'; 
    cfg_preproc.medianfiltord       = 30;
    
    data_preproc                    = ft_preprocessing(cfg_preproc);
    
    %consider downsampling the data / talk to David about the analysis
    %metodos: specify for which specific analysis the data was downsampled
    %for
    
    %crear carpeta con ambos: downsampled and not downsampled. Make sure
    %about the triggers. should look the same in the databrowser if I do it
    %at the end
    
%     save(strcat(paths.save,data_filename(1:12),'.mat'),'cfg_trial','data_preproc','-v7.3')

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
    %% Preprocessing: interpolation of specific artifacts
    
    subj_artifacts = artifacts.artifacts{dataset};
    
    if ~isempty(subj_artifacts)
        
        for trial = 1:numel(subj_artifacts)
            badtrial                = subj_artifacts{trial}{1};
            badtrialIdx             = zeros(1,numel(data_preproc.trial));
            badtrialIdx(badtrial)   = 1;
            badtrialIdx             = logical(badtrialIdx);
            badchannels             = subj_artifacts{trial}{2};
            
            cfg_fixartfs                = [];
            cfg_fixartfs.method         = 'weighted';
            cfg_fixartfs.badchannel     = badchannels;
            cfg_neighb.elec             = 'GSN-HydroCel-128.sfp';%sensors;
            cfg_neighb.method           = 'distance';
            cfg_fixartfs.neighbours     = ft_prepare_neighbours(cfg_neighb);
            cfg_fixartfs.trials         = badtrialIdx;
            
            data_preproc_temp = ft_channelrepair(cfg_fixartfs, data_preproc);
            
            data_preproc.trial{badtrial} = data_preproc_temp.trial{:};
        end
    end
    
    % Remove the noisy trials
    
    badtrials = cell2mat(artifacts.badtrials{dataset});
    
    if ~isempty(badtrials)
        includedtrials = ones(1,numel(data_preproc.trial));
        includedtrials(badtrials)=0;
        
        cfg             = [];
        cfg.trials      = find(includedtrials);
        data_preproc    = ft_selectdata(cfg, data_preproc);
    end
    
    % Re-reference data
    
    cfg_ref                 = [];
    cfg_ref.channel         = 'all'; % this is the default
    cfg_ref.reref           = 'yes';
    cfg_ref.refmethod       = 'avg';
    cfg_ref.refchannel      = {'E57', 'E100'}; %Mastoids
    data_preproc            = ft_preprocessing(cfg_ref, data_preproc);
    
    
    % save(strcat(paths.save,data_filename(1:12),'.mat'),'cfg_trial','data_preproc','-v7.3')

    %% Downsampling
    
    cfg_downsample                 =[];
    cfg_downsample.resamplefs      = 250;
    data_downsamp_250              = ft_resampledata(cfg_downsample, data_preproc);
    
    
    newPath = paths.save;%'D:\Sleep\DataDownload\Preprocessing_250Hz\';
    save(strcat(newPath,data_filename(1:12),'.mat'),'cfg_trial','data_downsamp_250','-v7.3')

        
    % cfg_downsample                 = [];
    % cfg_downsample.resamplefs      = 100;
    % data_downsamp_100              = ft_resampledata(cfg_downsample, data_preproc);
    
    % newPath = 'D:\Sleep\DataDownload\Preprocessing_100Hz\';
    % save(strcat(newPath,data_filename(1:12),'.mat'),'cfg_trial','data_downsamp_100','-v7.3')

end

%% Visual inspection of channels
% % % 
% 
% channels_wo_face   = {'all', '-E49', '-E48', '-E43', '-E127', '-E126', '-E17', '-E128', '-E32', '-E25', '-E21', '-E14', '-E8', '-E1', '-E125', '-E120', '-E119', '-E113','-VREF', '-E129'};

% cfg_db                          = [];
% cfg_db.viewmode                 = 'vertical';
% cfg_db.preproc.baselinewindow   = [-5,15];
% % cfg_db.latency         = [-5,15];
% cfg_db.channel                  = channels_wo_face;
% cfg_db.ylim                     = [-20 20];
% cfg_db                          = ft_databrowser(cfg_db, data_downsamp_250);
% % % % 
% %% Artifact detectionahh
% 
% path_prep = 'D:\Sleep\DataDownload\PreprocessingBPFilter';
% files = dir(strcat(path_prep,filesep,'*.mat'));
% 
% 
% for file = 1:numel(files)
%     
%     load(files(file).name)
%     %
%     cfg_art					= [];
%     cfg_art.continuous      = 'yes';
%     %cfg_art.trl             = cfg_trial.trl;
%     %cfg_art.dataset         = data_preproc;
%     cfg_art.artfctdef       = [];
%     
%     % Z-value based rejection
%     % This is the one from here: https://www.fieldtriptoolbox.org/tutorial/automatic_artifact_rejection/#examples-for-getting-started
%     % All those parameters are just what worked for me at some point, dont use
%     % them necessarily
%     
%     
%     cfg_art.artfctdef.zvalue.channel     = channels_wo_face; % dont incorporate artifact-prone frontal channels
%     cfg_art.artfctdef.zvalue.trlpadding  = 0;
%     cfg_art.artfctdef.zvalue.fltpadding  = 1;   % only used for filtering before artifact detection (tutorial: .1)
%     cfg_art.artfctdef.zvalue.artpadding  = 0.4; % window around artifacts still rejected
%     cfg_art.artfctdef.zvalue.detrend     = 'yes';
%     cfg_art.artfctdef.zvalue.bpfilter    = 'yes';
%     cfg_art.artfctdef.zvalue.bpfreq      = [0.6 30]; % check tutorals for optimal values
%     cfg_art.artfctdef.zvalue.bpfiltord   = 8;
%     cfg_art.artfctdef.zvalue.bpfilttype  = 'fir';
%     cfg_art.artfctdef.zvalue.hilbert     = 'yes';         % ?
%     cfg_art.artfctdef.zvalue.boxcar      = 0.2;           % ?
%     cfg_art.artfctdef.zvalue.interactive = 'yes';
%     cfg_art.artfctdef.zvalue.cutoff      = 0.6;
%     cfg_art.feedback                     = 'yes';
%     cfg_art                              = ft_artifact_zvalue(cfg_art,data_preproc);
%     
% end
% % 
% % % There is also the one from here: 
% % % https://www.fieldtriptoolbox.org/tutorial/visual_artifact_rejection/#manual-artifact-rejection---display-a-summary
% % % ...which looks cool but it works differencely than all the
% % % ft_artifact_xxx functions. It needs data and gives you back lists of
% % % rejectable trials and channels I think.
% % % cfg          = [];
% % % cfg.method   = 'summary';
% % % cfg.ylim     = [-1e-12 1e-12];
% % % dummy        = ft_rejectvisual(cfg,dataFIC);
% % 
% % % And then there is a fully manual way of detection artifacts, by marking
% % % them in the databrowser. Here you can also see all the previously
% % % determined artifacts and doublecheck them. There might be a few mistakes
% % % in this code, didnt double check:
% % cfg_db                 = [];
% % cfg_db.viewmode        = 'vertical';
% % cfg_db.channel         = channels_wo_face;
% % % cfg_db.data            = data_preproc;%fullfile(paths.data, 'RC_121_sleep.mff');%Doing now with subject 12, session 1
% % % cfg_db.blocksize       = 30;		
% % cfg_db.ylim            = [-120 120];
% % % cfg_db.selectmode      = 'markartifact';
% % % cfg_db.artfctdef	   = cfg_art.artfctdef;
% % cfg_db                 = ft_databrowser(cfg_db, data_preproc);
% % 
% % %save(cfg_art, path_artifactdef);