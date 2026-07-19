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
		DividerColor = Color3.fromRGB(80, 80, 80),
		DividerTransparency = 0.92,

		TextPrimary = Color3.fromRGB(255, 255, 255),
		TextPrimaryTransparency = 0,
		TextMuted = Color3.fromRGB(255, 255, 255),
		TextMutedTransparency = 0.55,
		TextDim = Color3.fromRGB(255, 255, 255),
		TextDimTransparency = 0.65,

		ElementBackground = Color3.fromRGB(255, 255, 255),
		ElementBackgroundTransparency = 0.95,

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



local function RegisterOption(idx, obj)
	if idx ~= nil then
		if Valk.Options[idx] then
			warn("[Valk] Options idx '" .. tostring(idx) .. "' is being overwritten")
		end
		Valk.Options[idx] = obj
	end
	return obj
end


local function ResolveArgs(a, b)
	if type(a) == "table" or a == nil then
		return nil, a or {}
	else
		return a, b or {}
	end
end


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

local function ApplyVisible(instance, config, functions)
	if config.Visible ~= nil then
		instance.Visible = config.Visible
	end
	function functions:SetVisible(state)
		instance.Visible = state
	end
end

local function BuildTooltip(AnchorFrame, cfg)
	cfg = cfg or {}
	local text = cfg.Text or ""
	local ttype = cfg.Type or "Hover"
	local delay = cfg.Delay or 0.3
	local richText = cfg.RichText or false

	local rootParent = AnchorFrame
	while rootParent and rootParent.Name ~= "Main" and rootParent.Parent do
		rootParent = rootParent.Parent
	end
	rootParent = rootParent or AnchorFrame

	local TooltipFrame = create("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.XY,
		Visible = false,
		ZIndex = 500,
		Parent = rootParent,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TooltipFrame })
	create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.85, Parent = TooltipFrame })
	RegisterThemeElement(TooltipFrame, "BackgroundColor3", "BaseBackground")

	create("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = TooltipFrame,
	})

	local TooltipLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(0, 0, 0, 0),
		FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Text = text,
		RichText = richText,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TooltipFrame,
	})
	RegisterThemeElement(TooltipLabel, "TextColor3", "TextPrimary", "TextPrimaryTransparency")

	local function positionTooltip()
		local anchorPos = AnchorFrame.AbsolutePosition
		local anchorSize = AnchorFrame.AbsoluteSize
		local rootPos = rootParent.AbsolutePosition
		TooltipFrame.AnchorPoint = Vector2.new(0.5, 1)
		TooltipFrame.Position = UDim2.new(0, anchorPos.X - rootPos.X + anchorSize.X / 2, 0, anchorPos.Y - rootPos.Y - 8)
	end

	local isShown = false
	local showToken = 0

	local function fadeIn()
		positionTooltip()
		TooltipFrame.Visible = true
		TooltipFrame.BackgroundTransparency = 1
		TooltipLabel.TextTransparency = 1
		Tween(TooltipFrame, TweenInfo.new(0.15), { BackgroundTransparency = 0.1 }):Play()
		Tween(TooltipLabel, TweenInfo.new(0.15), { TextTransparency = 0 }):Play()
		isShown = true
	end

	local function fadeOut()
		if not isShown then return end
		isShown = false
		local closeTween = Tween(TooltipFrame, TweenInfo.new(0.12), { BackgroundTransparency = 1 })
		Tween(TooltipLabel, TweenInfo.new(0.12), { TextTransparency = 1 }):Play()
		closeTween.Completed:Connect(function()
			if not isShown then
				TooltipFrame.Visible = false
			end
		end)
		closeTween:Play()
	end

	local TooltipFunctions = { Instance = TooltipFrame }

	if ttype == "Button" then
		local IconBtn = create("ImageButton", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -4, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 16),
			Image = cfg.Icon or "rbxassetid://74115333842618",
			ZIndex = 50,
			Parent = AnchorFrame,
		})

		IconBtn.MouseButton1Click:Connect(function()
			if isShown then
				fadeOut()
			else
				fadeIn()
			end
		end)

		TooltipFunctions.Button = IconBtn
	else
		AnchorFrame.MouseEnter:Connect(function()
			showToken += 1
			local myToken = showToken
			task.delay(delay, function()
				if myToken == showToken then
					fadeIn()
				end
			end)
		end)

		AnchorFrame.MouseLeave:Connect(function()
			showToken += 1
			fadeOut()
		end)
	end

	function TooltipFunctions:SetText(newText)
		text = newText
		TooltipLabel.Text = newText
	end

	function TooltipFunctions:Show()
		fadeIn()
	end

	function TooltipFunctions:Hide()
		fadeOut()
	end

	return TooltipFunctions
end

-- Attaches chained addon methods (:Keybind, :Tooltip) onto an element's functions table.
-- opts.Get/opts.Set describe a toggle-like state for default Keybind behavior; opts.Fire
-- describes a button-like default action. Both are optional.
local function AttachAddons(Functions, MainFrame, opts)
	opts = opts or {}
	local getState = opts.Get
	local setState = opts.Set
	local fireAction = opts.Fire

	function Functions:Keybind(a, b)
		local idx, keybindSettings = ResolveArgs(a, b)
		local key = keybindSettings.Key
		local mode = keybindSettings.Mode or "Toggle"
		local callback = keybindSettings.Callback
		local preventToggle = keybindSettings.PreventToggle

		local function trigger(active)
			if callback then
				callback(active)
			end
			if not (callback and preventToggle) then
				if setState and getState then
					if mode == "Hold" then
						setState(active)
					elseif active then
						setState(not getState())
					end
				elseif fireAction and active then
					fireAction()
				end
			end
		end

		local beganConn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if key and input.KeyCode == key then
				trigger(true)
			end
		end)

		local endedConn
		if mode == "Hold" then
			endedConn = UserInputService.InputEnded:Connect(function(input)
				if key and input.KeyCode == key then
					trigger(false)
				end
			end)
		end

		local KeybindFunctions = { Instance = MainFrame }

		function KeybindFunctions:SetKey(newKey)
			key = newKey
		end

		function KeybindFunctions:Destroy()
			beganConn:Disconnect()
			if endedConn then
				endedConn:Disconnect()
			end
		end

		return RegisterOption(idx, KeybindFunctions)
	end

	function Functions:Tooltip(tooltipSettings)
		return BuildTooltip(MainFrame, tooltipSettings)
	end
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

local function BuildElementFunctions(Target, Body)
	-- Label(idx, labelSettings) or Label(labelSettings)
	function Target:Label(a, b)
		local idx, labelSettings = ResolveArgs(a, b)

		local Label = create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
			Text = labelSettings.Text or "",
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = Body,
		})
		RegisterThemeElement(Label, "TextColor3", "TextMuted", "TextMutedTransparency")

		local LabelFunctions = { Instance = Label }

		function LabelFunctions:Set(text)
			Label.Text = text
		end

		function LabelFunctions:Get()
			return Label.Text
		end

		ApplyVisible(Label, labelSettings, LabelFunctions)
		AttachAddons(LabelFunctions, Label, {})

		return RegisterOption(idx, LabelFunctions)
	end

	-- Card(idx, cardSettings) or Card(cardSettings)
	function Target:Card(a, b)
		local idx, cardSettings = ResolveArgs(a, b)
		cardSettings.Corner = cardSettings.Corner or {}
		cardSettings.Gradient = cardSettings.Gradient or {}

		local TL = cardSettings.Corner.TopLeftRadius or UDim.new(0, 12)
		local TR = cardSettings.Corner.TopRightRadius or UDim.new(0, 12)
		local BR = cardSettings.Corner.BottomRightRadius or UDim.new(0, 12)
		local BL = cardSettings.Corner.BottomLeftRadius or UDim.new(0, 12)

		local CardHolder = create("Frame", {
			Active = true,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, cardSettings.Height or 100),
			Parent = Body,
		})

		create("UICorner", {
			TopLeftRadius = TL,
			TopRightRadius = TR,
			BottomRightRadius = BR,
			BottomLeftRadius = BL,
			Parent = CardHolder,
		})

		create("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Transparency = .85,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = CardHolder,
		})

		if cardSettings.BackgroundImage then
			local BgImage = create("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Image = cardSettings.BackgroundImage,
				ScaleType = Enum.ScaleType.Crop,
				ZIndex = 0,
				Parent = CardHolder,
			})
			create("UICorner", {
				TopLeftRadius = TL, TopRightRadius = TR,
				BottomRightRadius = BR, BottomLeftRadius = BL,
				Parent = BgImage,
			})
		end

		if cardSettings.BackgroundVideo then
			local BgVideo = create("VideoFrame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Video = cardSettings.BackgroundVideo,
				Looped = true,
				Playing = true,
				Volume = 0,
				ZIndex = 0,
				Parent = CardHolder,
			})
			create("UICorner", {
				TopLeftRadius = TL, TopRightRadius = TR,
				BottomRightRadius = BR, BottomLeftRadius = BL,
				Parent = BgVideo,
			})
		end

		local Gradient = create("UIGradient", {
			Parent = CardHolder,
		})

		local GradColor1 = cardSettings.Gradient.Color1 or Color3.fromRGB(0, 0, 84)
		local GradColor2 = cardSettings.Gradient.Color2 or Color3.fromRGB(18, 22, 255)

		Gradient.Color = ColorSequence.new(GradColor1, GradColor2)

		local iconWidth = cardSettings.Icon and 100 or 0

		if cardSettings.Icon then
			local IconHolder = create("Frame", {
				BorderSizePixel = 0,
				BackgroundTransparency = .9,
				BackgroundColor3 = Color3.new(1, 1, 1),
				Size = UDim2.new(0, 100, 1, 0),
				Parent = CardHolder,
			})

			create("UICorner", {
				TopLeftRadius = TL,
				BottomLeftRadius = BL,
				TopRightRadius = UDim.new(0, 0),
				BottomRightRadius = UDim.new(0, 0),
				Parent = IconHolder,
			})

			create("ImageLabel", {
				AnchorPoint = Vector2.new(.5, .5),
				Position = UDim2.fromScale(.5, .5),
				Size = UDim2.fromOffset(56, 56),
				BackgroundTransparency = 1,
				Image = cardSettings.Icon,
				Parent = IconHolder,
			})
		end

		local TitleLabel, DescLabel

		if cardSettings.Title or cardSettings.Desc then
			local TextHolder = create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, iconWidth + 12, 0, 0),
				Size = UDim2.new(1, -(iconWidth + 24), 1, 0),
				Parent = CardHolder,
			})

			create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 4),
				Parent = TextHolder,
			})

			if cardSettings.Title then
				TitleLabel = create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 20),
					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
					Text = cardSettings.Title,
					TextSize = 16,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					LayoutOrder = 1,
					Parent = TextHolder,
				})
			end

			if cardSettings.Desc then
				DescLabel = create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 16),
					AutomaticSize = Enum.AutomaticSize.Y,
					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
					Text = cardSettings.Desc,
					TextSize = 13,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextTransparency = 0.25,
					LayoutOrder = 2,
					Parent = TextHolder,
				})
			end
		end

		if cardSettings.PrimaryButton or cardSettings.SecondaryButton then
			local ButtonRow = create("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, iconWidth + 12, 1, -12),
				Size = UDim2.new(1, -(iconWidth + 24), 0, 30),
				Parent = CardHolder,
			})
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = ButtonRow,
			})

			local function buildCardBtn(btnConfig, order)
				local CardBtn = create("TextButton", {
					AutoButtonColor = false,
					BackgroundColor3 = btnConfig.Color or Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.new(0, 0, 1, 0),
					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
					Text = "  " .. (btnConfig.Text or "Action") .. "  ",
					TextSize = 13,
					TextColor3 = btnConfig.TextColor or Color3.fromRGB(0, 0, 0),
					LayoutOrder = order,
					Parent = ButtonRow,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = CardBtn })
				CardBtn.MouseButton1Click:Connect(function()
					if btnConfig.Callback then
						btnConfig.Callback()
					end
				end)
				return CardBtn
			end

			if cardSettings.PrimaryButton then
				buildCardBtn(cardSettings.PrimaryButton, 1)
			end
			if cardSettings.SecondaryButton then
				buildCardBtn(cardSettings.SecondaryButton, 2)
			end
		end

		local direction = cardSettings.Gradient.Direction or Vector2.new(-1, 0)
		Gradient.Offset = direction

		local gradientTween = nil
		local function playGradientTween()
			if gradientTween then
				gradientTween:Cancel()
			end
			gradientTween = Tween(
				Gradient,
				TweenInfo.new(cardSettings.Gradient.Duration or 8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
				{ Offset = -direction }
			)
			gradientTween:Play()
		end

		if cardSettings.Gradient.Enabled ~= false and cardSettings.Gradient.Rotate ~= false then
			playGradientTween()
		end

		local CardFunctions = {
			Frame = CardHolder,
			Gradient = Gradient,
			TitleLabel = TitleLabel,
			DescLabel = DescLabel,
		}

		function CardFunctions:SetTitle(text)
			if TitleLabel then
				TitleLabel.Text = text
			end
		end

		function CardFunctions:SetDesc(text)
			if DescLabel then
				DescLabel.Text = text
			end
		end

		function CardFunctions:SetGradient(color1, color2)
			Gradient.Color = ColorSequence.new(color1, color2)
		end

		function CardFunctions:SetGradientEnabled(enabled)
			if enabled then
				playGradientTween()
			elseif gradientTween then
				gradientTween:Cancel()
				gradientTween = nil
			end
		end

		ApplyVisible(CardHolder, cardSettings, CardFunctions)
		AttachAddons(CardFunctions, CardHolder, {})

		return RegisterOption(idx, CardFunctions)
	end

	-- Divider(idx, dividerSettings) or Divider(dividerSettings) or Divider(idx) or Divider()
	function Target:Divider(a, b)
		local idx, dividerSettings = ResolveArgs(a, b)

		local Line = create("Frame", {
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 1),
			Parent = Body,
		})
		RegisterThemeElement(Line, "BackgroundColor3", "DividerColor", "DividerTransparency")

		local DividerFunctions = { Instance = Line }

		ApplyVisible(Line, dividerSettings, DividerFunctions)
		AttachAddons(DividerFunctions, Line, {})

		return RegisterOption(idx, DividerFunctions)
	end

	-- Paragraph(idx, paragraphSettings) or Paragraph(paragraphSettings)
	function Target:Paragraph(a, b)
		local idx, paragraphSettings = ResolveArgs(a, b)

		local Holder = create("Frame", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = Body,
		})

		local TitleLabel
		if paragraphSettings.Title then
			TitleLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 20),
				FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				Text = paragraphSettings.Title,
				RichText = paragraphSettings.RichText or false,
				TextSize = 15,
				TextWrapped = paragraphSettings.TextWrapped ~= false,
				TextXAlignment = paragraphSettings.TitleAlignmentX or Enum.TextXAlignment.Left,
				LayoutOrder = 1,
				Parent = Holder,
			})
			RegisterThemeElement(TitleLabel, "TextColor3", "TextPrimary", "TextPrimaryTransparency")
		end

		local DescLabel
		if paragraphSettings.Desc then
			DescLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, TitleLabel and 24 or 0),
				Size = UDim2.new(1, 0, 0, 16),
				AutomaticSize = Enum.AutomaticSize.Y,
				FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
				Text = paragraphSettings.Desc,
				RichText = paragraphSettings.RichText or false,
				TextSize = 13,
				TextWrapped = paragraphSettings.TextWrapped ~= false,
				TextXAlignment = paragraphSettings.DescAlignmentX or Enum.TextXAlignment.Left,
				LayoutOrder = 2,
				Parent = Holder,
			})
			RegisterThemeElement(DescLabel, "TextColor3", "TextDim", "TextDimTransparency")
		end

		local ParagraphFunctions = { Instance = Holder, TitleLabel = TitleLabel, DescLabel = DescLabel }

		function ParagraphFunctions:SetTitle(text)
			if TitleLabel then
				TitleLabel.Text = text
			end
		end

		function ParagraphFunctions:SetDesc(text)
			if DescLabel then
				DescLabel.Text = text
			end
		end

		ApplyVisible(Holder, paragraphSettings, ParagraphFunctions)
		AttachAddons(ParagraphFunctions, Holder, {})

		return RegisterOption(idx, ParagraphFunctions)
	end

	-- Button(idx, buttonSettings) or Button(buttonSettings)
	function Target:Button(a, b)
		local idx, buttonSettings = ResolveArgs(a, b)
		elementCount += 1

		local hasDescription = buttonSettings.Description and buttonSettings.Description ~= ""
		local btnHeight = hasDescription and 60 or 44

		local Btn = create("Frame", {
			Size = UDim2.new(1, 0, 0, btnHeight),
			BackgroundTransparency = 1,
			Parent = Body,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Btn })
		RegisterThemeElement(Btn, "BackgroundTransparency", "ButtonTrans")

		local Text = create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, hasDescription and 8 or 0),
			Size = UDim2.new(1, -50, 0, hasDescription and 18 or btnHeight),
			FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			Text = buttonSettings.Name or "Button",
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = Btn,
		})
		RegisterThemeElement(Text, "TextColor3", "TextPrimary", "TextPrimaryTransparency")

		local Description
		if hasDescription then
			Description = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 28),
				Size = UDim2.new(1, -50, 0, 24),
				FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
				Text = buttonSettings.Description,
				TextSize = 12,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				Parent = Btn,
			})
			RegisterThemeElement(Description, "TextColor3", "TextDim", "TextDimTransparency")
		end

		local Icon = create("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 30, 0, 30),
			Image = "rbxassetid://101007429951147",
			Position = UDim2.new(1, 0, 0.5, 0),
			ImageTransparency = 0.65,
			AnchorPoint = Vector2.new(1, 0.5),
			Parent = Btn,
		})

		local hitbox = create("ImageButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Parent = Btn,
		})

		hitbox.MouseEnter:Connect(function()
			Icon.ImageTransparency = 0.3
		end)

		hitbox.MouseLeave:Connect(function()
			Icon.ImageTransparency = 0.65
		end)

		local callback = buttonSettings.Callback

		hitbox.MouseButton1Click:Connect(function()
			if callback then
				callback()
			end
		end)

		local ButtonFunctions = { Instance = Btn }

		function ButtonFunctions:SetName(text)
			Text.Text = text
		end

		function ButtonFunctions:SetDescription(text)
			if Description then
				Description.Text = text
			end
		end

		function ButtonFunctions:SetCallback(fn)
			callback = fn
		end

		function ButtonFunctions:Fire()
			if callback then
				callback()
			end
		end

		ApplyVisible(Btn, buttonSettings, ButtonFunctions)
		AttachAddons(ButtonFunctions, Btn, {
			Fire = function()
				ButtonFunctions:Fire()
			end,
		})

		return RegisterOption(idx, ButtonFunctions)
	end

	-- Toggle(idx, toggleSettings) or Toggle(toggleSettings)
	function Target:Toggle(a, b)
		local idx, toggleSettings = ResolveArgs(a, b)
		elementCount += 1
		local state = toggleSettings.Default or false
		local style = toggleSettings.Style or 1

		local hasDescription = toggleSettings.Description and toggleSettings.Description ~= ""
		local toggleHeight = hasDescription and 60 or 44

		local Holder = create("Frame", {
			Size = UDim2.new(1, 0, 0, toggleHeight),
			BackgroundTransparency = 1,
			Parent = Body,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Holder })

		local NameLabel = create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, hasDescription and 8 or 0),
			Size = UDim2.new(1, -50, 0, hasDescription and 18 or toggleHeight),
			FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			Text = toggleSettings.Name or "Toggle",
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = Holder,
		})
		RegisterThemeElement(NameLabel, "TextColor3", "TextPrimary", "TextPrimaryTransparency")

		local DescriptionLabel
		if hasDescription then
			DescriptionLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 28),
				Size = UDim2.new(1, -50, 0, 24),
				FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
				Text = toggleSettings.Description,
				TextSize = 12,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				Parent = Holder,
			})
			RegisterThemeElement(DescriptionLabel, "TextColor3", "TextDim", "TextDimTransparency")
		end

		local ToggleFunctions = {}
		local setState

		if style == 2 then
			local DotBtn = create("TextButton", {
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "",
				Size = UDim2.new(0, 22, 0, 22),
				Position = UDim2.new(1, -30, 0.5, -11),
				Parent = Holder,
			})

			local Dot = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundColor3 = Valk.CurrentTheme.DividerColor,
				Size = UDim2.new(0, 6, 0, 6),
				BorderSizePixel = 0,
				ZIndex = 2,
				Parent = DotBtn,
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Dot })
			RegisterThemeElement(Dot, "BackgroundColor3", "DividerColor")

			local DotGlow = create("ImageLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(1, 14, 1, 14),
				Image = "rbxassetid://118051995939704",
				ImageColor3 = Valk.CurrentTheme.Accent,
				ImageTransparency = 1,
				ZIndex = 1,
				Parent = Dot,
			})
			
			local hitbox = create("ImageButton", {
				ImageTransparency = 1,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Parent = Holder
			})
			
			RegisterThemeElement(DotGlow, "ImageColor3", "Accent")

			function setState(value)
				state = value
				Tween(DotGlow, TweenInfo.new(0.2), {
					ImageTransparency = state and 0.3 or 1,
				}):Play()
				Tween(Dot, TweenInfo.new(0.2), {
					Size = state and UDim2.new(0, 8, 0, 8) or UDim2.new(0, 6, 0, 6),
					BackgroundColor3 = state and Valk.CurrentTheme.Accent or Valk.CurrentTheme.DividerColor,
				}):Play()
			end

			hitbox.MouseButton1Click:Connect(function()
				setState(not state)
				if toggleSettings.Callback then
					toggleSettings.Callback(state)
				end
			end)
		else
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

			function setState(value)
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
		end

		function ToggleFunctions:Set(value)
			setState(value)
			if toggleSettings.Callback then
				toggleSettings.Callback(state)
			end
		end

		function ToggleFunctions:Get()
			return state
		end

		function ToggleFunctions:SetName(text)
			NameLabel.Text = text
		end

		function ToggleFunctions:SetDescription(text)
			if DescriptionLabel then
				DescriptionLabel.Text = text
			end
		end

		ApplyVisible(Holder, toggleSettings, ToggleFunctions)
		AttachAddons(ToggleFunctions, Holder, {
			Get = function()
				return ToggleFunctions:Get()
			end,
			Set = function(value)
				ToggleFunctions:Set(value)
			end,
		})

		return RegisterOption(idx, ToggleFunctions)
	end
	
	function Target:Dropdown(a, b)
		local idx, dropdownSettings = ResolveArgs(a, b)
		elementCount += 1

		local options = dropdownSettings.Options or {}
		local selected = dropdownSettings.Default
		local multi = dropdownSettings.Multi or false
		local maxVisible = dropdownSettings.MaxVisible or 6
		local placeholder = dropdownSettings.Placeholder or "Select..."
		local style = dropdownSettings.Style or 1 -- 1: Thả xuống, 2: Panel trượt từ bên phải

		if multi then
			selected = type(selected) == "table" and selected or {}
		else
			selected = selected ~= nil and selected or nil
		end

		local hasDescription = dropdownSettings.Description and dropdownSettings.Description ~= ""
		local ddHeight = hasDescription and 60 or 44

		local Holder = create("Frame", {
			Size = UDim2.new(1, 0, 0, ddHeight),
			BackgroundTransparency = 1,
			Parent = Body,
			ClipsDescendants = false,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Holder })

		local NameLabel = create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, hasDescription and 8 or 0),
			Size = UDim2.new(1, -155, 0, hasDescription and 18 or ddHeight),
			FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			Text = dropdownSettings.Name or "Dropdown",
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = Holder,
		})
		RegisterThemeElement(NameLabel, "TextColor3", "TextPrimary", "TextPrimaryTransparency")

		local DescriptionLabel
		if hasDescription then
			DescriptionLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 28),
				Size = UDim2.new(1, -155, 0, 24),
				FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
				Text = dropdownSettings.Description,
				TextSize = 12,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				Parent = Holder,
			})
			RegisterThemeElement(DescriptionLabel, "TextColor3", "TextDim", "TextDimTransparency")
		end

		local DropdownBox = create("TextButton", {
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			Size = UDim2.new(0, 140, 0, 30),
			Position = UDim2.new(1, -140, 0.5, -15),
			Parent = Holder,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = DropdownBox })
		RegisterThemeElement(DropdownBox, "BackgroundColor3", "ElementBackground", "ElementBackgroundTransparency")

		create("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Transparency = 0.8,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = DropdownBox,
		})

		local function getDisplayText()
			if multi then
				if #selected == 0 then return placeholder end
				if #selected == 1 then return tostring(selected[1]) end
				return tostring(#selected) .. " selected"
			else
				return selected ~= nil and tostring(selected) or placeholder
			end
		end

		local ValueLabel = create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 0),
			Size = UDim2.new(1, -30, 1, 0),
			FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
			Text = getDisplayText(),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = DropdownBox,
		})
		RegisterThemeElement(ValueLabel, "TextColor3", "TextPrimary", "TextPrimaryTransparency")

		local ArrowIcon = create("ImageLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.new(0, 12, 0, 12),
			Image = style == 2 and "rbxassetid://10614461413" or "rbxassetid://71880540200693",
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			Rotation = 0,
			Parent = DropdownBox,
		})
		RegisterThemeElement(ArrowIcon, "ImageColor3", "TextMuted", "ImageTransparency")

		-- Tìm kiếm Frame chính tên "Main"
		local mainParent = Holder
		while mainParent and mainParent.Name ~= "Main" and mainParent.Parent do
			mainParent = mainParent.Parent
		end
		mainParent = mainParent or Holder

		-- Đảm bảo folder DropdownPanels luôn tồn tại trong Main để chứa cả Style 1 và Style 2
		local panelsFolder = mainParent:FindFirstChild("DropdownPanels")
		if not panelsFolder then
			panelsFolder = create("Folder", {
				Name = "DropdownPanels",
				Parent = mainParent
			})
		end

		local scrollFrame = Holder
		while scrollFrame and not scrollFrame:IsA("ScrollingFrame") and scrollFrame.Parent do
			scrollFrame = scrollFrame.Parent
		end

		-- Khởi tạo Menu Frame dựa vào Style nhưng tất cả đều nằm trong panelsFolder
		local Menu
		if style == 2 then
			Menu = create("Frame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 240, 1, 0),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 250, 0, 0), -- Giấu sang bên phải màn hình
				Visible = false,
				ZIndex = 200,
				Parent = panelsFolder,
			})
			create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = Menu })
		else
			Menu = create("Frame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 140, 0, 0),
				Visible = false,
				ZIndex = 200, -- Nâng ZIndex lên ngang hàng để đảm bảo đè lên nội dung khác tốt hơn
				Parent = panelsFolder, -- CHUYỂN VÀO FOLDER CHUNG
			})
			create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Menu })
		end
		RegisterThemeElement(Menu, "BackgroundColor3", "BaseBackground")

		local searchEnabled = dropdownSettings.Search or false
		local searchOffset = searchEnabled and 32 or 0

		local OptionList = create("ScrollingFrame", {
			Active = true,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = style == 2 and UDim2.new(1, -20, 1, -40 - searchOffset) or UDim2.new(1, -8, 1, -8 - searchOffset),
			Position = style == 2 and UDim2.new(0, 10, 0, 20 + searchOffset) or UDim2.new(0, 4, 0, 4 + searchOffset),
			ScrollBarThickness = style == 2 and 0 or 0,
			ScrollBarImageColor3 = Valk.CurrentTheme.DividerColor,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 201,
			Parent = Menu,
		})

		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
			Parent = OptionList,
		})

		local searchQuery = ""
		local SearchBox

		if searchEnabled and style == 2 then
			-- Style 2: circular search icon top-right that slides open into a search bar.
			local SearchStrip = create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 14),
				Size = UDim2.new(1, -20, 0, 32),
				ClipsDescendants = true,
				ZIndex = 202,
				Parent = Menu,
			})

			local SearchPill = create("Frame", {
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.new(0, 32, 0, 32),
				ZIndex = 202,
				Parent = SearchStrip,
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SearchPill })
			create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.8, Parent = SearchPill })
			RegisterThemeElement(SearchPill, "BackgroundColor3", "ElementBackground", "ElementBackgroundTransparency")

			SearchBox = create("TextBox", {
				BackgroundTransparency = 1,
				ClearTextOnFocus = false,
				TextEditable = false,
				Position = UDim2.new(0, 40, 0, 0),
				Size = UDim2.new(1, -74, 1, 0),
				FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
				PlaceholderText = "Search...",
				Text = "",
				TextSize = 13,
				TextTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 203,
				Parent = SearchPill,
			})
			RegisterThemeElement(SearchBox, "TextColor3", "TextPrimary", "TextPrimaryTransparency")

			local SearchIcon = create("ImageButton", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, 16, 0.5, 0),
				Size = UDim2.new(0, 18, 0, 18),
				Image = "rbxassetid://72296609649861",
				ZIndex = 204,
				Parent = SearchPill,
			})
			RegisterThemeElement(SearchIcon, "ImageColor3", "TextPrimary", "TextPrimaryTransparency")

			local searchBarOpen = false

			local function openSearchBar()
				if searchBarOpen then return end
				searchBarOpen = true
				local fullWidth = SearchStrip.AbsoluteSize.X
				Tween(SearchPill, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, fullWidth, 0, 32),
				}):Play()
				task.delay(0.15, function()
					if not searchBarOpen then return end
					SearchBox.TextEditable = true
					Tween(SearchBox, TweenInfo.new(0.15), { TextTransparency = 0 }):Play()
					SearchBox:CaptureFocus()
				end)
			end

			local function closeSearchBar()
				if not searchBarOpen then return end
				searchBarOpen = false
				SearchBox:ReleaseFocus()
				SearchBox.TextEditable = false
				Tween(SearchBox, TweenInfo.new(0.1), { TextTransparency = 1 }):Play()
				Tween(SearchPill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Size = UDim2.new(0, 32, 0, 32),
				}):Play()
			end

			SearchIcon.MouseButton1Click:Connect(function()
				if searchBarOpen then
					closeSearchBar()
				else
					openSearchBar()
				end
			end)

			SearchBox.FocusLost:Connect(function()
				if SearchBox.Text == "" then
					closeSearchBar()
				end
			end)
		elseif searchEnabled then
			SearchBox = create("TextBox", {
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				ClearTextOnFocus = false,
				Position = UDim2.new(0, 4, 0, 4),
				Size = UDim2.new(1, -8, 0, 24),
				FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
				PlaceholderText = "Search...",
				Text = "",
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 202,
				Parent = Menu,
			})
			create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = SearchBox })
			RegisterThemeElement(SearchBox, "BackgroundColor3", "ElementBackground", "ElementBackgroundTransparency")
			RegisterThemeElement(SearchBox, "TextColor3", "TextPrimary", "TextPrimaryTransparency")

			create("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				Parent = SearchBox,
			})
		end

		local optionButtons = {}
		local isOpen = false
		local scrollConn = nil

		local function compareValues(a, b)
			if a == nil or b == nil then return false end
			return tostring(a) == tostring(b)
		end

		local function isSelected(opt)
			if multi then
				for _, v in ipairs(selected) do
					if compareValues(v, opt) then return true end
				end
				return false
			else
				return compareValues(selected, opt)
			end
		end

		local function toggleSelect(opt)
			if multi then
				local found = false
				for i, v in ipairs(selected) do
					if compareValues(v, opt) then
						table.remove(selected, i)
						found = true
						break
					end
				end
				if not found then
					table.insert(selected, opt)
				end
			else
				selected = opt
			end
		end

		local visibleCount = 0

		local function matchesSearch(opt)
			if not searchEnabled or searchQuery == "" then return true end
			return string.find(string.lower(tostring(opt)), string.lower(searchQuery), 1, true) ~= nil
		end

		local function buildOptions()
			for _, btn in ipairs(optionButtons) do
				btn:Destroy()
			end
			table.clear(optionButtons)
			visibleCount = 0

			for i, opt in ipairs(options) do
				if matchesSearch(opt) then
				visibleCount += 1
				local optText = tostring(opt)
				local sel = isSelected(opt)

				local OptBtn = create("TextButton", {
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Text = "",
					Size = UDim2.new(1, 0, 0, style == 2 and 34 or 28),
					ZIndex = 202,
					Parent = OptionList,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = OptBtn })

				local textColor = sel and Valk.CurrentTheme.TextPrimary or Valk.CurrentTheme.TextMuted
				local fontWeight = sel and Enum.FontWeight.Bold or Enum.FontWeight.Regular

				local OptLabel = create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 32, 0, 0),
					Size = UDim2.new(1, -40, 1, 0),
					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", fontWeight, Enum.FontStyle.Normal),
					Text = optText,
					TextSize = style == 2 and 14 or 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = textColor,
					ZIndex = 202,
					Parent = OptBtn,
				})

				local Dot = create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 10, 0.5, 0),
					BackgroundColor3 = sel and Valk.CurrentTheme.Accent or Valk.CurrentTheme.DividerColor,
					Size = sel and UDim2.new(0, 8, 0, 8) or UDim2.new(0, 6, 0, 6),
					BorderSizePixel = 0,
					ZIndex = 203,
					Parent = OptBtn,
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Dot })
				RegisterThemeElement(Dot, "BackgroundColor3", sel and "Accent" or "DividerColor")

				local DotGlow = create("ImageLabel", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(1, 14, 1, 14),
					Image = "rbxassetid://118051995939704",
					ImageColor3 = Valk.CurrentTheme.Accent,
					ImageTransparency = sel and 0.3 or 1,
					ZIndex = 202,
					Parent = Dot,
				})
				RegisterThemeElement(DotGlow, "ImageColor3", "Accent")

				OptBtn.MouseEnter:Connect(function()
					Tween(OptLabel, TweenInfo.new(0.1), {
						TextColor3 = Valk.CurrentTheme.TextPrimary,
					}):Play()
				end)

				OptBtn.MouseLeave:Connect(function()
					local targetColor = isSelected(opt) and Valk.CurrentTheme.TextPrimary or Valk.CurrentTheme.TextMuted
					Tween(OptLabel, TweenInfo.new(0.1), {
						TextColor3 = targetColor,
					}):Play()
				end)

				OptBtn.MouseButton1Click:Connect(function()
					toggleSelect(opt)
					ValueLabel.Text = getDisplayText()

					if dropdownSettings.Callback then
						dropdownSettings.Callback(multi and selected or selected)
					end

					if not multi then
						buildOptions()
						task.delay(0.15, closeMenu)
					else
						buildOptions()
					end
				end)

				table.insert(optionButtons, OptBtn)
				end
			end

			if searchEnabled and isOpen and style ~= 2 then
				local itemCount = math.min(visibleCount, maxVisible)
				local boxWidth = DropdownBox.AbsoluteSize.X
				Tween(Menu, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, boxWidth, 0, itemCount * 30 + 8 + searchOffset),
				}):Play()
			end
		end

		if searchEnabled then
			SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
				searchQuery = SearchBox.Text
				buildOptions()
			end)
		end

		local function updateMenuPosition()
			if style == 2 then return end
			local absPos = DropdownBox.AbsolutePosition
			local absSize = DropdownBox.AbsoluteSize
			local mainPos = mainParent.AbsolutePosition
			-- Vẫn tính toán chính xác vị trí tương đối so với mainParent cho Style 1
			Menu.Position = UDim2.new(0, absPos.X - mainPos.X, 0, absPos.Y - mainPos.Y + absSize.Y + 4)
			Menu.Size = UDim2.new(0, absSize.X, 0, Menu.Size.Y.Offset)
		end

		local function openMenu()
			if isOpen or #options == 0 then return end
			isOpen = true

			buildOptions()

			if style == 2 then
				Menu.Visible = true
				Menu.BackgroundTransparency = 0
				Tween(Menu, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(1, 0, 0, 0)
				}):Play()
				Tween(ArrowIcon, TweenInfo.new(0.2), { Rotation = 90 }):Play()
			else
				updateMenuPosition()
				local itemCount = math.min(visibleCount, maxVisible)
				local menuHeight = itemCount * 30 + 8 + searchOffset
				local boxWidth = DropdownBox.AbsoluteSize.X

				Menu.Size = UDim2.new(0, boxWidth, 0, 0)
				Menu.Visible = true
				Menu.BackgroundTransparency = 1

				if scrollFrame and scrollFrame:IsA("ScrollingFrame") then
					scrollConn = scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
						if isOpen then
							updateMenuPosition()
						end
					end)
				end

				Tween(ArrowIcon, TweenInfo.new(0.2), { Rotation = 180 }):Play()
				Tween(Menu, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, boxWidth, 0, menuHeight),
					BackgroundTransparency = 0.3,
				}):Play()
			end
		end

		local function closeMenu()
			if not isOpen then return end
			isOpen = false

			if scrollConn then
				scrollConn:Disconnect()
				scrollConn = nil
			end

			if style == 2 then
				Tween(ArrowIcon, TweenInfo.new(0.2), { Rotation = 0 }):Play()
				local closeTween = Tween(Menu, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Position = UDim2.new(1, 250, 0, 0)
				})
				closeTween.Completed:Connect(function()
					if not isOpen then
						Menu.Visible = false
					end
				end)
				closeTween:Play()
			else
				local boxWidth = DropdownBox.AbsoluteSize.X
				Tween(ArrowIcon, TweenInfo.new(0.2), { Rotation = 0 }):Play()
				local closeTween = Tween(Menu, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Size = UDim2.new(0, boxWidth, 0, 0),
					BackgroundTransparency = 1,
				})
				closeTween.Completed:Connect(function()
					if not isOpen then
						Menu.Visible = false
					end
				end)
				closeTween:Play()
			end
		end

		DropdownBox.MouseButton1Click:Connect(function()
			if isOpen then
				closeMenu()
			else
				openMenu()
			end
		end)

		local function onInputBegan(input, gameProcessed)
			if not isOpen then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end

			local pos = input.Position
			local menuAbsPos = Menu.AbsolutePosition
			local menuAbsSize = Menu.AbsoluteSize
			local boxAbsPos = DropdownBox.AbsolutePosition
			local boxAbsSize = DropdownBox.AbsoluteSize

			local inMenu = pos.X >= menuAbsPos.X and pos.X <= menuAbsPos.X + menuAbsSize.X
				and pos.Y >= menuAbsPos.Y and pos.Y <= menuAbsPos.Y + menuAbsSize.Y
			local inBox = pos.X >= boxAbsPos.X and pos.X <= boxAbsPos.X + boxAbsSize.X
				and pos.Y >= boxAbsPos.Y and pos.Y <= boxAbsPos.Y + boxAbsSize.Y

			if not inMenu and not inBox then
				closeMenu()
			end
		end

		local inputConn = UserInputService.InputBegan:Connect(onInputBegan)

		local DropdownFunctions = { Instance = Holder }

		function DropdownFunctions:SetOptions(newOptions)
			options = newOptions or {}
			if multi then
				local valid = {}
				for _, sel in ipairs(selected) do
					for _, opt in ipairs(options) do
						if compareValues(sel, opt) then
							table.insert(valid, sel)
							break
						end
					end
				end
				selected = valid
			else
				local valid = false
				for _, opt in ipairs(options) do
					if compareValues(selected, opt) then valid = true; break end
				end
				if not valid then selected = nil end
			end
			ValueLabel.Text = getDisplayText()
			if isOpen then buildOptions() end
		end

		function DropdownFunctions:SetValue(value)
			if multi then
				selected = type(value) == "table" and value or {}
			else
				selected = value
			end
			ValueLabel.Text = getDisplayText()
			if isOpen then buildOptions() end
			if dropdownSettings.Callback then
				dropdownSettings.Callback(multi and selected or selected)
			end
		end

		function DropdownFunctions:GetValue()
			return multi and selected or selected
		end

		function DropdownFunctions:SetName(text)
			NameLabel.Text = text
		end

		function DropdownFunctions:SetDescription(text)
			if DescriptionLabel then
				DescriptionLabel.Text = text
			end
		end

		function DropdownFunctions:Open()
			openMenu()
		end

		function DropdownFunctions:Close()
			closeMenu()
		end

		function DropdownFunctions:Destroy()
			if scrollConn then scrollConn:Disconnect() end
			inputConn:Disconnect()
			Menu:Destroy()
			Holder:Destroy()
		end

		ApplyVisible(Holder, dropdownSettings, DropdownFunctions)
		AttachAddons(DropdownFunctions, Holder, {})

		return RegisterOption(idx, DropdownFunctions)
	end

	-- Slider(idx, sliderSettings) or Slider(sliderSettings)
	function Target:Slider(a, b)
		local idx, sliderSettings = ResolveArgs(a, b)
		elementCount += 1
		local Min = sliderSettings.Minimum or 0
		local Max = sliderSettings.Maximum or 100
		local value = sliderSettings.Default or Min

		local Holder = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 40),
			Parent = Body,
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

		local function refresh()
			local rel = math.clamp((value - Min) / (Max - Min), 0, 1)
			Fill.Size = UDim2.new(rel, 0, 1, 0)
			Label.Text = (sliderSettings.Name or "Slider") .. ": " .. tostring(value)
		end

		local dragging = false
		local function update(input)
			local rel = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
			value = math.floor(Min + (Max - Min) * rel)
			refresh()
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

		local SliderFunctions = { Instance = Holder }

		function SliderFunctions:Set(newValue)
			value = math.clamp(newValue, Min, Max)
			refresh()
			if sliderSettings.Callback then
				sliderSettings.Callback(value)
			end
		end

		function SliderFunctions:Get()
			return value
		end

		ApplyVisible(Holder, sliderSettings, SliderFunctions)
		AttachAddons(SliderFunctions, Holder, {
			Get = function()
				return SliderFunctions:Get()
			end,
			Set = function(v)
				SliderFunctions:Set(v)
			end,
		})

		return RegisterOption(idx, SliderFunctions)
	end

	-- ChipSelection(idx, chipSettings) or ChipSelection(chipSettings)
	-- ChipSelection(idx, chipSettings) or ChipSelection(chipSettings)
	function Target:ChipSelection(a, b)
		local idx, chipSettings = ResolveArgs(a, b)
		elementCount += 1

		local options = chipSettings.Options or {}
		local multi = chipSettings.Multi
		if multi == nil then multi = true end

		local selected = chipSettings.Default
		if multi then
			selected = type(selected) == "table" and selected or {}
		end

		local hasDescription = chipSettings.Description and chipSettings.Description ~= ""

		local Holder = create("Frame", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = Body,
		})

		local NameLabel = create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			Text = chipSettings.Name or "Chips",
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Holder,
		})
		RegisterThemeElement(NameLabel, "TextColor3", "TextPrimary", "TextPrimaryTransparency")

		local DescriptionLabel
		if hasDescription then
			DescriptionLabel = create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 20),
				Size = UDim2.new(1, 0, 0, 16),
				AutomaticSize = Enum.AutomaticSize.Y,
				FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
				Text = chipSettings.Description,
				TextSize = 12,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Holder,
			})
			RegisterThemeElement(DescriptionLabel, "TextColor3", "TextDim", "TextDimTransparency")
		end

		local ChipArea = create("Frame", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Position = UDim2.new(0, 0, 0, hasDescription and 42 or 24),
			Size = UDim2.new(1, 0, 0, 0),
			Parent = Holder,
		})

		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Wraps = true,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			Parent = ChipArea,
		})

		local chipButtons = {}

		local function isSelected(opt)
			if multi then
				for _, v in ipairs(selected) do
					if tostring(v) == tostring(opt) then return true end
				end
				return false
			else
				return selected ~= nil and tostring(selected) == tostring(opt)
			end
		end

		local function toggleSelect(opt)
			if multi then
				local found = false
				for i, v in ipairs(selected) do
					if tostring(v) == tostring(opt) then
						table.remove(selected, i)
						found = true
						break
					end
				end
				if not found then
					table.insert(selected, opt)
				end
			else
				if selected ~= nil and tostring(selected) == tostring(opt) then
					selected = nil
				else
					selected = opt
				end
			end
		end

		local function fireCallback()
			if chipSettings.Callback then
				chipSettings.Callback(multi and selected or selected)
			end
		end

		local buildChips

		function buildChips()
			for _, c in ipairs(chipButtons) do
				c:Destroy()
			end
			table.clear(chipButtons)

			for i, opt in ipairs(options) do
				local sel = isSelected(opt)

				local Chip = create("TextButton", {
					AutoButtonColor = false,
					BorderSizePixel = 0,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.new(0, 0, 0, 28),
					Text = "",
					LayoutOrder = i,
					Parent = ChipArea,
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Chip })
				create("UIPadding", {
					PaddingLeft = UDim.new(0, 14),
					PaddingRight = UDim.new(0, 14),
					Parent = Chip,
				})

				if sel then
					Chip.BackgroundColor3 = Valk.CurrentTheme.Accent
					Chip.BackgroundTransparency = 0.1
				else
					Chip.BackgroundTransparency = Valk.CurrentTheme.ElementBackgroundTransparency
					RegisterThemeElement(Chip, "BackgroundColor3", "ElementBackground", "ElementBackgroundTransparency")
				end

				create("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
					Transparency = sel and 0.6 or 0.85,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Parent = Chip,
				})

				local ChipLabel = create("TextLabel", {
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.new(0, 0, 1, 0),
					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", sel and Enum.FontWeight.Bold or Enum.FontWeight.Regular, Enum.FontStyle.Normal),
					Text = tostring(opt),
					TextSize = 13,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Parent = Chip,
				})

				if sel then
					ChipLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					RegisterThemeElement(ChipLabel, "TextColor3", "TextMuted", "TextMutedTransparency")
				end

				Chip.MouseButton1Click:Connect(function()
					toggleSelect(opt)
					buildChips()
					fireCallback()
				end)

				table.insert(chipButtons, Chip)
			end
		end

		buildChips()

		local ChipFunctions = { Instance = Holder }

		function ChipFunctions:SetOptions(newOptions)
			options = newOptions or {}
			buildChips()
		end

		function ChipFunctions:SetValue(value)
			if multi then
				selected = type(value) == "table" and value or {}
			else
				selected = value
			end
			buildChips()
			fireCallback()
		end

		function ChipFunctions:GetValue()
			return multi and selected or selected
		end

		function ChipFunctions:SetName(text)
			NameLabel.Text = text
		end

		function ChipFunctions:SetDescription(text)
			if DescriptionLabel then
				DescriptionLabel.Text = text
			end
		end

		ApplyVisible(Holder, chipSettings, ChipFunctions)
		AttachAddons(ChipFunctions, Holder, {})

		return RegisterOption(idx, ChipFunctions)
	end
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
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 700, 0, 500),
		BackgroundTransparency = 1, 
		ClipsDescendants = true,
		Parent = valkGui,
	})

	create("UICorner", { CornerRadius = UDim.new(0, 20), Parent = Main })
	local MainStroke = create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 1, Parent = Main })
	RegisterThemeElement(Main, "BackgroundColor3", "BaseBackground")

	local MainScale = create("UIScale", { Scale = 0.85, Parent = Main })

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
		BackgroundTransparency = 1,
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
			Size = UDim2.new(1, 0, 1, 0),
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

	local settingsCog = nil

	local cachedSettingsFunctions = nil

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
		Size = UDim2.new(1, -185, 1, -100),
		Parent = Main,
	})

	task.defer(function()
		Tween(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.1,
		}):Play()
		Tween(MainStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 0.65,
		}):Play()
		Tween(MainScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()
	end)

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
			BackgroundColor3 = Color3.fromRGB(80, 80, 80),
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

		local PageWrapper = create("CanvasGroup", {
			Name = (tabSettings.Name or "Tab") .. "PageWrapper",
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Visible = false,
			Parent = Containt,
		})

		local Page = create("ScrollingFrame", {
			Name = (tabSettings.Name or "Tab") .. "Page",
			Active = true,
			BackgroundTransparency = 0.5,
			BackgroundColor3 = Color3.fromRGB(50, 50, 50),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Size = UDim2.new(1, 0, 1, 0),
			ScrollBarThickness = 0,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = PageWrapper,
		})

		RegisterThemeElement(Page, "BackgroundTransparency", "PageTransparency")
		create("UICorner", { CornerRadius = UDim.new(0, 20), Parent = Page })

		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Parent = Page,
		})

		create("UIPadding", {
			PaddingTop = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 16),
			Parent = Page,
		})

		local TabFunctions = {
			Name = tabSettings.Name,
			Page = Page,
			PageWrapper = PageWrapper,
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
				local wrapper = t.PageWrapper

				if isActive then
					wrapper:SetAttribute("KeepVisible", true)
					wrapper.Visible = true
					Tween(wrapper, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						GroupTransparency = 0,
					}):Play()
				else
					wrapper:SetAttribute("KeepVisible", false)
					if wrapper.Visible then
						local hideTween = Tween(wrapper, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
							GroupTransparency = 1,
						})
						hideTween.Completed:Connect(function()
							-- Guard against a rapid re-select bringing this
							-- page back before the fade-out tween finished.
							if not wrapper:GetAttribute("KeepVisible") then
								wrapper.Visible = false
							end
						end)
						hideTween:Play()
					end
				end

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

		function TabFunctions:Section(title, icon, side)
			local SectionFrame = create("Frame", {
				Name = title or "Section",
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Size = UDim2.new(0.95, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
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

			local Body = create("Frame", {
				Name = "Body",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 3,
				Parent = SectionFrame,
			})

			create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				Parent = Body,
			})

			local collapsed = false
			local CollapseArrow

			if title or icon then
				local Row = create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 24),
					LayoutOrder = 1,
					Parent = SectionFrame,
				})

				if icon then
					local Icon = create("ImageLabel", {
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 0, 0.5, -8),
						Size = UDim2.new(0, 16, 0, 16),
						Image = icon,
						ImageColor3 = Color3.fromRGB(255, 255, 255),
						Parent = Row,
					})
					RegisterThemeElement(Icon, "ImageColor3", "Accent")
				end

				local HeaderLabel = create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.new(0, icon and 24 or 0, 0, 0),
					Size = UDim2.new(1, -(icon and 24 or 0) - 28, 1, 0),
					FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
					Text = title or "Section",
					TextSize = 18,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = Row,
				})
				RegisterThemeElement(HeaderLabel, "TextColor3", "TextPrimary", "TextPrimaryTransparency")

				local CollapseButton = create("TextButton", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 20, 0, 20),
					BackgroundTransparency = 1,
					Text = "",
					Parent = Row,
				})

				CollapseArrow = create("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(0, 14, 0, 14),
					BackgroundTransparency = 1,
					Image = "rbxassetid://101007429951147",
					ImageColor3 = Color3.fromRGB(255, 255, 255),
					Rotation = 90,
					Parent = CollapseButton,
				})
				RegisterThemeElement(CollapseArrow, "ImageColor3", "TextMuted", "ImageTransparency")

				CollapseButton.MouseButton1Click:Connect(function()
					collapsed = not collapsed
					Body.Visible = not collapsed
					Tween(CollapseArrow, TweenInfo.new(0.2), {
						Rotation = collapsed and 0 or 90,
					}):Play()
				end)

				local DividerHolder = create("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 1),
					LayoutOrder = 2,
					Parent = SectionFrame,
				})

				local DividerLine = create("Frame", {
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, 0),
					Parent = DividerHolder,
				})
				RegisterThemeElement(DividerLine, "BackgroundColor3", "DividerColor")

				create("UIGradient", {
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(0.5, 0.7),
						NumberSequenceKeypoint.new(1, 1),
					}),
					Parent = DividerLine,
				})
			end

			local SectionFunctions = { Frame = SectionFrame, Body = Body, Side = side }
			BuildElementFunctions(SectionFunctions, Body)

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


	function WindowFunctions:Settings(Type)
		Type = Type or 1

		if cachedSettingsFunctions then
			cachedSettingsFunctions:SetType(Type)
			return cachedSettingsFunctions
		end

		if not settingsCog then

			UserPill.Position = UDim2.new(1, -24 - 32 - 10, 0.5, 0)

			settingsCog = create("ImageButton", {
				Name = "SettingsCog",
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -24, 0.5, 0),
				Size = UDim2.new(0, 32, 0, 32),
				Image = "",
				AutoButtonColor = false,
				Parent = Header,
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = settingsCog })
			create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.7, Parent = settingsCog })
			RegisterThemeElement(settingsCog, "BackgroundColor3", "ElementBackground", "ElementBackgroundTransparency")

			local CogIcon = create("ImageLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 18, 0, 18),
				Image = "rbxassetid://106205298246017",
				Parent = settingsCog,
			})
			RegisterThemeElement(CogIcon, "ImageColor3", "TextPrimary", "TextPrimaryTransparency")
		end

		local Backdrop = create("TextButton", {
			Name = "SettingsBackdrop",
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Size = UDim2.new(1, 0, 1, 0),
			Visible = false,
			ZIndex = 20,
			Parent = Main,
		})

		create("UICorner", { CornerRadius = UDim.new(0, 20), Parent = Backdrop })

		local Panel = create("Frame", {
			Name = "SettingsPanel",
			BorderSizePixel = 0,
			BackgroundTransparency = 0.2,
			Active = true,
			ZIndex = 21,
			Parent = Backdrop,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 16), Parent = Panel })
		create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9, Parent = Panel })
		RegisterThemeElement(Panel, "BackgroundColor3", "BaseBackground")

		-- Pop-in scale for the panel itself, independent of the backdrop fade.
		local PanelScale = create("UIScale", { Scale = 0.85, Parent = Panel })

		local PanelHeader = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 40),
			ZIndex = 21,
			Parent = Panel,
		})

		local PanelTitle = create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 16, 0, 0),
			Size = UDim2.new(1, -50, 1, 0),
			FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			Text = "Settings",
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 21,
			Parent = PanelHeader,
		})
		RegisterThemeElement(PanelTitle, "TextColor3", "TextPrimary", "TextPrimaryTransparency")

		local CloseButton = create("ImageButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.new(0, 20, 0, 20),
			BackgroundTransparency = 1,
			Image = "rbxassetid://116396312853810",
			ZIndex = 21,
			Parent = PanelHeader,
		})

		local PanelBody = create("ScrollingFrame", {
			Active = true,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 44),
			Size = UDim2.new(1, 0, 1, -54),
			ScrollBarThickness = 0,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 21,
			Parent = Panel,
		})

		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			Parent = PanelBody,
		})

		create("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 10),
			Parent = PanelBody,
		})

		local isOpen = false
		local SettingsFunctions = { Panel = Panel, Body = PanelBody, Type = Type }

		local function targetBackdropTransparency()
			return SettingsFunctions.Type == 2 and 1 or 0.5
		end

		local function layoutForType()
			if SettingsFunctions.Type == 2 then
				Panel.AnchorPoint = Vector2.new(1, 0)
				Panel.Position = UDim2.new(1, -24, 0, 86)
				Panel.Size = UDim2.new(0, 240, 0, 280)
			else
				Panel.AnchorPoint = Vector2.new(0.5, 0.5)
				Panel.Position = UDim2.new(0.5, 0, 0.5, 0)
				Panel.Size = UDim2.new(0, 320, 0, 360)
			end
			if isOpen then
				Backdrop.BackgroundTransparency = targetBackdropTransparency()
			end
		end
		layoutForType()

		function SettingsFunctions:SetType(newType)
			SettingsFunctions.Type = newType
			layoutForType()
		end

		function SettingsFunctions:Open()
			if isOpen then return end
			isOpen = true
			Backdrop.Visible = true
			Backdrop.BackgroundTransparency = 1
			PanelScale.Scale = 0.85

			Tween(Backdrop, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = targetBackdropTransparency(),
			}):Play()
			Tween(PanelScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = 1,
			}):Play()
		end

		function SettingsFunctions:Close()
			if not isOpen then return end
			isOpen = false

			local fadeTween = Tween(Backdrop, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1,
			})
			Tween(PanelScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Scale = 0.85,
			}):Play()
			fadeTween.Completed:Connect(function()
				if not isOpen then
					Backdrop.Visible = false
				end
			end)
			fadeTween:Play()
		end

		function SettingsFunctions:Toggle()
			if isOpen then
				SettingsFunctions:Close()
			else
				SettingsFunctions:Open()
			end
		end

		CloseButton.MouseButton1Click:Connect(function()
			SettingsFunctions:Close()
		end)

		Backdrop.MouseButton1Click:Connect(function()
			if SettingsFunctions.Type == 1 then
				SettingsFunctions:Close()
			end
		end)

		settingsCog.MouseButton1Click:Connect(function()
			SettingsFunctions:Open()
		end)

		BuildElementFunctions(SettingsFunctions, PanelBody)

		cachedSettingsFunctions = SettingsFunctions
		return SettingsFunctions
	end

	windowState = WindowFunctions
	return WindowFunctions
end

return Valk
