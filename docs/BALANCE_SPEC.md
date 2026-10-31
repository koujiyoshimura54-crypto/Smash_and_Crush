# BALANCE_SPEC — ゲームバランス正本

## 2026-10-31 — Approved World2 HP and variable wall counts

This table supersedes earlier World2 Boss/wall values and four-wall assumptions. M=1,000,000; B=1,000,000,000. World2GameplayConfig owns the values; World2Config and World2BossConfig expose them. RequiredStrength remains Boss HP / 5 as information only, without entry restrictions or a mandatory hit count.

| Stage | Boss HP | Wall1 | Wall2 | Wall3 | Wall4 | Wall5 | Wall6 |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 15M | 6M | 7.5M | 9M | 10.5M | 12M | — |
| 2 | 30M | 12M | 15M | 18M | 21M | 24M | — |
| 3 | 75M | 30M | 37.5M | 45M | 52.5M | 60M | — |
| 4 | 150M | 60M | 75M | 90M | 105M | 120M | — |
| 5 | 500M | 200M | 250M | 300M | 350M | 400M | — |
| 6 | 1B | 400M | 500M | 600M | 700M | 800M | 900M |
| 7 | 5B | 2B | 2.5B | 3B | 3.5B | 4B | 4.5B |
| 8 | 15B | 6B | 7.5B | 9B | 10.5B | 12B | 13.5B |
| 9 | 45B | 18B | 22.5B | 27B | 31.5B | 36B | 40.5B |
| 10 | 150B | 60B | 75B | 90B | 105B | 120B | 135B |

Stages1–5 have five walls; Stages6–10 have six, totaling55. Carry propagates across all walls within the Stage and is discarded at the Boss boundary. Win rewards, drops, prices, equipment, Treadmill, Rebirth, World1 values and all Boss motion/attack tuning remain unchanged. The 3.5T/70B/140B proposals are superseded by this table. These focused prepared tests establish no three-hour completion-time claim. See [implementation and verification](../reports/World2HPWalls_20261031/README.md).

## 2026-10-28 — Approved World1 HP and Dumbbell values

This table supersedes earlier World1 Boss/Wall and NORMAL dumbbell values below. Current unsaved Studio is authoritative. Boss HP retains RequiredStrength × 5; RequiredStrength is a calculation reference, not a new entry gate or enforced hit count. Stage1–4 are preserved; Stage5 uses fixed walls; Stage6–10 walls are 40/50/60/80% of Boss HP. Combat, Win rewards, intervals, movement and World2 remain unchanged.

| Stage | Boss HP | Wall1 | Wall2 | Wall3 | Wall4 |
|---|---:|---:|---:|---:|---:|
| 1 | 375 | 100 | 125 | 150 | 200 |
| 2 | 2250 | 300 | 325 | 350 | 425 |
| 3 | 12500 | 600 | 750 | 900 | 1200 |
| 4 | 30000 | 3000 | 3750 | 4500 | 6000 |
| 5 | 75000 | 7000 | 8750 | 10500 | 14000 |
| 6 | 190000 | 76000 | 95000 | 114000 | 152000 |
| 7 | 410000 | 164000 | 205000 | 246000 | 328000 |
| 8 | 990000 | 396000 | 495000 | 594000 | 792000 |
| 9 | 1800000 | 720000 | 900000 | 1080000 | 1440000 |
| 10 | 5000000 | 2000000 | 2500000 | 3000000 | 4000000 |

| NORMAL grade | Strength addition | Purchase Win | Sale Win | Merge points |
|---|---:|---:|---:|---:|
| 1 | 1 | 5 | 3 | 5 |
| 2 | 3 | 20 | 10 | 20 |
| 3 | 5 | 50 | 25 | 40 |
| 4 | 7 | 100 | 50 | 70 |
| 5 | 10 | 150 | 75 | 110 |
| 6 | 15 | 400 | 200 | 160 |
| 7 | 25 | 750 | 375 | 220 |
| 8 | 35 | 1250 | 625 | 290 |
| 9 | 50 | 2000 | 1000 | 370 |
| 10 | 65 | 3500 | 1750 | 450 |
| 11 | 85 | 5000 | 2500 | 530 |
| 12 | 100 | 7500 | 3750 | 650 |

Only PriceWin / SellWin / StrengthBonus change in DumbbellItemMaster. Existing IDs, images, Grade, owned quantities, equipped IDs, saved schema, merge thresholds and World2 definitions remain. Existing owned dumbbells use these current effects/prices. Ore points/drops/sales/RNG and Item/Aura/Pet/Treadmill/Rebirth/payment values are unchanged. See reports/World1Balance_20261028 for actual verification; no predicted clear time is established by these tables.

## 2026-10-17 - Provisional World1 Stage5-10 Boss and Wall HP

This owner-approved provisional balance supersedes earlier World1 HP tables and the Stage1-5 fixed-wall rule below. `ReplicatedStorage.Config.World1BossConfig` remains the only authority. Preserve Stage1-4 exactly as found in CurrentCloud/5bf7d96; Stage5 now joins Stage6-10 in deriving four walls from RequiredStrength times 2 / 2.5 / 3 / 4. Boss HP remains RequiredStrength times 5. Future tuning should edit this Config, not duplicate HP tables in consumers.

| Stage | RequiredStrength | Wall1 | Wall2 | Wall3 | Wall4 | Boss HP |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 75 | 100 | 125 | 150 | 200 | 375 |
| 2 | 450 | 300 | 325 | 350 | 425 | 2,250 |
| 3 | 2,500 | 600 | 750 | 900 | 1,200 | 12,500 |
| 4 | 6,000 | 3,000 | 3,750 | 4,500 | 6,000 | 30,000 |
| 5 | 20,000 | 40,000 | 50,000 | 60,000 | 80,000 | 100,000 |
| 6 | 100,000 | 200,000 | 250,000 | 300,000 | 400,000 | 500,000 |
| 7 | 700,000 | 1,400,000 | 1,750,000 | 2,100,000 | 2,800,000 | 3,500,000 |
| 8 | 3,000,000 | 6,000,000 | 7,500,000 | 9,000,000 | 12,000,000 | 15,000,000 |
| 9 | 15,000,000 | 30,000,000 | 37,500,000 | 45,000,000 | 60,000,000 | 75,000,000 |
| 10 | 50,000,000 | 100,000,000 | 125,000,000 | 150,000,000 | 200,000,000 | 250,000,000 |

Wall order is progression1 through4. RequiredStrength is the unmodified five-hit Boss damage benchmark, not a forced hit count. Preserve real Strength/Glove damage, wall-to-wall surplus and discarded surplus after Wall4. RecommendedLevels, unlocks, Rebirth, all Win rewards and World2 remain unchanged. Existing NumberFormat handles new labels, including 3.5M / 37.5M / 125M / 250M, with its existing rounding policy.

Evidence: actual Source simulation and native Studio EditFile loading, detailed in DEV_STATUS. Cloud gameplay and total progression duration were not measured. No assertion that this balance achieves 30-60 minutes.

## 2026-10-01 — Inventory Capacity tiers 5→12

- InventoryCapacityConfigのUpgradesを拡張。5→6: 5 Win、6→7: 15 Win、7→8: 30 Win、8→9: 75 Win、9→10: 150 Win、10→11: 1,000 Win、11→12: 4,500 Win。12の次段階は未設定でMAX。下記Phase 5Gの100 Win設定を置き換える。

## 2026-09-30 — Inventory Capacity (Phase 5G)

- 初期Capacity 5 → 購入後6、仮価格100 Win。正本は`ReplicatedStorage.Config.InventoryCapacityConfig`のDefaultCapacity / Upgrades。6→7以降は未設定。Boss Drop / Rarity / その他の購入価格は未変更。

## 2026-09-19 — World1 upgrade economy V1

World1の新規無課金Player向けに、購入判断を残しつつ序盤からUpgradeへ到達できる価格帯へ変更した。設計目標は完全最適30～32分、標準40～45分、非最適50～55分であり、実Play計測前の目標値である。

| Dumbbell Grade | Training Strength Bonus | Win Price |
|---:|---:|---:|
| 1 | 2 | 5 |
| 2 | 4 | 15 |
| 3 | 8 | 40 |
| 4 | 25 | 100 |
| 5 | 60 | 250 |
| 6 | 150 | 600 |
| 7 | 300 | 1,500 |

| Aura | Strength Bonus | Win Price |
|---|---:|---:|
| Pink | 10 | 25 |
| Purple | 20 | 75 |
| Yellow | 40 | 200 |
| Green | 150 | 500 |
| Blue | 350 | 1,250 |

通常ItemのWin価格はCommon 75、Uncommon 200、Rare 600。Epic / LegendaryはRobux購入を維持する。Studio正本のItem効果値（Protein 1 / 15 / 30 / 50 / 150、Glove 5% / 10% / 20% / 35% / 50%、Belt 0.25 / 0.5 / 1 / 1.5 / 2）は変更しない。Red Aura +1000、VIP / Secret Aura、Rebirth、Treadmill、World1 Stage値、Boss Drop 20%、Time Rewards、Element Set ×1.5も変更しない。

15分Time Rewardは引き続き新しいDumbbell / Aura値を正本として、通常Training 15秒相当の式を使う。45分RewardはItem Roll ×10を維持する。

Version: 1.4 / 監査・更新日: 2026-09-16

## 読み方・参照元

初期監査の静的導出・過去Play記録と、今回の検証を区別する。2026-09-16のConfig統合では、統合前後のPlayサーバーからWorld1/World2全Stageの数値を取得し、同一のサービス検証520項目が完全一致した。過去表を根拠に現在Runtimeの数値を変更しない。

**World1BossConfig = World1 Stage1〜10の唯一のBalance正本**。`ReplicatedStorage.Config.World1BossConfig`のRequiredStrength / RecommendedLevels / GetMaxHP / GetWallConfigを参照する。`Stage1WallManager.Config`とGetStageConfigは同じ設定を返す互換窓口。旧後半Configは全Runtime参照移行・Play一致確認後に削除済み。World2はWorld2Config.Stagesを独立した正本とし、World1への依存はない。

根拠: [Config統合・Play検証報告](../reports/World1_Config_Consolidation_20260916/build_report.md)、[統合後World1BossConfig](../reports/World1_Config_Consolidation_20260916/sources/ReplicatedStorage.Config.World1BossConfig.luau)、[全Stage数値CSV](../reports/World1_Config_Consolidation_20260916/final_balance.csv)。過去reportsのSnapshotは当時の履歴として保持する。

## World1 Stage1〜10：Historical 2026-09-16 values (superseded above)

| Stage | 推奨Lv | RequiredStrength | Wall .1 | Wall .2 | Wall .3 | Wall .4 | Boss MaxHP | Pad基本Win |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 8 | 50 | 100 | 125 | 150 | 200 | 250 | 1 |
| 2 | 10 | 100 | 300 | 325 | 350 | 425 | 500 | 3 |
| 3 | 15 | 450 | 600 | 750 | 900 | 1,200 | 2,250 | 5 |
| 4 | 20 | 2,000 | 3,000 | 3,750 | 4,500 | 6,000 | 10,000 | 10 |
| 5 | 25 | 5,000 | 7,000 | 8,750 | 10,500 | 14,000 | 25,000 | 30 |
| 6 | 30 | 37,315 | 74,630 | 93,287.5 | 111,945 | 149,260 | 186,575 | 75 |
| 7 | 35 | 81,865 | 163,730 | 204,662.5 | 245,595 | 327,460 | 409,325 | 150 |
| 8 | 40 | 196,915 | 393,830 | 492,287.5 | 590,745 | 787,660 | 984,575 | 300 |
| 9 | 45 | 462,965 | 925,930 | 1,157,412.5 | 1,388,895 | 1,851,860 | 2,314,825 | 750 |
| 10 | 50 | 1,018,015 | 2,036,030 | 2,545,037.5 | 3,054,045 | 4,072,060 | 5,090,075 | 1,000 |

**確定設計：Stage6〜10は推奨Lv30 / 35 / 40 / 45 / 50。Stage10をLv50前後でクリアできる戦闘耐久。** RequiredStrengthちょうどではWall倍率2.0 / 2.5 / 3.0 / 4.0、Boss倍率5.0。これは個別HP設計であり、Carry込み実攻撃回数を整数倍率へ丸める設計ではない。Lv50までの育成所要時間は今回計測していない。

Stage1〜5のWallは上表の固定HPをそのまま維持する。**Stage2は3 / 3.25 / 3.5 / 4.25倍（300 / 325 / 350 / 425）**。Stage3〜5のRequiredStrengthは今回のPlayで450 / 2,000 / 5,000を確認し、ユーザー指示によりこの現行値を維持したため、Wallを一律の倍率で再生成しない。全StageのBoss MaxHPはRequiredStrength×5。旧SPECの300 / 1,500 / 3,500は現在Runtimeと異なっていたため記述だけを訂正し、Balance自体は変更していない。Win表は今回変更していない。

WinはBoss撃破時の即時付与ではなく、本人が黄色RewardPadを取得した際の基本値。有効World1 DoubleWinならfloor(基本Win×2)。他のDaily/Time等のWinすべてにDoubleWinを掛ける仕様ではない。

根拠: [ReplicatedStorage.Config.TrophyRewardConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.TrophyRewardConfig.luau)、[ServerScriptService.Services.TrophyRewardService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.TrophyRewardService.luau)。

## Level / Strengthカーブ

2026-09-15に意味を変更：以下の各値は**そのLevelから次Levelへ進むための獲得量**。累積戦闘Strengthの到達Thresholdではない。全数値を維持し、LevelとLevelProgressを独立保存する。Strength・Progressとも小数を保持する。

| Lv | Strength | Lv | Strength | Lv | Strength | Lv | Strength | Lv | Strength |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 10 | 11 | 330 | 21 | 1,760 | 31 | 7,510 | 41 | 45,010 |
| 2 | 30 | 12 | 375 | 22 | 2,010 | 32 | 9,010 | 42 | 52,010 |
| 3 | 50 | 13 | 420 | 23 | 2,260 | 33 | 10,010 | 43 | 60,010 |
| 4 | 70 | 14 | 470 | 24 | 2,510 | 34 | 12,010 | 44 | 69,010 |
| 5 | 90 | 15 | 535 | 25 | 3,010 | 35 | 15,010 | 45 | 80,010 |
| 6 | 125 | 16 | 610 | 26 | 3,510 | 36 | 18,010 | 46 | 95,010 |
| 7 | 155 | 17 | 760 | 27 | 4,010 | 37 | 22,010 | 47 | 105,010 |
| 8 | 190 | 18 | 1,110 | 28 | 4,510 | 38 | 27,010 | 48 | 125,010 |
| 9 | 235 | 19 | 1,360 | 29 | 5,010 | 39 | 33,010 | 49 | 150,010 |
| 10 | 290 | 20 | 1,510 | 30 | 6,010 | 40 | 40,010 | 50 | 200,010 |

Lv1〜50の既存50値は完全維持。**Lv51〜200は各Levelに明示的な整数Requirementが存在する**。正本は `ReplicatedStorage.Config.LevelRequirements.LevelStrengthRequirements`（既存 `FixedStrength` と同じfreeze済み表）。Lv1〜200の200行を数値リテラルで保持し、実行時補間は行わない。

### Lv51〜200：全Requirement（旧表の数値維持）
以下は以前のThreshold表の作成履歴であり、今回再計算はしていない。指定アンカー間を単調3次Hermite補間で作成し、1,000単位へ四捨五入。内部アンカーの傾きは隣接区間の加重調和平均。Lv50の開始傾きは28,000（既存Lv49→50の差）、Lv200の終端傾きは250Mとして暫定延長に接続した。補間は表作成時のみ使用する。丸め後も全Levelで厳密増加し、11アンカーは完全一致。中間値は育成時間の実測前の仮バランス。

| Lv | 必要Strength | Lv | 必要Strength | Lv | 必要Strength |
|---:|---:|---:|---:|---:|---:|
| 51 | 319,000 | 101 | 40,142,000 | 151 | 400,042,000 |
| 52 | 463,000 | 102 | 42,560,000 | 152 | 424,753,000 |
| 53 | 671,000 | 103 | 45,018,000 | 153 | 449,770,000 |
| 54 | 932,000 | 104 | 47,502,000 | 154 | 474,912,000 |
| 55 | 1,235,000 | 105 | 50,000,000 | 155 | 500,000,000 |
| 56 | 1,569,000 | 106 | 52,568,000 | 156 | 525,383,000 |
| 57 | 1,924,000 | 107 | 55,269,000 | 157 | 551,580,000 |
| 58 | 2,287,000 | 108 | 58,098,000 | 158 | 578,667,000 |
| 59 | 2,650,000 | 109 | 61,049,000 | 159 | 606,716,000 |
| 60 | 3,000,000 | 110 | 64,116,000 | 160 | 635,802,000 |
| 61 | 3,351,000 | 111 | 67,294,000 | 161 | 666,000,000 |
| 62 | 3,724,000 | 112 | 70,578,000 | 162 | 697,383,000 |
| 63 | 4,118,000 | 113 | 73,963,000 | 163 | 730,025,000 |
| 64 | 4,530,000 | 114 | 77,442,000 | 164 | 764,000,000 |
| 65 | 4,961,000 | 115 | 81,010,000 | 165 | 799,383,000 |
| 66 | 5,408,000 | 116 | 84,662,000 | 166 | 836,247,000 |
| 67 | 5,871,000 | 117 | 88,392,000 | 167 | 874,667,000 |
| 68 | 6,349,000 | 118 | 92,196,000 | 168 | 914,716,000 |
| 69 | 6,840,000 | 119 | 96,067,000 | 169 | 956,469,000 |
| 70 | 7,343,000 | 120 | 100,000,000 | 170 | 1,000,000,000 |
| 71 | 7,857,000 | 121 | 103,910,000 | 171 | 1,045,235,000 |
| 72 | 8,381,000 | 122 | 107,737,000 | 172 | 1,092,247,000 |
| 73 | 8,914,000 | 123 | 111,513,000 | 173 | 1,141,333,000 |
| 74 | 9,454,000 | 124 | 115,273,000 | 174 | 1,192,790,000 |
| 75 | 10,000,000 | 125 | 119,048,000 | 175 | 1,246,914,000 |
| 76 | 10,543,000 | 126 | 122,873,000 | 176 | 1,304,000,000 |
| 77 | 11,080,000 | 127 | 126,779,000 | 177 | 1,364,346,000 |
| 78 | 11,614,000 | 128 | 130,800,000 | 178 | 1,428,247,000 |
| 79 | 12,153,000 | 129 | 134,968,000 | 179 | 1,496,000,000 |
| 80 | 12,702,000 | 130 | 139,317,000 | 180 | 1,567,901,000 |
| 81 | 13,266,000 | 131 | 143,880,000 | 181 | 1,644,247,000 |
| 82 | 13,852,000 | 132 | 148,690,000 | 182 | 1,725,333,000 |
| 83 | 14,465,000 | 133 | 153,779,000 | 183 | 1,811,457,000 |
| 84 | 15,111,000 | 134 | 159,181,000 | 184 | 1,902,914,000 |
| 85 | 15,795,000 | 135 | 164,928,000 | 185 | 2,000,000,000 |
| 86 | 16,524,000 | 136 | 171,053,000 | 186 | 2,109,778,000 |
| 87 | 17,304,000 | 137 | 177,591,000 | 187 | 2,238,222,000 |
| 88 | 18,139,000 | 138 | 184,572,000 | 188 | 2,384,000,000 |
| 89 | 19,036,000 | 139 | 192,031,000 | 189 | 2,545,778,000 |
| 90 | 20,000,000 | 140 | 200,000,000 | 190 | 2,722,222,000 |
| 91 | 21,098,000 | 141 | 209,441,000 | 191 | 2,912,000,000 |
| 92 | 22,382,000 | 142 | 221,171,000 | 192 | 3,113,778,000 |
| 93 | 23,840,000 | 143 | 235,012,000 | 193 | 3,326,222,000 |
| 94 | 25,458,000 | 144 | 250,782,000 | 194 | 3,548,000,000 |
| 95 | 27,222,000 | 145 | 268,301,000 | 195 | 3,777,778,000 |
| 96 | 29,120,000 | 146 | 287,388,000 | 196 | 4,014,222,000 |
| 97 | 31,138,000 | 147 | 307,864,000 | 197 | 4,256,000,000 |
| 98 | 33,262,000 | 148 | 329,548,000 | 198 | 4,501,778,000 |
| 99 | 35,480,000 | 149 | 352,259,000 | 199 | 4,750,222,000 |
| 100 | 37,778,000 | 150 | 375,817,000 | 200 | 5,000,000,000 |

全値のCSV: [Lv51〜200](../reports/Level_Curve_20260915/level_51_200_thresholds.csv)。[検証報告](../reports/Level_Curve_20260915/build_report.md)。

### Lv201〜10,000：暫定ルール
**暫定**：`Requirement(Lv) = 5,000,000,000 + (Lv - 200) × 250,000,000`。1Levelごとに一定の250M増加。将来のWorld/Itemバランスとして確定した値ではない。

- Lv199=4,750,222,000 → Lv200=5,000,000,000 → Lv201=5,250,000,000。
- Lv10,000=2,455,000,000,000（2.455T）。すべて2^53以内で整数として正確に保持できる。
- Level上限=10,000。LevelProgression.Advanceは現在Requirementを順に消費し、最大でも上限までの有限回で停止する。上限到達後もStrengthと余剰Progressは保持。HUDバーは従来どおり上限時100%。
- GetRequiredStrengthの値・clamp・暫定式は変更していない。通常HUDはLevelProgress / GetRequiredStrength(Level)を表示する。Lv1の0 Requirementは除算せず0%表示し、最初の正の獲得時に次Levelへ進む。
- 非有限・負のProgress/獲得量は拒否。旧データのLevel復元だけにCalculateLevelを使用し、通常進行・Rebirth判定・BossのPlayerLevel表示には使用しない。
- 保存項目はLevel、LevelProgress、LevelProgressVersion=1。旧保存Levelがない場合のみ旧Strength Thresholdから従来Levelを一度復元し、Progress=0を設定する。以後、Strengthだけの管理用絶対値変更ではLevel/Progressを変更しない。

### 旧Threshold方式での比較（履歴）
次の比較は移行前の記録。新方式では同じ累積StrengthからLevelを特定できず、推奨Levelと戦闘Strengthの到達速度は今後検証・調整する。Boss/Wall/RequiredStrength/RecommendedLevelの数値は今回は変更していない。


| Stage | 推奨Lv | RequiredStrength | そのStrengthの実Lv | 推奨Lv到達に必要なStrength | 整合 |
|---|---:|---:|---:|---:|---|
| 1 | 8 | 50 | 3 | 180 | 仕様不一致・要確認 K02 |
| 2 | 10 | 100 | 5 | 280 | 仕様不一致・要確認 K02 |
| 3 | 15 | 300 | 10 | 525 | 仕様不一致・要確認 K02 |
| 4 | 20 | 1,500 | 20 | 1,500 | 一致 |
| 5 | 25 | 3,500 | 25 | 3,500 | 一致 |
| 6 | 30 | 9,000 | 30 | 9,000 | 一致 |
| 7 | 35 | 25,000 | 35 | 25,000 | 一致 |
| 8 | 40 | 60,000 | 40 | 60,000 | 一致 |
| 9 | 45 | 130,000 | 45 | 130,000 | 一致 |
| 10 | 50 | 250,000 | 50 | 250,000 | 一致 |

上表は旧方式の履歴。新方式の正本はLevelProgressionと現在のLevelRequirementsであり、この比較を新規Playerの到達Level予測には使用しない。Requirementの表は変更していない。

## Step / Training / 倍率の適用順

基礎値BaseGain=1、歩行間隔0.5秒、Training間隔0.5秒。Stepは歩行時間tickで、距離あたりの歩数ではない。歩行可能な状態でMoveDirection>0.05または水平速度>0.5を判定する。Training・戦闘・Treadmill内・死亡時に歩行分を重複付与しない。

1 tickの現在式：

```text
歩行Strength =
  (1 + AuraBonus + ProteinBonus)
  × RebirthMultiplier × StrengthPotionMultiplier × VIPMultiplier

TrainingStrength =
  (1 + DumbbellBonus + AuraBonus + ProteinBonus)
  × RebirthMultiplier
  × (TreadmillTier + TrainingBeltBonus + TrainingPotionBonus)
  × StrengthPotionMultiplier × VIPMultiplier
```

TrainingBeltとTrainingPotionはTreadmill倍率へ加算。独立の乗算ではない。歩行にはDumbbell・Belt・Treadmill・TrainingPotionを使わない。複数tickをまとめて処理しても加算装備分はtickごと。小数を切り捨てない。

Time Rewardの「通常Training15秒分」は `(1+Dumbbell+Aura+Protein)×Rebirth×30tick`。Belt、機器Tier、Potion、VIPを含まない基準値を直接付与し、再度倍率を掛けない。

根拠: [ReplicatedStorage.Config.TrainingConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.TrainingConfig.luau)、[ServerScriptService.Services.StrengthManager](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.StrengthManager.luau)、[ServerScriptService.Systems.Controllers.TrainingController](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Systems.Controllers.TrainingController.luau)、[ServerScriptService.Services.TimeRewardService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.TimeRewardService.luau)。

### Treadmill

| 機器 | Type名 | 必要Rebirth / 権利 | Tier倍率 | 状態 |
|---|---|---|---:|---|
| Tredmill01 | Premium | Administrator Treadmill、GamePassId=1982996954 | 20 | Server所有確認済みのみ利用可 |
| Tredmill02〜03 | Rebirth7 | **5** | 3 | 実装済み、Type名と条件が不一致 |
| Tredmill04〜05 | Rebirth3 | 3 | 2 | 実装済み |
| Tredmill06〜10 | Normal | 0 | 1 | 実装済み |

Zone監視は0.2秒。Objectに残るTickInterval=1 / StrengthPerTick=1は現行tickの参照元ではない。上記TrainingConfigが実行時の値（K05）。Rebirth7という名前から必要回数7を推定しない（K06）。

根拠: [ReplicatedStorage.Config.TreadmillConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.TreadmillConfig.luau)、[ServerScriptService.Services.TrainingManager](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.TrainingManager.luau)。

### Rebirth

World1MaxRebirth=5。RebirthCountを増やし、既存のStrength=0／Level=1を維持。新設LevelProgressも同じサイクルで0へ戻す。Win・Inventory・HighestUnlockedWorldは維持。

| 現在回数 | 次回必要Lv | 現在のStrength倍率 |
|---|---:|---:|
| 0 | 10 | 1 |
| 1 | 15 | 1.5 |
| 2 | 22 | 2 |
| 3 | 30 | 2.5 |
| 4 | 45 | 3 |
| 5 | World1では上限 | 3.5 |

以下は定義のみある将来用データで、World2解放仕様が確定した意味ではない。

- R6〜R30必要Lv：40, 50, 36, 38, 40, 45, 50, 300, 400, 500, 600, 750, 900, 1000, 1250, 1500, 2000, 2500, 3000, 4000, 5000, 6000, 7500, 9000, 10000。
- 回数6〜30の倍率：4, 4.5, 5, 6, 7, 8, 9, 10, 12, 14, 16, 18, 20, 25, 30, 45, 60, 75, 90, 100, 120, 150, 200, 250, 300。

根拠: [ReplicatedStorage.Config.RebirthConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.RebirthConfig.luau)、[ReplicatedStorage.Config.RebirthMultiplierConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.RebirthMultiplierConfig.luau)。

## 装備・購入・Merge

### 通常Item

各種類Protein / Glove / TrainingBelt、属性Fire / Ice / Electric、5 Rarityで合計45定義。属性は効果倍率を変えない。各種類1つ装備。Mergeは同じItemId×3 → 同種・同属性の次Rarity×1、Legendary不可。

| Rarity | Protein加算 | Glove Boss Damage加算率 | Belt Tier加算 | Win購入価格 |
|---|---:|---:|---:|---:|
| Common | 1 | 5% | 0.25 | 100 |
| Uncommon | 15 | 10% | 0.5 | 300 |
| Rare | 40 | 20% | 1 | 1,000 |
| Epic | 100 | 35% | 1.5 | Robux商品 |
| Legendary | 250 | 50% | 2 | Robux商品 |

根拠: [ReplicatedStorage.Config.ItemMaster](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.ItemMaster.luau)、[ReplicatedStorage.Config.ItemMultiplierConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.ItemMultiplierConfig.luau)、[ReplicatedStorage.Config.ItemMergeConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.ItemMergeConfig.luau)。

### Dumbbell / Aura / Speed

| Dumbbell Grade / ID末尾 | Win価格 | Training基礎加算 |
|---|---:|---:|
| 1 / NORMAL_01 | 5 | 1 |
| 2 / NORMAL_02 | 20 | 3 |
| 3 / NORMAL_03 | 50 | 5 |
| 4 / NORMAL_04 | 150 | 10 |
| 5 / NORMAL_05 | 400 | 15 |
| 6 / NORMAL_06 | 2,000 | 50 |
| 7 / NORMAL_07 | 7,500 | 100 |

Dumbbellは所有booleanと1装備枠。定義のMergeable=trueに対応するDumbbell Merge実装は確認できない（K07）。

| Aura | Strength基礎加算 | 購入 |
|---|---:|---|
| Pink | 10 | 250 Win |
| Purple | 25 | 750 Win |
| Yellow | 50 | 2,500 Win |
| Green | 100 | 7,500 Win |
| Blue | 200 | 20,000 Win |
| Red | 1,000 | Pass 1975173075 |
| VIP / Secret | 0 | 各Shop権利 |

Auraは同時1つ。VIP/Secret Aura自体のStrength加算は0。VIP Passの1.1倍率と混同しない。

Speed：Default WalkSpeed24、通常購入500 Winで32、Premium Passで40。速度を変えてもStep基礎tick間隔は0.5秒。

根拠: [ReplicatedStorage.Config.DumbbellItemMaster](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.DumbbellItemMaster.luau)、[ReplicatedStorage.Config.AuraConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.AuraConfig.luau)、[ReplicatedStorage.Config.SpeedConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.SpeedConfig.luau)。

## Boss Combat / Hit設計 / Carry

2026-09-30 Phase 4：World1のStrength不足時の抽選・5Hit強制決着を撤廃。World2の既存ルールは変更していない。旧Lottery表/APIはWorld2互換用として残るが、World1 Begin/Attackは使用しない。

自動攻撃間隔0.8秒、手動Boss攻撃Cooldown 0.5秒、攻撃アニメーション時間0.6秒、Wall自動hit適用遅延0.18秒、Boss自動hit遅延0.5秒、手動hitは受付時に即適用、接触監視0.1秒。予約済み自動Hit直後に手動Hitが成立する既知の約0.017秒問題は未修正。

Wallダメージは現在Strength（Gloveなし）。World1 Bossは全Strength帯で遭遇開始時Strength×(1+既存Glove加算率)をHPから引く。Gloveは一度だけ適用し、RequiredStrengthへのDamage Clampや新しい上限は追加しない。RequiredStrengthはGlove・Carryなしで約5Hit撃破する推奨値であり、参加制限ではない。MaxHP=RequiredStrength×5を維持する。

World1はHP<=0で勝利。5Hit後もBossが生存していれば6Hit以降へ継続し、事前に勝敗を計画しない。同Run内の遭遇Strength・Glove・HP保持は従来どおり。Player死亡時はPhase 3のリセットを維持する。

2026-09-30追加修正：壁余剰でBoss HP<=0になる場合は壁Damage処理内で即撃破し、次のPlayer Attackを待たない。HPが残る場合だけ従来のCombatへ進む。通常Attack・壁余剰・Combat開始時のHP0検知は同じDefeatedガード付き撃破処理を使用し、正式Combat前の撃破でも生存Playerは全回復する。[即撃破検証](../reports/World1_Immediate_Boss_Defeat_20260930/README.md)。

Phase 3のBoss攻撃25 Damage / 1秒間隔、Player HP100、戦闘終了時全回復は未変更。Stage01の今回PlayではGlove・Carryなしで、Strength 75 / 60 / 45 / 112.5に対しDamage同値、MaxHP375、撃破5 / 7 / 9 / 4Hit。60%の9Hit勝利は位置を制御してBoss初撃をMISSさせた条件。近距離では8Hit後、Boss4撃目で死亡した。詳細：[Phase 4検証](../reports/World1_Phase4_20260930/README.md)。

**Wall余剰は次WallへCarryし、Wall4からBossへもCarryする。現在実装済みだがBossへのCarryを今後維持するかは要検討（K03）。** Bossを常に満タンから開始する仕様ではない。

既存2026-09-15 Playでは、RequiredStrengthちょうど・Glove補正0、Wall1から連続進行した各Stageの実測が次のとおり。

| Stage | Wall1〜4実攻撃 | Boss開始HP | MaxHP比 | Boss実攻撃 |
|---|---:|---:|---:|---:|
| 6 | 12 | 40,500 | 90% | 5 |
| 7 | 12 | 112,500 | 90% | 5 |
| 8 | 12 | 270,000 | 90% | 5 |
| 9 | 12 | 585,000 | 90% | 5 |
| 10 | 12 | 1,125,000 | 90% | 5 |

Wall合計=11.5×RequiredStrengthのため12回目に0.5×RequiredStrengthが残る。このケースのBoss開始HPは4.5×RequiredStrength。別Strength・装備・開始状態では結果が変わる。実測に合わせたHP再変更は行っていない。

根拠: [ServerScriptService.World.BossCombatService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.World.BossCombatService.luau)、[ServerScriptService.World.EnemyManager](../reports/Implementation_Audit_20260915/sources/ServerScriptService.World.EnemyManager.luau)、[既存実測CSV](../reports/World1_Stage6_10_20260915/final_balance.csv)。

## Bossモデル / Collider / CombatZone

SizeはローカルXYZ、stud。回転した箱のSizeはワールドBBox寸法ではない。Boss ScaleとDisplayHeightを勝手に変更しない。

| Stage | Boss Name | DisplayHeight | CollisionReference Size | Refローカル位置 | Y回転 | CombatZone Size |
|---|---|---:|---|---|---:|---|
| 6 | Pipi_Kiwi | 36 | 18 × 34 × 36 | (0,13,2) | 0° | 22 × 14 × 40 |
| 7 | Trippi Troppi | 48 | 18 × 44 × 44 | (0,18,0) | 150° | 22 × 14 × 48 |
| 8 | Chimpanzini Bananini | 44 | 32 × 44 × 30 | (0,18,0) | 0° | 36 × 14 × 34 |
| 9 | Trippa Troppa Tralala Lirilì Rilà TungTung Sahur Boneca TungTung Tralalelo TrippiTroppa Crocodina | 56 | 28 × 52 × 14 | (0,22,0) | 0° | 32 × 14 × 18 |
| 10 | Dragon Cannelloni | 52 | 28 × 46 × 32 | (0,19,0) | -30° | 32 × 14 × 36 |

Stage6 Colliderは前回維持、Stage7〜10は主要胴体基準へ調整済み。羽・尻尾等の全BBoxを覆わない。Stage6〜10 ZoneはColliderと同じ水平中心・回転、XZを各合計4stud拡張、高さ14、底面をFloor上面へ合わせる。Stage1〜5は既存10×14×16、Root基準Z=-5のまま。

前回Playで5 Stage×4方向の接触・戦闘開始・離脱20件を確認。Collider底面=Floor上面Y=2。これは過去の検証記録であり、新規Avatar寸法や多人数で無条件に保証するものではない。

## Item Drop / Rarity

Boss撃破ごとにItemHitChance=20%、MISS=80%。1 Player / Run / Stageにつき1回。Rarity基本重みCommon80 / Uncommon13 / Rare4 / Epic2 / Legendary1。EpicはStage5、LegendaryはStage8で解放。種類・属性は各3択均等。

| 現在Stage | ITEMが出た場合のRarity分布 |
|---|---|
| 1〜4 | Common80/97、Uncommon13/97、Rare4/97 |
| 5〜7 | Common80/99、Uncommon13/99、Rare4/99、Epic2/99 |
| 8〜10 | Common80%、Uncommon13%、Rare4%、Epic2%、Legendary1% |

Boss撃破1回あたりの各Rarity確率は上表×20%。個別ItemIdはさらに種類・属性の9通りで等分。

Daily/Time/Community Item報酬はMISSなしだが、**受取時CurrentStage**の解放Rarityで再正規化。最高到達Stage基準ではない。Day7重みは50/25/15/8/2に変わるが同じStage制限が残る（K08）。Secret Packは別のEpic+専用抽選。

## Daily / Time / Potion / Community

| Daily日数 | 報酬 |
|---|---|
| 1 | 1 Win |
| 2 | Strength Potion ×1 |
| 3 | 3 Win |
| 4 | ItemRoll ×10 |
| 5 | Training Potion ×1 |
| 6 | 5 Win |
| 7 | ItemRoll ×10、重み50/25/15/8/2 |

UTCで1日1つ、7段階は一度きり。VIPは別枠でUTC日次1 Win。

| Time ID | 累積オンライン秒 | 報酬 |
|---|---:|---|
| 01 | 60 | 1 Win |
| 02 | 120 | Training Potion 60秒 |
| 03 | 300 | 3 Win |
| 04 | 420 | Strength Potion 180秒 |
| 05 | 600 | 10 Win |
| 06 | 900 | 通常Training15秒相当Strength |
| 07 | 1,200 | Training Potion 180秒 |
| 08 | 1,800 | 25 Win |
| 09 | 2,700 | ItemRoll ×10 |

累積時間・取得状況は保存、2700秒で蓄積上限。前の報酬のClaimを次の必須条件にしない。オフライン経過を通常の時間加算に用いない。

Strength Potionは×1.5、Training Potionは機器Tierへ+1、標準180秒。同種の追加は時間延長、倍率の重複乗算ではない。Time02だけ60秒。Shop Packは期限の保存・復元があり、通常Potionのセッションタイマーとは異なる。

Community：GroupId787332211、加入確認後に一度だけ3 Win＋ItemRoll1。根拠: [ReplicatedStorage.Config.TimeRewardConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.TimeRewardConfig.luau)、[ReplicatedStorage.Config.DailyRewardConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.DailyRewardConfig.luau)、[ReplicatedStorage.Config.CommunityRewardConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.CommunityRewardConfig.luau)。

## Game Pass / Developer Product / Stage Skip

以下ID・効果はStudio内の設定。Roblox側の現在価格・販売状態を外部照合した表ではない。

| Game Pass | ID | 効果 |
|---|---:|---|
| World1 DoubleWin | 1970515086 | World1 Pad Win×2 |
| Starter Pack | 1976228285 | 一度100 Win＋Strength/Training Potion各1（即時180秒） |
| Secret Pack | 1977086287 | 一度500 Win＋Secret Aura＋Epic以上Item1 |
| VIP | 1977128286 | 歩行・Training×1.1、VIP Aura/Tag、UTC日次1 Win |
| Premium Speed | 1979583273 | WalkSpeed40、Fallback100 Robux |
| Red Aura | 1975173075 | 装備時基礎Strength+1,000、Fallback100 Robux |
| Premium Treadmill | 1982996954 | Administrator Treadmill。Tier20 |

Secret PackはEpic:Legendary=2:1、各Rarity内9 Item均等、MISSなし。PolicyServiceのPaidRandomAllowed判定経路を持つ。

StudioDebugConfig.GamePassEffectsEnabled=false / ForceSpeedPremiumUnowned=false。Studioで所有していても課金効果は検証用ゲートで抑制される。これを本番効果なしと解釈しない。今回切替はしていない（K11）。

| Developer Product | ID | Config Fallback価格 |
|---|---:|---:|
| 選択Epic Item | 3711755218 | 25 Robux |
| 選択Legendary Item | 3711755280 | 50 Robux |

通常Item購入はKind/Element選択のIntentに対応した付与。WinProductsは空で購入未設定。UnconfirmedWinProductId=3711615649は付与量未確認の未使用ID。

| Skip先 | Win価格 | ProductId | Fallback Robux |
|---|---:|---:|---:|
| 2 | 1 | 3711531641 | 10 |
| 3 | 2 | 3711531688 | 20 |
| 4 | 3 | 3711533318 | 30 |
| 5 | 4 | 3711533363 | 40 |
| 6 | 5 | 3711533407 | 50 |
| 7 | 6 | 3711533440 | 60 |
| 8 | 7 | 3711533493 | 70 |
| 9 | 8 | 3711533535 | 80 |
| 10 | 9 | 3711533573 | 90 |

Stage SkipはLobby内・非戦闘時のみ。指定StageのWall1から開始し、飛ばしたStageはSkipped。過去Stageの撃破報酬を自動付与しない。Remote要求間隔0.4秒。実売価格はMarketplace取得値を優先し、Fallbackは代替表示に限る。

根拠: [ReplicatedStorage.Config.StageSkipConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.StageSkipConfig.luau)、[ReplicatedStorage.Config.DeveloperProductConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.DeveloperProductConfig.luau)、[ReplicatedStorage.Config.ShopProductConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.ShopProductConfig.luau)、[ReplicatedStorage.Config.WorldPassConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.WorldPassConfig.luau)、[ServerScriptService.Config.StudioDebugConfig](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Config.StudioDebugConfig.luau)。

## World2：Studio現行値と今後採用する設計

### 旧暫定値（2026-09-15に置換済み）

変更前のWorld2 HP Configは、World1後半再バランス前の旧基準×25,000で作られた値だった。現在は下表の独自Balanceへ置換済み。World2MapはAuthoringOnlyでCombat/Stage進行に未接続。**この旧値を今後のBalance正本として使用しない。**

### World2確定設計（Config反映済み・Combat未接続）

World2はStage10を**Lv200前後でクリア**する設計とする。Bossは適正Strengthの5倍、WallはWorld1後半と同じく .1=2倍 / .2=2.5倍 / .3=3倍 / .4=4倍を基準とする。

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

World2 Itemは別設計とし、World2専用InventoryをWorld2到達時に解放する。World1 ItemはWorld2でも装備可能で、性能値はWorld移動によって弱体化しない。World2 ItemをWorld2のStrength帯に合わせて強くするため、World1 Itemは相対的に弱くなる。

Lv201以降は**暫定実装**としてLv200=5Bを起点に毎Level+250M、上限Lv10,000を採用。詳細は上記Level節。将来のWorld2 Item/育成時間確認後に再調整する。

2026-09-15：下表の確定値をReplicatedStorage.Config.World2Config.Stagesへ反映。World2BossConfig / World2WallConfigはその参照用Config。World2HPScaleは参照2箇所の置換後に削除済み。World1値は変更していない。その後同日のLevelカーブ更新により、World2全10 StageのRecommendedLevelとRequiredStrengthがThreshold上で完全一致した（K16解決）。育成時間の妥当性・World2 Combat完成を意味しない。[検証報告](../reports/World2_Balance_20260915/build_report.md)。

## その他の数値と変更時の注意

MuscleScaleConfig now uses the approved thirteen-stage table in the2026-10-20 section below. That section supersedes the old ten-stage summary; existing part growth proportions and excluded parts are retained.

保存・課金の永続仕様は[GAME_SPEC](GAME_SPEC.md)、表示倍率は[UI_SPEC](UI_SPEC.md)、未確定事項は[DEV_STATUS](DEV_STATUS.md)。Balance変更時は有効参照元とWorld2への依存を監査し、実装変更・Play実測・回帰結果を区別して本書を更新する。

## 2026-09-15 — Level進行の意味変更

上記200個の表値・Lv201以降の式は完全維持。通常付与の最終GainをStrength/LevelProgressに同時加算する。例：Lv60、Progress=500Kに+2.5MでLv61/Progress=0となり、Strengthは+2.5Mされたまま。複数Levelを跨ぐ場合は各Requirementを順に消費する。過去のWorld1/World2推奨Levelと旧Thresholdの一致検証は履歴として残すが、新方式の育成時間の保証ではない。Item・Training・Potion・倍率の調整は未実施。[検証報告](../reports/Level_Progress_20260915/build_report.md)。
## 2026-09-16 — World1 Lv1〜50 / Stage6〜10 rebalance

### LevelRequirements（獲得量）

| Level | Requirement | Level | Requirement | Level | Requirement | Level | Requirement | Level | Requirement |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 0 | 11 | 320 | 21 | 1,750 | 31 | 7,500 | 41 | 45,000 |
| 2 | 20 | 12 | 365 | 22 | 2,000 | 32 | 9,000 | 42 | 52,000 |
| 3 | 40 | 13 | 410 | 23 | 2,250 | 33 | 10,000 | 43 | 60,000 |
| 4 | 60 | 14 | 460 | 24 | 2,500 | 34 | 12,000 | 44 | 69,000 |
| 5 | 80 | 15 | 525 | 25 | 3,000 | 35 | 15,000 | 45 | 80,000 |
| 6 | 115 | 16 | 600 | 26 | 3,500 | 36 | 18,000 | 46 | 95,000 |
| 7 | 145 | 17 | 750 | 27 | 4,000 | 37 | 22,000 | 47 | 105,000 |
| 8 | 180 | 18 | 1,100 | 28 | 4,500 | 38 | 27,000 | 48 | 125,000 |
| 9 | 225 | 19 | 1,350 | 29 | 5,000 | 39 | 33,000 | 49 | 150,000 |
| 10 | 280 | 20 | 1,500 | 30 | 6,000 | 40 | 40,000 | 50 | 200,000 |

LvN到達時の累積StrengthはLv1〜Lv(N-1)のRequirement合計で、Lv8/10/15/20/25/30/35/40/45/50はそれぞれ460 / 865 / 2,700 / 7,025 / 17,025 / 37,025 / 81,525 / 196,525 / 462,525 / 1,017,525。

Stage1〜5の前半Play Balanceは維持する。Stage6〜10はRecommendedLevel到達時の理論累積StrengthをRequiredStrengthとして使用し、Wall倍率2/2.5/3/4、Boss倍率5を適用する。

| Stage | RecommendedLevel | RequiredStrength | Wall .1 | Wall .2 | Wall .3 | Wall .4 | Boss |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 6 | 30 | 37,025 | 74,050 | 92,562.5 | 111,075 | 148,100 | 185,125 |
| 7 | 35 | 81,525 | 163,050 | 203,812.5 | 244,575 | 326,100 | 407,625 |
| 8 | 40 | 196,525 | 393,050 | 491,312.5 | 589,575 | 786,100 | 982,625 |
| 9 | 45 | 462,525 | 925,050 | 1,156,312.5 | 1,387,575 | 1,850,100 | 2,312,625 |
| 10 | 50 | 1,017,525 | 2,035,050 | 2,543,812.5 | 3,052,575 | 4,070,100 | 5,087,625 |

Stage5→6のジャンプは意図した前半／後半境界である。Lv40→Lv50の累積Strengthは196,525→1,017,525（約5.18倍）で、Lv50到達時に約1Mへ到達する設計とする。Lv51〜200の明示Requirement、Lv201以降の暫定式、World2のBalanceは変更していない。
## 2026-09-16 — Lv1〜50 Requirement +10 adjustment

Lv1〜50の全Requirementへ一律+10を適用した。Lv1=10となり、Lv1→Lv2にも10 Strengthが必要。Lv51〜200の明示RequirementとLv201以降の暫定式は維持する。

変更後の主要な累積StrengthはLv8=530、Lv10=955、Lv15=2,840、Lv20=7,215、Lv25=17,265、Lv30=37,315、Lv35=81,865、Lv40=196,915、Lv45=462,965、Lv50=1,018,015。

World1 Stage6〜10はRequiredStrengthを37,315 / 81,865 / 196,915 / 462,965 / 1,018,015へ同期し、既存倍率でWall/Boss HPを再計算した。Stage1〜5とWorld2は変更していない。
## 2026-09-19 — Element Set Strength multiplier

Equipping owned Protein, Glove, and Training Belt Items with one identical Element (Fire, Ice, or Electric) applies `Strength gain ×1.5`. The check ignores Rarity. It applies once to normal walking, Auto Tap, Manual Tap, and Treadmill Strength through `StrengthManager.AddStrength`; fixed reward Strength, Protein's base bonus, Glove Boss Damage, and Training Belt tier values are unchanged.
# 2026-09-20 — World1 muscle progression

World1 muscle stages use cumulative Strength consumed by `LevelProgression.Advance`, reaching stages at Lv3 / 6 / 10 / 15 / 20 / 25 / 30 / 35 / 40 / 45. The authoritative cumulative thresholds are 40 / 250 / 955 / 2,840 / 7,215 / 17,265 / 37,315 / 81,865 / 196,915 / 462,965. Growth factors are 4 / 6 / 7 / 8 / 9 / 10 / 11 / 12 / 13 / 14, and Height scales are 1.20 / 1.35 / 1.50 / 1.70 / 1.90 / 2.15 / 2.40 / 2.70 / 3.00 / 3.30. Stage10 therefore uses UpperTorso X/Y/Z 2.68 / 3.30 / 2.40 and UpperArm X/Y/Z 3.10 / 3.30 / 3.10.

## 2026-10-06 - World1 Win Pass multiplier3

Legacy GamePassService.GetWinReward floors baseWin multiplied by the highest verified owned Win pass:1/2/3 for none/2x/3x. Both passes remain3x. Existing AreEffectsEnabled gates can suppress application to1x. Base stage Win amounts and fixed/time rewards are unchanged. Formal IDs1970515086/2005353724; live Marketplace price and live reward verification remain pending.


## 2026-10-12 - Normal Pet Merge preview (local, incomplete seven-Pet pools)

Shared normal rank slots E/E/E/D/C/B/A use10/10/10/20/30/40/50 points, multiplied by Basic1/Rare5/Legendary25/Mythic125. Existing normal draw chances/prices remain unchanged until seventh-species approval. The latest completed-Egg preview probability table (40/60/80% promotion, same50/250/1250 certainty thresholds, adjacent-row linear interpolation/cap1250) is recorded in [the catalog](Stud_Egg_Pet_Catalog.md#completed-egg-probability-preview-not-a-pet-draw--no-merge-execution). It does not change Pet draw odds, Win rewards or combat balance.


## 2026-10-12 - Approved normal seven-Pet pools

Normal Pet draw odds are25/25/25/15/6.5/3/0.5% in preserved original six order plus approved seventh. Corresponding merge ranks E/E/E/D/C/B/A and points10/10/10/20/30/40/50 times Basic1/Rare5/Legendary25/Mythic125 are active from shared Modules.Egg. Seventh-Pet points50/250/1250/6250. Egg Win prices, Limited odds/products, raised completed-Egg Merge preview table and all combat/reward balance unchanged. See latest approved28-Pet table in Stud_Egg_Pet_Catalog.


## 2026-10-13 - Approved World1 Speed tiers

| Stage | Normal upgraded speed | Next speed | Win price |
|---|---:|---:|---:|
| 0 |24|28|100|
| 1 |28|32|200|
| 2 |32|36|300|
| 3 |36|40|400|
| 4 |40|MAX|Disabled|

Total1000 Win. Legacy600-Win Boost owners retain40 and count as stage4; Premium remains50 and disables these purchases. Apply highest eligible speed, not addition. Capacity prices, transient2x multiplier/current local0.8s duration, Training/Boss logic, Item prices, Merge and all rewards are unchanged.


## 2026-10-14 - Item Phase 1 proposals (UNAPPROVED; NOT APPLIED)

Four-star Win offer proposal:1800 Win, equal to three current600-Win Rare items. No approved historic amount was found. Epic Win purchasing remains disabled pending approval; its Robux offer and all Legendary conditions are unchanged.

One point-based Item merge proposal:

| Rarity | Material points | Minimum total for this output rank |
|---|---:|---:|
| Common / star1 | 1 | 1 |
| Uncommon / star2 | 3 | 3 |
| Rare / star3 | 9 | 9 |
| Epic / star4 | 27 | 27 |
| Legendary / star5 | 81 reference value | 81 |

- At least two actual units, with no fixed unit cap; all inputs share one Element. Allow different regular Item types. Proposed maximum-rank handling: Legendary inputs stay unavailable, preserving their current non-mergeable status; output caps at Legendary. Totals above81 do not improve output rank; warn before accepting excess material. These choices require approval.
- Output rank is deterministic: choose the highest threshold not exceeding total points. Thus eligible totals2 produce star1,3..8 star2,9..26 star3,27..80 star4,81+ star5. No rank lottery or hidden remainder carry. Each accepted merge produces one Item in this proposal.
- Output type is a separate weighted lottery: sum material points for each included type, divide by the total. Only submitted types enter the lottery; same-type inputs yield that type100%. Element stays the common input Element. Do not use input unit-count proportions when point values differ.
- This geometric point scale retains the old three-of-one-rank upgrade thresholds while allowing variable counts, mixed types and larger jumps. Two low-rank inputs can retain the same rank; this must be previewed explicitly rather than promised as an upgrade.

Checked examples (all inputs share one Element):

| Inputs | Total | Output rank | Type probabilities |
|---|---:|---|---|
| 2 Common Gloves | 2 | star1 | Glove100% |
| 3 Rare Gloves | 27 | star4 | Glove100% |
| 2 Uncommon Gloves + 3 Common Protein | 9 | star3 | Glove66 2/3%, Protein33 1/3%; Belt0% / excluded |
| 1 Epic Glove + 1 Rare Belt | 36 | star4 | Glove75%, Belt25%; Protein excluded |
| 81 Common Gloves | 81 | star5 | Glove100% |
| 82 Common Gloves | 82 | star5, no extra rank benefit | Glove100% |

Exact-fraction examples sum to100%. Pending approval: price, material scale, thresholds, minimum2, maximum-rank input/excess handling and single-output policy. No new values are installed in ItemMaster, ItemMergeConfig or any server/client merge calculation. Current fixed-three merge remains authoritative.

## 2026-10-14 - Approved Item point lottery and Epic4500 Win (supersedes Phase1 proposal)

| Rank | Material points / rarity threshold |
|---|---:|
| Common / star1 |1|
| Uncommon / star2 |3|
| Rare / star3 |9|
| Epic / star4 |27|
| Legendary / star5 |81|

At least2 actual units; output1. Count multiplies each input's points. Between adjacent thresholds L/U, upper probability=(P-L)/(U-L), lower=1-upper. Exact thresholds100%;81+ Legendary100%. Legendary inputs are permitted. New ranks require Master definitions and shared configured points; current upper rank is inferred from the ladder.

Type probability=points for that type / total; Element probability=points for that Element / total. Those two draws and rarity are independent. Each concrete candidate probability is their product; no unsubmitted type/Element enters the pool. This replaces the prior deterministic-rank/common-Element proposal.

| Total points | Rarity distribution |
|---:|---|
|2|Common50%, Uncommon50%|
|9|Rare100%|
|18|Rare50%, Epic50%|
|27|Epic100%|
|54|Epic50%, Legendary50%|
|81+|Legendary100%|

Fire Common Glove1 + Ice Common Protein1: total2; each included type50%, each included Element50%, Common/Uncommon50%; eight actual combinations each12.5%. Fire-only inputs keep Fire100%; Glove-only inputs keep Glove100%. One Epic Glove + one Rare Belt: total36, Epic83 1/3%/Legendary16 2/3%, Glove75%/Belt25%; Element shares independently follow the submitted points. No points/odds text is added to the material cards.

Approved Win prices: Common75, Uncommon200, Rare600, **Epic4500**. Existing Epic Robux and Legendary conditions unchanged. Price strings alone compact toK/M; internal spending/config/storage retains exact numbers. Normal/Limited Egg odds, normal Pet merge points/table and all combat prices/rewards remain unchanged.

## 2026-10-15 - Epic Win-only individual offer

Supersedes the Epic Robux condition above. Epic/star4 remains exactly4500 Win, displayed4.5K, with no new individual Robux purchase. Keep product3711755218 for already-paid receipt recovery; its fallback metadata is not an active offer. Legendary3711755280, other products/packs, all effects and Item merge probabilities remain unchanged.
## 2026-10-15 update: World1 Egg prices and equipped-Pet Strength

This approved update supersedes earlier cosmetic-only Pet descriptions and normal Egg prices. The existing `Modules.Config.Eggs.Eggs[name].wins` remains the sole price authority; server validation/debit and client labels use `Egg.price`.

| World1 normal Egg | 1 | 3 | 8 |
| --- | ---: | ---: | ---: |
| Basic | 15 Win | 45 Win | 120 Win |
| Rare | 100 Win | 300 Win | 800 Win |
| Legendary | 300 Win | 900 Win | 2,400 Win |
| Mythic | 1,000 Win | 3,000 Win | 8,000 Win |

Strength percentages follow the actual species slots in `Egg.NormalPools.StrengthPercents`. Each row retains odds 25/25/25/15/6.5/3/0.5 percent. Merge points, coefficients, thresholds and execution availability remain separate and unchanged.

| Egg | Actual species, in existing pool order | Strength bonuses, same order |
| --- | --- | --- |
| Basic | Dog; Grey Cat; Pink Bunny; Sheep; Bear; Camel; Slime | +2%; +2%; +2%; +4%; +6%; +8%; +12% |
| Rare | Cow; Giraffe; Lion; Lizard; Spider; Bat; Shroom | +8%; +8%; +8%; +12%; +18%; +25%; +35% |
| Legendary | Elephant; Mammoth; Penguin; Crocodile; Octopus; Shark; Ninja | +20%; +20%; +20%; +30%; +45%; +60%; +80% |
| Mythic | Turtle; Alien; Anglerfish; Dino; Scorpion; Evil Dragon; Chimpanzini Bananini | +45%; +45%; +45%; +60%; +80%; +100%; +130% |

Limited Egg 01 uses `LimitedEggConfig.Entries[*].StrengthPercent` alongside unchanged paid-pool odds:

| Actual ID | Odds | Strength |
| --- | ---: | ---: |
| Pet_042 | 25% | +90% |
| Pet_064 | 25% | +90% |
| Pet_081 | 25% | +90% |
| Pet_086 | 15% | +110% |
| Pet_094 | 6.5% | +130% |
| Pet_024 | 3% | +160% |
| Pet_135 | 0.5% | +200% |

For World1 normal Strength gains only, multiply the completed existing gain calculation by `1 + equippedPercent / 100`. Examples: +2% = 1.02; +130% = 2.3; +200% = 3.0. Resolve only the first owned equipped individual in authoritative saved Pet state. Unequipped, invalid, unknown or unavailable state gives 1.0; duplicate ownership adds nothing. Walking and Treadmill use this path. Fixed Strength rewards and the reward-reference `GetNormalTrainingGain` exclude Pet bonuses. Do not add bonuses to Win, Boss Damage or World2.

Limited product 3717610547, Marketplace price lookup, paid receipt recovery/deduplication, one grant per purchase and Limited exclusion from Pet Merge remain unchanged. Unlisted species receive no inferred ability.
## 2026-10-16 - Approved World1 normal Dumbbells 1-12

Supersedes all earlier seven-item prices/bonuses and the withdrawn slot6 W1-6D image proposal. `ReplicatedStorage.Config.DumbbellItemMaster` is the sole runtime authority for price, additive Strength and image across server/Inventory/Shop/world sale signs. Retain NORMAL_01..07 ownership/equipment IDs; add NORMAL_08..12 in the same normal-only namespace, with no product IDs or save migration.

| No. | ItemId | Win | Strength addition | Image asset ID |
| ---: | --- | ---: | ---: | --- |
| 1 | NORMAL_01 | 5 | +3 | 131314372434925 (retained) |
| 2 | NORMAL_02 | 15 | +5 | 126019719977317 (retained) |
| 3 | NORMAL_03 | 40 | +9 | 96428309215438 (retained) |
| 4 | NORMAL_04 | 100 | +15 | 77317637436768 (retained) |
| 5 | NORMAL_05 | 200 | +25 | 134662273184560 (retained) |
| 6 | NORMAL_06 | 400 | +45 | 98216689951421 (W1-5D) |
| 7 | NORMAL_07 | 750 | +75 | 79967244610623 (retained) |
| 8 | NORMAL_08 | 1,250 | +120 | 137711371845706 (W1-8D) |
| 9 | NORMAL_09 | 2,000 | +180 | 83905550410213 (W1-9D) |
| 10 | NORMAL_10 | 3,500 | +280 | 79276445613926 (W1-10D) |
| 11 | NORMAL_11 | 6,000 | +450 | 111665673963075 (W1-11D) |
| 12 | NORMAL_12 | 10,000 | +700 | 83499911643975 (W1-12D) |

Every image uses `rbxassetid://` plus the listed ID. Slot5 is unchanged; W1-5D is explicitly slot6. Existing addition/multiplication order is unchanged: Dumbbell addition applies on Training's existing path, without adding it to walking. Existing Pet/Rebirth and all other factors remain where they are. Existing fixed reward/reference calculations continue reading the same equipped bonus; no new reward multiplier or formula change. World2/Boss/Pet/Egg/Item/Aura/Merge/Robux settings are unchanged.


## 2026-10-20 — World2 Excel authority and shared Rebirth

The numeric authority is the complete 340-cell World2_数値一覧.xlsx snapshot [recorded here](../reports/World2Workbook_20261020.json), generated into ReplicatedStorage.Config.World2GameplayConfig for server/UI consumers. Independent adjacent tables do not establish unlock relationships. World2 HP/walls/rewards, equipment, Eggs/Pets and treadmill requirements use these values without growth/time balancing. Existing encounter rules are retained; BossHP/5 is not an entry gate. No completion-time claim is validated.

Shared Rebirth required LV for counts 1–10: 10/15/22/30/45/70/90/110/140/160; all ten reference cumulative Strength values match the unchanged LevelRequirements curve. Multiplier is 1+0.5*count including counts above ten. Existing later required-level entries remain. Treadmills old01/02/03/04 use x5/x7/x12/x35 and R0/R7/R9/paid-unavailable; no normal Win purchase condition. Legendary Item 405,000 Win is a three-Epic reference, not a direct purchase. Pet values are final single-equipped multipliers. Unknown paid prices/IDs remain absent. See [evidence and limits](../reports/World2Gameplay_20261020.md).

## 2026-10-20 - Current StageSkip price clarification

Read from the actual CurrentCloud Config during the StageSkip repair: stages2..10 cost1 / 5 / 15 / 50 / 75 / 150 / 300 / 750 / 1200 Win. This supersedes the older StageSkip Win table above and records existing values, not a balance change. Existing ProductIds3711531641,3711531688,3711533318,3711533363,3711533407,3711533440,3711533493,3711533535,3711533573 and fallback Robux10..90 remain exact. World1, Lobby/noncombat and stage2..10 restrictions remain. Evidence: reports/StageSkip_20261020/REPORT.md and FileValidation.json.


## 2026-10-20 - Approved thirteen-stage body growth

Supersedes all earlier muscle threshold/height/factor tables, including the2026-09-20 ten-stage progression. Stage0 is the unchanged base, followed by13 discrete growth stages. Level is explanatory only; AUTO reads current Strength, with no World/Boss gate and no interpolation. Cap at13 for6B or more.

| Stage | Required Strength | Prior LV guide (not a condition) | Height | Upper-arm X/Z |
|---|---:|---:|---:|---:|
|0|0|1|1.00|1.00|
|1|40|3|1.10|1.30|
|2|250|6|1.175|1.45|
|3|955|10|1.25|1.525|
|4|2840|15|1.35|1.60|
|5|7215|20|1.45|1.675|
|6|100000|30|1.70|1.825|
|7|3000000|40|2.00|1.975|
|8|50000000|45|2.15|2.05|
|9|100000000|64|2.40|2.20|
|10|300000000|79|2.65|2.35|
|11|1000000000|102|2.95|2.50|
|12|3000000000|121|3.25|2.65|
|13|6000000000|145|3.55|2.80|

Use `(upperArmScale-1)/0.15` with the existing part coefficients: UpperTorso X/Z .12/.10, LowerTorso .05/.05, LowerArm .08/.08, UpperLeg UpperTorso*.75, LowerLeg UpperTorso*.60. Y uses the explicit table. Head/hands/feet/root are not newly scaled. Manual size access remains Rebirth5,500 Win per changed non-AUTO selection, free AUTO. No Strength/LV/rebirth multiplier/damage/Speed/price/reward changes.


## 2026-10-20 - Body growth threshold-only revision

Stages6..12 now require100000/3000000/50000000/100000000/300000000/1000000000/3000000000 Strength. The table above reflects these values; all shape multipliers and the6B cap remain unchanged. LV labels retain the prior design guides, not recalculated conditions. Level/Rebirth logic, selection/payment/access and all other gameplay are unchanged. Offline boundary/syntax/binary preservation checks passed; Studio was not started.


## 2026-10-20 - Rebirth authority consolidation, no balance change

RebirthConfig now directly owns the existing effective levels10/15/22/30/45/70/90/110/140/160, unchanged entries11..30, and the existing base1/+0.5-per-count multiplier. World2GameplayConfig no longer owns Rebirth. Cumulative Strength references moved to the common Config as information only; they are not admission conditions. Existing World2 treadmill RequiredRebirth0/7/9 and all other equipment values are unchanged.


## 2026-10-26 — Confirmed World1 Ore/dumbbell balance

Authoritative numeric definitions are `ReplicatedStorage.Config.OreConfig` and `DumbbellItemMaster`; the complete twelve-row table is recorded in [World1Ore_20261026](../reports/World1Ore_20261026/README.md). World1 purchase Win:7,20,50,130,250,500,1000,1500,2500,4500,8000,13000. Sale Win:3,10,25,65,125,250,500,750,1250,2250,4000,6500. Merge thresholds:5,20,40,70,110,160,220,290,370,450,530,650. Strength bonuses remain3,5,9,15,25,45,75,120,180,280,450,700.

Ore merge uses only the two neighboring thresholds; the upper probability is `(points-lower)/(upper-lower)`, with exact thresholds guaranteed.500/530/560/590/620/650 produce the requested37.5%/62.5%,100%,75%/25%,50%/50%,25%/75%,100% cases. World1 conditional Ore pools total100%; Spark begins Stage9. No World2, Egg, Pet strength, Item merge formula or multiplier-order rebalance. Spark×5 direct sale325 versus forged#12 sale6500 is intentional, not normalized. Reserved Ore017–020 sale values remain unset.


## 2026-10-31 ? Strength rewards and HUD (unsaved local Edit)

Offline Strength: departure reference per second ? min(elapsed seconds, 3600) ? 0.05. Double product 3724845103 adds the remaining amount to reach exactly 2? the fixed reward. Packs: 3724835102 / 120 seconds / base19; 3724835678 / 720 seconds / base99; 3724836170 / 2400 seconds / base299. Prices are queried from Marketplace, not scaled by progression. Existing training and treadmill values are unchanged.
