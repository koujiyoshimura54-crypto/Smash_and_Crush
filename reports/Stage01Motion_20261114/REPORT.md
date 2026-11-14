# World1 Stage1 Boss：振り幅2倍と接地補正

2026-11-14。対象は正本Studio PlaceId **126576845524886** / UniverseId **10765181857**、開始時Edit PlaceVersion **627**。開始時main/origin/mainは `5cac28b17fd84e2ca4af71194bc1477ee4f3a735`。公開版の更新ではない。

既存のBallerinaの動き・テンポを保ち、関節の周期的な振り幅を約2倍にした。追加依頼の床への埋まりは、見える通路上面へクライアントの外観だけを合わせて修正した。HP・戦闘Root・サーバーの当たり判定・移動/旋回/攻撃設定は変更していない。

## 現行Studioの確認

- 開始時はEditであり、ユーザーのPlayを停止していない。対象クライアント、EnemyManager、World1BossPresentationのSource/Editorをローカルと照合してから変更した。Phase 1/2・直前の計測変更を保持。AGENTSの古いPlaceIdより今回指定を優先。
- `ServerStorage.EnemyTemplates.Stage01Boss.BallerinaCappuccinaRig` はScale **4.5**、3 MeshPart、16 Bone。FakeRootPartの下にTorso→Head/腕/脚の階層と、独立した左右の足制御Bone `Leg.L.003` / `Leg.R.003` がある。各足制御の子は `.002`。
- `Stage01Idle.AnimationId = rbxassetid://91205904952804`、`Stage01Walk.AnimationId = rbxassetid://101135921440052`。テンプレート、メッシュ、AnimationIdは変更していない。
- 実PlayのAnimatorは既存2 Trackのみ。IdleはPriority Idle、3.8秒、WalkはPriority Movement、1.15秒。双方Speed=1、Weight=1、Looped=true。
- 元のWalkは61 Keyframeで全16 Boneにキーがある。Idleの6 Boneも含むため、Weight=1のMovement Walkが表示姿勢を支配する。固定の肩角度約60度・肘約12度、曲げた膝・低いTorso姿勢を一律に倍増してはいけない。
- `EnemyManager.attachEarlyStageVisual` の既存接地基準は非表示Floor上面Y=4。実際に見える `Workspace.GeneratedMap.BattleCorridor.Stage01.Stage1.5.PathToRun.Upper` の上面はY=4.4000146。約0.400015 studsの差が埋まりの原因だった。Stage1のFloorはCanQuery=false。実通路を含むStage01限定rayで上面を確認した。

## 変更Full Pathと方法

| Full Path | 変更理由・内容 |
|---|---|
| `ReplicatedStorage.Config.Stage01MotionConfig`（新規ModuleScript） | `Amplitude=2.0`、対象Walk ID、周期の中心姿勢、`GroundFit=true` を明示する。 |
| `ReplicatedStorage.Modules.Stage01Motion`（新規ModuleScript） | Animatorが出したローカルBone姿勢の変動分と独立足制御を補正し、外観Weldを実通路へ合わせる。WorldId=1、StageNumber=1、対象Walk IDを確認する。 |
| `StarterPlayer.StarterPlayerScripts.World.Stage01AppearanceClient` | 既存のRig追跡・再生・解放にMount/cleanupを接続。既存Trackの再生方法・速度・優先度は維持。 |

リポジトリの対応先は `src/` 以下の同じ階層（クライアントは `.client.luau`）。EnemyManager、World1BossPresentation、テンプレートの変更は不要だった。

回転は `centerRotation * rotationDelta^Amplitude`。中心は元Walkの時間間隔で重み付けした平均姿勢から求め、固定姿勢は維持する。Torsoだけ中心からの上下変動も拡大。肩・股関節・膝・頭/体の局所回転を各1回補正し、親のWorld姿勢を再度増幅しない。一定の肘・手首・足先回転は変更しない。独立した足制御Boneは元の接地ゼロ点からの歩幅/持上げだけを拡大する。Rootの移動やbind姿勢は拡大しない。

毎PreAnimationに前回保存した**補正前**のTransformへ戻し、PreSimulationで今回のAnimator出力を取得して補正する。Animator評価が間引かれても前回の補正結果を再利用しない。cleanupは冪等で、2接続を切り、補正前の姿勢と元Weldへ戻す。既存BindingのRig交換・破棄処理を使い、Trackを追加しない。未到着のBone/Weldがあれば既存refreshで待つ。

接地は元Weldから導いた左右の足の静止位置を基準に、現在のStage01の実上面をrayで確認する。固定World座標や前フレームの持上げ済み座標を基準にしない。`Stage01VisualRootWeld.C0` だけをクライアントで上げる。EnemyManagerで上げると、その後に作るサーバーのCollider位置まで変わるため、サーバー側の配置は保持した。

`Amplitude=1.0` で元のアニメーション振り幅へ戻る。接地修正は独立して残る。完全な旧外観との比較は `Amplitude=1.0, GroundFit=false`。別のWalkへ差し替える際は中心姿勢を再検証する必要があり、異なるIDではこの補正を適用しない。

## 数値と実描画

同じ個体、同じ位置、同じ元Track/Speed=1、各3.5秒・211回のPostSimulation標本。下表の数値比較は両方GroundFit=trueとして、振り幅だけを比較した。角度は周期中心からの最大角変位、距離は周期中の最大−最小。標本時刻が異なるため完全な整数比にはならない。

| 測定 | Amplitude 1 | Amplitude 2 |
|---|---:|---:|
| 左肩角変位 | 16.078° | 32.167° |
| 右肩角変位 | 16.078° | 32.167° |
| 左股関節角変位 | 24.842° | 49.572° |
| 右股関節角変位 | 24.830° | 49.660° |
| 左膝角変位 | 22.134° | 44.279° |
| 右膝角変位 | 22.260° | 44.399° |
| 体/頭の角変位 | 1.998° | 3.992° |
| 体の上下幅 | 0.0600 studs | 0.1197 studs |
| 左手先の前後幅 | 1.7035 studs | 3.2772 studs |
| 左足の前後幅 | 2.0062 studs | 4.0062 studs |
| 右足の前後幅 | 2.0025 studs | 4.0062 studs |
| 左足の持上げ幅 | 0.3589 studs | 0.7179 studs |

手先のWorld変位は回転合成なので厳密な2倍ではなく約1.92倍。局所関節の変動は約2倍で、親子階層による4倍化はしていない。

実描画はStudio Play、1390×601で確認。変更前と変更後を同じ固定カメラ・モデルScale・Walk位相0.18秒で比較した（この比較時だけ双方Speed=0で固定）。カメラ位置 `(306.799988,10.108449,190.899994)`、通常再生は元のSpeed=1へ復帰。通常再生中、戦闘中、帰還後の再出現も描画を確認した。腕/脚の振りが広がり、旧外観で通路に隠れていた足が上面へ出ることを確認。確認した視点・位相で極端な浮きやメッシュ破綻は見られなかった。スクリーンショットは一時確認のみで、画像ファイルを報告書やcommitに含めていない。

| 接地・維持項目 | 変更前 → 変更後 |
|---|---|
| 外観Root Y（client） | 10.108449 → 10.508467 |
| 外観Weld C0.Y（client） | 2.108449 → 2.508467 |
| 足制御の接地最小Y | 約4.0 → 約4.400015（実通路上面） |
| サーバー外観Root / Weld Y | 10.108449 / 2.108449のまま |
| サーバー戦闘Root Y | 8のまま |
| Collider寸法 | 19 × 16.842552 × 10のまま |
| CombatZone寸法 | 29 × 16.842552 × 20のまま |
| Collider / Zone中心Y | 13.779726のまま |
| Scale / Boss HP | 4.5 / 200のまま |

生の標本集計・Track値・最終照合値は [evidence.json](evidence.json)。座標は監査値であり、実装の固定座標ではない。

## 検証区分

| 区分 | 実施・結果 |
|---|---|
| 隔離ネイティブPlay：動作 | 上記の実描画比較、通常速度での実骨姿勢の数値比較。テンポ/2 Track/モデルScale維持。 |
| 隔離ネイティブPlay：非累積 | 通常速度で13.816秒＝Walk約12.014周。その前後を同じ位相0.18秒に戻すと、全16 Boneの最大位置差0、角度差0、Weld位置差0。描画フレーム5553→5762で描画も継続。 |
| 隔離ネイティブPlay：戦闘・復帰 | メモリプロフィールをLV4/Strength40に準備し、既存壁破壊/EnemyManager/RunReturn経路を使用。実Boss戦を開始、手動攻撃で撃破、CurrentStage=2と撃破事実を確認。Back後にStage1へ再出現し、同じ接地/Scale、Speed1の既存2 Trackのみ。別の実Boss戦で死亡・Lobby復帰も確認。自然育成や実機手操作のテストではない。 |
| 模擬境界テスト | 実Module Sourceと実Instance、フレーム信号のみfake。43 assertions通過。600回のAnimator更新なしフレームでも非累積、1.0復帰、固定中心保持、Root不変、cleanup冪等/切断、World2/別Stage/別ID/未読込Bone除外を検証。 |
| 静的・同期 | 製品3 SourceとテストのLuau構文検証。最終Source/Editor/ローカル照合6件一致。EnemyManager・Binding・World1BossConfig維持。 |

既存 `tests/FirstBattleTutorial/InstallIsolation.luau` によりDataStore/Marketplace/Badge/Messaging/Policyをメモリ/非外部処理へ39件差し替えたPlay。実データのリセット、購入操作、保存・公開操作はしていない。手順・一時fixtureは [tests/Stage01Motion](../../tests/Stage01Motion/README.md)。

## Runtimeと確認できていない範囲

- 最終PlayのConsoleはLimitedEgg/StudioTestの既存起動ログと、隔離BadgeServiceがfalseを返したFirstSmash通知2件。今回の3 Sourceに由来するRuntime Error / Warning / Infinite Yieldは観測しなかった。
- 初期検証で別アセット `119910397965139` の権限警告を観測。今回のIdle/Walkとは別で、最終Playでは再出力していない。検証用の巨大StringValue格納/Source転送失敗は補助操作のエラーとして処理し、製品の実行エラーと混同しない。
- 途中、サーバー処理・PreSimulationは進むがRenderフレームが固定される状態、再起動後Viewport=1の状態が発生。その時間帯は数値/サーバー確認のみで、実描画合格としていない。後に1390×601で描画が復帰し、上記の最終比較と戦闘描画を実施した。**描画停止・復帰の原因は未確定**で、ガイドや今回の補正の不具合とは断定しない。
- 実機スマホ/タブレット、公開環境、自然なネットワークstreaming、長時間/全負荷/全カメラ角度は未確認。未到着Rigの模擬除外と実再出現を、自然streamingの検証済みとは扱わない。他Stage/World2は適用除外と変更差分で確認し、全Stageの実戦は実施していない。

## 後片付け・引継ぎ

検証39 Sourceは保存した原文と現在の差し替え文の一致を確認して復元。QA Folder/ServerScript/LocalScript、メモリ/backupを除去。製品の変更3 Sourceのみ正本に残した。対象6 SourceのSource/Editorとローカル一致、テンプレートのScale/2 AnimationId維持を確認した。

正本Studioは**未保存Edit**。Save/Publish・保存GUI操作なし。ユーザーの既存編集、Phase 1/2・計測の成果、既存未追跡報告書 `reports/Visual_Templates_Secret_VIP_Green_20260917.md` を保持。PR #1は操作していない。関連変更のみを通常commitし、origin/mainへ通常pushする。Place保存/公開はユーザー本人の操作に委ねる。

実装で使うBoneのローカルTransformと実行タイミングは、Robloxの [Bone](https://create.roblox.com/docs/reference/engine/classes/Bone) / [Task scheduler](https://create.roblox.com/docs/performance-optimization/microprofiler/task-scheduler) の仕様も確認した。
