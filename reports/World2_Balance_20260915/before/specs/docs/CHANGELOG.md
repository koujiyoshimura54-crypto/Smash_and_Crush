# CHANGELOG

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

## 今後の追記形式

```text
## YYYY-MM-DD — 確認できるPhase / 変更名
- 変更した仕様と対象範囲
- 関連SPEC
- Audit / Implementation / Play Test / Regression Test結果
- 残存課題・未検証範囲
- 根拠レポートの相対リンク
```
