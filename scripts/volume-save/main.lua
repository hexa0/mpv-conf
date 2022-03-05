-- written by hexa
-- saves the last used volume to ".volsave"

local OUT_PATH = ("%s/.volsave"):format(mp.get_script_directory())

mp.register_event("file-loaded", function()
	local success, volumeSaveError = pcall(function()
		print("loading volume")
		local volumeSave = io.open(OUT_PATH, "r")
		local volumeSaveData = volumeSave:read("*a")
		print("got ")
		mp.set_property("volume", tonumber(volumeSaveData))
		volumeSave:close()
	end)
	if not success then -- something fucked up, probably didn't have a .volsave yet
		print("[warn]", volumeSaveError)
	end
end)

mp.register_event("shutdown", function()
	print("saving volume")
	local volumeSave  = io.open(OUT_PATH, "w")
	volumeSave:write(tostring(mp.get_property("volume")))
	volumeSave:close()
end)