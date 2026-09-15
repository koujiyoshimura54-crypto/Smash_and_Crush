local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Config.CommunityRewardConfig)
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Items=require(game.ServerScriptService.Services.ItemService)
local Roller=require(game.ServerScriptService.Services.EnemyDropRoller)
local Stage=require(game.ServerScriptService.World.StageManager)
local M={}
local sessions=setmetatable({}, {__mode="k"})
local rng=Random.new()
local function session(p)
 if typeof(p)~="Instance" or not p:IsA("Player") or p.Parent~=Players then return nil end
 local d=Data.Get(p)
 if not d or not d.Loaded or not d.Data then return nil end
 local s=sessions[p]
 if not s or s.Data~=d.Data then s={Data=d.Data,Joined=false,CheckedAt=-math.huge};sessions[p]=s end
 return s,d
end
function M.GetState(p,refresh)
 local s,d=session(p)
 if not s then return {Loaded=false,Status="Loading",HasReady=false} end
 if d.Data.CommunityRewards.Claimed then return {Loaded=true,Status="Claimed",HasReady=false} end
 if not Config.IsValid() then return {Loaded=true,Status="Unavailable",HasReady=false} end
 if refresh and not s.Checking and os.clock()-s.CheckedAt>=5 then
  s.Checking=true
  local ok,joined=pcall(function()return p:IsInGroupAsync(Config.GroupId)end)
  s.Checking=false s.CheckedAt=os.clock()
  s.Joined=ok and joined==true s.CheckError=not ok
 end
 if s.Busy or d.PendingItemMutation or d.Saving then return {Loaded=true,Status="Pending",HasReady=false} end
 return {Loaded=true,Status=s.CheckError and "CheckFailed" or (s.Joined and "Ready" or "NotJoined"),HasReady=s.Joined and not s.CheckError}
end
function M.Claim(p)
 local s,d=session(p)
 if not s then return false,"DataNotLoaded" end
 if s.Busy then return false,"ClaimInProgress" end
 if d.Data.CommunityRewards.Claimed then return false,"AlreadyClaimed" end
 if d.Saving or d.PendingItemMutation then return false,"DataSaving" end
 if not Config.IsValid() then return false,"Unavailable" end
 s.Busy=true
 local ok,success,code,result=xpcall(function()
  local membershipOK,joined=pcall(function()return p:IsInGroupAsync(Config.GroupId)end)
  if not membershipOK then return false,"MembershipUnavailable" end
  s.Joined=joined==true s.CheckedAt=os.clock()
  if not joined then return false,"NotJoined" end
  if Data.Get(p)~=d or d.Data~=s.Data or not d.Loaded or p.Parent~=Players then return false,"DataNotLoaded" end
  local stage=Stage.GetCurrentStageNumber(p)
  local ids,counts={},{}
  for i=1,Config.ItemAmount do
   local id=Roller.RollItem(rng,stage)
   ids[i]=id;counts[id]=(counts[id] or 0)+1
  end
  local result={WinAmount=Config.WinAmount,Items=ids,Stage=stage}
  local success,code=Items.RunItemTransaction(p,function(token)
   for id,count in pairs(counts) do
    local added,reason=Items.AddItem(p,id,count,token)
    if not added then return false,reason end
   end
   return true,"Staged"
  end,{CommunityReward=true})
  return success,code,result
 end,debug.traceback)
 s.Busy=false
 if not ok then warn("[CommunityReward] "..tostring(success));return false,"ClaimFailed" end
 return success,code,result
end
Players.PlayerRemoving:Connect(function(p)sessions[p]=nil end)
return M
