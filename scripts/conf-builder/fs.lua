local mp = require("mp")
local platform = require("platform")

local hfs = {}

local SCRIPT_DIR = mp.get_script_directory()
local MPV_DIR = SCRIPT_DIR:sub(1, #SCRIPT_DIR - #("/scripts/conf-builder"))

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
	if platform:IsInRange(platform.OS_RANGES.NT) then
		path = path:gsub("\\", "/")
	end

	local file = io.open(path, hfs.IO_MODE.READ)

	if file then
		io.close(file)
		return true
	end

	return false
end

function hfs.OpenFile(path, mode, compute)
	if platform:IsInRange(platform.OS_RANGES.NT) then
		path = path:gsub("\\", "/")
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


-- probably unnecessary but it doesn't hurt having it!
local function EscapeShellArgument(arg)
	assert(type(arg) == "string", "must be a string")

	return arg:gsub("([%\\\"$`])", "\\%1")
end

local function HasItem(table, item)
	for _, v in pairs(table) do
		if v == item then
			return true
		end
	end

	return false
end

local cachedIndex = {}

function hfs.CacheFetch()
	cachedIndex = {}

	if platform:IsInRange(platform.OS_RANGES.NT) then
		local command = ([[%s/index.bat "%s"]]):format(SCRIPT_DIR:gsub(" ", "^ "), MPV_DIR)
		print(command)
		local cachedIndexHandle = io.popen(command)
		local current = "unknown"
		-- local did = 0
		-- local lines = 0
	
		for line in cachedIndexHandle:lines() do``
			if line:sub(1, 7) == ";BEGIN " then
				current = line:sub(8)
				-- did = did + 1
				-- print(current)
			else
				cachedIndex[current] = cachedIndex[current] or {}
				
				if not HasItem(cachedIndex[current], line) then
					table.insert(cachedIndex[current], line)
				end
			end
		end
	
		-- print("cached " .. did .. " directories and " .. lines - did .. " files for conf-builder.")
	
		cachedIndexHandle:close()
	end
end

function hfs.ListItemsInDirectory(path)
	local cachePath = path:sub(#MPV_DIR + 1):gsub("\\", "/")

	if cachedIndex[cachePath] then
		return cachedIndex[cachePath]
	else
		error("cache miss on " .. cachePath)
	end
	
	if platform:IsInRange(platform.OS_RANGES.NT) then
		local handle = io.popen(('dir "%s" /b'):format(EscapeShellArgument(path:gsub("\\", "/"))))
		local lines = {}
		for line in handle:lines() do
			table.insert(lines, line)
		end
		handle:close()
		return lines
	elseif platform:IsInRange(platform.OS_RANGES.UNIX) then
		local handle = io.popen(('ls -pa "%s" | grep -v /'):format(EscapeShellArgument(path)))
		local lines = {}
		for line in handle:lines() do
			table.insert(lines, line)
		end
		handle:close()
		return lines
	else
		error(("fs.ListItemsInDirectory(path: string) not implemented for OS %s"):format(platform.platform))
	end
end

return hfs