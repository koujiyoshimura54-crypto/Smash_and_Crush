> c4a55e5時点のBody調査・最初の提出の記録。World2表示の現在状態は[REPORT.md](REPORT.md)を参照。以下の未登録・未適用は当時の状態。

# World2ダンベル・8番UI・Body/Treadmill調査

2026-11-17。**部分完了。World2モデルと8番UIの取り込み・反映は未完了。**

Bodyの旧検証環境の不備を切り分け、実設備・現行Body生成を使う隔離Playで再測定した。World1 Treadmillのジャンプ中判定に本体の問題を確認し、TrainingManagerだけを副本へ修正反映した。World2はフォルダ許可と05/09の対応確認が必要。未完成の表示コードは実行対象へ入れず、[準備差分](pending/README.md)として保存した。

## 対象・保持・変更Full Path

- 実接続: PlaceId 126576845524886、UniverseId 10765181857、OwnerUser 7467238848。
- 開始HEAD/origin/main: 84e999ca4825a3b1f4896f308fb950cb0f9e6d46。ブランチ codex/analytics-spawn-items-20261115。
- 無関係な未追跡 crashes/ は保持し、コミットへ含めない。
- 開始時526 Sourceをメモリ基準で比較。変更Full Pathは **ServerScriptService.Services.TrainingManager** のみ。ファイルは src/ServerScriptService/Services/TrainingManager.luau。
- BodyPrototype、WalkSpeed、モデル寸法、W1登録12種と05既存モデル、両手表示、価格・倍率・周期・LV・保存・装備・マージ・売却は変更しない。
- 副本のPlay、Save/Publish、正本、PR #1、課金・本番保存は実施していない。検証用別Studioは終了。副本は既存編集を保持した未保存Edit。

## World2の入力と対応

実Downloadsは C:\Users\kouji\Downloads。12 ZIPが存在し、各FBXのSHA256は異なる。原本は変更せず、展開先を Downloads\World2Dumbbells_20261117\originals\<UUID> とした。

[元モデル12件の実描画](images/source_models.png)と[現行World2 UI](images/icons_before.png)を比較。元FBXをBlenderで描画し、画像から作り直していない。番号順・テクスチャ名では割り当てない。

| ItemId | 元ZIPのUUID（tripo_convert_<UUID>.zip） | 確認内容 |
|---|---|---|
| W2_NORMAL_01 | be9de5d1-da96-4257-b9fa-0e9cfc268e96 | 黄・黒の工業型 |
| W2_NORMAL_02 | 699aff5d-dfc7-47af-8c04-3d2fc97fbd2d | 赤い金具・コンクリート |
| W2_NORMAL_03 | c29ae88b-713b-40c8-a674-7cc619ae9784 | 赤・鋼のスパイク |
| W2_NORMAL_04 | 325c88e5-35ce-4599-abbc-d6add5edffa0 | 緑の液体 |
| W2_NORMAL_05 | 未確定 | 下記髑髏2件との対応待ち |
| W2_NORMAL_06 | 15b4b34a-ee7b-4724-a23d-840821ad4b01 | 蜘蛛 |
| W2_NORMAL_07 | 6f4d6c73-89cb-4430-a575-6c6cdf56fdd4 | 鎖・赤い核 |
| W2_NORMAL_08 | c0336e3e-4fa8-4e1b-8c0d-8ec6e1aa5dc5 | 指定の紫水晶・黒い岩 |
| W2_NORMAL_09 | 未確定 | 現行の目玉と一致するモデル未確認 |
| W2_NORMAL_10 | 45523401-b6e5-40be-886e-87653b1ca616 | 青い浮遊キューブ |
| W2_NORMAL_11 | 850c42fe-67c0-4846-9611-d1d1e7b1c6c0 | 双顎 |
| W2_NORMAL_12 | 1f4b4e93-389d-433a-a119-495af875a4b4 | 金枠・紫の三角結晶 |

129491e9-6098-49c1-85c7-bb7dda049030 と d359c5a6-d5f2-4e22-bb90-1b79bf0dcf09 は別モデルだが実描画では両方髑髏。05/09への割当、または目玉の別元ファイルを確認中。消去法で割り当てていない。d359の柄は斜めなので、対応確定後に作業コピーの回転補正も必要。

作業GLBは12,538〜13,879 triangles、各約4.4〜5.8MB。削減・色変更なし。BaseColor=sRGB、Normal/Roughness/Metallic=Non-Colorで4マップを接続。元FBX・全テクスチャは保持。巨大FBX/GLB/重複素材はGitに含めない。

### 実際のアップロード拒否

asset:read/writeスコープ付きUniverse GETはHTTP 200。08のGLBをアップロードすると **File not in an approved upload directory** で拒否された。成功したW2アップロードは0件、新Model/Mesh/Texture IDは未取得。拒否ファイルを別の許可済みフォルダへ移す回避はしていない。

必要: Studioの Assistant Settings → MCP Permissions → Approved upload directories に **C:\Users\kouji\Downloads\World2Dumbbells_20261117** を追加。Windowsの読み書き権限とは別。

実際に読んだ tmp/Dumbbell3D/skills/rbx-permissions/SKILL.md はフォルダ拒否時に “ask the user to approve its directory” とし、“Don't copy or move it yourself.” と指定する。許可確認が未回答のため依存工程を停止。OSのACL拒否や自動承認レビュー拒否ではない。

[ASSETS.json](ASSETS.json)に12元ZIP、FBX/各マップSHA256、変換情報、確定10 ItemId/未確定2件を記録。実ID欄はnull。登録原本がないためRobloxからのモデル復元はまだできない。元ZIP/GLBはDownloadsに保持。

### 8番UI

指定PNG「紫水晶の双頭クリスタルメイス.png」はRGBA 1536×1024、透明画素あり。SHA256はASSETS.json参照。新画像ID未取得・未反映。3Dテクスチャで代用していない。

現行 ReplicatedStorage.Config.World2GameplayConfig.DumbbellImages[8] は **101543601215487** のまま。静的にDumbbellItemMasterからInventoryPanelClientの詳細/プレビュー、DumbbellInventoryViewの一覧、MergeShopViewの候補/ダンベル完成結果まで共通参照を追跡。登録後は共通設定1か所を差し替える。Fit/透明背景・レイアウトを変更する必要はない。差替え後UI画像はまだない。

## ① 筋肉最小Bodyの低速: fixture修正

前回コード・生データを読み、旧fixtureを現行Sourceで再実行。装着1.1478、非装着1.7248 studs/sを再現した。WalkSpeedは24。前回6.31/1.14と同じ著しい低速だが、非装着値まで一致したとは扱わない。

旧XML生成は筋肉15 MeshPartの公開MeshSizeに相当するXML InitialSizeを保持していなかった。**床・入力・測定時間・体型切替を変えず、この情報だけを補完**。Play前に15部品のMeshSize/質量が副本実値に一致することをassertした再実行では、装着24.0373、非装着23.9832 studs/sになった。

| 条件 | 非装着 studs/s | 装着 studs/s | 筋肉最小AssemblyMass |
|---|---:|---:|---:|
| 旧fixture再現 | 1.7248 | 1.1478 | 3.880802 |
| 旧fixture + MeshSize保持だけ | 23.9832 | 24.0373 | 3.880802 |
| 現行生成・配置、安定後3回平均 | 23.9958 | 24.0002 | 3.880802 |

根拠: [旧再現](ORIGINAL_FIXTURE_REPLAY.json)、[一要因修正後](ORIGINAL_FIXTURE_SERIALIZED_REPLAY.json)、[現行経路全生データgzip](BODY_FIXED_SERIALIZED.json.gz)。旧テストは装着/非装着の差だけで合否を決め、両方1台でも合格し得た。そのラベルを正常速度の根拠にしない。

今回再現した低速は旧fixtureの再構成不備で解消。本体Body、WalkSpeed、ダンベルサイズは修正しない。メッシュ情報欠落と旧生成/切替の組合せでの再現であり、すべての生成経路で必ず起きるとは断定しない。エンジン内部の衝突データの詳細原因までは未確認。

CreateMeshPartAsync/ApplyMeshによる再生成案では、同じBox指定・MeshSizeでも質量が違った（UpperTorso 38.6884対38.8812、筋肉最小AssemblyMass 3.1854対3.8808）。[その測定](BODY_FIXED_REGENERATED_MESH.json.gz)は比較用で、最終確認に採用しない。[旧切替だけの対照](BODY_LEGACY_TRANSITION.json.gz)も原因を単独再現しなかった。

## ② 通常成長最大BodyのTreadmill: fixture不備と本体修正を分離

旧fixtureの仮設Areaは20×0.8×24、中心Y=1。足底が帯上端より高く、装着/非装着とも加算0になる結果を再確認。

実World1 Normal01のAreaは7×15×12、中心Y=12.0000、支持面Y=5.0000。実形状・現行Body生成で、**修正前TrainingManagerでも**通常成長最大BodyのStrengthが1.65秒で非装着+3/装着+6、各3 tick増加した。仮設形状の結果は本体不成立の証拠にならない。

ただし実World1ではジャンプ中も足が高さ15のArea内に入りInside=trueとなる本体の問題を再現。World2は既存の支持面・高さ・移動状態判定でfalseだった。

本体修正は TrainingManager.IsPlayerInsideZone のR15支持面判定をWorld1にも適用。既存XZ範囲を維持し、実設備の上向き支持面をHipHeight+Root半高±0.4 studsで確認。Jump/Jumping/Freefall/垂直速度を除外し、FloorMaterial=Airだけで拒否しない。World2のArea半高による既存許容値は保持。

| 同じ実設備・Body条件 | 修正前 | 修正後 |
|---|---|---|
| 通常最大/筋肉最小、装着/非装着、W1接地 | 全条件Strength増加 | 同じ増加を維持 |
| 上記4条件、W1ジャンプ | Inside=true | Inside=false、実加算停止 |
| W2接地/ジャンプ | 接地のみ有効 | 維持 |

[修正前実Play](BODY_BASELINE_SERIALIZED.json.gz)は24チェック中W1ジャンプ4件が失敗。[修正後](BODY_FIXED_SERIALIZED.json.gz)112項目はすべて成立。0.5秒周期・倍率・Strength計算は変更していない。判定範囲の無制限拡大、接地条件の削除はしていない。

## 実Play構成と測定

本番保存・課金・外部送信実装を含まないローカルPlaceId=0。Source35本の許可リスト/構文/禁止呼出し/部品寸法・質量をPlay前にassertし、失敗ならExecuteMultiplayerTestAsyncへ進まない。

実装を通す経路:
- LobbySpawnService/Client → BodyPrototype初期化 → MuscleCharacterService → ComparisonService/Clientの体型適用ACK・配置。
- DumbbellService → 既存サーバー両手表示。W2新モデル未実装のためW2の表示は既存legacy。
- TrainingManager → StrengthManager → StrengthCalculation → LevelProgression → メモリPlayerDataService。

本番PlayerDataService全体は含めない。現行AddStrengthGain関数本体をそのまま抽出したメモリadapterでStrength/Level/Progressを実更新。GamePass/Item/Potion/Aura/Pet/Analyticsは効果0/倍率1/送信なしの明示adapter。副本の無関係サービスを一括改変しない。

Studio内の実物理PlayでHumanoidへスクリプト入力。実キー/スティックの操作感の合格ではない。接地と垂直速度の連続安定を待ち、加速1秒を除き2秒間の変位を3回測定。全24試行で接地安定を確認。

| Body | 非装着3回 studs/s | 装着3回 studs/s |
|---|---|---|
| 通常最小 | 23.987 / 23.268 / 23.999 | 23.997 / 24.011 / 24.016 |
| 通常成長最大 | 24.004 / 23.992 / 23.996 | 23.997 / 23.967 / 24.002 |
| 筋肉最小 | 24.000 / 23.992 / 23.995 | 24.008 / 24.007 / 23.986 |
| 筋肉成長最大 | 23.991 / 24.002 / 24.054 | 23.992 / 23.998 / 24.000 |

23.268も除外せず記録。全試行の位置・入力・状態・AssemblyLinearVelocity・質量・HipHeightと、部品の衝突/固定/Massless/接続情報は生データに収録。WalkSpeed増加や閾値緩和で帳尻を合わせていない。

両Worldの実Treadmillで接地増加、ジャンプ/退出停止、再接近、資格喪失/復帰を確認。1.65秒で3 tick、W1非装着+3/装着+6、W2非装着+15/装着+30。W2の実測支持面Y=3.40969。実tick間隔32件は0.5003〜0.5178秒、平均0.5134秒（task.waitの遅延込み）。開始はfixtureから実StartTrainingを呼ぶ方式で、購入/設備入口UIを含む全ゲーム進行の確認ではない。

[追加Play](BODY_LIFECYCLE.json)9項目で、2クライアントが互いの01/12左右2本を観測、両Worldの死亡時加算停止・旧表示消去・復帰後2本・再鍛錬を確認。記録内RoundTripという旧ラベルはNormal体型要求後の測定24.0159を指し、そのrun単体で全4体型往復を行った意味ではない。体型列の往復は旧fixture再実行に別途含む。

CoreGuiのCreatorType未設定エラーと、旧fixtureの既存看板画像119910397965139の権限エラーを観測。今回のダンベルモデル/TrainingManagerとは区別し、権限回避・既存画像差替えなし。最初の新fixtureはStreaming=falseにより現行配置が完了せず、速度未測定で終了。実副本と同じtrue/64/1024へ揃えた後に測定した。

## 静的確認と未確認

静的確認:
- W2設備は Workspace.World2Map.TrainingArea.DumbbellDisplays.PerStepButtons.1..12。12 W2 ItemId属性を照合。購入Press/配置/価格説明UIは未変更。
- 準備差分の構文、完全ItemIdでのWorld分離、W1全12 cloneの横幅2、厚み1〜1.5をEdit内の非親付け複製で確認。古いModule requireキャッシュではなく現行Sourceを新評価。
- 画像共通参照と08だけの変更予定箇所を確認。既存W1画像は未変更。

未確認・未完了:
- W2登録12種、Robloxメッシュ/PBR読込、設備展示、両手表示、05/09確定、8番新UI ID/描画。
- W2新表示での購入/マージ/売却/持替え/退出/再参加/読込失敗/負荷。準備コードを実装済みとは扱わない。
- 新W2展示・手持ち・UI比較画像、スマホ/タブレット相当、実端末、公開環境、手動操作、本番保存、課金。
- 本番全サービスを同時に動かす統合Play。隔離では明示依存だけを使用。
- 通常成長最大を超える手動極大Bodyの修正後Treadmill。旧fixture再実行の手動Body歩行記録は、新支持面判定の合格ではない。

## 再現用ファイルと反映タイミング

tests/build_body_dumbbell_diagnostics.py、BodyDumbbellDiagnostics.server/client/memory.luau、read_body_dumbbell_results.pyを追加。入力SourceSnapshot.json、実設備geometry.json、NativeDonorAudit.jsonは作業PCのtmp/World2Dumbbell3D、W1モデルgeometryはtmp/Dumbbell3Dに保持。他PCでは最新副本から入力再取得が必要で、空checkoutだけでは生成できない。生成物・本番PDS全Source・巨大中間物はGitへ含めない。

例: python tests/build_body_dumbbell_diagnostics.py --variant serialized_mesh --training-fixed --regression --clients 2

生成runnerは隔離検査を通った時だけ別PlaceでPlayする。--training-fixedなしは修正前Snapshot、--training-onlyは通常最大/筋肉最小のTreadmill比較。旧fixtureの一要因再現補助はtests/replay_body_dumbbell_legacy.py。--serialized-meshを付けるとMeshSize保持だけを補完する。

反映したTrainingManagerは新しいPlay/serverから有効。Editで既にrequireされたModuleの戻り値は更新されない。W2の調整予定Full Path・単位・例は[pending/README.md](pending/README.md)。準備差分を適用して現行表示を失わせないよう、現在の表示コードを保持している。

最終[Studio確認](STUDIO_FINAL.json): 526 Source中525保持・1変更、追加/削除0、SourceとEditor一致、検証helper 0、W1登録モデル12保持、W2新Library未作成。副本Edit継続。Gitへの提出は確認できたTrainingManager修正・検証/報告・未適用準備差分に限定する。
