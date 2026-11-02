local Config={}
Config.Order={"Pink","Purple","Yellow","Green","Blue","Red"}
Config.Auras={
["Pink"]={VisualTemplate="Pink_Aura3",Id="Pink",Key="Pink",DisplayName="Pink Aura",Name="Pink Aura",Icon="rbxassetid://110843600021702",StrengthBonus=5,PurchaseType="Win",Price=30,Order=1,Tint=Color3.new(0.9411764740943909,0.3607843220233917,0.686274528503418)},
	["Purple"]={VisualTemplate = "Purple_Aura1",Id="Purple",Key="Purple",DisplayName="Purple Aura",Name="Purple Aura",Icon="rbxassetid://113527186215193",StrengthBonus=10,PurchaseType="Win",Price=75,Order=2,Tint=Color3.new(0.6666666865348816,0.3607843220233917,0.9607843160629272)},
	["Yellow"]={VisualTemplate = "Yellow_Aura1",Id="Yellow",Key="Yellow",DisplayName="Yellow Aura",Name="Yellow Aura",Icon="rbxassetid://115006077417349",StrengthBonus=30,PurchaseType="Win",Price=200,Order=3,Tint=Color3.new(0.95686274766922,0.772549033164978,0.21568627655506134)},
	["Green"]={VisualTemplate = "Green_Aura1",Id="Green",Key="Green",DisplayName="Green Aura",Name="Green Aura",Icon="rbxassetid://72326661519750",StrengthBonus=500,PurchaseType="Win",Price=25000,Order=4,Tint=Color3.new(0.26274511218070984,0.8039215803146362,0.4470588266849518)},
	["Blue"]={VisualTemplate = "Blue_Aura1","Blue_Aura2","Blue_Aura3",Id="Blue",Key="Blue",DisplayName="Blue Aura",Name="Blue Aura",Icon="rbxassetid://104827909443134",StrengthBonus=1500,PurchaseType="Win",Price=250000,Order=5,Tint=Color3.new(0.2549019753932953,0.6039215922355652,0.9764705896377563)},
	["Red"]={VisualTemplate = "Red_Aura1",Id="Red",Key="Red",DisplayName="Red Aura",Name="Red Aura",Icon="rbxassetid://86956843606297",StrengthBonus=500,PurchaseType="GamePass",GamePassId=1975173075,DisplayPriceFallback=100,Order=6,Tint=Color3.new(0.9333333373069763,0.2549019753932953,0.2980392277240753)},
}
local World2=require(script.Parent.World2GameplayConfig)
local visualOrder={"Pink","Purple","Yellow","Green","Blue","Red"}
for index,row in ipairs(World2.Auras) do
 local aura=table.clone(Config.Auras[visualOrder[index]])
 local id=string.format("W2_AURA_%02d",index)
 aura.Id=id;aura.Key=id;aura.WorldId=2
 aura.StrengthBonus=row.StrengthBonus;aura.Order=#Config.Order+1
 aura.PurchaseType=row.GamePassId and "GamePass" or "Win"
 aura.PurchaseEnabled=row.PurchaseEnabled;aura.Price=row.PriceWin
 aura.GamePassId=row.GamePassId;aura.ProductId=nil;aura.DisplayPriceFallback=row.BasePrice
 -- Keep the original saved IDs and bonuses for owners of retired Win Auras.
 aura.Listed=false;aura.LegacyOwnedOnly=true
 Config.Auras[id]=aura
 if index==6 then
  aura.Name=row.Name;aura.DisplayName=row.Name;aura.Icon=row.Icon;aura.IconFallback=row.IconFallback
  aura.VisualTemplate="Eclipse_Aura1";aura.VisibleWorld=2
  aura.Listed=true;aura.LegacyOwnedOnly=nil
  -- Modest, editable presentation; all textures already used by existing Auras.
  aura.VisualSettings={
   Kind="Eclipse",DarkColor=Color3.fromRGB(18,3,33),FlameColor=Color3.fromRGB(126,20,222),
   GoldColor=Color3.fromRGB(255,194,35),EmitterSize=Vector3.new(3.2,2,2),ZOffset=.5,
   FlameTexture="rbxassetid://10428805046",DarkTexture="rbxassetid://2360242557",
   FlameSize=2.9,FlameRate=22,DarkRate=10,
   FlameSpeed=NumberRange.new(1.4,2.8),FlameLifetime=NumberRange.new(.6,.9),
   LightningSize=4.2,LightningRate=7,LightningLifetime=NumberRange.new(.16,.28),
   RingRadius=2.1,RingWidth=.1,RingTransparency=.16,FootClearance=.12,
  }
  table.insert(Config.Order,id)
 end
end
local Shop=require(script.Parent.ShopProductConfig)
for _,id in ipairs({"VIP","Secret"}) do
 local aura=Shop.Auras[id]
 aura.Key=id;aura.DisplayName=aura.Name;aura.Order=#Config.Order+1
 Config.Auras[id]=aura
 table.insert(Config.Order,id)
end
function Config.Get(id) return typeof(id)=="string" and Config.Auras[id] or nil end
function Config.GetAll() return Config.Auras end
-- Presentation only. World changes never revoke ownership or an equipped Aura.
function Config.IsListed(id,world)
 local aura=Config.Get(id)
 return aura~=nil and aura.Listed~=false and (not aura.VisibleWorld or aura.VisibleWorld==(tonumber(world) or 1))
end
return Config
