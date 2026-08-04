# Aether

Modern Roblox Luau UI library with a dual-column layout, smooth animations, theme system, and a clean method-based API.

**Highlights**
- One shared `ScrollingFrame` per tab (left + right columns scroll together)
- Full-width groupboxes, nested sections, headerless variants
- Toggle variants: Switch / Checkbox / Button
- Element **Link** panels (Popup / Side)
- Dynamic Island style hide + floating toggle button
- Live theme registry, search, notifications, keybind unload

---

## Load

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/Aether/main/Aether.lua"))()
```

Replace `USERNAME` with your GitHub username / org.

Local / Studio:

```lua
local Library = require(path.to.Aether) -- if converted to ModuleScript
-- or
loadstring(readfile("Aether.lua"))()
```

---

## Quick start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/Aether/main/Aether.lua"))()

local Window = Library:CreateWindow({
    Title = "Aether",
    Size = UDim2.fromOffset(780, 560),
    Center = true,
    Resizable = true,
    Searchbar = true,
    ToggleKeybind = Enum.KeyCode.RightControl,
})

Window:AddTabSection({ Text = "Main", Collapsible = true })

local Tab = Window:AddTab({ Name = "Combat" })
local Left = Tab:AddLeftGroupbox("Aimbot")
local Right = Tab:AddRightGroupbox("Visuals")

Left:AddToggle("Aimbot", {
    Text = "Aimbot",
    Default = false,
    Variant = "Switch",
    Callback = function(Value)
        print("Aimbot:", Value)
    end,
})

Left:AddSlider("FOV", {
    Text = "FOV",
    Min = 10,
    Max = 180,
    Default = 90,
    Rounding = 0,
    Suffix = "°",
})

Right:AddColorPicker("ESPColor", {
    Text = "ESP Color",
    Default = Color3.fromRGB(110, 90, 255),
})

Library:Notify("Aether loaded", 3, "success")
```

---

## Window

### CreateWindow

```lua
local Window = Library:CreateWindow({
    Title = "Aether",
    Size = UDim2.fromOffset(780, 560),
    Center = true,
    Resizable = true,
    Searchbar = true,
    SidebarWidth = 168,
    ToggleKeybind = Enum.KeyCode.RightControl,
    AutoShow = true,
    StackColumnsOnMobile = false,
})
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `Title` | string | `"Aether"` | Top bar title |
| `Size` | UDim2 | `760x520` | Initial window size |
| `Center` | boolean | `true` | Center on screen |
| `Resizable` | boolean | `true` | Corner resize grip |
| `Searchbar` | boolean | `true` | Sidebar search field |
| `SidebarWidth` | number | `168` | Sidebar width (px) |
| `ToggleKeybind` | KeyCode | `RightControl` | Show / hide key |
| `AutoShow` | boolean | `true` | Show on create |
| `StackColumnsOnMobile` | boolean | `false` | Keep dual columns on mobile |

### Visibility

```lua
Window:Show()
Window:Hide()
Window:Toggle()          -- flip
Window:Toggle(true)      -- force show
Window:Toggle(false)     -- force hide
Window:IsVisible()
Window:Destroy()
```

Also available globally:

```lua
Library:Toggle()
Library.Show()
Library.Hide()
```

### Tab sections

Sidebar section headers (group tabs):

```lua
Window:AddTabSection({
    Text = "Combat",
    Collapsible = true,     -- default false
    XAlignments = "Left",   -- Left | Center | Right
    Icon = nil,             -- optional icon key / rbxassetid
})
```

Tabs created **after** a section are grouped under it. Collapsible sections hide/show those tab buttons.

### Tabs

```lua
local Tab = Window:AddTab({ Name = "Aimbot", Icon = nil })
-- or
Window:AddTab("Aimbot")
```

```lua
Tab:Show()
Tab:Hide()
Tab:Destroy()
```

### Groupboxes

```lua
local Left  = Tab:AddLeftGroupbox("Main")
local Right = Tab:AddRightGroupbox("Settings")
local Full  = Tab:AddFullGroupbox("Advanced")

-- unified form
Tab:AddGroupbox({
    Side = "Left",          -- Left | Right | Full
    Name = "Main",
    Variant = 1,            -- 1 = header + collapse, 2 = headerless
    Transparency = 0,       -- background transparency
    Collapsible = true,     -- force header/collapse even on full
})
```

| Variant | Behavior |
|---------|----------|
| `1` (default) | Title header + collapse chevron |
| `2` | No header, no collapse (plain box) |

```lua
Box:SetTitle("New title")
Box:SetCollapsed(true)
Box:ToggleCollapse()
Box:SetVisible(false)
Box:Destroy()
Box:Resize()
```

### Nested sections (inside a groupbox)

Best with full-width boxes. Side `1` / `2` sit **inside** the parent:

```lua
local Full = Tab:AddGroupbox({ Side = "Full", Name = "Advanced", Collapsible = true })

local Rage  = Full:GroupBoxSection(1, "Rage")   -- left half
local Legit = Full:GroupBoxSection(2, "Legit")  -- right half
local Notes = Full:GroupBoxSection("Notes")     -- full width inside parent

Rage:AddToggle("RageBot", { Text = "Rage Bot" })
```

---

## Elements

All element methods return an object with `SetValue` / `SetVisible` / `Destroy` (where applicable).  
Flags are stored in `Library.Flags[flag]`.

### Toggle

```lua
local Tog = Box:AddToggle("FlagName", {
    Text = "Aimbot",
    Default = false,
    Variant = "Switch",   -- Switch | Checkbox | Button
    Risky = false,
    Disabled = false,
    Callback = function(Value) end,
    Changed = function(Value) end,
})

Tog:SetValue(true)
Tog:GetValue()
Tog:SetText("New")
Tog:SetDisabled(true)
Tog:SetVisible(false)
Tog:Destroy()
```

Alias:

```lua
Box:AddCheckbox("Flag", { Text = "Check me" })
```

### Link (Toggle + Label)

Opens a settings panel you can fill with more elements.

```lua
local Link = Tog:Link("Popup")  -- or "Side"
Link:AddSlider("Smooth", { Text = "Smoothness", Min = 1, Max = 20, Default = 5 })
Link:AddToggle("TeamCheck", { Text = "Team Check", Default = true })
Link:Open()
Link:Close()
Link:Toggle()
Link:IsOpen()
```

| Toggle variant | Gear position |
|----------------|---------------|
| Switch | Left of the switch |
| Checkbox | Far right |
| Button | **Not supported** |
| Label | Far right |

| Link mode | Behavior |
|-----------|----------|
| `"Popup"` | Floating panel under the gear button |
| `"Side"` | 25% width, full height, inside the window, slides from top |

```lua
local Lbl = Box:AddLabel({ Text = "Extra" })
local Side = Lbl:Link("Side")
Side:AddParagraph({ Title = "Info", Desc = "Side panel content." })
```

### Slider

```lua
Box:AddSlider("WalkSpeed", {
    Text = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Rounding = 0,
    Prefix = "",
    Suffix = " studs",
    Callback = function(Value) end,
})
```

### Button

```lua
Box:AddButton({
    Text = "Refresh",
    Risky = false,          -- red style when true
    Callback = function() end,
})
```

### Input

```lua
Box:AddInput("PlayerName", {
    Text = "Player",
    Default = "",
    Placeholder = "Name...",
    Callback = function(Text) end,
})
```

### Dropdown

```lua
Box:AddDropdown("Mode", {
    Text = "Mode",
    Values = { "A", "B", "C" },
    Default = "A",
    Callback = function(Value) end,
})

Box:AddMultiDropdown("Ignore", {
    Text = "Ignore",
    Values = { "Friends", "Clan", "NPCs" },
    Default = { "Friends" },
    Callback = function(Values) end,
})
```

### KeyPicker

```lua
Box:AddKeyPicker("ToggleKey", {
    Text = "Key",
    Default = "E",
    Callback = function(Key) end,
})
```

### ColorPicker

HSV square + hue bar + hex / hsl / rgb fields.

```lua
Box:AddColorPicker("Accent", {
    Text = "Accent",
    Default = Color3.fromRGB(110, 90, 255),
    Callback = function(Color) end,
})
```

### Label / Paragraph / Space / Divider

```lua
Box:AddLabel({
    Text = "Section title",
    TextSize = 12,
    Color = Color3.fromRGB(200, 200, 210),
    Center = false,
    Wrapped = false,
})

Box:AddParagraph({
    Title = "Note",
    Desc = "Long description text goes here.",
    TitleSize = 13,
    DescSize = 12,
})

Box:Space(8)        -- or Box:AddSpace(8)
Box:AddDivider()
```

Paragraph APIs: `:SetTitle`, `:SetDesc`, `:SetText`, `:SetVisible`, `:Destroy`  
Space APIs: `:SetLength`, `:SetVisible`, `:Destroy`

---

## ToggleUiButton

Floating button to show / hide the window.

```lua
local Btn = Window:ToggleUiButton({
    Text = "UI",
    Image = "rbxassetid://...",   -- optional
    ImageOnly = false,            -- fill button with image
    ImageScaleType = "Fit",       -- Stretch | Fit | Crop | Tile | Slice
    Round = true,
    Size = 44,
    OnlyMobile = false,
    Draggable = true,
    Position = UDim2.new(1, -18, 1, -18),
    AnchorPoint = Vector2.new(1, 1),
    Callback = nil,               -- default: Window:Toggle()
})

Btn:SetText("Menu")
Btn:SetImage("rbxassetid://...")
Btn:SetImageScaleType("Crop")
Btn:SetVisible(true)
Btn:SetPosition(UDim2.new(1, -18, 1, -18))
Btn:SetSize(48)
Btn:SetColor(Color3.fromRGB(110, 90, 255))
Btn:Destroy()
```

---

## DynamicUi (Dynamic Island)

When the window hides, it shrinks / slides up and a pill drops in from the top. Click the pill to restore.

```lua
local Island = Window:DynamicUi({
    Text = "Aether",
    Icon = "rbxassetid://...",
    ImageOnly = false,
    ImageScaleType = "Fit",
    Size = UDim2.fromOffset(160, 34),
})

Island:SetText("Aether")
Island:SetIcon("rbxassetid://...")
Island:SetImageScaleType("Crop")
Island:SetVisible(true)
Island:Destroy()
```

---

## Notifications

```lua
Library:Notify("Hello", 3)                 -- info
Library:Notify("Saved", 2, "success")
Library:Notify("Careful", 2, "warning")
Library:Notify("Failed", 2, "error")
```

Notifications slide in from the right and slide out off-screen.

---

## Theme

```lua
Library:SetTheme({
    Accent     = Color3.fromRGB(140, 80, 255),
    AccentDark = Color3.fromRGB(100, 50, 200),
    Background = Color3.fromRGB(16, 16, 20),
    Surface    = Color3.fromRGB(22, 22, 28),
    Element    = Color3.fromRGB(30, 30, 38),
    Text       = Color3.fromRGB(235, 235, 245),
    SubText    = Color3.fromRGB(140, 140, 160),
    Border     = Color3.fromRGB(40, 40, 52),
    Success    = Color3.fromRGB(70, 200, 120),
    Warning    = Color3.fromRGB(230, 180, 60),
    Danger     = Color3.fromRGB(230, 70, 80),
})

Library:UpdateTheme()
```

Registered instances update live when the theme changes.

---

## Animations

```lua
Library:SetAnimationConfig("Slider", {
    Time = 0.28,
    Style = Enum.EasingStyle.Quint,
    Direction = Enum.EasingDirection.Out,
})
```

Keys: `Default`, `Window`, `Tab`, `Collapse`, `Notify`, `Toggle`, `Slider`, `Drag`, `Hover`.

Toggle global flags via `Library.Animations` (e.g. `Library.Animations.Enabled = false`).

---

## Search

Enabled with `Searchbar = true` on the window. Filters elements / groupboxes while keeping the single-scroller layout.

```lua
Library:UpdateSearch("aim")
```

---

## Flags & options

```lua
print(Library.Flags.Aimbot)
print(Library.Flags.WalkSpeed)
```

Element objects are also tracked when a flag is provided.

---

## Icons

Built-in keys (override via `Library.Icons`):

| Key | Usage |
|-----|--------|
| `Close` | Close buttons |
| `ChevronRight` | Collapse / sections |
| `ChevronUpDown` | Dropdowns |
| `Search` | Search bar |
| `Keyboard` | Key picker |
| `Loader` | Loading |
| `Input` | Text fields |
| `Settings` | Link gear button |

```lua
Library.Icons.Settings = "rbxassetid://106205298246017"
```

---

## Unload

```lua
Library:Unload()
```

Destroys the UI, cleans connections, and sets `Library.Unloaded = true`.

---

## Layout notes

```
┌─────────────────────────────────────────────┐
│ Title bar                                   │
├──────────┬──────────────────────────────────┤
│ Search   │                                  │
│ Section  │  ┌ Left Groupbox ┐ ┌ Right GB ┐ │
│  Tab     │  │ elements      │ │ elements │ │
│  Tab     │  └───────────────┘ └──────────┘ │
│ Section  │  ┌──── Full Groupbox ─────────┐ │
│  Tab     │  │  Sec(1)    │   Sec(2)      │ │
│          │  └────────────────────────────┘ │
└──────────┴──────────────────────────────────┘
```

- **One** `ScrollingFrame` per tab
- Left / Right columns always side-by-side
- Full groupboxes stack above the dual columns
- No per-groupbox scrollbars

---

## File map

```text
Aether/
├── Aether.lua      -- library
├── example.lua     -- demo (loadstring only, no comments)
└── README.md
```

---

## License

MIT — free to use, modify, and distribute. Credit appreciated but not required.
