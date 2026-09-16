# World1 enemy Wall height alignment — 2026-09-16

## 変更

- 対象は`Workspace.GeneratedMap.BattleCorridor.Stage01〜Stage10.StageN.1〜.4.Wall`の40 Partのみ。
- 各Stageの既存`LeftWall` / `RightWall`を実測基準とし、敵Wallの上端を同じY=58.25へ揃えた。
- 敵Wall: Size `88 x 27 x 1.2` → `88 x 56.25 x 1.2`、Position Y `15.5` → `30.125`。
- 底面Y=2、幅88、厚さ1.2、X/Z、CFrame回転を維持。上方向だけ29.25 stud延長。
- 左右側面Wall、`Stage10BoundaryWall`、Gate、CombatZone、World2は変更なし。
- HP、RequiredStrength、Damage、Stage進行、Player Scale、Jumpは変更なし。

## UI

- `StageSurface`は敵Wallの子であり、新しいWall表面へ追従。Face=Front、CanvasSize=580x270を維持。
- MiniBoss用個人`SurfaceGui`も次Stage .1 WallをAdorneeにし、同じFace / CanvasSizeを再利用するため新しい壁面へ追従。

## Play確認

- 最大Muscle段階: Strength 15,370、HeightScale 3.5、Character BoundingBox高さ約8.42 stud。
- 未到達Stage10 .1 Wallへ前進＋連続Jumpしても、Wall Z=656.34に対してCharacter Z=654.95で停止し通過しなかった。
- 敵Wallと側面Wallはいずれも底面Y=2、上端Y=58.25。
- Stage1 .1 CombatZoneはSize 88x14x7、Position (27.92, 6, -23)のまま。
- Stage表示・Wall HPをPlay表示で確認。MiniBoss SurfaceGuiは高さ56.25の次WallをAdorneeとしてFace=Front / CanvasSize=580x270を維持。
- Runtime Error / Warning / Infinite Yieldなし。
