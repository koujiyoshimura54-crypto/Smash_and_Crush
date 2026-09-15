# 実装監査・SPEC初期化記録

監査日：2026-09-15（Asia/Tokyo）  
対象：+1 スマッシュ&クラッシュ / PlaceId 101572058398926  
Studio接続ID：052ceee8-7f96-4c5e-9882-a7f288d28d8b  
Project Root：C:\Users\kouji\Smash_and_Crush

## 結果

現在のStudio実装を基準に、[GAME_SPEC](../../docs/GAME_SPEC.md)、[BALANCE_SPEC](../../docs/BALANCE_SPEC.md)、[UI_SPEC](../../docs/UI_SPEC.md)、[DEV_STATUS](../../docs/DEV_STATUS.md)の初期正本を作成した。README・AGENTS・CHANGELOGと未適用の.gitignore.exampleも用意した。

今回の変更はローカル文書の作成と既存レポートの整理のみ。StudioのScript/Config/Map/UI/World1/World2を編集せず、Play開始・DataStore操作・Publish・Place保存/Export・Git初期化/Commitを行っていない。

## 監査方法

- 接続先がEdit状態の対象Placeであることを確認。
- ReplicatedStorage.Config / Modules、ServerScriptService、StarterGui、StarterPlayer.StarterPlayerScriptsにある関連Source123本を読み取り、[sources](sources)へ保存。
- ModuleScriptのSource・呼出元・Config参照・Object属性を追跡。数値表は読み取った式から静的に導出し、既存の最終Play報告と照合した。
- World1/World2のFloor・Stage・Wall、Boss Template/CollisionReference、Treadmill、RewardPad、Gate、主要UIを合計520レコード取得。
- 既存レポートを読んでPlay結果と今回の静的確認を区別。新しくPlayerをSpawnしたり保存データを取得していない。

[Source manifest](source_manifest.json)は123ファイルの保存先・SHA-256。[current_balance.csv](current_balance.csv)は現在の有効設定を静的導出したStage1〜10/W2の数表。[scene_objects.json](scene_objects.json)は選択Objectの監査記録。

保存Sourceは監査時点の証拠で、自動同期する開発用ソースではない。全383 Scriptのうち関連123本を保存しており、全Instance・Mesh・Texture等を含む完全なPlaceバックアップではない。Sourceの存在だけで全機能のPlay成功を保証しない。

## 前後照合

[comparison.json](comparison.json)に照合結果を保存。

| 比較 | 結果 |
|---|---|
| 全LuaSourceContainer | 383本、追加/削除/ソース指紋差分0 |
| 保護対象Scope | 24範囲、Instance数・属性/主要物理プロパティ等の指紋差分0 |
| 選択Object記録 | 520件、前後差分0 |
| 主要Sourceの取得時確認 | 123本、取得時の比較で不一致なし |
| 終了時Studio | Edit |
| 終了時Console | 空 |

指紋は既存監査コードの32bit DJB2方式であり、暗号学的な完全証明ではない。Scopeには旧監査の「後半Wall MaxGaugeを除くMap」もあるが、別途520件のObject比較ではそのWall属性も含めて一致した。すべての未取得プロパティ・外部Asset・DataStore状態を比較したという意味ではない。

[前指紋](fingerprint_before.json) / [後指紋](fingerprint_after.json)。

## Runtime結果の区別

今回のConsoleはEdit状態で空。**今回は新しいPlayを行っていないので、Runtime Error / Warning / Infinite Yieldの再検証結果は「未実施」**。

既存[2026-09-15後半レポート](../World1_Stage6_10_20260915/build_report.md)には最終Playの0 / 0 / 0と、少なくとも61秒経過までConsoleが空だった記録がある。後半Balance・Collider・UIの実測はこの記録を引用した。全サービス・多人数・Mobile/Tabletの今回合格に拡張して解釈しない。

## レポート整理と保存保証

元のプロジェクト直下にあった次の6項目を、reports/World1_Stage6_10_20260915へまとめて移動した。

- build_report.md
- final_balance.csv
- fingerprint.luau
- before/
- after/
- evidence/

計37ファイルのSHA-256が移動前後で一致。[report_relocation_sha256.json](report_relocation_sha256.json)に元の相対パスとハッシュを保存した。関連フォルダーを一緒に移したため内部参照を維持。既存ファイルへの上書きを避け、旧報告本文は編集していない。

C:\Users\kouji\World1_Stage6_10_20260915にあるプロジェクト外の旧コピーは変更していない。今回の正本となる報告の場所は次のとおり。

- C:\Users\kouji\Smash_and_Crush\reports\World1_Stage6_10_20260915\build_report.md
- C:\Users\kouji\Smash_and_Crush\reports\World1_Stage6_10_20260915\final_balance.csv

## 主な仕様不一致・要確認

詳細と優先度は[DEV_STATUS Known Issues](../../docs/DEV_STATUS.md#known-issues)に集約。

- Stage1〜3の推奨Lvと必要Strengthの実Lvが一致しない。後半Stage6〜10は一致。
- Wall4の余剰がBossへCarryし、適正Strengthでは90%開始になるケース。継続方針未確定。
- Stage10 Boss撃破のWorldCompleteと、Pad取得のHighestUnlockedWorld更新は別イベント。
- World2 HPは再バランス前World1基準×25,000。RequiredStrength/Asset未確定、移動/Combat/進行未接続。
- Map寸法属性と実Floor、Treadmillの旧tick属性/Type名と現行Configに差がある。
- Dumbbell Mergeable定義に対する操作未実装、Reward ItemのRarity判定は受取時CurrentStage。
- Game PassのStudio効果ゲート、未設定商品、未検証多人数Gate/端末UIを区別して記録した。

## Git準備

Projectおよび祖先の.gitは見つからず、現在Repositoryではない。gitはPATHで見つからず、C:\Program Files\Git\cmd\git.exeとユーザー側一般インストール先にもない。PC内の全配置を検索したわけではないため「絶対に未導入」と断定しない。インストール・初期化・Commitは行っていない。

[READMEの管理方針](../../README.md#バージョン管理の準備)と[.gitignore.example](../../.gitignore.example)を提案。候補は未適用で、docs/reports/Place保存物を一括除外しない。

## ローカル検証

[validate_documentation.ps1](validate_documentation.ps1)はこの監査の文書・リンク・CSV・移動済み証拠の照合用スクリプト。Studioへ接続したり実装を変更する処理は含まない。結果は[validation.json](validation.json)へ保存する。

最終照合：8文書・120ローカルリンクでリンク切れ0、文字化けの置換文字0、必要な進捗セクションの欠落0。10行のBalance CSVを確認し、後半指定値に不一致なし。移動した37ファイルのSHA-256不一致0。検証スクリプトはプロセス限定のExecutionPolicy設定で実行し、Windowsの恒久設定は変更していない。
