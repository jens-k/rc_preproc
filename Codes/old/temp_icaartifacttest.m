% Load original data, do filtering
cfg=[]; 
cfg.dataset=abpath(subjdata(10).rs1{2});
cfg.channel						= 'E63';
cfg.trialfun                    = 'trialfun_rs';
cfg.trialdef.post_start         = 4;        % secs to start after the start trigger
cfg.trialdef.pre_end            = 4;        % secs to end before end trigger
cfg.trialdef.segment_length     = 0;        % length of time window to cut data to (in sec)
cfg.trialdef.explength          = 60 * 10;  % expected length of recording in sec (optional)
cfg.trialdef.cut_breaks			= false;	 % cut out breaks or not (e.g. if you handle them later as artifacts)
cfg.trialdef.pre_break			= 10;		 % secs to stop before break trigger
cfg.trialdef.post_break			= 10;		 % secs to start again after break trigger
cfg.id							= 's25_n2_rs1';
cfg.counter						= 1;
cfg								= ft_definetrial(cfg);

data_raw						= ft_preprocessing(cfg);

cfg.bpfilter					= 'yes';
cfg.bpfreq						= [0.2 180]; 
cfg.bpfilttype					= 'fir'; 
cfg.bpfiltdir					= 'twopass';
cfg.padding						= 600; 
data_bp							= ft_preprocessing(cfg);

% Plot both
cfg = []; 
cfg.viewmode = 'vertical'; 
cfg.blocksize = 67; 
cfg.preproc.detrend = 'yes';
ft_databrowser(cfg, data_raw)

cfg = [];
cfg.viewmode = 'vertical'; 
cfg.blocksize = 67; 
ft_databrowser(cfg, data_bp)


% Procedure before ICA
cfg_re							= [];
cfg_re.resamplemethod			= 'downsample';
cfg_re.resamplefs				= 500;
cfg_re.detrend					= 'no';
data_re							= ft_resampledata(cfg_re, data_bp);

cfg_pp							= [];
cfg_pp.hpfilter					= 'yes';
cfg_pp.hpfreq					= 1;
cfg_pp.padding					= 600;
data_final						= ft_preprocessing(cfg_pp, data_re);

cfg = [];
cfg.viewmode = 'vertical'; 
cfg.blocksize = 67; 
ft_databrowser(cfg, data_final)
