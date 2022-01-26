function datadir = get_pathdata(system)
% This function returns the correct homedir path for the current system or 
% the system specified by input parameter 'system' ('cluster' or 'office').
%
% This function returns the correct homedir path for the current system.
% This is fully redundant to init_rc, in which the path is defined already
% (Matlab didnt let me do this more elegantly..)
%
% see also get_homedir
%
% AUTHOR:
% Jens Klinzing, jens.klinzing@uni-tuebingen.de
dir_cluster    = '/gpfs01/born/study/Reactivated Connectivity Jens Klinzing';
dir_office      = 'Z:\Reactivated Connectivity Jens Klinzing';

if nargin == 0
    if isunix
        datadir     = dir_cluster;
    elseif ispc
        datadir     = dir_office;
    else
        error('Does not recognize system.')
    end
elseif nargin == 1 && strcmp(system, 'cluster')
    datadir         = dir_cluster;
elseif nargin == 1 && strcmp(system, 'office')
    datadir         = dir_office;
end