classdef Audiorama_v01 < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        FhighEditField          matlab.ui.control.NumericEditField
        FhighEditFieldLabel     matlab.ui.control.Label
        FlowEditField           matlab.ui.control.NumericEditField
        FlowEditFieldLabel      matlab.ui.control.Label
        Switch                  matlab.ui.control.Switch
        Button_2                matlab.ui.control.Button
        Button                  matlab.ui.control.Button
        StopButton              matlab.ui.control.Button
        SelectfileButton        matlab.ui.control.Button
        PlayButton              matlab.ui.control.Button
        TimeSeriesButton        matlab.ui.control.Button
        SpectrogramButton       matlab.ui.control.Button
        dBmaxEditField          matlab.ui.control.NumericEditField
        dBminEditField          matlab.ui.control.NumericEditField
        FmaxEditField           matlab.ui.control.NumericEditField
        FminEditField           matlab.ui.control.NumericEditField
        OverlapEditField        matlab.ui.control.NumericEditField
        NfftDropDown            matlab.ui.control.DropDown
        WindowDropDown          matlab.ui.control.DropDown
        DurationEditField       matlab.ui.control.NumericEditField
        SecondEditField         matlab.ui.control.NumericEditField
        MinuteEditField         matlab.ui.control.NumericEditField
        HourEditField           matlab.ui.control.NumericEditField
        DateDatePicker          matlab.ui.control.DatePicker
        UpdateButton            matlab.ui.control.Button
        FminEditFieldLabel      matlab.ui.control.Label
        DaysLabel               matlab.ui.control.Label
        FilterLabel             matlab.ui.control.Label
        dBmaxEditFieldLabel     matlab.ui.control.Label
        dBminEditFieldLabel     matlab.ui.control.Label
        NfftDropDownLabel       matlab.ui.control.Label
        ExportFiguresLabel      matlab.ui.control.Label
        StarttimeLabel          matlab.ui.control.Label
        FmaxEditFieldLabel      matlab.ui.control.Label
        PlaybackLabel           matlab.ui.control.Label
        WindowDropDownLabel     matlab.ui.control.Label
        FilenameLabel           matlab.ui.control.Label
        SpectrogramLabel        matlab.ui.control.Label
        DurationEditFieldLabel  matlab.ui.control.Label
        OverlapEditFieldLabel   matlab.ui.control.Label
        SecondEditFieldLabel    matlab.ui.control.Label
        MinuteEditFieldLabel    matlab.ui.control.Label
        HourEditFieldLabel      matlab.ui.control.Label
        DateDatePickerLabel     matlab.ui.control.Label
        Slider                  matlab.ui.control.Slider
        UIAxes                  matlab.ui.control.UIAxes
    end


    properties (Access = private)
        fname
        fullpath
        x
        t
        Fs
        P
        T
        F
        tstart_file
        tend_file
        tstart
        tlen
        N
        Nfft
        ovrlap
        Fmin
        Fmax
        dBmin
        dBmax
        HH
        MM
        SS
        input_time
        quick_update
        Flow
        Fhigh
        xfilt
    end

    methods (Access = private)

        %% Initialization function
        function initialize(app)

            % select file in finder
            if isempty(app.fullpath)
                [tmp_name,tmp_path]= uigetfile({'*.*','All Files (*.*)'},'File Selector');
            else
                [tmp_name,tmp_path]= uigetfile({'*.*','All Files (*.*)'},'File Selector',app.fullpath);
            end
            figure(app.UIFigure)

            % if file is selected
            if tmp_name~=0
                app.fname=tmp_name;
                app.fullpath=tmp_path;

                % displays file name
                app.FilenameLabel.Text=['Filename: ',app.fname];

                % extract file start/end time
                tmp=strsplit(app.fname,'_');
                app.tstart_file=datenum([tmp{5},tmp{6}],'yymmddHHMMSS');
                I=audioinfo([app.fullpath,app.fname]);
                app.tend_file=app.tstart_file+I.Duration/86400;

                % sets slider limits based based on file start/end time
                app.Slider.Limits=[0 app.tend_file-app.tstart_file];

                % set file start time as default time
                tmp=datestr(app.tstart_file,'yyyy-mm-dd-HH-MM-SS');
                tmp=strsplit(tmp,'-');
                app.HourEditField.Value=str2double(tmp{4});
                app.MinuteEditField.Value=str2double(tmp{5});
                app.SecondEditField.Value=str2double(tmp{6});
                app.DateDatePicker.Value=datetime(str2double(tmp{1}),...
                    str2double(tmp{2}),str2double(tmp{3}));

                % set default duration and spectrogram settings
                app.tlen=app.DurationEditField.Value;
                app.N=str2double(app.WindowDropDown.Value);
                app.Nfft=str2double(app.NfftDropDown.Value);
                app.ovrlap=app.OverlapEditField.Value;
                app.Fmin=app.FminEditField.Value;
                app.Fmax=app.FmaxEditField.Value;
                app.dBmax=app.dBmaxEditField.Value;
                app.dBmin=app.dBminEditField.Value;

                % set default filtering settings
                app.Flow=app.FlowEditField.Value;
                app.Fhigh=app.FhighEditField.Value;

                % plot spectrogram
                app.input_time='manual';
                app.quick_update=0;
                [app.x,app.t,app.Fs,app.P,app.T,app.F]=update_func(app);
            end
        end

        %% Update start time and spectrogram function
        function [x,t,Fs,P,T,F]=update_func(app)

            % set start time from manual date/time input values
            if strcmp(app.input_time,'manual')==1
                tmp=datestr(app.DateDatePicker.Value,'yyyy-mm-dd');
                tmp=strsplit(tmp,'-');

                app.tstart=datenum(str2double(tmp{1}),str2double(tmp{2}),str2double(tmp{3}),...
                    app.HourEditField.Value,...
                    app.MinuteEditField.Value,...
                    app.SecondEditField.Value);

                % update slider position
                app.Slider.Value=app.tstart-app.tstart_file;

                % start time based on slider position
            else

                % update display date
                app.DateDatePicker.Value=datetime(str2double(datestr(app.tstart,'yyyy')),...
                    str2double(datestr(app.tstart,'mm')),...
                    str2double(datestr(app.tstart,'dd')));

                % update display time
                app.HourEditField.Value=str2double(datestr(app.tstart,'HH'));
                app.MinuteEditField.Value=str2double(datestr(app.tstart,'MM'));
                app.SecondEditField.Value=str2double(datestr(app.tstart,'SS'));
            end

            % Read data for given start time and duration
            [x,Fs,t,app.tstart_file,app.tend_file]=...
                read_GOM_data([app.fullpath,app.fname],app.tstart,app.tstart+app.tlen/86400);

            % Compute spectrogram
            [~,F,T,P]=spectrogram(x,app.N,round(app.N*app.ovrlap),app.Nfft,Fs);

            % Plot spectrogram
            imagesc(app.UIAxes,T,F,10*log10(P)); set(app.UIAxes,'YDir','Normal')

            xlabel(app.UIAxes,'Time (s)')
            ylabel(app.UIAxes,'Frequency (Hz)')
            xlim(app.UIAxes,[T(1) T(end)]); ylim(app.UIAxes,[app.Fmin app.Fmax])

            cb=colorbar(app.UIAxes); ylabel(cb,'Power (dB)');
            caxis(app.UIAxes,[app.dBmin app.dBmax]); colormap(app.UIAxes,'jet')

            set(app.UIAxes,'FontSize',15)
            title(app.UIAxes,'')
        end

        %% Filtering function
        function xfilt=custom_filt(app)

            % highpass
            if isempty(app.Flow) || isnan(app.Flow)
                m=[0 1];
                f=[app.Fhigh app.Fhigh+0.1*app.Fhigh];
                dev=[0.05 0.01];
                % lowpass
            elseif isempty(app.Fhigh) || isnan(app.Fhigh)
                m=[1 0];
                f=[app.Flow-0.1*app.Flow app.Flow];
                dev=[0.01 0.05];
                % bandpass
            else
                m=[0 1 0];
                fmean=mean([app.Flow app.Fhigh]);
                f=[app.Flow-0.1*fmean app.Flow app.Fhigh app.Fhigh+0.1*fmean];
                dev=[0.05 0.01 0.05];
            end

            % design filter
            [n,fo,mo,w]=firpmord(f,m,dev,app.Fs);
            B=firpm(n,fo,mo,w);

            % apply filter
            xfilt=filtfilt(B,1,app.x);
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % app name
            app.UIFigure.Name='Audiorama';
        end

        % Button pushed function: UpdateButton
        function UpdateButtonPushed(app, event)
            if ~app.quick_update
                [app.x,app.t,app.Fs,app.P,app.T,app.F]=update_func(app);
            end
        end

        % Button pushed function: PlayButton
        function PlayButtonPushed(app, event)

            if strcmp(app.Switch.Value,'On')==1

                app.xfilt=custom_filt(app);
                soundsc(app.xfilt,app.Fs)

            else
                soundsc(app.x,app.Fs)
            end
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            clear sound
        end

        % Value changed function: Slider
        function SliderValueChanged(app, event)
            app.tstart=app.Slider.Value+app.tstart_file;
            app.input_time='slider';
        end

        % Value changed function: SecondEditField
        function SecondEditFieldValueChanged(app, event)
            app.SS=app.SecondEditField.Value;
            app.input_time='manual';
        end

        % Value changed function: DateDatePicker
        function DateDatePickerValueChanged(app, event)
            app.input_time='manual';
        end

        % Value changed function: OverlapEditField
        function OverlapEditFieldValueChanged(app, event)
            app.ovrlap=app.OverlapEditField.Value;
        end

        % Value changed function: MinuteEditField
        function MinuteEditFieldValueChanged(app, event)
            app.MM=app.MinuteEditField.Value;
            app.input_time='manual';
        end

        % Value changed function: HourEditField
        function HourEditFieldValueChanged(app, event)
            app.HH=app.HourEditField.Value;
            app.input_time='manual';
        end

        % Button pushed function: Button_2
        function Button_2Pushed(app, event)
            app.tstart=app.tstart+(app.tlen/86400)/2;
            app.input_time='slider';
            [app.x,app.Fs]=update_func(app);
        end

        % Button pushed function: Button
        function ButtonPushed(app, event)
            app.tstart=app.tstart-(app.tlen/86400)/2;
            app.input_time='slider';
            [app.x,app.Fs]=update_func(app);
        end

        % Value changed function: DurationEditField
        function DurationEditFieldValueChanged(app, event)
            app.tlen=app.DurationEditField.Value;
        end

        % Value changed function: WindowDropDown
        function WindowDropDownValueChanged2(app, event)
            app.N=str2double(app.WindowDropDown.Value);
        end

        % Button pushed function: SpectrogramButton
        function SpectrogramButtonPushed(app, event)
            figure()

            imagesc(app.T,app.F,10*log10(app.P))
            xlabel('Time (s)'); ylabel('Frequency (Hz)')
            xlim([app.T(1) app.T(end)]); ylim([app.Fmin app.Fmax])

            cb=colorbar; ylabel(cb,'Power (dB)');
            caxis([app.dBmin app.dBmax]); colormap('jet')

            set(gca,'FontSize',12)
            set(gca,'YDir','Normal')
            set(gcf,'Position',[75 350 1200 300])

            title(sprintf('Filename: %s\nStart time: %s\nSpectrogram: Window = %i; Overlap = %.2f%%; Nfft = %i',...
                app.fname,datestr(app.tstart),app.N,app.ovrlap,app.Nfft),'Interpreter','none')
        end

        % Value changed function: FmaxEditField
        function FmaxEditFieldValueChanged(app, event)
            app.Fmax=app.FmaxEditField.Value;
            ylim(app.UIAxes,[app.Fmin app.Fmax])
            app.quick_update=1;
        end

        % Button pushed function: TimeSeriesButton
        function TimeSeriesButtonPushed(app, event)

            figure()

            if strcmp(app.Switch.Value,'On')==1

                app.xfilt=custom_filt(app);
                plot(app.t,app.xfilt)

                title(sprintf('Filename: %s\nStart time: %s\nFilter: [%.2f %.2f Hz]',...
                    app.fname,datestr(app.tstart),app.Flow,app.Fhigh),'Interpreter','none')

            else
                plot(app.t,app.x)
                title(sprintf('Filename: %s\nStart time: %s',...
                    app.fname,datestr(app.tstart)),'Interpreter','none')
            end
            grid on
            xlabel('Time (s)'); ylabel('Amplitude (uncalibrated)')

            set(gca,'FontSize',12)
            set(gcf,'Position',[75 350 1200 300])
        end

        % Value changed function: NfftDropDown
        function NfftDropDownValueChanged(app, event)
            app.Nfft=str2double(app.NfftDropDown.Value);
        end

        % Value changed function: dBmaxEditField
        function dBmaxEditFieldValueChanged(app, event)
            app.dBmax=app.dBmaxEditField.Value;
            caxis(app.UIAxes,[app.dBmin app.dBmax]);
            app.quick_update=1;
        end

        % Value changed function: dBminEditField
        function dBminEditFieldValueChanged(app, event)
            app.dBmin=app.dBminEditField.Value;
            caxis(app.UIAxes,[app.dBmin app.dBmax]);
            app.quick_update=1;
        end

        % Callback function
        function FlowEditFieldValueChanged(app, event)
            app.Flow=str2double(app.FlowEditField.Value);
        end

        % Callback function
        function FhighEditFieldValueChanged(app, event)
            app.Fhigh=str2double(app.FhighEditField.Value);
        end

        % Callback function
        function PlayFilteredButtonPushed(app, event)
            app.xfilt=custom_filt(app);
            soundsc(app.xfilt,app.Fs)
        end

        % Button pushed function: SelectfileButton
        function SelectfileButtonPushed(app, event)
            initialize(app);
        end

        % Value changed function: FminEditField
        function FminEditFieldValueChanged(app, event)
            app.Fmin=app.FminEditField.Value;
            ylim(app.UIAxes,[app.Fmin app.Fmax])
            app.quick_update=1;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 150 1408 568];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [2 53 1354 301];

            % Create Slider
            app.Slider = uislider(app.UIFigure);
            app.Slider.Limits = [0 1];
            app.Slider.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged, true);
            app.Slider.Position = [21 394 1322 3];

            % Create DateDatePickerLabel
            app.DateDatePickerLabel = uilabel(app.UIFigure);
            app.DateDatePickerLabel.HorizontalAlignment = 'right';
            app.DateDatePickerLabel.Position = [189 505 31 22];
            app.DateDatePickerLabel.Text = 'Date';

            % Create HourEditFieldLabel
            app.HourEditFieldLabel = uilabel(app.UIFigure);
            app.HourEditFieldLabel.HorizontalAlignment = 'right';
            app.HourEditFieldLabel.Position = [214 475 35 22];
            app.HourEditFieldLabel.Text = 'Hour';

            % Create MinuteEditFieldLabel
            app.MinuteEditFieldLabel = uilabel(app.UIFigure);
            app.MinuteEditFieldLabel.HorizontalAlignment = 'right';
            app.MinuteEditFieldLabel.Position = [207 443 42 22];
            app.MinuteEditFieldLabel.Text = 'Minute';

            % Create SecondEditFieldLabel
            app.SecondEditFieldLabel = uilabel(app.UIFigure);
            app.SecondEditFieldLabel.HorizontalAlignment = 'right';
            app.SecondEditFieldLabel.Position = [203 412 46 22];
            app.SecondEditFieldLabel.Text = 'Second';

            % Create OverlapEditFieldLabel
            app.OverlapEditFieldLabel = uilabel(app.UIFigure);
            app.OverlapEditFieldLabel.HorizontalAlignment = 'right';
            app.OverlapEditFieldLabel.Position = [514 445 47 22];
            app.OverlapEditFieldLabel.Text = 'Overlap';

            % Create DurationEditFieldLabel
            app.DurationEditFieldLabel = uilabel(app.UIFigure);
            app.DurationEditFieldLabel.HorizontalAlignment = 'right';
            app.DurationEditFieldLabel.Position = [372 433 51 22];
            app.DurationEditFieldLabel.Text = 'Duration';

            % Create SpectrogramLabel
            app.SpectrogramLabel = uilabel(app.UIFigure);
            app.SpectrogramLabel.HorizontalAlignment = 'center';
            app.SpectrogramLabel.FontSize = 15;
            app.SpectrogramLabel.FontWeight = 'bold';
            app.SpectrogramLabel.Position = [575 540 161 24];
            app.SpectrogramLabel.Text = 'Spectrogram';

            % Create FilenameLabel
            app.FilenameLabel = uilabel(app.UIFigure);
            app.FilenameLabel.FontSize = 15;
            app.FilenameLabel.Position = [147 20 601 22];
            app.FilenameLabel.Text = 'Filename:';

            % Create WindowDropDownLabel
            app.WindowDropDownLabel = uilabel(app.UIFigure);
            app.WindowDropDownLabel.HorizontalAlignment = 'right';
            app.WindowDropDownLabel.Position = [512 499 48 22];
            app.WindowDropDownLabel.Text = 'Window';

            % Create PlaybackLabel
            app.PlaybackLabel = uilabel(app.UIFigure);
            app.PlaybackLabel.HorizontalAlignment = 'center';
            app.PlaybackLabel.FontSize = 15;
            app.PlaybackLabel.FontWeight = 'bold';
            app.PlaybackLabel.Position = [1073 540 110 24];
            app.PlaybackLabel.Text = 'Playback';

            % Create FmaxEditFieldLabel
            app.FmaxEditFieldLabel = uilabel(app.UIFigure);
            app.FmaxEditFieldLabel.HorizontalAlignment = 'right';
            app.FmaxEditFieldLabel.Position = [695 483 35 22];
            app.FmaxEditFieldLabel.Text = 'Fmax';

            % Create StarttimeLabel
            app.StarttimeLabel = uilabel(app.UIFigure);
            app.StarttimeLabel.HorizontalAlignment = 'center';
            app.StarttimeLabel.FontSize = 15;
            app.StarttimeLabel.FontWeight = 'bold';
            app.StarttimeLabel.Position = [189 540 157 24];
            app.StarttimeLabel.Text = 'Start time';

            % Create ExportFiguresLabel
            app.ExportFiguresLabel = uilabel(app.UIFigure);
            app.ExportFiguresLabel.HorizontalAlignment = 'center';
            app.ExportFiguresLabel.FontSize = 15;
            app.ExportFiguresLabel.FontWeight = 'bold';
            app.ExportFiguresLabel.Position = [1267 540 120 24];
            app.ExportFiguresLabel.Text = 'Export Figures';

            % Create NfftDropDownLabel
            app.NfftDropDownLabel = uilabel(app.UIFigure);
            app.NfftDropDownLabel.HorizontalAlignment = 'right';
            app.NfftDropDownLabel.Position = [536 472 25 22];
            app.NfftDropDownLabel.Text = 'Nfft';

            % Create dBminEditFieldLabel
            app.dBminEditFieldLabel = uilabel(app.UIFigure);
            app.dBminEditFieldLabel.HorizontalAlignment = 'right';
            app.dBminEditFieldLabel.Position = [690 447 39 22];
            app.dBminEditFieldLabel.Text = 'dBmin';

            % Create dBmaxEditFieldLabel
            app.dBmaxEditFieldLabel = uilabel(app.UIFigure);
            app.dBmaxEditFieldLabel.HorizontalAlignment = 'right';
            app.dBmaxEditFieldLabel.Position = [690 425 39 22];
            app.dBmaxEditFieldLabel.Text = 'dBmax';

            % Create FilterLabel
            app.FilterLabel = uilabel(app.UIFigure);
            app.FilterLabel.HorizontalAlignment = 'center';
            app.FilterLabel.FontSize = 15;
            app.FilterLabel.FontWeight = 'bold';
            app.FilterLabel.Position = [874 540 110 24];
            app.FilterLabel.Text = 'Filter';

            % Create DaysLabel
            app.DaysLabel = uilabel(app.UIFigure);
            app.DaysLabel.Position = [22 413 77 22];
            app.DaysLabel.Text = 'Days:';

            % Create FminEditFieldLabel
            app.FminEditFieldLabel = uilabel(app.UIFigure);
            app.FminEditFieldLabel.HorizontalAlignment = 'right';
            app.FminEditFieldLabel.Position = [698 505 32 22];
            app.FminEditFieldLabel.Text = 'Fmin';

            % Create UpdateButton
            app.UpdateButton = uibutton(app.UIFigure, 'push');
            app.UpdateButton.ButtonPushedFcn = createCallbackFcn(app, @UpdateButtonPushed, true);
            app.UpdateButton.Position = [21 484 128 57];
            app.UpdateButton.Text = 'Update';

            % Create DateDatePicker
            app.DateDatePicker = uidatepicker(app.UIFigure);
            app.DateDatePicker.ValueChangedFcn = createCallbackFcn(app, @DateDatePickerValueChanged, true);
            app.DateDatePicker.Position = [232 505 114 22];

            % Create HourEditField
            app.HourEditField = uieditfield(app.UIFigure, 'numeric');
            app.HourEditField.Limits = [0 24];
            app.HourEditField.ValueChangedFcn = createCallbackFcn(app, @HourEditFieldValueChanged, true);
            app.HourEditField.Position = [266 475 56 22];

            % Create MinuteEditField
            app.MinuteEditField = uieditfield(app.UIFigure, 'numeric');
            app.MinuteEditField.Limits = [0 60];
            app.MinuteEditField.ValueChangedFcn = createCallbackFcn(app, @MinuteEditFieldValueChanged, true);
            app.MinuteEditField.Position = [266 443 56 22];

            % Create SecondEditField
            app.SecondEditField = uieditfield(app.UIFigure, 'numeric');
            app.SecondEditField.Limits = [0 60];
            app.SecondEditField.ValueChangedFcn = createCallbackFcn(app, @SecondEditFieldValueChanged, true);
            app.SecondEditField.Position = [266 413 56 22];

            % Create DurationEditField
            app.DurationEditField = uieditfield(app.UIFigure, 'numeric');
            app.DurationEditField.ValueChangedFcn = createCallbackFcn(app, @DurationEditFieldValueChanged, true);
            app.DurationEditField.Position = [345 412 78 22];
            app.DurationEditField.Value = 30;

            % Create WindowDropDown
            app.WindowDropDown = uidropdown(app.UIFigure);
            app.WindowDropDown.Items = {'32', '64', '128', '256', '512', '1024', '2048', '4096', '8192', '16384', '32768', '65536'};
            app.WindowDropDown.ValueChangedFcn = createCallbackFcn(app, @WindowDropDownValueChanged2, true);
            app.WindowDropDown.Position = [575 499 100 22];
            app.WindowDropDown.Value = '512';

            % Create NfftDropDown
            app.NfftDropDown = uidropdown(app.UIFigure);
            app.NfftDropDown.Items = {'32', '64', '128', '256', '512', '1024', '2048', '4096', '8192', '16384', '32768', '65536'};
            app.NfftDropDown.ValueChangedFcn = createCallbackFcn(app, @NfftDropDownValueChanged, true);
            app.NfftDropDown.Position = [576 472 100 22];
            app.NfftDropDown.Value = '1024';

            % Create OverlapEditField
            app.OverlapEditField = uieditfield(app.UIFigure, 'numeric');
            app.OverlapEditField.ValueChangedFcn = createCallbackFcn(app, @OverlapEditFieldValueChanged, true);
            app.OverlapEditField.Position = [576 445 100 22];
            app.OverlapEditField.Value = 0.75;

            % Create FminEditField
            app.FminEditField = uieditfield(app.UIFigure, 'numeric');
            app.FminEditField.ValueChangedFcn = createCallbackFcn(app, @FminEditFieldValueChanged, true);
            app.FminEditField.Position = [736 505 40 22];

            % Create FmaxEditField
            app.FmaxEditField = uieditfield(app.UIFigure, 'numeric');
            app.FmaxEditField.ValueChangedFcn = createCallbackFcn(app, @FmaxEditFieldValueChanged, true);
            app.FmaxEditField.Position = [736 483 40 22];
            app.FmaxEditField.Value = 250;

            % Create dBminEditField
            app.dBminEditField = uieditfield(app.UIFigure, 'numeric');
            app.dBminEditField.ValueChangedFcn = createCallbackFcn(app, @dBminEditFieldValueChanged, true);
            app.dBminEditField.Position = [736 447 40 23];
            app.dBminEditField.Value = -110;

            % Create dBmaxEditField
            app.dBmaxEditField = uieditfield(app.UIFigure, 'numeric');
            app.dBmaxEditField.ValueChangedFcn = createCallbackFcn(app, @dBmaxEditFieldValueChanged, true);
            app.dBmaxEditField.Position = [736 425 40 23];
            app.dBmaxEditField.Value = -70;

            % Create SpectrogramButton
            app.SpectrogramButton = uibutton(app.UIFigure, 'push');
            app.SpectrogramButton.ButtonPushedFcn = createCallbackFcn(app, @SpectrogramButtonPushed, true);
            app.SpectrogramButton.Position = [1272 483 110 43];
            app.SpectrogramButton.Text = 'Spectrogram';

            % Create TimeSeriesButton
            app.TimeSeriesButton = uibutton(app.UIFigure, 'push');
            app.TimeSeriesButton.ButtonPushedFcn = createCallbackFcn(app, @TimeSeriesButtonPushed, true);
            app.TimeSeriesButton.Position = [1272 433 110 43];
            app.TimeSeriesButton.Text = 'Time Series';

            % Create PlayButton
            app.PlayButton = uibutton(app.UIFigure, 'push');
            app.PlayButton.ButtonPushedFcn = createCallbackFcn(app, @PlayButtonPushed, true);
            app.PlayButton.Position = [1073 483 110 43];
            app.PlayButton.Text = 'Play';

            % Create SelectfileButton
            app.SelectfileButton = uibutton(app.UIFigure, 'push');
            app.SelectfileButton.ButtonPushedFcn = createCallbackFcn(app, @SelectfileButtonPushed, true);
            app.SelectfileButton.Position = [20 16 110 30];
            app.SelectfileButton.Text = 'Select file';

            % Create StopButton
            app.StopButton = uibutton(app.UIFigure, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.Position = [1073 433 110 43];
            app.StopButton.Text = 'Stop';

            % Create Button
            app.Button = uibutton(app.UIFigure, 'push');
            app.Button.ButtonPushedFcn = createCallbackFcn(app, @ButtonPushed, true);
            app.Button.Position = [1195 8 73 54];
            app.Button.Text = '<<';

            % Create Button_2
            app.Button_2 = uibutton(app.UIFigure, 'push');
            app.Button_2.ButtonPushedFcn = createCallbackFcn(app, @Button_2Pushed, true);
            app.Button_2.Position = [1282 8 73 54];
            app.Button_2.Text = '>>';

            % Create Switch
            app.Switch = uiswitch(app.UIFigure, 'slider');
            app.Switch.Position = [906 506 45 20];

            % Create FlowEditFieldLabel
            app.FlowEditFieldLabel = uilabel(app.UIFigure);
            app.FlowEditFieldLabel.HorizontalAlignment = 'right';
            app.FlowEditFieldLabel.Position = [864 466 31 22];
            app.FlowEditFieldLabel.Text = 'Flow';

            % Create FlowEditField
            app.FlowEditField = uieditfield(app.UIFigure, 'numeric');
            app.FlowEditField.Position = [904 466 49 22];
            app.FlowEditField.Value = 50;

            % Create FhighEditFieldLabel
            app.FhighEditFieldLabel = uilabel(app.UIFigure);
            app.FhighEditFieldLabel.HorizontalAlignment = 'right';
            app.FhighEditFieldLabel.Position = [860 433 35 22];
            app.FhighEditFieldLabel.Text = 'Fhigh';

            % Create FhighEditField
            app.FhighEditField = uieditfield(app.UIFigure, 'numeric');
            app.FhighEditField.Position = [904 433 49 22];
            app.FhighEditField.Value = 200;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Audiorama_v01

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