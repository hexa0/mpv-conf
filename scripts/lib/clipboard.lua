local Clipboard = {}

local Platform = require("platform")
local EscapeShellArgument = require("escapeShellArgument")

local WAYLAND_CLIPBOARD_GET_MPV_NATIVE_COMMAND = {
    name = "subprocess";
    args = {
        "bash";
        "--noprofile";
        "-c";
        "echo -n $(wl-paste)";
    };
    playback_only = false;
    capture_stdout = true;
    capture_stderr = true;
}

local X11_CLIPBOARD_GET_MPV_NATIVE_COMMAND = {
    name = "subprocess";
    args = {
        "xclip";
        "-selection";
        "clipboard";
        "-o";
    };
    playback_only = false;
    capture_stdout = true;
    capture_stderr = true;
}

local MACOS_CLIPBOARD_GET_MPV_NATIVE_COMMAND = {
    name = "subprocess";
    args = {
        "pbpaste";
    };
    playback_only = false;
    capture_stdout = true;
    capture_stderr = true;
}

local NT_CLIPBOARD_GET_MPV_NATIVE_COMMAND = {
    name = "subprocess";
    args = {
		"powershell";
		"-NoProfile";
		"-Command";
		"Get-Clipboard";
		"-Raw";
	};
    playback_only = false;
    capture_stdout = true;
    capture_stderr = true;
}

local function WAYLAND_CLIPBOARD_SET_MPV_NATIVE_COMMAND(text)
    return {
        name = "subprocess";
        args = {
            "bash";
			"--noprofile";
            "-c";
            "echo -n " .. EscapeShellArgument(text) .. " | wl-copy";
        };
        playback_only = false;
        capture_stdout = false;
        capture_stderr = true;
    }
end

local function X11_CLIPBOARD_SET_MPV_NATIVE_COMMAND(text)
    return {
        name = "subprocess";
        args = {
            "bash";
			"--noprofile";
            "-c";
            "echo -n " .. EscapeShellArgument(text) .. " | xclip -selection clipboard";
        };
        playback_only = false;
        capture_stdout = false;
        capture_stderr = true;
    }
end

local function MACOS_CLIPBOARD_SET_MPV_NATIVE_COMMAND(text)
    return {
        name = "subprocess";
        args = {
            "bash";
			"--noprofile";
            "-c";
            "echo -n " .. EscapeShellArgument(text) .. " | pbcopy";
        };
        playback_only = false;
        capture_stdout = false;
        capture_stderr = true;
    }
end

local function NT_CLIPBOARD_SET_MPV_NATIVE_COMMAND(text)
    return {
        name = "subprocess";
        args = {
            "powershell";
            "-NoProfile";
            "-Command";
            "Set-Clipboard";
            "-Value";
            text;
        };
        playback_only = false;
        capture_stdout = false;
        capture_stderr = true;
    }
end

local function GetWaylandClipboard()
    local clipboardProcess = mp.command_native(WAYLAND_CLIPBOARD_GET_MPV_NATIVE_COMMAND)

    if clipboardProcess.status < 0 then
       error("wayland paste failed: " .. clipboardProcess.error_string .. "\n" .. clipboardProcess.stderr)
    end

    return clipboardProcess.stdout
end

local function GetX11Clipboard()
    local clipboardProcess = mp.command_native(X11_CLIPBOARD_GET_MPV_NATIVE_COMMAND)

    if clipboardProcess.status < 0 then
       error("x11 paste failed: " .. clipboardProcess.error_string .. "\n" .. clipboardProcess.stderr)
    end

    return clipboardProcess.stdout
end

local function GetMacClipboard()
    local clipboardProcess = mp.command_native(MACOS_CLIPBOARD_GET_MPV_NATIVE_COMMAND)

    if clipboardProcess.status < 0 then
       error("mac paste failed: " .. clipboardProcess.error_string .. "\n" .. clipboardProcess.stderr)
    end

    return clipboardProcess.stdout
end

local function GetNTClipboard()
	local clipboardProcess = mp.command_native(NT_CLIPBOARD_GET_MPV_NATIVE_COMMAND)

    if clipboardProcess.status < 0 then
       error("nt paste failed: " .. clipboardProcess.error_string .. "\n" .. clipboardProcess.stderr)
    end

    return clipboardProcess.stdout
end

local function SetWaylandClipboard(text)
    mp.command_native_async(WAYLAND_CLIPBOARD_SET_MPV_NATIVE_COMMAND(text))
end

local function SetX11Clipboard(text)
    mp.command_native_async(X11_CLIPBOARD_SET_MPV_NATIVE_COMMAND(text))
end

local function SetMacClipboard(text)
    mp.command_native_async(MACOS_CLIPBOARD_SET_MPV_NATIVE_COMMAND(text))
end

local function SetNTClipboard(text)
	mp.command_native_async(NT_CLIPBOARD_SET_MPV_NATIVE_COMMAND(text))
end

function Clipboard.Get()
	if Platform.platform == Platform.PLATFORMS.LINUX_WAYLAND then
		return GetWaylandClipboard()
	elseif Platform.platform == Platform.PLATFORMS.LINUX_X11 then
		return GetX11Clipboard()
	elseif Platform.platform == Platform.PLATFORMS.MAC then
		return GetMacClipboard()
	elseif Platform:IsInRange(Platform.OS_RANGES.NT) then
		return GetNTClipboard()
	else
		mp.osd_message("Platform " .. Platform:GetInternalName(Platform.platform) .. " has no supported clipboard paste implementation,\nplease open a PR / Issue to hexa0/mpv-conf")
		return ""
	end
end

function Clipboard.Set(text)
	if Platform.platform == Platform.PLATFORMS.LINUX_WAYLAND then
		return SetWaylandClipboard(text)
	elseif Platform.platform == Platform.PLATFORMS.LINUX_X11 then
		return SetX11Clipboard(text)
	elseif Platform.platform == Platform.PLATFORMS.MAC then
		return SetMacClipboard(text)
	elseif Platform:IsInRange(Platform.OS_RANGES.NT) then
		return SetNTClipboard(text)
	else
		mp.osd_message("Platform " .. Platform:GetInternalName(Platform.platform) .. " has no supported clipboard copy implementation,\nplease open a PR / Issue to hexa0/mpv-conf")
		return ""
	end
end


return Clipboard