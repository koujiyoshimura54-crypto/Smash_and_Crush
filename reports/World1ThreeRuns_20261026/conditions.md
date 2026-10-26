# Fixed conditions — World1 three-run native Play benchmark

Target: current unsaved Y01 Studio, Universe 10765181857 / Place 126576845524886. Reference Git commit 245a1e7. Start of preparation: 2026-10-26 14:10 UTC (23:10 JST). Current Studio Sources take precedence over Git; no gameplay implementation changes are authorized for this benchmark.

Every preparation/main Play gets a fresh empty in-memory DataStore implementation. Native PlayerData loading supplies the ordinary defaults: Strength 0, level 1 / progress 0, Win 0, rebirth 0, World1, World2 unvisited, capacity 5, AutoTap true, empty owned/equipped inventories and no claimed rewards. No seeded grants or progression. The short preparation Play is discarded in full before run 1. No StudioStartOverride command or API is used. Current Studio automatic override is disabled by its existing setting; that setting is preserved.

Marketplace ownership queries return false for all passes, including VIP, Win multipliers, premium treadmills, speed and other paid perks. Payment prompts are blocked. Badge ownership is empty. The real account's storage/paid receipts and ranking stores are never accessed. No group reward will be claimed using the operator's existing membership. Multipliers begin at 1; normal default speed is 24. Base normal/treadmill gain is 1 per 0.5-second tick; manual training cooldown is 0.25 seconds and manual attack cooldown 0.5 seconds. These values, enemy HP, drop/Egg/merge RNG, prices and rewards remain untouched throughout all runs. Later multipliers must arise from ordinary purchases, equipment or rebirth.

## Standard policy, fixed before runs 1 and 2

- Train on the best normally accessible free treadmill when waiting for the next Stage. Use the UI's displayed RequiredStrength as the initial safe attempt target; adjust only after an observed failure or a change of equipment. Do not require every product to be bought.
- Bank and equip strictly better drops. Consider an Ore merge when its ordinary candidates can improve the equipped Dumbbell; select the fewest useful materials. Item/Pet merge only when surplus eligible copies and their displayed candidates make it useful. Do not merge merely to tick a test box.
- After a lobby return, compare affordable Dumbbell/Aura/Item upgrades by their displayed incremental training or combat benefit per Win. Prefer substantial upgrades over small marginal purchases. Egg spending follows affordable additive upgrades unless the live results make a Pet clearly useful. Claim normally available timed rewards through UI.
- Rebirth only when its ordinary level condition is met and rebuilding the current Strength at the observed equipped training rate is estimated to take at most 90 seconds. Include the actual rebuilding time in elapsed time. Favor unlocking a better treadmill when this rule permits it.
- Use Win StageSkip only through its UI and full payment when it meaningfully saves revisiting cleared stages and current funds support the next productive attempt. Bag capacity upgrades require observed capacity pressure; do not buy every tier automatically.
- Record each actual decision and deviation. Run 2 applies these same criteria to its own random results. Run 3 can revise priorities using the first two runs, with its policy recorded before its clock starts.

## Timing and evidence

Each main clock starts when the fresh player has a living usable character, loaded ordinary data and usable UI. Loading is separate. The finish is the first World1 Stage10 defeat observed in the server's normal EnemyManager state; read-only polling resolution will be disclosed. No reward/combat/purchase/merge internal function is called to progress.

Mutually exclusive time buckets prioritize death/respawn, combat, treadmill training, actual movement, annotated UI operations, then Codex interruption/idle. Growth overlapping movement or Codex activity remains logged and included in total real elapsed time. No estimated human-input correction is used. At 60 minutes record the live state and continue.

Allowed automation: actual UI pointer/keyboard input and ordinary Humanoid movement/jump at the unchanged native speed. Read-only server state/remote receipts and lightweight timestamp logging are permitted. No CFrame movement, numeric grants, HP edits, reset/clear commands, forced RNG, or direct progression service calls.

Temporary isolation and measurement Sources are guarded against their exact installation baseline and restored afterward. No Studio Save/Publish, rbxl writing/copying, user Studio closure, editor-layout, developer-GUI or emulator setting changes.
