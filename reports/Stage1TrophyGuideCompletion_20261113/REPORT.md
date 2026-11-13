# Stage1 Trophy誘導の完了判定修正 — 2026-11-13

完了済みプレイヤーへの再誘導を修正した。正本Place **126576845524886**の現在の未保存Sourceを基準とし、開始時に取得したmain **3583c1c**と対象Source／Editorが一致することを確認してから、1行だけ変更した。

## 原因と変更

変更Full Path: **StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient:414**
[変更Source](../../src/StarterPlayer/StarterPlayerScripts/Tutorial/TutorialGuideClient.client.luau#L414)

完了時に旧案内から後続ガイドへ移る条件が `legacy and TutorialCompleted~=false` に限られていた。新対象では `phase=="Complete"`でも `stage1Defeated and trophy` があると例外的にTrophyへ進み、TrophySpawnのたびに完了済みの案内を復活させていた。新対象のReward段階でも、初回受取後のTutorialCompletedを停止条件に使えていなかった。

```diff
- if (legacy and player:GetAttribute("TutorialCompleted")~=false)
+ if player:GetAttribute("TutorialCompleted")~=false
   or phase=="Complete" and not (stage1Defeated and trophy) then
```

TutorialCompletedが**明示的にfalseのときだけ**初期のTrophy／壁／Treadmill案内へ進む。FirstBattle側がCompleteでも、初回Trophyが未受取なら既存の例外を維持する。マージ・装備・Waitingはこの条件より前の既存分岐のままであり、必要な後続ガイドは既存AllowLaterGuidesへ渡す。新規保存フラグ・DataStore移行・Boss撃破時の強制完了は追加していない。

## 検証

[テスト](../../tests/TrophyGuideCompletion.luau)は現行Sourceの `wallCleared` 以降を取り出し、**実際のrefresh、TrophySpawn等のハンドラ、属性監視、FirstBattleTutorialState**を実行する。Player・Signal・描画・Remoteはローカルのテーブルで代用する。Studio Editで実行した状態／イベントの模擬検証であり、実Playではない。実サービスのrequire、Player操作、DataStoreアクセス、補助Instance追加は行っていない。

修正前 **9/24成功・15/24失敗**、修正後 **24/24成功**。[個別結果](Evidence.json)

| 条件 | 結果 |
|---|---|
| 初戦勝利・初回Trophy未受取 | 誘導あり |
| 敗北→マージ・装備→再戦勝利、FirstBattle側Complete・TutorialCompleted=false | 誘導あり |
| 表示中の初回受取完了属性 | 即時に誘導を解除 |
| 完了済みでStage1再撃破／TrophySpawn、完了属性が先／後 | 再表示なし |
| Stage2有効攻撃相当の完了属性→後のStage1 Trophy | 誘導なし |
| 新旧プロフィールの完了属性復元、死亡復帰・World往復相当 | 再表示なし |
| 完了属性nil、壁・Treadmillへの古い案内への戻り | 誘導なし |
| 初回受取後のMerge／Equip、終了後のEgg／PetMerge／上位Ore対象 | 既存分岐・後続ガイドを維持 |
| Busy、他World、他ガイド所有、別Stage／削除済みTrophy | 既存の表示条件を維持 |
| 既存の明示的TutorialResetSequenceと未完了状態の復元 | 初期案内を再開 |

修正後SourceのLuauコンパイル、EditorとSourceの一致、予定した1行差分との完全一致を確認した。次の参照Source 5本は調査前後のバイト数と2種類のrolling hashが一致し、変更していない。

- ReplicatedStorage.Modules.FirstBattleTutorialState
- ReplicatedStorage.Modules.PersonalTrophyVisibility
- ServerScriptService.Services.TrophyRewardService
- ServerScriptService.Services.PlayerDataService
- ServerScriptService.World.EnemyManager

現行TrophyRewardService:197–198のStage1受取完了、EnemyManager:1095–1102のStage2実ダメージ確認後の完了、PlayerDataService:1195–1206の既存保存・属性更新処理を確認して維持した。Trophy本体の出現・表示・受取、Win付与、Bank／帰還には変更を加えていない。これらの実行時成功を今回再検証したとは扱わない。

## 未確認・清掃・保存状態

接続は正本Editのみで、本番データを遮断した隔離Playは確保していない。**今回の実Play、実画面の描画、実Trophy受取／Win／帰還、実Stage2攻撃、実再参加、実通信の順序・遅延、実機は未確認。** 模擬Signalのイベント順序と属性復元を、実ネットワークや本番保存の成功としない。今回の実Play Runtime Error／Warning／Infinite Yieldログも未取得。

ゲームSourceの変更は上記1本1行のみ。LV必要量＋5%、Treadmill加算、身体成長、設備接触、HP、報酬、Trophy表示復元は変更していない。診断用Instance／仮Remote／依存差替えは追加0件で、Studio内に検証補助を残していない。回帰テストはRepositoryにだけ保存した。

Studioは **Editのまま、変更は未保存**。ユーザーのPlay開始・停止・再起動、Save／Publish、保存GUI操作、Placeファイル直接書込み、PR #1のマージを行っていない。GitはSource・回帰テスト・報告／証拠・UI_SPEC／DEV_STATUS／CHANGELOGの今回分のみを通常commit／pushする。
