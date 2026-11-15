# World2 Item画像06〜10（2026-11-15、アップロード権限の反映待ち）

副本PlaceId126576845524886 / UniverseId10765181857。画像所有者はゲームと同じUser7467238848。Save/Publish・正本・PR #1は操作しない。

画像原本はユーザー指定のDownloads/World2_Items_06-10_AllElements/World2_Items_06-10にある45PNGをそのまま使用する。ユーザーの最新指示により、新規フォルダー、画像原本の複製、GitHubへの約60MBの画像追加は行わない。必要な対応表・登録結果・検証報告をこの1ファイルへまとめる。

## 確認済み

- CODEX_PROMPT.txtを読み、45件のSHA256/サイズがmanifestと一致。重複・欠番なし。合計59,561,527 bytes。すべて1254×1254 RGBA透過PNG。
- 原本の一覧を目視し、3属性、各06〜10、Groveの左右ペアを確認。検査用一覧画像は破棄済み。
- 06 Common / 07 Uncommon / 08 Rare / 09 Epic / 10 Legendary。Grove→Glove、Belt→TrainingBelt。ゲーム内rarityやItemIdを新設しない。
- asset:read / asset:writeは読み取りGETで許可済みを確認。Upload foldersはユーザーが登録・許可済みと明言したため、再確認しない。
- 現在の関連7 Source/editorはGit基準241efd5と一致。World2は現状World1画像を共有するため、ItemMasterのWorld2 cloneのImageだけを変更する予定。World1の空スロット/カテゴリ画像は維持。
- アップロード先は公式Assets API。1ファイルにつき1POST、operation/結果をこの表へ逐次記録し、不明な結果を無条件に再POSTしない。登録・審査・実読込を区別する。

## 登録記録

| 原本相対パス | 既存ItemId | SHA256 | operation | assetId | UI画像URI | 状態 |
| --- | --- | --- | --- | --- | --- | --- |
| Fire/Fire_Protein06.png | W2_PROTEIN_COMMON_FIRE | f9ead7ecc3e0ff792ecf767137bc7903d970cf9034c5572aff59d1f8d51e5b9d | — | — | — | blocked_upload_folder |
| Fire/Fire_Protein07.png | W2_PROTEIN_UNCOMMON_FIRE | 2b5bf50025a7b9f8629d72266f24f17270f21fe1c8fb2d0dcea9b9084f481941 | — | — | — | not_uploaded |
| Fire/Fire_Protein08.png | W2_PROTEIN_RARE_FIRE | d92ee59aadbbda1f7edb9560075735f1b9e460ee23f12c43fecfd311c9522da3 | — | — | — | not_uploaded |
| Fire/Fire_Protein09.png | W2_PROTEIN_EPIC_FIRE | 909d74723f11e6249d899c01daba6bbd1fcf774e2ec4da5570a7620095ce1a44 | — | — | — | not_uploaded |
| Fire/Fire_Protein10.png | W2_PROTEIN_LEGENDARY_FIRE | eb161c332d30f35940970ed83d8e2d4d4599fc050e974e5aeb206c9c268d3744 | — | — | — | not_uploaded |
| Fire/Fire_Grove06.png | W2_GLOVE_COMMON_FIRE | 1daa0fe278462bc37a766fc0b27d6f87e8f6de62164c2c9c11f461da51690007 | — | — | — | not_uploaded |
| Fire/Fire_Grove07.png | W2_GLOVE_UNCOMMON_FIRE | 5be291771a84684b5245258d722b86dcab11b62bb42a416ac750440e6812c749 | — | — | — | not_uploaded |
| Fire/Fire_Grove08.png | W2_GLOVE_RARE_FIRE | 2b2f6d36b732d477dd09f85797e1c0cf1cea917015769fd97bcca1db3626ec07 | — | — | — | not_uploaded |
| Fire/Fire_Grove09.png | W2_GLOVE_EPIC_FIRE | ba793e6ea2ed7d35c73fa4511fb83c3ece28ab07b5a7576774e4022587cc1baa | — | — | — | not_uploaded |
| Fire/Fire_Grove10.png | W2_GLOVE_LEGENDARY_FIRE | f1f01ca632898cd3d6294502cd56cd7b9f960c36f0df95ec11fe46b1973b5ef5 | — | — | — | not_uploaded |
| Fire/Fire_Belt06.png | W2_TRAININGBELT_COMMON_FIRE | ca0b7e54d3170ea1dc29df4e679a33e0eb0d95eafcdc9d1082ec65608ccf835e | — | — | — | not_uploaded |
| Fire/Fire_Belt07.png | W2_TRAININGBELT_UNCOMMON_FIRE | 1a322fe675ab11f988ddd1e20e33bcd72cf47360ebc3a77aa745989ed7fbf261 | — | — | — | not_uploaded |
| Fire/Fire_Belt08.png | W2_TRAININGBELT_RARE_FIRE | 32a624ab69c9f97f2dd83827a310ae68458850688c6524777596d469dbafd12f | — | — | — | not_uploaded |
| Fire/Fire_Belt09.png | W2_TRAININGBELT_EPIC_FIRE | df077bc8da9de13d213975e5e9c9e498b609261bd970a69353149afb8399edf9 | — | — | — | not_uploaded |
| Fire/Fire_Belt10.png | W2_TRAININGBELT_LEGENDARY_FIRE | 525e9ef0a3603ad52336338fd1ecf4c7174030d4bb7c7a1abedbf9b3c2a5991a | — | — | — | not_uploaded |
| Electric/Electric_Protein06.png | W2_PROTEIN_COMMON_ELECTRIC | fc17dc15d1673b017eec32106ac2179f9c1df19df3932c7b07621a03d6353c15 | — | — | — | not_uploaded |
| Electric/Electric_Protein07.png | W2_PROTEIN_UNCOMMON_ELECTRIC | 471d587359a670d02e2e1df690702510304b22555a119dd79dff8387239f434f | — | — | — | not_uploaded |
| Electric/Electric_Protein08.png | W2_PROTEIN_RARE_ELECTRIC | d58cbd97da19c87f2add92bbc4aff9f64e3aaf5bc8858fa47b47e5995752bf0d | — | — | — | not_uploaded |
| Electric/Electric_Protein09.png | W2_PROTEIN_EPIC_ELECTRIC | 178bd94c17a94f2ec64e087f448c041e2e6c78594b9e3dc4e9e29151bb244211 | — | — | — | not_uploaded |
| Electric/Electric_Protein10.png | W2_PROTEIN_LEGENDARY_ELECTRIC | 5bca4fa280cf69c85beee5787949f0df67910fa2dca6ccd17508a15bd9154959 | — | — | — | not_uploaded |
| Electric/Electric_Grove06.png | W2_GLOVE_COMMON_ELECTRIC | 22772e4c7aa4165db749dd2acb6badbd535794585a9ab9eba00e63c1e6e485a7 | — | — | — | not_uploaded |
| Electric/Electric_Grove07.png | W2_GLOVE_UNCOMMON_ELECTRIC | f516bcd87eb5765c33d89b7dfbd00aa4acf7ac8faa8c9e8c617c2b31e4e443bd | — | — | — | not_uploaded |
| Electric/Electric_Grove08.png | W2_GLOVE_RARE_ELECTRIC | 30609a552b2781910067713da8a2bd4447507bf2bd402096d842e10a027d3fae | — | — | — | not_uploaded |
| Electric/Electric_Grove09.png | W2_GLOVE_EPIC_ELECTRIC | 89a41937c5f9a65624505a1555a3214f9b282a271be1332954875c781c3ceac4 | — | — | — | not_uploaded |
| Electric/Electric_Grove10.png | W2_GLOVE_LEGENDARY_ELECTRIC | 677afe72fb4535f45eb62b405887340560fe3681db9333e88729b7bce8a1f5fa | — | — | — | not_uploaded |
| Electric/Electric_Belt06.png | W2_TRAININGBELT_COMMON_ELECTRIC | 4cdf8143fa3b45dfb0a9d567451b43b4d68017f2314131cbf1605eefd92fd137 | — | — | — | not_uploaded |
| Electric/Electric_Belt07.png | W2_TRAININGBELT_UNCOMMON_ELECTRIC | 8efecf0b24f277adc4f05a8d495a79ee658b3c653087eb3770768848a62050f9 | — | — | — | not_uploaded |
| Electric/Electric_Belt08.png | W2_TRAININGBELT_RARE_ELECTRIC | 7f926f4379209cd7dec8cb379ce18f90739bcec43d2cfdc5f5127255cb5f9f0d | — | — | — | not_uploaded |
| Electric/Electric_Belt09.png | W2_TRAININGBELT_EPIC_ELECTRIC | 713b41f704ffc3a88a246495aa5946e6cb0d3f42c0c58b559d97d54ff5d4ae20 | — | — | — | not_uploaded |
| Electric/Electric_Belt10.png | W2_TRAININGBELT_LEGENDARY_ELECTRIC | 45d75021d40ea89679f6758f30dd5504b03c6b84ee18c504a39b7778e3f57710 | — | — | — | not_uploaded |
| Ice/Ice_Protein06.png | W2_PROTEIN_COMMON_ICE | 3ab2d9ddbd1eb1b6b65cc9793a436478583e5e1f8ad178ec62a5243473db6884 | — | — | — | not_uploaded |
| Ice/Ice_Protein07.png | W2_PROTEIN_UNCOMMON_ICE | 9f1fc9583da45556442a70a966a9c0b56ea73c6208f4840ebaa2d8dff4eca89a | — | — | — | not_uploaded |
| Ice/Ice_Protein08.png | W2_PROTEIN_RARE_ICE | 18e0557f2aa82cd56b30f330df155002c63606e79d44eefa886f70e397d2d108 | — | — | — | not_uploaded |
| Ice/Ice_Protein09.png | W2_PROTEIN_EPIC_ICE | 505fff3d3c6a78762ef5c1cc19b71b9894f45a30f3d1343ed8921930fa385714 | — | — | — | not_uploaded |
| Ice/Ice_Protein10.png | W2_PROTEIN_LEGENDARY_ICE | 4b5afcbef218213b4cfec5ece8f2f73b6bb4106c3a8dd9575eab3926731bb77f | — | — | — | not_uploaded |
| Ice/Ice_Grove06.png | W2_GLOVE_COMMON_ICE | fc61de01a6d8d1a3bd750bdf51391f8b440a1938e92ea281541b90a4bab726a2 | — | — | — | not_uploaded |
| Ice/Ice_Grove07.png | W2_GLOVE_UNCOMMON_ICE | 0a3359dce1e9645495f610c625665974fad5e4ce301e12470bf81c0a8ae274ed | — | — | — | not_uploaded |
| Ice/Ice_Grove08.png | W2_GLOVE_RARE_ICE | a32588918db7b0ed67fd5ab94dade5a5e24409698449c1868cc0f93a9f8661ef | — | — | — | not_uploaded |
| Ice/Ice_Grove09.png | W2_GLOVE_EPIC_ICE | eec475547b48e05e7fa27db03125665aaecc88ee5aa71aee548b27af10669bd3 | — | — | — | not_uploaded |
| Ice/Ice_Grove10.png | W2_GLOVE_LEGENDARY_ICE | 1b67dc06500156531a4ecb67b951fc56f15e41fda5aec8e12dd94629fe1fe6d7 | — | — | — | not_uploaded |
| Ice/Ice_Belt06.png | W2_TRAININGBELT_COMMON_ICE | 785be37e175b6a73b91494095a3b8880088c96decb29e0ae0528981002859cb7 | — | — | — | not_uploaded |
| Ice/Ice_Belt07.png | W2_TRAININGBELT_UNCOMMON_ICE | 7c4bf378957521fe3bebd9e6843e61619b3e116481f5123f3f1d3ac4bd2f17fc | — | — | — | not_uploaded |
| Ice/Ice_Belt08.png | W2_TRAININGBELT_RARE_ICE | f15167924a8cc1bd28d4704b2ce07837f27ccf8f7b7550a25a99663a1ae08cfe | — | — | — | not_uploaded |
| Ice/Ice_Belt09.png | W2_TRAININGBELT_EPIC_ICE | 44df78ed1ad1b89ce90543668be012fe29a42d36c8294f9250afe5777bf9d4d4 | — | — | — | not_uploaded |
| Ice/Ice_Belt10.png | W2_TRAININGBELT_LEGENDARY_ICE | 1fcbe728fe374e71f72373656c4f1ed7bf411006ac58cdd923531366ee424ffb | — | — | — | not_uploaded |

## 実装・検証

アップロード0/45。最初のFire/Fire_Protein06.pngについて、公式open_cloud_invokeがローカルファイルの許可検査で拒否した。スラッシュ表記と同じファイルのWindows標準表記で各1回、同じ拒否。APIのoperationやassetIdは返っておらず、アセットは作成されていない。残り44枚は未試行。ファイルの移動や別APIによる制限回避は行っていない。

ユーザーからUpload folders登録・許可済みと明示された後の実呼出し結果であり、未登録と断定するものではない。現在の接続が認識している許可とユーザーの設定が一致していない。拒否文：`is not inside a directory approved for uploads`。まず拒否された原本のFireサブフォルダーが現在の副本接続で許可される必要がある。

取得したRoblox提供rbx-permissionsの該当指示：`File not in an approved upload directory: ask the user to approve its directory ... Don't copy or move it yourself.` この制限のためアップロードを止めている。APIキーやCookieの提供は不要。

World2画像差し替え・審査・ImageLabel読込・隔離Playは未実施。StudioのSource/Objectは変更せず、元の511 Source/editorを保持。副本はEdit、Save/Publishなし。既存UIのWorld1/World2共通画像参照も現状のまま。画像IDを推測して実装しない。

重複するローカル検証ファイルは整理し、今回の記録は既存reports内のこの1ファイルに統合。前回のSourceバックアップ10件は既存commit4b0560bと全文一致し、履歴から復元可能であることを確認した。元のDownloadsの画像45枚は一切変更しない。重い画像原本のGitHub複製も行わない。

公式資料：[Studio MCPの権限とUpload folders](https://create.roblox.com/docs/studio/mcp-open-cloud)、[Assets API](https://create.roblox.com/docs/reference/cloud/assets/v1)、[アップロード・operation・moderation](https://create.roblox.com/docs/cloud/guides/usage-assets)。
