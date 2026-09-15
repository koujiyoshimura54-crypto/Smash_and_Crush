# LevelProgress方式への移行 — 2026-09-15

対象PlaceId: 101572058398926。最新AGENTS/GAME_SPEC/BALANCE_SPEC/UI_SPEC/DEV_STATUSを確認して実装。
Publish・Git Commit・World2機能接続・Item/Training等のバランス調整は行っていない。

## 最終仕様
- Strength：現在の成長サイクルの累積戦闘力。Level Upでは消費しない。生涯ランキングのTotalStrengthEarnedとは別。
- LevelProgress：現在Levelからの獲得進捗。Requirementを消費した余剰を保持する。
- LevelRequirement：現在Levelから次Levelへの必要獲得量。LevelRequirementsの数値・暫定式は維持。
- 獲得後、現在Requirementを順に消費してLevelを増やす。余剰Carry、複数Level Upに対応。
- Lv1 Requirement=0を維持。Join/移行/Rebirthでは自動加算せず、最初の正の獲得で0を消費してLv2へ進む。
- 上限10,000は維持。上限以降もStrengthとProgressを保持し、HUDバーは従来どおり100%。
- /setstrength等の管理用絶対値変更は獲得ではないためLevel/Progressを変更しない。

## 付与経路監査と変更
歩行TrainingController → StrengthManager.AddStrength。
Treadmill TrainingManager → StrengthManager.AddStrength。
Item・Dumbbell・Aura・Rebirth・Potion・VIP等の最終倍率は従来どおりStrengthManager内で計算。
Time Rewardは通常Training相当量を算出 → durable Claim → AddRewardStrength。
すべてcommitGain → PlayerDataService.AddStrengthGain → LevelProgression.ApplyGainへ収束。
各機能にLevelProgress加算を複製していない。ランキング加算も一度だけ実行する。

Time Rewardの保存前snapshotにもLevel/Progressを追加し、永続化には同じ純粋関数を使用。
既存ItemMutationId・Resolving排他を維持。永続化成功後のローカル反映は共通付与経路で一度だけ。
通常SaveはLevel/Progressをsnapshotとして保存するが、完了時に古いsnapshotをlive状態へ戻さない。

## 保存と旧データ
追加：Level、LevelProgress、LevelProgressVersion=1。
新規：Level1 / Progress0。
旧Levelフィールドがあれば維持。旧仕様の通常データにはLevelが保存されていないため、
変更していない旧Threshold検索で従来Levelを一度復元し、Progress0を設定する。
以後はLevel/Progressを独立保存し、Strengthから逆算しない。
未知Version、不正Level/Progress、不完全な新形式はLoadを拒否し、壊れた値で上書きしない。
Production PlayerData_v1 / Studio PlayerData_v1_Studio、ResetToken、Receipt/ItemMutation、
Win/Rebirth/Inventory/HighestUnlockedWorld等の既存保存項目を維持。

## Rebirth / Combat / HUD
- Rebirth判定は保存Levelを使う。既存Strength0/Level1にProgress0の同時リセットを追加。
- Win/Items/World解放、Rebirth条件・倍率は変更なし。
- BossのPlayerLevel情報だけを保存Level参照へ変更。Damage/Ratio/Lotteryは累積Strengthのまま。
- WallのDamage経路は未変更。
- StrengthLevelHUD.Strengthは累積Strength。下段はLevelProgress / 現在Requirement。
- 更新はStrength/Level/LevelProgress Attributeイベント。HUDLayout、Size、Position、Formatterは未変更。
- CalculateLevelの旧検索は移行および旧テスト互換として残す。通常のLevel/Rebirth/Boss情報/HUDは参照しない。

## 検証結果
|確認|結果|
|---|---|
|Lv1〜10,000のRequirement出力前後比較|10,000件一致|
|全Level境界・Carry・移行・保存競合・Reward再試行等|30,049チェック合格|
|旧データ移行|Strength3Mを保持、従来Lv60、Progress0。Win/Inventory/World解放保持|
|実Player +500K|Strength3.5M、Lv60、500K / 3M、バー1/6|
|さらに+2.5M|Strength6M、Lv61、Progress0|
|大量獲得|Strength13,075,123、Lv63、余剰Progress123|
|専用StoreへのSave→Stop→Play再Join|Strength10,575,123 / Lv62 / Progress1,224,123を完全復元|
|実UIによるRebirth|Strength1・保存Lv10でも判定成功。Strength0/Lv1/Progress0、Win77/World2解放保持|
|実歩行|Strength4.5 / Lv2 / Progress4.5。最終獲得量の同量反映|
|実Treadmill|Strength12→18、Progress12→18。以後Level Up/Carryも正常|
|Boss.Begin/Attack|BattleStartStrengthと通常Damageが累積Strength/Gloveを使用することを確認|
|Time Reward再試行|曖昧な保存結果、並行獲得、再ResolveでもStrength/Progress二重付与なし|
|最終通常Play|約156秒、Error/Warning/Infinite Yield=0/0/0|

保存試験は専用LevelProgressCheck_20260915_01_Studioを使用。Production/通常StudioのPlayer記録へテスト値を書き込んでいない。
専用Storeへの一時切替と検証Script/Moduleは撤去。最終Playは通常設定に復元した状態。
初期検証ではツールのSource/Player作成/Remote権限制限と、検証コマンドのSave待ち不足があった。
検証構成を修正し、Rebirthは実UIで操作。上表は修正後の結果。
本番課金・旧仕様サーバーとの同時稼働・実機/Device Emulatorは未確認。
UIデザインは変更していない。

## 変更一覧
新規：
- ReplicatedStorage.Modules.LevelProgression

変更：
- ServerScriptService.Services.PlayerDataService
- ServerScriptService.Services.StrengthManager
- ServerScriptService.Systems.Controllers.StrengthController
- ServerScriptService.Systems.Controllers.RebirthService
- ServerScriptService.World.BossCombatService（PlayerLevel参照のみ）
- ServerScriptService.Systems.Debug.StudioDebugService（Level表示参照のみ）
- StarterGui.StrengthGui.StrengthDisplay
- ReplicatedStorage.Config.LevelRequirements（意味・移行用途のコメントのみ。数値/式は不変）

Source指紋比較で上記以外の既存Script変更・削除なし。Map/UI Instance形状・配置への変更なし。
既存Legacy/Testを削除していない。今回作成した一時検証Objectのみ撤去した。
before/afterは今回の記録で、過去レポートの証拠は変更していない。

更新SPEC：
GAME_SPEC v1.2、BALANCE_SPEC v1.3、UI_SPEC v1.1、DEV_STATUS v1.3、CHANGELOG。

詳細検証値：[evidence.json](evidence.json)。

