# Egg close controls, notification image, and Trophy restoration — 2026-11-12

## Outcome and scope

Canonical Studio PlaceId **126576845524886**, universe **10765181857**. Baseline Git main: **5a4947b**. Work used the currently open unsaved Edit Sources and editor buffers, not a Git-to-place restore.

Implemented the two requested UI phases and the subsequently requested PersonalTrophyVisibility repair. The restoration defect is fixed in isolated native tests. **Resolution of the reported mobile-only WinTrophy symptom is not established.** No actual combat Play or natural streaming session was started.

Existing Slap Hand purchase-prompt suppression is present and unchanged. Merge UI, balance, Egg prices/counts/pools, purchases/receipts, owned Pets, saves, Trophy rewards/return, HP and Strength are unchanged. PR #1 was not merged or incorporated. No new directories were created.

## Changed production Full Paths

| Full Path | Change |
| --- | --- |
| `StarterPlayer.StarterPlayerScripts.Services.EggClient` | Per-Egg dismissal, close binding, physical-distance rearming, lifecycle reset and idempotent startup. |
| `StarterPlayer.StarterPlayerScripts.Services.StandClient` | Existing Limited Egg close control uses the shared donor and physical-size compensation; dead characters close the sheet. |
| `ReplicatedStorage.Modules.EggSheetClose` | New small helper cloning the existing purchased Inventory Exit artwork and binding Activated through the sheet Janitor. |
| `ReplicatedStorage.Modules.BadgeRenderer` | Existing live helper extended to render the supplied image, suppress old paint, animate and clean up centrally. The module existed in Studio but lacked a tracked src mirror; its current implementation is now recorded. |
| `StarterGui.StrengthGui.InventoryNotificationClient` | One shared renderer mount; all notification decisions remain in existing code. |
| `ReplicatedStorage.Modules.PersonalTrophyVisibility` | Restore authored values even when detached to nil; make root release and deferred removal safe. |

The authored `ReplicatedStorage.Assets.Templates.OpenEgg` and close donor `StarterGui.ScreenGui.Menus.Inventory.Exit` were reused without editing their authored hierarchy. GUI additions occur on runtime clones.

## Phase 1 — PetEgg close behavior

Cause: normal Egg sheets have proximity-driven choose/fit/RenderStepped updates. Disabling a BillboardGui alone cannot dismiss it.

Each registered normal Egg now retains its own dismissed flag. Activated immediately disables its sheet, zeros opening progress, and hides the hover card. The flag is cleared only after physical distance exceeds the existing 15-stud reach, or on character/world lifecycle reset. Camera selection cannot clear it. Other nearby Eggs remain eligible. fit also checks the flag, preventing reopening during an opening/closing transition.

Normal World1 and World2 Eggs share this path; World2's paid Limited Egg is still excluded. Limited Egg 01 and 02 use StandClient's separate, explicit ProximityPrompt-to-ScreenGui path. They already had a close control and do not automatically reopen while nearby. That manual opening policy is preserved; the existing close control is replaced with the same shared purchased artwork and an approximately 48-pixel minimum target after UIScale. Leaving the 24-stud Limited range, changing World or dying closes it.

Normal-sheet restart is idempotent. Sheet rebuilds retain the existing Janitor cleanup. Close handlers contain no purchase dispatch. Existing press(), Limited purchase()/receipt callbacks and HatchClient implementation were not changed. Closing a Limited sheet does not clear its pending purchase lock or disconnect the lifetime committed-receipt handler.

Manual tuning: `EggSheetClose.PixelSize=48`, `Padding=4`. Limited local dimensions round upward after division by panel scale; measured small-screen size was 48.109 pixels. Normal target measured 48 x 48. The normal layout and candidate distribution were retained.

## Phase 2 — notification image and movement

The user supplied image **126155807251943**. Metadata identifies an Image asset named “白い感嘆符の赤い通知バッジ”. Its creator and the canonical experience creator are the same account. ContentProvider returned Success; visible GUI images reported IsLoaded=true, and screenshots showed the red circle, white exclamation mark and black outline. No new image was generated, uploaded or substituted. No additional registration action is needed for this supplied asset in the verified Studio session; a published-client permissions check was not performed.

BadgeRenderer mounts existing notification roots and incremental descendants. It preserves existing Visible values, eligibility and seen logic. Old text/background/stroke paint is muted, including later legacy style writes, while the old label objects remain available to existing callers. A single noninteractive ImageLabel paints the supplied image at 1.5 times the original badge bounds. Equipped/owned badges and Merge content are outside the target name set.

One shared Heartbeat scheduler drives short sine rotation: 3-second interval, 0.4-second duration, approximately +/-10 degrees. There are no per-badge Tween loops. Hidden badges/ancestors/screens reset their clock and angle. Destroy/removal disconnects observers; repeated mount/attach does not duplicate the image or scheduler. Parent-layer observers keep dynamic card badges above purchased button visuals after ResponsivePanels changes ZIndex. This was added after the first resized inventory preview exposed the layer issue.

Manual tuning is centralized in `BadgeRenderer.Style`: Image, Scale, Interval, Duration, Angle. Image Active/Interactable/Selectable are false. Existing notification root dimensions and positions remain authored.

## Additional repair — Trophy restoration

Cause reproduced before the change: a hidden child detached to Parent=nil skipped restoration, then lost its original-value record. Re-registration captured LocalTransparencyModifier=1 or Enabled=false as its authored default. Root release had the same Parent guard.

Both paths now call one restore helper that disconnects old property observers and restores the captured values even without a parent. Root release clears its old item table. Deferred child removal first verifies that its record is still the currently registered root, preventing stale cleanup from overwriting a new registration. No rule forces all objects opaque/enabled.

The existing accepted owner/world/run/sequence envelope, personal grants, alive/world check, removal/collection clearing and character-reset logic remain unchanged. CombatClient, EnemyManager and TrophyRewardService were not edited.

## Verification performed

Three committed tests execute copies/extracts of current Sources with isolated native GUI/Instance objects, fake lifecycle/input/time boundaries where stated, and no production profiles or purchase calls:

- [EggDismissalEdit.luau](../tests/EggDismissalEdit.luau): **16 assertions**. Immediate close; fit cannot reopen; another Egg stays eligible; camera rotation retains dismissal; leaving/re-entering; death/respawn reset; both Worlds; Hatch suppression; no purchase request in the close callback. Close invocation is synthetic, not a real click.
- [NotificationBadgeEdit.luau](../tests/NotificationBadgeEdit.luau): **22 assertions**. Correct image/scale, noninteractive paint, legacy paint suppression, shared connection/image deduplication, positive/negative/zero rotation, hidden ancestor/screen/detachment, resume, clone/destruction cleanup and a forced stale responsive layer.
- [PersonalTrophyRestoreEdit.luau](../tests/PersonalTrophyRestoreEdit.luau): **640 assertions** across normal/Double and actual Model shape plus a BasePart-root edge fixture. Five repeated cycles each cover hidden detach/re-add before qualification and qualified root/child detach/re-add. Authored Transparency=0.42, LTM=0.25, Volume=0.37, enabled light/GUI, and disabled GUI/particle/label were retained. Unqualified, removed, collected, death, respawn, World2, return and new-run cases remain hidden.

The earlier nine-case restoration probe was also rerun: its previously stuck LTM=1/Enabled=false cases restored normally. All six changed/added production Sources compiled and matched their editor buffers and reviewed candidates.

Exact current Trophy spawn/send and client-fence functions were run with isolated transport/player/map stubs. Stage2 produced one TrophySpawn with Owner/World/RunRevision/MessageSequence, duplicate spawn produced no second record, and replay advanced sequence. One valid packet was adopted; wrong owner, wrong World, older revision, newer revision without Initialize, duplicate/older sequence and missing sequence were rejected. **These are function checks, not observed live RemoteEvent delivery.**

A native Edit Heartbeat sample on a rendered badge measured rotation from approximately -9.998 to +9.602 degrees and zero after hiding. Actual image pixels were inspected.

### Visual coverage and limits

Studio Device Simulator was used with current presets:

| Preset | Resolution / viewport | Observed |
| --- | --- | --- |
| Average Windows | 1366 x 768 | Normal/Limited close, HUD image paint; final fresh Limited sheet fully in bounds. |
| Samsung Galaxy A06 landscape | preset 800 x 360; camera viewport 706 x 339 | Normal close 48 x 48; Limited close about 48.109 x 48.109; image paint and representative inventory purchase badges with readable prices. |
| iPad Pro M5 13-inch landscape | 1376 x 1032 | Normal/Limited close, HUD image paint and inventory layout. |

ScreenOrientation remained Sensor. Temporary preview ScreenGuis used IgnoreGuiInset=true as in the relevant sheet path. These were **rendered Edit previews**, not running gameplay or physical devices. Current HUDLayout and actual cloned HUD/purchased button artwork were used with synthetic notification visibility. The normal Billboard's authored children were rendered in a temporary ScreenGui at the pixel dimensions calculated by the current fit function; this is not proof of actual PlayerGui Billboard rendering. Limited previews executed the current show() path against a fake player with price fetching disabled. No real checkout or receipt was sent.

The final normal and Limited close controls did not cover their titles, candidate probabilities or purchase buttons in the inspected previews. HUD images did not cover button captions/adjacent buttons. Representative actual inventory-card mobile previews kept prices readable. Dynamic notification layers were separately fault-tested after the responsive-layer repair. A deliberately unscaled synthetic 96-pixel purchase-button fixture was not representative of the actual inventory UIScale and was not accepted as a final layout check.

Runtime TouchGui was absent in Edit, so tablet touch-control-driven HUD layout is not verified. Some early Limited Pet viewport images were still loading; the final World2 PC preview showed all seven. World1 Limited candidate artwork was not visually accepted during this task. No claim is made about all Pet artwork, Hatch animation, all notification combinations, physical touch hit testing, gamepad selection or production save/rejoin.

The simulator initially rejected setting a mobile orientation on the desktop preset; the desktop run was repeated without that setter. A stale Edit layout after switching devices was repeated with a freshly opened sheet. An initial destruction test expected immediate signals; it was corrected to wait for native deferred notifications. These initial fixture observations are not counted as passing evidence.

## Mobile WinTrophy status and remaining evidence

**Restoration bug: repaired and verified in the isolated tests above. Mobile-only symptom: unconfirmed, not declared resolved.** Manual Parent changes were used; no natural stream-out/stream-in or Stage2 combat Play was observed. Previous instructions against starting/stopping the user's Play were retained.

Live causal diagnosis still needs one correlated trace: server TrophySpawn/send, client receive/adopt or fence rejection, accepted grant, equipment/Handle/GUI presence, restored property values, camera distance/frustum and an actual screen capture at failure. Current saved Stage1/2 equipment settings remain as audited previously; Enabled=true alone is not visual proof. No display qualification was relaxed and no stage/map was made persistent.

The separately identified CombatClient.showTrophy one-shot reward-text lookup remains unchanged: an isolated delayed arrival retained authored +3 Win until an explicit packet replay applied the test +9 Win. This is a known text-refresh limitation, not proof of the missing-equipment cause.

## Cleanup and delivery

All preview GUIs, temporary anchor/fixtures and globals were removed. Device simulation was stopped, returning to the original default viewport; Studio remained Edit. No user Play was started/stopped, no OS input/UI Automation was used, and no Save/Publish, rbxl write, Studio shutdown, production data mutation or real paid action occurred. Screenshots were inspected through the tool and were not saved/committed.

The original unrelated untracked report was left untouched and excluded. Only the six production Sources, focused tests and this task's documentation are included in the normal main commit/push. Canonical Studio remains **unsaved**. The user must manually Save, and Publish when ready for public servers.
