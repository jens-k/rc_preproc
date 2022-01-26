function rootdir = get_pathroot(system)
% This function returns the correct rootdir path for the current system or 
% the system specified by input parameter 'system' ('cluster' or 'office').
%
% This is kinda redundant to init_rc, in which the path is defined already
% (Matlab didnt let me do this more elegantly..)
%
% see also get_pathdata
%
% AUTHOR:
% Jens Klinzing, jens.klinzing@uni-tuebingen.de
dir_cluster    = '/gpfs01/born/group/Jens/Reactivated Connectivity';
dir_office      = 'Y:\Jens\Reactivated Connectivity';

if nargin == 0
    if (isunix)
        rootdir     = dir_cluster;
    elseif (ispc)
        rootdir     = dir_office;
    else
        error('Does not recognize system.')
    end
elseif nargin == 1 && strcmp(system, 'cluster')
    rootdir         = dir_cluster;
elseif nargin == 1 && strcmp(system, 'office')
    rootdir         = dir_office;
elseif nargin == 1
    error('Input does not satisfy my needs.')
end