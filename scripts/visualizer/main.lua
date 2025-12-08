-- taken from https://github.com/mfcc64/mpv-scripts/blob/master/visualizer.lua
-- however i made a lot of modifications of my own

local options = require 'mp.options'

local function Read(file) 
	local handle = io.open(debug.getinfo(1, "S").source:sub(2, -9) .. file, "r")
	local content = {}

	for line in handle:lines() do
		table.insert(content, line)
	end

	handle:close()

	return content
end

local VISUALIZERS = {
    "off";
    "showcqt";
    "avectorscope";
    "showspectrum";
    "showcqtbar";
    "showwaves";
	"showvolume";
}

local OSDTX_FORMAT_SWITCH = "Switched visualizer to %s"
local OSDTX_FORMAT_OFF = "Disabled audio visualizer"
local OSDTX_NO_TRACKS = "Cannot cycle audio visualizer,\nno audio tracks found."

local RESOURCES = Read("resources.txt")

local visualizerSettings = {
    enabled = true;

	--[[
		off
		showcqt
		avectorscope
		showspectrum
		showcqtbar
		showwaves
		showvolume
	]]
    name = "off";

	keyCycleFowards = "a";
	keyCycleBackwards = "A";

	--[[
		verylow
		low
		medium
		high
		veryhigh
	]]
    quality = "veryhigh";
}

options.read_options(visualizerSettings, "visualizer")

local lastAudioTrack
local lastVideoTrack

function math.clamp(n, min, max)
	if n < min then
		return min
	elseif n > max then
		return max
	else
		return n
	end
end

local function get_visualizer()
    local w, h, fps

    if visualizerSettings.quality == "verylow" then
        w = 640
        fps = 30
    elseif visualizerSettings.quality == "low" then
        w = 960
        fps = 30
    elseif visualizerSettings.quality == "medium" then
        w = 1280
        fps = 60
    elseif visualizerSettings.quality == "high" then
        w = 1920
        fps = 60
    elseif visualizerSettings.quality == "veryhigh" then
        w = 2560
        fps = 60
    else
        mp.log("error", "invalid quality")
        return nil
    end

    if h == nil then -- only if a quality doesn't manually define a height
		h = w / (16 / 9)
	end

	local msg = visualizerSettings.name == "off" and OSDTX_FORMAT_OFF or OSDTX_FORMAT_SWITCH 
	mp.osd_message(msg:format(visualizerSettings.name), 1)

	local audio_params = mp.get_property_native("audio-params") or mp.get_property_native("audio-out-params") or { samplerate = 48000 }
	-- in case of e.g. lavfi-complex there can be no input audio, only output
	if not audio_params then
		audio_params = mp.get_property_native("audio-out-params")
	end

	local video_params = mp.get_property_native("video-params") or mp.get_property_native("video-out-params") or {}

	local display_fps = mp.get_property_number("display-fps", 0) or 60

	lastAudioTrack = lastAudioTrack or "1"
	local audioInput = "[aid" .. lastAudioTrack .. "]"

    if visualizerSettings.name == "showcqt" then
        local count = math.ceil(w * 180 / 1920 / fps)

        return audioInput .. " asplit [ao]," ..
            "aformat     = channel_layouts = stereo," ..
            "showcqt            =" ..
                "fps            =" .. fps .. ":" ..
                "size           =" .. w .. "x" .. h .. ":" ..
                "count          =" .. count .. ":" ..
                "csp            = bt709:" ..
                "bar_g          = 2:" ..
                "sono_g         = 4:" ..
                "bar_v          = 9:" ..
                "sono_v         = 17:" ..
                "axisfile       = data\\\\:'image/webp;base64," .. RESOURCES[1] .. "':" ..
                "font           = 'Nimbus Mono L,Courier New,mono|bold':" ..
                "fontcolor      = 'st(0, (midi(f)-53.5)/12); st(1, 0.5 - 0.5 * cos(PI*ld(0))); r(1-ld(1)) + b(ld(1))':" ..
                "tc             = 0.33:" ..
                "attack         = 0.033:" ..
                "tlength        = 'st(0,0.17); 384*tc / (384 / ld(0) + tc*f /(1-ld(0))) + 384*tc / (tc*f / ld(0) + 384 /(1-ld(0)))'," ..
            "format             = yuv420p [vo]"


    elseif visualizerSettings.name == "avectorscope" then
        return audioInput .. " asplit [ao]," ..
            "aformat            =" ..
                "sample_rates   = 384000," ..
            "avectorscope       =" ..
                "size           =" .. w .. "x" .. h .. ":" ..
                "r              =" .. display_fps .. ":" ..
				"mirror=y" .. ":" ..
				"draw=line" .. ":" ..
				"rf=100:bf=100:gf=100" .. ":" ..
				"m              =" .. "lissajous_xy" .. "," ..
            "format             = rgb0 [vo]"


    elseif visualizerSettings.name == "showspectrum" then
		local height = math.clamp(audio_params["samplerate"] / 128, 10, 48000 / 128)
        return audioInput .. " asplit [ao]," ..
            "showspectrum       =" ..
				"mode=combined:color=rainbow:saturation=2:gain=0.2:fscale=lin:win_func=parzen:legend=1:drange=120:slide=scroll:fps=" .. display_fps .. ":" ..
                "size           =" .. math.floor(height * (w/h)) .. "x" .. math.floor(height) .. ":[vo]"


    elseif visualizerSettings.name == "showcqtbar" then
        local axis_h = math.ceil(w * 12 / 1920) * 4

        return audioInput .. " asplit [ao]," ..
            "aformat     = channel_layouts = stereo," ..
            "showcqt            =" ..
                "fps            =" .. display_fps .. ":" ..
                "size           =" .. w .. "x" .. (h + axis_h)/2 .. ":" ..
                "count          = 1:" ..
                "csp            = bt709:" ..
                "bar_g          = 2:" ..
                "sono_g         = 4:" ..
                "bar_v          = 9:" ..
                "sono_v         = 17:" ..
                "sono_h         = 0:" ..
                "axisfile       = data\\\\:'image/webp;base64," .. RESOURCES[2] .. "':" ..
                "axis_h         =" .. axis_h .. ":" ..
                "font           = 'Nimbus Mono L,Courier New,mono|bold':" ..
                "fontcolor      = 'st(0, (midi(f)-53.5)/12); st(1, 0.5 - 0.5 * cos(PI*ld(0))); r(1-ld(1)) + b(ld(1))':" ..
                "tc             = 0.33:" ..
                "attack         = 0.033:" ..
                "tlength        = 'st(0,0.17); 384*tc / (384 / ld(0) + tc*f /(1-ld(0))) + 384*tc / (tc*f / ld(0) + 384 /(1-ld(0)))'," ..
            "format             = yuv420p," ..
            "split [v0]," ..
            "crop               =" ..
                "h              =" .. (h - axis_h)/2 .. ":" ..
                "y              = 0," ..
            "vflip [v1];" ..
            "[v0][v1] vstack [vo]"


    elseif visualizerSettings.name == "showwaves" then
		local width = audio_params["samplerate"] * (1/display_fps)
        return audioInput .. " asplit [ao]," ..
            "showwaves          =" ..
                "size           =" .. math.floor(width) .. "x" .. math.floor(width * (h/w)) .. ":" ..
                "r              =" .. display_fps .. ":" ..
                "mode           = p2p," ..
            "format             = rgb0 [vo]"
	elseif visualizerSettings.name == "showvolume" then
		return audioInput .. " asplit [ao]," ..
			"showvolume         =" ..
			"w                  =" .. w/2 .. ":" ..
			"h                  =" .. h/8 .. ":" ..
			"r                  =" .. display_fps .. ":" ..
			"m                  =p" .. ":" ..
			"t                  =true " .. ":" ..
			"f                  =0" .. ":" ..
			"ds                 =log" .. ":" ..
			"dm                 =1," ..
			"format             = rgb0 [vo]"
    elseif visualizerSettings.name == "off" then
		return nil
    end

    mp.log("error", "invalid visualizer name")
    return nil
end

local function select_visualizer()
    return visualizerSettings.enabled and get_visualizer() or nil
end

local function visualizer_hook()
	if mp.get_property_number("track-list/count", -1) <= 0 then
		mp.osd_message(OSDTX_NO_TRACKS, 1)
		return
	end

	if mp.get_property("file-local-options/lavfi-complex") == "" then
		lastAudioTrack = mp.get_property("audio")
		lastVideoTrack = mp.get_property("video")
	end

	local selected = select_visualizer()

	if selected then
		mp.set_property("file-local-options/lavfi-complex", selected)
		mp.commandv("set", "audio", 0)
		mp.commandv("set", "video", 0)
	else
		mp.set_property("file-local-options/lavfi-complex", "")
		mp.commandv("set", "audio", lastAudioTrack)
		mp.commandv("set", "video", lastVideoTrack)
	end
end

local function cycle_visualizer()
    local index

    for i=1, #VISUALIZERS do
        if (VISUALIZERS[i] == visualizerSettings.name) then
            index = i + 1
            if index > #VISUALIZERS then
                index = 1
            end
            break
        end
    end
	
    visualizerSettings.name = VISUALIZERS[index]
    visualizer_hook()
end

local function cycle_visualizer_reverse()
	local index = 1

	for i=1, #VISUALIZERS do
		if (VISUALIZERS[i] == visualizerSettings.name) then
			index = i - 1
			if index < 1 then
				index = #VISUALIZERS
			end
			break
		end
	end

	visualizerSettings.name = VISUALIZERS[index]
	visualizer_hook()
end

mp.add_key_binding(visualizerSettings.keyCycleFowards, "cycle-visualizer", cycle_visualizer)
mp.add_key_binding(visualizerSettings.keyCycleBackwards, "reverse-cycle-visualizer", cycle_visualizer_reverse)