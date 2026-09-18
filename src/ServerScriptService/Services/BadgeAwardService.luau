local Players=game:GetService("Players")
local BadgeService=game:GetService("BadgeService")
local Config=require(game.ReplicatedStorage.Config:WaitForChild("BadgeConfig"))
local M={}
local states=setmetatable({}, {__mode="k"})

local function state(player)
 local value=states[player]
 if not value then value={Owned={},Pending={}};states[player]=value end
 return value
end

function M.Award(player,key)
 if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then return false,"InvalidPlayer" end
 local badgeId=Config.GetBadgeId(key)
 if typeof(badgeId)~="number" or badgeId<=0 then return false,"InvalidBadge" end
 local current=state(player)
 if current.Owned[key] or current.Pending[key] then return false,current.Owned[key] and "AlreadyOwned" or "Pending" end
 current.Pending[key]=true
 task.spawn(function()
  local ownedOK,owned=pcall(BadgeService.UserHasBadgeAsync,BadgeService,player.UserId,badgeId)
  if not ownedOK then
   current.Pending[key]=nil
   warn(("[BadgeAward] Ownership check failed for %s (%s)"):format(player.Name,key))
   return
  end
  if owned then
   current.Owned[key]=true
   current.Pending[key]=nil
   return
  end
  local awardOK,awarded=pcall(BadgeService.AwardBadge,BadgeService,player.UserId,badgeId)
  current.Pending[key]=nil
  if awardOK and awarded then
   current.Owned[key]=true
  else
   warn(("[BadgeAward] Award failed for %s (%s)"):format(player.Name,key))
  end
 end)
 return true,"Queued"
end

Players.PlayerRemoving:Connect(function(player) states[player]=nil end)
return M
