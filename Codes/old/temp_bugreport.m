%% ---------------------	BUGREPORT 1		
% Differences in ft_connectivityanalysis output

%% Preparation
% load
freq = load_file(abpath('Y:\Jens\Reactivated Connectivity\homes\sourceanalysis 1.0\rs_tfr\s5_n1_rs1-3_tfr.mat'));
freq =  freq{15};
freq.fourierspctrm  = permute(freq.fourierspctrm, [4 2 3 1]);
freq.dimord         = 'rpttap_chan_freq'; % rpt_chan_freq leads to terrible fieldtrip failure (ft_sourceanalysis, line 630) and hours of troubleshooting..
freq.cumtapcnt      = ones(size(freq.fourierspctrm,1),1);
freq                = rmfield(freq, 'time');
freq.label			= freq.label';
freq				= rmfield(freq, {'cond', 'nid'});

% now data looks like every other freq structure (like in the whole brain
% network tutorial). lets subselect 10 trials to make the data more handy.
cfg					= [];
cfg.trials			= 1:10;
freq				= ft_selectdata(cfg,freq);
realsave('/gpfs01/born/group/Jens/Reactivated Connectivity/bugreport 1/freq.mat', freq)


grid						= load_file(abpath('Y:\Jens\Reactivated Connectivity\homes\headmodels 1.1\subject-specific grids\s5_grid_10mm.mat'));        % previously computed grid
vol							= load_file(abpath('Y:\Jens\Reactivated Connectivity\homes\headmodels 1.1\prepared\s5_n1_scalp.15_simbio_fem_prep.mat'));   % previously computed volume conduction model
elec						= load_file(abpath('Y:\Jens\Reactivated Connectivity\homes\headmodels 1.1\projected electrodes\prepared\s5_n1_scalp.15_simbio_fem_elecs_proj_prep.mat'));
realsave('/gpfs01/born/group/Jens/Reactivated Connectivity/bugreport 1/source.mat', source)
realsave('/gpfs01/born/group/Jens/Reactivated Connectivity/bugreport 1/grid.mat', grid)
realsave('/gpfs01/born/group/Jens/Reactivated Connectivity/bugreport 1/elec.mat', elec)
realsave('/gpfs01/born/group/Jens/Reactivated Connectivity/bugreport 1/vol.mat', vol)



cfg							= [];
cfg.method					= 'pcc';
cfg.grid					= grid;
cfg.headmodel				= vol;  
cfg.elec					= elec;
cfg.keeptrials				= 'yes';
cfg.pcc.realfilter			= 'yes';		
cfg.pcc.fixedori			= 'yes';
source						= ft_sourceanalysis(cfg, freq);
source						= ft_sourcedescriptives([], source);

realsave('/gpfs01/born/group/Jens/Reactivated Connectivity/bugreport 1/source.mat', source)

%% Bug report code

% compute connectivity
cfg					= [];
cfg.method			= 'coh';
cfg.complex			= 'absimag';
source_coh			= ft_connectivityanalysis(cfg, source);

cfg					= [];
cfg.method			= 'plv';
source_plv			= ft_connectivityanalysis(cfg, source);

cfg					= [];
cfg.method			= 'powcorr_ortho';
source_pco			= ft_connectivityanalysis(cfg, source);

save('source_coh', 'source_coh')
save('source_plv', 'source_plv')
save('source_pco', 'source_pco')

%% Result	
% 
% source_coh = 
% 
%           dim: [18 21 18]
%        inside: [3294x1 double]
%           pos: [6804x3 double]
%       outside: [3510x1 double]
%     cohspctrm: [6804x6804 double]
%        dimord: 'pos_pos_freq'
%          freq: 7.9828
%           cfg: [1x1 struct]
% 
% source_plv = 
% 
%           dim: [18 21 18]
%        inside: [3294x1 double]
%           pos: [6804x3 double]
%       outside: [3510x1 double]
%     plvspctrm: [6804x6804 double]
%        dimord: 'pos_pos_freq'
%          freq: 7.9828
%           cfg: [1x1 struct]
% 
% source_pco = 
% 
%               dim: [18 21 18]
%            inside: [6804x1 logical]
%               pos: [6804x3 double]
%     powcorrspctrm: [3294x3294 double]
%            dimord: '{pos}_ori'
%               cfg: [1x1 struct]

%% ---------------------	BUGREPORT 2
cd(abpath('Y:\Jens\Reactivated Connectivity\bugreport 1'));

% mri				= ft_read_mri(fullfile(path_root, 'fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));
% source			= load_file('source.mat');
sourcemodel = load_file(fullfile(path_root, 'fieldtrip','template', 'sourcemodel', 'standard_sourcemodel3d10mm.mat')); % 
atlas			= ft_read_atlas(fullfile(path_root, 'fieldtrip', 'template', 'atlas', 'aal','ROI_MNI_V4.nii')); 

source_pco		= load_file('source_pco_new.mat');

source_pco		= ft_convert_units(source_pco, 'cm'); 
atlas			= ft_convert_units(atlas, 'cm');
sourcemodel		= ft_convert_units(sourcemodel, 'cm');
% mri				= ft_convert_units(mri, 'cm');

% For parcellation we need an atlas that corresponds to our sourcemodel
cfg_int						= [];
cfg_int.interpmethod		= 'nearest';
cfg_int.parameter			= 'tissue';
atlas_templ					= ft_sourceinterpolate(cfg_int, atlas, sourcemodel);

% All of these have to be identical
source_pco.pos  = sourcemodel.pos;
atlas_templ.pos = sourcemodel.pos;

% ISSUE 1: The field tissuelabel was dropped during interpolation. if it is
% not present we dont know what the tissue indices mean but also
% ft_checkdata does not recognize the atlas as a parcellation
atlas_templ.tissuelabel			= atlas.tissuelabel; 

% ISSUE 2: ft_sourceparcellation cannot deal with NaNs
atlas_templ.tissue(isnan(atlas_templ.tissue)) = 0;	 

% Now the parcellation works
cfg					= [];
cfg.parcellation	= 'tissue';
cfg.parameter		= 'powcorrspctrm';
source_pco_parc		= ft_sourceparcellate(cfg, source_pco, atlas_templ);
imagesc(source_pco_parc.powcorrspctrm)


%% --------------------------------------------

%% Interpolate source to original MNI MRI
% Source grids were subject-specific mni-warped, so this should be legal:
source.pos		= sourcemodel.pos; 
source.dim		= sourcemodel.dim;
source.coordsys = 'mni';

% Interpolate source to template
cfg_int                             = [];
cfg_int.parameter                   = 'avg.pow';
source_int							= ft_sourceinterpolate(cfg_int, source, mri);
source_int.coordsys					= 'mni';

%% Interpolate atlas to template - this is possible but not needed
cfg_int                             = [];
cfg_int.interpmethod				= 'nearest';
cfg_int.parameter                   = 'tissue';
atlas_int                           = ft_sourceinterpolate(cfg_int, atlas, mri);

% There are some weird fixes needed
atlas_int.tissuelabel				= atlas.tissuelabel; % both fields tissue- and anatomylabel are
atlas_int.anatomylabel				= atlas.tissuelabel; % needed for use it in ft_sourceplot
atlas_int.coordsys					= 'mni';			 % ... as well as the coordsys
atlas_int.tissue(isnan(atlas_int.tissue)) = 0;			 % this is needed for directly plotting the atlas (and then it will find twice as many ROIs..)


% The atlas can now be used both, interpolated and non-interpolated
cfg						= [];
cfg.method				= 'slice';
cfg.funparameter		= 'tissue';
cfg.funcolormap			= 'jet';
ft_sourceplot(cfg, atlas_int); % only works if there are no NaNs in .tissue

cfg						= [];
cfg.method				= 'surface';
cfg.funparameter		= 'pow';
cfg.roi					= {'SupraMarginal_R','Angular_L','Angular_R','Precuneus_L','Precuneus_R','Vermis_9', 'Temporal_Pole_Mid_L', 'Temporal_Pole_Mid_R'};
cfg.atlas				= atlas_int; % this also works without interpolating the atlas
ft_sourceplot(cfg, source_int);

%% DONE UP TO HERE

atlas = ft_read_atlas(fullfile(path_root, 'fieldtrip', 'template', 'atlas', 'aal','ROI_MNI_V4.nii')); 

% get the mask - this is magically done without an interpolation
% tmpcfg          = [];
% tmpcfg.roi      = 'Vermis_9';
% tmpcfg.atlas    = atlas;
% tmpcfg.inputcoord = 'mni';
% roi = ft_volumelookup(tmpcfg,source_int);




atlas.pos = source_conn.pos; % otherwise the parcellation won't work

cfg = [];
cfg.parcellation = 'parcellation';
cfg.parameter    = 'cohspctrm';
parc_conn = ft_sourceparcellate(cfg, source_conn, atlas);



