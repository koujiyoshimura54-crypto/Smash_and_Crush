# 時間報酬・デイリー報酬の通知バッジ縮小

2026-11-20。副本 PlaceId **126576845524886** / UniverseId **10765181857**。

2つの通知「！」を最終描画の縦横 **50%** に縮小し、各報酬ボタンの右上に重ねた。報酬アイコン本体、文言、色、表示条件、報酬処理、クリック領域、他の通知は変更していない。副本の Source と Edit プロパティへ反映済み。Save / Publish / Play は行っていない。

## 変更箇所・手動調整

| Full Path | 変更 |
|---|---|
| `ReplicatedStorage.Config.RightHUDStyle` | `RewardBadgeSizeRatio=.5` を追加。今回の2つだけの倍率。 |
| `ReplicatedStorage.Modules.RightHUDPresentation` | `Layout` 内の `RewardBadgeScale` に上記倍率を一度だけ適用。X位置を親の右端 `UDim2.new(1,0,0,…)` に固定。Y位置は半分にした画像の回転最大範囲から算出して切り上げ。 |
| `StarterGui.StrengthGui.LeftMenu.TimeRewardsButton.NotificationBadge.RewardBadgeScale` | `Scale: 2.7288167476654053 → 1.3644083738327026`（現在のEdit配置）。 |
| `StarterGui.StrengthGui.LeftMenu.DailyRewardsButton.NotificationBadge.RewardBadgeScale` | 同上。 |
| `StarterGui.StrengthGui.LeftMenu.TimeRewardsButton.NotificationBadge` | `Position: {0,83},{0,60} → {1,0},{0,29}`。 |
| `StarterGui.StrengthGui.LeftMenu.DailyRewardsButton.NotificationBadge` | 同上。 |

対応ファイル：`src/ReplicatedStorage/Config/RightHUDStyle.luau`、`src/ReplicatedStorage/Modules/RightHUDPresentation.luau`。Editプロパティを再適用する記録は [`tools/ApplyRewardBadgeHalf.luau`](../../tools/ApplyRewardBadgeHalf.luau)。同じ処理を2回実行し、再縮小されないことも確認した。これは元のEdit補償値を記録した限定再適用用で、任意に編集された補償値は上書きせず停止する。

サイズの調整は `RewardBadgeSizeRatio`、位置の調整は `RightHUDPresentation.Layout` の通知位置式で行う。共通 `BadgeRenderer` の `Scale=1.5`、画像、色、3秒周期・0.4秒間・±10度の動きはそのまま。旧アイコン縮小を補償する `oldRightScale / scale` に `.5` を一度だけ掛け、画像サイズに二重適用しない。X座標は親右端へ追従し、Y座標の切り上げは整数座標化で上端が欠けるのを防ぐ。

## 比較画像・実測

**StudioのEdit描画**を撮影。通知の表示条件を本番データで操作せず、スクリプトを除いた一時GUIコピー上で通知を表示した。実際の `HUDLayout` / `RightHUDPresentation` / `BadgeRenderer` を使用。アニメーションは既存処理へ模擬時間を渡し、通常・+10度・−10度を同じ時刻で比較した。

| 端末プリセット・横画面 | GUI描画領域 | 変更前の画像一辺 | 変更後の画像一辺 | 縦・横比 |
|---|---:|---:|---:|---:|
| 一般的なWindows | 1365×768 | 30.8981 px | 15.4491 px | 0.5000 |
| iPhone 16 Pro Max | 831×439 | 24.6127 px | 12.3063 px | 0.5000 |
| iPad Pro 13-inch (M5) | 1375×1030 | 30.9998 px | 15.4999 px | 0.5000 |

両バッジとも同値。数値は `NotificationImage.AbsoluteSize` のGUI座標。StudioのFitToWindow表示倍率や物理ディスプレイのピクセル数とは別。回転した外接範囲も縦横50%。最大回転時の上端余白は0.1887～0.2182 px、右端余白は3.0220 px以上。画像はアイコン右上に重なり、相互のバッジ・隣の報酬ボタン・購入バナーとの重なりはない。Studioの座標キューブはエディタ表示であり、ゲームHUDではない。

| 画面 | 通常・前 | 通常・後 | +10° 前／後 | −10° 前／後 |
|---|---|---|---|---|
| PC | [画像](images/pc_before_normal.png) | [画像](images/pc_after_normal.png) | [前](images/pc_before_plus10.png) / [後](images/pc_after_plus10.png) | [前](images/pc_before_minus10.png) / [後](images/pc_after_minus10.png) |
| スマホ | [画像](images/phone_before_normal.png) | [画像](images/phone_after_normal.png) | [前](images/phone_before_plus10.png) / [後](images/phone_after_plus10.png) | [前](images/phone_before_minus10.png) / [後](images/phone_after_minus10.png) |
| タブレット | [画像](images/tablet_before_normal.png) | [画像](images/tablet_after_normal.png) | [前](images/tablet_before_plus10.png) / [後](images/tablet_after_plus10.png) | [前](images/tablet_before_minus10.png) / [後](images/tablet_after_minus10.png) |

拡大比較は [REPORT.html](REPORT.html)。画像は既存StudioをWindowsの読み取り専用 `PrintWindow` で取得。Studio MCPの画像取得が応答しなかったため撮影方法を切り替えた。新しいアプリ起動、GUIのクリック、Save / Publishは行っていない。

## 検証と保持

- [`measurements.json`](measurements.json)：3画面×変更前後×3角度の実測。`python tests/RewardBadgeHalfEvidence.py` でサイズ比、回転角、アイコン本体の完全一致、角への接触、画面内収容、装飾の非入力性など360件の幾何検査に合格。
- 表示条件とアニメーションのSourceは変更していない。報酬クライアント・受取処理・クリック接続は今回実行していない。
- [`studio_final.json`](studio_final.json)：559 Source中、今回の2本以外557本をSource・編集バッファとも保持。広告修正も保持。StarterGui内13,673オブジェクトを比較し、差分は2バッジのScaleとPositionの4プロパティだけ。
- 一時GUI・接続を破棄し、Instance数 **228,570 → 228,570**。通知Visibleは元のfalseへ復元し、強制表示は残していない。端末シミュレーションは開始前の `default` に戻し、検証用sharedデータも除去。
- 反映後の2本を再取得し、ローカルSource・Studio Source・編集バッファの一致を確認。対象Module末尾の余分な空行だけはGitの空白検査に合わせ整理した。
- 既存のローカルmainは古い履歴で未保存差分もあるため、チェックアウトやstashを使わず、最新origin/mainを親とする別Git indexで今回分だけをコミット。既存main・通常index・既存編集は保持。広告修正 `dc6164745c5eba38e9a7ff06f9ed0e13ca50b09d` を親にして通常push。

## 未確認・残件

実Play、実機のPC／スマートフォン／タブレット、実タッチ、実際の報酬受取は未確認。Edit描画・模擬時間の確認を実機／実Play合格とはしていない。OS・Robloxメニューのすべての状態や端末の全機種を網羅する検証ではない。

既存のUI_SPEC / DEV_STATUSには「小型化前の通知サイズを維持」という旧仕様がある。今回の明示指示で2報酬通知だけ50%に変更。これらの文書は今回以前の編集を含むため変更せず、本報告を更新候補・確定仕様の記録とした。

副本Studioは**開いたままの未保存Edit状態**。今回分以外のファイル・PR #1・正本・公開状態は変更していない。

端末シミュレーターAPIの確認資料：[Roblox公式 StudioDeviceSimulatorService](https://create.roblox.com/docs/reference/engine/classes/StudioDeviceSimulatorService)。実測値は上記の自前取得データによる。
