-- credits to knock for making me aware of being able to do this aswell as where she got the filter from: https://github.com/mpv-player/mpv/issues/6536#issuecomment-1966449338
-- however this entire script was written by me (hexa)

local modes = {
	no = 1;
	all = 2;
	allBut3 = 3;
}

local modeStrings = {
	"No Merging";
	"All";
	"All (Excluding Track 3)"; -- used by me to exclude the unprocessed mic channel to prevent it from classing with the processed mic
}

local totalModes = 3
local mode = 0

local modeFunctions = {
	function () -- no
		return {}
	end;
	function (tracks) -- all
		local createdTable = {}
		
		for i=1, #tracks do
			table.insert(createdTable, true)
		end

		return createdTable
	end;
	function (tracks) -- all but 3
		local createdTable = {}

		for i=1, #tracks do
			table.insert(createdTable, i ~= 3)
		end

		return createdTable
	end;
}

function switchMode()
	mode = mode + 1

	if mode > totalModes then
		mode = 1
	end

	local tracks = {}

	for _, track in pairs(mp.get_property_native("track-list", {})) do
		if track.type == "audio" then
			table.insert(tracks, {
				id = tonumber(track.id);
				title = track.title or "unknown";
				included = false;
			})
		end
	end

	local filter = ""
	local enabledTracks = modeFunctions[mode](tracks)

	if #enabledTracks > 0 then
		local count = 0
		for i, enabled in pairs(enabledTracks) do
			if enabled then
				count = count + 1
				filter = filter .. "[aid" .. tostring(i) .. "] "
			end
		end
		
		filter = filter .. "amix=inputs=" .. count .. ":normalize=0[ao]"
	end

	mp.set_property("options/lavfi-complex", filter)

	mp.osd_message("Audio Merge Mode: " .. modeStrings[mode], 0.5)
end

mp.add_key_binding("ctrl+3", "switch-audio-mode", switchMode)