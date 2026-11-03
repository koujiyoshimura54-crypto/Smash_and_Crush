# Pet equipment, acquisition history and scoped UI — 2026-11-03

## Authority and scope

Applied minimal Source edits to the current unsaved canonical Studio, PlaceId 126576845524886 / UniverseId 10765181857. No place/file replacement, Save, Publish, rbxl write, OS input, camera setting, window layout or device-preview change. Unrelated Item set/Best Equip, Boss contact, audio, reward/receipt and tutorial work was retained. Japanese fallback font work remains deferred.

## Changed Full Paths

| Full Path | Change |
|---|---|
| ReplicatedStorage.Modules.Pet | Three distinct owned-copy slots; additive Strength multiplier; single-Pet multiplier text; durable species discovery; coherent follower identity snapshot. |
| ServerScriptService.Services.PlayerDataService | Advance the existing Pet view generation on reset so revision zero replaces the previous client state and old responses cannot restore it. |
| StarterPlayer.StarterPlayerScripts.Services.PetClient | 0/3–3/3 plus total multiplier; full-slot explanation; accepted-state event for candidate refresh. |
| StarterPlayer.StarterPlayerScripts.Services.PetFollowClient | Three existing models; strongest at rear center, others left/right; stable slot tie-break and individual identity. Existing movement/bob/turn values retained. |
| StarterPlayer.StarterPlayerScripts.Services.EggClient | Normal W1/W2 candidates use saved species discovery; alpha-preserving black images/model renders; refresh open candidates on accepted Pet state. |
| ReplicatedStorage.Modules.LimitedPetViewport | Opt-in host silhouette tint, including remount/visibility changes. Other hosts and Limited candidates retain white tint. |
| ReplicatedStorage.Modules.MergeShopView | Item list/input/candidate/completed-result points and selected total from ItemMergeConfig.GetPoints; existing formatter. Inventory stars and Merge ordering/rules untouched. |
| StarterPlayer.StarterPlayerScripts.UI.EnemyDropGachaClient | Ore per-unit points beside its icon; no Ore/Item quantity caption; Item gets no points. |
| StarterPlayer.StarterPlayerScripts.UI.ItemEffectHUDClient | Equipped Item ID selects each image; set caption uses StrengthHUDPresentation / StrengthHUDStyle font and outline at refresh. |

Shop code and button geometry were **not changed**: the reported narrow clone could not be reproduced in this live baseline. Existing normal and narrow prices/icons remained readable.

## Persistence and calculation

- Existing Version=1 Pet data, owned individual IDs, valid equipment, revision, protected flags and transaction records are retained. Missing slots become empty; duplicate equipped references are normalized once without deleting owned copies.
- Clicking an equipped copy keeps the existing unequip action; an unequipped copy fills the first empty slot. At three, the server returns PetSlotsFull. The existing explicit unequip-then-equip route performs replacement; no automatic weakest replacement or auto-equip was added.
- Pet.StrengthMultiplier is now 1 + sum(StrengthPercent)/100. Existing PetServer consumers in StrengthManager and StrengthReference therefore receive the same value. Fixed paid quantities, offline rewards and receipt journals are never recalculated.
- Discovered is a saved species-ID map under Pets. Ownership and validated saved LastResults provide migration evidence; successful Hatch/Merge results add history in the existing durable operation. Consuming a copy never removes history. Visual/model aliases are not keys: Dog and W2 Dog remain distinct.
- Existing data has no complete historical normal-Pet acquisition ledger beyond these confirmed records. Already-lost species without evidence remain undiscovered; no unlocks were guessed.
- Reset uses existing defaults and persistence. Found and corrected an existing client revision problem: after a reset, revision zero was rejected against the old inventory. Advancing PetViewGeneration makes reset authoritative and rejects pre-reset requests.

## Verification actually performed

All stores, badges and Marketplace dependencies were substituted by temporary in-memory/test implementations before native Play. Both Studio and production-named reset handles pointed to that memory provider. No real purchase or persistent user-data write occurred. The real debug command logs its normal “Production reset” wording; that wording is **not** evidence of a production write in this test.

| Area | Evidence |
|---|---|
| Shop | Native first/open/reopen and isolated 540px available-width checks over 69 purchase visuals. Visible narrow visuals stayed at least 95.96px wide; price TextFits passed. Normal cloned visuals were about 160–173px wide. Captured normal Shop pixels. The authored inactive Teleporter is 0x0 and excluded from visible-width checks. One actual Win purchase callback bought NORMAL_01 exactly once: Win 100,000,000 → 99,999,995; ownership 1. |
| Merge Item | Actual rendered material/input/candidate labels: two 9pt Items → total 18pt, candidates 9/27pt at 50% each. No Item star containers. Normal transaction from 1,500 Common copies consumed two and generated one Common: count 1,499, result 1pt at 100%, displayed ownership ×1.5K. High rank ordering retained. Pet/Ore authorities and points paths unchanged. |
| Acquisition cue | Duplicate simulated server notification produced one personal Billboard: Stone uses current OreConfig value **5pt**, not the example 10pt. No Quantity child on Ore or Item; Item has no Points child. Owner check and original two-second teardown remain. The transient world Billboard was not captured clearly; its pixels are not marked verified. |
| HUD | Native rendered Fire Protein / Ice Glove / Electric Belt used three corresponding Item images. Ice set refresh showed +45 STR / +30% DMG / +1.5 Tier and Item ×1.5. Actual multiplier label family FredokaOne, black 2px outline, TextFits true. HP/LV/packs/Auto layout retained. |
| Pet operations | 22 focused native server checks: old one-copy migration, duplicate-reference repair, 0–3 equip, same species with distinct IDs, full refusal, all three equipped-copy merge guards, explicit replacement, operation replay, normal merge, persisted discovery and JSON save/reload. Client equip requests and 0/3, 1/3, 2/3, 3/3 captions checked. Existing request cooldown was preserved; a rapid second request was rejected until its normal interval elapsed. |
| Strength | Real configured 2% + 2% + 20% yielded ×1.24; final Dog/Elephant/Crocodile equipment yielded ×1.52. A temporary isolated percent lookup supplied exactly 10/20/30: native AddStrength(10) added 16, and StrengthReference context also read 1.6. The lookup was immediately restored; no shipped individual effects changed. |
| Two clients | Real StudioTestService multiplayer run: six client follower models, three unique IDs per owner, strongest rear-center, tie order by equipped slot. World2/World1 lobby movement and death/respawn retained equipment/models. Both clients passed after a fixture barrier ensured neither reset before the other finished observing respawn. No production correction was needed for that initial test race. |
| Egg discovery | W1 Pink Bunny and W2 Dog transitioned black → normal immediately on accepted server grant, without reopening. W1 Dog ownership did not reveal W2 Dog. Grey Cat remained discovered after two copies were consumed by the normal durable Pet merge. Memory save/reload retained history including W2 Dog. Reset cleared it. |
| Egg pixels | Inspected real image/model candidate parts in an isolated screen mount: W1 colored acquired images plus black alpha silhouettes; W2 acquired model colored with other models black. Ordinary world Billboard placement was not successfully captured, so these are **isolated render checks**, not full world-sheet raster acceptance. |
| Limited | Native W1 and W2 Limited sheets were explicitly opened with price fetching disabled for the display test. Seven Viewports in each retained white tint; colored models were captured despite absent discovery. No purchase was attempted. Some existing asset authorization warnings appeared for model content; asset IDs/permissions were not changed. |
| Reset | Invoked existing StudioDebugService.Execute(player, "/resetdata") with every store isolated. Server and native client both returned empty discovery, empty equipment, 0/3 and ×1. A request with the previous Pet generation returned PetStateChanged. |

## Limits and cleanup

- No production save/rejoin, actual payment, OS pointer/touch input, device emulation or Japanese fallback-font validation.
- The two-client checks inspected actual client models/IDs/transforms, not retained two-client screenshots. Narrow checks covered Shop; no blanket all-screen/device claim.
- W1 discovery after actual merge consumption passed. W2 normal Pets remain subject to the existing merge eligibility rules; no new W2 disposal/merge rule was introduced.
- Transient Ore/Item world notification pixels and ordinary normal-Egg world Billboard placement remain unverified. Candidate content was rendered separately as described above.
- Existing Limited model content produced authorization warnings (95256658378010, 139190015780830, 82687933211372, 7221927873). Models were visible in native captures; completeness of every texture is not asserted.
- Temporary scripts, callbacks, price stubs, memory stores, percent lookup, preview state and UI mounts were removed with Play. Edit cleanup verified all 465 production Source/Enabled entries and 74 SoundIds against the pre-test manifest; no __P3QA helpers remained.
- Final nine changed live Sources compiled and matched repository UTF-8 bytes/hashes, including the complete 112,521-byte PlayerDataService.
- Screenshots were inspected temporarily and not retained, per AGENTS.md. Test fixtures are archived under tests/PetThreeAndPresentation*; they are not shipped into the place.
- Studio remains in Edit with this work and existing edits **unsaved**. The user must manually Save/Publish.
