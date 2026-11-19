assert(game.PlaceId==126576845524886 and game.GameId==10765181857 and not game:GetService("RunService"):IsRunning())
local H=game:GetService("HttpService")
local S={}
for _,path in {"ReplicatedStorage.Config.WorldPassConfig","ReplicatedStorage.Config.TreadmillConfig","ReplicatedStorage.Config.World2GameplayConfig","ReplicatedStorage.Config.TrainingConfig","ReplicatedStorage.Config.LevelRequirements","ReplicatedStorage.Config.RebirthConfig","ReplicatedStorage.Config.SpeedConfig","ReplicatedStorage.Config.AutoTapConfig","ReplicatedStorage.Config.SlapPassConfig","ReplicatedStorage.Modules.LevelProgression","ReplicatedStorage.Modules.StrengthCalculation","ServerScriptService.Services.StrengthManager","ServerScriptService.Services.AutoTapService","ServerScriptService.Services.PlayerActionTiming","ServerScriptService.Config.World1PremiumTreadmillEventConfig","ServerScriptService.Services.World1PremiumTreadmillEventSchedule","ServerScriptService.Services.World1PremiumTreadmillEvent","ServerScriptService.Systems.Controllers.World1PremiumTreadmillEventController","ServerScriptService.Services.TrainingManager","ServerScriptService.Services.GamePassService","ServerScriptService.Systems.Controllers.GamePassController"} do
 local o=game for n in path:gmatch("[^.]+") do o=assert(o:FindFirstChild(n),path) end
 S[path]=o.Source
 assert(game:GetService("ScriptEditorService"):GetEditorSource(o)==o.Source,"Editor conflict: "..path)
end
local data=game.ServerScriptService.Services.PlayerDataService.Source
S.MemoryMethods=assert(data:match("(function PlayerDataService.AddStrengthGain.-)\nfunction PlayerDataService.ResetStrengthProgress")).."\n"..assert(data:match("(function PlayerDataService.RecordStrengthGain.-\nend)"))
for _,path in {"ReplicatedStorage.Config.World1PremiumTreadmillEventStyle","ReplicatedStorage.Modules.World1PremiumTreadmillEventClientRuntime","ReplicatedStorage.Modules.World1PremiumTreadmillEventPresentation","ReplicatedStorage.Modules.World1PremiumTreadmillEventSchedule","ServerScriptService.Config.World1PremiumTreadmillEventConfig","ServerScriptService.Services.World1PremiumTreadmillEvent","ServerScriptService.Services.World1PremiumTreadmillEventSchedule","ServerScriptService.Systems.Controllers.World1PremiumTreadmillEventController","StarterPlayer.StarterPlayerScripts.UI.World1PremiumTreadmillEventClient","ServerScriptService.Services.TrainingManager","ServerScriptService.Services.GamePassService"} do local o=game for n in path:gmatch("[^.]+")do o=assert(o:FindFirstChild(n),path)end S[path]=o.Source;assert(loadstring(o.Source,"="..path)) end
-- Host supplies checked-in spec text as TestSource and Suite="integration"/"legacy"/"calendar"/"ui".
-- This file never starts Play or requires live game services.
local test=assert(loadstring(TestSource,"=isolated-event.spec"))()
local result
if Suite=="calendar" then
 result=test(assert(loadstring(S["ReplicatedStorage.Modules.World1PremiumTreadmillEventSchedule"]))())
elseif Suite=="ui" then
 result=test(S,workspace.EventBoard,workspace.Treadmills.Diamond01.Area)
else result=test(S) end
return H:JSONEncode(result)
