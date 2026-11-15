# Analytics・退出時生成・Item画像の修正報告（2026-11-15）

副本Studioへ6 Sourceと4個の固定Imageプロパティを反映した。隔離した実Playで3結果のOreファネル、通常参加・死亡復帰・World1/World2配置、Item描画と代表的な操作を確認した。退出タイミングの競合全条件、実Analytics API/Creator Hub、実機・複数クライアントなどは未確認であり、完全解消や「バグなし」とは判定しない。

## 対象と終了状態

- 接続を照合した副本：PlaceId **126576845524886**、UniverseId **10765181857**。
- Git基準：origin/main `4b0560b526b20fa5a157f5e942edc607ffaa36dc`。独立作業ツリーで実装。既存の別チェックアウトの未commit編集には触れていない。
- 開始時、対象10 SourceのStudio Source/editorを最新GitHubと比較し一致を確認。作業中は現在のStudio Sourceを基準に条件付き更新した。終了時は元の511 Source/editorを再照合し、今回の6変更以外の505件が開始時と一致。
- Play中だけ39 Sourceの外部サービス参照をメモリ実装へ置換。本番DataStore、実課金は使用していない。終了時に39件を条件付き復元、最後の検証Object5個を除去し、`__ThreeFix*` / `__PostOre*`残存0件。前のPlay用補助も除去済み。
- カメラと端末設定を作業前へ戻し、副本は**未保存Edit**。Studio自体は閉じていない。Save/Publish、保存GUI、正本、PR #1の操作なし。
- [数値・観測記録](evidence.json)、[固定Imageの変更記録](studio_image_properties.json)。画像キャプチャは目視後に保管せず、報告へ添付していない。

## 変更Full Path

| Studio Full Path | 内容 |
| --- | --- |
| ReplicatedStorage.Config.ItemMaster | 種類×属性×レアリティで45画像を一元定義。90 Itemの画像だけを変更 |
| ServerScriptService.Services.FirstPlayAnalyticsService | OreのCustomEvent分類を短い区別可能な名称へ変更 |
| ServerScriptService.Services.FirstPlayAnalyticsTransport | Studio/公開側共通のCustomField検査、失敗診断、ファネル後続抑止 |
| ServerScriptService.Services.LobbySpawnService | PlayerRemoving開始、生成/要求/Characterの所有権、待機・予約・接続の終了処理 |
| StarterGui.StrengthGui.ItemInventoryTabClient | Itemsタブの固定アイコンを共通正本から設定 |
| StarterGui.StrengthGui.EssentialStudShopClient | Shop内Holderの二重クリップで動的商品が切れる問題を修正 |

対応ファイルは同階層の `src/`。LocalScriptのみ `.client.luau`、その他は `.luau`。

固定Objectは次のImageだけを更新した。これらはStudioの未保存プロパティ変更で、ファイル管理されないObjectにも再適用できるようJSONに記録した。実行時も上記の共通正本参照で同じ画像になる。

| Full Path | 旧ID → 新ID |
| --- | --- |
| StarterGui.StrengthGui.ShopPanel.MainScrollingFrame.Holder.Card07_RedProtein.Icon | 88813844869136 → 119239917570949 |
| StarterGui.StrengthGui.ShopPanel.MainScrollingFrame.Holder.Card08_RedGlove.Icon | 112294938722512 → 131063706477806 |
| StarterGui.StrengthGui.ShopPanel.MainScrollingFrame.Holder.Card09_RedBelt.Icon | 123189885722060 → 135152518487596 |
| StarterGui.StrengthGui.InventoryPanel.Tabs.Items.Icon | 88813844869136 → 119239917570949 |

## 1. Analyticsの原因と修正

ファネル分類の `PostFirstBattle_v2:<結果>` 自体は制限内だったが、CustomEvent用にステップ名、Death、Bypass理由を連結すると50文字を超えた。例えばVictoryのLobby段階は56、Deathは54、Backは53。Studio Transportは実APIへ送らず記録していたため、同じ入力の拒否を再現できなかった。

ファネル名 `MTF_FirstOreMerge_v1`、固定分類 `PostFirstBattle_v2:Victory/Death/Back`、5段階の番号・表示名は維持した。CustomEventだけを以下へ変更。数値は引き続き**参加時点からの経過秒**であり、初戦終了起点へ変えていない。対象者、順序、重複防止、ゲーム進行・チュートリアル・合成・保存処理は変更していない。

### CustomField03の新旧対応

以下のRはVictory、Death、Backそれぞれ。完全な42行と文字数は [analytics_classifications.csv](analytics_classifications.csv)。新42値はすべて相互に異なり、最大34文字。先頭切り捨ては使用しない。

| 用途 | 旧値 | 新値 |
| --- | --- | --- |
| 時間1 | PostFirstBattle_v2:R:FirstBattleEnded | PF2:R:BattleEnd |
| 時間2 | PostFirstBattle_v2:R:LobbyPlayableAfterFirstBattle | PF2:R:LobbyReady |
| 時間3 | PostFirstBattle_v2:R:MergeGuideShown | PF2:R:GuideShown |
| 時間4 | PostFirstBattle_v2:R:OreViewOpened | PF2:R:OreView |
| 時間5 | PostFirstBattle_v2:R:MergeCommitted | PF2:R:MergeDone |
| 死亡1～5 | 上記旧時間値の先頭にDeath: | 上記新時間値の先頭にDeath: |
| Bypass | PostFirstBattle_v2:R:Bypass:OreViewBeforeLobbyReady | PF2:R:Bypass:ViewBeforeReady |
| Bypass | PostFirstBattle_v2:R:Bypass:OreViewBeforeGuide | PF2:R:Bypass:ViewBeforeGuide |
| Bypass | PostFirstBattle_v2:R:Bypass:MergeRequestWithoutPrefix | PF2:R:Bypass:RequestNoPrefix |
| Bypass | PostFirstBattle_v2:R:Bypass:MergeCommitted | PF2:R:Bypass:MergeCommitted |

CustomField01は `PlaceVersion:<version>`、02は既存cohort、03は上記以外の既存分類を維持。現在の生成値はASCIIで、全分岐の生成値検査を実施した。将来の値もTransportで文字列型・UTF-8妥当性・50バイト以内を検査する。非ASCIIへの50バイト判定は保守的であり、50 Unicode文字まで許可する実装ではない。

不正値は送信前にDroppedへ計上し、イベント名・Kind・Step・不正フィールド・型・長さを警告する。フィールド値やプレイヤー情報は出力しない。警告はセッション当たり先頭8件に制限。ファネルの不正値・送信失敗はそのファネルのSendBrokenを立て、後続だけを送らない。無関係なファネル/CustomEventやゲーム処理は継続する。Queue内の値はコピーし、検査後の呼出元変更を遮断した。既存の64件キュー、30秒期限、送信予算、再送なしは維持。

### 検証結果

| 項目 | 区分・結果 |
| --- | --- |
| Victory / Death / Back通常5段階 | **実Play**。各5 Funnel + 5 Custom、表示名・分類・順序をStudio recorderで確認 |
| 3結果×各段階の死亡記録 | **模擬**。実Sourceに依存アダプタを注入し全15段階を確認 |
| Guide前開店 / Lobby準備前開店 / 前段不足の要求・完了 | **模擬**。Bypass分類と後続ファネル停止を確認 |
| CF01～03の50/51境界、型、UTF-8、待ち中の値変更 | **模擬**。Studioと公開側送信分岐双方で許可/拒否を確認 |
| 重複、順序、対象除外、時間起点、分類衝突 | **模擬**。AnalyticsMatrix 1,631 assertion |
| 他5ファネルの回帰 | **模擬**。変更前後18行の名前・番号・表示名・分類・順序が一致 |
| 送信例外、キュー上限、独立ファネル継続 | **模擬**。TransportMatrix 26 assertion、既存stress 52 check |
| 実API・Creator Hub受信 | **未確認**。Studio recorderを受信証拠としていない |

実Playは空のメモリプロファイルと初戦用の準備状態を使った。DeathはBoss攻撃による死亡、Backは既存の検証付きRunReturn、Victoryは間隔を空けた既存EnemyManager攻撃処理による撃破。その後は実クライアント描画観測、Ore画面操作、Stone2個の合成、メモリへの保存完了を通した。自然な最初の参加から全育成を手操作で通した試験ではない。

stressは20人相当の瞬間負荷で920件中380送信/540ローカルdrop、既存基準720件中380/340。これは偽時計による既存の飽和制約の確認であり、実20人Playや実サービス性能の測定ではない。サーバーで検知できないプラットフォーム側の欠落も防ぎきれない。

## 2. 退出時生成の原因と修正

従来はLoadCharacterAsync直前のParentだけを確認し、戻った時点でloadingを外していた。PlayerRemoving中でもParentがPlayersの短い期間、新しい要求が入れた。さらにエンジン戻り、体型待ち、ストリーミング待ちの後に古い処理が継続でき、待機や死亡復活予約を十分に解放していなかった。

PlayerインスタンスをキーとしたleavingをPlayerRemovingの開始で立てる。生成所有者はエンジン・体型・ストリーミング・配置完了まで保持し、すべての再開点で退出・所有者・Character・要求を再確認する。旧処理が新しい所有者を消さない。MuscleScaleReady待ちは退出・Character消失・死亡・要求差替で解除し、接続とBindableを破棄。死亡予約、遅延stream予約、Character/Player接続を終了し、当該要求が保持したアンカーを元へ戻す。

Prefetchの完了も同じPlayer/Character/ジョブの場合だけ反映する。差替済みprefetchを待ち続けないよう、待機条件へ現在のキャッシュとの同一性を加えた。接続中の本当の生成・準備失敗は警告を残し、自動無限再試行は追加していない。

### 2行のログの調査

- `[LobbySpawn] Character load failed:` はこのService内のpcall失敗警告。
- `Character cannot be changed ... is being removed` の文字列を出すLua Sourceは見つからなかった。対象511 Sourceに実LoadCharacterAsync呼出しはこの箇所1つで、EnemyManagerの復活要求もこのServiceへ委譲。直接のPlayer.Character代入も見つからない。
- 2行目は今回の実Playでは再現しなかった。同じ呼出しのエンジン内部ログである可能性はあるが、発生元を確定していない。すでに進行中のエンジン生成自体はLuaから取り消せず、無効な戻り値の継続を抑止する対策である。エンジン警告の完全消失は保証しない。

| ケース | 検証区分・結果 |
| --- | --- |
| 初回生成開始前退出 | 模擬：ParentがPlayersのままでもLoadを開始しない |
| LoadCharacterAsync中退出 | 模擬：帰還結果を破棄し、配置/再生成しない |
| MuscleScaleReady待ち中退出 | 模擬：待機解除、接続解放 |
| Lobby stream待ち中退出 | 模擬：後続配置を抑止、所有アンカーを解放 |
| 死亡後、復活予約前退出 | 模擬：予約取消、新Loadなし |
| 同UserIdの新Player / 他プレイヤー | 模擬：旧Playerの終了が妨害しない |
| 古いCharacter/要求、二重Load、prefetch差替 | 模擬：古い継続の書込みと待ち続けを防止 |
| 接続中の生成失敗 | 模擬：警告を検知、成功扱いしない、無限再試行なし |
| 通常初回参加・死亡復活 | **実Play**。Health100、Engine/Scale/Placed true、最後にAnchored=false |
| World1/World2配置・World2死亡復帰 | **実Play**。fixtureのWorld指定から既存生成処理を使用。自然なWorld解放経路は対象外 |
| 最終Sourceでの通常参加・死亡復帰 | **実Play**。prefetch修正後にも実施、MuscleScaleReady→LobbySpawnPlacedの順序を観測 |
| 実Playでの生成中切断 | **未確認**。Kick試行はLoadが先に戻ったため、競合の再現には不成立 |
| 実ネットワーク再参加・複数実クライアント | **未確認** |

SpawnMatrixは34 assertion合格。これは実Sourceの制御フローを偽Players・時計・エンジン/stream待機で検査した結果。正常系の実Playと混同しない。

## 3. Item画像45件と共通経路

01=Common、02=Uncommon、03=Rare、04=Epic、05=Legendaryを今回の指定どおりに割当。アップロード名Grove/Beltを内部Glove/TrainingBeltやItemIdへ持ち込んでいない。World2は既存のWorld1コピー関係を維持し、表示ランク6～10でも同じ元rarityの画像を共有する。新規画像・推測番号はない。

90定義について画像以外のプロパティ1,692比較が一致。ItemId、効果、価格、所有/装備/保存形式、解放、確率、合成条件/消費/結果を変更していない。旧9画像IDのSource直書きと対象UIの実Objectを調査し、一般属性マーク、Trophy、Pet、Ore、Dumbbell、ポーション、Gamepass看板へ一括置換していない。

| 属性 | 内部種類 | アップロード番号 / rarity | 新Asset ID |
| --- | --- | --- | --- |
| Fire | Protein | 01 / Common | 119239917570949 |
| Fire | Protein | 02 / Uncommon | 108422218042975 |
| Fire | Protein | 03 / Rare | 79765453122830 |
| Fire | Protein | 04 / Epic | 82077986207411 |
| Fire | Protein | 05 / Legendary | 91739900505998 |
| Fire | Glove | 01 / Common | 131063706477806 |
| Fire | Glove | 02 / Uncommon | 98887322321581 |
| Fire | Glove | 03 / Rare | 77605756931267 |
| Fire | Glove | 04 / Epic | 109538064430664 |
| Fire | Glove | 05 / Legendary | 73308020209583 |
| Fire | TrainingBelt | 01 / Common | 135152518487596 |
| Fire | TrainingBelt | 02 / Uncommon | 139567332510562 |
| Fire | TrainingBelt | 03 / Rare | 93608276021361 |
| Fire | TrainingBelt | 04 / Epic | 74118581220310 |
| Fire | TrainingBelt | 05 / Legendary | 104564972440529 |
| Ice | Protein | 01 / Common | 109626867118785 |
| Ice | Protein | 02 / Uncommon | 91362170512211 |
| Ice | Protein | 03 / Rare | 82858655370111 |
| Ice | Protein | 04 / Epic | 82889919252005 |
| Ice | Protein | 05 / Legendary | 124374248196874 |
| Ice | Glove | 01 / Common | 77728202879648 |
| Ice | Glove | 02 / Uncommon | 139999591744437 |
| Ice | Glove | 03 / Rare | 110123985270101 |
| Ice | Glove | 04 / Epic | 110315224232470 |
| Ice | Glove | 05 / Legendary | 93781714149316 |
| Ice | TrainingBelt | 01 / Common | 110481788029040 |
| Ice | TrainingBelt | 02 / Uncommon | 123049417284290 |
| Ice | TrainingBelt | 03 / Rare | 117141510259080 |
| Ice | TrainingBelt | 04 / Epic | 132759157132674 |
| Ice | TrainingBelt | 05 / Legendary | 96064369103679 |
| Electric | Protein | 01 / Common | 88641679595352 |
| Electric | Protein | 02 / Uncommon | 85795080513978 |
| Electric | Protein | 03 / Rare | 107739440992464 |
| Electric | Protein | 04 / Epic | 103146146252897 |
| Electric | Protein | 05 / Legendary | 97578658858016 |
| Electric | Glove | 01 / Common | 111718628408896 |
| Electric | Glove | 02 / Uncommon | 102792375678043 |
| Electric | Glove | 03 / Rare | 119911873482523 |
| Electric | Glove | 04 / Epic | 134926043547076 |
| Electric | Glove | 05 / Legendary | 131591548966635 |
| Electric | TrainingBelt | 01 / Common | 96496752053787 |
| Electric | TrainingBelt | 02 / Uncommon | 85833750596611 |
| Electric | TrainingBelt | 03 / Rare | 119294353394586 |
| Electric | TrainingBelt | 04 / Epic | 105659825652489 |
| Electric | TrainingBelt | 05 / Legendary | 99054363236474 |

[CSV（World1/World2 ItemIdを含む）](item_images45.csv)。45IDに欠番・重複なし。実Marketplace metadataは全45件AssetTypeId=1。Fireの一部名称はStudioで日本語にローカライズされるが、ID/番号対応を照合した。

### 表示経路と操作

| 経路 / Source | 確認結果 |
| --- | --- |
| Itemインベントリ一覧 / ItemInventoryTabClient | item.Image。実Playで表示、rarityタブ、スクロール、開閉、World2ランク10を確認 |
| 装備スロット・未装備種類アイコン / 同上 | 装備品Image、未装備Common Fireを共通正本から取得。実クリック装備後も個数・Win不変 |
| 装備効果HUD / ItemEffectHUDClient | equipped item.Image。実PlayのProteinアイコン読込・表示を確認。属性セットマークは従来のまま |
| Shop商品 / EssentialStudShopClient | 共通item.Image、39 ItemカードのID対応を実Playで確認。PC/スマホの画面描画、実Win購入を確認 |
| マージ一覧・選択・投入・ドラッグ / MergePanelClient_New → MergeShopView | 共通画像。実Playで素材2個選択、ドラッグ画像、解除、再選択を確認 |
| マージ候補・完成 / MergeShopView | Master.Get(outcome.ItemId).Image。World2 Legendary Fire Gloveの候補/完成画像を実Playで確認 |
| 売却選択/詳細 / ItemInventoryTabClient | 実Playで選択表示と1個売却。4→3個、Win100000→100037、装備維持 |
| 敵ドロップ / EnemyDropGachaClient | Masterから取得。fixtureのTryAddDropと実通知で新画像・IsLoaded/Shown=trueを確認。自然抽選や演出全体の目視は未確認 |
| その他のItem購入/報酬 | 関連SourceのMaster参照を静的確認。すべての購入/報酬画面を実操作したとは扱わない。Robux購入/receiptは未実施 |

Shopの空白は実Play中に特定した。Holderの固定参照高さ約2795.56に対し内容約6352.05、Item行の相対Y約3372が外に出ていた。Holder.ClipsDescendants=trueと外側ScrollingFrameの二重クリップが原因。Holderだけfalseにし、外側のclipを維持。配置・サイズ・星・価格・操作方式は変更せず、動的行を外側スクロール窓で描画する。PC/スマホで欠落解消を目視、Win購入は4→5個、100000→99925、メモリ書込9回を確認した。

Item mergeの実操作では同一最高rank素材4→3個（2消費・1生成）、Win100037を維持。これは代表例の確認で、全確率/全装備組合せの網羅試験ではない。保存結果はメモリアダプタまで確認し、本番保存互換性の実DataStore試験は行っていない。

### 読込と描画の区別

- 実クライアントのImageLabelを使うPreloadAsyncで45件すべてSuccess。対象45件について403・削除・審査待ちによる読込失敗は今回のStudio接続では観測しなかった。公開環境での権限は別途未確認。
- PCの実Playギャラリーで45画像すべてを目視。透明背景と高rank装飾を確認し、画像の切抜き/余白加工はしていない。ゲームUIは下記の代表経路を目視した。
- PC約1346×624：インベントリ、装備HUD、Shop、売却、マージ。スマホ相当iPhone17Proの実viewport約749×381：Inventory/ShopとElectricギャラリー。タブレット相当iPad Pro M5の約1374×1030：Legendary Inventory。**全45×全画面×全端末の総当たり目視は未実施**。
- 最終タブレットShopはImage/IsLoaded/viewport/clip状態を記録。最後のキャプチャは評価できていないため、タブレットShopの最終目視完了とはしない。
- 画面外カードのIsLoaded=falseは、表示失敗と区別。敵ドロップはIconの読込/表示フラグを確認したが、短い演出をキャプチャで捉えられず、装飾まで目視確認済みとはしない。
- 実スマホ/タブレットのタッチ入力・性能、公開版の描画は未確認。

## 実行時の問題と対処

初期ClientはFrames=0、Viewport=1×1で描画停止状態だった。Studioの実クライアントタブを前面へ戻した後、RenderStepped進行と実viewportを確認して描画検証した。この状態を画像読込失敗とは扱わない。

検証補助のraw URI一括Preloadは有効な旧画像を含めFailureを返した。ImageLabelインスタンスを渡す補助へ直し、45件Successを再取得した。補助の実行Context・マウス座標指定・非モバイル端末のOrientation設定によるエラーも修正/回復した。これらを本体修正の成功証拠には含めない。

既存の別画像/音声の権限警告や `Images/wd` 不在警告を観測した。対象45IDの警告ではなく、今回の置換対象外。例：17387207972、95256658378010、139190015780830。Badge関連の失敗警告は隔離アダプタがfalseを返すため。最後のShop Play consoleは初期化4行で、今回対象のエラー/Infinite Yieldは観測しなかった。すべての経路でエラーがないことを保証するものではない。

## 再実行・残る確認

[テスト手順](../../tests/AnalyticsSpawnItems/README.md) と同フォルダのLuauを使用。模擬テストは実APIや実退出を再現したことにならない。実Playには外部サービス隔離と、その時点のSource/editorを保存する手順が必要。

所有者による公開後の確認は今回の未実施範囲：実API/Creator Hubで新Custom分類を確認し、ファネルの固定分類と分けて集計する。生成中の実切断/再参加・複数プレイヤー、実端末・公開asset権限、自然抽選ドロップ演出、未操作購入/報酬経路を確認する。今回のためにSave/Publish・課金を行っていない。

Git提出は今回の6 Source、専用tests、報告、関連SPEC/DEV_STATUS/CHANGELOGのみ。別チェックアウトの編集、.qaの開始時バックアップ、AGENTS.md、検証画像はcommit対象外。通常pushの成否とcommit IDは最終応答で提示する。
