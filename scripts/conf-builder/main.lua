local mp = require("mp")
local fs = require("fs")
local platform = require("platform")

local CONFIG_HEADER_01 = ([[
# this file is being managed with conf-builder]])

local CONFIG_HEADER_02 = ([[
 version 0.0.0 to improve git source control, DO NOT edit it!
# please edit the files in the conf folder instead of directly modifying this as it WILL be replaced on startup
# files will get applied in the order specified before the name in the number, you cannot have more than one of the same number
# use the "user" sub folder not "builtin", if you need to overwrite a default then set it on the user side]])

local CONFIG_HEADER_ALL = CONFIG_HEADER_01 .. CONFIG_HEADER_02

local MESSAGES = {
BACKED_UP = ([[
you've made changes to %s before it was managed by conf-builder,
the file has been backed up, restart mpv.]]);
SORT_OUT_OF_ORDER = ([[
your sort order is out of order.]]);
SORT_DUPLICATION = ([[
you have two files with the same sort number, please set an actual order to prevent unpredictable file ordering.
suspect: %s]]);
SORT_BAD_FORMAT = ([[
you've omitted the sort order number from a config file (%s),
please add x- before the file name and replace x with the desired order
you cannot have two files with the same number, a higher number means it is applied last
user config files will apply after built in ones]]);
RESTART_NEEDED = ([[
config file(s) has been updated and restarting mpv is required.
changed files:
%s]]);
}

local MESSAGE_TIME = 5
local MESSAGE_TIME_LONG = 100

local SCRIPT_DIR = mp.get_script_directory()
local MPV_DIR = SCRIPT_DIR:sub(1, #SCRIPT_DIR - #("/scripts/conf-builder"))
local OUT_MPV = ("%s/mpv.conf"):format(MPV_DIR)
local OUT_INPUT = ("%s/input.conf"):format(MPV_DIR)
local OUT_SCRIPTS = ("%s/script-opts/"):format(MPV_DIR)
local IN_MPV = ("%s/conf/mpv/"):format(MPV_DIR)
local IN_INPUT = ("%s/conf/input/"):format(MPV_DIR)
local IN_SCRIPTS = ("%s/conf/script-opts/"):format(MPV_DIR)

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

local function BuildFullConfig(path)
	local output = CONFIG_HEADER_ALL

	local function CombineSource(source)
		local list = {}
		local sourcePath = path .. source

		ShowMessageImmediate("Building Config" .. "\n" .. sourcePath:sub(#MPV_DIR + 1) .. "\n" .. source)
		for _, path in pairs(fs.ListItemsInDirectory(sourcePath)) do
			if path:match(".conf") then
				local index = path:match("([0-9]+)")
				local indexNumber = tonumber(index)
				if indexNumber then
					if list[indexNumber + 1] then
						QueueMessage(MESSAGES.SORT_DUPLICATION:format(path))
					else
						if indexNumber > 0 and not list[indexNumber] then
							QueueMessage(MESSAGES.SORT_OUT_OF_ORDER)
						end
					end
	
					-- if this ever becomes async this will need to change
					fs.OpenFile(sourcePath .. "/" .. path, fs.IO_MODE.READ, function(file)
						list[indexNumber + 1] = "# from: " .. path .. ":\n\n" ..  file:read("*all")
					end)
				else
					QueueMessage(MESSAGES.SORT_BAD_FORMAT)
				end
			end
		end

		return table.concat(list, "\n\n")
	end

	output = output .. "\n\n#builtin\n\n" .. CombineSource("builtin/")
	output = output .. "\n\n#user\n\n" .. CombineSource("user/")

	return output
end

local function Build()
	fs.CacheFetch()
	ShowMessageImmediate("Building Config")

	local passed = true
	for _, path in pairs(fs.ListItemsInDirectory(OUT_SCRIPTS)) do
		if path:match(".conf") then
			if not HeaderCheck(OUT_SCRIPTS .. path) then
				passed = false
				break
			end
		end
	end

	local restartNeeded

	if passed then
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
			DoFile(OUT_SCRIPTS .. script .. ".conf", IN_SCRIPTS .. script .. "/")
		end
	end

	if restartNeeded then
		if platform:IsInRange(platform.OS_RANGES.NT) then
			ShowMessageImmediate("Restarting")
			local path = mp.get_property("path")
			local timePosition = mp.get_property("time-pos")

			if path then
				if timePosition then
					for line in io.popen(([[powershell.exe -file %s/restart.ps1 "%s" "%s"]]):format(SCRIPT_DIR, path,  tonumber(timePosition) + 0.5)):lines() do
						print(line)
					end
				else
					io.popen('start mpv.exe /c "' .. path .. '"')
				end
			else
				io.popen("start mpv.exe")
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