local HttpService = game:GetService("HttpService")

local SaveManager = {
    Folder = "SaveManager",
}

function SaveManager:BuildFolderTree()
    if not isfolder(self.Folder) then
        makefolder(self.Folder)
    end
end

function SaveManager:Set(file, pathOrData, value)
    if type(file) ~= "string" then
        return false
    end

    if not file:find("%.json$") then
        file = file .. ".json"
    end

    self:BuildFolderTree()
    local fullPath = self.Folder .. "/" .. file

    if type(pathOrData) == "table" and value == nil then
        local success, encoded = pcall(HttpService.JSONEncode, HttpService, pathOrData)
        if not success then
            return false
        end
        writefile(fullPath, encoded)
        return true
    end

    local data = {}
    if isfile(fullPath) then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(fullPath))
        end)
        if success and type(decoded) == "table" then
            data = decoded
        end
    end

    if type(pathOrData) == "string" then
        local keys = string.split(pathOrData, ".")
        local current = data
        for i = 1, #keys - 1 do
            local k = keys[i]
            if type(current[k]) ~= "table" then
                current[k] = {}
            end
            current = current[k]
        end
        current[keys[#keys]] = value
    end

    local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if not success then
        return false
    end
    writefile(fullPath, encoded)
    return true
end

function SaveManager:Get(file, path, default)
    if type(file) ~= "string" then
        return default
    end

    if not file:find("%.json$") then
        file = file .. ".json"
    end

    local fullPath = self.Folder .. "/" .. file
    if not isfile(fullPath) then
        return default
    end

    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(fullPath))
    end)

    if not success or type(data) ~= "table" then
        return default
    end

    if not path or path == "" then
        return data
    end

    local keys = string.split(path, ".")
    local current = data
    for _, k in ipairs(keys) do
        if type(current) ~= "table" or current[k] == nil then
            return default
        end
        current = current[k]
    end

    return current
end

function SaveManager:Delete(file)
    if type(file) ~= "string" then
        return false
    end

    if not file:find("%.json$") then
        file = file .. ".json"
    end

    local fullPath = self.Folder .. "/" .. file
    if isfile(fullPath) then
        delfile(fullPath)
        return true
    end
    return false
end

function SaveManager:List()
    self:BuildFolderTree()
    local files = {}
    for _, file in ipairs(listfiles(self.Folder) or {}) do
        local name = file:match("([^/\\]+)%.json$")
        if name then
            table.insert(files, name)
        end
    end
    table.sort(files)
    return files
end

function SaveManager:SetFolder(folder)
    self.Folder = folder or "SaveManager"
    self:BuildFolderTree()
end

return SaveManager
