local contexts={}
local function forWorld(worldId)
 assert(worldId==1 or worldId==2,"Unsupported world")
 if contexts[worldId] then return contexts[worldId] end
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local M={} local stages,map local states=setmetatable({},{__mode="k"})
local function get(p)local s=states[p] if not s then s=M.InitializePlayer(p) end return s end
function M.Initialize(newMap)
 map=newMap or Workspace:FindFirstChild(worldId==2 and "World2Map" or "GeneratedMap") assert(map)
 stages={} for _,x in map.BattleCorridor:GetChildren() do local n=x.Name:match("^Stage(%d%d)$") if x:IsA("Model") and n then table.insert(stages,{Number=tonumber(n),Model=x,Gate=x:FindFirstChild("Gate")}) end end
 table.sort(stages,function(a,b)return a.Number<b.Number end)
 for _,x in stages do if x.Gate then x.Gate.CanCollide=false x.Gate.Transparency=1 end end
 local nextArea=map:FindFirstChild("NextWorldArea")
 local nextGate=nextArea and nextArea:FindFirstChild("NextWorldGate")
 if nextGate then nextGate.CanCollide=false nextGate.Transparency=1 end
 for _,p in Players:GetPlayers() do M.InitializePlayer(p) end return stages
end
function M.InitializePlayer(p,targetStage)
 targetStage=targetStage or 1
 assert(typeof(targetStage)=="number" and targetStage%1==0 and targetStage>=1 and targetStage<=10)
 local s={CurrentStage=targetStage,Cleared={},Skipped={},WorldComplete=false}
 for major=1,targetStage-1 do s.Skipped[major]=true end
 states[p]=s
 p:SetAttribute(worldId==2 and "World2CurrentStage" or "CurrentStage",targetStage)
 p:SetAttribute(worldId==2 and "World2Complete" or "WorldComplete",false)
 return s
end
function M.IsStageSkipped(p,n)return get(p).Skipped[n]==true end
function M.ClearStage(p,n)local s=get(p) if s.WorldComplete then return false,"complete" end if n~=s.CurrentStage then return false,"out of order" end s.Cleared[n]=true if n<10 then s.CurrentStage+=1 p:SetAttribute(worldId==2 and "World2CurrentStage" or "CurrentStage",s.CurrentStage)else s.WorldComplete=true p:SetAttribute(worldId==2 and "World2Complete" or "WorldComplete",true)end return true end
function M.GetCurrentStageNumber(p)return get(p).CurrentStage end
function M.IsStageCleared(p,n)return get(p).Cleared[n]==true end
function M.GetState(p)local s=get(p)local c={}for n,v in s.Cleared do c[n]=v end return{CurrentStage=s.CurrentStage,Cleared=c,WorldComplete=s.WorldComplete}end
function M.GetStages()return stages end
function M.ResetPlayer(p)return M.InitializePlayer(p)end
Players.PlayerRemoving:Connect(function(p)states[p]=nil end)

 contexts[worldId]=M
 M.ForWorld=forWorld
 return M
end
return forWorld(1)
