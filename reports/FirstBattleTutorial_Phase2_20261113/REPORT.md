# Phase 2：初回戦闘 → マージ・装備 → 再挑戦

作業日：2026-11-13。対象Place **126576845524886** / Universe **10765181857**。基準commit **bc79c97732c7f7951157286be9706ea13b541513**（Phase 1）。GitHub：koujiyoshimura54-crypto/Smash_and_Crush、main。最新依頼を旧Place ID・過去SPECより優先した。

実装と隔離Play検証を完了。正本Studioへ必要箇所を反映した未保存Editで保持し、Save/Publishは実施していない。PR #1はマージしていない。初戦の勝敗は通常戦闘に従い、強制敗北・HP偽装・自動難易度調整は追加していない。**継続率改善は未検証の仮説**。

## 保存事実と案内

新プロフィールの所有権取得トランザクションが、通常OwnedOresのORE_001×2とFirstBattleTutorial（Version1 / Eligible=true）を同時に保存してからLoadedを公開する。BattleBagには入れない。取得応答の消失や初回通常保存前のマージでも、取得済みプロフィールとForgeジャーナルを再利用する。

| 確認済みの事実 | 次の案内 |
|---|---|
| 新対象・初戦未経験、LV<2 | 既存Normal Treadmill |
| 初戦未経験、LV>=2 | 壁1枚 → 実Stage1.5のBoss |
| 初戦前に自主的にショップを開く | その場でOreマージ・最良装備。閉じただけでは完了しない |
| 自主マージ・装備後、初戦未経験 | LV2未満なら鍛錬、以上なら壁／Boss。初戦済みにはしない |
| 本人のStage1 Bossとの実戦Death / Victory / 受理済みBack | 次のLobbyで未完了マージ・装備を案内 |
| 勝利後Stage2へ進行中 | ショップを強制表示せず、次のLobbyで再評価 |
| マージ・装備済み、未撃破、LV<4 | 再鍛錬 → LV>=4で再戦 |
| 同上、すでにLV>=4 | 再鍛錬を省略し再戦 |
| Stage1撃破・マージ・装備済み | 新導線完了。後続ガイドが通常条件で再開 |
| LV4以降でも敗北 | マージ・装備を保持。再マージや自動HP変更なし |

FirstBattleTutorialにBattleStarted、FirstOutcome（Death / Back / Victory）、Stage1Defeatedを保持する。FirstOutcomeは初回結果、Stage1Defeatedは後日の勝利も保持する単調な事実。既存OreMergeTutorial.CompletedとEquipmentTutorial.DumbbellCompletedを再利用し、新たな重複完了フラグは保存しない。DumbbellEquipTutorialInitialCompletedは既存初回装備完了の複製Attributeであり、上位装備案内の表示用完了とは区別する。

Boss開始は本人所有の実BossとのサーバーCombatType=MiniBossから記録する。本人が攻撃する前にBossに倒されるケースも対象。死亡は同じCharacter / 戦闘状態 / Run / ResetTokenを検証し、Backは受付前の証拠と実際の帰還成功を照合する。戦闘前の落下・リセット・帰還や退出だけでは初戦結果を作らない。事実は既存所有権付きSaveへ即時予約し、失敗時に再試行・既存autosave/退出保存へ引き継ぐ。クラウド全障害時の永久保証を追加したものではない。

旧プロフィールに新フィールドがない場合はEligible=false。旧OwnedOresを保持し、Stone再配布・新しいマージ必須状態・売却制限を適用しない。読込エラーは未ロードのままで新規扱いしない。明示された既存の全チュートリアル／プロフィールリセットは新規状態へ戻るが、通常の再参加・死亡・帰還・World移動は初期付与を繰り返さない。

TutorialCompletedは既存のStage1 Trophy、およびStage2有効攻撃時のフォールバックの意味を維持し、Ore/装備ガイドを早めるためには変更しない。新導線中はPet・PetMerge・上位Ore・Item装備の別案内を待機し、既存Coordinatorで表示を一つにする。読込、メニュー、通知、帰還等の一時抑止後は既存更新周期で再評価する。

## Stone売却と時間報酬

新対象は初回の正規Oreマージが保存確定するまでStoneを売却できない。UIのStoneカードにLockedを表示し、既存status行で理由を示す。サーバーは保護Stoneを含む単体・一括・混合要求全体を、数量・Win・ジャーナルを変更せず拒否する。ほかの鉱石の売却は維持。マージの応答が不明な間はローカル制限を維持し、確定済み保存を再取得した後に解除する。ショップを開く／選択／ボタンを押すだけで解除せず、Stone補充も行わない。

マージの最大5個、素材・抽選・生成性能、既存Forgeのトークン／Sequence／ジャーナル／所有権制御は維持する。通常Saveは保存済みForge更新を巻き戻さない。

初回時間報酬は60秒のままWin×1（IntroWin02）。残り8枠は変更なし。旧IDはGit履歴 **0188223のReward01（初回Win）**、**912d51cのStoneIntro01** を確認した。三つのIDを同一初回枠として判定し、旧キー自体も保存する。受理済み報酬内容をコピーして再試行し、保存途中の旧Stone報酬をWinへすり替えない。旧受取報酬の回収・一律補償はなし。

## Stage1のHP・構造

| 対象 | 変更前 | 変更後 |
|---|---:|---:|
| 壁1 | 50 | 50（位置維持） |
| 壁2 | 75 | 除去 |
| 壁3 | 100 | 除去 |
| 壁4 | 135 | 除去 |
| 壁合計 | 360 | 50 |
| Boss | 200 | 200 |
| Boss込み | 560 | 250 |

削除は次のPartとその子（SurfaceGui等）だけ。空の区画Model、床、通路、Boss床、報酬設備、Stage2境界は残す。

- Workspace.GeneratedMap.BattleCorridor.Stage01.Stage1.2.Wall
- Workspace.GeneratedMap.BattleCorridor.Stage01.Stage1.3.Wall
- Workspace.GeneratedMap.BattleCorridor.Stage01.Stage1.4.Wall

残すStage1.1.Wallの中心は約(287.800,15.688,97.000)、Size約(89.200,23.375,1.200)。Bossは実構造のStage1.5.EnemySpawn、約(287.800,4.500,198.900)を維持した。壁数からBoss Model名を再生成しない。

最終照合ではStage01のBasePartが47→44、削除3壁以外の44 PartはCFrame / Size / CanCollide / CanTouch / CanQuery / Transparency一致。床矢印、HP表示、攻撃対象、死亡復活、Back解放は受信壁数・実物を参照。壁の余剰ダメージをBossへ移す処理は追加していない。Stage2以降・World2、全Boss HP、推奨LV、Strength獲得量、LV曲線、再生条件は維持した。

GitにはSourceと、今回Studioへ適用した[限定壁削除ツール](../../tools/ApplyStage1SingleWall.luau)を記録。Placeファイル保存・Publishを行っていないため、Git pushだけで公開Placeのジオメトリが更新されるわけではない。

## 変更Full Path

| Full Path | 変更 |
|---|---|
| `ReplicatedStorage.Config.TimeRewardConfig` | 初回60秒Win×1、確認済み旧IDの同一枠判定 |
| `ReplicatedStorage.Config.World1BossConfig` | Stage1 Walls={50}、初回案内LV>=2 |
| `ReplicatedStorage.Modules.EggPetTutorialGuide` | 新導線中の待機と終了後の再開 |
| `ReplicatedStorage.Modules.EquipmentTutorialGuide` | Ore保存後はTutorialCompleted前も装備案内、Item案内の待機 |
| `ReplicatedStorage.Modules.EquipmentTutorialState` | 初回Dumbbell装備完了を上位案内と独立して複製 |
| `ReplicatedStorage.Modules.ForgeInventory` | 保護Stoneを含む売却要求全体の拒否 |
| `ReplicatedStorage.Modules.MergeShopView` | StoneのLocked表示・数量操作・売却送信の制限 |
| `ReplicatedStorage.Modules.OreMergeTutorialGuide` | 初戦後／自主ショップからの初回案内、上位案内待機 |
| `ReplicatedStorage.Modules.PetMergeTutorialGuide` | 新導線中の待機と終了後の再開 |
| `ReplicatedStorage.Modules.Stage1WallPromptState` | 受信WallCountに基づく本人の現在壁判定 |
| `ServerScriptService.Services.ForgeService` | StoneSellLockedを既存Stateへ追加 |
| `ServerScriptService.Services.PlayerDataService` | 初期Stoneと対象識別、保存事実、単調保存、報酬履歴互換と受理内容固定 |
| `ServerScriptService.Services.RunReturnService` | Boss戦の証拠を帰還受付前に取得・再確認し、実Lobby配置後にBack記録 |
| `ServerScriptService.Services.TimeRewardService` | 旧受取履歴を含む表示・請求判定 |
| `ServerScriptService.World.EnemyManager` | 既存戦闘開始・死亡・撃破・初期化へ事実通知だけ追加 |
| `StarterGui.StrengthGui.RunReturnClient` | 壁4枚固定のBoss解放判定をWallCountへ変更 |
| `StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient` | 事実から案内を選択、壁1枚と実Boss区画Stage1.5を独立参照 |
| `ReplicatedStorage.Modules.FirstBattleTutorialState` | 新規：保存事実の正規化・単調統合・案内選択・後続ガイド優先度 |
| `ServerScriptService.Services.FirstBattleTutorialService` | 新規：本人・Character・Run・Worldの戦闘／帰還証拠を検証 |

Phase 1のReplicatedStorage.Config.Stage1WallPromptConfig、ReplicatedStorage.Modules.Stage1WallPrompt本体、TutorialPresentationCoordinator、CombatClientは原文一致を確認した。画像は **rbxassetid://85558189403057**、設定箇所はStage1WallPromptConfig。画像を変更・再生成していない。

表示はWorld1 Stage1の壁案内中、受信済みの本人の未破壊壁、既存処理の攻撃可能状態、生存、AutoTap明示OFFを条件にする。メニュー／購入／死亡／移動／他ガイド中や画面外では隠す。文字は現在入力のClick/Tap一語。画像・文字・親GUIから攻撃を送信せず、既存手動入力を吸収しない。本人の対象壁へのサーバー確認済み有効手動攻撃でセッション中の促しを完了し、死亡で完了を消さない。既存リセットには追従する。

## 検証方法と結果

本番プロフィールを変更せず、現在のEditから開始した**検証専用Playのデータ・購入・Badge・Messaging等をメモリ実装へ隔離**した。検証用のプロフィール初期化、位置準備、強制LV設定を使ったケースは下表の「準備あり」。自然計測にはそれらを使わない。保存切断はセッションRelease/Loadと遅延・失敗注入による模擬であり、実ネットワーク切断や公開DataStore試験ではない。

| 必須ケース | 実施・結果 | 検証区分 |
|---|---|---|
| 1. LV2→壁1枚→初戦敗北→帰還→マージ・装備→LV4→再戦 | 通過。初戦LV2/Strength6、再戦LV4/Strength46で勝利 | 自然獲得の実Play・自動操作 |
| 2. 先にLV4→初戦勝利→帰還→マージ | 通過。Strength40で勝利、再鍛錬・再撃破なし | 自然獲得の実Play・自動操作 |
| 3. 初戦前自主マージ | 実UIで開く→閉じる（未完了）→再入店→2個選択→Merge。保存後Best EquipでPhase=Train、BattleStarted=false / TutorialCompleted=false | 実PlayのUI操作。途中に隔離保存試験と同プロフィール復元を挟んだため自然時間には含めない |
| 4. Boss Backと戦闘前帰還 | 本人Boss接触後・本人攻撃0のBackはBackとして記録。Boss接触前の死亡復帰は結果なし。戦闘前Backは状態判定で拒否することも確認 | 準備あり実Play＋状態テスト。全帰還手段の自然操作網羅ではない |
| 5. 勝利→Stage2→後で帰還 | 正規Bossダメージで勝利後、Stage2接触中はショップ非表示・促し非表示。既存Back成功後Phase=Merge。撃破事実はRelease/Load後も保持 | 準備あり実Play（LV・位置準備） |
| 6. 売却禁止・解禁 | UI Locked、Stoneカード/数量操作無効、直接要求・単体/全数/混合拒否で数量/Win不変。ほかのOre売却可、マージ確定後Stone売却可 | 実UI＋ネイティブ保存サービス |
| 7. 時間報酬 | 59秒不可・60秒Win1、両旧履歴、応答消失、受理内容の変更防止、旧Stone保存途中の設定変更で二重受取なし | 時刻準備＋メモリ保存故障注入 |
| 8. 初期付与直後・保存中の退出/連打 | 初回通常Save前のマージとRelease/Load、失敗前/後、書込保留中の連打・所有権交代で二重消費/生成・Stone復活なし | ネイティブサービス／切断模擬 |
| 9. 敗北・装備・再鍛錬中の再参加 | Death、Ore確定、装備完了、LV4再戦待ちの事実を保存再取得して保持 | メモリ保存・セッション再取得。実機退出再参加ではない |
| 10. 強い装備・LV超過・再敗北 | NORMAL_02装備は初回生成品への持替え不要。LV>=判定、1加算で超過、LV4準備で本人攻撃0のBoss死亡を2回繰り返してもOre/装備を保持しPhase=Battle | 自然LV超過＋準備あり実Play＋保存テスト |
| 11. 壁復活・Boss解放・指促し | 壁1枚50で再初期化、破壊後Boss解放。手動未完了死亡→復帰再表示、完了後死亡→復帰非表示。指画像上のmouse/touch各1要求・1有効HP減少 | 描画あり実Play／死亡準備。再読込はクライアントdetach/reparent模擬 |
| 12. 既存・Stage2・World2・後続ガイド | 旧プロフィールは再配布/新制限なし。Stage2壁4枚の設定維持、Stage2/World2で促しなし。旧完了者および新導線完了後の後続ガイド許可、進行中の抑止を確認 | 保存テスト・実Play属性準備・状態判定。World2全戦闘の再走破なし |

[保存結果](save-checks.json)：**14ケース / 120項目成功**。本番Moduleのネイティブ実行を使い、DataStore応答だけをメモリへ置換した。初期取得、Forge保存、通常Save、報酬保存の整合を検証している。

ローカル `python tests/run_first_battle.py`：**82進行判定 + 53壁促し判定成功**、変更Sourceと検証Luauの構文検査成功。実機確認をこれらで代用していない。

### 端末・入力

PC1390×601はClick、phone simulator667×375とtablet simulator1376×1032はTap。指画像Loaded=trueで描画し、壁HP・キャラクター・左右メニュー・移動スティック・Jumpを大きく隠さない配置を目視した。指サイズはphone約77px、tablet約110px。いずれも同じ画像とアニメーション。

PCの画像クリックは要求38→39・壁HP50→45、phoneの画像タップは要求39→40・HP45→40で、各1回の有効攻撃・促し完了。Auto ONの自動攻撃では促し完了せず、OFFで未完了なら再表示した。実ツールのスティックdrag／カメラdragでは要求数・完了が増えず、メニュー開閉・壁から離れる・クライアント対象detach/reparentでも条件どおり抑止／復帰し、GUI数1を維持した。

新しいStone Locked表示と既存5スロットもphone/tablet相当で目視。phoneの補足statusは小さく、Lockedカード表示が主要な拒否表示になる。既存の「Boss Anim Preview (Studio)」表示がphoneのショップ上部と重なる場面は対象外の既存編集として保持した。物理的な指での操作、ノッチを含む全機種の可読性は未確認。スクリーンショットは検査のみで保存・commitしていない。

### 描画停止とRuntime

初期の隔離PlayではRenderStepped=0、Viewport=1×1で、サーバー・Heartbeat・物理は進行したが描画確認できず、画面取得／入力ツールが待機することがあった。後で描画フレームが再開し、上記の死亡復帰・入力・端末表示を実際に確認できた。再開時に促しコードの修正はしていない。原因は未確定で、ガイド不具合とは断定しない。

自然ルートのconsoleと最終検証Playで、今回の製品変更に由来するRuntime Error / Infinite Yieldは見つからなかった。既存の別asset **89137136456777 / 119910397965139** にRequester permission Warningが出た試行がある。指定指画像85558189403057は描画を確認した。BadgeAward失敗は隔離BadgeServiceが付与しないため。保存故障注入のWarningは期待したもの。検証操作の一部に「HatchGui取得後すでに破棄」「Reload直後Boss未生成」の補助エラーがあり、生成・破棄タイミングを待って該当確認をやり直した。これらを製品Runtimeの成功判定へ混同していない。

## 通常獲得による実測

時計は検証ObserverがPlayerAddedを受けた参加時から。操作可能はLoaded / Character生存 / LobbySpawnPlaced / 非Anchoredを満たして通常操作を開始した観測。LVは実獲得のAttribute、Boss開始は既存CombatState、保存確定はサーバーのOreTutorialCompleted公開、その他は既存操作後のclient観測を使う。

Humanoid.MoveToで歩き、既存Normal01 Treadmillで鍛えた。AutoTapはOFF。戦闘成立中に既存Tap要求を0.25秒間隔で送信し、既存サーバー受付間隔に従う。通常Forge経路でStone2をマージし、既存Hatchクリック処理とBest Equipを実行した。強制LV/Strength/勝敗、Warp、時間報酬待ちや取得は使っていない。装備抽選結果とTreadmill退出時の追加tickで測定間の差が出る。人間の読解・迷い・実機応答を含む所要時間ではない。

### 初戦敗北→再戦勝利

| 観測 | 参加から秒 | 前行から秒 | LV / Strength |
|---|---:|---:|---|
| 操作可能 | 3.950 | 3.950 | 1 / 0 |
| LV2到達 | 9.619 | 5.669 | 2 / 5 |
| 壁破壊 | 18.103 | 8.483 | 2 / 6 |
| 初戦Boss開始 | 20.234 | 2.131 | 2 / 6 |
| 初戦結果（敗北） | 24.220 | 3.985 | 2 / 6 |
| Lobby帰還 | 28.151 | 3.932 | 2 / 6 |
| マージ保存確定 | 30.617 | 2.466 | 2 / 6 |
| ダンベル装備 | 34.211 | 3.594 | 2 / 6 |
| LV4到達 | 43.218 | 9.007 | 4 / 42 |
| 再戦Boss開始 | 52.283 | 9.065 | 4 / 46 |
| 再戦撃破 | 53.399 | 1.116 | 4 / 46 |
| 再戦後Lobby帰還 | 54.365 | 0.966 | 4 / 46 |

### LV4初戦勝利

| 観測 | 参加から秒 | 前行から秒 | LV / Strength |
|---|---:|---:|---|
| 操作可能 | 4.117 | 4.117 | 1 / 0 |
| LV2到達 | 9.815 | 5.697 | 2 / 5 |
| LV4到達 | 27.682 | 17.867 | 4 / 40 |
| 壁破壊 | 34.270 | 6.588 | 4 / 40 |
| 初戦Boss開始 | 36.446 | 2.177 | 4 / 40 |
| 初戦結果（勝利） | 37.664 | 1.217 | 4 / 40 |
| Lobby帰還 | 38.598 | 0.935 | 4 / 40 |
| マージ保存確定 | 41.047 | 2.448 | 4 / 40 |
| ダンベル装備 | 44.660 | 3.614 | 4 / 40 |


敗北ルート生成品はNORMAL_02（+3）。LV4到達時Strength42、Treadmill退出tick後46。勝利ルートは初戦前未装備でStrength40。勝利後マージ品は[保存ログ](natural-win.json)の装備欄を参照。再戦開始・撃破は勝利ルートには不要で未実施。

[敗北ルートの時系列](natural-loss.json)、[勝利ルートの時系列](natural-win.json)。参加からの完了は各54.365秒、44.660秒。これらの値に合わせてHP・獲得量・LV曲線を追加調整していない。

## 既存ファネルと比較上の注意

自然ルート双方でMTF_FirstCombat_v1のstep3 ClearedFirstWall → step4 ClearedStage1Wallsが同じ壁破壊でこの順に各1回。死亡・再戦でも重複なし。ファネル名・順序・対象者・意味・既存PlaceVersionを変更していない。FirstPlayAnalyticsService / Configの原文一致も確認。

初期StoneでOre Eligibleが新規プロフィール取得直後に早まるため、変更前後の率を単純比較できない。未観測イベントは補完しない。自動計測の直接Forge要求は既存の検証済み選択UIイベントを通らないため、OreRequestWithoutValidatedView等の実観測をそのまま残した。Creator Hub到達は未確認。新ファネル追加は今回実施しておらず、必要なら別提案とする。

## 最終照合と残る範囲

[final-audit.json](final-audit.json)：38関連SourceとScriptEditor内容を照合し、19変更・19維持、すべて期待値と一致。Phase1画像設定と本体を保持。検証用40 Source差し替えをexact Beforeへ戻し、7補助オブジェクト、メモリModule、backupを除去。名前に__FirstBattleを含む検証オブジェクトは0、端末シミュレータはdefault、StudioはEdit。

関連SPEC / DEV_STATUS / CHANGELOG / analytics解釈記録を更新。今回のSource・限定壁削除ツール・テスト・この報告だけをcommit対象とする。既存の未追跡 `reports/Visual_Templates_Secret_VIP_Green_20260917.md` は保持し、今回のcommitへ含めない。

未確認は実機操作、自然なネットワークstreaming、実ネットワーク切断・公開DataStoreへの保存、公開後のCreator Hub計測・継続率、全Worldの網羅回帰。描画停止の原因は未確定。公開反映は未実施で、StudioのSave/Publishはユーザー操作に委ねた。
