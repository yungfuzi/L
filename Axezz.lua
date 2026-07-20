local Library = {
}

local cloneref = cloneref or clonereference or function(instance) return instance end

local CoreGui = cloneref(game:GetService("CoreGui"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local SoundService = cloneref(game:GetService("SoundService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TextService = cloneref(game:GetService("TextService"))
local Teams = cloneref(game:GetService("Teams"))
local TweenService = cloneref(game:GetService("TweenService"))
local HttpService = cloneref(game:GetService("HttpService"))

local getgenv = getgenv or function() return shared end
local setclipboard = setclipboard or nil
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function() return CoreGui end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = cloneref(LocalPlayer:GetMouse())

local Theme = {
    Base = Color3.fromRGB(10, 10, 14),
    Window = Color3.fromRGB(18, 18, 24),
    Surface = Color3.fromRGB(24, 24, 32),
    Elevated = Color3.fromRGB(32, 32, 42),
    Glass = Color3.fromRGB(255, 255, 255, 0.06),
    TextPrimary = Color3.fromRGB(240, 240, 245),
    TextSecondary = Color3.fromRGB(180, 180, 195),
    TextMuted = Color3.fromRGB(130, 130, 150),
    TextDisabled = Color3.fromRGB(80, 80, 95),
    Border = Color3.fromRGB(55, 55, 70),
    Divider = Color3.fromRGB(45, 45, 55),
    Shadow = Color3.fromRGB(0, 0, 0, 0.4),
    AccentStart = Color3.fromRGB(0, 180, 255),
    AccentMiddle = Color3.fromRGB(150, 80, 255),
    AccentEnd = Color3.fromRGB(255, 80, 200),
    Success = Color3.fromRGB(0, 230, 120),
    Warning = Color3.fromRGB(255, 200, 0),
    Error = Color3.fromRGB(255, 70, 70),
    Info = Color3.fromRGB(0, 180, 255),
    RadiusWindow = 14,
    RadiusPanel = 10,
    RadiusElement = 8,
    RadiusSmall = 6,
    RadiusPill = 20,
    Font = Font.fromEnum(Enum.Font.Gotham),
}

local function accentGradientSequence()
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.AccentStart),
        ColorSequenceKeypoint.new(0.5, Theme.AccentMiddle),
        ColorSequenceKeypoint.new(1, Theme.AccentEnd),
    })
end

local CustomImageManager = {}
local ImageAssets = {}

function CustomImageManager:AddAsset(name, robloxId, url, forceRedownload)
    if ImageAssets[name] then error("Asset already exists: " .. name) end
    assert(type(robloxId) == "number", "robloxId must be number")
    ImageAssets[name] = {
        RobloxId = robloxId,
        Path = "Library/custom/" .. name,
        URL = url,
        Id = nil,
    }
    self:DownloadAsset(name, forceRedownload)
end

function CustomImageManager:GetAsset(name)
    local asset = ImageAssets[name]
    if not asset then return nil end
    if asset.Id then return asset.Id end
    local id = "rbxassetid://" .. asset.RobloxId
    if getcustomasset then
        local success, custom = pcall(getcustomasset, asset.Path)
        if success and custom then id = custom end
    end
    asset.Id = id
    return id
end

function CustomImageManager:DownloadAsset(name, forceRedownload)
    local asset = ImageAssets[name]
    if not getcustomasset or not writefile or not isfile then return false, "missing functions" end
    local segments = asset.Path:split("/")
    table.remove(segments, #segments)
    local folder = table.concat(segments, "/")
    if not isfolder(folder) then makefolder(folder) end
    if not forceRedownload and isfile(asset.Path) then return true end
    local success, err = pcall(function()
        writefile(asset.Path, game:HttpGet(asset.URL))
    end)
    return success, err
end

local BaseURL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local defaultAssets = {
    TransparencyTexture = { RobloxId = 139785960036434, URL = BaseURL .. "assets/TransparencyTexture.png" },
    SaturationMap = { RobloxId = 4155801252, URL = BaseURL .. "assets/SaturationMap.png" },
    LoadingIcon = { RobloxId = 97544096941083, URL = BaseURL .. "assets/LoadingIcon.png" },
    CheckIcon = { RobloxId = 97682394690683, URL = BaseURL .. "assets/CheckIcon.png" },
}
for name, data in pairs(defaultAssets) do
    CustomImageManager:AddAsset(name, data.RobloxId, data.URL)
end

local LucideModule
local LucideLoaded = pcall(function()
    LucideModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua"))()
end)

function Library:GetIcon(name)
    if not LucideLoaded then return nil end
    local ok, icon = pcall(LucideModule.GetAsset, name)
    if ok then return icon end
    return nil
end

function Library:GetCustomIcon(icon)
    if type(icon) == "number" then
        icon = "rbxassetid://" .. tostring(icon)
    end
    if type(icon) ~= "string" then return nil end
    if icon:match("^content://") or icon:match("^rbxasset://") or icon:match("^rbxassetid://") then
        return {
            Url = icon,
            ImageRectOffset = Vector2.zero,
            ImageRectSize = Vector2.zero,
            IsCustom = true,
        }
    end
    local lucide = Library:GetIcon(icon)
    if lucide then
        return {
            Url = lucide.Url,
            ImageRectOffset = lucide.ImageRectOffset,
            ImageRectSize = lucide.ImageRectSize,
            IsCustom = false,
        }
    end
    if icon:match("^https?://") then
        return {
            Url = icon,
            ImageRectOffset = Vector2.zero,
            ImageRectSize = Vector2.zero,
            IsCustom = true,
        }
    end
    return nil
end

local function WaitForEvent(event, timeout, condition)
    local bind = Instance.new("BindableEvent")
    local conn = event:Once(function(...)
        if not condition or (type(condition) == "function" and condition(...)) then
            bind:Fire(true)
        else
            bind:Fire(false)
        end
    end)
    task.delay(timeout, function()
        conn:Disconnect()
        bind:Fire(false)
    end)
    local result = bind.Event:Wait()
    bind:Destroy()
    return result
end

local function IsMouseInput(input, includeM2)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or (includeM2 and input.UserInputType == Enum.UserInputType.MouseButton2)
        or input.UserInputType == Enum.UserInputType.Touch
end

local function IsClickInput(input, includeM2)
    return IsMouseInput(input, includeM2)
        and input.UserInputState == Enum.UserInputState.Begin
        and Library._isFocused
end

local function IsHoverInput(input)
    return (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
        and input.UserInputState == Enum.UserInputState.Change
end

local function IsDragInput(input, includeM2)
    return IsMouseInput(input, includeM2)
        and (input.UserInputState == Enum.UserInputState.Begin or input.UserInputState == Enum.UserInputState.Change)
        and Library._isFocused
end

local function IsMovementInput(input)
    return (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
        and Library._isFocused
end

local function GetTableSize(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function StopTween(tween, destroy)
    if not tween then return end
    if tween.PlaybackState == Enum.PlaybackState.Playing then
        tween:Cancel()
    end
    if destroy then pcall(tween.Destroy, tween) end
end

local function Trim(s) return s:match("^%s*(.-)%s*$") end

local function Round(value, decimals)
    if decimals == 0 then return math.floor(value) end
    return tonumber(string.format("%." .. decimals .. "f", value))
end

local function GetPlayers(excludeLocal)
    local list = Players:GetPlayers()
    if excludeLocal then
        for i = #list, 1, -1 do
            if list[i] == LocalPlayer then table.remove(list, i) end
        end
    end
    table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)
    return list
end

local function GetTeams()
    local list = Teams:GetTeams()
    table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)
    return list
end

Library._isFocused = true
Library._toggled = false
Library._unloaded = false
Library._searching = false
Library._searchText = ""
Library._globalSearch = false
Library._lastSearchTab = nil

Library._tabs = {}
Library._tabButtons = {}
Library._activeTab = nil
Library._windows = {}
Library._panels = {}
Library._dependencyBoxes = {}

Library._notifications = {}
Library._notifyOrder = {}
Library._notifySide = "Right"
Library._notifyTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

Library._dialogs = {}
Library._activeDialog = nil

Library._activeLoading = nil

Library._corners = {}
Library._specificCorners = {}

Library._animations = {
    Window = true,
    Tab = true,
    Panel = true,
    Dropdown = true,
    KeyPicker = true,
}

Library._tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
Library._tabTransitionInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
Library._tabSwipeOffset = 20
Library._tabSwipeFrom = "right"

Library._registry = {}
Library._scales = {}
Library._scalesOffset = {}

Library._signals = {}
Library._unloadCallbacks = {}

Library._draggableElements = {}
Library._cantDragForced = false

Library._toggleKeybind = Enum.KeyCode.RightControl
Library._showCustomCursor = true

Library._minSize = Vector2.new(480, 360)
Library._originalMinSize = Vector2.new(480, 360)
Library._dpiScale = 1

Library._isMobile = false
if RunService:IsStudio() then
    Library._isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
else
    local platform = pcall(UserInputService.GetPlatform, UserInputService) and UserInputService:GetPlatform()
    Library._isMobile = platform == Enum.Platform.Android or platform == Enum.Platform.IOS
end
if Library._isMobile then
    Library._originalMinSize = Vector2.new(480, 240)
end
Library._minSize = Library._originalMinSize

local function New(className, props)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    return inst
end

local function SafeParent(inst, parent)
    local success = pcall(function()
        if parent then inst.Parent = parent else inst.Parent = CoreGui end
    end)
    if not success then
        inst.Parent = LocalPlayer:WaitForChild("PlayerGui", math.huge)
    end
end

local function ParentUI(inst, skipProtect)
    if not skipProtect then pcall(protectgui, inst) end
    SafeParent(inst, gethui())
end

local ScreenGui = New("ScreenGui", {
    Name = "Library",
    DisplayOrder = 998,
    ResetOnSpawn = false,
})
ParentUI(ScreenGui)

local ModalElement = New("TextButton", {
    BackgroundTransparency = 1,
    Modal = false,
    Size = UDim2.fromScale(0, 0),
    Text = "",
    ZIndex = -999,
    Parent = ScreenGui,
})

local Cursor, CursorImage
do
    Cursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.TextPrimary,
        Size = UDim2.fromOffset(9, 1),
        Visible = false,
        ZIndex = 11000,
        Parent = ScreenGui,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Shadow,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 10999,
        Parent = Cursor,
    })
    local CursorV = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.TextPrimary,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1, 9),
        ZIndex = 11000,
        Parent = Cursor,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Shadow,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 10999,
        Parent = CursorV,
    })
    CursorImage = New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(20, 20),
        ZIndex = 11000,
        Visible = false,
        Parent = Cursor,
    })
end

local NotificationArea = New("Frame", {
    AnchorPoint = Vector2.new(1, 0),
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -6, 0, 6),
    Size = UDim2.new(0, 320, 1, -6),
    Parent = ScreenGui,
})
table.insert(Library._scales, New("UIScale", { Parent = NotificationArea }))

function Library:AddToRegistry(instance, props)
    self._registry[instance] = props
end

function Library:RemoveFromRegistry(instance)
    self._registry[instance] = nil
end

function Library:UpdateColors()
    for inst, props in pairs(self._registry) do
        for prop, token in pairs(props) do
            local value
            if type(token) == "function" then
                value = token()
            elseif Theme[token] ~= nil then
                value = Theme[token]
            else
                value = token
            end
            if value ~= nil then
                inst[prop] = value
            end
        end
    end
end

local function GetOverlappingDraggable(ui, pos)
    local pos1 = pos or ui.AbsolutePosition
    local size1 = ui.AbsoluteSize
    for _, other in ipairs(Library._draggableElements) do
        if other == ui or not other.Visible or not other.Parent then continue end
        local pos2 = other.AbsolutePosition
        local size2 = other.AbsoluteSize
        if pos1.X < pos2.X + size2.X and pos1.X + size1.X > pos2.X and
           pos1.Y < pos2.Y + size2.Y and pos1.Y + size1.Y > pos2.Y then
            return other
        end
    end
    return nil
end

local function GetNonOverlappingPosition(ui, startPos)
    local screenSize = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)) - Vector2.new(100, 100)
    local start = startPos and Vector2.new(startPos.X.Offset, startPos.Y.Offset) or Vector2.new(6, 6)
    local padding = 6
    local cx, cy = start.X, start.Y
    local size = ui.AbsoluteSize
    if size.X == 0 or size.Y == 0 then
        RunService.RenderStepped:Wait()
        size = ui.AbsoluteSize
    end
    if size.X == 0 then size = Vector2.new(150, 40) end
    local maxXInColumn = size.X

    while true do
        local obstacle = GetOverlappingDraggable(ui, Vector2.new(cx, cy))
        if not obstacle then break end
        if obstacle.AbsoluteSize.X > maxXInColumn then maxXInColumn = obstacle.AbsoluteSize.X end
        local nextY = obstacle.AbsolutePosition.Y + obstacle.AbsoluteSize.Y + padding
        if nextY + size.Y > screenSize.Y - padding then
            local nextX = cx + maxXInColumn + padding
            if nextX + size.X > screenSize.X - padding then break end
            cy = start.Y
            cx = nextX
            maxXInColumn = size.X
        else
            cy = nextY
        end
    end
    return UDim2.fromOffset(cx, cy)
end

local function PositionDraggable(ui, startPos)
    ui.Position = GetNonOverlappingPosition(ui, startPos)
end

function Library:MakeDraggable(ui, dragFrame, ignoreToggled, isMain)
    local startPos, framePos, dragging = nil, nil, false
    local changed, inputBegan, inputChanged

    inputBegan = dragFrame.InputBegan:Connect(function(input)
        if not IsClickInput(input) or (isMain and self._cantDragForced) then return end
        startPos = input.Position
        framePos = ui.Position
        dragging = true
        changed = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if changed and changed.Connected then changed:Disconnect() end
                changed = nil
            end
        end)
    end)

    inputChanged = UserInputService.InputChanged:Connect(function(input)
        if (not ignoreToggled and not self._toggled) or (isMain and self._cantDragForced) or not (ScreenGui and ScreenGui.Parent) then
            dragging = false
            if changed and changed.Connected then changed:Disconnect() end
            changed = nil
            return
        end
        if dragging and IsHoverInput(input) then
            local delta = input.Position - startPos
            ui.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X,
                                    framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)

    self:GiveSignal(inputChanged)
    self:GiveSignal(inputBegan)

    ui.Destroying:Once(function()
        if inputChanged and inputChanged.Connected then inputChanged:Disconnect() end
        if inputBegan and inputBegan.Connected then inputBegan:Disconnect() end
        if changed and changed.Connected then changed:Disconnect() end
    end)

    table.insert(self._draggableElements, ui)
end

function Library:MakeResizable(ui, dragFrame, callback)
    local startPos, frameSize, dragging = nil, nil, false
    local changed, inputBegan, inputChanged

    inputBegan = dragFrame.InputBegan:Connect(function(input)
        if not IsClickInput(input) then return end
        startPos = input.Position
        frameSize = ui.Size
        dragging = true
        changed = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if changed and changed.Connected then changed:Disconnect() end
                changed = nil
            end
        end)
    end)

    inputChanged = UserInputService.InputChanged:Connect(function(input)
        if not ui.Visible or not (ScreenGui and ScreenGui.Parent) then
            dragging = false
            if changed and changed.Connected then changed:Disconnect() end
            changed = nil
            return
        end
        if dragging and IsHoverInput(input) then
            local delta = input.Position - startPos
            ui.Size = UDim2.new(
                frameSize.X.Scale,
                math.clamp(frameSize.X.Offset + delta.X, Library._minSize.X, math.huge),
                frameSize.Y.Scale,
                math.clamp(frameSize.Y.Offset + delta.Y, Library._minSize.Y, math.huge)
            )
            if callback then callback() end
        end
    end)

    self:GiveSignal(inputChanged)
    self:GiveSignal(inputBegan)

    ui.Destroying:Once(function()
        if inputChanged and inputChanged.Connected then inputChanged:Disconnect() end
        if inputBegan and inputBegan.Connected then inputBegan:Disconnect() end
        if changed and changed.Connected then changed:Disconnect() end
    end)
end

local TooltipLabel = New("TextLabel", {
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = Theme.Surface,
    TextSize = 13,
    TextWrapped = true,
    Visible = false,
    ZIndex = 20,
    Parent = ScreenGui,
})
New("UIPadding", {
    PaddingBottom = UDim.new(0, 4),
    PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6),
    PaddingTop = UDim.new(0, 4),
    Parent = TooltipLabel,
})
table.insert(Library._scales, New("UIScale", { Parent = TooltipLabel }))
New("UIStroke", { Color = Theme.Border, Parent = TooltipLabel })
table.insert(Library._corners, New("UICorner", { CornerRadius = UDim.new(0, Theme.RadiusSmall), Parent = TooltipLabel }))

local currentHoverInstance = nil
function Library:AddTooltip(text, disabledText, hoverInstance)
    local tooltip = { disabled = false, signals = {} }

    local function doHover()
        if currentHoverInstance == hoverInstance or Library._activeDialog or (tooltip.disabled and not disabledText) then return end
        currentHoverInstance = hoverInstance
        local parent = hoverInstance:FindFirstAncestorOfClass("ScreenGui") or ScreenGui
        TooltipLabel.Parent = parent
        TooltipLabel.Text = tooltip.disabled and disabledText or text
        TooltipLabel.Visible = true

        while Library._toggled and not Library._activeDialog and
              Library:MouseIsOverFrame(hoverInstance, Mouse) do
            TooltipLabel.Position = UDim2.fromOffset(
                Mouse.X + (Library._showCustomCursor and 8 or 14),
                Mouse.Y + (Library._showCustomCursor and 8 or 12)
            )
            RunService.RenderStepped:Wait()
        end
        TooltipLabel.Visible = false
        currentHoverInstance = nil
    end

    local function addSignal(conn)
        if conn and conn.Connected then table.insert(tooltip.signals, conn) end
        return conn
    end

    addSignal(hoverInstance.MouseEnter:Connect(doHover))
    addSignal(hoverInstance.MouseMoved:Connect(doHover))
    addSignal(hoverInstance.MouseLeave:Connect(function()
        if currentHoverInstance == hoverInstance then
            TooltipLabel.Visible = false
            currentHoverInstance = nil
        end
    end))

    function tooltip:Destroy()
        for _, c in ipairs(self.signals) do
            if c.Connected then c:Disconnect() end
        end
        if currentHoverInstance == hoverInstance then
            TooltipLabel.Visible = false
            currentHoverInstance = nil
        end
    end
    return tooltip
end

function Library:SetNotifySide(side)
    self._notifySide = side
    local left = side:lower() == "left"
    NotificationArea.AnchorPoint = left and Vector2.new(0, 0) or Vector2.new(1, 0)
    NotificationArea.Position = left and UDim2.fromOffset(6, 6) or UDim2.new(1, -6, 0, 6)
    for bg in pairs(self._notifications) do
        if bg and bg.Parent then
            bg.AnchorPoint = left and Vector2.new(0, 0) or Vector2.new(1, 0)
        end
    end
    self:UpdateNotificationPositions(true)
end

function Library:UpdateNotificationPositions(snap)
    local left = self._notifySide:lower() == "left"
    local xScale = left and 0 or 1
    local runningY = 0
    for _, bg in ipairs(self._notifyOrder) do
        local data = self._notifications[bg]
        if not data or not bg.Parent then continue end
        local target = UDim2.new(xScale, 0, 0, runningY)
        if snap or not data._positionInit then
            bg.Position = target
            data._positionInit = true
        elseif bg.Position ~= target then
            TweenService:Create(bg, self._notifyTweenInfo, { Position = target }):Play()
        end
        runningY = runningY + bg.AbsoluteSize.Y + 8
    end
end

function Library:Notify(...)
    local data = {}
    local info = select(1, ...)
    if type(info) == "table" then
        data.Title = tostring(info.Title)
        data.Description = tostring(info.Description)
        data.Time = info.Time or 5
        data.SoundId = info.SoundId
        data.Icon = info.Icon
        data.BigIcon = info.BigIcon
        data.IconColor = info.IconColor
        data.Volume = tonumber(info.Volume) or 3
        data.Persist = info.Persist
    else
        data.Description = tostring(info)
        data.Time = select(2, ...) or 5
        data.SoundId = select(3, ...)
        data.Volume = select(4, ...) or 3
    end
    data.Destroyed = false

    local fakeBg = New("Frame", {
        AnchorPoint = self._notifySide:lower() == "left" and Vector2.new(0, 0) or Vector2.new(1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 0),
        Visible = false,
        Parent = NotificationArea,
    })

    local holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Glass,
        Position = self._notifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
        Size = UDim2.fromScale(1, 1),
        ZIndex = 5,
        Parent = fakeBg,
    })
    table.insert(self._corners, New("UICorner", { CornerRadius = UDim.new(0, Theme.RadiusPanel), Parent = holder }))
    New("UIListLayout", { Padding = UDim.new(0, 4), Parent = holder })
    New("UIPadding", { PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), Parent = holder })
    New("UIStroke", { Color = Theme.Border, Parent = holder })

    local content = New("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromScale(1, 0),
        Parent = holder,
    })

    if data.BigIcon then
        New("UIListLayout", { Padding = UDim.new(0, 8), FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Parent = content })
        local iconData = Library:GetCustomIcon(data.BigIcon)
        if iconData then
            New("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(24, 24),
                Image = iconData.Url,
                ImageColor3 = data.IconColor or Theme.AccentStart,
                ImageRectOffset = iconData.ImageRectOffset or Vector2.zero,
                ImageRectSize = iconData.ImageRectSize or Vector2.zero,
                Parent = content,
            })
        end
    end

    local textContainer = New("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromScale(0, 0),
        Parent = content,
    })
    New("UIListLayout", { Padding = UDim.new(0, 4), Parent = textContainer })

    local titleLabel, descLabel
    if data.Title then
        titleLabel = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            Text = data.Title,
            TextColor3 = Theme.TextPrimary,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = textContainer,
        })
    end
    if data.Description then
        descLabel = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            Text = data.Description,
            TextColor3 = Theme.TextSecondary,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = textContainer,
        })
    end

    function data:Resize()
        local maxWidth = NotificationArea.AbsoluteSize.X - 20
        if titleLabel then
            local x, y = Library:GetTextBounds(titleLabel.Text, Theme.Font, 15, maxWidth)
            titleLabel.Size = UDim2.fromOffset(x, y)
        end
        if descLabel then
            local x, y = Library:GetTextBounds(descLabel.Text, Theme.Font, 13, maxWidth)
            descLabel.Size = UDim2.fromOffset(x, y)
        end
        fakeBg.Size = UDim2.fromOffset(maxWidth + 10, 0)
        if self._notifications[fakeBg] then
            self:UpdateNotificationPositions()
        end
    end

    data:Resize()

    local timerHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 5),
        Visible = not data.Persist and type(data.Time) == "number",
        Parent = holder,
    })
    local timerBar = New("Frame", {
        BackgroundColor3 = Theme.Border,
        Position = UDim2.fromOffset(0, 2),
        Size = UDim2.new(1, 0, 0, 2),
        Parent = timerHolder,
    })
    local timerFill = New("Frame", {
        BackgroundColor3 = Theme.AccentStart,
        Size = UDim2.fromScale(1, 1),
        Parent = timerBar,
    })

    if data.SoundId then
        local sid = type(data.SoundId) == "number" and ("rbxassetid://" .. data.SoundId) or data.SoundId
        New("Sound", { SoundId = sid, Volume = data.Volume, PlayOnRemove = true, Parent = SoundService }):Destroy()
    end

    table.insert(self._notifyOrder, fakeBg)
    self._notifications[fakeBg] = data
    self:UpdateNotificationPositions()

    fakeBg.Visible = true
    TweenService:Create(holder, self._notifyTweenInfo, { Position = UDim2.fromOffset(0, 0) }):Play()

    task.delay(self._notifyTweenInfo.Time, function()
        if data.Persist then return end
        if type(data.Time) == "number" and data.Time > 0 then
            TweenService:Create(timerFill, TweenInfo.new(data.Time, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 1) }):Play()
            task.wait(data.Time)
        end
        if not data.Destroyed then data:Destroy() end
    end)

    function data:Destroy()
        data.Destroyed = true
        local idx = table.find(self._notifyOrder, fakeBg)
        if idx then table.remove(self._notifyOrder, idx) end
        self._notifications[fakeBg] = nil
        self:UpdateNotificationPositions()
        TweenService:Create(holder, self._notifyTweenInfo, {
            Position = self._notifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
        }):Play()
        task.delay(self._notifyTweenInfo.Time, function()
            fakeBg:Destroy()
        end)
    end

    return data
end

local currentContextMenu = nil

function Library:CreateContextMenu(anchor, sizeProvider, offsetProvider, isScrolling, activeCallback, cornerMode, animationType)
    local menu = nil
    local parentGui = anchor:FindFirstAncestorOfClass("ScreenGui") or ScreenGui
    local zIndex = math.max(10, anchor.ZIndex + 1)

    if isScrolling then
        menu = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme.Surface,
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Border,
            Size = sizeProvider(),
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            Visible = false,
            ZIndex = zIndex,
            Parent = parentGui,
        })
    else
        menu = New("Frame", {
            BackgroundColor3 = Theme.Surface,
            Size = sizeProvider(),
            Visible = false,
            ZIndex = zIndex,
            Parent = parentGui,
        })
    end
    table.insert(Library._scales, New("UIScale", { Parent = menu }))
    New("UIStroke", { Color = Theme.Border, Parent = menu })

    local corner = nil
    if not cornerMode then
        corner = New("UICorner", { CornerRadius = UDim.new(0, Theme.RadiusElement), Parent = menu })
        table.insert(Library._corners, corner)
    else
        local r = Theme.RadiusElement
        if cornerMode == "top" then
            corner = New("UICorner", { TopLeftRadius = UDim.new(0, r), TopRightRadius = UDim.new(0, r), BottomRightRadius = UDim.new(0, 0), BottomLeftRadius = UDim.new(0, 0), Parent = menu })
        elseif cornerMode == "bottom" then
            corner = New("UICorner", { TopLeftRadius = UDim.new(0, 0), TopRightRadius = UDim.new(0, 0), BottomRightRadius = UDim.new(0, r), BottomLeftRadius = UDim.new(0, r), Parent = menu })
        elseif cornerMode == "no_left" then
            corner = New("UICorner", { TopLeftRadius = UDim.new(0, 0), TopRightRadius = UDim.new(0, r), BottomRightRadius = UDim.new(0, r), BottomLeftRadius = UDim.new(0, 0), Parent = menu })
        elseif cornerMode == "no_top_left" then
            corner = New("UICorner", { TopLeftRadius = UDim.new(0, 0), TopRightRadius = UDim.new(0, r), BottomRightRadius = UDim.new(0, r), BottomLeftRadius = UDim.new(0, r), Parent = menu })
        end
        if corner then table.insert(Library._specificCorners, corner) end
    end

    local context = {
        Active = false,
        Menu = menu,
        Anchor = anchor,
        SizeProvider = sizeProvider,
        OffsetProvider = offsetProvider,
        AutoSizeY = isScrolling,
        OpenCloseTween = nil,
        Signals = {},
    }

    local function animate(open)
        local isAnimated = (animationType and Library._animations[animationType])
        local tweenInfo = isAnimated and TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) or nil
        return isAnimated, tweenInfo
    end

    function context:Open()
        if currentContextMenu == context then return end
        if currentContextMenu then currentContextMenu:Close() end
        currentContextMenu = context
        context.Active = true

        if activeCallback then activeCallback(true) end

        local pos = context.OffsetProvider()
        menu.Position = UDim2.fromOffset(
            math.floor(anchor.AbsolutePosition.X + pos[1]),
            math.floor(anchor.AbsolutePosition.Y + pos[2])
        )

        local targetSize = context.SizeProvider()
        local isAnimated, tweenInfo = animate(true)
        if isAnimated then
            local openSize = targetSize
            if context.AutoSizeY then
                menu.AutomaticSize = Enum.AutomaticSize.None
                openSize = UDim2.new(targetSize.X.Scale, targetSize.X.Offset, 0, menu.AbsoluteSize.Y)
            end
            menu.Size = UDim2.new(openSize.X.Scale, openSize.X.Offset, 0, 0)
            menu.Visible = true
            local tween = TweenService:Create(menu, tweenInfo, { Size = openSize })
            context.OpenCloseTween = tween
            tween:Play()
            tween.Completed:Once(function()
                if context.OpenCloseTween == tween then
                    StopTween(context.OpenCloseTween, true)
                    context.OpenCloseTween = nil
                    if context.AutoSizeY then menu.AutomaticSize = Enum.AutomaticSize.Y end
                end
            end)
        else
            menu.Size = targetSize
            menu.Visible = true
        end

        local conn = anchor:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            local p = context.OffsetProvider()
            menu.Position = UDim2.fromOffset(
                math.floor(anchor.AbsolutePosition.X + p[1]),
                math.floor(anchor.AbsolutePosition.Y + p[2])
            )
        end)
        table.insert(context.Signals, conn)
    end

    function context:Close()
        if currentContextMenu ~= context then return end
        if activeCallback then activeCallback(false) end
        for _, c in ipairs(context.Signals) do
            if c.Connected then c:Disconnect() end
        end
        context.Signals = {}
        context.Active = false
        currentContextMenu = nil

        if context.OpenCloseTween then
            StopTween(context.OpenCloseTween, true)
            context.OpenCloseTween = nil
        end

        local isAnimated, tweenInfo = animate(false)
        if isAnimated then
            if context.AutoSizeY then menu.AutomaticSize = Enum.AutomaticSize.None end
            local cur = menu.Size
            local closed = UDim2.new(cur.X.Scale, cur.X.Offset, 0, 0)
            local tween = TweenService:Create(menu, tweenInfo, { Size = closed })
            context.OpenCloseTween = tween
            tween:Play()
            tween.Completed:Once(function()
                if context.OpenCloseTween == tween then
                    StopTween(context.OpenCloseTween, true)
                    context.OpenCloseTween = nil
                    menu.Visible = false
                    if context.AutoSizeY then menu.AutomaticSize = Enum.AutomaticSize.Y end
                end
            end)
        else
            menu.Visible = false
        end
    end

    function context:Toggle()
        if context.Active then context:Close() else context:Open() end
    end

    function context:Destroy()
        for _, c in ipairs(context.Signals) do if c.Connected then c:Disconnect() end end
        if currentContextMenu == context then context:Close() end
        if context.OpenCloseTween then StopTween(context.OpenCloseTween, true) end
        if menu then menu:Destroy() end
    end

    return context
end

UserInputService.InputBegan:Connect(function(input)
    if Library._unloaded then return end
    if IsClickInput(input, true) then
        local pos = input.Position
        if currentContextMenu and not (
            Library:MouseIsOverFrame(currentContextMenu.Menu, pos) or
            Library:MouseIsOverFrame(currentContextMenu.Anchor, pos)
        ) then
            currentContextMenu:Close()
        end
    end
end)

local PanelBase = {}
function PanelBase:AddDivider(...) end
function PanelBase:AddLabel(...) end
function PanelBase:AddAction(...) end
function PanelBase:AddSwitch(...) end
function PanelBase:AddRange(...) end
function PanelBase:AddSelect(...) end
function PanelBase:AddInput(...) end
function PanelBase:AddColorPicker(...) end
function PanelBase:AddHotkey(...) end
function PanelBase:AddImage(...) end
function PanelBase:AddVideo(...) end
function PanelBase:AddViewport(...) end
function PanelBase:AddUIPassthrough(...) end

function Library:GetTextBounds(text, font, size, width)
    local params = Instance.new("GetTextBoundsParams")
    params.Text = text
    params.RichText = true
    params.Font = font
    params.Size = size
    params.Width = width or workspace.CurrentCamera.ViewportSize.X - 32
    local bounds = TextService:GetTextBoundsAsync(params)
    return bounds.X, bounds.Y
end

function Library:MouseIsOverFrame(frame, mousePos)
    local pos, size = frame.AbsolutePosition, frame.AbsoluteSize
    return mousePos.X >= pos.X and mousePos.X <= pos.X + size.X and
           mousePos.Y >= pos.Y and mousePos.Y <= pos.Y + size.Y
end

local function CreatePanel(parent, info)
    info = info or {}
    local title = info.Title or ""
    local desc = info.Description or ""
    local icon = info.Icon
    local collapsible = info.Collapsible ~= false
    local collapsed = info.Collapsed or false
    local side = info.Side or 1

    local holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 0),
        Parent = parent,
    })
    New("UIListLayout", { Padding = UDim.new(0, 4), Parent = holder })
    New("UIPadding", { PaddingBottom = UDim.new(0, 4), PaddingTop = UDim.new(0, 4), Parent = holder })

    local panel = New("Frame", {
        BackgroundColor3 = Theme.Glass,
        Size = UDim2.fromScale(1, 0),
        Parent = holder,
    })
    New("UICorner", { CornerRadius = UDim.new(0, Theme.RadiusPanel), Parent = panel })
    New("UIStroke", { Color = Theme.Border, Parent = panel })

    local header = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
        Parent = panel,
    })
    New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), Parent = header })
    New("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = header })

    if icon then
        local iconData = Library:GetCustomIcon(icon)
        if iconData then
            New("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(20, 20),
                Image = iconData.Url,
                ImageColor3 = Theme.AccentStart,
                ImageRectOffset = iconData.ImageRectOffset or Vector2.zero,
                ImageRectSize = iconData.ImageRectSize or Vector2.zero,
                Parent = header,
            })
        end
    end

    local titleLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(0, 1),
        Text = title,
        TextColor3 = Theme.TextPrimary,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        FontFace = Theme.Font,
        Parent = header,
    })
    if desc and desc ~= "" then
        titleLabel.TextSize = 15
    end

    local descLabel
    if desc and desc ~= "" then
        descLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromScale(0, 1),
            Text = desc,
            TextColor3 = Theme.TextMuted,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            FontFace = Theme.Font,
            Parent = header,
        })
    end

    New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = header })

    local arrow = nil
    if collapsible then
        local arrowIcon = Library:GetIcon("chevron-up")
        arrow = New("ImageButton", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(20, 20),
            Image = arrowIcon and arrowIcon.Url or "",
            ImageColor3 = Theme.TextSecondary,
            ImageRectOffset = arrowIcon and arrowIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = arrowIcon and arrowIcon.ImageRectSize or Vector2.zero,
            Rotation = collapsed and 0 or 180,
            Parent = header,
        })
    end

    local content = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 36),
        Size = UDim2.new(1, 0, 1, -36),
        Visible = not collapsed,
        Parent = panel,
    })
    New("UIListLayout", { Padding = UDim.new(0, 6), Parent = content })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 6),
        Parent = content,
    })

    local panelObj = {
        Holder = holder,
        Panel = panel,
        Header = header,
        Content = content,
        TitleLabel = titleLabel,
        DescLabel = descLabel,
        Arrow = arrow,
        Collapsed = collapsed,
        Collapsible = collapsible,
        Elements = {},
        DependencyBoxes = {},
        Tab = nil,
        Type = "Panel",
    }

    function panelObj:Resize()
        local totalHeight = 36
        if not panelObj.Collapsed then
            local layout = content:FindFirstChildOfClass("UIListLayout")
            if layout then
                totalHeight = totalHeight + layout.AbsoluteContentSize.Y + 8
            end
        end
        panel.Size = UDim2.new(1, 0, 0, totalHeight)
        holder.Size = UDim2.new(1, 0, 0, totalHeight + 4)
    end

    function panelObj:SetCollapsed(value)
        if not collapsible then return end
        self.Collapsed = value
        content.Visible = not value
        if arrow then
            TweenService:Create(arrow, Library._tweenInfo, { Rotation = value and 0 or 180 }):Play()
        end
        self:Resize()
    end

    function panelObj:ToggleCollapsed()
        self:SetCollapsed(not self.Collapsed)
    end

    if arrow then
        arrow.MouseButton1Click:Connect(function()
            panelObj:ToggleCollapsed()
        end)
    end

    local function addElement(element)
        table.insert(panelObj.Elements, element)
        panelObj:Resize()
        return element
    end

    return panelObj
end

local function CreateTab(window, name, icon, description)
    local tabButton = New("TextButton", {
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40),
        Text = "",
        Parent = window._tabContainer,
    })
    local padding = New("UIPadding", {
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 8),
        Parent = tabButton,
    })

    local label = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(30, 0),
        Size = UDim2.new(1, -30, 1, 0),
        Text = name,
        TextColor3 = Theme.TextSecondary,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        FontFace = Theme.Font,
        Parent = tabButton,
    })

    local iconImg = nil
    if icon then
        local iconData = Library:GetCustomIcon(icon)
        if iconData then
            iconImg = New("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Image = iconData.Url,
                ImageColor3 = Theme.TextSecondary,
                ImageRectOffset = iconData.ImageRectOffset or Vector2.zero,
                ImageRectSize = iconData.ImageRectSize or Vector2.zero,
                Parent = tabButton,
            })
        end
    end

    local canvas = New("CanvasGroup", {
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        GroupTransparency = 0,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        Parent = window._contentContainer,
    })

    local content = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = canvas,
    })

    local leftSide = New("ScrollingFrame", {
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        CanvasSize = UDim2.fromScale(0, 0),
        ScrollBarThickness = 0,
        Size = UDim2.new(0.5, -3, 1, 0),
        Parent = content,
    })
    New("UIListLayout", { Padding = UDim.new(0, 2), Parent = leftSide })
    New("UIPadding", { PaddingBottom = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), PaddingTop = UDim.new(0, 2), Parent = leftSide })

    local rightSide = New("ScrollingFrame", {
        AnchorPoint = Vector2.new(1, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        CanvasSize = UDim2.fromScale(0, 0),
        Position = UDim2.fromScale(1, 0),
        ScrollBarThickness = 0,
        Size = UDim2.new(0.5, -3, 1, 0),
        Parent = content,
    })
    New("UIListLayout", { Padding = UDim.new(0, 2), Parent = rightSide })
    New("UIPadding", { PaddingBottom = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), PaddingTop = UDim.new(0, 2), Parent = rightSide })

    local tabObj = {
        Name = name,
        Icon = icon,
        Description = description,
        Button = tabButton,
        Canvas = canvas,
        Content = content,
        LeftSide = leftSide,
        RightSide = rightSide,
        Panels = {},
        Tabboxes = {},
        DependencyBoxes = {},
        Window = window,
        Active = false,
    }

    function tabObj:Show()
        if window._activeTab == tabObj then return end
        if window._activeTab then window._activeTab:Hide() end
        window._activeTab = tabObj
        tabObj.Active = true

        TweenService:Create(tabButton, Library._tweenInfo, { BackgroundTransparency = 0 }):Play()
        TweenService:Create(label, Library._tweenInfo, { TextColor3 = Theme.TextPrimary }):Play()
        if iconImg then
            TweenService:Create(iconImg, Library._tweenInfo, { ImageColor3 = Theme.AccentStart }):Play()
        end

        Library:PlayTabAnimation(canvas, true)
        if description then
            window:ShowTabInfo(name, description)
        end
        for _, panel in ipairs(tabObj.Panels) do
            panel:Resize()
        end
    end

    function tabObj:Hide()
        tabObj.Active = false
        TweenService:Create(tabButton, Library._tweenInfo, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(label, Library._tweenInfo, { TextColor3 = Theme.TextSecondary }):Play()
        if iconImg then
            TweenService:Create(iconImg, Library._tweenInfo, { ImageColor3 = Theme.TextSecondary }):Play()
        end
        Library:PlayTabAnimation(canvas, false)
        if window._activeTab == tabObj then
            window._activeTab = nil
            window:HideTabInfo()
        end
    end

    function tabObj:AddPanel(info)
        info = info or {}
        info.Side = info.Side or 1
        local target = info.Side == 1 and leftSide or rightSide
        local panel = CreatePanel(target, info)
        panel.Tab = tabObj
        table.insert(tabObj.Panels, panel)
        panel:Resize()
        return panel
    end

    function tabObj:AddLeftPanel(info)
        info.Side = 1
        return self:AddPanel(info)
    end

    function tabObj:AddRightPanel(info)
        info.Side = 2
        return self:AddPanel(info)
    end

    function tabObj:Destroy()
        if window._activeTab == tabObj then tabObj:Hide() end
        canvas:Destroy()
        tabButton:Destroy()
        for _, panel in ipairs(tabObj.Panels) do
            panel.Panel:Destroy()
            panel.Holder:Destroy()
        end
        tabObj.Panels = {}
        for i, t in ipairs(window._tabs) do
            if t == tabObj then table.remove(window._tabs, i) break end
        end
    end

    tabButton.MouseEnter:Connect(function()
        if tabObj.Active then return end
        TweenService:Create(label, Library._tweenInfo, { TextColor3 = Theme.TextPrimary }):Play()
        if iconImg then
            TweenService:Create(iconImg, Library._tweenInfo, { ImageColor3 = Theme.TextPrimary }):Play()
        end
    end)
    tabButton.MouseLeave:Connect(function()
        if tabObj.Active then return end
        TweenService:Create(label, Library._tweenInfo, { TextColor3 = Theme.TextSecondary }):Play()
        if iconImg then
            TweenService:Create(iconImg, Library._tweenInfo, { ImageColor3 = Theme.TextSecondary }):Play()
        end
    end)
    tabButton.MouseButton1Click:Connect(tabObj.Show)

    return tabObj
end

function Library:CreateWindow(info)
    info = info or {}
    local title = info.Title or "Library"
    local footer = info.Footer or ""
    local icon = info.Icon
    local size = info.Size or UDim2.fromOffset(760, 520)
    local position = info.Position or UDim2.fromOffset(6, 6)
    local center = info.Center ~= false
    local resizable = info.Resizable ~= false
    local sidebarWidth = info.SidebarWidth or 200
    local compactSidebar = info.CompactSidebar or false
    local minWidth = info.MinWidth or 480
    local minHeight = info.MinHeight or 360
    local globalsearch = info.GlobalSearch or false
    local notifySide = info.NotifySide or "Right"
    local toggleKeybind = info.ToggleKeybind or Enum.KeyCode.RightControl

    self._globalSearch = globalsearch
    self:SetNotifySide(notifySide)
    self._toggleKeybind = toggleKeybind

    local viewport = workspace.CurrentCamera.ViewportSize
    local maxX = math.max(viewport.X - 64, minWidth)
    local maxY = math.max(viewport.Y - 64, minHeight)
    local w = math.clamp(size.X.Offset, minWidth, maxX)
    local h = math.clamp(size.Y.Offset, minHeight, maxY)
    size = UDim2.fromOffset(w, h)
    self._minSize = Vector2.new(minWidth, minHeight)

    local main = New("TextButton", {
        BackgroundColor3 = Theme.Window,
        Name = "Main",
        Text = "",
        Position = position,
        Size = size,
        Visible = false,
        Parent = ScreenGui,
    })
    New("UICorner", { CornerRadius = UDim.new(0, Theme.RadiusWindow), Parent = main })
    New("UIStroke", { Color = Theme.Border, Parent = main })
    table.insert(self._scales, New("UIScale", { Parent = main }))

    local glass = New("Frame", {
        BackgroundColor3 = Theme.Glass,
        Position = UDim2.fromScale(0, 0),
        Size = UDim2.fromScale(1, 1),
        ZIndex = 0,
        Parent = main,
    })
    New("UICorner", { CornerRadius = UDim.new(0, Theme.RadiusWindow), Parent = glass })

    local topBar = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 44),
        Parent = main,
    })
    self:MakeDraggable(main, topBar, false, true)

    local titleHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, sidebarWidth, 1, 0),
        Parent = topBar,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = titleHolder,
    })

    local iconImg = nil
    if icon then
        local iconData = Library:GetCustomIcon(icon)
        if iconData then
            iconImg = New("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(24, 24),
                Image = iconData.Url,
                ImageColor3 = Theme.TextPrimary,
                ImageRectOffset = iconData.ImageRectOffset or Vector2.zero,
                ImageRectSize = iconData.ImageRectSize or Vector2.zero,
                Parent = titleHolder,
            })
        end
    end

    local titleLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = title,
        TextColor3 = Theme.TextPrimary,
        TextSize = 18,
        FontFace = Theme.Font,
        Parent = titleHolder,
    })

    local rightWrapper = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(1, -sidebarWidth - 12, 1, -16),
        Parent = topBar,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        Parent = rightWrapper,
    })

    local tabInfo = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        Parent = rightWrapper,
    })
    New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Grow, Parent = tabInfo })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = tabInfo,
    })
    local tabTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Text = "",
        TextColor3 = Theme.TextPrimary,
        TextSize = 15,
        FontFace = Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tabInfo,
    })
    local tabDesc = New("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Text = "",
        TextColor3 = Theme.TextMuted,
        TextSize = 12,
        FontFace = Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tabInfo,
    })

    local searchBox = New("TextBox", {
        BackgroundColor3 = Theme.Surface,
        ClearTextOnFocus = false,
        PlaceholderText = "Search...",
        Size = UDim2.fromScale(0.4, 1),
        Text = "",
        TextColor3 = Theme.TextPrimary,
        TextSize = 14,
        FontFace = Theme.Font,
        Parent = rightWrapper,
    })
    New("UICorner", { CornerRadius = UDim.new(0, Theme.RadiusElement), Parent = searchBox })
    New("UIStroke", { Color = Theme.Border, Parent = searchBox })
    New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = searchBox })

    local sidebar = New("ScrollingFrame", {
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Base,
        CanvasSize = UDim2.fromScale(0, 0),
        Position = UDim2.fromOffset(0, 44),
        ScrollBarThickness = 0,
        Size = UDim2.new(0, sidebarWidth, 1, -44),
        Parent = main,
    })
    New("UIListLayout", { Parent = sidebar })

    local contentContainer = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = Theme.Surface,
        ClipsDescendants = true,
        Position = UDim2.new(1, 0, 0, 44),
        Size = UDim2.new(1, -sidebarWidth - 1, 1, -44),
        Parent = main,
    })
    New("UICorner", { CornerRadius = UDim.new(0, Theme.RadiusWindow), Parent = contentContainer })

    local divider = New("Frame", {
        BackgroundColor3 = Theme.Border,
        Position = UDim2.fromOffset(sidebarWidth, 44),
        Size = UDim2.new(0, 1, 1, -44),
        ZIndex = 2,
        Parent = main,
    })

    local footerBar = New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = Theme.Base,
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 28),
        Parent = main,
    })
    local footerLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = footer,
        TextColor3 = Theme.TextMuted,
        TextSize = 12,
        FontFace = Theme.Font,
        Parent = footerBar,
    })

    if resizable then
        local resizeBtn = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -Theme.RadiusWindow/2, 0, 0),
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Text = "",
            Parent = footerBar,
        })
        self:MakeResizable(main, resizeBtn, function()
            for _, tab in ipairs(windowObj._tabs) do
                for _, panel in ipairs(tab.Panels) do
                    panel:Resize()
                end
            end
        end)
        local resizeIcon = Library:GetIcon("move-diagonal-2")
        if resizeIcon then
            New("ImageLabel", {
                BackgroundTransparency = 1,
                Image = resizeIcon.Url,
                ImageColor3 = Theme.TextMuted,
                ImageRectOffset = resizeIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = resizeIcon.ImageRectSize or Vector2.zero,
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 1, -4),
                Parent = resizeBtn,
            })
        end
    end

    local windowObj = {
        Main = main,
        Sidebar = sidebar,
        ContentContainer = contentContainer,
        Divider = divider,
        TopBar = topBar,
        TitleLabel = titleLabel,
        FooterLabel = footerLabel,
        SearchBox = searchBox,
        TabInfo = tabInfo,
        TabTitle = tabTitle,
        TabDesc = tabDesc,
        _tabs = {},
        _activeTab = nil,
        _tabContainer = sidebar,
        _contentContainer = contentContainer,
        _compactSidebar = compactSidebar,
        _sidebarWidth = sidebarWidth,
    }

    function windowObj:ShowTabInfo(name, desc)
        tabTitle.Text = name
        tabDesc.Text = desc or ""
        tabInfo.Visible = true
        searchBox.Size = UDim2.fromScale(0.4, 1)
    end

    function windowObj:HideTabInfo()
        tabInfo.Visible = false
        searchBox.Size = UDim2.fromScale(1, 1)
    end

    function windowObj:AddTab(name, icon, description)
        local tab = CreateTab(windowObj, name, icon, description)
        table.insert(windowObj._tabs, tab)
        return tab
    end

    function windowObj:Toggle(force)
        if self._unloaded then return end
        local newState = (force ~= nil) and force or not self._toggled
        self._toggled = newState
        main.Visible = newState
        if newState and not Library._isMobile then
            local binding = tostring({})
            RunService:UnbindFromRenderStep(binding)
            RunService:BindToRenderStep(binding, Enum.RenderPriority.Last.Value, function()
                UserInputService.MouseIconEnabled = not Library._showCustomCursor
                Cursor.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
                Cursor.Visible = Library._showCustomCursor
                if not (Library._toggled and ScreenGui and ScreenGui.Parent) then
                    UserInputService.MouseIconEnabled = true
                    Cursor.Visible = false
                    RunService:UnbindFromRenderStep(binding)
                end
            end)
        elseif not newState then
            Cursor.Visible = false
            UserInputService.MouseIconEnabled = true
        end
        if currentContextMenu then currentContextMenu:Close() end
        TooltipLabel.Visible = false
    end

    function windowObj:SetSidebarWidth(width)
        width = math.clamp(width, 60, main.Size.X.Offset - 200)
        self._sidebarWidth = width
        sidebar.Size = UDim2.new(0, width, 1, -44)
        titleHolder.Size = UDim2.new(0, width, 1, 0)
        divider.Position = UDim2.fromOffset(width, 44)
        contentContainer.Size = UDim2.new(1, -width - 1, 1, -44)
    end

    function windowObj:Destroy()
        for _, tab in ipairs(self._tabs) do
            tab:Destroy()
        end
        main:Destroy()
        for i, w in ipairs(Library._windows) do
            if w == windowObj then table.remove(Library._windows, i) break end
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Library:UpdateSearch(searchBox.Text, windowObj)
    end)

    if info.AutoShow ~= false then
        task.spawn(function() windowObj:Toggle(true) end)
    end

    table.insert(Library._windows, windowObj)
    return windowObj
end

function Library:UpdateSearch(text, window)
    self._searchText = text
    local search = Trim(text):lower()
    if search == "" then
        self._searching = false
        self._lastSearchTab = nil
        for _, win in ipairs(self._windows) do
            if win == window or not window then
                for _, tab in ipairs(win._tabs) do
                    for _, panel in ipairs(tab.Panels) do
                    end
                end
            end
        end
        return
    end

    self._searching = true
    for _, win in ipairs(self._windows) do
        if win == window or not window then
            for _, tab in ipairs(win._tabs) do
                local found = false
                for _, panel in ipairs(tab.Panels) do
                    local visible = false
                    for _, elem in ipairs(panel.Elements) do
                        if elem.Text and elem.Text:lower():match(search) then
                            visible = true
                            break
                        end
                    end
                    panel.Panel.Visible = visible
                    if visible then found = true end
                end
            end
        end
    end
end

local function AddSwitch(panel, info)
    info = info or {}
    local label = info.Label or ""
    local desc = info.Description or ""
    local default = info.Default or false
    local callback = info.Callback or function() end
    local disabled = info.Disabled or false
    local visible = info.Visible ~= false

    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Visible = visible,
        Parent = panel.Content,
    })

    local labelWidget = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 1, 0),
        Text = label,
        TextColor3 = Theme.TextPrimary,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        FontFace = Theme.Font,
        Parent = holder,
    })
    if desc and desc ~= "" then
        labelWidget.Text = label .. "\n" .. desc
        labelWidget.TextSize = 13
        labelWidget.TextColor3 = Theme.TextSecondary
    end

    local switch = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Theme.Surface,
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(40, 22),
        Parent = holder,
    })
    New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = switch })
    New("UIStroke", { Color = Theme.Border, Parent = switch })

    local thumb = New("Frame", {
        BackgroundColor3 = Theme.TextMuted,
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.fromOffset(2, 2),
        Parent = switch,
    })
    New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = thumb })

    local switchObj = {
        Value = default,
        Disabled = disabled,
        Holder = holder,
        Switch = switch,
        Thumb = thumb,
        Callback = callback,
        Text = label,
    }

    function switchObj:SetValue(value)
        if self.Disabled then return end
        self.Value = value
        local offset = value and 20 or 2
        TweenService:Create(thumb, Library._tweenInfo, { Position = UDim2.fromOffset(offset, 2) }):Play()
        TweenService:Create(switch, Library._tweenInfo, {
            BackgroundColor3 = value and Theme.AccentStart or Theme.Surface,
        }):Play()
        self.Callback(value)
    end

    function switchObj:SetDisabled(state)
        self.Disabled = state
        holder.Active = not state
        switch.BackgroundColor3 = state and Theme.Base or Theme.Surface
        thumb.BackgroundColor3 = state and Theme.TextDisabled or Theme.TextMuted
    end

    function switchObj:SetVisible(state)
        holder.Visible = state
    end

    switch.MouseButton1Click:Connect(function()
        if not switchObj.Disabled then
            switchObj:SetValue(not switchObj.Value)
        end
    end)

    switchObj:SetValue(default)
    table.insert(panel.Elements, switchObj)
    panel:Resize()
    return switchObj
end

local function AddAction(panel, info)
    info = info or {}
    local label = info.Label or ""
    local callback = info.Callback or function() end
    local variant = info.Variant or "Primary"
    local disabled = info.Disabled or false
    local visible = info.Visible ~= false

    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
        Visible = visible,
        Parent = panel.Content,
    })

    local button = New("TextButton", {
        BackgroundColor3 = Theme.Surface,
        Size = UDim2.fromScale(1, 1),
        Text = label,
        TextColor3 = Theme.TextPrimary,
        TextSize = 14,
        FontFace = Theme.Font,
        AutoButtonColor = false,
        Parent = holder,
    })
    New("UICorner", { CornerRadius = UDim.new(0, Theme.RadiusElement), Parent = button })
    New("UIStroke", { Color = Theme.Border, Parent = button })

    local actionObj = {
        Text = label,
        Disabled = disabled,
        Holder = holder,
        Button = button,
        Callback = callback,
    }

    function actionObj:SetDisabled(state)
        self.Disabled = state
        button.Active = not state
        button.BackgroundColor3 = state and Theme.Base or Theme.Surface
        button.TextColor3 = state and Theme.TextDisabled or Theme.TextPrimary
    end

    function actionObj:SetVisible(state)
        holder.Visible = state
    end

    button.MouseEnter:Connect(function()
        if not self.Disabled then
            TweenService:Create(button, Library._tweenInfo, { BackgroundColor3 = Theme.Elevated }):Play()
        end
    end)
    button.MouseLeave:Connect(function()
        if not self.Disabled then
            TweenService:Create(button, Library._tweenInfo, { BackgroundColor3 = Theme.Surface }):Play()
        end
    end)
    button.MouseButton1Click:Connect(function()
        if not self.Disabled then
            callback()
        end
    end)

    table.insert(panel.Elements, actionObj)
    panel:Resize()
    return actionObj
end

local function AddRange(panel, info)
    info = info or {}
    local label = info.Label or ""
    local min = info.Min or 0
    local max = info.Max or 100
    local default = info.Default or min
    local step = info.Step or 1
    local suffix = info.Suffix or ""
    local callback = info.Callback or function() end
    local disabled = info.Disabled or false
    local visible = info.Visible ~= false

    local holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40),
        Visible = visible,
        Parent = panel.Content,
    })

    local labelWidget = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Text = label,
        TextColor3 = Theme.TextPrimary,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        FontFace = Theme.Font,
        Parent = holder,
    })

    local valueLabel = New("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.fromOffset(50, 16),
        Text = tostring(default) .. suffix,
        TextColor3 = Theme.TextSecondary,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        FontFace = Theme.Font,
        Parent = holder,
    })

    local track = New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = Theme.Surface,
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 6),
        Parent = holder,
    })
    New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

    local fill = New("Frame", {
        BackgroundColor3 = Theme.AccentStart,
        Size = UDim2.fromScale((default - min) / (max - min), 1),
        Parent = track,
    })
    New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

    local thumb = New("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.TextPrimary,
        Position = UDim2.fromScale((default - min) / (max - min), 0.5),
        Size = UDim2.fromOffset(16, 16),
        Text = "",
        Parent = track,
    })
    New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = thumb })
    New("UIStroke", { Color = Theme.Border, Parent = thumb })

    local rangeObj = {
        Value = default,
        Min = min,
        Max = max,
        Step = step,
        Suffix = suffix,
        Disabled = disabled,
        Holder = holder,
        Track = track,
        Fill = fill,
        Thumb = thumb,
        ValueLabel = valueLabel,
        Callback = callback,
        Text = label,
    }

    function rangeObj:SetValue(value)
        if self.Disabled then return end
        local clamped = math.clamp(value, self.Min, self.Max)
        if self.Step > 0 then
            clamped = math.floor(clamped / self.Step) * self.Step
        end
        self.Value = clamped
        local progress = (clamped - self.Min) / (self.Max - self.Min)
        TweenService:Create(fill, Library._tweenInfo, { Size = UDim2.fromScale(progress, 1) }):Play()
        TweenService:Create(thumb, Library._tweenInfo, { Position = UDim2.fromScale(progress, 0.5) }):Play()
        valueLabel.Text = tostring(clamped) .. self.Suffix
        self.Callback(clamped)
    end

    function rangeObj:SetDisabled(state)
        self.Disabled = state
        thumb.Active = not state
        track.BackgroundColor3 = state and Theme.Base or Theme.Surface
        thumb.BackgroundColor3 = state and Theme.TextDisabled or Theme.TextPrimary
    end

    function rangeObj:SetVisible(state)
        holder.Visible = state
    end

    local dragging = false
    thumb.InputBegan:Connect(function(input)
        if IsClickInput(input) and not rangeObj.Disabled then
            dragging = true
            local pos = input.Position
            local trackPos = track.AbsolutePosition
            local trackSize = track.AbsoluteSize
            local progress = math.clamp((pos.X - trackPos.X) / trackSize.X, 0, 1)
            local value = min + (max - min) * progress
            rangeObj:SetValue(value)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and IsMovementInput(input) then
            local pos = input.Position
            local trackPos = track.AbsolutePosition
            local trackSize = track.AbsoluteSize
            local progress = math.clamp((pos.X - trackPos.X) / trackSize.X, 0, 1)
            local value = min + (max - min) * progress
            rangeObj:SetValue(value)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if dragging and IsMouseInput(input) then
            dragging = false
        end
    end)

    table.insert(panel.Elements, rangeObj)
    panel:Resize()
    return rangeObj
end

local function AddSelect(panel, info) end
local function AddInput(panel, info) end
local function AddColorPicker(panel, info) end
local function AddHotkey(panel, info) end
local function AddImage(panel, info) end
local function AddVideo(panel, info) end
local function AddViewport(panel, info) end
local function AddUIPassthrough(panel, info) end

local PanelMethods = {
    AddSwitch = AddSwitch,
    AddAction = AddAction,
    AddRange = AddRange,
    AddSelect = AddSelect,
    AddInput = AddInput,
    AddColorPicker = AddColorPicker,
    AddHotkey = AddHotkey,
    AddImage = AddImage,
    AddVideo = AddVideo,
    AddViewport = AddViewport,
    AddUIPassthrough = AddUIPassthrough,
}

function Library:PlayTabAnimation(canvas, showing, onComplete)
    if not canvas then if onComplete then onComplete() end return end
    if not self._animations.Tab then
        canvas.Visible = showing
        canvas.GroupTransparency = showing and 0 or 1
        canvas.Position = UDim2.fromScale(0, 0)
        if onComplete then onComplete() end
        return
    end

    if showing then
        local offset = self._tabSwipeOffset
        local from = self._tabSwipeFrom
        local startPos
        if from == "left" then startPos = UDim2.fromOffset(-offset, 0)
        elseif from == "top" then startPos = UDim2.fromOffset(0, -offset)
        elseif from == "right" then startPos = UDim2.fromOffset(offset, 0)
        else startPos = UDim2.fromOffset(0, offset) end
        canvas.GroupTransparency = 1
        canvas.Position = startPos
        canvas.Visible = true
        TweenService:Create(canvas, self._tabTransitionInfo, {
            GroupTransparency = 0,
            Position = UDim2.fromScale(0, 0),
        }):Play()
    else
        canvas.GroupTransparency = 1
        canvas.Visible = false
        canvas.Position = UDim2.fromScale(0, 0)
        if onComplete then onComplete() end
    end
end

function Library:CreateLoading(info)
    info = info or {}
    local title = info.Title or "Loading"
    local icon = info.Icon
    local totalSteps = info.TotalSteps or 10
    local currentStep = info.CurrentStep or 0

    if self._activeLoading then
        warn("Loading already exists")
        return self._activeLoading
    end

    local screen = New("ScreenGui", {
        Name = "Loading",
        DisplayOrder = 999,
        ResetOnSpawn = false,
    })
    ParentUI(screen)

    local main = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Window,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(400, 200),
        Parent = screen,
    })
    New("UICorner", { CornerRadius = UDim.new(0, Theme.RadiusWindow), Parent = main })
    New("UIStroke", { Color = Theme.Border, Parent = main })
    table.insert(self._scales, New("UIScale", { Parent = main }))

    local container = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 1, -24),
        Position = UDim2.fromOffset(12, 12),
        Parent = main,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 12),
        Parent = container,
    })

    if icon then
        local iconData = Library:GetCustomIcon(icon)
        if iconData then
            New("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(48, 48),
                Image = iconData.Url,
                ImageColor3 = Theme.AccentStart,
                ImageRectOffset = iconData.ImageRectOffset or Vector2.zero,
                ImageRectSize = iconData.ImageRectSize or Vector2.zero,
                Parent = container,
            })
        end
    end

    local titleLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.TextPrimary,
        TextSize = 20,
        FontFace = Theme.Font,
        Parent = container,
    })

    local progressBar = New("Frame", {
        BackgroundColor3 = Theme.Surface,
        Size = UDim2.new(0.8, 0, 0, 8),
        Parent = container,
    })
    New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = progressBar })

    local fill = New("Frame", {
        BackgroundColor3 = Theme.AccentStart,
        Size = UDim2.fromScale(0, 1),
        Parent = progressBar,
    })
    New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

    local stepLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Text = "0/" .. totalSteps,
        TextColor3 = Theme.TextSecondary,
        TextSize = 14,
        FontFace = Theme.Font,
        Parent = container,
    })

    local loadingObj = {
        ScreenGui = screen,
        Main = main,
        Fill = fill,
        StepLabel = stepLabel,
        TotalSteps = totalSteps,
        CurrentStep = currentStep,
        Destroyed = false,
    }

    function loadingObj:SetCurrentStep(step)
        self.CurrentStep = math.clamp(step, 0, self.TotalSteps)
        local progress = self.CurrentStep / self.TotalSteps
        TweenService:Create(fill, Library._tweenInfo, { Size = UDim2.fromScale(progress, 1) }):Play()
        stepLabel.Text = self.CurrentStep .. "/" .. self.TotalSteps
    end

    function loadingObj:SetTotalSteps(steps)
        self.TotalSteps = steps
        self:SetCurrentStep(self.CurrentStep)
    end

    function loadingObj:Destroy()
        if self.Destroyed then return end
        self.Destroyed = true
        screen:Destroy()
        Library._activeLoading = nil
        if Library._toggled ~= nil then
            Library:Toggle(true)
        end
    end

    loadingObj.Continue = loadingObj.Destroy

    Library._activeLoading = loadingObj
    if Library._toggled then Library:Toggle(false) end
    loadingObj:SetCurrentStep(currentStep)
    return loadingObj
end

function Library:CreateDialog(info)
    info = info or {}
    local title = info.Title or "Dialog"
    local description = info.Description or ""
    local buttons = info.Buttons or {}
    local autoDismiss = info.AutoDismiss ~= false
    local outsideDismiss = info.OutsideClickDismiss ~= false

    local overlay = New("TextButton", {
        BackgroundColor3 = Theme.Shadow,
        BackgroundTransparency = 0.5,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        ZIndex = 9000,
        Parent = ScreenGui,
    })
    local dialogFrame = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Window,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(400, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 9001,
        Parent = overlay,
    })
    New("UICorner", { CornerRadius = UDim.new(0, Theme.RadiusWindow), Parent = dialogFrame })
    New("UIStroke", { Color = Theme.Border, Parent = dialogFrame })

    local container = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = dialogFrame,
    })
    New("UIPadding", { PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 16), Parent = container })
    New("UIListLayout", { Padding = UDim.new(0, 8), Parent = container })

    local titleLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Text = title,
        TextColor3 = Theme.TextPrimary,
        TextSize = 18,
        FontFace = Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })

    local descLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = description,
        TextColor3 = Theme.TextSecondary,
        TextSize = 14,
        FontFace = Theme.Font,
        TextWrapped = true,
        Parent = container,
    })

    local buttonHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = container,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = buttonHolder,
    })

    local dialogObj = {
        Overlay = overlay,
        Frame = dialogFrame,
        Container = container,
        TitleLabel = titleLabel,
        DescLabel = descLabel,
        ButtonHolder = buttonHolder,
        Buttons = {},
        Destroyed = false,
    }

    function dialogObj:AddButton(text, callback, variant)
        variant = variant or "Primary"
        local btn = New("TextButton", {
            BackgroundColor3 = Theme.Surface,
            Size = UDim2.fromOffset(80, 30),
            Text = text,
            TextColor3 = Theme.TextPrimary,
            TextSize = 14,
            FontFace = Theme.Font,
            AutoButtonColor = false,
            Parent = buttonHolder,
        })
        New("UICorner", { CornerRadius = UDim.new(0, Theme.RadiusElement), Parent = btn })
        New("UIStroke", { Color = Theme.Border, Parent = btn })

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, Library._tweenInfo, { BackgroundColor3 = Theme.Elevated }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, Library._tweenInfo, { BackgroundColor3 = Theme.Surface }):Play()
        end)
        btn.MouseButton1Click:Connect(function()
            if callback then callback(dialogObj) end
            if autoDismiss then dialogObj:Dismiss() end
        end)
        table.insert(dialogObj.Buttons, btn)
        return btn
    end

    function dialogObj:Dismiss()
        if self.Destroyed then return end
        self.Destroyed = true
        if Library._activeDialog == self then Library._activeDialog = nil end
        overlay:Destroy()
    end

    for _, btnInfo in ipairs(buttons) do
        dialogObj:AddButton(btnInfo.Text, btnInfo.Callback, btnInfo.Variant)
    end

    overlay.MouseButton1Click:Connect(function()
        if outsideDismiss then dialogObj:Dismiss() end
    end)

    Library._activeDialog = dialogObj
    return dialogObj
end

function Library:CreateWatermark(info)
    info = info or {}
    local text = info.Text or "Watermark"
    local icon = info.Icon
    local visible = info.Visible ~= false

    local label = New("TextLabel", {
        BackgroundColor3 = Theme.Window,
        Size = UDim2.fromOffset(0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        Text = text,
        TextColor3 = Theme.TextPrimary,
        TextSize = 14,
        FontFace = Theme.Font,
        ZIndex = 10,
        Parent = ScreenGui,
    })
    New("UICorner", { CornerRadius = UDim.new(0, Theme.RadiusElement), Parent = label })
    New("UIStroke", { Color = Theme.Border, Parent = label })
    New("UIPadding", { PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), Parent = label })
    table.insert(Library._scales, New("UIScale", { Parent = label }))

    if icon then
        local iconData = Library:GetCustomIcon(icon)
        if iconData then
            New("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(16, 16),
                Image = iconData.Url,
                ImageColor3 = Theme.AccentStart,
                ImageRectOffset = iconData.ImageRectOffset or Vector2.zero,
                ImageRectSize = iconData.ImageRectSize or Vector2.zero,
                Position = UDim2.fromOffset(6, 6),
                Parent = label,
            })
        end
    end

    self:MakeDraggable(label, label, true)
    table.insert(self._draggableElements, label)
    PositionDraggable(label)

    local watermark = {
        Label = label,
        Visible = visible,
    }

    function watermark:SetText(newText)
        label.Text = newText
        label:GetPropertyChangedSignal("Text"):Wait()
        label.Size = UDim2.fromOffset(0, 0)
    end

    function watermark:SetVisible(state)
        label.Visible = state
    end

    function watermark:Destroy()
        label:Destroy()
        local idx = table.find(Library._draggableElements, label)
        if idx then table.remove(Library._draggableElements, idx) end
    end

    return watermark
end

function Library:SetDPIScale(scale)
    self._dpiScale = scale / 100
    self._minSize = self._originalMinSize * self._dpiScale
    for _, uiScale in ipairs(self._scales) do
        uiScale.Scale = self._dpiScale - (tonumber(self._scalesOffset[uiScale]) or 0)
    end
end

function Library:GiveSignal(signal)
    if signal and (typeof(signal) == "RBXScriptConnection" or typeof(signal) == "RBXScriptSignal") then
        table.insert(self._signals, signal)
    end
    return signal
end

function Library:OnUnload(callback)
    table.insert(self._unloadCallbacks, callback)
end

function Library:Unload()
    if self._unloaded then return end
    self._unloaded = true

    for _, conn in ipairs(self._signals) do
        if conn.Connected then conn:Disconnect() end
    end
    self._signals = {}

    for _, cb in ipairs(self._unloadCallbacks) do
        cb()
    end
    self._unloadCallbacks = {}

    for _, win in ipairs(self._windows) do
        win:Destroy()
    end
    self._windows = {}

    if self._activeLoading then self._activeLoading:Destroy() end

    for _, d in ipairs(self._dialogs) do
        if d and not d.Destroyed then d:Dismiss() end
    end

    if ScreenGui then ScreenGui:Destroy() end

    table.clear(self._registry)
    table.clear(self._scales)
    table.clear(self._scalesOffset)
    table.clear(self._corners)
    table.clear(self._specificCorners)
    table.clear(self._notifications)
    table.clear(self._notifyOrder)
    table.clear(self._draggableElements)
    table.clear(self._dependencyBoxes)

    self._tabs = {}
    self._tabButtons = {}

    getgenv().Library = nil
end

UserInputService.WindowFocused:Connect(function()
    Library._isFocused = true
end)
UserInputService.WindowFocusReleased:Connect(function()
    Library._isFocused = false
end)

UserInputService.InputBegan:Connect(function(input)
    if Library._unloaded then return end
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Library._toggleKeybind then
        for _, win in ipairs(Library._windows) do
            win:Toggle()
        end
    end
end)

return Library
