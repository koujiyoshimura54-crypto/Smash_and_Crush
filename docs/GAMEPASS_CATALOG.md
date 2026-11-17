# Game Pass最新記録（2026-11-17）

根拠はユーザー提供 `C:\Users\kouji\Downloads\Roblox_GamePass_Phases_20261117.md` 全文と、同文書に記されたCreator Hub画像3枚（083409 / 083416 / 085627）。画面価格・管理された価格設定についてはこの記録を最新として扱う。画像そのものの再照合、販売価格の変更、Pass新規作成は今回行っていない。

| Creator Hub名 | Pass ID | 画面価格（Robux） | 管理された価格設定 | 現在の扱い |
|---|---:|---:|---|---|
| Strength×2 | 2089895831 | 3 | 有効 | Phase1：歩行・Treadmillの倍率へ＋1。購入UIはPhase2 |
| World 2 Premium Aura | 2045204630 | 99 | 有効 | 既存 |
| World 2 Premium Treadmill | 2044250678 | 399 | 有効 | Phase1：設備35→15倍 |
| 3WinIcon | 2005353724 | 149 | 有効 | 既存Win×3 |
| Slap Pass | 1987256653 | 300 | 有効 | 既存設定では購入Prompt非表示。所有・効果の今回実Playは未確認 |
| Administrator Treadmill | 1982996954 | 499 | 有効 | Phase1：World1設備20→7倍 |
| Speed_premium | 1979583273 | 99 | 有効 | 既存。速度イベント対象外 |
| RedAura | 1975173075 | 99 | 有効 | 既存 |
| Teleporter | 1976630274 | 79 | 有効 | ゲーム内効果・表示は未確認 |
| VIP | 1977128286 | 399 | 有効 | 既存 |
| Starter Pack | 1976228285 | 129 | 有効 | 既存 |
| Secret Pack | 1977086287 | 99 | 有効 | 既存 |
| 2WinIcon | 1970515086 | 15 | 有効 | 既存Win×2。UI統一はPhase2 |

全13件の管理された価格設定が有効という記録であり、全地域・全Playerの同一価格や、全商品のゲーム内実装完了を意味しない。過去の「価格未確認」はこの画面記録で更新する。古い日付の監査・測定報告は当時の証拠として保持する。

`SpeedConfig.Premium.FallbackPrice=100`、`World2GameplayConfig.Auras[6].BasePrice=299` は代替／参照値であり、今回の画面価格99ではない。既存12商品の販売価格やこれらの代替値は変更していない。Phase2で実際の購入対象価格を動的取得する方針。

今回の対象は副本 PlaceId `126576845524886` / UniverseId `10765181857`。実装・式・検証範囲は[Phase1報告](../reports/GamePassPhase1_20261117/REPORT.md)。新規購入カード、報酬ボタン移動、無料Treadmillイベントは未実装。
