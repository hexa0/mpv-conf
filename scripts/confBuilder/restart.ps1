$processOptions = @{
    FilePath = "mpv.exe"
    ArgumentList = "`"$($args[0])`"", "--start=$($args[1])"
}

Start-Process @processOptions