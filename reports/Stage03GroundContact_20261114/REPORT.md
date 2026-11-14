# World1 Stage3 Bossの床埋まり修正

2026-11-14。Place126576845524886 / Universe10765181857、開始・終了時Edit PlaceVersion627。基準main/origin/mainは `fa679c7c15a3dcb3e91ee717d2d3f9972c010d81`。既存の未保存編集、Stage1/2の修正を保持した。

## 原因と修正

実Rigは `ServerStorage.EnemyTemplates.Stage03Boss.TungTungSahurRig`、Scale約2.8のR15。既存 `EnemyManager.attachStage03TungTungSahur` は静止BoundingBoxを非表示Floor上面Y4へ合わせる。一方、実通路 `Workspace.GeneratedMap.BattleCorridor.Stage03.Stage3.5.PathToRun.Upper` はY4.4000146。さらに既存WalkがLowerTorsoのRoot Transformを下げる（位相0.15秒でY=-1.27819）ため、歩行時の足が静止BBox基準より低くなっていた。

隔離Playで埋まりを再現し、足Partの回転を含む外接箱下端が通路より最大2.51954 studs低いことを確認。0.4 studsだけの固定持上げでは歩行中の埋まりが残る。

変更Full Pathは2件だけ。

| Full Path | 内容 |
|---|---|
| `ReplicatedStorage.Modules.Stage03GroundContact`（新規） | Stage3専用のR15足姿勢計算と外観側の高さ補正。 |
| `StarterPlayer.StarterPlayerScripts.World.Stage03IdleClient` | 既存Rig追跡・releaseにMount/cleanupを接続。 |

リポジトリは `src/` 以下の対応階層。Stage3のRoot→Hip→Knee→Ankleの実Motor6Dをたどり、PreSimulationで現在のAnimator Transformから両足の位置・向きを予測する。前フレームのPart.CFrameを基準にせず、保存した補正前Root.C0から計算する。Stage03の実WalkableGeometryとBoss区画のFloor/PathToRunにrayを当て、足下端が上向き面を下回る分だけ持ち上げる。

書込みは**クライアント外観Rigの `LowerTorso.Root.C0` の高さ**だけ。戦闘Root、外観HumanoidRootPart、Stage03VisualRootWeld、サーバーColliderを動かさない。脚の関節角度・Animator Transform・再生速度は変更しない。空中へ持ち上がる側の足まで地面に固定しない。非表示/破棄時は接続を切り、元C0へ戻す。未到着の関節は待ち、交換後に再評価する。

WorldId1 / StageNumber3 / TungTungSahurRigに限定。`Stage03GroundContact.Enabled=false` で補正前へ戻せる。Stage1のBone処理やStage2の浮遊は使用・変更していない。

## 実測と検証

同じ個体・カメラ・位置・Walk位相0.15秒で、変更前後の実描画を比較。従来床に隠れていた足が見えることを確認した。この静止比較では双方Track速度0、その後は既存のIdle速度1・Walk速度0.6へ戻して測定した。カメラ位置 `(304.430786,8.536248,420.497070)`、1390×601。

通常再生で各約3.217秒・193 PostSimulation標本。下表の差は足Partの回転を含む外接箱下端−実床面であり、負値が埋まり。個々のメッシュ頂点の測定ではない。

| 項目 | 補正前 | 補正後 |
|---|---:|---:|
| 両足を通じた最小床面差 | -2.519538 studs | -0.00000168 studs |
| 各フレームの低い側の足の床面差・最大 | -0.763670 studs | +0.00000296 studs |
| 高く上がる足の最大床面差 | -0.655115 studs | +1.148337 studs |
| 床ray欠測 | 0 | 0 |

同位相の全Motor6D.Transform成分差0。既存速度で8.400秒（Walk約8周）動かした後、同じ位相のRoot.C0位置差0で、持上げの累積なし。

- **隔離実Play**：既存StartRun(3)・壁破壊経路で準備し、実戦闘→手動攻撃→Gauge10000→8000→0・Stage4進行を確認。戦闘中の43標本の最小床面差は-0.00000131 studs。Back→再出現後も実描画と通常Track2本を確認した。
- **攻撃姿勢の模擬再生**：実戦闘の短い標本期間ではAction Trackを観測できなかったため、その期間を攻撃アニメーション検証済みとはしない。別に既存Stage03Attackを直接再生し、60標本中23標本でActionが再生中、最小床面差-0.00000151 studsを確認した。追加TrackはStop/Destroyし、通常2本へ戻した。正規の攻撃通知経路そのものの全タイミング検証ではない。
- **Native Editの30 assertions**：回転した足の下端式を8頂点計算と比較、実R15構造の受付、World2/別Stage/別Rig除外、関節欠落/到着、冪等なcleanupと元C0復元。Playや自然streamingの代用とはしない。
- **静的・同期**：製品2＋テスト4 SourceのLuau構文検証通過。最終11 SourceのSource/Editor/ローカル一致。EnemyManager、Stage03AttackVisual、Binding、Stage1/2の6 Sourceを維持。

実Playは既存メモリ隔離を使い、LV15/Strength2000とStage3開始を自動準備したもの。自然育成・実機手操作ではない。[測定値](evidence.json)／[再現用補助](../../tests/Stage03GroundContact/README.md)。確認画像は一時確認のみで、画像保存/commitはしていない。

## 維持項目・Runtime・限界

HP10000、サーバーRoot位置 `(287.799988,8,442.627014)`、Collider寸法7.338420×13.346803×5.586443・中心Y10.423394、CombatZone寸法17.338421×14×15.586443・中心Y10.749992、サーバー外観Root.C0.Y=-2.5517416は前後一致。

Idle `507766388` / 3.766667秒 / Speed1、Walk `16562332340` / 0.625秒 / Speed0.6、Attack `522635514` / 設定PlaybackSpeed1.25を保持。テンプレート、モデルScale、移動/旋回/攻撃設定、HP、報酬、保存処理を変更していない。

最終Playに今回の変更由来のRuntime Error / Warning / Infinite Yieldは観測なし。隔離BadgeServiceによるFirstSmash通知1件、既存起動ログ、StudioツールのCameraType復元ログを区別する。

実機、公開環境、自然なネットワークstreaming、全視点・長時間・全地形境界は未確認。外接箱下端による保守的な接地であり、足裏メッシュに対するIKの追加ではない。確認した描画では極端な浮きや破綻は見られなかった。過去の描画停止原因が解決したという判定もしない。

## 後片付け・提出

開始時はEditで、ユーザーのPlayは停止していない。DataStore/Marketplace/Badge/Messaging/Policyの39差し替えを現在値と保存した原文で確認して復元し、QA3オブジェクトとメモリ/backupを除去。終了時は補助0、正本**未保存Edit**。Save/Publish・保存GUI操作なし。本番データや購入処理への検証操作なし。

今回の関連変更だけを通常commit・origin/mainへ通常pushする。既存未追跡 `reports/Visual_Templates_Secret_VIP_Green_20260917.md` は保持・対象外。PR #1は操作しない。Place保存・公開はユーザー本人の手動操作に委ねる。
