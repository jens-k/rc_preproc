% fieldtrip network tutorial
% starting with spectral analysis
%% load the required geometrical information
cd('Y:\Jens\Reactivated Connectivity\temp_network tutorial')
load hdm
load sourcemodel_4k
load dataica

%% compute the leadfield
cfg             = [];
cfg.grid        = sourcemodel;
cfg.headmodel   = hdm;
cfg.channel     = {'MEG'};
lf              = ft_prepare_leadfield(cfg, dataica);

%% compute sensor level Fourier spectra, to be used for cross-spectral density computation.
cfg            = [];
cfg.method     = 'mtmfft';
cfg.output     = 'fourier';
cfg.keeptrials = 'yes';
cfg.tapsmofrq  = 1;
cfg.foi        = 10;
freq           = ft_freqanalysis(cfg, dataica);

%% do the source reconstruction
cfg                   = [];
cfg.frequency         = freq.freq;
cfg.method            = 'pcc';
cfg.grid              = lf;
cfg.headmodel         = hdm;
cfg.keeptrials        = 'yes';
cfg.pcc.lambda        = '10%';
cfg.pcc.projectnoise  = 'yes';
cfg.pcc.fixedori      = 'yes';
source = ft_sourceanalysis(cfg, freq);
source = ft_sourcedescriptives([], source); % to get the neural-activity-index

%% compute connectivity
cfg         = [];
cfg.method  ='coh';
cfg.complex = 'absimag';
source_conn = ft_connectivityanalysis(cfg, source);

% get my own data
source_conn_own		= load_file(get_filenames('Y:\Jens\Reactivated Connectivity\homes\sourceanalysis 1.2\resting-state\sources\connectivities', 9, 'full'));
source_conn_own		= source_conn_own{2};

sourcemodel_mni		= load_file('Y:\Jens\fieldtrip\template\sourcemodel\standard_sourcemodel3d10mm.mat');
source_conn_own		= ft_convert_units(source_conn_own,'cm');
source_conn_own.pos = sourcemodel_mni.pos;
% hm_own = load_file('Y:\Jens\Reactivated Connectivity\homes\headmodels 1.2\subject-specific grids\s5_mnigrid_10mm.mat');


%% parcellate 
load atlas_MMP1.0_4k.mat;
atlas.pos = source_conn.pos; % otherwise the parcellation won't work

cfg					= [];
cfg.parcellation	= 'parcellation';
cfg.parameter		= 'cohspctrm';
parc_conn			= ft_sourceparcellate(cfg, source_conn, atlas);

% own data
atlas_own_bn		= ft_read_atlas(fullfile('Y:\Jens\', 'fieldtrip', 'template', 'atlas', 'brainnetome', 'BNA_MPM_thr25_1.25mm.nii'));
atlas_own			= ft_read_atlas(fullfile('Y:\Jens\', 'fieldtrip/template/atlas/aal/ROI_MNI_V4.nii'));
atlas_own			= ft_convert_units(atlas_own,'cm');

% This might solve the error?
% atlas_own.pos		= sourcemodel_mni.pos;
% atlas_own.tissuelabel{1,117} = '?';
% atlas_own.tissue(atlas_own.tissue==0) = 117;
% atlas_own			= ft_convert_units(atlas_own,'cm');

cfg					= []; 
cfg.interpmethod	= 'nearest'; 
cfg.parameter		= 'tissue'; 
atlas_own_int		= ft_sourceinterpolate(cfg, atlas_own, sourcemodel_mni);
atlas_own_int.pos	= sourcemodel_mni.pos;

cfg					= [];
cfg.parcellation	= 'tissue';
cfg.parameter		= 'powcorrspctrm';
parc_conn_own		= ft_sourceparcellate(cfg, source_conn_own, atlas_own_int);

% figure;imagesc(parc_conn.cohspctrm);
% figure;imagesc(parc_conn_own.powcorrspctrm);

%% network analysis
cfg           = [];
cfg.method    = 'degrees';
cfg.parameter = 'cohspctrm';
cfg.threshold = .1;
network_full = ft_networkanalysis(cfg,source_conn);
network_parc = ft_networkanalysis(cfg,parc_conn);

cfg           = [];
cfg.method    = 'degrees';
cfg.parameter = 'powcorrspctrm';
cfg.threshold = .01;
% network_full_own = ft_networkanalysis(cfg,source_conn_own);
network_parc_own = ft_networkanalysis(cfg,parc_conn_own);

%% visualize
cfg               = [];
cfg.method        = 'surface';
cfg.funparameter  = 'degrees';
cfg.funcolormap   = 'jet';
ft_sourceplot(cfg, network_full);
view([-150 30]);

ft_sourceplot(cfg, network_parc);
view([-150 30]);

% own data
cfg               = [];
cfg.method        = 'surface';
cfg.funparameter  = 'degrees';
cfg.funcolormap   = 'jet';
ft_sourceplot(cfg, network_full_own);
view([-150 30]);

ft_sourceplot(cfg, network_parc_own); %  <- why does that also have so few tissue points?
% ft_sourceplot(cfg, t_own);
view([-150 30]);

% Anatomy is missing
mri = ft_read_mri('single_subj_T1_1mm.nii');
cfg					= []; 
cfg.interpmethod	= 'nearest'; 
cfg.parameter		= 'degrees'; 
network_parc_own_int		= ft_sourceinterpolate(cfg, network_parc_own, mri);

cfg               = [];
cfg.method        = 'slice';
cfg.funparameter  = 'degrees';
cfg.funcolormap   = 'jet';
ft_sourceplot(cfg, network_parc_own_int); 

% Problem:
% ft_sourceplot line 275 turns tissues into points in coordinate space, produces NaNs
% ft_checkdata, line 376 does the conversion
% - > ft_checkdata, line 1369 calls unparcellate, which produces NaNs
 t = ft_checkdata(network_parc, 'datatype', {'source', 'volume'}, 'feedback', 'yes', 'hasunit', 'yes');
 any(isnan(unique(t.degrees))) % is 0
 
 t_own = ft_checkdata(network_parc_own, 'datatype', {'source', 'volume'}, 'feedback', 'yes', 'hasunit', 'yes');
 t_own.degrees(isnan(t_own.degrees)) = 0;
 any(isnan(unique(t_own.degrees))) % is 1 !!

 
 
 