-- Presentation only; these values do NOT grant event access.
-- Pixels refer to the existing SurfaceGui canvas. Sizes/spacing are canvas fractions.
-- OverheadOffset is studs relative to Diamond01.Area, following equipment movement.
-- Change before Play; all modules cache configuration for the session.
return table.freeze({
 Font=Enum.Font.FredokaOne,
 BoardColor=Color3.fromRGB(24,24,24),BoardTransparency=0.5,
 White=Color3.new(1,1,1),FreeColor=Color3.fromRGB(255,65,65),
 OpenColor=Color3.fromRGB(255,224,102),StrokeColor=Color3.new(0,0,0),
 TitleTextSize=60,FreeTextSize=100,TimeTextSize=52,
 TitleHeight=0.28,FreeHeight=0.38,TimeHeight=0.22,
 RowWidth=0.94,RowGap=0.02,TopPadding=0.04,
 StrokeSizingMode=Enum.StrokeSizingMode.FixedSize, -- Thickness values below are pixels.
 StrokeThickness=2,OpenStrokeThickness=4,
 OverheadOffset=Vector3.new(0,16,-8),
 OverheadSize=Vector2.new(150,44),OverheadTextSize=34,
 OverheadMaxDistance=100,
 RefreshSeconds=0.1, -- Local time polling only; Text writes occur only on changes.
})
