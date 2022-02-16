-- written by hexa
-- mocks the audio by distorting the pitch

local mockEnabled = false
local previousSpeed = 1
local SPEED = 32
local AMP = 0.1
local OSDTX_ENABLED = "Mock enabled"
local OSDTX_DISBLED = "Mock disabled"

local function MockLoop()
	if mockEnabled then
		mp.set_property("speed", previousSpeed + math.sin(os.clock() * SPEED) * AMP)
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