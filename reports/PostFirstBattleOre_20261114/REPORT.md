# 初戦終了後のOre直列ファネル — 2026-11-14

既存 `MTF_FirstOreMerge_v1` を指定の5段階へ変更した。新しいファネル名・CustomEvent名は追加していない。変更は計測用の6 Sourceで、チュートリアルの順番・ガイド表示条件、戦闘、報酬、素材、合成・装備・保存処理は変更していない。Eggファネル、オフライン報酬案内も対象外。

正本は PlaceId **126576845524886** / UniverseId **10765181857**。開始時はEdit、PlaceVersion **627**。ローカル開始HEAD `49f7090` に対しorigin/mainを確認し、既存の5コミットを通常fast-forwardで取り込んだ **`d0b5f24`** を今回の差分基準とした。現行Studioとの対象Source・エディタ内容を照合してから変更し、古いGitHub SourceでStudioを置換していない。Phase 1・2、Trophy案内修正、高LV曲線・旧形式復元など直前の変更を保持した。

## 定義と新旧対応

同じ番号でも旧版と意味が異なる。過去の `Normal` 分類と今回の集計を合算しない。

| Step | 旧StepName | 新StepName | 今回の確定条件 |
| --- | --- | --- | --- |
| 1 | Eligible | FirstBattleEnded | 既存FirstBattleTutorialServiceがWorld1 Stage1の初戦Victory / Death / Backを受理 |
| 2 | OreViewOpened | LobbyPlayableAfterFirstBattle | 初戦後の新しい描画観測と、現在の生存Character・Lobby実位置・配置応答・HUD・操作・Loading終了を確認 |
| 3 | ValidSelection | MergeGuideShown | 初回OreガイドがCoordinatorを所有し、現在の案内文字が実際に表示領域内で可視 |
| 4 | MergeRequested | OreViewOpened | 現在のOre合成モードのパネルが描画され、本人がMerge範囲内。Item/Pet/売却は除外 |
| 5 | MergeCommitted | MergeCommitted | 既存ForgePersistence.Resolveのジャーナル保存確認・runtime反映後。今回の観測済み前段と同一操作 |

旧画面表示は新Step4に相当する。素材選択・受付は今回のファネル段階から外したが、正規の素材判定・受付・保存は維持した。Step5の保存確定という意味は同じでも、母集団・前段・分類が変わるため旧版と混ぜない。

対象は `PlayerDataOwnership.Acquire` によりこの参加でNewと確定した初回セッション、かつ `FirstBattleTutorial.Eligible` の新導線対象で、初戦結果確定時に初回Ore合成が未完了の人。既存プロフィール、Unknown、再参加、データリセット、Studio開始override、StageSkipは対象外。フィールドがないだけでNewとは判定しない。

初戦の既存権威経路を利用する。Deathは既存の本人Boss戦witness、Character、戦闘state、run、reset token等が一致した死亡、Victoryは既存の本人Stage1撃破、Backは既存の受理済み撤退・帰還配置経路。退出、壁接触、単なる区域進入から結果を作らない。別World・Stageの結果通知を新しく接続していない。最初に確定した結果を固定し、死亡復帰・再戦で開始状態を消さない。

`CheckOre` の候補抽出・`OreMerge.Evaluate` は維持。Stone×2で素材条件を満たした観測は既存Custom詳細 `Ore:Eligible` に残すが、ファネルは開始しない。

## 順序、実表示、重複防止

結果確定時に参加中だけのchallengeを発行する。Step2は初回参加の `ClientPlayable` フラグを転用せず、結果後のchallengeを含む新しいクライアント描画観測を受け取る。サーバーは現在のCharacter、既存配置のCharacter/revision、配置ready属性、生存・非anchor、World1、戦闘/帰還/skip処理中でないこと、実TrainingArea.Floorの範囲を確認する。徒歩でLobbyへ戻った場合も、現在の配置確認と新しい操作準備観測があれば対象になる。不要な新スポーンを要求しない。

Step3はTarget属性やガイド対象資格だけでは成立しない。既存OreGuideの現在step、Initial種別、Coordinator所有、Presentationの現在のPinnedLine、文字・透明度・可視矩形を読取確認する。閉じたガイド、他メニューや競合で非表示の案内は送らない。ガイドを表示させるための条件変更はしていない。

Step4はMergeShopViewの読取providerから、Oreタブ・非売却・親GUI有効・実パネル可視矩形を描画フレームで確認する。セッション、challenge、Character、Forge token/generation、単調増加sequence/view revision、close revisionを照合する。古いCharacter、閉じた画面、旧tokenや逆順通知は進行させない。初期ClientPlayableの既存Heartbeat処理は維持した。

ForgeClientの通常リクエストに付くAnalyticsContextは、直近1秒以内に描画観測済みの現在の画面だけを引き継ぐ。サーバー側も観測済みviewと正規素材の一致を確認する。このcontextから未観測のStep2〜4を作ることはない。保存完了の通知は既存経路をそのまま利用し、クリック・受付・保存待ちではStep5を出さない。

複数の事実が同じ観測で成立した場合は確認できた前段から順に進める。描画が来ない場合や観測を失った場合は補完しない。ローカルの読取は最大10Hz、送信は変化時最短0.25秒、同一signature最大5回・1秒間隔。これは配置通知等との競合に対応する観測の再通知であり、Analytics APIの再送ではない。Startの多重呼出し・ガイド解除で接続を増やさない。

## 対象外と迂回

| 経路 | 扱い |
| --- | --- |
| 初戦前に初回合成を保存確定 | 今回のファネル対象外。後の結果・再戦でも開始しない |
| 初戦後、ガイド観測前にOre画面を自主表示 | 直列前段をそこで固定し、ガイドを補完しない。実際の表示と保存確定を既存CustomEventで識別 |
| Lobby操作準備観測より先にOre画面を表示 | 同様に前段を補完せず、別の固定理由で識別 |
| 勝利後Stage2へ進む | Step1を維持。退出やLobby到着と推定しない。後の実帰還で再評価 |
| 初戦中退出、再参加 | 退出から結果を推定しない。後の既存プロフィール参加へ前回の未完了ファネルを再開しない |
| リセット、StageSkip、別World/Stage | 対象と混ぜない。すでに観測した前段も再開始しない |

迂回の詳細値は既存 `MTF_FirstActionSeconds_v1` のCustomField03を使用する。

- `PostFirstBattle_v2:<結果>:Bypass:OreViewBeforeGuide`
- `PostFirstBattle_v2:<結果>:Bypass:OreViewBeforeLobbyReady`
- `PostFirstBattle_v2:<結果>:Bypass:MergeRequestWithoutPrefix`
- `PostFirstBattle_v2:<結果>:Bypass:MergeCommitted`

後からガイドが見えても、その迂回セッションの前段を修復しない。画面表示・合成成功を失敗や離脱と同一視せず、Customの実観測を併用する。既存 `MergeRequestAccepted` / `OreRequestWithoutValidatedView` / `MergeSaved` の例外観測も維持する。

## 分類と送信

Oreファネル内の全段でCustomField01は `PlaceVersion:<実値>`、02は `NewFirstSession`、03は最初の結果に応じた **`PostFirstBattle_v2:Victory` / `PostFirstBattle_v2:Death` / `PostFirstBattle_v2:Back`** に固定する。他5ファネルは03=`Normal`を含め定義・フィールドを維持。

時刻は既存のサーバー参加観測からの経過秒。新しい段階の詳細値は `PostFirstBattle_v2:<結果>:<新StepName>`。旧 `Ore:OreViewOpened` 等へ別の意味を入れない。初回死亡時の最新Ore段階詳細も新prefixで区別する。固定CustomEvent名は既存2個のまま。

Transportは変更していない。既存の順序付き64件キュー、30秒待機上限、API pacingと、送信例外・overflow・期限による当該ファネルの後段抑止を使用する。Analytics失敗が保存処理やゲーム成功を待たせる仕組みは追加していない。APIのsilent dropは検出できないため、プラットフォーム内部の欠測まで完全に防げるとは扱わない。Customの到達観測とFunnel配信成否は独立する。故障注入試験では合成保存が成功し、Funnel Step5だけが欠測する一方、到達Custom値が残る例も確認した。

## 変更Full Path

| Full Path | 変更理由 |
| --- | --- |
| ServerScriptService.Services.FirstPlayAnalyticsService | 5段階、対象・結果固定、前段検証、迂回、既存確定通知の利用 |
| ServerScriptService.Services.FirstBattleTutorialService | 既存の受理済みDeath/Victory/Backの直後に計測通知のみ追加 |
| ReplicatedStorage.Modules.FirstPlayAnalyticsClient | 結果後の新しい準備・描画観測、古いcontextの除外、有限再通知 |
| ReplicatedStorage.Modules.MergeShopView | 読取providerへPanel/Tab/Selling/CloseRevisionを提供 |
| ReplicatedStorage.Modules.OreMergeTutorialGuide | 既存表示の所有権・実表示を返す読取関数と解除 |
| ReplicatedStorage.Modules.OreMergeTutorialPresentation | 現在のPinnedLineの可視性を返す読取メソッド |

調査したFirstBattleTutorialState、TutorialGuideClient、FirstPlayAnalyticsTransport、PlayerDataService、ForgeService、ForgePersistence、ForgeClient、LobbySpawnService、RunReturnService等は無変更。最終照合は関連20 Sourceと20 Editor text、うち6変更・14保持。[ハッシュ証跡](evidence.json)。UI・ゲーム仕様の追記と [FIRST_PLAY_ANALYTICS](../../docs/FIRST_PLAY_ANALYTICS.md)、DEV_STATUS、CHANGELOGも更新した。

## 検証結果

本番DataStore・購入を使わず、既存FirstBattleTutorialのmemory隔離環境を使用した。外部サービス参照39箇所を一時的にredirectし、終了時に保存したBefore/Afterの完全一致を確認して復元。テスト補助は `tests/PostBattleOre` に再現用として残すが、Studioの一時Script/Folder/Moduleは除去した。

| 種別 | 確認内容 | 結果 |
| --- | --- | --- |
| 模擬・正規Source実行 | StateMatrix：3結果、対象外、初期Stone、順序、旧通知、再戦、画面close、保存待ち、送信例外/overflow/予算期限 | **185 assertions成功** |
| 模擬・正規Source実行 | ClientMatrix：実描画イベントなし、非表示/画面外、Item/Pet/売却、HUD/controls、旧Character/token、再開、接続数、有限再通知 | **30 assertions成功** |
| 模擬回帰 | 変更前d0b5f24と他5ファネルの出力比較 | **18 Funnel行の名前・順序・session・全フィールド一致**。185項目に含む |
| 隔離実Play・準備済み戦闘 | Victory / Death / Back → Lobby → 実ガイド → 実Oreタブ → 素材クリック → 合成保存 | **3結果とも1〜5が順に1回ずつ** |
| 隔離実Play | Inventoryメニュー中のガイド非表示、閉じた後の再評価 | Step2で停止、実表示後だけStep3 |
| 隔離実Play | Item表示、Petタブクリック、Oreタブクリック | Item/PetはStep3まで、OreでStep4 |
| 隔離実Play | 実Mergeクリック、memory保存失敗、再試行、連打 | 失敗/待機中は4まで、保存確定後5が1回 |
| 隔離実Play | 死亡後の実respawn | Death直後ではなく、新Characterの生存・配置・操作準備後に2、ガイド実表示後3 |
| 隔離実Play | 勝利後Stage2直行→後からBack | Stage2中は1のみ。帰還後2〜5、分類はVictoryのまま |
| 隔離実Play | 初戦前に通常ForgeClientで合成保存→Boss戦→Back | 結果前後ともOreファネル0。初期素材だけの開始も0 |
| 隔離実Play・競合fixture | Coordinatorをテスト所有者で占有し、ガイドなしで実Oreタブを開く | 1〜2のみ。競合解除後も3〜5を補完せず、実合成をBypass詳細で記録 |
| 隔離実Play・送信故障注入 | 実画面・素材・Merge操作後のAnalytics送信失敗 | 素材消費・生成・保存完了。Funnelは1〜4、失敗した5を再送しない |
| Hybrid | 描画停止中、表示通知だけ模擬、戦闘結果・Forgeは実処理 | 3結果の経路と保存失敗/保留を確認。**実表示の証拠ではない** |
| 静的 | 変更6 Source＋テスト5 Luauのコンパイル | 11ファイル成功。diff whitespace確認 |

実Playは戦闘fixtureでLV4/Strength40、壁破壊済み・位置を準備し、既存Boss攻撃/手動攻撃/Return処理で結果を発生させた。自然な新規育成時間の測定ではない。ガイド・画面の観測、Humanoid移動、タブ・素材・Mergeのクリックは後半の実Playでは実クライアントを通した。実機操作ではなくStudio入力ツールによるPC相当1390×601の確認。

参加起点の値が変わっていないことを確認するための記録例（秒、ツール操作待ち・故障注入待ちを含む）：

| 実Play結果 | 初戦結果 | Lobby準備 | ガイド実表示 | Ore画面 | 保存確定 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Back | 13.991 | 14.155 | 25.588 | 49.188 | 74.154 |
| Death | 19.558 | 23.591 | 23.591 | 45.940 | 47.826 |
| Victory（Stage2経由） | 15.425 | 39.823 | 39.823 | 57.473 | 59.256 |

これは操作時間・継続率改善の評価値ではない。詳細な観測値と状態は [evidence.json](evidence.json)、再現手順は [tests/PostBattleOre/README](../../tests/PostBattleOre/README.md)。

## 描画停止、ログ、未確認事項

前半の複数隔離PlayではRenderSteppedが0、Viewportが1×1、案内文字のAbsoluteSizeが0だった。サーバー処理は進んでいたが、この間の実表示検証は不能。実表示として成功扱いせず、表示通知を模擬したHybrid試験と分けた。その後の新しい隔離PlayでViewport1390×601と描画フレームを確認し、上記の実表示経路を追加実施した。停止・復帰の原因は未確定であり、ガイドの不具合と断定しない。

関連の新しい製品Runtime Error / Infinite Yieldは観測されなかった。memoryの保存故障注入では意図した `[Forge] Save unconfirmed` Warning、Badge無効化ではAward失敗Warningが出た。一部Playで既存asset `81504106` のnot found、`17387207972` / `118491056518808` / `103097380197303` の権限/取得Warningもあった。対象外アセットを修正していない。前半の補助コードにはPlay側loadstring不可とfixture anchor解除前のassert失敗があり、製品のエラーとは分けて扱った。fixture解除後と後半実Playで検証をやり直した。

未確認：公開環境のCreator Hub受信・集計、実ネットワーク切断/遅延・プラットフォームsilent drop、スマホ/タブレット実機・端末相当プレビュー、自然なストリーミング。今回UI配置は変更していない。切断・旧Character/token・再参加・キュー欠測等の境界は上表の模擬検証であり、実機通信試験とは呼ばない。新規性は既存のプロフィール取得provenanceに依存し、過去に完全削除されたデータと本当に初めてのアカウントを区別できるとは保証しない。

## Creator Hub確認手順

1. ユーザー本人が手動Save/Publishした後、**実際の公開日時と実際のPlaceVersion**を記録する。本報告のEdit 627と隔離Play 0は今回変更の公開版を意味しない。将来の版・公開日時は未記入。
2. Universe 10765181857のAnalytics → Funnelで `MTF_FirstOreMerge_v1` を選ぶ。期間を実公開以降にし、CustomField01=`PlaceVersion:<実公開版>`、02=`NewFirstSession`、03=`PostFirstBattle_v2:Victory` / `Death` / `Back`の完全な値を指定する。まず結果別に確認し、合計を見る場合もこの3分類だけを対象にする。
3. 旧03=`Normal`を除外する。ファネル名やStep番号だけの比較を避ける。旧版は素材Eligibleが母数、新版は未合成の初戦終了が母数。名称変更前後の単純な率比較から改善を断定しない。
4. 公開環境で正規の新規プロフィールの各経路を観測し、View Eventsで1〜5の順序、StepName、参加session、固定分類、PlaceVersionを確認する。既存プレイヤーやdebug resetでNewを偽装しない。Studio recorderの成功はHub受信の証拠ではない。
5. Custom / Exploreの既存 `MTF_FirstActionSeconds_v1` を同じ公開版・期間で絞り、新prefixの各段階とBypass詳細を個別確認する。Count/Unique Usersは到達、Average valueは**参加からの秒数**。結果後の区間時間や全参加者の平均と読み替えない。ガイド前自主開店・先行合成・Stage2滞在を単純なゲーム離脱と呼ばない。
6. View Events / Error Reportで欠測を確認し、集計更新を待つ。ローカルで検出可能な送信失敗は後段を抑止するが、プラットフォームのsilent dropまで保証しない。

根拠：[Roblox Funnel events（前段補完・初段分類）](https://create.roblox.com/docs/production/analytics/funnel-events)、[Custom fields](https://create.roblox.com/docs/production/analytics/custom-fields)、[Event types / View Events](https://create.roblox.com/docs/production/analytics/event-types)。Studioの `rbx-instrument-analytics` skillを使用し、ファネル名維持・非公開など今回の明示指示を優先した。

## 最終状態

正本はEdit、関連20 Sourceと20 Editor textが今回のローカル内容に一致。検証用の外部サービスredirect39箇所を完全復元し、`__FirstBattleMemory`、backup、`__PostOreQA`、各補助Scriptを除去した。Save/Publish・保存GUI操作なし。ユーザーのPlayは開始時点では動いておらず、停止したのは今回開始した隔離Playのみ。

今回分だけを通常commit・origin/mainへ通常pushする。既存未追跡 `reports/Visual_Templates_Secret_VIP_Green_20260917.md` は保持して対象外。PR #1の操作・マージ、force push、既存編集の破棄は行わない。報告書・コードを含むcommitはGit履歴と完了報告を参照。
