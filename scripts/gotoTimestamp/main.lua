-- written by hexa0
-- allows you to paste a timestamp in to jump to it
-- some logic was re-used from here https://github.com/zenyd/mpv-scripts/blob/master/copy-paste-URL.lua

package.path = mp.command_native({"expand-path", "~~/scripts/lib/?.lua;"})..package.path

local Clipboard = require("clipboard")

local function ValidateContentAsTimestamp(content)
    local secondsOnly = tonumber(content)
    if secondsOnly ~= nil then
        return secondsOnly
    end

    local parts = {}
    for part in string.gmatch(content, "[^:.]+") do
        local num = tonumber(part)
        if num == nil then
            return nil
        end
        table.insert(parts, num)
    end
    
    local numParts = #parts
    local totalSeconds = 0
    
    if numParts < 2 or numParts > 4 then
        return nil
    end
    
    local milliseconds = parts[numParts] or 0
    local seconds = parts[numParts - 1] or 0
    local minutes = parts[numParts - 2] or 0
    local hours = parts[numParts - 3] or 0
    
    if (numParts >= 3 and minutes >= 60) or seconds >= 60 then
        return nil
    end

    totalSeconds = (hours * 3600) + (minutes * 60) + seconds + (milliseconds / 1000)
    
    return totalSeconds
end

local function PasteTimestamp()
	local clipboardContent = Clipboard.Get()
    local timePosition = mp.get_property_number("time-pos")

    if not timePosition then
		mp.osd_message("Cannot seek when media is not playing.")
		return
	end

	if #clipboardContent > 0 then
		print(clipboardContent)
		local validatedSeconds = ValidateContentAsTimestamp(clipboardContent)

		if validatedSeconds then
			mp.set_property("time-pos", validatedSeconds)
            
            local hours = validatedSeconds / 3600
            local minutes = (validatedSeconds / 60) % 60
            local seconds = validatedSeconds % 60
            local milliseconds = (validatedSeconds % 1) * 1000

            local displayTime = string.format("%02d:%02d:%02d.%03d", math.floor(hours), math.floor(minutes), math.floor(seconds), milliseconds)
            
			mp.osd_message("Jumping to: " .. displayTime)
		else
			mp.osd_message("Clipboard Isn't A Valid Timestamp")
		end
	else
		mp.osd_message("Clipboard Is Empty")
	end
end

mp.add_key_binding("Ctrl+g", "paste-timestamp", PasteTimestamp)