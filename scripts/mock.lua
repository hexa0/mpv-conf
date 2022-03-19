-- written by hexa
-- mocks the audio by distorting the pitch

local mockEnabled = false
local previousSpeed = 1
local speedFix = 1
local SPEED = 32
local AMP = 0.1
local OSDTX_ENABLED = "Mock enabled"
local OSDTX_DISBLED = "Mock disabled"

local BinaryFormat = package.cpath:match("%p[\\|/]?%p(%a+)")
if BinaryFormat == "dll" then -- Windows

elseif BinaryFormat == "so" then -- Linux
	-- Speed appears to be around slower depending on video framerate on my linux install, no idea if this happens on all distros
	-- This check is here if i every find a way to actually fix it
elseif BinaryFormat == "dylib" then -- Mac

end

local function MockLoop()
	if mockEnabled then
		mp.set_property("speed", previousSpeed + math.sin(os.clock() * (SPEED * speedFix)) * AMP)
		mp.add_timeout(1/60, MockLoop)
	end
end

local function ToggleMock()
	mockEnabled = not mockEnabled
	if mockEnabled then
		print("Mock Enabled")
		previousSpeed = mp.get_property("speed")
		MockLoop()
		mp.osd_message(OSDTX_ENABLED, 0.5)
	else
		print("Mock Disabled")
		mp.set_property("speed", previousSpeed)
		mp.osd_message(OSDTX_DISBLED, 0.5)
	end
end

mp.add_key_binding("M", "mock-audio", ToggleMock)