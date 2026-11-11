local RS=game.ReplicatedStorage;local D=require(game.ServerScriptService.Services.PlayerDataService);local M=require(RS.__EarlyQAMemory);local T=require(game.ServerScriptService.Services.TimeRewardService)
local b=Instance.new("BindableFunction");b.Name="Fault";b.Parent=RS.__EarlyQABoundary
b.OnInvoke=function(action,value)
 local p=game.Players:GetPlayers()[1]
 if action=="Hold"then M.HoldWrites=value;return M.BlockedWrites end
 if action=="FailAfter"then M.FailAfter=value;return true end
 if action=="State"then local d=D.Get(p).Data;return {Rewards=T.GetState(p),Ores=d.OwnedOres,Win=d.Win,Strength=d.Strength,Level=d.Level,Progress=d.LevelProgress,Pending=D.Get(p).PendingItemMutation~=nil,Stored=M.DataStoreService:GetDataStore("PlayerData_v1_Studio"):GetAsync("Player_"..p.UserId)}end
 error("bad action")
end
