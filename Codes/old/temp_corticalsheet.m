
cd(abpath('Y:\Jens\Reactivated Connectivity\temp_corticalsheet'));

% Lets segment the MNI brain and next to it the S01 brain
mri_spm             = ft_read_mri(fullfile(path_root, 'fieldtrip','template','anatomy','single_subj_T1_1mm.nii'));
mri_spm.coordsys	= 'spm';

cfg            = [];
cfg.resolution = 1;
cfg.dim        = [256 256 256];
mrirs          = ft_volumereslice(cfg, mri_spm);
transform_vox2spm = mrirs.transform; % thats actually just shifting it a bit since its already in spm space

save('transform_vox2spm', 'transform_vox2spm');

% save the resliced anatomy in a FreeSurfer compatible format
cfg             = [];
cfg.filename    = 'MNI';
cfg.filetype    = 'nifti'; % nifti for windows, mgz for linux/mac
cfg.parameter   = 'anatomy';
ft_volumewrite(cfg, mrirs);

cfg = [];
cfg.output = 'brain';
seg = ft_volumesegment(cfg, mrirs);
mrirs.anatomy = mrirs.anatomy.*double(seg.brain);

cfg             = [];
cfg.filename    = 'MNImasked';
cfg.filetype    = 'nifti';
cfg.parameter   = 'anatomy';
ft_volumewrite(cfg, mrirs);


	