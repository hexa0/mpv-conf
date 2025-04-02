echo ";BEGIN /script-opts"
Get-ChildItem -Path ($args[0] + "/script-opts/") -Name

echo ";BEGIN /conf/script-opts"
Get-ChildItem -Path ($args[0] + "/conf/script-opts/") -Name

foreach ($item in Get-ChildItem -Path ($args[0] + "/conf/script-opts/")) {
	echo ";BEGIN /conf/script-opts/$($item.name)/builtin"
	Get-ChildItem -Path ($args[0] + "/conf/script-opts/$($item.name)/builtin/") -Name
	echo ";BEGIN /conf/script-opts/$($item.name)/user"
	Get-ChildItem -Path ($args[0] + "/conf/script-opts/$($item.name)/user/") -Name
}

echo ";BEGIN /conf/input/builtin"
Get-ChildItem -Path ($args[0] + "/conf/input/builtin/") -Name

echo ";BEGIN /conf/input/user"
Get-ChildItem -Path ($args[0] + "/conf/input/user/") -Name

echo ";BEGIN /conf/mpv/builtin"
Get-ChildItem -Path ($args[0] + "/conf/mpv/builtin/") -Name

echo ";BEGIN /conf/mpv/user"
Get-ChildItem -Path ($args[0] + "/conf/mpv/user/") -Name