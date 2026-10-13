# AGENTS.md — Smash_and_Crush 開発ルール

Current game: Merge to Forge Your Strength. Cloud PlaceId: 126576845524886; UniverseId: 10765181857.
Repository: koujiyoshimura54-crypto/Smash_and_Crush (main).
Y02 repository: C:\Users\kouji\Smash_and_Crush\Smash_and_Crush_updated_20260915.
Editable local place: C:\Users\kouji\MergeToForge_CurrentCloud.rbxl. A newer explicit user path takes precedence.

## 作業前の必読

1. Read the latest relevant entry in [DEV_STATUS](docs/DEV_STATUS.md) and only the sections of [GAME_SPEC](docs/GAME_SPEC.md), [BALANCE_SPEC](docs/BALANCE_SPEC.md), and [UI_SPEC](docs/UI_SPEC.md) needed for this task. Do not reread all specifications for every small fix.
2. 最新ユーザー指示とSPECが矛盾する場合は最新指示を優先し、関連SPECの更新が必要なことを報告する。過去の指示・古いコメントだけで最新の許可範囲を狭めない。
3. 不明な仕様を推測で大規模変更しない。現行Studio、最新reports、明確に確定した設計、旧コメントの順で根拠を調べ、「仕様不一致・要確認」を記録する。
4. 正常に動いている機能を変更する前に、今回の変更へ直接関係するScript・Config・Object・呼び出し元と影響先だけを確認する。小規模な不具合でProject全体へ監査範囲を広げない。既にユーザーまたは直前Phaseで確認済みの前提は、今回の変更が触れていない限り再確認しない。

## 実装と検証

5. 大きな変更・影響範囲が不明な変更は **Audit → Implementation → Play Test → Regression Test** を基本とする。小規模な不具合修正は **原因候補を2〜3個に絞る → 正常例との差分確認 → 最小修正 → 必要最小限のPlay確認** を基本とし、AuditやRegressionを機械的にフル実施しない。文書整理・読み取り専用の依頼ではImplementationを文書作成に限定し、Studio変更やPlayを勝手に行わない。
6. 1 Phaseの変更範囲を広げすぎない。直接依頼されていない問題は別の課題として記録する。
7. 固定World座標よりModel / Stage / Floor / Spawn等の相対座標を優先する。旧Stage寸法属性・Pivotを信頼する前に、実Floor/Zoneと照合する。
8. World1とWorld2のConfigを混同しない。World1BossConfigはWorld1 Stage1〜10の唯一のBalance正本。Stage1WallManager.Config / GetStageConfigは互換窓口。World2はWorld2Config.Stagesを独立した正本とする。World1 Stage1〜5のWall固定値、特にStage2特殊倍率をConfig統合の理由で再計算しない。
9. Balance変更時はBALANCE_SPECを確認し、Level/Strength・装備補正・Carryを含む実効値を確認する。実測回数に合わせて承認済みHPを勝手に再設定しない。
10. UI変更時はUI_SPECを確認する。HUDLayout/ResponsivePanelsと端末別の実際の配置を調べる。Tablet左メニュー倍率をUI全体の倍率と取り違えない。
11. 完了時、確定した仕様変更があれば該当SPECとDEV_STATUSの更新候補を報告する。文書更新も許可範囲なら反映し、CHANGELOGへ確認できる日付・Phase・証拠だけを追記する。
12. 実装変更のPlayでは今回の変更に直接関係するRuntime Error / Warning / Infinite Yieldを確認し、必要最小限の回帰範囲と未検証範囲を報告する。毎回World1全体・全Stage・全Reward・全Save経路・全端末を再検証しない。UI変更時だけ必要に応じて端末別確認を行う。過去のPlay・今回の静的監査・今回のPlayを区別し、Consoleが空のEdit監査をPlay合格と呼ばない。
13. ユーザーが明示していない大規模リファクタを行わない。
14. World2作業時はWorld1を変更しないことを基本とする。共通Moduleや旧HP基準への依存を事前監査し、指示範囲を超える変更を連鎖させない。

## 調査範囲の制限

- 小規模な不具合では、最初に原因候補を2〜3個へ絞る。
- 正常に動く比較対象がある場合は、まず正常例との差分比較を優先する。
- ユーザーが存在・正常を前提として明示しているものを、理由なく再確認しない。
- 原因が特定できた時点で追加調査を停止し、「念のため」の全体監査を続けない。
- 直接関係しないScript・Config・Object・World・報酬・保存経路へ調査を広げない。
- Playは修正内容に直接関係する最小ケースを優先する。直前Phaseで検証済みの項目は、今回触れていない限り再検証しない。
- 調査だけの依頼では、原因特定に不要なレポート生成・大規模証跡収集・全体回帰を行わない。

## 正本と証拠の扱い

- 初期SPECの優先順位は現在Studio → 最新reports/CSV → 明確な確定設計 → 古い仕様・コメント。今後のユーザー最新指示はSPECに優先する。
- 「現在実装済み」「暫定」「未実装」「将来予定」「要確認」を分ける。存在するConfigやUIボタンだけで機能完成を宣言しない。
- For Cloud edits/Play, identify the intended connected Studio by PlaceId126576845524886. Old PlaceId101572058398926 is a legacy reference, not the editing target. A user-confirmed local CurrentCloud is authoritative for that local task; do not demand additional proof of its Cloud origin.
- reports/Implementation_Audit_20260915/sourcesは監査時点の保存物で、自動同期ソースではない。報告のbefore/after/evidenceを後から書き換えない。新しい変更は新しい報告へ記録する。
- 既存レポート整理では内容と関連リンクを維持する。検証用Playerデータ、個人情報、秘密情報を新規公開物へ流用しない。
- Publish、削除・破壊的移行はユーザーの許可範囲を確認する。既に明確に許可された通常作業について細かな確認を繰り返さない。
- For an authorized Git synchronization task, locate the existing repository first (including the Y02 nested path above). If absent, clone the specified remote into an absent/empty destination without asking again; never overwrite a nonempty directory or initialize an unrelated repository. Software installation and credential changes require separate authorization.
- 今回の文書初期化でStudio実装は変更していない。次回作業では必要な監査を行い、SPEC v1.0を出発点として扱う。

## Git運用

- Git導入済みの本Projectでは、依頼された作業が正常完了し、必要な検証と差分確認が済んだら、追加確認を求めずに今回分だけをCommitし、`origin/main`へPushする。
- Commit前に`git status`と`git diff`を確認し、今回と無関係な変更を混ぜない。他者または以前から存在する変更を勝手にCommit・破棄しない。
- 通常のCommitと`origin/main`へのPushは完了作業の一部として扱い、都度の事前確認を不要とする。
- Force Push、rebaseやreset等による履歴改変、Branch削除、今回と無関係な変更の破棄を行う場合だけ、実行前にユーザー確認を得る。


## Standing authorization and fewer interruptions — 2026-10-14

The user explicitly authorized this update to reduce repeated permission questions. Apply these rules to the requested task, not unrelated work.

- A request to implement or fix authorizes its necessary targeted reads, Source/property edits, same-file CurrentCloud writes, focused verification, English project records, and normal commit/push of that task's changes to the existing origin/main. Do not stop after diagnosis or ask "may I implement/test/commit/push?" again.
- Reading logs, current files and Git history, inspecting the connected Studio, and checking status/diffs need no conversational confirmation. Routine reversible implementation choices within the agreed scope are delegated to the agent.
- Cloud Play/Stop/Edit verification related to the requested implementation is authorized. Preserve the user's session and unrelated edits. Do not run local PlaceId0 Play. Do not reset player data, make real Robux purchases, or introduce unrelated data changes as a test without explicit authorization.
- The user saves and publishes manually. Do not perform Studio GUI Save/Publish, create unsolicited backups/alternate rbxl/work or migration folders, or manufacture replacement visuals when purchased assets cannot be accessed.
- Close only verification Studio processes started by the agent. Remove only the exact target's stale lock after confirming no process still holds it; never terminate the user's Studio or delete an active lock.
- Preserve existing tracked/untracked changes. Commit only the task's changes. Do not discard work, force-push, rewrite history, or broaden the task merely to finish.
- Accept a user's confirmation of the target file and established facts. Recheck only when new evidence materially conflicts with them. Do not impose new proof, backup, staging, or approval gates.
- Ask only when a material unresolved choice cannot be inferred, the next action exceeds authorization, or a concrete risk of serious data loss/DataStore damage cannot be resolved within scope. Continue independent authorized work while resolving the blocker.
- Conversation authorization and host/tool permissions are separate. Follow enforced sandbox, managed policy, MCP Capability and approval requirements. This file grants no bypass. If enforcement blocks an action, state the exact action and reason once; use a permitted alternative if available, otherwise request the smallest necessary user action. Do not repeatedly submit equivalent blocked attempts.
- These standing authorizations supersede older repository wording that requires repeated conversational permission for the same ordinary task. They do not override enforced platform permissions or the explicit prohibitions above.
