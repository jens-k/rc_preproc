
files = get_filenames(pwd, 'full');

% restructuring 1
for iFile=1:numel(files)    
    arts                    = load_file(files{iFile});
    arts.artfctdef.zvalue   = arts.zvalue.parameters;
    arts                    = rmfield(arts, 'zvalue');

    realsave(files{iFile}, arts)
end

% restructuring 2
for iFile=1:8 %numel(files)
    temp                    = load_file(files{iFile});
    
    arts                    = [];
    arts.id                 = temp.id;
    arts.artfctdef          = temp.artfctdef;
    arts.trl                = temp.trl;
    arts.dataset            = temp.dataset;
    realsave(files{iFile}, arts)
end
