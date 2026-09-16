# World1 MiniBoss → next Wall .1 UI transition — 2026-09-16

## 実装

- Combat順序は`Wall .1 → .2 → .3 → .4 → MiniBoss → 次Stage`のまま。
- Stage1〜9のMiniBoss用`PersonalGauge`は次Stage .1 WallをAdorneeとし、壁上端から4stud上へ表示する。
- 次Stage .1の`StageSurface`はPlayerごとの`PersonalStageDisplayEnabled`属性で制御する。
- 現在Stageが次Stageへ切り替わるまで、次Stage .1のStage表示とHPBarを隠す。
- `EnemyDefeated`受信時にクライアント表示上のStageを即座に次へ進め、同じ描画更新でBoss Gaugeを非表示、次Stage .1のStageSurfaceと満タンHPBarを表示する。
- Wall .2〜.4のHP表示は従来どおり対象Wall戦闘中のみ。
- Stage10は次Stage .1がないため従来のBoss BoundingBox上端表示へフォールバックする。

## Play確認

- Stage1開始：Stage1 .1 StageSurface/HP=`true`、Stage2/3 .1=`false`、HP=`100 / 100`。
- Wall進行中も将来Stage .1は非表示。
- MiniBoss GaugeのAdorneeが次Stage .1 WallであることをStage1→2、Stage2→3、Stage3→4の生成状態で確認。
- MiniBoss撃破後：次Stage .1 StageSurface/HP=`true`。次Wallへの接触前から満タンHPを表示。
- Boss HPは既存`BossGauge`イベントと`NumberFormat`を使用して更新。
- PlayerごとのLocalScriptと個人CombatStateだけを使用し、共有Workspace UIをサーバー一括変更していない。
- Runtime Error / Warning / Infinite Yieldは0件。

## 変更ソース

- `StarterPlayer.StarterPlayerScripts.Combat.CombatClient`
- `StarterPlayer.StarterPlayerScripts.Combat.StageWallDisplayClient`

変更後ソースは`sources/`へ保存した。
