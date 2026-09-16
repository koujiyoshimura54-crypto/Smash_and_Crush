# World1 Wall UI scale and persistent HP — 2026-09-16

## Scope / baseline
- main was clean at 34fd3cb985ae912c8c79ee70ad3c96ee979825cb; origin/main pull reported up to date.
- Studio PlaceId 101572058398926. No Publish.
- Reviewed 28bc4f1 parent and reports/Miniboss_UI_Wall_Surface_20260916. Original 27-stud Wall used FixedSize 580x270; HPBar Y=.65, height=.19, lower clearance=.16.
- Increasing physical height to56.25 without canvas adjustment stretched vertical pixels by56.25/27=2.08333. Previous fix preserved the already enlarged10.6875-stud HP height, so was insufficient.

## Final implementation
- Existing SurfaceGui remains on Wall face. CanvasSize=580 x (wall.Size.Y*10), preserving original0.1stud per vertical canvas pixel; horizontal canvas/physical width unchanged.
- HP lower clearance4.32stud; height5.13stud. Wall StageNumber height6.75stud / Heading4.32stud. StageNumber bottom1stud above HP; Heading gap.4stud.
- Boss STAGE height3.5stud; name6stud (Stage9 full wrapped name12stud). Boss HP shares the Wall bar region. Stage1-9 next Stage .1; Stage10 existing boundary wall.
- Removed previous UI-only HPGaugeBottomStuds/HPGaugeHeightStuds metadata on40 StageSurfaces. Physical Parts unchanged.
- Current target .1-.4 is visible from authoritative snapshot, independent of contact/Fighting. Future/cleared surfaces hidden. Direct Enabled update avoids waiting for deferred AttributeChanged signals.
- EnemyManager only adds two presentation payload fields: WallCleared.State=existing GetSnapshotForStage after ApplyDamageForStage, and BossRecommendation.Current=existing personal gauge.
- Client installs full post-Carry snapshot before rendering. No HP initialization, consumption, damage calculation, carry or progression changes.
- Boss QueueDamage only reserves damage. Existing Begin applies it on contact (including lottery route-specific floor). Unlock HP therefore remains the true pre-contact HP, not a speculative post-Carry preview. No early Begin, lottery evaluation, or duplicate subtraction introduced.

## Verification
### Normal Stage1 Play, original Strength57 unchanged
- Stage1 .1:100/100 visible, future .2-.4 hidden.
- .1 clear -> untouched .2:111/125.
- .2 clear -> untouched .3:147/150.
- .3 clear -> untouched .4:176/200.
- .4 clear -> IsFighting=false, Ballerina Cappuccina / STAGE1 / HP250/250 visible on Stage2 .1; all Wall bars hidden.
- Boss contact: BossInitialize.Current198 (queued52 applied), then BossGauge141,84,27,0; client matched each packet.
- Defeat -> Stage2 .1 enabled and300/300 before contact; Boss UI removed.
- Full normal sequence repeated, and callback-time evidence captured.

### Isolated high-Damage Play fixture
- Normal Server execution used unchanged Stage1WallManager with fake per-player state (SetAttribute no-op). Actual Player Strength, Stage attributes, saved data were not changed.
- Damage131 advances to .2:94/125, .3:113/150, .4:182/200, then51/200, then unlock with pending remainder80.
- Real client received the resulting post-Carry WallCleared snapshots. On each clear, only the correct surface/bar was enabled with94,113,182 respectively; no full-health target flash.
- Damage300 bypasses Wall1+Wall2 and leaves Wall3=75/150; verified against the existing server state.
- Fixture UI state was restored with existing SendState. Temporary fixture source and observer removed by Stop/final source restore.
- This is an isolated high-Damage test, not a change to production Damage/Strength or a multiplayer session.

### Layout / limits
- All40 Wall parts retain height56.25; runtime bar height5.13, bottom4.32, Stage gap1 within.001stud.
- Checked all10 Boss GUI destinations, including Stage10BoundaryWall.
- Screenshot inspected on mobile landscape; SurfaceGui remains on the wall.
- Multi-client concurrent test and Stage10 full combat were not run; all stages share the same local target rendering.
- Final game console during complete Play: no Error/Warning/Infinite Yield. Tool attempts to create temporary Scripts were rejected by Assistant capability and did not become game scripts; fixture ran through temporary existing module source instead.
- No DataStore command/reset, Balance/World2 changes, or Publish.

## Files
- CombatClient, StageWallDisplayClient, EnemyManager (UI notification payload only).
- GAME_SPEC, UI_SPEC, DEV_STATUS, CHANGELOG.
- before/ contains untouched starting snapshots; sources/ contains final sources; play_events.json contains HP/UI-only evidence.

