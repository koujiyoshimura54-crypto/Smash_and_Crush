# 歩行音の実移動判定 — 2026-11-16

対象は副本 PlaceId `126576845524886` / UniverseId `10765181857`。接続IDを確認して作業した。Save / Publish、保存GUI、正本、PR #1は操作していない。Studioは検証補助を除去した未保存Edit状態。

## 変更箇所と原因

製品変更Full Pathは **`StarterPlayer.StarterPlayerScripts.World.MovementSoundClient`** の1本。Git側は `src/StarterPlayer/StarterPlayerScripts/World/MovementSoundClient.client.luau`。このパスは従来srcに未収録だったため、現在StudioのSourceを基に修正して追加した。古い監査保存物で現在Sourceを上書きしていない。比較開始時のorigin/mainは `62d93a85d41aed9d51e3eb5d22fe7f9647b6fcf2`。

現在Studioと実Playで、次の3経路を区別した。

| 発生元Full Path | 実行時Sound / 現在の動作 |
| --- | --- |
| `StarterPlayer.StarterPlayerScripts.World.MovementSoundClient` | `SoundService.Creamy Keyboard Typing Free`。91656373864470、Volume 0.1、PlaybackSpeed 1.2、ループ。歩行中に再生していた |
| `Players.<LocalPlayer>.PlayerScripts.RbxCharacterSounds`（Roblox標準の自動挿入） | `Workspace.<Character>.HumanoidRootPart.Running`。action_footsteps_plastic.mp3、Volume 0.65、PlaybackSpeed 1.85。歩行中に上記と並行再生していた |
| `StarterGui.StrengthGainGui.StrengthGainClient` | StrengthGain通知から `Players.<LocalPlayer>.PlayerGui.StrengthGainGui.SoundPool` のKeyboard Click系を再生。現在のコード上の音量は0で、実Playでも0。歩行入力の処理ではない。変更していない |

変更前の独自音も、キー押下だけを直接見ていたわけではない。接地・入力・生存等に加えてAssemblyLinearVelocityの水平成分を判定していた。ただし実位置の推移は見ておらず、標準Runningも速度と入力で独立再生していた。この2経路へ実変位による共通の停止条件を適用した。変更前の通常体型・壁静止の短い計測では誤再生を再現できなかったため、「修正前に常に壁で鳴った」とは断定しない。

## 修正内容

- 生存、地面上のRunning / RunningNoPhysics、MoveDirection > 0.05、移動可能な状態を必須にする。端末・キー種別による分岐は追加しない。
- Rootの約0.12秒間の水平純変位を計測。開始0.8 studs/s、継続0.35 studs/sとし、微小な往復揺れと閾値付近の断続を抑える。
- 停止入力、空中への状態変化、FloorMaterial=Air、死亡はイベントでも停止。着地後は移動実測を再開する。
- 1フレームの位置変化が `max(1.5, WalkSpeed × dt × 2)` を超えた場合、配置revision・World変更時は計測をリセットし、0.2秒待つ。dt > 0.25秒の停滞も計測から除外する。
- 標準Runningにも同じ停止条件を適用。標準のJumping / Landing / Died等、音源、音量、再生速度は変更しない。
- Character / Humanoid / Rootの交代時は古い接続を解除。死亡復帰後も独自Soundは1個。Script破棄時も接続と生成Soundを片付ける。

SE / BGM音量、Strength加算、Treadmill、体型、移動速度、保存処理の製品変更はない。

## 実Play検証

副本の実Playで、実Character・物理衝突・Humanoid状態・Sound.IsPlayingをHeartbeatごとに観測した。PC操作はStudio入力ツールによるW / D / Space入力。壁はPlay中だけの衝突Part、Treadmillは実物 `Workspace.Treadmills.Normal01`。死亡は実Humanoid.Health=0から既存復活処理を通した。Lobby帰還は既存LobbySpawnService.MoveToLobbyを呼んだ。テレポート試験だけはPlay中に10 studsの位置変更を注入した。

DataStore、購入、Badge等の外部依存は一時メモリアダプタへ隔離。本番DataStore・実課金は使っていない。物理・歩行音・既存生成/復帰・Treadmillの実行を模擬計算に置き換えた検証ではない。

以下の「再生」はSound.IsPlayingの観測であり、耳で聞いた確認ではない。

| 条件 | 通常体型 | 最大Body |
| --- | --- | --- |
| 歩行→ジャンプ→着地→停止 | 361標本、水平移動27.16 studs。歩行時両音再生、空中/入力なしの再生標本0 | 361標本、27.30 studs。同条件0 |
| Wを壁へ押し続ける | 進入後の壁静止83標本、両音再生0 | 壁静止52標本、両音再生0 |
| Treadmill上のその場足踏み | Training=true 121標本、変位0、両音再生0 | Training=true 121標本、変位0、両音再生0 |
| 死亡→Character一時不在→復帰 | 約11秒654標本、両音再生0、復帰Health100、HeightScale1 | 約11秒653標本、両音再生0、復帰Health100、HeightScale2 |
| 復帰後に再び歩行→停止 | 15.96 studs移動、両音32標本で再生、停止後false、独自Sound1個 | 16.00 studs移動、両音33標本で再生、停止後false、独自Sound1個 |
| W入力中の位置ジャンプ | 未実施 | 位置変更直後0.03〜0.18秒の9標本で両音再生0、その後の実歩行で再生 |
| W入力中のLobby帰還 | 未実施 | 配置revision変更直後の9標本で両音再生0、その後の実歩行で再生 |

通常/最大は既存体型設定で準備し、最終歩行・復帰ではHeightScale 1 / 2を確認した。通常Treadmillは通常体型で開始したが、実トレーニングによる成長は止めていない。通常壁・通常Treadmillは同じ変位判定を実装した段階の計測であり、その後の変更は状態/入力/接地イベントによる即時停止の追加。最終版で通常/最大の歩行・ジャンプ・停止・死亡復帰、最大壁/Treadmillを確認した。

初版の観測では空中移行・入力解除に1標本の遅れがあり、即時停止を追加。最終歩行試験では該当標本の再生0。検証用コードのPlayerModule待機、Character不在中のnil参照は補助側で修正し、対象試験をやり直した。Humanoid:Moveだけで実移動しなかった試行は歩行成功に含めていない。

最終PlayのConsoleでMovementSoundClient由来の実行エラーは確認していない。別アセットの権限/承認ログは残る。119910397965139の権限警告に加え、終了後に取得したログには17387207972、89137136456777、139190015780830、95256658378010、7221927873、82687933211372、16909595683、18210292572の権限/承認警告、およびMCPのCameraType復元通知がある。歩行音91656373864470の警告ではなく、今回それらのアセットを変更していない。

## 現在の音量調整場所（変更なし）

| Full Path / 設定 | 現在値・役割 |
| --- | --- |
| `StarterPlayer.StarterPlayerScripts.World.MovementSoundClient` → `MOVEMENT_SOUND_VOLUME` | **0.1**。独自歩行音 |
| `Workspace.<Character>.HumanoidRootPart.Running.Volume` | **0.65**。実PlayのRoblox標準歩行音。標準RbxCharacterSoundsが生成 |
| `StarterGui.StrengthGainGui.StrengthGainClient` → `STRENGTH_GAIN_SOUND_VOLUME` | **0**。Strength加算通知音 |
| `StarterGui.StrengthGainGui.SoundPool.Keyboard Click`、`Keyboard Click2`、`Keyboard Click3`、`Keyboard Click4` → Volume | 編集テンプレートは **10**。実行時は上の定数によって0になる |
| `SoundService.UI.Click` / `Error` / `Notification` / `Cash` / `Success` / `Winner` → Volume | 各 **0.75** |
| `SoundService.UI.Hover.Volume` | **1**。現在の既存編集を保持 |
| `SoundService.WallBreak.Volume` | **0.9** |
| `ReplicatedStorage.Config.UISoundConfig.CoinCollect.Volume` | **0.55**。実行時 `SoundService.CoinCollectFeedback`。使用元 `StarterPlayer.StarterPlayerScripts.UI.TrophyRewardFeedbackClient` |
| `ReplicatedStorage.Config.UISoundConfig.Added` | Click 0.65、Rebirth / Offline / Merge 1.3、Sale / Purchase / WinReward / Reward 1、Denied / Level 0.8。Hover欄0.15は存在するが現行コメントではSoundService.UI.Hover側を正本とする |
| `StarterGui.LevelUpGui.ResponsiveEffect.LevelUpEffect.Level_up.Volume` | **0.5** |
| `StarterPlayer.StarterPlayerScripts.Services.SoundClient` | SoundService.UI配下とWallBreakの既存音量を保持し、SE切替時に0/元値へ変更する。数値一括の主音量設定ではない |
| `Workspace.Sounds.Sound.Volume` | **0.07**、音源89468328910114、Looped=true。実Playで再生中のBGM |
| `SoundService.Music.Classic Easter.Volume` | **0.5**、音源83679816707559。観測時は停止 |
| `SoundService.Music.Fun And Games (Sleigh Bells Version).Volume` | **0.5**、音源134468436646618。観測時は停止 |
| `StarterPlayer.StarterPlayerScripts.Services.MusicClient` | SoundService.Music内のSoundを使用し、setEnabledでPause/Resume。Volumeの上書きなし |

## 保持確認・未確認範囲

- 一時差し替え39 Sourceを、書換え後の内容との一致を確認して復元。補助3オブジェクト、メモリアダプタ、復元用オブジェクトを除去。Play専用の衝突壁も残存0。
- 作業前511 SourceについてSourceとScript Editor内容を照合。製品変更1本、その他510本一致。ゲーム内Sound/SoundGroup 74個の音量とSoundIdは作業前と一致。別枠のPluginGuiService内Sound1個はゲームの変更対象外。
- ローカルに新規フォルダー、画像、音声、スクリーンショット、重いバックアップは作成していない。成果物は既存ディレクトリ内の製品Source、本報告、関連SPEC/進捗/履歴のみ。
- **実際に音を聞く確認は未実施**。Sound.IsPlayingと音量の観測から聴感・瞬間的な音漏れを完全保証しない。
- **スマホ/タブレット実機タッチ、物理ゲームパッドは未確認**。キーに依存しない共通Humanoid条件を静的確認した。仮想Thumbstick入力試行はMoveDirection=0、移動0のままで、ゲームパッド成功に数えていない。
- 現在の標準音はSound。AudioPlayer分岐は実行されておらず未確認。公開環境、低FPS/通信遅延の全条件、全テレポート経路、全Body段階の網羅確認ではない。
- 微小揺れを避けるため0.8 studs/s未満の低速移動では再生開始しない。明示的配置通知がなく、1フレーム閾値未満の小さな位置変更は通常移動と完全には区別できない。

この報告は、確認した条件での結果であり、全環境で不具合がないという宣言ではない。
