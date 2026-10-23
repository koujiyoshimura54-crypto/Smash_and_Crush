# SCP096 forward-arm pursuit correction — applied to the current Studio editor

## Finding

The user clarified that the intended run keeps both arms extended forward throughout pursuit. The previous implementation selected `Running_BodyBones` outside the existing attack eligibility predicate and selected `AttackRunStart_BodyBones` -> `AttackRun_BodyBones` only inside it. Leaving the predicate restored Running, including when interrupting AttackRunStart. This explains the reported lowered, sideways arms; the earlier statement that the intended running motion was already connected was too broad.

Read-only inspection of the current Cloud editor (PlaceId126576845524886, UniverseId10765181857, loaded PlaceVersion254) found all ten production Sources matching206b16e. Production Running/AttackRunStart/AttackRun matched the current editor saves and their archived frame data. No Walk clip is used in the new production BodyClips folder. The user's previous `Workspace["SCP 096"]` editing model is no longer present; both animation-save ObjectValue links are nil, while all19 body saves and the production template remain. Nothing was restored over that state.

The actual production state/sampler was exercised on a detached memory clone. Running put the upper-arm-to-hand direction downward/backward (forward component approximately-0.59 to-0.81); AttackRunStart raised it by approximately0.5s, and AttackRun maintained a forward component approximately0.97 with near-horizontal arms. Original carrier versus converted upper/lower limb segment directions matched within0.028 degrees at authored key times. These are pose/kinematic checks, **not rendered visual acceptance**. They identify the state selection mismatch without proving final skinned-mesh appearance.

## Applied correction

The repository changes now use GetUp_Panic2x -> Panic2x -> AttackRunStart1x once -> AttackRun1x loop for pursuit. Range/angle eligibility changes no longer restart the start clip or select Running. The loop advances during actual travel or stationary eligible close combat, otherwise holds its current forward-arm pose. Retry/cancellation remains per actor. Existing damage25, one-second cadence and hit predicates are unchanged; damage does not wait for AttackRunStart completion. Existing clip keys, five Config rates, models and other Bosses are untouched.

Changed runtime Full Paths:

- `ReplicatedStorage.Modules.World2SCP096State`
- `ReplicatedStorage.Modules.World2SCP096Clip`
- `ServerScriptService.World.World2BossAnimationService`
- `StarterPlayer.StarterPlayerScripts.World2BossAnimationClient`

The saved clip paths remain `ServerStorage.EnemyTemplates.World2SCPDisplays.SCP096_BodyBones_Display.BodyClips.AttackRunStart_BodyBones` and `.AttackRun_BodyBones`. Original Running is retained as data.

## Verification and delivery status

- Passed: all four edited runtime Sources and three focused test Sources compile with the local Luau compiler.
- Passed:24 offline assertions using the actual updated state module and Config, covering intro timing, start/loop timing, eligibility changes, cancellation, retry and actor isolation.
- Earlier attempts could not apply because the target Studio had disconnected; they were not deliveries. On the user's renewed request, the existing MCP connected to the reopened **Cloud-place editor, loaded PlaceVersion257**, PlaceId126576845524886 / UniverseId10765181857. All ten relevant Sources still matched206b16e, so only the four guarded Source deltas were applied. No older file/model was loaded over the document.
- Passed:116 native Edit preflight checks, including exact durations, rates, per-actor lifecycle, actual Bone sampling, horizontal forward arms, freeze/resume and unchanged actor pivot. This is not Play or rendered acceptance. See `ForwardEditPreflight.json`.
- Passed: a native server and two real test clients ran the current document with isolated in-memory stores and mocked Marketplace/Badges. Real wall destruction/combat APIs started GetUp_Panic -> Panic -> AttackRunStart -> AttackRun on both clients. Both actors pursued, kept the same loop across contact/range exit, and never selected Running. Per-client actual transformed arm measurements gave minimum forward components0.97290 and0.97294, with maximum vertical components below0.056 during both distant pursuit and contact. Actual Bone transform changes were observed in all four phases; this is stronger than a playback flag but is still **not rendered visual acceptance**. See `ForwardNativeFinal.json`.
- Existing damage25 landed0.201762s after entering contact; the unchanged one-second deadline implementation was retained. Reset/retry created a fresh owner actor, and World return retired it without resetting the peer's identity or phase revision. The broader death/defeat/departure suite from206b16e was not repeated for this scoped correction.
- Retained failed attempt: the first native fixture selected the initial automatic waiting actor instead of the current encounter generation and failed its movement assertion. The production actor already had the expected forward-arm measurements. Only the fixture's generation selection was corrected; `ForwardNativeInitial.json` is not reported as a pass.
- Restored all36 temporary test Source substitutions and removed3 fixture Instances. Final readback confirms four edited Sources match the repository, the complete production template and all19 editor clips retain their initial scoped properties, and camera/focus/development-GUI values are unchanged. Test server/clients ended; the user's target Studio remains open in Edit. See `ForwardTestRestoration.json` and `ForwardFinalIntegrity.json`.
- Final native log review of server9FA2B and clients530E8/9F86C found no SCP096/World2BossAnimation/test-script error or infinite-yield stack. Unrelated WinsGift image resolution failures remain; this is not a clean whole-game log claim.
- No GUI input, camera/device-preview changes, local rbxl writes/reloads, Studio Save/Publish or Cloud publication were performed. `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl` remains6,634,931 bytes with SHA-256 `aee5bae001df02c1edbdefcd19e9a75b8ac0305cc44a7759af66b41935f253fc`. It still predates206b16e and must not replace the current Cloud editor.
- **Current verification location:** the already-open Studio document for PlaceId126576845524886, World2 Stage1, after the owner destroys Wall4. This is an unsaved editor change; reopening the Place from Cloud or opening the old local rbxl does not retrieve this correction. The user must manually save before closing Studio/moving PCs, and manually publish to update public servers.
- Not verified: rendered front/side skinned appearance, sole contact/twist quality, physical input and published-server behavior. No animation asset was newly uploaded. No binary file was serialized, so rbxl decode/INST/PROP/PRNT/UniqueId checks are not claimed for this live-only change.

Historical206b16e verification remains in README.md and is not counted as validation of this correction.
