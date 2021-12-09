% Analysis pipeline, mostly using the wrapper hh_callFunction() to run
% analyses over whole folders.
%
% Fields of the cfg may be processedby the fieldtrip function or further
% wrapper functions. Only fields processed by hh_callFunction are marked as
% such, using the prefix 'hh_' (eg. in cfg.hh_analyze).
%
% AUTHOR:
% Jens Klinzing, jens.klinzing@uni-tuebingen.de

%% ------     SETTINGS      
% ... and parameters that are used more than once
% Clean data is taken from the respective sensor-level analysis
error('Don''t try to run this file by accidentally pressing F5.');

home                            = hh_getHome(); 
dirFiles.home                   = fullfile(home, 'data', 'source-level analysis 4.0');
dirFiles.meta                   = fullfile(dirFiles.home, 'meta');
dirFiles.clean                  = fullfile(home, 'data', 'sensor-level analysis 3.0 non-events', 'clean');
dirFiles.headmodel              = fullfile(home, 'data', 'headmodel');  
dirFiles.preparedMRI            = fullfile(dirFiles.headmodel, 'prepared mri');     % correctly realinged MRI scans should be provided (see Further Comments)
dirFiles.segmentedMRI           = fullfile(dirFiles.headmodel, 'segmented mri');
dirFiles.trialInfo              = fullfile(dirFiles.meta, 'trialinfo');     % files saying which trial is from which condition
dirFiles.commonFilters_FS       = fullfile(home, 'data', 'source-level analysis 4.x common filters', 'FS');
dirFiles.commonFilters_SSH      = fullfile(home, 'data', 'source-level analysis 4.x common filters', 'SSH');
dirFiles.commonFilters_SS       = fullfile(home, 'data', 'source-level analysis 4.x common filters', 'SS');
dirFiles.commonFilters_FSDO     = fullfile(home, 'data', 'source-level analysis 4.x common filters', 'FSDO');

dirFiles.grids                  = fullfile(dirFiles.meta, 'MNI-aligned grids 8mm');

file_source_cmap                = fullfile(home, 'data', 'meta', 'source_cmap128.mat');
fileSampleinfo                  = fullfile(dirFiles.home, 'meta', 'sampleinfo.mat');        % sample info (extracted by hh_extractSampleinfo)
fileGrad                        = fullfile(dirFiles.home, 'meta', 'movement grads.mat');    % results from ft_headmovement will be saved here
subjectdata                     = hh_getSubjectdata;
channel_all                     = {'MEG'};
channel_good                    = {'MEG', '-MLF21','-MRO52','-MRP44', '-MRO11'}; % only channels that work in all subjects
gridResolution                  = 8;    % 4, 5, 6, 7.5, 8, or 10 mm, chooses MNI-template accordingly
vdown_edit                      = [0,0.967741935483871,0.935483870967742,0.903225806451613,0.870967741935484,0.838709677419355,0.806451612903226,0.774193548387097,0.741935483870968,0.709677419354839,0.677419354838710,0.645161290322581,0.612903225806452,0.580645161290323,0.548387096774194,0.516129032258065,0.483870967741936,0.451612903225807,0.419354838709677,0.387096774193548,0.354838709677419,0.322580645161290,0.290322580645161,0.258064516129032,0.225806451612903,0.193548387096774,0.161290322580645,0.129032258064516,0.0967741935483871,0.0645161290322581,0.0322580645161290,0,0,0.0322580645161290,0.0645161290322581,0.0967741935483871,0.129032258064516,0.161290322580645,0.193548387096774,0.225806451612903,0.258064516129032,0.290322580645161,0.322580645161290,0.354838709677419,0.387096774193548,0.419354838709677,0.451612903225806,0.483870967741936,0.516129032258065,0.548387096774194,0.580645161290323,0.612903225806452,0.645161290322581,0.677419354838710,0.709677419354839,0.741935483870968,0.774193548387097,0.806451612903226,0.838709677419355,0.870967741935484,0.903225806451613,0.935483870967742,0.967741935483871,1];
mri_mni                         = ft_read_mri(fullfile(home, '_fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));
labels_cerebrum                 = {'Precentral_L';'Precentral_R';'Frontal_Sup_L';'Frontal_Sup_R';'Frontal_Sup_Orb_L';'Frontal_Sup_Orb_R';'Frontal_Mid_L';'Frontal_Mid_R';'Frontal_Mid_Orb_L';'Frontal_Mid_Orb_R';'Frontal_Inf_Oper_L';'Frontal_Inf_Oper_R';'Frontal_Inf_Tri_L';'Frontal_Inf_Tri_R';'Frontal_Inf_Orb_L';'Frontal_Inf_Orb_R';'Rolandic_Oper_L';'Rolandic_Oper_R';'Supp_Motor_Area_L';'Supp_Motor_Area_R';'Olfactory_L';'Olfactory_R';'Frontal_Sup_Medial_L';'Frontal_Sup_Medial_R';'Frontal_Med_Orb_L';'Frontal_Med_Orb_R';'Rectus_L';'Rectus_R';'Insula_L';'Insula_R';'Cingulum_Ant_L';'Cingulum_Ant_R';'Cingulum_Mid_L';'Cingulum_Mid_R';'Cingulum_Post_L';'Cingulum_Post_R';'Hippocampus_L';'Hippocampus_R';'ParaHippocampal_L';'ParaHippocampal_R';'Amygdala_L';'Amygdala_R';'Calcarine_L';'Calcarine_R';'Cuneus_L';'Cuneus_R';'Lingual_L';'Lingual_R';'Occipital_Sup_L';'Occipital_Sup_R';'Occipital_Mid_L';'Occipital_Mid_R';'Occipital_Inf_L';'Occipital_Inf_R';'Fusiform_L';'Fusiform_R';'Postcentral_L';'Postcentral_R';'Parietal_Sup_L';'Parietal_Sup_R';'Parietal_Inf_L';'Parietal_Inf_R';'SupraMarginal_L';'SupraMarginal_R';'Angular_L';'Angular_R';'Precuneus_L';'Precuneus_R';'Paracentral_Lobule_L';'Paracentral_Lobule_R';'Caudate_L';'Caudate_R';'Putamen_L';'Putamen_R';'Pallidum_L';'Pallidum_R';'Thalamus_L';'Thalamus_R';'Heschl_L';'Heschl_R';'Temporal_Sup_L';'Temporal_Sup_R';'Temporal_Pole_Sup_L';'Temporal_Pole_Sup_R';'Temporal_Mid_L';'Temporal_Mid_R';'Temporal_Pole_Mid_L';'Temporal_Pole_Mid_R';'Temporal_Inf_L';'Temporal_Inf_R'};
labels_cerebrum_reduced         = {'Precentral_L';'Precentral_R';'Frontal_Sup_L';'Frontal_Sup_R';'Frontal_Sup_Orb_L';'Frontal_Sup_Orb_R';'Frontal_Mid_L';'Frontal_Mid_R';'Frontal_Mid_Orb_L';'Frontal_Mid_Orb_R';'Frontal_Inf_Oper_L';'Frontal_Inf_Oper_R';'Frontal_Inf_Tri_L';'Frontal_Inf_Tri_R';'Frontal_Inf_Orb_L';'Frontal_Inf_Orb_R';'Rolandic_Oper_L';'Rolandic_Oper_R';'Supp_Motor_Area_L';'Supp_Motor_Area_R';'Olfactory_L';'Olfactory_R';'Frontal_Sup_Medial_L';'Frontal_Sup_Medial_R';'Frontal_Med_Orb_L';'Frontal_Med_Orb_R';'Rectus_L';'Rectus_R';'Insula_L';'Insula_R';'Hippocampus_L';'Hippocampus_R';'ParaHippocampal_L';'ParaHippocampal_R';'Amygdala_L';'Amygdala_R';'Calcarine_L';'Calcarine_R';'Cuneus_L';'Cuneus_R';'Lingual_L';'Lingual_R';'Occipital_Sup_L';'Occipital_Sup_R';'Occipital_Mid_L';'Occipital_Mid_R';'Occipital_Inf_L';'Occipital_Inf_R';'Fusiform_L';'Fusiform_R';'Postcentral_L';'Postcentral_R';'Parietal_Sup_L';'Parietal_Sup_R';'Parietal_Inf_L';'Parietal_Inf_R';'SupraMarginal_L';'SupraMarginal_R';'Angular_L';'Angular_R';'Precuneus_L';'Precuneus_R';'Paracentral_Lobule_L';'Paracentral_Lobule_R';'Caudate_L';'Caudate_R';'Putamen_L';'Putamen_R';'Pallidum_L';'Pallidum_R';'Thalamus_L';'Thalamus_R';'Heschl_L';'Heschl_R';'Temporal_Sup_L';'Temporal_Sup_R';'Temporal_Pole_Sup_L';'Temporal_Pole_Sup_R';'Temporal_Mid_L';'Temporal_Mid_R';'Temporal_Pole_Mid_L';'Temporal_Pole_Mid_R';'Temporal_Inf_L';'Temporal_Inf_R'};

FSfreq                          = [14 14];    % frequency of the fast spindles
FSfreqband                      = 2;          % +/- Hz
FStime                          = [0.3 0.8];  % in relation to the SO troughs

SSHfreq                         = [10 10];   % frequency of the normal slow spindles
SSHfreqband                     = 1.5;
SSHtime                         = [-0.4 0.1];

SSfreq                          = [8 8];      % frequency of the slow spindles
SSfreqband                      = 1.5;
SStime                          = [-0.4 0.1];

FSDOfreq                        = [14 14];    % frequency of the fast spindles
FSDOfreqband                    = 2;          % +/- Hz
FSDOtime                        = [-0.25 0.25];  % in relation to the SO troughs


% For ripples (RP): 2 means narrow band, DU means DOWN-UP phase instead of up phase
% RPfreq                          = [110 110];
% RPfreqband                      = 30;
% RPtime                          = [0.4 0.7];  % 0.3s = 33 cycles @ 110 Hz
% RPDUfreq                        = [110 110];
% RPDUfreqband                    = 30;
% RPDUtime                        = [0.1 0.4];  
% RP2freq                         = [90 90];
% RP2freqband                     = 10;
% RP2time                         = [0.4 0.7];  
% RPDU2freq                       = [90 90];
% RPDU2freqband                   = 10;
% RPDU2time                       = [0.1 0.4];  


%% ------     START WITH CLEANED DATA       
%  ------     ...after artifact rejection and ica component rejection (s. sensor-level preprocessing)    ------ 


%% ------     EXTRACT SAMPLEINFO
% results in Nx3 cell arrays that are saved into one .mat file

hh_extractSampleinfo(dirFiles.clean, fileSampleinfo);            

                            
%% ------     HEAD MOVEMENT CORRECTION (FT_HEADMOVEMENT)    

% see Further comments: Clustering algorithm
numberOfClusters                    = [12 12 12 12 1 1 1 12 12 12 12 12 12 12]; 
trl                                 = hh_loadData(fileSampleinfo); 

for subj = 1:length(subjectdata)     % for each subject
    
    cfg                                 = [];
    
    % If the number of clusters was specified run the algorithm, otherwise
    % just extract the grad info from the preprocessed dataset.
    cfg.dataset                     = subjectdata{subj}.MEGdir;
    cfg.numclusters                 = numberOfClusters(subj); % number of segments with constant headposition in which to split the data (default = 12)
    cfg.trl                         = trl{subj}; % Nx3 matrix with the trial definition, see FT_DEFINETRIAL
    succeeded                       = 0;
    while succeeded == 0
        try
            grad{subj}                      = ft_headmovement_edited(cfg);
            succeeded                       = 1;
        catch err
            if strcmp('stats:kmeans:EmptyCluster', err.identifier) % lost all clusters? (can happen with k-means)
                % tell the user about your loss; let the loop go for another round
                disp('Lost all clusters, will try again!')
            else rethrow(err)
            end
        end
    end
    
    close all

end

% Save one file for the current condition containing the grads for all subjects
if ~exist(dirFiles.meta,'dir'), mkdir(dirFiles.meta); end
save(fileGrad, 'grad');
                         

%% ------     GENERATE HEAD MODELS      
% Headmodels were taken from source-level analysis 2.1 (expressed in cm)
% using this code:
%
% hh_generateHeadmodel calls ft_read_mri, ft_volumereslice,
% ft_volumesegment, ft_prepare_headmodel, ft_convert_units
% Think about using the preexisting ones!

% Results are saved in dirFiles.headmodel / .segmentedMRI /.preparedMRI

% cfg                         = [];
% 
% % Parameters for saving files
% cfg.saveSegmentedMRI        = dirFiles.segmentedMRI;
% cfg.saveHeadmodel           = dirFiles.headmodel;
% cfg.savePreparedMRI         = dirFiles.preparedMRI;
% 
% % Parameters for ft_volumereslice
% cfg.reslice.dim             = [256 256 256];                 % original dimension
% 
% % Parameters for ft_volumesegment
% cfg.segment.write           = 'no';
% cfg.segment.output          = 'tpm';
% cfg.segment.coordsys        = 'ctf';
% 
% % Parameters for ft_prepare_headmodel
% cfg.hm.method               = 'singleshell'; % for EEG: probably use 'dipoli' (Oostendorp's BEM implementation)
% % cfg.hm.tissue               = 'brain';
% 
%                             hh_generateHeadmodel(cfg);


%% ------     GENERATE SUBJECT-SPECIFIC MNI-ALIGNED GRID  
% see Further Notes: Using MNI-aligned grids in individual head space
% and Further Notes: Leadfield and Sourcemodel preparation

% Note that generate leadfield is a misnomer since the here only the grid
% is computed. The leadfield is later created by ft_prepare_leadfield or 
% on-the-fly by ft_sourceanalysis

cfg                         = [];
cfg.saveTo                  = dirFiles.grids;
cfg.fileGrad                = fileGrad; 
cfg.resolution              = gridResolution;
cfg.dirPreparedMRI          = dirFiles.preparedMRI;
cfg.unit                    = 'cm';

                            hh_callFunction('hh_prepareMNIalignedGrid', cfg, dirFiles.headmodel);

           
%% ------     REDEFINE TRIALS    
% to choose the correct time range

dirFiles.FS                 = fullfile(dirFiles.home, 'fast spindles');
dirFiles.SS                 = fullfile(dirFiles.home, 'slow spindles');
dirFiles.SSH                = fullfile(dirFiles.home, 'slow spindles 10Hz');
dirFiles.FSDO               = fullfile(dirFiles.home, 'fast spindles DOWN');

% dirFiles.RP                 = fullfile(dirFiles.home, 'ripples');
% dirFiles.RPDU               = fullfile(dirFiles.home, 'ripples down-up');
% dirFiles.RP2                = fullfile(dirFiles.home, 'ripples narrow band');
% dirFiles.RPDU2              = fullfile(dirFiles.home, 'ripples down-up narrow band');

cfg                         = [];  

% ---  Fast spindles

cfg.toilim                  = FStime;        %  Time should be: full cycles / freq !!
cfg.saveTo                  = dirFiles.FS;

                            hh_callFunction('ft_redefinetrial',cfg, dirFiles.clean);

% ---  Slow spindles                            
cfg.toilim                  = SStime;                       
cfg.saveTo                  = dirFiles.SS;

                            hh_callFunction('ft_redefinetrial',cfg, dirFiles.clean);

% ---  Slow spindles 10 Hz                            
cfg.toilim                  = SSHtime;                       
cfg.saveTo                  = dirFiles.SSH;

                            hh_callFunction('ft_redefinetrial',cfg, dirFiles.clean);

% ---  Fast spindles DOWN STATE

cfg.toilim                  = FSDOtime;        %  Time should be: full cycles / freq !!
cfg.saveTo                  = dirFiles.FSDO;

                            hh_callFunction('ft_redefinetrial',cfg, dirFiles.clean);

                            
% % ---  Ripples
% cfg.toilim                  = RPtime;                       
% cfg.saveTo                  = dirFiles.RP;
% 
%                             hh_callFunction('ft_redefinetrial',cfg, dirFiles.clean);
% 
% % ---  Ripples - DOWN-UP phase
% cfg.toilim                  = RPDUtime;                       
% cfg.saveTo                  = dirFiles.RPDU;
% 
%                             hh_callFunction('ft_redefinetrial',cfg, dirFiles.clean);
% 
% % ---  Ripples - Narrow band
% cfg.toilim                  = RPtime;                       
% cfg.saveTo                  = dirFiles.RP2;
% 
%                             hh_callFunction('ft_redefinetrial',cfg, dirFiles.clean);
% 
% % ---  Ripples - Narrow band, DOWN-UP phase
% cfg.toilim                  = RPDUtime;                       
% cfg.saveTo                  = dirFiles.RPDU2;
% 
%                             hh_callFunction('ft_redefinetrial',cfg, dirFiles.clean);
   
                            
%% ------     TIME-FREQUENCY ANALYSIS           
% ... to later construct a common spatial filter - MANY PARAMETER VARIATIONS POSSIBLE!
% see http://fieldtrip.fcdonders.nl/example/common_filters_in_beamforming
% TODO: Change to DICS? With foilim eg. [13 15] and [7.5 8.5]?
%
% Compute time-frequency analysis with baseline and experimental condition
% combined -- needed to build a common spatial filter
cfg                         = [];
cfg.method                  = 'mtmfft';    % mtmfft = multitaper frequency transformation, no time dimension!
cfg.output                  = 'powandcsd';
cfg.keeptrials              = 'yes';

% Fast spindles:
cfg.foilim                  = FSfreq;              % frequency of interest
cfg.tapsmofrq               = FSfreqband;          % +/- how many Hz (taper smoothing frequency)

dirFiles.FS_TFR             = hh_callFunction('ft_freqanalysis', cfg, dirFiles.FS);


% Slow spindles 10 Hz:
cfg.foilim                  = SSHfreq;
cfg.tapsmofrq               = SSHfreqband; 

dirFiles.SSH_TFR             = hh_callFunction('ft_freqanalysis', cfg, dirFiles.SSH);


% Slow spindles 08 Hz:
cfg.foilim                  = SSfreq;
cfg.tapsmofrq               = SSfreqband; 

dirFiles.SS_TFR             = hh_callFunction('ft_freqanalysis', cfg, dirFiles.SS);

% Fast spindles DOWN STATE:
cfg.foilim                  = FSDOfreq;              % frequency of interest
cfg.tapsmofrq               = FSDOfreqband;          % +/- how many Hz (taper smoothing frequency)

dirFiles.FSDO_TFR           = hh_callFunction('ft_freqanalysis', cfg, dirFiles.FSDO);


% % Ripples:
% cfg.foilim                  = RPfreq;
% cfg.tapsmofrq               = RPfreqband; 
% 
% dirFiles.RP_TFR             = hh_callFunction('ft_freqanalysis', cfg, dirFiles.RP);
% 
% % Ripples - DOWN-UP phase:
% cfg.foilim                  = RPDUfreq;
% cfg.tapsmofrq               = RPDUfreqband; 
% 
% dirFiles.RPDU_TFR           = hh_callFunction('ft_freqanalysis', cfg, dirFiles.RPDU);
% 
% % Ripples - Narrow band:
% cfg.foilim                  = RP2freq;
% cfg.tapsmofrq               = RP2freqband; 
% 
% dirFiles.RP2_TFR             = hh_callFunction('ft_freqanalysis', cfg, dirFiles.RP2);
% 
% % Ripples - Narrow band, DOWN-UP phase:
% cfg.foilim                  = RPDU2freq;
% cfg.tapsmofrq               = RPDU2freqband; 
% 
% dirFiles.RPDU2_TFR           = hh_callFunction('ft_freqanalysis', cfg, dirFiles.RPDU2);


%% ------     SOURCE MODELLING - ALL SPINDLES               IN-SCRIPT REBUILT after artifact messup
% Note that the automatic grand averages here are a) performed over all
% subjects, and b) consider split datasets as two units of observation (no
% merge done prior to averaging). These things have to be dealt with
% manually later.
%
% See Further comments: DICS beamforming
% and http://fieldtrip.fcdonders.nl/example/common_filters_in_beamforming

subjectsToAverage_TUE            = [1 2 3 4 5 6 7 8 9 11 12];   % subjects to consider for the grand average (after merge = TÜ notation!)

dirFiles.FS_sources         = fullfile(dirFiles.home, 'sources FS');
dirFiles.FS_base            = fullfile(dirFiles.FS_sources, 'baseline');
dirFiles.FS_exp             = fullfile(dirFiles.FS_sources, 'experimental');
% dirFiles.FS_trials          = fullfile(dirFiles.FS_sources, 'trials');
dirFiles.FS_results         = fullfile(dirFiles.FS_sources, 'results');
dirFiles.FS_merged          = fullfile(dirFiles.FS_results, 'merged');
dirFiles.FS_merged_int      = fullfile(dirFiles.FS_results, 'merged int');

dirFiles.SSH_sources        = fullfile(dirFiles.home, 'sources SSH');
dirFiles.SSH_base           = fullfile(dirFiles.SSH_sources, 'baseline');
dirFiles.SSH_exp            = fullfile(dirFiles.SSH_sources, 'experimental');
% dirFiles.SSH_trials         = fullfile(dirFiles.SSH_sources, 'trials');
dirFiles.SSH_results        = fullfile(dirFiles.SSH_sources, 'results');
dirFiles.SSH_merged         = fullfile(dirFiles.SSH_results, 'merged');
dirFiles.SSH_merged_int     = fullfile(dirFiles.SSH_results, 'merged int');

dirFiles.SS_sources         = fullfile(dirFiles.home, 'sources SS');
dirFiles.SS_base            = fullfile(dirFiles.SS_sources, 'baseline');
dirFiles.SS_exp             = fullfile(dirFiles.SS_sources, 'experimental');
% dirFiles.SS_trials          = fullfile(dirFiles.SS_sources, 'trials');
dirFiles.SS_results         = fullfile(dirFiles.SS_sources, 'results');
dirFiles.SS_merged          = fullfile(dirFiles.SS_results, 'merged');
dirFiles.SS_merged_int      = fullfile(dirFiles.SS_results, 'merged int');

dirFiles.FSDO_sources         = fullfile(dirFiles.home, 'sources FSDO');
dirFiles.FSDO_base            = fullfile(dirFiles.FSDO_sources, 'baseline');
dirFiles.FSDO_exp             = fullfile(dirFiles.FSDO_sources, 'experimental');
% dirFiles.FSDO_trials          = fullfile(dirFiles.FSDO_sources, 'trials');
dirFiles.FSDO_results         = fullfile(dirFiles.FSDO_sources, 'results');
dirFiles.FSDO_merged          = fullfile(dirFiles.FSDO_results, 'merged');
dirFiles.FSDO_merged_int      = fullfile(dirFiles.FSDO_results, 'merged int');

tfrs                        = {dirFiles.FS_TFR, dirFiles.SSH_TFR, dirFiles.SS_TFR, dirFiles.FSDO_TFR};
sources                     = {dirFiles.FS_sources, dirFiles.SSH_sources, dirFiles.SS_sources, dirFiles.FSDO_sources};
bases                       = {dirFiles.FS_base, dirFiles.SSH_base, dirFiles.SS_base, dirFiles.FSDO_base};
exps                        = {dirFiles.FS_exp, dirFiles.SSH_exp, dirFiles.SS_exp, dirFiles.FSDO_exp};
results                     = {dirFiles.FS_results, dirFiles.SSH_results, dirFiles.SS_results, dirFiles.FSDO_results};
merged                      = {dirFiles.FS_merged, dirFiles.SSH_merged, dirFiles.SS_merged, dirFiles.FSDO_merged};
merged_int                  = {dirFiles.FS_merged_int, dirFiles.SSH_merged_int, dirFiles.SS_merged_int, dirFiles.FSDO_merged_int};
cfilters                    = {dirFiles.commonFilters_FS, dirFiles.commonFilters_SSH, dirFiles.commonFilters_SS, dirFiles.commonFilters_FSDO};
names                       = {'FS', 'SSH', 'SS', 'FSDO'};
gradios                     = {fileGrad, fileGrad, fileGrad, fileGrad};
mri_mni                     = ft_read_mri(fullfile(home, '_fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));
template                    = hh_loadData(fullfile(home,'_fieldtrip','template', 'sourcemodel', ['standard_sourcemodel3d' num2str(gridResolution) 'mm.mat']));


% Since we use MNI-aligned grids are used, the result is not interpolated
% to subject MRI and then normalized to the MNI, but is directly inter-
% polated to the MNI-template MRI.

for iPart = 4 %1:numel(tfrs)

    % One source localization for each subject
    for iSubj = 1:14
        disp(['Starting source analysis of part ' num2str(iPart) '/' num2str(numel(tfrs)) ', subject ' num2str(iSubj)])
        
        mri_mni                     = ft_read_mri(fullfile(home, '_fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));
        tfr                         = hh_loadData(tfrs{iPart}, iSubj);
        design                      = hh_loadData(dirFiles.trialInfo, iSubj);
        grads                       = hh_loadData(gradios{iPart});
        
        cfg                         = [];
        cfg.vol                     = hh_loadData(dirFiles.headmodel, iSubj);
        cfg.grid                    = hh_loadData(dirFiles.grids, iSubj);
        cfg.frequency               = tfr.freq;
        cfg.method                  = 'dics';       % use dynamic imaging of coherent sources (Gross2001)
        cfg.dics.projectnoise       = 'yes';        % estimates the noise at every location; not very precise
        cfg.dics.lambda             = '5%';         % regularization parameter
        cfg.dics.keepfilter         = 'yes';        % save the calculated filter, e.g. to use it as a common filter
        cfg.dics.realfilter         = 'yes';        % only use the real part of the fourier transform
        cfg.dics.powmethod          = 'lambda1';    % 'trace' or 'lambda1' (default)
        cfg.keeptrials              = 'yes';        % trials must be kept when two conditions are compared together
        cfg.grad                    = grads{iSubj};     % ft_headmovement have to be given here again (although Joerg said otherwise)
        
        source_cb                   = ft_sourceanalysis(cfg, tfr);
        
        
        % Save the common filter for use in other analysis branches
        filter                      = source_cb.avg.filter;
        if ~exist(cfilters{iPart},'dir'), mkdir(cfilters{iPart}); end
        save(fullfile(cfilters{iPart}, ['source_combined_' hh_count2subjectname(iSubj) '_' names{iPart} '_filter']), 'filter','-v7.3');
        
        clear source_cb
        
        % Use that filter to source localize each trial
        cfg.grid.filter                     = filter;
        cfg.dics.keepfilter                 = 'no';       % this time we don't need it anymore (keeping it used to lead to an error bug 2861)
        cfg.rawtrial                        = 'yes';      % project each single trial through the filter (instead of only the average)
        source_trials                       = ft_sourceanalysis(cfg, tfr);
        
        source_trials.pos                   = template.pos;
        source_trials.dim                   = template.dim;
        
        % The trials cannot be saved here, because its just to much (up to >55 GB)
        
        % Split the conditions, save and contrast them
        design_exp                          = find(design == 0);
        design_base                         = find(design == 1);
        source_exp                          = source_trials;
        source_base                         = source_trials;
        
        cfg_des                             = [];
        source_exp.trial(design_base)       = [];   % delete unneeded trials
        source_exp.trialinfo(design_base)   = [];
        source_exp.cumtapcnt(design_base)   = [];
        source_exp.df                       = length(design_exp);
        source_exp                          = ft_sourcedescriptives(cfg_des, source_exp); % compute average source reconstruction for condition A
        source_exp.cfg.previous             = [];
        
        cfg_des                             = [];
        source_base.trial(design_exp)       = [];   % delete unneeded trials
        source_base.trialinfo(design_exp)   = [];
        source_base.cumtapcnt(design_exp)   = [];
        source_base.df                      = length(design_base);
        source_base                         = ft_sourcedescriptives(cfg_des, source_base); % compute average source reconstruction for condition A
        source_base.cfg.previous            = [];
        
        if ~exist(bases{iPart},'dir'), mkdir(bases{iPart}); end
        save(fullfile(bases{iPart}, ['source_base_' hh_count2subjectname(iSubj) '_' names{iPart}]), 'source_base','-v7.3');
        
        if ~exist(exps{iPart},'dir'), mkdir(exps{iPart}); end
        save(fullfile(exps{iPart}, ['source_exp_' hh_count2subjectname(iSubj) '_' names{iPart}]), 'source_exp','-v7.3');
        
        source_diff = source_exp;
        source_diff.avg.pow = (source_exp.avg.pow - source_base.avg.pow) ./ source_base.avg.pow; % = exp/base-1
        
        if ~exist(results{iPart},'dir'), mkdir(results{iPart}); end
        save(fullfile(results{iPart}, ['source_diff_' hh_count2subjectname(iSubj) '_' names{iPart}]), 'source_diff','-v7.3');
    end

                                   
    % Merge the two split datasets via averaging
    disp(['Averaging split trial-averaged datasets of part ' num2str(iPart) '/' num2str(numel(tfrs))])
    cfg                         = [];
    cfg.dirFiles                = results{iPart};
    cfg.saveTo                  = merged{iPart};
    cfg.parameter               = 'avg.pow';
    cfg.merge                   = {[6 7], [10 11]};
    
                                hh_averageSources(cfg);

    % Interpolate merged files to MNI template for plotting, cannot be used
    % for the grand averages (just doesnt work...)
    files = hh_getFilenames(merged{iPart});
    for iFile = 1:12 % actually should be numel(files)
        source_diff = hh_loadData(merged{iPart}, iFile);
        
        cfg_int                     = [];
        cfg_int.downsample          = 1;
        cfg_int.parameter           = 'avg.pow';
        source_diff_int             = ft_sourceinterpolate(cfg_int, source_diff, mri_mni);
        
        if ~exist(merged_int{iPart},'dir'), mkdir(merged_int{iPart}); end
        save(fullfile(merged_int{iPart}, ['source_diff_int_' hh_tue2subjectname(iFile) '_' names{iPart}]), 'source_diff_int','-v7.3');
    end
    
    % Compute Grand Average
    % Generate the grand average (can't just use callFunction because of a
    % fieldtrip bug (I filed it under #2596).
    disp(['Starting grand average of part ' num2str(iPart) '/' num2str(numel(tfrs))])
    files    = hh_getFilenames(merged{iPart});
    counter = 1;
    clear average_this
    for iFile = subjectsToAverage_TUE
        average_this{counter}     = hh_loadData(fullfile(merged{iPart}, files{iFile}));
        counter = counter + 1;
    end
    
    grandavg                    = ft_sourcegrandaverage([], average_this{:});

    cfg_int                      = [];
    cfg_int.downsample           = 1;           % default: 1 (no downsampling)
    cfg_int.parameter            = 'pow';
    grandavg_int                 = ft_sourceinterpolate(cfg_int, grandavg, mri_mni);

    name = ['x_' names{iPart} '_grandaverage_int.mat'];
    save(fullfile(merged_int{iPart}, name),'grandavg_int','-v7.3');
    disp(['Successfully saved ' name '.'])
    clear grandavg grandavg_int

    % Compute NORMALIZED Grand Average
    disp(['Starting normalized grand average of part ' num2str(iPart) '/' num2str(numel(tfrs))])
    files   = hh_getFilenames(merged{iPart});
    
    counter = 1; vector = []; length = [];
    for iFile = 1:numel(average_this)        
        vector                          = reshape(average_this{counter}.avg.pow,[],1);  % transform the power matrix to a 1-column vector
        vector(isnan(vector))           = [];                                           % delete all NaNs
        length                          = norm(vector);                                 % calculate its length
        average_this{counter}.avg.pow   = average_this{counter}.avg.pow / length;       % use the length to normalize the source power
        all_lengths(counter)            = length;                                       % remember the lengths for later use
        counter = counter + 1;
        clear vector length  
    end
    
    grandavg_norm                    = ft_sourcegrandaverage([], average_this{:});
    clear average_this
    
    % Re-multiply the grand average with the average length of all subject vectors
    grandavg_norm.pow                = grandavg_norm.pow .* mean(all_lengths);
    
    % Interpolate the grand average to the mni mri
    cfg_int                      = [];
    cfg_int.downsample           = 1;           % default: 1 (no downsampling)
    cfg_int.parameter            = 'pow';
    grandavg_norm_int            = ft_sourceinterpolate(cfg_int, grandavg_norm, mri_mni);

    name = ['x_' names{iPart} '_grandaverage_normalized_int.mat'];
    save(fullfile(merged_int{iPart}, name),'grandavg_norm_int','-v7.3');
    disp(['Successfully saved ' name '.'])
    clear grandavg_norm grandavg_norm_int all_lengths
end


%% ######       FSDO STARTET UP TO HERE       ###


%% ------     SOURCE STATISTICS - ALL SPINDLES              CLUSTER PERMUTATION                          

dirFiles.FS_base_merged             = fullfile(dirFiles.FS_sources, 'baseline merged');
dirFiles.SSH_base_merged            = fullfile(dirFiles.SSH_sources, 'baseline merged');
dirFiles.SS_base_merged             = fullfile(dirFiles.SS_sources, 'baseline merged');

dirFiles.FS_exp_merged              = fullfile(dirFiles.FS_sources, 'experimental merged');
dirFiles.SSH_exp_merged             = fullfile(dirFiles.SSH_sources, 'experimental merged');
dirFiles.SS_exp_merged              = fullfile(dirFiles.SS_sources, 'experimental merged');

dirFiles.FS_stat                    = fullfile(dirFiles.FS_results, 'cstats merged, wos10');
dirFiles.SSH_stat                   = fullfile(dirFiles.SSH_results, 'cstats merged, wos10');
dirFiles.SS_stat                    = fullfile(dirFiles.SS_results, 'cstats merged, wos10');

dirFiles.FS_stat_int                = fullfile(dirFiles.FS_results, 'cstats merged, wos10, int');
dirFiles.SSH_stat_int               = fullfile(dirFiles.SSH_results, 'cstats merged, wos10, int');
dirFiles.SS_stat_int                = fullfile(dirFiles.SS_results, 'cstats merged, wos10, int');

base_split                          = {dirFiles.FS_base, dirFiles.SSH_base, dirFiles.SS_base};
exp_split                           = {dirFiles.FS_exp, dirFiles.SSH_exp, dirFiles.SS_exp};
base                                = {dirFiles.FS_base_merged,dirFiles.SSH_base_merged, dirFiles.SS_base_merged};
exp                                 = {dirFiles.FS_exp_merged, dirFiles.SSH_exp_merged, dirFiles.SS_exp_merged};
stats                               = {dirFiles.FS_stat, dirFiles.SSH_stat, dirFiles.SS_stat};
stats_int                           = {dirFiles.FS_stat_int, dirFiles.SSH_stat_int, dirFiles.SS_stat_int};

name_suffix                         = {'FS', 'SSH', 'SS'};
calpha                              = {0.05, 0.01, 0.005, 0.001};
subjectsToAnalyze                   = [1 2 3 4 5 6 7 8 9 11 12];    % subset !!

template                            = hh_loadData(fullfile(home,'_fieldtrip','template', 'sourcemodel', ['standard_sourcemodel3d' num2str(gridResolution) 'mm.mat']));
mri_mni                             = ft_read_mri(fullfile(home, '_fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));

% I don't want the split datasets to count twice in the statistics.
% Therefore, first merge the split trial-averaged conditions
% for iPart = 1:numel(exp)
%     disp(['Averaging split trial-averaged datasets of part ' num2str(iPart) '/' num2str(numel(tfrs))])
%     cfg                         = [];
%     cfg.parameter               = 'avg.pow';
%     cfg.merge                   = {[6 7], [10 11]};
%     cfg.dirFiles                = exp_split{iPart};
%     cfg.saveTo                  = exp{iPart};
%     hh_averageSources(cfg);
%                                 
%     cfg.dirFiles                = base_split{iPart};
%     cfg.saveTo                  = base{iPart};
%     hh_averageSources(cfg);
% end

% Do the actual statistics
for iPart = 1:numel(exp)                                                        
    disp(['Starting statistics of part ' num2str(iPart) '/' num2str(numel(exp))])

    % Gather all the source localizations
    cur_base_files                          = hh_getFilenames(base{iPart});
    cur_exp_files                           = hh_getFilenames(exp{iPart});
   
    counter = 1;
    for iSubj = subjectsToAnalyze
        grandAvgBase{counter}               = hh_loadData(fullfile(base{iPart}, cur_base_files{iSubj}));
        grandAvgBase{counter}.pos           = template.pos; % take pos and dim from the MNI template
        grandAvgBase{counter}.dim           = template.dim;

        grandAvgExp{counter}                = hh_loadData(fullfile(exp{iPart}, cur_exp_files{iSubj}));
        grandAvgExp{counter}.pos            = template.pos; % take pos and dim from the MNI template
        grandAvgExp{counter}.dim            = template.dim;
        counter = counter + 1;
    end
    
    for iCalpha = 1:numel(calpha)
        % run statistics over subjects %
        cfg                         = [];
        cfg.dim                     = grandAvgExp{1}.dim;
        cfg.method                  = 'montecarlo';
        cfg.statistic               = 'ft_statfun_depsamplesT';
        cfg.parameter               = 'avg.pow';
        cfg.correctm                = 'cluster';
        cfg.clusterstatistic        = 'maxsum';    % default: maxsum
        cfg.clustertail             = 0;
        cfg.numrandomization        = 1000; % maybe also try 1500?
        cfg.clusteralpha            = calpha{iCalpha};
        cfg.alpha                   = 0.025;
        cfg.tail                    = 0;
        
        nsubj=numel(grandAvgBase);
        cfg.design(1,:)             = [1:nsubj 1:nsubj];
        cfg.design(2,:)             = [ones(1,nsubj) ones(1,nsubj)*2];
        cfg.uvar                    = 1; % row of design matrix that contains unit variable (in this case: subjects)
        cfg.ivar                    = 2; % row of design matrix that contains independent variable (the conditions)
        
        stat                        = ft_sourcestatistics(cfg, grandAvgExp{:}, grandAvgBase{:});
        stat.cfg.previous           = [];
        
        % Save the result (first without interpolating it, which strangely destroyed some fields)
        if ~exist(stats{iPart},'dir'), mkdir(stats{iPart}); end
        name = ['Group stats ' name_suffix{iPart} ' (' cfg.clusterstatistic ', calpha' num2str(cfg.clusteralpha,'%.3f') ', alpha' num2str(cfg.alpha,'%.3f') ', nrands' num2str(cfg.numrandomization) ').mat'];
        save(fullfile(stats{iPart}, name),'stat','-v7.3');
        disp(['Stats successfully saved to ' name '.'])
        
        % Interpolate the results and save as well
        cfg_int                     = [];
        cfg_int.parameter           = 'all';
        stat_int                    = ft_sourceinterpolate(cfg_int, stat, mri_mni);
        
        if ~exist(stats_int{iPart},'dir'), mkdir(stats_int{iPart}); end
        name = ['Group stats ' name_suffix{iPart} ' (' cfg.clusterstatistic ', calpha' num2str(cfg.clusteralpha,'%.3f') ', alpha' num2str(cfg.alpha,'%.3f') ', nrands' num2str(cfg.numrandomization) ') - int.mat'];
        save(fullfile(stats_int{iPart}, name),'stat_int','-v7.3');
        disp(['MNI-interpolated stats successfully saved to ' name '.'])
        clear stat stat_int
    end
    clear name cur_base_files cur_exp_files grandAvgExp grandAvgBase
end


%% ------     SOURCE STATISTICS - ALL SPINDLES              CLUSTER PERMUTATION incl. NORMALIZATION                            

% dirFiles.FS_stat_norm              = fullfile(dirFiles.FS_results, 'cstats merged, wos10, norm');
% dirFiles.SSH_stat_norm             = fullfile(dirFiles.SSH_results, 'cstats merged, wos10, norm');
% dirFiles.SS_stat_norm              = fullfile(dirFiles.SS_results, 'cstats merged, wos10, norm');

dirFiles.FS_stat_norm_int          = fullfile(dirFiles.FS_results, 'cstats merged, wos10, norm, int');
dirFiles.SSH_stat_norm_int         = fullfile(dirFiles.SSH_results, 'cstats merged, wos10, norm, int');
dirFiles.SS_stat_norm_int          = fullfile(dirFiles.SS_results, 'cstats merged, wos10, norm, int');

base                               = {dirFiles.FS_base_merged,  dirFiles.SSH_base_merged, dirFiles.SS_base_merged};
exp                                = {dirFiles.FS_exp_merged, dirFiles.SSH_exp_merged, dirFiles.SS_exp_merged};
% stats                              = {dirFiles.FS_stat_norm, dirFiles.SSH_stat_norm, dirFiles.SS_stat_norm};
stats_int                          = {dirFiles.FS_stat_norm_int, dirFiles.SSH_stat_norm_int, dirFiles.SS_stat_norm_int};

name_suffix                           = {'FS', 'SSH', 'SS'};
calpha                                = {0.05, 0.01, 0.005, 0.001};
subjectsToAnalyze                     = [1 2 3 4 5 6 7 8 9 11 12];    % subset !!

template                              = hh_loadData(fullfile(home,'_fieldtrip','template', 'sourcemodel', ['standard_sourcemodel3d' num2str(gridResolution) 'mm.mat']));
mri_mni                               = ft_read_mri(fullfile(home, '_fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));

for iPart = 1:numel(exp)                                                        
    disp(['Starting normalized statistics of part ' num2str(iPart) '/' num2str(numel(exp))])

    % Gather all the source localizations
    cur_base_files                          = hh_getFilenames(base{iPart});
    cur_exp_files                           = hh_getFilenames(exp{iPart});
   
    counter = 1;
    for iSubj = subjectsToAnalyze
        grandAvgBase{counter}               = hh_loadData(fullfile(base{iPart}, cur_base_files{iSubj}));
        grandAvgBase{counter}.pos           = template.pos; % take pos and dim from the MNI template
        grandAvgBase{counter}.dim           = template.dim;
        vector                              = grandAvgBase{counter}.avg.pow;
        
        grandAvgExp{counter}                = hh_loadData(fullfile(exp{iPart}, cur_exp_files{iSubj}));
        grandAvgExp{counter}.pos            = template.pos; % take pos and dim from the MNI template
        grandAvgExp{counter}.dim            = template.dim;
        vector                              = [grandAvgExp{counter}.avg.pow; vector];
        
        vector(isnan(vector))               = [];                                           % delete all NaNs
        vec_length                          = norm(vector);                                 % calculate its length
        grandAvgExp{counter}.avg.pow        = grandAvgExp{counter}.avg.pow / vec_length;        % use the length to normalize the source power
        grandAvgBase{counter}.avg.pow       = grandAvgBase{counter}.avg.pow / vec_length;
        clear vector vec_length
        
        counter = counter + 1;
    end
    
    for iCalpha = 1:numel(calpha)
        cfg                         = [];
        cfg.dim                     = grandAvgExp{1}.dim;
        cfg.method                  = 'montecarlo';
        cfg.statistic               = 'ft_statfun_depsamplesT';
        cfg.parameter               = 'avg.pow';
        cfg.correctm                = 'cluster';
        cfg.clusterstatistic        = 'maxsum';    % default: maxsum
        cfg.clustertail             = 0;
        cfg.numrandomization        = 1200; % maybe also try 1500?
        cfg.clusteralpha            = calpha{iCalpha};
        cfg.alpha                   = 0.025;
        cfg.tail                    = 0;
        
        nsubj=numel(grandAvgBase);
        cfg.design(1,:)             = [1:nsubj 1:nsubj];
        cfg.design(2,:)             = [ones(1,nsubj) ones(1,nsubj)*2];
        cfg.uvar                    = 1; % row of design matrix that contains unit variable (in this case: subjects)
        cfg.ivar                    = 2; % row of design matrix that contains independent variable (the conditions)
        
        stat                        = ft_sourcestatistics(cfg, grandAvgExp{:}, grandAvgBase{:});
        stat.cfg.previous           = [];
        
        % Save the result (first without interpolating it, which strangely destroyed some fields)
        %         if ~exist(stats{iPart},'dir'), mkdir(stats{iPart}); end
        %         name = ['Group stats ' name_suffix{iPart} ' (' cfg.clusterstatistic ', calpha' num2str(cfg.clusteralpha,'%.3f') ', alpha' num2str(cfg.alpha,'%.3f') ', nrands' num2str(cfg.numrandomization) ').mat'];
        %         save(fullfile(stats{iPart}, name),'stat','-v7.3');
        %         disp(['Stats successfully saved to ' name '.'])
        
        % Interpolate the results and save as well
        cfg_int                     = [];
        cfg_int.parameter           = 'all';
        stat_int                    = ft_sourceinterpolate(cfg_int, stat, mri_mni);
        
        if ~exist(stats_int{iPart},'dir'), mkdir(stats_int{iPart}); end
        name = ['Group stats ' name_suffix{iPart} ' (' cfg.clusterstatistic ', calpha' num2str(cfg.clusteralpha,'%.3f') ', alpha' num2str(cfg.alpha,'%.3f') ', nrands' num2str(cfg.numrandomization) ') - normed, int.mat'];
        save(fullfile(stats_int{iPart}, name),'stat_int','-v7.3');
        disp(['Normalized MNI-interpolated stats successfully saved to ' name '.'])
        clear stat stat_int
    end
    clear name cur_base_files cur_exp_files
    
    clear grandAvgExp grandAvgBase
end


%% ------     SOURCE STATISTICS - ALL SPINDLES              SINGLE SUBJECTS - WAS NOT CALCULATED DUE TO FILE SIZE


%% ------     PLOTTING: NEW GRAND AVERAGE + STATISTICS      UNNORMED
% Best done locally with Matlab 2014b or higher
colorlimits                     = [-0.8 0.8];
plotTfrNum                      = 13; % file number the interpolated grand average
dir_tfr                         = {dirFiles.FS_merged_int, dirFiles.SSH_merged_int, dirFiles.SS_merged_int};
dir_stats                       = {dirFiles.FS_stat_int, dirFiles.SSH_stat_int, dirFiles.SS_stat_int};
plot_version                    = 'v1.5 local unnormed cmap5';
cmap                            = hh_loadData(fullfile(home,'data','meta','cmap5.mat'));

% -----   SURFACE   -----
cfg                             = [];
cfg.method                      = 'surface';
cfg.funparameter                = 'pow';
% cfg.maskparameter               = cfg.funparameter;
cfg.funcolormap                 = cmap;
%cfg.opacitymap                  = 'auto';  
cfg.projmethod                  = 'nearest'; 
cfg.surfdownsample              = 5; 
cfg.savePNG                     = true;
cfg.saveFIG                     = false;
cfg.setPosition                 = [50 100 1400 1050];
cfg.funcolorlim                 = colorlimits;
cfg.doSelfMasking               = 'yes'; % 'yes' multiplies mask with data (needed when using a mask + opacity)

cfg.atlas                       = fullfile(home, '_fieldtrip','template','atlas','aal','ROI_MNI_V4.nii');
cfg.roi                         = labels_cerebrum_reduced;
cfg.addCoordsys                 = 'mni';        % setting for hh_plotSource

% Loop automatically handling most types of input
for iPart = 1:numel(dir_tfr)
    files_tfr = hh_getFilenames(dir_tfr{iPart});
    for iTfr = plotTfrNum
        noStats = numel(hh_getFilenames(dir_stats{iPart}));
        for iStats = 1:noStats+1
            cfg_temp = cfg;
            if iStats == noStats+1  % plot one version without stat and atlas
                if isfield(cfg_temp, 'atlas'), cfg_temp = rmfield(cfg_temp, 'atlas'); end
                if isfield(cfg_temp, 'roi'), cfg_temp = rmfield(cfg_temp, 'roi'); end
                if isfield(cfg_temp, 'useMaskData'), cfg_temp = rmfield(cfg_temp, 'useMaskData'); end
                if isfield(cfg_temp, 'doSelfMasking'), cfg_temp = rmfield(cfg_temp, 'doSelfMasking'); end
                if isfield(cfg_temp, 'funcolorlim')
                    cfg_temp.saveTo          = ['plots GA, ' num2str(cfg_temp.funcolorlim(1)) ' ' num2str(cfg_temp.funcolorlim(2)) ', no stats, no atlas, ' plot_version ' - '   cfg_temp.method];
                else
                    cfg_temp.saveTo          = ['plots GA, auto scaling, no stats, no atlas, ' plot_version ' - '   cfg_temp.method];
                end
            else
                cfg_temp.useMaskData    = hh_loadData(dir_stats{iPart}, iStats);
                if isfield(cfg_temp, 'funcolorlim')
                    cfg_temp.saveTo          = ['plots GA, ' num2str(cfg_temp.funcolorlim(1)) ' ' num2str(cfg_temp.funcolorlim(2)) ', cl stats, p' num2str(cfg_temp.useMaskData.cfg.previous{1}.clusteralpha,'%.3f') ', ' plot_version ' - '   cfg_temp.method];
                else
                    cfg_temp.saveTo          = ['plots GA, auto scaling, cl stats, p' num2str(cfg_temp.useMaskData.cfg.previous{1}.clusteralpha,'%.3f') ', ' plot_version ' - '   cfg_temp.method];
                end
            end
            
            close all
            hh_callFunction('hh_plotSource', cfg_temp, dir_tfr{iPart}, iTfr);
        end
    end
end

  
% -----   SLICE   -----
cfg                             = [];
cfg.method                      = 'slice';
cfg.funparameter                = 'pow';
cfg.maskparameter               = cfg.funparameter;
cfg.funcolormap                 = cmap;
cfg.slicerange                  = [35 142];     % if not downsampled: [35 142]
cfg.nslices                     = 12;
cfg.opacitymap                  = vdown_edit;
cfg.savePNG                     = 'true';
cfg.saveFIG                     = 'true';
cfg.setPosition                 = [50 100 1400 1050];
cfg.funcolorlim                 = colorlimits;
cfg.doSelfMasking               = 'no'; % 'yes' multiplies mask with  data (needed when using a mask + opacity)

dir_stats                       = [];

% This is the loop version for non-stat, no-atlas plotting
for iPart = 1:numel(dir_tfr)
    files_tfr = hh_getFilenames(dir_tfr{iPart});
    for iTfr = plotTfrNum
        cfg_temp = cfg;
        if isfield(cfg_temp, 'funcolorlim')
            cfg_temp.saveTo          = ['plots GA, ' num2str(cfg_temp.funcolorlim(1)) ' ' num2str(cfg_temp.funcolorlim(2)) ', no stats, no atlas, ' plot_version ' - '   cfg_temp.method];
        else
            cfg_temp.saveTo          = ['plots GA, auto scaling, no stats, no atlas, ' plot_version ' - '   cfg_temp.method];
        end
        close all
        hh_callFunction('hh_plotSource', cfg_temp, dir_tfr{iPart}, iTfr);
    end
end


%% ------     PLOTTING: NEW GRAND AVERAGE + STATISTICS      NORMED
% Best done locally with Matlab 2014b or higher
colorlimits                     = [-1.1 1.1];
plotTfrNum                      = 14; % file number the interpolated grand average
dir_tfr                         = {dirFiles.FS_merged_int, dirFiles.SSH_merged_int, dirFiles.SS_merged_int};
dir_stats                       = {dirFiles.FS_stat_norm_int, dirFiles.SSH_stat_norm_int, dirFiles.SS_stat_norm_int};
plot_version                    = 'v1.5 local normed cmap5';
cmap                            = hh_loadData(fullfile(home,'data','meta','cmap5.mat'));

% -----   SURFACE   -----
cfg                             = [];
cfg.method                      = 'surface';
cfg.funparameter                = 'pow';
% cfg.maskparameter               = cfg.funparameter;
cfg.funcolormap                 = cmap;
%cfg.opacitymap                  = 'auto';  
cfg.projmethod                  = 'nearest'; 
cfg.surfdownsample              = 5; 
cfg.savePNG                     = true;
cfg.saveFIG                     = false;
cfg.setPosition                 = [50 100 1400 1050];
cfg.funcolorlim                 = colorlimits;
cfg.doSelfMasking               = 'yes'; % 'yes' multiplies mask with data (needed when using a mask + opacity)

cfg.atlas                       = fullfile(home, '_fieldtrip','template','atlas','aal','ROI_MNI_V4.nii');
cfg.roi                         = labels_cerebrum_reduced;
cfg.addCoordsys                 = 'mni';        % setting for hh_plotSource

% Loop automatically handling most types of input
for iPart = 1:numel(dir_tfr)
    
    files_tfr = hh_getFilenames(dir_tfr{iPart});
    
    for iTfr = plotTfrNum
        noStats = numel(hh_getFilenames(dir_stats{iPart}));
        for iStats = 1:noStats+1
            cfg_temp = cfg;
            if iStats == noStats+1  % plot one version without stat and atlas
                if isfield(cfg_temp, 'atlas'), cfg_temp = rmfield(cfg_temp, 'atlas'); end
                if isfield(cfg_temp, 'roi'), cfg_temp = rmfield(cfg_temp, 'roi'); end
                if isfield(cfg_temp, 'useMaskData'), cfg_temp = rmfield(cfg_temp, 'useMaskData'); end
                if isfield(cfg_temp, 'doSelfMasking'), cfg_temp = rmfield(cfg_temp, 'doSelfMasking'); end
                if isfield(cfg_temp, 'funcolorlim')
                    cfg_temp.saveTo          = ['plots GA, ' num2str(cfg_temp.funcolorlim(1)) ' ' num2str(cfg_temp.funcolorlim(2)) ', no stats, no atlas, ' plot_version ' - '   cfg_temp.method];
                else
                    cfg_temp.saveTo          = ['plots GA, auto scaling, no stats, no atlas, ' plot_version ' - '   cfg_temp.method];
                end
            else
                cfg_temp.useMaskData    = hh_loadData(dir_stats{iPart}, iStats);
                if isfield(cfg_temp, 'funcolorlim')
                    cfg_temp.saveTo          = ['plots GA, ' num2str(cfg_temp.funcolorlim(1)) ' ' num2str(cfg_temp.funcolorlim(2)) ', cl stats, p' num2str(cfg_temp.useMaskData.cfg.previous{1}.clusteralpha,'%.3f') ', ' plot_version ' - '   cfg_temp.method];
                else
                    cfg_temp.saveTo          = ['plots GA, auto scaling, cl stats, p' num2str(cfg_temp.useMaskData.cfg.previous{1}.clusteralpha,'%.3f') ', ' plot_version ' - '   cfg_temp.method];
                end
            end
            
            close all
            hh_callFunction('hh_plotSource', cfg_temp, dir_tfr{iPart}, iTfr);
        end
    end
end

  
% -----   SLICE   -----
cfg                             = [];
cfg.method                      = 'slice';
cfg.funparameter                = 'pow';
cfg.maskparameter               = cfg.funparameter;
cfg.funcolormap                 = cmap;
cfg.slicerange                  = [35 142];     % if not downsampled: [35 142]
cfg.nslices                     = 12;
cfg.opacitymap                  = vdown_edit;
cfg.savePNG                     = 'true';
cfg.saveFIG                     = 'true';
cfg.setPosition                 = [50 100 1400 1050];
cfg.funcolorlim                 = colorlimits;
cfg.doSelfMasking               = 'no'; % 'yes' multiplies mask with  data (needed when using a mask + opacity)

dir_stats                       = [];

% This is the loop version for non-stat, no-atlas plotting
for iPart = 1:numel(dir_tfr)
    files_tfr = hh_getFilenames(dir_tfr{iPart});
    for iTfr = plotTfrNum
        cfg_temp = cfg;
        if isfield(cfg_temp, 'funcolorlim')
            cfg_temp.saveTo          = ['plots GA, ' num2str(cfg_temp.funcolorlim(1)) ' ' num2str(cfg_temp.funcolorlim(2)) ', no stats, no atlas, ' plot_version ' - '   cfg_temp.method];
        else
            cfg_temp.saveTo          = ['plots GA, auto scaling, no stats, no atlas, ' plot_version ' - '   cfg_temp.method];
        end
        close all
        hh_callFunction('hh_plotSource', cfg_temp, dir_tfr{iPart}, iTfr);
    end
end


%% ------     SAVE DIR LOCATIONS    

hh_save(dirFiles);


%% ######     REWRITTEN UNTIL HERE
%% ######     RUN UNTIL HERE

                                
%% ------     PLOTTING: STATISTICS        

% ----- Slice

cfg                         = [];
cfg.method                  = 'slice';
cfg.funparameter            = 'stat';
cfg.maskparameter           = 'mask';
cfg.funcolormap             = 'jet';
cfg.funcolorlim             = [-10 10];
cfg.saveTo                  = ['plots slice ' num2str(cfg.funcolorlim(1)) ' ' num2str(cfg.funcolorlim(2))];
cfg.slicerange              = [35 142];     % if not downsampled: [35 142]
cfg.nslices                 = 12;    
cfg.setPosition             = [50 100 1400 1050];
cfg.saveFIG                 = true;
cfg.savePNG                 = true;

                            hh_callFunction('hh_plotSource', cfg, dirFiles.FS_stat, [1 3 5]);
                            hh_callFunction('hh_plotSource', cfg, dirFiles.SSH_stat, [1 3 5]);
                            hh_callFunction('hh_plotSource', cfg, dirFiles.SS_stat, [1 3 5]);
                            
                            hh_callFunction('hh_plotSource', cfg, dirFiles.FS_statfdr, [1]);
                            hh_callFunction('hh_plotSource', cfg, dirFiles.SSH_statfdr, [1]);
                            hh_callFunction('hh_plotSource', cfg, dirFiles.SS_statfdr, [1]);

                            hh_callFunction('hh_plotSource', cfg, dirFiles.FS_stat_nmps);
                            hh_callFunction('hh_plotSource', cfg, dirFiles.SSH_stat_nmps);                            

                            
% ----- Surface

cfg                         = [];
cfg.method                  = 'surface';
cfg.surfdownsample          = 5;
cfg.funparameter            = 'stat';
cfg.maskparameter           = 'mask';
cfg.funcolormap             = 'jet';
cfg.funcolorlim             = [-10 10];
cfg.saveTo                  = ['plots surface ' num2str(cfg.funcolorlim(1)) ' ' num2str(cfg.funcolorlim(2))];
cfg.setPosition             = [50 100 1400 1050];
cfg.saveFIG                 = true;
cfg.savePNG                 = true;

                            hh_callFunction('hh_plotSource', cfg, dirFiles.FS_stat, [1 3 5]);   % [1 3 5]
                            hh_callFunction('hh_plotSource', cfg, dirFiles.SSH_stat, [1 3 5]);
                            hh_callFunction('hh_plotSource', cfg, dirFiles.SS_stat, [1 3 5]);
                            
                            hh_callFunction('hh_plotSource', cfg, dirFiles.FS_statfdr);   % [1 3 5]
                            hh_callFunction('hh_plotSource', cfg, dirFiles.SSH_statfdr);
                            hh_callFunction('hh_plotSource', cfg, dirFiles.SS_statfdr);




%% ------     FURTHER COMMENTS      
%
% ---  Masking source plots
% Use ft_volumelookup manually to create a mask for sourceplotting;
% cfg                             = [];
% cfg.inputcoord                  = 'mni';
% cfg.atlas                      = fullfile(home, '_fieldtrip','template','atlas','aal','ROI_MNI_V4.nii');
% % cfg.roi                         = {'ParaHippocampal_L';'ParaHippocampal_R'};
% cfg.roi                         = {'Supp_Motor_Area_L';'Supp_Motor_Area_R'};
% mask                            = ft_volumelookup(cfg,source);
% source.mask                     = mask;
%
%
% ---  Time-Frequency Analysis
%
% The spectral bandwidth at a given frequency F is equal to F/cycles*2
% (so, at 30 Hz and a width of 7, the spectral bandwidth is (30/7)*2 =
% 8.6 Hz) while the wavelet duration is equal to width/F/pi (in this
% case, 7/30/pi = 0.074s = 74ms; (for a hanning window with a fixed
% window length it would be 1/length in seconds).
% [taken from fieldtrip website]
%
%
% ---  Time-Frequency Plots - Z Limits
%
% 05 - 20 Hz:   GrandAvg       [0.80 1.65]
%               SinglePlots    [0.70 1.65]
% 20 - 45 Hz:   GrandAvg       [0.70 1.30]
%               SinglePlots    [0.70 1.30]
% 55 - 80 Hz:   GrandAvg       [0.90 1.10]
%               SinglePlots    [0.80 1.20]
% 80 - 140 Hz:  GrandAvg       [0.90 1.10]
%               SinglePlots    [0.85 1.15]
% 55 - 140 Hz:  GrandAvg       [0.90 1.10]
%               SinglePlots    [0.80 1.20]
% 05 - 140 Hz:  GrandAvg       [0.90 1.30]
%               SinglePlots    [0.85 1.30]
%
%
% ---  Head movements
%
% The second way of dealing with the movements means that you perform
% ft_timelockanalysis, ft_freqanalysis or ft_sourceanalysis with the option
% keeptrials=yes. This will give trial estimates of the ERF, the power or
% the source strength for each trial. The effect that the variable head
% position has on those single-trial estimates can be estimated and removed
% from the data using ft_regressconfound. This method has been found to
% significantly improve statistical sensivity following head movements, up
% to 30%, and is therefore demonstrated in the second half of the example
% script. The third way of dealing with the movements requires that you
% make a apatial interpolation of the raw MEG data at each moment in time,
% in which you correct for the movements. In principle this could be done
% using the ft_megrealign function, but at this moment (May 2012) that
% function cannot yet deal with within-session movements. The fourth way of
% dealing with the movements is implemented in the ft_headmovement
% function. It is not explained in further detail on this example page.
% Text taken from fieldtrip:
% http://fieldtrip.fcdonders.nl/example/how_to_incorporate_head_movements_in_meg_analysis
%
% Head Movements - HLC channels:
% HLC00n1 X coordinate relative to the dewar (in meters) of the nth head localization coil
% HLC00n2 Y coordinate relative to the dewar (in meters) of the nth head localization coil
% HLC00n3 Z coordinate relative to the dewar (in meters) of the nth head localization coil
%
% Headmovement clustering algorithm (ft_headmovement)
% Number of clusters to find; for three recordings it was not possible to
% find more than 1 cluster; ft_headmovement eliminated all head positions
% below a certain threshold and none or only one was left. I am not
% e3xactly sure what the function did there, but running ft_headmovement
% led to an error I could not resolve. In general it is good to know that
% the clustering algorithm (k-mneans) is not deterministic and may loose
% all clusters in the very beginning. This leads to an error and the
% function has to be started again. Usually it works the second time.
%
%
% ---  Planar Gradients
%
% Strictly speaking, planar gradient transformation is not necessary, so
% you can just skip those steps if you really want to. However, if you have
% axial gradiometer data (as I seem to recall from your earlier posts) and
% want to do TF-analysis and -statistics on sensor level, I would strongly
% recommend applying a planar gradient transformation. Axial gradiometer
% data will produce maximal deflections (of opposite polarity) on both
% sides of a current dipole, while planar gradiometer data produces a
% positive maximum exactly above the source. If you apply TF-analysis to
% axial gradiometer data, you will get two spatially separated 'blobs'
% where there was only a single oscillating dipole in the brain. If you
% look at power (as is typically done), you will lose the polarity
% information, and hence interpreting the power topography in terms of
% brain is nearly impossible with axial gradient data.
% (taken from the fieldtrip mailinglist)
%
% Templates for defining neighbouring channels
% http://fieldtrip.fcdonders.nl/template/neighbours
%
%
% ---  Realigning and co-registrating MRI scans
%
% To visualize an MRI image, read it in using ft_read_mri and plot it using
% cfg=[]; cfg.interactive='yes'; ft_sourceplot(cfg,ft_read_mri(sd{i}.MRIfile)
%
% To visualize the segmented MRI:
% cfg=[]; cfg.interactive='yes'; cfg.funparameter='gray'; ft_sourceplot(cfg, segmentedmri)
%
% To check whether the segmentation fits into the original mri, attach it
% to the segmentation:
% segmentedmri.anatomy   = mri_re.anatomy;
% segmentedmri.transform = mri_re.transform;
% ...and then plot it as usual:
% cfg=[]; cfg.interactive='yes'; cfg.funparameter='gray'; ft_sourceplot(cfg, segmentedmri)
%
% To visualize a headmodel together with the sensors use:
% ft_plot_vol(vol); ft_plot_sens(grad)
%
% To plot headmodel, grid, and channels together:
% vol = ft_convert_units(vol, 'cm');
% figure; hold on
% ft_plot_vol(vol, 'edgecolor', 'none')
% alpha 0.4           % make the surface transparent
% ft_plot_mesh(sourcemodel.pos(sourcemodel.inside,:));
% ft_plot_sens(grad);
%
% To manually specify the fiducials in the MRI use ft_volumerealign:
% i = 3;
% cfg = [];
% cfg.method = 'interactive';
% cfg.snapshotfile = fullfile(home,'data','realigned mri','snapshots',sd{i}.subjectname);
% cfg.outputfile =  fullfile(home,'data','realigned mri',sd{i}.subjectname);
% ft_volumerealign(cfg,ft_read_mri(sd{i}.MRIfile))
%
% To re-specify axes of the coordinate system use:
% ft_determine_coordsys
%
% Fieldtrip documentation: 
% http://fieldtrip.fcdonders.nl/faq/how_are_the_different_head_and_mri_coordinate_systems_defined
% http://fieldtrip.fcdonders.nl/tutorial/headmodel_meg
% http://fieldtrip.fcdonders.nl/faq/how_are_the_lpa_and_rpa_points_defined
%
%
% ---  Leadfield and Sourcemodel preparation
%
% The fieldtrip website offers two tutorials on beamforming. In the simpler
% one, ft_prepare_leadfield ist just called with some parameters how to
% generate a sourcemodel/grid. For each of these grid points, a leadfield
% will be created.
% http://fieldtrip.fcdonders.nl/tutorial/beamformer
% However, in the more elaborate tutorial a sourcemodel is created by hand
% and then used as an input parameter cfg.grid when ft_prepare_leadfield is
% called
% http://fieldtrip.fcdonders.nl/tutorial/beamformingextended
%
%
% ---  DICS beamforming
%
% Using a comman spatial filter:
% Some things have to be changed in hh_doPreprocessing if two conditions
% are to be contrasted. See 
% http://fieldtrip.fcdonders.nl/example/common_filters_in_beamforming
%
% Using a real-valued filter:
% For a discussion on whether spatial filters should be real- or
% complex-valued see:
% http://mailman.science.ru.nl/pipermail/fieldtrip/2012-September/005691.html
%
% Averaging over trials
% ft_sourceanalysis, although constructing the spatial filter from all
% trials, calculates the source after averaging over all trials. It does
% not perform beamforming on all trials and averages the result. The later
% behavior can be done by choosing the option rawtrials = 'yes'.



%% ------------------------     OLD     ------------------------  
%                             
% %% ------     REDEFINE TRIALS   
% 
% FS                          = 'fast spindles';
% dirFiles.FS                 = fullfile(dirFiles.home, FS);
% 
% SS                          = 'slow spindles';
% SSbaseline                  = 'slow spindles baseline';
% dirFiles.SSbaseline         = fullfile(dirFiles.home, SSbaseline);
% dirFiles.SS                 = fullfile(dirFiles.home, SS);
% 
% cfg                         = [];  
% 
% 
% % ---  Fast spindles
% 
% cfg.toilim                  = FStime;        %  Time should be: full cycles / freq !!
% cfg.saveTo                  = dirFiles.FS;
% 
%                             hh_callFunction('ft_redefinetrial',cfg, dirFiles.clean);
%                                          
% cfg.toilim                  = FSbaselineTime;                       
% cfg.saveTo                  = dirFiles.FSbaseline;
% 
%                             hh_callFunction('ft_redefinetrial',cfg, dirFiles.clean);
%                             
%                         
% % ---  Slow spindles
% 
% cfg.toilim                  = SStime;      
% cfg.saveTo                  = dirFiles.SS;
% 
%                             hh_callFunction('ft_redefinetrial',cfg, dirFiles.clean);
% 
% cfg.toilim                  = SSbaselineTime; 
% cfg.saveTo                  = dirFiles.SSbaseline;
% 
%                             hh_callFunction('ft_redefinetrial',cfg, dirFiles.clean);
%                           
%                             
% %% ------     TIME-FREQUENCY ANALYSIS 1 - SEPARATE CONDITIONS   
% % ... to get the cross-spectral density matrix
% 
% cfg                         = [];
% cfg.method                  = 'mtmfft';    % Morlet wavelet
% cfg.output                  = 'powandcsd';
% 
% 
% % ---  Fast spindles
% 
% cfg.foilim                  = FSfreq;
% cfg.tapsmofrq               = FSfreqband;          % +/- how many Hz
% 
% dirFiles.FSbaseline_TFR     = hh_callFunction('ft_freqanalysis', cfg, dirFiles.FSbaseline);
% dirFiles.FS_TFR             = hh_callFunction('ft_freqanalysis', cfg, dirFiles.FS);
% 
% 
% % ---  Slow spindles
% 
% cfg.foilim                  = SSfreq;
% cfg.tapsmofrq               = SSfreqband; 
% 
% dirFiles.SSbaseline_TFR     = hh_callFunction('ft_freqanalysis', cfg, dirFiles.SSbaseline);
% dirFiles.SS_TFR             = hh_callFunction('ft_freqanalysis', cfg, dirFiles.SS);                       
%  
% 
% %% ------     TIME-FREQUENCY ANALYSIS 2 - COMBINED CONDITIONS   
% % ... to later construct a common spatial filter
% % see http://fieldtrip.fcdonders.nl/example/common_filters_in_beamforming
% 
% % Append data for each condition
% dirFiles.FScombined = fullfile(dirFiles.home, 'fast spindles combined');
% dirFiles.SScombined = fullfile(dirFiles.home, 'slow spindles combined');
% 
% hh_appendFolders(dirFiles.FSbaseline, dirFiles.FS, dirFiles.FScombined);
% hh_appendFolders(dirFiles.SSbaseline, dirFiles.SS, dirFiles.SScombined);
% 
% % Comput another time-frequency analysis with baseline and experimental
% % condition combined -- needed to build a common spatial filter
% cfg                         = [];
% cfg.method                  = 'mtmfft';    % Morlet wavelet
% cfg.output                  = 'powandcsd';
% 
% % Fast spindles:
% cfg.foilim                  = FSfreq;
% cfg.tapsmofrq               = FSfreqband;          % +/- how many Hz
% 
% dirFiles.FScombined_TFR     = hh_callFunction('ft_freqanalysis', cfg, dirFiles.FScombined);
% 
% % Slow spindles:
% cfg.foilim                  = SSfreq;
% cfg.tapsmofrq               = SSfreqband; 
% 
% dirFiles.SScombined_TFR     = hh_callFunction('ft_freqanalysis', cfg, dirFiles.SScombined);



%% ------     X SOURCE STATISTICS - FAST SPINDLES                     - FDR analytic      

name_suffix                     = '_FS';
dirFiles.FS_statfdr             = fullfile(dirFiles.FS_results, 'stats (merged, subset wos10) fdr');
template                        = hh_loadData(fullfile(home,'_fieldtrip','template', 'sourcemodel', ['standard_sourcemodel3d' num2str(gridResolution) 'mm.mat']));

% Gather all the source localizations
fileList.FS_exp                 = hh_getFilenames(dirFiles.FS_exp);
fileList.FS_base                = hh_getFilenames(dirFiles.FS_base);

subjectsToAnalyze               = [1 2 3 4 5 6 7 8 9 11 12];    % subset, without s10 !!

counter = 1; 
for iSubj = subjectsToAnalyze
   grandAvgBase{counter}            = hh_loadData(fullfile(dirFiles.FS_base, fileList.FS_base{iSubj}));
   grandAvgBase{counter}.pos        = template.pos; % take pos and dim from the MNI template
   grandAvgBase{counter}.dim        = template.dim;
   counter = counter + 1;
end

counter = 1; 
for iSubj = subjectsToAnalyze
   grandAvgExp{counter}            = hh_loadData(fullfile(dirFiles.FS_exp, fileList.FS_exp{iSubj}));
   grandAvgExp{counter}.pos        = template.pos; % take pos and dim from the MNI template
   grandAvgExp{counter}.dim        = template.dim;
   counter = counter + 1;
end

% run statistics over subjects %
cfg                         = [];
cfg.dim                     = grandAvgExp{1}.dim;
cfg.method                  = 'analytic';
cfg.statistic               = 'ft_statfun_depsamplesT';
cfg.parameter               = 'avg.pow';
cfg.correctm                = 'fdr';
cfg.correcttail             = 'alpha';  % corrects for two tails
cfg.alpha                   = 0.01;
cfg.tail                    = 0;

nsubj=numel(grandAvgBase);
cfg.design(1,:)             = [1:nsubj 1:nsubj];
cfg.design(2,:)             = [ones(1,nsubj) ones(1,nsubj)*2];
cfg.uvar                    = 1; % row of design matrix that contains unit variable (in this case: subjects)
cfg.ivar                    = 2; % row of design matrix that contains independent variable (the conditions)

stat                        = ft_sourcestatistics(cfg, grandAvgExp{:}, grandAvgBase{:});

clear grandAvgExp grandAvgBase

% Save the result (first without interpolating it which destroyed some
% fields)
% if ~exist(dirFiles.FS_stat,'dir'), mkdir(dirFiles.FS_stat); end
% name = ['Statistics - group level (cstats ' cfg.clusterstatistic ', calpha' num2str(cfg.clusteralpha) ', alpha' num2str(cfg.alpha) ', nrands' num2str(cfg.numrandomization) ').mat'];
% save(fullfile(dirFiles.FS_stat, name),'stat','-v7.3');
% disp(['Stats successfully saved to ' name '.'])

% Interpolate the results and save as well
cfg_int                     = [];
cfg_int.parameter           = 'all';
stat_mni                    = ft_sourceinterpolate(cfg_int, stat, mri_mni);

% One could delete stat_mni.cfg.previous here to save 95 % of the disk
% space and loading time.

name = ['Group stats ' name_suffix ' (FDRanl, alpha' num2str(cfg.alpha) ') - interp.mat'];
if ~exist(dirFiles.FS_statfdr,'dir'), mkdir(dirFiles.FS_statfdr); end
save(fullfile(dirFiles.FS_statfdr, name),'stat_mni','-v7.3');
disp(['Interpolated stats successfully saved to ' name '.'])
    
clear stat stat_mni name


%% ------     X SOURCE STATISTICS - SLOW SPINDLES 10 Hz               - FDR analytic             

name_suffix                         = '_SSH';
dirFiles.SSH_statfdr                = fullfile(dirFiles.SSH_results, 'stats (merged, subset wos10) fdr');
template                            = hh_loadData(fullfile(home,'_fieldtrip','template', 'sourcemodel', ['standard_sourcemodel3d' num2str(gridResolution) 'mm.mat']));

% Gather all the source localizations
fileList.SSH_exp                    = hh_getFilenames(dirFiles.SSH_exp);
fileList.SSH_base                   = hh_getFilenames(dirFiles.SSH_base);

subjectsToAnalyze                   = [1 2 3 4 5 6 7 8 9 11 12];        % subset !!

counter = 1; 
for iSubj = subjectsToAnalyze
   grandAvgBase{counter}            = hh_loadData(fullfile(dirFiles.SSH_base, fileList.SSH_base{iSubj}));
   grandAvgBase{counter}.pos        = template.pos; % take pos and dim from the MNI template
   grandAvgBase{counter}.dim        = template.dim;
   counter = counter + 1;
end

counter = 1; 
for iSubj = subjectsToAnalyze
   grandAvgExp{counter}            = hh_loadData(fullfile(dirFiles.SSH_exp, fileList.SSH_exp{iSubj}));
   grandAvgExp{counter}.pos        = template.pos; % take pos and dim from the MNI template
   grandAvgExp{counter}.dim        = template.dim;
   counter = counter + 1;
end

% run statistics over subjects %
cfg                         = [];
cfg.dim                     = grandAvgExp{1}.dim;
cfg.method                  = 'analytic';
cfg.statistic               = 'ft_statfun_depsamplesT';
cfg.parameter               = 'avg.pow';
cfg.correctm                = 'fdr';
cfg.correcttail             = 'alpha';  % corrects for two tails
cfg.alpha                   = 0.01;
cfg.tail                    = 0;

nsubj=numel(grandAvgBase);
cfg.design(1,:)             = [1:nsubj 1:nsubj];
cfg.design(2,:)             = [ones(1,nsubj) ones(1,nsubj)*2];
cfg.uvar                    = 1; % row of design matrix that contains unit variable (in this case: subjects)
cfg.ivar                    = 2; % row of design matrix that contains independent variable (the conditions)

stat                        = ft_sourcestatistics(cfg, grandAvgExp{:}, grandAvgBase{:});

clear grandAvgExp grandAvgBase

% Save the result (first without interpolating it which destroyed some
% fields)
% if ~exist(dirFiles.SSH_stat,'dir'), mkdir(dirFiles.SSH_stat); end
% name = ['Statistics - group level (cstats ' cfg.clusterstatistic ', calpha' num2str(cfg.clusteralpha) ', alpha' num2str(cfg.alpha) ', nrands' num2str(cfg.numrandomization) ').mat'];
% save(fullfile(dirFiles.SSH_stat, name),'stat','-v7.3');
% disp(['Stats successfully saved to ' name '.'])

% Interpolate the results and save as well
cfg_int                     = [];
cfg_int.parameter           = 'all';
stat_mni                    = ft_sourceinterpolate(cfg_int, stat, mri_mni);

name = ['Group stats ' name_suffix ' (FDRanl, alpha' num2str(cfg.alpha) ') - interp.mat'];
if ~exist(dirFiles.SSH_statfdr,'dir'), mkdir(dirFiles.SSH_statfdr); end
save(fullfile(dirFiles.SSH_statfdr, name),'stat_mni','-v7.3');
disp(['Interpolated stats successfully saved to ' name '.'])
    
clear stat stat_mni name


%% ------     X SOURCE STATISTICS - SLOW SPINDLES 08 Hz               - FDR analytic     

name_suffix                         = '_SS';
dirFiles.SS_statfdr                 = fullfile(dirFiles.SS_results, 'stats (merged, subset wos10) fdr');
template                            = hh_loadData(fullfile(home,'_fieldtrip','template', 'sourcemodel', ['standard_sourcemodel3d' num2str(gridResolution) 'mm.mat']));
                                                  
% Gather all the source localizations
fileList.SS_exp                     = hh_getFilenames(dirFiles.SS_exp);
fileList.SS_base                    = hh_getFilenames(dirFiles.SS_base);

subjectsToAnalyze                   = [1 2 3 4 5 6 7 8 9 11 12];    % subset !!

counter = 1; 
for iSubj = subjectsToAnalyze
   grandAvgBase{counter}            = hh_loadData(fullfile(dirFiles.SS_base, fileList.SS_base{iSubj}));
   grandAvgBase{counter}.pos        = template.pos; % take pos and dim from the MNI template
   grandAvgBase{counter}.dim        = template.dim;
   counter = counter + 1;
end

counter = 1; 
for iSubj = subjectsToAnalyze
   grandAvgExp{counter}            = hh_loadData(fullfile(dirFiles.SS_exp, fileList.SS_exp{iSubj}));
   grandAvgExp{counter}.pos        = template.pos; % take pos and dim from the MNI template
   grandAvgExp{counter}.dim        = template.dim;
   counter = counter + 1;
end

% run statistics over subjects %
cfg                         = [];
cfg.dim                     = grandAvgExp{1}.dim;
cfg.method                  = 'analytic';
cfg.statistic               = 'ft_statfun_depsamplesT';
cfg.parameter               = 'avg.pow';
cfg.correctm                = 'fdr';
cfg.correcttail             = 'alpha';  % corrects for two tails
cfg.alpha                   = 0.01;
cfg.tail                    = 0;

nsubj=numel(grandAvgBase);
cfg.design(1,:)             = [1:nsubj 1:nsubj];
cfg.design(2,:)             = [ones(1,nsubj) ones(1,nsubj)*2];
cfg.uvar                    = 1; % row of design matrix that contains unit variable (in this case: subjects)
cfg.ivar                    = 2; % row of design matrix that contains independent variable (the conditions)

stat                        = ft_sourcestatistics(cfg, grandAvgExp{:}, grandAvgBase{:});

clear grandAvgExp grandAvgBase

% Save the result (first without interpolating it which destroyed some
% fields)
% if ~exist(dirFiles.SS_stat,'dir'), mkdir(dirFiles.SS_stat); end
% name = ['Statistics - group level (cstats ' cfg.clusterstatistic ', calpha' num2str(cfg.clusteralpha) ', alpha' num2str(cfg.alpha) ', nrands' num2str(cfg.numrandomization) ').mat'];
% save(fullfile(dirFiles.SS_stat, name),'stat','-v7.3');
% disp(['Stats successfully saved to ' name '.'])

% Interpolate the results and save as well
cfg_int                     = [];
cfg_int.parameter           = 'all';
stat_mni                    = ft_sourceinterpolate(cfg_int, stat, mri_mni);

name = ['Group stats ' name_suffix ' (FDRanl, alpha' num2str(cfg.alpha) ') - interp.mat'];
if ~exist(dirFiles.SS_statfdr,'dir'), mkdir(dirFiles.SS_statfdr); end
save(fullfile(dirFiles.SS_statfdr, name),'stat_mni','-v7.3');
disp(['Interpolated stats successfully saved to ' name '.'])
    
clear stat stat_mni name


%% ------     X SOURCE MODELLING - RIPPLES                          - DID NOT WORK OUT      


% ---  Ripples

dirFiles.RP_sources         = fullfile(dirFiles.home, 'sources RP trace'); % HERE
dirFiles.RP_results         = fullfile(dirFiles.RP_sources, 'results');


% Parameters for ft_sourceanalysis
% If MNI-aligned grids are used, the result is not interpolated to subject
% MRI and then normalized to the MNI, but is directly interpolated to the
% MNI-template MRI.
cfg                         = [];
cfg.dirLeadfield            = dirFiles.leadfield;
cfg.dirHeadmodel            = dirFiles.headmodel;
cfg.dirMRI                  = dirFiles.preparedMRI;
cfg.dirTFR                  = dirFiles.RP_TFR;
cfg.frequency               = RPfreq(1);
cfg.saveTo                  = dirFiles.RP_sources;
cfg.saveResultsTo           = dirFiles.RP_results;
cfg.method                  = 'dics';   % use dynamic imaging of coherent sources (Gross2001)
cfg.dics.projectnoise       = 'yes';    % estimates the noise at every location; not very precise
cfg.dics.lambda             = '5%';     % regularization parameter
cfg.dics.keepfilter         = 'yes';    % save the calculated filter, e.g. to use it as a common filter
cfg.dics.realfilter         = 'yes';    % only use the real part of the fourier transform
cfg.powmethod               = 'trace';    % 'trace' or 'lambda1' (default)          % HERE
cfg.gridResolution          = gridResolution;   % will lead to use of the correct template to replace .pos and .dim
cfg.keeptrials              = 'yes';    % trials must be kept when two conditions are compared together
cfg.dirDesign               = dirFiles.trialInfo; % couldnt name it cfg.dirTrialinfo (callFunction would have handled it)
% cfg.fileGrad                = fileGrad;   % ft_headmovement grads should not be given here again (says Joerg)

                            hh_callFunction('hh_doDICS', cfg, cfg.dirTFR)

% Generate the grand average (can't just use callFunction because of a
% fieldtrip bug (I filed it under #2596).
% This can be done on non-interpolated data, since everything is in MNI
% space anyway.
fileList.RP_results         = hh_getFilenames(dirFiles.RP_results);

for iSubj = 1:14
   average_this{iSubj}          = hh_loadData(fullfile(dirFiles.RP_results, fileList.RP_results{iSubj}));
end

cfg                         = [];
grandavg                    = ft_sourcegrandaverage(cfg, average_this{:});

clear average_this

% Read the MNI MRI
mri = ft_read_mri(fullfile(home, '_fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));

% Interpolate the grand average to it
cfg_int                      = [];
cfg_int.downsample           = 2;
cfg_int.parameter            = 'pow';
grandavg_int                 = ft_sourceinterpolate(cfg_int, grandavg, mri);

save(fullfile(dirFiles.RP_results, 'x_RP_grandaverage_1mm.mat'),'grandavg_int','-v7.3');
clear grandavg grandavg_int


% ---  Ripples - DOWN-UP phase DU

dirFiles.RPDU_sources         = fullfile(dirFiles.home, 'sources RP down-up');
dirFiles.RPDU_results         = fullfile(dirFiles.RPDU_sources, 'results');


% Parameters for ft_sourceanalysis
% If MNI-aligned grids are used, the result is not interpolated to subject
% MRI and then normalized to the MNI, but is directly interpolated to the
% MNI-template MRI.
cfg                         = [];
cfg.dirLeadfield            = dirFiles.leadfield;
cfg.dirHeadmodel            = dirFiles.headmodel;
cfg.dirMRI                  = dirFiles.preparedMRI;
cfg.dirTFR                  = dirFiles.RPDU_TFR;
cfg.frequency               = RPDUfreq(1);
cfg.saveTo                  = dirFiles.RPDU_sources;
cfg.saveResultsTo           = dirFiles.RPDU_results;
cfg.method                  = 'dics';   % use dynamic imaging of coherent sources (Gross2001)
cfg.dics.projectnoise       = 'yes';    % estimates the noise at every location; not very precise
cfg.dics.lambda             = '5%';     % regularization parameter
cfg.dics.keepfilter         = 'yes';    % save the calculated filter, e.g. to use it as a common filter
cfg.dics.realfilter         = 'yes';    % only use the real part of the fourier transform
cfg.powmethod               = 'lambda1';    % 'trace' or 'lambda1' (default)
cfg.gridResolution          = gridResolution;   % will lead to use of the correct template to replace .pos and .dim
cfg.keeptrials              = 'yes';    % trials must be kept when two conditions are compared together
cfg.dirDesign               = dirFiles.trialInfo; % couldnt name it cfg.dirTrialinfo (callFunction would have handled it)
% cfg.fileGrad                = fileGrad;   % ft_headmovement grads should not be given here again (says Joerg)

                            hh_callFunction('hh_doDICS', cfg, cfg.dirTFR)

% Generate the grand average (can't just use callFunction because of a
% fieldtrip bug (I filed it under #2596).
% This can be done on non-interpolated data, since everything is in MNI
% space anyway.
fileList.RPDU_results         = hh_getFilenames(dirFiles.RPDU_results);

for iSubj = 1:14
   average_this{iSubj}          = hh_loadData(fullfile(dirFiles.RPDU_results, fileList.RPDU_results{iSubj}));
end

cfg                         = [];
grandavg                    = ft_sourcegrandaverage(cfg, average_this{:});

clear average_this

% Read the MNI MRI
mri = ft_read_mri(fullfile(home, '_fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));

% Interpolate the grand average to it
cfg_int                      = [];
cfg_int.downsample           = 2;
cfg_int.parameter            = 'pow';
grandavg_int                 = ft_sourceinterpolate(cfg_int, grandavg, mri);

save(fullfile(dirFiles.RPDU_results, 'x_RP_grandaverage_1mm.mat'),'grandavg_int','-v7.3');
clear grandavg grandavg_int


% ---  Ripples - Narrow band

dirFiles.RP2_sources         = fullfile(dirFiles.home, 'sources RP narrow');
dirFiles.RP2_results         = fullfile(dirFiles.RP2_sources, 'results');


% Parameters for ft_sourceanalysis
% If MNI-aligned grids are used, the result is not interpolated to subject
% MRI and then normalized to the MNI, but is directly interpolated to the
% MNI-template MRI.
cfg                         = [];
cfg.dirLeadfield            = dirFiles.leadfield;
cfg.dirHeadmodel            = dirFiles.headmodel;
cfg.dirMRI                  = dirFiles.preparedMRI;
cfg.dirTFR                  = dirFiles.RP2_TFR;
cfg.frequency               = RP2freq(1);
cfg.saveTo                  = dirFiles.RP2_sources;
cfg.saveResultsTo           = dirFiles.RP2_results;
cfg.method                  = 'dics';   % use dynamic imaging of coherent sources (Gross2001)
cfg.dics.projectnoise       = 'yes';    % estimates the noise at every location; not very precise
cfg.dics.lambda             = '5%';     % regularization parameter
cfg.dics.keepfilter         = 'yes';    % save the calculated filter, e.g. to use it as a common filter
cfg.dics.realfilter         = 'yes';    % only use the real part of the fourier transform
cfg.powmethod               = 'lambda1';    % 'trace' or 'lambda1' (default)
cfg.gridResolution          = gridResolution;   % will lead to use of the correct template to replace .pos and .dim
cfg.keeptrials              = 'yes';    % trials must be kept when two conditions are compared together
cfg.dirDesign               = dirFiles.trialInfo; % couldnt name it cfg.dirTrialinfo (callFunction would have handled it)
% cfg.fileGrad                = fileGrad;   % ft_headmovement grads should not be given here again (says Joerg)

                            hh_callFunction('hh_doDICS', cfg, cfg.dirTFR)

% Generate the grand average (can't just use callFunction because of a
% fieldtrip bug (I filed it under #2596).
% This can be done on non-interpolated data, since everything is in MNI
% space anyway.
fileList.RP2_results         = hh_getFilenames(dirFiles.RP2_results);

for iSubj = 1:14
   average_this{iSubj}          = hh_loadData(fullfile(dirFiles.RP2_results, fileList.RP2_results{iSubj}));
end

cfg                         = [];
grandavg                    = ft_sourcegrandaverage(cfg, average_this{:});

clear average_this

% Read the MNI MRI
mri = ft_read_mri(fullfile(home, '_fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));

% Interpolate the grand average to it
cfg_int                      = [];
cfg_int.downsample           = 2;
cfg_int.parameter            = 'pow';
grandavg_int                 = ft_sourceinterpolate(cfg_int, grandavg, mri);

save(fullfile(dirFiles.RP2_results, 'x_RP2_grandaverage_1mm.mat'),'grandavg_int','-v7.3');
clear grandavg grandavg_int


% ---  Ripples - DOWN-UP phase DU, narrow band

dirFiles.RPDU2_sources         = fullfile(dirFiles.home, 'sources RP down-up narrow');
dirFiles.RPDU2_results         = fullfile(dirFiles.RPDU2_sources, 'results');


% Parameters for ft_sourceanalysis
% If MNI-aligned grids are used, the result is not interpolated to subject
% MRI and then normalized to the MNI, but is directly interpolated to the
% MNI-template MRI.
cfg                         = [];
cfg.dirLeadfield            = dirFiles.leadfield;
cfg.dirHeadmodel            = dirFiles.headmodel;
cfg.dirMRI                  = dirFiles.preparedMRI;
cfg.dirTFR                  = dirFiles.RPDU2_TFR;
cfg.frequency               = RPDU2freq(1);
cfg.saveTo                  = dirFiles.RPDU2_sources;
cfg.saveResultsTo           = dirFiles.RPDU2_results;
cfg.method                  = 'dics';   % use dynamic imaging of coherent sources (Gross2001)
cfg.dics.projectnoise       = 'yes';    % estimates the noise at every location; not very precise
cfg.dics.lambda             = '5%';     % regularization parameter
cfg.dics.keepfilter         = 'yes';    % save the calculated filter, e.g. to use it as a common filter
cfg.dics.realfilter         = 'yes';    % only use the real part of the fourier transform
cfg.powmethod               = 'lambda1';    % 'trace' or 'lambda1' (default)
cfg.gridResolution          = gridResolution;   % will lead to use of the correct template to replace .pos and .dim
cfg.keeptrials              = 'yes';    % trials must be kept when two conditions are compared together
cfg.dirDesign               = dirFiles.trialInfo; % couldnt name it cfg.dirTrialinfo (callFunction would have handled it)
% cfg.fileGrad                = fileGrad;   % ft_headmovement grads should not be given here again (says Joerg)

                            hh_callFunction('hh_doDICS', cfg, cfg.dirTFR)

% Generate the grand average (can't just use callFunction because of a
% fieldtrip bug (I filed it under #2596).
% This can be done on non-interpolated data, since everything is in MNI
% space anyway.
fileList.RPDU2_results         = hh_getFilenames(dirFiles.RPDU2_results);

for iSubj = 1:14
   average_this{iSubj}          = hh_loadData(fullfile(dirFiles.RPDU2_results, fileList.RPDU2_results{iSubj}));
end

cfg                         = [];
grandavg                    = ft_sourcegrandaverage(cfg, average_this{:});

clear average_this

% Read the MNI MRI
mri = ft_read_mri(fullfile(home, '_fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));

% Interpolate the grand average to it
cfg_int                      = [];
cfg_int.downsample           = 2;
cfg_int.parameter            = 'pow';
grandavg_int                 = ft_sourceinterpolate(cfg_int, grandavg, mri);

save(fullfile(dirFiles.RPDU2_results, 'x_RPDU2_grandaverage_1mm.mat'),'grandavg_int','-v7.3');
clear grandavg grandavg_int


%% ------     X SOURCE MODELLING - SPINDLES (single trial)          - NOT REALLY DONE YET       


% ---  Fast spindles

dirFiles.FSs_sources         = fullfile(dirFiles.home, 'sources FS single');
dirFiles.FSs_results         = fullfile(dirFiles.FSs_sources, 'results');


% Parameters for ft_sourceanalysis
% If MNI-aligned grids are used, the result is not interpolated to subject
% MRI and then normalized to the MNI, but is directly interpolated to the
% MNI-template MRI.
cfg                         = [];
cfg.dirLeadfield            = dirFiles.leadfield;
cfg.dirHeadmodel            = dirFiles.headmodel;
cfg.dirMRI                  = dirFiles.preparedMRI;
cfg.dirTFR                  = dirFiles.FS_TFR;
cfg.frequency               = FSfreq(1);
cfg.saveTo                  = dirFiles.FSs_sources;
cfg.saveResultsTo           = dirFiles.FSs_results;
cfg.method                  = 'dics';       % use dynamic imaging of coherent sources (Gross2001)
cfg.dics.projectnoise       = 'yes';        % estimates the noise at every location; not very precise
cfg.dics.lambda             = '5%';         % regularization parameter
cfg.dics.keepfilter         = 'yes';        % save the calculated filter, e.g. to use it as a common filter
cfg.dics.realfilter         = 'yes';        % only use the real part of the fourier transform
cfg.dics.powmethod          = 'lambda1';    % 'trace' or 'lambda1' (default)
cfg.gridResolution          = gridResolution;   % will lead to use of the correct template to replace .pos and .dim
cfg.keeptrials              = 'yes';    % trials must be kept when two conditions are compared together
cfg.dirDesign               = dirFiles.trialInfo; % couldnt name it cfg.dirTrialinfo (callFunction would have handled it)
% cfg.fileGrad                = fileGrad;   % ft_headmovement grads should not be given here again (says Joerg)
cfg.giveSingleTrials        = 8;           % 10 equals about 50 GB of needed RAM
cfg.singleTrialClusterSize  = 2;
                            hh_callFunction('hh_doDICS', cfg, cfg.dirTFR)


% ---  Slow spindles

dirFiles.SSs_sources         = fullfile(dirFiles.home, 'sources SS single');
dirFiles.SSs_results         = fullfile(dirFiles.SSs_sources, 'results');


% Parameters for ft_sourceanalysis
cfg                         = [];
cfg.dirLeadfield            = dirFiles.leadfield;
cfg.dirHeadmodel            = dirFiles.headmodel;
cfg.dirMRI                  = dirFiles.preparedMRI;
cfg.dirTFR                  = dirFiles.SS_TFR;
cfg.frequency               = SSfreq(1);
cfg.saveTo                  = dirFiles.SSs_sources;
cfg.saveResultsTo           = dirFiles.SSs_results;
cfg.method                  = 'dics';       % use dynamic imaging of coherent sources (Gross2001)
cfg.dics.projectnoise       = 'yes';        % estimates the noise at every location; not very precise
cfg.dics.lambda             = '5%';         % regularization parameter
cfg.dics.keepfilter         = 'yes';        % save the calculated filter, e.g. to use it as a common filter
cfg.dics.realfilter         = 'yes';        % only use the real part of the fourier transform
cfg.dics.powmethod          = 'lambda1';    % 'trace' or 'lambda1' (default)
cfg.gridResolution          = gridResolution;   % will lead to use of the correct template to replace .pos and .dim
cfg.keeptrials              = 'yes';    % trials must be kept when two conditions are compared together
cfg.dirDesign               = dirFiles.trialInfo; % couldnt name it cfg.dirTrialinfo (callFunction would have handled it)
% cfg.fileGrad                = fileGrad;   % ft_headmovement grads should not be given here again (says Joerg)
cfg.giveSingleTrials        = 8;           % 10 equals about 50 GB of needed RAM
cfg.singleTrialClusterSize  = 2;

                            hh_callFunction('hh_doDICS', cfg, cfg.dirTFR)


%% ------     ~MERGE SPLIT DATASETS (AVERAGE)    

% Average split data sets in experimental and baseline condition, and also
% the source contrasts in the 'results' folders. For the latter a new
% folder 'merged' is created to keep the previously generated grand average
% sensible.
cfg                         = [];
cfg.parameter               = 'avg.pow';
cfg.merge                   = {[6 7], [10 11]};
                            
cfg.dirFiles                = dirFiles.FS_exp;
                            hh_averageSources(cfg);
                            
cfg.dirFiles                = dirFiles.FS_base;
                            hh_averageSources(cfg);                          

cfg.dirFiles                = dirFiles.SSH_exp;
                            hh_averageSources(cfg);
                            
cfg.dirFiles                = dirFiles.SSH_base;
                            hh_averageSources(cfg);
                            
cfg.dirFiles                = dirFiles.SS_exp;
                            hh_averageSources(cfg);
                            
cfg.dirFiles                = dirFiles.SS_base;
                            hh_averageSources(cfg);

% Result folders

cfg                         = [];
cfg.parameter               = 'avg.pow';
cfg.merge                   = {[6 7], [10 11]};
cfg.saveTo                  = 'merged';

cfg.dirFiles                = dirFiles.FS_results;
dirFiles.FS_results_mged    = hh_averageSources(cfg);
                            
cfg.dirFiles                = dirFiles.SSH_results;
dirFiles.SSH_results_mged   = hh_averageSources(cfg);  
                            
cfg.dirFiles                = dirFiles.SS_results;
dirFiles.SS_results_mged    = hh_averageSources(cfg);                            


%% ------     ~GRAND AVERAGE OF MERGED FILES     

subjectsToAverage_TUE            = [1 2 3 4 5 6 7 8 9 11 12];   % subjects to consider for the grand average (after merge = TÜ notation!)
name_suffix                      = {'_FS__wos10', '_SSH__wos10', '_SS__wos10'};

merged                           = {dirFiles.FS_results_mged, dirFiles.SSH_results_mged, dirFiles.SS_results_mged};

for iPart = 1:numel(merged)
    
    fileList.cur_mergedResults   = hh_getFilenames(merged{iPart});
    
    counter = 1;
    for iFile = subjectsToAverage_TUE
        average_this{counter}     = hh_loadData(fullfile(merged{iPart}, fileList.cur_mergedResults{iFile}));
        counter = counter + 1;
    end
    
    cfg                         = [];
    grandavg                    = ft_sourcegrandaverage(cfg, average_this{:});
    clear average_this
    
    % Read the MNI MRI
    mri = ft_read_mri(fullfile(home, '_fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));
    
    % Interpolate the grand average to it
    cfg_int                      = [];
    cfg_int.downsample           = 1;
    cfg_int.parameter            = 'pow';
    grandavg_int                 = ft_sourceinterpolate(cfg_int, grandavg, mri);
    
    grandavg_int.cfg.previous    = [];
    
    name = ['x_grandaverage' name_suffix{iPart} '_1mm_dnsmpl' num2str(cfg_int.downsample) '.mat'];
    save(fullfile(merged{iPart}, name),'grandavg_int','-v7.3');
    disp(['Successfully saved ' name '.'])
    clear grandavg grandavg_int
end


%% ------     ~GRAND AVERAGE OF MERGED FILES                         - WITH NORMALIZATION 

subjectsToAverage_TUE            = [1 2 3 4 5 6 7 8 9 11 12];   % subjects to consider for the grand average (after merge = TÜ notation!)
name_suffix                      = {'_FS_wos10_NORM', '_SSH_wos10_NORM', '_SS_wos10_NORM'};

merged                           = {dirFiles.FS_results_mged, dirFiles.SSH_results_mged, dirFiles.SS_results_mged};

for iPart = 1:numel(merged)
    
    fileList.cur_mergedResults   = hh_getFilenames(merged{iPart});
    
    counter = 1;
    all_lengths = [];
    for iFile = subjectsToAverage_TUE
        
        average_this{counter}           = hh_loadData(fullfile(merged{iPart}, fileList.cur_mergedResults{iFile}));
        vector                          = reshape(average_this{counter}.avg.pow,[],1);  % transform the power matrix to a 1-column vector
        vector(isnan(vector))           = [];                                           % delete all NaNs
        length                          = norm(vector);                                 % calculate its length
        average_this{counter}.avg.pow   = average_this{counter}.avg.pow / length;       % use the length to normalize the source power
        
        all_lengths(counter)            = length;       % remember this length for later use
            
        counter = counter + 1;
        clear vector length
    end
    
    % Calculate the grand average
    cfg                                 = [];
    grandavg                            = ft_sourcegrandaverage(cfg, average_this{:});
    clear average_this counter
    
    % Re-multiply the result with the average length of all subject vectors
    grandavg.pow                        = grandavg.pow .* mean(all_lengths);
    
    % Read the MNI MRI
    mri = ft_read_mri(fullfile(home, '_fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));
    
    % Interpolate the grand average to it
    cfg_int                             = [];
    cfg_int.downsample                  = 1;
    cfg_int.parameter                   = 'pow';
    grandavg_int                        = ft_sourceinterpolate(cfg_int, grandavg, mri);
    
    grandavg_int.cfg.previous           = [];
    
    name = ['x_grandaverage' name_suffix{iPart} '_1mm_dnsmpl' num2str(cfg_int.downsample) '.mat'];
    save(fullfile(merged{iPart}, name),'grandavg_int','-v7.3');
    disp(['Successfully saved ' name '.'])
    clear grandavg grandavg_int
end


%% ------     BACKUP: SOURCE MODELLING - SPINDLES       - before rebuilt
% Note that the automatic grand averages here are a) performed over all
% subjects, and b) consider split datasets as two units of observation (no
% merge done prior to averaging). These things have to be dealt with
% manually later.
%
% See Further comments: DICS beamforming
% and http://fieldtrip.fcdonders.nl/example/common_filters_in_beamforming

% ---  Fast spindles

dirFiles.FS_sources         = fullfile(dirFiles.home, 'sources FS new');
dirFiles.FS_base            = fullfile(dirFiles.FS_sources, 'baseline');
dirFiles.FS_exp             = fullfile(dirFiles.FS_sources, 'experimental');
dirFiles.FS_results         = fullfile(dirFiles.FS_sources, 'results');


% Parameters for ft_sourceanalysis
% If MNI-aligned grids are used, the result is not interpolated to subject
% MRI and then normalized to the MNI, but is directly interpolated to the
% MNI-template MRI.
cfg                         = [];
cfg.dirLeadfield            = dirFiles.leadfield;
cfg.dirHeadmodel            = dirFiles.headmodel;
cfg.dirMRI                  = dirFiles.preparedMRI;
cfg.dirTFR                  = dirFiles.FS_TFR;
cfg.frequency               = FSfreq(1);
cfg.saveTo                  = dirFiles.FS_sources;
cfg.saveBaseTo              = dirFiles.FS_base;
cfg.saveExpTo               = dirFiles.FS_exp;
cfg.saveResultsTo           = dirFiles.FS_results;
cfg.method                  = 'dics';       % use dynamic imaging of coherent sources (Gross2001)
cfg.dics.projectnoise       = 'yes';        % estimates the noise at every location; not very precise
% cfg.dics.lambda             = '5%';         % regularization parameter
cfg.dics.keepfilter         = 'yes';        % save the calculated filter, e.g. to use it as a common filter
cfg.dics.realfilter         = 'yes';        % only use the real part of the fourier transform
cfg.dics.powmethod          = 'lambda1';    % 'trace' or 'lambda1' (default)
cfg.gridResolution          = gridResolution;   % will lead to use of the correct template to replace .pos and .dim
cfg.keeptrials              = 'yes';    % trials must be kept when two conditions are compared together
cfg.dirDesign               = dirFiles.trialInfo; % couldnt name it cfg.dirTrialinfo (callFunction would have handled it)
cfg.fileGrad                = fileGrad;   % ft_headmovement grads should not be given here again (says Joerg)

                            hh_callFunction('hh_doDICS', cfg, cfg.dirTFR)
                            
% Generate the grand average (can't just use callFunction because of a
% fieldtrip bug (I filed it under #2596).
% This can be done on non-interpolated data, since everything is in MNI
% space anyway.
fileList.FS_results         = hh_getFilenames(dirFiles.FS_results);

for iSubj = 1:14
   average_this{iSubj}          = hh_loadData(fullfile(dirFiles.FS_results, fileList.FS_results{iSubj}));
end

cfg                         = [];
grandavg                    = ft_sourcegrandaverage(cfg, average_this{:});

clear average_this

% Read the MNI MRI
mri = ft_read_mri(fullfile(home, '_fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));

% Interpolate the grand average to it
cfg_int                      = [];
cfg_int.downsample           = 1;
cfg_int.parameter            = 'pow';
grandavg_int                 = ft_sourceinterpolate(cfg_int, grandavg, mri);

grandavg_int.cfg.previous    = [];

save(fullfile(dirFiles.FS_results, 'x_FS_grandaverage_1mm.mat'),'grandavg_int','-v7.3');
clear grandavg grandavg_int


% ---  Slow spindles 10 Hz

dirFiles.SSH_sources         = fullfile(dirFiles.home, 'sources SSH');
dirFiles.SSH_base            = fullfile(dirFiles.SSH_sources, 'baseline');
dirFiles.SSH_exp             = fullfile(dirFiles.SSH_sources, 'experimental');
dirFiles.SSH_results         = fullfile(dirFiles.SSH_sources, 'results');


% Parameters for ft_sourceanalysis
cfg                         = [];
cfg.dirLeadfield            = dirFiles.leadfield;
cfg.dirHeadmodel            = dirFiles.headmodel;
cfg.dirMRI                  = dirFiles.preparedMRI;
cfg.dirTFR                  = dirFiles.SSH_TFR;
cfg.frequency               = SSHfreq(1);
cfg.saveTo                  = dirFiles.SSH_sources;
cfg.saveBaseTo              = dirFiles.SSH_base;
cfg.saveExpTo               = dirFiles.SSH_exp;
cfg.saveResultsTo           = dirFiles.SSH_results;
cfg.method                  = 'dics';   % use dynamic imaging of coherent sources (Gross2001)
cfg.dics.projectnoise       = 'yes';    % estimates the noise at every location; not very precise
cfg.dics.lambda             = '5%';     % regularization parameter
cfg.dics.keepfilter         = 'yes';    % save the calculated filter, e.g. to use it as a common filter
cfg.dics.realfilter         = 'yes';    % only use the real part of the fourier transform
cfg.powmethod               = 'lambda1';    % 'trace' or 'lambda1' (default)
cfg.gridResolution          = gridResolution;   % will lead to use of the correct template to replace .pos and .dim
cfg.keeptrials              = 'yes';    % I think trials must  be kept when two conditions are compared
cfg.dirDesign               = dirFiles.trialInfo; % couldnt name it cfg.dirTrialinfo (callFunction would have handled it)
% cfg.fileGrad                = fileGrad;   % ft_headmovement grads should not be given here again (says Joerg)

                            hh_callFunction('hh_doDICS', cfg, cfg.dirTFR)
                            

% Generate the grand average (can't just use callFunction because of a
% fieldtrip bug (I filed it under #2596).
fileList.SSH_results         = hh_getFilenames(dirFiles.SSH_results);

for iSubj = 1:14
   average_this{iSubj}          = hh_loadData(fullfile(dirFiles.SSH_results, fileList.SSH_results{iSubj}));
end

cfg                         = [];
grandavg                    = ft_sourcegrandaverage(cfg, average_this{:});

clear average_this

% Read the MNI MRI
mri = ft_read_mri(fullfile(home, '_fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));

% Interpolate the grand average to it
cfg_int                      = [];
cfg_int.downsample           = 1;
cfg_int.parameter            = 'pow';
grandavg_int                 = ft_sourceinterpolate(cfg_int, grandavg, mri);

grandavg_int.cfg.previous    = [];

save(fullfile(dirFiles.SSH_results, 'x_SSH_grandaverage_1mm.mat'),'grandavg_int','-v7.3');
clear grandavg grandavg_int


% ---  Slow spindles 08 Hz

dirFiles.SS_sources         = fullfile(dirFiles.home, 'sources SS');
dirFiles.SS_base            = fullfile(dirFiles.SS_sources, 'baseline');
dirFiles.SS_exp             = fullfile(dirFiles.SS_sources, 'experimental');
dirFiles.SS_results         = fullfile(dirFiles.SS_sources, 'results');


% Parameters for ft_sourceanalysis
cfg                         = [];
cfg.dirLeadfield            = dirFiles.leadfield;
cfg.dirHeadmodel            = dirFiles.headmodel;
cfg.dirMRI                  = dirFiles.preparedMRI;
cfg.dirTFR                  = dirFiles.SS_TFR;
cfg.frequency               = SSfreq(1);
cfg.saveTo                  = dirFiles.SS_sources;
cfg.saveBaseTo              = dirFiles.SS_base;
cfg.saveExpTo               = dirFiles.SS_exp;
cfg.saveResultsTo           = dirFiles.SS_results;
cfg.method                  = 'dics';   % use dynamic imaging of coherent sources (Gross2001)
cfg.dics.projectnoise       = 'yes';    % estimates the noise at every location; not very precise
cfg.dics.lambda             = '5%';     % regularization parameter
cfg.dics.keepfilter         = 'yes';    % save the calculated filter, e.g. to use it as a common filter
cfg.dics.realfilter         = 'yes';    % only use the real part of the fourier transform
cfg.powmethod               = 'lambda1';    % 'trace' or 'lambda1' (default)
cfg.gridResolution          = gridResolution;   % will lead to use of the correct template to replace .pos and .dim
cfg.keeptrials              = 'yes';    % I think trials must  be kept when two conditions are compared
cfg.dirDesign               = dirFiles.trialInfo; % couldnt name it cfg.dirTrialinfo (callFunction would have handled it)
% cfg.fileGrad                = fileGrad;   % ft_headmovement grads should not be given here again (says Joerg)

                            hh_callFunction('hh_doDICS', cfg, cfg.dirTFR)
                            

% Generate the grand average (can't just use callFunction because of a
% fieldtrip bug (I filed it under #2596).
fileList.SS_results         = hh_getFilenames(dirFiles.SS_results);

for iSubj = 1:14
   average_this{iSubj}          = hh_loadData(fullfile(dirFiles.SS_results, fileList.SS_results{iSubj}));
end

cfg                         = [];
grandavg                    = ft_sourcegrandaverage(cfg, average_this{:});

clear average_this

% Read the MNI MRI
mri = ft_read_mri(fullfile(home, '_fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));

% Interpolate the grand average to it
cfg_int                      = [];
cfg_int.downsample           = 1;
cfg_int.parameter            = 'pow';
grandavg_int                 = ft_sourceinterpolate(cfg_int, grandavg, mri);

grandavg_int.cfg.previous    = [];

save(fullfile(dirFiles.SS_results, 'x_SS_grandaverage_1mm.mat'),'grandavg_int','-v7.3');
clear grandavg grandavg_int


%% ------     PLOTTING: ATLAS  
% TODO: Umschreiben für hh_plotSource

% For partial masking of functional data use ft_volumelookup manually and
% add it as a mask to your source structure (s. below).
% atlas   = ft_read_atlas(fullfile(home, '_fieldtrip','template','atlas','aal','ROI_MNI_V4.nii'));
% Tzourio-Mazoyer (2002). Automated Anatomical Labeling of Activations in 
% SPM... Neuroimage.
% 'Hippocampus_L'         37
% 'Hippocampus_R'         38
% 'ParaHippocampal_L'     39
% 'ParaHippocampal_R'     40
% 'Supp_Motor_Area_L'     19
% 'Supp_Motor_Area_R'     20

cfg                             = [];
cfg.saveTo                      = 'testplots';
cfg.addCoordsys                 = 'mni';        % setting for hh_plotSource
cfg.funparameter                = 'avg.pow';
cfg.opacitymap                  = 'rampup';  
cfg.funcolormap                 = 'jet';

% cfg.funcolorlim                 = 'zeromax'; % = [0.0 1.2];
% cfg.opacitylim                  = 'zeromax'; % = [0.0 1.2];
cfg.method                      = 'slice';
cfg.funcolorlim                 = [0 0.01]; % = [0.0 1.2];
cfg.opacitylim                  = [0 0.01]; % = [0.0 1.2]; = 'zeromax'; 
% cfg.nslices                     = 20;
% cfg.slicerange                  = [18 35];
cfg.atlas                       = fullfile(home, '_fieldtrip','template','atlas','aal','ROI_MNI_V4.nii');
% cfg.roi                         = {'ParaHippocampal_L';'ParaHippocampal_R'};
% cfg.roi                         = {'Hippocampus_L';'Hippocampus_R'};
cfg.roi                         = {'Hippocampus_L';'Hippocampus_R'; 'ParaHippocampal_L';'ParaHippocampal_R'};
% cfg.roi                         = {'Supp_Motor_Area_L','Supp_Motor_Area_R'};

                                hh_callFunction('hh_plotSource', cfg, dirFiles.RPDU_results, 1)

cfg.funparameter                = 'pow';                                

                                hh_callFunction('ft_sourceplot', cfg, dirFiles.RP_results, 15)


%% ------     PLOTTING      

% Slice plot
cfg                             = [];
cfg.method                      = 'slice';
% cfg.funparameter                = 'avg.pow';
cfg.funparameter                = 'trial.pow';
cfg.maskparameter               = cfg.funparameter;
% cfg.opacitymap                  = 'rampup';  
cfg.funcolormap                 = 'jet';
% cfg.coordsys                    = 'als';
cfg.funcolorlim                 = 'zeromax'; % = [0.0 1.2];
cfg.opacitylim                  = [0.0 1]; %'zeromax'; % = [0.0 1.2];

% cfg.funcolorlim                 = [0 0.8]; % = [0.0 1.2];
% cfg.opacitylim                  = [0.2 0.9]; % = [0.0 1.2]; = 'zeromax'; 

                                hh_callFunction('hh_plotSource',cfg,dirFiles.FS_results, 1:14)
                                
% cfg.funcolorlim                 = [0 1.4]; % = [0.0 1.2];
% cfg.opacitylim                  = [0.4 1.4]; % = [0.0 1.2]; = 'zeromax'; 

                                hh_callFunction('hh_plotSource',cfg,dirFiles.SS_results, 1:14)
                                
                                hh_callFunction('hh_plotSource',cfg,dirFiles.RP_results, 1:14)
                                hh_callFunction('hh_plotSource',cfg,dirFiles.RPDU_results, 1:14)
                                hh_callFunction('hh_plotSource',cfg,dirFiles.RP2_results, 1:14)                                
                                hh_callFunction('hh_plotSource',cfg,dirFiles.RPDU2_results, 1:14)   
                                
% Surface plot
cfg                             = [];
cfg.method                      = 'surface';
cfg.funparameter                = 'avg.pow';
cfg.maskparameter               = cfg.funparameter;
cfg.funcolormap                 = 'jet';
cfg.opacitymap                  = 'rampup';  
cfg.projmethod                  = 'nearest'; 
% cfg.surfdownsample              = 10; 
% cfg.funcolorlim                 = 'zeromax'; % = [0.0 1.2];
% cfg.opacitylim                  = 'zeromax'; % = [0.0 1.2];

% cfg.funcolorlim                 = [0 0.8]; % = [0.0 1.2];
% cfg.opacitylim                  = [0.2 0.9]; % = [0.0 1.2]; = 'zeromax'; 

                                hh_callFunction('hh_plotSource', cfg,dirFiles.FS_results, 1:14)

% cfg.funcolorlim                 = [0 1.4]; % = [0.0 1.2];
% cfg.opacitylim                  = [0.4 1.4]; % = [0.0 1.2]; = 'zeromax';    

                                hh_callFunction('hh_plotSource', cfg,dirFiles.SS_results, 1:14)

                                hh_callFunction('hh_plotSource',cfg,dirFiles.RP_results, 1:14)
                                hh_callFunction('hh_plotSource',cfg,dirFiles.RPDU_results, 1:14)
                                hh_callFunction('hh_plotSource',cfg,dirFiles.RP2_results, 1:14)                                
                                hh_callFunction('hh_plotSource',cfg,dirFiles.RPDU2_results, 1:14)
%% ------     PLOTTING - GRAND AVERAGE

% Slice plot - total mess when you start having negative values....
cfg                             = [];
cfg.method                      = 'slice';
cfg.funparameter                = 'avg.pow';
cfg.renderer                    = 'opengl';

cfg.funcolorlim                 = [-0.31 0.75];
% cfg.funcolormap                 = cmap;
% cfg.opacitymap                  = 'vdown';
% cfg.opacitylim                  = cfg.funcolorlim;

cfg.slicerange                  = [20 70];
cfg.nslices                     = 12;

% ft_sourceplot(cfg,grandavg_int)

% % Create a mask to get certain values out
% grandavg_int.mask                   = (grandavg_int.pow < -0.1 | grandavg_int.pow > 0.2);
% 
% % Try some manual masking
% grandavg_int.pow_masked             = (grandavg_int.pow .* grandavg_int.mask);
% nans                                = isnan(grandavg_int.pow);
% grandavg_int.pow_nonan              = grandavg_int.pow;
% grandavg_int.pow_nonan(nans)        = 0;

                                hh_callFunction('hh_plotSource',cfg,dirFiles.FS_results, 16)
                                
                                
cfg.funcolorlim                 = [0 1.45]; % = [0.0 1.2];
cfg.opacitylim                  = [0.3 1.45]; % = [0.0 1.2]; = 'zeromax'; 

                                hh_callFunction('hh_plotSource',cfg,dirFiles.SS_results, 16)
                                
                                hh_callFunction('hh_plotSource',cfg,dirFiles.RP_results, 15)
                                hh_callFunction('hh_plotSource',cfg,dirFiles.RPDU_results, 15)
                                hh_callFunction('hh_plotSource',cfg,dirFiles.RP2_results, 15)                                
                                hh_callFunction('hh_plotSource',cfg,dirFiles.RPDU2_results, 15)
 