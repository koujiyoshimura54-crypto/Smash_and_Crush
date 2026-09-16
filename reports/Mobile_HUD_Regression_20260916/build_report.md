# Mobile / Tablet HUD regression fix

Date: 2026-09-16

## Root cause and change

- The restored standard `DynamicThumbstickFrame` is a large input-capture rectangle. `HUDLayout.GetControls` treated it as a visible physical control, reducing Smartphone LeftMenu scale from its normal responsive scale to about 0.18.
- `DynamicThumbstickFrame` is now excluded from HUD obstacle calculations. Visible Thumbstick parts and Jump remain available to the layout logic.
- Mobile Strength HUD no longer uses the LeftMenu/Jump lane or Tablet collision relocation for horizontal placement. It uses `AnchorPoint.X=0.5` and `Position.X.Scale=0.5`, relative to the full viewport.
- Tablet LeftMenu sizing and placement logic was not changed. Desktop retains its pre-existing non-touch branch.

## Measurements

| Target | Viewport Center X | Strength Center X before | Before delta | Strength Center X after | After delta | LeftMenu |
|---|---:|---:|---:|---:|---:|---|
| iPhone 17 Pro landscape | 374.5 | 328 | -46.5px | 374.5 | 0px | scale 0.18043 -> 0.41739; first button ~25.98 -> ~60.10px |
| Amazon Fire HD 10 landscape | 479.5 | 398 | -81.5px | 479.5 | 0px | unchanged: scale 0.423224; position 19,105; size 127.814x194.683px |

Dynamic Thumbstick sizes remained 399.6x302px and 483.6x460.67px respectively, with frame background transparency 1. Both StarterGui and PlayerGui remained `LandscapeSensor`. Desktop reported TouchEnabled=false and no TouchGui; its non-touch placement branch and AnchorPoint remain unchanged. Studio Output contained no Error, Warning, or Infinite Yield.
