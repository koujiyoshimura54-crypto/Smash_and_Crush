-- Native client inputs; fixture only. Button rendering remains production code.
local RS=game.ReplicatedStorage
local p=game.Players.LocalPlayer
local Q=RS:WaitForChild("__AutoJoinQA")
local sawOn=false
local function button()local g=p:FindFirstChild("PlayerGui");return g and g:FindFirstChild("AutoTapButton",true)end
local watch=game:GetService("RunService").RenderStepped:Connect(function()
 if not Q:GetAttribute("InputsStarted") then local b=button();if b and b.State.Text=="ON" then sawOn=true end end
end)
local function waitFor(fn,t)
 local untilAt=os.clock()+(t or 15)
 repeat local v=fn();if v then return v end;task.wait(.03)until os.clock()>untilAt
 error("AutoJoin client timeout")
end
local function status()
 local b=waitFor(button)
 return {Text=b.State.Text,Attribute=p:GetAttribute("AutoTapEnabled"),SawOnBeforeInput=sawOn,
 GradientTop=tostring(b.UIGradient.Color.Keypoints[1].Value),World=p:GetAttribute("CurrentWorld")}
end
Q.Call.OnClientInvoke=function(action,arg)
 local ok,value=xpcall(function()
  if action=="Status" then return status()
  elseif action=="Toggle" then
   local before=p:GetAttribute("AutoTapEnabled")
   RS.Remotes.AutoTapRequest:FireServer("Toggle")
   waitFor(function()return p:GetAttribute("AutoTapEnabled")~=before end)
   task.wait(.1);return status()
  elseif action=="Tap" then RS.Remotes.AutoTapRequest:FireServer("Tap");task.wait(.2);return status()
  elseif action=="Walk" then
   local c=p.Character;local r=c.HumanoidRootPart;local h=c.Humanoid;local start=r.Position
   h:MoveTo(start+Vector3.new(16,0,0));task.wait(1.3);h:MoveTo(r.Position);task.wait(.3)
   return {Distance=(r.Position-start).Magnitude,State=status()}
  elseif action=="Travel" then
   local c=p.Character;local r=c.HumanoidRootPart
   local wall=require(RS.Modules.WorldGateContact).Wall(p:GetAttribute("CurrentWorld")==2 and 2 or 1)
   local target=wall.CFrame:PointToWorldSpace(Vector3.new(0,0,-8))
   c.Humanoid:MoveTo(Vector3.new(target.X,r.Position.Y,target.Z))
   waitFor(function()local g=p.PlayerGui:FindFirstChild("WorldTravelGui");return g and g.Modal.Visible end)
   c.Humanoid:MoveTo(r.Position);task.wait(.15)
   RS.Remotes.WorldTravelRequest:FireServer("Teleport",arg)
   waitFor(function()return p:GetAttribute("CurrentWorld")==arg end,25)
   task.wait(.5);return status()
  end
  error("Unknown action")
 end,debug.traceback)
 return {OK=ok,Value=ok and value or nil,Error=not ok and value or nil}
end
