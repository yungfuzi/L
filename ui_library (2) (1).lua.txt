--// Obsidian-like UI Library
--// Full executor compat. Mobile support. Theme registry. DPI. Animations.

local Library = {}
getgenv().Library = Library

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")

-- Executor compat
local cloneref = cloneref or function(o) return o end
local gethui = gethui or function() return CoreGui end
local protectgui = protectgui or function() end
local getcustomasset = getcustomasset or nil
local isfolder = isfolder or function() return false end
local makefolder = makefolder or function() end
local writefile = writefile or function() end
local readfile = readfile or function() end
local isfile = isfile or function() return false end

-- GUI parent
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = HttpService:GenerateGUID(false)
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
protectgui(ScreenGui)
ScreenGui.Parent = gethui()
Library.ScreenGui = ScreenGui

-- Z-index tiers (all are top-level children of ScreenGui, so these
-- values alone decide stacking regardless of creation order):
--   Windows            = 1
--   Overlay (popups)   = 30   (dropdown lists, color pickers)
--   Notifications      = 60
--   Dialogs (modal)    = 100
local Overlay = Instance.new("Frame")
Overlay.Name = "Overlay"
Overlay.BackgroundTransparency = 1
Overlay.Size = UDim2.fromScale(1, 1)
Overlay.ZIndex = 30
Overlay.Parent = ScreenGui
Library.Overlay = Overlay

-- Templates
Library.Templates = {
    Window = { Title = "Obsidian", Size = UDim2.fromOffset(560, 420), Center = true, AutoShow = true },
    Toggle = { Default = false, Risky = false, Description = nil, Callback = function() end },
    Slider = { Default = 0, Min = 0, Max = 100, Rounding = 0, Prefix = "", Suffix = "", Description = nil, Callback = function() end },
    Dropdown = { Default = nil, Multi = false, Search = false, Description = nil, Callback = function() end },
    Input = { Default = "", Numeric = false, Finished = false, ClearTextOnFocus = false, Description = nil, Callback = function() end },
    ColorPicker = { Default = Color3.fromRGB(255,255,255), Transparency = 0, Description = nil, Callback = function() end },
    KeyPicker = { Default = "None", Mode = "Toggle", Description = nil, Callback = function() end, Modes = {"Always","Toggle","Hold","Press"} },
    Notification = { Title = "Notification", Content = "", Duration = 5 },
    Dialog = { Title = "Dialog", Content = "", Buttons = {} },
}

-- Theme
Library.Scheme = {
    Background = Color3.fromRGB(14, 14, 14),
    Accent = Color3.fromRGB(105, 160, 240),
    Outline = Color3.fromRGB(34, 34, 34),
    Inline = Color3.fromRGB(22, 22, 22),
    FontColor = Color3.fromRGB(230, 230, 230),
    DimmedFont = Color3.fromRGB(140, 140, 140),
    Risky = Color3.fromRGB(240, 100, 100),
    GroupBackground = Color3.fromRGB(18, 18, 18),
}

Library.Registry = {}
Library.DPIRegistry = {}
Library.Connections = {}
Library.Animations = true
Library.ToggleKey = Enum.KeyCode.RightShift
Library.IsMobile = UserInputService.TouchEnabled

-- Utility
local function Connect(obj, signal, callback)
    local conn = signal:Connect(callback)
    obj.Connections = obj.Connections or {}
    table.insert(obj.Connections, conn)
    table.insert(Library.Connections, conn)
    return conn
end

local function AddToRegistry(instance, props)
    Library.Registry[instance] = props
    for prop, key in pairs(props) do
        if typeof(key) == "string" then
            instance[prop] = Library.Scheme[key]
        end
    end
end

function Library:UpdateRegistry()
    for inst, props in pairs(self.Registry) do
        if inst and inst.Parent then
            for prop, key in pairs(props) do
                if typeof(key) == "string" then
                    inst[prop] = self.Scheme[key]
                end
            end
        end
    end
end

local function Tween(instance, info, props)
    if not Library.Animations then
        for k,v in pairs(props) do instance[k] = v end
        return
    end
    TweenService:Create(instance, info, props):Play()
end

local function GetTextSize(text, size, font)
    return TextService:GetTextSize(text, size, font, Vector2.new(9999, 9999))
end

-- Native UIShadow (engine class, wrapped in pcall for older executors/clients)
local function AddShadow(parent, transparency, blur, offsetY)
    local ok, shadow = pcall(function()
        local Shadow = Instance.new("UIShadow")
        Shadow.Color = Color3.new(0, 0, 0)
        Shadow.Transparency = transparency or 0.55
        Shadow.BlurRadius = UDim.new(0, blur or 14)
        Shadow.Offset = UDim2.new(0, 0, 0, offsetY or 3)
        Shadow.Parent = parent
        return Shadow
    end)
    return ok and shadow or nil
end

-- Small dimmed caption placed under an element's main label
local function AddDescription(parent, yOffset, text)
    local Desc = Instance.new("TextLabel")
    Desc.Size = UDim2.new(1, 0, 0, 14)
    Desc.Position = UDim2.new(0, 0, 0, yOffset)
    Desc.BackgroundTransparency = 1
    Desc.Text = text
    Desc.TextColor3 = Library.Scheme.DimmedFont
    Desc.Font = Enum.Font.Gotham
    Desc.TextSize = 11
    Desc.TextWrapped = true
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.TextYAlignment = Enum.TextYAlignment.Top
    Desc.Parent = parent
    AddToRegistry(Desc, {TextColor3 = "DimmedFont"})
    return Desc
end

-- Icons
Library.Icons = {
    ["loader"] = "rbxassetid://10709782600",
    ["check"] = "rbxassetid://10709782223",
    ["chevron-down"] = "rbxassetid://10709782371",
    ["x"] = "rbxassetid://10709783367",
    ["search"] = "rbxassetid://10709783021",
}
function Library:GetIcon(name)
    if string.find(name, "rbxassetid://") then return name end
    return self.Icons[name] or ""
end

-- Notifications
do
    local NotifContainer = Instance.new("Frame")
    NotifContainer.Size = UDim2.new(0, 260, 1, -20)
    NotifContainer.Position = UDim2.new(1, -270, 0, 10)
    NotifContainer.BackgroundTransparency = 1
    NotifContainer.ZIndex = 60
    NotifContainer.Parent = ScreenGui
    
    local NotifList = Instance.new("UIListLayout")
    NotifList.SortOrder = Enum.SortOrder.LayoutOrder
    NotifList.Padding = UDim.new(0, 6)
    NotifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotifList.Parent = NotifContainer
    
    function Library:Notify(info)
        info = setmetatable(info or {}, {__index = self.Templates.Notification})
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(1, 0, 0, 60)
        Frame.BackgroundColor3 = self.Scheme.Background
        Frame.BorderSizePixel = 0
        Frame.Parent = NotifContainer
        AddToRegistry(Frame, {BackgroundColor3 = "Background"})
        AddShadow(Frame, 0.5, 10)
        
        local Stroke = Instance.new("UIStroke")
        Stroke.Color = self.Scheme.Outline
        Stroke.Thickness = 1
        Stroke.Parent = Frame
        AddToRegistry(Stroke, {Color = "Outline"})
        
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 0)
        Corner.Parent = Frame
        
        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -12, 0, 18)
        Title.Position = UDim2.new(0, 6, 0, 4)
        Title.BackgroundTransparency = 1
        Title.Text = info.Title
        Title.TextColor3 = self.Scheme.FontColor
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 14
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Parent = Frame
        AddToRegistry(Title, {TextColor3 = "FontColor"})
        
        local Content = Instance.new("TextLabel")
        Content.Size = UDim2.new(1, -12, 0, 32)
        Content.Position = UDim2.new(0, 6, 0, 22)
        Content.BackgroundTransparency = 1
        Content.Text = info.Content
        Content.TextColor3 = self.Scheme.DimmedFont
        Content.Font = Enum.Font.Gotham
        Content.TextSize = 12
        Content.TextWrapped = true
        Content.TextXAlignment = Enum.TextXAlignment.Left
        Content.TextYAlignment = Enum.TextYAlignment.Top
        Content.Parent = Frame
        AddToRegistry(Content, {TextColor3 = "DimmedFont"})
        
        Tween(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0,0,0,0)})
        
        task.delay(info.Duration, function()
            if Frame and Frame.Parent then
                Tween(Frame, TweenInfo.new(0.3), {Position = UDim2.new(1, 20, 0, 0)})
                task.wait(0.35)
                Frame:Destroy()
            end
        end)
    end
end

-- Loading Screen
function Library:ShowLoading(text)
    local Frame = Instance.new("Frame")
    Frame.Name = "Loading"
    Frame.Size = UDim2.fromOffset(200, 80)
    Frame.Position = UDim2.fromScale(0.5, 0.5)
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.BackgroundColor3 = self.Scheme.Background
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui
    AddToRegistry(Frame, {BackgroundColor3 = "Background"})
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 0)
    Corner.Parent = Frame
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = self.Scheme.Outline
    Stroke.Thickness = 1
    Stroke.Parent = Frame
    AddToRegistry(Stroke, {Color = "Outline"})
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text or "Loading..."
    Label.TextColor3 = self.Scheme.FontColor
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 14
    Label.Parent = Frame
    AddToRegistry(Label, {TextColor3 = "FontColor"})
    
    return Frame
end

-- Dialog
function Library:CreateDialog(info)
    info = setmetatable(info or {}, {__index = self.Templates.Dialog})
    
    local DialogLayer = Instance.new("Frame")
    DialogLayer.Size = UDim2.fromScale(1, 1)
    DialogLayer.BackgroundColor3 = Color3.new(0,0,0)
    DialogLayer.BackgroundTransparency = 0.5
    DialogLayer.ZIndex = 100
    DialogLayer.Parent = ScreenGui
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.fromOffset(300, 160)
    Frame.Position = UDim2.fromScale(0.5, 0.5)
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.BackgroundColor3 = self.Scheme.Background
    Frame.BorderSizePixel = 0
    Frame.ZIndex = 101
    Frame.Parent = DialogLayer
    AddToRegistry(Frame, {BackgroundColor3 = "Background"})
    AddShadow(Frame, 0.45, 16)
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 0)
    Corner.Parent = Frame
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = self.Scheme.Outline
    Stroke.Thickness = 1
    Stroke.Parent = Frame
    AddToRegistry(Stroke, {Color = "Outline"})
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 24)
    Title.Position = UDim2.new(0, 10, 0, 8)
    Title.BackgroundTransparency = 1
    Title.Text = info.Title
    Title.TextColor3 = self.Scheme.FontColor
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame
    AddToRegistry(Title, {TextColor3 = "FontColor"})
    
    local Content = Instance.new("TextLabel")
    Content.Size = UDim2.new(1, -20, 0, 60)
    Content.Position = UDim2.new(0, 10, 0, 36)
    Content.BackgroundTransparency = 1
    Content.Text = info.Content
    Content.TextColor3 = self.Scheme.DimmedFont
    Content.Font = Enum.Font.Gotham
    Content.TextSize = 13
    Content.TextWrapped = true
    Content.TextXAlignment = Enum.TextXAlignment.Left
    Content.TextYAlignment = Enum.TextYAlignment.Top
    Content.Parent = Frame
    AddToRegistry(Content, {TextColor3 = "DimmedFont"})
    
    local BtnContainer = Instance.new("Frame")
    BtnContainer.Size = UDim2.new(1, -20, 0, 32)
    BtnContainer.Position = UDim2.new(0, 10, 1, -42)
    BtnContainer.BackgroundTransparency = 1
    BtnContainer.Parent = Frame
    
    local BtnList = Instance.new("UIListLayout")
    BtnList.FillDirection = Enum.FillDirection.Horizontal
    BtnList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    BtnList.Padding = UDim.new(0, 8)
    BtnList.Parent = BtnContainer
    
    for _, btnInfo in ipairs(info.Buttons or {}) do
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(0, 80, 1, 0)
        Btn.BackgroundColor3 = self.Scheme.Inline
        Btn.Text = btnInfo.Text or "OK"
        Btn.TextColor3 = self.Scheme.FontColor
        Btn.Font = Enum.Font.GothamBold
        Btn.TextSize = 13
        Btn.AutoButtonColor = false
        Btn.Parent = BtnContainer
        AddToRegistry(Btn, {BackgroundColor3 = "Inline", TextColor3 = "FontColor"})
        
        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 0)
        BtnCorner.Parent = Btn
        
        Connect(Btn, Btn.MouseEnter, function()
            Tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = self.Scheme.Accent})
        end)
        Connect(Btn, Btn.MouseLeave, function()
            Tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = self.Scheme.Inline})
        end)
        Connect(Btn, Btn.MouseButton1Click, function()
            if btnInfo.Callback then btnInfo.Callback() end
            DialogLayer:Destroy()
        end)
    end
    
    return DialogLayer
end

-- Groupbox factory
local function CreateGroupbox(Tab, Parent, info)
    local Groupbox = {Connections = {}, Elements = {}}
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 40)
    Frame.BackgroundColor3 = Library.Scheme.GroupBackground
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = Parent
    AddToRegistry(Frame, {BackgroundColor3 = "GroupBackground"})
    AddShadow(Frame, 0.65, 6)
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Library.Scheme.Outline
    Stroke.Thickness = 1
    Stroke.Parent = Frame
    AddToRegistry(Stroke, {Color = "Outline"})
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 0)
    Corner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -12, 0, 20)
    Label.Position = UDim2.new(0, 6, 0, 4)
    Label.BackgroundTransparency = 1
    Label.Text = info.Name or "Groupbox"
    Label.TextColor3 = Library.Scheme.FontColor
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    AddToRegistry(Label, {TextColor3 = "FontColor"})
    
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -12, 1, -28)
    Container.Position = UDim2.new(0, 6, 0, 24)
    Container.BackgroundTransparency = 1
    Container.Parent = Frame
    
    local List = Instance.new("UIListLayout")
    List.SortOrder = Enum.SortOrder.LayoutOrder
    List.Padding = UDim.new(0, 6)
    List.Parent = Container
    
    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, 4)
    Padding.PaddingBottom = UDim.new(0, 4)
    Padding.Parent = Container
    
    Connect(Groupbox, List:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        local h = List.AbsoluteContentSize.Y + 36
        Tween(Frame, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, h)})
    end)
    
    -- DependencyBox
    function Groupbox:AddDependencyBox()
        local DepBox = {Predicate = function() return true end}
        local oldAdd = {}
        for k,v in pairs(Groupbox) do
            if typeof(v) == "function" and k ~= "AddDependencyBox" and k ~= "SetVisibility" then
                oldAdd[k] = v
                Groupbox[k] = function(self, info)
                    local elem = oldAdd[k](self, info)
                    table.insert(DepBox, elem)
                    elem.Holder.Visible = DepBox.Predicate()
                    return elem
                end
            end
        end
        function DepBox:Setup(predicate)
            self.Predicate = predicate
            for _, elem in ipairs(self) do
                elem.Holder.Visible = predicate()
            end
        end
        return DepBox
    end
    
    -- Toggle
    function Groupbox:AddToggle(info)
        info = setmetatable(info or {}, {__index = Library.Templates.Toggle})
        local Toggle = {Value = info.Default, Connections = {}, Type = "Toggle"}
        
        local rowHeight = 20
        local totalHeight = info.Description and (rowHeight + 14) or rowHeight
        
        local Holder = Instance.new("Frame")
        Holder.Size = UDim2.new(1, 0, 0, totalHeight)
        Holder.BackgroundTransparency = 1
        Holder.Parent = Container
        
        local Box = Instance.new("Frame")
        Box.Size = UDim2.fromOffset(16, 16)
        Box.Position = UDim2.new(0, 0, 0, rowHeight / 2 - 8)
        Box.BackgroundColor3 = Library.Scheme.Inline
        Box.BorderSizePixel = 0
        Box.Parent = Holder
        AddToRegistry(Box, {BackgroundColor3 = "Inline"})
        
        local BoxCorner = Instance.new("UICorner")
        BoxCorner.CornerRadius = UDim.new(0, 0)
        BoxCorner.Parent = Box
        
        local BoxStroke = Instance.new("UIStroke")
        BoxStroke.Color = Library.Scheme.Outline
        BoxStroke.Thickness = 1
        BoxStroke.Parent = Box
        AddToRegistry(BoxStroke, {Color = "Outline"})
        
        local Check = Instance.new("Frame")
        Check.Size = UDim2.fromOffset(10, 10)
        Check.Position = UDim2.new(0.5, -5, 0.5, -5)
        Check.BackgroundColor3 = Library.Scheme.Accent
        Check.BorderSizePixel = 0
        Check.Visible = Toggle.Value
        Check.Parent = Box
        AddToRegistry(Check, {BackgroundColor3 = "Accent"})
        
        local CheckCorner = Instance.new("UICorner")
        CheckCorner.CornerRadius = UDim.new(0, 0)
        CheckCorner.Parent = Check
        
        local Text = Instance.new("TextLabel")
        Text.Size = UDim2.new(1, -24, 0, rowHeight)
        Text.Position = UDim2.new(0, 22, 0, 0)
        Text.BackgroundTransparency = 1
        Text.Text = info.Text or "Toggle"
        Text.TextColor3 = info.Risky and Library.Scheme.Risky or Library.Scheme.FontColor
        Text.Font = Enum.Font.Gotham
        Text.TextSize = 13
        Text.TextXAlignment = Enum.TextXAlignment.Left
        Text.Parent = Holder
        if info.Risky then AddToRegistry(Text, {TextColor3 = "Risky"})
        else AddToRegistry(Text, {TextColor3 = "FontColor"}) end
        
        if info.Description then
            AddDescription(Holder, rowHeight, info.Description)
        end
        
        local Click = Instance.new("TextButton")
        Click.Size = UDim2.new(1, 0, 0, rowHeight)
        Click.BackgroundTransparency = 1
        Click.Text = ""
        Click.Parent = Holder
        
        function Toggle:Set(val)
            self.Value = val
            Check.Visible = val
            if info.Callback then info.Callback(val) end
        end
        function Toggle:Destroy()
            for _,c in ipairs(self.Connections) do c:Disconnect() end
            Holder:Destroy()
        end
        
        Connect(Toggle, Click.MouseButton1Click, function()
            Toggle:Set(not Toggle.Value)
        end)
        
        Toggle.Holder = Holder
        table.insert(Groupbox.Elements, Toggle)
        table.insert(Tab.Elements, Toggle)
        return Toggle
    end
    
    -- Button
    function Groupbox:AddButton(info)
        info = setmetatable(info or {}, {__index = {Text = "Button", Description = nil, Callback = function() end}})
        local Button = {Connections = {}, Type = "Button"}
        
        local rowHeight = 26
        local totalHeight = info.Description and (rowHeight + 14) or rowHeight
        
        local Holder = Instance.new("Frame")
        Holder.Size = UDim2.new(1, 0, 0, totalHeight)
        Holder.BackgroundTransparency = 1
        Holder.Parent = Container
        
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(1, 0, 0, rowHeight)
        Btn.BackgroundColor3 = Library.Scheme.Inline
        Btn.Text = info.Text
        Btn.TextColor3 = Library.Scheme.FontColor
        Btn.Font = Enum.Font.Gotham
        Btn.TextSize = 13
        Btn.AutoButtonColor = false
        Btn.Parent = Holder
        AddToRegistry(Btn, {BackgroundColor3 = "Inline", TextColor3 = "FontColor"})
        
        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 0)
        BtnCorner.Parent = Btn
        
        local BtnStroke = Instance.new("UIStroke")
        BtnStroke.Color = Library.Scheme.Outline
        BtnStroke.Thickness = 1
        BtnStroke.Parent = Btn
        AddToRegistry(BtnStroke, {Color = "Outline"})
        
        Connect(Button, Btn.MouseEnter, function()
            Tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Library.Scheme.Accent})
        end)
        Connect(Button, Btn.MouseLeave, function()
            Tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = Library.Scheme.Inline})
        end)
        Connect(Button, Btn.MouseButton1Click, function()
            if info.Callback then info.Callback() end
        end)
        
        if info.Description then
            AddDescription(Holder, rowHeight, info.Description)
        end
        
        Button.Holder = Holder
        table.insert(Groupbox.Elements, Button)
        table.insert(Tab.Elements, Button)
        return Button
    end
    
    -- Slider
    function Groupbox:AddSlider(info)
        info = setmetatable(info or {}, {__index = Library.Templates.Slider})
        local Slider = {Value = info.Default, Connections = {}, Type = "Slider"}
        
        local descOffset = info.Description and 14 or 0
        
        local Holder = Instance.new("Frame")
        Holder.Size = UDim2.new(1, 0, 0, 36 + descOffset)
        Holder.BackgroundTransparency = 1
        Holder.Parent = Container
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 0, 16)
        Label.BackgroundTransparency = 1
        Label.Text = info.Text or "Slider"
        Label.TextColor3 = Library.Scheme.FontColor
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Holder
        AddToRegistry(Label, {TextColor3 = "FontColor"})
        
        local ValueLabel = Instance.new("TextLabel")
        ValueLabel.Size = UDim2.new(0, 50, 0, 16)
        ValueLabel.Position = UDim2.new(1, -50, 0, 0)
        ValueLabel.BackgroundTransparency = 1
        ValueLabel.Text = tostring(info.Default)
        ValueLabel.TextColor3 = Library.Scheme.DimmedFont
        ValueLabel.Font = Enum.Font.Gotham
        ValueLabel.TextSize = 13
        ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
        ValueLabel.Parent = Holder
        AddToRegistry(ValueLabel, {TextColor3 = "DimmedFont"})
        
        if info.Description then
            AddDescription(Holder, 16, info.Description)
        end
        
        local Track = Instance.new("Frame")
        Track.Size = UDim2.new(1, 0, 0, 6)
        Track.Position = UDim2.new(0, 0, 0, 22 + descOffset)
        Track.BackgroundColor3 = Library.Scheme.Inline
        Track.BorderSizePixel = 0
        Track.Parent = Holder
        AddToRegistry(Track, {BackgroundColor3 = "Inline"})
        
        local TrackCorner = Instance.new("UICorner")
        TrackCorner.CornerRadius = UDim.new(0, 0)
        TrackCorner.Parent = Track
        
        local Fill = Instance.new("Frame")
        Fill.Size = UDim2.new(0, 0, 1, 0)
        Fill.BackgroundColor3 = Library.Scheme.Accent
        Fill.BorderSizePixel = 0
        Fill.Parent = Track
        AddToRegistry(Fill, {BackgroundColor3 = "Accent"})
        
        local FillCorner = Instance.new("UICorner")
        FillCorner.CornerRadius = UDim.new(0, 0)
        FillCorner.Parent = Fill
        
        local function Update(input)
            local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
            local val = info.Min + (info.Max - info.Min) * pos
            if info.Rounding and info.Rounding > 0 then
                val = math.floor(val * (10^info.Rounding) + 0.5) / (10^info.Rounding)
            else
                val = math.floor(val + 0.5)
            end
            Slider.Value = val
            Fill.Size = UDim2.new(pos, 0, 1, 0)
            ValueLabel.Text = info.Prefix .. tostring(val) .. info.Suffix
            if info.Callback then info.Callback(val) end
        end
        
        local dragging = false
        Connect(Slider, Track.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                Update(input)
            end
        end)
        Connect(Slider, UserInputService.InputChanged, function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                Update(input)
            end
        end)
        Connect(Slider, UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        
        function Slider:Set(val)
            val = math.clamp(val, info.Min, info.Max)
            if info.Rounding and info.Rounding > 0 then
                val = math.floor(val * (10^info.Rounding) + 0.5) / (10^info.Rounding)
            else
                val = math.floor(val + 0.5)
            end
            self.Value = val
            local pos = (val - info.Min) / (info.Max - info.Min)
            Fill.Size = UDim2.new(pos, 0, 1, 0)
            ValueLabel.Text = info.Prefix .. tostring(val) .. info.Suffix
            if info.Callback then info.Callback(val) end
        end
        
        Slider.Holder = Holder
        table.insert(Groupbox.Elements, Slider)
        table.insert(Tab.Elements, Slider)
        return Slider
    end
    
    -- Dropdown
    function Groupbox:AddDropdown(info)
        info = setmetatable(info or {}, {__index = Library.Templates.Dropdown})
        local Dropdown = {Value = info.Multi and {} or (info.Default or nil), Connections = {}, Type = "Dropdown", Options = info.Values or {}}
        
        local rowHeight = 26
        local descOffset = info.Description and 14 or 0
        
        local Holder = Instance.new("Frame")
        Holder.Size = UDim2.new(1, 0, 0, rowHeight + descOffset)
        Holder.BackgroundTransparency = 1
        Holder.Parent = Container
        
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(1, 0, 0, rowHeight)
        Btn.BackgroundColor3 = Library.Scheme.Inline
        Btn.Text = ""
        Btn.AutoButtonColor = false
        Btn.Parent = Holder
        AddToRegistry(Btn, {BackgroundColor3 = "Inline"})
        
        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 0)
        BtnCorner.Parent = Btn
        
        local BtnStroke = Instance.new("UIStroke")
        BtnStroke.Color = Library.Scheme.Outline
        BtnStroke.Thickness = 1
        BtnStroke.Parent = Btn
        AddToRegistry(BtnStroke, {Color = "Outline"})
        
        local Text = Instance.new("TextLabel")
        Text.Size = UDim2.new(1, -30, 1, 0)
        Text.Position = UDim2.new(0, 8, 0, 0)
        Text.BackgroundTransparency = 1
        Text.Text = info.Text or "Dropdown"
        Text.TextColor3 = Library.Scheme.FontColor
        Text.Font = Enum.Font.Gotham
        Text.TextSize = 13
        Text.TextXAlignment = Enum.TextXAlignment.Left
        Text.Parent = Btn
        AddToRegistry(Text, {TextColor3 = "FontColor"})
        
        local Icon = Instance.new("ImageLabel")
        Icon.Size = UDim2.fromOffset(16, 16)
        Icon.Position = UDim2.new(1, -22, 0.5, -8)
        Icon.BackgroundTransparency = 1
        Icon.Image = Library:GetIcon("chevron-down")
        Icon.ImageColor3 = Library.Scheme.DimmedFont
        Icon.Parent = Btn
        AddToRegistry(Icon, {ImageColor3 = "DimmedFont"})
        
        if info.Description then
            AddDescription(Holder, rowHeight, info.Description)
        end
        
        -- Popup list lives in the Overlay layer (not nested under Btn) so its
        -- ZIndex always wins against other windows/groupboxes, regardless of
        -- how deep the dropdown itself is nested.
        local ListFrame = Instance.new("Frame")
        ListFrame.Size = UDim2.new(0, 0, 0, 0)
        ListFrame.BackgroundColor3 = Library.Scheme.Background
        ListFrame.BorderSizePixel = 0
        ListFrame.ClipsDescendants = true
        ListFrame.Visible = false
        ListFrame.ZIndex = 2
        ListFrame.Parent = Library.Overlay
        AddToRegistry(ListFrame, {BackgroundColor3 = "Background"})
        AddShadow(ListFrame, 0.5, 10)
        
        local ListCorner = Instance.new("UICorner")
        ListCorner.CornerRadius = UDim.new(0, 0)
        ListCorner.Parent = ListFrame
        
        local ListStroke = Instance.new("UIStroke")
        ListStroke.Color = Library.Scheme.Outline
        ListStroke.Thickness = 1
        ListStroke.Parent = ListFrame
        AddToRegistry(ListStroke, {Color = "Outline"})
        
        local function RepositionList()
            ListFrame.Position = UDim2.fromOffset(Btn.AbsolutePosition.X, Btn.AbsolutePosition.Y + Btn.AbsoluteSize.Y + 4)
        end
        Connect(Dropdown, Btn:GetPropertyChangedSignal("AbsolutePosition"), RepositionList)
        Connect(Dropdown, Btn:GetPropertyChangedSignal("AbsoluteSize"), RepositionList)
        RepositionList()
        
        local Scroll = Instance.new("ScrollingFrame")
        Scroll.Size = UDim2.new(1, -8, 1, -8)
        Scroll.Position = UDim2.new(0, 4, 0, 4)
        Scroll.BackgroundTransparency = 1
        Scroll.ScrollBarThickness = 2
        Scroll.ScrollBarImageColor3 = Library.Scheme.Outline
        Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Scroll.Parent = ListFrame
        AddToRegistry(Scroll, {ScrollBarImageColor3 = "Outline"})
        
        local ScrollList = Instance.new("UIListLayout")
        ScrollList.SortOrder = Enum.SortOrder.LayoutOrder
        ScrollList.Padding = UDim.new(0, 2)
        ScrollList.Parent = Scroll
        
        local SearchBox
        if info.Search then
            SearchBox = Instance.new("TextBox")
            SearchBox.Size = UDim2.new(1, -8, 0, 22)
            SearchBox.Position = UDim2.new(0, 4, 0, 4)
            SearchBox.BackgroundColor3 = Library.Scheme.Inline
            SearchBox.Text = ""
            SearchBox.PlaceholderText = "Search..."
            SearchBox.TextColor3 = Library.Scheme.FontColor
            SearchBox.Font = Enum.Font.Gotham
            SearchBox.TextSize = 12
            SearchBox.Parent = ListFrame
            AddToRegistry(SearchBox, {BackgroundColor3 = "Inline", TextColor3 = "FontColor"})
            
            local SearchCorner = Instance.new("UICorner")
            SearchCorner.CornerRadius = UDim.new(0, 0)
            SearchCorner.Parent = SearchBox
            
            Scroll.Position = UDim2.new(0, 4, 0, 30)
            Scroll.Size = UDim2.new(1, -8, 1, -34)
        end
        
        local open = false
        local function Build()
            for _, child in ipairs(Scroll:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            
            local values = Dropdown.Options
            if info.SpecialType == "Player" then
                values = {}
                for _, plr in ipairs(Players:GetPlayers()) do table.insert(values, plr.Name) end
            elseif info.SpecialType == "Team" then
                values = {}
                for _, team in ipairs(game.Teams:GetTeams()) do table.insert(values, team.Name) end
            end
            
            local filter = SearchBox and string.lower(SearchBox.Text) or ""
            for _, val in ipairs(values) do
                if filter == "" or string.find(string.lower(tostring(val)), filter) then
                    local Opt = Instance.new("TextButton")
                    Opt.Size = UDim2.new(1, 0, 0, 22)
                    Opt.BackgroundTransparency = 1
                    Opt.Text = "  " .. tostring(val)
                    Opt.TextColor3 = Library.Scheme.FontColor
                    Opt.Font = Enum.Font.Gotham
                    Opt.TextSize = 12
                    Opt.TextXAlignment = Enum.TextXAlignment.Left
                    Opt.Parent = Scroll
                    AddToRegistry(Opt, {TextColor3 = "FontColor"})
                    
                    if info.Multi and Dropdown.Value[val] then
                        Opt.BackgroundColor3 = Library.Scheme.Accent
                        Opt.BackgroundTransparency = 0.8
                    elseif not info.Multi and Dropdown.Value == val then
                        Opt.BackgroundColor3 = Library.Scheme.Accent
                        Opt.BackgroundTransparency = 0.8
                    end
                    
                    Connect(Dropdown, Opt.MouseButton1Click, function()
                        if info.Multi then
                            Dropdown.Value[val] = not Dropdown.Value[val]
                        else
                            Dropdown.Value = val
                            open = false
                            Tween(ListFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, Btn.AbsoluteSize.X, 0, 0)})
                            ListFrame.Visible = false
                            Icon.Rotation = 0
                        end
                        if info.Callback then
                            info.Callback(Dropdown.Value)
                        end
                        Build()
                    end)
                end
            end
        end
        
        Connect(Dropdown, Btn.MouseButton1Click, function()
            open = not open
            if open then
                Build()
                RepositionList()
                ListFrame.Size = UDim2.new(0, Btn.AbsoluteSize.X, 0, 0)
                ListFrame.Visible = true
                Tween(ListFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, Btn.AbsoluteSize.X, 0, math.min(150, ScrollList.AbsoluteContentSize.Y + (SearchBox and 34 or 8)))})
                Icon.Rotation = 180
            else
                Tween(ListFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, Btn.AbsoluteSize.X, 0, 0)})
                task.wait(0.2)
                ListFrame.Visible = false
                Icon.Rotation = 0
            end
        end)
        
        if SearchBox then
            Connect(Dropdown, SearchBox:GetPropertyChangedSignal("Text"), function()
                if open then Build() end
            end)
        end
        
        if info.SpecialType == "Player" then
            Connect(Dropdown, Players.PlayerAdded, function() if open then Build() end end)
            Connect(Dropdown, Players.PlayerRemoving, function() if open then Build() end end)
        end
        
        function Dropdown:Set(val)
            self.Value = val
            if info.Callback then info.Callback(val) end
        end
        function Dropdown:Destroy()
            for _,c in ipairs(self.Connections) do c:Disconnect() end
            ListFrame:Destroy()
            Holder:Destroy()
        end
        
        Dropdown.Holder = Holder
        table.insert(Groupbox.Elements, Dropdown)
        table.insert(Tab.Elements, Dropdown)
        return Dropdown
    end
    
    -- Input
    function Groupbox:AddInput(info)
        info = setmetatable(info or {}, {__index = Library.Templates.Input})
        local Input = {Value = info.Default, Connections = {}, Type = "Input"}
        
        local descOffset = info.Description and 14 or 0
        
        local Holder = Instance.new("Frame")
        Holder.Size = UDim2.new(1, 0, 0, 44 + descOffset)
        Holder.BackgroundTransparency = 1
        Holder.Parent = Container
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 0, 16)
        Label.BackgroundTransparency = 1
        Label.Text = info.Text or "Input"
        Label.TextColor3 = Library.Scheme.FontColor
        Label.Font = Enum.Font.Gotham
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Holder
        AddToRegistry(Label, {TextColor3 = "FontColor"})
        
        if info.Description then
            AddDescription(Holder, 16, info.Description)
        end
        
        local Box = Instance.new("TextBox")
        Box.Size = UDim2.new(1, 0, 0, 24)
        Box.Position = UDim2.new(0, 0, 0, 18 + descOffset)
        Box.BackgroundColor3 = Library.Scheme.Inline
        Box.Text = tostring(info.Default)
        Box.PlaceholderText = info.Placeholder or ""
        Box.TextColor3 = Library.Scheme.FontColor
        Box.Font = Enum.Font.Gotham
        Box.TextSize = 12
        Box.ClearTextOnFocus = info.ClearTextOnFocus
        Box.Parent = Holder
        AddToRegistry(Box, {BackgroundColor3 = "Inline", TextColor3 = "FontColor"})
        
        local BoxCorner = Instance.new("UICorner")
        BoxCorner.CornerRadius = UDim.new(0, 0)
        BoxCorner.Parent = Box
        
        local BoxStroke = Instance.new("UIStroke")
        BoxStroke.Color = Library.Scheme.Outline
        BoxStroke.Thickness = 1
        BoxStroke.Parent = Box
        AddToRegistry(BoxStroke, {Color = "Outline"})
        
        local function Fire()
            local txt = Box.Text
            if info.Numeric then
                txt = tonumber(txt) or 0
            end
            Input.Value = txt
            if info.Callback then info.Callback(txt) end
        end
        
        if info.Finished then
            Connect(Input, Box.FocusLost, function() Fire() end)
        else
            Connect(Input, Box:GetPropertyChangedSignal("Text"), function()
                if info.Numeric and Box.Text ~= "" and not tonumber(Box.Text) then
                    Box.Text = Box.Text:sub(1, -2)
                    return
                end
                Fire()
            end)
        end
        
        function Input:Set(val)
            self.Value = val
            Box.Text = tostring(val)
            if info.Callback then info.Callback(val) end
        end
        
        Input.Holder = Holder
        table.insert(Groupbox.Elements, Input)
        table.insert(Tab.Elements, Input)
        return Input
    end
    
    -- Label
    function Groupbox:AddLabel(info)
        info = typeof(info) == "string" and {Text = info} or (info or {})
        local Label = {Connections = {}, Type = "Label"}
        
        local Holder = Instance.new("Frame")
        Holder.Size = UDim2.new(1, 0, 0, 18)
        Holder.BackgroundTransparency = 1
        Holder.Parent = Container
        
        local Text = Instance.new("TextLabel")
        Text.Size = UDim2.new(1, 0, 1, 0)
        Text.BackgroundTransparency = 1
        Text.Text = info.Text or ""
        Text.TextColor3 = Library.Scheme.DimmedFont
        Text.Font = Enum.Font.Gotham
        Text.TextSize = 12
        Text.TextWrapped = true
        Text.TextXAlignment = Enum.TextXAlignment.Left
        Text.Parent = Holder
        AddToRegistry(Text, {TextColor3 = "DimmedFont"})
        
        function Label:SetText(txt)
            Text.Text = txt
            local bounds = GetTextSize(txt, Text.TextSize, Text.Font)
            Holder.Size = UDim2.new(1, 0, 0, math.max(18, bounds.Y))
        end
        
        Label.Holder = Holder
        Label.Text = Text
        table.insert(Groupbox.Elements, Label)
        table.insert(Tab.Elements, Label)
        return Label
    end
    
    -- ColorPicker
    function Groupbox:AddColorPicker(info)
        info = setmetatable(info or {}, {__index = Library.Templates.ColorPicker})
        local Picker = {Value = info.Default, Transparency = info.Transparency, Connections = {}, Type = "ColorPicker"}
        
        local Holder = Instance.new("Frame")
        Holder.Size = UDim2.new(1, 0, 0, 20)
        Holder.BackgroundTransparency = 1
        Holder.Parent = Container
        
        local Text = Instance.new("TextLabel")
        Text.Size = UDim2.new(1, -30, 1, 0)
        Text.BackgroundTransparency = 1
        Text.Text = info.Text or "Color"
        Text.TextColor3 = Library.Scheme.FontColor
        Text.Font = Enum.Font.Gotham
        Text.TextSize = 13
        Text.TextXAlignment = Enum.TextXAlignment.Left
        Text.Parent = Holder
        AddToRegistry(Text, {TextColor3 = "FontColor"})
        
        local Swatch = Instance.new("TextButton")
        Swatch.Size = UDim2.fromOffset(20, 20)
        Swatch.Position = UDim2.new(1, -20, 0, 0)
        Swatch.BackgroundColor3 = Picker.Value
        Swatch.Text = ""
        Swatch.AutoButtonColor = false
        Swatch.Parent = Holder
        
        local SwatchCorner = Instance.new("UICorner")
        SwatchCorner.CornerRadius = UDim.new(0, 0)
        SwatchCorner.Parent = Swatch
        
        local SwatchStroke = Instance.new("UIStroke")
        SwatchStroke.Color = Library.Scheme.Outline
        SwatchStroke.Thickness = 1
        SwatchStroke.Parent = Swatch
        AddToRegistry(SwatchStroke, {Color = "Outline"})
        
        -- Popup with hue/sat/val fields
        local Popup = Instance.new("Frame")
        Popup.Size = UDim2.fromOffset(180, 200)
        Popup.BackgroundColor3 = Library.Scheme.Background
        Popup.BorderSizePixel = 0
        Popup.Visible = false
        Popup.ZIndex = 50
        Popup.Parent = Holder
        AddToRegistry(Popup, {BackgroundColor3 = "Background"})
        
        local PopupCorner = Instance.new("UICorner")
        PopupCorner.CornerRadius = UDim.new(0, 0)
        PopupCorner.Parent = Popup
        
        local PopupStroke = Instance.new("UIStroke")
        PopupStroke.Color = Library.Scheme.Outline
        PopupStroke.Thickness = 1
        PopupStroke.Parent = Popup
        AddToRegistry(PopupStroke, {Color = "Outline"})
        
        local SatVal = Instance.new("ImageButton")
        SatVal.Size = UDim2.new(1, -16, 0, 120)
        SatVal.Position = UDim2.new(0, 8, 0, 8)
        SatVal.Image = "rbxassetid://4155801252"
        SatVal.ZIndex = 51
        SatVal.Parent = Popup
        
        local SatValCorner = Instance.new("UICorner")
        SatValCorner.CornerRadius = UDim.new(0, 0)
        SatValCorner.Parent = SatVal
        
        local h, s, v = Color3.toHSV(Picker.Value)
        SatVal.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        
        local Cursor = Instance.new("Frame")
        Cursor.Size = UDim2.fromOffset(6, 6)
        Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
        Cursor.Position = UDim2.new(s, 0, 1 - v, 0)
        Cursor.BackgroundColor3 = Color3.new(1,1,1)
        Cursor.BorderSizePixel = 0
        Cursor.ZIndex = 52
        Cursor.Parent = SatVal
        
        local CursorCorner = Instance.new("UICorner")
        CursorCorner.CornerRadius = UDim.new(1, 0)
        CursorCorner.Parent = Cursor
        
        local HueSlider = Instance.new("ImageButton")
        HueSlider.Size = UDim2.new(1, -16, 0, 16)
        HueSlider.Position = UDim2.new(0, 8, 0, 136)
        HueSlider.Image = "rbxassetid://3283211550"
        HueSlider.ZIndex = 51
        HueSlider.Parent = Popup
        
        local HueCorner = Instance.new("UICorner")
        HueCorner.CornerRadius = UDim.new(0, 0)
        HueCorner.Parent = HueSlider
        
        local HueCursor = Instance.new("Frame")
        HueCursor.Size = UDim2.new(0, 3, 1, 4)
        HueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
        HueCursor.Position = UDim2.new(h, 0, 0.5, 0)
        HueCursor.BackgroundColor3 = Color3.new(1,1,1)
        HueCursor.BorderSizePixel = 0
        HueCursor.ZIndex = 52
        HueCursor.Parent = HueSlider
        
        local function UpdateColor()
            Picker.Value = Color3.fromHSV(h, s, v)
            Swatch.BackgroundColor3 = Picker.Value
            SatVal.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            if info.Callback then info.Callback(Picker.Value, Picker.Transparency) end
        end
        
        local satDragging, hueDragging = false, false
        Connect(Picker, SatVal.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                satDragging = true
            end
        end)
        Connect(Picker, HueSlider.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                hueDragging = true
            end
        end)
        Connect(Picker, UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                satDragging, hueDragging = false, false
            end
        end)
        Connect(Picker, UserInputService.InputChanged, function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            if satDragging then
                local px = math.clamp((input.Position.X - SatVal.AbsolutePosition.X) / SatVal.AbsoluteSize.X, 0, 1)
                local py = math.clamp((input.Position.Y - SatVal.AbsolutePosition.Y) / SatVal.AbsoluteSize.Y, 0, 1)
                s, v = px, 1 - py
                Cursor.Position = UDim2.new(px, 0, py, 0)
                UpdateColor()
            elseif hueDragging then
                local px = math.clamp((input.Position.X - HueSlider.AbsolutePosition.X) / HueSlider.AbsoluteSize.X, 0, 1)
                h = px
                HueCursor.Position = UDim2.new(px, 0, 0.5, 0)
                UpdateColor()
            end
        end)
        
        Connect(Picker, Swatch.MouseButton1Click, function()
            Popup.Visible = not Popup.Visible
        end)
        
        function Picker:Set(color)
            self.Value = color
            h, s, v = Color3.toHSV(color)
            Cursor.Position = UDim2.new(s, 0, 1 - v, 0)
            HueCursor.Position = UDim2.new(h, 0, 0.5, 0)
            Swatch.BackgroundColor3 = color
            SatVal.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            if info.Callback then info.Callback(color, self.Transparency) end
        end
        
        Picker.Holder = Holder
        table.insert(Groupbox.Elements, Picker)
        table.insert(Tab.Elements, Picker)
        return Picker
    end
    
    -- KeyPicker
    function Groupbox:AddKeyPicker(info)
        info = setmetatable(info or {}, {__index = Library.Templates.KeyPicker})
        local Picker = {Value = info.Default, Mode = info.Mode, Connections = {}, Type = "KeyPicker", Toggled = false}
        
        local Holder = Instance.new("Frame")
        Holder.Size = UDim2.new(1, 0, 0, 20)
        Holder.BackgroundTransparency = 1
        Holder.Parent = Container
        
        local Text = Instance.new("TextLabel")
        Text.Size = UDim2.new(1, -80, 1, 0)
        Text.BackgroundTransparency = 1
        Text.Text = info.Text or "Keybind"
        Text.TextColor3 = Library.Scheme.FontColor
        Text.Font = Enum.Font.Gotham
        Text.TextSize = 13
        Text.TextXAlignment = Enum.TextXAlignment.Left
        Text.Parent = Holder
        AddToRegistry(Text, {TextColor3 = "FontColor"})
        
        local KeyBtn = Instance.new("TextButton")
        KeyBtn.Size = UDim2.fromOffset(70, 18)
        KeyBtn.Position = UDim2.new(1, -70, 0, 1)
        KeyBtn.BackgroundColor3 = Library.Scheme.Inline
        KeyBtn.Text = tostring(info.Default)
        KeyBtn.TextColor3 = Library.Scheme.FontColor
        KeyBtn.Font = Enum.Font.Gotham
        KeyBtn.TextSize = 12
        KeyBtn.AutoButtonColor = false
        KeyBtn.Parent = Holder
        AddToRegistry(KeyBtn, {BackgroundColor3 = "Inline", TextColor3 = "FontColor"})
        
        local KeyCorner = Instance.new("UICorner")
        KeyCorner.CornerRadius = UDim.new(0, 0)
        KeyCorner.Parent = KeyBtn
        
        local listening = false
        Connect(Picker, KeyBtn.MouseButton1Click, function()
            listening = true
            KeyBtn.Text = "..."
        end)
        
        Connect(Picker, UserInputService.InputBegan, function(input, gpe)
            if listening and (input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1) then
                listening = false
                Picker.Value = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name or "MouseButton1"
                KeyBtn.Text = Picker.Value
                return
            end
            if gpe or listening then return end
            
            local matches = (input.KeyCode and input.KeyCode.Name == Picker.Value) or (input.UserInputType.Name == Picker.Value)
            if not matches then return end
            
            if Picker.Mode == "Toggle" then
                Picker.Toggled = not Picker.Toggled
                if info.Callback then info.Callback(Picker.Toggled) end
            elseif Picker.Mode == "Hold" then
                Picker.Toggled = true
                if info.Callback then info.Callback(true) end
            elseif Picker.Mode == "Press" then
                if info.Callback then info.Callback(true) end
            end
        end)
        
        Connect(Picker, UserInputService.InputEnded, function(input)
            if Picker.Mode == "Hold" then
                local matches = (input.KeyCode and input.KeyCode.Name == Picker.Value) or (input.UserInputType.Name == Picker.Value)
                if matches then
                    Picker.Toggled = false
                    if info.Callback then info.Callback(false) end
                end
            end
        end)
        
        function Picker:Set(key)
            self.Value = key
            KeyBtn.Text = key
        end
        
        Picker.Holder = Holder
        table.insert(Groupbox.Elements, Picker)
        table.insert(Tab.Elements, Picker)
        return Picker
    end
    
    Groupbox.Frame = Frame
    return Groupbox
end

-- Tab factory
local function CreateTab(Window, TabButton, Page, info)
    local Tab = {Connections = {}, Elements = {}, Groupboxes = {}}
    
    function Tab:AddLeftGroupbox(gInfo)
        local gb = CreateGroupbox(Tab, Window.LeftColumn, gInfo)
        table.insert(Tab.Groupboxes, gb)
        return gb
    end
    function Tab:AddRightGroupbox(gInfo)
        local gb = CreateGroupbox(Tab, Window.RightColumn, gInfo)
        table.insert(Tab.Groupboxes, gb)
        return gb
    end
    
    Tab.Button = TabButton
    Tab.Page = Page
    return Tab
end

-- Window factory
function Library:CreateWindow(info)
    info = setmetatable(info or {}, {__index = self.Templates.Window})
    local Window = {Tabs = {}, Connections = {}}
    
    local Main = Instance.new("Frame")
    Main.Size = info.Size
    Main.Position = UDim2.fromScale(0.5, 0.5)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = self.Scheme.Background
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Visible = info.AutoShow
    Main.Parent = ScreenGui
    AddToRegistry(Main, {BackgroundColor3 = "Background"})
    AddShadow(Main, 0.4, 20)
    Window.Main = Main
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 0)
    MainCorner.Parent = Main
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = self.Scheme.Outline
    MainStroke.Thickness = 1
    MainStroke.Parent = Main
    AddToRegistry(MainStroke, {Color = "Outline"})
    
    -- Top bar
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 32)
    TopBar.BackgroundColor3 = self.Scheme.GroupBackground
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Main
    AddToRegistry(TopBar, {BackgroundColor3 = "GroupBackground"})
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -16, 1, 0)
    TitleLabel.Position = UDim2.new(0, 12, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = info.Title
    TitleLabel.TextColor3 = self.Scheme.FontColor
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar
    AddToRegistry(TitleLabel, {TextColor3 = "FontColor"})
    
    -- Drag
    do
        local dragging, dragStart, startPos = false, nil, nil
        Connect(Window, TopBar.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Main.Position
                local conn
                conn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        conn:Disconnect()
                    end
                end)
            end
        end)
        Connect(Window, UserInputService.InputChanged, function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end
    
    -- Tab bar
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1, -16, 0, 26)
    TabBar.Position = UDim2.new(0, 8, 0, 38)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent = Main
    
    local TabList = Instance.new("UIListLayout")
    TabList.FillDirection = Enum.FillDirection.Horizontal
    TabList.Padding = UDim.new(0, 4)
    TabList.Parent = TabBar
    
    -- Content area with 2 columns
    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -16, 1, -74)
    Content.Position = UDim2.new(0, 8, 0, 68)
    Content.BackgroundTransparency = 1
    Content.Parent = Main
    
    local LeftColumn = Instance.new("ScrollingFrame")
    LeftColumn.Size = UDim2.new(0.5, -4, 1, 0)
    LeftColumn.BackgroundTransparency = 1
    LeftColumn.ScrollBarThickness = 2
    LeftColumn.ScrollBarImageColor3 = self.Scheme.Outline
    LeftColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
    LeftColumn.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LeftColumn.Parent = Content
    AddToRegistry(LeftColumn, {ScrollBarImageColor3 = "Outline"})
    
    local LeftList = Instance.new("UIListLayout")
    LeftList.SortOrder = Enum.SortOrder.LayoutOrder
    LeftList.Padding = UDim.new(0, 6)
    LeftList.Parent = LeftColumn
    
    local RightColumn = Instance.new("ScrollingFrame")
    RightColumn.Size = UDim2.new(0.5, -4, 1, 0)
    RightColumn.Position = UDim2.new(0.5, 4, 0, 0)
    RightColumn.BackgroundTransparency = 1
    RightColumn.ScrollBarThickness = 2
    RightColumn.ScrollBarImageColor3 = self.Scheme.Outline
    RightColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
    RightColumn.AutomaticCanvasSize = Enum.AutomaticSize.Y
    RightColumn.Parent = Content
    AddToRegistry(RightColumn, {ScrollBarImageColor3 = "Outline"})
    
    local RightList = Instance.new("UIListLayout")
    RightList.SortOrder = Enum.SortOrder.LayoutOrder
    RightList.Padding = UDim.new(0, 6)
    RightList.Parent = RightColumn
    
    Window.LeftColumn = LeftColumn
    Window.RightColumn = RightColumn
    
    function Window:AddTab(name)
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.fromOffset(math.max(60, GetTextSize(name, 13, Enum.Font.GothamBold).X + 20), 26)
        TabButton.BackgroundColor3 = Library.Scheme.Inline
        TabButton.Text = name
        TabButton.TextColor3 = Library.Scheme.FontColor
        TabButton.Font = Enum.Font.GothamBold
        TabButton.TextSize = 13
        TabButton.AutoButtonColor = false
        TabButton.Parent = TabBar
        AddToRegistry(TabButton, {BackgroundColor3 = "Inline", TextColor3 = "FontColor"})
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 0)
        TabCorner.Parent = TabButton
        
        local Tab = CreateTab(self, TabButton, Content, {})
        
        Connect(Tab, TabButton.MouseButton1Click, function()
            for _, t in ipairs(self.Tabs) do
                Tween(t.Button, TweenInfo.new(0.15), {BackgroundColor3 = Library.Scheme.Inline})
            end
            Tween(TabButton, TweenInfo.new(0.15), {BackgroundColor3 = Library.Scheme.Accent})
            self.ActiveTab = Tab
        end)
        
        if #self.Tabs == 0 then
            Tween(TabButton, TweenInfo.new(0.01), {BackgroundColor3 = Library.Scheme.Accent})
            self.ActiveTab = Tab
        end
        
        table.insert(self.Tabs, Tab)
        return Tab
    end
    
    function Window:SetVisible(bool)
        Main.Visible = bool
    end
    function Window:Toggle()
        Main.Visible = not Main.Visible
    end
    
    Connect(Window, UserInputService.InputBegan, function(input, gpe)
        if gpe then return end
        if input.KeyCode == self.ToggleKey then
            Main.Visible = not Main.Visible
        end
    end)
    
    -- Mobile toggle button
    if self.IsMobile then
        local MobileBtn = Instance.new("TextButton")
        MobileBtn.Size = UDim2.fromOffset(44, 44)
        MobileBtn.Position = UDim2.new(0, 10, 0, 100)
        MobileBtn.BackgroundColor3 = self.Scheme.Accent
        MobileBtn.Text = "UI"
        MobileBtn.TextColor3 = Color3.new(1,1,1)
        MobileBtn.Font = Enum.Font.GothamBold
        MobileBtn.TextSize = 14
        MobileBtn.Parent = ScreenGui
        
        local MobileCorner = Instance.new("UICorner")
        MobileCorner.CornerRadius = UDim.new(1, 0)
        MobileCorner.Parent = MobileBtn
        
        Connect(Window, MobileBtn.MouseButton1Click, function()
            Window:Toggle()
        end)
    end
    
    table.insert(self.Registry, Window)
    return Window
end

-- Config save/load
function Library:SaveConfig(name)
    if not isfolder("Tze") then makefolder("Tze") end
    local data = {}
    for inst, elem in pairs(self.Registry) do
        -- placeholder for future per-element config serialization
    end
    writefile("Tze/" .. name .. ".json", HttpService:JSONEncode(data))
end

function Library:LoadConfig(name)
    local path = "Tze/" .. name .. ".json"
    if not isfile(path) then return false end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(path))
    if not ok then return false end
    return data
end

function Library:Destroy()
    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
    self.ScreenGui:Destroy()
end

return Library
