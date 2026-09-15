# Smash_and_Crush

**Roblox Game:** Train to Smash Everything  
**接続Studio:** +1 スマッシュ&クラッシュ / PlaceId 101572058398926  
**Project Root:** C:\Users\kouji\Smash_and_Crush

World1 Stage1〜10の進行、後半Balance、大型Boss Collider、HP UIを実装済み。World2はGate表示・解放データ・Map Grayboxまでで、移動・Combat・Stage進行は未実装。World2専用Balance（Lv60〜200 / Boss15M〜25B）とWorld2専用Inventory方針は設計確定・Studio未反映。英語名と公開タイトルの統一は未確認。

## 正本SPEC

- [GAME_SPEC](docs/GAME_SPEC.md)：ゲーム全体、実装済みと未実装の境界
- [BALANCE_SPEC](docs/BALANCE_SPEC.md)：数値・計算式・Carry・暫定World2値
- [UI_SPEC](docs/UI_SPEC.md)：HUD、端末対応、戦闘HP、Gate表示
- [DEV_STATUS](docs/DEV_STATUS.md)：進捗・次タスク・要確認事項
- [CHANGELOG](docs/CHANGELOG.md)：確認できる変更履歴
- 開発ルールは **[AGENTS.md](AGENTS.md)** を参照

現在の未確定事項はBossへのCarryと初期Stageの推奨Lv差。World2永続解放はStage10 RewardPad取得で確定。World2再開時は新BalanceのConfig反映、World2専用Inventory/Item、Enemy Asset、移動・Combat・Stage進行を限定Phaseで進める。

2026-09-15追記：World1後半はWall .4撃破後にBossが近すぎる問題をEnemySpawn後退で調整済み。戦闘・床内収まり・UI追従を確認。Wall .4手前の低視点からBoss全体を見せることは要件ではない。Carryは変更していない。

## レポート

- [World1 Stage6〜10 build_report](reports/World1_Stage6_10_20260915/build_report.md)
- [World1 Stage6〜10 final_balance.csv](reports/World1_Stage6_10_20260915/final_balance.csv)
- [2026-09-15 実装監査概要](reports/Implementation_Audit_20260915/audit_summary.md)
- [World1後半の間隔・視認性レポート](reports/World1_Stage6_10_Spacing_20260915/build_report.md)

reports内のsourcesは特定時点の監査証拠。Studioへ自動同期する開発用ソースではなく、これだけで完全なPlaceを復元できる構成でもない。現行実装と矛盾した場合はSPECへ差を記録し、勝手に統一しない。

## バージョン管理の準備

2026-09-15確認：このフォルダーと祖先に.gitはなく、既存Repositoryではない。gitコマンドはPATH上で利用できず、一般的なインストール先にも見つからなかった。PC上の全領域で未導入を証明したわけではない。インストール・git init・Commit・Remote作成は今回行っていない。

[.gitignore.example](.gitignore.example)は**未適用の候補**。採用時に管理対象を決めて.gitignoreへ反映する。

| データ | 推奨 |
|---|---|
| AGENTS / README / docs | Git管理する。仕様変更と検証根拠を追えるようにする |
| reportsの確定md/csv/json/luau・小さな検証記録 | Git管理する。未加工の個人データや秘密情報がないか確認してからCommit |
| 開発用Luau / Config / Rojo設定 | 今後正式な同期構成を導入した場合に管理。監査sourcesとは区別 |
| Studio保存物 | 明示的に保存先と方式を決定。差分向きの.rbxlx/.rbxmx、または.rbxl/.rbxm＋Git LFSを検討 |
| PNG等の必要なAsset | 小規模ならGit、大容量ならLFSを検討。ローカルパスだけではRobloxのAsset実体を保存したことにならない |
| AutoSave / Recovery / temp / cache / logs | 原則除外。確定試験結果はreportsへ保存して管理 |
| 個人的なbackup / Studio生成バックアップ | 原則除外。バックアップの唯一のコピーをGit除外だけで済ませない |
| 認証情報・.env・DataStore生ダンプ | Gitへ含めない |

.rbxl/.rbxlxやreports全体を一括除外する候補にはしていない。今回Studioから新しいPlaceファイルの保存・Exportは行っていない。

最終更新：2026-09-15 / SPEC v1.0
