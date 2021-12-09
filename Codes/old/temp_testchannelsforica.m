path_origin             = paths.rs_artreject;
files                   = get_filenames(path_origin, 'full');

iFile = 16;
data_eog                = load_file(files{iFile});

cfg                     = [];
cfg.channel = channels_wo_face_with_eog3;
data_eog = ft_selectdata(cfg, data_eog);


cfg                     = [];
cfg.resamplefs          = 300;
cfg.resamplemethod      = 'resample';   % probably default: filters the data prior to downsampling
cfg.detrend             = 'no';
data_eog = ft_resampledata(cfg, data_eog);

cfg                     = [];
cfg.method              = 'runica';
data                = ft_componentanalysis(cfg, data_eog);

% Coherence Plot
for i = 1       % just so we can fold it
    % Let's go through some pain to show the components most correlated to
    % the eye channels
    cfg                     = [];
    cfg.reref               = 'yes';
    cfg.channel             = {'E25', 'E8'};
    cfg.refchannel          = 'E25';
    data_eogh               = ft_preprocessing(cfg, data_eog);
    chidx                   = find(strcmp(data_eogh.label, 'E8'));
    data_eogh.label{chidx}  = 'EOG_H';
    
    cfg.channel             = {'E14', 'E126'};
    cfg.refchannel          = 'E14';
    data_eogv               = ft_preprocessing(cfg, data_eog);
    chidx                   = find(strcmp(data_eogv.label, 'E126'));
    data_eogv.label{chidx}  = 'EOG_V';
    
    cfg                     = [];
    cfg.channel             = {'EOG_H'};
    data_eogh                = ft_selectdata(cfg, data_eogh);
    cfg.channel             = {'EOG_V'};
    data_eogv                = ft_selectdata(cfg, data_eogv);
    data_app                = ft_appenddata([], data_eogv, data_eogh, data);
    
    cfg                     = [];  % lets cut the data in 4s-trials to calculate coherence
    cfg.length              = 4;
    data_red                = ft_redefinetrial(cfg, data_app);
    
    cfg                     = [];
    cfg.method              = 'mtmfft';
    cfg.output              = 'fourier';
    cfg.foi                 = [0.4:0.2:2];
    cfg.taper               = 'hanning';
    cfg.pad                 = 'maxperlen';
    freq                    = ft_freqanalysis(cfg, data_red);
    cfg                     = [];
    cfg.channelcmb          = {'all' 'EOG_V'; 'all' 'EOG_H'};
    cfg.method              = 'coh';
    %     cfg.complex             = 'real';   % because zero-lag connectivity will be represented in the real part of coherence
    fdcomp                  = ft_connectivityanalysis(cfg, freq);
    % Lets separate the PPCs with one and the other channel and plot them in order
    spctrm_a        = abs(fdcomp.cohspctrm(strcmp(fdcomp.labelcmb(:,2), 'EOG_V')));
    spctrm_labels_a = (fdcomp.labelcmb(strcmp(fdcomp.labelcmb(:,2), 'EOG_V')));
    spctrm_b        = abs(fdcomp.cohspctrm(strcmp(fdcomp.labelcmb(:,2), 'EOG_H')));
    spctrm_labels_b = (fdcomp.labelcmb(strcmp(fdcomp.labelcmb(:,2), 'EOG_H')));
    [~,a]           = sort(mean(spctrm_a,2), 'descend'); % get sorted indices
    [~,b]           = sort(mean(spctrm_b,2), 'descend');
    % Show the coherence values for both EOG channels
    clear labels_a values_a labels_b values_b
    for i = 1:numel(a)
        labels_a{i} = spctrm_labels_a{a(i)};    % labels in order
        values_a(i) = spctrm_a(a(i));           % values in order
    end
    for i = 1:numel(b)
        labels_b{i} = spctrm_labels_b{b(i)};
        values_b(i) = spctrm_b(b(i));
    end
    figure
    subplot(2,2,1)
    bar(values_a(1:15))
    set(gca,'xticklabel',labels_a(1:15))
    %     set(gca, 'ylim', [0 .4])
    set(gca,'XTickLabelRotation', 90);
    title('Top 15 Coh with EOG_V')
    subplot(2,2,3)
    bar(values_b(1:15))
    set(gca,'xticklabel',labels_b(1:15))
    %     set(gca, 'ylim', [0 .4])
    set(gca,'XTickLabelRotation', 90);
    title('Top 15 Coh with EOG_H')
    subplot(2,2,2)
    bar(values_a)
    %     set(gca, 'ylim', [0 .4])
    title('All Coh with EOG_V')
    subplot(2,2,4)
    bar(values_b)
    %     set(gca, 'ylim', [0 .4])
    title('All Coh with EOG_H')
    set(gcf, 'Position', get(0,'Screensize')); % maximize figure
end

% Other plots
for iComps = 1:numel(components)
    for i =1 % just so we can fold it
        % Plot topoplots
        figure
        cfg                         = [];
        cfg.component               = components{iComps};  % specify the component(s) that should be plotted
        cfg.layout                  = 'egi_corrected.sfp'; % specify the layout file that should be used for plotting
        cfg.comment                 = 'no';
        cfg.marker                  = 'off';
        cfg.gridscale               = 200;
        ft_topoplotIC(cfg, data);
        h{1} = gcf;
        screen                      = get(0, 'ScreenSize');
        borders                     = get(gcf,'OuterPosition') - get(gcf,'Position');
        edge                        = -borders(1)/2;
        pos_topo                    =   [edge,...                 % from left
            35,...                    % from bottom
            screen(3)/2 - 100 - edge,...    % width
            screen(4)-40];            % height
        set(h{1},'OuterPosition', pos_topo)
        
        % Plot timelines
        cfg                         = [];
        cfg.viewmode                = 'component';
        cfg_plot.ylim               = [-8 8];
        cfg.layout                  = 'egi_corrected.sfp';
        cfg.channel                 = components{iComps};
        cfg.blocksize               = 12;
        ft_databrowser(cfg, data);
        h{2} = gcf;
        borders                     = get(gcf,'OuterPosition') - get(gcf,'Position');
        edge                        = -borders(1)/2;
        pos_compo                   =   [pos_topo(1) + pos_topo(3) + edge,...
            screen(4)/4 + 10,...
            screen(3)/2 + 100 - edge,...
            screen(4)*3/4 - 10];
        set(h{2},'OuterPosition',pos_compo), for t = 1:50000, t; end, pause(0.2);
        set(h{2},'OuterPosition',pos_compo)
        
        % Plot EOG timelines
        cfg_eog                    = [];
        cfg_eog.layout             = 'egi_corrected.sfp';
        cfg_eog.ylim               = [-80 80];
        cfg_eog.viewmode           = 'vertical';
        cfg_eog.channel            = {'EOG_V', 'EOG_H'};
        cfg_eog.blocksize          = 12;
        ft_databrowser(cfg_eog, data_app); % pause(0.4)
        h{3} = gcf;
        borders                     = get(h{3},'OuterPosition') - get(h{3},'Position');
        edge                        = -borders(1)/2;
        pos_peri                    = [pos_topo(1) + pos_topo(3) + edge + 65,...     % from left
            35,...                                       % from bottom
            screen(3)/2 - edge + 100 - 65,...            % width
            screen(4)/4 - 25];                           % height
        set(h{3},'OuterPosition',pos_peri)
        for t = 1:50000, t; end
        set(h{3},'OuterPosition',pos_peri)
        for t = 1:50000, t; end
        set(h{3},'OuterPosition',pos_peri)
        for t = 1:50000, t; end, pause(0.2);
        set(h{3},'OuterPosition',pos_peri)
        for t = 1:50000, t; end
        set(h{3},'OuterPosition',pos_peri)
        for t = 1:50000, t; end
        set(h{3},'OuterPosition',pos_peri)
        disp(['Showing file ' get_filenames(path_origin, iFile)])
        set(h{3},'OuterPosition',pos_peri)
        input('Press ENTER to go on.')
        close(h{1}); close(h{2}); close(h{3}); clear h
    end
end