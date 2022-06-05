classdef Audiorama < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
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
        TimeseriesButton            matlab.ui.control.Button
        wavButton                   matlab.ui.control.Button
        SpectrogramButton           matlab.ui.control.Button
        FilterPanel                 matlab.ui.container.Panel
        FilterHzLabel               matlab.ui.control.Label
        FilterFmaxEditField         matlab.ui.control.NumericEditField
        FilterFminEditField         matlab.ui.control.NumericEditField
        FilterSwitch                matlab.ui.control.Switch
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

            % update spectrogram
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
                    app.tstart=datenum(tmp(1),tmp(2),tmp(3),app.hrEditField.Value,app.minEditField.Value,app.sEditField.Value);
            
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
        end

        %% update spectrogram
        function app=update(app)
    
            % read acoustic data if window duration has changed or new start time
            app.duration=app.DurationEditField.Value;
            if app.duration~=length(app.x)/app.Fs || ~strcmp(app.inputimetype,'default')
                app=readin(app);
            end

            if ~app.default
                % read input spectrogram settings
                N=2^nextpow2(app.WindowlengthEditField.Value);
                NFFT=2^nextpow2(app.NFFTEditField.Value);
                app.WindowlengthEditField.Value=N;
                app.NFFTEditField.Value=NFFT;
                Overlap=app.OverlapEditField.Value;
                Fmin=app.FminEditField.Value;
                Fmax=app.FmaxEditField.Value;
                dBmin=app.dBminEditField.Value;
                dBmax=app.dBmaxEditField.Value;
            else
                % default settings
                N=2^(nextpow2(app.Fs/5));
                NFFT=N*2;
                Overlap=75;
                Fmin=0; Fmax=round(app.Fs/4);
                app.WindowlengthEditField.Value=N;
                app.NFFTEditField.Value=NFFT;
                app.OverlapEditField.Value=Overlap;
                app.FminEditField.Value=Fmin;
                app.FmaxEditField.Value=Fmax;
            end

            % Compute spectrogram
            [~,F,T,P]=spectrogram(app.x,N,round(N*Overlap/100),NFFT,app.Fs);

            % Plot spectrogram
            imagesc(app.UIAxes,T,F,10*log10(P)); set(app.UIAxes,'YDir','Normal');

            xlabel(app.UIAxes,'Time (s)')
            ylabel(app.UIAxes,'Frequency (Hz)')
            xlim(app.UIAxes,[T(1) T(end)])
            ylim(app.UIAxes,[Fmin Fmax])

            colormap(app.UIAxes,'jet')
            cb=colorbar(app.UIAxes); 
            ylabel(cb,'dB/Hz');
            
            if app.default
                app.dBminEditField.Value=round(cb.Limits(1));
                app.dBmaxEditField.Value=round(cb.Limits(2));
                dBmin=app.dBminEditField.Value;
                dBmax=app.dBmaxEditField.Value;
            end
            caxis(app.UIAxes,[dBmin dBmax])   

            app.inputimetype='initial';
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
            soundsc(app.x,app.Fs)
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
                % update spectrogram
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
            app.UpdateButton.Position = [10 526 255 81];
            app.UpdateButton.Text = 'Update';

            % Create LoadfileButton
            app.LoadfileButton = uibutton(app.UIFigure, 'push');
            app.LoadfileButton.ButtonPushedFcn = createCallbackFcn(app, @LoadfileButtonPushed, true);
            app.LoadfileButton.Position = [10 480 255 34];
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

            % Create FilterSwitch
            app.FilterSwitch = uiswitch(app.FilterPanel, 'slider');
            app.FilterSwitch.Position = [58 63 45 20];

            % Create FilterFminEditField
            app.FilterFminEditField = uieditfield(app.FilterPanel, 'numeric');
            app.FilterFminEditField.Position = [10 14 49 22];

            % Create FilterFmaxEditField
            app.FilterFmaxEditField = uieditfield(app.FilterPanel, 'numeric');
            app.FilterFmaxEditField.Position = [70 14 49 22];

            % Create FilterHzLabel
            app.FilterHzLabel = uilabel(app.FilterPanel);
            app.FilterHzLabel.HorizontalAlignment = 'center';
            app.FilterHzLabel.Position = [126 13 25 25];
            app.FilterHzLabel.Text = 'Hz';

            % Create ExportPanel
            app.ExportPanel = uipanel(app.UIFigure);
            app.ExportPanel.TitlePosition = 'centertop';
            app.ExportPanel.Title = 'Export';
            app.ExportPanel.FontWeight = 'bold';
            app.ExportPanel.FontSize = 15;
            app.ExportPanel.Position = [1233 480 162 126];

            % Create SpectrogramButton
            app.SpectrogramButton = uibutton(app.ExportPanel, 'push');
            app.SpectrogramButton.Position = [31 71 100 22];
            app.SpectrogramButton.Text = 'Spectrogram';

            % Create wavButton
            app.wavButton = uibutton(app.ExportPanel, 'push');
            app.wavButton.Position = [31 11 100 22];
            app.wavButton.Text = '.wav';

            % Create TimeseriesButton
            app.TimeseriesButton = uibutton(app.ExportPanel, 'push');
            app.TimeseriesButton.Position = [31 41 100 22];
            app.TimeseriesButton.Text = 'Time series';

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
            app.StarttimeLabel.Position = [466 27 188 22];
            app.StarttimeLabel.Text = 'Start time: ';

            % Create EndtimeLabel
            app.EndtimeLabel = uilabel(app.FileinfoPanel);
            app.EndtimeLabel.Position = [466 6 188 22];
            app.EndtimeLabel.Text = 'End time:';

            % Create FsLabel
            app.FsLabel = uilabel(app.FileinfoPanel);
            app.FsLabel.Position = [8 6 91 22];
            app.FsLabel.Text = 'Fs = ';

            % Create Slider
            app.Slider = uislider(app.UIFigure);
            app.Slider.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged, true);
            app.Slider.Position = [16 370 1348 3];

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