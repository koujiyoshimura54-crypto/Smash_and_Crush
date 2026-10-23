# UI_SPEC — 現在のUI仕様正本

## 2026-10-21 — Restored Inventory secrets and World1 2D displays

Unowned Inventory Dumbbells and Items use the existing card background darkened by25%, a black transparent icon and white outlined `???`. Current ownership restores the original colors; equipped/owned-unequipped cards stay normal. No new unlock rules, layout or purchase logic. Reused the previously tested three Sources unchanged. The six owner-supplied World1 transparent IDs are shared by Master, saved stands, Inventory and Shop; NORMAL_05 remains134662273184560.

Restore only World1's twelve existing boards:9x9 studs, offset(0,6.5,0), ItemIcon58%, Strength effect14%, Win price12%, state10%. Remove exhibition models beneath ShoesModels, retain its Folder, all equipment geometry/held models and subsequent fonts/equipped colors. World2 remains unchanged. [Restoration and verification](../reports/InventoryDisplayRestore_20261021/REPORT.md).

## 2026-10-10 - ShopStall capacity title

- Capacity purchase header is now exactly `UpGrade` in both existing text layers, superseding the historical `Update` labels below. Color, decoration, layout and purchase behavior are unchanged.
- `Workspace.ShopStallTemplate.UpGradeBillboard` reuses the purchased Feedback BillboardGui and its font/black stroke, with vivid lime RGB(170,255,0),10x3-stud size and center1.5+half-height studs above the roof. No model movement or duplicate label.


## 2026-09-30 — Inventory Capacity purchase (Phase 5G)

- 下記previewの外観・ShopStallTemplate前トリガーを維持し、実購入へ接続。1商品、`Update`タイトル、`5 >>> 6`、トロフィー＋`100`を表示。購入価格はInventoryCapacityConfigだけに定義し、PreviewConfigは配置のみを保持する。
- `PurchaseInventoryCapacity` Remoteへ現在Capacityを送り、価格・所持Win・保存・OwnershipはServerが検証。ClientはWin / Capacityを書き換えない。保存中は連打を抑止し、Win不足は`Not enough Win`。確認待ちは再試行可能。
- 購入後は現在値6とMAXを表示してButton無効化。将来Configに次段階を足すと次価格を表示する。RunInventoryCapacity Attributeの更新で既存HUDも自動更新する。

## 2026-09-30 — Inventory Capacity upgrade preview

- `InventoryCapacityUpgradeClient` creates `StrengthGui.InventoryCapacityUpgradePanel` at runtime: existing Shop header/X, title `Update` without its left icon, one Inventory Capacity card, existing bag/trophy assets, large `+current >>> +next` values and trophy + numeric price only. Preview price/increment/design/trigger dimensions are isolated in `InventoryCapacityPreviewConfig` (100 / +1 initially).
- A client-only transparent `Workspace.ShopStallTemplate.InventoryCapacityTrigger` uses the stall pivot offset `(0, 3.5, -12)` and size `(20, 9, 9)` on its front side. Enter opens, leave closes; X stays dismissed until exit/reentry. World1/living-player only, and entry while an existing panel is open does not replace that panel.
- Purchase fires the panel-local `PurchaseRequested` BindableEvent and shows `Coming soon`; no remote, Win deduction or capacity mutation. Play verified entry, X dismissal, reentry, leaving, purchase feedback and unchanged Win/Capacity. Existing Shop still opens normally. Place/GUI unsaved; stopped in Edit. No Push.

## 2026-09-30 — Run Return Boss-unlock visibility

- Supersedes the visibility rule in the revision below; upper-center placement/red styling are unchanged. RunReturnClient shows Return only for an active World1 Run outside Lobby, with the current Boss unlocked/undefeated and a living Humanoid. Return pending/busy also hides it; a failed request releases the existing lock for retry.
- Unlock is read exclusively from existing CombatState `WallInitialize` / `WallCleared` snapshots (`Current >= 5`, not Skipped) and `Stage1BossUnlocked`. Initialize/RunId changes clear cached unlocks. HealthChanged/CharacterRemoving hide the button on death. The existing Lobby footprint check is retained only for Lobby visibility, never for Boss unlock.
- One Play: Stage1 and Stage2 wall .1–.4 progression hidden, .4 completion visible, Stage1 BossInitialize visible, Stage2 actual Chasing visible; real Stage1 defeat/TrophySpawn/Stage2 entry hidden. Death and Respawn/Lobby hidden. World2 UI condition only checked; travel not tested. Return server/persistence and HUDLayout unchanged, Place/GUI unsaved, Stop/Edit.

## 2026-09-30 — Run Return UI revision

- Supersedes the Phase 5D button placement/visibility below. `RunReturnClient` creates a red `StrengthGui.HUD.RunReturnButton`; HUDLayout alone places it at the upper center (desktop 144×48, compact 120×44 below Win/Inventory). The sixth left-menu slot is removed.
- Visible only for an active World1 Run outside the existing TrainingArea floor footprint, with the current Boss undefeated. Existing CombatState Initialize snapshots supply cleared/skipped state; EnemyDefeated hides immediately and StageCleared permits the next undefeated Stage to show it. Lobby footprint is sampled every 0.2 seconds for presentation only. RunId requests, pending lock, server Return and persistence are unchanged.
- Play: actual Stage1 defeat hid the button, Stage2 progression showed it again, desktop button click returned successfully with Run Count 0 and hid it in Lobby. PC 1348×639 and iPhone 17 Pro landscape 749×361 were visually checked; World2 hiding was checked by setting the runtime CurrentWorld attribute to 2 (travel itself not tested). Tablet not retested. Place/GUI unsaved; Stop/Edit and default viewport restored.

## 2026-09-30 — World1 Return button (Phase 5D)

- `RunReturnClient` creates `StrengthGui.LeftMenu.RunReturnButton`, with a matching `HUD.LeftHUD` slot (order 6, existing two-column menu's third-row right). HUDLayout alone controls placement and scaling and includes this visible slot in touch/status collision checks.
- World1 + RunInventoryActiveで表示。「戻る」からRunIdだけをServerへ送信する。確認ダイアログなし。処理中は「保存中…」で無効化し、失敗時は「失敗／再試行」で再操作できる。帰還成功後はInactiveとなり非表示。Inventoryカウンターは独立した表示専用のまま。
- Average Laptop、iPad Pro M5 13in、iPhone 17 Pro、iPhone 7横画面で文字収まりと既存ボタン／実表示Touch controlsとの非重複を確認。Place/GUI未保存。[検証記録](../reports/World1_RunReturn_Phase5D_20260930.md)。

## 2026-09-30 — World1 Run Inventory HUD (Phase 5C)

- `StarterGui.StrengthGui.RunInventoryHUDClient` creates a display-only `HUD.RunInventoryLabel` beside the TopHUD region. Text is exactly `Inventory <RunInventoryCount> / <RunInventoryCapacity>`; both server AttributeChanged signals update it, with no client quantity/capacity calculation or remote request.
- The label stays visible for inactive runs. Missing initial attributes use `-` until replication; capacity is never hardcoded in the UI. Existing ResetOnSpawn=false preserves the HUD across respawn; lifecycle resets come from the server.
- HUDLayout alone owns placement and text size: desktop/tablet above Win with safe-area padding, compact landscape beside LeftHUD below the Win row. Transparent TextLabel, existing Level FontFace/TextOutline, 22px desktop/tablet and 18px compact landscape. No input action or full-state decoration.
- PC, iPad Pro, Fire HD 10, iPhone 17 Pro and iPhone 7 landscape were checked in Play. Existing FULL presentation, other HUD positions and World2 behavior remain unchanged. [Evidence and limits](../reports/World1_RunInventory_Phase5C_20260930.md).

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

上段の表示内部は`StrengthValueContainer`内の数値`Strength`と固定単位`StrengthUnit`をHorizontal `UIListLayout`で中央配置する。数値LabelだけをRuntime更新し、`StrengthUnit.Text = "Strength"`／`AutoLocalize = true`で既存Localization Entry（日本語`強さ`）を使用する。桁数やLocaleが変わっても数値と単位を1行中央表示する。
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

`ReplicatedStorage.Config.BossDisplayConfig`が表示設定の正本。初期値はTransparency=0.5、SurfaceOffset=0.5stud（Wall表面とSurface裏面の間隔）、Thickness=0.05stud、VerticalOffset=2。StageOverridesは現在空。薄いSmoothPlastic面を半透明表示し、奥の実Wallを透かす。BlurEffect等は追加しない。

SurfaceはAnchored=true、CanCollide / CanTouch / CanQuery=false、CastShadow=false。Visual専用で、Damage・Combat・Gate・Progress・Reward・Trigger・入力受付の責務を持たない。SurfaceGuiはActive=false。サーバー共有WorkspaceへSurfaceを生成せず、LocalPlayerの既存CombatStateだけで表示を切り替える。

Wall .4撃破通知で接触前からSurfaceとBoss名 / STAGE N / HP Bar / Current HP / Max HPを即表示する。この間、次Stage .1の通常StageSurfaceとWall HPは隠す。Boss撃破時はそのPlayerのSurfaceをTransparency=1、GUIをEnabled=falseにし、次Stage .1のStage表示とサーバーの実HPへ切り替える。非表示中もCanQuery / CanTouch / CanCollide=false。Run初期化ではローカル面を再生成する。Stage10もSurfaceGuiで統一し、WorldComplete / World2 Gate処理は変更しない。

Boss高さはEnemyManagerの生成処理で、Scaleと床合わせ完了後の見た目Modelから一度だけ測定する。UI専用boundsは実際に表示されるBasePartの8頂点だけを集計し、Bone、透明Part、Root、Collider、CombatZone等を除外してBossDisplayBottomY / BossDisplayTopY / BossDisplayHeightを記録する。HPバー中心のワールドYは `BossDisplayTopY + VerticalOffset`。名前・STAGEは既存の間隔でその上へ配置する。Bossサイズ変更は次回生成時に再測定され、アニメーション中は高さを再測定しない。Wall高さはCanvas座標への変換にのみ使用する。

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

- Item cards for Common, Uncommon, and Rare use one full-width purchase button showing the existing Win HUD Trophy icon beside `75`, `200`, or `600`. The button does not add a `Win` text suffix.
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

## Claimed reward buttons

Time Rewards and Daily Rewards retain their existing visuals while locked or ready. A claimed reward keeps its card, icon, and reward presentation unchanged; only its disabled `CLAIMED` button uses the shared gray-lavender gradient and neutral strokes. Reopening or rebuilding either panel reapplies the claimed visual from the existing server state.

- Player-facing source language is English. Japanese and other target languages are managed through the Roblox Localization Table.
- The Git source of truth for manual localization imports is `localization/GameLocalizationTable.csv`; committing this file does not upload it to the Roblox cloud table.
- Dynamic entries retain Roblox placeholders such as `{number1}`, `{number2}`, `{number3}`, and `{time1}` in both Source and translated text.
- Japanese terminology uses `強さ` for Strength, `再生` for Rebirth, `通常ダンベル` for Normal Dumbbell, and `オーラ` for Aura. STR, DMG, HP, VIP, Win, Robux, and Lv. remain unchanged.
- Runtime Sources are case-sensitive, so required variants such as `Equipped` and `EQUIPPED` remain separate entries. Source and translated placeholders must match exactly.
- NumberFormat abbreviations (`K`, `M`, `B`, `T` and higher suffixes) are runtime values, not Localization Sources. Numeric TextLabels use `AutoLocalize = false`; mixed displays keep formatted numbers separate from AutoLocalized fixed labels such as `StrengthUnit`.
- Playtest text capture is not the source of truth: fixed player-facing text is managed explicitly in the CSV, while dynamic numbers, asset/internal IDs, and other runtime values remain outside the Localization Table.

## Element Set Bonus HUD

When equipped Protein, Glove, and Training Belt Items share an Element, the Item Effect HUD displays the matching existing Element image beside `×1.5` in the Fire coral, Ice cyan, or Electric gold palette. The compact badge is centered immediately above the three existing Item effects and is hidden for incomplete or mixed sets. The former FIRE / ICE / ELECTRIC SET localization Sources remain as old candidates.

## 2026-09-30 — Run Inventory Phase 5B notification only

- Existing EnemyDropGachaClient rejects stale World1 RunId presentations. A successful item draw rejected by Run capacity uses the existing result label with RUN INVENTORY FULL; no reward card is shown for the ungranted item.
- No Inventory count HUD, Return button or capacity purchase UI was added. Server attributes are ready for a later UI phase; World2 result presentation remains compatible.

## 2026-10-06 - Purchased Trophy Win Pass presentation

Retain purchased Trophy geometry/Prompt/Billboard. Client presentation follows verified owner state: x2 Wins / x3 Wins / Owned;3x owners see no purchase Prompt. Fetch price from Marketplace with no fixed24 fallback; use ... during lookup and Price unavailable on failure. No custom UI. Equipment Edit placement checked; published-app interaction remains unverified.


## 2026-10-10 - Inventory / Skip purchased Shop presentation

InventoryPanel and StageSkipGui.Panel reuse StrengthGui.ShopPanel artwork with light purple/pink surfaces, black borders and retained yellow Win/green Robux controls. Inventory uses a900x410 design only for landscape viewports below500px high (otherwise900x660), retaining the equipped pane; compact cards and sockets fit below the header. This changes presentation only. See [actual Edit review and remaining checks](Inventory_Skip_Visual_Review.md); Cloud/live translation/touch validation is not complete.


## 2026-10-10 - Superseding Inventory / Skip palette and structure

The earlier light purple/pink direction is revoked. Inventory uses saturated purple; Skip uses saturated blue. Reuse purchased Shop header/close/card artwork, its dark RGB7,7,12 body at50% transparency, same-role typography and90px stud tiles. Studs belong on header/cards, not the full body. Equipment/list wrappers stay transparent; Inventory retains a compact left equipment pane and3-column right list. Skip aligns Stage/Win/Robux with a scrollable last row. See [actual comparison](Inventory_Skip_Shop_Alignment.md) for the confirmed Edit views and remaining Cloud/device checks.


## 2026-10-10 - Limited Egg 01 Phase 2 display

Workspace.Chill Octopus opens a purchased OpenEgg panel clone with seven static Pet Viewports, exact numerical odds, purchased close control and one disabled green Robux button. Normal Eggs keep their six-slot UI/Win1/3/8 controls. Pet Inventory uses the original purchased tiles and inner3D display for the seven registered names, with the title band reserved. No ownership, abilities or rarity is inferred from display registration.

Product3717610547 uses Marketplace price when available and base149 otherwise. Purchase is deliberately disconnected until Phase 3. See [model mappings, screenshots and verification limits](Stud_Egg_Pet_Catalog.md#permanent-robux-egg-phase-2---facility-and-display-2026-10-10). No temporary UI or display-only Pet IDs are saved in CurrentCloud.


## 2026-10-12 - Normal Pet Merge preview (local, incomplete seven-Pet pools)

Merge Pet cards reuse purchased PetInventory titles/checks/images/Viewports with rank/point labels; candidate frames/percent labels reuse OpenEgg.Background.Pets.1. Actual Basic/Rare/Legendary/Mythic MeshParts display through existing static Viewport fit, unless a per-Egg image URI is configured. Hide0%/invalid-minimum candidates, show rounded100% totals/surplus notice, clean display resources on close/tab/destroy. Only Merge labels bypass translation; execution remains disabled. Real Edit/device appearance is unverified.


## 2026-10-12 - Approved normal seven-Pet pools

Normal Egg candidate sheets reuse seven actual purchased OpenEgg frames with13%-scale width and six1.5% gaps, no wrap. Correct named Decals and %g%% numeric probabilities come from the shared normal pool, preserving1/3/8 actions. Reopen/restamp mock verified without duplicate seventh. Actual Edit rendering/image access/device fit remain unverified because MCP disconnected before preview. Existing Merge completed-Egg MeshPart Viewports and rank labels retained.


## 2026-10-12 - Purchased Pet material cards in Global Merge GUI

Keep original purchased card/image/font/layout settings. Material tiles normalize only Z layers above their destination ancestor: Stroke/Main/Icon/check/title/input, with the rank-point label above the title layer. This adapts the Sibling donor to StrengthGui Global without changing original Inventory behavior. Local Source/mock verification only; actual Pet/Egg rendering and image authorization are unverified.


## 2026-10-12 - Merge reference-layout replacement (supersedes three-step/socket and point-label presentation)

Use measured1372x823 Item reference geometry for both tabs: purchased yellow header/red basket/pink close, dark translucent body, left Item/Pet tabs/title/three columns, right result above free drop region, footer Selected/Clear/Merge/Creates. Narrow portrait stacks the list/result/drop while retaining three columns and accessible actions. Actual purchased parts/images only. English/AutoLocalize=false; no rank/point text.

Click/tap and drag share the selection entry path. Mouse6px drag; touch240ms hold, earlier motion is scroll; valid drop adds once, outside drop cancels,400ms post-drop activation suppression. No dropped icons/sockets in the region. Tab/close clears and releases display resources. Pet inputs are normal owned copies, excluding Limited/equipped; Merge remains explicitly disabled. Item uses existing count-based3-identical recipe, authoritative result and sole pending-guarded submit.

Upgrade-only filtering has no agreed mixed-origin baseline. Until decided, show actual positive outcomes as Possible Eggs (no chance redistribution). Rendered states/comparison links and remaining physical-input/Cloud checks are in the latest DEV_STATUS; do not claim pixel-perfect art identity or live gameplay verification.


## 2026-10-13 - Inventory common shell / two-card Speed (supersedes Inventory shell geometry)

Use the owner's two-card Speed reference as the1130x812 design: purple purchased Stud header, existing Inventory icon, single white outlined title and pink close; separated translucent dark body; equally spaced Dumbbells/Items/Aura/Speed tabs, cyan selected. Other page bodies retain their existing lists/equipment/purchase renderers. Portrait uses the same four tabs and vertically reflows Speed actions without replacing purchased buttons.

Speed has Current Speed and Premium Speed only. Current is display-only, uses the server's normal WalkSpeed/active source and existing shoe icon, and excludes temporary2x movement. Premium shows Config speed and exactly one of fetched Robux price, OWNED or ACTIVE. Preserve purchased green button artwork/font/currency glyph; no extra Robux word. Price failure/owned/pending states disable new purchase. Remove only the Inventory600-Win offer, preserving already-owned effects. No new Win upgrade UI.

Actual Edit comparisons and limits are recorded in DEV_STATUS; hardware input/Cloud runtime remain unverified.


## 2026-10-13 - UpGrade two-card layout

Supersedes the previous capacity-only UpGrade geometry. Use the measured1410x800 panel with existing orange/yellow UpGrade header/close, dark translucent body and two grey Stud cards: Inventory Capacity above Speed. Reuse existing backpack/blue Speed image and purchased yellow Win button artwork. Align icons/current-arrow-next values/actions; no tabs. Portrait uses700x1000 reflow. Capacity feedback and Speed feedback/pending are independent. Speed shows server upgrade values/prices, MAX40 or Premium50/OWNED with purchase disabled; no temporary multiplier is shown. Latest Inventory layout remains unchanged, and no600-Win purchase entrance returns.


## 2026-10-13 - Purchased Dumbbell station display

Retain the purchased four-by-three stepped equipment, Ramp/red carpet/access path, stand decorations and original two-row world billboards. Shared sign says "Dumbbells". For stands1..7 use actual normal DumbbellDisplayTemplate exhibits and Master icons/names/Strength bonuses/Win prices in existing Amount and Price fields; show owned/equipped/pending per player. Stands8..12 show ON HOLD/Unavailable, without a purchase offer. Do not add large description panels or replace purchased artwork. The user's saved Ramp rotation takes precedence; final manual assembly alignment and visual legibility remain pending.


## 2026-10-14 - Regular Item rarity overlays

Protein/Glove/TrainingBelt icon overlays read ItemMaster.RarityRank and show one through five stars. Reuse existing equipment/drop Stars, otherwise clone purchased ShopPanel.Top.ShopText1 and its black outline. Keep actual images, purchase buttons, palette and card geometry. Place card stars in the upper-left portion, away from the upper-right selection check and bottom count/equip/purchase controls; drag clones keep the overlay above their icon. Apply to Inventory, normal-Item Shop cards, Merge material/selected/drag/result cards and existing drop-result stars. Pet and Dumbbell icons are excluded. Actual Edit preview and unverified runtime limits are in DEV_STATUS.

## 2026-10-14 - Point Item candidates and compact price labels

Retain the purchased Merge shell, material/result cards, real icons, ItemMaster-driven star overlays, selected dim/check and card-rectangle overlap drop detection. Mixed Item unit selection is variable with minimum2, not fixed sockets/three identical copies. Virtualized list preserves independently selectable count-derived unit identities even for large holdings. Candidate scroll shows actual type/Element/rank cross-product images, stars and probability, with no additional point explanation text; use existing purchased list/card primitives. Clear/deselect/ownership updates/hide/reopen synchronize selection and release display resources.

Epic Inventory card has the actual yellow4500-Win control plus its existing green Robux control, with amount-only K/M. Preserve currency images, gradients/strokes/fonts. All monetary presentation uses common NumberFormat.Price/PriceText or MarketplacePrice.Format; all non-price values and actual price sources are unchanged.

Real Edit desktop Epic/mixed and390x690 candidate previews were inspected. Narrow candidate names/percentages fit and actions remain inside the panel; physical input and Cloud gameplay remain unverified. Pet Merge remains disabled and its calculation/ownership behavior is unchanged.

## 2026-10-15 - Item Inventory reference layout

Supersedes the compact Inventory Item grid and upper-left star overlay for this page only. Follow the owner's 1672x941 effect-label reference: shared purple Stud Inventory header, existing backpack/close/four tabs, dark navy body, fixed left Equipped/Best Equip and three vertical equipment sockets, fixed right star1..5 filter, and only the right card list scrolling. Item mode uses a1368x910 design; other Inventory tabs retain their1130x812 shell. Portrait uses700x1050; available screen width reduces card columns3->2->1 without shrinking rows to fit all products.

Use existing ItemMaster images in ImageLabels. Rarity surfaces are grey/green/blue/vivid purple/gold; equipment sockets read the actual equipped Item rarity. Each card has one separate five-slot star row below its icon/effect, with constant slot geometry, gold earned stars and dark remaining stars. Equipment uses the same five-slot convention. Other Shop/Merge/drop overlays remain unchanged.

One short English effect line uses the existing purchase Amount FontFace, white text and black outline: Strength +N, Boss Damage +N%, Treadmill +N×. Values come from ItemMultiplierConfig getters. Do not show a duplicate type/name, rarity name, points or long description. Display owned counts only when greater than one. Keep the actual Win/Robux purchase artwork through HUDLayout.BindPurchaseButton, unchanged native gradients/currency/typography and existing compact prices; Epic keeps a second full-width Robux row below Win.

Keep existing Remote/state/pending/purchase conditions. Equipment acknowledgements update both panes and checks; rank switches rebuild only cards and reset their scroll. Reopening/notifications preserve the selected rank and current scroll while refreshing authoritative state. Initial rank remains1. Empty slots show None and cannot unequip. Gameplay, save, effects, merge and price Configs are unchanged. See DEV_STATUS for separate screenshot, real-Instance geometry/state and unverified physical-input/Cloud evidence.

## 2026-10-15 - Item image stars and Win-only Epic follow-up

Supersedes the text stars, effect font and second Epic purchase row above. Only Item Inventory uses five equal square ImageLabels: gold76134658177553 for earned ranks, grey126441080731699 for remaining ranks, transparent/Fit/white tint. Filters show the same gold image plus number. Selection alone has a6-unit white outer border and bright inner highlight; other filters use a3-unit dark border with the inner highlight disabled, independently of hover/press.

Short Config effects use the existing purchased HatchClient GothamBlack FontFace, white with a2.5-unit black outline. Keep original Item/purchase artwork, purchase amount face, gradients/currencies and K/M. Epic shows4500 Win (4.5K) only, with no reserved Robux row; Legendary keeps Robux. Shared InventoryPresentation/Shop/Merge/drop stars remain unchanged. Fixed equipped slots/Best Equip/filters and independently scrolling3/2/1-column cards remain. Evidence and limitations: DEV_STATUS.

## 2026-10-15 - Pets entry in left menu slot6

Move the original purchased ScreenGui.Left.Inventory entry into StrengthGui.LeftMenu.PetsButton at runtime, using the existing HUDLayout two-column/three-row slot system. Keep Skip, Inventory, Rebirth, Shop and Free in their original slots1..5, with the same144px design size and14px gaps. Pets fills the bottom-right slot6, retains its actual purchased button/icon140192410666130, and adopts the surrounding label geometry/FontFace with English source text Pets and existing AutoLocalize behavior.

HUDLayout alone owns placement/scale; PetClient.bootstrap no longer fixes the entry at right-center. Move before purchased MenuClient/ButtonClient scans, so one cached activation callback toggles the existing separate Pet Inventory through MenuClient.open/close without a competing size tween. Disable the empty old Left HUD container. Keep both existing ResetOnSpawn=false settings and all Pet equip/save/Hatch/follow/effect behavior. No Pet tab is added to Strength Inventory. Actual Edit input and remaining runtime limits: DEV_STATUS.

## 2026-10-15 - Image stars in Item Merge

Supersedes text-star overlays for Item Merge materials, dragging cards, possible results and completed results only. Use Inventory's gold76134658177553/grey126441080731699 assets: five equal square transparent/Fit/white-tinted ImageLabels, rank-count gold and remaining slots grey. Place stars below the actual image in their own row. Keep image checkmarks/selected dimming separate from the white-tinted stars.

Item materials gain a44-unit star band and matching virtual-list stride; ghosts include that band. Candidates/completions separate image/stars/name/probability rows. Portrait Item mode grows its result/design height by82 units to fit these rows; retain scrolling/final probabilities. No fixed socket/icon is added to Drop. Pet layout/images/odds/disabled execution, InventoryPresentation's shared Shop/drop stars, Inventory image stars and prior Pets slot6 move remain. Evidence/limits: DEV_STATUS.
## 2026-10-15 update: normal Egg totals and Pet ability text

The existing native Open1/Open3/Open8 Title/TitleShadow labels show `Open N` and the corresponding `Egg.price(name) * Egg.count(buttonName)` total in Win, formatted with the existing `NumberFormat.Price` K/M policy. Keep native label dimensions, FontFace, wrapping and text scaling. World1 Egg pedestal prices also use the same getter/formatter; saved Info text is updated to 15/100/300/1K without moving any objects.

The existing Pet detail Description Text/TextShadow pair displays `Strength +X%` from `Pet.StrengthPercent` for the 35 approved World1 species/IDs. Unknown species retain their prior cosmetic description. Preserve purchased GUI assets, the dedicated Pet Inventory, existing equipment/follow behavior and the shared left-menu Pets slot6. No additional Inventory tab or replacement artwork.

Edit-mode native Instance checks confirmed all 12 totals and representative +2/+130/+200 descriptions with TextFits=true. Screenshot capture returned white and was discarded, so visual comparison and physical input are not verified for this update. No local Play.
## 2026-10-16 - Twelve normal Dumbbell cards and sale signs

Normal Dumbbell Inventory/Shop render the same twelve ordered Master definitions/images/additions/compact Win prices. Keep purchased assets and first-seven IDs, including slot5 image134662273184560 and corrected slot6 image98216689951421. Added cards reuse native Shop card/button artwork. Shop owns only normal-card sizes/aspect; shared ResponsivePanels skips its former size restoration for these cards, avoiding competing resize writes. Retain the purchased wrapping UIListLayout, align its growing contents to Top and size the scroll canvas from AbsoluteContentSize; other product artwork/size/purchase logic is unchanged. Shared list row positions necessarily follow the expanded list. Normal Shop uses two columns where width permits and one on narrow viewports, with minimum180px card height. Existing equipped items show EQUIPPED and disable input; owned items show EQUIP and use the existing equip Remote.

Dumbbell Inventory alone reduces three columns to two/one with available width, preserves at least40px purchase-button height, separates image/effect/button rows and enables only vertical list scrolling/automatic canvas. Existing equipped pane and shell/manual map placement remain. This is not an Item/Speed/Aura layout rewrite.

Saved sale signs1..12 use the same prices/additions and existing Win icon. Saved native Shop cards1..5 receive the same effect/price text; runtime Master sync supplies all12 images/cards. All12 asset IDs returned Completed from Roblox's public thumbnail endpoint. This does not verify in-experience ImageLabel.IsLoaded or image permissions. UI builder/state/geometry checks were simulated; actual engine rendering, overlap, final-row scrolling and physical mouse/touch remain unverified. No connected Studio tool is available in this task, so no Edit screenshot or input pass is claimed.

## 2026-10-16 - Dumbbell facility images and ownership state

Each existing PerStepButtons1..12 BillboardGui now has four independent vertical rows: ItemIcon, native Amount/Win icon, Price showing +N Strength, and Status. Reuse the station's purchased ImageLabel/aspect constraint and TextLabel/UIStroke; ItemIcon reads Master.Image with Fit/white/transparent settings. Keep the existing currency asset, price gradient, fonts and black outline. Billboard dimensions become8x7 studs with the original StudsOffset and animation retained; row heights0.40/0.16/0.14/0.12 and padding0.01 leave space within the board. No new screen UI or purchase input is added.

DumbbellStandClient enumerates Master and reads the existing authoritative inventory state/replies. Status shows Step to buy, Owned or Equipped; an equipped station also retains its existing green Press highlight. Initial unloaded state retries read-only inventory fetches; a response revision prevents an older initial read from overwriting a purchase/equip acknowledgement. Equipment attributes also refresh presentation. The start guard prevents duplicate remote listeners. Saved ItemIcon/Status Instances are reused when descendants replicate, without runtime duplicate creation.

Exact saved geometry/property checks and actual client Source simulation pass; they do not establish native image loading, camera projection, narrow-screen appearance, rendered text fit or physical operation. Those remain owner Cloud checks after Save/Publish. Existing Shop/Inventory presentation is unchanged in this follow-up.

## 2026-10-17 - Two worlds of 2D Dumbbell facilities

Supersedes the previous stationary 3D exhibit presentation. World1 reuses all12 existing ItemIcons, purchased Amount/Win/Price/Status rows and their typography/colors/strokes. Board9x9 studs, StudsOffset(0,6.5,0); image/price/effect/status heights58/14/12/10 percent with1% native gaps. Fit and zero crop preserve image aspect, with the existing square FitWithinMaxSize constraint. World1 physical equipment/Ramp/carpet remain authored. Master is still the sole World1 image authority for equipment/Shop/Inventory; six V2 changes include W1-5DV2 in slot6, while slot5 and1..5/7 remain unchanged.

World2 has twelve copies of the purchased station/stair assembly under World2Map.TrainingArea.DumbbellDisplays, retaining four columns/three tiers. It shows only ItemIcon(84%) and the reused numbered label01..12(12%); price/effect/purchase guidance/Owned/Equipped are hidden. WorldId/StandIndex/ImageName/DisplayImage attributes identify display content independently from products. No ItemId, purchase input, gameplay Script or Shop/Inventory entry is copied.

Native final Edit screenshot/fit/placement evidence is in DEV_STATUS. All24 image URIs are configured;23 load. World1 slot8 image11017141876908 returns404 and does not render. Exact requested ID is retained pending a usable owner asset; do not claim all24 rendered. Other23 load successfully. No local Play or live Cloud/Shop/Inventory operation verified.

## 2026-10-17 - Expanded World2 equipment presentation

The existing twelve Dumbbell stations rotate/move as one authored assembly; each ItemIcon keeps its own Press Adornee, Fit/aspect constraint, image mapping and numbered row. Native red/gold entrance treads meet a13-stud carpet branch. No stationary3D Dumbbells return. World1 station8 now uses the corrected 110171141876908; native final Edit confirms this image and all twelve World2 images are loaded, superseding the earlier 23/24 result for that corrected asset.

Reuse the purchased Treadmill number labels, with visible centered scale coordinates, TextWrapped/TextScaled, original font/color/strokes and a world offset measured above each machine. Show only 01..12. Blank old speed/multiplier/premium/owner/requirement labels and disable copied buttons; retain the equipment artwork and shared Treadmills heading. Belt motion and Training remain unconnected.

Reused normal Egg displays show species names and the shared Eggs sign; Limited Egg retains its name/artwork. Merge/Upgrades booths, Win Boost, ranking-board headings and Feedback retain the purchased appearance. Hide or blank only prices, effects, requirements, saved ranking rows/avatars and inactive inputs. Keep signs/UI artwork visible. No purchase affordance should imply a free or configured offer. There is no new World2 Shop/Inventory product entry.

Native Edit screenshots and IsLoaded observations are recorded separately from exact saved-property checks and memory-only simulations. Cloud walking, physical input, real transactions/training and all-device views remain unverified. Temporary inspection camera/GUI/reference-library visibility is restored; Studio Save/Publish and local Play are not performed.

## 2026-10-18 — Current World2 replica display contract

Supersedes the rejected expansion presentation for the newly downloaded file. World1 saved UI/Source remains unchanged in this task. World2 copies the actual World1 facility assemblies at the same relative positions/orientations. Each of twelve existing cloned ItemIcons uses the approved W2-1D..W2-12D URI, its own Press Adornee, Fit/zero crop and native aspect constraint. Board9x9, offset(0,6.5,0), image84%/number12%; price/effect/purchase/Owned/Equipped rows hidden. No3D Dumbbell exhibits are copied and no product definition is added.

Only four approved earlier treadmills are shown:01,02,03 and04 Robux. Old numeric speed/owner/admin labels are blank.04 has category text only; no purchase button/amount/ID/multiplier. Other facilities retain purchased names/artwork/headings while undefined numeric fields/ranking rows and inactive inputs are blank/hidden. Display metadata does not authorize gameplay; copied tags/IDs/Sources/prompts are excluded and actual selectors checked.

All12 World2 ItemIcons are both configured and actually loaded in final Studio Edit (Success/IsLoaded). Same-direction overhead/front pairs and detail views are in the [current replica report](../reports/World2LobbyReplica_20261018.md). Runtime/Cloud interaction and all-device views remain unverified. No local Play, Save or Publish.

## 2026-10-19 — Seven-machine World2 labels and moving assemblies

World2 now displays old treadmill type labels 01/01/02/02/03/03/04 Robux in ascending world-X row order. StationIndex 1–7, VisualType and World1Slot metadata distinguish individual models without authorizing products. Preserve the existing fonts, artwork and own-model Adornees. No price, requirement, multiplier or active purchase input is introduced.

Dumbbell 12 and normal Egg 4 signs/UI move rigidly with their full assemblies. All twelve existing W2 ItemIcons retain URI/number mapping, own-Press Adornee, offset, Fit and aspect settings; native final Edit confirms all twelve actually loaded. Existing side paths extend along their actual world axes with 13/16 widths. Same-direction before/after and near-eye entrance views: [current report](../reports/World2LobbyDepth_20261019.md). No local Play/Save/Publish; runtime walking and all-device behavior remain unverified.

## 2026-10-19 — Studio /test replies and diagnostics

StudioTestCommandResult carries server replies to the restored StudioTestCommandClient, which displays them through RBXGeneral.DisplaySystemMessage and logs them in Client Output. Bind a later-created Remote once; wait for the chat channel and report unavailable/display-failure cases. Server help/status remain available before gameplay dependency initialization completes; status names readiness/failure and Output records initialization/execution errors. No new screen UI or production command enablement. Native Edit compile and memory-only response/HUD tests pass; real chat display and replicated HUD behavior remain unverified. [Repair record](../reports/StudioTestCommands_20261019.md).


## 2026-10-20 — World2 connected existing UI

Existing Shop/Inventory/Merge/Aura/Egg/treadmill/stand UI consumes the same World2 catalog definitions as server calculations, with separate W2 identity and synchronized price/owned/equipped states. Existing icons, stars/rarity numbers, element/type labels, fonts and outlines are reused. Existing stand images/Adornees remain. Normal Egg counts 1/3/8 display the actual debit. Unknown paid treadmill/Aura/Limited Egg show unavailable purchase state without 0/free pricing; no placeholder-asset disclaimer is added. Geometry remains unchanged.

Native Edit confirmed configured UI references/labels and model aliases, but image requests remained unloaded and capture did not complete. Actual image rendering, runtime panel layout/state/animation and operation are unverified. [Details](../reports/World2Gameplay_20261020.md).


### UI layout investigation only — 2026-10-20

Inventory: 94 UI-related Sources, 416 authored GUI roots/views, including dynamic/shared/facility builders. Native temporary counters reproduced EssentialStudShopClient layoutDumbbellShop 493 startup calls and recurring HUDLayout RenderStepped full-PlayerGui obstruction scans. Prioritize event-driven/diffed HUD layout, then coalesced Shop card/canvas layout, then shared ResponsivePanels writes. No UI behavior/design implementation was changed. Resize, touch and direct connection-growth validation remain pending; do not classify every screen as affected. Detailed statuses and measured scope: reports/TutorialArrows_UIAudit_20261020/REPORT.md.


### 2026-10-20 — Lobby equipment headings and shared layout

The six World1/World2 Dumbbell, Egg and Treadmill headings allocate explicit icon/text width instead of combining zero-width AutomaticSize.X with TextScaled. Treadmill caption rectangles and heading UI offsets change; equipment transforms, authoritative values and physical occlusion remain. The existing TreadmillUIClient is enabled for presentation only. HUD layout and Return collision updates are separately invalidated; tracked watchers disconnect on removal/destruction. ResponsivePanels coalesces visible layouts/hitboxes and avoids equivalent writes. Shop preserves the authored card-height reference while separating it from measured CanvasSize. These changes do not establish a fix for persistent Gameplay Paused or all devices. See reports/LobbyUIFix_20261020/REPORT.md.


## 2026-10-20 — Treadmill heading fitting

Superseding the8384ce6 regression: keep TextWrapped=true and TextScaled=true together. Measure localized text and extend only the treadmill title width (English40.7976 / Japanese55.8672 studs), preserving the normal7.5-stud height,6.8-stud icon,1.2-stud gap and existing offset/font/colors/stroke. Retain rbxassetid://106106287008236 with Fit/aspect preservation. Native English/Japanese near/far rendering and actual icon loading passed in both Worlds against normal Dumbbell headings. See reports/TreadmillHeadingSizing_20261020/REPORT.md.


## 2026-10-20 - Thirteen-stage size selection

Keep existing Size Change styling, two columns and unlock/payment behavior. Generate AUTO and SIZE1..13 from SizeChangeConfig.MinTier/MaxTier. Use a vertically scrolling220-wide panel,430 high on desktop and bounded by the available viewport height. Saved numbers0..10 keep their ordinal meaning under the new size table; do not convert old10 to13.


## 2026-10-20 - Rebirth shared Config reference

RebirthMenuClient reads both required LV and multiplier from RebirthConfig. Current completed count controls the current multiplier, current+1 controls its preview, and GetRequiredLevel(current) returns the next requirement. Layout, controls, eligibility, badges and MAX behavior are unchanged; absence of a next definition still controls MAX.

## 2026-10-20 ? Shared equipment state colors

Speed uses Equip/Equipped instead of ACTIVE. Speed, Dumbbells, regular Item slots, individual Pets, Aura, size1?13/AUTO, Shop Dumbbell buttons and world stands use equipped cyan #00DEFF?#0094EC (solid #00DEFF where appropriate). Paint the visible purchased Main/image gradient, restore original unselected paint, preserve purchase colors/actions/hover sizing. State comes from server confirmation. Native equipment LocalizationTable uses CSV Equip/Equipped/Owned wording; layout and other Active meanings are unchanged. Evidence: reports/SpeedEquipment_20261020/REPORT.md.

## 2026-10-21 — World2 arrival-locked Inventory cards

Unowned World2 Item/dumbbell cards remain visible before first arrival, with the existing dark secret paint, black alpha silhouette and supplied white padlock (rbxassetid://93565525595769). Only the lock is shown: names, effects, prices, stars, purchase controls and ??? are hidden. Locked cards neither select nor send requests. After permanent server-confirmed arrival they use the existing ??? view and eligible purchase controls. Owned cards retain color/equipment regardless of arrival history. Layout, patterns, World1, other tabs and equipped colors remain unchanged. Native real-tab screenshots and isolated verification are recorded in [World2ArrivalLocks_20261021](../reports/World2ArrivalLocks_20261021/README.md).

## 2026-10-21 - Saved Pets entry and Egg candidate sizing

Pets is a saved sixth entry at StarterGui.StrengthGui.LeftMenu.PetsButton, with a saved HUD.LeftHUD.PetsButton slot and the common square size. PetClient binds this entry to the existing Pet Inventory without runtime relocation or entry creation. EggClient uses centered rows of at most four square Fit images inside the unchanged candidate panel, with centered probability bands below. Existing order, odds, purchase controls, hatch animation and Pet Inventory card sizes are preserved. The existing Limited Egg viewport layout remains unchanged. Evidence: reports/PetsEntryEggCandidates_20261021/README.md.

## 2026-10-22 - Studio Boss Animation Preview investigation controls

The Studio-only tool lists all ten World2 Bosses in two columns. Existing manual R15/R6 candidates, Play/Stop/Close, Front/Side/Back and cycle-speed controls remain. Stage2 offers original/recovered large aligned procedural gait; Stage7 offers its saved939walk and a1.35x rotational variant. Other added stages expose diagnostic candidates and explicit structural limitations, not an implied production gait. A floor guide is limited to the five investigation stages; status excludes hidden helper motors from visible-motion detection. Public runtime UI and combat configuration are unchanged. Native callbacks and images were checked; physical input and narrow-device layout remain unverified. See [investigation and candidate instructions](../reports/World2RemainingBossAnimations_20261022/README.md).

### 2026-10-22 - Shared production Preview candidates

Stage2/4/6/7 now offer **Approved Walk (production)** in the existing sorted candidate list, sharing the exact production gait, amplitude, cadence and ground correction. Historical candidates and all controls remain. Only the preview copy receives preparation; production never calls the Studio tool. Current HUD, Strength/Win displays and death-camera manual edits are preserved. Details: [four-boss delivery](../reports/World2FourBossWalk_20261022/README.md).

## 2026-10-23 - Y01 player camera framing recovery

The current editor calibration is `18 * (1 + (MuscleHeightScale - 1) * .15)` studs, applied once on a new Character or changed height. The authored StarterPlayer zoom minimum is 18 and maximum is 30, restored directly from the owner's PreMerge rbxl. The existing framing script then permits manual inward zoom to `min(18, automaticDistance / 2)` and outward zoom to `30 * heightScale`. Same-character World travel, StageSkip and Trophy return retain nominal manual zoom; death respawn reframes the new Character. A temporarily Scriptable/unready camera now retries when normal follow returns. Camera replacement preserves nominal zoom even during obstacle occlusion; body centering uses an absolute correction only when resizing. Existing death freeze, FOV restoration and spawn heading remain. Native Play/rendered representative checks and limits: [Y01 report](../reports/PlayerCameraY01_20261023/README.md). The later two-property correction and focused Play readback are recorded in [PreMerge bounds](../reports/PlayerCameraY01_20261023/PREMERGE_BOUNDS.md). Current Studio only; no rbxl write or Save/Publish.
