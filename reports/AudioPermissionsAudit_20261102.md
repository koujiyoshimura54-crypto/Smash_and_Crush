# Audio registration and permission audit — 2026-11-02

Follow-up: the canonical Studio subsequently connected and the owner authorized replacement. [Verified findings, nine applied SoundIds and unchanged WallBreak](./AudioReplacement_20261102.md). The initial connection-limited evidence below is retained as history.

## Conclusion and connection limit

**Registered uploads are confirmed. The nine IDs in the preceding canonical Play are the purchased-map IDs, not the user's registered IDs. The current canonical Studio document cannot be certified in this audit because it was not connected.** Re-uploading is not justified by the available evidence.

The requested Place126576845524886 belongs to Universe10765181857, confirmed by the public Place-to-Universe API. The universe belongs to **yossy945, User7467238848**; its root/start Place is101572058398926, which does not replace the requested child Place.

Repeated MCP Studio discovery returned only `MergeToForge_CurrentCloud.rbxl`, PlaceId0/GameId0, in Edit. The previous canonical connection was absent. Asked the owner to connect the intended Studio; no connection became available before recording these findings. Did not open another Place, start Play in the local file, or present its document as canonical. Used its existing signed-in account only for read-only account inventory and asset metadata calls.

## Registered audio and ownership

Authenticated Creator Inventory search (`scope=user, assetType=Audio`) returned11 assets, including all10 supplied filenames plus the unrelated Pause and Hit. The10 relevant assets belong to **yossy945 / User7467238848**, the same owner as the requested universe. MarketplaceService.GetProductInfoAsync confirmed all as **Audio / AssetTypeId3**, registered on **2026-10-01 at11:47:19.994–11:47:23.829 UTC**.

The purchased file `C:\Users\kouji\Downloads\Game\Game.rbxl` was parsed read-only with the existing binary reader. SHA256 `2369cfe1ff4ef2111112bca45e853a9cc33cad0217b3074205820ce2f4bb1f5c` matches the previous audit. Its nine UI/Music IDs exactly match the user's preceding-reference table and the previous canonical tutorial Play's authorization errors. Its WallBreak ID is **107566922588765**, not the MP3 metadata ID100100028436250. This original-file value is **not a claim about the current canonical WallBreak**.

**F** = Fl0ppaDevelopa / **User8709680466** (purchased-map reference owner; different from the game owner).

**Y** = yossy945 / **User7467238848** (registered candidate and game owner).

All assets in the following table are Audio. **Current Full Path/SoundId and fresh loading results remain unverified**; paths/IDs below are explicitly prior canonical references, except WallBreak's original-file reference.

| File | Prior Full Path / reference ID | Reference asset name / owner | Registered candidate ID / name / owner | Loading evidence | Necessary action |
| --- | --- | --- | --- | --- | --- |
| Click.mp3 | `SoundService.UI.Click` / `110783070910373` | Click / F | `138115752460180` / Click / Y | Prior canonical authorization error; fresh test unavailable | Confirm current reference, then registered-ID replacement candidate or permission grant for F's asset |
| Hover.mp3 | `SoundService.UI.Hover` / `70375637366855` | ui-bubble-click / F | `96375954366615` / Hover / Y | Prior canonical authorization error; fresh test unavailable | Confirm current reference, then registered-ID replacement candidate or permission grant for F's asset |
| Notification.mp3 | `SoundService.UI.Notification` / `117918896943222` | Roblox GUI - Notification High / F | `119147718004156` / Notification / Y | Prior canonical authorization error; fresh test unavailable | Confirm current reference, then registered-ID replacement candidate or permission grant for F's asset |
| Success.mp3 | `SoundService.UI.Success` / `132703558395523` | CashGenerator / F | `137104456181758` / Success / Y | Prior canonical authorization error; fresh test unavailable | Confirm current reference, then registered-ID replacement candidate or permission grant for F's asset |
| Winner.mp3 | `SoundService.UI.Winner` / `93441624600336` | winner! / F | `121202237775456` / Winner / Y | Prior canonical authorization error; fresh test unavailable | Confirm current reference, then registered-ID replacement candidate or permission grant for F's asset |
| Cash.mp3 | `SoundService.UI.Cash` / `80878570230928` | Cash / F | `125741903880677` / Cash / Y | Prior canonical authorization error; fresh test unavailable | Confirm current reference, then registered-ID replacement candidate or permission grant for F's asset |
| Error.mp3 | `SoundService.UI.Error` / `137456349421517` | error-011-352286 / F | `76931233259822` / Error / Y | Prior canonical authorization error; fresh test unavailable | Confirm current reference, then registered-ID replacement candidate or permission grant for F's asset |
| Music2.mp3 | `SoundService.Music.Classic Easter` / `92759730216628` | Classic Easter / F | `83679816707559` / Music2 / Y | Prior canonical authorization error; fresh test unavailable | Confirm current reference, then registered-ID replacement candidate or permission grant for F's asset |
| Music1.mp3 | `SoundService.Music.Fun And Games (Sleigh Bells Version)` / `75011432119943` | Fun And Games (Sleigh Bells Version) / F | `134468436646618` / Music1 / Y | Prior canonical authorization error; fresh test unavailable | Confirm current reference, then registered-ID replacement candidate or permission grant for F's asset |
| WallBreak.mp3 | `SoundService.WallBreak` / `107566922588765` **original file only** | lordsonny-small-rock-break-194553 (1) / F | `97452853183370` / WallBreak / Y | No failure inferred; fresh/current reference unavailable | Additional confirmation; no change if already using a working owned asset |

The original-file references all have F as owner and were registered2026-09-20. The ten Y candidates are distinct IDs created together on October1. No same-name asset has been declared the identical waveform solely by name.

## Content-candidate evidence

Read `Downloads\Game\Sounds\*.mp3` with the already-installed ffprobe; used AssetService.GetAudioMetadataAsync for the registered IDs. The duration profiles are consistent, providing evidence beyond filenames. The API returns coarse/integer duration metadata: zero for a subsecond click/hover is **not** a load failure or TimeLength measurement.

| File | Local MP3 duration, seconds | Registered asset metadata duration, seconds |
| --- | ---: | ---: |
| Click | 0.394042 | 0 |
| Hover | 0.500000 | 0 |
| Notification | 1.517698 | 2 |
| Success | 1.812104 | 2 |
| Winner | 1.578957 | 2 |
| Cash | 1.741458 | 2 |
| Error | 0.925708 | 1 |
| Music2 | 122.236984 | 122 |
| Music1 | 141.311995 | 141 |
| WallBreak | 4.048980 | 4 |

**Music1 →134468436646618** corresponds to the141-second file and the prior *Fun And Games (Sleigh Bells Version)* reference. **Music2 →83679816707559** corresponds to the122-second file and *Classic Easter*. Their mapping was not reversed.

No remote audio bytes were downloaded for a waveform/hash comparison; no listening check was performed. Candidates are strongly supported by account ownership, batch timestamps, names and durations, but exact acoustic identity remains unconfirmed. The embedded original IDs supplied by the user were queried as provenance only, never proposed as replacements.

## History and usage evidence

- `GameAsset_Full_Audit_20261001.md`, section17, records the original ten Sound paths/IDs and original triggers. It is a historical purchased-map audit, not today's canonical playback test.
- Git commit `60ea616`, `reports/PerformanceAudit_20261020/Static.json`, records registered Y IDs for Hover, Error, WallBreak, Cash, Click, Winner and Notification among local-file SoundId references. This supports prior registration/import; the aggregate does not identify their Full Paths or prove that the active UI references were replaced.
- No dedicated upload transaction/detailed ID-replacement commit was found by scoped Git message/content searches. Absence of such a record does not mean the upload did not occur; the account inventory directly establishes registration.
- The previous canonical tutorial verification associated with `3386385` emitted **User is not authorized to access Asset** for the nine old UI/Music IDs. Those are prior-play results, not a fresh Preload test for this request. WallBreak was absent from that nine-ID error list; no permission problem is inferred from absence or from its name.
- Fetching main exposed the newer **Y02** audit `e62d8d7`, [RemainingTasksAudit_20261102](./RemainingTasksAudit_20261102/REPORT.md), whose baseline was60e84fd in the same Place. Its native evidence records all nine old IDs with **IsLoaded=false / TimeLength=0** and explicit authorization errors. It identifies Click/Hover/Notification as active, Success/Winner as configured hatch paths, Cash/Error as not demonstrated active, and both BGM instances as not playing with the legacy MusicClient loader disabled. This strengthens the historical comparison, but is another session's Y02 evidence, not a newly connected Y01 test. No new Preload result is claimed.
- Local historical Studio logs also contain those nine authorization errors. No private account credentials or whole logs are copied into this report.

The repository snapshot at3386385 gives the following **static** usage links; the newer Y02 audit above provides additional recorded evidence. The current Y01 Studio's live execution chain is pending connection:

| Source / audio | Evidence and limit |
| --- | --- |
| `ReplicatedStorage.Modules.HUDLayout` → UI.Hover / UI.Click | Purchase-button hover/activation invokes the named Sounds. |
| `ReplicatedStorage.Modules.StrengthHUDPresentation` → UI.Click | Existing button activation calls Sound:Play. |
| `StarterPlayer.StarterPlayerScripts.Services.PetClient` | Starts ButtonClient, NotifyClient and HatchClient; notification/egg integration exists. |
| `StarterPlayer.StarterPlayerScripts.Services.HatchClient` + `ReplicatedStorage.Modules.Config` | knockPath=UI.Click, crackPath=UI.Success, rarePath=UI.Winner; clones and plays the corresponding Sounds. |
| UI.Notification / UI.Cash / UI.Error | The fetched Y02 audit identifies NotifyClient as active, Cash duplicatePath as retained but unbound at Hatch startup, and Error in legacy PurchaseClient with active use unestablished. Not re-read live on Y01. |
| Music.Classic Easter / Music.Fun And Games | Original MusicClient plays the playlist. Previous tutorial audit records the old Main disabled; mere BGM instances/config or load errors do not establish an active playlist today. |
| WallBreak | Original StageClient used the Sound. Current repository CombatClient routes World1 wall clears to ReplicatedStorage.MergeToForge.WallBreakVisualService.Play; its current live Sound reference remains unread. |

No disabled old Main, MusicClient or purchased gameplay system was enabled.

## Permission, moderation and playback distinctions

Marketplace metadata is available for all queried IDs, including the old references and registered candidates. It reports IsPublicDomain=false / IsForSale=false for the old reference set and Y candidate set. These fields do **not** give the target universe's permission-grant list or a moderation decision. No permission ACL, moderation dashboard state or approved/rejected status was directly obtained.

Roblox documents that metadata remains visible independently of usage permission; restricted asset loading checks creator/game access. Its audio documentation describes private-audio sharing and import moderation. See [Asset privacy](https://create.roblox.com/docs/projects/assets/privacy) and [Audio assets](https://create.roblox.com/docs/audio/assets). The same-owner candidate relationship is favorable evidence, **not a substitute for a client load test**.

| Requested runtime evidence | Result in this audit |
| --- | --- |
| PreloadAsync callback status / fresh errors in canonical client | Not run: canonical Studio absent. |
| IsLoaded / TimeLength | Not measured. Audio metadata Duration is not TimeLength. |
| Playback state / advancing TimePosition through existing callers | Not measured. |
| Listening / audible confirmation | Not performed. |
| Current per-universe permission grants / moderation status | Not exposed by the available read tools. |

Once the intended Studio connects, read its current Sounds and exact caller chain first. If it still uses F's IDs, the Y candidates should be checked for content/load before recommending those registered IDs. If an owned candidate is already referenced and loads, no replacement is needed. Permission configuration is an alternative only where the desired asset still lacks access; do not conclude re-upload is required. This audit made no replacements or permission changes.

## Files and preservation

The final comparison is against fetched main2130f5c; only these two audit files are added. Existing upstream work was merged normally without importing it into Studio.

Only this English report and its compact public metadata evidence JSON are added to Git. No Source, SoundId, GUI, permission or publication setting was changed. No uploads, purchases, seller contacts, Play, OS input, layout/camera changes, Save/Publish, rbxl write or Studio exit occurred. No test helper was installed, so none remains. The reachable local Studio stayed in its existing Edit state. The absent canonical Studio's current unsaved state cannot be inspected or certified.
