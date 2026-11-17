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
 -- Both rendering and transport use World1WalkwayGeometry.Bounds. Width is
 -- calculated from WidthMultiplier and the actual chevron stroke geometry.
 StartDistance=5, -- Empty entrance margin from the fixed SpawnLocation origin.
 EndClearance=4, -- Inside the existing 5-stud forward wall combat trigger.
 RefreshInterval=0.2,
 GroundTolerance=0.45,
 EndpointTolerance=0.15,
 ExitRearmDistance=1,
})
