local source=game.StarterPlayer.StarterPlayerScripts.Services.EggClient.Source
local function section(a,b)local start=assert(source:find(a,1,true));local stop=assert(source:find(b,start+#a,1,true));return source:sub(start,stop-1)end
local helpers=section("local function setSize","function EggClient.start()")
local closeBody=assert(source:match("CloseButton%.Mount%(open, egg%.janitor, function%(%)\n(.-)\n\tend%)"))
local factory=assert(loadstring([[
return function(Player,Eggs,Egg,Config,HatchClient,PetClient)
local ROOT_NAME="HumanoidRootPart"
]]..helpers..[[
local function close(egg) local open=egg.open
]]..closeBody..[[
end
return {Choose=choose,Fit=fit,Reset=resetSheets,Close=close}
end]]))()
local objects={}
local function own(x)table.insert(objects,x);return x end
local holder=own(Instance.new("Folder"));local character=own(Instance.new("Model"))
local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Parent=character
local hum=Instance.new("Humanoid");hum.Parent=character
local player={Character=character,World=1,GetAttribute=function(self)return self.World end}
local eggs={}
for _,id in ipairs({"Basic","Rare","W2_Basic"})do
local part=Instance.new("Part");part.Name=id;part.Position=Vector3.new(id=="Rare" and 3 or 0,0,0);part.Parent=holder
eggs[id]={part=part,base=part.CFrame,open=own(Instance.new("BillboardGui")),size=UDim2.fromScale(20,12.5),share=0,drift=Vector2.zero,openness=0,dismissed=false}
end
local hatch=false
local calls=0
local t=factory(player,eggs,{identity=function(p)return p.Name end,world=function(id)return id=="W2_Basic" and 2 or 1 end},{Egg={reach=15,tie=.01,openSeconds=.2,width=.48,margin=.02,catchUp=12}},{playing=function()return hatch end},{hideCard=function()calls+=1 end})
local camera={CFrame=CFrame.lookAt(Vector3.new(0,0,-30),Vector3.zero),ViewportSize=Vector2.new(800,360),FieldOfView=70,WorldToViewportPoint=function()return Vector3.new(400,180,30)end}
local rows={}
local function check(name,condition)assert(condition,name);table.insert(rows,name)end
local ok,err=xpcall(function()
 root.Position=Vector3.zero
 check("W1 initially chooses Basic",t.Choose(camera)==eggs.Basic)
 t.Fit(eggs.Basic,camera,1,true)
 check("sheet initially enabled",eggs.Basic.open.Enabled)
 t.Close(eggs.Basic)
 check("close disables immediately",not eggs.Basic.open.Enabled and eggs.Basic.dismissed)
 t.Fit(eggs.Basic,camera,1,true)
 check("fit cannot reopen dismissed sheet",not eggs.Basic.open.Enabled)
 check("closed Basic does not block Rare",t.Choose(camera)==eggs.Rare)
 for _=1,30 do camera.CFrame=camera.CFrame*CFrame.Angles(0,.25,0);t.Choose(camera)end
 check("camera rotation retains dismissal",eggs.Basic.dismissed)
 root.Position=Vector3.new(100,0,0);t.Choose(camera)
 check("physical departure resets dismissal",not eggs.Basic.dismissed)
 root.Position=Vector3.zero;camera.CFrame=CFrame.lookAt(Vector3.new(0,0,-30),Vector3.zero)
 check("re-entry permits Basic",t.Choose(camera)==eggs.Basic)
 t.Close(eggs.Basic);hum.Health=0
 check("dead character cannot choose",t.Choose(camera)==nil)
 check("death clears latched dismissal",not eggs.Basic.dismissed)
 hum.Health=100;t.Reset()
 check("respawn reset permits Basic",t.Choose(camera)==eggs.Basic)
 t.Close(eggs.Basic);player.World=2;t.Reset()
 check("World2 chooses its normal Egg",t.Choose(camera)==eggs.W2_Basic)
 t.Close(eggs.W2_Basic)
 check("World2 latch works",t.Choose(camera)==nil)
 player.World=1;t.Reset()
 check("World return remains usable",t.Choose(camera)==eggs.Basic)
 hatch=true;t.Fit(eggs.Basic,camera,1,true)
 check("hatch presentation still suppresses sheet",not eggs.Basic.open.Enabled)
 check("close path has no purchase dispatch",not closeBody:find("request",1,true) and not closeBody:find("press",1,true))
end,debug.traceback)
for _,x in objects do x:Destroy()end
assert(ok,err)
return game:GetService("HttpService"):JSONEncode({Checks=#rows,Passed=rows,Mode="Exact current functions; synthetic close invocation, camera and player; no physical input",Cleanup=true})
