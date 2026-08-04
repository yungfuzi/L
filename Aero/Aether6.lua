--[[
    Aether — Roblox Luau UI Library v1.1
    Single shared ScrollingFrame per Tab · Left/Right columns
]]

local Services = {
    CoreGui = game:GetService("CoreGui"),
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    TextService = game:GetService("TextService"),
    HttpService = game:GetService("HttpService"),
    GuiService = game:GetService("GuiService"),
}

local LocalPlayer = Services.Players.LocalPlayer or Services.Players.PlayerAdded:Wait()
local Mouse = LocalPlayer:GetMouse()

local getgenv = getgenv or function() return shared end
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function() return Services.CoreGui end
local setclipboard = setclipboard or function() end

--// Library Core
local Library = {
    Version = "1.1.0",
    LocalPlayer = LocalPlayer,

    ScreenGui = nil,
    Window = nil,
    ActiveTab = nil,

    Flags = {},
    Options = {},
    Toggles = {},

    Tabs = {},
    Notifications = {},
    Signals = {},
    UnloadSignals = {},
    Registry = {},

    Searching = false,
    SearchText = "",
    GlobalSearch = false,

    Toggled = false,
    Unloaded = false,
    IsMobile = false,
    IsRobloxFocused = true,
    CantDragForced = false,

    DPIScale = 1,
    MinSize = Vector2.new(480, 360),
    OriginalMinSize = Vector2.new(480, 360),
    CornerRadius = 8,

    ToggleKeybind = Enum.KeyCode.RightControl,
    NotifySide = "Right",
    ShowCustomCursor = false,
    HideScrollbars = true,

    -- Fully customizable animation config
    Animations = {
        Enabled = true,
        Window = true,
        Tabs = true,
        Groupboxes = true,
        Dropdowns = true,
        Notifications = true,
        Toggles = true,
        Sliders = true,
        DragSmoothing = true,
    },

    AnimationConfig = {
        Default = { Time = 0.2, Style = Enum.EasingStyle.Quint, Direction = Enum.EasingDirection.Out },
        Window  = { Time = 0.32, Style = Enum.EasingStyle.Quint, Direction = Enum.EasingDirection.Out },
        Tab     = { Time = 0.22, Style = Enum.EasingStyle.Quint, Direction = Enum.EasingDirection.Out },
        Collapse= { Time = 0.25, Style = Enum.EasingStyle.Quint, Direction = Enum.EasingDirection.Out },
        Notify  = { Time = 0.35, Style = Enum.EasingStyle.Quint, Direction = Enum.EasingDirection.Out },
        Toggle  = { Time = 0.22, Style = Enum.EasingStyle.Back, Direction = Enum.EasingDirection.Out }, -- squishy
        Slider  = { Time = 0.28, Style = Enum.EasingStyle.Quint, Direction = Enum.EasingDirection.Out },
        Drag    = { Time = 0.28, Style = Enum.EasingStyle.Quint, Direction = Enum.EasingDirection.Out },
        Hover   = { Time = 0.15, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
    },

    Icons = {
        Close           = "rbxassetid://116396312853810",
        ChevronUpDown   = "rbxassetid://71880540200693",
        ChevronRight    = "rbxassetid://101007429951147",
        Search          = "rbxassetid://72296609649861",
        Keyboard        = "rbxassetid://121978468376124",
        Loader          = "rbxassetid://132295854994374",
        Input           = "rbxassetid://84912489891242",
    },

    Theme = {
        Background   = Color3.fromRGB(16, 16, 20),
        Surface      = Color3.fromRGB(22, 22, 28),
        Element      = Color3.fromRGB(30, 30, 38),
        ElementHover = Color3.fromRGB(38, 38, 48),
        Accent       = Color3.fromRGB(110, 90, 255),
        AccentDark   = Color3.fromRGB(80, 60, 200),
        Text         = Color3.fromRGB(240, 240, 248),
        SubText      = Color3.fromRGB(140, 140, 160),
        Border       = Color3.fromRGB(48, 48, 60),
        Success      = Color3.fromRGB(70, 200, 120),
        Warning      = Color3.fromRGB(240, 180, 50),
        Danger       = Color3.fromRGB(230, 70, 70),
        White        = Color3.new(1, 1, 1),
        Black        = Color3.new(0, 0, 0),
    },
}

--// Utilities
local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local n = {}
    for k, v in pairs(t) do n[k] = DeepCopy(v) end
    return n
end

local function Merge(defaults, overrides)
    local result = DeepCopy(defaults)
    if type(overrides) ~= "table" then return result end
    for k, v in pairs(overrides) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = Merge(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

local function Validate(user, template)
    return Merge(template, user)
end

local function Trim(s)
    return (tostring(s or ""):match("^%s*(.-)%s*$"))
end

local function Round(value, places)
    places = places or 0
    if places <= 0 then return math.floor(value + 0.5) end
    local mult = 10 ^ places
    return math.floor(value * mult + 0.5) / mult
end

local function GetTextSize(text, font, size, width)
    local params = Instance.new("GetTextBoundsParams")
    params.Text = text
    params.Font = font
    params.Size = size
    params.Width = width or 9999
    params.RichText = true
    local ok, bounds = pcall(function()
        return Services.TextService:GetTextBoundsAsync(params)
    end)
    if ok and bounds then return bounds.X, bounds.Y end
    return #text * (size * 0.55), size + 4
end

local function IsClick(input, allowRight)
    local t = input.UserInputType
    return (t == Enum.UserInputType.MouseButton1
        or (allowRight and t == Enum.UserInputType.MouseButton2)
        or t == Enum.UserInputType.Touch)
        and input.UserInputState == Enum.UserInputState.Begin
        and Library.IsRobloxFocused
end

local function IsHover(input)
    local t = input.UserInputType
    return (t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch)
        and input.UserInputState == Enum.UserInputState.Change
end

local function SafeCallback(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then warn("[Aether] Callback error:", err) end
end

local function StopTween(tween)
    if tween and tween.PlaybackState == Enum.PlaybackState.Playing then
        pcall(function() tween:Cancel() end)
    end
end

local function MakeTweenInfo(key)
    local cfg = Library.AnimationConfig[key] or Library.AnimationConfig.Default
    return TweenInfo.new(cfg.Time, cfg.Style, cfg.Direction)
end

local function Tween(inst, props, key)
    if not Library.Animations.Enabled then
        for k, v in pairs(props) do
            pcall(function() inst[k] = v end)
        end
        return nil
    end
    local info = MakeTweenInfo(key or "Default")
    local t = Services.TweenService:Create(inst, info, props)
    t:Play()
    return t
end

--// Signal / Maid
function Library:GiveSignal(conn)
    if conn then table.insert(self.Signals, conn) end
    return conn
end

local function CreateMaid()
    local maid = { _tasks = {} }
    function maid:Give(task)
        table.insert(self._tasks, task)
        return task
    end
    function maid:Connect(signal, fn)
        local c = signal:Connect(fn)
        table.insert(self._tasks, c)
        return c
    end
    function maid:Clean()
        for i = #self._tasks, 1, -1 do
            local t = table.remove(self._tasks, i)
            if typeof(t) == "RBXScriptConnection" then
                if t.Connected then t:Disconnect() end
            elseif type(t) == "function" then
                pcall(t)
            elseif typeof(t) == "Instance" then
                pcall(function() t:Destroy() end)
            elseif type(t) == "table" and t.Destroy then
                pcall(function() t:Destroy() end)
            end
        end
    end
    return maid
end

--// Theme Registry
function Library:AddToRegistry(inst, props)
    self.Registry[inst] = props
end

function Library:RemoveFromRegistry(inst)
    self.Registry[inst] = nil
end

function Library:GetThemeValue(key)
    if type(key) == "function" then return key() end
    return self.Theme[key]
end

function Library:UpdateTheme()
    for inst, props in pairs(self.Registry) do
        if inst and inst.Parent then
            for prop, key in pairs(props) do
                local val = self:GetThemeValue(key)
                if val ~= nil then
                    pcall(function() inst[prop] = val end)
                end
            end
        end
    end
end

function Library:SetTheme(newTheme)
    if type(newTheme) ~= "table" then return end
    for k, v in pairs(newTheme) do
        if self.Theme[k] ~= nil then self.Theme[k] = v end
    end
    self:UpdateTheme()
end

function Library:SetAnimationConfig(key, cfg)
    if type(cfg) ~= "table" then return end
    Library.AnimationConfig[key] = Merge(Library.AnimationConfig[key] or Library.AnimationConfig.Default, cfg)
end

--// Instance helpers
local Templates = {
    Frame = { BorderSizePixel = 0, BackgroundColor3 = "Surface" },
    TextLabel = {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium, TextColor3 = "Text", TextSize = 13, RichText = true,
    },
    TextButton = {
        AutoButtonColor = false, BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium, TextColor3 = "Text", TextSize = 13, RichText = true,
    },
    TextBox = {
        BorderSizePixel = 0, Font = Enum.Font.Gotham,
        TextColor3 = "Text", PlaceholderColor3 = "SubText", TextSize = 13, ClearTextOnFocus = false,
    },
    ImageLabel = { BackgroundTransparency = 1, BorderSizePixel = 0 },
    ImageButton = { AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0 },
    ScrollingFrame = {
        BorderSizePixel = 0, ScrollBarThickness = 0, ScrollBarImageTransparency = 1,
        BackgroundTransparency = 1, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    },
    UIListLayout = { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) },
    UIPadding = {},
    UICorner = { CornerRadius = UDim.new(0, 8) },
    UIStroke = { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Color = "Border" },
}

local function New(className, props)
    local inst = Instance.new(className)
    local base = Templates[className]
    if base then
        for k, v in pairs(base) do
            local themeVal = Library:GetThemeValue(v)
            if themeVal ~= nil and type(v) == "string" and Library.Theme[v] then
                inst[k] = themeVal
                Library:AddToRegistry(inst, { [k] = v })
            else
                inst[k] = v
            end
        end
    end
    if props then
        local reg = Library.Registry[inst] or {}
        for k, v in pairs(props) do
            if k == "Parent" then
                inst.Parent = v
            else
                local themeVal = Library:GetThemeValue(v)
                if themeVal ~= nil and type(v) == "string" and Library.Theme[v] then
                    inst[k] = themeVal
                    reg[k] = v
                else
                    inst[k] = v
                end
            end
        end
        if next(reg) then Library.Registry[inst] = reg end
    end
    return inst
end

local function AddCorner(parent, radius)
    return New("UICorner", {
        CornerRadius = UDim.new(0, radius or Library.CornerRadius),
        Parent = parent,
    })
end

local function AddStroke(parent, colorKey, thickness)
    return New("UIStroke", {
        Color = colorKey or "Border",
        Thickness = thickness or 1,
        Parent = parent,
    })
end

local function AddPadding(parent, top, right, bottom, left)
    return New("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        Parent = parent,
    })
end

local function IconImage(parent, iconKey, size, colorKey)
    local id = Library.Icons[iconKey] or iconKey
    local img = New("ImageLabel", {
        Image = id,
        ImageColor3 = colorKey or "Text",
        Size = size or UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    return img
end

--// Parenting / Mobile
local function ParentUI(ui)
    pcall(protectgui, ui)
    local ok = pcall(function() ui.Parent = gethui() end)
    if not ok or not ui.Parent then
        ui.Parent = LocalPlayer:WaitForChild("PlayerGui", 10) or Services.CoreGui
    end
end

do
    local ok, platform = pcall(function() return Services.UserInputService:GetPlatform() end)
    if ok then
        Library.IsMobile = (platform == Enum.Platform.Android or platform == Enum.Platform.IOS)
    else
        Library.IsMobile = Services.UserInputService.TouchEnabled and not Services.UserInputService.MouseEnabled
    end
    if Library.IsMobile then
        Library.OriginalMinSize = Vector2.new(360, 280)
        Library.MinSize = Library.OriginalMinSize
    end
end

--// ScreenGui
local ScreenGui = New("ScreenGui", {
    Name = "Aether",
    DisplayOrder = 2000,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui

ScreenGui.DescendantRemoving:Connect(function(desc)
    Library:RemoveFromRegistry(desc)
end)

--// Notifications
local NotifyArea = New("Frame", {
    Name = "Notifications",
    AnchorPoint = Vector2.new(1, 0),
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -12, 0, 12),
    Size = UDim2.new(0, 300, 1, -24),
    ClipsDescendants = false,
    ZIndex = 10000,
    Parent = ScreenGui,
})
New("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Parent = NotifyArea,
})

function Library:Notify(text, duration, notifType)
    duration = duration or 3
    notifType = notifType or "info"

    local accentColor = Library.Theme.Accent
    if notifType == "success" then accentColor = Library.Theme.Success
    elseif notifType == "warning" then accentColor = Library.Theme.Warning
    elseif notifType == "error" then accentColor = Library.Theme.Danger end

    --// holder keeps list layout slot; card slides inside it
    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = false,
        ZIndex = 10000,
        Parent = NotifyArea,
    })

    local card = New("Frame", {
        BackgroundColor3 = "Surface",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        ZIndex = 10001,
        Parent = holder,
    })
    AddCorner(card, 8)
    AddStroke(card)
    AddPadding(card, 12, 14, 12, 14)

    local bar = New("Frame", {
        BackgroundColor3 = accentColor,
        Size = UDim2.new(0, 3, 1, 8),
        Position = UDim2.fromOffset(-10, -4),
        ZIndex = 10002,
        Parent = card,
    })
    AddCorner(bar, 2)

    local label = New("TextLabel", {
        Text = tostring(text),
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10002,
        Parent = card,
    })

    local slideOffset = 360
    if Library.Animations.Notifications and Library.Animations.Enabled then
        card.Position = UDim2.fromOffset(slideOffset, 0)
        Tween(card, { Position = UDim2.fromOffset(0, 0) }, "Notify")
    end

    task.delay(duration, function()
        if not holder.Parent then return end
        if Library.Animations.Notifications and Library.Animations.Enabled then
            local t = Tween(card, { Position = UDim2.fromOffset(slideOffset, 0) }, "Notify")
            if t then t.Completed:Wait() end
        end
        holder:Destroy()
    end)

    return card
end

--// Dragging / Resizing
function Library:MakeDraggable(ui, handle, ignoreToggle)
    local dragging, startPos, startFrame, targetPos
    local renderConn

    local began = handle.InputBegan:Connect(function(input)
        if not IsClick(input) then return end
        if not ignoreToggle and not Library.Toggled then return end
        if Library.CantDragForced then return end
        dragging = true
        startPos = input.Position
        startFrame = ui.Position
        targetPos = startFrame

        local c
        c = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if c then c:Disconnect() end
            end
        end)
    end)

    local changed = Services.UserInputService.InputChanged:Connect(function(input)
        if not dragging or not IsHover(input) then return end
        local delta = input.Position - startPos
        targetPos = UDim2.new(
            startFrame.X.Scale, startFrame.X.Offset + delta.X,
            startFrame.Y.Scale, startFrame.Y.Offset + delta.Y
        )
        if Library.Animations.DragSmoothing and Library.Animations.Enabled then
            Tween(ui, { Position = targetPos }, "Drag")
        else
            ui.Position = targetPos
        end
    end)

    Library:GiveSignal(began)
    Library:GiveSignal(changed)
end

function Library:MakeResizable(ui, handle, onResize)
    local dragging, startPos, startSize
    local began = handle.InputBegan:Connect(function(input)
        if not IsClick(input) then return end
        dragging = true
        startPos = input.Position
        startSize = ui.Size
        local c
        c = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if c then c:Disconnect() end
            end
        end)
    end)

    local changed = Services.UserInputService.InputChanged:Connect(function(input)
        if not dragging or not IsHover(input) then return end
        local delta = input.Position - startPos
        local newX = math.max(Library.MinSize.X, startSize.X.Offset + delta.X)
        local newY = math.max(Library.MinSize.Y, startSize.Y.Offset + delta.Y)
        ui.Size = UDim2.fromOffset(newX, newY)
        if onResize then SafeCallback(onResize) end
    end)

    Library:GiveSignal(began)
    Library:GiveSignal(changed)
end

--// Option registry
local function RegisterOption(flag, option)
    if flag and flag ~= "" then
        Library.Options[flag] = option
        if option.Type == "Toggle" or option.Type == "Checkbox" then
            Library.Toggles[flag] = option
        end
        Library.Flags[flag] = option.Value
    end
end

local function UnregisterOption(flag)
    if flag and flag ~= "" then
        Library.Options[flag] = nil
        Library.Toggles[flag] = nil
        Library.Flags[flag] = nil
    end
end

local function CreateElementShell(parent, height)
    return New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height or 28),
        Parent = parent,
    })
end

local function ApplyElementVisibility(holder, visible)
    holder.Visible = visible ~= false
end

--// Groupbox
local GroupboxMeta = {}
GroupboxMeta.__index = GroupboxMeta

function GroupboxMeta:Resize()
    if self._destroyed then return end
    local content, layout, holder = self.Content, self.Layout, self.Holder
    if not content or not layout or not holder then return end

    local headerH = self.HeaderHeight or 34
    local pad = 12
    local target = 0
    if not self.Collapsed then
        target = math.max(layout.AbsoluteContentSize.Y + pad, 0)
    end

    if self._heightTween then StopTween(self._heightTween) end
    if self._holderTween then StopTween(self._holderTween) end

    local contentSize = UDim2.new(1, 0, 0, target)
    local holderSize = UDim2.new(1, 0, 0, headerH + target)

    if Library.Animations.Groupboxes and Library.Animations.Enabled then
        self._heightTween = Tween(content, { Size = contentSize }, "Collapse")
        self._holderTween = Tween(holder, { Size = holderSize }, "Collapse")
    else
        content.Size = contentSize
        holder.Size = holderSize
    end

    if self.Column and self.Column.UpdateHeight then
        self.Column:UpdateHeight()
    end
end

function GroupboxMeta:SetCollapsed(state)
    self.Collapsed = state and true or false
    --// right-chevron: 0 = collapsed (point right), 90 = open (point down)
    if self.Chevron then
        local rot = self.Collapsed and 0 or 90
        Tween(self.Chevron, { Rotation = rot }, "Default")
    end
    self:Resize()
end

function GroupboxMeta:ToggleCollapse()
    self:SetCollapsed(not self.Collapsed)
end

function GroupboxMeta:SetVisible(v)
    self.Visible = v ~= false
    if self.Holder then self.Holder.Visible = self.Visible end
    if self.Column and self.Column.UpdateHeight then self.Column:UpdateHeight() end
end

function GroupboxMeta:SetTitle(text)
    if self.TitleLabel then self.TitleLabel.Text = text end
end

function GroupboxMeta:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    if self.Maid then self.Maid:Clean() end
    for _, el in ipairs(self.Elements) do
        if el.Destroy then pcall(function() el:Destroy() end) end
    end
    table.clear(self.Elements)
    if self.Holder then self.Holder:Destroy() end
    if self.Column and self.Column.Groupboxes then
        local idx = table.find(self.Column.Groupboxes, self)
        if idx then table.remove(self.Column.Groupboxes, idx) end
        self.Column:UpdateHeight()
    end
end

--// Label / Divider / Paragraph
function GroupboxMeta:AddLabel(flagOrText, info)
    local text, flag
    if type(flagOrText) == "table" then
        info = flagOrText; text = info.Text or "Label"; flag = info.Flag
    elseif type(info) == "table" then
        flag = flagOrText; text = info.Text or tostring(flagOrText)
    else
        text = tostring(flagOrText)
    end
    info = info or {}

    local holder = CreateElementShell(self.Content, 20)
    local label = New("TextLabel", {
        Text = text, Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = info.Color and nil or "SubText",
        TextSize = info.TextSize or 12, Parent = holder,
    })
    if info.Color then label.TextColor3 = info.Color end

    local el = { Type = "Label", Holder = holder, Label = label, Visible = true, Text = text, ParentBox = self }
    function el:SetText(t) self.Text = t; label.Text = t end
    function el:SetVisible(v) self.Visible = v ~= false; ApplyElementVisibility(holder, self.Visible); self.ParentBox:Resize() end
    function el:Destroy()
        holder:Destroy()
        local i = table.find(self.ParentBox.Elements, self)
        if i then table.remove(self.ParentBox.Elements, i) end
        self.ParentBox:Resize()
    end
    table.insert(self.Elements, el)
    self:Resize()
    return el
end

function GroupboxMeta:AddDivider()
    local holder = CreateElementShell(self.Content, 10)
    New("Frame", {
        BackgroundColor3 = "Border", Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.fromScale(0, 0.5), AnchorPoint = Vector2.new(0, 0.5), Parent = holder,
    })
    local el = { Type = "Divider", Holder = holder, Visible = true, ParentBox = self }
    function el:SetVisible(v) self.Visible = v ~= false; ApplyElementVisibility(holder, self.Visible); self.ParentBox:Resize() end
    function el:Destroy()
        holder:Destroy()
        local i = table.find(self.ParentBox.Elements, self)
        if i then table.remove(self.ParentBox.Elements, i) end
        self.ParentBox:Resize()
    end
    table.insert(self.Elements, el)
    self:Resize()
    return el
end

function GroupboxMeta:AddParagraph(flagOrText, info)
    local text
    if type(flagOrText) == "table" then info = flagOrText; text = info.Text or ""
    else text = tostring(flagOrText); info = info or {} end

    local holder = New("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Parent = self.Content,
    })
    New("TextLabel", {
        Text = text, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = "SubText", TextSize = 12, Parent = holder,
    })
    local el = { Type = "Paragraph", Holder = holder, Text = text, Visible = true, ParentBox = self }
    function el:SetText(t) self.Text = t; holder:FindFirstChildWhichIsA("TextLabel").Text = t; self.ParentBox:Resize() end
    function el:SetVisible(v) self.Visible = v ~= false; ApplyElementVisibility(holder, self.Visible); self.ParentBox:Resize() end
    function el:Destroy()
        holder:Destroy()
        local i = table.find(self.ParentBox.Elements, self)
        if i then table.remove(self.ParentBox.Elements, i) end
        self.ParentBox:Resize()
    end
    table.insert(self.Elements, el)
    self:Resize()
    return el
end

--// Button
function GroupboxMeta:AddButton(flagOrInfo, info)
    if type(flagOrInfo) == "table" then info = flagOrInfo
    else info = info or {}; info.Text = info.Text or tostring(flagOrInfo) end
    info = Validate(info, {
        Text = "Button", Callback = function() end, Disabled = false, Visible = true, Risky = false,
    })

    local holder = CreateElementShell(self.Content, 30)
    local btn = New("TextButton", {
        BackgroundColor3 = "Element", Size = UDim2.fromScale(1, 1),
        Text = info.Text, Parent = holder,
    })
    AddCorner(btn, 6)
    AddStroke(btn)

    local maid = CreateMaid()
    local activeColor = Library.Theme.Element
    local hoverColor = Library.Theme.ElementHover
    if info.Risky then
        activeColor = Library.Theme.Danger
        hoverColor = Color3.fromRGB(
            math.min(255, Library.Theme.Danger.R * 255 + 20),
            math.min(255, Library.Theme.Danger.G * 255 + 20),
            math.min(255, Library.Theme.Danger.B * 255 + 20)
        )
        btn.BackgroundColor3 = activeColor
        btn.TextColor3 = Color3.new(1, 1, 1)
    end

    maid:Connect(btn.MouseEnter, function()
        if not info.Disabled then Tween(btn, { BackgroundColor3 = hoverColor }, "Hover") end
    end)
    maid:Connect(btn.MouseLeave, function()
        Tween(btn, { BackgroundColor3 = activeColor }, "Hover")
    end)
    maid:Connect(btn.MouseButton1Click, function()
        if info.Disabled then return end
        -- squish pulse
        if Library.Animations.Enabled then
            local s = New("UIScale", { Scale = 1, Parent = btn })
            Tween(s, { Scale = 0.96 }, "Toggle")
            task.delay(0.08, function()
                Tween(s, { Scale = 1 }, "Toggle")
                task.delay(0.15, function() if s then s:Destroy() end end)
            end)
        end
        SafeCallback(info.Callback)
    end)

    local el = {
        Type = "Button", Holder = holder, Button = btn, Visible = info.Visible,
        Disabled = info.Disabled, ParentBox = self, Maid = maid,
    }
    function el:SetText(t) btn.Text = t end
    function el:SetDisabled(d)
        self.Disabled = d; info.Disabled = d
        btn.TextTransparency = d and 0.5 or 0
    end
    function el:SetVisible(v)
        self.Visible = v ~= false; ApplyElementVisibility(holder, self.Visible); self.ParentBox:Resize()
    end
    function el:Destroy()
        maid:Clean(); holder:Destroy()
        local i = table.find(self.ParentBox.Elements, self)
        if i then table.remove(self.ParentBox.Elements, i) end
        self.ParentBox:Resize()
    end

    table.insert(self.Elements, el)
    self:Resize()
    return el
end

--// Toggle
function GroupboxMeta:AddToggle(flag, info)
    info = Validate(info or {}, {
        Text = tostring(flag or "Toggle"),
        Default = false,
        Variant = "Switch", -- Switch | Checkbox | Button
        Callback = function() end,
        Changed = function() end,
        Disabled = false,
        Visible = true,
        Risky = false,
    })

    local variant = string.lower(info.Variant or "Switch")
    local value = info.Default and true or false
    local maid = CreateMaid()
    local holder, applyVisual

    if variant == "checkbox" then
        holder = CreateElementShell(self.Content, 26)
        local box = New("Frame", {
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = "Element", Parent = holder,
        })
        AddCorner(box, 4)
        AddStroke(box)
        local check = IconImage(box, "Close", UDim2.fromOffset(12, 12), "White") -- will swap visual
        -- use a simple check via text for reliability
        check:Destroy()
        local checkMark = New("TextLabel", {
            Text = "✓", Size = UDim2.fromScale(1, 1), TextSize = 13,
            TextColor3 = "White", BackgroundTransparency = 1,
            Visible = false, Parent = box,
        })
        local label = New("TextLabel", {
            Text = info.Text, Size = UDim2.new(1, -28, 1, 0),
            Position = UDim2.fromOffset(26, 0),
            TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
        })

        applyVisual = function(v, animate)
            checkMark.Visible = v
            local bg = v and Library.Theme.Accent or Library.Theme.Element
            if animate and Library.Animations.Toggles then
                Tween(box, { BackgroundColor3 = bg }, "Toggle")
            else
                box.BackgroundColor3 = bg
            end
        end

        maid:Connect(holder.InputBegan, function(input)
            if info.Disabled then return end
            if IsClick(input) then
                value = not value
                applyVisual(value, true)
                if flag then Library.Flags[flag] = value end
                SafeCallback(info.Callback, value)
                SafeCallback(info.Changed, value)
            end
        end)

    elseif variant == "button" then
        holder = CreateElementShell(self.Content, 30)
        local btn = New("TextButton", {
            BackgroundColor3 = "Element", Size = UDim2.fromScale(1, 1),
            Text = info.Text, Parent = holder,
        })
        AddCorner(btn, 6)
        AddStroke(btn)

        applyVisual = function(v, animate)
            local bg = v and Library.Theme.Accent or Library.Theme.Element
            local tc = v and Library.Theme.White or Library.Theme.Text
            if animate and Library.Animations.Toggles then
                Tween(btn, { BackgroundColor3 = bg }, "Toggle")
                Tween(btn, { TextColor3 = tc }, "Toggle")
            else
                btn.BackgroundColor3 = bg
                btn.TextColor3 = tc
            end
        end

        maid:Connect(btn.MouseButton1Click, function()
            if info.Disabled then return end
            value = not value
            applyVisual(value, true)
            if flag then Library.Flags[flag] = value end
            SafeCallback(info.Callback, value)
            SafeCallback(info.Changed, value)
        end)

    else -- Switch (default)
        holder = CreateElementShell(self.Content, 28)
        local label = New("TextLabel", {
            Text = info.Text, Size = UDim2.new(1, -44, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
        })
        local track = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(40, 22),
            BackgroundColor3 = "Element", Parent = holder,
        })
        AddCorner(track, 11)
        AddStroke(track)
        local knob = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.fromOffset(18, 18),
            BackgroundColor3 = "Text", Parent = track,
        })
        AddCorner(knob, 9)

        applyVisual = function(v, animate)
            local targetPos = v and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
            local targetBg = v and Library.Theme.Accent or Library.Theme.Element
            if animate and Library.Animations.Toggles and Library.Animations.Enabled then
                -- squishy knob
                local scale = New("UIScale", { Scale = 1, Parent = knob })
                Tween(knob, { Position = targetPos }, "Toggle")
                Tween(track, { BackgroundColor3 = targetBg }, "Toggle")
                Tween(scale, { Scale = 0.85 }, "Toggle")
                task.delay(0.1, function()
                    Tween(scale, { Scale = 1 }, "Toggle")
                    task.delay(0.2, function() if scale then scale:Destroy() end end)
                end)
            else
                knob.Position = targetPos
                track.BackgroundColor3 = targetBg
            end
        end

        maid:Connect(holder.InputBegan, function(input)
            if info.Disabled then return end
            if IsClick(input) then
                value = not value
                applyVisual(value, true)
                if flag then Library.Flags[flag] = value end
                SafeCallback(info.Callback, value)
                SafeCallback(info.Changed, value)
            end
        end)
    end

    applyVisual(value, false)

    local el = {
        Type = "Toggle", Flag = flag, Holder = holder, Value = value,
        Visible = info.Visible, Disabled = info.Disabled,
        ParentBox = self, Maid = maid, Text = info.Text, Variant = variant,
    }
    function el:SetValue(v, fire)
        value = v and true or false
        self.Value = value
        applyVisual(value, true)
        if flag then Library.Flags[flag] = value end
        if fire ~= false then
            SafeCallback(info.Callback, value)
            SafeCallback(info.Changed, value)
        end
    end
    function el:GetValue() return value end
    function el:SetText(t) self.Text = t; local l = holder:FindFirstChildWhichIsA("TextLabel"); if l then l.Text = t end end
    function el:SetDisabled(d) self.Disabled = d; info.Disabled = d end
    function el:SetVisible(v)
        self.Visible = v ~= false; ApplyElementVisibility(holder, self.Visible); self.ParentBox:Resize()
    end
    function el:Destroy()
        maid:Clean(); UnregisterOption(flag); holder:Destroy()
        local i = table.find(self.ParentBox.Elements, self)
        if i then table.remove(self.ParentBox.Elements, i) end
        self.ParentBox:Resize()
    end

    RegisterOption(flag, el)
    table.insert(self.Elements, el)
    self:Resize()
    return el
end

GroupboxMeta.AddCheckbox = function(self, flag, info)
    info = info or {}
    info.Variant = "Checkbox"
    return self:AddToggle(flag, info)
end

--// Slider
function GroupboxMeta:AddSlider(flag, info)
    info = Validate(info or {}, {
        Text = tostring(flag or "Slider"), Default = 0, Min = 0, Max = 100, Rounding = 0,
        Prefix = "", Suffix = "", Callback = function() end, Changed = function() end,
        Disabled = false, Visible = true,
    })

    local holder = New("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48), Parent = self.Content,
    })
    local title = New("TextLabel", {
        Text = info.Text, Size = UDim2.new(1, -56, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left, TextSize = 12, Parent = holder,
    })
    local valueLabel = New("TextLabel", {
        Text = info.Prefix .. tostring(info.Default) .. info.Suffix,
        Size = UDim2.new(0, 54, 0, 16), Position = UDim2.new(1, -54, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right, TextSize = 12, TextColor3 = "SubText", Parent = holder,
    })

    local track = New("Frame", {
        BackgroundColor3 = "Element", Position = UDim2.fromOffset(0, 28),
        Size = UDim2.new(1, 0, 0, 6), Parent = holder,
    })
    AddCorner(track, 3)

    local fill = New("Frame", {
        BackgroundColor3 = "Accent", Size = UDim2.new(0, 0, 1, 0), Parent = track,
    })
    AddCorner(fill, 3)

    --// pill knob (same style as colorpicker hue knob)
    local knob = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(6, 16),
        ZIndex = 2,
        Parent = track,
    })
    AddCorner(knob, 3)
    local knobStroke = Instance.new("UIStroke")
    knobStroke.Color = Color3.fromRGB(30, 30, 30)
    knobStroke.Thickness = 1
    knobStroke.Parent = knob

    local value = math.clamp(info.Default, info.Min, info.Max)
    local function updateVisual(animate)
        local pct = (value - info.Min) / math.max(info.Max - info.Min, 1e-6)
        local props = { Size = UDim2.new(pct, 0, 1, 0) }
        local kprops = { Position = UDim2.new(pct, 0, 0.5, 0) }
        if animate and Library.Animations.Sliders and Library.Animations.Enabled then
            Tween(fill, props, "Slider")
            Tween(knob, kprops, "Slider")
        else
            fill.Size = props.Size
            knob.Position = kprops.Position
        end
        valueLabel.Text = info.Prefix .. tostring(Round(value, info.Rounding)) .. info.Suffix
    end
    updateVisual(false)

    local dragging = false
    local maid = CreateMaid()

    local function setFromX(x, fire)
        local abs = track.AbsolutePosition.X
        local size = math.max(track.AbsoluteSize.X, 1)
        local pct = math.clamp((x - abs) / size, 0, 1)
        value = Round(info.Min + pct * (info.Max - info.Min), info.Rounding)
        updateVisual(true)
        if flag then Library.Flags[flag] = value end
        if fire ~= false then
            SafeCallback(info.Callback, value)
            SafeCallback(info.Changed, value)
        end
    end

    maid:Connect(track.InputBegan, function(input)
        if info.Disabled then return end
        if IsClick(input) then dragging = true; setFromX(input.Position.X) end
    end)
    maid:Connect(knob.InputBegan, function(input)
        if info.Disabled then return end
        if IsClick(input) then dragging = true end
    end)
    maid:Connect(Services.UserInputService.InputChanged, function(input)
        if not dragging or not IsHover(input) then return end
        setFromX(input.Position.X)
    end)
    maid:Connect(Services.UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local el = {
        Type = "Slider", Flag = flag, Holder = holder, Value = value,
        Visible = info.Visible, Disabled = info.Disabled, ParentBox = self, Maid = maid, Text = info.Text,
    }
    function el:SetValue(v, fire)
        value = math.clamp(Round(v, info.Rounding), info.Min, info.Max)
        self.Value = value; updateVisual(true)
        if flag then Library.Flags[flag] = value end
        if fire ~= false then SafeCallback(info.Callback, value); SafeCallback(info.Changed, value) end
    end
    function el:GetValue() return value end
    function el:SetText(t) self.Text = t; title.Text = t end
    function el:SetDisabled(d) self.Disabled = d; info.Disabled = d end
    function el:SetVisible(v) self.Visible = v ~= false; ApplyElementVisibility(holder, self.Visible); self.ParentBox:Resize() end
    function el:Destroy()
        maid:Clean(); UnregisterOption(flag); holder:Destroy()
        local i = table.find(self.ParentBox.Elements, self)
        if i then table.remove(self.ParentBox.Elements, i) end
        self.ParentBox:Resize()
    end

    RegisterOption(flag, el)
    table.insert(self.Elements, el)
    self:Resize()
    return el
end

--// Input
function GroupboxMeta:AddInput(flag, info)
    info = Validate(info or {}, {
        Text = tostring(flag or "Input"), Default = "", Placeholder = "",
        Numeric = false, Finished = false, Callback = function() end, Changed = function() end,
        Disabled = false, Visible = true, ClearTextOnFocus = false,
    })

    local holder = New("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48), Parent = self.Content,
    })
    local title = New("TextLabel", {
        Text = info.Text, Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left, TextSize = 12, Parent = holder,
    })
    local box = New("TextBox", {
        BackgroundColor3 = "Element", Position = UDim2.fromOffset(0, 20),
        Size = UDim2.new(1, 0, 0, 26), Text = tostring(info.Default),
        PlaceholderText = info.Placeholder, ClearTextOnFocus = info.ClearTextOnFocus,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
    })
    AddCorner(box, 6)
    AddStroke(box)
    AddPadding(box, 0, 8, 0, 8)

    local value = tostring(info.Default)
    local maid = CreateMaid()

    local function commit(fire)
        local t = box.Text
        if info.Numeric then
            local n = tonumber(t)
            if n then t = tostring(n) else t = value end
            box.Text = t
        end
        value = t
        if flag then Library.Flags[flag] = value end
        if fire ~= false then SafeCallback(info.Callback, value); SafeCallback(info.Changed, value) end
    end

    maid:Connect(box.FocusLost, function(enter)
        if info.Finished and not enter then return end
        commit(true)
    end)
    if not info.Finished then
        maid:Connect(box:GetPropertyChangedSignal("Text"), function()
            value = box.Text
            if flag then Library.Flags[flag] = value end
            SafeCallback(info.Changed, value)
        end)
    end

    local el = {
        Type = "Input", Flag = flag, Holder = holder, Value = value,
        Visible = info.Visible, Disabled = info.Disabled, ParentBox = self, Maid = maid, Text = info.Text,
    }
    function el:SetValue(v, fire)
        value = tostring(v); box.Text = value; self.Value = value
        if flag then Library.Flags[flag] = value end
        if fire ~= false then SafeCallback(info.Callback, value); SafeCallback(info.Changed, value) end
    end
    function el:GetValue() return value end
    function el:SetText(t) self.Text = t; title.Text = t end
    function el:SetDisabled(d) self.Disabled = d; info.Disabled = d; box.TextEditable = not d end
    function el:SetVisible(v) self.Visible = v ~= false; ApplyElementVisibility(holder, self.Visible); self.ParentBox:Resize() end
    function el:Destroy()
        maid:Clean(); UnregisterOption(flag); holder:Destroy()
        local i = table.find(self.ParentBox.Elements, self)
        if i then table.remove(self.ParentBox.Elements, i) end
        self.ParentBox:Resize()
    end

    RegisterOption(flag, el)
    table.insert(self.Elements, el)
    self:Resize()
    return el
end

--// Dropdown
function GroupboxMeta:AddDropdown(flag, info)
    info = Validate(info or {}, {
        Text = tostring(flag or "Dropdown"), Values = {}, Default = nil, Multi = false,
        MaxVisibleDropdownItems = 6, Callback = function() end, Changed = function() end,
        Disabled = false, Visible = true,
    })

    local holder = New("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48), Parent = self.Content,
    })
    local title = New("TextLabel", {
        Text = info.Text, Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left, TextSize = 12, Parent = holder,
    })
    local trigger = New("TextButton", {
        BackgroundColor3 = "Element", Position = UDim2.fromOffset(0, 20),
        Size = UDim2.new(1, 0, 0, 26), Text = "", Parent = holder,
    })
    AddCorner(trigger, 6)
    AddStroke(trigger)

    local display = New("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -28, 1, 0),
        Position = UDim2.fromOffset(8, 0), TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = trigger,
    })
    local chevron = IconImage(trigger, "ChevronUpDown", UDim2.fromOffset(14, 14), "SubText")
    chevron.AnchorPoint = Vector2.new(1, 0.5)
    chevron.Position = UDim2.new(1, -8, 0.5, 0)

    local values = {}
    for _, v in ipairs(info.Values) do table.insert(values, v) end

    local selected
    if info.Multi then
        selected = {}
        if type(info.Default) == "table" then
            for _, v in ipairs(info.Default) do selected[v] = true end
        end
    else
        selected = info.Default
        if selected == nil and #values > 0 then selected = values[1] end
    end

    local function refreshDisplay()
        if info.Multi then
            local parts = {}
            for _, v in ipairs(values) do if selected[v] then table.insert(parts, tostring(v)) end end
            display.Text = #parts > 0 and table.concat(parts, ", ") or "None"
        else
            display.Text = selected ~= nil and tostring(selected) or "None"
        end
    end
    refreshDisplay()

    -- Menu parented to ScreenGui, repositioned under trigger each open
    local menuOpen = false
    local menu = New("Frame", {
        BackgroundColor3 = "Surface", Visible = false, ZIndex = 300, Parent = ScreenGui,
    })
    AddCorner(menu, 6)
    AddStroke(menu)
    local menuScroll = New("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0, Parent = menu,
    })
    AddPadding(menuScroll, 4, 4, 4, 4)
    New("UIListLayout", { Padding = UDim.new(0, 2), Parent = menuScroll })

    local function closeMenu()
        menuOpen = false
        menu.Visible = false
    end

    local function positionMenu()
        local abs = trigger.AbsolutePosition
        local size = trigger.AbsoluteSize
        local itemH = 26
        local visible = math.min(#values, info.MaxVisibleDropdownItems)
        local h = visible * (itemH + 2) + 8
        -- follow under the button
        menu.Position = UDim2.fromOffset(abs.X, abs.Y + size.Y + 4)
        menu.Size = UDim2.fromOffset(size.X, h)
    end

    local function openMenu()
        if info.Disabled then return end
        menuOpen = true
        positionMenu()
        menu.Visible = true
    end

    local function rebuildMenu()
        for _, c in ipairs(menuScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, v in ipairs(values) do
            local isOn = info.Multi and selected[v] or (selected == v)
            local item = New("TextButton", {
                BackgroundColor3 = isOn and "Accent" or "Element",
                Size = UDim2.new(1, 0, 0, 24), Text = "  " .. tostring(v),
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 301, Parent = menuScroll,
            })
            AddCorner(item, 4)
            item.MouseButton1Click:Connect(function()
                if info.Multi then
                    selected[v] = not selected[v]
                    if flag then
                        local list = {}
                        for _, vv in ipairs(values) do if selected[vv] then table.insert(list, vv) end end
                        Library.Flags[flag] = list
                    end
                    SafeCallback(info.Callback, selected)
                    SafeCallback(info.Changed, selected)
                    rebuildMenu(); refreshDisplay()
                else
                    selected = v
                    if flag then Library.Flags[flag] = selected end
                    SafeCallback(info.Callback, selected)
                    SafeCallback(info.Changed, selected)
                    refreshDisplay(); closeMenu()
                end
            end)
        end
    end
    rebuildMenu()

    local maid = CreateMaid()
    maid:Connect(trigger.MouseButton1Click, function()
        if menuOpen then closeMenu() else openMenu() end
    end)
    -- keep menu under button while open (scroll / resize)
    maid:Connect(Services.RunService.RenderStepped, function()
        if menuOpen then positionMenu() end
    end)
    maid:Connect(Services.UserInputService.InputBegan, function(input)
        if not menuOpen then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local pos = input.Position
            local mPos, mSize = menu.AbsolutePosition, menu.AbsoluteSize
            local tPos, tSize = trigger.AbsolutePosition, trigger.AbsoluteSize
            local overMenu = pos.X >= mPos.X and pos.X <= mPos.X + mSize.X and pos.Y >= mPos.Y and pos.Y <= mPos.Y + mSize.Y
            local overTrig = pos.X >= tPos.X and pos.X <= tPos.X + tSize.X and pos.Y >= tPos.Y and pos.Y <= tPos.Y + tSize.Y
            if not overMenu and not overTrig then closeMenu() end
        end
    end)

    local el = {
        Type = "Dropdown", Flag = flag, Holder = holder, Value = selected, Values = values,
        Multi = info.Multi, Visible = info.Visible, Disabled = info.Disabled,
        ParentBox = self, Maid = maid, Text = info.Text,
    }
    function el:SetValue(v, fire)
        if info.Multi then
            selected = {}; if type(v) == "table" then for _, x in ipairs(v) do selected[x] = true end end
        else selected = v end
        self.Value = selected; refreshDisplay(); rebuildMenu()
        if flag then
            if info.Multi then
                local list = {}; for _, vv in ipairs(values) do if selected[vv] then table.insert(list, vv) end end
                Library.Flags[flag] = list
            else Library.Flags[flag] = selected end
        end
        if fire ~= false then SafeCallback(info.Callback, selected); SafeCallback(info.Changed, selected) end
    end
    function el:GetValue() return selected end
    function el:SetValues(list)
        values = {}; for _, v in ipairs(list or {}) do table.insert(values, v) end
        self.Values = values; rebuildMenu(); refreshDisplay()
    end
    function el:SetText(t) self.Text = t; title.Text = t end
    function el:SetDisabled(d) self.Disabled = d; info.Disabled = d end
    function el:SetVisible(v) self.Visible = v ~= false; ApplyElementVisibility(holder, self.Visible); self.ParentBox:Resize() end
    function el:Destroy()
        closeMenu(); maid:Clean(); menu:Destroy(); UnregisterOption(flag); holder:Destroy()
        local i = table.find(self.ParentBox.Elements, self)
        if i then table.remove(self.ParentBox.Elements, i) end
        self.ParentBox:Resize()
    end

    if flag then
        if info.Multi then
            local list = {}; for _, vv in ipairs(values) do if selected[vv] then table.insert(list, vv) end end
            Library.Flags[flag] = list
        else Library.Flags[flag] = selected end
    end
    RegisterOption(flag, el)
    table.insert(self.Elements, el)
    self:Resize()
    return el
end

function GroupboxMeta:AddMultiDropdown(flag, info)
    info = info or {}; info.Multi = true
    return self:AddDropdown(flag, info)
end

--// KeyPicker
function GroupboxMeta:AddKeyPicker(flag, info)
    info = Validate(info or {}, {
        Text = tostring(flag or "Key"), Default = "None", Mode = "Toggle",
        Callback = function() end, Changed = function() end, Disabled = false, Visible = true,
    })

    local holder = CreateElementShell(self.Content, 28)
    local label = New("TextLabel", {
        Text = info.Text, Size = UDim2.new(1, -84, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
    })
    local keyBtn = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(76, 22), BackgroundColor3 = "Element",
        Text = "  " .. tostring(info.Default), TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
    })
    AddCorner(keyBtn, 5)
    AddStroke(keyBtn)
    local keyIcon = IconImage(keyBtn, "Keyboard", UDim2.fromOffset(12, 12), "SubText")
    keyIcon.AnchorPoint = Vector2.new(1, 0.5)
    keyIcon.Position = UDim2.new(1, -6, 0.5, 0)

    local key = info.Default
    local listening = false
    local maid = CreateMaid()

    maid:Connect(keyBtn.MouseButton1Click, function()
        if info.Disabled then return end
        listening = true
        keyBtn.Text = "  ..."
    end)
    maid:Connect(Services.UserInputService.InputBegan, function(input)
        if not listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            key = input.KeyCode.Name
        elseif input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2 then
            key = input.UserInputType.Name
        else return end
        keyBtn.Text = "  " .. key
        listening = false
        if flag then Library.Flags[flag] = key end
        SafeCallback(info.Changed, key)
    end)

    local el = {
        Type = "KeyPicker", Flag = flag, Holder = holder, Value = key,
        Visible = info.Visible, Disabled = info.Disabled, ParentBox = self, Maid = maid, Text = info.Text,
    }
    function el:SetValue(v) key = tostring(v); self.Value = key; keyBtn.Text = "  " .. key; if flag then Library.Flags[flag] = key end end
    function el:GetValue() return key end
    function el:SetText(t) self.Text = t; label.Text = t end
    function el:SetDisabled(d) self.Disabled = d; info.Disabled = d end
    function el:SetVisible(v) self.Visible = v ~= false; ApplyElementVisibility(holder, self.Visible); self.ParentBox:Resize() end
    function el:Destroy()
        maid:Clean(); UnregisterOption(flag); holder:Destroy()
        local i = table.find(self.ParentBox.Elements, self)
        if i then table.remove(self.ParentBox.Elements, i) end
        self.ParentBox:Resize()
    end

    RegisterOption(flag, el)
    if flag then Library.Flags[flag] = key end
    table.insert(self.Elements, el)
    self:Resize()
    return el
end

--// ColorPicker
function GroupboxMeta:AddColorPicker(flag, info)
    info = Validate(info or {}, {
        Text = tostring(flag or "Color"), Default = Color3.fromRGB(255, 255, 255),
        Callback = function() end, Changed = function() end, Disabled = false, Visible = true,
    })

    local h, s, v = info.Default:ToHSV()
    local value = info.Default

    local holder = CreateElementShell(self.Content, 28)
    local label = New("TextLabel", {
        Text = info.Text, Size = UDim2.new(1, -36, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
    })
    local swatch = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(28, 20), BackgroundColor3 = value, Text = "", Parent = holder,
    })
    AddCorner(swatch, 5)
    AddStroke(swatch)

    -- Color panel
    local panelOpen = false
    local panel = New("Frame", {
        BackgroundColor3 = "Surface", Size = UDim2.fromOffset(220, 290),
        Visible = false, ZIndex = 20000, Parent = ScreenGui,
    })
    AddCorner(panel, 10)
    AddStroke(panel)
    AddPadding(panel, 12, 12, 12, 12)

    --// SV square
    local svFrame = New("Frame", {
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        Size = UDim2.fromOffset(196, 140),
        ClipsDescendants = true,
        Active = true,
        Parent = panel,
    })
    AddCorner(svFrame, 8)

    local whiteGrad = New("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        Size = UDim2.fromScale(1, 1),
        Active = false,
        Parent = svFrame,
    })
    AddCorner(whiteGrad, 8)
    local wg = Instance.new("UIGradient")
    wg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    wg.Parent = whiteGrad

    local blackGrad = New("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        Size = UDim2.fromScale(1, 1),
        Active = false,
        Parent = svFrame,
    })
    AddCorner(blackGrad, 8)
    local bg = Instance.new("UIGradient")
    bg.Rotation = 90
    bg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    bg.Parent = blackGrad

    --// transparent hit layer on top of gradients
    local svHit = New("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        ZIndex = 5,
        Parent = svFrame,
    })

    --// SV cursor
    local cursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(s, 1 - v),
        ZIndex = 10,
        Active = false,
        Parent = svFrame,
    })
    local cursorOuter = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Active = false,
        Parent = cursor,
    })
    AddCorner(cursorOuter, 8)
    local outerStroke = Instance.new("UIStroke")
    outerStroke.Color = Color3.new(1, 1, 1)
    outerStroke.Thickness = 2
    outerStroke.Parent = cursorOuter
    local cursorInner = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Active = false,
        Parent = cursor,
    })
    AddCorner(cursorInner, 8)
    local innerStroke = Instance.new("UIStroke")
    innerStroke.Color = Color3.new(0, 0, 0)
    innerStroke.Thickness = 1
    innerStroke.Parent = cursorInner

    --// hue bar (single gradient, segments non-interactive)
    local hueBar = New("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        Position = UDim2.fromOffset(0, 150),
        Size = UDim2.new(1, 0, 0, 14),
        Active = true,
        Parent = panel,
    })
    AddCorner(hueBar, 5)
    local hueGrad = Instance.new("UIGradient")
    hueGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
    })
    hueGrad.Parent = hueBar

    local hueKnob = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(h, 0, 0.5, 0),
        Size = UDim2.fromOffset(6, 18),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = 10,
        Parent = hueBar,
    })
    AddCorner(hueKnob, 3)
    local hueKnobStroke = Instance.new("UIStroke")
    hueKnobStroke.Color = Color3.fromRGB(30, 30, 30)
    hueKnobStroke.Thickness = 1
    hueKnobStroke.Parent = hueKnob

    -- Hex / HSL / RGB rows
    local function makeColorRow(y, placeholder)
        local row = New("Frame", {
            BackgroundColor3 = "Element", Position = UDim2.fromOffset(0, y),
            Size = UDim2.new(1, 0, 0, 24), Parent = panel,
        })
        AddCorner(row, 5)
        AddStroke(row)
        local tb = New("TextBox", {
            BackgroundTransparency = 1, Size = UDim2.new(1, -28, 1, 0),
            Position = UDim2.fromOffset(8, 0), Text = placeholder,
            TextXAlignment = Enum.TextXAlignment.Left, TextSize = 11, Parent = row,
        })
        local copyBtn = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0),
            Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Text = "⧉",
            TextSize = 12, TextColor3 = "SubText", Parent = row,
        })
        return tb, copyBtn
    end

    local hexBox, hexCopy = makeColorRow(174, "ffffff")
    local hslBox, hslCopy = makeColorRow(204, "hsl(0, 0%, 100%)")
    local rgbBox, rgbCopy = makeColorRow(234, "rgb(255, 255, 255)")

    local function colorToHex(c)
        return string.format("%02x%02x%02x",
            math.floor(c.R * 255 + 0.5),
            math.floor(c.G * 255 + 0.5),
            math.floor(c.B * 255 + 0.5))
    end

    local function refreshFields()
        value = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = value
        svFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        cursor.Position = UDim2.fromScale(s, 1 - v)
        hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
        hexBox.Text = colorToHex(value)
        local hh = math.floor(h * 360 + 0.5)
        local ss = math.floor(s * 100 + 0.5)
        local vv = math.floor(v * 100 + 0.5)
        hslBox.Text = string.format("hsl(%ddeg %d%% %d%%)", hh, ss, vv)
        rgbBox.Text = string.format("rgb(%d, %d, %d)",
            math.floor(value.R * 255 + 0.5),
            math.floor(value.G * 255 + 0.5),
            math.floor(value.B * 255 + 0.5))
        if flag then Library.Flags[flag] = value end
    end
    refreshFields()

    local function commitColor(fire)
        refreshFields()
        if fire ~= false then
            SafeCallback(info.Callback, value)
            SafeCallback(info.Changed, value)
        end
    end

    local maid = CreateMaid()
    local draggingSV, draggingHue = false, false

    local function guiMouse()
        local m = Services.UserInputService:GetMouseLocation()
        local inset = Services.GuiService:GetGuiInset()
        return Vector2.new(m.X - inset.X, m.Y - inset.Y)
    end

    local function updateSV(pos)
        local p = typeof(pos) == "Vector2" and pos or Vector2.new(pos.X, pos.Y)
        local rel = p - svFrame.AbsolutePosition
        local size = svFrame.AbsoluteSize
        s = math.clamp(rel.X / math.max(size.X, 1), 0, 1)
        v = 1 - math.clamp(rel.Y / math.max(size.Y, 1), 0, 1)
        commitColor(true)
    end

    local function updateHue(pos)
        local p = typeof(pos) == "Vector2" and pos or Vector2.new(pos.X, pos.Y)
        local rel = p.X - hueBar.AbsolutePosition.X
        h = math.clamp(rel / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
        commitColor(true)
    end

    maid:Connect(svHit.MouseButton1Down, function()
        draggingSV = true
        updateSV(guiMouse())
    end)
    maid:Connect(svHit.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            draggingSV = true
            updateSV(input.Position)
        end
    end)
    maid:Connect(hueBar.InputBegan, function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            draggingHue = true
            updateHue(input.Position)
        end
    end)
    maid:Connect(Services.UserInputService.InputChanged, function(input)
        local t = input.UserInputType
        if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then
            return
        end
        if draggingSV then
            updateSV(input.Position)
        elseif draggingHue then
            updateHue(input.Position)
        end
    end)
    maid:Connect(Services.UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingSV, draggingHue = false, false
        end
    end)

    local function copyText(tb)
        pcall(setclipboard, tb.Text)
        Library:Notify("Copied: " .. tb.Text, 1.5, "success")
    end
    maid:Connect(hexCopy.MouseButton1Click, function() copyText(hexBox) end)
    maid:Connect(hslCopy.MouseButton1Click, function() copyText(hslBox) end)
    maid:Connect(rgbCopy.MouseButton1Click, function() copyText(rgbBox) end)

    local function positionPanel()
        local abs = swatch.AbsolutePosition
        local size = swatch.AbsoluteSize
        panel.Position = UDim2.fromOffset(abs.X + size.X - 220, abs.Y + size.Y + 6)
    end

    local function openPanel()
        if info.Disabled then return end
        panelOpen = true
        positionPanel()
        panel.Visible = true
    end
    local function closePanel()
        panelOpen = false
        panel.Visible = false
    end

    maid:Connect(swatch.MouseButton1Click, function()
        if panelOpen then closePanel() else openPanel() end
    end)
    maid:Connect(Services.RunService.RenderStepped, function()
        if panelOpen then positionPanel() end
    end)
    maid:Connect(Services.UserInputService.InputBegan, function(input)
        if not panelOpen then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local pos = input.Position
            local pPos, pSize = panel.AbsolutePosition, panel.AbsoluteSize
            local sPos, sSize = swatch.AbsolutePosition, swatch.AbsoluteSize
            local overP = pos.X >= pPos.X and pos.X <= pPos.X + pSize.X and pos.Y >= pPos.Y and pos.Y <= pPos.Y + pSize.Y
            local overS = pos.X >= sPos.X and pos.X <= sPos.X + sSize.X and pos.Y >= sPos.Y and pos.Y <= sPos.Y + sSize.Y
            if not overP and not overS then closePanel() end
        end
    end)

    local el = {
        Type = "ColorPicker", Flag = flag, Holder = holder, Value = value,
        Visible = info.Visible, Disabled = info.Disabled, ParentBox = self, Maid = maid, Text = info.Text,
    }
    function el:SetValue(c, fire)
        h, s, v = c:ToHSV()
        value = c; self.Value = value; refreshFields()
        if fire ~= false then SafeCallback(info.Callback, value); SafeCallback(info.Changed, value) end
    end
    function el:GetValue() return value end
    function el:SetText(t) self.Text = t; label.Text = t end
    function el:SetDisabled(d) self.Disabled = d; info.Disabled = d end
    function el:SetVisible(v) self.Visible = v ~= false; ApplyElementVisibility(holder, self.Visible); self.ParentBox:Resize() end
    function el:Destroy()
        closePanel(); maid:Clean(); panel:Destroy(); UnregisterOption(flag); holder:Destroy()
        local i = table.find(self.ParentBox.Elements, self)
        if i then table.remove(self.ParentBox.Elements, i) end
        self.ParentBox:Resize()
    end

    RegisterOption(flag, el)
    if flag then Library.Flags[flag] = value end
    table.insert(self.Elements, el)
    self:Resize()
    return el
end

--// Dependency Groupbox
function GroupboxMeta:AddDependencyGroupbox(info)
    info = info or {}
    local deps = info.Dependencies or {}

    local depHolder = New("Frame", {
        BackgroundColor3 = "Element", BackgroundTransparency = 0.35,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false, Parent = self.Content,
    })
    AddCorner(depHolder, 6)
    AddStroke(depHolder)
    AddPadding(depHolder, 6, 6, 6, 6)
    local depLayout = New("UIListLayout", { Padding = UDim.new(0, 4), Parent = depHolder })

    local depBox = setmetatable({
        Content = depHolder, Layout = depLayout, Elements = {}, Holder = depHolder,
        Collapsed = false, Visible = false, Column = self.Column, ParentBox = self,
        Maid = CreateMaid(), _destroyed = false,
    }, GroupboxMeta)

    local function evaluate()
        local show = true
        for _, d in ipairs(deps) do
            local opt, expected = d[1], d[2]
            local val = nil
            if type(opt) == "table" then
                if opt.GetValue then val = opt:GetValue()
                elseif opt.Value ~= nil then val = opt.Value end
            end
            if val ~= expected then show = false; break end
        end
        depBox.Visible = show
        depHolder.Visible = show
        self:Resize()
    end

    task.spawn(function()
        while not depBox._destroyed do
            evaluate()
            task.wait(0.12)
        end
    end)

    function depBox:Resize()
        if self.ParentBox then self.ParentBox:Resize() end
    end

    table.insert(self.Elements, depBox)
    self:Resize()
    return depBox
end

--// Create Groupbox
local function CreateGroupbox(column, name, opts)
    opts = opts or {}
    local headerH = 34

    --// manual height (no AutomaticSize) so collapse can shrink the holder
    local holder = New("Frame", {
        BackgroundColor3 = "Surface",
        Size = UDim2.new(1, 0, 0, headerH),
        ClipsDescendants = true,
        Parent = column.Container,
    })
    AddCorner(holder, Library.CornerRadius)
    AddStroke(holder)

    local header = New("TextButton", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, headerH), Text = "", Parent = holder,
    })
    local titleLabel = New("TextLabel", {
        Text = name or "Group", Size = UDim2.new(1, -36, 1, 0),
        Position = UDim2.fromOffset(12, 0), TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold, TextSize = 13, Parent = header,
    })

    --// right chevron: open=90 (down), collapsed=0 (right)
    local chevron = IconImage(header, "ChevronRight", UDim2.fromOffset(12, 12), "SubText")
    chevron.AnchorPoint = Vector2.new(1, 0.5)
    chevron.Position = UDim2.new(1, -12, 0.5, 0)
    chevron.Rotation = 90

    local content = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, headerH),
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Parent = holder,
    })
    AddPadding(content, 4, 12, 10, 12)
    local layout = New("UIListLayout", {
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content,
    })

    local box = setmetatable({
        Name = name, Holder = holder, Header = header, TitleLabel = titleLabel,
        Chevron = chevron, Content = content, Layout = layout, Elements = {},
        Collapsed = false, Visible = true, Column = column, Maid = CreateMaid(),
        HeaderHeight = headerH, _destroyed = false, _heightTween = nil, _holderTween = nil,
    }, GroupboxMeta)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if not box.Collapsed then box:Resize() end
    end)

    box.Maid:Connect(header.MouseButton1Click, function()
        box:ToggleCollapse()
    end)

    task.defer(function() box:Resize() end)
    table.insert(column.Groupboxes, box)
    return box
end

--// Column / Tab
local ColumnMeta = {}
ColumnMeta.__index = ColumnMeta

function ColumnMeta:UpdateHeight() end
function ColumnMeta:AddGroupbox(name, opts)
    return CreateGroupbox(self, name, opts)
end

local TabMeta = {}
TabMeta.__index = TabMeta

function TabMeta:Show()
    if Library.ActiveTab == self then return end
    if Library.ActiveTab then Library.ActiveTab:Hide() end
    self.Canvas.Visible = true
    if Library.Animations.Tabs and Library.Animations.Enabled then
        self.Canvas.GroupTransparency = 1
        Tween(self.Canvas, { GroupTransparency = 0 }, "Tab")
    else
        self.Canvas.GroupTransparency = 0
    end
    if self.Button then
        self.Button.BackgroundTransparency = 0
        if self.ButtonLabel then self.ButtonLabel.TextTransparency = 0 end
    end
    Library.ActiveTab = self
    if self.LeftColumn and self.LeftColumn.UpdateHeight then
        task.defer(self.LeftColumn.UpdateHeight)
    end
    if Library.Searching then Library:UpdateSearch(Library.SearchText) end
end

function TabMeta:Hide()
    if Library.Animations.Tabs and Library.Animations.Enabled then
        local t = Tween(self.Canvas, { GroupTransparency = 1 }, "Tab")
        if t then
            t.Completed:Connect(function()
                if Library.ActiveTab ~= self then self.Canvas.Visible = false end
            end)
        end
    else
        self.Canvas.Visible = false
        self.Canvas.GroupTransparency = 1
    end
    if self.Button then
        self.Button.BackgroundTransparency = 1
        if self.ButtonLabel then self.ButtonLabel.TextTransparency = 0.45 end
    end
end

function TabMeta:AddLeftGroupbox(name, opts)
    return self.LeftColumn:AddGroupbox(name, opts)
end
function TabMeta:AddRightGroupbox(name, opts)
    return self.RightColumn:AddGroupbox(name, opts)
end
function TabMeta:AddGroupbox(info)
    info = info or {}
    local side = string.lower(info.Side or "Left")
    local name = info.Name or "Group"
    if side == "right" then return self:AddRightGroupbox(name, info) end
    return self:AddLeftGroupbox(name, info)
end

function TabMeta:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    if self.Maid then self.Maid:Clean() end
    for _, col in ipairs({ self.LeftColumn, self.RightColumn }) do
        if col then
            for _, g in ipairs(col.Groupboxes) do
                if g.Destroy then g:Destroy() end
            end
        end
    end
    if self.Canvas then self.Canvas:Destroy() end
    if self.Button then self.Button:Destroy() end
    Library.Tabs[self.Name] = nil
    if Library.ActiveTab == self then Library.ActiveTab = nil end
end

--// Window
function Library:CreateWindow(info)
    info = Validate(info or {}, {
        Title = "Aether", Footer = "", Size = UDim2.fromOffset(720, 520),
        Position = nil, Center = true, Resizable = true,
        ToggleKeybind = Enum.KeyCode.RightControl, Searchbar = true, GlobalSearch = false,
        StackColumnsOnMobile = false, MinSidebarWidth = 140, SidebarWidth = 168,
        CornerRadius = 10, AutoShow = true,
    })

    Library.ToggleKeybind = info.ToggleKeybind or Library.ToggleKeybind
    Library.GlobalSearch = info.GlobalSearch
    Library.CornerRadius = info.CornerRadius or Library.CornerRadius

    local windowMaid = CreateMaid()

    local main = New("Frame", {
        Name = "Main", BackgroundColor3 = "Background",
        Size = info.Size, Position = info.Position or UDim2.fromOffset(80, 80),
        ClipsDescendants = true, Visible = false, Parent = ScreenGui,
    })
    AddCorner(main, info.CornerRadius)
    AddStroke(main)

    if info.Center then
        local cam = workspace.CurrentCamera
        local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
        main.Position = UDim2.fromOffset(
            math.floor((vs.X - info.Size.X.Offset) / 2),
            math.floor((vs.Y - info.Size.Y.Offset) / 2)
        )
    end

    -- Top bar
    local topBar = New("Frame", {
        BackgroundColor3 = "Surface", Size = UDim2.new(1, 0, 0, 44), Parent = main,
    })
    New("UICorner", { CornerRadius = UDim.new(0, info.CornerRadius), Parent = topBar })
    New("Frame", {
        BackgroundColor3 = "Surface", Position = UDim2.new(0, 0, 1, -12),
        Size = UDim2.new(1, 0, 0, 12), BorderSizePixel = 0, Parent = topBar,
    })

    local titleLabel = New("TextLabel", {
        Text = info.Title, Font = Enum.Font.GothamBold, TextSize = 15,
        Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(14, 0),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = topBar,
    })

    Library:MakeDraggable(main, topBar)

    if info.Resizable then
        local grip = New("Frame", {
            AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1),
            Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, Parent = main,
        })
        Library:MakeResizable(main, grip)
    end

    local sidebarWidth = info.SidebarWidth
    local sidebar = New("Frame", {
        BackgroundColor3 = "Surface", Position = UDim2.fromOffset(0, 44),
        Size = UDim2.new(0, sidebarWidth, 1, -44), Parent = main,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sidebar,
    })
    AddPadding(sidebar, 8, 8, 8, 8)

    New("Frame", {
        BackgroundColor3 = "Border", Position = UDim2.new(0, sidebarWidth, 0, 44),
        Size = UDim2.new(0, 1, 1, -44), Parent = main,
    })

    local contentHost = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, sidebarWidth + 1, 0, 44),
        Size = UDim2.new(1, -(sidebarWidth + 1), 1, -44),
        ClipsDescendants = true, Parent = main,
    })

    if info.Searchbar then
        local searchHolder = New("Frame", {
            BackgroundColor3 = "Element", Size = UDim2.new(1, 0, 0, 30), Parent = sidebar,
        })
        AddCorner(searchHolder, 6)
        AddStroke(searchHolder)
        local searchIcon = IconImage(searchHolder, "Search", UDim2.fromOffset(14, 14), "SubText")
        searchIcon.Position = UDim2.fromOffset(8, 8)
        local searchBox = New("TextBox", {
            BackgroundTransparency = 1, Size = UDim2.new(1, -30, 1, 0),
            Position = UDim2.fromOffset(28, 0), PlaceholderText = "Search...",
            Text = "", TextXAlignment = Enum.TextXAlignment.Left, Parent = searchHolder,
        })
        windowMaid:Connect(searchBox:GetPropertyChangedSignal("Text"), function()
            Library:UpdateSearch(searchBox.Text)
        end)
    end

    local Window = {
        Main = main, Sidebar = sidebar, ContentHost = contentHost,
        Tabs = {}, Title = info.Title, Info = info, Maid = windowMaid,
        StackColumnsOnMobile = info.StackColumnsOnMobile,
        Sections = {},
        _currentSection = nil,
        _sidebarOrder = 0,
    }

    local function nextSidebarOrder()
        Window._sidebarOrder += 1
        return Window._sidebarOrder
    end

    function Window:AddTabSection(sectionInfo)
        if type(sectionInfo) == "string" then
            sectionInfo = { Text = sectionInfo }
        end
        sectionInfo = Validate(sectionInfo or {}, {
            Text = "Section",
            Collapsible = false,
            XAlignments = "Left",
            XAlegnments = nil,
            Icon = nil,
        })

        local align = string.lower(tostring(sectionInfo.XAlignments or sectionInfo.XAlegnments or "Left"))
        local textAlign = Enum.TextXAlignment.Left
        if align == "center" then
            textAlign = Enum.TextXAlignment.Center
        elseif align == "right" then
            textAlign = Enum.TextXAlignment.Right
        end

        local collapsible = sectionInfo.Collapsible == true
        local collapsed = false
        local tabButtons = {}

        local header = New("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 26),
            Text = "",
            LayoutOrder = nextSidebarOrder(),
            AutoButtonColor = false,
            Parent = sidebar,
        })

        local leftPad = 6
        local iconImg = nil
        if sectionInfo.Icon and tostring(sectionInfo.Icon) ~= "" then
            iconImg = IconImage(header, sectionInfo.Icon, UDim2.fromOffset(14, 14), "SubText")
            iconImg.Position = UDim2.fromOffset(6, 6)
            leftPad = 26
        end

        local label = New("TextLabel", {
            Text = sectionInfo.Text,
            Size = UDim2.new(1, collapsible and -(leftPad + 22) or -leftPad, 1, 0),
            Position = UDim2.fromOffset(leftPad, 0),
            TextXAlignment = textAlign,
            TextColor3 = "SubText",
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextTransparency = 0.15,
            Parent = header,
        })

        local chevron = nil
        if collapsible then
            chevron = IconImage(header, "ChevronRight", UDim2.fromOffset(12, 12), "SubText")
            chevron.AnchorPoint = Vector2.new(1, 0.5)
            chevron.Position = UDim2.new(1, -4, 0.5, 0)
            chevron.Rotation = 90
            chevron.ImageTransparency = 0.25
        end

        local function setCollapsed(state)
            collapsed = state and true or false
            if chevron then
                Tween(chevron, { Rotation = collapsed and 0 or 90 }, "Default")
            end
            for _, btn in ipairs(tabButtons) do
                btn.Visible = not collapsed
            end
        end

        local section = {
            Text = sectionInfo.Text,
            Header = header,
            Label = label,
            Collapsible = collapsible,
            Collapsed = false,
            TabButtons = tabButtons,
            Tabs = {},
        }

        function section:SetCollapsed(v)
            setCollapsed(v)
            self.Collapsed = collapsed
        end

        function section:Toggle()
            self:SetCollapsed(not collapsed)
        end

        function section:SetText(t)
            self.Text = t
            label.Text = t
        end

        function section:RegisterTabButton(btn, tab)
            table.insert(tabButtons, btn)
            table.insert(self.Tabs, tab)
            btn.Visible = not collapsed
        end

        if collapsible then
            header.MouseButton1Click:Connect(function()
                section:Toggle()
            end)
        end

        table.insert(Window.Sections, section)
        Window._currentSection = section
        return section
    end

    function Window:AddTab(tabInfo)
        if type(tabInfo) == "string" then tabInfo = { Name = tabInfo } end
        tabInfo = Validate(tabInfo or {}, { Name = "Tab", Icon = nil })
        local name = tabInfo.Name

        local tabBtn = New("TextButton", {
            BackgroundColor3 = "Element", BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 32), Text = "",
            LayoutOrder = nextSidebarOrder(),
            Parent = sidebar,
        })
        AddCorner(tabBtn, 6)

        local labelPad = 10
        if tabInfo.Icon and tostring(tabInfo.Icon) ~= "" then
            local tIcon = IconImage(tabBtn, tabInfo.Icon, UDim2.fromOffset(14, 14), "SubText")
            tIcon.Position = UDim2.fromOffset(10, 9)
            tIcon.ImageTransparency = 0.35
            labelPad = 30
        end

        local tabLabel = New("TextLabel", {
            Text = name, Size = UDim2.new(1, -labelPad, 1, 0), Position = UDim2.fromOffset(labelPad, 0),
            TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 0.45, Parent = tabBtn,
        })

        local canvas = New("CanvasGroup", {
            BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
            Visible = false, GroupTransparency = 1, Parent = contentHost,
        })

        --// one ScrollingFrame for the whole tab
        local scroll = New("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 0,
            ScrollBarImageTransparency = 1,
            CanvasSize = UDim2.new(),
            Parent = canvas,
        })
        AddPadding(scroll, 12, 12, 12, 12)

        local gap = 12
        local columnsFrame = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Parent = scroll,
        })

        local leftColFrame = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(200, 0),
            Parent = columnsFrame,
        })
        local leftLayout = New("UIListLayout", {
            Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = leftColFrame,
        })

        local rightColFrame = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(212, 0),
            Size = UDim2.fromOffset(200, 0),
            Parent = columnsFrame,
        })
        local rightLayout = New("UIListLayout", {
            Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = rightColFrame,
        })

        local function applyColumnLayout()
            if not leftColFrame or not rightColFrame then return end

            local lh = math.max(leftLayout.AbsoluteContentSize.Y, 0)
            local rh = math.max(rightLayout.AbsoluteContentSize.Y, 0)
            local halfGap = gap / 2

            --// scale-based so both columns always fit inside the scroller
            columnsFrame.Size = UDim2.new(1, 0, 0, math.max(lh, rh, 1))
            leftColFrame.Position = UDim2.new(0, 0, 0, 0)
            leftColFrame.Size = UDim2.new(0.5, -halfGap, 0, lh)
            rightColFrame.Position = UDim2.new(0.5, halfGap, 0, 0)
            rightColFrame.Size = UDim2.new(0.5, -halfGap, 0, rh)
        end

        leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(applyColumnLayout)
        rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(applyColumnLayout)
        scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyColumnLayout)

        local leftColumn = setmetatable({
            Container = leftColFrame, Layout = leftLayout, Groupboxes = {}, Side = "Left", Tab = nil,
            UpdateHeight = applyColumnLayout,
        }, ColumnMeta)
        local rightColumn = setmetatable({
            Container = rightColFrame, Layout = rightLayout, Groupboxes = {}, Side = "Right", Tab = nil,
            UpdateHeight = applyColumnLayout,
        }, ColumnMeta)

        local tab = setmetatable({
            Name = name, Button = tabBtn, ButtonLabel = tabLabel, Canvas = canvas,
            Scroll = scroll, ColumnsFrame = columnsFrame,
            LeftColumn = leftColumn, RightColumn = rightColumn,
            Maid = CreateMaid(), _destroyed = false,
        }, TabMeta)

        leftColumn.Tab = tab
        rightColumn.Tab = tab

        applyColumnLayout()
        windowMaid:Connect(main:GetPropertyChangedSignal("AbsoluteSize"), applyColumnLayout)

        tab.Maid:Connect(tabBtn.MouseButton1Click, function() tab:Show() end)
        tab.Maid:Connect(tabBtn.MouseEnter, function()
            if Library.ActiveTab ~= tab then tabLabel.TextTransparency = 0.15 end
        end)
        tab.Maid:Connect(tabBtn.MouseLeave, function()
            if Library.ActiveTab ~= tab then tabLabel.TextTransparency = 0.45 end
        end)

        Window.Tabs[name] = tab
        Library.Tabs[name] = tab

        if Window._currentSection and Window._currentSection.RegisterTabButton then
            Window._currentSection:RegisterTabButton(tabBtn, tab)
            tab.Section = Window._currentSection
        end

        if not Library.ActiveTab then tab:Show() end
        return tab
    end

    function Window:Toggle(value)
        if typeof(value) == "boolean" then Library.Toggled = value
        else Library.Toggled = not Library.Toggled end

        if Library.Animations.Window and Library.Animations.Enabled then
            if Library.Toggled then
                main.Visible = true
                main.BackgroundTransparency = 1
                -- scale pop
                local scale = main:FindFirstChildOfClass("UIScale") or New("UIScale", { Scale = 0.96, Parent = main })
                scale.Scale = 0.96
                Tween(main, { BackgroundTransparency = 0 }, "Window")
                Tween(scale, { Scale = 1 }, "Window")
            else
                local scale = main:FindFirstChildOfClass("UIScale") or New("UIScale", { Scale = 1, Parent = main })
                Tween(scale, { Scale = 0.96 }, "Window")
                local t = Tween(main, { BackgroundTransparency = 1 }, "Window")
                if t then
                    t.Completed:Connect(function()
                        if not Library.Toggled then main.Visible = false end
                    end)
                end
            end
        else
            main.Visible = Library.Toggled
        end
    end

    function Window:Destroy()
        windowMaid:Clean()
        for _, tab in pairs(Window.Tabs) do
            if tab.Destroy then tab:Destroy() end
        end
        main:Destroy()
        Library.Window = nil
    end

    Library.Window = Window
    Library.Toggle = function(_, v) return Window:Toggle(v) end

    Library:GiveSignal(Services.UserInputService.InputBegan:Connect(function(input)
        if Library.Unloaded then return end
        if Services.UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == Library.ToggleKeybind then Window:Toggle() end
    end))
    Library:GiveSignal(Services.UserInputService.WindowFocused:Connect(function()
        Library.IsRobloxFocused = true
    end))
    Library:GiveSignal(Services.UserInputService.WindowFocusReleased:Connect(function()
        Library.IsRobloxFocused = false
    end))

    if info.AutoShow then
        task.defer(function() Window:Toggle(true) end)
    end

    return Window
end

--// Search
local function MatchText(text, search)
    if not text or search == "" then return true end
    return string.find(string.lower(tostring(text)), search, 1, true) ~= nil
end

local function ApplySearchToGroupbox(box, search)
    local visibleCount = 0
    for _, el in ipairs(box.Elements) do
        if el.Type == "Divider" then
            el.Holder.Visible = false
        elseif el.Elements then
            local sub = ApplySearchToGroupbox(el, search)
            visibleCount += sub
            el.Holder.Visible = sub > 0 and el.Visible ~= false
        else
            local show = MatchText(el.Text, search) and el.Visible ~= false
            if el.Holder then el.Holder.Visible = show end
            if show then visibleCount += 1 end
        end
    end
    if box.Holder then
        box.Holder.Visible = (visibleCount > 0) and (box.Visible ~= false)
    end
    box:Resize()
    return visibleCount
end

local function ResetGroupbox(box)
    for _, el in ipairs(box.Elements) do
        if el.Elements then ResetGroupbox(el)
        elseif el.Holder then el.Holder.Visible = el.Visible ~= false end
    end
    if box.Holder then box.Holder.Visible = box.Visible ~= false end
    box:Resize()
end

function Library:UpdateSearch(text)
    Library.SearchText = text or ""
    local search = string.lower(Trim(Library.SearchText))
    local tabsToProcess = {}
    if Library.GlobalSearch then
        for _, t in pairs(Library.Tabs) do table.insert(tabsToProcess, t) end
    elseif Library.ActiveTab then
        table.insert(tabsToProcess, Library.ActiveTab)
    end

    if search == "" then
        Library.Searching = false
        for _, tab in ipairs(tabsToProcess) do
            for _, col in ipairs({ tab.LeftColumn, tab.RightColumn }) do
                if col then for _, g in ipairs(col.Groupboxes) do ResetGroupbox(g) end end
            end
        end
        return
    end

    Library.Searching = true
    for _, tab in ipairs(tabsToProcess) do
        for _, col in ipairs({ tab.LeftColumn, tab.RightColumn }) do
            if col then for _, g in ipairs(col.Groupboxes) do ApplySearchToGroupbox(g, search) end end
        end
    end
end

--// Unload
function Library:Unload()
    Library.Unloaded = true
    for i = #Library.Signals, 1, -1 do
        local c = table.remove(Library.Signals, i)
        if c and c.Connected then pcall(function() c:Disconnect() end) end
    end
    for i = #Library.UnloadSignals, 1, -1 do
        SafeCallback(table.remove(Library.UnloadSignals, i))
    end
    if Library.Window and Library.Window.Destroy then Library.Window:Destroy() end
    if ScreenGui then ScreenGui:Destroy() end
    table.clear(Library.Registry)
    table.clear(Library.Flags)
    table.clear(Library.Options)
    table.clear(Library.Toggles)
    table.clear(Library.Tabs)
    table.clear(Library.Notifications)
    table.clear(Library.Signals)
    getgenv().Aether = nil
    getgenv().Library = nil
end

--// Export
getgenv().Aether = Library
getgenv().Library = Library
return Library
