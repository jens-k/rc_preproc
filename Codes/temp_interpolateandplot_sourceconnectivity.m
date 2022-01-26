% load a source connectivity dataset into data

sourcemodel				= load_file(fullfile(paths.root,'fieldtrip','template','sourcemodel','standard_sourcemodel3d10mm.mat'));
mri						= ft_read_mri(fullfile(paths.root,'fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));
load('own_sourceconn.mat')
data.pos = sourcemodel.pos;

cfg					= [];
cfg.method			= 'degrees';
cfg.parameter		= 'powcorrspctrm'; 
cfg.threshold		= .1;
network      		= ft_networkanalysis(cfg, data);

cfg_int                      = [];
cfg_int.downsample           = 1;          
cfg_int.parameter            = 'degrees';
network_int = ft_sourceinterpolate(cfg_int, network, mri);

cfg					= [];
cfg.funparameter	= 'degrees';
cfg.method			= 'slice';
ft_sourceplot(cfg, network_int)

% ------  Now lets parcellate
atlas				= ft_read_atlas(fullfile(paths.root, 'fieldtrip', 'template', 'atlas', 'brainnetome', 'BNA_MPM_thr25_1.25mm.nii'));
atlas				= ft_convert_units(atlas,'cm');

cfg					= []; 
cfg.interpmethod	= 'nearest'; 
cfg.parameter		= 'tissue'; 
atlas_int			= ft_sourceinterpolate(cfg, atlas, sourcemodel);
atlas_int.pos		= sourcemodel.pos;

cfg					= [];
cfg.parcellation	= 'tissue';
cfg.parameter		= 'powcorrspctrm'; %'powcorrspctrm'; %'cohspctrm';
parc_data			= ft_sourceparcellate(cfg, data, atlas_int);

cfg					= [];
cfg.method			= 'degrees';
cfg.parameter		= 'powcorrspctrm'; % 'powcorrspctrm'; %'cohspctrm';
cfg.threshold		= .05;
parc_network		= ft_networkanalysis(cfg, parc_data);

cfg_int                      = [];
cfg_int.downsample           = 1;           % default: 1 (no downsampling)
cfg_int.parameter            = 'degrees';
parc_network_int = ft_sourceinterpolate(cfg_int, parc_network, mri);

cfg					= [];
cfg.funparameter	= 'degrees';
cfg.method			= 'surface';
ft_sourceplot(cfg, parc_network_int)
