# GAME_SPEC — ゲーム仕様正本

## 2026-09-18 — World1 Double Win purchase entry

- LobbyのWorld1DoubleWinShopは購入エリアへの入場で既存GamePassService.Promptを呼ぶ。E / TapによるProximityPrompt操作を廃止。右HUDの既存購入Buttonは変更しない。
- ServerがPedestalの相対座標で生存CharacterのHumanoidRootPartを0.1秒間隔で確認。8×8studの台座から左右前後2studまで（12×12）、台座上面の1stud下から高さ10studを購入エリアとする。外側0.75studを退出判定の余裕として境界の揺れを防ぐ。
- Playerごとの入場状態を所有確認前に記録。購入 / Cancel後も退出まで再Promptしない。所有確認中に退出・Character変更した場合は古い入場要求を破棄する。スポット外のRespawnではPromptしない。
- GamePassService.HasWorld1DoubleWin / Promptを再利用。Pass ID=1970515086、Config倍率2、Roblox側価格、UserOwnsGamePassAsync・Cache・購入完了後の再所有確認・World適用範囲・StudioDebugの効果抑制は変更なし。


## 2026-09-17 — Equipped Item Effect HUD

- Level / Strength Gauge上部に装備中Protein / Glove / TrainingBeltの効果を横並び表示する。未装備は非表示。Item名ではなく専用miniiconと「+N STR / +N% DMG / +N Tier」を使用。
- 値の正本は実計算と共通のItemMultiplierConfig.GetProteinBonus / GetGloveBossDamageBonus / GetBeltTreadmillBonus。既存ItemInventoryStateと装備・購入・Merge応答のStateから、所有中かつ種類が一致する装備ItemのRarityを読む。Element別の数値定義やUI用Balance表は追加しない。
- Gloveは既存World1 BossCombatServiceが戦闘開始時に保持したGloveBonusを実際に使い、Boss HPが減少した命中でだけ演出する。EnemyManagerの既存BossGauge通知へAttackId / GloveAppliedを追加。Manual / Auto共通。LOTTERY_WIN・Wall・補正なし・無効攻撃は対象外。World2の現行CombatはこのGlove計算を呼んでおらず、新たな補正を追加しない。
- BeltはServerの受理済みIsTraining / TrainingTreadmillと生存・装備状態で演出する。Proteinは静止。装備変更・死亡・Respawnで表示とTweenを更新・解除する。
- 効果、Strength / Damage / Treadmill計算、Merge、Item保存、Balanceは変更しない。


## 2026-09-17 — Merge selection flow

- Mergeは開始→基準Itemを1つ選択→自動素材セットと実行の3STEP。所持数1以上でItemMergeService.GetMergeResultが受理する通常Itemを選択可能とし、素材不足でも基準Itemとして選べる。Legendary / 無効定義 / 未所有Itemは一覧から除外。
- ItemMergeControllerの読み取り専用ItemMergeStateがGetMergeResult / CanMerge / ItemService.GetItemCountを直接呼び、結果ItemId・所持数・実行可否・拒否理由を返す。UI専用のMerge互換性・実行可否判定は追加しない。
- 同一ItemId×RequiredCount（現行3）→同Type・同Elementの次Rarity×1を維持。InventoryはItemId別数量で個体IDなし。基準Itemの数量を先頭Socketから必要数だけ表示する。装備中Itemを別扱いで除外する新ルールは追加しない。
- MERGE押下だけが既存ItemMergeRequestを送信。Serverの再検証、RunItemTransaction、RemoveItem / AddItem、ChangeItemCounts / ResolveItemMutationの永続化経路は不変。成功後はServer状態を再取得し、同じ基準Itemの充足または0〜2個の不足状態を表示。
- 他Inventoryタブ、通知Seen、Balance、Item定義、保存Schemaは変更なし。[監査・検証](../reports/Merge_UI_20260917.md)。


## 2026-09-17 — Treadmill visual templates

- ReplicatedStorage.TreadmillVisualTemplatesはTreadmill本体専用。Player用AuraVisualTemplatesと装着処理を共有しない。
- 初回導入のPremium_FireはWorkspace.Treadmill.Tredmill01.PremiumAuraの3 ParticleEmitterをInstance Cloneで保持。現在のStudioライブラリはAura 17個、Treadmill 10個へ拡張済み。正式保存物はassets/AuraVisualTemplates.rbxmとassets/TreadmillVisualTemplates.rbxm。Visualの正本はStudio Instanceとし、LuaへParticle設定を転記しない。
- TreadmillConfig.Types.<種別>.VisualTemplateで指定する。通常 / Rebirth3 / Rebirth7は空文字、PremiumはPremium_Fire。倍率・利用条件とは独立。PremiumのVisualInstanceName=PremiumAuraは既存Effectを置換するための表示Object名であり、性能設定ではない。
- TrainingManager.Initializeから共通TreadmillVisualService.Applyを呼ぶ。TrainingZone.VisualRoot Attachmentを装着基準とし、Template.RootからのPart / Attachment相対配置・Particle設定を維持する。
- 同名Template再適用は既存Objectを再使用。別Templateへ変更時は旧Effectを置換。空指定はEffectなし。利用可否によるParticle制御やPlayerイベントでのCloneは行わない。
- 配色、Mat、Guide、倍率Billboard、Strength / Rebirth表示、Training間隔・倍率・条件、Player Aura、DataStoreは変更しない。

## 2026-09-17 — Studio Win debug commands

- Studioのチャットで/addwin 数値は本人のWinへ加算、/setwin 数値は本人のWinを設定する。0〜9,007,199,254,740,991の十進整数のみ受理し、負数・小数・NaN / Inf・不正文字列・引数過不足・加算overflowを拒否する。
- 既存StudioDebugController / StudioDebugService経由。IsStudioと接続中Player本人の検証、DebugBusy / DataNotLoaded / DataBusyを共用する。現行Debugには追加のUserId許可リストは存在しない。ProductionではCommand未登録かつExecuteはStudioOnlyを返す。
- session.Data.Winを正本としてPlayerDataService.SetWinを使用する。AttributeとDirtyが更新され、通常のautosave / 退出保存でPlayerData_v1_Studioへ保存される。セッション限定で自動復元する機能ではない。必要なら/setwinで元の値へ戻す。
- 新規WinコマンドはStore名がPlayerData_v1_Studioであることも確認する。Production Reset経路・OrderedDataStoreは呼ばない。/resetdataの既存仕様、価格、Reward、Balance、保存Schemaは変更なし。

## 2026-09-17 — Reusable Aura visual templates

- Visual正本はReplicatedStorage.AuraVisualTemplatesの8個のModel。ParticleEmitterの設定をLuaで再生成せず、Studioで編集したInstanceをCloneする。
- AuraConfig.Auras.Pink.VisualTemplate="Pink_Aura3"。AuraCharacterEffectsが既存AuraServiceの所有・装備判定後にTemplateを取得し、Character.AuraEffects.EquippedAuraVisualへ1組だけ装着する。
- ModelのRootをAttachTo属性（初期UpperTorso、R6 Torso / HumanoidRootPartへfallback）へ合わせ、各透明carrier PartのRoot相対CFrame・SizeとAttachment / Particle / Light設定を保持する。衝突・Touch・Queryは無効。元Workspace素材・マネキン・Map配置は変更しない。
- Unequip / 装備変更 / 死亡でVisualを削除し、Respawn時は既存保存装備から再適用。Pinkの旧0.67倍Size補正は廃止し、Pink_Aura3の14Emitterをそのまま使用する。
- 所有、Price、StrengthBonus、購入、通知、保存、GamePass条件に変更なし。今回のStudio上のPinkはPrice=250 / StrengthBonus=50で、旧BALANCE_SPECの表値へ戻していない。
- Template本体はassets/AuraVisualTemplates.rbxm（Roblox標準SerializationServiceによる保存）、変更Scriptはsrc/。自動Studio同期・Publishは行っていない。


## 2026-09-16 — Auto Tap / Manual Training / Manual Combat

- Auto Tapボタンは画面下部のLevel / Strength Progress Gaugeのすぐ右隣へ配置。既存ゲージを親とするコンパクトな2段表示とし、位置・サイズはHUDに追従する。配置・装飾変更のみで下記の設定保存・入力・Training / Combat仕様は変更しない。
- PlayerData.AutoTapEnabled（Boolean）を追加。未保存の旧データはtrue。既存Load/normalize/Save経路で保存し、Player Attributeは表示用の鏡とする。通常のResetでは他の初期値と同様trueへ戻る。
- ON：通常・BattleCorridor非Combatでは従来の地上歩行条件で0.5秒ごとにStrengthを付与。停止中に新しい自動付与は追加しない。Combatは従来のAttackInterval=0.8秒、Wall命中遅延0.18秒 / Boss命中遅延0.5秒を維持。
- OFF：通常・BattleCorridor非Combatの自動付与を停止。画面Tap / 左クリックで通常のStrength計算を1回実行（最小0.25秒）。歩行計算と同じくDumbbell加算なし。既存Aura / Protein / Rebirth / Potion / VIPの扱いを変えない。
- OFFかつ接触Combat中：自動攻撃を開始せず、入力時に現在のWall / BossへManual Attack。最小0.25秒をServerで再確認し、受付時に既存Damage関数を実行。Strengthは加算しない。ON中に受付済みの遅延命中は既存どおり完了する。
- Treadmillの占有を最優先し、ON/OFFを問わず既存0.5秒Training。Tapは追加StrengthもAttackも発生させない。倍率・利用条件・付与量は変更なし。
- ServerのAutoTapServiceが保存状態・生存・Treadmill占有を確認し、EnemyManagerが既存接触対象・Pending・攻撃Cooldownを確認する。Clientから対象・座標・Damage・獲得量は受け取らない。
- 設定正本：ReplicatedStorage.Config.AutoTapConfig。AutoInterval=0.5、ManualTapCooldown=0.25、ManualAttackCooldown=0.25、ManualAttackAnimationSpeed=2.0。自動CombatとTreadmillの周期は従来Configのまま独立。
- 変更Scriptの現行ソースはsrc/に保存。過去reportsのソースは更新しない。Balance、Carry、Stage順序、Reward、Map、World2は変更なし。

## 2026-09-16 — Tutorial Guide floor-only arrows（Completed）

- TutorialGuideClientの床候補をGeneratedMap内の正規Floor / ConnectorFloorへ限定。TrainingZone、Terrain、Asset内の同名Floorを候補にしない。
- 矢印の中心・両腕の端点・中点・縁を検査し、床外または可視Assetの領域にかかる矢印一組を非表示にする。CanQuery=falseのマットも遮蔽物として扱う。
- Start / Goal / 経路 / 間隔 / 形状 / 更新周期 / Tutorial進行と保存仕様は維持。
- Studio再起動後の最終Playで床表示、Treadmill / 非Queryマット / 操作パネル / Wall / Character / Enemy上の非表示、床への復帰時の再表示を確認。実経路28組の判定不一致0、表示矢印の床高さ不一致0、OutputのError / Warning / Infinite Yieldなし。Tutorial進行コードは変更なし（全Tutorial完遂は未検証）。[確認記録](../reports/Tutorial_Floor_Only_20260916/build_report.md)。

## 2026-09-16 — Treadmill group multiplier guidance

青Treadmill2台の中央上部に×3、緑2台の中央上部に×5を各1個のClient専用BillboardGuiとして追加する。既存の各機器Strength / Rebirth UIは維持。TreadmillConfig.MultiplierBillboardで距離100stud、基準Size16×10stud、TextScale1.5、高さOffset12studを設定する。標準MaxDistanceで遠距離非表示にし、本人が青利用中なら×3だけ、緑利用中なら×5だけを非表示にする。未利用・通常・Premium利用中は両方が距離条件に従う。判定はServerの受理済みTrainingTreadmillと既存Configの実Multiplierを使用する。

ベルト上のChevronガイドはPlayerが使用可能なTreadmillだけ表示され、使用可能な間は常時流れる。TrainingManager.CanUseTreadmillの結果をPlayer個別属性として通知し、ClientのSurfaceGuiとTweenで描画する。ガイド側でRebirthやGamePass条件を重複実装しない。設定はTreadmillConfig.Guideへ集約。利用可否・報酬計算・Interval・Balance・Premium条件・既存色・マット・DataStoreは変更しない。[実装・検証報告](../reports/Treadmill_Availability_Guides_20260916/build_report.md)。

## 2026-09-16 — Treadmill Strength reward colors

World1 Treadmillの見た目は、実Trainingに使用するReplicatedStorage.Config.TreadmillConfig.TypesのMultiplierを色判定の正本として使う。StrengthColorsはMultiplierごとにBeltColor / FrameColor / MatColorを持つ。+3は明るい青ベルトRGB(55,145,255)、濃い青フレームRGB(20,65,150)、さらに濃い青マットRGB(8,25,65)。+5は明るい緑ベルトRGB(70,200,110)、濃い緑フレームRGB(20,100,55)、さらに濃い緑マットRGB(8,40,22)とする。Tredmill04〜05は+3、Tredmill02〜03は+5を使用し、側面・支柱・上部横梁・操作パネル周辺を含むフレーム全体へFrameColorを適用する。

各2台の既存マット外周からRuntimeで共用マットを1Partずつ生成する。横幅28、前後24、厚さ0.2stud。元の4枚はRuntime中だけ非表示にして物理設定を保持し、新しい2枚は表示専用（Collision / Touch / Queryなし）。Premium / Normalは対象外。色変更は次回Play初期化で反映。[共用マット検証](../reports/Treadmill_Group_Mats_20260916/build_report.md)。

既存の×3 Strength / ×5 Strength表示を維持する。最終加算量は従来どおりBaseGain、Dumbbell / Aura / Protein、Rebirth、Treadmill Multiplier、Belt / Training Potion、Strength Potion、VIPから計算する。今回Multiplier、TrainingInterval、利用条件、Collision、Level、Rebirth、Balance、DataStoreは変更しない。[初回色分け報告](../reports/Treadmill_Strength_Colors_20260916/build_report.md) / [2トーン調整報告](../reports/Treadmill_Frame_Colors_20260916/build_report.md)。

## 2026-09-16 — Configurable World1 Wall UI layout

World1 Stage1〜10の通常Wall .1〜.4は、`ReplicatedStorage.Config.WallDisplayConfig.WallUI`を共通表示設定の正本とする。初期値は`Scale=0.8`、`StageGap=0.4`。ScaleはStage表示、HP Gauge、HP数値と関連装飾へ一括適用し、StageGapはStageNumber下端とHP Gauge上端の見た目上の実隙間をstud単位で指定する。

UI寸法とGapはWall高さへ比例させない。Wall高さはSurfaceGui座標変換にだけ使用し、物理Wall高さ56.25stud、Wall HP、Current HP、Carry、Combat、Stage進行、Balance、Mapは維持する。Boss UIはBossDisplayConfig / BossDisplaySurfaceの独立経路を使用し、WallDisplayConfigを適用しない。[実装・検証報告](../reports/World1_Wall_Display_Config_20260916/build_report.md)。

## 2026-09-16 — Configurable Boss display surfaces

World1のBoss UIはClient専用の半透明BossDisplaySurfaceをRuntime生成して表示する。Stage1〜9は次Stage .1 Wall、Stage10はStage10BoundaryWallを基準とし、Mapの恒久配置は増やさない。Boss実Modelから生成時に測った高さでUI位置を決め、BossDisplayConfigで透明度・前方間隔・高さ比率・上下補正を調整できる。既存CombatStateの表示タイミングと実HP、NumberFormat、Combat / Carry / Balance / WorldComplete / Gateは維持する。[実装・検証報告](../reports/World1_Boss_Display_Surface_20260916/build_report.md)。

## 2026-09-16 — World1 Balance Config統合

World1 Stage1〜10の唯一のBalance正本は `ReplicatedStorage.Config.World1BossConfig`。RequiredStrength、RecommendedLevel、Boss MaxHP、Wall HPを集約し、`GetRequiredStrength` / `GetRecommendedLevel` / `GetMaxHP` / `GetWallConfig`で取得する。`Stage1WallManager.Config`は同じWall設定を参照する互換窓口で、別の数値表を持たない。

統合前の実Runtimeを維持した。Stage3〜5のRequiredStrengthは450 / 2,000 / 5,000。Stage1〜5のWall HPは固定値を保持し、Stage2は300 / 325 / 350 / 425。Stage6〜10はRequiredStrength×2 / 2.5 / 3 / 4、全Bossは×5。World2は専用Configのまま。

旧後半Configは3つのRuntime参照を移行し、Play一致確認後に削除した。Lottery・Combat・Carry・Stage進行は変更していない。検証範囲と証拠：[統合報告](../reports/World1_Config_Consolidation_20260916/build_report.md)。

## 2026-09-16 — World1 Wall UI scale / persistent HP

- 27stud Wall時の580x270 Canvasを基準に、Canvas高さをWall高さ×10へ変更。現在の通常WallはHPバー基準高さ5.13studとStage表示へScale=0.8を適用し、Stage表示はHP上端からStageGap=0.4stud上。物理Wall高さ56.25は維持。
- Wall .1〜.4は現在攻略対象になった瞬間からStage/実HPを表示し、撃破済み・未来Wallは非表示。
- WallClearedへ既存のCarry適用後Snapshotを添付し、一括反映。MaxHPによる仮表示を行わない。
- Boss解放直後はサーバーの実HPを表示。Boss Carryは既存どおり予約後、接触時Beginで適用する。UI側で先行消費・再計算しない。
- Stage1〜9のBossは次Stage .1壁面、Stage10は既存境界壁。個人表示、Combat / Carry / HP / Balance / Map / DataStoreは維持。
- 検証範囲と結果は[報告](../reports/World1_Wall_UI_Scale_20260916/build_report.md)を参照。

Version: 1.2 / 監査・更新日: 2026-09-15 / プロジェクト: Smash_and_Crush

## 対応画面方向（2026-09-16）

Smartphone / TabletはLandscapeを正式対応とし、`StarterGui`と実行時`PlayerGui`の双方へRobloxの`LandscapeSensor`を設定してLandscapeLeft / LandscapeRightへ追従する。Portraitでのゲームプレイは対応対象外。移動入力と入力範囲はRoblox標準Dynamic Thumbstickを使用し、ゲーム独自のサイズClamp・Safe Area・UI回避は行わない。操作Zoneは他UIとの重なりを許容し、通常時はZone背景だけを非表示、指を置いた際の標準Thumbstick表示は維持する。Desktop操作は従来どおり。

## 適用と情報の優先順位

本書・[BALANCE_SPEC](BALANCE_SPEC.md)・[UI_SPEC](UI_SPEC.md)・[DEV_STATUS](DEV_STATUS.md)を今後の開発の正本とする。これは現在の実装を記録する初期版であり、暫定実装をすべて最終承認したという意味ではない。

初期整理の根拠は、(1) 現在のStudio実装、(2) プロジェクト内の最新レポート/CSV、(3) 明確に確定した設計、(4) 古い仕様・コメントの順。今後のユーザー最新指示はSPECに優先する。実装とSPECが食い違った場合は「仕様不一致・要確認」を残し、既存の片方を黙って書き換えない。

状態は **実装済み／暫定実装／未実装／将来予定／要確認** に分ける。「実装済み」は今回のソース・Object監査で存在と接続を確認した意味で、全機能のPlay合格を意味しない。今回Playを開始せず、ModuleScriptのrequire・DataStore読書き・Studio変更・Publishを行っていない。

証拠: [監査概要](../reports/Implementation_Audit_20260915/audit_summary.md)、[2026-09-15 World1後半Play報告](../reports/World1_Stage6_10_20260915/build_report.md)。既存のPlay結果と今回の静的監査結果は区別する。

## 名称・接続対象

| 項目 | 現在確認できる値 |
|---|---|
| プロジェクト名 | Smash_and_Crush |
| ユーザー指定の英語ゲーム名 | Train to Smash Everything |
| 接続Studioの表示名 | +1 スマッシュ&クラッシュ |
| PlaceId | 101572058398926 |
| プロジェクトルート | C:\Users\kouji\Smash_and_Crush |

英語名・Studio名・公開タイトルの統一は未確認（DEV_STATUS K01）。公開ページの名称やUniverseIdを推測して補完しない。別プロジェクトのHaisarino Churarino Blender成果物は今回のゲーム仕様の完成機能に含めない。

## コアループとソロ進行

LobbyでTrainingまたは歩行によってStrengthを増やす → 自分の現在StageのWall .1〜.4を壊す → Bossを倒す → 次Stageへ進む、または出現した黄色RewardPadを取得してWinを得てLobbyへ戻る → 装備購入・Merge・Rebirthで育成を続ける。

「ソロ進行」は同じサーバー内でもPlayerごとにHP・Stage・報酬状態を持つ方式。単一Player専用サーバーという意味ではない。Wall/Boss HP、Cleared、Skipped、戦闘判定、Reward所有はPlayerごと。Bossモデルと物理Colliderの一部はサーバー共有であり、完全に相互干渉がないと断定しない。多人数同時Boss戦・Gate表示は別途検証する（K12）。

根拠: [ServerScriptService.World.EnemyManager](../reports/Implementation_Audit_20260915/sources/ServerScriptService.World.EnemyManager.luau)、[ServerScriptService.World.Stage1WallManager](../reports/Implementation_Audit_20260915/sources/ServerScriptService.World.Stage1WallManager.luau)、[ServerScriptService.Services.TrophyRewardService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.TrophyRewardService.luau)。

## World / Map / Lobby

| 対象 | 状態 | 実装 |
|---|---|---|
| World1 | 実装済み | Workspace.GeneratedMap。TrainingArea、LobbyCorridorConnector、BattleCorridor、NextWorldArea |
| World1 Stage1〜10 | 実装済み | BattleCorridor.Stage01〜Stage10。各StageにWall .1〜.4、Boss区画 .5 |

World1の破壊対象Wall .1〜.4は全StageでSize `88 x 56.25 x 1.2`、底面Y=2、上端Y=58.25とし、各Stageの左右側面Wallと上端を揃える。高さ調整は敵Wallだけに適用し、側面Wall、Stage10BoundaryWall、Gate、CombatZoneには適用しない。
| World1 Map拡張 | 実装済み | 各Stage Floor幅90stud。全体配置は監査Object記録参照 |
| Lobby | 実装済み | GeneratedMap.TrainingArea。SpawnLocation、育成・購入UIへの導線 |
| Training機器 | 実装済み | Workspace.Treadmill.Tredmill01〜10。World2Map内の複製とは別 |
| World2Gate | 暫定実装 | Workspace.World2Gate。Lobby側の表示・装飾。配置属性はTemporary - BackWall preview |
| World2 Map | Grayboxのみ | Workspace.World2Map。SourceWorldId=1、WorldId=2、IntegrationStatus=AuthoringOnly |
| World2 HP Config | 設定実装済み | 2026-09-15にWorld2専用BalanceをWorld2Config.Stagesへ反映。Boss/Wall Configが参照。旧×25,000依存は除去。Combatは未接続。検証は[更新報告](../reports/World2_Balance_20260915/build_report.md) |
| World2移動・Combat・Stage進行 | 未実装 | StageProgressControllerはGeneratedMapだけを初期化。World2Mapに接続しない |
| World2 Enemy Asset | 未確定 | World2用Assetは今後選定 |
| World2育成・Inventory | 設計確定・未実装 | World2到達時にWorld2専用Inventoryを解放。World1 ItemもWorld2で装備可能で性能値は変えず、World2専用Itemの方を強く設計する |
| 以降のWorld | 将来用領域のみ | NextWorldAreaの存在はプレイ可能Worldの実装完了を意味しない |

StageWidth/StageLength属性やModel Pivotには古い配置情報が残る。配置変更時は実Floor/Spawn/ZoneのCFrameとSizeを監査する。属性を実寸の代わりに使わない（K05）。詳細: [Object監査](../reports/Implementation_Audit_20260915/scene_objects.json)。

### 2026-09-15追記：World1後半のBoss位置

Stage6〜10のEnemySpawnを既存位置から相対+Zへ4 / 3.5 / 3.25 / 6 / 1stud後退した。変更後Zは365.54001 / 463.13998 / 555.98993 / 636.83997 / 715.93994。X/Y/回転、Wall .4、Floor、RewardPad位置は維持。

EnemyManagerのStatic Boss表示倍率は、移動するRootではなく既存StageN.5.Floor中心を参照して算出する。Spawn後退に伴う自動縮小を防ぐためで、実Scale・DisplayHeight・Collider/CombatZone Sizeは変更前と一致する。実位置は引き続きEnemySpawnから生成する。

歩行での接近・戦闘開始/離脱/再接近/撃破、HP UI追従、Pad非干渉をPlay確認した。今回の目的は「Wall .4撃破後にBossが近すぎて見づらい状態を改善すること」であり、Wall .4手前の低いカメラからBoss全体を見せることは要件ではない。Spawn後退による間隔調整は完了扱いとする。詳細は[間隔レポート](../reports/World1_Stage6_10_Spacing_20260915/build_report.md)。Carry・Balance・World2は変更していない。

## Strength / Step / Training / Level

- Strengthはサーバーが保持する非負の数値。小数を保持する。表示のK/M短縮を内部値に使わない。
- Stepは現行実装では「地上歩行時間に応じた0.5秒tick」。一定移動距離ごとの歩数ではなく、独立した保存Step通貨・StepCount・Step Levelは確認されない。
- 歩行中、HumanoidがRunning/RunningNoPhysicsで入力方向または水平速度条件を満たすとStrengthを得る。Training中・戦闘中・Treadmill占有中には歩行分を付与しない。
- TreadmillのTrainingZoneに入ると、自動で使用条件を判定して0.5秒ごとにTraining。退出・死亡・機器消失で停止。固定席数の予約ロックは確認されず、Player単位のTraining状態を持つ。
- 歩行ではDumbbell加算なし。TrainingはDumbbell/Aura/Proteinを基礎値に加算し、Rebirth・Treadmill・Potion・VIPを計算する。正確な式はBALANCE_SPEC。
- **Strength＝現在の成長サイクルで保持する累積戦闘力**。Level Upで消費せず、Boss/Wallは引き続きこの値を使用する。生涯ランキング用TotalStrengthEarnedとは別。
- **LevelProgress＝現在Levelで獲得したStrength進捗**。現在Requirementを消費した後の余剰を保持する。
- **LevelRequirement＝現在Levelから次Levelへ上がるための必要獲得量**。LevelRequirementsのLv1〜200の全数値とLv201以降+250Mの暫定式は変更していない。
- 最終Strength獲得量をPlayerDataService.AddStrengthGainでStrengthとLevelProgressへ同時反映する。Progressが現在Requirement以上なら順に消費し、Carry・複数Level Upへ対応。Levelを累積Strengthから再計算しない。
- Lv1の既存Requirement=0は維持。新規Join・旧データ移行・RebirthではLevelを自動加算せず、最初の正の獲得で0を消費してLv2へ進む。上限Lv10,000ではLevelを止め、StrengthとProgressは保持する。
- 旧データは保存Levelがあればそれを維持。旧仕様でLevelが保存されていない場合のみ、変更していない旧Threshold検索で従来Levelを一度復元する。LevelProgress=0から開始し、その後は独立保存する。

根拠: [ServerScriptService.Systems.Controllers.TrainingController](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Systems.Controllers.TrainingController.luau)、[ServerScriptService.Services.TrainingManager](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.TrainingManager.luau)、[ServerScriptService.Services.StrengthManager](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.StrengthManager.luau)。

## Rebirth

実装済み。World1上限5回。次回に必要なLevelを満たすとRebirthCountを1増やし、Strength=0／Level=1／LevelProgress=0へ戻す。現在のControllerはStage進行・Win・所有装備・HighestUnlockedWorldをリセットしない。Rebirth6以降の数表は存在するが、現行World1の操作では到達不可。World2用のRebirth解放条件は未実装。

根拠: [ServerScriptService.Systems.Controllers.RebirthService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Systems.Controllers.RebirthService.luau)、[ReplicatedStorage.Config.RebirthConfig](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.RebirthConfig.luau)。

## Stage / Wall / Boss / Combat

実装済み。参加・通常Run開始はStage1。Skip開始は指定Stageから始まり、前StageはSkipped扱い。現在StageのWallを順番に進め、4枚突破後にBossを解放する。

Wallの攻撃力は攻撃時のStrength。Glove補正はWallには加えない。余剰は同Stageの次WallへCarryし、同一攻撃で複数枚を突破する場合がある。Wall4後の余剰はBossへもQueueされる。**Boss Carryは現在実装済みだが、今後維持するかは要検討**（K03）。

自動戦闘はPlayer前方のWallCombatTriggerとWall/CombatZoneの接触で開始。CombatTypeは実装上「Wall」または「MiniBoss」。Boss CombatZoneは戦闘開始判定、MiniBossColliderは物理衝突であり、役割を分ける。

World1の進行順は各Stage共通で`Wall .1 → .2 → .3 → .4 → MiniBoss → 次Stage`を維持する。Wall .4撃破時点で接触前からBossDisplaySurfaceとBoss Gauge一式を個人表示する。Stage1〜9は次Stage .1 Wall、Stage10は既存Stage10BoundaryWallのPlayer側0.5stud手前に専用面をRuntime生成する。UI中心はBossの実寸高さ×0.6＋上下補正をBoss底面から加算し、名前・Stage表示はHPの少し上へ配置する。Wall高さでUI位置を決めない。Boss撃破通知でSurfaceとGaugeを隠し、Stage1〜9では次Stage .1のStage表示と実Current / Max Wall HPを接触前から即表示する。Combat順序、進行条件、WorldComplete / Gate処理は変更しない。

Bossは戦闘開始時のStrength・Glove・RequiredStrength比率を固定する。比率1以上は通常ダメージ、1未満は抽選ルート。抽選と回数制限はBALANCE_SPEC。離脱時は現在戦闘を終了し、同じBossのHP・抽選結果は同Run内で保持する。Boss再生成やRunリセットとの境界はEnemyManager/BossCombatServiceに従う。

Boss撃破で個人のStageが進む。Stage10撃破でWorldComplete=true。敗北では死亡演出後にLobbyへ再SpawnしRunをリセットする。Stage6〜10のBoss差し替え、大型Collider、HP UIは実装済み。過去のシーサー用分岐や名前だけのコメントを現在のBoss仕様と混同しない。

根拠: [ServerScriptService.World.EnemyManager](../reports/Implementation_Audit_20260915/sources/ServerScriptService.World.EnemyManager.luau)、[ServerScriptService.World.BossCombatService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.World.BossCombatService.luau)、[ServerScriptService.World.StageManager](../reports/Implementation_Audit_20260915/sources/ServerScriptService.World.StageManager.luau)。

## RewardPad / Win / Item Drop

- Boss撃破時にWinを直接付与しない。本人用の黄色PadがBoss区画左側に出現する。
- Pad踏み込みをサーバーが所有者・Boss撃破済み・身体との実重なりで検証。取得ロックにより二重付与を防ぐ。
- 取得でStage別Win×有効DoubleWin倍率を加算し、全Padを消し、回復してLobbyへ戻りRunをStage1へリセットする。
- 途中StageのPadを取らず、次Stageへ進むことも可能。PadとBoss進行は独立している。
- Item DropはPadと別。各Player/Run/StageのBoss撃破につき1回の抽選。ITEMなら所有Inventoryへ付与し、本人へ結果通知。現在は20% ITEM／80% MISS。
- Winは非負整数。Pad以外にDaily/Time/Community/Packから獲得する。通常Item・Dumbbell・Aura・Speed・Stage Skipに消費する。
- TrophyRewardConfigに「Temporary World1 Play-debug」とあるため、現在のWin報酬表は実装済みの暫定値として扱う（K02）。

## World解放 / HighestUnlockedWorld / WorldComplete

| 状態 | 保存 | 更新条件 |
|---|---|---|
| CurrentStage / Cleared / Skipped / Wall・Boss HP | Run内のみ | 各Playerの進行 |
| WorldComplete | 永続保存しない | Stage10 Boss撃破でtrue、Run初期化でfalse |
| HighestUnlockedWorld | 永続保存する | 初期値1。**Stage10 RewardPad取得**で2へ上げる |
| GateのLocallyUnlocked | ローカル表示のみ | LocalPlayer.HighestUnlockedWorld>=2 |

Stage10 Boss撃破だけでHighestUnlockedWorldは上がらない。永続World2解放はStage10 RewardPad取得時にHighestUnlockedWorld=2とする現行仕様で確定。保存時はHighestUnlockedWorldを既存値とのmaxで保持する。CanAccessWorld(player,world)はサーバーの保存セッションを確認するが、Gate移動にはまだ接続されていない。

根拠: [ServerScriptService.Services.TrophyRewardService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.TrophyRewardService.luau) collect、[ServerScriptService.Services.PlayerDataService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.PlayerDataService.luau) UnlockWorld/CanAccessWorld、[StarterPlayer.StarterPlayerScripts.World.WorldGateClient](../reports/Implementation_Audit_20260915/sources/StarterPlayer.StarterPlayerScripts.World.WorldGateClient.luau)。

## Inventory / Merge

実装済みInventoryはDumbbells／Items／Merge／Aura／Speedの5タブ。通常ItemはProtein、Glove、TrainingBeltに各1装備枠。3属性×5Rare度×3種=45 Item定義。所有数は数量、装備には所有を検証する。Best Equipは各種類の最高Rarityを選び、同等の有効な現装備は維持する。

Inventoryの「！」は購入状態ではなく、タブ単位の未確認内容を示す。Dumbbells／Aura／Speedは新たに解放された内容、Itemsは新たに所有したItemが未確認のとき表示する。対象タブを一度開くと購入・Equipの有無にかかわらずタブ通知は確認済みとなり、その後に別の内容が解放・追加された場合だけ再表示する。親Inventoryの「！」は、いずれかの子タブに未確認内容がある間だけ表示する。

Dumbbellの購入可能Itemには個別のBuyボタン通知も表示する。これはタブ既読と分離し、対象BuyボタンがScrollingFrameの表示領域へ入った時点で購入せずに既読となる。タブを開いただけでは画面外Itemを既読にしない。既読ItemIdはInventoryNotificationSeen.DumbbellBuyへ保存し、再Joinで復活させない。購入可否はDumbbellServiceの購入処理と同じ検証結果を使い、所有済みItemへBuy通知を出さない。

Mergeは同一ItemId3個を消費して同種・同属性の次Rarity1個にする。LegendaryはMerge不可。Dumbbellは7種の購入・所有・装備を実装しているが、Mergeable=trueという定義だけでDumbbell Merge実装済みと判断しない。現行MergeServiceは通常Itemのみ（K07）。

Auraは同時に1つ、Speedは購入済み/Pass所有から最適なWalkSpeedを適用。金額・効果・装備状態の決定はサーバー。

根拠: [ServerScriptService.Services.ItemService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.ItemService.luau)、[ServerScriptService.Services.ItemMergeService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.ItemMergeService.luau)、[ServerScriptService.Services.DumbbellService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.DumbbellService.luau)、[StarterGui.StrengthGui.InventoryTabsClient](../reports/Implementation_Audit_20260915/sources/StarterGui.StrengthGui.InventoryTabsClient.luau)。

## World2 Inventory / Item 方針

World2到達時にWorld2専用Inventoryを解放する。World2専用Item群はWorld2のStrength帯に合わせて新規設計する。World1 ItemはWorld2でも装備可能で、World移動による性能値の弱体化は行わない。World2 Itemをより強く設計することで、World1 Itemは相対的に弱くなる。World1 InventoryとWorld2 InventoryのUI/データ構造の詳細は実装Phaseで確定する。

## Shop / Game Pass / Developer Product

- 実装済み: Starter Pack、Secret Pack、VIP、Premium Speed、World1 DoubleWin、Red Aura、通常ItemのRobux購入、Stage Skip。
- 商品IDと効果はBALANCE_SPEC。表示価格はMarketplace取得を優先し、ConfigのFallbackPriceを確定販売価格と呼ばない。
- Premium Treadmillは機器・倍率定義のみあり、専用PassId=0で利用不可。
- BUY WINの導線はあるがWinProductsが空。未確定IDを使ったWin販売は未実装。
- Game Pass所有はサーバー確認。StudioではGamePassEffectsEnabled=falseにより所有状態と効果適用を分離する。
- ProductionではStudio設定と分離し、StudioDebugConfig.ProductionCreatorUserIdsに明示した製作者だけをProductionCreatorGamePassEffectsEnabledで手動ON/OFFする。一般Playerは常に通常効果。所有表示とDeveloper Productは対象外。
- Developer Productは単一ProcessReceipt経路。Item購入は選択ItemのIntentとReceiptの永続管理を行い、未解決処理を重複付与しない。
- Secret PackはPaidRandomAllowed確認を持つ。権利確認や商品効果をクライアント表示から推測しない。

## Daily / Time / Community Reward / Potion

DailyはUTC日付で1日1段階、7段階の一度きり系列。欠席で連続日数を初日に戻す処理や、Day7後に循環する処理はない。VIPの日次Winは通常Day7完了後も別枠。

Time Rewardは累積オンライン時間とClaim状態を永続保存。最後の閾値2700秒まで蓄積し、日次リセットではない。受取順番号は定義されるが、Serviceの実条件は各閾値到達・未取得であり、前報酬の取得を必須にしていない。

Daily/TimeのItemRollにはMISS抽選がない。ただし受取時のCurrentStageによるRarity解放制限がかかる。過去最高到達Stage基準ではない（K08）。

通常Potionは取得時に即時発動し、同種は倍率ではなく残り時間を加算する。通常タイマーはセッション内。Shop PackのPotion期限はShopRewardsにUTC期限として保持するため同一扱いにしない。

Community RewardはGroupId 787332211への加入をサーバーで検証して一度だけ3 Win＋Item1個。今回、外部グループの実在や実課金の再検証はしていない。

## Data保存

根拠: [ServerScriptService.Services.PlayerDataService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Services.PlayerDataService.luau)、[ServerScriptService.Systems.Controllers.PlayerDataController](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Systems.Controllers.PlayerDataController.luau)、[ServerScriptService.Systems.Purchases.ReceiptService](../reports/Implementation_Audit_20260915/sources/ServerScriptService.Systems.Purchases.ReceiptService.luau)。

| Store | 本番 | Studio |
|---|---|---|
| プレイヤーデータ | PlayerData_v1 | PlayerData_v1_Studio |
| 累計Strengthランキング | TotalStrengthRanking_v1 | 同名＋_Studio |
| 日次Strengthランキング | DailyStrengthRanking_YYYY-MM-DD | 同名＋_Studio |
| 商品Receipt台帳 | DeveloperProductReceipts_v1 | セッション内メモリ |
| Item購入Intent | ItemPurchaseIntents_v1 | セッション内メモリ |

PlayerData keyはPlayer_<UserId>。主な保存項目はStrength、RebirthCount、Win、TotalStrengthEarned、DailyStrengthEarned、DailyDate、OwnedSpeeds、OwnedDumbbells/EquippedDumbbell、OwnedAuras/EquippedAura、OwnedItems/EquippedItems、InventoryNotificationSeen、TutorialCompleted、TimeRewards、DailyRewards、CommunityRewards、ShopRewards、HighestUnlockedWorld、ResetToken。Receipt/Mutationの再実行防止用メタデータも使用する。Level・LevelProgress・LevelProgressVersion=1を後方互換の追加項目として保存する。InventoryNotificationSeenはDumbbells／DumbbellBuy／Items／Aura／Speedごとの確認済みコンテンツIDを保持し、旧データで欠ける集合は空集合から開始する。既存Strength・Win・Rebirth・Inventory・World解放は維持し、CurrentStage/WorldCompleteは保存しない。

通常Autosaveは90秒、最大6並列。退出・Shutdown時の保存あり。UpdateAsync、Dirty世代、ResetToken、数量更新のPendingItemMutationを使用する。日次StrengthランキングはJST、Daily RewardとVIP DailyはUTC。今回は保存処理を実行せず、ソース監査だけを行った。

## 今後の変更

未確定・予定は[DEV_STATUS](DEV_STATUS.md)へ集約する。World2再計算、移動、Combat、Asset選定を今回の仕様書作成だけで承認済み実装タスクにしない。変更時は[AGENTS.md](../AGENTS.md)に従って範囲を限定し、関連SPECと検証根拠を更新する。

## 2026-09-15 — LevelProgress方式への移行

最新指示による実装変更。数値カーブ・戦闘バランス・UIデザインは維持。通常付与とTime Rewardの永続化に共通の純粋進行関数を使用し、Save中の獲得・Claim再試行・再Joinを検証した。初期監査とは別の作業記録：[実装・検証報告](../reports/Level_Progress_20260915/build_report.md)。
## 2026-09-15 — World2 Gate travel

- `HighestUnlockedWorld >= 2` のPlayerがWorld1 Lobbyの`World2Gate.WorldGateTrigger`へ入ると、Player専用の英語確認UIを表示する。
- YES時はClientが引数なしの`WorldTravelRequest`を送信し、Serverが解放状態・Gate内滞在・Character生存を再検証する。
- 移動先は固定座標ではなく`Workspace.World2Map.TrainingArea.World2LobbySpawn.CFrame`を使用する。同一Characterを`Model:PivotTo()`で移動し、`CurrentWorld=2`を設定する。
- NO後はTriggerから一度退出するまで再表示しない。World2 Combat、Stage進行、Reward、Return Gateは未接続。
## 2026-09-15 — World1 / World2 round-trip travel

- `Workspace.World2Map.TrainingArea.World1ReturnGate`から、共通の確認UIを経由してWorld1 Lobbyへ帰還できる。
- Serverは許可済みAction、`CurrentWorld==2`、Return Gate内滞在、Character生存を検証し、`Workspace.GeneratedMap.TrainingArea.SpawnLocation`へ同一Characterを移動する。
- World1→World2は解放確認を維持し、World2→World1は自由帰還。成功時に`CurrentWorld`を2/1へ切り替える。Stage進行と永続データは変更しない。
## 2026-09-16 — World1 cumulative Strength progression rebalance

Lv1〜50のLevelRequirementsを新しい累積Strengthカーブへ更新した。各値はそのLevelから次Levelへ進むためのStrength獲得量として扱う。Strength自体は累積戦闘Strengthとして維持し、Lv51以降・World2・Level進行ロジックは変更していない。

World1 Stage6〜10はRecommendedLevel到達時の理論累積StrengthをRequiredStrengthへ反映し、Stage5→6の大きな難易度上昇を意図的に維持する。
## 2026-09-16 — Lv1 requirement floor adjustment

Lv1〜50のRequirementを各10 Strengthずつ増加した。Lv1→Lv2にも10 Strengthが必要になり、初回Strength獲得時の即時Level Upを防ぐ。Lv51以降、LevelProgress仕様、戦闘・World2仕様は変更していない。
