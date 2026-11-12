-- Run in Studio Edit with execute_luau. No Play, player profile or network calls.
local source=game.StarterPlayer.StarterPlayerScripts.UI.TouchControlZoneClient.Source
local count,writes=0,0
local all={}
local function signal()
 local handlers={}
 local s={}
 function s:Connect(fn)
  local c={Connected=true}
  function c:Disconnect() self.Connected=false end
  table.insert(handlers,{fn,c});return c
 end
 function s:Fire(...) for _,v in handlers do if v[2].Connected then v[1](...) end end end
 function s:Count() local n=0 for _,v in handlers do if v[2].Connected then n+=1 end end return n end
 table.insert(all,s);return s
end
local changed,focus,added,world,desc=signal(),signal(),signal(),signal(),signal()
local actual=Enum.ScreenOrientation.Portrait
local pg=setmetatable({},{
 __index=function(_,key)
  if key=="ScreenOrientation" then return actual end
  if key=="GetPropertyChangedSignal" then return function(_,name)assert(name=="ScreenOrientation");return changed end end
  if key=="GetDescendants" then return function()return {}end end
  if key=="DescendantAdded" then return desc end
 end,
 __newindex=function(_,key,value)assert(key=="ScreenOrientation");actual=value;writes+=1;changed:Fire()end,
})
local p={CharacterAdded=added,WaitForChild=function()return pg end,GetAttributeChangedSignal=function(_,n)assert(n=="CurrentWorld");return world end}
local fake={GetService=function(_,n)if n=="Players" then return {LocalPlayer=p} elseif n=="UserInputService" then return {WindowFocused=focus} end error(n)end}
local fixture=Instance.new("LocalScript")
local function check(ok,label)assert(ok,label);count+=1 end
assert(loadstring("return function(game,script)\n"..source.."\nend"))()(fake,fixture)
check(actual==Enum.ScreenOrientation.LandscapeSensor,"portrait startup requests both landscapes")
check(writes==1,"one startup write")
local before={} for _,s in all do table.insert(before,s:Count())end
for i=1,5 do
 added:Fire();world:Fire();focus:Fire()
 check(writes==1,"no redundant write on lifecycle")
 for j,s in all do check(s:Count()==before[j],"no lifecycle connection growth")end
end
pg.ScreenOrientation=Enum.ScreenOrientation.Portrait
check(actual==Enum.ScreenOrientation.LandscapeSensor,"property change repaired")
check(writes==3,"one foreign write plus one repair, no recursion")
actual=Enum.ScreenOrientation.Sensor;focus:Fire()
check(actual==Enum.ScreenOrientation.LandscapeSensor,"app focus repairs reset")
local zone=Instance.new("Frame");zone.Name="DynamicThumbstickFrame";zone.Size=UDim2.fromOffset(300,200);zone.Position=UDim2.fromOffset(7,19)
desc:Fire(zone)
check(zone.BackgroundTransparency==1,"background hidden")
check(zone.Size==UDim2.fromOffset(300,200) and zone.Position==UDim2.fromOffset(7,19),"input zone geometry retained")
desc:Fire(zone)
zone.BackgroundTransparency=.2;task.wait()
check(zone.BackgroundTransparency==1,"existing background guard retained")
fixture:Destroy();task.wait();task.wait()
for _,s in all do check(s:Count()==0,"lifetime connections cleaned")end
local finalWrites=writes;focus:Fire();added:Fire();world:Fire()
check(writes==finalWrites,"destroyed script no longer acts")
zone:Destroy()
return {Assertions=count,Writes=writes,Kind="Isolated exact Source with fake orientation/lifecycle signals"}
