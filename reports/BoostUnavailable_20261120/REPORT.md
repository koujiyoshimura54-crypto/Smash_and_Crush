# 広告ブースト入口・Unavailable表示（2026-11-20）

副本PlaceId **126576845524886** / UniverseId **10765181857** の既存UIを変更した。広告の利用可否から入口表示を分離し、利用不可でも説明画面と閉じるXを使用できる。利用不可・失敗・タイムアウト・Studio制限時は、既存WATCH ADボタンの位置と寸法でグレーの **Unavailable** を表示する。腕アイコン、入口、ダイアログの配置・寸法・その他の装飾は維持した。

実Play・実広告・実購入・Save・Publishは実施していない。現在のStudioは既存編集を保持した未保存Edit状態。確認画像は一時取得して目視確認後に削除した（画像を保管しない既存指示による）。

## 原因と修正

旧実装は、入口とOpenの両方が `usable()` に依存していた。広告利用不可では説明画面も開けず、成功結果の60秒キャッシュが切れると入口が消えた。開いていた画面では古いWATCH AD表示が残る一方、Activeだけfalseになり、自動再確認もなかった。Studioの利用可否アダプターもfalseを返していた。

入口は既存の他画面との重なり制御 `not blocked()` だけで表示する。広告開始は、設定有効・新しい利用可能結果・Studio以外・ユーザーのWATCH AD操作を必要とし、さらに視聴直前に再確認する。入口表示によって広告開始・報酬付与の制限を緩めていない。

| 画面状態 | 既存ボタン位置の表示 | 操作 |
|---|---|---|
| 確認中／開始要求待ち | Checking…、グレー | 広告開始不可、Xは使用可 |
| 利用可能 | WATCH AD、既存の緑 | 明示タップで視聴直前確認 |
| 利用不可／失敗／タイムアウト／Studio | Unavailable、グレー | 広告開始不可、入口・開閉は使用可 |
| ブースト有効中 | 残り時間、既存の緑 | 二重開始不可。入口の残り時間も維持 |

他画面を開いた間は従来どおり入口を隠し、広告画面を閉じる。背景の可否確認はそれだけでは取り消さず、他画面を閉じると入口が復帰する。Closeは視聴意図と未開始の再試行予約を解除する。閉じた後の結果、通常確認完了、期限切れからの復帰だけでは広告を開始しない。

## 更新と診断

- 成功キャッシュは既存設定の60秒。不可／失敗の再確認間隔は5秒、問い合わせ上限は15秒。
- 開いた時点で有効な結果があれば再利用する。結果が古ければ再確認する。
- 画面表示中は既存0.25秒UIタイマーで期限だけを確認し、60秒経過または失敗後5秒で一件だけ問い合わせる。Checking…から結果へ遷移する。
- 閉じている間の定期照会は追加していない。初回、既存のメニュー・各画面終了等の自然な操作、ブースト終了に伴う確認は維持。自然なイベントが再試行間隔内に発生した場合の予約は一件まで。
- 同時確認を抑止し、連番の異なる古い応答は破棄する。Destroyで接続・待機を解除する。タイムアウト後の遅い応答は結果を書き戻さない。
- Studioは既存のサーバー開始制限を維持するため、広告APIを呼ばずUnavailableとする。実APIの利用不可理由を推測で記録しない。

診断は既存 `ReplicatedStorage.Config.RewardedStrengthBoostConfig.AvailabilityDiagnostics=false` のまま。必要なクライアントだけ、既存StrengthGuiの `StrengthBoostDiagnostics` 属性をtrueにする。既存Mountハンドルを取得して以下を確認できる（同じGuiへのMountは重複生成しない）。

```luau
local gui = game.Players.LocalPlayer.PlayerGui.StrengthGui
gui:SetAttribute("StrengthBoostDiagnostics", true)
local ui = require(game.ReplicatedStorage.Modules.RewardedStrengthBoostClient).Mount(gui)
local state = ui.GetAvailabilityState()
local history = ui.GetAvailabilityDiagnostics()
-- 確認後に戻す
gui:SetAttribute("StrengthBoostDiagnostics", nil)
```

履歴は最大8件のメモリ内情報。`RawResult` はAPI返却表のコピー、`APIResult` は実際のAdAvailabilityResult。`CallSucceeded`、`Error`、`Seconds`、`TimedOut`、`APIInvoked`、`StudioRestricted`、`UIState`、表示状態、照会理由を区別する。StudioではAPIInvoked=falseであり、APIResultや成功状態を作らない。未完了タイムアウトにはCallSucceededの確定値がない。古い応答はIgnored/StaleResponseを記録する。通常の大量ログ、DataStore保存、プレイヤー向け内部コード表示は追加していない。属性を戻すと新規記録が止まり、既存履歴はDestroy時に消える。

API返却表の扱いは[AdService公式API](https://create.roblox.com/docs/reference/engine/classes/AdService)と[AdAvailabilityResult](https://create.roblox.com/docs/reference/engine/enums/AdAvailabilityResult)を参照。実APIは実行しておらず、実際の平均確認時間は**未計測**。試験内の2.5秒や15秒等は模擬時計による設定時間である。

## 変更Full Pathと手動調整場所

| Studio Full Path | 対応ファイル／変更 |
|---|---|
| ReplicatedStorage.Modules.RewardedStrengthBoostClient | `src/ReplicatedStorage/Modules/RewardedStrengthBoostClient.luau`：入口・開閉・表示状態・期限更新・診断 |
| ReplicatedStorage.Modules.RewardedStrengthBoostPresentation | `src/ReplicatedStorage/Modules/RewardedStrengthBoostPresentation.luau`：生成時の入口表示、初期Unavailable表示 |
| ReplicatedStorage.Config.RewardedStrengthBoostStyle | `src/ReplicatedStorage/Config/RewardedStrengthBoostStyle.luau`：UnavailableColorのみ追加、RGB(117,120,125) |
| StarterGui.RewardedStrengthBoostGui.Entry | Visible false → true |
| StarterGui.RewardedStrengthBoostGui.Overlay.Panel.Watch | BackgroundColor3 (76,237,39) → (117,120,125)、Active true → false、AutoButtonColor=falseを設定 |
| StarterGui.RewardedStrengthBoostGui.Overlay.Panel.Watch.Title | Text WATCH AD → Unavailable、TextSize 44 → 23（既存StatusTextSizeを使用） |

ボタンの枠436×78、パネル570×480、WATCH ADの44、状態表示の23、その他の位置・寸法・白文字・黒輪郭は既存Styleの値を維持。色はUnavailableColor、状態文字サイズはModal.StatusTextSizeで調整できる。時間設定は既存ConfigのAvailabilityCacheSeconds／AvailabilityRetrySeconds／AvailabilityTimeoutSecondsを参照し、今回は値を変更していない。

Editプロパティの再適用記録は `tools/ApplyBoostUnavailablePresentation.luau`。対象PlaceとEditを確認してから既存Guiの上記プロパティだけを更新する。Source更新だけでは残る古いEdit表示にも適用済み。ボタンAutoButtonColorは最初の比較対象プロパティ一覧に含まれていなかったため、最終監査の差分数は5項目であり、6項目の前後実測とは表記しない。

## 検証結果

| 区分 | 結果・証拠 |
|---|---|
| 修正前再現／修正後 | 実際のClient・Presentation・Styleを使用し、API・時刻・メニューを注入した独立試験。旧版で不可時の入口消失・Open拒否と60秒経過後の入口消失／古いWATCH ADを再現。新版で解消。`after_studio_tests.json` |
| 新UI試験 | 副本から再読込した最終Sourceで357アサーション通過。利用可能／不可／エラー／タイムアウト、60秒期限、可視中更新、5秒復帰、古い応答、Close後の視聴取消、連打、300秒終了、破棄・再Mountを確認 |
| 既存回帰 | 前回UI復帰111、receipt競合回復60、ブーストcore126の模擬アサーション通過。保存中に一回だけ受けたreceiptの復帰、重複防止、300秒、倍率＋1、パス併用を維持。`tests.json`（初期UI287件の記録も含む。最終UI件数は上記357） |
| 他画面イベント | OfflineRewards、Robloxメニュー、Shop／Inventory／Merge等の開閉イベントと応答の両順序。テストからRefreshAvailabilityを直接呼ぶだけの復帰ではなく、実制御のVisible／Menuイベントを使用 |
| Edit実描画 | 現在のStudioでaverage_windows、iphone_16_pro_max横画面、ipad_pro_M5_13in横画面を順次使用。実ClientのStudio制限で入口→Open→Unavailable→Closeを確認。実UIの文字TextFits、境界内収まり、腕の色、赤Xを確認。`edit_geometry.json` |
| ソース・保全 | 変更3 Source＋エディター内容がローカルと一致。他556 SourceとDisabled状態を保持。元のInstance総数228570で増殖なし。今回対象外の既存ローカル96ファイルのハッシュ一致。6 Luauファイルcompile成功。`studio_final.json` |

Edit描画確認はテスト用依存を注入した実UIコントローラーのOpen/Close操作であり、物理マウスクリック／タッチ、通常ゲーム起動からの実Playとは区別する。確認用GUI・接続はDestroyし、退避した元Guiを復元。端末シミュレーターはdefaultに戻した。実API・広告要求は0回。

実Playは未実施。現在の通常起動には本番プロフィール保存・通知等への経路があり、今回それらから隔離された起動を確認できなかった。無関係な多数のサービスを変更せず、独立模擬試験とEdit描画で検証した。公開環境の広告在庫・実API時間・実広告画面・実購入・実機タッチ・実参加／死亡復帰は未確認。模擬の属性更新や再Mountを実プレイヤー検証済みとは扱わない。

## 維持した範囲と提出

商品3733706770、配置28777229838999、300秒、訓練倍率＋1、永久Strengthパス併用、通常ショップ購入経路、サーバーreceipt・保存競合復帰・報酬計算は未変更。時間／デイリー通知の縮小・黄色表示、イベント、LV曲線、その他の編集を保持した。

調査時の最新origin/mainは `a0f0a5be040aaceace694e7e717c6918cb4df9d1`。既存ローカルHEAD `1e795c8ed3f61cc59cc43f57b39f99ea02b9414a` とインデックスを保持し、別インデックスで最新origin/mainを親に今回のファイルだけをcommitする方式。worktree・stash・reset・過去commitへの巻戻しは使用しない。通常push後、remote SHAと提出ファイルを照合する。

SPEC更新候補：UI_SPECの広告入口条件、Unavailable／Checking表示、可視中の可否更新、DEV_STATUSの検証区分。これらの文書は既存の未commit編集を持つため、今回は内容を混在させず本報告に確定仕様を記録した。残件は上記の公開環境／実機確認のみ。
