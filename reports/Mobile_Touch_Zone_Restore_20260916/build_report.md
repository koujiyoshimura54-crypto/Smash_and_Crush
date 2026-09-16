# Mobile Touch Zone restoration

Date: 2026-09-16

## Change

- Removed the custom Smartphone and Tablet size calculations introduced by `b50eee5`.
- Removed maximum clamps, LeftMenu/Jump boundaries, viewport listeners, and UI safe-area repositioning from `TouchControlZoneClient`.
- Roblox PlayerModule now owns `DynamicThumbstickFrame` size and position again.
- The client forces only `DynamicThumbstickFrame.BackgroundTransparency` to `1`; child Thumbstick images and input behavior remain untouched.
- `StarterGui.ScreenOrientation` and runtime `PlayerGui.ScreenOrientation` remain `LandscapeSensor`.

## Runtime verification

| Target | Viewport | DynamicThumbstickFrame position | DynamicThumbstickFrame size | Background | Thumbstick children |
|---|---:|---:|---:|---:|---|
| iPhone 17 Pro landscape | 749x361 | -100, 101 | 399.6x302 | 1 | Start/End present, visible, ImageTransparency=0 |
| Fire HD 10 landscape | 959x599 | -100, 180.33 | 483.6x460.67 | 1 | Start/End present, visible, ImageTransparency=0 |
| Desktop | 1066x499 | n/a | n/a | n/a | TouchEnabled=false, TouchGui absent |

The measured mobile/tablet sizes are the standard PlayerModule values obtained with custom sizing disabled. Both mobile targets reported `LandscapeSensor` on StarterGui and PlayerGui. Desktop retained mouse/keyboard mode. Studio Output contained no Error, Warning, or Infinite Yield during these checks.

## Scope

No Combat, Balance, Stage, Inventory, DataStore, Map, Player Progression, HUD layout, or LandscapeSensor behavior was changed.
