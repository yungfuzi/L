local cloneref = (cloneref or clonereference or function(instance: any)
	return instance
end)
local CoreGui: CoreGui = cloneref(game:GetService("CoreGui"))
local Players: Players = cloneref(game:GetService("Players"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local SoundService: SoundService = cloneref(game:GetService("SoundService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))
local Teams: Teams = cloneref(game:GetService("Teams"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local getgenv = getgenv or function()
	return shared
end
local setclipboard = setclipboard or nil
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function()
	return PlayerGui
end

local Assets = {
	Icons =  {
		["MousePointerClick"] = "rbxassetid://81854854241463",
		["ChevronsUpDown"] = "rbxassetid://71880540200693",
		["ChevronRight"] = "rbxassetid://101007429951147",
		["Settings"] = "rbxassetid://106205298246017",

	},
}

local Labels = {}
local Buttons = {}
local Toggles = {}
local Options = {}
local Tooltips = {}

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
	UIStroke = {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	},
}

local Library = {
	DevicePlatform = nil,
	IsMobile = false,
	ScreenGui = nil,        
	Window = nil,
	WindowContainer = nil,
	ActiveTab = nil,
	TabGroups = {},
	Tabs = {},
	TabButtons = {},
	Labels = Labels,
	Buttons = Buttons,
	Toggles = Toggles,
	Options = Options,
	Tooltips = Tooltips,
	Scheme = {
		BackgroundColor = Color3.fromRGB(15, 15, 15),
		MainColor = Color3.fromRGB(25, 25, 25),
		AccentColor = Color3.fromRGB(0, 200, 255),
		OutlineColor = Color3.fromRGB(40, 40, 40),
		FontColor = Color3.new(1, 1, 1),
		Font = Font.fromEnum(Enum.Font.Roboto),
		RedColor = Color3.fromRGB(255, 50, 50),
		DestructiveColor = Color3.fromRGB(220, 38, 38),
		DarkColor = Color3.new(0, 0, 0),
		WhiteColor = Color3.new(1, 1, 1),
	},
	Registry = {},
	Templates = Templates,
	OriginalMinSize = Vector2.new(480, 360),
	MinSize = Vector2.new(480, 360),
	DPIScale = 1,
	Scales = {},
	Signals = {},
	UnloadCallbacks = {},
	Unloaded = false,
	Assets = Assets,
}

if RunService:IsStudio() then
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		Library.IsMobile = true
		Library.OriginalMinSize = Vector2.new(480, 240)
	else
		Library.IsMobile = false
		Library.OriginalMinSize = Vector2.new(480, 360)
	end
else
	pcall(function()
		Library.DevicePlatform = UserInputService:GetPlatform()
	end)
	Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
	Library.OriginalMinSize = Library.IsMobile and Vector2.new(480, 240) or Vector2.new(480, 360)
end

local function GetSchemeValue(Index)
	if not Index then return nil end
	return Library.Scheme[Index]
end

local function FillInstance(Properties, Instance)
	local ThemeProperties = {}
	for key, value in Properties do
		if key ~= "Text" then
			if type(value) == "function" then
				value = value()
			end
			if type(value) == "string" then
				local SchemeValue = GetSchemeValue(value)
				if SchemeValue then
					ThemeProperties[key] = value
					value = SchemeValue
				end
			end
		end
		Instance[key] = value
	end
	if next(ThemeProperties) then
		Library.Registry[Instance] = ThemeProperties
	end
end

local function HSVToRGB(H, S, V)
	if S == 0 then return V, V, V end
	local i = math.floor(H * 6)
	local f = H * 6 - i
	local p = V * (1 - S)
	local q = V * (1 - f * S)
	local t = V * (1 - (1 - f) * S)
	i = i % 6
	if i == 0 then return V, t, p
	elseif i == 1 then return q, V, p
	elseif i == 2 then return p, V, t
	elseif i == 3 then return p, q, V
	elseif i == 4 then return t, p, V
	else return V, p, q end
end

local function RGBToHSV(R, G, B)
	local max = math.max(R, G, B)
	local min = math.min(R, G, B)
	local V = max
	local delta = max - min
	if delta == 0 then return 0, 0, V end
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


Library.Colorpicker = {
	HSVToRGB = HSVToRGB,
	RGBToHSV = RGBToHSV,
}
function Library:New(ClassName, Properties)
	local Instance = Instance.new(ClassName)
	if self.Templates[ClassName] then
		FillInstance(self.Templates[ClassName], Instance)
	end
	if Properties then
		FillInstance(Properties, Instance)
	end
	return Instance
end

function Library:UpdateColors()
	for Instance, Properties in self.Registry do
		for Property, Key in Properties do
			Instance[Property] = GetSchemeValue(Key)
		end
	end
end

function Library:GetBetterColor(Color, Add)
	Add = Add or 0
	return Color3.fromRGB(
		math.clamp(Color.R * 255 + Add, 0, 255),
		math.clamp(Color.G * 255 + Add, 0, 255),
		math.clamp(Color.B * 255 + Add, 0, 255)
	)
end

function Library:GetCustomIcon(Icon)
	if not Icon then return nil end
	if type(Icon) == "number" then
		Icon = string.format("rbxassetid://%s", tostring(Icon))
	end
	return {
		Url = Icon,
		ImageRectOffset = Vector2.zero,
		ImageRectSize = Vector2.zero,
	}
end

function Library:MakeDraggable(UI, DragFrame)
	local Dragging = false
	local StartPos = nil
	local FramePos = nil
	DragFrame.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			StartPos = Input.Position
			FramePos = UI.Position
		end
	end)
	DragFrame.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
			local Delta = Input.Position - StartPos
			UI.Position = UDim2.new(
				FramePos.X.Scale, FramePos.X.Offset + Delta.X,
				FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y
			)
		end
	end)
end

function Library:MakeResizable(UI, ResizeButton)
	local Dragging = false
	local StartPos = nil
	local FrameSize = nil
	local MinSize = self.MinSize or Vector2.new(300, 200)
	ResizeButton.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			StartPos = Input.Position
			FrameSize = UI.Size
		end
	end)
	ResizeButton.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
			local Delta = Input.Position - StartPos
			UI.Size = UDim2.new(
				FrameSize.X.Scale,
				math.max(FrameSize.X.Offset + Delta.X, MinSize.X),
				FrameSize.Y.Scale,
				math.max(FrameSize.Y.Offset + Delta.Y, MinSize.Y)
			)
		end
	end)
end

function Library:CreateTabGroup(Container, Title, Icon, Collapsed)
	local BoxHolder = self:New("Frame", {
		Name = Title .. "TabGroupBoxHolder",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = Container,
	})
	self:New("UIListLayout", {
		Padding = UDim.new(0, 6),
		Parent = BoxHolder,
	})
	self:New("UIPadding", {
		PaddingBottom = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 4),
		Parent = BoxHolder,
	})

	local GroupHolder = self:New("Frame", {
		Name = Title .. "TabGroupHolder",
		BackgroundColor3 = "BackgroundColor",
		Size = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = BoxHolder,
	})
	self:New("UICorner", {
		CornerRadius = UDim.new(0, 4),
		Parent = GroupHolder,
	})


	local Header = self:New("TextButton", {
		Name = Title .. "TabGroupHeader",
		BackgroundTransparency = 1,
		BackgroundColor3 = "BackgroundColor",
		Size = UDim2.new(1, 0, 0, 34),
		Text = "",
		Parent = GroupHolder,
	})
	self:New("UICorner", {
		CornerRadius = UDim.new(0, 4),
		Parent = Header,
	})

	if Icon then
		local IconData = self:GetCustomIcon(Icon)
		self:New("ImageLabel", {
			Name = Title .. "TabGroupIcon",
			Image = IconData and IconData.Url or "rbxassetid://77937190465422",
			ImageRectOffset = IconData and IconData.ImageRectOffset or Vector2.zero,
			ImageRectSize = IconData and IconData.ImageRectSize or Vector2.zero,
			Position = UDim2.fromOffset(10, 7),
			Size = UDim2.fromOffset(20, 20),
			Parent = Header,
		})
	end

	local TitleLabel = self:New("TextLabel", {
		Name = Title .. "TabGroupTitle",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(Icon and 36 or 12, 0),
		Size = UDim2.new(1, Icon and -48 or -24, 1, 0),
		Text = Title,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Header,
	})

	local Arrow = self:New("ImageLabel", {
		Name = Title .. "TabGroupArrow",
		Image = "rbxassetid://101007429951147",
		ImageColor3 = "FontColor",
		ImageTransparency = 0.5,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		Parent = Header,
	})

	local Content = self:New("Frame", {
		Name = Title .. "TabGroupContent",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 35),
		Size = UDim2.new(1, 0, 1, -35),
		Visible = not Collapsed,
		Parent = GroupHolder,
	})
	self:New("UIListLayout", {
		Padding = UDim.new(0, 4),
		Parent = Content,
	})
	self:New("UIPadding", {
		PaddingBottom = UDim.new(0, 7),
		PaddingLeft = UDim.new(0, 7),
		PaddingRight = UDim.new(0, 7),
		PaddingTop = UDim.new(0, 7),
		Parent = Content,
	})

	local Tabs = {}

	local TabGroup = {
		Name = Title,
		Title = Title,
		Icon = Icon,
		Holder = GroupHolder,
		BoxHolder = BoxHolder,
		Content = Content,
		Header = Header,
		Arrow = Arrow,
		Tabs = Tabs,
		Collapsed = Collapsed or false,
		Visible = true,
		ActiveTab = nil,
		ContentContainer = nil,

		AddTab = function(self, Name, Icon)
			local Tab = Library:CreateTab(self.Content, self.ContentContainer, Name, Icon)
			table.insert(self.Tabs, Tab)
			if not self.ActiveTab then
				Tab:Show()
			end
			return Tab
		end,

		SetCollapsed = function(self, State)
			self.Collapsed = State
			local Rotation = State and 0 or 90
			TweenService:Create(self.Arrow, TweenInfo.new(0.2), {
				Rotation = Rotation,
			}):Play()
			TweenService:Create(self.Content, TweenInfo.new(0.2), {
				Visible = not State,
			}):Play()
			self:Resize()
		end,

		Toggle = function(self)
			self:SetCollapsed(not self.Collapsed)
		end,

		SetTitle = function(self, NewTitle)
			self.Title = NewTitle
			TitleLabel.Text = NewTitle
		end,

		SetIcon = function(self, NewIcon)
			self.Icon = NewIcon
			if NewIcon then
				local IconData = self:GetCustomIcon(NewIcon)
				if self.IconLabel then
					self.IconLabel.Image = IconData and IconData.Url or ""
					self.IconLabel.ImageRectOffset = IconData and IconData.ImageRectOffset or Vector2.zero
					self.IconLabel.ImageRectSize = IconData and IconData.ImageRectSize or Vector2.zero
					self.IconLabel.Visible = true
				end
			else
				if self.IconLabel then
					self.IconLabel.Visible = false
				end
			end
		end,

		SetVisible = function(self, Visible)
			self.Visible = Visible
			self.BoxHolder.Visible = Visible
		end,

		Resize = function(self)
			if self.Collapsed then
				self.Holder.Size = UDim2.new(1, 0, 0, 34)
			else
				local ContentSize = self.Content.UIListLayout.AbsoluteContentSize
				self.Holder.Size = UDim2.new(1, 0, 0, 35 + ContentSize.Y + 14)
			end
		end,

		Destroy = function(self)
			for _, Tab in self.Tabs do
				Tab:Destroy()
			end
			self.Holder:Destroy()
			self.BoxHolder:Destroy()
		end,
	}

	Header.MouseButton1Click:Connect(function()
		TabGroup:Toggle()
	end)

	local ContentList = self:New("UIListLayout", {
		Padding = UDim.new(0, 4),
		Parent = Content,
	})
	TabGroup.ContentList = ContentList

	ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TabGroup:Resize()
	end)

	TabGroup:Resize()

	return TabGroup
end

function Library:CreateTab(ButtonContainer, ContentContainer, Name, Icon)
	local TabButton = self:New("TextButton", {
		Name = Name .. "TabButton",
		BackgroundColor3 = "MainColor",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		Text = "",
		Parent = ButtonContainer,
	})
	local Label = self:New("TextLabel", {
		Name = Name .. "TabLabel",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(Icon and 34 or 12, 0),
		Size = UDim2.new(1, Icon and -34 or -12, 1, 0),
		Text = Name or "Tab",
		TextSize = 16,
		TextTransparency = 0.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TabButton,
	})
	if Icon then
		local IconData = self:GetCustomIcon(Icon)
		self:New("ImageLabel", {
			Name = Name .. "TabIcon",
			Image = IconData and IconData.Url or "",
			ImageRectOffset = IconData and IconData.ImageRectOffset or Vector2.zero,
			ImageRectSize = IconData and IconData.ImageRectSize or Vector2.zero,
			ImageTransparency = 0.5,
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.fromOffset(18, 18),
			Parent = TabButton,
		})
	end

	local TabCanvas = self:New("CanvasGroup", {
		Name = Name .. "Canvas",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = ContentContainer,
	})

	local ScrollFrame = self:New("ScrollingFrame", {
		Name = Name .. "Scroll",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = "OutlineColor",
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = TabCanvas,
	})

	self:New("UIPadding", {
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 6),
		Parent = ScrollFrame,
	})

	local ColumnsContainer = self:New("Frame", {
		Name = Name .. "Columns",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 0, 0), 
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = ScrollFrame,
	})

	self:New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		Parent = ColumnsContainer,
	})

	local LeftSide = self:New("Frame", {
		Name = Name .. "LeftSide",
		BackgroundTransparency = 1,
		Size = UDim2.new(0.5, -3, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = ColumnsContainer,
	})
	self:New("UIListLayout", {
		Padding = UDim.new(0, 6),
		Parent = LeftSide,
	})

	local RightSide = self:New("Frame", {
		Name = Name .. "RightSide",
		BackgroundTransparency = 1,
		Size = UDim2.new(0.5, -3, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = ColumnsContainer,
	})
	self:New("UIListLayout", {
		Padding = UDim.new(0, 6),
		Parent = RightSide,
	})

	local Tab = {
		Name = Name or "Tab",
		TabButton = TabButton,
		Label = Label,
		Canvas = TabCanvas,
		ScrollFrame = ScrollFrame,
		ColumnsContainer = ColumnsContainer,
		LeftSide = LeftSide,
		RightSide = RightSide,
		Active = false,
		Show = function(self)
			if Library.ActiveTab then
				Library.ActiveTab:Hide()
			end
			self.Active = true
			self.TabButton.BackgroundTransparency = 0.95
			self.Label.TextTransparency = 0
			self.Canvas.Visible = true
			Library.ActiveTab = self
		end,
		Hide = function(self)
			self.Active = false
			self.TabButton.BackgroundTransparency = 1
			self.Label.TextTransparency = 0.5
			self.Canvas.Visible = false
			if Library.ActiveTab == self then
				Library.ActiveTab = nil
			end
		end,
		AddLeftGroupbox = function(self, Title, Icon, Collapsed, Center)
			return Library:CreateGroupbox(self.LeftSide, Title, Icon, Collapsed, Center)
		end,
		AddRightGroupbox = function(self, Title, Icon, Collapsed, Center)
			return Library:CreateGroupbox(self.RightSide, Title, Icon, Collapsed, Center)
		end,
		Destroy = function(self)
			self.Canvas:Destroy()
			self.TabButton:Destroy()
		end,
	}
	TabButton.MouseButton1Click:Connect(function()
		Tab:Show()
	end)
	return Tab
end

function Library:CreateGroupbox(Container, Title, Icon, Collapsed, Center)
	Title = Title or "Groupbox"
	Collapsed = Collapsed or false
	Center = Center or false
	local BaseName = Title:gsub("[^%w]", "")

	local BoxHolder = self:New("Frame", {
		Name = BaseName .. "BoxHolder",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = Container,
	})
	self:New("UIListLayout", {
		Padding = UDim.new(0, 6),
		Parent = BoxHolder,
	})
	self:New("UIPadding", {
		PaddingBottom = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 4),
		Parent = BoxHolder,
	})

	local GroupboxHolder = self:New("Frame", {
		Name = BaseName .. "Holder",
		BackgroundColor3 = "BackgroundColor",
		BackgroundTransparency = 0.5,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = BoxHolder,
	})
	self:New("UICorner", {
		CornerRadius = UDim.new(0, 15),
		Parent = GroupboxHolder,
	})

	local Header = self:New("TextButton", {
		Name = BaseName .. "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		Text = "",
		AutoButtonColor = false,
		Parent = GroupboxHolder,
	})

	local IconLabel
	if Icon then
		local IconData = self:GetCustomIcon(Icon)
		IconLabel = self:New("ImageLabel", {
			Name = BaseName .. "Icon",
			Image = IconData and IconData.Url or "rbxassetid://77937190465422",
			ImageRectOffset = IconData and IconData.ImageRectOffset or Vector2.zero,
			ImageRectSize = IconData and IconData.ImageRectSize or Vector2.zero,
			ImageColor3 = "FontColor",
			ImageTransparency = 0,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 7),
			Size = UDim2.fromOffset(20, 20),
			Parent = Header,
		})
	end

	local TitleLabel = self:New("TextLabel", {
		Name = BaseName .. "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(Icon and 40 or 12, 0),
		Size = UDim2.new(1, Icon and -72 or -44, 1, 0),
		Text = Title,
		TextSize = 15,
		TextXAlignment = Center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
		Parent = Header,
	})

	local Arrow = self:New("ImageLabel", {
		Name = BaseName .. "Arrow",
		Image = "rbxassetid://101007429951147",
		ImageColor3 = "FontColor",
		ImageTransparency = 0.5,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		Rotation = Collapsed and 0 or 90,
		Parent = Header,
	})

	local Content = self:New("Frame", {
		Name = BaseName .. "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 35),
		Size = UDim2.new(1, 0, 1, -35),
		Visible = not Collapsed,
		Parent = GroupboxHolder,
	})
	self:New("UIListLayout", {
		Padding = UDim.new(0, 8),
		Parent = Content,
	})
	self:New("UIPadding", {
		PaddingBottom = UDim.new(0, 7),
		PaddingLeft = UDim.new(0, 7),
		PaddingRight = UDim.new(0, 7),
		PaddingTop = UDim.new(0, 7),
		Parent = Content,
	})

	local Groupbox = {
		Name = BaseName,
		Title = Title,
		Icon = Icon,
		Collapsed = Collapsed,
		Center = Center,
		Holder = GroupboxHolder,
		BoxHolder = BoxHolder,
		Content = Content,
		Header = Header,
		Arrow = Arrow,
		IconLabel = IconLabel,
		Elements = {},
		Visible = true,

		AddLabel = function(self, Text, Name)
			local Label = Library:CreateLabel(self.Content, Text, Name or Text)
			table.insert(self.Elements, Label)
			return Label
		end,

		AddButton = function(self, Text, Callback, Name)
			local Button = Library:CreateButton(self.Content, Text, Callback, Name or Text)
			table.insert(self.Elements, Button)
			return Button
		end,

		AddToggle = function(self, Text, Default, Callback, Name)
			local Toggle = Library:CreateToggle(self.Content, Text, Default, Callback, Name or Text)
			table.insert(self.Elements, Toggle)
			return Toggle
		end,

		AddSlider = function(self, Idx, Config)
			local Slider = Library:CreateSlider(self.Content, Idx, Config)
			table.insert(self.Elements, Slider)
			return Slider
		end,

		AddDropdown = function(self, Idx, Config)
			local Dropdown = Library:CreateDropdown(self.Content, Idx, Config)
			table.insert(self.Elements, Dropdown)
			return Dropdown
		end,

		AddInput = function(self, Idx, Config)
			local Input = Library:CreateInput(self.Content, Idx, Config)
			table.insert(self.Elements, Input)
			return Input
		end,

		AddKeybind = function(self, Idx, Config)
			local Keybind = Library:CreateKeybind(self.Content, Idx, Config)
			table.insert(self.Elements, Keybind)
			return Keybind
		end,

		AddParagraph = function(self, Idx, Config)
			local Paragraph = Library:CreateParagraph(self.Content, Idx, Config)
			table.insert(self.Elements, Paragraph)
			return Paragraph
		end,

		AddColorPicker = function(self, Idx, Config)
			local Picker = Library:CreateColorPicker(self.Content, Idx, Config)
			table.insert(self.Elements, Picker)
			return Picker
		end,


		SetCollapsed = function(self, State)
			self.Collapsed = State
			local Rotation = State and 0 or 90
			TweenService:Create(self.Arrow, TweenInfo.new(0.2), {
				Rotation = Rotation,
			}):Play()
			self.Content.Visible = not State
			self:Resize()
		end,

		Toggle = function(self)
			self:SetCollapsed(not self.Collapsed)
		end,

		SetTitle = function(self, NewTitle)
			self.Title = NewTitle
			TitleLabel.Text = NewTitle
		end,

		SetCenter = function(self, State)
			self.Center = State
			TitleLabel.TextXAlignment = State and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
		end,

		SetIcon = function(self, NewIcon)
			self.Icon = NewIcon
			if NewIcon then
				local IconData = Library:GetCustomIcon(NewIcon)
				if not self.IconLabel then
					self.IconLabel = Library:New("ImageLabel", {
						Name = self.Name .. "Icon",
						ImageColor3 = "FontColor",
						ImageTransparency = 0,
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(12, 7),
						Size = UDim2.fromOffset(20, 20),
						Parent = self.Header,
					})
				end
				self.IconLabel.Image = IconData and IconData.Url or "rbxassetid://77937190465422"
				self.IconLabel.ImageRectOffset = IconData and IconData.ImageRectOffset or Vector2.zero
				self.IconLabel.ImageRectSize = IconData and IconData.ImageRectSize or Vector2.zero
				self.IconLabel.Visible = true
				TitleLabel.Position = UDim2.fromOffset(40, 0)
				TitleLabel.Size = UDim2.new(1, -72, 1, 0)
			else
				if self.IconLabel then
					self.IconLabel.Visible = false
				end
				TitleLabel.Position = UDim2.fromOffset(12, 0)
				TitleLabel.Size = UDim2.new(1, -44, 1, 0)
			end
		end,

		SetVisible = function(self, Visible)
			self.Visible = Visible
			self.BoxHolder.Visible = Visible
		end,

		Resize = function(self)
			if self.Collapsed then
				self.Holder.Size = UDim2.new(1, 0, 0, 34)
			else
				local ContentSize = self.Content.UIListLayout.AbsoluteContentSize
				self.Holder.Size = UDim2.new(1, 0, 0, 35 + ContentSize.Y + 14)
			end
		end,

		Destroy = function(self)
			for _, Element in self.Elements do
				Element:Destroy()
			end
			self.Holder:Destroy()
			self.BoxHolder:Destroy()
		end,
	}

	Header.MouseButton1Click:Connect(function()
		Groupbox:Toggle()
	end)

	Content.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Groupbox:Resize()
	end)

	Groupbox:Resize()

	return Groupbox
end

function Library:CreateLabel(Container, Text, Name)
	Name = Name or Text or "Label"
	local Holder = self:New("Frame", {
		Name = Name .. "Holder",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Parent = Container,
	})
	local Label = self:New("TextLabel", {
		Name = Name .. "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Text = Text or "Label",
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Holder,
	})
	local LabelObject = {
		Name = Name,
		Text = Text or "Label",
		Holder = Holder,
		Label = Label,
		Visible = true,
		SetText = function(self, NewText)
			self.Text = NewText
			self.Label.Text = NewText
		end,
		SetVisible = function(self, Visible)
			self.Visible = Visible
			self.Holder.Visible = Visible
		end,
		Destroy = function(self)
			self.Holder:Destroy()
		end,
	}
	table.insert(Library.Labels, LabelObject)
	return LabelObject
end

function Library:CreateButton(Container, Text, Callback, Name)
	Name = Name or Text or "Button"
	local Holder = self:New("Frame", {
		Name = Name .. "Holder",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 21),
		Parent = Container,
	})
	local Button = self:New("TextButton", {
		Name = Name .. "Button",
		BackgroundColor3 = "MainColor",
		Size = UDim2.fromScale(1, 1),
		Text = Text or "Button",
		TextSize = 14,
		TextTransparency = 0.4,
		Parent = Holder,
	})
	self:New("UICorner", {
		CornerRadius = UDim.new(0, 4),
		Parent = Button,
	})
	self:New("UIStroke", {
		Color = "OutlineColor",
		Parent = Button,
	})
	local ButtonObject = {
		Name = Name,
		Text = Text or "Button",
		Callback = Callback or function() end,
		Holder = Holder,
		Button = Button,
		Disabled = false,
		Visible = true,
		SetText = function(self, NewText)
			self.Text = NewText
			self.Button.Text = NewText
		end,
		SetDisabled = function(self, Disabled)
			self.Disabled = Disabled
			self.Button.Active = not Disabled
			self.Button.TextTransparency = Disabled and 0.8 or 0.4
		end,
		SetVisible = function(self, Visible)
			self.Visible = Visible
			self.Holder.Visible = Visible
		end,
		Destroy = function(self)
			self.Holder:Destroy()
		end,
	}
	Button.MouseEnter:Connect(function()
		if not ButtonObject.Disabled then
			TweenService:Create(Button, TweenInfo.new(0.1), {
				TextTransparency = 0,
			}):Play()
		end
	end)
	Button.MouseLeave:Connect(function()
		if not ButtonObject.Disabled then
			TweenService:Create(Button, TweenInfo.new(0.1), {
				TextTransparency = 0.4,
			}):Play()
		end
	end)
	Button.MouseButton1Click:Connect(function()
		if not ButtonObject.Disabled then
			ButtonObject:Callback()
		end
	end)
	table.insert(Library.Buttons, ButtonObject)
	return ButtonObject
end

function Library:CreateToggle(Container, Text, Default, Callback, Name)
	Name = Name or Text or "Toggle"
	Default = Default or false
	local Holder = self:New("Frame", {
		Name = Name .. "Holder",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Parent = Container,
	})
	local Button = self:New("TextButton", {
		Name = Name .. "Button",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		Parent = Holder,
	})
	local Label = self:New("TextLabel", {
		Name = Name .. "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -40, 1, 0),
		Text = Text or "Toggle",
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Button,
	})
	local Switch = self:New("Frame", {
		Name = Name .. "Switch",
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = "MainColor",
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(32, 18),
		Parent = Button,
	})
	self:New("UICorner", {
		CornerRadius = UDim.new(1, 0),
		Parent = Switch,
	})
	self:New("UIPadding", {
		PaddingBottom = UDim.new(0, 2),
		PaddingLeft = UDim.new(0, 2),
		PaddingRight = UDim.new(0, 2),
		PaddingTop = UDim.new(0, 2),
		Parent = Switch,
	})
	local SwitchStroke = self:New("UIStroke", {
		Name = Name .. "SwitchStroke",
		Color = "OutlineColor",
		Parent = Switch,
	})
	local Ball = self:New("Frame", {
		Name = Name .. "Ball",
		BackgroundColor3 = "FontColor",
		Size = UDim2.fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Parent = Switch,
	})
	self:New("UICorner", {
		CornerRadius = UDim.new(1, 0),
		Parent = Ball,
	})
	local ToggleObject = {
		Name = Name,
		Text = Text or "Toggle",
		Value = Default,
		Callback = Callback or function() end,
		Holder = Holder,
		Button = Button,
		Label = Label,
		Switch = Switch,
		SwitchStroke = SwitchStroke,
		Ball = Ball,
		Disabled = false,
		Visible = true,
		_Display = function(self)
			local Offset = self.Value and 1 or 0
			self.Switch.BackgroundColor3 = self.Value and self.Scheme.AccentColor or self.Scheme.MainColor
			self.SwitchStroke.Color = self.Value and self.Scheme.AccentColor or self.Scheme.OutlineColor
			TweenService:Create(self.Ball, TweenInfo.new(0.15), {
				AnchorPoint = Vector2.new(Offset, 0),
				Position = UDim2.fromScale(Offset, 0),
			}):Play()
			TweenService:Create(self.Label, TweenInfo.new(0.15), {
				TextTransparency = self.Value and 0 or 0.4,
			}):Play()
		end,
		SetValue = function(self, Value)
			if self.Disabled then return end
			self.Value = Value
			self:_Display()
			if self.Callback then
				self.Callback(self.Value)
			end
		end,
		Toggle = function(self)
			self:SetValue(not self.Value)
		end,
		SetDisabled = function(self, Disabled)
			self.Disabled = Disabled
			self.Button.Active = not Disabled
			self.Label.TextTransparency = Disabled and 0.8 or 0.4
			self:_Display()
		end,
		SetVisible = function(self, Visible)
			self.Visible = Visible
			self.Holder.Visible = Visible
		end,
		SetText = function(self, NewText)
			self.Text = NewText
			self.Label.Text = NewText
		end,
		Destroy = function(self)
			self.Holder:Destroy()
		end,
	}
	ToggleObject.Scheme = self.Scheme
	Button.MouseButton1Click:Connect(function()
		ToggleObject:Toggle()
	end)
	ToggleObject:_Display()
	self.Toggles[Name] = ToggleObject
	table.insert(self.Toggles, ToggleObject)
	return ToggleObject
end


function Library:CreateSlider(Container, Idx, Config)
	Config = Config or {}
	local Text = Config.Text or Idx or "Slider"
	local Default = Config.Default or 50
	local Min = Config.Min or 0
	local Max = Config.Max or 100
	local Rounding = Config.Rounding or 0
	local Callback = Config.Callback or function() end
	local Suffix = Config.Suffix or ""
	local Compact = Config.Compact or false

	local BaseName = (Idx or Text):gsub("[^%w]", "")

	local Holder = self:New("Frame", {
		Name = BaseName .. "Holder",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Compact and 34 or 50),
		Parent = Container,
	})

	local Label = self:New("TextLabel", {
		Name = BaseName .. "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -65, 0, 16),
		Text = Text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 0.3,
		Parent = Holder,
	})

	local NumBox = self:New("TextBox", {
		Name = BaseName .. "NumBox",
		BackgroundTransparency = 1,
		TextColor3 = "FontColor",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(55, 16),
		Text = tostring(Default) .. Suffix,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTransparency = 0.4,
		ClearTextOnFocus = true,
		Parent = Holder,
	})

	local Track = self:New("Frame", {
		Name = BaseName .. "Track",
		BackgroundColor3 = "MainColor",
		Position = UDim2.fromOffset(0, Compact and 20 or 20),
		Size = UDim2.new(1, 0, 0, 14),
		Parent = Holder,
	})
	self:New("UICorner", {
		CornerRadius = UDim.new(0, 4),
		Parent = Track,
	})

	local Fill = self:New("Frame", {
		Name = BaseName .. "Fill",
		BackgroundColor3 = "AccentColor",
		Size = UDim2.fromScale((Default - Min) / (Max - Min), 1),
		Parent = Track,
	})
	self:New("UICorner", {
		CornerRadius = UDim.new(0, 4),
		Parent = Fill,
	})

	local Cursor = self:New("Frame", {
		Name = BaseName .. "Cursor",
		BackgroundColor3 = Color3.new(1, 1, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale((Default - Min) / (Max - Min), 0.5),
		Size = UDim2.fromOffset(4, 18),
		ZIndex = 10,
		Parent = Track,
	})
	self:New("UICorner", {CornerRadius = UDim.new(0, 2), Parent = Cursor})
	self:New("UIStroke", {Color = Color3.new(0, 0, 0), Thickness = 1, Parent = Cursor})

	local SliderObject = {
		Name = BaseName,
		Text = Text,
		Value = Default,
		Min = Min,
		Max = Max,
		Rounding = Rounding,
		Suffix = Suffix,
		Callback = Callback,
		Holder = Holder,
		Track = Track,
		Fill = Fill,
		Cursor = Cursor,
		Label = Label,
		NumBox = NumBox,
		Disabled = false,
		Visible = true,

		SetValue = function(self, Value)
			if self.Disabled then return end
			Value = math.clamp(Value, self.Min, self.Max)
			if self.Rounding > 0 then
				Value = math.floor(Value * (10 ^ self.Rounding) + 0.5) / (10 ^ self.Rounding)
			else
				Value = math.floor(Value + 0.5)
			end
			self.Value = Value
			local Scale = (Value - self.Min) / (self.Max - self.Min)
			self.Fill.Size = UDim2.fromScale(Scale, 1)
			self.Cursor.Position = UDim2.fromScale(Scale, 0.5)
			self.NumBox.Text = tostring(Value) .. self.Suffix
			if self.Callback then
				self.Callback(Value)
			end
		end,

		SetDisabled = function(self, Disabled)
			self.Disabled = Disabled
			self.Track.Active = not Disabled
			self.NumBox.Active = not Disabled
			self.NumBox.TextEditable = not Disabled
			self.Label.TextTransparency = Disabled and 0.8 or 0.3
			self.NumBox.TextTransparency = Disabled and 0.8 or 0.4
		end,

		SetVisible = function(self, Visible)
			self.Visible = Visible
			self.Holder.Visible = Visible
		end,

		SetText = function(self, NewText)
			self.Text = NewText
			self.Label.Text = NewText
		end,

		Destroy = function(self)
			self.Holder:Destroy()
		end,
	}

	local Dragging = false
	Track.InputBegan:Connect(function(Input)
		if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not SliderObject.Disabled then
			Dragging = true
			local Pos = math.clamp((Input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
			local Value = Min + (Max - Min) * Pos
			SliderObject:SetValue(Value)
		end
	end)
	Track.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) and not SliderObject.Disabled then
			local Pos = math.clamp((Input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
			local Value = Min + (Max - Min) * Pos
			SliderObject:SetValue(Value)
		end
	end)

	NumBox.FocusLost:Connect(function()
		if SliderObject.Disabled then return end
		local Clean = NumBox.Text:gsub("[^%d%.%-]", "")
		if Clean == "" or Clean == "-" then
			SliderObject:SetValue(SliderObject.Value)
			return
		end
		local Num = tonumber(Clean)
		if Num then
			SliderObject:SetValue(Num)
		else
			SliderObject:SetValue(SliderObject.Value)
		end
	end)

	return SliderObject
end

function Library:CreateDropdown(Container, Idx, Config)
	Config = Config or {}
	local Text = Config.Text or Idx or "Dropdown"
	local Values = Config.Values or {}
	local Default = Config.Default or 1
	local Multi = Config.Multi or false
	local Callback = Config.Callback or function() end

	local BaseName = (Idx or Text):gsub("[^%w]", "")

	local Holder = self:New("Frame", {
		Name = BaseName .. "Holder",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 5,
		Parent = Container,
	})

	local Label = self:New("TextLabel", {
		Name = BaseName .. "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Text = Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 0.3,
		ZIndex = 5,
		Parent = Holder,
	})

	local Button = self:New("TextButton", {
		Name = BaseName .. "Button",
		BackgroundColor3 = "MainColor",
		Position = UDim2.fromOffset(0, 20),
		Size = UDim2.new(1, 0, 0, 28),
		Text = "",
		ZIndex = 5,
		Parent = Holder,
	})
	self:New("UICorner", {
		CornerRadius = UDim.new(0, 6),
		Parent = Button,
	})
	self:New("UIStroke", {
		Color = "OutlineColor",
		Transparency = 0.5,
		Parent = Button,
	})

	local Display = self:New("TextLabel", {
		Name = BaseName .. "Display",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -36, 1, 0),
		Text = Multi and "Select..." or (Values[Default] or "Select..."),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 5,
		Parent = Button,
	})

	local Arrow = self:New("ImageLabel", {
		Name = BaseName .. "Arrow",
		Image = "rbxassetid://71880540200693",
		ImageColor3 = "FontColor",
		ImageTransparency = 0.4,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		ZIndex = 5,
		Parent = Button,
	})

	-- Dropdown list: dùng ScrollingFrame thay vì Frame để có scroll nếu nhiều option
	local DropdownFrame = self:New("ScrollingFrame", {
		Name = BaseName .. "Dropdown",
		BackgroundColor3 = "MainColor",
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 52),
		Size = UDim2.new(1, 0, 0, 0),
		Visible = false,
		ZIndex = 50,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = "OutlineColor",
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = Holder,
	})
	self:New("UICorner", {
		CornerRadius = UDim.new(0, 6),
		Parent = DropdownFrame,
	})
	self:New("UIStroke", {
		Color = "OutlineColor",
		Transparency = 0.5,
		Parent = DropdownFrame,
	})
	self:New("UIPadding", {
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 4),
		Parent = DropdownFrame,
	})

	local OptionList = self:New("UIListLayout", {
		Padding = UDim.new(0, 1),
		Parent = DropdownFrame,
	})

	local DropdownObject = {
		Name = BaseName,
		Text = Text,
		Values = Values,
		Value = Multi and {} or (Values[Default] or nil),
		Multi = Multi,
		Callback = Callback,
		Holder = Holder,
		Button = Button,
		Display = Display,
		Arrow = Arrow,
		DropdownFrame = DropdownFrame,
		IsOpen = false,
		Disabled = false,
		Visible = true,
		Options = {},

		SetValue = function(self, Value)
			if self.Disabled then return end
			if self.Multi then
				self.Value = Value
				local Selected = {}
				for k, v in pairs(Value) do
					if v then table.insert(Selected, k) end
				end
				self.Display.Text = #Selected > 0 and table.concat(Selected, ", ") or "Select..."
			else
				self.Value = Value
				self.Display.Text = Value or "Select..."
			end
			if self.Callback then
				self.Callback(self.Value)
			end
			self:RefreshOptions()
		end,

		RefreshOptions = function(self)
			for _, Opt in self.Options do
				Opt:Destroy()
			end
			self.Options = {}
			for i, Val in self.Values do
				local OptButton = Library:New("TextButton", {
					Name = Val .. "Option",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 24),
					Text = Val,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 50,
					Parent = self.DropdownFrame,
				})
				Library:New("UIPadding", {
					PaddingLeft = UDim.new(0, 8),
					Parent = OptButton,
				})

				local IsSelected = self.Multi and (self.Value[Val] == true) or (self.Value == Val)
				if IsSelected then
					OptButton.TextColor3 = Library.Scheme.AccentColor
				else
					OptButton.TextColor3 = Library.Scheme.FontColor
				end

				OptButton.MouseEnter:Connect(function()
					if not IsSelected then
						TweenService:Create(OptButton, TweenInfo.new(0.1), {
							BackgroundTransparency = 0.9,
							BackgroundColor3 = Library.Scheme.AccentColor,
						}):Play()
					end
				end)
				OptButton.MouseLeave:Connect(function()
					TweenService:Create(OptButton, TweenInfo.new(0.1), {
						BackgroundTransparency = 1,
					}):Play()
				end)

				OptButton.MouseButton1Click:Connect(function()
					if self.Multi then
						local NewVal = table.clone(self.Value)
						NewVal[Val] = not NewVal[Val]
						self:SetValue(NewVal)
					else
						self:SetValue(Val)
						if CloseOnSelected then
							self:Close()
						end
					end
				end)

				table.insert(self.Options, OptButton)
			end
			local ContentSize = OptionList.AbsoluteContentSize
			self.DropdownFrame.Size = UDim2.new(1, 0, 0, math.min(ContentSize.Y + 8, 180))
		end,

		Open = function(self)
			self.IsOpen = true
			self.Holder.ZIndex = 100
			TweenService:Create(self.Arrow, TweenInfo.new(0.15), { Rotation = 180 }):Play()
			self.DropdownFrame.Visible = true
			self.DropdownFrame.CanvasSize = UDim2.new(0, 0, 0, OptionList.AbsoluteContentSize.Y + 8)
		end,

		Close = function(self)
			self.IsOpen = false
			self.Holder.ZIndex = 5
			TweenService:Create(self.Arrow, TweenInfo.new(0.15), { Rotation = 0 }):Play()
			self.DropdownFrame.Visible = false
		end,

		Toggle = function(self)
			if self.IsOpen then self:Close() else self:Open() end
		end,

		SetValues = function(self, NewValues)
			self.Values = NewValues
			self:RefreshOptions()
		end,

		SetDisabled = function(self, Disabled)
			self.Disabled = Disabled
			self.Button.Active = not Disabled
			self.Label.TextTransparency = Disabled and 0.8 or 0.3
		end,

		SetVisible = function(self, Visible)
			self.Visible = Visible
			self.Holder.Visible = Visible
		end,

		SetText = function(self, NewText)
			self.Text = NewText
			self.Label.Text = NewText
		end,

		Destroy = function(self)
			self.Holder:Destroy()
		end,
	}

	Button.MouseButton1Click:Connect(function()
		if not DropdownObject.Disabled then
			DropdownObject:Toggle()
		end
	end)

	DropdownObject:RefreshOptions()

	-- CloseOnSelected: tự động đóng khi chọn option (single mode)
	-- Mặc định: true cho single, false cho multi
	local CloseOnSelected = Config.CloseOnSelected
	if CloseOnSelected == nil then
		CloseOnSelected = not Multi
	end

	return DropdownObject
end

function Library:CreateInput(Container, Idx, Config)
	Config = Config or {}
	local Text = Config.Text or Idx or "Input"
	local Default = Config.Default or ""
	local Placeholder = Config.Placeholder or ""
	local Callback = Config.Callback or function() end
	local Numeric = Config.Numeric or false
	local Finished = Config.Finished or false

	local BaseName = (Idx or Text):gsub("[^%w]", "")

	local Holder = self:New("Frame", {
		Name = BaseName .. "Holder",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		Parent = Container,
	})

	local Label = self:New("TextLabel", {
		Name = BaseName .. "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -115, 1, 0),
		Text = Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 0.3,
		Parent = Holder,
	})

	local Box = self:New("TextBox", {
		Name = BaseName .. "Box",
		BackgroundColor3 = "MainColor",
		TextColor3 = "FontColor",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(110, 24),
		Text = Default,
		PlaceholderText = Placeholder,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ClearTextOnFocus = false,
		Parent = Holder,
	})
	self:New("UICorner", {
		CornerRadius = UDim.new(0, 6),
		Parent = Box,
	})
	self:New("UIStroke", {
		Color = "OutlineColor",
		Transparency = 0.6,
		Parent = Box,
	})
	self:New("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = Box,
	})

	-- Focus effect: stroke đổi màu accent khi focus
	Box.Focused:Connect(function()
		TweenService:Create(Box:FindFirstChildOfClass("UIStroke"), TweenInfo.new(0.15), {
			Color = Library.Scheme.AccentColor,
			Transparency = 0,
		}):Play()
	end)
	Box.FocusLost:Connect(function()
		TweenService:Create(Box:FindFirstChildOfClass("UIStroke"), TweenInfo.new(0.15), {
			Color = Library.Scheme.OutlineColor,
			Transparency = 0.6,
		}):Play()
	end)

	local InputObject = {
		Name = BaseName,
		Text = Text,
		Value = Default,
		Callback = Callback,
		Holder = Holder,
		Box = Box,
		Label = Label,
		Disabled = false,
		Visible = true,

		SetValue = function(self, Value)
			if self.Disabled then return end
			self.Value = Value
			self.Box.Text = Value
			if self.Callback then
				self.Callback(Value)
			end
		end,

		SetDisabled = function(self, Disabled)
			self.Disabled = Disabled
			self.Box.Active = not Disabled
			self.Box.TextEditable = not Disabled
			self.Label.TextTransparency = Disabled and 0.8 or 0.3
		end,

		SetVisible = function(self, Visible)
			self.Visible = Visible
			self.Holder.Visible = Visible
		end,

		SetText = function(self, NewText)
			self.Text = NewText
			self.Label.Text = NewText
		end,

		Destroy = function(self)
			self.Holder:Destroy()
		end,
	}

	Box.FocusLost:Connect(function(EnterPressed)
		if Numeric then
			local Num = tonumber(Box.Text)
			if Num then
				InputObject:SetValue(tostring(Num))
			else
				Box.Text = InputObject.Value
			end
		else
			InputObject:SetValue(Box.Text)
		end
		if Finished and EnterPressed and InputObject.Callback then
			InputObject.Callback(InputObject.Value)
		end
	end)

	Box:GetPropertyChangedSignal("Text"):Connect(function()
		if not Finished and not InputObject.Disabled then
			InputObject.Value = Box.Text
			if InputObject.Callback then
				InputObject.Callback(Box.Text)
			end
		end
	end)

	return InputObject
end

function Library:CreateKeybind(Container, Idx, Config)
	Config = Config or {}
	local Text = Config.Text or Idx or "Keybind"
	local Default = Config.Default or Enum.KeyCode.Unknown
	local Callback = Config.Callback or function() end
	local NoHold = Config.NoHold or false

	local BaseName = (Idx or Text):gsub("[^%w]", "")

	local Holder = self:New("Frame", {
		Name = BaseName .. "Holder",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		Parent = Container,
	})

	local Label = self:New("TextLabel", {
		Name = BaseName .. "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 1, 0),
		Text = Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Holder,
	})

	local KeyButton = self:New("TextButton", {
		Name = BaseName .. "Key",
		BackgroundColor3 = "MainColor",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(55, 18),
		Text = Default ~= Enum.KeyCode.Unknown and Default.Name or "None",
		TextSize = 12,
		Parent = Holder,
	})
	self:New("UICorner", {
		CornerRadius = UDim.new(1, 0),
		Parent = KeyButton,
	})
	self:New("UIStroke", {
		Color = "OutlineColor",
		Parent = KeyButton,
	})

	local KeybindObject = {
		Name = BaseName,
		Text = Text,
		Value = Default,
		Callback = Callback,
		NoHold = NoHold,
		Holder = Holder,
		KeyButton = KeyButton,
		Label = Label,
		Listening = false,
		Disabled = false,
		Visible = true,

		SetValue = function(self, Key)
			if self.Disabled then return end
			self.Value = Key
			self.KeyButton.Text = Key ~= Enum.KeyCode.Unknown and Key.Name or "None"
			if self.Callback then
				self.Callback(Key)
			end
		end,

		SetDisabled = function(self, Disabled)
			self.Disabled = Disabled
			self.KeyButton.Active = not Disabled
			self.Label.TextTransparency = Disabled and 0.8 or 0
		end,

		SetVisible = function(self, Visible)
			self.Visible = Visible
			self.Holder.Visible = Visible
		end,

		SetText = function(self, NewText)
			self.Text = NewText
			self.Label.Text = NewText
		end,

		Destroy = function(self)
			self.Holder:Destroy()
		end,
	}

	KeyButton.MouseButton1Click:Connect(function()
		if KeybindObject.Disabled then return end
		KeybindObject.Listening = true
		KeyButton.Text = "..."
	end)

	UserInputService.InputBegan:Connect(function(Input)
		if KeybindObject.Listening and Input.UserInputType == Enum.UserInputType.Keyboard then
			KeybindObject.Listening = false
			if Input.KeyCode == Enum.KeyCode.Escape then
				KeybindObject:SetValue(Enum.KeyCode.Unknown)
			else
				KeybindObject:SetValue(Input.KeyCode)
			end
		elseif not KeybindObject.Listening and Input.UserInputType == Enum.UserInputType.Keyboard
			and Input.KeyCode == KeybindObject.Value and KeybindObject.Value ~= Enum.KeyCode.Unknown then
			if KeybindObject.NoHold then
				if KeybindObject.Callback then
					KeybindObject.Callback(true)
				end
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(Input)
		if not KeybindObject.Listening and not KeybindObject.NoHold
			and Input.UserInputType == Enum.UserInputType.Keyboard
			and Input.KeyCode == KeybindObject.Value then
			if KeybindObject.Callback then
				KeybindObject.Callback(false)
			end
		end
	end)

	return KeybindObject
end

function Library:CreateParagraph(Container, Idx, Config)
	Config = Config or {}
	local Title = Config.Title or Config.Text or Idx or "Paragraph"
	local Content = Config.Content or ""
	local TitleSize = Config.TitleSize or 14
	local ContentSize = Config.ContentSize or 12
	local TitleColor = Config.TitleColor or "FontColor"
	local ContentColor = Config.ContentColor or "FontColor"
	local TitleTransparency = Config.TitleTransparency or 0
	local ContentTransparency = Config.ContentTransparency or 0.4
	local Alignment = Config.Alignment or Config.TextXAlignment or Enum.TextXAlignment.Left
	local TitleAlignment = Config.TitleXAlignment or Config.TitleAlignment or Alignment
	local RichText = Config.RichText ~= false
	local Spacing = Config.Spacing or 4

	local BaseName = (Idx or Title):gsub("[^%w]", "")

	local Holder = self:New("Frame", {
		Name = BaseName .. "ParagraphHolder",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = Container,
	})

	self:New("UIListLayout", {
		Padding = UDim.new(0, Spacing),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = Holder,
	})

	local TitleLabel = self:New("TextLabel", {
		Name = BaseName .. "Title",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, TitleSize + 2),
		Text = Title,
		TextSize = TitleSize,
		TextColor3 = TitleColor,
		LayoutOrder = 0,
		TextTransparency = TitleTransparency,
		TextXAlignment = TitleAlignment,
		RichText = RichText,
		Parent = Holder,
	})

	local ContentLabel = self:New("TextLabel", {
		Name = BaseName .. "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = Content,
		TextSize = ContentSize,
		TextColor3 = ContentColor,
		TextTransparency = ContentTransparency,
		LayoutOrder = 1,
		TextXAlignment = Alignment,
		TextWrapped = true,
		RichText = RichText,
		Parent = Holder,
	})

	local ParagraphObject = {
		Name = BaseName,
		Title = Title,
		Content = Content,
		Holder = Holder,
		TitleLabel = TitleLabel,
		ContentLabel = ContentLabel,
		Visible = true,

		SetTitle = function(self, NewTitle)
			self.Title = NewTitle
			self.TitleLabel.Text = NewTitle
		end,

		SetContent = function(self, NewContent)
			self.Content = NewContent
			self.ContentLabel.Text = NewContent
		end,

		SetVisible = function(self, Visible)
			self.Visible = Visible
			self.Holder.Visible = Visible
		end,

		Destroy = function(self)
			self.Holder:Destroy()
		end,
	}

	return ParagraphObject
end

function Library:CreateColorPicker(Container, Idx, Config)
	Config = Config or {}
	local Text = Config.Text or Config.Title or Idx or "Color"
	local Default = Config.Default or Color3.fromRGB(0, 170, 255)
	local TransparencyDefault = Config.Transparency or 0
	local Callback = Config.Callback or function() end
	local BaseName = (Idx or Text):gsub("[^%w]", "")

	local Holder = self:New("Frame", {
		Name = BaseName .. "ColorPickerHolder",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		Parent = Container,
	})

	local Label = self:New("TextLabel", {
		Name = BaseName .. "Label",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -56, 1, 0),
		Text = Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Holder,
	})

	local ColorBtn = self:New("TextButton", {
		Name = BaseName .. "ColorBtn",
		BackgroundColor3 = Default,
		BackgroundTransparency = TransparencyDefault,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(48, 18),
		Text = "",
		Parent = Holder,
	})
	self:New("UICorner", {CornerRadius = UDim.new(0, 4), Parent = ColorBtn})
	self:New("UIStroke", {Color = "OutlineColor", Parent = ColorBtn})

	local Popup = self:New("Frame", {
		Name = BaseName .. "ColorPopup",
		BackgroundColor3 = "BackgroundColor",
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(240, 320),
		Visible = false,
		ZIndex = 100,
		Parent = self.ColorpickerFolder or self.ScreenGui or gethui(),
	})
	self:New("UICorner", {CornerRadius = UDim.new(0, 10), Parent = Popup})
	self:New("UIStroke", {Color = "OutlineColor", Parent = Popup})
	self:New("UIPadding", {
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 12),
		Parent = Popup,
	})
	local ColorPickerScale = self:New("UIScale", {Scale = self.DPIScale or 1, Parent = Popup})
	table.insert(self.Scales, ColorPickerScale)

	local PopupList = self:New("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = Popup,
	})

	local DragHandle = self:New("Frame", {
		Name = "ADragHandle",
		BackgroundTransparency = 0.6,
		BackgroundColor3 = "OutlineColor",
		Size = UDim2.new(1, 0, 0, 6),
		LayoutOrder = 1,
		Active = true,
		ZIndex = 250,
		Parent = Popup,
	})
	self:New("UICorner", {
		CornerRadius = UDim.new(1, 0),
		Parent = DragHandle,
	})

	self:MakeDraggable(Popup, DragHandle)

	local SVHolder = self:New("Frame", {
		Name = "SVHolder",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 100),
		LayoutOrder = 2,
		Parent = Popup,
	})

	local SatFrame = self:New("Frame", {
		Name = "SatFrame",
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromScale(1, 1),
		Parent = SVHolder,
	})
	self:New("UICorner", {CornerRadius = UDim.new(0, 6), Parent = SatFrame})

	local SatGradient = self:New("UIGradient", {
		Color = ColorSequence.new(Color3.new(1,1,1), Default),
		Parent = SatFrame,
	})

	local ValFrame = self:New("Frame", {
		Name = "ValFrame",
		BackgroundColor3 = Color3.new(0, 0, 0),
		Size = UDim2.fromScale(1, 1),
		Parent = SVHolder,
	})
	self:New("UICorner", {CornerRadius = UDim.new(0, 6), Parent = ValFrame})
	self:New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new(1, 0),
		Parent = ValFrame,
	})

	local SVCursor = self:New("Frame", {
		Name = "SVCursor",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(6, 6),
		Parent = SVHolder,
	})
	self:New("UICorner", {CornerRadius = UDim.new(1, 0), Parent = SVCursor})
	self:New("UIStroke", {Color = Color3.new(0,0,0), Thickness = 1.5, Parent = SVCursor})

	local HueFrame = self:New("Frame", {
		Name = "HueFrame",
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.new(1, 0, 0, 14),
		LayoutOrder = 3,
		Parent = Popup,
	})
	self:New("UICorner", {CornerRadius = UDim.new(0, 4), Parent = HueFrame})
	self:New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
			ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255,255,0)),
			ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0,255,0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
			ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0,0,255)),
			ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255,0,255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0)),
		}),
		Parent = HueFrame,
	})

	local HueCursor = self:New("Frame", {
		Name = "HueCursor",
		BackgroundColor3 = Color3.new(1, 1, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(4, 18),
		Parent = HueFrame,
	})
	self:New("UICorner", {CornerRadius = UDim.new(0, 2), Parent = HueCursor})
	self:New("UIStroke", {Color = Color3.new(0,0,0), Thickness = 1, Parent = HueCursor})

	local OpacityLabel = self:New("TextLabel", {
		Name = "OpacityLabel",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Text = "Opacity",
		TextSize = 12,
		TextTransparency = 0.4,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 4,
		Parent = Popup,
	})

	local OpacityFrame = self:New("Frame", {
		Name = "OpacityFrame",
		BackgroundColor3 = "MainColor",
		Size = UDim2.new(1, 0, 0, 14),
		LayoutOrder = 5,
		Parent = Popup,
	})
	self:New("UICorner", {CornerRadius = UDim.new(0, 4), Parent = OpacityFrame})

	local OpacityFill = self:New("Frame", {
		Name = "OpacityFill",
		BackgroundColor3 = "AccentColor",
		Size = UDim2.fromScale(1 - TransparencyDefault, 1),
		Parent = OpacityFrame,
	})
	self:New("UICorner", {CornerRadius = UDim.new(0, 4), Parent = OpacityFill})

	local OpacityCursor = self:New("Frame", {
		Name = "OpacityCursor",
		BackgroundColor3 = Color3.new(1,1,1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(1 - TransparencyDefault, 0.5),
		Size = UDim2.fromOffset(4, 18),
		Parent = OpacityFrame,
	})
	self:New("UICorner", {CornerRadius = UDim.new(0, 2), Parent = OpacityCursor})
	self:New("UIStroke", {Color = Color3.new(0,0,0), Thickness = 1, Parent = OpacityCursor})

	local BottomRow = self:New("Frame", {
		Name = "BottomRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		LayoutOrder = 6,
		Parent = Popup,
	})
	self:New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = BottomRow,
	})

	local Preview = self:New("Frame", {
		Name = "Preview",
		BackgroundColor3 = Default,
		BackgroundTransparency = TransparencyDefault,
		Size = UDim2.fromOffset(32, 32),
		Parent = BottomRow,
	})
	self:New("UICorner", {CornerRadius = UDim.new(0, 6), Parent = Preview})
	self:New("UIStroke", {Color = "OutlineColor", Parent = Preview})

	local HexBox = self:New("TextBox", {
		Name = "HexBox",
		BackgroundColor3 = "MainColor",
		TextColor3 = "FontColor",
		Size = UDim2.new(1, -40, 0, 28),
		Text = string.format("#%02X%02X%02X", Default.R*255, Default.G*255, Default.B*255),
		PlaceholderText = "#RRGGBB",
		TextSize = 12,
		Parent = BottomRow,
	})
	self:New("UICorner", {CornerRadius = UDim.new(0, 6), Parent = HexBox})
	self:New("UIStroke", {Color = "OutlineColor", Parent = HexBox})
	self:New("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = HexBox})

	-- RGB Inputs
	local RGBRow = self:New("Frame", {
		Name = "RGBRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 7,
		Parent = Popup,
	})
	self:New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		Parent = RGBRow,
	})

	local function MakeRGBBox(Name, DefaultVal)
		local Box = self:New("TextBox", {
			Name = Name .. "Box",
			BackgroundColor3 = "MainColor",
			TextColor3 = "FontColor",
			Size = UDim2.new(0.333, -4, 1, 0),
			Text = tostring(DefaultVal),
			PlaceholderText = Name,
			TextSize = 12,
			Parent = RGBRow,
		})
		self:New("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Box})
		self:New("UIStroke", {Color = "OutlineColor", Parent = Box})
		self:New("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = Box})
		return Box
	end

	local RBox = MakeRGBBox("R", math.floor(Default.R * 255))
	local GBox = MakeRGBBox("G", math.floor(Default.G * 255))
	local BBox = MakeRGBBox("B", math.floor(Default.B * 255))

	local BtnRow = self:New("Frame", {
		Name = "BtnRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		LayoutOrder = 8,
		Parent = Popup,
	})
	self:New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		Parent = BtnRow,
	})

	local ConfirmBtn = self:New("TextButton", {
		Name = "ConfirmBtn",
		BackgroundColor3 = "AccentColor",
		Size = UDim2.new(0.5, -4, 1, 0),
		Text = "Confirm",
		TextColor3 = "WhiteColor",
		TextSize = 13,
		Parent = BtnRow,
	})
	self:New("UICorner", {CornerRadius = UDim.new(0, 6), Parent = ConfirmBtn})

	local CancelBtn = self:New("TextButton", {
		Name = "CancelBtn",
		BackgroundColor3 = "MainColor",
		Size = UDim2.new(0.5, -4, 1, 0),
		Text = "Cancel",
		TextColor3 = "FontColor",
		TextSize = 13,
		Parent = BtnRow,
	})
	self:New("UICorner", {CornerRadius = UDim.new(0, 6), Parent = CancelBtn})

	-- State
	local H, S, V = RGBToHSV(Default.R, Default.G, Default.B)
	local Alpha = TransparencyDefault
	local Open = false

	local function UpdateSVGradient()
		local r, g, b = HSVToRGB(H, 1, 1)
		SatGradient.Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(r, g, b))
	end

	local function UpdateUIFromState()
		local R, G, B = HSVToRGB(H, S, V)
		local Color = Color3.new(R, G, B)

		SVCursor.Position = UDim2.fromScale(S, 1 - V)
		HueCursor.Position = UDim2.fromScale(H, 0.5)
		OpacityCursor.Position = UDim2.fromScale(1 - Alpha, 0.5)
		OpacityFill.Size = UDim2.fromScale(1 - Alpha, 1)

		Preview.BackgroundColor3 = Color
		Preview.BackgroundTransparency = Alpha
		ColorBtn.BackgroundColor3 = Color
		ColorBtn.BackgroundTransparency = Alpha

		HexBox.Text = string.format("#%02X%02X%02X", R*255, G*255, B*255)
		RBox.Text = tostring(math.floor(R * 255))
		GBox.Text = tostring(math.floor(G * 255))
		BBox.Text = tostring(math.floor(B * 255))

		UpdateSVGradient()
	end

	local function SetFromRGB(r, g, b)
		H, S, V = RGBToHSV(r, g, b)
		UpdateUIFromState()
	end

	local function Apply()
		local R, G, B = HSVToRGB(H, S, V)
		local Color = Color3.new(R, G, B)
		if Callback then
			Callback(Color, Alpha)
		end
	end

	local SVDragging = false
	SVHolder.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			SVDragging = true
			local ap = SVHolder.AbsolutePosition
			local as = SVHolder.AbsoluteSize
			local x = math.clamp((Input.Position.X - ap.X) / as.X, 0, 1)
			local y = math.clamp((Input.Position.Y - ap.Y) / as.Y, 0, 1)
			S, V = x, 1 - y
			UpdateUIFromState()
		end
	end)
	SVHolder.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then SVDragging = false end
	end)

	-- Hue dragging
	local HueDragging = false
	HueFrame.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			HueDragging = true
			local ap = HueFrame.AbsolutePosition
			local as = HueFrame.AbsoluteSize
			H = math.clamp((Input.Position.X - ap.X) / as.X, 0, 1)
			UpdateUIFromState()
		end
	end)
	HueFrame.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then HueDragging = false end
	end)

	local OpacityDragging = false
	OpacityFrame.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			OpacityDragging = true
			local ap = OpacityFrame.AbsolutePosition
			local as = OpacityFrame.AbsoluteSize
			Alpha = 1 - math.clamp((Input.Position.X - ap.X) / as.X, 0, 1)
			UpdateUIFromState()
		end
	end)
	OpacityFrame.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then OpacityDragging = false end
	end)

	UserInputService.InputChanged:Connect(function(Input)
		if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then return end
		if SVDragging then
			local ap = SVHolder.AbsolutePosition
			local as = SVHolder.AbsoluteSize
			S = math.clamp((Input.Position.X - ap.X) / as.X, 0, 1)
			V = 1 - math.clamp((Input.Position.Y - ap.Y) / as.Y, 0, 1)
			UpdateUIFromState()
		elseif HueDragging then
			local ap = HueFrame.AbsolutePosition
			local as = HueFrame.AbsoluteSize
			H = math.clamp((Input.Position.X - ap.X) / as.X, 0, 1)
			UpdateUIFromState()
		elseif OpacityDragging then
			local ap = OpacityFrame.AbsolutePosition
			local as = OpacityFrame.AbsoluteSize
			Alpha = 1 - math.clamp((Input.Position.X - ap.X) / as.X, 0, 1)
			UpdateUIFromState()
		end
	end)

	-- Hex input
	HexBox.FocusLost:Connect(function()
		local txt = HexBox.Text:gsub("#", "")
		if #txt == 6 then
			local r = tonumber(txt:sub(1,2), 16)
			local g = tonumber(txt:sub(3,4), 16)
			local b = tonumber(txt:sub(5,6), 16)
			if r and g and b then
				SetFromRGB(r/255, g/255, b/255)
			end
		end
		UpdateUIFromState()
	end)

	-- RGB inputs
	local function HandleRGBBox(Box, Index)
		Box.FocusLost:Connect(function()
			local n = tonumber(Box.Text)
			if n then
				n = math.clamp(math.floor(n), 0, 255) / 255
				local R, G, B = HSVToRGB(H, S, V)
				if Index == 1 then R = n elseif Index == 2 then G = n else B = n end
				SetFromRGB(R, G, B)
			else
				UpdateUIFromState()
			end
		end)
	end
	HandleRGBBox(RBox, 1)
	HandleRGBBox(GBox, 2)
	HandleRGBBox(BBox, 3)

	-- Open / Close
	local function PositionPopup()
		local abs = ColorBtn.AbsolutePosition
		local scale = self.DPIScale or 1
		Popup.Position = UDim2.fromOffset(abs.X - 180 * scale, abs.Y + 28 * scale)
	end

	local function OpenPopup()
		Open = true
		PositionPopup()
		Popup.Visible = true
		UpdateUIFromState()
	end

	local function ClosePopup()
		Open = false
		Popup.Visible = false
	end

	ColorBtn.MouseButton1Click:Connect(function()
		if Open then ClosePopup() else OpenPopup() end
	end)

	ConfirmBtn.MouseButton1Click:Connect(function()
		Apply()
		ClosePopup()
	end)

	CancelBtn.MouseButton1Click:Connect(function()
		ClosePopup()
	end)

	UserInputService.InputBegan:Connect(function(Input)
		if not Open then return end
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			local pos = Input.Position
			local pAbs = Popup.AbsolutePosition
			local pSize = Popup.AbsoluteSize
			local inPopup = pos.X >= pAbs.X and pos.X <= pAbs.X + pSize.X and pos.Y >= pAbs.Y and pos.Y <= pAbs.Y + pSize.Y
			local inBtn = pos.X >= ColorBtn.AbsolutePosition.X and pos.X <= ColorBtn.AbsolutePosition.X + ColorBtn.AbsoluteSize.X
				and pos.Y >= ColorBtn.AbsolutePosition.Y and pos.Y <= ColorBtn.AbsolutePosition.Y + ColorBtn.AbsoluteSize.Y
			if not inPopup and not inBtn then
				ClosePopup()
			end
		end
	end)

	local ColorPickerObject = {
		Name = BaseName,
		Text = Text,
		Value = Default,
		Transparency = TransparencyDefault,
		Holder = Holder,
		ColorBtn = ColorBtn,
		Popup = Popup,
		Visible = true,

		SetValue = function(self, Color, Transparency)
			self.Value = Color
			self.Transparency = Transparency or 0
			Alpha = self.Transparency
			SetFromRGB(Color.R, Color.G, Color.B)
			Apply()
		end,

		SetVisible = function(self, Visible)
			self.Visible = Visible
			self.Holder.Visible = Visible
			if not Visible then ClosePopup() end
		end,

		Destroy = function(self)
			self.Holder:Destroy()
			self.Popup:Destroy()
		end,
	}

	return ColorPickerObject
end

function Library:Window(info)
	info = info or {}
	info.Title = info.Title or "Uzi Library"
	info.Description = info.Description or info.Desc or "Library"
	info.Size = info.Size or UDim2.fromOffset(760, 450)
	info.Position = info.Position or UDim2.new(0.5, 0, 0.5, 0)
	info.SizeLocked = info.SizeLocked or false
	info.CornerRadius = info.CornerRadius or 24

	local MainColor = self:GetBetterColor(self.Scheme.BackgroundColor, -1)
	local SidebarColor = self.Scheme.BackgroundColor
	local ContentColor = self:GetBetterColor(self.Scheme.BackgroundColor, 1)

	self.ScreenGui = self:New("ScreenGui", {
		Name = "UziLibrary",
		DisplayOrder = 998,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = gethui(),
	})

	local ColorpickerFolder = Instance.new("Folder")
	ColorpickerFolder.Name = "Colorpicker"
	ColorpickerFolder.Parent = self.ScreenGui
	self.ColorpickerFolder = ColorpickerFolder

	local MainFrame = self:New("Frame", {
		Name = "MainFrame",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = MainColor,
		BackgroundTransparency = 0.15,
		Position = info.Position,
		Size = info.Size,
		ClipsDescendants = true,
		Parent = self.ScreenGui,
	})

	self:New("UICorner", {
		CornerRadius = UDim.new(0, info.CornerRadius),
		Parent = MainFrame,
	})

	self:New("UIStroke", {
		Color = "OutlineColor",
		Parent = MainFrame,
	})

	local MainScale = self:New("UIScale", {
		Name = "MainScale",
		Parent = MainFrame,
	})
	table.insert(self.Scales, MainScale)

	local TopBar = self:New("Frame", {
		Name = "TopBar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 48),
		Parent = MainFrame,
	})

	local TitleHolder = self:New("Frame", {
		Name = "TitleHolder",
		BackgroundTransparency = 1,
		Size = UDim2.new(0.5, 0, 1, 0),
		Parent = TopBar,
	})
	self:New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		Parent = TitleHolder,
	})
	self:New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		Parent = TitleHolder,
	})


	local TitleHolder = self:New("Frame", {
		Name = "TitleHolder",
		BackgroundTransparency = 1,
		Size = UDim2.new(0.5, 0, 1, 0),
		Parent = TopBar,
	})
	self:New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		Parent = TitleHolder,
	})
	self:New("UIPadding", {
		PaddingLeft = UDim.new(0, 16),
		Parent = TitleHolder,
	})

	if info.Icon then
		local IconData = self:GetCustomIcon(info.Icon)
		self:New("ImageLabel", {
			Name = "WindowIcon",
			Image = IconData and IconData.Url or "",
			ImageRectOffset = IconData and IconData.ImageRectOffset or Vector2.zero,
			ImageRectSize = IconData and IconData.ImageRectSize or Vector2.zero,
			ImageColor3 = "FontColor",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(26, 26),
			Parent = TitleHolder,
		})
	end

	local TextStack = self:New("Frame", {
		Name = "TextStack",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, info.Icon and -34 or 0, 1, 0),
		Parent = TitleHolder,
	})
	self:New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
		Parent = TextStack,
	})

	self:New("TextLabel", {
		Name = "WindowTitle",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = 0,
		Text = info.Title,
		TextSize = 16,
		TextColor3 = "FontColor",
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TextStack,
	})

	self:New("TextLabel", {
		Name = "WindowDescription",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		LayoutOrder = 1,
		Text = info.Description,
		TextSize = 12,
		TextColor3 = "FontColor",
		TextTransparency = 0.4,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TextStack,
	})

	local ButtonHolder = self:New("Frame", {
		Name = "TopBarButtonHolder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = TopBar,
	})
	self:New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		Parent = ButtonHolder,
	})

	local TopBarButtons = {}

	local SidebarWidth = 180
	local Sidebar = self:New("ScrollingFrame", {
		Name = "Sidebar",
		BackgroundColor3 = SidebarColor,
		Position = UDim2.fromOffset(0, 49),
		Size = UDim2.new(0, SidebarWidth, 1, -49),
		ScrollBarThickness = 0,
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = MainFrame,
	})
	self:New("UIListLayout", {
		Parent = Sidebar,
	})

	local ContentContainer = self:New("Frame", {
		Name = "ContentContainer",
		BackgroundColor3 = ContentColor,
		Position = UDim2.fromOffset(SidebarWidth + 1, 49),
		Size = UDim2.new(1, -(SidebarWidth + 1), 1, -49),
		BackgroundTransparency = 1,
		Parent = MainFrame,
	})
	self:New("UIPadding", {
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 6),
		Parent = ContentContainer,
	})

	if not info.SizeLocked then
		local ResizeButton = self:New("TextButton", {
			Name = "ResizeButton",
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -info.CornerRadius / 4, 0, 0),
			Size = UDim2.fromScale(1, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Text = "",
			Parent = MainFrame,
		})
		self:New("ImageLabel", {
			Name = "ResizeIcon",
			Image = "rbxassetid://6107172090",
			ImageColor3 = "FontColor",
			ImageTransparency = 0.5,
			Position = UDim2.fromOffset(2, 2),
			Size = UDim2.new(1, -4, 1, -4),
			Parent = ResizeButton,
		})
		self:MakeResizable(MainFrame, ResizeButton)
	end

	self:MakeDraggable(MainFrame, TopBar)

	function Library:CreateTopBarButton(ButtonHolder, Config)
		Config = Config or {}
		local Text = Config.Text or ""
		local Icon = Config.Icon
		local IconSize = Config.IconSize or 16
		local BtnType = Config.Type or "corner"
		local AlwaysShow = Config.AlwaysShow or false
		local HideBackground = Config.HideBackground or false
		local Callback = Config.Callback or function() end

		local BaseName = (Text ~= "" and Text or "Btn"):gsub("[^%w]", "")

		local CornerRadius = BtnType == "circle" and UDim.new(1, 0) or UDim.new(0, 6)
		local BtnSize = BtnType == "circle" and math.max(30, IconSize + 8) or math.max(28, IconSize + 8)

		local Holder = self:New("Frame", {
			Name = BaseName .. "TopBtnHolder",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(BtnSize, BtnSize),
			ClipsDescendants = true,
			Parent = ButtonHolder,
		})

		local Button = self:New("TextButton", {
			Name = BaseName .. "TopBtn",
			BackgroundColor3 = "MainColor",
			BackgroundTransparency = HideBackground and 1 or 0,
			Size = UDim2.fromOffset(BtnSize, BtnSize),
			Text = "",
			AutoButtonColor = false,
			Parent = Holder,
		})
		self:New("UICorner", {
			CornerRadius = CornerRadius,
			Parent = Button,
		})

		local IconLabel
		if Icon then
			local IconData = self:GetCustomIcon(Icon)
			IconLabel = self:New("ImageLabel", {
				Name = BaseName .. "TopBtnIcon",
				Image = IconData and IconData.Url or "",
				ImageRectOffset = IconData and IconData.ImageRectOffset or Vector2.zero,
				ImageRectSize = IconData and IconData.ImageRectSize or Vector2.zero,
				ImageColor3 = "FontColor",
				ImageTransparency = 0.4,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(IconSize, IconSize),
				Parent = Button,
			})
		end

		local TextLabel
		local TextWidth = 0
		if Text ~= "" then
			local EstWidth = math.min(#Text * 7 + 4, 120)
			TextLabel = self:New("TextLabel", {
				Name = BaseName .. "TopBtnText",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(BtnSize + 4, 0),
				Size = UDim2.new(0, EstWidth, 1, 0),
				Text = Text,
				TextSize = 12,
				TextTransparency = AlwaysShow and 0.3 or 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = Holder,
			})
			TextWidth = EstWidth
		end

		if AlwaysShow and TextLabel then
			local NewWidth = BtnSize + 4 + TextWidth + 4
			Holder.Size = UDim2.fromOffset(NewWidth, BtnSize)
		end

		local BtnObject = {
			Name = BaseName,
			Text = Text,
			Icon = Icon,
			IconSize = IconSize,
			Type = BtnType,
			AlwaysShow = AlwaysShow,
			HideBackground = HideBackground,
			Callback = Callback,
			Holder = Holder,
			Button = Button,
			IconLabel = IconLabel,
			TextLabel = TextLabel,
			Disabled = false,
			Visible = true,

			SetCallback = function(self, NewCallback)
				self.Callback = NewCallback
			end,

			SetVisible = function(self, Visible)
				self.Visible = Visible
				self.Holder.Visible = Visible
			end,

			SetDisabled = function(self, Disabled)
				self.Disabled = Disabled
				self.Button.Active = not Disabled
				if self.IconLabel then
					self.IconLabel.ImageTransparency = Disabled and 0.8 or 0.4
				end
			end,

			Destroy = function(self)
				self.Holder:Destroy()
			end,
		}

		if TextLabel and not AlwaysShow then
			Button.MouseEnter:Connect(function()
				if BtnObject.Disabled then return end
				local TW = TextLabel.TextBounds.X
				local NewWidth = BtnSize + 4 + TW + 4
				TweenService:Create(Holder, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.fromOffset(NewWidth, BtnSize),
				}):Play()
				TweenService:Create(TextLabel, TweenInfo.new(0.15), {
					TextTransparency = 0.3,
				}):Play()
				if IconLabel then
					TweenService:Create(IconLabel, TweenInfo.new(0.15), {
						ImageTransparency = 0,
					}):Play()
				end
			end)

			Button.MouseLeave:Connect(function()
				if BtnObject.Disabled then return end
				TweenService:Create(Holder, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.fromOffset(BtnSize, BtnSize),
				}):Play()
				TweenService:Create(TextLabel, TweenInfo.new(0.15), {
					TextTransparency = 1,
				}):Play()
				if IconLabel then
					TweenService:Create(IconLabel, TweenInfo.new(0.15), {
						ImageTransparency = 0.4,
					}):Play()
				end
			end)
		else
			-- Không text hoặc AlwaysShow: chỉ hover icon
			Button.MouseEnter:Connect(function()
				if BtnObject.Disabled then return end
				if IconLabel then
					TweenService:Create(IconLabel, TweenInfo.new(0.15), {
						ImageTransparency = 0,
					}):Play()
				end
			end)
			Button.MouseLeave:Connect(function()
				if BtnObject.Disabled then return end
				if IconLabel then
					TweenService:Create(IconLabel, TweenInfo.new(0.15), {
						ImageTransparency = 0.4,
					}):Play()
				end
			end)
		end

		Button.MouseButton1Click:Connect(function()
			if not BtnObject.Disabled then
				BtnObject:Callback()
			end
		end)

		return BtnObject
	end


	local ThemeOverlay = self:New("Frame", {
		Name = "ThemeOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = "DarkColor",
		BackgroundTransparency = 0.6,
		Visible = false,
		ZIndex = 90,
		Parent = self.ScreenGui,
	})

	local ThemePopup = self:New("Frame", {
		Name = "ThemePopup",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(400, 480),
		BackgroundColor3 = "BackgroundColor",
		BackgroundTransparency = 0.02,
		Visible = false,
		ZIndex = 1,
		Parent = self.ScreenGui,
	})
	self:New("UICorner", {CornerRadius = UDim.new(0, 16), Parent = ThemePopup})
	self:New("UIStroke", {Color = "OutlineColor", Parent = ThemePopup})
	local ThemeScale = self:New("UIScale", {Scale = self.DPIScale or 1, Parent = ThemePopup})
	table.insert(self.Scales, ThemeScale)

	local ThemeTopBar = self:New("Frame", {
		Name = "ThemeTopBar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 44),
		Parent = ThemePopup,
	})
	self:New("UIPadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		Parent = ThemeTopBar,
	})

	self:New("TextLabel", {
		Name = "ThemeTitle",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -40, 1, 0),
		Text = "Theme Settings",
		TextSize = 16,
		TextColor3 = "FontColor",
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = ThemeTopBar,
	})

	local CloseThemeBtn = self:New("TextButton", {
		Name = "CloseThemeBtn",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(28, 28),
		Text = "✕",
		TextColor3 = "FontColor",
		TextSize = 14,
		Parent = ThemeTopBar,
	})

	local ThemeScroll = self:New("ScrollingFrame", {
		Name = "ThemeScroll",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, 0, 1, -44),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = "OutlineColor",
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = ThemePopup,
	})
	self:New("UIPadding", {
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 8),
		Parent = ThemeScroll,
	})
	self:New("UIListLayout", {
		Padding = UDim.new(0, 10),
		Parent = ThemeScroll,
	})

	self:MakeDraggable(ThemePopup, ThemeTopBar)

	local SchemeKeys = {
		{"BackgroundColor", "Background"},
		{"MainColor", "Main"},
		{"AccentColor", "Accent"},
		{"OutlineColor", "Outline"},
		{"FontColor", "Font"},
		{"RedColor", "Red"},
		{"DestructiveColor", "Destructive"},
		{"DarkColor", "Dark"},
		{"WhiteColor", "White"},
	}

	for _, KeyData in ipairs(SchemeKeys) do
		local Key = KeyData[1]
		local Display = KeyData[2]
		self:CreateColorPicker(ThemeScroll, Display, {
			Text = Display,
			Default = self.Scheme[Key],
			Callback = function(Color, Alpha)
				self.Scheme[Key] = Color
				self:UpdateColors()
			end,
		})
	end

	CloseThemeBtn.MouseButton1Click:Connect(function()
		ThemePopup.Visible = false
		ThemeOverlay.Visible = false
	end)

	local WindowObject = {
		Name = info.Title,
		Type = "Window",
		Title = info.Title,
		Description = info.Description,
		MainFrame = MainFrame,
		Sidebar = Sidebar,
		ContentContainer = ContentContainer,
		Tabs = {},
		TabGroups = {},
		ActiveTab = nil,
		Visible = true,
		ScreenGui = self.ScreenGui,

		AddTabGroup = function(self, Title, Icon, Collapsed)
			local TabGroup = Library:CreateTabGroup(self.Sidebar, Title, Icon, Collapsed)
			TabGroup.ContentContainer = self.ContentContainer
			table.insert(self.TabGroups, TabGroup)
			return TabGroup
		end,

		AddTab = function(self, Name, Icon)
			local Tab = Library:CreateTab(self.Sidebar, self.ContentContainer, Name, Icon)
			table.insert(self.Tabs, Tab)
			if not self.ActiveTab then
				Tab:Show()
			end
			return Tab
		end,
		AddTopBarButton = function(self, Config)
			local Btn = Library:CreateTopBarButton(self.MainFrame.TopBar.TopBarButtonHolder, Config)
			table.insert(TopBarButtons, Btn)
			return Btn
		end,


		SetVisible = function(self, Visible)
			self.Visible = Visible
			self.MainFrame.Visible = Visible
		end,

		Toggle = function(self)
			self:SetVisible(not self.Visible)
		end,

		SetTitle = function(self, NewTitle)
			self.Title = NewTitle
			for _, Child in self.MainFrame:GetDescendants() do
				if Child:IsA("TextLabel") and Child.Name == "WindowTitle" then
					Child.Text = NewTitle
					break
				end
			end
		end,

		SetDescription = function(self, NewDesc)
			self.Description = NewDesc
			for _, Child in self.MainFrame:GetDescendants() do
				if Child:IsA("TextLabel") and Child.Name == "WindowDescription" then
					Child.Text = NewDesc
					break
				end
			end
		end,

		Destroy = function(self)
			self.MainFrame:Destroy()
			if self.ScreenGui then
				self.ScreenGui:Destroy()
			end
		end,

		SetDPI = function(self, Scale)
			Library.DPIScale = Scale
			local ActiveScales = {}
			for _, ScaleInstance in ipairs(Library.Scales) do
				if ScaleInstance and ScaleInstance.Parent then
					ScaleInstance.Scale = Scale
					table.insert(ActiveScales, ScaleInstance)
				end
			end
			Library.Scales = ActiveScales
		end,

		UIToggleButton = function(self, Config)
			Config = Config or {}
			local Icon = Config.Icon or "rbxassetid://101007429951147"
			local Position = Config.Position or UDim2.new(0.05, 0, 0.1, 0)
			local Size = Config.Size or UDim2.fromOffset(44, 44)

			local ToggleBtnGui = Library:New("ImageButton", {
				Name = "UIToggleButton",
				BackgroundColor3 = Library.Scheme.MainColor,
				Position = Position,
				Size = Size,
				Image = Icon,
				ImageColor3 = Library.Scheme.FontColor,
				Parent = self.ScreenGui,
			})
			Library:New("UICorner", {
				CornerRadius = UDim.new(0, 8),
				Parent = ToggleBtnGui,
			})
			Library:New("UIStroke", {
				Color = "OutlineColor",
				Parent = ToggleBtnGui,
			})

			Library:MakeDraggable(ToggleBtnGui, ToggleBtnGui)

			ToggleBtnGui.MouseEnter:Connect(function()
				TweenService:Create(ToggleBtnGui, TweenInfo.new(0.15), {
					ImageTransparency = 0.2,
				}):Play()
			end)
			ToggleBtnGui.MouseLeave:Connect(function()
				TweenService:Create(ToggleBtnGui, TweenInfo.new(0.15), {
					ImageTransparency = 0,
				}):Play()
			end)

			ToggleBtnGui.MouseButton1Click:Connect(function()
				self:Toggle()
			end)

			return ToggleBtnGui
		end,
	}

	function WindowObject:ToggleThemeUi()
		local state = not ThemePopup.Visible
		ThemePopup.Visible = state
		ThemeOverlay.Visible = state
	end

	function WindowObject:DraggableLabel(Config)
		Config = Config or {}
		local Text = Config.Text or "Label"
		local Size = Config.Size
		local AutoSize = Config.AutoSize or false
		local MaxWidth = Config.MaxWidth or 400
		local Padding = Config.Padding or {X = 24, Y = 14}
		local Position = Config.Position or UDim2.new(0.5, 0, 0, 10)
		local AnchorPoint = Config.AnchorPoint or Vector2.new(0.5, 0)
		local TextSize = Config.TextSize or 14
		local TextColor = Config.TextColor or "FontColor"
		local BackgroundColor = Config.BackgroundColor or "MainColor"
		local BackgroundTransparency = Config.BackgroundTransparency or 0.2
		local CornerRadius = Config.CornerRadius or 8
		local Name = Config.Name or "DraggableLabel"

		local Holder = Library:New("Frame", {
			Name = Name,
			AnchorPoint = AnchorPoint,
			Position = Position,
			BackgroundColor3 = BackgroundColor,
			BackgroundTransparency = BackgroundTransparency,
			ZIndex = 1,
			Parent = self.ScreenGui,
		})
		Library:New("UICorner", {
			CornerRadius = UDim.new(0, CornerRadius),
			Parent = Holder,
		})
		Library:New("UIStroke", {
			Color = "OutlineColor",
			Parent = Holder,
		})

		local Label = Library:New("TextLabel", {
			Name = "Text",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = Text,
			TextSize = TextSize,
			TextColor3 = TextColor,
			TextXAlignment = Config.TextXAlignment or Enum.TextXAlignment.Center,
			TextYAlignment = Config.TextYAlignment or Enum.TextYAlignment.Center,
			TextWrapped = true,
			Parent = Holder,
		})

		local function ComputeSize()
			local font = Enum.Font.Code
			local success, bounds = pcall(function()
				return TextService:GetTextSize(Label.Text, Label.TextSize, Label.FontFace, Vector2.new(MaxWidth, 9999))
			end)
			if not success then
				bounds = TextService:GetTextSize(Label.Text, Label.TextSize, font, Vector2.new(MaxWidth, 9999))
			end
			return UDim2.fromOffset(
				math.clamp(bounds.X + Padding.X, 40, MaxWidth + Padding.X),
				bounds.Y + Padding.Y
			)
		end

		if AutoSize then
			Holder.Size = Size or ComputeSize()
		else
			Holder.Size = Size or UDim2.fromOffset(200, 32)
		end

		Library:MakeDraggable(Holder, Holder)

		local Obj = {
			Holder = Holder,
			Label = Label,
			AutoSize = AutoSize,
			MaxWidth = MaxWidth,
			Padding = Padding,
			Visible = true,

			SetText = function(self, NewText)
				self.Label.Text = NewText
				if self.AutoSize then
					self.Holder.Size = ComputeSize()
				end
			end,

			SetVisible = function(self, State)
				self.Visible = State
				self.Holder.Visible = State
			end,

			SetSize = function(self, NewSize)
				self.Holder.Size = NewSize
				self.AutoSize = false
			end,

			SetPosition = function(self, NewPos)
				self.Holder.Position = NewPos
			end,

			SetTextSize = function(self, S)
				self.Label.TextSize = S
				if self.AutoSize then
					self:SetText(self.Label.Text)
				end
			end,

			SetTextColor = function(self, C)
				self.Label.TextColor3 = C
			end,

			SetTextXAlignment = function(self, Align)
				self.Label.TextXAlignment = Align
			end,

			SetBackgroundTransparency = function(self, T)
				self.Holder.BackgroundTransparency = T
			end,

			Destroy = function(self)
				self.Holder:Destroy()
			end,
		}

		return Obj
	end

	self.Window = WindowObject
	self.WindowContainer = ContentContainer
	return WindowObject
end


function Library:Notify(Config)
	Config = Config or {}
	local Title = Config.Title or "Notification"
	local Content = Config.Content or ""
	local Icon = Config.Icon
	local Duration = Config.Duration or 3
	local RichText = Config.RichText ~= false
	local Type = Config.Type or 1
	local Pos = Config.Pos or (Type == 1 and "right" or "top-center")
	Pos = Pos:lower():gsub("%s+", "")

	if not self.NotificationFolder then
		local folder = (self.ScreenGui and self.ScreenGui:FindFirstChild("Notification")) or Instance.new("Folder")
		folder.Name = "Notification"
		folder.Parent = self.ScreenGui or gethui()
		self.NotificationFolder = folder
	end

	local Parent = self.NotificationFolder

	local IsMobile = self.IsMobile or false
	local NotifWidth = IsMobile and 250 or 320

	if not self.NotifyContainers then
		self.NotifyContainers = {}
		local function MakeContainer(name, anchor, pos, fillDir, hAlign, vAlign)
			local F = Instance.new("Frame")
			F.Name = name
			F.BackgroundTransparency = 1
			F.AnchorPoint = anchor
			F.Position = pos
			F.Size = UDim2.new(0, NotifWidth, 1, 0)
			F.ZIndex = 1000
			F.Parent = Parent
			local L = Instance.new("UIListLayout")
			L.FillDirection = fillDir
			L.HorizontalAlignment = hAlign
			L.VerticalAlignment = vAlign
			L.Padding = UDim.new(0, 8)
			L.Parent = F
			return F
		end
		self.NotifyContainers.Right = MakeContainer("RightNotif", Vector2.new(1, 0), UDim2.new(1, -20, 0, 20), Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Top)
		self.NotifyContainers.Left = MakeContainer("LeftNotif", Vector2.new(0, 0), UDim2.new(0, 20, 0, 20), Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)
		self.NotifyContainers.TopCenter = MakeContainer("TopCenterNotif", Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 20), Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)
		self.NotifyContainers.BottomCenter = MakeContainer("BottomCenterNotif", Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -20), Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Bottom)
	else
		-- Ensure container width stays updated if size constraints changed
		for _, container in pairs(self.NotifyContainers) do
			container.Size = UDim2.new(0, NotifWidth, 1, 0)
		end
	end

	local Container
	if Pos == "left" or Pos == "topleft" then
		Container = self.NotifyContainers.Left
	elseif Pos == "right" or Pos == "topright" then
		Container = self.NotifyContainers.Right
	elseif Pos == "top-center" or Pos == "topcenter" then
		Container = self.NotifyContainers.TopCenter
	elseif Pos == "bottom-center" or Pos == "bottomcenter" then
		Container = self.NotifyContainers.BottomCenter
	else
		Container = self.NotifyContainers.Right
	end

	local Height = Type == 1 and (IsMobile and 54 or 64) or (IsMobile and 38 or 44)
	local NotifyFrame = self:New("Frame", {
		Name = "Notify",
		BackgroundColor3 = "BackgroundColor",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Height),
		ZIndex = 1001,
		Parent = Container,
	})
	self:New("UICorner", {CornerRadius = UDim.new(0, 8), Parent = NotifyFrame})
	self:New("UIStroke", {Color = "OutlineColor", Parent = NotifyFrame})
	self:New("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 24), 
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		Parent = NotifyFrame,
	})

	local IconSize = Type == 1 and (IsMobile and 22 or 28) or (IsMobile and 16 or 22)
	local IconOffset = Icon and (IconSize + 8) or 0

	if Icon then
		local IconData = self:GetCustomIcon(Icon)
		self:New("ImageLabel", {
			Name = "NotifyIcon",
			Image = IconData and IconData.Url or "",
			ImageRectOffset = IconData and IconData.ImageRectOffset or Vector2.zero,
			ImageRectSize = IconData and IconData.ImageRectSize or Vector2.zero,
			ImageColor3 = "FontColor",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(IconSize, IconSize),
			Position = UDim2.fromOffset(0, Type == 1 and (IsMobile and 6 or 4) or (IsMobile and 3 or 2)),
			ZIndex = 1002,
			Parent = NotifyFrame,
		})
	end

	local TitleSize = IsMobile and 12 or 14
	local ContentSize = IsMobile and 10 or 12

	if Type == 1 then
		self:New("TextLabel", {
			Name = "NotifyTitle",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(IconOffset, 0),
			Size = UDim2.new(1, -IconOffset, 0, IsMobile and 15 or 18),
			Text = Title,
			TextSize = TitleSize,
			TextColor3 = "FontColor",
			TextXAlignment = Enum.TextXAlignment.Left,
			RichText = RichText,
			ZIndex = 1002,
			Parent = NotifyFrame,
		})
		self:New("TextLabel", {
			Name = "NotifyContent",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(IconOffset, IsMobile and 16 or 20),
			Size = UDim2.new(1, -IconOffset, 1, IsMobile and -16 or -20),
			Text = Content,
			TextSize = ContentSize,
			TextColor3 = "FontColor",
			TextTransparency = 0.35,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			RichText = RichText,
			ZIndex = 1002,
			Parent = NotifyFrame,
		})
	else
		self:New("TextLabel", {
			Name = "NotifyContent",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(IconOffset, 0),
			Size = UDim2.new(1, -IconOffset, 1, 0),
			Text = Content,
			TextSize = IsMobile and 11 or 13,
			TextColor3 = "FontColor",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			RichText = RichText,
			ZIndex = 1002,
			Parent = NotifyFrame,
		})
	end

	local DismissBtn = self:New("ImageButton", {
		Name = "DismissBtn",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 16, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),

		Image = "rbxassetid://116396312853810",
		ImageColor3 = "FontColor",
		ImageTransparency = 0.5,

		AutoButtonColor = false,
		ZIndex = 1003,
		Parent = NotifyFrame,
	})

	local dismissed = false
	local function Dismiss()
		if dismissed then return end
		dismissed = true
		local T = TweenService:Create(NotifyFrame, TweenInfo.new(0.2), {BackgroundTransparency = 1})
		T:Play()
		for _, child in ipairs(NotifyFrame:GetDescendants()) do
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				TweenService:Create(child, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
			end
			if child:IsA("ImageLabel") or child:IsA("ImageButton") then
				TweenService:Create(child, TweenInfo.new(0.2), {ImageTransparency = 1}):Play()
			end
			if child:IsA("Frame") and child ~= NotifyFrame then
				TweenService:Create(child, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
			end
		end
		T.Completed:Wait()
		NotifyFrame:Destroy()
	end

	DismissBtn.MouseButton1Click:Connect(Dismiss)

	TweenService:Create(NotifyFrame, TweenInfo.new(0.25), {BackgroundTransparency = 0.05}):Play()
	for _, child in ipairs(NotifyFrame:GetDescendants()) do
		if child:IsA("TextLabel") then
			TweenService:Create(child, TweenInfo.new(0.25), {TextTransparency = child.Name == "NotifyContent" and 0.35 or 0}):Play()
		elseif child:IsA("ImageLabel") then
			TweenService:Create(child, TweenInfo.new(0.25), {ImageTransparency = 0}):Play()
		end
	end

	task.delay(Duration, function()
		if not dismissed then
			Dismiss()
		end
	end)
end

return Library
