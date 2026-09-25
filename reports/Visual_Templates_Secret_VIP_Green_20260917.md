# Secret / VIP / Green template追加 — 2026-09-17

Studio PlaceId: 101572058398926。ReplicatedStorage.AuraVisualTemplatesとTreadmillVisualTemplatesへSecret_Aura1 / Vip_Aura1 / Green_Aura2を独立したModelとして各3個追加。既存Model / Root / PrimaryPart方式を使用。Player側AttachToはHumanoidRootPart。正式Config割当は変更していない。

| 素材 | 元Attachment | Template Attachment | Particle | Beam | Trail | Highlight | Light |
|---|---:|---:|---:|---:|---:|---:|---:|
| Secret_Aura1 | 2 | 2 | 5 | 0 | 0 | 0 | 2 PointLight |
| Vip_Aura1 | 5 | 5 | 24 | 2 | 0 | 0 | 3 PointLight |
| Green_Aura2 | 21 | 3 | 4 | 2 | 0 | 0 | 0 |

Secret/VIPの元素材はWorkspace.Aura Pack Premium By Sanzzzzz内、GreenはWorkspace.Auras内。いずれもModel。元素材の削除・移動・renameなし。

Effectのない展示用人型の手足・頭・関節をClone側だけ除外。GreenのRig用Attachment18個は除外し、Root下のBottom / Top / RootAttachmentを保持。SecretのUpperTorso MeshPartは羽の取付部として元SizeとRoot相対位置を保持し、展示用の胴体面だけ透明化。Vector3Value2個も保持。RootのSize、全Attachment局所CFrame、Particle / Beam / Light設定を維持し、Beam参照先は各Clone内へ接続。2,314個のVisualプロパティ比較で相違なし。Partの配置はRoot原点へ正規化し、物理接触を無効化する既存方式を使用。

## Play

- 隔離Studio Storeで既存AuraService.EquipAura / UnequipAuraとAuraCharacterEffects.Syncを使用。一時的にPinkのRuntime VisualTemplateだけを切替。3種類ともPlayerとTreadmillのEffect数は各1。Particle数は5 / 24 / 4。
- SecretでUnequip後0、再Equip後1、実Player Respawn後1。Syncを5回呼んでも1組。TreadmillVisualService.Applyも各Templateで5回繰り返して1組を維持。
- SecretのPlayer表示とGreenのTreadmill表示をPlay画面で確認。Treadmillの通常Configを変更せず、テスト用名で既存Applyへ一時設定を渡した。
- 一時割当を復元して両Effect0を確認。QA Scriptを削除し、DataStoreConfigの一時接続先を元のSourceへ完全復元。最終通常PlayにはQA Objectなし。
- Runtime Error / Infinite Yieldは最終通常Playで観測なし。既存Treadmill設定が未登録Green_Aura1を参照する警告が2行出る。今回対象のGreen_Aura2とは別で、指示範囲外のConfig修正は行っていない。
- 復元後の監査で既存全Scriptの指紋、3元素材のVisual指紋、既存全TemplateのVisual指紋は変更前と一致。差分は追加6Templateのみ。Balance、購入、VIP/Secret Pack、Training、Combat、DataStore Schema変更なし。

## Git停止状態

実RepositoryはC:\Users\kouji\Smash_and_Crush、.gitも同直下。rev-parse --show-toplevel確認済み。branch main、origin https://github.com/koujiyoshimura54-crypto/Smash_and_Crush.git。

開始時・実装後のHEADとローカルorigin/mainは8dfeed43221d4b749534e783e8a79203b24b877c、GitHub mainは538653ea55aaa6a9762608b03089a876a6a29dd8。5コミット未同期。開始時working tree clean。前の「まだpullしない」という指示を維持し、同期・Commit・Pushを停止。新規init/clone、reset、force、旧フォルダ整理は未実施。

Template実体は現在のStudio Edit DataModelに保持している。GitへTemplate assetを保存済みとは扱わない。この1ファイルだけが今回のローカル検証記録。Publishは行っていない。
