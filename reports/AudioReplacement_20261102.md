# Registered audio replacement — 2026-11-02

Follow-up to [the initial ownership audit](./AudioPermissionsAudit_20261102.md). The owner opened the canonical Studio, then explicitly authorized replacement: **「問題なさそうなら差し替えて」**. The initial read-only restriction was observed until that instruction.

## Finding and applied change

Verified live PlaceId **126576845524886**, UniverseId **10765181857**, creator **yossy945 / User7467238848**. Current Studio was read before edits. The registered audio already existed: eight effects were placed under **Workspace.Sounds**, while the active **SoundService.UI** objects still referenced the purchased map's different-owner IDs. The two purchased BGM objects also retained old IDs; the registered Music1/Music2 were not present as authored Sound instances.

The nine old references were owned by **Fl0ppaDevelopa / User8709680466**. All nine failed native client Preload callbacks with **Failure**, IsLoaded=false, TimeLength=0 and explicit **User is not authorized to access Asset** errors. Registered candidates belong to the game owner, were uploaded together on2026-10-01, and match the supplied files' names and duration profiles. All ten registered candidates loaded successfully and advanced TimePosition in temporary muted playback probes.

Changed **only nine SoundId properties**, preserving names, paths, volume, looping, Source, current background music and other edits:

| Changed Full Path | Before ID | Applied registered ID / asset name | Native client after: Preload / IsLoaded / TimeLength |
| --- | ---: | --- | --- |
| `SoundService.UI.Click` | 110783070910373 | **138115752460180** (Click) | Success / true / 0.394042s |
| `SoundService.UI.Hover` | 70375637366855 | **96375954366615** (Hover) | Success / true / 0.500000s |
| `SoundService.UI.Notification` | 117918896943222 | **119147718004156** (Notification) | Success / true / 1.517698s |
| `SoundService.UI.Success` | 132703558395523 | **137104456181758** (Success) | Success / true / 1.812104s |
| `SoundService.UI.Winner` | 93441624600336 | **121202237775456** (Winner) | Success / true / 1.578957s |
| `SoundService.UI.Cash` | 80878570230928 | **125741903880677** (Cash) | Success / true / 1.741458s |
| `SoundService.UI.Error` | 137456349421517 | **76931233259822** (Error) | Success / true / 0.925708s |
| `SoundService.Music.Classic Easter` | 92759730216628 | **83679816707559** (Music2) | Success / true / 122.236984s |
| `SoundService.Music.Fun And Games (Sleigh Bells Version)` | 75011432119943 | **134468436646618** (Music1) | Success / true / 141.311995s |

All replacement assets are **Audio / AssetTypeId3**, owned by **yossy945 / User7467238848**, the same User owner as the universe. Original asset names, timestamps and provenance IDs remain in the initial audit JSON. This manifest is sufficient to reproduce the property-only change; the Before/After mapping is also recorded in `AudioReplacement_20261102.json`.

**WallBreak was already different and healthy:** `SoundService.WallBreak.SoundId=rbxassetid://128974899749995`, *[Block Tales] Defeated Enemy*, owner **Kadestinator / User74012656**, Audio, IsPublicDomain=true. Native Preload succeeded, IsLoaded=true, TimeLength=0.937506s; the existing wall presentation helper advanced playback. **No change was needed or made.** The user's registered `97452853183370` WallBreak remains in Workspace.Sounds, loads at4.048980s, and was not substituted just because its name matches.

No re-upload, permission grant, public/private change, purchase or seller contact occurred. The registered audio works in the canonical client without such changes. Permission ACLs and moderation-dashboard status were not exposed; functional loading is established without claiming a specific moderation label. Exact waveform identity and listening acceptance remain unverified.

## Actual consumers and test boundaries

- Click/Hover: current HUD/button wiring selects SoundService.UI. Native calls through the existing ButtonClient audio helper changed from unloaded/zero progress to loaded/advancing playback.
- Notification: invoked the existing **NotifyClient.pin** route, then closed the test notice. It now advances playback.
- Click/Success/Winner: existing HatchClient startup binds knock/crack/rare to these SoundService objects. Invoked its existing audio helper using a temporary probe; each resulting clone loaded and advanced. No egg purchase, pet grant, full hatch or camera effect was triggered.
- Cash: retained duplicatePath config, not bound by current Hatch startup. Error: legacy PurchaseClient reference; current active invocation not established. Both named SoundService objects were repaired and passed isolated playback checks without enabling legacy systems.
- The two SoundService.Music objects are retained, dormant playlist entries. Their old MusicClient loader remains disabled. Current playing background is `Workspace.Sounds.Sound` / **89468328910114**, *Pause and Hit*; it remained unchanged. Music1 maps to the141.311995s registered asset; Music2 to122.236984s.
- WallBreak: invoked the existing **WallBreakVisualService.Play** on a temporary isolated part, not a real progression/combat operation. The existing selected sound worked before and after.
- Playing=true alone was insufficient: failed old assets could report Playing=true while TimePosition stayed0. Acceptance required successful Preload, IsLoaded, positive TimeLength and advancing TimePosition.
- Existing button/hatch audio helpers were called programmatically through temporary native probes; no OS input or physical button-event acceptance is claimed. Loading, playback-state observation and actual listening are separate; **no auditory confirmation** was performed.

Two short solo Plays used memory-only DataStore/Badge adapters. The first compared existing references with registered candidates; the second verified the actual replaced SoundService objects. All nine replacements and unchanged WallBreak passed after replacement; no target audio authorization failure remained in the second Play log. Tests did not touch production saves or perform real transactions. Probes were local/runtime only; no old Main or disabled system was enabled.

## Preservation and delivery

Stopped Play and restored all nine temporary Source substitutions from exact pre-test copies. Removed all helpers. Verified **462 Sources and script Enabled states unchanged**, and **74 authored Sound IDs/volume/loop settings**, allowing only the intended nine ID differences. Both legacy Main scripts remain disabled. No GUI, camera/window/display setting or other gameplay change was made.

Only this report, its property/verification JSON and a follow-up link in the earlier report are committed. Studio remains open in **Edit with the existing edits and nine replacements unsaved**. No Save, Publish, rbxl write or Studio exit occurred. **The owner must manually Save/Publish.**
