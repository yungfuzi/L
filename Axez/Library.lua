--[[
    Aether UI Library
    August 2026
]]

local cloneref = cloneref or clonereference or function(i) return i end
local gethui = gethui or function() return cloneref(game:GetService("CoreGui")) end
local protectgui = protectgui or (syn and syn.protect_gui) or function() end

local Services = {
    Players = cloneref(game:GetService("Players")),
    TweenService = cloneref(game:GetService("TweenService")),
    UserInputService = cloneref(game:GetService("UserInputService")),
    RunService = cloneref(game:GetService("RunService")),
    GuiService = cloneref(game:GetService("GuiService")),
    HttpService = cloneref(game:GetService("HttpService")),
    TextService = cloneref(game:GetService("TextService")),
}

local LocalPlayer = Services.Players.LocalPlayer

--@ Utility
local Utility = {}

function Utility.Create(class, props, children)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then
                inst[k] = v
            end
        end
        if props.Parent then
            inst.Parent = props.Parent
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    return inst
end

function Utility.Tween(obj, props, info)
    if Library and Library.Animations and Library.Animations.Enabled == false then
        for k, v in pairs(props) do
            obj[k] = v
        end
        return nil
    end
    local anim = (Library and Library.Animations) or {}
    info = info or TweenInfo.new(
        anim.Duration or 0.18,
        anim.Style or Enum.EasingStyle.Quart,
        anim.Direction or Enum.EasingDirection.Out
    )
    local tween = Services.TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

function Utility.IsMobile()
    return Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled
end

function Utility.DeepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = Utility.DeepCopy(v)
    end
    return copy
end

function Utility.Round(n, places)
    local mult = 10 ^ (places or 0)
    return math.floor(n * mult + 0.5) / mult
end

--@ Signal
local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({}, Signal)
    self._connections = {}
    self._destroyed = false
    return self
end

function Signal:Connect(fn)
    if self._destroyed then return { Disconnect = function() end } end
    local conn = {
        Connected = true,
        _fn = fn,
        Disconnect = function(c)
            c.Connected = false
            for i, v in ipairs(self._connections) do
                if v == c then
                    table.remove(self._connections, i)
                    break
                end
            end
        end,
    }
    table.insert(self._connections, conn)
    return conn
end

function Signal:Fire(...)
    if self._destroyed then return end
    for _, conn in ipairs(self._connections) do
        if conn.Connected then
            task.spawn(conn._fn, ...)
        end
    end
end

function Signal:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for _, conn in ipairs(self._connections) do
        conn.Connected = false
    end
    table.clear(self._connections)
end

--@ Connection Manager
local ConnectionManager = {}
ConnectionManager.__index = ConnectionManager

function ConnectionManager.new()
    local self = setmetatable({}, ConnectionManager)
    self._connections = {}
    return self
end

function ConnectionManager:Add(conn)
    table.insert(self._connections, conn)
    return conn
end

function ConnectionManager:Connect(signal, fn)
    local conn = signal:Connect(fn)
    return self:Add(conn)
end

function ConnectionManager:Destroy()
    for _, conn in ipairs(self._connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        elseif type(conn) == "table" and conn.Disconnect then
            conn:Disconnect()
        end
    end
    table.clear(self._connections)
end

--@ Theme
local DefaultTheme = {
    Background = Color3.fromRGB(18, 18, 22),
    Surface = Color3.fromRGB(28, 28, 34),
    SurfaceSecondary = Color3.fromRGB(36, 36, 44),
    Border = Color3.fromRGB(48, 48, 58),
    Text = Color3.fromRGB(240, 240, 245),
    TextSecondary = Color3.fromRGB(160, 160, 175),
    Accent = Color3.fromRGB(99, 102, 241),
    AccentHover = Color3.fromRGB(129, 132, 255),
    Success = Color3.fromRGB(34, 197, 94),
    Warning = Color3.fromRGB(234, 179, 8),
    Error = Color3.fromRGB(239, 68, 68),
    ToggleOn = Color3.fromRGB(99, 102, 241),
    ToggleOff = Color3.fromRGB(60, 60, 72),
    SliderFill = Color3.fromRGB(99, 102, 241),
    InputBackground = Color3.fromRGB(24, 24, 30),
}

--@ Library
local Library = {
    Flags = {},
    _flagElements = {},
    _windows = {},
    _theme = Utility.DeepCopy(DefaultTheme),
    _registry = {},
    _dpi = 1,
    _unloaded = false,
    Icons = {
        ArrowDownUp = "rbxassetid://117405374619280",
        Keyboard = "rbxassetid://121978468376124",
        Input = "rbxassetid://84912489891242",
        Palette = "rbxassetid://127369887384101",
        Settings = "rbxassetid://106205298246017",
        MoreHorizontal = "rbxassetid://101330725759187",
        MoreVertical = "rbxassetid://76302166494262",
    },
    Animations = {
        Enabled = true,
        Duration = 0.18,
        Style = Enum.EasingStyle.Quart,
        Direction = Enum.EasingDirection.Out,
        Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        Normal = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        Slow = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        TabSwitch = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        Toggle = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        Dropdown = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    },
}

Library.OnFlagChanged = Signal.new()

function Library:SetFlag(flag, value, silent)
    if not flag then return end
    local old = self.Flags[flag]
    self.Flags[flag] = value
    local el = self._flagElements[flag]
    if el and el.SetValue and not silent then
        el:SetValue(value, true)
    end
    if not silent and old ~= value then
        self.OnFlagChanged:Fire(flag, value)
    end
end

function Library:GetFlag(flag)
    return self.Flags[flag]
end

function Library:HasFlag(flag)
    return self.Flags[flag] ~= nil
end

function Library:RegisterFlag(flag, element)
    if not flag then return end
    if self._flagElements[flag] and self._flagElements[flag] ~= element then
        warn("[Aether] Duplicate flag: " .. tostring(flag))
    end
    self._flagElements[flag] = element
end

function Library:UnregisterFlag(flag, element)
    if self._flagElements[flag] == element then
        self._flagElements[flag] = nil
    end
end

function Library:GetConfig()
    return Utility.DeepCopy(self.Flags)
end

function Library:LoadConfig(data)
    if type(data) ~= "table" then return end
    for flag, value in pairs(data) do
        local el = self._flagElements[flag]
        if el and el.SetValue then
            el:SetValue(value, true)
        end
        self.Flags[flag] = value
    end
end

function Library:ResetFlags()
    for flag, el in pairs(self._flagElements) do
        if el and el._default ~= nil then
            el:SetValue(el._default, true)
        end
    end
end

function Library:SetTheme(theme)
    if type(theme) == "string" then
        if theme == "Dark" then
            self._theme = Utility.DeepCopy(DefaultTheme)
        end
    elseif type(theme) == "table" then
        for k, v in pairs(theme) do
            self._theme[k] = v
        end
    end
    for inst, props in pairs(self._registry) do
        if inst and inst.Parent then
            for prop, key in pairs(props) do
                if self._theme[key] then
                    inst[prop] = self._theme[key]
                end
            end
        end
    end
end

function Library:RegisterTheme(inst, props)
    self._registry[inst] = props
    for prop, key in pairs(props) do
        if self._theme[key] then
            inst[prop] = self._theme[key]
        end
    end
end

function Library:GetTheme()
    return self._theme
end

function Library:GetIcon(name)
    if not name then return nil end
    if type(name) == "string" and name:find("rbxassetid://") then
        return name
    end
    return self.Icons[name]
end

function Library:SetDPI(scale)
    self._dpi = math.clamp(scale or 1, 0.5, 2)
    for _, win in ipairs(self._windows) do
        if win._uiScale then
            win._uiScale.Scale = self._dpi
        end
    end
end

function Library:Unload()
    if self._unloaded then return end
    self._unloaded = true
    for _, win in ipairs(self._windows) do
        if win.Destroy then
            win:Destroy()
        end
    end
    table.clear(self._windows)
    table.clear(self._flagElements)
    table.clear(self._registry)
    self.OnFlagChanged:Destroy()
end

--@ Base Element
local BaseElement = {}
BaseElement.__index = BaseElement

function BaseElement.new(parent, config)
    local self = setmetatable({}, BaseElement)
    self._parent = parent
    self._config = config or {}
    self._visible = true
    self._disabled = false
    self._connections = ConnectionManager.new()
    self._destroyed = false
    self.Changed = Signal.new()
    return self
end

function BaseElement:SetVisible(v)
    self._visible = v
    if self._frame then
        self._frame.Visible = v
    end
    return self
end

function BaseElement:SetDisabled(v)
    self._disabled = v
    if self._frame then
        self._frame.Active = not v
    end
    return self
end

function BaseElement:OnChanged(fn)
    return self.Changed:Connect(fn)
end

function BaseElement:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    self._connections:Destroy()
    self.Changed:Destroy()
    if self._flag then
        Library:UnregisterFlag(self._flag, self)
    end
    if self._frame then
        self._frame:Destroy()
    end
end

local function getContentParent(container)
    if container._content then
        return container._content
    end
    return container
end

--@ Toggle
local Toggle = setmetatable({}, { __index = BaseElement })
Toggle.__index = Toggle

function Toggle.new(container, text, config)
    config = config or {}
    local self = setmetatable(BaseElement.new(container, config), Toggle)
    self._text = text
    self._flag = config.Flag
    self._default = config.Default == true
    self._value = self._default
    self._callback = config.Callback

    local theme = Library:GetTheme()
    local parent = getContentParent(container)
    local height = config.Description and 36 or 32

    self._frame = Utility.Create("Frame", {
        Name = "Toggle",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height),
        Parent = parent,
    })

    self._label = Utility.Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.fromOffset(0, 0),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = theme.Text,
        Parent = self._frame,
    })
    Library:RegisterTheme(self._label, { TextColor3 = "Text" })

    if config.Description then
        self._label.Size = UDim2.new(1, -50, 0, 16)
        self._label.Position = UDim2.fromOffset(0, 2)
        self._desc = Utility.Create("TextLabel", {
            Name = "Description",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -50, 0, 12),
            Position = UDim2.fromOffset(0, 17),
            Font = Enum.Font.Gotham,
            Text = config.Description,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = theme.TextSecondary,
            Parent = self._frame,
        })
        Library:RegisterTheme(self._desc, { TextColor3 = "TextSecondary" })
    end

    self._box = Utility.Create("Frame", {
        Name = "Box",
        BackgroundColor3 = self._value and theme.ToggleOn or theme.ToggleOff,
        Size = UDim2.fromOffset(36, 20),
        Position = UDim2.new(1, -36, 0.5, -10),
        Parent = self._frame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = self._box })

    self._knob = Utility.Create("Frame", {
        Name = "Knob",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.fromOffset(16, 16),
        Position = self._value and UDim2.new(1, -18, 0.5, -8) or UDim2.fromOffset(2, 2),
        Parent = self._box,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = self._knob })

    local btn = Utility.Create("TextButton", {
        Name = "Hit",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        Parent = self._frame,
    })

    self._connections:Add(btn.MouseButton1Click:Connect(function()
        if self._disabled or self._destroyed then return end
        self:SetValue(not self._value)
    end))

    if self._flag then
        Library:RegisterFlag(self._flag, self)
        Library.Flags[self._flag] = self._value
    end

    return self
end

function Toggle:SetValue(value, silent)
    if self._destroyed then return self end
    value = value == true
    self._value = value
    local theme = Library:GetTheme()
    local info = Library.Animations.Toggle
    Utility.Tween(self._box, { BackgroundColor3 = value and theme.ToggleOn or theme.ToggleOff }, info)
    Utility.Tween(self._knob, {
        Position = value and UDim2.new(1, -18, 0.5, -8) or UDim2.fromOffset(2, 2),
    }, info)
    if self._flag then
        Library.Flags[self._flag] = value
    end
    if not silent then
        if self._callback then
            task.spawn(self._callback, value)
        end
        self.Changed:Fire(value)
    end
    return self
end

function Toggle:GetValue()
    return self._value
end

--@ Button
local Button = setmetatable({}, { __index = BaseElement })
Button.__index = Button

function Button.new(container, text, config)
    config = config or {}
    local self = setmetatable(BaseElement.new(container, config), Button)
    self._text = text
    self._callback = config.Callback

    local theme = Library:GetTheme()
    local parent = getContentParent(container)

    self._frame = Utility.Create("Frame", {
        Name = "Button",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = parent,
    })

    self._btn = Utility.Create("TextButton", {
        Name = "Btn",
        BackgroundColor3 = theme.SurfaceSecondary,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextSize = 13,
        TextColor3 = theme.Text,
        AutoButtonColor = false,
        Parent = self._frame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = self._btn })
    Library:RegisterTheme(self._btn, { BackgroundColor3 = "SurfaceSecondary", TextColor3 = "Text" })

    local fast = Library.Animations.Fast
    self._connections:Add(self._btn.MouseEnter:Connect(function()
        if self._disabled then return end
        Utility.Tween(self._btn, { BackgroundColor3 = theme.Border }, fast)
    end))
    self._connections:Add(self._btn.MouseLeave:Connect(function()
        Utility.Tween(self._btn, { BackgroundColor3 = theme.SurfaceSecondary }, fast)
    end))
    self._connections:Add(self._btn.MouseButton1Click:Connect(function()
        if self._disabled or self._destroyed then return end
        if self._callback then
            task.spawn(self._callback)
        end
        self.Changed:Fire()
    end))

    return self
end

function Button:SetText(text)
    self._text = text
    if self._btn then
        self._btn.Text = text
    end
    return self
end

--@ Slider
local Slider = setmetatable({}, { __index = BaseElement })
Slider.__index = Slider

function Slider.new(container, text, config)
    config = config or {}
    local self = setmetatable(BaseElement.new(container, config), Slider)
    self._text = text
    self._flag = config.Flag
    self._min = config.Min or 0
    self._max = config.Max or 100
    self._default = config.Default or self._min
    self._value = self._default
    self._rounding = config.Rounding or 0
    self._suffix = config.Suffix or ""
    self._prefix = config.Prefix or ""
    self._callback = config.Callback
    self._editing = false

    local theme = Library:GetTheme()
    local parent = getContentParent(container)

    self._frame = Utility.Create("Frame", {
        Name = "Slider",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 48),
        Parent = parent,
    })

    self._label = Utility.Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -70, 0, 16),
        Position = UDim2.fromOffset(0, 0),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = theme.Text,
        Parent = self._frame,
    })
    Library:RegisterTheme(self._label, { TextColor3 = "Text" })

    self._valueBox = Utility.Create("TextBox", {
        Name = "Value",
        BackgroundColor3 = theme.InputBackground,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(64, 18),
        Position = UDim2.new(1, -64, 0, -1),
        Font = Enum.Font.Gotham,
        Text = self._prefix .. tostring(self._value) .. self._suffix,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = theme.TextSecondary,
        ClearTextOnFocus = false,
        Parent = self._frame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = self._valueBox })
    Library:RegisterTheme(self._valueBox, { TextColor3 = "TextSecondary" })

    self._track = Utility.Create("Frame", {
        Name = "Track",
        BackgroundColor3 = theme.SurfaceSecondary,
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.fromOffset(0, 28),
        Parent = self._frame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = self._track })
    Library:RegisterTheme(self._track, { BackgroundColor3 = "SurfaceSecondary" })

    self._fill = Utility.Create("Frame", {
        Name = "Fill",
        BackgroundColor3 = theme.SliderFill,
        Size = UDim2.new(0, 0, 1, 0),
        Parent = self._track,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = self._fill })
    Library:RegisterTheme(self._fill, { BackgroundColor3 = "SliderFill" })

    self._knob = Utility.Create("Frame", {
        Name = "Knob",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.new(0, -7, 0.5, -7),
        Parent = self._track,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = self._knob })

    local dragging = false
    local function updateFromX(x)
        local rel = math.clamp((x - self._track.AbsolutePosition.X) / math.max(self._track.AbsoluteSize.X, 1), 0, 1)
        local raw = self._min + (self._max - self._min) * rel
        local val = Utility.Round(raw, self._rounding)
        self:SetValue(val)
    end

    self._connections:Add(self._track.InputBegan:Connect(function(input)
        if self._disabled or self._destroyed or self._editing then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end))
    self._connections:Add(Services.UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            updateFromX(input.Position.X)
        end
    end))
    self._connections:Add(Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    self._connections:Add(self._valueBox.Focused:Connect(function()
        if self._disabled or self._destroyed then return end
        self._editing = true
        self._valueBox.BackgroundTransparency = 0
        self._valueBox.Text = tostring(self._value)
        self._valueBox.TextXAlignment = Enum.TextXAlignment.Center
        self._valueBox.TextColor3 = theme.Text
    end))

    self._connections:Add(self._valueBox.FocusLost:Connect(function(enter)
        self._editing = false
        self._valueBox.BackgroundTransparency = 1
        self._valueBox.TextXAlignment = Enum.TextXAlignment.Right
        self._valueBox.TextColor3 = theme.TextSecondary
        local n = tonumber(self._valueBox.Text)
        if n then
            self:SetValue(n)
        else
            self._valueBox.Text = self._prefix .. tostring(self._value) .. self._suffix
        end
    end))

    if self._flag then
        Library:RegisterFlag(self._flag, self)
        Library.Flags[self._flag] = self._value
    end
    self:SetValue(self._value, true)

    return self
end

function Slider:SetValue(value, silent)
    if self._destroyed then return self end
    value = math.clamp(Utility.Round(value, self._rounding), self._min, self._max)
    self._value = value
    local pct = (self._max == self._min) and 0 or (value - self._min) / (self._max - self._min)
    self._fill.Size = UDim2.new(pct, 0, 1, 0)
    self._knob.Position = UDim2.new(pct, -7, 0.5, -7)
    if not self._editing then
        self._valueBox.Text = self._prefix .. tostring(value) .. self._suffix
    end
    if self._flag then
        Library.Flags[self._flag] = value
    end
    if not silent then
        if self._callback then
            task.spawn(self._callback, value)
        end
        self.Changed:Fire(value)
    end
    return self
end

function Slider:GetValue()
    return self._value
end

--@ Dropdown
local Dropdown = setmetatable({}, { __index = BaseElement })
Dropdown.__index = Dropdown

function Dropdown.new(container, text, config)
    config = config or {}
    local self = setmetatable(BaseElement.new(container, config), Dropdown)
    self._text = text
    self._flag = config.Flag
    self._values = config.Values or {}
    self._multi = config.Multi == true
    self._default = config.Default
    self._callback = config.Callback
    self._open = false
    self._selected = {}

    if self._multi then
        if type(self._default) == "table" then
            for _, v in ipairs(self._default) do
                self._selected[v] = true
            end
        end
    else
        self._value = self._default or (self._values[1] or nil)
    end

    local theme = Library:GetTheme()
    local parent = getContentParent(container)

    self._frame = Utility.Create("Frame", {
        Name = "Dropdown",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 52),
        ClipsDescendants = false,
        Parent = parent,
        ZIndex = 5,
    })

    self._label = Utility.Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = theme.Text,
        Parent = self._frame,
    })
    Library:RegisterTheme(self._label, { TextColor3 = "Text" })

    self._box = Utility.Create("TextButton", {
        Name = "Box",
        BackgroundColor3 = theme.InputBackground,
        Size = UDim2.new(1, 0, 0, 28),
        Position = UDim2.fromOffset(0, 20),
        Font = Enum.Font.Gotham,
        Text = "",
        TextSize = 12,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        Parent = self._frame,
        ZIndex = 6,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = self._box })
    Utility.Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 28), Parent = self._box })
    Library:RegisterTheme(self._box, { BackgroundColor3 = "InputBackground", TextColor3 = "Text" })

    local arrowId = Library:GetIcon("ArrowDownUp")
    self._arrow = Utility.Create("ImageLabel", {
        Name = "Arrow",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.new(1, -22, 0.5, -7),
        Image = arrowId or "",
        ImageColor3 = theme.TextSecondary,
        Parent = self._box,
        ZIndex = 7,
    })

    self._list = Utility.Create("Frame", {
        Name = "List",
        BackgroundColor3 = theme.Surface,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.fromOffset(0, 52),
        Visible = false,
        ClipsDescendants = true,
        Parent = self._frame,
        ZIndex = 20,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = self._list })
    Utility.Create("UIStroke", { Color = theme.Border, Thickness = 1, Parent = self._list })
    Library:RegisterTheme(self._list, { BackgroundColor3 = "Surface" })

    Utility.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = self._list,
    })
    Utility.Create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        Parent = self._list,
    })

    local function refreshDisplay()
        if self._multi then
            local parts = {}
            for _, v in ipairs(self._values) do
                if self._selected[v] then
                    table.insert(parts, tostring(v))
                end
            end
            self._box.Text = #parts > 0 and table.concat(parts, ", ") or "None"
        else
            self._box.Text = self._value and tostring(self._value) or "Select..."
        end
    end

    local function rebuildList()
        for _, child in ipairs(self._list:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        for i, val in ipairs(self._values) do
            local item = Utility.Create("TextButton", {
                Name = "Item",
                BackgroundColor3 = theme.SurfaceSecondary,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 26),
                Font = Enum.Font.Gotham,
                Text = "  " .. tostring(val),
                TextSize = 12,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                LayoutOrder = i,
                Parent = self._list,
                ZIndex = 21,
            })
            Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = item })

            local isSelected = self._multi and self._selected[val] or (self._value == val)
            if isSelected then
                item.BackgroundTransparency = 0
                item.BackgroundColor3 = theme.Accent
            end

            self._connections:Add(item.MouseEnter:Connect(function()
                if not (self._multi and self._selected[val]) and self._value ~= val then
                    item.BackgroundTransparency = 0
                    item.BackgroundColor3 = theme.Border
                end
            end))
            self._connections:Add(item.MouseLeave:Connect(function()
                local sel = self._multi and self._selected[val] or (self._value == val)
                if not sel then
                    item.BackgroundTransparency = 1
                else
                    item.BackgroundColor3 = theme.Accent
                end
            end))
            self._connections:Add(item.MouseButton1Click:Connect(function()
                if self._disabled then return end
                if self._multi then
                    self._selected[val] = not self._selected[val]
                    item.BackgroundTransparency = self._selected[val] and 0 or 1
                    item.BackgroundColor3 = self._selected[val] and theme.Accent or theme.Border
                    local result = {}
                    for _, v in ipairs(self._values) do
                        if self._selected[v] then
                            table.insert(result, v)
                        end
                    end
                    if self._flag then
                        Library.Flags[self._flag] = result
                    end
                    if self._callback then
                        task.spawn(self._callback, result)
                    end
                    self.Changed:Fire(result)
                    refreshDisplay()
                else
                    self:SetValue(val)
                    self:Close()
                end
            end))
        end
        local count = #self._values
        local h = math.min(count * 28 + 8, 160)
        self._list.Size = UDim2.new(1, 0, 0, h)
    end

    function self:Open()
        if self._open or self._destroyed then return end
        self._open = true
        rebuildList()
        self._list.Visible = true
        self._frame.Size = UDim2.new(1, 0, 0, 52 + self._list.Size.Y.Offset + 4)
        self._frame.ZIndex = 50
    end

    function self:Close()
        if not self._open then return end
        self._open = false
        self._list.Visible = false
        self._frame.Size = UDim2.new(1, 0, 0, 52)
        self._frame.ZIndex = 5
    end

    self._connections:Add(self._box.MouseButton1Click:Connect(function()
        if self._disabled or self._destroyed then return end
        if self._open then
            self:Close()
        else
            self:Open()
        end
    end))

    refreshDisplay()
    if self._flag then
        Library:RegisterFlag(self._flag, self)
        if self._multi then
            local result = {}
            for _, v in ipairs(self._values) do
                if self._selected[v] then
                    table.insert(result, v)
                end
            end
            Library.Flags[self._flag] = result
        else
            Library.Flags[self._flag] = self._value
        end
    end

    return self
end

function Dropdown:SetValue(value, silent)
    if self._destroyed then return self end
    if self._multi then
        self._selected = {}
        if type(value) == "table" then
            for _, v in ipairs(value) do
                self._selected[v] = true
            end
        end
        local result = {}
        for _, v in ipairs(self._values) do
            if self._selected[v] then
                table.insert(result, v)
            end
        end
        if self._flag then
            Library.Flags[self._flag] = result
        end
        if not silent then
            if self._callback then
                task.spawn(self._callback, result)
            end
            self.Changed:Fire(result)
        end
    else
        self._value = value
        self._box.Text = value and tostring(value) or "Select..."
        if self._flag then
            Library.Flags[self._flag] = value
        end
        if not silent then
            if self._callback then
                task.spawn(self._callback, value)
            end
            self.Changed:Fire(value)
        end
    end
    return self
end

function Dropdown:GetValue()
    if self._multi then
        local result = {}
        for _, v in ipairs(self._values) do
            if self._selected[v] then
                table.insert(result, v)
            end
        end
        return result
    end
    return self._value
end

function Dropdown:SetValues(values)
    self._values = values or {}
    return self
end

--@ Input
local Input = setmetatable({}, { __index = BaseElement })
Input.__index = Input

function Input.new(container, text, config)
    config = config or {}
    local self = setmetatable(BaseElement.new(container, config), Input)
    self._text = text
    self._flag = config.Flag
    self._default = config.Default or ""
    self._value = self._default
    self._placeholder = config.Placeholder or ""
    self._numeric = config.Numeric == true
    self._callback = config.Callback
    self._finished = config.Finished

    local theme = Library:GetTheme()
    local parent = getContentParent(container)

    self._frame = Utility.Create("Frame", {
        Name = "Input",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 52),
        Parent = parent,
    })

    self._label = Utility.Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = theme.Text,
        Parent = self._frame,
    })
    Library:RegisterTheme(self._label, { TextColor3 = "Text" })

    self._box = Utility.Create("TextBox", {
        Name = "Box",
        BackgroundColor3 = theme.InputBackground,
        Size = UDim2.new(1, 0, 0, 28),
        Position = UDim2.fromOffset(0, 20),
        Font = Enum.Font.Gotham,
        Text = self._value,
        PlaceholderText = self._placeholder,
        TextSize = 12,
        TextColor3 = theme.Text,
        PlaceholderColor3 = theme.TextSecondary,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = self._frame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = self._box })
    Utility.Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = self._box })
    Library:RegisterTheme(self._box, { BackgroundColor3 = "InputBackground", TextColor3 = "Text" })

    local iconId = Library:GetIcon("Input")
    if iconId then
        self._box.Size = UDim2.new(1, -28, 0, 28)
        Utility.Create("ImageLabel", {
            Name = "Icon",
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(14, 14),
            Position = UDim2.new(1, -20, 0, 27),
            Image = iconId,
            ImageColor3 = theme.TextSecondary,
            Parent = self._frame,
        })
    end

    self._connections:Add(self._box.FocusLost:Connect(function(enter)
        local textVal = self._box.Text
        if self._numeric then
            local n = tonumber(textVal)
            if n then
                textVal = tostring(n)
                self._box.Text = textVal
            else
                self._box.Text = self._value
                return
            end
        end
        self:SetValue(textVal)
        if self._finished and enter then
            task.spawn(self._finished, textVal)
        end
    end))

    if self._flag then
        Library:RegisterFlag(self._flag, self)
        Library.Flags[self._flag] = self._value
    end

    return self
end

function Input:SetValue(value, silent)
    if self._destroyed then return self end
    self._value = tostring(value or "")
    self._box.Text = self._value
    if self._flag then
        Library.Flags[self._flag] = self._value
    end
    if not silent then
        if self._callback then
            task.spawn(self._callback, self._value)
        end
        self.Changed:Fire(self._value)
    end
    return self
end

function Input:GetValue()
    return self._value
end

--@ Label
local Label = setmetatable({}, { __index = BaseElement })
Label.__index = Label

function Label.new(container, text, config)
    config = config or {}
    local self = setmetatable(BaseElement.new(container, config), Label)
    self._text = text

    local theme = Library:GetTheme()
    local parent = getContentParent(container)

    self._frame = Utility.Create("Frame", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Parent = parent,
    })

    self._label = Utility.Create("TextLabel", {
        Name = "Text",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Enum.Font.Gotham,
        Text = text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = theme.TextSecondary,
        TextWrapped = true,
        Parent = self._frame,
    })
    Library:RegisterTheme(self._label, { TextColor3 = "TextSecondary" })

    return self
end

function Label:SetText(text)
    self._text = text
    if self._label then
        self._label.Text = text
    end
    return self
end

--@ Divider
local Divider = setmetatable({}, { __index = BaseElement })
Divider.__index = Divider

function Divider.new(container, config)
    config = config or {}
    local self = setmetatable(BaseElement.new(container, config), Divider)
    local theme = Library:GetTheme()
    local parent = getContentParent(container)

    self._frame = Utility.Create("Frame", {
        Name = "Divider",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 12),
        Parent = parent,
    })

    self._line = Utility.Create("Frame", {
        Name = "Line",
        BackgroundColor3 = theme.Border,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0.5, 0),
        Parent = self._frame,
    })
    Library:RegisterTheme(self._line, { BackgroundColor3 = "Border" })

    return self
end

--@ Keybind
local Keybind = setmetatable({}, { __index = BaseElement })
Keybind.__index = Keybind

function Keybind.new(container, text, config)
    config = config or {}
    local self = setmetatable(BaseElement.new(container, config), Keybind)
    self._text = text
    self._flag = config.Flag
    self._default = config.Default or Enum.KeyCode.Unknown
    self._value = self._default
    self._mode = config.Mode or "Toggle"
    self._callback = config.Callback
    self._listening = false

    local theme = Library:GetTheme()
    local parent = getContentParent(container)

    self._frame = Utility.Create("Frame", {
        Name = "Keybind",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = parent,
    })

    self._label = Utility.Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -90, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = theme.Text,
        Parent = self._frame,
    })
    Library:RegisterTheme(self._label, { TextColor3 = "Text" })

    self._box = Utility.Create("TextButton", {
        Name = "Box",
        BackgroundColor3 = theme.SurfaceSecondary,
        Size = UDim2.fromOffset(80, 24),
        Position = UDim2.new(1, -80, 0.5, -12),
        Font = Enum.Font.Gotham,
        Text = self._value.Name == "Unknown" and "None" or self._value.Name,
        TextSize = 11,
        TextColor3 = theme.Text,
        AutoButtonColor = false,
        Parent = self._frame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = self._box })
    Library:RegisterTheme(self._box, { BackgroundColor3 = "SurfaceSecondary", TextColor3 = "Text" })

    local iconId = Library:GetIcon("Keyboard")
    if iconId then
        Utility.Create("ImageLabel", {
            Name = "Icon",
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(12, 12),
            Position = UDim2.fromOffset(6, 6),
            Image = iconId,
            ImageColor3 = theme.TextSecondary,
            Parent = self._box,
        })
        self._box.TextXAlignment = Enum.TextXAlignment.Right
        Utility.Create("UIPadding", { PaddingRight = UDim.new(0, 8), Parent = self._box })
    end

    self._connections:Add(self._box.MouseButton1Click:Connect(function()
        if self._disabled or self._destroyed then return end
        self._listening = true
        self._box.Text = "..."
    end))

    self._connections:Add(Services.UserInputService.InputBegan:Connect(function(input, gp)
        if not self._listening then
            if self._value and input.KeyCode == self._value and not gp then
                if self._callback then
                    task.spawn(self._callback)
                end
                self.Changed:Fire(self._value)
            end
            return
        end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            self._listening = false
            if input.KeyCode == Enum.KeyCode.Escape then
                self:SetValue(Enum.KeyCode.Unknown)
            else
                self:SetValue(input.KeyCode)
            end
        end
    end))

    if self._flag then
        Library:RegisterFlag(self._flag, self)
        Library.Flags[self._flag] = self._value
    end

    return self
end

function Keybind:SetValue(value, silent)
    if self._destroyed then return self end
    self._value = value or Enum.KeyCode.Unknown
    self._box.Text = self._value.Name == "Unknown" and "None" or self._value.Name
    if self._flag then
        Library.Flags[self._flag] = self._value
    end
    if not silent then
        self.Changed:Fire(self._value)
    end
    return self
end

function Keybind:GetValue()
    return self._value
end

--@ ColorPicker
local ColorPicker = setmetatable({}, { __index = BaseElement })
ColorPicker.__index = ColorPicker

function ColorPicker.new(container, text, config)
    config = config or {}
    local self = setmetatable(BaseElement.new(container, config), ColorPicker)
    self._text = text
    self._flag = config.Flag
    self._default = config.Default or Color3.fromRGB(255, 255, 255)
    self._value = self._default
    self._callback = config.Callback

    local theme = Library:GetTheme()
    local parent = getContentParent(container)

    self._frame = Utility.Create("Frame", {
        Name = "ColorPicker",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = parent,
    })

    self._label = Utility.Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = theme.Text,
        Parent = self._frame,
    })
    Library:RegisterTheme(self._label, { TextColor3 = "Text" })

    self._preview = Utility.Create("TextButton", {
        Name = "Preview",
        BackgroundColor3 = self._value,
        Size = UDim2.fromOffset(28, 20),
        Position = UDim2.new(1, -28, 0.5, -10),
        Text = "",
        AutoButtonColor = false,
        Parent = self._frame,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = self._preview })
    Utility.Create("UIStroke", { Color = theme.Border, Thickness = 1, Parent = self._preview })

    self._connections:Add(self._preview.MouseButton1Click:Connect(function()
        if self._disabled or self._destroyed then return end
        local h, s, v = self._value:ToHSV()
        h = (h + 0.1) % 1
        self:SetValue(Color3.fromHSV(h, s, v))
    end))

    if self._flag then
        Library:RegisterFlag(self._flag, self)
        Library.Flags[self._flag] = self._value
    end

    return self
end

function ColorPicker:SetValue(value, silent)
    if self._destroyed then return self end
    self._value = value
    self._preview.BackgroundColor3 = value
    if self._flag then
        Library.Flags[self._flag] = value
    end
    if not silent then
        if self._callback then
            task.spawn(self._callback, value)
        end
        self.Changed:Fire(value)
    end
    return self
end

function ColorPicker:GetValue()
    return self._value
end

--@ Groupbox
local Groupbox = {}
Groupbox.__index = Groupbox

function Groupbox.new(tab, config)
    local self = setmetatable({}, Groupbox)
    self._tab = tab
    self._name = config.Name or "Group"
    self._elements = {}
    self._destroyed = false

    local theme = Library:GetTheme()
    local parent = tab._scrollContent

    self._frame = Utility.Create("Frame", {
        Name = "Groupbox",
        BackgroundColor3 = theme.Surface,
        Size = UDim2.new(1, 0, 0, 40),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = parent,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self._frame })
    Utility.Create("UIStroke", { Color = theme.Border, Thickness = 1, Parent = self._frame })
    Library:RegisterTheme(self._frame, { BackgroundColor3 = "Surface" })

    self._title = Utility.Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 0, 28),
        Position = UDim2.fromOffset(10, 4),
        Font = Enum.Font.GothamBold,
        Text = self._name,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = theme.Text,
        Parent = self._frame,
    })
    Library:RegisterTheme(self._title, { TextColor3 = "Text" })

    self._content = Utility.Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 0, 0),
        Position = UDim2.fromOffset(8, 32),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self._frame,
    })
    Utility.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = self._content,
    })
    Utility.Create("UIPadding", {
        PaddingBottom = UDim.new(0, 10),
        Parent = self._content,
    })

    return self
end

function Groupbox:AddToggle(text, config)
    local el = Toggle.new(self, text, config)
    table.insert(self._elements, el)
    return el
end

function Groupbox:AddButton(text, config)
    local el = Button.new(self, text, config)
    table.insert(self._elements, el)
    return el
end

function Groupbox:AddSlider(text, config)
    local el = Slider.new(self, text, config)
    table.insert(self._elements, el)
    return el
end

function Groupbox:AddDropdown(text, config)
    local el = Dropdown.new(self, text, config)
    table.insert(self._elements, el)
    return el
end

function Groupbox:AddInput(text, config)
    local el = Input.new(self, text, config)
    table.insert(self._elements, el)
    return el
end

function Groupbox:AddLabel(text, config)
    local el = Label.new(self, text, config)
    table.insert(self._elements, el)
    return el
end

function Groupbox:AddDivider(config)
    local el = Divider.new(self, config)
    table.insert(self._elements, el)
    return el
end

function Groupbox:AddKeybind(text, config)
    local el = Keybind.new(self, text, config)
    table.insert(self._elements, el)
    return el
end

function Groupbox:AddColorPicker(text, config)
    local el = ColorPicker.new(self, text, config)
    table.insert(self._elements, el)
    return el
end

function Groupbox:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for _, el in ipairs(self._elements) do
        if el.Destroy then
            el:Destroy()
        end
    end
    table.clear(self._elements)
    if self._frame then
        self._frame:Destroy()
    end
end

--@ Tab
local Tab = {}
Tab.__index = Tab

function Tab.new(window, config, parentList)
    local self = setmetatable({}, Tab)
    self._window = window
    self._name = config.Name or "Tab"
    self._icon = config.Icon
    self._full = config.Full == true or config.Type == 2
    self._active = false
    self._groupboxes = {}
    self._elements = {}
    self._destroyed = false

    local theme = Library:GetTheme()
    local listParent = parentList or window._sidebarList

    self._button = Utility.Create("TextButton", {
        Name = self._name,
        BackgroundColor3 = theme.SurfaceSecondary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -12, 0, 36),
        Text = "",
        AutoButtonColor = false,
        Parent = listParent,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = self._button })

    local hasIcon = Library:GetIcon(self._icon) ~= nil
    local textOffset = hasIcon and 34 or 12

    if hasIcon then
        self._iconImage = Utility.Create("ImageLabel", {
            Name = "Icon",
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(16, 16),
            Position = UDim2.fromOffset(10, 10),
            Image = Library:GetIcon(self._icon),
            ImageColor3 = theme.TextSecondary,
            Parent = self._button,
        })
    end

    self._buttonLabel = Utility.Create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -(textOffset + 8), 1, 0),
        Position = UDim2.fromOffset(textOffset, 0),
        Font = Enum.Font.GothamMedium,
        Text = self._name,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = theme.TextSecondary,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = self._button,
    })
    Library:RegisterTheme(self._buttonLabel, { TextColor3 = "TextSecondary" })

    self._page = Utility.Create("Frame", {
        Name = self._name,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        Parent = window._content,
    })

    self._scroll = Utility.Create("ScrollingFrame", {
        Name = "Scroll",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.Border,
        BorderSizePixel = 0,
        Parent = self._page,
    })

    self._scrollContent = Utility.Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self._scroll,
    })
    Utility.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
        Parent = self._scrollContent,
    })
    Utility.Create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 6),
        Parent = self._scrollContent,
    })

    if self._full then
        self._content = Utility.Create("Frame", {
            Name = "Direct",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = self._scrollContent,
            LayoutOrder = 0,
        })
        Utility.Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            Parent = self._content,
        })
    end

    self._button.MouseButton1Click:Connect(function()
        window:SelectTab(self)
    end)

    return self
end

function Tab:AddGroupbox(config)
    if type(config) == "string" then
        config = { Name = config }
    end
    local gb = Groupbox.new(self, config or {})
    table.insert(self._groupboxes, gb)
    return gb
end

function Tab:AddToggle(text, config)
    if not self._full then
        warn("[Aether] Tab:AddToggle requires Full = true (Type 2). Use Groupbox instead.")
        return nil
    end
    local el = Toggle.new(self, text, config)
    table.insert(self._elements, el)
    return el
end

function Tab:AddButton(text, config)
    if not self._full then
        warn("[Aether] Tab:AddButton requires Full = true (Type 2). Use Groupbox instead.")
        return nil
    end
    local el = Button.new(self, text, config)
    table.insert(self._elements, el)
    return el
end

function Tab:AddSlider(text, config)
    if not self._full then
        warn("[Aether] Tab:AddSlider requires Full = true (Type 2). Use Groupbox instead.")
        return nil
    end
    local el = Slider.new(self, text, config)
    table.insert(self._elements, el)
    return el
end

function Tab:AddDropdown(text, config)
    if not self._full then
        warn("[Aether] Tab:AddDropdown requires Full = true (Type 2). Use Groupbox instead.")
        return nil
    end
    local el = Dropdown.new(self, text, config)
    table.insert(self._elements, el)
    return el
end

function Tab:AddInput(text, config)
    if not self._full then
        warn("[Aether] Tab:AddInput requires Full = true (Type 2). Use Groupbox instead.")
        return nil
    end
    local el = Input.new(self, text, config)
    table.insert(self._elements, el)
    return el
end

function Tab:AddLabel(text, config)
    if not self._full then
        warn("[Aether] Tab:AddLabel requires Full = true (Type 2). Use Groupbox instead.")
        return nil
    end
    local el = Label.new(self, text, config)
    table.insert(self._elements, el)
    return el
end

function Tab:AddDivider(config)
    if not self._full then
        warn("[Aether] Tab:AddDivider requires Full = true (Type 2). Use Groupbox instead.")
        return nil
    end
    local el = Divider.new(self, config)
    table.insert(self._elements, el)
    return el
end

function Tab:AddKeybind(text, config)
    if not self._full then
        warn("[Aether] Tab:AddKeybind requires Full = true (Type 2). Use Groupbox instead.")
        return nil
    end
    local el = Keybind.new(self, text, config)
    table.insert(self._elements, el)
    return el
end

function Tab:AddColorPicker(text, config)
    if not self._full then
        warn("[Aether] Tab:AddColorPicker requires Full = true (Type 2). Use Groupbox instead.")
        return nil
    end
    local el = ColorPicker.new(self, text, config)
    table.insert(self._elements, el)
    return el
end

function Tab:SetActive(active)
    self._active = active
    self._page.Visible = active
    local theme = Library:GetTheme()
    if active then
        self._button.BackgroundTransparency = 0
        self._button.BackgroundColor3 = theme.SurfaceSecondary
        self._buttonLabel.TextColor3 = theme.Text
        if self._iconImage then
            self._iconImage.ImageColor3 = theme.Text
        end
    else
        self._button.BackgroundTransparency = 1
        self._buttonLabel.TextColor3 = theme.TextSecondary
        if self._iconImage then
            self._iconImage.ImageColor3 = theme.TextSecondary
        end
    end
end

function Tab:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for _, gb in ipairs(self._groupboxes) do
        gb:Destroy()
    end
    for _, el in ipairs(self._elements) do
        if el.Destroy then
            el:Destroy()
        end
    end
    table.clear(self._groupboxes)
    table.clear(self._elements)
    if self._button then self._button:Destroy() end
    if self._page then self._page:Destroy() end
end

--@ TabGroup
local TabGroup = {}
TabGroup.__index = TabGroup

function TabGroup.new(window, config)
    local self = setmetatable({}, TabGroup)
    self._window = window
    self._name = config.Name or ""
    self._tabs = {}
    self._destroyed = false

    local theme = Library:GetTheme()

    self._frame = Utility.Create("Frame", {
        Name = "TabGroup",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = window._sidebarList,
    })

    if self._name ~= "" then
        self._header = Utility.Create("TextLabel", {
            Name = "Header",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 22),
            Font = Enum.Font.GothamBold,
            Text = string.upper(self._name),
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = theme.TextSecondary,
            Parent = self._frame,
        })
        Utility.Create("UIPadding", {
            PaddingLeft = UDim.new(0, 6),
            Parent = self._header,
        })
        Library:RegisterTheme(self._header, { TextColor3 = "TextSecondary" })
    end

    self._list = Utility.Create("Frame", {
        Name = "List",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self._frame,
    })
    Utility.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = self._list,
    })

    return self
end

function TabGroup:AddTab(config)
    if type(config) == "string" then
        config = { Name = config }
    end
    local tab = Tab.new(self._window, config or {}, self._list)
    table.insert(self._tabs, tab)
    table.insert(self._window._tabs, tab)
    if not self._window._activeTab then
        self._window:SelectTab(tab)
    end
    return tab
end

function TabGroup:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for _, tab in ipairs(self._tabs) do
        tab:Destroy()
    end
    table.clear(self._tabs)
    if self._frame then
        self._frame:Destroy()
    end
end

--@ Window
local Window = {}
Window.__index = Window

function Window.new(config)
    local self = setmetatable({}, Window)
    self._title = config.Title or "Aether"
    self._subtitle = config.Subtitle or ""
    self._size = config.Size or UDim2.fromOffset(580, 420)
    self._tabs = {}
    self._tabGroups = {}
    self._activeTab = nil
    self._connections = ConnectionManager.new()
    self._destroyed = false
    self._minimized = false

    local theme = Library:GetTheme()

    self._gui = Utility.Create("ScreenGui", {
        Name = "Aether",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
        IgnoreGuiInset = true,
    })
    pcall(protectgui, self._gui)
    self._gui.Parent = gethui()

    self._uiScale = Utility.Create("UIScale", {
        Scale = Library._dpi,
        Parent = self._gui,
    })

    self._main = Utility.Create("Frame", {
        Name = "Main",
        BackgroundColor3 = theme.Background,
        Size = self._size,
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Parent = self._gui,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = self._main })
    Utility.Create("UIStroke", { Color = theme.Border, Thickness = 1, Parent = self._main })
    Library:RegisterTheme(self._main, { BackgroundColor3 = "Background" })

    self._topbar = Utility.Create("Frame", {
        Name = "Topbar",
        BackgroundColor3 = theme.Surface,
        Size = UDim2.new(1, 0, 0, 42),
        Parent = self._main,
    })
    Utility.Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = self._topbar })
    Library:RegisterTheme(self._topbar, { BackgroundColor3 = "Surface" })

    Utility.Create("Frame", {
        Name = "TopbarFix",
        BackgroundColor3 = theme.Surface,
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BorderSizePixel = 0,
        Parent = self._topbar,
    })

    self._titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -80, 0, 20),
        Position = UDim2.fromOffset(14, 6),
        Font = Enum.Font.GothamBold,
        Text = self._title,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = theme.Text,
        Parent = self._topbar,
    })
    Library:RegisterTheme(self._titleLabel, { TextColor3 = "Text" })

    if self._subtitle ~= "" then
        self._subLabel = Utility.Create("TextLabel", {
            Name = "Subtitle",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -80, 0, 14),
            Position = UDim2.fromOffset(14, 24),
            Font = Enum.Font.Gotham,
            Text = self._subtitle,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = theme.TextSecondary,
            Parent = self._topbar,
        })
        Library:RegisterTheme(self._subLabel, { TextColor3 = "TextSecondary" })
    end

    self._closeBtn = Utility.Create("TextButton", {
        Name = "Close",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -34, 0, 7),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextSize = 18,
        TextColor3 = theme.TextSecondary,
        Parent = self._topbar,
    })
    self._connections:Add(self._closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end))

    self._minBtn = Utility.Create("TextButton", {
        Name = "Min",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -62, 0, 7),
        Font = Enum.Font.GothamBold,
        Text = "–",
        TextSize = 16,
        TextColor3 = theme.TextSecondary,
        Parent = self._topbar,
    })
    self._connections:Add(self._minBtn.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
    end))

    self._sidebar = Utility.Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = theme.Surface,
        Size = UDim2.new(0, 148, 1, -42),
        Position = UDim2.fromOffset(0, 42),
        Parent = self._main,
    })
    Library:RegisterTheme(self._sidebar, { BackgroundColor3 = "Surface" })

    self._sidebarList = Utility.Create("ScrollingFrame", {
        Name = "List",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -8),
        Position = UDim2.fromOffset(0, 4),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        BorderSizePixel = 0,
        Parent = self._sidebar,
    })
    Utility.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Parent = self._sidebarList,
    })
    Utility.Create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 8),
        Parent = self._sidebarList,
    })

    self._content = Utility.Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -160, 1, -54),
        Position = UDim2.fromOffset(154, 48),
        Parent = self._main,
    })

    local dragging, dragStart, startPos
    self._connections:Add(self._topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self._main.Position
        end
    end))
    self._connections:Add(Services.UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            self._main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
    self._connections:Add(Services.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    table.insert(Library._windows, self)
    return self
end

function Window:AddTab(config)
    if type(config) == "string" then
        config = { Name = config }
    end
    local tab = Tab.new(self, config or {})
    table.insert(self._tabs, tab)
    if not self._activeTab then
        self:SelectTab(tab)
    end
    return tab
end

function Window:AddTabGroup(config)
    if type(config) == "string" then
        config = { Name = config }
    end
    local group = TabGroup.new(self, config or {})
    table.insert(self._tabGroups, group)
    return group
end

function Window:SelectTab(tab)
    if self._activeTab == tab then return end
    if self._activeTab then
        self._activeTab:SetActive(false)
    end
    self._activeTab = tab
    tab:SetActive(true)
end

function Window:ToggleMinimize()
    self._minimized = not self._minimized
    if self._minimized then
        self._sidebar.Visible = false
        self._content.Visible = false
        self._main.Size = UDim2.new(self._size.X.Scale, self._size.X.Offset, 0, 42)
    else
        self._sidebar.Visible = true
        self._content.Visible = true
        self._main.Size = self._size
    end
end

function Window:SetDPI(scale)
    Library:SetDPI(scale)
end

function Window:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    self._connections:Destroy()
    for _, group in ipairs(self._tabGroups) do
        group:Destroy()
    end
    for _, tab in ipairs(self._tabs) do
        if not tab._destroyed then
            tab:Destroy()
        end
    end
    table.clear(self._tabs)
    table.clear(self._tabGroups)
    if self._gui then
        self._gui:Destroy()
    end
    for i, w in ipairs(Library._windows) do
        if w == self then
            table.remove(Library._windows, i)
            break
        end
    end
end

--@ Public API
function Library:CreateWindow(config)
    return Window.new(config or {})
end

if getgenv then
    getgenv().Aether = Library
end

return Library
