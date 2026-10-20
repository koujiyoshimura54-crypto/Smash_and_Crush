# Speed application — 2026-10-20

Current-file investigation followed the existing highest-eligible-speed calculation: normal tiers24/28/32/36/40, legacy Boost40, Premium50; no addition or new selection rules. Inventory's Current Speed is display-only and Premium ownership activates its eligible effect automatically. The old SpeedServer writer is inactive (`Main.Enabled=false`). Muscle scaling and Training do not write WalkSpeed. Studio/creator GamePass effect suppression is intentional and remains unchanged; OWNED/purchase restrictions are outside this fix.

Confirmed defect: World1 RunReturnService captured normal speed **before** streaming and the durable bank operation. A Speed change that completed during that operation was overwritten by the old captured value on return, until a later state publication. Native runtime reproduction: current32 -> eligible Premium50 applied -> return writes32 while GetState remains50. This was a controlled interleaving at Bank.Commit, not a spontaneous reproduction of the user's general symptom.

Only changed game Full Path: `game.ServerScriptService.Services.RunReturnService`. Remove the speed snapshot/argument and call existing `Speed.Apply(player)` after the return reset, immediately before existing placement. Both World branches use that helper. Existing initialization clears transition boosts. No new waits, polling, per-frame enforcement, ownership/UI/config changes, purchase restrictions or transfer changes. All other Sources, including ba1186f/36595fe/07c2518, remain exact.

## Focused Studio verification

One actual Studio Play client; PlayerData and other non-package DataStore consumers used a temporary memory-only adapter. Premium ownership/effect eligibility, World unlock and the return commit interleaving used temporary server fixtures. The patched Source was loaded as a native ModuleScript and installed into the existing service table during Play. No production data write or Robux checkout. The final same-file Source also passes compilation and structural preservation checks.

Actual W input on the same temporary anchored220x220 flat floor, same camera/direction and1.6-second key hold. Measure the middle approximately1 second after0.25-second acceleration allowance, using actual root displacement/time; every sampled frame was grounded. Units are studs and seconds:

| Test | Server calculated / Humanoid | Distance / time | Measured speed |
|---|---:|---:|---:|
| Unmodified normal baseline |32 /32|32.53284 /1.01839|31.9453|
| Old return, Premium eligible after commit interleave |50 /32|32.53284 /1.01667|31.9994|
| Fixed return, identical interleave |50 /50|49.99878 /1.00105|49.9466|
| Actual Win upgrade UI,24->28 |28 /28|28.00049 /1.00116|27.9681|
| After death, World round trip, Treadmill entry/exit |50 /50|50.62376 /1.01607|49.8229|

The deterministic comparison holds only the existing30-second ownership refresh at a temporary test event, so that incidental recovery cannot mask the obsolete return write; attribute-driven publication is allowed to finish before the return continues. Assembly velocity averaged32 before and50 after; displacement/time, rather than that velocity/property alone, is the pass evidence.

- Actual UI keyboard selection/Return: the existing UpGrade Speed button upgraded24->28, consumed100 test Win once (2000->1900), and showed `Upgraded!`. Inventory button and Speed tab opened through the same keyboard path; test Premium ownership showed Current50 and ACTIVE. The current UI has no normal/Premium equip toggle, so fixture entitlement changes are **not** claimed as UI equipment selection or a real pass purchase.
- Native death/respawn retained50. Existing WorldTravelRequest handlers moved World1->World2->World1 from their real triggers and retained50. Fixture positioning entered the real Normal01 TrainingZone; IsTraining became true and then false after leaving;50 remained. Final actual W measurement above followed all these transitions. Positioning/unlock was scripted, not manual gate/Treadmill navigation. Badge awarding was suppressed in the fixture.
- Ordinary normal-speed application and respawn worked in the original code. A broad initial-join/general speed failure was not reproduced. No Speed/RunReturn runtime error or infinite yield was observed. Existing inaccessible-asset/Core UI warnings and temporary adapter metadata-acknowledgement warnings occurred; the latter concern the deliberately incomplete memory adapter, not a validated live save path.

Unverified: natural occurrence/frequency of this race, physical mouse/touch, a nonexistent equip-toggle flow, live Premium ownership/payment, production persistence/rejoin, multiple clients, every tier/body size and all cinematic restrictions. Only the confirmed return snapshot bug was changed. Play stopped; temporary fixtures and adapter Sources removed in Edit. The owned verification Studio is closed without Save/Publish after write verification; final process/lock evidence is recorded in FileValidation.json. External CurrentCloud.rbxl is not Git-tracked; the commit records the Source, same-file writer and this evidence. No additional authored rbxl/Backup/Copy/Migration was created.
