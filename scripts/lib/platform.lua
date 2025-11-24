local Platform = {}

Platform.OS_RANGES = {
	NT = {0, 99};
	UNIX = {100, 199};
	LINUX = {110, 119};
}

Platform.PLATFORMS = {
	-- NT 0 - 99
	WINDOWS = 0;
	-- WINDOWS7 = 1;
	-- WINDOWS8 = 2;
	-- WINDOWS8_1 = 3;
	-- WINDOWS10 = 4;
	-- WINDOWS11 = 5;

	-- UNIX-LIKE 100 - 199
	UNIX_GENERIC = 100;
	MAC = 101;
	LINUX_X11 = 110;
	LINUX_WAYLAND = 111;
	-- BSD = 103;
}

-- an unknown OS will be assumed to be UNIX_GENERIC
Platform.platform = Platform.PLATFORMS.UNIX_GENERIC; do
	if package.cpath:match(".dll") then -- Windows
		Platform.platform = Platform.PLATFORMS.WINDOWS
	elseif package.cpath:match(".so") then -- Linux
		if os.getenv("WAYLAND_DISPLAY") then -- Wayland
			Platform.platform = Platform.PLATFORMS.LINUX_WAYLAND
		else -- X11
			Platform.platform = Platform.PLATFORMS.LINUX_X11
		end
	elseif package.cpath:match(".dylib") then -- Mac
		Platform.platform = Platform.PLATFORMS.MAC
	end
end

function Platform:IsInRange(range)
	return self.platform >= range[1] and self.platform <= range[2]
end

function Platform:GetInternalName(id)
	for i, v in pairs(self.PLATFORMS) do
		if v == id then
			return i
		end
	end

	return "UNKNOWN_PLATFORM_" .. id
end

-- print("mpv is running on " .. Platform:GetInternalName(Platform.platform))

return Platform