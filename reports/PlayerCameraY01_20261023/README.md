# Y01 player camera framing — 2026-10-23

## Scope and authority

Current open Cloud-place Edit document, PlaceId126576845524886 / UniverseId10765181857, loaded PlaceVersion259. Fetched origin/main through b45c1ac before work. The current editor, including the new production SCP096 and owner's unsaved edits, was the baseline. No old rbxl or bulk source restore was used.

Only permanent runtime change: **StarterPlayer.StarterPlayerScripts.World.SpawnFacingCameraClient**. Before.luau captures its live pre-task Source, including existing death-camera logic and the owner's 18/.15 calibration. The src version now exports that preserved current Source plus the scoped fix. The previous src entry still had the historical .65 formula and lacked the later live death-camera changes; those preserved sections are not newly designed by this task.

## Historical behavior

- 9d53766: scale-aware zoom bounds and subject-centering correction.
- b42805f and reports/Studio_Phase23_Script_Sync_20260930/README.md: replaced forced scaled minimum with one-shot framing, CAMERA_DISTANCE_MULTIPLIER=.65, standard manual zoom, coalesced size changes.
- No later Git-recorded alternate calibration was found in the targeted history. Current later-authoritative Edit Source explicitly uses CAMERA_BASE_DISTANCE=18 and CAMERA_SCALE_INFLUENCE=.15. The user also cited that calibration. It is retained; the historical .65 formula is not restored over it.
- Current 13-tier MuscleScaleConfig heights are retained without changing growth, size prices, Strength or saved data.

Restored framing: **D = 18 * (1 + (MuscleHeightScale - 1) * .15)**. The ordinary unscaled initial character uses18. The following numbers are formula checks; only representative tiers were played.

| Tier | Height scale | Automatic distance (studs) | Maximum zoom (studs) |
|---|---|---|---|
| 1 | 1.1 | 18.2700 | 140.80 |
| 2 | 1.175 | 18.4725 | 150.40 |
| 3 | 1.25 | 18.6750 | 160.00 |
| 4 | 1.35 | 18.9450 | 172.80 |
| 5 | 1.45 | 19.2150 | 185.60 |
| 6 | 1.7 | 19.8900 | 217.60 |
| 7 | 2 | 20.7000 | 256.00 |
| 8 | 2.15 | 21.1050 | 275.20 |
| 9 | 2.4 | 21.7800 | 307.20 |
| 10 | 2.65 | 22.4550 | 339.20 |
| 11 | 2.95 | 23.2650 | 377.60 |
| 12 | 3.25 | 24.0750 | 416.00 |
| 13 | 3.55 | 24.8850 | 454.40 |

Minimum remains the authored .5; maximum remains the authored128 times height scale. Both authored bounds were read from current StarterPlayer. Manual zoom is standard Roblox zoom, including permitted first person.

A new Character or changed height resets to the automatic distance once. Repeated spawn-facing notifications, same-character World travel, StageSkip and Trophy return keep the user's nominal zoom. Death respawn creates a new Character and reapplies its automatic distance. SizeChange changes height on the existing Character and reframes once. This follows the existing Source's appliedScale-per-Character behavior. Camera replacement preserves nominal manual zoom, rather than an obstacle-shortened distance.

## Confirmed defect and fix

Ordinary fresh spawn and unobstructed growth already worked in the initial native Play. There was no competing enabled purchased-map camera Source in the targeted camera-property audit. This is not evidence that every occurrence of the user's original symptom had the same timing.

The confirmed reproducible failure is a discarded size-framing request while CameraType is Scriptable (or otherwise not ready). The old single delayed callback returns, with no retry on CameraType/CameraSubject/CurrentCamera readiness. Native baseline: change from height1 to3.55 while temporarily Scriptable; after returning to Custom, nominal/measured distance remains18 and bounds remain .5/128, instead of24.885 and .5/454.4. This reproduces a concrete route to missing framing. The precise original user-session trigger was not observed.

Fix:
- Coalesce bounded readiness retries and retry when CameraType, CameraSubject, CurrentCamera or a late PlayerModule/CameraModule becomes available. Character identity/death/cancellation are checked.
- Track applied Character/Humanoid, scale, Camera and controller. Unchanged normal follow is left alone, preserving manual zoom without per-frame enforcement.
- On Camera replacement, restore the previous controller's nominal zoom; never infer intent from occluded CFrame/Focus separation.
- For actual resizing, calculate an absolute subject-centering offset using the standard controller's uncorrected subject point and the existing character bounds. The old additive correction sampled potentially stale Camera.Focus after growth/teleport. Unchanged-size camera replacement does not recompute the offset from another idle pose.
- Preserve existing death freeze, overlay/FOV restoration, heading-only spawn alignment and combat listeners.

Current native PlayerModule is under StarterPlayer.PlayerModule, with no PlayerScripts.PlayerModule. Its CameraModule does expose activeCameraController; the existing fallback path is retained. Initial acquisition was successful in the baseline. A missing module/controller remains a guarded retry condition, not a separately proven cause of the user's session.

## Native verification and measurement

Real Studio Play on this document; stores, Marketplace and Badges were replaced by isolated memory adapters before Play, then restored exactly. No production records, Robux or real purchase fulfillment were used. Body/ownership conditions were prepared through test fixtures. Actual game growth, SizeChange, travel/StageSkip, Trophy credit/return, death/respawn and standard camera code executed.

Measurement: **|(CurrentCamera.CFrame.Position - CurrentCamera.Focus.Position)|**, in studs. Separately read the real runtime controller's GetCameraToSubjectDistance() nominal target. Read probes execute in native LocalScript context (the Assistant/plugin require cache is separate and was not used to infer live controller state). Post-change spring settling and floating-point differences are visible in Verification.json.

- Both Worlds: visual captures of unscaled, tier7/height2 and tier13/height3.55 characters at open lobby positions. Measured distances approximately18,20.7,24.885; largest recorded middle-tier immediate sample20.70755 before full spring settling. Screenshots were inspected temporarily and not committed.
- Actual mouse-wheel input changed24.885 to51.7700 and later38.3275. It remained unchanged while waiting, changing Camera/subject, World travel, successful World1 StageSkip to2.1, lobby placement and Trophy return.
- Actual WorldTravelRequest routes ran from prepared trigger positions; both World directions passed. StageSkip used BuyWithWin with isolated Win and returned “Stage 2.1 started”.
- SizeChange selected tiers7/13/AUTO through the existing server purchase function. Growth used existing Strength/PlayerData services. These were server/Remote-driven condition operations, not physical UI clicks.
- Death was triggered by setting the test Humanoid's Health to0, not by a Boss attack. During death CameraType was Scriptable and CFrame stayed fixed; actual respawn returned to Custom, matching Humanoid subject, height2 and distance20.7.
- Both Worlds' ordinary Trophy buttons were tested with an isolated prepared defeated flag; no combat-clear claim. The real saved pad touch, eligibility, Win credit, streaming/lobby placement and reset path executed. Nominal manual38.3275 was retained. No Win×2 purchase was tested because purchase behavior is outside scope.
- Temporary local collidable occluder shortened measured distance38.3275 to5.6 while the nominal target stayed38.3275. Replacement during occlusion retained the nominal target; removing the fixture restored38.3275. Existing Zoom occlusion mode stayed enabled; wall clipping was not disabled.
- Main suite ran before the final small centering restriction (recalculate only on actual resize). Final focused rerun passed initial spawn, the Scriptable growth reproduction, actual wheel zoom, occlusion and Camera replacement with identical offset before/after replacement.
- Final Source compiled. No scoped camera/test runtime error or infinite-yield line was found in the final console review. Existing unrelated sound-asset authorization warnings remain.

Not tested: published public servers, mobile/gamepad, complete hatch/battle cinematic sequences, long-stall module insertion, every one of13 physical body tiers, real purchases, physical gate/SizeChange/StageSkip UI clicks. The temporary Scriptable presentation tests the camera handoff directly; it is not a complete hatch cinematic test.

## Delivery and cleanup

Play stopped; user Studio remains open in Edit. All35 temporary service Source substitutions were restored exactly; two fixture Scripts and one memory Module were removed. No __Y01 Instances remain. Current camera CFrame/Focus/type/FOV and development-GUI flag match the pre-test values; no panel arrangement or device-preview setting was changed. Final camera Source readback matches the delivered text. Local rbxl was not written or reopened, and Studio Save/Publish were not performed. Cloud published content therefore remains unchanged.

Git includes the current target Source, live Before snapshot, reviewable task-only patch, focused test fixtures and this English record. Fixtures are files only, absent from the finished document.
