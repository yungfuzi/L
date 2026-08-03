local Library = {
	Version = "1.0.0",
	Animations = true,
	ToggleKey = Enum.KeyCode.RightShift,
	Flags = {},
	Options = {},
	Scheme = {},
	Icons = {},
	Overlay = nil,
	ScreenGui = nil,
	Connections = {},
	UnloadCallbacks = {},
	Registry = {},
	FontRegistry = {},
	Windows = {},
	Notifications = {},
	OpenPopups = {},
	_destroyed = false,
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")

Library.Scheme = {
	Background = Color3.fromRGB(255, 255, 255),
	SidebarColor = Color3.fromRGB(100, 100, 100),
	FontColor = Color3.fromRGB(30, 30, 30),
	TitleColor = Color3.fromRGB(20, 20, 20),
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

function Library:Tween(instance, properties, options)
	options = options or {}

	if not self.Animations then
		for prop, value in pairs(properties) do
			instance[prop] = value
		end
		if options.Callback then
			task.spawn(options.Callback)
		end
		return nil
	end

	local config = {}
	for k, v in pairs(self.Animation.Default) do
		config[k] = v
	end

	if options.Style and self.Animation.Presets[options.Style] then
		for k, v in pairs(self.Animation.Presets[options.Style]) do
			config[k] = v
		end
	end

	if options.Duration then config.Duration = options.Duration end
	if options.EasingStyle then config.EasingStyle = options.EasingStyle end
	if options.EasingDirection then config.EasingDirection = options.EasingDirection end
	if options.RepeatCount then config.RepeatCount = options.RepeatCount end
	if options.Reverses ~= nil then config.Reverses = options.Reverses end
	if options.DelayTime then config.DelayTime = options.DelayTime end

	local tweenInfo = TweenInfo.new(
		config.Duration,
		config.EasingStyle,
		config.EasingDirection,
		config.RepeatCount,
		config.Reverses,
		config.DelayTime
	)

	local tween = TweenService:Create(instance, tweenInfo, properties)

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
}

function Library:GetIcon(name)
	if typeof(name) == "string" then
		if name:match("^rbxassetid://") or name:match("^rbxasset://") then
			return name
		end
		return self.Icons[name] or name
	end
	return name
end

local function ResolveValue(value, theme)
	if type(value) == "string" and theme[value] then
		return theme[value]
	end
	return value
end

local function Create(class, props, theme)
	theme = theme or Library.Scheme

	local defaults = Templates[class] or {}
	local finalProps = {}

	for k, v in pairs(defaults) do
		finalProps[k] = v
	end

	for k, v in pairs(props or {}) do
		finalProps[k] = v
	end

	for k, v in pairs(finalProps) do
		if type(v) == "string" and theme[v] then
			finalProps[k] = theme[v]
		elseif type(v) == "function" then
			finalProps[k] = v()
		end
	end

	local inst = Instance.new(class)
	for k, v in pairs(finalProps) do
		if k ~= "Parent" then
			inst[k] = v
		end
	end

	if props and props.Parent then
		inst.Parent = props.Parent
	end

	return inst
end

local function HSVToRGB(H, S, V)
	if S == 0 then
		return V, V, V
	end
	local i = math.floor(H * 6)
	local f = H * 6 - i
	local p = V * (1 - S)
	local q = V * (1 - f * S)
	local t = V * (1 - (1 - f) * S)
	i = i % 6
	if i == 0 then
		return V, t, p
	elseif i == 1 then
		return q, V, p
	elseif i == 2 then
		return p, V, t
	elseif i == 3 then
		return p, q, V
	elseif i == 4 then
		return t, p, V
	else
		return V, p, q
	end
end

local function RGBToHSV(R, G, B)
	local max = math.max(R, G, B)
	local min = math.min(R, G, B)
	local V = max
	local delta = max - min
	if delta == 0 then
		return 0, 0, V
	end
	local S = delta / max
	local H = 0
	if max == R then
		H = (G - B) / delta + (G < B and 6 or 0)
	elseif max == G then
		H = (B - R) / delta + 2
	else
		H = (R - G) / delta + 4
	end
	H = H / 6
	return H, S, V
end

local function MakeDraggable(frame, handle)
	handle = handle or frame

	local dragging = false
	local dragStart = nil
	local startPos = nil

	local function update(input)
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				update(input)
			end
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				update(input)
			end
		end
	end)
end

function Library:CreateWindow(opts)
	opts = opts or {}

	local window = setmetatable({}, { __index = Library })

	local Title = opts.Title or "Aero"
	local SubTitle = opts.SubTitle or ""
	local Size = opts.Size or UDim2.new(0, 700, 0, 450)
	local MinSize = opts.MinSize or Size
	local MaxSize = opts.MaxSize or Size
	local lockResize = opts.LockResize
	local cornerRadius = opts.UiCorner or UDim.new(0, 16)
	local draggable = opts.Draggable ~= false

	local ScreenGui = Create("ScreenGui", {
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})

	local Main = Create("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = self.Scheme.Background,
		Parent = ScreenGui,
	})

	Create("UIShadow", {
		BlurRadius = UDim.new(0, 24),
		Color = Color3.fromRGB(0, 0, 0),
		Transparency = 0.6,
		Offset = UDim2.fromOffset(0, 8),
		Parent = Main,
	})

	Create("UICorner", {
		CornerRadius = cornerRadius,
		Parent = Main,
	})

	local TitleBar = Create("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		Parent = Main,
	})

	local TrafficLights = Create("Frame", {
		Name = "TrafficLights",
		Size = UDim2.fromOffset(70, 14),
		Position = UDim2.fromOffset(16, 17),
		BackgroundTransparency = 1,
		Parent = TitleBar,
	})

	local DotColors = {
		{ Color = Color3.fromRGB(255, 95, 87), Name = "Close" },
		{ Color = Color3.fromRGB(255, 189, 46), Name = "Minimize" },
		{ Color = Color3.fromRGB(40, 200, 64), Name = "Maximize" },
	}

	for i, data in ipairs(DotColors) do
		local Dot = Create("Frame", {
			Name = data.Name,
			Size = UDim2.fromOffset(12, 12),
			Position = UDim2.fromOffset((i - 1) * 22, 1),
			BackgroundColor3 = data.Color,
			Parent = TrafficLights,
		})

		Create("UICorner", {
			CornerRadius = UDim.new(1, 0),
			Parent = Dot,
		})

		Create("UIShadow", {
			BlurRadius = UDim.new(0, 8),
			Color = data.Color,
			Transparency = 0.35,
			Offset = UDim2.fromOffset(0, 0),
			Spread = UDim2.fromOffset(2, 2),
			Parent = Dot,
		})
	end

	local TitleContainer = Create("Frame", {
		Name = "TitleContainer",
		Size = UDim2.new(1, -100, 1, 0),
		Position = UDim2.fromOffset(90, 0),
		BackgroundTransparency = 1,
		Parent = TitleBar,
	})

	local TitleLabel = Create("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.fromOffset(0, 6),
		BackgroundTransparency = 1,
		Text = Title,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 14,
		Font = Enum.Font.GothamMedium,
		TextColor3 = self.Scheme.TitleColor,
		Parent = TitleContainer,
	})

	local SubTitleLabel = Create("TextLabel", {
		Name = "SubTitle",
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.fromOffset(0, 24),
		BackgroundTransparency = 1,
		Text = SubTitle,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 11,
		Font = Enum.Font.Gotham,
		TextColor3 = self.Scheme.FontColor,
		TextTransparency = 0.4,
		Parent = TitleContainer,
	})

	local SideBar = Create("Frame", {
		Name = "SideBar",
		Size = UDim2.new(0.25, 0, 1, -48),
		Position = UDim2.fromOffset(0, 48),
		BackgroundColor3 = self.Scheme.SidebarColor,
		Parent = Main,
	})

	Create("UICorner", {
		TopLeftRadius = UDim.new(0, 0),
		BottomLeftRadius = cornerRadius,
		TopRightRadius = UDim.new(0, 0),
		BottomRightRadius = UDim.new(0, 0),
		Parent = SideBar,
	})

	local Content = Create("Frame", {
		Name = "Content",
		Size = UDim2.new(0.75, 0, 1, -48),
		Position = UDim2.new(0.25, 0, 0, 48),
		BackgroundTransparency = 1,
		Parent = Main,
	})

	if draggable then
		MakeDraggable(Main, TitleBar)
	end

	Main.Size = UDim2.fromOffset(0, 0)
	Main.BackgroundTransparency = 1

	task.defer(function()
		Library:Tween(Main, {
			Size = Size,
			BackgroundTransparency = 0,
		}, {
			Style = "Smooth",
			Duration = 0.45,
		})
	end)

	window.ScreenGui = ScreenGui
	window.Main = Main
	window.TitleBar = TitleBar
	window.TrafficLights = TrafficLights
	window.SideBar = SideBar
	window.Content = Content
	window.Title = Title
	window.SubTitle = SubTitle

	table.insert(Library.Windows, window)

	return window
end

return Library
