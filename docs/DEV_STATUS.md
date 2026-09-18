# DEV_STATUS — 開発状況

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
