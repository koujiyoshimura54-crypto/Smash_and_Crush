-- Persistent PlayerScripts owner; the old StarterGui Folder respawned this controller.
-- Shared interactive Item/Pet/Ore view; current transaction and proximity wiring retained.
local buildMergeShop=require(game:GetService("ReplicatedStorage").Modules:WaitForChild("MergeShopView"))


local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local gui=player:WaitForChild("PlayerGui"):WaitForChild("StrengthGui")
if gui:GetAttribute("MergeShopMounted") then return end
local Master=require(RS.Config:WaitForChild("ItemMaster"))
local PetClient=require(player:WaitForChild("PlayerScripts"):WaitForChild("Services"):WaitForChild("PetClient"))
local Egg=require(RS.Modules:WaitForChild("Egg"))
local mergeRemote=RS.Remotes:WaitForChild("ItemMergeRequest")
local stateRemote=RS.Remotes:WaitForChild("ItemMergeState")
local state,pending,fetching,fresh=nil,false,false,false
local pendingRequest
local deliveredResults={}
local consumeResult
local revision=0
local refresh,view
local status=""
local errors={WorldNotReached="Reach World 2 first",MixedWorldMaterials="Use materials from one World",NotEnoughItems="Select at least 2 owned Items",DataSaving="Saving. Please wait.",DataNotLoaded="Loading…",CountOverflow="Item count limit reached",InventorySavePending="Waiting for save…",RateLimited="Please wait…",InvalidAmount="Invalid material amount",InvalidItemId="Select another item",MergeSessionChanged="Reopen Merge and try again",MergeSequenceChanged="Inventory changed. Please retry",InvalidReplay="Please make a new selection"}
local colors={}
-- Rarity surfaces are the existing purchased Pet visual palettes; no new art or stats.
local Config=require(RS.Modules.Config)
local Pet=require(RS.Modules.Pet)
for _,name in {"Common","Uncommon","Rare","Epic","Legendary"} do
 local rarity=Config.Rarities and Config.Rarities[name]
 if rarity and rarity.Colors then colors[name]=Pet.sequence(rarity.Colors) end
end
local ok,built=pcall(buildMergeShop,{
 gui=gui,RS=RS,PetClient=PetClient,Egg=Egg,Master=Master,ItemColors=colors,
 PurchasedInventory=game.StarterGui.ScreenGui.Menus.Inventory.Main,
 EggViewport=require(RS.Modules.LimitedPetViewport),Input=game:GetService("UserInputService"),GuiService=game:GetService("GuiService"),
 OnMerge=function(materials)
  if pending then return end
  if not state or not state.SessionToken or not state.NextSequence then return end
  pendingRequest={RequestId=game:GetService("HttpService"):GenerateGUID(false),SessionToken=state.SessionToken,Sequence=state.NextSequence,Materials=materials}
  pending=true;fresh=false;revision+=1;status=""
  view:SetItemState(state,fresh,pending,status)
  mergeRemote:FireServer(pendingRequest)
 end,
 OnTab=function(name)
  if not view then return end
  if name=="Item" then task.spawn(refresh) else task.spawn(PetClient.refresh) end
 end,
})
if not ok then
 local failed=gui.Parent:FindFirstChild("MergeShopGui");if failed then failed:Destroy() end
 warn("[MergeShop] Purchased UI mount failed; no substitute created: "..tostring(built));return
end
view=built
local shop=view.Root
gui.InventoryPanel.Content.Merge.Visible=false
refresh=function()
 if fetching then return end;fetching=true
 local requestRevision=revision
 local success,response=pcall(function() return stateRemote:InvokeServer() end)
 fetching=false
 if requestRevision~=revision then task.defer(refresh);return end
 fresh=success and typeof(response)=="table" and response.Loaded==true
 if fresh then state=response;if status=="Checking connection…" then status="" end else status="Checking connection…" end
 if fresh and pendingRequest and state.LastResult and state.LastResult.RequestId==pendingRequest.RequestId then consumeResult(state.LastResult) end
 view:SetItemState(state,fresh,pending,status)
end
consumeResult=function(result)
 if typeof(result)~="table" or not pendingRequest or result.RequestId~=pendingRequest.RequestId then return end
 if result.Code=="InventorySavePending" or result.Code=="MergeInProgress" then
  status="Waiting for save…";return
 end
 local id=pendingRequest.RequestId;pendingRequest=nil;pending=false;revision+=1
 if result.MergeState and result.MergeState.Loaded then state=result.MergeState;fresh=true end
 status=result.Success and "Merge complete." or errors[result.Code] or "Merge failed. Please retry."
 view:SetItemState(state,fresh,pending,status)
 if result.Success and result.ResultItemId and not deliveredResults[id] then
  deliveredResults[id]=true;view:CompleteItem(result.ResultItemId)
 end
end
mergeRemote.OnClientEvent:Connect(function(result)
 consumeResult(result);view:SetItemState(state,fresh,pending,status);task.spawn(refresh)
end)
for _,name in {"ItemPurchaseRequest","ItemRobuxPurchaseRequest","ItemEquipRequest"} do
 RS.Remotes:WaitForChild(name).OnClientEvent:Connect(function()
  fresh=false;revision+=1
  if shop.Visible then view:SetItemState(state,fresh,pending,status);task.spawn(refresh) end
 end)
end
player:GetAttributeChangedSignal("World2Visited"):Connect(function()
 fresh=false;revision+=1;if shop.Visible then task.spawn(refresh) end
end)
local function openShop()
 for _,name in {"InventoryPanel","ShopPanel","RebirthPanel"} do local x=gui:FindFirstChild(name);if x then x.Visible=false end end
 local skip=gui.Parent:FindFirstChild("StageSkipGui");if skip and skip:FindFirstChild("Panel") then skip.Panel.Visible=false end
 view:Show();task.spawn(refresh)
end
local inside=false
local elapsed,petPoll,itemPoll=0,0,0
local beat=RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;petPoll+=dt;itemPoll+=dt
 if shop.Visible and petPoll>=.5 then petPoll=0;view:SetPetState(PetClient.state()) end
 if shop.Visible and view:IsItem() and itemPoll>=2 then itemPoll=0;task.spawn(refresh) end
 if elapsed<.1 then return end;elapsed=0
 local model=workspace:FindFirstChild("RestockShop")
  if player:GetAttribute("CurrentWorld")==2 then
   local map=workspace:FindFirstChild("World2Map");local lobby=map and map:FindFirstChild("TrainingArea")
   local facilities=lobby and lobby:FindFirstChild("FacilityDisplays")
   model=facilities and facilities:FindFirstChild("MergeDisplay")
  end
 local area=model and model:FindFirstChild("Area")
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local now=false
 if area and area:IsA("BasePart") and root then
  local point=area.CFrame:PointToObjectSpace(root.Position);local half=area.Size/2
  if area:IsA("Part") and area.Shape==Enum.PartType.Cylinder then
   local radius=math.min(half.Y,half.Z);now=math.abs(point.X)<=half.X and point.Y*point.Y+point.Z*point.Z<=radius*radius
  else now=math.abs(point.X)<=half.X and math.abs(point.Y)<=half.Y and math.abs(point.Z)<=half.Z end
 end
 if now~=inside then inside=now;if now then openShop() else view:Hide() end end
end)
for _,name in {"InventoryPanel","ShopPanel","RebirthPanel"} do
 local x=gui:FindFirstChild(name)
 if x then x:GetPropertyChangedSignal("Visible"):Connect(function() if x.Visible then view:Hide() end end) end
end
script.Destroying:Connect(function() beat:Disconnect();view:Destroy();gui:SetAttribute("MergeShopMounted",nil) end)
-- Mark mounted only after state/result/proximity handlers are installed.
gui:SetAttribute("MergeShopMounted",true)
