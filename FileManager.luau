local FileManager = {}
FileManager.__index = FileManager

local function normalizePath(path)
    if type(path) ~= "string" or path == "" then
        return ""
    end
    path = path:gsub("\\", "/"):gsub("/+", "/")
    if #path > 1 and path:sub(-1) == "/" then
        path = path:sub(1, -2)
    end
    return path
end

local function getParentPath(path)
    path = normalizePath(path)
    return path:match("(.+)/[^/]+$")
end

local function safeCall(fn, ...)
    local results = { pcall(fn, ...) }
    return table.unpack(results)
end

local function warnFail(method, path, err)
    warn(string.format("[FileManager] %s failed for '%s': %s", method, tostring(path), tostring(err)))
end

function FileManager:MakeFolder(path)
    path = normalizePath(path)
    if path == "" then
        warn("[FileManager] MakeFolder: empty path")
        return false
    end
    if isfolder(path) then
        return true
    end
    local parent = getParentPath(path)
    if parent and parent ~= "" and not isfolder(parent) then
        if not self:MakeFolder(parent) then
            return false
        end
    end
    local ok, err = safeCall(makefolder, path)
    if not ok then
        warnFail("MakeFolder", path, err)
        return false
    end
    return isfolder(path)
end

function FileManager:WriteFile(path, content)
    path = normalizePath(path)
    if path == "" then
        warn("[FileManager] WriteFile: empty path")
        return false
    end
    if type(content) ~= "string" then
        content = tostring(content)
    end
    local parent = getParentPath(path)
    if parent and parent ~= "" then
        if not self:MakeFolder(parent) then
            return false
        end
    end
    local ok, err = safeCall(writefile, path, content)
    if not ok then
        warnFail("WriteFile", path, err)
        return false
    end
    return isfile(path)
end

function FileManager:AppendFile(path, content)
    path = normalizePath(path)
    if path == "" then
        warn("[FileManager] AppendFile: empty path")
        return false
    end
    if type(content) ~= "string" then
        content = tostring(content)
    end
    if type(appendfile) == "function" then
        local parent = getParentPath(path)
        if parent and parent ~= "" and not isfolder(parent) then
            if not self:MakeFolder(parent) then
                return false
            end
        end
        local ok, err = safeCall(appendfile, path, content)
        if not ok then
            warnFail("AppendFile", path, err)
            return false
        end
        return true
    end
    local existing = ""
    if isfile(path) then
        local ok, data = safeCall(readfile, path)
        if ok and type(data) == "string" then
            existing = data
        end
    end
    return self:WriteFile(path, existing .. content)
end

function FileManager:ReadFile(path)
    path = normalizePath(path)
    if path == "" then
        warn("[FileManager] ReadFile: empty path")
        return nil
    end
    if not isfile(path) then
        warnFail("ReadFile", path, "file does not exist")
        return nil
    end
    local ok, content = safeCall(readfile, path)
    if not ok then
        warnFail("ReadFile", path, content)
        return nil
    end
    return content
end

function FileManager:ListFiles(path)
    path = normalizePath(path)
    if path == "" or not isfolder(path) then
        warnFail("ListFiles", path, "folder does not exist")
        return {}
    end
    local ok, files = safeCall(listfiles, path)
    if not ok or type(files) ~= "table" then
        warnFail("ListFiles", path, files)
        return {}
    end
    return files
end

function FileManager:DeleteFile(path)
    path = normalizePath(path)
    if path == "" then
        warn("[FileManager] DeleteFile: empty path")
        return false
    end
    if not isfile(path) then
        warnFail("DeleteFile", path, "file does not exist")
        return false
    end
    local ok, err = safeCall(delfile, path)
    if not ok then
        warnFail("DeleteFile", path, err)
        return false
    end
    return not isfile(path)
end

function FileManager:DeleteFolder(path)
    path = normalizePath(path)
    if path == "" then
        warn("[FileManager] DeleteFolder: empty path")
        return false
    end
    if not isfolder(path) then
        warnFail("DeleteFolder", path, "folder does not exist")
        return false
    end
    local ok, err = safeCall(delfolder, path)
    if not ok then
        warnFail("DeleteFolder", path, err)
        return false
    end
    return not isfolder(path)
end

function FileManager:IsFile(path)
    path = normalizePath(path)
    return path ~= "" and isfile(path) == true
end

function FileManager:IsFolder(path)
    path = normalizePath(path)
    return path ~= "" and isfolder(path) == true
end

function FileManager:Exists(path)
    path = normalizePath(path)
    return path ~= "" and (isfile(path) or isfolder(path))
end

function FileManager:GetFileSize(path)
    path = normalizePath(path)
    if not isfile(path) then
        return nil
    end
    if type(getfilesize) == "function" then
        local ok, size = safeCall(getfilesize, path)
        if ok and type(size) == "number" then
            return size
        end
    end
    local content = self:ReadFile(path)
    if content then
        return #content
    end
    return nil
end

function FileManager:Rename(oldPath, newPath)
    oldPath = normalizePath(oldPath)
    newPath = normalizePath(newPath)
    if oldPath == "" or newPath == "" then
        warn("[FileManager] Rename: empty path")
        return false
    end
    if oldPath == newPath then
        return true
    end
    if not self:Exists(oldPath) then
        warnFail("Rename", oldPath, "source does not exist")
        return false
    end
    if self:Exists(newPath) then
        warnFail("Rename", newPath, "destination already exists")
        return false
    end
    if type(rename) == "function" then
        local ok = safeCall(rename, oldPath, newPath)
        if ok then
            return true
        end
    end
    if self:IsFile(oldPath) then
        local content = self:ReadFile(oldPath)
        if content == nil then
            return false
        end
        if not self:WriteFile(newPath, content) then
            return false
        end
        return self:DeleteFile(oldPath)
    end
    return false
end

return setmetatable({}, FileManager)
