-- Fixture-only persistence boundary. No save/network implementation is packaged.
-- AddStrengthGain is copied verbatim from the current PlayerDataService by builder.
local LevelProgression=require(game.ReplicatedStorage.Modules.LevelProgression)
local sessions={}
local PlayerDataService={}
function PlayerDataService.Get(p)
 if not sessions[p] then
  local owned={};for world=1,2 do for i=1,12 do owned[string.format(world==1 and "NORMAL_%02d" or "W2_NORMAL_%02d",i)]=1 end end
  sessions[p]={Loaded=true,Data={OwnedDumbbells=owned,EquippedDumbbell="",Strength=123,Win=456,Level=140,LevelProgress=0,LevelCurveVersion=game.ReplicatedStorage.Config.LevelRequirements and require(game.ReplicatedStorage.Config.LevelRequirements).CurrentCurveVersion},Events={}}
 end
 return sessions[p]
end
function PlayerDataService.IsLoaded(p)return PlayerDataService.Get(p).Loaded end
function PlayerDataService.SetEquippedDumbbell(p,id)
 local s=PlayerDataService.Get(p)
 if not s.Loaded or (id~="" and not s.Data.OwnedDumbbells[id]) then return false end
 s.Data.EquippedDumbbell=id;p:SetAttribute("EquippedDumbbell",id);return true
end
function PlayerDataService.GetLevelState(p)
 local s=PlayerDataService.Get(p);if not s.Loaded then return nil end
 return s.Data.Level,s.Data.LevelProgress,s.Data.LevelCurveVersion
end
function PlayerDataService.RecordStrengthGain(p,gain)
 local s=PlayerDataService.Get(p)
 table.insert(s.Events,{Time=workspace:GetServerTimeNow(),Gain=gain,Strength=s.Data.Strength,Level=s.Data.Level,Progress=s.Data.LevelProgress})
end
-- INSERT_PRODUCTION_ADD_STRENGTH_GAIN
return PlayerDataService
