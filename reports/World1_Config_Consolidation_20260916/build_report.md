# World1 Balance Config統合 — 2026-09-16

対象: +1 スマッシュ&クラッシュ / PlaceId 101572058398926。
World1BossConfigをWorld1 Stage1〜10の唯一のBalance正本へ統合した。実RuntimeのBalanceは変更していない。

## 統合前の役割と監査

- World1BossConfig: Stage1〜5の現行RequiredStrength・RecommendedLevel、共通Lottery APIを保持。Stage6〜10には未使用の旧RequiredStrength 20,000 / 70,000 / 200,000 / 600,000 / 2,000,000が残っていた。
- World1LateStageConfig: BossConfigをcloneし、Stage6〜10の現行RequiredStrengthを上書き。GetRequiredStrength / GetRecommendedLevel / GetMaxHPを再定義し、GetWallConfigを後半Stage用に提供。
- Stage1WallManager.Config: Stage1〜5の現行Wall HPと後半の旧Wall HPを保持。実Runtimeの後半WallはGetStageConfigがLateStageConfigから取得していた。
- Studio全395 LuaSourceContainerとローカルProject全体を、World1LateStageConfig / World1BossConfig / GetRequiredStrength / GetRecommendedLevel / GetWallConfig / GetMaxHPで検索。Studioでは13 Scriptが該当。LevelRequirements関連の同名APIとServerStorage.Tests内の過去テストも区別した。
- ローカル検索は445対象ファイル、100該当ファイル、291該当行（362一致）。既存のローカル固有コピーも読取検索に含め、変更・再利用はしていない。履歴資料の一致はRuntime依存として扱わない。

[Studio統合前参照](references_before.json) / [Project検索](references_local_before.txt)

## 現行値の確定

初回依頼のStage3〜5 300 / 1,500 / 3,500は実Runtimeと異なっていた。PlayサーバーのBossCombatServiceで450 / 2,000 / 5,000を確認し、ユーザーが後者の維持を明示承認した。古いSPECを訂正したもので、今回の実装でこれらの数値を変更したのではない。

| Stage | RecommendedLevel | RequiredStrength | Wall .1 | Wall .2 | Wall .3 | Wall .4 | Boss MaxHP |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 8 | 50 | 100 | 125 | 150 | 200 | 250 |
| 2 | 10 | 100 | 300 | 325 | 350 | 425 | 500 |
| 3 | 15 | 450 | 600 | 750 | 900 | 1,200 | 2,250 |
| 4 | 20 | 2,000 | 3,000 | 3,750 | 4,500 | 6,000 | 10,000 |
| 5 | 25 | 5,000 | 7,000 | 8,750 | 10,500 | 14,000 | 25,000 |
| 6 | 30 | 37,315 | 74,630 | 93,287.5 | 111,945 | 149,260 | 186,575 |
| 7 | 35 | 81,865 | 163,730 | 204,662.5 | 245,595 | 327,460 | 409,325 |
| 8 | 40 | 196,915 | 393,830 | 492,287.5 | 590,745 | 787,660 | 984,575 |
| 9 | 45 | 462,965 | 925,930 | 1,157,412.5 | 1,388,895 | 1,851,860 | 2,314,825 |
| 10 | 50 | 1,018,015 | 2,036,030 | 2,545,037.5 | 3,054,045 | 4,072,060 | 5,090,075 |

全Boss HPはRequiredStrength×5。Stage6〜10 Wallは×2 / ×2.5 / ×3 / ×4。
Stage1〜5は独立した既存Wall固定値を保持。特にStage2の300 / 325 / 350 / 425を維持し、Stage3〜5のWallも現在RequiredStrengthから再生成しない。

[統合前Runtime](before_runtime.json) / [最終CSV](final_balance.csv)

## 移行・削除

| Runtime経路 | 統合前 | 統合後 |
|---|---|---|
| ServerScriptService.World.Stage1WallManager | BossConfigからBoss HP、LateStageConfigから後半Wall、内部の旧Wall表 | BossConfig.GetWallConfigから全10 Stageを取得。ConfigとGetStageConfigを互換窓口として維持 |
| ServerScriptService.World.BossCombatService | LateStageConfigをWaitForChildしてrequire | World1BossConfigへ参照名だけを変更 |
| ServerScriptService.Systems.Debug.StudioDebugService | GetBalanceSnapshot内でLateStageConfigをrequire | World1BossConfigへ参照名だけを変更 |

World1BossConfigの既存GetRequiredStrength / GetRecommendedLevel / GetMaxHP / GetLotteryWinChanceを維持し、GetWallConfigを全Stage用に統合した。Stage1WallManagerの進行・ダメージ適用・Snapshotロジックは同一。

旧Configは参照移行後のPlay検証が合格してから削除した。削除直前に全Script内の旧Config名への参照ゼロを確認し、削除後も同じPlay検証を再実施した。Backup、既存reportsのSnapshot、ServerStorage.Testsの過去テストは削除・書換えしていない。

[削除結果](deletion.json) / [統合後参照](references_after.json)

## World2と変更範囲

World2Config.Stagesが独立した正本で、World2BossConfig / World2WallConfigはそれだけを参照している。World1 ConfigへのRuntime依存は残っていなかったため、World2コードの参照移行は不要だった。

World2の3 Configはソース完全一致。Playで全10 StageのRequiredStrength / RecommendedLevel / Wall HP / Boss HPおよび参照APIが統合前と一致。

Studioのソース指紋（長さ・Adler32・DJB2）を全395→394 Scriptで比較し、変更4本・削除1本・追加0本を確認。変更4本の実Sourceと今回のsources書き出しも完全一致。BossCombatServiceとStudioDebugServiceはrequire先の名前変更のみ。EnemyManager、StageManager、Lottery計算、World2、Client UI、DataStore、育成・課金コードは変更なし。

[範囲比較](scope_comparison.json) / [統合前指紋](fingerprints_before.json) / [統合後指紋](fingerprints_after.json)

## 今回のPlay検証

統合前・参照移行後（削除前）・旧Config削除後に同一の520チェックを実施。統合前後の結果JSONをキー順序だけ正規化して比較し、全体が完全一致した。統合後は追加でAPI互換性92チェックも合格。

- World1全10 StageのRequiredStrength、RecommendedLevel、4枚のWall HP、Boss HP、Wall SnapshotのBoss HP。
- World2全10 Stageの同じ数値とBoss/Wall参照API。
- 全StageのWallダメージ、複数WallへのCarry、Bossへの余剰Queue、Boss開始HP、通常攻撃回数、離脱/再開時の同一Encounter・HP保持。
- Lotteryの16境界値、全Stageの通常ルート、0%不当選の5回敗北、当選の5回勝利。抽選を改変せず当選を観測（各Stage最大64試行）。
- Stage1→10のClear、次Stage、Stage10 WorldComplete、Skip、順序違い拒否、負ダメージの無視。
- 実Playerを読み取るDebug Snapshotで、新しい正本のRequiredStrength/Boss HPを取得できた。
- 検証Scriptを除去後、通常PlayでServer/Clientの参加・Stage1・PlayerGui・旧Config不在を確認。38秒時点で正常起動を記録し、その後Consoleを再確認して停止。

サービス検証はPlayサーバー上の実Moduleを使用し、Player部分だけを独立した属性オブジェクトへ置換した。接続Playerの育成値・Stage・保存データへ試験値を設定していない。全StageのCharacter歩行・物理接触を通した手動操作、複数Player同時試験、本番公開は今回の確認範囲に含まない。

最終通常PlayのConsole: **Runtime Error 0 / Warning 0 / Infinite Yield 0**（観測期間内）。
初期の直接require/Script再配置はAssistant実行権限で拒否されたため、正式なScript編集ツールで一時検証Scriptを作成して実施した。Player Instance作成も権限で拒否されたため、上記の代替オブジェクトを使用した。削除前参照チェックがコメント内の旧名を検出した際は削除せず、コメント修正後に再監査した。これらの監査・試験準備時エラーを最終ゲームRuntimeの合格結果と混同しない。

[統合前Play](before_play.json) / [削除後Play](after_play.json) / [通常Play](normal_play.json)
[検証Script（統合前）](verification/play_probe_before.luau) / [検証Script（統合後）](verification/play_probe_after.luau)

## SPEC・Git作業環境

GAME_SPEC、BALANCE_SPEC、DEV_STATUS、CHANGELOGとAGENTSの旧正本記述を更新した。CHANGELOGは今回の記録を追加し、既存履歴は変更していない。過去reportsにも変更なし。現在SPEC中の旧Threshold比較等、明示された履歴表は履歴として維持した。

C:\Users\kouji\Smash_and_Crushを引き続き作業Repositoryとして使用。元の差分11件は.git/local-pre-main-backupへ原本コピーし、SHA256一致を確認した。ローカル固有260件は同じ場所に残し、.git/info/excludeの2パスで今回のCommit対象外とした。新しいclone先や別の作業Repositoryは作成していない。

作業開始時main=origin/main=dc4c5102dee3e09fbfb1c22c71340628154783d2。今回の変更と新規検証記録だけをCommit / Push対象とする。Commit message: `Consolidate World1 balance config`。

このRepositoryは既存運用に従ってdocsとStudioのソースSnapshotを管理する。sourcesは今回のStudio実装と一致する記録であり、自動同期するRojo構成ではない。Publishは行っていない。
