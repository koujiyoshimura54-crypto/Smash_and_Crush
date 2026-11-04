# Auto attack cadence and stale Belt HUD — 2026-11-04

## Outcome and scope

Canonical Y02 Studio, PlaceId **126576845524886**, UniverseId10765181857. The open unsaved Edit document was the baseline. Repository/main was fast-forwarded to a8eaeb3; no repository snapshot was imported into Studio.

**Fixed:** stale equipped-Item HUD across data reset and old responses.
**Not reproduced:** sustained automatic Player-to-wall/Boss damage at approximately0.2s. No attack implementation or timing setting was changed.

The user's later instruction removed the need for further multiplayer attack testing. Two native-client runs had already been started; subsequent verification used ordinary **solo Test/Play**, without further multiplayer launches. Final Studio is stopped and focused on **Edit**, not a Server/Client test view.

## Proven Belt cause and production change

Only changed production Full Path:
**StarterPlayer.StarterPlayerScripts.UI.ItemEffectHUDClient**

Before the fix, the HUD accepted Item states without validating EquipmentGeneration against ForgeSessionToken. It neither cleared nor requested fresh equipment when the token changed. Its initial loading loop had already finished. A reset can retain the same Character and persistent HUD, so the old equipped Belt remained until a later equipment response. A delayed old-session event could also restore it.

Reproduction through ordinary isolated PlayerDataService.Reset:
- Equip Common Fire Belt: server effect0.25; HUD icon and +0.25 Tier.
- Equip Rare Ice Belt: effect1; HUD +1 Tier.
- Reset: server OwnedItems empty, all equipment slots empty, effective Belt0; HUD still showed Rare Ice and +1 Tier.
- Best Equip: returned the empty authoritative state and hid the icon, matching the reported symptom. The hidden label still retained stale text before the fix.

The patch clears icons, values, slots and set badge on generation changes; re-requests current state; validates response generation; fences in-flight reads by both generation and local state revision; retries initial/reset loading; and clears text on unequip. Legacy ItemMerge notifications without generation are treated as invalidation signals and fetch fresh authoritative state instead of applying an unversioned snapshot. No every-frame polling was added.

ServerScriptService.Services.ItemService.GetEffectiveEffects and ReplicatedStorage.Modules.ElementSetBonus.GetEffects already require matching owned equipment. Server Belt effects were correct and remain unchanged. No auto-BestEquip, blanket unequip, player-data deletion, save schema, Item value or set multiplier change.

## Auto routing and reservations

Read current Studio and compared the relevant Sources with current Git:
- ServerScriptService.Systems.Controllers.TrainingController: Heartbeat calls AutoTapService.TryAutomatic.
- ServerScriptService.Services.AutoTapService: gates readiness/Auto/timing, then routes to one combat target or the unchanged grounded-walking gain.
- ServerScriptService.World.EnemyManager: its0.1s contact monitor also attempts automatic combat.
- ServerScriptService.Services.PlayerActionTiming: both routes share the same per-Player state and single Pending ticket.
- StarterPlayer.StarterPlayerScripts.UI.AutoTapClient and Combat.CombatClient: original input Remote routing and punch playback.
- ReplicatedStorage.Config.AutoTapConfig: unchanged minimum0.2, after-manual0.3, after-auto0.5.

Two attempt sources exist, but do not have independent clocks. ScheduleAutomatic refuses an existing Pending reservation. Its callback checks ticket identity and CanAct(false) again before damage. Successful hits update the shared deadline; manual success cancels the prior reservation. OFF cancels it. The reviewed wall/Boss damage-to-RecordSuccess section has no yield that could open a second success between those operations.

The solo trace contains60 accepted reservations, zero accepted while already Pending,32 automatic perform callbacks and32 corresponding successful automatic HP reductions. Failed manual requests left Last and NextAuto unchanged. All automatic success snapshots set NextAuto-Last to0.5; all manual snapshots set0.3.

### Measured real HP intervals (seconds)

Each case: fresh Auto → four OFF/ON cycles through the original Toggle handler/Remote → four taps through the original client tap handler (plus a rapid Remote burst to observe rejections) → stop all manual input while retaining contact → automatic-only sample → OFF.

| World / target | Baseline fresh Auto | Baseline first Auto after manual | Baseline subsequent Auto | Final solo first Auto after manual | Final solo subsequent Auto |
|---|---:|---:|---:|---:|---:|
| World1 wall |0.516|0.316|0.501–0.516|0.300|0.501–0.517|
| World1 Boss |0.515|0.317|0.500–0.518|0.316|0.501–0.518|
| World2 wall |0.500|0.301|0.501–0.517|0.301|0.500–0.516|
| World2 Boss |0.517|0.316|0.515–0.517|0.301|0.501–0.517|

Stage1 was used in both Worlds. Fixture setup cleared walls directly only to prepare the Boss encounter; measured attacks used the normal input/Remote/scheduler path and real HP mutation. An initial fresh solo interval of0.542, and a later cold World2 wall interval of0.570, were slower scheduling/loading samples, not accelerated damage.

### Animation versus damage

CombatAttack is sent when a reservation is made, before its damage deadline. Manual cancellation does not retract the already-played punch. A new manual action or replacement reservation can therefore start another animation before the original animation would have caused damage. This is a plausible transient visual explanation, **not a demonstrated cause of sustained0.2s damage**.

Recorded actual AnimationTrack.Play start time, speed, length and IsPlaying separately from HP reductions and CombatAttack delivery. Manual speed2 returned to the configured automatic playback calculation (observed0.361/0.444); it did not remain at manual speed. Animation-start intervals varied with windup, cancellation and delivery, and cannot be used as hit intervals.

The initial observer exposed both World renderers with the same probe name, so its exported Track list covered World1 only. A corrected World-specific observer in a separate solo run captured40 World2 Track starts and repeated both World2 HP cases successfully. This was an observer correction, not a game change. Physical punch/body-motion acceptance from video is not claimed.

## Verification, isolation and evidence

- [Before.json](Before.json):87 passing assertions; both Worlds and reset/HUD reproduction in two native clients.
- [AfterMultiplayer.json](AfterMultiplayer.json): combat and reset/generation assertions passed;167 checks passed. A later test-harness step attempted to read write-only OnServerInvoke and failed. This run is deliberately recorded as **not fully passed**. The observer was corrected; no production callback was broken.
- [AfterSolo.json](AfterSolo.json):110 passing assertions; full four-target sequence, reset, old event, real inventory response delayed across reset, simulated unavailable-data response/recovery, generation-less merge notification, normal equip/change/unequip/BestEquip, death/respawn.
- [World2AnimationsSolo.json](World2AnimationsSolo.json):48 passing assertions, corrected World-specific Track observation, normal input/Remote HP measurements.
- [Treadmill.json](Treadmill.json): actual unchanged normal treadmill ticks. No Belt: multiplier1, gain1. Equipped Common Belt:1.25, gain1.25. After reset:1, gain1. A reset-completion tick retains the preceding test phase label but its Belt/effective values correctly show0/1.
- Before the multiplayer requirement was withdrawn, the second client's automatic wall timer stayed independent while the first player toggled/manual-attacked. The peer's empty Belt HUD did not acquire the first player's equipment.

All persistence handles were redirected to a temporary in-memory provider before Play; Marketplace, badges, policy and messaging were isolated. Native solo reused the account's avatar only, not its production data. Reset tests call the ordinary data-reset service on this isolated state. No real payment or production data write. User identifiers in solo evidence are replaced with SoloPlayer.

**Actual screen inspection:** ordinary solo capture at the existing1390×622 viewport showed the valid Fire Belt icon and +0.25 Tier above Strength; the following isolated reset capture showed neither icon nor value. One runtime ItemEffectHUD was present. No camera/window/device-preview or OS input manipulation. Screens were inspected in-memory and are not committed. Before-fix HUD reproduction is property/state evidence, not a before-fix raster comparison.

Unverified: the user's exact sustained0.2s phenomenon; physical mouse/touch and video timing; public/live-server latency; production persistence/rejoin; other Stages beyond the representative Stage1 wall/Boss. There is no claimed fix for an unreproduced Auto defect. If it recurs, the smallest next diagnostic is a scoped origin/ticket/animation/HP trace during that exact session; changing the shared minimum or prohibiting manual input would violate the specification.

## Fixture reproduction and cleanup

Test Sources: tests/AutoBeltRegression.server.luau, tests/AutoBeltRegression.client.luau, tests/AutoBeltTreadmill.server.luau. These are not shipped into Studio. They require temporary memory-provider substitutions, read-only PlayerActionTiming.__QASnapshot, EnemyManager contact probes, an AutoTapClient BindableFunction invoking its original tap/toggle closures, World-specific CombatClient Track probes, and an optional ItemController post-snapshot delay observer. Snapshot reads must not call the timing state synchronizer. Native=false uses solo; Only filters named cases; Fixed=true checks the repaired HUD. The treadmill fixture observes real training ticks and restores its method wrapper.

Removed all helpers and restored44 temporary Source substitutions. Verified all486 original LuaSourceContainers against the starting unsaved snapshot plus the one intended HUD patch, all recorded Enabled states, no extra Sources, unchanged Edit camera CFrame/Focus, HttpEnabled=false and Hover.Volume=0.15. No map/authored-GUI change, Save/Publish, rbxl writeback or Studio closure.

**Studio remains unsaved. The user must manually Save/Publish.**
