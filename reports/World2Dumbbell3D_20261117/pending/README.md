# 未適用のWorld2表示準備

アセット未登録、05/09未確定、展示/手持ち実Play未確認。自動適用用ではない。

- World2Visuals.patch: 既存W1の複製・両手接続・設備更新を両Worldで共有する準備差分。完全ItemIdで登録を解決。既存legacy手持ちのCanQuery=falseも含む。
- World2DumbbellVisualConfig.luau: 確定10件の登録準備。05/09は回答後に追加。モデルIDの仮値はない。

予定Full Path:

- ReplicatedStorage.Config.World2DumbbellVisualConfig
- ServerStorage.World2DumbbellModels.W2_NORMAL_01..12（種類ごとに原本1つ、未作成）
- ServerScriptService.Services.World1DumbbellVisuals（既存名の互換を維持）
- ServerScriptService.Systems.Controllers.World1DumbbellExhibitController
- ServerScriptService.Systems.Controllers.DumbbellDisplayController

Config.Items.W2_NORMAL_XXで調整する。DisplayLength=4.8は展示の柄方向X全長studs、DisplayOffset=Vector3.new(0,8.4,0)はPress基準の位置補正studs。実展示未調整の初期値であり最終配置ではない。DisplayRotationはlocal軸degrees。

HeldLength=2は手持ち柄方向X全長studs。GripOffsetは手のlocal位置補正studs、HeldRotationはlocal軸degrees。小Bodyの追加厚み1、大Bodyの暫定上限1.5。BodyPrototypeの全体倍率とは別にY/Zだけへ適用。毎回原本からcloneし、前回倍率へ累積しない。登録原本は柄をlocal X、握り中央をpivot原点へ合わせる。

例: 08の手首位置だけを下げるならGripOffset=Vector3.new(0,-0.1,0)。横幅を維持して厚み上限を調整するならBodyThickness.MaxMultiplier。展示サイズには影響しない。ModuleScriptの変更は新しいPlay/serverで反映。

登録後は実取得Model/Mesh/4テクスチャIDをASSETS.jsonへ記録し、Modelを正規権限で取得してgeometry/materialのみの原本を各ItemIdへ配置。設備・各Player左右の手が同じ原本を複製する。今は復元可能なW2登録IDが存在しないため、復元完了とは扱わない。

8番UIはReplicatedStorage.Config.World2GameplayConfig.DumbbellImages[8]だけを実取得画像IDへ変更し、共通Masterを参照する一覧/詳細/マージUIで確認する。PNG登録と反映は未実施。
