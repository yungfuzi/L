--[[
    Aether — Roblox Luau UI Library
    Clean architecture inspired by modern UI patterns.
    Single shared ScrollingFrame per Tab with Left/Right columns.
]]

local Services = {
    CoreGui = game:GetService("CoreGui"),
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    TextService = game:GetService("TextService"),
    HttpService = game:GetService("HttpService"),
}

local LocalPlayer = Services.Players.LocalPlayer or Services.Players.PlayerAdded:Wait()
local Mouse = LocalPlayer:GetMouse()

local getgenv = getgenv or function() return shared end
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function() return Services.CoreGui end

----------------------------------------------------------------
-- Library Core
----------------------------------------------------------------
local Library = {
    Version = "1.0.0",
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

    Registry = {},          -- Instance -> { Property = ThemeKey | function }
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
    CornerRadius = 6,

    ToggleKeybind = Enum.KeyCode.RightControl,
    NotifySide = "Right",
    ShowCustomCursor = false,

    Animations = {
        Window = true,
        Tabs = true,
        Groupboxes = true,
        Dropdowns = true,
        Notifications = true,
    },

    TweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    WindowTweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TabTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    CollapseTweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

    Theme = {
        Background   = Color3.fromRGB(18, 18, 22),
        Surface      = Color3.fromRGB(24, 24, 30),
        Element      = Color3.fromRGB(32, 32, 40),
        ElementHover = Color3.fromRGB(40, 40, 50),
        Accent       = Color3.fromRGB(110, 90, 255),
        AccentDark   = Color3.fromRGB(80, 60, 200),
        Text         = Color3.fromRGB(235, 235, 245),
        SubText      = Color3.fromRGB(150, 150, 170),
        Border       = Color3.fromRGB(45, 45, 58),
        Success      = Color3.fromRGB(70, 200, 120),
        Warning      = Color3.fromRGB(240, 180, 50),
        Danger       = Color3.fromRGB(230, 70, 70),
        White        = Color3.new(1, 1, 1),
        Black        = Color3.new(0, 0, 0),
    },
}

----------------------------------------------------------------
-- Utilities
----------------------------------------------------------------
local function DeepCopy(t)
    if type(t) ~= "table" then return t end
    local n = {}
    for k, v in pairs(t) do
        n[k] = DeepCopy(v)
    end
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
    if places <= 0 then
        return math.floor(value + 0.5)
    end
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
    if ok and bounds then
        return bounds.X, bounds.Y
    end
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
    if not ok then
        warn("[Aether] Callback error:", err)
    end
end

local function StopTween(tween)
    if tween and tween.PlaybackState == Enum.PlaybackState.Playing then
        pcall(function() tween:Cancel() end)
    end
end

----------------------------------------------------------------
-- Signal / Connection management
----------------------------------------------------------------
function Library:GiveSignal(conn)
    if conn then
        table.insert(self.Signals, conn)
    end
    return conn
end

function Library:Connect(signal, fn)
    local conn = signal:Connect(fn)
    return self:GiveSignal(conn)
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
            local t = self._tasks[i]
            self._tasks[i] = nil
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

----------------------------------------------------------------
-- Theme Registry
----------------------------------------------------------------
function Library:AddToRegistry(inst, props)
    self.Registry[inst] = props
end

function Library:RemoveFromRegistry(inst)
    self.Registry[inst] = nil
end

function Library:GetThemeValue(key)
    if type(key) == "function" then
        return key()
    end
    return self.Theme[key]
end

function Library:UpdateTheme()
    for inst, props in pairs(self.Registry) do
        if inst and inst.Parent then
            for prop, key in pairs(props) do
                local val = self:GetThemeValue(key)
                if val ~= nil then
                    pcall(function()
                        inst[prop] = val
                    end)
                end
            end
        end
    end
end

function Library:SetTheme(newTheme)
    if type(newTheme) ~= "table" then return end
    for k, v in pairs(newTheme) do
        if self.Theme[k] ~= nil then
            self.Theme[k] = v
        end
    end
    self:UpdateTheme()
end

----------------------------------------------------------------
-- Instance creation helpers
----------------------------------------------------------------
local Templates = {
    Frame = { BorderSizePixel = 0, BackgroundColor3 = "Surface" },
    TextLabel = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        TextColor3 = "Text",
        TextSize = 14,
        RichText = true,
    },
    TextButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        TextColor3 = "Text",
        TextSize = 14,
        RichText = true,
    },
    TextBox = {
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        TextColor3 = "Text",
        PlaceholderColor3 = "SubText",
        TextSize = 14,
        ClearTextOnFocus = false,
    },
    ImageLabel = { BackgroundTransparency = 1, BorderSizePixel = 0 },
    ImageButton = { AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0 },
    ScrollingFrame = {
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = "Border",
        BackgroundTransparency = 1,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    },
    UIListLayout = { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) },
    UIPadding = {},
    UICorner = { CornerRadius = UDim.new(0, 6) },
    UIStroke = { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Color = "Border" },
}

local function New(className, props)
    local inst = Instance.new(className)
    local base = Templates[className]
    if base then
        for k, v in pairs(base) do
            local themeVal = Library:GetThemeValue(v)
            if themeVal ~= nil then
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
        if next(reg) then
            Library.Registry[inst] = reg
        end
    end
    return inst
end

local function AddCorner(parent, radius)
    radius = radius or Library.CornerRadius
    return New("UICorner", {
        CornerRadius = UDim.new(0, radius),
        Parent = parent,
    })
end

local function AddStroke(parent, colorKey)
    return New("UIStroke", {
        Color = colorKey or "Border",
        Thickness = 1,
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

----------------------------------------------------------------
-- Parenting
----------------------------------------------------------------
local function ParentUI(ui)
    pcall(protectgui, ui)
    local ok = pcall(function()
        ui.Parent = gethui()
    end)
    if not ok or not ui.Parent then
        ui.Parent = LocalPlayer:WaitForChild("PlayerGui", 10) or Services.CoreGui
    end
end

----------------------------------------------------------------
-- Detect mobile
----------------------------------------------------------------
do
    local ok, platform = pcall(function()
        return Services.UserInputService:GetPlatform()
    end)
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

----------------------------------------------------------------
-- ScreenGui
----------------------------------------------------------------
local ScreenGui = New("ScreenGui", {
    Name = "Aether",
    DisplayOrder = 1000,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui

ScreenGui.DescendantRemoving:Connect(function(desc)
    Library:RemoveFromRegistry(desc)
end)

----------------------------------------------------------------
-- Notifications
----------------------------------------------------------------
local NotifyArea = New("Frame", {
    Name = "Notifications",
    AnchorPoint = Vector2.new(1, 0),
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -12, 0, 12),
    Size = UDim2.new(0, 280, 1, -24),
    Parent = ScreenGui,
})
New("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Parent = NotifyArea,
})

function Library:Notify(text, duration)
    duration = duration or 3
    local card = New("Frame", {
        BackgroundColor3 = "Surface",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = NotifyArea,
    })
    AddCorner(card, 8)
    AddStroke(card)
    AddPadding(card, 10, 12, 10, 12)

    local label = New("TextLabel", {
        Text = tostring(text),
        TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    if Library.Animations.Notifications then
        card.BackgroundTransparency = 1
        label.TextTransparency = 1
        Services.TweenService:Create(card, Library.TweenInfo, { BackgroundTransparency = 0 }):Play()
        Services.TweenService:Create(label, Library.TweenInfo, { TextTransparency = 0 }):Play()
    end

    task.delay(duration, function()
        if not card.Parent then return end
        if Library.Animations.Notifications then
            local t1 = Services.TweenService:Create(card, Library.TweenInfo, { BackgroundTransparency = 1 })
            local t2 = Services.TweenService:Create(label, Library.TweenInfo, { TextTransparency = 1 })
            t1:Play()
            t2:Play()
            t1.Completed:Wait()
        end
        card:Destroy()
    end)

    return card
end

----------------------------------------------------------------
-- Dragging / Resizing helpers
----------------------------------------------------------------
function Library:MakeDraggable(ui, handle, ignoreToggle)
    local dragging, startPos, startFrame
    local began, changed, ended

    began = handle.InputBegan:Connect(function(input)
        if not IsClick(input) then return end
        if not ignoreToggle and not Library.Toggled then return end
        if Library.CantDragForced then return end
        dragging = true
        startPos = input.Position
        startFrame = ui.Position
        local c
        c = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if c then c:Disconnect() end
            end
        end)
    end)

    changed = Services.UserInputService.InputChanged:Connect(function(input)
        if not dragging or not IsHover(input) then return end
        local delta = input.Position - startPos
        ui.Position = UDim2.new(
            startFrame.X.Scale, startFrame.X.Offset + delta.X,
            startFrame.Y.Scale, startFrame.Y.Offset + delta.Y
        )
    end)

    Library:GiveSignal(began)
    Library:GiveSignal(changed)
end

function Library:MakeResizable(ui, handle, onResize)
    local dragging, startPos, startSize
    local began, changed

    began = handle.InputBegan:Connect(function(input)
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

    changed = Services.UserInputService.InputChanged:Connect(function(input)
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

----------------------------------------------------------------
-- Base element helpers
----------------------------------------------------------------
local function CreateElementShell(parent, height)
    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height or 28),
        Parent = parent,
    })
    return holder
end

local function ApplyElementVisibility(holder, visible)
    holder.Visible = visible ~= false
end

----------------------------------------------------------------
-- GROUPBOX (shared abstraction)
----------------------------------------------------------------
local GroupboxMeta = {}
GroupboxMeta.__index = GroupboxMeta

function GroupboxMeta:Resize()
    if self._destroyed then return end
    local content = self.Content
    local layout = self.Layout
    if not content or not layout then return end

    -- Force layout update
    local y = 0
    for _, child in ipairs(content:GetChildren()) do
        if child:IsA("GuiObject") and child.Visible and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            y = y + child.AbsoluteSize.Y + layout.Padding.Offset
        end
    end
    -- Use AbsoluteContentSize when available
    local target = math.max(layout.AbsoluteContentSize.Y + 8, 0)

    if self.Collapsed then
        target = 0
    end

    if Library.Animations.Groupboxes and self._heightTween then
        StopTween(self._heightTween)
    end

    if Library.Animations.Groupboxes then
        self._heightTween = Services.TweenService:Create(content, Library.CollapseTweenInfo, {
            Size = UDim2.new(1, 0, 0, target)
        })
        self._heightTween:Play()
    else
        content.Size = UDim2.new(1, 0, 0, target)
    end

    -- Propagate to column / tab
    if self.Column and self.Column.UpdateHeight then
        self.Column:UpdateHeight()
    end
end

function GroupboxMeta:SetCollapsed(state)
    self.Collapsed = state and true or false
    if self.Chevron then
        local rot = self.Collapsed and -90 or 0
        Services.TweenService:Create(self.Chevron, Library.TweenInfo, { Rotation = rot }):Play()
    end
    self:Resize()
end

function GroupboxMeta:ToggleCollapse()
    self:SetCollapsed(not self.Collapsed)
end

function GroupboxMeta:SetVisible(v)
    self.Visible = v ~= false
    if self.Holder then
        self.Holder.Visible = self.Visible
    end
    if self.Column and self.Column.UpdateHeight then
        self.Column:UpdateHeight()
    end
end

function GroupboxMeta:SetTitle(text)
    if self.TitleLabel then
        self.TitleLabel.Text = text
    end
end

function GroupboxMeta:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    if self.Maid then self.Maid:Clean() end
    for _, el in ipairs(self.Elements) do
        if el.Destroy then pcall(function() el:Destroy() end) end
    end
    table.clear(self.Elements)
    if self.Holder then
        self.Holder:Destroy()
    end
    if self.Column and self.Column.Groupboxes then
        local idx = table.find(self.Column.Groupboxes, self)
        if idx then table.remove(self.Column.Groupboxes, idx) end
        self.Column:UpdateHeight()
    end
end

-- Element factories attached to Groupbox
local function RegisterOption(flag, option)
    if flag and flag ~= "" then
        Library.Options[flag] = option
        if option.Type == "Toggle" or option.Type == "Checkbox" then
            Library.Toggles[flag] = option
            Library.Flags[flag] = option.Value
        else
            Library.Flags[flag] = option.Value
        end
    end
end

local function UnregisterOption(flag)
    if flag and flag ~= "" then
        Library.Options[flag] = nil
        Library.Toggles[flag] = nil
        Library.Flags[flag] = nil
    end
end

----------------------------------------------------------------
-- ELEMENT: Label
----------------------------------------------------------------
function GroupboxMeta:AddLabel(flagOrText, info)
    local text, flag
    if type(flagOrText) == "table" then
        info = flagOrText
        text = info.Text or "Label"
        flag = info.Flag
    elseif type(info) == "table" then
        flag = flagOrText
        text = info.Text or tostring(flagOrText)
    else
        text = tostring(flagOrText)
    end
    info = info or {}

    local holder = CreateElementShell(self.Content, 22)
    local label = New("TextLabel", {
        Text = text,
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = info.Color and nil or "SubText",
        TextSize = info.TextSize or 13,
        Parent = holder,
    })
    if info.Color then label.TextColor3 = info.Color end

    local el = {
        Type = "Label",
        Holder = holder,
        Label = label,
        Visible = true,
        Text = text,
    }
    function el:SetText(t)
        self.Text = t
        label.Text = t
    end
    function el:SetVisible(v)
        self.Visible = v ~= false
        ApplyElementVisibility(holder, self.Visible)
        self.ParentBox:Resize()
    end
    function el:Destroy()
        holder:Destroy()
        local i = table.find(self.ParentBox.Elements, self)
        if i then table.remove(self.ParentBox.Elements, i) end
        self.ParentBox:Resize()
    end
    el.ParentBox = self
    table.insert(self.Elements, el)
    self:Resize()
    return el
end

----------------------------------------------------------------
-- ELEMENT: Divider
----------------------------------------------------------------
function GroupboxMeta:AddDivider()
    local holder = CreateElementShell(self.Content, 12)
    local line = New("Frame", {
        BackgroundColor3 = "Border",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.fromScale(0, 0.5),
        AnchorPoint = Vector2.new(0, 0.5),
        Parent = holder,
    })
    local el = {
        Type = "Divider",
        Holder = holder,
        Visible = true,
        ParentBox = self,
    }
    function el:SetVisible(v)
        self.Visible = v ~= false
        ApplyElementVisibility(holder, self.Visible)
        self.ParentBox:Resize()
    end
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

----------------------------------------------------------------
-- ELEMENT: Button
----------------------------------------------------------------
function GroupboxMeta:AddButton(flagOrInfo, info)
    if type(flagOrInfo) == "table" then
        info = flagOrInfo
    else
        info = info or {}
        info.Text = info.Text or tostring(flagOrInfo)
    end
    info = Validate(info, {
        Text = "Button",
        Callback = function() end,
        Disabled = false,
        Visible = true,
        Risky = false,
    })

    local holder = CreateElementShell(self.Content, 30)
    local btn = New("TextButton", {
        BackgroundColor3 = "Element",
        Size = UDim2.fromScale(1, 1),
        Text = info.Text,
        Parent = holder,
    })
    AddCorner(btn, 5)
    AddStroke(btn)

    local accent = info.Risky and "Danger" or "Accent"
    local function setState(hover)
        local col = hover and Library.Theme.ElementHover or Library.Theme.Element
        btn.BackgroundColor3 = col
    end

    local maid = CreateMaid()
    maid:Connect(btn.MouseEnter, function()
        if not info.Disabled then setState(true) end
    end)
    maid:Connect(btn.MouseLeave, function()
        setState(false)
    end)
    maid:Connect(btn.MouseButton1Click, function()
        if info.Disabled then return end
        SafeCallback(info.Callback)
    end)

    local el = {
        Type = "Button",
        Holder = holder,
        Button = btn,
        Visible = info.Visible,
        Disabled = info.Disabled,
        ParentBox = self,
        Maid = maid,
    }
    function el:SetText(t) btn.Text = t end
    function el:SetDisabled(d)
        self.Disabled = d
        info.Disabled = d
        btn.TextTransparency = d and 0.5 or 0
    end
    function el:SetVisible(v)
        self.Visible = v ~= false
        ApplyElementVisibility(holder, self.Visible)
        self.ParentBox:Resize()
    end
    function el:Destroy()
        maid:Clean()
        holder:Destroy()
        local i = table.find(self.ParentBox.Elements, self)
        if i then table.remove(self.ParentBox.Elements, i) end
        self.ParentBox:Resize()
    end

    table.insert(self.Elements, el)
    self:Resize()
    return el
end

----------------------------------------------------------------
-- ELEMENT: Toggle / Checkbox
----------------------------------------------------------------
function GroupboxMeta:AddToggle(flag, info)
    info = Validate(info or {}, {
        Text = tostring(flag or "Toggle"),
        Default = false,
        Callback = function() end,
        Changed = function() end,
        Disabled = false,
        Visible = true,
        Risky = false,
    })

    local holder = CreateElementShell(self.Content, 28)
    local label = New("TextLabel", {
        Text = info.Text,
        Size = UDim2.new(1, -40, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    local box = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(36, 20),
        BackgroundColor3 = "Element",
        Parent = holder,
    })
    AddCorner(box, 10)
    AddStroke(box)

    local knob = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = "Text",
        Parent = box,
    })
    AddCorner(knob, 8)

    local value = info.Default
    local function applyVisual(v, animate)
        local targetPos = v and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        local targetBg = v and Library.Theme.Accent or Library.Theme.Element
        if animate then
            Services.TweenService:Create(knob, Library.TweenInfo, { Position = targetPos }):Play()
            Services.TweenService:Create(box, Library.TweenInfo, { BackgroundColor3 = targetBg }):Play()
        else
            knob.Position = targetPos
            box.BackgroundColor3 = targetBg
        end
    end
    applyVisual(value, false)

    local maid = CreateMaid()
    local function setValue(v, fire)
        value = v and true or false
        applyVisual(value, true)
        if flag then Library.Flags[flag] = value end
        if fire ~= false then
            SafeCallback(info.Callback, value)
            SafeCallback(info.Changed, value)
        end
    end

    maid:Connect(holder.InputBegan, function(input)
        if info.Disabled then return end
        if IsClick(input) then
            setValue(not value)
        end
    end)

    local el = {
        Type = "Toggle",
        Flag = flag,
        Holder = holder,
        Value = value,
        Visible = info.Visible,
        Disabled = info.Disabled,
        ParentBox = self,
        Maid = maid,
        Text = info.Text,
    }
    function el:SetValue(v, fire)
        setValue(v, fire)
        self.Value = value
    end
    function el:GetValue() return value end
    function el:SetText(t)
        self.Text = t
        label.Text = t
    end
    function el:SetDisabled(d)
        self.Disabled = d
        info.Disabled = d
        label.TextTransparency = d and 0.5 or 0
    end
    function el:SetVisible(v)
        self.Visible = v ~= false
        ApplyElementVisibility(holder, self.Visible)
        self.ParentBox:Resize()
    end
    function el:Destroy()
        maid:Clean()
        UnregisterOption(flag)
        holder:Destroy()
        local i = table.find(self.ParentBox.Elements, self)
        if i then table.remove(self.ParentBox.Elements, i) end
        self.ParentBox:Resize()
    end

    el.Value = value
    RegisterOption(flag, el)
    table.insert(self.Elements, el)
    self:Resize()
    return el
end

GroupboxMeta.AddCheckbox = GroupboxMeta.AddToggle

----------------------------------------------------------------
-- ELEMENT: Slider
----------------------------------------------------------------
function GroupboxMeta:AddSlider(flag, info)
    info = Validate(info or {}, {
        Text = tostring(flag or "Slider"),
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
    })

    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 42),
        Parent = self.Content,
    })
    local title = New("TextLabel", {
        Text = info.Text,
        Size = UDim2.new(1, -50, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 13,
        Parent = holder,
    })
    local valueLabel = New("TextLabel", {
        Text = info.Prefix .. tostring(info.Default) .. info.Suffix,
        Size = UDim2.new(0, 48, 0, 18),
        Position = UDim2.new(1, -48, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextSize = 13,
        TextColor3 = "SubText",
        Parent = holder,
    })

    local track = New("Frame", {
        BackgroundColor3 = "Element",
        Position = UDim2.fromOffset(0, 24),
        Size = UDim2.new(1, 0, 0, 8),
        Parent = holder,
    })
    AddCorner(track, 4)

    local fill = New("Frame", {
        BackgroundColor3 = "Accent",
        Size = UDim2.new(0, 0, 1, 0),
        Parent = track,
    })
    AddCorner(fill, 4)

    local knob = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "Text",
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(14, 14),
        Parent = track,
    })
    AddCorner(knob, 7)

    local value = math.clamp(info.Default, info.Min, info.Max)
    local function updateVisual()
        local pct = (value - info.Min) / math.max(info.Max - info.Min, 1e-6)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valueLabel.Text = info.Prefix .. tostring(Round(value, info.Rounding)) .. info.Suffix
    end
    updateVisual()

    local dragging = false
    local maid = CreateMaid()

    local function setFromX(x)
        local abs = track.AbsolutePosition.X
        local size = track.AbsoluteSize.X
        local pct = math.clamp((x - abs) / math.max(size, 1), 0, 1)
        value = Round(info.Min + pct * (info.Max - info.Min), info.Rounding)
        updateVisual()
        if flag then Library.Flags[flag] = value end
        SafeCallback(info.Callback, value)
        SafeCallback(info.Changed, value)
    end

    maid:Connect(track.InputBegan, function(input)
        if info.Disabled then return end
        if IsClick(input) then
            dragging = true
            setFromX(input.Position.X)
        end
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
        Type = "Slider",
        Flag = flag,
        Holder = holder,
        Value = value,
        Visible = info.Visible,
        Disabled = info.Disabled,
        ParentBox = self,
        Maid = maid,
        Text = info.Text,
    }
    function el:SetValue(v, fire)
        value = math.clamp(Round(v, info.Rounding), info.Min, info.Max)
        self.Value = value
        updateVisual()
        if flag then Library.Flags[flag] = value end
        if fire ~= false then
            SafeCallback(info.Callback, value)
            SafeCallback(info.Changed, value)
        end
    end
    function el:GetValue() return value end
    function el:SetText(t)
        self.Text = t
        title.Text = t
    end
    function el:SetDisabled(d)
        self.Disabled = d
        info.Disabled = d
        title.TextTransparency = d and 0.5 or 0
    end
    function el:SetVisible(v)
        self.Visible = v ~= false
        ApplyElementVisibility(holder, self.Visible)
        self.ParentBox:Resize()
    end
    function el:Destroy()
        maid:Clean()
        UnregisterOption(flag)
        holder:Destroy()
        local i = table.find(self.ParentBox.Elements, self)
        if i then table.remove(self.ParentBox.Elements, i) end
        self.ParentBox:Resize()
    end

    RegisterOption(flag, el)
    table.insert(self.Elements, el)
    self:Resize()
    return el
end

----------------------------------------------------------------
-- ELEMENT: Input
----------------------------------------------------------------
function GroupboxMeta:AddInput(flag, info)
    info = Validate(info or {}, {
        Text = tostring(flag or "Input"),
        Default = "",
        Placeholder = "",
        Numeric = false,
        Finished = false,
        Callback = function() end,
        Changed = function() end,
        Disabled = false,
        Visible = true,
        ClearTextOnFocus = false,
    })

    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 48),
        Parent = self.Content,
    })
    local title = New("TextLabel", {
        Text = info.Text,
        Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 13,
        Parent = holder,
    })
    local box = New("TextBox", {
        BackgroundColor3 = "Element",
        Position = UDim2.fromOffset(0, 20),
        Size = UDim2.new(1, 0, 0, 26),
        Text = tostring(info.Default),
        PlaceholderText = info.Placeholder,
        ClearTextOnFocus = info.ClearTextOnFocus,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })
    AddCorner(box, 5)
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
        if fire ~= false then
            SafeCallback(info.Callback, value)
            SafeCallback(info.Changed, value)
        end
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
        Type = "Input",
        Flag = flag,
        Holder = holder,
        Value = value,
        Visible = info.Visible,
        Disabled = info.Disabled,
        ParentBox = self,
        Maid = maid,
        Text = info.Text,
    }
    function el:SetValue(v, fire)
        value = tostring(v)
        box.Text = value
        self.Value = value
        if flag then Library.Flags[flag] = value end
        if fire ~= false then
            SafeCallback(info.Callback, value)
            SafeCallback(info.Changed, value)
        end
    end
    function el:GetValue() return value end
    function el:SetText(t)
        self.Text = t
        title.Text = t
    end
    function el:SetDisabled(d)
        self.Disabled = d
        info.Disabled = d
        box.TextEditable = not d
        box.TextTransparency = d and 0.5 or 0
    end
    function el:SetVisible(v)
        self.Visible = v ~= false
        ApplyElementVisibility(holder, self.Visible)
        self.ParentBox:Resize()
    end
    function el:Destroy()
        maid:Clean()
        UnregisterOption(flag)
        holder:Destroy()
        local i = table.find(self.ParentBox.Elements, self)
        if i then table.remove(self.ParentBox.Elements, i) end
        self.ParentBox:Resize()
    end

    RegisterOption(flag, el)
    table.insert(self.Elements, el)
    self:Resize()
    return el
end

----------------------------------------------------------------
-- ELEMENT: Dropdown (single + multi)
----------------------------------------------------------------
function GroupboxMeta:AddDropdown(flag, info)
    info = Validate(info or {}, {
        Text = tostring(flag or "Dropdown"),
        Values = {},
        Default = nil,
        Multi = false,
        MaxVisibleDropdownItems = 6,
        Callback = function() end,
        Changed = function() end,
        Disabled = false,
        Visible = true,
    })

    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 48),
        Parent = self.Content,
    })
    local title = New("TextLabel", {
        Text = info.Text,
        Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 13,
        Parent = holder,
    })
    local trigger = New("TextButton", {
        BackgroundColor3 = "Element",
        Position = UDim2.fromOffset(0, 20),
        Size = UDim2.new(1, 0, 0, 26),
        Text = "",
        Parent = holder,
    })
    AddCorner(trigger, 5)
    AddStroke(trigger)

    local display = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = trigger,
    })
    local chevron = New("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        Text = "▾",
        TextSize = 12,
        TextColor3 = "SubText",
        Parent = trigger,
    })

    local values = {}
    for _, v in ipairs(info.Values) do
        table.insert(values, v)
    end

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
            for _, v in ipairs(values) do
                if selected[v] then table.insert(parts, tostring(v)) end
            end
            display.Text = #parts > 0 and table.concat(parts, ", ") or "None"
        else
            display.Text = selected ~= nil and tostring(selected) or "None"
        end
    end
    refreshDisplay()

    -- Dropdown menu (parented to ScreenGui to escape clipping)
    local menuOpen = false
    local menu = New("Frame", {
        BackgroundColor3 = "Surface",
        Visible = false,
        ZIndex = 200,
        Parent = ScreenGui,
    })
    AddCorner(menu, 6)
    AddStroke(menu)
    local menuScroll = New("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        Parent = menu,
    })
    AddPadding(menuScroll, 4, 4, 4, 4)
    local menuLayout = New("UIListLayout", {
        Padding = UDim.new(0, 2),
        Parent = menuScroll,
    })

    local function closeMenu()
        menuOpen = false
        menu.Visible = false
    end

    local function openMenu()
        if info.Disabled then return end
        menuOpen = true
        local abs = trigger.AbsolutePosition
        local size = trigger.AbsoluteSize
        local itemH = 26
        local visible = math.min(#values, info.MaxVisibleDropdownItems)
        local h = visible * (itemH + 2) + 8
        menu.Position = UDim2.fromOffset(abs.X, abs.Y + size.Y + 4)
        menu.Size = UDim2.fromOffset(size.X, h)
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
                Size = UDim2.new(1, 0, 0, 24),
                Text = "  " .. tostring(v),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 201,
                Parent = menuScroll,
            })
            AddCorner(item, 4)
            item.MouseButton1Click:Connect(function()
                if info.Multi then
                    selected[v] = not selected[v]
                    if flag then
                        local list = {}
                        for _, vv in ipairs(values) do
                            if selected[vv] then table.insert(list, vv) end
                        end
                        Library.Flags[flag] = list
                    end
                    SafeCallback(info.Callback, selected)
                    SafeCallback(info.Changed, selected)
                    rebuildMenu()
                    refreshDisplay()
                else
                    selected = v
                    if flag then Library.Flags[flag] = selected end
                    SafeCallback(info.Callback, selected)
                    SafeCallback(info.Changed, selected)
                    refreshDisplay()
                    closeMenu()
                end
            end)
        end
    end
    rebuildMenu()

    local maid = CreateMaid()
    maid:Connect(trigger.MouseButton1Click, function()
        if menuOpen then closeMenu() else openMenu() end
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
        Type = "Dropdown",
        Flag = flag,
        Holder = holder,
        Value = selected,
        Values = values,
        Multi = info.Multi,
        Visible = info.Visible,
        Disabled = info.Disabled,
        ParentBox = self,
        Maid = maid,
        Text = info.Text,
    }
    function el:SetValue(v, fire)
        if info.Multi then
            selected = {}
            if type(v) == "table" then
                for _, x in ipairs(v) do selected[x] = true end
            end
        else
            selected = v
        end
        self.Value = selected
        refreshDisplay()
        rebuildMenu()
        if flag then
            if info.Multi then
                local list = {}
                for _, vv in ipairs(values) do if selected[vv] then table.insert(list, vv) end end
                Library.Flags[flag] = list
            else
                Library.Flags[flag] = selected
            end
        end
        if fire ~= false then
            SafeCallback(info.Callback, selected)
            SafeCallback(info.Changed, selected)
        end
    end
    function el:GetValue() return selected end
    function el:SetValues(list)
        values = {}
        for _, v in ipairs(list or {}) do table.insert(values, v) end
        self.Values = values
        rebuildMenu()
        refreshDisplay()
    end
    function el:SetText(t)
        self.Text = t
        title.Text = t
    end
    function el:SetDisabled(d)
        self.Disabled = d
        info.Disabled = d
        trigger.TextTransparency = d and 0.5 or 0
        display.TextTransparency = d and 0.5 or 0
    end
    function el:SetVisible(v)
        self.Visible = v ~= false
        ApplyElementVisibility(holder, self.Visible)
        self.ParentBox:Resize()
    end
    function el:Destroy()
        closeMenu()
        maid:Clean()
        menu:Destroy()
        UnregisterOption(flag)
        holder:Destroy()
        local i = table.find(self.ParentBox.Elements, self)
        if i then table.remove(self.ParentBox.Elements, i) end
        self.ParentBox:Resize()
    end

    -- Init flag
    if flag then
        if info.Multi then
            local list = {}
            for _, vv in ipairs(values) do if selected[vv] then table.insert(list, vv) end end
            Library.Flags[flag] = list
        else
            Library.Flags[flag] = selected
        end
    end
    RegisterOption(flag, el)
    table.insert(self.Elements, el)
    self:Resize()
    return el
end

function GroupboxMeta:AddMultiDropdown(flag, info)
    info = info or {}
    info.Multi = true
    return self:AddDropdown(flag, info)
end

----------------------------------------------------------------
-- ELEMENT: KeyPicker (simplified)
----------------------------------------------------------------
function GroupboxMeta:AddKeyPicker(flag, info)
    info = Validate(info or {}, {
        Text = tostring(flag or "Key"),
        Default = "None",
        Mode = "Toggle", -- Always / Toggle / Hold
        Callback = function() end,
        Changed = function() end,
        Disabled = false,
        Visible = true,
    })

    local holder = CreateElementShell(self.Content, 28)
    local label = New("TextLabel", {
        Text = info.Text,
        Size = UDim2.new(1, -80, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })
    local keyBtn = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(72, 22),
        BackgroundColor3 = "Element",
        Text = tostring(info.Default),
        TextSize = 12,
        Parent = holder,
    })
    AddCorner(keyBtn, 4)
    AddStroke(keyBtn)

    local key = info.Default
    local listening = false
    local maid = CreateMaid()

    maid:Connect(keyBtn.MouseButton1Click, function()
        if info.Disabled then return end
        listening = true
        keyBtn.Text = "..."
    end)

    maid:Connect(Services.UserInputService.InputBegan, function(input, gp)
        if not listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            key = input.KeyCode.Name
            keyBtn.Text = key
            listening = false
            if flag then Library.Flags[flag] = key end
            SafeCallback(info.Changed, key)
        elseif input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2 then
            key = input.UserInputType.Name
            keyBtn.Text = key
            listening = false
            if flag then Library.Flags[flag] = key end
            SafeCallback(info.Changed, key)
        end
    end)

    -- Simple activation for Toggle/Hold modes is left to consumer via Flags

    local el = {
        Type = "KeyPicker",
        Flag = flag,
        Holder = holder,
        Value = key,
        Visible = info.Visible,
        Disabled = info.Disabled,
        ParentBox = self,
        Maid = maid,
        Text = info.Text,
    }
    function el:SetValue(v)
        key = tostring(v)
        self.Value = key
        keyBtn.Text = key
        if flag then Library.Flags[flag] = key end
    end
    function el:GetValue() return key end
    function el:SetText(t)
        self.Text = t
        label.Text = t
    end
    function el:SetDisabled(d)
        self.Disabled = d
        info.Disabled = d
    end
    function el:SetVisible(v)
        self.Visible = v ~= false
        ApplyElementVisibility(holder, self.Visible)
        self.ParentBox:Resize()
    end
    function el:Destroy()
        maid:Clean()
        UnregisterOption(flag)
        holder:Destroy()
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

----------------------------------------------------------------
-- ELEMENT: ColorPicker (simplified)
----------------------------------------------------------------
function GroupboxMeta:AddColorPicker(flag, info)
    info = Validate(info or {}, {
        Text = tostring(flag or "Color"),
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function() end,
        Changed = function() end,
        Disabled = false,
        Visible = true,
    })

    local holder = CreateElementShell(self.Content, 28)
    local label = New("TextLabel", {
        Text = info.Text,
        Size = UDim2.new(1, -36, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })
    local swatch = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(28, 20),
        BackgroundColor3 = info.Default,
        Text = "",
        Parent = holder,
    })
    AddCorner(swatch, 4)
    AddStroke(swatch)

    local value = info.Default
    -- Simple cycle for demo; full HSV picker would be larger
    local presets = {
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(110, 90, 255),
        Color3.fromRGB(70, 200, 120),
        Color3.fromRGB(230, 70, 70),
        Color3.fromRGB(240, 180, 50),
        Color3.fromRGB(50, 150, 255),
        Color3.fromRGB(0, 0, 0),
    }
    local idx = 1
    for i, c in ipairs(presets) do
        if c == value then idx = i break end
    end

    local maid = CreateMaid()
    maid:Connect(swatch.MouseButton1Click, function()
        if info.Disabled then return end
        idx = (idx % #presets) + 1
        value = presets[idx]
        swatch.BackgroundColor3 = value
        if flag then Library.Flags[flag] = value end
        SafeCallback(info.Callback, value)
        SafeCallback(info.Changed, value)
    end)

    local el = {
        Type = "ColorPicker",
        Flag = flag,
        Holder = holder,
        Value = value,
        Visible = info.Visible,
        Disabled = info.Disabled,
        ParentBox = self,
        Maid = maid,
        Text = info.Text,
    }
    function el:SetValue(c, fire)
        value = c
        self.Value = value
        swatch.BackgroundColor3 = value
        if flag then Library.Flags[flag] = value end
        if fire ~= false then
            SafeCallback(info.Callback, value)
            SafeCallback(info.Changed, value)
        end
    end
    function el:GetValue() return value end
    function el:SetText(t)
        self.Text = t
        label.Text = t
    end
    function el:SetDisabled(d)
        self.Disabled = d
        info.Disabled = d
    end
    function el:SetVisible(v)
        self.Visible = v ~= false
        ApplyElementVisibility(holder, self.Visible)
        self.ParentBox:Resize()
    end
    function el:Destroy()
        maid:Clean()
        UnregisterOption(flag)
        holder:Destroy()
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

----------------------------------------------------------------
-- ELEMENT: Paragraph
----------------------------------------------------------------
function GroupboxMeta:AddParagraph(flagOrText, info)
    local text
    if type(flagOrText) == "table" then
        info = flagOrText
        text = info.Text or ""
    else
        text = tostring(flagOrText)
        info = info or {}
    end
    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self.Content,
    })
    local label = New("TextLabel", {
        Text = text,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextColor3 = "SubText",
        TextSize = 13,
        Parent = holder,
    })
    local el = {
        Type = "Paragraph",
        Holder = holder,
        Text = text,
        Visible = true,
        ParentBox = self,
    }
    function el:SetText(t)
        self.Text = t
        label.Text = t
        self.ParentBox:Resize()
    end
    function el:SetVisible(v)
        self.Visible = v ~= false
        ApplyElementVisibility(holder, self.Visible)
        self.ParentBox:Resize()
    end
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

----------------------------------------------------------------
-- Dependency Groupbox (nested, no own scroller)
----------------------------------------------------------------
function GroupboxMeta:AddDependencyGroupbox(info)
    info = info or {}
    local deps = info.Dependencies or {}

    local depHolder = New("Frame", {
        BackgroundColor3 = "Element",
        BackgroundTransparency = 0.4,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.Content,
    })
    AddCorner(depHolder, 5)
    AddPadding(depHolder, 6, 6, 6, 6)
    local depLayout = New("UIListLayout", {
        Padding = UDim.new(0, 4),
        Parent = depHolder,
    })

    local depBox = setmetatable({
        Content = depHolder,
        Layout = depLayout,
        Elements = {},
        Holder = depHolder,
        Collapsed = false,
        Visible = false,
        Column = self.Column,
        ParentBox = self,
        Maid = CreateMaid(),
        _destroyed = false,
    }, GroupboxMeta)

    local function evaluate()
        local show = true
        for _, d in ipairs(deps) do
            local opt, expected = d[1], d[2]
            if type(opt) == "table" and opt.GetValue then
                if opt:GetValue() ~= expected then
                    show = false
                    break
                end
            elseif type(opt) == "table" and opt.Value ~= nil then
                if opt.Value ~= expected then
                    show = false
                    break
                end
            end
        end
        depBox.Visible = show
        depHolder.Visible = show
        self:Resize()
    end

    -- Hook dependency changes
    for _, d in ipairs(deps) do
        local opt = d[1]
        if type(opt) == "table" then
            local oldChanged = opt.Changed or function() end
            -- We rely on the option already calling its Changed; also poll via SetValue wrappers if present
            if opt.Type == "Toggle" or opt.Type == "Checkbox" then
                local orig = info.Callback
            end
        end
    end

    -- Re-evaluate when parent resizes / periodically safe
    task.spawn(function()
        while not depBox._destroyed do
            evaluate()
            task.wait(0.15)
        end
    end)

    function depBox:Resize()
        -- AutomaticSize handles height; just bubble
        if self.ParentBox then
            self.ParentBox:Resize()
        end
    end

    table.insert(self.Elements, depBox)
    self:Resize()
    return depBox
end

----------------------------------------------------------------
-- Create Groupbox UI
----------------------------------------------------------------
local function CreateGroupbox(column, name, opts)
    opts = opts or {}
    local holder = New("Frame", {
        BackgroundColor3 = "Surface",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = column.Container,
    })
    AddCorner(holder, Library.CornerRadius)
    AddStroke(holder)

    -- Header
    local header = New("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Text = "",
        Parent = holder,
    })
    local titleLabel = New("TextLabel", {
        Text = name or "Group",
        Size = UDim2.new(1, -28, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        Parent = header,
    })
    local chevron = New("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        Text = "▾",
        TextSize = 12,
        TextColor3 = "SubText",
        Parent = header,
    })

    -- Content (NO ScrollingFrame)
    local content = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 32),
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        Parent = holder,
    })
    AddPadding(content, 4, 10, 8, 10)
    local layout = New("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = content,
    })

    local box = setmetatable({
        Name = name,
        Holder = holder,
        Header = header,
        TitleLabel = titleLabel,
        Chevron = chevron,
        Content = content,
        Layout = layout,
        Elements = {},
        Collapsed = false,
        Visible = true,
        Column = column,
        Maid = CreateMaid(),
        _destroyed = false,
        _heightTween = nil,
    }, GroupboxMeta)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if not box.Collapsed then
            box:Resize()
        end
    end)

    box.Maid:Connect(header.MouseButton1Click, function()
        box:ToggleCollapse()
    end)

    -- Initial size
    task.defer(function()
        box:Resize()
    end)

    table.insert(column.Groupboxes, box)
    return box
end

----------------------------------------------------------------
-- COLUMN
----------------------------------------------------------------
local ColumnMeta = {}
ColumnMeta.__index = ColumnMeta

function ColumnMeta:UpdateHeight()
    -- Parent ScrollingFrame uses AutomaticCanvasSize; force a layout pass
    if self.Tab and self.Tab.Scroll then
        -- AbsoluteContentSize updates automatically with AutomaticCanvasSize
        -- Nothing extra required; keep for future manual calc
    end
end

function ColumnMeta:AddGroupbox(name, opts)
    return CreateGroupbox(self, name, opts)
end

----------------------------------------------------------------
-- TAB
----------------------------------------------------------------
local TabMeta = {}
TabMeta.__index = TabMeta

function TabMeta:Show()
    if Library.ActiveTab == self then return end
    if Library.ActiveTab then
        Library.ActiveTab:Hide()
    end
    self.Canvas.Visible = true
    if Library.Animations.Tabs then
        self.Canvas.GroupTransparency = 1
        Services.TweenService:Create(self.Canvas, Library.TabTweenInfo, { GroupTransparency = 0 }):Play()
    else
        self.Canvas.GroupTransparency = 0
    end
    if self.Button then
        self.Button.BackgroundTransparency = 0
        if self.ButtonLabel then
            self.ButtonLabel.TextTransparency = 0
        end
    end
    Library.ActiveTab = self
    if Library.Searching then
        Library:UpdateSearch(Library.SearchText)
    end
end

function TabMeta:Hide()
    if Library.Animations.Tabs then
        local t = Services.TweenService:Create(self.Canvas, Library.TabTweenInfo, { GroupTransparency = 1 })
        t:Play()
        t.Completed:Connect(function()
            if Library.ActiveTab ~= self then
                self.Canvas.Visible = false
            end
        end)
    else
        self.Canvas.Visible = false
        self.Canvas.GroupTransparency = 1
    end
    if self.Button then
        self.Button.BackgroundTransparency = 1
        if self.ButtonLabel then
            self.ButtonLabel.TextTransparency = 0.45
        end
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
    if side == "right" then
        return self:AddRightGroupbox(name, info)
    end
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
    if Library.ActiveTab == self then
        Library.ActiveTab = nil
    end
end

----------------------------------------------------------------
-- WINDOW
----------------------------------------------------------------
function Library:CreateWindow(info)
    info = Validate(info or {}, {
        Title = "Aether",
        Footer = "",
        Size = UDim2.fromOffset(720, 520),
        Position = nil,
        Center = true,
        Resizable = true,
        ToggleKeybind = Enum.KeyCode.RightControl,
        Searchbar = true,
        GlobalSearch = false,
        StackColumnsOnMobile = true,
        MinSidebarWidth = 140,
        SidebarWidth = 160,
        CornerRadius = 8,
        AutoShow = true,
    })

    Library.ToggleKeybind = info.ToggleKeybind or Library.ToggleKeybind
    Library.GlobalSearch = info.GlobalSearch
    Library.CornerRadius = info.CornerRadius or Library.CornerRadius

    local windowMaid = CreateMaid()

    -- Main frame
    local main = New("Frame", {
        Name = "Main",
        BackgroundColor3 = "Background",
        Size = info.Size,
        Position = info.Position or UDim2.fromOffset(80, 80),
        ClipsDescendants = true,
        Visible = false,
        Parent = ScreenGui,
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
        BackgroundColor3 = "Surface",
        Size = UDim2.new(1, 0, 0, 42),
        Parent = main,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, info.CornerRadius),
        Parent = topBar,
    })
    -- cover bottom corners of topBar
    New("Frame", {
        BackgroundColor3 = "Surface",
        Position = UDim2.new(0, 0, 1, -10),
        Size = UDim2.new(1, 0, 0, 10),
        BorderSizePixel = 0,
        Parent = topBar,
    })

    local titleLabel = New("TextLabel", {
        Text = info.Title,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.fromOffset(14, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topBar,
    })

    -- Close / minimize style buttons (simple)
    local closeBtn = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(24, 24),
        BackgroundColor3 = "Element",
        Text = "×",
        TextSize = 16,
        Parent = topBar,
    })
    AddCorner(closeBtn, 4)

    Library:MakeDraggable(main, topBar)

    if info.Resizable then
        local grip = New("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.fromScale(1, 1),
            Size = UDim2.fromOffset(16, 16),
            BackgroundTransparency = 1,
            Parent = main,
        })
        local gripVisual = New("Frame", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.fromScale(1, 1),
            Size = UDim2.fromOffset(10, 10),
            BackgroundColor3 = "Border",
            Parent = grip,
        })
        AddCorner(gripVisual, 2)
        Library:MakeResizable(main, grip, function()
            -- optional: notify tabs
        end)
    end

    -- Sidebar
    local sidebarWidth = info.SidebarWidth
    local sidebar = New("Frame", {
        BackgroundColor3 = "Surface",
        Position = UDim2.fromOffset(0, 42),
        Size = UDim2.new(0, sidebarWidth, 1, -42),
        Parent = main,
    })
    local sideLayout = New("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = sidebar,
    })
    AddPadding(sidebar, 8, 8, 8, 8)

    -- Divider
    local divider = New("Frame", {
        BackgroundColor3 = "Border",
        Position = UDim2.new(0, sidebarWidth, 0, 42),
        Size = UDim2.new(0, 1, 1, -42),
        Parent = main,
    })

    -- Content area
    local contentHost = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, sidebarWidth + 1, 0, 42),
        Size = UDim2.new(1, -(sidebarWidth + 1), 1, -42),
        ClipsDescendants = true,
        Parent = main,
    })

    -- Search bar (optional)
    local searchBox
    if info.Searchbar then
        local searchHolder = New("Frame", {
            BackgroundColor3 = "Element",
            Size = UDim2.new(1, 0, 0, 30),
            Parent = sidebar,
        })
        AddCorner(searchHolder, 5)
        AddStroke(searchHolder)
        searchBox = New("TextBox", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            PlaceholderText = "Search...",
            Text = "",
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = searchHolder,
        })
        AddPadding(searchBox, 0, 8, 0, 8)
        windowMaid:Connect(searchBox:GetPropertyChangedSignal("Text"), function()
            Library:UpdateSearch(searchBox.Text)
        end)
    end

    local Window = {
        Main = main,
        Sidebar = sidebar,
        ContentHost = contentHost,
        Tabs = {},
        Title = info.Title,
        Info = info,
        Maid = windowMaid,
        StackColumnsOnMobile = info.StackColumnsOnMobile,
    }

    function Window:AddTab(tabInfo)
        if type(tabInfo) == "string" then
            tabInfo = { Name = tabInfo }
        end
        tabInfo = Validate(tabInfo or {}, {
            Name = "Tab",
            Icon = nil,
        })

        local name = tabInfo.Name

        -- Sidebar button
        local tabBtn = New("TextButton", {
            BackgroundColor3 = "Element",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 32),
            Text = "",
            Parent = sidebar,
        })
        AddCorner(tabBtn, 5)
        local tabLabel = New("TextLabel", {
            Text = name,
            Size = UDim2.fromScale(1, 1),
            Position = UDim2.fromOffset(10, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 0.45,
            Parent = tabBtn,
        })

        -- Canvas (CanvasGroup for fade)
        local canvas = New("CanvasGroup", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Visible = false,
            GroupTransparency = 1,
            Parent = contentHost,
        })

        -- ★ SINGLE ScrollingFrame for the entire Tab ★
        local scroll = New("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.new(),
            Parent = canvas,
        })
        AddPadding(scroll, 10, 10, 10, 10)

        -- Columns container (horizontal list)
        local columnsFrame = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = scroll,
        })
        local columnsLayout = New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = columnsFrame,
        })

        local function isStacked()
            if Library.IsMobile and Window.StackColumnsOnMobile then
                return true
            end
            -- also stack when window is narrow
            return main.AbsoluteSize.X < 560
        end

        local function applyColumnLayout()
            local stacked = isStacked()
            columnsLayout.FillDirection = stacked and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
            if stacked then
                leftColFrame.Size = UDim2.new(1, 0, 0, 0)
                rightColFrame.Size = UDim2.new(1, 0, 0, 0)
            else
                leftColFrame.Size = UDim2.new(0.5, -5, 0, 0)
                rightColFrame.Size = UDim2.new(0.5, -5, 0, 0)
            end
        end

        -- Left column
        local leftColFrame = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            Parent = columnsFrame,
        })
        local leftLayout = New("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = leftColFrame,
        })

        -- Right column
        local rightColFrame = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0.5, -5, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
            Parent = columnsFrame,
        })
        local rightLayout = New("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = rightColFrame,
        })

        local leftColumn = setmetatable({
            Container = leftColFrame,
            Layout = leftLayout,
            Groupboxes = {},
            Side = "Left",
            Tab = nil,
        }, ColumnMeta)

        local rightColumn = setmetatable({
            Container = rightColFrame,
            Layout = rightLayout,
            Groupboxes = {},
            Side = "Right",
            Tab = nil,
        }, ColumnMeta)

        local tab = setmetatable({
            Name = name,
            Button = tabBtn,
            ButtonLabel = tabLabel,
            Canvas = canvas,
            Scroll = scroll,
            ColumnsFrame = columnsFrame,
            LeftColumn = leftColumn,
            RightColumn = rightColumn,
            Maid = CreateMaid(),
            _destroyed = false,
        }, TabMeta)

        leftColumn.Tab = tab
        rightColumn.Tab = tab

        applyColumnLayout()
        windowMaid:Connect(main:GetPropertyChangedSignal("AbsoluteSize"), applyColumnLayout)

        tab.Maid:Connect(tabBtn.MouseButton1Click, function()
            tab:Show()
        end)
        tab.Maid:Connect(tabBtn.MouseEnter, function()
            if Library.ActiveTab ~= tab then
                tabLabel.TextTransparency = 0.2
            end
        end)
        tab.Maid:Connect(tabBtn.MouseLeave, function()
            if Library.ActiveTab ~= tab then
                tabLabel.TextTransparency = 0.45
            end
        end)

        Window.Tabs[name] = tab
        Library.Tabs[name] = tab

        if not Library.ActiveTab then
            tab:Show()
        end

        return tab
    end

    function Window:Toggle(value)
        if typeof(value) == "boolean" then
            Library.Toggled = value
        else
            Library.Toggled = not Library.Toggled
        end
        if Library.Animations.Window then
            if Library.Toggled then
                main.Visible = true
                main.BackgroundTransparency = 1
                Services.TweenService:Create(main, Library.WindowTweenInfo, { BackgroundTransparency = 0 }):Play()
            else
                local t = Services.TweenService:Create(main, Library.WindowTweenInfo, { BackgroundTransparency = 1 })
                t:Play()
                t.Completed:Connect(function()
                    if not Library.Toggled then
                        main.Visible = false
                    end
                end)
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

    windowMaid:Connect(closeBtn.MouseButton1Click, function()
        Window:Toggle(false)
    end)

    Library.Window = Window
    Library.Toggle = function(_, v) return Window:Toggle(v) end

    -- Toggle keybind
    Library:GiveSignal(Services.UserInputService.InputBegan:Connect(function(input, gp)
        if Library.Unloaded then return end
        if Services.UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == Library.ToggleKeybind then
            Window:Toggle()
        end
    end))

    Library:GiveSignal(Services.UserInputService.WindowFocused:Connect(function()
        Library.IsRobloxFocused = true
    end))
    Library:GiveSignal(Services.UserInputService.WindowFocusReleased:Connect(function()
        Library.IsRobloxFocused = false
    end))

    if info.AutoShow then
        task.defer(function()
            Window:Toggle(true)
        end)
    end

    return Window
end

----------------------------------------------------------------
-- SEARCH
----------------------------------------------------------------
local function MatchText(text, search)
    if not text or search == "" then return true end
    return string.find(string.lower(tostring(text)), search, 1, true) ~= nil
end

local function ApplySearchToGroupbox(box, search)
    local visibleCount = 0
    for _, el in ipairs(box.Elements) do
        if el.Type == "Divider" then
            el.Holder.Visible = false
        elseif el.Type == "Label" or el.Type == "Paragraph" then
            local show = MatchText(el.Text, search) and el.Visible ~= false
            el.Holder.Visible = show
            if show then visibleCount += 1 end
        elseif el.Elements then
            -- nested dependency box
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
        if el.Elements then
            ResetGroupbox(el)
        elseif el.Holder then
            el.Holder.Visible = el.Visible ~= false
        end
    end
    if box.Holder then
        box.Holder.Visible = box.Visible ~= false
    end
    box:Resize()
end

function Library:UpdateSearch(text)
    Library.SearchText = text or ""
    local search = string.lower(Trim(Library.SearchText))

    local tabsToProcess = {}
    if Library.GlobalSearch then
        for _, t in pairs(Library.Tabs) do
            table.insert(tabsToProcess, t)
        end
    elseif Library.ActiveTab then
        table.insert(tabsToProcess, Library.ActiveTab)
    end

    if search == "" then
        Library.Searching = false
        for _, tab in ipairs(tabsToProcess) do
            for _, col in ipairs({ tab.LeftColumn, tab.RightColumn }) do
                if col then
                    for _, g in ipairs(col.Groupboxes) do
                        ResetGroupbox(g)
                    end
                end
            end
        end
        return
    end

    Library.Searching = true
    for _, tab in ipairs(tabsToProcess) do
        for _, col in ipairs({ tab.LeftColumn, tab.RightColumn }) do
            if col then
                for _, g in ipairs(col.Groupboxes) do
                    ApplySearchToGroupbox(g, search)
                end
            end
        end
    end
end

----------------------------------------------------------------
-- UNLOAD
----------------------------------------------------------------
function Library:Unload()
    Library.Unloaded = true

    for i = #Library.Signals, 1, -1 do
        local c = table.remove(Library.Signals, i)
        if c and c.Connected then
            pcall(function() c:Disconnect() end)
        end
    end

    for i = #Library.UnloadSignals, 1, -1 do
        local cb = table.remove(Library.UnloadSignals, i)
        SafeCallback(cb)
    end

    if Library.Window and Library.Window.Destroy then
        Library.Window:Destroy()
    end

    if ScreenGui then
        ScreenGui:Destroy()
    end

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

----------------------------------------------------------------
-- Export
----------------------------------------------------------------
getgenv().Aether = Library
getgenv().Library = Library -- convenience alias

return Library
