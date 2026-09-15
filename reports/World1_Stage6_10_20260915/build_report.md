# World1 Stage6〜10 調整・Play検証レポート

対象: +1 スマッシュ&クラッシュ / PlaceId 101572058398926  
作業日: 2026-09-15  
結果: Studio編集データへ反映済み。World2作業には進まず終了。Robloxへの公開操作は実施していません。

## 最終バランス（Play実測を含む）

| Stage | RecommendedLevel | RequiredStrength | Wall .1 | Wall .2 | Wall .3 | Wall .4 | Boss MaxHP | Boss実攻撃数 | Carry込みWall1〜4実攻撃数 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 6 | 30 | 9,000 | 18,000 | 22,500 | 27,000 | 36,000 | 45,000 | 5 | 12 |
| 7 | 35 | 25,000 | 50,000 | 62,500 | 75,000 | 100,000 | 125,000 | 5 | 12 |
| 8 | 40 | 60,000 | 120,000 | 150,000 | 180,000 | 240,000 | 300,000 | 5 | 12 |
| 9 | 45 | 130,000 | 260,000 | 325,000 | 390,000 | 520,000 | 650,000 | 5 | 12 |
| 10 | 50 | 250,000 | 500,000 | 625,000 | 750,000 | 1,000,000 | 1,250,000 | 5 | 12 |

全Stageで実PlayerのStrengthをRequiredStrengthちょうどにし、実際のGlove Bonusが0であることを確認しました。Wall間を移る位置合わせは検証スクリプトで行い、攻撃・Carry・HP減少・撃破・進行は既存のEnemyManagerの自動戦闘で実行しました。バランス計測中に検証コードからダメージ関数を直接呼んでいません。サーバーHP変化の計測と、クライアントに届いたCombatAttackイベント数が一致しています。

Wall耐久の合計はRequiredStrength×11.5。既存実装はWall4の余剰ダメージもBossへ渡すため、この連続進行テストではBoss戦開始HPがMaxHPの90%になりました。開始HPはStage6から順に40,500 / 112,500 / 270,000 / 585,000 / 1,125,000です。それでもBossへの実攻撃数は全Stageで5回でした。満タンBossの耐久設定は正確にRequiredStrength×5です。Carryロジック自体は変更していません。実測に合わせたHPの再調整もしていません。

## Collider / CombatZone

SizeはローカルXYZ、単位はstud。回転があるColliderでは、Sizeはワールド軸のBoundingBoxと同じ意味ではありません。

| Stage | Boss | DisplayHeight（維持） | CollisionReference最終Size | CombatZone最終Size |
|---|---|---:|---|---|
| 6 | Pipi_Kiwi | 36 | 18 × 34 × 36（変更なし） | 22 × 14 × 40 |
| 7 | Trippi Troppi | 48 | 18 × 44 × 44 | 22 × 14 × 48 |
| 8 | Chimpanzini Bananini | 44 | 32 × 44 × 30 | 36 × 14 × 34 |
| 9 | Trippa Troppa Tralala Lirilì Rilà TungTung Sahur Boneca TungTung Tralalelo TrippiTroppa Crocodina | 56 | 28 × 52 × 14 | 32 × 14 × 18 |
| 10 | Dragon Cannelloni | 52 | 28 × 46 × 32 | 32 × 14 × 36 |

| Stage | 変更前Size | 最終ローカル位置 | 最終Y回転 | 調整内容 |
|---|---|---|---:|---|
| 6 | 18 × 34 × 36 | (0, 13, 2) | 0° | 既存Colliderを維持。四方向で既存不具合を検出せず |
| 7 | 24 × 38 × 36 | (0, 18, 0) | 150° | 胴体Meshの向きに合わせた細長い箱。前後の被覆を改善し、全体BBoxを箱にすることを回避 |
| 8 | 5 × 7.5 × 4 | (0, 18, 0) | 0° | 主体部分の幅・奥行きに拡大。全体幅約45.45をそのまま採用せず |
| 9 | 5 × 7.5 × 4 | (0, 22, 0) | 0° | 胴体の薄い奥行きを維持した大型Collider |
| 10 | 5 × 7.5 × 4 | (0, 19, 0) | -30° | 胴体の向きに合わせて回転。翼などを含む全体幅約56.27から縮めた箱 |

Play上で主要胴体とColliderを視覚比較し、四方向から実PlayerのHumanoidを歩かせて接触を確認しました。今回の確認範囲では、主要胴体への大きな侵入や、主要胴体から大きく離れた不自然な停止は検出していません。細い突出部・翼・装飾の全表面を物理形状に一致させるものではありません。

Stage6〜10のCollider底面はすべてY=2で、床上面Y=2に一致。停止時のPlayer足底は約Y=1.982〜2.005で、床に沿って停止しました。20ケースすべてでPlayerの中心がCollider側面の外にあり、足元への潜り込みを検出していません。

CombatZoneは旧サイズ10×14×16・前方オフセットでは、大型Colliderの側面・背面から戦闘判定に届かない位置関係でした。Stage6〜10に限定して、各Colliderと同じXZ位置・回転で水平各軸を合計4stud拡張した範囲へ変更。高さ14を維持し、底面を床へ合わせています。物理ColliderはCanCollide用、CombatZoneは非衝突の戦闘開始判定用として役割を維持。Stage1〜5のCombatZone生成処理は元のままです。

## Play確認

| 検証 | 結果 |
|---|---|
| Stage6〜10のHP・RequiredStrength・RecommendedLevel | 指定値と一致 |
| Gloveなし・RequiredStrengthちょうど | 全Stageで確認 |
| Carry込みWall突破 | 各Stage 12攻撃、全Wall HP=0 |
| Boss撃破 | 各Stage 5攻撃、Boss HP=0 |
| 正面・左・右・背面の接触 | 5 Stage × 4方向、全20ケースで接触確認 |
| 停止位置からBoss戦開始 | 全20ケースでFighting=trueかつBossEncounterあり |
| 離脱 | 全20ケースでFighting=falseに戻る |
| 足元・Collider底面 | 全Stageで床面に一致 |
| Wall戦UI | 60回の実攻撃観測でWall HP Barのみ1個表示、Boss HP非表示 |
| Boss戦UI | 25回の実攻撃観測でBoss HP Gaugeのみ1個表示、Wall HP非表示 |
| Stage6→7→8→9→10 | 既存撃破処理による連続進行を確認 |
| Stage10 WorldComplete | trueを確認 |
| 検証Playerの復元 | 元のStrength 1,143,796.7624999975 / Win 2,139等へ復元 |
| 最終PlayのError / Warning / Infinite Yield | 0 / 0 / 0 |

Collider検証では前提条件としてWall解放状態を作りました。この前提設定と、実攻撃数を数えた連続進行テストは別工程です。初回試験で見つかったWall旧値参照とStage8正面の試験開始位置を修正し、上表は再実行後の結果です。HP UIやゲームデザインは変更していません。

最終の通常Playは、検証スクリプトを除去した状態で起動し、少なくとも71秒経過時点までConsoleが空であることを確認しました。Studioは停止して編集状態に戻しています。検証用の自動スクリプト・観測LocalScriptは納品シーンから削除済みです。

## Level / Strengthカーブ

| Level | 現行必要Strength | 指定RequiredStrength | そのStrengthの実際のLevel | 判定 |
|---:|---:|---:|---:|---|
| 30 | 9,000 | 9,000 | 30 | 一致 |
| 35 | 25,000 | 25,000 | 35 | 一致 |
| 40 | 60,000 | 60,000 | 40 | 一致 |
| 45 | 130,000 | 130,000 | 45 | 一致 |
| 50 | 250,000 | 250,000 | 50 | 一致 |

LevelRequirementsおよびStrengthManagerは変更していません。今回確認したのはLevelとStrengthの対応および戦闘耐久で、Lv50までの育成所要時間の再計測ではありません。

## World2を維持する実装

World2BossConfigはWorld1BossConfigのHPを、World2WallConfigはStage1WallManager.ConfigのWall HPを参照して倍率を掛けています。そこで両方の基準テーブルをそのまま残し、World1の実戦だけWorld1LateStageConfig / Stage1WallManager.GetStageConfigを経由させました。

今後World1 Stage6〜10の設定を確認・調整するときは、World1LateStageConfigとGetStageConfigを参照してください。旧World1BossConfigおよびWall.Configの後半値を直接変更するとWorld2にも波及するため、今回それらの値は変更していません。

| Stage | World2 Boss HP（維持） | World2 Wall HP .1 / .2 / .3 / .4（維持） |
|---|---:|---|
| 6 | 2,500,000,000 | 105,125,000 / 210,250,000 / 315,375,000 / 420,500,000 |
| 7 | 8,750,000,000 | 144,500,000 / 289,000,000 / 433,500,000 / 578,000,000 |
| 8 | 25,000,000,000 | 190,125,000 / 380,250,000 / 570,375,000 / 760,500,000 |
| 9 | 75,000,000,000 | 242,000,000 / 484,000,000 / 726,000,000 / 968,000,000 |
| 10 | 250,000,000,000 | 300,125,000 / 600,250,000 / 900,375,000 / 1,200,500,000 |

これらはPlay内の既存World2設定モジュールから読み取った値で、維持した旧基準×25,000と一致します。World2Map / World2Gate / World2Config / World2BossConfig / World2WallConfigは変更前後の照合が一致。HighestUnlockedWorld、移動、解放、HPの調整は実施していません。

## 変更したConfig / Script / Object

| 対象 | 内容 |
|---|---|
| ReplicatedStorage.Config.World1LateStageConfig（追加） | Stage6〜10のStrength・推奨Level・Boss HP・Wall HP。Stage1〜5は既存設定を引き継ぐ |
| ServerScriptService.World.BossCombatService | World1の有効設定の参照先を新Configへ変更 |
| ServerScriptService.World.Stage1WallManager | GetStageConfigを追加し、状態初期化とSnapshotに適用。旧ConfigとCarry処理を維持 |
| ServerScriptService.World.EnemyManager | Wall HP通知のMaxを有効設定に統一。Stage6〜10のみCombatZoneをColliderに合わせて生成 |
| ServerScriptService.Systems.Debug.StudioDebugService | 読み取り用/balance診断がWorld1の有効設定を表示するよう参照先変更 |
| ServerStorage.EnemyTemplates.Stage07Boss〜Stage10Boss.CollisionReference | 上表のSize・CFrameへ変更 |
| Workspace.GeneratedMap.BattleCorridor.Stage06〜Stage10内のStageN.1〜StageN.4 | 各Wall Modelと子WallのMaxGauge属性のみ更新（20 Model + 20 Part） |

Stage1〜5のWall/Boss設定・要求値・推奨Level・Collider・Combat・Rewardは維持。マップの形状・位置、RewardPad、Win、Item Drop、Stage Skip価格、計算式、Rebirth、Inventory、課金、Daily/Time Reward、UIデザイン、DataStore Schemaも変更していません。

変更前後の全Scriptソースの照合で、変更は既存4本と追加1本のみです。さらに保護対象24範囲（Stage1〜5本体とテンプレート、World2一式、全体Mapの許可HP属性以外、Stage6 Collider、Stage6〜10 Visualなど）のハッシュ・Instance数がすべて一致しました。詳細はevidence/scope_comparison.jsonとbefore/afterのfingerprints.jsonを参照してください。

## 保存物

- build_report.md: 本レポート。
- final_balance.csv: 最終数値とPlay実測値。
- before/: 変更前ソース、Object属性、保護対象の照合情報。
- after/: 反映済みソース、最終Object属性、保護対象の照合情報。
- evidence/play_results.json: 最終の戦闘・四方向接触・離脱・進行・World2読取結果。
- evidence/client_combat_events.json: 実CombatAttackとUI表示観測。
- evidence/scope_comparison.json: 変更禁止範囲とScript変更一覧の比較。
- evidence/final_play_probe.luau / client_probe.luau: 測定に使用した一時コードの記録。シーンには残していません。
- evidence/initial_play_results.json: 初回の診断結果（最終合格値ではありません）。

対象のStudio編集データに実装を反映しました。本フォルダーはソースと検証記録の保存先であり、完全な.rbxl/.rbxlxの書き出しではありません。RobloxへのPublishは行っていません。

