-- Exact existing tutorial and analytics Sources, isolated lifecycle/transport.
local q=assert(_G.OreSlotsReview);local v=q.View;local RS=game.ReplicatedStorage
local n=0;local function check(ok,label)assert(ok,label);n+=1 end
v:Hide();v:Show();v:SelectTab("Ore");q.SetCount(0)
local overlay=game.StarterGui.OreMergeTutorialGui:Clone();overlay.Parent=nil
local attrs={CurrentWorld=1,TutorialCompleted=true,OreTutorialEligible=true,OreTutorialCompleted=false,HigherOreTutorialEligible=true,HigherOreTutorialCompleted=false,ForgeSessionToken="isolated"}
local events={};local cleanup={}
local function event()local e=Instance.new("BindableEvent");table.insert(cleanup,e);return e end
local removing,beat=event(),event()
local pg={WaitForChild=function()return overlay end,FindFirstChild=function()return nil end}
local floor=workspace.GeneratedMap.TrainingArea.Floor
local p={Character={FindFirstChildOfClass=function()return {Health=100}end,FindFirstChild=function()return {Position=floor.Position}end},CharacterRemoving=removing.Event}
function p:WaitForChild()return pg end
function p:GetAttribute(k)return attrs[k]end
function p:SetAttribute(k,value)attrs[k]=value end
function p:GetAttributeChangedSignal(k)if not events[k]then events[k]=event()end return events[k].Event end
local target,message
local presentation={Mount=function()return {Pin=function(_,s)message=s end,Target=function(_,x)target=x end,Hide=function()target=nil end,Destroy=function()end}end}
local function req(m)
 if m==RS.Modules.ForgeClient then return q.Forge elseif m==RS.Modules.OreMergeTutorialPresentation then return presentation
 elseif m==RS.Modules.TutorialPresentationCoordinator then return {Acquire=function()return true end,Release=function()end}end
 return require(m)
end
local fakeGame={GetService=function(_,name)if name=="RunService"then return {Heartbeat=beat.Event}end return game:GetService(name)end}
local guide=assert(loadstring("return function(require,game,script)\n"..RS.Modules.OreMergeTutorialGuide.Source.."\nend"))()(req,fakeGame,RS.Modules.OreMergeTutorialGuide)
local stop=guide.Mount(p,q.Gui,v);task.wait()
check(overlay:GetAttribute("Step")=="AddOres","initial guide selects material")
q.SetCount(1);task.wait();check(overlay:GetAttribute("Step")=="AddOres" and target~=v.Merge,"one keeps material guide")
check(v.Drop.Inputs.OreEmptySlot2:GetAttribute("NextRequired"),"one highlights second slot")
q.SetCount(2);task.wait();check(overlay:GetAttribute("Step")=="Merge" and target==v.Merge,"two hands off to Merge")
check(not v.Drop.Inputs.OreEmptySlot3:GetAttribute("NextRequired"),"no competing third-slot highlight")
attrs.OreTutorialCompleted=true;events.OreTutorialCompleted:Fire();task.wait()
check(overlay:GetAttribute("GuideKind")=="Higher" and overlay:GetAttribute("Step")=="AddOres","higher guide retains point threshold")
v:ActivateMaterial("ORE_003");task.wait()
check(overlay:GetAttribute("Step")=="Merge" and target==v.Merge,"higher guide accepts sufficient selected points")
v:SetSellMode(true);task.wait();check(overlay:GetAttribute("Step")=="ChooseOre","sale still routes tutorial to Ore merge")
v:SetSellMode(false);q.State(q.Forge.State,true);task.wait();check(overlay:GetAttribute("Step")=="Saving","pending tutorial retained")
q.State(q.Forge.State,false);stop();overlay:Destroy();for _,e in cleanup do e:Destroy()end
-- Run the existing analytics observer with a fake clock and transport, never send a real event.
local sends={};local connections={}
local function track(signal)return {Connect=function(_,fn)local c=signal:Connect(fn);table.insert(connections,c);return c end}end
local heartbeat,remoteEvent=Instance.new("BindableEvent"),Instance.new("BindableEvent")
local remote={OnClientEvent=track(remoteEvent.Event),FireServer=function(_,action,value)table.insert(sends,{Action=action,Value=value})end}
local fakeRS={FindFirstChild=function()return {FindFirstChild=function()return remote end}end,Remotes={FindFirstChild=function()return remote end}}
local flags={MTFSession="isolated-analytics",MTFNewFirstSession=true,MTFOreFinished=false,ForgeInventoryRevision=1}
local ap={GetAttribute=function(_,k)return flags[k]end,Character={}}
local runtime={GetService=function(_,name)if name=="Players"then return {LocalPlayer=ap}elseif name=="ReplicatedStorage"then return fakeRS elseif name=="RunService"then return {Heartbeat=track(heartbeat.Event)}end error(name)end,IsLoaded=function()return false end}
local now=10
local client=assert(loadstring("return function(game,os)\n"..RS.Modules.FirstPlayAnalyticsClient.Source.."\nend"))()(runtime,{clock=function()return now end})
client.BindOre(q.AnalyticsReader,track(v.Changed));client.Start()
local function tick()now+=.3;heartbeat:Fire(.3);task.wait()end
v:Clear();tick();check(#sends==1 and sends[1].Value.Open,"Ore denominator remains open view")
tick();check(#sends==1,"unchanged snapshot deduplicated")
for _,amount in {1,2,5}do now+=.3;q.SetCount(amount);tick();check(sends[#sends].Value.Materials.ORE_001==amount,"same selected quantities in analytics");local before=#sends;tick();check(#sends==before,"duplicate quantity does not send")end
v:SetSellMode(true);tick();check(sends[#sends].Value.Open==false,"sale excluded from open merge")
flags.MTFOreFinished=true;local before=#sends;v:SetSellMode(false);v:Clear();tick();check(#sends==before,"completed funnel stops observation")
flags.MTFOreFinished=false;flags.MTFNewFirstSession=false;v:ActivateMaterial("ORE_001");tick();check(#sends==before,"existing cohort excluded")
for _,c in connections do c:Disconnect()end;heartbeat:Destroy();remoteEvent:Destroy();q.SetCount(0)
return {Assertions=n,AnalyticsSends=#sends,Kind="Existing tutorial/analytics code with isolated player, clock and transport; no live analytics"}
