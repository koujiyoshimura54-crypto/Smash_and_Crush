-- Native Play observation; data/services redirected to memory before Play starts.
assert(game:GetService('RunService'):IsStudio() and game.ReplicatedStorage:FindFirstChild('__FirstBattleMemory'))
local RS=game.ReplicatedStorage;local q=RS.__FirstBattleQA
local joined={};local events={};local logs={}
local function join(p) joined[p]=workspace:GetServerTimeNow() end
game.Players.PlayerAdded:Connect(join);for _,p in game.Players:GetPlayers() do join(p) end
game:GetService('LogService').MessageOut:Connect(function(text,kind)
 if kind==Enum.MessageType.MessageError or kind==Enum.MessageType.MessageWarning then logs[#logs+1]={Message=text,Kind=kind.Name} end
end)
local D=require(game.ServerScriptService.Services.PlayerDataService)
local function state(p)
 local s=D.Get(p);local d=s and s.Data
 if not d then return {Loaded=false} end
 return {Loaded=s.Loaded,Level=d.Level,Strength=d.Strength,Win=d.Win,Ores=table.clone(d.OwnedOres),Facts=table.clone(d.FirstBattleTutorial),
  Ore=table.clone(d.OreMergeTutorial),Equipment=table.clone(d.EquipmentTutorial),Dumbbell=d.EquippedDumbbell,Pending=s.PendingItemMutation~=nil,
  Auto=d.AutoTapEnabled,Stage=p:GetAttribute('CurrentStage'),World=p:GetAttribute('CurrentWorld')}
end
local function record(p,name,details)
 events[#events+1]={Name=name,At=workspace:GetServerTimeNow()-(joined[p] or workspace:GetServerTimeNow()),Details=details,State=state(p)}
end
local function watch(p)
 for _,name in {'Level','FirstBattleStarted','FirstBattleOutcome','FirstBattleStage1Defeated','OreTutorialCompleted','DumbbellEquipTutorialInitialCompleted','Stage1SubStage'} do
  p:GetAttributeChangedSignal(name):Connect(function()record(p,name,p:GetAttribute(name)) end)
 end
end
game.Players.PlayerAdded:Connect(watch);for _,p in game.Players:GetPlayers()do watch(p)end
q.Report.OnServerEvent:Connect(record)
q.State.OnServerInvoke=function(p) return state(p) end
local inspect=Instance.new('BindableFunction');inspect.Name='Inspect';inspect.Parent=q
inspect.OnInvoke=function()
 local p=game.Players:GetPlayers()[1]
 return {State=p and state(p),Events=events,Logs=logs,Analytics=require(game.ServerScriptService.Services.FirstPlayAnalyticsTransport).StudioRecords()}
end
