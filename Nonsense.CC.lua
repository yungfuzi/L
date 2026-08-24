--[[
    Nonsense.CC
    Modern Roblox Executor UI Library
    Single-file • One Window • Left Sidebar • Gradient Depth
]]

local Nonsense = {}
Nonsense.__index = Nonsense
Nonsense.Version = "1.0.0"
Nonsense.Name = "Nonsense.CC"

--// Services \\--
local cloneref = cloneref or clonereference or function(i) return i end
local Services = {
    CoreGui          = cloneref(game:GetService("CoreGui")),
    Players          = cloneref(game:GetService("Players")),
    RunService       = cloneref(game:GetService("RunService")),
    UserInputService = cloneref(game:GetService("UserInputService")),
    TweenService     = cloneref(game:GetService("TweenService")),
    TextService      = cloneref(game:GetService("TextService")),
    HttpService      = cloneref(game:GetService("HttpService")),
}

local LocalPlayer = Services.Players.LocalPlayer or Services.Players.PlayerAdded:Wait()
local Mouse = LocalPlayer:GetMouse()

--// Executor Compatibility \\--
local getgenv = getgenv or function() return shared end
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function() return Services.CoreGui end
local getcustomasset = getcustomasset or nil
local writefile = writefile or nil
local isfile = isfile or nil
local isfolder = isfolder or nil
local makefolder = makefolder or nil
local setclipboard = setclipboard or nil

--//============================================================================\\--
--//                              CORE UTILITIES
--//============================================================================\\--

local Utility = {}

function Utility.Clamp(n, min, max)
    return math.clamp(n, min, max)
end

function Utility.Round(value, decimals)
    decimals = decimals or 0
    if decimals <= 0 then
        return math.floor(value + 0.5)
    end
    local mult = 10 ^ decimals
    return math.floor(value * mult + 0.5) / mult
end

function Utility.Trim(str)
    return (str:gsub("^%s*(.-)%s*$", "%1"))
end

function Utility.DeepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[Utility.DeepCopy(k)] = Utility.DeepCopy(v)
    end
    return copy
end

function Utility.Merge(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            Utility.Merge(target[k], v)
        else
            target[k] = v
        end
    end
    return target
end

function Utility.IsClick(input, includeRight)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or (includeRight and input.UserInputType == Enum.UserInputType.MouseButton2)
        or input.UserInputType == Enum.UserInputType.Touch
end

function Utility.IsHover(input)
    return (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch)
        and input.UserInputState == Enum.UserInputState.Change
end

function Utility.GetTextBounds(text, font, size, width)
    local params = Instance.new("GetTextBoundsParams")
    params.Text = text or ""
    params.Font = font
    params.Size = size
    params.Width = width or 10000
    params.RichText = true
    local bounds = Services.TextService:GetTextBoundsAsync(params)
    return bounds.X, bounds.Y
end

function Utility.SafeCallback(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[Nonsense.CC] Callback error:", err)
    end
end

function Utility.Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

--//============================================================================\\--
--//                              SIGNAL SYSTEM
--//============================================================================\\--

local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({
        _connections = {},
        _destroyed = false,
    }, Signal)
end

function Signal:Connect(fn)
    if self._destroyed then return { Disconnect = function() end } end
    local conn = { fn = fn, connected = true }
    table.insert(self._connections, conn)
    return {
        Disconnect = function()
            if not conn.connected then return end
            conn.connected = false
            for i, c in ipairs(self._connections) do
                if c == conn then
                    table.remove(self._connections, i)
                    break
                end
            end
        end
    }
end

function Signal:Once(fn)
    local conn
    conn = self:Connect(function(...)
        conn:Disconnect()
        fn(...)
    end)
    return conn
end

function Signal:Fire(...)
    if self._destroyed then return end
    for _, conn in ipairs(self._connections) do
        if conn.connected then
            Utility.SafeCallback(conn.fn, ...)
        end
    end
end

function Signal:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    table.clear(self._connections)
end

--//============================================================================\\--
--//                           CONNECTION MANAGER
--//============================================================================\\--

local ConnectionManager = {}
ConnectionManager.__index = ConnectionManager

function ConnectionManager.new()
    return setmetatable({ _list = {} }, ConnectionManager)
end

function ConnectionManager:Add(conn)
    if conn then
        table.insert(self._list, conn)
    end
    return conn
end

function ConnectionManager:Connect(signal, fn)
    local conn = signal:Connect(fn)
    return self:Add(conn)
end

function ConnectionManager:Destroy()
    for _, conn in ipairs(self._list) do
        if type(conn) == "table" and conn.Disconnect then
            pcall(conn.Disconnect, conn)
        elseif typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end
    table.clear(self._list)
end

--//============================================================================\\--
--//                              THEME SYSTEM
--//============================================================================\\--

local Themes = {
    Dark = {
        Background      = Color3.fromRGB(18, 18, 22),
        Surface         = Color3.fromRGB(28, 28, 34),
        SurfaceAlt      = Color3.fromRGB(36, 36, 44),
        Border          = Color3.fromRGB(48, 48, 58),
        Text            = Color3.fromRGB(235, 235, 245),
        TextSecondary   = Color3.fromRGB(160, 160, 175),
        Accent          = Color3.fromRGB(140, 100, 255),
        AccentHover     = Color3.fromRGB(160, 120, 255),
        Success         = Color3.fromRGB(80, 200, 120),
        Warning         = Color3.fromRGB(255, 180, 60),
        Error           = Color3.fromRGB(240, 70, 70),
        GradientTop     = Color3.fromRGB(32, 28, 42),
        GradientBottom  = Color3.fromRGB(18, 18, 22),
    },
    SoftPurple = {
        Background      = Color3.fromRGB(22, 18, 32),
        Surface         = Color3.fromRGB(34, 28, 48),
        SurfaceAlt      = Color3.fromRGB(44, 36, 62),
        Border          = Color3.fromRGB(60, 50, 85),
        Text            = Color3.fromRGB(240, 235, 255),
        TextSecondary   = Color3.fromRGB(170, 160, 200),
        Accent          = Color3.fromRGB(170, 120, 255),
        AccentHover     = Color3.fromRGB(190, 145, 255),
        Success         = Color3.fromRGB(90, 210, 140),
        Warning         = Color3.fromRGB(255, 185, 70),
        Error           = Color3.fromRGB(245, 80, 90),
        GradientTop     = Color3.fromRGB(42, 32, 58),
        GradientBottom  = Color3.fromRGB(22, 18, 32),
    },
    Cyan = {
        Background      = Color3.fromRGB(14, 20, 28),
        Surface         = Color3.fromRGB(22, 32, 42),
        SurfaceAlt      = Color3.fromRGB(30, 44, 56),
        Border          = Color3.fromRGB(40, 60, 75),
        Text            = Color3.fromRGB(230, 245, 255),
        TextSecondary   = Color3.fromRGB(140, 180, 200),
        Accent          = Color3.fromRGB(60, 200, 230),
        AccentHover     = Color3.fromRGB(90, 220, 245),
        Success         = Color3.fromRGB(70, 210, 150),
        Warning         = Color3.fromRGB(255, 190, 70),
        Error           = Color3.fromRGB(240, 75, 85),
        GradientTop     = Color3.fromRGB(24, 38, 52),
        GradientBottom  = Color3.fromRGB(14, 20, 28),
    },
}

local Theme = {
    Current = "Dark",
    Colors = Utility.DeepCopy(Themes.Dark),
    Registry = {}, -- Instance → { Property = ColorKey or function }
}

function Theme:Set(nameOrTable)
    if type(nameOrTable) == "string" then
        local t = Themes[nameOrTable]
        if not t then
            warn("[Nonsense.CC] Unknown theme:", nameOrTable)
            return
        end
        self.Current = nameOrTable
        self.Colors = Utility.DeepCopy(t)
    elseif type(nameOrTable) == "table" then
        Utility.Merge(self.Colors, nameOrTable)
        self.Current = "Custom"
    end
    self:Apply()
end

function Theme:Get(key)
    return self.Colors[key]
end

function Theme:Register(instance, props)
    self.Registry[instance] = props
end

function Theme:Unregister(instance)
    self.Registry[instance] = nil
end

function Theme:Apply()
    for inst, props in pairs(self.Registry) do
        if inst and inst.Parent then
            for prop, key in pairs(props) do
                local value
                if type(key) == "function" then
                    value = key()
                else
                    value = self.Colors[key]
                end
                if value ~= nil then
                    pcall(function() inst[prop] = value end)
                end
            end
        end
    end
end

function Theme:MakeGradient(parent, rotation)
    local grad = Utility.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.Colors.GradientTop),
            ColorSequenceKeypoint.new(1, self.Colors.GradientBottom),
        }),
        Rotation = rotation or 90,
        Parent = parent,
    })
    self:Register(grad, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Theme.Colors.GradientTop),
                ColorSequenceKeypoint.new(1, Theme.Colors.GradientBottom),
            })
        end
    })
    return grad
end

--//============================================================================\\--
--//                              FLAG REGISTRY
--//============================================================================\\--

local Flags = {
    _data = {},
    _elements = {}, -- flag → element
}

function Flags:Set(flag, value, silent)
    if not flag then return end
    self._data[flag] = value
    local elem = self._elements[flag]
    if elem and not silent and elem.SetValue then
        -- already set by element itself usually
    end
end

function Flags:Get(flag)
    return self._data[flag]
end

function Flags:Has(flag)
    return self._data[flag] ~= nil
end

function Flags:Register(flag, element)
    if not flag then return end
    if self._elements[flag] then
        warn("[Nonsense.CC] Flag already registered:", flag)
    end
    self._elements[flag] = element
end

function Flags:Unregister(flag)
    if flag then
        self._elements[flag] = nil
    end
end

function Flags:GetAll()
    return Utility.DeepCopy(self._data)
end

function Flags:Reset()
    table.clear(self._data)
    table.clear(self._elements)
end

--//============================================================================\\--
--//                              DPI / SCALE
--//============================================================================\\--

local DPI = {
    Scale = 1,
    Scales = {}, -- UIScale instances
}

function DPI:Set(scalePercent)
    self.Scale = (scalePercent or 100) / 100
    for _, uiScale in ipairs(self.Scales) do
        if uiScale and uiScale.Parent then
            uiScale.Scale = self.Scale
        end
    end
end

function DPI:Attach(uiScale)
    table.insert(self.Scales, uiScale)
    uiScale.Scale = self.Scale
end

--//============================================================================\\--
--//                              ICON SYSTEM
--//============================================================================\\--

local Icons = {
    _lucide = nil,
    _custom = {},
    _loaded = false,
}

function Icons:Init()
    if self._loaded then return end
    local ok, module = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/lucide-roblox-direct/refs/heads/main/source.lua"))()
    end)
    if ok and module then
        self._lucide = module
    end
    self._loaded = true
end

function Icons:Get(name)
    if not name then return nil end
    self:Init()

    -- Custom asset id or rbxasset
    if type(name) == "number" or (type(name) == "string" and (name:match("^rbxassetid://") or name:match("^rbxasset://"))) then
        local url = type(name) == "number" and ("rbxassetid://" .. name) or name
        return { Url = url, ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero }
    end

    -- Lucide
    if self._lucide and self._lucide.GetAsset then
        local ok, icon = pcall(self._lucide.GetAsset, name)
        if ok and icon then
            return icon
        end
    end

    return nil
end

function Icons:AddCustom(name, urlOrId)
    self._custom[name] = urlOrId
end

--//============================================================================\\--
--//                              LIBRARY STATE
--//============================================================================\\--

Nonsense.Flags = Flags
Nonsense.Theme = Theme
Nonsense.DPI = DPI
Nonsense.Icons = Icons
Nonsense.Signals = ConnectionManager.new()
Nonsense.Unloaded = false
Nonsense.Toggled = false
Nonsense.IsMobile = false
Nonsense.Window = nil
Nonsense.ScreenGui = nil
Nonsense.ActiveTab = nil
Nonsense.Notifications = {}
Nonsense.Dialogues = {}

-- Detect mobile
do
    local platform
    pcall(function()
        platform = Services.UserInputService:GetPlatform()
    end)
    Nonsense.IsMobile = platform == Enum.Platform.Android or platform == Enum.Platform.IOS
        or (Services.UserInputService.TouchEnabled and not Services.UserInputService.MouseEnabled)
end

--//============================================================================\\--
--//                              ANIMATION HELPERS
--//============================================================================\\--

local Anim = {
    Info = {
        Fast     = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Normal   = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Smooth   = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Spring   = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        Window   = TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        Tab      = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    },
    Enabled = {
        Window = true,
        Tab = true,
        Groupbox = true,
        Dropdown = true,
        Hover = true,
    }
}

function Anim.Play(instance, info, props)
    local tween = Services.TweenService:Create(instance, info, props)
    tween:Play()
    return tween
end

function Anim.Stop(tween)
    if tween and tween.PlaybackState == Enum.PlaybackState.Playing then
        tween:Cancel()
    end
end

--//============================================================================\\--
--//                         PARENTING & PROTECTION
--//============================================================================\\--

local function SafeParent(gui)
    pcall(protectgui, gui)
    local ok = pcall(function()
        gui.Parent = gethui()
    end)
    if not ok or not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5) or Services.CoreGui
    end
end

--//============================================================================\\--
--//                              SCREEN GUI
--//============================================================================\\--

local function CreateScreenGui()
    if Nonsense.ScreenGui then return Nonsense.ScreenGui end

    local sg = Utility.Create("ScreenGui", {
        Name = "NonsenseCC",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        IgnoreGuiInset = true,
    })
    SafeParent(sg)
    Nonsense.ScreenGui = sg

    -- Custom cursor (optional)
    -- will be added later if needed

    return sg
end

--//============================================================================\\--
--//                              NOTIFY SYSTEM (stub for now)
--//============================================================================\\--

function Nonsense:Notify(title, content, duration)
    -- Full implementation later
    print(string.format("[Nonsense] %s: %s", tostring(title), tostring(content)))
end

--//============================================================================\\--
--//                              UNLOAD
--//============================================================================\\--

function Nonsense:Unload()
    if self.Unloaded then return end
    self.Unloaded = true

    self.Signals:Destroy()

    if self.Window and self.Window.Destroy then
        self.Window:Destroy()
    end

    if self.ScreenGui then
        self.ScreenGui:Destroy()
        self.ScreenGui = nil
    end

    Flags:Reset()
    table.clear(Theme.Registry)
    table.clear(DPI.Scales)

    getgenv().Nonsense = nil
    getgenv().Library = nil -- optional alias
end

--//============================================================================\\--
--//                              CREATE WINDOW
--//============================================================================\\--

function Nonsense:CreateWindow(config)
    if self.Window then
        warn("[Nonsense.CC] Only one window is supported.")
        return self.Window
    end

    config = config or {}
    local title       = config.Title or "Nonsense.CC"
    local footer      = config.Footer or ("v" .. self.Version)
    local size        = config.Size or UDim2.fromOffset(640, 500)
    local minSize     = config.MinSize or Vector2.new(480, 340)
    local toggleKey   = config.ToggleKey or Enum.KeyCode.RightControl
    local sidebarW    = config.SidebarWidth or 160
    local compactW    = 52
    local cornerR     = config.CornerRadius or 8
    local center      = config.Center ~= false
    local autoShow    = config.AutoShow ~= false

    CreateScreenGui()

    --================ MAIN FRAME ================--
    local Main = Utility.Create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = size,
        BackgroundColor3 = Theme:Get("Background"),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        Parent = self.ScreenGui,
    })
    Theme:Register(Main, { BackgroundColor3 = "Background" })

    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, cornerR),
        Parent = Main,
    })

    Theme:MakeGradient(Main, 115)

    local mainStroke = Utility.Create("UIStroke", {
        Color = Theme:Get("Border"),
        Thickness = 1.2,
        Parent = Main,
    })
    Theme:Register(mainStroke, { Color = "Border" })

    local mainScale = Utility.Create("UIScale", { Parent = Main })
    DPI:Attach(mainScale)

    --================ TOP BAR ================--
    local TopBar = Utility.Create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = Theme:Get("Surface"),
        BorderSizePixel = 0,
        Parent = Main,
    })
    Theme:Register(TopBar, { BackgroundColor3 = "Surface" })
    Theme:MakeGradient(TopBar, 90)

    -- Title
    local TitleLabel = Utility.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(0, 200, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = title,
        TextSize = 16,
        TextColor3 = Theme:Get("Text"),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })
    Theme:Register(TitleLabel, { TextColor3 = "Text" })

    -- Search box
    local SearchHolder = Utility.Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(180, 28),
        BackgroundColor3 = Theme:Get("SurfaceAlt"),
        BorderSizePixel = 0,
        Parent = TopBar,
    })
    Theme:Register(SearchHolder, { BackgroundColor3 = "SurfaceAlt" })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = SearchHolder })

    local SearchBox = Utility.Create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = Enum.Font.Gotham,
        PlaceholderText = "Search...",
        PlaceholderColor3 = Theme:Get("TextSecondary"),
        Text = "",
        TextSize = 13,
        TextColor3 = Theme:Get("Text"),
        ClearTextOnFocus = false,
        Parent = SearchHolder,
    })
    Theme:Register(SearchBox, { TextColor3 = "Text", PlaceholderColor3 = "TextSecondary" })

    -- Divider under topbar
    local TopDivider = Utility.Create("Frame", {
        Position = UDim2.fromOffset(0, 46),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme:Get("Border"),
        BorderSizePixel = 0,
        Parent = Main,
    })
    Theme:Register(TopDivider, { BackgroundColor3 = "Border" })

    --================ SIDEBAR ================--
    local Sidebar = Utility.Create("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, 47),
        Size = UDim2.new(0, sidebarW, 1, -47),
        BackgroundColor3 = Theme:Get("Surface"),
        BorderSizePixel = 0,
        Parent = Main,
    })
    Theme:Register(Sidebar, { BackgroundColor3 = "Surface" })

    local SidebarList = Utility.Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -36),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme:Get("Border"),
        BorderSizePixel = 0,
        Parent = Sidebar,
    })
    Theme:Register(SidebarList, { ScrollBarImageColor3 = "Border" })

    local SidebarLayout = Utility.Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = SidebarList,
    })
    Utility.Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = SidebarList,
    })

    -- Footer in sidebar
    local FooterLabel = Utility.Create("TextLabel", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = footer,
        TextSize = 11,
        TextColor3 = Theme:Get("TextSecondary"),
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = Sidebar,
    })
    Theme:Register(FooterLabel, { TextColor3 = "TextSecondary" })

    -- Sidebar right divider
    local SideDivider = Utility.Create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Theme:Get("Border"),
        BorderSizePixel = 0,
        Parent = Sidebar,
    })
    Theme:Register(SideDivider, { BackgroundColor3 = "Border" })

    --================ CONTENT AREA ================--
    local Content = Utility.Create("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(sidebarW + 1, 47),
        Size = UDim2.new(1, -(sidebarW + 1), 1, -47),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = Main,
    })

    --================ WINDOW OBJECT ================--
    local Window = {
        Title = title,
        Main = Main,
        TopBar = TopBar,
        Sidebar = Sidebar,
        SidebarList = SidebarList,
        Content = Content,
        Config = config,
        Tabs = {},
        TabButtons = {},
        ActiveTab = nil,
        SidebarWidth = sidebarW,
        Compact = false,
        Connections = ConnectionManager.new(),
        Destroyed = false,
        SearchText = "",
    }

    -- Make draggable
    do
        local dragging, dragStart, startPos
        Window.Connections:Add(TopBar.InputBegan:Connect(function(input)
            if not Utility.IsClick(input) then return end
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            local ended
            ended = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if ended then ended:Disconnect() end
                end
            end)
        end))
        Window.Connections:Add(Services.UserInputService.InputChanged:Connect(function(input)
            if dragging and Utility.IsHover(input) then
                local delta = input.Position - dragStart
                Main.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end))
    end

    -- Toggle
    function Window:Toggle(state)
        if state == nil then
            Nonsense.Toggled = not Nonsense.Toggled
        else
            Nonsense.Toggled = state
        end

        if Anim.Enabled.Window then
            if Nonsense.Toggled then
                Main.Visible = true
                Main.BackgroundTransparency = 1
                Anim.Play(Main, Anim.Info.Window, { BackgroundTransparency = 0 })
            else
                local tw = Anim.Play(Main, Anim.Info.Window, { BackgroundTransparency = 1 })
                tw.Completed:Once(function()
                    if not Nonsense.Toggled then
                        Main.Visible = false
                    end
                end)
            end
        else
            Main.Visible = Nonsense.Toggled
        end
    end

    function Window:SetTitle(text)
        self.Title = text
        TitleLabel.Text = text
    end

    function Window:SetFooter(text)
        FooterLabel.Text = text
    end

    function Window:SetTheme(name)
        Theme:Set(name)
    end

    function Window:Destroy()
        if self.Destroyed then return end
        self.Destroyed = true
        self.Connections:Destroy()
        for _, tab in pairs(self.Tabs) do
            if tab.Destroy then tab:Destroy() end
        end
        table.clear(self.Tabs)
        if self.Main then self.Main:Destroy() end
        Nonsense.Window = nil
        Nonsense.ActiveTab = nil
    end

    --================ ADD TAB ================--
    function Window:AddTab(opts)
        if type(opts) == "string" then
            opts = { Name = opts }
        end
        opts = opts or {}
        local name = opts.Name or "Tab"
        local iconName = opts.Icon
        local order = opts.Order or (#self.TabButtons + 1)

        -- Tab button in sidebar
        local TabBtn = Utility.Create("TextButton", {
            Name = name,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Theme:Get("SurfaceAlt"),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = order,
            Parent = SidebarList,
        })
        Theme:Register(TabBtn, { BackgroundColor3 = "SurfaceAlt" })
        Utility.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabBtn })

        local iconData = Icons:Get(iconName)
        local IconImg
        if iconData then
            IconImg = Utility.Create("ImageLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(10, 8),
                Size = UDim2.fromOffset(20, 20),
                Image = iconData.Url,
                ImageRectOffset = iconData.ImageRectOffset,
                ImageRectSize = iconData.ImageRectSize,
                ImageColor3 = Theme:Get("TextSecondary"),
                Parent = TabBtn,
            })
            Theme:Register(IconImg, { ImageColor3 = "TextSecondary" })
        end

        local TabLabel = Utility.Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(iconData and 36 or 12, 0),
            Size = UDim2.new(1, -(iconData and 44 or 20), 1, 0),
            Font = Enum.Font.Gotham,
            Text = name,
            TextSize = 14,
            TextColor3 = Theme:Get("TextSecondary"),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = TabBtn,
        })
        Theme:Register(TabLabel, { TextColor3 = "TextSecondary" })

        -- Tab content canvas
        local TabCanvas = Utility.Create("CanvasGroup", {
            Name = name,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            GroupTransparency = 1,
            Visible = false,
            Parent = Content,
        })

        local LeftSide = Utility.Create("ScrollingFrame", {
            Name = "Left",
            Size = UDim2.new(0.5, -6, 1, 0),
            Position = UDim2.fromOffset(6, 6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme:Get("Border"),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = TabCanvas,
        })
        Theme:Register(LeftSide, { ScrollBarImageColor3 = "Border" })
        Utility.Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = LeftSide,
        })
        Utility.Create("UIPadding", {
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 2),
            Parent = LeftSide,
        })

        local RightSide = Utility.Create("ScrollingFrame", {
            Name = "Right",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -6, 0, 6),
            Size = UDim2.new(0.5, -6, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme:Get("Border"),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = TabCanvas,
        })
        Theme:Register(RightSide, { ScrollBarImageColor3 = "Border" })
        Utility.Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = RightSide,
        })
        Utility.Create("UIPadding", {
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 2),
            Parent = RightSide,
        })

        local Tab = {
            Name = name,
            Button = TabBtn,
            Label = TabLabel,
            Icon = IconImg,
            Canvas = TabCanvas,
            Left = LeftSide,
            Right = RightSide,
            Groupboxes = {},
            Window = Window,
            Connections = ConnectionManager.new(),
            Destroyed = false,
        }

        function Tab:Show()
            if Window.ActiveTab == self then return end
            if Window.ActiveTab then
                Window.ActiveTab:Hide()
            end

            -- Button active style
            TabBtn.BackgroundTransparency = 0
            TabLabel.TextColor3 = Theme:Get("Text")
            if IconImg then
                IconImg.ImageColor3 = Theme:Get("Accent")
            end

            -- Canvas show
            TabCanvas.Visible = true
            if Anim.Enabled.Tab then
                TabCanvas.GroupTransparency = 1
                Anim.Play(TabCanvas, Anim.Info.Tab, { GroupTransparency = 0 })
            else
                TabCanvas.GroupTransparency = 0
            end

            Window.ActiveTab = self
            Nonsense.ActiveTab = self
        end

        function Tab:Hide()
            TabBtn.BackgroundTransparency = 1
            TabLabel.TextColor3 = Theme:Get("TextSecondary")
            if IconImg then
                IconImg.ImageColor3 = Theme:Get("TextSecondary")
            end
            TabCanvas.GroupTransparency = 1
            TabCanvas.Visible = false
        end

        function Tab:Destroy()
            if self.Destroyed then return end
            self.Destroyed = true
            self.Connections:Destroy()
            for _, gb in pairs(self.Groupboxes) do
                if gb.Destroy then gb:Destroy() end
            end
            table.clear(self.Groupboxes)
            if TabCanvas then TabCanvas:Destroy() end
            if TabBtn then TabBtn:Destroy() end
            Window.Tabs[name] = nil
        end

        -- Hover
        TabBtn.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab then
                Anim.Play(TabBtn, Anim.Info.Fast, { BackgroundTransparency = 0.6 })
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if Window.ActiveTab ~= Tab then
                Anim.Play(TabBtn, Anim.Info.Fast, { BackgroundTransparency = 1 })
            end
        end)
        TabBtn.MouseButton1Click:Connect(function()
            Tab:Show()
        end)

        --================ GROUPBOX ================--
        function Tab:AddGroupbox(opts)
            if type(opts) == "string" then
                opts = { Name = opts }
            end
            opts = opts or {}
            local gbName = opts.Name or "Groupbox"
            local side = (opts.Side == "Right" or opts.Side == 2) and 2 or 1
            local parentSide = side == 1 and LeftSide or RightSide

            local Holder = Utility.Create("Frame", {
                Name = gbName,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = parentSide,
            })

            local Box = Utility.Create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme:Get("Surface"),
                BorderSizePixel = 0,
                Parent = Holder,
            })
            Theme:Register(Box, { BackgroundColor3 = "Surface" })
            Utility.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = Box })
            Theme:MakeGradient(Box, 100)

            local boxStroke = Utility.Create("UIStroke", {
                Color = Theme:Get("Border"),
                Thickness = 1,
                Parent = Box,
            })
            Theme:Register(boxStroke, { Color = "Border" })

            -- Header
            local Header = Utility.Create("Frame", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1,
                Parent = Box,
            })

            local HeaderLabel = Utility.Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -24, 1, 0),
                Font = Enum.Font.GothamMedium,
                Text = gbName,
                TextSize = 13,
                TextColor3 = Theme:Get("Text"),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Header,
            })
            Theme:Register(HeaderLabel, { TextColor3 = "Text" })

            local HeaderLine = Utility.Create("Frame", {
                Position = UDim2.fromOffset(0, 32),
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Theme:Get("Border"),
                BorderSizePixel = 0,
                Parent = Box,
            })
            Theme:Register(HeaderLine, { BackgroundColor3 = "Border" })

            -- Container for elements
            local Container = Utility.Create("Frame", {
                Position = UDim2.fromOffset(0, 33),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = Box,
            })
            local List = Utility.Create("UIListLayout", {
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Container,
            })
            Utility.Create("UIPadding", {
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                Parent = Container,
            })

            local Groupbox = {
                Name = gbName,
                Holder = Holder,
                Box = Box,
                Container = Container,
                Elements = {},
                Tab = Tab,
                Visible = true,
                Connections = ConnectionManager.new(),
                Destroyed = false,
            }

            function Groupbox:Resize()
                -- AutomaticSize handles it
            end

            function Groupbox:SetVisible(v)
                self.Visible = v
                Holder.Visible = v
            end

            function Groupbox:Destroy()
                if self.Destroyed then return end
                self.Destroyed = true
                self.Connections:Destroy()
                for _, el in pairs(self.Elements) do
                    if el.Destroy then el:Destroy() end
                end
                table.clear(self.Elements)
                if Holder then Holder:Destroy() end
            end

            --================ TOGGLE ================--
            function Groupbox:AddToggle(flagOrOpts, opts)
                local flag, config
                if type(flagOrOpts) == "string" then
                    flag = flagOrOpts
                    config = opts or {}
                else
                    config = flagOrOpts or {}
                    flag = config.Flag
                end

                local text = config.Text or config.Name or flag or "Toggle"
                local default = config.Default == true
                local callback = config.Callback
                local risky = config.Risky == true

                local Row = Utility.Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    Parent = Container,
                })

                local Label = Utility.Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -40, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = text,
                    TextSize = 13,
                    TextColor3 = risky and Theme:Get("Error") or Theme:Get("Text"),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                })
                Theme:Register(Label, {
                    TextColor3 = function()
                        return risky and Theme:Get("Error") or Theme:Get("Text")
                    end
                })

                -- Switch track
                local Track = Utility.Create("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(36, 18),
                    BackgroundColor3 = Theme:Get("SurfaceAlt"),
                    BorderSizePixel = 0,
                    Parent = Row,
                })
                Theme:Register(Track, { BackgroundColor3 = "SurfaceAlt" })
                Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track })

                local Knob = Utility.Create("Frame", {
                    Position = UDim2.fromOffset(2, 2),
                    Size = UDim2.fromOffset(14, 14),
                    BackgroundColor3 = Theme:Get("TextSecondary"),
                    BorderSizePixel = 0,
                    Parent = Track,
                })
                Theme:Register(Knob, { BackgroundColor3 = "TextSecondary" })
                Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })

                local Toggle = {
                    Type = "Toggle",
                    Flag = flag,
                    Value = default,
                    Text = text,
                    Callback = callback,
                    Row = Row,
                    Connections = ConnectionManager.new(),
                    Destroyed = false,
                }

                local function UpdateVisual(val, animate)
                    local targetPos = val and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2)
                    local targetTrack = val and Theme:Get("Accent") or Theme:Get("SurfaceAlt")
                    local targetKnob = val and Color3.new(1, 1, 1) or Theme:Get("TextSecondary")

                    if animate and Anim.Enabled.Hover then
                        Anim.Play(Knob, Anim.Info.Fast, { Position = targetPos, BackgroundColor3 = targetKnob })
                        Anim.Play(Track, Anim.Info.Fast, { BackgroundColor3 = targetTrack })
                    else
                        Knob.Position = targetPos
                        Knob.BackgroundColor3 = targetKnob
                        Track.BackgroundColor3 = targetTrack
                    end
                end

                function Toggle:SetValue(val, silent)
                    val = val == true
                    self.Value = val
                    if flag then Flags:Set(flag, val) end
                    UpdateVisual(val, true)
                    if not silent then
                        Utility.SafeCallback(self.Callback, val)
                    end
                end

                function Toggle:GetValue()
                    return self.Value
                end

                function Toggle:SetText(t)
                    self.Text = t
                    Label.Text = t
                end

                function Toggle:SetVisible(v)
                    Row.Visible = v
                end

                function Toggle:OnChanged(fn)
                    self.Callback = fn
                end

                function Toggle:Destroy()
                    if self.Destroyed then return end
                    self.Destroyed = true
                    self.Connections:Destroy()
                    if flag then Flags:Unregister(flag) end
                    if Row then Row:Destroy() end
                end

                -- Click
                local Hit = Utility.Create("TextButton", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = Row,
                })
                Hit.MouseButton1Click:Connect(function()
                    Toggle:SetValue(not Toggle.Value)
                end)

                -- Init
                if flag then
                    Flags:Register(flag, Toggle)
                    Flags:Set(flag, default)
                end
                UpdateVisual(default, false)

                table.insert(Groupbox.Elements, Toggle)
                return Toggle
            end

            --================ BUTTON ================--
            function Groupbox:AddButton(opts)
                if type(opts) == "string" then
                    opts = { Text = opts }
                end
                opts = opts or {}
                local text = opts.Text or opts.Name or "Button"
                local callback = opts.Callback
                local risky = opts.Risky == true

                local Btn = Utility.Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = risky and Theme:Get("Error") or Theme:Get("SurfaceAlt"),
                    BorderSizePixel = 0,
                    Text = text,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 13,
                    TextColor3 = Theme:Get("Text"),
                    AutoButtonColor = false,
                    Parent = Container,
                })
                Theme:Register(Btn, {
                    BackgroundColor3 = function()
                        return risky and Theme:Get("Error") or Theme:Get("SurfaceAlt")
                    end,
                    TextColor3 = "Text"
                })
                Utility.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Btn })

                local Button = {
                    Type = "Button",
                    Text = text,
                    Callback = callback,
                    Instance = Btn,
                    Connections = ConnectionManager.new(),
                    Destroyed = false,
                }

                function Button:SetText(t)
                    self.Text = t
                    Btn.Text = t
                end

                function Button:SetVisible(v)
                    Btn.Visible = v
                end

                function Button:Destroy()
                    if self.Destroyed then return end
                    self.Destroyed = true
                    self.Connections:Destroy()
                    if Btn then Btn:Destroy() end
                end

                Btn.MouseEnter:Connect(function()
                    Anim.Play(Btn, Anim.Info.Fast, {
                        BackgroundColor3 = risky and Theme:Get("Error") or Theme:Get("Accent")
                    })
                end)
                Btn.MouseLeave:Connect(function()
                    Anim.Play(Btn, Anim.Info.Fast, {
                        BackgroundColor3 = risky and Theme:Get("Error") or Theme:Get("SurfaceAlt")
                    })
                end)
                Btn.MouseButton1Click:Connect(function()
                    Utility.SafeCallback(Button.Callback)
                end)

                table.insert(Groupbox.Elements, Button)
                return Button
            end

            --================ LABEL ================--
            function Groupbox:AddLabel(text)
                local Label = Utility.Create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = tostring(text or ""),
                    TextSize = 13,
                    TextColor3 = Theme:Get("TextSecondary"),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = Container,
                })
                Theme:Register(Label, { TextColor3 = "TextSecondary" })

                local Obj = {
                    Type = "Label",
                    Instance = Label,
                    Destroyed = false,
                }
                function Obj:SetText(t)
                    Label.Text = tostring(t or "")
                end
                function Obj:Destroy()
                    if self.Destroyed then return end
                    self.Destroyed = true
                    if Label then Label:Destroy() end
                end

                table.insert(Groupbox.Elements, Obj)
                return Obj
            end

            --================ DIVIDER ================--
            function Groupbox:AddDivider()
                local Line = Utility.Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = Theme:Get("Border"),
                    BorderSizePixel = 0,
                    Parent = Container,
                })
                Theme:Register(Line, { BackgroundColor3 = "Border" })
                local Obj = { Type = "Divider", Instance = Line }
                table.insert(Groupbox.Elements, Obj)
                return Obj
            end

            Tab.Groupboxes[gbName] = Groupbox
            return Groupbox
        end

        function Tab:AddLeftGroupbox(name)
            return self:AddGroupbox({ Name = name, Side = "Left" })
        end

        function Tab:AddRightGroupbox(name)
            return self:AddGroupbox({ Name = name, Side = "Right" })
        end

        -- Auto show first tab
        if not Window.ActiveTab then
            Tab:Show()
        end

        Window.Tabs[name] = Tab
        table.insert(Window.TabButtons, TabBtn)

        -- Update canvas size on content change
        SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            SidebarList.CanvasSize = UDim2.new(0, 0, 0, SidebarLayout.AbsoluteContentSize.Y + 16)
        end)

        return Tab
    end

    -- Search
    Window.Connections:Add(SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Window.SearchText = SearchBox.Text
        -- Full search implementation later with elements
    end))

    -- Toggle keybind
    Window.Connections:Add(Services.UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or Nonsense.Unloaded then return end
        if input.KeyCode == toggleKey then
            Window:Toggle()
        end
    end))

    -- Mobile floating buttons
    if Nonsense.IsMobile then
        local ToggleBtn = Utility.Create("TextButton", {
            Name = "MobileToggle",
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.fromOffset(12, 12),
            Size = UDim2.fromOffset(70, 32),
            BackgroundColor3 = Theme:Get("Accent"),
            Text = "Menu",
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            Parent = self.ScreenGui,
        })
        Theme:Register(ToggleBtn, { BackgroundColor3 = "Accent" })
        Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = ToggleBtn })
        ToggleBtn.MouseButton1Click:Connect(function()
            Window:Toggle()
        end)
    end

    -- Show
    if autoShow then
        task.defer(function()
            Window:Toggle(true)
        end)
    end

    Nonsense.Window = Window
    return Window
end

--//============================================================================\\--
--//                              INIT & EXPORT
--//============================================================================\\--

-- Set default theme
Theme:Set("Dark")

-- Export
getgenv().Nonsense = Nonsense
getgenv().Library = Nonsense -- optional compatibility alias

return Nonsense
