local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService)
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
repeat task.wait(.1)until D.Get(p) and D.Get(p).Loaded
D.SetAutoTapEnabled(p,false)
local d=D.Get(p).Data
local id=require(game.ReplicatedStorage.Config.DumbbellItemMaster).GetSorted(2)[1].ItemId
d.OwnedDumbbells[id]=2;d.EquippedDumbbell="";d.OwnedAuras={};d.EquippedAura=""
d.World2Visited=false;D.Get(p).World2VisitedThisPlay=false;p:SetAttribute("World2Visited",false);p:SetAttribute("CurrentWorld",1)
D.SetWin(p,1000000);D.Save(p)
local q=Instance.new("BindableFunction");q.Name="__UI4QAServer";q.Parent=game.ServerStorage
q.OnInvoke=function(action)
 if action=="Unlock"then D.UnlockWorld(p,2);D.MarkWorld2Reached(p);p:SetAttribute("CurrentWorld",2)
 elseif action=="Return"then p:SetAttribute("CurrentWorld",1)
 elseif action=="Lock"then d.World2Visited=false;D.Get(p).World2VisitedThisPlay=false;p:SetAttribute("World2Visited",false)
 elseif action=="Death"then p.Character.Humanoid.Health=0
 end
 return {World2=D.HasReachedWorld2(p),W2Id=id,Owned=d.OwnedDumbbells[id],Equipped=d.EquippedDumbbell,Win=d.Win,Auras=d.OwnedAuras,EquippedAura=d.EquippedAura}
end
