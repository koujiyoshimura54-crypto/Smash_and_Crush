# Tutorial floor-only arrows — 2026-09-16 (Play verification pending)
Baseline origin/main:8dfeed4, clean before work; pull fast-forwarded fromdc4c510.
Studio PlaceId:101572058398926.
Only TutorialGuideClient source changed. Map/Training/Treadmill Guide/Multiplier Billboard/Tutorial progression/DataStore unchanged.

Previous floors: all workspace descendants named Floor/Baseplate/Ground/TrainingZone/ConnectorFloor plus Terrain, Include raycast ignoring assets.
New floors: exact GeneratedMap TrainingArea.Floor, LobbyCorridorConnector.ConnectorFloor, NextWorldArea.Floor and direct Stage/main/substage Floors. No arbitrary name-only descendants, TrainingZone, Terrain, character, enemy, UI or runtime visual as floors.
Arrow center, endpoints/midpoints/width edges must all hit floor at the same level and not intersect visible asset oriented bounds between floor and original castTop. Conservative bounding boxes hide rather than elevate. Nonquery mats are checked geometrically. Nearby candidate broadphase avoids repeated detailed asset tests.
All route/geometry/timing/progression code retained.

Edit measurement: open floor (28,2,-100) true; Tredmill01/02/04 false; Stage1.1 Wall false; SpawnLocation floor position false as an asset (expected).
Initial pre-final Play revealed Terrain container's bounds incorrectly blocked arrows; excluded Terrain and added candidate broadphase.
Final source is installed and matches sources/TutorialGuideClient.luau.
Final Play NOT completed: Assistant plugin version change warnings, Client bridge unreachable, subsequent Play start stuck "Start play hasn't finished yet" while studio state Edit. No successful final runtime/character/enemy/shared runtime-mat verification claimed.
No commit or push pending final Play. No Publish. No reset command or data writes executed.

## Resumed final Play after Studio restart — Completed

The pending results above record the original bridge failure; the restarted Studio completed final Play normally.
Reopened TutorialGuideClient contains the final floor-only implementation.
Initial tutorial target remained Treadmill, Level=1, TutorialCompleted=false.
Actual route: 28 Chevron pairs, 14 shown and 14 hidden; all shown arm parts at Y=2.055, floor height errors=0.
All 10 floor/asset probes passed: open floor before and after shown; Tredmill01/02/04, nonquery group mats 3/5, Wall, Character and Enemy hidden.
All 3 tested elevated treadmill panel parts hid arrows.
Actual live route visibility matched expected floor-only results at every pair: mismatches=0. Floor display resumed at indices 19, 23 and 26 after hidden intervals.
Console output empty: no Error, Warning or Infinite Yield observed during this final Play.
Play stopped after verification. No reset command, explicit DataStore write test or Publish executed.
Tutorial completion was not played through; progression, route and arrow geometry/timing remain unchanged.
Detailed probe output: play_evidence.json.
