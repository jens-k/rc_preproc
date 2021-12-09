%% Testscript for bem vs. fem headmodels
% Headmodels are already created and prepared (transfer matrix, number of electrodes in that particular recording etc.)

%% Beamforming

cd(abpath('/gpfs01/born/group/Jens/Reactivated Connectivity/homes/headmodeltest'));

tfr						= load_file('tfr.mat');
tfr.fourierspctrm   = permute(tfr.fourierspctrm, [4 2 3 1]);
tfr.dimord          = 'rpttap_chan_freq'; % rpt_chan_freq leads to terrible fieldtrip failure (ft_sourceanalysis, line 630) and hours of troubleshooting..
tfr.cumtapcnt       = ones(size(tfr.fourierspctrm,1),1);
tfr                 = rmfield(tfr, 'time');

grid						= load_file('s5_grid.mat');        % previously computed grid
vol_fem						= load_file('s5_fem_prep.mat');    % previously computed volume conduction model
elec_fem					= load_file('s5_elec_proj_fem.mat'); % electrodes projected onto the model
vol_bem						= load_file('s5_bem.mat');    % previously computed volume conduction model
elec_bem					= load_file('s5_elec_proj_bem.mat'); % electrodes projected onto the model

%% Preprare leadfields
cfg							= [];
cfg.headmodel				= vol_bem;
cfg.elec 					= elec_bem;
cfg.grid					= grid;
lf_bem						= ft_prepare_leadfield(cfg, tfr);

cfg.headmodel				= vol_fem;
cfg.elec 					= elec_fem;
lf_fem						= ft_prepare_leadfield(cfg, tfr);

%% Source analysis
cfg							= [];
cfg.method					= 'pcc';
% cfg.grid					= grid;
cfg.keeptrials				= 'yes';
cfg.pcc.realfilter			= 'yes';		% use only the real part of the filter
cfg.pcc.fixedori			= 'yes';        % TODO: check if that actually changes the filter and how hipp did it
cfg.pcc.lambda				= '5%';
cfg.pcc.projectnoise		= 'yes';		% TODO: Project noise? Then we can calculate the NAI later...

cfg.grid					= lf_bem;
cfg.headmodel				= vol_bem;  % the actual leadfield is computed quickly on the fly
cfg.elec					= elec_bem;
sources_bem					= ft_sourceanalysis(cfg, tfr);
sources_bem.cond			= tfr.cond;
sources_bem.nid				= tfr.nid;

cfg.grid					= lf_fem;
cfg.headmodel				= vol_fem;  % the actual leadfield is computed quickly on the fly
cfg.elec					= elec_fem;
sources_fem					= ft_sourceanalysis(cfg, tfr);
sources_fem.cond			= tfr.cond;
sources_fem.nid				= tfr.nid;

cfg_sel=[]; cfg_sel.trials = (sources_bem.cond == 1);
sources_bem_1 = ft_selectdata(cfg_sel, sources_bem);
sources_fem_1 = ft_selectdata(cfg_sel, sources_fem);

cfg_sel=[]; cfg_sel.trials = (sources_bem.cond == 2);
sources_bem_2 = ft_selectdata(cfg_sel, sources_bem);
sources_fem_2 = ft_selectdata(cfg_sel, sources_fem);

cfg_sel=[]; cfg_sel.trials = (sources_bem.cond == 3);
sources_bem_3 = ft_selectdata(cfg_sel, sources_bem);
sources_fem_3 = ft_selectdata(cfg_sel, sources_fem);

sources_bem_1.cond = []; sources_bem_2.cond = []; sources_bem_3.cond = [];
sources_fem_1.cond = []; sources_fem_2.cond = []; sources_fem_3.cond = [];

% COMPARE LEADFIELD SOURCES WITH ORIGINAL SOURCES: Done, same!

cfg_sd = []; cfg_sd.keepcsd = 'yes'; cfg_sd.keepnoisecsd = 'yes';
sources_bem_1 = ft_sourcedescriptives(cfg_sd,sources_bem_1); % computes the NAI and power averaged across trials
sources_bem_2 = ft_sourcedescriptives(cfg_sd,sources_bem_2);
sources_bem_3 = ft_sourcedescriptives(cfg_sd,sources_bem_3);
sources_fem_1 = ft_sourcedescriptives(cfg_sd,sources_fem_1);
sources_fem_2 = ft_sourcedescriptives(cfg_sd,sources_fem_2);
sources_fem_3 = ft_sourcedescriptives(cfg_sd,sources_fem_3);

%% Plotting

sourcemodel			= load_file(fullfile(path_root,'fieldtrip','template','sourcemodel','standard_sourcemodel3d10mm.mat'));
mri					= ft_read_mri(fullfile(path_root,'fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));

sources_bem_1.pos	= sourcemodel.pos;
sources_bem_2.pos	= sourcemodel.pos;
sources_bem_3.pos	= sourcemodel.pos;
sources_fem_1.pos	= sourcemodel.pos;
sources_fem_2.pos	= sourcemodel.pos;
sources_fem_3.pos	= sourcemodel.pos;

cfg_int             = [];
cfg_int.downsample  = 1;           % default: 1 (no downsampling)
cfg_int.parameter   = 'all';
source_bem_1_int	= ft_sourceinterpolate(cfg_int, sources_bem_1, mri);
source_bem_2_int    = ft_sourceinterpolate(cfg_int, sources_bem_2, mri);
source_bem_3_int    = ft_sourceinterpolate(cfg_int, sources_bem_3, mri);
source_fem_1_int    = ft_sourceinterpolate(cfg_int, sources_fem_1, mri);
source_fem_2_int    = ft_sourceinterpolate(cfg_int, sources_fem_2, mri);
source_fem_3_int    = ft_sourceinterpolate(cfg_int, sources_fem_3, mri);

cfg					= [];
cfg.method			= 'slice';
cfg.funparameter	= 'nai';
cfg.funcolormap		= 'jet';
% cfg.funcolorlim		= [0.25 0.55];
ft_sourceplot(cfg,source_bem_1_int)
ft_sourceplot(cfg,source_fem_1_int)

%% Calculate amplitude of each source point's leadfield
ampl_bem = {}; 
ampl_bem = nan(size(lf_bem.pos,1),1);
for iSource = 1:size(lf_bem.pos,1)
	if ~isnan(lf_bem.leadfield{iSource})
		ampl_bem(iSource) = sqrt(sum(lf_bem.leadfield{iSource}(:).^2));
	end
end
ampl_fem = {};
ampl_fem = nan(size(lf_fem.pos,1),1);
for iSource = 1:size(lf_fem.pos,1)
	if ~isnan(lf_fem.leadfield{iSource})
		ampl_fem(iSource) = sqrt(sum(lf_fem.leadfield{iSource}(:).^2));
	end
end

leadfields				= sources_bem_1;
% leadfields				= rmfield(leadfields, 'pow');
leadfields.pos			= sourcemodel.pos;
leadfields.ampl_fem		= ampl_fem;
leadfields.ampl_bem		= ampl_bem;

cfg                        = [];
cfg.parameter              = {'ampl_fem', 'ampl_bem', 'pow'};
leadfields_int			   = ft_sourceinterpolate(cfg, leadfields, mri);

cfg = [];
cfg.method = 'slice';
cfg.funparameter = 'ampl_bem';
cfg.funcolorlim = [0 0.1];
ft_sourceplot(cfg,leadfields_int)

cfg = [];
cfg.method = 'slice';
cfg.funparameter = 'nai';
% cfg.funparameter = 'pow';
% cfg.funcolorlim = [0 1e13];
ft_sourceplot(cfg, source_fem_1_int)


%% Correlate leadfields



	
%% OLD ----- Comparing leadfields

 
%plotting the correlations
cfg                        = [];
cfg.funparameter           = 'avg.pow';
cfg.nslices                = 12;
cfg.colmax                 = 1;
cfg.colmin                 = 0.8;
cfg.spacemin               = 75;
cfg.spacemax               = 150;
figure;
ft_sliceinterp(cfg,sourceinterp{1});
figure;
ft_sliceinterp(cfg,sourceinterp{2});% etcetera...
%--------------------------------------------------------------------------------------------
%compute the correlations between the different leadfields
%NOTE:to be able to compare them you should recalculate the leadfields with the grid
%specifications for the single-shell model to make the leadfields of comparable sizes: 
%in the cfg for prepare_leadfield the input should contain:
%cfg.grid.xgrid = grid_singleshell.xgrid;
%cfg.grid.ygrid = grid_singleshell.ygrid;
%cfg.grid.zgrid = grid_singleshell.zgrid;
%cfg.grid.pos = grid_singleshell.pos;
%cfg.grid.inside = grid_singleshell.inside;
%cfg.grid.outside = grid_singleshell.outside;
%cfg.resolution=[];
%--------------------------------------------------------------------------------------------
comp = {};
for i=1:5
for j=(i+1):5
  disp([i j]);
  a = grid{i};
  b = grid{j};
  comp{i,j} = [];
  comp{i,j}.corrcoef = zeros(grid{5}.dim) * nan;
  for k=a.inside(:)'
    dum = corrcoef(a.leadfield{k}(:), b.leadfield{k}(:));
    comp{i,j}.corrcoef(k) = dum(1,2);
  end
end
end
 
%interpolate the data on an mri for plotting the correlations between the leadfields
mri=ft_read_mri('Subject01.mri');
cfg                 = [];
source              = grid{1};
source.dim          = grid{5}.dim;
sourceinterp        = {};
for i=1:5
  for j=(i+1):5
    source.avg.pow=comp{i,j}.corrcoef;
    sourceinterp{i,j}=ft_sourceinterpolate(cfg,source,mri);
  end
end
 
%plotting the correlations
cfg                 = [];
cfg.funparameter    = 'avg.pow';
cfg.nslices         = 12;
cfg.colmax          = 1;
cfg.colmin          = 0.8;
cfg.spacemin        = 75;
cfg.spacemax        = 150;
figure;
ft_sliceinterp(cfg,sourceinterp{1,2});
figure;
ft_sliceinterp(cfg,sourceinterp{2,3});% etcetera...

