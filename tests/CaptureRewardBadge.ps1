param([Parameter(Mandatory=$true)][string]$Label)
$ErrorActionPreference='Stop'
if($Label -notmatch '^[a-z0-9_-]+$'){throw 'Invalid capture label'}
$folder=Join-Path (Split-Path $PSScriptRoot -Parent) 'reports\RewardBadgeHalf_20261120\images'
New-Item -ItemType Directory -Force -Path $folder | Out-Null
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;using System.Runtime.InteropServices;
public static class RewardBadgeCapture {
 [StructLayout(LayoutKind.Sequential)]public struct Rect{public int Left,Top,Right,Bottom;}
 [DllImport("user32.dll")]public static extern bool GetWindowRect(IntPtr h,out Rect r);
 [DllImport("user32.dll")]public static extern bool PrintWindow(IntPtr h,IntPtr dc,uint flags);
}
'@
$studio=Get-Process RobloxStudioBeta | Where-Object {$_.MainWindowHandle -ne 0}
if(@($studio).Count -ne 1){throw 'Expected the single already-open Studio'}
$rect=New-Object RewardBadgeCapture+Rect
if(-not [RewardBadgeCapture]::GetWindowRect($studio.MainWindowHandle,[ref]$rect)){throw 'Window unavailable'}
$bitmap=New-Object Drawing.Bitmap(($rect.Right-$rect.Left),($rect.Bottom-$rect.Top))
$graphics=[Drawing.Graphics]::FromImage($bitmap)
$dc=$graphics.GetHdc()
$ok=[RewardBadgeCapture]::PrintWindow($studio.MainWindowHandle,$dc,2)
$graphics.ReleaseHdc($dc)
if(-not $ok){throw 'Capture failed'}
$path=Join-Path $folder ($Label+'.png')
$bitmap.Save($path,[Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose();$bitmap.Dispose()
Write-Output $path
