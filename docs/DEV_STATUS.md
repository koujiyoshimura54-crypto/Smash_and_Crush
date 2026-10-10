# DEV_STATUS — 開発状況

## 2026-10-01 — Inventory Capacity tiers 5→12

- 実装差分はInventoryCapacityConfigのみ。5→12の7価格を追加し、5→6は100から5 Winへ変更。
- 1回のPlayで実Buttonから5→6（20→15 Win）、6→7（15→0 Win）を購入。次UIは7 >>> 8 / トロフィー＋30、Win文字なし。12のMAX/無効化はClient Attributeだけを一時変更して確認後7へ復元（12までの実購入は未実施）。検証用20 Winは全額購入に使用。
- 既存保存失敗・連打・再Join・Ownershipの再検証は行わず。Place/GUI未保存、Play停止・Edit復帰。前Phaseの分離テストは当時の単一Tier/100 Win前提の記録であり、今回再実行していない。

## 2026-09-30 — Inventory Capacity purchase (Phase 5G)

- 5→6 / 100 Win実装済み。PlayerData defaults / normalize、Ownership付き購入保存、現在RunのCapacity同期、既存Update UIへのRemote接続を追加。前Phaseの未Commit preview UIも今回へ含める。
- Playで不足Win 2の購入拒否、検証用100 Win加算後の実Button購入（102→2）、HUD `3 / 5`→`3 / 6`、RunId / Count維持、MAX無効化、連打とRemote再送を確認。保存先をキャッシュなしで読み、Win 2 / Capacity 6 / 購入IDを確認。Permanent / Equippedは前後一致。
- Stop→再PlayでCapacity 6、Win 2、HUD `0 / 6`を確認。購入済みCapacity 6は検証Playerに保持。検証用Run Itemは通常退出で消失し、Permanentへ加算していない。
- `InventoryCapacityPhase5G.spec.luau`の分離10件通過：新規/旧データ、Win不足時の書込ゼロ、100回再要求、callback retry、保存前失敗、応答消失、AutoSave/退出保存、再Join、Owner交代、保存中のWin加算・二重消費防止。`InventoryCapacityPhase5GStudioRunner.luau`から実PlayerDataServiceの保存先のみMemoryStoreへ差し替えて実行。
- 今回コードのRuntime Error / Infinite Yieldなし。既存Unused_Assets/BossAnimationReferences由来のChattedエラー・待機Warningは対象外。World2 / Boss / Returnの再回帰は行わず。Place/GUI未保存、StopしてEdit復帰。

## 2026-09-30 — Inventory Capacity upgrade preview

- Added InventoryCapacityUpgradeClient and InventoryCapacityPreviewConfig. Runtime-only single-product UI opens at the ShopStallTemplate front trigger; existing Shop header/bag/trophy visuals reused. Purchase remains a local preview with no data changes.
- Play opening/closing/reentry, mock purchase and existing Shop opening passed. Place/GUI unsaved, Edit restored; local Git changes only, no Commit/Push. [UI details](UI_SPEC.md).

## 2026-09-30 — Run Return Boss-unlock visibility

- RunReturnClient only: existing wall snapshots/unlock notification plus living Humanoid gate Return visibility. Same red upper-center layout; server Return and transaction logic unchanged.
- One Play verified Stage1/Stage2 wall progression hidden and Boss unlock visible, Stage1 Combat and Stage2 Chasing visible, actual Stage1 defeat/Trophy hidden, death/Respawn/Lobby hidden. World2 condition only checked. Place/GUI unsaved; Stop/Edit. [UI details](UI_SPEC.md).

## 2026-09-30 — Run Return UI revision

- Red Return button moved to the upper center, with placement owned by HUDLayout. Visibility uses active World1 Run, current Boss defeat snapshots and the existing Lobby floor footprint; Return/persistence scripts remain unchanged.
- Actual Stage1 defeat → hidden; Stage2 → visible; desktop click → Returned / Run 0 / hidden in Lobby. PC and iPhone 17 Pro landscape checked. World2 attribute condition checked, travel and Tablet not retested. Stop/Edit, default viewport restored; Place/GUI unsaved. [UI details](UI_SPEC.md).

## 2026-09-30 — Run Return transaction safety (Phase 5F)

- PlayerDataOwnershipを追加し、PlayerDataService / RunReturnPersistence / RunReturnServiceを更新。既存キー内のOwner Tokenと永続Return Journalで旧Serverを拒否し、Grantedの減算rollbackを廃止。
- Play内の実Luauによる状態遷移18件＋独立PlayerDataService Sessionの結合14件が成功。Phase 5Eの旧Cancel／新Return競合は16個、Pending取消経路は11個。旧ID／旧Ownerが後続metadataを変更しないこと、新規／旧形式プロフィールのLoadを確認。
- 実Studio DataStoreで1個／5個Return、LoadCharacter、90秒AutoSave、未確定5個の実退出、次Playの新Owner取得／Granted維持を確認。検証追加6個だけを既存ItemServiceで除去し、元のOwnedItemsとEquippedItemsの一致を確認。
- BindToClose近接・Crash・別Server競合は故障注入Adapterと独立Sessionによる相当試験。実プロセス強制終了や本番2Server試験とは区別する。再実行用testsと結果JSONを収録。
- 既存504 Scriptのうち対象3個だけ変更、追加1個。一時テストInstanceは除去。RunInventoryService、HUD、World2固有処理、ItemMaster、各Reward等のSourceは一致。Stop→Edit、Place/GUI未保存。
- 公開時はOwner検査のない5D以前のServerと混在させない切替が必要（今回Publish／Server再起動は未実施）。[詳細](../reports/World1_RunReturn_Phase5F_20260930/README.md)。

## 2026-09-30 — World1 Run Return (Phase 5D)

- World1「戻る」→既存Item Transactionで保存確認→Run消去／Inactive化→戦闘解除・回復・Lobby帰還を実装。新規4 Script、既存3 Scriptを変更。
- Play: 0/1/5個、実ボタン、Remote20連送、保存前／応答後の失敗・再試行、UpdateAsync callback再実行、死亡の前後、旧Run Drop、LoadCharacterを確認。障害注入は一時メモリAdapter、通常保存は既存Studio DataStoreの実書込とcache無効の再読込で確認。追加した検証品は差分のみ取り除き、元のOwnedItems/EquippedItems一致を確認。
- 未確定5個で通常Saveと退出を実行し、OwnedItemsに混入しないことを再読込で確認。Boss/Attack状態の解除、HP25→100、同一Characterも確認。PC/Tablet/Phone横画面の配置確認済み。
- 一時Adapter/Probe除去。既存500 Scriptのうち変更対象3個以外のSource一致、追加4個だけを確認。World2/戦闘式/VFX等はSource比較で回帰確認し、全ゲームプレイを再走査したものではない。既存Unused_AssetsのError/Infinite Yieldは未変更。
- Stop→Edit、標準viewportへ復帰。Place/GUI未保存。[証拠・障害検証の限界](../reports/World1_RunReturn_Phase5D_20260930.md)。

## 2026-09-30 — World1 Run Inventory HUD Phase 5C

- Added RunInventoryHUDClient and a small HUDLayout placement block. Server count/capacity are rendered through AttributeChanged signals; no gameplay, inventory mutation or save changes.
- Play verified initial 0/5, all five real random-drop acceptance updates, sixth rejection with 5/5 plus existing FULL, death/respawn/LoadCharacter/new-run resets, inactive visibility and server capacity notification 3/7 and 3/10. Permanent ownership/equipment remained equal.
- PC, iPad Pro, Fire HD 10 and two iPhones passed Simulator text-fit/screen-HUD overlap checks. Original Studio sources other than HUDLayout retained matching fingerprints. Existing unused-reference-model errors/waits remain; full combat/World2/save-flow replay was outside this UI phase.
- Place/GUI not saved; Stop→Edit and normal viewport restored. [Report](../reports/World1_RunInventory_Phase5C_20260930.md).

## 2026-09-30 — World1 Boss HP0即撃破

- BossCombatService.QueueDamageがWorld1の壁余剰適用後HPを返し、EnemyManagerが同じ壁hit内で致死判定する。通常Attack・Combat開始時HP0も既存defeatへ合流。WIN通知をDefeatedガード内へ集約。
- Play 9ケース：通常Manual/Auto、壁余剰致死（過剰・ちょうど0）、残HP50、低Strength7Hit、Boss予定攻撃の約34ms前撃破、Stage10余剰撃破→WorldComplete、開始時HP0フォールバック。全件WIN / EnemyDefeated / StageCleared / Reward呼び出し / Trophy生成が各1回。
- Strength1000のStage01壁突破はBoss Attack入力0回・BossAttack.Start 0回で即撃破。正常撃破後のPlayer HP100、攻撃停止、Stage進行を確認。Chase / BossAttackService / 攻撃周期 / Damage式は未変更。
- 検証条件復元後Stop→Edit、Place未保存。保管モデルの既存エラー・参照待機警告は未変更。詳細：[即撃破報告](../reports/World1_Immediate_Boss_Defeat_20260930/README.md)。

## 2026-09-30 — World1 Boss Phase 4

- World1の勝率抽選、5Hit強制勝利・敗北を撤廃。既存Strength×Glove補正で実HPを削り、RequiredStrengthは推奨値として維持。World2互換の抽選経路は維持。
- Stage01の実Combat：100% / 80% / 60% / 150%で5 / 7 / 9 / 4Hit勝利。60%は位置制御でBoss初撃MISS、近距離ではBoss4撃で死亡。低Strength WIN / EnemyDefeated / StageCleared、Stage02進行、死亡後のStage1・Lobby・再戦を確認。
- Stage01実壁Carryは60 Strengthで25、Boss開始HP350、6Hit撃破。Strength1000では余剰425により開始HP0となり、次の受付攻撃でWIN。従来Carryを維持した結果であり、追加上限は未導入。
- 全10Stage×6Strength帯の実サービス検証60件、World2の決定的経路4件を旧実装と比較。Chase / BossAttackService / 攻撃周期設定は変更なし。
- 一時検証条件を復元しStop→Edit。Place未保存。保管モデルの参照エラー・Infinite Yieldは対象外として未修正。旧Lottery前提のServerStorage.Testsは過去仕様の検証であり、今回の合格証拠には使用しない。
- 詳細・検証範囲：[報告](../reports/World1_Phase4_20260930/README.md)、[実測](../reports/World1_Phase4_20260930/evidence.json)。

## 2026-09-22 — Abbreviated number localization exclusion

- Marked NumberFormat-driven Strength, Level progress, Win, Strength gain, Boss HP, Wall HP, and reward amount labels as non-localized while retaining the separate AutoLocalized `StrengthUnit` label.
- Removed obsolete dynamic Sources `+1M Cash` and `6.4K Strength` from the CSV; K/M/B/T runtime output is locale-invariant and fixed text remains explicitly managed.
- Localization CSV remains UTF-8 BOM with unique, nonblank Sources and matching placeholders.

## 2026-09-19 — Element Set icon badge

- Element Set表示をElement名＋SETのTextから、ItemMasterの既存Element別Protein画像＋固定 `×1.5` へ変更。
- Badge位置・Element色・成立判定・Strength倍率は維持。旧Localization Sourceは削除せずOLD_CANDIDATEとして保持。

## 2026-09-19 — Element Set Badge localized width

- Element Set Badgeの幅を英語Sourceの手計算から、Localization後の実描画文字列へ追従するAutomaticSizeへ変更。左右10px Paddingを維持し、Fire / Ice / Electricと英語 / 日本語で末尾が欠けない構造にした。
- Element Set判定とStrength ×1.5計算、Item Effect Icon、HUD位置・色・文字サイズは変更なし。

## 2026-09-19 — World1 upgrade economy V1

- Dumbbell Grade 1～7をBonus 2 / 4 / 8 / 25 / 60 / 150 / 300、Price 5 / 15 / 40 / 100 / 250 / 600 / 1500へ更新。
- Aura Pink～BlueをBonus 10 / 20 / 40 / 150 / 350、Price 25 / 75 / 200 / 500 / 1250へ更新。
- 通常Item Win価格をCommon 75、Uncommon 200、Rare 600へ更新。UIと購入判定は共通Config参照を継続し、Save SchemaとLocalization Sourceは変更なし。

## 2026-09-19 — Player Collision / Slap Pass（Implemented）

- StarterPackへ追加されたStore Tool `Slap`を監査。外部require／HttpService／DataStore／Marketplace／Admin処理はなかったが、全Workspace Humanoid走査、Force 140、Ragdollを行う付属Scriptを削除し、`ServerStorage.SlapToolTemplate`へ移動した。
- Handle Mesh `32054761`、R15 Animation `102083458174016`、R6 Animation `243827693`、Smack Sound `7195270254`、Gripと補助stickを維持。Clone時にもScript／Remoteを除去する防御を追加。
- R15 AnimationはAsset権限エラーでロード不能のため再生を無効化。代替Animationは追加せず、0.20秒Hit Delayのみ正規Client→Server要求へ統合した。
- `PlayerCharacters` CollisionGroupを追加し、CharacterAddedとDescendantAddedでCharacter／Accessoryを同Groupへ設定。同Group間のみ非衝突でWorld Collisionは維持。
- Slap Pass `1987256653`の独立したServer所有権キャッシュ、購入Prompt、購入完了後再確認、Respawn対応Tool付与を追加。
- Slap成功判定と5秒CooldownをServer Authority化。8stud以内の別Playerへ水平60／上20のImpulseを成功時だけ適用し、未所有・空振り・距離外・Cooldown中を拒否する。
- 未所有Playerの近距離検出はCharacter同士の距離で行い、Touchedへ依存せず、PromptはPlayer単位で30秒抑止する。

## 2026-09-19 — Localization CSV source of truth

- `GameLocalizationTable_Complete_JA.csv`（192 Entry）を検証し、`localization/GameLocalizationTable.csv`へGit正本として保存。UTF-8 BOM、5列、Source重複・空欄・Placeholder不一致なし。
- Cloud Translatorはja-jp訳を返す一方、AutoLocalize UIは英語のまま。Script再代入ではなく、このStudio PlayでPlayer Emulatorのgame localeが未適用（`ForcePlayModeGameLocaleId`が空）であることを確認。Creator DashboardのUse translated content設定はAPIから確認できないため、実機確認前に併せて確認が必要。CSVのGit保存とCloud uploadは別工程。
- Player向け日本語Source 4箇所を、CSVに存在するEnglish Sourceへ変更。Gameplay、Balance、UI Layoutは変更なし。

## 2026-09-19 — Total Strength ranking display correction

- Production `TotalStrengthRanking_v1` raw top values were verified as descending. The observed `15M` row was raw `150,444,109`, ahead of raw `142,065,423` as expected.
- Fixed only `RankingBoardController.shortNumber`: fractional zeroes are trimmed only when a decimal point exists. OrderedDataStore writes/reads, player-name binding, Daily ranking behavior, and balance remain unchanged.

## 2026-09-19 — Merge card visual polish

- fetch後のorigin/main=`a98b70e`とStudioソースを照合し、MergeInventory.pngを閲覧。STEP 2の表示のみ改修し、ItemMaster / Server eligibility / Sort / Merge / Save / Balanceは変更なし。
- Cardと画像・5 Star・×Nを大型化し、内側四角背景を除去。StarのGold Glow、Lavender未到達Star、Element Border / Soft Glow、Server CanMergeによる軽い強調、選択時1.04倍とGold外周を実装。FredokaOneを維持。
- PC / iPhone 17 Pro Landscape / Fire HD 10 LandscapeのStudio Simulatorで3列・Scroll・明るさ・画像・所有数・5 Slot・BACK / Titleを実表示確認。短いLandscapeの選択パネルだけを安全領域へ拡張し、Card全体を表示できる高さを確保。実機タッチは未検証。
- 隔離Store fixtureでCommon / Uncommon / Rare / Epic、×1 / ×2 / ×3 / ×4、Protein / Glove / TrainingBelt、Fire / Ice / Electricを確認。3個所持でもServerのSaving gate中はCanMerge=falseで強調解除、解除後は復帰。通常・Merge可能・選択中の状態を確認。
- 実Activatedで選択Scale最大1.04、Gold Border、約0.20秒のFeedbackを測定。スマホの選択時に外周GlowがScroll領域内に収まり、隣Cardとの重なりなし。STEP 3の完成画像、素材★4→完成★5、3 Socket、3/3、MERGE有効と、1/3不足を確認。BACK 3→2→1で元配置へ復帰。
- QA用Script / 一時観測LocalScriptを撤去し、DataStoreConfigを原文へ復元。QA隔離Storeでは既存ランキングmirror保存Warningを観測。一時fixtureの構文・監査コマンドエラーは修正・撤去後の通常Playと分離。最終通常Store PlayのError / Warning / Infinite Yieldはなし。

## 2026-09-18 — Merge STEP 2 rarity-star cards (completed)

- Fast-forwarded the clean tracked tree to `origin/main` at `e4e91da`, then used the current Bright Merge palette and FredokaOne implementation as the baseline. Reviewed `MergeInventory.png` for card information hierarchy and brightness only; it was not imported as an asset.
- Replaced STEP 2 card labels with five fixed star slots, a larger item image, and `×N`. Runtime fixtures confirmed Common `★☆☆☆☆`, Uncommon `★★☆☆☆`, Rare `★★★☆☆`, Epic `★★★★☆`, and counts `×1`, `×2`, `×3`, and `×4`. The implementation supports Legendary through rank 5 without adding it to the eligible recipe list.
- Verified Fire Protein, Fire Glove, Ice TrainingBelt, and Electric Glove images. Fire → Ice → Electric and within-element stable ordering remained intact. Merge recipe filtering, selection, server execution, balance, and save paths were not changed.
- Verified PC, iPhone 17 Pro landscape, and Fire HD 10 landscape. Cards, five stars, item images, counts, scrolling, title, and back button fit without overlap. The existing bright panel/card/element colors remain unchanged and inactive stars are lavender rather than black.
- STEP 3 regression passed with result image, material/result rarity stars, three sockets, item count, and final MERGE button intact. Temporary QA data and scripts were removed and the normal DataStore configuration was restored.

## 2026-09-18 — Achievement Badge（Completed）

- BadgeConfigへ5 Badge IDを集約し、BadgeAwardServiceがRoblox BadgeServiceの所有確認・付与・Session重複抑止・失敗隔離を担当。
- First Smash、First Rebirth、First Legendary、World 1 Complete、Into World 2を各正規Server成立地点へ接続。Join時遡及、独自UI、Badge用DataStore、Balance変更なし。
- Legendary通常ItemはBoss Drop、Daily / Time / Community Reward、Secret Pack、Win Shop、Developer Product、Mergeの成立後に共通判定。Debug / QA直接付与は対象外。

## 2026-09-18 — Administrator Treadmill Game Pass

- TreadmillConfigのPremiumTreadmillPassIdを0から1982996954へ正式設定。実Marketplace商品はAdministrator Treadmill / 450 Robux（検証時点）。価格はコードへ複製していない。
- TrainingManagerの既存TrainingZone / 0.2秒scanへPlayer・Character・Treadmill単位の入場ラッチを追加。GamePassServiceへ同期所有確認、Prompt、購入完了後最大5回の再確認、HasPremiumTreadmill属性mirrorを追加。
- 隔離Marketplace応答で、入場0→1、Cancel滞在1、退出再入場2、未所有中Training=false / Strength変化なし、購入成功後Zone内Training=true、所有済み再入場Prompt増加なしを確認。Normal Tredmill06は従来どおりTraining=true。
- PC / iPhone17 Pro Landscape / Fire HD10 Landscape SimulatorでPassId 1982996954、入力不要、Cancel滞在中の再Promptなしを確認。Treadmill配下のProximityPromptは変更前から0。実未所有アカウントのNative購入画面・実課金完了は未検証。
- QA adapterを撤去しGamePassService / StudioDebugConfigを正式ソースへ復元。Premiumは×20、TrainingInterval=0.5、StartTraining以降のStrength計算コード、Visual / Map / 他Treadmillは不変。通常Marketplace接続で実所有=true、既存StudioDebugの効果OFFによりTraining=falseを確認。最終通常PlayのRuntime Error / Warning / Infinite Yieldなし。DeviceをPCへ戻しEditで停止。Publish・実課金なし。

## 2026-09-18 — Auto prompt Double Win purchase on entry

- 最新origin/main=aa7c2d9・SPEC・WorldPassConfig・GamePassController / Service・DoubleWinClient・StudioDebugConfigを監査。PurchasePromptを参照していたScriptはGamePassControllerのみ。変更Scriptは同Controllerだけで、現行ソースをsrcへ保存。
- 既存Pedestal基準のServer入場検知、入場ラッチ、退出余裕0.75stud、所有確認後のCharacter / 入場再検証を実装。ゲームの可視Object変更なし。
- 通常接続アカウントは実所有済み。実APIの商品照会はID1970515086 / PriceInRobux72を返した（取得時点）。所有済みで入場してPromptなし。価格をコードに新定義していない。
- 未所有・購入 / Cancelは一時Marketplace応答adapterで検証。GamePassService自体のPrompt・所有Cache・完了後再確認を通し、初期0→入場1→Cancel滞在1→退出再入場2→購入成功・所有済み再入場2→スポット外Respawn2を確認。成功時HasWorld1DoubleWin=true。StudioのGamePassEffectsEnabled=falseに従い倍率1 / 基本Win10の報酬10を維持。
- PC / iPhone17 Pro Landscape / Fire HD10 Landscape Simulatorで入場時に正しいPass IDのPrompt API呼び出しを確認。E表示なし。境界6.3↔5.9studで呼出数不変、7stud退出後の再入場で+1。実機・未所有実アカウントのNative購入画面・実課金完了は未検証。
- QA adapter / Scriptを撤去しGamePassServiceを原文に復元。WorldPassConfig / StudioDebugConfig不変を照合。他のShopDoorPrompt / Aura ProximityPromptは有効のまま。最終通常PlayのRuntime Error / Warning / Infinite Yieldなし。DeviceをPCへ戻しEditで停止。Publish・実課金なし。


## 2026-09-17 — Equipped Item Effect HUD

- origin/main=85127a5をfetchし、最新SPEC・ItemMaster・ItemMultiplierConfig・ItemService・StrengthManager・TrainingManager・BossCombatService・EnemyManager・装備Remote・StrengthDisplay / HUDLayoutを監査。追加はItemEffectHUDClient、既存変更はEnemyManagerの演出通知だけ。
- 隔離Studio Storeで実ItemEquipRequestを使用し、3種類×5Rarityの全15効果値を確認。Rare→Legendary、順次Unequip、全未装備非表示、Best Equip、Rareへの再装備を確認。
- 実Boss接触：Manual即時・Auto遅延0.5秒の命中通知でGloveApplied=true、Strength50 / Rare GloveのHP減少60、Icon -5pxを確認。Glove未装備はHP減少50 / false / 0px。固定5回勝利は隔離fixtureでRouteを指定し、false / 0pxを確認。戦闘終了は0px。抽選確率・戦闘計算は変更していない。
- 実Tredmill06でTraining中0〜-4px、Unequipで非表示 / 0px、退出・通常歩行でIsTraining=false / 0px。Training中死亡と通常Respawnでも表示・Tween状態を確認。
- Studio Device Simulator：PC1280×720相当、iPhone17 Pro / iPhone7 Landscape、Fire HD10 / iPad Pro Landscape。Icon28〜32px、Text18〜20px、全TextFits=true、中央配置、Gauge上8px。Level / Auto Tap / 可視左右Buttonとの重なりなし。透明なDynamicThumbstick入力領域は可視UIの衝突判定から除外。実機検証は未実施。
- QA用Server / Client Scriptを撤去しDataStoreConfigを原文へ復元。ItemMaster / ItemMultiplierConfig / ItemService / StrengthManager / TrainingManager / BossCombatService / 既存Inventory・HUDソースの不変を照合。最終通常PlayでRuntime Error / Warning / Infinite Yieldなし。DeviceをPCへ戻しEditで停止。不要なreport / Snapshot生成、Publishなし。


## 2026-09-17 — Merge UI redesign

- 3STEP、固定Element順、基準Itemの単一選択、素材自動セット、0〜3個のSocket表示、戻る、空一覧を実装。変更ScriptはMergePanelClient_NewとItemMergeControllerの2本。
- GitHub origin/mainをfetchして5bc8399と現行SPEC・Studioを監査。正規ItemMergeService / ItemService / PlayerDataService、Merge必要数・結果は変更していない。
- 隔離Studio Storeで実Remote経由の3個消費・1個生成・再Merge・不足・0個を確認。再Playで保存数量の復元、素材不足 / Legendary / 不正ID / 保存中の拒否を確認。
- PC、iPhone 17 Pro / iPhone 7 Landscape、iPad Pro 13 / Fire HD 10 Landscapeで実寸と表示を確認。最長のTraining Belt / Electric / Uncommonも収まる。入力検証はStudioのMouse / KeyboardによるActivated経路。実機タッチの操作感は未検証。
- 隔離QAでは既存ランキングmirror保存Warning、監査ツール操作では権限・入力試験エラーを観測し、ゲームRuntimeと分離記録。QA Script撤去・通常Store設定復元済み。最終通常Play結果は[検証記録](../reports/Merge_UI_20260917.md)を参照。


## 2026-09-17 — Latest visual template asset export

- 現在StudioからAura 17個 / Treadmill 10個を正式Repositoryのassetsへ保存。保存済みバイト列を再読込し、Deserializeしたライブラリの名前・階層・主要Visual設定・Beam/Trail参照・PrimaryPartをStudioと照合。Aura 260 Instance / Treadmill 113 Instance。AuraのCFrameに最大4.11e-10未満の標準シリアライズ誤差、その他検査項目は一致。
- 今回はasset保存と関連SPEC整理のみ。Studioライブラリ・Config・Scriptは変更せず、Play再試験は行っていない。親フォルダassetsとWorld1 Balance Auditは変更・Commit対象外。

## 2026-09-17 — Treadmill visual templates (prior Studio verification)

- Premiumの既存3 ParticleEmitterをPremium_FireへTemplate化。通常・青・緑はEffect追加なし。TrainingZone.VisualRoot基準の共通適用で位置とParticle設定を維持。
- Playで適用・差し替え・空指定・5回再適用・通常Training・Respawnを確認。最終通常PlayはParticle 3、Guide 10、倍率Billboard 2、Output Error / Warning / Infinite Yieldなし。検証Scriptは撤去。
- 既存問題：Respawn後にGuide / Billboardフォルダが消える。今回の変更前Config / TrainingManagerへ戻した比較Playでも再現。対象外のGuide処理は変更していない。
- 最新ユーザー指定によりSmash_and_Crush_updated_20260915を今回の正式Git保存先として使用。今回の保存範囲は2つのTemplate assetと関連SPEC。Treadmill装着Scriptのソース書き出しは今回のCommitに含めない。

## 2026-09-17 — Studio Win commands verified

- /addwinと/setwinを既存Debugの登録・Server Executeへ追加。PlayerDataService.SetWinを再利用し、Production側は既存の二重Studio gateで拒否。
- Play中の実TextChatCommand経由で0→10,000→50,000を確認。Shop表示中のHUDは10K→50K、Dumbbell残高表示は10,000→50,000へ即時反映。負数入力は拒否し50,000を維持。
- 非数・無限大文字列・負数・小数・追加引数・上限超過・加算overflow・不正Player・保存中/Item mutation中を拒否。0への設定も確認。
- IsStudio=falseへ差し替えた隔離検証で、Serviceは両コマンドをStudioOnlyとして拒否し、ControllerはCommandを登録しないことを確認。公開環境での実行試験やPublishはしていない。
- 検証用Studio Winは開始前の0へ復元。QA Script/Moduleは撤去。DataStoreConfig、PlayerDataService、/resetdata、Balanceは変更なし。
- QA撤去後の通常Playで両Commandの登録とWin=0を再確認。Runtime Error / Warning / Infinite Yieldなし。Editで停止。

## 2026-09-17 — Aura templates / Pink visual

- ReplicatedStorage.AuraVisualTemplatesへ8Templateを追加し、Pink装備VisualをPink_Aura3へ変更。共通VisualTemplate参照で装着し、他Auraの性能・購入・保存は変更なし。
- 全98Emitter×32主要property=3,136項目、carrier Size / Root相対変換、Attachment配置を照合。LightはInstance Cloneで保持。不要なRig / ScriptはTemplateに含めない。
- 隔離Studio Storeで実AuraServiceを使用したEquip / Unequip / 再Equip / Purple切替 / 重複防止 / 死亡 / 通常Respawnの32チェック合格。R15 UpperTorsoへの装着とClient描画を確認。
- QA Scriptを撤去し、DataStoreConfigを原文へ復元。最終通常PlayのError / Warning / Infinite Yieldなし。Editで停止。Production Reset / Publishなし。
- Template保存はRoblox標準.rbxmを使用し、Serialize→Deserializeで8ModelとRoot参照の復元を確認。元Workspace素材は保持。
- Pink1/2の名前対応はUI_SPEC記載の仮定。Puple_Aura1ではなく実物のPurple_Aura1を採用。R6 fallbackはコード上のみ、実PlayはR15。


## 2026-09-16 — Auto Tap beside Strength HUD

- AutoTap.pngを確認し、独立した上部ボタンをLevelPanel右隣へ移動。既存HUDのCorner / Outline / Fontを再利用し、ON金色 / OFF灰紫色のコンパクトな2段表示へ変更。
- AutoTapClientの表示部分のみ変更。LevelPanel基準の右8px / 下端揃え、HUDLayout.GetLocalSizeによる高さ44〜54px / 幅1.35倍。HUD本体・入力・Remote・保存・Config・Combat・Balanceは変更なし。
- Play：PC70×52px、Phone / Tablet59×44px。全端末で右隙間8px、下端差0px。Phone / Tabletで可視Buttonとの重なり0。ON→OFF→ONの往復を各端末で確認。
- Runtime Error / Warning / Infinite Yieldなし。Device Simulatorを通常Viewportへ戻し、Editで停止。実機スマホの見た目評価は未実施。旧フォルダへ新規ファイルは作らず、既存ソース・SPECだけ更新。

## 2026-09-16 — Auto Tap / Manual input implemented

- 保存Boolean AutoTapEnabled（旧データdefault ON）、1ボタン切替、通常Manual Training、接触対象へのManual Combatを追加。
- 通常ONは従来地上歩行0.5秒、OFFは入力時0.25秒。Treadmillは独立0.5秒でTap加算なし。Manual Combatも0.25秒をServerで制限し、既存Damage / Carry / Boss抽選経路を再利用。
- Play：OFF無入力でStrength / Wall / Boss HP変化なし。20連続のService要求と50連続の実Client Remote要求を1回へ制限。Wall / Boss受付直後のDamageとStrength加算0を確認。Wall Carry後HP105/125を確認。
- 歩行ON1.6秒で3回分、OFF同時間で増加0。非CombatのBattleCorridorもTapで1回分。Treadmillは両設定とも約1秒に2回、追加Tap0。Manual Punchの実AnimationTrack.Speed=2を確認。
- 専用QA StoreへのOFF保存、キャッシュ無効Read-back、次PlayでのOFF復元を確認。通常PlayerData / ProductionのResetは未実施。QA Scriptを撤去、DataStoreConfigを完全復元。
- Desktop / iPhone / iPad Simulatorを確認。実機の操作感・音の聴感・複数Client同時接続は未検証。隔離QAで既存ランキングmirror保存Warningを記録。通常設定でのPlayはError / Warning / Infinite Yieldなし。
- 変更ソースはsrc/配下の8 Script / Config。検証報告は指定の親Project reports/AutoTap_20260916/build_report.md（Gitリポジトリ外）へ保存。

## 2026-09-16 — Tutorial Guide floor-only arrows（Completed）

- TutorialGuideClientの床候補をGeneratedMap内の正規Floor / ConnectorFloorへ限定。TrainingZone、Terrain、Asset内の同名Floorを候補にしない。
- 矢印の中心・両腕の端点・中点・縁を検査し、床外または可視Assetの領域にかかる矢印一組を非表示にする。CanQuery=falseのマットも遮蔽物として扱う。
- Start / Goal / 経路 / 間隔 / 形状 / 更新周期 / Tutorial進行と保存仕様は維持。
- Studio再起動後の最終Playで床表示、Treadmill / 非Queryマット / 操作パネル / Wall / Character / Enemy上の非表示、床への復帰時の再表示を確認。実経路28組の判定不一致0、表示矢印の床高さ不一致0、OutputのError / Warning / Infinite Yieldなし。Tutorial進行コードは変更なし（全Tutorial完遂は未検証）。[確認記録](../reports/Tutorial_Floor_Only_20260916/build_report.md)。

## 2026-09-16 — Treadmill availability guides（Completed）

- 使用可能なベルトだけにClient専用Chevronを表示し、常時Tweenで流す。正規CanUseTreadmillの結果を通知し、表示専用のRebirth/GamePass判定は追加していない。
- Billboardは受理済み利用機種から青なら×2のみ、緑なら×3のみ非表示。通常・Premium・退出後は両方表示可能。MaxDistance100、既存デザイン・位置を維持。下記の初回実装時の全機種両方非表示を置換した。
- Rebirth2/3/4/5、通常・青・緑の実利用、Premiumの所有/未所有/効果無効を隔離fixtureで確認。最終通常PlayはError / Warning / Infinite Yieldなし。隔離QA中は既存ランキング保存経路の警告1件を記録。
- Premium実購入と複数Client同時接続は未検証。PassId0等の本設定は変更なし。[検証報告](../reports/Treadmill_Availability_Guides_20260916/build_report.md)。

## 2026-09-16 — Treadmill multiplier billboards（Completed）

- ConfigへMultiplierBillboardを追加。各2台中央の×2/×3を本人のClientで各1個生成。MaxDistance100、Size16×10 × TextScale1.5、高さOffset12。
- 近距離表示、距離外非表示、斜めCamera追従、実Normal Treadmill利用中の両方非表示、退出後再表示を確認。既存Strength / Rebirth表示維持。Server側Billboardは0。
- 最終通常PlayはRuntime Error / Warning / Infinite Yield 0。途中の別作業によるAuraConfig構文エラーと関連起動失敗は報告へ分離記録。AuraConfig / TrophyRewardConfigは今回の変更に含めない。
- 複数Client同時接続は未検証。[実装・Play報告](../reports/Treadmill_Multiplier_Billboards_20260916/build_report.md)。

## 2026-09-16 — Treadmill frames and group mats（Completed）

- +3/+5の明るいベルトを維持し、側面・支柱・上部・操作パネル外枠まで濃色で統一。MatColorをConfigへ追加し、さらに濃色の2台共用マットを各1Part生成。
- マットは28×0.2×24stud。元の4枚はRuntime非表示・物理設定保持。Premium / Normal、Training、Rebirth、付与式、Interval、DataStoreは変更なし。
- 実Trainingで倍率3/5とRebirth補正込み実付与7.5/17.5を確認。QA撤去・保存先復旧済み。最終PlayはError 0 / Infinite Yield 0、既存ランキング保存Warning 1件を観測。
- [実装・Play報告](../reports/Treadmill_Group_Mats_20260916/build_report.md)。

## 2026-09-16 — Treadmill two-tone frame colors（Completed）

- TreadmillConfig.StrengthColorsをBeltColor / FrameColorへ分離。既存ベルト色を維持し、+2へ濃い青RGB(20,65,150)、+3へ濃い緑RGB(20,100,55)のフレーム色を追加。
- BeltはBeltColor、ConsoleAccentとFrameAccent×2はFrameColorを使用。Premium / Normalと残すべき灰色・金属部品は変更なし。
- Config差し替えPlayでFrameColorだけが反映されBeltColorが維持されることを確認。最終PlayはRuntime Error / Warning / Infinite Yield 0。[実装・Play報告](../reports/Treadmill_Frame_Colors_20260916/build_report.md)。

## 2026-09-16 — Treadmill Strength reward colors（Completed）

- TreadmillConfig.Typesの実Multiplierを表示色のキーとして再利用。2はBlue、3はGreen。見た目専用Strength値は追加していない。
- Tredmill04〜05 / 02〜03のBelt、ConsoleAccent、FrameAccent×2をTrainingManager初期化時に着色。残すべき灰色フレームとNormal / Premium機器は維持。
- 数字表示は×2 Strength / ×3 Strengthのまま。選択PartのSize / CFrame / Material / Transparency / CanCollide / CanTouch / CanQueryは変更なし。
- 隔離Storeで利用判定中のIsTraining=trueと既存式による実加算を確認。Multiplier、Interval、装備・Rebirth・Potion・VIP計算は未変更。
- Config差し替え反映と最終通常Playを確認。Runtime Error / Warning / Infinite Yieldなし。
- 根拠：[実装・Play報告](../reports/Treadmill_Strength_Colors_20260916/build_report.md)。

## 2026-09-16 — Configurable World1 wall UI layout（Completed）

- `WallDisplayConfig.WallUI`へ`Scale=0.8`、`StageGap=0.4`を集約。StageWallDisplayClientの単一経路でWorld1 Stage1〜10のWall .1〜.4へ適用。
- ScaleはHP Gauge、内包HP数値、StageNumber、Heading、UIStrokeへ適用。StageGapはStageNumber下端からHP Gauge上端までの実隙間として計算。
- 80studへの一時変更でもGauge 4.104stud、Stage 5.4stud、Gap 0.4studを維持し、最終Wall高さ56.25studへ復元。
- Stage1で75/100更新とCarry後100/125、Stage6で74.6K、Stage10で2Mを確認。BossDisplaySurface 250/250、Transparency 0.5、Offset 0.5を維持。
- QA Script撤去後の通常PlayでRuntime Error / Warning / Infinite Yieldなし。Combat / Balance / Map / DataStoreは変更なし。
- 根拠：[実装・Play報告](../reports/World1_Wall_Display_Config_20260916/build_report.md)。

## 2026-09-16 — Dumbbell Buy button seen notifications（Completed）

- 現行seen-based通知を維持し、Dumbbellタブ用DumbbellsとBuyボタン用DumbbellBuyの既読集合を分離。
- タブはDumbbellページを開くと現在購入可能Itemを既読化。Buy通知はScrollingFrameとButtonの実表示矩形が交差したItemだけを既読化し、購入を条件にしない。
- DumbbellServiceへ購入処理と通知Stateが共有する購入可能判定を集約。所有・Win・Category・Price・保存状態を同じ経路で検証。
- 隔離StoreのPlayでA〜Gを確認。画面外NORMAL_03〜05はタブOpen後もBuy未既読、スクロール後に消去・保存、再Join非復活。次のNORMAL_06解放で再通知、所有後は対象外。
- Aura／Speed／Itemsと購入Remoteの処理は変更なし。検証コード撤去・通常Store復元後の52秒PlayでRuntime Error / Warning / Infinite Yieldなし。
- 根拠：[実装・Play報告](../reports/Dumbbell_Buy_Seen_Notifications_20260916/build_report.md)。

## 2026-09-16 — Configurable Boss display surfaces（Completed）

- CombatClientがPlayer別BossDisplaySurfaceをRuntime生成。Stage1〜9は次Stage .1、Stage10は境界壁基準。同じ幅・高さ、厚さ0.05、透明度0.5、Wall表面との間隔0.5stud。
- BossDisplayConfigへHeightRatio=0.6 / VerticalOffset=0とStageOverridesを集約。EnemyManagerはBoss生成時に見た目Modelの実寸を一度計測し、UI専用属性へ記録する。Combat / Balance / Map / DataStore Schemaは変更なし。
- Stage1→2実Combatで、接触前250/250、Carry適用後198/250、141→84→27→0、撃破後Stage2 Wall 300/300を確認。
- 全10Stageの表示Fixture、4設定とStage Override、Wall高さ非依存、Raycast非干渉、Boss1.25倍後の再生成追従を確認。Streaming時は実HPを保持して表示生成を再試行する。
- 複数Client同時接続とStage10実Combat完走は未実施。Client専用生成とサーバー上のSurface不在を確認。
- 検証用保存先でランキング保存Warningを1件観測。検証コード除去・通常設定復元後の145秒PlayではRuntime Error / Warning / Infinite Yieldなし。詳細は[報告](../reports/World1_Boss_Display_Surface_20260916/build_report.md)に分離記録する。

## 2026-09-16 — World1 Balance Config統合（Completed）

- **World1BossConfig = World1 Stage1〜10の唯一のBalance正本**。Stage1〜5のWall固定値、Stage2特殊倍率、Stage3〜5の実Runtime RequiredStrength 450 / 2,000 / 5,000を維持。
- Stage1WallManager / BossCombatService / StudioDebugServiceの参照を移行。Wall.Configは正本データを参照する互換窓口。旧後半Configを参照ゼロ・Play合格後に削除。
- 統合前後のPlayで520項目が一致。統合API/互換窓口92項目、実PlayerのDebug Snapshotも確認。World2全10 Stageは不変。
- 実サービス＋独立したPlayer代替オブジェクトでLottery境界、通常/当選/不当選戦闘、Carry、再開、Skip、Stage1〜10進行を確認。全Stageの実Character移動・接触操作と複数Player同時試験は今回未実施。
- 検証Script除去後の通常PlayでRuntime Error / Warning / Infinite YieldのConsole出力なし。変更は4 Scriptと旧Config削除のみ。履歴Snapshotは保持。
- 同じローカルフォルダーのmainをGitHub mainへ接続。ローカル差分11件は.git内に原本保存、固有260件は残してCommit対象外とした。
- 根拠：[統合・検証報告](../reports/World1_Config_Consolidation_20260916/build_report.md)。


## 2026-09-16 — World1 Wall UI scale / persistent HP

- 27stud Wall時の580x270 Canvasを基準に、Canvas高さをWall高さ×10へ変更。現在の通常WallはHPバー基準高さ5.13studとStage表示へScale=0.8を適用し、Stage表示はHP上端からStageGap=0.4stud上。物理Wall高さ56.25は維持。
- Wall .1〜.4は現在攻略対象になった瞬間からStage/実HPを表示し、撃破済み・未来Wallは非表示。
- WallClearedへ既存のCarry適用後Snapshotを添付し、一括反映。MaxHPによる仮表示を行わない。
- Boss解放直後はサーバーの実HPを表示。Boss Carryは既存どおり予約後、接触時Beginで適用する。UI側で先行消費・再計算しない。
- Stage1〜9のBossは次Stage .1壁面、Stage10は既存境界壁。個人表示、Combat / Carry / HP / Balance / Map / DataStoreは維持。
- 検証範囲と結果は[報告](../reports/World1_Wall_UI_Scale_20260916/build_report.md)を参照。

Version: 1.3 / 監査・更新日: 2026-09-15

## 2026-09-16 — World1 Wall / Boss UI positioning（Completed）

- Stage表示とBoss Gaugeを既存Wall HP領域基準へ配置し、Wall高さ変更で上昇しないUI基準を保存。
- Wall .4撃破からBoss接触前の250 / 250表示、接触後のHP更新、撃破後のStage2 .1と300 / 300即時表示を実Combatで確認。
- Stage1〜10の共通クライアント処理。通常Wall全40枚はWallDisplayConfigによりStage表示下端とHP上端の間隔0.4stud。Stage10 Boss UIは独立した既存境界壁経路を使用。
- 最終PlayのError / Warning / Infinite Yieldなし。複数Client同時Playは未実施。
- 根拠: [実装・検証報告](../reports/World1_Wall_Boss_UI_20260916/build_report.md)。

## 2026-09-16 — Mobile / Tablet HUD regression fix（Completed）
- 標準Dynamic Thumbstickの大きなCapture領域をHUD障害物として扱っていたため縮小したSmartphone LeftMenuを、表示部品基準の通常倍率へ復元。
- Strength HUDをMobile共通でViewport全幅の中央Anchorへ変更。iPhone 17 Pro / Fire HD 10相当で中心差0pxを実測。
- Tablet LeftMenuは倍率0.423224、位置19,105、サイズ127.814x194.683pxで変更前後同一。Touch Zone、LandscapeSensor、Desktop非Touch分岐は維持。
- Runtime Error / Warning / Infinite Yieldなし。根拠: [実装・検証報告](../reports/Mobile_HUD_Regression_20260916/build_report.md)。

## 2026-09-16 — Mobile Touch Zone restoration（Completed）
- `b50eee5`で追加したSmartphone / Tablet別サイズ、最大Clamp、LeftMenu / Jump境界、Safe Area計算を撤回し、PlayerModule標準Dynamic Thumbstick範囲へ復元。
- `DynamicThumbstickFrame`の背景だけを常時透明化し、Thumbstick / Knob / Drag表示と入力判定は維持。
- iPhone 17 Pro相当で399.6x302px、Fire HD 10相当で483.6x460.7pxの標準範囲を実測。両端末でStarterGui / PlayerGuiのLandscapeSensorを維持。
- DesktopはTouchGuiなし。Runtime Error / Warning / Infinite Yieldなし。根拠: [実装・検証報告](../reports/Mobile_Touch_Zone_Restore_20260916/build_report.md)。

## 2026-09-16 — World1 Enemy Wall height alignment（Completed）

- World1 Stage1〜10の敵Wall .1〜.4、計40枚だけを高さ27から56.25へ変更。
- 底面Y=2を維持して上端Y=58.25へ延長し、既存の左右側面Wall上端と一致。幅・厚さ・回転・CombatZoneは維持。
- 最大Muscle段階のJumpで未到達Wallを越えられないこと、StageSurface / Wall HP / MiniBoss SurfaceGuiの追従を確認。
- 側面Wall、Stage10BoundaryWall、Gate、World2、Combat、Balanceは変更なし。Runtime Error / Warning / Infinite Yieldなし。
- 根拠: [実装・Play報告](../reports/World1_Enemy_Wall_Height_20260916/build_report.md)。

## 2026-09-16 — Runtime PlayerGui LandscapeSensor（Completed）

- `TouchControlZoneClient`がPlayerGui取得直後に`PlayerGui.ScreenOrientation=LandscapeSensor`を設定。
- StarterGui側のLandscapeSensor、既存Touch Zone、Clamp、HUDLayoutは変更なし。
- iPhone 17 Pro / Fire HD 10相当でStarterGui・PlayerGui両方の実行時値と既存Zone寸法を確認。DesktopはTouchGuiなし。
- Runtime Error / Warning / Infinite Yieldなし。根拠: [Play報告](../reports/PlayerGui_LandscapeSensor_20260916/build_report.md)。

## 2026-09-16 — MiniBoss UI Wall Surface placement（Completed）

- Stage1〜9のMiniBoss Gaugeを次Stage .1 Wall上空のBillboardから、既存StageSurfaceと同じ壁面のSurfaceGuiへ修正。
- Boss名、STAGE、HP Bar、Current / Max HPとリアルタイム更新を維持。撃破直後は同じ壁面で次Stage .1通常表示と満タンHPへ即時切替。
- Stage1→2をPlay確認。Stage2〜9は共通経路、Stage10は従来Boss追従Billboardを維持。
- Stage進行、Combat、HP、Balance、Map、DataStoreは変更なし。Runtime Error / Warning / Infinite Yieldなし。
- 根拠: [実装・Play報告](../reports/Miniboss_UI_Wall_Surface_20260916/build_report.md)。

## 2026-09-16 — Mobile Landscape / Touch Zone（Completed）

- `StarterGui.ScreenOrientation=LandscapeSensor`へ変更。Portrait用UIは追加していない。
- 標準Dynamic Thumbstickを維持し、Smartphone / Tablet別の入力Zone計算とTablet最大320x300px Clampを追加。
- 入力Zoneを左側LeftMenu右端とJumpButton左端の間へ制限。Fire HD 10相当で表示中Interactive UIとの重なり0を確認。
- 表示専用Potion / HP / Strength HUDはZone回避計算から除外。DesktopはTouchGuiなしで従来動作を確認。
- iPhone 17 Pro相当、Fire HD 10相当、iPad Pro 13相当、DesktopをPlay確認し、Error / Warning / Infinite Yieldなし。
- 根拠: [実装・検証報告](../reports/Mobile_Landscape_TouchZone_20260916/build_report.md)。

正本：[GAME_SPEC](GAME_SPEC.md) / [BALANCE_SPEC](BALANCE_SPEC.md) / [UI_SPEC](UI_SPEC.md)。実装済みとPlay検証済みは別に記録する。初期版は読み取り専用監査で作成し、その後の許可された変更は日付と証拠を添えて追記する。Publish・Git初期化/Commitは未実施。

## Completed

- 2026-09-16：World1 Stage遷移UIを改善。Stage1〜9のMiniBoss戦中は次Stage .1のStage/Wall HPを隠して同じ壁上部へMiniBoss HPを表示し、撃破直後に次Stage .1のStage/満タンHPへ切替。Combat順序とBalanceは変更なし。[検証報告](../reports/World1_Miniboss_Wall1_UI_20260916/build_report.md)。

- 2026-09-16：Inventoryの「！」を購入可能／未購入ベースからタブ単位の未確認ベースへ変更。Dumbbells／Items／Aura／Speedを個別に確認済みにでき、親Inventoryは未確認タブの論理和で表示する。`InventoryNotificationSeen`を後方互換でPlayerDataへ追加し、同じ内容が再Joinで復活しないことをPlay確認。[検証報告](../reports/Inventory_Seen_Notifications_20260916/build_report.md)。

- 2026-09-15：Levelを累積Threshold方式から保存Level/LevelProgress方式へ変更。Requirement全数値・暫定式・戦闘バランスを維持。旧データは従来Levelを維持してProgress=0へ移行。共通付与、Carry、複数Level Up、Save中の獲得、Reward再試行、実PlayerのHUD/歩行/Training/Rebirth/専用Store再Joinを検証。[報告](../reports/Level_Progress_20260915/build_report.md)。
- 過去の「推奨Levelと累積Thresholdの一致」は旧方式の履歴。今後はLevelと累積戦闘Strengthが独立した状態であり、育成時間・獲得量の再バランスは別Phase。

- 2026-09-15：Lv51〜200の全150 Thresholdを明示テーブル化。Lv1〜50を保持し、World2全10アンカーとの不一致K16を解消。Lv201以降は暫定+250M/Level、上限10,000。全境界70,335チェックとHUD150チェックが合格。[Levelカーブ報告](../reports/Level_Curve_20260915/build_report.md)。

- 2026-09-15：World2独自Balanceを3 Configへ反映。10 Stageの推奨Lv/RequiredStrength/Wall/BossをPlayで459項目検証し、25BのクライアントAttribute受信と表示も確認。旧World2HPScaleとWorld1への依存を除去。World2 Combat・移動・Inventoryは未接続/未実装のまま。[検証報告](../reports/World2_Balance_20260915/build_report.md)。

| 項目 | 確認できる現在状態 | 検証根拠・限界 |
|---|---|---|
| World1 Stage1〜10 | 個人Wall/Boss進行、Stage Clear、Stage10 WorldCompleteの接続あり | 今回は静的監査、後半は既存Play記録あり |
| World1 Map拡張 | Floor幅90、Stage6〜10を含む拡張配置 | 実Object確認。古い寸法属性が残る |
| Stage6〜10 Boss差し替え | 現在の5体とDisplayHeight36/48/44/56/52 | Model/Templateとソース確認 |
| World1 Stage1〜10 Config統合 | World1BossConfigを唯一の正本とし、後半RequiredStrength37,315/81,865/196,915/462,965/1,018,015を維持 | 今回の統合前後Playで数値・サービス挙動一致 |
| 大型Boss Collider | Stage7〜10再調整、Stage6維持、後半専用CombatZone | 既存Playで4方向×5Stage接触・開始・離脱を確認 |
| Boss HP UI改善 | 長いBoss名、個人Boss HP、Wall/Boss排他表示 | 現行ソースと既存Play UI観測 |
| RewardPad黄色Pad化 | 黄色Neon Pad、本人所有、踏み込み取得 | Template/Service/Client接続確認 |
| World2Gate作成 | WORLD 2、LOCKED/ENTER、Player別ローカル切替 | 表示のみ。配置属性は暫定 |
| HighestUnlockedWorld | 初期1、Stage10 Pad取得で2、永続化経路 | 保存コード監査。今回DataStore操作なし |
| World2 Map Graybox | World2Map、10 Stage、AuthoringOnly | 実Object確認。移動/戦闘の完了ではない |
| 既存育成・装備・報酬・課金経路 | Training、Rebirth、Inventory/Merge、Daily/Time、Shop/Receipt | ソース接続を確認。今回全機能の再Playなし |
| SPEC初期版・レポート整理 | 正本4文書、開発ルール、入口、履歴を作成 | 今回の成果。既存37ファイルの内容を保持 |

既存の後半Play結果：適正Strength・GloveなしでWall1〜4は各Stage12攻撃、Bossは5攻撃。CarryによりBoss開始90%のケースを確認。最終通常PlayのError/Warning/Infinite Yieldは記録上0/0/0。今回の新しいRuntime試験結果ではない。

根拠：[World1後半報告](../reports/World1_Stage6_10_20260915/build_report.md)、[最終CSV](../reports/World1_Stage6_10_20260915/final_balance.csv)、[今回監査概要](../reports/Implementation_Audit_20260915/audit_summary.md)。

## In Progress

- 2026-09-15：World1 Stage6〜10の間隔調整を実施。EnemySpawnを+Zへ4 / 3.5 / 3.25 / 6 / 1stud移動し、実Scaleを維持。接近・戦闘・UI・PadのPlay確認は完了。
- World1 Stage6〜10のWall .4撃破後のBoss間隔調整は完了。低視点からWall越しにBoss全体を見せることは要件ではない。詳細は[間隔レポート](../reports/World1_Stage6_10_Spacing_20260915/build_report.md)。
- SPEC v1.0の初期整備は完了。未確定仕様は下記Known Issuesに分離済み。
- World2はGraybox・表示・保存権限の基盤まで。移動・Combat・Stage進行は未実装。World2専用Balance（推奨Lv60〜200、Boss15M〜25B）はConfig反映済み。World2推奨LevelとThresholdの一致は検証済み（K16解決）。World2専用Inventory方針は設計確定・未実装。

## Next

以下は推奨順序であり、新機能実装の着手承認ではない。

1. **World1の未確定境界を決める**：K03 BossへのCarry維持、K02 Stage1〜3の推奨Lv差と暫定Win値の扱い。World2永続解放はStage10 RewardPad取得で確定。
2. 異なるHighestUnlockedWorldを持つ複数PlayerのGate表示試験。World1共有Boss/Colliderへの相互影響も範囲を決めて確認する。
3. Mobile/Tabletの表示・タッチ操作を実機/Emulatorで検証。無条件のUI拡大はしない。
4. World2 Config反映は完了。次回は暫定Levelカーブの育成時間、専用Inventory/Item設計とEnemy Assetを整理したうえで、指示された限定Phaseで移動→Combat→Stage進行を接続する。今回は次機能へ進まない。
5. Gitは既存Projectのmainをorigin/mainへ接続済み。完全なStudio保存物と自動同期の方式は今後決定する。

## Known Issues

「仕様不一致・要確認」は、確認できた差や未確定状態を意味する。未確認のものをRuntimeバグと断定しない。

| ID | 分類 / 優先 | 実装で確認した事実・差 | 確認すべき判断 |
|---|---|---|---|
| K01 | 名称 / Low | ユーザー英語名Train to Smash Everything、Studio表示+1 スマッシュ&クラッシュ、Project Smash_and_Crush | 公開タイトル・英語表記をどこまで統一するか。公開ページ未照合 |
| K02 | Balance / High | 現行Stage1〜5のRequiredStrengthは50/100/450/2,000/5,000、推奨Lvは8/10/15/20/25。Levelと累積Strengthは独立。旧Threshold比較は過去の記録 | Config統合では実Runtimeを維持。前半Wall固定値・Stage2特殊値・Rewardを自動変更しない |
| K03 | Carry / High | Wall余剰が次WallだけでなくBossへ渡る。後半適正StrengthではBossが90%開始 | Wall4→Boss Carryを維持するか。現行挙動を仕様化するか変更するか未決 |
| K04 | World解放 / Resolved | Stage10 Boss撃破でWorldComplete、Stage10 **Pad取得**でHighestUnlockedWorld=2 | 永続World2解放はPad取得で確定。現行仕様を維持 |
| K05 | Map/機器属性 / Medium | StageWidth20（一部30）・StageLength28（一部36）等に対し実Floor幅90・可変長。古いPivotも残る。Treadmill TickInterval1に対し実行時0.5 | 今後の座標・数値参照元をFloor/Spawn・現行Configへ限定。今回属性修正なし |
| K06 | 命名 / Low | Treadmill Type Rebirth7はRequiredRebirth5 / Tier3 | 名前だけ旧式か。表示はConfigからRebirth5を生成している |
| K07 | Merge / Medium | Dumbbell定義Mergeable=true、実際のItemMergeServiceは通常Itemのみ | Dumbbell Mergeを将来作るか、メタデータを整理するか |
| K08 | Reward確率 / Medium | Daily/Time/CommunityのItemRollは受取時CurrentStageでRarity制限。最高Stageではない | Lobbyへ戻ってStage1で受け取った場合の制限を維持するか |
| K09 | World2 / Config反映済み・機能未接続 | 独自Balanceを3 Configへ反映し旧×25,000方式を除去。Inventory設計は到達時解放・World1 Item性能維持のまま | World2 Item/Enemy、移動、Combat、Stage進行は別途指示後に実装 |
| K10 | 商品設定 / Medium | Premium TreadmillはAdministrator Treadmill（1982996954）として設定済み。WinProducts空・未使用Win商品IDは継続 | Premium TreadmillはClosed。BUY WIN商品は引き続き要確認 |
| K11 | テスト設定 / Medium | Studio GamePassEffectsEnabled=false、ForceSpeedPremiumUnowned=false | 所有確認と効果テストを分離。本番/Studioの試験条件を明記する |
| K11-P | Production製作者Game Pass試験 / Implemented | ProductionCreatorGamePassEffectsEnabled=false、対象UserId=7467238848 | 指定製作者だけ効果OFF。一般Player・所有表示・Developer Productは変更なし |
| K12 | 多人数検証 / High | GateはLocalPlayer別表示だが同時接続試験なし。Bossモデル/Colliderは共有要素あり | LOCKED/ENTER併存、同時Boss戦・撃破再生成への相互影響を検証 |
| K13 | Mobile / Tablet / Medium | Tablet左メニュー倍率3.0＋領域補正、端末別の最終倍率は可変 | 縦横/ノッチ/操作ボタン/長いBoss名を再検証。今後調整の可能性 |
| K14 | バージョン管理 / 接続済み | このPCの既存ProjectにGitを導入し、mainをGitHub origin/mainへ接続。差分11件の原本とローカル固有260件は保全 | 通常のpull / commit / pushで管理。Studio自動同期・完全Place保存方式は未導入 |

| ID | 分類 / 優先 | 今回確認した差 | 判断 |
|---|---|---|---|
| K16 | Levelカーブ / Resolved | Lv51〜200の明示Threshold導入によりWorld2全10アンカー完全一致。Lv1〜50維持 | 中間補間値・Lv201以降+250Mは暫定。育成時間とItemの確認後に再調整 |
| K17 | HP表示精度 / Medium | 指定例15M/500M/1B/2.5B/25Bは正常。1.25Bは1.2B、5.25Bは5.2Bに丸められる。旧方式では現在/次閾値が同じ短縮表示になる問題もあった。新HUDはProgress/現在Requirement。小数1桁の丸め自体は維持 | World2 UI接続前に表示桁数を確認。今回Formatter変更なし |
| K18 | 旧メタデータ / Low | World2 PlaceholderのRequiredStrengthStatus=Pendingは既存の要確認事項。World1 Config内の旧World2依存コメントは統合時に整理。World2 Balance正本はWorld2Config.Stages | 今回World2 Modelは変更なし。Pending属性を現行Balance判定に使わない |

K02/K05/K06/K07は現在実装と推奨値・旧コメント・属性の差として記録した。どちらかに勝手に統一していない。

**K15 — Closed**：Wall .4撃破後にBossが近すぎる問題はEnemySpawn後退で調整完了。Wall .4手前の低視点からBoss全体を視認することは要件ではない。

## Deferred

- 暫定Levelカーブの育成時間・Lv201以降の本バランス調整。Level Threshold実装とWorld2 Balance Config反映は完了。
- World2専用Item/Inventory実装、Enemy Asset選定、移動、Combat、Stage進行。
- World2Gateの本配置と移動連携。現在は暫定BackWall preview。
- BUY WIN付与量と商品設定。
- 多人数試験、端末別UI調整、育成所要時間の計測。
- Rojo等の同期導入、完全Placeの保存形式決定。Git Repository接続は完了。
- Blenderキャラクター制作は別作業。今回のゲーム監査から完成NPCとして計上しない。

## Do Not Change Without Confirmation

- 最新ユーザー指示で範囲が明示されていない大規模仕様変更、リファクタ、デザイン変更。
- World1 Stage6〜10の確定Balance、DisplayHeight、Boss名、Carry方針。
- World1 Stage1〜5のHP/RequiredStrength/RecommendedLevel/Collider/Reward。
- World2の旧HP基準を共通World1Config経由で間接変更すること。
- Level/Strength式、Rebirth、Win、Item Drop、Stage Skip価格、課金付与、DataStore Schema。
- WorldCompleteとHighestUnlockedWorldの発火条件、セーブ互換性。
- UIデザインの全面変更・Tablet倍率の無条件全体適用。
- 未指定のPublish、Git Commit、元レポートや証拠の破棄。

上記は追加の毎回確認を要求するものではない。ユーザーが当該範囲を明示的に許可した場合はその指示に従い、必要な監査・実装・検証を進める。初期SPEC作成時は文書整理だけが許可されていた。以後の作業はその時点の最新ユーザー指示を優先する。

## 検証状態と更新方法

初期監査：Edit状態のSource123本、全LuaSourceContainerの指紋、対象Object/Config/Map/UIを読み取った。この工程ではPlayしていない。

2026-09-15間隔調整：Stage6〜10の歩行接近・戦闘・UIをPlay確認。検証コード除去後の通常PlayでError/Warning/Infinite Yieldは0/0/0。視認性の未達を含む検証範囲は間隔・視認性レポートを参照。

今後Completedへ移す際は、変更したScript/Config/Object、SPEC差分、Play/Regression結果、未検証範囲、日付を残す。変更候補と承認済み仕様を分け、CHANGELOGへ確認できる変更だけを追記する。

## LevelProgress移行後の注意

- Lv1 Requirement=0は数値維持のため、最初の正の獲得でLv2へ進む。Join/Rebirth時点はLv1・Progress0を維持。
- 上限10,000ではLevelは増えず、StrengthとProgressを保持する。
- /setstrengthは管理用の累積戦闘力変更のみ。Level/Progressは逆算しない。旧テストのThreshold前提は履歴として残し、今回の新規検証と区別する。
- Production Store名・既存保存項目は維持。新規3項目は欠損時移行し、不正/未知Versionは読込を拒否して上書きしない。旧仕様の稼働サーバーとの同時運用・本番課金は今回未検証。
- Item/Training/Potion/VIP倍率やWorld推奨Level調整には進んでいない。
## 2026-09-15 — World2 Gate travel

- 実装済み: World2Gate侵入検知、Player別確認UI、Server側解放・距離再検証、World2LobbySpawnへの同一Character移動、`CurrentWorld=2`。
- 確認済み: 未解放時非表示、NO後の退出待ち、再侵入表示、YES移動、Strength/Level/LevelProgress/Win/Rebirth維持。
- 未実装: World2 Combat、World2 Stage進行、World2 Reward、World1 Return Gate。
## 2026-09-15 — World1 / World2往復

- 実装済み: World2 Lobbyの`World1ReturnGate`、共通Modal、Server検証、正式World1 Spawnへの同一Character帰還、`CurrentWorld=1`。
- Play確認済み: World1→2→1→2、NO後の退出待ち、状態値維持。World2 Combat・Stage・Inventoryは未接続。
## 2026-09-16 — World1 progression rebalance

- Lv1〜50のRequirementを確定カーブへ更新。Lv51以降とWorld2は未変更。
- 当時の後半ConfigをRequiredStrength 37,025 / 81,525 / 196,525 / 462,525 / 1,017,525へ更新した履歴。現在値は下記+10調整後の値で、参照元はWorld1BossConfigへ統合済み。
- Stage1〜5の前半Play Balance、Strength獲得量、戦闘ロジック、Map、課金、DataStoreは変更なし。
## 2026-09-16 — Lv1〜50 requirement floor adjustment

- Lv1〜50のRequirementを一律+10。Lv1→Lv2=10 Strength。
- Stage6〜10の実Combat RequiredStrengthを37,315 / 81,865 / 196,915 / 462,965 / 1,018,015へ同期。Stage1〜5、Lv51以降、World2は未変更。
## 2026-09-18 — Item currency buttons and Dumbbell purchase feedback

- Implemented currency-specific Item buttons: Win text for stars 1–3 and Robux logo plus live Marketplace price for stars 4–5.
- Dumbbell purchase rejection codes now surface through the Inventory status area; insufficient funds include the authoritative item price.
- Verified Studio purchase of `NORMAL_01`: Win deduction, ownership, automatic equip, card/HUD refresh, and ownership restoration after rejoin. Debug Win was restored to 0.
## 2026-09-18 — Exclusive Merge flow and Item currency icons

- MergeFlow now resets all step roots to hidden on every render and enables only STEP 1, STEP 2, or STEP 3 content. STEP 1 gained `0/3 ITEMS` and three guidance sockets; STEP 3 no longer duplicates result text in the status line.
- Common through Rare purchase buttons now use the live Win HUD Trophy image and numeric price; Epic and Legendary retain the standard Robux logo and Marketplace price.
- Server merge validation, item transactions, persistence, badges, pricing, and balance remain unchanged.
## 2026-09-18 — Item notification seen timing

- Removed Items-open and acquisition-time bulk acknowledgement. Added per-Item viewport exposure tracking and deferred acknowledgement on Items exit/Inventory close.
- Inventory and Items-tab acknowledgement are independently persisted per Item within the existing notification set; old plain Seen IDs remain backward compatible.
- Merge cards are excluded. Item acquisition, purchase, equip, merge, balance, and saved-data schema remain unchanged.

## 2026-09-18 — Brighten and simplify Merge UI

- Changed only MergePanelClient_New presentation: brighter purple panels/cards/sockets, gold primary buttons, blue BACK, and a simplified image-and-stars STEP 3.
- Preserved exclusive step visibility and existing server state/request handling. No Server, Item, Balance, Save, or Badge changes.
- Normal Play navigation and visual checks cover PC, iPhone 17 Pro Landscape, and Fire HD 10 Landscape in Studio Simulator. Client-only presentation fixtures supplement 1/2/3+ material states and ★4→★5 without changing Player inventory or sending Merge requests; actual Merge transactions are outside this visual-only regression.
- Removed the temporary presentation fixture and repeated normal Play: STEP 1/2/3 exclusive Visible states, 1/3 disabled state, removed STEP 3 name/identity/result labels, and an empty Runtime console confirmed. Phone ★5 fits at 17px; checked execution controls have no rectangle overlaps. Device Simulator was returned to the normal viewport. Physical devices were not tested.

## 2026-09-18 — Inventory notification exposure and acknowledgement

- DumbbellsのTab Open一括Seen／Buy交差即Seen、AuraのTab Open一括Seen、SpeedのTab Open即Seenを修正。Items 7403ef9と同じ「表示中は維持、離脱時Seen」へ統一。
- 共通Viewport判定は各方向35%、上限32px／24px。Dumbbells／Auraは実表示したIDのみ、Speedは既存Tab通知のみ。入口通知と下位通知は独立。保存は既存集合内のキーを利用しSchema変更なし。
- 隔離Storeの通常Play操作で表示直後維持、Tab／Merge／Close離脱、複数IDのSeen／Unseen分離、再Play復元を確認。PC・iPhone 17 Pro横・Fire HD10横のStudio Simulatorで画面外判定を確認。Items回帰では表示6件だけSeen、未表示3件はUnseen。
- 隔離データでAura／Dumbbell購入・自動Equip・通知条件解消を確認。購入・性能・価格・Equip・Merge・Badge・Server保存処理は変更なし。最初の隔離起動は検証用Store名長超過で失敗し、短い名前へ訂正後のPlayはError／Warning／Infinite Yieldなし。
- 2026-09-16のOpen／交差即Seen記録は旧動作の履歴。現行仕様は上記とGAME_SPEC／UI_SPECを正本とする。
- 検証Script撤去・通常Store復元後の最終Playで各Tab／Merge／Closeを操作し、Runtime consoleが空であることを確認。Editへ戻し変更6ソースの一致確認後、StudioへCtrl+Sを実行。端末確認はSimulatorであり実機検証ではない。

## 2026-09-18 — Merge completed-Item preview / FredokaOne

- STEP 3 HeroをItemMergeStateのResultItemId参照へ変更。Common→Uncommon、Uncommon→Rare、Rare→Epic、Epic→LegendaryでHero星と右側星がServer結果に一致し、Socketは素材を維持。
- InventoryPanel配下の既存・Runtime生成TextをFredokaOneへ統一。PC・iPhone 17 Pro横・Fire HD10横でHeader、Tab、Card、価格、Merge操作、★1〜5を確認。
- 一時日本語Text「アイテムを選択　マージ　購入　戻る」がStudio Playで欠落せず表示されるRoblox fallbackを確認後、テストObjectを撤去。Localization設定は変更なし。
- Merge／購入／Save／Balance、明るい3STEP、Trophy／Robux Iconは変更なし。検証は隔離Studio Storeと表示用seedを使用し、Productionデータへ接続していない。

## 2026-09-19 — Japanese localization terminology quality pass

- Japanese terminology was standardized while preserving every existing English Source and placeholder. Runtime-required `EQUIPPED` and `Normal Dumbbell {number1}` entries were added.
- CSV header, UTF-8 BOM, case-sensitive Source uniqueness, nonblank values, and placeholder parity were verified. Cloud Localization upload remains a separate manual operation.

## 2026-09-19 — Treadmill animation authority

- Removed Server-side Player walk-track control from TrainingManager. The existing TreadmillRunClient now owns one reusable Movement-priority Walk track per Character and follows the accepted `IsTraining`／`TrainingTreadmill` state.
- Standard Animate, Training eligibility, rewards, intervals, multipliers, Premium checks, and save behavior are unchanged.

## 2026-09-19 — Trophy reward feedback

- Added a Player-specific RewardPad Billboard using the existing Trophy icon and the final server-calculated Win reward, including active Double Win.
- Added confirmed-collection-only Win HUD Pop／Shake and reusable local Coin Collect audio. Reward calculation, collection validation, saving, stage progress, and balance are unchanged.

## 2026-09-19 — Treadmill movement animation conflict

- Changed the Client-owned Treadmill animation to Run `913376220` and retained one dedicated Track per Character.
- While the accepted Training state is active, only standard Animate walk／run tracks are weight-suppressed; exit restores their weights and normal Idle／Walk／Run behavior. Standard Animate and all Training gameplay remain enabled and unchanged.
- Changed suppression from exact zero to an imperceptible `0.0001` Weight so Animate retains live locomotion Tracks. Moving exits now restore the original blend immediately without requiring stop／restart input.

## 2026-09-19 — Strength HUD localization

- Split the Strength HUD into one formatted numeric label and one AutoLocalize unit label while preserving the existing single-line centered appearance.
- Reused the existing `Strength → 強さ` Localization entry; Strength, Level, progress, and balance calculations are unchanged.

## 2026-09-19 — Claimed reward button visuals

- Time Rewards and Daily Rewards now render claimed buttons with the same gray-lavender gradient and neutral strokes.
- Locked and ready visuals, claim eligibility, reward contents, persistence, and Localization Sources are unchanged.

## 2026-09-19 — Per-player boss collision gates

- Shared `MiniBossCollider` instances remain non-colliding through wall unlock, defeat, replacement, and streaming; Server/Client `CanCollide` contention remains removed.
- Each Client clones the current Generation's MiniBossCollider geometry into an invisible `PersonalBossCollider_StageXX` only after that Player unlocks an uncleared Boss. Instance / SpawnGeneration changes and periodic streaming retries rebuild it; `EnemyDefeated` disables and destroys it immediately.
- Boss visual-rig BaseParts are forced non-colliding on the Client so Humanoid-managed Torso collision cannot remain behind an invisible defeated Boss. The former 88 x 56.25 Stage-wide PersonalGate is no longer used.
- Boss combat, HP, drops, Trophy feedback, Stage balance, save schema, and DataStore behavior are unchanged.
# 2026-09-19 — Matching Element Set Bonus

- Added one shared ItemMaster-based set predicate for Server Strength calculation and the Item Effect HUD. Matching owned/equipped Protein, Glove, and Training Belt Elements apply a single 1.5 multiplier; no set state or schema is stored.
- Added localized Element Set HUD Sources and retained all Item effects, Best Equip, Merge, reward, and save behavior.
# 2026-09-20 — Boss contact, generation continuity, and Stage 9 visual

- Derived all Stage 1–10 Boss CombatZones from MiniBossCollider geometry and added direction-independent character-root contact while retaining the existing forward trigger.
- Changed World1 per-player Boss encounter identity from Boss Instance to Stage and rebind active sessions across shared SpawnGeneration replacement. Boss events carry SpawnGeneration and the client rejects older-generation HP events.
- Restored the exact UTF-8 Stage 9 visual name `Lirilì Rilà`; the existing Stage09Boss template and CollisionReference remain authoritative.
# 2026-09-20 — Boss HP visual-top alignment

- Added UI-only visible BasePart bounds for all Stage 1–10 Bosses after final scale and floor placement. Helper roots, bones, transparent geometry, collision references, MiniBossCollider, and CombatZone do not affect HP placement.
- Replaced HeightRatio placement with BossDisplayTopY plus the common two-stud VerticalOffset. Boss/Wall UI size, Boss scale, combat, generation continuity, and balance remain unchanged.
# 2026-09-20 — Developer-only custom avatar

- Restricted the existing Hisarino head and layered body jacket auto-equip path to developer UserId `7467238848`. Non-developer CharacterAdded events are not subscribed by this script and their Roblox avatars remain untouched.
- Developer cleanup now runs after `CharacterAppearanceLoaded`, removes Classic Clothing, preserves the Dynamic Head `FaceControls`, and normalizes `Hisarino_hair` / `Hisarino_Body` to one instance each on spawn and respawn.
- Accessory cleanup uses an explicit Character-child name allowlist: only `Hisarino_hair` and `Hisarino_Body` survive, regardless of AccessoryType.
# 2026-09-20 — World1 muscle progression rebalance

- Muscle stages now reach Lv3 / 6 / 10 / 15 / 20 / 25 / 30 / 35 / 40 / 45 using cumulative `LevelProgression.Advance` Strength.
- Stage10 is capped at Height 3.30, UpperTorso X/Z 2.68/2.40, and UpperArm X/Z 3.10/3.10 so the developer Layered Clothing remains inside the verified rendering range.
- Strength, Level progression, Rebirth, combat, training, Items, and avatar assets are unchanged.

# 2026-09-24 — World2 SCP boss integration

- Implemented the ten confirmed SCP placements using existing EnemySpawn/Floor anchors and shared world-scoped combat/rendering. SCP-131 is excluded and preserved; overlapping placeholders are archived intact.
- Verified all ten World2 stage advances, matching HP displays, floor contact, no shared boss replacement, respawn, gate round trips, and World1 Stage1 regression. Final clean normal Play had no Error/Warning/Infinite Yield.
- Two-client rendering remains unverified (two-participant combat-state isolation passed). World2 Trophy/Win rewards remain unconfigured. See [report](../reports/World2_SCP_Bosses_20260924/README.md).

## 2026-09-30 — World1 Run Inventory Phase 5B

- World1 Boss Dropの通常Itemだけをサーバー専用RunInventoryServiceへ未確定保持する。初期Capacity=5はGetCapacityへ集約し、数量合計で数える。既存OwnedItems／EquippedItemsは枠に含めず、取得時のPlayerData保存は行わない。
- RunIdとDrop IDで旧Run混入・二重付与を拒否。満杯の当選Itemは追加せず、既存Drop演出にRUN INVENTORY FULLを表示する。抽選率・Rarity率は維持。
- 死亡・Character再生成・Run初期化で未確定品を消去。退出時は保存せず破棄。World移動はWorld1取得受付を一時停止／再開する。既存Trophy帰還もRun初期化のため、このPhaseでは持ち帰りにならない。
- Daily／Time／Community／Shop／MergeとWorld2は従来のPermanent付与を維持。戻る・持ち帰り確定・HUDカウンター・Capacity購入は未実装。
- 検証範囲と既存Console問題は[Phase 5B report](../reports/World1_RunInventory_Phase5B_20260930.md)を参照。Place未保存。

## 2026-10-06 - Y02 / CurrentCloud purchased Feedback limited verification

- Target: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`. SHA-256 before/after: `9489e05420e6c071c8bea860d19c85d80f44688ffce52406466e9304e2392b60`. No rbxl modification or rewrite: the requested startup and prompt connection already exist in this disk file. No new instance, folder, backup or other rbxl.
- Confirmed discrepancy: two Edit Studios both named MergeToForge_CurrentCloud.rbxl. Studio `6aaa480e-8eaa-4a16-9c9e-f9105f39e818` matches both disk Sources; Studio `960b0bbd-746d-4792-bcfe-0c0dbf7e615d` (PlaceId 0) has no Feedback startup in LeftMenuClient and the original PromptShown-based FeedbackClient. Thus the latter loaded model cannot start purchased Feedback with purchased Main disabled. This is an observed stale loaded-model discrepancy; which window the user operated and the published game version remain unconfirmed. Neither Studio was edited or saved.
- Checked Full Paths: `StarterGui.StrengthGui.LeftMenuClient`, `StarterPlayer.StarterPlayerScripts.Services.FeedbackClient`, and the three same-named `Workspace.Mailboxes.Feedback.Part.ProximityPrompt` instances. LeftMenuClient Disabled=false; StrengthGui Enabled=true. The task.spawn bootstrap precedes HUD waits and requires only FeedbackClient.start().
- Current physical equipment: all three Feedback models are directly under Workspace.Mailboxes, with enabled default-style Give Feedback! prompts and Feedback=true on the actual prompt-parent Part. Prompt-parent positions: (-57.886,9.218,50.028), (61.446,9.218,53.297), (5.271,9.218,1.506). No additional Feedback models found under Workspace in the matching Edit model. Multiple children are named Part; first-name lookup is not sufficient to identify a prompt parent. Filter uses the actual event prompt.Parent and matches all three. These are Edit positions; runtime Lobby/player reachability is not verified.
- PromptTriggered passes the prompt and player; one global subscription and started guard prevent duplicate connections. The local-player/identity/attribute checks precede the yielding SocialService:PromptFeedbackSubmissionAsync() pcall. prompting remains true during the dialog and resets after normal return/cancellation/timeout/error. This is static control-flow verification, not runtime cancellation testing. No rewards, remotes, claims, new UI or saves.
- ServerScriptService.Main Disabled=true, StarterPlayer.StarterPlayerScripts.Main Disabled=true, StarterGui.ScreenGui Enabled=false remain unchanged. Other purchased systems are not started.
- Checks: both exact disk Sources compiled with existing Luau compiler --null; fresh disk reDecode passed (87,068 instances); all UniqueIds unique; lossless encode equals disk bytes. No Play, actual submission, Studio Save/Publish. Cloud reflection and application execution are unverified.
- Roblox official API: https://create.roblox.com/docs/reference/engine/classes/SocialService#PromptFeedbackSubmissionAsync and https://create.roblox.com/docs/reference/engine/classes/ProximityPromptService#PromptTriggered . Standard Feedback requires the published game in the Roblox application.
- Repository mapping: no corresponding current LeftMenuClient/FeedbackClient file exists in tracked src. The only tracked LeftMenuClient is the immutable 2026-09-15 audit snapshot; TrophyRewardFeedbackClient is unrelated legacy Smash reward presentation. To preserve these boundaries and the no-new-folder constraint, the exact verified current Sources are recorded below in this existing work record, rather than overwriting unrelated/historical files. No implementation Source changed this task.
- Next task: read this section and the target's two related Sources first. Do not repeat the purchased Lobby or reward audit unless evidence changes. Remaining: reopen/reload the designated disk file in the stale Studio without saving over it; separately apply to Cloud through the authorized workflow; then check all three equipments and normal completion/cancel/error retries in the published Roblox application. Those operations were not performed here.

### Verified Source: `StarterGui.StrengthGui.LeftMenuClient`

```lua
-- Start only the purchased Feedback module from this existing active client.
task.spawn(function()
 local playerScripts=game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts")
 local feedback=playerScripts:WaitForChild("Services"):WaitForChild("FeedbackClient")
 local ok,err=pcall(function() require(feedback).start() end)
 if not ok then warn("[FeedbackClient] Start failed: "..tostring(err)) end
end)

-- Phase 7.2.3.1: shared menu presentation only.
-- Skip and Rebirth are bound by their existing client scripts.
local TweenService=game:GetService("TweenService")
local gui=script.Parent
local menu=gui:WaitForChild("LeftMenu")
local layout=require(game.ReplicatedStorage.Modules:WaitForChild("HUDLayout")).Mount(gui).Refresh
for _,name in ipairs({"SkipButton","InventoryButton","RebirthButton","ShopButton","MergeButton"}) do
 local button=menu:WaitForChild(name)
 local tween
 local function highlight(on)
  if tween then tween:Cancel() end
  tween=TweenService:Create(button,TweenInfo.new(0.12),{
   BackgroundColor3=on and Color3.fromRGB(53,65,89) or Color3.fromRGB(29,35,49),
  })
  tween:Play()
 end
 button.MouseEnter:Connect(function() highlight(button.Active) end)
 button.MouseLeave:Connect(function() highlight(false) end)
 button.SelectionGained:Connect(function() highlight(button.Active) end)
 button.SelectionLost:Connect(function() highlight(false) end)
end
-- Inventory interaction is handled by InventoryPanelClient.


gui.Parent.ChildAdded:Connect(function(child) if child.Name=="World1DoubleWinGui" then task.defer(layout) end end)
task.defer(layout)
```

### Verified Source: `StarterPlayer.StarterPlayerScripts.Services.FeedbackClient`

```lua
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local SocialService = game:GetService("SocialService")
local Player = Players.LocalPlayer

local FeedbackClient = {}
local started = false
local prompting = false

function FeedbackClient.start()
 if started then return end

 -- One client-wide connection covers the three purchased mailboxes.
 ProximityPromptService.PromptTriggered:Connect(function(prompt, playerWhoTriggered)
  if playerWhoTriggered ~= Player or prompting then return end
  local part = prompt.Parent
  local model = part and part.Parent
  local mailboxes = workspace:FindFirstChild("Mailboxes")
  if not mailboxes or not model or model.Parent ~= mailboxes
   or model.Name ~= "Feedback" or part:GetAttribute("Feedback") ~= true then return end

  -- The yielding call owns the lock until it returns, including cancellation.
  prompting = true
  local ok, err = pcall(function()
   SocialService:PromptFeedbackSubmissionAsync()
  end)
  prompting = false
  if not ok then
   warn("[FeedbackClient] Feedback prompt failed: " .. tostring(err))
  end
 end)

 started = true
end

return FeedbackClient
```

## 2026-10-06 - Y02 CurrentCloud active file lock

- Limited check: C:\Users\kouji\MergeToForge_CurrentCloud.rbxl.lock (77 bytes) names PID 10708, RobloxStudioBeta, host DESKTOP-59IA67A; current hostname matches. PID 10708 exists as RobloxStudioBeta.exe with the exact target rbxl command-line argument. PID 29332 also exists with -ide and the same target. Both reported an empty MainWindowTitle; this does not prove absence of unsaved work.
- Result: active owner, not a stale orphan lock. Lock was not deleted and neither process was terminated because unsaved work is unconfirmed. Target was not reopened, since unlock was not achieved; normal editable opening remains unverified. No rbxl/Source/Map change, Save/Publish, Play, backup or new file.
- Remaining blocker: owning Studio PID 10708 must release its active lock through a safe exit after its unsaved-work state is established. This task did not repeat reopen attempts or inspect unrelated processes.

## 2026-10-06 - Y02 Feedback placed in current World1 Lobby

- Read the preceding Feedback records first; no reward/API or lock re-audit. Actual missing integration was physical placement: purchased mailboxes remained at original map X=-58..63, while Workspace.GeneratedMap.TrainingArea.Floor is centered at (274.5,0,10.5), size (237,8,149). This supersedes the earlier connection-only check: original equipment was outside the current Lobby.
- Moved ONE existing purchased Workspace.Mailboxes.Feedback (original referent 21341, originally the prompt at (5.271080,9.217956,1.506299)) into the current TrainingArea's physical space. Kept its Mailboxes parent so the existing FeedbackClient identity filter continues matching. No clone, reparent, rename, new asset or custom UI. Two other originals stay untouched.
- Final model pivot: (304,7.213201522827148,30), yaw 45 degrees; original orientation rotated +90 degrees toward Spawn. Spawn is (287.861,3.898,13). All 12 existing Part CFrames and this model's WorldPivotData changed together; relative geometry, attributes, appearance and text are retained. Bottom Y=4 equals TrainingArea.Floor top Y=4. Prompt parent: (303.850952,9.217926,29.943182). Placement is diagonally beside Spawn, outside the carpet/Training transit path.
- Edit checks in Studio 230b9991-b034-4f18-85be-383cd983a827, named MergeToForge_CurrentCloud.rbxl: screenshot visually confirms purchased mailbox and Feedback! sign in the current Lobby with Treadmills behind it; floor raycast hits TrainingArea.Floor at Y=4; equipment interior bounds have no other collidable overlaps. Approach space is clear in Edit. No actual character approach or Prompt interaction was performed. Studio remains Edit.
- Source changes: NONE needed. Existing StarterGui.StrengthGui.LeftMenuClient starts only StarterPlayer.StarterPlayerScripts.Services.FeedbackClient before HUD waits. Actual Workspace.Mailboxes.Feedback.Part.ProximityPrompt is enabled, Default style, range 20, ActionText Give Feedback!, and its actual parent Part has Feedback=true; its model is still directly under Mailboxes. Therefore the existing PromptTriggered handler accepts the moved equipment and calls PromptFeedbackSubmissionAsync(). Existing start guard/single connection and yielding pcall lock release remain unchanged. Exact Sources are in the preceding verified-Source section. No rewards/Remote/claim flag added.
- Purchased ServerScriptService.Main and StarterPlayer.StarterPlayerScripts.Main remain disabled; StarterGui.ScreenGui remains disabled. No other system or DataStore edit.
- CurrentCloud directly written without Studio Save: before SHA-256 9489e05420e6c071c8bea860d19c85d80f44688ffce52406466e9304e2392b60; after 41d18bcc27ea6da50b3f6231c3b38f5f4cec354564b62d8a24a796e904f42063. Fresh disk reDecode passed: 87,068 instances; UniqueId duplicates 0; hierarchy/properties decoded by the lossless parser and all Sources unchanged; only Part.CFrame and Model.WorldPivotData chunks differ. Both relevant Sources compiled successfully with existing luau-compile --null. No new work folder/other rbxl/backup.
- Cloud was NOT saved/published. Standard Feedback dialog, live player reachability and completion/cancel/error retries remain unverified; confirm those after authorized Cloud reflection in the published Roblox application. No local Play or actual submission. Next work starts from this placement record and related Sources, not another reward/API/lock audit.

Placement reproduction (existing purchased model only; for documentation, not a startup script):

```lua
-- Select the original third Feedback equipment identified above, not by first-name lookup.
-- Same retained geometry, with original pivot yaw -45 degrees rotated +90 degrees.
mailbox:PivotTo(CFrame.new(304, 7.213201522827148, 30) * CFrame.Angles(0, math.rad(45), 0))
```

## 2026-10-06 - Y02 Codex verification Studio lock released

- Result: LOCK RELEASED. Read existing Feedback/lock records first, then checked fresh lock owner PID 10736 and current target-file processes. PID 10736 (created 13:53:36) was the Codex-launched placement-verification Studio; its latest undo record was Assistant 5 and mailbox placement matched the already-written target file. PID 29020 (created 13:46:55) was the other Codex launch; MCP confirmed no Place was open, so it held no unsaved Place work. Old recorded PIDs were not reused.
- Tried CloseMainWindow for each identified Codex process; both returned false. Force-terminated only these confirmed Codex processes. A later target-file PID 32096 had already exited and was not terminated; no unknown-user-work Studio was closed. After verifying no target-file Studio process remained and lock owner 10736 no longer existed, deleted only C:\Users\kouji\MergeToForge_CurrentCloud.rbxl.lock.
- rbxl unchanged: before/after SHA-256 41d18bcc27ea6da50b3f6231c3b38f5f4cec354564b62d8a24a796e904f42063. No reopening Studio, Save/Publish, Play, Source edit, backup or other rbxl. Only this record is committed; unrelated local file retained.

## 2026-10-06 - Y02 purchased Stage1-area Trophy read-only investigation

- Read prior DEV_STATUS first; no previous record identified this purchased Trophy. Decoded only the designated CurrentCloud and followed this equipment's related purchase modules. No Studio opened, no Studio changes, and no Play/purchase/Save/Publish/backup/export. rbxl SHA-256 remains 41d18bcc27ea6da50b3f6231c3b38f5f4cec354564b62d8a24a796e904f42063.
- Identity by hierarchy AND position: the only decoded Model named Trophy is Workspace.Trophy, referent 21180. ReplicatedStorage.Assets.Icons.Trophy is a Decal, not this equipment. Main geometry Workspace.Trophy.PartMain is (-28.6839,7.3077,111.6828); interaction part Workspace.Trophy.Buy is (-28.6847,10.9482,111.6849). Purchased original Stage01 Environment.Floor is centered (-12.2,0,106.3), confirming this equipment is beside that original Stage1 geometry. Current GeneratedMap Stage01 walkable floor is (287.8,0,106.3), with walls at Z=97,107,117,127: the Trophy is NOT relocated into that current corridor. No inference of a legacy Smash reward connection.
- Display: Workspace.Trophy.BillboardGui.Text = x2 Wins; .Price = ONLY [Robux glyph U+E002]24!; both Visible=true and BillboardGui Enabled=true. A Part.SurfaceGui.TextLabel reads 1. Empty AttributesSerialize on model/parts/prompt; no Trophy-local Script or Remote. All equipment BaseParts have CanTouch=false and CanCollide=false. No equipment touch-collection handler found.
- Interaction: Workspace.Trophy.Buy.ProximityPrompt, Enabled=true, ActionText=x2 Wins, ObjectText=Buy, HoldDuration=0.25, MaxActivationDistance approximately18.693, RequiresLineOfSight=true. CheapClient validates prompt.Parent against the configured Trophy.Buy, then calls buy(wins). It is a Robux Game Pass multiplier purchase entrance, NOT a free Win gift, direct Win currency grant, Stage-clear trophy pickup, or decoration-only implementation. Purchased Main currently being disabled makes it a visible but disconnected purchase entrance in this file.
- Related Client: StarterPlayer.StarterPlayerScripts.Services.CheapClient and .PurchaseClient. Server: ServerScriptService.Services.CheapServer; .PurchaseServer only performs general Game Pass spending accounting. Config: ReplicatedStorage.Modules.Config (Cheap.Trophy and Cheap.Tiles.wins), .ProductIDs, .Pass, .Data. Bootstrap: respective disabled Main scripts call ReplicatedStorage.Modules.Loader.load(Services). No other explicit CheapClient/CheapServer bootstrap reference found. Source presence is not runtime evidence.
- Exact offer: wins tier field wins multiplier2 GamePassId1965960556; next unowned tier wins3 multiplier3 GamePassId1975934298. Config selects the first unowned tier; after both owned no tier is sellable and client disables the Prompt. Ownership fields passes.wins and passes.wins3 exist in purchased Data defaults. No repeat reward/claim cooldown/daily receipt logic belongs to this equipment.
- PurchaseClient.promptGamePass calls MarketplaceService:PromptGamePassPurchase(Player,passId). CheapServer checks UserOwnsGamePassAsync on join and writes passes[field]=true; successful PromptGamePassPurchaseFinished also writes the corresponding pass flag. There is NO fixed Win grant on Trophy interaction or purchase. Downstream purchased WinServer.reward multiplies ordinary Win rewards by Pass.payout(playerData,wins), which picks highest owned tier (otherwise1). This does not establish integration with the active legacy Smash reward system.
- Remote: Trophy purchase path uses Roblox MarketplaceService methods/events directly, no Trophy-specific custom Remote. The downstream purchased WinServer reward path separately sends QuickNet.WonWins; that is not a Trophy pickup/request Remote.
- Price24 is the saved sign text, NOT a verified live Roblox price. CheapServer.priceTrophy would query GetProductInfo for the FIRST wins tier and update the Billboard price if started; Client also fetches tier prices for purchased GUI. No external price query or actual purchase was performed.
- Current file state: ServerScriptService.Main.Disabled=true; StarterPlayer.StarterPlayerScripts.Main.Disabled=true; StarterGui.ScreenGui.Enabled=false. Thus purchased CheapClient/CheapServer/WinServer purchase and multiplier processing are not bootstrapped by Main. Prompt.Enabled=true alone does not mean the handler is running. No WinsGift/time reward or legacy TrophyRewardService linkage inferred.
- Unconfirmed: published Cloud version, runtime purchase screen, current Marketplace prices/availability, successful pass grant/persistence and effective live Win multiplier. Existing purchased Data defaults contain pass flags, but full save lifecycle was not re-audited. Static file investigation only.

Short Source evidence:

`ReplicatedStorage.Modules.Config`

```lua
	Trophy = {
		tile = "wins",

		model = "Trophy",
		press = "Buy",
		board = "BillboardGui",

		adornee = "PartMain",
	},
```

`ReplicatedStorage.Modules.ProductIDs`

```lua
		wins = 1965960556,
		wins3 = 1975934298,
```

`StarterPlayer.StarterPlayerScripts.Services.CheapClient`

```lua
end

local function buy(name: string)
	local tier = Pass.selling(playerData, name)
	if not tier then return end

	local id = ProductIDs.Gamepasses.Cheap[tier.field]
	if type(id) ~= "number" then
		warn(`[CheapClient] no gamepass id for "{tier.field}"`)
		return
	end

	PurchaseClient.promptGamePass(id)
end

```

`StarterPlayer.StarterPlayerScripts.Services.CheapClient`

```lua
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		if player ~= Player then return end
		if not isTrophy(prompt) then return end

		buy(Config.Cheap.Trophy.tile)
	end)
```

`StarterPlayer.StarterPlayerScripts.Services.PurchaseClient`

```lua
function PurchaseClient.promptGamePass(passId: number)
	Raised[passId] = os.clock() + WINDOW_SECONDS

	MarketplaceService:PromptGamePassPurchase(Player, passId)
end
```

`ServerScriptService.Services.CheapServer`

```lua

	passes[field](true)
end

local function unlock(player: Player)
	Data.Service:waitForData(player)

	local playerData = Data[player]
	if not playerData then return end

	for _, tier in ipairs(rungs()) do
		if Pass.owned(playerData, tier.field) then continue end

		local id = idFor(tier.field)
		if not id then
			warn(`[CheapServer] no gamepass id for "{tier.field}"`)
			continue
		end

		local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
		if not ok then
			warn(`[CheapServer] could not read pass {id} for {player.Name}: {owns}`)
			continue
		end
		if not owns then continue end

		grant(playerData, tier.field)
	end
```

`ServerScriptService.Services.WinServer`

```lua
local function reward(player: Player, playerData: any, amount: number): number
	local paid = amount * Boost.payout(playerData, WIN_BOOST) * Pass.payout(playerData, WIN_PASS) * Bonus.timePayout(player) * Weather.winsPayout()

	playerData.wins(function(wins: number): number
		return wins + paid
	end)

	return paid
end

```

## 2026-10-06 - Y02 purchased Trophy connected to legacy Win Pass system

- Read the Trophy investigation and related current/old-reference Sources first. Old Smash reference C:\Users\kouji\Smash_and_Crush_PreMerge_20261003.rbxl was read-only. CurrentCloud retains its legacy TrophyRewardService.GetWinReward call sites; no replacement purchased Data/WinServer or Main is started.
- Formal Game Pass IDs: 2x Win1970515086; 3x Win2005353724. Used only in WorldPassConfig/Game Pass Marketplace requests, never as Image/Texture IDs. The old purchased1965960556/1975934298 IDs are absent from all changed Sources; their inactive purchased ProductIDs module remains unused.
- Existing Workspace.Trophy (referent21180) moved to physical World1 Lobby/BattleArea entrance RIGHT when walking from Spawn toward +Z: pivot (269,9.063096046447754,72). Parent/path retained. World-space rotation +45deg toward approaching Lobby, with original authored model pivot basis preserved. Ground bottom4 equals TrainingArea.Floor top4. All29 existing BasePart CFrames and model pivot updated; no clone/new instance/reparent. Original appearance/Prompt/sign assets retained; saved fixed24 Robux Price label replaced by ... for Marketplace-only runtime pricing.
- GamePassService owns both official entitlements, exposes highest owned multiplier and next offer, and mirrors verified state to the client. None owned -> x2; only2x owned -> x3; any3x owned -> Owned/no offer; both owned ->3x, never6x. Existing AreEffectsEnabled debug/creator gates remain unchanged. Existing stage Win base amounts and reward/return/storage code are unchanged. No fixed Win or time reward grant.
- One server prompt lock shared by all Win purchase entrances is latched before yielding ownership checks. Requests reverify ownership before choosing the next pass. Successful Marketplace completion retries UserOwnsGamePassAsync up to5 times; unresolved ownership then continues with a deduplicated15-second retry worker. No completion signal/client Attribute alone grants a benefit. Cancel/error releases the prompt lock;1-second request throttle and120-second missing-close recovery prevent rapid duplicated prompting/permanent lock.
- Purchased CheapClient is now an isolated Trophy bridge, started idempotently by existing enabled StrengthGui.LeftMenuClient beside Feedback. It imports only legacy WorldPassConfig/MarketplacePrice and uses existing ReplicatedStorage.Remotes.World1DoubleWinPrompt (TrophyPrompt action). No purchased Loader/Main/Data/PurchaseClient/CheapServer/WinServer startup. The server controller validates the actual Trophy.Buy Prompt and alive-player distance before prompting.
- Personal client sign/Prompt uses x2 Wins/x3 Wins/Owned, verified owner Attributes, and MarketplacePrice.Get(GamePass,nil fallback). Price lookup failure says Price unavailable; no24 fallback. PromptShown refreshes presentation without reconnecting Triggered; actual purchase uses one global Triggered connection with guards. Existing HUD DoubleWinClient, EssentialStudShopClient DoubleWin card, and optional legacy pedestal entry all route through the same authoritative IDs/tier selection.
- WorldPassConfig preserves original World1 Place101572058398926 and adds established CurrentCloud Place126576845524886 as World1, previously missing and otherwise rejecting the transferred legacy pass routes. Explicit World2 config still has no Win pass offer; unknown Place IDs remain unavailable. No broader world mapping/Map system change.
- Changed Source Full Paths and permanent src mirrors:
  - `ReplicatedStorage.Config.WorldPassConfig` -> `src/ReplicatedStorage/Config/WorldPassConfig.luau`
  - `ServerScriptService.Services.GamePassService` -> `src/ServerScriptService/Services/GamePassService.luau`
  - `ServerScriptService.Systems.Controllers.GamePassController` -> `src/ServerScriptService/Systems/Controllers/GamePassController.server.luau`
  - `StarterPlayer.StarterPlayerScripts.Services.CheapClient` -> `src/StarterPlayer/StarterPlayerScripts/Services/CheapClient.luau`
  - `StarterGui.StrengthGui.LeftMenuClient` -> `src/StarterGui/StrengthGui/LeftMenuClient.client.luau`
  - `StarterGui.World1DoubleWinGui.DoubleWinClient` -> `src/StarterGui/World1DoubleWinGui/DoubleWinClient.client.luau`
  - `StarterGui.StrengthGui.EssentialStudShopClient` -> `src/StarterGui/StrengthGui/EssentialStudShopClient.client.luau`
- Corresponding current Source files missing from tracked src were added in their normal permanent src hierarchy; historical audit Sources untouched. No temporary work folder or extra place export.
- Static checks: final file reDecoded87068 instances; UniqueId duplicates0; all7 disk Sources exactly match Git mirrors and compile with existing luau-compile --null. Candidate preflight checked unchanged hierarchy/decoded properties/all unrelated Sources and raw chunks except intended Source, Trophy CFrame/pivot and one price Text property. Purchased Main Server/Client remain Disabled=true; purchased ScreenGui.Enabled=false; active legacy controller/LeftMenu remain enabled.
- Edit confirmation in CODEx-opened Studio23c03d3f-844a-432e-ba3a-f58cbe39a586: screenshot shows original trophy beside entrance on right, with clear grass approach off red path. Floor raycast hits TrainingArea.Floor at4; computed all-part bottom3.99999976 and no overlaps with any other collidable part except the support floor. Prompt enabled, actual parent Trophy.Buy, saved price...; no Player movement/purchase test. Pure WorldPassConfig functions evaluated in Edit for00/10/01/11: multipliers1/2/3/3, next IDs1970515086/2005353724/none/none. Symbolic World2 -> no offer/multiplier1. This is not runtime reward confirmation.
- File directly written; before SHA-25641d18bcc27ea6da50b3f6231c3b38f5f4cec354564b62d8a24a796e904f42063; final314c0e3067dedec3ca357c9ac1f7c32e58b921c76198be52e8a23723e0383652. No Studio Save/Publish, local Play, actual purchase, backup or other rbxl. Cloud is not reflected by this task; published-app purchase/cancel/error flow, real price/ownership propagation and actual Win rewards remain unverified.
- Confirmation Studio PID20920(created15:50:03) was identified separately from preexisting user PID14856(created15:21:18). Only read-only Edit inspection/geometry math and a pure Config evaluation were performed in20920; no unsaved game edits. CloseMainWindow returned false, so terminated only this Codex-owned verification process. It no longer retains the target. User Studio14856 still owns the existing .lock and was NOT closed; .lock NOT deleted while this user owner remains. Full file-lock release is therefore blocked by the user Studio, not retained by Codex. No new Studio opened after cleanup.
- Next task reads this record and the7 corresponding src files first; live confirmation requires authorized Cloud reflection and Roblox application testing. Existing user Studio was opened before the direct write and is not proof of the final disk version.

## 2026-10-06 - Y02 CurrentCloud lock absent after user confirmation

- Result: LOCK RELEASED. Fresh Win32 process check found0 RobloxStudioBeta processes opening the exact CurrentCloud target; MCP Studio list was empty. The adjacent MergeToForge_CurrentCloud.rbxl.lock was already absent and its absence was verified again. No past PID was reused; no termination or lock deletion was necessary.
- Did not reopen Studio or change rbxl/Source/Map. File SHA-256 remains314c0e3067dedec3ca357c9ac1f7c32e58b921c76198be52e8a23723e0383652, matching the implemented version. No Save/Publish, Play or backup. Only this record committed; unrelated local changes preserved.

## 2026-10-07 CurrentCloud Studio debug command restoration

- Target: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`. Git repository is the existing nested `C:\Users\kouji\Smash_and_Crush\Smash_and_Crush_updated_20260915`; fast-forwarded to fetched `origin/main=62ea5ed` while retaining all preexisting local changes.
- Confirmed cause: disk and the already-open CurrentCloud Edit model lacked `ServerScriptService.Systems.Debug`, its Controller/Service, and `StarterPlayer.StarterPlayerScripts.Debug.StudioDebugClient`. The six commands therefore had no registration entry point; this was missing instances, not Disabled=true. StudioDebugConfig and PlayerDataService existed and matched the current Git Sources after line-ending normalization.
- Restored Full Paths:
  - `ServerScriptService.Systems.Debug` (Folder)
  - `ServerScriptService.Systems.Debug.StudioDebugController` (Script, Disabled=false, RunContext=Legacy) from unchanged `src/ServerScriptService/Systems/Debug/StudioDebugController.server.luau`.
  - `ServerScriptService.Systems.Debug.StudioDebugService` (ModuleScript) from unchanged `src/ServerScriptService/Systems/Debug/StudioDebugService.luau`.
  - `StarterPlayer.StarterPlayerScripts.Debug` (Folder)
  - `StarterPlayer.StarterPlayerScripts.Debug.StudioDebugClient` (LocalScript, Disabled=false, RunContext=Legacy), restored from the existing 2026-09-15 audit Source and mirrored without logic changes to `src/StarterPlayer/StarterPlayerScripts/Debug/StudioDebugClient.client.luau`. Historical audit file retained.
- Registration route: Controller's IsStudio guard -> require existing Debug service -> six TextChatCommand instances under TextChatService -> Triggered resolves a current Player by TextSource.UserId -> Debug.Execute. Response uses Player attributes StudioDebugMessage/StudioDebugMessageSequence -> client AttributeChanged -> RBXSystem (fallback RBXGeneral) DisplaySystemMessage. No custom debug Remote is required or added. Direct required service/config instances already exist.
- Preserved existing Studio-only guards, current-Player checks, argument validation, busy/save gates, Studio DataStore naming, and all persistence/reset logic. No new authorization bypass, fake/default-on-failure player data, or public-game command activation. StudioDebugConfig and PlayerDataService were not edited. /resetdata [UserId] still has its existing Production reset route; no reset or other data-changing command was executed.
- DataNotLoaded is a service response for a missing/unloaded PlayerData session, distinct from missing command registration. CurrentCloud has PlaceId=0; local DataStore acquisition/loading remains subject to that environment. No local Play or real load attempt was made, so this task does not claim to have reproduced or fixed a local DataStore failure. The confirmed missing-entry-point fault existed independently.
- Verification: direct binary write followed by fresh disk reDecode; 87,149 -> 87,154 instances, exactly the five additions above. Every original instance, parent, property value and Source retained; unrelated raw chunks retained; UniqueId duplicates=0. All three restored disk Sources are byte-identical to src. Controller, Service, Client, existing Config and PlayerDataService all compiled using loadstring in Edit without invoking the compiled game scripts.
- An isolated registration check using substituted game/Instance/require dependencies registered all six aliases and attached Triggered callbacks; non-Studio registered zero and never required Debug. The client connected exactly once to StudioDebugMessageSequence. No Triggered callback, command handler, DataStore function or real game service was executed by this check. This is registration/control-flow verification, not an actual chat test.
- Existing Output was inspected: no StudioDebug startup error was present, consistent with the scripts being absent; existing asset authorization and Studio MaterialManager plugin messages are unrelated. There was no new Play startup, so real require/startup behavior and client chat display after restoration remain unverified.
- No already-corrected Cloud original was available: the preexisting connected Place101572058398926 was already in Play and also lacked the debug scripts/commands. It was read only; no /balance, Play restart or Stop was issued there. No local Play, command execution, Studio Save/Publish, backup, other rbxl or temporary work folder was used.
- Before SHA-256: `1c9e64a1e5d90f0a4dde79e38462e4ec1351d849a7c897925acc11b82d440d48`. After: `368080461f4a60f25fed0d3fd53de55b98d661ea326a64ab7e7bfa3e19eef499`. This task starts from the actual current disk hash, not the different hash recorded on 2026-10-06.
- No verification Studio was opened; the two preexisting user Studios were not closed or edited. The existing CurrentCloud lock belongs to live user PID8500 and was retained. The already-open CurrentCloud model predates this disk write and must be reloaded by the user without saving the stale model over the repaired file. Cloud reflection and actual /balance acceptance/response remain unverified.

## 2026-10-08 - Y02 Studio debug command registration restored

- Cause verified in actual Y02 target: SHA-256314c0e3067dedec3ca357c9ac1f7c32e58b921c76198be52e8a23723e0383652 had StudioDebugConfig but lacked the Debug Controller/Service/folders and response Client. GitHub's2026-10-07 restoration record concerns a different before/after file hash; it was not present in this actual disk version. Existing local records and specified Sources were read, then fetched origin/main cfd2221 and its latest restoration/client record were reconciled. No broad audit.
- Restored Full Paths from existing current Source: ServerScriptService.Systems.Debug (Folder), .StudioDebugController (Script Disabled=false), .StudioDebugService (ModuleScript), StarterPlayer.StarterPlayerScripts.Debug (Folder), .StudioDebugClient (LocalScript Disabled=false). Current GitHub attribute Client reused without logic changes; no new debug Remote or unrelated StudioStart client. Five added instances, fresh unique identities.
- Only changed implementation Source: ServerScriptService.Systems.Debug.StudioDebugController -> src/ServerScriptService/Systems/Debug/StudioDebugController.server.luau. Leading IsStudio guard remains; register six TextChatCommand aliases before attempting the DataStore-dependent Service require. Require/Execute occur in a protected command callback, returning errors through existing StudioDebugMessage/Sequence attributes. The latest StudioDebugClient connects those attributes to RBXSystem/fallback RBXGeneral. Registration marker prevents duplicate startup.
- StudioDebugService from src/ServerScriptService/Systems/Debug/StudioDebugService.luau and Client from src/StarterPlayer/StarterPlayerScripts/Debug/StudioDebugClient.client.luau restored unchanged. StudioDebugConfig and PlayerDataService are unchanged. Existing Studio-only/current-player checks, arguments, busy/save gates and Production reset methods preserved. No fake data or DataStore bypass; no public-game activation. All required modules are present.
- Distinguish: missing scripts meant NO alias registration. PlaceId0 may separately fail PlayerDataService's existing GetDataStore during require, now reported as DebugUnavailable(PlaceId=0):original error after registration. A successfully loaded Service with an unloaded session still returns original DataNotLoaded. These runtime data errors were not induced or bypassed.
- Checks: disk reDecode87073 instances (original87068 plus5), UniqueId duplicates0; all original instance properties/Sources/raw chunks preserved except parent/header expansion. Final restored Sources match current src. Related Source syntax passes. Chat is TextChatService with input/window/default channels enabled. Registration/control flow confirmed statically; no handler or DataStore call was executed.
- Verification Studio loaded the restored Debug Controller/Service and enabled response Client in Edit (before final switch to the latest attribute Client). Final attribute Client/folder replacement was reDecoded and syntax checked, not a second Studio run. No local Play. No matching already-reflected Cloud original available, so real startup and /balance acceptance/response remain UNVERIFIED; no reset or any data mutation command executed.
- CurrentCloud directly written, final hashb3b42419de871baabb31f86716fef98772037b794d9fd73913681b7677bd7b89. No Save/Publish, actual reset, backup, other rbxl or work folder. Cloud not reflected.
- Confirmation launcher11212 spawned updated Studio29664 (parent11212, created2026-10-08 09:04:15). Only read-only Edit inspection was performed. Codex session terminated; final fresh process query0 target Studios, .lock absent. No user Studio closed or reopened.
- Next verification: only on an already-reflected matching Cloud original, use /balance for read-only acceptance/response then Stop. Never execute /resetdata [UserId] or other mutation commands as tests. Read this record and current related src first.

## 2026-10-08 - Stud Egg and Pet compatibility investigation (read only)

- Fetched latest origin/main=19a9e1f before investigation; read existing DEV_STATUS and related Sources. Existing Studio b4ca14da-01ba-4f12-9edd-2b900ed307fb was Edit, Place126576845524886, game.Name=Place2. Read confirmed Workspace.Stud Egg & Pet (two immediate children,31441 descendants). Studio disconnected during subsequent inspection; no new Studio launched or user session closed. Exact local-file association and full unsaved differences cannot be confirmed from PlaceId alone.
- Actual CurrentCloud disk contains Workspace.Stud Egg & Pet:167260 total instances, SHA25637d92539ba8775babbb38a57c5ea29daef6dbc177ffd4e81d59a4cbe7f3d7dc6. It is already saved, not absent from the file. Disk root has one child Mod and31440 descendants, versus live two children/31441: small live/disk difference remains unidentified. No write/reload/overwrite performed. Prior debug-task file hash is obsolete for this user-modified file. Asset Store page104179732320310 could not be read; observed hierarchy is the evidence, not assumed Store contents.
- Full Paths: Workspace.Stud Egg & Pet.Mod.Model.EggModels and Workspace.Stud Egg & Pet.Mod.Model.Pets. Mod contains two sibling models both named Model; select by their EggModels/Pets children, not first same-name match. EggModels has192 direct Models,191 unique names Egg_001..Egg_191, with two Egg_001 entries. Pets has180 distinct Models Pet_001..Pet_180. No Script/LocalScript/ModuleScript anywhere inside this saved asset. Includes meshes, rigs/bones, constraints/effects and scene/rig Value objects, not a game-system Config.1746 instances have serialized attributes (not fully decoded); no gameplay price/probability mapping is established by this investigation.
- PrimaryPart decoded from binary reference properties:191/192 Egg Models and179/180 Pet Models have one; Egg_119 and Pet_130 do not. Existing renderer/follower uses GetPivot/GetBoundingBox/ScaleTo/PivotTo with optional PrimaryPart reset; absence is not an unconditional failure. Actual orientation, skinning, animation behavior and performance remain untested.
- Saved asset has12 Animation instances: ten LightWinAnimation/DarkWinAnimation on Egg_152..Egg_156, Animation on Egg_179, and Pet_180.Animation. Also7 KeyframeSequence and182 Animator instances. Existing HatchClient/PetFollowClient do not load/play these authored Animations; animation authorization/playback unverified.

| Component | Assessment | Source/object evidence and minimal missing connection |
| --- | --- | --- |
| Models | Reusable after mapping | Egg/Pet geometry can be reused; numbered asset names do not match current Config names. Resolve duplicate Egg_001 explicitly. Pet.model resolves ReplicatedStorage.Assets.Pets.<name> or one group beneath it, not Workspace asset wrappers. Pet icons require same-name Decals at ReplicatedStorage.Assets.Icons.Pets. |
| Egg opening UI / random selection | Connection changes required | StarterPlayer.StarterPlayerScripts.Services.EggClient and ServerScriptService.Services.EggServer scan only direct BasePart children of Workspace.Eggs, names in ReplicatedStorage.Modules.Config.Eggs.Eggs. Asset Eggs are Models in another folder. Reuse existing Basic/Rare/Legendary/Mythic BasePart interaction anchors and original OpenEgg BillboardGui template; attach selected purchased visuals and configure an explicit name mapping. Prize.Info/InfoShadow is the existing price sign. |
| Hatch presentation | Reusable after mapping | StarterPlayer.StarterPlayerScripts.Services.HatchClient.templateFor reads Workspace.Eggs.<configuredName>, fallback ReplicatedStorage.Assets.RGBEgg. mount accepts Model or BasePart; reveal uses ReplicatedStorage.Modules.Pet.model. Existing Viewport shake/click/crack/reveal/rarity/sound pipeline can stay. To show a separate multi-part Stud Egg in Hatch, a small visual-template lookup change is needed while retaining BasePart interaction anchors. |
| Pet Inventory / equip / following | Reusable after data bridge | PetClient uses StarterGui.ScreenGui.Menus.Inventory, Assets.Templates.PetInventory/PetHover and Icons.Pets. PetServer validates ownership, toggles equip and publishes Player Pet/Pet2 attributes; PetFollowClient clones Pet.model and moves it with PivotTo. Preserve these UI/render operations and attribute contract. |
| Persistence / duplicate handling / abilities | Connection changes required | Purchased Data and Speed are separate from legacy PlayerData/Strength. Map Wins debit, owned-pet flags, two equip slots and replication to the legacy authoritative loaded session. No automatic Speed-to-Strength conversion or balance decision. |
| Actual operation | Unverified | No Play, purchase or live opening/equip/save test. Purchased server/client Main both Disabled=true, ScreenGui.Enabled=false on disk and live Main reads; no direct legacy Egg/Pet startup call found in relevant Sources. Existence is not running-state proof. |

- Exact Source contracts: ReplicatedStorage.Modules.Egg: `Egg.FolderName = "Eggs"`, `return Config.Eggs.Eggs[name] ~= nil`; EggClient.start: `if not child:IsA("BasePart") then continue end`; EggServer.start: `QuickNet.OpenEgg.OnServerEvent:ConnectAsync(open)`; HatchClient.start consumes QuickNet.Hatch; PetClient emits QuickNet.EquipPet. ReplicatedStorage.Packages.QuickNet declares those messages; OpenEgg/EquipPet rate limit10 per5 seconds. No messages fired during investigation.
- Existing Config (not changed/proposed new balance): Basic100, Rare10000, Legendary100000, Mythic1000000 Wins; Open1/Open3/Open8 counts1/3/8. Each current egg has six named pets with weights3/7/10/15/25/40. ReplicatedStorage.Modules.Egg.pick performs server weighted random selection. Stud numbered models have no established mapping to these entries; do not invent odds/prices/abilities.
- Purchased persistence Source ReplicatedStorage.Modules.Data: `STORE_INDEX = ... "OfficialGameProduction"`, template `inventory.pets = {current="",second="", [petName]=false,...}`. DataServiceTyped provides callable Values and Changed listeners; not interchangeable with legacy plain profile tables. EggServer.grant requires a preexisting key then `container[name](true)`. No count/unique pet instance is stored. Duplicate hatch uses `bonus = math.max(settings.duplicateSpeed, math.floor(held * settings.duplicatePercent))`, Config.Hatch100 and0.01, credits playerData.speed and displays the bonus; duplicates cannot equip as separate copies. EggServer also calls purchased QuestServer.report(...,"eggs",...), an extra Data dependency to isolate, not a reason to start all quests.
- ReplicatedStorage.Modules.Pet: `Pet.Slots = {"current", "second"}`, `Pet.Attributes = {"Pet", "Pet2"}`, ownership boolean, maximum two distinct names. Same-name click unequips; full slots shift oldest out. Pet.payout sums equipped worth (fallback1); percent pets depend on best owned multiplier. ReplicatedStorage.Modules.Stack consumes Pet.payout in purchased SpeedServer's per-step gain, not legacy Strength. Purchased PetServer also checks ProductIDs.Gamepasses.Pets; do not activate foreign purchase IDs or its bulk entitlement startup merely to enable equip.
- Legacy ServerScriptService.Services.PlayerDataService default/normalization presently contains Win/Strength/OwnedSpeeds/OwnedItems etc but no Pet ownership/equip fields. Necessary implementation would add validated Pet fields to existing default/normalize/save/load and client replication, use existing SetWin/loaded-session authority rather than a second DataStore, and bridge read/Changed interfaces consumed by PetClient/EggClient. ServerScriptService.Services.StrengthManager.AddStrength/AddRewardStrength are authoritative legacy gain paths; Pet ability placement and duplicate conversion require user decisions before any integration. Do not multiply existing Strength balance using purchased Speed's large pet values by assumption.
- Minimal implementation proposal (not implemented): select a small explicitly approved Egg/Pet mapping first; reuse existing interaction anchors/UI and purchased visuals with proper pivots/icons; bridge only EggClient/HatchClient/PetClient/PetFollowClient and Egg/Pet server handlers to legacy data, with narrowly enabled idempotent startup and original QuickNet result/attribute contracts. Isolate Data/Quest/pass dependencies. Add server serialization/debit/grant checks: current EggServer has no explicit distance or in-flight lock, beyond QuickNet rate limiting, so cannot claim concurrent-safe opening. Present only the existing Inventory/opening UI needed, without starting purchased Main or unrelated menus/services. Decide new names, prices, odds, Strength ability and duplicate reward policy before implementation. No ore merge work.
- Only this investigation record and CHANGELOG changed. No Source/Map/rbxl writes, Studio launch/close, Play, Save/Publish, purchase, backup or additional export. Unrelated untracked report retained. Current saved asset and possible live-only differences must not be overwritten by any older rbxl in subsequent work.

## 2026-10-08 - Stud Egg and Pet Phase 1 catalog

- Read fetched latest origin/main=8c1bae1 and prior investigation first; no repeat reward/API audit. Existing Studio060567ee-fed8-4730-bfe4-18a1d0cace96 Edit, Place126576845524886, read only. Batched inventory confirms192 Egg Models/191 names (two Egg_001),180 distinct Pet Models. Saved disk name multisets/counts match; rbxl hash37d92539ba8775babbb38a57c5ea29daef6dbc177ffd4e81d59a4cbe7f3d7dc6 unchanged. No full live/disk equality or save claim.
- Formal artifacts: [guide](Stud_Egg_Pet_Catalog.md), [Egg192 rows](Stud_Egg_Catalog.csv), [Pet180 rows](Stud_Pet_Catalog.csv). Model-name order numbering, Full Paths, live Model Pivot world coordinates, immediate sibling order, PrimaryPart. Same-named parent Model distinguished by EggModels/Pets child. Duplicate Egg_001 positions (-113.987137,111.719208,1786.684082) and (120.413147,111.719193,2267.039551), sibling80/186. Sibling order is session-dependent; UniqueId unreadable here, no identity fabricated.
- Validated row counts, unique catalog numbers, disk name correspondence and blank design fields. Egg output-Pet; Pet family/rarity/source-Egg/ability/merge-target remain blank. USER DECISION: Pets are also merge targets, not implemented. Phase2+ model selection, relationships, rarity, prices, odds, abilities, merge rules/consumption/results, duplicate/save format, equip/Strength integration remain undecided.
- Individual images NOT acquired; image catalog incomplete. Available screen_capture is current view or temporary Camera reposition. No non-mutating batch per-model capture established. Requested fallback completed: every correspondence row first, with image feasibility reported, avoiding372 individual camera operations. No generated/self-drawn substitute. Guide points to actual-model positions for user review.
- Only3 permanent catalog files and DEV_STATUS/CHANGELOG changed. No Source/Studio edits, Camera/placement changes, Studio launch/close, Play/Save/Publish/purchase, rbxl write, backup, Map clone or work folder. User session and unrelated untracked report preserved.

## 2026-10-08 - Stud Egg and Pet Rig/Animation limited inspection

- Read latest origin/main=2dac166, DEV_STATUS, catalog guide and all180 Pet CSV rows first. Read-only existing Studio060567ee-fed8-4730-bfe4-18a1d0cace96 Edit, target Workspace.Stud Egg & Pet. No new Studio or close. Scope only Pet rig structure,12 Animation objects,7 local KeyframeSequences and PetFollowClient full Source.
- Added11 structural count/check columns to existing180-row Pet CSV; original14 columns and every design blank unchanged.115 pets contain3226 Bones;179 contain2281 Motor6D. All180 have Bone or Motor structure, not merely HumanoidRootPart. Bone parent checks0 invalid.2280 motors have both endpoints inside same Pet; Pet_137.Model.Root.MotorJoint_002 Part1=nil. Motor graphs1 component except Pet_130 two sub-rigs, Pet_079 no motors (has bones). This is static connectivity, not deformation/skin-weight or playback proof.
- Humanoid1 on Pet_180; AnimationController180 total (Pet_130 two, Pet_180 none). Animator176 with valid Humanoid/AnimationController parent; missing on Pet_058/089/103/114. No fix performed. Outer HRP motor-reachability alone is not a valid test for internal-model rigs.
- Guide now lists all12 Animation names, exact Full Paths/IDs, storage models and co-located rig counts. Only Pet_180 has a Pet-stored Animation; other11 are in Egg_152..156/179 and have no evidenced corresponding Pet. External clip content/intended purpose, skeleton compatibility, real playback and ownership/experience permission UNVERIFIED. Did not infer purpose from LightWin/DarkWin/Animation labels, fetch/load clip data or play any Animation.
- Seven local KeyframeSequences belong to Pet_046(two),Pet_048(two),Pet_082(three), total432 Keyframes. Loop=true,Priority=Action. All unique Pose names match local Bone/BasePart names (78/27/27 respective sets); names alone do not prove full animation hierarchy correspondence.7 AnimationRigData present; no proven mapping between saved sequences and the12 external IDs.
- PetFollowClient full live Source confirms anchored model clone, ScaleTo and PivotTo for position/yaw/bob/hop/pitch; no LoadAnimation/track playback or direct Bone/Motor Transform updates. Needed future work: approved clip-to-rig map, Animator scope/lifecycle and idle/move transitions, missing Animator/unconnected motor handling, anchoring/pose compatibility review and separate authorized playback/permission validation. No implementation or spec decision.
- Only existing Pet CSV, guide, DEV_STATUS/CHANGELOG modified; no Source/game/model/Camera changes, Play, Animation playback, Save/Publish, rbxl write or backup. Unrelated local report preserved. User Studio retained.

## 2026-10-08 - Pet image capture attempted, incomplete

- Read fetched origin/main=ea392bc, latest DEV_STATUS/guide/Pet CSV. Existing user Studio060567ee-fed8-4730-bfe4-18a1d0cace96 confirmed Edit only. Read180 actual Pet bounds/pivots without changing models. Preserve existing Pet-001..180/name correspondence; no Egg capture or gameplay work.
- Recorded initial Camera CFrame/Focus/FOV/type before movement; temporary camera framing authorized. Several trial captures of Pet_001/Pet_002 using bounds/pivot facing, explicit CFrame/Focus, render waits and tool position/look parameters failed reliable individual framing: returned screenshots contained nearby models/map/HUD rather than an independently verified requested Pet. Do not label ambiguous images. Did not proceed with180 unreliable captures. Native screen check could not foreground Studio (SetForegroundWindow false); browser-only diagnostic image was immediately deleted and is not committed.
- VERIFIED IMAGES0; NOT ACQUIRED180. Failure reason recorded on each existing CSV row. Identification memo stays blank because no per-model image verified. [Nine-page20-entry catalog](Stud_Pet_Photo_Catalog.html) retains all model IDs/names/positions and explicit image-not-acquired status, no placeholder bitmap/generated/substitute images. This is an INCOMPLETE image catalog, not completion of180 photos. Guide links it. Existing25 CSV columns and all Rig/design blanks remain byte-value identical;2 status columns appended.180 unique numbers/names and9 pages checked.
- Final Camera restore readback matches starting CFrame/Focus within floating-point tolerance, FOV70, CameraType.Fixed. Original CFrame position (131.95870971679688,130.80755615234375,2234.428955078125), Focus position (132.29376220703125,129.31005859375,2235.711669921875). Complete12-component CFrame/Focus recorded below. No user Studio close/new launch, Play/Save/Publish, model/Source/gameplay changes, rbxl writes, backup or work folder. Only catalog/status documentation; unrelated untracked report retained.

- Initial Camera full record: `{"type":"Enum.CameraType.Fixed","focus":[132.29376220703125,129.31005859375,2235.711669921875,1,0,0,0,1,0,0,0,1],"viewport":[1280,720],"cframe":[131.95870971679688,130.80755615234375,2234.428955078125,-0.9675377607345581,0.18922583758831024,-0.1675238013267517,7.450580596923828e-9,0.6628662347793579,0.7487378716468811,0.25272640585899353,0.7244321703910828,-0.641348123550415],"fov":70}`.

## 2026-10-08 - Pet real photo catalog, 175 usable / 5 unavailable

- Read fetched origin/main=3127cd0 and existing DEV_STATUS/guide/180-row CSV before continuing the previous failed capture. Existing user Studio 060567ee-fed8-4730-bfe4-18a1d0cace96, Edit PlaceId126576845524886, PID12220 / HWND15533898. Verified the actual Studio window on the secondary monitor (-1927,3)-(-9,1042), not the primary-monitor browser. No new Studio or user Studio close.
- First verified Pet_001 using its exact Instance reference under the Model containing Pets, visible-part bounds excluding invisible FX/root offsets, and a negative control: hiding this target removed its body from the capture. Only then expanded to180. Temporarily recorded/restored BasePart Transparency and effects/GUI Enabled plus Camera/Selection. Hiding Decal/Texture during diagnostic trials made some bodies disappear; original texture values were restored and excluded from final isolation. Studio capture also omitted some rendered bodies / timed out, so native PrintWindow of the verified existing Studio window was used for end entries and42 suspect entries. No generated/substitute image, model movement/clone/rename, or description/spec invention.
- Reviewed all9 sheets of20 entries after replacement. Accepted175 real photographs;5 rejected, not empty-image placeholders: Pet_041/119 have visible MeshParts (Transparency0, LocalTransparencyModifier0) but no body rendered in existing Edit; Pet_095 lacks identifiable full body; Pet_159 renders a few Parts while UnionOperation body is missing despite visibility properties. Cause of missing geometry rendering and asset permission UNVERIFIED. Pet_130 has two separated sub-rigs about4 studs apart with visible parts approximately0.001-0.012 stud; whole-model framing does not resolve these. Did not scale/move or invent replacements. Rejected images and temporary diagnostic sheets removed.
- docs/Stud_Pet_Photo_Catalog.html now contains175 actual image links and5 specific unavailability reasons in existing20x9 grouping, correct Pet-001..180 / Pet_001..180 labels. docs/Stud_Pet_Catalog.csv image references connected; failure reason cleared only for accepted photos. Original27 columns retained; all25 other columns compare equal to HEAD, including Rig counts, coordinates, identifiers, blank design fields and blank identification memo.175 unique image hashes / file references,180 unique IDs/names,9 pages checked. Guide updated with current status. Pet-as-merge-target decision and undecided Phase2 specifications remain unchanged.
- Final restore22486 properties, failed0; subsequent readback confirms Camera CFrame/Focus/FOV70/type Fixed and original one-instance Selection exactly restored, stored temporary property list empty. Error/interruption paths also restore. User Studio remains open; our native capture input process ended. Initial Camera position (160.11082458496094,165.5592041015625,2175.434814453125), Focus position (160.0364227294922,164.09410095214844,2176.794189453125). No Play/animation playback, Save/Publish, Source/gameplay edit, rbxl write, backup, work folder or Egg capture. CurrentCloud SHA256 remains37d92539ba8775babbb38a57c5ea29daef6dbc177ffd4e81d59a4cbe7f3d7dc6.
- Only175 final JPEGs, existing HTML/CSV/guide and DEV_STATUS/CHANGELOG are included. Unrelated reports/Visual_Templates_Secret_VIP_Green_20260917.md preserved, excluded from commit. This is175 usable images, not a claim that all180 are photographed successfully.

## 2026-10-08 - Purchased Basic Egg / original Pets restored (static completion)

- Read latest fetched origin/main `28dd604`, DEV_STATUS and existing Egg/Pet investigations first. No repeat Stud model/rig/image audit. Actual target `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl` was newer than the investigation hash: before SHA256 `07510b35b1709a56ca5002ffd0fc086aeddbf5c382e639388ac09f2c8419612c`, 167264 instances. No Studio process/connected session at preflight; no unsaved Studio model was overwritten. V2/PreMerge not modified.
- Cause/scope: purchased Egg/Pet assets and modules existed, but both purchased Main loaders and ScreenGui were disabled and no isolated Egg/Pet bootstrap reached legacy PlayerData. Basic and its original stand remained at the purchased map coordinates. Restored only this path; Main scripts remain Disabled. Purchased Data/OfficialGameProduction, Quest, other Shop, other Eggs and packs are not started.
- Placement Full Paths:
  - `Workspace.Eggs.Basic`: original MeshPart moved from (42.624416,12.111495,-7.353715) to **(314,11.736531,56)**.
  - `Workspace.Map.Spawn.PathToEggs.Stands.Standd`: original Basic stand (same-named siblings exist; selected by its seven Parts beneath the original Basic, decoded model referent6148 / Parts6149..6155). Those seven Parts and that model's WorldPivotData translated by **(271.375584,-0.374963,63.353715)**; size, rotation, appearance, identity and hierarchy retained. No cloned or substitute geometry. Stand bottom aligns with actual `Workspace.GeneratedMap.TrainingArea.Floor` top Y=4.
  - Static approach envelope X305..323 / Z46..66 / Y4.1..19 has zero saved BasePart obstructions (Terrain's generic bounding envelope excluded). Spawn, Training and other equipment were not moved. Visual/navigation clearance still needs Cloud review.
- Changed Source Full Paths (each synchronized to its corresponding existing-hierarchy `src` file; purchased modules previously absent from Git are now tracked from actual current Source):
  - `ReplicatedStorage.Modules.Pet`
  - `ServerScriptService.Services.PlayerDataService`
  - `ServerScriptService.Services.EggServer`
  - `ServerScriptService.Services.PetServer`
  - `ServerScriptService.Systems.Controllers.PlayerDataController` -> `src/ServerScriptService/Systems/Controllers/PlayerDataController.server.luau`
  - `StarterPlayer.StarterPlayerScripts.Services.EggClient`
  - `StarterPlayer.StarterPlayerScripts.Services.HatchClient`
  - `StarterPlayer.StarterPlayerScripts.Services.PetClient`
  - `StarterPlayer.StarterPlayerScripts.Services.MenuClient`
  - `StarterGui.StrengthGui.LeftMenuClient` -> `src/StarterGui/StrengthGui/LeftMenuClient.client.luau`
- Startup: existing enabled PlayerDataController starts only EggServer/PetServer. Existing enabled LeftMenuClient starts the isolated PetClient bootstrap, original Menu/Button/Notify/Hatch/Egg presentation and unchanged PetFollowClient. ScreenGui stays disabled in the saved file and is enabled only after unrelated panels are hidden. Original Inventory HUD artwork is reused as the Pets entry at right-middle (72x72); only Inventory/Pets tab is bound. Its Exit closes through original MenuClient. Unconnected Items/Trails/EquipBest controls and other menus are hidden.
- Original `ReplicatedStorage.Modules.Config` and `ReplicatedStorage.Modules.Egg` retained: **100 Win per roll; Dog40%, Grey Cat25%, Pink Bunny15%, Sheep10%, Bear7%, Camel3%**. Existing OpenEgg six tiles display matching icon/actual percent using the same ranked table used by server sampling. Original Open1/Open3/Open8 map to1/3/8, costing100/300/800 Win. Existing Basic path has no pass entitlement requirement for these counts. No purchased Marketplace handler/product ID is invoked. Original models/icons, hover/rarity art, proximity billboard, click/shake/crack/reveal/sounds and two-slot bob/hop/trail following are reused.
- API integration: runtime-only `ReplicatedStorage.Remotes.PetRequest` RemoteFunction (`GetState`, `OpenEgg`, `Equip`) provides a durable receipt/state response. This narrow acknowledged bridge replaces purchased QuickNet fire-and-forget/Data connections on the active Basic path; original QuickNet definitions remain unchanged/dormant. Server validates current Player, loaded/owned legacy session, request ID/revision, Basic/count, living character, original15-stud reach, balance and available original Pet models. Server chooses outcomes/individual GUIDs, charges Win and validates equipment. Invalid/stale/busy requests cannot roll or write.
- Persistence: **existing StoreConfig-selected PlayerData_v1 / Player_<UserId> key**, with existing Studio/production naming and session ownership fencing. `Pets={Version=1,Revision,Owned={[copyId]=petName},Equipped={copyId1,copyId2},LastRequestId,LastResults}`. Old profiles with no Pets get an empty field only after successful normal load; malformed Pets fail normalization. No fake data fallback and no purchased DataStore migration/load. Each duplicate remains an independent copy; same species can occupy both slots using distinct IDs. Equip toggles that individual copy, fills empty slots, and when full replaces the older slot using original two-slot behavior.
- Win debit + Pet grant/equip + receipt are committed in one owned UpdateAsync before success. Existing PendingItemMutation/Saving gates serialize with other inventory/capacity saves. An ambiguous write retains the same ID/outcomes/reservation; server retry and client retry confirm that receipt without charging/rerolling again. Revision rejects stale requests after later operations. Ordinary autosave preserves durable Pets; load/reset/confirmed mutations publish Pet/Pet2 visual names and PetInventoryRevision. Failed DataStore access stays a failure; local PlaceId0 is not bypassed.
- No Speed compensation, Speed multiplier or Strength multiplier is connected. Hatch forces duplicate=false/bonus0 and no longer renders the duplicate-Speed reward; shared payout returns1. Hover description says `Cosmetic pet` and hides its ability icon. Original rarity is visual only. Future merge must operate on copy IDs and reconcile Equipped/receipt when consuming copies; no merge or selected Stud Pet substitution is implemented.
- Static verification after direct write: fresh disk reDecode167264 instances,10 changed Sources identical to src, all10 reDecoded Sources compile with official Luau0.741 without invocation; six OpenEgg percent labels, models/icons, original sounds, GUI/control paths and bootstrap targets exist. Both purchased Main Disabled=true; original active entry scripts remain enabled. UniqueId duplicates0. Only six binary property chunks changed (three Source classes, MeshPart/Part CFrame, Model WorldPivotData); all other raw chunks unchanged, all parents/reference values unchanged. Only Basic+seven stand Parts moved; no Stud asset modifications.
- Isolated offline Luau: `python tests/BasicEggOffline.py <luau executable>` passes **79 assertions** using the actual Pet module and extracted production transaction/request functions with a memory store and stubbed services. Covers duplicate-copy/equip/reload normalization, stale/repeated requests, 3/8 grants, before-write failure, committed/lost response, callback retry, concurrent requests/rewards, pending spend guard, paid credits, unloaded/ownership-lost/override/reset/invalid data, incorrect count/odds and server distance/Egg/balance rejection. This is not real DataStore, full Save/Load lifecycle, engine UI or network verification.
- After SHA256 **`87cfbf3a2f3373818cc19c3f9f20611e5df396dd18721e7d5698d763292f3c9b`**, 5418145 bytes. No local Play, real purchases, data commands, Studio Save/Publish, backup, other rbxl, staging/work folder or verification Studio. Final file lock absent; no user Studio closed. Cloud reflection/Save/Publish are manual user steps.
- **Remaining / UNVERIFIED:** Cloud startup/errors, real proximity/input and1/3/8 Hatch, desktop/mobile HUD fit, asset permissions/rendering/VFX, real equip/unequip/two-pet following, durable save/rejoin and network failure behavior. Source/static completion does not claim live restoration has been played successfully. After manual Cloud reflection, verify these with authorized normal gameplay. Selected Stud replacements and merge remain later work. Existing unrelated Git modifications are retained and excluded from this commit.

## 2026-10-09 - Basic Egg purchased carpet / original layout restored

- Fetched/read latest origin/main f38316d, DEV_STATUS and Basic restoration record first; fast-forwarded clean tracked branch, preserving unrelated untracked report. CurrentCloud had newer user-saved changes: before SHA2562739e99f15cf5b2aa29b2dbde275bac28e7a7869ec8869a5c8ebcc8563a9633a,167267 instances. No existing Studio process or connected session and target lock absent at preflight. Edited this current disk, not the prior87cfbf3 version. Existing hatch/save/equip/follow and all Source left unchanged.
- Limited source geometry inspection: Workspace.Eggs.Basic and Workspace.Map.Spawn.PathToEggs. Three same-named Standd models were distinguished by actual seven-part positions, not old referents or first name match. Basic's actual stand is current model116738 / Parts116739..116745 at the prior314/56 placement; other Standd and RareStand remain unchanged. Those seven purchased sculpted parts are the Basic pedestal and decoration; no new geometry.
- Placement evidence: current World1 Lobby right connector Workspace.GeneratedMap.TrainingArea.EntranceCarpets.Path Upper82483/Lower82484 already exactly matches purchased source Path Upper116762/Lower116761 translated +300X. TrainingArea.Floor spans X156..393,Z-64..85, topY4. Thus original source layout +300X fits naturally without keeping temporary(314,11.737,56) position, resizing, rotating, cloning or translating the whole Map. Existing right connector is reused; moving another identical source Path on top would cause overlap, so both original source Path pairs were retained.
- Moved Workspace.Eggs.Basic to(342.624416,12.111495,-7.353715), original source(42.624416,12.111495,-7.353715)+300X. Basic Standd seven-part layout and model pivot reverted its earlier temporary delta, then applied the same +300X; lower main slab center(342.612576,4.713943,-7.375532), model pivot(342.824429,5.180017,-7.333169). WorldPivotData updated only for this stand and carpet model.
- Moved purchased red-carpet assembly Workspace.Map.Spawn.PathToEggs.EggsStand Upper to(342.574448,4.200015,13.693081), Lower to(342.824455,4.098510,13.693077). This is the ORIGINAL SHARED egg display carpet, not a Basic-only separate rug. Retained full original Upper55.5x0.41x22.5 / Lower58.5x0.231x26 shape, material/color/Texture/appearance, hierarchy and identity; no other Egg or stand moved/activated. Carpet inside current floor, right Lobby connector ends atX331.329884; upper carpet beginsX331.324448, original seam overlap0.005421 and top-height difference0.004905 stud (not identical coplanar surfaces). Lower trim inset into floor about0.017 stud as original. Basic stand's lowest edgeY4.374979 overlaps carpet top4.405015 by original0.030036 stud, without floating gap. Source-relative stand/Egg heights retained.
- Static approach X332..338,Z-15..17,Y4.5..20 contains zero foreign BaseParts; gives a clear route from connector along the red rug to within original15-stud Basic reach. Carpet and approach are clear of treadmill/Training platform (upper north edgeZ-26.2), Spawn and unchanged manual World2Gate at Pivot(237.600006,4,76.099998). No obstruction relocated. Runtime flicker/navigation and rendered visuals are not established by this numeric inspection.
- Direct write only CurrentCloud; fresh reDecode167267 instances, UniqueId duplicates0. Ten BasePart CFrame positions and two model pivots changed; only MeshPart.CFrame, Part.CFrame, Model.WorldPivotData binary chunks changed. All other chunks, Source, sizes/rotations, appearance, attributes, IDs, PRNT/reference hierarchy exact unchanged. Fresh position/size/rotation readback checked. After SHA25654db9e433479781b3a1e39ef116b01e016694dc84e1d2730c905238618a0ec77. [Exact placement correspondence](Basic_Egg_Placement.json) stores before/after paths, current referents, coordinates and pivots; no rbxl committed.
- Attempted authorized Edit visual check by opening CurrentCloud once in our verification Studio PID15896; command line matched target. Studio stayed at login and never connected/opened the Place, so NO placement screenshot or visual pass claimed. No Save/Publish, Play, game/Source edits or authentication action performed. Normal CloseMainWindow had no usable main window; ended only this confirmed verification process. No Studio process/target.lock remains; no user Studio closed. No backup, alternate rbxl or work folder.
- Cloud reflection not performed. Remaining checks after user reflection: full equipment appearance, carpet/trim seam and flicker, approach/proximity in Roblox; existing Basic hatch/save/equip/follow behavior not reimplemented or run in this placement-only task. Only placement manifest and DEV_STATUS/CHANGELOG committed; unrelated report preserved.

## 2026-10-09 - Inventory / Stage Skip use actual purchased Shop visuals

- Fetched latest origin/main71b1fcf and read DEV_STATUS/CHANGELOG first. Used current CurrentCloud bytes (before SHA25654db9e433479781b3a1e39ef116b01e016694dc84e1d2730c905238618a0ec77), not an older Cloud/Git file. Existing user Studio f9026290-6a16-4a0d-83ea-51b172ef2f2d is Cloud Place101572058398926 in Edit, so its original DataModel/UI/Camera/selection were not edited, closed or replaced. No verification Studio launched; target file lock absent.
- Changed UI Full Paths: StarterGui.StrengthGui.InventoryPanel and StarterGui.StageSkipGui.Panel. Actual current-game donors: StarterGui.StrengthGui.ShopPanel.Top (header, double text, black strokes, gradient, StudPattern), .Top.Close (complete X/outline/gradient/Stud artwork), and .MainScrollingFrame.Holder.Card02_StarterPack (actual card outlines/gradient/StudPattern). Reused these actual instances/property values; no generated/substitute artwork. Added142 visual-only clones inside the two requested trees, each with a fresh UniqueId/HistoryId. Existing control names, hierarchy, data labels and click targets remain intact. Added PurchasedShopHeader / CloseButton.PurchasedShopClose plus purchased decoration layers; all142 original-to-copy paths are in [UI provenance](Inventory_Skip_Shop_UI.json).
- Backgrounds now bright purple/pink (body229/163/255 to255/190/221, cards246/190/255 to255/151/207, header239/153/255 to255/139/193). Selected tabs/cards use pale yellow-to-pink; equipped item statuses green, equip action blue. Original purchased bold FontFace, black text edging and actual Shop thick/double borders are reused. Inventory Dumbbells/Items/Merge/Aura/Speed tabs, equipped slots, card/list surfaces and all nine Stage2..10 rows are covered. Existing yellow Win / green Robux visuals and their owned/equipped rendering through HUDLayout remain untouched/protected.
- Changed Source Full Paths (synced from actual disk to canonical src, not historical audit exports):
  - ReplicatedStorage.Modules.InventoryPresentation -> src/ReplicatedStorage/Modules/InventoryPresentation.luau
  - StarterGui.StrengthGui.InventoryTabsClient -> src/StarterGui/StrengthGui/InventoryTabsClient.client.luau
  - StarterGui.StrengthGui.InventoryPanelClient -> src/StarterGui/StrengthGui/InventoryPanelClient.client.luau
  - StarterGui.StrengthGui.ItemInventoryTabClient -> src/StarterGui/StrengthGui/ItemInventoryTabClient.client.luau
  - StarterGui.StrengthUI.MergePanel_New.MergePanelClient_New -> src/StarterGui/StrengthUI/MergePanel_New/MergePanelClient_New.client.luau (its existing generated MergeFlow lives under InventoryPanel.Content.Merge)
  - StarterPlayer.StarterPlayerScripts.UI.StageSkipClient -> src/StarterPlayer/StarterPlayerScripts/UI/StageSkipClient.client.luau
- Runtime: idempotent purchased skin binding at existing Inventory/Skip entry paths; immediate original-text synchronization and deferred Text-change updates into the purchased header; original title/close paths retained. Existing AutoLocalize/RootLocalizationTable and all old text values remain. DescendantAdded handles generated cards/sockets/list content; old background assignments are corrected using the selected/equipped state. Tab, Dumbbell and Item selection setters retain purchased borders while updating the new gradient. Merge paint reapplies the purchased surface after its own state rendering. This is presentation only; original remote calls, ownership/equip logic, tabs, stage scope and all server/config Sources remain unchanged.
- Verification: all6 changed Sources compile with official Luau without invocation. Static comparison against actual starting file: request expressions unchanged; original purchase-button subtrees untouched;285 existing visual property changes restricted to the requested trees; every other original UI property/Source outside the six named scripts, all Map/Config/Remotes/server contents and existing parent/reference paths preserved. Final fresh reDecode167409 instances, UniqueId duplicates0; serialized GUI property rows roundtrip exactly, clone parentage/classes checked. After SHA256dd9c2c562ac7cc167f640b9b21db58aa2e2a5a90643a77a933405d57b5283d16.
- Additional engine Edit check used ONLY detached temporary copies of the actual user-Studio UI and the new rendering functions, with no placement in the DataModel and no client/server gameplay script execution: duplicate binding adds no extra objects, runtime card generation gains purchased artwork, selected gradient survives old dark-background assignment, equipped state has distinct color, translated-title changes propagate after deferred signals, all18 existing Skip purchase-button contents/gradients/images remain identical. Final counts Inventory502 descendants / Skip450 match the intended added142 visuals. Temporary clones and event bindings destroyed. Direct GuiObject counts under all existing grid/list layouts stay unchanged: those containers use gradient/borders without an extra background image that would be laid out as a card. This is not Play or an on-screen visual/layout pass.
- UNVERIFIED: rendered layout/overlap at actual device sizes, all-language text fit, reopen/equip/purchase behavior in published gameplay. No local Play, real purchase, Studio Save/Publish, backup, alternate rbxl or work folder. Cloud reflection not performed. User Studio retained; no target lock introduced. Only six canonical Sources, UI provenance and DEV_STATUS/CHANGELOG included; unrelated local report preserved.

## 2026-10-09 - Repair CurrentCloud UI instance serialization after 6b3c38e

- Read fetched origin/main6b3c38e and the preceding UI record. The previous custom reDecode/UniqueId checks were insufficient: they accepted sparse out-of-range referents and did not decode SharedString indexes. The user-reported Studio failure was caused by our UI serialization, not by gameplay or a file lock.
- Cause1: after removing two extra grid background images from144 added visuals, header/INST/PRNT counts were correctly reduced to167409, but referents167409 and167410 remained outside0..167408; holes167312 and167340 remained. Reassigned167409->167312 for StarterGui.StageSkipGui.Panel.CloseButton.PurchasedShopClose.UIStrokeInner and167410->167340 for its UIGradient, updating both INST arrays and PRNT children/parents. All167409 referents now form a unique dense in-range set; class count158 matches header. All75674 reference-property values resolve or are null; none required changes.
- Cause2 exposed by actual Studio load after the first fix: SharedString dictionary index invalid1024/351 in Frame.Tags chunk962. The earlier generic codec incorrectly treated type28 SharedString indexes as contiguous four-byte rows when extending classes; these indexes require byte-plane interleaving. Recovered all original Tags rows from their unchanged original byte prefix; assigned each of the142 clones its actual purchased donor's Tags; correctly interleaved Frame/ImageLabel/TextButton/TextLabel Tags arrays. All SharedString indexes now fall within the351-entry dictionary. All other property chunks (including Sources, UI artwork/colors, gameplay/config/Map) are byte-identical to the reported broken file. Only2 INST,1 PRNT and4 Tags PROP chunks changed overall; no rollback or instance/UI removal.
- Same CurrentCloud directly repaired: before SHA256dd9c2c562ac7cc167f640b9b21db58aa2e2a5a90643a77a933405d57b5283d16; final SHA2560df0b835ae4c8479194646d072921a874ba19fb19939c95abf19e41514d05698. ReDecode, dense/range/duplicate referents, header/class/instance totals, full PRNT membership, reference properties, SharedString bounds, original node/property preservation and UniqueId duplicates0 passed. Source text unchanged. Exact remap/chunks and checks are in Inventory_Skip_Shop_UI.json. Future instance-clone verification must include these checks and an actual Studio file load, not only custom reDecode/UniqueId.
- ACTUAL STUDIO LOAD PASS: launched dedicated PID9292 for the exact file, retried once in the same process after repairing Tags. Studio6d7e80e6-8d9c-4f9f-b1ec-03f2346fca02 opened MergeToForge_CurrentCloud.rbxl, PlaceId0, Edit. Read-only engine inspection confirmed Inventory502/Skip450 descendants, both panel gradient top229/163/255, InventoryPresentation present and repaired close-button stroke/gradient present. This was the disk file itself, not detached UI copies or the existing Cloud session. No Play or gameplay invocation; rendered UI/device/language behavior remains unverified.
- Cleanup: normal-close attempts were made only for our PID9292; a later guarded termination attempt found it already absent and executed no force stop. Final PID9292 absent and target.lock absent; disk SHA256 still matches the repaired bytes after Studio. No user-Studio termination issued. No Save/Publish, backup, alternate rbxl or work folder. Only this repair's provenance and DEV_STATUS/CHANGELOG committed; unrelated report preserved. Cloud reflection remains not performed.

## 2026-10-09 - Basic Egg authored Hatch restoration: original-source comparison blocked

- Fetched/read origin/main32ece6f, latest DEV_STATUS/CHANGELOG and the serialization repair evidence first. CurrentCloud SHA2560df0b835ae4c8479194646d072921a874ba19fb19939c95abf19e41514d05698 is exactly the repaired file. Read-only reDecode167409, dense/header/INST/PRNT/reference/SharedString checks and UniqueId duplicates0 passed again. No rbxl write, Source edit or rollback in this task.
- Compared the actual Sources in CurrentCloud and READ-ONLY MergeToForge_CurrentCloudV2.rbxl (SHA2564a16324225a5f306f3d2d231f26e5b0d67d566a5786bd6558126f8c875cba952). StarterPlayer.StarterPlayerScripts.Services.HatchClient, .EggClient and ReplicatedStorage.Modules.Config are byte-identical between both files. HatchClient SHA256293d955cdaa2c1d9dfb4036bef058b9ed05b67edad0e320869a1074e70a94c3f. Both already contain legacy receipt/no-Speed integration comments and code; V2 cannot establish the unmodified purchased Hatch presentation baseline. PreMerge contains no Hatch/RGBEgg Source. The canonical Hatch Source first entered Git in f38316d with the integrated implementation; no earlier version exists at that canonical path. No separate original Hatch asset was identified in the existing relevant exports or Roblox model/place filenames under Documents/Downloads/OneDrive/Roblox_SavedArchives; unrelated models were not decoded.
- Current connection only: PetClient.request calls HatchClient.play(playerData.LastResults,"Basic") after the acknowledged matching durable receipt. HatchClient.templateFor prefers Workspace.Eggs.Basic and uses ReplicatedStorage.Assets.RGBEgg only as fallback; build/layout handle the result count including1/3/8. mount clones the supplied actual Egg/Pet into ViewportFrames and strips BillboardGui; existing knock/shudder/pop/reveal, UI rings/flecks/glow/flash, result labels and SoundService.UI.Click/Success/Winner are present. Config.Hatch specifies4 clicks,0.55-second charge,0.3-second pop,0.45-second reveal and0.12-second stagger. These are observed current/V2 values, NOT independently verified vendor-original settings. No shell-part splitting was found; the variable crackSound plays the existing Success sound and is not evidence of authored shell geometry.
- Assets: Workspace.Eggs.Basic is MeshPart MeshId1527559 plus Prize BillboardGui children; ReplicatedStorage.Assets.RGBEgg is Part plus SpecialMesh MeshId110218693. Neither subtree contains a ParticleEmitter. Their same hierarchy exists in V2. This does not establish that the purchased original never had other particle/effect logic; only the available current/V2 structures were confirmed.
- BLOCKER / NOT IMPLEMENTED: a separate unmodified purchased Hatch Source or its source asset/file location is needed to establish the requested original presentation. Asked user for that location; did not invent replacement effects, infer timings, switch Basic to RGBEgg without evidence or reactivate purchased Data/Speed/Main. Win/prices/odds/numeric labels, durable per-copy persistence/equipment/following, all geometry and repaired Inventory/Skip remain unchanged. No new Studio launched or user Studio closed; no Play, effect playback, Save/Publish, backup, alternate rbxl or work folder. The actual file-open PASS belongs to the preceding repair task and is not claimed as a new test. Cloud reflection/effect runtime remain UNVERIFIED. Only this investigation record is committed; implementation resumes after the original source is identified.

## 2026-10-09 - Placed Basic Egg idle glow: purchased yellow effect located, mapping pending

- Read fetched origin/main1a82721 and latest DEV_STATUS/CHANGELOG. This request is the permanent world Egg glow, distinct from Hatch. The prior Hatch-source blocker does not establish whether idle glow exists. Current user-saved file is newer: SHA256f272a081c63b1313ab86601565a8e82f2322b3c5363cc8f78528edd2519bd0a3,180246 instances,381 SharedStrings. ReDecode, dense/header referents, reference-property/SharedString bounds and UniqueId duplicates0 passed. No older file was written over it.
- Purchased yellow candidate found: Workspace.Eggs.Rare.Particles (Attachment), .Shine2 and .Sparkles (ParticleEmitter). Same UniqueIds in READ-ONLY V2 establish the same existing purchased objects. Shine2 has original yellow ColorSequence255/243/65, Size10, Rate1, LightEmission1 and texture3693840710; Sparkles has original yellow-green252/255/25, peak Size0.5/envelope0.125, Rate10, LightEmission0.5 and texture7112395588. Both Enabled/LockedToPart=true. Other Egg effects are distinct: Legendary purple, Mythic another yellow palette plus an additional six-emitter Attachment. These are actual purchased effects, not generated alternatives.
- Limited mapping check: Workspace.Eggs.Basic contains the Prize billboard only; its corresponding seven-part stand and PathToEggs have no separate glow objects. Current and V2 share the same Basic subtree and EggClient Source. EggClient registers Basic, sets its CFrame to its saved base plus the original sinusoidal rise, and builds the opening billboard; it neither creates nor clones idle emitters. Traced current LeftMenuClient -> PetClient.bootstrap -> EggClient.start. Purchased Main remains Disabled on Client/Server; no hidden whole-Main startup is needed for a parented ParticleEmitter. Checked relevant particle/tag consumer candidates; no Basic-specific external VFX mapping/generator was identified. No inference from the prior Hatch audit was used as proof of absence.
- PENDING USER IDENTITY CLARIFICATION: asked whether the requested yellow effect is specifically the purchased Rare.Particles assembly and may be used unchanged on Basic. No evidence establishes that it was originally Basic's effect, so do not label a Rare-to-Basic copy as a verified restoration of Basic's original palette/size/motion without that clarification. If confirmed, minimally clone that complete Attachment once at Basic registration, guard duplicate creation/startup, and retain its original properties; parenting plus LockedToPart follows the existing Basic float without moving Egg/stand/carpet or enabling other Eggs/Main. No effect substitute authored.
- No game/Source/file changes in this task; only this evidence recorded. No Studio connected at preflight; no verification Studio launched while the donor mapping remains unresolved. Actual latest-file Studio load and glow display/runtime are NOT verified in this task. No Play, Save/Publish, backup, other rbxl or work folder. Cloud untouched; user Studio not closed. Existing Win/odds/Hatch/persistence/equip/follow and all user additions retained. Implementation is pending the donor identity response, not marked complete.

## 2026-10-09 - Apply purchased Rare yellow idle glow to Basic (user-confirmed specification)

- Latest user explicitly chose Workspace.Eggs.Rare.Particles unchanged for Basic. This supersedes the previous pending mapping question: it is an intentional purchased Rare-to-Basic application, not a claim about Basic's historical original. Fetched/read origin/maina01ff75 and latest record; edited the actual newer user-saved CurrentCloud SHA256f272a081c63b1313ab86601565a8e82f2322b3c5363cc8f78528edd2519bd0a3,180246 instances, preserving all user additions.
- Added exactly3 purchased clones: Workspace.Eggs.Rare.Particles -> Workspace.Eggs.Basic.Particles; .Shine2 -> .Shine2; .Sparkles -> .Sparkles. All saved properties match their actual donor rows except fresh UniqueId/HistoryId; original Name/local CFrame, Color/Texture/Size/Rate, speed/lifetime/rotation, light/transparency/shape and Enabled/LockedToPart are retained. Rare subtree is untouched. No custom VFX or emitter construction from guessed values.
- No Source changes were needed: a persisted Attachment under Basic follows Basic's existing EggClient CFrame bob, with both purchased emitters LockedToPart=true. Exactly one Particles Attachment is saved; the install guard refuses a second copy, and no runtime generator/extra event connection was added. Current LeftMenuClient -> PetClient.bootstrap -> EggClient.start continues unchanged. Purchased Client/Server Main remain Disabled; no Data/Speed activation. Hatch, purchase/price/odds/numeric labels, per-copy save/equip/PetFollow and all Egg/stand/carpet positions are unchanged. Basic remains(342.624420,12.111495,-7.353715).
- Direct same-file write; fresh reDecode180249 instances. Header/class/INST counts and dense referents0..180248, complete PRNT membership, all76129 reference-property values,381-entry SharedString index bounds and UniqueId duplicates0 passed. Original instance rows/parents and all Sources unchanged; every cloned nonidentity property matches its donor. Only Attachment/ParticleEmitter property arrays, their INST arrays, PRNT and instance-count header changed. Existing EggClient syntax compiled without invocation. Exact paths/hashes and verification are in Basic_Egg_Placement.json. Final SHA256e12ea16f73f95817f5e97377839b69c023fd694e5afb01f7ae71f46ab2157026.
- ACTUAL FILE LOAD / EDIT VISUAL PASS: dedicated Studio274b2a43-31a8-4a85-84bc-40188e9e7faf/PID8792 opened MergeToForge_CurrentCloud.rbxl in Edit (RunService not running). Engine inspection confirmed one Attachment/two emitters; each emitter's33 exposed effect properties and Attachment.CFrame exactly match Rare; Attachment.WorldPosition equals Basic.Position. [Actual Edit screenshot](Basic_Egg_Glow_Edit.jpg) visibly shows the yellow surrounding glow and sparkles on the existing Egg/pedestal/carpet. Screenshot includes existing Edit GUI overlays; no UI/gameplay script was run or modified for capture.
- Cleanup: only our PID8792 was targeted, verified by start time2026-10-09 14:37:33 and executable. Hidden window had no normal CloseMainWindow target; guarded force termination ended that read-only verification process, then its residual.lock was removed. Process absent, target.lock absent, final disk hash unchanged after Studio. No user Studio closed, Play, Save/Publish, backup, alternate rbxl or work folder. Cloud reflection not performed. Remaining UNVERIFIED: published-client startup/rendering and live float-following; the Edit visual and native parent/LockedToPart check do not claim gameplay execution. Only placement/VFX provenance, screenshot and DEV_STATUS/CHANGELOG committed; unrelated local report retained.

## 2026-10-09 - Purchased treadmill captions: Strength base gain and Japanese wording

- Fetched/read latest origin/main8eebdf1 and latest DEV_STATUS/CHANGELOG. Used the actual CurrentCloud with purchased Basic glow, before SHA256e12ea16f73f95817f5e97377839b69c023fd694e5afb01f7ae71f46ab2157026. Seven purchased models exist under Workspace.Treadmills; other child Billboard is a heading only. The seven BillboardGui.Multiplier labels retained old x1/x3/x10/x25 Speed text. The current authoritative TrainingConfig.BaseGain1/TrainingInterval0.5 and TreadmillConfig multipliers1/2/3/20 already matched the requested base awards; no reward/access change needed.
- UI Full Paths: Workspace.Treadmills.Normal01.BillboardGui.Multiplier, Workspace.Treadmills.Normal02.BillboardGui.Multiplier, Workspace.Treadmills.Iron01.BillboardGui.Multiplier, Workspace.Treadmills.Iron02.BillboardGui.Multiplier, Workspace.Treadmills.Gold01.BillboardGui.Multiplier, Workspace.Treadmills.Gold02.BillboardGui.Multiplier, Workspace.Treadmills.Diamond01.BillboardGui.Multiplier. Saved Text now +1/+2/+3/+20 Strength / 0.5s respectively. Only Text and AutoLocalize changed; purchased artwork, font, size, stroke, position, rebirth/Premium signs and access numbers unchanged. No extra Speed wording was found in other equipment labels/prompts within the scoped folder. Full before/after and Japanese strings in Treadmill_Strength_Labels.json.
- Changed Source Full Paths: ReplicatedStorage.Config.TreadmillConfig -> src/ReplicatedStorage/Config/TreadmillConfig.luau adds only GetGainDisplayText(modelName,localeId), deriving base amount/interval from the already-authoritative configuration. StarterGui.StrengthGui.LeftMenuClient -> src/StarterGui/StrengthGui/LeftMenuClient.client.luau adds only an isolated purchased-caption binding. Existing startup/functions remain intact. Canonical Git TreadmillConfig previously still contained old Tredmill01..10 assignments; synchronized the seven assignments already present in CurrentCloud, without changing those in-game assignments in this task.
- Runtime/localization: existing enabled LeftMenuClient binds only Multiplier/optional MultiplierShadow under the seven purchased BillboardGui nodes. Explicit Japanese captions for ja LocaleId and English otherwise; only these labels disable auto-translation to prevent stale Speed translations. LocaleId/Text/AutoLocalize changes update via events, late labels bind once, removal/script destruction disconnects; no polling or global string replacement. Internal names/attributes are unchanged. Dormant purchased TreadmillServer/Speed/Data and the intentionally Disabled TreadmillUIClient, TreadmillMultiplierBillboardClient, TreadmillGuideClient are not enabled or invoked. Training awards/access/pass requests, WalkSpeed24, TreadmillRun animation and other Speed systems are untouched; no gameplay module is started for label rendering.
- Direct same-file write and fresh reDecode180249 instances passed; header/INST/PRNT/reference checks,76129 reference values,381-entry SharedString bounds and UniqueId duplicates0 passed. No new instances. Both changed Sources compile with official Luau without invocation. All existing property chunks except seven Text/AutoLocalize values and the two Source replacements are preserved. All gameplay Sources/configuration fields, Map transforms and Basic.Particles/Shine2/Sparkles remain intact. Final SHA256212a615b2f0a60c4d3fac4b3108534235f24fa19f7a5579b1677e8624bcb0626.
- ACTUAL STUDIO LOAD: dedicated PID15952 / Studio75d64d89-0d3d-4486-be23-fc3a1205bdda opened MergeToForge_CurrentCloud.rbxl in Edit. Readback confirmed all seven exact captions, all three old presentation scripts Disabled, both purchased Main Disabled and Basic glow present. Detached actual billboard copies passed English/Japanese switching, old-Speed repaint guard, AutoLocalize guard, dynamic shadow registration, removal/lifetime cleanup and unrelated-Speed preservation. Separate Edit capture inspected the seven original signs with English/Japanese wording; screen HUD overlays were temporarily hidden solely in our verification session and restored with saved English text afterward. No whole client/gameplay script execution, Play or real purchase. A two-line layout preview was rejected as less readable; final label format remains one line with original layout properties.
- Cleanup: verified own PID15952/start15:06:50/executable; hidden window had no normal CloseMainWindow target, so ended only that verification process and removed its residual target.lock. Final process/lock absent; file hash unchanged after Studio. No user Studio closed, Save/Publish, backup, alternate rbxl or work folder. Cloud not reflected; published-client startup, actual gameplay and device-specific billboard readability/overlap remain UNVERIFIED. Only two canonical Sources, caption provenance and DEV_STATUS/CHANGELOG committed; unrelated report preserved.


## 2026-10-09 - Pet equipment limited to one purchased follower

- Read fetched origin/main59c8d04 and latest DEV_STATUS/CHANGELOG first. Edited the actual latest CurrentCloud directly, starting SHA256212a615b2f0a60c4d3fac4b3108534235f24fa19f7a5579b1677e8624bcb0626. User additions, Basic yellow glow and latest treadmill captions retained. No rollback, backup, alternate rbxl or work folder.
- Changed Source Full Paths: ReplicatedStorage.Modules.Pet; StarterPlayer.StarterPlayerScripts.Services.PetClient; StarterPlayer.StarterPlayerScripts.Services.PetFollowClient. All synchronized to matching src paths; PetFollowClient was previously absent from canonical src, so exported the actual current purchased Source with only the slot-cleanup/start-guard changes. Historical audit exports untouched.
- Server/state: MaxEquipped=1, one current slot/one Pet attribute. Existing PetServer ownership/model checks and PlayerDataService transaction/load/save paths already use Pet.NormalizeState/ApplyOperation/Publish; those services require no edits. Selecting another owned copy replaces slot1; selecting the same copy clears it. Receipt/revision/save guards retained, including retry without toggling twice. Normalization accepts legacy slots1/2 in numeric order and retains the first nonempty ID present in Owned; empty/dangling first slots can fall through to slot2, repeated IDs collapse to one. Malformed slot types/extra slots still reject. Owned copies, revision and receipts remain intact. Version1 read compatibility retained; existing normal save/transaction writes the normalized one-slot state without a separate migration write.
- Purchased UI Full Path: StarterGui.ScreenGui.Menus.Inventory.Main.2PetsEquipInfo (existing internal name retained). Saved Text is Equipped (0/1), AutoLocalize=false; PetClient refresh/rebind renders Equipped (0/1) or Equipped (1/1) and checks only the selected copy. Reused the original label/card visuals; this Pet menu has no separate second physical slot. Hidden ItemsTab equipment rows are unrelated and unchanged. The retired two-pet auto-translation key is no longer used.
- Follow: Publish explicitly clears legacy Pet2 on load/reset/confirmed updates. Purchased PetFollowClient watches only Pet, removes retired slot entries through its existing Janitor, and starts once to avoid duplicate follow folders/connections. Purchased model selection, size, trail, movement/bob/hop/turn formulas remain unchanged. Same-species copies remain distinct in inventory even though their one follower shares the same appearance. No ability/merge or purchased Data/Speed/Main activation.
- Verification: official Luau compile passed for all3 changed Sources. Existing tests/BasicEggOffline.py + .spec.luau extended:131 assertions passed using exact production Pet/state transaction functions and extracted exact UI/follower refresh functions with in-memory service/model stubs. Covers equip, different/same-species copy replacement, toggle-off, receipt replay, first-valid legacy2 migration, stale/empty/sparse/duplicate slots, ownership preservation, reload, rejection of unowned/malformed operations, UI count/checkmarks and retired/replaced/unequipped follower cleanup. Existing Hatch1/3/8 receipt/payment/failure/session tests also pass. No real DataStore, Studio gameplay execution or live player data was accessed.
- Fresh reDecode after same-file write:180249 instances, dense/header/INST/PRNT valid,76129 instance-reference values resolve,381 SharedStrings and206347 indexes valid, UniqueId duplicates0. No instances added or removed. Exact chunk/row comparison limits changes to3 Source values and the label's Text/AutoLocalize; every other property, Source, hierarchy and transform is unchanged, including Hatch/Egg probabilities/prices/per-copy ownership assets/Basic glow. Final SHA25677daadad41ab485f13ff50c0b022e123fb85748dc7489452280aed6cb5f88490.
- UNVERIFIED: new file was not opened in Studio during this task; rendered device UI and actual published-game equip/rejoin/follow behavior remain unverified. Cloud not reflected; user Save/Publish required before runtime confirmation. No local Play, Save/Publish or DataStore test. No Studio launched/closed; target.lock absent. Only this task's3 canonical Sources,2 existing offline test files and DEV_STATUS/CHANGELOG included in commit; unrelated local report retained.


## 2026-10-09 - Remove only the added treadmill caption duration

- Fetched/read latest origin/main893ce06 DEV_STATUS/CHANGELOG and preceding treadmill diff59c8d04. Used the latest actual CurrentCloud after single-Pet equipment changes; starting SHA25677daadad41ab485f13ff50c0b022e123fb85748dc7489452280aed6cb5f88490. No rollback or other task changes.
- Changed UI Full Paths: Workspace.Treadmills.{Normal01,Normal02,Iron01,Iron02,Gold01,Gold02,Diamond01}.BillboardGui.Multiplier. Respectively +1/+1/+2/+2/+3/+3/+20 Strength / 0.5s -> +1/+1/+2/+2/+3/+3/+20 Strength. Removed the duration suffix only; current numbers, plus prefix and Strength wording retained. All layout/artwork/AutoLocalize properties unchanged.
- Changed Source: ReplicatedStorage.Config.TreadmillConfig (matching canonical src). GetGainDisplayText now formats English +N Strength / Japanese +N strength wording without the seconds suffix. Existing LeftMenuClient continues to call this helper for refresh/localization, so it cannot re-add the duration. Amount computation and all configuration values unchanged; Training interval/gain/speed/access/charging and disabled presentation scripts untouched.
- Same-file direct write + fresh reDecode180249 passed; official Luau Source compile passed. Exact property/chunk comparison confirms only seven Text values and one Source changed; header, INST, PRNT, reference/SharedString chunks and all other properties/Sources unchanged; UniqueId duplicates0. Final SHA2569d732273f9c104073ca653008273dddf17e8ca4ed3c902c40afaead1c4fa910f. Basic glow, one-Pet equip/follow and user additions preserved.
- No Studio launched/closed or in-memory session modified; pre-existing target.lock left untouched. No Play, Save/Publish, backup or alternate rbxl. Cloud/runtime display not checked; changes are in disk CurrentCloud only. Committed only this Source and DEV_STATUS/CHANGELOG; unrelated local report retained. Earlier caption JSON remains historical evidence of the original change.


## 2026-10-10 - Purchased Rare / Legendary / Mythic Eggs connected

- Fetched/read latest origin/mainc892be1 DEV_STATUS/CHANGELOG and Basic placement/integration records first. Used actual current disk SHA2569d732273f9c104073ca653008273dddf17e8ca4ed3c902c40afaead1c4fa910f, including user additions, Basic glow, single-Pet equipment and duration-free treadmill labels. No existing Studio process/session at preflight; no stale file rollback.
- Purchased source of prices/pools/counts: ReplicatedStorage.Modules.Config.Eggs and ReplicatedStorage.Modules.Egg. Config and Egg module unchanged. Open1/Open3/Open8 map to1/3/8 and charge configured Win price times count. Scoped source/config/OpenEgg button inspection found no additional pass/product gate for these counts; no Robux product calls or paid entitlement were bypassed. No Speed rebate/ability/merge, purchased Main/Data startup or extra DataStore.
- Rare:10000 Win per roll; Cow40%, Giraffe25%, Lion15%, Lizard10%, Spider7%, Bat3%. Legendary:100000 Win; Elephant40%, Mammoth25%, Penguin15%, Crocodile10%, Octopus7%, Shark3%. Mythic:1000000 Win; Turtle40%, Alien25%, Anglerfish15%, Dino10%, Scorpion7%, Evil Dragon3%. Each pool totals100%. All24 actual authored Pet models/icons across four Eggs verified at ReplicatedStorage.Assets.Pets and Assets.Icons.Pets. Exact paths and1/3/8 totals are in [Purchased_Eggs_Expansion.json](Purchased_Eggs_Expansion.json).
- Layout: retained Basic(342.624420,12.111495,-7.353715) and shared purchased Workspace.Map.Spawn.PathToEggs.EggsStand/carpet/connector exactly. Applied their established source translation(+300,0,0) to Workspace.Eggs.Rare ->(342.958588,12.258780,6.666829), Legendary ->(342.965424,12.430873,20.474342), Mythic ->(342.964996,12.770164,34.474751), their21 stand/decorative parts and3 WorldPivotData values. Rare uses PathToEggs.Stands.RareStand; Legendary/Mythic use the two Standd models whose source centers were near(42.824,5.138,20.667)/(42.824,5.138,34.667), distinguished by geometry and seven-part membership, not first name match. Basic Standd untouched. Moved the existing shared Workspace.Eggs.Billboard heading by the same translation. Total25 BasePart transforms; rotation/size/appearance and all original attachment/emitter settings retained, no clones. Other Map objects and manual placements unchanged.
- Changed Source Full Paths: ServerScriptService.Services.EggServer; ServerScriptService.Services.PlayerDataService; StarterPlayer.StarterPlayerScripts.Services.EggClient; StarterPlayer.StarterPlayerScripts.Services.PetClient. Matching canonical src updated from current Sources. Server registration/lookup/distance/pool/model checks now use configured Egg name; positive integral unit price validated. Save validator requires EggName, correct configured count price and matching Pet/percent from that Egg. Existing owned UpdateAsync/revision/receipt/reservation/failure retry remains. Client registers all configured actual Eggs and passes the requested name into unchanged HatchClient.templateFor, retaining authored1/3/8 presentation. No Hatch reimplementation. Existing purchased OpenEgg six icon/percentage slots stamp each selected pool; hover uses actual names, cosmetic-only description. Original per-copy inventory, one equipped follower/replacement/toggle and following animation retained.
- UI: Workspace.Eggs.{Rare,Legendary,Mythic}.Prize.Info Text now10000/100000/1000000; init maintains all four configured prices at runtime. Basic saved Prize.Info remains prior0 (visible in Edit screenshot), and init still sets100 in gameplay. All other UI/layout retained; no substitute UI or effects. [Actual Edit image](Purchased_Eggs_Edit.jpg).
- Verification: all4 changed Sources compile with official Luau. Expanded existing in-memory tests/BasicEggOffline.spec.luau:462 assertions pass using actual production transaction/request functions and deterministic roll/model stubs, covering all4 Egg x1/3/8 price/pool/per-copy save, receipt replay, failed/ambiguous saves, balance/distance rejection per Egg, cross-Egg/incorrect price/odds rejection and one-Pet equipment. Existing single-Pet migration/UI/follower tests retained. These tests access no real DataStore/player data or Roblox gameplay; unchanged purchased RNG/presentation are not playback-tested.
- Same CurrentCloud directly written then fresh reDecode180249: dense/header/INST/PRNT and76129 reference values valid;381 SharedStrings and indexes valid; UniqueId duplicates0. No instances added/removed. Exact row/chunk comparison limited changes to4 Source values,25 CFrames,3 model pivots and3 price Text values. All remaining Sources/properties/configuration/geometry unchanged. Final SHA256672fd776d39b16ab60551ceeeb8b17886ea5fcef8f5ba60e26559dc80d4c947a.
- ACTUAL STUDIO LOAD / EDIT VISUAL PASS: dedicated PID20576, Studio8ad5b56d-4e15-470d-95cc-78a352617667 opened the exact file, PlaceId0, RunService not running. Readback checked four Egg positions, three price signs, all original enabled emitters, four seven-part stand bounds/pivots and both purchased Main Disabled. The screenshot confirms the four purchased Eggs/stands/effects on the shared red carpet. All four sampled approach boxes x333,y8,zEgg (8x6x10) contain0 foreign collidable parts; downward approach rays meet carpet y4.405015. Static placement/collision queries do not claim player navigation or gameplay tests.
- Cleanup: own PID/start/executable verified; CloseMainWindow returned false (hidden verification window), so terminated only that process and removed its remaining lock after matching first line20576. Process/target.lock absent; final disk hash unchanged. No user Studio closed, Play, real purchase/DataStore test, Save/Publish, backup, alternate rbxl or work folder. Cloud NOT reflected; live proximity/UI/hatch/input/network/save/rejoin/follow and asset playback remain UNVERIFIED until manual publish and authorized published-game confirmation. Commit only4 Sources, existing offline test, placement/catalogue JSON, actual screenshot and DEV_STATUS/CHANGELOG; unrelated local report retained.


## 2026-10-10 - Dance Girl supplied animation startup repaired

- Fetched/read latest origin/main641218f and DEV_STATUS/CHANGELOG. Exact saved model is Workspace.Dance Girl (with a space), already in CurrentCloud SHA256672fd776d39b16ab60551ceeeb8b17886ea5fcef8f5ba60e26559dc80d4c947a. No existing Studio process/session at preflight, so no unsaved inserted model was overwritten. Used this latest file, preserving Egg/Pet/treadmill/user changes.
- Limited inspection: Workspace.Dance Girl.Humanoid is R15 with one Animator; all15 Motor6Ds reference the correct16 body parts, including root/waist/neck/limbs. Only HumanoidRootPart is Anchored; body/accessory parts are not. Existing accessory joints retained. Original model pivot(315.055450,7.300014,73.859207). No rig/Anchored/size/appearance/placement changes. AnimSaves points to ServerStorage.RBX_ANIMSAVES.Dance Girl, an ObjectValue backlink to the model, with no attached KeyframeSequence/Animation data.
- Cause proven by Source and engine hierarchy: enabled Workspace.Dance Girl.EmoteScript (Legacy server Script under Workspace) declares local animationid=15122972413 but never uses it; controller:LoadAnimation(script.Animation):play() refers to a nonexistent Animation child. There were zero Animation descendants in the model and no other Dance Girl startup reference. The script also did not explicitly request looping. No published-game error log was claimed; the missing child/reference was directly checked in Edit.
- Supplied ID retained exactly: rbxassetid://15122972413. Marketplace readback: asset type24 Animation, name simssd, creator Roblox/User1. AnimationClipProvider fetched the authored KeyframeSequence with1312 poses covering the matching R15 body names. No unrelated emote or replacement asset. This Studio account could load and play it; no owner-side permission grant was indicated by this test. Published experience permissions remain part of Cloud confirmation, not proven by local Edit.
- Changed Full Path only: Workspace.Dance Girl.EmoteScript -> src/Workspace/Dance Girl/EmoteScript.server.luau (new canonical Source path, no temporary work folder). Reuses existing Humanoid.Animator, creates the missing Animation reference at runtime with the original ID, starts an Action-priority loop, guards repeated/duplicate script startup on this model, reuses an existing matching track and stops only duplicate tracks of this same dance. Script disable/destruction/model removal disconnects and cleans its track/runtime Animation/guard. Synchronous startup failures clear the guard and warn with the exact asset ID; no fallback animation.
- Same-file direct write/fresh reDecode180249 passed; syntax compiled with official Luau. Exact comparison permits only this one Source value: header/INST/PRNT, all reference/SharedString chunks, other Sources and every rig/model/property row unchanged; UniqueId duplicates0. No persisted Instances created or cloned. Final SHA256256605c22fa0c03a901b900c517acf2d7efd35907d7fa2e67fe9de3a89e323d6.
- EDIT PLAYBACK CONFIRMED (not local Play): opened exact repaired disk file in dedicated Studioc0676a45-53c1-4a17-bdfd-57021a3502ed/PID6256, PlaceId0, RunService not running. Invoked only the repaired NPC Source directly in Edit and manually stepped its Animator. Original ID loaded with length3.375s; all15 Motor6D transforms changed, and all15 advanced between0.5s samples. Calling Source twice produced one track. Stepping beyond the3.375s duration wrapped to0.25s with Looped=true/IsPlaying=true. Disable cleanup removed the temporary Animation/guard and left0 playing tracks; model pivot restored with0 position error. No gameplay/bootstrap/DataStore execution. Ordinary game-start Script scheduling still requires published-game confirmation.
- An earlier diagnostic session returned zero-length tracks after its fetched provider clip had been destroyed during inspection; that session was discarded and its cache reset by closing it. Those observations are not treated as an asset/permission failure or replay success. The fresh-session test above used the actual repaired Source and original asset ID and passed. No animation was re-published or substituted.
- Cleanup: only dedicated PID35052/start09:43:55 and PID6256/start09:49:06 were closed after identity checks (hidden windows had no normal close target); their matching residual target.lock files removed. Final process/lock absent; disk hash unchanged after Edit testing. No user Studio closed, local rbxl Play, Save/Publish, backup, alternate rbxl or work folder. Cloud NOT reflected: user must Save/Publish and confirm automatic looping in the published game; replication/Cloud asset authorization/runtime lifecycle remain UNVERIFIED. Only NPC Source and DEV_STATUS/CHANGELOG committed; unrelated local report retained.
- API reference used for direct Animator playback: https://create.roblox.com/docs/reference/engine/classes/Animator/LoadAnimation . Actual asset/Rig/playback findings above come from this file and engine checks, not from asset-name inference.


## 2026-10-10 - Inventory / Skip purchased Shop visual refinement

- Fetched/read origin/main a753938 and latest DEV_STATUS/CHANGELOG/prior UI records first. Started from actual CurrentCloud SHA256256605c22fa0c03a901b900c517acf2d7efd35907d7fa2e67fe9de3a89e323d6, preserving later Dance Girl/Pet/Egg/user changes. Shop donor was inspected in Edit alongside both targets. Found header-relative .06/.05 strokes incorrectly applied to entire panels, yellow inner rim, red StarterPack pane strokes, old Inventory icon/title overlap and hidden saved Skip purchase artwork.
- Changed Full Paths: StarterGui.StrengthGui.InventoryPanel; StarterGui.StageSkipGui.Panel; ReplicatedStorage.Modules.InventoryPresentation; ReplicatedStorage.Modules.ResponsivePanels; StarterGui.StrengthGui.InventoryPanelClient. Reused ShopPanel/Top/Close/Card01_SecretPack artwork with appropriate border widths, light purple/pink surfaces, clear header/tabs/content spacing and purchased yellow Win/green Robux visuals. Text surfaces keep white lettering; selected/equipped styles and repaint protection retained. Inventory short-landscape layout preserves equipment and readable cards, fixes socket/header overlap and clipped first-row card controls. Other panels and gameplay/IDs/prices/conditions unchanged.
- Important current-source preservation: disk AuraInventoryClient/SpeedInventoryClient contain existing purchased-button integrations absent from their older canonical Git copies. Initial proposed edits to those canonical copies were discarded; neither in-file Source was replaced. ResponsivePanels had no canonical file, so its current Source was exported with only Inventory's compact design and Items card-height changes. No historical audit Source overwritten.
- Direct same-file writes + fresh reDecode:180249 instances; dense/header/INST/PRNT valid;76129 refs;381 SharedStrings/206347 indexes; UniqueId duplicates0. No persisted instances cloned/added/deleted. Exact row/chunk checks restrict cumulative differences to895 target UI property values and3 Source values. All3 Sources and the display fixture compile. Final SHA256a2f7ec57940b48a08b46433c4c92c8c0fe69a153cec3e7ef2bcac3d4da3cf26a.
- ACTUAL FINAL STUDIO LOAD: PID24896/start11:34:28, Studio86f8c918-9dfc-4ea0-a63c-f2beb3a17eb5, exact CurrentCloud/PlaceId0/Edit. Final Sources read back; display-only fixtures ran through all5 existing Inventory renderers with Remote writes/purchase prompts blocked and background network loops suppressed. Verified all-tab reopen, Owned/Equipped,9 Robux item cards, selected palette/old-color guard, compact socket and card bounds,196px dumbbell cards and310px desktop restoration. Scroll limits checked for Dumbbells/Items/Aura and Skip Stage10. Nine actual Edit screenshots and [review/limits](Inventory_Skip_Visual_Review.md) recorded. Japanese images are temporary width samples; mobile is844x390-equivalent landscape within1280x720 captures.
- LIMITS / EXCEPTION: Cloud NOT reflected. Real ownership/purchase/save, end-to-end merge selection/result, translation delivery, portrait/touch and live startup remain unverified. Earlier verification PID18528 unexpectedly yielded a tool Play-mode response and two gameplay images; no Start Play call was made by this agent. Next query/readback was already Edit, so no Stop action was needed. Those images were excluded; this is not a local-Play test claim. Cause unknown. No Save/Publish, purchase or data-changing command was issued.
- Cleanup: only own PIDs7040/18528/24896 with recorded start times were ended; normal CloseMainWindow had no accessible target, so only those disposable fixture processes were terminated. Initial lock deletion raced process teardown; after exit final matching residual lock was deleted. Final verification process and target.lock absent, disk hash unchanged. No user Studio existed at preflight; no backup, alternate rbxl or work folder. Only3 Sources, fixture,9 captures, property provenance/review and existing docs recorded; unrelated local report retained.


## 2026-10-10 - Inventory / Skip aligned with purchased Shop, saturated colors

- Fetched/read latest origin/main2e9920e and DEV_STATUS/CHANGELOG/prior UI evidence first. Started from CurrentCloud SHA256a2f7ec57940b48a08b46433c4c92c8c0fe69a153cec3e7ef2bcac3d4da3cf26a. User revoked pastel pink. Preserved current Dance Girl/Pet/Egg/gameplay Sources and original yellow Win/green Robux controls. User Cloud Studio PID33344 was already in Play at preflight; no calls changed its mode or closed it. Dedicated verification Studios were used one at a time.
- Changed Full Paths: StarterGui.StrengthGui.InventoryPanel; StarterGui.StageSkipGui.Panel; ReplicatedStorage.Modules.InventoryPresentation; StarterGui.StrengthGui.InventoryPanelClient; StarterGui.StrengthGui.ItemInventoryTabClient. Restored StarterGui.StageSkipGui.Enabled=true after the independent preview save described below. No price/ID/purchase/equip/merge/Skip/server/save logic changed. Current Aura/Speed/Responsive Sources retained, including integrations absent from historical Git copies.
- Donor: StarterGui.StrengthGui.ShopPanel.Top/Top.Close/MainScrollingFrame.Holder.Card01_SecretPack and same-role Title/Benefits/Owned.PriceTag typography/strokes. Saturated purple Inventory and blue Skip headers; Shop RGB7,7,12 body at0.5 transparency. Transparent equipment/list wrappers, individual card gaps, no body-wide studs or old pane borders. Purchased90px stud tiles compensate for Inventory scale. Removed obsolete contextual strokes instead of layering another active/inactive outline. Inventory left29%/right70%,3-column206px dumbbell cards (186px short landscape), wider Items list and compact Best Equip/socket spacing. Skip76px rows,12px gaps, aligned prices and automatic scroll canvas.
- Actual1280x720 captures compare Shop/Inventory/Skip at approximately648px panel width. All5 Inventory tabs, Merge owned-card selection, Japanese CSV wording and844x390-equivalent landscape layouts recorded: [comparison and verification limits](Inventory_Skip_Shop_Alignment.md). Production renderers used only memory display fixtures with Remote writes/purchase prompts blocked. Verified reopen, Equipped changes,9 rarity5 cards, old-color restoration guard, duplicate binding, scroll endpoints and full Stage10 visibility. No Cloud/live transaction or automatic localization claim.
- Initial same-file write changed574 target UI property values and3 Source values; fresh reDecode180249 passed with dense INST/PRNT,76129 refs,381 SharedStrings/206347 indexes, UniqueId duplicates0. Studio loaded it successfully. Subsequent final Source-only write was stopped by a hash mismatch: at12:20:57 CurrentCloud was independently reserialized to181684 instances, SHA7eab2a32e647ed0385c1345278e7f801b0a13e436817a7f7585794e7fc777d30. No agent Save/Publish call was issued; save caller unknown. Final Source was already present, alongside display-fixture objects.
- Narrow cleanup identified1418 temporary UI instances by session UniqueId suffix2cccece64c253bc8 AND membership in the two target panels; none parented an original child. Removed only those fixtures, restored recorded original presentation geometry/properties, reset saved Skip language-width samples and enabled its ScreenGui. Retained all out-of-scope latest-file instances, including17 net additional engine/session instances; no old-rbxl rollback. Reserialized dense referents and all reference targets after removal. Final180266 instances,76155 reference values,381 SharedStrings/206364 indexes, UniqueId duplicates0. [Exact property/cleanup provenance](Inventory_Skip_Shop_Alignment.json).
- Final saved file actually opened in Studio ad1e7aa1-e410-4da6-bc39-3b21ed9bb5e4 / PID21880, PlaceId0/Edit. Before running the fixture, confirmed no saved NORMAL_01 card/ProteinSocket/MergeFlow, Skip enabled and final Source present. Fresh fixture verified all tabs/reopen, exactly one Best Equip/socket, no compact overlap, and exactly one contextual Merge glyph stroke. All3 production Sources and the fixture compile. Final SHA2566b514fa62b336bfc9d4e0969d6d2cc6dd6fa8d5978ea67ed278b9f8c21cfe7b5.
- LIMITS: Cloud not reflected; live input, purchase/equip/merge/save, real server refresh, automatic translation delivery, portrait and physical touch remain unverified. Japanese captures are width/glyph samples, not a localization deployment test. Price lookup is suppressed in offline fixture; Speed shows existing... fallback. Some purchased image assets required preload; no replacements were invented. No local Play/purchase/Save/Publish/backup/alternate rbxl/work folder was invoked. Own verification PIDs25112/34936/21880/34988 only were closed; final lock/hash check recorded after cleanup. User Studio was not closed. Commit only task Sources/fixture/10 actual captures/provenance/review and existing records; unrelated report preserved.

- Preview-save cleanup also restored visibility of StrengthGui.HUD/LeftMenu/StrengthLevelHUD and Enabled on LevelUpGui/StrengthGainGui/WorldTravelGui/World1DoubleWinGui. These were hidden for screenshots; existing clients require their containers enabled. No styling or Source of those other screens changed; purchased ScreenGui and legacy Merge screen remain disabled. Final additional load checks use only read-only inspection, without executing a fixture.

- Final read-only load: Studio86e44785-0b6f-47d4-af2c-23978164ffcb/PID34988, PlaceId0/Edit, confirmed target names/translucency, restored startup containers, purchased ScreenGui disabled and no saved fixture cards/sockets/MergeFlow. No fixture executed in that last session. Process and target.lock absent after closing only PID34988; final SHA2566b514fa62b336bfc9d4e0969d6d2cc6dd6fa8d5978ea67ed278b9f8c21cfe7b5 unchanged after Studio.


## 2026-10-10 - Inventory / Skip title icons only

- Read origin/main b912b9d and current UI history. Latest user file was SHA256 add83062539f15b5cc997d025caf7bb3ccbd6d2be29889b3f2544edf37f88b7b, 179131 instances; used this current file, not the prior task file. No Studio session/target lock was present before verification.
- Restored `StarterGui.StrengthGui.InventoryPanel.InventoryTitleIcon` (rbxassetid://96014751655862), the original object retained in CurrentCloud and visible in read-only PreMerge. The presentation module had explicitly hidden it. Created exactly one `StarterGui.StageSkipGui.Panel.SkipTitleIcon` by copying the existing `StarterGui.StrengthGui.LeftMenu.SkipButton.Icon` (rbxassetid://106809643209866), also present in PreMerge. Neither inspected file had a Skip title ImageLabel; this is reuse of the original Skip entry icon, not a claim that a historical Skip title object was recovered. No new/replacement image asset.
- Only changed `ReplicatedStorage.Modules.InventoryPresentation` Source, the two icon layouts/visibility and both header text layers' left margin. Icons are40x40 at x16, header vertical center, with12px separation from title x68; text right edge stays unchanged. Existing Inventory icon path is retained. Binding protects icons from styling passes, reuses the saved Skip icon (guarded fallback clone), and keeps vertical alignment in compact layout. Current colors/header/body/cards, purchases/equipment/merge/Skip/data/gameplay unchanged.
- Direct write to the same CurrentCloud only; reDecode179132 instances, dense referents/complete PRNT,75837 reference values,366 SharedStrings/205134 indexes and UniqueId duplicates0. One changed Source compiles. No other Source changed. Final SHA2565466282b772d61b2b39c2688cabfccbca95750cea0e370567b9595c96bdf56f4.
- Actual file loaded in one verification Studio,25adca90-c896-4ae5-80ca-14f5d4b4bf89 / PID4700, PlaceId0/Edit. Saved icons/positions/Source read back. Presentation binding on disposable CoreGui clones passed repeated binding and close/reopen checks with exactly one icon per panel. Original saved panels were then temporarily shown for actual [Inventory title](Inventory_Title_Icon_Restored.jpg) and [Skip title](Skip_Title_Icon_Restored.jpg) captures; both images visible and12px text separation confirmed. Title scope only: empty Inventory body in Edit is not a runtime inventory test.
- Restored every temporary Visible/Enabled value, removed CoreGui previews; no Camera/selection changes. Closed only the identity-checked verification PID4700, removed its residual target.lock, verified no Studio process/lock and unchanged final rbxl hash. No preview UI saved. No Play/Save/Publish/purchase/backup/alternate rbxl; Cloud/live rendering unverified. Unrelated reports/Visual_Templates_Secret_VIP_Green_20260917.md preserved outside commit.


## 2026-10-10 - Permanent Robux Egg Phase 1 (read-only mapping)

- Fetched/read latest origin/main2cca755, DEV_STATUS/CHANGELOG and existing Pet catalog. Read current CurrentCloud SHA2567f3a4c4f8742c3769ef9a7c07842bcaa1bd8c15b28ca0e69e85ec5ce295a85f7 (179132 instances), preserving user updates after the preceding UI task. No connected Studio; no new Studio or game changes.
- Confirmed Workspace.Chill Octopus actual Prompt/labels/position and old GamePass1962289090 to StandClient/PurchaseClient path; purchased Main Server/Client are disabled and active narrow Pet bootstrap does not start Stand. Old label99/200%-better and Equip action do not implement the new offer.
- User-confirmed offer: permanent Developer Product,149 Robux/one Pet; Pet_042/064/081 each25%,08615%,0946.5%,1353%,0240.5%; total100%, per-copy save, one equipped, no abilities/merge. Seven current models match catalog identity/Root coordinates, with existing real photos and limited geometry/Rig checks. They are not yet in Pet.model's Assets.Pets search path. Product ID UNSET in inspected configs/routing; Creator Hub product inventory not checked.
- [Full Paths, seven-Pet table, two unselected Egg candidates, Phase 2 changes and official policy references](Stud_Egg_Pet_Catalog.md#permanent-robux-egg-phase-1---mapping-2026-10-10). OpenEgg has6 slots; preserve purchased frame/Percent/Button and add seventh plus inner ViewportFrame. PetInventory.Main.Icon also needs3D mounting. Existing Hatch/follow Root-only orientation reset needs care with multipart models.
- Reuse sole ReceiptService registration and existing purchase journal; persist one result/copy ID per PurchaseId and atomically record grant marker with Owned before Granted. Current latest-only LastRequestId is insufficient for delayed paid receipts. Preserve existing session ownership, per-copy saves/equip1 and all Win Eggs. Record odds disclosure, server PolicyService restriction/error denial and in-game-only sales proposal. No old Product ID reuse, product creation or sending.
- Static/file and existing-photo evidence only; current Studio/Viewport/asset permission/Cloud purchase/hatch/follow and retry tests remain unverified. Only existing documentation changed; no rbxl/Source/Camera/model/Play/Save/Publish/backup/alternate file/work folder operation. User Studio untouched.


## 2026-10-10 - Limited Egg 01 Phase 2: facility/display only

- Read/fetched origin/main4889874 and Phase 1; repaired the corrupted Phase 1 catalog section/links in English. New records use English. Latest user file preserved: input7f3a4c4f8742c3769ef9a7c07842bcaa1bd8c15b28ca0e69e85ec5ce295a85f7; final7cdc289399aa87bf35ab0d737ee4507a5abde4196e843f05d53ae616b39ce384.
- Workspace.Chill Octopus remains at(7.428236,8.665257,32.959766), same appearance/size/orientation. Its purchased Prompt opens Limited Egg 01 through LeftMenuClient -> PetClient.bootstrap -> StandClient. Retired GamePass/equip route removed from this station; labels now name/price/one Pet. Product3717610547/base149 registered for display only; purchased green button disabled, no payment/roll/grant/save or server receipt changes.
- Exact purchased Pet_042/064/081/086/094/135/024 copies in ReplicatedStorage.Assets.LimitedEgg01Pets; odds25/25/25/15/6.5/3/0.5=100%. Seven static Viewports in a clone of purchased OpenEgg UI; PetClient's existing tile builder supports the same3D models. Models framed together without root-only distortion; inventory title band preserved. Normal four Eggs/six candidates/Win/1/3/8/Hatch/equip1/follow and all other properties untouched.
- Changed Sources: ReplicatedStorage.Config.LimitedEggConfig (new), ReplicatedStorage.Modules.LimitedPetViewport (new), StarterPlayer.StarterPlayerScripts.Services.StandClient and PetClient, ServerScriptService.Services.StandServer. Purchased Main remains disabled; only client Stand starts, no purchased Data.
- Final reDecode179515 (+383), dense INST/header/PRNT,76082 references,366 SharedStrings/205757 indexes, UniqueId duplicates0; five Sources compile. Final file loaded successfully in Studio Edit. Actual seven-model/odds/text-fit captures, show/close/reopen idempotence, inventory hide/reopen cleanup and final no-fixture checks passed. No real data was granted. [Paths, provenance, images and Phase 3 work](Stud_Egg_Pet_Catalog.md#permanent-robux-egg-phase-2---facility-and-display-2026-10-10).
- Read-only Marketplace lookup returned135 Robux; UI uses this when fetched,149 fallback. Screenshot shows offline fallback. Creator Hub pricing/experience association remains for owner verification; no purchase was prompted.
- Own sequential verification PIDs10436/24868 closed without Save; no Studio process/target.lock and unchanged final hash confirmed. No user Studio closed, local Play/purchase/DataStore/Save/Publish/backup/alternate rbxl/work folder. Cloud unreflected: live Prompt/bootstrap, touch, purchase/Hatch/follow/save/policy/retry unverified; Phase 3 not connected. Unrelated report preserved.


## 2026-10-10 - Move Limited Egg 01 to the active World1 Lobby

- User reported that Octopus was not visible from the active Lobby. Confirmed the previous Phase 2 retained the purchased-map position (7.428236,8.665257,32.959766), about281 studs from the active Spawn. The earlier capture was in the original purchased map and did not prove active-Lobby usability. User explicitly authorized relocation, superseding the earlier keep-position constraint.
- Moved the existing `Workspace.Chill Octopus.PetMesh` to (315,8.665255,40), yaw+45 degrees facing Spawn, inside `Workspace.GeneratedMap.TrainingArea` spatially. Parent/Full Path remain `Workspace.Chill Octopus`. Exactly one saved CFrame property changed; no clones, Source, UI, size, appearance, purchase, data or other placement changes.
- Same latest CurrentCloud updated: input SHA2567cdc289399aa87bf35ab0d737ee4507a5abde4196e843f05d53ae616b39ce384; output b5e67aefaef10c0c596ac81c6384bcb96a6df716fca6c58250a963f28cb6a686. ReDecode179515, dense referents/complete PRNT,76082 references,366 SharedStrings/205757 indexes, UniqueId duplicates0; all other property rows byte-identical. No Source syntax change.
- Actual Studio Edit load passed. FeetY4.00000048 versus FloorTopY4; expanded footprint (+2 studs X/Z) found zero other overlapping parts with the floor excluded. Spawn-eye ray to the station was unobstructed; center distance38.58 studs. [Actual view from the Spawn side](LimitedEgg01_World1_Placement.jpg) shows the original Octopus beside the Egg area, clear of the main red path. Prompt remains View Pets and title Limited Egg 01.
- Opened only verification PID8648 at18:28:35; closed without Save and removed its residual lock. No Studio process/target.lock remained; final file hash unchanged. No user session was present or closed. No Play/purchase/Save/Publish/backup/alternate rbxl. Cloud remains unreflected; actual E/touch interaction unverified and Phase 3 purchase remains disconnected. Only this placement record/image committed; unrelated report preserved.


## 2026-10-10 - Limited Egg Phase 4 presentation / equipment / follow

- Fetched/read origin/main1d12daf and inspected latest CurrentCloud. Phase 3 is NOT implemented: Product3717610547 exists only in the display registry; no receipt/roll/grant/save integration. Purchase button remains disabled; no Phase 3 or purchased Main startup was added.
- Changed four Sources: ReplicatedStorage.Config.LimitedEggConfig; ReplicatedStorage.Modules.Pet; StarterPlayer.StarterPlayerScripts.Services.HatchClient and PetFollowClient. Latest instructed odds are042/064/08125%,08615%,0946.5%,0243%,1350.5%. Registered seven existing purchased models for the unchanged server owned-copy equip path, inventory and max-one follower. Preserved rig-relative transforms by whole-model pivots/scaling; existing follow movement/hop/bob reused. Added limited Hatch mounting and a guarded post-save consumer with visual PurchaseId deduplication; its sender/Remote remains deferred to Phase 3.
- Extended existing offline suite:545 assertions passed (regular Egg regression, exact server owned/unowned equip, replacement/unequip/equip1, individual IDs, cancellation/unconfirmed/repeated notification gates). Four Sources compile. Actual Edit file load and seven-model geometry/follower simulation passed; multipart relative error<=0.00000236 studs, height3. Hatch model bounds fit16 orbit angles each, ratio<=0.819. [Full paths, notification contract, actual display image and limits](Stud_Egg_Pet_Catalog.md#limited-egg-01-phase-4---hatch-models-equipment-and-follow-2026-10-10).
- Initial agent write changed only four Source values,179515 instances; SHA2561fc67a98c2269969013dc1e5a84e46d9e04684f7f37611d7ecd2ad7283464e8a. A separate write at19:39:07 produced latest c5d080bcd0f0adc97c5fa85cd4b8bd7bb6cdd1e8628dfdb4b6e44d419419399b /179534 instances. Preserved latest; all four Sources retained and no task preview instances. Final reDecode/header/PRNT,76112 refs,366 SharedStrings/205776 indexes,UniqueId0 passed. No old-file overwrite.
- Only verification PID11620 (19:33:10) was opened. Temporary UI/modules removed and UI states restored; PID already exited before the close command executed. Final no Studio process/no target.lock verified, so no residual lock needed deleting. No user Studio killed and no final reopen. No local Play, purchase, real grant, DataStore, Save/Publish, backup or alternate rbxl.
- Phase 4 display/model/equipment paths are prepared; end-to-end purchase -> durable save -> notification -> timed Hatch and live replicated follow remain UNVERIFIED. Cloud not reflected; Phase 3 sender/persistence/policy and cross-session receipt deduplication still required. Commit only task Source/tests/image/English records; unrelated report preserved.
