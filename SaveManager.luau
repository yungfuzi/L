local HttpService = game:GetService("HttpService")

local SaveManager = {
	Folder = "SaveManager",
}

local function SplitPath(Path)
	local Parts = {}
	for Part in string.gmatch(Path, "[^/\\]+") do
		table.insert(Parts, Part)
	end
	return Parts
end

function SaveManager:EnsureFolder(Path)
	if not Path or Path == "" then
		return true
	end

	local Parts = SplitPath(Path)
	local Current = self.Folder

	if not isfolder(Current) then
		makefolder(Current)
	end

	for _, Part in ipairs(Parts) do
		Current = Current .. "/" .. Part
		if not isfolder(Current) then
			makefolder(Current)
		end
	end

	return true
end

function SaveManager:BuildFolderTree()
	if not isfolder(self.Folder) then
		makefolder(self.Folder)
	end
end

function SaveManager:SetFolder(Folder)
	self.Folder = Folder or "SaveManager"
	self:BuildFolderTree()
end

function SaveManager:Set(File, PathOrData, Value)
	if type(File) ~= "string" then
		return false
	end

	if not File:find("%.json$") then
		File = File .. ".json"
	end

	local FullPath = self.Folder .. "/" .. File
	local FolderPart = FullPath:match("(.+)/[^/]+$")

	if FolderPart then
		self:EnsureFolder(FolderPart:gsub("^" .. self.Folder .. "/?", ""))
	else
		self:BuildFolderTree()
	end

	if type(PathOrData) == "table" and Value == nil then
		local Success, Encoded = pcall(HttpService.JSONEncode, HttpService, PathOrData)
		if not Success then
			return false
		end
		writefile(FullPath, Encoded)
		return true
	end

	local Data = {}
	if isfile(FullPath) then
		local Success, Decoded = pcall(function()
			return HttpService:JSONDecode(readfile(FullPath))
		end)
		if Success and type(Decoded) == "table" then
			Data = Decoded
		end
	end

	if type(PathOrData) == "string" then
		local Keys = string.split(PathOrData, ".")
		local Current = Data
		for i = 1, #Keys - 1 do
			local Key = Keys[i]
			if type(Current[Key]) ~= "table" then
				Current[Key] = {}
			end
			Current = Current[Key]
		end
		Current[Keys[#Keys]] = Value
	end

	local Success, Encoded = pcall(HttpService.JSONEncode, HttpService, Data)
	if not Success then
		return false
	end

	writefile(FullPath, Encoded)
	return true
end

function SaveManager:Get(File, Path, Default)
	if type(File) ~= "string" then
		return Default
	end

	if not File:find("%.json$") then
		File = File .. ".json"
	end

	local FullPath = self.Folder .. "/" .. File
	if not isfile(FullPath) then
		return Default
	end

	local Success, Data = pcall(function()
		return HttpService:JSONDecode(readfile(FullPath))
	end)

	if not Success or type(Data) ~= "table" then
		return Default
	end

	if not Path or Path == "" then
		return Data
	end

	local Keys = string.split(Path, ".")
	local Current = Data
	for _, Key in ipairs(Keys) do
		if type(Current) ~= "table" or Current[Key] == nil then
			return Default
		end
		Current = Current[Key]
	end

	return Current
end

function SaveManager:Delete(File)
	if type(File) ~= "string" then
		return false
	end

	if not File:find("%.json$") then
		File = File .. ".json"
	end

	local FullPath = self.Folder .. "/" .. File
	if isfile(FullPath) then
		delfile(FullPath)
		return true
	end
	return false
end

function SaveManager:CreateFolder(Name)
	if type(Name) ~= "string" or Name == "" then
		return false
	end
	return self:EnsureFolder(Name)
end

function SaveManager:DeleteFolder(Name)
	if type(Name) ~= "string" or Name == "" then
		return false
	end

	local Path = self.Folder .. "/" .. Name
	if isfolder(Path) then
		delfolder(Path)
		return true
	end
	return false
end

function SaveManager:List(Folder)
	Folder = Folder or ""
	local Target = Folder == "" and self.Folder or (self.Folder .. "/" .. Folder)

	if not isfolder(Target) then
		return {}, {}
	end

	local Files, Folders = {}, {}

	for _, Item in ipairs(listfiles(Target) or {}) do
		local Name = Item:match("([^/\\]+)$")
		if isfolder(Item) then
			table.insert(Folders, Name)
		elseif Name:find("%.json$") then
			table.insert(Files, Name:gsub("%.json$", ""))
		end
	end

	table.sort(Files)
	table.sort(Folders)
	return Files, Folders
end

function SaveManager:Exists(Path)
	if type(Path) ~= "string" then
		return false
	end

	local Full = self.Folder .. "/" .. Path
	return isfile(Full) or isfolder(Full)
end

return SaveManager
