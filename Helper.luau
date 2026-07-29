local Helper = {}
Helper.__index = Helper

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local NoclipConnection = nil
local NoclipParts = {}
local ActiveTween = nil
local currentTweenTarget = nil

local function safeCall(fn, ...)
    local results = { pcall(fn, ...) }
    return table.unpack(results)
end

function Helper:SafeGet(parent, name)
    if typeof(parent) ~= "Instance" or type(name) ~= "string" then
        return nil
    end
    local ok, result = safeCall(parent.FindFirstChild, parent, name)
    if ok then
        return result
    end
    return nil
end

function Helper:SafeGetChildren(parent)
    if typeof(parent) ~= "Instance" then
        return {}
    end
    local ok, result = safeCall(parent.GetChildren, parent)
    if ok and type(result) == "table" then
        return result
    end
    return {}
end

function Helper:SafeGetDescendants(parent)
    if typeof(parent) ~= "Instance" then
        return {}
    end
    local ok, result = safeCall(parent.GetDescendants, parent)
    if ok and type(result) == "table" then
        return result
    end
    return {}
end

function Helper:SafeFindFirstChild(parent, name, recursive)
    if typeof(parent) ~= "Instance" or type(name) ~= "string" then
        return nil
    end
    local ok, result = safeCall(parent.FindFirstChild, parent, name, recursive == true)
    if ok then
        return result
    end
    return nil
end

function Helper:SafeFindFirstChildOfClass(parent, className)
    if typeof(parent) ~= "Instance" or type(className) ~= "string" then
        return nil
    end
    local ok, result = safeCall(parent.FindFirstChildOfClass, parent, className)
    if ok then
        return result
    end
    return nil
end

function Helper:SafeFindFirstChildWhichIsA(parent, className, recursive)
    if typeof(parent) ~= "Instance" or type(className) ~= "string" then
        return nil
    end
    local ok, result = safeCall(parent.FindFirstChildWhichIsA, parent, className, recursive == true)
    if ok then
        return result
    end
    return nil
end

function Helper:SafeWaitForChild(parent, name, timeout)
    if typeof(parent) ~= "Instance" or type(name) ~= "string" then
        return nil
    end
    local ok, result
    if timeout ~= nil then
        ok, result = safeCall(parent.WaitForChild, parent, name, timeout)
    else
        ok, result = safeCall(parent.WaitForChild, parent, name)
    end
    if ok then
        return result
    end
    return nil
end

function Helper:SafeDestroy(instance)
    if typeof(instance) ~= "Instance" then
        return false
    end
    local ok = safeCall(instance.Destroy, instance)
    return ok == true
end

function Helper:SafeClone(instance)
    if typeof(instance) ~= "Instance" then
        return nil
    end
    local ok, result = safeCall(instance.Clone, instance)
    if ok then
        return result
    end
    return nil
end

function Helper:IsAlive(instance)
    return typeof(instance) == "Instance" and instance.Parent ~= nil
end

function Helper:GetPath(instance)
    if typeof(instance) ~= "Instance" then
        return ""
    end
    local parts = {}
    local current = instance
    while current and current ~= game do
        table.insert(parts, 1, current.Name)
        current = current.Parent
    end
    return table.concat(parts, ".")
end

function Helper:SetNoclip(enabled)
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
    if not enabled then
        for part, wasCollide in pairs(NoclipParts) do
            if part.Parent then
                part.CanCollide = wasCollide
            end
        end
        table.clear(NoclipParts)
        return
    end
    NoclipConnection = RunService.Stepped:Connect(function()
        local character = Player.Character
        if not character then
            return
        end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if NoclipParts[part] == nil then
                    NoclipParts[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    end)
end

function Helper:StopTween()
    if ActiveTween then
        if ActiveTween.conn then
            ActiveTween.conn:Disconnect()
        end
        if ActiveTween.BV then
            ActiveTween.BV:Destroy()
        end
        ActiveTween = nil
    end
    currentTweenTarget = nil
    self:SetNoclip(false)
end

function Helper:Tween(Target, Options)
    local Character = Player.Character
    local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then
        return
    end
    Options = type(Options) == "table" and Options or {}
    local Speed = Options.Speed or 100
    local TPDistance = Options.TPDistance or 5
    local Angles = Options.Angles
    local TargetPos
    local TargetCF
    if typeof(Target) == "CFrame" then
        TargetPos = Target.Position
        TargetCF = Target
    elseif typeof(Target) == "Vector3" then
        TargetPos = Target
        TargetCF = CFrame.new(Target)
    else
        return
    end
    if ActiveTween and currentTweenTarget and (currentTweenTarget - TargetPos).Magnitude < TPDistance then
        return
    end
    self:StopTween()
    self:SetNoclip(true)
    currentTweenTarget = TargetPos
    local BV = Instance.new("BodyVelocity")
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    BV.P = 1250
    BV.Velocity = Vector3.new(0, 0, 0)
    BV.Parent = HumanoidRootPart
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not HumanoidRootPart or not HumanoidRootPart.Parent then
            self:StopTween()
            return
        end
        local Direction = TargetPos - HumanoidRootPart.Position
        local Distance = Direction.Magnitude
        if Distance <= TPDistance then
            BV.Velocity = Vector3.zero
            HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
            if Angles then
                HumanoidRootPart.CFrame = CFrame.new(TargetPos) * Angles
            elseif TargetCF then
                HumanoidRootPart.CFrame = TargetCF
            else
                HumanoidRootPart.CFrame = CFrame.new(TargetPos)
            end
            self:StopTween()
            return
        end
        BV.Velocity = Direction.Unit * Speed
        if Angles then
            HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * Angles
        end
    end)
    ActiveTween = { BV = BV, conn = conn }
end

return setmetatable({}, Helper)
