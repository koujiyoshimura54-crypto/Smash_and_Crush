-- QA: ordinary client requests and physics; no OS input or gameplay value changes.
local p=game.Players.LocalPlayer
local RS=game.ReplicatedStorage
local measure=RS:WaitForChild('__NightMeasure')
local bridge=Instance.new('BindableFunction');bridge.Name='__NightControl';bridge.Parent=p.PlayerScripts
local generation=0
local requests={}
local allowed={DumbbellPurchaseRequest=true,DumbbellEquipRequest=true,AuraPurchaseRequest=true,AuraEquipRequest=true,AutoTapRequest=true,RebirthRequest=true,ItemEquipRequest=true,ItemPurchaseRequest=true,ItemMergeRequest=true,TimeRewardClaim=true,DailyRewardClaim=true,RunReturnRequest=true}
for name in allowed do
 local r=RS.Remotes:FindFirstChild(name)
 if r and r:IsA('RemoteEvent')then r.OnClientEvent:Connect(function(data)requests[name]=data;if type(data)=='table'and(data.Success~=nil or data.Type~=nil)then measure:FireServer('ClientEvent',{Remote=name,Data=data})end end)end
end
task.spawn(function()
 repeat task.wait(.1)until p.Character and p.Character:FindFirstChildOfClass('Humanoid')and p.Character:FindFirstChild('HumanoidRootPart')and type(p:GetAttribute('Strength'))=='number'and p.PlayerGui:FindFirstChild('StrengthGui')
 measure:FireServer('Start',{ClientUTC=DateTime.now().UnixTimestampMillis/1000})
end)
local function stop()
 generation+=1
 local c=p.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local r=c and c:FindFirstChild('HumanoidRootPart')
 if h and r then h:MoveTo(r.Position);h:Move(Vector3.zero,false)end
end
local oldStage=p:GetAttribute('CurrentStage')or 1
p:GetAttributeChangedSignal('CurrentStage'):Connect(function()local s=p:GetAttribute('CurrentStage')or 1;if s<oldStage then stop()end;oldStage=s end)
bridge.OnInvoke=function(op,arg)
 if op=='Phase'then measure:FireServer('Phase',arg.Phase,arg.Reason);return true end
 if op=='StopMove'then stop();return true end
 if op=='Move'then
  generation+=1;local own=generation
  local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid');assert(h and h.Health>0)
  local destination=Vector3.new(arg[1],arg[2],arg[3])
  measure:FireServer('Phase','movement',arg.Reason or 'Normal MoveTo')
  task.spawn(function()
   while generation==own and h.Parent and h.Health>0 do
    local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
    if not r or (Vector3.new(r.Position.X,0,r.Position.Z)-Vector3.new(destination.X,0,destination.Z)).Magnitude<2 then break end
    h:MoveTo(destination);task.wait(.5)
   end
  end);return true
 end
 if op=='Jump'then p.Character:FindFirstChildOfClass('Humanoid').Jump=true;return true end
 if op=='Fire'then
  assert(allowed[arg.Name],'Request not audited')
  local r=RS.Remotes:FindFirstChild(arg.Name);assert(r and r:IsA('RemoteEvent'),'Remote unavailable')
  requests[arg.Name]=nil;r:FireServer(table.unpack(arg.Args or {},1,arg.Count or #(arg.Args or {})))
  measure:FireServer('Phase','operations','Normal UI request '..arg.Name)
  return {Sent=true}
 end
 if op=='Replies'then return requests end
 if op=='Invoke'then assert(({TimeRewardState=true,DailyRewardState=true,ItemInventoryState=true,DumbbellInventoryState=true,AuraInventoryState=true})[arg.Name]);return RS.Remotes[arg.Name]:InvokeServer()end
 if op=='Forge'then
  local f=require(RS.Modules.ForgeClient);f.Refresh()
  return {Accepted=f.Request(arg.Action,arg.Fields or {})}
 end
 if op=='ForgeState'then local f=require(RS.Modules.ForgeClient);return f.Refresh()end
 if op=='Config'then
  local b=require(RS.Config.World1BossConfig);local m=require(RS.Config.DumbbellItemMaster);local bosses={}
  for i=1,10 do bosses[i]={Boss=b.GetMaxHP(i),Walls=b.GetWallConfig(i).Walls,Required=b.GetRequiredStrength(i)}end
  return {Bosses=bosses,Dumbbells=m.GetSorted(1)}
 end
 if op=='Status'then local c=p.Character;local r=c and c:FindFirstChild('HumanoidRootPart');return {Position=r and {r.Position.X,r.Position.Y,r.Position.Z},Strength=p:GetAttribute('Strength'),Stage=p:GetAttribute('CurrentStage')}end
 error('Unknown operation')
end
