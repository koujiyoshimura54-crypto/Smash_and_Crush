# Y01 Studio固有差分の保全・main統合・Daily限定修正 — 2026-11-17

## 対象と結果

- PC: Y01 / Windows名 DESKTOP-CNFVEH2。
- 既存Studio接続: 06d4a97d-7b0e-46bc-b715-6ab9a9d7e23a。
- 実値: PlaceId 126576845524886 / UniverseId 10765181857 / PlaceVersion 728。開始・終了ともEdit。
- 作業worktree: C:\Users\kouji\Smash_and_Crush\AnalyticsSpawnItems。
- ブランチ: codex/analytics-spawn-items-20261115。
- 開始HEAD: 16745e12a9a7a5c7754d401b5cfef9a126cca68d。
- fetchした統合前main: 1e795c8ed3f61cc59cc43f57b39f99ea02b9414a。
- 追跡ファイルの開始時変更・独自コミットは0。既存crashes/を保持し、mainへfast-forward。
- 関連41 Sourceを再比較し、実質的差分は指定の3件。取得できたEditor内容はSourceと一致。末尾空白だけの差分は同期対象に広げていない。
- Studioの新表・Stage1表記をGitへ採用。Studioで書き換えたのはDailyの2文字列だけ。
- FPS最適化・DataStore調査修正・追加バランス変更は実施していない。

## Phase 1.1: 変更前の保全

[Source manifest](before/source_manifest.json)にFull Path、ClassName、UTC取得日時、Enabled/Disabled/RunContext等の適用可能な状態、SourceとEditorそれぞれのSHA256とバイト数を保存。

| Full Path | Sourceファイル | SHA256 |
|---|---|---|
| ReplicatedStorage.Config.LevelRequirements | [原文](before/sources/ReplicatedStorage.Config.LevelRequirements.luau) | 040c6341b982ebea724dc5b160675693a2c12de828e698edd2817a9ea683765e |
| StarterPlayer.StarterPlayerScripts.Combat.CombatClient | [原文](before/sources/StarterPlayer.StarterPlayerScripts.Combat.CombatClient.luau) | 262d055c523d504745b4b06490b98adfdd11073ec5fcb27864b4c4d2ca590df2 |
| StarterGui.StrengthGui.DailyRewardsClient | [文字化けを含む原文](before/sources/StarterGui.StrengthGui.DailyRewardsClient.luau) | 93af27ba9dd1d9c32fa570455d9a16c6f9c485c53022e7e9115c755c39864282 |

UTF-8・BOMなしで、取得文字列の改行・末尾空白・文字化けをそのまま保存。3件ともSourceとEditor内容が同一なので、同じファイルを両方の参照先にしている。ModuleScriptには適用されないEnabled/Disabledは記録していない。今回専用.gitattributesで保全物のGit改行変換を無効化した。書出し後に受信内容との一致・SHA256を確認してから統合へ進んだ。

[GUI設定](before/GUI.snapshot.json.gz)はRobloxTypedGuiSnapshot/1の型付きJSON（gzip）。163対象ルートと必要な祖先、合計2,888 Instanceを記録。展開JSONは3,570,728 bytes、圧縮94,688 bytes。[GUI manifest](before/gui_manifest.json)に両方のSHA256と取得時刻を記録した。

主な保全対象:
- Workspace.PerStepButtons.1～12.BillboardGui。
- Workspace.World2Map.TrainingArea.DumbbellDisplays.PerStepButtons.1～12.BillboardGui。
- StarterGui.StrengthGui.LeftMenu.TimeRewardsButton / DailyRewardsButton、各NotificationBadge。
- StarterGui.World1DoubleWinGui配下の2バナー。
- 両WorldのBattleCorridorに存在するTrophyRewardBillboard、CombatClientが操作する壁SurfaceGui。
- StarterGui.StrengthGui.DailyRewardsPanel配下の全日数・VIP表示。
- 対応テンプレートと、親のVisible/Enabled等を解釈するための祖先。

Text、表示、Position/Size/AnchorPoint、UIScale、色、Font/FontFace、画像ID、関連Attribute等を型付きで保存。UDim2はScale/Offset、Color3はRGB成分、FontはFamily/Weight/Style、Enumは型名/名称/値、Instance参照はFullPathとName/ClassName/同名同Class内OrdinalのAddressを持つ。単なるtostringの値にはしていない。読み取り専用のAbsolutePosition/AbsoluteSize等はDerivedとして分離。対象プロパティの取得不可は0件。

[文字列・Scale一覧](before/GUI_text_and_scale.csv)は確認用の抜粋であり、復元用の本体は型付きJSON。GUIをStudioへ再適用していない。

### 保全物の読み方・復元時の注意

GUI JSONはPythonで `json.loads(gzip.decompress(path.read_bytes()))` として読める。
値のTypeに従ってRoblox型を再構築する。例: UDim2はUDim2.new(X[1],X[2],Y[1],Y[2])、FontはFont.new(Family,Weight,Style)。Instance参照と各対象はAddressの各段でNameとClassNameが一致する子をOrdinal順に解決する。Stage1.1のような名前にドットがあるため、FullPathを単純なドット区切りで復元しない。参照が解決できなければ停止し、別Instanceで代用しない。

これは既存階層上のGUI設定保全であり、Place全体・モデル全形状のバックアップではない。復元は別途指示された際に必要箇所だけ行う。Source原文を自動で一括適用する処理は用意していない。[capture_gui.luau](capture_gui.luau)は読み取り専用の取得関数である。

## Phase 1.2: mainとの統合

最新mainの3コミットをfast-forwardで取り込み、そこにStudio固有差分だけを追加した。TrophyのK/M、右HUD、ダンベル＋表示/1.5、歩道範囲共通化、Manual Strengthパスの既存変更を保持。

| Gitの本体パス | 統合内容 |
|---|---|
| src/ReplicatedStorage/Config/LevelRequirements.luau | 保全したStudio Source全文をそのまま採用。Studio自身には再適用していない |
| src/StarterPlayer/StarterPlayerScripts/Combat/CombatClient.client.luau | 保全したStudio Sourceを採用。mainとの差はWorld1 Stage1表記の条件分岐のみ |
| src/StarterGui/StrengthGui/DailyRewardsClient.client.luau | 最新mainに正しい文字列が存在したため、その本体ファイルを維持。Phase 1.3の修正と一致 |

[LevelRequirements差分](integration/ReplicatedStorage.Config.LevelRequirements.patch)、[CombatClient差分](integration/StarterPlayer.StarterPlayerScripts.Combat.CombatClient.patch)、[開始時Source再比較](before/source_comparison.json)を保存。

Stage1は `worldId == 1 and major == 1` のとき `Stage1`、それ以外は従来の `Stage %d-%d`。最新mainのNumberFormat適用を落としていない。

### 新Strength表と比較用CSV

Q(L)は「Lv L → L+1の追加必要量」。累積Strengthではない。

**[Studio実装から生成した比較用CSV_Lv1-201.csv](Studio実装から生成した比較用CSV_Lv1-201.csv)** は今回生成した比較資料。Level、CurveVersion、StudioRequiredStrength、PreIntegrationGitHubRequiredStrength、Difference、Ratio（Studio÷統合前GitHub）の402行。元の承認CSVを発見したものではない。

| Q(L) | 保全したStudio／統合後 |
|---|---:|
| Q(50) | 200010 |
| Q(51) | 319880 |
| Q(100) | 377780000 |
| Q(130) | 67842854710 |
| Q(136) | 150359438580 |
| Q(140) | 200000000000 |
| Q(200) | 5000000000000 |
| Q(201) | 5250000000000 |

旧参照CSV `reports/Level_Curve_20260915/level_51_200_thresholds.csv` と全150行を独立照合。[検証結果](verification_old_csv.json)に旧CSVのSHA256、各行、計算式を保存した。
- smooth(t)=t*t*(3-2*t)。
- Lv51～100: 旧Q × 10^smooth((L-50)/50)。
- Lv101～140: 旧Q × 10^(1+2*smooth((L-100)/40))。
- Lv141～200: 旧Q ×1000。
- 10単位切り上げでStudio全150値と一致。

元の承認CSV、当時のテスト結果・報告書は所在未確認。Sourceコメントの「Approved CSV」は当該原本を今回回収したという意味ではない。

## 副作用を遮断した検証

[verify_progression.luau](verify_progression.luau)はSource文字列を受け取る純粋検証関数。既存StudioのEdit内でloadstring/setfenvを使い、math/table等だけを許可した環境で実行。LevelProgressionのrequireには検証用トークンだけを許可し、純粋な必要量テーブルを返す。実ModuleScriptのrequire、実Player、DataStore、購入、Analyticsへの到達経路はない。

[独立計算結果](verification_pure.json): 90,949 assertions。
- 両曲線のLv1～50: 100比較で保持。
- 両曲線のLv1～10000: Studioと統合後20,000比較で一致、必要量20,000件が有限・正。
- Lv201～10000: 両曲線19,600件で新Q(200)起点の＋5％・10単位切り上げに一致。
- Lv1～200の直前・一致・超過: 両曲線1,200条件。
- 保存済みLevel/Strength/小数進捗保持、複数LVUP、ApplyGain、最大Levelでの進捗保持。
- Lv136からQ(136)+Q(137)+17: Lv138・残り17、入力Strength 123456.5を変更しない。
- 旧保存形式のCalculateLevel比較等30,008件で統合前と一致。
- 不正Level/進捗/バージョン/負数/NaN/無限大の拒否等15条件。

PlayerDataServiceとLevelProgressionは変更していない。PlayerDataService全体を検証環境で実行していないので、実保存・再参加の検証済みとは扱わない。高LVでは既存の倍精度数値の精度制約が残り、厳密な整数演算へ変更していない。

[verify_artifacts.py](verify_artifacts.py)はオフラインで保全ハッシュ、旧CSVとの関係、統合内容、未変更の2 Module等を検証し、比較CSVを再生成する。実行例:
`python reports/Y01StudioPreservation_20261117/verify_artifacts.py`。
[結果](verification_artifacts.json)も保存した。

## Phase 1.3: Daily文字化けの限定修正

変更したStudio Full Pathは **StarterGui.StrengthGui.DailyRewardsClientだけ**。
- `VIP 窶｢ Daily bonus` → `VIP • Daily bonus`
- ` 窶｢ READY` → ` • READY`

[Daily限定差分](integration/Daily_mojibake_only.patch)と[確認結果](verification_daily.json)を分離して保存。報酬・条件・購入・翻訳方針・レイアウトは変更していない。最新mainの正しい2文字列と文脈を照合した。main側は既に正しいため、同じ内容を重ねて書き換えたり、空白だけの本体差分を追加したりしていない。

UpdateSourceAsyncが末尾の既存CRLFをLFへ正規化したため、再読込でその1バイト差を特定し、元の改行を復元した。最終Sourceは「変更前原文へ上記2文字列置換だけを行った文字列」と完全一致。エディター内容も一致し、構文コンパイルが成功。変更前の文字化けはバックアップ内に意図的に残る。

現在のEdit GUIのVIP見出しは保全時点で既に `VIP • Daily bonus`。GUIは変更せず、次回の通常クライアント実行でrenderが使用するSource文字列を直した。READYを実操作で表示させるPlayは実施していない。

## Phase 1.4: 最終整合とGit保存対象

- [Studio確認](verification_studio.json): 新Strength表とCombatClientは変更前の保全Sourceと完全一致。Dailyだけ意図した置換。3件ともEditor一致・構文正常・Enabled等の状態保持。Edit / Running=false。
- [GUI前後比較](verification_gui.json): 2,888 InstanceのFullPath/ClassName/Address/設定/Attribute等に差分0。Derived値の差分も0。
- [保全対象外の確認](verification_preservation.json): 別worktree14件のHEAD/status/既存変更ファイル、既存stash、crashes/10ファイルが開始時と一致。
- Studioへ検証用Instanceを追加していない。取得・検証コードは今回の報告用資料としてGitに保持し、Studioへ常設していない。
- Save/Publish、Play/Stop、新しいStudio/Place/クライアントの起動、Studio終了なし。既存未保存編集を維持したまま開いている。
- 通常push先はorigin/main。保存対象は今回の本体2ファイル、関連記録、専用報告・保全・検証成果物。GitHub側の既存3コミットはfast-forwardで保持。commit SHAとpush後の照合結果は完了返信に記載する。

## 未確認

元の承認CSVと当時の検証資料の所在。実Play、実Playerのロード/保存/再参加、実機、公開環境、Daily受取や購入、FPS・DataStore警告の原因は今回未確認。独立計算・静的確認を実Play合格と扱わない。
