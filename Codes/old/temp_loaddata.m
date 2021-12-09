
cfg                             = [];
cfg.dataformat                  = 'egi_mff_v2';
cfg.headerformat                = 'egi_mff_v2';
cfg.dataset                     = '/gpfs01/born/group/Jens/EGI_Nico/S05_R2PhdEEG_sleep_20160609_105919.mff';
cfg.dataset                     = 'Z:\Reactivated Connectivity Jens Klinzing\EEG\RC_291_rs1_20161010_105132.mff';
cfg.dataset                     = 'Z:\Reactivated Connectivity Jens Klinzing\EEG\RC_371_rs1_20161120_104559.mff';
cfg.continuous                  = 'yes';
cfg.bpfilter                    = 'yes';
cfg.bpfreq                      = [1 140]; 

data                            = ft_preprocessing(cfg);
% realsave('/gpfs01/born/group/Jens/EGI_Nico/data08.mat', data);
% clear data

cfg                             = [];
cfg.resamplefs                  = 200;
cfg.resamplemethod              = 'resample';   % probably default: filters the data prior to downsampling
cfg.detrend                     = 'no';
data_dn                         = ft_resampledata(cfg, data);
% realsave('/gpfs01/born/group/Jens/EGI_Nico/data08_200Hz.mat', data_dn);
clear data

cfg                             = [];
cfg.method                      = 'summary';
cfg.layout                      = 'egi_corrected.sfp';
cfg.alim                        = 1e-12;
ft_rejectvisual(cfg, data_dn);         
close all

cfg                             = [];
cfg.event                       = ft_read_event('Z:\Reactivated Connectivity Jens Klinzing\EEG\RC_291_rs1_20161010_105132.mff');
cfg.viewmode                    = 'vertical';
cfg.layout                      = 'egi_corrected.sfp';
cfg.channel                     = 1:20;
ft_databrowser(cfg, data_dn)


    