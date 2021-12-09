
cd(abpath('Y:\Jens\Reactivated Connectivity\network tutorial'));

load('atlas_MMP1.0_4k.mat') % atlas
load('sourcemodel_4k.mat') % DIFF: This just looks completely differentthen my sourcemodels or the ones at template/sourcemodel
load('lf.mat')
load('dataica.mat')
load('hdm')

%% Plot the atlas
figure
cfg               = [];
cfg.method        = 'surface';
cfg.funparameter  = 'parcellation';
% cfg.surffile		= 'surface_white_left.mat';
cfg.funcolormap   = map2; %'jet';

ft_sourceplot(cfg, atlas);

%% visualize the coregistration of sensors, headmodel, and sourcemodel.
% make the headmodel surface transparent
ft_plot_vol(hdm, 'edgecolor', 'none'); alpha 0.4           
ft_plot_mesh(ft_convert_units(sourcemodel, 'cm'), 'vertexcolor',sourcemodel.sulc);
ft_plot_mesh(ft_convert_units(sourcemodel, 'cm'), 'facecolor', 'brain', 'surfaceonly', true);
% ft_plot_sens(datads.grad);
% view([0 -90 0])


%% compute sensor level Fourier spectra, to be used for cross-spectral density computation.
cfg            = [];
cfg.method     = 'mtmfft';
cfg.output     = 'fourier';
cfg.keeptrials = 'yes';
cfg.tapsmofrq  = 1;
cfg.foi        = 10;
freq           = ft_freqanalysis(cfg, dataica);


%% do the source reconstruction
cfg                   = [];
cfg.frequency         = freq.freq;
cfg.method            = 'pcc';
cfg.grid              = lf;
cfg.headmodel         = hdm;
cfg.keeptrials        = 'yes';
cfg.pcc.lambda        = '10%';
cfg.pcc.projectnoise  = 'yes';
cfg.pcc.fixedori      = 'yes';
source = ft_sourceanalysis(cfg, freq);
source = ft_sourcedescriptives([], source); % to get the neural-activity-index


%% plot the neural activity index (power/noise)
cfg               = [];
cfg.method        = 'surface';
cfg.funparameter  = 'nai';
cfg.maskparameter = cfg.funparameter;
cfg.funcolorlim   = [0.0 8];
cfg.opacitylim    = [3 8]; 
cfg.opacitymap    = 'rampup';  
cfg.funcolormap   = 'jet';
cfg.colorbar      = 'no';
ft_sourceplot(cfg, source);
view([-90 30]);
light;

%% compute sensor level single trial power spectra
cfg              = [];
cfg.output       = 'pow';
cfg.method       = 'mtmfft';
cfg.taper        = 'dpss';
cfg.foilim       = [9 11];                          
cfg.tapsmofrq    = 1;             
cfg.keeptrials   = 'yes';
datapow           = ft_freqanalysis(cfg, dataica);

%% identify the indices of trials with high and low alpha power
freqind = nearest(datapow.freq, 10);
tmp     = datapow.powspctrm(:,:,freqind);    
chanind = find(mean(tmp,1)==max(mean(tmp,1)));  % find the sensor where power is max
indlow  = find(tmp(:,chanind)<=median(tmp(:,chanind)));
indhigh = find(tmp(:,chanind)>=median(tmp(:,chanind)));

%% compute the power spectrum for the median splitted data
cfg              = [];
cfg.trials       = indlow; 
datapow_low      = ft_freqdescriptives(cfg, datapow);

cfg.trials       = indhigh; 
datapow_high     = ft_freqdescriptives(cfg, datapow);

%% compute the difference between high and low
cfg = [];
cfg.parameter = 'powspctrm';
cfg.operation = 'divide';
powratio      = ft_math(cfg, datapow_high, datapow_low);

%% plot the topography of the difference along with the spectra
cfg        = [];
cfg.layout = 'CTF275_helmet.mat';
cfg.xlim   = [9.9 10.1];
figure; ft_topoplotER(cfg, powratio);

cfg         = [];
cfg.channel = {'MRO33'};
figure; ft_singleplotER(cfg, datapow_high, datapow_low);

%% compute fourier spectra for frequency of interest according to the trial split
cfg            = [];
cfg.method     = 'mtmfft';
cfg.output     = 'fourier';
cfg.keeptrials = 'yes';
cfg.tapsmofrq  = 1;
cfg.foi        = 10;

cfg.trials = indlow; 
freq_low   = ft_freqanalysis(cfg, dataica);

cfg.trials = indhigh; 
freq_high  = ft_freqanalysis(cfg, dataica);

%% compute the beamformer filters based on the entire data
cfg                   = [];
cfg.frequency         = freq.freq;
cfg.method            = 'pcc';
cfg.grid              = lf;
cfg.headmodel         = hdm;
cfg.keeptrials        = 'yes';
cfg.pcc.lambda        = '10%';
cfg.pcc.projectnoise  = 'yes';
cfg.pcc.keepfilter    = 'yes';
cfg.pcc.fixedori      = 'yes';
source = ft_sourceanalysis(cfg, freq);

% use the precomputed filters 
cfg                   = [];
cfg.frequency         = freq.freq;
cfg.method            = 'pcc';
cfg.grid              = lf;
cfg.grid.filter       = source.avg.filter;
cfg.headmodel         = hdm;
cfg.keeptrials        = 'yes';
cfg.pcc.lambda        = '10%';
cfg.pcc.projectnoise  = 'yes';
source_low  = ft_sourcedescriptives([], ft_sourceanalysis(cfg, freq_low));
source_high = ft_sourcedescriptives([], ft_sourceanalysis(cfg, freq_high));

cfg           = [];
cfg.operation = 'log10(x1)-log10(x2)';
cfg.parameter = 'pow';
source_ratio  = ft_math(cfg, source_high, source_low);

% create a fancy mask
source_ratio.mask = (1+tanh(2.*(source_ratio.pow./max(source_ratio.pow(:))-0.5)))./2; 

cfg = [];
cfg.method        = 'surface';
cfg.funparameter  = 'pow';
cfg.maskparameter = 'mask';
cfg.funcolorlim   = [-.3 .3];
cfg.funcolormap   = 'jet';
cfg.colorbar      = 'no';
ft_sourceplot(cfg, source_ratio); % SOURCES ARE ROTATED COMPARED TO TUTORIAL !!
view([-90 30]);
light('style','infinite','position',[0 -200 200]);

%% -----------      DIFFs
% Comparable structures are: 
% source = I dont have a .tri field; source.avg.csdlabel has 'scandip' in
% every row while we only have it in inside rows; and I did not estimate
% noise. thats it.
% sourcemodel = Is completely different, this sourcemodel has
% tri,sulc,curv,thickness,atlasroi, etc. analogous to used atlas
%
% ft_sourceplot says: If the input source data contains a tri-field (i.e. a
% description of a mesh), no interpolation is needed. If the input source
% data does not contain a tri-field, an interpolation is performed onto a
% specified surface. Note that the coordinate system in which the surface
% is defined should be the same as the coordinate system that is
% represented in source.pos.

%% compute connectivity
cfg         = [];
cfg.method  = 'coh';
cfg.complex = 'absimag';
source_conn = ft_connectivityanalysis(cfg, source);

figure;imagesc(source_conn.cohspctrm);


atlas.pos = source_conn.pos; % otherwise the parcellation won't work

cfg = [];
cfg.parcellation = 'parcellation';
cfg.parameter    = 'cohspctrm';
parc_conn = ft_sourceparcellate(cfg, source_conn, atlas);

figure;imagesc(parc_conn.cohspctrm);







