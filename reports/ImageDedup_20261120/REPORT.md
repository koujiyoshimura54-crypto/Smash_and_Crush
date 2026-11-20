# 確認画像の重複削除とGitHub画像のローカル共有

2026-11-20。直前の調査で「確認画像候補」に分類したファイルを対象に実施。

## 結果

- SHA256が本体の保持画像と完全一致する重複コピー **1,248枚を削除**。削除前に両方を再照合し、本体の **440種類は保持**。
- 削除量 **345,688,859 bytes（約345.7MB）**。
- GitHub mainだけにあった **16枚・8,372,491 bytes** を、同じ相対パスでローカルへ取り込み。既存ファイルの上書きなし。
- 画像ファイル容量の差引削減は **337,316,368 bytes（約337.3MB）**。Gitオブジェクト・ファイルシステムの割当容量を含むディスク全体の削減量ではない。
- mainの画像 **668枚すべてがローカルにも存在し、Git blobと一致**。main内に完全一致する画像重複は **0枚** のため、GitHubから削除する画像はなかった。

## 削除した作業コピー

`C:\Users\kouji\` を基準とした保存場所：

| 保存場所 | 削除枚数 |
|---|---:|
| Smash_and_Crush/tmp/EventBoardAppearance_20261119/delivery | 420 |
| Smash_and_Crush/tmp/FloorRoute20261116/git | 384 |
| Smash_and_Crush_starter_character_audit_20261114 | 369 |
| Roblox_SavedArchives/Smash_and_Crush_backup_20260925-0915 | 15 |
| Roblox_SavedArchives/Smash_and_Crush_boss_round_work | 15 |
| Roblox_SavedArchives/Smash_and_Crush_phase23_git_save | 15 |
| Roblox_SavedArchives/Smash_and_Crush_Y02_back_ui | 15 |
| Smash_and_Crush/Smash_and_Crush_updated_20260915 | 15 |

削除したファイル・保持先・SHA256・容量：[deleted_duplicates.csv](deleted_duplicates.csv)。名前だけが同じ、あるいは見た目が似ているという理由では削除していない。

古い作業コピーの報告書 **89文書・1,358リンク** を、本体に残した画像への相対リンクへ変更。本文・画像説明・他のリンクはそのまま。関連する1,110文書の明示的なMarkdown／HTML／CSS画像リンクを検査し、今回削除した画像への残存リンクは0件。

旧作業コピーがGit worktreeの場合、画像削除と参照変更はそのローカル差分として残る。旧ブランチへのcommit／push、worktree削除、checkout、reset、stashはしていない。今後旧ブランチを復元すれば重複画像が戻る可能性がある。

## ローカルに取り込んだ画像

- `reports/OfflineRewardMenuUI_20261119/images/`：7枚。
- `reports/RewardedStrengthBoost_20261120/images/`：9枚（参考画像2枚を含む）。

取得元は `origin/main` の `b6e2679777c1d639e225b98a301dbc79159652f7`。各ファイルのGit blob・SHA256・容量：[imported_images.json](imported_images.json)。ローカルの古いmainを巻き戻したり最新へ一括置換したりせず、欠けていた画像だけを取得した。

## 保持と確認

既存の編集中ファイル78件を作業前後のSHA256で照合。参考画像・素材カタログ・テクスチャ・別案件など、前回調査で保留したローカル画像951枚も一致を確認して保持。これらは今回の確認画像重複削除の対象外。

[document_links.json](document_links.json) に参照変更した文書と変更前後ハッシュ、[verification.json](verification.json) に検証結果を記録。調査範囲は前回一覧に含まれるゲーム関連フォルダー。個人写真・一般Downloads・アプリキャッシュの全画像を整理したものではない。

Studio・ゲームSource・RBXL／FBX／Blend・画像アセットには変更を加えていない。Gitの過去履歴は保持し、force pushは行わない。今回のmainへのcommit対象はこの整理記録だけ。既存のmain HEADと通常indexは保持し、最新origin/mainを親とする別indexで通常pushする。
