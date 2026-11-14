# StarterCharacter 静的調査 — 2026-11-14

**判定：修正すれば利用候補。** 実物はR15の関節付き筋肉Bodyで、現在の成長処理が要求する部位名も揃っている。ただし、現在はプレイヤー用テンプレートとして配置されておらず、購入済みの頭・顔・髪を保持する経路、衣服、初期寸法の調整が必要。今回の判定は静的調査であり、操作・着用・成長をPlayで確認した判定ではない。

## 対象・作業範囲

- 当初指定された正本は **PlaceId 101572058398926**。開始時の接続一覧に正本がなかったため、代用して調査を始めず、その状況を報告した。
- その後のユーザー指示 **「副本でお願いします」** に従い、以下の副本の実物へ調査対象を変更した。正本の構成を示す報告ではない。

| 実取得した項目 | 値 |
|---|---|
| PlaceId | `126576845524886`（副本） |
| UniverseId / game.GameId | `10765181857` |
| 読み込まれたPlaceVersion | `627` |
| Studio接続ID | `967b1f14-eccd-45c3-885e-b33c5bfe4db7` |
| 調査時状態 | Edit、`RunService:IsRunning() == false` |
| 実物のFull Path | **`Workspace.StarterCharacter`** |
| `StarterPlayer.StarterCharacter` | 存在しない |
| `Workspace.Muscle` | 今回の副本には存在しない |

モデル・Source・プロパティを読み取っただけで、内蔵コードの実行、Moduleのrequire、モデル生成・縮小・拡大・移動、プレイヤーへの適用、Play/Stop操作はしていない。Save/Publish、保存GUI、本番データ操作、PR #1操作も実施していない。作成物は本報告書だけ。

Gitの開始時ローカルHEADは`c514bfe`。取得した最新origin/mainは`762215d`（Hisarino開発者用外観処理の解除）。既存作業フォルダには未追跡の`reports/Visual_Templates_Secret_VIP_Green_20260917.md`があるため保持した。既存チェックアウトのコードを変更せず、`762215d`を基準にした分離チェックアウトで本書だけを追加する。

## 1. 実物の構造と寸法【確認した事実】

```text
Workspace.StarterCharacter [Model / GetScale() = 1]
├─ Humanoid [R15]
│  ├─ Animator
│  ├─ BodyTypeScale = 1 / BodyProportionScale = 0
│  ├─ HeadScale / BodyWidthScale / BodyDepthScale / BodyHeightScale = 1
│  └─ Status
├─ HumanoidRootPart [Part、PrimaryPart]
├─ Head [MeshPart]
│  ├─ Neck [Motor6D]
│  ├─ NeckRigAttachment
│  └─ BTWeld [Weld、Head → Handle]
├─ Handle [透明Part]
│  └─ Decal [Front、rbxassetid://149816692]
├─ UpperTorso / LowerTorso [MeshPart]
├─ Left/RightUpperArm、Left/RightLowerArm、Left/RightHand [MeshPart]
└─ Left/RightUpperLeg、Left/RightLowerLeg、Left/RightFoot [MeshPart]
```

配下135インスタンス。MeshPart 15、Part 2、Humanoid 1、Animator 1、Motor6D 15、Weld 1、Attachment 30、Decal 1、NumberValue 6、Vector3Value 47、StringValue 15、Status 1。Bone、Constraint、WrapTarget、WrapLayer、FaceControls、Accessory、BodyColors、Shirt、Pants、ShirtGraphic、SurfaceAppearance、Script/LocalScript/ModuleScriptはいずれも0。

内蔵スクリプトがないため、その内部の外部require・外部コード依存もない。外部アセット参照はMeshIdと顔Decal。アセットの利用権限・内部UV・頂点ウェイトまでは検査していない。

### 元寸法

全体の外接寸法は **8.002 × 9.279 × 2.620 studs**。下表は今回の未変更実物の`Size`（X/Y/Z）。外接寸法とMeshPartの箱寸法であり、三角形から測定した実際の皮膚・足裏面ではない。

| Full Pathの末尾（親は`Workspace.StarterCharacter`） | Size X/Y/Z | MeshId末尾 |
|---|---|---|
| Head | 0.827 / 0.985 / 0.963 | 6072643459 |
| UpperTorso | 4.146 / 5.113 / 2.620 | 6072643648 |
| LowerTorso | 3.055 / 1.883 / 2.146 | 6072643475 |
| LeftUpperArm / RightUpperArm | 2.592 / 3.869 / 2.531 | 6072643612 / 6072643516 |
| LeftLowerArm / RightLowerArm | 1.829 / 2.365 / 1.770 | 6072643492 / 6072643493 |
| LeftHand / RightHand | 1.126 / 1.784 / 1.206 | 6072643538 / 6072643555 |
| LeftUpperLeg / RightUpperLeg | 1.776 / 3.241 / 2.005 | 6072643592 / 6072643589 |
| LeftLowerLeg / RightLowerLeg | 1.421 / 2.316 / 1.426 | 6072643481 / 6072643595 |
| LeftFoot / RightFoot | 1.029 / 0.808 / 1.890 | 6072643456 / 6072643466 |
| HumanoidRootPart | 2 / 2 / 1 | Meshなし |
| Handle | 0.700 / 0.700 / 0.250 | Meshなし |

- `Humanoid.HipHeight = 3.973626`、Health 100、WalkSpeed 16、AutomaticScalingEnabled=true、RequiresNeck=true、BreakJointsOnDeath=true。テンプレートの値であり、ゲーム実行後の最終値を測定したものではない。
- 全17 BasePartがAnchored=false、Massless=false、CanTouch=true、CanQuery=true、CollisionGroup=`Default`。
- CanCollide=trueはHead、UpperTorso、LowerTorso、HumanoidRootPart、透明Handle。腕・手・脚・足はfalse。15 MeshPartのCollisionFidelityはBox。
- Head・腕・手は黄系、胴は青系、脚・足は緑系の`Color`。材質はPlastic、全MeshのTextureIDは空。現状の色分けを「着用中の服」とは扱わない。
- 各部位にOriginalSize、関節AttachmentにOriginalPositionがあり、読取値は現在寸法・位置と整合。AvatarPartScaleTypeは`ProportionsNormal`。

### 関節・接地の静的整合

15 Motor6Dは、Root→LowerTorso、Waist→UpperTorso、Neck→Head、左右のShoulder→UpperArm→Elbow→LowerArm→Wrist→Hand、Hip→UpperLeg→Knee→LowerLeg→Ankle→Footの接続を持つ。参照切れはなく、全15部位がRootへ接続されている。

現在姿勢の`Part0.CFrame * C0`と`Part1.CFrame * C1`の位置差は最大約0.000031 studs。Root中心からFoot箱下端まで4.973625 studsで、`HipHeight + Root.Size.Y/2 = 4.973626`とほぼ一致する。**これは初期の静止姿勢の数値確認であり、床との実接触、歩行時の継ぎ目、拡大後の接地の合格判定ではない。**

30 Attachmentはすべて関節用の`*RigAttachment`。HeadにはNeckRigAttachmentしかなく、HairAttachment、HatAttachment、FaceFrontAttachment、FaceCenterAttachmentがない。手にもGripAttachmentはない。

### 配置・参照とMuscleとの関係

`StarterPlayer`直下にないため、名前がStarterCharacterでも現在の自動スポーン用テンプレートとしては配置されていない。現行の読込経路と関連Sourceに、このWorkspaceモデルを選択・複製する参照は見つからなかった。Workspace配下スクリプトにも`StarterCharacter`の文字列参照はなかった。動的に名前を組み立てる全コードの不存在まで保証するものではない。

StarterPlayer配下の`StarterCharacter`を全プレイヤー用モデルにするのはエンジンの機能だが、今回移動・適用していない。[公式StarterPlayer仕様](https://create.roblox.com/docs/reference/engine/classes/StarterPlayer.md)

今回`Workspace.Muscle`はないため、現物2体の同時比較はできない。直前の別調査で確認したMuscleは6 Mesh・関節なしでMeshIdも異なる。今回の15 Mesh・R15モデルはその構成とは別物であり、名前変更や制作経緯までは未確認。

## 2. 頭・顔・髪・肌色・服

### 現在の経路【確認した事実】

- `StarterPlayer.LoadCharacterAppearance = true`。
- `ServerScriptService.Systems.Controllers.InitialSpawnFacing`は`ServerScriptService.Services.LobbySpawnService.Start()`を呼ぶ。
- 同Serviceは実行時にCharacterAutoLoadsをfalseにし、`LoadCharacterAsync()`による生成・死亡後の再生成を管理する。Edit時に読み取ったPlayers.CharacterAutoLoadsはtrue。
- LoadCharacterAsyncの完了後にSpawnEngineReadyを立て、MuscleScaleReadyを待ってLobbyへ配置する。
- 今回読んだ関連Sourceには、Workspace.StarterCharacterへ購入済みの頭・顔・髪を移植する処理はない。モデル自体にもその処理はない。
- `StarterPlayer.LoadCharacterLayeredClothing`、`Workspace.MeshPartHeadsAndAccessories`、`StarterPlayer.AvatarJointUpgrade`、`StarterPlayer.CharacterRigType`は今回のAPIで読めず、設定値を断定していない。

現在の通常ロードは本人の外観を読み込む設定だが、独自Bodyへ採用した後も同じ外観が自動的・完全に保持されるとは判断しない。[LoadCharacterAppearanceの仕様](https://create.roblox.com/docs/reference/engine/classes/StarterPlayer.md#property-starterplayerloadcharacterappearance)

### 保持に必要な条件【採用時の対応案・未実装】

| 対象 | 実物の状態と必要な対応 |
|---|---|
| 購入済みの頭本体 | 現在は固定MeshのHead。本人のHeadを保持・移植するか、本人の外観情報と専用Bodyを組み合わせて生成する経路が必要。首の位置・大きさ・Neck接続を合わせる |
| 通常の顔 | 現在の顔画像は`Head.face`ではなく、`Head.BTWeld`で接続された`Handle.Decal`。本人の顔を使うなら、この固定顔を重ねず、通常顔のHead内Decalを維持する。FaceアセットIDとDecal/Image IDは同じ扱いにしない |
| Dynamic Head | 現物にFaceControls/Boneはない。本人のHeadを顔制御・メッシュ内部の表情データごと保持する必要があり、顔画像だけのコピーでは保持できない |
| 髪・帽子・顔アクセサリー | 本人のAccessoryと、対応するHead側Attachment・接続を保持する。現物には頭部の装着点がない。眼鏡などの顔Accessoryと顔Decalは別に扱う |
| 肌色 | 現在の固定色をそのまま採用すると本人の肌色にはならない。BodyColors/外観情報の色を専用Bodyへ対応させ、ズボン等の着色と分離する |
| 服 | 全衣服を無条件に適合させる保証はできない。ClassicとLayeredで分け、保持対象と専用衣服への置換方針を決める |

外観情報はHumanoidDescriptionで頭・顔・アクセサリー・色等を取得できる。ただし、そのまま全項目を適用すると専用Bodyの部位や倍率も置換対象になるため、Bodyの所有者を明確にする必要がある。[公式HumanoidDescription仕様](https://create.roblox.com/docs/reference/engine/classes/HumanoidDescription.md)

Dynamic Headの表情・装着点・ケージは別要素である。本人の頭を保持する場合は、不要な「固定頭への顔画像移植」でそれらを失わない設計にする。[公式Dynamic Head仕様](https://create.roblox.com/docs/avatar/dynamic-heads)

### ズボン等の準備物【条件付き提案】

| 方法 | 判断 |
|---|---|
| 既存Classic Shirt/Pants | R15の部位名は揃うが、標準衣服テンプレートに対応するUVかは未確認。TextureIDが空でもUVがないとはいえない。まずClassic Pantsを試着する検証が最小で、正常なら既存・専用Classic Pantsを使える |
| 専用テクスチャ | 標準UVに合わない場合の有力候補。LowerTorso、左右UpperLeg/LowerLegに合うUV資料とズボン用画像を用意する。肌を見せる領域・股・腰・膝の境界を合わせる。身体形状に直接載るため追加の衣服関節は不要だが、UVと画像の制作は必要 |
| 専用3D衣服 / Layered Pants | 厚みのあるズボンや購入済みLayered Clothingも対応したい場合の候補。現物にWrapTarget/ケージがなく、そのままの着用適合は未確認。Bodyのケージ、衣服側WrapLayer・ケージ・変形設定・接続点を準備するため、追加作業が最も多い |

したがって、**まずUVを確認してClassic Pantsを評価し、不適合なら専用Body用テクスチャを検討する**。今回の静的確認だけで特定のズボンが使えるとは断定しない。Layered ClothingはBody側WrapTargetと衣服側構造の両方が必要。[WrapTarget仕様](https://create.roblox.com/docs/reference/engine/classes/WrapTarget.md)、[Layered accessories仕様](https://create.roblox.com/docs/avatar/layered-accessories)

### HisarinoHairAutoEquip

今回の副本DataModel全体で`HisarinoHairAutoEquip`というインスタンスは見つからなかった。したがって、Studio現物のEnabled/Sourceは「対象なし」であり、Enabled=falseを確認したとは記録しない。この名前のスクリプトが今回の副本で外見を変更している証拠はない。

最新GitHub mainの`762215d`では、`src/ServerScriptService/HisarinoHairAutoEquip.server.luau`はコメントのみで実行コードがない。古いローカルHEADには元衣服の削除・専用外観装着・手足透明化があるが、それを現在のStudio実態と取り違えない。解除方針は維持し、今回スクリプトの追加・有効化・無効化・同期はしない。

## 3. LV10段階成長との互換性

**実物から読んだSource**：`ServerScriptService.Config.MuscleScaleConfig`、`ServerScriptService.Systems.Controllers.MuscleCharacterService`、`ServerScriptService.Services.PlayerDataService`のGetLevelState/Level更新部分、`ServerScriptService.Systems.Controllers.PlayerDataController`、`ServerScriptService.Services.LobbySpawnService`。

- 閾値はLV **2 / 4 / 8 / 16 / 32 / 50 / 70 / 90 / 115 / 140**。読み込み済み保存データのLevelを使い、手動SelectedSizeTierを優先する。
- 成長対象のUpper/LowerTorso、左右Upper/LowerArm、左右Upper/LowerLegはすべて存在し、直下の名前も一致。頭・手・足先・Rootは対象外。
- Characterごとに元Size、Attachment.Position、Motor6D.C0/C1、HipHeightを取得し、元値から再計算する。今回のRigはMotor6D方式なので、この経路の対象になる。
- 外観・Bodyの組み立てと初期縮小が完了してから基準値を取得する必要がある。後から頭や部位を交換すると、元Part/関節を保持する現在のキャッシュと不整合を起こし得る。
- AutomaticScalingEnabled=true、OriginalSize/OriginalPositionもあるため、外観読み込みによるエンジン側の再スケールと独自成長の順序確認が必要。

### 現行表をそのまま掛けた場合の数値例【机上計算・適用していない】

読取Sizeと現行係数の単純計算。将来の採用倍率・承認値でも、成長後の実測でもない。

| LV / 段階 | 上腕 X/Y/Z | UpperTorso X/Y/Z | HipHeight |
|---|---|---|---:|
| 1 / 0 | 2.592 / 3.869 / 2.531 | 4.146 / 5.113 / 2.620 | 3.974 |
| 32 / 5 | 6.480 / 6.964 / 6.326 | 9.121 / 9.204 / 5.240 | 7.153 |
| 140 / 10 | 7.258 / 7.737 / 7.086 | 10.116 / 10.227 / 5.764 | 7.947 |

初期状態ですでに大きいため、上腕2.80/Y2.00を無条件に採用しない。手・足先・頭を固定したまま胴と四肢が変わるので、手首・足首・首の輪郭差、肩・股の重なり、衣服の伸び、頭に対するBody比率を確認する。HipHeightの単純倍率と実際の足裏位置が成長後も一致するかは未確認。

既存Body報告の最大時の足浮きは別Rigの結果であり、本モデルの合否へ転用しない。最大BodyのWinTrophy問題は既知の据置事項。接触条件・報酬処理は今回調査・修正の対象に広げていない。

### 「とても小さい体型をスタートにする」追加相談

R15の部位・関節が一体として構成されているため、**初期Bodyを小さくして、その寸法をLV1の基準にすることは構造上の候補になる**。今回は縮小実験を行っていない。

- 現物全体を仮に等比40％にした場合の外接寸法は約3.201 × 3.712 × 1.048 studs、30％なら約2.401 × 2.784 × 0.786 studs。単純な算術上の目安であり、決定した初期サイズではない。
- この全高の目安は頭を含む全体の等比縮小。本人の頭を別の大きさで保持する構成では全高が変わる。「購入アセットを保持すること」と「頭を元の寸法に固定すること」は別に決める。
- 採用時は、初期Body・頭・首・装着点・HipHeightを整えた後にMuscleCharacterServiceへ基準寸法を渡す。死亡復帰で現在サイズへ縮小率を繰り返し掛けない。
- 小さい手と既存サイズのダンベル、Rootと設備/戦闘判定、段差・ジャンプ・カメラを確認する。見た目を小さくするだけで全操作が成立するとは扱わない。
- 10個の成長LVは維持し、初期サイズと各段階倍率はBody実寸・購入済み頭との比率を見て再評価する。今回、新倍率は承認・実装していない。

## 4. 直接影響するゲーム機能

| 現物のFull Path | 依存と採用前確認 |
|---|---|
| `StarterPlayer.StarterCharacterScripts` / モデル内 | 現在いずれにもAnimate等のScriptはない。R15骨格はあるが、プレイヤー生成時の標準Animate・操作スクリプト供給をPlayで確認する |
| `StarterPlayer.StarterPlayerScripts.World.TreadmillRunClient` | Humanoid.Animatorへ走行アニメーション`913376220`を再生。関節名は対応候補だが、筋肉形状の屈伸・めり込みは未確認 |
| `ServerScriptService.Services.TrainingManager` | World1はR15のFoot、World2はRoot/HipHeightと同じ設備の支持面等を利用。走行表示だけでなく生Strength増加、成長・ジャンプ・退出時の停止を確認する |
| `ServerScriptService.Systems.Controllers.DumbbellDisplayController` | 左右HandのCFrameと固定offset `(0,-0.15,0)`へWeldConstraintで装着。現在の処理はGripAttachment不在で即失敗する構造ではないが、太い/小さい手の握り位置は再確認が必要 |
| `StarterPlayer.StarterPlayerScripts.Combat.CombatClient` | Animatorで左右パンチ`121823319369216` / `87608603137173`を再生。筋肉Bodyでの肩・肘・胴の交差は未確認 |
| `ServerScriptService.World.EnemyManager` | Rootに固定した戦闘Trigger（7×5.5×4、前方3 studs）を使用。Bodyが大きく/小さくなってもTrigger寸法は自動一致しない。壁/Bossへ接近できるかと見た目上の届き方を確認する。ダメージ・範囲を独断で変更しない |
| `StarterPlayer.StarterPlayerScripts.World.SpawnFacingCameraClient` | HumanoidをCameraSubjectとし、Root/MuscleHeightScaleで距離を補正。基礎サイズが変わるためLV1から画角・頭位置を確認する |
| `ServerScriptService.Services.LobbySpawnService` | Root/HipHeightによる配置、ロード完了→成長完了→Lobby移動、死亡時の再生成を管理。独自Bodyと本人の外観の組み立ても同じ生成順序へ整合させる |

## 5. 採用前の最小修正・検証案【今回は未実施】

1. 元モデルを保持したまま、採用候補の初期寸法・頭の比率・露出部の肌色・衣服方針を決める。透明Handle上の固定顔とその衝突は、本人Head保持方式と両立するよう整理する。
2. R15部位/関節を維持して、本人Head（通常顔またはDynamic Head）と頭部Accessoryを組み合わせる。必要な装着Attachmentを揃え、固定Bodyを外観ロードで上書きしない生成経路を作る。
3. UVを確認し、Classic Pantsが使えるならそれを優先。不適合なら専用テクスチャとUV資料を用意する。3D衣服が必要な場合だけケージ/Wrap対応へ進む。
4. 初期縮小・外観構築→元寸法取得→LV成長という順序へ接続する。現在の2.80/2.00の流用可否は描画と接地を見て決める。
5. 隔離Playで以下の代表ケースを確認する。本番データ・実課金は使用しない。

| 代表状態 | 最小確認内容 |
|---|---|
| LV1 | 小さい初期体型の比率、通常Head/購入済みDynamic Head、髪・帽子・眼鏡、肌色、ズボン、足裏・首・手首、歩行・ジャンプ・カメラ、UI出現 |
| LV32 | 中間成長、肩・肘・膝・腰・股の継ぎ目、衣服/髪の追従、ダンベル装着、World1/2 Treadmillの生Strength増加と開始停止、壁/Boss接近・攻撃 |
| LV140 | 最大での接地・視界・設備利用・Bodyと衝突の差。通常顔とDynamic Head双方で描画。既知WinTrophy問題と新たな悪化を区別し、Trophy修正へ広げない |
| 状態遷移 | LV1→32→140の飛び越え、同じLVの再適用、AUTO/手動、死亡復帰、Lobby帰還、World1→2→1。サイズ累積・外観二重装着・接続残留・基準値の取り直し漏れがないこと |

## 6. 未確認事項と終了記録

- 今回はプロパティ・階層・Source・関節位置の静的調査のみ。Play、アバターへの適用、縮小/拡大、衣服試着、実機操作、端末相当プレビューは実施していない。
- UV・頂点/ケージ・スキニングの内部データ、Classic衣服の描画、購入アセットの読込権限/ロード成功、標準Animate挿入、Dynamic Head移植、足浮き・衣服破綻・戦闘/設備動作は未確認。
- 対象はユーザーの追指示による副本。正本のStarterCharacter、正本との差分、正本への反映は未確認・未実施。
- 他のログにあった外観読込エラーや、直前のPlay不調を、この未適用のWorkspaceモデルの不具合とは断定しない。
- 元チェックアウトの既存編集は保持。今回のcommit対象は`reports/StarterCharacterInvestigation_20261114/REPORT.md`だけ。関連SPEC・ゲームコード・モデルファイルは変更しない。
- Studioは開始時と同じEditを維持。モデル・Source・設定の書込み、検証補助の挿入、Save/Publish、PR #1操作はしていない。検証補助や画像ファイルは作成していない。
- 終了時の再読取で、モデルの135インスタンスの階層・寸法・接続・記録対象プロパティ、およびMuscleScaleConfig、MuscleCharacterService、InitialSpawnFacing、LobbySpawnService、PlayerDataController、DumbbellDisplayControllerの6 Sourceが調査時と一致。LoadCharacterAppearance=true、Edit時CharacterAutoLoads=trueも維持していた。
