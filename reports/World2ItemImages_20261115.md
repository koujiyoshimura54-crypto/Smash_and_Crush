# World2 Item画像06〜10 — 完了報告（2026-11-16）

副本PlaceId **126576845524886** / UniverseId **10765181857**。現在の未保存Studioを基準に、World2の45画像を登録・反映し、隔離した実Playで代表表示経路を検証した。World1の45画像は維持。ゲームのSave/Publish、正本Place101572058398926、PR #1は操作していない。

## 入力・アップロード

- 原本はユーザー指定の `C:\Users\kouji\Downloads\World2_Items_06-10_AllElements\World2_Items_06-10`。CODEX_PROMPT.txt、manifest、生成仕様を確認。
- 45件のSHA256・サイズがmanifestと一致。重複・欠番なし。合計59,561,527 bytes、全画像1254×1254 RGBA透過PNG。原本の一覧で属性・06〜10・Groveの左右ペアを目視確認。
- **06=Common / 07=Uncommon / 08=Rare / 09=Epic / 10=Legendary**。表示ランク6〜10、Grove→Glove/GLOVE、Belt→TrainingBelt/TRAININGBELT。ItemIdやrarityは新設しない。
- asset:read / asset:writeを使用。最初の拒否は、接続中StudioのUpload directoriesが空だったことが原因。ユーザーの「追加して進めて」に従い、上記の原本フォルダー1件をAssistant MCP設定へ登録した。ここで保存したのはMCP設定だけであり、ゲームの保存ではない。
- 公式Assets APIへ各画像1POST。operationを直ちに記録し、処理中はGETで追跡。45個の異なるImage assetId、所有者User **7467238848**（ゲーム所有者と一致）、アップロード名、審査 **Approved 45/45** を確認。
- Fire_Belt08/10は説明文中のSHA256がRobloxテキストフィルターで伏字になった。画像・名前・所有者の拒否ではなく、両画像ともApproved/実読込成功。原本ハッシュは下表に保持し、後続の説明文からハッシュだけを省いた。
- ユーザーの最新指示に従い、新規フォルダーや画像原本の複製を作らず、約60MBのPNGをGitHubへ追加しない。検査画像は保持・commitしない。対応表と結果はこの既存ファイルに集約する。

## 変更Full Path・原因

実装変更は **ReplicatedStorage.Config.ItemMaster**（`src/ReplicatedStorage/Config/ItemMaster.luau`）だけ。

以前はWorld1の定義をcloneした際にImageも引き継いでいた。種類×属性×既存rarityのWorld2専用45画像を同じ共通正本へ追加し、World2 cloneのImageだけを上書きする。各UIへの対応表の重複実装はない。空装備スロット・種類タブのCommon Fire画像は既存World1画像のまま。

現在Source/editorをGit基準241efd5と照合した後、最新Studio Sourceへの差分として反映。全90定義の前後比較ではWorld2のImage45件だけが変化し、World1の全フィールド、World2のImage以外の全フィールドが一致。ItemId、価格、購入条件、効果、装備、保存形式、合成・ドロップ仕様を変更していない。

## 45画像の対応表

画像番号は原本名を正本とする。各行のstatusは登録・審査状態であり、それだけで画面表示を確認したことにはしない。実読込・描画は後述。

| 原本相対パス | 既存ItemId | SHA256 | operation | assetId | UI画像URI | 状態 |
| --- | --- | --- | --- | --- | --- | --- |
| Fire/Fire_Protein06.png | W2_PROTEIN_COMMON_FIRE | f9ead7ecc3e0ff792ecf767137bc7903d970cf9034c5572aff59d1f8d51e5b9d | operations/f17a8000-c9c1-4807-8f93-31f2e87c61bd | 136237412165016 | rbxassetid://136237412165016 | Approved |
| Fire/Fire_Protein07.png | W2_PROTEIN_UNCOMMON_FIRE | 2b5bf50025a7b9f8629d72266f24f17270f21fe1c8fb2d0dcea9b9084f481941 | operations/ce170e14-4f55-404e-8c82-b65934943aa8 | 80099985786353 | rbxassetid://80099985786353 | Approved |
| Fire/Fire_Protein08.png | W2_PROTEIN_RARE_FIRE | d92ee59aadbbda1f7edb9560075735f1b9e460ee23f12c43fecfd311c9522da3 | operations/cf2070e1-51f3-4154-b714-fd1f5e9a5b0a | 99340317645486 | rbxassetid://99340317645486 | Approved |
| Fire/Fire_Protein09.png | W2_PROTEIN_EPIC_FIRE | 909d74723f11e6249d899c01daba6bbd1fcf774e2ec4da5570a7620095ce1a44 | operations/8f3ec29a-a32a-489a-bcfd-378fa6d3b10a | 134953233792211 | rbxassetid://134953233792211 | Approved |
| Fire/Fire_Protein10.png | W2_PROTEIN_LEGENDARY_FIRE | eb161c332d30f35940970ed83d8e2d4d4599fc050e974e5aeb206c9c268d3744 | operations/5ff54f72-2dd4-4e50-9289-1e0b06a0758c | 77017472463243 | rbxassetid://77017472463243 | Approved |
| Fire/Fire_Grove06.png | W2_GLOVE_COMMON_FIRE | 1daa0fe278462bc37a766fc0b27d6f87e8f6de62164c2c9c11f461da51690007 | operations/4e086be9-972c-4fc2-9e47-d351df5c0131 | 74280673512618 | rbxassetid://74280673512618 | Approved |
| Fire/Fire_Grove07.png | W2_GLOVE_UNCOMMON_FIRE | 5be291771a84684b5245258d722b86dcab11b62bb42a416ac750440e6812c749 | operations/44f1f3c2-8deb-4232-92d3-8b984d6d9533 | 90055877712309 | rbxassetid://90055877712309 | Approved |
| Fire/Fire_Grove08.png | W2_GLOVE_RARE_FIRE | 2b2f6d36b732d477dd09f85797e1c0cf1cea917015769fd97bcca1db3626ec07 | operations/bec4cd53-e12d-4e89-a867-32ab50fae0b5 | 117035832275501 | rbxassetid://117035832275501 | Approved |
| Fire/Fire_Grove09.png | W2_GLOVE_EPIC_FIRE | ba793e6ea2ed7d35c73fa4511fb83c3ece28ab07b5a7576774e4022587cc1baa | operations/bc197741-64cb-4fb6-bbfe-fb5890f2f598 | 113185001705480 | rbxassetid://113185001705480 | Approved |
| Fire/Fire_Grove10.png | W2_GLOVE_LEGENDARY_FIRE | f1f01ca632898cd3d6294502cd56cd7b9f960c36f0df95ec11fe46b1973b5ef5 | operations/73c70068-1b07-49ec-a674-3ae91e87ba46 | 121235136564738 | rbxassetid://121235136564738 | Approved |
| Fire/Fire_Belt06.png | W2_TRAININGBELT_COMMON_FIRE | ca0b7e54d3170ea1dc29df4e679a33e0eb0d95eafcdc9d1082ec65608ccf835e | operations/408ed204-c500-4fbe-aa0f-b4aa27451d06 | 86486962390940 | rbxassetid://86486962390940 | Approved |
| Fire/Fire_Belt07.png | W2_TRAININGBELT_UNCOMMON_FIRE | 1a322fe675ab11f988ddd1e20e33bcd72cf47360ebc3a77aa745989ed7fbf261 | operations/71833af2-6cb9-4115-a809-6aafa01a42d6 | 120496332637611 | rbxassetid://120496332637611 | Approved |
| Fire/Fire_Belt08.png | W2_TRAININGBELT_RARE_FIRE | 32a624ab69c9f97f2dd83827a310ae68458850688c6524777596d469dbafd12f | operations/336fdb1f-4373-4ff8-ae21-67697c2b7490 | 99570951073156 | rbxassetid://99570951073156 | Approved |
| Fire/Fire_Belt09.png | W2_TRAININGBELT_EPIC_FIRE | df077bc8da9de13d213975e5e9c9e498b609261bd970a69353149afb8399edf9 | operations/cf2f149a-2436-4842-b340-61b9b01efc14 | 76162631763634 | rbxassetid://76162631763634 | Approved |
| Fire/Fire_Belt10.png | W2_TRAININGBELT_LEGENDARY_FIRE | 525e9ef0a3603ad52336338fd1ecf4c7174030d4bb7c7a1abedbf9b3c2a5991a | operations/f71b0758-c504-44b3-b687-007f28530697 | 71249795305351 | rbxassetid://71249795305351 | Approved |
| Electric/Electric_Protein06.png | W2_PROTEIN_COMMON_ELECTRIC | fc17dc15d1673b017eec32106ac2179f9c1df19df3932c7b07621a03d6353c15 | operations/b7b5c36d-2b96-47fd-b1fe-9a70719803bf | 106178663042067 | rbxassetid://106178663042067 | Approved |
| Electric/Electric_Protein07.png | W2_PROTEIN_UNCOMMON_ELECTRIC | 471d587359a670d02e2e1df690702510304b22555a119dd79dff8387239f434f | operations/4965f772-01a4-4ebd-8dea-f638c87de109 | 87357549308053 | rbxassetid://87357549308053 | Approved |
| Electric/Electric_Protein08.png | W2_PROTEIN_RARE_ELECTRIC | d58cbd97da19c87f2add92bbc4aff9f64e3aaf5bc8858fa47b47e5995752bf0d | operations/50bc2c6a-f503-4c2c-ba7c-9e267e1528cd | 117336147289487 | rbxassetid://117336147289487 | Approved |
| Electric/Electric_Protein09.png | W2_PROTEIN_EPIC_ELECTRIC | 178bd94c17a94f2ec64e087f448c041e2e6c78594b9e3dc4e9e29151bb244211 | operations/7baf5817-63e2-4381-adc5-bafe2e140901 | 113727967764645 | rbxassetid://113727967764645 | Approved |
| Electric/Electric_Protein10.png | W2_PROTEIN_LEGENDARY_ELECTRIC | 5bca4fa280cf69c85beee5787949f0df67910fa2dca6ccd17508a15bd9154959 | operations/3b29c959-2c21-4578-a57e-7049268caa93 | 117269460565255 | rbxassetid://117269460565255 | Approved |
| Electric/Electric_Grove06.png | W2_GLOVE_COMMON_ELECTRIC | 22772e4c7aa4165db749dd2acb6badbd535794585a9ab9eba00e63c1e6e485a7 | operations/38d9aa02-031b-4af8-8cd0-fa758265b1ce | 114306457808851 | rbxassetid://114306457808851 | Approved |
| Electric/Electric_Grove07.png | W2_GLOVE_UNCOMMON_ELECTRIC | f516bcd87eb5765c33d89b7dfbd00aa4acf7ac8faa8c9e8c617c2b31e4e443bd | operations/1e829a4e-5809-4d52-91e2-cc396bf1efe7 | 71242187536138 | rbxassetid://71242187536138 | Approved |
| Electric/Electric_Grove08.png | W2_GLOVE_RARE_ELECTRIC | 30609a552b2781910067713da8a2bd4447507bf2bd402096d842e10a027d3fae | operations/7029433c-8c25-4599-98d6-051d3fa5d835 | 74986318363859 | rbxassetid://74986318363859 | Approved |
| Electric/Electric_Grove09.png | W2_GLOVE_EPIC_ELECTRIC | 89a41937c5f9a65624505a1555a3214f9b282a271be1332954875c781c3ceac4 | operations/bfceff95-694d-4d4a-bd95-54d1c47d2972 | 100766710950328 | rbxassetid://100766710950328 | Approved |
| Electric/Electric_Grove10.png | W2_GLOVE_LEGENDARY_ELECTRIC | 677afe72fb4535f45eb62b405887340560fe3681db9333e88729b7bce8a1f5fa | operations/2a9a39ca-4855-41e8-a3a4-adaed9befe3c | 118096701999842 | rbxassetid://118096701999842 | Approved |
| Electric/Electric_Belt06.png | W2_TRAININGBELT_COMMON_ELECTRIC | 4cdf8143fa3b45dfb0a9d567451b43b4d68017f2314131cbf1605eefd92fd137 | operations/0dab007c-3348-4ec3-9749-c5490e73e9e9 | 106210517080753 | rbxassetid://106210517080753 | Approved |
| Electric/Electric_Belt07.png | W2_TRAININGBELT_UNCOMMON_ELECTRIC | 8efecf0b24f277adc4f05a8d495a79ee658b3c653087eb3770768848a62050f9 | operations/12a142aa-dcd6-43fe-8243-9af6b0f68d87 | 120230356848277 | rbxassetid://120230356848277 | Approved |
| Electric/Electric_Belt08.png | W2_TRAININGBELT_RARE_ELECTRIC | 7f926f4379209cd7dec8cb379ce18f90739bcec43d2cfdc5f5127255cb5f9f0d | operations/cbdd69c5-f17b-497f-8198-e4f0977d1c00 | 82574060179334 | rbxassetid://82574060179334 | Approved |
| Electric/Electric_Belt09.png | W2_TRAININGBELT_EPIC_ELECTRIC | 713b41f704ffc3a88a246495aa5946e6cb0d3f42c0c58b559d97d54ff5d4ae20 | operations/f558b776-5762-4e7a-b3cd-d4ce0bbc8cef | 113352940250561 | rbxassetid://113352940250561 | Approved |
| Electric/Electric_Belt10.png | W2_TRAININGBELT_LEGENDARY_ELECTRIC | 45d75021d40ea89679f6758f30dd5504b03c6b84ee18c504a39b7778e3f57710 | operations/b7a34c2e-25f6-4b9f-9f0c-813952c55504 | 86291841907893 | rbxassetid://86291841907893 | Approved |
| Ice/Ice_Protein06.png | W2_PROTEIN_COMMON_ICE | 3ab2d9ddbd1eb1b6b65cc9793a436478583e5e1f8ad178ec62a5243473db6884 | operations/f3d9d12d-bfd7-4077-a150-2a847f362618 | 118179858238695 | rbxassetid://118179858238695 | Approved |
| Ice/Ice_Protein07.png | W2_PROTEIN_UNCOMMON_ICE | 9f1fc9583da45556442a70a966a9c0b56ea73c6208f4840ebaa2d8dff4eca89a | operations/e4bded2b-e177-4285-9253-93e74f293bf1 | 129669865032093 | rbxassetid://129669865032093 | Approved |
| Ice/Ice_Protein08.png | W2_PROTEIN_RARE_ICE | 18e0557f2aa82cd56b30f330df155002c63606e79d44eefa886f70e397d2d108 | operations/473c0f1a-16c5-4d6a-bf08-2e6288ea6ba4 | 119680560024540 | rbxassetid://119680560024540 | Approved |
| Ice/Ice_Protein09.png | W2_PROTEIN_EPIC_ICE | 505fff3d3c6a78762ef5c1cc19b71b9894f45a30f3d1343ed8921930fa385714 | operations/54121b63-f996-46a8-b17b-e929c70b04fa | 130499515826855 | rbxassetid://130499515826855 | Approved |
| Ice/Ice_Protein10.png | W2_PROTEIN_LEGENDARY_ICE | 4b5afcbef218213b4cfec5ece8f2f73b6bb4106c3a8dd9575eab3926731bb77f | operations/81ec0a13-2925-40d2-82a5-859fa616c16a | 126723124357935 | rbxassetid://126723124357935 | Approved |
| Ice/Ice_Grove06.png | W2_GLOVE_COMMON_ICE | fc61de01a6d8d1a3bd750bdf51391f8b440a1938e92ea281541b90a4bab726a2 | operations/c8127de1-ddf2-461c-b4d3-a0123ff80875 | 82021641232664 | rbxassetid://82021641232664 | Approved |
| Ice/Ice_Grove07.png | W2_GLOVE_UNCOMMON_ICE | 0a3359dce1e9645495f610c625665974fad5e4ce301e12470bf81c0a8ae274ed | operations/664e0731-a5d0-4758-a4cd-3a549e653f89 | 86309716139764 | rbxassetid://86309716139764 | Approved |
| Ice/Ice_Grove08.png | W2_GLOVE_RARE_ICE | a32588918db7b0ed67fd5ab94dade5a5e24409698449c1868cc0f93a9f8661ef | operations/63e170e9-5916-4947-a4d3-20e153652c9f | 112482767004991 | rbxassetid://112482767004991 | Approved |
| Ice/Ice_Grove09.png | W2_GLOVE_EPIC_ICE | eec475547b48e05e7fa27db03125665aaecc88ee5aa71aee548b27af10669bd3 | operations/841107ab-eefe-4f39-a27e-4a5d11a42d1c | 72673766766004 | rbxassetid://72673766766004 | Approved |
| Ice/Ice_Grove10.png | W2_GLOVE_LEGENDARY_ICE | 1b67dc06500156531a4ecb67b951fc56f15e41fda5aec8e12dd94629fe1fe6d7 | operations/903b1ed1-2885-4af0-bdd2-72bff1297571 | 98934007987043 | rbxassetid://98934007987043 | Approved |
| Ice/Ice_Belt06.png | W2_TRAININGBELT_COMMON_ICE | 785be37e175b6a73b91494095a3b8880088c96decb29e0ae0528981002859cb7 | operations/a5f954c8-cf19-48e8-af81-dd87b2641d32 | 72918904494941 | rbxassetid://72918904494941 | Approved |
| Ice/Ice_Belt07.png | W2_TRAININGBELT_UNCOMMON_ICE | 7c4bf378957521fe3bebd9e6843e61619b3e116481f5123f3f1d3ac4bd2f17fc | operations/ac7db8a0-96fd-4007-80b3-1318167c4a63 | 89420899228447 | rbxassetid://89420899228447 | Approved |
| Ice/Ice_Belt08.png | W2_TRAININGBELT_RARE_ICE | f15167924a8cc1bd28d4704b2ce07837f27ccf8f7b7550a25a99663a1ae08cfe | operations/967e3e55-e400-4385-a0bb-8c68efa1a68f | 109476972668907 | rbxassetid://109476972668907 | Approved |
| Ice/Ice_Belt09.png | W2_TRAININGBELT_EPIC_ICE | 44df78ed1ad1b89ce90543668be012fe29a42d36c8294f9250afe5777bf9d4d4 | operations/4e0ab676-ab2c-4450-9dad-ab93d7e8bbef | 126465842000064 | rbxassetid://126465842000064 | Approved |
| Ice/Ice_Belt10.png | W2_TRAININGBELT_LEGENDARY_ICE | 1fcbe728fe374e71f72373656c4f1ed7bf411006ac58cdd923531366ee424ffb | operations/74629579-6108-490d-8a2f-99e00e9ea3c6 | 104684295265635 | rbxassetid://104684295265635 | Approved |

## 検証結果と表示経路

### 静的確認・設定評価

- 45ファイル/45ハッシュ/45 ItemId/45 assetIdが一意。欠番、属性・種類・番号の取り違えなし。Studioの全World2定義45件が下表URIと一致。
- 全90 Item定義の前後評価：World1 45件は全項目一致、World2はImageだけ変更。その他の公開定義・関数や確率には差分なし。
- 下記の既存UIは共通item.Imageを利用し、Source変更不要。World2 Shopカードは実行時に生成される。今回、一般属性マーク、Trophy、Pet、Ore、Dumbbell、Gamepassなどの固定画像を置換していない。

| Full Path | 経路 | 今回確認 |
| --- | --- | --- |
| StarterGui.StrengthGui.ItemInventoryTabClient | 一覧、装備枠、空種類アイコン、売却詳細 | 実PlayでWorld2ランク6/10、タブ・スクロール・開閉・装備を操作。装備枠と一覧のIsLoaded=true。空種類アイコン維持。タブレットで売却詳細2.5K/全4個10Kを表示（売却確定は未実施）。 |
| StarterGui.StrengthGui.EssentialStudShopClient | Shop商品カード | World2 Common Fire/Ice、Epic Fire/Ice/Electric、Rare Electric等をスクロールして実描画。画像はFit。Win購入サービスをnative serverから呼び、Common Fire Proteinを4→5、Win100000→95000と確認。UI購入ボタン全種・実課金は未実施。 |
| StarterPlayer.StarterPlayerScripts.UI.ItemEffectHUDClient | 装備効果HUD | World2 Common Fire Proteinの新画像と+200 STRを実描画。死亡復帰後も装備・IsLoaded=trueを保持。 |
| StarterPlayer.StarterPlayerScripts.UI.MergePanelClient_New / ReplicatedStorage.Modules.MergeShopView | 素材、選択、ドラッグ、候補、完成 | 実UI入力でWorld2 Legendary Electric Gloveを2個選択、1個解除、ドラッグで再投入。素材・投入枠・100%候補が同じ新画像でIsLoaded=true。Merge実行後4→3（2消費/1生成）、完成画像、選択0、Win95000維持を確認。 |
| StarterPlayer.StarterPlayerScripts.UI.EnemyDropGachaClient | 敵ドロップ取得演出 | 隔離native serverからWorld2の取得イベントを投入し、実clientのPersonalDropReward.Iconが新URI/IsLoaded=trueまで確認。頭上アイコンを判読できるスクリーンショットは取得できず、自然敵撃破からの抽選・全演出の目視は未確認。 |

### 今回の実Play

実際のStudio Server/Client ScriptとLocalScriptで実行。MCP側だけでrequireした模擬VMを実Play結果として扱っていない。既存の検証コードをメモリ内でWorld2向けに調整し、39 SourceのDataStore/Marketplace/Badge/Messaging/Policy参照を一時的なメモリアダプターへ隔離。本番DataStore・実課金は不使用。

- 初回参加・体型準備・配置を確認。通常死亡後、Health100、MuscleScaleReady=true、LobbySpawnPlaced=true、非アンカーへ復帰。装備とマージ後所持数を維持。World2へ配置後の画像経路も確認。
- PC相当 **1346×507**：3属性×15枚の一時ギャラリーを実描画し、各15枚IsLoaded=trueを確認。全45枚の透過、Grove左右ペア、高ランク装飾を目視。実UIは上表の範囲。
- iPhone 17 Pro相当 **749×381**、横向き：45件のPreload成功、ランク10実インベントリ、タブ/スクロール、Ice15枚の実描画。既存の縦長カードはスクロールが必要で、今回サイズや配置は変更しない。
- 13インチiPad Pro (M5)相当 **1375×1031**、横向き：45件のPreload成功、Electric15枚、ランク10/6実インベントリ、売却詳細を実描画。
- ゲームはLandscapeSensor。端末確認はStudioシミュレーターであり、実機タッチ/端末GPU/回線検証ではない。全45画像×全画面×全端末の網羅目視はしていない。
- 一時ギャラリーは画像自体の描画検査であり、実インベントリ・Shop・Merge画面の検証とは分けた。ギャラリー・全補助は最終的に除去。PC Merge検査時だけ新規プレイヤー向けガイドの画面を実client内で非表示にした。ガイドSource・保存データの変更はない。

### 発生したエラー・制約

- Ice_Protein06（118179858238695）の初回PreloadにHTTP502。再PreloadはSuccess、実画像IsLoaded=trueと目視を確認。後続のphone/tablet Playは全45件Success。今回の45枚で最終時点の403・審査未承認・削除は確認されていないが、将来の配信状態を保証しない。
- 一時Extra検証ScriptがPlayer追加前に走りassertした。検証補助の開始順序が原因で、PlayerAdded待機に直しnative実行を再開した。製品Sourceのエラーとして隠していない。
- 隔離BadgeServiceがfalseを返すためFirstLegendaryのAward failedが出た。実バッジ付与は未実施。
- World2/アバター読込中に、今回の45画像とは異なる既存IDで権限/未承認ログを確認：17387207972、95256658378010、139190015780830、82687933211372、7221927873、89137136456777、119910397965139。これらは今回置換していない。所有者・審査/権限設定や影響先の別調査が必要であり、プロジェクト全体の「エラーなし」とはしない。
- 上記の隔離実Playとは別に、全90定義比較とmanifest照合は設定評価/静的確認。外部保存の耐久性、実購入、公開ゲームでの配信、自然ドロップ全分岐は未確認。
- 元のAnalytics/退出時生成修正は既存commit241efd5と[前報告](AnalyticsSpawnItems_20261115/REPORT.md)の範囲。今回その仕様は変えておらず、実Analytics API/Creator Hub受信や切断競合の未確認項目を今回完了扱いにしない。

## 後始末・Git

39 Sourceの隔離差分を照合して復元し、検証Script/LocalScript・メモリアダプター・一時バックアップ・ギャラリーを除去。全 **511 Source/editor** を開始時と再照合し、意図したItemMaster 1件以外の **510件は一致**。残存補助0。デバイスは元のgeneric_handheld_720、カメラを復元。副本は未保存Editで停止。元の.blend/FBX、正本、PR #1、ゲームSave/Publishは操作していない。

今回のGit対象はItemMaster、本報告、UI_SPEC/DEV_STATUS/CHANGELOGの更新だけ。既存の別checkout編集は不使用。画像原本・スクリーンショット・重いファイル・新規フォルダーは追加しない。origin/mainをfetchして最新との差分を確認し、今回分を通常commit/pushする。
