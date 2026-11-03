-- Reproduce the only non-Source edit in PetInventoryBestEquip_20261103.
-- Run against the current canonical Edit DataModel; does not save or publish.
assert(game.PlaceId==126576845524886,"Wrong canonical place")
local RS=game:GetService("ReplicatedStorage")
local price=require(RS.Modules.Egg).price("Basic")
assert(price>0,"Basic price is unavailable")
local prize=workspace:WaitForChild("Eggs"):WaitForChild("Basic"):WaitForChild("Prize")
for _,name in ipairs({"Info","InfoShadow"}) do
 local label=prize:FindFirstChild(name)
 if label and label:IsA("TextLabel") then label.Text=require(RS.Modules.NumberFormat).Price(price) end
end
return price
