# CHANGELOG

## 2026-09-16 — Inventory通知を確認済み方式へ変更

- Dumbbell／Aura／Speedの「！」を、未購入である限り残る方式から、新しく解放された内容を対象タブで確認するまで残る方式へ変更。
- Itemsは新しく所有したItem IDを未確認として通知し、Itemsタブを開いた時点で確認済みにする。
- 親Inventory通知はDumbbells／Items／Aura／Speedの未確認状態の論理和とし、タブごとの独立性を維持。
- `InventoryNotificationSeen`をPlayerDataへ後方互換で追加。旧データは空の確認済み集合として読み込み、確認後は再Joinしても同じ通知を復活させない。
- 購入、Win消費、Robux購入、Equip、Merge、所有状態は変更なし。
- PlayでDumbbell／Aura／Speedの独立消去、購入なしでの消去、親通知の集約、再Join維持を確認。Runtime Error / Warning / Infinite Yieldなし（AssistantCommand由来の検証制約ログはゲーム実装外）。

確認できる日付・Phaseだけを記録する。実装を観測した日を、その機能の完成日とみなさない。

## 2026-09-15 — SPEC v1.0 / 文書整理
 
この初期整理の後に、同日の「World1後半の間隔・視認性調整」を実施。追記は次のセクションを参照。

- C:\Users\kouji\Smash_and_Crushをプロジェクトルートとして文書構造を整備。
- GAME_SPEC / BALANCE_SPEC / UI_SPEC / DEV_STATUS、AGENTS、READMEを作成。
- 現行Studioの読み取り専用監査を実施し、旧コメント・暫定値との不一致をKnown Issuesへ分離。
- World1後半レポートとbefore/after/evidenceをreports/World1_Stage6_10_20260915へ整理。37ファイルの移動前後SHA-256一致。
- Roblox Studioの実装・DataStore・Publishに変更なし。Git初期化・Commitなし。

根拠：[今回監査概要](../reports/Implementation_Audit_20260915/audit_summary.md)。

## 2026-09-15 — World1 Stage6〜10最終リバランス

既存報告に明記された作業日。細分Phase名は確認できないため補完しない。

- Stage6〜10のRequiredStrengthを9,000 / 25,000 / 60,000 / 130,000 / 250,000、推奨Lv30 / 35 / 40 / 45 / 50へ設定。
- Wallを適正Strengthの2 / 2.5 / 3 / 4倍、Bossを5倍へ設定。
- World1LateStageConfigとWallの有効値取得経路を追加。World2参照中の旧基準値は維持。
- Stage7〜10 Colliderを主要胴体へ調整。Stage6 Colliderと各DisplayHeightは維持。
- Stage6〜10 CombatZoneをColliderに合わせて設定。Stage1〜5を変更せず。
- 既存Carryを維持。Play実測は各StageでWall12攻撃、Boss5攻撃。4方向接触・離脱、UI切替、Stage進行、WorldCompleteを確認。
- 最終通常Playは記録上Error / Warning / Infinite Yield = 0 / 0 / 0。Publishなし。

根拠：[build_report](../reports/World1_Stage6_10_20260915/build_report.md)、[final_balance](../reports/World1_Stage6_10_20260915/final_balance.csv)。

## 実装済みだが実施日・Phaseが未確認の主要変更

以下は今回2026-09-15に実装を観測した事実。実際の制作日・順序を推測した履歴ではない。

| 変更 | 確認できる状態 | Phase情報 |
|---|---|---|
| World1 Map拡張 | GeneratedMapに10 Stage、Floor幅90、後半拡張 | 正確な拡張Phase未確認。古いGeneratedMap属性から推定しない |
| Stage6〜10 Boss差し替え | Pipi_KiwiからDragon Cannelloniまで5体 | 未確認 |
| RewardPad変更 | 黄色Neon Pad、TrophyRewardServiceと本人用表示 | 未確認 |
| Boss HP UI変更 | 名前・個人HP・Wall/Boss排他表示 | ユーザーの既存確定説明ではPhase C.5。実施日は未確認 |
| World2Gate | LOCKED/ENTERをPlayer別に表示 | 未確認 |
| HighestUnlockedWorld | 保存フィールド、Stage10 Pad取得によるWorld2解放 | 未確認 |
| World2 Map Graybox | World2Map、10 Stage、AuthoringOnly | 未確認 |

根拠：[GAME_SPEC](GAME_SPEC.md)、[UI_SPEC](UI_SPEC.md)、今回のSource/Object監査。将来日付・Phaseが証拠で判明したら、根拠を添えてこの区分から正式履歴へ移す。

## 2026-09-15 — World1後半の間隔・視認性調整

- Stage6〜10のEnemySpawnを+Zへ4 / 3.5 / 3.25 / 6 / 1stud後退。Wall .4、Floor、RewardPad位置は維持。
- EnemyManagerのStatic表示倍率の参照点を既存Boss Area Floorへ変更し、Spawn移動による自動縮小を防止。実Scale・DisplayHeight・Collider/CombatZone Sizeは前後一致。
- 歩行でのBoss戦開始/離脱/再接近/撃破、HP UI追従、床内収まり、Pad非干渉をPlay確認。Carry・Balance・Stage1〜5・World2は変更なし。
- Wall .4撃破後にBossが近すぎる問題をEnemySpawn後退で調整。Wall .4手前の低視点からBoss全体を見せることは要件ではなく、間隔調整は完了扱い。Map拡張/Wall形状変更は行わず停止。
- 一時テストコードを除去し、通常PlayのError/Warning/Infinite Yield=0/0/0。Publishなし。
- 根拠：[間隔・視認性レポート](../reports/World1_Stage6_10_Spacing_20260915/build_report.md)、[最終位置CSV](../reports/World1_Stage6_10_Spacing_20260915/final_spacing.csv)。GAME_SPEC/DEV_STATUSをv1.1へ追記。


## 2026-09-15 — World2 Balance / Inventory設計をSPECへ反映（文書のみ）

- World2 Stage1〜10の目標Boss HPを15M / 50M / 100M / 250M / 500M / 1B / 2.5B / 5B / 10B / 25Bに決定。
- 推奨Lvを60 / 75 / 90 / 105 / 120 / 140 / 155 / 170 / 185 / 200、RequiredStrengthを3M / 10M / 20M / 50M / 100M / 200M / 500M / 1B / 2B / 5Bとする設計を追加。
- Wall耐久は適正Strengthの2 / 2.5 / 3 / 4倍、Bossは5倍をWorld2でも採用する設計。
- World2到達時にWorld2専用Inventoryを解放する方針を追加。World1 ItemはWorld2でも装備可能・性能維持とし、World2 Itemを強くすることで相対的に弱くする。
- Lv201以降は一定のLevel上昇ルールを仮採用する方針。具体式・Strength増分は未確定。
- StudioのWorld2 Configは変更していない。旧×25,000値は要置換として残る。
- World1後半のBoss間隔調整について、低視点Wall越し視認は要件ではないことをSPEC/DEV_STATUSへ訂正。

## 2026-09-15 — World2独自BalanceのStudio Config反映

- 最新SPECの確定表をWorld2Config.Stagesへ反映。推奨Lv60〜200、RequiredStrength3M〜5B、Wall倍率2/2.5/3/4、Boss倍率5（15M〜25B）。
- World2BossConfig / World2WallConfigをWorld2Config参照へ変更。旧World2HPScaleは利用2箇所を置換して削除。World1へのrequire依存を除去。
- Playで459項目の設定・数値検証が合格。25BのAttributeをクライアントで受信し25B表示を確認。
- World1・Inventory・Map・UI・Level式・Carry・Gate等は変更なし。World2 Combat、移動、Stage進行は接続していない。
- Level式との不一致K16、短縮表示精度K17、旧メタデータK18を記録。新機能・Publish・Commitなし。
- DEV_STATUSを更新。README/GAME_SPEC/BALANCE_SPECは実装済み状態の表記だけ同期し、確定Balance表・Inventory方針は維持。
- 根拠：[World2 Balance報告](../reports/World2_Balance_20260915/build_report.md)、[最終値CSV](../reports/World2_Balance_20260915/final_balance.csv)。

## 2026-09-15 — Level Threshold Lv51〜200明示化・暫定延長

- 最新指示に従いLevelRequirementsのLv51〜200に150件の整数Thresholdを明示。全11アンカー（Lv50含む）一致、Lv1〜50の50値を完全維持。
- 単調3次Hermite補間を表生成時だけ使用し、1,000単位で丸めた確定リテラルを保存。実行時補間なし。
- Lv201以降は暫定で毎Level+250M、Lv201=5.25B、Lv10,000=2.455T。上限10,000と有限回二分探索を追加。
- StrengthDisplayの進捗計算1行を上限時100%へ対応。UIデザイン・短縮Formatterは維持。
- Play：全Level境界等70,335チェック、実HUD30ケース150チェックが合格。Strengthテスト属性はクライアント内で復元し、一時検証Scriptは除去。
- 検証コード除去後の通常Play約136秒でError/Warning/Infinite Yield=0/0/0。Stop後の変更前後比較で対象2 Source以外の変更なし。
- World1/World2 HP、RequiredStrength、RecommendedLevel、Item、Inventory、Rebirth、Map、Combat、Reward、Game Pass、DataStore Schemaは変更なし。Publish/Commitなし。
- BALANCE_SPECに全150値と暫定延長を明記、DEV_STATUS K16を解決、GAME_SPEC/READMEも現行Level方式へ同期。
- 根拠：[報告](../reports/Level_Curve_20260915/build_report.md)、[全150値CSV](../reports/Level_Curve_20260915/level_51_200_thresholds.csv)。

## 今後の追記形式

```text
## YYYY-MM-DD — 確認できるPhase / 変更名
- 変更した仕様と対象範囲
- 関連SPEC
- Audit / Implementation / Play Test / Regression Test結果
- 残存課題・未検証範囲
- 根拠レポートの相対リンク
```

## 2026-09-15 — LevelProgress方式へ移行

- Strengthを累積戦闘力、LevelProgressを現在Levelの獲得進捗、Requirementを現在Level→次Levelの必要量として分離。Lv1〜200の全値とLv201以降の暫定式は維持。
- PlayerDataServiceの共通付与でStrength/Level/Progressを同時更新。LevelProgressionを通常付与とTime Reward永続化で共有。余剰Carry・複数Level Upに対応。
- Level/LevelProgress/LevelProgressVersion=1を後方互換追加。旧データの従来Level・Strengthを維持しProgress0から開始。Rebirthは既存Strength0/Level1にProgress0を追加。
- HUD下段をProgress/現在Requirementへ変更。上段StrengthとUIデザイン・配置は維持。
- 隔離テスト30,049チェック合格。実Playerで旧データ移行、獲得・HUD・Carry・複数Level Up・専用Store再Join・UI経由Rebirth・歩行・Treadmillを確認。検証用ScriptとStore切替は撤去。
- GAME_SPEC/BALANCE_SPEC/UI_SPEC/DEV_STATUSを更新。World HP・RequiredStrength・RecommendedLevel・Item/Training/Potion/Game Pass倍率は変更なし。Publish/Commitなし。
- 根拠：[実装・検証報告](../reports/Level_Progress_20260915/build_report.md)。
## 2026-09-15 — World2 Gate移動確認UI

- `WorldTravelRequest`、`WorldTravelGui`を追加し、既存`WorldGateClient`へTrigger侵入・YES/NO・退出後再表示制御を追加。
- Serverは`HighestUnlockedWorld >= 2`とGate内滞在を再検証し、`World2LobbySpawn`基準で同一Characterを移動。`CurrentWorld=2`はセッションAttributeのみ。
- World2 Combat・Stage進行・DataStore Schema・Map・Balanceは変更なし。
## 2026-09-15 — World2からWorld1へのReturn Gate

- World2 TrainingAreaのBackWall手前右寄りへ独立`World1ReturnGate`を追加。Signは`WORLD 1` / `RETURN`。
- `WorldTravelGui`と`WorldTravelRequest`を往復で共有し、Serverは`ToWorld2` / `ReturnWorld1`だけを許可。CurrentWorld・Gate内滞在・Character生存を再検証する。
- `SpawnLocation` / `World2LobbySpawn`基準で同一Characterを移動。Map構造・Combat・DataStore Schema・Balanceは変更なし。

## 2026-09-15 — Production creator Game Pass effects switch

- StudioDebugConfigへProductionCreatorGamePassEffectsEnabled=falseと対象一覧ProductionCreatorUserIds={[7467238848]=true}を追加。
- 既存GamePassService.AreEffectsEnabled(player)へPlayer単位のProduction判定を集約。Studioは従来の全Player設定、Production一般Playerは常時有効、指定製作者だけ新設定へ従う。
- Starter/Secret Pack、VIP、Double Win、Premium Speed/Treadmill、Aura、Potion再適用の既存ガードへPlayerを渡した。所有表示とDeveloper Product、DataStore Schema、/resetdataは変更なし。
## 2026-09-16 — Rebalance World1 progression and cumulative Strength

- Lv1〜50のLevelRequirementsを新しい獲得量カーブへ更新。Lv51以降は維持。
- World1 Stage6〜10をRecommendedLevel到達時の累積Strengthへ同期し、Wall倍率2/2.5/3/4、Boss倍率5でHPを更新。
- Stage1〜5、World2、Strength獲得速度、LevelProgress処理、DataStore、UI、Combat仕様は変更なし。
## 2026-09-16 — Adjust Lv1-50 Strength requirements by 10

- Lv1〜50のRequirementを一律+10し、Lv1→Lv2に10 Strengthを要求。
- 新しい累積StrengthへWorld1 Stage6〜10を同期し、Wall/Boss倍率からHPを再計算。
- Lv51以降、Stage1〜5、World2、Strength獲得量、LevelProgress、DataStore、課金仕様は変更なし。
