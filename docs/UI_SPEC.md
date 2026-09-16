# UI_SPEC — 現在のUI仕様正本

Version: 1.1 / 監査・更新日: 2026-09-15

## 対象と根拠

現在のStarterGui、HUDLayout、各LocalScriptとサーバー通知経路を基準とする。過去のUI案や古いObject位置だけを採用しない。今回の確認はEdit状態のソース・プロパティ監査で、PC/Smartphone/Tabletの新しい画面実測は実施していない。

根拠: [ReplicatedStorage.Modules.HUDLayout](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Modules.HUDLayout.luau)、[ReplicatedStorage.Modules.ResponsivePanels](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Modules.ResponsivePanels.luau)、[UI Object記録](../reports/Implementation_Audit_20260915/scene_objects.json)。仕様不一致は[DEV_STATUS](DEV_STATUS.md)へ集約する。

## HUDLayout / LEFTMENU

HUDLayout.Mountが表示時の配置を管理する。実Object階層のLeftMenuと、画面左に見えるボタン集合は同じ意味ではない。Rewards/DailyがLeftMenuの子でも画面右側に配置される場合がある。

| HUD領域 | 現在の内容 |
|---|---|
| 左 / LEFTMENU | 2列：1段目Skip / Inventory、2段目Rebirth / Shop、3段目Free / 空き |
| 右 | Rewards（Time Rewards）、Daily、World1 DoubleWin |
| 上 | Win |
| 下 | Strength / Levelと進捗バー、Potion状態 |
| Overlay | Item Drop等のルーレット表示と、その予約領域 |

左基準寸法は幅302×高さ460、1ボタン144×144、隙間14。右基準寸法は211×476。旧MergeButtonは存在するがVisible=false。MergeはInventory内のMergeタブから使用する。

StrengthGui：CoreUISafeInsets、IgnoreGuiInset=false、ResetOnSpawn=false、通常DisplayOrder10。主要Panel表示中は35。World1DoubleWinGuiは25、StageSkipGuiは30。ルーレット用領域は45、既存演出Guiは509/510かつDeviceSafeInsets。常にすべてを最前面へ上げる方式ではない。

編集時LeftMenu.MenuScaleに残る倍率を現在の画面倍率とみなさない。MountがMenuScaleを1へ戻し、配置先の各ボタンUIScaleで制御する。

## PC / Smartphone / Tablet

| 区分 | 現在の判定・処理 |
|---|---|
| PC等の通常画面 | preferred=min((幅/1917)^0.45,(高さ/1022)^0.45)を0.34〜1へclamp。利用可能領域へ配置 |
| Compact | 幅<700、または高さ<500。横長/縦長でWin・左右HUD・下部HUDの位置を変える |
| Touch | TouchEnabledだけでなく、実際に表示されるTouchGui操作部品を検出 |
| Tablet | Touch操作あり、かつmin(幅,高さ)>=500 |
| PanelのSmall判定 | 幅<1000、または高さ<650、またはTouch操作あり。HUDのCompactとは別 |

SmartphoneでもLEFTMENUは基本2列。Thumbstick・Jump・SafeInsets・右HUD・ルーレット予約領域を避けて配置する。画面サイズを端末名だけから推定しない。

### Tablet倍率

**Tabletでは左メニューの基準倍率へ3.0を掛ける実装。UI全体を一律3倍にする仕様ではない。**

その後、画面内に収まる幅・高さ、右側HUD、実際のJumpButtonやThumbstick可視部との重なりを検査して倍率/位置を補正する。全面を覆うDynamicThumbstickFrameをそのまま巨大な障害物として扱わず、見えている操作部品を使う。最終倍率は画面ごとに変わる。

Panel、Win、Strength、右メニューは別の計算を持つ。Tabletの「3倍」をそれらへ無条件適用しない。Mobile/Tabletの実機・縦横・ノッチ・文字サイズの再調整余地は残る（K13）。

### Panelの拡縮

ResponsivePanelsはPanel固有のResponsiveDesignSizeを保持し、画面からHUD予約領域と余白を引いた範囲へUIScaleでFitする（clamp 0.05〜1）。主要Panelの内部レイアウト処理は現在local small=falseで編集済み形状を維持する。ソース中に残る小画面用カード再配置案をすべて有効な仕様として記載しない。

| Panel | 編集時の基準寸法（約px） |
|---|---|
| Inventory | 900 × 660 |
| Shop | 919.52 × 681.29 |
| Rebirth | 895.20 × 592.70 |
| Time Rewards | 760 × 440 |
| Daily | 679.67 × 450 |
| Community / Free | 786.91 × 488.94 |

Item一覧は3列。Touch対象には親領域内で約40px以上を目指す透明Hitboxを追加し、0.1秒の連打抑制がある。物理画面で全端末の押しやすさを保証した結果ではない。

## Strength / Level HUD

上段StrengthLevelHUD.Strengthはサーバーの累積StrengthをNumberFormatで短縮表示する。下段Levelは保存Level Attribute、数値ラベルは **LevelProgress / GetRequiredStrength(Level)**、バーは同じ比率を0〜1へclampして表示する。StrengthからLevelを逆算しない。
Strength・Level・LevelProgressのAttribute変更で更新する。Lv1 Requirement=0では0除算を避けバー0%、上限Lv10,000は従来どおりバー100%。例：累積3.5M Strength／Lv.60／500K / 3M。
UI Object、位置、サイズ、HUDLayout、Formatterの丸めは変更していない。

RebirthでStrength=0・Level=1・LevelProgress=0となり、上段0 Strength／下段0 / 0・バー0%へ更新。Potionは有効種別と残り時間を表示。表示上の丸めをゲーム内部のStrengthへ書き戻さない。

## Boss HP UI / Boss Name / Wall HP UI

現行のPhase C.5関連改善を維持する。サーバーの個人CombatType/HP/Stage通知が表示を決める。

| 戦闘状態 | Boss HP UI | Wall HP UI |
|---|---|---|
| CombatType=MiniBoss | 対象Bossのみ表示 | 非表示 |
| CombatType=Wall | 非表示 | 対象WallのHPだけ表示 |
| 非戦闘・離脱・Run初期化等 | 条件に従い解除 | 条件に従い解除 |

Bossの共有Humanoid Healthを個人HPの正本として表示しない。Wallも古いConfigのMaxHPをクライアント側で推測せず、有効設定に基づくサーバーPacketを使用する。CharacterAdded、Stage変更、Boss結果、初期化で古い表示を解除・再評価する。

### Boss表示の形状

PersonalGaugeというBillboardGuiをBoss Rootへ付け、実BBoxとBone.WorldPositionを考慮した上端へ配置する。高さに応じた余白は4〜8stud。AlwaysOnTop=false、MaxDistance200、LightInfluence0。

表示幅はviewport幅-32をもとに280〜通常480px、Stage9だけ最大620px。高さは通常160px、Stage9は216px。Boss名領域は通常60px、Stage9は116px、TextSize制約20〜32、折り返しあり。Stage表示と緑のHPバーを含む。

| Stage | Boss Name |
|---|---|
| 6 | Pipi_Kiwi |
| 7 | Trippi Troppi |
| 8 | Chimpanzini Bananini |
| 9 | Trippa Troppa Tralala Lirilì Rilà TungTung Sahur Boneca TungTung Tralalelo TrippiTroppa Crocodina |
| 10 | Dragon Cannelloni |

Stage9の名前を短縮名へ変更しない。Stage1〜5はモデル名から末尾Rigを除き、camelcase境界等を整えて表示する経路。後半の名前は現在の指定表記を使用する。

根拠となる実装ファイルは[ソース一覧](../reports/Implementation_Audit_20260915/source_manifest.json)中のCombatClient、StageWallDisplayClientおよびEnemyManager。前回PlayではWall攻撃60回でWallのみ、Boss攻撃25回でBossのみの表示を確認済み。[既存レポート](../reports/World1_Stage6_10_20260915/build_report.md)を参照。今回UIを変更・再Playしていない。

## Rewards / Daily / Shop / Inventory / Rebirth

| UI | 現在の役割・状態 |
|---|---|
| Rewards | 累積オンライン時間、各報酬の残り時間/受取状態、Claim |
| Daily | UTC日付での7段階報酬、受取可否、VIP日次追加枠 |
| Free / Community | Group加入に対する一度きりRewardの確認・Claim |
| Inventory | Dumbbells / Items / Merge / Aura / Speed。初期Dumbbells、所有・装備状態を表示 |
| Items | Protein / Glove / Belt、数量、Rarity、装備、Best Equip |
| Merge | 同一通常Item3個のレシピ、結果、所有数・実行可否 |
| Shop | Starter Pack / Secret Pack / VIP / Premium Speed / BUY WIN導線。価格はMarketplace優先 |
| Secret Pack | Epic+抽選内容・確率確認、PaidRandom制限への対応 |
| Rebirth | 現在回数、次Level条件、倍率、実行またはWorld1 MAX |
| Stage Skip | Stage2〜10選択、Win/Robux購入。サーバーがLobby・非戦闘を再検証 |

Inventory通知バッジはタブ単位の既読方式とする。新しいDumbbell／Aura／Speed解放または新しい所有Itemがあるタブだけ「！」を表示し、そのタブを開いた時点で消す。購入は消去条件ではない。別タブの未確認通知は残り、親Inventoryバッジは子タブの論理和で表示する。確認済みIDはPlayerDataへ保存するため、再Joinで同じ内容を再通知しない。

Panelは他の主要Panelと排他で開閉する。BUY WINの見た目上の導線はあるが、WinProducts空のため販売完成を意味しない（K10）。UIが示す課金所有状態と、StudioDebugConfigで効果が抑制されるテスト状態を区別する（K11）。

## RewardPad

実装は黄色Neon Pad。TrophyRewardTemplate.Handleは8×0.3×5stud、RGB255,221,0。旧Trophy像へ戻す予定は確定していない。

Boss区画Floorの左側へ相対配置し、実接触用HitboxはHandleに高さ0.6studを加え、中心を上へ0.3studずらす。OwnerUserId付きで本人用表示・取得判定。Winの加算は表示を見た時点ではなくサーバーのPad取得成功時。詳細は[GAME_SPEC](GAME_SPEC.md)。

## World2Gate Sign / PortalSurface / Player別表示

場所：Workspace.World2Gate。現行PlacementStatusは「Temporary - BackWall preview」。Gateの存在はWorld2移動実装済みを意味しない。

| 状態 | 表示 | Portal色・材質 | 透明度 | 文字色 |
|---|---|---|---:|---|
| HighestUnlockedWorld<2 | WORLD 2 / LOCKED / Clear World 1 | RGB91,73,60、SmoothPlastic | 0.12 | RGB255,239,208 |
| HighestUnlockedWorld>=2 | WORLD 2 / ENTER | RGB180,123,52、Neon | 0.22 | RGB49,28,16 |

SignはSign.SignAnchor.WorldLabel。PortalSurfaceは12.2×24×0.25stud、CanCollide / CanTouch / CanQueryすべてfalse。表示用Surfaceと移動Triggerを混同しない。

WorldGateClientがLocalPlayerのHighestUnlockedWorldに応じてローカル表示を更新する。共有サーバーのGateを一律解放色へ変える方式ではない。LocallyUnlocked属性はクライアント表示の補助で、サーバーのWorldアクセス権ではない。

**ENTERでも移動しない：World2移動は未実装。** Gate文言のClear World 1に対し、現行永続解放はStage10 RewardPad取得時。Boss撃破時WorldCompleteとは別イベント（K04）。多人数でLOCKED/ENTERを同時表示する試験は未実施（K12）。

根拠: [ReplicatedStorage.Config.WorldGateConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.WorldGateConfig.luau)、[StarterPlayer.StarterPlayerScripts.World.WorldGateClient](../reports/Implementation_Audit_20260915/sources/StarterPlayer.StarterPlayerScripts.World.WorldGateClient.luau)。

## 次回UI検証

PC、Smartphone縦/横、Tablet縦/横を実際のViewportとTouchGuiで検証する。長いStage9名、ルーレット中の操作、Panelの閉じる/Claim/購入ボタン、SafeInsets、Potion表示、異なる解放状態の複数Playerを含める。今回は新たな合格結果を作らず、未検証として残す。


2026-09-15：実PlayerのStrength獲得・Level Up・Carry・Rebirthで上記HUD表示をPlay確認。端末別デザイン変更は実施していない。[検証報告](../reports/Level_Progress_20260915/build_report.md)。
## 2026-09-15 — World travel confirmation

- `StarterGui.WorldTravelGui`はPlayer別Modal。表示文は`WORLD 2` / `Travel to World 2?`、操作は`YES` / `NO`。
- 中央配置、幅86%・最大520px・最小280px、高さ230px（200〜250px制約）。TextScaledとUITextSizeConstraintを併用し、PC・Phone・Tabletで同じ構造を維持する。
- 未解放Playerには表示しない。NO後はGate退出まで再表示を抑止し、YES後は即座に閉じて連続送信を防ぐ。
## 2026-09-15 — World1 Return confirmation

- 既存`WorldTravelGui`を往復で共有する。World2行きは`WORLD 2` / `Travel to World 2?`、World1帰還は`WORLD 1` / `Return to World 1?`。
- YES/NO、中央Modal、PC/Phone/Tablet向けSize制約は共通。NO後は現在のGateを退出するまで再表示しない。
