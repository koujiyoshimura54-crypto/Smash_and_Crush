# 実機FPS計測計画（未実施）

この文書は次工程の計画。今回は計測用スイッチ/プロファイルマーカーを実装せず、スマホを操作せず、Studio Play/Stop・Save/Publishを行っていない。

**計測開始の前提**

現在の副本は未保存Edit。スマホがこの未保存DataModelへそのまま接続できるとは扱わない。測定対象のPlaceId、UniverseId、公開PlaceVersion、取得時UTC、対応commit、サーバー起動時刻/識別用匿名コードを記録する。対応commitや公開履歴が分からなければ「不明」とする。日次FPSの11/14〜16と現行Sourceの因果比較には、各日の公開版と端末/画質/人数の内訳が別途必要。

次工程で現在の副本そのものを測るには、**別途許可された、保存/購入/外部送信を隔離した実機用ビルド**が必要。既存の適切な検証ビルドがなければ準備待ち。今の副本を公開する依頼ではない。隔離確認に失敗/未確認なら測定を開始しない。本番Playerの所持品・購入・保存値の書換えで条件を作らない。

既存公開版の測定資料を使う場合も、その版の観測として扱い、現在の未保存副本の性能検証と混ぜない。

**固定条件と記録**

| 条件 | 記録/固定方法 |
|---|---|
| 端末 | メーカー/型番、OS、Robloxアプリ版、可能ならSoC/RAM。同じ端末で比較。スマホ1台を優先、次にタブレット1台。 |
| 画面・画質 | 解像度/向き、RobloxのManual graphics段階、FPS上限を固定。Automaticなら自動変化が交絡するため別系列。 |
| 電源・熱 | 充電状態、バッテリー、省電力モード、ケース、室温、開始前休止時間。測定間で充電条件を変えない。温度/クロックが取れない時は未取得。 |
| ゲーム状態 | Place/Version、World、Body、装備ItemId/オーラ、人数、各Playerの位置・装備、操作。既存歩行/鍛錬速度・Strength計算は変えない。 |
| カメラ | 立ち位置、向き、高さ、距離/ズームを各条件で再現。将来隔離ビルドでpose記録機構を採用する場合は別途実装。今はランドマークと記述で残す。 |
| ロード | 初期ロードと、素材/Streamingが落ち着いた定常状態を別条件にする。ロード直後を定常FPSへ混ぜない。 |
| 通信 | 同一Wi-Fi、人数/サーバーを固定。ping/受信送信量を記録できれば記録。ネットワーク遅延と低FPSは別判定。 |
| オーバーレイ | Performance Stats/MicroProfiler表示条件を揃える。録画する場合もON/OFFを両側で揃える。録画なしを基本とする。 |

PCの画面サイズエミュレーションはレイアウト確認用で、スマホのGPU/メモリ/熱の再現ではない。[実機テストの公式説明](https://create.roblox.com/docs/performance-optimization/test-on-hardware)

**最初に行う順番**

1. まず1人、通常Body、同じ装備でWorld1ロビーの同じ地点から「設備方向A→壁方向B→設備方向A」。歩道へ乗らない位置で停止。画面以外の条件を揃える。表示対象による差を短時間で確認する。
2. A/Bを逆順でも行う。各条件60秒の定常観察中、離れた時点で90frameのcaptureを3回取得。FPS統計が得られるなら60秒区間を記録。短いcaptureのP50/P95は「取得frameのみの統計」であり、60秒全体の統計に見せない。
3. World2へ正規に到達可能な隔離条件で、同じA/Bを行う。Treadmill03/04の光源方向、05〜07の粒子方向、壁方向を区別する。World1との差だけでは各Worldの全要素が交絡するため、同一World内の向き比較を優先。
4. GPU/描画が支配的なら候補2/3、physics/animationが支配的なら候補1/NPC、Lua/GUIが支配的なら候補4/5の一時スイッチ比較を次に選ぶ。スイッチの実装は別工程で許可を得てから。
5. 人数・装備・エフェクトを増やす比較、開始直後/10〜15分後の比較へ進む。

**シーン表**

| ID | 場面 | 同条件で比べるもの | 主に分けたい負荷 |
|---|---|---|---|
| W1-A/B | World1ロビー停止、設備方向/壁方向 | 同位置・同装備・同人数、カメラ方向のみ | 描画/影/World GUI/粒子と常駐CPU |
| W1-T | Treadmill近傍、乗車前/乗車中 | 視点・画質固定、同一設備、資格ありの隔離データ | 演出と鍛錬animation/物理/通知。獲得倍率は変更しない |
| W1-R | 歩道外停止/乗車/離脱 | ルート表示を含む同じカメラ、別に表示だけを止める将来比較 | 矢印描画・キャッシュ・搬送Constraint/Input/animationの分離 |
| W2-A/B | World2ロビー、設備/壁方向 | 同じ位置でTreadmill05〜07が見える側/見えない側 | 大きな粒子の重なりとWorld2周辺群の配信 |
| W2-S | World2接近→滞在→離れる | ロード中と安定後、同一往復経路 | Streaming追加/除去、キャッシュ再構築、texture取得/保持 |
| C | 同じStageの戦闘前/中/後 | 同じNPC・Body・装備・視点 | Boss移動/animation/物理、頭上GUI更新、replication |
| UI | ロビー停止、Inventory閉/開、Merge閉/開 | 同じtab/同じ所有snapshot/同じ視点。Merge候補閲覧だけ | GUI描画、カード作成/配置、照会。合成/購入/売却実行は不要 |
| P | 1人→2人→可能なら4人 | 立ち位置、Body、同じ装備/同じオーラを揃える | 人数増の基礎コスト |
| P-G | 同人数で同じダンベル→異なるダンベル | オーラなし等の同条件。左右表示維持 | 素材共有とmesh表示数を分離 |
| P-E | 同人数/同装備でオーラ条件比較 | 1人/複数人、種類固定、画面内密度固定 | エフェクトの画面占有と人数増 |
| L | 同じセッションの開始直後・安定後・10〜15分後 | 同シーンへ戻り同じ条件を再現。持ち替え/死亡/World往復の回数を記録 | 熱/メモリ/接続/モデル増殖の候補 |

開始直後0〜30秒のロード観察と、1〜2分程度で安定した基準を別に残す。10〜15分後に同条件のA/Bを再実施。長時間で遅くなるだけで熱原因と決めず、温度/クロックが取れなければ熱は仮説のまま。モデル数/メモリ増加があっても、それがCPU/GPUの支配時間に結び付くか確認する。

装備交換/死亡等は隔離データでのみ行う。繰り返しごとのTrainingDumbbell左右数、Weld数、effect clone数、キャッシュ要素数、Lua heap/Instances/texture memoryを取る案。これらの追加カウンターは今回は未実装。取得不能なら空欄にし、増殖なしと判定しない。

**一時スイッチの厳密な意味（設計のみ）**

| 案 | 外す成分 | 残す成分/注意 |
|---|---|---|
| ReferenceVisualOff | 指定参照群の可視geometryのみ | scripts、Humanoid、接触、effect、保持メモリを別管理。透明化だけで群全負荷OFFにはならない。 |
| ReferencePhysicsOff | 隔離コピー内の対象群の可動物理/接触/必要ならHumanoid更新 | 初期姿勢・見た目を揃える。Anchored変更で見た目やネットワーク量も変わり得るので副作用を記録。ゲーム用Colliderへ適用しない。 |
| ReferenceGroupAbsent | 依存確認した群をクライアントへ配信しない | 描画/物理/効果/メモリ全部が変わる総合試験。単独の原因同定には使わず、各成分比較後に行う。 |
| TreadmillParticlesOff / AuraParticlesOff | 指定Emitterの発生・粒子描画/シミュレーション | 最大Lifetimeを待つ。Light/Beamは別条件。購入/資格/Strengthは変えない。 |
| LightsOff / ShadowsOff | 指定Lightまたは指定meshの影 | geometry、材質、スクリプト、物理は残す。全Lighting一括変更はしない。 |
| DumbbellVisualOff | 展示/手持ちmeshの描画のみ | 登録・装備同期・Weld/物理・保持メモリは残す。全clone除去との混同を避ける。 |
| ArrowMotionFreeze | 表示poolのCFrame更新だけ | 固定した表示、床cache、搬送、ゲーム状態を残す。床再判定freezeは別条件。 |
| RouteRefreshFreeze | 経路cache再構築/床判定だけ | static場面限定で前回cacheを使用、矢印移動と搬送は維持。障害物変更やWorld移動を混ぜない。 |
| TreadmillDiscoveryFreeze | 設備一覧再探索のみ | 既存14設備・ベルトTween・鍛錬は維持。Streamingで未登録になる副作用は記録。 |
| RewardViewPollPause | 定期View要求のみ | 隔離環境の同一snapshotを使用、表示更新は同条件。購入/報酬タイミングが変わる本番へは適用しない。 |
| UIWriteDeduplicate / UIDrawOff | 前者は同値代入のみ、後者は描画のみ | 照会/イベント/接続を維持。各々別試験。GPU差とLua差を混ぜない。 |

A/B/A/Bまたは順序を反転したB/A/B/Aで再現性を見る。最初は一条件だけ変更する。改善案の採用には、変えた負荷の対応するframe taskが下がること、見た目/導線/操作/報酬を保つこと、複数captureで再現することが必要。数字の閾値を後から緩めて合格にしない。

**スマホのデータをPCで取得・解析する方法**

1. 計測許可と隔離を確認したビルドへ実機で入り、Roblox SettingsでPerformance Statsを表示。MicroProfilerをOnにする。
2. 同じLANのPCブラウザーで、実機に表示されたIP:portを開く。既定の直近30frameでは短いため、URL末尾に /90 を付けて90frameを取得。Re-captureで新しい区間を取得する。
3. Web UIの **Save to file** で microprofile-日付-時刻.html をPCへ保存する。3回のcaptureの時刻とScene IDをCSVへ記録。HTMLを後でブラウザーで開いて解析できる。IP/portはGitに記録せず、インターネットへ開放しない。
4. CPU/Jobs/Render/GPUのframe時間を読む。GPUタイミングが未提供・0固定等なら「未取得」と記録し、GPU負荷0と判定しない。
5. ExportのCPU flame graphを使い、対応するA/B dumpを読み込んでdiff比較する。CPU/物理/animation/GUI等の個別taskを確認。並列threadや親子taskの時間を単純加算しない。

これは公式のモバイルWeb captureとHTML保存手順に基づく。端末によって設定が見つからない、LAN通信が制限される場合は、その状態を記録して止める。機能を迂回しない。[MicroProfiler公式手順](https://create.roblox.com/docs/performance-optimization/microprofiler)

**解析の記録項目**

- FPS：集計元、観察区間、上限、平均/P50/P95等の定義。フレーム時間P50/P95/max、33.3ms/16.7msを超える取得frameの割合。FPS日次P50の逆数を同じセッションのframe時間P50として扱わない。
- CPU：Jobs wall / render thread、script、animation、physics、UI関連task。全CPU時間の合計とcritical pathは別。
- GPU：GPU frame timeと描画/影/粒子の区間、入手可能ならdrawcall/triangle。欠測は空欄。
- 物理：physicsStepped / worldStep / stepHumanoid等、動作中Assembly/contactsが取れるなら併記。
- Script：Lua/Heartbeat/PreSimulation/RenderStepped、GUI invalidationやscene更新。現コードに専用マーカーがなければ、特定関数のmsを推測しない。必要なら次工程で対象関数だけに計測マーカーを追加する案とする。
- メモリ：利用可能な総量/texture/mesh/Instances/Lua heapの時系列。単発の容量やPNGファイルサイズからFPS原因へ直結させない。
- サーバー：必要になった場合に限り、同時刻のserver profiler/networkを別途採取する計画。client GPU時間とサーバーscript時間を合算しない。
- runtime count：loaded/visible mesh、Emitter、Humanoid、Weld、renderer候補数など。今回はカウンター未実装のため観測不能な欄を埋めない。

タグ名や取得可否はアプリ版による。physics/animation/render/影などのtaskを手がかりに、現物候補に対応する箇所を調べる。[改善調査の公式説明](https://create.roblox.com/docs/performance-optimization/improve)

90frame×3の標本だけから15分全体の頻度は算定できない。異常frameの代表captureと定常captureを分け、都合のよい最良値のみを採用しない。3回の中央値と範囲を示し、シーン差がrun間ばらつきより小さければ原因候補を維持したまま追加計測する。

**ユーザーが行う最小限の実機操作**

- 今は端末の型番/OS/Roblox画質・FPS上限を確認すればよい。副本の公開・Studio起動は不要。
- 保存隔離と対象版が確認できる計測先が用意できた時だけ、実機で入る。
- 同じロビー地点から設備方向/壁方向を向き、Performance StatsとMicroProfilerをOnにする。
- PCを同じWi-Fiにつなぎ、実機表示のアドレスでcaptureを保存する。開始直後/安定後と10〜15分後に同じ場面を繰り返す。最初はこの1端末・1人・2視点で十分。
- 保存したHTMLと記入したCSVを渡せば、PC側で内訳の比較を継続できる。公開先/版が分からない場合は推測せずその旨を添える。

計測先が未準備なら、データ取得のために今の副本をSave/Publishする必要はない。今回の調査はそこで止め、最適化実装へ進まない。
