classdef Audiorama < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        Switch                      matlab.ui.control.ToggleSwitch
        Slider                      matlab.ui.control.Slider
        FileinfoPanel               matlab.ui.container.Panel
        FsLabel                     matlab.ui.control.Label
        EndtimeLabel                matlab.ui.control.Label
        StarttimeLabel              matlab.ui.control.Label
        NameLabel                   matlab.ui.control.Label
        SkipPanel                   matlab.ui.container.Panel
        SkipBckwdButton             matlab.ui.control.Button
        SkipFwdButton               matlab.ui.control.Button
        FwdButton                   matlab.ui.control.Button
        BckwdButton                 matlab.ui.control.Button
        PlaybackPanel               matlab.ui.container.Panel
        StopButton                  matlab.ui.control.Button
        PlayButton                  matlab.ui.control.Button
        ExportPanel                 matlab.ui.container.Panel
        wavButton                   matlab.ui.control.Button
        SpectrumButton              matlab.ui.control.Button
        SpectrogramButton           matlab.ui.control.Button
        TimeseriesButton            matlab.ui.control.Button
        FilterPanel                 matlab.ui.container.Panel
        FilterSwitch                matlab.ui.control.ToggleSwitch
        FilterHzLabel               matlab.ui.control.Label
        FilterFmaxEditField         matlab.ui.control.NumericEditField
        FilterFminEditField         matlab.ui.control.NumericEditField
        SpectrogramPanel            matlab.ui.container.Panel
        FreezeSwitch                matlab.ui.control.Switch
        FreezesettingsSwitchLabel   matlab.ui.control.Label
        dBLabel                     matlab.ui.control.Label
        HzLabel                     matlab.ui.control.Label
        dBmaxEditField              matlab.ui.control.NumericEditField
        dBminEditField              matlab.ui.control.NumericEditField
        FmaxEditField               matlab.ui.control.NumericEditField
        FminEditField               matlab.ui.control.NumericEditField
        AxesLabel                   matlab.ui.control.Label
        PercentLabel                matlab.ui.control.Label
        OverlapEditField            matlab.ui.control.NumericEditField
        OverlapEditFieldLabel       matlab.ui.control.Label
        NFFTEditField               matlab.ui.control.NumericEditField
        NFFTEditFieldLabel          matlab.ui.control.Label
        WindowlengthEditField       matlab.ui.control.NumericEditField
        WindowlengthEditFieldLabel  matlab.ui.control.Label
        DurationPanel               matlab.ui.container.Panel
        DurationEditField           matlab.ui.control.NumericEditField
        sEditField_2Label           matlab.ui.control.Label
        StartTimePanel              matlab.ui.container.Panel
        sEditField                  matlab.ui.control.NumericEditField
        sEditFieldLabel             matlab.ui.control.Label
        minEditField                matlab.ui.control.NumericEditField
        minEditFieldLabel           matlab.ui.control.Label
        hrEditField                 matlab.ui.control.NumericEditField
        hrEditFieldLabel            matlab.ui.control.Label
        DateDatePicker              matlab.ui.control.DatePicker
        DateDatePickerLabel         matlab.ui.control.Label
        LoadfileButton              matlab.ui.control.Button
        UpdateButton                matlab.ui.control.Button
        UIAxes                      matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        fpath           % path to file 
        fname           % file name
        Fs              % sample rate (Hz)
        ftstart         % file start time
        ftend           % file end time
        fduration       % file duration (s)
        tstart          % window start timee
        duration        % duration (s)
        x               % audio data
        xf              % filtered audio data 
        t               % audio data time vector
        N               % FFT window length
        NFFT            % number of FFT points
        Overlap         % FFT overlap (%)
        Fmin            % display frequency minimum (Hz)
        Fmax            % display frequency maximum (Hz)
        dBmin           % display dB minimum  
        dBmax           % display dB maximum
        P               % Spectrogram (PSD)
        F               % Spectrogram frequency vector (Hz)
        T               % Spectrogram time vector (s)
        default         % default settings flag
        inputimetype    % type of input time
    end
    
    methods (Access = private)

        %% initialize file
        function app=initialize(app)

            % displays file name
            app.NameLabel.Text=['Name: ',app.fname];

            % audio file info
            I=audioinfo([app.fpath,app.fname]);

            % Fs
            app.Fs=I.SampleRate;
            app.FsLabel.Text=sprintf('Fs = %i Hz',round(app.Fs));

            % file duration
            app.fduration=I.Duration;
            
            % file start/end 
            try
                app.ftstart=getFiledate(app.fname);
            catch
                app.ftstart=0;
            end
            if isnan(app.ftstart)
                app.ftstart=0; 
            end
             % set file start as window start
            app.tstart=app.ftstart; 

            app.ftend=app.ftstart+app.fduration/86400;
            app.StarttimeLabel.Text=['Start time:    ',datestr(app.ftstart,'dd-mmm-yyyy HH:MM:SS')];
            app.EndtimeLabel.Text=['End time:     ',datestr(app.ftend,'dd-mmm-yyyy HH:MM:SS')];
       
            app.StarttimeLabel.HorizontalAlignment='right';
            app.EndtimeLabel.HorizontalAlignment='right';
            app=update_date_display(app);

            app.Slider.Limits=[0 app.ftend-app.ftstart];
            app.Slider.Value=0;

            app.inputimetype='default';

            % read acoustic data
            app=readin(app);

          app=update(app);

            % remove default settings flag after first initialization
            app.default=0;
        end

        %% read acoustic data
        function app=readin(app)
            
            if app.default
                if app.fduration<60
                    app.duration=floor(app.fduration);
                else
                    app.duration=60;
                end
                app.DurationEditField.Value=app.duration;
            elseif (app.tstart-app.ftstart)*86400+app.duration<app.fduration
                app.duration=app.DurationEditField.Value;
            end
    
            switch app.inputimetype
                case 'exact'
                    tmp=datevec(app.DateDatePicker.Value);
                    tmp=datenum(tmp(1),tmp(2),tmp(3),app.hrEditField.Value,app.minEditField.Value,app.sEditField.Value);
                    
                    if tmp>=app.ftstart
                    app.tstart=tmp;
                    else
                        beep; disp('Reached edge of audio file.')
                        app=update_date_display(app);
                    end
            
                    app.Slider.Value=app.tstart-app.ftstart;
                case 'slider'
                    app.tstart=app.Slider.Value+app.ftstart;
                    app=update_date_display(app);
            end
            app=update_date_display(app);

            % window first/last samples in file
            nlim(1)=round(((app.tstart-app.ftstart)*86400)*app.Fs)+1;
            nlim(2)=round(nlim(1)+app.duration*app.Fs)-1;

            % read audio file
            app.x=audioread(fullfile(app.fpath,app.fname),nlim);

            % remove mean
            app.x=app.x-mean(app.x);

            % time vector
            app.t=[0:length(app.x)-1]/app.Fs;
        end

        %% update spectrogram
        function app=update_spec(app)
    
            % read acoustic data if window duration has changed or new start time
            app.duration=app.DurationEditField.Value;
            if app.duration~=length(app.x)/app.Fs || ~strcmp(app.inputimetype,'default')
                app=readin(app);
            end

            if ~app.default
                % read input spectrogram settings
                app.N=2^nextpow2(app.WindowlengthEditField.Value);
                app.NFFT=2^nextpow2(app.NFFTEditField.Value);
                app.WindowlengthEditField.Value=app.N;
                app.NFFTEditField.Value=app.NFFT;
                app.Overlap=app.OverlapEditField.Value;
                app.Fmin=app.FminEditField.Value;
                app.Fmax=app.FmaxEditField.Value;
                app.dBmin=app.dBminEditField.Value;
                app.dBmax=app.dBmaxEditField.Value;
            else
                % default settings
                app.N=2^(nextpow2(app.Fs/5));
                app.NFFT=app.N*2;
                app.Overlap=75;
                app.Fmin=0; app.Fmax=round(app.Fs/4);
                app.WindowlengthEditField.Value=app.N;
                app.NFFTEditField.Value=app.NFFT;
                app.OverlapEditField.Value=app.Overlap;
                app.FminEditField.Value=app.Fmin;
                app.FmaxEditField.Value=app.Fmax;
            end

            % Compute spectrogram
            [~,app.F,app.T,app.P]=spectrogram(app.x,app.N,round(app.N*app.Overlap/100),app.NFFT,app.Fs);

            % Plot spectrogram
            imagesc(app.UIAxes,app.T,app.F,10*log10(app.P)); set(app.UIAxes,'YDir','Normal')

            xlabel(app.UIAxes,'Time (s)')
            ylabel(app.UIAxes,'Frequency (Hz)')
            xlim(app.UIAxes,[app.T(1) app.T(end)])
            ylim(app.UIAxes,[app.Fmin app.Fmax])

            colormap(app.UIAxes,'turbo')
            cb=colorbar(app.UIAxes); 
            ylabel(cb,'dB/Hz');
            
            if app.default
                app.dBminEditField.Value=round(cb.Limits(1));
                app.dBmaxEditField.Value=round(cb.Limits(2));
                app.dBmin=app.dBminEditField.Value;
                app.dBmax=app.dBmaxEditField.Value;
            end
            caxis(app.UIAxes,[app.dBmin app.dBmax])   

            app.inputimetype='default';
        end

        %% update time series
        function app=update_time(app)

            % read acoustic data if window duration has changed or new start time
            app.duration=app.DurationEditField.Value;
            if app.duration~=length(app.x)/app.Fs || ~strcmp(app.inputimetype,'default')
                app=readin(app);
            end

            % plot times series
            if strcmp(app.FilterSwitch.Value,'On')
                app=audiorama_filt(app); 
                plot(app.UIAxes,app.t,app.xf)
            else
                plot(app.UIAxes,app.t,app.x)
            end
            grid(app.UIAxes,'on')
            
            xlabel(app.UIAxes,'Time (s)')
            ylabel(app.UIAxes,'Amplitude')
            xlim(app.UIAxes,[app.t(1) app.t(end)])
            
            ylim(app.UIAxes,'auto')
            maxlim=max(abs(get(app.UIAxes,'YLim')));
            ylim(app.UIAxes,[-maxlim maxlim]);

            colorbar(app.UIAxes,'delete');

            app.inputimetype='default';
        end

        %% main update
        function app=update(app)

            switch app.Switch.Value
                case 'Spectrogram'
                    app=update_spec(app);
                case 'Time series'
                    app=update_time(app);
            end
        end

        %% determine file start date from name
        function ftsart=getFiledate(fname)

            nfiles=size(fname,1);

            for fIdx=1:nfiles
                tmp=filename(fIdx,:);

                dateexpr='(?<yr>\d\d)(?<mon>\d\d)(?<day>\d\d)[-_-. ](?<hr>\d\d)(?<min>\d\d)(?<s>\d\d(\.\d\d\d)?)';
                match=regexp(tmp,dateexpr,'names');
                if isempty(match)
                    dateexpr='[_-. ](?<yr>(\d\d)?\d\d)(?<mon>\d\d)(?<day>\d\d)[_-. ]'; %date only
                    match=regexp(tmp, dateexpr, 'names');
                    if isempty(match)
                        ftsart(fIdx,:)=nan;
                    else
                        ftsart(fIdx,:)=datenum([str2double(match.yr) str2double(match.mon) str2double(match.day)]);
                    end
                else
                    ftsart(fIdx,:)=datenum([str2double(match.yr)+2000 str2double(match.mon) str2double(match.day) ...
                        str2double(match.hr) str2double(match.min) str2double(match.s)]);
                end
            end
        end
        
        %% update display start time
        function app=update_date_display(app)    
                % update display date
                if app.ftstart
                    app.DateDatePicker.Value=datetime(str2double(datestr(app.tstart,'yyyy')),...
                    str2double(datestr(app.tstart,'mm')),...
                    str2double(datestr(app.tstart,'dd')));
                else
                    app.DateDatePicker.Value=datetime(0,1,1);
                end
                % update display time
                app.hrEditField.Value=str2double(datestr(app.tstart,'HH'));
                app.minEditField.Value=str2double(datestr(app.tstart,'MM'));
                app.sEditField.Value=str2double(datestr(app.tstart,'SS'));
        end

        %% Filtering function
        function app=audiorama_filt(app)           
            if app.FilterFminEditField.Value==0 && app.FilterFmaxEditField.Value==0
                app.xf=app.x;
            elseif app.FilterFminEditField.Value==0 && app.FilterFmaxEditField.Value~=0
                % highpass
                app.xf=highpass(app.x,app.FilterFmaxEditField.Value,app.Fs);
            elseif app.FilterFminEditField.Value~=0 && app.FilterFmaxEditField.Value==0
                % lowpass
                app.xf=lowpass(app.x,app.FilterFminEditField.Value,app.Fs);
            else
                % bandpass
                app.xf=bandpass(app.x,[app.FilterFminEditField.Value app.FilterFmaxEditField.Value],app.Fs);
            end
        end

    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % app name
            app.UIFigure.Name='Audiorama 2.0 by Ludovic Tenorio-Hallé (2022)';
        end

        % Button pushed function: LoadfileButton
        function LoadfileButtonPushed(app, event)
            if isempty(app.fpath)
                [tmp_name,tmp_path]= uigetfile({'*.wav*'},'Audiorama: select audio file');
            else
                [tmp_name,tmp_path]= uigetfile({'*.wav*'},'Audiorama: select audio file',app.fpath);
            end
            figure(app.UIFigure)

            % if file is selected, assign file name and path and initialize
            if tmp_name~=0
                app.fname=tmp_name;
                app.fpath=tmp_path;
                if strcmp(app.FreezeSwitch.Value,'On')
                    app.default=0;
                else
                    app.default=1;
                end
                app=initialize(app);
            end     
        end

        % Button pushed function: UpdateButton
        function UpdateButtonPushed(app, event)
            app=update(app);
        end

        % Button pushed function: PlayButton
        function PlayButtonPushed(app, event)
             if strcmp(app.FilterSwitch.Value,'On')
                app=audiorama_filt(app); 
                soundsc(app.xf,app.Fs)
            else
                soundsc(app.x,app.Fs)
             end        
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            clear sound
        end

        % Button pushed function: FwdButton
        function FwdButtonPushed(app, event)
            try
                app.tstart=app.tstart+(app.duration/2)/86400;
                app=readin(app);
            catch
                beep
                app.tstart=app.ftend-app.duration/86400;
                app=readin(app);
                disp('Reached edge of audio file.')
            end
            app=update(app);
            app.Slider.Value=app.tstart-app.ftstart;
            app=update_date_display(app);
        end

        % Button pushed function: BckwdButton
        function BckwdButtonPushed(app, event)
            try
                tmp=app.tstart;
                app.tstart=app.tstart-(app.duration/2)/86400;
                app=readin(app);
            catch
                beep
                app.tstart=app.ftstart;
                app=readin(app);
                disp('Reached edge audio file.')
            end
            app=update(app);
            app.Slider.Value=app.tstart-app.ftstart;
            app=update_date_display(app);
        end

        % Button pushed function: SkipFwdButton
        function SkipFwdButtonPushed(app, event)
            % load directory
            D=dir(app.fpath);
            
            % find current file
            I=find(contains({D.name},app.fname));
    
            % move to next wav file
            found_next_wavfile=0;
            while ~found_next_wavfile
                I=I+1;
                if I>length(D)
                    disp('Reached last readable audio file in folder.')
                    beep; return
                end
                [~,~,ext]=fileparts(fullfile(app.fpath,D(I).name));
                if strcmp(ext,'.wav')==1
                    found_next_wavfile=1;
                end
            end
            
            % assign new file name and re-initialize 
            app.fname=D(I).name;
            app=initialize(app);
        end

        % Button pushed function: SkipBckwdButton
        function SkipBckwdButtonPushed(app, event)
            if app.tstart~=app.ftstart
                % go back to the start of the file
                app.tstart=app.ftstart;
                % read acoustic data
                app=readin(app);
                app=update(app);
                app.Slider.Value=app.tstart-app.ftstart;
            else
                % load directory
                D=dir(app.fpath);

                % find current file
                I=find(contains({D.name},app.fname));

                % move to next wav file
                found_previous_wavfile=0;
                while ~found_previous_wavfile
                    I=I-1;
                    if I==0
                        disp('Reached first readable audio file in this folder.')
                        beep; return
                    end
                    [~,~,ext]=fileparts(fullfile(app.fpath,D(I).name));
                    if strcmp(ext,'.wav')==1
                        found_previous_wavfile=1;
                    end
                end

                % assign new file name and re-initialize
                app.fname=D(I).name;
                app=initialize(app);
            end
        end

        % Value changed function: Slider
        function SliderValueChanged(app, event)
            slidervalue=app.Slider.Value;
            app.inputimetype='slider';
        end

        % Value changed function: DateDatePicker
        function DateDatePickerValueChanged(app, event)
            app.inputimetype='exact';
        end

        % Value changed function: hrEditField
        function hrEditFieldValueChanged(app, event)
             app.inputimetype='exact';
        end

        % Value changed function: minEditField
        function minEditFieldValueChanged(app, event)
            app.inputimetype='exact';
        end

        % Value changed function: sEditField
        function sEditFieldValueChanged(app, event)
            app.inputimetype='exact';
        end

        % Button pushed function: wavButton
        function wavButtonPushed(app, event)
            [~,tmp,~]=fileparts(app.fname);
            str=sprintf('%s_sample_%s_%is.wav',tmp,datestr(app.tstart,'yyyymmdd_HHMMSS'),round(app.duration));
            audiowrite(str,app.x,app.Fs);
        end

        % Button pushed function: SpectrumButton
        function SpectrumButtonPushed(app, event)
            [Pxx,Fxx]=pwelch(app.x,app.N,app.Overlap,app.NFFT,app.Fs);
            figure()
            plot(Fxx,10*log10(Pxx),'r','linewidth',1); grid on; grid minor
            xlabel('Frequency (Hz)'); ylabel ('PSD (dB/Hz)')
            xlim([app.Fmin app.Fmax])
            yl=get(gca,'YLim');
            subtitle(sprintf('Filename: %s; Start time: %s; Duration: %i s; N=%i; NFFT=%i; Overlap=%i%%; Fs=%i Hz',...
                app.fname,datestr(app.tstart,'yyyy-mmm-dd HH:MM:SS'),round(app.duration),app.N,app.NFFT,app.Overlap,app.Fs),...
                'fontsize',9,'Interpreter','none','Position',[app.Fmin max(yl)],'horizontalalignment','left')
            set(gcf,'Position',[150 200 1200 500])
        end

        % Button pushed function: SpectrogramButton
        function SpectrogramButtonPushed(app, event)
            figure()
            imagesc(app.T,app.F,10*log10(app.P)); set(gca,'YDir','Normal')
            xlabel('Time (s)'); ylabel('Frequency (Hz)')
            xlim([app.T(1) app.T(end)]); ylim([app.Fmin app.Fmax])
            colormap('turbo')
            cb=colorbar; ylabel(cb,'dB/Hz');
            caxis([app.dBmin app.dBmax])   
            subtitle(sprintf('Filename: %s; Start time: %s; Duration: %i s; N=%i; NFFT=%i; Overlap=%i%%; Fs=%i Hz',...
                app.fname,datestr(app.tstart,'yyyy-mmm-dd HH:MM:SS'),round(app.duration),app.N,app.NFFT,app.Overlap,app.Fs),...
                'fontsize',9,'Interpreter','none','Position',[app.T(1) app.Fmax],'horizontalalignment','left')
            set(gcf,'Position',[50 300 1450 350])
        end

        % Button pushed function: TimeseriesButton
        function TimeseriesButtonPushed(app, event)
            figure()
             if strcmp(app.FilterSwitch.Value,'On')
                app=audiorama_filt(app); 
                plot(app.t,app.xf)
            else
                plot(app.t,app.x)
            end
            grid on; grid minor
            xlabel('Time (s)'); ylabel('Amplitude')
            maxlim=max(abs(get(gca,'YLim')));
            ylim([-maxlim maxlim]);
            str=sprintf('Filename: %s; Start time: %s; Duration: %i s; Fs=%i Hz',...
                app.fname,datestr(app.tstart,'yyyy-mmm-dd HH:MM:SS'),round(app.duration),app.Fs);             
            if strcmp(app.FilterSwitch.Value,'On')
                str=[str,sprintf('; Filter [%i %i] Hz',app.FilterFminEditField.Value,app.FilterFmaxEditField.Value)];
            end
            subtitle(str,'fontsize',9,'Interpreter','none','Position',[app.t(1) maxlim],'horizontalalignment','left')
            set(gcf,'Position',[50 300 1450 350])
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1403 617];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [10 11 1363 312];

            % Create UpdateButton
            app.UpdateButton = uibutton(app.UIFigure, 'push');
            app.UpdateButton.ButtonPushedFcn = createCallbackFcn(app, @UpdateButtonPushed, true);
            app.UpdateButton.Position = [10 526 172 81];
            app.UpdateButton.Text = 'Update';

            % Create LoadfileButton
            app.LoadfileButton = uibutton(app.UIFigure, 'push');
            app.LoadfileButton.ButtonPushedFcn = createCallbackFcn(app, @LoadfileButtonPushed, true);
            app.LoadfileButton.Position = [10 480 172 34];
            app.LoadfileButton.Text = 'Load file';

            % Create StartTimePanel
            app.StartTimePanel = uipanel(app.UIFigure);
            app.StartTimePanel.TitlePosition = 'centertop';
            app.StartTimePanel.Title = 'Start Time';
            app.StartTimePanel.FontWeight = 'bold';
            app.StartTimePanel.FontSize = 15;
            app.StartTimePanel.Position = [683 390 371 79];

            % Create DateDatePickerLabel
            app.DateDatePickerLabel = uilabel(app.StartTimePanel);
            app.DateDatePickerLabel.HorizontalAlignment = 'right';
            app.DateDatePickerLabel.Position = [3 14 31 22];
            app.DateDatePickerLabel.Text = 'Date';

            % Create DateDatePicker
            app.DateDatePicker = uidatepicker(app.StartTimePanel);
            app.DateDatePicker.ValueChangedFcn = createCallbackFcn(app, @DateDatePickerValueChanged, true);
            app.DateDatePicker.Position = [45 14 120 22];

            % Create hrEditFieldLabel
            app.hrEditFieldLabel = uilabel(app.StartTimePanel);
            app.hrEditFieldLabel.Position = [211 14 14 22];
            app.hrEditFieldLabel.Text = 'hr';

            % Create hrEditField
            app.hrEditField = uieditfield(app.StartTimePanel, 'numeric');
            app.hrEditField.ValueChangedFcn = createCallbackFcn(app, @hrEditFieldValueChanged, true);
            app.hrEditField.Position = [172 14 32 22];

            % Create minEditFieldLabel
            app.minEditFieldLabel = uilabel(app.StartTimePanel);
            app.minEditFieldLabel.Position = [266 14 25 22];
            app.minEditFieldLabel.Text = 'min';

            % Create minEditField
            app.minEditField = uieditfield(app.StartTimePanel, 'numeric');
            app.minEditField.ValueChangedFcn = createCallbackFcn(app, @minEditFieldValueChanged, true);
            app.minEditField.Position = [228 14 32 22];

            % Create sEditFieldLabel
            app.sEditFieldLabel = uilabel(app.StartTimePanel);
            app.sEditFieldLabel.Position = [356 14 16 22];
            app.sEditFieldLabel.Text = 's';

            % Create sEditField
            app.sEditField = uieditfield(app.StartTimePanel, 'numeric');
            app.sEditField.ValueChangedFcn = createCallbackFcn(app, @sEditFieldValueChanged, true);
            app.sEditField.Position = [290 14 58 22];

            % Create DurationPanel
            app.DurationPanel = uipanel(app.UIFigure);
            app.DurationPanel.TitlePosition = 'centertop';
            app.DurationPanel.Title = 'Duration';
            app.DurationPanel.FontWeight = 'bold';
            app.DurationPanel.FontSize = 15;
            app.DurationPanel.Position = [1062 390 162 79];

            % Create sEditField_2Label
            app.sEditField_2Label = uilabel(app.DurationPanel);
            app.sEditField_2Label.Position = [140 14 16 22];
            app.sEditField_2Label.Text = 's';

            % Create DurationEditField
            app.DurationEditField = uieditfield(app.DurationPanel, 'numeric');
            app.DurationEditField.Position = [34 14 98 22];

            % Create SpectrogramPanel
            app.SpectrogramPanel = uipanel(app.UIFigure);
            app.SpectrogramPanel.TitlePosition = 'centertop';
            app.SpectrogramPanel.Title = 'Spectrogram';
            app.SpectrogramPanel.FontWeight = 'bold';
            app.SpectrogramPanel.FontSize = 15;
            app.SpectrogramPanel.Position = [683 480 371 126];

            % Create WindowlengthEditFieldLabel
            app.WindowlengthEditFieldLabel = uilabel(app.SpectrogramPanel);
            app.WindowlengthEditFieldLabel.HorizontalAlignment = 'right';
            app.WindowlengthEditFieldLabel.Position = [5 65 84 22];
            app.WindowlengthEditFieldLabel.Text = 'Window length';

            % Create WindowlengthEditField
            app.WindowlengthEditField = uieditfield(app.SpectrogramPanel, 'numeric');
            app.WindowlengthEditField.Position = [104 65 38 22];

            % Create NFFTEditFieldLabel
            app.NFFTEditFieldLabel = uilabel(app.SpectrogramPanel);
            app.NFFTEditFieldLabel.HorizontalAlignment = 'right';
            app.NFFTEditFieldLabel.Position = [53 39 36 22];
            app.NFFTEditFieldLabel.Text = 'NFFT';

            % Create NFFTEditField
            app.NFFTEditField = uieditfield(app.SpectrogramPanel, 'numeric');
            app.NFFTEditField.Position = [104 39 38 22];

            % Create OverlapEditFieldLabel
            app.OverlapEditFieldLabel = uilabel(app.SpectrogramPanel);
            app.OverlapEditFieldLabel.HorizontalAlignment = 'right';
            app.OverlapEditFieldLabel.Position = [42 14 47 22];
            app.OverlapEditFieldLabel.Text = 'Overlap';

            % Create OverlapEditField
            app.OverlapEditField = uieditfield(app.SpectrogramPanel, 'numeric');
            app.OverlapEditField.Position = [104 14 38 22];

            % Create PercentLabel
            app.PercentLabel = uilabel(app.SpectrogramPanel);
            app.PercentLabel.HorizontalAlignment = 'center';
            app.PercentLabel.Position = [144 16 12 18];
            app.PercentLabel.Text = '%';

            % Create AxesLabel
            app.AxesLabel = uilabel(app.SpectrogramPanel);
            app.AxesLabel.HorizontalAlignment = 'center';
            app.AxesLabel.Position = [180 71 43 22];
            app.AxesLabel.Text = 'Axes';

            % Create FminEditField
            app.FminEditField = uieditfield(app.SpectrogramPanel, 'numeric');
            app.FminEditField.Position = [224 71 49 22];

            % Create FmaxEditField
            app.FmaxEditField = uieditfield(app.SpectrogramPanel, 'numeric');
            app.FmaxEditField.Position = [280 71 49 22];

            % Create dBminEditField
            app.dBminEditField = uieditfield(app.SpectrogramPanel, 'numeric');
            app.dBminEditField.Position = [224 42 49 22];

            % Create dBmaxEditField
            app.dBmaxEditField = uieditfield(app.SpectrogramPanel, 'numeric');
            app.dBmaxEditField.Position = [280 42 49 22];

            % Create HzLabel
            app.HzLabel = uilabel(app.SpectrogramPanel);
            app.HzLabel.HorizontalAlignment = 'center';
            app.HzLabel.Position = [328 70 25 25];
            app.HzLabel.Text = 'Hz';

            % Create dBLabel
            app.dBLabel = uilabel(app.SpectrogramPanel);
            app.dBLabel.HorizontalAlignment = 'center';
            app.dBLabel.Position = [328 40 25 25];
            app.dBLabel.Text = 'dB';

            % Create FreezesettingsSwitchLabel
            app.FreezesettingsSwitchLabel = uilabel(app.SpectrogramPanel);
            app.FreezesettingsSwitchLabel.HorizontalAlignment = 'center';
            app.FreezesettingsSwitchLabel.Position = [176 4 91 22];
            app.FreezesettingsSwitchLabel.Text = 'Freeze settings';

            % Create FreezeSwitch
            app.FreezeSwitch = uiswitch(app.SpectrogramPanel, 'slider');
            app.FreezeSwitch.Position = [295 6 43 19];

            % Create FilterPanel
            app.FilterPanel = uipanel(app.UIFigure);
            app.FilterPanel.TitlePosition = 'centertop';
            app.FilterPanel.Title = 'Filter';
            app.FilterPanel.FontWeight = 'bold';
            app.FilterPanel.FontSize = 15;
            app.FilterPanel.Position = [1062 480 162 126];

            % Create FilterFminEditField
            app.FilterFminEditField = uieditfield(app.FilterPanel, 'numeric');
            app.FilterFminEditField.Position = [70 51 49 22];

            % Create FilterFmaxEditField
            app.FilterFmaxEditField = uieditfield(app.FilterPanel, 'numeric');
            app.FilterFmaxEditField.Position = [70 26 49 22];

            % Create FilterHzLabel
            app.FilterHzLabel = uilabel(app.FilterPanel);
            app.FilterHzLabel.HorizontalAlignment = 'center';
            app.FilterHzLabel.Position = [121 25 25 25];
            app.FilterHzLabel.Text = 'Hz';

            % Create FilterSwitch
            app.FilterSwitch = uiswitch(app.FilterPanel, 'toggle');
            app.FilterSwitch.Position = [15 28 20 45];

            % Create ExportPanel
            app.ExportPanel = uipanel(app.UIFigure);
            app.ExportPanel.TitlePosition = 'centertop';
            app.ExportPanel.Title = 'Export';
            app.ExportPanel.FontWeight = 'bold';
            app.ExportPanel.FontSize = 15;
            app.ExportPanel.Position = [1233 390 162 216];

            % Create TimeseriesButton
            app.TimeseriesButton = uibutton(app.ExportPanel, 'push');
            app.TimeseriesButton.ButtonPushedFcn = createCallbackFcn(app, @TimeseriesButtonPushed, true);
            app.TimeseriesButton.Position = [31 143 100 33];
            app.TimeseriesButton.Text = 'Time series';

            % Create SpectrogramButton
            app.SpectrogramButton = uibutton(app.ExportPanel, 'push');
            app.SpectrogramButton.ButtonPushedFcn = createCallbackFcn(app, @SpectrogramButtonPushed, true);
            app.SpectrogramButton.Position = [31 99 100 34];
            app.SpectrogramButton.Text = 'Spectrogram';

            % Create SpectrumButton
            app.SpectrumButton = uibutton(app.ExportPanel, 'push');
            app.SpectrumButton.ButtonPushedFcn = createCallbackFcn(app, @SpectrumButtonPushed, true);
            app.SpectrumButton.Position = [31 57 100 34];
            app.SpectrumButton.Text = 'Spectrum';

            % Create wavButton
            app.wavButton = uibutton(app.ExportPanel, 'push');
            app.wavButton.ButtonPushedFcn = createCallbackFcn(app, @wavButtonPushed, true);
            app.wavButton.Position = [31 13 100 34];
            app.wavButton.Text = '.wav';

            % Create PlaybackPanel
            app.PlaybackPanel = uipanel(app.UIFigure);
            app.PlaybackPanel.TitlePosition = 'centertop';
            app.PlaybackPanel.Title = 'Playback';
            app.PlaybackPanel.FontWeight = 'bold';
            app.PlaybackPanel.FontSize = 15;
            app.PlaybackPanel.Position = [276 480 147 126];

            % Create PlayButton
            app.PlayButton = uibutton(app.PlaybackPanel, 'push');
            app.PlayButton.ButtonPushedFcn = createCallbackFcn(app, @PlayButtonPushed, true);
            app.PlayButton.FontSize = 20;
            app.PlayButton.FontWeight = 'bold';
            app.PlayButton.Position = [14 25 50 50];
            app.PlayButton.Text = '▶';

            % Create StopButton
            app.StopButton = uibutton(app.PlaybackPanel, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.FontSize = 20;
            app.StopButton.FontWeight = 'bold';
            app.StopButton.FontColor = [1 0 0];
            app.StopButton.Position = [84 25 50 50];
            app.StopButton.Text = '■';

            % Create SkipPanel
            app.SkipPanel = uipanel(app.UIFigure);
            app.SkipPanel.TitlePosition = 'centertop';
            app.SkipPanel.Title = 'Skip';
            app.SkipPanel.FontWeight = 'bold';
            app.SkipPanel.FontSize = 15;
            app.SkipPanel.Position = [432 480 242 126];

            % Create BckwdButton
            app.BckwdButton = uibutton(app.SkipPanel, 'push');
            app.BckwdButton.ButtonPushedFcn = createCallbackFcn(app, @BckwdButtonPushed, true);
            app.BckwdButton.FontWeight = 'bold';
            app.BckwdButton.Position = [69 25 50 50];
            app.BckwdButton.Text = '◀◀';

            % Create FwdButton
            app.FwdButton = uibutton(app.SkipPanel, 'push');
            app.FwdButton.ButtonPushedFcn = createCallbackFcn(app, @FwdButtonPushed, true);
            app.FwdButton.FontWeight = 'bold';
            app.FwdButton.Position = [125 25 50 50];
            app.FwdButton.Text = '▶▶';

            % Create SkipFwdButton
            app.SkipFwdButton = uibutton(app.SkipPanel, 'push');
            app.SkipFwdButton.ButtonPushedFcn = createCallbackFcn(app, @SkipFwdButtonPushed, true);
            app.SkipFwdButton.FontWeight = 'bold';
            app.SkipFwdButton.Position = [182 25 50 50];
            app.SkipFwdButton.Text = '▶▶|';

            % Create SkipBckwdButton
            app.SkipBckwdButton = uibutton(app.SkipPanel, 'push');
            app.SkipBckwdButton.ButtonPushedFcn = createCallbackFcn(app, @SkipBckwdButtonPushed, true);
            app.SkipBckwdButton.FontWeight = 'bold';
            app.SkipBckwdButton.Position = [11 25 50 50];
            app.SkipBckwdButton.Text = '|◀◀';

            % Create FileinfoPanel
            app.FileinfoPanel = uipanel(app.UIFigure);
            app.FileinfoPanel.TitlePosition = 'centertop';
            app.FileinfoPanel.Title = 'File info';
            app.FileinfoPanel.FontWeight = 'bold';
            app.FileinfoPanel.FontSize = 15;
            app.FileinfoPanel.Position = [10 390 664 79];

            % Create NameLabel
            app.NameLabel = uilabel(app.FileinfoPanel);
            app.NameLabel.Position = [8 27 426 22];
            app.NameLabel.Text = 'Name:';

            % Create StarttimeLabel
            app.StarttimeLabel = uilabel(app.FileinfoPanel);
            app.StarttimeLabel.Position = [433 27 221 22];
            app.StarttimeLabel.Text = 'Start time: ';

            % Create EndtimeLabel
            app.EndtimeLabel = uilabel(app.FileinfoPanel);
            app.EndtimeLabel.Position = [433 6 221 22];
            app.EndtimeLabel.Text = 'End time:';

            % Create FsLabel
            app.FsLabel = uilabel(app.FileinfoPanel);
            app.FsLabel.Position = [8 6 91 22];
            app.FsLabel.Text = 'Fs = ';

            % Create Slider
            app.Slider = uislider(app.UIFigure);
            app.Slider.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged, true);
            app.Slider.Position = [16 370 1348 3];

            % Create Switch
            app.Switch = uiswitch(app.UIFigure, 'toggle');
            app.Switch.Items = {'Time series', 'Spectrogram'};
            app.Switch.Position = [221 526 18 40];
            app.Switch.Value = 'Spectrogram';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Audiorama

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end