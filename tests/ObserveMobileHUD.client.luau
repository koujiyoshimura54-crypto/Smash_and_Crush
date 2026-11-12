-- OPT-IN OBSERVER ONLY. Not installed in the canonical place.
-- For a private device check, copy into ReplicatedFirst as a LocalScript.
-- Set its EntryRoute attribute to "app" or "shared-link" for each comparison.
-- Client console lines start [MobileHUDObserve]. No UI/input/data/network writes.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Http=game:GetService("HttpService")
local began=os.clock()
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")
if _G.MobileHUDObserve then _G.MobileHUDObserve.Stop() end
local connections,watched={},{}
local records={}
local cameraConnection
local alive,pending=true,false
local reasons={}
local function xy(v)return {v.X,v.Y}end
local function rect(x)
 if not x or not x:IsA("GuiObject") then return nil end
 return {P=xy(x.AbsolutePosition),S=xy(x.AbsoluteSize),Visible=x.Visible,Active=x.Active}
end
local function sample(reason)
 if not alive then return end
 local camera=workspace.CurrentCamera
 local gui=pg:FindFirstChild("StrengthGui")
 local left=gui and gui:FindFirstChild("LeftMenu")
 local controls={}
 local touch=pg:FindFirstChild("TouchGui")
 if touch then for _,x in touch:GetDescendants() do
  if x.Name=="DynamicThumbstickFrame" or x.Name=="ThumbstickStart" or x.Name=="ThumbstickEnd" or x.Name=="ThumbstickFrame" or x.Name=="JumpButton" then
   if x:IsA("GuiObject") then controls[x.Name]=rect(x) end
  end
 end end
 local buttons={}
 if left then for _,name in {"SkipButton","InventoryButton","RebirthButton","ShopButton","CommunityRewardsButton","PetsButton"} do
  local b=left:FindFirstChild(name)
  if b then local hit=b:IsA("GuiButton") and b or b:FindFirstChild("Button");buttons[name]={Paint=rect(b),Hit=rect(hit)} end
 end end
 local row={Elapsed=os.clock()-began,Reason=reason,EntryRoute=script:GetAttribute("EntryRoute") or "unlabelled",
  PlaceVersion=game.PlaceVersion,Requested=tostring(pg.ScreenOrientation),Actual=tostring(pg.CurrentScreenOrientation),
  TouchEnabled=UIS.TouchEnabled,Viewport=camera and xy(camera.ViewportSize),GuiSize=gui and xy(gui.AbsoluteSize),
  World=player:GetAttribute("CurrentWorld"),Character=player.Character~=nil,TouchGuiEnabled=touch and touch.Enabled,
  Base=gui and gui:GetAttribute("LeftMenuBaseScale"),Final=gui and gui:GetAttribute("LeftMenuFinalScale"),
  Ratio=gui and gui:GetAttribute("LeftMenuAvoidanceRatio"),Buttons=buttons,Controls=controls}
 table.insert(records,row);if #records>128 then table.remove(records,1)end
 print("[MobileHUDObserve] "..Http:JSONEncode(row))
end
local function schedule(reason)
 if not alive then return end
 reasons[reason]=true
 if pending then return end
 pending=true
 task.defer(function()
  pending=false
  if not alive then return end
  local list={} for r in reasons do table.insert(list,r)end table.clear(reasons);table.sort(list)
  local ok,err=pcall(sample,table.concat(list,","))
  if not ok then warn("[MobileHUDObserve] "..tostring(err))end
 end)
end
local function connect(signal,callback)table.insert(connections,signal:Connect(callback))end
local function bindCamera()
 if cameraConnection then cameraConnection:Disconnect();cameraConnection=nil end
 local c=workspace.CurrentCamera
 if c then cameraConnection=c:GetPropertyChangedSignal("ViewportSize"):Connect(function()schedule("viewport")end)end
 schedule("camera")
end
local function watch(x)
 if watched[x] then return end
 if x.Name=="StrengthGui" and x:IsA("ScreenGui") then
  watched[x]={
   x:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()schedule("gui-size")end),
   x:GetAttributeChangedSignal("LeftMenuFinalScale"):Connect(function()schedule("menu-scale")end),
   x:GetAttributeChangedSignal("LeftMenuBaseScale"):Connect(function()schedule("menu-base")end),
  }
  schedule("gui-arrived")
 end
end
local function unwatch(x)
 if watched[x] then for _,c in watched[x] do c:Disconnect()end watched[x]=nil end
end
connect(pg:GetPropertyChangedSignal("ScreenOrientation"),function()schedule("requested-orientation")end)
connect(pg:GetPropertyChangedSignal("CurrentScreenOrientation"),function()schedule("actual-orientation")end)
connect(workspace:GetPropertyChangedSignal("CurrentCamera"),bindCamera)
connect(UIS.WindowFocused,function()schedule("app-focus")end)
connect(UIS.WindowFocusReleased,function()schedule("app-blur")end)
connect(player.CharacterAdded,function()schedule("character-added")end)
connect(player.CharacterRemoving,function()schedule("character-removing")end)
connect(player:GetAttributeChangedSignal("CurrentWorld"),function()schedule("world")end)
connect(pg.ChildAdded,watch);connect(pg.ChildRemoved,unwatch)
connect(UIS.InputBegan,function(input)if input.UserInputType==Enum.UserInputType.Touch then schedule("touch-began")end end)
connect(UIS.InputEnded,function(input)if input.UserInputType==Enum.UserInputType.Touch then schedule("touch-ended")end end)
local handle={}
function handle.Mark(label)schedule("manual:"..tostring(label))end
function handle.Dump()return Http:JSONEncode(records)end
function handle.Stop()
 if not alive then return end
 alive=false
 for _,c in connections do c:Disconnect()end
 if cameraConnection then cameraConnection:Disconnect()end
 for x in watched do unwatch(x)end
 if _G.MobileHUDObserve==handle then _G.MobileHUDObserve=nil end
end
connect(script.Destroying,handle.Stop)
_G.MobileHUDObserve=handle
for _,x in pg:GetChildren()do watch(x)end
bindCamera();schedule("observer-start")
