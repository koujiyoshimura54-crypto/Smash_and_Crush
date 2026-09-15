# AGENTS.md — Smash_and_Crush 開発ルール

対象プロジェクト：C:\Users\kouji\Smash_and_Crush  
Roblox Game：Train to Smash Everything / Studio表示 +1 スマッシュ&クラッシュ

## 作業前の必読

1. 作業開始前に必ず全文を確認する：  
   [GAME_SPEC](docs/GAME_SPEC.md)、[BALANCE_SPEC](docs/BALANCE_SPEC.md)、[UI_SPEC](docs/UI_SPEC.md)、[DEV_STATUS](docs/DEV_STATUS.md)。
2. 最新ユーザー指示とSPECが矛盾する場合は最新指示を優先し、関連SPECの更新が必要なことを報告する。過去の指示・古いコメントだけで最新の許可範囲を狭めない。
3. 不明な仕様を推測で大規模変更しない。現行Studio、最新reports、明確に確定した設計、旧コメントの順で根拠を調べ、「仕様不一致・要確認」を記録する。
4. 正常に動いている機能を変更する前に、関連Script・Config・Object・呼び出し元と影響先を監査する。

## 実装と検証

5. 大きな変更は **Audit → Implementation → Play Test → Regression Test** を基本とする。文書整理・読み取り専用の依頼ではImplementationを文書作成に限定し、Studio変更やPlayを勝手に行わない。
6. 1 Phaseの変更範囲を広げすぎない。直接依頼されていない問題は別の課題として記録する。
7. 固定World座標よりModel / Stage / Floor / Spawn等の相対座標を優先する。旧Stage寸法属性・Pivotを信頼する前に、実Floor/Zoneと照合する。
8. World1とWorld2のConfigを混同しない。現在World1後半はWorld1LateStageConfig / Stage1WallManager.GetStageConfigが有効値。旧World1BossConfig / Wall.ConfigはWorld2が参照するため、間接的な変更に注意する。
9. Balance変更時はBALANCE_SPECを確認し、Level/Strength・装備補正・Carryを含む実効値を確認する。実測回数に合わせて承認済みHPを勝手に再設定しない。
10. UI変更時はUI_SPECを確認する。HUDLayout/ResponsivePanelsと端末別の実際の配置を調べる。Tablet左メニュー倍率をUI全体の倍率と取り違えない。
11. 完了時、確定した仕様変更があれば該当SPECとDEV_STATUSの更新候補を報告する。文書更新も許可範囲なら反映し、CHANGELOGへ確認できる日付・Phase・証拠だけを追記する。
12. 実装変更のPlayではRuntime Error / Warning / Infinite Yieldを確認し、回帰範囲と未検証範囲を報告する。過去のPlay・今回の静的監査・今回のPlayを区別する。Consoleが空のEdit監査をPlay合格と呼ばない。
13. ユーザーが明示していない大規模リファクタを行わない。
14. World2作業時はWorld1を変更しないことを基本とする。共通Moduleや旧HP基準への依存を事前監査し、指示範囲を超える変更を連鎖させない。

## 正本と証拠の扱い

- 初期SPECの優先順位は現在Studio → 最新reports/CSV → 明確な確定設計 → 古い仕様・コメント。今後のユーザー最新指示はSPECに優先する。
- 「現在実装済み」「暫定」「未実装」「将来予定」「要確認」を分ける。存在するConfigやUIボタンだけで機能完成を宣言しない。
- Studioの接続Placeを確認する。今回の初期監査対象PlaceIdは101572058398926。複数Studioや異なるPlaceでは誤編集を防ぐ。
- reports/Implementation_Audit_20260915/sourcesは監査時点の保存物で、自動同期ソースではない。報告のbefore/after/evidenceを後から書き換えない。新しい変更は新しい報告へ記録する。
- 既存レポート整理では内容と関連リンクを維持する。検証用Playerデータ、個人情報、秘密情報を新規公開物へ流用しない。
- Publish、Git Commit、削除・破壊的移行はユーザーの許可範囲を確認する。既に明確に許可された通常作業について細かな確認を繰り返さない。
- Git未導入・未初期化を理由に勝手にインストール、git init、Commit、Remote作成をしない。
- 今回の文書初期化でStudio実装は変更していない。次回作業では必要な監査を行い、SPEC v1.0を出発点として扱う。

