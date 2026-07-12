local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local CardLib = {}
CardLib.__index = CardLib

local Card = {}
Card.__index = Card

local TextOption = {}
TextOption.__index = TextOption

local ButtonOption = {}
ButtonOption.__index = ButtonOption

local ParagraphOption = {}
ParagraphOption.__index = ParagraphOption

local function resolvePosition(pos, size, offset)
	offset = offset or 20
	if typeof(pos) == "UDim2" then
		return pos
	end

	local w, h = size.X.Offset, size.Y.Offset
	local presets = {
		Center = UDim2.new(0.5, -w / 2, 0.5, -h / 2),
		TopLeft = UDim2.new(0, offset, 0, offset),
		TopRight = UDim2.new(1, -w - offset, 0, offset),
		BottomLeft = UDim2.new(0, offset, 1, -h - offset),
		BottomRight = UDim2.new(1, -w - offset, 1, -h - offset),
		Top = UDim2.new(0.5, -w / 2, 0, offset),
		Bottom = UDim2.new(0.5, -w / 2, 1, -h - offset),
		Left = UDim2.new(0, offset, 0.5, -h / 2),
		Right = UDim2.new(1, -w - offset, 0.5, -h / 2),
	}

	return presets[pos] or presets.Center
end

local function createMacButton(parent, color, hoverColor, xPos, onClick)
	local button = Instance.new("ImageButton")
	button.Name = "MacButton"
	button.Parent = parent
	button.Size = UDim2.new(0, 13, 0, 13)
	button.Position = UDim2.new(0, xPos, 0.5, -6.5)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.ZIndex = 8
	button.Image = "rbxasset://textures/ui/Button/Default.png"
	button.ImageTransparency = 1

	local corner = Instance.new("UICorner", button)
	corner.CornerRadius = UDim.new(1, 0)

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundColor3 = hoverColor,
		}):Play()
		TweenService:Create(button, TweenInfo.new(0.15), {
			Size = UDim2.new(0, 15, 0, 15),
			Position = UDim2.new(0, xPos - 1, 0.5, -7.5),
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {
			BackgroundColor3 = color,
		}):Play()
		TweenService:Create(button, TweenInfo.new(0.15), {
			Size = UDim2.new(0, 13, 0, 13),
			Position = UDim2.new(0, xPos, 0.5, -6.5),
		}):Play()
	end)

	if onClick then
		button.MouseButton1Click:Connect(onClick)
	end

	return button
end


function TextOption.new(label, container)
	local self = setmetatable({}, TextOption)
	self.Label = label
	self.Container = container
	return self
end

function TextOption:SetText(text)
	self.Label.Text = text
end

function TextOption:SetVisible(visible)
	self.Label.Visible = visible
end

function TextOption:SetColor(color3)
	self.Label.TextColor3 = color3
end

function TextOption:SetPosition(udim2)
	self.Label.Position = udim2
end

function TextOption:SetSize(udim2)
	self.Label.Size = udim2
end

function TextOption:SetWrap(wrap)
	self.Label.TextWrapped = wrap
end

function TextOption:Remove()
	self.Label:Destroy()
end


function ParagraphOption.new(holder, titleLabel, bodyLabel)
	local self = setmetatable({}, ParagraphOption)
	self.Holder = holder
	self.TitleLabel = titleLabel
	self.BodyLabel = bodyLabel
	return self
end

function ParagraphOption:SetTitle(text)
	self.TitleLabel.Text = text
end

function ParagraphOption:SetText(text)
	self.BodyLabel.Text = text
end

function ParagraphOption:SetVisible(visible)
	self.Holder.Visible = visible
end

function ParagraphOption:SetColor(color3)
	self.BodyLabel.TextColor3 = color3
end

function ParagraphOption:SetTitleColor(color3)
	self.TitleLabel.TextColor3 = color3
end

function ParagraphOption:SetPosition(udim2)
	self.Holder.Position = udim2
end

function ParagraphOption:SetSize(udim2)
	self.Holder.Size = udim2
end

function ParagraphOption:Remove()
	self.Holder:Destroy()
end


function ButtonOption.new(button, label)
	local self = setmetatable({}, ButtonOption)
	self.Button = button
	self.Label = label
	self._conns = {}
	return self
end

function ButtonOption:SetText(text)
	self.Label.Text = text
end

function ButtonOption:SetVisible(visible)
	self.Button.Visible = visible
end

function ButtonOption:SetPosition(udim2)
	self.Button.Position = udim2
end

function ButtonOption:SetSize(udim2)
	self.Button.Size = udim2
end

function ButtonOption:SetEnabled(enabled)
	self.Button.Active = enabled
	self.Button.AutoButtonColor = false
	TweenService:Create(self.Label, TweenInfo.new(0.15), {
		TextTransparency = enabled and 0 or 0.5,
	}):Play()
end

function ButtonOption:OnClick(callback)
	local conn = self.Button.MouseButton1Click:Connect(callback)
	table.insert(self._conns, conn)
	return conn
end

function ButtonOption:Remove()
	for _, conn in ipairs(self._conns) do
		conn:Disconnect()
	end
	self.Button:Destroy()
end


function Card.new(parent, config)
	config = config or {}
	local size = config.Size or UDim2.new(0, 300, 0, 200)
	local position = resolvePosition(config.Position, size, config.Offset)

	local self = setmetatable({}, Card)
	self.Options = {}
	self._conns = {}
	self.IsMinimized = false
	self.IsMaximized = false
	self.OriginalSize = size
	self.OriginalPosition = position

	local Holder = Instance.new("Frame")
	Holder.Name = "GridCard"
	Holder.Parent = parent
	Holder.Size = size
	Holder.Position = position
	Holder.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
	Holder.BorderSizePixel = 0
	Holder.ClipsDescendants = false
	Holder.ZIndex = 10

	local Corner = Instance.new("UICorner", Holder)
	Corner.CornerRadius = UDim.new(0, 16)

	local Gradient = Instance.new("Frame")
	Gradient.Name = "GradientBackground"
	Gradient.Parent = Holder
	Gradient.Size = UDim2.new(1, 0, 1, 0)
	Gradient.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
	Gradient.ZIndex = 1

	local gradCorner = Instance.new("UICorner", Gradient)
	gradCorner.CornerRadius = UDim.new(0, 16)

	local UIGradient = Instance.new("UIGradient")
	UIGradient.Parent = Gradient
	UIGradient.Rotation = 45
	UIGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 25)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(45, 45, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 70, 75)),
	})

	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Parent = Holder
	TopBar.Size = UDim2.new(1, 0, 0, 32)
	TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
	TopBar.BackgroundTransparency = 0
	TopBar.ZIndex = 5
	TopBar.BorderSizePixel = 0

	local topBarCorner = Instance.new("UICorner", TopBar)
	topBarCorner.CornerRadius = UDim.new(0, 16)

	local TopBarFiller = Instance.new("Frame")
	TopBarFiller.Name = "TopBarFiller"
	TopBarFiller.Parent = Holder
	TopBarFiller.Size = UDim2.new(1, 0, 0, 16)
	TopBarFiller.Position = UDim2.new(0, 0, 0, 16)
	TopBarFiller.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
	TopBarFiller.BackgroundTransparency = 0
	TopBarFiller.BorderSizePixel = 0
	TopBarFiller.ZIndex = 4

	local SeparatorLine = Instance.new("Frame")
	SeparatorLine.Name = "SeparatorLine"
	SeparatorLine.Parent = TopBar
	SeparatorLine.Size = UDim2.new(1, 0, 0, 1)
	SeparatorLine.Position = UDim2.new(0, 0, 1, -1)
	SeparatorLine.BackgroundColor3 = Color3.fromRGB(40, 40, 42)
	SeparatorLine.BackgroundTransparency = 0
	SeparatorLine.BorderSizePixel = 0
	SeparatorLine.ZIndex = 5

	local ButtonContainer = Instance.new("Frame")
	ButtonContainer.Name = "ButtonContainer"
	ButtonContainer.Parent = TopBar
	ButtonContainer.Size = UDim2.new(0, 70, 1, 0)
	ButtonContainer.Position = UDim2.new(0, 12, 0, 0)
	ButtonContainer.BackgroundTransparency = 1
	ButtonContainer.ZIndex = 7

	local Shadow = Instance.new("ImageLabel")
	Shadow.Name = "Shadow"
	Shadow.Parent = Holder
	Shadow.BackgroundTransparency = 1
	Shadow.Position = UDim2.new(0, -20, 0, -20)
	Shadow.Size = UDim2.new(1, 40, 1, 40)
	Shadow.Image = "rbxassetid://88645182616510"
	Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	Shadow.ImageTransparency = 0.4
	Shadow.ZIndex = 0
	Shadow.Active = false
	Shadow.Selectable = false

	local closeBtn = createMacButton(ButtonContainer, Color3.fromRGB(255, 95, 87), Color3.fromRGB(255, 60, 50), 0, function()
		self:Destroy()
	end)

	local minimizeBtn = createMacButton(ButtonContainer, Color3.fromRGB(255, 189, 46), Color3.fromRGB(255, 210, 30), 18, function()
		self:Minimize()
	end)

	local maximizeBtn = createMacButton(ButtonContainer, Color3.fromRGB(39, 201, 63), Color3.fromRGB(20, 220, 50), 36, function()
		self:Maximize()
	end)

	local Content = Instance.new("Frame")
	Content.Name = "Content"
	Content.Parent = Holder
	Content.Size = UDim2.new(1, 0, 1, -32)
	Content.Position = UDim2.new(0, 0, 0, 32)
	Content.BackgroundTransparency = 1
	Content.ZIndex = 3
	Content.ClipsDescendants = true

	self.Holder = Holder
	self.Content = Content
	self._size = size
	self._position = position
	self.TopBar = TopBar
	self.ButtonContainer = ButtonContainer
	self._parent = parent
	self.UIGradient = UIGradient
	self.Gradient = Gradient

	local isDragging = false
	local dragOffset = nil
	local isHovered = false
	local isVisible = true

	local function fadeUI(transparency)
		TweenService:Create(Holder, TweenInfo.new(0.5), { BackgroundTransparency = transparency }):Play()
		TweenService:Create(Gradient, TweenInfo.new(0.5), { BackgroundTransparency = transparency }):Play()
	end

	local startTime = tick()
	table.insert(self._conns, RunService.RenderStepped:Connect(function()
		local elapsed = (tick() - startTime) % 2
		UIGradient.Offset = Vector2.new(elapsed / 2, 0)
	end))

	table.insert(self._conns, Holder.MouseEnter:Connect(function()
		if not isVisible or self.IsMinimized then return end
		isHovered = true
		fadeUI(0)
		if not self.IsMaximized then
			TweenService:Create(Holder, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(size.X.Scale * 1.05, size.X.Offset * 1.05, size.Y.Scale * 1.05, size.Y.Offset * 1.05),
			}):Play()
		end
	end))

	table.insert(self._conns, Holder.MouseLeave:Connect(function()
		if not isVisible or self.IsMinimized then return end
		isHovered = false
		fadeUI(0.7)
		if not self.IsMaximized then
			TweenService:Create(Holder, TweenInfo.new(0.3), { Size = size }):Play()
		end
	end))

	local function startDrag(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if self.IsMinimized or self.IsMaximized then return end
			isDragging = true
			fadeUI(0)
			local inputPos = Vector2.new(input.Position.X, input.Position.Y)
			local holderPos = Vector2.new(Holder.AbsolutePosition.X, Holder.AbsolutePosition.Y)
			dragOffset = inputPos - holderPos
		end
	end

	table.insert(self._conns, TopBar.InputBegan:Connect(startDrag))

	table.insert(self._conns, Holder.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and isDragging and dragOffset then
			local inputPos = Vector2.new(input.Position.X, input.Position.Y)
			local newPos = inputPos - dragOffset
			local viewportSize = parent.AbsoluteSize or Vector2.new(1920, 1080)
			newPos = Vector2.new(
				math.clamp(newPos.X, 0, viewportSize.X - Holder.AbsoluteSize.X),
				math.clamp(newPos.Y, 0, viewportSize.Y - Holder.AbsoluteSize.Y)
			)
			Holder.Position = UDim2.new(0, newPos.X, 0, newPos.Y)
		end
	end))

	table.insert(self._conns, Holder.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = false
			dragOffset = nil
			if not self.IsMaximized and not self.IsMinimized then
				TweenService:Create(Holder, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = size,
				}):Play()
			end
			if not isHovered and not self.IsMinimized then
				fadeUI(0.7)
			end
		end
	end))

	return self
end

function Card:Minimize()
	if self.IsMinimized then
		self.IsMinimized = false
		self.Holder.Visible = true
		TweenService:Create(self.Holder, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = self.OriginalSize,
			Position = self.OriginalPosition,
		}):Play()
	else
		self.IsMinimized = true
		TweenService:Create(self.Holder, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 1, -20),
		}):Play()
		task.delay(0.3, function()
			self.Holder.Visible = false
		end)
	end
end

function Card:Maximize()
	if self.IsMaximized then
		self.IsMaximized = false
		TweenService:Create(self.Holder, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = self.OriginalSize,
			Position = self.OriginalPosition,
		}):Play()
	else
		self.IsMaximized = true
		local viewportSize = self._parent.AbsoluteSize or Vector2.new(1920, 1080)
		local pad = 20
		TweenService:Create(self.Holder, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, viewportSize.X - pad * 2, 0, viewportSize.Y - pad * 2),
			Position = UDim2.new(0, pad, 0, pad),
		}):Play()
	end
end

function Card:AddText(idx, config)
	config = config or {}

	local Label = Instance.new("TextLabel")
	Label.Name = "Text_" .. tostring(idx)
	Label.Parent = self.Content
	Label.BackgroundTransparency = 1
	Label.Size = config.Size or UDim2.new(1, -20, 0, 24)
	Label.Position = config.Position or UDim2.new(0, 10, 0, 10)
	Label.Text = config.Text or ""
	Label.TextWrapped = config.Wrap or false
	Label.TextColor3 = config.Color or Color3.fromRGB(255, 255, 255)
	Label.Font = config.Font or Enum.Font.Gotham
	Label.TextSize = config.TextSize or 16
	Label.TextXAlignment = config.TextXAlignment or Enum.TextXAlignment.Left
	Label.TextYAlignment = config.TextYAlignment or Enum.TextYAlignment.Top
	Label.RichText = true
	Label.ZIndex = 3

	local option = TextOption.new(Label, self.Content)
	self.Options[idx] = option
	return option
end

function Card:AddParagraph(idx, config)
	config = config or {}

	local Holder = Instance.new("Frame")
	Holder.Name = "Paragraph_" .. tostring(idx)
	Holder.Parent = self.Content
	Holder.BackgroundTransparency = 1
	Holder.Size = config.Size or UDim2.new(1, -20, 0, 60)
	Holder.Position = config.Position or UDim2.new(0, 10, 0, 10)
	Holder.ZIndex = 3

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Name = "Title"
	TitleLabel.Parent = Holder
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Size = UDim2.new(1, 0, 0, config.Title and 18 or 0)
	TitleLabel.Position = UDim2.new(0, 0, 0, 0)
	TitleLabel.Visible = config.Title ~= nil
	TitleLabel.Text = config.Title or ""
	TitleLabel.TextColor3 = config.TitleColor or Color3.fromRGB(255, 255, 255)
	TitleLabel.Font = config.TitleFont or Enum.Font.GothamBold
	TitleLabel.TextSize = config.TitleTextSize or 15
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.TextYAlignment = Enum.TextYAlignment.Top
	TitleLabel.ZIndex = 3

	local BodyLabel = Instance.new("TextLabel")
	BodyLabel.Name = "Body"
	BodyLabel.Parent = Holder
	BodyLabel.BackgroundTransparency = 1
	BodyLabel.Size = UDim2.new(1, 0, 1, config.Title and -20 or 0)
	BodyLabel.Position = UDim2.new(0, 0, 0, config.Title and 20 or 0)
	BodyLabel.Text = config.Text or ""
	BodyLabel.TextWrapped = true
	BodyLabel.TextColor3 = config.Color or Color3.fromRGB(200, 200, 205)
	BodyLabel.Font = config.Font or Enum.Font.Gotham
	BodyLabel.TextSize = config.TextSize or 14
	BodyLabel.TextXAlignment = Enum.TextXAlignment.Left
	BodyLabel.TextYAlignment = Enum.TextYAlignment.Top
	BodyLabel.RichText = true
	BodyLabel.ZIndex = 3

	local option = ParagraphOption.new(Holder, TitleLabel, BodyLabel)
	self.Options[idx] = option
	return option
end

function Card:AddButton(idx, config)
	config = config or {}

	local baseColor = config.Color or Color3.fromRGB(45, 45, 50)
	local hoverColor = config.HoverColor or Color3.fromRGB(60, 60, 66)

	local Button = Instance.new("TextButton")
	Button.Name = "Button_" .. tostring(idx)
	Button.Parent = self.Content
	Button.Size = config.Size or UDim2.new(1, -20, 0, 32)
	Button.Position = config.Position or UDim2.new(0, 10, 0, 10)
	Button.BackgroundColor3 = baseColor
	Button.BorderSizePixel = 0
	Button.AutoButtonColor = false
	Button.Text = ""
	Button.ZIndex = 3

	local corner = Instance.new("UICorner", Button)
	corner.CornerRadius = UDim.new(0, 10)

	local stroke = Instance.new("UIStroke", Button)
	stroke.Color = Color3.fromRGB(70, 70, 75)
	stroke.Thickness = 1
	stroke.Transparency = 0.5

	local Label = Instance.new("TextLabel")
	Label.Name = "Label"
	Label.Parent = Button
	Label.BackgroundTransparency = 1
	Label.Size = UDim2.new(1, 0, 1, 0)
	Label.Text = config.Text or "Button"
	Label.TextColor3 = config.TextColor or Color3.fromRGB(255, 255, 255)
	Label.Font = config.Font or Enum.Font.GothamMedium
	Label.TextSize = config.TextSize or 15
	Label.TextXAlignment = Enum.TextXAlignment.Center
	Label.TextYAlignment = Enum.TextYAlignment.Center
	Label.ZIndex = 4

	Button.MouseEnter:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.15), { BackgroundColor3 = hoverColor }):Play()
	end)

	Button.MouseLeave:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.15), { BackgroundColor3 = baseColor }):Play()
	end)

	Button.MouseButton1Down:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.1), {
			Size = UDim2.new(
				Button.Size.X.Scale, Button.Size.X.Offset - 4,
				Button.Size.Y.Scale, Button.Size.Y.Offset - 2
			),
		}):Play()
	end)

	Button.MouseButton1Up:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.1), {
			Size = config.Size or UDim2.new(1, -20, 0, 32),
		}):Play()
	end)

	local option = ButtonOption.new(Button, Label)
	if config.OnClick then
		option:OnClick(config.OnClick)
	end
	self.Options[idx] = option
	return option
end

function Card:Destroy()
	for _, conn in ipairs(self._conns) do
		conn:Disconnect()
	end
	self.Holder:Destroy()
end

function CardLib:MakeCard(config)
	config = config or {}
	local parent = config.Parent

	if not parent then
		local player = Players.LocalPlayer
		if not player then return nil end

		local playerGui = player:WaitForChild("PlayerGui")

		local existing = playerGui:FindFirstChild("CardLibGui")
		if existing then
			existing:Destroy()
		end

		local ScreenGui = Instance.new("ScreenGui")
		ScreenGui.Name = "CardLibGui"
		ScreenGui.ResetOnSpawn = false
		ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		ScreenGui.Parent = playerGui
		parent = ScreenGui
	end

	return Card.new(parent, config)
end

return CardLib
