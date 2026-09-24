# Backup validation

- Studio export versus local src: 482 checked, zero Source mismatches before Git staging.
- All 63 original source paths retained; no source-only path deletion.
- Staged credential pattern scan: zero candidates (GitHub/OpenAI/AWS key patterns, private keys, Roblox session-cookie warning).
- No staged file over 10 MB. No full Place, Model binary, bundle, credential file, AutoSave, Recovery or Cache artifact staged.
- Existing external-source trailing whitespace/EOF warnings from git diff --check were preserved, not reformatted; they are not runtime QA results.
- Local repository-all.bundle verifies successfully and records complete reachable history.
- No reflog commit outside fetched remote reachability before backup commits; stash empty.
- Cloud localization equality, complete Place save, restoration test and runtime gameplay tests remain unverified/not performed.
- Public export includes game and bundled third-party Luau source, not third-party model binaries. Preserve script metadata and licenses; do not activate archived scripts when restoring.
- Final remote SHA verification is performed after commit/push and reported in the completion response.
