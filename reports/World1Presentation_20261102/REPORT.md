# World1 presentation repairs — 2026-11-02

Implemented in the currently open canonical Y02 Studio, PlaceId **126576845524886**, preserving its unsaved Edit model. Baseline Git: `1d07150`. Read the preceding [arrow audit](../OreMergeArrowAudit_20261102/REPORT.md) and [approved Merge presentation](../OreMergeTutorialDisplay_20261102/REPORT.md). No map, balance, asset, collision, camera or approved Merge presentation changes.

## 1. Treadmill carpet

Cause: the two nested walkable surfaces were absent from the floor whitelist. The lower floor was selected and the carpet became an obstruction.

Added only these exact surfaces to the existing whitelist/cache in `StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient`:

- `Workspace.GeneratedMap.TrainingArea.PathToTreadmills.ThreadmillStand.Upper`
- `Workspace.GeneratedMap.TrainingArea.PathToTreadmills.ThreadmillStand.Lower`

In native Play both were registered. The original route had 21 chevrons / 42 Parts; 24 Parts were visible. Samples 16–19 selected the stand Upper at Y=4.400015 and were visible. Samples 20–21 remained blocked by `Workspace.Treadmills.Normal01.1` / `.2`. Samples 14–15 crossing a height boundary remained excluded by the existing 0.08-stud footprint-height rule. No broad name/color matching or machine whitelist was introduced. Arrow styling, pool, scheduler and occlusion code are unchanged.

**Raster limitation:** repeated carpet captures did not return. Floor hits, actual Part transparency and renderer decisions were measured, but visible appearance before/on/across the carpet is not claimed as visually accepted. The initial trace also reported zero on-screen Parts for that camera state.

Merge regression: prepared eligible ore state navigated to Merge; actual facility proximity opened the panel (`ChooseOre`, target nil, zero floor Parts); leaving its Area returned to `GoToMerge` with 14 visible floor Parts. No start/pause/dismissal condition, highlight, dimming or notification Source/template was changed.

## 2. All ten World1 Bosses

Cause: the ten stage appearance scripts looked directly below `Workspace.Enemies`, while real actors live under `Workspace.Enemies.Owner_<UserId>`. Existing clips and rigs were present.

The new `ReplicatedStorage.Modules.World1BossPresentation` shares CombatClient's accepted revision/generation and personal visibility. It resolves only the local player's direct owner folder and checks OwnerUserId, WorldId, RunRevision and SpawnGeneration. A shared 0.25-second retry handles partial replication, attributes and late children. Each stage keeps its existing animation, float, weld and VFX implementation. Old tracks/connections are released when their accepted actor disappears or becomes hidden/dead/out of World1. Stage10 restores the captured emitter rate on release so reattachment cannot accumulate attenuation.

CombatClient's existing packet owner/world/revision/sequence fence remains authoritative. World1 defeat/clear/attack notifications include the actor generation; stale generations cannot suppress the replacement. Stage03's delayed attack also checks the captured actor before playing. World2 uses its existing path.

Native solo Play measured root-relative body motion over ten samples, excluding chase translation, and inspected time-separated screenshots:

| Stage | Visible motion inspected | Changed Bones / visible MeshParts | Playing tracks |
|---|---|---:|---:|
| 1 | Ballerina arms/body | 16 / 0 | 2 |
| 2 | Shark legs and float | 18 / 2 | 2 |
| 3 | Wooden character limbs | 0 / 15 | 2 |
| 4 | Flying crocodile propellers | 5 / 0 | 1 |
| 5 | 67 arms/body | 31 / 0 | 2 |
| 6 | Pipi Kiwi body/legs | 22 / 0 | 1 |
| 7 | Shrimp feet/body | 16 / 0 | 1 |
| 8 | Banana peel/body and float | 34 / 2 | 1 |
| 9 | Combined body/arm and attached visuals | 67 / 0 | 1 |
| 10 | Dragon wings and flame pulse | 21 / 0 | 1 |

IDs, track speeds/priorities and measured transforms are in [Evidence.json](Evidence.json). Stage03 Walk retained speed 0.6; other sampled clips retained speed 1. Tall Bosses were partly cropped by the unchanged camera; this is visible-body motion acceptance, not a full-model/all-angle inspection.

Representative lifecycle checks: Stage8 resumed after actual death/respawn, retry, native World2 travel and return with one track. A native client probe rejected an older generation and retained the current actor. Temporarily withholding Stage1 OwnerUserId stopped both previous tracks; restoring the attribute with Walk withheld played one Idle; delivering Walk later restored exactly two tracks with moving bones. These were runtime-only fixtures.

## 3. Entire personal Trophy equipment

Cause: existing presentation managed Trophy billboards, leaving the authored pad visible. The old appearance listeners also lacked the accepted combat revision/generation context.

New `ReplicatedStorage.Modules.PersonalTrophyVisibility` controls both whole authored devices in all ten World1 stages. It consumes server Trophy records only after CombatClient's packet fence. Server Trophy presentation now uses the existing EnemyManager owner/world/run/sequence envelope; post-yield qualification is checked before sending/replaying a TrophySpawn.

The client hides BasePart/Decal local transparency, GUI visibility, effect/light/prompt Enabled and sound Volume, preserving original values. It discovers late roots and descendants. The actual current devices contain a Handle pad plus BillboardGui/frame/icon/text hierarchy; all are covered. Additional Decal, Light and disabled Particle probes checked restoration without making everything opaque or enabled. Shared server equipment, claim conditions, prices, multiplier logic, purchase cancellation, award deduplication and return placement remain intact.

Native solo results:

- All twenty devices hidden before qualification. Touching Stage10 normal and double pads before defeat produced Win=0 and zero purchase prompts.
- Actual server defeat showed both Stage1 devices: each restored its one visible Handle and enabled BillboardGui. Other stages stayed hidden.
- Normal contact awarded one Win once, returned to Lobby and hid all devices; repeated contact did not award again.
- Death hid devices. A late Part retained Transparency=0.42, restored authored LocalTransparencyModifier=0.2, restored an enabled Light, and retained a disabled Particle. Decal local transparency restored to zero. A replacement Trophy root and the returned original both restored correctly while qualified.

**Real two-client test:** `StudioTestService:ExecuteMultiplayerTestAsync(2)` ran against the current Edit model with isolated stores. Both clients animated their own Stage8 bones; foreign actors were invisible with zero playing tracks on the observing client. Only the defeating owner saw both Trophy devices. The peer continued moving through the other owner's defeat, death, retry and collection/return. Retry had one track. A mocked double purchase prompted without granting Win; cancellation cleared the purchase lock and retained qualification. Normal Stage8 collection granted 150 once; repeated contact stayed 150. All 15 assertions passed.

This is a real two-client runtime result, not two simulated player records. Its visibility results are measured client properties, not inspected two-client screenshots. Post-fix Trophy raster capture also failed; no screenshot acceptance is claimed for it. No real checkout occurred.

## Changed Full Paths and reproducible object delta

Existing Sources:

- `StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient`
- `StarterPlayer.StarterPlayerScripts.Combat.CombatClient`
- `StarterPlayer.StarterPlayerScripts.Combat.Stage03AttackVisual`
- `StarterPlayer.StarterPlayerScripts.World.Stage01AppearanceClient`
- `StarterPlayer.StarterPlayerScripts.World.Stage02AppearanceClient`
- `StarterPlayer.StarterPlayerScripts.World.Stage03IdleClient`
- `StarterPlayer.StarterPlayerScripts.World.Stage04AppearanceClient`
- `StarterPlayer.StarterPlayerScripts.World.Stage05AppearanceClient`
- `StarterPlayer.StarterPlayerScripts.World.Stage06AppearanceClient`
- `StarterPlayer.StarterPlayerScripts.World.Stage07AppearanceClient`
- `StarterPlayer.StarterPlayerScripts.World.Stage08AppearanceClient`
- `StarterPlayer.StarterPlayerScripts.World.Stage09AppearanceClient`
- `StarterPlayer.StarterPlayerScripts.World.Stage10AppearanceClient`
- `ServerScriptService.World.EnemyManager`
- `ServerScriptService.Services.TrophyRewardService`

Added exactly two ModuleScripts:

- `ReplicatedStorage.Modules.World1BossPresentation`
- `ReplicatedStorage.Modules.PersonalTrophyVisibility`

Their Sources are under the matching `src/` paths. [Sources.json](Sources.json) maps all 17 paths to files and before/after SHA-256. Reproduction consists of these localized Source diffs and the two ModuleScript additions. **No authored GUI, equipment, template, geometry, placement or collision property delta.** Do not replace the current place with a repository snapshot.

## Test isolation, corrections and final state

Temporary adapters redirected DataStore, Marketplace and Badge dependencies to memory. Prepared progression/strength and own wall clearance shortened inspection; an inspection-only health refill prevented incidental chase deaths while explicit Health=0 exercised real death handling. This was not natural progression, balance timing, real payment or production persistence validation.

Two fixture issues were corrected: a defeat attempt initially changed strength after the encounter had captured it, and an adapter inserted a mock purchase signal at the wrong return statement. Those attempts are not passing evidence. The final two-client adapter and encounter setup passed. Play also exposed a new Trophy-controller bug: deferred property notifications mistook its own hidden values for authored values. Tracking the last applied value fixed restoration; fresh solo and two-client tests verified the correction.

All 21 changed/new production and test Luau files compiled. Focused runtime logs had no new presentation script error or infinite yield. Existing sound asset authorization warnings and deliberately unsuccessful mock Badge awards remained; animation assets loaded and actual bodies moved. No unrelated sound/access repair was made.

After stopping Play, restored all **38** temporary Source substitutions exactly and removed **4** Edit fixture objects. Final verification: **461 Sources** match the intended production baseline; **8,634 protected instances / 37,733 properties** and attributes are unchanged; **212,895 authored parent checks** found no unexpected reparent/removal; only the two intended ModuleScripts are added. Studio's internal Stats/MemStorage connections were recreated by Play and left alone. All 17 exports match the Edit Sources. Camera CFrame/Focus and HttpEnabled=false are unchanged.

Canonical Studio is **Edit, focused Edit**, with existing and new edits unsaved. No Save/Publish, rbxl writeback, Studio shutdown, OS input, window rearrangement or camera-setting change. Temporary screenshots were inspected without retention/commit.

Remaining limits: carpet and post-fix Trophy raster acceptance; two-client screenshots; physical mobile/input testing; full-model views of cropped large Bosses; real paid checkout, production persistence and public-server deployment. World2 animation Source and balance were retained; the focused World travel check is not a new full World2 regression.
