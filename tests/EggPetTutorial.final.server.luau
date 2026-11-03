local RS=game.ReplicatedStorage
local D=require(game.ServerScriptService.Services.PlayerDataService)
local E=require(game.ServerScriptService.Services.EggServer)
local H=game.HttpService
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local function idle()
 for i=1,200 do local s=D.Get(p);if s and s.Loaded and not s.Saving and not s.PendingItemMutation then return s end;task.wait(.1)end error("wait")
end
local s=idle();if s.StudioStartOverride then D.RestoreStudioStartOverride(p)end
idle();assert(D.Reset(p));D.SetAutoTapEnabled(p,false);D.SetWin(p,3)
repeat task.wait(.1)until p.Character and p.Character:FindFirstChild("HumanoidRootPart")
p:SetAttribute("CurrentWorld",1);p.Character.HumanoidRootPart.Anchored=true;p.Character:PivotTo(workspace.Eggs.Basic.CFrame+Vector3.new(0,0,5))
local function request(action,a,b)
 local state,_,g=D.GetPetState(p);return E.request(p,action,H:GenerateGUID(false),state.Revision,a,b,g)
end
local early={Before=D.Get(p).Data.TutorialCompleted,Purchase=request("OpenEgg","Basic","Open1")}
assert(early.Purchase.ok);task.wait(.8)
early.Equip=request("BestEquip")
assert(early.Equip.ok)
local remote=Instance.new("RemoteFunction");remote.Name="__EggFinalQA"
remote.OnServerInvoke=function(_,action)
 if action=="Early"then return early
 elseif action=="CompleteFloor"then assert(D.CompleteTutorial(p));return true
 elseif action=="ResetEligible"then idle();assert(D.Reset(p));assert(D.CompleteTutorial(p));D.SetWin(p,3);require(game.ServerScriptService.Services.LobbySpawnService).MoveToLobby(p,p.Character,1);p.Character.HumanoidRootPart.Anchored=true;return true
 elseif action=="Done"then return D.Get(p).Data.EggPetTutorial end
end
remote.Parent=RS
