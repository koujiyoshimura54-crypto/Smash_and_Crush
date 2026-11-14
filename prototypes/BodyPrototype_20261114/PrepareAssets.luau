-- Edit command; install ONLY after importing BodyPrototype.luau as a ModuleScript
-- named BodyPrototype under ServerStorage.BodyPrototype_20261114.
-- Does not install any live-player spawn hook.
assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
local folder=assert(game.ServerStorage:FindFirstChild("BodyPrototype_20261114"),"Import the prototype module first")
assert(folder:FindFirstChild("BodyPrototype"):IsA("ModuleScript"))
assert(not folder:FindFirstChild("SourceBody"),"Existing prototype must be retained")
local source=workspace.StarterCharacter:Clone();source.Name="SourceBody";source.Parent=folder
folder:SetAttribute("PrototypeOnly",true);folder:SetAttribute("DefaultRatio",0.4)
local clothes=Instance.new("Folder");clothes.Name="Clothing";clothes.Parent=folder
for _,id in {3670737444,398634295,398633812} do
 local asset=game:GetService("InsertService"):LoadAsset(id)
 for _,v in asset:GetChildren() do
  if v:IsA("Shirt") or v:IsA("Pants") then
   v.Name=tostring(id);v:SetAttribute("CatalogAssetId",id);v.Parent=clothes
  end
 end
 asset:Destroy()
end
local userId=game:GetService("StudioService"):GetUserId()
local donor=game:GetService("Players"):CreateHumanoidModelFromUserIdAsync(userId)
donor.Name="CurrentAvatarReference";donor.Parent=folder
return {folder=folder:GetFullName(),signature=require(folder.BodyPrototype).Signature(donor)}
