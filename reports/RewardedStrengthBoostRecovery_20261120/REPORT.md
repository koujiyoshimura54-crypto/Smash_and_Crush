# 5分Strengthブースト：receipt競合復帰／広告ボタン復帰

2026-11-20。副本 PlaceId **126576845524886** / UniverseId **10765181857** の既存Editへ反映。基準は最新 `origin/main = e76e2f88a29b836d20bc6d07d8dae3ac210f806c` と現在のStudio Source。実値で接続先を確認し、対象12 SourceはGitHubと一致（改行末尾を除く）、エディターバッファとも一致した。

**2件とも修正前を再現し、修正後は同じ参加／自然な画面開閉から復帰した。** 検証は隔離された実Source関数と未接続GUIによる模擬であり、実Play・実広告・実購入ではない。[検証記録](verification.json)。

## 1. receiptが保存競合後に再開しない問題

原因は `PlayerDataService.CommitStrengthBoostReceipt` が `Saving` または別の `PendingItemMutation` で、ブースト操作を登録する前に戻ること。既存の1/2/4/8秒再試行は「既に登録された操作」しか扱わず、この入口競合を回復しなかった。

修正は `RewardedStrengthBoostController.Receipt` に限定した。正規receiptを受け取った元のProcessReceipt呼出しを保持し、セッションと既存保存バリアが利用可能になるまで1秒間隔でメモリ状態だけを確認する。競合解消後は既存Commit・所有権付き保存・永続PurchaseId台帳をそのまま通す。PlayerDataService・Persistence・State・ReceiptServiceのSourceは変更していない。

- 同一Player／セッション／PurchaseIdの並行呼出しは処理中の結果を共有。別の正規receiptは既存排他に従って別々に確定する。
- `PurchaseGranted` は既存Commitの永続化成功確認後だけ。広告終了やクライアント通知では付与しない。
- 一度登録された操作の既存1/2/4/8秒再試行を優先。失敗が続いた後の追加試行は30秒間隔。別操作が占有中、保存中、既存再試行予約中には追加のDataStore要求を出さない。
- 待機時間でreceiptを破棄する期限は設けない。通常の競合復帰に再購入・再参加・Roblox再送は不要。
- 退出、セッション差替え、未ロード化、所有権喪失、`StrengthClosing`、BindToCloseで待機を終了し、未確定ならNotProcessedYet。既に始まった保存を途中破棄しない。再参加時の未確定receiptはRobloxからの再配送と保存済み台帳で復旧し、確定済みIDは再延長しない。
- 無効なデータ／Reset不一致など既存Commitの非一時エラーはNotProcessedYetで終了する。永続状態の不正を成功扱いしない。
- ProcessReceipt登録先、他商品の振分け、保存形式、所有権管理は変更なし。

公式の[ProcessReceipt説明](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService#ProcessReceipt)も確認。時間経過だけでNotProcessedYetが再実行される前提を置かず、元の呼出しで待機する方式を採用した。

## 2. 別画面を開くとFREEボタンが戻らない問題

原因は `Close()` が利用可否確認のserialを更新して進行中の返答を無効化し、メニュー／パネルを閉じた時は再描画しかしていなかったこと。

利用可否の世代・広告モーダル表示・WATCH操作の意思を分離した。Closeはモーダルと今回の開始意思だけを取り消し、背景の利用可否確認を取り消さない。確認結果が閉じている間に届いても保持し、別画面を閉じるイベントでFREE表示へ反映する。返答だけでモーダルを開いたり広告開始要求を送ったりしない。

- 初回確認は1件に集約。利用可能のキャッシュは60秒で失効し、WATCH直前は必ず新しく確認する。新鮮な結果がある時のモーダル表示・World移動で重複照会しない。
- 失敗／在庫なしの後は、MenuClosed、各パネルVisible変更、GUI Enabled、CharacterAdded、World変更などの自然な機会で再確認する。
- 再確認間隔は5秒。間隔中の自然な機会は1件だけ保留し、既存のUIタイマーから実行する。失敗が次の照会を自動予約するループや毎フレームAPI照会は追加していない。
- 15秒で確認をタイムアウト扱いにし、その世代と視聴意思を無効化。待機Luaタスクを終了し、次の自然な機会で復旧する。新世代より古い応答は無視する。
- 有効中ブーストの期限は広告可否とは独立。広告確認に失敗しても残り時間を保持する。
- 同じGUIへのMountは既存インスタンスを返す。GUI破棄時に接続と待機を終了し、再作成されたパネルの切断済み接続参照も整理する。
- Presentation・Style・価格処理・UI文言／位置／サイズは無変更。

利用可否APIは[GetAdAvailabilityNowAsync](https://create.roblox.com/docs/reference/engine/classes/AdService#GetAdAvailabilityNowAsync)。今回、実APIの呼出しはしていない。

## 変更Full Path

| Studio Full Path | 変更 |
|---|---|
| `ServerScriptService.Services.RewardedStrengthBoostController` | receiptの同一セッション待機・同一ID共有・終了条件 |
| `ServerScriptService.Services.RewardedStrengthBoostService` | 既存Initにサーバー終了時の待機終了を接続 |
| `ReplicatedStorage.Modules.RewardedStrengthBoostClient` | 利用可否と画面・視聴意思の分離、自然な復帰、診断 |
| `ReplicatedStorage.Config.RewardedStrengthBoostConfig` | 待機間隔、キャッシュ期限、診断の設定 |

対応するGitファイルは各Full Pathのドットを `/` に置き換えた `src/.../*.luau`。変更前は [before/studio.json](before/studio.json)、照合・既存ローカル差分の保全記録は [before/manifest.json](before/manifest.json)。

## 修正前／後の再現結果

| 条件 | 修正前 | 修正後 |
|---|---|---|
| 保存中に正規receiptを1回だけ渡し、保存を終了 | NotProcessedYetのまま、書込み0件 | テスト再送なしで1件だけ確定。解除から1回のメモリ待機以内に開始 |
| 別PendingItemMutation中にreceiptを1回だけ渡し、別操作を終了 | 同じく再開なし | 元の呼出しから1件だけ確定 |
| 同じIDを3並行＋別の通常購入IDを1件 | 既存台帳の単体試験とは別に再現 | 書込み2件、同じIDは1回、異なるIDは300秒ずつ延長 |
| 保存前失敗／保存後の応答消失 | 登録後の既存試験を維持 | 既存再試行で確定、応答消失で二重延長なし |
| 保存失敗が80秒続く模擬条件 | — | 0/1/3/7/15秒の既存試行、30/60/90秒の復旧試行で1回確定 |
| オフライン報酬・Robloxメニュー・Shop・Inventory・Mergeを確認中に開く | 返答が破棄されFREE非表示のまま | 開いている間に返答／閉じた後に返答、両順序で自然復帰 |
| 失敗後のメニュー開閉 | — | 手動RefreshAvailabilityなしで5秒間隔を守って再確認 |
| 15秒超の返答、古い成功より新しい在庫なしが先着 | — | 古い返答を適用せず、次の画面開閉で復旧 |
| WATCH直前確認中に別画面を開く | — | 返答後も広告開始要求0件、広告画面も再表示しない |
| 素早い開閉、GUI破棄後の応答、再Mount、World／復帰イベント | — | 同時照会の重複なし、古い世代の影響なし |

receipt試験は実Controller・実Commit・実Persistence・実所有権関数を、メモリ保存と仮想時計で実行。UI試験は未接続のnative GUIに実Visible/Enabled変更イベントを発生させた。Roblox標準メニューとCharacterAddedは対応するイベント入力を模擬し、実際のCoreGui操作・キャラクター死亡は行っていない。テスト側からRefreshAvailabilityを呼んで復帰させる手順は使っていない。

## 回帰・実測・未確認

- 今回のreceipt復帰60項目、UI復帰110項目。副本反映後も同じ試験を実行。
- 既存ブーストcore126項目、訓練統合363項目、Save統合75項目を実行。合計734は模擬アサーション数。
- 商品 **3733706770**、Placement **28777229838999**、**300秒／訓練倍率＋1**を維持。永久パス併用、歩行・手動・AutoTap・両WorldのTreadmill、他補正との加算順、期限切れ、再参加時の台帳、直接報酬への非適用を確認。
- 他補正なしの模擬値：歩行／手動／AutoTapは2（永久パスあり3）。World1有料は8（9）、World2有料は16（17）。World2通常の現行基本5も維持し6（7）。Treadmill中の手動／AutoTap重複加算抑止を保持。
- Studio実値の照合：変更4 Sourceのローカル／Source／エディターバッファ一致、構文コンパイル成功。対象外555 Source、Script無効状態、既存広告GUI／商品カード510プロパティ、Instance総数228,568を保持。
- **実Play未実施**：通常起動のプロフィール保存・通知などを実データから隔離できる手順が確認できず、無関係なサービスを一括置換する方法は使っていない。
- **実広告・実購入・実DataStore・実通知・実端末・実ユーザー死亡／再参加は未確認**。実AdServiceの平均確認時間は未計測。仮想時計やBindableEventで設定した遅延はRoblox APIの実測時間ではない。

## 診断・調整場所と戻し方

`ReplicatedStorage.Config.RewardedStrengthBoostConfig` に以下を集約。

| 設定 | 初期値 |
|---|---:|
| ReceiptWaitSeconds | 1 |
| ReceiptRecoverySeconds | 30 |
| AvailabilityCacheSeconds | 60 |
| AvailabilityRetrySeconds | 5 |
| AvailabilityTimeoutSeconds | 15 |
| AvailabilityDiagnostics | false |

通常は診断無効。必要時だけクライアントの `PlayerGui.StrengthGui` に属性 `StrengthBoostDiagnostics=true` を設定する（コード全体の設定を変える場合はConfigのAvailabilityDiagnostics=true、次回起動から）。既存Mountの `GetAvailabilityDiagnostics()` で直近最大8件のRequest／Reason／Started／Finished／Seconds／Resultを取得できる。値はクライアントの単調時計で、ログ大量出力・DataStore保存・送信はない。

属性をfalseまたは削除、Configを変更した場合はfalseへ戻すと記録を停止する。記録はGUI破棄で消える。読み取り例はクライアント側で `require(game.ReplicatedStorage.Modules.RewardedStrengthBoostClient).Mount(game.Players.LocalPlayer.PlayerGui.StrengthGui).GetAvailabilityDiagnostics()`。既にMount済みのGUIに対して使用する。

検証の再実行は `tests/RewardedStrengthBoostRecoveryOffline.py` で `receipt` / `ui` / `core` / `training` / `save` の隔離fixture入力を生成する。JSONのTestを注入依存で実行し、trainingのみ生成Runnerを既存StudioのEditで実行する。本番Moduleをrequireしてサービスを起動する方式ではない。

## Git・引き渡し

開始時のローカルmainは `1e795c8` で、既存LV関連の編集等を含んでいた。これらを保全し、mainのcheckout更新・別worktree・stashを行っていない。最新origin/mainを親とする専用Git indexから今回の差分だけをcommitし、通常のfast-forward pushを行う。既存ローカルmainとその未commitファイルは元の状態を維持する。関連仕様への追補はこの報告に集約し、既存編集のあるSPECを今回のために書き換えていない。

検証GUIは未接続で実行後に破棄。共有メモリの保全・検証補助も最後に除去する。副本は既存編集を保持した**未保存Edit状態で開いたまま**。Save／Publish、新規Studio、Place作成、正本、PR #1、実広告・購入・通知、force pushの操作はない。commit／push後のremote SHAは最終返信で報告する。
