atlas = ft_read_atlas(fullfile(path_root, 'fieldtrip/template/atlas/aal/ROI_MNI_V4.nii'));	

% Lets load the standard headmodel, it is identical to segmenting the
% T1.nii and creating a singleshell headmodel from that
template_headmodel = load_file(fullfile(path_root, 'fieldtrip', 'template', 'headmodel', 'standard_singleshell.mat'));

% Construct a grid based on that headmodel (it decides inside grid points)
% this leads to slightly different results than loading the standard
% template grid (same number of grid points but slightly different
% positions and number of inside points)
% cfg = [];
% cfg.grid.resolution = 1;
% cfg.grid.tight  = 'yes';
% cfg.inwardshift = -1.5; % this can be less, we dont need so many sources outside the head
% cfg.headmodel   = template_headmodel;
% template_grid   = ft_prepare_sourcemodel(cfg); 
template_grid = load_file(fullfile(path_root, 'fieldtrip', 'template', 'sourcemodel', 'standard_sourcemodel3d10mm.mat'));

% figure
% hold on
% ft_plot_vol(template_headmodel, 'facecolor', 'cortex');alpha 0.5; camlight;
% ft_plot_mesh(template_grid.pos(~template_grid.inside,:)); 
% ft_plot_mesh(template_grid.pos(template_grid.inside,:), 'vertexcolor', 'r'); 

atlas = ft_convert_units(atlas,'cm'); % crucial !!
cfg = [];
cfg.atlas = atlas;
cfg.roi = atlas.tissuelabel;
cfg.inputcoord = 'mni';
mask = ft_volumelookup(cfg,template_grid);

% version fieldtrip
tmp                  = repmat(template_grid.inside,1,1);
tmp(tmp==1)          = 0;
tmp(mask)            = 1;
template_grid.inside = tmp;

% =
template_grid.inside = mask(:);

figure
ft_plot_mesh(template_grid.pos(template_grid.inside,:))


%% ---------------------------------------------------------------------

% plot an atlas
t = jet(128);
cfg=[];
cfg.funparameter = 'tissue';
cfg.method = 'surface';
cfg.surffile = 'surface_pial_right.mat';
cfg.funcolormap = t(randperm(128)',:);
ft_sourceplot(cfg,atlas_t)

% load stuff
mri_spm             = ft_read_mri(fullfile(path_root, 'fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));
atlas2 = ft_read_atlas(fullfile(path_root,'fieldtrip/template/atlas/spm_anatomy/AllAreas_v17_MPM'))


