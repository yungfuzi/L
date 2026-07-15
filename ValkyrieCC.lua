local Valk = {
	Options = {},
	CurrentTheme = {},
	Folder = "Valk",
	GetService = function(service)
		return cloneref and cloneref(game:GetService(service)) or game:GetService(service)
	end,
}


local TweenService = Valk.GetService("TweenService")
local UserInputService = Valk.GetService("UserInputService")
local RunService = Valk.GetService("RunService")
local Players = Valk.GetService("Players")
local TextService = Valk.GetService("TextService")



local LocalPlayer = Players.LocalPlayer

local windowState
local tabs = {}
local currentTabInstance = nil
local tabIndex = 0
local elementCount = 0

local Themes = {
	Dark = {
		BaseBackground = Color3.fromRGB(15, 15, 17),
		HeaderBackground = Color3.fromRGB(15, 15, 17),
		SidebarBackground = Color3.fromRGB(15, 15, 17),
		DividerColor = Color3.fromRGB(255, 255, 255),
		DividerTransparency = 0.92,

		TextPrimary = Color3.fromRGB(255, 255, 255),
		TextPrimaryTransparency = 0,
		TextMuted = Color3.fromRGB(255, 255, 255),
		TextMutedTransparency = 0.55,
		TextDim = Color3.fromRGB(255, 255, 255),
		TextDimTransparency = 0.65,

		ElementBackground = Color3.fromRGB(28, 28, 32),
		ElementBackgroundTransparency = 0,

		TabActiveBackground = Color3.fromRGB(45, 110, 235),
		TabActiveTransparency = 0.6,
		TabHoverBackground = Color3.fromRGB(255, 255, 255),
		TabHoverTransparency = 0.94,

		ToggleOff = Color3.fromRGB(45, 45, 50),
		Accent = Color3.fromRGB(45, 110, 235),
		Success = Color3.fromRGB(52, 199, 89),
	},
	Light = {
		BaseBackground = Color3.fromRGB(240, 240, 245),
		HeaderBackground = Color3.fromRGB(230, 230, 238),
		SidebarBackground = Color3.fromRGB(230, 230, 238),
		DividerColor = Color3.fromRGB(0, 0, 0),
		DividerTransparency = 0.9,

		TextPrimary = Color3.fromRGB(20, 20, 20),
		TextPrimaryTransparency = 0,
		TextMuted = Color3.fromRGB(60, 60, 60),
		TextMutedTransparency = 0.4,
		TextDim = Color3.fromRGB(60, 60, 60),
		TextDimTransparency = 0.55,

		ElementBackground = Color3.fromRGB(0, 0, 0),
		ElementBackgroundTransparency = 0.95,

		TabActiveBackground = Color3.fromRGB(88, 82, 232),
		TabActiveTransparency = 0.15,
		TabHoverBackground = Color3.fromRGB(0, 0, 0),
		TabHoverTransparency = 0.94,

		ToggleOff = Color3.fromRGB(180, 180, 180),
		Accent = Color3.fromRGB(88, 82, 232),
		Success = Color3.fromRGB(40, 170, 100),
	},
}

Valk.CurrentTheme = Themes.Dark
local ThemeRegistry = {}


local function GetGui()
	local newGui = Instance.new("ScreenGui")
	newGui.Name = "Valk"
	newGui.ResetOnSpawn = false
	newGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	newGui.DisplayOrder = 2147483647

	local parent = RunService:IsStudio()
		and LocalPlayer:FindFirstChild("PlayerGui")
		or (gethui and gethui())
		or (cloneref and cloneref(Valk.GetService("CoreGui")) or Valk.GetService("CoreGui"))

	newGui.Parent = parent
	return newGui
end

local function RegisterThemeElement(instance, property, themeKey, transparencyKey)
	table.insert(ThemeRegistry, {
		Instance = instance,
		Property = property,
		ThemeKey = themeKey,
		TransparencyKey = transparencyKey,
	})

	if Valk.CurrentTheme[themeKey] then
		instance[property] = Valk.CurrentTheme[themeKey]
	end

	if transparencyKey and Valk.CurrentTheme[transparencyKey] then
		local transparencyValue = Valk.CurrentTheme[transparencyKey]

		if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
			if property == "TextColor3" then
				instance.TextTransparency = transparencyValue
			else
				instance.BackgroundTransparency = transparencyValue
			end
		elseif instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
			if property == "ImageColor3" then
				instance.ImageTransparency = transparencyValue
			else
				instance.BackgroundTransparency = transparencyValue
			end
		else
			instance.BackgroundTransparency = transparencyValue
		end
	end
end

local function Tween(instance, tweeninfo, propertytable)
	return TweenService:Create(instance, tweeninfo, propertytable)
end

local function create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function MakeDraggable(frame, dragHandle)
	local dragging, dragInput, dragStart, startPos

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end


function Valk:SetTheme(themeName)
	local targetTheme = Themes[themeName]
	if not targetTheme then
		return warn("Theme '" .. tostring(themeName) .. "' does not exist!")
	end

	Valk.CurrentTheme = targetTheme

	for _, registration in ipairs(ThemeRegistry) do
		local inst = registration.Instance
		if inst and inst.Parent then
			local targetColor = targetTheme[registration.ThemeKey]
			if targetColor then
				Tween(inst, TweenInfo.new(0.25, Enum.EasingStyle.Sine), { [registration.Property] = targetColor }):Play()
			end
		else
			table.remove(ThemeRegistry, table.find(ThemeRegistry, registration))
		end
	end
end

function Valk:Window(Settings)
	Settings = Settings or {}
	local WindowFunctions = { Settings = Settings }

	local valkGui = GetGui()


	local Main = create("Frame", {
		Name = "Main",
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, -350, 0.5, -250),
		Size = UDim2.new(0, 700, 0, 500),
		BackgroundTransparency = 0,
		ClipsDescendants = true,
		Parent = valkGui,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 20), Parent = Main })
	create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.65, Parent = Main })
	RegisterThemeElement(Main, "BackgroundColor3", "BaseBackground")


	local Header = create("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 78),
		Parent = Main,
	})

	local IconBadge = create("Frame", {
		Name = "IconBadge",
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.new(0, 24, 0.5, -20),
		Size = UDim2.new(0, 40, 0, 40),
		Parent = Header,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = IconBadge })
	RegisterThemeElement(IconBadge, "BackgroundColor3", "Accent")

	if Settings.Icon and Settings.Icon ~= "" then
		create("ImageLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0, 22, 0, 22),
			Image = Settings.Icon,
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			Parent = IconBadge,
		})
	else
		create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			Text = Settings.IconText or string.sub(Settings.Title or "V", 1, 1),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 20,
			Parent = IconBadge,
		})
	end

	local TitleRow = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 76, 0, 12),
		Size = UDim2.new(0, 400, 0, 24),
		Parent = Header,
	})

	local TitleLabel = create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Text = Settings.Title or "Valk",
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TitleRow,
	})
	RegisterThemeElement(TitleLabel, "TextColor3", "TextPrimary", "TextPrimaryTransparency")

	local TitleGra = create("UIGradient", { Parent = TitleLabel })

	TitleGra.Color = ColorSequence.new(
		Color3.fromRGB(103, 103, 103), 
		Color3.fromRGB(255, 255, 255) 
	)

	if Settings.Version then
		local VersionLabel = create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(0, 0, 1, 0),
			FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
			Text = Settings.Version,
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = TitleRow,
		})
		RegisterThemeElement(VersionLabel, "TextColor3", "Accent")

		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Parent = TitleRow,
		})
	end

	local SubRow = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 76, 0, 40),
		Size = UDim2.new(0, 400, 0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = Header,
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = SubRow,
	})

	if Settings.SubTitle then
		local SubTitleLabel = create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
			Text = Settings.SubTitle,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = SubRow,
		})
		RegisterThemeElement(SubTitleLabel, "TextColor3", "TextDim", "TextDimTransparency")
	end

	local TextService = game:GetService("TextService")

	local function getPillWidth(name)
		local nameText = name
		local handleText = "@" .. name

		local nameSize = TextService:GetTextSize(
			nameText, 14, Enum.Font.Roboto,
			Vector2.new(math.huge, 16)
		)
		local handleSize = TextService:GetTextSize(
			handleText, 11, Enum.Font.Roboto,
			Vector2.new(math.huge, 14)
		)

		local textWidth = math.max(nameSize.X, handleSize.X)
		return math.clamp(32 + 4 + 8 + textWidth + 12, 90, 260)
	end

	local pillWidth = getPillWidth(Settings.Username or LocalPlayer.Name)

	local UserPill = create("Frame", {
		Name = "UserPill",
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -24, 0.5, 0),
		Size = UDim2.new(0, pillWidth, 0, 40),
		Parent = Header,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 20), Parent = UserPill })
	create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.7, Parent = UserPill })
	RegisterThemeElement(UserPill, "BackgroundColor3", "ElementBackground", "ElementBackgroundTransparency")

	local Avatar = create("ImageLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 4, 0.5, -16),
		Size = UDim2.new(0, 32, 0, 32),
		Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150",
		Parent = UserPill,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Avatar })

	local UsernameLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 44, 0, 4),
		Size = UDim2.new(1, -56, 0, 16),
		FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
		Text = Settings.Username or LocalPlayer.Name,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = UserPill,
	})
	RegisterThemeElement(UsernameLabel, "TextColor3", "TextPrimary", "TextPrimaryTransparency")

	local HandleLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 44, 0, 20),
		Size = UDim2.new(1, -56, 0, 14),
		FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Text = "@" .. (Settings.Username or LocalPlayer.Name),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = UserPill,
	})
	RegisterThemeElement(HandleLabel, "TextColor3", "TextDim", "TextDimTransparency")

	local Divider = create("Frame", {
		Name = "Divider",
		BorderSizePixel = 0,
		Position = UDim2.new(0.05, 0, 0, 78),
		Size = UDim2.new(0.9, 0, 0, 1),
		Parent = Main,
	})
	RegisterThemeElement(Divider, "BackgroundColor3", "DividerColor", "DividerTransparency")


	local Tabs = create("Frame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 24, 0, 94),
		Size = UDim2.new(0, 140, 1, -100),
		Parent = Main,
	})

	local TabScroll = create("ScrollingFrame", {
		Active = true,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = Tabs,
	})

	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		Parent = TabScroll,
	})

	local Containt = create("Frame", {
		Name = "Containt",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 180, 0, 94),
		Size = UDim2.new(1, -200, 1, -100),
		Parent = Main,
	})


	local function createTab(parent, tabSettings)
		tabSettings = tabSettings or {}
		tabIndex += 1

		local TabButton = create("TextButton", {
			Name = tabSettings.Name or ("Tab" .. tabIndex),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 34),
			AutoButtonColor = false,
			Text = "",
			Parent = parent,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = TabButton })

		local TabStroke = create("UIStroke", { 
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border, 
			BorderStrokePosition = Enum.BorderStrokePosition.Inner, 
			Color = Color3.fromRGB(255, 255, 255), 
			Transparency = 1, 
			Parent = TabButton 
		})

		local TabGradient = create("UIGradient", { Enabled = false, Parent = TabButton })

		TabGradient.Color = ColorSequence.new(
			Color3.fromRGB(255, 255, 255), 
			Color3.fromRGB(53, 53, 53) 
		)



		local TabIcon = create("ImageLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0.5, -8),
			Size = UDim2.new(0, 16, 0, 16),
			Image = tabSettings.Icon or "rbxassetid://98203944616105",
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			Parent = TabButton,
		})
		RegisterThemeElement(TabIcon, "ImageColor3", "TextMuted", "ImageTransparency")

		local TabLabel = create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 34, 0, 0),
			Size = UDim2.new(1, -50, 1, 0),
			FontFace = Font.new(
				"rbxasset://fonts/families/Roboto.json", 
				Enum.FontWeight.Bold, 
				Enum.FontStyle.Normal
			),
			Text = tabSettings.Name or "Tab",
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = TabButton,
		})
		RegisterThemeElement(TabLabel, "TextColor3", "TextPrimary", "TextPrimaryTransparency")

		local TabDot = create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.new(0, 6, 0, 6),
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = TabButton,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = TabDot })
		RegisterThemeElement(TabDot, "BackgroundColor3", "DividerColor")

		local TabDotGlow = create("ImageLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, 14, 1, 14),
			Image = "rbxassetid://118051995939704",
			ImageColor3 = Valk.CurrentTheme.Accent,
			ImageTransparency = 1,
			ZIndex = 1,
			Parent = TabDot,
		})
		RegisterThemeElement(TabDotGlow, "ImageColor3", "Accent")

		local Page = create("ScrollingFrame", {
			Name = (tabSettings.Name or "Tab") .. "Page",
			Active = true,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ScrollBarThickness = 0,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = Containt,
		})

		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
			Parent = Page,
		})

		local TabFunctions = { 
			Name = tabSettings.Name, 
			Page = Page, 
			Button = TabButton, 
			UIStroke = TabStroke, 
			Gradient = TabGradient,
			Dot = TabDot, 
			DotGlow = TabDotGlow, 
			Sections = {} 
		}

		function TabFunctions:Select()
			for _, t in ipairs(tabs) do
				local isActive = (t == TabFunctions)
				t.Page.Visible = isActive

				Tween(t.Button, TweenInfo.new(0.15), {
					BackgroundColor3 = isActive and Valk.CurrentTheme.TabActiveBackground or Valk.CurrentTheme.BaseBackground,
					BackgroundTransparency = isActive and Valk.CurrentTheme.TabActiveTransparency or 1,
				}):Play()

				Tween(t.DotGlow, TweenInfo.new(0.2), {
					ImageTransparency = isActive and 0.3 or 1,
				}):Play()

				Tween(t.Dot, TweenInfo.new(0.2), {
					Size = isActive and UDim2.new(0, 8, 0, 8) or UDim2.new(0, 6, 0, 6),
				}):Play()

				Tween(t.UIStroke, TweenInfo.new(0.2), {
					Transparency = isActive and 0.75 or 1,
				}):Play()

				t.Gradient.Enabled = isActive
			end
			currentTabInstance = TabFunctions
		end

		TabButton.MouseButton1Click:Connect(function()
			TabFunctions:Select()
		end)

		function TabFunctions:SetStatus(active)
			TabDot.BackgroundColor3 = active and Valk.CurrentTheme.Success or Valk.CurrentTheme.DividerColor
		end

		function TabFunctions:Section(sectionSettings)
			sectionSettings = sectionSettings or {}

			local SectionFrame = create("Frame", {
				Name = sectionSettings.Name or "Section",
				BorderSizePixel = 0,
				Size = sectionSettings.Size or UDim2.new(0, 254, 0, 356),
				Parent = Page,
			})
			create("UICorner", { CornerRadius = UDim.new(0, 16), Parent = SectionFrame })
			RegisterThemeElement(SectionFrame, "BackgroundColor3", "ElementBackground", "ElementBackgroundTransparency")

			create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				Parent = SectionFrame,
			})

			create("UIPadding", {
				PaddingTop = UDim.new(0, 12),
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 12),
				Parent = SectionFrame,
			})

			local SectionFunctions = { Frame = SectionFrame }

			function SectionFunctions:Header(headerSettings)
				headerSettings = headerSettings or {}
				local Row = create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 24),
					Parent = SectionFrame,
				})
				if headerSettings.Icon then
					local Icon = create("TextLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.new(0, 20, 1, 0),
						FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
						Text = headerSettings.Icon,
						TextSize = 16,
						Parent = Row,
					})
					RegisterThemeElement(Icon, "TextColor3", "Accent")
				end
				local Header = create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.new(0, headerSettings.Icon and 24 or 0, 0, 0),
					Size = UDim2.new(1, headerSettings.Icon and -24 or 0, 1, 0),
					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
					Text = headerSettings.Name or "Header",
					TextSize = 18,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = Row,
				})
				RegisterThemeElement(Header, "TextColor3", "TextPrimary", "TextPrimaryTransparency")
				return Row
			end

			function SectionFunctions:Label(labelSettings)
				labelSettings = labelSettings or {}
				local Label = create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 20),
					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
					Text = labelSettings.Text or "",
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					Parent = SectionFrame,
				})
				RegisterThemeElement(Label, "TextColor3", "TextMuted", "TextMutedTransparency")
				return Label
			end

			function SectionFunctions:Divider()
				local Line = create("Frame", {
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 1),
					Parent = SectionFrame,
				})
				RegisterThemeElement(Line, "BackgroundColor3", "DividerColor", "DividerTransparency")
				return Line
			end

			function SectionFunctions:Button(buttonSettings)
				buttonSettings = buttonSettings or {}
				elementCount += 1
				local Btn = create("TextButton", {
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 34),
					AutoButtonColor = false,
					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
					Text = buttonSettings.Name or "Button",
					TextSize = 15,
					Parent = SectionFrame,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Btn })
				RegisterThemeElement(Btn, "BackgroundColor3", "ToggleOff")
				RegisterThemeElement(Btn, "TextColor3", "TextPrimary", "TextPrimaryTransparency")

				Btn.MouseButton1Click:Connect(function()
					if buttonSettings.Callback then
						buttonSettings.Callback()
					end
				end)

				return Btn
			end

			function SectionFunctions:Toggle(toggleSettings)
				toggleSettings = toggleSettings or {}
				elementCount += 1
				local state = toggleSettings.Default or false

				local Holder = create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 30),
					Parent = SectionFrame,
				})

				local Label = create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -50, 1, 0),
					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
					Text = toggleSettings.Name or "Toggle",
					TextSize = 15,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = Holder,
				})
				RegisterThemeElement(Label, "TextColor3", "TextPrimary", "TextPrimaryTransparency")

				local Switch = create("TextButton", {
					BackgroundColor3 = state and Valk.CurrentTheme.Success or Valk.CurrentTheme.ToggleOff,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Position = UDim2.new(1, -40, 0.5, -10),
					Size = UDim2.new(0, 40, 0, 20),
					Text = "",
					Parent = Holder,
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Switch })

				local Knob = create("Frame", {
					BorderSizePixel = 0,
					Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
					Size = UDim2.new(0, 16, 0, 16),
					Parent = Switch,
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })
				RegisterThemeElement(Knob, "BackgroundColor3", "TextPrimary")

				local ToggleFunctions = {}

				local function setState(value)
					state = value
					Tween(Switch, TweenInfo.new(0.2), { BackgroundColor3 = state and Valk.CurrentTheme.Success or Valk.CurrentTheme.ToggleOff }):Play()
					Tween(Knob, TweenInfo.new(0.2), { Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) }):Play()
				end

				Switch.MouseButton1Click:Connect(function()
					setState(not state)
					if toggleSettings.Callback then
						toggleSettings.Callback(state)
					end
				end)

				function ToggleFunctions:Set(value)
					setState(value)
					if toggleSettings.Callback then
						toggleSettings.Callback(state)
					end
				end

				return ToggleFunctions
			end

			function SectionFunctions:Slider(sliderSettings)
				sliderSettings = sliderSettings or {}
				elementCount += 1
				local Min = sliderSettings.Minimum or 0
				local Max = sliderSettings.Maximum or 100
				local value = sliderSettings.Default or Min

				local Holder = create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 40),
					Parent = SectionFrame,
				})

				local Label = create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 18),
					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
					Text = (sliderSettings.Name or "Slider") .. ": " .. tostring(value),
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = Holder,
				})
				RegisterThemeElement(Label, "TextColor3", "TextPrimary", "TextPrimaryTransparency")

				local Bar = create("Frame", {
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0, 24),
					Size = UDim2.new(1, 0, 0, 8),
					Parent = Holder,
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Bar })
				RegisterThemeElement(Bar, "BackgroundColor3", "ToggleOff")

				local Fill = create("Frame", {
					BorderSizePixel = 0,
					Size = UDim2.new((value - Min) / (Max - Min), 0, 1, 0),
					Parent = Bar,
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill })
				RegisterThemeElement(Fill, "BackgroundColor3", "Accent")

				local dragging = false
				local function update(input)
					local rel = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
					value = math.floor(Min + (Max - Min) * rel)
					Fill.Size = UDim2.new(rel, 0, 1, 0)
					Label.Text = (sliderSettings.Name or "Slider") .. ": " .. tostring(value)
					if sliderSettings.Callback then
						sliderSettings.Callback(value)
					end
				end

				Bar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						update(input)
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						update(input)
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = false
					end
				end)

				return Holder
			end

			TabFunctions.Sections[#TabFunctions.Sections + 1] = SectionFunctions
			return SectionFunctions
		end

		TabButton.MouseButton1Click:Connect(function()
			TabFunctions:Select()
		end)

		tabs[#tabs + 1] = TabFunctions

		if not currentTabInstance then
			currentTabInstance = TabFunctions
			task.defer(function()
				TabFunctions:Select()
			end)
		end

		return TabFunctions
	end

	function WindowFunctions:Tab(tabSettings)
		return createTab(TabScroll, tabSettings)
	end

	function WindowFunctions:GroupTab(Title, XAlignment)
		local GroupHolder = create("Frame", {
			Name = "Group_" .. Title,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = TabScroll,
		})

		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
			Parent = GroupHolder,
		})

		local GroupLabel = create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			Text = Title or "Group",
			TextSize = 12,
			TextXAlignment = XAlignment or Enum.TextXAlignment.Left,
			Parent = GroupHolder,
		})
		RegisterThemeElement(GroupLabel, "TextColor3", "TextDim", "TextDimTransparency")

		local GroupFunctions = { Holder = GroupHolder, Label = GroupLabel }

		function GroupFunctions:Tab(tabSettings)
			return createTab(GroupHolder, tabSettings)
		end

		return GroupFunctions
	end

	windowState = WindowFunctions
	return WindowFunctions
end

return Valk
