# Pet Stage2 gate / camera verification — 2026-11-14

対象: 副本 PlaceId **126576845524886**。実際のStudio Edit Source・EditorSourceを確認して変更し、隔離Playを2回実行した。正本101572058398926、Save/Publish、PR #1は操作していない。

## 変更したFull Path

| Full Path | 変更 |
|---|---|
| ReplicatedStorage.Modules.EggPetTutorialState | 既存Version1レコードへWorld1Stage2Defeatedを追加。欠落はfalse。撃破情報だけをORで統合 |
| ReplicatedStorage.Modules.EggPetTutorialGuide | EggTutorialStage2Defeatedを初回Egg/Pet案内固有の追加条件にする |
| ServerScriptService.World.EnemyManager | World1の実撃破確定defeat(player,2)でだけ新しいサーバーAPIを呼ぶ |
| ServerScriptService.Services.PlayerDataService | 撃破記録、通常保存・Pet取引との統合、既存所有権/ロック/再試行による保存 |
| StarterPlayer.StarterPlayerScripts.World.SpawnFacingCameraClient | 成長連動zoom/min/max/CameraOffsetとSpawnFacing強制回転を撤去。死亡演出・追従復帰を保持 |

変更前の上記5 Sourceは当時のorigin/mainと一致し、既存の未保存編集を上書きする差異はなかった。
FirstBattleTutorialState、PetMergeTutorialGuide/Stateは変更していない。終了時に8 SourceとEditorSourceの一致、補助ゼロを再確認した。カメラ設定18～30も保持。

## 原因と保存項目

- TutorialCompletedはWorld1 Stage2への最初の受理ダメージで立ち、撃破の証拠にならない。CurrentStageはスキップ・帰還で変わる。既存のStage2撃破分析値はセッション限定だった。
- 保存先は既存プロフィール内の **EggPetTutorial.World1Stage2Defeated: boolean**。新規・旧項目欠落ともfalse。過去撃破の推定付与はしない。Eligible / Completed / Acquired / PurchaseId / CompletionIdを保持する。
- 実撃破時にliveへ記録し、既存WaitForSave/Save/ownedUpdateを使用して最大3回の保存を試す。未確認分は既存Dirty・自動保存・退出保存へ残す。新しいDataStore・クライアント要求remoteは作っていない。
- 通常保存は既存の保存済みPet進捗を維持して撃破flagのみOR。Pet購入・装備は開始時のflagを取引に統合し、yield中の撃破も取引終了時にliveへORして巻き戻りを防ぐ。既存取引ID・重複拒否・所有権を使用する。
- 再生はflagを消さない。既存の明示的な管理用プロフィールResetは全進捗リセットという元の意味を維持する。
- 共有AllowLaterGuidesは無変更。手動購入・装備にもStage2条件は追加していない。

## Studioで実際に試した内容

既存tests/FirstBattleTutorial/InstallIsolation.luauを今回専用名で使用。39 SourceのDataStore/Marketplace/Badge/Messaging/Policy参照を一時的なメモリ実装へ置換した。本番保存・実課金を使っていない。実ゲームScript/LocalScriptから同じrequireキャッシュで測定した。戦闘到達、資金、Strength、解放済み条件の一部は隔離fixtureで準備しているため、自然な通しプレイの所要時間を示すものではない。

| 検証 | 結果 |
|---|---|
| Stage2未撃破・実Win StageSkip | Stage2.1へ進入してもflag=false、案内WaitingForStage2Victory |
| World1 Stage2へ非致死ダメージ | Boss HP1795、TutorialCompleted=trueでも新flag=false |
| World1 Stage2実撃破 | TryManualAttack→既存撃破経路でDefeated=true、新flag=true。Win=0 |
| 撃破直後の戦闘区域 | WaitingForLobby。即案内なし |
| 実Back帰還、Win不足→充足 | flag保持。WaitingForWin→既存先行ガイド終了後GoToEgg |
| 先行ガイド調整 | OreがGoToMerge中はEggがWaitingForGuide。準備済み先行条件が完了するとEggが取得 |
| World2 Stage2実撃破 | 最終試行でDefeated=true、Gauge=0、新flag=false |
| 初戦→Ore | World1 Stage1実撃破、FirstOutcome=Victory、実Back後Ore=GoToMerge。Stage2待ちで止まらない |
| 撃破前の手動Basic購入→BestEquip | 両方成功。flag=falseでも既存由来を持つPetでCompleted=true |
| 早期完了→撃破記録→保存/再読込 | CompletedとPurchaseId/CompletionId保持、案内Complete。再購入不要 |
| 保存中に撃破記録 | 購入UpdateAsyncをholdし、途中で記録。購入済み・未装備の進捗とflagが双方live/保存先に残る |
| flag記録後の装備・通常保存 | 完了・購入由来・flagを保持 |
| 保存前失敗2回 | 既存再試行でflag保存。保留worker終了 |
| commit後応答消失 | 再試行AlreadyApplied。Winは1回分のみ消費、flag保持 |
| 旧レコードのflag欠落 | 完了済み・購入由来を保持しfalseへ正規化。TutorialCompleted=trueから推定しない |
| セッション再取得 | Release/Loadによる所有権の取り直し・保存済みflag復元を確認 |

### カメラ

旧syncScaleはBodyに応じて距離・範囲・Offsetを上書きし、alignHeadingが帰還時等の向きへ回転させていた。これらを削除した。
死亡時だけ既存Scriptable固定・DeathGuiを使い、復帰後は新Humanoid/Customへ戻す。直前の**公称zoom距離と回転**を新しいsubject位置へ移し、旧地点の絶対CFrameは復元しない。

追加の実測で、標準モバイルFollowCameraもワープを旧地点からの歩行と解釈して回転することが判明。最終版はサーバー配置中（root.AnchoredまたはSpawnPlacementRevisionの新targetへ到着）だけ標準controllerの古い移動履歴を消す。入力・通常追従・障害物処理・配置/帰還ackは標準経路のまま。PlayerModule自体は変更していない。

| 操作 | 実測 |
|---|---|
| PC相当のホイール | 公称距離18↔30へ手動変更できた |
| 角度の手動入力 | 標準の右矢印入力でyaw 1.2343→-0.7900 radへ変更。比較用の別角度は一回限りのfixtureでも設定 |
| 再生 | 実TryRebirth成功、LV32→1/scale1.8→1。距離28、pitch-0.5585/yaw1.1345維持 |
| LVUP | 実AddStrengthGainでLV1→36/scale1→1.8。距離18、上記角度維持 |
| SIZE3→AUTO | 実ChangeSelectedSize成功。距離18・角度・min18/max30・Offset0維持 |
| 最終版iPhone17 Pro相当、StageSkip→Back | 実経路成功。距離29、pitch-0.45/yaw3.14116維持 |
| 最終版iPhone17 Pro相当、World1→2 | 実WorldTravelRequest成功。距離29、pitch-0.45/yaw1.234263維持 |
| 最終版iPhone17 Pro相当、Trophy帰還 | 実接触でWorld2 Stage2報酬1回/7000Win、帰還。距離29、pitch-0.45/yaw-0.8維持 |
| PC相当死亡復帰 | 距離18、pitch-0.5585/yaw1.1345維持、新Humanoid/Custom、生存100 |
| 最終版iPhone相当死亡復帰 | DeathGui有効/Scriptable→新Humanoid/Custom、DeathGui無効、距離29/pitch-0.45/yaw-0.8維持 |

iPhone17 ProはTouchEnabled=true、749×381、LandscapeSensor。元のエミュレータgeneric_handheld_720へ最後に戻した。
Worldゲート付近では障害物により実距離26.51、公称29となり、離れると実距離29へ戻った。これを強制zoomと混同していない。足元の接触補正や標準Followの通常移動による小角度変化も比較から区別した。
HatchClient、StudioBossAnimationPreview、WorldGateClientの他Camera書込みは専用Viewportカメラで、ゲームCameraの強制設定ではない。

## コードから確認した内容・未確認

- 本人専用Boss/既存defeat(player,stage)/worldId==1の経路に限定。**今回2人の実クライアントでの他人撃破試験は未実施**。
- 再参加はメモリ保存でRelease/Loadまで。実ネットワーク切断・別サーバー再参加、本番DataStore障害/サーバークラッシュ耐性は未確認。
- PetマージはWaitingForPets時の併存と共有Coordinator無変更を確認。両ガイドが同時に対象となるPetマージ実操作は未確認。
- PCの右ドラッグ、モバイルの指ドラッグ/ピンチはMCP入力で有効な回転変化を作れず、**手動タッチ操作の合格とはしていない**。標準入力処理は維持し、モバイルFollowでの各帰還・死亡復帰は実測した。実端末操作が残る。
- 一部準備失敗（World2切替直後の初期化競合等）は再準備して実経路成功を確認。成功結果を上表に記載し、全試行ログはevidence.jsonに残した。
- 外観、最大Body WinTrophy、HP/Strength加算/LV必要量/報酬/戦闘判定の製品仕様は変更していない。

## 終了状態

自分が開始した2回のPlayだけを終了。39 Source差し替えを一致確認して復元し、検証補助は全除去。副本は**未保存Edit**。
Workspace.StarterCharacter、Workspace.BodyPrototype_20261114、ServerStorage.BodyPrototype_20261114は保持。
今回5 Source、仕様追記、検証記録だけを通常commitしてorigin/mainへpushする。公開適用は行わない。
