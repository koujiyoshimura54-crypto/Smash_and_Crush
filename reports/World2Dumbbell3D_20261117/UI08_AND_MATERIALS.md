# 8番UI反映・素材の集約（2026-11-17）

今回のユーザー指示で、指定PNGの同一フォルダーへの移動と、World1/World2素材の集約・重複削除を実施した。前のフォルダー許可待ちは解消した。新たなローカルStudio/アプリを開かない指示を受けた後は、追加起動・Play・画像/フォルダーのウィンドウ表示を行っていない。

## 画像の登録と副本への反映

- PNG: `UI/World2/紫水晶の双頭クリスタルメイス.png`
- SHA256: `99ba41843cef191afc9c2d19369b3fd5c5904598e3d0a6283b14a5e55182ddb1`
- RGBA 1536×1024。完全透明945,471画素、完全不透明602,306画素。ファイルの色・縦横比・アルファは変更なし。
- Image ID: **112266643972428**。Owner User 7467238848、Active / Approved。[登録結果](UI08_UPLOAD.json)。モデルや3Dテクスチャからの代用なし。
- 変更Full Path: **ReplicatedStorage.Config.World2GameplayConfig.DumbbellImages[8]**（src/ReplicatedStorage/Config/World2GameplayConfig.luau）。旧101543601215487から新IDへ、1か所のみ変更。
- 共通DumbbellItemMasterを新Sourceで評価。変更フィールドはW2_NORMAL_08.Image / ImageAssetIdだけ。World1の08、他ItemId、価格/Strength/合成/保存/進捗は変更なし。
- 既存表示参照: InventoryPanelClientの詳細/装備プレビュー、DumbbellInventoryView.CreateCardの一覧、MergeShopView.updateCandidatesの生成候補/完成結果。いずれも共通Master.Image。画像ID直書きを表示箇所へ追加していない。
- 反映時期: 次のPlay/serverでModuleScriptを新規requireしたとき。既に起動中のクライアントのModuleキャッシュを強制更新しない。

## 確認済みと未確認

静的・Edit内の確認: Config差分はDumbbellImages.8だけ、Master差分は上記2フィールドだけ。副本の対象Source/Editor一致、全Source数527、W1登録12/W2登録10、今回の検証Instance0・helper globalなし。[最終確認](UI08_STUDIO_FINAL.json)。接続IDが変わった後も実PlaceId 126576845524886 / Universe10765181857と反映済みSourceを再確認した。再接続により全Sourceの一時baselineは失われたため、未取得の全527 Source比較を実施済みとは記載しない。

既存副本Editで画面へ追加しない一時ImageLabelを使いContentProviderを確認。callback/AssetFetchStatusはSuccess。一方、非表示・非親付けのImageLabel.IsLoadedはfalseであり、実UIが描画された根拠にはしない。[取得記録](UI08_FETCH.json)。その前の文字列だけでのPreloadはFailureだったため、最初から全経路で成功とは扱わない。

実UI Playは**未確認**。新規起動を止める指示の前に、26 Source許可リスト・構文・禁止API検査を通した別PlaceId=0を1回起動したが、ExecuteMultiplayerTestAsyncの戻り値に結果がなく、UI assertion/画面確認は成立していない。Success:trueという呼出し成功だけを合格としない。その後は追加起動を止めた。保存・購入・外部送信の実装はfixtureへ含めていない。画像の実インベントリ/候補/完成結果の見え方、スマホ/タブレット表示、新画像の確認スクリーンショットは未確認。既存レイアウト/Fit/透明背景指定は静的に保持。

準備したtests/ExportWorld2DumbbellUI.luau、World2DumbbellUI.client.luau、build_world2_dumbbell_ui.pyは未完了の検証補助。製品Sourceに組み込まない。再現には作業PCのtmp/World2Dumbbell3D/UIExportFinal.jsonを使用する。runnerはPlay前隔離失敗時に停止し、結果がない終了も成功扱いしない。新たなローカル起動はユーザーの制約に従う。

## 素材の集約・重複削除

集約先: **C:\Users\kouji\Downloads\World2Dumbbells_20261117**。フォルダー名は既存のアップロード許可を維持するためそのまま。内部はWorld1 / World2 / UI / Referenceに整理し、README.mdを置いた。

189ファイルを移動し、移動前後SHA256が全件一致。23 ZIPの全エントリーを展開済みFBX/テクスチャとハッシュ照合後、重複ZIP23個と重複PNG1個を削除。削減 **100,079,760 bytes（約100 MB）**。削除前に保持先・削除対象のハッシュを再検査。最終素材群にバイト一致する重複ファイルなし。無関係なZIP・ゲームソース・販促画像・プロジェクトは対象外。

現在位置:

| 内容 | 集約先からの相対パス |
|---|---|
| W1 FBX/テクスチャ | World1/originals/NORMAL_xx |
| W1 GLB | World1/exports |
| W2 FBX/テクスチャ | World2/originals/<UUID> |
| W2 GLB | World2/exports |
| W1/W2 UI画像 | UI/World1、UI/World2 |
| 番号未割当参考画像・管理表 | UI/References、Reference |

[移動/削除の全パスとハッシュ](MATERIAL_ORGANIZATION.json)。元ZIP名は[ASSETS.json](ASSETS.json)の由来情報として保持し、現在のFBX/GLB/PNGパスを追加。古い報告の取得時パスは歴史記録であり、現在の場所は本書。作業素材や巨大中間物をGitへ追加しない。

## 残り

World2の05/09はモデル対応の確認待ちで未登録。既存モデルの新規推測割当はしていない。前段で完了した10種類の設備/両手とBody/Treadmill検証は[REPORT.md](REPORT.md)参照。

副本はEdit接続を維持し、Save/Publish・正本・PR #1・force pushは操作しない。今回はConfig1か所と素材整理の記録・検証準備だけを通常commit/push対象とする。
