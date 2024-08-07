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

set(0, 'DefaultLegendInterpreter', 'none')

global BpodSystem
Op = lower(varargin{1});
Params = varargin{2};
switch Op
    case 'init' % Make the initial figure
        ParamNames = fieldnames(Params.GUI);
        nParams = length(ParamNames);
        BpodSystem.GUIData.ParameterGUI.ParamNames = cell(1,nParams);
        BpodSystem.GUIData.ParameterGUI.nParams = nParams;
        % BpodSystem.GUIHandles.ParameterGUI.Labels = zeros(1,nParams);
        % BpodSystem.GUIHandles.ParameterGUI.Params = cell(1,nParams);
        BpodSystem.GUIData.ParameterGUI.LastParamValues = cell(1,nParams);
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
        GUIHeight = 400;
        MaxVPos = 0;
        MaxHPos = 0;
        ParamNum = 1;
        BpodSystem.ProtocolFigures.ParameterGUI = figure('Position', [50 50 450 GUIHeight],'name','Parameter GUI','numbertitle','off', 'MenuBar', 'none', 'Resize', 'on');
        if ~isempty(closeFunction)
           BpodSystem.ProtocolFigures.ParameterGUI.CloseRequestFcn = closeFunction;
        end
        BpodSystem.GUIHandles.ParameterGUI.Tabs.TabGroup = uitabgroup(BpodSystem.ProtocolFigures.ParameterGUI);
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
        for t = 1:nTabs
            VPos = 10;
            HPos = 10;
            ThisTabPanelNames = Tabs.(TabNames{t});
            nPanels = length(ThisTabPanelNames);
            BpodSystem.GUIHandles.ParameterGUI.Tabs.(TabNames{t}) = uitab('title', TabNames{t});
            htab = BpodSystem.GUIHandles.ParameterGUI.Tabs.(TabNames{t});
            for p = 1:nPanels
                ThisPanelParamNames = Panels.(ThisTabPanelNames{p});
                ThisPanelParamNames = ThisPanelParamNames(end:-1:1);
                nParams = length(ThisPanelParamNames);
                
                paramLabelWidth = 260;                
                paramWidth      = 100;
                paramHeight     = 30;                
                paramYSpace     = 33;
                paramLabelX     = 8;
                paramX          = 292;
                paramYPos       = 5;

                ThisPanelHeight = (paramYSpace*nParams)+30;
                BpodSystem.GUIHandles.ParameterGUI.Panels.(ThisTabPanelNames{p}) = uipanel(htab,'title', ThisTabPanelNames{p},'FontSize',12, 'FontWeight', 'Bold', 'BackgroundColor','white','Units','Pixels', 'Position',[HPos VPos 430 ThisPanelHeight]);
                hPanel = BpodSystem.GUIHandles.ParameterGUI.Panels.(ThisTabPanelNames{p});

                paramCount = 1;
                for i = 1:nParams
                    ThisParamName = ThisPanelParamNames{i};
                    ThisParam = Params.(ThisParamName);
                    BpodSystem.GUIData.ParameterGUI.ParamNames{ParamNum} = ThisParamName;
                    if ischar(ThisParam)
                        BpodSystem.GUIData.ParameterGUI.LastParamValues{ParamNum} = NaN;
                    elseif isempty(ThisParam)

                    else
                        BpodSystem.GUIData.ParameterGUI.LastParamValues{ParamNum} = ThisParam;
                    end
                    if isfield(Meta, ThisParamName)
                        if isstruct(Meta.(ThisParamName))
                            if isfield(Meta.(ThisParamName), 'Style')
                                ThisParamStyle = Meta.(ThisParamName).Style;
                                if isfield(Meta.(ThisParamName), 'String')
                                    ThisParamString = Meta.(ThisParamName).String;
                                else
                                    ThisParamString = '';
                                end
                            else
                                % error(['Style not specified for parameter ' ThisParamName '.'])
                                ThisParamStyle = 'edit';
                            end
                            % Check for label
                            if isfield(Meta.(ThisParamName), 'Label')
                                ThisParamLabel = Meta.(ThisParamName).Label;
                            else
                                ThisParamLabel = ThisParamName;
                            end
                        else
                            error(['GUIMeta entry for ' ThisParamName ' must be a struct.'])
                        end
                    else
                        ThisParamStyle = 'edit';
                        ThisParamValue = NaN;
                        ThisParamLabel = ThisParamName;
                    end
                    BpodSystem.GUIHandles.ParameterGUI.Labels(ParamNum) = uicontrol(hPanel,...
                        'Style', 'text', 'String', ThisParamLabel, 'Position', ...
                        [paramLabelX paramYPos paramLabelWidth paramHeight], 'FontWeight', 'normal',...
                        'FontSize', 12, 'BackgroundColor','white', 'FontName', 'Arial','HorizontalAlignment','Center');
                    % BpodSystem.GUIHandles.ParameterGUI.Labels(ParamNum).InnerPosition(2) = ...
                    %     BpodSystem.GUIHandles.ParameterGUI.Labels(ParamNum).InnerPosition(2) - 2;
                    switch lower(ThisParamStyle)
                        case 'edit'
                            BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 1;
                            BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = ...
                                uicontrol(hPanel,'Style', 'edit', 'String', num2str(ThisParam), ...
                                'Position', [paramX paramYPos paramWidth paramHeight-5], ...
                                'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor','white', ...
                                'FontName', 'Arial','HorizontalAlignment','Center');
                        case 'text'
                            BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 2;
                            BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = ...
                            uicontrol(hPanel,'Style', 'text', 'String', num2str(ThisParam), ...
                            'Position', [paramX paramYPos paramWidth paramHeight], ...
                            'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor','white', ...
                            'FontName', 'Arial','HorizontalAlignment','Center');
                        case 'checkbox'
                            BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 3;
                            BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = ...
                                uicontrol(hPanel,'Style', 'checkbox', 'Value', ThisParam, ...
                                'String', '', 'Position', ...
                                [paramX paramYPos paramWidth paramHeight], ...
                                'FontWeight', 'normal', 'FontSize', 12, ...
                                'BackgroundColor','white', 'FontName', ...
                                'Arial','HorizontalAlignment','Center');
                        case 'popupmenu'
                            BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 4;
                            BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = ...
                                uicontrol(hPanel,'Style', 'popupmenu', 'String', ...
                                ThisParamString, 'Value', ThisParam, 'Position', ...
                                [paramX paramYPos paramWidth paramHeight], ...
                                'FontWeight', 'normal', 'FontSize', 12, 'BackgroundColor', ...
                                'white', 'FontName', 'Arial','HorizontalAlignment','Center');
                        case 'togglebutton' % INCOMPLETE
                            BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 5;
                            BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = ...
                                uicontrol(hPanel,'Style', 'togglebutton', 'String', ...
                                ThisParamString, 'Value', ThisParam, 'Position', ...
                                [paramX paramYPos paramWidth paramHeight], ...
                                'FontWeight', 'normal', 'FontSize', 12, ...
                                'BackgroundColor','white', 'FontName', ...
                                'Arial','HorizontalAlignment','Center');
                        case 'pushbutton'
                            BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 6;
                            BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = ...
                                uicontrol(hPanel,'Style', 'pushbutton', 'String', ThisParamString,...
                                'Value', ThisParam, 'Position', [paramX paramYPos paramWidth paramHeight], ...
                                'FontWeight', 'normal', 'FontSize', 12,...
                                'BackgroundColor','white', 'FontName', ...
                                'Arial','HorizontalAlignment','Center', ...
                                'Callback',Meta.OdorSettings.Callback);
                        case 'table'
                            BpodSystem.GUIData.ParameterGUI.Styles(ParamNum) = 7;
                            columnNames = fieldnames(Params.(ThisParamName));
                            if isfield(Meta.(ThisParamName),'ColumnLabel')
                                columnLabel = Meta.(ThisParamName).ColumnLabel;
                            else
                                columnLabel = columnNames;
                            end
                            tableData = [];
                            for iTableCol = 1:numel(columnNames)
                                tableData = [tableData, Params.(ThisParamName).(columnNames{iTableCol})];
                            end
%                             tableData(:,2) = tableData(:,2)/sum(tableData(:,2));
                            htable = uitable(hPanel,'data',tableData,'columnname',columnLabel,...
                                'ColumnEditable',[true true], 'FontSize', 12);
                            htable.Position([3 4]) = htable.Extent([3 4]);
                            htable.Position([1 2]) = [paramX paramYPos];
                            BpodSystem.GUIHandles.ParameterGUI.Params(ParamNum) = htable;
                            ThisPanelHeight = ThisPanelHeight + (htable.Position(4)-25);
                            BpodSystem.GUIHandles.ParameterGUI.Panels.(ThisTabPanelNames{p}).Position(4) = ThisPanelHeight;
                            BpodSystem.GUIData.ParameterGUI.LastParamValues{ParamNum} = htable.Data;

                        otherwise
                            error('Invalid parameter style specified. Valid parameters are: ''edit'', ''text'', ''checkbox'', ''popupmenu'', ''togglebutton'', ''pushbutton''');
                    end
                    BpodSystem.GUIHandles.ParamNums.(TabNames{t}).(ThisTabPanelNames{p})(paramCount) = ParamNum;
                    paramYPos = paramYPos + paramYSpace;
                    ParamNum = ParamNum + 1;
                    paramCount = paramCount + 1;
                end
                paramCount = 1;
                % Align Parameters
                % panelParamNums = BpodSystem.GUIHandles.ParamNums.(TabNames{t}).(ThisTabPanelNames{p});
                % panelPosition = BpodSystem.GUIHandles.ParameterGUI.Panels.(ThisTabPanelNames{p}).Position;
                % % 
                % BpodSystem.GUIHandles.ParameterGUI.Labels(panelParamNums(1)).Position(2) = 5;
                % % BpodSystem.GUIHandles.ParameterGUI.Labels(panelParamNums(1)).Units = "normalized";
                % % BpodSystem.GUIHandles.ParameterGUI.Labels(panelParamNums(1)).Position(1) = 0.025;
                % % BpodSystem.GUIHandles.ParameterGUI.Labels(panelParamNums(1)).Units = "pixels"; 
                % % 
                % % BpodSystem.GUIHandles.ParameterGUI.Labels(panelParamNums(end)).Position(2) = ...
                % %     panelPosition(3) - 40;
                % % BpodSystem.GUIHandles.ParameterGUI.Labels(panelParamNums(end)).Units = "normalized";
                % % BpodSystem.GUIHandles.ParameterGUI.Labels(panelParamNums(end)).Position(1) = 0.025;
                % % BpodSystem.GUIHandles.ParameterGUI.Labels(panelParamNums(end)).Units = "pixels"; 
                % % 
                % BpodSystem.GUIHandles.ParameterGUI.Params(panelParamNums(1)).Position(2) = 5;
                % BpodSystem.GUIHandles.ParameterGUI.Params(panelParamNums(1)).Units = "normalized";
                % BpodSystem.GUIHandles.ParameterGUI.Params(panelParamNums(1)).Position(1) = 0.55;
                % BpodSystem.GUIHandles.ParameterGUI.Params(panelParamNums(1)).Units = "pixels"; 
                % 
                % BpodSystem.GUIHandles.ParameterGUI.Params(panelParamNums(end)).Position(2) = ...
                %     panelPosition(3) - 40;
                % BpodSystem.GUIHandles.ParameterGUI.Params(panelParamNums(end)).Units = "normalized";
                % BpodSystem.GUIHandles.ParameterGUI.Params(panelParamNums(end)).Position(1) = 0.55;
                % BpodSystem.GUIHandles.ParameterGUI.Params(panelParamNums(end)).Units = "pixels"; 
                % 
                % align(BpodSystem.GUIHandles.ParameterGUI.Labels(panelParamNums),"Left","Distribute")
                % align(BpodSystem.GUIHandles.ParameterGUI.Params(panelParamNums),"Left","Distribute")

                % Check next panel to see if it will fit, otherwise start new column
                Wrap = 0;
                if p < nPanels
                    NextPanelParams = Panels.(ThisTabPanelNames{p+1});
                    NextPanelSize = (length(NextPanelParams)*paramHeight) + 5;
                    if VPos + ThisPanelHeight + paramHeight + NextPanelSize > GUIHeight
                        Wrap = 1;
                    end
                end
                VPos = VPos + ThisPanelHeight + 10;
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
                BpodSystem.ProtocolFigures.ParameterGUI.Position(3) = MaxHPos+450;
                BpodSystem.ProtocolFigures.ParameterGUI.Position(4) = MaxVPos+paramHeight;
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
            ThisParamHandle = BpodSystem.GUIHandles.ParameterGUI.Params{p};
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

function SettingsMenuSave_Callback(~, ~, ~)
global BpodSystem
global TaskParameters
ProtocolSettings = BpodParameterGUI('get',TaskParameters);
save(BpodSystem.SettingsPath,'ProtocolSettings')

function SettingsMenuSaveAs_Callback(~, ~, SettingsMenuHandle)
global BpodSystem
global TaskParameters
ProtocolSettings = BpodParameterGUI('get',TaskParameters);
[file,path] = uiputfile('*.mat','Select a Bpod ProtocolSettings file.',BpodSystem.SettingsPath);
if file>0
    save(fullfile(path,file),'ProtocolSettings')
    BpodSystem.SettingsPath = fullfile(path,file);
    [~,SettingsName] = fileparts(file);
    set(SettingsMenuHandle,'Label',['Settings: ',SettingsName,'.']);
end
