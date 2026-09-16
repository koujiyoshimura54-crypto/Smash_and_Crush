local p=game.Players.LocalPlayer
local control=p.PlayerGui.BossDisplayQAClient
local e=workspace.Enemies.Stage01_Enemy
local g=e:FindFirstChild("PersonalGauge",true)
local s=g.Adornee
local w=workspace.GeneratedMap.BattleCorridor.Stage02["Stage2.1"].Wall
local function read()
 return {center=g:GetAttribute("BossDisplayCenterY"),position={s.CFrame:GetComponents()},size={s.Size.X,s.Size.Y,s.Size.Z},wall={w.CFrame:GetComponents()},wallSize={w.Size.X,w.Size.Y,w.Size.Z},alpha=s.Transparency,height=e:GetAttribute("BossDisplayHeight")}
end
local out={baseline=read()}
for _,action in {"offset","restore","ratio","restore","gap","restore","alpha","restore","override","restore"} do
 control:SetAttribute("Action",action) task.wait(.65)
 if action~="restore" then out[action]=read() end
end
assert(math.abs(out.offset.center-out.baseline.center-2)<.001)
assert(math.abs(out.ratio.center-out.baseline.center-out.baseline.height*.1)<.001)
assert(math.abs(out.override.center-out.baseline.center-3)<.001)
assert(math.abs(out.alpha.alpha-.6)<.001)
assert(math.abs(out.gap.position[3]-out.baseline.position[3]+.5)<.001)
local oldSize,oldCF=w.Size,w.CFrame
w.Size+=Vector3.new(0,20,0);w.CFrame+=Vector3.new(0,10,0)
task.wait(.65)
out.tallerWall=read()
assert(math.abs(out.tallerWall.center-out.baseline.center)<.001)
w.Size=oldSize;w.CFrame=oldCF;task.wait(.65)
local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={s,w}
local hit=workspace:Raycast(s.Position+Vector3.new(0,0,-5),Vector3.new(0,0,10),rp)
assert(hit and hit.Instance==w)
out.raycastHit=hit.Instance:GetFullName()
out.restored=read()
return game:GetService("HttpService"):JSONEncode(out)
