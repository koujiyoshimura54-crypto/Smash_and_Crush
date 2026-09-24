-- Phase 7.5.3: owner-only world drops; server proximity pickup.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Master=require(game.ReplicatedStorage.Config.ItemMaster)
local Items=require(game.ServerScriptService.Services.ItemService)
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local flash=game.ReplicatedStorage.Remotes:WaitForChild("BossDropFlash")
local M={}
local folder=Instance.new("Folder");folder.Name="BossItemDrops";folder.Parent=workspace
local records={}
local sequence=0
local PICKUP_RADIUS=3
local function remove(r)
 records[r.Part]=nil
 r.Part:Destroy()
end
local function finish(r,success,code)
 if not records[r.Part] then return end
 if success then remove(r)
 else r.Busy=false;r.Label.Text="APPROACH TO PICK UP";r.Part:SetAttribute("PickupState","Available") end
end
function M.Spawn(player,itemId,cf)
 local item=Master.Get(itemId)
 if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then return nil,"InvalidPlayer" end
 if not item or item.Rarity~="Common" or typeof(cf)~="CFrame" then return nil,"InvalidDrop" end
 sequence+=1
 local part=Instance.new("Part");part.Name="Drop_"..sequence
 part.Shape=Enum.PartType.Ball;part.Size=Vector3.new(.8,.8,.8)
 part.Material=Enum.Material.Neon;part.Color=Color3.fromRGB(110,215,255)
 part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
 part.CFrame=cf
 part:SetAttribute("ItemId",itemId);part:SetAttribute("OwnerUserId",player.UserId);part:SetAttribute("PickupState","Available")
 local gui=Instance.new("BillboardGui");gui.Name="ItemDisplay";gui.Size=UDim2.fromOffset(130,45)
 gui.StudsOffset=Vector3.new(0,4.2,0);gui.AlwaysOnTop=true;gui.MaxDistance=90;gui.Parent=part
 -- A thin two-sided image card keeps the ItemMaster image visible in-world.
 local plate=Instance.new("Part");plate.Name="ImagePlate";plate.Size=Vector3.new(3,3,.08)
 plate.Anchored=true;plate.CanCollide=false;plate.CanTouch=false;plate.CanQuery=false
 plate.Color=Color3.fromRGB(22,27,39);plate.CFrame=cf*CFrame.new(0,2,0);plate.Parent=part
 for _,face in ipairs({Enum.NormalId.Front,Enum.NormalId.Back}) do
  local decal=Instance.new("Decal");decal.Name=face.Name.."Image";decal.Texture=item.Image;decal.Face=face;decal.Parent=plate
 end
 local text=Instance.new("TextLabel");text.Name="Info";text.BackgroundTransparency=.25;text.BackgroundColor3=Color3.fromRGB(22,27,39)
 text.Size=UDim2.new(1,0,0,27);text.Position=UDim2.fromOffset(0,0);text.Font=Enum.Font.GothamBold;text.TextSize=12
 text.TextColor3=Color3.new(1,1,1);text.Text=item.ItemType.." / "..item.Element.."\n"..player.Name.."'s drop";text.Parent=gui
 local label=text:Clone();label.Name="PickupStatus";label.Position=UDim2.fromOffset(0,27);label.Size=UDim2.new(1,0,0,18)
 label.TextSize=10;label.Text="APPROACH TO PICK UP";label.Parent=gui
 local r={Owner=player,ItemId=itemId,Part=part,Label=label,Created=os.clock(),Armed=false,Busy=false}
 records[part]=r
 part.Parent=folder
 flash:FireAllClients(cf)
 return part
end
function M.TryPickup(player,part)
 local r=records[part]
 if not r or r.Owner~=player or r.Busy then return false,"Unavailable" end
 if player.Parent~=Players then return false,"InvalidPlayer" end
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not root or not humanoid or humanoid.Health<=0 then return false,"NotAlive" end
 local distance=(root.Position-part.Position).Magnitude
 if distance>PICKUP_RADIUS then r.Armed=true;return false,"TooFar" end
 if not r.Armed or os.clock()-r.Created<.75 then return false,"ApproachRequired" end
 r.Busy=true;part:SetAttribute("PickupState","Saving");r.Label.Text="SAVING..."
 -- No second AddItem is issued once its durable mutation has been accepted.
 local ok,added,code=pcall(Items.AddItem,player,r.ItemId,1)
 if not ok then warn("World drop pickup failed: "..tostring(added));finish(r,false);return false,"Failed" end
 if not added and code=="InventorySavePending" then
  local session=Data.Get(player)
  r.Pending=session and session.PendingItemMutation
  return false,code
 end
 finish(r,added,code)
 return added,code
end
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.15 then return end;elapsed=0
 for part,r in records do
  if r.Owner.Parent~=Players or not part.Parent then remove(r)
  elseif r.Pending then
   -- Outcome is transient operation state, never part of the saved schema.
   if r.Pending.Result then
    local result=r.Pending.Result;r.Pending=nil;finish(r,result=="Changed",result)
   end
  elseif not r.Busy then
   -- Persistence may yield; do not stall other players' pickup scans.
   task.spawn(M.TryPickup,r.Owner,part)
  end
 end
end)
Players.PlayerRemoving:Connect(function(player)
 for _,r in records do if r.Owner==player then remove(r) end end
end)
return M
