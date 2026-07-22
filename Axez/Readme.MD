# 🎨 Axez UI Library

based on Obsidian

## 📋 Table of Contents
- [Features](#-features)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Core Components](#-core-components)
  - [Window](#window)
  - [Tab Groups & Tabs](#tab-groups--tabs)
  - [Groupboxes](#groupboxes)
- [Widgets](#-widgets)
  - [Label](#label)
  - [Button](#button)
  - [Toggle](#toggle)
  - [Slider](#slider)
  - [Dropdown](#dropdown)
  - [Input](#input)
  - [Keybind](#keybind)
  - [Paragraph](#paragraph)
  - [ColorPicker](#colorpicker)
- [Advanced Features](#-advanced-features)
  - [Link Containers](#link-containers)
  - [Top Bar Buttons](#top-bar-buttons)
  - [Notifications](#notifications)
  - [Unload System](#unload-system)
  - [Draggable Label](#draggable-label)
  - [UI Toggle Button](#ui-toggle-button)
  - [Theme System](#theme-system)
- [Configuration](#-configuration)
- [Examples](#-examples)
- [API Reference](#-api-reference)
- [License](#-license)

---

## ✨ Features

- 🎨 **Complete Widget Set** - Labels, Buttons, Toggles, Sliders, Dropdowns, Inputs, Keybinds, Color Pickers
- 📱 **Mobile Support** - Automatically adapts to mobile devices
- 🎭 **Theme System** - Fully customizable colors with live preview
- 🔄 **Animations** - Smooth transitions with configurable easing
- 📦 **Layout Options** - Left/Right columns, Single column, Center alignment
- 🔗 **Link Containers** - Popup overlays, dropdowns, side panels
- 🔔 **Notifications** - Toast and normal notifications with multiple positions
- 🎯 **Unload System** - Cleanup callbacks on window close
- 🖱️ **Draggable & Resizable** - Move and resize windows
- 🌍 **DPI Scaling** - Support for different screen resolutions

---

## 📦 Installation

```lua
-- Load the library
local Library = loadstring(game:HttpGet(https://raw.githubusercontent.com/yungfuzi/L/refs/heads/main/Axez/Library.lua"))()
```

---

## 🚀 Quick Start

```lua
-- Create a window
local Window = Library:Window({
    Title = "My UI",
    Description = "Example Library",
    Icon = 1234567890,
    Size = UDim2.fromOffset(800, 500),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    SizeLocked = false,
    CornerRadius = 24
})

-- Add a tab group
local MainGroup = Window:AddTabGroup("Main", 1234567890)

-- Add a tab
local MainTab = MainGroup:AddTab("Controls", 1234567890)

-- Add a groupbox
local Group = MainTab:AddSingleGroupbox("Settings")

-- Add widgets
Group:AddLabel("Welcome to Axez UI")
Group:AddButton("Click Me", function()
    print("Button clicked!")
end)
```

---

## 🧩 Core Components

### Window

```lua
local Window = Library:Window({
    Title = "Window Title",              -- Window title
    Description = "Subtitle",            -- Window subtitle
    Icon = 1234567890,                   -- Optional: rbxassetid
    Size = UDim2.fromOffset(760, 450),   -- Window size
    Position = UDim2.new(0.5, 0, 0.5, 0),-- Window position
    SizeLocked = false,                  -- Prevent resizing
    CornerRadius = 24,                   -- Window corner radius
    DisableAnimations = false            -- Disable animations
})
```

#### Window Methods
```lua
Window:SetVisible(true/false)           -- Show/hide window
Window:Toggle()                         -- Toggle window visibility
Window:SetTitle("New Title")            -- Change window title
Window:SetDescription("New Desc")       -- Change window description
Window:SetDPI(1.2)                      -- Set DPI scaling
Window:ToggleThemeUi()                  -- Open theme settings
Window:Destroy()                        -- Destroy the window
Window:Unload()                         -- Unload with cleanup
Window:OnUnload(function)               -- Register cleanup callback
```

---

### Tab Groups & Tabs

#### Tab Group
```lua
local TabGroup = Window:AddTabGroup("Title", Icon, Collapsed)
```

**Methods:**
```lua
TabGroup:AddTab("Tab Name", Icon)       -- Add tab to group
TabGroup:SetCollapsed(true/false)       -- Collapse/expand group
TabGroup:Toggle()                       -- Toggle collapse state
TabGroup:SetTitle("New Title")          -- Change group title
TabGroup:SetIcon(Icon)                  -- Change group icon
TabGroup:SetVisible(true/false)         -- Show/hide group
TabGroup:Destroy()                      -- Destroy group
```

#### Tab
```lua
local Tab = TabGroup:AddTab("Name", Icon)
```

**Methods:**
```lua
Tab:Show()                              -- Show tab
Tab:Hide()                              -- Hide tab
Tab:AddSingleGroupbox(title, icon, collapsed, center)  -- Full width groupbox
Tab:AddLeftGroupbox(title, icon, collapsed, center)    -- Left column groupbox
Tab:AddRightGroupbox(title, icon, collapsed, center)   -- Right column groupbox
```

---

### Groupboxes

```lua
-- Single column (full width)
local Group = Tab:AddSingleGroupbox("Title", Icon, Collapsed, Center)

-- Two columns layout
local LeftGroup = Tab:AddLeftGroupbox("Left", Icon, Collapsed, Center)
local RightGroup = Tab:AddRightGroupbox("Right", Icon, Collapsed, Center)
```

**Parameters:**
- `Title` - Groupbox title
- `Icon` - Optional icon rbxassetid
- `Collapsed` - Start collapsed (default: false)
- `Center` - Center align title (default: false)

**Groupbox Methods:**
```lua
Group:SetCollapsed(true/false)          -- Collapse/expand
Group:Toggle()                          -- Toggle collapse
Group:SetTitle("New Title")             -- Change title
Group:SetIcon(Icon)                     -- Change icon
Group:SetCenter(true/false)             -- Toggle center alignment
Group:SetVisible(true/false)            -- Show/hide
Group:Destroy()                         -- Destroy groupbox
```

---

## 🎛️ Widgets

### Label

```lua
local Label = Group:AddLabel("Text", {
    Text = "Label Text"                  -- Display text
})
```

**Methods:**
```lua
Label:SetText("New Text")               -- Change label text
Label:SetVisible(true/false)            -- Show/hide label
Label:Destroy()                         -- Destroy label
Label:Link("Title", Config)             -- Add settings link (see Link Containers)
```

---

### Button

```lua
local Button = Group:AddButton("Text", function()
    print("Clicked!")
end)

-- Or with config
local Button = Group:AddButton("Text", {
    Text = "Button",
    Callback = function() print("Clicked!") end
})
```

**Methods:**
```lua
Button:SetText("New Text")              -- Change button text
Button:SetDisabled(true/false)          -- Enable/disable button
Button:SetVisible(true/false)           -- Show/hide button
Button:Destroy()                        -- Destroy button
```

---

### Toggle

```lua
local Toggle = Group:AddToggle("Enable Feature", true, function(Value)
    print("Toggle:", Value)
end)

-- With config
local Toggle = Group:AddToggle("Feature", {
    Text = "Feature",
    Default = false,
    Callback = function(v) print(v) end
})
```

**Methods:**
```lua
Toggle:SetValue(true/false)             -- Set toggle value
Toggle:Toggle()                         -- Toggle value
Toggle:SetDisabled(true/false)          -- Enable/disable
Toggle:SetText("New Text")              -- Change label
Toggle:SetVisible(true/false)           -- Show/hide
Toggle:Destroy()                        -- Destroy
Toggle:Link("Title", Config)            -- Add settings link
```

---

### Slider

```lua
local Slider = Group:AddSlider("Volume", {
    Text = "Volume",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Compact = false,
    Callback = function(Value)
        print("Volume:", Value)
    end
})
```

**Properties:**
- `Text` - Slider label
- `Default` - Default value
- `Min` - Minimum value (default: 0)
- `Max` - Maximum value (default: 100)
- `Rounding` - Decimal places (default: 0)
- `Suffix` - Text after value (e.g., "%")
- `Compact` - Compact mode (default: false)
- `Callback` - Function called on value change

**Methods:**
```lua
Slider:SetValue(75)                     -- Set slider value
Slider:SetDisabled(true/false)          -- Enable/disable
Slider:SetText("New Text")              -- Change label
Slider:SetVisible(true/false)           -- Show/hide
Slider:Destroy()                        -- Destroy
```

---

### Dropdown

```lua
-- Single selection
local Dropdown = Group:AddDropdown("Select", {
    Text = "Choose Option",
    Values = {"Option 1", "Option 2", "Option 3"},
    Default = 1,
    Multi = false,
    CloseOnSelected = true,
    Callback = function(Value)
        print("Selected:", Value)
    end
})

-- Multi selection
local MultiDropdown = Group:AddDropdown("Multi Select", {
    Text = "Choose Multiple",
    Values = {"Apple", "Banana", "Orange"},
    Multi = true,
    Default = {Apple = true},
    Callback = function(Value)
        for k, v in pairs(Value) do
            if v then print(k) end
        end
    end
})
```

**Methods:**
```lua
Dropdown:SetValue(Value)                -- Set selected value(s)
Dropdown:SetValues({"New", "Options"})  -- Update options
Dropdown:Open()                         -- Open dropdown
Dropdown:Close()                        -- Close dropdown
Dropdown:Toggle()                       -- Toggle dropdown
Dropdown:SetDisabled(true/false)        -- Enable/disable
Dropdown:SetText("New Text")            -- Change label
Dropdown:SetVisible(true/false)         -- Show/hide
Dropdown:Destroy()                      -- Destroy
```

---

### Input

```lua
local Input = Group:AddInput("Username", {
    Text = "Username",
    Default = "Player123",
    Placeholder = "Enter username...",
    Numeric = false,
    Finished = false,
    Callback = function(Value)
        print("Input:", Value)
    end
})
```

**Properties:**
- `Text` - Input label
- `Default` - Default text
- `Placeholder` - Placeholder text
- `Numeric` - Only accept numbers
- `Finished` - Callback on Enter press only
- `Callback` - Function called on input change

**Methods:**
```lua
Input:SetValue("New Text")              -- Set input value
Input:SetDisabled(true/false)           -- Enable/disable
Input:SetText("New Label")              -- Change label
Input:SetVisible(true/false)            -- Show/hide
Input:Destroy()                         -- Destroy
```

---

### Keybind

```lua
-- Hold keybind
local Keybind = Group:AddKeybind("Hold Key", {
    Text = "Hold Key",
    Default = Enum.KeyCode.LeftControl,
    NoHold = false,
    Callback = function(Held)
        print("Key held:", Held)
    end
})

-- Press keybind
local PressKey = Group:AddKeybind("Press Key", {
    Text = "Press Key",
    Default = Enum.KeyCode.F,
    NoHold = true,
    Callback = function()
        print("Key pressed!")
    end
})
```

**Properties:**
- `Text` - Keybind label
- `Default` - Default key (Enum.KeyCode)
- `NoHold` - Press instead of hold (default: false)
- `Callback` - Function called on key event

**Methods:**
```lua
Keybind:SetValue(Enum.KeyCode.G)        -- Set new key
Keybind:SetDisabled(true/false)         -- Enable/disable
Keybind:SetText("New Text")             -- Change label
Keybind:SetVisible(true/false)          -- Show/hide
Keybind:Destroy()                       -- Destroy
```

---

### Paragraph

```lua
local Paragraph = Group:AddParagraph("Info", {
    Title = "Information",
    Content = "This is a paragraph with rich text support.",
    TitleSize = 16,
    ContentSize = 12,
    TitleTransparency = 0,
    ContentTransparency = 0.3,
    Spacing = 8,
    RichText = true,
    Alignment = Enum.TextXAlignment.Left,
    TitleXAlignment = Enum.TextXAlignment.Left
})
```

**Methods:**
```lua
Paragraph:SetTitle("New Title")         -- Change title
Paragraph:SetContent("New Content")     -- Change content
Paragraph:SetVisible(true/false)        -- Show/hide
Paragraph:Destroy()                     -- Destroy
```

---

### ColorPicker

```lua
local ColorPicker = Group:AddColorPicker("Pick Color", {
    Text = "Select Color",
    Default = Color3.fromRGB(0, 200, 255),
    Transparency = 0,
    Callback = function(Color, Alpha)
        print("Color:", Color, "Alpha:", Alpha)
    end
})
```

**Methods:**
```lua
ColorPicker:SetValue(Color, Transparency)  -- Set color
ColorPicker:SetVisible(true/false)         -- Show/hide
ColorPicker:Destroy()                      -- Destroy
```

---

## 🚀 Advanced Features

### Link Containers

Link containers are settings popups that can contain any widget.

#### Type 1: Overlay Popup
```lua
local Link = Label:Link("Settings", {
    Type = 1  -- Overlay popup
})

-- Add widgets to link
Link:AddLabel("Sub Settings")
Link:AddToggle("Enable", {
    Default = false,
    Callback = function(v) print(v) end
})
Link:AddButton("Save", function() print("Saved!") end)
```

#### Type 2: Dropdown Style
```lua
local Link = Toggle:Link("More Options", {
    Type = 2  -- Dropdown style
})
```

#### Type 3: Side Panel
```lua
local Link = Toggle:Link("Advanced", {
    Type = 3  -- Side panel
})
```

**Available Methods:**
```lua
Link:AddLabel("Text")                   -- Add label
Link:AddButton("Text", Callback)        -- Add button
Link:AddToggle("Text", Default, Callback)-- Add toggle
Link:AddSlider("Text", Config)          -- Add slider
Link:AddDropdown("Text", Config)        -- Add dropdown
Link:AddInput("Text", Config)           -- Add input
Link:AddKeybind("Text", Config)         -- Add keybind
Link:AddParagraph("Text", Config)       -- Add paragraph
Link:AddColorPicker("Text", Config)     -- Add color picker
```

---

### Top Bar Buttons

```lua
local Btn = Window:AddTopBarButton({
    Text = "Settings",                   -- Button text (optional)
    Icon = 106205298246017,              -- Icon rbxassetid
    IconSize = 16,                       -- Icon size
    Type = "corner",                     -- "corner" or "circle"
    AlwaysShow = false,                  -- Always show text
    HideBackground = false,              -- Hide background
    Callback = function()
        print("Button clicked!")
    end
})
```

**Methods:**
```lua
Btn:SetCallback(function)               -- Change callback
Btn:SetVisible(true/false)              -- Show/hide
Btn:SetDisabled(true/false)             -- Enable/disable
Btn:Destroy()                           -- Destroy
```

---

### Notifications

```lua
-- Normal notification
Library:Notify({
    Title = "Notification",
    Content = "This is a notification",
    Icon = 77937190465422,
    Duration = 3,
    Type = 1,                            -- 1: Normal, 2: Toast
    Pos = "right"                        -- "right", "left", "top-center"
})

-- Toast notification
Library:Notify({
    Title = "Toast",
    Content = "This is a toast",
    Type = 2,
    Pos = "top-center",
    Duration = 2
})
```

---

### Unload System

```lua
-- Register cleanup callback
Window:OnUnload(function()
    game:GetService("SoundService").Volume = 1
end)

-- Multiple callbacks
Window:OnUnload(function() print("Callback 1") end)
Window:OnUnload(function() print("Callback 2") end)

-- Unload window
Window:Unload()
```

---

### Draggable Label

```lua
local Label = Window:DraggableLabel({
    Text = "⚡ Draggable Label",
    Position = UDim2.new(0.5, 0, 0.02, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    AutoSize = true,
    MaxWidth = 300,
    TextSize = 14,
    BackgroundTransparency = 0.2,
    CornerRadius = 8,
    Padding = {X = 20, Y = 10},
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center
})
```

**Methods:**
```lua
Label:SetText("New Text")               -- Change text
Label:SetVisible(true/false)            -- Show/hide
Label:SetSize(UDim2)                    -- Set size
Label:SetPosition(UDim2)                -- Set position
Label:SetTextSize(16)                   -- Change text size
Label:SetTextColor(Color3)              -- Change text color
Label:SetTextXAlignment(Enum)           -- Change alignment
Label:SetBackgroundTransparency(0.5)    -- Change background
Label:Destroy()                         -- Destroy
```

---

### UI Toggle Button

```lua
Window:UIToggleButton({
    Icon = "rbxassetid://101007429951147",
    Position = UDim2.new(0.02, 0, 0.5, 0),
    Size = UDim2.fromOffset(44, 44)
})
```

---

### Theme System

```lua
-- Open theme settings
Window:ToggleThemeUi()

-- Custom colors
Library.Scheme = {
    BackgroundColor = Color3.fromRGB(15, 15, 15),
    MainColor = Color3.fromRGB(25, 25, 25),
    AccentColor = Color3.fromRGB(0, 200, 255),
    OutlineColor = Color3.fromRGB(40, 40, 40),
    FontColor = Color3.new(1, 1, 1),
    Font = Font.fromEnum(Enum.Font.Roboto),
    RedColor = Color3.fromRGB(255, 50, 50),
    DestructiveColor = Color3.fromRGB(220, 38, 38),
    DarkColor = Color3.new(0, 0, 0),
    WhiteColor = Color3.new(1, 1, 1)
}

-- Update all colors
Library:UpdateColors()
```

---

## ⚙️ Configuration

### Library Configuration
```lua
Library.Animation = {
    Enabled = true,
    Duration = 0.25,
    EasingStyle = Enum.EasingStyle.Quad,
    EasingDirection = Enum.EasingDirection.Out
}

Library.MinSize = Vector2.new(480, 360)  -- Minimum window size
Library.DPIScale = 1                     -- DPI scaling
Library.IsMobile = false                 -- Mobile mode (auto-detected)
```

### Color Scheme Keys
```lua
-- Available color keys:
"BackgroundColor"   -- Main background
"MainColor"         -- Secondary background
"AccentColor"       -- Highlight color
"OutlineColor"      -- Border color
"FontColor"         -- Text color
"RedColor"          -- Error/delete color
"DestructiveColor"  -- Destructive actions
"DarkColor"         -- Dark overlays
"WhiteColor"        -- White elements
```

---

## 💡 Examples

### Complete Example with All Features

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/yungfuzi/L/refs/heads/main/Axez/Library.lua"))()

local Window = Library:Window({
    Title = "Axez UI Demo",
    Description = "Complete Example",
    Size = UDim2.fromOffset(800, 500),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    SizeLocked = false,
    CornerRadius = 24
})

-- Unload callbacks
Window:OnUnload(function()
    
end)

-- Add main group
local MainGroup = Window:AddTabGroup("Main", 1234567890)
local MainTab = MainGroup:AddTab("Controls", 1234567890)

-- Left groupbox
local LeftGroup = MainTab:AddLeftGroupbox("Settings", 1234567890)

-- Toggle
local Toggle = LeftGroup:AddToggle("Enable Feature", true, function(v)
    print("Toggle:", v)
end)

-- Slider
local Slider = LeftGroup:AddSlider("Volume", {
    Default = 50,
    Min = 0,
    Max = 100,
    Suffix = "%",
    Callback = function(v)
        print("Volume:", v)
        game:GetService("SoundService").Volume = v / 100
    end
})

-- Dropdown
local Dropdown = LeftGroup:AddDropdown("Select", {
    Values = {"Option 1", "Option 2", "Option 3"},
    Callback = function(v) print("Selected:", v) end
})

-- Right groupbox
local RightGroup = MainTab:AddRightGroupbox("Actions", 1234567890)

-- Button
RightGroup:AddButton("Click Me", function()
    Library:Notify({
        Title = "Button",
        Content = "You clicked the button!",
        Duration = 2
    })
end)

-- Input
RightGroup:AddInput("Username", {
    Placeholder = "Enter username...",
    Callback = function(v) print("Username:", v) end
})

-- Keybind
RightGroup:AddKeybind("Keybind", {
    Default = Enum.KeyCode.F,
    NoHold = true,
    Callback = function() print("Key pressed!") end
})

-- Advanced group
local AdvancedGroup = Window:AddTabGroup("Advanced", 1234567890)
local AdvTab = AdvancedGroup:AddTab("Tools", 1234567890)
local AdvGroup = AdvTab:AddSingleGroupbox("Advanced Tools", 1234567890)

-- ColorPicker
AdvGroup:AddColorPicker("Pick Color", {
    Default = Color3.fromRGB(0, 200, 255),
    Callback = function(Color, Alpha)
        print("Color:", Color, "Alpha:", Alpha)
    end
})

-- Paragraph
AdvGroup:AddParagraph("Info", {
    Title = "Information",
    Content = "This is a paragraph with <b>rich text</b> support.",
    RichText = true
})

-- Top bar button
Window:AddTopBarButton({
    Text = "Theme",
    Icon = 106205298246017,
    Callback = function() Window:ToggleThemeUi() end
})

Window:AddTopBarButton({
    Text = "Notify",
    Icon = 77937190465422,
    Callback = function()
        Library:Notify({
            Title = "Notification",
            Content = "This is a notification!",
            Type = 1,
            Duration = 2
        })
    end
})

-- Draggable label
Window:DraggableLabel({
    Text = "✨ Axez UI",
    Position = UDim2.new(0.5, 0, 0.02, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    AutoSize = true
})

-- UI Toggle button
Window:UIToggleButton()

-- Register unload callbacks
Window:OnUnload(function()
    print("✅ Cleanup complete!")
end)

print("✅ UI loaded successfully!")
```

---

## 📚 API Reference

### Library Object

| Method | Description |
|--------|-------------|
| `:Window(info)` | Create a new window |
| `:Notify(config)` | Show a notification |
| `:OnUnload(callback)` | Register unload callback |
| `:Unload()` | Unload library |
| `:UpdateColors()` | Update all colors from scheme |
| `:GetCustomIcon(id)` | Get icon data from rbxassetid |

### Window Object

| Method | Description |
|--------|-------------|
| `:AddTabGroup(title, icon, collapsed)` | Add tab group |
| `:AddTab(name, icon)` | Add tab (outside group) |
| `:AddTopBarButton(config)` | Add top bar button |
| `:UIToggleButton(config)` | Add toggle button |
| `:DraggableLabel(config)` | Add draggable label |
| `:ToggleThemeUi()` | Open theme settings |
| `:SetVisible(bool)` | Show/hide window |
| `:Toggle()` | Toggle visibility |
| `:SetTitle(text)` | Change title |
| `:SetDescription(text)` | Change description |
| `:SetDPI(scale)` | Set DPI scaling |
| `:Destroy()` | Destroy window |
| `:Unload()` | Unload with cleanup |
| `:OnUnload(callback)` | Register cleanup callback |

### Widget Methods

All widgets support these basic methods:
- `:SetVisible(bool)` - Show/hide
- `:Destroy()` - Destroy widget

And specific methods for each widget type as documented above.

---

## 📄 License

MIT License - Free to use and modify.

---

## 🙏 Credits

- **Library**: Axez UI
- **Design**: Modern, clean, responsive
- **Built with**: Claude


---

## 🔗 Links

---

**Made with ❤️ for the Roblox community**
