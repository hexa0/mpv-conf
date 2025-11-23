-- written by hexa0
-- fix for pasting paths & URLs into mpv on wayland (tested on kubuntu 25.10)

local PLAYLIST_ACTION = "replace"

local WAYLAND_CLIPBOARD_MPV_NATIVE_COMMAND = {
    name = "subprocess";
    args = {
        "bash";
        "--noprofile";
        "-c";
        "echo -n $(wl-paste)";
    };
    playback_only = false;
    capture_stdout = true;
    capture_stderr = true;
}

local function GetWaylandClipboard()
    local clipboardProcess = mp.command_native(WAYLAND_CLIPBOARD_MPV_NATIVE_COMMAND)

    if clipboardProcess.status < 0 then
       error("wayland paste failed: " .. clipboardProcess.error_string .. "\n" .. clipboardProcess.stderr)
    end

    return clipboardProcess.stdout
end

local function Clamp(x, min, max)
    return (x < max and ((x > min and x) or min)) or max
end

local function ClampedSub(sourceString, startPosition, endPosition)
    local length = #sourceString

    return string.sub(
        sourceString,
        startPosition and (startPosition > 0 and Clamp(startPosition, 1, length)) or Clamp(startPosition, -length, -1),
        endPosition and ((endPosition > 0 and Clamp(endPosition, 1, length)) or Clamp(endPosition, -length, -1)) or nil
    )
end

local URLHexToCharacter = function(hexCode)
    return string.char(tonumber(hexCode, 16))
end

local function ValidateContentShouldBeLoadable(path)
    if ClampedSub(path, 1, 1) == "/" then
        return path -- unix file path
    elseif ClampedSub(path, 1, 7) == "http://" then
        return path -- http url
    elseif ClampedSub(path, 1, 8) == "https://" then
        return path -- https url
    elseif ClampedSub(path, 1, 7) == "file://" then -- file url
		-- mpv cannot handle this format so we parse it
        return ClampedSub(path, 8, -2):gsub("%%(%x%x)", URLHexToCharacter):gsub("+", " ")
    end

    return nil
end

local function Paste()
	local clipboardContent = GetWaylandClipboard()

	if #clipboardContent > 0 then
		local validated = ValidateContentShouldBeLoadable(clipboardContent)

		print(validated)
		if validated then
			mp.osd_message("Trying To Open URL/Path:\n" .. validated)
			mp.commandv("loadfile", validated, PLAYLIST_ACTION)
		else
			mp.osd_message("Clipboard Is Invalid")
		end
	else
		mp.osd_message("Clipboard Is Empty")
	end
end

mp.add_key_binding(nil, "paste-url-wayland", Paste)