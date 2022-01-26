mri = ft_read_mri(abpath('$root/fieldtrip dataset/Subject01.mri'));
mri     = ft_volumereslice([],mri);

mri5 = ft_read_mri(fullfile(path_data, 'Anatomies/56_AT/5/nifti', 't1_mp2rage_sag_p3_iso_INV1.nii'));
mri6 = ft_read_mri(fullfile(path_data, 'Anatomies/56_AT/6/nifti', 't1_mp2rage_sag_p3_iso_INV2.nii'));
mri7 = ft_read_mri(fullfile(path_data, 'Anatomies/56_AT/7/nifti', 't1_mp2rage_sag_p3_iso_UNI_Images.nii'));

mri5.coordsys				= 'ras';
mri6.coordsys				= 'ras';
mri7.coordsys				= 'ras';

% cfg							= [];
% cfg.spmversion				= 'spm12';
% mri_un						= ft_volumebiascorrect(cfg, mri);

cfg     = [];

cfg.yrange                  = [-149.5 149.5];
cfg.dim = mri5.dim;
mri5     = ft_volumereslice(cfg,mri5);
cfg.dim = mri6.dim;
mri6     = ft_volumereslice(cfg,mri6);
cfg.dim = mri7.dim;
mri7     = ft_volumereslice(cfg,mri7);

ft_sourceplot([], mri5); ft_sourceplot([], mri6); ft_sourceplot([], mri7)

% ft_sourceplot([], mri);
% ft_sourceplot([], mri_un);


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

segmentedmri5  = ft_volumesegment(cfg_seg, mri5);
segmentedmri6  = ft_volumesegment(cfg_seg, mri6);
segmentedmri7  = ft_volumesegment(cfg_seg, mri7);

% cfg        = [];
% cfg.shift  = 0.3;
% cfg.method = 'hexahedral';
% mesh5 = ft_prepare_mesh(cfg,segmentedmri5);
% mesh6 = ft_prepare_mesh(cfg,segmentedmri6);
% mesh7 = ft_prepare_mesh(cfg,segmentedmri7);

seg_i5               = ft_datatype_segmentation(segmentedmri5,'segmentationstyle','indexed');
seg_i6               = ft_datatype_segmentation(segmentedmri6,'segmentationstyle','indexed');
seg_i7               = ft_datatype_segmentation(segmentedmri7,'segmentationstyle','indexed');

cfg                 = [];
cfg.funparameter    = 'seg';
cfg.funcolormap     = lines(6); % distinct color per tissue
cfg.location        = 'center';

cfg.atlas           = seg_i5;    % the segmentation can also be used as atlas
ft_sourceplot(cfg, seg_i5); %export_fig(gcf, fullfile(path_segplots, [subjdata(iSj).id '_scalp' num2str(cfg_seg.scalpthreshold) '_brain' num2str(cfg_seg.brainthreshold) '_skull' num2str(cfg_seg.skullthreshold) '_bias' num2str(cfg_seg.opts.biasreg) '_mars' num2str(cfg_seg.mars.convergence) '_eTPM' '.mat']), '-a2', '-nocrop', '-m4'); close all
% ft_sourceplot([], mri5); %export_fig(gcf, fullfile(path_segplots, [subjdata(iSj).id '_scalp' num2str(cfg_seg.scalpthreshold) '_brain' num2str(cfg_seg.brainthreshold) '_skull' num2str(cfg_seg.skullthreshold) '_bias' num2str(cfg_seg.opts.biasreg) '_mars' num2str(cfg_seg.mars.convergence) '_eTPM' '_origmri.mat']), '-a2', '-nocrop', '-m4'); close all

cfg.atlas           = seg_i6;    % the segmentation can also be used as atlas
ft_sourceplot(cfg, seg_i6); %export_fig(gcf, fullfile(path_segplots, [subjdata(iSj).id '_scalp' num2str(cfg_seg.scalpthreshold) '_brain' num2str(cfg_seg.brainthreshold) '_skull' num2str(cfg_seg.skullthreshold) '_bias' num2str(cfg_seg.opts.biasreg) '_mars' num2str(cfg_seg.mars.convergence) '_eTPM' '.mat']), '-a2', '-nocrop', '-m4'); close all
% ft_sourceplot([], mri6); %export_fig(gcf, fullfile(path_segplots, [subjdata(iSj).id '_scalp' num2str(cfg_seg.scalpthreshold) '_brain' num2str(cfg_seg.brainthreshold) '_skull' num2str(cfg_seg.skullthreshold) '_bias' num2str(cfg_seg.opts.biasreg) '_mars' num2str(cfg_seg.mars.convergence) '_eTPM' '_origmri.mat']), '-a2', '-nocrop', '-m4'); close all

cfg.atlas           = seg_i7;    % the segmentation can also be used as atlas
ft_sourceplot(cfg, seg_i7); %export_fig(gcf, fullfile(path_segplots, [subjdata(iSj).id '_scalp' num2str(cfg_seg.scalpthreshold) '_brain' num2str(cfg_seg.brainthreshold) '_skull' num2str(cfg_seg.skullthreshold) '_bias' num2str(cfg_seg.opts.biasreg) '_mars' num2str(cfg_seg.mars.convergence) '_eTPM' '.mat']), '-a2', '-nocrop', '-m4'); close all
% ft_sourceplot([], mri7); %export_fig(gcf, fullfile(path_segplots, [subjdata(iSj).id '_scalp' num2str(cfg_seg.scalpthreshold) '_brain' num2str(cfg_seg.brainthreshold) '_skull' num2str(cfg_seg.skullthreshold) '_bias' num2str(cfg_seg.opts.biasreg) '_mars' num2str(cfg_seg.mars.convergence) '_eTPM' '_origmri.mat']), '-a2', '-nocrop', '-m4'); close all

