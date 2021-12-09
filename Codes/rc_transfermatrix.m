function rc_transfermatrix(cfg)
% Wrapper for using qsub to calculate transfer matrices.
%
% vol has to be given as the path
% elec has to be the actual structure
%
% AUTHOR:
% Jens Klinzing, jens.klinzing@uni-tuebingen.de
requiredFields = {'vol_path', 'elec', 'nid', 'channel'};
for i = requiredFields
	if ~isfield(cfg,i)
		error(['Required field missing in cfg: ' i{1} '.']);
	end
end

vol			= load_file(cfg.vol_path);
[vol_new, elec_new]     = ft_prepare_vol_sens(vol, cfg.elec, 'order', 10, 'channel', cfg.channel);

vol_new.nid             = cfg.nid;
elec_new.nid            = cfg.nid;
realsave(cfg.result_vol, vol_new);
realsave(cfg.result_elec, elec_new);

end