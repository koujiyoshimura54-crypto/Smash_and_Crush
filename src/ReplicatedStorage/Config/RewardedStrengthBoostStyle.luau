-- Pixels at the authored size; uniformly fitted to the current safe viewport.
-- Read at GUI creation. Restart Play after changing these values.
local HUD=require(script.Parent.StrengthHUDStyle)
return {
	Font=HUD.Font, ArmImage=HUD.Assets.Strength,
	White=Color3.new(1,1,1), Yellow=Color3.fromRGB(255,221,38),
	Green=Color3.fromRGB(76,237,39), Red=Color3.fromRGB(230,45,37),
	PanelColor=Color3.fromRGB(18,18,18), PanelTransparency=.18,
	DisplayOrder=50, -- Above game banners, below Roblox CoreGui and the existing menu notice.
	Entry={Width=158,Height=154,LeftGap=14,Top=20,MinScale=.64,MaxScale=1,
		TitleSize=27,FooterSize=30,IconSize=94,IconTop=30},
	Modal={Width=570,Height=480,Edge=18,Radius=18,Border=5,
		TitleSize=52,TitleTop=22,TitleHeight=64,IconSize=210,IconTop=94,
		SubtitleSize=38,SubtitleTop=306,SubtitleHeight=50,
		ButtonWidth=436,ButtonHeight=78,ButtonTop=377,ButtonTextSize=44,
		CloseSize=56,CloseInset=10,StatusTextSize=23},
}
