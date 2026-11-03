-- Temporary fixture only: install with memory adapters before running.
assert(game.ReplicatedStorage:FindFirstChild("__InvQAMemory"),"Memory isolation required")
local RS=game.ReplicatedStorage
local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService)
local F=require(S.ForgeService)
local endpoint=Instance.new("BindableFunction");endpoint.Name="__InvQAControl";endpoint.Parent=RS
endpoint.OnInvoke=function(action,args)
 local p=game.Players:GetPlayers()[1]
 assert(p and D.Get(p) and D.Get(p).Loaded,"Player not ready")
 local s=D.Get(p)
 if action=="Setup" then
  D.SetAutoTapEnabled(p,false)
  s.Data.OwnedDumbbells={NORMAL_01=5,NORMAL_02=1,NORMAL_03=2,NORMAL_04=3,NORMAL_05=1,NORMAL_06=1}
  s.Data.EquippedDumbbell="NORMAL_02";p:SetAttribute("EquippedDumbbell","NORMAL_02")
  D.SetWin(p,10000);s.Dirty=true
  p:SetAttribute("World2Visited",false)
  p:SetAttribute("ForgeInventoryRevision",(p:GetAttribute("ForgeInventoryRevision") or 0)+1)
 elseif action=="Counts" then
  s.Data.OwnedDumbbells=args.Counts;s.Data.EquippedDumbbell=args.Equipped or "";p:SetAttribute("EquippedDumbbell",s.Data.EquippedDumbbell)
  D.SetWin(p,args.Win or 10000);s.Dirty=true
  p:SetAttribute("ForgeInventoryRevision",(p:GetAttribute("ForgeInventoryRevision") or 0)+1)
 elseif action=="Direct" then return F.Request(p,args)
 elseif action=="Death" then p.Character.Humanoid.Health=0
 elseif action=="Save" then return D.Save(p,"DumbbellUIQA")
 elseif action=="Unlock" then D.UnlockWorld(p,2);D.MarkWorld2Reached(p)
 end
 return F.State(p)
end
