-- Native GUI Instances in an UNPARENTED fixture. No Player/physics/real clock/network.
return function(Sources,originalBoard,originalArea)
 local result={Kind="Native Edit GUI + client lifecycle simulation (not Play)",Assertions=0}
 local function check(v,msg)result.Assertions+=1;assert(v,msg)end
 local root=Instance.new("Folder")
 local board=originalBoard:Clone();board.Name="EventBoard";board.Parent=root
 local folder=Instance.new("Folder");folder.Name="Treadmills";folder.Parent=root
 local machine=Instance.new("Model");machine.Name="Diamond01";machine.Parent=folder
 local area=originalArea:Clone();area.Parent=machine
 local state=Instance.new("StringValue");local owner=Instance.new("Folder");local owner2=Instance.new("Folder")
 local stop
 local ok,err=xpcall(function()
  local callbacks={}
  local heartbeat={}
  function heartbeat:Connect(f)
   local c={Connected=true};function c:Disconnect() self.Connected=false end
   table.insert(callbacks,{f,c});return c
  end
  function heartbeat:Fire() for _,r in callbacks do if r[2].Connected then r[1](.1) end end end
  local function active() local n=0 for _,r in callbacks do if r[2].Connected then n+=1 end end return n end
  local rs={Modules={World1PremiumTreadmillEventSchedule="schedule",World1PremiumTreadmillEventPresentation="view"},
   Config={World1PremiumTreadmillEventStyle="style"}}
  function rs:FindFirstChild(name)return name=="World1PremiumTreadmillEventState" and state or nil end
  local now=DateTime.fromUniversalTime(2040,2,29,9,45).UnixTimestamp+1
  local ws={FindFirstChild=function(_,name)return root:FindFirstChild(name)end,GetServerTimeNow=function()return now end}
  local H=game:GetService("HttpService") -- JSON encode/decode only.
  local services={ReplicatedStorage=rs,Workspace=ws,RunService={Heartbeat=heartbeat},HttpService=H}
  local proxy={ReplicatedStorage=rs,GetService=function(_,name)return assert(services[name],"Forbidden service: "..name)end}
  local modules={}
  local function load(path)
   local f=assert(loadstring(Sources[path],"="..path))
   setfenv(f,setmetatable({game=proxy,workspace=ws,require=function(ref)return assert(modules[ref],ref)end},{__index=getfenv()}))
   return f()
  end
  modules.style=load("ReplicatedStorage.Config.World1PremiumTreadmillEventStyle")
  modules.schedule=load("ReplicatedStorage.Modules.World1PremiumTreadmillEventSchedule")
  modules.view=load("ReplicatedStorage.Modules.World1PremiumTreadmillEventPresentation")
  local S,V,style=modules.schedule,modules.view,modules.style
  local plan=S.Compile({Enabled=true,EventDateJST="2040-02-29",EventStartTimeJST="18:45",StartIntervalSeconds=1800,OpenDurationSeconds=180})
  local epoch=plan.StartUnixSeconds;state.Value=H:JSONEncode(plan)
  local runtime=load("ReplicatedStorage.Modules.World1PremiumTreadmillEventClientRuntime")
  stop=runtime.Start(owner)
  check(active()==1,"one update connection")
  local gui=board.Board.SurfaceGui
  local floating=area.PremiumEventCountdown
  check(gui.Event1.Text=="Premium Treadmill" and gui.Event2.Text=="Free","two exact headings")
  check(gui.Event2.TextSize>gui.Event1.TextSize and gui.Event1.TextSize>48,"size hierarchy")
  check(gui.Event2.TextColor3==style.FreeColor and gui.Event2.TextTransparency==0,"opaque red Free")
  check(gui.Event3.Text=="Now! 02:59" and floating.Time.Text=="02:59","shared clock string")
  check(gui.Event3.TextColor3==style.OpenColor and gui.Event3.UIStroke.Thickness==style.OpenStrokeThickness,"open emphasis")
  check(gui.Event3.UIStroke.StrokeSizingMode==Enum.StrokeSizingMode.FixedSize,"stroke units")
  check(board.Board.Transparency==.5 and board.Part.Transparency==.5,"visible body")
  local beforeCount=#board:GetDescendants()+#area:GetDescendants()
  for _=1,10 do V.BindBoard(board);V.BindOverhead(machine) end
  heartbeat:Fire()
  check(#board:GetDescendants()+#area:GetDescendants()==beforeCount,"idempotent binding")
  local changes=0;local changed=gui.Event3:GetPropertyChangedSignal("Text"):Connect(function()changes+=1 end)
  for _=1,20 do heartbeat:Fire()end;task.wait()
  check(changes==0,"no Text writes when second unchanged")
  now=epoch+2;heartbeat:Fire();task.wait()
  check(changes==1 and gui.Event3.Text=="Now! 02:58","one new second write")
  changed:Disconnect()
  now=epoch+181;heartbeat:Fire()
  check(gui.Event3.Text=="Next 26:59" and not floating.Enabled,"waiting hides overhead")
  check(gui.Event3.TextColor3==style.White and gui.Event3.UIStroke.Thickness==style.StrokeThickness,"waiting restores white")
  now=epoch+84780;heartbeat:Fire()
  check(gui.Enabled and not gui.Event3.Visible and gui.Event3.Text=="","last interval, no fake next")
  now=epoch+86400;heartbeat:Fire()
  check(not gui.Enabled and board.Board.Transparency==1 and board.Part.Transparency==1,"day end hides whole board")
  now=epoch-1;heartbeat:Fire()
  check(not gui.Enabled and not floating.Enabled,"before day hidden")
  now=epoch+1800;heartbeat:Fire()
  check(gui.Event3.Text=="Now! 03:00" and board.Board.Transparency==.5 and board.Board.Color==style.BoardColor,"restoration")
  state.Value="invalid json";heartbeat:Fire()
  check(not gui.Enabled and not floating.Enabled,"invalid replicated data fail closed")
  state.Value=H:JSONEncode({Valid=false,Version=1,Reason="StartTimeUnset"});heartbeat:Fire()
  check(not gui.Enabled,"unset start time hidden")
  state.Value=H:JSONEncode(plan);heartbeat:Fire()
  check(gui.Enabled and floating.Enabled,"valid snapshot restored")
  -- Streaming-like removal/reappearance of the whole object and individual descendants.
  board.Parent=nil;area.Parent=nil;heartbeat:Fire()
  board.Parent=root;area.Parent=machine;heartbeat:Fire()
  check(gui.Enabled and floating.Enabled,"stream reappearance")
  local label=gui.Event3;label.Parent=nil;heartbeat:Fire()
  check(not gui.Enabled,"partial board hidden")
  label.Parent=gui;heartbeat:Fire()
  check(gui.Enabled and gui.Event3==label,"same three labels reused")
  local countBeforePartial=#area:GetChildren()
  floating.Parent=nil;heartbeat:Fire()
  check(#area:GetChildren()==countBeforePartial-1,"partial streaming cannot create a duplicate Billboard")
  floating.Parent=area;heartbeat:Fire()
  check(floating.Enabled,"authored Billboard arrival resumes")
  local frame=board.Part;frame.Parent=nil;heartbeat:Fire()
  check(not gui.Enabled,"partial board frame hidden")
  frame.Parent=board;heartbeat:Fire()
  check(gui.Enabled and frame.Transparency==.5,"frame reappearance restores")
  local oldCF=area.CFrame;area.CFrame=oldCF+Vector3.new(10,2,4);heartbeat:Fire()
  check(floating.Adornee==area and floating.StudsOffsetWorldSpace==style.OverheadOffset,"relative attachment follows equipment")
  area.CFrame=oldCF
  stop=runtime.Start(owner2)
  check(active()==1,"reinitialize disconnects previous update")
  check(#board:GetDescendants()+#area:GetDescendants()==beforeCount,"reinitialize no duplicated GUI")
  stop();check(active()==0 and not gui.Enabled and not floating.Enabled,"explicit cleanup")
  stop=runtime.Start(owner);owner:Destroy();task.wait()
  check(active()==0,"owner destroy cleanup")
  result.InstanceCount=beforeCount;result.RefreshSeconds=style.RefreshSeconds
  result.TextChangesFor20UnchangedUpdates=0
 end,debug.traceback)
 if stop then stop()end
 root:Destroy();board:Destroy();area:Destroy();state:Destroy();owner:Destroy();owner2:Destroy()
 assert(ok,err)
 return result
end
