# UI_SPEC — 現在のUI仕様正本

## 2026-09-19 — Merge STEP 2 card visual polish

- Cardは固定5 Star / Item画像 / `×N`を維持し、最低幅を優先して最大4列・中央配置・20px間隔へ変更。少数Cardも中央へ配置する。Scrollは維持。
- 短いLandscapeではSTEP 2の選択パネルだけをInventory Tabs下の画面安全領域へ広げる。STEP 1 / STEP 3へ戻ると元のサイズ・位置へ復帰し、Inventory shellや他Tabの配置は変更しない。
- Item画像の内側四角背景は透明化。Cardは旧Bright Purpleを最低明度とする明るいグラデーション。FireはCoral、IceはCyan、ElectricはGoldのBorder / 薄い外周Glow / ごく弱い画像背面光を使う。
- Starは引き続き`ItemMaster.RarityRank`が正本。固定5 Slotを均等配置し、有効StarはGold本体・Dark Gold輪郭・上側Highlight・薄いYellow Glow、未到達StarはLavender。追加画像AssetやFontは使用しない。
- 所有数はFredokaOneの白文字とDark Purple Stroke、通常30px / 短いLandscape28px。Card名・Element名・Rarity名・Owned:は表示しない。
- Merge可能の軽い強調は、既存Server応答`recipe.CanMerge`と既存のfresh / pending状態からBorder明度・太さ・Element Glowを更新する。Countによる別のMerge判定を追加しない。Starと所有数の色は変えない。
- Activated後はGold Border 4px / Soft Gold Glow / SurfaceのUIScale 1.04で約0.18秒Feedbackを表示してSTEP 3へ進む。Gridの実寸は変更せず、連打・BACK・再表示で遅延遷移を二重実行しない。
- Studio実測はPC 230×224 / 画像146px、iPhone 17 Pro Landscape 211×143 / 画像95px、Fire HD 10 Landscape 194×224 / 画像146px、各3列。Star領域は通常40px高 / 短いLandscape34px高。並び順・Recipe・Server処理・STEP 3 Previewの正本は従来どおり。

## 2026-09-18 — Merge STEP 2 item cards

- STEP 2 cards show only five fixed rarity-star slots, the item image, and `×N` owned count. Item type, element name, rarity name, and the `Owned:` prefix are hidden.
- All five star positions remain fixed. Active stars use the Bright Merge gold and inactive stars use a visible lavender. The filled count reads `ItemMaster.RarityRank` directly; no UI-only rarity table is defined.
- The item image is enlarged and keeps the existing bright Fire, Ice, and Electric image backgrounds. Cards retain the bright purple/lavender palette and use a gold edge for press/selection feedback.
- The existing Fire → Ice → Electric, rarity, type, and ItemId ordering and the server-provided merge recipe eligibility remain unchanged. STEP 1 and STEP 3 layouts remain unchanged.
- Responsive verification: PC cards are 150×158 with 96px images; iPhone 17 Pro landscape cards are 160×138 with 76px images and scroll; Fire HD 10 landscape cards are 151×158 with 96px images. Five stars fit without overlap, and `BACK` does not overlap `SELECT 1 ITEM`.

## 2026-09-18 — Administrator Treadmill purchase entry

- Tredmill01の既存TrainingZoneを購入Triggerとして再利用。未所有Playerは乗るだけでRoblox Game Pass購入Promptへ進み、Eキー / Tap用Interact Buttonは表示しない。
- 1回の入場につき最大1Prompt。Cancel後のZone内滞在では再表示せず、完全退出後の再入場で未所有なら再表示する。Character変更も新しい入場として扱うが、スポット外Respawnでは表示しない。
- Premium購入専用ProximityPromptは現行Treadmill群に存在しないためObject削除なし。他Shop / Aura Prompt、Treadmillの見た目・案内・VisualRoot / VisualTemplateは変更しない。

## 2026-09-18 — Double Win spot interaction

- World1DoubleWinShopのPedestal購入エリアへ入ると、未所有Playerに既存Roblox Game Pass購入Promptを表示。PC / Smartphone / Tablet共通でE / Tap不要。
- Trophy.Handle.PurchasePromptだけをGamePassController起動時に無効化する。従来の距離12studのTriggered接続を入場検知へ置換。Model / Pedestal / Trophy / 看板の位置・見た目は維持。
- 1入場につき最大1Prompt。Cancel後その場に留まっても再表示せず、退出・再入場した未所有Playerだけ再試行できる。他のShop / Aura等のProximityPrompt、右HUD購入Button、Shop UIは変更しない。


## 2026-09-17 — Item Effect HUD

- ItemEffectHUDClientがStrengthLevelHUDの直上8pxに表示専用の横一列を生成。Protein→Glove→TrainingBeltの順に装備中だけを中央配置。既存Level表示のFontFace・白文字・暗色TextStrokeを使用する。既存PotionStatusが同じ位置を占める場合はその上へ避ける。
- Asset：Protein_miniicon=rbxassetid://105488661849761、Glove_miniicon=rbxassetid://108415780326588、Belt_miniicon=rbxassetid://111026808967442。新画像Assetなし。
- Smartphone LandscapeはIcon28px / Text18px、PC・TabletはIcon32px / Text20px。内容の実測幅を使い、未装備分の空白を残さない。Level Gauge / Auto Tap / 左右HUDの既存配置は変更しない。
- Protein「+N STR」は静止。Glove「+N% DMG」はServerのGloveApplied=trueの実命中時にIconだけ5px上へ0.09秒、0.16秒で戻す。戦闘終了・装備変更・死亡で停止して原位置へ戻す。
- TrainingBelt「+N Tier」は装備・生存・受理済みTraining中だけIconを4px、片道0.55秒で往復。退出・Unequip・死亡で停止・原位置復帰。Textと行の配置は動かさない。
- InventoryのEquip / Unequip / Best Equip / Rarity変更応答で即時更新。初回・Respawnで状態取得し、未ロード時は再試行。取得中に新しい装備応答が届いた場合は古い取得結果で上書きしない。


## 2026-09-17 — Merge 3STEP UI

- Merge Tabを開くたびSTEP 1。中央に大きな「SELECT ITEM」と「Merge 3 identical items to upgrade」。重複MERGE見出しは表示せず、Buttonと説明を中央配置。Xは既存Inventoryの閉じる操作を維持。
- STEP 2は「SELECT 1 ITEM」とItemIdごとに1枚の大きなカード。画像・Item名・Element名・Rarity名・Owned数を表示。Serverが返した有効レシピのうち所持数1以上を表示し、空なら「NO ITEMS AVAILABLE」。
- Sort Buttonと手動3素材選択を廃止。明示Element Priority Fire=1 / Ice=2 / Electric=3、Master.RarityRank昇順、Master.Kinds順（Protein / Glove / TrainingBelt）、ItemId順で安定整列。Legendaryは正規レシピがないため一覧に出ない。
- STEP 3は選択Item、3 Socket、充足数、MERGEを表示。基準ItemのServer数量から最大RequiredCount枠を自動表示し、不足枠は「?」。CanMerge=trueかつ最新状態取得済み・未送信中のみ実行可能。保存中等のServer拒否理由も表示。成功文言を維持し、同じ基準Itemの最新数量を再取得する。
- BACKはSTEP 3→2→1。STEP 3の重複MERGE見出しも表示せず、最終実行MERGE Buttonは維持。新Merge UI内の状態・エラー文言も英語に統一。元の日本語は生成Scriptの直接定義であり、ゲーム全体のLocalizationは変更しない。Tab再表示はSTEP 1に戻る。表示中は2秒ごとにもServer状態を再取得し、Drop / Reward / Save lockを反映する。取得失敗時は実行無効。
- MergeFlowだけで親Fit倍率を打ち消し、文字・操作領域を画面pxで確保。カード高150を維持。高さ340px未満のLandscapeでは画像とSocketを横配置し、★UpgradeをBACK横へ置く。通常の高さでは画像→★Upgrade→Socket→充足数→Status→MERGEを中央に縦配置する。
- 既存TemplateのFrame / UICorner / UIStroke、InventoryのFont / TextStroke / Gradient、Element色、既存Item画像を再利用。参考MergeUI01.png / MergeUI02.pngは閲覧のみでAsset追加なし。
- 既存MergePanelは非表示の互換レイアウトノードとして保持し、ResponsivePanels・Inventory shell・他Tabを変更しない。[端末別実測・検証](../reports/Merge_UI_20260917.md)。


## 2026-09-17 — Studio最新版ライブラリの保存

- AuraVisualTemplates（17）：Blue_Aura1/2/3/4、Green_Aura1/2、Hyper_Aura1、Pink_Aura1/2/3/4、Purple_Aura1、Red_Aura1、Secret_Aura1、Vip_Aura1、Yellow_Aura1/2。
- TreadmillVisualTemplates（10）：Blue_Aura1/2/3/4、Green_Aura2、Premium_Fire、Secret_Aura1、Vip_Aura1、Yellow_Aura1/2。
- assets内の同名rbxmはFolder全体の保存物。Importする場合は同名Folderを重複配置しない。Player用とTreadmill用は独立Instance。Template編集→Config.VisualTemplateへ名前指定→Playの既存手順を使用する。

## 2026-09-17 — Treadmill Effectの手動追加

1. ReplicatedStorage.TreadmillVisualTemplates.Premium_Fire等のModelをDuplicateし、名前を変更。
2. Rootを基準にEmitter用Part / Attachment / ParticleEmitterをStudioで編集。Rootは透明な配置基準、PrimaryPart=Rootを維持。Scriptは入れない。
3. TreadmillConfig.Types.Normal / Rebirth3 / Rebirth7 / PremiumのVisualTemplateへTemplate名を指定。
4. Play確認。空文字ならEffectなし。倍率・価格・利用条件は変更しない。

配置は各TreadmillのTrainingZone.VisualRoot（未作成時は共通処理でAttachmentを追加）を基準とする。Template内のPart位置・Attachment.Positionを編集すると相対位置がそのまま反映される。Particleの広がりは元のcarrier PartサイズとEmitter設定で調整し、Luaへ設定値を転記しない。

Premium_FireはRootとAuraEmitterPartを持ち、Attachment=0 / ParticleEmitter=3 / Beam=0 / Trail=0 / Light=0 / Highlight=0。元のEmitter発生範囲22×0.7×10studと配置・設定を保持する。Runtimeの表示先はTredmill01.PremiumAuraで、既存PremiumAuraを置換するため二重表示しない。青・緑・通常用の新デザインは作成していない。

## 2026-09-17 — Aura Visual追加手順

1. ReplicatedStorage.AuraVisualTemplates内のModelをDuplicateし、Template名を設定する。
2. Root / その他透明carrier Part配下のAttachment・ParticleEmitter・Light等をStudioで編集する。PartのSizeは発生範囲、Rootとの相対配置はAura全体の配置。Rig・Scriptは入れない。
3. ModelのPrimaryPartをRoot、AttachTo属性を装着先（標準UpperTorso）にする。
4. ReplicatedStorage.Config.AuraConfigの該当Aura定義へVisualTemplate="Template名"を指定する。Price / StrengthBonusとは独立。
5. PlayでEquip / Unequip / 再Equip / Respawnを確認する。Git保存を更新するときはAuraVisualTemplatesを標準の.rbxm Modelファイルとしてassets/AuraVisualTemplates.rbxmへ書き出す。

TemplateはModel単位でCloneされる。EmitterのSize / Rate等をScript側で補正しない。元Workspace素材は比較用として残す。TemplateごとのSourcePath属性でコピー元を確認できる。

| Template | Attachment | ParticleEmitter | Beam | Trail | Light |
|---|---:|---:|---:|---:|---:|
| Pink_Aura1 | 0 | 1 | 0 | 0 | 0 |
| Pink_Aura2 | 0 | 1 | 0 | 0 | 0 |
| Pink_Aura3 | 0 | 14 | 0 | 0 | 0 |
| Pink_Aura4 | 5 | 23 | 0 | 0 | 0 |
| Red_Aura1 | 2 | 22 | 0 | 0 | 1 |
| Hyper_Aura1 | 2 | 7 | 0 | 0 | 1 |
| Green_Aura1 | 6 | 15 | 0 | 0 | 0 |
| Purple_Aura1 | 6 | 15 | 0 | 0 | 0 |

Redには追加でHighlight1個を保持。Pink_Aura3は元noob.Torso直下の14EmitterをRoot（2×2×1stud）へ保持するため、Particle用Attachmentは0個。

命名差：WorkspaceにPink_Aura1 / Pink_Aura2は存在しなかったため、既存vfx pack.VFX.PinkAura / PinkAura2を対応元素材と仮定してTemplate化した。確認質問は作業時点で未回答。Greenと紫はVFX Auras配下。紫の実名はPurple_Aura1で、Puple_Aura1は見つからなかった。元Objectのrenameはしていない。


## 2026-09-16 — Auto Tap toggle / manual input

- StarterPlayerScripts.UI.AutoTapClientがPlayerGui.StrengthGui.StrengthLevelHUD.LevelPanel.AutoTapButtonを生成。ボタンは1つで「Auto Tap」「ON / OFF」の2行表示。ONは金色、OFFは灰紫色の縦グラデーション。既存LevelPanelのUICorner / Outlineと文字Font / TextOutlineを再利用する。1回のActivatedでServerへToggleを要求し、保存状態のAttribute通知で表示更新する。
- AutoTap.pngをレイアウト参考とし、LevelPanelの右端から8ローカルpx空けて下端を揃える。AnchorPoint=(0,1)、Position=(1,8,1,0)。LevelPanelの子としてHUDの座標系・UIScaleを継承し、AbsoluteSize変更時にHUDLayout.GetLocalSizeを再利用する。高さ=clamp(ゲージのローカル高さ,44,54)、幅=round(高さ×1.35)。独立した画面上部配置へ戻さない。既存HUD・LeftMenu・Touch Zone・LandscapeSensorは変更しない。
- OFF時の左クリックとTouchTapInWorldを受付。処理済み入力、Robloxメニュー、TextBoxフォーカス、位置に重なるGuiButton / TextBox / ScrollingFrame / ActiveなGuiObjectとその子孫を除外。ドラッグやThumbstick移動をTraining Tapにしない。
- ReplicatedStorage.Remotes.AutoTapRequestの要求はToggle / Tapのみ。Clientは入力頻度を抑え、Serverが最終的なTraining / Combat / Treadmill分岐とRate Limitを決定する。
- Manual Attackは既存左右Punch AnimationをSpeed=2.0で停止・再スタートする。DamageはAnimation終了を待たない。Punch SEは既存1個のSoundを停止・再生し、Soundを連打ごとに増殖させない。ON時の演出は維持。
- 配置変更後のPlay実測：Desktop1365×768で70×52px、iPhone 17 Pro Landscape749×361で59×44px、iPad Pro M5 13-inch Landscape1374×1031で59×44px。各端末でゲージ右端との間隔8px・下端差0px。Phone / Tabletで他の可視GuiButtonとの重なり0、3端末でON→OFF→ONを確認。実機スマホの最終的な見た目評価はユーザーが行う。

## 2026-09-16 — Tutorial Guide floor-only arrows（Completed）

- TutorialGuideClientの床候補をGeneratedMap内の正規Floor / ConnectorFloorへ限定。TrainingZone、Terrain、Asset内の同名Floorを候補にしない。
- 矢印の中心・両腕の端点・中点・縁を検査し、床外または可視Assetの領域にかかる矢印一組を非表示にする。CanQuery=falseのマットも遮蔽物として扱う。
- Start / Goal / 経路 / 間隔 / 形状 / 更新周期 / Tutorial進行と保存仕様は維持。
- Studio再起動後の最終Playで床表示、Treadmill / 非Queryマット / 操作パネル / Wall / Character / Enemy上の非表示、床への復帰時の再表示を確認。実経路28組の判定不一致0、表示矢印の床高さ不一致0、OutputのError / Warning / Infinite Yieldなし。Tutorial進行コードは変更なし（全Tutorial完遂は未検証）。[確認記録](../reports/Tutorial_Floor_Only_20260916/build_report.md)。

Version: 1.1 / 監査・更新日: 2026-09-15

## Treadmill multiplier billboards（2026-09-16）

既存の各機器Strength / Rebirth表示を維持し、青2台へ「×2」1個、緑2台へ「×3」1個の大型BillboardGuiを追加する。実Multiplierと既存Assignmentsを使用し、2台のTreadmillUIDisplayの中央から配置。文字はBeltColor、縁取りはMatColorを再利用する。

`ReplicatedStorage.Config.TreadmillConfig.MultiplierBillboard`が設定正本。MaxDistance=100stud、StudsOffset=(0,12,0)をワールド座標で加算、Size=(16,10)stud × TextScale=1.5で最終Canvasは24×15stud。Config編集後はPlay再起動で反映。

Client専用LocalScriptが本人のPlayerGuiとローカル透明Anchorへ生成し、標準MaxDistanceで遠距離非表示・Camera追従を行う。毎Frameの独自距離判定は持たない。Serverが受理したTrainingTreadmill名を本人へ通知し、Configの実Multiplierが2なら×2だけ、3なら×3だけを非表示にする。未利用・通常・Premium利用中は両方を有効にし、100studの距離条件に従う。他PlayerやServer共有Enabledは操作しない。Streamingで片方が欠ける場合はその組の表示を除去し、両方が揃うと再生成する。

初回の近距離・遠距離・斜めCamera確認は[初回報告](../reports/Treadmill_Multiplier_Billboards_20260916/build_report.md)。利用機種別の分岐と遠距離非表示を再確認済み。複数Client同時接続は未実施。[今回の検証](../reports/Treadmill_Availability_Guides_20260916/build_report.md)。

## Treadmill availability guides（2026-09-16）

TreadmillガイドはPlayerが使用可能なTreadmillだけ表示され、使用可能な間は常時流れる。乗車の有無は条件にしない。TrainingManager.CanUseTreadmillの結果を既存0.2秒Zone走査でPlayerのTreadmillAvailable_<Model名>属性へ反映し、本人のClientのみ表示する。通常は表示、+3はRebirth3以上、+5は5以上、Premiumは既存GamePass所有・効果有効判定に従う。表示側に利用条件を複製しない。利用不可ではSurfaceGuiを完全非表示にしてTweenを停止する。

TreadmillGuideClientが実ベルト上にローカル表示専用面とSurfaceGuiを生成する。TutorialGuideClientと同じ2本の線によるChevron形状を採用し、クリップ内の固定個数のFrameをLinearの繰返しTweenで流す。GUI下方向を既存ベルトのLookVectorへ揃える。毎Frameの生成・破棄はなく、表示面はCanCollide/CanTouch/CanQuery=false。既存機器UI、色、マット、物理設定は変更しない。

`ReplicatedStorage.Config.TreadmillConfig.Guide`でEnabled=true、Speed=4stud/秒、Transparency=0.15、Size=(4,1.6)stud、Spacing=4stud、Thickness=0.25studを設定。NormalColor / BlueColor / GreenColor / PremiumColorも同Configへ集約。変更後はPlay再起動で反映する。利用可否と利用機器属性は表示用の一時状態であり、DataStoreへ保存しない。

## Treadmill reward colors（2026-09-16）

TreadmillConfig.StrengthColorsがTreadmill表示色の正本。実Trainingに使う同ConfigのMultiplierを直接キーにし、各値はBeltColor / FrameColor / MatColorを分離する。Multiplier 2はBeltColor RGB(55,145,255)・FrameColor RGB(20,65,150)・MatColor RGB(8,25,65)、Multiplier 3はBeltColor RGB(70,200,110)・FrameColor RGB(20,100,55)・MatColor RGB(8,40,22)とする。別の表示用Strength値は持たない。

対象Modelのベルトには明るいBeltColor、コンソール上面・外枠、側面、支柱、上部横梁、前後フレームには濃いFrameColorを適用する。各2台のマットはさらに濃いMatColorの1枚のRuntime Part（28×0.2×24stud）で表示し、旧4枚は非表示で保持する。既存×2 Strength / ×3 StrengthとRebirth必要数表示は維持し、大型倍率表示は上記の独立したBillboardで追加する。Normal / Premium機器はStrengthColorsに定義がないため既存の見た目を維持する。Config編集後はPlayを再起動して反映。[共用マット検証](../reports/Treadmill_Group_Mats_20260916/build_report.md)。

## World1 normal Wall display layout（2026-09-16）

`ReplicatedStorage.Config.WallDisplayConfig.WallUI`がWorld1 Stage1〜10の通常Wall .1〜.4に対する共通表示設定の正本。初期値は`Scale=0.8`、`StageGap=0.4`。Stage別の個別値は持たない。

Scaleは基準レイアウトに対して、HP Gaugeの幅・高さ、内包するFill / HP数値、StageNumber / Headingの幅・高さ・内部間隔、関連UIStrokeを一括縮小する。HP Gauge下端は床から4.32studを維持する。StageGapは`StageNumber下端 - HP Gauge上端`の実距離として計算し、中心間距離には使用しない。

寸法とGapは固定stud値であり、Wall高さは`CanvasSize.Y = Wall.Size.Y × 10`の座標変換にだけ使う。Wall高さ変更でScale後のGauge高さ、Stage高さ、StageGapを変えない。Boss UIはBossDisplayConfig / BossDisplaySurfaceの独立経路であり、本Configの対象外。検証：[World1 Wall表示Config報告](../reports/World1_Wall_Display_Config_20260916/build_report.md)。

## Mobile / Tablet landscape controls（2026-09-16）
- Smartphone / Tabletの正式対応方向はLandscape。`StarterGui.ScreenOrientation=LandscapeSensor`に加え、Client起動時に既存`TouchControlZoneClient`が`PlayerGui.ScreenOrientation=LandscapeSensor`を明示設定し、LandscapeLeft / LandscapeRightへ端末センサーで追従する。Portrait専用HUDや回転警告UIは持たない。
- 移動方式と入力範囲はRoblox標準PlayerModuleのDynamic Thumbstickを使用する。ゲーム独自の端末別サイズ、最大Clamp、Safe Area、LeftMenu / Jump境界による縮小・移動は行わない。
- Touch操作ZoneはLeftMenu、Potion、Player HP、Strength HUD、その他UIとの重なりを許容し、操作しやすい標準範囲を優先する。
- 通常時は`DynamicThumbstickFrame`の背景だけを透明化する。指を置いた際のThumbstick、Knob、Drag中の標準操作表示と入力判定は変更しない。
- SmartphoneのLeftMenu倍率計算では大きな入力Capture領域を障害物として扱わず、表示されるThumbstick部品とJumpだけを参照する。Tablet LeftMenuの専用倍率・位置は維持する。
- Smartphone / TabletのStrength HUDは`AnchorPoint.X=0.5`、`Position.X.Scale=0.5`でViewport全幅の物理中心へ配置し、Touch Zone、LeftMenu、Safe Area、Jump位置による横移動を行わない。
- DesktopはTouchGuiを生成しないため、この処理によるMouse / Keyboardおよび既存配置の変更はない。

## 対象と根拠

現在のStarterGui、HUDLayout、各LocalScriptとサーバー通知経路を基準とする。過去のUI案や古いObject位置だけを採用しない。初期監査はEdit状態のソース・プロパティ確認であり、2026-09-16のMobile Landscape変更では端末シミュレーターによるPC/Smartphone/TabletのPlay実測を追加した。

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
| 現在StageのWall .4撃破後、Boss未撃破 | 接触前からサーバーの実Current HPを表示 | 非表示 |
| 現在攻略対象がWall .1〜.4 | 非表示 | 接触・Combat開始を待たず対象WallのStage / 実HPを表示 |
| Boss離脱 | 現在HPで表示を維持 | 非表示 |
| Boss結果・Run初期化 | 解除・状態再評価 | 次Stage .1は接触前から表示 |

Bossの共有Humanoid Healthを個人HPの正本として表示しない。Wallも古いConfigのMaxHPをクライアント側で推測せず、有効設定に基づくサーバーPacketを使用する。CharacterAdded、Stage変更、Boss結果、初期化で古い表示を解除・再評価する。

### Boss表示の形状

PersonalGaugeと専用Part `BossDisplaySurface`をClientごとにRuntime生成する。Stage1〜9は次Stage .1 Wall、Stage10は既存Stage10BoundaryWallを基準とする。WallのSize / CFrameと既存StageSurfaceのPlayer側Faceから、同じ幅・高さの薄い面を手前へ配置する。現在の寸法はStage1〜9が88×56.25×0.05stud、Stage10が90×56.25×0.05stud。Mapへの恒久Part配置は行わない。

`ReplicatedStorage.Config.BossDisplayConfig`が表示設定の正本。初期値はTransparency=0.5、SurfaceOffset=0.5stud（Wall表面とSurface裏面の間隔）、Thickness=0.05stud、HeightRatio=0.6、VerticalOffset=0。StageOverridesは必要なStageの項目だけ上書き可能で、現在は空。薄いSmoothPlastic面を半透明表示し、奥の実Wallを透かす。BlurEffect等は追加しない。

SurfaceはAnchored=true、CanCollide / CanTouch / CanQuery=false、CastShadow=false。Visual専用で、Damage・Combat・Gate・Progress・Reward・Trigger・入力受付の責務を持たない。SurfaceGuiはActive=false。サーバー共有WorkspaceへSurfaceを生成せず、LocalPlayerの既存CombatStateだけで表示を切り替える。

Wall .4撃破通知で接触前からSurfaceとBoss名 / STAGE N / HP Bar / Current HP / Max HPを即表示する。この間、次Stage .1の通常StageSurfaceとWall HPは隠す。Boss撃破時はそのPlayerのSurfaceをTransparency=1、GUIをEnabled=falseにし、次Stage .1のStage表示とサーバーの実HPへ切り替える。非表示中もCanQuery / CanTouch / CanCollide=false。Run初期化ではローカル面を再生成する。Stage10もSurfaceGuiで統一し、WorldComplete / World2 Gate処理は変更しない。

Boss高さはEnemyManagerの生成処理で、Scaleと床合わせ完了後の見た目Modelから一度だけ測定する。既存staticBoundsで可視BasePartの8頂点とBone位置を集計し、透明な外側Collider / CombatZoneを除外してBossDisplayHeight / BossDisplayBaseYを記録する。HPバー中心のワールドYは `BossDisplayBaseY + BossDisplayHeight × HeightRatio + VerticalOffset`。名前・STAGEは既存の間隔でその上へ配置する。Bossサイズ変更は次回生成時に再測定され、アニメーション中は高さを再測定しない。Wall高さはCanvas座標への変換にのみ使用する。

ConfigはEditで調整して次回Playへ反映する。Play中はClientでrequire済みConfigの値を調整すると、既存0.5秒の表示保守処理で反映される。VerticalOffsetはUIだけを上下し、Surfaceや実Wall、CombatZoneを移動しない。StreamingでBoss Partや基準Wallが遅れて到着する場合も、受信済み実HPを保持して表示生成を再試行する。

27stud時の580x270 Canvasを基準に、SurfaceGuiのCanvasSizeを580 x (表示面.Size.Y x 10)とする。壁高56.25でも1 Canvas pixelの縦寸法を0.1studに維持し、テキストの縦伸びを防ぐ。通常WallのHP領域は底面から4.32studを維持し、基準高さ5.13studへWallDisplayConfigのScaleを適用する。StageNumber下端はHPバー上端からStageGap上、Headingの高さとStageNumberからの0.4stud基準間隔にもScaleを適用する。Boss HPバーは独立して高さ5.13studを維持し、中心位置は上記Boss実寸式で決める。BossのSTAGE Nはバー上端の1stud上、Boss名はその0.4stud上。旧HPGaugeBottomStuds / HPGaugeHeightStuds属性は使用せず、Wall上端を配置基準にしない。

現在攻略対象になった時点からStage/HPを表示する。撃破済み・未来Wallは非表示。Current HPはCarry適用後の実CombatStateを正本とし、WallClearedに既存GetSnapshotForStageの全状態を添付して一括反映する。次WallをMaxHPで仮表示しない。BossRecommendationにもサーバーのCurrentを添付し、クライアントでMaxをCurrentへ代入しない。

Boss Carryの現行仕様はQueueDamageで予約し、接触時のBoss.Beginで初めて適用する。解放直後に満タンなのは未適用の実状態であり、UIで先行減算しない。接触時にはCarry適用後のBossInitialize、その後BossGaugeを表示する。抽選ルートやCarry適用時点は変更しない。

専用Surface上でも既存Canvas尺度を再利用し、Boss名領域は通常6stud、長文のStage9は12stud、STAGE Nは3.5stud。名前の全文、折り返し、既存Font / 色 / TextSize制約、緑のHPバー、NumberFormatを維持する。共通HeightRatio=0.6で全10Stageの名前領域が表示面内に収まる。

| Stage | Boss Name |
|---|---|
| 6 | Pipi_Kiwi |
| 7 | Trippi Troppi |
| 8 | Chimpanzini Bananini |
| 9 | Trippa Troppa Tralala Lirilì Rilà TungTung Sahur Boneca TungTung Tralalelo TrippiTroppa Crocodina |
| 10 | Dragon Cannelloni |

Stage9の名前を短縮名へ変更しない。Stage1〜5はモデル名から末尾Rigを除き、camelcase境界等を整えて表示する経路。後半の名前は現在の指定表記を使用する。

最新の実装・検証は[BossDisplaySurface報告](../reports/World1_Boss_Display_Surface_20260916/build_report.md)。Stage1→2の実Combat、全10Stageの表示Fixture、Config各項目、Bossサイズ変更後の再生成をPlay確認した。複数Client同時接続とStage10の実Combat完走は未実施。過去の戦闘実測は[既存レポート](../reports/World1_Stage6_10_20260915/build_report.md)に保持する。

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

Inventory通知は入口・Tab・個別Cardの段階を分離する。通知発生条件は従来のまま、Inventory／Tabを開いても即消去せず、表示後にClose／別Tab／Mergeへ離れた時にその段階を既読にする。入口の既読は下位へ伝播しない。既存Seen保存により再Joinでも確認済みIDを復元する。

Dumbbells／Auraの既存Buyボタン「！」は、通常Tab内で対象が実Viewportへ入ったIDだけをShown候補として記録する。表示直後は「！」を残し、一覧を離れた時に候補IDだけSeenにする。スクロール下の未表示Cardは未読を維持する。購入は既読の必要条件ではなく、購入・Equip等による従来の通知条件解消は優先する。

InventoryNotificationExposureがItemsと同じAbsolutePosition／AbsoluteSizeの交差判定を共通提供する。画面・ScrollingFrame・Clipする祖先の範囲を使い、各方向35%（上限：幅32px／高さ24px）以上を必要とする。Visibleだけ・1px交差ではShownにしない。MergeのCardは対象外。Speedは既存Tab通知だけに離脱時Seenを適用し、Card通知は追加しない。

既存InventoryNotificationSeen.Dumbbells／DumbbellBuy／Aura／Speedを再利用し、入口は各集合のInventory:ID、Aura TabはTab:ID、その他の既存ID用途は維持する。旧保存IDは既読として継承する。Itemsの段階的保存は変更なし。並行Seen応答が古くても、既読集合を未読へ巻き戻さない。旧実装の履歴：[Dumbbell Buy通知報告](../reports/Dumbbell_Buy_Seen_Notifications_20260916/build_report.md)。

Panelは他の主要Panelと排他で開閉する。BUY WINの見た目上の導線はあるが、WinProducts空のため販売完成を意味しない（K10）。UIが示す課金所有状態と、StudioDebugConfigで効果が抑制されるテスト状態を区別する（K11）。

## RewardPad

実装は黄色Neon Pad。TrophyRewardTemplate.Handleは8×0.3×5stud、RGB255,221,0。旧Trophy像へ戻す予定は確定していない。

- Player個別のRewardPad上には、既存Win HUDのTrophy Iconと実獲得値を`+N Win`で表示するBillboardGuiをRuntime生成する。Handle実寸から上方向へ2.75stud加算し、MaxDistance 30stud、220×64px、FredokaOneとする。
- 取得成功後はWin AttributeとHUD数値の更新を確認してから、WinLabel全体を1.17倍へPopし、Rotationを小さく4回揺らして約0.5秒で基準状態へ戻す。連続取得時は進行中TweenをCancelして基準状態から再開する。
- 同時に本人だけへ共通`UISoundConfig.CoinCollect`を再生する。失敗・二重接触・既取得ではFeedbackを出さない。

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
## 2026-09-18 — Item purchase currency and Dumbbell feedback

- Item cards for Common, Uncommon, and Rare use one full-width purchase button showing the existing Win HUD Trophy icon beside `100`, `300`, or `1,000`. The button does not add a `Win` text suffix.
- Epic and Legendary item cards show Roblox's standard Robux logo (`rbxasset://textures/ui/common/robux.png`) beside the live Marketplace product price. The previously referenced `rbxassetid://77577420970893` resolves to a Trophy image and must not be used for Robux currency. `DeveloperProductConfig` fallback prices are used only when Marketplace lookup fails.
- A failed Dumbbell purchase uses the Inventory status presentation for a short English message. `NotEnoughWin` includes the selected Dumbbell's current `DumbbellItemMaster.PriceWin`; `DataSaving` and `AlreadyOwned` have explicit player-facing messages.

## 2026-09-18 — Exclusive Merge steps

- STEP 1 exclusively shows `SELECT ITEM`, `0/3 ITEMS`, three empty sockets, and the short merge explanation. The Item list and execution controls are hidden.
- STEP 2 exclusively shows BACK, `SELECT 1 ITEM`, and the existing Item-card presentation for every owned mergeable regular Item, including counts of one or two.
- STEP 3 exclusively shows BACK, the selected Item, three material sockets, capped `N/3 ITEMS`, result preview, shortage status, and MERGE. The selection list is hidden; MERGE is enabled only from the current server projection when three materials are available.
- Each render first hides every step-specific root and the legacy MergePanel, then enables only the current step. BACK transitions are STEP 3 to 2 and STEP 2 to 1.
## 2026-09-18 — Staged Item notification seen timing

- Item notifications have independent Inventory, Items-tab, and individual-Item stages. Opening a surface records that the upper stage was shown; it remains visible until the player closes Inventory or leaves Items.
- An individual Item is only a Seen candidate when its normal Items-tab card/guide button intersects the ScrollingFrame and screen by a recognizable amount: at least 35% of each dimension, capped at 32px width and 24px height. `Visible=true` alone is insufficient.
- Entering the viewport keeps `!` visible. Only leaving the normal Items view marks the individually recorded Items Seen. Items never shown remain Unseen, including cards below the canvas viewport.
- Inventory and Items-tab stages use per-Item namespaced entries in the existing `InventoryNotificationSeen.Items` set. Existing plain Item IDs remain the persistent individual Seen source, preserving old saves without a schema change.
- Merge STEP 2 cards do not participate in Items notification exposure. A successful Equip may immediately resolve the corresponding individual notification under the existing notification-condition rule.

## 2026-09-18 — Bright, simplified Merge presentation

- All three exclusive steps use a brighter purple Merge-only panel, white text with dark outlines, and clear rounded borders. Inventory Header, Close, Tabs, and other pages retain their existing presentation.
- STEP 1 retains SELECT ITEM, 0/3 ITEMS, three empty sockets, and the short explanation. SELECT ITEM is gold; count and sockets use brighter purple with pale borders. BACK uses a secondary blue color.
- STEP 2 retains the existing Item-card information and one-or-more-copy selection rule. Cards and element-image backgrounds are brighter; Item name, Element, Rarity, and Owned count remain readable.
- STEP 3 shows a large Item image and current rarity stars, followed by a current-star → result-star preview. Stars come from ItemMaster.RarityRank and the server's ResultItemId. Item type/name, Element name, rarity names, and the old result-name/×1 text are not displayed. Success status is simply `Merge complete.`
- Filled sockets have gold borders and Item images; empty sockets have pale-purple borders and a large question mark. Count remains capped at 3/3. Shortage status is secondary and appears only when needed.
- MERGE is gray-purple when disabled and bright gold when the existing server projection permits execution. Server eligibility, recipes, consumption, result, saving, and Badge behavior are unchanged.

## 2026-09-18 — Completed-Item preview and Inventory font

- Merge STEP 3の上部Heroは、選択素材ではなくItemMergeStateが返すResultItemIdの実Item画像と完成Rarity星を表示する。Client独自のRarity推測は持たない。
- 3 Socketは消費する素材Item、Upgradeは素材Rarity星 → 完成Rarity星を維持し、Hero・右側星・Server結果ItemIdを一致させる。
- Inventory Window配下の英数字Textは、既存・Runtime生成を含めEnum.Font.FredokaOneへ統一する。★もFredokaOneで正常表示する。非対応言語はRoblox標準Font fallbackを許容し、Localization設定やSource Languageは変更しない。
- FredokaOneの文字幅に合わせ、TextScaled要素は既存UITextSizeConstraintの最小値だけ必要時6pxまで縮小可能とする。レイアウト、明るい3STEP Visual、通貨Icon、購入・Merge機能は変更しない。
# Localization source management

- Player-facing source language is English. Japanese and other target languages are managed through the Roblox Localization Table.
- The Git source of truth for manual localization imports is `localization/GameLocalizationTable.csv`; committing this file does not upload it to the Roblox cloud table.
- Dynamic entries retain Roblox placeholders such as `{number1}`, `{number2}`, `{number3}`, and `{time1}` in both Source and translated text.
- Japanese terminology uses `強さ` for Strength, `再生` for Rebirth, `通常ダンベル` for Normal Dumbbell, and `オーラ` for Aura. STR, DMG, HP, VIP, Win, Robux, and Lv. remain unchanged.
- Runtime Sources are case-sensitive, so required variants such as `Equipped` and `EQUIPPED` remain separate entries. Source and translated placeholders must match exactly.
