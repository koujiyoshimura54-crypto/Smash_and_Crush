# World1 repeated-run Boss visibility — 2026-09-25

## Reproduction and cause

PlaceId 101572058398926, one Studio client/server, isolated Studio DataStore suffixes. The exercised path used real wall/boss combat, real Trophy spawn/physical pickup, the normal lobby reset, and a second combat start.

The first two observed Trophy cycles restored correctly. Repetition with the unchanged weak transparency cache reproduced the reported failure on the next Stage1 attempt:

- TrophyCollected -> TrophyRemoved -> Initialize.
- Initialize cleared defeated and bossSuppressed.
- The shared Stage1 Boss Instance remained identical and SpawnGeneration remained 1.
- At the next BossInitialize, defeated and bossSuppressed were empty, gauge/collider were active, but all three visible parts had LocalTransparencyModifier 1.
- The parts stayed at 1 beyond three seconds. PreSimulation was no longer rehiding them because defeated was already empty.

The actual defect was a weak-key bossVisualTransparency table. The entry holding each part's original local transparency could disappear while the persistent shared Boss Instance remained in use. A later show operation then observed the current hidden value 1, cached it as the original, and restored 1.

## Minimal fix

- Hold the ten shared bosses' part transparency baselines in a normal strong table for the client script lifetime.
- Treat a valid, generation-accepted BossInitialize as the server-authoritative start of the current attempt: clear only that Stage's transient defeated and bossSuppressed, then restore VFX/visuals.
- No shared Boss Destroy/Clone, generation update, server transparency, collider, balance, reward, progression, model, or UI changes.

## Runtime verification

- Stage1 round 1: initial and +3.1s LTM [0,0,0]; second defeat and Trophy pickup succeeded.
- Stage1 round 2: initial and +3.1s LTM [0,0,0]; second defeat and Trophy pickup succeeded.
- Stage2: initial/retry and +3.1s LTM [0,0]; second defeat produced its Trophy.
- World1 Stage1 -> Stage2 continuous: all eight walls and both bosses completed, ending at Stage3.
- LOSE: actual BossResult Result=LOSE Stage=1; respawn returned to Stage1 with empty transient state and LTM [0,0,0].
- World2 Stage1 defeat/reset/retry: nine visible parts remained LTM 0 after 3.1s.
- All measured World1/World2 Boss references remained the original Instances with SpawnGeneration=1.
- Personal collider existed only for the active unlocked Boss and was not included in visual transparency updates.
- Two-client Studio test was unavailable; multiplayer isolation is verified structurally only. The patch remains entirely inside each mount(worldId) client state.

Temporary diagnostics, QA Script/BindableFunction, and isolated DataStore suffixes were removed. A fresh normal Play ran for 30 seconds with empty console output and no temporary instances. Studio returned to Edit and Ctrl+S was dispatched; Publish was not performed.
