# Studio専用Body試作

副本PlaceId 126576845524886専用。自動起動・全プレイヤーへの導入はしない。
結果と制約は [報告書](../../reports/BodyPrototype_20261114/REPORT.md) を参照。

## 保存内容

- BodyPrototype.luau：実際にPlayした組み立てModule。元BodyのCloneを絶対倍率で縮小し、本人のHead Instanceと頭部アクセサリーを保持。成長基準取得より前に呼ぶ。同一Characterへの再呼出しはno-op。
- PrepareAssets.luau：初回の資材準備を再実行用にまとめたEditコマンド。既存の試作があれば停止する。最初にServerStorage.BodyPrototype_20261114へBodyPrototypeをModuleScriptとして取り込む。元モデルと本人のアバターを複製し、衣服をLoadAssetする。読込だけで服の適合を判断しない。
- RebuildPreviews.luau：今回の名前・属性を持つプレビューだけ再作成。本人の頭の元寸法を共通にした30％・40％、Pastel、肌色の静止展示。
- InstallIsolation.luau：既存tests/FirstBattleTutorialのメモリ隔離を今回用の識別名へ変更したもの。39 Sourceを挿入時の内容ごとバックアップ。
- InstallRuntimeHook.luau：隔離設置後のEdit限定。本人UserId 7467238848だけへ一時適用し、SpawnEngineReadyより前で組み立てる。通常経路へ残してはいけない。
- RuntimeProbe.server.luau：Play中だけServerScriptServiceに挿入。実行中ScriptのrequireキャッシュでData/Trainingへアクセスする。BindableFunction __BodyPrototypeProbeのstate/level/reapply/equip/treadmills/skin/clothes/ratioで今回のfixtureを設定・測定。
- TreadmillTrial.server.luau：Play中のみ。Normal01へ配置し4秒間の実際のTrainingを記録して退出。Strengthを直接加算しない。
- Cleanup.luau：自分のPlay終了後Editで呼び、フックと隔離Sourceが設置時のAfterに一致することを確認してからBeforeへ戻す。使用者の途中編集があれば停止する。

## 再試験の順序

1. 正本には実行しない。副本の状態を確認し、ユーザーのPlay中なら停止しない。
2. 既存の今回試作を使用するか、空の専用Folder/Moduleを作ってPrepareAssetsを実行。通常のStarterPlayerへ移さない。
3. EditでInstallIsolation → 残るDataStore/Marketplace参照確認 → InstallRuntimeHook。
4. 自分で開始したPlayへRuntimeProbeを一時挿入する。既存セッション状態の確認には実行中Scriptを使う。Studioツール内から直接requireすると別のModule状態を得る場合があり、Data未読込や空のTreadmill registryを実ゲームの結果と誤認しない。
5. 本人Head・衣服・基準寸法を組み立て後に現行成長処理が取得したことを測定。レベル変更/装備fixtureはメモリ隔離内だけ。
6. 自分のPlayだけを終了し、Cleanupを実行。通常SourceからBodyPrototypeへの参照と__BodyPrototype系の一時補助が残らないことを確認。プレビューと非自動実行Moduleだけ保持。Save/Publishしない。

今回の実測では、帽子・顔アクセサリーや通常顔の本人装着例はない。Classic衣服は読めたがUV適合しない。コードを本番へ有効化するための完成品ではない。
