-- Temporary Studio-only client observation. No gameplay or GUI design changes.
if not game:GetService("RunService"):IsStudio() then return end
local p=game.Players.LocalPlayer
local Http=game:GetService("HttpService")
local value=Instance.new("StringValue") value.Name="World1AuditClientResults" value.Parent=p:WaitForChild("PlayerGui")
local rows={}
local evidence=workspace:WaitForChild("World1AuditEvidence",45)
local remote=game.ReplicatedStorage.Remotes.GameRemotes.CombatState
local function publish() value.Value=Http:JSONEncode(rows) end
remote.OnClientEvent:Connect(function(d)
 if not evidence then return end
 local phase=evidence:GetAttribute("Phase")
 if phase~="Wall" and phase~="Boss" then return end
 if d.Type=="CombatAttack" or d.Type=="BossResult" or d.Type=="StageCleared" or d.Type=="Fighting" or d.Type=="BossGauge" then
  local row={Type=d.Type,Phase=phase,Stage=evidence:GetAttribute("Stage"),PacketStage=d.Stage or d.MajorStage,Active=d.Active,Current=d.Current,Max=d.Max,Result=d.Result,CombatType=d.CombatType}
  table.insert(rows,row)
  if d.Type=="CombatAttack" then
   task.delay(.1,function()
    local bosses,walls={},{}
    for _,v in workspace:GetDescendants() do
     if v:IsA("BillboardGui") and v.Name=="PersonalGauge" and v.Enabled then table.insert(bosses,v:GetFullName()) end
     if v:IsA("Frame") and v.Name=="HPBar" and v.Visible and v.Parent and v.Parent.Parent and v.Parent.Parent.Name=="StageSurface" then table.insert(walls,v:GetFullName()) end
    end
    row.VisibleBossGauges=bosses row.VisibleWallBars=walls publish()
   end)
  end
  publish()
 end
end)

