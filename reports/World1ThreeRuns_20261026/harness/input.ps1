param([int]$X,[int]$Y,[int]$Clicks=1,[int]$Scroll=0)
Add-Type -TypeDefinition 'using System;using System.Runtime.InteropServices;public class NightInput{[StructLayout(LayoutKind.Sequential)]public struct Rect{public int L,T,R,B;}[StructLayout(LayoutKind.Sequential)]public struct Point{public int X,Y;}[DllImport("user32.dll")]public static extern bool GetWindowRect(IntPtr h,out Rect r);[DllImport("user32.dll")]public static extern IntPtr WindowFromPoint(Point p);[DllImport("user32.dll")]public static extern IntPtr GetAncestor(IntPtr h,uint f);[DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);[DllImport("user32.dll")]public static extern void mouse_event(uint f,uint x,uint y,uint d,UIntPtr e);[DllImport("user32.dll")]public static extern IntPtr GetForegroundWindow();[DllImport("user32.dll")]public static extern bool SetForegroundWindow(IntPtr h);}'
$studio=(Get-Process RobloxStudioBeta | Where-Object MainWindowHandle -NE 0 | Select-Object -First 1)
if (-not $studio) { throw 'Studio window unavailable' }
[NightInput]::SetForegroundWindow($studio.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 150
if ([NightInput]::GetForegroundWindow() -NE $studio.MainWindowHandle) {
 # Activate through a normal click on the visible Studio title bar. Never click an occluding app.
 $r=New-Object NightInput+Rect
 [NightInput]::GetWindowRect($studio.MainWindowHandle,[ref]$r) | Out-Null
 $point=New-Object NightInput+Point;$point.X=$r.L+500;$point.Y=$r.T+20
 $atPoint=[NightInput]::GetAncestor([NightInput]::WindowFromPoint($point),2)
 if ($atPoint -NE $studio.MainWindowHandle) { throw 'Studio title bar is occluded; no input sent' }
 [NightInput]::SetCursorPos($point.X,$point.Y) | Out-Null
 [NightInput]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
 Start-Sleep -Milliseconds 75
 [NightInput]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
 Start-Sleep -Milliseconds 200
}
if ([NightInput]::GetForegroundWindow() -NE $studio.MainWindowHandle) { throw 'Studio is not foreground; no game input sent' }
[NightInput]::SetCursorPos($X,$Y) | Out-Null
if ($Scroll -NE 0) {
 for ($i=0;$i -lt [Math]::Abs($Scroll);$i++) {
  $wheel=[BitConverter]::ToUInt32([BitConverter]::GetBytes([int](120*[Math]::Sign($Scroll))),0)
  [NightInput]::mouse_event(0x0800,0,0,$wheel,[UIntPtr]::Zero)
  Start-Sleep -Milliseconds 90
 }
} else {
 for ($i=0;$i -lt $Clicks;$i++) {
  [NightInput]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
  Start-Sleep -Milliseconds 75
  [NightInput]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
  Start-Sleep -Milliseconds 150
 }
}
