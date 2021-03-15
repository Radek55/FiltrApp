classdef ProjektFiltrm < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        GridLayout                matlab.ui.container.GridLayout
        LeftPanel                 matlab.ui.container.Panel
        PlayButton                matlab.ui.control.Button
        SamplerateHzSpinnerLabel  matlab.ui.control.Label
        SamplerateHzSpinner       matlab.ui.control.Spinner
        AmplitudeSpinnerLabel     matlab.ui.control.Label
        AmplitudeSpinner          matlab.ui.control.Spinner
        FrequencyHzSpinnerLabel   matlab.ui.control.Label
        FrequencyHzSpinner        matlab.ui.control.Spinner
        LowpassfilterCheckBox     matlab.ui.control.CheckBox
        TimeSpinnerLabel          matlab.ui.control.Label
        TimeSpinner               matlab.ui.control.Spinner
        TypeDropDownLabel         matlab.ui.control.Label
        TypeDropDown              matlab.ui.control.DropDown
        RightPanel                matlab.ui.container.Panel
        Signal                    matlab.ui.control.UIAxes
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    
    properties (Access = private)                               %wlasnosci
        y; 
        t; 
        A;
        f; 
        fpr; 
    end
    
    methods (Access = private)
        
        function results = signalGenerator(app)                 %#ok<STOUT> 
            app.fpr = app.SamplerateHzSpinner.Value;            %czestotliwosc probkowania
            dt = 1/app.fpr;                                     %okres probkowania
            to = app.TimeSpinner.Value;                         %czas obserwacji sygnalu
            N = to/dt;                                          %ilosc probek
            app.t = (0:N-1) * dt;                               %czas
            app.A = app.AmplitudeSpinner.Value;                 %amplituda
            app.f = app.FrequencyHzSpinner.Value;               %czestotliwosc
            switch app.TypeDropDown.Value                       %generowanie sygnalu
                case 'sin'                                      %i wybor typu sygnalu
                    app.y = app.A * sin(2*pi*app.f*app.t); 
                case 'cos'
                    app.y = app.A * cos(2*pi*app.f*app.t);
                case 'square'
                    app.y = app.A * square(2*pi*app.f*app.t);
                case 'sawtooth'
                    app.y = app.A * sawtooth(2*pi*app.f*app.t,0.5);   
            end
                                     
            if (app.LowpassfilterCheckBox.Value == true)        %filtrowanie sygnalu
                persistent Hd;                                  %#ok<TLEV> 
                if isempty(Hd)
                    Fpass = 869;    
                    Fstop = 1759;   
                    Apass = 1;      
                    Astop = 60;     
                    Fs    = 44100;
                    h = fdesign.lowpass('fp,fst,ap,ast', Fpass, Fstop, Apass, Astop, Fs);
                    Hd = design(h, 'equiripple', ...
                        'MinOrder', 'any', ...
                        'StopbandShape', 'flat');
                    set(Hd,'PersistentMemory',true);
                end
                filtration = filter(Hd,app.y);           %filtrowanie
                plot(app.Signal,app.t,filtration);       %rysowanie wykresu (filtrowanego sygnalu)
                sound(filtration,app.fpr,16)             %odtwarzanie dzwieku (filtrowanego sygnalu)
            else 
                plot(app.Signal,app.t,app.y);            %rysowanie wykresu
                sound(app.y,app.fpr,16)                  %odtwarzanie dzwieku
            end
        end
        
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.LowpassfilterCheckBox.Value = false;  %domyslnie filtrowanie jest wylaczone
            app.PlayButton.Enable = 'off';            %domyslnie przycisk Play jest niedostepny
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {282, 282};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {220, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end

        % Button pushed function: PlayButton
        function PlayButtonPushed(app, event)
            app.signalGenerator; %uruchomienie programu
        end

        % Value changed function: TimeSpinner
        function TimeSpinnerValueChanged(app, event)
            value1 = app.TimeSpinner.Value;
            value2 = app.AmplitudeSpinner.Value;
            value3 = app.FrequencyHzSpinner.Value;
            value4 = app.SamplerateHzSpinner.Value;
            if value1 > 0 && value2 > 0 && value3 > 0 && value4 >= 2*value3 
                app.PlayButton.Enable = 'on';           %przycisk Play mozna nacisnac dopiero
            else                                        %gdy podane zostana wszystkie wartosci 
                app.PlayButton.Enable = 'off';          %(trzeba takze kliknac poza pole do wpisania wartosci
            end                                         %gdy skonczy sie wpisywac, aby program zaliczyl ze jest wpisane)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 722 282];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {220, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create PlayButton
            app.PlayButton = uibutton(app.LeftPanel, 'push');
            app.PlayButton.ButtonPushedFcn = createCallbackFcn(app, @PlayButtonPushed, true);
            app.PlayButton.Position = [117 234 100 22];
            app.PlayButton.Text = 'Play';

            % Create SamplerateHzSpinnerLabel
            app.SamplerateHzSpinnerLabel = uilabel(app.LeftPanel);
            app.SamplerateHzSpinnerLabel.HorizontalAlignment = 'right';
            app.SamplerateHzSpinnerLabel.Position = [7 163 95 22];
            app.SamplerateHzSpinnerLabel.Text = 'Sample rate [Hz]';

            % Create SamplerateHzSpinner
            app.SamplerateHzSpinner = uispinner(app.LeftPanel);
            app.SamplerateHzSpinner.Position = [117 163 100 22];

            % Create AmplitudeSpinnerLabel
            app.AmplitudeSpinnerLabel = uilabel(app.LeftPanel);
            app.AmplitudeSpinnerLabel.HorizontalAlignment = 'right';
            app.AmplitudeSpinnerLabel.Position = [43 130 59 22];
            app.AmplitudeSpinnerLabel.Text = 'Amplitude';

            % Create AmplitudeSpinner
            app.AmplitudeSpinner = uispinner(app.LeftPanel);
            app.AmplitudeSpinner.Position = [117 130 100 22];

            % Create FrequencyHzSpinnerLabel
            app.FrequencyHzSpinnerLabel = uilabel(app.LeftPanel);
            app.FrequencyHzSpinnerLabel.HorizontalAlignment = 'right';
            app.FrequencyHzSpinnerLabel.Position = [15 196 87 22];
            app.FrequencyHzSpinnerLabel.Text = 'Frequency [Hz]';

            % Create FrequencyHzSpinner
            app.FrequencyHzSpinner = uispinner(app.LeftPanel);
            app.FrequencyHzSpinner.Position = [117 196 100 22];

            % Create LowpassfilterCheckBox
            app.LowpassfilterCheckBox = uicheckbox(app.LeftPanel);
            app.LowpassfilterCheckBox.Text = 'Lowpass filter';
            app.LowpassfilterCheckBox.Position = [117 22 95 22];

            % Create TimeSpinnerLabel
            app.TimeSpinnerLabel = uilabel(app.LeftPanel);
            app.TimeSpinnerLabel.HorizontalAlignment = 'right';
            app.TimeSpinnerLabel.Position = [70 96 32 22];
            app.TimeSpinnerLabel.Text = 'Time';

            % Create TimeSpinner
            app.TimeSpinner = uispinner(app.LeftPanel);
            app.TimeSpinner.ValueChangedFcn = createCallbackFcn(app, @TimeSpinnerValueChanged, true);
            app.TimeSpinner.Position = [117 96 100 22];

            % Create TypeDropDownLabel
            app.TypeDropDownLabel = uilabel(app.LeftPanel);
            app.TypeDropDownLabel.HorizontalAlignment = 'right';
            app.TypeDropDownLabel.Position = [65 59 32 22];
            app.TypeDropDownLabel.Text = 'Type';

            % Create TypeDropDown
            app.TypeDropDown = uidropdown(app.LeftPanel);
            app.TypeDropDown.Items = {'sin', 'cos', 'square', 'sawtooth'};
            app.TypeDropDown.Position = [112 59 100 22];
            app.TypeDropDown.Value = 'sin';

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create Signal
            app.Signal = uiaxes(app.RightPanel);
            title(app.Signal, 'Signal')
            xlabel(app.Signal, 't')
            ylabel(app.Signal, 's(t)')
            zlabel(app.Signal, 'Z')
            app.Signal.Position = [28 22 446 238];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ProjektFiltrm

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