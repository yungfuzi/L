# Lyra

A clean, dark Roblox UI library with sharp outer frames, rounded groupboxes, and full mobile support.

## Features

- Window with centered title and traffic-light dots
- Tabs with isolated content
- Left / right groupboxes
- Toggle, Button, Slider, Dropdown, Input, Label, ColorPicker, KeyPicker
- `:Link()` nested settings popup on Toggle and Label
- Dependency boxes
- Notifications, dialogs, loading screen
- Theme registry
- Config save / load stubs
- Executor compatible (`gethui`, `protectgui`, etc.)
- Mobile toggle button

## Load

```lua
local Library = loadstring(game:HttpGet("YOUR_LIBRARY_URL"))()
```

## Quick Start

```lua
local Window = Library:CreateWindow({
    Title = "Lyra",
    Size = UDim2.fromOffset(580, 440),
    Center = true,
    AutoShow = true,
})

local Tab = Window:AddTab("Main")
local Left = Tab:AddLeftGroupbox({ Name = "Combat" })
local Right = Tab:AddRightGroupbox({ Name = "Settings" })

Left:AddToggle({
    Text = "Aimbot",
    Default = false,
    Description = "Locks onto the nearest enemy",
    Callback = function(Value)
        print(Value)
    end,
})
```

## Window

```lua
local Window = Library:CreateWindow({
    Title = "Lyra",
    Size = UDim2.fromOffset(560, 420),
    Center = true,
    AutoShow = true,
})

Window:SetVisible(true)
Window:Toggle()
```

Toggle key defaults to `RightShift`. Change with:

```lua
Library.ToggleKey = Enum.KeyCode.RightControl
```

## Tabs

```lua
local Tab = Window:AddTab("Main")
local Left = Tab:AddLeftGroupbox({ Name = "Group" })
local Right = Tab:AddRightGroupbox({ Name = "Group" })
```

## Elements

### Toggle

```lua
local Toggle = Groupbox:AddToggle({
    Text = "Enabled",
    Default = false,
    Risky = false,
    Description = "Optional description",
    Callback = function(Value) end,
})

Toggle:Set(true)
print(Toggle.Value)
```

### Button

```lua
Groupbox:AddButton({
    Text = "Click Me",
    Description = "Optional description",
    Callback = function() end,
})
```

### Slider

```lua
local Slider = Groupbox:AddSlider({
    Text = "FOV",
    Default = 90,
    Min = 0,
    Max = 180,
    Rounding = 0,
    Prefix = "",
    Suffix = "°",
    Description = "Optional description",
    Callback = function(Value) end,
})

Slider:Set(120)
print(Slider.Value)
```

### Dropdown

```lua
local Dropdown = Groupbox:AddDropdown({
    Text = "Part",
    Values = {"Head", "Torso"},
    Default = "Head",
    Multi = false,
    Search = false,
    Description = "Optional description",
    Callback = function(Value) end,
})

-- Special types
Groupbox:AddDropdown({
    Text = "Players",
    SpecialType = "Player",
    Multi = true,
    Search = true,
    Callback = function(Value) end,
})

Groupbox:AddDropdown({
    Text = "Teams",
    SpecialType = "Team",
    Callback = function(Value) end,
})
```

### Input

```lua
local Input = Groupbox:AddInput({
    Text = "Webhook",
    Default = "",
    Placeholder = "https://...",
    Numeric = false,
    Finished = true,
    ClearTextOnFocus = false,
    Description = "Optional description",
    Callback = function(Text) end,
})

Input:Set("hello")
print(Input.Value)
```

### Label

```lua
local Label = Groupbox:AddLabel({
    Text = "Status: Ready",
    Description = "Optional description",
})

Label:SetText("Status: Running")
```

### ColorPicker

```lua
local Picker = Groupbox:AddColorPicker({
    Text = "Accent",
    Default = Color3.fromRGB(105, 160, 240),
    Transparency = 0,
    Description = "Optional description",
    Callback = function(Color, Transparency) end,
})

Picker:Set(Color3.fromRGB(255, 0, 0))
```

### KeyPicker

```lua
local Key = Groupbox:AddKeyPicker({
    Text = "Aim Key",
    Default = "E",
    Mode = "Hold",
    Description = "Optional description",
    Callback = function(Active) end,
})

-- Modes: "Always", "Toggle", "Hold", "Press"
Key:Set("Q")
```

## Link

Attach a settings gear to a Toggle or Label. Opens a nested popup.

```lua
local Toggle = Groupbox:AddToggle({ Text = "Aimbot", Default = false })
local Link = Toggle:Link()

Link:AddToggle({ Text = "Visible Check", Default = true, Callback = function(v) end })
Link:AddSlider({ Text = "Smooth", Default = 0.3, Min = 0, Max = 1, Rounding = 2 })
Link:AddDropdown({ Text = "Part", Values = {"Head", "Torso"}, Default = "Head" })
Link:AddColorPicker({ Text = "Color", Default = Color3.fromRGB(255, 80, 80) })
Link:AddKeyPicker({ Text = "Key", Default = "E", Mode = "Hold" })
Link:AddButton({ Text = "Reset", Callback = function() end })
Link:AddInput({ Text = "Value", Default = "100", Numeric = true })
Link:AddLabel("Extra options")
```

Same API works on labels:

```lua
local Label = Groupbox:AddLabel({ Text = "Status" })
local Link = Label:Link()
```

## Dependency Box

Show or hide elements based on a condition.

```lua
local Toggle = Groupbox:AddToggle({
    Text = "Aimbot",
    Default = false,
    Callback = function()
        DepBox:Update()
    end,
})

local DepBox = Groupbox:AddDependencyBox()
DepBox:Setup(function()
    return Toggle.Value
end)

DepBox:AddSlider({
    Text = "Range",
    Default = 150,
    Min = 50,
    Max = 500,
})

DepBox:AddToggle({ Text = "Team Check", Default = true })
```

Call `DepBox:Update()` whenever the controlling value changes.

## Overlays

### Notification

```lua
Library:Notify({
    Title = "Success",
    Content = "Action completed",
    Duration = 5,
})
```

### Dialog

```lua
Library:CreateDialog({
    Title = "Confirm",
    Content = "Are you sure?",
    Buttons = {
        { Text = "Yes", Callback = function() end },
        { Text = "No", Callback = function() end },
    },
})
```

Click the backdrop or a button to close.

### Loading

```lua
local Frame = Library:ShowLoading("Please wait...")
task.delay(2, function()
    Frame:Destroy()
end)
```

## Theme

```lua
Library.Scheme = {
    Background = Color3.fromRGB(14, 14, 14),
    Accent = Color3.fromRGB(105, 160, 240),
    Outline = Color3.fromRGB(34, 34, 34),
    Inline = Color3.fromRGB(22, 22, 22),
    FontColor = Color3.fromRGB(230, 230, 230),
    DimmedFont = Color3.fromRGB(140, 140, 140),
    Risky = Color3.fromRGB(240, 100, 100),
    GroupBackground = Color3.fromRGB(18, 18, 18),
}

Library:UpdateRegistry()
```

## Config

```lua
Library:SaveConfig("default")
local data = Library:LoadConfig("default")
```

## Cleanup

```lua
Library:Destroy()
```

## Options

| Property | Default | Description |
|----------|---------|-------------|
| `Library.Animations` | `true` | Enable tweens |
| `Library.ToggleKey` | `RightShift` | Key to show/hide UI |
| `Library.Corner` | `UDim.new(0, 6)` | Radius for rounded elements |
| `Library.IsMobile` | auto | Touch device detection |
