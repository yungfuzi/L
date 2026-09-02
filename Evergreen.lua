local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)

local CoreGui: CoreGui = cloneref(game:GetService("CoreGui"))
local GuiService: GuiService = cloneref(game:GetService("GuiService"))
local Players: Players = cloneref(game:GetService("Players"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local SoundService: SoundService = cloneref(game:GetService("SoundService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))
local Teams: Teams = cloneref(game:GetService("Teams"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))

local getgenv = getgenv or function()
    return shared
end
local setclipboard = setclipboard or nil
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function()
    return CoreGui
end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = cloneref(LocalPlayer:GetMouse())

local Labels = {}
local Buttons = {}
local Toggles = {}
local Options = {}
local Tooltips = {}

local Library = {
    LocalPlayer = LocalPlayer,
    IsRobloxFocused = true,

    DevicePlatform = nil,
    IsMobile = false,

    ScreenGui = nil,
    Floats = nil,
    Overlay = nil,

    Window = nil,
    WindowContainer = nil,

    SearchText = "",
    Searching = false,
    GlobalSearch = false,
    LastSearchTab = nil,

    ActiveTab = nil,
    PreviousTab = nil,
    Tabs = {},
    TabButtons = {},

    DependencyBoxes = {},

    KeybindFrame = nil,
    KeybindContainer = nil,
    KeybindToggles = {},

    Notifications = {},
    NotifySide = "Right",
    NotifyTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

    Dialogues = {},
    ActiveDialog = nil,

    ActiveLoading = nil,

    ContextMenus = {},

    Corners = {},
    SpecificCorners = {},

    TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TabTransitionInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TabSwipeOffset = 26,
    TabSwipeFrom = "bottom",
    WindowAnimationInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    DropdownTransitionInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    KeyPickerTransitionInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    GroupboxTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    RotatingChevronTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),

    Animations = {
        ToggleWindow = false,
        TabSwitch = false,
        Groupbox = false,
        Dropdown = false,
        KeyPicker = false
    },

    Toggled = false,
    Unloaded = false,

    Labels = Labels,
    Buttons = Buttons,
    Toggles = Toggles,
    Options = Options,

    ToggleKeybind = Enum.KeyCode.RightControl,
    ShowToggleFrameInKeybinds = true,

    NotifyOnError = false,
    ShowCustomCursor = true,
    ForceCheckbox = false,

    CantDragForced = false,
    DraggableElements = {},

    PopOutSnapDistance = 80,
    PopOutDragThreshold = 8,
    PopOutHoldTime = 0.15,

    Signals = {},
    UnloadSignals = {},

    OriginalMinSize = Vector2.new(480, 360),
    MinSize = Vector2.new(480, 360),
    DPIScale = 1,
    CornerRadius = 6,

    IsLightTheme = false,
    Scheme = {
        BackgroundColor = Color3.fromRGB(51, 51, 51),
        MainColor = Color3.fromRGB(41, 41, 41),
        AccentColor = Color3.fromRGB(60, 140, 255),
        OutlineColor = Color3.fromRGB(61, 61, 61),
        FontColor = Color3.fromRGB(255, 255, 255),
        Font = Font.fromEnum(Enum.Font.Code),

        RedColor = Color3.fromRGB(255, 50, 50),
        DestructiveColor = Color3.fromRGB(220, 38, 38),
        DarkColor = Color3.new(0, 0, 0),
        WhiteColor = Color3.new(1, 1, 1),

        BackgroundImage = ""
    },

    Registry = {},
    Scales = {},
    ScalesOffset = {},

    OriginalMouseIconEnabled = UserInputService.MouseIconEnabled,
    ShowCursorBinding = string.sub(tostring({}), 10),

    Notify = nil,
    Toggle = nil
}

if RunService:IsStudio() then
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        Library.IsMobile = true
        Library.OriginalMinSize = Vector2.new(480, 240)
    else
        Library.IsMobile = false
        Library.OriginalMinSize = Vector2.new(480, 360)
    end
else
    pcall(function()
        Library.DevicePlatform = UserInputService:GetPlatform()
    end)

    Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
    Library.OriginalMinSize = Library.IsMobile and Vector2.new(480, 240) or Vector2.new(480, 360)
end

local Templates = {
    Frame = {
        BorderSizePixel = 0,
    },
    ImageLabel = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    },
    ImageButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
    },
    ScrollingFrame = {
        BorderSizePixel = 0,
    },
    TextLabel = {
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextBox = {
        BorderSizePixel = 0,
        FontFace = "Font",
        PlaceholderColor3 = function()
            local H, S, V = Library.Scheme.FontColor:ToHSV()
            return Color3.fromHSV(H, S, V / 2)
        end,
        Text = "",
        TextColor3 = "FontColor",
    },
    UIListLayout = {
        SortOrder = Enum.SortOrder.LayoutOrder,
    },
    UIStroke = {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    },

    Window = {
        Title = "Evergreen",
        Footer = "",

        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(700, 470),
        IconSize = UDim2.fromOffset(30, 30),

        AutoShow = true,
        Center = true,
        Resizable = true,
        AlwaysOnTop = false,

        Snapping = false,
        SnapDistance = 28,
        SnapMargin = 8,
        SnapAvoidCoreGui = true,

        SearchbarSize = UDim2.fromScale(1, 1),
        GlobalSearch = false,

        CornerRadius = 6,
        NotifySide = "Right",
        ShowCustomCursor = true,

        Font = Enum.Font.Code,
        ToggleKeybind = Enum.KeyCode.RightControl,

        ShowMobileButtons = true,
        MobileButtonsSide = "Left",

        UnlockMouseWhileOpen = true,

        EnableSidebarResize = false,
        EnableCompacting = false,
        DisableCompactingSnap = false,
        SidebarCompacted = false,
        MinContainerWidth = 256,

        MinSidebarWidth = 128,
        SidebarCompactWidth = 48,
        SidebarCollapseThreshold = 0.5,

        CompactWidthActivation = 128,

        BackgroundImage = "",

        Animations = {
            ToggleWindow = false,
            TabSwitch = false,
            Groupbox = false,
            Dropdown = false,
            KeyPicker = false
        },

        TabTransitionTime = 0.22,
        TabSwipeOffset = 26,
        TabSwipeFrom = "bottom"
    },
    Groupbox = {
        Side = 1,
        Name = "Groupbox",
        IconName = nil,
        Description = nil,
        Visible = true,
        Collapsed = false,
        DisableCollapsing = false,
        PopOut = true,
    },
    Tabbox = {
        Side = 1,
        Name = nil,
        PopOut = true,
    },
    Dialog = {
        Title = "Dialog",
        Description = "Description",
        AutoDismiss = true,
        OutsideClickDismiss = true,
        FooterButtons = {}
    },
    Loading = {
        Title = "Evergreen",
        Icon = nil,
        IconSize = UDim2.fromOffset(30, 30),

        LoadingIcon = nil,
        LoadingIconColor = nil,
        LoadingIconTweenTime = 1,

        CurrentStep = 0,
        TotalSteps = 10,

        ShowSidebar = false,
        AutoResizeHeight = false,
        AlwaysOnTop = true,

        WindowWidth = 450,
        WindowHeight = 275,

        ContentWidth = 450,
        SidebarWidth = 250,
    },
    Toggle = {
        Text = "Toggle",
        Default = false,
        Variant = "Checkbox",

        Callback = function() end,
        Changed = function() end,

        Risky = false,
        Disabled = false,
        Visible = true,
    },
    Input = {
        Text = "Input",
        Default = "",
        Finished = false,
        Numeric = false,
        ClearTextOnFocus = true,
        ClearTextOnBlur = false,
        Placeholder = "",
        AllowEmpty = true,
        EmptyReset = "---",

        Callback = function() end,
        Changed = function() end,
        VerifyValue = nil,

        Disabled = false,
        Visible = true,
    },
    Slider = {
        Text = "Slider",
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,

        Prefix = "",
        Suffix = "",

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,

        AllowRightClickInput = true
    },
    Dropdown = {
        Values = {},
        DisabledValues = {},
        ValueImages = {},

        Multi = false,
        DragSelect = false,
        MaxVisibleDropdownItems = 8,

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Viewport = {
        Object = nil,
        Camera = nil,
        Clone = true,
        AutoFocus = true,
        Interactive = false,
        Height = 200,
        Visible = true,
    },
    Image = {
        Image = "",
        Transparency = 0,
        BackgroundTransparency = 0,
        Color = Color3.new(1, 1, 1),
        RectOffset = Vector2.zero,
        RectSize = Vector2.zero,
        ScaleType = Enum.ScaleType.Fit,
        Height = 200,
        Visible = true,
    },
    Video = {
        Video = "",
        Looped = false,
        Playing = false,
        Volume = 1,
        Height = 200,
        Visible = true,
    },
    UIPassthrough = {
        Instance = nil,
        Height = 24,
        Visible = true,
    },

    KeyPicker = {
        Text = "KeyPicker",

        Default = "None",
        DefaultModifiers = {},

        Blacklisted = {},
        BlacklistedModifiers = {},
        Whitelisted = {},
        WhitelistedModifiers = {},

        Mode = "Toggle",
        Modes = { "Always", "Toggle", "Hold" },
        SyncToggleState = false,

        Callback = function() end,
        ChangedCallback = function() end,
        Changed = function() end,
        Clicked = function() end,
    },
    ColorPicker = {
        Default = Color3.new(1, 1, 1),

        Resizable = true,

        Callback = function() end,
        Changed = function() end,
    },
}

local Places = {
    Bottom = { 0, 1 },
    Right = { 1, 0 },
}
local Sizes = {
    Left = { 0.5, 1 },
    Right = { 0.5, 1 },
}
local SideIndex = {
    left = 1,
    right = 2,
}

local SchemeReplaceAlias = {
    RedColor = "Red",
    WhiteColor = "White",
    DarkColor = "Dark"
}

local SchemeAlias = {
    Red = "RedColor",
    White = "WhiteColor",
    Dark = "DarkColor"
}

local function GetSchemeValue(Index)
    if not Index then
        return nil
    end

    local ReplaceAliasIndex = SchemeReplaceAlias[Index]
    if ReplaceAliasIndex and Library.Scheme[ReplaceAliasIndex] ~= nil then
        Library.Scheme[Index] = Library.Scheme[ReplaceAliasIndex]
        Library.Scheme[ReplaceAliasIndex] = nil
        return Library.Scheme[Index]
    end

    local AliasIndex = SchemeAlias[Index]
    if AliasIndex and Library.Scheme[AliasIndex] ~= nil then
        return Library.Scheme[AliasIndex]
    end

    return Library.Scheme[Index]
end

local function IsMouseInput(Input: InputObject, IncludeM2: boolean?)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or (IncludeM2 == true and Input.UserInputType == Enum.UserInputType.MouseButton2)
        or Input.UserInputType == Enum.UserInputType.Touch
end

local function IsClickInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and Input.UserInputState == Enum.UserInputState.Begin
        and Library.IsRobloxFocused
end

local function IsHoverInput(Input: InputObject)
    return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
        and Input.UserInputState == Enum.UserInputState.Change
end

local function GetTableSize(Table: { [any]: any })
    local Size = 0
    for _, _ in Table do
        Size += 1
    end
    return Size
end

local function StopTween(Tween: TweenBase, Destroy: boolean?)
    if not Tween then
        return
    end

    if Tween.PlaybackState == Enum.PlaybackState.Playing then
        Tween:Cancel()
    end

    if Destroy == true then
        pcall(Tween.Destroy, Tween)
    end
end

local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end

local function Round(Value, Rounding)
    assert(Rounding >= 0, "Invalid rounding number.")

    if Rounding == 0 then
        return math.floor(Value)
    end

    return tonumber(string.format("%." .. Rounding .. "f", Value))
end

--@
function Library:AddToRegistry(Instance, Properties)
    Library.Registry[Instance] = Properties
end

--@
function Library:RemoveFromRegistry(Instance)
    Library.Registry[Instance] = nil
end

--@
function Library:UpdateColorsUsingRegistry()
    for Instance, Properties in Library.Registry do
        for Property, Index in Properties do
            local SchemeValue = GetSchemeValue(Index)

            if SchemeValue or typeof(Index) == "function" then
                Instance[Property] = SchemeValue or Index()
            end
        end
    end
end

--@
function Library:SetDPIScale(DPIScale: number)
    Library.DPIScale = DPIScale / 100
    Library.MinSize = Library.OriginalMinSize * Library.DPIScale

    for _, UIScale in Library.Scales do
        UIScale.Scale = Library.DPIScale - (tonumber(Library.ScalesOffset[UIScale]) or 0)
    end
end

--@
function Library:GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
    local ConnectionType = typeof(Connection)
    if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
        table.insert(Library.Signals, Connection)
    end

    return Connection
end

--@
function Library:Validate(Table: { [string]: any }, Template: { [string]: any }): { [string]: any }
    if typeof(Table) ~= "table" then
        return Template
    end

    for k, v in Template do
        if typeof(k) == "number" then
            continue
        end

        if typeof(v) == "table" then
            Table[k] = Library:Validate(Table[k], v)
        elseif Table[k] == nil then
            Table[k] = v
        end
    end

    return Table
end

--@
function Library:SafeCallback(Func: (...any) -> ...any, ...: any)
    if not (Func and typeof(Func) == "function") then
        return
    end

    local Result = table.pack(xpcall(Func, function(Error)
        task.defer(error, debug.traceback(Error, 2))
        if Library.NotifyOnError and Library.Notify then
            Library:Notify(Error)
        end

        return Error
    end, ...))

    if not Result[1] then
        return nil
    end

    return table.unpack(Result, 2, Result.n)
end

--@
function Library:GetBetterColor(Color: Color3, Add: number): Color3
    Add = Add * (Library.IsLightTheme and -4 or 2)
    return Color3.fromRGB(
        math.clamp(Color.R * 255 + Add, 0, 255),
        math.clamp(Color.G * 255 + Add, 0, 255),
        math.clamp(Color.B * 255 + Add, 0, 255)
    )
end

--@
function Library:GetLighterColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, math.max(0, S - 0.1), math.min(1, V + 0.1))
end

--@
function Library:GetDarkerColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, S, V / 2)
end

--@
function Library:GetTextBounds(Text: string, Font: Font, Size: number, Width: number?): (number, number)
    local Params = Instance.new("GetTextBoundsParams")
    Params.Text = Text
    Params.RichText = true
    Params.Font = Font
    Params.Size = Size
    Params.Width = Width or workspace.CurrentCamera.ViewportSize.X - 32

    local Bounds = TextService:GetTextBoundsAsync(Params)
    return Bounds.X, Bounds.Y
end

--@
function Library:MouseIsOverFrame(Frame: GuiObject, Mouse: Vector2): boolean
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X >= AbsPos.X
        and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y
        and Mouse.Y <= AbsPos.Y + AbsSize.Y
end

local function FillInstance(Table: { [string]: any }, Instance: GuiObject)
    local ThemeProperties = Library.Registry[Instance] or {}

    for key, value in Table do
        if key ~= "Text" then
            local SchemeValue = GetSchemeValue(value)

            if SchemeValue or typeof(value) == "function" then
                ThemeProperties[key] = value
                value = SchemeValue or value()
            else
                ThemeProperties[key] = nil
            end
        end

        Instance[key] = value
    end

    if GetTableSize(ThemeProperties) > 0 then
        Library.Registry[Instance] = ThemeProperties
    end
end

local function New(ClassName: string, Properties: { [string]: any }): any
    local Instance = Instance.new(ClassName)

    if Templates[ClassName] then
        FillInstance(Templates[ClassName], Instance)
    end
    FillInstance(Properties, Instance)

    if Properties["Parent"] and not Properties["ZIndex"] then
        pcall(function()
            Instance.ZIndex = Properties.Parent.ZIndex
        end)
    end

    return Instance
end

local function SafeParentUI(Instance: Instance, Parent: Instance | () -> Instance)
    local success, _error = pcall(function()
        if not Parent then
            Parent = CoreGui
        end

        local DestinationParent
        if typeof(Parent) == "function" then
            DestinationParent = Parent()
        else
            DestinationParent = Parent
        end

        Instance.Parent = DestinationParent
    end)

    if not (success and Instance.Parent) then
        Instance.Parent = Library.LocalPlayer:WaitForChild("PlayerGui", math.huge)
    end
end

local function ParentUI(UI: Instance, SkipHiddenUI: boolean?)
    if SkipHiddenUI then
        SafeParentUI(UI, CoreGui)
        return
    end

    pcall(protectgui, UI)
    SafeParentUI(UI, gethui)
end

local ScreenGui = New("ScreenGui", {
    Name = "Evergreen",
    DisplayOrder = 998,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui

ScreenGui.DescendantRemoving:Connect(function(Instance)
    task.defer(function()
        if Instance.Parent and Instance:IsDescendantOf(ScreenGui) then
            return
        end

        Library:RemoveFromRegistry(Instance)
    end)
end)

local ModalElement = New("TextButton", {
    BackgroundTransparency = 1,
    Modal = false,
    Size = UDim2.fromScale(0, 0),
    AnchorPoint = Vector2.zero,
    Text = "",
    ZIndex = -999,
    Parent = ScreenGui,
})

local Floats = New("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 10,
    Active = false,
    Parent = ScreenGui,
})

local Overlay = New("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 20,
    Active = false,
    Parent = ScreenGui,
})

Library.Floats = Floats
Library.Overlay = Overlay

--@
function Library:MakeDraggable(
    UI: GuiObject,
    DragFrame: GuiObject,
    IgnoreToggled: boolean?,
    IsMainWindow: boolean?
)
    local StartPos
    local FramePos
    local Dragging = false
    local Changed
    local InputBegan
    local InputChanged

    InputBegan = DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) or (IsMainWindow and Library.CantDragForced) then
            return
        end

        StartPos = Input.Position
        FramePos = UI.Position
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false

            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)

    InputChanged = UserInputService.InputChanged:Connect(function(Input: InputObject)
        if
            (not IgnoreToggled and not Library.Toggled)
            or (IsMainWindow and Library.CantDragForced)
            or not (ScreenGui and ScreenGui.Parent)
        then
            Dragging = false

            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            local NewX = FramePos.X.Offset + Delta.X
            local NewY = FramePos.Y.Offset + Delta.Y

            UI.Position = UDim2.new(FramePos.X.Scale, NewX, FramePos.Y.Scale, NewY)
        end
    end)

    Library:GiveSignal(InputChanged)
    Library:GiveSignal(InputBegan)

    UI.Destroying:Once(function()
        if InputChanged and InputChanged.Connected then
            InputChanged:Disconnect()
        end

        if InputBegan and InputBegan.Connected then
            InputBegan:Disconnect()
        end

        if Changed and Changed.Connected then
            Changed:Disconnect()
        end
    end)
end

--@
function Library:MakeResizable(UI: GuiObject, DragFrame: GuiObject, Callback: (() -> ())?)
    local StartPos
    local FrameSize
    local Dragging = false
    local Changed
    local InputBegan
    local InputChanged

    InputBegan = DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end

        StartPos = Input.Position
        FrameSize = UI.Size
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)

    InputChanged = UserInputService.InputChanged:Connect(function(Input: InputObject)
        if not UI.Visible or not (ScreenGui and ScreenGui.Parent) then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Size = UDim2.new(
                FrameSize.X.Scale,
                math.clamp(FrameSize.X.Offset + Delta.X, Library.MinSize.X, math.huge),
                FrameSize.Y.Scale,
                math.clamp(FrameSize.Y.Offset + Delta.Y, Library.MinSize.Y, math.huge)
            )
            if Callback then
                Library:SafeCallback(Callback)
            end
        end
    end)

    Library:GiveSignal(InputChanged)
    Library:GiveSignal(InputBegan)

    UI.Destroying:Once(function()
        if InputChanged and InputChanged.Connected then
            InputChanged:Disconnect()
        end

        if InputBegan and InputBegan.Connected then
            InputBegan:Disconnect()
        end

        if Changed and Changed.Connected then
            Changed:Disconnect()
        end
    end)
end

--@
function Library:AddOutline(Frame: GuiObject)
    local OutlineStroke = New("UIStroke", {
        Color = "OutlineColor",
        Thickness = 1.5,
        ZIndex = 2,
        Parent = Frame,
    })
    return OutlineStroke
end

local BaseGroupbox = {}
BaseGroupbox.__index = BaseGroupbox

--@
function BaseGroupbox:AddLabel(Text, DoesWrap)
    local Groupbox = self
    if Groupbox.Type ~= "Groupbox" then
        return
    end

    local Label = {
        Type = "Label",
        Text = Text or "",
        Visible = true,
    }

    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 0),
        Parent = Groupbox.Container,
    })

    local TextLabel = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 0),
        Text = Text or "",
        TextSize = 13,
        TextWrapped = DoesWrap == true,
        TextXAlignment = Enum.TextXAlignment.Left,
        FontFace = Library.Scheme.Font,
        TextColor3 = "FontColor",
        Parent = Holder,
    })
    Library:AddToRegistry(TextLabel, {
        TextColor3 = "FontColor",
        FontFace = "Font"
    })

    --@
    function Label:SetText(NewText)
        Label.Text = NewText
        TextLabel.Text = NewText
    end

    --@
    function Label:SetVisible(Visible)
        Label.Visible = Visible
        Holder.Visible = Visible
    end

    table.insert(Groupbox.Elements, Label)
    return Label
end

--@
function BaseGroupbox:AddButton(Text, Callback)
    local Groupbox = self
    if Groupbox.Type ~= "Groupbox" then
        return
    end

    if typeof(Text) == "table" then
        Callback = Text.Callback or Text.Func
        Text = Text.Text or "Button"
    end

    local Button = {
        Type = "Button",
        Text = Text or "Button",
        Visible = true,
        Callback = Callback or function() end,
    }

    local Holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
        Parent = Groupbox.Container,
    })

    local ButtonFrame = New("TextButton", {
        BackgroundColor3 = "BackgroundColor",
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        Parent = Holder,
    })
    Library:AddToRegistry(ButtonFrame, {
        BackgroundColor3 = "BackgroundColor"
    })

    table.insert(Library.Corners, New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 2),
        Parent = ButtonFrame,
    }))

    Library:AddOutline(ButtonFrame)

    local ButtonLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = Text or "Button",
        TextSize = 13,
        FontFace = Library.Scheme.Font,
        TextColor3 = "FontColor",
        Parent = ButtonFrame,
    })
    Library:AddToRegistry(ButtonLabel, {
        TextColor3 = "FontColor",
        FontFace = "Font"
    })

    ButtonFrame.MouseEnter:Connect(function()
        TweenService:Create(ButtonFrame, Library.TweenInfo, {
            BackgroundColor3 = Library:GetBetterColor(Library.Scheme.BackgroundColor, 8)
        }):Play()
    end)

    ButtonFrame.MouseLeave:Connect(function()
        TweenService:Create(ButtonFrame, Library.TweenInfo, {
            BackgroundColor3 = Library.Scheme.BackgroundColor
        }):Play()
    end)

    ButtonFrame.MouseButton1Click:Connect(function()
        Library:SafeCallback(Button.Callback)
    end)

    --@
    function Button:SetText(NewText)
        Button.Text = NewText
        ButtonLabel.Text = NewText
    end

    --@
    function Button:SetVisible(Visible)
        Button.Visible = Visible
        Holder.Visible = Visible
    end

    --@
    function Button:SetCallback(NewCallback)
        Button.Callback = NewCallback or function() end
    end

    table.insert(Groupbox.Elements, Button)
    table.insert(Buttons, Button)
    return Button
end

--@
function BaseGroupbox:AddToggle(Idx, Info)
    local Groupbox = self
    if Groupbox.Type ~= "Groupbox" then
        return
    end

    if typeof(Idx) == "table" then
        Info = Idx
        Idx = Info.Flag or Info.Text
    end

    Info = Library:Validate(Info or {}, Templates.Toggle)
    Info.Text = Info.Text or tostring(Idx)

    local Variant = string.lower(Info.Variant or "Checkbox")
    if Variant ~= "checkbox" and Variant ~= "checkdot" and Variant ~= "switch" then
        Variant = "checkbox"
    end

    local Toggle = {
        Type = "Toggle",
        Text = Info.Text,
        Value = Info.Default,
        Variant = Variant,
        Visible = Info.Visible ~= false,
        Disabled = Info.Disabled == true,
        Risky = Info.Risky == true,
        Callback = Info.Callback,
        Changed = Info.Changed,
        Flag = typeof(Idx) == "string" and Idx or nil,
        Addon = nil,
    }

    local Holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
        Visible = Toggle.Visible,
        Parent = Groupbox.Container,
    })

    local ToggleLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -42, 1, 0),
        Text = Info.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        FontFace = Library.Scheme.Font,
        TextColor3 = Toggle.Risky and "RedColor" or "FontColor",
        Parent = Holder,
    })
    Library:AddToRegistry(ToggleLabel, {
        TextColor3 = Toggle.Risky and "RedColor" or "FontColor",
        FontFace = "Font"
    })

    local Control = nil
    local Indicator = nil
    local Knob = nil

    if Variant == "switch" then
        Control = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Toggle.Value and "AccentColor" or "BackgroundColor",
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(36, 18),
            Parent = Holder,
        })
        Library:AddToRegistry(Control, {
            BackgroundColor3 = function()
                return Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.BackgroundColor
            end
        })

        table.insert(Library.Corners, New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Control,
        }))
        Library:AddOutline(Control)

        Knob = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = "FontColor",
            Position = UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            Parent = Control,
        })
        Library:AddToRegistry(Knob, {
            BackgroundColor3 = "FontColor"
        })

        table.insert(Library.Corners, New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Knob,
        }))
    else
        Control = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Toggle.Value and "AccentColor" or Color3.fromRGB(30, 30, 30),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(18, 18),
            Parent = Holder,
        })
        Library:AddToRegistry(Control, {
            BackgroundColor3 = function()
                return Toggle.Value and Library.Scheme.AccentColor or Color3.fromRGB(30, 30, 30)
            end
        })

        table.insert(Library.Corners, New("UICorner", {
            CornerRadius = Variant == "checkdot" and UDim.new(1, 0) or UDim.new(0, 3),
            Parent = Control,
        }))

        local BoxStroke = New("UIStroke", {
            Color = "OutlineColor",
            Thickness = 1.5,
            Parent = Control,
        })
        Library:AddToRegistry(BoxStroke, {
            Color = "OutlineColor"
        })

        if Variant == "checkdot" then
            Indicator = nil
        else
            Indicator = nil
        end
    end

    local function UpdateVisual()
        if Variant == "switch" then
            local TargetColor = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.BackgroundColor
            TweenService:Create(Control, Library.TweenInfo, {
                BackgroundColor3 = TargetColor
            }):Play()
            TweenService:Create(Knob, Library.TweenInfo, {
                Position = Toggle.Value and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
            }):Play()
        else
            local TargetColor = Toggle.Value and Library.Scheme.AccentColor or Color3.fromRGB(30, 30, 30)

            TweenService:Create(Control, Library.TweenInfo, {
                BackgroundColor3 = TargetColor
            }):Play()
        end
    end

    --@
    function Toggle:SetValue(Value, Silent)
        if Toggle.Disabled then
            return
        end

        Toggle.Value = Value and true or false
        UpdateVisual()

        if Toggle.Flag then
            Library.Options[Toggle.Flag] = Toggle
            Options[Toggle.Flag] = Toggle
        end

        if not Silent then
            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
        end
    end

    --@
    function Toggle:GetValue()
        return Toggle.Value
    end

    --@
    function Toggle:SetText(NewText)
        Toggle.Text = NewText
        ToggleLabel.Text = NewText
    end

    --@
    function Toggle:SetVisible(Visible)
        Toggle.Visible = Visible
        Holder.Visible = Visible
    end

    --@
    function Toggle:SetDisabled(Disabled)
        Toggle.Disabled = Disabled
        ToggleLabel.TextTransparency = Disabled and 0.5 or 0
        Control.BackgroundTransparency = Disabled and 0.5 or 0
    end

    --@
    function Toggle:AddToggle(AddonInfo)
        if Toggle.Addon then
            return Toggle.Addon
        end

        if typeof(AddonInfo) ~= "table" then
            AddonInfo = {}
        end

        local SubText = AddonInfo.Text or "Sub option"
        local SubDefault = AddonInfo.Default or false
        local SubVariant = string.lower(AddonInfo.Variant or "checkbox")
        local SubCallback = AddonInfo.Callback or function() end
        local SubChanged = AddonInfo.Changed or function() end
        local SubFlag = AddonInfo.Flag

        local SubToggle = {
            Type = "Toggle",
            Text = SubText,
            Value = SubDefault,
            Variant = SubVariant,
            Visible = true,
            Disabled = false,
            Callback = SubCallback,
            Changed = SubChanged,
            Flag = SubFlag,
            ParentToggle = Toggle,
        }

        local AddonHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 26),
            Parent = Groupbox.Container,
        })

        local ArrowIcon = New("ImageLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            Image = "rbxassetid://82061714010896",
            ImageColor3 = "FontColor",
            ImageTransparency = 0.3,
            Parent = AddonHolder,
        })
        Library:AddToRegistry(ArrowIcon, {
            ImageColor3 = "FontColor"
        })

        local SubLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(20, 0),
            Size = UDim2.new(1, -46, 1, 0),
            Text = SubText,
            TextSize = 12,
            TextTransparency = 0.15,
            TextXAlignment = Enum.TextXAlignment.Left,
            FontFace = Library.Scheme.Font,
            TextColor3 = "FontColor",
            Parent = AddonHolder,
        })
        Library:AddToRegistry(SubLabel, {
            TextColor3 = "FontColor",
            FontFace = "Font"
        })

        local SubControl = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = SubDefault and "AccentColor" or Color3.fromRGB(30, 30, 30),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(18, 18),
            Parent = AddonHolder,
        })
        Library:AddToRegistry(SubControl, {
            BackgroundColor3 = function()
                return SubToggle.Value and Library.Scheme.AccentColor or Color3.fromRGB(30, 30, 30)
            end
        })

        table.insert(Library.Corners, New("UICorner", {
            CornerRadius = SubVariant == "checkdot" and UDim.new(1, 0) or UDim.new(0, 3),
            Parent = SubControl,
        }))

        local SubStroke = New("UIStroke", {
            Color = "OutlineColor",
            Thickness = 1.5,
            Parent = SubControl,
        })
        Library:AddToRegistry(SubStroke, {
            Color = "OutlineColor"
        })

        local function UpdateSubVisual()
            local TargetColor = SubToggle.Value and Library.Scheme.AccentColor or Color3.fromRGB(30, 30, 30)

            TweenService:Create(SubControl, Library.TweenInfo, {
                BackgroundColor3 = TargetColor
            }):Play()
        end

        --@
        function SubToggle:SetValue(Value, Silent)
            if SubToggle.Disabled then
                return
            end

            SubToggle.Value = Value and true or false
            UpdateSubVisual()

            if SubToggle.Flag then
                Options[SubToggle.Flag] = SubToggle
                Library.Options[SubToggle.Flag] = SubToggle
            end

            if not Silent then
                Library:SafeCallback(SubToggle.Callback, SubToggle.Value)
                Library:SafeCallback(SubToggle.Changed, SubToggle.Value)
            end
        end

        --@
        function SubToggle:GetValue()
            return SubToggle.Value
        end

        --@
        function SubToggle:SetText(NewText)
            SubToggle.Text = NewText
            SubLabel.Text = NewText
        end

        --@
        function SubToggle:SetVisible(Visible)
            SubToggle.Visible = Visible
            AddonHolder.Visible = Visible
        end

        --@
        function SubToggle:SetDisabled(Disabled)
            SubToggle.Disabled = Disabled
            SubLabel.TextTransparency = Disabled and 0.5 or 0.15
            SubControl.BackgroundTransparency = Disabled and 0.5 or 0
        end

        local SubClick = New("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            ZIndex = 2,
            Parent = AddonHolder,
        })

        SubClick.MouseButton1Click:Connect(function()
            if SubToggle.Disabled then
                return
            end
            SubToggle:SetValue(not SubToggle.Value)
        end)

        if SubFlag then
            Options[SubFlag] = SubToggle
            Library.Options[SubFlag] = SubToggle
        end

        Toggle.Addon = SubToggle
        table.insert(Groupbox.Elements, SubToggle)
        table.insert(Toggles, SubToggle)

        SubToggle:SetValue(SubDefault, true)
        return SubToggle
    end

    local ClickDetector = New("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        ZIndex = 2,
        Parent = Holder,
    })

    ClickDetector.MouseButton1Click:Connect(function()
        if Toggle.Disabled then
            return
        end
        Toggle:SetValue(not Toggle.Value)
    end)

    if Toggle.Flag then
        Options[Toggle.Flag] = Toggle
        Library.Options[Toggle.Flag] = Toggle
    end

    table.insert(Groupbox.Elements, Toggle)
    table.insert(Toggles, Toggle)

    Toggle:SetValue(Info.Default, true)
    return Toggle
end

--@
function BaseGroupbox:AddSlider(Idx, Info)
    local Groupbox = self
    if Groupbox.Type ~= "Groupbox" then
        return
    end

    if typeof(Idx) == "table" then
        Info = Idx
        Idx = Info.Flag or Info.Text
    end

    Info = Library:Validate(Info or {}, Templates.Slider)
    Info.Text = Info.Text or tostring(Idx)

    local Slider = {
        Type = "Slider",
        Text = Info.Text,
        Value = Info.Default,
        Min = Info.Min,
        Max = Info.Max,
        Rounding = Info.Rounding,
        Prefix = Info.Prefix or "",
        Suffix = Info.Suffix or "",
        Visible = Info.Visible ~= false,
        Disabled = Info.Disabled == true,
        Callback = Info.Callback,
        Changed = Info.Changed,
        Flag = typeof(Idx) == "string" and Idx or nil,
    }

    local Holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 42),
        Visible = Slider.Visible,
        Parent = Groupbox.Container,
    })

    local SliderLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Text = Info.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        FontFace = Library.Scheme.Font,
        TextColor3 = "FontColor",
        Parent = Holder,
    })
    Library:AddToRegistry(SliderLabel, {
        TextColor3 = "FontColor",
        FontFace = "Font"
    })

    local ValueLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 60, 0, 16),
        Text = "",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        FontFace = Library.Scheme.Font,
        TextColor3 = "FontColor",
        Parent = Holder,
    })
    Library:AddToRegistry(ValueLabel, {
        TextColor3 = "FontColor",
        FontFace = "Font"
    })

    local Track = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.new(0, 0, 0, 22),
        Size = UDim2.new(1, 0, 0, 14),
        Parent = Holder,
    })
    Library:AddToRegistry(Track, {
        BackgroundColor3 = "BackgroundColor"
    })

    table.insert(Library.Corners, New("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = Track,
    }))

    Library:AddOutline(Track)

    local Fill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Size = UDim2.new(0, 0, 1, 0),
        Parent = Track,
    })
    Library:AddToRegistry(Fill, {
        BackgroundColor3 = "AccentColor"
    })

    table.insert(Library.Corners, New("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = Fill,
    }))

    local function UpdateVisual()
        local Percent = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
        Percent = math.clamp(Percent, 0, 1)
        Fill.Size = UDim2.new(Percent, 0, 1, 0)
        ValueLabel.Text = Slider.Prefix .. tostring(Slider.Value) .. Slider.Suffix
    end

    --@
    function Slider:SetValue(Value, Silent)
        if Slider.Disabled then
            return
        end

        Value = math.clamp(Value, Slider.Min, Slider.Max)
        Value = Round(Value, Slider.Rounding)

        Slider.Value = Value
        UpdateVisual()

        if Slider.Flag then
            Options[Slider.Flag] = Slider
            Library.Options[Slider.Flag] = Slider
        end

        if not Silent then
            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
        end
    end

    --@
    function Slider:GetValue()
        return Slider.Value
    end

    --@
    function Slider:SetText(NewText)
        Slider.Text = NewText
        SliderLabel.Text = NewText
    end

    --@
    function Slider:SetVisible(Visible)
        Slider.Visible = Visible
        Holder.Visible = Visible
    end

    --@
    function Slider:SetDisabled(Disabled)
        Slider.Disabled = Disabled
        SliderLabel.TextTransparency = Disabled and 0.5 or 0
        ValueLabel.TextTransparency = Disabled and 0.5 or 0
    end

    local Dragging = false

    Track.InputBegan:Connect(function(Input)
        if Slider.Disabled then
            return
        end
        if not IsClickInput(Input) then
            return
        end

        Dragging = true

        local function UpdateFromInput(InputObj)
            local AbsPos = Track.AbsolutePosition.X
            local AbsSize = Track.AbsoluteSize.X
            local Percent = math.clamp((InputObj.Position.X - AbsPos) / AbsSize, 0, 1)
            local Value = Slider.Min + (Slider.Max - Slider.Min) * Percent
            Slider:SetValue(Value)
        end

        UpdateFromInput(Input)

        local MoveConn
        local EndConn

        MoveConn = UserInputService.InputChanged:Connect(function(MoveInput)
            if Dragging and IsHoverInput(MoveInput) then
                UpdateFromInput(MoveInput)
            end
        end)

        EndConn = UserInputService.InputEnded:Connect(function(EndInput)
            if EndInput.UserInputType == Input.UserInputType then
                Dragging = false
                if MoveConn then
                    MoveConn:Disconnect()
                end
                if EndConn then
                    EndConn:Disconnect()
                end
            end
        end)
    end)

    if Slider.Flag then
        Options[Slider.Flag] = Slider
        Library.Options[Slider.Flag] = Slider
    end

    table.insert(Groupbox.Elements, Slider)
    table.insert(Options, Slider)

    Slider:SetValue(Info.Default, true)
    return Slider
end

--@
function BaseGroupbox:AddDropdown(Idx, Info)
    local Groupbox = self
    if Groupbox.Type ~= "Groupbox" then
        return
    end

    if typeof(Idx) == "table" then
        Info = Idx
        Idx = Info.Flag or Info.Text
    end

    Info = Library:Validate(Info or {}, Templates.Dropdown)
    Info.Text = Info.Text or tostring(Idx)

    local Values = Info.Values or {}
    local Multi = Info.Multi == true
    local MaxVisible = Info.MaxVisibleDropdownItems or 8

    local Dropdown = {
        Type = "Dropdown",
        Text = Info.Text,
        Values = Values,
        Value = Info.Default,
        Multi = Multi,
        Visible = Info.Visible ~= false,
        Disabled = Info.Disabled == true,
        Callback = Info.Callback,
        Changed = Info.Changed,
        Flag = typeof(Idx) == "string" and Idx or nil,
        IsOpen = false,
    }

    if Multi then
        if typeof(Dropdown.Value) ~= "table" then
            Dropdown.Value = {}
        end
    end

    local Holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 48),
        Visible = Dropdown.Visible,
        Parent = Groupbox.Container,
    })

    local DropLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Text = Info.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        FontFace = Library.Scheme.Font,
        TextColor3 = "FontColor",
        Parent = Holder,
    })
    Library:AddToRegistry(DropLabel, {
        TextColor3 = "FontColor",
        FontFace = "Font"
    })

    local Box = New("TextButton", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.new(0, 0, 0, 20),
        Size = UDim2.new(1, 0, 0, 26),
        Text = "",
        AutoButtonColor = false,
        Parent = Holder,
    })
    Library:AddToRegistry(Box, {
        BackgroundColor3 = "BackgroundColor"
    })

    table.insert(Library.Corners, New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 2),
        Parent = Box,
    }))
    Library:AddOutline(Box)

    local ValueText = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -28, 1, 0),
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        FontFace = Library.Scheme.Font,
        TextColor3 = "FontColor",
        Parent = Box,
    })
    Library:AddToRegistry(ValueText, {
        TextColor3 = "FontColor",
        FontFace = "Font"
    })

    local Arrow = New("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        Text = "v",
        TextSize = 12,
        FontFace = Library.Scheme.Font,
        TextColor3 = "FontColor",
        Parent = Box,
    })
    Library:AddToRegistry(Arrow, {
        TextColor3 = "FontColor",
        FontFace = "Font"
    })

    local Menu = New("ScrollingFrame", {
        BackgroundColor3 = "MainColor",
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(200, 0),
        Visible = false,
        ZIndex = 100,
        ClipsDescendants = true,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = Overlay,
    })
    Library:AddToRegistry(Menu, {
        BackgroundColor3 = "MainColor"
    })

    table.insert(Library.Corners, New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 2),
        Parent = Menu,
    }))
    Library:AddOutline(Menu)

    local MenuList = New("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Menu,
    })

    New("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        Parent = Menu,
    })

    local OptionButtons = {}

    local function GetDisplayText()
        if Multi then
            local Selected = {}
            for _, V in ipairs(Values) do
                if Dropdown.Value[V] then
                    table.insert(Selected, tostring(V))
                end
            end
            if #Selected == 0 then
                return "None"
            end
            return table.concat(Selected, ", ")
        else
            return Dropdown.Value ~= nil and tostring(Dropdown.Value) or "None"
        end
    end

    local function RefreshList()
        for _, Btn in OptionButtons do
            Btn:Destroy()
        end
        table.clear(OptionButtons)

        for i, Value in ipairs(Values) do
            local Selected = Multi and Dropdown.Value[Value] == true or Dropdown.Value == Value

            local OptBtn = New("TextButton", {
                BackgroundColor3 = Selected and "AccentColor" or "BackgroundColor",
                BackgroundTransparency = Selected and 0.3 or 1,
                Size = UDim2.new(1, 0, 0, 22),
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = i,
                ZIndex = 51,
                Parent = Menu,
            })
            Library:AddToRegistry(OptBtn, {
                BackgroundColor3 = function()
                    local Sel = Multi and Dropdown.Value[Value] == true or Dropdown.Value == Value
                    return Sel and Library.Scheme.AccentColor or Library.Scheme.BackgroundColor
                end
            })

            table.insert(Library.Corners, New("UICorner", {
                CornerRadius = UDim.new(0, 3),
                Parent = OptBtn,
            }))

            local OptLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = tostring(Value),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                FontFace = Library.Scheme.Font,
                TextColor3 = "FontColor",
                ZIndex = 52,
                Parent = OptBtn,
            })
            Library:AddToRegistry(OptLabel, {
                TextColor3 = "FontColor",
                FontFace = "Font"
            })

            New("UIPadding", {
                PaddingLeft = UDim.new(0, 6),
                Parent = OptLabel,
            })

            OptBtn.MouseEnter:Connect(function()
                if not (Multi and Dropdown.Value[Value] or Dropdown.Value == Value) then
                    TweenService:Create(OptBtn, Library.TweenInfo, {
                        BackgroundTransparency = 0.6
                    }):Play()
                end
            end)

            OptBtn.MouseLeave:Connect(function()
                local Sel = Multi and Dropdown.Value[Value] == true or Dropdown.Value == Value
                TweenService:Create(OptBtn, Library.TweenInfo, {
                    BackgroundTransparency = Sel and 0.3 or 1
                }):Play()
            end)

            OptBtn.MouseButton1Click:Connect(function()
                if Dropdown.Disabled then
                    return
                end

                if Multi then
                    Dropdown.Value[Value] = not Dropdown.Value[Value]
                    if not Dropdown.Value[Value] then
                        Dropdown.Value[Value] = nil
                    end
                else
                    Dropdown.Value = Value
                    Dropdown:Close()
                end

                ValueText.Text = GetDisplayText()
                RefreshList()

                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)

                if Dropdown.Flag then
                    Options[Dropdown.Flag] = Dropdown
                    Library.Options[Dropdown.Flag] = Dropdown
                end
            end)

            table.insert(OptionButtons, OptBtn)
        end

        local VisibleCount = math.min(#Values, MaxVisible)
        local MenuHeight = math.max(VisibleCount * 24 + 8, 32)
        local BoxWidth = math.max(Box.AbsoluteSize.X, 120)
        Menu.Size = UDim2.fromOffset(BoxWidth, MenuHeight)
    end

    --@
    function Dropdown:Open()
        if Dropdown.Disabled then
            return
        end
        Dropdown.IsOpen = true
        RefreshList()

        local AbsPos = Box.AbsolutePosition
        local AbsSize = Box.AbsoluteSize
        Menu.Position = UDim2.fromOffset(AbsPos.X, AbsPos.Y + AbsSize.Y + 4)
        Menu.Size = UDim2.fromOffset(math.max(AbsSize.X, 120), Menu.Size.Y.Offset)
        Menu.Visible = true
        Menu.ZIndex = 200
        Arrow.Text = "^"
    end

    --@
    function Dropdown:Close()
        Dropdown.IsOpen = false
        Menu.Visible = false
        Arrow.Text = "v"
    end

    --@
    function Dropdown:Toggle()
        if Dropdown.IsOpen then
            Dropdown:Close()
        else
            Dropdown:Open()
        end
    end

    --@
    function Dropdown:SetValue(Value, Silent)
        if Multi then
            if typeof(Value) == "table" then
                Dropdown.Value = Value
            end
        else
            Dropdown.Value = Value
        end

        ValueText.Text = GetDisplayText()
        if Dropdown.IsOpen then
            RefreshList()
        end

        if Dropdown.Flag then
            Options[Dropdown.Flag] = Dropdown
            Library.Options[Dropdown.Flag] = Dropdown
        end

        if not Silent then
            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
        end
    end

    --@
    function Dropdown:GetValue()
        return Dropdown.Value
    end

    --@
    function Dropdown:SetValues(NewValues)
        Values = NewValues or {}
        Dropdown.Values = Values
        if Dropdown.IsOpen then
            RefreshList()
        end
        ValueText.Text = GetDisplayText()
    end

    --@
    function Dropdown:SetText(NewText)
        Dropdown.Text = NewText
        DropLabel.Text = NewText
    end

    --@
    function Dropdown:SetVisible(Visible)
        Dropdown.Visible = Visible
        Holder.Visible = Visible
    end

    --@
    function Dropdown:SetDisabled(Disabled)
        Dropdown.Disabled = Disabled
        DropLabel.TextTransparency = Disabled and 0.5 or 0
        ValueText.TextTransparency = Disabled and 0.5 or 0
    end

    Box.MouseButton1Click:Connect(function()
        if Dropdown.Disabled then
            return
        end
        Dropdown:Toggle()
    end)

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input)
        if not Dropdown.IsOpen then
            return
        end
        if IsClickInput(Input) then
            local Pos = Vector2.new(Input.Position.X, Input.Position.Y)
            if not Library:MouseIsOverFrame(Box, Pos) and not Library:MouseIsOverFrame(Menu, Pos) then
                Dropdown:Close()
            end
        end
    end))

    if Dropdown.Flag then
        Options[Dropdown.Flag] = Dropdown
        Library.Options[Dropdown.Flag] = Dropdown
    end

    table.insert(Groupbox.Elements, Dropdown)

    ValueText.Text = GetDisplayText()
    return Dropdown
end

--@
function Library:CreateWindow(WindowInfo)
    WindowInfo = Library:Validate(WindowInfo or {}, Templates.Window)

    if Library.Window then
        warn("[Evergreen] Only one window is supported at a time.")
        return Library.Window
    end

    Library.CornerRadius = WindowInfo.CornerRadius or 6
    Library.ToggleKeybind = WindowInfo.ToggleKeybind or Enum.KeyCode.RightControl
    Library.Animations = WindowInfo.Animations or Library.Animations
    Library.NotifySide = WindowInfo.NotifySide or "Right"
    Library.ShowCustomCursor = WindowInfo.ShowCustomCursor

    local MainFrame = New("Frame", {
        Name = "Main",
        BackgroundColor3 = "BackgroundColor",
        BorderSizePixel = 0,
        Position = WindowInfo.Position,
        Size = WindowInfo.Size,
        Parent = ScreenGui,
    })

    table.insert(Library.Corners, New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius),
        Parent = MainFrame,
    }))

    local MainStroke = New("UIStroke", {
        Thickness = 1.5,
        Color = "OutlineColor",
        Parent = MainFrame,
    })
    Library:AddToRegistry(MainStroke, {
        Color = "OutlineColor"
    })

    local Topbar = New("Frame", {
        Name = "Topbar",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30),
        Parent = MainFrame,
    })

    table.insert(Library.Corners, New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius),
        Parent = Topbar,
    }))

    New("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.000, Color3.fromRGB(41, 41, 41)),
            ColorSequenceKeypoint.new(0.600, Color3.fromRGB(41, 41, 41)),
            ColorSequenceKeypoint.new(1.000, Color3.fromRGB(31, 31, 31)),
        }),
        Parent = Topbar,
    })

    local TitleLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -24, 1, 0),
        Text = WindowInfo.Title or "Evergreen",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        FontFace = Library.Scheme.Font,
        TextColor3 = "FontColor",
        Parent = Topbar,
    })
    Library:AddToRegistry(TitleLabel, {
        TextColor3 = "FontColor",
        FontFace = "Font"
    })

    local Container = New("Frame", {
        Name = "Container",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 30),
        Size = UDim2.new(1, 0, 1, -30),
        Parent = MainFrame,
    })

    local Tabs = New("ScrollingFrame", {
        Name = "Tabs",
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(0.2, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = Container,
    })

    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Tabs,
    })

    New("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = Tabs,
    })

    local Content = New("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0.2, 0, 0, 0),
        Size = UDim2.new(0.8, 0, 1, 0),
        Parent = Container,
    })

    local Divider = New("Frame", {
        Name = "Divider",
        BackgroundColor3 = "OutlineColor",
        BorderSizePixel = 0,
        Position = UDim2.new(0.2, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Parent = Container,
    })
    Library:AddToRegistry(Divider, {
        BackgroundColor3 = "OutlineColor"
    })

    Library:MakeDraggable(MainFrame, Topbar, false, true)

    if WindowInfo.Resizable then
        local ResizeHandle = New("Frame", {
            Name = "ResizeHandle",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 0, 1, 0),
            Size = UDim2.fromOffset(16, 16),
            Parent = MainFrame,
        })

        Library:MakeResizable(MainFrame, ResizeHandle)
    end

    if WindowInfo.Center then
        local Camera = workspace.CurrentCamera
        if Camera then
            local Viewport = Camera.ViewportSize
            MainFrame.Position = UDim2.fromOffset(
                (Viewport.X - WindowInfo.Size.X.Offset) / 2,
                (Viewport.Y - WindowInfo.Size.Y.Offset) / 2
            )
        end
    end

    local Window = {
        MainFrame = MainFrame,
        Topbar = Topbar,
        TitleLabel = TitleLabel,
        Container = Container,
        Tabs = Tabs,
        Content = Content,
        Divider = Divider,

        TabsList = {},
        ActiveTab = nil,
    }

    Library.Window = Window
    Library.WindowContainer = Content

    --@
    function Window:Toggle(Value: boolean?)
        if typeof(Value) == "boolean" then
            Library.Toggled = Value
        else
            Library.Toggled = not Library.Toggled
        end

        MainFrame.Visible = Library.Toggled

        if WindowInfo.UnlockMouseWhileOpen then
            ModalElement.Modal = Library.Toggled
        end
    end

    --@
    function Library:Toggle(Value: boolean?)
        return Window:Toggle(Value)
    end

    --@
    function Window:AddTab(...)
        local Name = nil
        local Icon = nil
        local Description = nil
        local Order = nil

        if select("#", ...) == 1 and typeof(...) == "table" then
            local Info = select(1, ...)
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
            Order = Info.Order
        else
            Name = select(1, ...) or "Tab"
            Icon = select(2, ...)
            Description = select(3, ...)
            Order = select(4, ...)
        end

        if not tonumber(Order) then
            Order = #Tabs:GetChildren()
        end

        local TabButton = New("TextButton", {
            BackgroundColor3 = "MainColor",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 32),
            Text = "",
            LayoutOrder = Order,
            Parent = Tabs,
        })
        Library:AddToRegistry(TabButton, {
            BackgroundColor3 = "MainColor"
        })

        table.insert(Library.Corners, New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius - 2),
            Parent = TabButton,
        }))

        local TabLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -20, 1, 0),
            Text = Name,
            TextSize = 13,
            TextTransparency = 0.4,
            TextXAlignment = Enum.TextXAlignment.Left,
            FontFace = Library.Scheme.Font,
            TextColor3 = "FontColor",
            Parent = TabButton,
        })
        Library:AddToRegistry(TabLabel, {
            TextColor3 = "FontColor",
            FontFace = "Font"
        })

        local TabContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Visible = false,
            Parent = Content,
        })

        local TabLeft = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            CanvasSize = UDim2.fromScale(0, 0),
            ScrollBarThickness = 0,
            Size = UDim2.new(0.5, -4, 1, 0),
            Parent = TabContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            Parent = TabLeft,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            Parent = TabLeft,
        })

        local TabRight = New("ScrollingFrame", {
            AnchorPoint = Vector2.new(1, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            CanvasSize = UDim2.fromScale(0, 0),
            Position = UDim2.fromScale(1, 0),
            ScrollBarThickness = 0,
            Size = UDim2.new(0.5, -4, 1, 0),
            Parent = TabContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            Parent = TabRight,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            Parent = TabRight,
        })

        local Tab = {
            Name = Name,
            Description = Description,
            Icon = Icon,

            Button = TabButton,
            Label = TabLabel,
            Container = TabContainer,
            Sides = { TabLeft, TabRight },

            Groupboxes = {},
            Tabboxes = {},
            Elements = {},

            Window = Window,
        }

        setmetatable(Tab, BaseGroupbox)

        --@
        function Tab:Show()
            if Library.ActiveTab == Tab then
                return
            end

            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 0,
            }):Play()

            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0,
            }):Play()

            TabContainer.Visible = true
            Library.ActiveTab = Tab
            Window.ActiveTab = Tab
        end

        --@
        function Tab:Hide()
            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 1,
            }):Play()

            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0.4,
            }):Play()

            TabContainer.Visible = false

            if Library.ActiveTab == Tab then
                Library.PreviousTab = Tab
                Library.ActiveTab = nil
                Window.ActiveTab = nil
            end
        end

        --@
        function Tab:SetVisible(Visible: boolean)
            TabButton.Visible = Visible
            if not Visible and Library.ActiveTab == Tab then
                Tab:Hide()
            end
        end

        --@
        function Tab:AddGroupbox(Info)
            Info = Library:Validate(Info or {}, Templates.Groupbox)

            if typeof(Info.Side) == "string" then
                local lowerSide = string.lower(Info.Side)
                if not SideIndex[lowerSide] then
                    error(string.format("Invalid side: %s", Info.Side))
                end
                Info.Side = SideIndex[lowerSide]
            end

            local SideParent = (Info.Side == 1) and TabLeft or TabRight

            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Parent = SideParent,
            })

            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = BoxHolder,
            })

            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                Parent = BoxHolder,
            })

            local GroupboxHolder = New("Frame", {
                BackgroundColor3 = "MainColor",
                Size = UDim2.fromScale(1, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                ClipsDescendants = true,
                Parent = BoxHolder,
            })
            Library:AddToRegistry(GroupboxHolder, {
                BackgroundColor3 = "MainColor"
            })

            table.insert(Library.Corners, New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius),
                Parent = GroupboxHolder,
            }))

            Library:AddOutline(GroupboxHolder)

            local HolderList = New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 0),
                Parent = GroupboxHolder,
            })

            local GroupboxTop = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 30),
                LayoutOrder = 1,
                Parent = GroupboxHolder,
            })

            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                PaddingTop = UDim.new(0, 4),
                Parent = GroupboxTop,
            })

            local GroupboxLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -28, 1, 0),
                Text = Info.Name,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                FontFace = Library.Scheme.Font,
                TextColor3 = "FontColor",
                Parent = GroupboxTop,
            })
            Library:AddToRegistry(GroupboxLabel, {
                TextColor3 = "FontColor",
                FontFace = "Font"
            })

            local CollapseButton = nil
            local CollapseIcon = nil

            if Info.DisableCollapsing ~= true then
                CollapseButton = New("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(22, 22),
                    Text = "",
                    Parent = GroupboxTop,
                })

                CollapseIcon = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Image = "rbxassetid://121870002155147",
                    ImageColor3 = "FontColor",
                    Rotation = 0,
                    Parent = CollapseButton,
                })
                Library:AddToRegistry(CollapseIcon, {
                    ImageColor3 = "FontColor"
                })
            end

            local GroupboxLine = New("Frame", {
                BackgroundColor3 = "OutlineColor",
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 1),
                LayoutOrder = 2,
                Parent = GroupboxHolder,
            })
            Library:AddToRegistry(GroupboxLine, {
                BackgroundColor3 = "OutlineColor"
            })

            local GroupboxContainer = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                LayoutOrder = 3,
                Parent = GroupboxHolder,
            })

            local GroupboxList = New("UIListLayout", {
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = GroupboxContainer,
            })

            New("UIPadding", {
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                PaddingTop = UDim.new(0, 8),
                Parent = GroupboxContainer,
            })

            local Groupbox = {
                Type = "Groupbox",
                Name = Info.Name,
                Description = Info.Description,

                Visible = true,
                Collapsed = false,

                BoxHolder = BoxHolder,
                Holder = GroupboxHolder,
                Container = GroupboxContainer,
                List = GroupboxList,
                Line = GroupboxLine,
                CollapseIcon = CollapseIcon,

                Tab = Tab,
                Elements = {},
                DependencyBoxes = {},
            }

            setmetatable(Groupbox, BaseGroupbox)

            --@
            function Groupbox:Resize()
            end

            --@
            function Groupbox:SetCollapsed(Collapsed)
                if Info.DisableCollapsing == true then
                    return
                end

                Groupbox.Collapsed = Collapsed == true

                if Groupbox.Collapsed then
                    GroupboxContainer.Visible = false
                    GroupboxLine.Visible = false
                    GroupboxContainer.AutomaticSize = Enum.AutomaticSize.None
                    GroupboxContainer.Size = UDim2.new(1, 0, 0, 0)
                else
                    GroupboxContainer.Visible = true
                    GroupboxLine.Visible = true
                    GroupboxContainer.Size = UDim2.fromScale(1, 0)
                    GroupboxContainer.AutomaticSize = Enum.AutomaticSize.Y
                end

                if CollapseIcon then
                    local TargetRotation = Groupbox.Collapsed and -90 or 0
                    TweenService:Create(CollapseIcon, Library.RotatingChevronTweenInfo, {
                        Rotation = TargetRotation
                    }):Play()
                end
            end

            --@
            function Groupbox:ToggleCollapsed()
                Groupbox:SetCollapsed(not Groupbox.Collapsed)
            end

            --@
            function Groupbox:SetVisible(Visible: boolean)
                Groupbox.Visible = Visible
                BoxHolder.Visible = Visible
            end

            --@
            function Groupbox:Show()
                Groupbox:SetVisible(true)
            end

            --@
            function Groupbox:Hide()
                Groupbox:SetVisible(false)
            end

            if CollapseButton then
                CollapseButton.MouseButton1Click:Connect(function()
                    Groupbox:ToggleCollapsed()
                end)
            end

            Tab.Groupboxes[Info.Name] = Groupbox

            if Info.Visible == false then
                Groupbox:Hide()
            end

            if Info.DisableCollapsing ~= true and Info.Collapsed == true then
                Groupbox:SetCollapsed(true)
            end

            return Groupbox
        end

        --@
        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1, Name = Name })
        end

        --@
        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2, Name = Name })
        end

        TabButton.MouseEnter:Connect(function()
            if Library.ActiveTab ~= Tab then
                TweenService:Create(TabLabel, Library.TweenInfo, {
                    TextTransparency = 0.2,
                }):Play()
            end
        end)

        TabButton.MouseLeave:Connect(function()
            if Library.ActiveTab ~= Tab then
                TweenService:Create(TabLabel, Library.TweenInfo, {
                    TextTransparency = 0.4,
                }):Play()
            end
        end)

        TabButton.MouseButton1Click:Connect(function()
            Tab:Show()
        end)

        if not Library.ActiveTab then
            Tab:Show()
        end

        Library.Tabs[Name] = Tab
        table.insert(Window.TabsList, Tab)
        table.insert(Library.TabButtons, TabButton)

        return Tab
    end

    if WindowInfo.AutoShow then
        task.defer(function()
            Window:Toggle(true)
        end)
    else
        MainFrame.Visible = false
    end

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
        if Library.Unloaded then
            return
        end

        if UserInputService:GetFocusedTextBox() then
            return
        end

        if Input.KeyCode == Library.ToggleKeybind then
            Library:Toggle()
        end
    end))

    Library:GiveSignal(UserInputService.WindowFocused:Connect(function()
        Library.IsRobloxFocused = true
    end))

    Library:GiveSignal(UserInputService.WindowFocusReleased:Connect(function()
        Library.IsRobloxFocused = false
    end))

    return Window
end

--@
function Library:Unload()
    Library.Unloaded = true

    for Index = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Index)
        if Connection and Connection.Connected then
            Connection:Disconnect()
        end
    end

    for _ = 1, #Library.UnloadSignals do
        local Callback = table.remove(Library.UnloadSignals, 1)
        if Callback then
            Library:SafeCallback(Callback)
        end
    end

    if ScreenGui then
        ScreenGui:Destroy()
    end

    table.clear(Library.Registry)
    table.clear(Options)
    table.clear(Toggles)
    table.clear(Buttons)
    table.clear(Labels)
    table.clear(Library.Tabs)
    table.clear(Library.TabButtons)
    table.clear(Library.Scales)
    table.clear(Library.Corners)

    getgenv().Library = nil
end

--@
function Library:OnUnload(Callback)
    table.insert(Library.UnloadSignals, Callback)
end

getgenv().Library = Library
return Library
