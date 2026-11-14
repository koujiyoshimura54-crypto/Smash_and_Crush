# Stage3 cosmetic grounding checks

Use these only as temporary isolated Studio helpers, never published scripts.

1. Verify canonical Place126576845524886 is Edit; preserve existing content and never stop a user's Play. Install the existing FirstBattleTutorial isolation with exact-source guards (39 redirects in this run).
2. Create ReplicatedStorage.__Stage3GroundQA; install Native.server as ServerScriptService.__Stage3GroundServer and Native.client as StarterPlayerScripts.__Stage3GroundClient. Start an owned Play. Server actions Unlock/Battle/Tap/Back prepare memory LV15/Strength2000 and use the existing Stage3 combat/return paths.
3. Client Ground(false/true) toggles the native module for A/B, Phase(.15) pauses both tracks at matching times, Camera fixes the view, Run restores original speeds, HUD controls temporary UI. Measure.luau runs the native range/pose/nonaccumulation comparison. Inspect real rendered feet and battle/reappearance; check console. Directly played attack poses must be reported separately from authoritative combat notifications.
4. Stop only the owned Play, restore the39 exact isolation Sources, remove the three Edit QA objects and memory/backup. Confirm source/editor/local equality. Leave unsaved Edit; no Save/Publish.

Checks.luau runs30 focused native Edit geometry/scope/lifecycle assertions using the real template outside the DataModel. It does not claim real streaming or rendering.

[Report and limits](../../reports/Stage03GroundContact_20261114/REPORT.md).
