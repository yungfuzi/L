local Library = {
	Version = "2.12.2",
	Flags = {},
	Windows = {},
	Notifications = {},
	ActiveTheme = "macOS Dark",
	DPI = 1,
}
Library.__index = Library

local Section
local Tab
local Window

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local GuiService        = game:GetService("GuiService")
local TextService       = game:GetService("TextService")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local HttpService       = game:GetService("HttpService")

local function SafeParent()
	local ok, hui = pcall(function()
		if typeof(gethui) == "function" then
			return gethui()
		end
		return nil
	end)
	if ok and hui then
		return hui
	end

	local player = Players.LocalPlayer
	if not player then
		local okWait, result = pcall(function()
			return Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
		end)
		if okWait then
			player = result
		end
	end

	if player then
		local pg = player:FindFirstChildOfClass("PlayerGui")
		if not pg then
			local okPg, waited = pcall(function()
				return player:WaitForChild("PlayerGui", 5)
			end)
			if okPg then
				pg = waited
			end
		end
		if pg then
			return pg
		end
	end

	local okCore, core = pcall(function()
		return CoreGui
	end)
	if okCore and core then
		return core
	end

	return nil
end

local function SafeProtect(gui)
	pcall(function()
		if typeof(protectgui) == "function" then
			protectgui(gui)
		elseif syn and type(syn) == "table" and syn.protect_gui then
			syn.protect_gui(gui)
		end
	end)
end


export type ThemeTokens = {
	Background: Color3,
	Surface: Color3,
	SurfaceSecondary: Color3,
	SurfaceTertiary: Color3,
	Border: Color3,
	BorderHover: Color3,
	Text: Color3,
	TextSecondary: Color3,
	TextTertiary: Color3,
	Accent: Color3,
	AccentHover: Color3,
	AccentPressed: Color3,
	Success: Color3,
	Warning: Color3,
	Danger: Color3,
	Shadow: Color3,
	Overlay: Color3,
}

export type WindowConfig = {
	Title: string?,
	Subtitle: string?,
	Size: UDim2?,
	MinSize: Vector2?,
	MaxSize: Vector2?,
	Theme: (string | ThemeTokens)?,
	Acrylic: boolean?,
	Resizable: boolean?,
	Draggable: boolean?,
	Center: boolean?,
	Icon: string?,
	CompactTab: boolean?,
	ElementsRow: {
		Enabled: boolean?,
		Type: string?,
	}?,
}

export type SectionConfig = {
	Name: string?,
	Type: ("full" | "left" | "right")?,
	Collapse: {
		Enabled: boolean?,
		Default: boolean?,
	}?,
}

export type ToggleConfig = {
	Name: string,
	Description: string?,
	Flag: string?,
	Default: boolean?,
	Tooltip: string?,
	Callback: ((value: boolean) -> ())?,
}

export type SliderConfig = {
	Name: string,
	Description: string?,
	Flag: string?,
	Min: number?,
	Max: number?,
	Default: number?,
	Rounding: number?,
	Suffix: string?,
	Tooltip: string?,
	Callback: ((value: number) -> ())?,
}

export type DropdownConfig = {
	Name: string,
	Description: string?,
	Flag: string?,
	Values: {string}?,
	Default: (string | {string})?,
	Multi: boolean?,
	Searchable: boolean?,
	Tooltip: string?,
	Callback: ((value: any) -> ())?,
}

export type InputConfig = {
	Name: string,
	Description: string?,
	Flag: string?,
	Placeholder: string?,
	Default: string?,
	ClearTextOnFocus: boolean?,
	Numeric: boolean?,
	Tooltip: string?,
	Callback: ((value: string) -> ())?,
}

export type KeybindConfig = {
	Name: string,
	Description: string?,
	Flag: string?,
	Default: (Enum.KeyCode | Enum.UserInputType)?,
	Mode: ("Toggle" | "Hold" | "Always")?,
	Tooltip: string?,
	Callback: ((key: Enum.KeyCode | Enum.UserInputType, active: boolean?) -> ())?,
}

export type ButtonConfig = {
	Name: string,
	Description: string?,
	Icon: string?,
	Tooltip: string?,
	Color: Color3?,
	Disabled: boolean?,
	Callback: (() -> ())?,
}

export type ColorPickerConfig = {
	Name: string,
	Flag: string?,
	Default: Color3?,
	Alpha: number?,
	Tooltip: string?,
	Callback: ((color: Color3, alpha: number) -> ())?,
}


local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local FONT_SEMIBOLD = Enum.Font.GothamSemibold

local DEFAULT_CORNER = 10
local SIDEBAR_WIDTH = 150
local HEADER_HEIGHT = 48
local ROW_HEIGHT = 36
local SECTION_GAP = 12


local Utility = {}

function Utility.SafeCallback(fn, ...)
	if type(fn) ~= "function" then return end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[Library] Callback error:", err)
	end
end

function Utility.DeepCopy(t)
	if type(t) ~= "table" then return t end
	local n = {}
	for k, v in pairs(t) do
		n[k] = Utility.DeepCopy(v)
	end
	return n
end

function Utility.Round(n: number, places: number?)
	places = places or 0
	local m = 10 ^ places
	return math.floor(n * m + 0.5) / m
end

function Utility.Clamp(n: number, min: number, max: number)
	return math.clamp(n, min, max)
end

function Utility.IsMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function Utility.GetTextBounds(text: string, font: Enum.Font, size: number, width: number?)
	local ok, bounds = pcall(function()
		local params = Instance.new("GetTextBoundsParams")
		params.Text = text or ""
		params.Font = Font.fromEnum(font)
		params.Size = size
		params.Width = width or 0
		local b = TextService:GetTextBoundsAsync(params)
		params:Destroy()
		return b
	end)
	if ok and bounds then
		return bounds
	end
	return Vector2.new(#(text or "") * (size * 0.5), size + 4)
end

function Utility.Create(class: string, props: {[string]: any}?, children: {Instance}?)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then
				inst[k] = v
			end
		end
		if props.Parent then
			inst.Parent = props.Parent
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	return inst
end


function Utility.AddShadow(parent: Instance, opts: {
	BlurRadius: number?,
	Color: Color3?,
	Offset: UDim2?,
	Spread: UDim2?,
	Transparency: number?,
	ZIndex: number?,
	}?)
	opts = opts or {}
	local ok, shadow = pcall(function()
		local s = Instance.new("UIShadow")
		s.BlurRadius = UDim.new(0, opts.BlurRadius or 12)
		s.Color = opts.Color or Color3.new(0, 0, 0)
		s.Offset = opts.Offset or UDim2.fromOffset(0, 4)
		s.Spread = opts.Spread or UDim2.fromOffset(0, 0)
		s.Transparency = opts.Transparency or 0.55
		s.ZIndex = opts.ZIndex or 0
		s.Enabled = true
		s.Parent = parent
		return s
	end)
	if ok then
		return shadow
	end

	return nil
end


local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _connections = {}, _destroyed = false }, Signal)
end

function Signal:Connect(fn)
	if self._destroyed then return { Disconnect = function() end } end
	local conn = { Connected = true, _fn = fn, _signal = self }
	function conn:Disconnect()
		if not self.Connected then return end
		self.Connected = false
		local idx = table.find(self._signal._connections, self)
		if idx then table.remove(self._signal._connections, idx) end
	end
	table.insert(self._connections, conn)
	return conn
end

function Signal:Fire(...)
	if self._destroyed then return end
	for _, conn in ipairs(table.clone(self._connections)) do
		if conn.Connected then
			task.spawn(conn._fn, ...)
		end
	end
end

function Signal:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	for _, conn in ipairs(self._connections) do
		conn.Connected = false
	end
	table.clear(self._connections)
end

function Signal:DisconnectAll()
	for _, conn in ipairs(self._connections) do
		conn.Connected = false
	end
	table.clear(self._connections)
end


local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {} }, Maid)
end

function Maid:GiveTask(task)
	if task == nil then return end
	table.insert(self._tasks, task)
	return task
end

function Maid:Give(task)
	return self:GiveTask(task)
end

function Maid:DoCleaning()
	local tasks = self._tasks
	self._tasks = {}
	for i = #tasks, 1, -1 do
		local t = tasks[i]
		local ty = typeof(t)
		if ty == "RBXScriptConnection" then
			t:Disconnect()
		elseif ty == "Instance" then
			t:Destroy()
		elseif ty == "function" then
			pcall(t)
		elseif ty == "table" and t.Destroy then
			pcall(function() t:Destroy() end)
		elseif ty == "table" and t.Disconnect then
			pcall(function() t:Disconnect() end)
		end
	end
end

function Maid:Destroy()
	self:DoCleaning()
end


local Themes: {[string]: ThemeTokens} = {
	["macOS Dark"] = {
		Background        = Color3.fromRGB(28, 28, 30),
		Surface           = Color3.fromRGB(38, 38, 40),
		SurfaceSecondary  = Color3.fromRGB(48, 48, 52),
		SurfaceTertiary   = Color3.fromRGB(58, 58, 62),
		Border            = Color3.fromRGB(58, 58, 62),
		BorderHover       = Color3.fromRGB(80, 80, 86),
		Text              = Color3.fromRGB(255, 255, 255),
		TextSecondary     = Color3.fromRGB(174, 174, 178),
		TextTertiary      = Color3.fromRGB(120, 120, 128),
		Accent            = Color3.fromRGB(10, 132, 255),
		AccentHover       = Color3.fromRGB(40, 150, 255),
		AccentPressed     = Color3.fromRGB(0, 110, 220),
		Success           = Color3.fromRGB(48, 209, 88),
		Warning           = Color3.fromRGB(255, 159, 10),
		Danger            = Color3.fromRGB(255, 69, 58),
		Shadow            = Color3.fromRGB(0, 0, 0),
		Overlay           = Color3.fromRGB(0, 0, 0),
	},
	["macOS Light"] = {
		Background        = Color3.fromRGB(242, 242, 247),
		Surface           = Color3.fromRGB(255, 255, 255),
		SurfaceSecondary  = Color3.fromRGB(242, 242, 247),
		SurfaceTertiary   = Color3.fromRGB(229, 229, 234),
		Border            = Color3.fromRGB(209, 209, 214),
		BorderHover       = Color3.fromRGB(174, 174, 178),
		Text              = Color3.fromRGB(28, 28, 30),
		TextSecondary     = Color3.fromRGB(99, 99, 102),
		TextTertiary      = Color3.fromRGB(142, 142, 147),
		Accent            = Color3.fromRGB(0, 122, 255),
		AccentHover       = Color3.fromRGB(10, 132, 255),
		AccentPressed     = Color3.fromRGB(0, 100, 220),
		Success           = Color3.fromRGB(52, 199, 89),
		Warning           = Color3.fromRGB(255, 149, 0),
		Danger            = Color3.fromRGB(255, 59, 48),
		Shadow            = Color3.fromRGB(0, 0, 0),
		Overlay           = Color3.fromRGB(0, 0, 0),
	},
}

local ThemeRegistry: {[Instance]: {[string]: string}} = {}

local function RegisterTheme(inst: Instance, prop: string, token: string)
	if not ThemeRegistry[inst] then
		ThemeRegistry[inst] = {}
	end
	ThemeRegistry[inst][prop] = token
end

local function ApplyThemeToInstance(inst: Instance, tokens: ThemeTokens)
	local map = ThemeRegistry[inst]
	if not map then return end
	for prop, token in pairs(map) do
		local color = tokens[token]
		if color and inst[prop] ~= nil then
			inst[prop] = color
		end
	end
end

function Library:GetTheme(): ThemeTokens
	if type(Library.ActiveTheme) == "table" then
		return Library.ActiveTheme :: ThemeTokens
	end
	return Themes[Library.ActiveTheme] or Themes["macOS Dark"]
end

function Library:SetTheme(theme: string | ThemeTokens)
	if type(theme) == "string" then
		if not Themes[theme] then
			warn("[Library] Unknown theme:", theme)
			return
		end
		Library.ActiveTheme = theme
	elseif type(theme) == "table" then
		Library.ActiveTheme = theme
	else
		return
	end
	local tokens = Library:GetTheme()
	for inst in pairs(ThemeRegistry) do
		if inst and inst.Parent then
			ApplyThemeToInstance(inst, tokens)
		else
			ThemeRegistry[inst] = nil
		end
	end
	for _, win in ipairs(Library.Windows) do
		if win and not win.Destroyed then
			win:_ApplyTheme(tokens)
		end
	end
end


local ActiveTweens: {[Instance]: {[string]: Tween}} = {}

local function Tween(obj: Instance, goal: {[string]: any}, info: TweenInfo?)
	info = info or TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	if not ActiveTweens[obj] then
		ActiveTweens[obj] = {}
	end
	for prop in pairs(goal) do
		local existing = ActiveTweens[obj][prop]
		if existing then
			existing:Cancel()
			ActiveTweens[obj][prop] = nil
		end
	end
	local tw = TweenService:Create(obj, info, goal)
	for prop in pairs(goal) do
		ActiveTweens[obj][prop] = tw
	end
	tw.Completed:Connect(function()
		if ActiveTweens[obj] then
			for prop in pairs(goal) do
				if ActiveTweens[obj][prop] == tw then
					ActiveTweens[obj][prop] = nil
				end
			end
		end
	end)
	tw:Play()
	return tw
end

local function QuickTween(obj: Instance, goal: {[string]: any}, duration: number?)
	return Tween(obj, goal, TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
end

local function SpringTween(obj: Instance, goal: {[string]: any}, frequency: number?)
	local freq = frequency or 8
	local duration = math.clamp(1.15 / freq, 0.12, 0.45)
	return Tween(obj, goal, TweenInfo.new(duration, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out))
end

local SpringMotors: {[Instance]: {[string]: any}} = {}

local function SpringMotor(initial: number, obj: Instance, prop: string, useImplicit: boolean?)
	local motor = {
		_value = initial,
		_goal = initial,
		_velocity = 0,
		_frequency = 8,
		_damping = 1,
		_running = false,
		_conn = nil,
	}

	local function stop()
		if motor._conn then
			motor._conn:Disconnect()
			motor._conn = nil
		end
		motor._running = false
	end

	local function step(dt: number)
		local f = motor._frequency * 2 * math.pi
		local d = motor._damping
		local target = motor._goal
		local x = motor._value - target
		local v = motor._velocity

		local exp = math.exp(-d * f * dt)
		local newX, newV
		if math.abs(d - 1) < 1e-4 then
			newX = (x * (1 + f * dt) + v * dt) * exp
			newV = (v * (1 - f * dt) - x * (f * f * dt)) * exp
		else
			local o = math.sqrt(math.max(1e-6, 1 - d * d))
			local cos = math.cos(f * o * dt)
			local sin = math.sin(f * o * dt)
			local t = sin / math.max(o, 1e-6)
			local u = sin / math.max(f * o, 1e-6)
			newX = (x * (cos + d * t) + v * u) * exp
			newV = (v * (cos - t * d) - x * (t * f)) * exp
		end

		motor._value = newX + target
		motor._velocity = newV

		pcall(function()
			obj[prop] = motor._value
		end)

		if math.abs(newV) < 0.001 and math.abs(newX) < 0.001 then
			motor._value = target
			motor._velocity = 0
			pcall(function()
				obj[prop] = target
			end)
			stop()
		end
	end

	function motor:setGoal(goal: number, frequency: number?)
		self._goal = goal
		if frequency then
			self._frequency = frequency
		end
		if not self._running then
			self._running = true
			self._conn = RunService.RenderStepped:Connect(function(dt)
				step(math.min(dt, 0.05))
			end)
		end
	end

	function motor:setInstant(goal: number)
		stop()
		self._goal = goal
		self._value = goal
		self._velocity = 0
		pcall(function()
			obj[prop] = goal
		end)
	end

	function motor:Destroy()
		stop()
	end

	SpringMotors[obj] = SpringMotors[obj] or {}
	SpringMotors[obj][prop] = motor
	return motor
end


local Icons = {
	house      = "rbxassetid://10747373176",
	settings   = "rbxassetid://10734950309",
	search     = "rbxassetid://10734943674",
	close      = "rbxassetid://10747384394",
	minimize   = "rbxassetid://10734895698",
	chevron    = "rbxassetid://10709790948",
	check      = "rbxassetid://10709790644",
	plus       = "rbxassetid://10734898355",
	info       = "rbxassetid://10723415939",
	warning    = "rbxassetid://10723415339",
	success    = "rbxassetid://10709799156",
	error      = "rbxassetid://10709798783",
	key        = "rbxassetid://10734949127",
	color      = "rbxassetid://10734884548",
	user       = "rbxassetid://10734948424",
	folder     = "rbxassetid://10734883381",
	star       = "rbxassetid://10734952273",
	eye        = "rbxassetid://10723415040",
	target     = "rbxassetid://10734977012",
	zap        = "rbxassetid://10723345749",
	shield     = "rbxassetid://10734951847",
	sword      = "rbxassetid://10734975486",
	home       = "rbxassetid://10747373176",
	list       = "rbxassetid://10734943674",
	box        = "rbxassetid://10709782497",
}

local function ResolveIcon(name: string?): string?
	if not name then return nil end
	return Icons[string.lower(name)] or name
end

local function CreateIcon(parent: Instance, name: string?, size: number?)
	size = size or 16
	local icon = Utility.Create("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		Image = ResolveIcon(name) or "",
		ImageColor3 = Library:GetTheme().TextSecondary,
		ScaleType = Enum.ScaleType.Fit,
		Parent = parent,
	})
	RegisterTheme(icon, "ImageColor3", "TextSecondary")
	return icon
end

local function ApplyRowIcon(parent: Frame, iconName: string?, rowHeight: number?, yOffset: number?)
	if not iconName or iconName == "" then
		return 0, nil
	end
	local h = rowHeight or 36
	local icon = CreateIcon(parent, iconName, 16)
	local y = yOffset
	if y == nil then
		y = math.floor((h - 16) / 2)
	end
	icon.Position = UDim2.fromOffset(0, y)
	icon.ImageColor3 = Library:GetTheme().TextSecondary
	return 22, icon
end


local TooltipGui: ScreenGui? = nil
local TooltipFrame: Frame? = nil
local TooltipLabel: TextLabel? = nil
local TooltipHideToken = 0

local function FindScreenGui(inst: Instance?): ScreenGui?
	local p = inst
	while p do
		if p:IsA("ScreenGui") then
			return p
		end
		p = p.Parent
	end
	return nil
end

local function EnsureTooltip()
	if TooltipFrame and TooltipFrame.Parent then return end

	if not TooltipGui or not TooltipGui.Parent then
		TooltipGui = Utility.Create("ScreenGui", {
			Name = "LibraryTooltip",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			DisplayOrder = 1000,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		})
		SafeProtect(TooltipGui)
		local tipParent = SafeParent()
		if tipParent then
			TooltipGui.Parent = tipParent
		end
	end

	TooltipFrame = Utility.Create("Frame", {
		Name = "Tooltip",
		BackgroundColor3 = Library:GetTheme().SurfaceSecondary,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(80, 28),
		Visible = false,
		Parent = TooltipGui,
		ZIndex = 10000,
	})
	RegisterTheme(TooltipFrame, "BackgroundColor3", "SurfaceSecondary")
	Utility.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TooltipFrame })
	Utility.Create("UIStroke", {
		Color = Library:GetTheme().Border,
		Thickness = 1,
		Parent = TooltipFrame,
	})
	Utility.Create("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = TooltipFrame,
	})
	Utility.AddShadow(TooltipFrame, {
		BlurRadius = 10,
		Transparency = 0.45,
		Offset = UDim2.fromOffset(0, 3),
	})

	TooltipLabel = Utility.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Library:GetTheme().Text,
		Font = FONT,
		TextSize = 12,
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent = TooltipFrame,
	})
	RegisterTheme(TooltipLabel, "TextColor3", "Text")
end

local function ShowTooltip(text: string, anchor: GuiObject)
	if not text or text == "" then return end
	EnsureTooltip()
	TooltipHideToken += 1
	local token = TooltipHideToken

	TooltipLabel.Text = text

	local bounds = Utility.GetTextBounds(text, FONT, 12)
	local tipW = math.clamp(math.ceil(bounds.X) + 20, 48, 320)
	local tipH = math.clamp(math.ceil(bounds.Y) + 12, 24, 80)
	TooltipFrame.Size = UDim2.fromOffset(tipW, tipH)

	local host = FindScreenGui(anchor) or TooltipGui
	if host and TooltipFrame.Parent ~= host then
		TooltipFrame.Parent = host
	end

	TooltipFrame.Visible = true
	TooltipFrame.ZIndex = 10000

	local function place()
		if token ~= TooltipHideToken then return end

		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
		local mouse = UserInputService:GetMouseLocation()
		local inset = GuiService:GetGuiInset()
		local hostGui = FindScreenGui(TooltipFrame)

		local mx, my = mouse.X, mouse.Y
		if hostGui and hostGui.IgnoreGuiInset then
			mx = mx + inset.X
			my = my + inset.Y
		end

		local gapX, gapY = 14, 18
		local x = mx + gapX
		local y = my + gapY

		if x + tipW > vp.X - 4 then
			x = mx - tipW - 8
		end
		if y + tipH > vp.Y - 4 then
			y = my - tipH - 8
		end

		x = math.clamp(x, 4, math.max(4, vp.X - tipW - 4))
		y = math.clamp(y, 4, math.max(4, vp.Y - tipH - 4))

		TooltipFrame.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
	end

	place()
	task.defer(place)
end

local function HideTooltip()
	TooltipHideToken += 1
	if TooltipFrame then
		TooltipFrame.Visible = false
		if TooltipGui and TooltipFrame.Parent ~= TooltipGui then
			TooltipFrame.Parent = TooltipGui
		end
	end
end

local function BindTooltip(target: GuiObject, textGetter: () -> string)
	local maid = Maid.new()
	local hovering = false

	local function tryShow()
		hovering = true
		task.delay(0.1, function()
			if not hovering then return end
			local text = textGetter()
			if text and text ~= "" then
				ShowTooltip(text, target)
			end
		end)
	end

	maid:Give(target.MouseEnter:Connect(tryShow))
	maid:Give(target.MouseLeave:Connect(function()
		hovering = false
		HideTooltip()
	end))
	if target:IsA("GuiButton") then
		maid:Give(target.SelectionGained:Connect(tryShow))
		maid:Give(target.SelectionLost:Connect(function()
			hovering = false
			HideTooltip()
		end))
	end
	maid:Give(target.Destroying:Connect(function()
		hovering = false
		HideTooltip()
		maid:Destroy()
	end))
	return maid
end


local FlagMeta = {}
FlagMeta.__index = FlagMeta

function FlagMeta:Set(value, silent)
	if self._component and self._component.Set then
		self._component:Set(value, silent)
	else
		self.Value = value
	end
end

function FlagMeta:Get()
	return self.Value
end

local function RegisterFlag(flagName: string, component, initialValue: any, displayText: string?, flagType: string?)
	if not flagName or flagName == "" then return end

	if Library.Flags[flagName] and Library.Flags[flagName]._component and Library.Flags[flagName]._component ~= component then
		warn("[Library] Duplicate flag:", flagName)
	end

	local obj = setmetatable({
		Value = initialValue,
		Text = displayText or flagName,
		Type = flagType or "Unknown",
		_component = component,
		_flag = flagName,
	}, FlagMeta)

	Library.Flags[flagName] = obj
	return obj
end

function Library:SetFlag(flag: string, value: any)
	if not flag or flag == "" then return end
	local obj = Library.Flags[flag]
	if obj and obj.Set then
		obj:Set(value)
	else

		Library.Flags[flag] = setmetatable({
			Value = value,
			Text = flag,
			Type = "Raw",
			_component = nil,
			_flag = flag,
		}, FlagMeta)
	end
end

function Library:GetFlag(flag: string)
	local obj = Library.Flags[flag]
	if obj then
		return obj.Value
	end
	return nil
end

function Library:HasFlag(flag: string)
	return Library.Flags[flag] ~= nil
end

function Library:ResetFlags()
	table.clear(Library.Flags)
end

function Library:GetConfig()
	local cfg = {}
	for k, obj in pairs(Library.Flags) do
		cfg[k] = obj.Value
	end
	return cfg
end

function Library:LoadConfig(data: {[string]: any})
	if type(data) ~= "table" then return end
	for flag, value in pairs(data) do
		Library:SetFlag(flag, value)
		for _, win in ipairs(Library.Windows) do
			if win and not win.Destroyed then
				win:_ApplyFlag(flag, value)
			end
		end
	end
end


local Component = {}
Component.__index = Component

function Component.new(parentSection, config)
	local self = setmetatable({}, Component)
	self.Section = parentSection
	self.Config = config or {}
	self.Maid = Maid.new()
	self.Visible = true
	self.Disabled = config.Disabled == true
	self.Destroyed = false
	self.Changed = Signal.new()
	self.Maid:Give(self.Changed)
	return self
end

function Component:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	if self.Config.Flag and Library.Flags[self.Config.Flag] and Library.Flags[self.Config.Flag]._component == self then
		Library.Flags[self.Config.Flag]._component = nil
	end
	self.Maid:Destroy()
	if self.Frame then
		self.Frame:Destroy()
	end
end

function Component:SetVisible(v: boolean)
	self.Visible = v
	if self.Frame then
		self.Frame.Visible = v
	end
end

function Component:SetDisabled(v: boolean)
	self.Disabled = v == true
	if self.Frame then
		self.Frame.Active = not self.Disabled
		if self._ApplyDisabled then
			self:_ApplyDisabled(self.Disabled)
		else
			self.Frame.BackgroundTransparency = self.Disabled and 0.5 or 0
			for _, d in ipairs(self.Frame:GetDescendants()) do
				if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
					d.TextTransparency = self.Disabled and 0.45 or 0
				elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
					d.ImageTransparency = self.Disabled and 0.45 or 0
				elseif d:IsA("GuiObject") and d.BackgroundTransparency < 1 then
					d.BackgroundTransparency = self.Disabled and math.min(1, d.BackgroundTransparency + 0.35) or d.BackgroundTransparency
				end
			end
		end
	end
end

function Component:Get()
	return self.Value
end

function Component:GetValue()
	return self.Value
end

function Component:Set(value, silent)
end

function Component:SetValue(value, silent)
	return self:Set(value, silent)
end

function Component:OnChanged(fn)
	return self.Changed:Connect(fn)
end

function Component:IsVisible()
	return self.Visible ~= false
end

function Component:IsDisabled()
	return self.Disabled == true
end

function Component:SetText(text: string)
	if self._TitleLabel then
		self._TitleLabel.Text = text or ""
	elseif self.Label then
		self.Label.Text = text or ""
	end
	if self.Config then
		self.Config.Name = text
	end
end

function Component:GetText()
	if self.Config and self.Config.Name then
		return self.Config.Name
	end
	if self._TitleLabel then
		return self._TitleLabel.Text
	end
	return ""
end

function Component:Update(config)
	if type(config) ~= "table" then return self end
	for k, v in pairs(config) do
		self.Config[k] = v
	end
	if config.Name then
		self:SetText(config.Name)
	end
	if config.Disabled ~= nil then
		self:SetDisabled(config.Disabled)
	end
	if config.Default ~= nil and self.Set then
		self:Set(config.Default, true)
	end
	if config.Visible ~= nil then
		self:SetVisible(config.Visible)
	end
	return self
end

function Component:SetTooltip(text: string)
	self.Config = self.Config or {}
	self.Config.Tooltip = text
	if self._TooltipMaid then
		self._TooltipMaid:Destroy()
		self._TooltipMaid = nil
	end
	if text and text ~= "" and self.Frame then
		self._TooltipMaid = BindTooltip(self.Frame, function() return self.Config.Tooltip end)
		self.Maid:Give(self._TooltipMaid)
	end
	return self
end

function Component:SetCallback(fn)
	self.Config = self.Config or {}
	self.Config.Callback = fn
	return self
end

function Component:SetFlag(flag: string)
	if not flag then return self end
	self.Config.Flag = flag
	RegisterFlag(flag, self, self.Value, self.Config.Name, self.Config.Type or "Component")
	return self
end

function Component:Toggle()
	if type(self.Value) == "boolean" and self.Set then
		self:Set(not self.Value)
	end
	return self
end

function Component:Refresh()
	if self.Set and self.Value ~= nil then
		local v = self.Value
		self.Value = nil
		self:Set(v, true)
	end
	return self
end


local function CreateSurface(parent, props)
	local tokens = Library:GetTheme()
	local frame = Utility.Create("Frame", {
		BackgroundColor3 = tokens.Surface,
		BorderSizePixel = 0,
		Parent = parent,
	})
	RegisterTheme(frame, "BackgroundColor3", "Surface")
	Utility.Create("UICorner", {
		CornerRadius = UDim.new(0, props and props.Corner or DEFAULT_CORNER),
		Parent = frame,
	})
	if props and props.Stroke then
		local stroke = Utility.Create("UIStroke", {
			Color = tokens.Border,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = frame,
		})
		RegisterTheme(stroke, "Color", "Border")
	end
	if props then
		for k, v in pairs(props) do
			if k ~= "Corner" and k ~= "Stroke" and k ~= "Parent" then
				frame[k] = v
			end
		end
	end
	return frame
end

local function CreateRow(parent, height)
	height = height or ROW_HEIGHT
	return Utility.Create("Frame", {
		Name = "Row",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height),
		Parent = parent,
	})
end

local function CreateLabel(parent, text, size, colorToken)
	local tokens = Library:GetTheme()
	local lbl = Utility.Create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text or "",
		TextColor3 = tokens[colorToken or "Text"],
		Font = FONT,
		TextSize = size or 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = parent,
	})
	RegisterTheme(lbl, "TextColor3", colorToken or "Text")
	return lbl
end

local Button = setmetatable({}, { __index = Component })
Button.__index = Button

local function RelayoutButtonRow(section)
	local slots = section._ButtonSlots
	if not slots or #slots == 0 then return end
	local n = #slots
	local pad = 8
	for i, slot in ipairs(slots) do
		if n == 1 then
			slot.Size = UDim2.new(1, 0, 1, 0)
		else
			slot.Size = UDim2.new(1 / n, -math.floor(pad * (n - 1) / n), 1, 0)
		end
	end
end

local function EnsureButtonRow(section)
	if not section._ButtonRow or (section._ButtonRowCount or 0) >= 3 then
		local row = Utility.Create("Frame", {
			Name = "ButtonRow",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 36),
			Parent = section.Content,
		})
		Utility.Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = row,
		})
		section._ButtonRow = row
		section._ButtonRowCount = 0
		section._ButtonSlots = {}
	end
	return section._ButtonRow
end

function Button.new(section, config: ButtonConfig)
	local self = Component.new(section, config)
	setmetatable(self, Button)

	local tokens = Library:GetTheme()
	local customColor = config.Color
	local row = EnsureButtonRow(section)
	section._ButtonRowCount = (section._ButtonRowCount or 0) + 1

	local frame = Utility.Create("Frame", {
		Name = "ButtonSlot",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = row,
	})
	table.insert(section._ButtonSlots, frame)
	RelayoutButtonRow(section)
	self.Frame = frame

	local bgColor = customColor or tokens.SurfaceSecondary
	local textColor = customColor and Color3.new(1, 1, 1) or tokens.Text

	local btn = Utility.Create("TextButton", {
		Name = "Button",
		BackgroundColor3 = bgColor,
		Size = UDim2.fromScale(1, 1),
		Text = config.Name or "Button",
		TextColor3 = textColor,
		Font = FONT_SEMIBOLD,
		TextSize = 13,
		AutoButtonColor = false,
		Parent = frame,
	})
	if not customColor then
		RegisterTheme(btn, "BackgroundColor3", "SurfaceSecondary")
		RegisterTheme(btn, "TextColor3", "Text")
	end
	Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })
	if not customColor then
		Utility.Create("UIStroke", {
			Color = tokens.Border,
			Thickness = 1,
			Parent = btn,
		})
	end
	if customColor then
		Utility.AddShadow(btn, {
			BlurRadius = 8,
			Transparency = 0.6,
			Offset = UDim2.fromOffset(0, 2),
			Color = bgColor,
		})
	end

	local baseColor = bgColor
	local hoverColor = customColor and Color3.new(
		math.min(1, customColor.R + 0.08),
		math.min(1, customColor.G + 0.08),
		math.min(1, customColor.B + 0.08)
	) or tokens.SurfaceTertiary
	local pressColor = customColor and Color3.new(
		math.max(0, customColor.R - 0.1),
		math.max(0, customColor.G - 0.1),
		math.max(0, customColor.B - 0.1)
	) or tokens.Border

	local function setState(state)
		if self.Disabled then return end
		if state == "hover" then
			SpringTween(btn, { BackgroundColor3 = hoverColor }, 9)
		elseif state == "press" then
			SpringTween(btn, { BackgroundColor3 = pressColor }, 12)
		else
			SpringTween(btn, { BackgroundColor3 = baseColor }, 8)
		end
	end

	self.Maid:Give(btn.MouseEnter:Connect(function() setState("hover") end))
	self.Maid:Give(btn.MouseLeave:Connect(function() setState("normal") end))
	self.Maid:Give(btn.MouseButton1Down:Connect(function() setState("press") end))
	self.Maid:Give(btn.MouseButton1Up:Connect(function() setState("hover") end))
	self.Maid:Give(btn.Activated:Connect(function()
		if self.Disabled then return end
		Utility.SafeCallback(config.Callback)
	end))

	if config.Tooltip then
		self.Maid:Give(BindTooltip(btn, function() return config.Tooltip end))
	end

	if self.Disabled then
		self:SetDisabled(true)
	end

	self._ApplyDisabled = function(_, disabled)
		btn.Active = not disabled
		btn.TextTransparency = disabled and 0.45 or 0
		btn.BackgroundTransparency = disabled and 0.35 or 0
	end

	function self:AddButton(nextConfig)
		if type(nextConfig) == "string" then
			nextConfig = { Name = nextConfig }
		end
		nextConfig = nextConfig or {}
		local section = self.Section
		if not section or section.Destroyed then
			return self
		end
		local sibling = Button.new(section, nextConfig)
		table.insert(section.Components, sibling)
		return sibling
	end

	return self
end


local Toggle = setmetatable({}, { __index = Component })
Toggle.__index = Toggle


local LINK_ICON = "rbxassetid://101330725759187"
local ActiveLinkPopup = nil

local function CloseLinkPopup()
	if ActiveLinkPopup then
		local data = ActiveLinkPopup
		ActiveLinkPopup = nil
		if data.Content and data.Storage and data.Content.Parent then
			data.Content.Parent = data.Storage
		end
		if data.Popup then
			data.Popup:Destroy()
		end
	end
end

local function BuildLinkProxy(component)
	local storage = Utility.Create("Frame", {
		Name = "LinkStorage",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(204, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = component.Frame,
	})

	local content = Utility.Create("Frame", {
		Name = "LinkContent",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = storage,
	})
	Utility.Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = content,
	})
	Utility.Create("UIPadding", {
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 2),
		Parent = content,
	})

	local proxy = {
		Content = content,
		Frame = content,
		Components = {},
		_ButtonRow = nil,
		_ButtonRowCount = 0,
		_ButtonSlots = nil,
		Tab = component.Section and component.Section.Tab or nil,
		Destroyed = false,
		_Storage = storage,
		_Component = component,
	}

	local function add(methodName, cfg)
		if not Section or not Section[methodName] then
			warn("[Library] Link: Section." .. methodName .. " unavailable")
			return nil
		end
		return Section[methodName](proxy, cfg)
	end

	function proxy:AddToggle(cfg) return add("AddToggle", cfg) end
	function proxy:AddSlider(cfg) return add("AddSlider", cfg) end
	function proxy:AddDropdown(cfg) return add("AddDropdown", cfg) end
	function proxy:AddMultiDropdown(cfg) return add("AddMultiDropdown", cfg) end
	function proxy:AddButton(cfg) return add("AddButton", cfg) end
	function proxy:AddInput(cfg) return add("AddInput", cfg) end
	function proxy:AddKeybind(cfg) return add("AddKeybind", cfg) end
	function proxy:AddColorPicker(cfg) return add("AddColorPicker", cfg) end
	function proxy:AddLabel(cfg) return add("AddLabel", cfg) end
	function proxy:AddParagraph(cfg) return add("AddParagraph", cfg) end
	function proxy:AddDivider(cfg) return add("AddDivider", cfg) end
	function proxy:AddSpace(cfg) return add("AddSpace", cfg) end

	function proxy:Destroy()
		CloseLinkPopup()
		for _, c in ipairs(self.Components) do
			pcall(function() c:Destroy() end)
		end
		storage:Destroy()
	end

	return proxy
end

local function OpenLinkPopup(component)
	if not component._LinkProxy then return end
	CloseLinkPopup()

	local tokens = Library:GetTheme()
	local window = component.Section and component.Section.Tab and component.Section.Tab.Window
	local parent = (window and window.ScreenGui) or SafeParent()
	if not parent then return end

	local anchor = component._LinkButton
	local POPUP_W = 220
	local POPUP_MAX_H = 220

	local popup = Utility.Create("Frame", {
		Name = "LinkPopup",
		BackgroundColor3 = tokens.Surface,
		Size = UDim2.fromOffset(POPUP_W, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
		ZIndex = 300,
		ClipsDescendants = true,
	})
	RegisterTheme(popup, "BackgroundColor3", "Surface")
	Utility.Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = popup })
	Utility.Create("UIStroke", { Color = tokens.Border, Thickness = 1, Parent = popup })
	Utility.AddShadow(popup, { BlurRadius = 16, Transparency = 0.4, Offset = UDim2.fromOffset(0, 4) })
	Utility.Create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = popup,
	})
	Utility.Create("UISizeConstraint", {
		MaxSize = Vector2.new(POPUP_W, POPUP_MAX_H),
		Parent = popup,
	})

	local scroll = Utility.Create("ScrollingFrame", {
		Name = "LinkScroll",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageTransparency = 0.5,
		BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = popup,
	})
	Utility.Create("UISizeConstraint", {
		MaxSize = Vector2.new(POPUP_W - 16, POPUP_MAX_H - 16),
		Parent = scroll,
	})

	local proxy = component._LinkProxy
	proxy.Content.Visible = true
	proxy.Content.Size = UDim2.new(1, 0, 0, 0)
	proxy.Content.AutomaticSize = Enum.AutomaticSize.Y
	proxy.Content.Parent = scroll
	if #proxy.Components == 0 then
		local empty = CreateLabel(scroll, "No options", 11, "TextSecondary")
		empty.Size = UDim2.new(1, 0, 0, 20)
		empty.TextXAlignment = Enum.TextXAlignment.Center
	end

	local abs = anchor.AbsolutePosition
	local asz = anchor.AbsoluteSize
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	local x = abs.X + asz.X + 6
	local y = abs.Y
	if x + POPUP_W > vp.X - 8 then
		x = abs.X - POPUP_W - 6
	end
	y = math.clamp(y, 8, math.max(8, vp.Y - POPUP_MAX_H - 12))
	popup.Position = UDim2.fromOffset(math.floor(x), math.floor(y))

	local scale = Utility.Create("UIScale", { Scale = 0.96, Parent = popup })
	SpringTween(scale, { Scale = 1 }, 10)

	ActiveLinkPopup = {
		Popup = popup,
		Content = proxy.Content,
		Storage = proxy._Storage,
		Component = component,
	}
	component._LinkOpen = true

	local function pointIn(gui, x, y)
		if not gui or not gui.Parent then return false end
		local p = gui.AbsolutePosition
		local s = gui.AbsoluteSize
		if s.X < 1 or s.Y < 1 then return false end
		return x >= p.X and x <= p.X + s.X and y >= p.Y and y <= p.Y + s.Y
	end

	local function mouseInsideLink()
		local m = UserInputService:GetMouseLocation()
		local inset = GuiService:GetGuiInset()
		local pts = {
			m,
			Vector2.new(m.X - inset.X, m.Y - inset.Y),
			Vector2.new(m.X + inset.X, m.Y + inset.Y),
		}
		for _, pt in ipairs(pts) do
			if pointIn(popup, pt.X, pt.Y) or pointIn(anchor, pt.X, pt.Y) then
				return true
			end
			if proxy.Content and pointIn(proxy.Content, pt.X, pt.Y) then
				return true
			end
		end
		local ok, objs = pcall(function()
			local pos = m - inset
			return parent:GetGuiObjectsAtPosition(pos.X, pos.Y)
		end)
		if ok and type(objs) == "table" then
			for _, obj in ipairs(objs) do
				if obj == popup or obj:IsDescendantOf(popup) then
					return true
				end
				if obj == anchor or (anchor and obj:IsDescendantOf(anchor)) then
					return true
				end
			end
		end
		return false
	end

	local closeConn
	closeConn = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		task.delay(0.05, function()
			if not popup.Parent then
				if closeConn then closeConn:Disconnect() end
				return
			end
			if mouseInsideLink() then
				return
			end
			component._LinkOpen = false
			CloseLinkPopup()
			if closeConn then closeConn:Disconnect() end
		end)
	end)
end

local function AttachLinkButton(component, frame, isToggle)
	local tokens = Library:GetTheme()
	local linkBtn = Utility.Create("ImageButton", {
		Name = "LinkButton",
		BackgroundTransparency = 1,
		Image = LINK_ICON,
		Size = UDim2.fromOffset(18, 18),
		Position = isToggle and UDim2.new(1, -70, 0.5, -9) or UDim2.new(1, -22, 0.5, -9),
		ImageColor3 = tokens.TextSecondary,
		ScaleType = Enum.ScaleType.Fit,
		Visible = false,
		Parent = frame,
		ZIndex = 5,
	})
	RegisterTheme(linkBtn, "ImageColor3", "TextSecondary")

	component._LinkButton = linkBtn
	component._LinkOpen = false
	component._LinkProxy = nil

	function component:Link()
		if self._LinkProxy then
			return self._LinkProxy
		end
		if self._LinkButton then
			self._LinkButton.Visible = true
		end
		self._LinkProxy = BuildLinkProxy(self)
		return self._LinkProxy
	end

	component.Maid:Give(linkBtn.Activated:Connect(function()
		if component.Disabled then return end
		if component._LinkOpen and ActiveLinkPopup then
			component._LinkOpen = false
			CloseLinkPopup()
			return
		end
		OpenLinkPopup(component)
	end))

	return linkBtn
end


function Toggle.new(section, config: ToggleConfig)
	local self = Component.new(section, config)
	setmetatable(self, Toggle)

	self.Value = config.Default == true
	if config.Flag then
		RegisterFlag(config.Flag, self, self.Value, config.Name, "Toggle")
	end

	local tokens = Library:GetTheme()
	local hasDesc = type(config.Description) == "string" and config.Description ~= ""
	local rowH = hasDesc and 52 or 36
	local frame = CreateRow(section.Content, rowH)
	self.Frame = frame

	local left = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -78, 1, 0),
		Parent = frame,
	})

	local iconPad = 0
	local rowIcon = nil
	if config.Icon and config.Icon ~= "" then
		rowIcon = CreateIcon(left, config.Icon, 16)
		rowIcon.Position = UDim2.fromOffset(0, hasDesc and 7 or math.floor((rowH - 16) / 2))
		rowIcon.ImageColor3 = Library:GetTheme().TextSecondary
		iconPad = 22
	end
	self._IconLabel = rowIcon

	local title = CreateLabel(left, config.Name or "Toggle", 14, "Text")
	title.Size = UDim2.new(1, -iconPad, 0, hasDesc and 18 or rowH)
	title.Position = UDim2.fromOffset(iconPad, hasDesc and 6 or 0)
	title.TextYAlignment = hasDesc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
	self._TitleLabel = title

	if hasDesc then
		local desc = CreateLabel(left, config.Description, 12, "TextSecondary")
		desc.Size = UDim2.new(1, 0, 0, 16)
		desc.Position = UDim2.fromOffset(0, 26)
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.TextWrapped = true
		self._DescLabel = desc
	end

	local track = Utility.Create("Frame", {
		Name = "Track",
		BackgroundColor3 = self.Value and tokens.Accent or tokens.SurfaceTertiary,
		Size = UDim2.fromOffset(44, 26),
		Position = UDim2.new(1, -44, 0.5, -13),
		Parent = frame,
	})
	RegisterTheme(track, "BackgroundColor3", self.Value and "Accent" or "SurfaceTertiary")
	Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
	Utility.AddShadow(track, { BlurRadius = 6, Transparency = 0.7, Offset = UDim2.fromOffset(0, 1) })

	local knob = Utility.Create("Frame", {
		Name = "Knob",
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromOffset(22, 22),
		Position = self.Value and UDim2.new(1, -24, 0.5, -11) or UDim2.fromOffset(2, 2),
		Parent = track,
	})
	Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
	Utility.AddShadow(knob, { BlurRadius = 4, Transparency = 0.5, Offset = UDim2.fromOffset(0, 1) })

	local hit = Utility.Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		Parent = frame,
	})

	function self:Set(value: boolean, silent: boolean?)
		if self.Destroyed then return end
		value = value == true
		if self.Value == value then return end
		self.Value = value

		local t = Library:GetTheme()
		SpringTween(track, { BackgroundColor3 = value and t.Accent or t.SurfaceTertiary }, 10)
		SpringTween(knob, {
			Position = value and UDim2.new(1, -24, 0.5, -11) or UDim2.fromOffset(2, 2)
		}, 10)

		if config.Flag and Library.Flags[config.Flag] then
			Library.Flags[config.Flag].Value = value
		end
		if not silent then
			Utility.SafeCallback(config.Callback, value)
			self.Changed:Fire(value)
		end
	end

	self.Maid:Give(hit.Activated:Connect(function()
		if self.Disabled then return end
		self:Set(not self.Value)
	end))

	if config.Tooltip then
		self.Maid:Give(BindTooltip(hit, function() return config.Tooltip end))
	end

	if self.Disabled then
		self:SetDisabled(true)
	end

	AttachLinkButton(self, frame, true)

	return self
end


local Slider = setmetatable({}, { __index = Component })
Slider.__index = Slider

function Slider.new(section, config: SliderConfig)
	local self = Component.new(section, config)
	setmetatable(self, Slider)

	local min = config.Min or 0
	local max = config.Max or 100
	local rounding = config.Rounding or 0
	self.Value = Utility.Clamp(config.Default or min, min, max)
	if config.Flag then
		RegisterFlag(config.Flag, self, self.Value, config.Name, "Slider")
	end

	local tokens = Library:GetTheme()
	local frame = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 52),
		Parent = section.Content,
	})
	self.Frame = frame

	local iconPad = 0
	if config.Icon then
		local ic = CreateIcon(frame, config.Icon, 16)
		ic.Position = UDim2.fromOffset(0, 2)
		iconPad = 22
		self._IconLabel = ic
	end
	local title = CreateLabel(frame, config.Name or "Slider", 14, "Text")
	title.Size = UDim2.new(1, -(70 + iconPad), 0, 18)
	title.Position = UDim2.fromOffset(iconPad, 0)
	self._TitleLabel = title

	local valueBox = Utility.Create("TextBox", {
		BackgroundColor3 = tokens.SurfaceTertiary,
		Size = UDim2.fromOffset(56, 22),
		Position = UDim2.new(1, -56, 0, 0),
		Text = tostring(self.Value),
		TextColor3 = tokens.Text,
		PlaceholderText = "",
		Font = FONT,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		ClearTextOnFocus = false,
		Parent = frame,
	})
	RegisterTheme(valueBox, "BackgroundColor3", "SurfaceTertiary")
	RegisterTheme(valueBox, "TextColor3", "Text")
	Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = valueBox })
	Utility.Create("UIPadding", {
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		Parent = valueBox,
	})

	local minLbl = CreateLabel(frame, tostring(min), 11, "TextTertiary")
	minLbl.Size = UDim2.fromOffset(36, 14)
	minLbl.Position = UDim2.fromOffset(0, 34)
	minLbl.TextXAlignment = Enum.TextXAlignment.Left

	local maxLbl = CreateLabel(frame, tostring(max), 11, "TextTertiary")
	maxLbl.Size = UDim2.fromOffset(36, 14)
	maxLbl.Position = UDim2.new(1, -36, 0, 34)
	maxLbl.TextXAlignment = Enum.TextXAlignment.Right

	local track = Utility.Create("Frame", {
		BackgroundColor3 = tokens.SurfaceTertiary,
		Size = UDim2.new(1, -80, 0, 6),
		Position = UDim2.fromOffset(40, 38),
		Parent = frame,
	})
	RegisterTheme(track, "BackgroundColor3", "SurfaceTertiary")
	Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

	local fill = Utility.Create("Frame", {
		BackgroundColor3 = tokens.Accent,
		Size = UDim2.new((self.Value - min) / math.max(max - min, 1e-6), 0, 1, 0),
		Parent = track,
	})
	RegisterTheme(fill, "BackgroundColor3", "Accent")
	Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

	local knob = Utility.Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((self.Value - min) / math.max(max - min, 1e-6), 0, 0.5, 0),
		Parent = track,
		ZIndex = 3,
	})
	Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
	Utility.AddShadow(knob, { BlurRadius = 6, Transparency = 0.4, Offset = UDim2.fromOffset(0, 1) })

	local hit = Utility.Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.fromOffset(0, -7),
		Text = "",
		ZIndex = 4,
		Parent = track,
	})

	local dragging = false

	local function updateFromX(x)
		local ap = track.AbsolutePosition.X
		local as = track.AbsoluteSize.X
		if as < 1 then return end
		local rel = Utility.Clamp((x - ap) / as, 0, 1)
		local raw = min + (max - min) * rel
		self:Set(Utility.Clamp(Utility.Round(raw, rounding), min, max))
	end

	function self:Set(value: number, silent: boolean?)
		if self.Destroyed then return end
		value = Utility.Clamp(Utility.Round(value, rounding), min, max)
		if self.Value == value and valueBox.Text == tostring(value) then return end
		self.Value = value

		local pct = (value - min) / math.max(max - min, 1e-6)
		SpringTween(fill, { Size = UDim2.new(pct, 0, 1, 0) }, 10)
		SpringTween(knob, { Position = UDim2.new(pct, 0, 0.5, 0) }, 10)
		if not valueBox:IsFocused() then
			valueBox.Text = tostring(value)
		end

		if config.Flag and Library.Flags[config.Flag] then
			Library.Flags[config.Flag].Value = value
		end
		if not silent then
			Utility.SafeCallback(config.Callback, value)
			self.Changed:Fire(value)
		end
	end

	self.Maid:Give(valueBox.FocusLost:Connect(function()
		local n = tonumber(valueBox.Text)
		if n then
			self:Set(n)
		else
			valueBox.Text = tostring(self.Value)
		end
	end))

	self.Maid:Give(hit.InputBegan:Connect(function(input)
		if self.Disabled then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end))
	self.Maid:Give(UserInputService.InputChanged:Connect(function(input)
		if not dragging or self.Disabled then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			updateFromX(input.Position.X)
		end
	end))
	self.Maid:Give(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	if config.Tooltip then
		self.Maid:Give(BindTooltip(frame, function() return config.Tooltip end))
	end

	if self.Disabled then
		self:SetDisabled(true)
	end

	return self
end


local Dropdown = setmetatable({}, { __index = Component })
Dropdown.__index = Dropdown

function Dropdown.new(section, config: DropdownConfig)
	local self = Component.new(section, config)
	setmetatable(self, Dropdown)

	local multi = config.Multi == true
	local values = config.Values or {}
	self.Values = table.clone(values)

	if multi then
		self.Value = type(config.Default) == "table" and table.clone(config.Default) or {}
	else
		self.Value = config.Default or (values[1] or "")
	end

	if config.Flag then
		RegisterFlag(config.Flag, self, self.Value, config.Name, multi and "MultiDropdown" or "Dropdown")
	end

	local tokens = Library:GetTheme()
	local frame = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 52),
		Parent = section.Content,
	})
	self.Frame = frame
	self.Open = false

	local iconPad = 0
	if config.Icon then
		local ic = CreateIcon(frame, config.Icon, 16)
		ic.Position = UDim2.fromOffset(0, 4)
		iconPad = 22
		self._IconLabel = ic
	end
	local title = CreateLabel(frame, config.Name or "Dropdown", 14, "Text")
	title.Size = UDim2.new(1, -iconPad, 0, 18)
	title.Position = UDim2.fromOffset(iconPad, 2)
	self._TitleLabel = title

	local trigger = Utility.Create("TextButton", {
		Name = "Trigger",
		BackgroundColor3 = tokens.SurfaceSecondary,
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, 22),
		Text = "",
		AutoButtonColor = false,
		Parent = frame,
	})
	RegisterTheme(trigger, "BackgroundColor3", "SurfaceSecondary")
	Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = trigger })
	Utility.Create("UIStroke", {
		Color = tokens.Border,
		Thickness = 1,
		Parent = trigger,
	})

	local display = CreateLabel(trigger, multi and table.concat(self.Value, ", ") or tostring(self.Value), 13, "Text")
	display.Size = UDim2.new(1, -28, 1, 0)
	display.Position = UDim2.fromOffset(10, 0)
	display.TextTruncate = Enum.TextTruncate.AtEnd

	local chevron = Utility.Create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = "rbxassetid://71880540200693",
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(1, -22, 0.5, -7),
		ImageColor3 = tokens.TextSecondary,
		ScaleType = Enum.ScaleType.Fit,
		Parent = trigger,
	})
	RegisterTheme(chevron, "ImageColor3", "TextSecondary")

	local listFrame = nil

	local function refreshDisplay()
		if multi then
			display.Text = #self.Value > 0 and table.concat(self.Value, ", ") or "None"
		else
			display.Text = tostring(self.Value)
		end
	end

	local function closeList()
		if not listFrame then return end
		self.Open = false
		SpringTween(chevron, { Rotation = 0 }, 9)
		listFrame:Destroy()
		listFrame = nil
		frame.Size = UDim2.new(1, 0, 0, 52)
	end

	local function openList()
		if listFrame then return end
		self.Open = true
		SpringTween(chevron, { Rotation = 180 }, 9)

		local itemH = 28
		local maxH = math.min(#self.Values * itemH + 8, 180)
		frame.Size = UDim2.new(1, 0, 0, 52 + maxH + 4)

		listFrame = Utility.Create("Frame", {
			BackgroundColor3 = tokens.SurfaceSecondary,
			Size = UDim2.new(1, 0, 0, maxH),
			Position = UDim2.fromOffset(0, 54),
			ClipsDescendants = true,
			Parent = frame,
			ZIndex = 10,
		})
		RegisterTheme(listFrame, "BackgroundColor3", "SurfaceSecondary")
		Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = listFrame })
		Utility.Create("UIStroke", {
			Color = tokens.Border,
			Thickness = 1,
			Parent = listFrame,
		})
		Utility.AddShadow(listFrame, { BlurRadius = 12, Transparency = 0.5, Offset = UDim2.fromOffset(0, 4) })

		local scroll = Utility.Create("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.fromOffset(0, #self.Values * itemH),
			ScrollBarThickness = 0,
			BorderSizePixel = 0,
			Parent = listFrame,
		})
		Utility.Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = scroll,
		})

		for i, val in ipairs(self.Values) do
			local item = Utility.Create("TextButton", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, itemH),
				Text = "  " .. tostring(val),
				TextColor3 = tokens.Text,
				Font = FONT,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				LayoutOrder = i,
				Parent = scroll,
			})
			RegisterTheme(item, "TextColor3", "Text")

			local selected = multi and table.find(self.Value, val) or self.Value == val
			if selected then
				item.TextColor3 = tokens.Accent
			end

			self.Maid:Give(item.MouseEnter:Connect(function()
				item.BackgroundTransparency = 0.9
				item.BackgroundColor3 = tokens.SurfaceTertiary
			end))
			self.Maid:Give(item.MouseLeave:Connect(function()
				item.BackgroundTransparency = 1
			end))
			self.Maid:Give(item.Activated:Connect(function()
				if multi then
					local idx = table.find(self.Value, val)
					if idx then
						table.remove(self.Value, idx)
					else
						table.insert(self.Value, val)
					end
					self:Set(self.Value)
					closeList()
					openList()
				else
					self:Set(val)
					closeList()
				end
			end))
		end
	end

	function self:Set(value, silent)
		if self.Destroyed then return end
		if multi then
			self.Value = type(value) == "table" and value or {}
		else
			self.Value = value
		end
		refreshDisplay()
		if config.Flag and Library.Flags[config.Flag] then
			Library.Flags[config.Flag].Value = self.Value
		end
		if not silent then
			Utility.SafeCallback(config.Callback, self.Value)
			self.Changed:Fire(self.Value)
		end
	end

	function self:SetValues(newValues)
		self.Values = table.clone(newValues or {})
		if self.Open then
			closeList()
			openList()
		end
	end

	self.Maid:Give(trigger.Activated:Connect(function()
		if self.Open then closeList() else openList() end
	end))

	if config.Tooltip then
		self.Maid:Give(BindTooltip(trigger, function() return config.Tooltip end))
	end

	if self.Disabled then
		self:SetDisabled(true)
	end

	return self
end


local Input = setmetatable({}, { __index = Component })
Input.__index = Input

function Input.new(section, config: InputConfig)
	local self = Component.new(section, config)
	setmetatable(self, Input)

	self.Value = config.Default or ""
	if config.Flag then
		RegisterFlag(config.Flag, self, self.Value, config.Name, "Input")
	end

	local tokens = Library:GetTheme()
	local frame = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		Parent = section.Content,
	})
	self.Frame = frame

	local iconPad = 0
	if config.Icon then
		local ic = CreateIcon(frame, config.Icon, 16)
		ic.Position = UDim2.fromOffset(0, 10)
		iconPad = 22
		self._IconLabel = ic
	end

	local title = CreateLabel(frame, config.Name or "Input", 14, "Text")
	title.Size = UDim2.new(1, -(150 + iconPad), 1, 0)
	title.Position = UDim2.fromOffset(iconPad, 0)
	title.TextYAlignment = Enum.TextYAlignment.Center
	self._TitleLabel = title

	local box = Utility.Create("TextBox", {
		BackgroundColor3 = tokens.SurfaceTertiary,
		Size = UDim2.fromOffset(140, 26),
		Position = UDim2.new(1, -140, 0.5, -13),
		Text = self.Value,
		PlaceholderText = config.Placeholder or "",
		PlaceholderColor3 = tokens.TextTertiary,
		TextColor3 = tokens.Text,
		Font = FONT,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = config.ClearTextOnFocus == true,
		Parent = frame,
	})
	RegisterTheme(box, "BackgroundColor3", "SurfaceTertiary")
	RegisterTheme(box, "TextColor3", "Text")
	RegisterTheme(box, "PlaceholderColor3", "TextTertiary")
	Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = box })
	Utility.Create("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = box,
	})

	self.Maid:Give(box.Focused:Connect(function()
		local t = Library:GetTheme()
		SpringTween(box, { BackgroundColor3 = t.SurfaceSecondary }, 10)
	end))
	self.Maid:Give(box.FocusLost:Connect(function()
		local t = Library:GetTheme()
		SpringTween(box, { BackgroundColor3 = t.SurfaceTertiary }, 10)
		local text = box.Text
		if config.Numeric then
			text = tostring(tonumber(text) or self.Value)
			box.Text = text
		end
		self:Set(text)
	end))

	function self:Set(value: string, silent: boolean?)
		if self.Destroyed then return end
		value = tostring(value or "")
		self.Value = value
		box.Text = value
		if config.Flag and Library.Flags[config.Flag] then
			Library.Flags[config.Flag].Value = value
		end
		if not silent then
			Utility.SafeCallback(config.Callback, value)
			self.Changed:Fire(value)
		end
	end

	if config.Tooltip then
		self.Maid:Give(BindTooltip(frame, function() return config.Tooltip end))
	end

	if self.Disabled then
		self:SetDisabled(true)
	end

	return self
end


local Keybind = setmetatable({}, { __index = Component })
Keybind.__index = Keybind

local ListeningKeybind = nil

function Keybind.new(section, config: KeybindConfig)
	local self = Component.new(section, config)
	setmetatable(self, Keybind)

	self.Value = config.Default or Enum.KeyCode.Unknown
	self.Mode = config.Mode or "Toggle"
	self.Active = false
	if config.Flag then
		RegisterFlag(config.Flag, self, self.Value, config.Name, "Keybind")
	end

	local tokens = Library:GetTheme()
	local frame = CreateRow(section.Content, 40)
	self.Frame = frame

	local title = CreateLabel(frame, config.Name or "Keybind", 14, "Text")
	title.Size = UDim2.new(1, -90, 1, 0)

	local btn = Utility.Create("TextButton", {
		BackgroundColor3 = tokens.SurfaceSecondary,
		Size = UDim2.fromOffset(80, 26),
		Position = UDim2.new(1, -80, 0.5, -13),
		Text = self.Value.Name or "None",
		TextColor3 = tokens.Text,
		Font = FONT,
		TextSize = 12,
		AutoButtonColor = false,
		Parent = frame,
	})
	RegisterTheme(btn, "BackgroundColor3", "SurfaceSecondary")
	RegisterTheme(btn, "TextColor3", "Text")
	Utility.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })

	function self:Set(key, silent)
		if self.Destroyed then return end
		self.Value = key
		btn.Text = (key and key.Name) or "None"
		if config.Flag and Library.Flags[config.Flag] then
			Library.Flags[config.Flag].Value = key
		end
		if not silent then
			Utility.SafeCallback(config.Callback, key)
			self.Changed:Fire(key)
		end
	end

	self.Maid:Give(btn.Activated:Connect(function()
		if ListeningKeybind and ListeningKeybind ~= self then
			ListeningKeybind:_CancelListen()
		end
		ListeningKeybind = self
		btn.Text = "..."
		SpringTween(btn, { BackgroundColor3 = tokens.Accent }, 10)
	end))

	function self:_CancelListen()
		btn.Text = (self.Value and self.Value.Name) or "None"
		SpringTween(btn, { BackgroundColor3 = tokens.SurfaceSecondary }, 8)
		if ListeningKeybind == self then
			ListeningKeybind = nil
		end
	end

	self.Maid:Give(UserInputService.InputBegan:Connect(function(input, gp)
		if ListeningKeybind == self then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				self:Set(input.KeyCode)
				self:_CancelListen()
			elseif input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2 then
				self:Set(input.UserInputType)
				self:_CancelListen()
			end
			return
		end

		if self.Value and not gp then
			local match = (input.KeyCode == self.Value) or (input.UserInputType == self.Value)
			if match then
				if self.Mode == "Toggle" then
					self.Active = not self.Active
					Utility.SafeCallback(config.Callback, self.Value, self.Active)
				elseif self.Mode == "Hold" then
					self.Active = true
					Utility.SafeCallback(config.Callback, self.Value, true)
				else
					Utility.SafeCallback(config.Callback, self.Value)
				end
			end
		end
	end))

	self.Maid:Give(UserInputService.InputEnded:Connect(function(input)
		if self.Mode == "Hold" and self.Active then
			local match = (input.KeyCode == self.Value) or (input.UserInputType == self.Value)
			if match then
				self.Active = false
				Utility.SafeCallback(config.Callback, self.Value, false)
			end
		end
	end))

	if config.Tooltip then
		self.Maid:Give(BindTooltip(btn, function() return config.Tooltip end))
	end

	if self.Disabled then
		self:SetDisabled(true)
	end

	return self
end


local Label = setmetatable({}, { __index = Component })
Label.__index = Label

function Label.new(section, config)
	local self = Component.new(section, config or {})
	setmetatable(self, Label)
	config = config or {}
	local text = config.Text or config.Name or config.Title or ""
	local size = config.TextSize or 13
	local token = config.Color or "TextSecondary"
	if typeof(token) == "Color3" then
		token = nil
	end
	local frame = CreateRow(section.Content, config.Height or (size + 10))
	self.Frame = frame
	local lbl = CreateLabel(frame, text, size, token or "TextSecondary")
	lbl.Size = UDim2.new(1, -28, 1, 0)
	lbl.RichText = config.RichText == true
	if typeof(config.Color) == "Color3" then
		lbl.TextColor3 = config.Color
	end
	if config.Bold then
		lbl.Font = FONT_SEMIBOLD
	end
	self.Label = lbl
	self._TitleLabel = lbl

	function self:SetText(t)
		if self.Label then
			self.Label.Text = t or ""
		end
	end

	function self:SetColor(c)
		if self.Label and typeof(c) == "Color3" then
			self.Label.TextColor3 = c
		end
	end

	AttachLinkButton(self, frame, false)

	return self
end

local Paragraph = setmetatable({}, { __index = Component })
Paragraph.__index = Paragraph

function Paragraph.new(section, config)
	local self = Component.new(section, config or {})
	setmetatable(self, Paragraph)
	config = config or {}
	local title = config.Title or config.Name
	local text = config.Content or config.Text or ""
	local rich = config.RichText ~= false
	local textSize = config.TextSize or 13
	local iconName = config.Icon

	local frame = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = section.Content,
	})
	self.Frame = frame

	local iconPad = 0
	if iconName and iconName ~= "" then
		local ic = CreateIcon(frame, iconName, 16)
		ic.Position = UDim2.fromOffset(0, 2)
		ic.ImageColor3 = Library:GetTheme().TextSecondary
		ic.ZIndex = 2
		self.IconLabel = ic
		iconPad = 22
	end

	local y = 0
	if title then
		local titleLbl = CreateLabel(frame, title, 14, "Text")
		titleLbl.Size = UDim2.new(1, -iconPad, 0, 18)
		titleLbl.Position = UDim2.fromOffset(iconPad, 0)
		titleLbl.Font = FONT_SEMIBOLD
		titleLbl.RichText = rich
		titleLbl.TextTruncate = Enum.TextTruncate.None
		titleLbl.TextWrapped = false
		self.TitleLabel = titleLbl
		y = 20
	end

	local firstLine, rest = text, nil
	if not title then
		local nl = string.find(text, "\n", 1, true)
		if nl then
			firstLine = string.sub(text, 1, nl - 1)
			rest = string.sub(text, nl + 1)
		end
	end

	local contentLbl = CreateLabel(frame, firstLine, textSize, "TextSecondary")
	if title then
		contentLbl.Position = UDim2.fromOffset(0, y)
		contentLbl.Size = UDim2.new(1, 0, 0, 0)
	else
		contentLbl.Position = UDim2.fromOffset(iconPad, y)
		contentLbl.Size = UDim2.new(1, -iconPad, 0, 0)
	end
	contentLbl.AutomaticSize = Enum.AutomaticSize.Y
	contentLbl.TextWrapped = true
	contentLbl.TextYAlignment = Enum.TextYAlignment.Top
	contentLbl.TextTruncate = Enum.TextTruncate.None
	contentLbl.RichText = rich
	contentLbl.ClipsDescendants = false
	self.Label = contentLbl
	self.ContentLabel = contentLbl

	if rest and rest ~= "" then
		local restLbl = CreateLabel(frame, rest, textSize, "TextSecondary")
		restLbl.Position = UDim2.fromOffset(0, y + 18)
		restLbl.Size = UDim2.new(1, 0, 0, 0)
		restLbl.AutomaticSize = Enum.AutomaticSize.Y
		restLbl.TextWrapped = true
		restLbl.TextYAlignment = Enum.TextYAlignment.Top
		restLbl.TextTruncate = Enum.TextTruncate.None
		restLbl.RichText = rich
		restLbl.ClipsDescendants = false
		self._RestLabel = restLbl

		local function relayout()
			local h = math.max(contentLbl.TextBounds.Y, contentLbl.AbsoluteSize.Y, textSize + 2)
			restLbl.Position = UDim2.fromOffset(0, y + h + 2)
		end
		contentLbl:GetPropertyChangedSignal("TextBounds"):Connect(relayout)
		contentLbl:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
		task.defer(relayout)
	end

	self._TitleLabel = self.TitleLabel or contentLbl

	function self:SetText(t)
		t = t or ""
		if self._RestLabel and not self.TitleLabel then
			local nl = string.find(t, "\n", 1, true)
			if nl then
				self.Label.Text = string.sub(t, 1, nl - 1)
				self._RestLabel.Text = string.sub(t, nl + 1)
			else
				self.Label.Text = t
				self._RestLabel.Text = ""
			end
		elseif self.Label then
			self.Label.Text = t
		end
	end

	function self:SetContent(t)
		self:SetText(t)
	end

	function self:SetTitle(t)
		if self.TitleLabel then
			self.TitleLabel.Text = t or ""
		end
	end

	return self
end


local Divider = setmetatable({}, { __index = Component })
Divider.__index = Divider

function Divider.new(section, opts)
	opts = opts or {}
	local self = Component.new(section, opts)
	setmetatable(self, Divider)

	local tokens = Library:GetTheme()
	local height = opts.Text and 22 or 16
	local frame = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height),
		Parent = section.Content,
	})
	self.Frame = frame

	local line = Utility.Create("Frame", {
		BackgroundColor3 = tokens.Border,
		Size = UDim2.new(1, 0, 0, opts.Thickness or 1),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = frame,
	})
	RegisterTheme(line, "BackgroundColor3", "Border")

	if opts.Rounded then
		Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = line })
	end

	if opts.Fade then
		local grad = Utility.Create("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.2, 0),
				NumberSequenceKeypoint.new(0.8, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = line,
		})
	end

	if opts.Text and opts.Text ~= "" then
		local lbl = CreateLabel(frame, opts.Text, 11, "TextTertiary")
		lbl.Size = UDim2.fromOffset(0, 16)
		lbl.AutomaticSize = Enum.AutomaticSize.X
		lbl.AnchorPoint = Vector2.new(0.5, 0.5)
		lbl.Position = UDim2.fromScale(0.5, 0.5)
		lbl.BackgroundColor3 = tokens.Surface
		lbl.BackgroundTransparency = 0
		lbl.TextXAlignment = Enum.TextXAlignment.Center
		RegisterTheme(lbl, "BackgroundColor3", "Surface")
		Utility.Create("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			Parent = lbl,
		})
		line.Size = UDim2.new(1, 0, 0, opts.Thickness or 1)
	end

	return self
end

local Space = setmetatable({}, { __index = Component })
Space.__index = Space

function Space.new(section, opts)
	opts = opts or {}
	local self = Component.new(section, opts)
	setmetatable(self, Space)
	local size = opts.Size or 8
	local frame = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, size),
		Parent = section.Content,
	})
	self.Frame = frame
	return self
end

local ColorPicker = setmetatable({}, { __index = Component })
ColorPicker.__index = ColorPicker

function ColorPicker.new(section, config: ColorPickerConfig)
	local self = Component.new(section, config)
	setmetatable(self, ColorPicker)
	self.Value = config.Default or Color3.fromRGB(10, 132, 255)
	self.Alpha = config.Alpha or 1
	local h, s, v = self.Value:ToHSV()
	self._H, self._S, self._V = h, s, v
	self._DraftH, self._DraftS, self._DraftV = h, s, v
	if config.Flag then
		RegisterFlag(config.Flag, self, self.Value, config.Name, "ColorPicker")
	end

	local tokens = Library:GetTheme()
	local frame = CreateRow(section.Content, 40)
	self.Frame = frame

	local title = CreateLabel(frame, config.Name or "Color", 14, "Text")
	title.Size = UDim2.new(1, -44, 1, 0)
	self._TitleLabel = title

	local preview = Utility.Create("TextButton", {
		BackgroundColor3 = self.Value,
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -28, 0.5, -14),
		Text = "",
		AutoButtonColor = false,
		Parent = frame,
	})
	Utility.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = preview })
	Utility.Create("UIStroke", { Color = tokens.Border, Thickness = 1, Parent = preview })
	Utility.AddShadow(preview, { BlurRadius = 6, Transparency = 0.55, Offset = UDim2.fromOffset(0, 1) })
	self._Preview = preview

	function self:Set(color: Color3, silent: boolean?)
		if self.Destroyed then return end
		self.Value = color
		local nh, ns, nv = color:ToHSV()
		self._H, self._S, self._V = nh, ns, nv
		self._DraftH, self._DraftS, self._DraftV = nh, ns, nv
		preview.BackgroundColor3 = color
		if config.Flag and Library.Flags[config.Flag] then
			Library.Flags[config.Flag].Value = color
		end
		if not silent then
			Utility.SafeCallback(config.Callback, color, self.Alpha)
			self.Changed:Fire(color)
		end
	end

	function self:SetText(text: string)
		if self._TitleLabel then
			self._TitleLabel.Text = text or ""
		end
		self.Config.Name = text
	end

	local function openModal()
		if self.Disabled then return end
		local window = section.Tab and section.Tab.Window
		if not window or not window.Root then return end

		self._DraftH, self._DraftS, self._DraftV = self._H, self._S, self._V
		local tokens = Library:GetTheme()

		local overlay = Utility.Create("Frame", {
			Name = "ColorPickerModal",
			BackgroundColor3 = tokens.Overlay,
			BackgroundTransparency = 0.45,
			Size = UDim2.fromScale(1, 1),
			Parent = window.ScreenGui or window.Root,
			ZIndex = 200,
		})

		local modal = Utility.Create("Frame", {
			BackgroundColor3 = tokens.Surface,
			Size = UDim2.fromOffset(280, 280),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Parent = overlay,
			ZIndex = 51,
		})
		RegisterTheme(modal, "BackgroundColor3", "Surface")
		Utility.Create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = modal })
		local modalScale = Utility.Create("UIScale", { Scale = 1.08, Parent = modal })
		SpringTween(modalScale, { Scale = 1 }, 9)
		overlay.BackgroundTransparency = 1
		SpringTween(overlay, { BackgroundTransparency = 0.45 }, 8)
		Utility.Create("UIStroke", { Color = tokens.Border, Thickness = 1, Parent = modal })
		Utility.AddShadow(modal, {
			BlurRadius = 24,
			Transparency = 0.35,
			Offset = UDim2.fromOffset(0, 8),
		})
		Utility.Create("UIPadding", {
			PaddingTop = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 14),
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
			Parent = modal,
		})

		local header = CreateLabel(modal, config.Name or "Color", 15, "Text")
		header.Size = UDim2.new(1, 0, 0, 20)
		header.Font = FONT_SEMIBOLD

		local sat = Utility.Create("Frame", {
			BackgroundColor3 = Color3.fromHSV(self._DraftH, 1, 1),
			Size = UDim2.fromOffset(160, 140),
			Position = UDim2.fromOffset(0, 28),
			Parent = modal,
			ZIndex = 52,
			Active = true,
		})
		Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = sat })
		local satWhite = Utility.Create("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			Size = UDim2.fromScale(1, 1),
			Parent = sat,
			ZIndex = 52,
			Active = false,
		})
		Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = satWhite })
		Utility.Create("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = satWhite,
		})
		local satBlack = Utility.Create("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			Size = UDim2.fromScale(1, 1),
			Parent = sat,
			ZIndex = 53,
			Active = false,
		})
		Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = satBlack })
		Utility.Create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Parent = satBlack,
		})

		local satHit = Utility.Create("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			ZIndex = 60,
			AutoButtonColor = false,
			Parent = sat,
		})

		local cursor = Utility.Create("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			Size = UDim2.fromOffset(12, 12),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(self._DraftS, 1 - self._DraftV),
			ZIndex = 61,
			Parent = sat,
			Active = false,
		})
		pcall(function() cursor.Interactable = false end)
		Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = cursor })
		Utility.Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5, Parent = cursor })

		local hueBar = Utility.Create("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			Size = UDim2.fromOffset(18, 140),
			Position = UDim2.fromOffset(170, 28),
			Parent = modal,
			ZIndex = 52,
			Active = true,
		})
		Utility.Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = hueBar })
		Utility.Create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
				ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
				ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
				ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
				ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
				ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
			}),
			Parent = hueBar,
		})

		local hueHit = Utility.Create("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			ZIndex = 60,
			AutoButtonColor = false,
			Parent = hueBar,
		})

		local hueCursor = Utility.Create("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			Size = UDim2.new(1, 8, 0, 4),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, self._DraftH, 0),
			ZIndex = 61,
			Parent = hueBar,
			Active = false,
		})
		pcall(function() hueCursor.Interactable = false end)
		Utility.Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = hueCursor })
		Utility.Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = hueCursor })

		local previewBig = Utility.Create("Frame", {
			BackgroundColor3 = Color3.fromHSV(self._DraftH, self._DraftS, self._DraftV),
			Size = UDim2.fromOffset(48, 48),
			Position = UDim2.fromOffset(200, 28),
			Parent = modal,
			ZIndex = 52,
		})
		Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = previewBig })
		Utility.AddShadow(previewBig, { BlurRadius = 10, Transparency = 0.45, Offset = UDim2.fromOffset(0, 3) })

		local hexBox = Utility.Create("TextBox", {
			BackgroundColor3 = tokens.SurfaceSecondary,
			Size = UDim2.fromOffset(48, 22),
			Position = UDim2.fromOffset(200, 84),
			Text = string.format("%02X%02X%02X",
				math.floor(self.Value.R * 255),
				math.floor(self.Value.G * 255),
				math.floor(self.Value.B * 255)),
			TextColor3 = tokens.Text,
			Font = FONT,
			TextSize = 11,
			ClearTextOnFocus = false,
			Parent = modal,
			ZIndex = 52,
		})
		RegisterTheme(hexBox, "BackgroundColor3", "SurfaceSecondary")
		RegisterTheme(hexBox, "TextColor3", "Text")
		Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hexBox })

		local function refreshDraft()
			sat.BackgroundColor3 = Color3.fromHSV(self._DraftH, 1, 1)
			cursor.Position = UDim2.fromScale(self._DraftS, 1 - self._DraftV)
			hueCursor.Position = UDim2.new(0.5, 0, self._DraftH, 0)
			local c = Color3.fromHSV(self._DraftH, self._DraftS, self._DraftV)
			previewBig.BackgroundColor3 = c
			hexBox.Text = string.format("%02X%02X%02X",
				math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
		end

		local conns = {}

		local function updateSV()
			local ap = sat.AbsolutePosition
			local as = sat.AbsoluteSize
			if as.X < 1 or as.Y < 1 then return end
			local m = UserInputService:GetMouseLocation()
			local x = math.clamp(m.X, ap.X, ap.X + as.X)
			local y = math.clamp(m.Y, ap.Y, ap.Y + as.Y)
			self._DraftS = (x - ap.X) / as.X
			self._DraftV = 1 - ((y - ap.Y) / as.Y)
			refreshDraft()
		end

		local function updateH()
			local ap = hueBar.AbsolutePosition
			local as = hueBar.AbsoluteSize
			if as.Y < 1 then return end
			local m = UserInputService:GetMouseLocation()
			local y = math.clamp(m.Y, ap.Y, ap.Y + as.Y)
			self._DraftH = (y - ap.Y) / as.Y
			refreshDraft()
		end

		table.insert(conns, satHit.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			updateSV()
			local move
			move = RunService.RenderStepped:Connect(function()
				if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
					or #UserInputService:GetTouches() > 0 then
					updateSV()
				else
					move:Disconnect()
				end
			end)
			table.insert(conns, move)
		end))

		table.insert(conns, hueHit.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			updateH()
			local move
			move = RunService.RenderStepped:Connect(function()
				if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
					or #UserInputService:GetTouches() > 0 then
					updateH()
				else
					move:Disconnect()
				end
			end)
			table.insert(conns, move)
		end))
		table.insert(conns, hexBox.FocusLost:Connect(function()
			local hex = hexBox.Text:gsub("#", "")
			if #hex == 6 then
				local r = tonumber(hex:sub(1, 2), 16)
				local g = tonumber(hex:sub(3, 4), 16)
				local b = tonumber(hex:sub(5, 6), 16)
				if r and g and b then
					local nh, ns, nv = Color3.fromRGB(r, g, b):ToHSV()
					self._DraftH, self._DraftS, self._DraftV = nh, ns, nv
					refreshDraft()
				end
			end
		end))

		local btnRow = Utility.Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 34),
			Position = UDim2.fromOffset(0, 180),
			Parent = modal,
			ZIndex = 52,
		})
		Utility.Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 10),
			Parent = btnRow,
		})

		local function cleanup()
			for _, c in ipairs(conns) do
				c:Disconnect()
			end
			overlay:Destroy()
		end

		local cancelBtn = Utility.Create("TextButton", {
			BackgroundColor3 = tokens.SurfaceSecondary,
			Size = UDim2.fromOffset(90, 32),
			Text = "Cancel",
			TextColor3 = tokens.Text,
			Font = FONT_SEMIBOLD,
			TextSize = 13,
			AutoButtonColor = false,
			Parent = btnRow,
			ZIndex = 53,
		})
		RegisterTheme(cancelBtn, "BackgroundColor3", "SurfaceSecondary")
		RegisterTheme(cancelBtn, "TextColor3", "Text")
		Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = cancelBtn })
		cancelBtn.Activated:Connect(function()
			cleanup()
		end)

		local confirmBtn = Utility.Create("TextButton", {
			BackgroundColor3 = tokens.Accent,
			Size = UDim2.fromOffset(90, 32),
			Text = "Confirm",
			TextColor3 = Color3.new(1, 1, 1),
			Font = FONT_SEMIBOLD,
			TextSize = 13,
			AutoButtonColor = false,
			Parent = btnRow,
			ZIndex = 53,
		})
		RegisterTheme(confirmBtn, "BackgroundColor3", "Accent")
		Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = confirmBtn })
		confirmBtn.Activated:Connect(function()
			local color = Color3.fromHSV(self._DraftH, self._DraftS, self._DraftV)
			self:Set(color)
			cleanup()
		end)
	end

	self.Maid:Give(preview.Activated:Connect(function()
		openModal()
	end))

	if config.Tooltip then
		self.Maid:Give(BindTooltip(preview, function() return config.Tooltip end))
	end

	if self.Disabled then
		self:SetDisabled(true)
	end

	return self
end



local Header = setmetatable({}, { __index = Component })
Header.__index = Header

function Header.new(parentContent, config)
	config = config or {}
	if type(config) == "string" then
		config = { Text = config }
	end
	local self = setmetatable({}, Header)
	self.Config = config
	self.Maid = Maid.new()
	self.Destroyed = false
	self.Components = {}

	local text = config.Text or config.Name or config.Title or "Header"
	local tokens = Library:GetTheme()
	local frame = Utility.Create("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, config.Height or 28),
		Parent = parentContent,
	})
	self.Frame = frame

	local pad = 0
	if config.Icon then
		local ic = CreateIcon(frame, config.Icon, 16)
		ic.Position = UDim2.fromOffset(0, 6)
		ic.ImageColor3 = tokens.Text
		RegisterTheme(ic, "ImageColor3", "Text")
		self.IconLabel = ic
		pad = 22
	end

	local lbl = CreateLabel(frame, text, config.TextSize or 15, "Text")
	lbl.Size = UDim2.new(1, -pad, 1, 0)
	lbl.Position = UDim2.fromOffset(pad, 0)
	lbl.Font = FONT_SEMIBOLD
	lbl.RichText = config.RichText == true
	self.Label = lbl
	self._TitleLabel = lbl

	function self:SetText(t)
		if self.Label then self.Label.Text = t or "" end
	end

	return self
end



Section = {}
Section.__index = Section

function Section.new(tab, config: SectionConfig)
	local self = setmetatable({}, Section)
	self.Tab = tab
	self.Name = config.Name or "Section"
	self.Type = (config.Type or "full"):lower()
	if self.Type ~= "left" and self.Type ~= "right" and self.Type ~= "full" then
		self.Type = "full"
	end
	self.Components = {}
	self.Maid = Maid.new()
	self.Destroyed = false
	self.Collapsed = false

	local tokens = Library:GetTheme()
	local collapseCfg = config.Collapse or {}
	local collapseEnabled = collapseCfg.Enabled == true
	local startCollapsed = collapseCfg.Default == true


	local parentContainer
	if self.Type == "left" then
		parentContainer = tab.LeftColumn
	elseif self.Type == "right" then
		parentContainer = tab.RightColumn
	else
		parentContainer = tab.Content
	end

	local container = Utility.Create("Frame", {
		Name = "Section_" .. self.Name,
		BackgroundColor3 = tokens.Surface,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parentContainer,
	})
	RegisterTheme(container, "BackgroundColor3", "Surface")
	Utility.Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = container })
	Utility.Create("UIStroke", {
		Color = tokens.Border,
		Thickness = 1,
		Parent = container,
	})
	Utility.AddShadow(container, {
		BlurRadius = 10,
		Transparency = 0.65,
		Offset = UDim2.fromOffset(0, 2),
	})
	Utility.Create("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		Parent = container,
	})

	local layout = Utility.Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = container,
	})


	local headerBtn = Utility.Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = 0,
		Parent = container,
	})

	self.Icon = config.Icon
	local iconPad = 0
	if self.Icon then
		local secIcon = CreateIcon(headerBtn, self.Icon, 15)
		secIcon.Position = UDim2.fromOffset(0, 3)
		secIcon.ImageColor3 = tokens.Text
		RegisterTheme(secIcon, "ImageColor3", "Text")
		self.IconLabel = secIcon
		iconPad = 22
	end

	local header = CreateLabel(headerBtn, self.Name, 13, "TextSecondary")
	header.Size = UDim2.new(1, -(iconPad + (collapseEnabled and 24 or 0)), 1, 0)
	header.Position = UDim2.fromOffset(iconPad, 0)
	header.Font = FONT_SEMIBOLD
	header.TextXAlignment = Enum.TextXAlignment.Left
	self.Header = header

	local chevron
	if collapseEnabled then
		chevron = CreateIcon(headerBtn, "chevron", 14)
		chevron.Position = UDim2.new(1, -16, 0.5, -7)
		chevron.Rotation = startCollapsed and -90 or 0
	end


	local contentHolder = Utility.Create("Frame", {
		Name = "ContentHolder",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Visible = not startCollapsed,
		Parent = container,
	})
	local contentPad = 6
	local win = tab.Window
	if win and win.ElementsRow and win.ElementsRow.Enabled then
		contentPad = 0
	end
	Utility.Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, contentPad),
		Parent = contentHolder,
	})

	self.Frame = container
	self.Content = contentHolder
	self.Header = header
	self.Collapsed = startCollapsed

	if collapseEnabled then
		self.Maid:Give(headerBtn.Activated:Connect(function()
			self:SetCollapsed(not self.Collapsed)
		end))
	end

	function self:SetCollapsed(collapsed: boolean)
		if not collapseEnabled then return end
		self.Collapsed = collapsed
		contentHolder.Visible = not collapsed
		if chevron then
			SpringTween(chevron, { Rotation = collapsed and -90 or 0 }, 9)
		end
	end

	function self:ToggleCollapse()
		self:SetCollapsed(not self.Collapsed)
	end

	function self:SetName(name: string)
		self.Name = name or self.Name
		if self.Header then
			self.Header.Text = self.Name
		end
	end

	function self:GetName()
		return self.Name
	end

	function self:SetVisible(v: boolean)
		if self.Frame then
			self.Frame.Visible = v
		end
	end

	if config.Tooltip then
		self.Maid:Give(BindTooltip(headerBtn, function() return config.Tooltip end))
	end

	return self
end

local function InsertElementRowDivider(section)
	local tab = section.Tab
	local window = tab and tab.Window
	local er = window and window.ElementsRow
	if not er or er.Enabled ~= true then
		return
	end
	if not section.Content then
		return
	end
	if #(section.Components or {}) == 0 then
		return
	end

	local tokens = Library:GetTheme()
	local dtype = string.lower(tostring(er.Type or "thin"))
	local height = (dtype == "thick") and 10 or 1
	local holder = Utility.Create("Frame", {
		Name = "ElementRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height),
		Parent = section.Content,
	})

	if dtype == "fade" then
		local line = Utility.Create("Frame", {
			BackgroundColor3 = tokens.Border,
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.fromOffset(0, 0),
			BorderSizePixel = 0,
			Parent = holder,
		})
		RegisterTheme(line, "BackgroundColor3", "Border")
		local g = Utility.Create("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.15, 0.55),
				NumberSequenceKeypoint.new(0.5, 0.35),
				NumberSequenceKeypoint.new(0.85, 0.55),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = line,
		})
	elseif dtype == "thick" then
		local line = Utility.Create("Frame", {
			BackgroundColor3 = tokens.Border,
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 0.5, 0),
			BorderSizePixel = 0,
			Parent = holder,
		})
		RegisterTheme(line, "BackgroundColor3", "Border")
		line.BackgroundTransparency = 0.25
	else
		local line = Utility.Create("Frame", {
			BackgroundColor3 = tokens.Border,
			Size = UDim2.new(1, 0, 0, 1),
			BorderSizePixel = 0,
			BackgroundTransparency = 0.45,
			Parent = holder,
		})
		RegisterTheme(line, "BackgroundColor3", "Border")
	end
end


local function ResetButtonRow(section)
	section._ButtonRow = nil
	section._ButtonRowCount = 0
	section._ButtonSlots = nil
end

function Section:AddButton(config)
	if type(config) == "string" then
		config = { Name = config }
	end
	config = config or {}
	ResetButtonRow(self)
	InsertElementRowDivider(self)
	local c = Button.new(self, config)
	table.insert(self.Components, c)
	return c
end

function Section:AddToggle(config)
	ResetButtonRow(self)
	InsertElementRowDivider(self)
	local c = Toggle.new(self, config)
	table.insert(self.Components, c)
	return c
end

function Section:AddSlider(config)
	ResetButtonRow(self)
	InsertElementRowDivider(self)
	local c = Slider.new(self, config)
	table.insert(self.Components, c)
	return c
end

function Section:AddDropdown(config)
	ResetButtonRow(self)
	InsertElementRowDivider(self)
	local c = Dropdown.new(self, config)
	table.insert(self.Components, c)
	return c
end

function Section:AddMultiDropdown(config)
	config = config or {}
	config.Multi = true
	return self:AddDropdown(config)
end

function Section:AddInput(config)
	ResetButtonRow(self)
	InsertElementRowDivider(self)
	local c = Input.new(self, config)
	table.insert(self.Components, c)
	return c
end

function Section:AddKeybind(config)
	ResetButtonRow(self)
	InsertElementRowDivider(self)
	local c = Keybind.new(self, config)
	table.insert(self.Components, c)
	return c
end

function Section:AddLabel(config)
	if type(config) == "string" then
		config = { Text = config }
	end
	ResetButtonRow(self)
	InsertElementRowDivider(self)
	local c = Label.new(self, config or {})
	table.insert(self.Components, c)
	return c
end

function Section:AddHeader(config)
	if type(config) == "string" then
		config = { Text = config }
	end
	ResetButtonRow(self)
	InsertElementRowDivider(self)
	local c = Header.new(self.Content, config or {})
	table.insert(self.Components, c)
	return c
end

function Section:AddParagraph(config)
	if type(config) == "string" then
		config = { Text = config, RichText = true }
	end
	ResetButtonRow(self)
	InsertElementRowDivider(self)
	local c = Paragraph.new(self, config or {})
	table.insert(self.Components, c)
	return c
end

function Section:AddDivider(opts)
	ResetButtonRow(self)
	InsertElementRowDivider(self)
	local c = Divider.new(self, type(opts) == "table" and opts or {})
	table.insert(self.Components, c)
	return c
end

function Section:AddSpace(sizeOrOpts)
	InsertElementRowDivider(self)
	ResetButtonRow(self)
	local opts = type(sizeOrOpts) == "number" and { Size = sizeOrOpts } or (sizeOrOpts or {})
	local c = Space.new(self, opts)
	table.insert(self.Components, c)
	return c
end

function Section:AddColorPicker(config)
	ResetButtonRow(self)
	InsertElementRowDivider(self)
	local c = ColorPicker.new(self, config)
	table.insert(self.Components, c)
	return c
end

function Section:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	for _, c in ipairs(self.Components) do
		c:Destroy()
	end
	self.Maid:Destroy()
	if self.Frame then
		self.Frame:Destroy()
	end
end


Tab = {}
Tab.__index = Tab

function Tab.new(window, config)
	local self = setmetatable({}, Tab)
	self.Window = window
	self.Name = config.Name or "Tab"
	self.Icon = config.Icon
	self.Tooltip = config.Tooltip
	self.Sections = {}
	self.Maid = Maid.new()
	self.Destroyed = false
	self.Active = false

	local tokens = Library:GetTheme()
	local compact = window.CompactTab == true

	local btn = Utility.Create("TextButton", {
		Name = "TabBtn_" .. self.Name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, compact and -6 or -16, 0, compact and 52 or 36),
		Position = UDim2.fromOffset(compact and 3 or 8, 0),
		Text = "",
		AutoButtonColor = false,
		Parent = config.SidebarParent or window.SidebarList,
	})
	self.Button = btn

	local accentBar = Utility.Create("Frame", {
		BackgroundColor3 = tokens.Accent,
		Size = UDim2.fromOffset(3, 20),
		Position = UDim2.fromOffset(0, 8),
		Visible = false,
		Parent = btn,
	})
	RegisterTheme(accentBar, "BackgroundColor3", "Accent")
	Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = accentBar })
	self.AccentBar = accentBar

	if self.Icon then
		local icon = CreateIcon(btn, self.Icon, compact and 26 or 16)
		if compact then
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Position = UDim2.fromScale(0.5, 0.5)
		else
			icon.Position = UDim2.fromOffset(12, 10)
		end
		self.IconLabel = icon
	end

	local lbl = CreateLabel(btn, self.Name, 14, "TextSecondary")
	lbl.Size = UDim2.new(1, -40, 1, 0)
	lbl.Position = UDim2.fromOffset(self.Icon and 36 or 12, 0)
	lbl.Visible = not compact
	self.Label = lbl


	local page = Utility.Create("ScrollingFrame", {
		Name = "Page_" .. self.Name,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ScrollBarImageColor3 = tokens.Border,
		BorderSizePixel = 0,
		Visible = false,
		Parent = window.ContentContainer,
	})
	RegisterTheme(page, "ScrollBarImageColor3", "Border")
	Utility.Create("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = page,
	})


	local mainLayout = Utility.Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, SECTION_GAP),
		Parent = page,
	})


	local fullContainer = Utility.Create("Frame", {
		Name = "FullContainer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Parent = page,
	})
	Utility.Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, SECTION_GAP),
		Parent = fullContainer,
	})
	self.Content = fullContainer


	local columnsRow = Utility.Create("Frame", {
		Name = "ColumnsRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Parent = page,
	})
	Utility.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, SECTION_GAP),
		Parent = columnsRow,
	})

	local leftCol = Utility.Create("Frame", {
		Name = "LeftColumn",
		BackgroundTransparency = 1,
		Size = UDim2.new(0.5, -SECTION_GAP / 2, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Parent = columnsRow,
	})
	Utility.Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, SECTION_GAP),
		Parent = leftCol,
	})
	self.LeftColumn = leftCol

	local rightCol = Utility.Create("Frame", {
		Name = "RightColumn",
		BackgroundTransparency = 1,
		Size = UDim2.new(0.5, -SECTION_GAP / 2, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Parent = columnsRow,
	})
	Utility.Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, SECTION_GAP),
		Parent = rightCol,
	})
	self.RightColumn = rightCol

	self.Page = page

	self.Maid:Give(btn.Activated:Connect(function()
		window:SelectTab(self)
	end))

	self.Maid:Give(btn.MouseEnter:Connect(function()
		if not self.Active then
			SpringTween(lbl, { TextColor3 = tokens.Text }, 10)
		end
	end))
	self.Maid:Give(btn.MouseLeave:Connect(function()
		if not self.Active then
			SpringTween(lbl, { TextColor3 = tokens.TextSecondary }, 10)
		end
	end))


	if self.Tooltip then
		self.Maid:Give(BindTooltip(btn, function() return self.Tooltip end))
	end

	return self
end

function Tab:SetActive(active: boolean)
	self.Active = active
	local tokens = Library:GetTheme()
	if self.Page then
		self.Page.Visible = active
		if active then
			self.Page.CanvasPosition = Vector2.zero
		end
	end
	if self.AccentBar then
		self.AccentBar.Visible = active
		if active then
			self.AccentBar.Size = UDim2.fromOffset(3, 8)
			SpringTween(self.AccentBar, { Size = UDim2.fromOffset(3, 20) }, 10)
		end
	end
	if self.Label then
		SpringTween(self.Label, { TextColor3 = active and tokens.Text or tokens.TextSecondary }, 10)
	end
	if self.IconLabel then
		SpringTween(self.IconLabel, { ImageColor3 = active and tokens.Accent or tokens.TextSecondary }, 10)
	end
	if self.Button then
		if active then
			self.Button.BackgroundColor3 = tokens.SurfaceSecondary
			SpringTween(self.Button, { BackgroundTransparency = 0.92 }, 10)
		else
			SpringTween(self.Button, { BackgroundTransparency = 1 }, 10)
		end
	end
end

function Tab:AddSection(config)
	local sec = Section.new(self, config or {})
	table.insert(self.Sections, sec)
	return sec
end

function Tab:SetName(name: string)
	self.Name = name or self.Name
	if self.Label then
		self.Label.Text = self.Name
	end
end

function Tab:SetIcon(icon: string)
	self.Icon = icon
	if self.IconLabel then
		self.IconLabel.Image = ResolveIcon(icon) or ""
	end
end

function Tab:SetVisible(v: boolean)
	if self.Button then
		self.Button.Visible = v
	end
	if not v and self.Active and self.Window then
		for _, t in ipairs(self.Window.Tabs) do
			if t ~= self and t.Button and t.Button.Visible then
				self.Window:SelectTab(t)
				break
			end
		end
	end
end

function Tab:GetName()
	return self.Name
end


function Tab:AddToggle(config)
	local sec = self.Sections[#self.Sections]
	if not sec then sec = self:AddSection({ Name = "General" }) end
	return sec:AddToggle(config)
end
function Tab:AddButton(config)
	local sec = self.Sections[#self.Sections]
	if not sec then sec = self:AddSection({ Name = "General" }) end
	return sec:AddButton(config)
end
function Tab:AddSlider(config)
	local sec = self.Sections[#self.Sections]
	if not sec then sec = self:AddSection({ Name = "General" }) end
	return sec:AddSlider(config)
end
function Tab:AddDropdown(config)
	local sec = self.Sections[#self.Sections]
	if not sec then sec = self:AddSection({ Name = "General" }) end
	return sec:AddDropdown(config)
end
function Tab:AddMultiDropdown(config)
	local sec = self.Sections[#self.Sections]
	if not sec then sec = self:AddSection({ Name = "General" }) end
	return sec:AddMultiDropdown(config)
end
function Tab:AddInput(config)
	local sec = self.Sections[#self.Sections]
	if not sec then sec = self:AddSection({ Name = "General" }) end
	return sec:AddInput(config)
end
function Tab:AddKeybind(config)
	local sec = self.Sections[#self.Sections]
	if not sec then sec = self:AddSection({ Name = "General" }) end
	return sec:AddKeybind(config)
end
function Tab:AddLabel(config)
	local sec = self.Sections[#self.Sections]
	if not sec then sec = self:AddSection({ Name = "General" }) end
	return sec:AddLabel(config)
end

function Tab:AddHeader(config)
	if type(config) == "string" then
		config = { Text = config }
	end
	local c = Header.new(self.Content, config or {})
	return c
end
function Tab:AddParagraph(config)
	local sec = self.Sections[#self.Sections]
	if not sec then sec = self:AddSection({ Name = "General" }) end
	return sec:AddParagraph(config)
end
function Tab:AddDivider(opts)
	local host = { Content = self.Content, Components = {}, _ButtonRow = nil, _ButtonRowCount = 0 }
	return Divider.new(host, type(opts) == "table" and opts or {})
end
function Tab:AddSpace(sizeOrOpts)
	local host = { Content = self.Content, Components = {}, _ButtonRow = nil, _ButtonRowCount = 0 }
	local opts = type(sizeOrOpts) == "number" and { Size = sizeOrOpts } or (sizeOrOpts or {})
	return Space.new(host, opts)
end
function Tab:AddColorPicker(config)
	local sec = self.Sections[#self.Sections]
	if not sec then sec = self:AddSection({ Name = "General" }) end
	return sec:AddColorPicker(config)
end
function Tab:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	for _, s in ipairs(self.Sections) do
		s:Destroy()
	end
	self.Maid:Destroy()
	if self.Button then self.Button:Destroy() end
	if self.Page then self.Page:Destroy() end
end


local function CreateNotification(config)
	local tokens = Library:GetTheme()
	local duration = config.Duration or 4
	local nType = config.Type or "Info"

	local colorMap = {
		Info    = tokens.Accent,
		Success = tokens.Success,
		Warning = tokens.Warning,
		Error   = tokens.Danger,
	}
	local accent = colorMap[nType] or tokens.Accent

	local gui = Utility.Create("Frame", {
		Name = "Notification",
		BackgroundColor3 = tokens.Surface,
		Size = UDim2.fromOffset(320, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -20, 0, 20),
		Parent = Library._NotificationHolder,
		ZIndex = 100,
	})
	RegisterTheme(gui, "BackgroundColor3", "Surface")
	Utility.Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = gui })
	Utility.Create("UIStroke", {
		Color = tokens.Border,
		Thickness = 1,
		Parent = gui,
	})
	Utility.AddShadow(gui, {
		BlurRadius = 16,
		Transparency = 0.4,
		Offset = UDim2.fromOffset(0, 6),
	})
	Utility.Create("UIPadding", {
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		Parent = gui,
	})

	local bar = Utility.Create("Frame", {
		BackgroundColor3 = accent,
		Size = UDim2.fromOffset(4, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(0, 0),
		Parent = gui,
	})
	Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })

	local title = CreateLabel(gui, config.Title or "Notification", 14, "Text")
	title.Size = UDim2.new(1, -20, 0, 18)
	title.Font = FONT_SEMIBOLD
	title.Position = UDim2.fromOffset(12, 0)

	if config.Description then
		local desc = CreateLabel(gui, config.Description, 12, "TextSecondary")
		desc.Size = UDim2.new(1, -12, 0, 0)
		desc.AutomaticSize = Enum.AutomaticSize.Y
		desc.Position = UDim2.fromOffset(12, 22)
		desc.TextWrapped = true
	end

	gui.Position = UDim2.new(1, 40, 0, 20)
	SpringTween(gui, { Position = UDim2.new(1, -20, 0, 20 + (#Library.Notifications * 90)) }, 7)

	table.insert(Library.Notifications, gui)

	task.delay(duration, function()
		if gui and gui.Parent then
			local tw = SpringTween(gui, { Position = UDim2.new(1, 40, 0, gui.Position.Y.Offset) }, 7)
			tw.Completed:Wait()
			gui:Destroy()
			local idx = table.find(Library.Notifications, gui)
			if idx then table.remove(Library.Notifications, idx) end
		end
	end)

	return gui
end


local function CreateModal(window, config)
	local tokens = Library:GetTheme()

	local overlay = Utility.Create("Frame", {
		Name = "ModalOverlay",
		BackgroundColor3 = tokens.Overlay,
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		Parent = window.Root,
		ZIndex = 50,
	})

	local modal = Utility.Create("Frame", {
		BackgroundColor3 = tokens.Surface,
		Size = UDim2.fromOffset(360, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = overlay,
		ZIndex = 51,
	})
	RegisterTheme(modal, "BackgroundColor3", "Surface")
	Utility.Create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = modal })
	Utility.Create("UIStroke", {
		Color = tokens.Border,
		Thickness = 1,
		Parent = modal,
	})
	Utility.AddShadow(modal, {
		BlurRadius = 24,
		Transparency = 0.35,
		Offset = UDim2.fromOffset(0, 8),
	})
	Utility.Create("UIPadding", {
		PaddingTop = UDim.new(0, 20),
		PaddingBottom = UDim.new(0, 16),
		PaddingLeft = UDim.new(0, 20),
		PaddingRight = UDim.new(0, 20),
		Parent = modal,
	})

	local title = CreateLabel(modal, config.Title or "Confirm", 16, "Text")
	title.Size = UDim2.new(1, 0, 0, 22)
	title.Font = FONT_BOLD

	if config.Description then
		local desc = CreateLabel(modal, config.Description, 13, "TextSecondary")
		desc.Size = UDim2.new(1, 0, 0, 0)
		desc.AutomaticSize = Enum.AutomaticSize.Y
		desc.Position = UDim2.fromOffset(0, 28)
		desc.TextWrapped = true
	end

	local btnRow = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.fromOffset(0, config.Description and 70 or 40),
		Parent = modal,
	})
	Utility.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 10),
		Parent = btnRow,
	})

	local function close()
		overlay:Destroy()
	end

	for _, bcfg in ipairs(config.Buttons or {}) do
		local isPrimary = bcfg.Primary == true
		local b = Utility.Create("TextButton", {
			BackgroundColor3 = isPrimary and tokens.Accent or tokens.SurfaceSecondary,
			Size = UDim2.fromOffset(90, 32),
			Text = bcfg.Name or "OK",
			TextColor3 = isPrimary and Color3.new(1, 1, 1) or tokens.Text,
			Font = FONT_SEMIBOLD,
			TextSize = 13,
			AutoButtonColor = false,
			Parent = btnRow,
		})
		if isPrimary then
			RegisterTheme(b, "BackgroundColor3", "Accent")
		else
			RegisterTheme(b, "BackgroundColor3", "SurfaceSecondary")
			RegisterTheme(b, "TextColor3", "Text")
		end
		Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = b })
		b.Activated:Connect(function()
			Utility.SafeCallback(bcfg.Callback)
			close()
		end)
	end

	return overlay
end


Window = {}
Window.__index = Window

function Window.new(library, config: WindowConfig)
	local self = setmetatable({}, Window)
	self.Library = library
	self.Config = config or {}
	self.Tabs = {}
	self.Maid = Maid.new()
	self.Destroyed = false
	self.Minimized = false
	self.DPI = 1
	self.SearchEnabled = false
	self.CompactTab = config.CompactTab == true
	local er = config.ElementsRow
	if type(er) == "boolean" then
		er = { Enabled = er, Type = "thin" }
	elseif type(er) ~= "table" then
		er = { Enabled = false, Type = "thin" }
	end
	self.ElementsRow = {
		Enabled = er.Enabled == true,
		Type = tostring(er.Type or "thin"):lower(),
	}
	self.CurrentTab = nil

	local tokens = library:GetTheme()
	local size = config.Size or UDim2.fromOffset(720, 480)
	local minSize = config.MinSize or Vector2.new(480, 320)

	local screenGui = Utility.Create("ScreenGui", {
		Name = "LibraryUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 100,
	})
	SafeProtect(screenGui)
	local uiParent = SafeParent()
	if not uiParent then
		warn("[Library] Failed to find UI parent (PlayerGui/CoreGui)")
		return nil
	end
	screenGui.Parent = uiParent
	self.ScreenGui = screenGui

	local uiScale = Utility.Create("UIScale", {
		Scale = 1,
		Parent = screenGui,
	})
	self.UIScale = uiScale

	local root = Utility.Create("Frame", {
		Name = "Window",
		BackgroundTransparency = 1,
		Size = size,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = screenGui,
	})
	self.Root = root


	local surface = Utility.Create("Frame", {
		Name = "Surface",
		BackgroundColor3 = tokens.Background,
		Size = UDim2.fromScale(1, 1),
		Parent = root,
		ClipsDescendants = true,
	})
	RegisterTheme(surface, "BackgroundColor3", "Background")
	Utility.Create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = surface })
	Utility.Create("UIStroke", {
		Color = tokens.Border,
		Thickness = 1,
		Parent = surface,
	})
	Utility.AddShadow(surface, {
		BlurRadius = 28,
		Transparency = 0.4,
		Offset = UDim2.fromOffset(0, 10),
		Spread = UDim2.fromOffset(4, 4),
	})
	self.Surface = surface


	local header = Utility.Create("Frame", {
		Name = "Header",
		BackgroundColor3 = tokens.Surface,
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		BorderSizePixel = 0,
		Parent = surface,
	})
	
	Utility.Create("UICorner", { TopLeftRadius = UDim.new(0, 14), TopRightRadius = UDim.new(0, 14), BottomLeftRadius = UDim.new(0, 0), BottomRightRadius = UDim.new(0, 0), Parent = header })
	RegisterTheme(header, "BackgroundColor3", "Surface")
	self.Header = header


	local lights = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(70, 14),
		Position = UDim2.fromOffset(14, 17),
		Parent = header,
	})
	Utility.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		Parent = lights,
	})

	local function makeLight(color, callback)
		local l = Utility.Create("TextButton", {
			BackgroundColor3 = color,
			Size = UDim2.fromOffset(12, 12),
			Text = "",
			AutoButtonColor = false,
			Parent = lights,
		})
		Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = l })
		Utility.AddShadow(l, {
			BlurRadius = 4,
			Transparency = 0.35,
			Offset = UDim2.fromOffset(0, 1),
			Color = color,
		})
		l.Activated:Connect(callback)
		return l
	end

	makeLight(Color3.fromRGB(255, 95, 87), function() self:Destroy() end)
	makeLight(Color3.fromRGB(255, 189, 46), function() self:Minimize() end)
	makeLight(Color3.fromRGB(40, 200, 64), function() end)


	local titleX = 90
	if config.Icon then
		local winIcon = CreateIcon(header, config.Icon, 20)
		winIcon.Position = UDim2.fromOffset(90, 14)
		winIcon.ImageColor3 = tokens.Text
		RegisterTheme(winIcon, "ImageColor3", "Text")
		self.IconLabel = winIcon
		titleX = 118
	end

	local titleLbl = CreateLabel(header, config.Title or "Window", 17, "Text")
	titleLbl.Size = UDim2.new(1, -(titleX + 90), 0, 22)
	titleLbl.Position = UDim2.fromOffset(titleX, 6)
	titleLbl.Font = FONT_SEMIBOLD
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	self.TitleLabel = titleLbl

	local subLbl = CreateLabel(header, config.Subtitle or "", 12, "TextTertiary")
	subLbl.Size = UDim2.new(1, -(titleX + 90), 0, 16)
	subLbl.Position = UDim2.fromOffset(titleX, 26)
	self.SubtitleLabel = subLbl

	local searchBox = Utility.Create("TextBox", {
		Name = "Search",
		BackgroundColor3 = tokens.SurfaceSecondary,
		Size = UDim2.fromOffset(140, 26),
		Position = UDim2.new(1, -160, 0.5, -13),
		PlaceholderText = "Search…",
		PlaceholderColor3 = tokens.TextTertiary,
		Text = "",
		TextColor3 = tokens.Text,
		Font = FONT,
		TextSize = 12,
		Visible = false,
		Parent = header,
	})
	RegisterTheme(searchBox, "BackgroundColor3", "SurfaceSecondary")
	RegisterTheme(searchBox, "TextColor3", "Text")
	Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = searchBox })
	Utility.Create("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = searchBox,
	})
	self.SearchBox = searchBox

	local topBar = Utility.Create("Frame", {
		Name = "TopBarButtons",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -170, 0.5, 0),
		Parent = header,
	})
	Utility.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = topBar,
	})
	self.TopBarButtons = topBar
	self._TopBarButtonCount = 0

	local body = Utility.Create("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -HEADER_HEIGHT),
		Position = UDim2.fromOffset(0, HEADER_HEIGHT),
		Parent = surface,
	})
	self.Body = body

	local sidebarW = self.CompactTab and 64 or SIDEBAR_WIDTH
	local sidebar = Utility.Create("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = tokens.Surface,
		Size = UDim2.new(0, sidebarW, 1, 0),
		BorderSizePixel = 0,
		Parent = body,
	})
	Utility.Create("UICorner", { TopLeftRadius = UDim.new(0, 14), TopRightRadius = UDim.new(0, 0), BottomLeftRadius = UDim.new(0, 14), BottomRightRadius = UDim.new(0, 0), Parent = sidebar })
	RegisterTheme(sidebar, "BackgroundColor3", "Surface")
	self.Sidebar = sidebar


	local sideList = Utility.Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -12),
		Position = UDim2.fromOffset(0, 8),
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		BorderSizePixel = 0,
		Parent = sidebar,
	})
	Utility.Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
		Parent = sideList,
	})
	self.SidebarList = sideList

	local contentContainer = Utility.Create("Frame", {
		Name = "ContentContainer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -sidebarW, 1, 0),
		Position = UDim2.fromOffset(sidebarW, 0),
		Parent = body,
	})
	self.ContentContainer = contentContainer


	if config.Draggable ~= false then
		local dragging, dragStart, startPos
		self.Maid:Give(header.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = root.Position
			end
		end))
		self.Maid:Give(UserInputService.InputChanged:Connect(function(input)
			if not dragging then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				local delta = input.Position - dragStart
				root.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end))
		self.Maid:Give(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))
	end


	if config.Resizable ~= false then
		local handle = Utility.Create("Frame", {
			Name = "ResizeHandle",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.new(1, -16, 1, -16),
			Parent = root,
			ZIndex = 20,
		})
		local resizing, resizeStart, startSize
		self.Maid:Give(handle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				resizing = true
				resizeStart = input.Position
				startSize = root.AbsoluteSize
			end
		end))
		self.Maid:Give(UserInputService.InputChanged:Connect(function(input)
			if not resizing then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				local delta = input.Position - resizeStart
				local newW = math.clamp(startSize.X + delta.X, minSize.X, (config.MaxSize and config.MaxSize.X) or 2000)
				local newH = math.clamp(startSize.Y + delta.Y, minSize.Y, (config.MaxSize and config.MaxSize.Y) or 2000)
				root.Size = UDim2.fromOffset(newW, newH)
			end
		end))
		self.Maid:Give(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				resizing = false
			end
		end))
	end


	self.Maid:Give(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local query = string.lower(searchBox.Text)
		for _, tab in ipairs(self.Tabs) do
			for _, sec in ipairs(tab.Sections) do
				for _, comp in ipairs(sec.Components) do
					if query == "" then
						comp:SetVisible(true)
					else
						local name = string.lower(comp.Config.Name or "")
						local desc = string.lower(comp.Config.Description or "")
						comp:SetVisible(string.find(name, query, 1, true) ~= nil or string.find(desc, query, 1, true) ~= nil)
					end
				end
			end
		end
	end))

	if Utility.IsMobile() then
		root.Size = UDim2.fromScale(0.96, 0.9)
		sidebar.Size = UDim2.new(0, 64, 1, 0)
		contentContainer.Size = UDim2.new(1, -64, 1, 0)
		contentContainer.Position = UDim2.fromOffset(64, 0)
	end

	table.insert(Library.Windows, self)
	return self
end

function Window:AddTabGroup(config)
	config = config or {}
	local tokens = Library:GetTheme()
	local collapseCfg = config.Collapse or {}
	local collapseEnabled = collapseCfg.Enabled == true
	local startCollapsed = collapseCfg.Default == true
	local center = config.Center == true

	local group = {
		Window = self,
		Title = config.Title or "Group",
		Tabs = {},
		Collapsed = startCollapsed,
		Maid = Maid.new(),
	}

	local container = Utility.Create("Frame", {
		Name = "TabGroup_" .. group.Title,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = self.SidebarList,
	})
	Utility.Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
		Parent = container,
	})

	local header = Utility.Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 0, 32),
		Position = UDim2.fromOffset(6, 0),
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = 0,
		Parent = container,
	})

	local titleLbl = CreateLabel(header, group.Title, 14, "Text")
	titleLbl.Size = UDim2.new(1, collapseEnabled and -20 or 0, 1, 0)
	titleLbl.Font = FONT_SEMIBOLD
	titleLbl.TextColor3 = tokens.Text
	titleLbl.TextXAlignment = center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
	if center then
		titleLbl.Position = UDim2.fromOffset(0, 0)
	else
		titleLbl.Position = UDim2.fromOffset(8, 0)
	end

	local chevron
	if collapseEnabled then
		chevron = CreateIcon(header, "chevron", 12)
		chevron.Position = UDim2.new(1, -14, 0.5, -6)
		chevron.Rotation = startCollapsed and -90 or 0
	end

	local tabsHolder = Utility.Create("Frame", {
		Name = "TabsHolder",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = not startCollapsed,
		LayoutOrder = 1,
		Parent = container,
	})
	Utility.Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
		Parent = tabsHolder,
	})

	if config.Tooltip then
		group.Maid:Give(BindTooltip(header, function() return config.Tooltip end))
	end

	if collapseEnabled then
		group.Maid:Give(header.Activated:Connect(function()
			group.Collapsed = not group.Collapsed
			tabsHolder.Visible = not group.Collapsed
			if chevron then
				QuickTween(chevron, { Rotation = group.Collapsed and -90 or 0 })
			end
		end))
	end

	function group:AddTab(tabConfig)
		tabConfig = tabConfig or {}
		tabConfig.SidebarParent = tabsHolder
		local tab = Tab.new(self.Window, tabConfig)
		table.insert(self.Window.Tabs, tab)
		table.insert(self.Tabs, tab)
		if #self.Window.Tabs == 1 then
			task.defer(function()
				if not self.Window.Destroyed and tab and not tab.Destroyed then
					self.Window:SelectTab(tab)
				end
			end)
		end
		return tab
	end

	function group:SetCollapsed(v)
		if not collapseEnabled then return end
		self.Collapsed = v == true
		tabsHolder.Visible = not self.Collapsed
		if chevron then
			QuickTween(chevron, { Rotation = self.Collapsed and -90 or 0 })
		end
	end

	function group:Destroy()
		for _, t in ipairs(self.Tabs) do
			t:Destroy()
		end
		self.Maid:Destroy()
		container:Destroy()
	end

	return group
end

function Window:AddTab(config)
	local tab = Tab.new(self, config or {})
	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then
		task.defer(function()
			if not self.Destroyed and tab and not tab.Destroyed then
				self:SelectTab(tab)
			end
		end)
	end
	return tab
end

function Window:SelectTab(tab)
	if not tab then return end
	for _, t in ipairs(self.Tabs) do
		t:SetActive(t == tab)
	end
	self.CurrentTab = tab
	if tab.Page then
		tab.Page.Visible = true
		task.defer(function()
			if tab.Page and tab.Page.Parent then
				tab.Page.CanvasPosition = Vector2.zero
			end
		end)
	end
end

function Window:SetTitle(text)
	self.TitleLabel.Text = text or ""
end

function Window:SetSubtitle(text)
	self.SubtitleLabel.Text = text or ""
end

function Window:SetDPI(scale: number)
	scale = Utility.Clamp(scale, 0.6, 2)
	self.DPI = scale
	self.UIScale.Scale = scale
end

function Window:SetSearchEnabled(enabled: boolean)
	self.SearchEnabled = enabled
	self.SearchBox.Visible = enabled
	if self.TopBarButtons then
		self.TopBarButtons.Position = enabled and UDim2.new(1, -170, 0.5, 0) or UDim2.new(1, -14, 0.5, 0)
	end
end

function Window:AddTopBarButton(config)
	config = config or {}
	if not self.TopBarButtons then return nil end
	local tokens = Library:GetTheme()
	self._TopBarButtonCount = (self._TopBarButtonCount or 0) + 1

	local btn = Utility.Create("ImageButton", {
		Name = "TopBarBtn_" .. (config.Name or tostring(self._TopBarButtonCount)),
		BackgroundColor3 = tokens.SurfaceSecondary,
		Size = UDim2.fromOffset(28, 28),
		Image = config.Icon or config.Image or "",
		ImageColor3 = tokens.Text,
		ScaleType = Enum.ScaleType.Fit,
		AutoButtonColor = false,
		LayoutOrder = self._TopBarButtonCount,
		Parent = self.TopBarButtons,
	})
	RegisterTheme(btn, "BackgroundColor3", "SurfaceSecondary")
	RegisterTheme(btn, "ImageColor3", "Text")
	Utility.Create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = btn })
	Utility.Create("UIPadding", {
		PaddingTop = UDim.new(0, 5),
		PaddingBottom = UDim.new(0, 5),
		PaddingLeft = UDim.new(0, 5),
		PaddingRight = UDim.new(0, 5),
		Parent = btn,
	})

	if config.Tooltip then
		self.Maid:Give(BindTooltip(btn, function() return config.Tooltip end))
	end

	self.Maid:Give(btn.MouseEnter:Connect(function()
		SpringTween(btn, { BackgroundColor3 = tokens.SurfaceTertiary }, 10)
	end))
	self.Maid:Give(btn.MouseLeave:Connect(function()
		SpringTween(btn, { BackgroundColor3 = tokens.SurfaceSecondary }, 10)
	end))
	self.Maid:Give(btn.Activated:Connect(function()
		Utility.SafeCallback(config.Callback)
	end))

	local api = {
		Button = btn,
		SetIcon = function(_, icon)
			btn.Image = icon or ""
		end,
		SetVisible = function(_, v)
			btn.Visible = v
		end,
		Destroy = function()
			btn:Destroy()
		end,
	}
	return api
end

function Window:SetCompactTab(enabled: boolean)
	self.CompactTab = enabled == true
	local w = self.CompactTab and 64 or SIDEBAR_WIDTH
	if self.Sidebar then
		self.Sidebar.Size = UDim2.new(0, w, 1, 0)
	end
	if self.ContentContainer then
		self.ContentContainer.Size = UDim2.new(1, -w, 1, 0)
		self.ContentContainer.Position = UDim2.fromOffset(w, 0)
	end
	for _, tab in ipairs(self.Tabs) do
		if tab.Button then
			tab.Button.Size = UDim2.new(1, self.CompactTab and -6 or -16, 0, self.CompactTab and 52 or 36)
			tab.Button.Position = UDim2.fromOffset(self.CompactTab and 3 or 8, 0)
		end
		if tab.Label then
			tab.Label.Visible = not self.CompactTab
		end
		if tab.IconLabel then
			if self.CompactTab then
				tab.IconLabel.Size = UDim2.fromOffset(26, 26)
				tab.IconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
				tab.IconLabel.Position = UDim2.fromScale(0.5, 0.5)
			else
				tab.IconLabel.Size = UDim2.fromOffset(16, 16)
				tab.IconLabel.AnchorPoint = Vector2.new(0, 0)
				tab.IconLabel.Position = UDim2.fromOffset(12, 10)
			end
		end
	end
end

function Window:Minimize()
	self.Minimized = true
	self.Root.Visible = false
end

function Window:Restore()
	self.Minimized = false
	self.Root.Visible = true
end

function Window:Toggle()
	if self.Minimized then self:Restore() else self:Minimize() end
end

function Window:Confirm(config)
	return CreateModal(self, config)
end

function Window:_ApplyTheme(tokens)
end

function Window:_ApplyFlag(flag, value)
	for _, tab in ipairs(self.Tabs) do
		for _, sec in ipairs(tab.Sections) do
			for _, comp in ipairs(sec.Components) do
				if comp.Config.Flag == flag and comp.Set then
					comp:Set(value, true)
				end
			end
		end
	end
end

function Window:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	for _, tab in ipairs(self.Tabs) do
		tab:Destroy()
	end
	self.Maid:Destroy()
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end
	local idx = table.find(Library.Windows, self)
	if idx then table.remove(Library.Windows, idx) end
end


function Library:CreateWindow(config: WindowConfig)
	if not Library._NotificationHolder then
		local holderParent = SafeParent()
		if holderParent then
			local holder = Utility.Create("Frame", {
				Name = "NotificationHolder",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Parent = holderParent,
			})
			SafeProtect(holder)
			Library._NotificationHolder = holder
		end
	end
	if config and config.Theme then
		Library:SetTheme(config.Theme)
	end
	local window = Window.new(self, config or {})
	if not window then
		warn("[Library] CreateWindow failed — run as LocalScript in Play mode")
	end
	return window
end

function Library:Notify(config)
	return CreateNotification(config or {})
end

function Library:SetDPI(scale)
	Library.DPI = scale
	for _, win in ipairs(Library.Windows) do
		if win and not win.Destroyed then
			win:SetDPI(scale)
		end
	end
end

function Library:Unload()
	for _, win in ipairs(table.clone(Library.Windows)) do
		win:Destroy()
	end
	if Library._NotificationHolder then
		Library._NotificationHolder:Destroy()
		Library._NotificationHolder = nil
	end
	if TooltipGui then
		TooltipGui:Destroy()
		TooltipGui = nil
		TooltipFrame = nil
		TooltipLabel = nil
	end
	table.clear(Library.Flags)
	table.clear(ThemeRegistry)
	table.clear(ActiveTweens)
end

Library.Create = Library.CreateWindow

return Library
