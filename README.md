# mpv-conf
this is pretty much just a repo for all of my mpv configurations so i can keep all of my installs updated,<br>
most of these scripts aren't made by me although i may have modified a lot of them, all sources have been added at the start of each script as a comment

# Usage

## conf-builder:
To allow the people to override my configs locally without breaking version control i made conf-builder<br/>
all configs are stored in the "conf" folder now,<br/>
in each folder there is two sub folders (builtin and user)<br/>
edit the files in "user" then press shift + home to trigger a build<br/>
alternatively if you don't have a full keyboard you can delete the mpv.conf file and it will automatically retrigger on the next restart of mpv.<br/>
FYI all config files need to start with a number and have none of the numbers skipped, this is to ensure consistency when building the configs

## Keybinds:
* ## Custom to mpv-conf
* **shift + home** | _Manually trigger conf-builder to rebuild the configs_
* **shift + m** | _Mocks the audio and makes it sound stupid because it's funny lmao_
* **ctrl + 3** | _Switch audio track merge mode_
* ## Third-party scripts
* **f12** | _Search for keybinds_
* **c** | _Cycles between audio visaulizers (broken in windowed mode)_
* **ctrl + v** | _Attempts to open the url from the clipboard_
* **alt + o** | _Locates the current file_
* **k** | _Take a cropped screenshot_
* **shift + c** | _Copies the current timestamp to the clipboard_
* ## MPV bindings
* **shift + 3** | _Switch audio track_
* **scroll wheel** | _Change volume_

# Installation (Windows)
First you'll need mpv itself, for that make sure to use [chocolatey](https://chocolatey.org/install) as it's the easiest installation method<br>
```bash
choco install mpvio -a
```
if you've previously installed the outdated `mpv` package, then uninstall that with
```bash
choco uninstall mpv -a
```
that package states it isn't out of date but that's very wrong, it will break the titles of videos in the osc

then to install this config on windows, you'll need git, if you don't have it install it like this
```bash
choco install git -a
```
and then run
```bash
git clone https://github.com/hexa0/mpv-conf %USERPROFILE%\AppData\Roaming\mpv
```
# Installation (Linux)
Install the latest version of MPV and git from your package manager and run
```bash
git clone https://github.com/hexa0/mpv-conf ~/.config/mpv
```
if you're on wayland you'll need to install [wl-clipboard](https://github.com/bugaevc/wl-clipboard) to be able to copy timestamps<br/>
on wayland it's also recommended to edit the configs locally too (see the conf-builder section for more info)<br/>
create a user config with
```conf
vo=wlshm
```
to fix MPV taking two decades to open up<br/>
also you should add this regardless of you running wayland
```conf
audio-buffer=0.1
```
to prevent audio stutters as the audio on linux seems to be a lot laggier
# Installation (MacOS)
i don't own a mac no clue, maybe try following some of the linux instructions?