echo off

echo ;BEGIN /script-opts
dir "%~1\script-opts\" /b

echo ;BEGIN /conf/script-opts
dir "%~1\conf\script-opts" /b

for /d %%i in ("%~1\conf\script-opts\*") do (
	echo ;BEGIN /conf/script-opts/%%~nxi/builtin
	dir "%~1\conf\script-opts\%%~nxi\builtin\" /b
	echo ;BEGIN /conf/script-opts/%%~nxi/user
	dir "%~1\conf\script-opts\%%~nxi\user\" /b
)

echo ;BEGIN /conf/input/builtin
dir "%~1\conf\input\builtin" /b

echo ;BEGIN /conf/input/user
dir "%~1\conf\input\user" /b

echo ;BEGIN /conf/mpv/builtin
dir "%~1\conf\mpv\builtin" /b

echo ;BEGIN /conf/mpv/user
dir "%~1\conf\mpv\user" /b