%% Creates FEM headmodels for all participant
% The location of each resulting headmodel has to be entered in
% rc_headmodels to make them accessible to other analysis scripts.
error('Don''t run this file by accidentally pressing F5.'); 1==1;

%% TODOs
% Restrict grid points to the cortical sheet? http://www.fieldtriptoolbox.org/tutorial/sourcemodel
% ...or have only one filter for each brain area? (talk to jan-mattijs?)

%% Setup
% I didnt bother to set up a paths structure for this short pipeline
path_headmodels                 = enpath(fullfile(path_root, 'homes', 'headmodels 1.2'));
path_projelecs                  = enpath(fullfile(path_headmodels, 'projected electrodes'));
path_segmris					= enpath(fullfile(path_headmodels, 'segmented mris'));
path_segplots                   = enpath(fullfile(path_segmris, 'plots'));
path_elecplots                  = enpath(fullfile(path_projelecs, 'plots'));

subjdata                        = rc_subjectdata;

% Define tissue conductivities. These are taken from the fieldtrip FEM
% tutorial. The correct order is established ad hoc (may change with
% different segmentation algorithms).
conductivities{1}				= {'gray'; 'white'; 'csf'; 'skull'; 'scalp'};
conductivities{2}				= {0.33; 0.14; 1.79; 0.01; 0.43};

%% Create headmodels
overwrite = true;
delete(gcp('nocreate')), parpool('local', 8);
parfor iSj = 1:numel(subjdata)
    if isempty(get_filenames(path_segmris, subjdata(iSj).id)) || overwrite
        mri							= ft_read_mri(abpath(subjdata(iSj).mri), 'datatype', 'nifti');
        mri.coordsys				= 'ras';
        %     ft_sourceplot([], mri);
        
        cfg                         = [];
        cfg.dim                     = mri.dim;
        cfg.yrange                  = [-149.5 149.5];
        mri_res                     = ft_volumereslice(cfg,mri);
        %     ft_sourceplot([], mri_res);
        
        cfg_seg                         = [];
        cfg_seg.output                  = {'gray', 'white', 'csf','skull','scalp'};
        cfg_seg.scalpthreshold          = .4;	% default: .1; 01 and 02 done with .15
        cfg_seg.brainthreshold			= .4;   % 3 default: .5
        cfg_seg.skullthreshold			= .3;	% default: .5
        cfg_seg.brainsmooth				= 9;    % FWHM of gaussian kernel in voxels  (default = 5)
        cfg_seg.scalpsmooth				= 7;    % FWHM of gaussian kernel in voxels (default = 5)
        cfg_seg.skullsmooth				= 7;    % FWHM of gaussian kernel in voxels (default = 5)
        cfg_seg.spmversion				= 'spm12';
        cfg_seg.tpm						= abpath(fullfile(path_root, 'misc', 'eTPM.nii')); % new, fancy tpm, comes with mars, has spinal cord, see Huang2015
        
        cfg_seg.opts.biasfwhm			= 40;
        cfg_seg.opts.biasreg			= 0.00001;		% bias regulation did not make a big difference
        cfg_seg.spmmethod				= 'mars';		% new, fancy smoothing method, had some small effect, see Huang2015; used 'new' before
        cfg_seg.mars.convergence		= .005;			% 0.005 worked best with subj 1
        segmentedmri                    = ft_volumesegment(cfg_seg,mri_res);
        
        realsave(fullfile(path_segmris, [subjdata(iSj).id '_scalp' num2str(cfg_seg.scalpthreshold) '_brain' num2str(cfg_seg.brainthreshold) '_skull' num2str(cfg_seg.skullthreshold) '_bias' num2str(cfg_seg.opts.biasreg) '_mars' num2str(cfg_seg.mars.convergence) '_eTPM' '_smooth' '.mat']), segmentedmri);
        
        % Plot and save segmentation and original mri for comparison
        seg_i                 = ft_datatype_segmentation(segmentedmri,'segmentationstyle','indexed');
        cfg                 = [];
        cfg.funparameter    = 'seg';
        cfg.funcolormap     = lines(6); % distinct color per tissue
        cfg.location        = 'center';
        cfg.atlas           = seg_i;    % the segmentation can also be used as atlas
        ft_sourceplot(cfg, seg_i); export_fig(gcf, fullfile(path_segplots, [subjdata(iSj).id '_scalp' num2str(cfg_seg.scalpthreshold) '_brain' num2str(cfg_seg.brainthreshold) '_skull' num2str(cfg_seg.skullthreshold) '_bias' num2str(cfg_seg.opts.biasreg) '_mars' num2str(cfg_seg.mars.convergence) '_eTPM' '.mat']), '-a2', '-nocrop', '-m4'); close all
        ft_sourceplot([], mri_res); export_fig(gcf, fullfile(path_segplots, [subjdata(iSj).id '_scalp' num2str(cfg_seg.scalpthreshold) '_brain' num2str(cfg_seg.brainthreshold) '_skull' num2str(cfg_seg.skullthreshold) '_bias' num2str(cfg_seg.opts.biasreg) '_mars' num2str(cfg_seg.mars.convergence) '_eTPM' '_origmri.mat']), '-a2', '-nocrop', '-m4'); close all
        
        % Prepare a hexahedral mesh (mesh made up by cubes) and shift vertices in a
        % way to better approximate the anatomical shapes
        cfg                         = [];
        cfg.shift                   = 0.3;
        cfg.method                  = 'hexahedral';
        mesh                        = ft_prepare_mesh(cfg,segmentedmri);
        
        idx = [];
        for t = 1:numel(mesh.tissuelabel)
            idx(t) = find(cellfun(@(x) strcmp(mesh.tissuelabel{t}, x), conductivities{1}));
        end
        
        % Create the actual head model
        cfg                         = [];
        cfg.method                  = 'simbio';
        cfg.conductivity            = [conductivities{2}{idx}];   % order follows mesh.tissuelabel
        vol                         = ft_prepare_headmodel(cfg, mesh);
        
        realsave(fullfile(path_headmodels, [subjdata(iSj).id '_scalp' num2str(cfg_seg.scalpthreshold) '_brain' num2str(cfg_seg.brainthreshold) '_skull' num2str(cfg_seg.skullthreshold) '_bias' num2str(cfg_seg.opts.biasreg) '_mars' num2str(cfg_seg.mars.convergence) '_eTPM' '_simbio_fem.mat']), vol)
    end
end

%% Check headmodels, coregistration with EEG channel positions, and project electrodes onto skull
% ...including some special treatments of single datasets
for iSj = 1:numel(subjdata)
    vol                = load_file(path_headmodels, subjdata(iSj).id);
    elec               = ft_read_sens(abpath(subjdata(iSj).elec));

	for i = 1:128 % some renaming incl. checks
		if str2num(elec.label{i}) == i
			elec.label{i} = ['E' num2str(i)];
		elseif ~strcmp(elec.label{i}, ['E' num2str(i)])
			if i == 23 && strcmp(elec.label{23}, '32')
				elec.label{i} = 'E23';
			else
				error('Electrode names for %s are not as expected. Better double-check!', subjdata(iSj).id)
			end
			% Some subjects (e.g. s12) have a weird combination of E* and non-E*
			% channels...
		end
	end
	if strcmp(elec.label{129}, 'REF')
		elec.label{129} = 'VREF';
	end
	if ~all(strcmp(elec.label(129:135), {'VREF' 'COM' 'LEar' 'LEye' 'Nasion' 'REye' 'REar'}))
		error('Electrode names for %s are not as expected. Better double-check!', subjdata(iSj).id)
	end
    
    cfg                 = [];
    cfg.elec            = elec;
    cfg.headshape       = vol;
	cfg.channel         = elec.label(1:129); % only electrodes, without fiducial positions
	
	%     disp('Showing electrode positions. Manual corrections possible.')
	%     cfg.method          = 'interactive';
	%     elec_aligned        = ft_electroderealign(cfg);
	
	disp('Projecting electrodes onto the head.')
	cfg.method          = 'project';
	elec_proj           = ft_electroderealign(cfg);
	elec_proj.id        = subjdata(iSj).id;
    
	% Plot and save the result
	% fprintf('Showing electrode positions of %s after projecting them onto the head.\n', subjdata(iSj).id)
	% cfg.elec            = elec_proj;
	% cfg.method          = 'interactive';
	% ft_electroderealign(cfg)
	figure
	hold on
	ft_plot_mesh(vol,'surfaceonly','yes','vertexcolor','none','edgecolor','none','facecolor', [0.6 0.6 0.6],'face alpha',1), camlight
	ft_plot_sens(elec_proj) % ,'style', 'sr');
    view(180,10)
    export_fig(gcf, fullfile(path_elecplots, [subjdata(iSj).id '_elecs_proj_1.png']), '-a2', '-nocrop', '-m4');
    view(60,30)
    export_fig(gcf, fullfile(path_elecplots, [subjdata(iSj).id '_elecs_proj_2.png']), '-a2', '-nocrop', '-m4');
    view(-30,10)
    export_fig(gcf, fullfile(path_elecplots, [subjdata(iSj).id '_elecs_proj_3.png']), '-a2', '-nocrop', '-m4');
    close all

    [~, name, ~] = fileparts(get_filenames(path_headmodels, subjdata(iSj).id));     
    realsave(fullfile(path_projelecs, [subjdata(iSj).id '_elecs_proj.mat']), elec_proj);
end
    
%% Create subject-specific MNI-aligned grids
% If you want to use your own special grid, this has to be provided as
% cfg.grid.template to ft_prepare_sourcemodel.
delete(gcp('nocreate')), parpool('local', 4);
parfor iSj = 1:numel(subjdata)
    path_grids                  = enpath(fullfile(path_headmodels, 'subject-specific grids new'));
    
    cfg                         = [];
	% cfg.mri                     = load_file(get_filenames(path_segmris, subjdata(iSj).id, 'full'));
	cfg.mri                     = ft_read_mri(abpath(subjdata(iSj).mri), 'datatype', 'nifti');
    cfg.mri.coordsys            = 'ras';
    cfg.elec                    = load_file(get_filenames(path_projelecs, subjdata(iSj).id, 'full')); % dont think thats actually needed?
    cfg.grid.warpmni            = 'yes';    % !!
    cfg.grid.resolution         = 10;       % in mm
    cfg.grid.nonlinear          = 'yes';    % use non-linear normalization
    cfg.grid.unit               = 'mm';
	cfg.spmversion				= 'spm12';
	cfg.spmmethod				= 'new';
	% cfg.headmodel				  = load_file(get_filenames(path_headmodels, subjdata(iSj).id, 'full'));0;]
	grid                        = ft_prepare_sourcemodel(cfg);
	grid.id                     = subjdata(iSj).id;
	
% 	% Check results
% 	vol = load_file(abpath(subjdata(iSj).headmodel)); figure; ft_plot_vol(vol, 'edgecolor', 'none'); alpha 0.4;
% 	ft_plot_mesh(grid.pos(grid.inside,:), 'vertexcolor', 'green');
% 	
% 	input('Press ENTER to go on.')
% 	close all
	
	realsave(fullfile(path_grids, [subjdata(iSj).id '_mnigrid_' num2str(cfg.grid.resolution) 'mm.mat']), grid);
end
