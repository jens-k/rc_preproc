% Adapted from http://www.fieldtriptoolbox.org/tutorial/networkanalysis


%% frequency data is in variable "data"
% ...after re-shaping in main source analysis script
iFreq = 16;

%% identify the indices of trials with high and low alpha power
cfg = [];
cfg.keeptrials = 'yes';
tmp = ft_freqdescriptives(cfg, data{iFreq});

chanind = find(mean(tmp.powspctrm,1)==max(mean(tmp.powspctrm,1)));  % find the sensor where power is max
indlow  = find(tmp.powspctrm(:,chanind)<=median(tmp.powspctrm(:,chanind)));
indhigh = find(tmp.powspctrm(:,chanind)>=median(tmp.powspctrm(:,chanind)));

%% compute the power spectrum for the median splitted data
cfg              = [];
cfg.trials       = indlow;
data_low		 = ft_freqdescriptives(cfg, data{iFreq});

cfg.trials       = indhigh;
data_high		 = ft_freqdescriptives(cfg, data{iFreq});

%% compute the difference between high and low
cfg = [];
cfg.parameter = 'powspctrm';
cfg.operation = 'divide';
powratio      = ft_math(cfg, data_high, data_low);

%% plot the topography of the difference along with the spectra
cfg        = [];
cfg.layout = 'egi_corrected.sfp';
% cfg.xlim   = [9.9 10.1];
figure; ft_topoplotER(cfg, powratio); 


%% Beamform the data and save one result per frequency
cfg							= [];
cfg.method					= 'pcc';
cfg.grid					= lf;
cfg.headmodel				= vol;			% the actual leadfield is computed quickly on the fly if not provided
cfg.elec					= elec;
cfg.keeptrials				= 'yes';
cfg.pcc.keepfilter			= 'yes';        % remember the filter, only needed for sanity checks; can be set to 'no' later on
cfg.pcc.realfilter			= 'yes';		% use only the real part of the filter
% cfg.pcc.fixedori			= 'yes';        % TODO: check if that actually changes the filter and how hipp did it
cfg.pcc.lambda				= '5%';
cfg.pcc.projectnoise		= 'yes';		% Project noise - Then we can calculate the NAI later...

sources						= ft_sourceanalysis(cfg, data{iFreq});

tmp_low						= data{iFreq};
tmp_low.fourierspctrm		= data{iFreq}.fourierspctrm(indlow,:);
tmp_low.cumtapcnt			= data{iFreq}.cumtapcnt(indlow,:);

tmp_high					= data{iFreq};
tmp_high.fourierspctrm		= data{iFreq}.fourierspctrm(indhigh,:);
tmp_high.cumtapcnt			= data{iFreq}.cumtapcnt(indhigh,:);

cfg.grid.filter				= sources.avg.filter;
sources_low					= ft_sourceanalysis(cfg, tmp_low);
sources_high					= ft_sourceanalysis(cfg, tmp_high);
% Temp
% cfg_sd		= []; cfg_sd.keepcsd = 'yes'; cfg_sd.keepnoisecsd = 'yes';
% source		= ft_sourcedescriptives(cfg_sd,sources);

% cfg_sel=[]; cfg_sel.trials = indlow; s_low = ft_selectdata(cfg_sel, sources);
% cfg_sel=[]; cfg_sel.trials = indhigh; s_high = ft_selectdata(cfg_sel, sources);

% HERE: THIS PRODUCES ONLY 0s AND NANs - not anymore, right?
cfg_sd		= []; cfg_sd.keepcsd = 'yes'; cfg_sd.keepnoisecsd = 'yes';
sources_highd		= ft_sourcedescriptives(cfg_sd,sources_high);
sources_lowd		= ft_sourcedescriptives(cfg_sd,sources_low);

cfg           = [];
cfg.operation = 'log10(x1)-log10(x2)';
cfg.parameter = 'pow';
source_ratio  = ft_math(cfg, sources_highd, sources_lowd);

% create a fancy mask
source_ratio.mask = (1+tanh(2.*(source_ratio.pow./max(source_ratio.pow(:))-0.5)))./2; 

sourcemodel			= load_file('standard_sourcemodel3d10mm.mat');
mri					= ft_read_mri('single_subj_T1_1mm.nii');
source_ratio.pos			= sourcemodel.pos;
sources_highd.pos			= sourcemodel.pos;

cfg_int             = [];
cfg_int.downsample  = 1;           % default: 1 (no downsampling)
cfg_int.parameter   = {'pow' 'nai' 'noise'};
source_highd_int	= ft_sourceinterpolate(cfg_int, sources_highd, mri);
cfg_int.parameter   = {'pow'};
source_ratio_int	= ft_sourceinterpolate(cfg_int, source_ratio, mri);


cfg = [];
cfg.method        = 'slice';
cfg.funparameter  = 'pow';
% cfg.maskparameter = 'mask';
cfg.funcolorlim   = 'zeromax';
% cfg.funcolormap   = 'jet';
% cfg.colorbar      = 'no';
cfg.surfdownsample = 4;
ft_sourceplot(cfg, source_highd_int);
ft_sourceplot(cfg, source_ratio_int);




cfg=[]; 
cfg.funparameter = 'pow'; 
cfg.method = 'slice'; 
ft_sourceplot(cfg, source_int)





