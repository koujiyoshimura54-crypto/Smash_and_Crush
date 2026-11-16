-- Restore missing registered World2 models only. Existing templates are retained.
-- Run in the specified unsaved Edit copy. No upload, place Save/Publish, or runtime fetch.
-- Native imported MeshPart/SurfaceAppearance data is cloned before sanitization.
assert(game.PlaceId==126576845524886 and game.GameId==10765181857 and not game.RunService:IsRunning())
local records=game.HttpService:JSONDecode([==[[{"Id": "W2_NORMAL_01", "Asset": 120423306946269, "UUID": "be9de5d1-da96-4257-b9fa-0e9cfc268e96", "Size": [0.9816285371780396, 0.3546905517578125, 0.39114394783973694], "Center": [0.0, -0.0040073394775390625, -0.00021934881806373596]}, {"Id": "W2_NORMAL_02", "Asset": 102716104784959, "UUID": "699aff5d-dfc7-47af-8c04-3d2fc97fbd2d", "Size": [0.9804688692092896, 0.432403564453125, 0.5376281142234802], "Center": [0.0, -0.0051326751708984375, 0.004407892003655434]}, {"Id": "W2_NORMAL_03", "Asset": 128085702169072, "UUID": "c29ae88b-713b-40c8-a674-7cc619ae9784", "Size": [0.9820557832717896, 0.4853668212890625, 0.4508056640625], "Center": [0.0, -0.002948760986328125, 0.0031738318502902985]}, {"Id": "W2_NORMAL_04", "Asset": 117230570003114, "UUID": "325c88e5-35ce-4599-abbc-d6add5edffa0", "Size": [0.9797669649124146, 0.45623779296875, 0.3888855576515198], "Center": [0.0, 0.008337020874023438, 0.00040815770626068115]}, {"Id": "W2_NORMAL_06", "Asset": 76372035088717, "UUID": "15b4b34a-ee7b-4724-a23d-840821ad4b01", "Size": [0.9783326387405396, 0.34527587890625, 0.46011364459991455], "Center": [0.0, -0.008162498474121094, -0.03341938555240631]}, {"Id": "W2_NORMAL_07", "Asset": 79273947117738, "UUID": "6f4d6c73-89cb-4430-a575-6c6cdf56fdd4", "Size": [0.9801331758499146, 0.468505859375, 0.48170486092567444], "Center": [0.0, 0.008274078369140625, 0.0002651140093803406]}, {"Id": "W2_NORMAL_08", "Asset": 127996101926091, "UUID": "c0336e3e-4fa8-4e1b-8c0d-8ec6e1aa5dc5", "Size": [0.9819642305374146, 0.631561279296875, 0.5361633896827698], "Center": [0.0, 0.014760017395019531, -0.0038165654987096786]}, {"Id": "W2_NORMAL_10", "Asset": 89304737924828, "UUID": "45523401-b6e5-40be-886e-87653b1ca616", "Size": [0.9797364473342896, 0.500518798828125, 0.387664794921875], "Center": [0.0, -0.0062427520751953125, -0.010253915563225746]}, {"Id": "W2_NORMAL_11", "Asset": 115656579181767, "UUID": "850c42fe-67c0-4846-9611-d1d1e7b1c6c0", "Size": [0.9839783906936646, 0.4898681640625, 0.4333038926124573], "Center": [0.0, -0.015499114990234375, 0.0011748727411031723]}, {"Id": "W2_NORMAL_12", "Asset": 121212954959648, "UUID": "1f4b4e93-389d-433a-a119-495af875a4b4", "Size": [0.9817811250686646, 0.52203369140625, 0.4449616074562073], "Center": [0.0, -0.014505386352539062, 0.007617916911840439]}]]==])
local storage=game.ServerStorage
local library=storage:FindFirstChild("World2DumbbellModels")
if not library then library=Instance.new("Folder");library.Name="World2DumbbellModels";library.Parent=storage end
local audit={}
for _,r in records do
 local existing=library:FindFirstChild(r.Id)
 if existing then
  assert(existing:GetAttribute("SourceModelAssetId")==r.Asset,"Existing template differs; preserve: "..r.Id)
 else
  local package=game.InsertService:LoadAsset(r.Asset)
  local source;local count=0
  for _,x in package:GetDescendants()do
   if x:IsA("LuaSourceContainer")then package:Destroy();error("Unexpected source in registered asset")end
   if x:IsA("MeshPart")then source=x;count+=1 end
  end
  assert(count==1 and source,"Expected exactly one mesh for "..r.Id)
  local mesh=source:Clone();package:Destroy()
  for _,x in mesh:GetDescendants()do if not x:IsA("SurfaceAppearance")then x:Destroy()end end
  local material=assert(mesh:FindFirstChildOfClass("SurfaceAppearance"),"Missing PBR "..r.Id)
  for _,key in {"ColorMap","NormalMap","RoughnessMap","MetalnessMap"}do assert(material[key]~="","Missing "..key.." "..r.Id)end
  mesh.Name="Visual";mesh.Size=Vector3.new(unpack(r.Size));mesh.CFrame=CFrame.new(unpack(r.Center));mesh.PivotOffset=CFrame.identity
  local model=Instance.new("Model");model.Name=r.Id
  model:SetAttribute("ItemId",r.Id);model:SetAttribute("SourceUUID",r.UUID);model:SetAttribute("SourceModelAssetId",r.Asset)
  local grip=Instance.new("Part");grip.Name="Grip";grip.Size=Vector3.new(.05,.05,.05);grip.Transparency=1;grip.CFrame=CFrame.identity;grip.Parent=model
  mesh.Parent=model;model.PrimaryPart=grip
  for _,part in model:GetDescendants()do if part:IsA("BasePart")then part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Massless=true end end
  model.Parent=library
 end
 local mesh=library[r.Id].Visual;local material=mesh:FindFirstChildOfClass("SurfaceAppearance")
 table.insert(audit,{ItemId=r.Id,UUID=r.UUID,ModelAssetId=r.Asset,MeshAssetId=mesh.MeshId,MeshSize=tostring(mesh.MeshSize),Size=tostring(mesh.Size),Color=tostring(mesh.Color),ColorMap=material.ColorMap,NormalMap=material.NormalMap,RoughnessMap=material.RoughnessMap,MetalnessMap=material.MetalnessMap})
 task.wait()
end
game.ChangeHistoryService:SetWaypoint("Register World2 dumbbell visual templates")
return game.HttpService:JSONEncode(audit)
