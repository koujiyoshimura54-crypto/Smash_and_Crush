# 時間報酬・デイリー報酬アイコンを黄色系に変更

2026-11-20 / 副本 PlaceId 126576845524886、UniverseId 10765181857。

2つの入口アイコン内側の背景をピンク系から黄色・ゴールド系へ変更。時計・カレンダーの絵柄、黒い外枠、文言、位置、サイズ、前回縮小した通知「！」、報酬処理は維持。

## 変更箇所

- `ReplicatedStorage.Config.RightHUDStyle`：`RewardIconColors` を追加。上部 RGB **255,245,150**、中央 **255,216,55**、下部 **232,164,20**。手動で色を調整する場所。
- `ReplicatedStorage.Modules.RightHUDPresentation`：`ApplyRewardColors` を追加し、既存 `Layout` の2報酬ボタンにだけ適用。別の常時更新・接続は追加しない。
- `StarterGui.StrengthGui.LeftMenu.TimeRewardsButton` と `StarterGui.StrengthGui.LeftMenu.DailyRewardsButton`：それぞれ本体 `BackgroundColor3`、`InnerBorder.PopBackgroundGradient.Color`、`InnerBorder.UIStroke.Color` の3項目を変更。変更前後の全値は [verification.json](verification.json)。
- Editプロパティの再適用：[tools/ApplyRewardIconYellow.luau](../../tools/ApplyRewardIconYellow.luau)。Source設定を読み、色だけ反映する。Save / Publishはしない。

## 確認

[変更前](images/before.png) / [変更後](images/after.png)

現在開いている副本のEdit画面で黄色の背景を確認。対象2ボタンと全子要素のプロパティ比較では、差分は上記6色プロパティだけ。サイズ・位置・通知・画像・文字・クリック領域は一致。Instance数228,570のままで、追加Instanceや検証用接続はない。検証用shared退避データも除去済み。

2本のStudio Source・編集バッファ・ローカルファイルを一致確認。変更元は最新origin/main `4b843faa5dc40e1d9a1bf26e883806e382bfa100`。前回の通知変更・広告修正・既存の未保存編集を保持。

実Play・実端末での確認は未実施。色だけの変更のため、前回実施した端末別サイズ検証は再実施していない。報酬クライアントは変更・実行していない。

通常pushで今回分だけを反映。ローカルmainが古い履歴で既存編集を含むため、前回と同じ別Git index方式で最新origin/mainを親にし、元のHEAD・通常index・作業ツリーを保持。Save / Publishを行わず、副本Studioは開いたままの未保存Edit状態。

UI_SPEC / DEV_STATUSの追記候補：2報酬入口の内側は黄色系、通知「！」は既定色を維持。既存編集中の文書には今回は追記していない。
