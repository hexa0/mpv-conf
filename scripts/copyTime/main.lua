-- https://github.com/Arieleg/mpv-copyTime
-- Copy the current time of the video to clipboard.

package.path = mp.command_native({"expand-path", "~~/scripts/lib/?.lua;"})..package.path

local Clipboard = require("clipboard")

local function CopyTime()
    local timePosition = mp.get_property_number("time-pos")

	if not timePosition then
		mp.osd_message("Cannot copy time when media is not playing.")
		return
	end

    local hours = timePosition / 3600
    local minutes = (timePosition / 60) % 60
    local seconds = timePosition % 60
    local milliseconds = (timePosition % 1) * 1000
	
    local time = string.format("%02d:%02d:%02d.%03d", math.floor(hours), math.floor(minutes), math.floor(seconds), milliseconds)
   
	Clipboard.Set(time)
	mp.osd_message(string.format("Copied to Clipboard: %s", time))
end

mp.add_key_binding("Ctrl+c", "copyTime", CopyTime)