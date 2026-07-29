local Helper = {}
Helper.__index = Helper

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local noclipConn: RBXScriptConnection? = nil
local noclipParts: {[BasePart]: boolean} = {}
local charConn: RBXScriptConnection? = nil

local activeTween: {
	conn: RBXScriptConnection,
	attachment: Attachment,
	velocity: LinearVelocity,
}? = nil
local tweenTarget: Vector3? = nil

--// Safe utilities

local function Call(fn: (...any) -> ...any, ...: any): (boolean, ...any)
	return pcall(fn, ...)
end

function Helper:Get(parent: Instance, name: string): Instance?
	if typeof(parent) ~= "Instance" or type(name) ~= "string" then
		return nil
	end
	return parent:FindFirstChild(name)
end

function Helper:Children(parent: Instance): {Instance}
	if typeof(parent) ~= "Instance" then
		return {}
	end
	return parent:GetChildren()
end

function Helper:Descendants(parent: Instance): {Instance}
	if typeof(parent) ~= "Instance" then
		return {}
	end
	return parent:GetDescendants()
end

function Helper:Find(parent: Instance, name: string, recursive: boolean?): Instance?
	if typeof(parent) ~= "Instance" or type(name) ~= "string" then
		return nil
	end
	return parent:FindFirstChild(name, recursive == true)
end

function Helper:FindClass(parent: Instance, className: string): Instance?
	if typeof(parent) ~= "Instance" or type(className) ~= "string" then
		return nil
	end
	return parent:FindFirstChildOfClass(className)
end

function Helper:FindWhichIsA(parent: Instance, className: string, recursive: boolean?): Instance?
	if typeof(parent) ~= "Instance" or type(className) ~= "string" then
		return nil
	end
	return parent:FindFirstChildWhichIsA(className, recursive == true)
end

function Helper:Wait(parent: Instance, name: string, timeout: number?): Instance?
	if typeof(parent) ~= "Instance" or type(name) ~= "string" then
		return nil
	end
	local ok, result = Call(parent.WaitForChild, parent, name, timeout)
	return ok and result or nil
end

--// Instance utilities

function Helper:Destroy(instance: Instance): boolean
	if typeof(instance) ~= "Instance" then
		return false
	end
	local ok = Call(instance.Destroy, instance)
	return ok
end

function Helper:Clone(instance: Instance): Instance?
	if typeof(instance) ~= "Instance" then
		return nil
	end
	local ok, result = Call(instance.Clone, instance)
	return ok and result or nil
end

function Helper:Alive(instance: Instance): boolean
	return typeof(instance) == "Instance" and instance.Parent ~= nil
end

function Helper:Path(instance: Instance): string
	if typeof(instance) ~= "Instance" then
		return ""
	end
	local parts = {}
	local current: Instance? = instance
	while current and current ~= game do
		table.insert(parts, 1, current.Name)
		current = current.Parent
	end
	return table.concat(parts, ".")
end

-- Player utilities

local function getRoot(): BasePart?
	local char = Player.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function getHumanoid(): Humanoid?
	local char = Player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

--// Noclip utilities

local function clearNoclip()
	if noclipConn then
		noclipConn:Disconnect()
		noclipConn = nil
	end
	for part, wasCollide in pairs(noclipParts) do
		if part.Parent then
			part.CanCollide = wasCollide
		end
	end
	table.clear(noclipParts)
end

local function applyNoclip(character: Model)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			if noclipParts[part] == nil then
				noclipParts[part] = part.CanCollide
			end
			part.CanCollide = false
		end
	end
end

function Helper:NoclipOn()
	clearNoclip()
	local character = Player.Character
	if character then
		applyNoclip(character)
	end
	noclipConn = RunService.Stepped:Connect(function()
		local char = Player.Character
		if not char then
			return
		end
		applyNoclip(char)
	end)
	if charConn then
		charConn:Disconnect()
	end
	charConn = Player.CharacterAdded:Connect(function(char)
		table.clear(noclipParts)
		applyNoclip(char)
	end)
end

function Helper:NoclipOff()
	clearNoclip()
	if charConn then
		charConn:Disconnect()
		charConn = nil
	end
end

function Helper:Noclip(enabled: boolean)
	if enabled then
		self:NoclipOn()
	else
		self:NoclipOff()
	end
end

--// Tween utilities

function Helper:Stop()
	if activeTween then
		activeTween.conn:Disconnect()
		if activeTween.velocity.Parent then
			activeTween.velocity:Destroy()
		end
		if activeTween.attachment.Parent then
			activeTween.attachment:Destroy()
		end
		activeTween = nil
	end
	tweenTarget = nil
	self:NoclipOff()
end

function Helper:Tween(target: CFrame | Vector3, options: {Speed: number?, TPDistance: number?, Angles: CFrame?}?)
	local root = getRoot()
	if not root then
		return
	end

	options = options or {}
	local speed = options.Speed or 100
	local tpDistance = options.TPDistance or 5
	local angles = options.Angles

	local targetPos: Vector3
	local targetCF: CFrame
	if typeof(target) == "CFrame" then
		targetPos = target.Position
		targetCF = target
	elseif typeof(target) == "Vector3" then
		targetPos = target
		targetCF = CFrame.new(target)
	else
		return
	end

	if activeTween and tweenTarget and (tweenTarget - targetPos).Magnitude < tpDistance then
		return
	end

	self:Stop()
	self:NoclipOn()
	tweenTarget = targetPos

	local attachment = Instance.new("Attachment")
	attachment.Name = "HelperTweenAttachment"
	attachment.Parent = root

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "HelperTweenVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = 1e9
	linearVelocity.VectorVelocity = Vector3.zero
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = root

	local humanoid = getHumanoid()
	local diedConn: RBXScriptConnection? = nil
	if humanoid then
		diedConn = humanoid.Died:Connect(function()
			self:Stop()
		end)
	end

	local conn = RunService.Heartbeat:Connect(function()
		if not root.Parent then
			self:Stop()
			if diedConn then
				diedConn:Disconnect()
			end
			return
		end

		local direction = targetPos - root.Position
		local distance = direction.Magnitude

		if distance <= tpDistance then
			linearVelocity.VectorVelocity = Vector3.zero
			root.AssemblyLinearVelocity = Vector3.zero
			if angles then
				root.CFrame = CFrame.new(targetPos) * angles
			else
				root.CFrame = targetCF
			end
			self:Stop()
			if diedConn then
				diedConn:Disconnect()
			end
			return
		end

		linearVelocity.VectorVelocity = direction.Unit * speed

		if angles then
			root.CFrame = CFrame.new(root.Position) * angles
		end
	end)

	activeTween = {
		conn = conn,
		attachment = attachment,
		velocity = linearVelocity,
	}
end

return setmetatable({}, Helper)
