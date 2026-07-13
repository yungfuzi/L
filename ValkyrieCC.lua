GetService = function(service)
		return cloneref and cloneref(game:GetService(service)) or game:GetService(service)
end

--// Services / Variables
local TweenService = GetService("TweenService")
local RunService = GetService("RunService")
local HttpService = GetService("HttpService")
local UserInputService = GetService("UserInputService")
local Players = GetService("Players")

local isStudio = RunService:IsStudio()
local LocalPlayer = Players.LocalPlayer

local Library = {
    Theme = {},
    MenuKeybind = tostring(Enum.KeyCode.RightControl),
    Flags = {},
    Tween = {},
    FadeSpeed = 0.4,
  
    Folders = {},
  
    Images = {},
    Icons = {},

    ActiveTab = nil,
    Pages = {},
    Sections = {},
  
    Connections = {},
    
    Font = nil,
    SubFont = nil

    Addons = {
      ["ColorPicker"] = {},
      ["Link"] = {},
      ["Keybind"] = {},
    },
}

--// Functions
local function GetGui()
  if isStudio then
    return LocalPlayer.PlayerGui
  else
    return (gethui and gethui()) or GetService("CoreGui")
  end
end


--// Window
local function Library:CreateWindow(Config)
   --// Tab Section/Group


   --// Tabs

   --// Pages

    --// Sections

    --// Label

    --// Paragraph
  
    --// Toggle
    function Section:AddToggle(Cfg, Flags)
         Library:AddToggle(Cfg, Section)
    end

    --// Button

    --// Dropdown
end

function Library:AddToggle(Cfg, Parent)
end

return Library

    
