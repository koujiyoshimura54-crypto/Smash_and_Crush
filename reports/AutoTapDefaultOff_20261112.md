# Auto Tap default OFF — 2026-11-12 (JST)

## Request and scope
Make Auto Tap OFF by default. Apply this to new profiles, reset profiles and profiles with a missing preference. Preserve an explicit saved boolean ON or OFF; this does not force OFF on every login. Existing saved true values cannot distinguish an old default from a deliberate user choice.

Base: origin/main 08fb3078742b7f2faf0e20e5e3db7d804823b69e. This branch is independent of the in-progress early-balance PR #1 and retains the offline-claim and return-presentation fixes in its base.

## Changed production sources
- ServerScriptService.Services.PlayerDataService
  - Defaults/reset use false.
  - A missing saved value normalizes to false. Explicit true/false and invalid-type rejection remain.
  - Display attributes and save payload use explicit true.
  - IsAutoTapEnabled returns false until a session is loaded.
- ServerScriptService.Services.PlayerActionTiming
  - Missing AutoTapEnabled attributes no longer enable automatic admission.
  - Success clocks, cooldown calculations, reset behavior and manual admission are unchanged.
- StarterPlayer.StarterPlayerScripts.UI.AutoTapClient
  - Missing/false attributes display OFF; only true displays ON.

## Verification performed here
- Inspected current main source, normalization, reset callers, attribute publication, preference writes and save payload.
- Inspected AutoTapService, AutoTapController and the shared timing/client input paths.
- Reviewed the before/after diff: 3 production files; boolean defaults/admission/display only.
- AutoTapConfig is unchanged: shared minimum 0.2 s, after-manual 0.5 s, combat Auto 0.8 s, walking Auto 0.5 s.
- No Roblox Studio connector or Luau runtime is available in this environment. These are static findings, not Play, UI-image, persistence or runtime-test results.

## Required native Studio acceptance before merging/applying to main
Use the current canonical PlaceId 126576845524886. Preserve newer Studio edits and apply only these narrow changes.
1. New profile, /resetdata and legacy profile missing AutoTapEnabled begin OFF in both server state and actual HUD. No ON flash while attributes/data are loading.
2. Saved false remains OFF; saved true remains ON after real load. Invalid saved types retain current rejection behavior.
3. While OFF: grounded walking does not auto-gain, and wall/Boss contact does not auto-attack. Manual taps still work. Independent Treadmill gains remain unchanged.
4. Toggle ON: existing walking requirement and wall/Boss contact requirements work; toggle OFF stops further automatic actions. No queued burst or duplicate connection after repeated toggles.
5. Manual input still works with Auto ON. Confirm existing 0.2 / 0.5 / 0.8 timing behavior without changing those constants.
6. Save/reload OFF and ON, death/respawn, World travel and /resetdata retain the intended state and matching HUD.
7. Check scoped Runtime Error / Warning / Infinite Yield. Remove test helpers and return to Edit. Do not perform OS interaction, Save, Publish, rbxl writeback or Studio shutdown.

For the separate early-balance timing comparison, explicitly turn Auto ON in both matched Auto-based runs. Do not mistake the new default OFF for a cadence or progression regression.

## Status
Draft only. No native Studio application, Save, Publish or main-branch update has been performed here. Public game unchanged. GAME_SPEC/UI_SPEC/DEV_STATUS should record the new default after native acceptance; historical reports remain unchanged.
