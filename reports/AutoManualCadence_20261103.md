# Auto ON manual input / shared action clock — 2026-11-03

## Scope, cause and live changes

Canonical unsaved Y01 Studio: PlaceId126576845524886 / UniverseId10765181857. Base Git9c3ed78, including the Dumbbell Lobby correction and2173c0e Boss Ore Battle Bag work. The separate local-file Studio was untouched.

Changed Full Paths:

- ReplicatedStorage.Config.AutoTapConfig
- ServerScriptService.Services.PlayerActionTiming (new ModuleScript)
- ServerScriptService.Services.AutoTapService
- ServerScriptService.Systems.Controllers.TrainingController
- ServerScriptService.World.EnemyManager
- StarterPlayer.StarterPlayerScripts.UI.AutoTapClient

Auto ON was rejected independently in the input LocalScript, AutoTapService and EnemyManager. Ordinary gains used a walking accumulator, while combat used separate manual timestamps, LastTick and delayed Pending attacks. Changing only a cooldown could not enable manual input or enforce a shared rate.

The new server clock stores one Last-success timestamp, one NextAuto deadline and at most one cancellable automatic reservation per player. Successful manual/automatic actions share **MinimumInterval0.2s**. Manual success replaces NextAuto with now+**0.3s**; automatic success uses now+**0.5s**. No rejected request changes these success timestamps. Missed intervals are never accumulated. Auto OFF cancels automatic reservations and retains manual input.

Automatic normal training uses the existing heartbeat and now follows this deadline while stationary as well as moving; it no longer requires walking to advance an accumulated tick counter. Training and combat route through the existing target selection, and one action cannot grant Strength and attack. Treadmill training stays in its separate existing loop.

Combat windup leads into the shared deadline instead of adding another delay after it. A successful manual hit cancels the superseded automatic callback; animation/Pending state does not impose the former0.5s manual rejection. Existing Boss contact, character, life, stage, encounter and spawn-generation validations still run at impact. Actual gain/HP mutation must succeed before recording the action. Death, character replacement, World changes, Auto changes and battle reset retire obsolete reservations.

The first native test exposed a deferred AttributeChanged notification resetting an already-observed Auto transition twice. The clock now synchronizes the context on access and in notifications, resetting only when the context actually differs. This also protects input immediately following a toggle. This fix was included in all final cadence measurements.

## Native verification

Memory-isolated StudioTestService multiplayer Play with **two real test clients**. All DataStore, Badge, Marketplace, Policy and Messaging dependencies were redirected before startup. No real payments, production data updates or public messaging.

The main tests invoked the actual AutoTapClient local tap function through a temporary BindableFunction probe, retaining its Auto/input/UI filtering and normal AutoTapRequest Remote. Automatic actions ran through the actual heartbeat/EnemyManager monitor. Native server wrappers observed input arrival, acceptance/reason, committed Strength and wall/Boss HP changes, and the success clock. They did not replace damage or gain calculations.

Raw Remote spam and invalid payload tests deliberately bypassed the client throttle to verify server rejection. A separate lethal-hit test called the original server HandleTap directly to avoid racing a client round trip against a prepared one-hit Boss; it is an **internal-handler test in native Play**, not claimed as a physical or client-routed click. Its resulting defeat and new battle used the existing game services. Combat Strength, HP and positions were prepared in isolated data; these setup assignments are not counted as earned Strength or successful attacks.

### Measured successful-action intervals (seconds)

| World | Action | Auto only | Manual → Auto | Next Auto → Auto | Burst end → Auto |
|---|---|---:|---:|---:|---:|
| 1 | Training | 0.517 | 0.302 | 0.516 | 0.301 |
| 1 | Wall | 0.501 | 0.301 | 0.517 | 0.317 |
| 1 | Boss | 0.517 | 0.317 | 0.500 | 0.317 |
| 2 | Training | 0.515 | 0.300 | 0.502 | 0.301 |
| 2 | Wall | 0.500 | 0.301 | 0.516 | 0.301 |
| 2 | Boss | 0.501 | 0.301 | 0.500 | 0.302 |

Each of these six cases included Auto OFF manual actions, Auto ON manual actions, four accepted native manual burst inputs, automatic continuation, rapid rejected requests and Auto OFF cancellation. Every committed pair respected the common0.2s floor (measurement tolerance1ms); no per-source double allowance. Frame/scheduler delay accounts for intervals slightly above the configured minimum. Per-action Strength or damage was positive and matched the native gain/HP delta; animation-only acceptance was not used as evidence.

Representative short native log (server seconds, World1 normal gains):

| Time | Source | Accepted | Real change / clock |
|---:|---|---|---|
| 23.797 | Automatic | yes | Strength +1; next automatic24.297 |
| 24.062 | Manual input/commit, Auto ON | yes | Strength +1; replaces next automatic with24.362 |
| 24.146 | Rapid manual request | no, Cooldown | no gain; Last24.062 and NextAuto24.362 unchanged |
| 24.364 | Automatic | yes | Strength +1; next automatic24.864 |
| 24.880 | Automatic | yes | Strength +1; resumes0.5s cadence |

Wall observations used real1-point HP reductions; prepared Boss observations used0.375 per hit in World1 and15,000 in World2. These fixture strengths were held constant within their cases. The per-hit calculation modules were not edited.

Additional passing native checks:

- Both Worlds: contact loss during windup caused no hit or training fallback; it did not heal the retained encounter. Invalid contact requests left the success time unchanged. Recontact resumed, actual Humanoid death canceled the reservation, respawn could train, and a new fight accepted manual hits.
- Both Worlds: scripted lethal manual hit canceled the pending automatic hit; no old Boss hit followed defeat. New battle generations accepted normal client-routed manual input.
- Two real players: one player's manual burst did not shift the other player's automatic intervals.
- Processed input and an actual Auto button coordinate produced no gameplay Tap request. Existing menu/TextBox/scrolling/button guards remain.
- Real WorldTravelRequest W1→W2 retired the old context and accepted a new normal tap.
- Both Worlds' native treadmills continued to add Strength while Tap attempts were rejected. Neither treadmill ticks nor these rejections changed the action clock. The final fixture used an unanchored avatar supported by the real belt; anchoring animated feet had made the narrow World2 zone unstable in earlier attempts.
- No action queue or repeated catch-up damage. Compile and exact local/live Source matching passed.

## Test iterations and limits

The first run found the deferred-toggle reset issue. Wall preparation also initially missed its existing three-stud forward trigger, and the first World2 separation sample was not a valid retained-arena point; those fixture coordinates were corrected without changing map/zone code. The second run passed all six cadence cases, both contact/death cases and peer/UI exclusion. Two focused follow-ups completed the lethal/new-generation and stable-treadmill checks. Earlier failed fixture attempts are not counted as passes.

No OS input was synthesized; the game input function, Remote and native server path were exercised programmatically. No physical click/touch usability, animation appearance screenshot, high-latency network simulation or production persistence/payment test is claimed. Chat/Menu guards were preserved statically; the native exclusion tests covered processed input and a GUI button, not an actual chat session. Unrelated asset authorization/not-found warnings appeared during Play; assets were not changed.

Boss-to-Player Source, BossCombatService damage arithmetic, pursuit, arena recovery, equipment modifiers, treadmill config/loop, prices, receipts, tutorials, UI design and the previous Dumbbell fix remain unchanged. Existing tutorial completion code still executes only when an attack is accepted for presentation, as before.

## Cleanup

All temporary probes, wrappers, memory dependencies and test Scripts were removed. The post-implementation manifest verified **476 Sources/Enabled states and74 SoundIds** after restoration. All six production Sources compile and match their Git files; the original Boss damage/Boss-to-Player Sources match exactly. No __TapQA object remains.

The canonical Studio is stopped in **Edit with unsaved edits**. No Save, Publish, rbxl write, user Studio shutdown, OS GUI input, camera or preview-setting change occurred. Manual Save/Publish remains the user's responsibility.

Fixtures: tests/AutoManualCadence.server.luau and tests/AutoManualCadence.client.luau. They require the memory-isolation harness and are not installed in the final DataModel.
