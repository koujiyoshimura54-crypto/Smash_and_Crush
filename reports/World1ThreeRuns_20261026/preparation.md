# Preparation Play — discarded before run 1

Started in an empty memory store at approximately 2026-10-26 14:17 UTC. Ordinary native data loading produced Strength 0 / level 1 / Win 0 / rebirth 0 / empty inventory / capacity 5. VIP, Win and rebirth multipliers were all 1, speed 24, Auto true, World2 unvisited and StudioStartOverride false.

- Ordinary Humanoid MoveTo moved the real character from the spawn to a nearby point, then to Normal02 treadmill at unchanged native speed. No CFrame assignment or path bypass was used.
- Real Windows pointer clicks toggled the existing Auto UI OFF and ON; the server attributes reflected both actions.
- Normal02 started ordinary training. Native server state showed Strength 38, then 100 after actual elapsed training and movement. No value was granted by the harness.
- Ordinary forward movement reached the Stage1 walls. The rendered client showed Wall1 cleared and Wall2 at 118/125 HP from normal automatic combat/carry, with Strength 107. This established combat input/condition operation.
- One direct plugin-context wall-state read disagreed with the native game because plugin require caching is separate. It was not used as progress evidence. All main-run wall/defeat reads use the native Script recorder, sharing the game's actual module context.
- Preparation was stopped and its whole memory store/runtime state discarded. No part is included in a main-run time or carried over to run 1.

Current renderer and UI input work at the existing 1279×720 game viewport. The initial Studio window was already visible/maximized. No rendering/device/editor setting was changed.
