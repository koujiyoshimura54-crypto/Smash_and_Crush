# World1 Stage6〜10 — Wall .4 / Boss間隔・視認性

作業日：2026-09-15  
対象：+1 スマッシュ&クラッシュ / PlaceId 101572058398926

## 結果と未達条件

**間隔調整は実施済み。EnemySpawnをStage別に後退させ、Boss Scale・各判定サイズ・床寸法を維持した。歩行による戦闘開始、離脱、再接近、撃破、Boss HP UI追従、RewardPad非干渉をPlayで確認した。**

**視認性は部分達成に留まる。高めのカメラではBoss上部を確認できるが、Wall .4直前の低い視点では引き続き大きく遮蔽される。特にStage6/7は主要部の露出が不足し、Stage8/9も低視点では頭頂のみ。これを「全条件完了」とは報告しない。**

後退だけでは低視点の遮蔽を改善できず、Stage9等では見える部分が減る。Wallの高さ27・幅88、Boss Scale、床奥行きを今回維持した結果である。Map拡張やWall形状/UIの変更は実施していない。十分な視認性を次に求める場合は、Wall .4の高さ・形状等を変更範囲に含める判断が必要。

## 位置・距離の結果

単位stud。進行方向は+Z。Wall後面=maxZ、Boss Collider前面=minZ。回転したColliderは8頂点をworldへ変換してZ方向の範囲を測定した。斜め箱の中心線上の交点までの距離とは異なる。

| Stage | 変更前Spawn Z | 変更後Spawn Z | 移動+Z | Collider前面まで：前 | 後 | 視認性 | 床内 | Pad干渉 |
|---|---:|---:|---:|---:|---:|---|---|---|
| 6 | 361.54 | 365.54 | 4.00 | 11.00 | 15.00 | 上方：キウイ上部。低視点：ほぼ遮蔽 | ○ | なし |
| 7 | 459.64 | 463.14 | 3.50 | 7.45 | 10.95 | 上方：頭上・突起。低視点：ほぼ遮蔽 | ○ | なし |
| 8 | 552.74 | 555.99 | 3.25 | 7.00 | 10.25 | 上方：顔を認識。低視点：頭頂のみ | ○ | なし |
| 9 | 630.84 | 636.84 | 6.00 | 9.00 | 15.00 | 上方：主要上半身。低視点：頭頂のみ | ○ | なし |
| 10 | 714.94 | 715.94 | 1.00 | 7.14 | 8.14 | 上方：頭・翼。低視点：炎・上端中心 | ○ | なし |

| Stage | Wall .4中心XYZ | Wall後面Z | 見た目BBox前面まで：前 | 後 | 変更後Boss Root XYZ | 実床後端Z | 後端最小余白 |
|---|---|---:|---:|---:|---|---:|---:|
| 6 | 27.92, 15.50, 333.94 | 334.54 | 9.90 | 13.90 | 27.92, 6.00, 365.54 | 388.54 | 1.00 |
| 7 | 27.92, 15.50, 428.04 | 428.64 | 6.62 | 10.12 | 27.92, 6.00, 463.14 | 490.64 | 1.22 |
| 8 | 27.92, 15.50, 530.14 | 530.74 | 4.47 | 7.72 | 27.92, 6.00, 555.99 | 574.74 | 1.22 |
| 9 | 27.92, 15.50, 614.24 | 614.84 | 7.52 | 13.52 | 27.92, 6.00, 636.84 | 646.84 | 1.00 |
| 10 | 27.92, 15.50, 686.34 | 686.94 | 2.17 | 3.17 | 27.92, 6.00, 715.94 | 742.94 | 1.17 |

見た目前面はGetBoundingBoxの近似。翼・尾等の突出も含む。半透明Particleの全到達範囲を含む衝突領域ではない。Stage10の炎が画像上で広く見えることと、物理Colliderのはみ出しは別に扱う。

Wall .4位置・大きさは全Stageで不変。EnemySpawnのX/Y/回転も不変で、Stageの相対+Zだけ移動した。

## Boss Areaの解釈と移動量の選定

物理的な支持床は各Major Stage直下のFloor。Boss AreaとしてWall .4後面からその床後端までの範囲を使用した。StageN.5.Floorは奥行5.6の旧小床であり、RewardPadの相対配置基準として残っている。大型Bossの全領域をこの小床だけで判定しない。

| Stage | Boss Area奥行き（Wall後面〜実床後端） | 移動前の後端最小余白 | 採用移動量 | 変更後の後端最小余白 |
|---|---:|---:|---:|---:|
| 6 | 54.00 | 5.00 | 4.00 | 1.00 |
| 7 | 62.00 | 4.72 | 3.50 | 1.22 |
| 8 | 44.00 | 4.47 | 3.25 | 1.22 |
| 9 | 32.00 | 7.00 | 6.00 | 1.00 |
| 10 | 56.00 | 2.17 | 1.00 | 1.17 |

Visual BBox・MiniBossCollider・CombatZoneのうち最も後ろへ達するものから、約1stud以上を残した。Stage10は元から後方余白が約2.17studしかなく、1studの後退に留めた。全Stageを一律にずらしていない。床・Mapの拡張はしていない。

## Scale維持のために必要だった参照修正

EnemyManager.attachStaticStageVisualは、EnemySpawn由来Rootから床終端までの距離を使って表示倍率を制限していた。Spawnだけ後退させると見た目が自動縮小する可能性があり、ユーザーの「Scale変更禁止」と両立しない。

そこで**表示倍率算出の基準点だけを、既存StageN.5.Floorの中心に固定**した。位置の生成は引き続きEnemySpawnから行う。固定World座標、Stage別サイズ、倍率定数はScriptへ追加していない。対象関数のStatic BossはStage6〜10。

| Stage | 実行時GetScale（前後同値） | 見た目GetBoundingBox Size（前後同値、約） |
|---|---:|---|
| 6 | 8.568842888 | 17.89 × 32.56 × 34.19 |
| 7 | 10.101541519 | 45.09 × 48.40 × 48.76 |
| 8 | 11.363371849 | 45.45 × 49.73 × 35.06 |
| 9 | 11.657335281 | 34.78 × 56.04 × 16.96 |
| 10 | 4.441483974 | 56.27 × 52.15 × 51.67 |

DisplayHeight36 / 48 / 44 / 56 / 52も維持。移動前後の実Scale完全一致を確認した。将来床基準位置を動かす作業では、この表示倍率算出基準への影響も監査すること。

## Collider / CombatZone / RewardPad

| Stage | CollisionReference / MiniBossCollider Size | CombatZone Size | Pad Hitbox位置XYZ | 見た目BBoxとのX方向余白 |
|---|---|---|---|---:|
| 6 | 18.00 × 34.00 × 36.00 | 22.00 × 14.00 × 40.00 | -6.28, 2.58, 361.54 | 21.26 |
| 7 | 18.00 × 44.00 × 44.00 | 22.00 × 14.00 × 48.00 | -6.28, 2.58, 459.64 | 7.23 |
| 8 | 32.00 × 44.00 × 30.00 | 36.00 × 14.00 × 34.00 | -6.28, 2.58, 552.74 | 8.00 |
| 9 | 28.00 × 52.00 × 14.00 | 32.00 × 14.00 × 18.00 | -6.28, 2.58, 630.84 | 12.81 |
| 10 | 28.00 × 46.00 × 32.00 | 32.00 × 14.00 × 36.00 | -6.28, 2.58, 714.94 | 2.07 |

CollisionReferenceはTemplate内のローカルCFrame/Sizeを維持。RuntimeのMiniBossColliderはRootへWeldされ、CombatZoneは従来の生成処理で同じ移動量だけ追従した。床上面Y=2とCollider/Zone底面の対応も維持した。

RewardPadはStageN.5.Floorを基準とする従来の左寄せ配置のまま。EnemySpawnを動かしてもPad位置は変わらない。実際の撃破後に生成されたHitboxについて、Collider/CombatZoneとのOBB非交差を確認した。見た目全体のBBoxともX方向で分離している。

## Play確認

一時検証コードだけでPlayerを移動・観測し、Wall/Bossダメージは既存EnemyManagerの自動戦闘で発生させた。Wall .4からBossへの区間はクライアント所有の実Playerを歩かせた。ダメージ関数を検証コードから直接呼んで突破していない。

| Stage | Wall1〜4攻撃数 | Boss開始HP | 歩行接近・開始 | 離脱・再接近 | 撃破 | Pad非干渉 |
|---|---:|---:|---|---|---|---|
| 6 | 12 | 40,500 | ○ | ○ | ○ | ○ |
| 7 | 12 | 112,500 | ○ | ○ | ○ | ○ |
| 8 | 12 | 270,000 | ○ | ○ | ○ | ○ |
| 9 | 12 | 585,000 | ○ | ○ | ○ | ○ |
| 10 | 12 | 1,125,000 | ○ | ○ | ○ | ○ |

- 全StageでWall1〜4は12攻撃。Wall4からBossへのCarryで開始HPは90%となり、現行の挙動を再確認。
- 各Stageの開始時にRequiredStrengthを設定しGloveを外したが、実歩行中は既存の歩行Strength獲得が続く。**Boss開始Strengthを固定した純粋なHit設計試験ではない**。Stage6のBossは今回は4攻撃、他は5攻撃だった。HPやCarryをこれに合わせて変更していない。
- Stage10撃破でWorldComplete=true。
- Padは取得せず、生成位置と非交差を確認。今回のテストをWorld2解放/Pad取得機能の新しい検証とはしない。
- 通常のWall/Boss UIを84攻撃イベントで観測。Wall60件はWallバーのみ、Boss24件はBoss Gaugeのみ。Boss名・Stage・HP数値を確認し、BBox上端追従誤差は最大約0.000002stud。
- UIサイズ、デザイン、HP書式、Wall HP UIのScriptは変更していない。
- 検証Playerのデータ・属性・位置を戻し、Strength/Winの復元を確認。一時的な保存ロックは解除済み。DataStoreの実装・Schemaは変更していない。

根拠：[play_results.json](play_results.json)、[client_ui_results.json](client_ui_results.json)、[scope_comparison.json](scope_comparison.json)。

### 視認性テストの条件

Viewport1010×572、FOV70、PlayerをWall中心から7stud手前へ配置。比較用のカメラ操作だけ行い、製品のカメラScript/UIは変更していない。

- 低い比較視点：Rootから(0,+9,-16)、注視点Root+(0,+7,+18)。Before/Afterを同条件で比較。
- 高めの確認視点：Rootから(0,+28,-18)、注視点Root+(0,+12,+24)。Afterの見え方を追加確認。Before高視点画像は取得していないため、高視点の改善率は主張しない。

[比較ギャラリー](preview_gallery.html)に15枚を保存。低視点でWallによる遮蔽が大きい点を隠さず残す。特定の高い視点で見えるだけで、全カメラ角度で目標達成とは判断しない。

### テスト途中の修正

最初の補助コード挿入はexecute_luauのCapabilities制限で失敗し、専用multi_editツールで一時Scriptを作成した。次に補助コードのAnchored状態でのNetwork Ownership変更を修正した。

初期のサーバー所有Player移動では、個人用の壁通過判定がクライアントで切り替わる仕様と合わず、Stage7で壁に止まった。また、再接近時にTrigger外縁で移動を停止すると向きが変わり、検証がTimeoutした。これらは検証補助コードを修正し、通常のPlayer側歩行とColliderによる停止で再実測した。製品の壁通過・Carry・Combat処理を変更して回避したものではない。上の表は修正後の最終結果。

## 変更・保護範囲

恒久的なStudio編集は次の6対象のみ。

1. Workspace.GeneratedMap.BattleCorridor.Stage06.Stage6.5.EnemySpawn — +4stud
2. Workspace.GeneratedMap.BattleCorridor.Stage07.Stage7.5.EnemySpawn — +3.5stud
3. Workspace.GeneratedMap.BattleCorridor.Stage08.Stage8.5.EnemySpawn — +3.25stud
4. Workspace.GeneratedMap.BattleCorridor.Stage09.Stage9.5.EnemySpawn — +6stud
5. Workspace.GeneratedMap.BattleCorridor.Stage10.Stage10.5.EnemySpawn — +1stud
6. ServerScriptService.World.EnemyManager — Static表示倍率の参照点を既存Boss Area Floorへ変更して実Scale維持

全383 Scriptで差分はEnemyManagerの上記箇所のみ。Map全2025 Instanceの指紋は、5 SpawnのCFrameだけを監査時の値として比較すれば変更前と一致した。元値を実シーンへ戻す操作ではなく、比較用レコード内だけで正規化した。

**変更なし：** Wall位置/Size/HP、Boss HP/RequiredStrength/RecommendedLevel、Wall1→2→3→4→Boss Carry、DisplayHeight、実Boss Scale、CollisionReference、Collider/CombatZone Size、UI、Reward、Stage Skip、Stage1〜5、World2Map/Gate/Config、Mapサイズ、DataStoreコード、Game Pass、Rebirth。

28 Scope中、恒久差分は許可されたSpawn変更を含むFullMapのみ。他の27 Scopeは一致。指紋は32bit DJB2方式の監査用照合で、未取得の全プロパティを暗号学的に保証するものではない。

## Runtime / 終了状態

一時Server Script / LocalScriptを除去した通常Playを86秒以上観測し、Consoleは空。

- Runtime Error：0
- Warning：0
- Infinite Yield：0
- 検証用Script：Editデータから除去済み
- Studio：Play停止、Editへ復帰
- Publish / Git Commit：未実施

[runtime_final.json](runtime_final.json)に記録。World2作業へは進んでいない。

## 保存物

- build_report.md — 本報告
- final_spacing.csv — Stage別位置・距離・視認性判定
- before_positions.json / after_positions.json — Wall、Spawn、Root、Template Reference、Runtime Collider、Zone、Visual BBox、Floor
- before_sources/ / after_sources/ — 参照・変更したSource記録
- before_fingerprint.json / after_fingerprint.json / scope_comparison.json — 変更範囲照合
- play_results.json / client_ui_results.json / runtime_final.json — 最終Play証拠
- screenshots/ / preview_gallery.html — 低視点の前後比較と高め視点の確認
- scripts/ — 削除済み一時検証コードの保存コピー

## 次の判断

この範囲の作業はここで停止する。距離は確保したが、低視点のBoss存在感という要件は残っている。次回それを解決する場合は、Wall .4の高さ/形状等を含む別の限定作業として検討する。今回のCarry・Balance・床サイズ維持とは分けて判断する。

