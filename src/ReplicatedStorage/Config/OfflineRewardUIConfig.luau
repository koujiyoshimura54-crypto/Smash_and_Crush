-- Client presentation only. Read at client startup; edits apply on the next session.
-- Pixels are design pixels before fitting; MinTapPixels is a screen-pixel minimum.
-- Delivery is separately controlled by EngagementConfig.Offline (ID/Enabled/delay).
return {
	Exit = {
		Enabled = true,
		DisplayOrder = 60, -- Game HUD layer only; never changes/overrides CoreGui.
		Width = 700, Height = 410,
		BandHeightScale = .10, BandMinHeight = 44, BandMaxHeight = 90,
		BandTransparency = .35, BandColor = Color3.new(0, 0, 0),
		TextColor = Color3.fromRGB(255, 221, 35), StrokeColor = Color3.new(0, 0, 0),
		TopTextSize = 52, BottomTextSize = 40, Stroke = 3,
		SafeMargin = 12, CenterMargin = 18,
		Title = {18, 12, 664, 64}, TitleSize = 54,
		Subtitle = {18, 78, 664, 48}, SubtitleSize = 30,
		Icon = {254, 131, 192, 192}, Halo = {248, 124, 204, 204},
		Caption = {18, 332, 664, 60}, CaptionSize = 46,
	},
	Notify = {
		Enabled = true, -- Permission entry; does not require a delivery MessageId.
		Width = 230, Height = 48, MinTapPixels = 44,
		Gap = 8, BottomPadding = 12, TextSize = 27, Radius = 9,
		Color = Color3.fromRGB(35, 139, 230), TextColor = Color3.new(1, 1, 1),
		StrokeColor = Color3.new(0, 0, 0), Stroke = 3,
		CooldownSeconds = 2,
	},
}
