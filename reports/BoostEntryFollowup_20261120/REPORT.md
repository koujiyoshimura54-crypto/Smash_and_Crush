# 広告入口の重複・Treadmill倍率記号の修正（2026-11-20）

副本 PlaceId 126576845524886 / UniverseId 10765181857 に反映。Save／Publish・実Play・実広告・実購入は実施していない。既存編集を保持した未保存Edit状態で開いたまま。

## 広告入口

調査時のEditでは入口のScreenGuiは1個だった。実行時の生成順として、Client.MountがUIを作成した後からStarterGuiの同名テンプレートがコピーされる順序を、実際のClient／PresentationとネイティブInstanceで再現すると**2個**になった。ユーザーが目撃した実Playそのものの履歴は取得できていないため、観測済みの再現経路として記録する。

修正後はMount時にこのモジュール専用の同名ScreenGuiを整理し、Mount後のChildAddedでも遅れて来た余分なコピーだけを除去する。イベント接続のある本体を維持する。Workspace走査や毎フレームの削除処理は追加しない。Destroyで監視接続も解除する。別名のHUDには触れない。

前回のUnavailable、60秒キャッシュ更新、15秒タイムアウト、ユーザー操作による広告開始、300秒タイマー、診断は維持。

## Treadmillの「×」

現在の副本 `ReplicatedStorage.Config.TreadmillConfig` の表示関数2か所に、正常なU+00D7ではなく **U+FFFD と ~** の文字列が入っていた。Sourceとエディター内容はともに同じ破損。GitHubの最新コードは正常な「×」であり、相違はこの2文字列だけだった。破損が生じた操作・時点は不明。

`StarterGui.StrengthGui.LeftMenuClient` が実行時に `GetGainDisplayText()` を呼び、Multiplier／MultiplierShadowを書き換える経路がある。Editの既存Textが正常でも、この実行時更新で破損文字になる。公開版への接続・Source取得は行っていないため、公開版と副本が同一であるとは断定していない。

`GetDisplayText()` と `GetGainDisplayText()` の文字列をASCIIで記述できるLuauの `\u{00D7}` へ変更した。生成される表示は今までと同じ **×**（UTF-8 C3 97）。数値、倍率、周期、購入条件、World判定、表示の色・寸法は変更していない。

## 変更Full Path

| Full Path | Gitファイル |
|---|---|
| ReplicatedStorage.Modules.RewardedStrengthBoostClient | src/ReplicatedStorage/Modules/RewardedStrengthBoostClient.luau |
| ReplicatedStorage.Modules.RewardedStrengthBoostPresentation | src/ReplicatedStorage/Modules/RewardedStrengthBoostPresentation.luau |
| ReplicatedStorage.Config.TreadmillConfig | src/ReplicatedStorage/Config/TreadmillConfig.luau |

変更前の実Sourceは `before.json` に保全。元のGUIプロパティは今回変更していない。

## 確認した範囲

- 最終Studio Source／エディター内容とローカル3ファイルが一致。再読込したSourceで模擬試験を実施。
- 遅いテンプレート追加：旧版2個 → 修正版1個。3回繰り返しても本体を維持。破棄後に監視が残らず、2個残った状態で再Mountしても1個になる。別HUDは保持。
- 実UIコントローラーでUnavailable画面の開閉ができ、広告開始要求0回。既存可否UI試験を含む380アサーション通過。
- 全7設備について「×1／×2／×3／×7 Strength」、日本語／英語Locale引数、文字コードC3 97を確認。表示以外のConfig値の一致を含む93アサーション通過。World2の生成元は既に正常で変更不要。
- Editプレビューでも遅い同名コピーを追加し、1個だけになること、Open／Close、文字TextFitsを確認（`edit_gui.json`）。これは注入した依存とコールバックによるEdit確認であり、実Play・物理クリック・実タッチではない。
- プレビュー・一時Instance・接続は除去し、元のGUIを復元した。確認用画像は削除し、保管していない。今回レイアウト変更はなく、全端末の再確認は行っていない。

実Play、実広告、実購入、公開環境での修正後表示は未確認。前回と同様に本番保存等から隔離された通常起動を確認できていないため、実Playは開始していない。今回のSource変更は未保存・未Publishであり、稼働中の公開版へはまだ反映されない。

最新origin/main `e493b3b9dddd47e11186253cdd83ef616262cb0f` を親に今回分だけ提出する。既存ローカルHEADとインデックスを維持する従来の別インデックス方式を使用。reset／stash／別worktree／force pushは使用しない。

SPEC更新候補はUI_SPEC／DEV_STATUSの広告入口の生成管理と今回の検証記録。既存の未commit文書編集と混在させず、本報告に記録した。
