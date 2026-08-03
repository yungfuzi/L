local Library = {
	Version = "1.0.0",

	Animations = true,
	ToggleKey = Enum.KeyCode.RightShift,

	Flags = {},
	Options = {},

	Scheme = {},
	Icons = {},

	ScreenGui = nil,
	Window = nil,

	Tabs = {},
	TabButtons = {},

	Notifications = {},
	OpenPopups = {},
	Tooltips = {},

	Windows = {},
	DependencyBoxes = {},

	Connections = {},
	UnloadCallbacks = {},
	Registry = {},
	Corners = {},
	SpecificCorners = {},

	ActiveTab = nil,
	SearchText = "",
	Searching = false,

	CornerRadius = 16,
	MinSize = Vector2.new(500, 400),

	NotifySide = "Right",
	NotifyTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

	Toggled = false,
	Unloaded = false,
	Destroyed = false,

	IsRobloxFocused = true,
	CantDragForced = false,
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = LocalPlayer:GetMouse()

Library.LocalPlayer = LocalPlayer

Library.Scheme = {
	Background = Color3.fromRGB(255, 255, 255),
	SidebarColor = Color3.fromRGB(100, 100, 100),
	MainColor = Color3.fromRGB(243, 243, 243),
	AccentColor = Color3.fromRGB(0, 122, 255),
	OutlineColor = Color3.fromRGB(215, 215, 215),
	FontColor = Color3.fromRGB(30, 30, 30),
	TitleColor = Color3.fromRGB(20, 20, 20),
	DestructiveColor = Color3.fromRGB(220, 38, 38),
	RedColor = Color3.fromRGB(255, 50, 50),
	DarkColor = Color3.new(0, 0, 0),
	WhiteColor = Color3.new(1, 1, 1),
	Font = Font.fromEnum(Enum.Font.GothamMedium),
}

Library.Icons = {
	["ChevronRight"] = "rbxassetid://101007429951147",
}

Library.Animation = {
	Default = {
		Duration = 0.3,
		EasingStyle = Enum.EasingStyle.Quint,
		EasingDirection = Enum.EasingDirection.Out,
		RepeatCount = 0,
		Reverses = false,
		DelayTime = 0,
	},
	Presets = {
		Fast = {
			Duration = 0.15,
			EasingStyle = Enum.EasingStyle.Quad,
			EasingDirection = Enum.EasingDirection.Out,
		},
		Smooth = {
			Duration = 0.4,
			EasingStyle = Enum.EasingStyle.Quint,
			EasingDirection = Enum.EasingDirection.Out,
		},
		Bounce = {
			Duration = 0.5,
			EasingStyle = Enum.EasingStyle.Back,
			EasingDirection = Enum.EasingDirection.Out,
		},
		Linear = {
			Duration = 0.25,
			EasingStyle = Enum.EasingStyle.Linear,
			EasingDirection = Enum.EasingDirection.InOut,
		},
		Spring = {
			Duration = 0.6,
			EasingStyle = Enum.EasingStyle.Elastic,
			EasingDirection = Enum.EasingDirection.Out,
		},
	},
}

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
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = "OutlineColor",
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
		Title = "Aero",
		SubTitle = "",
		Size = UDim2.fromOffset(700, 450),
		MinSize = UDim2.fromOffset(500, 400),
		MaxSize = UDim2.fromOffset(9999, 9999),
		UiCorner = UDim.new(0, 16),
		Draggable = true,
		Resizable = true,
		LockResize = false,
		AutoShow = true,
		ToggleKey = Enum.KeyCode.RightShift,
		Animations = {
			TabSwitch = true,
			ToggleWindow = true,
		},
	},

	Button = {
		Text = "Button",
		Callback = function() end,
		Risky = false,
		Disabled = false,
		Visible = true,
		Tooltip = nil,
	},

	Toggle = {
		Text = "Toggle",
		Default = false,
		Callback = function() end,
		Changed = function() end,
		Risky = false,
		Disabled = false,
		Visible = true,
		Tooltip = nil,
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
	},

	Dropdown = {
		Text = "Dropdown",
		Values = {},
		Default = nil,
		Multi = false,
		MaxVisible = 8,
		Callback = function() end,
		Changed = function() end,
		Disabled = false,
		Visible = true,
	},

	Textbox = {
		Text = "Textbox",
		Default = "",
		Numeric = false,
		Placeholder = "",
		Finished = false,
		ClearTextOnFocus = true,
		Callback = function() end,
		Changed = function() end,
		Disabled = false,
		Visible = true,
	},

	ColorPicker = {
		Default = Color3.new(1, 1, 1),
		Transparency = false,
		Callback = function() end,
		Changed = function() end,
	},

	Keybind = {
		Text = "Keybind",
		Default = "None",
		Mode = "Toggle",
		Callback = function() end,
		Changed = function() end,
	},
}

local NotifyOrder = {}

local function GetTableSize(Table)
	local Size = 0
	for _ in Table do
		Size += 1
	end
	return Size
end

local function Trim(Text)
	return Text:match("^%s*(.-)%s*$")
end

local function Round(Value, Rounding)
	if Rounding <= 0 then
		return math.floor(Value)
	end
	return tonumber(string.format("%." .. Rounding .. "f", Value))
end

local function StopTween(Tween)
	if Tween and Tween.PlaybackState == Enum.PlaybackState.Playing then
		Tween:Cancel()
	end
end

local function WaitForEvent(Event, Timeout)
	local Bindable = Instance.new("BindableEvent")
	local Connection = Event:Once(function()
		Bindable:Fire(true)
	end)
	task.delay(Timeout, function()
		Connection:Disconnect()
		Bindable:Fire(false)
	end)
	local Result = Bindable.Event:Wait()
	Bindable:Destroy()
	return Result
end

local function IsMouseInput(Input)
	return Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.MouseButton2
		or Input.UserInputType == Enum.UserInputType.MouseButton3
		or Input.UserInputType == Enum.UserInputType.Touch
end

local function IsClickInput(Input)
	return (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch)
		and Input.UserInputState == Enum.UserInputState.Begin
		and Library.IsRobloxFocused
end

local function IsHoverInput(Input)
	return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
		and Input.UserInputState == Enum.UserInputState.Change
end

local function IsDragInput(Input)
	return (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch)
		and (Input.UserInputState == Enum.UserInputState.Begin or Input.UserInputState == Enum.UserInputState.Change)
		and Library.IsRobloxFocused
end

local function IsMovementInput(Input)
	return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
		and Library.IsRobloxFocused
end

local function GetSchemeValue(Index)
	if typeof(Index) == "string" then
		local Value = Library.Scheme[Index]
		if Value ~= nil then
			return Value
		end
	end
	return nil
end

function Library:GetIcon(name)
	if typeof(name) == "string" then
		if name:match("^rbxassetid://") or name:match("^rbxasset://") or name:match("^rbxthumb://") then
			return name
		end
		return self.Icons[name] or name
	end
	return name
end

function Library:Validate(Table, Template)
	if typeof(Table) ~= "table" then
		return Template
	end

	for Key, Value in Template do
		if typeof(Key) == "number" then
			continue
		end

		if typeof(Value) == "table" then
			Table[Key] = Library:Validate(Table[Key], Value)
		elseif Table[Key] == nil then
			Table[Key] = Value
		end
	end

	return Table
end

function Library:AddToRegistry(Instance, Properties)
	Library.Registry[Instance] = Properties
end

function Library:RemoveFromRegistry(Instance)
	Library.Registry[Instance] = nil
end

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

function Library:GetLighterColor(Color)
	local H, S, V = Color:ToHSV()
	return Color3.fromHSV(H, math.max(0, S - 0.1), math.min(1, V + 0.1))
end

function Library:GetDarkerColor(Color)
	local H, S, V = Color:ToHSV()
	return Color3.fromHSV(H, S, V / 2)
end

function Library:GetBetterColor(Color, Add)
	return Color3.fromRGB(
		math.clamp(Color.R * 255 + Add, 0, 255),
		math.clamp(Color.G * 255 + Add, 0, 255),
		math.clamp(Color.B * 255 + Add, 0, 255)
	)
end

function Library:GetTextBounds(Text, FontFace, Size, Width)
	local Params = Instance.new("GetTextBoundsParams")
	Params.Text = Text
	Params.Font = FontFace
	Params.Size = Size
	Params.Width = Width or 10000

	local Bounds = TextService:GetTextBoundsAsync(Params)
	return Bounds.X, Bounds.Y
end

function Library:MouseIsOverFrame(Frame, MousePosition)
	local AbsPos = Frame.AbsolutePosition
	local AbsSize = Frame.AbsoluteSize
	return MousePosition.X >= AbsPos.X
		and MousePosition.X <= AbsPos.X + AbsSize.X
		and MousePosition.Y >= AbsPos.Y
		and MousePosition.Y <= AbsPos.Y + AbsSize.Y
end

function Library:SafeCallback(Func, ...)
	if not (Func and typeof(Func) == "function") then
		return
	end

	local Result = table.pack(xpcall(Func, function(Error)
		task.defer(error, debug.traceback(Error, 2))
		return Error
	end, ...))

	if not Result[1] then
		return nil
	end

	return table.unpack(Result, 2, Result.n)
end

function Library:GetAnimationInfo(styleName, extraOptions)
	extraOptions = extraOptions or {}

	local config = {}
	for k, v in pairs(self.Animation.Default) do
		config[k] = v
	end

	if styleName and self.Animation.Presets[styleName] then
		for k, v in pairs(self.Animation.Presets[styleName]) do
			config[k] = v
		end
	end

	if extraOptions.Duration then config.Duration = extraOptions.Duration end
	if extraOptions.EasingStyle then config.EasingStyle = extraOptions.EasingStyle end
	if extraOptions.EasingDirection then config.EasingDirection = extraOptions.EasingDirection end
	if extraOptions.RepeatCount then config.RepeatCount = extraOptions.RepeatCount end
	if extraOptions.Reverses ~= nil then config.Reverses = extraOptions.Reverses end
	if extraOptions.DelayTime then config.DelayTime = extraOptions.DelayTime end

	return TweenInfo.new(
		config.Duration,
		config.EasingStyle,
		config.EasingDirection,
		config.RepeatCount,
		config.Reverses,
		config.DelayTime
	)
end

function Library:Tween(instance, properties, options)
	if type(options) == "string" then
		options = { Style = options }
	else
		options = options or {}
	end

	if not self.Animations then
		for prop, value in pairs(properties) do
			instance[prop] = value
		end
		if options.Callback then
			task.spawn(options.Callback)
		end
		return nil
	end

	local tween = TweenService:Create(instance, self:GetAnimationInfo(options.Style, options), properties)

	if options.Callback then
		tween.Completed:Connect(function()
			options.Callback()
		end)
	end

	tween:Play()
	return tween
end

function Library:TweenStyle(instance, properties, styleName, extraOptions)
	extraOptions = extraOptions or {}
	extraOptions.Style = styleName
	return self:Tween(instance, properties, extraOptions)
end

function Library:GiveSignal(Connection)
	if Connection and typeof(Connection) == "RBXScriptConnection" then
		table.insert(Library.Connections, Connection)
	end
	return Connection
end

function Library:OnUnload(Callback)
	table.insert(Library.UnloadCallbacks, Callback)
end

local function FillInstance(Properties, Instance)
	local ThemeProperties = Library.Registry[Instance] or {}

	for key, value in Properties do
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

local InstanceCounters = {}

local function New(ClassName, Properties)
	Properties = Properties or {}

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

	if not Properties["Name"] then
		InstanceCounters[ClassName] = (InstanceCounters[ClassName] or 0) + 1
		Instance.Name = string.format("%s_%d", ClassName, InstanceCounters[ClassName])
	end

	return Instance
end

local function AddUICorner(Frame, Radius, StoreSpecific)
	local Ratio = (Radius or Library.CornerRadius) / Library.CornerRadius
	local Corner = New("UICorner", {
		CornerRadius = UDim.new(0, Radius or Library.CornerRadius),
		Parent = Frame,
	})

	if StoreSpecific then
		table.insert(Library.SpecificCorners, { Corner = Corner, Ratio = Ratio })
	else
		table.insert(Library.Corners, { Corner = Corner, Ratio = Ratio })
	end

	return Corner
end

function Library:AddOutline(Frame)
	local Outline = New("UIStroke", {
		Color = "OutlineColor",
		Thickness = 1,
		Parent = Frame,
	})
	local Shadow = New("UIStroke", {
		Color = "DarkColor",
		Thickness = 1.5,
		Parent = Frame,
	})
	return Outline, Shadow
end

function Library:MakeLine(Frame, Info)
	local Line = New("Frame", {
		AnchorPoint = Info.AnchorPoint or Vector2.zero,
		BackgroundColor3 = "OutlineColor",
		Position = Info.Position,
		Size = Info.Size,
		ZIndex = Info.ZIndex or Frame.ZIndex,
		Parent = Frame,
	})
	return Line
end

function Library:MakeDraggable(UI, DragFrame, IsMainWindow)
	local StartPos, FramePos, Dragging = nil, nil, false
	local Changed, InputBegan, InputChanged

	InputBegan = DragFrame.InputBegan:Connect(function(Input)
		if not IsClickInput(Input) then
			return
		end
		if IsMainWindow and Library.CantDragForced then
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
			if Changed then
				Changed:Disconnect()
				Changed = nil
			end
		end)
	end)

	InputChanged = UserInputService.InputChanged:Connect(function(Input)
		if IsMainWindow and Library.CantDragForced then
			Dragging = false
			if Changed then
				Changed:Disconnect()
				Changed = nil
			end
			return
		end

		if Dragging and IsHoverInput(Input) then
			local Delta = Input.Position - StartPos
			UI.Position = UDim2.new(
				FramePos.X.Scale,
				FramePos.X.Offset + Delta.X,
				FramePos.Y.Scale,
				FramePos.Y.Offset + Delta.Y
			)
		end
	end)

	Library:GiveSignal(InputBegan)
	Library:GiveSignal(InputChanged)

	UI.Destroying:Once(function()
		if InputBegan and InputBegan.Connected then InputBegan:Disconnect() end
		if InputChanged and InputChanged.Connected then InputChanged:Disconnect() end
		if Changed and Changed.Connected then Changed:Disconnect() end
	end)
end

function Library:MakeResizable(UI, DragFrame, Callback)
	local StartPos, FrameSize, Dragging = nil, nil, false
	local Changed, InputBegan, InputChanged

	InputBegan = DragFrame.InputBegan:Connect(function(Input)
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
			if Changed then
				Changed:Disconnect()
				Changed = nil
			end
		end)
	end)

	InputChanged = UserInputService.InputChanged:Connect(function(Input)
		if not UI.Visible then
			Dragging = false
			return
		end

		if Dragging and IsHoverInput(Input) then
			local Delta = Input.Position - StartPos
			UI.Size = UDim2.new(
				FrameSize.X.Scale,
				math.max(FrameSize.X.Offset + Delta.X, Library.MinSize.X),
				FrameSize.Y.Scale,
				math.max(FrameSize.Y.Offset + Delta.Y, Library.MinSize.Y)
			)
			if Callback then
				Library:SafeCallback(Callback)
			end
		end
	end)

	Library:GiveSignal(InputBegan)
	Library:GiveSignal(InputChanged)

	UI.Destroying:Once(function()
		if InputBegan and InputBegan.Connected then InputBegan:Disconnect() end
		if InputChanged and InputChanged.Connected then InputChanged:Disconnect() end
		if Changed and Changed.Connected then Changed:Disconnect() end
	end)
end

local ScreenGui = New("ScreenGui", {
	Name = "Aero",
	DisplayOrder = 998,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
Library.ScreenGui = ScreenGui

ScreenGui.DescendantRemoving:Connect(function(Instance)
	Library:RemoveFromRegistry(Instance)
end)

local NotificationArea = New("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	BackgroundTransparency = 1,
	Name = "NotificationArea",
	Position = UDim2.new(1, -6, 0, 6),
	Size = UDim2.new(0, 300, 1, -6),
	Parent = ScreenGui,
})

local TooltipLabel = New("TextLabel", {
	AnchorPoint = Vector2.new(0, 0.5),
	AutomaticSize = Enum.AutomaticSize.XY,
	BackgroundColor3 = Color3.fromRGB(45, 45, 45),
	Name = "TooltipLabel",
	Size = UDim2.fromOffset(0, 0),
	Text = "",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 13,
	Visible = false,
	ZIndex = 100,
	Parent = ScreenGui,
})
New("UIPadding", {
	Name = "TooltipPadding",
	PaddingBottom = UDim.new(0, 4),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
	PaddingTop = UDim.new(0, 4),
	Parent = TooltipLabel,
})
AddUICorner(TooltipLabel, 6)
New("UIStroke", {
	Color = Color3.fromRGB(20, 20, 20),
	Name = "TooltipOutline",
	Parent = TooltipLabel,
})

local ActiveTabTweens = setmetatable({}, { __mode = "k" })

function Library:PlayTabAnimation(Canvas, Showing)
	if not Canvas then
		return
	end

	local Existing = ActiveTabTweens[Canvas]
	if Existing then
		StopTween(Existing)
		ActiveTabTweens[Canvas] = nil
	end

	if not self.Animations then
		Canvas.Visible = Showing
		Canvas.GroupTransparency = Showing and 0 or 1
		return
	end

	if Showing then
		Canvas.Visible = true
		Canvas.GroupTransparency = 1

		local Tween = self:Tween(Canvas, { GroupTransparency = 0 }, { Style = "Smooth", Duration = 0.25 })
		ActiveTabTweens[Canvas] = Tween
		if Tween then
			Tween.Completed:Connect(function()
				if ActiveTabTweens[Canvas] == Tween then
					ActiveTabTweens[Canvas] = nil
				end
			end)
		end
	else
		Canvas.GroupTransparency = 1
		Canvas.Visible = false
	end
end

function Library:AddTooltip(Info, DisabledInfo, HoverInstance)
	local Tooltip = {
		Signals = {},
		Disabled = false,
		Destroyed = false,
	}

	local function Show()
		if Tooltip.Destroyed then
			return
		end
		if Tooltip.Disabled and typeof(DisabledInfo) ~= "string" then
			return
		end
		TooltipLabel.Text = Tooltip.Disabled and DisabledInfo or Info
		TooltipLabel.Visible = true
	end

	local function Hide()
		TooltipLabel.Visible = false
	end

	table.insert(Tooltip.Signals, HoverInstance.MouseEnter:Connect(Show))
	table.insert(Tooltip.Signals, HoverInstance.MouseLeave:Connect(Hide))
	table.insert(Tooltip.Signals, HoverInstance.MouseMoved:Connect(function(x, y)
		TooltipLabel.Position = UDim2.fromOffset(x + 14, y + 10)
	end))

	function Tooltip:SetDisabled(Disabled)
		Tooltip.Disabled = Disabled
	end

	function Tooltip:Destroy()
		Tooltip.Destroyed = true
		for Index = #Tooltip.Signals, 1, -1 do
			local Signal = table.remove(Tooltip.Signals, Index)
			if Signal and Signal.Connected then
				Signal:Disconnect()
			end
		end
	end

	table.insert(Library.Tooltips, Tooltip)
	return Tooltip
end

function Library:AddPopup(Holder, Size, Offset, OnActive, CornerRadius)
	local Popup = New("Frame", {
		BackgroundColor3 = "Background",
		Size = typeof(Size) == "function" and Size() or Size,
		Visible = false,
		ZIndex = 50,
		Parent = ScreenGui,
	})
	AddUICorner(Popup, CornerRadius or Library.CornerRadius - 4)
	New("UIStroke", {
		Color = "OutlineColor",
		Parent = Popup,
	})

	local PopupObject = {
		Connections = {},
		Destroyed = false,

		Active = false,
		Holder = Holder,
		Popup = Popup,
		Size = Size,
		Offset = Offset,
		OnActive = OnActive,

		OpenCloseTween = nil,
		PositionSignal = nil,
	}

	local function UpdatePosition()
		local Offset = typeof(PopupObject.Offset) == "function" and PopupObject.Offset() or PopupObject.Offset
		Popup.Position = UDim2.fromOffset(
			math.floor(Holder.AbsolutePosition.X + Offset[1]),
			math.floor(Holder.AbsolutePosition.Y + Offset[2])
		)
	end

	function PopupObject:Open()
		if PopupObject.Destroyed or PopupObject.Active then
			return
		end

		for Other, _ in Library.OpenPopups do
			if Other ~= PopupObject then
				Other:Close()
			end
		end
		Library.OpenPopups[PopupObject] = true
		PopupObject.Active = true

		UpdatePosition()
		Popup.Visible = true

		local TargetSize = typeof(PopupObject.Size) == "function" and PopupObject.Size() or PopupObject.Size

		if PopupObject.OnActive then
			Library:SafeCallback(PopupObject.OnActive, true)
		end

		if PopupObject.OpenCloseTween then
			StopTween(PopupObject.OpenCloseTween)
			PopupObject.OpenCloseTween = nil
		end

		if Library.Animations then
			Popup.Size = UDim2.new(TargetSize.X.Scale, TargetSize.X.Offset, 0, 0)
			PopupObject.OpenCloseTween = Library:Tween(Popup, { Size = TargetSize }, { Style = "Smooth" })
		else
			Popup.Size = TargetSize
		end

		PopupObject.PositionSignal = Holder:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdatePosition)
	end

	function PopupObject:Close()
		if PopupObject.Destroyed or not PopupObject.Active then
			return
		end

		Library.OpenPopups[PopupObject] = nil
		PopupObject.Active = false

		if PopupObject.PositionSignal then
			PopupObject.PositionSignal:Disconnect()
			PopupObject.PositionSignal = nil
		end

		if PopupObject.OnActive then
			Library:SafeCallback(PopupObject.OnActive, false)
		end

		if PopupObject.OpenCloseTween then
			StopTween(PopupObject.OpenCloseTween)
			PopupObject.OpenCloseTween = nil
		end

		if Library.Animations then
			local Current = Popup.Size
			PopupObject.OpenCloseTween = Library:Tween(Popup, {
				Size = UDim2.new(Current.X.Scale, Current.X.Offset, 0, 0),
			}, { Style = "Fast", Callback = function()
				Popup.Visible = false
			end })
		else
			Popup.Visible = false
		end
	end

	function PopupObject:Toggle()
		if PopupObject.Active then
			PopupObject:Close()
		else
			PopupObject:Open()
		end
	end

	function PopupObject:SetSize(NewSize)
		PopupObject.Size = NewSize
		Popup.Size = typeof(NewSize) == "function" and NewSize() or NewSize
	end

	function PopupObject:Destroy()
		PopupObject.Destroyed = true

		Library.OpenPopups[PopupObject] = nil
		PopupObject.Active = false

		if PopupObject.PositionSignal then
			PopupObject.PositionSignal:Disconnect()
			PopupObject.PositionSignal = nil
		end
		if PopupObject.OpenCloseTween then
			StopTween(PopupObject.OpenCloseTween)
			PopupObject.OpenCloseTween = nil
		end
		if Popup then
			Popup:Destroy()
		end
	end

	return PopupObject
end

function Library:UpdateNotificationPositions(Snap)
	local IsLeft = Library.NotifySide:lower() == "left"
	local XOffset = IsLeft and 0 or 0
	local RunningY = 0

	for _, FakeBackground in NotifyOrder do
		local Data = Library.Notifications[FakeBackground]
		if not (Data and FakeBackground.Parent) then
			continue
		end

		local Target = UDim2.fromOffset(XOffset, RunningY)
		if Snap or not Data.PositionInitialized then
			FakeBackground.Position = Target
			Data.PositionInitialized = true
		elseif FakeBackground.Position ~= Target then
			Library:Tween(FakeBackground, { Position = Target }, { Style = "Fast" })
		end

		RunningY = RunningY + FakeBackground.AbsoluteSize.Y + 8
	end
end

function Library:SetNotifySide(Side)
	Library.NotifySide = Side

	local IsLeft = Side:lower() == "left"
	if IsLeft then
		NotificationArea.AnchorPoint = Vector2.new(0, 0)
		NotificationArea.Position = UDim2.fromOffset(6, 6)
	else
		NotificationArea.AnchorPoint = Vector2.new(1, 0)
		NotificationArea.Position = UDim2.new(1, -6, 0, 6)
	end

	Library:UpdateNotificationPositions(true)
end

function Library:Notify(...)
	local Data = {}
	local Info = select(1, ...)

	if typeof(Info) == "table" then
		Data.Title = tostring(Info.Title or "")
		Data.Description = tostring(Info.Description or "")
		Data.Time = Info.Time or 5
		Data.Icon = Info.Icon
		Data.TitleColor = Info.TitleColor
		Data.DescriptionColor = Info.DescriptionColor
	else
		Data.Title = ""
		Data.Description = tostring(Info or "")
		Data.Time = select(2, ...) or 5
	end
	Data.Destroyed = false

	local FakeBackground = New("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Name = "Notification",
		Size = UDim2.fromScale(1, 0),
		Visible = false,
		Parent = NotificationArea,
	})

	local Holder = New("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = "Background",
		Name = "Holder",
		Position = UDim2.new(1, 12, 0, 0),
		Size = UDim2.fromScale(1, 0),
		ZIndex = 20,
		Parent = FakeBackground,
	})
	AddUICorner(Holder, Library.CornerRadius)
	New("UIStroke", {
		Color = "OutlineColor",
		Parent = Holder,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 4),
		Parent = Holder,
	})
	New("UIPadding", {
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 10),
		Parent = Holder,
	})

	local TitleLabel
	local DescLabel

	if Data.Icon then
		local Icon = Library:GetIcon(Data.Icon)
		New("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0),
			Image = Icon,
			Size = UDim2.fromOffset(18, 18),
			Parent = Holder,
		})
	end

	if Data.Title ~= "" then
		TitleLabel = New("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			Text = Data.Title,
			TextColor3 = Data.TitleColor or "TitleColor",
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})
	end

	if Data.Description ~= "" then
		DescLabel = New("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			Text = Data.Description,
			TextColor3 = Data.DescriptionColor or "FontColor",
			TextSize = 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})
	end

	local TimerBar = New("Frame", {
		BackgroundColor3 = "OutlineColor",
		Size = UDim2.new(1, 0, 0, 2),
		Parent = Holder,
	})
	local TimerFill = New("Frame", {
		BackgroundColor3 = "AccentColor",
		Size = UDim2.fromScale(1, 1),
		Parent = TimerBar,
	})

	function Data:SetTitle(Text)
		if TitleLabel then
			TitleLabel.Text = tostring(Text)
		end
	end

	function Data:SetDescription(Text)
		if DescLabel then
			DescLabel.Text = tostring(Text)
		end
	end

	function Data:Destroy()
		if Data.Destroyed then
			return
		end
		Data.Destroyed = true

		local Idx = table.find(NotifyOrder, FakeBackground)
		if Idx then
			table.remove(NotifyOrder, Idx)
		end
		Library.Notifications[FakeBackground] = nil

		Library:UpdateNotificationPositions()

		Library:Tween(Holder, {
			Position = UDim2.new(1, 12, 0, 0),
		}, { Style = "Fast", Callback = function()
			if FakeBackground then
				FakeBackground:Destroy()
			end
		end })
	end

	table.insert(NotifyOrder, FakeBackground)
	Library.Notifications[FakeBackground] = Data
	Library:UpdateNotificationPositions()

	FakeBackground.Visible = true
	Library:Tween(Holder, { Position = UDim2.fromOffset(0, 0) }, { Style = "Smooth" })

	if Data.Time and Data.Time > 0 then
		task.delay(Data.Time, function()
			if not Data.Destroyed then
				Data:Destroy()
			end
		end)
	end

	return Data
end

local BaseGroupbox = {}
do
	local Funcs = {}

	local function ParseInfo(...)
		local First, Second = select(1, ...), select(2, ...)

		if typeof(First) == "table" then
			return First, nil
		elseif typeof(Second) == "table" then
			return Second, First
		end

		return nil, First
	end

	local function Register(Element, Idx)
		Element.Idx = Idx
		if Idx then
			Library.Options[Idx] = Element
		end
	end

	local function Unregister(Element)
		if Element.Idx then
			Library.Options[Element.Idx] = nil
		end
	end

	local function FlagValue(Element, Idx, Value)
		if Idx then
			Library.Flags[Idx] = { Value = Value }
			Element.Flag = Library.Flags[Idx]
		end
	end

	function Funcs:AddDivider(Text)
		if self.Destroyed then
			return nil
		end

		local Groupbox = self
		local Container = Groupbox.Container

		local Holder = New("Frame", {
			BackgroundTransparency = 1,
			Name = "Divider",
			Size = UDim2.new(1, 0, 0, 18),
			Parent = Container,
		})

		local Divider = {
			Connections = {},
			Destroyed = false,

			Text = Text,
			SearchText = nil,
			Visible = true,
			Type = "Divider",
			Holder = Holder,
		}

		if Text then
			local Label = New("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = "Background",
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(0, 0),
				Text = Text,
				TextSize = 13,
				TextTransparency = 0.5,
				Parent = Holder,
			})
			local X, _ = Library:GetTextBounds(Text, Label.FontFace, Label.TextSize, Holder.AbsoluteSize.X)
			Label.Size = UDim2.fromOffset(X + 16, 18)
		end

		New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = "OutlineColor",
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.new(1, 0, 0, 1),
			Parent = Holder,
		})

		function Divider:SetVisible(Value)
			Divider.Visible = Value == true
			Holder.Visible = Divider.Visible
			Groupbox:Resize()
		end

		function Divider:Destroy()
			Divider.Destroyed = true

			if Divider.Connections then
				for _, Connection in Divider.Connections do
					Connection:Disconnect()
				end
			end

			if Holder then
				Holder:Destroy()
			end

			local ElemIdx = table.find(Groupbox.Elements, Divider)
			if ElemIdx then
				table.remove(Groupbox.Elements, ElemIdx)
			end

			Groupbox:Resize()
		end

		table.insert(Groupbox.Elements, Divider)
		Groupbox:Resize()

		return Divider
	end

	function Funcs:AddSection(Text)
		if self.Destroyed then
			return nil
		end

		local Groupbox = self
		local Container = Groupbox.Container

		local Holder = New("Frame", {
			BackgroundTransparency = 1,
			Name = "Section",
			Size = UDim2.new(1, 0, 0, 24),
			Parent = Container,
		})

		local Section = {
			Connections = {},
			Destroyed = false,

			Text = Text,
			SearchText = nil,
			Visible = true,
			Type = "Section",
			Holder = Holder,
		}

		local Label = New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = Text,
			TextSize = 15,
			TextTransparency = 0.3,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})

		New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = "OutlineColor",
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = UDim2.new(1, -90, 0, 1),
			Parent = Holder,
		})

		function Section:SetText(NewText)
			Section.Text = NewText
			Label.Text = NewText
		end

		function Section:SetVisible(Value)
			Section.Visible = Value == true
			Holder.Visible = Section.Visible
			Groupbox:Resize()
		end

		function Section:Destroy()
			Section.Destroyed = true

			if Holder then
				Holder:Destroy()
			end

			local ElemIdx = table.find(Groupbox.Elements, Section)
			if ElemIdx then
				table.remove(Groupbox.Elements, ElemIdx)
			end

			Groupbox:Resize()
		end

		table.insert(Groupbox.Elements, Section)
		Groupbox:Resize()

		return Section
	end

	function Funcs:AddLabel(...)
		if self.Destroyed then
			return nil
		end

		local Groupbox = self
		local Container = Groupbox.Container

		local Info, Idx = ParseInfo(...)
		local Text = Info and Info.Text or select(1, ...)
		local DoesWrap = Info and Info.DoesWrap or select(2, ...)
		local TextSize = Info and Info.Size or 14

		local Label = {
			Connections = {},
			Destroyed = false,

			Text = Text,
			DoesWrap = DoesWrap == true,
			SearchText = Text,
			Visible = true,
			Type = "Label",
		}

		local TextLabel = New("TextLabel", {
			AutomaticSize = DoesWrap and Enum.AutomaticSize.Y or nil,
			BackgroundTransparency = 1,
			Name = "Label",
			Size = UDim2.new(1, 0, 0, 18),
			Text = Label.Text,
			TextSize = TextSize,
			TextTransparency = 0.5,
			TextWrapped = DoesWrap,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Container,
		})
		Label.TextLabel = TextLabel

		if DoesWrap then
			TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				local _, Y = Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
				TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)
				Groupbox:Resize()
			end)
		else
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				Padding = UDim.new(0, 6),
				Parent = TextLabel,
			})
		end

		function Label:SetText(NewText)
			Label.Text = NewText
			Label.SearchText = NewText
			TextLabel.Text = NewText
			Groupbox:Resize()
		end

		function Label:SetVisible(Visible)
			Label.Visible = Visible == true
			TextLabel.Visible = Label.Visible
			Groupbox:Resize()
		end

		function Label:Destroy()
			Label.Destroyed = true

			if TextLabel then
				TextLabel:Destroy()
			end

			local ElemIdx = table.find(Groupbox.Elements, Label)
			if ElemIdx then
				table.remove(Groupbox.Elements, ElemIdx)
			end

			Groupbox:Resize()
			Unregister(Label)
		end

		Label.Holder = TextLabel
		table.insert(Groupbox.Elements, Label)
		Register(Label, Idx)
		Groupbox:Resize()

		return Label
	end

	function Funcs:AddButton(...)
		if self.Destroyed then
			return nil
		end

		local Groupbox = self
		local Container = Groupbox.Container

		local Info, Idx = ParseInfo(...)
		if not Info then
			Info = {
				Text = select(1, ...) or Templates.Button.Text,
				Callback = select(2, ...) or Templates.Button.Callback,
			}
			Idx = select(3, ...) or nil
		end
		Info = Library:Validate(Info, Templates.Button)

		local Button = {
			Connections = {},
			Destroyed = false,

			Text = Info.Text,
			Callback = Info.Callback,
			Risky = Info.Risky,
			Disabled = Info.Disabled,
			Visible = Info.Visible,
			Tooltip = Info.Tooltip,
			TooltipTable = nil,
			SearchText = Info.Text,
			Type = "Button",
		}

		local Holder = New("Frame", {
			BackgroundTransparency = 1,
			Name = "Button",
			Size = UDim2.new(1, 0, 0, 32),
			Visible = Button.Visible,
			Parent = Container,
		})

		local Base = New("TextButton", {
			Active = not Button.Disabled,
			BackgroundColor3 = Button.Disabled and "Background" or "MainColor",
			Name = "Button",
			Size = UDim2.fromScale(1, 1),
			Text = Button.Text,
			TextSize = 14,
			TextTransparency = 0.4,
			Parent = Holder,
		})
		AddUICorner(Base, Library.CornerRadius / 2)
		New("UIStroke", {
			Color = "OutlineColor",
			Transparency = Button.Disabled and 0.5 or 0,
			Parent = Base,
		})

		if Button.Risky then
			Base.TextColor3 = Library.Scheme.RedColor
			Library.Registry[Base].TextColor3 = "RedColor"
		end

		local function UpdateColors()
			Base.BackgroundColor3 = Button.Disabled and Library.Scheme.Background or Library.Scheme.MainColor
			Base.TextTransparency = Button.Disabled and 0.8 or 0.4
			Library.Registry[Base].BackgroundColor3 = Button.Disabled and "Background" or "MainColor"
		end

		Base.MouseEnter:Connect(function()
			if Button.Disabled then
				return
			end
			Library:Tween(Base, { TextTransparency = 0 }, "Fast")
		end)
		Base.MouseLeave:Connect(function()
			if Button.Disabled then
				return
			end
			Library:Tween(Base, { TextTransparency = 0.4 }, "Fast")
		end)
		Base.MouseButton1Click:Connect(function()
			if Button.Disabled or Button.Destroyed then
				return
			end
			if Button.DoubleClick then
				Button.Locked = true
				Base.Text = "Are you sure?"
				local Clicked = WaitForEvent(Base.MouseButton1Click, 0.5)
				Base.Text = Button.Text
				if Clicked then
					Library:SafeCallback(Button.Callback)
				end
				task.wait()
				Button.Locked = false
				return
			end
			Library:SafeCallback(Button.Callback)
		end)

		function Button:SetDisabled(Disabled)
			Button.Disabled = Disabled == true
			if Button.TooltipTable then
				Button.TooltipTable:SetDisabled(Button.Disabled)
			end
			Base.Active = not Button.Disabled
			UpdateColors()
		end

		function Button:SetVisible(Visible)
			Button.Visible = Visible == true
			Holder.Visible = Button.Visible
			Groupbox:Resize()
		end

		function Button:SetText(NewText)
			Button.Text = NewText
			Button.SearchText = NewText
			Base.Text = NewText
		end

		function Button:Destroy()
			Button.Destroyed = true

			if Button.TooltipTable then
				Button.TooltipTable:Destroy()
			end

			if Holder then
				Holder:Destroy()
			end

			local ElemIdx = table.find(Groupbox.Elements, Button)
			if ElemIdx then
				table.remove(Groupbox.Elements, ElemIdx)
			end

			Groupbox:Resize()
			Unregister(Button)
		end

		if typeof(Button.Tooltip) == "string" then
			Button.TooltipTable = Library:AddTooltip(Button.Tooltip, nil, Base)
			Button.TooltipTable:SetDisabled(Button.Disabled)
		end

		Button.Holder = Holder
		table.insert(Groupbox.Elements, Button)
		Register(Button, Idx)
		Groupbox:Resize()

		return Button
	end

	function Funcs:AddToggle(Idx, Info)
		if self.Destroyed then
			return nil
		end

		Info = Library:Validate(Info, Templates.Toggle)

		local Groupbox = self
		local Container = Groupbox.Container

		local Toggle = {
			Connections = {},
			Destroyed = false,

			Text = Info.Text,
			Value = Info.Default,
			Callback = Info.Callback,
			Changed = Info.Changed,
			Risky = Info.Risky,
			Disabled = Info.Disabled,
			Visible = Info.Visible,
			Tooltip = Info.Tooltip,
			TooltipTable = nil,
			SearchText = Info.Text,
			Type = "Toggle",
		}

		local Holder = New("Frame", {
			BackgroundTransparency = 1,
			Name = "Toggle",
			Size = UDim2.new(1, 0, 0, 24),
			Visible = Toggle.Visible,
			Parent = Container,
		})

		local Button = New("TextButton", {
			Active = not Toggle.Disabled,
			BackgroundTransparency = 1,
			Name = "Button",
			Size = UDim2.fromScale(1, 1),
			Text = "",
			Parent = Holder,
		})

		local Label = New("TextLabel", {
			BackgroundTransparency = 1,
			Name = "Label",
			Size = UDim2.new(1, -44, 1, 0),
			Text = Toggle.Text,
			TextSize = 14,
			TextTransparency = 0.4,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})

		local Switch = New("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = "MainColor",
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromOffset(36, 18),
			Parent = Holder,
		})
		AddUICorner(Switch, 9, true)
		New("UIPadding", {
			PaddingBottom = UDim.new(0, 2),
			PaddingLeft = UDim.new(0, 2),
			PaddingRight = UDim.new(0, 2),
			PaddingTop = UDim.new(0, 2),
			Parent = Switch,
		})
		local SwitchStroke = New("UIStroke", {
			Color = "OutlineColor",
			Parent = Switch,
		})

		local Ball = New("Frame", {
			BackgroundColor3 = "FontColor",
			Size = UDim2.fromScale(1, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Parent = Switch,
		})
		AddUICorner(Ball, 9, true)

		function Toggle:Display()
			if Toggle.Destroyed then
				return
			end

			local Offset = Toggle.Value and 1 or 0

			Switch.BackgroundColor3 = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.MainColor
			SwitchStroke.Color = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.OutlineColor
			Library.Registry[Switch].BackgroundColor3 = Toggle.Value and "AccentColor" or "MainColor"
			Library.Registry[SwitchStroke].Color = Toggle.Value and "AccentColor" or "OutlineColor"

			if Toggle.Disabled then
				Label.TextTransparency = 0.8
				Ball.AnchorPoint = Vector2.new(Offset, 0)
				Ball.Position = UDim2.fromScale(Offset, 0)
				Ball.BackgroundColor3 = Library:GetDarkerColor(Library.Scheme.FontColor)
				return
			end

			Library:Tween(Label, { TextTransparency = Toggle.Value and 0 or 0.4 }, "Fast")
			Library:Tween(Ball, {
				AnchorPoint = Vector2.new(Offset, 0),
				Position = UDim2.fromScale(Offset, 0),
			}, "Fast")

			Ball.BackgroundColor3 = Library.Scheme.FontColor
			Library.Registry[Ball].BackgroundColor3 = "FontColor"
		end

		function Toggle:OnChanged(Func)
			Toggle.Changed = Func
		end

		function Toggle:RunChanged()
			Library:SafeCallback(Toggle.Callback, Toggle.Value)
			Library:SafeCallback(Toggle.Changed, Toggle.Value)
		end

		function Toggle:SetValue(Value)
			if Toggle.Disabled then
				return
			end

			Toggle.Value = Value == true
			if Toggle.Flag then
				Toggle.Flag.Value = Toggle.Value
			end

			Toggle:Display()
			Library:UpdateDependencyBoxes()
			Toggle:RunChanged()
		end

		function Toggle:SetDisabled(Disabled)
			Toggle.Disabled = Disabled == true
			if Toggle.TooltipTable then
				Toggle.TooltipTable:SetDisabled(Toggle.Disabled)
			end
			Button.Active = not Toggle.Disabled
			Toggle:Display()
		end

		function Toggle:SetVisible(Visible)
			Toggle.Visible = Visible == true
			Holder.Visible = Toggle.Visible
			Groupbox:Resize()
		end

		function Toggle:SetText(NewText)
			Toggle.Text = NewText
			Toggle.SearchText = NewText
			Label.Text = NewText
		end

		function Toggle:Destroy()
			Toggle.Destroyed = true

			if Toggle.Connections then
				for _, Connection in Toggle.Connections do
					Connection:Disconnect()
				end
			end

			if Toggle.TooltipTable then
				Toggle.TooltipTable:Destroy()
			end

			if Holder then
				Holder:Destroy()
			end

			local ElemIdx = table.find(Groupbox.Elements, Toggle)
			if ElemIdx then
				table.remove(Groupbox.Elements, ElemIdx)
			end

			Groupbox:Resize()
			Unregister(Toggle)
		end

		table.insert(Toggle.Connections, Button.MouseButton1Click:Connect(function()
			if Toggle.Disabled then
				return
			end
			Toggle:SetValue(not Toggle.Value)
		end))

		if Toggle.Risky then
			Label.TextColor3 = Library.Scheme.RedColor
			Library.Registry[Label].TextColor3 = "RedColor"
		end

		if typeof(Toggle.Tooltip) == "string" then
			Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, nil, Button)
			Toggle.TooltipTable:SetDisabled(Toggle.Disabled)
		end

		Toggle:Display()

		Toggle.Holder = Holder
		table.insert(Groupbox.Elements, Toggle)
		Register(Toggle, Idx)
		FlagValue(Toggle, Idx, Toggle.Value)
		Groupbox:Resize()

		return Toggle
	end

	function Funcs:AddSlider(Idx, Info)
		if self.Destroyed then
			return nil
		end

		Info = Library:Validate(Info, Templates.Slider)

		local Groupbox = self
		local Container = Groupbox.Container

		local Slider = {
			Connections = {},
			Destroyed = false,

			Text = Info.Text,
			Value = Info.Default,
			Min = Info.Min,
			Max = Info.Max,
			Rounding = Info.Rounding,
			Prefix = Info.Prefix,
			Suffix = Info.Suffix,
			Callback = Info.Callback,
			Changed = Info.Changed,
			Disabled = Info.Disabled,
			Visible = Info.Visible,
			Tooltip = Info.Tooltip,
			TooltipTable = nil,
			SearchText = Info.Text,
			Type = "Slider",
		}

		local Holder = New("Frame", {
			BackgroundTransparency = 1,
			Name = "Slider",
			Size = UDim2.new(1, 0, 0, 41),
			Visible = Slider.Visible,
			Parent = Container,
		})

		local Label = New("TextLabel", {
			BackgroundTransparency = 1,
			Name = "Label",
			Size = UDim2.new(1, 0, 0, 14),
			Text = Slider.Text,
			TextSize = 14,
			TextTransparency = 0.4,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})

		local Bar = New("TextButton", {
			Active = not Slider.Disabled,
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = "MainColor",
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 15),
			Text = "",
			Parent = Holder,
		})
		AddUICorner(Bar, Library.CornerRadius / 2)
		New("UIStroke", {
			Color = "OutlineColor",
			Parent = Bar,
		})

		local Fill = New("Frame", {
			BackgroundColor3 = "AccentColor",
			Size = UDim2.fromScale(0.5, 1),
			Parent = Bar,
		})
		AddUICorner(Fill, Library.CornerRadius / 2)

		local DisplayLabel = New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			TextSize = 12,
			ZIndex = Bar.ZIndex + 1,
			Parent = Bar,
		})

		function Slider:Display()
			if Slider.Destroyed then
				return
			end

			local Format = Info.FormatDisplayValue
			if typeof(Format) == "function" then
				DisplayLabel.Text = tostring(Format(Slider.Value))
			else
				DisplayLabel.Text = string.format("%s%s%s / %s%s%s",
					Slider.Prefix, Slider.Value, Slider.Suffix,
					Slider.Prefix, Slider.Max, Slider.Suffix)
			end

			local X = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
			Fill.Size = UDim2.fromScale(X, 1)
		end

		function Slider:OnChanged(Func)
			Slider.Changed = Func
		end

		function Slider:RunChanged()
			Library:SafeCallback(Slider.Callback, Slider.Value)
			Library:SafeCallback(Slider.Changed, Slider.Value)
		end

		function Slider:SetValue(Value)
			if Slider.Disabled then
				return
			end

			local Num = tonumber(Value)
			if not Num or Num == Slider.Value then
				return
			end

			Num = math.clamp(Num, Slider.Min, Slider.Max)
			Slider.Value = Round(Num, Slider.Rounding)
			if Slider.Flag then
				Slider.Flag.Value = Slider.Value
			end

			Slider:Display()
			Slider:RunChanged()
		end

		function Slider:SetMin(Value)
			Slider.Min = Value
			Slider:SetValue(math.max(Slider.Value, Slider.Min))
			Slider:Display()
		end

		function Slider:SetMax(Value)
			Slider.Max = Value
			Slider:SetValue(math.min(Slider.Value, Slider.Max))
			Slider:Display()
		end

		function Slider:SetDisabled(Disabled)
			Slider.Disabled = Disabled == true
			if Slider.TooltipTable then
				Slider.TooltipTable:SetDisabled(Slider.Disabled)
			end
			Bar.Active = not Slider.Disabled
		end

		function Slider:SetVisible(Visible)
			Slider.Visible = Visible == true
			Holder.Visible = Slider.Visible
			Groupbox:Resize()
		end

		function Slider:SetText(NewText)
			Slider.Text = NewText
			Slider.SearchText = NewText
			Label.Text = NewText
		end

		function Slider:Destroy()
			Slider.Destroyed = true

			if Slider.Connections then
				for _, Connection in Slider.Connections do
					Connection:Disconnect()
				end
			end

			if Slider.TooltipTable then
				Slider.TooltipTable:Destroy()
			end

			if Holder then
				Holder:Destroy()
			end

			local ElemIdx = table.find(Groupbox.Elements, Slider)
			if ElemIdx then
				table.remove(Groupbox.Elements, ElemIdx)
			end

			Groupbox:Resize()
			Unregister(Slider)
		end

		table.insert(Slider.Connections, Bar.InputBegan:Connect(function(Input)
			if not IsClickInput(Input) or Slider.Disabled then
				return
			end

			if Slider.Groupbox and Slider.Groupbox.Tab then
				for _, Side in Slider.Groupbox.Tab.Sides do
					Side.ScrollingEnabled = false
				end
			end

			while IsDragInput(Input) and not Slider.Destroyed do
				local X = Input.UserInputType == Enum.UserInputType.Touch and Input.Position.X or Mouse.X
				local Scale = math.clamp((X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
				local NewValue = Round(Slider.Min + ((Slider.Max - Slider.Min) * Scale), Slider.Rounding)

				if NewValue ~= Slider.Value then
					Slider:SetValue(NewValue)
				end

				RunService.RenderStepped:Wait()
			end

			if Slider.Groupbox and Slider.Groupbox.Tab then
				for _, Side in Slider.Groupbox.Tab.Sides do
					Side.ScrollingEnabled = true
				end
			end
		end))

		if typeof(Slider.Tooltip) == "string" then
			Slider.TooltipTable = Library:AddTooltip(Slider.Tooltip, nil, Bar)
			Slider.TooltipTable:SetDisabled(Slider.Disabled)
		end

		Slider:Display()

		Slider.Holder = Holder
		Slider.Groupbox = Groupbox
		table.insert(Groupbox.Elements, Slider)
		Register(Slider, Idx)
		FlagValue(Slider, Idx, Slider.Value)
		Groupbox:Resize()

		return Slider
	end

	function Funcs:AddDropdown(Idx, Info)
		if self.Destroyed then
			return nil
		end

		Info = Library:Validate(Info, Templates.Dropdown)

		local Groupbox = self
		local Container = Groupbox.Container

		local Dropdown = {
			Connections = {},
			Destroyed = false,

			Text = Info.Text,
			Value = Info.Multi and {} or nil,
			Values = Info.Values,
			Multi = Info.Multi,
			MaxVisible = Info.MaxVisible,
			Callback = Info.Callback,
			Changed = Info.Changed,
			Disabled = Info.Disabled,
			Visible = Info.Visible,
			Tooltip = Info.Tooltip,
			TooltipTable = nil,
			SearchText = Info.Text,
			Items = {},
			Type = "Dropdown",
		}

		local Holder = New("Frame", {
			BackgroundTransparency = 1,
			Name = "Dropdown",
			Size = UDim2.new(1, 0, 0, Info.Text and 41 or 23),
			Visible = Dropdown.Visible,
			Parent = Container,
		})

		local Label
		if Info.Text then
			Label = New("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 14),
				Text = Info.Text,
				TextSize = 14,
				TextTransparency = 0.4,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Holder,
			})
		end

		local Display = New("TextButton", {
			Active = not Dropdown.Disabled,
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = "MainColor",
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 23),
			Text = "",
			TextTransparency = 1,
			Parent = Holder,
		})
		AddUICorner(Display, Library.CornerRadius / 2, true)
		New("UIStroke", {
			Color = "OutlineColor",
			Parent = Display,
		})
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 4),
			Parent = Display,
		})

		local DisplayButton = New("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -24, 1, 0),
			Text = "---",
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = Display.ZIndex + 1,
			Parent = Display,
		})

		local Arrow = New("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(14, 14),
			Text = "❯",
			TextSize = 12,
			TextTransparency = 0.5,
			TextRotation = 90,
			Parent = Display,
		})

		local Popup = Library:AddPopup(Display, function()
			return UDim2.fromOffset(Display.AbsoluteSize.X, 0)
		end, function()
			return { 0, Display.AbsoluteSize.Y + 1.5 }
		end, function(Active)
			Arrow.TextRotation = Active and 270 or 90
			Arrow.TextTransparency = Active and 0 or 0.5
		end, Library.CornerRadius / 2)
		Dropdown.Popup = Popup

		local List = New("ScrollingFrame", {
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			CanvasSize = UDim2.fromScale(0, 0),
			Size = UDim2.fromScale(1, 1),
			ScrollBarThickness = 3,
			Parent = Popup.Popup,
		})
		New("UIListLayout", {
			Padding = UDim.new(0, 2),
			Parent = List,
		})
		New("UIPadding", {
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			PaddingTop = UDim.new(0, 4),
			Parent = List,
		})

		local function RecalculateListSize(Count)
			local Height = math.clamp((Count or #Dropdown.Values) * 23, 0, Dropdown.MaxVisible * 23) + 8
			Popup:SetSize(function()
				return UDim2.fromOffset(Display.AbsoluteSize.X, Height)
			end)
		end

		function Dropdown:Display()
			if Dropdown.Destroyed then
				return
			end

			local Str = ""
			if Dropdown.Multi then
				local Parts = {}
				for Value, Active in Dropdown.Value do
					if Active then
						table.insert(Parts, tostring(Value))
					end
				end
				Str = table.concat(Parts, ", ")
			else
				Str = Dropdown.Value and tostring(Dropdown.Value) or ""
			end

			if #Str > 25 then
				Str = Str:sub(1, 22) .. "..."
			end

			DisplayButton.Text = Str == "" and "---" or Str
		end

		function Dropdown:OnChanged(Func)
			Dropdown.Changed = Func
		end

		function Dropdown:GetActiveValues()
			local Active = {}
			if Dropdown.Multi then
				for Value, Toggle in Dropdown.Value do
					if Toggle then
						table.insert(Active, Value)
					end
				end
			elseif Dropdown.Value ~= nil then
				table.insert(Active, Dropdown.Value)
			end
			return Active
		end

		function Dropdown:RunChanged()
			Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
			Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
		end

		function Dropdown:BuildDropdownList()
			if Dropdown.Destroyed then
				return
			end

			for _, Item in Dropdown.Items do
				if Item.Container then
					Item.Container:Destroy()
				end
			end
			table.clear(Dropdown.Items)

			local Count = 0
			for _, Value in Dropdown.Values do
				Count += 1

				local Selected
				if Dropdown.Multi then
					Selected = Dropdown.Value[Value] == true
				else
					Selected = Dropdown.Value == Value
				end

				local Item = {}
				local Container = New("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 23),
					Parent = List,
				})

				local Button = New("TextButton", {
					BackgroundColor3 = "Background",
					Size = UDim2.fromScale(1, 1),
					Text = tostring(Value),
					TextSize = 13,
					TextTransparency = 0.5,
					Parent = Container,
				})

				local function Update()
					if Dropdown.Multi then
						Selected = Dropdown.Value[Value] == true
					else
						Selected = Dropdown.Value == Value
					end

					Button.BackgroundColor3 = Selected and Library.Scheme.AccentColor or Library.Scheme.Background
					Button.TextColor3 = Selected and Library.Scheme.WhiteColor or Library.Scheme.FontColor
					Library.Registry[Button].BackgroundColor3 = Selected and "AccentColor" or "Background"
				end
				Item.Update = Update

				Button.MouseButton1Click:Connect(function()
					if Dropdown.Disabled then
						return
					end

					if Dropdown.Multi then
						Dropdown.Value[Value] = not Selected
					else
						Dropdown.Value = Selected and nil or Value
						Popup:Close()
					end

					if Dropdown.Flag then
						Dropdown.Flag.Value = Dropdown.Value
					end

					for _, Other in Dropdown.Items do
						if Other.Update then
							Other:Update()
						end
					end

					Dropdown:Display()
					Library:UpdateDependencyBoxes()
					Dropdown:RunChanged()
				end)

				Update()
				Item.Container = Container
				table.insert(Dropdown.Items, Item)
			end

			RecalculateListSize(Count)
		end

		function Dropdown:SetValue(Value)
			if Dropdown.Disabled then
				return
			end

			if Dropdown.Multi then
				local NewValues = {}
				if typeof(Value) == "table" then
					for Key, Active in Value do
						if typeof(Active) == "boolean" then
							if Active and table.find(Dropdown.Values, Key) then
								NewValues[Key] = true
							end
						elseif table.find(Dropdown.Values, Active) then
							NewValues[Active] = true
						end
					end
				end
				Dropdown.Value = NewValues
			else
				if Value == nil or table.find(Dropdown.Values, Value) then
					Dropdown.Value = Value
				end
			end

			if Dropdown.Flag then
				Dropdown.Flag.Value = Dropdown.Value
			end

			Dropdown:Display()
			for _, Item in Dropdown.Items do
				if Item.Update then
					Item:Update()
				end
			end

			Library:UpdateDependencyBoxes()
			Dropdown:RunChanged()
		end

		function Dropdown:SetValues(Values)
			Dropdown.Values = Values or {}
			Dropdown:BuildDropdownList()
		end

		function Dropdown:SetDisabled(Disabled)
			Dropdown.Disabled = Disabled == true
			if Dropdown.TooltipTable then
				Dropdown.TooltipTable:SetDisabled(Dropdown.Disabled)
			end
			Popup:Close()
			Display.Active = not Dropdown.Disabled
		end

		function Dropdown:SetVisible(Visible)
			Dropdown.Visible = Visible == true
			Holder.Visible = Dropdown.Visible
			Groupbox:Resize()
		end

		function Dropdown:SetText(NewText)
			Dropdown.Text = NewText
			Dropdown.SearchText = NewText
			if Label then
				Label.Text = NewText
				Holder.Size = UDim2.new(1, 0, 0, 41)
			else
				Holder.Size = UDim2.new(1, 0, 0, 23)
			end
		end

		function Dropdown:Destroy()
			Dropdown.Destroyed = true

			Popup:Destroy()

			if Dropdown.TooltipTable then
				Dropdown.TooltipTable:Destroy()
			end

			if Holder then
				Holder:Destroy()
			end

			local ElemIdx = table.find(Groupbox.Elements, Dropdown)
			if ElemIdx then
				table.remove(Groupbox.Elements, ElemIdx)
			end

			Groupbox:Resize()
			Unregister(Dropdown)
		end

		table.insert(Dropdown.Connections, Display.MouseButton1Click:Connect(function()
			if Dropdown.Disabled then
				return
			end
			Popup:Toggle()
		end))
		table.insert(Dropdown.Connections, DisplayButton.MouseButton1Click:Connect(function()
			if Dropdown.Disabled then
				return
			end
			Popup:Toggle()
		end))

		local Defaults = {}
		if typeof(Info.Default) == "string" then
			local Index = table.find(Dropdown.Values, Info.Default)
			if Index then
				table.insert(Defaults, Index)
			end
		elseif typeof(Info.Default) == "table" then
			for _, Value in Info.Default do
				local Index = table.find(Dropdown.Values, Value)
				if Index then
					table.insert(Defaults, Index)
				end
			end
		end

		for _, Index in Defaults do
			if Dropdown.Multi then
				Dropdown.Value[Dropdown.Values[Index]] = true
			else
				Dropdown.Value = Dropdown.Values[Index]
				break
			end
		end

		if typeof(Dropdown.Tooltip) == "string" then
			Dropdown.TooltipTable = Library:AddTooltip(Dropdown.Tooltip, nil, Display)
			Dropdown.TooltipTable:SetDisabled(Dropdown.Disabled)
		end

		Dropdown:Display()
		Dropdown:BuildDropdownList()

		Dropdown.Holder = Holder
		Dropdown.Groupbox = Groupbox
		table.insert(Groupbox.Elements, Dropdown)
		Register(Dropdown, Idx)
		FlagValue(Dropdown, Idx, Dropdown.Value)
		Groupbox:Resize()

		return Dropdown
	end

	function Funcs:AddTextbox(Idx, Info)
		if self.Destroyed then
			return nil
		end

		Info = Library:Validate(Info, Templates.Textbox)

		local Groupbox = self
		local Container = Groupbox.Container

		local Textbox = {
			Connections = {},
			Destroyed = false,

			Text = Info.Text,
			Value = Info.Default,
			Numeric = Info.Numeric,
			Placeholder = Info.Placeholder,
			Finished = Info.Finished,
			ClearTextOnFocus = Info.ClearTextOnFocus,
			Callback = Info.Callback,
			Changed = Info.Changed,
			Disabled = Info.Disabled,
			Visible = Info.Visible,
			Tooltip = Info.Tooltip,
			TooltipTable = nil,
			SearchText = Info.Text,
			Type = "Textbox",
		}

		local Holder = New("Frame", {
			BackgroundTransparency = 1,
			Name = "Textbox",
			Size = UDim2.new(1, 0, 0, 44),
			Visible = Textbox.Visible,
			Parent = Container,
		})

		local Label = New("TextLabel", {
			BackgroundTransparency = 1,
			Name = "Label",
			Size = UDim2.new(1, 0, 0, 14),
			Text = Textbox.Text,
			TextSize = 14,
			TextTransparency = 0.4,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})

		local Box = New("TextBox", {
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = "MainColor",
			ClearTextOnFocus = not Textbox.Disabled and Textbox.ClearTextOnFocus,
			PlaceholderText = Textbox.Placeholder,
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 24),
			Text = Textbox.Value,
			TextEditable = not Textbox.Disabled,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})
		AddUICorner(Box, Library.CornerRadius / 2)
		New("UIStroke", {
			Color = "OutlineColor",
			Parent = Box,
		})
		New("UIPadding", {
			PaddingBottom = UDim.new(0, 3),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 3),
			Parent = Box,
		})

		function Textbox:OnChanged(Func)
			Textbox.Changed = Func
		end

		function Textbox:RunChanged()
			Library:SafeCallback(Textbox.Callback, Textbox.Value)
			Library:SafeCallback(Textbox.Changed, Textbox.Value)
		end

		function Textbox:SetValue(NewValue)
			if Textbox.Numeric and NewValue ~= "" and not tonumber(NewValue) then
				NewValue = Textbox.Value
			end

			Textbox.Value = tostring(NewValue)
			if Textbox.Flag then
				Textbox.Flag.Value = Textbox.Value
			end
			Box.Text = Textbox.Value

			if not Textbox.Disabled then
				Textbox:RunChanged()
			end
		end

		function Textbox:SetDisabled(Disabled)
			Textbox.Disabled = Disabled == true
			if Textbox.TooltipTable then
				Textbox.TooltipTable:SetDisabled(Textbox.Disabled)
			end
			Box.TextEditable = not Textbox.Disabled
			Box.ClearTextOnFocus = not Textbox.Disabled and Textbox.ClearTextOnFocus
		end

		function Textbox:SetVisible(Visible)
			Textbox.Visible = Visible == true
			Holder.Visible = Textbox.Visible
			Groupbox:Resize()
		end

		function Textbox:SetText(NewText)
			Textbox.Text = NewText
			Textbox.SearchText = NewText
			Label.Text = NewText
		end

		function Textbox:Destroy()
			Textbox.Destroyed = true

			if Textbox.Connections then
				for _, Connection in Textbox.Connections do
					Connection:Disconnect()
				end
			end

			if Textbox.TooltipTable then
				Textbox.TooltipTable:Destroy()
			end

			if Holder then
				Holder:Destroy()
			end

			local ElemIdx = table.find(Groupbox.Elements, Textbox)
			if ElemIdx then
				table.remove(Groupbox.Elements, ElemIdx)
			end

			Groupbox:Resize()
			Unregister(Textbox)
		end

		if Textbox.Finished then
			table.insert(Textbox.Connections, Box.FocusLost:Connect(function(Enter)
				if not Enter then
					return
				end
				Textbox:SetValue(Box.Text)
			end))
		else
			table.insert(Textbox.Connections, Box:GetPropertyChangedSignal("Text"):Connect(function()
				if Box.Text == Textbox.Value then
					return
				end
				Textbox:SetValue(Box.Text)
			end))
		end

		if typeof(Textbox.Tooltip) == "string" then
			Textbox.TooltipTable = Library:AddTooltip(Textbox.Tooltip, nil, Box)
			Textbox.TooltipTable:SetDisabled(Textbox.Disabled)
		end

		Textbox.Holder = Holder
		Textbox.Groupbox = Groupbox
		table.insert(Groupbox.Elements, Textbox)
		Register(Textbox, Idx)
		FlagValue(Textbox, Idx, Textbox.Value)
		Groupbox:Resize()

		return Textbox
	end

	function Funcs:AddColorPicker(Idx, Info)
		if self.Destroyed then
			return nil
		end

		Info = Library:Validate(Info, Templates.ColorPicker)

		local Groupbox = self
		local Container = Groupbox.Container

		local ColorPicker = {
			Connections = {},
			Destroyed = false,

			Value = Info.Default,
			TransparencyEnabled = Info.Transparency,
			Transparency = 0,
			Callback = Info.Callback,
			Changed = Info.Changed,
			Visible = true,
			SearchText = "Color",
			Type = "ColorPicker",
		}
		ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = ColorPicker.Value:ToHSV()

		local Holder = New("Frame", {
			BackgroundTransparency = 1,
			Name = "ColorPicker",
			Size = UDim2.new(1, 0, 0, 24),
			Parent = Container,
		})

		local Label = New("TextLabel", {
			BackgroundTransparency = 1,
			Name = "Label",
			Size = UDim2.new(1, -34, 1, 0),
			Text = "Color",
			TextSize = 14,
			TextTransparency = 0.4,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})

		local Swatch = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = ColorPicker.Value,
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(26, 26),
			Text = "",
			Parent = Holder,
		})
		AddUICorner(Swatch, Library.CornerRadius / 2)
		local SwatchStroke = New("UIStroke", {
			Color = "OutlineColor",
			Parent = Swatch,
		})

		local HueSequence = {}
		for i = 0, 10 do
			local H = i / 10
			table.insert(HueSequence, ColorSequenceKeypoint.new(H, Color3.fromHSV(H, 1, 1)))
		end

		local Popup = Library:AddPopup(Swatch, UDim2.fromOffset(228, ColorPicker.TransparencyEnabled and 248 or 228), function()
			return { 0, Swatch.AbsoluteSize.Y + 1.5 }
		end, nil, Library.CornerRadius / 2)
		ColorPicker.Popup = Popup

		New("UIListLayout", {
			Padding = UDim.new(0, 8),
			Parent = Popup.Popup,
		})
		New("UIPadding", {
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 8),
			Parent = Popup.Popup,
		})

		local ColorRow = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(212, 200),
			Parent = Popup.Popup,
		})
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			Parent = ColorRow,
		})

		local SatMap = New("Frame", {
			BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1),
			Size = UDim2.fromOffset(200, 200),
			Parent = ColorRow,
		})
		New("UIGradient", {
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
			Transparency = NumberSequence.new(0, 1),
			Parent = SatMap,
		})
		New("UIGradient", {
			Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
			Transparency = NumberSequence.new(0, 1),
			Rotation = 90,
			Parent = SatMap,
		})

		local SatCursor = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = "WhiteColor",
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(12, 12),
			Parent = SatMap,
		})
		AddUICorner(SatCursor, 6, true)
		New("UIStroke", {
			Color = "DarkColor",
			Thickness = 1.5,
			Parent = SatCursor,
		})

		local HueBar = New("Frame", {
			Size = UDim2.fromOffset(16, 200),
			Parent = ColorRow,
		})
		New("UIGradient", {
			Color = ColorSequence.new(HueSequence),
			Rotation = 90,
			Parent = HueBar,
		})

		local HueCursor = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = "WhiteColor",
			BorderColor3 = "DarkColor",
			BorderSizePixel = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, 4, 0, 3),
			Parent = HueBar,
		})

		local AlphaBar, AlphaCursor
		if ColorPicker.TransparencyEnabled then
			AlphaBar = New("Frame", {
				BackgroundColor3 = "DarkColor",
				Size = UDim2.new(1, 0, 0, 8),
				Parent = Popup.Popup,
			})
			AlphaCursor = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = "WhiteColor",
				BorderColor3 = "DarkColor",
				BorderSizePixel = 1,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 6, 1, 0),
				Parent = AlphaBar,
			})
		end

		local HexLabel = New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			Text = "",
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = Popup.Popup,
		})

		function ColorPicker:Display()
			if ColorPicker.Destroyed then
				return
			end

			ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)

			Swatch.BackgroundColor3 = ColorPicker.Value
			SwatchStroke.Color = Library:GetDarkerColor(ColorPicker.Value)

			SatMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
			SatCursor.Position = UDim2.fromScale(ColorPicker.Sat, 1 - ColorPicker.Vib)
			HueCursor.Position = UDim2.fromScale(0.5, ColorPicker.Hue)

			if AlphaCursor then
				AlphaCursor.Position = UDim2.new(ColorPicker.Transparency, 0, 0.5, 0)
			end

			HexLabel.Text = "#" .. ColorPicker.Value:ToHex()
		end

		function ColorPicker:OnChanged(Func)
			ColorPicker.Changed = Func
		end

		function ColorPicker:RunChanged()
			Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
			Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
		end

		function ColorPicker:Update()
			ColorPicker:Display()
			ColorPicker:RunChanged()
		end

		function ColorPicker:SetValue(Color, Transparency)
			if typeof(Color) == "Color3" then
				ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
			end
			if ColorPicker.TransparencyEnabled and Transparency ~= nil then
				ColorPicker.Transparency = math.clamp(Transparency, 0, 1)
			end
			if ColorPicker.Flag then
				ColorPicker.Flag.Value = ColorPicker.Value
			end
			ColorPicker:Update()
		end

		function ColorPicker:SetVisible(Visible)
			ColorPicker.Visible = Visible == true
			Holder.Visible = ColorPicker.Visible
			Groupbox:Resize()
		end

		function ColorPicker:Destroy()
			ColorPicker.Destroyed = true

			Popup:Destroy()

			if Holder then
				Holder:Destroy()
			end

			local ElemIdx = table.find(Groupbox.Elements, ColorPicker)
			if ElemIdx then
				table.remove(Groupbox.Elements, ElemIdx)
			end

			Groupbox:Resize()
			Unregister(ColorPicker)
		end

		table.insert(ColorPicker.Connections, Swatch.MouseButton1Click:Connect(function()
			Popup:Toggle()
		end))

		table.insert(ColorPicker.Connections, SatMap.InputBegan:Connect(function(Input)
			if not IsClickInput(Input) then
				return
			end
			while IsDragInput(Input) and not ColorPicker.Destroyed do
				local MinX = SatMap.AbsolutePosition.X
				local X = math.clamp(Mouse.X, MinX, MinX + SatMap.AbsoluteSize.X)
				local MinY = SatMap.AbsolutePosition.Y
				local Y = math.clamp(Mouse.Y, MinY, MinY + SatMap.AbsoluteSize.Y)

				ColorPicker.Sat = (X - MinX) / SatMap.AbsoluteSize.X
				ColorPicker.Vib = 1 - (Y - MinY) / SatMap.AbsoluteSize.Y
				ColorPicker:Update()

				RunService.RenderStepped:Wait()
			end
		end))

		table.insert(ColorPicker.Connections, HueBar.InputBegan:Connect(function(Input)
			if not IsClickInput(Input) then
				return
			end
			while IsDragInput(Input) and not ColorPicker.Destroyed do
				local MinY = HueBar.AbsolutePosition.Y
				local Y = math.clamp(Mouse.Y, MinY, MinY + HueBar.AbsoluteSize.Y)

				ColorPicker.Hue = (Y - MinY) / HueBar.AbsoluteSize.Y
				ColorPicker:Update()

				RunService.RenderStepped:Wait()
			end
		end))

		if AlphaBar then
			table.insert(ColorPicker.Connections, AlphaBar.InputBegan:Connect(function(Input)
				if not IsClickInput(Input) then
					return
				end
				while IsDragInput(Input) and not ColorPicker.Destroyed do
					local MinX = AlphaBar.AbsolutePosition.X
					local X = math.clamp(Mouse.X, MinX, MinX + AlphaBar.AbsoluteSize.X)

					ColorPicker.Transparency = (X - MinX) / AlphaBar.AbsoluteSize.X
					ColorPicker:Update()

					RunService.RenderStepped:Wait()
				end
			end))
		end

		ColorPicker:Display()

		ColorPicker.Holder = Holder
		table.insert(Groupbox.Elements, ColorPicker)
		Register(ColorPicker, Idx)
		FlagValue(ColorPicker, Idx, ColorPicker.Value)
		Groupbox:Resize()

		return ColorPicker
	end

	function Funcs:AddKeybind(Idx, Info)
		if self.Destroyed then
			return nil
		end

		Info = Library:Validate(Info, Templates.Keybind)

		local Groupbox = self
		local Container = Groupbox.Container

		local Keybind = {
			Connections = {},
			Destroyed = false,

			Text = Info.Text,
			Value = Info.Default,
			Mode = Info.Mode,
			Toggled = false,
			Callback = Info.Callback,
			Changed = Info.Changed,
			Visible = true,
			SearchText = Info.Text,
			Type = "Keybind",
		}
		local Picking = false

		local Holder = New("Frame", {
			BackgroundTransparency = 1,
			Name = "Keybind",
			Size = UDim2.new(1, 0, 0, 24),
			Parent = Container,
		})

		local Label = New("TextLabel", {
			BackgroundTransparency = 1,
			Name = "Label",
			Size = UDim2.new(1, -74, 1, 0),
			Text = Keybind.Text,
			TextSize = 14,
			TextTransparency = 0.4,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})

		local Picker = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = "MainColor",
			Name = "Picker",
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromOffset(66, 24),
			Text = Keybind.Value,
			TextSize = 13,
			TextTransparency = 0.5,
			Parent = Holder,
		})
		AddUICorner(Picker, Library.CornerRadius / 2)
		New("UIStroke", {
			Color = "OutlineColor",
			Parent = Picker,
		})

		local SpecialKeys = {
			["MB1"] = Enum.UserInputType.MouseButton1,
			["MB2"] = Enum.UserInputType.MouseButton2,
			["MB3"] = Enum.UserInputType.MouseButton3,
		}

		local SpecialKeysInput = {
			[Enum.UserInputType.MouseButton1] = "MB1",
			[Enum.UserInputType.MouseButton2] = "MB2",
			[Enum.UserInputType.MouseButton3] = "MB3",
		}

		local function KeyFromInput(Input)
			if SpecialKeysInput[Input.UserInputType] then
				return SpecialKeysInput[Input.UserInputType]
			elseif Input.UserInputType == Enum.UserInputType.Keyboard then
				return Input.KeyCode == Enum.KeyCode.Escape and "None" or Input.KeyCode.Name
			end
			return nil
		end

		local function IsPressed(Input)
			if Keybind.Value == "None" then
				return false
			end

			if SpecialKeys[Keybind.Value] then
				return Input.UserInputType == SpecialKeys[Keybind.Value]
			end

			return Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Keybind.Value
		end

		function Keybind:Display()
			if Keybind.Destroyed then
				return
			end
			Picker.Text = Picking and "..." or Keybind.Value
		end

		function Keybind:OnChanged(Func)
			Keybind.Changed = Func
		end

		function Keybind:RunChanged(State)
			Library:SafeCallback(Keybind.Callback, State)
			Library:SafeCallback(Keybind.Changed, State)
		end

		function Keybind:SetValue(Value)
			Keybind.Value = Value or "None"
			if Keybind.Flag then
				Keybind.Flag.Value = Keybind.Value
			end
			Keybind:Display()
		end

		function Keybind:SetVisible(Visible)
			Keybind.Visible = Visible == true
			Holder.Visible = Keybind.Visible
			Groupbox:Resize()
		end

		function Keybind:Destroy()
			Keybind.Destroyed = true

			if Keybind.Connections then
				for _, Connection in Keybind.Connections do
					Connection:Disconnect()
				end
			end

			if Holder then
				Holder:Destroy()
			end

			local ElemIdx = table.find(Groupbox.Elements, Keybind)
			if ElemIdx then
				table.remove(Groupbox.Elements, ElemIdx)
			end

			Groupbox:Resize()
			Unregister(Keybind)
		end

		Picker.MouseButton1Click:Connect(function()
			if Keybind.Destroyed or Picking then
				return
			end

			Picking = true
			Keybind:Display()

			local Input = UserInputService.InputBegan:Wait()
			if Keybind.Destroyed then
				return
			end

			Picking = false
			local Key = KeyFromInput(Input)
			if Key then
				Keybind:SetValue(Key)
			end
			Keybind:Display()
		end)

		table.insert(Keybind.Connections, UserInputService.InputBegan:Connect(function(Input)
			if Library.Unloaded or Keybind.Destroyed then
				return
			end
			if Picking or UserInputService:GetFocusedTextBox() then
				return
			end
			if not IsPressed(Input) then
				return
			end

			if Keybind.Mode == "Toggle" then
				Keybind.Toggled = not Keybind.Toggled
				Keybind:RunChanged(Keybind.Toggled)
			else
				Keybind:RunChanged(true)
			end
		end))

		if Keybind.Mode == "Hold" then
			table.insert(Keybind.Connections, UserInputService.InputEnded:Connect(function(Input)
				if Library.Unloaded or Keybind.Destroyed then
					return
				end
				if IsPressed(Input) then
					Keybind:RunChanged(false)
				end
			end))
		end

		Keybind:Display()

		Keybind.Holder = Holder
		Keybind.Groupbox = Groupbox
		table.insert(Groupbox.Elements, Keybind)
		Register(Keybind, Idx)
		FlagValue(Keybind, Idx, Keybind.Value)
		Groupbox:Resize()

		return Keybind
	end

	function Funcs:AddDependencyBox()
		if self.Destroyed then
			return nil
		end

		local Groupbox = self
		local Container = Groupbox.Container

		local DepboxContainer = New("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Name = "DependencyBox",
			Size = UDim2.new(1, 0, 0, 0),
			Visible = false,
			Parent = Container,
		})
		New("UIListLayout", {
			Padding = UDim.new(0, 6),
			Parent = DepboxContainer,
		})
		New("UIPadding", {
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			PaddingTop = UDim.new(0, 4),
			Parent = DepboxContainer,
		})

		local Depbox = {
			Connections = {},
			Destroyed = false,

			Visible = false,
			Dependencies = {},
			Elements = {},
			DependencyBoxes = {},

			Holder = DepboxContainer,
			Container = DepboxContainer,
			Type = "DependencyBox",
		}

		function Depbox:Resize()
			if Depbox.Destroyed then
				return
			end
			DepboxContainer.Size = UDim2.new(1, 0, 0, DepboxContainer.AbsoluteSize.Y)
			Groupbox:Resize()
		end

		function Depbox:Update()
			for _, Dependency in Depbox.Dependencies do
				local Element = Dependency[1]
				local Expected = Dependency[2]

				if Element.Type == "Toggle" and Element.Value ~= Expected then
					DepboxContainer.Visible = false
					Depbox.Visible = false
					Groupbox:Resize()
					return
				elseif Element.Type == "Dropdown" then
					if typeof(Element.Value) == "table" then
						if not Element.Value[Expected] then
							DepboxContainer.Visible = false
							Depbox.Visible = false
							Groupbox:Resize()
							return
						end
					elseif Element.Value ~= Expected then
						DepboxContainer.Visible = false
						Depbox.Visible = false
						Groupbox:Resize()
						return
					end
				end
			end

			Depbox.Visible = true
			DepboxContainer.Visible = true
			Groupbox:Resize()
		end

		function Depbox:SetupDependencies(Dependencies)
			Depbox.Dependencies = Dependencies or {}
			Depbox:Update()
		end

		function Depbox:Destroy()
			Depbox.Destroyed = true

			for _, Element in Depbox.Elements do
				if Element.Destroy then
					Element:Destroy()
				end
			end

			if DepboxContainer then
				DepboxContainer:Destroy()
			end

			local ElemIdx = table.find(Groupbox.DependencyBoxes, Depbox)
			if ElemIdx then
				table.remove(Groupbox.DependencyBoxes, ElemIdx)
			end

			local LibIdx = table.find(Library.DependencyBoxes, Depbox)
			if LibIdx then
				table.remove(Library.DependencyBoxes, LibIdx)
			end

			Groupbox:Resize()
		end

		setmetatable(Depbox, BaseGroupbox)

		table.insert(Groupbox.DependencyBoxes, Depbox)
		table.insert(Library.DependencyBoxes, Depbox)

		return Depbox
	end

	BaseGroupbox.__index = Funcs
end

function Library:UpdateDependencyBoxes()
	for _, Depbox in Library.DependencyBoxes do
		if Depbox.Update then
			Depbox:Update()
		end
	end
end

local function ResetGroupbox(Groupbox)
	for _, Element in Groupbox.Elements do
		Element.Holder.Visible = Element.Visible ~= false
	end

	for _, Depbox in Groupbox.DependencyBoxes do
		if Depbox.Visible then
			ResetGroupbox(Depbox)
		end
	end

	Groupbox.Holder.Visible = Groupbox.Visible ~= false
	Groupbox:Resize()
end

local function SearchGroupbox(Groupbox, Search)
	local Visible = 0

	for _, Element in Groupbox.Elements do
		if Element.Type == "Divider" or Element.Type == "Section" then
			Element.Holder.Visible = false
			continue
		end

		local Match = Element.Visible ~= false
			and Element.SearchText
			and Element.SearchText:lower():match(Search) ~= nil

		Element.Holder.Visible = Match == true
		if Match then
			Visible += 1
		end
	end

	for _, Depbox in Groupbox.DependencyBoxes do
		if Depbox.Visible then
			Visible += SearchGroupbox(Depbox, Search)
		end
	end

	Groupbox.Holder.Visible = Visible > 0
	Groupbox:Resize()

	return Visible
end

function Library:UpdateSearch(SearchText)
	Library.SearchText = SearchText

	local Active = Library.ActiveTab
	if not Active or not Active.Groupboxes then
		return
	end

	if Trim(SearchText) == "" then
		Library.Searching = false
		for _, Groupbox in Active.Groupboxes do
			ResetGroupbox(Groupbox)
		end
		return
	end

	Library.Searching = true

	local Search = SearchText:lower()
	for _, Groupbox in Active.Groupboxes do
		if Groupbox.Visible == false then
			continue
		end
		SearchGroupbox(Groupbox, Search)
	end
end

function Library:CreateWindow(WindowInfo)
	WindowInfo = Library:Validate(WindowInfo, Templates.Window)

	if typeof(WindowInfo.ToggleKey) == "EnumItem" then
		Library.ToggleKey = WindowInfo.ToggleKey
	end

	local MinSize = Vector2.new(WindowInfo.MinSize.X.Offset, WindowInfo.MinSize.Y.Offset)
	local MaxSize = Vector2.new(WindowInfo.MaxSize.X.Offset, WindowInfo.MaxSize.Y.Offset)
	local BaseSize = WindowInfo.Size
	local Maximized = false

	Library.CornerRadius = WindowInfo.UiCorner.Offset
	Library.MinSize = MinSize

	local Main = New("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = "Background",
		GroupTransparency = 1,
		Name = "Main",
		Position = WindowInfo.Position or UDim2.fromScale(0.5, 0.5),
		Size = WindowInfo.Size,
		Visible = false,
		Parent = ScreenGui,
	})

	if not WindowInfo.Position then
		Main.Position = UDim2.new(0.5, 0, 0.5, 0)
	end

	AddUICorner(Main, WindowInfo.UiCorner.Offset)
	New("UIShadow", {
		BlurRadius = UDim.new(0, 24),
		Color = Color3.fromRGB(0, 0, 0),
		Transparency = 0.6,
		Offset = UDim2.fromOffset(0, 8),
		Parent = Main,
	})

	local Sidebar = New("Frame", {
		BackgroundColor3 = "SidebarColor",
		Name = "Sidebar",
		Size = UDim2.new(0.25, 0, 1, 0),
		Parent = Main,
	})
	
	New("UICorner", {
		BottomLeftRadius = UDim.new(0, Library.CornerRadius),
		BottomRightRadius = UDim.new(0, 0),
		TopLeftRadius = UDim.new(0, Library.CornerRadius),
		TopRightRadius = UDim.new(0, 0),

		Parent = Sidebar,
	})

	local TrafficLights = New("Frame", {
		BackgroundTransparency = 1,
		Name = "TrafficLights",
		Position = UDim2.fromOffset(16, 16),
		Size = UDim2.fromOffset(70, 14),
		Parent = Sidebar,
	})

	local DotColors = {
		{ Color = Color3.fromRGB(255, 95, 87), Name = "Close" },
		{ Color = Color3.fromRGB(255, 189, 46), Name = "Minimize" },
		{ Color = Color3.fromRGB(40, 200, 64), Name = "Maximize" },
	}

	local function ToggleMaximize()
		Maximized = not Maximized
		local Target = Maximized and UDim2.fromOffset(
			workspace.CurrentCamera.ViewportSize.X - 40,
			workspace.CurrentCamera.ViewportSize.Y - 40
		) or BaseSize

		Library:Tween(Main, { Size = Target }, { Style = "Smooth" })
		Main.Position = UDim2.new(0.5, 0, 0.5, 0)
	end

	for i, data in ipairs(DotColors) do
		local Dot = New("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = data.Color,
			Size = UDim2.fromOffset(12, 12),
			Position = UDim2.fromOffset((i - 1) * 22, 1),
			Text = "",
			Parent = TrafficLights,
		})
		AddUICorner(Dot, 6, true)
		New("UIShadow", {
			BlurRadius = UDim.new(0, 8),
			Color = data.Color,
			Transparency = 0.35,
			Spread = UDim2.fromOffset(2, 2),
			Parent = Dot,
		})

		if data.Name == "Close" then
			Dot.MouseButton1Click:Connect(function()
				Window:Toggle(false)
			end)
		elseif data.Name == "Minimize" then
			Dot.MouseButton1Click:Connect(function()
				Window:Toggle(false)
			end)
		elseif data.Name == "Maximize" then
			Dot.MouseButton1Click:Connect(ToggleMaximize)
		end
	end

	local hasTitle = WindowInfo.Title ~= nil and WindowInfo.Title ~= ""
	local hasSubTitle = WindowInfo.SubTitle ~= nil and WindowInfo.SubTitle ~= ""
	local headerOffset = 40

	local TitleLabel = nil
	local SubTitleLabel = nil

	if hasTitle then
		TitleLabel = New("TextLabel", {
			BackgroundTransparency = 1,
			Name = "TitleLabel",
			Position = UDim2.fromOffset(16, headerOffset),
			Size = UDim2.new(1, -24, 0, 20),
			Text = WindowInfo.Title,
			TextColor3 = "WhiteColor",
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Sidebar,
		})
		headerOffset = headerOffset + 22
	end

	if hasSubTitle then
		SubTitleLabel = New("TextLabel", {
			BackgroundTransparency = 1,
			Name = "SubTitleLabel",
			Position = UDim2.fromOffset(16, headerOffset),
			Size = UDim2.new(1, -24, 0, 16),
			Text = WindowInfo.SubTitle,
			TextColor3 = "WhiteColor",
			TextSize = 11,
			TextTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Sidebar,
		})
		headerOffset = headerOffset + 20
	end

	local Tabs = New("ScrollingFrame", {
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		CanvasSize = UDim2.fromScale(0, 0),
		Name = "Tabs",
		Position = UDim2.fromOffset(0, headerOffset + 8),
		ScrollBarThickness = 0,
		Size = UDim2.new(1, 0, 1, -(headerOffset + 8)),
		Parent = Sidebar,
	})
	New("UIListLayout", {
		Name = "TabLayout",
		Padding = UDim.new(0, 4),
		Parent = Tabs,
	})
	New("UIPadding", {
		Name = "TabPadding",
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 4),
		Parent = Tabs,
	})

	local Content = New("Frame", {
		BackgroundColor3 = "Background",
		Name = "Content",
		Position = UDim2.new(0.25, 0, 0, 0),
		Size = UDim2.new(0.75, 0, 1, 0),
		Parent = Main,
	})

	local ContentHeader = New("Frame", {
		BackgroundTransparency = 1,
		Name = "ContentHeader",
		Size = UDim2.new(1, 0, 0, 40),
		Parent = Content,
	})

	local SearchBox = New("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = "MainColor",
		ClearTextOnFocus = false,
		Name = "SearchBox",
		PlaceholderText = "Search...",
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(180, 26),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = ContentHeader,
	})
	AddUICorner(SearchBox, 8)
	New("UIStroke", {
		Color = "OutlineColor",
		Name = "SearchBoxOutline",
		Parent = SearchBox,
	})
	New("UIPadding", {
		Name = "SearchBoxPadding",
		PaddingLeft = UDim.new(0, 10),
		Parent = SearchBox,
	})

	local TabLayer = New("Frame", {
		BackgroundTransparency = 1,
		Name = "TabLayer",
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 1, -40),
		Parent = Content,
	})

	if WindowInfo.Draggable then
		Library:MakeDraggable(Main, Sidebar, true)
	end

	if WindowInfo.Resizable and not WindowInfo.LockResize then
		local ResizeGrip = New("TextButton", {
			AnchorPoint = Vector2.new(1, 1),
			BackgroundTransparency = 1,
			Name = "ResizeGrip",
			Position = UDim2.new(1, 0, 1, 0),
			Size = UDim2.fromOffset(20, 20),
			Text = "",
			Parent = Main,
		})
		Library:MakeResizable(Main, ResizeGrip)
	end

	Library:GiveSignal(SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		Library:UpdateSearch(SearchBox.Text)
	end))

	local Window = {}
	local Fading = false

	function Window:ChangeTitle(NewTitle)
		WindowInfo.Title = NewTitle or ""
		if TitleLabel then
			TitleLabel.Text = WindowInfo.Title
		end
	end

	function Window:ChangeSubTitle(NewSubTitle)
		WindowInfo.SubTitle = NewSubTitle or ""
		if SubTitleLabel then
			SubTitleLabel.Text = WindowInfo.SubTitle
		end
	end

	function Window:SetCornerRadius(Radius)
		Radius = math.clamp(Radius or Library.CornerRadius, 0, 20)
		Library.CornerRadius = Radius

		for _, Entry in Library.Corners do
			Entry.Corner.CornerRadius = UDim.new(0, math.max(0, Entry.Ratio * Radius))
		end

		for _, Entry in Library.SpecificCorners do
			Entry.Corner.CornerRadius = UDim.new(0, math.max(0, Entry.Ratio * Radius))
		end
	end

	function Window:SetAnimations(Animations)
		if typeof(Animations) == "table" then
			WindowInfo.Animations = Animations
		end
	end

	function Window:AddTab(...)
		local Name = select(1, ...)
		local Icon = select(2, ...)

		if typeof(Name) == "table" then
			local Info = Name
			Name = Info.Name or "Tab"
			Icon = Info.Icon
		end

		local TabButton = New("TextButton", {
			BackgroundColor3 = "MainColor",
			BackgroundTransparency = 1,
			Name = "Tab_" .. tostring(Name),
			Size = UDim2.new(1, 0, 0, 36),
			Text = "",
			Parent = Tabs,
		})
		AddUICorner(TabButton, 8, true)

		local leftPad = 12
		local TabIcon = nil

		if Icon then
			leftPad = 36
			TabIcon = New("ImageLabel", {
				BackgroundTransparency = 1,
				Name = "Icon",
				Position = UDim2.new(0, 12, 0.5, -8),
				Size = UDim2.fromOffset(16, 16),
				Image = Library:GetIcon(Icon),
				ImageColor3 = Color3.fromRGB(255, 255, 255),
				ImageTransparency = 0.4,
				Parent = TabButton,
			})
		end

		local TabLabel = New("TextLabel", {
			BackgroundTransparency = 1,
			Name = "Label",
			Position = UDim2.fromOffset(leftPad, 0),
			Size = UDim2.new(1, -(leftPad + 8), 1, 0),
			Text = Name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			TextTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = TabButton,
		})

		table.insert(Library.TabButtons, TabButton)

		local TabCanvas = New("CanvasGroup", {
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			Name = "Tab_" .. tostring(Name),
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			Parent = TabLayer,
		})

		local TabContainer = New("Frame", {
			BackgroundTransparency = 1,
			Name = "Container",
			Size = UDim2.fromScale(1, 1),
			Parent = TabCanvas,
		})

		local TabLeft = New("ScrollingFrame", {
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			CanvasSize = UDim2.fromScale(0, 0),
			Name = "TabLeft",
			ScrollBarThickness = 3,
			Size = UDim2.new(0.5, -3, 1, 0),
			Parent = TabContainer,
		})
		New("UIListLayout", {
			Name = "LeftLayout",
			Padding = UDim.new(0, 6),
			Parent = TabLeft,
		})
		New("UIPadding", {
			Name = "LeftPadding",
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			PaddingTop = UDim.new(0, 4),
			Parent = TabLeft,
		})

		local TabRight = New("ScrollingFrame", {
			AnchorPoint = Vector2.new(1, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			CanvasSize = UDim2.fromScale(0, 0),
			Name = "TabRight",
			Position = UDim2.fromScale(1, 0),
			ScrollBarThickness = 3,
			Size = UDim2.new(0.5, -3, 1, 0),
			Parent = TabContainer,
		})
		New("UIListLayout", {
			Name = "RightLayout",
			Padding = UDim.new(0, 6),
			Parent = TabRight,
		})
		New("UIPadding", {
			Name = "RightPadding",
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			PaddingTop = UDim.new(0, 4),
			Parent = TabRight,
		})

		local Tab = {
			Connections = {},
			Destroyed = false,

			Window = Window,
			Canvas = TabCanvas,
			Sides = { TabLeft, TabRight },

			Groupboxes = {},
			DependencyBoxes = {},
		}

		function Tab:Resize()
			for _, Groupbox in Tab.Groupboxes do
				Groupbox:Resize()
			end
		end

		function Tab:Hover(Hovering)
			if Library.ActiveTab == Tab then
				return
			end
			Library:Tween(TabLabel, { TextTransparency = Hovering and 0.25 or 0.5 }, "Fast")
			if TabIcon then
				Library:Tween(TabIcon, { ImageTransparency = Hovering and 0.2 or 0.4 }, "Fast")
			end
		end

		function Tab:Show()
			if Library.ActiveTab == Tab then
				return
			end
			if Library.ActiveTab then
				Library.ActiveTab:Hide()
			end

			Library:PlayTabAnimation(TabCanvas, true)
			Library:Tween(TabButton, { BackgroundTransparency = 0 }, "Fast")
			Library:Tween(TabLabel, { TextTransparency = 0 }, "Fast")
			if TabIcon then
				Library:Tween(TabIcon, { ImageTransparency = 0 }, "Fast")
			end

			Library.ActiveTab = Tab

			if Library.Searching then
				Library:UpdateSearch(Library.SearchText)
			end
		end

		function Tab:Hide()
			Library:PlayTabAnimation(TabCanvas, false)
			Library:Tween(TabButton, { BackgroundTransparency = 1 }, "Fast")
			Library:Tween(TabLabel, { TextTransparency = 0.5 }, "Fast")
			if TabIcon then
				Library:Tween(TabIcon, { ImageTransparency = 0.4 }, "Fast")
			end

			Library.ActiveTab = nil
		end

		function Tab:SetVisible(Visible)
			TabButton.Visible = Visible == true
		end

		function Tab:Destroy()
			Tab.Destroyed = true

			for _, Groupbox in Tab.Groupboxes do
				if Groupbox.Destroy then
					Groupbox:Destroy()
				end
			end
			table.clear(Tab.Groupboxes)

			if TabCanvas then
				TabCanvas:Destroy()
			end
			if TabButton then
				TabButton:Destroy()
			end

			Library.Tabs[Name] = nil
		end

		function Tab:AddGroupbox(Info)
			if typeof(Info) == "string" then
				Info = { Name = Info, Side = 1 }
			end
			Info.Side = Info.Side or 1

			local Side = Info.Side == 2 and TabRight or TabLeft

			local GroupboxHolder = New("Frame", {
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = "Background",
				Name = "Groupbox_" .. tostring(Info.Name),
				Size = UDim2.new(1, 0, 0, 0),
				Parent = Side,
			})
			AddUICorner(GroupboxHolder, Library.CornerRadius)
			New("UIStroke", {
				Color = "OutlineColor",
				Name = "Outline",
				Parent = GroupboxHolder,
			})

			local GroupboxHeader = New("Frame", {
				BackgroundTransparency = 1,
				Name = "Header",
				Size = UDim2.new(1, 0, 0, 34),
				Parent = GroupboxHolder,
			})

			local GroupboxLabel = New("TextLabel", {
				BackgroundTransparency = 1,
				Name = "Label",
				Size = UDim2.new(1, 0, 1, 0),
				Text = Info.Name,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = GroupboxHeader,
			})
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				Parent = GroupboxLabel,
			})

			Library:MakeLine(GroupboxHolder, {
				Position = UDim2.fromOffset(0, 34),
				Size = UDim2.new(1, 0, 0, 1),
			})

			local GroupboxContainer = New("Frame", {
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Name = "Container",
				Position = UDim2.fromOffset(0, 35),
				Size = UDim2.new(1, 0, 0, 0),
				Parent = GroupboxHolder,
			})
			New("UIListLayout", {
				Name = "Layout",
				Padding = UDim.new(0, 8),
				Parent = GroupboxContainer,
			})
			New("UIPadding", {
				Name = "Padding",
				PaddingBottom = UDim.new(0, 7),
				PaddingLeft = UDim.new(0, 7),
				PaddingRight = UDim.new(0, 7),
				PaddingTop = UDim.new(0, 7),
				Parent = GroupboxContainer,
			})

			local CollapseArrow = New("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 1,
				Name = "CollapseArrow",
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(14, 14),
				Text = "❯",
				TextSize = 12,
				TextTransparency = 0.5,
				TextRotation = 90,
				Parent = GroupboxHeader,
			})

			local Groupbox = {
				Type = "Groupbox",

				Connections = {},
				Destroyed = false,

				Visible = true,
				Collapsed = false,

				Holder = GroupboxHolder,
				Container = GroupboxContainer,

				Tab = Tab,
				Elements = {},
				DependencyBoxes = {},
			}

			function Groupbox:Resize()
				if Groupbox.Destroyed then
					return
				end
				local Target = UDim2.new(1, 0, 0, Groupbox.Collapsed and 35 or (GroupboxContainer.AbsoluteSize.Y + 35))
				GroupboxHolder.Size = Target
			end

			function Groupbox:SetCollapsed(Collapsed)
				Groupbox.Collapsed = Collapsed == true
				GroupboxContainer.Visible = not Groupbox.Collapsed
				Library:Tween(CollapseArrow, { TextRotation = Groupbox.Collapsed and 90 or 270 }, "Fast")
				Library:Tween(GroupboxHolder, {
					Size = UDim2.new(1, 0, 0, Groupbox.Collapsed and 35 or (GroupboxContainer.AbsoluteSize.Y + 35)),
				}, "Smooth")
			end

			function Groupbox:ToggleCollapsed()
				Groupbox:SetCollapsed(not Groupbox.Collapsed)
			end

			function Groupbox:SetVisible(Visible)
				Groupbox.Visible = Visible == true
				GroupboxHolder.Visible = Groupbox.Visible
			end

			function Groupbox:Show()
				Groupbox:SetVisible(true)
			end

			function Groupbox:Hide()
				Groupbox:SetVisible(false)
			end

			function Groupbox:Destroy()
				Groupbox.Destroyed = true

				for _, Element in Groupbox.Elements do
					if Element.Destroy then
						Element:Destroy()
					end
				end
				table.clear(Groupbox.Elements)

				for _, SubDepbox in Groupbox.DependencyBoxes do
					if SubDepbox.Destroy then
						SubDepbox:Destroy()
					end
				end

				if GroupboxHolder then
					GroupboxHolder:Destroy()
				end

				local ElemIdx = table.find(Tab.Groupboxes, Groupbox)
				if ElemIdx then
					table.remove(Tab.Groupboxes, ElemIdx)
				end
			end

			GroupboxHeader.InputBegan:Connect(function(Input)
				if IsClickInput(Input) then
					Groupbox:ToggleCollapsed()
				end
			end)

			GroupboxContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				Groupbox:Resize()
			end)

			setmetatable(Groupbox, BaseGroupbox)

			table.insert(Tab.Groupboxes, Groupbox)

			Groupbox:Resize()

			if Info.Visible == false then
				Groupbox:Hide()
			end
			if Info.Collapsed == true then
				Groupbox:SetCollapsed(true)
			end

			return Groupbox
		end

		function Tab:AddLeftGroupbox(Name, Visible, Collapsed)
			return Tab:AddGroupbox({ Name = Name, Side = 1, Visible = Visible, Collapsed = Collapsed })
		end

		function Tab:AddRightGroupbox(Name, Visible, Collapsed)
			return Tab:AddGroupbox({ Name = Name, Side = 2, Visible = Visible, Collapsed = Collapsed })
		end

		if not Library.ActiveTab then
			Tab:Show()
		end

		TabButton.MouseEnter:Connect(function()
			Tab:Hover(true)
		end)
		TabButton.MouseLeave:Connect(function()
			Tab:Hover(false)
		end)
		TabButton.MouseButton1Click:Connect(function()
			Tab:Show()
		end)

		Library.Tabs[Name] = Tab

		return Tab
	end

	function Window:Toggle(Value)
		if Window.Destroyed then
			return
		end

		if typeof(Value) == "boolean" then
			Library.Toggled = Value
		else
			Library.Toggled = not Library.Toggled
		end

		if Library.Animations and WindowInfo.Animations.ToggleWindow then
			if Library.Toggled then
				Main.Visible = true
			end

			Library:Tween(Main, {
				GroupTransparency = Library.Toggled and 0 or 1,
			}, { Style = "Smooth", Callback = function()
				if not Library.Toggled then
					Main.Visible = false
				end
			end })
		else
			Main.Visible = Library.Toggled
		end
	end

	function Window:Destroy()
		Window.Destroyed = true

		local Idx = table.find(Library.Windows, Window)
		if Idx then
			table.remove(Library.Windows, Idx)
		end

		if Library.ActiveTab then
			Library.ActiveTab = nil
		end

		if Main then
			Main:Destroy()
		end

		if Library.Window == Window then
			Library.Window = nil
		end
	end

	function Library:Toggle(Value)
		if Library.Window then
			return Library.Window:Toggle(Value)
		end
	end

	if WindowInfo.AutoShow then
		task.spawn(function()
			Window:Toggle(true)
		end)
	end

	Library.Window = Window
	table.insert(Library.Windows, Window)

	return Window
end

Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input)
	if Library.Unloaded then
		return
	end

	if IsClickInput(Input) then
		local Location = Input.Position
		local Popups = {}
		for Popup, _ in Library.OpenPopups do
			table.insert(Popups, Popup)
		end

		for _, Popup in Popups do
			if Popup.Active and not (
				Library:MouseIsOverFrame(Popup.Popup, Location)
					or Library:MouseIsOverFrame(Popup.Holder, Location)
				) then
				Popup:Close()
			end
		end
	end

	if UserInputService:GetFocusedTextBox() then
		return
	end

	if Input.KeyCode == Library.ToggleKey then
		Library:Toggle()
	end
end))

Library:GiveSignal(UserInputService.WindowFocused:Connect(function()
	Library.IsRobloxFocused = true
end))
Library:GiveSignal(UserInputService.WindowFocusReleased:Connect(function()
	Library.IsRobloxFocused = false
end))

function Library:SetFont(FontFace)
	if typeof(FontFace) == "EnumItem" then
		FontFace = Font.fromEnum(FontFace)
	end
	Library.Scheme.Font = FontFace
	Library:UpdateColorsUsingRegistry()
end

function Library:SetThemeColor(Key, Value)
	if Library.Scheme[Key] == nil then
		return
	end
	Library.Scheme[Key] = Value
	Library:UpdateColorsUsingRegistry()
end

function Library:Unload()
	if Library.Unloaded then
		return
	end
	Library.Unloaded = true

	for Index = #Library.Connections, 1, -1 do
		local Connection = table.remove(Library.Connections, Index)
		if Connection and Connection.Connected then
			Connection:Disconnect()
		end
	end

	for _ = 1, #Library.UnloadCallbacks do
		local Callback = table.remove(Library.UnloadCallbacks, 1)
		if Callback then
			Library:SafeCallback(Callback)
		end
	end

	for Index = #Library.Windows, 1, -1 do
		local Window = table.remove(Library.Windows, Index)
		if Window and Window.Destroy then
			Window:Destroy()
		end
	end

	for _, Tooltip in Library.Tooltips do
		if Tooltip.Destroy then
			Tooltip:Destroy()
		end
	end

	if Library.ScreenGui then
		Library.ScreenGui:Destroy()
	end

	table.clear(Library.Registry)
	table.clear(Library.Flags)
	table.clear(Library.Options)
	table.clear(Library.Tabs)
	table.clear(Library.TabButtons)
	table.clear(Library.Notifications)
	table.clear(Library.Tooltips)
	table.clear(Library.Corners)
	table.clear(Library.SpecificCorners)
	table.clear(Library.DependencyBoxes)
	table.clear(NotifyOrder)
	table.clear(ActiveTabTweens)

	Library.Window = nil
	Library.ScreenGui = nil
	Library.ActiveTab = nil
	Library.Toggled = false
end

return Library
