function rc_prepare_leadfield(cfg)
% Wrapper function for ft_prepare_leadfield for use with qsub. Very
% custom-build for the reactivated connectivity project.
%
% Also joins given data sets and rearranges the result so that it looks
% like independent observations.
%
% INPUT VARIABLES:
% cfg		cfg to be forwarded to ft_prepare_leadfield.
%
% The cfg must have additional fields with parameters for this wrapper
% function:
% cfg.params.data
% cfg.params.grid
% cfg.params.headmodel
% cfg.params.elec
% cfg.params.outputfile

data						= load_file(cfg.params.data);

cfg.grid					= load_file(cfg.params.grid);
cfg.headmodel				= load_file(cfg.params.headmodel);
cfg.elec					= load_file(cfg.params.elec);
cfg.elec.label				= upper(cfg.elec.label);			% just in case of shenanigans
cfg.channel					= cfg.elec.label;
lf							= ft_prepare_leadfield(cfg, data);	% data can be any frequency, leadfield is not data-dependent

realsave(cfg.params.outputfile, lf);



