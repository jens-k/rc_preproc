%% Creates FEM headmodels for all participant
% The location of each resulting headmodel has to be entered in
% rc_headmodels to make them accessible to other analysis scripts.
error('Don''t run this file by accidentally pressing F5.'); 1==1;

%% TODOs
% Restrict grid points to the cortical sheet? http://www.fieldtriptoolbox.org/tutorial/sourcemodel
% ...or have only one filter for each brain area? (talk to jan-mattijs?)

%% Setup
% I didnt bother to set up a paths structure for this short pipeline
path_headmodels                 = enpath(fullfile(path_root, 'homes', 'headmodels 1.1 BEM'));
path_projelecs                  = enpath(fullfile(path_headmodels, 'projected electrodes'));
subjdata                        = rc_subjectdata;

%% Create headmodels
for iSj = 1:numel(subjdata)
    mri_nifti                   = ft_read_mri(abpath(subjdata(iSj).mri), 'datatype', 'nifti');
    mri_nifti.coordsys          = 'ras';
	mri_nifti					= ft_convert_units(mri_nifti, 'mm');
%     ft_sourceplot([], mri_nifti);
    
    cfg                         = [];
	cfg.dim                     = mri_nifti.dim;
	cfg.yrange                  = [-149.5 149.5];
	mri                         = ft_volumereslice(cfg,mri_nifti);
	%     ft_sourceplot([], mri_res);
	
	cfg           = [];
	cfg.output    = {'brain','skull','scalp'};
	segmentedmri  = ft_volumesegment(cfg, mri);
	
% 	seg_i               = ft_datatype_segmentation(segmentedmri,'segmentationstyle','indexed');
% 	cfg                 = [];
% 	cfg.funparameter    = 'seg';
% 	cfg.funcolormap     = lines(6); % distinct color per tissue
% 	cfg.location        = 'center';
% 	cfg.atlas           = seg_i;    % the segmentation can also be used as atlas
% 	ft_sourceplot(cfg, seg_i);
	
	% Prepare a mesh 
	% ..uses default cfg.method 'projectmesh'
	
	cfg=[];
	cfg.tissue={'brain','skull','scalp'};
	cfg.numvertices = [3000 2000 1000];
	mesh=ft_prepare_mesh(cfg,segmentedmri);
	
	% Create the actual head model
    cfg                         = [];
    cfg.method                  = 'bemcp';
    vol                         = ft_prepare_headmodel(cfg, mesh);
    
    realsave(fullfile(path_headmodels, [subjdata(iSj).id '_bem.mat']), vol)
end

%% Check headmodels and coregistration with EEG channel positions
for iSj = 1:numel(subjdata)
	vol_filename		= get_filenames(path_headmodels, subjdata(iSj).id, 'full');
    vol					= load_file(vol_filename);
	vol					= ft_convert_units(vol, 'mm');
    elec				= ft_read_sens(abpath(subjdata(iSj).elec));
	elec				= ft_convert_units(elec, 'mm');

    for i = 1:128 % some renaming incl. checks
%         if str2num(elec.label{i}) == i  %this should look for the
%         occurrence in the number in the label
            elec.label{i} = ['E' num2str(i)];
%         else
%             error('Electrode names are not as expected. Better double-check!')
%             % For example s12 and further have a weird combination of E* and non-E*
%             % channels...
%         end
    end
    if strcmp(elec.label{129}, 'REF')
        elec.label{129} = 'VREF'
    else
        error('Electrode names are not as expected. Better double-check!')
    end
    
    % Lets select only those channels actually present in the data
	% (eliminates COM LEar LEye Nasion REye REear)
    cfg                 = [];
    cfg.channel         = elec.label(1:129);
    elec                = ft_selectdata(cfg, elec)
    
%     ft_plot_mesh(vol.bnd(1), 'edgecolor','none','facealpha',0.8,'facecolor',[0.6 0.6 0.8]); hold on;
%     ft_plot_sens(elec, 'style', 'sk');
    
    % Correct misalignments interactively and save final result
    % (even if the electrodes are aligned perfectly this function has to
    % be called
    cfg                 = [];
    cfg.elec            = elec;
    cfg.headshape       = vol.bnd(3); % this is the scalp surface, other methods may have other tissue orders!!
    
%     disp('Showing electrode positions. Manual corrections possible.')
%     cfg.method          = 'interactive';
%     elec_aligned        = ft_electroderealign(cfg);
    
    disp('Projecting electrodes onto the head.')
    cfg.method          = 'project';
    elec_proj           = ft_electroderealign(cfg);
    
    % Double check if electrode positions make sense
    disp('Showing electrode positions after projecting them onto the head.')
    cfg.elec            = elec_proj;
    cfg.method          = 'interactive';
                        ft_electroderealign(cfg)
    
    elec_proj.id        = subjdata(iSj).id;                     
    [~, name, ~]		= fileparts(vol_filename);     
    realsave(fullfile(path_projelecs, [subjdata(iSj).id '_elecs_proj.mat']), elec_proj);
end
    
%% Create subject-specific MNI-aligned grids
% If you want to use your own special grid, this has to be the 
% cfg.grid.template that goes to ft_prepare_sourcemodel.
for iSj = 1:numel(subjdata)
    path_grids                  = enpath(fullfile(path_headmodels, 'subject-specific grids'));
    
    cfg                         = [];
    cfg.mri                     = ft_read_mri(abpath(subjdata(iSj).mri), 'datatype', 'nifti');
    cfg.mri.coordsys            = 'ras';
    cfg.elec                    = load_file(path_projelecs, subjdata(iSj).id); % dont think thats actually needed?
    cfg.grid.warpmni            = 'yes';    % !!
    cfg.grid.resolution         = 10;       % in mm
    cfg.grid.nonlinear          = 'yes';    % use non-linear normalization
    cfg.grid.unit               = 'mm';
    grid                        = ft_prepare_sourcemodel(cfg);    
    
    grid.id                     = subjdata(iSj).id;
    
    % Check results
    vol                         = load_file(path_headmodels, subjdata(iSj).id);
    figure;
    ft_plot_vol(vol, 'edgecolor', 'none'); alpha 0.4;
    ft_plot_mesh(grid.pos(grid.inside,:));
%     input('Press ENTER to go on.')
%     close all
        
    realsave(fullfile(path_grids, [subjdata(iSj).id '_mnigrid_' num2str(cfg.grid.resolution) 'mm.mat']), grid);
end
