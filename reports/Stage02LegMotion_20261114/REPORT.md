# World1 Stage2 Boss：脚の動作幅を1.5倍

2026-11-14。正本Studio PlaceId **126576845524886** / UniverseId **10765181857**、Edit PlaceVersion **627**。開始時main/origin/mainはStage1実装 `632586c89308094564b9db78d5f10fd610a5ebc4`。公開版の更新ではない。

Stage2の既存Walkの脚だけを約1.5倍に拡大した。体・頭・尾のアニメーション、Idle/Walkの速度・周期、Scale、独立した浮遊、HP・当たり判定・移動・旋回・攻撃設定を保持。Stage1のBone名・中心姿勢・GroundFitは流用していない。

## 現行確認と対象の特定

開始時は正本Editで、ユーザーPlayは停止していない。Stage02AppearanceClient、EnemyManager、World1BossPresentationのSource/Editorはローカルmainと一致。既存未保存Studio、Stage1の3 Source、既存未追跡報告書を保持した。古いPlaceIdより今回指定を優先した。

実テンプレートは `ServerStorage.EnemyTemplates.Stage02Boss.TralaleroTralalaRig`。Scale **1.75**、2 MeshPart、18 Bone。見た目の脚はBone名の `Arms` に対応するので、名前だけで腕と判断していない。実Rigの階層、静止姿勢、Walkキー、Play中のBone位置とメッシュ描画を照合した。

| 対象 | 実値・役割 |
|---|---|
| `Stage02Idle.AnimationId` | `rbxassetid://132887057767342`、2.8秒、57 Keyframe、UpTorsoのみ動く |
| `Stage02Walk.AnimationId` | `rbxassetid://85312619327964`、1.05秒、41 Keyframe、18 Boneにキー |
| 実再生Track | Idle（Track名Animation）/ Priority Idle、Stage02Walk / Priority Movement。双方Speed1・Weight1・ループ、計2本 |
| `FakeRootPart.UpTorso.Arms.L` / `.Arms.L.001` | 左前脚の上部関節・下部関節 |
| `FakeRootPart.UpTorso.Arms.R` / `.Arms.R.001` | 右前脚の上部関節・下部関節 |
| `FakeRootPart.Arms.L.002` / `Arms.R.002` | 前脚2本の独立した足制御。各子 `.003` は一定で補正しない |
| `FakeRootPart.UpTorso.007` | 独立した後ろ足制御。子 `UpTorso.005` は一定で補正しない |
| `UpTorso`・Head・Mouth・残るUpTorso系 | 身体/頭/尾など。変更しない。静止キーの関節も変更しない |

Movement WalkがWeight1でUpTorsoにもキーを持つため、表示はWalk側の姿勢が優先される。Idleの動きへ乗算する方法にはしていない。元のBone.CFrameに含まれる脚の開き・長さ・向きは一切変更しない。Walkの中心姿勢は41キーの時間間隔で重み付けした位置平均・符号を揃えたQuaternion平均から求めた。Stage1の中心は使っていない。

## 変更Full Path

| Full Path | 内容・理由 |
|---|---|
| `ReplicatedStorage.Config.Stage02LegMotionConfig`（新規） | Stage2専用 `Amplitude=1.5`、Rig名、Walk ID、7対象関節の正確な階層と中心姿勢。`1.0` で元の振り幅へ戻る。 |
| `ReplicatedStorage.Modules.Stage02LegMotion`（新規） | 7 Boneの局所変動分のみを補正。接地、Root、Weldには書き込まない。 |
| `StarterPlayer.StarterPlayerScripts.World.Stage02AppearanceClient` | 既存Rig追跡・破棄・非表示時のreleaseへ補正のMount/cleanupを接続。Bone交換時に古い補正を解放し、揃った後に再Mountする。 |

リポジトリは `src/` 以下の同じ階層（クライアントは `.client.luau`）。テンプレート、AnimationId、EnemyManager、World1BossPresentation、Stage1の3 Source、World1BossConfigは変更していない。

回転は `centerRotation * rotationDelta^Amplitude`。中心からの角変位だけを1.5倍にする。前脚の上部/下部は局所回転のみ、独立足制御3本は中心からの移動と回転を拡大する。一定の子Boneや親のWorld変換を再増幅しないので、足先だけ2.25倍になる処理はない。足の固定位置は中心として維持し、単純なTransform全体の乗算にしない。

毎PreAnimationに保存した**補正前**の姿勢へ戻し、PreSimulationで新しいAnimator出力を読み直す。Animator評価が間引かれても前回補正を入力にしない。Walkが読み込まれ、再生中・Weight>=0.999になってから適用する。未到着Boneでは接続を作らず既存Bindingのrefreshを待つ。途中でBoneが外れた場合も古い参照を解放して再評価する。cleanupは冪等で、2接続を切り、補正前の姿勢を戻す。

**浮遊処理は全文一致で維持**した。`FLOAT_AMPLITUDE=0.3` / `FLOAT_PERIOD=3` / `FLOAT_BASE_LIFT=0.3`。新Moduleは `Stage02VisualRootWeld` に書き込まず、GroundFit/raycastもない。EnemyManagerのStage2配置offset2.7も変更しない。

## 前後の実測と実描画

数値は隔離ネイティブPlay、同じ個体、Scale1.75、両Track Speed1、既存浮遊を動かしたまま、各約3.216秒・193 PostSimulation標本。足先の移動はFakeRootPart基準で測り、全身浮遊を脚の移動幅へ混ぜていない。角度は各周期中心からの最大角変位、距離は最大−最小。標本位相により丸め差がある。

| 測定 | 1.0 | 1.5 | 比率目安 |
|---|---:|---:|---:|
| 左/右前脚上部の角変位 | 14.973° | 22.459° | 1.500 |
| 左前脚下部の角変位 | 4.493° | 6.740° | 1.500 |
| 右前脚下部の角変位 | 4.455° | 6.683° | 1.500 |
| 左足制御の角変位 | 16.478° | 24.716° | 1.500 |
| 右足制御の角変位 | 16.438° | 24.656° | 1.500 |
| 左足先の前後幅 | 2.05009 studs | 3.07513 studs | 1.500 |
| 右足先の前後幅 | 2.04978 studs | 3.07464 studs | 1.500 |
| 後ろ足の角変位 | 0.698° | 1.047° | 約1.5 |
| 後ろ足の左右幅 | 0.18302 studs | 0.27453 studs | 1.500 |
| 左足先の上下幅 | 0.15029 studs | 0.22544 studs | 1.500 |
| 後ろ足の上下幅 | 0.06267 studs | 0.09400 studs | 1.500 |
| 全身浮遊Weldの上下幅 | 0.599969 studs | 0.599965 studs | 維持 |

同位相0.23秒で脚以外の11 Boneを比較し、位置差/角度差0。1.5から1.0へ戻した全18 Boneも元の姿勢と一致した。

実描画は1390×601のStudio Play。カメラ位置 `(308.799988,11.520892,317.839996)`、同じ向き、同じモデル位置・Scale、Walk位相0、両Track Speed0で前後を比較した。**この静止比較だけ**検証fixtureで既存浮遊の現在のWeld値を固定し、同じ高さで比較した。製品コードにはこの固定処理を入れていない。その後固定を解除し、Speed1と本来の浮遊で数値測定・20周再生・実戦闘・再出現を確認した。

前脚の振りと歩幅が広がり、確認した視点/位相/通常再生・戦闘中の描画で極端な床埋まり・脚の交差・メッシュ破綻は見られなかった。元からある全身浮遊は続いており、足を地面へ固定する変更ではない。画像は一時確認のみで保存/commitしていない。生の集計は [evidence.json](evidence.json)。

## 検証結果

| 区分 | 内容・結果 |
|---|---|
| 実Play：非累積 | 通常Speed1で21.0156秒＝Walk約20.0149周。前後を同じ位相0.23秒へ戻すと全18 Boneの12成分の最大差0。描画フレーム2215→2532。 |
| 数値誤差の扱い | CFrame相対角は0.0006905radを返したが、同じCFrameと自分自身の比較でも同じ値。行列成分は完全一致しており、実際の姿勢ずれではない。単純な角度値だけで累積と判断していない。 |
| 実Play：戦闘 | 隔離メモリのLV8/Strength360、既存StartRun(2)・壁破壊経路で準備。Boss戦開始、既存手動攻撃でGauge1800→1440→0、CurrentStage3・戦闘終了を確認。通常戦闘ロジックを使用したが、自然育成・実機手操作ではない。 |
| 実Play：帰還・再出現 | Back→新しいStage2 Rigで再生。旧Rig/AnimatorはParentなし、旧TrackはIsPlaying=falseで時刻が1秒後も停止。新RigのTrackは2本、Speed1。 |
| 旧Track照会の注意 | 破棄済みAnimatorのGetPlayingAnimationTracksは保持参照として2件を返した。件数だけで再生中とは扱わず、IsPlaying=false・時刻停止・Parentなしを確認した。 |
| 実クライアント経路＋模擬非表示 | 既存Binding.SetVisible(false/true)を検証fixtureから呼ぶ。非表示でTrack0、浮遊Weldが元値へ復帰、再表示でTrack2。自然な距離離脱の代用とは区別する。 |
| 実クライアント経路＋模擬未読込 | 左足制御Boneを一時的に外して戻す。エラーなし、Track2を維持。復帰後の7関節は1回だけの1.5倍計算と全成分差0。自然なネットワークstreamingの検証ではない。 |
| 模擬境界 | 実Module Source・実一時Instance・fakeフレーム信号で64 assertions通過。600回のAnimator更新なしでも非累積、固定中心、1.0復帰、Fade中待機、脚以外/Root/Weld保持、接続解放、Bone欠落/到着、別World/Stage/Rig/Clip除外。 |
| 静的・同期 | 製品3＋テスト6 SourceのLuau構文検証通過。既存浮遊関数全体の一致。最終9 Source/Editor/ローカル一致。テンプレート18 Boneの階層/CFrame/Transform、Scale/2 IDも開始時と一致。 |

サーバーの実値も維持：HP1800、ChaseSpeed16、ChaseTurnResponse5、戦闘RootY8、外観Weld C0.Y=1.921709、Collider寸法16.913128×11.244787×21.018574・中心Y11.371885、CombatZone寸法26.913128×14×31.018574・中心Y12.749492。攻撃周期のSourceには差分がない。

## Runtime・未確認事項

最終Playで今回の3 Sourceに由来するRuntime Error / Warning / Infinite Yieldは観測していない。既存の別アセット `119910397965139` の権限警告3件、隔離BadgeServiceがfalseを返したFirstSmash通知1件、StudioツールによるCameraType復元ログを区別して記録する。Stage2 Idle/Walkのロード失敗はなかった。

今回は描画フレームが進む状態で比較・戦闘・再出現を実施できた。Stage1等で発生した過去の描画停止の原因が今回解決した、とは判断しない。

実機スマホ/タブレット、公開環境、自然なネットワークstreaming、全負荷・長時間・全視点は未確認。他Stage/World2は適用除外と維持Sourceの照合で確認し、全Bossを再戦してはいない。模擬フレームの600回確認は、実端末でのAnimator負荷間引き再現とは区別する。

## 後片付け・提出

既存 `tests/FirstBattleTutorial/InstallIsolation.luau` でDataStore/Marketplace/Badge/Messaging/Policyをメモリ等へ39件差し替えた隔離Play。本番データや購入処理へ検証用操作をしていない。停止したのは今回開始したPlayのみ。

39 Sourceの現在値を保存済み差し替え文と照合して原文へ復元。QA Folder/ServerScript/LocalScript、メモリ/backupを除去。Play中のみのLifecycle補助も終了時に除去された。最終補助検索0、正本は**未保存Edit**。Save/Publish・保存GUI操作なし。Stage1と既存編集、既存未追跡 `reports/Visual_Templates_Secret_VIP_Green_20260917.md` を保持し、PR #1は操作していない。

再現用fixtureと手順は [tests/Stage02LegMotion](../../tests/Stage02LegMotion/README.md)。今回の製品3 Source・検証・報告書・関連仕様記録だけを通常commit / origin/mainへ通常pushする。Placeの保存・公開はユーザー本人の手動操作に委ねる。
