%{
----------------------------------------------------------------------------

This file is part of the Bpod Project
Copyright (C) 2014 Joshua I. Sanders, Cold Spring Harbor Laboratory, NY, USA

----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}

function varargout = BpodParameterGUI(varargin)

% EnhancedParameterGUI('init', ParamStruct) - initializes a GUI with edit boxes for every field in subfield ParamStruct.GUI
% EnhancedParameterGUI('sync', ParamStruct) - updates the GUI with fields of
%       ParamStruct.GUI, if they have not been changed by the user. 
%       Returns a param struct. Fields in the GUI sub-struct are read from the UI.

% This version of ParameterGUI includes improvements 
% from EnhancedParameterGUI, contributed by F. Carnevale
% Modified by Paul Anderson 03/2024
% Mainly adjusting text sizes and positions for the panels/boxes

global BpodSystem
Op = lower(varargin{1});
Params = varargin{2};
switch Op
    case 'init' % Make the initial figure
        ParamNames = fieldnames(Params.GUI);
        nParams = length(ParamNames);
        BpodSystem.GUIData.ParameterGUI.ParamNames = cell(1,nParams);
        BpodSystem.GUIData.ParameterGUI.nParams = nParams; 
        BpodSystem.GUIData.ParameterGUI.LastParamValues = cell(1,nParams);

        % Extract info
        if isfield(Params, 'GUIMeta')
            Meta = Params.GUIMeta;
        else
            Meta = struct;
        end
        if isfield(Params, 'GUIPanels')
            Panels = Params.GUIPanels;
            PanelNames = fieldnames(Panels);
        else
            Panels = struct;
            Panels.Parameters = ParamNames;
            PanelNames = {'Parameters'};
        end
        if isfield(Params, 'GUITabs')
            Tabs = Params.GUITabs;            
        else
            Tabs = struct;
            Tabs.Parameters = PanelNames;
        end
        TabNames = fieldnames(Tabs);
        nTabs = length(TabNames);
             
        % Newly added closing functions
        if isfield(Params, 'CloseFunction')
           closeFunction = Params.CloseFunction;
        else
           closeFunction = [];
        end   
            
        Params = Params.GUI;
        PanelNames = PanelNames(end:-1:1);
        GUIHeight = 350;
        MaxVPos = 0;
        MaxHPos = 0;
        ParamNum = 1;

        BpodSystem.ProtocolFigures.ParameterGUI = figure('Position', ...
            [50 50 450 GUIHeight],'name','Parameter GUI',...
            'numbertitle','off', 'MenuBar', 'none', 'Resize', 'on');
        
        if ~isempty(closeFunction)
           BpodSystem.ProtocolFigures.ParameterGUI.CloseRequestFcn = closeFunction;
        end

        BpodSystem.GUIHandles.ParameterGUI.Tabs.TabGroup = ...
            uitabgroup(BpodSystem.ProtocolFigures.ParameterGUI);

        [~, SettingsFile] = fileparts(BpodSystem.Path.Settings);

        SettingsMenu = uimenu(BpodSystem.ProtocolFigures.ParameterGUI,'Label',['Settings: ',SettingsFile,'.']);
        try
            uimenu(BpodSystem.ProtocolFigures.ParameterGUI,'Label',['Protocol: ', BpodSystem.Status.CurrentProtocolName,'.']);
        catch
            uimenu(BpodSystem.ProtocolFigures.ParameterGUI,'Label','Protocol: 2AFC.');
        end

        % [subpath1, ~] = fileparts(BpodSystem.Path.CurrentDataFile); 
        % [subpath2, ~] = fileparts(subpath1); 
        % [subpath3, ~] = fileparts(subpath2);
        % [~,  subject] = fileparts(subpath3);
        % uimenu(BpodSystem.ProtocolFigures.ParameterGUI,'Label',['Subject: ', subject,'.']);
        uimenu(SettingsMenu,'Label','Save','Callback',{@SettingsMenuSave_Callback});
        uimenu(SettingsMenu,'Label','Save as...','Callback',{@SettingsMenuSaveAs_Callback,SettingsMenu});

        % Loop through tabs
        for t = 1:nTabs
            VPos = 10;
            HPos = 10;
            ThisTabPanelNames = Tabs.(TabNames{t});
            nPanels = length(ThisTabPanelNames);
            BpodSystem.GUIHandles.ParameterGUI.Tabs.(TabNames{t}) = uitab('title', TabNames{t});
            htab = BpodSystem.GUIHandles.ParameterGUI.Tabs.(TabNames{t});
            % Loop through Panels
            for p = 1:nPanels
                ThisPanelParamNames = Panels.(ThisTabPanelNames{p});
                ThisPanelParamNames = ThisPanelParamNames(end:-1:1);
                nParams = length(ThisPanelParamNames);
                
                % Setup paramSpacing
                paramSpacing.LabelWidth = 215;                
                paramSpacing.Width      = 100;
                paramSpacing.Height     = 30;                
                paramSpacing.YSpace     = 33;
                paramSpacing.LabelX     = 8;
                paramSpacing.X          = 292;
                paramSpacing.YPos       = 5;
                paramSpacing.PanelHeight = (paramSpacing.YSpace*nParams)+30;

                BpodSystem.GUIHandles.ParameterGUI.Panels.(ThisTabPanelNames{p}) = ...
                    uipanel(htab,'title', ThisTabPanelNames{p},...
                    'FontSize',12, 'FontWeight', 'Bold', ...
                    'BackgroundColor','white',...
                    'Units','Pixels', 'Position',[HPos VPos 430 paramSpacing.PanelHeight]);
                hPanel = BpodSystem.GUIHandles.ParameterGUI.Panels.(ThisTabPanelNames{p});

                for paramI = 1:nParams
                    ThisParamName = ThisPanelParamNames{paramI};
                    ThisParam = Params.(ThisParamName);
                    BpodSystem.GUIData.ParameterGUI.ParamNames{ParamNum} = ThisParamName;
                    
                    if ischar(ThisParam)
                        BpodSystem.GUIData.ParameterGUI.LastParamValues{ParamNum} = NaN;
                    elseif isempty(ThisParam)

                    else
                        BpodSystem.GUIData.ParameterGUI.LastParamValues{ParamNum} = ThisParam;
                    end
   
                    % Create uiobject and label here
                    [BpodSystem.GUIHandles.ParameterGUI.Labels(ParamNum),...
                     BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum),...
                     BpodSystem.GUIData.ParameterGUI.Styles(ParamNum), ...
                     paramSpacing] = createUIElement(ThisParam, ThisParamName,...
                                        paramSpacing, Meta, hPanel, ParamNum);
                   
                    BpodSystem.GUIHandles.ParamNums.(TabNames{t}).(ThisTabPanelNames{p})(paramI) = ParamNum;
                    paramSpacing.YPos = paramSpacing.YPos + paramSpacing.YSpace;
                    ParamNum = ParamNum + 1;
                end
                             
                % Check next panel to see if it will fit, otherwise start new column
                Wrap = 0;

                if p < nPanels
                    NextPanelParams = Panels.(ThisTabPanelNames{p+1});
                    NextPanelSize = (length(NextPanelParams)*paramSpacing.Height) + 5;
                    if VPos + paramSpacing.PanelHeight + paramSpacing.Height + NextPanelSize > GUIHeight
                        Wrap = 1; 
                    end
                end
                VPos = VPos + paramSpacing.PanelHeight + 10;
                if Wrap
                    HPos = HPos + 450;
                    if VPos > MaxVPos
                        MaxVPos = VPos;
                    end
                    VPos = 10;
                else
                    if VPos > MaxVPos
                        MaxVPos = VPos;
                    end
                end
                if HPos > MaxHPos
                    MaxHPos = HPos;
                end
                BpodSystem.ProtocolFigures.ParameterGUI.Position(3) = MaxHPos + 450;
                BpodSystem.ProtocolFigures.ParameterGUI.Position(4) = MaxVPos+paramSpacing.Height;
                % set(BpodSystem.ProtocolFigures.ParameterGUI, 'Position', [50 50 MaxHPos+450 MaxVPos+paramHeight]);
            end            
        end        
    case 'sync'
        ParamNames = BpodSystem.GUIData.ParameterGUI.ParamNames;
        nParams = BpodSystem.GUIData.ParameterGUI.nParams;
        for p = 1:nParams
            ThisParamName = ParamNames{p}; 
            ThisParamStyle = BpodSystem.GUIData.ParameterGUI.Styles(p);
            ThisParamHandle = BpodSystem.GUIHandles.ParameterGUI.Params(p);
            ThisParamLastValue = BpodSystem.GUIData.ParameterGUI.LastParamValues{p};
            switch ThisParamStyle
                case 1 % Edit
                    GUIParam = str2double(get(ThisParamHandle, 'String'));
                    if GUIParam ~= ThisParamLastValue
                        Params.GUI.(ThisParamName) = GUIParam;
                    elseif Params.GUI.(ThisParamName) ~= ThisParamLastValue
                        set(ThisParamHandle, 'String', num2str(GUIParam));
                    end
                case 2 % Text
                    GUIParam = Params.GUI.(ThisParamName);
                    Text = GUIParam;
                    if ~ischar(Text)
                        Text = num2str(Text);
                    end
                    set(ThisParamHandle, 'String', Text);
                case 3 % Checkbox
                    GUIParam = get(ThisParamHandle, 'Value');
                    if GUIParam ~= ThisParamLastValue
                        Params.GUI.(ThisParamName) = GUIParam;
                    elseif Params.GUI.(ThisParamName) ~= ThisParamLastValue
                        set(ThisParamHandle, 'Value', GUIParam);
                    end
                case 4 % Popupmenu
                    GUIParam = get(ThisParamHandle, 'Value');
                    if GUIParam ~= ThisParamLastValue
                        Params.GUI.(ThisParamName) = GUIParam;
                    elseif Params.GUI.(ThisParamName) ~= ThisParamLastValue
                        set(ThisParamHandle, 'Value', GUIParam);
                    end
                case 6 %Pushbutton
                    GUIParam = get(ThisParamHandle, 'Value');
                    if GUIParam ~= ThisParamLastValue
                        Params.GUI.(ThisParamName) = GUIParam;
                    elseif Params.GUI.(ThisParamName) ~= ThisParamLastValue
                        set(ThisParamHandle, 'Value', GUIParam);
                    end
                case 7 %Table
                    GUIParam = ThisParamHandle.Data;
                    columnNames = fieldnames(Params.GUI.(ThisParamName));
                    argData = [];
                    for iColumn = 1:numel(columnNames)
                        argData = [argData, Params.GUI.(ThisParamName).(columnNames{iColumn})];
                    end
                    if any(GUIParam(:) ~= ThisParamLastValue(:)) % Change originated in the GUI propagates to TaskParameters
                        for iColumn = 1:numel(columnNames)
                            Params.GUI.(ThisParamName).(columnNames{iColumn}) = GUIParam(:,iColumn);
                        end
                    elseif any(argData(:) ~= ThisParamLastValue(:)) % Change originated in TaskParameters propagates to the GUI
                        ThisParamHandle.Data = argData;
                    end
            end
            BpodSystem.GUIData.ParameterGUI.LastParamValues{p} = GUIParam;
        end
    case 'get'
        ParamNames = BpodSystem.GUIData.ParameterGUI.ParamNames;
        nParams = BpodSystem.GUIData.ParameterGUI.nParams;
        for p = 1:nParams
            ThisParamName = ParamNames{p};
            ThisParamStyle = BpodSystem.GUIData.ParameterGUI.Styles(p);
            try % In some matlab version this will be a graphics array (vector) 
                % others a cell array...
                ThisParamHandle = BpodSystem.GUIHandles.ParameterGUI.Params(p);
            catch
                ThisParamHandle = BpodSystem.GUIHandles.ParameterGUI.Params{p};
            end
            switch ThisParamStyle
                case 1 % Edit
                    GUIParam = str2double(get(ThisParamHandle, 'String'));
                    Params.GUI.(ThisParamName) = GUIParam;
                case 2 % Text
                    GUIParam = get(ThisParamHandle, 'String');
                    GUIParam = str2double(GUIParam);  
                    Params.GUI.(ThisParamName) = GUIParam;
                case 3 % Checkbox
                    GUIParam = get(ThisParamHandle, 'Value');
                    Params.GUI.(ThisParamName) = GUIParam;
                case 4 % Popupmenu
                    GUIParam = get(ThisParamHandle, 'Value');
                    Params.GUI.(ThisParamName) = GUIParam;
                case 6 % Pushbutton
                    GUIParam = get(ThisParamHandle, 'Value');
                    Params.GUI.(ThisParamName) = GUIParam;
                case 7 % Table
                    GUIParam = ThisParamHandle.Data;
                    columnNames = fieldnames(Params.GUI.(ThisParamName));
                    for iColumn = 1:numel(columnNames)
                         Params.GUI.(ThisParamName).(columnNames{iColumn}) = GUIParam(:,iColumn);
                    end
            end
        end
    otherwise
    error('ParameterGUI must be called with a valid op code: ''init'' or ''sync''');
end
varargout{1} = Params;

end

function SettingsMenuSave_Callback(~, ~, ~)
global BpodSystem
global TaskParameters
ProtocolSettings = BpodParameterGUI('get',TaskParameters);
save(BpodSystem.SettingsPath,'ProtocolSettings')
end

function SettingsMenuSaveAs_Callback(~, ~, SettingsMenuHandle)
    global BpodSystem
    global TaskParameters
    ProtocolSettings = BpodParameterGUI('get',TaskParameters);
    [file,path] = uiputfile('*.mat','Select a Bpod ProtocolSettings file.',BpodSystem.Path.Settings);
    if file>0
        save(fullfile(path,file),'ProtocolSettings')
        BpodSystem.Path.Settings = fullfile(path,file);
        [~,SettingsName] = fileparts(file);
        set(SettingsMenuHandle,'Label',['Settings: ',SettingsName,'.']);
    end
end

function [label, element, style, spacing] = createUIElement(param, paramName, ...
                                                    spacing, Meta, hPanel, paramNum)
% Get elements
global BpodSystem
global TaskParameters

% Parse any meta data
if isfield(Meta, paramName)
    if isstruct(Meta.(paramName))
        if isfield(Meta.(paramName), 'Style')
            paramStyle = Meta.(paramName).Style;
            if isfield(Meta.(paramName), 'String')
                paramString = Meta.(paramName).String;
            else
                paramString = '';
            end
        else
            % error(['Style not specified for parameter ' ThisParamName '.'])
            paramStyle = 'edit';
        end
        % Check for label
        if isfield(Meta.(paramName), 'Label')
            paramLabel = Meta.(paramName).Label;
        else
            paramLabel = paramName;
        end
    else
        error(['GUIMeta entry for ' ThisParamName ' must be a struct.'])
    end
else
    paramStyle = 'edit';
    paramLabel = paramName;
    paramString = '';
end

label = uicontrol(hPanel,...
'Style', 'text', 'String', paramLabel, 'Position', ...
[spacing.LabelX spacing.YPos spacing.LabelWidth spacing.Height], ...
'FontWeight', 'normal','FontSize', 12, 'BackgroundColor','white', ...
'FontName', 'Arial', 'HorizontalAlignment','Left');

switch lower(paramStyle)
    case 'edit'
        style = 1;
        element = ...
            uicontrol(hPanel,'Style', 'edit', 'String', num2str(param), ...
            'Position', [spacing.X spacing.YPos spacing.Width spacing.Height-5], ...
            'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor','white', ...
            'FontName', 'Arial','HorizontalAlignment','Center');
        element.Position(2) = element.Position(2) + 5;
    case 'text'
        style = 2;
        element = ...
            uicontrol(hPanel,'Style', 'text', 'String', num2str(param), ...
            'Position', [spacing.X spacing.YPos spacing.Width spacing.Height], ...
            'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor','white', ...
            'FontName', 'Arial','HorizontalAlignment','Center');
        element.Position(2) = element.Position(2) - 2;
    case 'checkbox'
        style = 3;
        element = ...
            uicontrol(hPanel,'Style', 'checkbox', 'Value', param, ...
            'String', '', 'Position', ...
            [spacing.X+40 spacing.YPos spacing.Width spacing.Height], ...
            'FontWeight', 'normal', 'FontSize', 12, ...
            'BackgroundColor','white', 'FontName', ...
            'Arial','HorizontalAlignment','Center');
        element.Position(2) = element.Position(2) + 5;
    case 'popupmenu'
        style = 4;
        element = ...
            uicontrol(hPanel,'Style', 'popupmenu', 'String', ...
            paramString, 'Value', param, 'Position', ...
            [spacing.X-20 spacing.YPos spacing.Width+20 spacing.Height], ...
            'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor', ...
            'white', 'FontName', 'Arial','HorizontalAlignment','Center');

        element.Position(1) = [spacing.X - floor(element.Position(3)/2) + 25];
    case 'togglebutton' % INCOMPLETE
        style = 5;
        element = ...
            uicontrol(hPanel,'Style', 'togglebutton', 'String', ...
            paramString, 'Value', param, 'Position', ...
            [spacing.X spacing.YPos spacing.Width spacing.Height], ...
            'FontWeight', 'normal', 'FontSize', 12, ...
            'BackgroundColor','white', 'FontName', ...
            'Arial','HorizontalAlignment','Center');
    case 'pushbutton'
        style = 6;
        element = ...
            uicontrol(hPanel,'Style', 'pushbutton', 'String', paramString,...
            'Value', param, 'Position', [spacing.X spacing.YPos spacing.Width spacing.Height], ...
            'FontWeight', 'normal', 'FontSize', 12,...
            'BackgroundColor','white', 'FontName', ...
            'Arial','HorizontalAlignment','Center', ...
            'Callback',Meta.OdorSettings.Callback);
    case 'table'
        style = 7;
        spacing.YPos = spacing.YPos + 5;
        columnNames = fieldnames(param);
        if isfield(Meta.(paramName),'ColumnLabel')
            columnLabel = Meta.(paramName).ColumnLabel;
        else
            columnLabel = columnNames;
        end

        tableData = [];
        for iTableCol = 1:numel(columnNames)
            tableData = [tableData, param.(columnNames{iTableCol})];
        end

        htable = uitable(hPanel,'data',tableData,'ColumnName',columnLabel,...
             'FontSize', 12,'RowName','','ColumnEditable',true(size(tableData)),...
            'ColumnWidth',repmat({65},1,numel(columnNames)));
        
        htable.Position([3 4]) = htable.Extent([3 4]);
        htable.Position([1 2]) = [spacing.X - floor(htable.Position(3)/2) + 30 spacing.YPos];

        % htable.Position([1 2]) = [spacing.X-70 spacing.YPos];
        % htable.Position(3) = htable.Position(3) + 20;

        element = htable;
        spacing.PanelHeight = spacing.PanelHeight + (htable.Position(4)-20);       
        spacing.YPos = spacing.YPos + 15;

        BpodSystem.GUIHandles.ParameterGUI.Panels.(hPanel.Title).Position(4) = spacing.PanelHeight;
        BpodSystem.GUIData.ParameterGUI.LastParamValues{paramNum} = htable.Data;

    otherwise
        error('Invalid parameter style specified. Valid parameters are: ''edit'', ''text'', ''checkbox'', ''popupmenu'', ''togglebutton'', ''pushbutton''');
end

end % End create UI element 