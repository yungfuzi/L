local Helper = {}
Helper.__index = Helper

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

return setmetatable({}, Helper)
