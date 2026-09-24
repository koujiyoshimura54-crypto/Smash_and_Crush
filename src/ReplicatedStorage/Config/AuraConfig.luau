local Config={}
Config.Order={"Pink","Purple","Yellow","Green","Blue","Red"}
Config.Auras={
["Pink"]={VisualTemplate="Pink_Aura3",Id="Pink",Key="Pink",DisplayName="Pink Aura",Name="Pink Aura",Icon="rbxassetid://110843600021702",StrengthBonus=5,PurchaseType="Win",Price=30,Order=1,Tint=Color3.new(0.9411764740943909,0.3607843220233917,0.686274528503418)},
	["Purple"]={VisualTemplate = "Purple_Aura1",Id="Purple",Key="Purple",DisplayName="Purple Aura",Name="Purple Aura",Icon="rbxassetid://113527186215193",StrengthBonus=10,PurchaseType="Win",Price=75,Order=2,Tint=Color3.new(0.6666666865348816,0.3607843220233917,0.9607843160629272)},
	["Yellow"]={VisualTemplate = "Yellow_Aura1",Id="Yellow",Key="Yellow",DisplayName="Yellow Aura",Name="Yellow Aura",Icon="rbxassetid://115006077417349",StrengthBonus=30,PurchaseType="Win",Price=200,Order=3,Tint=Color3.new(0.95686274766922,0.772549033164978,0.21568627655506134)},
	["Green"]={VisualTemplate = "Green_Aura1",Id="Green",Key="Green",DisplayName="Green Aura",Name="Green Aura",Icon="rbxassetid://72326661519750",StrengthBonus=50,PurchaseType="Win",Price=500,Order=4,Tint=Color3.new(0.26274511218070984,0.8039215803146362,0.4470588266849518)},
	["Blue"]={VisualTemplate = "Blue_Aura1","Blue_Aura2","Blue_Aura3",Id="Blue",Key="Blue",DisplayName="Blue Aura",Name="Blue Aura",Icon="rbxassetid://104827909443134",StrengthBonus=150,PurchaseType="Win",Price=1250,Order=5,Tint=Color3.new(0.2549019753932953,0.6039215922355652,0.9764705896377563)},
	["Red"]={VisualTemplate = "Red_Aura1",Id="Red",Key="Red",DisplayName="Red Aura",Name="Red Aura",Icon="rbxassetid://86956843606297",StrengthBonus=500,PurchaseType="GamePass",GamePassId=1975173075,DisplayPriceFallback=100,Order=6,Tint=Color3.new(0.9333333373069763,0.2549019753932953,0.2980392277240753)},
}
local Shop=require(script.Parent.ShopProductConfig)
for _,id in ipairs({"VIP","Secret"}) do
 local aura=Shop.Auras[id]
 aura.Key=id;aura.DisplayName=aura.Name;aura.Order=#Config.Order+1
 Config.Auras[id]=aura
 table.insert(Config.Order,id)
end
function Config.Get(id) return typeof(id)=="string" and Config.Auras[id] or nil end
function Config.GetAll() return Config.Auras end
return Config
