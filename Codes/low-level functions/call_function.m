function dir_output = call_function(func, cfg, dir_input, dir_output, suffix, file_nums)
% Generic function wrapper. Runs specified function over all files in the
% specified directory. ... and more. If dir_ouput is empty the results will
% be saved in a subfolder 'proc'.
%
% Use as
% dir_output = call_function(func, cfg, dir_input, dir_output, suffix, file_nums)
% eg. dirFiles = call_function('ft_freqanalysis', cfg, C:\folder\, C:\folder\resultfolder)
%     dirFiles = call_function('ft_freqanalysis', cfg, C:\folder\, C:\folder\resultfolder, [5 6 7])
%
% INPUT VARIABLES:
% func              string; name of the fieldtrip function
% cfg               will be handed over to called
%                   function; may contain additional fields cfg.hh_... for
%                   the wrapper function. 
% dir_input         string; folder containing the files to be processed.
% dir_output        string (optional); path to folder in which results
%                   should be saved. Can be a simple string in which case a
%                   subfolder of dir_input will be created with that name
%                   in which the results will be saved. If this argument is
%                   empty results will not be saved.
% suffix            String (optional); will be attached to each filename,
%                   eg. '_proc' 
% file_nums         indices of files in dir_inpu to be processed, eg. [5 9]
%
% OUTPUT VARIABLES:
% dir_output        string; name of folder in which the results have been
%                   saved to (ust in case you didnt provide it)
%
% AUTHOR:
% Jens Klinzing, jens.klinzing@uni-tuebingen.de

% -----     INPUT CHECKS AND SETTINGS     -----


if isfield(cfg, 'outputfile')
    dosave = false;         % dont save the function output, is done by function itself
else
    dosave = true;          % save the function output
end

if nargin < 3 || nargin > 6
    error('Unexptected number of input arguments!');
end

if exist(dir_input,'dir'),
    files        = get_filenames(dir_input);
    if isempty(files)
        error('Input folder exists but is empty.')
    end
else
    error('Input folder does not exist.')
end

if nargin < 4 || isempty(dir_output)
    dosave = false;
else
    % If dir_output is not empty but also not a path, it is interpreted as a subfolder of dir_input.
    [path,~,~] = fileparts(dir_output);
    if isempty(path), dir_output = fullfile(dir_input,dir_output); end
end
if nargin < 5
    suffix = [];
end
if nargin < 6
    file_nums = 1:length(files);
end

% Set defaults (may be changed later)
% genInputFile        = 0;        % generate cfg.inputfile
% genOutputFile       = 0;        % generate cfg.outputfile
% runOnlyOnce         = 0;        % run the loop once only (eg. for grand averages)
% delInputFiles       = 0;
ext                 = '.mat';   % file extension for saving

% Convert the given string into a function handle.
fh = str2func(func);

% -----        START !        -----

for i = file_nums
       
    filename        = files{i};
    [~, name, ~]    = fileparts(filename);
    
%    % Specify trials to be processed
%     if isfield(cfg, 'selectTrials') && isfield(cfg, 'dirTrialinfo')
%         trialinfo       = hh_loadData(cfg.dirTrialinfo, i);   % load trialinfo for current subject
%         if strcmp(cfg.selectTrials, 'so')
%             cfg.trials  = trialinfo(:) == 0;        % Note true for each SO trial (originally coded as 0)
%         elseif strcmp(cfg.selectTrials, 'nonevent')
%             cfg.trials  = trialinfo(:) == 1;        % Note true for each non-event trial (originally coded as 1)
%         else
%             error('Specified trial code unknown (cfg.selectTrials)!');
%         end
%         
%         % cfg.selectSingleTrials can furthermore select a subset of these
%         % trials
%         if isfield(cfg,'selectSingleTrials')
%            
%             
%             % translate given trial numbers into trial numbers within
%             % selected condition
%             trials_ind              = find(cfg.trials); 
%             selectSingleTrials      = cfg.selectSingleTrials;   % make a temporary copy of the selected trial indices
%             selectSingleTrials(selectSingleTrials > numel(trials_ind)) = [];  % ... and delete the ones that are too large
%             trials_ind_selected     = trials_ind(selectSingleTrials);
%             cfg.trials              = false(size(cfg.trials));
%             cfg.trials(trials_ind_selected) = true;
% 
%             cfg.keeptrials  = 'yes';
%         end
%             
% 
%     elseif isfield(cfg, 'selectTrials') && ~isfield(cfg, 'trialInfo')
%         error('A condition was specified (cfg.selectTrials) but no trial info (cfg.trialInfo) is given.')
%     elseif isfield(cfg, 'trialInfo') && ~isfield(cfg, 'selectTrials')
%         error('A trial info was given (cfg.trialInfo) but no condition was specified (cfg.selectTrials).')
%     end

%     % Generate cfg.inputfile/ouputfile if desired
%     if genInputFile
%         cfg.inputfile  = fullfile(dir_input, files{i});
%     end
%     if genOutputFile
%         if strcmp(shorthand,'')
%             cfg.outputfile = fullfile(saveTo, [name,ext]);
%         else
%             cfg.outputfile = fullfile(saveTo, [name,'_',shorthand,ext]);
%         end
%     end
    
    % If the saving is done via cfg.outputfile and/or no output destination
    % is given, the results are not saved here. If output destinatin is
    % given saving is done right here
    if ~dosave
        if isfield(cfg, 'outputfile')
            saved = fileparts(cfg.outputfile); % for returning the path used for saving
            if ~exist(saved,'dir'), mkdir(saved); end
        end
        if isfield(cfg, 'inputfile')
            fh(cfg);
        else
            data = load_file(fullfile(dir_input, files{i})); % load data
            fh(cfg, data);                % process data with given function
        end
        
        clear data
%         if runOnlyOnce, break;end  % If this is eg. a grand average, end here.
        
    else
        if isfield(cfg, 'inputfile')
            data = fh(cfg);
        else
            temp = load_file(fullfile(dir_input, files{i})); % load data
            data = fh(cfg, temp);
            clear temp
        end
        
        realsave((fullfile(enpath(dir_output),[name,suffix,ext])), data);  % ... and save!
        disp(['File ' filename ' has successfully been processed (' func ').']);
        
        % Clean up
        clear data 
        % if runOnlyOnce, break;end  % If this is eg. a grand average, end here.
    end
    
%     if delInputFiles
%         delete(fullfile(dir_input, files{i}));
%         disp(['Input file ' files{i} ' has successfully been deleted.']);
%     end
    
end
end


% % -----     PREPARE FOR CALLED FUNCTION     -----
% 
% switch func
% 
%     % ----- Fieldtrip functions -----   
%     
%     case 'ft_selectdata'
%         if ~isfield(cfg,'saveTo'),saveTo = 'data red';
%         else saveTo = cfg.saveTo; end
%         shorthand       = 'red';
%         
%     case 'ft_redefinetrial'
%         if ~isfield(cfg,'saveTo'),saveTo = 'redef trials';
%         else saveTo = cfg.saveTo; end
%         shorthand       = '';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         
%     case 'ft_timelockanalysis'
%         if ~isfield(cfg,'saveTo'),saveTo = 'time-locked avgs';
%         else saveTo = cfg.saveTo; end
%         shorthand       = 'avg';
%         genInputFile    = 0;
%         genOutputFile   = 1;
%         
%     case 'ft_timelockgrandaverage'
%         if ~isfield(cfg,'saveTo'),saveTo = '';
%         else saveTo = cfg.saveTo; end
%         
%         if subsetGiven
%             shorthand       = 'hh_x_time-locked_grandaverage_subset';
%         else
%             shorthand       = 'hh_x_time-locked_grandaverage';      % x to have it last on row, what a dirty fix...
%         end
%         % If specified, average only the wanted subjects
%         warning('Warning, this function hasnt been tested after a rewrite. Double-check results!')
%         j=1;
%         for i = file_nums
%             files{j} = fullfile(dir_input, files{i});
%             j = j+1;
%         end
%         files(j:end) = [];
%         
%         cfg.inputfile   = files;
%         cfg.outputfile  = fullfile(dir_input, [shorthand '.mat']);
%         runOnlyOnce     = 1;
%         
%     case 'ft_freqanalysis'
%         if isfield(cfg, 'foi'), limits = cfg.foi;
%         elseif isfield(cfg, 'foilim'), limits = cfg.foilim;
%         else limits = [0 0];
%         end
%         if ~isfield(cfg,'saveTo')
%             if isfield(cfg,'width')
%                 saveTo = ['tfr (' num2str(limits(1)) '-' num2str(limits(end)) 'Hz), ' num2str(cfg.width) 'cyc'];
%             else
%                 saveTo = ['tfr (' num2str(limits(1)) '-' num2str(limits(end)) 'Hz)'];
%             end
%         else
%             saveTo = cfg.saveTo; 
%         end
% 
%         shorthand       = 'tfr';
%         genInputFile    = 1;        % generate an input file
%         genOutputFile   = 1;        % generate an output file
%         
%     case 'ft_freqgrandaverage'
%         if ~isfield(cfg,'saveTo'),saveTo = '';
%         else saveTo = cfg.saveTo; end
%         if subsetGiven
%             if isfield(cfg, 'foi')
%                 shorthand       = ['hh_x_tfr_grandaverage_subset_' num2str(cfg.foi(1)) '-' num2str(cfg.foi(end))];  % x to have it last on row, what a dirty fix...
%             else
%                 shorthand       = ['hh_x_tfr_grandaverage_subset'];  % x to have it last on row, what a dirty fix...
%             end
%         else
%             if isfield(cfg, 'foi')
%                 shorthand       = ['hh_x_tfr_grandaverage_' num2str(cfg.foi(1)) '-' num2str(cfg.foi(end))];  % x to have it last on row, what a dirty fix...
%             else
%                 shorthand       = ['hh_x_tfr_grandaverage'];  % x to have it last on row, what a dirty fix...
%             end
%         end
%         
%         % If specified, average only the wanted subjects
%         warning('Warning, this function hasnt been tested after a rewrite. Double-check results!')
%         j=1;
%         for i = file_nums
%             files{j} = fullfile(dir_input, files{i});
%             j = j+1;
%         end
%         files(j:end) = [];
%         
%         cfg.inputfile   = files;
%         cfg.outputfile  = fullfile(dir_input, [shorthand '.mat']);
%         runOnlyOnce     = 1;
%             
%     case 'ft_combineplanar'
%         if ~isfield(cfg,'saveTo'),saveTo = 'planar comb';
%         else saveTo = cfg.saveTo; end
%         shorthand       = 'cb';
%         genOutputFile   = 1;
%         genInputFile    = 1;
%        
%     case 'ft_resampledata'
%         if ~isfield(cfg,'saveTo'),saveTo = ['dwnsmpl ' num2str(cfg.resamplefs) ' Hz'];
%         else saveTo = cfg.saveTo; end
%         shorthand       = 'dnsmpl';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         
%     case 'ft_componentanalysis'
%         if ~isfield(cfg,'saveTo'),saveTo = 'ica components';
%         else saveTo = cfg.saveTo; end
%         shorthand       = 'ica';
%         genInputFile    = 1;
%         genOutputFile   = 1;        
%         
%     case 'ft_preprocessing'     % use to eg. filter after initial preprocessing
%         if ~isfield(cfg,'saveTo'),saveTo = 'preproc';
%         else saveTo = cfg.saveTo; end
%         shorthand = 'proc';
%         genInputFile    = 1;
%         genOutputFile   = 1;         
%         
%     case 'ft_sourcegrandaverage'
%         if ~isfield(cfg,'saveTo'),saveTo = '';
%         else saveTo = cfg.saveTo; end
%         
%         if subsetGiven
%             shorthand       = 'hh_x_sourcegrandaverage_subset';  % x to have it last on row, what a dirty fix...
%         else
%             shorthand       = 'hh_x_sourcegrandaverage';  % x to have it last on row, what a dirty fix...
%         end
%         
%         % If specified, average only the wanted subjects
%         j=1;
%         for i = file_nums
%             files{j} = fullfile(dir_input, files{i});
%             j = j+1;
%         end
%         files(j:end) = [];
% 
%         cfg.inputfile   = files;
%         cfg.outputfile  = fullfile(dir_input, [shorthand '.mat']);
%         runOnlyOnce     = 1;
%         
%         
%     % ------------     Own functions     ------------    
%         
%     case 'hh_prepareLeadfield'
%         if ~isfield(cfg,'saveTo'),saveTo = 'leadfield';
%         else saveTo = cfg.saveTo; end
%         shorthand = 'lf';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%    
%     case 'hh_prepareMNIalignedGrid'
%         if ~isfield(cfg,'saveTo'),saveTo = 'MNI-aligned grid';
%         else saveTo = cfg.saveTo; end
%         shorthand = 'lf';
%         genInputFile    = 1;
%         genOutputFile   = 1;
% 
%     case 'hh_prepareMNIalignedLeadfield'
%         if ~isfield(cfg,'saveTo'),saveTo = 'MNI-aligned grid';
%         else saveTo = cfg.saveTo; end
%         shorthand = 'lf';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         
%     case 'hh_calculateRMS'
%         if ~isfield(cfg,'saveTo'),saveTo = 'root-mean-square';
%         else saveTo = cfg.saveTo; end
%         shorthand       = 'rms';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         
%     case 'hh_contrastTFR'
% %         if length(hh_getFilenames(cfg.dirBaseline)) ~= length(hh_getFilenames(dirFiles)) % can lead to an error if one has a GrandAvg and the other one hasnt
% %             error('The given directories (dirFiles and cfg.dirBaseline) do not contain the same number of files.')
% %         end
%         if ~isfield(cfg,'saveTo')
%             if strcmp(cfg.contrastType, 'absolute')
%                 saveTo = 'abs contrast';
%             else
%                 saveTo = 'rel contrast';
%             end
%         else
%             saveTo = cfg.saveTo;
%         end
%         shorthand       = 'contr';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         
%     case 'hh_createMovementregressors'
%         if ~isfield(cfg,'saveTo'),saveTo = 'mvmnt confounds';
%         else saveTo = cfg.saveTo; end
%         shorthand       = 'conf';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         
%     case 'hh_extractEvents'
%         if ~isfield(cfg,'saveTo'),saveTo = 'filtered trials';
%         else saveTo = cfg.saveTo; end
%         shorthand       = '';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         
%     case 'hh_processConditions'
%         if ~isfield(cfg,'saveTo'),saveTo = 'trial-matched conds';
%         else saveTo = cfg.saveTo; end
%         shorthand       = 'mtchd';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         
%     case 'hh_regressConfound'
%         if ~isfield(cfg,'saveTo'),saveTo = 'regressed';
%         else saveTo = cfg.saveTo; end
%         shorthand       = 'reg';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         
%     case 'hh_plotTFRandSO'
%         if ~isfield(cfg,'saveTo'),saveTo = 'plots';
%         else saveTo = cfg.saveTo; end
%         shorthand       = '';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         ext             = '.png';
%         
%     case 'hh_plotAreas'
%         if ~isfield(cfg,'saveTo'),saveTo = 'plots';
%         else saveTo = cfg.saveTo; end
%         shorthand       = '';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         ext             = '.png';
%         
%     case 'hh_plotLines'
%         if ~isfield(cfg,'saveTo'),saveTo = 'plots';
%         else saveTo = cfg.saveTo; end
%         shorthand       = '';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         ext             = '.png';
%         
%     case 'hh_plotHeadpositions'
%         if ~isfield(cfg,'saveTo'),saveTo = 'plots';
%         else saveTo = cfg.saveTo; end
%         shorthand       = '';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         ext             = '.png';
%         
%     case 'hh_plotTopoplotER'
%         if ~isfield(cfg,'saveTo'),saveTo = 'plots';
%         else saveTo = cfg.saveTo; end
%         shorthand       = '';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         ext             = '.png';
%         
%     case 'hh_plotClusterstatistics'
%         if ~isfield(cfg,'saveTo'),saveTo = 'plots';
%         else saveTo = cfg.saveTo; end
%         shorthand       = '';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         ext             = '';
%         
%     case 'hh_plotHeadmotions'
%         if ~isfield(cfg,'saveTo'),saveTo = 'plots';
%         else saveTo = cfg.saveTo; end
%         shorthand       = '';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         ext             = '';
%    
%     case 'hh_plotHeadmotions_extended'
%         if ~isfield(cfg,'saveTo'),saveTo = 'plots';
%         else saveTo = cfg.saveTo; end
%         shorthand       = '';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         ext             = '';
% 
%     case 'hh_plotSource'
%         if ~isfield(cfg,'saveTo'),saveTo = 'plots';
%         else saveTo = cfg.saveTo; end
%         shorthand       = cfg.method;
%         genInputFile    = 1;
%         if ~isfield(cfg, 'outputfile')
%             genOutputFile   = 1;
%         end
%         ext             = '.fig';
%            
%     case 'hh_shortenFilenames'
%         if ~isfield(cfg,'saveTo'),saveTo = '';
%         else saveTo = cfg.saveTo; end
%         shorthand       = '';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         ext             = '';
% 
%     case 'hh_deleteCFGprevious'
%         saveTo = '';
%         shorthand       = '';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         
%     case 'hh_doDICS'  
%         if ~isfield(cfg,'saveTo'),saveTo = 'results';
%         else saveTo = cfg.saveTo; end
%         shorthand       = '';
%         cfg.saveTo      = saveTo;
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         
%     case 'hh_doLCMV'  
%         if ~isfield(cfg,'saveTo'),saveTo = 'results';
%         else saveTo = cfg.saveTo; end
%         shorthand       = '';
%         cfg.saveTo      = saveTo;
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         
%     case 'hh_averageOverDim'
%         if ~isfield(cfg,'saveTo'),saveTo = 'averaged';
%         else saveTo = cfg.saveTo; end
%         shorthand       = 'avg';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         
%     otherwise
%         if ~isfield(cfg,'saveTo'),saveTo = 'processed';
%         else saveTo = cfg.saveTo; end
%         shorthand       = '';
%         genInputFile    = 1;
%         genOutputFile   = 1;
%         warning(['Function ' func ' not explicitly supported. Use default settings.'])
% end

