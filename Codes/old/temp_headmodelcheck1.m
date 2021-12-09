init_rc;
subjdata                    = rc_subjectdata;

%% Load all kinds of data
% 1 = s5; 2 = s13 
headmodel1      = load_file(fullfile(path_root, 'homes','headmodels 1.1','prepared', 's5_n1_scalp.15_simbio_fem_prep.mat'));
headmodel2      = load_file(fullfile(path_root, 'homes','headmodels 1.1','prepared', 's13_n1_scalp.10_simbio_fem_prep.mat'));

hm_light1		= rmfield(headmodel1, 'transfer');
hm_light2		= rmfield(headmodel2, 'transfer');

elec1           = ft_read_sens(abpath(subjdata(1).elec));
elec1_proj      = load_file(fullfile(path_root, 'homes','headmodels 1.1','projected electrodes','prepared', 's5_n1_scalp.15_simbio_fem_elecs_proj_prep.mat'));

elec2			= ft_read_sens(abpath(subjdata(2).elec));
elec2_proj      = load_file(fullfile(path_root, 'homes','headmodels 1.1','projected electrodes','prepared', 's13_n1_scalp.10_simbio_fem_elecs_proj_prep.mat'));

grid1           = load_file(fullfile(path_root, 'homes','headmodels 1.1','subject-specific grids', 's5_grid_10mm.mat'));
grid2           = load_file(fullfile(path_root, 'homes','headmodels 1.1','subject-specific grids', 's13_grid_10mm.mat'));

figure;
ft_plot_vol(hm_light1, 'surfaceonly', true, 'facecolor', 'skin', 'edgecolor', 'none', 'vertexcolor', 'none'); 
ft_plot_mesh(grid1.pos(grid1.inside,:), 'vertexcolor', 'red')
ft_plot_mesh(grid1.pos(~logical(grid1.inside),:), 'vertexcolor', 'black')
ft_plot_sens(elec1, 'style', 'k.')
ft_plot_sens(elec1_proj, 'edgecolor', 'r', 'style', '.')

ft_plot_mesh(grid2.pos)
ft_plot_sens(elec2)

% figure
% ft_plot_mesh(hm_light1, 'facecolor', 'skin')
% lighting phong
% camlight left
% camlight right
% material dull
% alpha 0.5

%% Load leadfields and check whether they makes sense
lf      = load_file(fullfile(path_root, 'temp_checkheadmodel','s5_n1_leadfield.mat'));
lf_norm = load_file(fullfile(path_root, 'temp_checkheadmodel','s5_n1_leadfield_norm.mat'));

plotpos = [];
positions=[];
n=size(lf.pos,1);
p=1;
pos = randsample(find(~cellfun(@isempty,lf.leadfield)), 20); % get 20 random non-empty positions

for i = 1:n
    if any(pos == i)
        plotpos(p)=i;
        positions(p,:)=lf.pos(i,:);
        p=p+1;
    end
end
 
figure;
dim = 1;
for i=1:20 
    subplot(4,5,i);
    ft_plot_topo3d(lf.cfg.elec.chanpos,lf.leadfield{plotpos(i)}(:,dim));
	ori = [0 0 0]; 
	ori(dim) = 1;
	ft_plot_dipole(lf.pos(plotpos(i),:), ori, 'color', 'r', 'diameter', 10, 'length', 15)
	dim = dim + 1;
	if dim > 3, dim = 1; end
end

% Normed it looks exactly the same if you dont adapt the same scaling...
% figure;
% dim = 1;
% for i=1:20 
%     subplot(4,5,i);
%     ft_plot_topo3d(lf_norm.cfg.elec.chanpos,lf_norm.leadfield{plotpos(i)}(:,dim));
% 	ori = [0 0 0]; 
% 	ori(dim) = 1;
% 	ft_plot_dipole(lf_norm.pos(plotpos(i),:), ori, 'color', 'r', 'diameter', 10, 'length', 15)
% 	dim = dim + 1;
% 	if dim > 3, dim = 1; end
% end

% print three points in both leadfields

figure
plot(lf.leadfield{plotpos(20)}(:,2)), hold on; 
plot(lf.leadfield{plotpos(19)}(:,2))
plot(lf.leadfield{plotpos(18)}(:,2))

figure
plot(lf_norm.leadfield{plotpos(20)}(:,2)), hold on; 
plot(lf_norm.leadfield{plotpos(19)}(:,2))
plot(lf_norm.leadfield{plotpos(18)}(:,2))

%% Load filters and check whether they makes sense (still uses the leadfields for .pos)
temp			= load_file(fullfile(path_root, 'temp_checkheadmodel','filter for filtercheck.mat')); 
filter			= temp.filter;
filter_norm		= temp.filter_norm;
ori				= load_file(fullfile(path_root, 'temp_checkheadmodel','ori for filtercheck.mat')); % orientation of fixedori filters

plotpos = [];
positions=[];
n=size(lf.pos,1);
p=1;
pos = randsample(find(~cellfun(@isempty,lf.leadfield)), 20); % get 20 random non-empty positions

for i = 1:n
    if any(pos == i)
        plotpos(p)=i;
        positions(p,:)=lf.pos(i,:);
        p=p+1;
    end
end
 
figure;
for i=1:20 
    subplot(4,5,i);
    ft_plot_topo3d(lf.cfg.elec.chanpos,filter{plotpos(i)}(:));
	ft_plot_dipole(lf.pos(plotpos(i),:), ori{plotpos(i)}, 'color', 'r', 'diameter', 10, 'length', 15)
end

% Normed it looks exactly the same if you dont adapt the same scaling...
% figure;
% for i=1:20 
%     subplot(4,5,i);
%     ft_plot_topo3d(lf.cfg.elec.chanpos,filter_norm{plotpos(i)}(:));
% 	ft_plot_dipole(lf.pos(plotpos(i),:), ori{plotpos(i)}, 'color', 'r', 'diameter', 10, 'length', 15)
% end

%% Inside definition
% If you plot the inside grid points based on the FEM headmodel and based
% on the output of prepare_sourcemodel with warpmni = yes, the latter is
% larger and encapsulates the whole skull. 
% I first tried to do that mni-warping manually and manipulate some
% parameters, but there arent that many
% cfg = [];
% cfg.write = 'yes';
% cfg.nonlinear = 'yes';
% cfg.spmversion = 'spm8';
% cfg.name = fullfile(path_headmodels, 'segmentationspm2');
% normalised = ft_volumenormalise(cfg, mri)
%
% So lets test if thats the same with the fieldtrip standard brain -> yes
% it is


mri			= ft_read_mri(abpath(subjdata(1).mri), 'datatype', 'nifti');
mri.coordsys            = 'ras';
mri_ft		= ft_read_mri('Subject01.mri');

cfg                         = [];
cfg.grid.warpmni            = 'yes';    % !!
cfg.grid.resolution         = 10;       % in mm
cfg.grid.nonlinear          = 'yes';    % use non-linear normalization
cfg.grid.unit               = 'mm';

cfg.mri                     = mri;
grid                        = ft_prepare_sourcemodel(cfg);

cfg.mri						= mri_ft;
grid_ft						= ft_prepare_sourcemodel(cfg);

% Now we create our own headmodels with our own segmentation and compare
% them with the warpmni output

cfg                         = [];
cfg.dim                     = mri.dim;
% cfg.yrange                  = [-149.5 149.5];
mri_res                     = ft_volumereslice(cfg,mri);

cfg.dim                     = mri_ft.dim;
mri_ft_res                  = ft_volumereslice(cfg,mri_ft);
% ft_sourceplot([], mri_res);
% ft_sourceplot([], mri_ft_res);

cfg                         = [];
cfg.output                  = {'gray', 'white', 'csf','skull','scalp'};
segmentedmri                = ft_volumesegment(cfg,mri_res);
segmentedmri_ft             = ft_volumesegment(cfg,mri_ft_res);

% seg_i = ft_datatype_segmentation(segmentedmri,'segmentationstyle','indexed');
% seg_ft_i = ft_datatype_segmentation(segmentedmri_ft,'segmentationstyle','indexed');
% cfg              = [];
% cfg.funparameter = 'seg';
% cfg.funcolormap  = lines(6); 
% cfg.location     = 'center';
% cfg.atlas        = seg_i;    
% ft_sourceplot(cfg, seg_i);
% cfg.atlas        = seg_ft_i;    
% ft_sourceplot(cfg, seg_ft_i);

cfg        = [];
cfg.shift  = 0.3;
cfg.method = 'hexahedral';
mesh = ft_prepare_mesh(cfg,segmentedmri);
mesh_ft = ft_prepare_mesh(cfg,segmentedmri_ft);

cfg        = [];
cfg.method ='simbio';
cfg.conductivity = [0.33 0.14 1.79 0.01 0.43];   % order follows mesh.tissyelabel
vol        = ft_prepare_headmodel(cfg, mesh);  
vol_ft       = ft_prepare_headmodel(cfg, mesh_ft);

cfg                         = [];
% 	cfg.mri                     = ft_read_mri(abpath(subjdata(iSj).mri_reg), 'datatype', 'nifti');
cfg.grid.resolution         = 10;       % in mm
cfg.grid.unit               = 'mm';

cfg.headmodel				= vol;
grid_seg                    = ft_prepare_sourcemodel(cfg);

cfg.headmodel				= vol_ft;
grid_ft_seg                 = ft_prepare_sourcemodel(cfg);

figure
subplot(1,2,1);
ft_plot_mesh(grid_ft.pos(grid_ft.inside,:), 'vertexcolor', 'red');
ft_plot_mesh(grid_ft_seg.pos(grid_ft_seg.inside,:), 'vertexcolor', 'green');

subplot(1,2,2);
ft_plot_mesh(grid.pos(grid.inside,:), 'vertexcolor', 'red');
ft_plot_mesh(grid_seg.pos(grid_seg.inside,:), 'vertexcolor', 'green');

