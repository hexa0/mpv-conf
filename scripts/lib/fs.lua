local hfs = {}

local Platform = require("platform")
local EscapeShellArgument = require("escapeShellArgument")

local DEBUG_MODE = false
local SCRIPT_DIR = debug.getinfo(1, "S").source:sub(2, -8)
local MPV_DIR = SCRIPT_DIR:sub(1, #SCRIPT_DIR - #("/scripts/lib"))
local CONFIG_DIR = MPV_DIR:sub(1, #MPV_DIR - #("/mpv"))

if Platform:IsInRange(Platform.OS_RANGES.NT) then
	MPV_DIR = "%appdata%\\mpv"
	SCRIPT_DIR = MPV_DIR .. "\\scripts\\lib"
end

hfs.IO_MODE = {
	READ = "r";
	WRITE = "w";
	OVERWRITE = "w+";
	READWRITE = "r+";
	READOVERWRITE = "rw+";
	APPEND = "a";
	READAPPEND = "a+";
}

function hfs.FileExists(path)
	if Platform:IsInRange(Platform.OS_RANGES.NT) then
		path = path:gsub("\\", "/")
		path = path:gsub("%%appdata%%", CONFIG_DIR .. "\\")
	end

	local file = io.open(path, hfs.IO_MODE.READ)

	if file then
		io.close(file)
		return true
	end

	return false
end

function hfs.OpenFile(path, mode, compute)
	if Platform:IsInRange(Platform.OS_RANGES.NT) then
		path = path:gsub("\\", "/")
		path = path:gsub("%%appdata%%", CONFIG_DIR .. "\\")
	end
	
	local file, ioError, ioErrorID = io.open(path, mode)

	if file then
		local success, userError = pcall(function()
			compute(file)
		end)

		io.close(file)

		if not success then
			local errorMessage = ("IO User Error:\n%s"):format(userError)

			error(errorMessage)
		end
	else
		if not ioError or not ioErrorID then
			ioErrorID = ioErrorID or -1
			ioError = ioError or "File doesn't exist."
		end

		local errorMessage = ("IO Error %s: %s"):format(ioErrorID, ioError)

		error(errorMessage)
	end
end

local function HasItem(table, item)
	for _, v in pairs(table) do
		if v == item then
			return true
		end
	end

	return false
end

local function RecursivePrintOut(t, i)
	for i2, v in pairs(t) do
		if type(v) == "table" then
			print(string.rep("    ", i), ('"%s":'):format(i2))
			RecursivePrintOut(v, i + 1)
		else
			print(string.rep("    ", i), ('"%s": "%s"'):format(i2, v))
		end
	end
end

local cachedIndex = {}

function hfs.CacheFetch()
	cachedIndex = {}

	if Platform:IsInRange(Platform.OS_RANGES.NT) then
		local command

		command = ([[powershell -NoProfile -file "%s\index.ps1" "%s"]]):format(SCRIPT_DIR, MPV_DIR)

		if DEBUG_MODE then
			print("running", command, "to cache directories")
		end
		local cachedIndexHandle = io.popen(command)
		local current = "unknown"
		local did = 0
		local lines = 0

		if DEBUG_MODE then
			print("output:")
		end
	
		for line in cachedIndexHandle:lines() do
			if DEBUG_MODE then
				print(line)
			end
			if line:sub(1, 7) == ";BEGIN " then
				if not cachedIndex[current] then
					cachedIndex[current] = {}
				end
				
				current = line:sub(8)
				did = did + 1
				-- print(current)
			else
				cachedIndex[current] = cachedIndex[current] or {}
				
				if not HasItem(cachedIndex[current], line) then
					lines = lines + 1
					table.insert(cachedIndex[current], line)
				end
			end
		end

		if DEBUG_MODE then
			print("end")
		end
	
		if DEBUG_MODE then
			print("cached " .. did .. " directories and " .. lines - did .. " files for conf-builder.")
		end
	
		cachedIndexHandle:close()
	end

	if DEBUG_MODE then
		print("cachedIndex:")
		RecursivePrintOut(cachedIndex, 1)
	end
end

function hfs.ListItemsInDirectory(path)
	local cachePath = path:sub(#MPV_DIR + 1):gsub("\\", "/")

	if cachedIndex[cachePath] then
		return cachedIndex[cachePath]
	else
		if Platform:IsInRange(Platform.OS_RANGES.NT) then
			error("cache miss on " .. cachePath)
		end
	end
	
	if Platform:IsInRange(Platform.OS_RANGES.NT) then
		local handle = io.popen(('dir "%s" /b'):format(EscapeShellArgument(path:gsub("\\", "/"))))
		local lines = {}
		for line in handle:lines() do
			table.insert(lines, line)
		end
		handle:close()
		return lines
	elseif Platform:IsInRange(Platform.OS_RANGES.UNIX) then
		-- on linux this isn't an issue since it doesn't load a whole terminal GUI like it does on windows
		-- so we can safely skip caching it there!
		local handle = io.popen(('ls -pa "%s" | grep -v \\\\./'):format(EscapeShellArgument(path)))
		local lines = {}
		for line in handle:lines() do
			if line:sub(#line) == "/" then
				line = line:sub(1, #line - 1)
			end

			table.insert(lines, line)
		end
		handle:close()
		return lines
	else
		error(("fs.ListItemsInDirectory(path: string) not implemented for OS %s"):format(Platform:GetInternalName(Platform.platform)))
	end
end

return hfs