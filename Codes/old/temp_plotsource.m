% source_bem			= sources_sep_bem{1};
% source_fem			= sources_sep_fem{1};

sourcemodel			= load_file(abpath('/gpfs01/born/group/Jens/Reactivated Connectivity/fieldtrip/template/sourcemodel/standard_sourcemodel3d10mm.mat'));
mri					= ft_read_mri(fullfile(path_root, 'fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));

sources_bem{2}.pos = sourcemodel.pos;
sources_fem{2}.pos = sourcemodel.pos;

cfg_int                      = [];
cfg_int.downsample           = 1;           % default: 1 (no downsampling)
cfg_int.parameter            = 'all';
source_bem_int             = ft_sourceinterpolate(cfg_int, sources_bem{2}, mri);
source_fem_int             = ft_sourceinterpolate(cfg_int, sources_fem{2}, mri);


% MAYBE PLOT WITH THESE SETTINGS?

% visualize with sourceplot
cfg               = [];
cfg.method        = 'slice';
cfg.funparameter  = 'nai';
cfg.funcolormap   = 'jet';
% cfg.location      = 'max';
cfg.funcolorlim = [0.25 0.55];
ft_sourceplot(cfg,source_bem_int)

cfg               = [];
cfg.method        = 'slice';
cfg.funparameter  = 'nai';
cfg.funcolormap   = 'jet';
% cfg.funcolorlim = [0 4.0E12];
ft_sourceplot(cfg,source_fem_int)