% data.pow(1:length(data.avg.mom)) = NaN;
% for i = 1:length(data.avg.mom)
% 	if ~isempty(data.avg.mom{i})
% 		data.pow(i) = mean(arrayfun(@(x) real(x)^2, data.avg.mom{i}));
% 	end
% end % that didnt give the same results as ft_sourcedescriptives which
% uses the CSD to calculate power (which makes a lot of sense...)

%% LOAD AND PLOT SOURCES
files{1} = abpath(fullfile(path_root, 'homes\sourceanalysis 1.0\rs_tfr\sources\s5_n1_rs1-3_tfr_sources_freq19.mat'));
files{2} = abpath(fullfile(path_root, 'homes\sourceanalysis 1.0\rs_tfr\sources\s5_n2_rs1-3_tfr_sources_freq19.mat'));
files{3} = abpath(fullfile(path_root, 'homes\sourceanalysis 1.0\rs_tfr\sources\s13_n1_rs1-3_tfr_sources_freq19.mat'));
files{4} = abpath(fullfile(path_root, 'homes\sourceanalysis 1.0\rs_tfr\sources\s13_n2_rs1-3_tfr_sources_freq19.mat'));
	mri_mni				= ft_read_mri(fullfile(path_root, 'fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));
	sourcemodel			= load_file(abpath('/gpfs01/born/group/Jens/Reactivated Connectivity/fieldtrip/template/sourcemodel/standard_sourcemodel3d10mm.mat'));

for iFile = 1:numel(files)	
	data = load_file(files{iFile});
	
	data1 = data{1,1};
% 	data2 = data{1,2};
% 	data3 = data{1,3};
	
	data1.pos			= sourcemodel.pos;
% 	data2.pos			= sourcemodel.pos;
% 	data3.pos			= sourcemodel.pos;
	
	cfg = [];
	cfg.parameter = 'nai';
	% cfg.interpmethod = 'nearest';
	data1_int = ft_sourceinterpolate(cfg, data1, mri_mni);
% 	data2_int = ft_sourceinterpolate(cfg, data2, mri_mni);
% 	data3_int = ft_sourceinterpolate(cfg, data3, mri_mni);
	
	% Plot and save
	filepath	= enpath(abpath(fullfile(path_root, 'homes\sourceanalysis 1.0\rs_tfr\sources\plots')));
	[~,name,~]	= fileparts(files{iFile});
	
	cfg = [];
	cfg.method = 'slice';
	cfg.funparameter = 'nai';
	cfg.funcolormap = 'jet';
	cfg.funcolorlim = [0 5];
	
	ft_sourceplot(cfg, data1_int)
	set(gcf,'units','normalized','outerposition',[0 0 1 1])
	export_fig(fullfile(filepath, [name '_plot_rs1_slice.png']),  '-m2', '-nocrop')
	close all
% 	ft_sourceplot(cfg, data2_int)
% 	set(gcf,'units','normalized','outerposition',[0 0 1 1])
% 	export_fig(fullfile(filepath, [name '_plot_rs2_slice.png']),  '-m2', '-nocrop')
% 	close all
% 	ft_sourceplot(cfg, data3_int)
% 	set(gcf,'units','normalized','outerposition',[0 0 1 1])
% 	export_fig(fullfile(filepath, [name '_plot_rs3_slice.png']),  '-m2', '-nocrop')
% 	close all
	
	cfg = [];
	cfg.method = 'surface';
	cfg.surffile = 'surface_pial_left.mat';
	cfg.funcolorlim = [0 5];
	cfg.funcolormap = 'jet';
	cfg.funparameter = 'nai';
	
	ft_sourceplot(cfg, data1_int)
	set(gcf,'units','normalized','outerposition',[0 0 1 1])
	material([.3 .4 .3 1])
	view([130 -30 40])
	export_fig(fullfile(filepath, [name '_plot_rs1_surf.png']),  '-m2', '-nocrop')
	close all
% 	ft_sourceplot(cfg, data2_int)
% 	set(gcf,'units','normalized','outerposition',[0 0 1 1])
% 	material([.3 .4 .3 1])
% 	view([130 -30 40])
% 	export_fig(fullfile(filepath, [name '_plot_rs2_surf.png']),  '-m2', '-nocrop')
% 	close all
% 	ft_sourceplot(cfg, data3_int)
% 	set(gcf,'units','normalized','outerposition',[0 0 1 1])
% 	material([.3 .4 .3 1])
% 	view([130 -30 40])
% 	export_fig(fullfile(filepath, [name '_plot_rs3_surf.png']),  '-m2', '-nocrop')
% 	close all
end

%% LOAD AND PLOT CONNECTIVITIES
files{1} = abpath(fullfile(path_root, 'homes\sourceanalysis 1.0\rs_tfr\sources\connectivities\s5_n1_rs1-3_tfr_sources_freq19.mat'));
files{2} = abpath(fullfile(path_root, 'homes\sourceanalysis 1.0\rs_tfr\sources\connectivities\s5_n2_rs1-3_tfr_sources_freq19.mat'));
files{3} = abpath(fullfile(path_root, 'homes\sourceanalysis 1.0\rs_tfr\sources\connectivities\s13_n1_rs1-3_tfr_sources_freq19.mat'));
files{4} = abpath(fullfile(path_root, 'homes\sourceanalysis 1.0\rs_tfr\sources\connectivities\s13_n2_rs1-3_tfr_sources_freq19.mat'));
filepath = enpath(abpath(fullfile(path_root, 'homes\sourceanalysis 1.0\rs_tfr\sources\connectivities\plots')));
filepath_net = enpath(abpath(fullfile(path_root, 'homes\sourceanalysis 1.0\rs_tfr\sources\connectivities\net plots')));

atlas					= ft_read_atlas(fullfile(path_root, 'fieldtrip/template/atlas/aal/ROI_MNI_V4.nii'));
template_grid			= load_file(fullfile(path_root, 'fieldtrip', 'template', 'sourcemodel', 'standard_sourcemodel3d10mm.mat'));
atlas					= ft_convert_units(atlas, 'cm');
template_grid			= ft_convert_units(template_grid, 'cm');

cfg						= [];
cfg.parameter			= 'tissue';
cfg.interpmethod		= 'nearest';
atlas_int				= ft_sourceinterpolate(cfg,atlas, template_grid);
atlas_int.coordsys		= 'mni';
atlas_int.pos			= template_grid.pos;
names = {'5-n1', '5-n2', '13-n1', '13-n2'};

for iFile = 1:numel(files)
	data				= load_file(files{iFile});
	
	data1				= data{1};
	data2				= data{2};
	data3				= data{3};
	
	data1				= ft_convert_units(data1, 'cm');
	data2				= ft_convert_units(data2, 'cm');
	data3				= ft_convert_units(data3, 'cm');
	
	data1.pos			= sourcemodel.pos;
	data2.pos			= sourcemodel.pos;
	data3.pos			= sourcemodel.pos;
	
% 	cfg					= [];
% 	cfg.parcellation	= 'tissue';
% 	cfg.parameter		= 'powcorrspctrm';
% 	cfg.method			= 'maxabs';
% 	data1_maxabs		= ft_sourceparcellate(cfg, data1, atlas_int);
% 	data2_maxabs		= ft_sourceparcellate(cfg, data2, atlas_int);
% 	data3_maxabs		= ft_sourceparcellate(cfg, data3, atlas_int);
% 	
	cfg					= [];
	cfg.parcellation	= 'tissue';
	cfg.parameter		= 'powcorrspctrm';
	cfg.method			= 'mean';
	data1_mean			= ft_sourceparcellate(cfg, data1, atlas_int);
	data2_mean			= ft_sourceparcellate(cfg, data2, atlas_int);
	data3_mean			= ft_sourceparcellate(cfg, data3, atlas_int);
	
% 	cfg					= [];
% 	cfg.parcellation	= 'tissue';
% 	cfg.parameter		= 'powcorrspctrm';
% 	cfg.method			= 'max';
% 	data1_max           = ft_sourceparcellate(cfg, data1, atlas_int);
% 	data2_max           = ft_sourceparcellate(cfg, data2, atlas_int);
% 	data3_max           = ft_sourceparcellate(cfg, data3, atlas_int);
	
	cfg					= [];
	cfg.method			= 'degrees';
	cfg.parameter		= 'powcorrspctrm';
	cfg.threshold		= .05;
	network_data1_mean  = ft_networkanalysis(cfg,data1_mean);
	network_data2_mean  = ft_networkanalysis(cfg,data2_mean);
	network_data3_mean  = ft_networkanalysis(cfg,data3_mean);
	
	cfg					= [];
	cfg.parameter		= 'degrees';
	% cfg.interpmethod   = 'nearest';
	network_data1_mean	= ft_sourceinterpolate(cfg, network_data1_mean, mri_mni);
	network_data2_mean	= ft_sourceinterpolate(cfg, network_data2_mean, mri_mni);
	network_data3_mean	= ft_sourceinterpolate(cfg, network_data3_mean, mri_mni);
	
	cfg					= [];
	cfg.method			= 'slice';
	cfg.funparameter	= 'degrees';
	cfg.funcolormap		= 'jet';
	% 	cfg.funcolorlim		= [0 5];
	
% 	ft_sourceplot(cfg, network_data1_mean)
% 	set(gcf,'units','normalized','outerposition',[0 0 1 1])
% 	export_fig(fullfile(filepath_net, [name '_plot_rs1_net_slice.png']),  '-m2', '-nocrop')
% 	close all
% 	
% 	ft_sourceplot(cfg, network_data2_mean)
% 	set(gcf,'units','normalized','outerposition',[0 0 1 1])
% 	export_fig(fullfile(filepath_net, [name '_plot_rs2_net_slice.png']),  '-m2', '-nocrop')
% 	close all
% 	
% 	ft_sourceplot(cfg, network_data3_mean)
% 	set(gcf,'units','normalized','outerposition',[0 0 1 1])
% 	export_fig(fullfile(filepath_net, [name '_plot_rs3_net_slice.png']),  '-m2', '-nocrop')
% 	close all
	
	cfg = [];
	cfg.method = 'surface';
	cfg.surffile = 'surface_pial_left.mat';
% 	cfg.funcolorlim = [0 5];
	cfg.funcolormap = 'jet';
	cfg.funparameter  = 'degrees';
	
	ft_sourceplot(cfg, network_data1_mean), 
	material([.3 .4 .3 1])
	view([130 -30 40])
	set(gcf,'units','normalized','outerposition',[0 0 1 1])
	export_fig(fullfile(filepath_net, [name '_plot_rs1_net_surf.png']),  '-m2', '-nocrop')
	close all
	
	ft_sourceplot(cfg, network_data2_mean), 
	material([.3 .4 .3 1])
	view([130 -30 40])
	set(gcf,'units','normalized','outerposition',[0 0 1 1])
	export_fig(fullfile(filepath_net, [name '_plot_rs2_net_surf.png']),  '-m2', '-nocrop')
	close all
	
	ft_sourceplot(cfg, network_data3_mean), 
	material([.3 .4 .3 1])
	view([130 -30 40])
	set(gcf,'units','normalized','outerposition',[0 0 1 1])
	export_fig(fullfile(filepath_net, [name '_plot_rs3_net_surf.png']),  '-m2', '-nocrop')
	close all
	
% 	t = atlas_int.tissue~=0;
% 	
% 	figure, imagesc(data1.powcorrspctrm(t(:),t(:))), colorbar, caxis([-.02 0.11]), title([names{iFile} '-rs1 raw']), tit = get(gca,'Title'); export_fig(fullfile(filepath, 'raw', [tit.String '.png']), '-nocrop', '-m2');close all
% 	figure, imagesc(data1_mean.powcorrspctrm), colorbar, caxis([0 0.1]), title([names{iFile} '-rs1 mean']), tit = get(gca,'Title'); export_fig(fullfile(filepath,'mean',[tit.String '.png']), '-nocrop', '-m2');close all
% 	figure, imagesc(data1_max.powcorrspctrm), colorbar, caxis([0 0.16]), title([names{iFile} '-rs1 max']), tit = get(gca,'Title'); export_fig(fullfile(filepath,'max',[tit.String '.png']), '-nocrop', '-m2');close all
% 	figure, imagesc(data1_maxabs.powcorrspctrm), colorbar, caxis([0 0.15]), title([names{iFile} '-rs1 maxabs']), tit = get(gca,'Title'); export_fig(fullfile(filepath,'maxabs',[tit.String '.png']), '-nocrop', '-m2');close all
% 	
% 	figure, imagesc(data2.powcorrspctrm(t(:),t(:))), colorbar, caxis([-.02 0.11]), title([names{iFile} '-rs2 raw']), tit = get(gca,'Title'); export_fig(fullfile(filepath,'raw', [tit.String '.png']), '-nocrop', '-m2');close all
% 	figure, imagesc(data2_mean.powcorrspctrm), colorbar, caxis([0 0.1]), title([names{iFile} '-rs2 mean']), tit = get(gca,'Title'); export_fig(fullfile(filepath,'mean',[tit.String '.png']), '-nocrop', '-m2');close all
% 	figure, imagesc(data2_max.powcorrspctrm), colorbar, caxis([0 0.16]), title([names{iFile} '-rs2 max']), tit = get(gca,'Title'); export_fig(fullfile(filepath,'max',[tit.String '.png']), '-nocrop', '-m2');close all
% 	figure, imagesc(data2_maxabs.powcorrspctrm), colorbar, caxis([0 0.15]), title([names{iFile} '-rs2 maxabs']), tit = get(gca,'Title'); export_fig(fullfile(filepath,'maxabs',[tit.String '.png']), '-nocrop', '-m2');close all
% 	
% 	figure, imagesc(data3.powcorrspctrm(t(:),t(:))), colorbar, caxis([-.02 0.11]), title([names{iFile} '-rs3 raw']), tit = get(gca,'Title'); export_fig(fullfile(filepath,'raw', [tit.String '.png']), '-nocrop', '-m2');close all
% 	figure, imagesc(data3_mean.powcorrspctrm), colorbar, caxis([0 0.1]), title([names{iFile} '-rs3 mean']), tit = get(gca,'Title'); export_fig(fullfile(filepath,'mean',[tit.String '.png']), '-nocrop', '-m2');close all
% 	figure, imagesc(data3_max.powcorrspctrm), colorbar, caxis([0 0.16]), title([names{iFile} '-rs3 max']), tit = get(gca,'Title'); export_fig(fullfile(filepath,'max',[tit.String '.png']), '-nocrop', '-m2');close all
% 	figure, imagesc(data3_maxabs.powcorrspctrm), colorbar, caxis([0 0.15]), title([names{iFile} '-rs3 maxabs']), tit = get(gca,'Title'); export_fig(fullfile(filepath,'maxabs',[tit.String '.png']), '-nocrop', '-m2');close all
	
end


