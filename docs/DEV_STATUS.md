# DEV_STATUS — 開発状況

Version: 1.3 / 監査・更新日: 2026-09-15

正本：[GAME_SPEC](GAME_SPEC.md) / [BALANCE_SPEC](BALANCE_SPEC.md) / [UI_SPEC](UI_SPEC.md)。実装済みとPlay検証済みは別に記録する。初期版は読み取り専用監査で作成し、その後の許可された変更は日付と証拠を添えて追記する。Publish・Git初期化/Commitは未実施。

## Completed

- 2026-09-15：Levelを累積Threshold方式から保存Level/LevelProgress方式へ変更。Requirement全数値・暫定式・戦闘バランスを維持。旧データは従来Levelを維持してProgress=0へ移行。共通付与、Carry、複数Level Up、Save中の獲得、Reward再試行、実PlayerのHUD/歩行/Training/Rebirth/専用Store再Joinを検証。[報告](../reports/Level_Progress_20260915/build_report.md)。
- 過去の「推奨Levelと累積Thresholdの一致」は旧方式の履歴。今後はLevelと累積戦闘Strengthが独立した状態であり、育成時間・獲得量の再バランスは別Phase。

- 2026-09-15：Lv51〜200の全150 Thresholdを明示テーブル化。Lv1〜50を保持し、World2全10アンカーとの不一致K16を解消。Lv201以降は暫定+250M/Level、上限10,000。全境界70,335チェックとHUD150チェックが合格。[Levelカーブ報告](../reports/Level_Curve_20260915/build_report.md)。

- 2026-09-15：World2独自Balanceを3 Configへ反映。10 Stageの推奨Lv/RequiredStrength/Wall/BossをPlayで459項目検証し、25BのクライアントAttribute受信と表示も確認。旧World2HPScaleとWorld1への依存を除去。World2 Combat・移動・Inventoryは未接続/未実装のまま。[検証報告](../reports/World2_Balance_20260915/build_report.md)。

| 項目 | 確認できる現在状態 | 検証根拠・限界 |
|---|---|---|
| World1 Stage1〜10 | 個人Wall/Boss進行、Stage Clear、Stage10 WorldCompleteの接続あり | 今回は静的監査、後半は既存Play記録あり |
| World1 Map拡張 | Floor幅90、Stage6〜10を含む拡張配置 | 実Object確認。古い寸法属性が残る |
| Stage6〜10 Boss差し替え | 現在の5体とDisplayHeight36/48/44/56/52 | Model/Templateとソース確認 |
| Stage6〜10後半バランス再設定 | Lv30/35/40/45/50、RequiredStrength9000/25000/60000/130000/250000 | 現行値・最新CSV一致、Levelカーブ一致 |
| 大型Boss Collider | Stage7〜10再調整、Stage6維持、後半専用CombatZone | 既存Playで4方向×5Stage接触・開始・離脱を確認 |
| Boss HP UI改善 | 長いBoss名、個人Boss HP、Wall/Boss排他表示 | 現行ソースと既存Play UI観測 |
| RewardPad黄色Pad化 | 黄色Neon Pad、本人所有、踏み込み取得 | Template/Service/Client接続確認 |
| World2Gate作成 | WORLD 2、LOCKED/ENTER、Player別ローカル切替 | 表示のみ。配置属性は暫定 |
| HighestUnlockedWorld | 初期1、Stage10 Pad取得で2、永続化経路 | 保存コード監査。今回DataStore操作なし |
| World2 Map Graybox | World2Map、10 Stage、AuthoringOnly | 実Object確認。移動/戦闘の完了ではない |
| 既存育成・装備・報酬・課金経路 | Training、Rebirth、Inventory/Merge、Daily/Time、Shop/Receipt | ソース接続を確認。今回全機能の再Playなし |
| SPEC初期版・レポート整理 | 正本4文書、開発ルール、入口、履歴を作成 | 今回の成果。既存37ファイルの内容を保持 |

既存の後半Play結果：適正Strength・GloveなしでWall1〜4は各Stage12攻撃、Bossは5攻撃。CarryによりBoss開始90%のケースを確認。最終通常PlayのError/Warning/Infinite Yieldは記録上0/0/0。今回の新しいRuntime試験結果ではない。

根拠：[World1後半報告](../reports/World1_Stage6_10_20260915/build_report.md)、[最終CSV](../reports/World1_Stage6_10_20260915/final_balance.csv)、[今回監査概要](../reports/Implementation_Audit_20260915/audit_summary.md)。

## In Progress

- 2026-09-15：World1 Stage6〜10の間隔調整を実施。EnemySpawnを+Zへ4 / 3.5 / 3.25 / 6 / 1stud移動し、実Scaleを維持。接近・戦闘・UI・PadのPlay確認は完了。
- World1 Stage6〜10のWall .4撃破後のBoss間隔調整は完了。低視点からWall越しにBoss全体を見せることは要件ではない。詳細は[間隔レポート](../reports/World1_Stage6_10_Spacing_20260915/build_report.md)。
- SPEC v1.0の初期整備は完了。未確定仕様は下記Known Issuesに分離済み。
- World2はGraybox・表示・保存権限の基盤まで。移動・Combat・Stage進行は未実装。World2専用Balance（推奨Lv60〜200、Boss15M〜25B）はConfig反映済み。World2推奨LevelとThresholdの一致は検証済み（K16解決）。World2専用Inventory方針は設計確定・未実装。

## Next

以下は推奨順序であり、新機能実装の着手承認ではない。

1. **World1の未確定境界を決める**：K03 BossへのCarry維持、K02 Stage1〜3の推奨Lv差と暫定Win値の扱い。World2永続解放はStage10 RewardPad取得で確定。
2. 異なるHighestUnlockedWorldを持つ複数PlayerのGate表示試験。World1共有Boss/Colliderへの相互影響も範囲を決めて確認する。
3. Mobile/Tabletの表示・タッチ操作を実機/Emulatorで検証。無条件のUI拡大はしない。
4. World2 Config反映は完了。次回は暫定Levelカーブの育成時間、専用Inventory/Item設計とEnemy Assetを整理したうえで、指示された限定Phaseで移動→Combat→Stage進行を接続する。今回は次機能へ進まない。
5. Git利用方法とStudio保存形式を決定し、明示指示後にRepositoryと初回Commitを準備する。今回は未実施。

## Known Issues

「仕様不一致・要確認」は、確認できた差や未確定状態を意味する。未確認のものをRuntimeバグと断定しない。

| ID | 分類 / 優先 | 実装で確認した事実・差 | 確認すべき判断 |
|---|---|---|---|
| K01 | 名称 / Low | ユーザー英語名Train to Smash Everything、Studio表示+1 スマッシュ&クラッシュ、Project Smash_and_Crush | 公開タイトル・英語表記をどこまで統一するか。公開ページ未照合 |
| K02 | Balance / High | Stage1/2/3は推奨Lv8/10/15に対しRequiredStrength50/100/300が実Lv3/5/10。推奨Lv閾値は180/280/525。早期World1とWin表にTemporaryコメント | 意図した緩和か、旧コメントだけか。Stage1〜5・Rewardを自動変更しない |
| K03 | Carry / High | Wall余剰が次WallだけでなくBossへ渡る。後半適正StrengthではBossが90%開始 | Wall4→Boss Carryを維持するか。現行挙動を仕様化するか変更するか未決 |
| K04 | World解放 / Resolved | Stage10 Boss撃破でWorldComplete、Stage10 **Pad取得**でHighestUnlockedWorld=2 | 永続World2解放はPad取得で確定。現行仕様を維持 |
| K05 | Map/機器属性 / Medium | StageWidth20（一部30）・StageLength28（一部36）等に対し実Floor幅90・可変長。古いPivotも残る。Treadmill TickInterval1に対し実行時0.5 | 今後の座標・数値参照元をFloor/Spawn・現行Configへ限定。今回属性修正なし |
| K06 | 命名 / Low | Treadmill Type Rebirth7はRequiredRebirth5 / Tier5 | 名前だけ旧式か。表示はConfigからRebirth5を生成している |
| K07 | Merge / Medium | Dumbbell定義Mergeable=true、実際のItemMergeServiceは通常Itemのみ | Dumbbell Mergeを将来作るか、メタデータを整理するか |
| K08 | Reward確率 / Medium | Daily/Time/CommunityのItemRollは受取時CurrentStageでRarity制限。最高Stageではない | Lobbyへ戻ってStage1で受け取った場合の制限を維持するか |
| K09 | World2 / Config反映済み・機能未接続 | 独自Balanceを3 Configへ反映し旧×25,000方式を除去。Inventory設計は到達時解放・World1 Item性能維持のまま | World2 Item/Enemy、移動、Combat、Stage進行は別途指示後に実装 |
| K10 | 商品設定 / Medium | PremiumTreadmillPassId0、WinProducts空、未使用Win商品IDあり。FallbackPriceは実売価格保証ではない | 商品のID・付与量・販売意図を確認するまで有効化しない |
| K11 | テスト設定 / Medium | Studio GamePassEffectsEnabled=false、ForceSpeedPremiumUnowned=false | 所有確認と効果テストを分離。本番/Studioの試験条件を明記する |
| K11-P | Production製作者Game Pass試験 / Implemented | ProductionCreatorGamePassEffectsEnabled=false、対象UserId=7467238848 | 指定製作者だけ効果OFF。一般Player・所有表示・Developer Productは変更なし |
| K12 | 多人数検証 / High | GateはLocalPlayer別表示だが同時接続試験なし。Bossモデル/Colliderは共有要素あり | LOCKED/ENTER併存、同時Boss戦・撃破再生成への相互影響を検証 |
| K13 | Mobile / Tablet / Medium | Tablet左メニュー倍率3.0＋領域補正、端末別の最終倍率は可変 | 縦横/ノッチ/操作ボタン/長いBoss名を再検証。今後調整の可能性 |
| K14 | バージョン管理 / Medium | Project/祖先に.gitなし。gitコマンド・一般的インストール先を確認できず | Git利用準備と完全なStudio保存物の管理方針を決定。ソース監査だけで復元可能とはしない |

| ID | 分類 / 優先 | 今回確認した差 | 判断 |
|---|---|---|---|
| K16 | Levelカーブ / Resolved | Lv51〜200の明示Threshold導入によりWorld2全10アンカー完全一致。Lv1〜50維持 | 中間補間値・Lv201以降+250Mは暫定。育成時間とItemの確認後に再調整 |
| K17 | HP表示精度 / Medium | 指定例15M/500M/1B/2.5B/25Bは正常。1.25Bは1.2B、5.25Bは5.2Bに丸められる。旧方式では現在/次閾値が同じ短縮表示になる問題もあった。新HUDはProgress/現在Requirement。小数1桁の丸め自体は維持 | World2 UI接続前に表示桁数を確認。今回Formatter変更なし |
| K18 | 旧メタデータ / Low | World2 Placeholder 10体のRequiredStrengthStatus=Pending、およびWorld1側の旧World2依存コメントが残る。現在値の正本はWorld2Config.Stages | 今回Boss Model/World1変更禁止のため維持。Pending属性を現行Balance判定に使わない |

K02/K05/K06/K07は現在実装と推奨値・旧コメント・属性の差として記録した。どちらかに勝手に統一していない。

**K15 — Closed**：Wall .4撃破後にBossが近すぎる問題はEnemySpawn後退で調整完了。Wall .4手前の低視点からBoss全体を視認することは要件ではない。

## Deferred

- 暫定Levelカーブの育成時間・Lv201以降の本バランス調整。Level Threshold実装とWorld2 Balance Config反映は完了。
- World2専用Item/Inventory実装、Enemy Asset選定、移動、Combat、Stage進行。
- World2Gateの本配置と移動連携。現在は暫定BackWall preview。
- Premium Treadmill商品設定、BUY WIN付与量と商品設定。
- 多人数試験、端末別UI調整、育成所要時間の計測。
- Git初期化・Commit・Remote作成、Rojo等の同期導入、完全Placeの保存形式決定。
- Blenderキャラクター制作は別作業。今回のゲーム監査から完成NPCとして計上しない。

## Do Not Change Without Confirmation

- 最新ユーザー指示で範囲が明示されていない大規模仕様変更、リファクタ、デザイン変更。
- World1 Stage6〜10の確定Balance、DisplayHeight、Boss名、Carry方針。
- World1 Stage1〜5のHP/RequiredStrength/RecommendedLevel/Collider/Reward。
- World2の旧HP基準を共通World1Config経由で間接変更すること。
- Level/Strength式、Rebirth、Win、Item Drop、Stage Skip価格、課金付与、DataStore Schema。
- WorldCompleteとHighestUnlockedWorldの発火条件、セーブ互換性。
- UIデザインの全面変更・Tablet倍率の無条件全体適用。
- 未指定のPublish、Git Commit、元レポートや証拠の破棄。

上記は追加の毎回確認を要求するものではない。ユーザーが当該範囲を明示的に許可した場合はその指示に従い、必要な監査・実装・検証を進める。初期SPEC作成時は文書整理だけが許可されていた。以後の作業はその時点の最新ユーザー指示を優先する。

## 検証状態と更新方法

初期監査：Edit状態のSource123本、全LuaSourceContainerの指紋、対象Object/Config/Map/UIを読み取った。この工程ではPlayしていない。

2026-09-15間隔調整：Stage6〜10の歩行接近・戦闘・UIをPlay確認。検証コード除去後の通常PlayでError/Warning/Infinite Yieldは0/0/0。視認性の未達を含む検証範囲は間隔・視認性レポートを参照。

今後Completedへ移す際は、変更したScript/Config/Object、SPEC差分、Play/Regression結果、未検証範囲、日付を残す。変更候補と承認済み仕様を分け、CHANGELOGへ確認できる変更だけを追記する。

## LevelProgress移行後の注意

- Lv1 Requirement=0は数値維持のため、最初の正の獲得でLv2へ進む。Join/Rebirth時点はLv1・Progress0を維持。
- 上限10,000ではLevelは増えず、StrengthとProgressを保持する。
- /setstrengthは管理用の累積戦闘力変更のみ。Level/Progressは逆算しない。旧テストのThreshold前提は履歴として残し、今回の新規検証と区別する。
- Production Store名・既存保存項目は維持。新規3項目は欠損時移行し、不正/未知Versionは読込を拒否して上書きしない。旧仕様の稼働サーバーとの同時運用・本番課金は今回未検証。
- Item/Training/Potion/VIP倍率やWorld推奨Level調整には進んでいない。
## 2026-09-15 — World2 Gate travel

- 実装済み: World2Gate侵入検知、Player別確認UI、Server側解放・距離再検証、World2LobbySpawnへの同一Character移動、`CurrentWorld=2`。
- 確認済み: 未解放時非表示、NO後の退出待ち、再侵入表示、YES移動、Strength/Level/LevelProgress/Win/Rebirth維持。
- 未実装: World2 Combat、World2 Stage進行、World2 Reward、World1 Return Gate。
## 2026-09-15 — World1 / World2往復

- 実装済み: World2 Lobbyの`World1ReturnGate`、共通Modal、Server検証、正式World1 Spawnへの同一Character帰還、`CurrentWorld=1`。
- Play確認済み: World1→2→1→2、NO後の退出待ち、状態値維持。World2 Combat・Stage・Inventoryは未接続。
## 2026-09-16 — World1 progression rebalance

- Lv1〜50のRequirementを確定カーブへ更新。Lv51以降とWorld2は未変更。
- World1 Stage6〜10の実Combat正本`World1LateStageConfig`をRequiredStrength 37,025 / 81,525 / 196,525 / 462,525 / 1,017,525へ更新し、既存倍率でWall/Boss HPを再生成。
- Stage1〜5の前半Play Balance、Strength獲得量、戦闘ロジック、Map、課金、DataStoreは変更なし。
## 2026-09-16 — Lv1〜50 requirement floor adjustment

- Lv1〜50のRequirementを一律+10。Lv1→Lv2=10 Strength。
- Stage6〜10の実Combat RequiredStrengthを37,315 / 81,865 / 196,915 / 462,965 / 1,018,015へ同期。Stage1〜5、Lv51以降、World2は未変更。
