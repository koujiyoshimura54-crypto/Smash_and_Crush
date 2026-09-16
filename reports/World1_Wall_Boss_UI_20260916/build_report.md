# World1 Wall / Boss UI positioning

## Implementation

- Changes are limited to CombatClient, StageWallDisplayClient and two presentation Attributes on the 40 World1 StageSurface instances.
- The existing HP bar was at Y scale 0.65 with height scale 0.19 on a 56.25-stud Wall. Its authored lower clearance is 9.000001475 studs; height is 10.687499866 studs. These measured values are stored as HPGaugeBottomStuds / HPGaugeHeightStuds.
- HP layout is reconstructed from the Wall bottom and these saved values. A later wall-height change does not raise the HP region or the labels.
- StageNumber's lower edge is 1 stud above the HP bar's upper edge. Heading is 0.4 stud above StageNumber. StageNumber / Heading presentation heights are 4 / 2.5 studs.
- Boss UI reuses the next Wall .1 HP region, with the same HP bar vertical bounds. STAGE N sits 1 stud above the bar; BossName is 0.4 stud above STAGE N. Their heights are 3.5 and 6 studs; Stage9's full wrapped name uses 12 studs.
- Stage1–9 use the next Stage .1 wall surface. Stage10 uses its existing Stage10BoundaryWall, referencing Stage10 .4's saved HP baseline. No Map or Gate part was changed.
- Boss UI is enabled from the player's Wall snapshot Current>=5 and current stage, instead of requiring active MiniBoss contact. WallCleared refreshes immediately; BossRecommendation supplies full HP, and BossInitialize / BossGauge continue to use server HP.
- BossResult / EnemyDefeated hide the Boss UI. The existing next Stage .1 immediate Stage/HP display is retained.
- Streaming retry retains received HP when the future wall has not loaded. World2 surfaces are excluded.

## Play evidence

- Used the test player's existing Strength=57; did not invoke reset commands or write test progression values.
- Contacted Wall .1 through .4 in order through the existing server Combat system.
- Wall .4 clear: SubStage=5, IsFighting=false, Boss UI enabled, Ballerina Cappuccina / STAGE 1 / 250 / 250, next Stage .1 hidden, Wall .4 UI hidden.
- Boss contact: IsFighting=true; HP updated to 141 / 250 in the final run. Existing carry/damage logic was not modified.
- Boss victory: CurrentStage=2, Boss UI disabled, Stage2 .1 StageSurface and HP visible with 300 / 300 before touching that wall.
- All 40 enemy Wall StageNumber-to-HP gaps checked within 0.0001 stud of 1 stud.
- All 10 Boss UI targets were observed, including Stage10BoundaryWall.
- Visual screenshot confirmed the complete Boss name / STAGE / bar group on the wall near its existing HP region.
- Final Play Output: no Error, Warning, or Infinite Yield.
- Earlier audit attempts hit AssistantCommand capability restrictions on module creation/require; no game runtime errors were produced. Final implementation uses only the existing LocalScripts.
- Display state is client-local and uses FireClient snapshots for that player. Multi-client simultaneous Play was not run.

## Scope / restoration

Combat order, HP, damage, RequiredStrength, RecommendedLevel, Strength, Balance, wall dimensions, Map and DataStore schema are unchanged.

Apply sources to their existing StarterPlayer.StarterPlayerScripts.Combat paths and restore_ui_metadata.luau only when restoring the baseline snapshot. Existing historical reports remain untouched. Studio Publish was not performed.
