function rc_sourceanalysis(cfg)
% Wrapper function for ft_sourceanalysis for use with qsub. Very
% custom-build for the reactivated connectivity project.
%
% INPUT VARIABLES:
% cfg		cfg to be forwarded to ft_freqanalysis.
%
% The cfg must have additional fields with parameters for this wrapper
% function in cfg.params.
outputfile					= cfg.params.outputfile;

% Load all required data
data						= load_file(cfg.params.data);
cfg.headmodel				= load_file(cfg.params.headmodel);
cfg.elec					= load_file(cfg.params.elec);
cfg.elec.label				= upper(cfg.elec.label); % in case of shenanigans
cfg.grid					= load_file(cfg.params.grid); % this can be a leadfield

% One filter for all datapoints, then use it on single conditions
cfg						= rmfield(cfg, 'params');
cfg.keeptrials			= 'no';
filter					= ft_sourceanalysis(cfg, data);

cfg.keeptrials			= 'yes';
cfg.grid.filter			= filter.avg.filter; 
cfg.pcc.fixedori		= 'no';  % this time the filter already only yields one ori per source location
clear filter

sources = cell(1,numel(unique(data.cond)));
for iCond = 1:numel(unique(data.cond))
	cfg_sel				= [];
	cfg_sel.trials		= (data.cond == iCond);
	data_sub			= ft_selectdata(cfg_sel, data);
	sources{iCond}		= ft_sourceanalysis(cfg, data_sub);
	sources{iCond}.cond = iCond;
	sources{iCond}.nid	= data.nid;
end

realsave(outputfile, sources);
clear data sources
