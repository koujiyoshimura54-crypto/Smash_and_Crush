-- Purchased configured Eggs only. Main/Data/Quest/Shop pipelines stay disabled.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")
local Egg=require(RS.Modules.Egg)
local Pet=require(RS.Modules.Pet)
local Config=require(RS.Modules.Config)
local Data=require(script.Parent.PlayerDataService)
local Pets=require(script.Parent.PetServer)
local M={}
local started=false
local nextRequest=setmetatable({}, {__mode="k"})
local function reply(player,ok,reason)
 local state=Pets.state(player)
 return {ok=ok,reason=reason,state=state,pending=player:GetAttribute("PetSavePending")==true}
end
local function open(player,name,button,id,revision)
 if not Egg.isEgg(name) then return false,"EggUnavailable" end
 local count=Egg.count(button)
 if count~=1 and count~=3 and count~=8 then return false,"InvalidOpenCount" end
 local folder=workspace:FindFirstChild(Egg.FolderName)
 local part=folder and folder:FindFirstChild(name)
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not part or not part:IsA("BasePart") then return false,"EggUnavailable" end
 if not root or not humanoid or humanoid.Health<=0 then return false,"CharacterNotReady" end
 if (root.Position-part.Position).Magnitude>Config.Egg.reach then return false,"TooFarFromEgg" end
 local state,reason=Data.GetPetState(player)
 if not state then return false,reason end
 local session=Data.Get(player)
 if session.Saving or session.PendingItemMutation then return false,"DataSaving" end
 if state.Revision~=revision then return false,"PetStateChanged" end
 local unitPrice=Egg.price(name)
 if unitPrice<=0 or unitPrice%1~=0 or unitPrice>9007199254740991/count then return false,"EggPriceUnavailable" end
 local price=unitPrice*count
 if session.Data.Win<price then return false,"NotEnoughWin" end
 local list=Egg.ranked(Egg.pets(name))
 if #list==0 then return false,"EggUnavailable" end
 for _,slot in ipairs(list) do
  if not Pet.model(slot.pet) then return false,"PetModelUnavailable" end
 end
 local results={}
 for _=1,count do
  local pet,percent=Egg.pick(list)
  if not pet then return false,"EggUnavailable" end
  table.insert(results,{id=Http:GenerateGUID(false),pet=pet,percent=percent,duplicate=false,bonus=0})
 end
 return Data.MutatePets(player,id,revision,"Hatch",{EggName=name,Count=count,PriceWin=price,Results=results})
end
function M.request(player,action,id,revision,a,b)
 if player.Parent~=Players then return {ok=false,reason="InvalidPlayer"} end
 if action=="GetState" then
  local state,reason=Pets.state(player)
  return {ok=state~=nil,reason=reason or "State",state=state,pending=player:GetAttribute("PetSavePending")==true}
 end
 if action~="OpenEgg" and action~="Equip" then return reply(player,false,"InvalidAction") end
 if type(id)~="string" or #id~=36 or not id:match("^[%x%-]+$")
  or type(revision)~="number" or revision~=revision or revision<0 or revision%1~=0 then return reply(player,false,"InvalidPetRequest") end
 local state,reason=Data.GetPetState(player)
 if not state then return reply(player,false,reason) end
 local session=Data.Get(player)
 -- Retrying an accepted operation only confirms its original roll/debit, even
 -- after the player leaves the Egg. It never revalidates into a new purchase.
 if state.LastRequestId==id then return reply(player,true,"AlreadyApplied") end
 local pending=session.PendingItemMutation
 if pending and pending.PetMutation and pending.Id==id then
  local ok,why=Data.ResolveItemMutation(player)
  return reply(player,ok,why)
 end
 local now=os.clock()
 if now<(nextRequest[player] or 0) then return reply(player,false,"PleaseWait") end
 nextRequest[player]=now+0.75
 local ok,why
 if action=="OpenEgg" then
  if type(a)~="string" or type(b)~="string" then return reply(player,false,"InvalidEggRequest") end
  ok,why=open(player,a,b,id,revision)
 else ok,why=Pets.equip(player,a,id,revision) end
 return reply(player,ok,why)
end
function M.init()
 local folder=workspace:FindFirstChild(Egg.FolderName)
 if not folder then return end
 for _,part in ipairs(folder:GetChildren()) do
  if not part:IsA("BasePart") or not Egg.isEgg(part.Name) then continue end
  local prize=part:FindFirstChild("Prize")
  if prize then
   for _,name in ipairs({"Info","InfoShadow"}) do
    local label=prize:FindFirstChild(name)
    if label and label:IsA("TextLabel") then label.Text=tostring(Egg.price(part.Name)) end
   end
  end
 end
end
function M.start()
 if started then return end
 started=true
 M.init();Pets.start()
 local remotes=RS:WaitForChild("Remotes")
 local remote=remotes:FindFirstChild("PetRequest")
 if remote then assert(remote:IsA("RemoteFunction"),"PetRequest must be a RemoteFunction")
 else remote=Instance.new("RemoteFunction");remote.Name="PetRequest";remote.Parent=remotes end
 remote.OnServerInvoke=function(player,...)
  local ok,result=pcall(M.request,player,...)
  if ok then return result end
  warn("[EggServer] Request failed: "..tostring(result))
  return reply(player,false,"PetRequestFailed")
 end
end
return M
