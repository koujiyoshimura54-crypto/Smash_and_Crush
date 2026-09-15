from pathlib import Path
root=Path(r"C:\Users\kouji\Smash_and_Crush\Smash_and_Crush_updated_20260915")
link="../reports/Level_Progress_20260915/build_report.md"
def read(name): return (root/"docs"/name).read_text(encoding="utf-8-sig")
def write(name,text): (root/"docs"/name).write_text(text,encoding="utf-8")
def replace(s,a,b):
    assert a in s,a
    return s.replace(a,b,1)
s=read("GAME_SPEC.md")
s=s.replace("Version: 1.1","Version: 1.2",1)
s=replace(s,"- Levelは現在Strengthから導く値。独立XPを加算する方式ではない。Lv1〜200は各Levelの明示Threshold表（Lv1〜50は従来値維持）。Lv201以降は暫定で毎Level+250M、上限Lv10,000。StrengthをLevelアップ時に書き換えない。詳細はBALANCE_SPEC。",
"""- **Strength＝現在の成長サイクルで保持する累積戦闘力**。Level Upで消費せず、Boss/Wallは引き続きこの値を使用する。生涯ランキング用TotalStrengthEarnedとは別。
- **LevelProgress＝現在Levelで獲得したStrength進捗**。現在Requirementを消費した後の余剰を保持する。
- **LevelRequirement＝現在Levelから次Levelへ上がるための必要獲得量**。LevelRequirementsのLv1〜200の全数値とLv201以降+250Mの暫定式は変更していない。
- 最終Strength獲得量をPlayerDataService.AddStrengthGainでStrengthとLevelProgressへ同時反映する。Progressが現在Requirement以上なら順に消費し、Carry・複数Level Upへ対応。Levelを累積Strengthから再計算しない。
- Lv1の既存Requirement=0は維持。新規Join・旧データ移行・RebirthではLevelを自動加算せず、最初の正の獲得で0を消費してLv2へ進む。上限Lv10,000ではLevelを止め、StrengthとProgressは保持する。
- 旧データは保存Levelがあればそれを維持。旧仕様でLevelが保存されていない場合のみ、変更していない旧Threshold検索で従来Levelを一度復元する。LevelProgress=0から開始し、その後は独立保存する。""")
s=s.replace("Strength=0／Level=1へ戻す。","Strength=0／Level=1／LevelProgress=0へ戻す。",1)
s=replace(s,"LevelはStrengthから再計算し、CurrentStage/WorldCompleteは保存しない。","Level・LevelProgress・LevelProgressVersion=1を後方互換の追加項目として保存する。既存Strength・Win・Rebirth・Inventory・World解放は維持し、CurrentStage/WorldCompleteは保存しない。")
s += "\n## 2026-09-15 — LevelProgress方式への移行\n\n最新指示による実装変更。数値カーブ・戦闘バランス・UIデザインは維持。通常付与とTime Rewardの永続化に共通の純粋進行関数を使用し、Save中の獲得・Claim再試行・再Joinを検証した。初期監査とは別の作業記録：[実装・検証報告]("+link+")。\n"
write("GAME_SPEC.md",s)
s=read("BALANCE_SPEC.md").replace("Version: 1.2","Version: 1.3",1)
s=replace(s,"Levelは現在Strengthが到達した最大の閾値。独立XP・保存Levelは用いない。Strengthは小数を保持する。Lv1〜50の必要Strengthは次表。",
"""2026-09-15に意味を変更：以下の各値は**そのLevelから次Levelへ進むための獲得量**。累積戦闘Strengthの到達Thresholdではない。全数値を維持し、LevelとLevelProgressを独立保存する。Strength・Progressとも小数を保持する。""")
s=s.replace("明示的な整数Threshold","明示的な整数Requirement").replace("### Lv51〜200：全Threshold（暫定補間値）","### Lv51〜200：全Requirement（旧表の数値維持）")
s=replace(s,"指定アンカー間を単調3次Hermite補間で作成し、1,000単位へ四捨五入。","以下は以前のThreshold表の作成履歴であり、今回再計算はしていない。指定アンカー間を単調3次Hermite補間で作成し、1,000単位へ四捨五入。")
s=s.replace("**暫定**：`Threshold(Lv) = 5,000,000,000 + (Lv - 200) × 250,000,000`","**暫定**：`Requirement(Lv) = 5,000,000,000 + (Lv - 200) × 250,000,000`",1)
a=s.index("- Level上限=10,000。CalculateLevel")
b=s.index("\n\n| Stage | 推奨Lv | RequiredStrength | そのStrengthの実Lv",a)
s=s[:a]+"""- Level上限=10,000。LevelProgression.Advanceは現在Requirementを順に消費し、最大でも上限までの有限回で停止する。上限到達後もStrengthと余剰Progressは保持。HUDバーは従来どおり上限時100%。
- GetRequiredStrengthの値・clamp・暫定式は変更していない。通常HUDはLevelProgress / GetRequiredStrength(Level)を表示する。Lv1の0 Requirementは除算せず0%表示し、最初の正の獲得時に次Levelへ進む。
- 非有限・負のProgress/獲得量は拒否。旧データのLevel復元だけにCalculateLevelを使用し、通常進行・Rebirth判定・BossのPlayerLevel表示には使用しない。
- 保存項目はLevel、LevelProgress、LevelProgressVersion=1。旧保存Levelがない場合のみ旧Strength Thresholdから従来Levelを一度復元し、Progress=0を設定する。以後、Strengthだけの管理用絶対値変更ではLevel/Progressを変更しない。

### 旧Threshold方式での比較（履歴）
次の比較は移行前の記録。新方式では同じ累積StrengthからLevelを特定できず、推奨Levelと戦闘Strengthの到達速度は今後検証・調整する。Boss/Wall/RequiredStrength/RecommendedLevelの数値は今回は変更していない。
""" + s[b:]
s=replace(s,"根拠: [ReplicatedStorage.Config.LevelRequirements](../reports/Implementation_Audit_20260915/sources/ReplicatedStorage.Config.LevelRequirements.luau)。Stage6〜10は指定対応と完全一致。Stage1〜3の差を埋めるためのLevel式・Strength・HP修正は未承認。",
"上表は旧方式の履歴。新方式の正本はLevelProgressionと現在のLevelRequirementsであり、この比較を新規Playerの到達Level予測には使用しない。Requirementの表は変更していない。")
s=s.replace("World1MaxRebirth=5。Strengthのみ0に戻しRebirthCountを増やす。","World1MaxRebirth=5。RebirthCountを増やし、既存のStrength=0／Level=1を維持。新設LevelProgressも同じサイクルで0へ戻す。Win・Inventory・HighestUnlockedWorldは維持。")
s += "\n## 2026-09-15 — Level進行の意味変更\n\n上記200個の表値・Lv201以降の式は完全維持。通常付与の最終GainをStrength/LevelProgressに同時加算する。例：Lv60、Progress=500Kに+2.5MでLv61/Progress=0となり、Strengthは+2.5Mされたまま。複数Levelを跨ぐ場合は各Requirementを順に消費する。過去のWorld1/World2推奨Levelと旧Thresholdの一致検証は履歴として残すが、新方式の育成時間の保証ではない。Item・Training・Potion・倍率の調整は未実施。[検証報告]("+link+")。\n"
write("BALANCE_SPEC.md",s)
s=read("UI_SPEC.md").replace("Version: 1.0","Version: 1.1",1)
s=replace(s,"Strengthはサーバー属性を受けてNumberFormatで短縮表示。Levelは現在Strengthの閾値から計算する。バー比率は `(Strength - 現Level開始閾値) / (次Level閾値 - 現Level開始閾値)`。数値ラベルの現在Strength/次閾値とバーの区間内進捗は異なる。",
"""上段StrengthLevelHUD.Strengthはサーバーの累積StrengthをNumberFormatで短縮表示する。下段Levelは保存Level Attribute、数値ラベルは **LevelProgress / GetRequiredStrength(Level)**、バーは同じ比率を0〜1へclampして表示する。StrengthからLevelを逆算しない。
Strength・Level・LevelProgressのAttribute変更で更新する。Lv1 Requirement=0では0除算を避けバー0%、上限Lv10,000は従来どおりバー100%。例：累積3.5M Strength／Lv.60／500K / 3M。
UI Object、位置、サイズ、HUDLayout、Formatterの丸めは変更していない。""")
s=s.replace("RebirthでStrengthが0になるとLevel1・対応バーへ更新。","RebirthでStrength=0・Level=1・LevelProgress=0となり、上段0 Strength／下段0 / 0・バー0%へ更新。",1)
s += "\n2026-09-15：実PlayerのStrength獲得・Level Up・Carry・Rebirthで上記HUD表示をPlay確認。端末別デザイン変更は実施していない。[検証報告]("+link+")。\n"
write("UI_SPEC.md",s)
s=read("DEV_STATUS.md").replace("Version: 1.2","Version: 1.3",1)
s=replace(s,"## Completed","""## Completed

- 2026-09-15：Levelを累積Threshold方式から保存Level/LevelProgress方式へ変更。Requirement全数値・暫定式・戦闘バランスを維持。旧データは従来Levelを維持してProgress=0へ移行。共通付与、Carry、複数Level Up、Save中の獲得、Reward再試行、実PlayerのHUD/歩行/Training/Rebirth/専用Store再Joinを検証。[報告]("""+link+""")。
- 過去の「推奨Levelと累積Thresholdの一致」は旧方式の履歴。今後はLevelと累積戦闘Strengthが独立した状態であり、育成時間・獲得量の再バランスは別Phase。""")
s=s.replace("高Levelで進捗ラベルの現在/次閾値が両方2.5T等になる場合がある。内部値・進捗バーは正常","旧方式では現在/次閾値が同じ短縮表示になる問題もあった。新HUDはProgress/現在Requirement。小数1桁の丸め自体は維持")
s += "\n## LevelProgress移行後の注意\n\n- Lv1 Requirement=0は数値維持のため、最初の正の獲得でLv2へ進む。Join/Rebirth時点はLv1・Progress0を維持。\n- 上限10,000ではLevelは増えず、StrengthとProgressを保持する。\n- /setstrengthは管理用の累積戦闘力変更のみ。Level/Progressは逆算しない。旧テストのThreshold前提は履歴として残し、今回の新規検証と区別する。\n- Production Store名・既存保存項目は維持。新規3項目は欠損時移行し、不正/未知Versionは読込を拒否して上書きしない。旧仕様の稼働サーバーとの同時運用・本番課金は今回未検証。\n- Item/Training/Potion/VIP倍率やWorld推奨Level調整には進んでいない。\n"
write("DEV_STATUS.md",s)
s=read("CHANGELOG.md")
s += "\n## 2026-09-15 — LevelProgress方式へ移行\n\n- Strengthを累積戦闘力、LevelProgressを現在Levelの獲得進捗、Requirementを現在Level→次Levelの必要量として分離。Lv1〜200の全値とLv201以降の暫定式は維持。\n- PlayerDataServiceの共通付与でStrength/Level/Progressを同時更新。LevelProgressionを通常付与とTime Reward永続化で共有。余剰Carry・複数Level Upに対応。\n- Level/LevelProgress/LevelProgressVersion=1を後方互換追加。旧データの従来Level・Strengthを維持しProgress0から開始。Rebirthは既存Strength0/Level1にProgress0を追加。\n- HUD下段をProgress/現在Requirementへ変更。上段StrengthとUIデザイン・配置は維持。\n- 隔離テスト30,049チェック合格。実Playerで旧データ移行、獲得・HUD・Carry・複数Level Up・専用Store再Join・UI経由Rebirth・歩行・Treadmillを確認。検証用ScriptとStore切替は撤去。\n- GAME_SPEC/BALANCE_SPEC/UI_SPEC/DEV_STATUSを更新。World HP・RequiredStrength・RecommendedLevel・Item/Training/Potion/Game Pass倍率は変更なし。Publish/Commitなし。\n- 根拠：[実装・検証報告]("+link+")。\n"
write("CHANGELOG.md",s)
print("Updated GAME_SPEC, BALANCE_SPEC, UI_SPEC, DEV_STATUS, CHANGELOG")

