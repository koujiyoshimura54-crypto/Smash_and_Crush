# World2 Balance更新報告
日付: 2026-09-15 / Studio: +1 スマッシュ&クラッシュ / PlaceId: 101572058398926

## 範囲と結果
最新指示および `C:\Users\kouji\Smash_and_Crush\Smash_and_Crush_updated_20260915` のAGENTS/README/5 SPECを全文確認。World2の独自Balanceのみ反映した。現在StudioはEdit。Publish・Git Commitは行っていない。新しいPlaceファイルの保存・Exportはしていない。

## 実際に確認した最終値
| Stage | 推奨Lv | RequiredStrength | Wall .1 | Wall .2 | Wall .3 | Wall .4 | Boss HP |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 60 | 3,000,000 | 6,000,000 | 7,500,000 | 9,000,000 | 12,000,000 | 15,000,000 |
| 2 | 75 | 10,000,000 | 20,000,000 | 25,000,000 | 30,000,000 | 40,000,000 | 50,000,000 |
| 3 | 90 | 20,000,000 | 40,000,000 | 50,000,000 | 60,000,000 | 80,000,000 | 100,000,000 |
| 4 | 105 | 50,000,000 | 100,000,000 | 125,000,000 | 150,000,000 | 200,000,000 | 250,000,000 |
| 5 | 120 | 100,000,000 | 200,000,000 | 250,000,000 | 300,000,000 | 400,000,000 | 500,000,000 |
| 6 | 140 | 200,000,000 | 400,000,000 | 500,000,000 | 600,000,000 | 800,000,000 | 1,000,000,000 |
| 7 | 155 | 500,000,000 | 1,000,000,000 | 1,250,000,000 | 1,500,000,000 | 2,000,000,000 | 2,500,000,000 |
| 8 | 170 | 1,000,000,000 | 2,000,000,000 | 2,500,000,000 | 3,000,000,000 | 4,000,000,000 | 5,000,000,000 |
| 9 | 185 | 2,000,000,000 | 4,000,000,000 | 5,000,000,000 | 6,000,000,000 | 8,000,000,000 | 10,000,000,000 |
| 10 | 200 | 5,000,000,000 | 10,000,000,000 | 12,500,000,000 | 15,000,000,000 | 20,000,000,000 | 25,000,000,000 |

## 変更したConfigと正本
- `ReplicatedStorage.Config.World2Config`: `Stages[1..10]` がWorld2数値の正本。各行にRecommendedLevel、RequiredStrength、Walls、BossMaxHPを保持。RequiredStrengthStatus=Configured。入れ子を含めfreeze。
- `ReplicatedStorage.Config.World2BossConfig`: World2ConfigのBoss HP / RequiredStrength / RecommendedLevelを取得する参照用Config。既存MaxHP表・GetMaxHP・GetRequiredStrengthの入口を維持し、GetRecommendedLevelを追加。
- `ServerScriptService.Config.World2WallConfig`: World2ConfigのWallsを参照。既存の数値Stage索引/Walls/GetMaxHPの入口を維持。
- 旧World2HPScaleは削除。383本のSourceを検索し、利用はBoss/Wall Configの2箇所のみだった。両方を置換後、最終検索で残るのは削除理由のコメントだけ。World1BossConfigとStage1WallManagerへのWorld2側requireを除去。
- SourceWorldId=1はGraybox由来のメタデータとして保持し、Balanceには使用しない。
- World2MapのWall/PlaceholderはHP数値を直接持たず、HPConfigパスで上記Configを参照する。MapやPlaceholderにCombat用HP・Humanoidを新設していない。

## 数値型・HP表示
Luau numberは64bit double。[Roblox公式Numbers資料](https://create.roblox.com/docs/luau/numbers)参照。25,000,000,000は連続整数を正確に表せる範囲2^53以内。今回の設定値・倍率はすべて整数結果として保持できる。

Playで各StageのConfig、Attribute往復、JSON往復、整数文字列往復、HPを1減算して戻す操作、5回分の適正Strength減算を検証。25BのAttributeがServer→Clientで完全一致し、クライアントFormatterも25Bを返す。既存のWall/Boss Damage計算はnumberの加減算とmath.min/max、Strengthは有限numberを保持し、対象経路に32bit整数化・bit32/buffer整数化・2^31上限制限は見つからなかった。HPラベルはNumberFormat、バーはCurrent/Max比率を使用する。DataStore Schemaは変更していない。World2実戦/保存を接続した試験ではない。

| 入力 | 現行NumberFormat実測 |
|---:|---|
| 15,000,000 | 15M |
| 500,000,000 | 500M |
| 1,000,000,000 | 1B |
| 2,500,000,000 | 2.5B |
| 25,000,000,000 | 25B |
| 1,250,000,000 | 1.2B |

指定例15M/500M/1B/2.5B/25Bは正常。**1.25Bは現行1桁精度により1.2Bへ丸められる**（内部HPは1,250,000,000のまま）。短縮値をHPへ逆変換する処理は追加していない。表示精度を増やすかはK17に記録し、Formatter・UIデザインは変更しない。

## Levelカーブの不一致（未修正）
| Stage | 推奨Lv | そのLvのStrength閾値 | 設定RequiredStrength | そのStrengthの実Lv |
|---:|---:|---:|---:|---:|
| 1 | 60 | 260,800 | 3,000,000 | 527 |
| 2 | 75 | 280,750 | 10,000,000 | 989 |
| 3 | 90 | 305,200 | 20,000,000 | 1,407 |
| 4 | 105 | 334,150 | 50,000,000 | 2,232 |
| 5 | 120 | 367,600 | 100,000,000 | 3,159 |
| 6 | 140 | 419,200 | 200,000,000 | 4,470 |
| 7 | 155 | 463,150 | 500,000,000 | 7,070 |
| 8 | 170 | 511,600 | 1,000,000,000 | 9,999 |
| 9 | 185 | 564,550 | 2,000,000,000 | 14,142 |
| 10 | 200 | 622,000 | 5,000,000,000 | 22,361 |

RecommendedLevelは指定どおり設定したが、現行LevelRequirementsのLv51以降二次式とは全Stageで不一致。**Lv200で5Bに到達する育成仕様が完成したという意味ではない。** 今回Level/Strength式を変更しない指示に従い維持。Lv201以降の新しい式も実装していない。

## Audit / Play / Regression
- 変更前: [Config Source](before/config_sources.json)、[全Source・対象Object指紋](before/fingerprints.json)、[参照・属性監査](before/reference_audit.json)を保存。
- 検証Play: [Server結果](evidence/server_probe.json)で459チェック合格。10 Stageの全設定値、両参照Config、無効Stageのnil、安全性・Formatterを検証。
- [Client結果](evidence/client_probe.json): 25BのAttribute受信と25B表示が一致。
- Boss5HitはConfigからの**算術確認**。World2 Combat・Carry・進行は未接続のため、実戦や攻撃回数を実測したとは扱わない。
- World1 Stage1〜10の有効値をRuntimeで読み取り、既存SPEC表と一致。変更前後383本の指紋で変更は3 Configのみ。Source削除なし。
- 全World1 Map（EnemySpawn位置含む）、EnemyTemplates（Collider含む）、World2Map、World2Gate、UI、LevelRequirementsの前後指紋一致。Inventory/Item/Reward/課金/Rebirth/Carry/Combat/保存のScriptは変更なし。
- World2MapはAuthoringOnly、実行時Humanoid 0。StageProgressControllerはGeneratedMapのみを初期化し、World2の移動・Combat・Stage進行を接続していない。
- 一時Server/Client検証Scriptを除去後の通常Play: **約124秒、Error 0 / Warning 0 / Infinite Yield 0**。Consoleは空。正常にPlayer Characterが生成され、CurrentStage=1。Stop後の指紋も変更後と一致。
- Runtime結果は上記観測時間とConfig検証範囲に限る。World2戦闘の合格結果ではない。

## SPEC同期
- DEV_STATUS.md: Config完了、次タスク、K09更新、K16(Level)/K17(表示精度)/K18(旧メタデータ)を記録。
- CHANGELOG.md: 今回の監査・実装・検証を追加。
- README.md / GAME_SPEC.md / BALANCE_SPEC.md: 「Studio未反映」等の実装状況のみ同期。既存の確定Balance表・Inventory方針を維持。
- AGENTS.md / UI_SPEC.mdは変更なし。旧監査・過去履歴の記載は当時の記録として保持。

## 残存事項・今回進めていない機能
1. K16: World2推奨Lvと現行育成カーブの差。別Phaseで判断が必要。
2. K17: 1.25B等の短縮表示精度。
3. K18: World2 Placeholder 10体のRequiredStrengthStatus=Pendingは旧メタデータ。Boss Model変更禁止のため維持した。World1側にも旧World2参照コメントが残るが、World1変更禁止のため維持。実際の正本はWorld2Config.Stages。
4. World2 Inventoryは到達時解放、World1 ItemはWorld2でも性能維持で装備可能、World2 Itemを強くする方針をSPECで確認した。今回は実装・変更しない。
5. 移動、Combat、Stage進行、Enemy差し替え、RewardPad、Stage Skip、CurrentWorld本格運用には進んでいない。

## 保存物
- build_report.md / final_balance.csv / level_curve_check.csv
- before/: 変更前Config、指紋、参照・属性監査、更新前SPECの内容
- after/: 変更後3 ConfigのSource、最終指紋、差分概要
- evidence/: Server/Client検証結果、通常Play Console、再現用検証Script（Studioには残していない）

Sourceアーカイブは変更箇所の証拠であり、完全なPlaceバックアップではない。
