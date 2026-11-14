# 専用Body試作・実機確認 — 2026-11-14

判定：30％・40％とも副本Studioの隔離Playで動作する試作を作成できた。ただしClassic衣服のUV不適合、成長後の足浮き、手とダンベルの比率が残るため、正式採用サイズ・衣服は未確定。

## Studioで実際に試した内容

### 対象と保護

- 対象：副本PlaceId **126576845524886**、UniverseId 10765181857、読込PlaceVersion **648**。開始・終了ともEdit。自分が開始したPlayを1回だけ実行・停止。
- 事前に [調査報告](../StarterCharacterInvestigation_20261114/REPORT.md) を読み、現在の実物と照合。元モデルは **Workspace.StarterCharacter**。調査時の135子孫に対し現在154子孫で、差は19個のNoCollisionConstraint。Body寸法・MeshId・成長Configは報告と一致。
- 元モデルは移動・縮小・顔削除・衝突変更をしていない。開始時コピーとの終了照合でSize/CFrame/Color/衝突設定/Motor C0・C1/Attachment等が一致。コピーは153子孫になるが、元のHumanoid.StatusだけがArchivable=falseであるため。
- 正本101572058398926、Save/Publish、PR #1への操作はなし。既存ローカル編集を保持し、origin/mainのbf80c37から分離した作業ツリーを使用。
- 既存FirstBattleTutorialの隔離実装を今回用の名前で使用。39 SourceのDataStore/Marketplace/Badge/Messaging/Policy参照をメモリ内代替へ一時転送し、残存する直接DataStore/Marketplace参照がないことを確認してからPlay。実課金・本番DataStoreを使わない。実測時のメモリ内書込カウンタは13。
- 一時生成フックはStudio・副本・今回の本人UserIdだけに限定し、LoadCharacterAsync完了後、SpawnEngineReadyを立てる前に組み立てる。全プレイヤー用StarterCharacterには配置していない。
- 終了時はフック1 Sourceと隔離39 Sourceを、挿入直前に取得したSourceへ一致確認付きで復元。一時プローブ、カメラ、測定用ScriptはPlay終了で除去。比較撮影のため一時非表示にした13 ScreenGuiも元のEnabled値へ復元。

### 30％／40％と購入済み外観

Bodyは元コピーから毎回絶対倍率で作成。本人のHeadは同じInstanceを保持し、Dynamic HeadのFaceControls、SurfaceAppearance、WrapTarget、Neck/Hair/Hat/FaceFront/FaceCenter Attachmentを保持した。元Bodyの固定顔Handle/Decalは試作用コピーから除去し、元の顔と二重に重ねていない。

| 項目 | 30％ | 40％ |
|---|---:|---:|
| LV1 UpperTorso XYZ | 1.244 / 1.534 / 0.786 | 1.658 / 2.045 / 1.048 |
| LV1 UpperArm XYZ | 0.778 / 1.161 / 0.759 | 1.037 / 1.547 / 1.012 |
| LV1 HipHeight | 1.192088 | 1.589450 |
| 本人Head XYZ（両候補共通） | 1.195 / 1.195 / 1.204 | 同左 |
| 静止プレビュー外接 XYZ（髪込み） | 2.401 / 4.172 / 1.817 | 3.201 / 5.020 / 1.817 |
| LV1足箱下端と床の差の例 | -0.012 / -0.020 | -0.013 / -0.025 studs |

頭はBodyと一緒に30％／40％へ縮小していない。これは**頭のアセット保持とは別の試作条件**で、今回は元の寸法を共通にして比較した。頭の寸法を将来固定する仕様を確定したものではない。30％のほうが頭・髪がBodyに対して大きく見える。

- 本人の装着Headアセット：**122931905199936**。Head MeshId：**117643569671751**。別アセットへ置換していない。
- 髪アセット：**71658502219651**。HairAttachmentへの装着が保たれた。実行時はAccessoryRigidConstraint、Editで作った参照モデルではAccessoryWeldという差があった。
- FaceControlsは1個を保持。JawDrop=0.7への設定を受理し、通常の瞬きも画面上で見えた。ただし全表情・リップシンクの合格判定ではない。
- 首の装着点差は代表測定で0～約0.000031 studs。既存アバターの旧Neck AnimationConstraint/BallSocketをBody交換時に整理し、最終再生成ではNeck Motor6Dが1個、全身Motor6Dが15個。
- 本人の既存Layered衣服・靴・Bodyアクセサリーは今回のClassic試着から除外し、参照モデル側に保持。専用Bodyのケージは作っていない。
- [比較画像](comparison_30_40.jpg)：左が40％Pastel、中央が40％Simple、右が30％Simple。これはPlay後のEdit静止プレビュー撮影。

### Classic衣服と肌色

以下は隔離によるMarketplaceモックを入れる**前**に、実際のMarketplaceServiceで価格・種別を確認し、InsertServiceで読込したもの。衣服アセットIDと、衣服Instanceから取得したテンプレート画像IDを分離した。いずれも確認時PriceInRobux=0、IsForSale=true。購入操作・再アップロードはなし。

| 候補 | 衣服アセットID | 種別 | テンプレート画像ID | 実際の結果 |
|---|---:|---|---:|---|
| [Roblox Shirt - Simple Pattern](https://www.roblox.com/catalog/3670737444) | 3670737444 | Classic Shirt / AssetType 11 | 3670737337 | LoadAsset成功。Tシャツ系として試着。黒い模様が肩・脇・胸等に分断され、形に適合せず |
| [Pastel Starburst Top with Gray Jacket](https://www.roblox.com/catalog/398634295) | 398634295 | Classic Shirt / AssetType 11 | 398634294 | LoadAsset・クライアントPreload成功。女子向けデザイン比較として試着。パステル領域が身体の節々へ分断され、ジャケットとして成立せず |
| [Black Jeans with White Shoes](https://www.roblox.com/catalog/398633812) | 398633812 | Classic Pants / AssetType 12 | 398633811 | LoadAsset・クライアントPreload成功。腰・股・膝・足へ模様が断片的に出て、連続したズボンにならず |

**読めた服は3点、適合を確認できた服は0点。** 無料・読込成功を衣服適合の根拠にはしていない。肩・脇・腰・股・膝を前方・斜めから比較し、LV32/140でも不適合が残った。すべての角度・全アニメーションの衣服品質保証はしていない。

本人のBodyColors（今回の胴：RGB **230/191/154**）を専用Bodyへ引き継ぎ、試作用に **244/215/190**、**111/78/55**へ切り替えた。顔の目・口、髪、Shirt/Pantsの模様は残った。HeadのSurfaceAppearance ColorMap **78897881727278**を変更していない。肌色変更はBasePartのColorだけに作用し、服・顔テクスチャを塗りつぶしていない。

[肌色・Pastel比較](comparison_skin_pastel.jpg)：左からLight、Dark、本人色、Simpleの比較。Edit撮影。衣服不適合は残るが、肌色だけの切替を判別できる。

### Playの接地・操作・設備

- 両候補で通常Humanoid CameraSubject/Customカメラによる初期表示、実キー入力の歩行、Spaceジャンプ、着地を確認。40％は水平約22.67 studs・上昇約7.53、30％は約23.56・上昇約7.31。入力区間とサンプリング区間が異なるため速度測定値にはしない。
- LV1はクライアントFloorMaterial=Plastic、Running/Landed/Freefall遷移を確認。上表の接地差は回転を含むFootの箱下端と衝突面Raycastの差であり、三角形の足裏面測定ではない。
- NORMAL_01ダンベルを隔離メモリ内の本人Inventoryへ試験付与し、既存EquipDumbbell経路で装備。両手のBar中心は手のローカル位置 **(0,-0.15,0)**に追従し、脱落なし。Bar寸法は2/0.5/0.2、手は30％で約0.338/0.535/0.362、40％で0.450/0.714/0.483。小さい手に対しダンベルが大きく、特に30％では握りの見た目の調整が必要。[40％の実Play画像](play_lv1_40_dumbbells.jpg)
- **Workspace.Treadmills.Normal01**へ実際のCharacterを置き、既存TrainingManagerの自動占有判定からStrength増加を確認。40％は0→114（観測時間を固定しない試験）。30％は約4.067秒で0→14、0.5秒ごとの記録は0/2/4/6/8/10/12/14。LV1時点でも0→2→4があり、6から通常どおりLV2へ成長した。数値を直接Strengthへ加算して成功扱いにしていない。退出後IsTraining=false。
- 比較用の近接撮影だけ、一時LocalScriptでカメラを固定。通常カメラ確認とは区別する。

### 成長・再適用・死亡復帰

実行中のPlayerDataService.ApplyStudioStartLevelでLV32・140を設定し、**現行MuscleCharacterServiceそのもの**に組み立て後の基準寸法を取得・適用させた。LV32の実セッションStrength=50,835、LV140=43,910,429,172,515。LV必要量や加算式を変更していない。

| Body / LV | UpperTorso XYZ | UpperArm XYZ | HipHeight | 静止接地時の足箱の浮きの例 |
|---|---|---|---:|---:|
| 30％ / 32 | 2.736 / 2.761 / 1.572 | 1.944 / 2.089 / 1.898 | 2.145758 | 約0.122～0.135 |
| 30％ / 140 | 3.035 / 3.068 / 1.729 | 2.177 / 2.321 / 2.126 | 2.384176 | 約0.160～0.178 |
| 40％ / 32 | 3.648 / 3.682 / 2.096 | 2.592 / 2.785 / 2.531 | 2.861011 | 約0.162～0.179 |
| 40％ / 140 | 4.046 / 4.091 / 2.306 | 2.903 / 3.095 / 2.834 | 3.178901 | 約0.211～0.260 |

衣服の採用条件は未成立だが、LV1で移動・接地できたため、上位LVを診断目的で表示・接地確認した。LV32から肩・上腕が頭に対してかなり大きくなる。倍率の適否は保留し、独断で本番表を変更していない。[30％LV140の実Play画像](play_lv140_30.jpg)

- 同一Characterへの組み立て再呼出しはno-op。同じ成長段階の再適用でも上表の寸法が変わらない。
- 30％・40％ともLV140でHealth=0から既存死亡復帰を実行し、同じ上腕・胴寸法へ戻ることを確認。
- 復帰後はHead寸法・MeshId・FaceControls・髪のHead装着を保持。Shirt 1、Pants 1、髪1、HeadのNeck 1、固定顔Decal 0、Motor6D 15。サイズ累積・顔/衣服の消失・二重装着なし。
- 試験途中の肌色・Pastel切替は保存機能を作っていない。死亡比較前に基準の本人色・Simple服へ戻し、その基準状態の復帰を検証した。
- 実Play Consoleに今回のBodyに関するRuntime Error/Warning/Infinite Yieldはなし。撮影時のツールによるCameraType復元メッセージは記録。試作準備時のSourceAssetId読取権限制約はログ項目を除いて修正済み。

## コード・数値からの推定

- 3点とも正常読込後に標準衣服の模様が各筋肉面へ分断されるため、標準Classic UVとの不一致が主因と考えられる。実際の頂点UVは抽出していない。**専用UV/テクスチャ制作、または標準Classic UVへ修正する工程が必要**と判断する。別の無料服だけで解決できる根拠はない。
- 現行成長は胴・腕・脚を伸ばす一方、Head・Hand・Foot・Rootを固定し、HipHeightを単純に1.8/2.0倍する。これが成長後の足浮き、手首/足首の比率差の原因候補。接地補正を別途検証する必要がある。
- 通常顔のDecalもHeadの保持経路に残る設計。Hat/Face用装着点も保持するが、これだけで実装着・描画の合格とはしない。
- 40％はLV1で30％より頭・ダンベルとの比率が穏やか。30％はより小さい起点になる。どちらも衣服修正前であり、サイズの採用判断は保留。

## 未確認と正式採用に必要な修正

- 今回本人が装着していたのはDynamic Headと髪。本人の通常顔、帽子、顔アクセサリーの実装着例は未確認。全Dynamic Head、全表情、顔のトラッキング、全衣服の互換性も未確認。
- World2 Treadmill、Treadmill上のジャンプ停止、全段差、全カメラ距離、複数プレイヤー・端末別操作は未確認。今回のTreadmill実測はWorld1 Normal01のみ。
- 正式採用前に、(1) UV/専用衣服、(2) 成長後の接地、(3) 小さい手の握り位置・ダンベル寸法、(4) 頭と首の比率と通常顔/帽子/顔アクセサリー、(5) 生成の順序とアバターConstraint方式への対応を詰める必要がある。
- 全プレイヤー生成経路への正式導入、ショップ、本番選択UI、肌色/衣服保存、DataStore項目追加、Layered Clothingケージ制作は行っていない。
- 最大Body WinTrophy問題は据置。HP、Strength加算、LV必要量、報酬、戦闘判定の仕様変更なし。

## Studioに残したFull Pathと成果物

いずれも副本の**未保存Edit**に残す。通常生成経路のSource参照は0、StarterPlayer.StarterCharacterは存在しない。プレビューはAnchored・非衝突の静止展示で、操作キャラクターではない。

- Workspace.BodyPrototype_20261114.LV1_Body30_OriginalHead
- Workspace.BodyPrototype_20261114.LV1_Body40_OriginalHead
- Workspace.BodyPrototype_20261114.LV1_Body40_Pastel
- Workspace.BodyPrototype_20261114.LV1_Body40_Pastel_DarkSkin
- Workspace.BodyPrototype_20261114.LV1_Body40_Pastel_LightSkin
- ServerStorage.BodyPrototype_20261114.SourceBody — 元Bodyの保管コピー
- ServerStorage.BodyPrototype_20261114.CurrentAvatarReference — 本人の取得外観の参照
- ServerStorage.BodyPrototype_20261114.Clothing — 読み込んだ3衣服
- ServerStorage.BodyPrototype_20261114.BodyPrototype — 自動実行しないModuleScript

[実測記録](measurements.json) / [再現用コードと手順](../../prototypes/BodyPrototype_20261114/README.md)。画像は今回許可された比較資料として保存。ゲーム本体srcや既存SPECは変更せず、この試作フォルダと本報告フォルダだけを通常commit・origin/mainへpushする。
