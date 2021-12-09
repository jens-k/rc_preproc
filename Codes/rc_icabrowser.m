function rc_icabrowser(cfg, comp)

% ICA component viewer and GUI
%
% loads in comp structure from FieldTrip ft_componentanalysis
% presents a GUI interface showin the power spectrum, variance over time
% and the topography of the components, as well as the possibility to save
% a PDF, view the timecourse and toggle components to be rejected vs kept.
% when done, will create a file with the components to be rejected
%
% CONFIGURATION NEEDED:
% (cfg.path         where pdfs will be saves)
% cfg.prefix       prefix of the pdf files
% cfg.layout       layout of the topo view
% cfg.existing_rej what do to withe existing rejections
%
% OPTIONAL CONFIGURATION:
% cfg.colormap      colormap for topo
% cfg.inputfile
% cfg.outputfile    will contain indices of all components to reject
%
% original written by Thomas Pfeffer
% adapted by Jonathan Daume and Anne Urai
% University Medical Center Hamburg-Eppendorf, 2015
%
% 2017: Adapted by Jens Klinzing, jens.klinzing@uni-tuebingen.de

% TODO: Add visual artifact marking to the timeseries browser. This has to
% be accumulatively saved and either returned by the function or added to
% an artifact structure the location of which is provided (cfg.artfctdef)
% or something...

%% SETUP

% Rejection categories
defaultcats = {'misc' 'eye', 'tech', 'jmp', 'strict'}; % will be used for output structure and buttons

% ICA components
if isfield(cfg, 'inputfile'), load(cfg.inputfile); end
assert(exist('comp', 'var') > 0, 'Could not find comps in inputfile.');

% Existing rejections
if isfield(cfg, 'inputrej'), 
	inputrej = load(cfg.inputrej); 
	if numel(comp.label) ~= numel(inputrej.rej_comp)
		error('Cannot handle existing rejected components: Number of rejections does not match number of components.')
	elseif ~isfield(inputrej, 'rej_comp') 
		error('Cannot handle existing rejected components: No components found')
	elseif any(inputrej.rej_comp > numel(defaultcats))
		error('Cannot handle existing rejected components: Too many categories.')
		
	% from here it's about category names
	elseif ~isfield(inputrej, 'cats') % does the input have rejection categories?
		inputrej.cats = defaultcats; 
		warning('Adding rejection categories to input.')
	elseif numel(inputrej.cats) ~= numel(defaultcats) % if so, are they in the correct number?
		error('Cannot handle existing rejected components: Number of rejection categories different from 4.')
	elseif any(~strcmp(inputrej.cats, defaultcats)) % if so, are they exactly the same?
		warning('Cannot handle existing rejected components: Categories do not match default categories. Better doublecheck.')
	end
	rej_comp = inputrej.rej_comp;
	cats = inputrej.cats;
else
	rej_comp = [];
	rej_comp = zeros(size(comp.label,1),1);
	cats = defaultcats;
end


%% START
var_data = cat(2,comp.trial{:});
var_time = (1:(size(var_data,2)))/comp.fsample;
% only do the fft on a subset of trials, saves time
fft_data = cat(2,comp.trial{1:5:end});
% preallocate rejected components

subpl	= 4;
l		= 0;		% current subplot
cnt		= 1;		% current page
il		= 0;		% current subplot on current page
logar	= 0;		% default logarithmic or linear scale for powspctrm

% set path
% path = cfg.path;
% if ~exist(path, 'dir'),
%     mkdir path;
% end
% prefix = cfg.prefix;

% to save time redoing this for each topo
cfglay = keepfields(cfg, {'layout'});
lay = ft_prepare_layout(cfglay); %, comp);

cfgtopo = [];
cfgtopo.layout    = lay;     % specify the layout file that should be used for plotting
cfgtopo.comment   = 'no';
cfgtopo.highlight = 'off';
cfgtopo.marker    = 'off';
cfgtopo.style     = 'straight';
if isfield(cfg, 'colormap'),  cfgtopo.colormap  = cfg.colormap;  end

err = 0;
manpos = [0.1 0.1 0.8 0.8]; % figure position, can be updated later

% ------------------------------------------------
% COMPUTE LATENCY FOR 2s-WINDOWS
% ------------------------------------------------

slen = floor(2*comp.fsample);
smax = floor(size(var_data,2)/slen);
comp_var  = nan(subpl, smax); % preallocate
comp_time = nan(1, smax);     % preallocate
for s = 1 : smax
	comp_time(s) = mean(var_time(1,(s-1)*slen+1:s*slen));
end

while err == 0 % KEEP GOING UNTIL THERE IS AN ERROR
	
	% OPEN THE OVERVIEW WINDOW
	while il < subpl, % il is the subplot count
		
		il = il + 1;
		i = (cnt-1)*subpl+il;
		
		if mod(i-1,subpl)==0
			% keep manual screen position - better in dual monitor settings
			f = figure('units','normalized','outerposition', manpos);
			% 			set(f,'position',get(0,'ScreenSize'));
			l = l + 1;
		end
		
		% ------------------------------------------------
		% COMPUTE VARIANCE FOR 2s-WINDOWS
		% ------------------------------------------------
		
		for s = 1 : smax
			comp_var(i,s)=var(var_data(i,(s-1)*slen+1:s*slen));
		end
		
		% ------------------------------------------------
		% COMPUTE POWER SPECTRUM
		% ------------------------------------------------
		smo = 50;
		steps = 10;
		Fs = comp.fsample;
		N = floor(size(fft_data,2));
		xdft = fft(fft_data(i,:));
		xdft = xdft(1:N/2+1);
		psdx = (1/(Fs*N)).*abs(xdft).^2;
		psdx(2:end-1) = 2*psdx(2:end-1);
		
		j = 1;
		k = 1;
		while j < length(psdx)-smo
			smoothed(k)=mean(psdx(j:j+smo));
			j = j + steps;
			k = k + 1;
		end
		
		freq = linspace(0,Fs/2,size(smoothed,2));
		strt = find(freq > 2,1,'first');
		stp  = find(freq < 120,1,'last');
		
		% ------------------------------------------------
		% PLOT POWER SPECTRUM
		% ------------------------------------------------
		subcomp{1}{il} = subplot(subpl,3,(i-(l-1)*subpl)*3-2);
		if logar
			plot(freq(strt:stp),log10(smoothed(strt:stp)));
			ylabel('(dB/Hz)');
		else
			plot(freq(strt:stp),smoothed(strt:stp));
			ylabel('uV^2/Hz');
		end
		set(gca,'TickDir','out','XTick',0:25:200)
		xlabel('Frequency (Hz)'); grid on;
		axis tight;
		
		% ------------------------------------------------
		% PLOT VARIANCE OVER TIME
		% ------------------------------------------------
		subcomp{2}{il} = subplot(subpl,3,(i-(l-1)*subpl)*3-1);
		scatter(comp_time,comp_var(i,:),'k.');
		xlabel('Time (s)'); ylabel('Variance');
		axis tight; set(gca, 'tickdir', 'out');
		
		% ------------------------------------------------
		% PLOT COMPONENT TOPOGRAPHY
		% ------------------------------------------------
		subcomp{3}{il} = subplot(subpl,3,(i-(l-1)*subpl)*3);
		cfgtopo.component = i;       % specify the component(s) that should be plotted
		ft_topoplotIC(cfgtopo, comp);
					
		% ------------------------------------------------
		% BUTTONS
		% ------------------------------------------------
		if mod(i,subpl)==0 || i == 80			% 80 ???
			
			% Show timelines button
			tc = uicontrol('Units','normalized','Position',[0.92 0.07 0.075 0.035],...
				'Style','pushbutton','String','Timecourse','Callback',{@tcs, cnt});
			
			% a-d are the rejection categories
			pos_1 = [0.72 0.73 0.032 0.035; ...
				     0.75 0.73 0.032 0.035; ...
				     0.78 0.73 0.032 0.035; ...
				     0.81 0.73 0.032 0.035; ...
					 0.84 0.73 0.032 0.035];
			pos_2 = [0.72 0.51 0.032 0.035; ...
				     0.75 0.51 0.032 0.035; ...
				     0.78 0.51 0.032 0.035; ...
				     0.81 0.51 0.032 0.035; ...
					 0.84 0.51 0.032 0.035];
			pos_3 = [0.72 0.29 0.032 0.035; ...
				     0.75 0.29 0.032 0.035; ...
				     0.78 0.29 0.032 0.035; ...
				     0.81 0.29 0.032 0.035; ...
					 0.84 0.29 0.032 0.035];
			pos_4 = [0.72 0.07 0.032 0.035; ...
				     0.75 0.07 0.032 0.035; ...
				     0.78 0.07 0.032 0.035; ...
				     0.81 0.07 0.032 0.035; ...
					 0.84 0.07 0.032 0.035];			 
			
			% Determine background for all rejection categories 
			% (bga = background a)
			for ibga = 1:4
				if rej_comp(i+(ibga-4)) == 1
					bga{ibga} = 'r';
				else
					bga{ibga} = 'g';
				end
			end
			for ibgb = 1:4
				if rej_comp(i+(ibgb-4)) == 2
					bgb{ibgb} = 'r';
				else
					bgb{ibgb} = 'g';
				end
			end			
			for ibgc = 1:4
				if rej_comp(i+(ibgc-4)) == 3
					bgc{ibgc} = 'r';
				else
					bgc{ibgc} = 'g';
				end
			end
			for ibgd = 1:4
				if rej_comp(i+(ibgd-4)) == 4
					bgd{ibgd} = 'r';
				else
					bgd{ibgd} = 'g';
				end
			end		
			for ibge = 1:4
				if rej_comp(i+(ibge-4)) == 5
					bge{ibge} = 'r';
				else
					bge{ibge} = 'g';
				end
			end				

			% REJECT COMPONENT
			rej1a = uicontrol('Units','normalized','Tag','rej1a','Position',pos_1(1,:),'Style','pushbutton','String',cats{1}, ...
				'Backgroundcolor',bga{1},'Callback',@rej1a_callback);
			rej1b = uicontrol('Units','normalized','Tag','rej1b','Position',pos_1(2,:),'Style','pushbutton','String',cats{2}, ...
				'Backgroundcolor',bgb{1},'Callback',@rej1b_callback);			
			rej1c = uicontrol('Units','normalized','Tag','rej1c','Position',pos_1(3,:),'Style','pushbutton','String',cats{3}, ...
				'Backgroundcolor',bgc{1},'Callback',@rej1c_callback);
			rej1d = uicontrol('Units','normalized','Tag','rej1d','Position',pos_1(4,:),'Style','pushbutton','String',cats{4}, ...
				'Backgroundcolor',bgd{1},'Callback',@rej1d_callback);
			rej1e = uicontrol('Units','normalized','Tag','rej1e','Position',pos_1(5,:),'Style','pushbutton','String',cats{5}, ...
				'Backgroundcolor',bge{1},'Callback',@rej1e_callback);
			
			rej2a = uicontrol('Units','normalized','Tag', 'rej2a','Position',pos_2(1,:),'Style','pushbutton','String',cats{1}, ...
				'Backgroundcolor',bga{2},'Callback',@rej2a_callback);
			rej2b = uicontrol('Units','normalized','Tag', 'rej2b','Position',pos_2(2,:),'Style','pushbutton','String',cats{2}, ...
				'Backgroundcolor',bgb{2},'Callback',@rej2b_callback);			
			rej2c = uicontrol('Units','normalized','Tag', 'rej2c','Position',pos_2(3,:),'Style','pushbutton','String',cats{3}, ...
				'Backgroundcolor',bgc{2},'Callback',@rej2c_callback);
			rej2d = uicontrol('Units','normalized','Tag', 'rej2d','Position',pos_2(4,:),'Style','pushbutton','String',cats{4}, ...
				'Backgroundcolor',bgd{2},'Callback',@rej2d_callback);
			rej2e = uicontrol('Units','normalized','Tag', 'rej2e','Position',pos_2(5,:),'Style','pushbutton','String',cats{5}, ...
				'Backgroundcolor',bge{2},'Callback',@rej2e_callback);
			
			rej3a = uicontrol('Units','normalized','Tag', 'rej3a','Position',pos_3(1,:),'Style','pushbutton','String',cats{1}, ...
				'Backgroundcolor',bga{3},'Callback',@rej3a_callback);
			rej3b = uicontrol('Units','normalized','Tag', 'rej3b','Position',pos_3(2,:),'Style','pushbutton','String',cats{2}, ...
				'Backgroundcolor',bgb{3},'Callback',@rej3b_callback);			
			rej3c = uicontrol('Units','normalized','Tag', 'rej3c','Position',pos_3(3,:),'Style','pushbutton','String',cats{3}, ...
				'Backgroundcolor',bgc{3},'Callback',@rej3c_callback);			
			rej3d = uicontrol('Units','normalized','Tag', 'rej3d','Position',pos_3(4,:),'Style','pushbutton','String',cats{4}, ...
				'Backgroundcolor',bgd{3},'Callback',@rej3d_callback);
			rej3e = uicontrol('Units','normalized','Tag', 'rej3e','Position',pos_3(5,:),'Style','pushbutton','String',cats{5}, ...
				'Backgroundcolor',bge{3},'Callback',@rej3e_callback);
			
			rej4a = uicontrol('Units','normalized','Tag', 'rej4a','Position',pos_4(1,:),'Style','pushbutton','String',cats{1}, ...
				'Backgroundcolor',bga{4},'Callback',@rej4a_callback);
			rej4b = uicontrol('Units','normalized','Tag', 'rej4b','Position',pos_4(2,:),'Style','pushbutton','String',cats{2}, ...
				'Backgroundcolor',bgb{4},'Callback',@rej4b_callback);			
			rej4c = uicontrol('Units','normalized','Tag', 'rej4c','Position',pos_4(3,:),'Style','pushbutton','String',cats{3}, ...
				'Backgroundcolor',bgc{4},'Callback',@rej4c_callback);
			rej4d = uicontrol('Units','normalized','Tag', 'rej4d','Position',pos_4(4,:),'Style','pushbutton','String',cats{4}, ...
				'Backgroundcolor',bgd{4},'Callback',@rej4d_callback);
			rej4e = uicontrol('Units','normalized','Tag', 'rej4e','Position',pos_4(5,:),'Style','pushbutton','String',cats{5}, ...
				'Backgroundcolor',bge{4},'Callback',@rej4e_callback);


			% SAVE COMPONENT PDF
			%             savecomp1 = uicontrol('Units','normalized','Position',[0.86 0.78 0.075 0.035],'Style','pushbutton','String','Save PDF','Callback',{@sc_cb, 1});
			%             savecomp2 = uicontrol('Units','normalized','Position',[0.86 0.56 0.075 0.035],'Style','pushbutton','String','Save PDF','Callback',{@sc_cb, 2});
			%             savecomp3 = uicontrol('Units','normalized','Position',[0.86 0.34 0.075 0.035],'Style','pushbutton','String','Save PDF','Callback',{@sc_cb, 3});
			%             savecomp4 = uicontrol('Units','normalized','Position',[0.86 0.12 0.075 0.035],'Style','pushbutton','String','Save PDF','Callback',{@sc_cb, 4});
			
			% MOVE TO NEXT
			% "nextplot" = previous plot
			% "lastplot" = next plot 
			
			if i > 4
				prev = uicontrol('Units','normalized','Position',[0.1 0.01 0.075 0.05],'Style','pushbutton','String','Prev','Callback',@nextplot);
			else
				prev = uicontrol('Units','normalized','Position',[0.1 0.01 0.075 0.05],'Style','pushbutton','String','');
			end
			
			if i < size(comp.label,1)-3
				next = uicontrol('Units','normalized','Position',[0.2 0.01 0.075 0.05],'Style','pushbutton','String','Next','Callback',@lastplot);
			else
				next = uicontrol('Units','normalized','Position',[0.2 0.01 0.075 0.05],'Style','pushbutton','String','');
			end
			
			% CHANGE FREQUENCY AXIS
			logarith = uicontrol('Units','normalized','Position',[0.3 0.01 0.075 0.05],'Style','pushbutton','String','Log10','Callback',@plotlog);
			lin      = uicontrol('Units','normalized','Position',[0.4 0.01 0.075 0.05],'Style','pushbutton','String','Linear','Callback',@plotlin);
			
			% SAVE AND QUIT
			s = uicontrol('Units','normalized','Position',[0.90 0.01 0.075 0.05], ...
				'Style','pushbutton','String','Save','Callback',@save_callback);
% 			quit_it = uicontrol('Units','normalized','Position',[0.80 0.01 0.075 0.05],...
% 				'Style','pushbutton','String','Quit','Callback',@quitme);
			orient landscape
			uiwait
		end
	end
end

% ------------------------------------------------
% DEFINE NESTED CALLBACK FUNCTIONS
% ------------------------------------------------

	% Rejection category A
	function rej1a_callback(h, evt)
		rej1a = findobj('Tag','rej1a');
		if (rej_comp(i-3) ~= 1),
			set(rej1a,'Backgroundcolor','r'),
			set(rej1b,'Backgroundcolor','g'),
			set(rej1c,'Backgroundcolor','g'),
			set(rej1d,'Backgroundcolor','g'),
			set(rej1e,'Backgroundcolor','g'),
			rej_comp(i-3)=1;	
		else
			set(rej1a,'Backgroundcolor','g'),
			rej_comp(i-3)=0;
		end
	end
	function rej2a_callback(h, evt)
		rej2a = findobj('Tag','rej2a');
		if (rej_comp(i-2) ~= 1),
			set(rej2a,'Backgroundcolor','r'),
			set(rej2b,'Backgroundcolor','g'),
			set(rej2c,'Backgroundcolor','g'),
			set(rej2d,'Backgroundcolor','g'),
			set(rej2e,'Backgroundcolor','g'),
			rej_comp(i-2)=1;
		else
			set(rej2a,'Backgroundcolor','g'),
			rej_comp(i-2)=0;
		end
	end
	function rej3a_callback(h, evt)
		rej3a = findobj('Tag','rej3a');
		if (rej_comp(i-1) ~= 1),
			set(rej3a,'Backgroundcolor','r'),
			set(rej3b,'Backgroundcolor','g'),
			set(rej3c,'Backgroundcolor','g'),
			set(rej3d,'Backgroundcolor','g'),
			set(rej3e,'Backgroundcolor','g'),
			rej_comp(i-1)=1;
		else
			set(rej3a,'Backgroundcolor','g'),
			rej_comp(i-1)=0;
		end
	end
	function rej4a_callback(h, evt)
		rej4a = findobj('Tag','rej4a');
		if (rej_comp(i-0) ~= 1),
			set(rej4a,'Backgroundcolor','r'),
			set(rej4b,'Backgroundcolor','g'),
			set(rej4c,'Backgroundcolor','g'),
			set(rej4d,'Backgroundcolor','g'),
			set(rej4e,'Backgroundcolor','g'),
			rej_comp(i-0)=1;
		else
			set(rej4a,'Backgroundcolor','g'),
			rej_comp(i-0)=0;
		end
	end

	% Rejection category B
	function rej1b_callback(h, evt)
		rej1b = findobj('Tag','rej1b');
		if (rej_comp(i-3) ~= 2),
			set(rej1a,'Backgroundcolor','g'),
			set(rej1b,'Backgroundcolor','r'),
			set(rej1c,'Backgroundcolor','g'),
			set(rej1d,'Backgroundcolor','g'),
			set(rej1e,'Backgroundcolor','g'),
			rej_comp(i-3)=2;	% 3 = rejection category c
		else
			set(rej1a,'Backgroundcolor','g'),
			rej_comp(i-3)=0;
		end
	end
	function rej2b_callback(h, evt)
		rej2b = findobj('Tag','rej2b');
		if (rej_comp(i-2) ~= 2),
			set(rej2a,'Backgroundcolor','g'),
			set(rej2b,'Backgroundcolor','r'),
			set(rej2c,'Backgroundcolor','g'),
			set(rej2d,'Backgroundcolor','g'),
			set(rej2e,'Backgroundcolor','g'),
			rej_comp(i-2)=2;
		else
			set(rej2b,'Backgroundcolor','g'),
			rej_comp(i-2)=0;
		end
	end
	function rej3b_callback(h, evt)
		rej3b = findobj('Tag','rej3b');
		if (rej_comp(i-1) ~= 2),
			set(rej3a,'Backgroundcolor','g'),
			set(rej3b,'Backgroundcolor','r'),
			set(rej3c,'Backgroundcolor','g'),
			set(rej3d,'Backgroundcolor','g'),
			set(rej3e,'Backgroundcolor','g'),
			rej_comp(i-1)=2;
		else
			set(rej3b,'Backgroundcolor','g'),
			rej_comp(i-1)=0;
		end
	end
	function rej4b_callback(h, evt)
		rej4b = findobj('Tag','rej4b');
		if (rej_comp(i-0) ~= 2),
			set(rej4a,'Backgroundcolor','g'),
			set(rej4b,'Backgroundcolor','r'),
			set(rej4c,'Backgroundcolor','g'),
			set(rej4d,'Backgroundcolor','g'),
			set(rej4e,'Backgroundcolor','g'),
			rej_comp(i-0)=2;
		else
			set(rej4b,'Backgroundcolor','g'),
			rej_comp(i-0)=0;
		end
	end

	% Third rejection category C
	function rej1c_callback(h, evt)
		rej1c = findobj('Tag','rej1c');
		if (rej_comp(i-3) ~= 3),
			set(rej1a,'Backgroundcolor','g'),
			set(rej1b,'Backgroundcolor','g'),
			set(rej1c,'Backgroundcolor','r'),
			set(rej1d,'Backgroundcolor','g'),
			set(rej1e,'Backgroundcolor','g'),
			rej_comp(i-3)=3;	% 3 = rejection category c
		else
			set(rej1c,'Backgroundcolor','g'),
			rej_comp(i-3)=0;
		end
	end
	function rej2c_callback(h, evt)
		rej2c = findobj('Tag','rej2c');
		if (rej_comp(i-2) ~= 3),
			set(rej2a,'Backgroundcolor','g'),
			set(rej2b,'Backgroundcolor','g'),
			set(rej2c,'Backgroundcolor','r'),
			set(rej2d,'Backgroundcolor','g'),
			set(rej2e,'Backgroundcolor','g'),
			rej_comp(i-2)=3;
		else
			set(rej2c,'Backgroundcolor','g'),
			rej_comp(i-2)=0;
		end
	end
	function rej3c_callback(h, evt)
		rej3c = findobj('Tag','rej3c');
		if (rej_comp(i-1) ~= 3),
			set(rej3a,'Backgroundcolor','g'),
			set(rej3b,'Backgroundcolor','g'),
			set(rej3c,'Backgroundcolor','r'),
			set(rej3d,'Backgroundcolor','g'),
			set(rej3e,'Backgroundcolor','g'),
			rej_comp(i-1)=3;
		else
			set(rej3c,'Backgroundcolor','g'),
			rej_comp(i-1)=0;
		end
	end
	function rej4c_callback(h, evt)
		rej4c = findobj('Tag','rej4c');
		if (rej_comp(i-0) ~= 3),
			set(rej4a,'Backgroundcolor','g'),
			set(rej4b,'Backgroundcolor','g'),
			set(rej4c,'Backgroundcolor','r'),
			set(rej4d,'Backgroundcolor','g'),
			set(rej4e,'Backgroundcolor','g'),
			rej_comp(i-0)=3;
		else
			set(rej4c,'Backgroundcolor','g'),
			rej_comp(i-0)=0;
		end
	end

	% Rejection category D
	function rej1d_callback(h, evt)
		rej1d = findobj('Tag','rej1d');
		if (rej_comp(i-3) ~= 4),
			set(rej1a,'Backgroundcolor','g'),
			set(rej1b,'Backgroundcolor','g'),
			set(rej1c,'Backgroundcolor','g'),
			set(rej1d,'Backgroundcolor','r'),
			set(rej1e,'Backgroundcolor','g'),
			rej_comp(i-3)=4;	% 3 = rejection category c
		else
			set(rej1d,'Backgroundcolor','g'),
			rej_comp(i-3)=0;
		end
	end
	function rej2d_callback(h, evt)
		rej2d = findobj('Tag','rej2d');
		if (rej_comp(i-2) ~= 4),
			set(rej2a,'Backgroundcolor','g'),
			set(rej2b,'Backgroundcolor','g'),
			set(rej2c,'Backgroundcolor','g'),
			set(rej2d,'Backgroundcolor','r'),
			set(rej2e,'Backgroundcolor','g'),
			rej_comp(i-2)=4;
		else
			set(rej2d,'Backgroundcolor','g'),
			rej_comp(i-2)=0;
		end
	end
	function rej3d_callback(h, evt)
		rej3d = findobj('Tag','rej3d');
		if (rej_comp(i-1) ~= 4),
			set(rej3a,'Backgroundcolor','g'),
			set(rej3b,'Backgroundcolor','g'),
			set(rej3c,'Backgroundcolor','g'),
			set(rej3d,'Backgroundcolor','r'),
			set(rej3e,'Backgroundcolor','g'),
			rej_comp(i-1)=4;
		else
			set(rej3d,'Backgroundcolor','g'),
			rej_comp(i-1)=0;
		end
	end
	function rej4d_callback(h, evt)
		rej4d = findobj('Tag','rej4d');
		if (rej_comp(i-0) ~= 4),
			set(rej4a,'Backgroundcolor','g'),
			set(rej4b,'Backgroundcolor','g'),
			set(rej4c,'Backgroundcolor','g'),
			set(rej4d,'Backgroundcolor','r'),
			set(rej4e,'Backgroundcolor','g'),
			rej_comp(i-0)=4;
		else
			set(rej4d,'Backgroundcolor','g'),
			rej_comp(i-0)=0;
		end
	end

	% Rejection category E
	function rej1e_callback(h, evt)
		rej1e = findobj('Tag','rej1e');
		if (rej_comp(i-3) ~= 5),
			set(rej1a,'Backgroundcolor','g'),
			set(rej1b,'Backgroundcolor','g'),
			set(rej1c,'Backgroundcolor','g'),
			set(rej1d,'Backgroundcolor','g'),
			set(rej1e,'Backgroundcolor','r'),
			rej_comp(i-3)=5;	
		else
			set(rej1e,'Backgroundcolor','g'),
			rej_comp(i-3)=0;
		end
	end
	function rej2e_callback(h, evt)
		rej2e = findobj('Tag','rej2e');
		if (rej_comp(i-2) ~= 5), % 5 = reject category 5 = E
			set(rej2a,'Backgroundcolor','g'),
			set(rej2b,'Backgroundcolor','g'),
			set(rej2c,'Backgroundcolor','g'),
			set(rej2d,'Backgroundcolor','g'),
			set(rej2e,'Backgroundcolor','r'),
			rej_comp(i-2)=5;
		else
			set(rej2e,'Backgroundcolor','g'),
			rej_comp(i-2)=0;
		end
	end
	function rej3e_callback(h, evt)
		rej3e = findobj('Tag','rej3e');
		if (rej_comp(i-1) ~= 5),
			set(rej3a,'Backgroundcolor','g'),
			set(rej3b,'Backgroundcolor','g'),
			set(rej3c,'Backgroundcolor','g'),
			set(rej3d,'Backgroundcolor','g'),
			set(rej3e,'Backgroundcolor','r'),
			rej_comp(i-1)=5;
		else
			set(rej3e,'Backgroundcolor','g'),
			rej_comp(i-1)=0;
		end
	end
	function rej4e_callback(h, evt)
		rej4e = findobj('Tag','rej4e');
		if (rej_comp(i-0) ~= 5),
			set(rej4a,'Backgroundcolor','g'),
			set(rej4b,'Backgroundcolor','g'),
			set(rej4c,'Backgroundcolor','g'),
			set(rej4d,'Backgroundcolor','g'),
			set(rej4e,'Backgroundcolor','r'),
			rej_comp(i-0)=5;
		else
			set(rej4e,'Backgroundcolor','g'),
			rej_comp(i-0)=0;
		end
	end

% single timecourse funcs
	function tc_cb(h, evt, whichcomp)
		cfgtc = [];
		cfgtc.layout = lay;
		cfgtc.viewmode = 'butterfly';
		cfgtc.channel = [i+(4-whichcomp)];
		% cfgtc.ylim = [-5e-13 5e-13];
		ft_databrowser(cfgtc, comp);
	end

% all timecourses
	function tcs(~,~,page)
		cfgtc = [];
		cfgtc.layout = lay;
		cfgtc.viewmode = 'component';
		cfgtc.channel = (ceil(page/4)-1)*16+1 : ceil(page/4)*16;  % (cnt-1)*4+1:(cnt-1+4)*4;
		% cfgtc.ylim = [-5e-13 5e-13];
		cfgtc.blocksize = 30;
		ft_databrowser(cfgtc, comp);
	end

% save to figure
% 	function sc_cb(h, evt, whichcomp)
% 		h = figure;
% 		set(h,'Position',[200 200 1000 300]);
% 		set(h,'Units','inches');
% 		screenposition = get(h,'Position');
% 		set(h, 'PaperPosition',[0 0 screenposition(3:4)],'PaperSize',[screenposition(3:4)]);
% 		new = copyobj(subcomp{1}{whichcomp},h);
% 		set(new,'Position',[.05 .1 0.25 0.85]);
% 		new = copyobj(subcomp{2}{whichcomp},h);
% 		set(new,'Position',[.35 .1 0.25 0.85]);
% 		set(new,'LineWidth',2);
% 		new = copyobj(subcomp{3}{whichcomp},h); set(new,'Position',[.55 .05 0.5 0.95]);
% 		
% 		% save under the correct comp nr
% 		compnrs = [i-3 : i];
% 		print(h,'-dpdf',sprintf('%s/%s_comp%d.pdf', path, prefix, compnrs(whichcomp)));
% 		fprintf('saved pdf to %s/%s_comp%d.pdf', path, prefix, compnrs(whichcomp));
% 		close(h)
% 	end

% gui
	function nextplot(h, evt)
		manpos = get(f,'OuterPosition');
		cnt = cnt - 1;
		il = 0;
		l = l - 2;
		close all;
	end

	% Next plot
	function lastplot(h, evt)
		manpos = get(f,'OuterPosition');
		cnt = cnt + 1;
		il = 0; 
		close all;
	end

	function plotlog(h, evt)
		manpos = get(f,'OuterPosition');
		il = 0;
		logar = 1;
		l = l - 1; 
		close all;
	end

	function plotlin(h, evt)
		manpos = get(f,'OuterPosition');
		il = 0; logar = 0; l = l - 1; 
		close all;
	end

	function save_callback(h, evt)
		idx = find(rej_comp~=0);
		if isfield(cfg, 'outputfile')
			save(cfg.outputfile,'idx', 'rej_comp', 'cats');
		else
			save(sprintf('%s/%s_rejectedcomps.mat', cfg.path, cfg.prefix), 'idx', 'rej_comp', 'cats');
		end
		close(f);
		err = 1;
		fprintf('Rejected %s components in dataset ''%s''. \n', num2str(numel(idx)), comp.id)
	end

	function CloseRequestFcn
		save_callback
	end
% 
% 	function quitme(h, evt)
% 		idx = find(rej_comp~=0);
% 		if isfield(cfg, 'outputfile')
% 			save(cfg.outputfile,'idx', 'rej_comp', 'cats');
% 		else
% 			save(sprintf('%s/%s_rejectedcomps.mat', cfg.path, cfg.prefix), 'idx', 'rej_comp', 'cats');
% 		end
% 		close(f);
% 		err = 1;
% 		fprintf('Rejected %s components in dataset ''%s''. \n', num2str(numel(idx)), comp.id)
% 	end

end % main function
