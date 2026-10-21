# Persistent Pets entry and readable Egg candidates — 2026-10-21

Target: `C:\Users\kouji\MergeToForge_CurrentCloud.rbxl`. Applied only the two requested UI changes over the completed `41c9e66` and `ee26fa7` state. Existing transparent icons, dumbbell displays, Inventory secrets and World2 arrival locks were preserved.

## Changes and full paths

- Moved the existing `StarterGui.ScreenGui.Left.Inventory` object to `StarterGui.StrengthGui.LeftMenu.PetsButton` in the saved file, with its existing icon `rbxassetid://140192410666130`. The old entry is absent. Added the saved sixth layout slot `StarterGui.StrengthGui.HUD.LeftHUD.PetsButton`, a square aspect constraint and HUDScale. The 144-by-144 design size, outer stroke, background and hitbox now follow the other five entries. The icon uses Fit; the title follows the existing menu typography. See `ObjectChanges.json` for exact object operations.
- `ReplicatedStorage.Modules.HUDLayout`: removed the runtime MountPetEntry cloning/moving implementation. Its existing layout now includes the saved sixth slot.
- `StarterPlayer.StarterPlayerScripts.Services.PetClient`: binds the saved button once to the existing Pet Inventory after MenuClient initialization. Removed the wait for the former entry and runtime mounting. Existing close controls, Pet/Egg startup and purchased Main activation state are preserved.
- `StarterGui.StrengthGui.LeftMenuClient`: includes Pets in the existing hover treatment, using its existing child input button without adding a competing size animation.
- `StarterPlayer.StarterPlayerScripts.Services.EggClient`: replaces the tiny seven-column row with centered rows of at most four candidates inside the existing panel. Images remain square and Fit. Each probability has its own centered, scaled band below the image. Candidate order, odds, panel size, headings and purchase controls are unchanged. The runtime sheet alone is adjusted; shared templates, hatching animation and Pet Inventory cards are unchanged.

The Pets shape problem came from mounting a differently sized purchased entry at runtime instead of providing a saved entry to the common HUD layout. Egg candidates were explicitly reduced to 13% of the panel in both dimensions to fit seven into one row. Inherited probability AutomaticSize also needed disabling so the centered text bands remained correctly aligned.

## Verification

- All four changed Sources compiled. The same rbxl was written in place, decoded again and checked for valid instance references. The writer compared 4,724,966 existing properties, preserved unrelated Sources/properties/parents and removed no instances. Only three layout objects were added. `FileValidation.json` records the hashes and reference checks.
- Reopened that exact file in a fresh verification Studio. All four Sources matched the final repository Sources. The saved Pets hierarchy, sixth layout slot, square geometry, Fit icon and absence of the former entry were confirmed in Edit mode.
- Actual Play at 1365-by-768: all six menu entries measured approximately 122.23-by-122.23 pixels. Normal clicks opened/toggled the existing Pet Inventory; its existing close button worked. Repeated open/close and death/respawn retained one Pets entry and working input.
- Actual Studio VGA emulation at approximately 639-by-480: all six entries measured 74.87-by-74.87 pixels, retaining two columns and three rows. No overlap among the six buttons. The emulator was restored afterward. Physical mobile hardware was not tested.
- Approached the actual World1 Rare Egg in Play and checked its real proximity UI. Seven loaded images retained their order and probabilities (25%, 25%, 25%, 15%, 6.5%, 3%, 0.5%). The images were approximately 99.56 pixels square at a 655-by-410 panel, with probabilities below and no overlap with the opening buttons.
- A fresh Play from the reopened file confirmed World2 Rare Egg's same seven loaded candidates and centered probability bands. At a 1919-by-1080 viewport the candidate frames measured approximately 139.99 pixels square. No mock UI was used for these screenshots.
- Opened the actual Limited Egg through its existing proximity interaction. Its existing four-plus-three ViewportFrame layout already used the candidate area correctly. Seven models and their probability/name bands were visible at the narrow size; viewport cameras fitted the geometry. No Limited Egg, viewport renderer, odds or purchase changes were needed.
- UI checks used a memory-only PlayerData/DataStore and badge substitute in the verification session. No real purchases were made and no production saved data was changed. Production persistence and live payment were deliberately not tested for this UI-only task.
- Play was stopped. All temporary fixture instances were removed and all memory-only Source substitutions restored; the final Edit cleanup reported zero remaining PetEgg instances and zero Sources needing restoration. Verification Studios were closed without Save/Publish. The user's Studio was left open.

Screenshots retained at the user's request: `PetsMenu.jpg`, `RareEgg.png`, `NarrowScreen.png`, `World2RareEgg.png`, and `LimitedEgg.png`. They show the actual running UI. Fixture positioning/camera control was used to reach and frame the existing Egg interactions without changing production progress.

Written file SHA-256: `c7240c9b0fe62e56f4f573020a49cfc72fa57f22a8fc68853e69f530d1ffd654`. No additional rbxl, backup, copy or migration file was created. Studio Save/Publish remains a manual user action. The repository contains the changed Sources, exact object manifest, guarded in-place writer and verification record; the target rbxl remains at its existing location outside the repository.

Final cleanup: both owned verification processes (14016 and 21196) exited. The user Studio process remained open. The target .lock was absent; exclusive file access succeeded and the final SHA-256 remained unchanged.
