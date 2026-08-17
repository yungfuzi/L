# SolixHub UI Library — Documentation

# ⚠️ WARNING: This documentation is AI made. Maybe errors.

> Load the library with:
>
> ```lua
> local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/yungfuzi/L/refs/heads/main/S-Lib/Solix.lua"))()
> ```

---

## Table of Contents

 1. [Window](#window)
 2. [Page](#page)
 3. [PageSection](#pagesection)
 4. [Section](#section)
 5. [ImageSection](#imagesection)
 6. [ViewportSection](#viewportsection)
 7. [Toggle](#toggle)
 8. [Checkbox](#checkbox)
 9. [Button](#button)
10. [Slider](#slider)
11. [Dropdown](#dropdown)
12. [ToggleDropdown](#toggledropdown)
13. [Label](#label)
14. [Textbox](#textbox)
15. [Colorpicker](#colorpicker)
16. [Keybind](#keybind)
17. [Notification](#notification)
18. [Modal](#modal)
19. [Watermark](#watermark)
20. [KeybindList](#keybindlist)
21. [Settings Page](#settings-page)
22. [Config System](#config-system)
23. [Theme System](#theme-system)
24. [Library Utilities](#library-utilities)
25. [Flags](#flags)
26. [Example](#example)

---

## Window

Creates the main UI window.

```lua
local Window = Library:Window({
    Name           = "My Hub",                          -- Title in the top-left
    Size           = UDim2.new(0, 770, 0, 526),          -- Optional (mobile defaults smaller)
    FadeSpeed      = 0.25,                              -- Animation speed for dropdowns/pickers
    BackgroundIcon = "rbxassetid://..."                 -- Optional background image
})
```

### Methods

| Method | Description |
| --- | --- |
| `Window:SetBackgroundTransparency(value)` | Set background opacity (0–1) |
| `Window:SetBackgroundImage(assetId)` | Change background image |
| `Window:SetOpen(bool)` | Show or hide the window |
| `Window:Minimize(bool)` | Collapse or expand the window |

> **Menu Keybind:** Default is `RightControl`. Change via `Library.MenuKeybind = "Enum.KeyCode.X"`.

---

## Page

Adds a navigation tab to the window.

```lua
local Page = Window:Page({
    Name      = "Combat",   -- Tab label
    Columns   = 2,          -- Number of content columns (default: 2)
    IsKeyPage = false       -- Special license-key layout (default: false)
})
```

### Key Page (for license keys)

```lua
local KeyPage = Window:Page({ Name = "Key", IsKeyPage = true })

KeyPage:AddKey("Enter your key", "MYKEY123", "https://getkey.link", function()
    -- runs on successful key entry
end)
```

### Methods

| Method | Description |
| --- | --- |
| `Page:Turn(bool)` | Activate / deactivate this page |
| `Page:AddKey(text, key, getKeyLink, callback)` | Key page only — adds key input UI |

---

## PageSection

Groups pages in the sidebar under a collapsible header.

```lua
local PageSection = Window:PageSection({
    Name        = "Combat",
    Collapsible = true,   -- default true
    Default     = true    -- start expanded (default true)
})

local AimPage = PageSection:Page({
    Name    = "Aimbot",
    Columns = 2
})

local EspPage = PageSection:Page({ Name = "ESP" })
```

You can still use `Window:Page()` for top-level pages outside any section.

### Methods

| Method | Description |
| --- | --- |
| `PageSection:Page(props)` | Create a page inside this section |
| `PageSection:GetState()` | Returns `true` if expanded |
| `PageSection:SetCollapsed(bool)` | Collapse (`true`) or expand (`false`) |
| `PageSection:SetOpen(bool)` | Expand (`true`) or collapse (`false`) |
| `PageSection:Toggle()` | Toggle open state |
| `PageSection:SetVisible(bool)` | Show / hide the section |
| `PageSection:SetName(text)` | Rename header |

---

## Section

Groups elements inside a page column. Supports optional collapse.

```lua
local Section = Page:Section({
    Name        = "Aimbot",
    Side        = 1,       -- 1 = left column, 2 = right column
    Collapsible = true,    -- show collapse arrow (icon rbxassetid://134878256295114)
    Default     = true     -- initial open state (true = expanded)
})
```

### Methods

| Method | Description |
| --- | --- |
| `Section:GetState()` | Returns `true` if open / expanded |
| `Section:SetCollapsed(bool)` | Collapse (`true`) or expand (`false`) |
| `Section:SetOpen(bool)` | Expand (`true`) or collapse (`false`) |
| `Section:Toggle()` | Toggle open / collapsed |
| `Section:SetVisible(bool)` | Show or hide the entire section |
| `Section:SetName(text)` | Change the section title |

---

## ImageSection

Displays a selectable image gallery inside a page column.

```lua
Page:ImageSection({
    Name   = "Gallery",
    Side   = 1,
    Images = {
        ["Cat"]  = "115002736787206",   -- name → rbxassetid number (without prefix)
        ["Dog"]  = "123456789"
    }
})
```

---

## ViewportSection

Displays a rotatable 3D viewport of a Part.

```lua
Page:ViewportSection({
    Name = "Character",
    Side = 2,                 -- or "Left" / "Right"
    Part = workspace.SomePart
})
```

Drag on the viewport to rotate the cloned part.

---

## Toggle

A binary on/off switch (pill style).

```lua
local MyToggle = Section:Toggle({
    Name      = "Silent Aim",
    Flag      = "SilentAim",       -- Unique identifier for saving/loading
    Default   = false,
    Disabled  = false,
    Tooltip   = "Enables silent aim",
    Callback  = function(value) end,
    OnChanged = function(value) end  -- optional extra listener
})
```

### Methods

| Method | Description |
| --- | --- |
| `MyToggle:Set(bool)` | Set value programmatically |
| `MyToggle:SetText(text)` | Change label |
| `MyToggle:SetDisabled(bool)` | Enable/disable interaction |
| `MyToggle:SetVisible(bool)` | Show/hide the element |
| `MyToggle:OnChanged(callback)` | Subscribe to value changes (fires immediately with current value) |
| `MyToggle:Colorpicker(props)` | Attach an inline colorpicker |
| `MyToggle:Keybind(props)` | Attach an inline keybind |

### Sub-elements

```lua
MyToggle:Colorpicker({
    Name     = "Aim Color",
    Flag     = "AimColor",
    Default  = Color3.fromRGB(255, 0, 0),
    Alpha    = 0,
    Callback = function(color, alpha) end
})

MyToggle:Keybind({
    Name     = "Aim Key",
    Flag     = "AimKey",
    Default  = Enum.KeyCode.X,
    Mode     = "Toggle",   -- "Toggle" | "Hold" | "Always"
    Callback = function(toggled) end
})
```

---

## Checkbox

Visually similar to Toggle but uses a checkmark indicator instead of a pill.

```lua
local MyCheckbox = Section:Checkbox({
    Name      = "Show ESP",
    Flag      = "ESP",
    Default   = false,
    Disabled  = false,
    Tooltip   = "Draw boxes",
    Callback  = function(value) end,
    OnChanged = function(value) end
})
```

Supports the same methods as Toggle, plus `:Colorpicker()` and `:Keybind()` sub-elements.

| Method | Description |
| --- | --- |
| `MyCheckbox:Set(bool)` | Set value |
| `MyCheckbox:SetText(text)` | Change label |
| `MyCheckbox:SetDisabled(bool)` | Enable/disable |
| `MyCheckbox:SetVisible(bool)` | Show/hide |
| `MyCheckbox:OnChanged(callback)` | Subscribe to changes |
| `MyCheckbox:Colorpicker(props)` | Inline colorpicker |
| `MyCheckbox:Keybind(props)` | Inline keybind |

---

## Button

A row of clickable buttons (auto-fills width equally).

Supports both positional args and a properties table.

```lua
local Buttons = Section:Button()

-- Table API (recommended)
local Btn = Buttons:Add({
    Name     = "Teleport",
    Tooltip  = "Teleports you",
    Disabled = false,
    Callback = function() end,
    Color    = Color3.fromRGB(80, 140, 255) -- optional custom color
})

-- Positional API (still supported)
local Btn2 = Buttons:Add(
    "Kill",                         -- Name
    function() end,                 -- Callback
    false,                          -- Disabled
    "Kills target",                 -- Tooltip
    Color3.fromRGB(255, 80, 80)     -- optional Color
)
```

### Button Methods

| Method | Description |
| --- | --- |
| `Btn:SetText(text)` | Change button label |
| `Btn:GetText()` | Get current label |
| `Btn:SetDisabled(bool)` | Enable/disable |
| `Btn:GetDisabled()` | Get disabled state |
| `Btn:SetVisible(bool)` | Show/hide |
| `Btn:SetColor(color3 \| nil)` | Set custom color (`nil` = theme Element) |
| `Btn:SetCallback(fn)` | Replace press callback |
| `Btn:Press()` | Trigger press programmatically |
| `Btn:OnPressed(callback)` | Extra subscribe on press |
| `Buttons:SetVisible(bool)` | Show/hide the whole row |

---

## Slider

A draggable numeric input.

```lua
local MySlider = Section:Slider({
    Name      = "Walk Speed",
    Flag      = "WalkSpeed",
    Min       = 16,
    Max       = 200,
    Default   = 16,
    Decimals  = 1,           -- step precision (1 = integers, 0.01 = two decimals)
    Suffix    = " studs",
    Disabled  = false,
    Tooltip   = "Character speed",
    Callback  = function(value) end,
    OnChanged = function(value) end
})
```

### Methods

| Method | Description |
| --- | --- |
| `MySlider:Set(value)` | Set value programmatically |
| `MySlider:SetText(text)` | Change label |
| `MySlider:SetMin(value)` | Change minimum |
| `MySlider:SetMax(value)` | Change maximum |
| `MySlider:SetSuffix(text)` | Change suffix text |
| `MySlider:SetDisabled(bool)` | Enable/disable |
| `MySlider:SetVisible(bool)` | Show/hide |
| `MySlider:OnChanged(callback)` | Subscribe to changes |

---

## Dropdown

Single or multi-select dropdown. Options can include icons.

```lua
local MyDropdown = Section:Dropdown({
    Name            = "Target Part",
    Flag            = "TargetPart",
    Items           = {"Head", "Torso", "HumanoidRootPart"},
    Default         = "Head",          -- string, or table if Multi
    Multi           = false,
    IsLabelDropdown = false,           -- options as labels instead of buttons
    Disabled        = false,
    Tooltip         = "Hit part",
    Callback        = function(value) end,
    OnChanged       = function(value) end
})

-- Items can also include icons via :Add
MyDropdown:Add("Left Arm", "96215562143920")
```

### Methods

| Method | Description |
| --- | --- |
| `MyDropdown:Set(option)` | Set selected value (string or table for multi) |
| `MyDropdown:Get()` | Get current value |
| `MyDropdown:Add(option, icon?)` | Add an option (optional rbxassetid icon) |
| `MyDropdown:Remove(option)` | Remove an option |
| `MyDropdown:Clear()` | Remove all options |
| `MyDropdown:Refresh(list)` | Clear and repopulate from a list |
| `MyDropdown:SetMulti(bool)` | Toggle multi-select mode |
| `MyDropdown:SetText(text)` | Change label |
| `MyDropdown:SetDisabled(bool)` | Enable/disable |
| `MyDropdown:SetVisible(bool)` | Show/hide |
| `MyDropdown:SetOpen(bool)` | Open/close the dropdown list |
| `MyDropdown:OnChanged(callback)` | Subscribe to changes |

---

## ToggleDropdown

Dropdown combined with a toggle (enable/disable the feature + pick options).

```lua
local MyToggleDropdown = Section:ToggleDropdown({
    Name      = "Auto Features",
    Flag      = "AutoFeatures",
    Items     = {"Auto Farm", "Auto Collect", "Auto Sell"},
    Default   = nil,
    Multi     = true,
    Disabled  = false,
    Tooltip   = "Pick features",
    Callback  = function(value) end,
    OnChanged = function(value) end
})
```

### Methods

Same as Dropdown:

| Method | Description |
| --- | --- |
| `MyToggleDropdown:Set(items)` | Set value |
| `MyToggleDropdown:Get()` | Get value |
| `MyToggleDropdown:Add(option, icon?)` | Add option |
| `MyToggleDropdown:Remove(option)` | Remove option |
| `MyToggleDropdown:Clear()` | Clear all |
| `MyToggleDropdown:Refresh(list)` | Repopulate |
| `MyToggleDropdown:SetMulti(bool)` | Multi-select |
| `MyToggleDropdown:SetText(text)` | Change label |
| `MyToggleDropdown:SetDisabled(bool)` | Enable/disable |
| `MyToggleDropdown:SetVisible(bool)` | Show/hide |
| `MyToggleDropdown:OnChanged(callback)` | Subscribe |

---

## Label

A styled text label. Supports rich text.

```lua
local MyLabel = Section:Label(
    "Status: Active",  -- Text (RichText enabled)
    "Left",            -- Alignment: "Left", "Center", "Right"
    "Tooltip text",    -- Optional tooltip
    false              -- Outline (bool) — black UIStroke on text
)
```

### Methods

| Method | Description |
| --- | --- |
| `MyLabel:SetText(text)` | Change text |
| `MyLabel:SetTextColor(color3)` | Override text color (removes theme binding) |
| `MyLabel:Colorpicker(props)` | Attach an inline colorpicker |
| `MyLabel:Keybind(props)` | Attach an inline keybind |

```lua
MyLabel:Colorpicker({
    Name     = "ESP Color",
    Flag     = "ESPColor",
    Default  = Color3.fromRGB(0, 255, 0),
    Alpha    = 0,
    Callback = function(color, alpha) end
})

MyLabel:Keybind({
    Name     = "Toggle ESP",
    Flag     = "ESPKey",
    Default  = Enum.KeyCode.E,
    Mode     = "Toggle",
    Callback = function(toggled) end
})
```

---

## Textbox

Single-line text input.

```lua
local MyTextbox = Section:Textbox({
    Name        = "Username",
    Flag        = "Username",
    Default     = "",
    Placeholder = "Enter name...",
    Disabled    = false,
    Tooltip     = "Target player",
    Callback    = function(value) end,
    OnChanged   = function(value) end
})
```

### Methods

| Method | Description |
| --- | --- |
| `MyTextbox:Set(value)` | Set text programmatically |
| `MyTextbox:SetText(text)` | Alias for Set |
| `MyTextbox:SetDisabled(bool)` | Enable/disable |
| `MyTextbox:SetVisible(bool)` | Show/hide |

---

## Colorpicker

Standalone color pickers are attached via **Toggle**, **Checkbox**, or **Label** (see above).

Options:

| Option | Description |
| --- | --- |
| `Name` | Identifier |
| `Flag` | Config flag |
| `Default` | `Color3` default |
| `Alpha` | Transparency 0–1 (default 0) |
| `Disabled` | Start disabled |
| `Callback` | `function(color, alpha)` |
| `OnChanged` | Extra listener |

Returned colorpicker methods (from component):

| Method | Description |
| --- | --- |
| `Colorpicker:Set(color, alpha?)` | Set color / alpha |
| `Colorpicker:SetOpen(bool)` | Open/close picker panel |

---

## Keybind

Standalone keybinds are attached via **Toggle**, **Checkbox**, or **Label**.

```lua
MyToggle:Keybind({
    Name      = "Aim Key",
    Flag      = "AimKey",
    Default   = Enum.KeyCode.X,   -- or Enum.UserInputType.MouseButton1
    Mode      = "Toggle",         -- "Toggle" | "Hold" | "Always"
    Callback  = function(toggled) end,
    OnChanged = function(toggled, key) end
})
```

### Modes

| Mode | Behavior |
| --- | --- |
| `Toggle` | Press once to enable, again to disable |
| `Hold` | Active only while key is held |
| `Always` | Always active (ignores key for activation) |

### Methods (component)

| Method | Description |
| --- | --- |
| `Keybind:Set(key)` | Set bound key |
| `Keybind:SetMode(mode)` | Change mode |
| `Keybind:SetOpen(bool)` | Open/close mode menu |
| `Keybind:Press(bool)` | Simulate press state |

---

## Notification

Shows a timed toast notification in the top-right corner.

```lua
Library:Notification(
    "Success!",            -- Title
    "Config loaded.",      -- Description
    5                      -- Duration in seconds
)
```

---

## Modal

Centered dialog overlay with optional buttons and auto-close.

```lua
local Modal = Library:Modal({
    Title    = "This Is A Modal",
    Content  = "This Is Modal Content",
    Duration = 5,              -- auto-close after N seconds (optional)
    CanClose = true,           -- show X button (default true, icon rbxassetid://131854485604535)
    Buttons  = {
        {"Confirm", Color3.fromRGB(80, 140, 255), function() end},
        {"Cancel",  nil, function() end},  -- nil color = theme Element
    }
})
```

### Methods

| Method | Description |
| --- | --- |
| `Modal:Close()` | Close and destroy the modal |

Each button entry is `{Text, Color3?, Callback}`. Pressing a button runs its callback then closes the modal.

---

## Watermark

A floating FPS/ping display bar.

```lua
local Watermark = Library:Watermark("My Hub | v1.0")

Watermark:SetVisible(true)   -- Show
Watermark:SetVisible(false)  -- Hide
```

Automatically updates with current **FPS** and **Ping** every frame.

---

## KeybindList

A draggable overlay listing all active keybinds.

```lua
local KeybindList = Library:KeybindList()

KeybindList:SetVisible(true)
```

### Methods

| Method | Description |
| --- | --- |
| `KeybindList:SetVisible(bool)` | Show / hide |
| `KeybindList:Add(key, name, mode)` | Manually add an entry |

Keybinds created via Toggle/Checkbox/Label automatically register when bound. Status highlights in accent color when active.

---

## Settings Page

Built-in settings page with configs, themes, watermark/keybind toggles, menu keybind, and tween settings.

```lua
local Watermark   = Library:Watermark("My Hub")
local KeybindList = Library:KeybindList()

Library:CreateSettingsPage(Window, Watermark, KeybindList)
```

Creates a **Settings** page with:

- **Configs** — create / delete / load / save / refresh / set & clear autoload
- **Themes** — create / delete / load / save theme presets
- **Watermark** & **Keybind list** toggles
- **Menu keybind** picker
- **Tween** time / style / direction
- **Theme** colorpickers for every theme key

Call `Library:CheckForAutoLoad()` after building your UI to load the autoload config if set.

---

## Config System

Configs are JSON files stored under `eclipse/Configs/`, scoped per `game.GameId`.

| Method | Description |
| --- | --- |
| `Library:GetConfig()` | Returns JSON string of all flags |
| `Library:LoadConfig(json)` | Load flags from JSON string → `success, result` |
| `Library:DeleteConfig(filename)` | Delete a config file |
| `Library:RefreshConfigsList(dropdown)` | Refresh a dropdown with available configs |
| `Library:CheckForAutoLoad()` | Load `eclipse/autoload.json` if present |

```lua
-- Manual save
writefile("eclipse/Configs/MyConfig" .. game.GameId .. ".json", Library:GetConfig())

-- Manual load
local ok, err = Library:LoadConfig(readfile("eclipse/Configs/MyConfig" .. game.GameId .. ".json"))
```

---

## Theme System

Built-in themes: **Default**, **Halloween**, **Aqua**, **Onetap**, **Bitchbot**, **Gamesense**.

Theme keys:

| Key | Typical use |
| --- | --- |
| `Background` | Window / modal background |
| `Inline` | Section / element panels |
| `Border` | Dividers / strokes |
| `Shadow` | Drop shadow |
| `Text` | Primary text |
| `Inactive Text` | Placeholder / dimmed text |
| `Accent` | Highlights / active states |
| `Element` | Buttons / inputs background |
| `Gradient` | UIGradient secondary color |

| Method | Description |
| --- | --- |
| `Library:ChangeTheme(key, color3)` | Live-update one theme color across all registered UI |
| `Library:GetTheme()` | JSON of current theme colorpicker flags |
| `Library:LoadTheme(json)` | Load theme flags from JSON → `success, result` |
| `Library:SaveTheme(name)` | Overwrite existing theme file |
| `Library:DeleteTheme(filename)` | Delete a theme file |
| `Library:RefreshThemesList(dropdown)` | Refresh a dropdown with theme files |

Themes are stored under `eclipse/Themes/`.

Folders used by the library:

```
eclipse/
├── Assets/
├── Configs/
└── Themes/
```

---

## Library Utilities

| Method / Property | Description |
| --- | --- |
| `Library:Unload()` | Disconnect all signals, destroy UI, clear state |
| `Library:Notification(title, desc, duration)` | Toast notification |
| `Library:Modal(props)` | Centered modal dialog |
| `Library:Watermark(name)` | Create watermark |
| `Library:KeybindList()` | Create keybind list overlay |
| `Library:CreateSettingsPage(window, watermark, keybindList)` | Built-in settings page |
| `Library:CheckForAutoLoad()` | Apply autoload config |
| `Library:SafeCall(fn, ...)` | pcall wrapper |
| `Library:Thread(fn)` | Spawn a managed thread |
| `Library:Connect(event, callback, name?)` | Tracked connection |
| `Library:Disconnect(name)` | Disconnect by name |
| `Library:NextFlag()` | Generate unique flag name |
| `Library:Round(number, float)` | Round helper |
| `Library:GetImage(name)` | Resolve custom asset image |
| `Library.MenuKeybind` | Menu toggle key (string of Enum) |
| `Library.Flags` | Table of all flag values |
| `Library.Theme` | Current theme color table |
| `Library.Tween.Time / Style / Direction` | Global animation settings |

---

## Flags

Every element with a `Flag` option stores its value in `Library.Flags[flagName]`.

| Element | Flag value type |
| --- | --- |
| Toggle / Checkbox | `boolean` |
| Slider | `number` |
| Dropdown / ToggleDropdown | `string` or `table` (multi) |
| Textbox | `string` |
| Colorpicker | `{ Color = hex, Alpha = number }` |
| Keybind | `{ Key = string, Mode = string, Toggled = bool }` |

Use unique flag names. If omitted, the library auto-generates one via `Library:NextFlag()`.

Access values at runtime:

```lua
print(Library.Flags["WalkSpeed"])
print(Library.Flags["SilentAim"])
```

---

## Example

```lua
local Library = loadstring(game:HttpGet("..."))()

local Window = Library:Window({
    Name = "Solix Hub",
    Size = UDim2.new(0, 770, 0, 526)
})

local Watermark   = Library:Watermark("Solix Hub | v1.0")
local KeybindList = Library:KeybindList()

-- Top-level page
local Home = Window:Page({ Name = "Home", Columns = 1 })
local Intro = Home:Section({ Name = "Welcome", Side = 1 })
Intro:Label("Thanks for using Solix UI.", "Center")

-- Grouped pages
local Combat = Window:PageSection({ Name = "Combat", Collapsible = true, Default = true })

local AimbotPage = Combat:Page({ Name = "Aimbot", Columns = 2 })
local AimSection = AimbotPage:Section({
    Name = "Silent Aim",
    Side = 1,
    Collapsible = true,
    Default = true
})

local Silent = AimSection:Toggle({
    Name     = "Enabled",
    Flag     = "SilentEnabled",
    Default  = false,
    Callback = function(v) end
})

Silent:Keybind({
    Flag    = "SilentKey",
    Default = Enum.KeyCode.X,
    Mode    = "Toggle"
})

Silent:Colorpicker({
    Flag    = "SilentColor",
    Default = Color3.fromRGB(255, 100, 255)
})

AimSection:Slider({
    Name     = "FOV",
    Flag     = "SilentFOV",
    Min      = 10,
    Max      = 500,
    Default  = 120,
    Suffix   = "px"
})

AimSection:Dropdown({
    Name    = "Hit Part",
    Flag    = "HitPart",
    Items   = {"Head", "Torso", "HumanoidRootPart"},
    Default = "Head"
})

local Buttons = AimSection:Button()
Buttons:Add({
    Name     = "Reset",
    Callback = function()
        Library:Modal({
            Title   = "Reset Settings?",
            Content = "This will restore aimbot defaults.",
            Buttons = {
                {"Yes", Color3.fromRGB(80, 200, 120), function()
                    Library.Flags["SilentEnabled"] = false
                end},
                {"No", nil, function() end}
            }
        })
    end
})

-- Settings + autoload
Library:CreateSettingsPage(Window, Watermark, KeybindList)
Library:CheckForAutoLoad()
```
