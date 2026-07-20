--[[
    Azex UI Library
    A modern, high-performance UI framework for Roblox exploiting.
    Inspired by Obsidian, but built from scratch with enhancements.
]]

local cloneref = cloneref or clonereference or function(instance) return instance end

-- Services
local CoreGui = cloneref(game:GetService("CoreGui"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local SoundService = cloneref(game:GetService("SoundService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TextService = cloneref(game:GetService("TextService"))
local Teams = cloneref(game:GetService("Teams"))
local TweenService = cloneref(game:GetService("TweenService"))

-- Globals
local getgenv = getgenv or function() return shared end
local setclipboard = setclipboard or nil
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function() return CoreGui end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = cloneref(LocalPlayer:GetMouse())

-- Asset Manager
local CustomImageManager = {}
local Assets = {}

local function RecursiveCreatePath(path, isFile)
    if not isfolder or not makefolder then return end
    local segments = path:split("/")
    if isFile then table.remove(segments, #segments) end
    local traversed = ""
    for _, seg in ipairs(segments) do
        local full = traversed .. seg
        if not isfolder(full) then makefolder(full) end
        traversed = full .. "/"
    end
    return traversed
end

function CustomImageManager:AddAsset(name, robloxId, url, forceRedownload)
    assert(not Assets[name], "Asset already exists: " .. name)
    Assets[name] = {
        RobloxId = robloxId,
        Path = "Azex/assets/" .. name,
        URL = url,
        Id = nil,
    }
    self:DownloadAsset(name, forceRedownload)
end

function CustomImageManager:GetAsset(name)
    local data = Assets[name]
    if not data then return nil end
    if data.Id then return data.Id end
    local id = "rbxassetid://" .. data.RobloxId
    if getcustomasset then
        local success, newId = pcall(getcustomasset, data.Path)
        if success and newId then id = newId end
    end
    data.Id = id
    return id
end

function CustomImageManager:DownloadAsset(name, forceRedownload)
    if not getcustomasset or not writefile or not isfile then return false, "missing functions" end
    local data = Assets[name]
    RecursiveCreatePath(data.Path, true)
    if not forceRedownload and isfile(data.Path) then return true, nil end
    local success, err = pcall(function()
        writefile(data.Path, game:HttpGet(data.URL))
    end)
    return success, err
end

-- Preload default assets
local BaseURL = "https://raw.githubusercontent.com/your-repo/Azex/main/assets/"
CustomImageManager:AddAsset("TransparencyTexture", 139785960036434, BaseURL .. "TransparencyTexture.png")
CustomImageManager:AddAsset("SaturationMap", 4155801252, BaseURL .. "SaturationMap.png")
CustomImageManager:AddAsset("LoadingIcon", 97544096941083, BaseURL .. "LoadingIcon.png")
CustomImageManager:AddAsset("CheckIcon", 97682394690683, BaseURL .. "CheckIcon.png")

-- Library table
local Library = {
    LocalPlayer = LocalPlayer,
    IsRobloxFocused = true,
    DevicePlatform = nil,
    IsMobile = false,

    ScreenGui = nil,
    Window = nil,
    WindowContainer = nil,

    SearchText = "",
    Searching = false,
    GlobalSearch = false,
    LastSearchTab = nil,

    ActiveTab = nil,
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

    Labels = {},
    Buttons = {},
    Toggles = {},
    Options = {},

    ToggleKeybind = Enum.KeyCode.RightControl,
    ShowToggleFrameInKeybinds = true,
    NotifyOnError = false,
    ShowCustomCursor = true,
    ForceCheckbox = false,

    CantDragForced = false,
    DraggableElements = {},

    Signals = {},
    UnloadSignals = {},

    OriginalMinSize = Vector2.new(480, 360),
    MinSize = Vector2.new(480, 360),
    DPIScale = 1,
    CornerRadius = 4,

    IsLightTheme = false,
    Scheme = {
        BackgroundColor = Color3.fromRGB(15, 15, 15),
        MainColor = Color3.fromRGB(25, 25, 25),
        AccentColor = Color3.fromRGB(125, 85, 255),
        OutlineColor = Color3.fromRGB(40, 40, 40),
        FontColor = Color3.new(1, 1, 1),
        Font = Font.fromEnum(Enum.Font.Code),
        RedColor = Color3.fromRGB(255, 50, 50),
        DestructiveColor = Color3.fromRGB(220, 38, 38),
        DarkColor = Color3.new(0, 0, 0),
        WhiteColor = Color3.new(1, 1, 1),
        BackgroundImage = "",
    },

    Registry = {},
    Scales = {},
    ScalesOffset = {},

    ImageManager = CustomImageManager,
    ShowCursorBinding = string.sub(tostring({}), 10),

    Notify = nil,
    Toggle = nil,
}

-- Determine mobile
if RunService:IsStudio() then
    Library.IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    Library.OriginalMinSize = Library.IsMobile and Vector2.new(480, 240) or Vector2.new(480, 360)
else
    pcall(function() Library.DevicePlatform = UserInputService:GetPlatform() end)
    Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
    Library.OriginalMinSize = Library.IsMobile and Vector2.new(480, 240) or Vector2.new(480, 360)
end

-- Templates
local Templates = {
    Frame = { BorderSizePixel = 0 },
    ImageLabel = { BackgroundTransparency = 1, BorderSizePixel = 0 },
    ImageButton = { AutoButtonColor = false, BorderSizePixel = 0 },
    ScrollingFrame = { BorderSizePixel = 0 },
    TextLabel = { BorderSizePixel = 0, FontFace = "Font", RichText = true, TextColor3 = "FontColor" },
    TextButton = { AutoButtonColor = false, BorderSizePixel = 0, FontFace = "Font", RichText = true, TextColor3 = "FontColor" },
    TextBox = { BorderSizePixel = 0, FontFace = "Font", PlaceholderColor3 = function() local h,s,v = Library.Scheme.FontColor:ToHSV() return Color3.fromHSV(h, s, v/2) end, Text = "", TextColor3 = "FontColor" },
    UIListLayout = { SortOrder = Enum.SortOrder.LayoutOrder },
    UIStroke = { ApplyStrokeMode = Enum.ApplyStrokeMode.Border },

    Window = {
        Title = "Azex",
        Footer = "Azex UI",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(720, 600),
        IconSize = UDim2.fromOffset(30, 30),
        AutoShow = true,
        Center = true,
        Resizable = true,
        SearchbarSize = UDim2.fromScale(1, 1),
        GlobalSearch = false,
        CornerRadius = 4,
        NotifySide = "Right",
        ShowCustomCursor = true,
        Font = Enum.Font.Code,
        ToggleKeybind = Enum.KeyCode.RightControl,
        ShowMobileButtons = true,
        MobileButtonsSide = "Left",
        UnlockMouseWhileOpen = true,
        EnableSidebarResize = false,
        EnableCompacting = true,
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
    Dialog = {
        Title = "Dialog",
        Description = "Description",
        AutoDismiss = true,
        OutsideClickDismiss = true,
        FooterButtons = {}
    },
    Loading = {
        Title = "Loading",
        Icon = 95816097006870,
        IconSize = UDim2.fromOffset(30, 30),
        LoadingIcon = CustomImageManager:GetAsset("LoadingIcon"),
        LoadingIconColor = nil,
        LoadingIconTweenTime = 1,
        CurrentStep = 0,
        TotalSteps = 10,
        ShowSidebar = false,
        AutoResizeHeight = false,
        WindowWidth = 450,
        WindowHeight = 275,
        ContentWidth = 450,
        SidebarWidth = 250,
    },
    Toggle = {
        Text = "Toggle",
        Default = false,
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
        Color = Color3.new(1,1,1),
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
        Modes = {"Always", "Toggle", "Hold"},
        SyncToggleState = false,
        Callback = function() end,
        ChangedCallback = function() end,
        Changed = function() end,
        Clicked = function() end,
    },
    ColorPicker = {
        Default = Color3.new(1,1,1),
        Callback = function() end,
        Changed = function() end,
    },
}

-- Utility functions
local function WaitForEvent(event, timeout, condition)
    local bindable = Instance.new("BindableEvent")
    local conn = event:Once(function(...)
        if not condition or (type(condition) == "function" and condition(...)) then
            bindable:Fire(true)
        else
            bindable:Fire(false)
        end
    end)
    task.delay(timeout, function() conn:Disconnect() bindable:Fire(false) end)
    local result = bindable.Event:Wait()
    bindable:Destroy()
    return result
end

local function IsMouseInput(input, includeM2)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or
        (includeM2 and input.UserInputType == Enum.UserInputType.MouseButton2) or
        input.UserInputType == Enum.UserInputType.Touch
end

local function IsClickInput(input, includeM2)
    return IsMouseInput(input, includeM2) and input.UserInputState == Enum.UserInputState.Begin and Library.IsRobloxFocused
end

local function IsHoverInput(input)
    return (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
        and input.UserInputState == Enum.UserInputState.Change
end

local function IsDragInput(input, includeM2)
    return IsMouseInput(input, includeM2) and (input.UserInputState == Enum.UserInputState.Begin or input.UserInputState == Enum.UserInputState.Change) and Library.IsRobloxFocused
end

local function IsMouseClickInput(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3
end

local function IsMovementInput(input)
    return (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and Library.IsRobloxFocused
end

local function TableSize(t) local c=0 for _,_ in pairs(t) do c=c+1 end return c end

local function StopTween(tween, destroy)
    if not tween then return end
    if tween.PlaybackState == Enum.PlaybackState.Playing then tween:Cancel() end
    if destroy then pcall(tween.Destroy, tween) end
end

local function Trim(s) return s:match("^%s*(.-)%s*$") end
local function Round(v, r) if r==0 then return math.floor(v) end return tonumber(string.format("%."..r.."f", v)) end

local function GetPlayers(excludeLocal)
    local list = Players:GetPlayers()
    if excludeLocal then
        local idx = table.find(list, LocalPlayer)
        if idx then table.remove(list, idx) end
    end
    table.sort(list, function(a,b) return a.Name:lower() < b.Name:lower() end)
    return list
end

local function GetTeams()
    local list = Teams:GetTeams()
    table.sort(list, function(a,b) return a.Name:lower() < b.Name:lower() end)
    return list
end

-- Scheme helpers
local SchemeAlias = {
    Red = "RedColor",
    White = "WhiteColor",
    Dark = "DarkColor"
}

local function GetSchemeValue(index)
    if not index then return nil end
    local alias = SchemeAlias[index]
    if alias and Library.Scheme[alias] ~= nil then
        warn(("Scheme value %q is deprecated, use %q instead"):format(index, alias))
        return Library.Scheme[alias]
    end
    return Library.Scheme[index]
end

-- Registry
function Library:AddToRegistry(instance, props)
    Library.Registry[instance] = props
end

function Library:RemoveFromRegistry(instance)
    Library.Registry[instance] = nil
end

function Library:UpdateColorsUsingRegistry()
    for instance, props in pairs(Library.Registry) do
        for prop, index in pairs(props) do
            local value = GetSchemeValue(index)
            if value or type(index) == "function" then
                instance[prop] = value or index()
            end
        end
    end
end

-- Basic object creation
local function FillInstance(template, instance)
    local themeProps = Library.Registry[instance] or {}
    for key, value in pairs(template) do
        if key ~= "Text" then
            local schemeVal = GetSchemeValue(value)
            if schemeVal or type(value) == "function" then
                themeProps[key] = value
                value = schemeVal or value()
            else
                themeProps[key] = nil
            end
        end
        instance[key] = value
    end
    if TableSize(themeProps) > 0 then
        Library.Registry[instance] = themeProps
    end
end

local function New(className, properties)
    local inst = Instance.new(className)
    if Templates[className] then
        FillInstance(Templates[className], inst)
    end
    FillInstance(properties, inst)
    if properties.Parent and not properties.ZIndex then
        pcall(function() inst.ZIndex = properties.Parent.ZIndex end)
    end
    return inst
end

-- UI parenting
local function SafeParentUI(inst, parent)
    local success, err = pcall(function()
        if not parent then parent = CoreGui end
        local dest = type(parent) == "function" and parent() or parent
        inst.Parent = dest
    end)
    if not (success and inst.Parent) then
        inst.Parent = Library.LocalPlayer:WaitForChild("PlayerGui", math.huge)
    end
end

local function ParentUI(inst, skipHidden)
    if skipHidden then
        SafeParentUI(inst, CoreGui)
        return
    end
    pcall(protectgui, inst)
    SafeParentUI(inst, gethui)
end

-- ScreenGui
local ScreenGui = New("ScreenGui", {
    Name = "Azex",
    DisplayOrder = 998,
    ResetOnSpawn = false,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui

ScreenGui.DescendantRemoving:Connect(function(inst)
    Library:RemoveFromRegistry(inst)
end)

local ModalElement = New("TextButton", {
    BackgroundTransparency = 1,
    Modal = false,
    Size = UDim2.fromScale(0,0),
    AnchorPoint = Vector2.zero,
    Text = "",
    ZIndex = -999,
    Parent = ScreenGui,
})

-- Cursor
local Cursor, CursorCustomImage
do
    Cursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "WhiteColor",
        Size = UDim2.fromOffset(9,1),
        Visible = false,
        ZIndex = 11000,
        Parent = ScreenGui,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.new(1,2,1,2),
        ZIndex = 10999,
        Parent = Cursor,
    })
    local CursorV = New("Frame", {
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = "WhiteColor",
        Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromOffset(1,9),
        ZIndex = 11000,
        Parent = Cursor,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.new(1,2,1,2),
        ZIndex = 10999,
        Parent = CursorV,
    })
    CursorCustomImage = New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromOffset(20,20),
        ZIndex = 11000,
        Visible = false,
        Parent = Cursor,
    })
end

-- Notification area
local NotificationArea
do
    NotificationArea = New("Frame", {
        AnchorPoint = Vector2.new(1,0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1,-6,0,6),
        Size = UDim2.new(0,300,1,-6),
        Parent = ScreenGui,
    })
    table.insert(Library.Scales, New("UIScale", { Parent = NotificationArea }))
end

-- Notification system
local NotifyOrder = {}

function Library:SetNotifySide(side)
    side = side:lower()
    Library.NotifySide = side
    local isLeft = side == "left"
    NotificationArea.AnchorPoint = isLeft and Vector2.new(0,0) or Vector2.new(1,0)
    NotificationArea.Position = isLeft and UDim2.fromOffset(6,6) or UDim2.new(1,-6,0,6)
    for bg in pairs(Library.Notifications) do
        if bg and bg.Parent then
            bg.AnchorPoint = isLeft and Vector2.new(0,0) or Vector2.new(1,0)
        end
    end
    Library:UpdateNotificationPositions(true)
end

function Library:UpdateNotificationPositions(snap)
    local isLeft = Library.NotifySide == "left"
    local xScale = isLeft and 0 or 1
    local runningY = 0
    for _, bg in ipairs(NotifyOrder) do
        local data = Library.Notifications[bg]
        if not (data and bg.Parent) then continue end
        local target = UDim2.new(xScale, 0, 0, runningY)
        if snap or not data.PositionInitialized then
            bg.Position = target
            data.PositionInitialized = true
        elseif bg.Position ~= target then
            TweenService:Create(bg, Library.NotifyTweenInfo, { Position = target }):Play()
        end
        runningY = runningY + bg.AbsoluteSize.Y + 8
    end
end

function Library:Notify(...)
    local data = {}
    local info = select(1, ...)
    if type(info) == "table" then
        data.Title = tostring(info.Title)
        data.TitleColor = info.TitleColor
        data.Description = tostring(info.Description)
        data.DescriptionColor = info.DescriptionColor
        data.Time = info.Time or 5
        data.SoundId = info.SoundId
        data.Steps = info.Steps
        data.Persist = info.Persist
        data.Icon = info.Icon
        data.BigIcon = info.BigIcon
        data.IconColor = info.IconColor
        data.Volume = tonumber(info.Volume) or 3
    else
        data.Description = tostring(info)
        data.Time = select(2, ...) or 5
        data.SoundId = select(3, ...)
        data.Volume = select(4, ...) or 3
    end
    data.Destroyed = false

    local deletedInstance = false
    local deleteConn
    if type(data.Time) == "Instance" then
        deleteConn = data.Time.Destroying:Connect(function()
            deletedInstance = true
            deleteConn:Disconnect()
            deleteConn = nil
        end)
    end

    local isLeft = Library.NotifySide == "left"
    local bg = New("Frame", {
        AnchorPoint = isLeft and Vector2.new(0,0) or Vector2.new(1,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1,0),
        Visible = false,
        Parent = NotificationArea,
    })

    local holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "MainColor",
        Position = isLeft and UDim2.new(-1,-8,0,-2) or UDim2.new(1,8,0,-2),
        Size = UDim2.fromScale(1,1),
        ZIndex = 5,
        Parent = bg,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = holder }))
    New("UIListLayout", { Padding = UDim.new(0,4), Parent = holder })
    New("UIPadding", { PaddingBottom = UDim.new(0,8), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,8), Parent = holder })
    Library:AddOutline(holder)

    local content = New("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromScale(1,0),
        Parent = holder,
    })

    local bigIcon
    if data.BigIcon then
        local icon = Library:GetCustomIcon(data.BigIcon)
        if icon then
            bigIcon = New("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(24,24),
                Image = icon.Url,
                ImageColor3 = data.IconColor or "AccentColor",
                ImageRectOffset = icon.ImageRectOffset,
                ImageRectSize = icon.ImageRectSize,
                Parent = content,
            })
            New("UIListLayout", { Padding = UDim.new(0,8), FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Parent = content })
        end
    end

    local textContainer = New("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromScale(0,0),
        Parent = content,
    })
    New("UIListLayout", { Padding = UDim.new(0,4), Parent = textContainer })

    local titleContainer
    if data.Title then
        titleContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(0,0),
            Parent = textContainer,
        })
    end

    local iconLabel
    if data.Icon and titleContainer then
        local icon = Library:GetCustomIcon(data.Icon)
        if icon then
            iconLabel = New("ImageLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0,0.5),
                Position = UDim2.new(0,0,0.5,1),
                Size = UDim2.fromOffset(15,15),
                Image = icon.Url,
                ImageColor3 = data.IconColor or "FontColor",
                ImageRectOffset = icon.ImageRectOffset,
                ImageRectSize = icon.ImageRectSize,
                Parent = titleContainer,
            })
        end
    end

    local title, desc
    local titleX, descX = 0,0

    if data.Title then
        title = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0,0.5),
            Position = UDim2.new(0, (data.Icon and 21 or 0), 0.5,0),
            Size = UDim2.fromScale(0,0),
            Text = data.Title,
            TextColor3 = data.TitleColor or "FontColor",
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextWrapped = true,
            Parent = titleContainer,
        })
    end

    if data.Description then
        desc = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(0,0),
            Text = data.Description,
            TextColor3 = data.DescriptionColor or "FontColor",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = textContainer,
        })
    end

    local function Resize()
        local extraW = bigIcon and 32 or 0
        local iconW = iconLabel and 21 or 0
        if title then
            local x,y = Library:GetTextBounds(title.Text, title.FontFace, title.TextSize, (NotificationArea.AbsoluteSize.X / Library.DPIScale) - 24 - extraW - iconW)
            title.Size = UDim2.fromOffset(x, y)
            titleX = x + iconW
            titleContainer.Size = UDim2.fromOffset(titleX, math.max(y, iconLabel and 16 or 0))
        end
        if desc then
            local x,y = Library:GetTextBounds(desc.Text, desc.FontFace, desc.TextSize, (NotificationArea.AbsoluteSize.X / Library.DPIScale) - 24 - extraW)
            desc.Size = UDim2.fromOffset(x, y)
            descX = x
        end
        bg.Size = UDim2.fromOffset(math.max(titleX, descX) + 24 + extraW, 0)
        if Library.Notifications[bg] then
            Library:UpdateNotificationPositions()
        end
    end

    function data:ChangeTitle(text)
        if title then
            data.Title = tostring(text)
            title.Text = data.Title
            Resize()
        end
    end

    function data:ChangeDescription(text)
        if desc then
            data.Description = tostring(text)
            desc.Text = data.Description
            Resize()
        end
    end

    function data:ChangeStep(step)
        if timerFill and data.Steps then
            step = math.clamp(step or 0, 0, data.Steps)
            timerFill.Size = UDim2.fromScale(step/data.Steps, 1)
        end
    end

    function data:Destroy()
        if data.Destroyed then return end
        data.Destroyed = true
        if type(data.Time) == "Instance" then pcall(data.Time.Destroy, data.Time) end
        if deleteConn then deleteConn:Disconnect() end
        local idx = table.find(NotifyOrder, bg)
        if idx then table.remove(NotifyOrder, idx) end
        Library:UpdateNotificationPositions()
        TweenService:Create(holder, Library.NotifyTweenInfo, {
            Position = isLeft and UDim2.new(-1,-8,0,-2) or UDim2.new(1,8,0,-2)
        }):Play()
        task.delay(Library.NotifyTweenInfo.Time, function()
            Library.Notifications[bg] = nil
            bg:Destroy()
        end)
    end

    Resize()

    local timerHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,7),
        Visible = (data.Persist ~= true and type(data.Time) ~= "Instance") or type(data.Steps) == "number",
        Parent = holder,
    })
    local timerBar = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        Position = UDim2.fromOffset(0,3),
        Size = UDim2.new(1,0,0,2),
        Parent = timerHolder,
    })
    local timerFill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Size = UDim2.fromScale(1,1),
        Parent = timerBar,
    })

    if type(data.Time) == "Instance" then
        timerFill.Size = UDim2.fromScale(0,1)
    end
    if data.SoundId then
        local id = data.SoundId
        if type(id) == "number" then id = "rbxassetid://"..id end
        New("Sound", { SoundId = id, Volume = tonumber(data.Volume) or 3, PlayOnRemove = true, Parent = SoundService }):Destroy()
    end

    data.Holder = holder

    table.insert(NotifyOrder, bg)
    Library.Notifications[bg] = data
    Library:UpdateNotificationPositions()
    bg.Visible = true
    TweenService:Create(holder, Library.NotifyTweenInfo, {
        Position = UDim2.fromOffset(0,0)
    }):Play()

    task.delay(Library.NotifyTweenInfo.Time, function()
        if data.Persist then return end
        if type(data.Time) == "Instance" then
            repeat task.wait() until deletedInstance or data.Destroyed
        else
            TweenService:Create(timerFill, TweenInfo.new(data.Time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                Size = UDim2.fromScale(0,1)
            }):Play()
            task.wait(data.Time)
        end
        if not data.Destroyed then data:Destroy() end
    end)

    return data
end

-- Context Menu
local CurrentMenu
function Library:AddContextMenu(holder, size, offset, list, activeCallback, ignoreCorner, specificCorner, animType)
    local menu
    local parentGui = holder:FindFirstAncestorOfClass("ScreenGui")
    local menuZ = math.max(10, holder.ZIndex + 1)
    if parentGui ~= ScreenGui and (Library.ActiveLoading and parentGui ~= Library.ActiveLoading.ScreenGui) then
        parentGui = ScreenGui
    end

    if list then
        menu = New("ScrollingFrame", {
            AutomaticCanvasSize = list == 2 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            AutomaticSize = list == 1 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundColor3 = "BackgroundColor",
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            CanvasSize = UDim2.fromOffset(0,0),
            ScrollBarImageColor3 = "OutlineColor",
            ScrollBarThickness = list == 2 and 2 or 0,
            Size = type(size) == "function" and size() or size,
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            Visible = false,
            ZIndex = menuZ,
            Parent = parentGui,
        })
    else
        menu = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            Size = type(size) == "function" and size() or size,
            Visible = false,
            ZIndex = menuZ,
            Parent = parentGui,
        })
    end
    table.insert(Library.Scales, New("UIScale", { Parent = menu }))

    New("UIStroke", { Color = "OutlineColor", Parent = menu })

    local corner
    if not ignoreCorner then
        if specificCorner == "top" then
            corner = New("UICorner", { TopLeftRadius = UDim.new(0, Library.CornerRadius/2), TopRightRadius = UDim.new(0, Library.CornerRadius/2), BottomRightRadius = UDim.new(0,0), BottomLeftRadius = UDim.new(0,0), Parent = menu })
            table.insert(Library.SpecificCorners, corner)
        elseif specificCorner == "bottom" then
            corner = New("UICorner", { TopLeftRadius = UDim.new(0,0), TopRightRadius = UDim.new(0,0), BottomRightRadius = UDim.new(0, Library.CornerRadius/2), BottomLeftRadius = UDim.new(0, Library.CornerRadius/2), Parent = menu })
            table.insert(Library.SpecificCorners, corner)
        elseif specificCorner == "no_left" then
            corner = New("UICorner", { TopLeftRadius = UDim.new(0,0), TopRightRadius = UDim.new(0, Library.CornerRadius/2), BottomRightRadius = UDim.new(0, Library.CornerRadius/2), BottomLeftRadius = UDim.new(0,0), Parent = menu })
            table.insert(Library.SpecificCorners, corner)
        elseif specificCorner == "no_top_left" then
            corner = New("UICorner", { TopLeftRadius = UDim.new(0,0), TopRightRadius = UDim.new(0, Library.CornerRadius/2), BottomRightRadius = UDim.new(0, Library.CornerRadius/2), BottomLeftRadius = UDim.new(0, Library.CornerRadius/2), Parent = menu })
            table.insert(Library.SpecificCorners, corner)
        else
            corner = New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius/2), Parent = menu })
            table.insert(Library.Corners, corner)
        end
    end

    local t = {
        Active = false,
        Holder = holder,
        Menu = menu,
        Size = size,
        AutoSizeY = list == 1,
        OpenCloseTween = nil,
        Connections = {},
        Destroyed = false,
        Animated = function()
            if not animType or animType == "none" then return false end
            if not (Library.Animations and Library.Animations[animType]) then return false end
            return true, Library[string.format("%sTransitionInfo", animType)] or TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    }

    if list then
        t.List = New("UIListLayout", { Parent = menu })
    end

    function t:Open()
        if CurrentMenu == self then return end
        if CurrentMenu then CurrentMenu:Close() end
        CurrentMenu = self
        self.Active = true

        local off = type(offset) == "function" and offset() or offset
        menu.Position = UDim2.fromOffset(
            math.floor(holder.AbsolutePosition.X + off[1]),
            math.floor(holder.AbsolutePosition.Y + off[2])
        )

        if type(activeCallback) == "function" then Library:SafeCallback(activeCallback, true) end

        if self.OpenCloseTween then StopTween(self.OpenCloseTween, true); self.OpenCloseTween = nil end

        local animated, tweenInfo = self:Animated()
        if animated then
            local targetSize = type(self.Size) == "function" and self.Size() or self.Size
            if self.AutoSizeY then
                local fullHeight = menu.AbsoluteSize.Y
                menu.AutomaticSize = Enum.AutomaticSize.None
                targetSize = UDim2.new(targetSize.X.Scale, targetSize.X.Offset, 0, fullHeight)
            end
            menu.Size = UDim2.new(targetSize.X.Scale, targetSize.X.Offset, 0, 0)
            menu.Visible = true
            local tw = TweenService:Create(menu, tweenInfo, { Size = targetSize })
            self.OpenCloseTween = tw
            local conn = Library:GiveSignal(tw.Completed:Once(function()
                if conn then conn:Disconnect() end
                if self.OpenCloseTween == tw then
                    StopTween(self.OpenCloseTween, true)
                    self.OpenCloseTween = nil
                    if self.AutoSizeY then menu.AutomaticSize = Enum.AutomaticSize.Y end
                end
            end))
            tw:Play()
        else
            menu.Size = type(self.Size) == "function" and self.Size() or self.Size
            menu.Visible = true
        end

        self.Signal = holder:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            local off2 = type(offset) == "function" and offset() or offset
            menu.Position = UDim2.fromOffset(
                math.floor(holder.AbsolutePosition.X + off2[1]),
                math.floor(holder.AbsolutePosition.Y + off2[2])
            )
            if not Library:IsInsideFrame(Library.WindowContainer, holder) and self.Active then
                self:Close()
            end
        end)
    end

    function t:Close()
        if CurrentMenu ~= self then return end
        if self.Signal then self.Signal:Disconnect(); self.Signal = nil end
        self.Active = false
        CurrentMenu = nil
        if type(activeCallback) == "function" then Library:SafeCallback(activeCallback, false) end

        if self.OpenCloseTween then StopTween(self.OpenCloseTween, true); self.OpenCloseTween = nil end

        local animated, tweenInfo = self:Animated()
        if animated then
            if self.AutoSizeY then menu.AutomaticSize = Enum.AutomaticSize.None end
            local current = menu.Size
            local collapsed = UDim2.new(current.X.Scale, current.X.Offset, 0, 0)
            local tw = TweenService:Create(menu, tweenInfo, { Size = collapsed })
            self.OpenCloseTween = tw
            local conn = Library:GiveSignal(tw.Completed:Once(function()
                if conn then conn:Disconnect() end
                if self.OpenCloseTween == tw then
                    StopTween(self.OpenCloseTween, true)
                    self.OpenCloseTween = nil
                    menu.Visible = false
                    if self.AutoSizeY then menu.AutomaticSize = Enum.AutomaticSize.Y end
                end
            end))
            tw:Play()
        else
            menu.Visible = false
        end
    end

    function t:Toggle()
        if self.Active then self:Close() else self:Open() end
    end

    function t:SetSize(sz)
        self.Size = sz
        menu.Size = type(sz) == "function" and sz() or sz
    end

    function t:Destroy()
        self.Destroyed = true
        for _, conn in self.Connections do conn:Disconnect() end
        if CurrentMenu == self then self:Close() end
        if self.OpenCloseTween then StopTween(self.OpenCloseTween, true); self.OpenCloseTween = nil end
        if menu then menu:Destroy() end
    end

    return t
end

Library:GiveSignal(UserInputService.InputBegan:Connect(function(input)
    if Library.Unloaded then return end
    if IsClickInput(input, true) then
        local pos = input.Position
        if CurrentMenu and not (Library:MouseIsOverFrame(CurrentMenu.Menu, pos) or Library:MouseIsOverFrame(CurrentMenu.Holder, pos)) then
            CurrentMenu:Close()
        end
    end
end))

-- Tooltip
local TooltipLabel = New("TextLabel", {
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = "BackgroundColor",
    TextSize = 14,
    TextWrapped = true,
    Visible = false,
    ZIndex = 20,
    Parent = ScreenGui,
})
New("UIPadding", { PaddingBottom = UDim.new(0,2), PaddingLeft = UDim.new(0,4), PaddingRight = UDim.new(0,4), PaddingTop = UDim.new(0,2), Parent = TooltipLabel })
table.insert(Library.Scales, New("UIScale", { Parent = TooltipLabel }))
New("UIStroke", { Color = "OutlineColor", Parent = TooltipLabel })
table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius/2), Parent = TooltipLabel }))
TooltipLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    if Library.Unloaded then return end
    local x,_ = Library:GetTextBounds(TooltipLabel.Text, TooltipLabel.FontFace, TooltipLabel.TextSize, (workspace.CurrentCamera.ViewportSize.X - TooltipLabel.AbsolutePosition.X - 8)/Library.DPIScale)
    TooltipLabel.Size = UDim2.fromOffset(x + 8, 0)
end)

local CurrentHoverInstance
function Library:AddTooltip(info, disabledInfo, hoverInst)
    local tt = { Disabled = false, Hovering = false, Signals = {} }

    local function DoHover()
        if CurrentHoverInstance == hoverInst or Library.ActiveDialog or (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse)) or (tt.Disabled and type(disabledInfo) ~= "string") or (not tt.Disabled and type(info) ~= "string") then
            return
        end
        CurrentHoverInstance = hoverInst
        local parentGui = hoverInst:FindFirstAncestorOfClass("ScreenGui")
        if parentGui ~= ScreenGui and (Library.ActiveLoading and parentGui ~= Library.ActiveLoading.ScreenGui) then
            parentGui = ScreenGui
        end
        TooltipLabel.Parent = parentGui
        TooltipLabel.Text = tt.Disabled and disabledInfo or info
        TooltipLabel.Visible = true
        while (Library.Toggled or Library.ActiveLoading) and not Library.ActiveDialog and Library:MouseIsOverFrame(hoverInst, Mouse) and not (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse)) do
            TooltipLabel.Position = UDim2.fromOffset(
                Mouse.X + (Library.ShowCustomCursor and 8 or 14),
                Mouse.Y + (Library.ShowCustomCursor and 8 or 12)
            )
            RunService.RenderStepped:Wait()
        end
        TooltipLabel.Visible = false
        CurrentHoverInstance = nil
    end

    local function AddSignal(conn)
        if conn and (type(conn) == "RBXScriptConnection" or type(conn) == "RBXScriptSignal") then
            table.insert(tt.Signals, conn)
        end
        return conn
    end

    AddSignal(hoverInst.MouseEnter:Connect(DoHover))
    AddSignal(hoverInst.MouseMoved:Connect(DoHover))
    AddSignal(hoverInst.MouseLeave:Connect(function()
        if CurrentHoverInstance == hoverInst then
            TooltipLabel.Visible = false
            CurrentHoverInstance = nil
        end
    end))

    function tt:Destroy()
        for _, conn in ipairs(tt.Signals) do
            if conn and conn.Connected then conn:Disconnect() end
        end
        if CurrentHoverInstance == hoverInst then
            TooltipLabel.Visible = false
            CurrentHoverInstance = nil
        end
    end
    return tt
end

-- Draggable elements
function Library:MakeDraggable(ui, dragFrame, ignoreToggled, isMainWindow)
    local startPos, framePos, dragging, changed, inputBegan, inputChanged
    inputBegan = dragFrame.InputBegan:Connect(function(input)
        if not IsClickInput(input) or (isMainWindow and Library.CantDragForced) then return end
        startPos = input.Position
        framePos = ui.Position
        dragging = true
        changed = input.Changed:Connect(function()
            if input.UserInputState ~= Enum.UserInputState.End then return end
            dragging = false
            if changed and changed.Connected then changed:Disconnect(); changed = nil end
        end)
    end)
    inputChanged = UserInputService.InputChanged:Connect(function(input)
        if (not ignoreToggled and not Library.Toggled) or (isMainWindow and Library.CantDragForced) or not (ScreenGui and ScreenGui.Parent) then
            dragging = false
            if changed and changed.Connected then changed:Disconnect(); changed = nil end
            return
        end
        if dragging and IsHoverInput(input) then
            local delta = input.Position - startPos
            ui.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)
    Library:GiveSignal(inputChanged); Library:GiveSignal(inputBegan)
    ui.Destroying:Once(function()
        if inputChanged and inputChanged.Connected then inputChanged:Disconnect() end
        if inputBegan and inputBegan.Connected then inputBegan:Disconnect() end
        if changed and changed.Connected then changed:Disconnect() end
        local idx = table.find(Library.Signals, inputChanged); if idx then table.remove(Library.Signals, idx) end
        idx = table.find(Library.Signals, inputBegan); if idx then table.remove(Library.Signals, idx) end
    end)
end

function Library:MakeResizable(ui, dragFrame, callback)
    local startPos, frameSize, dragging, changed, inputBegan, inputChanged
    inputBegan = dragFrame.InputBegan:Connect(function(input)
        if not IsClickInput(input) then return end
        startPos = input.Position
        frameSize = ui.Size
        dragging = true
        changed = input.Changed:Connect(function()
            if input.UserInputState ~= Enum.UserInputState.End then return end
            dragging = false
            if changed and changed.Connected then changed:Disconnect(); changed = nil end
        end)
    end)
    inputChanged = UserInputService.InputChanged:Connect(function(input)
        if not ui.Visible or not (ScreenGui and ScreenGui.Parent) then
            dragging = false
            if changed and changed.Connected then changed:Disconnect(); changed = nil end
            return
        end
        if dragging and IsHoverInput(input) then
            local delta = input.Position - startPos
            ui.Size = UDim2.new(
                frameSize.X.Scale,
                math.clamp(frameSize.X.Offset + delta.X, Library.MinSize.X, math.huge),
                frameSize.Y.Scale,
                math.clamp(frameSize.Y.Offset + delta.Y, Library.MinSize.Y, math.huge)
            )
            if callback then Library:SafeCallback(callback) end
        end
    end)
    Library:GiveSignal(inputChanged); Library:GiveSignal(inputBegan)
    ui.Destroying:Once(function()
        if inputChanged and inputChanged.Connected then inputChanged:Disconnect() end
        if inputBegan and inputBegan.Connected then inputBegan:Disconnect() end
        if changed and changed.Connected then changed:Disconnect() end
        local idx = table.find(Library.Signals, inputChanged); if idx then table.remove(Library.Signals, idx) end
        idx = table.find(Library.Signals, inputBegan); if idx then table.remove(Library.Signals, idx) end
    end)
end

function Library:MakeLine(frame, info)
    return New("Frame", {
        AnchorPoint = info.AnchorPoint or Vector2.zero,
        BackgroundColor3 = "OutlineColor",
        Position = info.Position,
        Size = info.Size,
        ZIndex = info.ZIndex or frame.ZIndex,
        Parent = frame,
    })
end

function Library:AddOutline(frame)
    local stroke = New("UIStroke", { Color = "OutlineColor", Thickness = 1, ZIndex = 2, Parent = frame })
    local shadow = New("UIStroke", { Color = "DarkColor", Thickness = 1.5, ZIndex = 1, Parent = frame })
    return stroke, shadow
end

function Library:AddBlank(frame, size)
    return New("Frame", { BackgroundTransparency = 1, Size = size or UDim2.fromScale(0,0), Parent = frame })
end

-- Icon helpers
local FetchIcons, Icons
do
    local success, res = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua"))()
    end)
    if success then
        FetchIcons = true
        Icons = res
    end
end

function Library:GetIcon(name)
    if not FetchIcons then return nil end
    local success, icon = pcall(Icons.GetAsset, name)
    if not success then return nil end
    return icon
end

function Library:GetCustomIcon(name)
    if not name then return nil end
    if tonumber(name) then name = "rbxassetid://"..tostring(name) end
    if type(name) == "string" and (name:match("^rbxassetid://") or name:match("^content://") or name:match("^rbxasset://%x+/")) then
        return { Url = name, ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero }
    end
    if type(name) == "string" and (name:match("^rbxasset://textures/") or name:match("roblox%.com/asset/%?id=") or name:match("rbxthumb://type=")) then
        return { Url = name, ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero, Custom = true }
    end
    local lucide = Library:GetIcon(name)
    if lucide then return lucide end
    return nil
end

-- Validate
function Library:Validate(tbl, template)
    if type(tbl) ~= "table" then return template end
    for k,v in pairs(template) do
        if type(k) == "number" then continue end
        if type(v) == "table" then
            tbl[k] = Library:Validate(tbl[k], v)
        elseif tbl[k] == nil then
            tbl[k] = v
        end
    end
    return tbl
end

-- Safe callback
function Library:SafeCallback(func, ...)
    if not (func and type(func) == "function") then return end
    local results = table.pack(xpcall(func, function(err)
        task.defer(error, debug.traceback(err, 2))
        if Library.NotifyOnError and Library.Notify then Library:Notify(err) end
        return err
    end, ...))
    if not results[1] then return nil end
    return table.unpack(results, 2, results.n)
end

-- Update search
function Library:UpdateSearch(text)
    Library.SearchText = text
    local tabsToReset = {}
    if Library.GlobalSearch then
        for _, tab in pairs(Library.Tabs) do
            if type(tab) == "table" and not tab.IsKeyTab then table.insert(tabsToReset, tab) end
        end
    elseif Library.LastSearchTab and type(Library.LastSearchTab) == "table" then
        table.insert(tabsToReset, Library.LastSearchTab)
    end
    for _, tab in ipairs(tabsToReset) do
        ResetTab(tab)
    end
    local search = Trim(text):lower()
    if search == "" then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end
    if not Library.GlobalSearch and Library.ActiveTab and Library.ActiveTab.IsKeyTab then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end
    Library.Searching = true
    local tabsToSearch = {}
    if Library.GlobalSearch then
        tabsToSearch = tabsToReset
        if #tabsToSearch == 0 then
            for _, tab in pairs(Library.Tabs) do
                if type(tab) == "table" and not tab.IsKeyTab then table.insert(tabsToSearch, tab) end
            end
        end
    elseif Library.ActiveTab then
        table.insert(tabsToSearch, Library.ActiveTab)
    end
    local firstVisible, activeHasVisible
    for _, tab in ipairs(tabsToSearch) do
        local has = ApplySearchToTab(tab, search)
        if has then
            if not firstVisible then firstVisible = tab end
            if tab == Library.ActiveTab then activeHasVisible = true end
        end
    end
    if Library.GlobalSearch then
        if activeHasVisible and Library.ActiveTab then
            Library.ActiveTab:RefreshSides()
        elseif firstVisible then
            local marker = text
            task.defer(function()
                if Library.SearchText ~= marker then return end
                if Library.ActiveTab ~= firstVisible then firstVisible:Show() end
            end)
        end
        Library.LastSearchTab = nil
    else
        Library.LastSearchTab = Library.ActiveTab
    end
end

-- Dependency Box helpers
function Library:UpdateDependencyBoxes()
    for _, dep in ipairs(Library.DependencyBoxes) do
        dep:Update(true)
    end
    if Library.Searching then Library:UpdateSearch(Library.SearchText) end
end

local function CheckDepbox(box, search)
    local visible = 0
    for _, elem in ipairs(box.Elements) do
        if elem.Type == "Divider" then
            elem.Holder.Visible = false
            continue
        elseif elem.SubButton then
            local vis = false
            if elem.Text:lower():match(search) and elem.Visible then vis = true else elem.Base.Visible = false end
            if elem.SubButton.Text:lower():match(search) and elem.SubButton.Visible then vis = true else elem.SubButton.Base.Visible = false end
            elem.Holder.Visible = vis
            if vis then visible = visible + 1 end
            continue
        end
        if elem.Text and elem.Text:lower():match(search) and elem.Visible then
            elem.Holder.Visible = true
            visible = visible + 1
        else
            elem.Holder.Visible = false
        end
    end
    for _, sub in ipairs(box.DependencyBoxes) do
        if not sub.Visible then continue end
        visible = visible + CheckDepbox(sub, search)
    end
    box.Holder.Visible = visible > 0
    return visible
end

local function RestoreDepbox(box)
    for _, elem in ipairs(box.Elements) do
        elem.Holder.Visible = elem.Visible ~= false
        if elem.SubButton then
            elem.Base.Visible = elem.Visible
            elem.SubButton.Base.Visible = elem.SubButton.Visible
        end
    end
    box:Resize()
    box.Holder.Visible = true
    for _, sub in ipairs(box.DependencyBoxes) do
        if not sub.Visible then continue end
        RestoreDepbox(sub)
    end
end

local function ApplySearchToTab(tab, search)
    if not tab then return false end
    local hasVisible = false
    for _, gb in ipairs(tab.Groupboxes) do
        if gb.Visible == false then continue end
        local visibleElem = 0
        for _, elem in ipairs(gb.Elements) do
            if elem.Type == "Divider" then
                elem.Holder.Visible = false
                continue
            elseif elem.SubButton then
                local vis = false
                if elem.Text:lower():match(search) and elem.Visible then vis = true else elem.Base.Visible = false end
                if elem.SubButton.Text:lower():match(search) and elem.SubButton.Visible then vis = true else elem.SubButton.Base.Visible = false end
                elem.Holder.Visible = vis
                if vis then visibleElem = visibleElem + 1 end
                continue
            end
            if elem.Text and elem.Text:lower():match(search) and elem.Visible then
                elem.Holder.Visible = true
                visibleElem = visibleElem + 1
            else
                elem.Holder.Visible = false
            end
        end
        for _, dep in ipairs(gb.DependencyBoxes) do
            if not dep.Visible then continue end
            visibleElem = visibleElem + CheckDepbox(dep, search)
        end
        if visibleElem > 0 then
            gb:Resize()
            hasVisible = true
        end
        gb.BoxHolder.Visible = visibleElem > 0
    end
    for _, tb in ipairs(tab.Tabboxes) do
        local visibleTabs = 0
        local visibleElems = {}
        for _, subTab in ipairs(tb.Tabs) do
            visibleElems[subTab] = 0
            for _, elem in ipairs(subTab.Elements) do
                if elem.Type == "Divider" then
                    elem.Holder.Visible = false
                    continue
                elseif elem.SubButton then
                    local vis = false
                    if elem.Text:lower():match(search) and elem.Visible then vis = true else elem.Base.Visible = false end
                    if elem.SubButton.Text:lower():match(search) and elem.SubButton.Visible then vis = true else elem.SubButton.Base.Visible = false end
                    elem.Holder.Visible = vis
                    if vis then visibleElems[subTab] = visibleElems[subTab] + 1 end
                    continue
                end
                if elem.Text and elem.Text:lower():match(search) and elem.Visible then
                    elem.Holder.Visible = true
                    visibleElems[subTab] = visibleElems[subTab] + 1
                else
                    elem.Holder.Visible = false
                end
            end
            for _, dep in ipairs(subTab.DependencyBoxes) do
                if not dep.Visible then continue end
                visibleElems[subTab] = visibleElems[subTab] + CheckDepbox(dep, search)
            end
        end
        for sub, vis in pairs(visibleElems) do
            sub.ButtonHolder.Visible = vis > 0
            if vis > 0 then
                visibleTabs = visibleTabs + 1
                hasVisible = true
                if tb.ActiveTab == sub then
                    sub:Resize()
                elseif tb.ActiveTab and visibleElems[tb.ActiveTab] == 0 then
                    sub:Show()
                end
            end
        end
        tb.BoxHolder.Visible = visibleTabs > 0
    end
    return hasVisible
end

local function ResetTab(tab)
    if not tab then return end
    for _, gb in ipairs(tab.Groupboxes) do
        for _, elem in ipairs(gb.Elements) do
            elem.Holder.Visible = elem.Visible ~= false
            if elem.SubButton then
                elem.Base.Visible = elem.Visible
                elem.SubButton.Base.Visible = elem.SubButton.Visible
            end
        end
        for _, dep in ipairs(gb.DependencyBoxes) do
            if not dep.Visible then continue end
            RestoreDepbox(dep)
        end
        gb:Resize()
        gb.BoxHolder.Visible = gb.Visible ~= false
    end
    for _, tb in ipairs(tab.Tabboxes) do
        for _, sub in ipairs(tb.Tabs) do
            for _, elem in ipairs(sub.Elements) do
                elem.Holder.Visible = elem.Visible ~= false
                if elem.SubButton then
                    elem.Base.Visible = elem.Visible
                    elem.SubButton.Base.Visible = elem.SubButton.Visible
                end
            end
            for _, dep in ipairs(sub.DependencyBoxes) do
                if not dep.Visible then continue end
                RestoreDepbox(dep)
            end
            sub.ButtonHolder.Visible = true
        end
        if tb.ActiveTab then tb.ActiveTab:Resize() end
        tb.BoxHolder.Visible = true
    end
end

-- Tab animation
local ActiveTabTweens = setmetatable({}, { __mode = "k" })
function Library:PlayTabAnimation(canvas, showing, onComplete)
    if not canvas then if onComplete then onComplete() end return end
    local existing = ActiveTabTweens[canvas]
    if existing then StopTween(existing, true); ActiveTabTweens[canvas] = nil end
    local baseZ = canvas.ZIndex
    if not (Library.Animations and Library.Animations.TabSwitch) then
        canvas.Visible = showing
        canvas.GroupTransparency = showing and 0 or 1
        canvas.Position = UDim2.fromScale(0,0)
        canvas.ZIndex = baseZ
        if onComplete then onComplete() end
        return
    end
    if showing then
        local tweenInfo = Library.TabTransitionInfo
        local offset = Library.TabSwipeOffset
        local from = string.lower(Library.TabSwipeFrom)
        local startPos
        if from == "left" then startPos = UDim2.fromOffset(-offset, 0)
        elseif from == "top" then startPos = UDim2.fromOffset(0, -offset)
        elseif from == "right" then startPos = UDim2.fromOffset(offset, 0)
        else startPos = UDim2.fromOffset(0, offset) end
        canvas.ZIndex = baseZ + 1
        canvas.GroupTransparency = 1
        canvas.Position = startPos
        canvas.Visible = true
        local tw = TweenService:Create(canvas, tweenInfo, { GroupTransparency = 0, Position = UDim2.fromScale(0,0) })
        ActiveTabTweens[canvas] = tw
        tw:Play()
        local conn = tw.Completed:Connect(function()
            if conn then conn:Disconnect() end
            if ActiveTabTweens[canvas] == tw then ActiveTabTweens[canvas] = nil end
            canvas.ZIndex = baseZ
            if onComplete then onComplete() end
        end)
    else
        canvas.GroupTransparency = 1
        canvas.Visible = false
        canvas.Position = UDim2.fromScale(0,0)
        canvas.ZIndex = baseZ
        if onComplete then onComplete() end
    end
end

-- Watermark (Draggable Label)
function Library:AddDraggableLabel(...)
    local params = select(1, ...)
    local text, icon, iconPos
    if type(params) == "table" then
        text = params.Text
        icon = params.Icon
        iconPos = params.IconPosition or "left"
    else
        text = params
        icon = select(2, ...)
        iconPos = select(3, ...) or "left"
    end
    iconPos = iconPos:lower()
    assert(iconPos == "left" or iconPos == "right", "Icon position must be left or right")

    local label = { Connections = {}, Destroyed = false }
    local iconImage
    local lbl = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "BackgroundColor",
        Size = UDim2.fromOffset(0,0),
        Position = UDim2.fromOffset(6,6),
        Text = text,
        TextSize = 15,
        ZIndex = 10,
        Parent = ScreenGui,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = lbl }))
    local pad = New("UIPadding", { PaddingBottom = UDim.new(0,6), PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12), PaddingTop = UDim.new(0,6), Parent = lbl })
    table.insert(Library.Scales, New("UIScale", { Parent = lbl }))
    Library:AddOutline(lbl)
    Library:MakeDraggable(lbl, lbl, true)

    function label:SetText(t)
        lbl.Text = t
    end

    function label:SetIcon(newIcon)
        icon = newIcon
        local isNotEmpty = icon and Trim(tostring(icon)) ~= ""
        if isNotEmpty then
            local custom = Library:GetCustomIcon(icon)
            assert(custom, "Invalid icon")
            iconImage = iconImage or New("ImageLabel", {
                BackgroundTransparency = 1,
                ImageColor3 = "FontColor",
                Size = UDim2.fromOffset(16,16),
                ZIndex = 11,
                Parent = lbl,
            })
            iconImage.Image = custom.Url
            iconImage.ImageRectOffset = custom.ImageRectOffset
            iconImage.ImageRectSize = custom.ImageRectSize
        end
        if iconImage then iconImage.Visible = isNotEmpty end
        label:SetIconPosition(iconPos)
    end

    function label:SetIconPosition(pos)
        iconPos = pos:lower()
        assert(iconPos == "left" or iconPos == "right")
        local isNotEmpty = icon and Trim(tostring(icon)) ~= ""
        pad.PaddingLeft = UDim.new(0, (isNotEmpty and iconPos == "left") and 34 or 12)
        pad.PaddingRight = UDim.new(0, (isNotEmpty and iconPos == "right") and 34 or 12)
        if iconImage then
            if iconPos == "left" then
                iconImage.AnchorPoint = Vector2.new(0,0.5)
                iconImage.Position = UDim2.new(0,-22,0.5,0)
            else
                iconImage.AnchorPoint = Vector2.new(1,0.5)
                iconImage.Position = UDim2.new(1,22,0.5,0)
            end
        end
    end

    function label:SetVisible(v)
        lbl.Visible = v
    end

    label:SetIcon(icon)
    label.Label = lbl
    if not table.find(Library.DraggableElements, lbl) then table.insert(Library.DraggableElements, lbl) end
    PositionDraggable(lbl, lbl.Position)

    function label:Destroy()
        label.Destroyed = true
        for _, conn in label.Connections do conn:Disconnect() end
        local idx = table.find(Library.DraggableElements, lbl)
        if idx then table.remove(Library.DraggableElements, idx) end
        if lbl then lbl:Destroy() end
    end
    return label
end

-- PositionDraggable helper
local function GetOverlappingDraggable(ui, targetPos)
    local p1 = targetPos or ui.AbsolutePosition
    local s1 = ui.AbsoluteSize
    for _, other in ipairs(Library.DraggableElements) do
        if other == ui or not other.Visible or not other.Parent then continue end
        local p2 = other.AbsolutePosition
        local s2 = other.AbsoluteSize
        if p1.X < p2.X + s2.X and p1.X + s1.X > p2.X and p1.Y < p2.Y + s2.Y and p1.Y + s1.Y > p2.Y then
            return other
        end
    end
    return nil
end

local function GetNonOverlappingPosition(ui, startPos)
    local screenSize = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)) - Vector2.new(100,100)
    local start = startPos and Vector2.new(startPos.X.Offset, startPos.Y.Offset) or Vector2.new(6,6)
    local padding = 6
    local curX, curY = start.X, start.Y
    local size = ui.AbsoluteSize
    if size.X == 0 and size.Y == 0 then RunService.RenderStepped:Wait(); size = ui.AbsoluteSize end
    if size.X == 0 then size = Vector2.new(150,40) end
    local maxXInCol = size.X
    while true do
        local obstacle = GetOverlappingDraggable(ui, Vector2.new(curX, curY))
        if not obstacle then break end
        if obstacle.AbsoluteSize.X > maxXInCol then maxXInCol = obstacle.AbsoluteSize.X end
        local nextY = obstacle.AbsolutePosition.Y + obstacle.AbsoluteSize.Y + padding
        if nextY + size.Y > screenSize.Y - padding then
            local nextX = curX + maxXInCol + padding
            if nextX + size.X > screenSize.X - padding then break end
            curY = start.Y
            curX = nextX
            maxXInCol = size.X
        else
            curY = nextY
        end
    end
    return UDim2.fromOffset(curX, curY)
end

function PositionDraggable(ui, startPos)
    ui.Position = GetNonOverlappingPosition(ui, startPos)
end

-- Keybinds frame
Library.KeybindFrame, Library.KeybindContainer = Library:AddDraggableMenu("Keybinds")
Library.KeybindFrame.AnchorPoint = Vector2.new(0,0.5)
Library.KeybindFrame.Position = UDim2.new(0,6,0.5,0)
Library.KeybindFrame.Visible = false

-- Base Addons (KeyPicker, ColorPicker)
local BaseAddons = {}
do
    local hueSequence = {}
    for h=0,1,0.1 do table.insert(hueSequence, ColorSequenceKeypoint.new(h, Color3.fromHSV(h,1,1))) end

    function BaseAddons:AddKeyPicker(idx, info)
        if self.Destroyed then return nil end
        info = Library:Validate(info, Templates.KeyPicker)
        local parent = self
        local label = parent.TextLabel
        if parent.Type == "Button" or parent.Type == "SubButton" then
            assert(info.Mode == "Press", "KeyPicker on buttons only supports 'Press' mode")
            label = parent.Base
        end

        local picker = {
            Connections = {},
            Text = info.Text,
            Value = info.Default,
            Modifiers = info.DefaultModifiers,
            DisplayValue = info.Default,
            Blacklisted = info.Blacklisted,
            BlacklistedModifiers = info.BlacklistedModifiers,
            Whitelisted = info.Whitelisted,
            WhitelistedModifiers = info.WhitelistedModifiers,
            Toggled = false,
            Mode = info.Mode,
            SyncToggleState = info.SyncToggleState,
            Callback = info.Callback,
            ChangedCallback = info.ChangedCallback,
            Changed = info.Changed,
            Clicked = info.Clicked,
            Type = "KeyPicker",
        }
        if picker.Mode == "Press" then
            assert(parent.Type == "Label" or parent.Type == "Button" or parent.Type == "SubButton")
            picker.SyncToggleState = false
            info.Modes = {"Press"}
            info.Mode = "Press"
        end
        if picker.SyncToggleState then
            info.Modes = {"Toggle", "Hold"}
            if not table.find(info.Modes, info.Mode) then info.Mode = "Toggle" end
        end

        local picking = false
        local isForButton = parent.Type == "Button" or parent.Type == "SubButton"

        local SpecialKeys = { MB1 = Enum.UserInputType.MouseButton1, MB2 = Enum.UserInputType.MouseButton2, MB3 = Enum.UserInputType.MouseButton3 }
        local SpecialKeysInput = { [Enum.UserInputType.MouseButton1] = "MB1", [Enum.UserInputType.MouseButton2] = "MB2", [Enum.UserInputType.MouseButton3] = "MB3" }
        local Modifiers = { LAlt = Enum.KeyCode.LeftAlt, RAlt = Enum.KeyCode.RightAlt, LCtrl = Enum.KeyCode.LeftControl, RCtrl = Enum.KeyCode.RightControl, LShift = Enum.KeyCode.LeftShift, RShift = Enum.KeyCode.RightShift, Tab = Enum.KeyCode.Tab, CapsLock = Enum.KeyCode.CapsLock }
        local ModifiersInput = {}
        for k,v in pairs(Modifiers) do ModifiersInput[v] = k end

        local function IsModifierInput(input)
            return input.UserInputType == Enum.UserInputType.Keyboard and ModifiersInput[input.KeyCode] ~= nil
        end

        local function GetActiveModifiers()
            local active = {}
            for name, code in pairs(Modifiers) do
                if table.find(active, name) then continue end
                if UserInputService:IsKeyDown(code) then table.insert(active, name) end
            end
            return active
        end

        local function AreModifiersHeld(required)
            if type(required) ~= "table" or #required == 0 then return true end
            local active = GetActiveModifiers()
            for _, name in ipairs(required) do
                if not table.find(active, name) then return false end
            end
            return true
        end

        local function IsInputDown(input)
            if not input then return false end
            if SpecialKeysInput[input.UserInputType] then
                return UserInputService:IsMouseButtonPressed(input.UserInputType) and not UserInputService:GetFocusedTextBox()
            elseif input.UserInputType == Enum.UserInputType.Keyboard then
                return UserInputService:IsKeyDown(input.KeyCode) and not UserInputService:GetFocusedTextBox()
            else
                return false
            end
        end

        local function ConvertToInputModifiers(mods)
            local res = {}
            for _, name in ipairs(mods) do
                if Modifiers[name] then table.insert(res, Modifiers[name]) end
            end
            return res
        end

        local function VerifyModifiers(mods)
            if type(mods) ~= "table" then return {} end
            local valid = {}
            for _, name in ipairs(mods) do
                if Modifiers[name] then table.insert(valid, name) end
            end
            return valid
        end
        picker.Modifiers = VerifyModifiers(picker.Modifiers)

        local slideOverflow = true
        local maxPickerWidth = 75
        local slidingLabel
        local lastPickerWidth = 0
        local slideForward, slideBack
        local function CancelSlides()
            if slideForward then StopTween(slideForward, true); slideForward = nil end
            if slideBack then StopTween(slideBack, true); slideBack = nil end
        end

        local pickerBtn = New("TextButton", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromOffset(18,18),
            Text = (isForButton and slideOverflow) and "" or picker.Value,
            TextSize = 14,
            Parent = label,
        })
        if isForButton and slideOverflow then
            pickerBtn.ClipsDescendants = true
            slidingLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1,0,1,0),
                Position = UDim2.new(0,0,0,0),
                Text = picker.Value,
                TextSize = 14,
                FontFace = pickerBtn.FontFace,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = pickerBtn,
            })
            Library:AddToRegistry(slidingLabel, { TextColor3 = "FontColor" })
        end
        New("UIStroke", { Color = "OutlineColor", Parent = pickerBtn })
        local corner = New("UICorner", { TopLeftRadius = UDim.new(0,Library.CornerRadius/2), TopRightRadius = UDim.new(0,Library.CornerRadius/2), BottomRightRadius = UDim.new(0,Library.CornerRadius/2), BottomLeftRadius = UDim.new(0,Library.CornerRadius/2), Parent = pickerBtn })
        table.insert(Library.SpecificCorners, corner)

        if isForButton then
            local holder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,21), Parent = label.Parent })
            New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalFlex = Enum.UIFlexAlignment.Fill, Padding = UDim.new(0,9), Parent = holder })
            label.Parent = holder
            pickerBtn.Parent = holder
            pickerBtn.Size = UDim2.new(0,18,1,0)
        end

        local keybindToggle = { Normal = picker.Mode ~= "Toggle" }
        do
            local holder = New("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1,0,0,16),
                Text = "",
                Visible = not info.NoUI,
                Parent = Library.KeybindContainer,
            })
            local lbl = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(0,1),
                Text = "",
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = holder,
            })
            local checkbox = New("Frame", {
                AnchorPoint = Vector2.new(0,0.5),
                BackgroundColor3 = "MainColor",
                Position = UDim2.fromScale(0,0.5),
                Size = UDim2.fromOffset(14,14),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = holder,
            })
            table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0,Library.CornerRadius/2), Parent = checkbox }))
            New("UIStroke", { Color = "OutlineColor", Parent = checkbox })
            local checkImg = New("ImageLabel", {
                Image = CustomImageManager:GetAsset("CheckIcon"),
                ImageColor3 = "FontColor",
                ImageTransparency = 1,
                Position = UDim2.fromOffset(2,2),
                Size = UDim2.new(1,-4,1,-4),
                Parent = checkbox,
            })
            function keybindToggle:Display(state)
                lbl.TextTransparency = state and 0 or 0.5
                checkImg.ImageTransparency = state and 0 or 1
            end
            function keybindToggle:SetText(t)
                lbl.Text = t
            end
            function keybindToggle:SetVisibility(v)
                holder.Visible = v
            end
            function keybindToggle:SetNormal(normal)
                keybindToggle.Normal = normal
                holder.Active = not normal
                lbl.Position = normal and UDim2.fromOffset(0,0) or UDim2.fromOffset(22,0)
                checkbox.Visible = not normal
            end
            picker.DoClick = function() end
            holder.MouseButton1Click:Connect(function()
                if keybindToggle.Normal then return end
                picker.Toggled = not picker.Toggled
                picker:DoClick()
            end)
            keybindToggle.Holder = holder
            keybindToggle.Label = lbl
            keybindToggle.Checkbox = checkbox
            keybindToggle.Loaded = true
            table.insert(Library.KeybindToggles, keybindToggle)
        end

        local modeButtons = {}
        local totalModes = TableSize(info.Modes)
        local menu = Library:AddContextMenu(pickerBtn, UDim2.fromOffset(62,0), function()
            return { pickerBtn.AbsoluteSize.X + 1.5, 0.5 }
        end, 1, function(active)
            corner.TopRightRadius = active and UDim.new(0,0) or UDim.new(0,Library.CornerRadius/2)
            corner.BottomRightRadius = active and UDim.new(0,0) or UDim.new(0,Library.CornerRadius/2)
        end, false, totalModes == 1 and "no_left" or "no_top_left", "KeyPicker")
        picker.Menu = menu

        for i, mode in ipairs(info.Modes) do
            local btn = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1,0,0,isForButton and 21 or (totalModes==1 and 18 or 19)),
                Text = mode,
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = menu.Menu,
            })
            if i == 1 and totalModes == 1 then
                table.insert(Library.SpecificCorners, New("UICorner", { TopLeftRadius = UDim.new(0,0), TopRightRadius = UDim.new(0,Library.CornerRadius/2), BottomLeftRadius = UDim.new(0,0), BottomRightRadius = UDim.new(0,Library.CornerRadius/2), Parent = btn }))
            elseif i == 1 then
                table.insert(Library.SpecificCorners, New("UICorner", { TopLeftRadius = UDim.new(0,0), TopRightRadius = UDim.new(0,Library.CornerRadius/2), BottomLeftRadius = UDim.new(0,0), BottomRightRadius = UDim.new(0,0), Parent = btn }))
            elseif i == totalModes then
                table.insert(Library.SpecificCorners, New("UICorner", { TopLeftRadius = UDim.new(0,0), TopRightRadius = UDim.new(0,0), BottomLeftRadius = UDim.new(0,Library.CornerRadius/2), BottomRightRadius = UDim.new(0,Library.CornerRadius/2), Parent = btn }))
            end
            local mt = { Select = function()
                for _, b in pairs(modeButtons) do b:Deselect() end
                picker.Mode = mode
                btn.BackgroundTransparency = 0
                btn.TextTransparency = 0
                menu:Close()
            end, Deselect = function()
                picker.Mode = nil
                btn.BackgroundTransparency = 1
                btn.TextTransparency = 0.5
            end }
            btn.MouseButton1Click:Connect(mt.Select)
            if picker.Mode == mode then mt:Select() end
            modeButtons[mode] = mt
        end

        function picker:Display(pickerText)
            if Library.Unloaded then return end
            local display = pickerText or picker.DisplayValue
            if isForButton and slideOverflow then
                if lastPickerWidth == pickerBtn.AbsoluteSize.X then return end
                local x,_ = Library:GetTextBounds(display, pickerBtn.FontFace, pickerBtn.TextSize, 10000)
                slidingLabel.Text = display
                local offsetScale = x + 9
                local w = math.min(offsetScale, maxPickerWidth)
                pickerBtn.Size = UDim2.new(0,w,1,0)
                if offsetScale > w then
                    slidingLabel.TextXAlignment = Enum.TextXAlignment.Left
                    slidingLabel.Size = UDim2.new(0,offsetScale,1,0)
                    slidingLabel.Position = UDim2.fromOffset(4.5,0)
                    RunService.RenderStepped:Wait()
                    local realW = pickerBtn.AbsoluteSize.X
                    if realW <= 0 then realW = w end
                    lastPickerWidth = realW
                    local overflow = offsetScale - realW - 4.5
                    if overflow > 0 then
                        CancelSlides()
                        local dur = overflow / 25
                        local ti = TweenInfo.new(dur, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
                        slideForward = TweenService:Create(slidingLabel, ti, { Position = UDim2.fromOffset(-overflow,0) })
                        slideBack = TweenService:Create(slidingLabel, ti, { Position = UDim2.fromOffset(4.5,0) })
                        slideForward:Play()
                        slideForward.Completed:Connect(function() task.wait(1.5); if slideBack then slideBack:Play() end end)
                        slideBack.Completed:Connect(function() task.wait(1.5); if slideForward then slideForward:Play() end end)
                    else
                        CancelSlides()
                        slidingLabel.TextXAlignment = Enum.TextXAlignment.Center
                        slidingLabel.Size = UDim2.new(1,0,1,0)
                        slidingLabel.Position = UDim2.new(0,0,0,0)
                    end
                else
                    CancelSlides()
                    slidingLabel.TextXAlignment = Enum.TextXAlignment.Center
                    slidingLabel.Size = UDim2.new(1,0,1,0)
                    slidingLabel.Position = UDim2.new(0,0,0,0)
                end
            else
                local x,y = Library:GetTextBounds(display, pickerBtn.FontFace, pickerBtn.TextSize, label.AbsoluteSize.X)
                pickerBtn.Text = display
                pickerBtn.Size = isForButton and UDim2.new(0,x+9,1,0) or UDim2.fromOffset(x+9, y+4)
            end
        end

        function picker:Update()
            picker:Display()
            if info.NoUI then return end
            if picker.Mode == "Toggle" and parent.Type == "Toggle" and parent.Disabled then
                keybindToggle:SetVisibility(false)
                return
            end
            local state = picker:GetState()
            local show = Library.ShowToggleFrameInKeybinds and picker.Mode == "Toggle"
            if picker.SyncToggleState and parent.Value ~= state then parent:SetValue(state) end
            if keybindToggle.Loaded then
                if show then keybindToggle:SetNormal(false) else keybindToggle:SetNormal(true) end
                keybindToggle:SetText(("[%s] %s (%s)"):format(picker.DisplayValue, picker.Text, picker.Mode))
                keybindToggle:SetVisibility(true)
                keybindToggle:Display(state)
            end
        end

        function picker:GetState()
            if picker.Mode == "Always" then return true
            elseif picker.Mode == "Hold" then
                local key = picker.Value
                if key == "None" then return false end
                if not AreModifiersHeld(picker.Modifiers) then return false end
                if picking then return false end
                if SpecialKeys[key] then
                    if Library.Toggled then return false end
                    return UserInputService:IsMouseButtonPressed(SpecialKeys[key]) and not UserInputService:GetFocusedTextBox()
                else
                    return UserInputService:IsKeyDown(Enum.KeyCode[key]) and not UserInputService:GetFocusedTextBox()
                end
            else
                return picker.Toggled
            end
        end

        function picker:OnChanged(f) picker.Changed = f end
        function picker:OnClick(f) picker.Clicked = f end

        function picker:DoClick()
            if picking then return end
            if picker.Mode == "Press" then
                if picker.Toggled and info.WaitForCallback == true then return end
                picker.Toggled = true
            end
            Library:SafeCallback(picker.Callback, picker.Toggled)
            Library:SafeCallback(picker.Clicked, picker.Toggled)
            if isForButton then Library:SafeCallback(parent.Func, picker.Toggled) end
            if Library.ToggleKeybind == picker and Library.Toggle then Library:Toggle() end
            if picker.Mode == "Press" then picker.Toggled = false end
        end

        function picker:RunChanged(isValid, keyCode)
            if isValid == nil and keyCode == nil then
                isValid, keyCode = pcall(function()
                    if picker.Value == "None" then return nil end
                    if SpecialKeys[picker.Value] == nil then return Enum.KeyCode[picker.Value] end
                    return SpecialKeys[picker.Value]
                end)
            end
            local mods = ConvertToInputModifiers(picker.Modifiers)
            Library:SafeCallback(picker.ChangedCallback, keyCode, mods)
            Library:SafeCallback(picker.Changed, keyCode, mods)
        end

        function picker:SetValue(data)
            local key, mode, mods = data[1], data[2], data[3]
            local isValid, keyCode = pcall(function()
                if key == "None" then key = nil; return nil end
                if SpecialKeys[key] == nil then return Enum.KeyCode[key] end
                return SpecialKeys[key]
            end)
            if key == nil then picker.Value = "None"
            elseif isValid then picker.Value = key
            else picker.Value = "Unknown" end
            picker.Modifiers = VerifyModifiers(type(mods) == "table" and mods or picker.Modifiers)
            picker.DisplayValue = #picker.Modifiers > 0 and (table.concat(picker.Modifiers, " + ") .. " + " .. picker.Value) or picker.Value
            if modeButtons[mode] then modeButtons[mode]:Select() end
            picker:Update()
            picker:RunChanged(isValid, keyCode)
        end

        function picker:SetText(t)
            keybindToggle:SetText(t)
            picker:Update()
        end

        local function SetPickingState(state)
            picking = state
            Library.IsPicking = state
            if parent then parent.AnyKeyPickerPicking = picking end
            if isForButton then
                label.Visible = not picking
                RunService.RenderStepped:Wait()
            end
            picker:Update()
        end

        pickerBtn.MouseButton1Click:Connect(function()
            if picking or Library.IsPicking then return end
            SetPickingState(true)
            if isForButton and slideOverflow then picker:Display("...")
            else pickerBtn.Text = "..."; pickerBtn.Size = isForButton and UDim2.new(0,29,1,0) or UDim2.fromOffset(29,18) end

            local activeMods = {}
            local currentInput = nil
            local function IsValidInput(input)
                if input.KeyCode == Enum.KeyCode.Escape then return true end
                local isMod = IsModifierInput(input)
                local keyName
                if SpecialKeysInput[input.UserInputType] then
                    keyName = SpecialKeysInput[input.UserInputType]
                elseif input.UserInputType == Enum.UserInputType.Keyboard then
                    if isMod then keyName = ModifiersInput[input.KeyCode] else keyName = input.KeyCode.Name end
                end
                if keyName then
                    if isMod then
                        if picker.WhitelistedModifiers and #picker.WhitelistedModifiers > 0 and not table.find(picker.WhitelistedModifiers, keyName) then return false end
                        if picker.BlacklistedModifiers and table.find(picker.BlacklistedModifiers, keyName) then return false end
                    else
                        if picker.Whitelisted and #picker.Whitelisted > 0 and not table.find(picker.Whitelisted, keyName) then return false end
                        if picker.Blacklisted and table.find(picker.Blacklisted, keyName) then return false end
                    end
                end
                return true
            end

            while true do
                local input = UserInputService.InputBegan:Wait()
                if UserInputService:GetFocusedTextBox() then SetPickingState(false); return end
                if IsValidInput(input) then currentInput = input; break end
            end

            while IsModifierInput(currentInput) do
                if currentInput.KeyCode == Enum.KeyCode.Escape then break end
                local modName = ModifiersInput[currentInput.KeyCode]
                if modName then
                    local text = #activeMods > 0 and table.concat(activeMods, " + ") .. " + " .. modName .. " + ..." or modName .. " + ..."
                    picker:Display(text)
                end
                local nextInput = nil
                local released = false
                local beganConn, endedConn
                beganConn = UserInputService.InputBegan:Connect(function(input)
                    if UserInputService:GetFocusedTextBox() then return end
                    if IsValidInput(input) then nextInput = input end
                end)
                endedConn = UserInputService.InputEnded:Connect(function(input)
                    if input.KeyCode == currentInput.KeyCode then released = true end
                end)
                repeat task.wait() until released or nextInput or UserInputService:GetFocusedTextBox() or Library.Unloaded
                if beganConn then beganConn:Disconnect() end
                if endedConn then endedConn:Disconnect() end
                if UserInputService:GetFocusedTextBox() or Library.Unloaded then SetPickingState(false); return end
                if released then break
                elseif nextInput then
                    local old = ModifiersInput[currentInput.KeyCode]
                    if old and not table.find(activeMods, old) then table.insert(activeMods, old) end
                    currentInput = nextInput
                    if currentInput.KeyCode == Enum.KeyCode.Escape then break end
                end
            end

            local key = "Unknown"
            if SpecialKeysInput[currentInput.UserInputType] then
                key = SpecialKeysInput[currentInput.UserInputType]
            elseif currentInput.UserInputType == Enum.UserInputType.Keyboard then
                key = currentInput.KeyCode == Enum.KeyCode.Escape and "None" or currentInput.KeyCode.Name
            end
            activeMods = (currentInput.KeyCode == Enum.KeyCode.Escape or key == "Unknown") and {} or activeMods
            picker.Toggled = parent.Type == "Toggle" and parent.Value or false
            picker:SetValue({key, picker.Mode, activeMods})
            repeat task.wait() until not IsInputDown(currentInput) or UserInputService:GetFocusedTextBox()
            SetPickingState(false)
        end)
        pickerBtn.MouseButton2Click:Connect(menu.Toggle)

        table.insert(picker.Connections, UserInputService.InputBegan:Connect(function(input)
            if Library.Unloaded then return end
            local isMouse = IsMouseClickInput(input)
            if picker.Mode == "Always" or picker.Value == "Unknown" or picker.Value == "None" or picking or Library.IsPicking or UserInputService:GetFocusedTextBox() or (isMouse and Library.Toggled) then return end
            local key = picker.Value
            if key and AreModifiersHeld(picker.Modifiers) and (SpecialKeysInput[input.UserInputType] == key or (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == key)) then
                if picker.Mode == "Toggle" then
                    picker.Toggled = not picker.Toggled
                    picker:DoClick()
                elseif picker.Mode == "Press" then
                    picker:DoClick()
                end
            end
            picker:Update()
        end))
        table.insert(picker.Connections, UserInputService.InputEnded:Connect(function(input)
            if Library.Unloaded then return end
            local isMouse = IsMouseClickInput(input)
            if picker.Value == "Unknown" or picker.Value == "None" or picking or Library.IsPicking or UserInputService:GetFocusedTextBox() or (isMouse and Library.Toggled) then return end
            picker:Update()
        end))

        picker:Update()
        if parent.Addons then table.insert(parent.Addons, picker) end
        picker.Default = picker.Value
        picker.DefaultModifiers = table.clone(picker.Modifiers or {})

        function picker:Destroy()
            picker.Destroyed = true
            for _, conn in ipairs(picker.Connections) do conn:Disconnect() end
            if keybindToggle and keybindToggle.Loaded then
                if keybindToggle.Holder then keybindToggle.Holder:Destroy() end
                local idx = table.find(Library.KeybindToggles, keybindToggle)
                if idx then table.remove(Library.KeybindToggles, idx) end
            end
            if menu then menu:Destroy() end
            if isForButton and slideOverflow then
                if slideForward then slideForward:Destroy() end
                if slideBack then slideBack:Destroy() end
            end
            if pickerBtn then pickerBtn:Destroy() end
            if parent and parent.Addons then
                local idx = table.find(parent.Addons, picker)
                if idx then table.remove(parent.Addons, idx) end
            end
            Options[idx] = nil
        end
        Options[idx] = picker
        return self
    end

    function BaseAddons:AddColorPicker(idx, info)
        if self.Destroyed then return nil end
        info = Library:Validate(info, Templates.ColorPicker)
        local parent = self
        local label = parent.TextLabel

        local picker = {
            Connections = {},
            Destroyed = false,
            Value = info.Default,
            Transparency = info.Transparency or 0,
            Title = info.Title,
            Callback = info.Callback,
            Changed = info.Changed,
            Type = "ColorPicker",
        }
        picker.Hue, picker.Sat, picker.Vib = picker.Value:ToHSV()

        local holder = New("TextButton", {
            BackgroundColor3 = picker.Value,
            Size = UDim2.fromOffset(18,18),
            Text = "",
            Parent = label,
        })
        local holderStroke = New("UIStroke", { Color = Library:GetDarkerColor(picker.Value), Parent = holder })
        local corner = New("UICorner", { TopLeftRadius = UDim.new(0,Library.CornerRadius/2), TopRightRadius = UDim.new(0,Library.CornerRadius/2), BottomRightRadius = UDim.new(0,Library.CornerRadius/2), BottomLeftRadius = UDim.new(0,Library.CornerRadius/2), Parent = holder })
        table.insert(Library.SpecificCorners, corner)
        local holderTrans = New("ImageLabel", {
            Image = CustomImageManager:GetAsset("TransparencyTexture"),
            ImageTransparency = 1 - picker.Transparency,
            ScaleType = Enum.ScaleType.Tile,
            Position = UDim2.new(0,-1,0,-1),
            Size = UDim2.new(1,2,1,2),
            TileSize = UDim2.fromOffset(9,9),
            Parent = holder,
        })
        table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0,Library.CornerRadius/2), Parent = holderTrans }))

        local colorMenu = Library:AddContextMenu(holder, UDim2.fromOffset(info.Transparency and 256 or 234,0), function()
            return { 0.5, holder.AbsoluteSize.Y + 1.5 }
        end, 1, function(active)
            corner.BottomRightRadius = active and UDim.new(0,0) or UDim.new(0,Library.CornerRadius/2)
            corner.BottomLeftRadius = active and UDim.new(0,0) or UDim.new(0,Library.CornerRadius/2)
        end, false, "no_top_left")
        colorMenu.List.Padding = UDim.new(0,8)
        picker.ColorMenu = colorMenu
        New("UIPadding", { PaddingBottom = UDim.new(0,6), PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6), PaddingTop = UDim.new(0,6), Parent = colorMenu.Menu })

        if type(picker.Title) == "string" then
            New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,8), Text = picker.Title, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = colorMenu.Menu })
        end

        local colorHolder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,200), Parent = colorMenu.Menu })
        New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,6), Parent = colorHolder })

        local satMap = New("ImageButton", {
            BackgroundColor3 = picker.Value,
            Image = CustomImageManager:GetAsset("SaturationMap"),
            Size = UDim2.fromOffset(200,200),
            Parent = colorHolder,
        })
        local satCursor = New("Frame", { AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = "WhiteColor", Size = UDim2.fromOffset(6,6), Parent = satMap })
        New("UICorner", { CornerRadius = UDim.new(1,0), Parent = satCursor })
        New("UIStroke", { Color = "DarkColor", Parent = satCursor })

        local hueSelector = New("TextButton", { Size = UDim2.fromOffset(16,200), Text = "", Parent = colorHolder })
        New("UIGradient", { Color = ColorSequence.new(hueSequence), Rotation = 90, Parent = hueSelector })
        local hueCursor = New("Frame", { AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = "WhiteColor", BorderColor3 = "DarkColor", BorderSizePixel = 1, Position = UDim2.fromScale(0.5, picker.Hue), Size = UDim2.new(1,2,0,1), Parent = hueSelector })

        local transSelector, transColor, transCursor
        if info.Transparency then
            transSelector = New("ImageButton", {
                Image = CustomImageManager:GetAsset("TransparencyTexture"),
                ScaleType = Enum.ScaleType.Tile,
                Size = UDim2.fromOffset(16,200),
                TileSize = UDim2.fromOffset(8,8),
                Parent = colorHolder,
            })
            transColor = New("Frame", { BackgroundColor3 = picker.Value, Size = UDim2.fromScale(1,1), Parent = transSelector })
            New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)}), Parent = transColor })
            transCursor = New("Frame", { AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = "WhiteColor", BorderColor3 = "DarkColor", BorderSizePixel = 1, Position = UDim2.fromScale(0.5, picker.Transparency), Size = UDim2.new(1,2,0,1), Parent = transSelector })
        end

        local infoHolder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,20), Parent = colorMenu.Menu })
        New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalFlex = Enum.UIFlexAlignment.Fill, Padding = UDim.new(0,8), Parent = infoHolder })

        local hueBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1,1),
            Text = "#??????",
            TextSize = 14,
            Parent = infoHolder,
        })
        New("UIStroke", { Color = "OutlineColor", Parent = hueBox })
        table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0,Library.CornerRadius/2), Parent = hueBox }))

        local rgbBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1,1),
            Text = "?, ?, ?",
            TextSize = 14,
            Parent = infoHolder,
        })
        New("UIStroke", { Color = "OutlineColor", Parent = rgbBox })
        table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0,Library.CornerRadius/2), Parent = rgbBox }))

        local contextMenu = Library:AddContextMenu(holder, UDim2.fromOffset(93,0), function()
            return { holder.AbsoluteSize.X + 1.5, 0.5 }
        end, 1, function(active)
            corner.TopRightRadius = active and UDim.new(0,0) or UDim.new(0,Library.CornerRadius/2)
            corner.BottomRightRadius = active and UDim.new(0,0) or UDim.new(0,Library.CornerRadius/2)
        end, false, "no_top_left")
        picker.ContextMenu = contextMenu
        contextMenu.List.Padding = UDim.new(0,6)
        do
            local function CreateButton(text, func)
                local btn = New("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,21), Text = text, TextSize = 14, Parent = contextMenu.Menu })
                btn.MouseButton1Click:Connect(function() Library:SafeCallback(func); contextMenu:Close() end)
            end
            CreateButton("Copy color", function() Library.CopiedColor = { picker.Value, picker.Transparency } end)
            picker.SetValueRGB = function() end
            CreateButton("Paste color", function() picker:SetValueRGB(Library.CopiedColor[1], Library.CopiedColor[2]) end)
            if setclipboard then
                CreateButton("Copy Hex", function() setclipboard(tostring(picker.Value:ToHex())) end)
                CreateButton("Copy RGB", function() setclipboard(table.concat({math.floor(picker.Value.R*255), math.floor(picker.Value.G*255), math.floor(picker.Value.B*255)}, ", ")) end)
            end
        end

        function picker:SetHSVFromRGB(color)
            picker.Hue, picker.Sat, picker.Vib = color:ToHSV()
        end

        function picker:Display()
            if Library.Unloaded then return end
            picker.Value = Color3.fromHSV(picker.Hue, picker.Sat, picker.Vib)
            holder.BackgroundColor3 = picker.Value
            holderStroke.Color = Library:GetDarkerColor(picker.Value)
            holderTrans.ImageTransparency = 1 - picker.Transparency
            satMap.BackgroundColor3 = Color3.fromHSV(picker.Hue, 1, 1)
            if transColor then transColor.BackgroundColor3 = picker.Value end
            satCursor.Position = UDim2.fromScale(picker.Sat, 1 - picker.Vib)
            hueCursor.Position = UDim2.fromScale(0.5, picker.Hue)
            if transCursor then transCursor.Position = UDim2.fromScale(0.5, picker.Transparency) end
            hueBox.Text = "#" .. picker.Value:ToHex()
            rgbBox.Text = table.concat({math.floor(picker.Value.R*255), math.floor(picker.Value.G*255), math.floor(picker.Value.B*255)}, ", ")
        end

        function picker:RunChanged()
            Library:SafeCallback(picker.Callback, picker.Value)
            Library:SafeCallback(picker.Changed, picker.Value)
        end

        function picker:Update()
            picker:Display()
            picker:RunChanged()
        end

        function picker:OnChanged(f) picker.Changed = f end

        function picker:SetValue(hsv, transparency)
            if type(hsv) == "Color3" then
                picker:SetValueRGB(hsv, transparency)
                return
            end
            local color = Color3.fromHSV(hsv[1], hsv[2], hsv[3])
            picker.Transparency = info.Transparency and transparency or 0
            picker:SetHSVFromRGB(color)
            picker:Update()
        end

        function picker:SetValueRGB(color, transparency)
            picker.Transparency = info.Transparency and transparency or 0
            picker:SetHSVFromRGB(color)
            picker:Update()
        end

        table.insert(picker.Connections, holder.MouseButton1Click:Connect(colorMenu.Toggle))
        table.insert(picker.Connections, holder.MouseButton2Click:Connect(contextMenu.Toggle))

        table.insert(picker.Connections, satMap.InputBegan:Connect(function(input)
            while IsDragInput(input) and not picker.Destroyed do
                local minX = satMap.AbsolutePosition.X
                local maxX = minX + satMap.AbsoluteSize.X
                local locX = math.clamp(Mouse.X, minX, maxX)
                local minY = satMap.AbsolutePosition.Y
                local maxY = minY + satMap.AbsoluteSize.Y
                local locY = math.clamp(Mouse.Y, minY, maxY)
                local oldS, oldV = picker.Sat, picker.Vib
                picker.Sat = (locX - minX) / (maxX - minX)
                picker.Vib = 1 - ((locY - minY) / (maxY - minY))
                if picker.Sat ~= oldS or picker.Vib ~= oldV then picker:Update() end
                RunService.RenderStepped:Wait()
            end
        end))
        table.insert(picker.Connections, hueSelector.InputBegan:Connect(function(input)
            while IsDragInput(input) and not picker.Destroyed do
                local min = hueSelector.AbsolutePosition.Y
                local max = min + hueSelector.AbsoluteSize.Y
                local loc = math.clamp(Mouse.Y, min, max)
                local oldH = picker.Hue
                picker.Hue = (loc - min) / (max - min)
                if picker.Hue ~= oldH then picker:Update() end
                RunService.RenderStepped:Wait()
            end
        end))
        if transSelector then
            table.insert(picker.Connections, transSelector.InputBegan:Connect(function(input)
                while IsDragInput(input) and not picker.Destroyed do
                    local min = transSelector.AbsolutePosition.Y
                    local max = min + transSelector.AbsoluteSize.Y
                    local loc = math.clamp(Mouse.Y, min, max)
                    local oldT = picker.Transparency
                    picker.Transparency = (loc - min) / (max - min)
                    if picker.Transparency ~= oldT then picker:Update() end
                    RunService.RenderStepped:Wait()
                end
            end))
        end
        table.insert(picker.Connections, hueBox.FocusLost:Connect(function(enter)
            if not enter then return end
            local success, color = pcall(Color3.fromHex, hueBox.Text)
            if success and type(color) == "Color3" then
                picker.Hue, picker.Sat, picker.Vib = color:ToHSV()
            end
            picker:Update()
        end))
        table.insert(picker.Connections, rgbBox.FocusLost:Connect(function(enter)
            if not enter then return end
            local r,g,b = rgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
            if r and g and b then
                picker:SetHSVFromRGB(Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)))
            end
            picker:Update()
        end))

        picker:Display()
        if parent.Addons then table.insert(parent.Addons, picker) end
        picker.Default = picker.Value

        function picker:Destroy()
            picker.Destroyed = true
            for _, conn in ipairs(picker.Connections) do conn:Disconnect() end
            if colorMenu then colorMenu:Destroy() end
            if contextMenu then contextMenu:Destroy() end
            if holder then holder:Destroy() end
            if parent and parent.Addons then
                local idx = table.find(parent.Addons, picker)
                if idx then table.remove(parent.Addons, idx) end
            end
            Options[idx] = nil
        end
        Options[idx] = picker
        return self
    end

    BaseAddons.__index = BaseAddons
end

-- BaseGroupbox metatable for elements
local BaseGroupbox = {}
do
    local Funcs = {}

    function Funcs:AddDivider(...)
        if self.Destroyed then return nil end
        local params = select(1, ...)
        local text, marginTop, marginBottom
        if type(params) == "table" then
            text = params.Text
            marginTop = params.MarginTop or params.Margin or 0
            marginBottom = params.MarginBottom or params.Margin or 0
        else
            text = params
        end
        local gb = self
        local container = gb.Container

        local holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,6 + marginTop + marginBottom),
            Parent = container,
        })
        local inner = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Parent = holder })
        New("UIPadding", { PaddingTop = UDim.new(0,marginTop), PaddingBottom = UDim.new(0,marginBottom), Parent = holder })

        if text then
            local lbl = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1,0),
                Text = text,
                TextSize = 14,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = inner,
            })
            local x,_ = Library:GetTextBounds(text, lbl.FontFace, lbl.TextSize, lbl.AbsoluteSize.X)
            local sx = x//2 + 10
            New("Frame", { AnchorPoint = Vector2.new(0,0.5), BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor", BorderSizePixel = 1, Position = UDim2.fromScale(0,0.5), Size = UDim2.new(0.5, -sx, 0, 2), Parent = inner })
            New("Frame", { AnchorPoint = Vector2.new(1,0.5), BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor", BorderSizePixel = 1, Position = UDim2.fromScale(1,0.5), Size = UDim2.new(0.5, -sx, 0, 2), Parent = inner })
        else
            New("Frame", { AnchorPoint = Vector2.new(0,0.5), BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor", BorderSizePixel = 1, Position = UDim2.fromScale(0,0.5), Size = UDim2.new(1,0,0,2), Parent = inner })
        end

        gb:Resize()
        local div = { Connections = {}, Destroyed = false, Holder = holder, Text = text, MarginTop = marginTop, MarginBottom = marginBottom, Type = "Divider" }
        function div:SetVisible(v) holder.Visible = v; gb:Resize() end
        function div:Destroy()
            div.Destroyed = true
            for _, conn in div.Connections do conn:Disconnect() end
            if holder then holder:Destroy() end
            local idx = table.find(gb.Elements, div); if idx then table.remove(gb.Elements, idx) end
            gb:Resize()
        end
        table.insert(gb.Elements, div)
        return div
    end

    function Funcs:AddLabel(...)
        if self.Destroyed then return nil end
        local data = {}
        local addons = {}
        local first = select(1, ...)
        local second = select(2, ...)
        if type(first) == "table" or type(second) == "table" then
            local params = type(first) == "table" and first or second
            data.Text = params.Text or ""
            data.DoesWrap = params.DoesWrap or false
            data.Size = params.Size or 14
            data.Visible = params.Visible or true
            data.Idx = type(second) == "table" and first or nil
        else
            data.Text = first or ""
            data.DoesWrap = second or false
            data.Size = 14
            data.Visible = true
            data.Idx = select(3, ...) or nil
        end
        local gb = self
        local container = gb.Container
        local lbl = {
            Connections = {},
            Destroyed = false,
            Text = data.Text,
            DoesWrap = data.DoesWrap,
            Addons = addons,
            Visible = data.Visible,
            Type = "Label",
        }
        local textLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,18),
            Text = lbl.Text,
            TextSize = data.Size,
            TextWrapped = lbl.DoesWrap,
            TextXAlignment = gb.IsKeyTab and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            Parent = container,
        })
        function lbl:Display()
            if not lbl.DoesWrap then return end
            local w = textLabel.AbsoluteSize.X
            if w <= 0 then return end
            local _, y = Library:GetTextBounds(lbl.Text, textLabel.FontFace, textLabel.TextSize, w)
            textLabel.Size = UDim2.new(1,0,0, y+4)
        end
        function lbl:SetVisible(v) lbl.Visible = v; textLabel.Visible = v; gb:Resize() end
        function lbl:SetText(t) lbl.Text = t; textLabel.Text = t; lbl:Display(); gb:Resize() end
        if lbl.DoesWrap then
            lbl:Display()
            local last = textLabel.AbsoluteSize
            textLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if textLabel.AbsoluteSize == last then return end
                lbl:Display(); last = textLabel.AbsoluteSize; gb:Resize()
            end)
        else
            New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0,6), Parent = textLabel })
        end
        gb:Resize()
        lbl.TextLabel = textLabel
        lbl.Container = container
        if not data.DoesWrap then setmetatable(lbl, BaseAddons) end
        lbl.Holder = textLabel
        table.insert(gb.Elements, lbl)
        if data.Idx then Labels[data.Idx] = lbl else table.insert(Labels, lbl) end
        function lbl:Destroy()
            lbl.Destroyed = true
            for _, conn in lbl.Connections do conn:Disconnect() end
            if lbl.Addons then for i=#lbl.Addons,1,-1 do local a = table.remove(lbl.Addons,i); if a and a.Destroy then a:Destroy() end end end
            if textLabel then textLabel:Destroy() end
            local idx = table.find(gb.Elements, lbl); if idx then table.remove(gb.Elements, idx) end
            gb:Resize()
            if data.Idx then Labels[data.Idx] = nil else local i = table.find(Labels, lbl); if i then table.remove(Labels, i) end end
        end
        return lbl
    end

    function Funcs:AddButton(...)
        if self.Destroyed then return nil end
        local function GetInfo(...)
            local info = {}
            local first = select(1, ...)
            local second = select(2, ...)
            if type(first) == "table" or type(second) == "table" then
                local params = type(first) == "table" and first or second
                info.Text = params.Text or ""
                info.Func = params.Func or params.Callback or function() end
                info.DoubleClick = params.DoubleClick
                info.Tooltip = params.Tooltip
                info.DisabledTooltip = params.DisabledTooltip
                info.Risky = params.Risky or false
                info.Disabled = params.Disabled or false
                info.Visible = params.Visible or true
                info.Idx = type(second) == "table" and first or nil
            else
                info.Text = first or ""
                info.Func = second or function() end
                info.DoubleClick = false
                info.Tooltip = nil
                info.DisabledTooltip = nil
                info.Risky = false
                info.Disabled = false
                info.Visible = true
                info.Idx = select(3, ...) or nil
            end
            return info
        end
        local info = GetInfo(...)
        local gb = self
        local container = gb.Container
        local btn = {
            Connections = {},
            Destroyed = false,
            Text = info.Text,
            Func = info.Func,
            DoubleClick = info.DoubleClick,
            Tooltip = info.Tooltip,
            DisabledTooltip = info.DisabledTooltip,
            TooltipTable = nil,
            Risky = info.Risky,
            Disabled = info.Disabled,
            Visible = info.Visible,
            Tween = nil,
            Type = "Button",
        }

        local holder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,21), Parent = container })
        New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalFlex = Enum.UIFlexAlignment.Fill, Padding = UDim.new(0,9), Parent = holder })

        local function CreateButton(button)
            local base = New("TextButton", {
                Active = not button.Disabled,
                BackgroundColor3 = button.Disabled and "BackgroundColor" or "MainColor",
                Size = UDim2.fromScale(1,1),
                Text = button.Text,
                TextSize = 14,
                TextTransparency = 0.4,
                Visible = button.Visible,
                Parent = holder,
            })
            local stroke = New("UIStroke", { Color = "OutlineColor", Transparency = button.Disabled and 0.5 or 0, Parent = base })
            table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0,Library.CornerRadius/2), Parent = base }))
            return base, stroke
        end

        local function InitEvents(button)
            button.Base.MouseEnter:Connect(function()
                if button.Disabled then return end
                button.Tween = TweenService:Create(button.Base, Library.TweenInfo, { TextTransparency = 0 })
                button.Tween:Play()
            end)
            button.Base.MouseLeave:Connect(function()
                if button.Disabled then return end
                button.Tween = TweenService:Create(button.Base, Library.TweenInfo, { TextTransparency = 0.4 })
                button.Tween:Play()
            end)
            button.Base.MouseButton1Click:Connect(function()
                if button.Disabled or button.Locked then return end
                if button.DoubleClick then
                    button.Locked = true
                    button.Base.Text = "Are you sure?"
                    button.Base.TextColor3 = Library.Scheme.AccentColor
                    Library.Registry[button.Base].TextColor3 = "AccentColor"
                    local clicked = WaitForEvent(button.Base.MouseButton1Click, 0.5)
                    button.Base.Text = button.Text
                    button.Base.TextColor3 = button.Risky and Library.Scheme.RedColor or Library.Scheme.FontColor
                    Library.Registry[button.Base].TextColor3 = button.Risky and "RedColor" or "FontColor"
                    if clicked then Library:SafeCallback(button.Func) end
                    RunService.RenderStepped:Wait()
                    button.Locked = false
                    return
                end
                Library:SafeCallback(button.Func)
            end)
        end

        btn.Base, btn.Stroke = CreateButton(btn)
        InitEvents(btn)

        function btn:AddButton(...)
            local info = GetInfo(...)
            local sub = {
                Connections = {},
                Destroyed = false,
                Text = info.Text,
                Func = info.Func,
                DoubleClick = info.DoubleClick,
                Tooltip = info.Tooltip,
                DisabledTooltip = info.DisabledTooltip,
                TooltipTable = nil,
                Risky = info.Risky,
                Disabled = info.Disabled,
                Visible = info.Visible,
                Tween = nil,
                Type = "SubButton",
            }
            btn.SubButton = sub
            sub.Base, sub.Stroke = CreateButton(sub)
            InitEvents(sub)
            function sub:UpdateColors()
                if Library.Unloaded then return end
                StopTween(sub.Tween)
                sub.Base.BackgroundColor3 = sub.Disabled and Library.Scheme.BackgroundColor or Library.Scheme.MainColor
                sub.Base.TextTransparency = sub.Disabled and 0.8 or 0.4
                sub.Stroke.Transparency = sub.Disabled and 0.5 or 0
                Library.Registry[sub.Base].BackgroundColor3 = sub.Disabled and "BackgroundColor" or "MainColor"
            end
            function sub:SetDisabled(d) sub.Disabled = d; if sub.TooltipTable then sub.TooltipTable.Disabled = d end; sub.Base.Active = not d; sub:UpdateColors() end
            function sub:SetVisible(v) sub.Visible = v; sub.Base.Visible = v; gb:Resize() end
            function sub:SetText(t) sub.Text = t; sub.Base.Text = t end
            if type(sub.Tooltip) == "string" or type(sub.DisabledTooltip) == "string" then
                sub.TooltipTable = Library:AddTooltip(sub.Tooltip, sub.DisabledTooltip, sub.Base)
                sub.TooltipTable.Disabled = sub.Disabled
            end
            if sub.Risky then
                sub.Base.TextColor3 = Library.Scheme.RedColor
                Library.Registry[sub.Base].TextColor3 = "RedColor"
            end
            sub:UpdateColors()
            if info.Idx then Buttons[info.Idx] = sub else table.insert(Buttons, sub) end
            sub.AddKeyPicker = BaseAddons.__index.AddKeyPicker
            function sub:Destroy()
                sub.Destroyed = true
                if sub.TooltipTable then sub.TooltipTable:Destroy() end
                if sub.Tween then sub.Tween:Destroy() end
                if sub.Base then sub.Base:Destroy() end
                if info.Idx then Buttons[info.Idx] = nil else local i = table.find(Buttons, sub); if i then table.remove(Buttons, i) end end
            end
            return sub
        end

        function btn:UpdateColors()
            if Library.Unloaded then return end
            StopTween(btn.Tween)
            btn.Base.BackgroundColor3 = btn.Disabled and Library.Scheme.BackgroundColor or Library.Scheme.MainColor
            btn.Base.TextTransparency = btn.Disabled and 0.8 or 0.4
            btn.Stroke.Transparency = btn.Disabled and 0.5 or 0
            Library.Registry[btn.Base].BackgroundColor3 = btn.Disabled and "BackgroundColor" or "MainColor"
        end
        function btn:SetDisabled(d) btn.Disabled = d; if btn.TooltipTable then btn.TooltipTable.Disabled = d end; btn.Base.Active = not d; btn:UpdateColors() end
        function btn:SetVisible(v) btn.Visible = v; holder.Visible = v; gb:Resize() end
        function btn:SetText(t) btn.Text = t; btn.Base.Text = t end
        if type(btn.Tooltip) == "string" or type(btn.DisabledTooltip) == "string" then
            btn.TooltipTable = Library:AddTooltip(btn.Tooltip, btn.DisabledTooltip, btn.Base)
            btn.TooltipTable.Disabled = btn.Disabled
        end
        if btn.Risky then
            btn.Base.TextColor3 = Library.Scheme.RedColor
            Library.Registry[btn.Base].TextColor3 = "RedColor"
        end
        btn:UpdateColors()
        gb:Resize()
        btn.Holder = holder
        table.insert(gb.Elements, btn)
        if info.Idx then Buttons[info.Idx] = btn else table.insert(Buttons, btn) end
        btn.AddKeyPicker = BaseAddons.__index.AddKeyPicker
        function btn:Destroy()
            btn.Destroyed = true
            if btn.TooltipTable then btn.TooltipTable:Destroy() end
            if btn.Tween then btn.Tween:Destroy() end
            if btn.SubButton then btn.SubButton:Destroy() end
            if holder then holder:Destroy() end
            local idx = table.find(gb.Elements, btn); if idx then table.remove(gb.Elements, idx) end
            gb:Resize()
            if info.Idx then Buttons[info.Idx] = nil else local i = table.find(Buttons, btn); if i then table.remove(Buttons, i) end end
        end
        return btn
    end

    function Funcs:AddCheckbox(idx, info)
        if self.Destroyed then return nil end
        info = Library:Validate(info, Templates.Toggle)
        local gb = self
        local container = gb.Container
        local toggle = {
            Connections = {},
            Destroyed = false,
            Text = info.Text,
            Value = info.Default,
            Tooltip = info.Tooltip,
            DisabledTooltip = info.DisabledTooltip,
            TooltipTable = nil,
            Callback = info.Callback,
            Changed = info.Changed,
            Risky = info.Risky,
            Disabled = info.Disabled,
            Visible = info.Visible,
            Addons = {},
            AnyKeyPickerPicking = false,
            Variant = "Checkbox",
            Type = "Toggle",
        }
        local button = New("TextButton", {
            Active = not toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,18),
            Text = "",
            Visible = toggle.Visible,
            Parent = container,
        })
        local label = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(26,0),
            Size = UDim2.new(1,-26,1,0),
            Text = toggle.Text,
            TextSize = 14,
            TextTransparency = 0.4,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = button,
        })
        New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0,6), Parent = label })
        local checkbox = New("Frame", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromScale(1,1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = button,
        })
        table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0,Library.CornerRadius/2), Parent = checkbox }))
        local stroke = New("UIStroke", { Color = "OutlineColor", Parent = checkbox })
        local checkImg = New("ImageLabel", {
            Image = CustomImageManager:GetAsset("CheckIcon"),
            ImageColor3 = "FontColor",
            ImageTransparency = 1,
            Position = UDim2.fromOffset(2,2),
            Size = UDim2.new(1,-4,1,-4),
            Parent = checkbox,
        })
        function toggle:UpdateColors()
            toggle:Display()
        end
        function toggle:Display()
            if Library.Unloaded then return end
            stroke.Transparency = toggle.Disabled and 0.5 or 0
            if toggle.Disabled then
                label.TextTransparency = 0.8
                checkImg.ImageTransparency = toggle.Value and 0.8 or 1
                checkbox.BackgroundColor3 = Library.Scheme.BackgroundColor
                Library.Registry[checkbox].BackgroundColor3 = "BackgroundColor"
                return
            end
            TweenService:Create(label, Library.TweenInfo, { TextTransparency = toggle.Value and 0 or 0.4 }):Play()
            TweenService:Create(checkImg, Library.TweenInfo, { ImageTransparency = toggle.Value and 0 or 1 }):Play()
            checkbox.BackgroundColor3 = Library.Scheme.MainColor
            Library.Registry[checkbox].BackgroundColor3 = "MainColor"
        end
        function toggle:OnChanged(f) toggle.Changed = f end
        function toggle:RunChanged()
            Library:SafeCallback(toggle.Callback, toggle.Value)
            Library:SafeCallback(toggle.Changed, toggle.Value)
        end
        function toggle:SetValue(v)
            if toggle.Disabled then return end
            toggle.Value = v
            toggle:Display()
            for _, addon in toggle.Addons do
                if addon.Type == "KeyPicker" and addon.SyncToggleState then
                    addon.Toggled = toggle.Value
                    addon:Update()
                end
            end
            Library:UpdateDependencyBoxes()
            if not toggle.AnyKeyPickerPicking then toggle:RunChanged() end
        end
        function toggle:SetDisabled(d)
            toggle.Disabled = d
            if toggle.TooltipTable then toggle.TooltipTable.Disabled = d end
            for _, addon in toggle.Addons do
                if addon.Type == "KeyPicker" and addon.SyncToggleState then addon:Update() end
            end
            button.Active = not d
            toggle:Display()
        end
        function toggle:SetVisible(v)
            toggle.Visible = v
            button.Visible = v
            gb:Resize()
        end
        function toggle:SetText(t)
            toggle.Text = t
            label.Text = t
        end
        table.insert(toggle.Connections, button.MouseButton1Click:Connect(function()
            if toggle.Disabled then return end
            toggle:SetValue(not toggle.Value)
        end))
        if type(toggle.Tooltip) == "string" or type(toggle.DisabledTooltip) == "string" then
            toggle.TooltipTable = Library:AddTooltip(toggle.Tooltip, toggle.DisabledTooltip, button)
            toggle.TooltipTable.Disabled = toggle.Disabled
        end
        if toggle.Risky then
            label.TextColor3 = Library.Scheme.RedColor
            Library.Registry[label].TextColor3 = "RedColor"
        end
        toggle:Display()
        gb:Resize()
        toggle.TextLabel = label
        toggle.Container = container
        setmetatable(toggle, BaseAddons)
        toggle.Holder = button
        table.insert(gb.Elements, toggle)
        toggle.Default = toggle.Value
        Toggles[idx] = toggle
        function toggle:Destroy()
            toggle.Destroyed = true
            for _, conn in toggle.Connections do conn:Disconnect() end
            if toggle.TooltipTable then toggle.TooltipTable:Destroy() end
            if button then button:Destroy() end
            if toggle.Addons then for i=#toggle.Addons,1,-1 do local a = table.remove(toggle.Addons,i); if a and a.Destroy then a:Destroy() end end end
            local idx2 = table.find(gb.Elements, toggle); if idx2 then table.remove(gb.Elements, idx2) end
            gb:Resize()
            Toggles[idx] = nil
        end
        return toggle
    end

    function Funcs:AddToggle(idx, info)
        if self.Destroyed then return nil end
        if Library.ForceCheckbox then return self:AddCheckbox(idx, info) end
        info = Library:Validate(info, Templates.Toggle)
        local gb = self
        local container = gb.Container
        local toggle = {
            Connections = {},
            Destroyed = false,
            Text = info.Text,
            Value = info.Default,
            Tooltip = info.Tooltip,
            DisabledTooltip = info.DisabledTooltip,
            TooltipTable = nil,
            Callback = info.Callback,
            Changed = info.Changed,
            Risky = info.Risky,
            Disabled = info.Disabled,
            Visible = info.Visible,
            Addons = {},
            AnyKeyPickerPicking = false,
            Variant = "Switch",
            Type = "Toggle",
        }
        local button = New("TextButton", {
            Active = not toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,18),
            Text = "",
            Visible = toggle.Visible,
            Parent = container,
        })
        local label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1,-40,1,0),
            Text = toggle.Text,
            TextSize = 14,
            TextTransparency = 0.4,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = button,
        })
        New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0,6), Parent = label })
        local switch = New("Frame", {
            AnchorPoint = Vector2.new(1,0),
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(1,0),
            Size = UDim2.fromOffset(32,18),
            Parent = button,
        })
        New("UICorner", { CornerRadius = UDim.new(1,0), Parent = switch })
        New("UIPadding", { PaddingBottom = UDim.new(0,2), PaddingLeft = UDim.new(0,2), PaddingRight = UDim.new(0,2), PaddingTop = UDim.new(0,2), Parent = switch })
        local switchStroke = New("UIStroke", { Color = "OutlineColor", Parent = switch })
        local ball = New("Frame", {
            BackgroundColor3 = "FontColor",
            Size = UDim2.fromScale(1,1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = switch,
        })
        New("UICorner", { CornerRadius = UDim.new(1,0), Parent = ball })

        function toggle:UpdateColors()
            toggle:Display()
        end
        function toggle:Display()
            if Library.Unloaded then return end
            local offset = toggle.Value and 1 or 0
            switch.BackgroundTransparency = toggle.Disabled and 0.75 or 0
            switchStroke.Transparency = toggle.Disabled and 0.75 or 0
            switch.BackgroundColor3 = toggle.Value and Library.Scheme.AccentColor or Library.Scheme.MainColor
            switchStroke.Color = toggle.Value and Library.Scheme.AccentColor or Library.Scheme.OutlineColor
            Library.Registry[switch].BackgroundColor3 = toggle.Value and "AccentColor" or "MainColor"
            Library.Registry[switchStroke].Color = toggle.Value and "AccentColor" or "OutlineColor"
            if toggle.Disabled then
                label.TextTransparency = 0.8
                ball.AnchorPoint = Vector2.new(offset,0)
                ball.Position = UDim2.fromScale(offset,0)
                ball.BackgroundColor3 = Library:GetDarkerColor(Library.Scheme.FontColor)
                Library.Registry[ball].BackgroundColor3 = function() return Library:GetDarkerColor(Library.Scheme.FontColor) end
                return
            end
            TweenService:Create(label, Library.TweenInfo, { TextTransparency = toggle.Value and 0 or 0.4 }):Play()
            TweenService:Create(ball, Library.TweenInfo, {
                AnchorPoint = Vector2.new(offset,0),
                Position = UDim2.fromScale(offset,0)
            }):Play()
            ball.BackgroundColor3 = Library.Scheme.FontColor
            Library.Registry[ball].BackgroundColor3 = "FontColor"
        end
        function toggle:OnChanged(f) toggle.Changed = f end
        function toggle:RunChanged()
            Library:SafeCallback(toggle.Callback, toggle.Value)
            Library:SafeCallback(toggle.Changed, toggle.Value)
        end
        function toggle:SetValue(v)
            if toggle.Disabled then return end
            toggle.Value = v
            toggle:Display()
            for _, addon in toggle.Addons do
                if addon.Type == "KeyPicker" and addon.SyncToggleState then
                    addon.Toggled = toggle.Value
                    addon:Update()
                end
            end
            Library:UpdateDependencyBoxes()
            if not toggle.AnyKeyPickerPicking then toggle:RunChanged() end
        end
        function toggle:SetDisabled(d)
            toggle.Disabled = d
            if toggle.TooltipTable then toggle.TooltipTable.Disabled = d end
            for _, addon in toggle.Addons do
                if addon.Type == "KeyPicker" and addon.SyncToggleState then addon:Update() end
            end
            button.Active = not d
            toggle:Display()
        end
        function toggle:SetVisible(v)
            toggle.Visible = v
            button.Visible = v
            gb:Resize()
        end
        function toggle:SetText(t)
            toggle.Text = t
            label.Text = t
        end
        table.insert(toggle.Connections, button.MouseButton1Click:Connect(function()
            if toggle.Disabled then return end
            toggle:SetValue(not toggle.Value)
        end))
        if type(toggle.Tooltip) == "string" or type(toggle.DisabledTooltip) == "string" then
            toggle.TooltipTable = Library:AddTooltip(toggle.Tooltip, toggle.DisabledTooltip, button)
            toggle.TooltipTable.Disabled = toggle.Disabled
        end
        if toggle.Risky then
            label.TextColor3 = Library.Scheme.RedColor
            Library.Registry[label].TextColor3 = "RedColor"
        end
        toggle:Display()
        gb:Resize()
        toggle.TextLabel = label
        toggle.Container = container
        setmetatable(toggle, BaseAddons)
        toggle.Holder = button
        table.insert(gb.Elements, toggle)
        toggle.Default = toggle.Value
        Toggles[idx] = toggle
        function toggle:Destroy()
            toggle.Destroyed = true
            for _, conn in toggle.Connections do conn:Disconnect() end
            if toggle.TooltipTable then toggle.TooltipTable:Destroy() end
            if button then button:Destroy() end
            if toggle.Addons then for i=#toggle.Addons,1,-1 do local a = table.remove(toggle.Addons,i); if a and a.Destroy then a:Destroy() end end end
            local idx2 = table.find(gb.Elements, toggle); if idx2 then table.remove(gb.Elements, idx2) end
            gb:Resize()
            Toggles[idx] = nil
        end
        return toggle
    end

    function Funcs:AddInput(idx, info)
        if self.Destroyed then return nil end
        if type(info) == "table" and (type(info.VerifyValue) == "function" and info.Finished ~= true) then
            info.Finished = true
        end
        info = Library:Validate(info, Templates.Input)
        local gb = self
        local container = gb.Container
        local input = {
            Connections = {},
            Destroyed = false,
            Text = info.Text,
            Value = info.Default,
            Finished = info.Finished,
            Numeric = info.Numeric,
            ClearTextOnFocus = info.ClearTextOnFocus,
            ClearTextOnBlur = info.ClearTextOnBlur,
            Placeholder = info.Placeholder,
            AllowEmpty = info.AllowEmpty,
            EmptyReset = info.EmptyReset,
            Tooltip = info.Tooltip,
            DisabledTooltip = info.DisabledTooltip,
            TooltipTable = nil,
            Callback = info.Callback,
            Changed = info.Changed,
            VerifyValue = info.VerifyValue,
            Disabled = info.Disabled,
            Visible = info.Visible,
            Type = "Input",
        }
        local holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,39),
            Visible = input.Visible,
            Parent = container,
        })
        local label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,14),
            Text = input.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = holder,
        })
        local box = New("TextBox", {
            AnchorPoint = Vector2.new(0,1),
            BackgroundColor3 = "MainColor",
            ClearTextOnFocus = not input.Disabled and input.ClearTextOnFocus,
            PlaceholderText = input.Placeholder,
            Position = UDim2.fromScale(0,1),
            Size = UDim2.new(1,0,0,21),
            Text = input.Value,
            TextEditable = not input.Disabled,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = holder,
        })
        New("UIPadding", { PaddingBottom = UDim.new(0,3), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,4), Parent = box })
        New("UIStroke", { Color = "OutlineColor", Parent = box })
        table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0,Library.CornerRadius/2), Parent = box }))

        function input:UpdateColors()
            if Library.Unloaded then return end
            label.TextTransparency = input.Disabled and 0.8 or 0
            box.TextTransparency = input.Disabled and 0.8 or 0
        end
        function input:OnChanged(f) input.Changed = f end
        function input:RunChanged()
            Library:SafeCallback(input.Callback, input.Value)
            Library:SafeCallback(input.Changed, input.Value)
        end
        function input:SetValue(text)
            if not input.AllowEmpty and Trim(text) == "" then text = input.EmptyReset end
            if info.MaxLength and #text > info.MaxLength then text = text:sub(1, info.MaxLength) end
            if input.Numeric then
                if #tostring(text) > 0 and not tonumber(text) then text = input.Value end
            end
            if type(info.VerifyValue) == "function" and (text ~= input.EmptyReset and info.VerifyValue(text) ~= true) then
                text = input.EmptyReset
            end
            input.Value = text
            box.Text = text
            if not input.Disabled then input:RunChanged() end
        end
        function input:SetDisabled(d)
            input.Disabled = d
            if input.TooltipTable then input.TooltipTable.Disabled = d end
            box.ClearTextOnFocus = not d and input.ClearTextOnFocus
            box.TextEditable = not d
            input:UpdateColors()
        end
        function input:SetVisible(v)
            input.Visible = v
            holder.Visible = v
            gb:Resize()
        end
        function input:SetText(t)
            input.Text = t
            label.Text = t
        end
        if input.Finished then
            table.insert(input.Connections, box.FocusLost:Connect(function(enter)
                if not enter then
                    if input.ClearTextOnBlur then box.Text = input.Value end
                    return
                end
                input:SetValue(box.Text)
            end))
        else
            table.insert(input.Connections, box:GetPropertyChangedSignal("Text"):Connect(function()
                if box.Text == input.Value then return end
                input:SetValue(box.Text)
            end))
        end
        if type(input.Tooltip) == "string" or type(input.DisabledTooltip) == "string" then
            input.TooltipTable = Library:AddTooltip(input.Tooltip, input.DisabledTooltip, box)
            input.TooltipTable.Disabled = input.Disabled
        end
        gb:Resize()
        input.Holder = holder
        table.insert(gb.Elements, input)
        input.Default = input.Value
        if type(info.VerifyValue) == "function" and (input.Default ~= input.EmptyReset and info.VerifyValue(input.Default) ~= true) then
            input:SetValue(input.EmptyReset)
            input.Default = input.EmptyReset
        end
        Options[idx] = input
        function input:Destroy()
            input.Destroyed = true
            for _, conn in input.Connections do conn:Disconnect() end
            if input.TooltipTable then input.TooltipTable:Destroy() end
            if holder then holder:Destroy() end
            local idx2 = table.find(gb.Elements, input); if idx2 then table.remove(gb.Elements, idx2) end
            gb:Resize()
            Options[idx] = nil
        end
        return input
    end

    function Funcs:AddSlider(idx, info)
        if self.Destroyed then return nil end
        info = Library:Validate(info, Templates.Slider)
        local gb = self
        local container = gb.Container
        local slider = {
            Connections = {},
            Destroyed = false,
            Text = info.Text,
            Value = info.Default,
            Min = info.Min,
            Max = info.Max,
            Prefix = info.Prefix,
            Suffix = info.Suffix,
            Compact = info.Compact,
            Rounding = info.Rounding,
            HideMax = info.HideMax,
            Tooltip = info.Tooltip,
            DisabledTooltip = info.DisabledTooltip,
            TooltipTable = nil,
            Callback = info.Callback,
            Changed = info.Changed,
            Disabled = info.Disabled,
            Visible = info.Visible,
            AllowRightClickInput = info.AllowRightClickInput,
            Type = "Slider",
        }
        local holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,info.Compact and 15 or 33),
            Visible = slider.Visible,
            Parent = container,
        })
        local sliderLabel
        if not info.Compact then
            sliderLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1,0,0,14),
                Text = slider.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })
        end
        local bar = New("TextButton", {
            Active = not slider.Disabled,
            AnchorPoint = Vector2.new(0,1),
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(0,1),
            Size = UDim2.new(1,0,0,15),
            Text = "",
            Parent = holder,
        })
        New("UIStroke", { Color = "OutlineColor", Parent = bar })
        local display = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1,1),
            Text = "",
            TextSize = 14,
            ZIndex = bar.ZIndex + 2,
            Parent = bar,
        })
        New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Color = "DarkColor", LineJoinMode = Enum.LineJoinMode.Miter, Parent = display })

        local inputBox
        if info.AllowRightClickInput then
            inputBox = New("TextBox", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1,1),
                Text = "",
                TextSize = 14,
                ZIndex = bar.ZIndex + 3,
                Visible = false,
                ClearTextOnFocus = false,
                Parent = bar,
            })
            New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Color = "DarkColor", LineJoinMode = Enum.LineJoinMode.Miter, Parent = inputBox })
        end

        local fill = New("Frame", {
            BackgroundColor3 = "AccentColor",
            Size = UDim2.fromScale(0.5,1),
            ZIndex = bar.ZIndex + 1,
            Parent = bar,
        })
        table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0,Library.CornerRadius/2), Parent = bar }))
        table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0,Library.CornerRadius/2), Parent = fill }))

        function slider:UpdateColors()
            if Library.Unloaded then return end
            if sliderLabel then sliderLabel.TextTransparency = slider.Disabled and 0.8 or 0 end
            display.TextTransparency = slider.Disabled and 0.8 or 0
            if info.AllowRightClickInput then inputBox.TextTransparency = slider.Disabled and 0.8 or 0 end
            fill.BackgroundColor3 = slider.Disabled and Library.Scheme.OutlineColor or Library.Scheme.AccentColor
            Library.Registry[fill].BackgroundColor3 = slider.Disabled and "OutlineColor" or "AccentColor"
        end

        function slider:Display()
            if Library.Unloaded then return end
            local custom = info.FormatDisplayValue and info.FormatDisplayValue(slider, slider.Value)
            if custom then
                display.Text = tostring(custom)
            else
                if info.Compact then
                    display.Text = string.format("%s: %s%s%s", slider.Text, slider.Prefix, slider.Value, slider.Suffix)
                elseif info.HideMax then
                    display.Text = string.format("%s%s%s", slider.Prefix, slider.Value, slider.Suffix)
                else
                    display.Text = string.format("%s%s%s/%s%s%s", slider.Prefix, slider.Value, slider.Suffix, slider.Prefix, slider.Max, slider.Suffix)
                end
            end
            local x = (slider.Value - slider.Min) / (slider.Max - slider.Min)
            fill.Size = UDim2.fromScale(x,1)
        end

        function slider:OnChanged(f) slider.Changed = f end
        function slider:SetMax(v) assert(v > slider.Min); slider:SetValue(math.clamp(slider.Value, slider.Min, v)); slider.Max = v; slider:Display() end
        function slider:SetMin(v) assert(v < slider.Max); slider:SetValue(math.clamp(slider.Value, v, slider.Max)); slider.Min = v; slider:Display() end
        function slider:RunChanged()
            Library:SafeCallback(slider.Callback, slider.Value)
            Library:SafeCallback(slider.Changed, slider.Value)
        end
        function slider:SetValue(v)
            if slider.Disabled then return end
            local num = tonumber(v)
            if not num or num == slider.Value then return end
            num = math.clamp(num, slider.Min, slider.Max)
            slider.Value = num
            slider:Display()
            slider:RunChanged()
        end
        function slider:SetDisabled(d)
            slider.Disabled = d
            if slider.TooltipTable then slider.TooltipTable.Disabled = d end
            bar.Active = not d
            slider:UpdateColors()
        end
        function slider:SetVisible(v)
            slider.Visible = v
            holder.Visible = v
            gb:Resize()
        end
        function slider:SetText(t) slider.Text = t; if sliderLabel then sliderLabel.Text = t else slider:Display() end end
        function slider:SetPrefix(p) slider.Prefix = p; slider:Display() end
        function slider:SetSuffix(s) slider.Suffix = s; slider:Display() end

        if info.AllowRightClickInput then
            local lastValid = ""
            table.insert(slider.Connections, inputBox:GetPropertyChangedSignal("Text"):Connect(function()
                local text = inputBox.Text
                local asNum = tonumber(text)
                if #tostring(text) > 0 and not asNum and text ~= "-" then
                    inputBox.Text = lastValid
                else
                    if slider.Rounding == 0 and text:find("%.") then inputBox.Text = lastValid; return end
                    local dp = text:find("%.")
                    if dp and slider.Rounding > 0 then
                        local decimals = #text - dp
                        if decimals > slider.Rounding then inputBox.Text = lastValid; return end
                    end
                    lastValid = text
                    if asNum then
                        if asNum > slider.Max then inputBox.Text = tostring(slider.Max)
                        elseif asNum < slider.Min then inputBox.Text = tostring(slider.Min) end
                    end
                end
            end))
            table.insert(slider.Connections, inputBox.FocusLost:Connect(function()
                inputBox.Visible = false
                display.Visible = true
                local num = tonumber(inputBox.Text)
                if not num then return end
                num = Round(num, slider.Rounding)
                slider:SetValue(num)
            end))
        end

        local lastTap = 0
        table.insert(slider.Connections, bar.InputBegan:Connect(function(input)
            local valid = IsClickInput(input) or input.UserInputType == Enum.UserInputType.MouseButton2
            if not valid or slider.Disabled then return end
            if info.AllowRightClickInput then
                local isRight = input.UserInputType == Enum.UserInputType.MouseButton2
                local isDouble = false
                if Library.IsMobile and input.UserInputType == Enum.UserInputType.Touch then
                    if tick() - lastTap < 0.3 then isDouble = true end
                    lastTap = tick()
                end
                if isRight or isDouble then
                    inputBox.Text = tostring(slider.Value)
                    inputBox.Visible = true
                    display.Visible = false
                    task.spawn(inputBox.CaptureFocus, inputBox)
                    return
                end
            end
            if not IsClickInput(input) then return end
            if Library.ActiveTab then
                for _, side in Library.ActiveTab.Sides do side.ScrollingEnabled = false end
            end
            if Library.ActiveLoading and Library.ActiveLoading.Sidebar then
                Library.ActiveLoading.Sidebar.Container.ScrollingEnabled = false
            end
            while IsDragInput(input) and not slider.Destroyed do
                local loc = Mouse.X
                local scale = math.clamp((loc - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local old = slider.Value
                slider.Value = Round(slider.Min + ((slider.Max - slider.Min) * scale), slider.Rounding)
                slider:Display()
                if slider.Value ~= old then slider:RunChanged() end
                RunService.RenderStepped:Wait()
            end
            if Library.ActiveTab then
                for _, side in Library.ActiveTab.Sides do side.ScrollingEnabled = true end
            end
            if Library.ActiveLoading and Library.ActiveLoading.Sidebar then
                Library.ActiveLoading.Sidebar.Container.ScrollingEnabled = true
            end
        end))

        if type(slider.Tooltip) == "string" or type(slider.DisabledTooltip) == "string" then
            slider.TooltipTable = Library:AddTooltip(slider.Tooltip, slider.DisabledTooltip, bar)
            slider.TooltipTable.Disabled = slider.Disabled
        end
        slider:UpdateColors()
        slider:Display()
        gb:Resize()
        slider.Holder = holder
        table.insert(gb.Elements, slider)
        slider.Default = slider.Value
        Options[idx] = slider
        function slider:Destroy()
            slider.Destroyed = true
            for _, conn in slider.Connections do conn:Disconnect() end
            if slider.TooltipTable then slider.TooltipTable:Destroy() end
            if holder then holder:Destroy() end
            local idx2 = table.find(gb.Elements, slider); if idx2 then table.remove(gb.Elements, idx2) end
            gb:Resize()
            Options[idx] = nil
        end
        return slider
    end

    function Funcs:AddDropdown(idx, info)
        if self.Destroyed then return nil end
        info = Library:Validate(info, Templates.Dropdown)
        local gb = self
        local container = gb.Container
        if info.SpecialType == "Player" then
            info.Values = GetPlayers(info.ExcludeLocalPlayer)
            info.AllowNull = true
        elseif info.SpecialType == "Team" then
            info.Values = GetTeams()
            info.AllowNull = true
        end

        local dropdown = {
            Connections = {},
            Destroyed = false,
            Text = type(info.Text) == "string" and info.Text or nil,
            Value = info.Multi and {} or nil,
            Values = info.Values,
            DisabledValues = info.DisabledValues,
            ValueImages = info.ValueImages,
            Multi = info.Multi,
            DragSelect = info.Multi and not Library.IsMobile and info.DragSelect == true,
            SpecialType = info.SpecialType,
            ExcludeLocalPlayer = info.ExcludeLocalPlayer,
            EnablePlayerImages = info.EnablePlayerImages,
            Tooltip = info.Tooltip,
            DisabledTooltip = info.DisabledTooltip,
            TooltipTable = nil,
            Callback = info.Callback,
            Changed = info.Changed,
            Disabled = info.Disabled,
            Visible = info.Visible,
            Type = "Dropdown",
        }

        local holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,dropdown.Text and 39 or 21),
            Visible = dropdown.Visible,
            Parent = container,
        })
        local label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,14),
            Text = dropdown.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = not not info.Text,
            ZIndex = 3,
            Parent = holder,
        })
        local displayContainer = New("TextButton", {
            AnchorPoint = Vector2.new(0,1),
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(0,1),
            Size = UDim2.new(1,0,0,21),
            Text = "",
            TextTransparency = 1,
            ZIndex = 2,
            Parent = holder,
        })
        New("UIPadding", { PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,4), Parent = displayContainer })
        New("UIStroke", { Color = "OutlineColor", Parent = displayContainer })
        local corner = New("UICorner", { TopLeftRadius = UDim.new(0,Library.CornerRadius/2), TopRightRadius = UDim.new(0,Library.CornerRadius/2), BottomRightRadius = UDim.new(0,Library.CornerRadius/2), BottomLeftRadius = UDim.new(0,Library.CornerRadius/2), Parent = displayContainer })
        table.insert(Library.SpecificCorners, corner)

        local displayImage = New("ImageLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(-4,3),
            Size = UDim2.fromOffset(16,16),
            Image = "",
            ImageTransparency = 1,
            ZIndex = 2,
            Parent = displayContainer,
        })
        local displayButton = New("TextButton", {
            Active = not dropdown.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,21),
            Text = "---",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2,
            Parent = displayContainer,
        })
        local arrow = New("ImageLabel", {
            AnchorPoint = Vector2.new(1,0.5),
            Image = Library:GetIcon("chevron-up") and Library:GetIcon("chevron-up").Url or "",
            ImageColor3 = "FontColor",
            ImageTransparency = 0.5,
            Position = UDim2.fromScale(1,0.5),
            Size = UDim2.fromOffset(16,16),
            Parent = displayContainer,
        })
        local searchBox
        if info.Searchable then
            searchBox = New("TextBox", {
                BackgroundTransparency = 1,
                PlaceholderText = "Search...",
                Position = UDim2.fromOffset(-8,0),
                Size = UDim2.new(1,-12,1,0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = false,
                Parent = displayButton,
            })
            New("UIPadding", { PaddingLeft = UDim.new(0,8), Parent = searchBox })
        end

        local function GetValueImage(val)
            if not val then return nil end
            if dropdown.SpecialType == "Player" and dropdown.EnablePlayerImages then
                if type(val) == "Instance" and val:IsA("Player") then
                    return { Url = string.format("rbxthumb://type=AvatarHeadShot&id=%s&w=48&h=48", tostring(val.UserId)) }
                end
            else
                if info.ValueImages and info.ValueImages[val] then
                    return Library:GetCustomIcon(info.ValueImages[val])
                end
            end
            return nil
        end

        local menu = Library:AddContextMenu(displayContainer, function()
            return UDim2.fromOffset((displayContainer.AbsoluteSize.X / Library.DPIScale), 0)
        end, function()
            return { 0.5, displayContainer.AbsoluteSize.Y + 1.5 }
        end, 2, function(active)
            displayButton.TextTransparency = (active and searchBox) and 1 or 0
            arrow.ImageTransparency = active and 0 or 0.5
            arrow.Rotation = active and 180 or 0
            if searchBox then
                searchBox.Text = ""
                searchBox.Visible = active
            end
            corner.BottomRightRadius = active and UDim.new(0,0) or UDim.new(0,Library.CornerRadius/2)
            corner.BottomLeftRadius = active and UDim.new(0,0) or UDim.new(0,Library.CornerRadius/2)
        end, false, "bottom", "Dropdown")
        dropdown.Menu = menu

        function dropdown:RecalculateListSize(count)
            local y = math.clamp((count or TableSize(dropdown.Values)) * 21, 0, info.MaxVisibleDropdownItems * 21)
            menu:SetSize(function() return UDim2.fromOffset((displayContainer.AbsoluteSize.X / Library.DPIScale), y) end)
        end

        function dropdown:UpdateColors()
            if Library.Unloaded then return end
            label.TextTransparency = dropdown.Disabled and 0.8 or 0
            displayButton.TextTransparency = dropdown.Disabled and 0.8 or 0
            displayImage.ImageTransparency = dropdown.Disabled and 0.8 or 0
            arrow.ImageTransparency = dropdown.Disabled and 0.8 or (menu.Active and 0 or 0.5)
        end

        function dropdown:Display()
            if Library.Unloaded then return end
            local str = ""
            local valImg = nil
            if info.Multi then
                for _, val in dropdown.Values do
                    if dropdown.Value[val] then
                        if not valImg then valImg = GetValueImage(val) end
                        str = str .. (info.FormatDisplayValue and tostring(info.FormatDisplayValue(val)) or tostring(val)) .. ", "
                    end
                end
                str = str:sub(1, #str-2)
            else
                valImg = GetValueImage(dropdown.Value)
                str = dropdown.Value and tostring(dropdown.Value) or ""
                if str ~= "" and info.FormatDisplayValue then str = tostring(info.FormatDisplayValue(str)) end
            end
            if #str > 25 then str = str:sub(1,22) .. "..." end
            displayButton.Text = (str == "" and "---" or str)
            if valImg then
                displayImage.Image = valImg.Url
                displayImage.ImageRectOffset = valImg.ImageRectOffset or Vector2.zero
                displayImage.ImageRectSize = valImg.ImageRectSize or Vector2.zero
                displayImage.ImageTransparency = 0
            else
                displayImage.Image = ""
                displayImage.ImageTransparency = 1
            end
            displayButton.Size = valImg and UDim2.new(1,-8,0,21) or UDim2.new(1,0,0,21)
            displayButton.Position = valImg and UDim2.fromOffset(14,0) or UDim2.fromOffset(0,0)
        end

        function dropdown:OnChanged(f) dropdown.Changed = f end

        function dropdown:GetActiveValues(returnCount)
            local t = {}
            if info.Multi then
                for val, _ in dropdown.Value do table.insert(t, val) end
            else
                if dropdown.Value then table.insert(t, dropdown.Value) end
            end
            return returnCount and TableSize(t) or t
        end

        local buttons = {}
        local dragSelecting = false
        local dragStartIdx = nil
        local dragInitialValues = {}
        local dragEndConn, dragChangeConn

        local function StopDragSelect()
            dragSelecting = false
            dragStartIdx = nil
            table.clear(dragInitialValues)
            if dragEndConn then dragEndConn:Disconnect(); dragEndConn = nil end
            if dragChangeConn then dragChangeConn:Disconnect(); dragChangeConn = nil end
        end

        local function UpdateDrag(currentIdx)
            local minIdx = math.min(dragStartIdx, currentIdx)
            local maxIdx = math.max(dragStartIdx, currentIdx)
            for btn, tb in buttons do
                local inRange = tb.Index >= minIdx and tb.Index <= maxIdx
                local try = dragInitialValues[tb.Value]
                if inRange then try = not try end
                if not (dropdown:GetActiveValues(true) == 1 and not try and not info.AllowNull) then
                    dropdown.Value[tb.Value] = try and true or nil
                end
                tb:UpdateButton()
            end
            dropdown:Display()
        end

        function dropdown:BuildDropdownList()
            local vals = dropdown.Values
            local disabled = dropdown.DisabledValues
            StopDragSelect()
            for btn,_ in pairs(buttons) do
                if btn and btn.Parent then btn.Parent:Destroy() end
            end
            table.clear(buttons)
            local count = 0
            local processed = 0
            local total = TableSize(vals) + TableSize(disabled)
            for _, val in vals do
                processed = processed + 1
                local formatted = tostring(info.FormatListValue and info.FormatListValue(val) or val)
                if searchBox and not formatted:lower():match(searchBox.Text:lower()) then continue end
                count = count + 1
                local isDisabled = table.find(disabled, val)
                local tb = {}
                local valImg = GetValueImage(val)
                local container = New("Frame", {
                    BackgroundColor3 = "MainColor",
                    BackgroundTransparency = 1,
                    LayoutOrder = isDisabled and 1 or 0,
                    Size = UDim2.new(1,0,0,21),
                    Parent = menu.Menu,
                })
                if processed == total then
                    table.insert(Library.SpecificCorners, New("UICorner", { TopLeftRadius = UDim.new(0,0), TopRightRadius = UDim.new(0,0), BottomRightRadius = UDim.new(0,Library.CornerRadius/2), BottomLeftRadius = UDim.new(0,Library.CornerRadius/2), Parent = container }))
                end
                if valImg then
                    New("ImageLabel", {
                        BackgroundTransparency = 1,
                        Image = valImg.Url,
                        ImageRectOffset = valImg.ImageRectOffset,
                        ImageRectSize = valImg.ImageRectSize,
                        ImageTransparency = 0.5,
                        Size = UDim2.fromOffset(16,16),
                        Position = UDim2.fromOffset(4,3),
                        Parent = container,
                    })
                end
                local btn = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = valImg and UDim2.new(1,-18,0,21) or UDim2.new(1,0,0,21),
                    Position = valImg and UDim2.fromOffset(18,0) or UDim2.fromOffset(0,0),
                    Text = formatted,
                    TextSize = 14,
                    TextTransparency = 0.5,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = container,
                })
                New("UIPadding", { PaddingLeft = UDim.new(0,7), PaddingRight = UDim.new(0,7), Parent = btn })
                local selected
                if info.Multi then selected = dropdown.Value[val] else selected = dropdown.Value == val end
                function tb:UpdateButton()
                    if info.Multi then selected = dropdown.Value[val] else selected = dropdown.Value == val end
                    container.BackgroundTransparency = selected and 0 or 1
                    btn.TextTransparency = isDisabled and 0.8 or (selected and 0 or 0.5)
                    if valImg then valImg.ImageTransparency = isDisabled and 0.8 or (selected and 0 or 0.5) end
                end
                tb.Index = count
                tb.Value = val
                if not isDisabled then
                    btn.MouseButton1Click:Connect(function()
                        if dragSelecting then return end
                        local try = not selected
                        if not (dropdown:GetActiveValues(true) == 1 and not try and not info.AllowNull) then
                            selected = try
                            if info.Multi then dropdown.Value[val] = selected and true or nil
                            else dropdown.Value = selected and val or nil end
                            for _, ob in buttons do ob:UpdateButton() end
                        end
                        tb:UpdateButton()
                        dropdown:Display()
                        Library:UpdateDependencyBoxes()
                        dropdown:RunChanged()
                    end)
                    if info.Multi and dropdown.DragSelect and not Library.IsMobile then
                        btn.InputBegan:Connect(function(startInput)
                            if not IsMouseInput(startInput) then return end
                            dragSelecting = true
                            dragStartIdx = tb.Index
                            table.clear(dragInitialValues)
                            for _, ot in buttons do
                                dragInitialValues[ot.Value] = dropdown.Value[ot.Value]
                            end
                            UpdateDrag(tb.Index)
                            if dragEndConn then dragEndConn:Disconnect() end
                            if dragChangeConn then dragChangeConn:Disconnect() end
                            dragChangeConn = Library:GiveSignal(UserInputService.InputChanged:Connect(function(changeInput)
                                if not IsMovementInput(changeInput) and changeInput ~= startInput then return end
                                local pos = changeInput.Position
                                for ob, ot in buttons do
                                    if Library:MouseIsOverFrame(ob, pos) then
                                        UpdateDrag(ot.Index)
                                        break
                                    end
                                end
                            end))
                            dragEndConn = Library:GiveSignal(UserInputService.InputEnded:Connect(function(endInput)
                                if endInput ~= startInput and not (IsMouseInput(endInput) and endInput.UserInputType == startInput.UserInputType) then return end
                                Library:UpdateDependencyBoxes()
                                dropdown:RunChanged()
                                StopDragSelect()
                            end))
                            table.insert(dropdown.Connections, dragEndConn)
                            table.insert(dropdown.Connections, dragChangeConn)
                        end)
                    end
                end
                tb:UpdateButton()
                dropdown:Display()
                buttons[btn] = tb
            end
            dropdown:RecalculateListSize(count)
        end

        function dropdown:RunChanged()
            Library:SafeCallback(dropdown.Callback, dropdown.Value)
            Library:SafeCallback(dropdown.Changed, dropdown.Value)
        end

        function dropdown:SetValue(val)
            if info.Multi then
                local t = {}
                for k,v in pairs(val or {}) do
                    if type(v) ~= "boolean" then t[v] = true
                    elseif v and table.find(dropdown.Values, k) then t[k] = true end
                end
                dropdown.Value = t
            else
                if table.find(dropdown.Values, val) then dropdown.Value = val
                elseif not val then dropdown.Value = nil end
            end
            dropdown:Display()
            for _, btn in buttons do btn:UpdateButton() end
            if not dropdown.Disabled then
                Library:UpdateDependencyBoxes()
                dropdown:RunChanged()
            end
        end

        function dropdown:SetValues(vals)
            dropdown.Values = vals
            dropdown:BuildDropdownList()
        end
        function dropdown:AddValues(vals)
            if type(vals) == "table" then for _, v in vals do table.insert(dropdown.Values, v) end
            elseif type(vals) == "string" then table.insert(dropdown.Values, vals) end
            dropdown:BuildDropdownList()
        end
        function dropdown:SetDisabledValues(vals)
            dropdown.DisabledValues = vals
            dropdown:BuildDropdownList()
        end
        function dropdown:AddDisabledValues(vals)
            if type(vals) == "table" then for _, v in vals do table.insert(dropdown.DisabledValues, v) end
            elseif type(vals) == "string" then table.insert(dropdown.DisabledValues, vals) end
            dropdown:BuildDropdownList()
        end
        function dropdown:SetValueImages(imgs)
            if type(imgs) ~= "table" then return end
            dropdown.ValueImages = imgs
            dropdown:BuildDropdownList()
        end
        function dropdown:AddValueImages(imgs)
            if type(imgs) ~= "table" then return end
            for k,v in pairs(imgs) do dropdown.ValueImages[k] = v end
            dropdown:BuildDropdownList()
        end
        function dropdown:SetDisabled(d)
            dropdown.Disabled = d
            if dropdown.TooltipTable then dropdown.TooltipTable.Disabled = d end
            menu:Close()
            displayButton.Active = not d
            dropdown:UpdateColors()
        end
        function dropdown:SetVisible(v)
            dropdown.Visible = v
            holder.Visible = v
            gb:Resize()
        end
        function dropdown:SetText(t)
            dropdown.Text = t
            holder.Size = UDim2.new(1,0,0,t and 39 or 21)
            label.Text = t and t or ""
            label.Visible = not not t
        end
        function dropdown:SetDragSelect(v)
            if not info.Multi or Library.IsMobile then v = false end
            dropdown.DragSelect = v
            dropdown:BuildDropdownList()
        end

        local function ToggleDropdown()
            if dropdown.Disabled then return end
            menu:Toggle()
        end
        table.insert(dropdown.Connections, displayContainer.MouseButton1Click:Connect(ToggleDropdown))
        table.insert(dropdown.Connections, displayButton.MouseButton1Click:Connect(ToggleDropdown))
        if searchBox then
            table.insert(dropdown.Connections, searchBox:GetPropertyChangedSignal("Text"):Connect(dropdown.BuildDropdownList))
        end

        local defaults = {}
        if type(info.Default) == "string" then
            local idx = table.find(dropdown.Values, info.Default)
            if idx then table.insert(defaults, idx) end
        elseif type(info.Default) == "table" then
            for _, v in next, info.Default do
                local idx = table.find(dropdown.Values, v)
                if idx then table.insert(defaults, idx) end
            end
        elseif dropdown.Values[info.Default] ~= nil then
            table.insert(defaults, info.Default)
        end
        if next(defaults) then
            for i=1,#defaults do
                local idx = defaults[i]
                if info.Multi then dropdown.Value[dropdown.Values[idx]] = true
                else dropdown.Value = dropdown.Values[idx]; break end
            end
        end

        if type(dropdown.Tooltip) == "string" or type(dropdown.DisabledTooltip) == "string" then
            dropdown.TooltipTable = Library:AddTooltip(dropdown.Tooltip, dropdown.DisabledTooltip, displayContainer)
            dropdown.TooltipTable.Disabled = dropdown.Disabled
        end
        dropdown:UpdateColors()
        dropdown:Display()
        dropdown:BuildDropdownList()
        gb:Resize()
        dropdown.Holder = holder
        table.insert(gb.Elements, dropdown)
        dropdown.Default = defaults
        dropdown.DefaultValues = dropdown.Values
        Options[idx] = dropdown

        function dropdown:Destroy()
            dropdown.Destroyed = true
            StopDragSelect()
            for _, conn in dropdown.Connections do conn:Disconnect() end
            if dropdown.TooltipTable then dropdown.TooltipTable:Destroy() end
            if menu then menu:Destroy() end
            if holder then holder:Destroy() end
            local idx2 = table.find(gb.Elements, dropdown); if idx2 then table.remove(gb.Elements, idx2) end
            gb:Resize()
            Options[idx] = nil
        end
        return dropdown
    end

    function Funcs:AddViewport(idx, info)
        if self.Destroyed then return nil end
        info = Library:Validate(info, Templates.Viewport)
        local gb = self
        local container = gb.Container

        local dragging, pinching = false, false
        local lastMousePos, lastPinchDist = nil, 0

        local viewObj = info.Object
        if info.Clone and type(info.Object) == "Instance" then
            if info.Object.Archivable then viewObj = viewObj:Clone()
            else info.Object.Archivable = true; viewObj = viewObj:Clone(); info.Object.Archivable = false end
        end

        local viewport = {
            Connections = {},
            Destroyed = false,
            Object = viewObj,
            Camera = info.Camera or Instance.new("Camera"),
            Interactive = info.Interactive,
            AutoFocus = info.AutoFocus,
            Visible = info.Visible,
            Type = "Viewport",
        }
        assert(type(viewport.Object) == "Instance" and (viewport.Object:IsA("BasePart") or viewport.Object:IsA("Model")), "Object must be BasePart or Model")
        assert(type(viewport.Camera) == "Instance" and viewport.Camera:IsA("Camera"), "Camera must be Camera")

        local function GetModelSize(model)
            if model:IsA("BasePart") then return model.Size end
            return select(2, model:GetBoundingBox())
        end

        local function FocusCamera()
            local size = GetModelSize(viewport.Object)
            local maxExt = math.max(size.X, size.Y, size.Z)
            local dist = maxExt * 2
            local pos = viewport.Object:GetPivot().Position
            viewport.Camera.CFrame = CFrame.new(pos + Vector3.new(0, maxExt/2, dist), pos)
        end

        local holder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,info.Height), Visible = viewport.Visible, Parent = container })
        local box = New("Frame", {
            AnchorPoint = Vector2.new(0,1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0,1),
            Size = UDim2.fromScale(1,1),
            Parent = holder,
        })
        New("UIPadding", { PaddingBottom = UDim.new(0,3), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,4), Parent = box })
        local vpFrame = New("ViewportFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1,1),
            Parent = box,
            CurrentCamera = viewport.Camera,
            Active = viewport.Interactive,
        })
        table.insert(viewport.Connections, vpFrame.MouseEnter:Connect(function()
            if not viewport.Interactive then return end
            for _, side in gb.Tab.Sides do side.ScrollingEnabled = false end
        end))
        table.insert(viewport.Connections, vpFrame.MouseLeave:Connect(function()
            if not viewport.Interactive then return end
            for _, side in gb.Tab.Sides do side.ScrollingEnabled = true end
        end))
        table.insert(viewport.Connections, vpFrame.InputBegan:Connect(function(input)
            if not viewport.Interactive then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                lastMousePos = input.Position
            end
        end))
        table.insert(viewport.Connections, UserInputService.InputEnded:Connect(function(input)
            if Library.Unloaded then return end
            if not viewport.Interactive then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
        table.insert(viewport.Connections, UserInputService.InputChanged:Connect(function(input)
            if Library.Unloaded then return end
            if not viewport.Interactive or not dragging or pinching then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - lastMousePos
                lastMousePos = input.Position
                local pos = viewport.Object:GetPivot().Position
                local cam = viewport.Camera
                local rotY = CFrame.fromAxisAngle(Vector3.new(0,1,0), -delta.X * 0.01)
                cam.CFrame = CFrame.new(pos) * rotY * CFrame.new(-pos) * cam.CFrame
                local rotX = CFrame.fromAxisAngle(cam.CFrame.RightVector, -delta.Y * 0.01)
                local pitched = CFrame.new(pos) * rotX * CFrame.new(-pos) * cam.CFrame
                if pitched.UpVector.Y > 0.1 then cam.CFrame = pitched end
            end
        end))
        table.insert(viewport.Connections, vpFrame.InputChanged:Connect(function(input)
            if not viewport.Interactive then return end
            if input.UserInputType == Enum.UserInputType.MouseWheel then
                viewport.Camera.CFrame += viewport.Camera.CFrame.LookVector * input.Position.Z * 2
            end
        end))
        table.insert(viewport.Connections, UserInputService.TouchPinch:Connect(function(positions, scale, velocity, state)
            if Library.Unloaded then return end
            if not viewport.Interactive or not Library:MouseIsOverFrame(vpFrame, positions[1]) then return end
            if state == Enum.UserInputState.Begin then
                pinching = true; dragging = false; lastPinchDist = (positions[1] - positions[2]).Magnitude
            elseif state == Enum.UserInputState.Change then
                local current = (positions[1] - positions[2]).Magnitude
                local delta = (current - lastPinchDist) * 0.1
                lastPinchDist = current
                viewport.Camera.CFrame += viewport.Camera.CFrame.LookVector * delta
            elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
                pinching = false
            end
        end))

        viewport.Object.Parent = vpFrame
        if viewport.AutoFocus then FocusCamera() end

        function viewport:SetObject(obj, clone)
            assert(obj)
            if clone then obj = obj:Clone() end
            if viewport.Object then viewport.Object:Destroy() end
            viewport.Object = obj
            viewport.Object.Parent = vpFrame
            gb:Resize()
        end
        function viewport:SetHeight(h)
            assert(h > 0)
            holder.Size = UDim2.new(1,0,0,h)
            gb:Resize()
        end
        function viewport:Focus()
            if viewport.Object then FocusCamera() end
        end
        function viewport:SetCamera(cam)
            assert(cam and type(cam) == "Instance" and cam:IsA("Camera"))
            viewport.Camera = cam
            vpFrame.CurrentCamera = cam
        end
        function viewport:SetInteractive(interactive)
            viewport.Interactive = interactive
            vpFrame.Active = interactive
        end
        function viewport:SetVisible(v)
            viewport.Visible = v
            holder.Visible = v
            gb:Resize()
        end

        gb:Resize()
        viewport.Holder = holder
        table.insert(gb.Elements, viewport)
        Options[idx] = viewport
        function viewport:Destroy()
            viewport.Destroyed = true
            for _, conn in viewport.Connections do conn:Disconnect() end
            if holder then holder:Destroy() end
            local idx2 = table.find(gb.Elements, viewport); if idx2 then table.remove(gb.Elements, idx2) end
            gb:Resize()
            Options[idx] = nil
        end
        return viewport
    end

    function Funcs:AddImage(idx, info)
        if self.Destroyed then return nil end
        info = Library:Validate(info, Templates.Image)
        local gb = self
        local container = gb.Container

        local img = {
            Connections = {},
            Destroyed = false,
            Image = info.Image,
            Color = info.Color,
            RectOffset = info.RectOffset,
            RectSize = info.RectSize,
            Height = info.Height,
            ScaleType = info.ScaleType,
            Transparency = info.Transparency,
            BackgroundTransparency = info.BackgroundTransparency,
            Visible = info.Visible,
            Type = "Image",
        }

        local holder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,info.Height), Visible = img.Visible, Parent = container })
        local box = New("Frame", {
            AnchorPoint = Vector2.new(0,1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            BackgroundTransparency = img.BackgroundTransparency,
            Position = UDim2.fromScale(0,1),
            Size = UDim2.fromScale(1,1),
            Parent = holder,
        })
        New("UIPadding", { PaddingBottom = UDim.new(0,3), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,4), Parent = box })
        local icon = Library:GetCustomIcon(img.Image)
        assert(icon, "Invalid image")
        local imageLabel = New("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1,1),
            Image = icon.Url,
            ImageRectOffset = icon.ImageRectOffset,
            ImageRectSize = icon.ImageRectSize,
            ImageTransparency = img.Transparency,
            ImageColor3 = img.Color,
            ScaleType = img.ScaleType,
            Parent = box,
        })

        function img:SetHeight(h) assert(h>0); img.Height=h; holder.Size=UDim2.new(1,0,0,h); gb:Resize() end
        function img:SetImage(newImg)
            local icon = Library:GetCustomIcon(newImg)
            assert(icon)
            img.Image = newImg
            imageLabel.Image = icon.Url
            imageLabel.ImageRectOffset = icon.ImageRectOffset
            imageLabel.ImageRectSize = icon.ImageRectSize
        end
        function img:SetColor(c) img.Color = c; imageLabel.ImageColor3 = c end
        function img:SetRectOffset(o) img.RectOffset = o; imageLabel.ImageRectOffset = o end
        function img:SetRectSize(s) img.RectSize = s; imageLabel.ImageRectSize = s end
        function img:SetScaleType(t) img.ScaleType = t; imageLabel.ScaleType = t end
        function img:SetTransparency(t) img.Transparency = t; imageLabel.ImageTransparency = t end
        function img:SetVisible(v) img.Visible = v; holder.Visible = v; gb:Resize() end

        gb:Resize()
        img.Holder = holder
        table.insert(gb.Elements, img)
        Options[idx] = img
        function img:Destroy()
            img.Destroyed = true
            if holder then holder:Destroy() end
            local idx2 = table.find(gb.Elements, img); if idx2 then table.remove(gb.Elements, idx2) end
            gb:Resize()
            Options[idx] = nil
        end
        return img
    end

    function Funcs:AddVideo(idx, info)
        if self.Destroyed then return nil end
        info = Library:Validate(info, Templates.Video)
        local gb = self
        local container = gb.Container

        local video = {
            Connections = {},
            Destroyed = false,
            Video = info.Video,
            Looped = info.Looped,
            Playing = info.Playing,
            Volume = info.Volume,
            Height = info.Height,
            Visible = info.Visible,
            Type = "Video",
        }

        local holder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,info.Height), Visible = video.Visible, Parent = container })
        local box = New("Frame", {
            AnchorPoint = Vector2.new(0,1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0,1),
            Size = UDim2.fromScale(1,1),
            Parent = holder,
        })
        New("UIPadding", { PaddingBottom = UDim.new(0,3), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,4), Parent = box })
        local vf = New("VideoFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1,1),
            Video = video.Video,
            Looped = video.Looped,
            Volume = video.Volume,
            Playing = video.Playing,
            Parent = box,
        })

        function video:SetHeight(h) assert(h>0); video.Height=h; holder.Size=UDim2.new(1,0,0,h); gb:Resize() end
        function video:SetVideo(v) video.Video=v; vf.Video=v end
        function video:SetLooped(l) video.Looped=l; vf.Looped=l end
        function video:SetVolume(v) video.Volume=v; vf.Volume=v end
        function video:SetPlaying(p) video.Playing=p; vf.Playing=p end
        function video:Play() video:SetPlaying(true) end
        function video:Pause() video:SetPlaying(false) end
        function video:SetVisible(v) video.Visible=v; holder.Visible=v; gb:Resize() end

        gb:Resize()
        video.Holder = holder
        video.VideoFrame = vf
        table.insert(gb.Elements, video)
        Options[idx] = video
        function video:Destroy()
            video.Destroyed = true
            for _, conn in video.Connections do conn:Disconnect() end
            if holder then holder:Destroy() end
            local idx2 = table.find(gb.Elements, video); if idx2 then table.remove(gb.Elements, idx2) end
            gb:Resize()
            Options[idx] = nil
        end
        return video
    end

    function Funcs:AddUIPassthrough(idx, info)
        if self.Destroyed then return nil end
        info = Library:Validate(info, Templates.UIPassthrough)
        local gb = self
        local container = gb.Container
        assert(info.Instance and type(info.Instance) == "Instance" and info.Instance:IsA("GuiBase2d"), "Instance must be GuiBase2d")
        assert(type(info.Height) == "number" and info.Height > 0)

        local pass = {
            Connections = {},
            Destroyed = false,
            Instance = info.Instance,
            Height = info.Height,
            Visible = info.Visible,
            Type = "UIPassthrough",
        }

        local holder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,info.Height), Visible = pass.Visible, Parent = container })
        pass.Instance.Parent = holder

        gb:Resize()
        function pass:SetHeight(h) assert(type(h)=="number" and h>0); pass.Height=h; holder.Size=UDim2.new(1,0,0,h); gb:Resize() end
        function pass:SetInstance(inst)
            assert(inst and type(inst)=="Instance" and inst:IsA("GuiBase2d"))
            if pass.Instance then pass.Instance.Parent = nil end
            pass.Instance = inst
            pass.Instance.Parent = holder
        end
        function pass:SetVisible(v) pass.Visible=v; holder.Visible=v; gb:Resize() end

        pass.Holder = holder
        table.insert(gb.Elements, pass)
        Options[idx] = pass
        function pass:Destroy()
            pass.Destroyed = true
            if pass.Connections then for _, conn in pass.Connections do conn:Disconnect() end end
            if holder then holder:Destroy() end
            local idx2 = table.find(gb.Elements, pass); if idx2 then table.remove(gb.Elements, idx2) end
            gb:Resize()
            Options[idx] = nil
        end
        return pass
    end

    function Funcs:AddDependencyBox()
        if self.Destroyed then return nil end
        local gb = self
        local container = gb.Container
        local depContainer = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1,1), Visible = false, Parent = container })
        local depList = New("UIListLayout", { Padding = UDim.new(0,8), Parent = depContainer })
        local depbox = {
            Connections = {},
            Destroyed = false,
            Visible = false,
            Dependencies = {},
            Holder = depContainer,
            Container = depContainer,
            Elements = {},
            DependencyBoxes = {}
        }
        function depbox:Resize()
            depContainer.Size = UDim2.new(1,0,0, depList.AbsoluteContentSize.Y / Library.DPIScale)
            gb:Resize()
        end
        function depbox:Update(cancelSearch)
            for _, dep in depbox.Dependencies do
                local elem = dep[1]
                local val = dep[2]
                if elem.Type == "Toggle" and elem.Value ~= val then
                    depContainer.Visible = false; depbox.Visible = false; return
                elseif elem.Type == "Dropdown" then
                    if type(elem.Value) == "table" then
                        if not elem.Value[val] then depContainer.Visible = false; depbox.Visible = false; return end
                    else
                        if elem.Value ~= val then depContainer.Visible = false; depbox.Visible = false; return end
                    end
                end
            end
            depbox.Visible = true
            depContainer.Visible = true
            if not Library.Searching then task.defer(function() depbox:Resize() end)
            elseif not cancelSearch then Library:UpdateSearch(Library.SearchText) end
        end
        function depbox:SetupDependencies(deps)
            for _, d in deps do assert(type(d)=="table" and d[1] ~= nil and d[2] ~= nil) end
            depbox.Dependencies = deps
            depbox:Update()
        end
        depContainer:GetPropertyChangedSignal("Visible"):Connect(function() depbox:Resize() end)
        setmetatable(depbox, BaseGroupbox)
        table.insert(gb.DependencyBoxes, depbox)
        table.insert(Library.DependencyBoxes, depbox)
        function depbox:Destroy()
            depbox.Destroyed = true
            for _, conn in depbox.Connections do conn:Disconnect() end
            for _, elem in depbox.Elements do if elem.Destroy then elem:Destroy() end end
            for _, sub in depbox.DependencyBoxes do if sub.Destroy then sub:Destroy() end end
            if depContainer then depContainer:Destroy() end
            local idx = table.find(gb.DependencyBoxes, depbox); if idx then table.remove(gb.DependencyBoxes, idx) end
            local libIdx = table.find(Library.DependencyBoxes, depbox); if libIdx then table.remove(Library.DependencyBoxes, libIdx) end
        end
        return depbox
    end

    function Funcs:AddDependencyGroupbox()
        if self.Destroyed then return nil end
        local gb = self
        local tab = gb.Tab
        local boxHolder = gb.BoxHolder

        local depContainer = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            Size = UDim2.fromScale(1,0),
            Visible = false,
            Parent = boxHolder,
        })
        table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0,Library.CornerRadius), Parent = depContainer }))
        Library:AddOutline(depContainer)
        local depList = New("UIListLayout", { Padding = UDim.new(0,8), Parent = depContainer })
        New("UIPadding", { PaddingBottom = UDim.new(0,7), PaddingLeft = UDim.new(0,7), PaddingRight = UDim.new(0,7), PaddingTop = UDim.new(0,7), Parent = depContainer })

        local depgb = {
            Connections = {},
            Destroyed = false,
            Visible = false,
            Dependencies = {},
            BoxHolder = boxHolder,
            Holder = depContainer,
            Container = depContainer,
            Tab = tab,
            Elements = {},
            DependencyBoxes = {}
        }
        function depgb:Resize()
            depContainer.Size = UDim2.new(1,0,0, (depList.AbsoluteContentSize.Y / Library.DPIScale) + 18)
        end
        function depgb:Update(cancelSearch)
            for _, dep in depgb.Dependencies do
                local elem = dep[1]; local val = dep[2]
                if elem.Type == "Toggle" and elem.Value ~= val then
                    depContainer.Visible = false; depgb.Visible = false; return
                elseif elem.Type == "Dropdown" then
                    if type(elem.Value) == "table" then
                        if not elem.Value[val] then depContainer.Visible = false; depgb.Visible = false; return end
                    else
                        if elem.Value ~= val then depContainer.Visible = false; depgb.Visible = false; return end
                    end
                end
            end
            depgb.Visible = true
            if not Library.Searching then
                depContainer.Visible = true
                depgb:Resize()
            elseif not cancelSearch then Library:UpdateSearch(Library.SearchText) end
        end
        function depgb:SetupDependencies(deps)
            for _, d in deps do assert(type(d)=="table" and d[1] ~= nil and d[2] ~= nil) end
            depgb.Dependencies = deps
            depgb:Update()
        end
        setmetatable(depgb, BaseGroupbox)
        table.insert(tab.DependencyGroupboxes, depgb)
        table.insert(Library.DependencyBoxes, depgb)
        function depgb:Destroy()
            depgb.Destroyed = true
            for _, conn in depgb.Connections do conn:Disconnect() end
            for _, elem in depgb.Elements do if elem.Destroy then elem:Destroy() end end
            for _, sub in depgb.DependencyBoxes do if sub.Destroy then sub:Destroy() end end
            if depContainer then depContainer:Destroy() end
            local idx = table.find(tab.DependencyGroupboxes, depgb); if idx then table.remove(tab.DependencyGroupboxes, idx) end
            local libIdx = table.find(Library.DependencyBoxes, depgb); if libIdx then table.remove(Library.DependencyBoxes, libIdx) end
        end
        return depgb
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(_, key, ...)
        return Funcs[key](...)
    end
end

-- Window creation
function Library:CreateWindow(windowInfo)
    windowInfo = Library:Validate(windowInfo, Templates.Window)
    local viewportSize = workspace.CurrentCamera.ViewportSize
    if RunService:IsStudio() and viewportSize.X <= 5 and viewportSize.Y <= 5 then
        repeat viewportSize = workspace.CurrentCamera.ViewportSize task.wait() until viewportSize.X > 5 and viewportSize.Y > 5
    end
    local maxX = viewportSize.X - 64
    local maxY = viewportSize.Y - 64
    Library.OriginalMinSize = Vector2.new(math.min(Library.OriginalMinSize.X, maxX), math.min(Library.OriginalMinSize.Y, maxY))
    Library.MinSize = Library.OriginalMinSize

    windowInfo.Size = UDim2.fromOffset(
        math.clamp(windowInfo.Size.X.Offset, Library.MinSize.X, maxX),
        math.clamp(windowInfo.Size.Y.Offset, Library.MinSize.Y, maxY)
    )
    if type(windowInfo.Font) == "EnumItem" then windowInfo.Font = Font.fromEnum(windowInfo.Font) end
    windowInfo.CornerRadius = math.min(windowInfo.CornerRadius, 20)
    if windowInfo.Compact ~= nil then windowInfo.SidebarCompacted = windowInfo.Compact end
    if windowInfo.SidebarMinWidth ~= nil then windowInfo.MinSidebarWidth = windowInfo.SidebarMinWidth end
    windowInfo.MinSidebarWidth = math.max(64, windowInfo.MinSidebarWidth)
    windowInfo.SidebarCompactWidth = math.max(48, windowInfo.SidebarCompactWidth)
    windowInfo.SidebarCollapseThreshold = math.clamp(windowInfo.SidebarCollapseThreshold, 0.1, 0.9)
    windowInfo.CompactWidthActivation = math.max(48, windowInfo.CompactWidthActivation)

    Library.CornerRadius = windowInfo.CornerRadius
    Library:SetNotifySide(windowInfo.NotifySide)
    Library.ShowCustomCursor = windowInfo.ShowCustomCursor
    Library.Scheme.Font = windowInfo.Font
    Library.ToggleKeybind = windowInfo.ToggleKeybind
    Library.GlobalSearch = windowInfo.GlobalSearch

    Library.Animations = windowInfo.Animations
    Library.TabTransitionInfo = TweenInfo.new(math.max(0, windowInfo.TabTransitionTime or 0.22), Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    Library.TabSwipeOffset = math.max(1, windowInfo.TabSwipeOffset or 26)
    Library.TabSwipeFrom = windowInfo.TabSwipeFrom or "right"

    local isDefaultSearchbarSize = windowInfo.SearchbarSize == UDim2.fromScale(1,1)
    local mainFrame, dividerLine, titleHolder, windowTitle, windowIcon, rightWrapper, searchBox, currentTabInfo, currentTabLabel, currentTabDesc, resizeButton, tabs, container, bgImage, bottomBg, footerLabel, topBar

    local initialLeftWidth = math.ceil(windowInfo.Size.X.Offset * 0.3)
    local isCompact = windowInfo.SidebarCompacted
    local lastExpandedWidth = initialLeftWidth

    -- Keybinds frame already exists
    Library.KeybindFrame.Visible = false

    mainFrame = New("TextButton", {
        BackgroundColor3 = function() return Library:GetBetterColor(Library.Scheme.BackgroundColor, -1) end,
        Name = "Main",
        Text = "",
        Position = windowInfo.Position,
        Size = windowInfo.Size,
        Visible = false,
        Parent = ScreenGui,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, windowInfo.CornerRadius), Parent = mainFrame }))
    table.insert(Library.Scales, New("UIScale", { Parent = mainFrame }))
    Library:AddOutline(mainFrame)
    Library:MakeLine(mainFrame, { Position = UDim2.fromOffset(0,48), Size = UDim2.new(1,0,0,1) })

    dividerLine = New("Frame", { BackgroundColor3 = "OutlineColor", Position = UDim2.fromOffset(initialLeftWidth,0), Size = UDim2.new(0,1,1,-21), Parent = mainFrame, ZIndex = 2 })

    local bgIcon = Library:GetCustomIcon(windowInfo.BackgroundImage)
    bgImage = New("ImageLabel", {
        Image = bgIcon and bgIcon.Url or "",
        ImageRectOffset = bgIcon and bgIcon.ImageRectOffset or Vector2.zero,
        ImageRectSize = bgIcon and bgIcon.ImageRectSize or Vector2.zero,
        Position = UDim2.fromScale(0,0),
        Size = UDim2.fromScale(1,1),
        ScaleType = Enum.ScaleType.Stretch,
        ZIndex = 999,
        BackgroundTransparency = 1,
        ImageTransparency = 0.75,
        Visible = bgIcon ~= nil,
        Parent = mainFrame,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, windowInfo.CornerRadius), Parent = bgImage }))

    if windowInfo.Center then
        mainFrame.Position = UDim2.new(0.5, -mainFrame.Size.X.Offset/2, 0.5, -mainFrame.Size.Y.Offset/2)
    end

    topBar = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,48), Parent = mainFrame })
    Library:MakeDraggable(mainFrame, topBar, false, true)

    titleHolder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, initialLeftWidth, 1,0), Parent = topBar })
    New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0,6), Parent = titleHolder })

    if windowInfo.Icon then
        local icon = Library:GetCustomIcon(windowInfo.Icon)
        windowIcon = New("ImageLabel", {
            Image = icon.Url,
            ImageRectOffset = icon.ImageRectOffset,
            ImageRectSize = icon.ImageRectSize,
            Size = windowInfo.IconSize,
            Parent = titleHolder,
        })
    else
        windowIcon = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = windowInfo.IconSize,
            Text = windowInfo.Title:sub(1,1),
            TextScaled = true,
            Visible = false,
            Parent = titleHolder,
        })
    end

    local x = Library:GetTextBounds(windowInfo.Title, Library.Scheme.Font, 20, titleHolder.AbsoluteSize.X - (windowInfo.Icon and windowInfo.IconSize.X.Offset + 6 or 0) - 12)
    windowTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, x, 1,0),
        Text = windowInfo.Title,
        TextSize = 20,
        Parent = titleHolder,
    })

    rightWrapper = New("Frame", {
        AnchorPoint = Vector2.new(1,0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -49, 0.5,0),
        Size = UDim2.new(1, -initialLeftWidth - 57 - 1, 1, -16),
        Parent = topBar,
    })
    New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0,8), Parent = rightWrapper })

    currentTabInfo = New("Frame", {
        Size = UDim2.fromScale(windowInfo.DisableSearch and 1 or 0.5, 1),
        Visible = false,
        BackgroundTransparency = 1,
        Parent = rightWrapper,
    })
    New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Grow, Parent = currentTabInfo })
    New("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Center, Parent = currentTabInfo })
    New("UIPadding", { PaddingBottom = UDim.new(0,8), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,8), Parent = currentTabInfo })
    currentTabLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = "",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = currentTabInfo,
    })
    currentTabDesc = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = "",
        TextWrapped = true,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 0.5,
        Parent = currentTabInfo,
    })

    searchBox = New("TextBox", {
        BackgroundColor3 = "MainColor",
        PlaceholderText = "Search",
        Size = windowInfo.SearchbarSize,
        TextScaled = true,
        Visible = not (windowInfo.DisableSearch or false),
        Parent = rightWrapper,
    })
    New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Shrink, Parent = searchBox })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, windowInfo.CornerRadius), Parent = searchBox }))
    New("UIPadding", { PaddingBottom = UDim.new(0,8), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,8), Parent = searchBox })
    New("UIStroke", { Color = "OutlineColor", Parent = searchBox })

    local searchIcon = Library:GetIcon("search")
    if searchIcon then
        New("ImageLabel", {
            Image = searchIcon.Url,
            ImageColor3 = "FontColor",
            ImageRectOffset = searchIcon.ImageRectOffset,
            ImageRectSize = searchIcon.ImageRectSize,
            ImageTransparency = 0.5,
            Size = UDim2.fromScale(1,1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = searchBox,
        })
    end

    local moveIcon = Library:GetIcon("move")
    if moveIcon then
        New("ImageLabel", {
            AnchorPoint = Vector2.new(1,0.5),
            Image = moveIcon.Url,
            ImageColor3 = "OutlineColor",
            ImageRectOffset = moveIcon.ImageRectOffset,
            ImageRectSize = moveIcon.ImageRectSize,
            Position = UDim2.new(1, -10, 0.5,0),
            Size = UDim2.fromOffset(28,28),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = topBar,
        })
    end

    bottomBg = New("Frame", {
        AnchorPoint = Vector2.new(0,1),
        BackgroundColor3 = function() return Library:GetBetterColor(Library.Scheme.BackgroundColor, 4) end,
        Position = UDim2.fromScale(0,1),
        Size = UDim2.new(1,0,0,20 + windowInfo.CornerRadius),
        Parent = mainFrame,
    })
    Library:MakeLine(mainFrame, { AnchorPoint = Vector2.new(0,1), Position = UDim2.new(0,0,1,-20), Size = UDim2.new(1,0,0,1) })
    local bottomBar = New("Frame", { AnchorPoint = Vector2.new(0,1), BackgroundTransparency = 1, Position = UDim2.fromScale(0,1), Size = UDim2.new(1,0,0,20), Parent = mainFrame })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, windowInfo.CornerRadius), Parent = bottomBg }))

    footerLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1,1),
        Text = windowInfo.Footer,
        TextSize = 14,
        TextTransparency = 0.5,
        Parent = bottomBar,
    })

    if windowInfo.Resizable then
        resizeButton = New("TextButton", {
            AnchorPoint = Vector2.new(1,0),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -windowInfo.CornerRadius/4, 0,0),
            Size = UDim2.fromScale(1,1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Text = "",
            Parent = bottomBar,
        })
        Library:MakeResizable(mainFrame, resizeButton, function()
            for _, tab in Library.Tabs do tab:Resize(true) end
        end)
        local resizeIcon = Library:GetIcon("move-diagonal-2")
        if resizeIcon then
            New("ImageLabel", {
                Image = resizeIcon.Url,
                ImageColor3 = "FontColor",
                ImageRectOffset = resizeIcon.ImageRectOffset,
                ImageRectSize = resizeIcon.ImageRectSize,
                ImageTransparency = 0.5,
                Position = UDim2.fromOffset(2,2),
                Size = UDim2.new(1,-4,1,-4),
                Parent = resizeButton,
            })
        end
    end

    tabs = New("ScrollingFrame", {
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "BackgroundColor",
        CanvasSize = UDim2.fromScale(0,0),
        Position = UDim2.fromOffset(0,49),
        ScrollBarThickness = 0,
        Size = UDim2.new(0, initialLeftWidth, 1, -70),
        Parent = mainFrame,
    })
    New("UIListLayout", { Parent = tabs })

    container = New("Frame", {
        AnchorPoint = Vector2.new(1,0),
        BackgroundColor3 = function() return Library:GetBetterColor(Library.Scheme.BackgroundColor, 1) end,
        ClipsDescendants = true,
        Name = "Container",
        Position = UDim2.new(1,0,0,49),
        Size = UDim2.new(1, -initialLeftWidth - 1, 1, -70),
        Parent = mainFrame,
    })
    New("UIPadding", { PaddingBottom = UDim.new(0,0), PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6), PaddingTop = UDim.new(0,0), Parent = container })

    Library.WindowContainer = container

    -- Window table
    local window = {}
    local Fading = false

    local function SetUICorner(uiCorner, corner, halfCurrent, halfValue, value)
        local current = uiCorner[corner]
        if current.Offset == 0 and current.Scale == 0 then return end
        uiCorner[corner] = current.Offset == halfCurrent and halfValue or value
    end

    function window:ChangeTitle(title)
        assert(type(title)=="string")
        windowTitle.Text = title
        windowInfo.Title = title
    end

    function window:SetBackgroundImage(image)
        local valid = false
        if type(image) == "string" then
            local bgIcon = Library:GetCustomIcon(image)
            if bgIcon then
                valid = true
                bgImage.Image = bgIcon.Url
                bgImage.ImageRectOffset = bgIcon.ImageRectOffset
                bgImage.ImageRectSize = bgIcon.ImageRectSize
                bgImage.Visible = true
            elseif image:match("http://") or image:match("https://") then
                local rawFile = image:match("(.+)%..+$")
                local _, domain = image:match("^(https?://)([^/]+)")
                if rawFile and domain then
                    local ext = string.sub(image, #rawFile+1, #image)
                    local fileName = rawFile:gsub("\\","/"):find("/[^/]*$") and image:sub(rawFile:gsub("\\","/"):find("/[^/]*$")+1) or nil
                    if fileName then
                        valid = true
                        local assetName = domain .. fileName
                        if #assetName > 255 then
                            local newLen = 255 - #domain - #ext
                            if newLen < 0 then assetName = domain .. ext
                            else assetName = domain .. string.sub(fileName:sub(1, #fileName - #ext), 1, newLen) .. ext end
                        end
                        if CustomImageManagerAssets[fileName] == nil then
                            CustomImageManager:AddAsset(fileName, 0, image)
                        else
                            CustomImageManager:DownloadAsset(fileName, true)
                        end
                        bgImage.Image = CustomImageManager:GetAsset(fileName)
                        bgImage.ImageRectOffset = Vector2.zero
                        bgImage.ImageRectSize = Vector2.zero
                        bgImage.Visible = true
                    end
                end
            end
        end
        if not valid then
            bgImage.Image = ""
            bgImage.ImageRectOffset = Vector2.zero
            bgImage.ImageRectSize = Vector2.zero
            bgImage.Visible = false
        end
        windowInfo.BackgroundImage = image
    end

    function window:SetFooter(footer)
        assert(type(footer)=="string")
        footerLabel.Text = footer
        windowInfo.Footer = footer
    end

    function window:SetCornerRadius(radius)
        assert(type(radius)=="number")
        radius = math.min(radius, 20)
        local half = UDim.new(0, radius/2)
        local full = UDim.new(0, radius)
        local halfCur = Library.CornerRadius/2
        for _, corner in Library.Corners do
            if corner.CornerRadius.Offset == halfCur then corner.CornerRadius = half
            else corner.CornerRadius = full end
        end
        for _, corner in Library.SpecificCorners do
            SetUICorner(corner, "TopRightRadius", halfCur, half, full)
            SetUICorner(corner, "TopLeftRadius", halfCur, half, full)
            SetUICorner(corner, "BottomRightRadius", halfCur, half, full)
            SetUICorner(corner, "BottomLeftRadius", halfCur, half, full)
        end
        Library.CornerRadius = radius
        windowInfo.CornerRadius = radius
        if resizeButton then resizeButton.Position = UDim2.new(1, -radius/4, 0,0) end
        bottomBg.Size = UDim2.new(1,0,0,20 + radius)
        for _, tab in Library.Tabs do
            if tab.IsKeyTab then continue end
            for _, tb in tab.Tabboxes do tb:UpdateCorners() end
        end
    end

    function window:SetAnimations(animations, tabTime, tabOffset, tabFrom)
        if type(animations) == "table" then
            windowInfo.Animations = animations
            Library.Animations = animations
        end
        if type(tabTime) == "number" then
            local ti = TweenInfo.new(math.max(0, tabTime), Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            windowInfo.TabTransitionInfo = ti
            Library.TabTransitionInfo = ti
        end
        if type(tabOffset) == "number" then
            tabOffset = math.max(1, tabOffset)
            windowInfo.TabSwipeOffset = tabOffset
            Library.TabSwipeOffset = tabOffset
        end
        if type(tabFrom) == "string" then
            tabFrom = tabFrom:lower()
            windowInfo.TabSwipeFrom = tabFrom
            Library.TabSwipeFrom = tabFrom
        end
    end

    local function ApplyCompact()
        isCompact = window:GetSidebarWidth() == windowInfo.SidebarCompactWidth
        if windowInfo.DisableCompactingSnap then
            isCompact = window:GetSidebarWidth() <= windowInfo.CompactWidthActivation
        end
        windowTitle.Visible = not isCompact
        if not windowInfo.Icon then windowIcon.Visible = isCompact end
        for _, button in Library.TabButtons do
            if not button.Icon then continue end
            button.Label.Visible = not isCompact
            button.Padding.PaddingBottom = UDim.new(0, isCompact and 6 or 11)
            button.Padding.PaddingLeft = UDim.new(0, isCompact and 6 or 12)
            button.Padding.PaddingRight = UDim.new(0, isCompact and 6 or 12)
            button.Padding.PaddingTop = UDim.new(0, isCompact and 6 or 11)
            button.Icon.SizeConstraint = isCompact and Enum.SizeConstraint.RelativeXY or Enum.SizeConstraint.RelativeYY
        end
    end

    function window:IsSidebarCompacted() return isCompact end
    function window:SetCompact(state)
        window:SetSidebarWidth(state and windowInfo.SidebarCompactWidth or lastExpandedWidth)
    end
    function window:GetSidebarWidth() return tabs.Size.X.Offset end
    function window:SetSidebarWidth(width)
        width = math.clamp(width, 48, mainFrame.Size.X.Offset - windowInfo.MinContainerWidth - 1)
        dividerLine.Position = UDim2.fromOffset(width, 0)
        titleHolder.Size = UDim2.new(0, width, 1,0)
        rightWrapper.Size = UDim2.new(1, -width - 57 - 1, 1, -16)
        tabs.Size = UDim2.new(0, width, 1, -70)
        container.Size = UDim2.new(1, -width - 1, 1, -70)
        if windowInfo.EnableCompacting then ApplyCompact() end
        if not isCompact then lastExpandedWidth = width end
    end

    function window:ShowTabInfo(name, desc)
        currentTabLabel.Text = name
        currentTabDesc.Text = desc
        if isDefaultSearchbarSize then searchBox.Size = UDim2.fromScale(0.5,1) end
        currentTabInfo.Visible = true
    end

    function window:HideTabInfo()
        currentTabInfo.Visible = false
        if isDefaultSearchbarSize then searchBox.Size = UDim2.fromScale(1,1) end
    end

    function window:AddTab(...)
        local name, icon, desc
        if select("#", ...) == 1 and type(...) == "table" then
            local info = select(1, ...)
            name = info.Name or "Tab"
            icon = info.Icon
            desc = info.Description
        else
            name = select(1, ...)
            icon = select(2, ...)
            desc = select(3, ...)
        end
        icon = Library:GetCustomIcon(icon)

        local tabButton, tabLabel, tabIcon
        local tabContainer, tabCanvas, tabLeft, tabRight

        tabButton = New("TextButton", {
            BackgroundColor3 = "MainColor",
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,40),
            Text = "",
            Parent = tabs,
        })
        local btnPad = New("UIPadding", {
            PaddingBottom = UDim.new(0, isCompact and 6 or 11),
            PaddingLeft = UDim.new(0, isCompact and 6 or 12),
            PaddingRight = UDim.new(0, isCompact and 6 or 12),
            PaddingTop = UDim.new(0, isCompact and 6 or 11),
            Parent = tabButton,
        })
        tabLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(30,0),
            Size = UDim2.new(1,-30,1,0),
            Text = name,
            TextSize = 16,
            TextTransparency = 0.5,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = not isCompact,
            Parent = tabButton,
        })
        if icon then
            tabIcon = New("ImageLabel", {
                Image = icon.Url,
                ImageColor3 = icon.Custom and "WhiteColor" or "AccentColor",
                ImageRectOffset = icon.ImageRectOffset,
                ImageRectSize = icon.ImageRectSize,
                ImageTransparency = 0.5,
                ScaleType = Enum.ScaleType.Fit,
                Size = UDim2.fromScale(1,1),
                SizeConstraint = isCompact and Enum.SizeConstraint.RelativeXY or Enum.SizeConstraint.RelativeYY,
                Parent = tabButton,
            })
        end
        table.insert(Library.TabButtons, { Label = tabLabel, Padding = btnPad, Icon = tabIcon })

        tabCanvas = New("CanvasGroup", {
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            GroupTransparency = 0,
            Size = UDim2.fromScale(1,1),
            Visible = false,
            Parent = container,
        })
        tabContainer = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromScale(0,0), Size = UDim2.fromScale(1,1), Visible = true, Parent = tabCanvas })
        tabLeft = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            CanvasSize = UDim2.fromScale(0,0),
            ScrollBarImageTransparency = 1,
            ScrollBarThickness = 0,
            Size = UDim2.new(0.5, -3, 1,0),
            Parent = tabContainer,
        })
        New("UIListLayout", { Padding = UDim.new(0,2), Parent = tabLeft })
        New("UIPadding", { PaddingBottom = UDim.new(0,2), PaddingLeft = UDim.new(0,2), PaddingRight = UDim.new(0,2), PaddingTop = UDim.new(0,2), Parent = tabLeft })
        New("Frame", { BackgroundTransparency = 1, LayoutOrder = -1, Parent = tabLeft })
        New("Frame", { BackgroundTransparency = 1, LayoutOrder = 1, Parent = tabLeft })

        tabRight = New("ScrollingFrame", {
            AnchorPoint = Vector2.new(1,0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            CanvasSize = UDim2.fromScale(0,0),
            Position = UDim2.fromScale(1,0),
            ScrollBarImageTransparency = 1,
            ScrollBarThickness = 0,
            Size = UDim2.new(0.5, -3, 1,0),
            Parent = tabContainer,
        })
        New("UIListLayout", { Padding = UDim.new(0,2), Parent = tabRight })
        New("UIPadding", { PaddingBottom = UDim.new(0,2), PaddingLeft = UDim.new(0,2), PaddingRight = UDim.new(0,2), PaddingTop = UDim.new(0,2), Parent = tabRight })
        New("Frame", { BackgroundTransparency = 1, LayoutOrder = -1, Parent = tabRight })
        New("Frame", { BackgroundTransparency = 1, LayoutOrder = 1, Parent = tabRight })

        -- Warning box
        local warningHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0,7),
            Size = UDim2.fromScale(1,0),
            Visible = false,
            Parent = tabContainer,
        })
        local warningBox, warningOutline, warningShadow, warningScroll, warningTitle, warningStroke, warningText
        warningBox = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            Position = UDim2.fromOffset(2,0),
            Size = UDim2.new(1,-5,0,0),
            Parent = warningHolder,
        })
        table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, windowInfo.CornerRadius), Parent = warningBox }))
        warningOutline, warningShadow = Library:AddOutline(warningBox)
        warningScroll = New("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1,1),
            CanvasSize = UDim2.new(0,0,0,0),
            ScrollBarThickness = 3,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Parent = warningBox,
        })
        New("UIPadding", { PaddingBottom = UDim.new(0,4), PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6), PaddingTop = UDim.new(0,4), Parent = warningScroll })
        warningTitle = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1,-4,0,14),
            Text = "",
            TextColor3 = Color3.fromRGB(255,50,50),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = warningScroll,
        })
        warningStroke = New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Color = Color3.fromRGB(169,0,0), LineJoinMode = Enum.LineJoinMode.Miter, Parent = warningTitle })
        warningText = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0,16),
            Size = UDim2.new(1,-4,0,0),
            Text = "",
            TextSize = 14,
            TextWrapped = true,
            Parent = warningScroll,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
        })
        New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Color = "DarkColor", LineJoinMode = Enum.LineJoinMode.Miter, Parent = warningText })

        local tab = {
            Description = desc,
            Connections = {},
            Destroyed = false,
            Window = window,
            Canvas = tabCanvas,
            Sides = { tabLeft, tabRight },
            WarningBox = { IsNormal = false, LockSize = false, Visible = false, Title = "WARNING", Text = "" },
            Groupboxes = {},
            Tabboxes = {},
            DependencyGroupboxes = {},
        }

        function tab:UpdateWarningBox(info)
            if type(info.IsNormal) == "boolean" then tab.WarningBox.IsNormal = info.IsNormal end
            if type(info.LockSize) == "boolean" then tab.WarningBox.LockSize = info.LockSize end
            if type(info.Visible) == "boolean" then tab.WarningBox.Visible = info.Visible end
            if type(info.Title) == "string" then tab.WarningBox.Title = info.Title end
            if type(info.Text) == "string" then tab.WarningBox.Text = info.Text end
            warningHolder.Visible = tab.WarningBox.Visible
            warningTitle.Text = tab.WarningBox.Title
            warningText.Text = tab.WarningBox.Text
            tab:Resize(true)
            warningBox.BackgroundColor3 = tab.WarningBox.IsNormal and Library.Scheme.BackgroundColor or Color3.fromRGB(127,0,0)
            warningShadow.Color = tab.WarningBox.IsNormal and Library.Scheme.DarkColor or Color3.fromRGB(85,0,0)
            warningOutline.Color = tab.WarningBox.IsNormal and Library.Scheme.OutlineColor or Color3.fromRGB(255,50,50)
            warningTitle.TextColor3 = tab.WarningBox.IsNormal and Library.Scheme.FontColor or Color3.fromRGB(255,50,50)
            warningStroke.Color = tab.WarningBox.IsNormal and Library.Scheme.OutlineColor or Color3.fromRGB(169,0,0)
            Library.Registry[warningBox] = {}
            Library.Registry[warningShadow] = {}
            Library.Registry[warningOutline] = {}
            Library.Registry[warningTitle] = {}
            Library.Registry[warningStroke] = {}
            Library.Registry[warningBox].BackgroundColor3 = function()
                return tab.WarningBox.IsNormal and Library.Scheme.BackgroundColor or Color3.fromRGB(127,0,0)
            end
            Library.Registry[warningShadow].Color = function()
                return tab.WarningBox.IsNormal and Library.Scheme.DarkColor or Color3.fromRGB(85,0,0)
            end
            Library.Registry[warningOutline].Color = function()
                return tab.WarningBox.IsNormal and Library.Scheme.OutlineColor or Color3.fromRGB(255,50,50)
            end
            Library.Registry[warningTitle].TextColor3 = function()
                return tab.WarningBox.IsNormal and Library.Scheme.FontColor or Color3.fromRGB(255,50,50)
            end
            Library.Registry[warningStroke].Color = function()
                return tab.WarningBox.IsNormal and Library.Scheme.OutlineColor or Color3.fromRGB(169,0,0)
            end
        end

        function tab:RefreshSides()
            local offset = warningHolder.Visible and warningBox.Size.Y.Offset + 8 or 0
            for _, side in tab.Sides do
                side.Position = UDim2.new(side.Position.X.Scale, 0, 0, offset)
                side.Size = UDim2.new(0.5, -3, 1, -offset)
            end
        end

        function tab:Resize(resizeWarning)
            if resizeWarning then
                local maxSize = math.floor(tabContainer.AbsoluteSize.Y / 3.25)
                local _, yText = Library:GetTextBounds(warningText.Text, Library.Scheme.Font, warningText.TextSize, warningText.AbsoluteSize.X)
                local yBox = 24 + yText
                if tab.WarningBox.LockSize and yBox >= maxSize then
                    warningScroll.CanvasSize = UDim2.fromOffset(0, yBox)
                    yBox = maxSize
                else
                    warningScroll.CanvasSize = UDim2.fromOffset(0,0)
                end
                warningText.Size = UDim2.new(1,-4,0,yText)
                warningBox.Size = UDim2.new(1,-5,0,yBox+4)
            end
            tab:RefreshSides()
        end

        local function AddTabbox(self, info)
            local parentObj = self
            local boxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1,0),
                Parent = parentObj.Type == "Groupbox" and parentObj.Container or (info.Side == 1 and tabLeft or tabRight),
            })
            New("UIListLayout", { Padding = UDim.new(0,6), Parent = boxHolder })
            New("UIPadding", { PaddingBottom = UDim.new(0,4), PaddingTop = UDim.new(0,4), Parent = boxHolder })

            local tabboxHolder, tabboxButtons
            tabboxHolder = New("Frame", { BackgroundColor3 = "BackgroundColor", Size = UDim2.fromScale(1,0), Parent = boxHolder })
            table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, windowInfo.CornerRadius), Parent = tabboxHolder }))
            Library:AddOutline(tabboxHolder)
            tabboxButtons = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,34), Parent = tabboxHolder })
            New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalFlex = Enum.UIFlexAlignment.Fill, Parent = tabboxButtons })

            local totalTabs = 0
            local firstTab, lastTab

            local tabbox = {
                Connections = {},
                Destroyed = false,
                ActiveTab = nil,
                BoxHolder = boxHolder,
                Holder = tabboxHolder,
                Tabs = {}
            }

            function tabbox:UpdateCorners()
                for _, t in tabbox.Tabs do t:UpdateCorners() end
            end

            function tabbox:AddTab(name, iconName)
                totalTabs = totalTabs + 1
                local idx = totalTabs
                lastTab = idx
                if not firstTab then firstTab = idx end
                local isNameEmpty = name == nil or Trim(tostring(name)) == ""
                local storeIdx = isNameEmpty and tostring(idx) or name

                local button = New("TextButton", {
                    BackgroundColor3 = "MainColor",
                    BackgroundTransparency = 0,
                    Size = UDim2.fromOffset(0,34),
                    Text = "",
                    Parent = tabboxButtons,
                })
                local btnCorner = New("UICorner", {
                    TopLeftRadius = UDim.new(0, windowInfo.CornerRadius),
                    TopRightRadius = UDim.new(0, windowInfo.CornerRadius),
                    BottomRightRadius = UDim.new(0,0),
                    BottomLeftRadius = UDim.new(0,0),
                    Parent = button,
                })
                table.insert(Library.SpecificCorners, btnCorner)
                local btnContent = New("Frame", {
                    AnchorPoint = Vector2.new(0.5,0.5),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0.5,0.5),
                    Size = UDim2.fromOffset(0,16),
                    Parent = button,
                })
                New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0,8), Parent = btnContent })
                local btnIcon
                local boxIcon = Library:GetCustomIcon(iconName)
                if boxIcon then
                    btnIcon = New("ImageLabel", {
                        Image = boxIcon.Url,
                        ImageColor3 = boxIcon.Custom and "WhiteColor" or "AccentColor",
                        ImageRectOffset = boxIcon.ImageRectOffset,
                        ImageRectSize = boxIcon.ImageRectSize,
                        ImageTransparency = 0.5,
                        Size = isNameEmpty and UDim2.fromOffset(16,16) or UDim2.fromOffset(18,18),
                        Parent = btnContent,
                    })
                end
                local btnLabel
                if not isNameEmpty then
                    btnLabel = New("TextLabel", {
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromOffset(0,16),
                        Text = name,
                        TextSize = 15,
                        TextTransparency = 0.5,
                        Parent = btnContent,
                    })
                end
                local line = Library:MakeLine(button, { AnchorPoint = Vector2.new(0,1), Position = UDim2.new(0,0,1,1), Size = UDim2.new(1,0,0,1) })
                local container = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0,35), Size = UDim2.new(1,0,1,-35), Visible = false, Parent = tabboxHolder })
                local list = New("UIListLayout", { Padding = UDim.new(0,8), Parent = container })
                New("UIPadding", { PaddingBottom = UDim.new(0,7), PaddingLeft = UDim.new(0,7), PaddingRight = UDim.new(0,7), PaddingTop = UDim.new(0,7), Parent = container })

                local subtab = {
                    Connections = {},
                    Destroyed = false,
                    ButtonHolder = button,
                    Container = container,
                    ButtonCorner = btnCorner,
                    Tab = tab,
                    Elements = {},
                    DependencyBoxes = {},
                }
                function subtab:Show()
                    if tabbox.ActiveTab then tabbox.ActiveTab:Hide() end
                    button.BackgroundTransparency = 1
                    if btnLabel then btnLabel.TextTransparency = 0 end
                    if btnIcon then btnIcon.ImageTransparency = 0 end
                    line.Visible = false
                    container.Visible = true
                    tabbox.ActiveTab = subtab
                    subtab:Resize()
                end
                function subtab:Hide()
                    button.BackgroundTransparency = 0
                    if btnLabel then btnLabel.TextTransparency = 0.5 end
                    if btnIcon then btnIcon.ImageTransparency = 0.5 end
                    line.Visible = true
                    container.Visible = false
                    tabbox.ActiveTab = nil
                end
                function subtab:Resize()
                    if tabbox.ActiveTab ~= subtab then return end
                    tabboxHolder.Size = UDim2.new(1,0,0, (list.AbsoluteContentSize.Y / Library.DPIScale) + 49)
                    if parentObj.Type == "Groupbox" then parentObj:Resize() end
                end
                function subtab:UpdateCorners()
                    local r = windowInfo.CornerRadius
                    btnCorner.TopLeftRadius = UDim.new(0, idx == firstTab and r or 0)
                    btnCorner.TopRightRadius = UDim.new(0, idx == lastTab and r or 0)
                end
                function subtab:Destroy()
                    subtab.Destroyed = true
                    for _, conn in subtab.Connections do conn:Disconnect() end
                    for _, elem in subtab.Elements do if elem.Destroy then elem:Destroy() end end
                    for _, dep in subtab.DependencyBoxes do if dep.Destroy then dep:Destroy() end end
                    if container then container:Destroy() end
                    if button then button:Destroy() end
                end

                if not tabbox.ActiveTab then subtab:Show() end
                button.MouseButton1Click:Connect(subtab.Show)
                setmetatable(subtab, BaseGroupbox)
                tabbox.Tabs[storeIdx] = subtab
                tabbox:UpdateCorners()
                return subtab, storeIdx
            end

            function tabbox:Destroy()
                tabbox.Destroyed = true
                for _, conn in tabbox.Connections do conn:Disconnect() end
                for _, t in tabbox.Tabs do if t.Destroy then t:Destroy() end end
                if tabboxHolder then tabboxHolder:Destroy() end
                if boxHolder then boxHolder:Destroy() end
            end

            if info.Name then tab.Tabboxes[info.Name] = tabbox else table.insert(tab.Tabboxes, tabbox) end
            return tabbox
        end

        tab.AddTabbox = AddTabbox

        function tab:AddLeftTabbox(name)
            return tab:AddTabbox({ Side = 1, Name = name })
        end
        function tab:AddRightTabbox(name)
            return tab:AddTabbox({ Side = 2, Name = name })
        end

        function tab:AddGroupbox(info)
            local boxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1,0),
                Parent = info.Side == 1 and tabLeft or tabRight,
            })
            New("UIListLayout", { Padding = UDim.new(0,6), Parent = boxHolder })
            New("UIPadding", { PaddingBottom = UDim.new(0,4), PaddingTop = UDim.new(0,4), Parent = boxHolder })

            local groupHolder, groupLabel, groupContainer, groupList, groupArrow, groupLine
            groupHolder = New("Frame", { BackgroundColor3 = "BackgroundColor", Size = UDim2.fromScale(1,0), Parent = boxHolder })
            table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, windowInfo.CornerRadius), Parent = groupHolder }))
            Library:AddOutline(groupHolder)
            groupLine = Library:MakeLine(groupHolder, { Position = UDim2.fromOffset(0,34), Size = UDim2.new(1,0,0,1) })

            local boxIcon = Library:GetCustomIcon(info.IconName)
            if boxIcon then
                New("ImageLabel", {
                    Image = boxIcon.Url,
                    ImageColor3 = boxIcon.Custom and "WhiteColor" or "AccentColor",
                    ImageRectOffset = boxIcon.ImageRectOffset,
                    ImageRectSize = boxIcon.ImageRectSize,
                    Position = UDim2.fromOffset(6,6),
                    Size = UDim2.fromOffset(22,22),
                    Parent = groupHolder,
                })
            end
            groupLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(boxIcon and 24 or 0, 0),
                Size = UDim2.new(1,0,0,34),
                Text = info.Name,
                TextSize = 15,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = groupHolder,
            })
            New("UIPadding", { PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12), Parent = groupLabel })

            if info.DisableCollapsing ~= true then
                groupArrow = New("ImageButton", {
                    Image = Library:GetIcon("chevron-up") and Library:GetIcon("chevron-up").Url or "",
                    ImageColor3 = "WhiteColor",
                    ImageTransparency = 0.5,
                    Rotation = 180,
                    Position = UDim2.new(1, -(22+6), 0, 6),
                    Size = UDim2.fromOffset(22,22),
                    BackgroundTransparency = 1,
                    Parent = groupHolder,
                })
            end

            groupContainer = New("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0,35), Size = UDim2.new(1,0,1,-35), Parent = groupHolder })
            groupList = New("UIListLayout", { Padding = UDim.new(0,8), Parent = groupContainer })
            New("UIPadding", { PaddingBottom = UDim.new(0,7), PaddingLeft = UDim.new(0,7), PaddingRight = UDim.new(0,7), PaddingTop = UDim.new(0,7), Parent = groupContainer })

            local group = {
                Type = "Groupbox",
                Connections = {},
                Destroyed = false,
                Visible = true,
                Collapsed = false,
                BoxHolder = boxHolder,
                Holder = groupHolder,
                Container = groupContainer,
                Tab = tab,
                DependencyBoxes = {},
                Elements = {}
            }

            local resizeTween, arrowTween

            function group:Resize()
                if resizeTween then StopTween(resizeTween, true); resizeTween = nil end
                local target = UDim2.new(1,0,0, if group.Collapsed then 34 else (groupList.AbsoluteContentSize.Y / Library.DPIScale) + 49)
                groupLine.Visible = not group.Collapsed
                if Library.Animations and Library.Animations.Groupbox then
                    local ti = Library.GroupboxTweenInfo
                    local tw = TweenService:Create(groupHolder, ti, { Size = target })
                    resizeTween = tw
                    local conn = Library:GiveSignal(tw.Completed:Once(function()
                        if conn then conn:Disconnect() end
                        if resizeTween == tw then StopTween(resizeTween, true); resizeTween = nil end
                    end))
                    tw:Play()
                else
                    groupHolder.Size = target
                end
            end

            function group:SetCollapsed(collapsed)
                if info.DisableCollapsing then return end
                group.Collapsed = collapsed
                if arrowTween then StopTween(arrowTween, true); arrowTween = nil end
                local targetRot = collapsed and 0 or 180
                groupContainer.Visible = not collapsed
                if Library.Animations and Library.Animations.Groupbox then
                    local ti = Library.RotatingChevronTweenInfo
                    local tw = TweenService:Create(groupArrow, ti, { Rotation = targetRot })
                    arrowTween = tw
                    local conn = Library:GiveSignal(tw.Completed:Once(function()
                        if conn then conn:Disconnect() end
                        if arrowTween == tw then StopTween(arrowTween, true); arrowTween = nil end
                    end))
                    tw:Play()
                else
                    groupArrow.Rotation = targetRot
                end
                group:Resize()
            end

            function group:ToggleCollapsed()
                if info.DisableCollapsing then return end
                group:SetCollapsed(not group.Collapsed)
            end

            function group:Destroy()
                group.Destroyed = true
                if resizeTween then StopTween(resizeTween, true); resizeTween = nil end
                if arrowTween then StopTween(arrowTween, true); arrowTween = nil end
                for _, conn in group.Connections do conn:Disconnect() end
                for _, elem in group.Elements do if elem.Destroy then elem:Destroy() end end
                for _, dep in group.DependencyBoxes do if dep.Destroy then dep:Destroy() end end
                if groupHolder then groupHolder:Destroy() end
                if boxHolder then boxHolder:Destroy() end
            end

            function group:SetVisible(v)
                group.Visible = v
                boxHolder.Visible = v
                if v and Library.Searching then Library:UpdateSearch(Library.SearchText) end
            end
            function group:Show() group:SetVisible(true) end
            function group:Hide() group:SetVisible(false) end

            if info.DisableCollapsing ~= true then
                groupArrow.MouseButton1Click:Connect(function() group:ToggleCollapsed() end)
            end

            group.AddTabbox = AddTabbox
            setmetatable(group, BaseGroupbox)
            group:Resize()
            tab.Groupboxes[info.Name] = group
            if info.Visible == false then group:Hide() end
            if info.DisableCollapsing ~= true and info.Collapsed == true then group:SetCollapsed(true) end
            return group
        end

        function tab:AddLeftGroupbox(name, iconName, visible, collapsed, disableCollapsing)
            return tab:AddGroupbox({ Side = 1, Name = name, IconName = iconName, Visible = visible, Collapsed = collapsed, DisableCollapsing = disableCollapsing })
        end
        function tab:AddRightGroupbox(name, iconName, visible, collapsed, disableCollapsing)
            return tab:AddGroupbox({ Side = 2, Name = name, IconName = iconName, Visible = visible, Collapsed = collapsed, DisableCollapsing = disableCollapsing })
        end

        function tab:Hover(hovering)
            if Library.ActiveTab == tab then return end
            TweenService:Create(tabLabel, Library.TweenInfo, { TextTransparency = hovering and 0.25 or 0.5 }):Play()
            if tabIcon then
                TweenService:Create(tabIcon, Library.TweenInfo, { ImageTransparency = hovering and 0.25 or 0.5 }):Play()
            end
        end

        function tab:Show()
            if Library.ActiveTab == tab then return end
            if Library.ActiveTab then Library.ActiveTab:Hide() end
            TweenService:Create(tabButton, Library.TweenInfo, { BackgroundTransparency = 0 }):Play()
            TweenService:Create(tabLabel, Library.TweenInfo, { TextTransparency = 0 }):Play()
            if tabIcon then
                TweenService:Create(tabIcon, Library.TweenInfo, { ImageTransparency = 0 }):Play()
            end
            if desc then window:ShowTabInfo(name, desc) end
            Library:PlayTabAnimation(tabCanvas, true)
            tab:RefreshSides()
            Library.ActiveTab = tab
            if Library.Searching then Library:UpdateSearch(Library.SearchText) end
        end

        function tab:Hide()
            TweenService:Create(tabButton, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
            TweenService:Create(tabLabel, Library.TweenInfo, { TextTransparency = 0.5 }):Play()
            if tabIcon then
                TweenService:Create(tabIcon, Library.TweenInfo, { ImageTransparency = 0.5 }):Play()
            end
            Library:PlayTabAnimation(tabCanvas, false)
            window:HideTabInfo()
            Library.ActiveTab = nil
        end

        function tab:SetVisible(v)
            tabButton.Visible = v
            if not v and Library.ActiveTab == tab then tab:Hide() end
        end

        function tab:Destroy()
            tab.Destroyed = true
            for _, conn in tab.Connections do conn:Disconnect() end
            for _, g in tab.Groupboxes do if g.Destroy then g:Destroy() end end
            for _, tb in tab.Tabboxes do if tb.Destroy then tb:Destroy() end end
            for _, dep in tab.DependencyGroupboxes do if dep.Destroy then dep:Destroy() end end
            if tabCanvas then tabCanvas:Destroy() elseif tabContainer then tabContainer:Destroy() end
            if tabButton then
                for i, entry in Library.TabButtons do if entry.Button == tabButton then table.remove(Library.TabButtons, i); break end end
                tabButton:Destroy()
            end
            Library.Tabs[name] = nil
        end

        if not Library.ActiveTab then tab:Show() end
        tabButton.MouseEnter:Connect(function() tab:Hover(true) end)
        tabButton.MouseLeave:Connect(function() tab:Hover(false) end)
        tabButton.MouseButton1Click:Connect(tab.Show)

        Library.Tabs[name] = tab
        return tab
    end

    function window:AddKeyTab(...)
        local name, icon, desc
        if select("#", ...) == 1 and type(...) == "table" then
            local info = select(1, ...)
            name = info.Name or "Tab"
            icon = info.Icon
            desc = info.Description
        else
            name = select(1, ...) or "Tab"
            icon = select(2, ...)
            desc = select(3, ...)
        end
        icon = icon or "key"
        local tabButton, tabLabel, tabIcon, tabCanvas, tabContainer

        icon = if icon == "key" then Library:GetIcon("key") else Library:GetCustomIcon(icon)

        tabButton = New("TextButton", {
            BackgroundColor3 = "MainColor",
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,40),
            Text = "",
            Parent = tabs,
        })
        local btnPad = New("UIPadding", {
            PaddingBottom = UDim.new(0, isCompact and 6 or 11),
            PaddingLeft = UDim.new(0, isCompact and 6 or 12),
            PaddingRight = UDim.new(0, isCompact and 6 or 12),
            PaddingTop = UDim.new(0, isCompact and 6 or 11),
            Parent = tabButton,
        })
        tabLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(30,0),
            Size = UDim2.new(1,-30,1,0),
            Text = name,
            TextSize = 16,
            TextTransparency = 0.5,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = not isCompact,
            Parent = tabButton,
        })
        if icon then
            tabIcon = New("ImageLabel", {
                Image = icon.Url,
                ImageColor3 = icon.Custom and "WhiteColor" or "AccentColor",
                ImageRectOffset = icon.ImageRectOffset,
                ImageRectSize = icon.ImageRectSize,
                ImageTransparency = 0.5,
                Size = UDim2.fromScale(1,1),
                SizeConstraint = isCompact and Enum.SizeConstraint.RelativeXY or Enum.SizeConstraint.RelativeYY,
                Parent = tabButton,
            })
        end
        table.insert(Library.TabButtons, { Label = tabLabel, Padding = btnPad, Icon = tabIcon })

        tabCanvas = New("CanvasGroup", {
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            GroupTransparency = 0,
            Size = UDim2.fromScale(1,1),
            Visible = false,
            Parent = container,
        })
        tabContainer = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            CanvasSize = UDim2.fromScale(0,0),
            ScrollBarThickness = 0,
            Position = UDim2.fromScale(0,0),
            Size = UDim2.fromScale(1,1),
            Visible = true,
            Parent = tabCanvas,
        })
        New("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0,8), VerticalAlignment = Enum.VerticalAlignment.Center, Parent = tabContainer })
        New("UIPadding", { PaddingLeft = UDim.new(0,1), PaddingRight = UDim.new(0,1), Parent = tabContainer })

        local tab = {
            Description = desc,
            IsKeyTab = true,
            Elements = {},
            Window = window,
            Canvas = tabCanvas,
            Container = tabContainer,
        }

        function tab:AddKeyBox(callback)
            assert(type(callback)=="function")
            local holder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.75,0,0,21), Parent = tabContainer })
            local box = New("TextBox", {
                BackgroundColor3 = "MainColor",
                PlaceholderText = "Key",
                Size = UDim2.new(1,-71,1,0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = holder,
            })
            New("UIPadding", { PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), Parent = box })
            New("UIStroke", { Color = "OutlineColor", Parent = box })
            table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0,Library.CornerRadius/2), Parent = box }))
            local btn = New("TextButton", {
                AnchorPoint = Vector2.new(1,0),
                BackgroundColor3 = "MainColor",
                Position = UDim2.fromScale(1,0),
                Size = UDim2.new(0,63,1,0),
                Text = "Execute",
                TextSize = 14,
                Parent = holder,
            })
            New("UIStroke", { Color = "OutlineColor", Parent = btn })
            table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0,Library.CornerRadius/2), Parent = btn }))
            btn.MouseButton1Click:Connect(function() callback(box.Text) end)
        end

        function tab:Destroy()
            if tabCanvas then tabCanvas:Destroy() elseif tabContainer then tabContainer:Destroy() end
            if tabButton then
                for i, entry in Library.TabButtons do if entry.Button == tabButton then table.remove(Library.TabButtons, i); break end end
                tabButton:Destroy()
            end
            Library.Tabs[name] = nil
        end

        tab.RefreshSides = function() end
        tab.Resize = function() end
        tab.UpdateCorners = function() end

        function tab:Hover(hovering)
            if Library.ActiveTab == tab then return end
            TweenService:Create(tabLabel, Library.TweenInfo, { TextTransparency = hovering and 0.25 or 0.5 }):Play()
            if tabIcon then
                TweenService:Create(tabIcon, Library.TweenInfo, { ImageTransparency = hovering and 0.25 or 0.5 }):Play()
            end
        end

        function tab:Show()
            if Library.ActiveTab == tab then return end
            if Library.ActiveTab then Library.ActiveTab:Hide() end
            TweenService:Create(tabButton, Library.TweenInfo, { BackgroundTransparency = 0 }):Play()
            TweenService:Create(tabLabel, Library.TweenInfo, { TextTransparency = 0 }):Play()
            if tabIcon then
                TweenService:Create(tabIcon, Library.TweenInfo, { ImageTransparency = 0 }):Play()
            end
            if desc then window:ShowTabInfo(name, desc) end
            Library:PlayTabAnimation(tabCanvas, true)
            tab:RefreshSides()
            Library.ActiveTab = tab
            if Library.Searching then Library:UpdateSearch(Library.SearchText) end
        end

        function tab:Hide()
            TweenService:Create(tabButton, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
            TweenService:Create(tabLabel, Library.TweenInfo, { TextTransparency = 0.5 }):Play()
            if tabIcon then
                TweenService:Create(tabIcon, Library.TweenInfo, { ImageTransparency = 0.5 }):Play()
            end
            Library:PlayTabAnimation(tabCanvas, false)
            window:HideTabInfo()
            Library.ActiveTab = nil
        end

        function tab:SetVisible(v)
            tabButton.Visible = v
            if not v and Library.ActiveTab == tab then tab:Hide() end
        end

        if not Library.ActiveTab then tab:Show() end
        tabButton.MouseEnter:Connect(function() tab:Hover(true) end)
        tabButton.MouseLeave:Connect(function() tab:Hover(false) end)
        tabButton.MouseButton1Click:Connect(tab.Show)

        Library.Tabs[name] = tab
        return tab
    end

    function window:AddDialog(idx, info)
        info = Library:Validate(info, Templates.Dialog)
        local dialogFrame, dialogOverlay, dialogContainer, buttonsHolder
        local footerButtons = {}

        dialogOverlay = New("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = "DarkColor",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1,1),
            Text = "",
            Active = false,
            ZIndex = 9000,
            Visible = true,
            Parent = mainFrame,
        })
        TweenService:Create(dialogOverlay, Library.TweenInfo, { BackgroundTransparency = 0.5 }):Play()

        dialogFrame = New("TextButton", {
            AnchorPoint = Vector2.new(0.5,0.5),
            BackgroundColor3 = "BackgroundColor",
            Position = UDim2.fromScale(0.5,0.5),
            Size = UDim2.fromOffset(300,0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 9001,
            Parent = dialogOverlay,
        })
        table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, windowInfo.CornerRadius), Parent = dialogFrame }))
        Library:AddOutline(dialogFrame)

        local inner = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1,0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 9002,
            Parent = dialogFrame,
        })
        local scale = New("UIScale", { Scale = 0.95, Parent = dialogFrame })
        TweenService:Create(scale, Library.TweenInfo, { Scale = 1 }):Play()
        New("UIPadding", { PaddingBottom = UDim.new(0,15), PaddingLeft = UDim.new(0,15), PaddingRight = UDim.new(0,15), PaddingTop = UDim.new(0,15), Parent = inner })
        New("UIListLayout", { Padding = UDim.new(0,10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = inner })

        local header = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1,0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = inner })
        New("UIListLayout", { Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = header })
        New("UIPadding", { PaddingBottom = UDim.new(0,5), Parent = header })

        local titleRow = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,20), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = header })
        New("UIListLayout", { Padding = UDim.new(0,6), FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = titleRow })

        if info.Icon then
            local icon = Library:GetCustomIcon(info.Icon)
            if icon then
                New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(16,16),
                    Image = icon.Url,
                    ImageColor3 = info.TitleColor or "FontColor",
                    ImageRectOffset = icon.ImageRectOffset,
                    ImageRectSize = icon.ImageRectSize,
                    LayoutOrder = 1,
                    ZIndex = 9002,
                    Parent = titleRow,
                })
            end
        end

        local titleLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,18),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = info.Title,
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
            ZIndex = 9002,
            Parent = titleRow,
        })
        if info.TitleColor then titleLabel.TextColor3 = info.TitleColor end

        local descLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,14),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = info.Description,
            TextSize = 14,
            TextTransparency = info.DescriptionColor and 0 or 0.2,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            LayoutOrder = 2,
            ZIndex = 9002,
            Parent = header,
        })
        if info.DescriptionColor then descLabel.TextColor3 = info.DescriptionColor end

        dialogContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1,0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 4,
            ZIndex = 9002,
            Parent = inner,
        })
        New("UIListLayout", { Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = dialogContainer })
        New("UIPadding", { PaddingBottom = UDim.new(0,5), Parent = dialogContainer })

        local sep2 = New("Frame", { BackgroundColor3 = "OutlineColor", BackgroundTransparency = 0, BorderSizePixel = 0, Size = UDim2.new(1,0,0,1), LayoutOrder = 5, ZIndex = 9002, Parent = inner })

        buttonsHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 6,
            ZIndex = 9002,
            Parent = inner,
        })
        New("UIListLayout", { Padding = UDim.new(0,8), FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Wraps = true, SortOrder = Enum.SortOrder.LayoutOrder, Parent = buttonsHolder })
        New("UIPadding", { PaddingTop = UDim.new(0,5), Parent = buttonsHolder })

        local dialog = {
            Destroyed = false,
            Elements = {},
            Container = dialogContainer,
        }

        function dialog:Resize()
            local maxW = mainFrame.AbsoluteSize.X * 0.75
            local minW = 400
            local totalBtnW = 0
            local btnCount = 0
            local hasButtons = false
            for _, wrap in footerButtons do
                hasButtons = true
                btnCount = btnCount + 1
                totalBtnW = totalBtnW + wrap.Container.Size.X.Offset
            end
            local targetW = minW
            if hasButtons then
                local req = totalBtnW + ((btnCount-1)*8) + 30
                targetW = math.max(minW, math.min(req, maxW))
            end
            dialogFrame.Size = UDim2.fromOffset(targetW,0)
            local _, descH = Library:GetTextBounds(descLabel.Text, Library.Scheme.Font, 14, targetW - 30)
            descLabel.Size = UDim2.new(1,0,0,descH)
            local hasElem = false
            for _, child in dialogContainer:GetChildren() do
                if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then hasElem = true; break end
            end
            dialogContainer.Visible = hasElem
            buttonsHolder.Visible = hasButtons
            sep2.Visible = hasButtons
        end

        function dialog:SetTitle(title)
            titleLabel.Text = title
            dialog:Resize()
        end
        function dialog:SetDescription(desc)
            descLabel.Text = desc
            dialog:Resize()
        end

        function dialog:Dismiss()
            if dialog.Destroyed then return end
            dialog.Destroyed = true
            if Library.ActiveDialog == dialog then Library.ActiveDialog = nil end
            for _, elem in dialog.Elements do if elem.Destroy then elem:Destroy() end end
            table.clear(dialog.Elements)
            local close = TweenService:Create(scale, Library.TweenInfo, { Scale = 0.95 })
            TweenService:Create(dialogOverlay, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
            close:Play()
            task.delay(Library.TweenInfo.Time, function() dialogOverlay:Destroy() end)
            Library.Dialogues[idx] = nil
        end

        dialogOverlay.MouseButton1Click:Connect(function()
            if info.OutsideClickDismiss then dialog:Dismiss() end
        end)

        function dialog:RemoveFooterButton(btnIdx)
            if footerButtons[btnIdx] then
                footerButtons[btnIdx].Container:Destroy()
                footerButtons[btnIdx] = nil
            end
        end

        function dialog:SetButtonDisabled(btnIdx, disabled)
            if footerButtons[btnIdx] and type(footerButtons[btnIdx].SetDisabled) == "function" then
                footerButtons[btnIdx]:SetDisabled(disabled)
            end
        end

        function dialog:SetButtonOrder(btnIdx, order)
            if footerButtons[btnIdx] and footerButtons[btnIdx].Container then
                footerButtons[btnIdx].Container.LayoutOrder = order
            end
        end

        function dialog:AddFooterButton(btnIdx, btnInfo)
            dialog:RemoveFooterButton(btnIdx)
            local waitTime = btnInfo.WaitTime or 0
            local container = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0,26),
                LayoutOrder = btnInfo.Order or 0,
                ZIndex = 9002,
                Parent = buttonsHolder,
            })
            local btnColor = "MainColor"
            local outlineColor = "OutlineColor"
            local variant = btnInfo.Variant or "Primary"
            if variant == "Primary" then btnColor = "FontColor"; outlineColor = "FontColor"
            elseif variant == "Secondary" then btnColor = "MainColor"; outlineColor = "OutlineColor"
            elseif variant == "Destructive" then btnColor = "DestructiveColor"; outlineColor = "DestructiveColor"
            elseif variant == "Ghost" then btnColor = "BackgroundColor"; outlineColor = "BackgroundColor" end

            local textBtn = New("TextButton", {
                BackgroundColor3 = btnColor,
                BorderColor3 = outlineColor,
                BackgroundTransparency = waitTime > 0 and 0.5 or 0,
                Size = UDim2.fromOffset(0,26),
                Text = "",
                AutoButtonColor = false,
                ZIndex = 9002,
                Parent = container,
            })
            Library:AddOutline(textBtn)
            table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0,Library.CornerRadius), Parent = textBtn }))
            New("UIPadding", { PaddingLeft = UDim.new(0,15), PaddingRight = UDim.new(0,15), Parent = textBtn })

            local textColor = Library.Scheme.FontColor
            if variant == "Primary" then textColor = Library.Scheme.BackgroundColor
            elseif variant == "Destructive" then textColor = Color3.new(1,1,1) end
            local btnLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1,1),
                Text = btnInfo.Title or btnIdx,
                TextColor3 = textColor,
                TextTransparency = waitTime > 0 and 0.5 or 0,
                TextSize = 14,
                ZIndex = 9002,
                Parent = textBtn,
            })
            local labelX,_ = Library:GetTextBounds(btnLabel.Text, Library.Scheme.Font, 14, 250)
            container.Size = UDim2.fromOffset(labelX + 30, 26)
            textBtn.Size = UDim2.fromOffset(labelX + 30, 26)

            local progressBar
            if waitTime > 0 then
                progressBar = New("Frame", {
                    BackgroundColor3 = "AccentColor",
                    BorderSizePixel = 0,
                    Position = UDim2.new(0,0,1,-2),
                    Size = UDim2.new(0,0,0,2),
                    ZIndex = 2,
                    Parent = textBtn,
                })
                table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0,Library.CornerRadius), Parent = progressBar }))
            end

            local isActive = waitTime <= 0
            local wrap = {
                Container = container,
                SetDisabled = function(self, disabled)
                    isActive = not disabled
                    local trans = disabled and 0.5 or 0
                    TweenService:Create(textBtn, Library.TweenInfo, { BackgroundTransparency = trans }):Play()
                    TweenService:Create(btnLabel, Library.TweenInfo, { TextTransparency = trans }):Play()
                end
            }

            local activeColor = type(btnColor) == "Color3" and btnColor or Library.Scheme[btnColor]
            local hoverColor = variant == "Ghost" and Library.Scheme.MainColor or Library:GetBetterColor(activeColor, 10)
            textBtn.MouseEnter:Connect(function()
                if not isActive then return end
                TweenService:Create(textBtn, Library.TweenInfo, { BackgroundColor3 = hoverColor }):Play()
            end)
            textBtn.MouseLeave:Connect(function()
                if not isActive then return end
                TweenService:Create(textBtn, Library.TweenInfo, { BackgroundColor3 = activeColor }):Play()
            end)
            textBtn.MouseButton1Click:Connect(function()
                if not isActive then return end
                if btnInfo.Callback then btnInfo.Callback(dialog) end
                if info.AutoDismiss then dialog:Dismiss() end
            end)

            if waitTime > 0 then
                TweenService:Create(progressBar, TweenInfo.new(waitTime, Enum.EasingStyle.Linear), {
                    Size = UDim2.new(1,0,0,2)
                }):Play()
                task.delay(waitTime, function()
                    wrap:SetDisabled(false)
                    if progressBar then
                        TweenService:Create(progressBar, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
                    end
                end)
            end

            footerButtons[btnIdx] = wrap
        end

        for bIdx, bInfo in info.FooterButtons do
            if type(bIdx) == "number" and bInfo.Id then bIdx = bInfo.Id end
            dialog:AddFooterButton(bIdx, bInfo)
        end

        setmetatable(dialog, BaseGroupbox)
        Library.Dialogues[idx] = dialog
        dialog:Resize()
        Library.ActiveDialog = dialog
        return dialog
    end

    -- Toggle function
    local GuiProperties = {"BackgroundTransparency"}
    local ImageProperties = {"BackgroundTransparency", "ImageTransparency"}
    local TextProperties = {"BackgroundTransparency", "TextTransparency"}
    local StrokeProperties = {"Transparency"}

    local TransparencyCache = {}
    local function FadeInstance(desc, props)
        local cache = TransparencyCache[desc]
        if not cache then cache = {}; TransparencyCache[desc] = cache end
        for _, prop in props do
            if not Library.Toggled then cache[prop] = desc[prop] end
            if cache[prop] ~= nil and cache[prop] ~= 1 then
                TweenService:Create(desc, Library.WindowAnimationInfo, {
                    [prop] = Library.Toggled and cache[prop] or 1
                }):Play()
            end
        end
    end

    function window:Toggle(value)
        if Fading then return end
        if Library.ActiveLoading then
            if value == true then return end
            if not Library.Toggled then return end
        end
        if type(value) == "boolean" then Library.Toggled = value
        else Library.Toggled = not Library.Toggled end

        if Library.Animations and Library.Animations.ToggleWindow then
            local fadeTime = Library.WindowAnimationInfo.Time
            Fading = true
            if Library.Toggled then mainFrame.Visible = true end
            if Library.Toggled then
                FadeInstance(mainFrame, {"BackgroundTransparency"})
                task.wait(fadeTime/2)
            else
                task.delay(fadeTime/2, FadeInstance, mainFrame, {"BackgroundTransparency"})
            end
            for _, instance in mainFrame:GetDescendants() do
                if instance == topBar then continue end
                if instance:IsA("GuiObject") then
                    local cn = instance.ClassName
                    if cn == "ImageLabel" or cn == "ImageButton" then
                        FadeInstance(instance, ImageProperties)
                    elseif cn == "TextLabel" or cn == "TextBox" or cn == "TextButton" then
                        FadeInstance(instance, TextProperties)
                    else
                        FadeInstance(instance, GuiProperties)
                    end
                elseif instance.ClassName == "UIStroke" then
                    FadeInstance(instance, StrokeProperties)
                end
            end
            task.delay(fadeTime, function()
                mainFrame.Visible = Library.Toggled
                Fading = false
            end)
        else
            mainFrame.Visible = Library.Toggled
        end

        if windowInfo.UnlockMouseWhileOpen then
            ModalElement.Modal = Library.Toggled
        end

        if Library.Toggled and not Library.IsMobile then
            local oldMouse = UserInputService.MouseIconEnabled
            local binding = Library.ShowCursorBinding
            pcall(function() RunService:UnbindFromRenderStep(binding) end)
            RunService:BindToRenderStep(binding, Enum.RenderPriority.Last.Value, function()
                UserInputService.MouseIconEnabled = not Library.ShowCustomCursor
                Cursor.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
                Cursor.Visible = Library.ShowCustomCursor
                if not (Library.Toggled and ScreenGui and ScreenGui.Parent) then
                    UserInputService.MouseIconEnabled = oldMouse
                    Cursor.Visible = false
                    RunService:UnbindFromRenderStep(binding)
                end
            end)
        elseif not Library.Toggled then
            TooltipLabel.Visible = false
            for _, opt in Library.Options do
                if opt.Type == "ColorPicker" then
                    opt.ColorMenu:Close(); opt.ContextMenu:Close()
                elseif opt.Type == "Dropdown" or opt.Type == "KeyPicker" then
                    opt.Menu:Close()
                end
            end
        end
    end

    function Library:Toggle(value)
        return window:Toggle(value)
    end

    -- Sidebar resize
    if windowInfo.EnableSidebarResize then
        local threshold = (windowInfo.MinSidebarWidth + windowInfo.SidebarCompactWidth) * windowInfo.SidebarCollapseThreshold
        local startPos, startWidth
        local dragging = false
        local changed

        local grabber = New("TextButton", {
            AnchorPoint = Vector2.new(0.5,0),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5,0),
            Size = UDim2.new(0,8,1,0),
            Text = "",
            Parent = dividerLine,
        })
        grabber.MouseEnter:Connect(function()
            TweenService:Create(dividerLine, Library.TweenInfo, {
                BackgroundColor3 = Library:GetLighterColor(Library.Scheme.OutlineColor),
            }):Play()
        end)
        grabber.MouseLeave:Connect(function()
            if dragging then return end
            TweenService:Create(dividerLine, Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.OutlineColor,
            }):Play()
        end)

        grabber.InputBegan:Connect(function(input)
            if not IsClickInput(input) then return end
            Library.CantDragForced = true
            startPos = input.Position
            startWidth = window:GetSidebarWidth()
            dragging = true
            changed = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then return end
                Library.CantDragForced = false
                TweenService:Create(dividerLine, Library.TweenInfo, {
                    BackgroundColor3 = Library.Scheme.OutlineColor,
                }):Play()
                dragging = false
                if changed and changed.Connected then changed:Disconnect(); changed = nil end
            end)
        end)

        Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
            if not Library.Toggled or not (ScreenGui and ScreenGui.Parent) then
                dragging = false
                if changed and changed.Connected then changed:Disconnect(); changed = nil end
                return
            end
            if dragging and IsHoverInput(input) then
                local delta = input.Position - startPos
                local width = startWidth + delta.X
                if windowInfo.DisableCompactingSnap then
                    window:SetSidebarWidth(width)
                    return
                end
                if width > threshold then
                    window:SetSidebarWidth(math.max(width, windowInfo.MinSidebarWidth))
                else
                    window:SetSidebarWidth(windowInfo.SidebarCompactWidth)
                end
            end
        end))
    end

    if windowInfo.EnableCompacting and windowInfo.SidebarCompacted then
        window:SetSidebarWidth(windowInfo.SidebarCompactWidth)
    end

    if windowInfo.AutoShow and not Library.ActiveLoading then
        task.spawn(Library.Toggle)
    end

    -- Mobile buttons
    if Library.IsMobile then
        local toggleBtn = Library:AddDraggableButton("Toggle", function() Library:Toggle() end, true, true)
        local lockBtn = Library:AddDraggableButton("Lock", function(self)
            Library.CantDragForced = not Library.CantDragForced
            self:SetText(Library.CantDragForced and "Unlock" or "Lock")
        end, true, true)
        if windowInfo.MobileButtonsSide == "Right" then
            toggleBtn.Button.AnchorPoint = Vector2.new(1,0)
            toggleBtn.Button.Position = UDim2.new(1,-6,0,6)
            lockBtn.Button.AnchorPoint = Vector2.new(1,0)
            lockBtn.Button.Position = UDim2.new(1, -(toggleBtn.Button.Size.X.Offset + 12), 0,6)
        else
            toggleBtn.Button.AnchorPoint = Vector2.new(0,0)
            toggleBtn.Button.Position = UDim2.fromOffset(6,6)
            lockBtn.Button.AnchorPoint = Vector2.new(0,0)
            lockBtn.Button.Position = UDim2.fromOffset(toggleBtn.Button.Size.X.Offset + 12, 6)
        end
        if not windowInfo.ShowMobileButtons then
            toggleBtn.Button.Visible = false
            lockBtn.Button.Visible = false
        end
    end

    Library:GiveSignal(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Library:UpdateSearch(searchBox.Text)
    end))

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(input)
        if Library.Unloaded then return end
        if UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == Library.ToggleKeybind then Library:Toggle() end
    end))

    Library:GiveSignal(UserInputService.WindowFocused:Connect(function()
        Library.IsRobloxFocused = true
    end))
    Library:GiveSignal(UserInputService.WindowFocusReleased:Connect(function()
        Library.IsRobloxFocused = false
    end))

    Library.Window = window
    return window
end

-- Loading screen
function Library:CreateLoading(loadingInfo)
    if Library.ActiveLoading then
        warn("Loading GUI already exists")
        return Library.ActiveLoading
    end
    loadingInfo = Library:Validate(loadingInfo, Templates.Loading)

    local loading = {
        CurrentStep = loadingInfo.CurrentStep,
        TotalSteps = loadingInfo.TotalSteps,
        ShowSidebar = loadingInfo.ShowSidebar,
        AutoResizeHeight = loadingInfo.AutoResizeHeight,
        IsError = false,
        Destroyed = false,
        WindowWidth = loadingInfo.WindowWidth,
        WindowHeight = loadingInfo.WindowHeight,
        BaseWindowHeight = loadingInfo.WindowHeight,
        WindowErrorHeight = loadingInfo.WindowHeight,
        ContentWidth = loadingInfo.ContentWidth,
        SidebarWidth = loadingInfo.SidebarWidth,
    }

    local screenGui = New("ScreenGui", {
        Name = "AzexLoading",
        DisplayOrder = 999,
        ResetOnSpawn = false,
    })
    ParentUI(screenGui)
    loading.ScreenGui = screenGui
    screenGui.DescendantRemoving:Connect(function(inst) Library:RemoveFromRegistry(inst) end)

    local mainFrame = New("TextButton", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = function() return Library:GetBetterColor(Library.Scheme.BackgroundColor, -1) end,
        Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromOffset(
            loading.ShowSidebar and (loading.ContentWidth + loading.SidebarWidth) or loading.WindowWidth,
            loading.WindowHeight
        ),
        ClipsDescendants = true,
        Text = "",
        AutoButtonColor = false,
        Parent = screenGui,
    })
    Library:AddOutline(mainFrame)
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = mainFrame }))
    local mainScale = New("UIScale", { Scale = Library.IsMobile and 0.8 or 1, Parent = mainFrame })
    table.insert(Library.Scales, mainScale)
    Library.ScalesOffset[mainScale] = Library.IsMobile and 0.2 or 0

    local container = New("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0,0),
        Size = UDim2.new(0, loading.ContentWidth, 1,0),
        Parent = mainFrame,
    })
    local sidebar = New("Frame", {
        Name = "SideBar",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(loading.ContentWidth, 0),
        Size = UDim2.new(0, loading.ShowSidebar and loading.SidebarWidth or 0, 1,0),
        ClipsDescendants = true,
        Visible = loading.ShowSidebar,
        Parent = mainFrame,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = sidebar }))
    Library:AddOutline(sidebar)
    local sidebarDivider = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0,0),
        Size = UDim2.new(0,1,1,0),
        Visible = loading.ShowSidebar,
        Parent = sidebar,
    })

    local topBar = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,48), ZIndex = 2, Parent = container })
    Library:MakeDraggable(mainFrame, topBar, true, true)
    local titleHolder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Parent = topBar })
    New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0,6), Parent = titleHolder })
    New("UIPadding", { PaddingLeft = UDim.new(0,12), Parent = titleHolder })

    if loadingInfo.Icon then
        local icon = Library:GetCustomIcon(loadingInfo.Icon)
        New("ImageLabel", {
            Image = icon.Url,
            ImageRectOffset = icon.ImageRectOffset,
            ImageRectSize = icon.ImageRectSize,
            Size = loadingInfo.IconSize,
            Parent = titleHolder,
        })
    else
        New("TextLabel", {
            BackgroundTransparency = 1,
            Size = loadingInfo.IconSize,
            Text = loadingInfo.Title:sub(1,1),
            TextScaled = true,
            Visible = false,
            Parent = titleHolder,
        })
    end
    local titleX = Library:GetTextBounds(loadingInfo.Title, Library.Scheme.Font, 20, titleHolder.AbsoluteSize.X - (loadingInfo.Icon and (loadingInfo.IconSize.X.Offset + 6) or 0) - 12)
    New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, titleX, 1,0),
        Text = loadingInfo.Title,
        TextSize = 20,
        Parent = titleHolder,
    })
    Library:MakeLine(container, { Position = UDim2.fromOffset(0,48), Size = UDim2.new(1,0,0,1) })

    local inner = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0,49),
        Size = UDim2.new(1,0,1,-49),
        Parent = container,
    })
    New("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0,12), Parent = inner })

    local iconHolder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(64,64), Parent = inner })
    local loaderIcon = Library:GetCustomIcon(loadingInfo.LoadingIcon)
    local loadingIcon = New("ImageLabel", {
        Name = "LoaderIcon",
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.fromScale(1,1),
        Image = loaderIcon.Url,
        ImageRectOffset = loaderIcon.ImageRectOffset,
        ImageRectSize = loaderIcon.ImageRectSize,
        ImageColor3 = loadingInfo.LoadingIconColor or ((loadingInfo.LoadingIcon == Templates.Loading.LoadingIcon) and "AccentColor" or "WhiteColor"),
        Parent = iconHolder,
    })
    local rotationTween
    if loadingInfo.LoadingIconTweenTime > 0 then
        rotationTween = TweenService:Create(loadingIcon, TweenInfo.new(loadingInfo.LoadingIconTweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 })
        rotationTween:Play()
    end

    local msgLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = loading.AutoResizeHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY,
        Size = loading.AutoResizeHeight and UDim2.new(1,-60,0,0) or UDim2.fromOffset(0,0),
        Text = "",
        TextSize = 18,
        TextWrapped = loading.AutoResizeHeight,
        Parent = inner,
    })
    local descLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = loading.AutoResizeHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY,
        Size = loading.AutoResizeHeight and UDim2.new(1,-60,0,0) or UDim2.fromOffset(0,0),
        Text = "",
        TextSize = 14,
        TextTransparency = 0.5,
        TextWrapped = loading.AutoResizeHeight,
        Parent = inner,
    })

    local sliderBar = New("Frame", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.new(0.7,0,0,15),
        Parent = inner,
    })
    Library:AddOutline(sliderBar)
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0,Library.CornerRadius/2), Parent = sliderBar }))
    local sliderFill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0,1),
        Parent = sliderBar,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0,Library.CornerRadius/2), Parent = sliderFill }))
    local progressLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1,1),
        Text = "",
        TextSize = 14,
        ZIndex = 2,
        Parent = sliderBar,
    })
    New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Color = "DarkColor", LineJoinMode = Enum.LineJoinMode.Miter, Parent = progressLabel })

    -- Sidebar content
    local sidebarScroll = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0,0,0,0),
        Size = UDim2.fromScale(1,1),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = "OutlineColor",
        Parent = sidebar,
    })
    local sidebarList = New("UIListLayout", { Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sidebarScroll })
    New("UIPadding", { PaddingBottom = UDim.new(0,12), PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12), PaddingTop = UDim.new(0,12), Parent = sidebarScroll })
    local sidebarObj = {
        Elements = {},
        DependencyBoxes = {},
        Tabboxes = {},
        BoxHolder = sidebarScroll,
        Container = sidebarScroll,
        Resize = function()
            sidebarScroll.CanvasSize = UDim2.fromOffset(0, sidebarList.AbsoluteContentSize.Y + 24)
        end,
        Tab = {
            Elements = {},
            DependencyBoxes = {},
            DependencyGroupboxes = {},
            Tabboxes = {},
        },
    }
    sidebarList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sidebarObj:Resize() end)
    setmetatable(sidebarObj, BaseGroupbox)
    loading.Sidebar = sidebarObj

    -- Error frame
    local errorFrame = New("Frame", {
        Name = "Error",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0,49),
        Size = UDim2.new(1,0,1,-49),
        ClipsDescendants = true,
        Visible = false,
        Parent = container,
    })
    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15,15),
        Size = UDim2.new(1,-30,0,18),
        Text = "Error",
        TextColor3 = "RedColor",
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = errorFrame,
    })
    local errorLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15,39),
        Size = UDim2.new(1,-30,1,-90),
        Text = "Error Message",
        TextSize = 14,
        TextTransparency = 0.2,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = errorFrame,
    })
    local errDivider = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5,0),
        Position = UDim2.new(0.5,0,1,-48),
        Size = UDim2.new(1,-30,0,1),
        Visible = false,
        Parent = errorFrame,
    })
    local errButtons = New("Frame", {
        AnchorPoint = Vector2.new(0.5,1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5,0,1,0),
        Size = UDim2.new(1,0,0,42),
        Visible = false,
        Parent = errorFrame,
    })
    New("UIListLayout", { Padding = UDim.new(0,8), FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = errButtons })
    New("UIPadding", { PaddingTop = UDim.new(0,5), PaddingBottom = UDim.new(0,15), PaddingRight = UDim.new(0,15), Parent = errButtons })

    function loading:UpdateLayout()
        if loading.IsError then loading:RecalculateErrorHeight() end
        local showSide = loading.ShowSidebar
        local finalW = showSide and (loading.ContentWidth + loading.SidebarWidth) or loading.WindowWidth
        local finalH = loading.IsError and loading.WindowErrorHeight or loading.WindowHeight
        if showSide then
            sidebar.Visible = true
            sidebarDivider.Visible = true
        end
        TweenService:Create(mainFrame, Library.TweenInfo, { Size = UDim2.fromOffset(finalW, finalH) }):Play()
        TweenService:Create(sidebar, Library.TweenInfo, { Position = UDim2.fromOffset(loading.ContentWidth,0), Size = UDim2.new(0, showSide and loading.SidebarWidth or 0, 1,0) }):Play()
        TweenService:Create(container, Library.TweenInfo, { Size = UDim2.new(0, showSide and loading.ContentWidth or loading.WindowWidth, 1,0) }):Play()
        if not showSide then
            task.delay(Library.TweenInfo.Time, function()
                if not loading.ShowSidebar then
                    sidebar.Visible = false
                    sidebarDivider.Visible = false
                end
            end)
        end
    end

    function loading:RecalculateLoadingHeight()
        if not loading.AutoResizeHeight then return end
        local req = 49 + 48 + inner.UIListLayout.AbsoluteContentSize.Y
        loading.WindowHeight = math.max(loading.BaseWindowHeight, req)
    end

    function loading:SetMessage(text)
        msgLabel.Text = text
        if loading.AutoResizeHeight then loading:RecalculateLoadingHeight(); loading:UpdateLayout() end
    end
    function loading:SetDescription(text)
        descLabel.Text = text
        if loading.AutoResizeHeight then loading:RecalculateLoadingHeight(); loading:UpdateLayout() end
    end
    function loading:SetLoadingIcon(icon)
        local data = Library:GetCustomIcon(icon)
        loadingIcon.Image = data.Url
        loadingIcon.ImageRectOffset = data.ImageRectOffset
        loadingIcon.ImageRectSize = data.ImageRectSize
    end
    function loading:SetLoadingIconTweenTime(t)
        if rotationTween then StopTween(rotationTween, true); rotationTween = nil end
        if t > 0 then
            rotationTween = TweenService:Create(loadingIcon, TweenInfo.new(t, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 })
            rotationTween:Play()
        else
            loadingIcon.Rotation = 0
        end
    end
    function loading:SetLoadingIconColor(color)
        loadingIcon.ImageColor3 = color
    end
    function loading:SetCurrentStep(step)
        loading.CurrentStep = math.clamp(step, 0, loading.TotalSteps)
        local progress = loading.CurrentStep / loading.TotalSteps
        TweenService:Create(sliderFill, Library.TweenInfo, { Size = UDim2.fromScale(progress,1) }):Play()
        progressLabel.Text = string.format("%d/%d", loading.CurrentStep, loading.TotalSteps)
    end
    function loading:SetTotalSteps(steps)
        loading.TotalSteps = steps
        loading:SetCurrentStep(loading.CurrentStep)
    end

    function loading:SetWindowHeight(h)
        loading.WindowHeight = h
        loading:UpdateLayout()
    end
    function loading:SetWindowWidth(w)
        loading.WindowWidth = w
        loading:UpdateLayout()
    end
    function loading:SetContentWidth(w)
        loading.ContentWidth = w
        loading:UpdateLayout()
    end
    function loading:SetSidebarWidth(w)
        loading.SidebarWidth = w
        loading:UpdateLayout()
    end

    function loading:ShowSidebarPage(bool)
        loading.ShowSidebar = bool
        loading:UpdateLayout()
    end

    function loading:ShowErrorPage(enabled)
        loading.IsError = enabled
        inner.Visible = not enabled
        errorFrame.Visible = enabled
        if loading.ShowSidebar then loading:ShowSidebarPage(not enabled) else loading:UpdateLayout() end
    end

    function loading:RecalculateErrorHeight()
        local targetW = (loading.ShowSidebar and loading.ContentWidth or loading.WindowWidth) - 30
        local _, errH = Library:GetTextBounds(errorLabel.Text, Library.Scheme.Font, 14, targetW)
        errorLabel.Size = UDim2.new(1,-30,0,errH)
        local hasButtons = errButtons.Visible
        local req = 49 + 15 + 18 + 6 + errH + 15 + (hasButtons and 48 or 0)
        loading.WindowErrorHeight = req
    end

    function loading:SetErrorMessage(text)
        errorLabel.Text = text
        loading:UpdateLayout()
    end

    function loading:SetErrorButtons(buttons)
        assert(type(buttons)=="table")
        for _, child in errButtons:GetChildren() do if child:IsA("Frame") then child:Destroy() end end
        local has = TableSize(buttons) > 0
        errButtons.Visible = has
        errDivider.Visible = has
        for idx, btnInfo in buttons do
            local container = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(0,26), Parent = errButtons })
            local variant = btnInfo.Variant or "Primary"
            local btnColor = "MainColor"
            local outlineColor = "OutlineColor"
            if variant == "Primary" then btnColor = "FontColor"; outlineColor = "FontColor"
            elseif variant == "Secondary" then btnColor = "MainColor"; outlineColor = "OutlineColor"
            elseif variant == "Destructive" then btnColor = "DestructiveColor"; outlineColor = "DestructiveColor"
            elseif variant == "Ghost" then btnColor = "BackgroundColor"; outlineColor = "BackgroundColor" end
            local textBtn = New("TextButton", {
                BackgroundColor3 = btnColor,
                BorderColor3 = outlineColor,
                Size = UDim2.fromOffset(0,26),
                Text = "",
                AutoButtonColor = false,
                Parent = container,
            })
            Library:AddOutline(textBtn)
            table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0,Library.CornerRadius), Parent = textBtn }))
            New("UIPadding", { PaddingLeft = UDim.new(0,15), PaddingRight = UDim.new(0,15), Parent = textBtn })
            local textColor = Library.Scheme.FontColor
            if variant == "Primary" then textColor = Library.Scheme.BackgroundColor
            elseif variant == "Destructive" then textColor = Color3.new(1,1,1) end
            local label = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1,1),
                Text = btnInfo.Title or idx,
                TextColor3 = textColor,
                TextSize = 14,
                Parent = textBtn,
            })
            local lx,_ = Library:GetTextBounds(label.Text, Library.Scheme.Font, 14, 250)
            container.Size = UDim2.fromOffset(lx + 30, 26)
            textBtn.Size = UDim2.fromOffset(lx + 30, 26)
            local activeColor = type(btnColor) == "Color3" and btnColor or Library.Scheme[btnColor]
            local hoverColor = variant == "Ghost" and Library.Scheme.MainColor or Library:GetBetterColor(activeColor, 10)
            textBtn.MouseEnter:Connect(function()
                TweenService:Create(textBtn, Library.TweenInfo, { BackgroundColor3 = hoverColor }):Play()
            end)
            textBtn.MouseLeave:Connect(function()
                TweenService:Create(textBtn, Library.TweenInfo, { BackgroundColor3 = activeColor }):Play()
            end)
            textBtn.MouseButton1Click:Connect(function()
                if btnInfo.Callback then btnInfo.Callback(loading) end
            end)
        end
        loading:UpdateLayout()
    end

    function loading:Destroy()
        if rotationTween then StopTween(rotationTween, true); rotationTween = nil end
        screenGui:Destroy()
        loading.Destroyed = true
        Library.ActiveLoading = nil
        if Library.Toggle and Library.Toggled == false and not Library.Unloaded then
            Library:Toggle(true)
        end
    end

    loading.Continue = loading.Destroy

    if Library.Toggle and Library.Toggled and not Library.Unloaded then
        Library:Toggle(false)
    end

    loading:SetCurrentStep(loading.CurrentStep)
    Library.ActiveLoading = loading
    return loading
end

-- Player/Team updates
local function OnPlayerChange()
    if Library.Unloaded then return end
    local players = GetPlayers()
    local excl = GetPlayers(true)
    for _, opt in Options do
        if opt.Type == "Dropdown" and opt.SpecialType == "Player" then
            opt:SetValues(opt.ExcludeLocalPlayer and excl or players)
        end
    end
end

local function OnTeamChange()
    if Library.Unloaded then return end
    local teams = GetTeams()
    for _, opt in Options do
        if opt.Type == "Dropdown" and opt.SpecialType == "Team" then
            opt:SetValues(teams)
        end
    end
end

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange))
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange))
Library:GiveSignal(Teams.ChildAdded:Connect(OnTeamChange))
Library:GiveSignal(Teams.ChildRemoved:Connect(OnTeamChange))

-- Unload
function Library:Unload()
    Library.Unloaded = true
    for i=#Library.Signals,1,-1 do
        local conn = table.remove(Library.Signals, i)
        if conn and conn.Connected then conn:Disconnect() end
    end
    for i=1,#Library.UnloadSignals do
        local cb = table.remove(Library.UnloadSignals, 1)
        if cb then Library:SafeCallback(cb) end
    end
    for i=#Library.Tabs,1,-1 do
        local tab = table.remove(Library.Tabs, i)
        if tab and tab.Destroy then tab:Destroy() end
    end
    for i=#Tooltips,1,-1 do
        local tt = table.remove(Tooltips, i)
        if tt and tt.Destroy then tt:Destroy() end
    end
    if Library.ActiveLoading then Library.ActiveLoading:Destroy() end
    if ScreenGui then ScreenGui:Destroy() end
    table.clear(Library.Registry)
    table.clear(Options); table.clear(Toggles); table.clear(Buttons); table.clear(Labels); table.clear(Tooltips)
    table.clear(Library.Tabs); table.clear(Library.TabButtons)
    table.clear(Library.Scales); table.clear(Library.ScalesOffset)
    table.clear(Library.Corners); table.clear(Library.SpecificCorners)
    table.clear(Library.Notifications); table.clear(Library.Dialogues); table.clear(Library.DraggableElements)
    table.clear(Library.KeybindToggles); table.clear(Library.DependencyBoxes)
    table.clear(TransparencyCache); table.clear(ActiveTabTweens)
    Library.Toggle = function() end
    Library.ScreenGui = nil
    Library.WindowContainer = nil
    Library.KeybindFrame = nil
    Library.KeybindContainer = nil
    getgenv().Library = nil
end

getgenv().Library = Library
return Library