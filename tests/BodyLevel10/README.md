# Body LV10 isolated validation

Do not deploy these drivers. Install only with tests/FirstBattleTutorial/InstallIsolation.luau after verifying Edit mode, the canonical Place and user-owned Play state. This substitutes memory stores and blocks real purchases; it does not authorize production resets.

Create ReplicatedStorage.__BodyQA with Server/Client BindableFunctions. Native.server.luau and Native.client.luau run in their corresponding native contexts. Behavior.server.luau installs the optional Behavior Bindable after a player is ready. Studio tool require caches are separate; invoke the native Bindables to exercise the running services.

SaveChecks performs synthetic profile/load/write failures using real PlayerDataService and memory storage. States changes fixture levels, then exercises real progression/rebirth/death/placement. Treadmill uses prepared placement and actual TrainingManager gains. Fixtures are not natural progression or real persisted accounts. The final CurrentWorld snapshot field replaces an unused CurrentWorldId diagnostic label; production world state is CurrentWorld.

Stop only the Play started for this task, restore all exact isolation backups, and remove the three Edit QA instances. Never Save/Publish. See reports/BodyLevel10_20261114 for observed results, images, remaining sole clearance and input/render limitations.
