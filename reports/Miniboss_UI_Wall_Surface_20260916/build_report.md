# MiniBoss UI placement on next Wall .1 — 2026-09-16

## 実装

- Stage1〜9の既存Boss Gauge一式を、次Stage .1 Wall上空のBillboardからWall表面の`SurfaceGui`へ変更。
- 次Stage .1の既存`StageSurface`から`Adornee`となるWall、`Face`、`SizingMode`、`CanvasSize`、`PixelsPerStud`、`LightInfluence`、`AlwaysOnTop`、`MaxDistance`、`ZOffset`を再利用。
- Boss名、`STAGE N`、HP Bar、Current / Max HPの既存デザイン・更新処理は維持。
- MiniBoss戦中は通常`StageSurface`とWall HPを隠し、撃破通知と同じ描画更新でSurface Boss Gaugeを消して次Stage .1表示と満タンHPを表示。
- Stage10は次Stage .1 Wallがないため、従来のBoss追従`BillboardGui`を維持。
- Stage進行、Combat順序、Damage、HP、Balance、Map、DataStoreは変更なし。

## Play確認

- Stage1 .1〜.4を通過してStage1 MiniBossへ進行。
- MiniBoss戦中: Stage2 .1 `StageSurface=false`、Wall HP=false、`PersonalGauge=SurfaceGui`、Adornee=Stage2 .1 Wall、Face=Front、CanvasSize=580x270。
- 表示内容: `Ballerina Cappuccina`、`STAGE 1`、HP `149 / 250`。Damageに伴うリアルタイム更新を確認。
- 撃破直後: Boss Gauge消去、Stage2 .1 `StageSurface=true`、Wall HP=true、接触前から`300 / 300`。
- Stage2〜9は同じ`n<10`共通経路でSurfaceGui、Stage10はBillboardGui。
- Runtime Error / Warning / Infinite Yieldなし。
