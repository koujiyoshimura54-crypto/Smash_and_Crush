# World2 Treadmill 最大Body時の加算停止 — 2026-11-13

## 結果と適用範囲

**隔離Playで確認した停止条件を、TrainingManagerのWorld2 R15占有判定だけで修正した。** 最大Bodyの代替Rigで、クライアントはRunning／Plastic、サーバーはFallingDown／Airのまま、同じ台に静止している状態を再現した。旧判定はFloorMaterialで拒否し、生Strengthの加算が0回になった。台の支持面を確認する判定では、同じCharacter・位置・資格のまま4.215秒で8回、合計40増加した。

**ユーザーが報告したアバターそのものの原因・解消は未確認。** 通常の `LoadCharacterWithHumanoidDescriptionAsync` と自然歩行・その場での最大化では、今回の代替アバターは修正前から正常だった。生成Rigでの再現と通常アバター読込の結果を区別し、全アバターで解消したとはしない。

- 基準main: `d19a25f5b86971073fac834e60fd50164ec684be`。開始時にfetch、作業用worktreeを分離。
- 正本: Place126576845524886 / Universe10765181857。開始時Edit、読み込まれたPlaceVersion621。公開V1321の現在Sourceを確認したものではない。
- 対象TrainingManagerと直前のTrophyガイド修正は開始時Studio／main一致。未保存Studioを基準に差分だけを適用する。
- [前回の調査](../EquipmentContactInvestigation_20261113/REPORT.md)を引き継ぐ。以前の63点静的Raycastを今回の実Play証拠に流用しない。
- 詳細値・時系列: [Evidence.json](Evidence.json)、[追加検証](FinalEvidence.json)。

## 変更Full Path

| Full Path | 変更理由 |
|---|---|
| `ServerScriptService.Services.TrainingManager` / [Source](../../src/ServerScriptService/Services/TrainingManager.luau#L215) | World2 R15を、アニメーション中の足裏やサーバーFloorMaterialだけに依存せず、実際の台への支持面で判定。その他のWorld、R6、資格・セッション・加算経路を維持 |

製品Sourceの変更はこの1本だけ。TrainingController、TreadmillRunClient、MuscleCharacterService、MuscleScaleConfig、StrengthManager、LV曲線、Treadmill倍率、0.5秒周期、再生条件、装備効果、HP、ショップ、WinTrophy、TutorialGuideClientは変更しない。Trophyガイドの完了属性による停止修正を保持する。

### 新しいWorld2 R15条件

既存の生存条件とRootのArea内X/Z条件に加え、次をすべて要求する。

1. Jump要求中、Jumping、Freefallではない。
2. Rootの上下速度の絶対値が1 stud/s以下。離床・落下・着地の揺れでは停止する。
3. Rootから下へ `HipHeight + Root.Size.Y/2 + Area.Size.Y/2` までRaycastする。現在のCharacterを除外し、CanCollideを尊重する。
4. 命中先は**その台自身**の子孫で、上向きの支持面（Normal.Y > 0.5）、Area上端以下。
5. 命中距離は想定立位高さの±Area半高内。現在のWorld2 Area半高は0.4 studsで、範囲を無条件に広げない。

Airを無条件に許可する変更ではない。実際の支持面、同じ設備、有限の高さ、移動状態を検査する。ジャンプ頂点もRaycastの到達範囲外になる。猶予タイマー、停止後の保留加算、tick補完、新しい待機は追加していない。正当な停止では既存セッションを破棄し、再入場は従来どおり0.5秒待つ。

World1のR15実足裏判定、R6のRoot／HipHeight判定は維持する。購入、再生回数、World、データ読込の資格判定は既存CanUseTreadmillをそのまま使う。

## 再現した停止箇所

代表例はPublicBody1の最大倍率3.55、HipHeight7.092992、Root Size2×2×1、World2台01。利用資格はtrue、Root水平条件はtrue、Root位置Y11.502935、支持面Y3.409689。Raycast長8.492992に対し、実際の立位誤差は約0.000255 studsだった。

左右足裏はArea中心より約1.07／1.26 studs上で、半高0.4を外れる。サーバーFloorMaterialがAirのため、旧コードは**有効な支持面Raycastへ進む前にfalse**となった。クライアントでは同じCharacterがRunning／Plastic、上下速度ほぼ0。RootはそのPlayerのnetwork ownershipだった。

下表は最終版と、通常ロード相当の衝突属性（Foot.CanCollide=false等）に揃えた代替Rigの測定。初期案の別比較はEvidence.jsonへ残し、最終版の比較はFinalEvidence.jsonに記録した。

| 観測 | 修正前 | 修正案 |
|---|---:|---:|
| 同一Character・同一位置、実StrengthManager＋メモリ保存、観測時間 | 4.201秒 | 4.215秒 |
| AddStrength呼出 | 0 | 8 |
| 生Strength | 25 → 25 | 25 → 65 |
| 1回の増分 | なし | 5 |
| セッション状態 | 停止 | 継続 |
| サーバーFloorMaterial | Air | Air |
| クライアントFloorMaterial | Plastic | Plastic |

この代表例は「占有が常時false」だった。前回候補の「瞬断→0.5秒待ち直し」だけが原因と決めつけない。探索中には短い開始・停止と加算0の例もあったが、恒久的な待ち時間変更は不要だった。HUDの丸めを原因としていない。

初期案のジャンプ確認で、位置・速度の複製より先にJumping／Freefallが届く短い区間を観測したため、最終版ではその状態を明示的に除外した。初期案の測定と最終版の測定はEvidence内で別ラベルにしている。

## 隔離環境と検証の区分

ローカルの別Studio（PlaceId0 / UniverseId0）を自分で起動。正本のPlayや起動処理には触れていない。Roblox付属の空に近いローカルテンプレートを開き、元からScriptがないことを確認して、メモリ内で最小環境を構成した。Placeファイルの書込み・Save／Publishはない。

- 実際のWorld2全7台とWorld1 Normal01をSerializationServiceで読み取り、別Studioへ複製。Area、衝突部品、位置・寸法・タグを使用。
- 現行TrainingManager、TrainingController、MuscleCharacterService、MuscleScaleConfig、TreadmillRunClientを使用。
- 本番StrengthManagerとStrengthCalculation、RebirthConfigを実行。PlayerDataのコミットはメモリのみ。装備・Pet・Potion・VIPは加算0／倍率1、所有・読込は検証用依存。公開DataStore・購入API・Analytics送信は呼ばない。
- Lobby配置は最小の支持面リフトへ置換。実サービス同様に現在Characterを保持し、身体成長の元寸法の寿命を維持する。成長倍率・Part/Motor変換は本番Source。
- 強制配置した初期比較は「自然入場」と呼ばない。別途、Humanoidの通常歩行、クライアントのJump、成長属性変更を使用。
- 使用Rig: Default、TallNarrow（Height1.05 / Width・Depth0.7 / BodyType・Proportion1）、ShortWide（Height0.9）、公開Bodyアセット構成PublicBody1。体型情報はEvidence参照。
- 生成RigのFoot.CanCollideと通常ロード時の差も記録し、通常ロードの衝突属性に揃えた代替Rigを追加比較した。

これは**Robloxの物理を動かした最小隔離Play**であり、ゲーム全体の通常プレイ／実機／公開環境での合格ではない。保存・購入依存は模擬。実アカウントの保存、実課金、実機タップ、Creator Hub受信は実施していない。

## 検証結果

| 確認項目 | 結果 |
|---|---|
| 基本・最大直前・最大 | 高さ1／3.25／3.55、4体型のWorld1・World2比較を実施。初期案では24ケースすべて2.1秒で4tick。最終版のWorld2も4体型×3段階の12ケースが各4tick・＋20 |
| World1比較 | 同じ体型・成長段階・装備なしで12ケース各4tick、＋4。元の判定コードを維持 |
| World2全7台 | 最終版で各4.2秒・8tick。下表どおり。セッション開始から計測 |
| 歩いて入場 | 台外から自然歩行で01へ入り、加算開始。最大Bodyでの再入場も確認 |
| その場で最大化 | 生存した同じCharacterを高さ1から3.55へ。配置の短い揺れでは停止、再接地後0.5秒から再開。成長倍率は変更なし |
| 中央・縁 | 最終版の縁はRoot localX=4.473755、Area半幅4.497184。支持面ありで継続。縁から歩いて退出後は0加算 |
| ジャンプ | 最終版で開始タイミング0.1／0.3／0.45秒の3ケース。Jumping／Freefallで占有成立0、空中AddStrength0。各1.6秒の最後の1tickは再接地・再開始から0.5秒後 |
| 退出・死亡・World不一致・未読込 | 対象区間のAddStrength0 |
| 再生資格／Premium所有喪失 | 台03のRebirth7→6、台07の所有falseでAddStrength0。実課金なし |
| 隣の台 | 01→02を歩行。01停止→間の床→02開始。01の区域判定ではfalse、02としてのみ加算。二重セッションなし |
| 加速・重複 | 短い歩行出入り6往復で開始・停止15回、加算0、最後の退出後2.1秒も0。記録した連続tickの間隔は0.5秒以上。任意の観測窓は位相により4.2秒で9tickを含み得るため、設備比較は新セッション開始から統一 |
| アニメーション | Training成立時に専用913376220 Trackが再生。初回再現の停止中は専用Trackなし。属性を基準とする現行Clientを維持 |
| 通常アバター読込＋自然入場 | 基本サイズは2.1秒＋20、最大化後は修正前4.2秒＋40、修正後4.2秒＋40。この経路では不具合未再現 |

| World2台 | 台倍率 | 検証Rebirth回数 | 既存Rebirth倍率 | 1tick | 8tick実測 |
|---|---:|---:|---:|---:|---:|
| 01 / 02 | 5 | 0 | 1 | 5 | 40 / 40 |
| 03 / 04 | 7 | 7 | 4.5 | 31.5 | 252 / 252 |
| 05 / 06 | 12 | 9 | 5.5 | 66 | 528 / 528 |
| 07 | 35 | 0 | 1 | 35 | 280 |

原始時系列にはRoot、足裏、Area高さ、接地面、FloorMaterial、Raycast長・命中先・命中Y、資格、Training属性、開始停止、AddStrength引数／戻り値／生Strengthを含む。最終ジャンプでは各加算時のHumanoid状態・速度も記録。[Verification.json](Verification.json)の23項目は記録の整合と変更範囲の検算であり、追加の実Play23回ではない。

## ログ・清掃・保存状態

隔離補助の構築途中に、サーバーからPlayerScriptsを参照した診断コードのエラーが1件あった。Client側へ移した。最小環境にStrengthGainの表示側購読がなかったためRemote queue warningが発生し、表示用の受信先を追加した。どちらも製品TrainingManagerのエラーではなく、修正と記録を行った。これらを「ログは最初から無警告」として扱わない。

最終コンソールに上記以外のRuntime Error／Warning／Infinite Yieldの追加はなかった。自分の隔離Playを停止し、Editに残る11個の検証用コンテナ・Script・部品を除去、残存LuaSourceContainer=0を確認。プロセス終了は一度自動審査で拒否されたが、起動引数・テンプレートパス・空のDataModelを確認したうえで、検証用Studioと未開場の起動プロセスだけを終了した。正本は起動したままEditを保持。

正本の関連13 Source／Editorを照合し、TrainingManagerのみ今回の差分、残り12本は開始時と一致。検証補助は正本へ追加していない。[清掃・設備寸法・照合](CleanupAndGeometry.json)。Studioは**未保存**、Save／Publish・保存GUI・Placeファイル書込みなし。公開DataStore変更、reset、実課金なし。

今回のSource、報告書、必要なSPEC／DEV_STATUS／CHANGELOGだけをcommit対象とし、origin/mainへ通常pushする。force pushなし、PR #1はopen / draft / merged=falseのまま。確定commitとpush結果は最終回答に記載する。

## 未確認と限界

- ユーザー報告のアバター構成、実際の公開サーバーでの失敗時系列、同アバターでの修正後確認。
- 生成Rigでは最大直前にも同じ拒否を観測した。「特定アバターの最大時のみ」という公開事象の全条件を再現したものではない。
- 通常ロードでは未再現のため、公開事象の原因を今回のサーバー接地情報の不一致と断定しない。
- 自然な通信遅延／パケット欠落、高負荷・多数Player、実機、公開後の継続動作。
- 最小環境の歩行速度・装備・保存は全ゲームの進行検証と同一ではない。通常ロードの成功と、生成Rigの再現を混同しない。
- Save／Publishを行わないため、公開版へ反映・公開受信された証拠はない。
