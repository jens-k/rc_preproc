function test_newnormalise(path_root)

% persistent isInitSelect; 
% isInitSelect = true;

% root = 'Y:\Jens\Reactivated Connectivity';
% addpath(fullfile(root, 'fieldtrip dataset'));
init_rc
addpath(fullfile(path_root, 'fieldtrip dataset'));

mri		= ft_read_mri('Subject01.mri');

cfg = [];
cfg.spmversion = 'spm12';
cfg.nonlinear = 'yes';

cfg.spmmethod = 'old';
old = ft_volumenormalise(cfg, mri);

cfg.spmmethod = 'new';
new = ft_volumenormalise(cfg, mri);

ft_sourceplot(cfg, old)
ft_sourceplot(cfg, new)
end