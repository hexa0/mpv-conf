# mpv-conf
this is pretty much just a repo for all of my mpv configurations so i can keep all of my installs updated,<br>
most of these scripts aren't made by me although i may have modified a lot of them, all sources have been added at the start of each script as a comment

# installation (windows)
first you'll need mpv itself, for that make sure to use [chocolatey](https://chocolatey.org/install) as it's the easiest installation method<br>
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
# installation (linux)
install the latest version of MPV from your package manager and run
```bash
git clone https://github.com/hexa0/mpv-conf ~/.config/mpv
```
this _should_ work however i haven't tested linux yet
# installation (mac)
i don't own a mac no clue, maybe try following some of the linux instructions

## binds:
* **shift + m** | _mocks the audio and makes it sound stupid, made this because funny_
* **c** | _cycles between audio visaulizers (broken in windowed mode)_
* **ctrl + v** | _attempts to open the url from the clipboard_
* **alt + o** | _locates the current file_
* **f12** | _search for keybinds_
* **scroll wheel** | _change volume_
* **k** | _take a cropped screenshot_
* **shift + 3** | _switch audio track_
* **ctrl + 3** | _switch audio track merge mode_
* **shift + home** | _manually trigger a rebuild of the config_