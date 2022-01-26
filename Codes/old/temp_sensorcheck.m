%% Load TFRs
% data1 = load_file(fullfile(path_root, 'homes', 'preprocessing 1.1', 'resting-state', 'clean', 's13_n1_rs1_0.2-140hz_rej_chrej_icarej_clean.mat'));
% data2 = load_file(fullfile(path_root, 'homes', 'preprocessing 1.1', 'resting-state', 'clean', 's13_n1_rs2_0.2-140hz_rej_chrej_icarej_clean.mat'));

data_tfr = load_file(fullfile(path_root, 'homes', 'sourceanalysis 1.2 alpha', 'rs_tfr', 's5_n1_rs1-3_tfr.mat'));
data_tfr = load_file(fullfile(path_root, 'homes', 'sourceanalysis 1.1 bem', 'rs_tfr', 's13_n1_rs1-3_tfr.mat'));

data_tfr = data_tfr{19};
data_tfr.time = 1:length(data_tfr.time)

%% Plot topo of whole segment (rs 1 and 3 to see drastic differences)
% ft_freqdescriptivse calls ft_selectdata with time = all which
% nevertheless changes the time axis incl. the number of time points
% (ft_selectdata, somewhere beteen line 297 and 377

idx			= find(data_tfr.cond==1);
cfg			= [];
cfg.latency	= [idx(1) idx(end)];
data1		= ft_selectdata(cfg, data_tfr);

idx			= find(data_tfr.cond==2);
cfg			= [];
cfg.latency	= [idx(1) idx(end)];
data2		= ft_selectdata(cfg, data_tfr);

idx			= find(data_tfr.cond==3);
cfg			= [];
cfg.latency	= [idx(1) idx(end)];
data3		= ft_selectdata(cfg, data_tfr);

power1 = ft_freqdescriptives([], data1);
power2 = ft_freqdescriptives([], data2);
power3 = ft_freqdescriptives([], data3);

cfg = [];
% cfg.xlim = [0.9 1.3];                
% cfg.ylim = [15 20];                  
% cfg.zlim = [-1e-27 1e-27];           
% cfg.baseline = [-0.5 -0.1];          
% cfg.baselinetype = 'absolute';
cfg.layout = 'egi_corrected.sfp';
ft_topoplotTFR(cfg,power1); hold off;
figure;ft_topoplotTFR(cfg,power2);
figure;ft_topoplotTFR(cfg,power3);

%% plot power spectrum - TODO


%% Beam it

vol_file = load_file(fullfile(path_root, 'homes','headmodels 1.1','prepared','s13_n1_scalp.10_simbio_fem_prep.mat'));















