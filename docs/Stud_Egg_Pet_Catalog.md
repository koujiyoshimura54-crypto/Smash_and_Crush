# Stud Egg & Pet 実物一覧 — Phase 1

[Pet画像一覧の閲覧ページ（20体×9ページ）](Stud_Pet_Photo_Catalog.html)。2026-10-08撮影試行: 個体と画像の対応を確実に確認できず、取得済み0件／未取得180件。画像付き一覧は未完成です。番号・モデル名・座標と各未取得理由を掲載し、曖昧な画像や生成画像は採用していません。Cameraは開始時へ復元しました。

[Egg全192件の対応表](Stud_Egg_Catalog.csv) · [Pet全180件の対応表](Stud_Pet_Catalog.csv)

2026-10-08、既存StudioのEditを読み取り。PlaceId: 126576845524886。対象: Workspace.Stud Egg & Pet。モデル名順でEgg-001〜192／Pet-001〜180を採番。番号は本一覧の識別子で、能力・レアリティ順ではありません。

Egg: 192モデル・191名（Egg_001が2件）。Pet: 180モデル・180名。Full Pathだけでは重複を区別できないため、モデルPivotのワールド座標とGetChildren取得時の同階層順番を記載。順番はセッション依存なので、座標・名前・親の子構造を併せて確認してください。

## Studioでの見つけ方

Workspace.Stud Egg & Pet.Modには同名Modelが2つあります。EggModelsフォルダを持つModelがEgg側、Petsフォルダを持つModelがPet側です。Pathの最初の名前一致だけで選ばないでください。

重複Egg_001:
- Egg-001: (-113.987137, 111.719208, 1786.684082)、同階層順番80。
- Egg-002: (120.413147, 111.719193, 2267.039551)、同階層順番186。

## 画像の取得状況

個別画像は全件未取得です。利用可能なStudio撮影は現在画面、またはCameraを一時移動する方式です。配置・Cameraを変えない条件で全372件を個別撮影する方法は今回確立できませんでした。自作・生成画像や別モデルの画像で代用していません。画像付き一覧は未完成で、CSVの画像欄を未取得と明示しています。全件対応表は完成しています。

## 記入欄・次のPhase

Eggの排出Pet、およびPetの系統・レアリティ・排出Egg・能力・マージ先はすべて空欄です。勝手な分類・数値設定はしていません。

確定事項: Petもマージ対象です。これは今後の設計方針であり、現在のゲームにマージが実装済みという意味ではありません。

Phase 2以降の未決定事項: 使用モデル選定、EggとPetの対応、系統・レアリティ、価格・排出確率・能力、マージ組合せ／必要数／消費／結果、重複Petの保存方式と既存還元仕様の扱い、装備枠・Strengthへの適用、画像の取得方法。今回は決定・実装しません。

## 保存済みファイルとの区別

CurrentCloud.rbxlにも同じ対象フォルダと件数が保存済みです。既存Studioから取得した位置・順番が本一覧の正本です。Studioとdiskの全プロパティ・未保存差分の一致を意味しません。前回記録の小さな階層差を上書きで解消していません。

読み取りのみ。Studio新規起動・終了、Camera変更、実物編集、Play、Save／Publish、rbxl書き戻し・Backup・Map複製は実施していません。

## Rig／Animation限定調査（2026-10-08）

既存StudioのEditで180種を読み取り。CSV末尾に個数と接続検査列を追加しました。Boneの親がBone／BasePartか、Motor6D両端が同じPet内の部品か、AnimatorがHumanoid／AnimationController直下かを検査。HumanoidRootPartの存在だけではRigと判定していません。Motor componentsは有効Motor6Dを辺とする無向グラフの連結成分数です。骨格とメッシュのskin weight、関節階層とクリップの完全互換性は未検証です。

- Boneあり115種（合計3226）、Motor6Dあり179種（合計2281）。全180種に少なくとも一方あり。Boneの不正親0、Motor両端有効2280／不正1。
- HumanoidはPet_180に1個。AnimationControllerは180個（Pet_130に2個、Pet_180に0個）。Animatorは176個、全176個の親種別は有効。
- Animatorなし: Pet_058、Pet_089、Pet_103、Pet_114。
- Pet_137.Model.Root.MotorJoint_002はPart0=同Pet内Root、Part1=nil。未接続として記録、修正なし。
- Pet_130はSpike／Puffの2つのRig構造、Motorグラフ2成分。Pet_079はMotorなし・Boneあり。外側HumanoidRootPartからのMotor到達数だけでは、内側Modelの骨格を否定できません。

### Animation 12個の対応表

Full Pathは下表の通り。格納先と同居Rigは確認済みですが、外部AnimationIdのクリップ内容・用途・対応骨格は未確認です。名前から勝利／待機／歩行等の用途を断定していません。Egg内のクリップをPetへ対応付ける根拠はありません。

| 名前 | Full Path | AnimationId | 格納先・対応Pet | 同じ格納モデルのRig（Bone／Motor／Animator） | 用途・実再生・利用権限 |
|---|---|---|---|---|---|
| DarkWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_152.DarkWinAnimation` | rbxassetid://100747355580894 | Egg内。対応Pet未確認 | 51／9／1 | 未確認 |
| LightWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_152.LightWinAnimation` | rbxassetid://77370551573285 | Egg内。対応Pet未確認 | 51／9／1 | 未確認 |
| DarkWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_153.DarkWinAnimation` | rbxassetid://108687111191446 | Egg内。対応Pet未確認 | 24／8／1 | 未確認 |
| LightWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_153.LightWinAnimation` | rbxassetid://75175132819461 | Egg内。対応Pet未確認 | 24／8／1 | 未確認 |
| DarkWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_154.DarkWinAnimation` | rbxassetid://135909692722395 | Egg内。対応Pet未確認 | 20／6／1 | 未確認 |
| LightWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_154.LightWinAnimation` | rbxassetid://126596643439445 | Egg内。対応Pet未確認 | 20／6／1 | 未確認 |
| DarkWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_155.DarkWinAnimation` | rbxassetid://98012025044588 | Egg内。対応Pet未確認 | 26／6／1 | 未確認 |
| LightWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_155.LightWinAnimation` | rbxassetid://74287011605505 | Egg内。対応Pet未確認 | 26／6／1 | 未確認 |
| DarkWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_156.DarkWinAnimation` | rbxassetid://77712811996924 | Egg内。対応Pet未確認 | 25／6／1 | 未確認 |
| LightWinAnimation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_156.LightWinAnimation` | rbxassetid://122731312101610 | Egg内。対応Pet未確認 | 25／6／1 | 未確認 |
| Animation | `Workspace.Stud Egg & Pet.Mod.Model.EggModels.Egg_179.Animation` | rbxassetid://119165623278067 | Egg内。対応Pet未確認 | 0／2／1 | 未確認 |
| Animation | `Workspace.Stud Egg & Pet.Mod.Model.Pets.Pet_180.Animation` | rbxassetid://83127051434605 | Pet_180内。クリップ適合未確認 | 0／2／1 | 未確認 |

### ローカルKeyframeSequence等

7個のKeyframeSequence（Keyframe合計432）が対象内にあります。格納Pet内のPose名とBone／BasePart名はすべて名前対応しました。ただし名前一致は完全な階層互換・再生確認ではありません。全7個Loop=true、Priority=Action。AnimationId12個との紐付けは未確認です。

| Full Path | 格納Pet | Keyframe数 | Poseのユニーク名一致 | 用途 |
|---|---|---|---|---|
| `Workspace.Stud Egg & Pet.Mod.Model.Pets.Pet_046.Model.AnimSaves.centipede_idle` | Pet_046 | 61 | 78／78 | 未確認（名称は原文のまま） |
| `Workspace.Stud Egg & Pet.Mod.Model.Pets.Pet_046.Model.AnimSaves.centipede_walk` | Pet_046 | 25 | 78／78 | 未確認（名称は原文のまま） |
| `Workspace.Stud Egg & Pet.Mod.Model.Pets.Pet_048.Model.AnimSaves.organic_croc_idle` | Pet_048 | 48 | 27／27 | 未確認（名称は原文のまま） |
| `Workspace.Stud Egg & Pet.Mod.Model.Pets.Pet_048.Model.AnimSaves.organic_croc_walk` | Pet_048 | 48 | 27／27 | 未確認（名称は原文のまま） |
| `Workspace.Stud Egg & Pet.Mod.Model.Pets.Pet_082.Model.AnimSaves.idle` | Pet_082 | 81 | 27／27 | 未確認（名称は原文のまま） |
| `Workspace.Stud Egg & Pet.Mod.Model.Pets.Pet_082.Model.AnimSaves.idle_1` | Pet_082 | 96 | 27／27 | 未確認（名称は原文のまま） |
| `Workspace.Stud Egg & Pet.Mod.Model.Pets.Pet_082.Model.AnimSaves.walking` | Pet_082 | 73 | 27／27 | 未確認（名称は原文のまま） |

AnimationRigDataも7個付属。Rig編集情報としての存在のみ確認し、実行時Animationや公開クリップとの対応は断定しません。

Keyframeの時刻・Pose.CFrameの変化も読み取りました。Pet_046の2本は0〜1秒／0〜2.5秒、変化するPose名は各76。Pet_048の2本は各0〜1.958333秒、各25。Pet_082のidle_1／walking／idleは0〜1.583333／1.2／1.333333秒、各25／26／20です。静止データだけではなく時系列の関節姿勢データがありますが、「歩行・待機として正しく見える」ことは未確認です。

AnimationRigDataの格納先は上表の各KeyframeSequence直下です。子名はPet_046でCentipede_WalkAnimationRigData／Centipede_IdleAnimationRigData、Pet_048で各Organic_CrocodileAnimationRigData、Pet_082で各frognumber1AnimationRigData。上表のFull Pathにこの子名を加えた場所が実物です。

### PetFollowClientの流用範囲・不足

根拠: `StarterPlayer.StarterPlayerScripts.Services.PetFollowClient`全文。`dress`は全BasePartをAnchored=trueにし、`resize`はPrimaryPart姿勢とScaleを調整。`update`は追従位置・旋回・上下動・pitchを計算し、`model:PivotTo(...)`でモデル全体を動かします。`Animator:LoadAnimation`、AnimationTrackのPlay／Stop、Bone.Transform／Motor6D.Transform操作はありません。したがって現在の追従処理自体はRig Animation再生に対応していません。

流用時の不足は、承認済みクリップとRigの対応表、適切なAnimator選択（複数Rigを含む）、Animator欠落／Motor未接続の扱い、待機・移動の切替／再生停止と破棄処理、全パーツ固定・姿勢変更と関節アニメーションの整合確認です。実再生と利用権限は別途確認が必要です。今回は追加・修正・再生をしていません。
