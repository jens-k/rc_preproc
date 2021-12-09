cfg                     = [];
cfg.dataset				= '/gpfs01/born/group/Jens/Nicotest/S14_R2PhdEEG_sess2_RS_20170407_054350.mff';
cfg.bpfilter             = 'yes';
cfg.bpfreq               = [2 180];
data                     = ft_preprocessing(cfg);

cfg                     = [];

cfg.viewmode        = 'vertical';
cfg.channel         = 1:30;     % show some random channels
cfg.blocksize       = 20;
% cfg_art.ylim            = [-120 120];
ft_databrowser(cfg, data)