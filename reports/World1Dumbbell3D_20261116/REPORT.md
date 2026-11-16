# World1 ダンベル3D実装（2026-11-16開始／2026-11-17更新）

> 2026-11-17素材整理: 現在のローカル素材は `C:\Users\kouji\Downloads\World2Dumbbells_20261117\World1` に集約。重複ZIPは展開内容照合後に削除。以下の取得時パスは履歴。[移動・削除記録](../World2Dumbbell3D_20261117/UI08_AND_MATERIALS.md)。

対象：副本 PlaceId **126576845524886**、Universe **10765181857**。接続実値と所有者 User **7467238848** を確認。
現在の未保存Studio編集を基準に反映。正本・PR #1・Save／Publishは操作していない。

## 実装内容と変更 Full Path

| Full Path | 変更 |
|---|---|
| ReplicatedStorage.Config.World1DumbbellVisualConfig | 新規。12 ItemIdのテンプレート、展示・手持ちのサイズ／回転／位置補正 |
| ServerStorage.World1DumbbellModels.NORMAL_01〜NORMAL_12 | 新規の表示専用ライブラリ。05だけ既存モデルの複製 |
| ServerScriptService.Services.World1DumbbellVisuals | 新規。表示専用複製、寸法、グリップ、非物理部品設定 |
| ServerScriptService.Systems.Controllers.World1DumbbellExhibitController | 新規。World1の設備展示だけを更新 |
| ServerScriptService.Systems.Controllers.DumbbellDisplayController | 既存両手表示へWorld1登録モデルを接続。死亡／離脱の後始末 |
| Workspace.PerStepButtons.1〜12.World1DumbbellExhibit | 各設備のItemIdと一致する展示 |
| Workspace.PerStepButtons.1〜12.BillboardGui.ItemIcon | ImageとVisible・レイアウトを維持し、ImageTransparency=1。元値を属性へ保持 |

購入用Press／既存部品の位置・サイズ・判定と、価格／説明Textを保持。
ショップ／インベントリ等の画像とDumbbellItemMasterは変更しない。
設備画像の行を消さず透明化することで、価格などのUIListLayout位置を保つ。
World2の設備および既存手持ちテンプレート処理を維持。

手持ちは従来どおり**左右に1本ずつ**。新しい装備システムやBackpackは追加しない。
DumbbellService.GetEquippedDumbbellが返す、ロード済み・所持確認済みの装備ItemIdに従う。
最高所持品を選ぶ既存処理も変更しない。サーバーで複製するため他プレイヤーにも反映する。
World2装備をWorld1の同番号へ置換しない。

新手持ち部品はAnchored=false、CanCollide／CanTouch／CanQuery=false、Massless=true。
グリップ中心を手へWeldConstraint接続し、モデル内部も接続する。
モデルごとの購入Part・Script・PackageLink・外部ジョイントは持ち込まない。
カメラ、アニメーション速度、HumanoidのWalkSpeedは変更しない。
ロード待ち／未所持／テンプレート欠落は表示を外して進行を継続。欠落警告はItemIdごとに一度で、Heartbeatから読込・生成を連打しない。

## 手動調整

設定場所：**ReplicatedStorage.Config.World1DumbbellVisualConfig.Items[ItemId]**。
Source変更は**次のPlay／新しいサーバー開始時**に反映する。
ModuleScriptはrequire結果をキャッシュするため、実行中のSource編集だけでは値は切り替わらない。
Editで既に配置された展示も、自動では再配置されない。次のPlayでは展示Controllerが再生成する。
StudioでEdit展示を合わせる場合は、新しく読み込んだConfigでWorld1DumbbellVisuals.RefreshExhibit(stand,true)を実行する。

| 設定 | 現在値 | 意味／単位 |
|---|---:|---|
| Template | NORMAL_01等 | ServerStorage.World1DumbbellModels直下のモデル名 |
| DisplayLength | 4.8 | 展示のバー方向全長、studs |
| DisplayRotation | (0,0,0) | Press座標系での回転、度 |
| DisplayOffset | (0,8.4,0) | Press基準のグリップ中心位置、studs |
| HeldLength | **2** | 手持ちのバー方向全長、studs。横幅は拡大前の値を維持 |
| HeldThicknessMultiplier | **1** | ItemIdごとの基本の厚み倍率。小さいBodyでは形状を変えない |
| BodyThickness.BaseHeightRatio | **1** | 追加の厚み倍率が始まるBody高さ比 |
| BodyThickness.FullHeightRatio | **2** | 追加の厚み倍率が上限に達するBody高さ比 |
| BodyThickness.MaxMultiplier | **1.5** | 大きいBodyの追加厚み倍率の暫定上限 |
| HeldRotation | (0,0,0) | 手の座標系での回転、度 |
| GripOffset | (0,0,0) | 手に対するグリップ中心補正、studs |
| HandOffset | (0,-0.15,0) | 既存の非Body比較時の手位置補正 |

体型比較中は既存BodyPrototypeDumbbellScaleと、手の高さの12%の持ち位置補正を維持。
HeldLengthとGripOffsetには既存の体型倍率を適用する。毎回新しいテンプレートから絶対寸法で複製し、持ち替え／体型変更の倍率を累積させない。
追加指示「3倍はやりすぎ、小さいときは倍率変更不要」に合わせ、固定3倍を撤回した。小さいBodyは1倍。既存MuscleHeightScaleが1〜2の範囲で、厚みを1〜1.5倍へ連続補間し、2以上で上限に止める。横幅（ローカルX）は維持し、グリップ中心を基準にY/Zの寸法と位置だけを調整する。元FBXと登録テンプレートは変更しない。
大きいBodyの上限について選択肢を提示し、回答前のため、控えめな**1.5倍を暫定値**とした。通常成長最大Bodyは実高さ比1.689なので、追加の厚み倍率は約1.345。小さい筋肉Bodyも実高さ比1以下なら追加倍率は1。
例：BodyThickness.MaxMultiplier=1で体型による追加厚みを完全に停止。1.25なら上限1.25倍。特定ItemIdだけ調整する場合はHeldThicknessMultiplierを変更する。HeldLength=2のまま横幅を維持できる。GripOffset=Vector3.new(0,0.1,0)で手のローカル上方向へ0.1 studs補正。
展示サイズはこの変更と独立して4.8 studs。
ユーザーの追加指示により、**体との見た目の重なりは許容**。干渉を避けるための縮小は行わない。

## 元ファイル・登録アセット

Windowsの実Downloadsを確認し、指定11 ZIPと各FBX／テクスチャを確認した。
一覧PNGは未準備という追加指示に従い使用していない。

- 元ZIP：C:\Users\kouji\Downloads\tripo_convert_UUID.zip
- 保持した展開元：C:\Users\kouji\Downloads\World1Dumbbells_20261116\originals\NORMAL_xx
- 取込用作業コピー：同フォルダーのexports\NORMAL_xx.glb
- 所有者7467238848、対象Universe10765181857の作成コンテキストでModelを11件アップロード。すべてApproved。
- アップロード用フォルダーの権限拒否時は中止。ユーザーのフォルダー登録後に正常実行した。再アップロードなし。
- すべて20,000三角形以下（3,098〜13,408）。軽量化・頂点削減・色変更はしていない。
- 作業コピー上でバーをローカルX方向へ揃え、グリップ中心を原点へ移す回転／平行移動のみ。
- BaseColor=sRGB、Normal／Roughness／Metallic=Non-Color。GLBのroughness G／metallic B対応も検査。
- 元FBX／JPEGを保持。Gitには元データやGLBを入れず、ID参照と[登録済みモデルの復元用スクリプト](../../tools/InstallWorld1DumbbellModels.luau)を保存。既存ライブラリがあれば停止し、全体を上書きしない。Roblox内部のメッシュ寸法・合成マテリアル情報を保持するため、正規のInsertService:LoadAssetで登録済みMeshPartを複製する。
- 詳細なファイル名、ハッシュ、三角形数、元マップと登録IDは[ASSETS.json](ASSETS.json)。

05は**ServerStorage.Templates.DumbbellDisplayTemplate**の7個の既存Partを使用。
既存展示は2D画像だったため、従来の手持ち表示に使っていた実体を特定して再利用した。
新規アップロードなし。旧画像名W1-5Dは06に対応し、05との入替は行っていない。

| ItemId | 元ZIPのUUID | Model ID | Mesh ID |
|---|---|---:|---:|
| NORMAL_01 | a88c0024-1595-4271-9fcd-431e840fcf95 | 100003248943176 | 94546154900247 |
| NORMAL_02 | fb3a75b8-70a5-4f8e-a943-4361a85dfb47 | 106469049055541 | 93773538534734 |
| NORMAL_03 | 5f42bf33-1673-4cd7-b611-3f092cae80b1 | 102433513297786 | 112471800394719 |
| NORMAL_04 | e2eea638-64b6-4800-8c5d-ab57ca813c8a | 93150737705355 | 70408019440632 |
| NORMAL_05 | 既存テンプレート | — | primitive Parts |
| NORMAL_06 | 4a01d4c0-a254-4af4-86fa-1f599ed18a73 | 94440891847547 | 122807268376475 |
| NORMAL_07 | 664a0906-864b-4752-9f22-be7769f00df7 | 101503029468609 | 104987959664688 |
| NORMAL_08 | 4a3ad0b8-f756-4462-a3d9-f8bebf800217 | 82472684564277 | 81262227275291 |
| NORMAL_09 | 1d429733-b5b6-48b1-9b48-f9d08a9de8b7 | 82180382781576 | 121550619495763 |
| NORMAL_10 | 9d34e00c-6acc-46d0-9e54-e2b0bdca123d | 77746198788025 | 135964415610728 |
| NORMAL_11 | 8cee376d-7bdb-4d1a-92c3-234c25a0206e | 74066961638377 | 85891133806939 |
| NORMAL_12 | 3267a786-95a1-4f0e-88e0-2fdc600b8f98 | 122102219580338 | 112477605860353 |

| ItemId | BaseColor ID | Normal ID | Roughness ID | Metallic ID |
|---|---:|---:|---:|---:|
| NORMAL_01 | 127699806641624 | 124796643512732 | 108748008084662 | 92062689807579 |
| NORMAL_02 | 94958906865185 | 95083219588816 | 139625629168917 | 140150685934556 |
| NORMAL_03 | 93549456299639 | 101161404896879 | 100430872060015 | 127291977808089 |
| NORMAL_04 | 139905511090529 | 109564890019761 | 117558394568054 | 106517204533390 |
| NORMAL_05 | — | — | — | — |
| NORMAL_06 | 136648309742188 | 130511227200958 | 135586196105763 | 126431149639476 |
| NORMAL_07 | 87276775290357 | 136994217526038 | 74195273034249 | 111692835610018 |
| NORMAL_08 | 123774794491484 | 126126012997771 | 87556769992648 | 93211813743102 |
| NORMAL_09 | 106865796385995 | 87976924111481 | 94570911017132 | 81255388349424 |
| NORMAL_10 | 105414794303318 | 83565532762026 | 110866506372039 | 128085144745544 |
| NORMAL_11 | 124050239207960 | 122727794400670 | 91043928845054 | 83663942152891 |
| NORMAL_12 | 116892275035446 | 116482099466797 | 113595243516490 | 83013328600151 |

## 画像

画像はユーザー指定により保存。元モデルからの3Dレンダリングと、Studioの撮影を区別する。

- [元FBXからの11種類比較](images/source_models.png)：Blenderで作業GLBを描画。05の欄はStudio既存品のため空欄。
- [設備変更前](images/stations_before.png)／[12種類の設備変更後](images/stations_after.png)：副本Editで撮影。
- [厚み変更前](images/held_body_comparison.png)／[小Bodyは1倍、大Bodyは控えめな厚みの現在設定](images/held_final_body_comparison.png)：通常Bodyと通常成長最大BodyのEditプレビュー。実Playの動作証拠ではない。

## 検証

副本本体でPlayは開始していない。
保存処理を含まない新規ローカルPlaceId 0に、許可した24 Sourceと表示／設備／Body検証用の幾何だけを配置。
実行前にPlaceId、ソース数、全ソースの構文、保存／課金等のサービスが含まれないことを検査し、成功後だけ2クライアントPlayを開始する。
Production PlayerDataServiceは含めずメモリー内fixtureへ置換。Strengthの最終保存や購入を試すものではない。
BodyPrototypeはfixtureのPlaceIdゲートのみ0へ変更し、寸法計算は現行ソースを使用。体型切替の待機は検証用の制御であり、本来のBody比較UIの総合テストではない。

### 実Playで確認した範囲

2クライアントで12種類の装備切替、各両手のItemId、非物理設定、各設備の単一生成、他者からの表示、Lobby退出／帰還、ロード待ち／復帰、所持消失、World2既存モデルへの復帰、死亡復帰、4回のLobby往復を確認した。テンプレート欠落時の片手残置なし・継続動作・実際の装備変更による再試行も確認。

最終形状調整前の広範囲検査は80項目中79項目を通過。残る1項目は初回の歩行速度差を0.8 studs/s以内とする検査で、無装着21.03／装着22.09 studs/sとなり基準外。移動速度の完全一致を合格扱いにしていない。詳細は[生の測定結果](PLAY_RESULTS.json)。

| Body（比較fixture） | 無装着 studs/s | 装着 studs/s | ジャンプ上昇量（装着） | AssemblyMass一致 |
|---|---:|---:|---:|---|
| 通常・初回比較 | 21.03 | 22.09 | 7.27 | 一致 |
| 通常・成長最大 | 23.47 | 23.98 | 7.27 | 一致 |
| 筋肉・最小 | 1.76 | 0.61 | 7.27 | 一致 |
| 筋肉・成長最大 | 21.89 | 22.08 | 7.27 | 一致 |
| 通常・手動最大10×10 | 24.00 | 23.91 | 7.27 | 一致 |

全条件でWalkSpeed=24を保持。短時間の壁時計測定には揺れがあり、特に筋肉最小Bodyはダンベルなしでも正常な歩行速度に達していないため、操作感の確認完了とはしない。通常・最大Bodyの動作は実際に動かしたが、副本の本来のBody UI／配置処理を含む統合確認を残す。

TrainingManager本体は、通常初期・筋肉最小／最大・手動最大の条件で、装着有無とも1.15秒中に2回の加算呼出しを確認。通常成長最大では装着有無とも0回で、両足の底がfixtureの判定帯上端より高くなり判定外だった。ダンベル追加による差はないが、その体格でのTreadmill成立を確認済みとはしない。StrengthManagerの最終計算・保存はメモリー内の記録先に置き換えており、本番Strengthの加算値を検証したものではない。

購入設備は現行DumbbellStandServiceの入場コールバックを確認。実際の購入・マージ・売却・再参加保存は実行していない。表示の前後でfixture内の所有品・装備・Strength／Winデータが勝手に変更されないことを比較した。

### 読込・静的確認

現在の控えめな厚み設定でも2クライアント実Playを再実施し、80項目中78項目を通過。[最終設定の生結果](PLAY_RESULTS_FINAL.json)。通常初回の速度一致検査（無装着21.82／装着24.00）と、筋肉最小Bodyの移動／ジャンプ比較が基準外。最小Bodyは無装着でも6.31 studs/sと通常速度へ達せず、装着時1.14 studs/sだった。原因を本体の不具合と断定せず、fixture内の体型切替・接地と実副本での確認を残す。全項目合格とは報告しない。

最終設定の通常成長最大は無装着24.01／装着24.01、筋肉成長最大23.97／23.90、手動最大24.09／24.00 studs/s。これらのAssemblyMassは装着有無で同じ。所有・装備同期、死亡・Lobby・World往復、欠落資源時の動作、Treadmill呼出し比較は再確認済み。

静的寸法確認は12モデル×5つのBody高さ比（0.5／1／1.5／2／10）の60ケース。横幅2 studsの維持、厚み倍率1／1／1.25／1.5／1.5、中央グリップ基準を確認。通常成長最大の実高さ比1.689では倍率1.344547、小Bodyの倍率は1。元の体型による全体倍率は別に維持する。

副本Editで11メッシュ＋44テクスチャ全てのAssetFetchStatus.Successを確認し、12設備の実表示を撮影。隔離Playでも全11メッシュの読込と色・質感の表示を[撮影](images/isolated_play_exhibits.png)。SurfaceAppearanceは合成済みtexture packで描画されるため、Playの生マップURIのfetch状態だけでは44枚の読込成否を判定できない。[Roblox公式のPreloadAsync制限](https://create.roblox.com/docs/reference/engine/classes/ContentProvider#PreloadAsync)に従い、初期の生URIプリロード失敗を読込済みという判定へ流用していない。

検証用の幾何XMLだけではネイティブのMeshSize／合成マテリアル情報が不足したため、隔離Play前に登録済みModelのMeshPartを正規APIで複製して補完した。副本へ配置した本体は最初からこの正規複製であり、同じ欠落はなかった。Roblox内部のTexturePack直接参照は権限不足で拒否され、利用していない。登録済みModelの取込・利用権限の拒否ではない。

保護対象596 Instanceの既存位置・寸法・衝突・価格Text・Image等に差分なし。元523 Sourceのうち変更はDumbbellDisplayControllerだけで、削除なし。新規Sourceは3つ。DumbbellItemMaster、DumbbellService、TrainingManager、個別ガイド、報酬・保存処理は変更していない。新規モデルにScript／外部処理なし。

### 未確認・制約

- 正規データを使った購入→装備、マージ／売却→持替、再参加保存の総合操作。本番所有・報酬・保存は未変更だが、実操作の確認済みとはしない。
- 実スマホ／タブレット／ゲームパッドの操作感・端末負荷。画像はPC Studioでの撮影。680×382のfixture画像を実端末試験とは呼ばない。
- 副本全体の戦闘・進行・個別ガイド・Body比較UIを含む回帰と、公開環境のアセット権限／読込。
- Player退出時の破棄はコード確認。実Playはセッション終了までで、個別切断の後始末を独立計測していない。
- fixtureのCoreGuiでCreatorType未設定由来のエラーと、既存看板画像119910397965139の権限エラーが発生。今回のダンベル11モデルのエラーとは区別した。検証のために権限を回避したり、既存画像を差し替えたりしていない。

## 完了時の保持・Git

副本の4変更Sourceについてローカルファイル／Studio Source／Editor Sourceの一致とネイティブ構文を確認。元の未保存編集を全体同期していない。展示12、テンプレート12を保持し、取込用の一時フォルダー、比較撮影用キャラクター、検証用_G値は除去。別fixtureは終了し、副本は未保存Editで開いたまま。Save／Publish、正本、PR #1、force pushは行っていない。

Gitは今回のSource、アセット対応表・復元スクリプト、比較画像、検証コード、報告と関連仕様の追記だけを対象とする。既存の未追跡crashes/、元ZIP／FBX／テクスチャ／GLB、tmpの検証用Placeは含めない。

検証再実行用のtests/build_world1_dumbbell_fixture.pyは、今回採取したローカルのtmp/Dumbbell3D/geometry.jsonを入力として新規Placeを構成する。元ゲームの保存処理は含めない。RunFixture.luauの隔離assertが失敗した場合は、後続のExecuteMultiplayerTestAsyncへ進まない。登録モデルの復元スクリプトも既存ライブラリがあれば停止し、上書きしない。
