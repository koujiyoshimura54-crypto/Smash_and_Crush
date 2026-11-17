# スマホFPS低下の静的調査 — 2026-11-17（Y01）

今回の結論は**原因候補と実機計測計画まで**。原因確定・FPS改善・軽量化率の実測はない。最適化、仕様変更、計測スイッチの実装は行っていない。

- 接続PC：Y01 / DESKTOP-CNFVEH2。既存Studio接続のみ、PlaceId **126576845524886** / UniverseId **10765181857**、Edit、PlaceVersion **728**。
- 作業フォルダー：C:\Users\kouji\Smash_and_Crush\AnalyticsSpawnItems。
- 調査基準：開始時fetch後のHEAD / origin/mainはともに **1fcd1171c4fef2f694f4ba825d424f947d04de10**。ブランチ codex/analytics-spawn-items-20261115。前工程は [Y01保全報告](../Y01StudioPreservation_20261117/REPORT.md)。固定された古いHEADへの巻き戻しなし。
- 開始時の追跡変更なし。既存未追跡 crashes/ を保持。本調査の成果物はこのフォルダーだけ。
- Studio Source・エディターバッファ・プロパティ・配置は読み取りのみ。Moduleのrequire、Playerデータ取得、DataStore・購入API・Analytics送信なし。Play/Stop・Save/Publish・Studio終了・新規起動なし。
- PlaceVersionは接続中DataModelの値であり、**現在の未保存編集が公開済みである証拠ではない**。11/14〜11/16の公開版・端末構成・人数・画質との対応は未確認。

**入力データの解釈**

ユーザー提示のUTC日次FPS P50：スマホ43.7→38.2、タブレット47.5→42.7、PC55.5→72.7（11/14→11/16）。11/15のDAUはスマホ＋タブレット約93.7%。今回は分析APIから再取得していない。同一端末・同一セッションの前後比較ではなく、公開内容、FPS上限、端末構成、画質、人数、滞在場所の差を除けない。集計値からCPU/GPUのどちらが原因かは決められない。

**先に調べる5候補**

順位は静的証拠に基づく実測の優先順位で、推定改善率ではない。

| 優先 | 候補・現物の根拠 | 増える条件／不足情報 | 切り分け設計と、改善時に守る仕様 |
|---|---|---|---|
| 1 | World2付近の参照モデル群と保持範囲。Workspace.Ungroup は217 Humanoid・816 MeshPart・883 ParticleEmitter。Workspace.Stud Egg & Pet は3,654 MeshPart。Workspace.MergeToForge.World1 は Persistent。詳細は下表。 | World2接近・Streamingの滞留・視点・起動時。実クライアントに届く個数、可視数、起動後の撤去、稼働Assembly/CPU時間が未確認。 | 将来の隔離コピーで、対象群の描画、エフェクト、物理/Humanoidを別々に止める比較を設計。最後に群全体を非複製保管へ移す総合比較。透明化だけでCPU/物理が止まったと扱わない。動的参照・展示用途・購入設備との依存を確認してから保管先/配信範囲を検討し、必要な設備・見た目を削除しない。 |
| 2 | Treadmill・装備オーラのエフェクト重なり。World2Map.TrainingArea.TreadmillDisplays.05/.06/.07 は各20 Emitter、設定Rate合計各2,303、最大Size＋Envelope約12.90。03/.04は各21 Light。 | 設備が画面を占める視点、近距離、複数人のオーラ。GPU時間、粒子の実生存数、画質による制限、実行時に適用される形が未確認。 | Treadmill粒子、装備オーラ粒子、Beam/Trail、Light/Shadowを別条件にする。Emitter停止後は既存粒子の消滅を待つ/隔離コピーでClear。描画と粒子シミュレーションの両方が変わる比較であることを記録。改善候補は距離・画面占有・品質別制御。鍛錬資格・Strength倍率/周期・オーラ効果を保持。 |
| 3 | ダンベルと関連素材・影。24展示は53 BasePart / 23 MeshPart、23 MeshId・92 PBR map ID、全Mesh RenderFidelity=Automatic / CastShadow=true。登録原本と展示は同じIDを共有。元変換記録では22モデルが2K、NORMAL_07は4Kの4map。 | ロビー設備方向、近距離、左右装備が増える人数、異なるモデルの混在。実LOD、描画パス、GPU/texture memory、公開版への適用が未確認。 | 装備同期と物理接続を保った描画のみOFF、次に影のみOFF、同じモデル人数増と異なるモデル人数増を比較。素材の縮小版/LODは将来の比較案のみ。両手・24 ItemId対応・寸法/厚み・色装飾・購入/装備判定を保持。透明化では同期・Weld・メモリは測定対象から外れない。 |
| 4 | ガイドのキャッシュ更新とStreamingイベント。FloorGuideRenderer:165–240はPartごとにChanged監視、各経路更新で移動部品集合を走査。389–415は経路変更時に0.25stud単位の床サンプル。TreadmillGuideClientはWorkspace追加/除去で全タグ付き設備を再確認。 | World移動、Streaming、周囲のモデル追加、チュートリアルと常設ガイドの同時表示。実クライアントの候補集合数・再構築頻度・イベント回数・msが不足。 | 将来、矢印CFrame更新だけを停止する比較と、キャッシュ更新/床再サンプルだけを保留する比較を分ける。搬送はそのまま。さらにTreadmill設備再検索の購読だけを停止する条件。改善候補は必要領域への監視限定・dirty集約。矢印の連続移動、幅3倍、Transparency .5、流速4、搬送12、範囲/障害物判定を維持。 |
| 5 | UIの常時確認と無効化通知。StrengthRewardClient:79–84,160 は閉じた画面でも約2秒＋応答時間ごとにView照会/描画更新。HUDLayout:415–458 / ResponsivePanels:435–462 はGUIプロパティを監視してdirty時に再配置。設備ラベル24個はMaxDistance=∞。 | HUD更新、通知、在庫更新、画面開閉、人数によるサーバー要求数。回数は分かるがUI/Script時間とサーバー応答コストは未実測。 | 将来の隔離データで、View照会だけ停止して録った同一snapshotを使う条件、値が同じ時の描画代入だけ止める条件、GUI描画だけ無効にする条件を分離。改善候補は差分描画/更新通知集約。報酬到着通知・購入/Claim・数値・レイアウトを保持。今回は保存経路やDataStoreを調査・修正しない。 |

すべてのスイッチは**設計案**。StudioにもGitのゲームSourceにも実装していない。モデル群を一括で外した比較だけでは、その中の何が原因かは特定できない。

**現物・Source・Git照合**

[ソース比較](source_comparison.json) にFull Path、ローカル相対パス、ファイルSHA256、origin/mainとの一致、Studio Source/エディターの比較を記録。対象36本のローカル内容はorigin/mainと一致（CRLF/LFを区別しない比較）。Studioは32本一致、4本に差分。36本すべて取得可能なエディター内容はSourceと一致。

| Studio Full Path | 現在の差分 | 今回の扱い |
|---|---|---|
| ReplicatedStorage.Config.TreadmillConfig | GetDisplayText / GetGainDisplayTextの2文字列が mainの × に対してStudioは �~。Source行79/86。倍率・Guide設定の差ではない。 | 生Sourceを比較JSONに収録。由来・新旧を推定せず未変更。FPS原因とは扱わず、文字化け修正は別作業。 |
| ReplicatedStorage.Modules.World1WalkwayGeometry | 末尾空行 | 未変更 |
| StarterPlayer.StarterPlayerScripts.Tutorial.World1FloorRouteClient | 末尾空行 | 未変更 |
| StarterGui.StrengthGui.DailyRewardsClient | 末尾改行 | 未変更。前工程で直したDaily文字列の差分なし。 |

ReplicatedStorage.Config.LevelRequirements と StarterPlayer.StarterPlayerScripts.Combat.CombatClient は一致。新Strength表・Stage1条件分岐を保持した状態を読み取った。既存のGUIを再適用・再生成していない。本比較は関連36本の確認であり、全Source同期の宣言ではない。

**数え方とメモリ・World配置**

[scene.json](scene.json)、[workspace_groups.json](workspace_groups.json)、[asset_census.json](asset_census.json) はEdit DataModelの在庫。Workspace総数と実際の描画数・クライアント常駐数・動いているAssembly数を区別する。部品中心AABBは形状端を含む厳密な境界ではない。

| Full Path | Editで確認した値 | 解釈の制限 |
|---|---|---|
| Workspace | descendants136,473、MeshPart5,304、Humanoid223、ParticleEmitter1,160、Beam158、Trail13、PointLight102、Highlight33 | プレイヤーCharacter/クライアント矢印を生成していないEdit総数。全部が同時に見えるとは言えない。 |
| Workspace.Ungroup | descendants48,741、BasePart3,472、Humanoid217、MeshPart816（MeshId809）、PE883/Enabled623、Beam131、Trail13、Highlight31 | モデル群中心範囲 X178〜319 / Z2060〜2161。World2付近。2本の「INSTRUCTIONS」「THANK YOU.」Scriptはコメントのみで、常時処理ではない。 |
| Workspace.Stud Egg & Pet | descendants31,440、BasePart4,670、MeshPart3,654（MeshId2,914）、PE135、Humanoid1 | 中心範囲 X−114〜210 / Z1787〜2309、Y約110〜118。World2の近く/上方。可視性は実機視点で確認が必要。 |
| Workspace.MergeToForge.World1 | Persistent、descendants13,824。親MergeToForgeはBasePart3,510、全Anchored、Collidable3,240 | 描画外でも配信・保持に関与し得る。文字列検索では群名の撤去処理を発見せず。ただし動的参照・タグ利用・起動時整理を除外できないため「未使用」と断定しない。 |
| Workspace.GeneratedMap | BasePart4,516、MeshPart0。BattleCorridorは3,448part | ゲームの現行World1配置。旧群との用途/重複は別途依存確認が必要。 |
| Workspace.World2Map | BasePart3,874、MeshPart643（MeshId55）、全Anchored。TrainingAreaは1,449part | 643個が643種類の素材ではない。共有が多い。 |
| ReplicatedStorage.Assets | descendants10,856、MeshPart715、異なるMeshId709 | クライアントへ複製される保管内容。Workspaceの描画と同じではない。使用頻度・取得後のtexture residencyは未測定。 |
| ServerStorage | descendants61,629。PurchasedCourseOriginals24,530、RBX_ANIMSAVES27,212、EnemyTemplates5,740、BodyPrototype2,130 | 通常クライアントへ複製される場所ではない。この個数をスマホ描画負荷に加えない。 |
| StarterGui | MeshPart556（MeshId6）、ImageLabel/Button596（Image ID109） | 3つのWorldTravelGui.Modal.Card.WorldList.World1/2/3.MapPreviewが125/191/240 meshを保持。Modal.Visible=false。閉じた状態で描画される556meshとは扱わない。 |

Workspace.StreamingEnabled=true、MinRadius=64、TargetRadius=1024、StreamOutBehavior=Opportunistic、StreamingIntegrityMode=PauseOutsideLoadedArea。対象を半径だけで完全に除外できるとは限らない。ModelStreamingBehavior / PhysicsSteppingMethod等、取得できないプロパティは scene.json で unavailable と記録。

実マップSpawnLocationは Workspace.GeneratedMap.TrainingArea.SpawnLocation=(287.8611,3.8983,13.0)。もう一つの Workspace.SpawnLocation=(-12.1389,3.8983,13.0) も存在する。workspace_groups.jsonの初期距離列は後者を基準にした値であり、**現在のPlayerの実スポーン距離として使用しない**。本報告の候補選定は実マップとモデル中心座標を使い、古い距離列を描画範囲判断に使っていない。

**ダンベル：共有と同時表示を分離**

Full Path：
- ServerStorage.World1DumbbellModels.NORMAL_01〜NORMAL_12
- ServerStorage.World2DumbbellModels.W2_NORMAL_01〜W2_NORMAL_12
- Workspace.PerStepButtons.<番号>.World1DumbbellExhibit
- Workspace.World2Map.TrainingArea.DumbbellDisplays.PerStepButtons.<番号>.World1DumbbellExhibit
- ReplicatedStorage.Config.World1DumbbellVisualConfig / World2DumbbellVisualConfig
- ServerScriptService.Services.World1DumbbellVisuals
- ServerScriptService.Systems.Controllers.DumbbellDisplayController / World1DumbbellExhibitController

詳細な24 ItemId・実Mesh/map ID・Full Pathは [dumbbell_asset_summary.csv](dumbbell_asset_summary.csv)、部品単位値は [dumbbell_instances.json](dumbbell_instances.json)。

NORMAL_05は既存7個のPrimitive Part。残る23種類は各Visual MeshPart＋透明Gripの2部品。展示合計53部品/23mesh。全展示がAnchored=true、CanCollide/CanTouch/CanQuery=false、Massless=true。Mesh CollisionFidelity=Default、RenderFidelity=Automatic、CastShadow=true。全モデルにPE/Beam/Trail/Lightなし。

23種類すべて、原本と展示のMeshId・SurfaceAppearanceの4map IDは一致。23個のMeshId、92個のmap IDを確認。同じメッシュの複製は共有資産を利用する構成で、複製回数をファイル読込回数/別テクスチャ数に置き換えない。実際のバッチ数は未取得。

元変換記録のMeshIdと現在のIDを照合できた23種類は3,098〜13,879 triangles、合計273,204（全23モデルを1つずつ数えた参考集計）。これは旧ASSETS.jsonの**変換時記録**で、今回Studioから読み取れた実LODの三角形数ではない。MeshPartのTriangleCount/VertexCountは取得不能。見た目から補間していない。

同じ記録の画像寸法はNORMAL_07の4mapが4096×4096、他22種類は2048×2048。現行IDと結び付く元ファイルSHA256を比較した範囲では、同一hashを異なる現行IDに割り当てた組を発見しなかった。[texture_duplicate_evidence.json](texture_duplicate_evidence.json) に検出範囲を記録。CDN実体を今回再ダウンロードして同一性を証明したわけではなく、他の設備/オーラ素材全体の重複IDは不明。圧縮ファイル容量や幅×高さから実行時メモリを断定しない。

DumbbellDisplayControllerはHeartbeatを0.2秒に間引き、全Playerを確認するが、装備ItemId/World/両手/サイズkeyが同じならcloneしない。外す際に左右TrainingDumbbellを破棄してから付け直す。死亡・CharacterRemoving・PlayerRemovingの片付けがある。原本を変形せず新しいcloneを調整するため、静的に倍率が毎tick累積する経路は見つからない。

World1DumbbellVisualsはClone内のScript等を落とし、手持ちは非Anchored・非衝突/接触/Query・Massless、内部VisualWeld＋Hand Weld。新mesh型の左右合計は4部品/4weld、NORMAL_05は14部品/14weld。装着中のAssemblyMass/ネットワーク所有/実際の接続数は今回はPlay禁止のため未測定。状態キャッシュと置換・片付けは確認できたが、10〜15分の持ち替え/死亡による増殖なしを実証した扱いにはしない。

**エフェクト・照明・半透明**

[effects.json.gz](effects.json.gz) にWorkspace全効果＋ReplicatedStorageのAura/Treadmillテンプレート、計1,551 Instanceの設定を収録。[effect_summary.csv](effect_summary.csv) は経路別集計。[highest_authored_emitters.json](highest_authored_emitters.json) は設定Rate上位。番号のない同名Emitterが複数ある場合、Full Path文字列だけでは一意にならない。配列の各レコードを独立Instanceとして数えている。

- Workspace.Treadmills：36 Emitter / 設定Rate合計477、Beam7。Gold01/Gold02/Diamond01は各12 Emitter・Rate159、Lifetime最大5秒。
- Workspace.World2Map.TrainingArea：82 Emitter / Rate合計6,998、Light44（Enabled、Shadows=false）、Beam7。Treadmill05/06/07の60 EmitterだけでRate6,909。複数の同名Conveyor.ParticleEmitterはRate555・Lifetime0.25・TimeScale約0.3。
- Workspace.Ungroup.Forsaken Characters.Killers.C00lKidd.Milestones.Milestone IV C00lkidd.HumanoidRootPart.Particles.ParticleEmitter：Enabled=true、**Rate=412421**、Lifetime≈0.1、TimeScale=1。極端な設定値なので優先確認するが、エンジン制限・Streaming・可視性・実行時整理を経た実発生数ではない。群全体のRate合計430,839.97を、そのまま実粒子/秒としない。
- ReplicatedStorage.AuraVisualTemplates.Purple_Aura1 / Green_Aura1：各15 Emitter、設定Rate各1,215、Lifetime0.8〜3秒、最大Size＋Envelopeは約9.5/7.125。Red_Aura1は22 Emitter、Rate1,235、Light1。保管テンプレート自体は画面の演出ではなく、装着clone時に人数に応じて増える。
- ReplicatedStorage.Config.AuraConfig:29–36 のEclipseはFlameRate22 / DarkRate10 / LightningRate7、Lifetime0.6〜0.9 / lightning0.16〜0.28、RingRadius2.1 / RingTransparency0.16。ReplicatedStorage.Modules.EclipseAuraVisualが3 Emitter＋4 Beamを生成する設計。Editテンプレートの総数と実行時生成数を混ぜない。
- ServerScriptService.Services.AuraCharacterEffectsは装備/Characterイベントで更新。同じテンプレート・接続なら再cloneしない。交換前に旧cloneを削除、Unbindで接続解除。Sync自身には距離による効果停止がない。種類のVisibleWorldなど別設定は存在するため「すべて常に全Worldで見える」とは言えない。
- ServerScriptService.Services.TreadmillVisualService:6–48 は同じtemplateの再利用/旧effectの置換を実装。自身には距離によるEmitter停止なし。今回のEditの外観がPlay初期化後も同じかは未確認。
- Lighting：LightingStyle=Soft、GlobalShadows=true、PrioritizeLightingQuality=true、Brightness=2.5、ShadowSoftness≈0.15、EnvironmentDiffuseScale≈0.35、SpecularScale=0.25。

半透明の面積・重なり・光源範囲を変えた実測が必要。Transparency=.5、Neonという属性だけで原因とはしない。エフェクトの寿命・Size・Light.Range/Brightness/Shadows等は生JSONに含む。画面上の重なり・距離カリングの実効値は未取得。

**常時処理・ネットワーク・解除**

| Full Path / コード箇所 | 現行処理と実値 | 評価 |
|---|---|---|
| ReplicatedStorage.Modules.FloorGuideRenderer:165–240 | 開始時Workspace列挙1回、各対象PartにChanged監視。staticはCELL=16の空間表、moving/large集合は更新時走査。FixedガイドはHumanoid祖先を除外、通常ガイドは同じ除外条件ではない。 | 毎フレーム全Workspace走査ではない。キャッシュ集合の実数とStreaming時再構築が計測対象。 |
| 同:360–415 | RenderSteppedで矢印2本を一体移動。pool再利用。床サンプル0.25stud、route/scene変更時に再計算。非表示はflow=nil、StopCacheでChanged監視等を解除。 | 通常アニメーション中に毎frame床Raycastを全経路へ再実行する構造ではない。実flow本数/床再構築頻度は未測定。 |
| StarterPlayer.StarterPlayerScripts.Tutorial.World1FloorRouteClient:12–42 | RefreshInterval=.2、World1のみ。World2でHide/StopCache。 | TutorialGuideClientとは別renderer。二つ動く場合の別キャッシュはあるが、これだけで二重表示/バグとは断定しない。 |
| StarterPlayer.StarterPlayerScripts.UI.TreadmillGuideClient:105以降 | ベルト矢印は無限Tween。利用状態でPause/Play、削除でCancel。Workspace DescendantAdded/Removingをdefer集約してタグ設備を再探索。 | 非表示時も必ずTweenが継続する、という証拠はない。遠距離だけの独立停止条件は見つからない。 |
| ServerScriptService.Services.World1WalkwayService | PreSimulationでPlayerごと判定。経路解決.2秒。範囲等を先に判定し、接地Raycast/搬送。LineVelocity/方向は乗車中更新。死亡/World変更/離脱で解除。 | サーバーCPU・Constraint更新/複製をクライアント描画負荷と区別する。 |
| StarterPlayer.StarterPlayerScripts.World.World1WalkwayClient | PreSimulation、経路解決.2秒、乗車中入力送信.05秒（約20回/秒）。サーバー受信は1/30秒制限、timeout .35秒。 | 送信は方向入力。矢印位置を毎frameRemote送信していない。 |
| ReplicatedStorage.Modules.World1WalkwayLocomotion:107–139 | PreAnimationから通常移動の基準観測/乗車中のCore walk/run track補正。AnimateのID再収集はキャッシュ条件付き。 | 搬送時以外にも基準観測がある。長時間track/接続数は未測定。アニメ速度は変更しない。 |
| ServerScriptService.World.BossChaseService:79–175 | Heartbeatで登録Boss、移動中はPivotTo＋BossMotionSpeed。境界判定で最大10試行、登録時の形状点を使う。本来位置でIdleなら早期return。 | 「全Bossを常にPivotTo」は誤り。戦闘中/人数別にserver CPUとreplication、client animationを分けて測る。 |
| ServerScriptService.World.EnemyManager:1197–1201 | 約.1秒で全Playerのcombat状態確認。owner別敵はremoveEnemyで破棄/Chase解除。 | ClientのFPSとserver遅延を混同しない。Pathfindingを毎frame実行する経路はこの対象で確認せず。 |
| StarterPlayer.StarterPlayerScripts.World2BossAnimationClient:113–170 | PreSimulationで登録NPCの速度/clip/gaitを更新。World2以外・削除でclean、Destroyで解除。 | 人数・表示中NPC・戦闘状態で増える。Editの217参照Humanoidを実戦Boss数に換算しない。 |

サーバーによるCFrame/Attribute更新頻度と、実際のネットワーク送信パケット頻度は同一ではない。エンジン集約・ownershipの実効値は未測定。

**物理・Body**

[physics_gui_inventory.json](physics_gui_inventory.json) で確認した、UnanchoredかつCanCollide=trueの部品はUngroup **954**、Stud Egg & Pet **1,475**。ただしUnanchored総数3,219/4,447のうち**2,106/53**はAssemblyRootPartがAnchoredだった。Unanchoredだけを「動く独立Assembly」と数えるのは誤り。sleep状態、物理step、接触数、network ownerはEditでは実測できていない。Stud Egg & PetにはConstraint8、World2Mapには33。必要性や負荷を個数だけで決めない。

ServerScriptService.Systems.Controllers.MuscleCharacterService:6–14 のBodyPrototype経路はIsStudioと対象PlaceIdとEnabledを条件にする。**公開版スマホの原因として扱わない**。通常成長の適用はstageキャッシュを使い、同じstageなら再サイズ適用を避ける（85行付近）。Level/SelectedSizeTier変更で適用する構造で、毎frame無条件にBody全体を再構築する経路は見つからない。

Workspace.Dance Girl.EmoteScriptは1本のループアニメを再利用して重複を整理し、Destroy/無効化/離脱時cleanup。ShopStallTemplateのDanceControllerにも1本のloop再生がある。AnimateScriptはLocalScriptであり、Workspaceに置かれているだけで実行されると断定しない。参照群のInstruction Script2本はコメントのみ。

**UI**

WorkspaceのBillboardGui129＋SurfaceGui161=290、そのうちEnabled235、AlwaysOnTop43。MaxDistance=1000が159、∞が63。これも可視数ではない。両Worldのダンベル24設備ラベルはEnabled=true、MaxDistance=∞。距離だけの上限がないラベル描画は候補だが、Streaming/画面外/遮蔽を経た描画数は不明。

- ReplicatedStorage.Modules.HUDLayout:415–458 と ResponsivePanels:435–462 は初回監視登録、dirty時のみRenderSteppedで配置。無変更時の全GUI再レイアウトを毎frame行う設計ではない。文字/AbsoluteSize/Position等の更新がdirtyへ波及する実頻度が計測対象。
- StarterPlayer.StarterPlayerScripts.UI.MergePanelClient_New:103–124：近接確認.1秒、Pet状態.5秒とItem状態2秒のpollは画面Visible条件付き。閉じたままItem pollが続くとは記録しない。
- StarterGui.StrengthGui.ItemInventoryTabClient:276以降：renderでカード再作成、Forge.Changed、表示切替、装備/所有返信等でrefresh。数値や装備が同じ場合の再構築回数、イベントの集中は未測定。一定周期の全カード再作成ループはこのSourceで見つからない。
- StarterGui.StrengthGui.TimeRewardsClient:122：.25秒wakeするがrenderはpanel.Visible時のみ。
- StarterGui.StrengthGui.StrengthRewardClient:48–85,160：ViewのRemoteFunction照会はVisible非依存。返答からText/Active等を再代入。毎2秒ちょうどではなく応答時間＋wait(2)。値が同じなら必ずChangedが発火するとは限らず、実invalidate数は未知。
- StarterPlayer.StarterPlayerScripts.UI.ItemEffectHUDClient:127–144：TrainingBeltの.55秒往復Tweenは生存・Frame.Visible・IsTraining・TrainingTreadmillを条件にし、外れればCancel。無条件の非表示Tween増殖は見つからない。
- Dailyはイベント時更新。閉じたパネルごとに全UIの常時Tween漏れがあるとする証拠は今回得ていない。

10月のEssentialStudShopのlayout過剰実行は旧環境の記録。現在はlayoutShopがResponsivePanels.Fitへ委譲しており、旧回数を現行の実測値として引用しない。閉じた画面のGPU描画がないことと、保管モデル/接続/照会がないことは別。

**既存計測資料と限界**

reports配下のファイル名検索と関連報告確認では、今回の副本を対象にしたスマホ実機MicroProfiler HTML dumpを発見しなかった。PC全ディスクやクラウドの所在まで否定していない。

[PerformanceAudit_20261020](../PerformanceAudit_20261020/REPORT.md) は別ローカル環境（ローカルPlaceId/GameId=0、参照ログのPlaceも異なる）、PC i5/RTX5060Ti、バックグラウンド約15FPS制限などの交絡を記録。当時のTutorial全走査116.74ms平均/209.68ms最大やABAB結果は旧コード・旧環境の値。現在の空間キャッシュ実装の所要時間ではない。当時もMicroProfiler dumpは取得できていない。World1/World2ダンベルのNativePlay検証はPC/Studioの機能・移動確認であり、スマホFPSの検証に転用しない。

**今回できたこと／まだ必要なこと**

- 確認済み：Edit構成・設定の採取、関連36 Sourceとmain照合、設定Rate/ID/部品数の集計、旧アセット記録との照合、更新/解除経路の静的確認。
- 未実施：実Play、スマホ/タブレット実機、実行時FPS/フレーム時間、CPU/GPU/物理/Script内訳、実メモリ、実LOD/可視数、10〜15分の増殖/熱の確認、公開版との同一性。
- 確実な不具合と断言できない項目：ダンベルの重複clone漏れ、倍率累積、全GUIの毎frame更新、矢印の毎frame全経路Raycast、公開環境でのBodyPrototype稼働。静的に予防/解除条件があるものは上に記載したが、実行時合格にはしていない。
- 比較用スイッチや候補変更の採用判断は実機計測後。本体の見た目・機能・報酬・保存仕様を削らない。

**実機計測計画とユーザー操作**

具体的なシーン表、CPU/GPU/物理/Scriptの比較、PCへのMicroProfiler保存方法は [MEASUREMENT_PLAN.md](MEASUREMENT_PLAN.md)。記入用CSVは [measurement_template.csv](measurement_template.csv)。測定値欄は空欄で、架空の結果を入れていない。

最初の比較は**同じロビー地点で設備方向→壁方向→設備方向**。次に同条件でWorld2ロビー、戦闘、インベントリを比較し、開始直後と10〜15分後を分ける。公開中のビルドしか実機へ入れない場合、それを現在の未保存副本と同一として評価しない。今回は公開を要求・実行しない。

**成果物・再現**

- scene.json / workspace_groups.json / asset_census.json：配置・サービス・資産ID種類数。
- dumbbell_instances.json / dumbbell_asset_summary.csv：24種類の原本/展示/物理属性/素材。
- effects.json.gz / effect_summary.csv / highest_authored_emitters.json：全対象効果と集計。
- physics_gui_inventory.json：物理交差条件、World GUI値、関連Workspace Script読取。
- source_comparison.json：現物とGitの照合、4差分のStudio Source。
- summarize_evidence.py：**オフラインのJSON/CSV集計だけ**。Studio接続/Source実行/ゲーム変更なし。
- read_effect_inventory.luau：今回用いた読み取りクエリ。OFFSETを0から戻りRecords数ずつ進め、Editのみで実行する形式。ゲームには取り込まない。
- git_observation.json / final_verification.json：Git・保護対象・最終照合。ハッシュ一覧は manifest.sha256。
- このフォルダーだけを明示stageし、通常commit/pushする。ゲームSource・Studio設定・DEV_STATUS等の別ファイルは変更しない。

Studioは既存未保存編集を保ったEditのまま開いている。Play/Stop・Save/Publishは未実施。FPS最適化実装・DataStore警告調査/修正には進んでいない。
