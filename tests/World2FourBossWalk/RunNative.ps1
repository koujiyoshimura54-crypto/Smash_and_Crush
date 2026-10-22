param([string]$Label='Smoke')
$ErrorActionPreference='Stop'
$runner=Join-Path $env:TEMP 'FourBossNative.luau'
$output=Join-Path $env:TEMP "FourBoss_$Label.log"
$process=Start-Process -FilePath 'C:\Users\kouji\AppData\Local\Roblox\Versions\version-7aaa6838d36c4448\RobloxStudioBeta.exe' -ArgumentList "--task RunScript --localPlaceFile C:\Users\kouji\MergeToForge_CurrentCloud.rbxl --runScriptFile $runner --outputFile $output --quitAfterExecution" -WindowStyle Hidden -PassThru
$watcher=Join-Path $PSScriptRoot 'CaptureSequences.ps1'
Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $watcher -OwnedEditProcess $($process.Id) -Label $Label" -WindowStyle Hidden -RedirectStandardOutput (Join-Path $env:TEMP "FourCapture_$Label.out") -RedirectStandardError (Join-Path $env:TEMP "FourCapture_$Label.err") | Out-Null
Write-Output "OwnedEditPid=$($process.Id) Log=$output"
