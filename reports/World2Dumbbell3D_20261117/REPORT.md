# World2ダンベル・8番UI・Body/Treadmill調査

2026-11-17 更新。**05の髑髏・09の目玉を登録し、World2全12種類の3D展示が副本Editに揃った。World1/World2展示全長7.2 studs、テキストはモデル上部。05/09は左右手持ちのEdit接続・描画確認済み、実Playは未実施。8番UI画像の実インベントリ/マージ画面描画は未確認。**

最新の[05/09の登録ID・選定根拠・Edit確認・未確認範囲](W20509_IMPLEMENTATION.md)。以下の旧実Play記録は登録10種類の時点の証拠。

前段の[展示サイズ・上方ラベル・09入力・確認画像と未確認範囲](EXHIBIT_SCALE_AND_W209.md)。以下の隔離Play記録は展示拡大前の検証であり、今回のラベル変更はEdit確認のみ。

最新の[8番画像ID・素材集約・削除記録・確認限界](UI08_AND_MATERIALS.md)。

対象実値: PlaceId **126576845524886** / UniverseId **10765181857** / Creator User **7467238848**。現在の未保存編集を基準とした。再開時HEAD/origin/mainは **c4a55e5f06e86c9dfc47cfdd320526237bb078d2**。84e999cへ巻き戻していない。前段の原因調査・修正前後の生測定は[BODY_PHASE.md](BODY_PHASE.md)に保存した。

## 現在の反映内容・Full Path

- 新規 `ReplicatedStorage.Config.World2DumbbellVisualConfig`。ItemId単位の展示・手持ち調整。
- 新規 `ServerStorage.World2DumbbellModels.W2_NORMAL_01〜12`。各1原本、GripとネイティブMeshPart/SurfaceAppearanceのみ。
- 変更 `ServerScriptService.Services.World1DumbbellVisuals`。従来名を保ち、完全ItemIdからW1/W2のConfigと原本を選ぶ共通表示処理。
- 変更 `ServerScriptService.Systems.Controllers.World1DumbbellExhibitController`。既存1コントローラーで両Worldの設備を監視。
- 変更 `ServerScriptService.Systems.Controllers.DumbbellDisplayController`。既存装備同期・左右2本の処理を利用。legacy部品のCanQuery=falseを追加。
- 展示追加 `Workspace.World2Map.TrainingArea.DumbbellDisplays.PerStepButtons.<1..12>.World2DumbbellExhibit`。現在は全12番号に反映済み。
- 前段c4a55e5の変更 `ServerScriptService.Services.TrainingManager` は保持。再開分で追加変更なし。

新しい装備システムや表示ループは追加していない。DumbbellServiceの有効な装備ItemIdと既存Lobby判定に追従する。World移動だけで装備品を別Worldの同番号へ変換しない。複製はサーバーが生成し、左右のHandWeldで接続。手持ちBasePartはAnchored=false、CanCollide/CanTouch/CanQuery=false、Massless=true。体型変更時は原本から再作成し倍率を累積させない。

購入・価格・Strength倍率/周期・LV・所有/装備/マージ/売却/保存のSourceは変更していない。World1登録12種類と05の既存原本を維持。新展示だけ元ItemIconを透明化して二重表示を防ぎ、画像ID・レイアウトは保持する。設備の既存84部品の位置/寸法/接触等と37ラベルの文字列は変更なし。

## 元ファイル・登録ID

取得時の元ZIPは実Downloads `C:\Users\kouji\Downloads`。現在はユーザー指示により `Downloads\World2Dumbbells_20261117\World2\originals\<UUID>` と同World2配下のexportsへ集約し、全内容が展開済みファイルと一致した重複ZIPは削除済み。全12元FBXは異なるSHA256。ファイル順やskull_maceという名前だけで割り当てていない。[元モデルの描画比較](images/source_models.png)と[旧設備/UI画像](images/icons_before.png)を照合した。

追加されたモデル用フォルダー権限で10件のアップロードが成功。全件同じ正規所有者へ1回ずつ登録し、再アップロードせず再利用する。ZIP名は `tripo_convert_<UUID>.zip`。

| ItemId | 元ZIPのUUID | Model / Mesh ID |
|---|---|---|
| W2_NORMAL_01 | be9de5d1-da96-4257-b9fa-0e9cfc268e96 | 120423306946269 / 72012182548192 |
| W2_NORMAL_02 | 699aff5d-dfc7-47af-8c04-3d2fc97fbd2d | 102716104784959 / 117246680201459 |
| W2_NORMAL_03 | c29ae88b-713b-40c8-a674-7cc619ae9784 | 128085702169072 / 121454316614909 |
| W2_NORMAL_04 | 325c88e5-35ce-4599-abbc-d6add5edffa0 | 117230570003114 / 128283127982055 |
| W2_NORMAL_05 | 129491e9-6098-49c1-85c7-bb7dda049030 | 72432008607429 / 82927178003009 |
| W2_NORMAL_06 | 15b4b34a-ee7b-4724-a23d-840821ad4b01 | 76372035088717 / 110179195904955 |
| W2_NORMAL_07 | 6f4d6c73-89cb-4430-a575-6c6cdf56fdd4 | 79273947117738 / 134262823105301 |
| W2_NORMAL_08 | c0336e3e-4fa8-4e1b-8c0d-8ec6e1aa5dc5 | 127996101926091 / 102402230962981 |
| W2_NORMAL_09 | 1d5bb350-b333-46b5-97b0-f61929c85f98（ユーザー指定） | 76842591874956 / 71030764434000 |
| W2_NORMAL_10 | 45523401-b6e5-40be-886e-87653b1ca616 | 89304737924828 / 107482140752258 |
| W2_NORMAL_11 | 850c42fe-67c0-4846-9611-d1d1e7b1c6c0 | 115656579181767 / 80759512986628 |
| W2_NORMAL_12 | 1f4b4e93-389d-433a-a119-495af875a4b4 | 121212954959648 / 115333744093861 |

実Model/Mesh/**BaseColor・Normal・Roughness・Metallicの全48 ID**、ZIP/FBX/各テクスチャのSHA256、寸法/補正は[ASSETS.json](ASSETS.json)、登録成功記録は[UPLOADS.json](UPLOADS.json)。08は指定の紫水晶＋黒い岩。Model **127996101926091** / Mesh **102402230962981**、4マップは **130992463031571 / 86500659021694 / 86256269074579 / 107419410147538**（上記順）。

BaseColor=sRGB、他3種=Non-Color。元ファイルを保持し、減ポリゴンや色/装飾の変更なし。柄方向X・グリップ中央を原点へ揃える剛体補正だけを作業コピーに適用。約12.5〜13.9k triangles/モデル。巨大FBX/GLB/重複素材はGitへ含めない。登録原本にはScript・外部ジョイント・購入処理を含めない。

05は既存UIと同じ白い髑髏・赤い棘・骨の柄を持つ129491e9を描画比較して採用。d359c5a6も同じ意匠の別形状であり、未使用素材として保持。09は追加された目玉FBXをユーザー指定で採用。選定と実IDの詳細は最新の05/09報告に記録した。

## 手動調整と復元

設定は `ReplicatedStorage.Config.World2DumbbellVisualConfig.Items.W2_NORMAL_XX` の一か所。

| 設定 | 意味・現在値 |
|---|---|
| Template / SourceUUID | 登録原本名 / 元ファイル追跡用UUID |
| DisplayLength | 展示の柄方向X全長、7.2 studs（今回1.5倍） |
| DisplayOffset | Pressのlocal座標基準、(0,8.4,0) studs |
| DisplayRotation | 展示local軸回転、degrees |
| HeldLength | 手持ち柄方向X全長、2 studs（既存Body全体倍率適用前） |
| HeldThicknessMultiplier | 種類別Y/Z厚み、1。Xへ追加しない |
| HeldRotation / GripOffset | 手持ちlocal軸回転degrees / グリップ補正studs |
| BodyThickness | 小Body追加1、大Body追加上限1.5。既存BodyPrototype全体倍率と別 |

例: 08の手首位置だけ下げる場合 `GripOffset=Vector3.new(0,-0.1,0)`。展示幅だけ変える場合 `DisplayLength=5`。横幅を維持して大Body厚みだけ調整する場合 `BodyThickness.MaxMultiplier`。Config変更は**新しいPlay/server開始時**に反映。Editで既にrequireされたModuleのキャッシュは自動更新されない。展示は次のPlayで初期化、未保存Editの見た目も即変更したい場合は最新SourceでのRefreshExhibitが必要。

原本復元: [tools/InstallWorld2DumbbellModels.luau](../../tools/InstallWorld2DumbbellModels.luau)を指定副本のEditで実行する。対象Place/Universeをassertし、登録ModelからネイティブMeshPart/SurfaceAppearanceを取得して不足原本だけ復元する。既存原本を上書きせず、登録ID不一致なら停止。PlaceのSave/Publishはしない。原本と上記4 Sourceが揃うと既存コントローラーがPlay時に展示/両手を複製する。復元は正規のasset読込権限が必要。復元用登録一覧は今回05/09を追加し、全12件に更新済み。

## 隔離した実Play

[VISUAL_PLAY_13.json.gz](VISUAL_PLAY_13.json.gz)は **2クライアント・289項目、失敗0**。PlaceId=0、現行Source39本の許可リスト/構文/禁止API/筋肉15部品MeshSizeと質量一致を**Play前にassert**した。[Sourceハッシュ・依存・禁止API](VISUAL_PLAY_MANIFEST.json)。副本を直接Playしていない。

実Lobby生成・BodyPrototype/体型適用ACK・MuscleCharacterService・装備Service・表示Controller・実設備形状・TrainingManager・StrengthManager/Calculation/LevelProgressionを通す。保存処理を持つ本番PlayerDataServiceは含めず、現行AddStrengthGain本体をそのまま使うメモリadapter。GamePass/Item/Potion/Aura/Pet/Analyticsは明示した効果0/倍率1/送信なしadapter。本番DataStore・課金・外部送信実装なし。公開環境でBody試作を有効化していない。

確認できたこと:

- W1全12、W2確定10の左右2本、登録原本と展示/手持ちMeshId一致、展示各1つ、安全な部品属性と左右接続。W2の05/09はPendingとしてlegacyを確認し、新モデル合格数に含めない。
- W2実10 MeshのAssetFetchStatus=Success、ネイティブSurfaceAppearance付き実描画。Editで全4マップの実IDを確認。各マップ単独のHTTP取得やレンダラー内部の使用率は測定していない。
- 持ち替え、Worldをまたいでも実ItemId維持、Lobby退出/帰還、ロード待ち/復帰、所有数0/復帰、モデル欠落時の部分装着なし/連打再試行なし、復元後持替えで再表示。
- 実DumbbellStandServiceがWorld2の08 Pressへの接近を検出。実購入は行わずcallbackを検証用に置換。価格・購入成功・マージ・売却の全UI経由操作を通した確認ではない。
- 4体型×装着有無の歩行/停止/ジャンプ、両Worldの接地鍛錬/退出/空中/資格喪失/復帰、死亡で加算停止・表示残置なし・復帰後再鍛錬。
- 2クライアント相互の表示。自動試験はW1 ItemIdの独立性も確認。追加観測で一方W2_NORMAL_08、他方W2_NORMAL_12の左右Meshを相手クライアントから取得した。[追加記録](PEER_WORLD2_HANDS.json)。

歩行速度はWalkSpeed=24の既存値を維持し、接地安定後、加速1秒を除いて2秒間の実変位を3回測定。単位studs/s。

| Body | 非装着3回平均 | W2_NORMAL_08装着3回平均 |
|---|---:|---:|
| 通常最小 | 24.0012 | 24.0127 |
| 通常成長最大 | 23.9886 | 24.0072 |
| 筋肉最小 | 24.0144 | 24.0030 |
| 筋肉成長最大 | 23.9916 | 24.0025 |

24試行は23.9562〜24.0572。体型切替後の通常Body再測定23.9801。状態/入力/速度/部品/質量/HipHeightは生データへ記録。今回の装着品はW2_NORMAL_08。Bodyやダンベルを縮小して低速を隠していない。

実メモリStrength増分は全体型で、1.65秒の3 tickあたりW1非装着+3/08装着+5403、W2非装着+15/08装着+27015。現在の08加算1800と既存台倍率を含む正規計算で、倍率や0.5秒設定は変更していない。加算呼出し数だけでなくStrength/LevelProgress更新を記録した。

先行run11はテストがruntimeからSurfaceAppearanceの旧ColorMapプロパティを読み、Plugin capability不足で停止。テストだけをEditでのID照合＋runtime native object/描画確認に変更した。run12は159項目後、退出先が実Lobby床の外で落下/死亡し次のRoot参照が失敗。fixtureだけにLobby範囲外の着地床を追加した。本体の床や接地条件は変更しない。[run11](VISUAL_PLAY_11.json.gz) / [run12](VISUAL_PLAY_12.json.gz)は失敗記録であり合格ではない。

run13ログでは意図したW2_04欠落警告1回と、既存W1看板画像119910397965139の読込権限エラーを観測。後者を新W2モデルのエラーと混同しない。新表示ControllerのRuntime Error/Infinite Yieldは観測なし。撮影補助のVector3.ToString誤使用1回は撮影用MCP呼出しだけで、本体Sourceへ入れていない。

## 確認画像・端末の限界

- [World2全12枠の設備展示](images/world2_exhibits_play.png)。05/09は旧画像、他10枠は新3D。
- [通常Body・08両手](images/world2_held_normal_08.png) / [通常成長最大Body・08両手](images/world2_held_maximum_08.png)。背景の別Playerと手持ちは別Assembly。体との見た目の重なりは許容。
- [iPhone 17 Pro相当・横](images/world2_phone_landscape.png) / [13インチiPad Pro M5相当・横](images/world2_tablet_landscape.png)。隔離Playで端末エミュレーションとタッチ操作UIを描画した。実タッチ/スティック操作やFPS/端末負荷を測定した意味ではない。

副本Editの画面取得が白くなるため、掲載画像は最新Sourceと実設備を移した隔離Playで撮影した。元Studioのカメラ/GUI/端末設定は復元し、白画面を直すために本体を改変していない。

## 8番UIと残る未確認

指定PNGをユーザーの明示指示で許可済みフォルダーへまとめ、Image **112266643972428** を登録。`ReplicatedStorage.Config.World2GameplayConfig.DumbbellImages[8]` の1か所へ反映した。DumbbellItemMasterからインベントリ一覧/詳細、マージ候補/完成結果へ共通参照する。PNGのアルファ/縦横比を保持し、3Dテクスチャで代用していない。

新規ローカル起動を止める指示に従い、追加のUI Playは行っていない。ContentFetchはSuccess、実UI描画・新画像の画面証拠は未確認。[詳細](UI08_AND_MATERIALS.md)。前段のフォルダー許可待ちは解消。

その他未完了/未確認:

- 全12新3Dでの実Play確認（Editでの12対応と05/09読込・接続・描画は確認済み）。
- 実購入、マージ/売却から装備が変わる全進行、再参加での本番ロード。今回の装備/所有変化は隔離メモリ状態での確認。
- 実機、公開環境、実データ保存、課金、実キー/ゲームパッド/タッチの操作感、端末FPS、大人数負荷。
- 全サービス同時の統合Play、手動極大Body。今回の物理マトリクスは通常/筋肉それぞれ成長0/10。

## Body2件の原因と修正範囲

前段の同条件比較と生データは[BODY_PHASE.md](BODY_PHASE.md)。筋肉最小の旧低速はfixtureのMeshSize/InitialSize欠落を補完しただけで、装着1.1478→24.0373、非装着1.7248→23.9832へ復帰。WalkSpeed/Body/手持ち寸法の本体変更なし。

通常成長最大の旧Treadmill不成立は仮設Area高さ0.8と実設備高さ15の相違。現行生成＋実形状では修正前もStrengthが増えた。一方、World1実設備でジャンプ中にも判定内になる本体不具合を再現し、TrainingManagerのR15支持面/垂直状態確認を修正。World2既存許容値・FloorMaterialだけで拒否しない判定は維持。今回W2モデル装着でも再検証した。fixture修正と本体修正を区別する。

## 提出・保持確認

[STUDIO_VISUAL_FINAL.json](STUDIO_VISUAL_FINAL.json): 再開時526 Sourceのうち523保持、既知3変更＋新Config1本＝527。Source/Editor一致、予期しない変更/削除0。W1原本12、W2原本10、検証Instance0。副本は未保存Edit。検証用別Studioは終了し、元Studioだけを開いたままにする。Save/Publish・正本・PR #1・force pushは操作していない。無関係なcrashes/をGitへ含めない。

検証再現: `python tests/build_body_dumbbell_diagnostics.py --visuals --variant serialized_mesh --training-fixed --regression --clients 2`。必要な最新Source/geometryは作業PCのtmpへ保持し、Source39本の隔離検査成功時だけPlay。空checkoutには巨大/非公開の作業スナップショットを含めないため、別PCでは副本から再取得が必要。W2形状の読み取りexportはtests/ExportWorld2DumbbellGeometry.luau。pending/は前段の準備履歴で、現在の正本Sourceはsrc/。

今回の8番共通設定1か所の追加変更と、最新の副本確認は[UI08_AND_MATERIALS.md](UI08_AND_MATERIALS.md) / [UI08_STUDIO_FINAL.json](UI08_STUDIO_FINAL.json)。
