# BALANCE_SPEC — ゲームバランス正本

Version: 1.4 / 監査・更新日: 2026-09-16

## 読み方・参照元

初期監査の静的導出・過去Play記録と、今回の検証を区別する。2026-09-16のConfig統合では、統合前後のPlayサーバーからWorld1/World2全Stageの数値を取得し、同一のサービス検証520項目が完全一致した。過去表を根拠に現在Runtimeの数値を変更しない。

**World1BossConfig = World1 Stage1〜10の唯一のBalance正本**。`ReplicatedStorage.Config.World1BossConfig`のRequiredStrength / RecommendedLevels / GetMaxHP / GetWallConfigを参照する。`Stage1WallManager.Config`とGetStageConfigは同じ設定を返す互換窓口。旧後半Configは全Runtime参照移行・Play一致確認後に削除済み。World2はWorld2Config.Stagesを独立した正本とし、World1への依存はない。

根拠: [Config統合・Play検証報告](../reports/World1_Config_Consolidation_20260916/build_report.md)、[統合後World1BossConfig](../reports/World1_Config_Consolidation_20260916/sources/ReplicatedStorage.Config.World1BossConfig.luau)、[全Stage数値CSV](../reports/World1_Config_Consolidation_20260916/final_balance.csv)。過去reportsのSnapshotは当時の履歴として保持する。

## World1 Stage1〜10：現在の有効値

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
| Tredmill02〜03 | Rebirth7 | **5** | 5 | 実装済み、Type名と条件が不一致 |
| Tredmill04〜05 | Rebirth3 | 3 | 3 | 実装済み |
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

攻撃間隔0.8秒、攻撃アニメーション時間0.6秒、Wall hit適用遅延0.18秒、Boss hit遅延0.5秒、接触監視0.1秒。

Wallダメージは現在Strength（Gloveなし）。Boss通常ダメージは遭遇開始時Strength×(1+Glove加算率)。Bossの適正判定比率は **補正前Strength / RequiredStrength** で、GloveやCarryを必要Strengthの代わりに使わない。

| 比率 | ルート / 勝利抽選率 |
|---|---|
| 1以上 | LEVEL_DAMAGE。抽選なし、HPによる決着、固定5回制限なし |
| 0.6未満 | 抽選0% |
| 0.6以上0.7未満 | 25% |
| 0.7以上0.8未満 | 50% |
| 0.8以上0.85未満 | 80% |
| 0.85以上0.9未満 | 85% |
| 0.9以上0.95未満 | 90% |
| 0.95以上1未満 | 95% |

比率1未満のLOTTERY_WINは5回で撃破するルート（途中HPを最低1に保ち、5回目で0）。LOTTERY_MISSはGlove込み通常ダメージでHP0なら勝利、5回までに倒せなければ敗北。旧Level差によるGetWinChanceヘルパーを現行比率抽選と混同しない。離脱しても同Runの遭遇Strength・HP・抽選結果を維持する。

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

MuscleScaleConfigのStrength閾値：30 / 70 / 130 / 250 / 490 / 970 / 1930 / 3850 / 7690 / 15370。対応HeightScale：1.2 / 1.35 / 1.5 / 1.7 / 1.9 / 2.15 / 2.4 / 2.7 / 3 / 3.5。体格の変更はBoss接触・Zone到達にも影響する。形状計算の詳細は[ServerScriptService.Config.MuscleScaleConfig](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Config.MuscleScaleConfig.luau)を参照する。

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
