
%% COMMENTS JENS
% Use this to produce a grid that is only covering cortex, maybe based on
% the new fancy atlas

atlas = ft_read_atlas(fullfile(path_root, 'fieldtrip/template/atlas/aal/ROI_MNI_V4.nii'));

%%

cfg = [];
cfg.grid.xgrid  = -20:5:20;
cfg.grid.ygrid  = -20:5:20;
cfg.grid.zgrid  = -20:5:20;
% cfg.grid.unit   = 'cm';
% cfg.grid.tight  = 'yes';
% cfg.inwardshift = -1.5;
% cfg.headmodel        = vol_stand;
template_grid  = ft_prepare_sourcemodel(cfg);

figure;
ft_plot_mesh(template_grid.pos(template_grid.inside,:));
hold on
ft_plot_vol(vol_stand,  'facecolor', 'cortex', 'edgecolor', 'none');alpha 0.5; camlight;


cfg = [];
cfg.atlas = atlas;
cfg.roi = atlas.tissuelabel;
cfg.inputcoord = 'mni';
mask = ft_volumelookup(cfg,template_grid);

% create temporary mask according to the atlas entries
tmp                  = repmat(template_grid.inside,1,1);
tmp(tmp==1)          = 0;
tmp(mask)            = 1;

% define inside locations according to the atlas based mask
template_grid.inside = tmp;

figure;
%     ft_plot_mesh(template_grid.pos(template_grid.inside,:));
%     hold on
%     ft_plot_vol(vol_stand,  'facecolor', 'cortex', 'edgecolor', 'none');alpha 0.5; camlight;

