local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService)
local I=require(S.ItemService)
local Strength=require(S.StrengthManager)
local p=game.Players:GetPlayers()[1]
local results={Rows={}}
local original=Strength.AddStrength
local phase="Empty"
Strength.AddStrength=function(player,amount,count,multiplier)
 local before=player:GetAttribute("Strength")
 local a,b=original(player,amount,count,multiplier)
 if player==p and multiplier then results.Rows[#results.Rows+1]={Phase=phase,Amount=amount,Multiplier=multiplier,Delta=player:GetAttribute("Strength")-before,Belt=I.GetBeltTreadmillBonus(player)} end
 return a,b
end
local ok,e=xpcall(function()
 local r=p.Character.HumanoidRootPart
 local h=p.Character.Humanoid
 local area=workspace.Treadmills.Normal01.Area
 r.Anchored=true;r.CFrame=CFrame.new(area.Position+Vector3.new(0,h.HipHeight+r.Size.Y/2+.1,0))
 r.AssemblyLinearVelocity=Vector3.zero;r.Anchored=false;r:SetNetworkOwner(nil)
 local function sample()
  local start=#results.Rows;local deadline=os.clock()+8
  repeat task.wait(.05) until #results.Rows>=start+2 or os.clock()>deadline
  assert(#results.Rows>=start+2,"No normal treadmill ticks")
 end
 sample()
 game.ServerStorage.__AutoBeltVisual:Invoke("Equip")
 phase="Equipped";sample()
 game.ServerStorage.__AutoBeltVisual:Invoke("Reset")
 phase="Reset";sample()
end,debug.traceback)
Strength.AddStrength=original
results.Passed=ok;results.Error=not ok and e or nil
local out=Instance.new("StringValue");out.Name="__AutoBeltTreadmillResult";out.Value=game.HttpService:JSONEncode(results);out.Parent=game.ReplicatedStorage
