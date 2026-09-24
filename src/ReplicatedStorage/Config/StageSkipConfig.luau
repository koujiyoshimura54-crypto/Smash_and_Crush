-- Phase 6.7: the single source of prices and product-to-stage mapping.
local Config = {}
Config.Stages = {
 [2]={RequiredWin=1, ProductId=3711531641, FallbackPrice=10},
 [3]={RequiredWin=5, ProductId=3711531688, FallbackPrice=20},
 [4]={RequiredWin=15, ProductId=3711533318, FallbackPrice=30},
 [5]={RequiredWin=50, ProductId=3711533363, FallbackPrice=40},
 [6]={RequiredWin=75, ProductId=3711533407, FallbackPrice=50},
 [7]={RequiredWin=150, ProductId=3711533440, FallbackPrice=60},
 [8]={RequiredWin=300, ProductId=3711533493, FallbackPrice=70},
 [9]={RequiredWin=750, ProductId=3711533535, FallbackPrice=80},
 [10]={RequiredWin=1200, ProductId=3711533573, FallbackPrice=90},
}
local byProduct = {}
for stage, entry in Config.Stages do
 assert(typeof(entry.RequiredWin)=="number" and entry.RequiredWin>=0 and entry.RequiredWin%1==0)
 entry.RobuxPrice=entry.FallbackPrice -- Legacy display alias; Marketplace supplies the live price.
 byProduct[entry.ProductId] = stage
 table.freeze(entry)
end
function Config.Get(stage)
 if typeof(stage) ~= "number" or stage ~= stage or stage % 1 ~= 0 then return nil end
 return Config.Stages[stage]
end
function Config.StageForProduct(productId)
 if typeof(productId) ~= "number" then return nil end
 return byProduct[productId]
end
function Config.IsInLobby(character)
 local map = workspace:FindFirstChild("GeneratedMap")
 local area = map and map:FindFirstChild("TrainingArea")
 local floor = area and area:FindFirstChild("Floor")
 local root = character and character:FindFirstChild("HumanoidRootPart")
 local hum = character and character:FindFirstChildOfClass("Humanoid")
 if not floor or not root or not hum or hum.Health <= 0 then return false end
 local p = floor.CFrame:PointToObjectSpace(root.Position)
 return math.abs(p.X) <= floor.Size.X/2 and math.abs(p.Z) <= floor.Size.Z/2
  and p.Y >= floor.Size.Y/2-1 and p.Y <= floor.Size.Y/2+40
end
table.freeze(Config.Stages)
return table.freeze(Config)
