# mpv-conf
this is pretty much just a repo for all of my mpv configurations so i can keep all of my installs updated,<br>
most of these scripts aren't made by me although i may have modified a lot of them, all sources have been added at the start of each script as a comment

# installation
first you'll need mpv itself, for that if you're on windows make sure use [chocolatey](https://chocolatey.org/install) as it's the easiest installation method<br>
```bash
choco install mpvio -a
```
if you've previously installed the outdated `mpv` package, then uninstall that with
```bash
choco uninstall mpv -a
```
that package states it isn't out of date but that's very wrong, it will break the titles of videos in the osc

then to install this config on windows run:
```bash
choco install git -a
^ (skip if you have git already)
```
and then
```bash
git clone https://github.com/hexa0/mpv-conf %USERPROFILE%\AppData\Roaming\mpv
```
if you're on linux you are probably not even going to need these install instructions, as for mac, i don't own one, good luck lol

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