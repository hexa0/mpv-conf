# mpv-conf
this is pretty much just a repo for all of my mpv configurations so i can keep all of my installs updated,<br>
not all of these scripts are made by me although i may have modified a lot of them,<br>
all sources have been added at the start of each script as a comment if it wasn't entirely written by me,<br>
if you see anything uncredited or incorrectly credited please open an issue/pr

# Usage

## conf-builder:
To allow the people to override my configs locally without breaking version control i made conf-builder<br/>
all configs are stored in the "conf" folder now,<br/>
in each folder there is two sub folders (`builtin` and `user`)<br/>
edit the files in `user` then press shift + home to trigger a build<br/>
alternatively if you don't have a full 100% keyboard you can delete the mpv.conf file and it will automatically retrigger on the next restart of mpv.<br/>
FYI all config files will be combined together so anything not starting with a number will have the lowest priorirty,<br/>
if your config needs to apply afer other configs to override them you will need to prefix it with a number e.g: "1-config.conf",<br/>
by default everything without a number is treated as 0,<br/>
additionally anything in `user` will always be applied after `builtin`

## Keybinds:
* **shift + home** | _Manually trigger conf-builder to rebuild the configs_
* **a** / **shift + A** | _Cycles forward/backwards through audio visaulizers (best used in fullscreen)_
* **shift + C** | _Attempt to automatically crop out black borders_
* **alt + o** | _Locates the current file_
* **k** | _Take a cropped screenshot_
* **ctrl + c** | _Copies the current timestamp to the clipboard_
* **ctrl + v** | _Attempts to open the file/url from the clipboard_
* **ctrl + g** | _Attempts to seek to the copied timestamp on the clipboard_
* **shift + 3** | _Switch audio track_
* **ctrl + 3** | _Switch audio track merge mode_
* **shift + M** | _Mocks the audio and makes it sound stupid because it's funny lmao_
* **scroll wheel** | _Change volume by 2_

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
if you're on wayland you'll need to install [wl-clipboard](https://github.com/bugaevc/wl-clipboard) to use clipboard related features,<br/>
or if you're on x11 you'll need to ensure that `xclip` is installed or else you will be unable to use clipboard features,<br/>
additionally there are also configs that will automatically be applied specifically on linux as well as wayland fixes to resolve various problems<br/>
however since i run wayland not x11 i have not tested these configs there,<br/>
changes may need to be made for things to work smoothly
# Installation (MacOS)
i don't own a mac no clue, maybe try following some of the linux instructions?