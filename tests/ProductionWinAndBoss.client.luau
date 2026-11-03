local RS=game.ReplicatedStorage
local p=game.Players.LocalPlayer
local records={}
RS.Remotes.EnemyDropGachaResult.OnClientEvent:Connect(function(r)
 if r.OwnerUserId~=p.UserId then return end
 records[r.Id]={Notice=r}
 task.delay(.35,function()
  local row=records[r.Id];row.BagCount=p:GetAttribute("RunInventoryCount")
  local label=p.PlayerGui.StrengthGui.HUD.RunInventoryLabel
  row.BagText=label.Text;row.BagVisible=label.Visible
 end)
end)
p.PlayerGui.ChildAdded:Connect(function(g)
 if g.Name=="PersonalDropReward" then
  local id=g:GetAttribute("RewardId")
  if records[id] then records[id].Overhead={Icon=g.Icon.Image,Points=g:FindFirstChild("Points") and g.Points.Text} end
 end
end)
local bf=Instance.new("BindableFunction");bf.Name="__WBQAClient";bf.Parent=RS
bf.OnInvoke=function()
 local g=p.PlayerGui.StrengthGui
 return {Drops=records,BagText=g.HUD.RunInventoryLabel.Text,BagVisible=g.HUD.RunInventoryLabel.Visible,WinText=g.HUD.WinAmount.Main.Text,Win=p:GetAttribute("Win")}
end
