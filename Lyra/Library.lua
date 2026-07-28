local Library = {}
getgenv().Library = Library

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")

local cloneref = cloneref or function(o) return o end
local gethui = gethui or function() return CoreGui end
local protectgui = protectgui or function() end
local getcustomasset = getcustomasset or nil
local isfolder = isfolder or function() return false end
local makefolder = makefolder or function() end
local writefile = writefile or function() end
local readfile = readfile or function() end
local isfile = isfile or function() return false end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = HttpService:GenerateGUID(false)
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
protectgui(ScreenGui)
ScreenGui.Parent = gethui()
Library.ScreenGui = ScreenGui

local Overlay = Instance.new("Frame")
Overlay.Name = "Overlay"
Overlay.BackgroundTransparency = 1
Overlay.Size = UDim2.fromScale(1, 1)
Overlay.ZIndex = 30
Overlay.Parent = ScreenGui
Library.Overlay = Overlay

Library.Templates = {
    Window = { Title = "Lyra", Size = UDim2.fromOffset(560, 420), Center = true, AutoShow = true },
    Toggle = { Default = false, Risky = false, Description = nil, Callback = function() end },
    Slider = { Default = 0, Min = 0, Max = 100, Rounding = 0, Prefix = "", Suffix = "", Description = nil, Callback = function() end },
    Dropdown = { Default = nil, Multi = false, Search = false, Description = nil, Callback = function() end },
    Input = { Default = "", Numeric = false, Finished = false, ClearTextOnFocus = false, Description = nil, Callback = function() end },
    ColorPicker = { Default = Color3.fromRGB(255,255,255), Transparency = 0, Description = nil, Callback = function() end },
    KeyPicker = { Default = "None", Mode = "Toggle", Description = nil, Callback = function() end, Modes = {"Always","Toggle","Hold","Press"} },
    Button = { Text = "Button", Description = nil, Callback = function() end },
    Notification = { Title = "Notification", Content = "", Duration = 5 },
    Dialog = { Title = "Dialog", Content = "", Buttons = {} },
}

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
Library.Flags = {}
Library.Options = {}
Library.Animations = true
Library.ToggleKey = Enum.KeyCode.RightShift
Library.IsMobile = UserInputService.TouchEnabled
Library.Corner = UDim.new(0, 6)

local function SetFlag(flag, value)
    if not flag then return end
    Library.Flags[flag] = value
    if Library.Options[flag] then
        Library.Options[flag].Value = value
    end
end

local function RegisterOption(flag, element)
    if not flag then return end
    element.Flag = flag
    Library.Options[flag] = element
    Library.Flags[flag] = element.Value
end

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

local function AddCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or Library.Corner
    c.Parent = parent
    return c
end

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
        AddCorner(Frame)

        local Stroke = Instance.new("UIStroke")
        Stroke.Color = self.Scheme.Outline
        Stroke.Thickness = 1
        Stroke.Parent = Frame
        AddToRegistry(Stroke, {Color = "Outline"})

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
    AddCorner(Frame)

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

function Library:CreateDialog(info)
    info = setmetatable(info or {}, {__index = self.Templates.Dialog})

    local DialogLayer = Instance.new("Frame")
    DialogLayer.Size = UDim2.fromScale(1, 1)
    DialogLayer.BackgroundColor3 = Color3.new(0,0,0)
    DialogLayer.BackgroundTransparency = 0.5
    DialogLayer.ZIndex = 100
    DialogLayer.Parent = ScreenGui

    local Backdrop = Instance.new("TextButton")
    Backdrop.Size = UDim2.fromScale(1, 1)
    Backdrop.BackgroundTransparency = 1
    Backdrop.Text = ""
    Backdrop.ZIndex = 100
    Backdrop.Parent = DialogLayer

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
    AddCorner(Frame)

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
    Title.ZIndex = 102
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
    Content.ZIndex = 102
    Content.Parent = Frame
    AddToRegistry(Content, {TextColor3 = "DimmedFont"})

    local BtnContainer = Instance.new("Frame")
    BtnContainer.Size = UDim2.new(1, -20, 0, 32)
    BtnContainer.Position = UDim2.new(0, 10, 1, -42)
    BtnContainer.BackgroundTransparency = 1
    BtnContainer.ZIndex = 102
    BtnContainer.Parent = Frame

    local BtnList = Instance.new("UIListLayout")
    BtnList.FillDirection = Enum.FillDirection.Horizontal
    BtnList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    BtnList.Padding = UDim.new(0, 8)
    BtnList.Parent = BtnContainer

    local function CloseDialog()
        DialogLayer:Destroy()
    end

    Connect(DialogLayer, Backdrop.MouseButton1Click, CloseDialog)

    for _, btnInfo in ipairs(info.Buttons or {}) do
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(0, 80, 1, 0)
        Btn.BackgroundColor3 = self.Scheme.Inline
        Btn.Text = btnInfo.Text or "OK"
        Btn.TextColor3 = self.Scheme.FontColor
        Btn.Font = Enum.Font.GothamBold
        Btn.TextSize = 13
        Btn.AutoButtonColor = false
        Btn.ZIndex = 103
        Btn.Parent = BtnContainer
        AddToRegistry(Btn, {BackgroundColor3 = "Inline", TextColor3 = "FontColor"})
        AddCorner(Btn)

        Connect(Btn, Btn.MouseEnter, function()
            Tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = self.Scheme.Accent})
        end)
        Connect(Btn, Btn.MouseLeave, function()
            Tween(Btn, TweenInfo.new(0.15), {BackgroundColor3 = self.Scheme.Inline})
        end)
        Connect(Btn, Btn.MouseButton1Click, function()
            if btnInfo.Callback then btnInfo.Callback() end
            CloseDialog()
        end)
    end

    return DialogLayer
end

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
    AddCorner(Frame)

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Library.Scheme.Outline
    Stroke.Thickness = 1
    Stroke.Parent = Frame
    AddToRegistry(Stroke, {Color = "Outline"})

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

    function Groupbox:AddDependencyBox()
        local DepBox = {
            Predicate = function() return true end,
            Elements = {},
        }

        local methodNames = {
            "AddToggle", "AddButton", "AddSlider", "AddDropdown",
            "AddInput", "AddLabel", "AddColorPicker", "AddKeyPicker",
        }

        for _, name in ipairs(methodNames) do
            DepBox[name] = function(_, info)
                local elem = Groupbox[name](Groupbox, info)
                table.insert(DepBox.Elements, elem)
                elem.Holder.Visible = DepBox.Predicate()
                return elem
            end
        end

        function DepBox:Setup(predicate)
            self.Predicate = predicate or function() return true end
            local vis = self.Predicate()
            for _, elem in ipairs(self.Elements) do
                elem.Holder.Visible = vis
            end
        end

        function DepBox:Update()
            local vis = self.Predicate()
            for _, elem in ipairs(self.Elements) do
                elem.Holder.Visible = vis
            end
        end

        return DepBox
    end

    local function CreateLink(owner, anchorHolder, rowHeight)
        local Link = {Connections = {}, Elements = {}, Type = "Link"}

        local IconBtn = Instance.new("ImageButton")
        IconBtn.Size = UDim2.fromOffset(16, 16)
        IconBtn.Position = UDim2.new(1, -16, 0, (rowHeight - 16) / 2)
        IconBtn.BackgroundTransparency = 1
        IconBtn.Image = "rbxassetid://106205298246017"
        IconBtn.ImageColor3 = Library.Scheme.DimmedFont
        IconBtn.ZIndex = 2
        IconBtn.Parent = anchorHolder
        AddToRegistry(IconBtn, {ImageColor3 = "DimmedFont"})

        local Popup = Instance.new("Frame")
        Popup.Size = UDim2.fromOffset(200, 40)
        Popup.BackgroundColor3 = Library.Scheme.Background
        Popup.BorderSizePixel = 0
        Popup.Visible = false
        Popup.ZIndex = 50
        Popup.ClipsDescendants = true
        Popup.Parent = Library.Overlay
        AddToRegistry(Popup, {BackgroundColor3 = "Background"})
        AddShadow(Popup, 0.5, 10)
        AddCorner(Popup)

        local PopupStroke = Instance.new("UIStroke")
        PopupStroke.Color = Library.Scheme.Outline
        PopupStroke.Thickness = 1
        PopupStroke.Parent = Popup
        AddToRegistry(PopupStroke, {Color = "Outline"})

        local PopupContainer = Instance.new("Frame")
        PopupContainer.Size = UDim2.new(1, -12, 1, -12)
        PopupContainer.Position = UDim2.new(0, 6, 0, 6)
        PopupContainer.BackgroundTransparency = 1
        PopupContainer.ZIndex = 51
        PopupContainer.Parent = Popup

        local PopupList = Instance.new("UIListLayout")
        PopupList.SortOrder = Enum.SortOrder.LayoutOrder
        PopupList.Padding = UDim.new(0, 6)
        PopupList.Parent = PopupContainer

        local function RepositionPopup()
            local x = math.clamp(IconBtn.AbsolutePosition.X - 180, 4, Overlay.AbsoluteSize.X - 204)
            local y = IconBtn.AbsolutePosition.Y + IconBtn.AbsoluteSize.Y + 4
            if y + Popup.AbsoluteSize.Y > Overlay.AbsoluteSize.Y then
                y = IconBtn.AbsolutePosition.Y - Popup.AbsoluteSize.Y - 4
            end
            Popup.Position = UDim2.fromOffset(x, y)
        end

        Connect(Link, IconBtn:GetPropertyChangedSignal("AbsolutePosition"), RepositionPopup)

        Connect(Link, PopupList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            local h = math.max(40, PopupList.AbsoluteContentSize.Y + 12)
            Popup.Size = UDim2.fromOffset(200, h)
            RepositionPopup()
        end)

        local open = false
        Connect(Link, IconBtn.MouseButton1Click, function()
            open = not open
            if open then
                RepositionPopup()
                Popup.Visible = true
                IconBtn.ImageColor3 = Library.Scheme.Accent
            else
                Popup.Visible = false
                IconBtn.ImageColor3 = Library.Scheme.DimmedFont
            end
        end)

        Connect(Link, UserInputService.InputBegan, function(input)
            if not open then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local pos = input.Position
                local pAbs = Popup.AbsolutePosition
                local pSize = Popup.AbsoluteSize
                local iAbs = IconBtn.AbsolutePosition
                local iSize = IconBtn.AbsoluteSize
                local inPopup = pos.X >= pAbs.X and pos.X <= pAbs.X + pSize.X and pos.Y >= pAbs.Y and pos.Y <= pAbs.Y + pSize.Y
                local inIcon = pos.X >= iAbs.X and pos.X <= iAbs.X + iSize.X and pos.Y >= iAbs.Y and pos.Y <= iAbs.Y + iSize.Y
                if not inPopup and not inIcon then
                    open = false
                    Popup.Visible = false
                    IconBtn.ImageColor3 = Library.Scheme.DimmedFont
                end
            end
        end)

        local function MakeHolder(height)
            local h = Instance.new("Frame")
            h.Size = UDim2.new(1, 0, 0, height)
            h.BackgroundTransparency = 1
            h.ZIndex = 52
            h.Parent = PopupContainer
            return h
        end

        function Link:AddToggle(info)
            info = setmetatable(info or {}, {__index = Library.Templates.Toggle})
            local Toggle = {Value = info.Default, Connections = {}, Type = "Toggle"}
            local Holder = MakeHolder(20)

            local Box = Instance.new("Frame")
            Box.Size = UDim2.fromOffset(14, 14)
            Box.Position = UDim2.new(0, 0, 0.5, -7)
            Box.BackgroundColor3 = Library.Scheme.Inline
            Box.BorderSizePixel = 0
            Box.ZIndex = 53
            Box.Parent = Holder
            AddToRegistry(Box, {BackgroundColor3 = "Inline"})
            AddCorner(Box, UDim.new(0, 3))

            local BoxStroke = Instance.new("UIStroke")
            BoxStroke.Color = Library.Scheme.Outline
            BoxStroke.Thickness = 1
            BoxStroke.Parent = Box
            AddToRegistry(BoxStroke, {Color = "Outline"})

            local Check = Instance.new("Frame")
            Check.Size = UDim2.fromOffset(8, 8)
            Check.Position = UDim2.new(0.5, -4, 0.5, -4)
            Check.BackgroundColor3 = Library.Scheme.Accent
            Check.BorderSizePixel = 0
            Check.Visible = Toggle.Value
            Check.ZIndex = 54
            Check.Parent = Box
            AddToRegistry(Check, {BackgroundColor3 = "Accent"})
            AddCorner(Check, UDim.new(0, 2))

            local Text = Instance.new("TextLabel")
            Text.Size = UDim2.new(1, -20, 1, 0)
            Text.Position = UDim2.new(0, 20, 0, 0)
            Text.BackgroundTransparency = 1
            Text.Text = info.Text or "Toggle"
            Text.TextColor3 = Library.Scheme.FontColor
            Text.Font = Enum.Font.Gotham
            Text.TextSize = 12
            Text.TextXAlignment = Enum.TextXAlignment.Left
            Text.ZIndex = 53
            Text.Parent = Holder
            AddToRegistry(Text, {TextColor3 = "FontColor"})

            local Click = Instance.new("TextButton")
            Click.Size = UDim2.new(1, 0, 1, 0)
            Click.BackgroundTransparency = 1
            Click.Text = ""
            Click.ZIndex = 55
            Click.Parent = Holder

            function Toggle:Set(val)
                self.Value = val
                Check.Visible = val
                if info.Callback then info.Callback(val) end
            end

            Connect(Toggle, Click.MouseButton1Click, function()
                Toggle:Set(not Toggle.Value)
            end)

            Toggle.Holder = Holder
            table.insert(Link.Elements, Toggle)
            return Toggle
        end

        function Link:AddButton(info)
            info = setmetatable(info or {}, {__index = Library.Templates.Button})
            local Button = {Connections = {}, Type = "Button"}
            local Holder = MakeHolder(24)

            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 1, 0)
            Btn.BackgroundColor3 = Library.Scheme.Inline
            Btn.Text = info.Text or "Button"
            Btn.TextColor3 = Library.Scheme.FontColor
            Btn.Font = Enum.Font.Gotham
            Btn.TextSize = 12
            Btn.AutoButtonColor = false
            Btn.ZIndex = 53
            Btn.Parent = Holder
            AddToRegistry(Btn, {BackgroundColor3 = "Inline", TextColor3 = "FontColor"})
            AddCorner(Btn, UDim.new(0, 4))

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

            Button.Holder = Holder
            table.insert(Link.Elements, Button)
            return Button
        end

        function Link:AddSlider(info)
            info = setmetatable(info or {}, {__index = Library.Templates.Slider})
            local Slider = {Value = info.Default, Connections = {}, Type = "Slider"}
            local Holder = MakeHolder(36)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -40, 0, 14)
            Label.BackgroundTransparency = 1
            Label.Text = info.Text or "Slider"
            Label.TextColor3 = Library.Scheme.FontColor
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.ZIndex = 53
            Label.Parent = Holder
            AddToRegistry(Label, {TextColor3 = "FontColor"})

            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Size = UDim2.new(0, 40, 0, 14)
            ValueLabel.Position = UDim2.new(1, -40, 0, 0)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Text = tostring(info.Default)
            ValueLabel.TextColor3 = Library.Scheme.DimmedFont
            ValueLabel.Font = Enum.Font.Gotham
            ValueLabel.TextSize = 12
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.ZIndex = 53
            ValueLabel.Parent = Holder
            AddToRegistry(ValueLabel, {TextColor3 = "DimmedFont"})

            local Track = Instance.new("Frame")
            Track.Size = UDim2.new(1, 0, 0, 5)
            Track.Position = UDim2.new(0, 0, 0, 20)
            Track.BackgroundColor3 = Library.Scheme.Inline
            Track.BorderSizePixel = 0
            Track.ZIndex = 53
            Track.Parent = Holder
            AddToRegistry(Track, {BackgroundColor3 = "Inline"})
            AddCorner(Track, UDim.new(0, 2))

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(0, 0, 1, 0)
            Fill.BackgroundColor3 = Library.Scheme.Accent
            Fill.BorderSizePixel = 0
            Fill.ZIndex = 54
            Fill.Parent = Track
            AddToRegistry(Fill, {BackgroundColor3 = "Accent"})
            AddCorner(Fill, UDim.new(0, 2))

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

            local initPos = (info.Default - info.Min) / (info.Max - info.Min)
            Fill.Size = UDim2.new(initPos, 0, 1, 0)

            Slider.Holder = Holder
            table.insert(Link.Elements, Slider)
            return Slider
        end

        function Link:AddDropdown(info)
            info = setmetatable(info or {}, {__index = Library.Templates.Dropdown})
            local Dropdown = {Value = info.Multi and {} or (info.Default or nil), Connections = {}, Type = "Dropdown", Options = info.Values or {}}
            local Holder = MakeHolder(24)

            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 1, 0)
            Btn.BackgroundColor3 = Library.Scheme.Inline
            Btn.Text = ""
            Btn.AutoButtonColor = false
            Btn.ZIndex = 53
            Btn.Parent = Holder
            AddToRegistry(Btn, {BackgroundColor3 = "Inline"})
            AddCorner(Btn, UDim.new(0, 4))

            local BtnStroke = Instance.new("UIStroke")
            BtnStroke.Color = Library.Scheme.Outline
            BtnStroke.Thickness = 1
            BtnStroke.Parent = Btn
            AddToRegistry(BtnStroke, {Color = "Outline"})

            local Text = Instance.new("TextLabel")
            Text.Size = UDim2.new(1, -24, 1, 0)
            Text.Position = UDim2.new(0, 6, 0, 0)
            Text.BackgroundTransparency = 1
            Text.Text = info.Text or "Dropdown"
            Text.TextColor3 = Library.Scheme.FontColor
            Text.Font = Enum.Font.Gotham
            Text.TextSize = 12
            Text.TextXAlignment = Enum.TextXAlignment.Left
            Text.ZIndex = 54
            Text.Parent = Btn
            AddToRegistry(Text, {TextColor3 = "FontColor"})

            local Icon = Instance.new("ImageLabel")
            Icon.Size = UDim2.fromOffset(12, 12)
            Icon.Position = UDim2.new(1, -16, 0.5, -6)
            Icon.BackgroundTransparency = 1
            Icon.Image = Library:GetIcon("chevron-down")
            Icon.ImageColor3 = Library.Scheme.DimmedFont
            Icon.ZIndex = 54
            Icon.Parent = Btn
            AddToRegistry(Icon, {ImageColor3 = "DimmedFont"})

            local ListFrame = Instance.new("Frame")
            ListFrame.Size = UDim2.new(0, 0, 0, 0)
            ListFrame.BackgroundColor3 = Library.Scheme.Background
            ListFrame.BorderSizePixel = 0
            ListFrame.ClipsDescendants = true
            ListFrame.Visible = false
            ListFrame.ZIndex = 60
            ListFrame.Parent = Library.Overlay
            AddToRegistry(ListFrame, {BackgroundColor3 = "Background"})
            AddShadow(ListFrame, 0.5, 8)
            AddCorner(ListFrame, UDim.new(0, 4))

            local ListStroke = Instance.new("UIStroke")
            ListStroke.Color = Library.Scheme.Outline
            ListStroke.Thickness = 1
            ListStroke.Parent = ListFrame
            AddToRegistry(ListStroke, {Color = "Outline"})

            local Scroll = Instance.new("ScrollingFrame")
            Scroll.Size = UDim2.new(1, -6, 1, -6)
            Scroll.Position = UDim2.new(0, 3, 0, 3)
            Scroll.BackgroundTransparency = 1
            Scroll.ScrollBarThickness = 0
            Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            Scroll.ZIndex = 61
            Scroll.Parent = ListFrame

            local ScrollList = Instance.new("UIListLayout")
            ScrollList.SortOrder = Enum.SortOrder.LayoutOrder
            ScrollList.Padding = UDim.new(0, 2)
            ScrollList.Parent = Scroll

            local function RepositionList()
                ListFrame.Position = UDim2.fromOffset(Btn.AbsolutePosition.X, Btn.AbsolutePosition.Y + Btn.AbsoluteSize.Y + 2)
            end

            local dropOpen = false
            local function Build()
                for _, child in ipairs(Scroll:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, val in ipairs(Dropdown.Options) do
                    local Opt = Instance.new("TextButton")
                    Opt.Size = UDim2.new(1, 0, 0, 20)
                    Opt.BackgroundTransparency = 1
                    Opt.Text = "  " .. tostring(val)
                    Opt.TextColor3 = Library.Scheme.FontColor
                    Opt.Font = Enum.Font.Gotham
                    Opt.TextSize = 11
                    Opt.TextXAlignment = Enum.TextXAlignment.Left
                    Opt.ZIndex = 62
                    Opt.Parent = Scroll
                    AddToRegistry(Opt, {TextColor3 = "FontColor"})

                    if not info.Multi and Dropdown.Value == val then
                        Opt.BackgroundColor3 = Library.Scheme.Accent
                        Opt.BackgroundTransparency = 0.8
                    end

                    Connect(Dropdown, Opt.MouseButton1Click, function()
                        if info.Multi then
                            Dropdown.Value[val] = not Dropdown.Value[val]
                        else
                            Dropdown.Value = val
                            Text.Text = tostring(val)
                            dropOpen = false
                            Tween(ListFrame, TweenInfo.new(0.15), {Size = UDim2.new(0, Btn.AbsoluteSize.X, 0, 0)})
                            ListFrame.Visible = false
                            Icon.Rotation = 0
                        end
                        if info.Callback then info.Callback(Dropdown.Value) end
                        Build()
                    end)
                end
            end

            Connect(Dropdown, Btn.MouseButton1Click, function()
                dropOpen = not dropOpen
                if dropOpen then
                    Build()
                    RepositionList()
                    ListFrame.Size = UDim2.new(0, Btn.AbsoluteSize.X, 0, 0)
                    ListFrame.Visible = true
                    Tween(ListFrame, TweenInfo.new(0.15), {Size = UDim2.new(0, Btn.AbsoluteSize.X, 0, math.min(100, #Dropdown.Options * 22 + 6))})
                    Icon.Rotation = 180
                else
                    Tween(ListFrame, TweenInfo.new(0.15), {Size = UDim2.new(0, Btn.AbsoluteSize.X, 0, 0)})
                    task.wait(0.15)
                    ListFrame.Visible = false
                    Icon.Rotation = 0
                end
            end)

            function Dropdown:Set(val)
                self.Value = val
                if not info.Multi then Text.Text = tostring(val) end
                if info.Callback then info.Callback(val) end
            end

            function Dropdown:SetValues(values)
                self.Options = values or {}
                if info.Multi then
                    self.Value = {}
                else
                    self.Value = nil
                    Text.Text = info.Text or "Dropdown"
                end
                if dropOpen then Build() end
            end

            function Dropdown:Refresh()
                if dropOpen then Build() end
            end

            Dropdown.Holder = Holder
            table.insert(Link.Elements, Dropdown)
            return Dropdown
        end

        function Link:AddInput(info)
            info = setmetatable(info or {}, {__index = Library.Templates.Input})
            local Input = {Value = info.Default, Connections = {}, Type = "Input"}
            local Holder = MakeHolder(40)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 0, 14)
            Label.BackgroundTransparency = 1
            Label.Text = info.Text or "Input"
            Label.TextColor3 = Library.Scheme.FontColor
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.ZIndex = 53
            Label.Parent = Holder
            AddToRegistry(Label, {TextColor3 = "FontColor"})

            local Box = Instance.new("TextBox")
            Box.Size = UDim2.new(1, 0, 0, 22)
            Box.Position = UDim2.new(0, 0, 0, 16)
            Box.BackgroundColor3 = Library.Scheme.Inline
            Box.Text = tostring(info.Default)
            Box.PlaceholderText = info.Placeholder or ""
            Box.TextColor3 = Library.Scheme.FontColor
            Box.Font = Enum.Font.Gotham
            Box.TextSize = 11
            Box.ClearTextOnFocus = info.ClearTextOnFocus
            Box.ZIndex = 53
            Box.Parent = Holder
            AddToRegistry(Box, {BackgroundColor3 = "Inline", TextColor3 = "FontColor"})
            AddCorner(Box, UDim.new(0, 4))

            local BoxStroke = Instance.new("UIStroke")
            BoxStroke.Color = Library.Scheme.Outline
            BoxStroke.Thickness = 1
            BoxStroke.Parent = Box
            AddToRegistry(BoxStroke, {Color = "Outline"})

            local function Fire()
                local txt = Box.Text
                if info.Numeric then txt = tonumber(txt) or 0 end
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
            table.insert(Link.Elements, Input)
            return Input
        end

        function Link:AddLabel(info)
            info = typeof(info) == "string" and {Text = info} or (info or {})
            local Label = {Connections = {}, Type = "Label"}
            local Holder = MakeHolder(16)

            local Text = Instance.new("TextLabel")
            Text.Size = UDim2.new(1, 0, 1, 0)
            Text.BackgroundTransparency = 1
            Text.Text = info.Text or ""
            Text.TextColor3 = Library.Scheme.DimmedFont
            Text.Font = Enum.Font.Gotham
            Text.TextSize = 11
            Text.TextXAlignment = Enum.TextXAlignment.Left
            Text.ZIndex = 53
            Text.Parent = Holder
            AddToRegistry(Text, {TextColor3 = "DimmedFont"})

            function Label:SetText(txt)
                Text.Text = txt
            end

            Label.Holder = Holder
            table.insert(Link.Elements, Label)
            return Label
        end

        function Link:AddColorPicker(info)
            info = setmetatable(info or {}, {__index = Library.Templates.ColorPicker})
            local Picker = {Value = info.Default, Transparency = info.Transparency, Connections = {}, Type = "ColorPicker"}
            local Holder = MakeHolder(18)

            local Text = Instance.new("TextLabel")
            Text.Size = UDim2.new(1, -22, 1, 0)
            Text.BackgroundTransparency = 1
            Text.Text = info.Text or "Color"
            Text.TextColor3 = Library.Scheme.FontColor
            Text.Font = Enum.Font.Gotham
            Text.TextSize = 12
            Text.TextXAlignment = Enum.TextXAlignment.Left
            Text.ZIndex = 53
            Text.Parent = Holder
            AddToRegistry(Text, {TextColor3 = "FontColor"})

            local Swatch = Instance.new("TextButton")
            Swatch.Size = UDim2.fromOffset(16, 16)
            Swatch.Position = UDim2.new(1, -16, 0.5, -8)
            Swatch.BackgroundColor3 = Picker.Value
            Swatch.Text = ""
            Swatch.AutoButtonColor = false
            Swatch.ZIndex = 53
            Swatch.Parent = Holder
            AddCorner(Swatch, UDim.new(0, 3))

            local SwatchStroke = Instance.new("UIStroke")
            SwatchStroke.Color = Library.Scheme.Outline
            SwatchStroke.Thickness = 1
            SwatchStroke.Parent = Swatch
            AddToRegistry(SwatchStroke, {Color = "Outline"})

            local ColorPopup = Instance.new("Frame")
            ColorPopup.Size = UDim2.fromOffset(160, 170)
            ColorPopup.BackgroundColor3 = Library.Scheme.Background
            ColorPopup.BorderSizePixel = 0
            ColorPopup.Visible = false
            ColorPopup.ZIndex = 70
            ColorPopup.Parent = Library.Overlay
            AddToRegistry(ColorPopup, {BackgroundColor3 = "Background"})
            AddShadow(ColorPopup, 0.5, 8)
            AddCorner(ColorPopup)

            local ColorStroke = Instance.new("UIStroke")
            ColorStroke.Color = Library.Scheme.Outline
            ColorStroke.Thickness = 1
            ColorStroke.Parent = ColorPopup
            AddToRegistry(ColorStroke, {Color = "Outline"})

            local SatVal = Instance.new("ImageButton")
            SatVal.Size = UDim2.new(1, -12, 0, 100)
            SatVal.Position = UDim2.new(0, 6, 0, 6)
            SatVal.Image = "rbxassetid://4155801252"
            SatVal.ZIndex = 71
            SatVal.Parent = ColorPopup
            AddCorner(SatVal, UDim.new(0, 3))

            local h, s, v = Color3.toHSV(Picker.Value)
            SatVal.BackgroundColor3 = Color3.fromHSV(h, 1, 1)

            local Cursor = Instance.new("Frame")
            Cursor.Size = UDim2.fromOffset(5, 5)
            Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
            Cursor.Position = UDim2.new(s, 0, 1 - v, 0)
            Cursor.BackgroundColor3 = Color3.new(1,1,1)
            Cursor.BorderSizePixel = 0
            Cursor.ZIndex = 72
            Cursor.Parent = SatVal
            AddCorner(Cursor, UDim.new(1, 0))

            local HueSlider = Instance.new("ImageButton")
            HueSlider.Size = UDim2.new(1, -12, 0, 12)
            HueSlider.Position = UDim2.new(0, 6, 0, 112)
            HueSlider.Image = "rbxassetid://3283211550"
            HueSlider.ZIndex = 71
            HueSlider.Parent = ColorPopup
            AddCorner(HueSlider, UDim.new(0, 3))

            local HueCursor = Instance.new("Frame")
            HueCursor.Size = UDim2.new(0, 2, 1, 2)
            HueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
            HueCursor.Position = UDim2.new(h, 0, 0.5, 0)
            HueCursor.BackgroundColor3 = Color3.new(1,1,1)
            HueCursor.BorderSizePixel = 0
            HueCursor.ZIndex = 72
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
                ColorPopup.Position = UDim2.fromOffset(
                    math.clamp(Swatch.AbsolutePosition.X - 140, 0, Overlay.AbsoluteSize.X - 160),
                    Swatch.AbsolutePosition.Y + 20
                )
                ColorPopup.Visible = not ColorPopup.Visible
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
            table.insert(Link.Elements, Picker)
            return Picker
        end

        function Link:AddKeyPicker(info)
            info = setmetatable(info or {}, {__index = Library.Templates.KeyPicker})
            local Picker = {Value = info.Default, Mode = info.Mode, Connections = {}, Type = "KeyPicker", Toggled = false}
            local Holder = MakeHolder(18)

            local Text = Instance.new("TextLabel")
            Text.Size = UDim2.new(1, -60, 1, 0)
            Text.BackgroundTransparency = 1
            Text.Text = info.Text or "Keybind"
            Text.TextColor3 = Library.Scheme.FontColor
            Text.Font = Enum.Font.Gotham
            Text.TextSize = 12
            Text.TextXAlignment = Enum.TextXAlignment.Left
            Text.ZIndex = 53
            Text.Parent = Holder
            AddToRegistry(Text, {TextColor3 = "FontColor"})

            local KeyBtn = Instance.new("TextButton")
            KeyBtn.Size = UDim2.fromOffset(54, 16)
            KeyBtn.Position = UDim2.new(1, -54, 0.5, -8)
            KeyBtn.BackgroundColor3 = Library.Scheme.Inline
            KeyBtn.Text = tostring(info.Default)
            KeyBtn.TextColor3 = Library.Scheme.FontColor
            KeyBtn.Font = Enum.Font.Gotham
            KeyBtn.TextSize = 11
            KeyBtn.AutoButtonColor = false
            KeyBtn.ZIndex = 53
            KeyBtn.Parent = Holder
            AddToRegistry(KeyBtn, {BackgroundColor3 = "Inline", TextColor3 = "FontColor"})
            AddCorner(KeyBtn, UDim.new(0, 3))

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
            table.insert(Link.Elements, Picker)
            return Picker
        end

        function Link:Destroy()
            for _, c in ipairs(self.Connections) do c:Disconnect() end
            Popup:Destroy()
            IconBtn:Destroy()
        end

        Link.Popup = Popup
        Link.Icon = IconBtn
        return Link
    end

    function Groupbox:AddToggle(info, flag)
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
        AddCorner(Box, UDim.new(0, 4))

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
        AddCorner(Check, UDim.new(0, 3))

        local Text = Instance.new("TextLabel")
        Text.Size = UDim2.new(1, -44, 0, rowHeight)
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
        Click.Size = UDim2.new(1, -20, 0, rowHeight)
        Click.BackgroundTransparency = 1
        Click.Text = ""
        Click.Parent = Holder

        function Toggle:Set(val)
            self.Value = val
            Check.Visible = val
            SetFlag(flag, val)
            if info.Callback then info.Callback(val) end
        end
        function Toggle:Destroy()
            for _,c in ipairs(self.Connections) do c:Disconnect() end
            if self._Link then self._Link:Destroy() end
            Holder:Destroy()
        end

        function Toggle:Link()
            if self._Link then return self._Link end
            self._Link = CreateLink(self, Holder, rowHeight)
            return self._Link
        end

        Connect(Toggle, Click.MouseButton1Click, function()
            Toggle:Set(not Toggle.Value)
        end)

        Toggle.Holder = Holder
        RegisterOption(flag, Toggle)
        table.insert(Groupbox.Elements, Toggle)
        table.insert(Tab.Elements, Toggle)
        return Toggle
    end

    function Groupbox:AddButton(info)
        info = setmetatable(info or {}, {__index = Library.Templates.Button})
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
        AddCorner(Btn)

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

    function Groupbox:AddSlider(info, flag)
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
        AddCorner(Track, UDim.new(0, 3))

        local Fill = Instance.new("Frame")
        Fill.Size = UDim2.new(0, 0, 1, 0)
        Fill.BackgroundColor3 = Library.Scheme.Accent
        Fill.BorderSizePixel = 0
        Fill.Parent = Track
        AddToRegistry(Fill, {BackgroundColor3 = "Accent"})
        AddCorner(Fill, UDim.new(0, 3))

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
            SetFlag(flag, val)
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
            SetFlag(flag, val)
            if info.Callback then info.Callback(val) end
        end

        Slider.Holder = Holder
        RegisterOption(flag, Slider)
        local initPos = (info.Default - info.Min) / math.max(info.Max - info.Min, 1e-9)
        Fill.Size = UDim2.new(initPos, 0, 1, 0)
        table.insert(Groupbox.Elements, Slider)
        table.insert(Tab.Elements, Slider)
        return Slider
    end

    function Groupbox:AddDropdown(info, flag)
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
        AddCorner(Btn)

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
        AddCorner(ListFrame)

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
        Scroll.ScrollBarThickness = 0
        Scroll.ScrollBarImageTransparency = 1
        Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Scroll.Parent = ListFrame

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
            AddCorner(SearchBox, UDim.new(0, 4))

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
                    AddCorner(Opt, UDim.new(0, 4))

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
                        SetFlag(flag, Dropdown.Value)
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
            SetFlag(flag, val)
            if info.Callback then info.Callback(val) end
        end

        function Dropdown:SetValues(values)
            self.Options = values or {}
            info.SpecialType = nil
            if info.Multi then
                self.Value = {}
            else
                self.Value = nil
            end
            SetFlag(flag, self.Value)
            if open then Build() end
        end

        function Dropdown:Refresh()
            if info.SpecialType == "Player" then
                self.Options = {}
                for _, plr in ipairs(Players:GetPlayers()) do
                    table.insert(self.Options, plr.Name)
                end
            elseif info.SpecialType == "Team" then
                self.Options = {}
                for _, team in ipairs(game.Teams:GetTeams()) do
                    table.insert(self.Options, team.Name)
                end
            end
            if open then Build() end
        end

        function Dropdown:Destroy()
            for _,c in ipairs(self.Connections) do c:Disconnect() end
            ListFrame:Destroy()
            Holder:Destroy()
        end

        Dropdown.Holder = Holder
        RegisterOption(flag, Dropdown)
        table.insert(Groupbox.Elements, Dropdown)
        table.insert(Tab.Elements, Dropdown)
        return Dropdown
    end

    function Groupbox:AddInput(info, flag)
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
        AddCorner(Box)

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
            SetFlag(flag, txt)
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
            SetFlag(flag, val)
            if info.Callback then info.Callback(val) end
        end

        Input.Holder = Holder
        RegisterOption(flag, Input)
        table.insert(Groupbox.Elements, Input)
        table.insert(Tab.Elements, Input)
        return Input
    end

    function Groupbox:AddLabel(info)
        info = typeof(info) == "string" and {Text = info} or (info or {})
        local Label = {Connections = {}, Type = "Label"}

        local rowHeight = 18
        local descOffset = info.Description and 14 or 0
        local Holder = Instance.new("Frame")
        Holder.Size = UDim2.new(1, 0, 0, rowHeight + descOffset)
        Holder.BackgroundTransparency = 1
        Holder.Parent = Container

        local Text = Instance.new("TextLabel")
        Text.Size = UDim2.new(1, -20, 0, rowHeight)
        Text.BackgroundTransparency = 1
        Text.Text = info.Text or ""
        Text.TextColor3 = Library.Scheme.DimmedFont
        Text.Font = Enum.Font.Gotham
        Text.TextSize = 12
        Text.TextWrapped = true
        Text.TextXAlignment = Enum.TextXAlignment.Left
        Text.Parent = Holder
        AddToRegistry(Text, {TextColor3 = "DimmedFont"})

        if info.Description then
            AddDescription(Holder, rowHeight, info.Description)
        end

        function Label:SetText(txt)
            Text.Text = txt
            local bounds = GetTextSize(txt, Text.TextSize, Text.Font)
            Holder.Size = UDim2.new(1, 0, 0, math.max(rowHeight, bounds.Y) + descOffset)
        end

        function Label:Link()
            if self._Link then return self._Link end
            self._Link = CreateLink(self, Holder, rowHeight)
            return self._Link
        end

        function Label:Destroy()
            for _, c in ipairs(self.Connections) do c:Disconnect() end
            if self._Link then self._Link:Destroy() end
            Holder:Destroy()
        end

        Label.Holder = Holder
        Label.Text = Text
        table.insert(Groupbox.Elements, Label)
        table.insert(Tab.Elements, Label)
        return Label
    end

    function Groupbox:AddColorPicker(info, flag)
        info = setmetatable(info or {}, {__index = Library.Templates.ColorPicker})
        local Picker = {Value = info.Default, Transparency = info.Transparency, Connections = {}, Type = "ColorPicker"}

        local rowHeight = 20
        local totalHeight = info.Description and (rowHeight + 14) or rowHeight

        local Holder = Instance.new("Frame")
        Holder.Size = UDim2.new(1, 0, 0, totalHeight)
        Holder.BackgroundTransparency = 1
        Holder.Parent = Container

        local Text = Instance.new("TextLabel")
        Text.Size = UDim2.new(1, -30, 0, rowHeight)
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
        AddCorner(Swatch, UDim.new(0, 4))

        local SwatchStroke = Instance.new("UIStroke")
        SwatchStroke.Color = Library.Scheme.Outline
        SwatchStroke.Thickness = 1
        SwatchStroke.Parent = Swatch
        AddToRegistry(SwatchStroke, {Color = "Outline"})

        if info.Description then
            AddDescription(Holder, rowHeight, info.Description)
        end

        local Popup = Instance.new("Frame")
        Popup.Size = UDim2.fromOffset(180, 200)
        Popup.BackgroundColor3 = Library.Scheme.Background
        Popup.BorderSizePixel = 0
        Popup.Visible = false
        Popup.ZIndex = 50
        Popup.Parent = Library.Overlay
        AddToRegistry(Popup, {BackgroundColor3 = "Background"})
        AddShadow(Popup, 0.5, 10)
        AddCorner(Popup)

        local PopupStroke = Instance.new("UIStroke")
        PopupStroke.Color = Library.Scheme.Outline
        PopupStroke.Thickness = 1
        PopupStroke.Parent = Popup
        AddToRegistry(PopupStroke, {Color = "Outline"})

        local function RepositionPopup()
            Popup.Position = UDim2.fromOffset(
                math.clamp(Swatch.AbsolutePosition.X - 160, 0, Overlay.AbsoluteSize.X - 180),
                Swatch.AbsolutePosition.Y + Swatch.AbsoluteSize.Y + 4
            )
        end
        Connect(Picker, Swatch:GetPropertyChangedSignal("AbsolutePosition"), RepositionPopup)

        local SatVal = Instance.new("ImageButton")
        SatVal.Size = UDim2.new(1, -16, 0, 120)
        SatVal.Position = UDim2.new(0, 8, 0, 8)
        SatVal.Image = "rbxassetid://4155801252"
        SatVal.ZIndex = 51
        SatVal.Parent = Popup
        AddCorner(SatVal, UDim.new(0, 4))

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
        AddCorner(Cursor, UDim.new(1, 0))

        local HueSlider = Instance.new("ImageButton")
        HueSlider.Size = UDim2.new(1, -16, 0, 16)
        HueSlider.Position = UDim2.new(0, 8, 0, 136)
        HueSlider.Image = "rbxassetid://3283211550"
        HueSlider.ZIndex = 51
        HueSlider.Parent = Popup
        AddCorner(HueSlider, UDim.new(0, 4))

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
            SetFlag(flag, Picker.Value)
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
            RepositionPopup()
            Popup.Visible = not Popup.Visible
        end)

        function Picker:Set(color)
            self.Value = color
            h, s, v = Color3.toHSV(color)
            Cursor.Position = UDim2.new(s, 0, 1 - v, 0)
            HueCursor.Position = UDim2.new(h, 0, 0.5, 0)
            Swatch.BackgroundColor3 = color
            SatVal.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            SetFlag(flag, color)
            if info.Callback then info.Callback(color, self.Transparency) end
        end

        function Picker:Destroy()
            for _,c in ipairs(self.Connections) do c:Disconnect() end
            Popup:Destroy()
            Holder:Destroy()
        end

        Picker.Holder = Holder
        RegisterOption(flag, Picker)
        table.insert(Groupbox.Elements, Picker)
        table.insert(Tab.Elements, Picker)
        return Picker
    end

    function Groupbox:AddKeyPicker(info, flag)
        info = setmetatable(info or {}, {__index = Library.Templates.KeyPicker})
        local Picker = {Value = info.Default, Mode = info.Mode, Connections = {}, Type = "KeyPicker", Toggled = false}

        local rowHeight = 20
        local totalHeight = info.Description and (rowHeight + 14) or rowHeight

        local Holder = Instance.new("Frame")
        Holder.Size = UDim2.new(1, 0, 0, totalHeight)
        Holder.BackgroundTransparency = 1
        Holder.Parent = Container

        local Text = Instance.new("TextLabel")
        Text.Size = UDim2.new(1, -80, 0, rowHeight)
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
        AddCorner(KeyBtn, UDim.new(0, 4))

        if info.Description then
            AddDescription(Holder, rowHeight, info.Description)
        end

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
                SetFlag(flag, Picker.Value)
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
            SetFlag(flag, key)
        end

        Picker.Holder = Holder
        RegisterOption(flag, Picker)
        table.insert(Groupbox.Elements, Picker)
        table.insert(Tab.Elements, Picker)
        return Picker
    end

    Groupbox.Frame = Frame
    return Groupbox
end

local function CreateTab(Window, TabButton, Page, info)
    local Tab = {Connections = {}, Elements = {}, Groupboxes = {}, Visible = false}

    function Tab:AddLeftGroupbox(gInfo)
        local gb = CreateGroupbox(Tab, Window.LeftColumn, gInfo)
        gb.Frame.Visible = Tab.Visible
        table.insert(Tab.Groupboxes, gb)
        return gb
    end
    function Tab:AddRightGroupbox(gInfo)
        local gb = CreateGroupbox(Tab, Window.RightColumn, gInfo)
        gb.Frame.Visible = Tab.Visible
        table.insert(Tab.Groupboxes, gb)
        return gb
    end

    function Tab:Show()
        self.Visible = true
        for _, gb in ipairs(self.Groupboxes) do
            gb.Frame.Visible = true
        end
    end

    function Tab:Hide()
        self.Visible = false
        for _, gb in ipairs(self.Groupboxes) do
            gb.Frame.Visible = false
        end
    end

    Tab.Button = TabButton
    Tab.Page = Page
    return Tab
end

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

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = self.Scheme.Outline
    MainStroke.Thickness = 1
    MainStroke.Parent = Main
    AddToRegistry(MainStroke, {Color = "Outline"})

    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 32)
    TopBar.BackgroundColor3 = self.Scheme.GroupBackground
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Main
    AddToRegistry(TopBar, {BackgroundColor3 = "GroupBackground"})

    local Traffic = Instance.new("Frame")
    Traffic.Size = UDim2.fromOffset(52, 12)
    Traffic.Position = UDim2.new(0, 10, 0.5, -6)
    Traffic.BackgroundTransparency = 1
    Traffic.Parent = TopBar

    local TrafficList = Instance.new("UIListLayout")
    TrafficList.FillDirection = Enum.FillDirection.Horizontal
    TrafficList.Padding = UDim.new(0, 6)
    TrafficList.VerticalAlignment = Enum.VerticalAlignment.Center
    TrafficList.Parent = Traffic

    local function MakeDot(color)
        local Dot = Instance.new("Frame")
        Dot.Size = UDim2.fromOffset(10, 10)
        Dot.BackgroundColor3 = color
        Dot.BorderSizePixel = 0
        Dot.Parent = Traffic
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = Dot
        return Dot
    end
    MakeDot(Color3.fromRGB(255, 95, 87))
    MakeDot(Color3.fromRGB(255, 189, 46))
    MakeDot(Color3.fromRGB(40, 200, 64))

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = info.Title
    TitleLabel.TextColor3 = self.Scheme.FontColor
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
    TitleLabel.Parent = TopBar
    AddToRegistry(TitleLabel, {TextColor3 = "FontColor"})

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

    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1, -16, 0, 26)
    TabBar.Position = UDim2.new(0, 8, 0, 38)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent = Main

    local TabList = Instance.new("UIListLayout")
    TabList.FillDirection = Enum.FillDirection.Horizontal
    TabList.Padding = UDim.new(0, 4)
    TabList.Parent = TabBar

    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -16, 1, -74)
    Content.Position = UDim2.new(0, 8, 0, 68)
    Content.BackgroundTransparency = 1
    Content.Parent = Main

    local LeftColumn = Instance.new("ScrollingFrame")
    LeftColumn.Size = UDim2.new(0.5, -4, 1, 0)
    LeftColumn.BackgroundTransparency = 1
    LeftColumn.ScrollBarThickness = 0
    LeftColumn.ScrollBarImageTransparency = 1
    LeftColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
    LeftColumn.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LeftColumn.ScrollingEnabled = true
    LeftColumn.Parent = Content

    local LeftList = Instance.new("UIListLayout")
    LeftList.SortOrder = Enum.SortOrder.LayoutOrder
    LeftList.Padding = UDim.new(0, 6)
    LeftList.Parent = LeftColumn

    local RightColumn = Instance.new("ScrollingFrame")
    RightColumn.Size = UDim2.new(0.5, -4, 1, 0)
    RightColumn.Position = UDim2.new(0.5, 4, 0, 0)
    RightColumn.BackgroundTransparency = 1
    RightColumn.ScrollBarThickness = 0
    RightColumn.ScrollBarImageTransparency = 1
    RightColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
    RightColumn.AutomaticCanvasSize = Enum.AutomaticSize.Y
    RightColumn.ScrollingEnabled = true
    RightColumn.Parent = Content

    local RightList = Instance.new("UIListLayout")
    RightList.SortOrder = Enum.SortOrder.LayoutOrder
    RightList.Padding = UDim.new(0, 6)
    RightList.Parent = RightColumn

    Window.LeftColumn = LeftColumn
    Window.RightColumn = RightColumn
    Window.Main = Main

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
        AddCorner(TabButton)

        local Tab = CreateTab(self, TabButton, Content, {})

        Connect(Tab, TabButton.MouseButton1Click, function()
            for _, t in ipairs(self.Tabs) do
                Tween(t.Button, TweenInfo.new(0.15), {BackgroundColor3 = Library.Scheme.Inline})
                t:Hide()
            end
            Tween(TabButton, TweenInfo.new(0.15), {BackgroundColor3 = Library.Scheme.Accent})
            Tab:Show()
            self.ActiveTab = Tab
        end)

        if #self.Tabs == 0 then
            Tween(TabButton, TweenInfo.new(0.01), {BackgroundColor3 = Library.Scheme.Accent})
            Tab:Show()
            self.ActiveTab = Tab
        else
            Tab:Hide()
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
        AddCorner(MobileBtn, UDim.new(1, 0))

        Connect(Window, MobileBtn.MouseButton1Click, function()
            Window:Toggle()
        end)
    end

    table.insert(self.Registry, Window)
    return Window
end

function Library:SaveConfig(name)
    if not isfolder("Tze") then makefolder("Tze") end
    local data = {}
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
