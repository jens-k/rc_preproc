function rc_connectivityanalysis(cfg)
% Wrapper function for ft_connectivityanalysis for use with qsub. Very
% custom-build for the reactivated connectivity project.
%
% INPUT VARIABLES:
% cfg		cfg to be forwarded to ft_connectivityanalysis; should have
%			cfg.method
%
% Required subfields:
% cfg.params.inputfile		path to data; is required to be source data or 
%							a 3x1 cell containing source data
% cfg.params.outputfile		path to desired outputfile
%
% The cfg must have additional fields with parameters for this wrapper
% function in cfg.params.
data						= load_file(cfg.params.inputfile);
conns						= cell(numel(data), 1);	% here were gonna save the connectivity results

if ~iscell(data)
	error('Not sure what kind of data that is.')
elseif numel(data) == 2
	conn_names	= {'odor', 'vehicle'}; % adhering to condition coding in rc_freqanalysis_sleep
elseif numel(data) == 3
	conn_names	= {'rs1', 'rs2', 'rs3'};
else
	error('Unexpected data.')
end

[s, n]					= idparts(cfg.params.inputfile); % ... or the filename
for iCond = 1:numel(data)
	conns{iCond}			= ft_connectivityanalysis(cfg, data{iCond});
	
	% Add some metadata to the results
	if isfield(data{iCond}, 'nid')
		conns{iCond}.nid		= data{iCond}.nid; % prefer id in the data over the filename
	else
		conns{iCond}.nid		= [s '_n' num2str(n)];
	end
	conns{iCond}.id			= s; % also add filename id
	conns{iCond}.cond		= conn_names{iCond};
end

if numel(conns) == 1, conns = conns{1}; end % for sleep we dont need it packed in a cell
realsave(cfg.params.outputfile, conns);
clear conns data

end


