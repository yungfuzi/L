--[[
    Library.lua — Modern macOS-inspired Roblox UI Framework
    Single ModuleScript • Metatable OOP • Responsive • DPI • Theme Tokens
    Designed for current Roblox engine (≈ August 2026)
]]

local Library = {}
Library.__index = Library
Library.Version = "2.1.0"
Library.Flags = {}
Library.Windows = {}
Library.Notifications = {}
Library.ActiveTheme = "macOS Dark"
Library.DPI = 1

----------------------------------------------------------------
-- Services (cached once)
----------------------------------------------------------------
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local GuiService        = game:GetService("GuiService")
local TextService       = game:GetService("TextService")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- Executor helpers (safe fallbacks)
local cloneref   = cloneref or clonereference or function(i) return i end
local gethui     = gethui or function() return CoreGui end
local protectgui = protectgui or (syn and syn.protect_gui) or function() end

----------------------------------------------------------------
-- Types
----------------------------------------------------------------
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
	Theme: string | ThemeTokens?,
	Acrylic: boolean?,
	Resizable: boolean?,
	Draggable: boolean?,
	Center: boolean?,
	Icon: string?,
}

export type ToggleConfig = {
	Name: string,
	Description: string?,
	Flag: string?,
	Default: boolean?,
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
	Callback: ((value: number) -> ())?,
}

export type DropdownConfig = {
	Name: string,
	Description: string?,
	Flag: string?,
	Values: {string}?,
	Default: string | {string}?,
	Multi: boolean?,
	Searchable: boolean?,
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
	Callback: ((value: string) -> ())?,
}

export type KeybindConfig = {
	Name: string,
	Description: string?,
	Flag: string?,
	Default: Enum.KeyCode | Enum.UserInputType?,
	Mode: ("Toggle" | "Hold" | "Always")?,
	Callback: ((key: Enum.KeyCode | Enum.UserInputType) -> ())?,
}

export type ButtonConfig = {
	Name: string,
	Description: string?,
	Icon: string?,
	Callback: (() -> ())?,
}

export type ColorPickerConfig = {
	Name: string,
	Flag: string?,
	Default: Color3?,
	Alpha: number?,
	Callback: ((color: Color3, alpha: number) -> ())?,
}

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------
local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local FONT_SEMIBOLD = Enum.Font.GothamSemibold

local DEFAULT_CORNER = 10
local SIDEBAR_WIDTH = 200
local HEADER_HEIGHT = 48
local ROW_HEIGHT = 36
local SECTION_GAP = 12

----------------------------------------------------------------
-- Utility
----------------------------------------------------------------
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

function Utility.Lerp(a, b, t)
	return a + (b - a) * t
end

function Utility.Color3ToHex(c: Color3)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

function Utility.HexToColor3(hex: string)
	hex = hex:gsub("#", "")
	return Color3.fromRGB(
		tonumber(hex:sub(1, 2), 16) or 0,
		tonumber(hex:sub(3, 4), 16) or 0,
		tonumber(hex:sub(5, 6), 16) or 0
	)
end

function Utility.GetTextBounds(text: string, font: Enum.Font, size: number, width: number?)
	local params = Instance.new("GetTextBoundsParams")
	params.Text = text
	params.Font = Font.fromEnum(font)
	params.Size = size
	params.Width = width or 0
	local bounds = TextService:GetTextBoundsAsync(params)
	params:Destroy()
	return bounds
end

function Utility.IsMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function Utility.Round(n: number, places: number?)
	places = places or 0
	local m = 10 ^ places
	return math.floor(n * m + 0.5) / m
end

function Utility.Clamp(n: number, min: number, max: number)
	return math.clamp(n, min, max)
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

----------------------------------------------------------------
-- Signal
----------------------------------------------------------------
local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({
		_connections = {},
		_destroyed = false,
	}, Signal)
	return self
end

function Signal:Connect(fn: (...any) -> ())
	if self._destroyed then return { Disconnect = function() end } end
	local conn = {
		Connected = true,
		_fn = fn,
		_signal = self,
	}
	function conn:Disconnect()
		if not self.Connected then return end
		self.Connected = false
		local list = self._signal._connections
		local idx = table.find(list, self)
		if idx then
			table.remove(list, idx)
		end
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

----------------------------------------------------------------
-- Maid (Cleanup)
----------------------------------------------------------------
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

----------------------------------------------------------------
-- Theme System
----------------------------------------------------------------
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

local ThemeRegistry: {[Instance]: {string}} = {} -- Instance → {propertyName, ...}

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

	-- Also update any live windows that keep a direct reference
	for _, win in ipairs(Library.Windows) do
		if win and not win.Destroyed then
			win:_ApplyTheme(tokens)
		end
	end
end

----------------------------------------------------------------
-- Tween System
----------------------------------------------------------------
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
	return Tween(obj, goal, TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
end

----------------------------------------------------------------
-- Icon System (simple resolver)
----------------------------------------------------------------
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

----------------------------------------------------------------
-- Flag System
----------------------------------------------------------------
function Library:SetFlag(flag: string, value: any)
	if not flag or flag == "" then return end
	Library.Flags[flag] = value
end

function Library:GetFlag(flag: string)
	return Library.Flags[flag]
end

function Library:HasFlag(flag: string)
	return Library.Flags[flag] ~= nil
end

function Library:ResetFlags()
	table.clear(Library.Flags)
end

function Library:GetConfig()
	return Utility.DeepCopy(Library.Flags)
end

function Library:LoadConfig(data: {[string]: any})
	if type(data) ~= "table" then return end
	for flag, value in pairs(data) do
		Library:SetFlag(flag, value)
		-- Notify any registered elements (simple broadcast)
		for _, win in ipairs(Library.Windows) do
			if win and not win.Destroyed then
				win:_ApplyFlag(flag, value)
			end
		end
	end
end

----------------------------------------------------------------
-- Component Base
----------------------------------------------------------------
local Component = {}
Component.__index = Component

function Component.new(parentSection, config)
	local self = setmetatable({}, Component)
	self.Section = parentSection
	self.Config = config or {}
	self.Maid = Maid.new()
	self.Visible = true
	self.Destroyed = false
	self.Changed = Signal.new()
	self.Maid:Give(self.Changed)
	return self
end

function Component:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
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

function Component:Get()
	return self.Value
end

function Component:Set(value, silent)
	-- overridden by subclasses
end

function Component:OnChanged(fn)
	return self.Changed:Connect(fn)
end

----------------------------------------------------------------
-- Primitives
----------------------------------------------------------------
local function CreateSurface(parent, props)
	local tokens = Library:GetTheme()
	local frame = Utility.Create("Frame", {
		BackgroundColor3 = tokens.Surface,
		BorderSizePixel = 0,
		Parent = parent,
	})
	RegisterTheme(frame, "BackgroundColor3", "Surface")

	local corner = Utility.Create("UICorner", {
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
	local row = Utility.Create("Frame", {
		Name = "Row",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height),
		Parent = parent,
	})
	return row
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

----------------------------------------------------------------
-- Button Component
----------------------------------------------------------------
local Button = setmetatable({}, { __index = Component })
Button.__index = Button

function Button.new(section, config: ButtonConfig)
	local self = Component.new(section, config)
	setmetatable(self, Button)

	local tokens = Library:GetTheme()
	local frame = CreateRow(section.Content, 40)
	self.Frame = frame

	local btn = Utility.Create("TextButton", {
		Name = "Button",
		BackgroundColor3 = tokens.Accent,
		Size = UDim2.new(1, 0, 1, 0),
		Text = config.Name or "Button",
		TextColor3 = Color3.new(1, 1, 1),
		Font = FONT_SEMIBOLD,
		TextSize = 14,
		AutoButtonColor = false,
		Parent = frame,
	})
	RegisterTheme(btn, "BackgroundColor3", "Accent")
	Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })

	local function setState(state)
		if state == "hover" then
			QuickTween(btn, { BackgroundColor3 = tokens.AccentHover })
		elseif state == "press" then
			QuickTween(btn, { BackgroundColor3 = tokens.AccentPressed })
		else
			QuickTween(btn, { BackgroundColor3 = tokens.Accent })
		end
	end

	self.Maid:Give(btn.MouseEnter:Connect(function() setState("hover") end))
	self.Maid:Give(btn.MouseLeave:Connect(function() setState("normal") end))
	self.Maid:Give(btn.MouseButton1Down:Connect(function() setState("press") end))
	self.Maid:Give(btn.MouseButton1Up:Connect(function() setState("hover") end))
	self.Maid:Give(btn.Activated:Connect(function()
		Utility.SafeCallback(config.Callback)
	end))

	return self
end

----------------------------------------------------------------
-- Toggle Component
----------------------------------------------------------------
local Toggle = setmetatable({}, { __index = Component })
Toggle.__index = Toggle

function Toggle.new(section, config: ToggleConfig)
	local self = Component.new(section, config)
	setmetatable(self, Toggle)

	self.Value = config.Default == true
	if config.Flag then
		Library:SetFlag(config.Flag, self.Value)
	end

	local tokens = Library:GetTheme()
	local frame = CreateRow(section.Content, 44)
	self.Frame = frame

	local left = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 1, 0),
		Parent = frame,
	})

	local title = CreateLabel(left, config.Name or "Toggle", 14, "Text")
	title.Size = UDim2.new(1, 0, 0, 18)
	title.Position = UDim2.fromOffset(0, 4)

	if config.Description then
		local desc = CreateLabel(left, config.Description, 12, "TextSecondary")
		desc.Size = UDim2.new(1, 0, 0, 16)
		desc.Position = UDim2.fromOffset(0, 22)
	end

	-- Track
	local track = Utility.Create("Frame", {
		Name = "Track",
		BackgroundColor3 = self.Value and tokens.Accent or tokens.SurfaceTertiary,
		Size = UDim2.fromOffset(44, 26),
		Position = UDim2.new(1, -44, 0.5, -13),
		Parent = frame,
	})
	RegisterTheme(track, "BackgroundColor3", self.Value and "Accent" or "SurfaceTertiary")
	Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

	local knob = Utility.Create("Frame", {
		Name = "Knob",
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromOffset(22, 22),
		Position = self.Value and UDim2.new(1, -24, 0.5, -11) or UDim2.fromOffset(2, 2),
		Parent = track,
	})
	Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

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
		QuickTween(track, { BackgroundColor3 = value and t.Accent or t.SurfaceTertiary })
		QuickTween(knob, {
			Position = value and UDim2.new(1, -24, 0.5, -11) or UDim2.fromOffset(2, 2)
		})

		if config.Flag then
			Library:SetFlag(config.Flag, value)
		end
		if not silent then
			Utility.SafeCallback(config.Callback, value)
			self.Changed:Fire(value)
		end
	end

	self.Maid:Give(hit.Activated:Connect(function()
		self:Set(not self.Value)
	end))

	return self
end

----------------------------------------------------------------
-- Slider Component
----------------------------------------------------------------
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
		Library:SetFlag(config.Flag, self.Value)
	end

	local tokens = Library:GetTheme()
	local frame = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 56),
		Parent = section.Content,
	})
	self.Frame = frame

	local title = CreateLabel(frame, config.Name or "Slider", 14, "Text")
	title.Size = UDim2.new(1, -60, 0, 18)
	title.Position = UDim2.fromOffset(0, 2)

	local valueLbl = CreateLabel(frame, tostring(self.Value) .. (config.Suffix or ""), 13, "TextSecondary")
	valueLbl.Size = UDim2.new(0, 56, 0, 18)
	valueLbl.Position = UDim2.new(1, -56, 0, 2)
	valueLbl.TextXAlignment = Enum.TextXAlignment.Right

	local track = Utility.Create("Frame", {
		BackgroundColor3 = tokens.SurfaceTertiary,
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.fromOffset(0, 32),
		Parent = frame,
	})
	RegisterTheme(track, "BackgroundColor3", "SurfaceTertiary")
	Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

	local fill = Utility.Create("Frame", {
		BackgroundColor3 = tokens.Accent,
		Size = UDim2.new((self.Value - min) / (max - min), 0, 1, 0),
		Parent = track,
	})
	RegisterTheme(fill, "BackgroundColor3", "Accent")
	Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

	local knob = Utility.Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new((self.Value - min) / (max - min), -8, 0.5, -8),
		Parent = track,
		ZIndex = 2,
	})
	Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
	Utility.Create("UIStroke", {
		Color = tokens.Border,
		Thickness = 1,
		Parent = knob,
	})

	local dragging = false

	local function updateFromX(x)
		local rel = Utility.Clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local raw = min + (max - min) * rel
		local value = Utility.Round(raw, rounding)
		value = Utility.Clamp(value, min, max)
		self:Set(value)
	end

	function self:Set(value: number, silent: boolean?)
		if self.Destroyed then return end
		value = Utility.Clamp(Utility.Round(value, rounding), min, max)
		if self.Value == value then return end
		self.Value = value

		local pct = (value - min) / math.max(max - min, 1e-6)
		QuickTween(fill, { Size = UDim2.new(pct, 0, 1, 0) })
		QuickTween(knob, { Position = UDim2.new(pct, -8, 0.5, -8) })
		valueLbl.Text = tostring(value) .. (config.Suffix or "")

		if config.Flag then
			Library:SetFlag(config.Flag, value)
		end
		if not silent then
			Utility.SafeCallback(config.Callback, value)
			self.Changed:Fire(value)
		end
	end

	self.Maid:Give(track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end))

	self.Maid:Give(UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
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

	return self
end

----------------------------------------------------------------
-- Dropdown Component
----------------------------------------------------------------
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
		Library:SetFlag(config.Flag, self.Value)
	end

	local tokens = Library:GetTheme()
	local frame = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 52),
		Parent = section.Content,
	})
	self.Frame = frame
	self.Open = false

	local title = CreateLabel(frame, config.Name or "Dropdown", 14, "Text")
	title.Size = UDim2.new(1, 0, 0, 18)
	title.Position = UDim2.fromOffset(0, 2)

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

	local chevron = CreateIcon(trigger, "chevron", 14)
	chevron.Position = UDim2.new(1, -22, 0.5, -7)
	chevron.Rotation = 0

	-- List container (created lazily)
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
		QuickTween(chevron, { Rotation = 0 })
		listFrame:Destroy()
		listFrame = nil
		frame.Size = UDim2.new(1, 0, 0, 52)
	end

	local function openList()
		if listFrame then return end
		self.Open = true
		QuickTween(chevron, { Rotation = 180 })

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

		local scroll = Utility.Create("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.fromOffset(0, #self.Values * itemH),
			ScrollBarThickness = 3,
			BorderSizePixel = 0,
			Parent = listFrame,
		})

		local layout = Utility.Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 0),
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
					openList() -- refresh selection colors
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
		if config.Flag then
			Library:SetFlag(config.Flag, self.Value)
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
		if self.Open then
			closeList()
		else
			openList()
		end
	end))

	return self
end

----------------------------------------------------------------
-- Input Component
----------------------------------------------------------------
local Input = setmetatable({}, { __index = Component })
Input.__index = Input

function Input.new(section, config: InputConfig)
	local self = Component.new(section, config)
	setmetatable(self, Input)

	self.Value = config.Default or ""
	if config.Flag then
		Library:SetFlag(config.Flag, self.Value)
	end

	local tokens = Library:GetTheme()
	local frame = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 52),
		Parent = section.Content,
	})
	self.Frame = frame

	local title = CreateLabel(frame, config.Name or "Input", 14, "Text")
	title.Size = UDim2.new(1, 0, 0, 18)
	title.Position = UDim2.fromOffset(0, 2)

	local box = Utility.Create("TextBox", {
		BackgroundColor3 = tokens.SurfaceSecondary,
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, 22),
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
	RegisterTheme(box, "BackgroundColor3", "SurfaceSecondary")
	RegisterTheme(box, "TextColor3", "Text")
	RegisterTheme(box, "PlaceholderColor3", "TextTertiary")
	Utility.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = box })
	Utility.Create("UIStroke", {
		Color = tokens.Border,
		Thickness = 1,
		Parent = box,
	})
	Utility.Create("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = box,
	})

	function self:Set(value: string, silent: boolean?)
		if self.Destroyed then return end
		value = tostring(value or "")
		self.Value = value
		box.Text = value
		if config.Flag then
			Library:SetFlag(config.Flag, value)
		end
		if not silent then
			Utility.SafeCallback(config.Callback, value)
			self.Changed:Fire(value)
		end
	end

	self.Maid:Give(box.FocusLost:Connect(function(enter)
		local text = box.Text
		if config.Numeric then
			text = tostring(tonumber(text) or self.Value)
			box.Text = text
		end
		self:Set(text)
	end))

	return self
end

----------------------------------------------------------------
-- Keybind Component
----------------------------------------------------------------
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
		Library:SetFlag(config.Flag, self.Value)
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
		if config.Flag then
			Library:SetFlag(config.Flag, key)
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
		QuickTween(btn, { BackgroundColor3 = tokens.Accent })
	end))

	function self:_CancelListen()
		btn.Text = (self.Value and self.Value.Name) or "None"
		QuickTween(btn, { BackgroundColor3 = tokens.SurfaceSecondary })
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

		-- Activation
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

	return self
end

----------------------------------------------------------------
-- Label / Paragraph / Divider
----------------------------------------------------------------
local Label = setmetatable({}, { __index = Component })
Label.__index = Label

function Label.new(section, config)
	local self = Component.new(section, config)
	setmetatable(self, Label)

	local frame = CreateRow(section.Content, 24)
	self.Frame = frame
	local lbl = CreateLabel(frame, config.Name or config.Text or "", 13, "TextSecondary")
	lbl.Size = UDim2.fromScale(1, 1)
	self.Label = lbl
	return self
end

function Label:SetText(text)
	if self.Label then
		self.Label.Text = text
	end
end

local Paragraph = setmetatable({}, { __index = Component })
Paragraph.__index = Paragraph

function Paragraph.new(section, config)
	local self = Component.new(section, config)
	setmetatable(self, Paragraph)

	local text = config.Text or config.Name or ""
	local bounds = Utility.GetTextBounds(text, FONT, 13, 280)
	local h = math.max(28, bounds.Y + 8)

	local frame = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, h),
		Parent = section.Content,
	})
	self.Frame = frame

	local lbl = CreateLabel(frame, text, 13, "TextSecondary")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.TextWrapped = true
	lbl.TextYAlignment = Enum.TextYAlignment.Top
	return self
end

local Divider = setmetatable({}, { __index = Component })
Divider.__index = Divider

function Divider.new(section)
	local self = Component.new(section, {})
	setmetatable(self, Divider)

	local frame = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Parent = section.Content,
	})
	self.Frame = frame

	local line = Utility.Create("Frame", {
		BackgroundColor3 = Library:GetTheme().Border,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0.5, 0),
		Parent = frame,
	})
	RegisterTheme(line, "BackgroundColor3", "Border")
	return self
end

----------------------------------------------------------------
-- ColorPicker (simplified modern)
----------------------------------------------------------------
local ColorPicker = setmetatable({}, { __index = Component })
ColorPicker.__index = ColorPicker

function ColorPicker.new(section, config: ColorPickerConfig)
	local self = Component.new(section, config)
	setmetatable(self, ColorPicker)

	self.Value = config.Default or Color3.fromRGB(10, 132, 255)
	self.Alpha = config.Alpha or 1
	if config.Flag then
		Library:SetFlag(config.Flag, self.Value)
	end

	local tokens = Library:GetTheme()
	local frame = CreateRow(section.Content, 40)
	self.Frame = frame

	local title = CreateLabel(frame, config.Name or "Color", 14, "Text")
	title.Size = UDim2.new(1, -44, 1, 0)

	local preview = Utility.Create("Frame", {
		BackgroundColor3 = self.Value,
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -28, 0.5, -14),
		Parent = frame,
	})
	Utility.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = preview })
	Utility.Create("UIStroke", {
		Color = tokens.Border,
		Thickness = 1,
		Parent = preview,
	})

	function self:Set(color: Color3, silent: boolean?)
		if self.Destroyed then return end
		self.Value = color
		preview.BackgroundColor3 = color
		if config.Flag then
			Library:SetFlag(config.Flag, color)
		end
		if not silent then
			Utility.SafeCallback(config.Callback, color, self.Alpha)
			self.Changed:Fire(color)
		end
	end

	-- Simple click cycles through a small palette for demo (full HSV picker would be larger)
	local palette = {
		Color3.fromRGB(10, 132, 255),
		Color3.fromRGB(48, 209, 88),
		Color3.fromRGB(255, 159, 10),
		Color3.fromRGB(255, 69, 58),
		Color3.fromRGB(175, 82, 222),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(28, 28, 30),
	}
	local idx = 1

	local hit = Utility.Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		Parent = preview,
	})
	self.Maid:Give(hit.Activated:Connect(function()
		idx = (idx % #palette) + 1
		self:Set(palette[idx])
	end))

	return self
end

----------------------------------------------------------------
-- ProgressBar
----------------------------------------------------------------
local ProgressBar = setmetatable({}, { __index = Component })
ProgressBar.__index = ProgressBar

function ProgressBar.new(section, config)
	local self = Component.new(section, config)
	setmetatable(self, ProgressBar)

	self.Value = config.Default or 0
	local tokens = Library:GetTheme()

	local frame = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		Parent = section.Content,
	})
	self.Frame = frame

	local title = CreateLabel(frame, config.Name or "Progress", 13, "Text")
	title.Size = UDim2.new(1, -50, 0, 16)

	local pctLbl = CreateLabel(frame, "0%", 12, "TextSecondary")
	pctLbl.Size = UDim2.fromOffset(40, 16)
	pctLbl.Position = UDim2.new(1, -40, 0, 0)
	pctLbl.TextXAlignment = Enum.TextXAlignment.Right

	local track = Utility.Create("Frame", {
		BackgroundColor3 = tokens.SurfaceTertiary,
		Size = UDim2.new(1, 0, 0, 8),
		Position = UDim2.fromOffset(0, 24),
		Parent = frame,
	})
	RegisterTheme(track, "BackgroundColor3", "SurfaceTertiary")
	Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

	local fill = Utility.Create("Frame", {
		BackgroundColor3 = tokens.Accent,
		Size = UDim2.new(0, 0, 1, 0),
		Parent = track,
	})
	RegisterTheme(fill, "BackgroundColor3", "Accent")
	Utility.Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

	function self:Set(value: number, silent: boolean?)
		value = Utility.Clamp(value, 0, 1)
		self.Value = value
		QuickTween(fill, { Size = UDim2.new(value, 0, 1, 0) })
		pctLbl.Text = math.floor(value * 100) .. "%"
		if not silent then
			self.Changed:Fire(value)
		end
	end

	self:Set(self.Value, true)
	return self
end

----------------------------------------------------------------
-- Section
----------------------------------------------------------------
local Section = {}
Section.__index = Section

function Section.new(tab, config)
	local self = setmetatable({}, Section)
	self.Tab = tab
	self.Name = config.Name or "Section"
	self.Components = {}
	self.Maid = Maid.new()
	self.Destroyed = false

	local tokens = Library:GetTheme()

	local container = Utility.Create("Frame", {
		Name = "Section_" .. self.Name,
		BackgroundColor3 = tokens.Surface,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = tab.Content,
	})
	RegisterTheme(container, "BackgroundColor3", "Surface")
	Utility.Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = container })
	Utility.Create("UIStroke", {
		Color = tokens.Border,
		Thickness = 1,
		Parent = container,
	})
	Utility.Create("UIPadding", {
		PaddingTop = UDim.new(0, 12),
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

	local header = CreateLabel(container, self.Name, 13, "TextSecondary")
	header.Size = UDim2.new(1, 0, 0, 18)
	header.Font = FONT_SEMIBOLD
	header.LayoutOrder = 0

	self.Frame = container
	self.Content = container
	self.Header = header

	return self
end

function Section:AddButton(config)
	local c = Button.new(self, config)
	table.insert(self.Components, c)
	return c
end

function Section:AddToggle(config)
	local c = Toggle.new(self, config)
	table.insert(self.Components, c)
	return c
end

function Section:AddSlider(config)
	local c = Slider.new(self, config)
	table.insert(self.Components, c)
	return c
end

function Section:AddDropdown(config)
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
	local c = Input.new(self, config)
	table.insert(self.Components, c)
	return c
end

function Section:AddKeybind(config)
	local c = Keybind.new(self, config)
	table.insert(self.Components, c)
	return c
end

function Section:AddLabel(config)
	local c = Label.new(self, config)
	table.insert(self.Components, c)
	return c
end

function Section:AddParagraph(config)
	local c = Paragraph.new(self, config)
	table.insert(self.Components, c)
	return c
end

function Section:AddDivider()
	local c = Divider.new(self)
	table.insert(self.Components, c)
	return c
end

function Section:AddColorPicker(config)
	local c = ColorPicker.new(self, config)
	table.insert(self.Components, c)
	return c
end

function Section:AddProgressBar(config)
	local c = ProgressBar.new(self, config)
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

----------------------------------------------------------------
-- Tab
----------------------------------------------------------------
local Tab = {}
Tab.__index = Tab

function Tab.new(window, config)
	local self = setmetatable({}, Tab)
	self.Window = window
	self.Name = config.Name or "Tab"
	self.Icon = config.Icon
	self.Sections = {}
	self.Maid = Maid.new()
	self.Destroyed = false
	self.Active = false

	local tokens = Library:GetTheme()

	-- Sidebar button
	local btn = Utility.Create("TextButton", {
		Name = "TabBtn_" .. self.Name,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 0, 36),
		Position = UDim2.fromOffset(8, 0),
		Text = "",
		AutoButtonColor = false,
		Parent = window.SidebarList,
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
		local icon = CreateIcon(btn, self.Icon, 16)
		icon.Position = UDim2.fromOffset(12, 10)
		self.IconLabel = icon
	end

	local lbl = CreateLabel(btn, self.Name, 14, "TextSecondary")
	lbl.Size = UDim2.new(1, -40, 1, 0)
	lbl.Position = UDim2.fromOffset(self.Icon and 36 or 12, 0)
	self.Label = lbl

	-- Content page
	local page = Utility.Create("ScrollingFrame", {
		Name = "Page_" .. self.Name,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
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
	Utility.Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, SECTION_GAP),
		Parent = page,
	})
	self.Content = page

	self.Maid:Give(btn.Activated:Connect(function()
		window:SelectTab(self)
	end))

	self.Maid:Give(btn.MouseEnter:Connect(function()
		if not self.Active then
			QuickTween(lbl, { TextColor3 = tokens.Text })
		end
	end))
	self.Maid:Give(btn.MouseLeave:Connect(function()
		if not self.Active then
			QuickTween(lbl, { TextColor3 = tokens.TextSecondary })
		end
	end))

	return self
end

function Tab:SetActive(active: boolean)
	self.Active = active
	local tokens = Library:GetTheme()
	self.Content.Visible = active
	self.AccentBar.Visible = active
	self.Label.TextColor3 = active and tokens.Text or tokens.TextSecondary
	if self.IconLabel then
		self.IconLabel.ImageColor3 = active and tokens.Accent or tokens.TextSecondary
	end
	if active then
		self.Button.BackgroundTransparency = 0.92
		self.Button.BackgroundColor3 = tokens.SurfaceSecondary
	else
		self.Button.BackgroundTransparency = 1
	end
end

function Tab:AddSection(config)
	local sec = Section.new(self, config or {})
	table.insert(self.Sections, sec)
	return sec
end

-- Convenience passthrough so users can do Tab:AddToggle directly
function Tab:AddToggle(config)
	local sec = self.Sections[#self.Sections]
	if not sec then
		sec = self:AddSection({ Name = "General" })
	end
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

function Tab:AddParagraph(config)
	local sec = self.Sections[#self.Sections]
	if not sec then sec = self:AddSection({ Name = "General" }) end
	return sec:AddParagraph(config)
end

function Tab:AddDivider()
	local sec = self.Sections[#self.Sections]
	if not sec then sec = self:AddSection({ Name = "General" }) end
	return sec:AddDivider()
end

function Tab:AddColorPicker(config)
	local sec = self.Sections[#self.Sections]
	if not sec then sec = self:AddSection({ Name = "General" }) end
	return sec:AddColorPicker(config)
end

function Tab:AddProgressBar(config)
	local sec = self.Sections[#self.Sections]
	if not sec then sec = self:AddSection({ Name = "General" }) end
	return sec:AddProgressBar(config)
end

function Tab:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	for _, s in ipairs(self.Sections) do
		s:Destroy()
	end
	self.Maid:Destroy()
	if self.Button then self.Button:Destroy() end
	if self.Content then self.Content:Destroy() end
end

----------------------------------------------------------------
-- Notification
----------------------------------------------------------------
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

	-- Animate in
	gui.Position = UDim2.new(1, 40, 0, 20)
	QuickTween(gui, { Position = UDim2.new(1, -20, 0, 20 + (#Library.Notifications * 90)) })

	table.insert(Library.Notifications, gui)

	task.delay(duration, function()
		if gui and gui.Parent then
			local tw = QuickTween(gui, { Position = UDim2.new(1, 40, 0, gui.Position.Y.Offset) })
			tw.Completed:Wait()
			gui:Destroy()
			local idx = table.find(Library.Notifications, gui)
			if idx then table.remove(Library.Notifications, idx) end
		end
	end)

	return gui
end

----------------------------------------------------------------
-- Modal / Confirm
----------------------------------------------------------------
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

----------------------------------------------------------------
-- Window
----------------------------------------------------------------
local Window = {}
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

	local tokens = library:GetTheme()
	local size = config.Size or UDim2.fromOffset(720, 480)
	local minSize = config.MinSize or Vector2.new(480, 320)

	-- Root ScreenGui
	local screenGui = Utility.Create("ScreenGui", {
		Name = "LibraryUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 100,
	})
	pcall(protectgui, screenGui)
	screenGui.Parent = gethui()
	self.ScreenGui = screenGui

	-- UIScale for DPI
	local uiScale = Utility.Create("UIScale", {
		Scale = 1,
		Parent = screenGui,
	})
	self.UIScale = uiScale

	-- Main window frame
	local root = Utility.Create("Frame", {
		Name = "Window",
		BackgroundTransparency = 1,
		Size = size,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = screenGui,
	})
	self.Root = root

	-- Shadow
	local shadow = Utility.Create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://6014261993",
		ImageColor3 = tokens.Shadow,
		ImageTransparency = 0.6,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		Size = UDim2.new(1, 40, 1, 40),
		Position = UDim2.fromOffset(-20, -16),
		Parent = root,
		ZIndex = 0,
	})

	-- Surface
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
	self.Surface = surface

	-- Header
	local header = Utility.Create("Frame", {
		Name = "Header",
		BackgroundColor3 = tokens.Surface,
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		Parent = surface,
	})
	RegisterTheme(header, "BackgroundColor3", "Surface")
	self.Header = header

	-- Traffic lights (macOS style)
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
		l.Activated:Connect(callback)
		return l
	end

	makeLight(Color3.fromRGB(255, 95, 87), function() self:Destroy() end) -- close
	makeLight(Color3.fromRGB(255, 189, 46), function() self:Minimize() end) -- minimize
	makeLight(Color3.fromRGB(40, 200, 64), function() end) -- maximize placeholder

	-- Title
	local titleLbl = CreateLabel(header, config.Title or "Window", 15, "Text")
	titleLbl.Size = UDim2.new(1, -180, 0, 20)
	titleLbl.Position = UDim2.fromOffset(90, 8)
	titleLbl.Font = FONT_SEMIBOLD
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	self.TitleLabel = titleLbl

	local subLbl = CreateLabel(header, config.Subtitle or "", 11, "TextTertiary")
	subLbl.Size = UDim2.new(1, -180, 0, 14)
	subLbl.Position = UDim2.fromOffset(90, 26)
	self.SubtitleLabel = subLbl

	-- Search box (optional)
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
	Utility.Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = searchBox })
	Utility.Create("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = searchBox,
	})
	self.SearchBox = searchBox

	-- Body
	local body = Utility.Create("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -HEADER_HEIGHT),
		Position = UDim2.fromOffset(0, HEADER_HEIGHT),
		Parent = surface,
	})
	self.Body = body

	-- Sidebar
	local sidebar = Utility.Create("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = tokens.Surface,
		Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0),
		Parent = body,
	})
	RegisterTheme(sidebar, "BackgroundColor3", "Surface")
	self.Sidebar = sidebar

	local sideStroke = Utility.Create("Frame", {
		BackgroundColor3 = tokens.Border,
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(1, -1, 0, 0),
		Parent = sidebar,
	})
	RegisterTheme(sideStroke, "BackgroundColor3", "Border")

	local sideList = Utility.Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -12),
		Position = UDim2.fromOffset(0, 8),
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		BorderSizePixel = 0,
		Parent = sidebar,
	})
	Utility.Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
		Parent = sideList,
	})
	self.SidebarList = sideList

	-- Content area
	local contentContainer = Utility.Create("Frame", {
		Name = "ContentContainer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, 0),
		Position = UDim2.fromOffset(SIDEBAR_WIDTH, 0),
		Parent = body,
	})
	self.ContentContainer = contentContainer

	-- Drag
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

	-- Resize
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

	-- Search filter
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

	-- Mobile adaptation
	if Utility.IsMobile() then
		root.Size = UDim2.fromScale(0.96, 0.9)
		sidebar.Size = UDim2.new(0, 64, 1, 0)
		contentContainer.Size = UDim2.new(1, -64, 1, 0)
		contentContainer.Position = UDim2.fromOffset(64, 0)
		for _, child in ipairs(sideList:GetChildren()) do
			if child:IsA("TextButton") then
				-- compact
			end
		end
	end

	table.insert(Library.Windows, self)
	return self
end

function Window:AddTab(config)
	local tab = Tab.new(self, config or {})
	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then
		self:SelectTab(tab)
	end
	return tab
end

function Window:SelectTab(tab)
	for _, t in ipairs(self.Tabs) do
		t:SetActive(t == tab)
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
	if self.Minimized then
		self:Restore()
	else
		self:Minimize()
	end
end

function Window:SetResizable(v: boolean)
	-- handle already created; could toggle visibility of handle
end

function Window:Confirm(config)
	return CreateModal(self, config)
end

function Window:_ApplyTheme(tokens)
	-- Theme registry handles most; force refresh of dynamic parts if needed
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

----------------------------------------------------------------
-- Public Library API
----------------------------------------------------------------
function Library:CreateWindow(config: WindowConfig)
	-- Ensure notification holder exists
	if not Library._NotificationHolder then
		local holder = Utility.Create("Frame", {
			Name = "NotificationHolder",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = gethui(),
		})
		pcall(protectgui, holder)
		Library._NotificationHolder = holder
	end

	if config and config.Theme then
		Library:SetTheme(config.Theme)
	end

	return Window.new(self, config or {})
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
	table.clear(Library.Flags)
	table.clear(ThemeRegistry)
	table.clear(ActiveTweens)
end

-- Convenience aliases
Library.Create = Library.CreateWindow

return Library
