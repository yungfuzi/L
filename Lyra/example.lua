local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/yungfuzi/L/refs/heads/main/Lyra/Library.lua"))()

Library.Scheme.Accent = Color3.fromRGB(130, 180, 255)
Library.Scheme.Background = Color3.fromRGB(12, 12, 14)
Library.Scheme.GroupBackground = Color3.fromRGB(16, 16, 18)
Library.Animations = true
Library.ToggleKey = Enum.KeyCode.RightShift

local Window = Library:CreateWindow({
    Title = "Lyra",
    Size = UDim2.fromOffset(580, 440),
    Center = true,
    AutoShow = true,
})

local MainTab = Window:AddTab("Main")
local VisualsTab = Window:AddTab("Visuals")
local MiscTab = Window:AddTab("Misc")

local Combat = MainTab:AddLeftGroupbox({ Name = "Combat" })

local AimbotToggle = Combat:AddToggle({
    Text = "Aimbot",
    Default = false,
    Description = "Locks onto the nearest enemy",
    Callback = function(Value)
        print("Aimbot:", Value)
        if DepBox then DepBox:Update() end
    end,
})

local AimbotLink = AimbotToggle:Link()

AimbotLink:AddToggle({
    Text = "Visible Check",
    Default = true,
    Callback = function(v)
        print("Visible Check:", v)
    end,
})

AimbotLink:AddSlider({
    Text = "Prediction",
    Default = 0.1,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(v) end,
})

AimbotLink:AddDropdown({
    Text = "Hit Part",
    Values = {"Head", "Torso", "HumanoidRootPart"},
    Default = "Head",
    Callback = function(v)
        print("Hit Part:", v)
    end,
})

AimbotLink:AddColorPicker({
    Text = "FOV Color",
    Default = Color3.fromRGB(255, 80, 80),
    Callback = function(c) end,
})

AimbotLink:AddKeyPicker({
    Text = "Aim Key",
    Default = "E",
    Mode = "Hold",
    Callback = function(active) end,
})

AimbotLink:AddButton({
    Text = "Reset Aimbot",
    Callback = function()
        print("Aimbot reset")
    end,
})

AimbotLink:AddInput({
    Text = "Custom FOV",
    Default = "90",
    Numeric = true,
    Callback = function(n) end,
})

AimbotLink:AddLabel("Advanced options")

Combat:AddToggle({
    Text = "Silent Aim",
    Default = false,
    Risky = true,
    Description = "Server-side aim correction",
    Callback = function(v)
        print("Silent Aim:", v)
    end,
})

Combat:AddSlider({
    Text = "FOV",
    Default = 90,
    Min = 30,
    Max = 180,
    Rounding = 0,
    Suffix = "°",
    Description = "Field of view of the aimbot",
    Callback = function(v)
        print("FOV:", v)
    end,
})

Combat:AddSlider({
    Text = "Smoothness",
    Default = 0.25,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Description = "Lower is snappier",
    Callback = function(v) end,
})

Combat:AddDropdown({
    Text = "Target Part",
    Values = {"Head", "Torso", "HumanoidRootPart", "UpperTorso"},
    Default = "Head",
    Description = "Body part to lock onto",
    Callback = function(v)
        print("Target part:", v)
    end,
})

Combat:AddDropdown({
    Text = "Players",
    SpecialType = "Player",
    Multi = true,
    Search = true,
    Description = "Select targets from the server",
    Callback = function(selected)
        print("Selected players:", selected)
    end,
})

local Settings = MainTab:AddRightGroupbox({ Name = "Settings" })

Settings:AddInput({
    Text = "Webhook URL",
    Default = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Finished = true,
    Description = "Discord webhook for logs",
    Callback = function(text)
        print("Webhook:", text)
    end,
})

Settings:AddInput({
    Text = "Max Distance",
    Default = "250",
    Numeric = true,
    Description = "Maximum lock distance in studs",
    Callback = function(n)
        print("Max distance:", n)
    end,
})

Settings:AddButton({
    Text = "Force Reset",
    Description = "Respawns your character",
    Callback = function()
        local char = game.Players.LocalPlayer.Character
        if char then char:BreakJoints() end
    end,
})

Settings:AddKeyPicker({
    Text = "Aimbot Key",
    Default = "E",
    Mode = "Hold",
    Description = "Hold to activate aimbot",
    Callback = function(active)
        print("Keybind active:", active)
    end,
})

local StatusLabel = Settings:AddLabel({
    Text = "Status: Ready",
    Description = "Current script state",
})

local StatusLink = StatusLabel:Link()

StatusLink:AddToggle({
    Text = "Auto Update",
    Default = true,
    Callback = function(v) end,
})

StatusLink:AddSlider({
    Text = "Refresh Rate",
    Default = 5,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Suffix = "s",
    Callback = function(v) end,
})

StatusLink:AddButton({
    Text = "Force Refresh",
    Callback = function()
        StatusLabel:SetText("Status: Refreshed")
    end,
})

local ESP = VisualsTab:AddLeftGroupbox({ Name = "ESP" })

ESP:AddToggle({
    Text = "Box ESP",
    Default = true,
    Description = "Draw boxes around players",
    Callback = function(v) end,
})

ESP:AddColorPicker({
    Text = "Box Color",
    Default = Color3.fromRGB(105, 160, 240),
    Description = "Color of the ESP boxes",
    Callback = function(color, transparency)
        print("Box color:", color)
    end,
})

ESP:AddToggle({
    Text = "Name ESP",
    Default = false,
    Description = "Show player names",
    Callback = function(v) end,
})

ESP:AddToggle({
    Text = "Health Bar",
    Default = true,
    Description = "Display health bars",
    Callback = function(v) end,
})

ESP:AddSlider({
    Text = "Max Distance",
    Default = 500,
    Min = 50,
    Max = 2000,
    Rounding = 0,
    Suffix = " studs",
    Description = "ESP render distance",
    Callback = function(v) end,
})

local Chams = VisualsTab:AddRightGroupbox({ Name = "Chams" })

Chams:AddToggle({
    Text = "Chams",
    Default = false,
    Description = "Highlight player models",
    Callback = function(v) end,
})

Chams:AddColorPicker({
    Text = "Fill Color",
    Default = Color3.fromRGB(255, 100, 100),
    Description = "Highlight fill color",
    Callback = function(c) end,
})

Chams:AddColorPicker({
    Text = "Outline Color",
    Default = Color3.fromRGB(255, 255, 255),
    Description = "Highlight outline color",
    Callback = function(c) end,
})

Chams:AddDropdown({
    Text = "Material",
    Values = {"ForceField", "Neon", "Glass", "SmoothPlastic"},
    Default = "ForceField",
    Description = "Chams material type",
    Callback = function(v) end,
})

local Utility = MiscTab:AddLeftGroupbox({ Name = "Utility" })

Utility:AddButton({
    Text = "Show Notification",
    Description = "Test the notification system",
    Callback = function()
        Library:Notify({
            Title = "Success",
            Content = "This is a notification from Lyra!",
            Duration = 4,
        })
    end,
})

Utility:AddButton({
    Text = "Show Dialog",
    Description = "Test the modal dialog",
    Callback = function()
        Library:CreateDialog({
            Title = "Confirm Action",
            Content = "Are you sure you want to continue?",
            Buttons = {
                {
                    Text = "Yes",
                    Callback = function()
                        Library:Notify({ Title = "Confirmed", Content = "You pressed Yes" })
                    end,
                },
                {
                    Text = "No",
                    Callback = function() end,
                },
            },
        })
    end,
})

Utility:AddButton({
    Text = "Loading Screen",
    Description = "Show a temporary loading overlay",
    Callback = function()
        local loading = Library:ShowLoading("Please wait...")
        task.delay(2.5, function()
            if loading then loading:Destroy() end
        end)
    end,
})

Utility:AddDropdown({
    Text = "Teams",
    SpecialType = "Team",
    Description = "Select a team",
    Callback = function(v)
        print("Team:", v)
    end,
})

local DepBox = Utility:AddDependencyBox()
DepBox:Setup(function()
    return AimbotToggle.Value
end)

DepBox:AddSlider({
    Text = "Aimbot Range",
    Default = 150,
    Min = 50,
    Max = 500,
    Description = "Only visible when aimbot is enabled",
    Callback = function(v) end,
})

DepBox:AddToggle({
    Text = "Team Check",
    Default = true,
    Description = "Ignore teammates",
    Callback = function(v) end,
})

local Config = MiscTab:AddRightGroupbox({ Name = "Config" })

Config:AddInput({
    Text = "Config Name",
    Default = "default",
    Description = "Name of the config file",
    Callback = function(t) end,
})

Config:AddButton({
    Text = "Save Config",
    Description = "Save current settings",
    Callback = function()
        Library:SaveConfig("default")
        Library:Notify({ Title = "Config", Content = "Saved successfully", Duration = 3 })
    end,
})

Config:AddButton({
    Text = "Load Config",
    Description = "Load saved settings",
    Callback = function()
        local data = Library:LoadConfig("default")
        if data then
            Library:Notify({ Title = "Config", Content = "Loaded successfully", Duration = 3 })
        else
            Library:Notify({ Title = "Config", Content = "No config found", Duration = 3 })
        end
    end,
})

Config:AddLabel({
    Text = "Lyra UI Library",
    Description = "v1.0 — full feature demo",
})

Config:AddKeyPicker({
    Text = "Menu Key",
    Default = "RightShift",
    Mode = "Toggle",
    Description = "Toggle UI visibility",
    Callback = function(v)
        Window:Toggle()
    end,
})
