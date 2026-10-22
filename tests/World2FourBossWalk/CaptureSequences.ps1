param([int]$OwnedEditProcess,[string]$Label)
$ErrorActionPreference='Stop'
$started=(Get-Process -Id $OwnedEditProcess).StartTime
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$folder=Join-Path $root "reports\World2FourBossWalk_20261022\frames\$Label"
New-Item -ItemType Directory -Force -Path $folder | Out-Null
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;using System.Text;using System.Runtime.InteropServices;
public static class FourCapture {
 public delegate bool Visitor(IntPtr h,IntPtr d);
 [StructLayout(LayoutKind.Sequential)]public struct Rect {public int Left,Top,Right,Bottom;}
 [DllImport("user32.dll")]public static extern bool EnumWindows(Visitor c,IntPtr d);
 [DllImport("user32.dll")]public static extern uint GetWindowThreadProcessId(IntPtr h,out uint p);
 [DllImport("user32.dll")]public static extern bool GetWindowRect(IntPtr h,out Rect r);
 [DllImport("user32.dll")]public static extern bool PrintWindow(IntPtr h,IntPtr dc,uint flags);
}
'@
$seen=@{};$deadline=(Get-Date).AddMinutes(13)
while((Get-Date) -lt $deadline -and (Get-Process -Id $OwnedEditProcess -ErrorAction SilentlyContinue)){
 $latest=$null
 $logs=Get-ChildItem -LiteralPath 'C:\Users\kouji\AppData\Local\Roblox\logs' -Filter '*Studio*last.log' | Where-Object {$_.CreationTime -ge $started.AddSeconds(-2)}
 foreach($log in $logs){
  $stream=[IO.File]::Open($log.FullName,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
  $reader=New-Object IO.StreamReader($stream);$lines=$reader.ReadToEnd() -split "`n";$reader.Dispose()
  foreach($line in $lines){
   if($line.Length -lt 300 -and $line -match '^([0-9T:.\-]+Z),.*FOUR_CAPTURE (S[0-9]+)_Player[0-9]+_(Front|Side|Normal)'){
    $time=[datetime]::Parse($Matches[1]).ToUniversalTime()
    if(-not $latest -or $time -gt $latest.Time){$latest=@{Time=$time;Slug="$($Matches[2])_$($Matches[3])"}}
   }
  }
 }
 if($latest){
  $elapsed=([datetime]::UtcNow-$latest.Time).TotalSeconds
  $frame=if($elapsed -ge 2.8){2}else{1}
  if($elapsed -ge .7 -and $elapsed -lt 4.9){
   $clients=Get-CimInstance Win32_Process -Filter "Name='RobloxStudioBeta.exe'" | Where-Object {$_.CreationDate -ge $started -and $_.CommandLine -match 'StartClient' -and $_.CommandLine -match "-editpid $OwnedEditProcess "}
   foreach($client in $clients){
    $key="$($latest.Slug)_P$($client.ProcessId)_$frame"
    if($seen.ContainsKey($key)){continue}
    $windows=[System.Collections.Generic.List[object]]::new()
    $capturePid=$client.ProcessId
    $callback=[FourCapture+Visitor]{param($h,$d)
     $p=[uint32]0;[void][FourCapture]::GetWindowThreadProcessId($h,[ref]$p)
     if($p -eq $capturePid){$rect=New-Object FourCapture+Rect;[void][FourCapture]::GetWindowRect($h,[ref]$rect)
      if($rect.Right-$rect.Left -gt 500 -and $rect.Bottom-$rect.Top -gt 400){$windows.Add($h)}}
     return $true
    }
    [void][FourCapture]::EnumWindows($callback,[IntPtr]::Zero)
    if($windows.Count -gt 0){
     $handle=$windows[0]
     $rect=New-Object FourCapture+Rect;[void][FourCapture]::GetWindowRect($handle,[ref]$rect)
     $bitmap=New-Object Drawing.Bitmap(($rect.Right-$rect.Left),($rect.Bottom-$rect.Top));$graphics=[Drawing.Graphics]::FromImage($bitmap)
     $dc=$graphics.GetHdc()
     $captured=[FourCapture]::PrintWindow($handle,$dc,2)
     $graphics.ReleaseHdc($dc)
     if($captured){$bitmap.Save((Join-Path $folder "$key.jpg"),[Drawing.Imaging.ImageFormat]::Jpeg)}
     $graphics.Dispose();$bitmap.Dispose();$seen[$key]=$true
    }
   }
  }
 }
 Start-Sleep -Milliseconds 200
}
Write-Output "Captured $($seen.Count) images from owned client processes only."
