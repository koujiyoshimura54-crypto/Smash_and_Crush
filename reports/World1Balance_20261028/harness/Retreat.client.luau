-- QA ordinary backward input inside the current authored arena after contact.
local p=game.Players.LocalPlayer
local control=p.PlayerScripts:WaitForChild('__NightControl')
local elapsed=0;local stage;local floor;local acted={}
script:SetAttribute('EnabledInput',false)
game:GetService('RunService').Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.1 then return end;elapsed=0
 local n=p:GetAttribute('CurrentStage')or 1
 if n~=stage then stage=n;floor=nil;if n==1 then acted={}end end
 if not script:GetAttribute('EnabledInput')or n<8 or acted[n]or not p:GetAttribute('IsFighting')then return end
 local c=p.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local root=c and c:FindFirstChild('HumanoidRootPart')
 if not h or h.Health<=0 or not root then return end
 if not floor then
  local map=workspace:FindFirstChild('GeneratedMap');local corridor=map and map:FindFirstChild('BattleCorridor')
  local s=corridor and corridor:FindFirstChild(('Stage%02d'):format(n));local arena=s and s:FindFirstChild('Stage'..n..'.5')
  floor=arena and arena:FindFirstChild('Floor')
 end
 if not floor or math.abs(root.Position.Z-floor.Position.Z)>16 then return end
 acted[n]=true
 local destination={floor.Position.X,floor.Position.Y+floor.Size.Y/2+3,floor.Position.Z-floor.Size.Z/2+10}
 game.ReplicatedStorage.__NightMeasure:FireServer('ClientEvent',{Remote='QANormalRetreat',Data={Type='Retreat',Stage=n,From={root.Position.X,root.Position.Y,root.Position.Z},To=destination}})
 control:Invoke('Move',destination)
end)
