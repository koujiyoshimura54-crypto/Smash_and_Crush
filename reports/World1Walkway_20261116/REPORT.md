# World1 動く歩道 — 2026-11-16 確定仕様

対象：副本 **PlaceId 126576845524886 / UniverseId 10765181857**。現在の未保存Edit実装を基準に必要な差分を反映した。旧「通常歩行の1.5倍へ合計速度固定」は撤回し、**搬送12 studs/s＋通常の方向入力**へ変更した。

## 変更Full Path

| Full Path | 今回の確定仕様への修正 |
|---|---|
| `ReplicatedStorage.Config.World1WalkwayConfig` | StartDistance=5、TransportSpeed=12。TransportMultiplierを削除 |
| `ReplicatedStorage.Modules.World1WalkwayGeometry` | 符号付き入力成分と固定搬送速度の加算、既存終点減速を共通化 |
| `ServerScriptService.Services.World1WalkwayService` | 有効区間のサーバー認可、正規速度と限定入力による目標値、不要な0.25秒待機を除去 |
| `StarterPlayer.StarterPlayerScripts.World.World1WalkwayClient` | 共通入力の局所予測、即時離脱、残る搬送成分を1回だけ除去 |
| `ReplicatedStorage.Modules.World1WalkwayLocomotion` | 新規。歩行／走行Coreトラックだけを搬送を除いた速度で補正 |

次の4本は前回反映した同じ歩道実装を維持し、未commitだった今回の機能一式へ含める。

| Full Path | 維持する役割 |
|---|---|
| `ReplicatedStorage.Modules.FloorGuideRenderer` | 常設所有者だけの流れる2-Part矢印、床・障害物キャッシュ |
| `StarterPlayer.StarterPlayerScripts.Tutorial.World1FloorRouteClient` | World1常設表示、固定Spawn→最初の壁 |
| `ServerScriptService.Systems.Controllers.World1WalkwayController` | サーバー搬送サービスの起動 |
| `ServerScriptService.Services.AutoTapService` | 搬送中の自動歩行Strengthを除外 |

実行中だけ `ReplicatedStorage.World1WalkwayInput` を1個生成する。搬送対象の `HumanoidRootPart.World1WalkwayAttachment / World1WalkwayVelocity` は乗車中だけ存在する。

`TreadmillGuideClient`、`TreadmillConfig`、`TreadmillRunClient`、`TutorialGuideClient`、既存の保存・報酬・戦闘・進捗の製品Sourceは変更していない。

## 手動設定

設定場所：**`ReplicatedStorage.Config.World1WalkwayConfig`**。ModuleScriptは各実行環境でキャッシュされるため、Editで値を変更した後、**次のPlay／新しいサーバー・クライアント起動時**に反映する。Play途中のSource編集で即時変更される仕様ではない。

| 設定 | 値 | 単位・意味 |
|---|---:|---|
| StartDistance | 5 | studs。固定経路のSpawnLocation中心から壁方向への開始距離 |
| Transparency | 0.5 | 0～1。表示中の両腕それぞれのTransparency。不透明度50% |
| TransportSpeed | 12 | studs/s。通常移動へ1回だけ加算する搬送成分 |
| ArrowSpeed | 4 | studs/s。入力・歩行・搬送速度から独立した矢印の流速 |
| WidthMultiplier | 3 | 元の矢印外縁幅に対する倍率 |

`TransportMultiplier`はSourceと設定から削除した。倍率制御との二重適用はない。

既存設定も維持：TransportWidth=7.093475 studs、EndClearance=4 studs、VisualWallClearance=1.5 studs、ArrowSpacing=3.5 studs（循環長を整数組で均等割り）、SurfaceSampleStep=0.25 studs、RefreshInterval=0.2秒、GroundTolerance=0.45 studs。

## 搬送と入力

壁方向をD、Humanoidの入力をM、サーバーが適用した通常歩行速度をWとすると、壁方向の目標は `12 + W * dot(M,D)`。Mは `Humanoid:GetMoveVelocity() / Humanoid.WalkSpeed` を使い、MoveDirectionでは失われるスティックの倒し量も保持する。終点の短い減速区間だけ既存の残距離制限を適用する。前フレームの速度へ加算しない。

通常速度24の場合、無入力12、前進36、逆方向−12、壁と直角の入力は壁方向12＋横方向24、45度入力は壁方向約28.971＋横方向約16.971になる。半倒しの壁方向入力0.5では24。これらは設計値で、実測は下表に区別する。速度強化や既存の正規一時ブーストはサーバー上のHumanoid.WalkSpeedを参照し、歩道からWalkSpeedを書き換えない。

既存のLine型LinearVelocityを維持し、入力に対して定数へ固定していた目標値だけを変更した。横方向と上下方向は通常Humanoidが制御する。カメラ、向き、入力を上書きしない。クライアント側は既にサーバーが作ったConstraintを同じ式で予測し、横離脱・ジャンプ・終点・World変更では直ちに無効化する。退出時の搬送成分は現在の入力に対する残差を上限として1回だけ差し引き、サーバー側の停止処理と二重に差し引かない。

MoveDirectionはサーバーへ複製されないため、入力Remoteは有限値−1～1の「壁方向への入力成分」だけを受け付ける。現在の本人Character・サーバー乗車認可・World1を照合し、30Hzより速い更新を拒否、0.35秒で失効する。クライアントから任意の速度・位置を受け取らず、区間外や空中から搬送を開始できない。参照：[Humanoid公式仕様](https://create.roblox.com/docs/reference/engine/classes/Humanoid)、[LinearVelocity公式仕様](https://create.roblox.com/docs/reference/engine/classes/LinearVelocity)。

## 開始・終点と接地

基準は `GeneratedMap.TrainingArea.SpawnLocation`。中心(287.861084, 3.898331, 12.999991)から壁方向へ5 studs。循環中の先頭矢印や歩数・Wキーは開始条件に使わない。通常の区間入場に0.25秒の固定待機はない。スポーン中心は区間外。

搬送終点は `GeneratedMap.BattleCorridor.Stage01["Stage1.1"].Wall` の手前面から4 studs。ただし実Body前方外縁＋0.5が大きければその余白を使う。Spawnから壁面83.400030 studs、通常体格の搬送終点79.400030、表示終端81.900030。最後の壁姿勢を構造Floor相対で保持し、壁破壊後もBoss／WinTrophyへ延長しない。Map／Stage／Section／Floor交換時は記録を失効する。

接地は実衝突床へのRaycast、HipHeight・Root寸法・実足裏、Humanoid状態・上下速度を組み合わせる。Touchedだけや固定Root高さには依存しない。新しい足場は追加していない。

## アニメーションと表示

通常床のR15 Animateと同じ速度正規化・体格補正・walk/runブレンドを使い、入力による速度だけを渡す。現在のエンジンでSingle Colliderが使われる場合の脚Attachment長も考慮する。同じ入力速度・同じ体格で通常床の再生速度を観測済みなら、その値を使う。AnimateはRunningイベントの最終速度を保持するため、物理速度の定常値と数%異なる場合もその既存挙動を維持する。観測前／速度・体格変更後は通常の正規化式を使う。無入力搬送ではCore歩行トラックを抑え、既存idle Animationを使う。離脱時は通常速度へ戻し、以降は既存Animateに制御を返す。

変更対象はAnimateのwalk/runに登録されたIDかつPriority=Coreだけ。TreadmillのMovementトラック、攻撃・道具のActionトラックの速度を変更しない。IsTraining／IsFighting中は補正を解除する。Animate Source自体は変更しない。

矢印は22組44 Parts。白Neon、線幅0.34・厚み0.045、実外縁幅7.093475 studs（3倍）を維持。両腕の位置を同じ位相で移動し、終端から始端へ循環する。表示中の全腕へTransparency=0.5、床なし／設備で非表示になる腕は1。常設フォルダーは1個。毎フレームの生成・破棄・Workspace全体検索・全経路Raycastは行わない。矢印位相はArrowSpeedと時刻だけで決まり、搬送と入力から独立する。

## 保存データからの隔離

今回は副本のサービスを一括置換せず、**新規の一時PlaceId 0のテストPlace**を作成した。副本から読み取った15個の床・壁・Spawn配置、今回の実製品Source、既存SpeedService／SpeedConfig／TreadmillRunClient、最小のメモリ上のデータ・権利fixtureだけを含む。

ビルダーと起動ランナーの両方が、DataStore／Marketplace／Badge／Analytics／MemoryStoreへの参照、想定外のSource数、PlaceId≠0を拒否する。最終版は15 Source。**全assert成功後にだけ**ExecuteMultiplayerTestAsyncを呼ぶ。隔離失敗時は後続Playへ進まない。指定副本のPlayは今回開始していない。

2クライアントの実Humanoid物理と実Animatorを使用したが、入力と位置設定、速度Upgrade、World属性、体格Scaleはテスト用に合成した。実キーボード／スティック操作、通常のゲーム進行、本番データを再現したとは扱わない。

前回ターンで隔離拒否後に短いPlayが誤開始された事実は残る。直ちに停止し検証データ操作はしていないが、その前回Playの保存データ無影響は断定しない。今回の測定には含めない。

## 実Play測定

最終の隔離Playは**63項目成功、例外なし**。値は `水平実変位 ÷ 経過時間`。設定値や式の計算結果を実測と呼んでいない。主測定区間は約0.5～0.62秒で、フレームと時計の標本化による小差を含む。[距離・時間・全チェックの記録](NativePhysics.json)。

| 条件 | 目標 studs/s | 実測 |
|---|---:|---|
| 通常床・歩行24 | 24 | 24.143 |
| 歩道・無入力 | 12 | 11.996 |
| 歩道・壁へ前進 | 36 | 36.209 |
| 歩道・逆方向入力 | −12 | −11.911 |
| 歩道・半倒し前進 | 24 | 24.044 |
| 通常床・速度強化40 | 40 | 39.693 |
| 歩行40＋搬送 | 52 | 51.662 |
| 歩行40設定・無入力 | 12 | 11.918 |

- 斜め入力：壁方向29.020、横方向17.002 studs/s（帯を出る前の約0.08秒測定）。横入力は帯を離れ、範囲外のローカルConstraint無効とサーバー乗車解除を確認。
- 開始境界：4.7 studsでは非乗車、5.1 studsへ接地配置すると無入力で乗車。配置からConstraint有効を観測するまで0.233秒（接地・ネットワーク複製込み）。歩数／W入力／旧0.25秒固定待機はない。
- 歩行アニメーション：24設定で通常床／歩道とも**1.912875**、40設定でとも**3.098115**。無入力では歩行Coreの速度0・重み0.0001、idle速度1。退出後は既存Runningイベントに基づく速度1.871325へ復帰。Actionトラック1.37、既存TreadmillRunTrack 1.0を維持。
- R15 Scale 0.7／1／2：搬送12.013／11.985／11.929 studs/s。通常体格は固定原点から79.282555で停止し、壁面まで4.117476 studs。壁を個別に非表示・非衝突にしても終点不変。
- 22組44腕のTransparency=0.5、全組の実移動・両腕同期・全周期循環を確認。周期中の新規Part生成0、常設フォルダー1個。2クライアントで片方の乗車中、帯外のもう片方は非乗車。
- ジャンプ・空中解除・再乗車、World属性往復、死亡復帰後のスポーン非乗車と再乗車を確認。

検証過程では半倒し入力の正規化問題を発見してGetMoveVelocityへ修正した。通常床の再生速度を同じ過去の数値と比較する検査は、既存AnimateのRunningイベントとの対応で検査するよう改めた。検証コード自身の死亡復帰待機の競合も修正後、全項目を再実行した。専用PlaceではCoreGuiのCreatorType関連エラーが出るため、標準TopBar／PlayerListの検査には使用していない。

## 検証区分と限界

- **実Play（専用fixture）**：速度と方向入力、開始前後、横離脱・ジャンプ・空中解除・再乗車、死亡／再生成、World属性往復、壁手前の停止、壁非表示後の固定終点、全矢印の移動・全周期循環・透明度・重複／生成数、通常床と歩行再生速度の比較。
- **体格の実Play**：R15を0.7／1／2倍へScaleToした接地・搬送。これは体格差の物理検査で、現行BodyPrototypeの最小／通常／最大Bodyそのものを全種類確認したものではない。
- **Editの実Geometry＋模擬時刻**：全矢印の移動、両腕同期、周期復帰、実幅、300描画更新で部品／床キャッシュrevision不変、厚さ0.04の非Query設備の遮蔽・除去後復帰。
- **模擬回帰**：実AutoTapService Sourceとメモリ依存を使う6ケース。搬送だけの自動Strengthなし、通常歩行／手動タップ、Treadmill専用経路、戦闘優先を確認。実TutorialGuideClient末尾による既存Trophy回帰24ケースも全成功。
- **未確認**：正規Lobby帰還／Worldゲートを通す副本全体の統合Play、実壁攻撃・クリック／タップ促し、実Treadmill／歩行のStrength加算、初回Treadmill→壁→Boss→Merge導線、現行BodyPrototype全サイズ、実PC入力・スマホ／タブレット／ゲームパッド、公開環境・本番保存／再参加。未確認事項を実測成功として扱わない。

特に終点は既存前方攻撃Trigger（Offset3＋半奥行2＝5 studs）内に入る距離をfixtureで確認したが、正規戦闘サービスでの攻撃成功とは区別する。World往復は属性切替、Lobby相当は固定Spawnへの配置であり、正規帰還／ゲート操作の確認ではない。

搬送中は能動入力があっても自動歩行Strengthを停止する。通常床の歩行Strength、手動タップ、Treadmill報酬経路は維持する。[Edit／模擬検査の全記録](Simulation.json)。

## 清掃・保持・Git

最終照合では開始時517 Source中、既存514本を完全保持、対象3本だけ変更、6本追加で523本。対象9本はローカル・Studio Source・Editor Sourceが一致し、ネイティブ構文コンパイル成功。欠落0、検証補助Instance 0、Edit中の搬送Constraint 0。[最終Source指紋](SourceHashes.json)。検証用Studioは終了し、指定副本だけが未保存Edit状態で開いている。

今回の製品9 Source、検証コード6ファイル、報告と関連仕様文書だけをcommit対象に選ぶ。通常の `git push origin HEAD:main` を使用し、最終commit／push結果は作業完了メッセージに記録する。Save／Publish、正本、PR #1、force pushは行っていない。

再現コード：`tests/build_world1_walkway_fixture.py`、`World1WalkwayFixture.server.luau`、`World1WalkwayFixture.client.luau`、`World1WalkwayGeometry.json`、`World1WalkwayRender.luau`、`World1WalkwayStrength.spec.luau`。Trophy回帰は既存`tests/TrophyGuideCompletion.luau`を使用。一時テストPlace・ローカルログ・クラッシュ出力はGit管理対象に含めない。
