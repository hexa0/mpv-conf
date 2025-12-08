-- https://github.com/nimatrueway/mpv-locatefile-lua-script

-- DEBUGGING
--
-- Debug messages will be printed to stdout with mpv command line option
-- `--msg-level='locatefile=debug'`

package.path = mp.command_native({"expand-path", "~~/scripts/lib/?.lua;"})..package.path

local Platform = require("platform")
local msg = require('mp.msg')
local mputils = require('mp.utils')

-- for linux
url_browser_linux_cmd = "xdg-open \"$url\""
file_browser_linux_cmd = "dbus-send --print-reply --dest=org.freedesktop.FileManager1 /org/freedesktop/FileManager1 org.freedesktop.FileManager1.ShowItems array:string:\"file:$path\" string:\"\""
-- for macos
url_browser_macos_cmd = "open \"$url\""
file_browser_macos_cmd = "osascript -e 'tell application \"Finder\"' -e 'set frontmost to true' -e 'reveal (POSIX file \"$path\")' -e 'end tell'"
-- for windows
url_browser_windows_cmd = "explorer \"$url\""
file_browser_windows_cmd = "explorer /select,\"$path\""

--// check if it's a url/stream
function is_url(path)
	if path ~= nil and string.sub(path,1,4) == "http" then
		return true
	else
		return false
	end
end

--// path separator stuffs
function path_sep()
	if Platform:IsInRange(Platform.OS_RANGES.NT) then
		return "\\" -- NT
	else
		return "/" --  Unix
	end
end

function split_by_separator(filepath)
	local t = {}
	local part_pattern = string.format("([^%s]+)", path_sep())
	for str in filepath:gmatch(part_pattern) do
		table.insert(t, str)
	end
	return t
end

function path_root()
	if path_sep() == "/" then
		return "/"
	else
		return ""
	end
end

--// Extract file dir from url
function normalize(relative_path, base_dir)
	base_dir = base_dir or mputils.getcwd()
	local full_path = mputils.join_path(base_dir, relative_path)

	local parts = split_by_separator(full_path)
	local idx = 1
	repeat
		if parts[idx] == ".." then
			table.remove(parts, idx)
			table.remove(parts, idx - 1)
			idx = idx - 2
		elseif parts[idx] == "." then
			table.remove(parts, idx)
			idx = idx - 1
		end
		idx = idx + 1
	until idx > #parts

	return path_root() .. table.concat(parts, path_sep())
end

--// handle "locate-current-file" function triggered by a key in "input.conf"
mp.register_script_message("locate-current-file", function()
	local path = mp.get_property("path")
	if path ~= nil then
		local cmd = ""
		if is_url(path) then
			msg.debug("Url detected '" .. path .. "', your OS web browser will be launched.")
			if Platform:IsInRange(Platform.OS_RANGES.NT) then
				cmd = url_browser_windows_cmd
			elseif Platform.platform == Platform.PLATFORMS.MAC then
				cmd = url_browser_macos_cmd
			elseif Platform:IsInRange(Platform.OS_RANGES.LINUX) then
				cmd = url_browser_linux_cmd
			else
				mp.osd_message("Platform " .. Platform:GetInternalName(Platform.platform) .. " has no supported open url implementation.")
			end
			cmd = cmd:gsub("$url", path)
		else
			msg.debug("File detected '" .. path .. "', your OS file browser will be launched.")
			if Platform:IsInRange(Platform.OS_RANGES.NT) then
				cmd = file_browser_windows_cmd
				path = path:gsub("/", "\\")
			elseif Platform.platform == Platform.PLATFORMS.MAC then
				cmd = file_browser_macos_cmd
			elseif Platform:IsInRange(Platform.OS_RANGES.LINUX) then
				cmd = file_browser_linux_cmd
			else
				mp.osd_message("Platform " .. Platform:GetInternalName(Platform.platform) .. " has no supported locate file implementation.")
			end
			path = normalize(path)
			cmd = cmd:gsub("$path", path)
		end
		msg.debug("Command to be executed: '" .. cmd .. "'")
		mp.osd_message('Browse \n' .. path)
		os.execute(cmd)
	else
		mp.osd_message("Cannot locate when nothing is playing.")
		msg.debug("'path' property was empty, no media has been loaded.")
	end
end)
