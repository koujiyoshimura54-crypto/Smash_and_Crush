# Premium Treadmill — 指定開始日時から24時間

2026-11-19。副本PlaceId 126576845524886 / UniverseId 10765181857、既存StudioのEditに反映。基準mainはa2cffc2。開始時の追跡変更なし、既存crashes/は操作しない。

## 最終設定・意味

設定場所：`ServerScriptService.Config.World1PremiumTreadmillEventConfig`

```lua
Enabled = true,
EventDateJST = "2026-11-19",
EventStartTimeJST = "22:00", -- HH:MM、24時間表記（00:00〜23:59）
StartIntervalSeconds = 1800,
OpenDurationSeconds = 180,
```

Studioだけに入力されていた2026-11-19を保全。開始時刻追加後にユーザーが入力した22:00も、最終の保存反映指示に従って保持しGitへ反映した。開始期間は2026-11-19 22:00 JST以上、2026-11-20 22:00 JST未満。[変更前Source](before.json)。

指定の日本時間開始日時を含み、ちょうど86400秒後（翌日の同時刻）を含まない。開始日時をUTCへ変換し、全サーバー・資格・ボード・上空の既存共通計算へ渡す。開催途中のJST 00:00では終了しない。

現在の22:00設定では初回22:00〜22:03、次回22:30〜22:33。最後の開放は翌21:30〜21:33、残る27分は上2行だけを表示し、翌22:00で全体非表示。

時刻の空欄・欠落・不正値は開催無効。24:00、23:60、1:00、秒付き、余白付き等を拒否する。午前0時開始は00:00を明示入力する。

現在はEnabled=true、開始日時設定は有効。期間中は3分開放/27分待機を繰り返す。停止はEnabled=false（または開始日時を空欄）。設定は起動時に読み込み、次のPlay/サーバー起動から反映。公開済みサーバーへの即時反映はしない。

## 変更Full Path

- `ServerScriptService.Config.World1PremiumTreadmillEventConfig`：開始時刻欄とコメント、承認済みのStudio日付をGitへ反映。
- `ReplicatedStorage.Modules.World1PremiumTreadmillEventSchedule`：HH:MMの厳密検証、日付＋時刻をUTCへ変換。終了は開始＋86400秒。
- `ReplicatedStorage.World1PremiumTreadmillEventState`：既存表示用JSONを現行設定から再計算し、StartTimeUnsetへ更新。

TrainingManager、Strength計算、所有/購入経路、表示Style・描画Sourceは変更していない。内部の互換名InEventDayは、指定開始時刻から24時間内かどうかを表す。

以前の「指定日00:00〜翌00:00」という説明は今回の仕様に置き換える。前回の[公開対応報告](../PremiumTreadmillPublicEvent_20261119/REPORT.md)は当時の記録として保持する。

## 検証

反映後のStudio SourceとEditor内容を再読込し、ローカルとの一致と構文を確認。[結果](verification.json)。

- 日時計算91項目：18:45開始のUTC変換、＋24時間、JST日付変更をまたぐ継続、閏年の月末、年末23:59開始、開始直前/一致/直後、終了直前/一致、不正時刻・未設定。
- 既存TrainingからStrength/メモリ更新までの隔離模擬283項目：18:45起点で180秒/1800秒の境界、24時間終了、正規/無料利用の同条件一致、購入要求抑止、既存排他を確認。
- GUI InstanceとクライアントRuntimeの隔離fixture32項目：18:45起点でボード/上空の同期、表示境界、最終待機、対象再出現・後始末を確認。

エージェントによる実Play・実乗車・実端末・公開サーバー検証は未実施。最終確認中に一時的なPlayモード応答があったが、開始/停止は操作せず、実動作の確認済みとは扱わない。前回同様、保存なしの安全なPlay隔離が未確認であり、実Playerデータ・DataStore・実購入にはアクセスしていない。試験時刻18:45はfixtureのみで、製品設定22:00はユーザー指定値。

通常pushの対象は今回の差分だけ。既存の未保存編集を保持したEditでStudioを開いたまま。エージェントによるSave/Publish、Play/Stop、Creator Hub公開、通知送信なし。手動公開前には開催日時の最終確認と、安全な実Playでの乗車・終了・購入画面確認が残る。
