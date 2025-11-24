-- written by hexa
-- saves the last used volume to ".volsave"

package.path = mp.command_native({"expand-path", "~~/scripts/lib/?.lua;"})..package.path

local CommentDataCodec = require("commentDataCodec")
local fs = require("fs")

local options = {
	muted = false;
	volume = 74;
}

local OUT_PATH = ("%s/.volume.conf"):format(mp.get_script_directory())

local function Init()
	if fs.FileExists(OUT_PATH) then
		fs.OpenFile(OUT_PATH, fs.IO_MODE.READ, function(file)
			local content = file:read("*all")
			local parsed = CommentDataCodec.Parse(content, "root")

			for k, v in pairs(parsed) do
				options[k] = v
			end

			mp.set_property("volume", tonumber(options.volume))
			mp.set_property_native("mute", options.muted)
		end)
	end
end

local function Save()
	fs.OpenFile(OUT_PATH, fs.IO_MODE.WRITE, function(file)
		options.volume = tostring(mp.get_property("volume"))
		options.muted = mp.get_property_native("mute")
		file:write(CommentDataCodec.Encode(options, "root"))
	end)
end

local function OnExit()
	Save()
end

mp.register_event("shutdown", OnExit)
Init()