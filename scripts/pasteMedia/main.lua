-- written by hexa0
-- supports for pasting in files and urls for multiple platforms
-- some logic was re-used from here https://github.com/zenyd/mpv-scripts/blob/master/copy-paste-URL.lua

package.path = mp.command_native({"expand-path", "~~/scripts/lib/?.lua;"})..package.path

local Clipboard = require("clipboard")

local PLAYLIST_ACTION = "replace"

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
    elseif ClampedSub(path, 2, 3) == ":\\" and ClampedSub(path, 1, 1):match("%a") then
        return path -- nt file path
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

local function PasteMedia()
	local clipboardContent = Clipboard.Get()

	if #clipboardContent > 0 then
		local validated = ValidateContentShouldBeLoadable(clipboardContent)

		if validated then
			mp.osd_message("Trying To Open URL/Path:\n" .. validated)
			mp.commandv("loadfile", validated, PLAYLIST_ACTION)
		else
			mp.osd_message("Clipboard Isn't Playable Media")
		end
	else
		mp.osd_message("Clipboard Is Empty")
	end
end

mp.add_key_binding("Ctrl+v", "paste-media", PasteMedia)