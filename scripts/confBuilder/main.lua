package.path = mp.command_native({"expand-path", "~~/scripts/lib/?.lua;"})..package.path

local mp = require("mp")
local fs = require("fs")
local Platform = require("platform")
local CommentDataCodec = require("commentDataCodec")

local CONFIG_HEADER_01 = ([[
# this file is being managed with conf-builder]])

local CONFIG_HEADER_02 = ([[
 version 0.1.0 to improve git source control, DO NOT edit it!
# please edit the files in the conf folder instead of directly modifying this as it WILL be replaced on startup
# files will get applied in the order specified before the name in the number, you cannot have more than one of the same number
# use the "user" sub folder not "builtin", if you need to overwrite a default then set it on the user side]])

local CONFIG_HEADER_ALL = CONFIG_HEADER_01 .. CONFIG_HEADER_02

local MESSAGES = {
BACKED_UP = ([[
you've made changes to %s before it was managed by conf-builder,
the file has been backed up, restart mpv.]]);
RESTART_NEEDED = ([[
config file(s) has been updated and restarting mpv is required.
changed files:
%s]]);
}

local MESSAGE_TIME = 5
local MESSAGE_TIME_LONG = 100

local SCRIPT_DIR = mp.get_script_directory()
local MPV_DIR = SCRIPT_DIR:sub(1, #SCRIPT_DIR - #("/scripts/confBuilder"))

if Platform:IsInRange(Platform.OS_RANGES.NT) then
	MPV_DIR = "%appdata%\\mpv"
	SCRIPT_DIR = MPV_DIR .. "\\scripts\\confBuilder"
end

local OUT_MPV = ("%s/mpv.conf"):format(MPV_DIR)
local OUT_INPUT = ("%s/input.conf"):format(MPV_DIR)
local OUT_SCRIPTS = ("%s/script-opts"):format(MPV_DIR)
local IN_MPV = ("%s/conf/mpv"):format(MPV_DIR)
local IN_INPUT = ("%s/conf/input"):format(MPV_DIR)
local IN_SCRIPTS = ("%s/conf/script-opts"):format(MPV_DIR)

local messageQueue = {}

local function ShowMessageImmediate(text)
	mp.osd_message(text, MESSAGE_TIME)
end

local _messagesQueued = false
local function _DisplayQueuedMessages()
	if #messageQueue == 0 then
		_messagesQueued = false
	else
		_messagesQueued = true
		ShowMessageImmediate(messageQueue[1])
		table.remove(messageQueue, 1)
		mp.add_timeout(MESSAGE_TIME, _DisplayQueuedMessages)
	end
end

local function QueueMessage(message)
	table.insert(messageQueue, message)
	if not _messagesQueued then
		_DisplayQueuedMessages()
	end
end

local function HeaderCheck(path)
	local passed = true

	if fs.FileExists(path) then
		fs.OpenFile(path, fs.IO_MODE.READ, function(file)
			local originalContent = file:read("*all")
			if originalContent:sub(1, #CONFIG_HEADER_01) ~= CONFIG_HEADER_01 then
				passed = false

				QueueMessage(MESSAGES.BACKED_UP:format(path:gsub(MPV_DIR .. "/", "")))

				fs.OpenFile(path .. ".bak", fs.IO_MODE.OVERWRITE, function(file)
					file:write(originalContent)
				end)

				fs.OpenFile(path, fs.IO_MODE.OVERWRITE, function(file)
					file:write(CONFIG_HEADER_ALL .. "\n#temp...")
				end)
			end
		end)
	else
		passed = false
	end

	return passed
end

local function PrintOutTableContent(t, ind)
	if not ind then
		ind = 1
		print("printing the contents of " .. tostring(t))
	end

	for i, v in pairs(t) do
		print(("%s[%s]: %s"):format(string.rep("    ", ind), tostring(i), tostring(v)))

		if type(v) == "table" then
			PrintOutTableContent(v, ind + 1)
		end
	end
end

local function SplitString(sourceString, delimiter)
    delimiter = delimiter or "%s"
    local result = {}
    local i = 1
    for str in string.gmatch(sourceString, "([^"..delimiter.."]+)") do
        result[i] = str
        i = i + 1
    end
    return result
end

local function BuildFullConfig(path)
	local output = CONFIG_HEADER_ALL

	local function CombineSource(source)
		local list = {}
		local sourcePath = path .. "/" .. source

		ShowMessageImmediate("Building Config" .. "\n" .. sourcePath:sub(#MPV_DIR + 1) .. "\n" .. source)
		for _, path in pairs(fs.ListItemsInDirectory(sourcePath)) do
			if path:match(".conf") then
				local dashSplish = SplitString(path, "-")
				
				local index = ""
				
				if dashSplish[1]:match("([0-9]+)") == dashSplish[1] then
					index = dashSplish[1]
				end
				
				--[[ if this ever becomes asynchronous this will need to change
				as we're depending on this being synchronous ]]
				fs.OpenFile(sourcePath .. "/" .. path, fs.IO_MODE.READ, function(file)
					local content = "# from: " .. path .. ":\n\n" .. file:read("*all")
					local canBeActive = true

					local metadata = CommentDataCodec.Parse(content, "metadata")

					if metadata.print == true then -- yes we leaving in debug code bc why not
						PrintOutTableContent(metadata)
					end
					
					if metadata.filter and type(metadata.filter) == "table" then
						local allowedPlatforms = SplitString(metadata.filter.platform, ",")
						local allowedDisplayServer = metadata.filter.display -- linux only

						local platformMatches = false

						for _, allowedPlatform in pairs(allowedPlatforms) do
							local matches = false
							
							if allowedPlatform == "linux" then
								if allowedDisplayServer then
									if allowedDisplayServer == "wayland" then
										matches = Platform.platform == Platform.PLATFORMS.LINUX_WAYLAND
									elseif allowedDisplayServer == "x11" then
										matches = Platform.platform == Platform.PLATFORMS.LINUX_X11
									else
										warn("unknown filter display server: " .. allowedDisplayServer)
									end
								else
									matches = Platform:IsInRange(Platform.OS_RANGES.LINUX)
								end
							elseif allowedPlatform == "unix" then
								matches = Platform:IsInRange(Platform.OS_RANGES.UNIX)
							elseif allowedPlatform == "mac" then
								matches = Platform.platform == Platform.PLATFORMS.MAC
							elseif allowedPlatform == "nt" then
								matches = Platform:IsInRange(Platform.OS_RANGES.NT)
							else
								warn("unknown filter platform: " .. allowedPlatform)
							end

							if matches then
								platformMatches = true
								break
							end
						end

						if not platformMatches then
							canBeActive = false
						end
					end

					if canBeActive then
						table.insert(list, {
							index = tonumber(index) or 0;
							content = content;
						})
					end
				end)
			end
		end

		table.sort(list, function(a, b)
			return a.index < b.index
		end)

		local concattableList = {}

		for _, item in pairs(list) do
			table.insert(concattableList, item.content)
		end

		return table.concat(concattableList, "\n\n")
	end

	output = output .. "\n\n#builtin\n\n" .. CombineSource("builtin")
	output = output .. "\n\n#user\n\n" .. CombineSource("user")

	return output
end

local function Build()
	fs.CacheFetch()
	ShowMessageImmediate("Building Config")

	for _, path in pairs(fs.ListItemsInDirectory(OUT_SCRIPTS)) do
		if path:match(".conf") and not path:match(".bak") then
			if not HeaderCheck(OUT_SCRIPTS .. "/" .. path) then
				break
			end
		end
	end

	local restartNeeded
	
	local function DoFile(path, buildPath)
		ShowMessageImmediate("Building Config" .. "\n" .. path:sub(#MPV_DIR + 1) .. "\n" .. buildPath:sub(#MPV_DIR + 1))
		local built = BuildFullConfig(buildPath)

		local exists = fs.FileExists(path)

		if exists then
			fs.OpenFile(path, fs.IO_MODE.READ, function(file)
				local content = file:read("*all")

				if content ~= built then
					restartNeeded = (restartNeeded or "") .. path:sub(#MPV_DIR + 1) .. "\n"
				end
			end)
		else
			restartNeeded = (restartNeeded or "") .. path:sub(#MPV_DIR + 1) .. "\n"
		end

		fs.OpenFile(path, fs.IO_MODE.OVERWRITE, function(file)
			file:write(built)
		end)
	end
	DoFile(OUT_MPV, IN_MPV)
	DoFile(OUT_INPUT, IN_INPUT)
	for _, script in pairs(fs.ListItemsInDirectory(IN_SCRIPTS)) do
		DoFile(OUT_SCRIPTS .. "/" .. script .. ".conf", IN_SCRIPTS .. "/" .. script)
	end

	if restartNeeded then
		if Platform:IsInRange(Platform.OS_RANGES.NT) then
			ShowMessageImmediate("Restarting")
			local path = mp.get_property("path")
			local timePosition = mp.get_property("time-pos")

			if path then
				if timePosition then
					for line in io.popen(([[powershell -NoProfile -file "%s/restart.ps1" "%s" "%s"]]):format(SCRIPT_DIR, path,  tonumber(timePosition) + 0.5)):lines() do
						print(line)
					end
				else
					io.popen('start mpv.exe /c "' .. path .. '"')
				end
			else
				io.popen("start mpv.exe")
			end

			os.exit()
		elseif Platform:IsInRange(Platform.OS_RANGES.UNIX) then
			ShowMessageImmediate("Restarting")
			local path = mp.get_property("path")
			local timePosition = mp.get_property("time-pos")

			if timePosition then
				io.popen(([[nohup mpv "%s" --start=%s]]):format(path, timePosition))
			else
				io.popen(([[nohup mpv "%s"]]):format(path))
			end

			os.exit()
		else
			MESSAGE_TIME = MESSAGE_TIME_LONG
			QueueMessage(MESSAGES.RESTART_NEEDED:format(restartNeeded:sub(1, #restartNeeded - 1)))
		end
	else
		ShowMessageImmediate("Done!\nno changes.")
	end
end

mp.add_timeout(0.2, function()
	if not HeaderCheck(OUT_MPV) or not HeaderCheck(OUT_INPUT) then
		Build()
	end
end)

mp.add_key_binding("Shift+HOME", "build-conf", Build)
mp.add_key_binding("KP_HOME", "build-conf", Build)