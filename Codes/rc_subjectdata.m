function subjectdata = rc_subjectdata(id)
% Returns subjectdata in consecutive notation.
%
% INPUT VARIABLES:
% id				String, subject ID in the original recording
%
% OUTPUT VARIABLES:
% subjectdata       Structure array containing the subject data in
%                   consecutive order. This order can change, e.g. if
%                   subjects are excluded. Save all filenames based on the
%                   field .id which is unique. Thats more important than
%                   forwarding the .id field at every analysis step.
%                   See also get_filenames.
%
% AUTHOR:
% Jens Klinzing, jens.klinzing@uni-tuebingen.de


%% TODOs
% Get rid unnecessary paths (headmodels, prepared elecs, grids etc.)
% Many of them can be generated when needed and dont have to be written
% down explicitly
% Also: Get rid of .channel, since that info is now in files

%% SETUP
path_eeg			= '$data/EEG/';
path_anatomies		= '$data\Anatomies';
path_localite		= '$data\Localite';

i = 1;
evalc('subjectdata(i)      = s05();'); i = i+1;
evalc('subjectdata(i)      = s09();'); i = i+1;
evalc('subjectdata(i)      = s12();'); i = i+1;
evalc('subjectdata(i)      = s13();'); i = i+1;
evalc('subjectdata(i)      = s14();'); i = i+1;
evalc('subjectdata(i)      = s16();'); i = i+1;
evalc('subjectdata(i)      = s17();'); i = i+1;
evalc('subjectdata(i)      = s20();'); i = i+1;
evalc('subjectdata(i)      = s24();'); i = i+1;
evalc('subjectdata(i)      = s25();'); i = i+1;
evalc('subjectdata(i)      = s26();'); i = i+1;
evalc('subjectdata(i)      = s28();'); i = i+1;
evalc('subjectdata(i)      = s29();'); i = i+1;
evalc('subjectdata(i)      = s30();'); i = i+1;
evalc('subjectdata(i)      = s35();'); i = i+1;
evalc('subjectdata(i)      = s39();'); i = i+1;
evalc('subjectdata(i)      = s41();'); i = i+1;
evalc('subjectdata(i)      = s44();'); i = i+1;
evalc('subjectdata(i)      = s45();'); i = i+1;
evalc('subjectdata(i)      = s46();'); i = i+1;
evalc('subjectdata(i)      = s47();'); i = i+1;
evalc('subjectdata(i)      = s48();'); i = i+1;
evalc('subjectdata(i)      = s49();'); i = i+1;
evalc('subjectdata(i)      = s51();'); 

if nargin == 1
	subjectdata = subjectdata(cellfun(@(x) strcmp(x, id), {subjectdata.id}));
	if isempty(subjectdata)
		error('Subject ID ''%s'' not found.', id)
	end
end


%% HELPER FUNCTION TO INITIALIZE AN EMPTY SUBJECT
% This way there are no errors in case not all fields are filled
	function data = initialize_subject(name)
		
		data = struct(	'id', name, ...
			'mri', '', ...
			'elec', '', ...
			'channel', '', ...
			'learn', '', ...
			'rs1', '', ...
			'rs2', '', ...
			'rs3', '', ...
			'sleep', '', ...
			'hypnogram', '');
		
		data.nid{1}		= [name '_n1'];
		data.nid{2}		= [name '_n2'];
	end

%% SUBJECT DATA
% All subjects have a few channels with strong line noise. These channels
% can change between recordings. I did not reject them since this frequency
% range will be filtered out anyway.

	function data = s05()
		
		data = initialize_subject('s5');
		
		% Subject-specific
		% Has an odd 14 times/s artifact on the mid-left:
		% '-E33', '-E34', '-E35', -'E36', '-E39', '-E40', '-E41', -'E42', '-E46', '-E47'
		
		data.mri            = [path_anatomies '\05_VN\nifti\05_VN_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '/VN_19900101_VN_4d87d5c3/Sessions/Session_20160510203319202/EEG/EEGMarkers20160510213058833.xml'];
		% data.elec_proj      = '$root/homes/headmodels 1.1/projected electrodes/s5_scalp.15_simbio_fem_elecs_proj.mat'; % after projection to head surface
		% data.headmodel      = '$root/homes/headmodels 1.1/s5_scalp.15_simbio_fem.mat';
		% data.grid           = '$root/homes/headmodels 1.1/subject-specific grids/s5_grid_10mm.mat';
		
		% Night- or recording-specific (.nid was already added during initialization)
		n = 1; fileprefix = ['RC_0' data.id(end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_0' data.id(end) num2str(n)];
		data.channel{n}     = {'-E26', '-E33', '-E107'}; % excludes artifactual channels
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

	function data = s09() 	
		
		data				= initialize_subject('s9');
		
		data.mri            = [path_anatomies '\09_JK\nifti\09_JK_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '\JK_19900101_09_4d87d5c3/Sessions/Session_20160803193106400/EEG/EEGMarkers20160803201136034.xml'];
		
		n = 1; fileprefix = ['RC_0' data.id(end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_0' data.id(end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

	function data = s12()
		% 14 jumps/sec artifacts in 27, 28, 29, 33, 34, 35, 36, 39, 40, 41 (left) sometimes in 110, 116, 117 (right)
		% high variance / high-frequency noise at around the two most posterior rows of the net, particularly in 'E63', 'E64', 'E65', 'E68', 'E69', 'E73', 'E74', 'E81', 'E82',
		% 'E88', 'E89', 'E94', 'E95'. I did not reject these channels for now.
		
		data				= initialize_subject('s12');
		
		data.mri            = [path_anatomies  '\12_NR\nifti\12_NR_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '\NR_19910101_12_4d87d5c3\Sessions\Session_20160614202257873\EEG\EEGMarkers20160614212020214.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {'-E39', '-E48', '-E107'}; % unnatural spikes in rs1, super noisy in rs1, super noisy in rs3
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {'-E39', '-E40', '-E41'}; % unnatural spikes
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

	function data = s13()
		% 14 jumps/sec artifacts in 1,5,6,7,8, 9, 14, 15 etc.
		
		data				= initialize_subject('s13');
		
		data.mri            = '$data\Anatomies\13_SD\nifti\13_SD_MPRAGE_GRAPPA2_t1.nii';
		data.elec           = '$data/Localite\SD_19950101_13_4d87d5c3\Sessions\Session_20160712194209170\EEG\EEGMarkers20160712202605575.xml';
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {'-E56'}; % noisy
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {'-E56', '-E82'}; % noisy
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

	function data = s14() 		
		data				= initialize_subject('s14');
		
		data.mri            = [path_anatomies '\14_FL\nifti\14_FL_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '\FL_19920101_14_4d87d5c3/Sessions/Session_20160620202039310/EEG/EEGMarkers20160620211443932.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

	function data = s16() 		
		data				= initialize_subject('s16');
		
		data.mri            = [path_anatomies '\16_BM\nifti\16_BM_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '\BM_19950101_16_4d87d5c3/Sessions/Session_20160623195905832/EEG/EEGMarkers20160623205244309.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

	function data = s17() 		
		data				= initialize_subject('s17');
		
		data.mri            = [path_anatomies '\17_AM\nifti\17_AM_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '\AM_19920101_17_4d87d5c3/Sessions/Session_20160719193501252/EEG/EEGMarkers20160719201857474.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

	function data = s20() 		
		data				= initialize_subject('s20');
		
		data.mri            = [path_anatomies '\20_YZ\nifti\20_YZ_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '\YZ_19920101_20_4d87d5c3/Sessions/Session_20160815194809847/EEG/EEGMarkers20160815203100481.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

	function data = s24() 		
		data				= initialize_subject('s24');
		
		data.mri            = [path_anatomies '\24_FH\nifti\24_FH_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '\FlHo_19900101_24_4d87d5c3/Sessions/Session_20160912193507579/EEG/EEGMarkers20160912201106728.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])]; % renamed this file, was accidentally called rs2
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

	function data = s25() 		
		data				= initialize_subject('s25');
		
		data.mri            = [path_anatomies '\25_EK\nifti\25_EK_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '\EK_19910101_25_4d87d5c3/Sessions/Session_20160911200801775/EEG/EEGMarkers20160911204357929.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

	function data = s26() 		
		data				= initialize_subject('s26');
		
		data.mri            = [path_anatomies '\26_FHA\nifti\26_FHA_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '/FHa_19940101_26_4d87d5c3/Sessions/Session_20160908193349610/EEG/EEGMarkers20160908201757154.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

	function data = s28() 		
		data				= initialize_subject('s28');
		
		data.mri            = [path_anatomies '\28_LW\nifti\28_LW_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '/LW_19970101_28_4d87d5c3/Sessions/Session_20161022193939974/EEG/EEGMarkers20161022202617638.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

	function data = s29() 		
		data				= initialize_subject('s29');
		
		data.mri            = [path_anatomies '\29_CW\nifti\29_CW_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '/CW_19920101_29_4d87d5c3/Sessions/Session_20161010194501075/EEG/EEGMarkers20161010203520995.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

	function data = s30() 		
		data				= initialize_subject('s30');
		
		data.mri            = [path_anatomies '\30_LB\nifti\30_LB_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '/LB_19920101_30_4d87d5c3/Sessions/Session_20161007194345631/EEG/EEGMarkers20161007202119252.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

	function data = s35() 		
		data				= initialize_subject('s35');
		
		data.mri            = [path_anatomies '\35_KM\nifti\35_KM_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '/KM_19930101_35_4d87d5c3/Sessions/Session_20161201195423444/EEG/EEGMarkers20161201203334915.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

	function data = s39() 		
		data				= initialize_subject('s39');
		
		data.mri            = [path_anatomies '\39_MV\nifti\39_MV_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '/MV_19950101_39_4d87d5c3/Sessions/Session_20170430195604987/EEG/EEGMarkers20170430203148173.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

	function data = s41() 		
		data				= initialize_subject('s41');
		
		data.mri            = [path_anatomies '\41_CS\nifti\41_CS_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '/CS_19960101_41_4d87d5c3/Sessions/Session_20170423192612823/EEG/EEGMarkers20170423200427233.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

	function data = s44() 		
		data				= initialize_subject('s44');
		
		data.mri            = [path_anatomies '\44_GH\nifti\44_GH_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '\GH_19960101_44_4d87d5c3/Sessions/Session_20170526200148969/EEG\EEGMarkers20170526203537296.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
	end

function data = s45() 		
		data				= initialize_subject('s45');
		
		data.mri            = [path_anatomies '\45_AG\nifti\45_AG_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '\AG_19950101_45_4d87d5c3/Sessions/Session_20170607200522137/EEG\EEGMarkers20170607203828454.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
end

function data = s46() 		
		data				= initialize_subject('s46');
		
		data.mri            = [path_anatomies '\46_PH\nifti\46_PH_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '\PH_19970101_46_4d87d5c3/Sessions/Session_20170614200033729\EEG\EEGMarkers20170614203502621.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
end

function data = s47() 		
		data				= initialize_subject('s47');
		
		data.mri            = [path_anatomies '\47_RF\nifti\47_RF_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '\RF_19960101_47_4d87d5c3\Sessions\Session_20170617200216025\EEG\EEGMarkers20170617203942335.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
end

function data = s48() 		
		data				= initialize_subject('s48');
		
		data.mri            = [path_anatomies '\48_JL\nifti\48_JL_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '\JL_19950101_JL_4d87d5c3\Sessions\Session_20170711193644855\EEG\EEGMarkers20170711201905179.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
end

function data = s49() 		
		data				= initialize_subject('s49');
		
		data.mri            = [path_anatomies '\49_LG\nifti\49_LG_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '\LG_19960101_49_4d87d5c3\Sessions\Session_20170618195335512\EEG\EEGMarkers20170618202706563.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
end

function data = s51() 		
		data				= initialize_subject('s51');
		
		data.mri            = [path_anatomies '\51_LM\nifti\51_LM_MPRAGE_GRAPPA2_t1.nii'];
		data.elec           = [path_localite '\LM_19970101_LM_4d87d5c3\Sessions\Session_20170713193930921\EEG\EEGMarkers20170713201311189.xml'];
		
		n = 1; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {}; 
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
		
		n = 2; fileprefix = ['RC_' data.id(end-1:end) num2str(n)];
		data.channel{n}     = {};
		data.learn{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_learn'])];
		data.rs1{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs1'])];
		data.rs2{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs2'])];
		data.rs3{n}         = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_rs3'])];
		data.sleep{n}       = [path_eeg get_filenames(abpath(path_eeg), [fileprefix '_sleep'])];
		data.hypnogram{n}   = '';
end

end