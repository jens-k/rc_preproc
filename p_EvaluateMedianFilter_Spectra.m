addpath(genpath('C:\Users\lanan\Documents\Github\rc_preproc\'))
% ft_defaults

addpath(genpath('C:\Users\lanan\Documents\MATLAB\fieldtrip\'))
%% General comments
% I wrote this code example down there without ever running it; please
% think of it as a broad pointer into the right direction.

%% ------     FIRST-TIME SETUP
% init_rc;
paths                       = [];
paths.root                  = 'D:\Sleep\DataDownload';
paths.data                  = 'D:\Sleep\DataDownload\Recordings\DNight';
paths.sl_hypnograms         = 'D:\Sleep\DataDownload\Hypnograms';

files = dir(strcat(paths.data,filesep,'*.mff'));

%% Get trial description
% load('D:\Sleep\DataDownload\Recordings\cfg_trial.mat')


subj = 13; % fos subject 29

data_filename   = files(subj).name;
hyp_filename    = strcat('s',data_filename(4:5),'_n',data_filename(6),'.txt');


cfg_trial{subj}						= [];
cfg_trial{subj}.dataset             = fullfile(paths.data, data_filename);%Doing now with subject 12, session 1
cfg_trial{subj}.trialdef.pre		= 5; % all the .trialdef fields are just forwarded to the cfg.trialfun
cfg_trial{subj}.trialdef.post	    = 15;
cfg_trial{subj}.epoch_length_sec    = 30;
cfg_trial{subj}.hypnogram			= fullfile(paths.sl_hypnograms,hyp_filename);%Doing now with subject 12, session 1
cfg_trial{subj}.trialfun            = 'rc_trialfun_2021'; % 
cfg_trial{subj}.id                  = data_filename(1:6); % unique recording ID for future reference
cfg_trial{subj}.counter				= subj;		% to easier find the dataset again later on
cfg_trial{subj}						= ft_definetrial(cfg_trial{subj});


%% Preprocessing: filtering

channels_wo_face   = {'all', '-E49', '-E48', '-E43', '-E127', '-E126', '-E17', '-E128', '-E32', '-E25', '-E21', '-E14', '-E8', '-E1', '-E125', '-E120', '-E119', '-E113','-VREF'};

% The output of ft_definetrial can be used for ft_preprocessing, so we dont
% have to preprocess and filter the whole dataset, and we save time.

cfg_preproc                     = cfg_trial{subj};
cfg_preproc.channel             = 'all';
cfg_preproc.detrend             = 'yes';
cfg_preproc.lpfilter            = 'yes';
cfg_preproc.lpfilttype          = 'fir';
cfg_preproc.lpfreq              = 30;
cfg_preproc.trials              = 36; % From trial 36, it appears the specific noise we are looking for 
cfg_preproc.medianfilter        = 'yes';
cfg_preproc.medianfiltord       = 30;


data_preproc                    = ft_preprocessing(cfg_preproc);


%% IRASA for spectrum following Jens suggestions and code

cf					= [];
cf.trials           = 36; % From trial 36 the specific noise we are looking for appears
cf.length			= 4;  % cut data into segments of this length (in sec)
cf.overlap			= 0;  % with this overlap
data_sleep_cut		= ft_redefinetrial(cf, data_preproc);


% Calculate spectra channel 45
cfg_spect           = [];
cfg_spect.method	= 'irasa';
cfg_spect.pad		= 'nextpow2';
% cfg_spect.trials    = 36;
cfg_spect.channel   = 'E45'; % Noisy channel
cfg_spect.foilim    = [10 20];
fra					= ft_freqanalysis(cfg_spect, data_sleep_cut);

cfg_spect.method 	= 'mtmfft';
cfg_spect.taper 	= 'hanning';
mix					= ft_freqanalysis(cfg_spect, data_sleep_cut);

% Calculate the oscillatory component by subtracting the fractal from the
% mixed component
cfg_temp			= [];
cfg_temp.parameter	= 'powspctrm';
cfg_temp.operation	= 'subtract';
osc					= ft_math(cfg_temp, mix, fra);

% Use percent change for even more obvious peaks
cfg_temp.operation	= 'divide';
rel					= ft_math(cfg_temp, osc, fra);

% Fill output structure
spectra_4sec_ord40_chan45          = [];
spectra_4sec_ord40_chan45.fra      = fra.powspctrm;
spectra_4sec_ord40_chan45.mix      = mix.powspctrm;
spectra_4sec_ord40_chan45.osc      = osc.powspctrm;
spectra_4sec_ord40_chan45.rel      = rel.powspctrm;
spectra_4sec_ord40_chan45.freq     = rel.freq; % add frequency vector

% Calculate spectra channel 47
cfg_spect           = [];
cfg_spect.method	= 'irasa';
cfg_spect.pad		= 'nextpow2';
% cfg_spect.trials    = 36;
cfg_spect.channel   = 'E47'; % NOT Noisy channel
cfg_spect.foilim    = [10 20];
fra					= ft_freqanalysis(cfg_spect, data_sleep_cut);

cfg_spect.method 	= 'mtmfft';
cfg_spect.taper 	= 'hanning';
mix					= ft_freqanalysis(cfg_spect, data_sleep_cut);

% Calculate the oscillatory component by subtracting the fractal from the
% mixed component
cfg_temp			= [];
cfg_temp.parameter	= 'powspctrm';
cfg_temp.operation	= 'subtract';
osc					= ft_math(cfg_temp, mix, fra);

% Use percent change for even more obvious peaks
cfg_temp.operation	= 'divide';
rel					= ft_math(cfg_temp, osc, fra);

% Fill output structure
spectra_4sec_ord40_chan47          = [];
spectra_4sec_ord40_chan47.fra      = fra.powspctrm;
spectra_4sec_ord40_chan47.mix      = mix.powspctrm;
spectra_4sec_ord40_chan47.osc      = osc.powspctrm;
spectra_4sec_ord40_chan47.rel      = rel.powspctrm;
spectra_4sec_ord40_chan47.freq     = rel.freq; % add frequency vector


%%

figure();
hold on;
plot(spectra_4sec_ord0_chan45.freq, spectra_4sec_ord0_chan45.osc,'k');
plot(spectra_4sec_ord2_chan45.freq, spectra_4sec_ord2_chan45.osc,'m');
plot(spectra_4sec_ord10_chan45.freq, spectra_4sec_ord10_chan45.osc,'b');
plot(spectra_4sec_ord20_chan45.freq, spectra_4sec_ord20_chan45.osc,'g');
plot(spectra_4sec_ord30_chan45.freq, spectra_4sec_ord30_chan45.osc,'r');
plot(spectra_4sec_ord40_chan45.freq, spectra_4sec_ord40_chan45.osc,'k');


title('Oscillatory channel E45')
xlabel('freq'); ylabel('power');
legend({'no median filt','median ord 2','median ord 10','median ord 20','median ord 30','median ord 40'},'location','northeast');


figure();
hold on;
plot(spectra_4sec_ord0_chan45.freq, spectra_4sec_ord0_chan45.fra,'k');
plot(spectra_4sec_ord2_chan45.freq, spectra_4sec_ord2_chan45.fra,'m');
plot(spectra_4sec_ord10_chan45.freq, spectra_4sec_ord10_chan45.fra,'b');
plot(spectra_4sec_ord20_chan45.freq, spectra_4sec_ord20_chan45.fra,'g');
plot(spectra_4sec_ord30_chan45.freq, spectra_4sec_ord30_chan45.fra,'r');
plot(spectra_4sec_ord40_chan45.freq, spectra_4sec_ord40_chan45.fra,'k');


title('Fractal channel E45')
xlabel('freq'); ylabel('power');
legend({'no median filt','median ord 2','median ord 10','median ord 20','median ord 30','median ord 40'},'location','northeast');


figure();
hold on;
plot(spectra_4sec_ord0_chan45.freq, spectra_4sec_ord0_chan45.rel,'k');
plot(spectra_4sec_ord2_chan45.freq, spectra_4sec_ord2_chan45.rel,'m');
plot(spectra_4sec_ord10_chan45.freq, spectra_4sec_ord10_chan45.rel,'b');
plot(spectra_4sec_ord20_chan45.freq, spectra_4sec_ord20_chan45.rel,'g');
plot(spectra_4sec_ord30_chan45.freq, spectra_4sec_ord30_chan45.rel,'r');
plot(spectra_4sec_ord40_chan45.freq, spectra_4sec_ord40_chan45.rel,'k');


title('Relative channel E45')
xlabel('freq'); ylabel('power');
legend({'no median filt','median ord 2','median ord 10','median ord 20','median ord 30','median ord 40'},'location','northeast');

%%

figure();
hold on;
plot(spectra_4sec_ord0_chan47.freq, spectra_4sec_ord0_chan47.osc,'k');
plot(spectra_4sec_ord2_chan47.freq, spectra_4sec_ord2_chan47.osc,'m');
plot(spectra_4sec_ord10_chan47.freq, spectra_4sec_ord10_chan47.osc,'b');
plot(spectra_4sec_ord20_chan47.freq, spectra_4sec_ord20_chan47.osc,'g');
plot(spectra_4sec_ord30_chan47.freq, spectra_4sec_ord30_chan47.osc,'r');
plot(spectra_4sec_ord40_chan47.freq, spectra_4sec_ord40_chan47.osc,'k');


title('Oscillatory channel E47')
xlabel('freq'); ylabel('power');
legend({'no median filt','median ord 2','median ord 10','median ord 20','median ord 30','median ord 40'},'location','northeast');


figure();
hold on;
plot(spectra_4sec_ord0_chan47.freq, spectra_4sec_ord0_chan47.fra,'k');
plot(spectra_4sec_ord2_chan47.freq, spectra_4sec_ord2_chan47.fra,'m');
plot(spectra_4sec_ord10_chan47.freq, spectra_4sec_ord10_chan47.fra,'b');
plot(spectra_4sec_ord20_chan47.freq, spectra_4sec_ord20_chan47.fra,'g');
plot(spectra_4sec_ord30_chan47.freq, spectra_4sec_ord30_chan47.fra,'r');
plot(spectra_4sec_ord40_chan47.freq, spectra_4sec_ord40_chan47.fra,'k');


title('Fractal channel E47')
xlabel('freq'); ylabel('power');
legend({'no median filt','median ord 2','median ord 10','median ord 20','median ord 30','median ord 40'},'location','northeast');


figure();
hold on;
plot(spectra_4sec_ord0_chan47.freq, spectra_4sec_ord0_chan47.rel,'k');
plot(spectra_4sec_ord2_chan47.freq, spectra_4sec_ord2_chan47.rel,'m');
plot(spectra_4sec_ord10_chan47.freq, spectra_4sec_ord10_chan47.rel,'b');
plot(spectra_4sec_ord20_chan47.freq, spectra_4sec_ord20_chan47.rel,'g');
plot(spectra_4sec_ord30_chan47.freq, spectra_4sec_ord30_chan47.rel,'r');
plot(spectra_4sec_ord40_chan47.freq, spectra_4sec_ord40_chan47.rel,'k');


title('Relative channel E47')
xlabel('freq'); ylabel('power');
legend({'no median filt','median ord 2','median ord 10','median ord 20','median ord 30','median ord 40'},'location','northeast');
