local platformCheck = {}

platformCheck.OS_RANGES = {
	NT = {0, 99};
	UNIX = {100, 199};
}

platformCheck.PLATORMS = {
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
	LINUX = 102;
	-- BSD = 103;
}

-- an unknown OS will be assumed to be UNIX_GENERIC
platformCheck.platform = platformCheck.PLATORMS.UNIX_GENERIC do
	if package.cpath:match(".dll") then -- Windows
		platformCheck.platform = platformCheck.PLATORMS.WINDOWS
	elseif package.cpath:match(".so") then -- Linux
		platformCheck.platform = platformCheck.PLATORMS.LINUX
	elseif package.cpath:match(".dylib") then -- Mac
		platformCheck.platform = platformCheck.PLATORMS.MAC
	end
end

function platformCheck:IsInRange(range)
	return self.platform >= range[1] and self.platform <= range[1]
end

return platformCheck