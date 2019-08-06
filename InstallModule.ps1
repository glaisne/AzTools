$ModuleName = "AzTools"
$ModulePath = "C:\Program Files\PowerShell\Modules"
$TargetPath = "$($ModulePath)\$($ModuleName)"

Copy-Item -Verbose -Path "$PSScriptRoot\$ModuleName" -Destination $ModulePath -Container -Recurse -Force