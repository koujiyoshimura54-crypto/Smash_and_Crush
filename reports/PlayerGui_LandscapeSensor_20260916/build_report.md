# PlayerGui LandscapeSensor runtime application — 2026-09-16

- 既存`TouchControlZoneClient`でLocalPlayerの`PlayerGui`取得直後に`PlayerGui.ScreenOrientation=LandscapeSensor`を設定。
- `StarterGui.ScreenOrientation=LandscapeSensor`を維持。左右Landscapeを許可し、Portrait警告UIは追加していない。
- iPhone 17 Pro相当: StarterGui / PlayerGuiともLandscapeSensor、既存Zone 299x190。
- Fire HD 10相当: StarterGui / PlayerGuiともLandscapeSensor、既存Zone 249x220。
- Desktop: PlayerGuiはLandscapeSensor、TouchGuiなし。Mouse / Keyboard経路に変更なし。
- Touch Zone計算、Clamp、HUDLayout、Combat、Balance、Stage、Data、Mapは変更なし。
- Runtime Error / Warning / Infinite Yieldなし。
