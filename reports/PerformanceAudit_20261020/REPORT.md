# Startup and performance investigation — 2026-10-20

## Findings, priority and limits

1. **Startup delay: root cause not established for the user's public session.** The local file reached Studio PlaceIdle in 8.685 seconds from our launch request; isolated local Play reached game.Loaded/character in seconds. Large resident asset/reference collections are a credible startup/memory contributor, but their startup improvement has not been measured. The all-Workspace preload code is **disabled**, so it is excluded as the current executable cause. Live DataStore latency, full public UI/asset readiness and input-ready time remain unmeasured.
2. **Stutter: tutorial route calculation is a confirmed CPU hotspot in the actual-file fixture.** A direct runtime wrapper measured refresh averaging 116.74 ms, peaking at 209.68 ms. Bypassing only that local route path reduced client mean Heartbeat time from 17.22/16.78 ms to 0.87/0.83 ms in A/B/A/B. The user confirms foreground stutter and suspects the arrows. This establishes local causality; it does not establish every source of the public client's ~30 FPS.
3. **First proposed fix: reduce tutorial obstacle/arrow work while preserving its route and completion rules.** Do not begin with an indiscriminate World2 asset deletion, equipment reduction, balance change or Streaming/graphics setting change. No fix is implemented by this investigation.

## Candidate evidence

| Target Full Path | Evidence | Normal measurement | Temporary comparison | Classification |
|---|---|---|---|---|
| `StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient` | Lines 61–65 scan Workspace every floor refresh; lines 96–105 scan all blockers for each candidate arrow; lines 159–176 refresh route, up to 160 arrows; lines 241–245 run every 0.2 s | 8,673 blockers, 24 arrows; refresh mean 116.74 ms / max 209.68 ms. A frames p95 195.26 / 188.28 ms; Heartbeat mean 17.22 / 16.78 ms | Route bypass B: p95 70.89 / 71.82 ms, Heartbeat 0.87 / 0.83 ms. Restoration reproduces A. FPS 8.23/8.33 → 14.96/15.00 in background | **Confirmed CPU hotspot** in fixture; exact foreground improvement unmeasured |
| `StarterGui.StrengthGui.EssentialStudShopClient` | Layout writes card sizes/aspect/CanvasSize then subscribes to AbsoluteSize/AbsoluteContentSize. Engine reports exponential deferred event growth on both Plays | Timed startup: 493 calls, mean 0.439 ms / max 5.429 ms; ~216 ms summed Lua callback time, excluding engine layout work | No permanent or bypass change; two Shop open/close cycles stayed at 493 calls | **Confirmed initialization feedback defect**; sustained FPS impact unconfirmed |
| `Workspace.Ungroup`, `Workspace.Stud Egg & Pet` | Large authoring collections remain in Workspace: 80,198 Instances combined, 8,142 BaseParts, 4,470 MeshParts; no literal Source references found. May still have tag/name/asset dependencies | Static inventory; native Edit process Stats ~3.5–3.7 GB, local Play same-process ~4.9–5.0 GB | Edit detach attempts were render/focus-confounded; physical anchoring test overlapped another exploratory test and is excluded | **Strong startup/memory candidate**, size is not proof of frame-time dominance |
| `Workspace.Map`, `Workspace.MergeToForge`, `ServerStorage.PurchasedCourseOriginals`, `ServerStorage.RBX_ANIMSAVES` | Purchased/original authoring content and animation poses remain alongside live generated maps. ServerStorage content is not ordinary client replication/render content | 3,059 / 13,826 / 24,531 / 10,991 Instances respectively | No valid startup ablation; original geometry not removed | **Candidate**, distinguish server/Edit cost from client rendering |
| `Workspace.World2Map.TrainingArea` effects/world UI, `...TreadmillDisplays` | Existing seven machines and UI; no placement/size change | Serial W2 Play baseline ~14.96 FPS / p95 69.97 ms / client Heartbeat 0.750 ms (background) | Effects off ~14.96 FPS / 0.777 ms; shadows off ~15.00 FPS / 0.722 ms; world UI off in raw record. Background ceiling/stale GPU counters prevent foreground attribution | **No large CPU improvement shown here**; foreground GPU cost unconfirmed |
| `ReplicatedFirst.LoadingScreen.LoadingClient` | Contains Workspace + Assets + StarterGui PreloadAsync pipeline with manual Skip after 10 s and no preload timeout | Actual LocalScript Disabled=true, GUI Enabled=false; no instrumented preload entry ran | Not enabled for the investigation | **Excluded as current running cause**, not a proposed immediate fix |
| `Workspace.Sounds` and other exact sound paths in Static.json | Nine sound IDs fail with permission 403 in native and existing player logs; invalid `Workspace.WinsGift.Wings.Mesh.TextureId` named Images/wd also appears in player log | Startup bursts, not a demonstrated continuous error storm. Specific sound paths are recorded | No sound/asset change; exact load-delay contribution unmeasured | **Confirmed bad assets**, startup/FPS contribution unconfirmed |
| Host foreground/FPS controls | Initial WMI CPU 80%, later 36%; RTX5060Ti used. Existing player/Studio plus FPSRunner and other apps. Raw FPS caps -1, not an explicit 30 | Edit observed ~14.79 FPS in background and 58.83 after successful foreground focus; user says public stutter continues foreground | No driver/FPS/quality/power/process setting changed | **Background throttle confirmed for audit**, public foreground ~30 cap vs load remains unmeasured |

## Timing boundaries and cache conditions

The file hash is `08c9434ec97c3f705c7454744d5355eba6589bb118c88b24f9f8d1c525ee7766` before and after. The actual file, not Git Source existence, was scanned (182,118 Instances / 420 Source containers / 6,376,043 bytes). Initial repo HEAD was 45a9c1a. Existing unrelated edits/untracked files were retained.

| Interval | Start / end criteria | Observed duration | Qualification |
|---|---|---:|---|
| Studio process launch → idle | Windows launch request 00:02:12.5676022Z → owned Studio log PlaceIdle 00:02:21.253Z | 8.6854 s | First audit open; OS/asset caches not cleared, not a cold-cache benchmark |
| Studio open pipeline | OpenPlaceInitialization 00:02:16.910Z → PlaceIdle 00:02:21.253Z | 4.343 s | Includes creation/streaming/postload; not isolated disk Decode |
| Open streaming wait | OpenPlaceWaitForStreaming 18.661 → OpenPlacePostLoadDataModel 19.707 | 1.046 s | Studio telemetry stage names |
| First Play initialization → idle | PlaySoloInit 00:08:52.108 → PlaySoloIdle 00:08:56.342 | 4.234 s | Actual local Play, all DataStore handles replaced with in-memory adapter |
| First client data model loaded | ReplicatedFirst monitor → game.Loaded | 0.7041 s | Does not mean UI/assets/data/input fully ready |
| First character | ReplicatedFirst monitor → CharacterAdded | 2.1197 s | Character event, not an actual movement test |
| Repeat Play initialization → idle | 00:17:58.193 → 00:18:02.487 | 4.294 s | Same session, warmer caches, added scoped timing wrappers |
| Repeat client loaded / character | ReplicatedFirst monitor → corresponding events | 0.6521 / 2.2035 s | Same boundary as first Play |
| Repeat PlayerData.Load | Actual Load call entry → return | 0.288 ms | **Memory adapter only**, not real DataStore latency |
| Public client observed join events | Existing engine `GameJoinLoadTime.join_time` reports | 3.2945 / 0.5253 s | First/second observed joins in log, not proven cold/warm caches; neither measures full operation readiness |
| Public initial snapshot timers | Existing engine Join snapshot timer reports | 3.3654 / 1.6911 s | Separate engine timer, not added to join_time |
| Every Service/UI ready, all assets finished, loading screen exit, first usable input | No complete common readiness boundary exists/was instrumented | **Unmeasured** | Custom loading screen inactive; actual safe fixture movement/purchases not tested |

Public player logs identify **PlaceId 101572058398926**, UniverseId 10765181857; the requested Cloud target is **126576845524886**. The local file opens as PlaceId/GameId 0. Exact local/public content identity cannot be established. A public-client join/profiler reproduction at the intended published Place is still required. No Cloud or target was republished.

## Environment and measurement controls

CPU i5-11600K (6C/12T), RAM ~31.86 GiB visible (~18.09 GiB free initially), GPU RTX5060Ti with 8,151 MiB total according to nvidia-smi (WMI AdapterRAM is truncated and is not used). Desktop display 1920x1080/60Hz; power plan Razer Cortex Power Plan. Actual NVIDIA D3D11 adapter confirmed in logs. Player saved graphics is Automatic (raw 0), Studio saved play quality raw 5; Studio rendering Level10 / EditQuality Automatic. Effective public in-game settings, driver/overlay frame caps and exact public render resolution remain unmeasured. FPSRunner was observed but its settings were not read or changed. Five-second per-process CPU delta evidence is separate from misleading cumulative CPU totals.

Local Play viewport was 1366x767. Audited Plays were background after focus could not be held; their ~15 FPS idle ceiling and lower FPS under CPU work are **not** the foreground client ~30 FPS benchmark. Six-second samples use two-second settle. Tutorial A/B/A/B preserves camera, viewport and other features; only the locally visible tutorial-completion condition is toggled to isolate route work, then restored. Server completion/real data is never changed. Direct refresh profiling times the unchanged real LocalScript implementation, including its normal route checks.

Edit source scripts do not execute like Play scripts, so tutorial CPU work cannot explain Edit-mode load by itself. Edit has the authoring map/reference/GUI geometry plus Studio/plugin/asset work. Exploratory Edit render stats went stale (identical scene counters after camera changes, framebuffer 396x222/680x382 inconsistent with viewport); their draw counts/GPU values and focus-confounded cases are not accepted. GPU zero / unavailable timings are **not** zero GPU cost. No MicroProfiler dump or full Script Profiler capture was obtained. Actual Luau function timing and engine Stats sampling were used where valid.

An early server-anchoring exploration overlapped an early visual exploration. Those two raw records are explicitly marked **excluded** for causal isolation; they are not normal A/B results. The later tutorial A/B/A/B and World2 serial cases occurred after they completed. Low server physics samples do not establish that all assemblies are cheap under all conditions. No group was permanently removed, anchored or hidden.

## Asset/map inventory (file, not dynamically streamed count)

| Full Path | Instances | BaseParts | MeshParts | Unanchored | ParticleEmitters | Billboard/Surface GUI |
|---|---:|---:|---:|---:|---:|---:|
| `Workspace.GeneratedMap.TrainingArea` | 2,685 | 954 | 0 | 0 | 0 | 0/0 |
| `Workspace.GeneratedMap.BattleCorridor` | 13,722 | 3,431 | 0 | 0 | 0 | 0/40 |
| `Workspace.World2Map.TrainingArea` | 4,642 | 1,239 | 211 | 0 | 82 | 35/14 |
| `Workspace.World2Map.BattleCorridor` | 10,675 | 2,232 | 400 | 0 | 0 | 0/40 |
| `Workspace.Ungroup` | 48,757 | 3,472 | 816 | 3,219 | 883 | 5/0 |
| `Workspace.Stud Egg & Pet` | 31,441 | 4,670 | 3,654 | 4,447 | 135 | 12/0 |
| `Workspace.Map` | 3,059 | 1,289 | 0 | 0 | 0 | 0/0 |
| `Workspace.MergeToForge` | 13,826 | 3,510 | 0 | 0 | 0 | 0/40 |
| `Workspace.Leaderboards` | 3,529 | 52 | 0 | 0 | 0 | 2/10 |
| `ReplicatedStorage.Assets` | 1,302 | 347 | 136 | 153 | 161 | 8/0 |
| `ServerStorage.PurchasedCourseOriginals` | 24,531 | 6,259 | 240 | 0 | 0 | 119/40 |
| `ServerStorage.RBX_ANIMSAVES` | 10,991 | 0 | 0 | 0 | 0 | 0/0 |

Workspace contains 135,136 file Instances. Broad authoring collections include poses/keyframes as well as parts; their Instance totals are not a draw-call ranking. The entire file has 3,957 unique MeshId values / 6,571 references, 501 distinct Texture-property strings / 36,511 references, plus Image, mesh TextureID/TextureId and SurfaceAppearance maps separately in Static.json. References are not unique texture byte sizes; no mesh polygon count, texture dimensions/compressed bytes or per-asset VRAM estimate is fabricated. The large pose/keyframe collections inflate Instance/storage cost without being equivalent to drawn triangles.

Streaming is already enabled: MinRadius 64 / TargetRadius 1024, default model behavior fields. Both World roots' nonspatial metadata/other replicated services differ from spatially streamed BaseParts. Runtime actual-client primitive samples differed (~9,361 in W1 vs ~12,671 in W2); that is consistent with different streamed residence, not proof that an entire other World is unloaded. World2 fixture InstanceCount ~155,287 vs W1 ~140,262 includes metadata/UI; same-process Stats memory near 4.9–5.0 GB includes local server/client/editor, not separate retail-client RAM. No Streaming setting was changed.

Detailed per-group counts cover BaseParts/MeshParts, Anchored, collision/transparent/shadow flags, effects, constraints, lights, billboards/surfaces/viewports and Script enabled flags. A root's enabled particle count outside Workspace does not mean it is rendering. Static Source name matches are not a dependency-complete proof that a reference library is unused; any later removal requires tag/name/template dependency checks.

## Script and longer-term observations

- Tutorial refreshes its whole Workspace blocker list every two seconds, then scans all blockers for every arrow every 0.2 seconds. Spatial broad-phase/cached local candidate lists and updating only after meaningful player/target movement are candidate fixes; preserve floor-only drawing and server-owned completion.
- Shop layout feeds AbsoluteContentSize/AbsoluteSize changes back into card/aspect/canvas writes. Both native Plays emit the engine's exponential event-growth error; one timed startup invokes it 493 times. Repeated open/close did **not** increase that count in two cycles. Treat it as a real initialization feedback defect, not a proven growing leak.
- CombatClient mounts both World streams, has a PreSimulation collider/wall maintenance pass and 0.5-second retries, plus World1 overhead rendering. Frame-time attribution after tutorial removal remains unmeasured. This code is a secondary profiling target, not a confirmed culprit.
- PetFollowClient has a guarded single start and one-equipped-Pet loop; EggClient animates registered Eggs on RenderStepped, FloatClient animates cached boards on Heartbeat. Their ModuleScript presence does not establish live activity. Purchased Main/client Main are disabled in this file; no equipped Pet was present in the fresh memory fixture. Pet/egg/hatch activation/open-menu load and world-return accumulation were not benchmarked.
- Treadmill registry/occupancy uses the existing throttled scheduler; no per-frame global GetDescendants was found there. Training gain, mount or purchases were not used for this performance test.
- Permission-denied sound bursts and a missing named texture are confirmed. No game-script timeout or demonstrated unbounded asset-retry loop was established. Assistant-tool/Core UI warnings are separated from game errors. The initial malformed diagnostic command is recorded as a tool error and no sample from it is adopted.
- Short A/B windows did not show large tutorial-correlated memory growth, and two Shop cycles did not increase layout calls. These observations are not a long-run leak test; equipped-Pet, UI-menu repetition and repeated World round trips remain unmeasured.

## Proposed fixes, ordered by current evidence (not implemented)

1. **Tutorial obstacle query/refresh work:** use a spatially local/cached candidate set and dirty/movement-driven refresh instead of every-arrow scanning of thousands of blockers. Preserve existing arrows, floor exclusion, route and completion semantics. Measured full-route bypass saves ~15.9–16.4 ms mean client Heartbeat and ~116–124 ms p95 in background; **actual optimized implementation benefit is unverified**, not a promise to reach 60 FPS.
2. **Shop layout feedback:** debounce/guard unchanged size writes and separate sizing from canvas-only updates; avoid the current content-size→card-size loop. Design/function can stay the same. 493 calls / ~216 ms summed Lua work and repeated engine cycle errors establish wasted initialization; exact startup/FPS gain unverified.
3. **Authoring/reference asset separation:** after confirming dynamic dependencies, keep unused purchased libraries/course originals out of live Workspace/replicated startup content and retain only required runtime templates. Intended appearance unchanged, but missing-template risk requires targeted verification. Large inventory/memory footprint measured; valid time/VRAM improvement is unmeasured. ServerStorage cleanup affects Edit/server/storage, not automatically client rendering.
4. **Repair/replace unauthorized sounds and broken named texture:** use authorized existing assets or stop requesting unavailable content. Audio/texture appearance may change; no measured FPS gain, startup wait improvement unverified.
5. **Foreground retail profiling after #1:** capture CPU/GPU/MicroProfiler at both Lobby cameras on the intended Place, using the actual FPS cap, graphics level and resolution. Then isolate Combat maintenance, World2 effects/UI and Pet/egg presentation as indicated. Do not reduce seven treadmills or geometry blindly. No foreground improvement established for graphics changes here.

The next decisive missing measurement is a foreground retail-client frame trace on the intended published Place, including an arrows-visible versus arrows-hidden comparison at the same position and quality. It must record effective FPS/driver/overlay cap and per-frame CPU/GPU. Live DataStore acquisition and actual input-ready timing need a separately instrumented **read-only/non-writing** data-access session; this investigation does not substitute a memory adapter for those measurements.

## Safety, restoration and evidence

Only a separately started owned Studio PID 27720 was instrumented. Before both Plays every Source that obtains DataStoreService was redirected in memory to a Studio-only in-memory adapter (six containers, including the explicit production-reset handle, ProfileStore, receipt/intent and leaderboard stores). Original account data was not read, changed, reset or purchased; no Marketplace purchase/Badge award/production or Studio DataStore call was requested. World2 visit moved only the disposable in-memory fixture through existing EnemyManager activation and actual Spawn; it was not a Gate/unlock acceptance test.

Both Plays were stopped; Edit was confirmed; eight temporarily changed Sources were restored and equality-checked. Temporary mock/monitor/runtime objects were gone, parent detaches restored, and original camera CFrame/Focus/Type restored. Only the verified owned Studio was closed; normal close reached a Save dialog, so its owned process alone was terminated **after** Stop/restoration without saving. Its PID-matching stale lock was removed. No close was sent to the user's Studio/client or other applications.

Studio's own automatic recovery ran once at 00:07:20–22Z before Play. It created `AppData/Local/Roblox/RobloxStudio/AutoSaves/MergeToForge_CurrentCloud_AutoRecovery_0.rbxl`; creation and write timestamps both matched this audit event. That newly created audit recovery file was removed after verification. No Save/Publish command or alternate working rbxl was issued. The original target SHA256 is unchanged. No persistent gameplay, balance, Source, layout, physics, rendering setting or ownership/save change was made. Detailed EnvironmentAndRestoration.json records these exceptions precisely.

Evidence: Static.json (actual-file groups/Source matches and blocked sound Full Paths), TutorialABAB.json, TutorialDirectProfile.json, ShopLayout.json, World2Serial.json, EnvironmentAndRestoration.json, HostCpuSample.json and sanitized LogSummary.json. EditExploratory/PhysicsExploratory/VisualExploratory retain excluded exploratory observations with explicit qualification. No raw account payload, private join identifier or server IP is published.
