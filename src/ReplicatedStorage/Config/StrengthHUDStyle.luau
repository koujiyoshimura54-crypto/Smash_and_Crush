-- Measured in pixels from the 1676 x 938 owner reference (2026-11-01).
-- HUDLayout scales this design uniformly; no gameplay/economy values live here.
return {
 Font = Enum.Font.FredokaOne,
 Text = {
  Item = {Size=31, Stroke=3.5}, Health = {Size=41, Stroke=3.5},
  Strength = {Size=57, MinSize=48, Stroke=4.5},
  Level = {Size=54, Stroke=4}, Progress = {Size=48, Stroke=4},
  Pack = {Size=55, Stroke=5},
  AutoTitle = {Size=19, MinScreenSize=13, Stroke=2}, AutoState = {Size=27, MinScreenSize=19, Stroke=2.5},
  OfflineTitle = {Size=58, Stroke=4}, OfflineAmount = {Size=60, Stroke=4},
  Claim = {Size=38, Stroke=3}, DoubleClaim = {Size=32, Stroke=2.5},
  Price = {Size=25, Stroke=2}, Close = {Size=44, Stroke=3},
 },
 Geometry = {
  Reference = Vector2.new(1676,938), Width=876, Height=294,
  CenterOffset=8, Bottom=32, Edge=12,
  ItemY=0, ItemHeight=60,
  ItemRowX=74, ItemRowWidth=728, ItemColumns={0,244,510},
  ItemIcons={72,66,76}, ItemTextOffsets={60,68,86},
  HealthX=68, HealthY=72, HealthWidth=336, HealthHeight=52,
  HeartX=-30, HeartY=-9, HeartSize=70,
  StrengthX=430, StrengthY=51, StrengthWidth=446, StrengthHeight=84,
  ArmSize=96, StrengthTextX=96, StrengthTextWidth=350,
  LevelY=137, LevelHeight=66, LevelInset=30,
  PacksY=216, PackHeight=78, PackGap=8, PackIconSize=100,
  AutoGap=12, AutoWidth=88, AutoHeight=66, AutoMinTouch=56,
  BadgeHeight=28, BadgeGap=8,
 },
 Border = {Gauge=5, Pack=5, GaugeRadius=17, HealthRadius=12, PackRadius=5},
 Offline = {
  Width=700, Height=450, MarginX=32, MarginY=48, Border=6, Radius=16,
  Title={24,12,652,68}, Icon={254,91,192,192}, Amount={18,290,664,64},
  Halo={248,84,204,204}, HaloColor=Color3.fromRGB(255,214,35),
  ButtonBorder=4, ButtonRadius=9, PriceIconSize=24, PriceGap=5,
  ClaimColors={Color3.fromRGB(213,255,0),Color3.fromRGB(86,238,0)},
  DoubleColors={Color3.fromRGB(255,239,0),Color3.fromRGB(255,160,0)},
  Claim={22,358,320,76}, Double={358,358,320,76},
  CloseInset=8, CloseSize=64,
 },
 Colors = {
  Text=Color3.new(1,1,1), Outline=Color3.new(0,0,0),
  EmptyTop=Color3.fromRGB(55,55,55), EmptyBottom=Color3.fromRGB(32,32,32),
  LevelTop=Color3.fromRGB(255,238,0), LevelBottom=Color3.fromRGB(255,156,0),
  HealthTop=Color3.fromRGB(255,47,59), HealthBottom=Color3.fromRGB(218,0,8),
  HealthEmpty=Color3.fromRGB(76,18,24),
  Packs={
   {Color3.fromRGB(255,210,0),Color3.fromRGB(255,164,0)},
   {Color3.fromRGB(195,52,255),Color3.fromRGB(139,0,238)},
   {Color3.fromRGB(255,45,52),Color3.fromRGB(244,0,7)},
  },
 },
 Assets = {
  -- Existing owned image, also used by Workspace.Treadmills.Billboard.
  Strength="rbxassetid://106106287008236",
  Heart="rbxassetid://79503513671021",
  Robux="rbxassetid://100116824861927",
  HeartTint=Color3.fromRGB(255,170,85),
  -- Purchased Shop card StudPattern, four embossed squares per tile edge.
  Studs="rbxassetid://97016358865650", StudCell=128, StudSize=32,
  StudSpacing=53, StudOrigin=Vector2.new(15,-5), StudColumns=5, StudRows=2, StudTransparency=.55,
 },
}
