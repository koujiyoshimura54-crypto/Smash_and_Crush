-- World1 permanent route ONLY. Edit in Studio, then restart Play to apply.
-- Speeds are studs/second; distances are studs; Transparency is 0..1.
-- TransportSpeed is added ONCE to normal directional walking, not multiplied.
return table.freeze({
 WidthMultiplier=3,
 Transparency=0.5,
 ArrowSpeed=4,
 ArrowSpacing=3.5,
 SurfaceSampleStep=0.25,
 TransportSpeed=12,
 TransportWidth=7.093475, -- Matches the existing threefold chevron envelope.
 StartDistance=5, -- From the fixed SpawnLocation route origin, not a moving arrow.
 EndClearance=4, -- Inside the existing 5-stud forward wall combat trigger.
 VisualWallClearance=1.5,
 RefreshInterval=0.2,
 GroundTolerance=0.45,
 EndpointTolerance=0.15,
 ExitRearmDistance=1,
})
