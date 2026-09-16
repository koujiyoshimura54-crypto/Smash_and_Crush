# Mobile landscape / touch zone implementation

- `StarterGui.ScreenOrientation = LandscapeSensor`。Portrait専用UIは追加していない。
- Roblox標準`TouchGui.TouchControlFrame.DynamicThumbstickFrame`を生成するPlayerModuleと`DevTouchMovementMode=UserChoice`は維持し、LocalScriptは実行時Frameの矩形だけを調整する。
- Smartphone Landscape: `W=clamp(viewportW*0.40,220,300)`, `H=clamp(viewportH*0.58,190,260)`。
- Tablet Landscape: `W=clamp(viewportW*0.26,240,320)`, `H=clamp(viewportH*0.38,220,300)`。
- Zone左端は表示中の左側LeftMenu `GuiButton`右端+8px、右端はJumpButton左端-8px以内。表示中Interactive buttonとの実測overlapは0。
- Potion / Strength / HP等の表示HUDはZone回避対象から除外。Interactive UIだけを入力回避対象にする。
- iPhone 17 Pro相当: viewport 749x361、Zone 299x190、LandscapeLeft/Right共通、LeftMenu overlap=false。
- Fire HD 10相当: viewport 959x599、Zone 249x220、LeftMenu overlap=false、表示中Interactive overlap=0。
- iPad Pro 13相当: viewport 1374x1031、Zone 320x300（最大Clamp）。
- Desktop: TouchGuiなし、既存Mouse/KeyboardとHUD配置を維持。
- Play Output: Error / Warning / Infinite Yieldなし。
