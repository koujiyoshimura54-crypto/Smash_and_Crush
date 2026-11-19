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
-- Source for tests/StudioPremiumTreadmillEvent.spec.luau or GamePassPhase1.spec.luau
-- is supplied by the read-only host runner as TestSource (never a live ModuleScript require).
assert(type(TestSource)=="string","Pass the checked-in spec text as TestSource")
local runner=assert(loadstring(TestSource,"=isolated-event.spec"))()
return H:JSONEncode(runner(S))
