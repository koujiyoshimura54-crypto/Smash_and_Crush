# BALANCE_SPEC — ゲームバランス正本

Version: 1.0 / 監査・更新日: 2026-09-15

## 読み方・参照元

現在StudioのソースとObjectを読み取った値を記録する。モジュールを実行せず、参照関係と式から導出した数値は「静的導出」。Play実測は既存の[World1後半レポート](../reports/World1_Stage6_10_20260915/build_report.md)からの引用で、今回は再実測していない。仕様不一致を修正するために数値を変更してはいけない。

World1 Stage6〜10の有効値は **World1LateStageConfig** と **Stage1WallManager.GetStageConfig**。古いWorld1BossConfigとStage1WallManager.Configの後半値は、World2が依存する旧基準として残っている。旧テーブルを現在World1の最終値と取り違えない。

根拠: [ReplicatedStorage.Config.World1LateStageConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.World1LateStageConfig.luau)、[ReplicatedStorage.Config.World1BossConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.World1BossConfig.luau)、[ServerScriptService.World.Stage1WallManager](../reports/Implementation_Audit_20260915/sources/ServerScriptService.World.Stage1WallManager.luau)。

## World1 Stage1〜10：現在の有効値

| Stage | 推奨Lv | RequiredStrength | Wall .1 | Wall .2 | Wall .3 | Wall .4 | Boss MaxHP | Pad基本Win |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 8 | 50 | 100 | 125 | 150 | 200 | 250 | 1 |
| 2 | 10 | 100 | 300 | 325 | 350 | 425 | 500 | 3 |
| 3 | 15 | 300 | 600 | 750 | 900 | 1,200 | 1,500 | 5 |
| 4 | 20 | 1,500 | 3,000 | 3,750 | 4,500 | 6,000 | 7,500 | 10 |
| 5 | 25 | 3,500 | 7,000 | 8,750 | 10,500 | 14,000 | 17,500 | 30 |
| 6 | 30 | 9,000 | 18,000 | 22,500 | 27,000 | 36,000 | 45,000 | 75 |
| 7 | 35 | 25,000 | 50,000 | 62,500 | 75,000 | 100,000 | 125,000 | 150 |
| 8 | 40 | 60,000 | 120,000 | 150,000 | 180,000 | 240,000 | 300,000 | 300 |
| 9 | 45 | 130,000 | 260,000 | 325,000 | 390,000 | 520,000 | 650,000 | 750 |
| 10 | 50 | 250,000 | 500,000 | 625,000 | 750,000 | 1,000,000 | 1,250,000 | 1,000 |

**確定設計：Stage6〜10は推奨Lv30 / 35 / 40 / 45 / 50。Stage10をLv50前後でクリアできる戦闘耐久。** RequiredStrengthちょうどではWall倍率2.0 / 2.5 / 3.0 / 4.0、Boss倍率5.0。これは個別HP設計であり、Carry込み実攻撃回数を整数倍率へ丸める設計ではない。Lv50までの育成所要時間は今回計測していない。

Stage1・3・4・5のWall倍率も2 / 2.5 / 3 / 4。**Stage2のみ3 / 3.25 / 3.5 / 4.25**。全StageのBoss MaxHPはRequiredStrength×5。Stage1〜5には旧「Temporary early-World1 Play balance」、Win表には「Temporary World1 Play-debug」コメントがある。現在値として記録し、正式確定の有無は要確認（K02）。

WinはBoss撃破時の即時付与ではなく、本人が黄色RewardPadを取得した際の基本値。有効World1 DoubleWinならfloor(基本Win×2)。他のDaily/Time等のWinすべてにDoubleWinを掛ける仕様ではない。

根拠: [ReplicatedStorage.Config.TrophyRewardConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.TrophyRewardConfig.luau)、[ServerScriptService.Services.TrophyRewardService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.TrophyRewardService.luau)。

## Level / Strengthカーブ

Levelは現在Strengthが到達した最大の閾値。独立XP・保存Levelは用いない。Strengthは小数を保持する。Lv1〜50の必要Strengthは次表。

| Lv | Strength | Lv | Strength | Lv | Strength | Lv | Strength | Lv | Strength |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 0 | 11 | 320 | 21 | 1,750 | 31 | 11,000 | 41 | 72,000 |
| 2 | 20 | 12 | 365 | 22 | 2,000 | 32 | 14,000 | 42 | 85,000 |
| 3 | 40 | 13 | 410 | 23 | 2,500 | 33 | 17,000 | 43 | 98,000 |
| 4 | 60 | 14 | 460 | 24 | 3,000 | 34 | 21,000 | 44 | 114,000 |
| 5 | 80 | 15 | 525 | 25 | 3,500 | 35 | 25,000 | 45 | 130,000 |
| 6 | 115 | 16 | 600 | 26 | 4,000 | 36 | 30,000 | 46 | 150,000 |
| 7 | 145 | 17 | 750 | 27 | 5,000 | 37 | 36,000 | 47 | 172,000 |
| 8 | 180 | 18 | 1,100 | 28 | 6,000 | 38 | 43,000 | 48 | 196,000 |
| 9 | 225 | 19 | 1,350 | 29 | 7,500 | 39 | 51,000 | 49 | 222,000 |
| 10 | 280 | 20 | 1,500 | 30 | 9,000 | 40 | 60,000 | 50 | 250,000 |

Lv51以降の閾値：`250000 + 10 × ((Lv - 1)^2 - 49^2)`。例：Lv51=250,990。この式と固定表は今回変更しない。

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

根拠: [ReplicatedStorage.Config.LevelRequirements](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.LevelRequirements.luau)。Stage6〜10は指定対応と完全一致。Stage1〜3の差を埋めるためのLevel式・Strength・HP修正は未承認。

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
| Tredmill01 | Premium | 専用Pass、PassId=0 | 20 | 未設定のため通常利用不可 |
| Tredmill02〜03 | Rebirth7 | **5** | 5 | 実装済み、Type名と条件が不一致 |
| Tredmill04〜05 | Rebirth3 | 3 | 3 | 実装済み |
| Tredmill06〜10 | Normal | 0 | 1 | 実装済み |

Zone監視は0.2秒。Objectに残るTickInterval=1 / StrengthPerTick=1は現行tickの参照元ではない。上記TrainingConfigが実行時の値（K05）。Rebirth7という名前から必要回数7を推定しない（K06）。

根拠: [ReplicatedStorage.Config.TreadmillConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.TreadmillConfig.luau)、[ServerScriptService.Services.TrainingManager](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.TrainingManager.luau)。

### Rebirth

World1MaxRebirth=5。Strengthのみ0に戻しRebirthCountを増やす。

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
| Premium Treadmill | 0 | 未設定。Tier20は定義のみ |

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

### Studio現行値（旧暫定・要置換）

現在Studioに残るWorld2 HP Configは、World1後半再バランス前の旧基準×25,000で作られた値である。World2MapはAuthoringOnlyでCombat/Stage進行に未接続。**この旧値を今後のBalance正本として使用しない。**

### World2確定設計案（Studio未反映）

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

Lv201以降は当面、**一定のLevel上昇ルールを仮採用する方針**とする。具体的なStrength増分・式は未確定であり、実プレイとWorld2 Itemバランス確認後に確定する。現行LevelRequirementsのLv51以降式を自動的にLv201以降の最終仕様とみなさない。

World2専用Balanceは設計確定段階であり、StudioのWorld2Config / World2BossConfig / World2WallConfigにはまだ反映していない。実装時は旧×25,000値をこの表へ明示的に置換し、World1へ波及させない。

## その他の数値と変更時の注意

MuscleScaleConfigのStrength閾値：30 / 70 / 130 / 250 / 490 / 970 / 1930 / 3850 / 7690 / 15370。対応HeightScale：1.2 / 1.35 / 1.5 / 1.7 / 1.9 / 2.15 / 2.4 / 2.7 / 3 / 3.5。体格の変更はBoss接触・Zone到達にも影響する。形状計算の詳細は[ServerScriptService.Config.MuscleScaleConfig](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Config.MuscleScaleConfig.luau)を参照する。

保存・課金の永続仕様は[GAME_SPEC](GAME_SPEC.md)、表示倍率は[UI_SPEC](UI_SPEC.md)、未確定事項は[DEV_STATUS](DEV_STATUS.md)。Balance変更時は有効参照元とWorld2への依存を監査し、実装変更・Play実測・回帰結果を区別して本書を更新する。
