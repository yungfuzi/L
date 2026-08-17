# Library

Modern **macOS-inspired** Roblox UI framework in a **single ModuleScript** (`Library.lua`).

Designed for the current Roblox engine, executor-friendly parenting, metatable OOP, centralized theme/flags, and spring-style motion.

| | |
|---|---|
| **Version** | 2.12.2 |
| **File** | `Library.lua` (one ModuleScript) |
| **Themes** | `macOS Dark`, `macOS Light` |
| **Architecture** | Window → Tab / TabGroup → Section → Components |

---

## Features

- Single self-contained ModuleScript
- Metatable OOP (`Window`, `Tab`, `Section`, components)
- macOS visual language (traffic lights, soft surfaces, hairline rows)
- `UIShadow` where available, with safe fallbacks
- Central theme registry + live updates
- `Library.Flags` with `.Value`, `.Text`, `.Set`, etc.
- Spring / exponential tweens
- Compact tabs, DPI scale, search, top-bar buttons
- `ElementsRow` separators (System Settings style)
- Link popovers on Toggle / Label
- Modal color picker (HSV + Confirm / Cancel)
- Notifications & confirm dialogs
- Tooltips, disable/hide APIs, config save/load helpers

---

## Install

1. Create a **ModuleScript** named `Library`.
2. Paste the contents of `Library.lua`.
3. From a LocalScript / executor script:

```lua
local Library = require(path.to.Library)
-- or loadstring / readfile in executor environments
```

---

## Quick start

```lua
local Library = require(path.to.Library)

local Window = Library:CreateWindow({
	Title = "Nebula",
	Subtitle = "v2.12.2",
	Icon = "house",
	Size = UDim2.fromOffset(780, 520),
	MinSize = Vector2.new(520, 360),
	Theme = "macOS Dark",
	CompactTab = false,
	Resizable = true,
	ElementsRow = {
		Enabled = true,
		Type = "thin", -- "thin" | "fade" | "thick"
	},
})

Window:SetSearchEnabled(true)

local Tab = Window:AddTab({
	Name = "Main",
	Icon = "house",
	Tooltip = "Main page",
})

local Section = Tab:AddSection({
	Name = "General",
	Icon = "folder",
})

Section:AddToggle({
	Name = "Enable",
	Flag = "Enabled",
	Default = true,
	Callback = function(Value)
		print(Value)
	end,
})
```

---

## Window

### `Library:CreateWindow(config)`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `Title` | string | `"Window"` | Title text |
| `Subtitle` | string | `""` | Subtitle under title |
| `Icon` | string | nil | Named icon or `rbxassetid://…` |
| `Size` | UDim2 | `720×480` | Initial size |
| `MinSize` | Vector2 | `480×320` | Resize minimum |
| `Theme` | string | `"macOS Dark"` | Theme name |
| `CompactTab` | boolean | `false` | Icon-only sidebar tabs |
| `Resizable` | boolean | true-ish | Allow resize |
| `ElementsRow` | table | off | Dividers between elements |

**`ElementsRow`**

```lua
ElementsRow = {
	Enabled = true,
	Type = "thin", -- "thin" | "fade" | "thick"
}
```

When enabled, each component in a section is separated by a hairline (macOS Settings style). Section list padding collapses to `0`.

### Window methods

| Method | Description |
|--------|-------------|
| `:AddTab(config)` | Add a tab |
| `:AddTabGroup(config)` | Group of tabs with optional collapse |
| `:SelectTab(tab)` | Select tab instance / index |
| `:SetTitle(text)` | |
| `:SetSubtitle(text)` | |
| `:SetDPI(scale)` | UIScale (e.g. `0.8`–`1.4`) |
| `:SetSearchEnabled(bool)` | Header search box |
| `:AddTopBarButton(config)` | Buttons left of search |
| `:SetCompactTab(bool)` | Compact sidebar |
| `:Minimize()` / `:Restore()` / `:Toggle()` | Visibility |
| `:Confirm(config)` | Modal confirm dialog |
| `:Destroy()` | Destroy this window |

### Top bar button

```lua
Window:AddTopBarButton({
	Icon = "rbxassetid://10734943674",
	Tooltip = "Action",
	Callback = function() end,
})
```

Placed **to the left of the search bar**, flowing toward the right.

### Confirm

```lua
Window:Confirm({
	Title = "Unload?",
	Description = "This cannot be undone.",
	Buttons = {
		{ Name = "Cancel" },
		{ Name = "Unload", Primary = true, Callback = function()
			Library:Unload()
		end },
	},
})
```

---

## Tabs & TabGroup

### `Window:AddTab(config)`

```lua
local Tab = Window:AddTab({
	Name = "Main",
	Icon = "house",      -- or rbxassetid
	Tooltip = "Main page",
})
```

### `Window:AddTabGroup(config)`

```lua
local Group = Window:AddTabGroup({
	Title = "Combat",
	Collapse = { Enabled = true, Default = false },
	Tooltip = "Combat modules",
	Center = false,
})

local Aimbot = Group:AddTab({
	Name = "Aimbot",
	Icon = "target",
})
```

Group title uses larger white text. Collapse shows a chevron.

### Tab helpers

Most `Add*` methods exist on **Tab** and auto-create a `"General"` section if none exists.

`Tab:AddHeader` parents **directly to tab content** (no section required).

```lua
Tab:AddHeader({ Text = "Overview", Icon = "info" })
Tab:AddHeader("Quick actions")
```

| Method | Notes |
|--------|--------|
| `:AddSection` | |
| `:AddToggle` `:AddButton` `:AddSlider` `:AddDropdown` `:AddMultiDropdown` | |
| `:AddInput` `:AddKeybind` `:AddColorPicker` | |
| `:AddLabel` `:AddParagraph` `:AddHeader` | Header can skip section |
| `:AddDivider` `:AddSpace` | Can host on tab content |
| `:SetName` `:SetIcon` `:SetVisible` `:Destroy` | |

---

## Sections

```lua
local Section = Tab:AddSection({
	Name = "General",
	Icon = "folder",
	Type = "full", -- "full" | "left" | "right"
	Collapse = { Enabled = true, Default = false },
	Tooltip = "…",
})
```

| `Type` | Layout |
|--------|--------|
| `full` | Full width column |
| `left` | Left column |
| `right` | Right column |

### Section methods

Same component `Add*` APIs as Tab, plus:

- `:SetCollapsed(bool)` / `:ToggleCollapse()`
- `:SetName` `:SetVisible` `:Destroy`

---

## Components

All interactive components support:

- `Flag` → registered on `Library.Flags`
- `Tooltip` → string
- `Disabled` → start disabled
- `Callback` → value change
- `Icon` → where noted (Toggle, Slider, Dropdown, Input, Section, Header, …)

Shared component APIs:

```lua
component:Get() / :GetValue()
component:Set(value) / :SetValue(value)
component:OnChanged(fn)
component:SetVisible(bool)
component:SetDisabled(bool)
component:SetText(text)
component:SetTooltip(text)
component:SetCallback(fn)
component:SetFlag(name)
component:Toggle()   -- boolean components
component:Refresh()
component:Update({ … })
component:Destroy()
```

---

### Toggle

```lua
Section:AddToggle({
	Name = "Enable",
	Description = "Master switch", -- optional; left-aligned under title
	Icon = "zap",
	Flag = "Enabled",
	Default = false,
	Tooltip = "…",
	Callback = function(Value) end,
})
```

Layout:

```text
[Icon] Title                    (switch)
Description                     ← full left, not indented under title
```

---

### Link (Toggle / Label)

Popover panel with its own `Add*` API.

```lua
local Toggle = Section:AddToggle({ Name = "Silent Aim", Flag = "Silent" })

local Link = Toggle:Link()

Link:AddSlider({ Name = "FOV", Flag = "FOV", Min = 10, Max = 180, Default = 80 })
Link:AddToggle({ Name = "Visible Check", Default = true })
Link:AddDropdown({
	Name = "Hit Part",
	Values = { "Head", "Torso" },
	Default = "Head",
})
```

- Icon appears only after `:Link()`
- Popup is **220× max 220**; scrolls if taller
- Click outside closes; click inside stays open

Also:

```lua
Section:AddLabel("More"):Link()
```

---

### Slider

```lua
Section:AddSlider({
	Name = "Range",
	Icon = "target",
	Flag = "Range",
	Min = 0,
	Max = 100,
	Default = 50,
	Rounding = 0,
	Suffix = " studs", -- optional display helper if used by your build
	Callback = function(Value) end,
})
```

- Min label left, max label right of track
- Draggable knob + fill
- Value textbox (editable)

---

### Dropdown

```lua
Section:AddDropdown({
	Name = "Mode",
	Icon = "list",
	Flag = "Mode",
	Values = { "Safe", "Normal", "Rage" },
	Default = "Normal",
	Callback = function(Value) end,
})
```

Multi:

```lua
Section:AddMultiDropdown({
	Name = "Elements",
	Flag = "ESPElements",
	Values = { "Box", "Name", "Health" },
	Default = { "Box", "Name" },
})
```

Chevron uses `rbxassetid://71880540200693`.

---

### Input

Single-row macOS field: **title left**, **pill textbox right**. No `UIStroke`.

```lua
Section:AddInput({
	Name = "Target",
	Icon = "user",
	Flag = "Target",
	Placeholder = "Username…",
	Default = "",
	Numeric = false,
	Callback = function(Text) end,
})
```

TextBoxes use `UICorner = UDim.new(1, 0)` (pill).

---

### Keybind

```lua
Section:AddKeybind({
	Name = "Toggle UI",
	Flag = "ToggleUI",
	Default = Enum.KeyCode.RightShift,
	Mode = "Toggle", -- or Hold, etc. depending on implementation
	Callback = function()
		Window:Toggle()
	end,
})
```

---

### ColorPicker

Opens a **modal** HSV UI (square + hue bar) with **Confirm** / **Cancel**.

```lua
Section:AddColorPicker({
	Name = "Accent",
	Flag = "AccentColor",
	Default = Color3.fromRGB(10, 132, 255),
	Callback = function(Color) end,
})
```

---

### Button

```lua
-- Full-width
Section:AddButton({
	Name = "Run",
	Callback = function() end,
})

-- Chain up to 3 in one row
Section:AddButton({ Name = "A" })
	:AddButton({ Name = "B", Color = Color3.fromRGB(255, 149, 0) })
	:AddButton({ Name = "C", Color = Color3.fromRGB(255, 69, 58) })
```

- `Section:AddButton` always starts a **new full-width** row  
- Only `:AddButton` on a **button instance** continues the same row (max 3)

---

### Label

```lua
Section:AddLabel("Simple")
Section:AddLabel({
	Text = "Status: <b>Online</b>",
	RichText = true,
	Bold = true,
	TextSize = 13,
})
```

Supports `:Link()`.

---

### Paragraph

Uses **`Content`** (or `Text`), not Description.

```lua
-- With title
Section:AddParagraph({
	Icon = "info",
	Title = "Notice",
	Content = "Body is full-width left, not indented under title.",
	RichText = true,
})

-- No title
Section:AddParagraph({
	Icon = "info",
	Content = "This is description\nnext line",
})
```

```text
[Icon] This is description
next line                 ← not indented under first line text
```

---

### Header

```lua
Tab:AddHeader({ Text = "Combat", Icon = "sword" })
Section:AddHeader({ Text = "Options", Icon = "settings" })
```

---

### Divider & Space

```lua
Section:AddDivider({ Text = "GENERAL", Fade = true })
Section:AddSpace(8)
Section:AddSpace({ Size = 12 })

-- Also on Tab without a section
Tab:AddDivider({ Text = "MISC" })
Tab:AddSpace(6)
```

---

## Flags

```lua
Library.Flags.Enabled.Value  -- current value
Library.Flags.Enabled.Text   -- display name
Library.Flags.Enabled:Set(true)

Library:GetFlag("Enabled")
Library:SetFlag("Enabled", false)
Library:HasFlag("Enabled")
Library:ResetFlags()

local config = Library:GetConfig()   -- map of flag values
Library:LoadConfig(config)
```

---

## Theme

```lua
Library:SetTheme("macOS Dark")
Library:SetTheme("macOS Light")

local tokens = Library:GetTheme()
```

Built-in themes: **`macOS Dark`**, **`macOS Light`**.

---

## Notify

```lua
Library:Notify({
	Title = "Loaded",
	Description = "Everything is ready",
	Type = "Success", -- Success | Warning | Error | Info (styling)
	Duration = 4,
})
```

---

## Icons

Pass a **name** or raw **`rbxassetid://…`**.

Built-in names include:

`house`, `home`, `settings`, `search`, `close`, `minimize`, `chevron`, `check`, `plus`, `info`, `warning`, `success`, `error`, `key`, `color`, `user`, `folder`, `star`, `eye`, `target`, `zap`, `shield`, `sword`, `list`, `box`

```lua
Icon = "settings"
Icon = "rbxassetid://10734950309"
```

---

## Global helpers

| Method | Description |
|--------|-------------|
| `Library:CreateWindow` | Create window |
| `Library:Notify` | Toast notification |
| `Library:SetTheme` | Switch theme |
| `Library:GetTheme` | Current tokens |
| `Library:SetDPI` | Global UI scale helper |
| `Library:Unload` | Destroy all windows / cleanup |
| `Library:GetConfig` / `LoadConfig` | Flag snapshot |
| `Library.Version` | e.g. `"2.12.2"` |
| `Library.Flags` | Flag table |
| `Library.Windows` | Active windows |

---

## Layout tips

```lua
-- Headers outside sections
Tab:AddHeader({ Text = "ESP", Icon = "eye" })

-- Two columns
Tab:AddSection({ Name = "Left", Type = "left" })
Tab:AddSection({ Name = "Right", Type = "right" })

-- Settings-style list
Library:CreateWindow({
	ElementsRow = { Enabled = true, Type = "thin" },
})
```

---

## Full example

```lua
local Library = require(path.to.Library)

local Window = Library:CreateWindow({
	Title = "Nebula",
	Subtitle = "v2.12.2",
	Icon = "house",
	Size = UDim2.fromOffset(780, 520),
	Theme = "macOS Dark",
	ElementsRow = { Enabled = true, Type = "thin" },
})

Window:SetSearchEnabled(true)

local Main = Window:AddTab({ Name = "Main", Icon = "house" })

Main:AddHeader({ Text = "Overview", Icon = "info" })

local General = Main:AddSection({ Name = "General", Icon = "folder" })

General:AddToggle({
	Name = "Enable",
	Description = "Master switch",
	Icon = "zap",
	Flag = "Enabled",
	Default = true,
})

local Silent = General:AddToggle({
	Name = "Silent Aim",
	Flag = "SilentAim",
	Default = false,
})

local Link = Silent:Link()
Link:AddSlider({ Name = "FOV", Min = 10, Max = 180, Default = 80, Flag = "SilentFOV" })
Link:AddToggle({ Name = "Team Check", Default = true })

General:AddSlider({
	Name = "Range",
	Flag = "Range",
	Min = 0,
	Max = 100,
	Default = 50,
	Rounding = 0,
})

General:AddDropdown({
	Name = "Mode",
	Flag = "Mode",
	Values = { "Safe", "Normal", "Rage" },
	Default = "Normal",
})

General:AddInput({
	Name = "Target",
	Flag = "Target",
	Placeholder = "Username…",
})

General:AddKeybind({
	Name = "Toggle UI",
	Flag = "ToggleUI",
	Default = Enum.KeyCode.RightShift,
	Callback = function()
		Window:Toggle()
	end,
})

General:AddColorPicker({
	Name = "Accent",
	Flag = "AccentColor",
	Default = Color3.fromRGB(10, 132, 255),
})

General:AddButton({ Name = "Run" })
	:AddButton({ Name = "Reset" })
	:AddButton({ Name = "Destroy", Color = Color3.fromRGB(255, 69, 58) })

Library:Notify({
	Title = "Loaded",
	Description = "Nebula is ready",
	Type = "Success",
	Duration = 4,
})
```

---

## Notes

- **One ModuleScript only** — do not split into a folder of modules.
- Parenting prefers `gethui()` → `PlayerGui` → `CoreGui` for Studio + executor.
- Prefer modern APIs (`Activated`, `AutomaticSize`, `UICorner`, `UIStroke`, `UIShadow` when present).
- Scrollbars are hidden in main content (`ScrollBarThickness = 0`); Link popup uses a thin scrollbar when content exceeds max height.

---

## License / usage

Use and modify freely in your own scripts. Keep a single-file distribution if you republish the library itself.
