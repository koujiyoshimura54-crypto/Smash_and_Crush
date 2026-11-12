# World1 Stage2 Boss死亡・未撃破Back計測 — Phase 1.1–1.3

2026-11-12。正本Studio **PlaceId126576845524886 / UniverseId10765181857**。開始時にorigin/mainを取得し、`a8b65952e03e6f775d47cb28809e191ee6beee0c`を確認。PR #1はDraft・未マージで、今回変更していない。

現在の未保存Studioから調査対象9本を読み取り、mainとの一致を確認してから差分を作成した。既存作業コピーの未追跡資料を保持するため、専用worktree/branch `codex/stage2-boss-outcomes-20261112` を使用。GitHubからStudio全体を復元していない。

## 実装した定義

| ファネル | Step1 | Step2 |
|---|---|---|
| `MTF_FirstStage2BossDeath_v1` | `DamagedStage2Boss` | `KilledByStage2Boss` |
| `MTF_FirstStage2BossBack_v1` | `DamagedStage2Boss` | `BackBeforeStage2BossDefeat` |

対象は既存MTF_FirstStage2Combat_v1と同じ、取得・新規作成が確認された初回参加セッションのWorld1 Stage2。既存Stage2の正常なStep4観測が成立した箇所から両方のStep1を開始する。攻撃ボタン入力だけ、未観測の前段、Existing／Unknown／未読込／debug reset／StageSkipから開始しない。名前・番号は固定、各ステップは既存参加GUIDにつき1回まで。新しいCustomイベント、時間・Strength・残HP値は追加しない。

死亡Step2は、既存BossAttackServiceのセッション検証と攻撃範囲判定を通った攻撃について、設定ダメージが致死量であり、実際のHP書込みが正数から0になった直後に観測する。攻撃レコード内のWorld、Stage、Boss、Character、Humanoidを使い、死亡後のCurrentStageは参照しない。Humanoid.Diedは従来の独立した死亡観測だけに使う。Reset、落下、別原因、他Stage／World2、古いCharacter、非致死攻撃では完了しない。

Back Step2は、RunReturnの正当な生存中要求に限定する。帰還前のWorld・StageManagerのStage・Character・現在のactive run・EnemyManager状態・サーバー側のBoss解放条件を確認して保持し、StreamLobby後にも照合する。Bank.Beginの受理tokenが同じrun／Characterであることを確認し、既存初期化が作った新runを記録。MoveToLobby成功後、既存LobbySpawnReadyのサーバー検証が成立してFirstPlayAnalyticsService.Placedへ届いたときに、同じCharacter／新run／World／配置revisionを照合して完了する。帰還・保存処理に追加の待機を入れていない。

銀行処理完了はBack判定に使わない。Trophy・徒歩・自動復活・World移動では計測を準備しない。ReturnBusy／StaleRun／死亡／配置失敗／確認通知未着・不一致では完了しない。既存ReturnAcceptedは初回専用のまま、新しい観測はそれから独立しているため、先にStage1でBackしてもStage2のBackを記録できる。

初回Boss撃破済みフラグは参加セッションに保持し、EnemyManagerからの実撃破観測で立てる。前段欠測で既存撃破ファネルが完了しなかった場合も、実撃破を見た後は新しい死亡・Backを完了させない。死亡・帰還・再挑戦で進捗やフラグを消さず、退出で破棄する。再参加した既存プレイヤーへ持ち越さない。

**両ファネルの完了者は重複する。死亡→再挑戦→Back、Back→再挑戦→死亡は両方に該当してよい。合算して未撃破人数、ゲーム退出人数、離脱人数と解釈しない。** その後のBoss撃破は従来の`DefeatedStage2Boss`を正常に進める。この名称は従来どおり「プレイヤーがBossを倒した」の意味である。ゲーム退出、徒歩離脱、再挑戦専用ファネルは追加していない。

## 変更Full Pathと確認した既存経路

実装変更は次の3本だけ。

| Full Path | 変更 |
|---|---|
| `ServerScriptService.Services.FirstPlayAnalyticsService` | 2本の定義・参加内重複防止・初回撃破ラッチ・致死攻撃判定・Back文脈と配置照合 |
| `ServerScriptService.World.BossAttackService` | 既存の有効HP減算直後に確定した攻撃レコードを通知 |
| `ServerScriptService.Services.RunReturnService` | 帰還前の文脈捕捉、stream後再検証、既存配置成功後の観測準備 |

既存のFirstPlayAnalyticsTransport／Config、RunItemBankService、RunReturnController、StarterGui.StrengthGui.RunReturnClient、EnemyManagerを確認し、変更していない。RunInventoryServiceのactive run／受理receiptとLobbySpawnServiceの配置確認条件、StageManagerのサーバーStage、PlayerDataServiceの新規分類／reset／差替えフックも確認した。共有銀行処理はBackとTrophyに共用され、受理receiptはrunリセット・死亡後も保存のために残ることを前提としている。

Analyticsは既存pcall入口と非同期Transportを使用する。BossAttack→Analytics→Transport／純粋Configの依存にEnemyManagerやRunReturnへの戻りrequireはない。RunReturnが追加参照するRunInventory、StageManager、Stage1WallManagerは既存依存で既に初期化済み。死亡・帰還中の新たなrequire待機、task.wait、API直呼び、Remote、保存項目は追加していない。

## 検証結果（模擬／実Play／Hubを区別）

**実施したのはStudioのネイティブLuauで実行する隔離Edit模擬検証。実ゲームPlayやCreator Hub受信の確認ではない。** コピーした実装Sourceを、偽Players／Character／時計／配置／保存／APIに結び付けて実行した。BossAttackのHeartbeatとHP書込み、RunReturn、RunInventory、RunItemBank、Analytics、Transportは実Sourceを使用した。物理的な攻撃範囲、stream・ロビー移動、クライアント通信、永続保存そのものは模擬依存である。失敗・死亡・run切替をstream後や配置確認前に注入し、非同期継続の境界条件を再現した。

| 試験 | 結果・証拠 |
|---|---|
| 新規outcome／帰還・戦闘結合 | **101 assertions合格**。[outcomes.json](outcomes.json)、[fixture](../../tests/FirstPlayAnalytics/Stage2Outcomes.luau) |
| Transport／無効化・失敗・飽和 | **59 assertions合格**。同JSON、[fixture](../../tests/FirstPlayAnalytics/Stage2OutcomesTransport.luau) |
| 既存Stage2回帰 | **68 assertions合格**。既存Stage2Matrixを使用し、正常予算期待値だけ46→48（新規Step1×2）へメモリ内調整。[regression.json](regression.json) |
| 従来Entry／Combat／Ore状態行列 | **38 assertionsを変更前・変更後双方で合格**。同一旧イベント列。上記Stage2回帰内で実行 |
| Studio適用／保持 | 3本のSourceを適用直前に全文一致検証し、適用後は予定Sourceと一致・Luauコンパイル合格。499本中変更3本、**496本不変**、追加・削除0。[preservation.json](preservation.json) |

101項目には以下を含む。

- 正常な有効ダメージでStep1が各1回。両方の名前・番号・同じGUID・PlaceVersion／NewFirstSession／Normalを照合。
- 致死HP書込み中にDiedが同期発火し、Stage・runが即時初期化されても死亡を記録。Reset、落下、他Stage、World2、未経験、miss、不正session、古いCharacter、非致死攻撃、非致死攻撃中に別原因で0になる場合を除外。
- 正常BackはMoveToLobbyの成功だけでは未完了で、対応する配置確認後に完了。連打と古いrunの10回再送、ReturnBusy、stream／配置失敗・例外、StaleRun・StalePlacementを除外。
- streamをまたぐ死亡、Character・run・Stage・World・データ・撃破状態の変更、および配置確認前の死亡、run・Character・World・revision・StageSkip・撃破変更を除外。
- Trophyの共有銀行成功、徒歩、復活、Stage1 Back、World2 Back、Boss未解放状態、確認通知未着だけでは完了しない。World2・Boss未解放時の帰還自体は従来どおり成功することも確認。
- Stage1 Back後のStage2 Back、死亡→BackとBack→死亡、両方完了後の旧撃破計測、初回撃破後再周回の除外を確認。
- Existing／Unknown／未読込／reset／データ差替え／debug overrideフック／StageSkip、前段欠測、再参加・GUID更新を確認。
- 同じ完全経路で、**旧4ファネルと全Custom行の名前・番号・順番・値・フィールド・GUIDが変更前と一致**。帰還のreset／Training／Speed／Move呼び出し列も一致。新しい4行だけを追加。
- Analytics無効・送信失敗でもBossダメージ・帰還・既存deferred銀行処理が成立し、模擬Item保存が1回だけ反映。帰還の配置確認が保存完了を待たないことも確認。

実Playを開始・停止していない。テスト用Script／Remote／InstanceをDataModelへ追加しておらず、検証用Playerデータも作っていない。純粋Ore／Merge／Countsだけを読んだ。正常ルートのRuntime Error／Warning／Infinite Yieldが0だったという主張はしない。実プレイヤーの物理戦闘・Backボタン入力、ネットワーク遅延、同時接続、実DataStoreとCreator Hub受信は未確認である。

## 送信量・欠測と順序保護

既存Transportの64行／参加キュー、共有`120 + 20×CCU`毎分ペース、30秒待機上限、失敗時再送なしを維持。新2本は通常最大**4件のFunnelイベント**だけで、完全経路は46→50行。旧4本の行の相対順序は変わらない。通常50行のキュー投入・送信は欠測なし。

偽時計による20人同時集中試験は、変更前920行（20×46）のうち380送信・540欠測、変更後1000行（20×50）のうち380送信・620欠測、最大キュー50、経過約30秒。追加80行で欠測も80増えた。これは瞬間集中を与える模擬負荷であり、本番の欠測率ではない。余分な送信量は飽和時に既存計測の欠測も増やし得る。今回キュー・レート・待機・再送方式を変更していない。

各新ファネルについて、Step1送信例外／キュー超過後にStep2を送らず、Step2失敗を再送せず、一方の失敗で他方を止めないことを確認した。検出できた欠測には既存SendBrokenの順序保護が働く。プラットフォーム側の無通知欠測や自動補完はこの保護では検出できない。実観測のない過去ステップをアプリ側で作ってはいない。

Backは厳密に配置revisionを照合する。並行したスケール補正等でrevisionが更新されたケースも古い文脈から推測せず欠測とする。これは計測上の制限であり、実際の移動・保存・再試行の挙動を変えない。

## 保持した状態

Boss HP、壁HP、必要Strength、成長量、攻撃・復活・帰還・保存仕様は未変更。Stage2 Bossは現行2250、RequiredStrength450、壁300／325／350／425を保持し、HP1500案は適用していない。Studioの既存Stage1候補値をmainへ復元・混入していない。

Ore5スロット、LandscapeSensor横画面、左Menu70％、Trophy／PetEgg／通知等を含む対象外Source496本を保持。ScreenOrientationもLandscapeSensorのまま。今回のStudio操作は3本のSource編集のみで、GUI／Object配置を変更していない。Save／Publish、保存GUI、Placeファイル書込みを実施していない。**Studioは未保存のEdit状態**。

## Creator Hub確認手順（所有者による後続操作）

1. 所有者が必要なタイミングで手動Save／Publishし、その公開PlaceVersionを控える。今回のエージェント作業では実施しない。
2. 公開サーバーで、本来の新規作成profileとなる初回セッションを用いて、World1 Stage2で正常なBossダメージを与える。既存低レベルprofileやdebug resetを新規の代用にしない。
3. Creator Hub → 対象Experience → Analytics → Funnelで2本の新規ファネルを選ぶ。公開PlaceVersionとNewFirstSessionで絞り、View EventsでStep1 `DamagedStage2Boss` が両方に1回、同じ参加GUIDで出ることを確認する。
4. 同じ参加内で「Boss致死攻撃→再挑戦→未撃破Back」または逆順を行い、それぞれのStep2名と1回限りの出力を確認する。先にStage1 Backした経路も確認する。その後の撃破は既存MTF_FirstStage2Combat_v1の`DefeatedStage2Boss`が進むこと、撃破後再周回では新規完了が増えないことを確認する。
5. Reset／別原因死亡／Trophy／徒歩／World2／失敗要求の除外、既存4本の出力と保存結果を確認する。View Eventsを更新し、届かない場合はError Reportも見る。Studio recorderや本報告の模擬JSONはHub受信証拠にならない。
6. 集計グラフは通常初回イベントから約24時間後に確認。2本の完了率は独立して読む。重複するため合計を未撃破率・離脱率にしない。

公開サーバーのみから送信できること、View Events／集計待ち時間・上限は2026-11-12に[公式Funnel説明](https://create.roblox.com/docs/production/analytics/funnel-events)と[公式イベント検証・制限](https://create.roblox.com/docs/production/analytics/event-types)を確認した。
