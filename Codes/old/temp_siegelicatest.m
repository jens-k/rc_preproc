

cfg = []; 
cfg.resamplefs = 200;
cfg.trials = 1:3;
data_new = ft_resampledata(cfg, data);

data1_new = ft_resampledata(cfg, data1);

cfg                     = [];
cfg.viewmode            = 'vertical';
cfg.channel             = 1:60;
ft_databrowser(cfg, data1_filt);
ft_databrowser(cfg, data);

cfg = [];
cfg.channel = {'all', '-E49', '-E48', '-E43', '-E127', '-E126', '-E17', '-E128', '-E32', '-E25', '-E21', '-E14', '-E8', '-E1', '-E125', '-E120', '-E119', '-E113', '-E56', '-E63', '-E68', '-E73', '-E81', '-E88', '-E94', '-E99', '-E107', '-E57', '-E100'};
			  
data1 = ft_selectdata(cfg, data1)
data2 = ft_selectdata(cfg, data2)

cfg = [];
cfg.bpfilter	= 'yes';
cfg.bpfreq		= [25 45];
data1_filt = ft_preprocessing(cfg, data1)
