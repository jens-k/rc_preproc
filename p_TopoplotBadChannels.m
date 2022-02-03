%% Topoplot bad channels

p_ArtifactsDefinition


bad_chans = artifacts.badchans;

for recording = 1:numel(bad_chans)
    if ~isempty(bad_chans{1,recording})
        
        cfg             = [];
        cfg.layout      = 'GSN-HydroCel-129.sfp';

        idx_badchans    = ismember(layout.label',bad_chans{1,recording});  % Get the index of the to-be-highlighted channel

        cfg.channel     = bad_chans{1,recording};
        layout          = ft_prepare_layout(cfg);
        
        
        figure
        ft_plot_layout(layout)
        title(artifacts.dataset{1,recording}, 'Interpreter', 'none');
        
        saveas(gcf,strcat(artifacts.dataset{1,recording},'.png'))
    end
end