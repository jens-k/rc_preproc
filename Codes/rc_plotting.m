% For MNI-warped sourcemodels
source = sources_sep{1};
sourcemodel			= load_file('standard_sourcemodel3d10mm.mat');
mri					= ft_read_mri('single_subj_T1_1mm.nii');
source.pos			= sourcemodel.pos;

cfg_int             = [];
cfg_int.downsample  = 1;           % default: 1 (no downsampling)
cfg_int.parameter   = 'all';
% cfg_int.interpmethod	= 'smudge';
% string, can be 'nearest', 'linear', 'cubic',  'spline', 'sphere_avg' or 'smudge' (default = 'linear for interpolating two 3D volumes, 'nearest' for all other cases)
source_int			= ft_sourceinterpolate(cfg_int, source, mri);

cfg=[]; 
cfg.funparameter = 'pow'; cfg.method = 'slice'; ft_sourceplot(cfg, source_int)


cfg=[]; cfg.surffile = 'surface_inflated_both.mat';
cfg.funparameter = 'pow'; cfg.method = 'surface'; ft_sourceplot(cfg, source_int)



% For non-aligned sources 
mri					= ft_read_mri(abpath(subjdata(1).mri));
mri.coordsys = 'ras';

cfg_int             = [];
cfg_int.downsample  = 1;           % default: 1 (no downsampling)
cfg_int.parameter   = 'all';
source_int			= ft_sourceinterpolate(cfg_int, source, mri);

cfg					= [];
cfg.nonlinear		= 'no';
source_int			= ft_volumenormalise(cfg, source_int);

cfg=[]; cfg.funparameter = 'nai'; cfg.method = 'surface'; ft_sourceplot(cfg, source_int)
cfg=[]; cfg.funparameter = 'pow'; cfg.method = 'slice'; ft_sourceplot(cfg, source_int)

