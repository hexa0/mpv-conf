-- written by hexa
-- mocks the audio by distorting the pitch

local mp = require("mp")

local mockEnabled = false
local previousSpeed = 1
local SPEED = 32
local AMP = 0.1
local OSDTX_ENABLED = "Mock enabled"
local OSDTX_DISBLED = "Mock disabled"

local function ToggleMock()
	mockEnabled = not mockEnabled
	if mockEnabled then
		print("Mock Enabled")
		previousSpeed = mp.get_property("speed")
		mp.osd_message(OSDTX_ENABLED, 0.5)
	else
		print("Mock Disabled")
		mp.set_property("speed", previousSpeed)
		mp.osd_message(OSDTX_DISBLED, 0.5)
	end
end

local mockTime = 0
local function MockUpdate()
	mockTime = mockTime + 1 / 60
	if mockEnabled then
		mp.set_property("speed", previousSpeed + math.sin(mockTime * (SPEED)) * AMP)
	end
end

mp.add_key_binding("M", "mock-audio", ToggleMock)
mp.add_periodic_timer(1/60, MockUpdate)