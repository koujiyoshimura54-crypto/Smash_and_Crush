-- Restore registered geometry into an Edit place from the EXISTING Model assets.
-- Run only when ServerStorage.World1DumbbellModels is missing; never overwrites it.
-- No uploads, place saves, scripts from assets, economy changes or runtime fetches.
-- Roblox's compiled PBR data is retained by cloning the imported MeshPart.
assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
local storage=game:GetService("ServerStorage")
assert(not storage:FindFirstChild("World1DumbbellModels"),"Existing library retained; stop restore")
local records={
 {Id="NORMAL_01",Asset=100003248943176,UUID="a88c0024-1595-4271-9fcd-431e840fcf95",Size=Vector3.new(0.9798890352249146,0.3620758056640625,0.4028168320655823),Center=Vector3.new(0,0.001911163330078125,-0.00012593716382980347)},
 {Id="NORMAL_02",Asset=106469049055541,UUID="fb3a75b8-70a5-4f8e-a943-4361a85dfb47",Size=Vector3.new(0.9814759492874146,0.465606689453125,0.4568023383617401),Center=Vector3.new(0,0.000537872314453125,0.0008087102323770523)},
 {Id="NORMAL_03",Asset=102433513297786,UUID="5f42bf33-1673-4cd7-b611-3f092cae80b1",Size=Vector3.new(0.9794923067092896,0.4166259765625,0.4253845810890198),Center=Vector3.new(0,0.008998870849609375,-0.000011410564184188843)},
 {Id="NORMAL_04",Asset=93150737705355,UUID="e2eea638-64b6-4800-8c5d-ab57ca813c8a",Size=Vector3.new(0.9783326387405396,0.4074554443359375,0.40652480721473694),Center=Vector3.new(0,0.0004482269287109375,-0.0005950983613729477)},
 {Id="NORMAL_06",Asset=94440891847547,UUID="4a01d4c0-a254-4af4-86fa-1f599ed18a73",Size=Vector3.new(1.0015870332717896,0.430633544921875,0.3520050644874573),Center=Vector3.new(0,0.009189605712890625,0.0013676099479198456)},
 {Id="NORMAL_07",Asset=101503029468609,UUID="664a0906-864b-4752-9f22-be7769f00df7",Size=Vector3.new(0.9800111055374146,0.4937744140625,0.4345245957374573),Center=Vector3.new(0,0.026215553283691406,-0.008745236322283745)},
 {Id="NORMAL_08",Asset=82472684564277,UUID="4a3ad0b8-f756-4462-a3d9-f8bebf800217",Size=Vector3.new(1.0001221895217896,0.4963378608226776,0.4320375323295593),Center=Vector3.new(0,0.06471441686153412,-0.012676239013671875)},
 {Id="NORMAL_09",Asset=82180382781576,UUID="1d429733-b5b6-48b1-9b48-f9d08a9de8b7",Size=Vector3.new(1.0004578828811646,0.54278564453125,0.4924774765968323),Center=Vector3.new(0,0.07963752746582031,-0.07131189107894897)},
 {Id="NORMAL_10",Asset=77746198788025,UUID="9d34e00c-6acc-46d0-9e54-e2b0bdca123d",Size=Vector3.new(0.9808655977249146,0.6279296875,0.6541444063186646),Center=Vector3.new(0,0.03655242919921875,0.034492455422878265)},
 {Id="NORMAL_11",Asset=74066961638377,UUID="8cee376d-7bdb-4d1a-92c3-234c25a0206e",Size=Vector3.new(0.9799805879592896,0.64837646484375,0.6756592988967896),Center=Vector3.new(0,0.05730438232421875,0.007270783185958862)},
 {Id="NORMAL_12",Asset=122102219580338,UUID="3267a786-95a1-4f0e-88e0-2fdc600b8f98",Size=Vector3.new(0.9816590547561646,0.4568023681640625,0.47576916217803955),Center=Vector3.new(0,0.0076732635498046875,0.012950891628861427)},
}
local library=Instance.new("Folder");library.Name="World1DumbbellModels"
local ok,err=pcall(function()
 local legacy=assert(storage.Templates:FindFirstChild("DumbbellDisplayTemplate")):Clone()
 legacy.Name="NORMAL_05";legacy:SetAttribute("ItemId","NORMAL_05");legacy:PivotTo(CFrame.identity);legacy.Parent=library
 for _,r in records do
  local package=game:GetService("InsertService"):LoadAsset(r.Asset)
  local mesh=package:FindFirstChildWhichIsA("MeshPart",true)
  if not mesh then package:Destroy();error("Missing mesh: "..r.Id)end
  local visual=mesh:Clone();package:Destroy()
  for _,x in visual:GetDescendants()do if not x:IsA("SurfaceAppearance")then x:Destroy()end end
  visual.Name="Visual";visual.Size=r.Size;visual.CFrame=CFrame.new(r.Center);visual.PivotOffset=CFrame.identity
  local model=Instance.new("Model");model.Name=r.Id;model:SetAttribute("ItemId",r.Id);model:SetAttribute("SourceUUID",r.UUID);model:SetAttribute("SourceModelAssetId",r.Asset)
  local grip=Instance.new("Part");grip.Name="Grip";grip.Size=Vector3.new(.05,.05,.05);grip.Transparency=1;grip.CFrame=CFrame.identity;grip.Parent=model
  visual.Parent=model;model.PrimaryPart=grip;model.Parent=library
 end
 for _,p in library:GetDescendants()do
  if p:IsA("LuaSourceContainer")then error("Unexpected source in geometry")end
  if p:IsA("BasePart")then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true end
 end
end)
if not ok then library:Destroy();error(err)end
library.Parent=storage
game:GetService("ChangeHistoryService"):SetWaypoint("Restore World1 dumbbell registered models")
print("Restored 12 templates; no Save/Publish")
