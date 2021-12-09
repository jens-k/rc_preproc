% wrapper function for ft_componentanalysis
function rc_componentanalysis(cfg)
data						= load(cfg.in);
id							= data.data.id;

cfg_re						= [];
cfg_re.resamplemethod		= 'downsample';
cfg_re.resamplefs			= cfg.resamplefs;
cfg_re.detrend				= 'no';
data						= ft_resampledata(cfg_re, data.data);

cfg_pp						= [];
cfg_pp.hpfilter				= 'yes';
cfg_pp.hpfreq				= cfg.hpfreq;
if isfield(cfg, 'padding')
	cfg_pp.padding				= cfg.padding;
end
data						= ft_preprocessing(cfg_pp, data);

cfg_ica						= [];
cfg_ica.method				= 'runica';
data_ica					= ft_componentanalysis(cfg_ica, data);
data_ica.id					= id;

save(cfg.out, 'data_ica')
end