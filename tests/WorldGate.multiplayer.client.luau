local RS=game.ReplicatedStorage
local p=game.Players.LocalPlayer
local gui=p:WaitForChild("PlayerGui"):WaitForChild("WorldTravelGui")
local qa=RS:WaitForChild("__GateQAMulti",45)
local remote=RS.Remotes.WorldTravelRequest
local events={}
remote.OnClientEvent:Connect(function(r)table.insert(events,r)end)
local report={}
local function call(a,v)return qa:InvokeServer(a,v)end
local function waitFor(fn,t)
 local limit=os.clock()+(t or 20)
 repeat local v=fn();if v then return v end;task.wait(.05)until os.clock()>limit
 error("Gate native client timeout")
end
local function check(name,condition,data)
 assert(condition,name);table.insert(report,{Name=name,Passed=true,Evidence=data})
end
local function count(kind)local n=0 for _,r in events do if r.Type==kind then n+=1 end end return n end
local function walk()
 local c=p.Character;local r=c.HumanoidRootPart
 local wall=require(RS.Modules.WorldGateContact).Wall(p:GetAttribute("CurrentWorld")==2 and 2 or 1)
 local pos=wall.CFrame:PointToWorldSpace(Vector3.new(0,0,-8))
 c.Humanoid:MoveTo(Vector3.new(pos.X,r.Position.Y,pos.Z))
end
local function enter()
 call("AtGate");task.wait(.5);walk();waitFor(function()return gui.Modal.Visible end)
 task.wait(.5);local s=call("Status")
 check("Native walking blocked at wall; private prompt",s.Touching and s.WallDistance>.25 and s.WallDistance<3,s)
end
local function click(id)
 _G.__GateQACallbacks[gui.Modal.Card.WorldList["World"..id].Action]()
end
local ok,err=xpcall(function()
 local rank=call("Ready");waitFor(function()return _G.__GateQACallbacks end)
 if rank==1 then
  enter()
  check("Unlocked W2 and locked W3",gui.Modal.Card.WorldList.World2.Action.Label.Text=="Teleport" and gui.Modal.Card.WorldList.World3.Action.Label.Text=="Locked")
  local opens=count("Open");_G.__GateQAClose();task.wait(.6)
  check("Close while touching stays closed",not gui.Modal.Visible and count("Open")==opens)
  enter();check("Leave and recontact re-arms once",count("Open")==opens+1)
  for i=1,6 do click(2)end
  waitFor(function()return p:GetAttribute("CurrentWorld")==2 and not gui.Modal.Visible end)
  local peer=call("Peer");check("Travel is private",peer.World==1 and peer.Highest==1,peer)
  local before=count("Open");task.wait(.5)
  check("Arrival outside gate, no reopen",not gui.Modal.Visible and count("Open")==before and not call("Status").Touching)
  call("Phase",1);call("WaitPhase",2)
  enter()
  check("W2 current, W1 teleport",gui.Modal.Card.WorldList.World2.Action.Label.Text=="Current" and gui.Modal.Card.WorldList.World1.Action.Label.Text=="Teleport")
  click(1);waitFor(function()return p:GetAttribute("CurrentWorld")==1 and not gui.Modal.Visible end)
  call("Die");call("Respawn");task.wait(.3)
  check("Death respawn does not reopen/duplicate GUI",not gui.Modal.Visible and gui.Parent==p.PlayerGui)
  enter();check("Contact still works after respawn",gui.Modal.Visible)
  _G.__GateQAClose();call("Phase",3)
 else
  call("WaitPhase",1)
  check("Peer contact/travel did not open local UI",not gui.Modal.Visible and count("Open")==0 and call("Status").World==1)
  enter()
  check("Locked player sees cards but cannot activate",gui.Modal.Card.WorldList.World2.Action.Label.Text=="Locked" and not gui.Modal.Card.WorldList.World2.Action.Active)
  local n=#events;remote:FireServer("Teleport",2)
  waitFor(function()return #events>n and events[#events].Type=="Result"end)
  check("Direct locked W2 request denied",events[#events].Code=="Locked" and call("Status").World==1)
  task.wait(1.1);n=#events;remote:FireServer("Teleport",3)
  waitFor(function()return #events>n and events[#events].Type=="Result"end)
  check("Unprepared W3 request denied",events[#events].Code=="Locked")
  _G.__GateQAClose();call("Phase",2);call("WaitPhase",3)
  call("Unlock");task.wait(.3)
  enter();click(2);waitFor(function()return p:GetAttribute("CurrentWorld")==2 end)
  check("Independent second-player unlock and travel",call("Peer").World==1 and not gui.Modal.Visible)
 end
end,debug.traceback)
call("Report",{Passed=ok,Error=not ok and err or nil,Checks=report})
