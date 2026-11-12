-- Synthetic input callbacks and isolated Forge outcomes; no gameplay requests.
local q=assert(_G.OreSlotsReview)
local v=q.View
local count=0
local function check(ok,label)assert(ok,label);count+=1 end
local normal={Loaded=true,Token="isolated",Generation=1,Sequence=0,World2Unlocked=false,Ores={ORE_001=7,ORE_002=3,ORE_003=2,ORE_004=1,ORE_005=1,ORE_006=1}}
local function fresh()q.State(table.clone(normal),false);v:Hide();v:Show();v:SelectTab("Ore");task.wait()end
local function slots(expected,highlight)
 local s=q.Snapshot()
 check(s.Count==expected,"selection count "..expected)
 check(#s.Slots==5,"exactly five occupied plus empty slots")
 local filled,lit=0,0
 for _,row in s.Slots do
  if row.Name:find(":")then filled+=1 end
  if row.Next then lit+=1;check(row.Name=="OreEmptySlot"..highlight,"next required index")end
 end
 check(filled==expected,"one card per Ore unit")
 check(lit==(highlight and 1 or 0),"only required additions highlighted")
 check(v.Drop.DropTitle.Visible==false,"Ore drag title hidden")
 check(v.Drop.Inputs.ScrollingEnabled==false and v.Drop.Inputs.CanvasSize==UDim2.new(),"non-scrolling strip")
 return s
end
fresh();slots(0,1);check(not v.Merge.Interactable,"zero cannot merge")
q.Clicks["material:ORE_001"]();slots(1,2);check(not v.Merge.Interactable,"one cannot merge")
q.Clicks["material:ORE_001"]();slots(2);check(v.Merge.Interactable,"two valid units can merge")
check(q.AnalyticsReader().Materials.ORE_001==2,"Analytics reads original selection")
check(v:GetOreTutorialState().Valid,"original tutorial sees valid merge at two")
q.Clicks["material:ORE_002"]();slots(3)
q.Clicks["material:ORE_001"]();q.Clicks["material:ORE_003"]();slots(5)
q.Clicks["material:ORE_001"]();slots(5);check(q.AnalyticsReader().Materials.ORE_001==3,"sixth rejected")
q.Clicks["input:ORE_001:2"]();slots(4);check(q.AnalyticsReader().Materials.ORE_001==2,"one matching unit removed")
v:Clear();slots(0,1)
q.Clicks["material:ORE_004"]();q.Clicks["material:ORE_004"]();slots(1,2);check(q.AnalyticsReader().Materials.ORE_004==1,"owned cap")
fresh()
local card=v.List:FindFirstChild("ORE_001");local a=card.AbsolutePosition+card.AbsoluteSize/2
v:PressMaterial("ORE_001",a,true,{});v:ReleasePointer(a);q.Clicks["material:ORE_001"]();slots(1,2)
fresh();card=v.List:FindFirstChild("ORE_001");a=card.AbsolutePosition+card.AbsoluteSize/2
v:PressMaterial("ORE_001",a,true,{});v:MovePointer(a+Vector2.new(0,30));v:ReleasePointer(a+Vector2.new(0,30));q.Clicks["material:ORE_001"]();slots(0,1)
fresh();card=v.List:FindFirstChild("ORE_001");a=card.AbsolutePosition+card.AbsoluteSize/2
local b=v.Drop.AbsolutePosition+v.Drop.AbsoluteSize/2
v:PressMaterial("ORE_001",a,false,{});v:MovePointer(b);v:ReleasePointer(b);q.Clicks["material:ORE_001"]();slots(1,2)
check(v.List.ScrollingEnabled,"scroll restored after drag")
fresh();card=v.List:FindFirstChild("ORE_001");a=card.AbsolutePosition+card.AbsoluteSize/2;b=v.Drop.AbsolutePosition+v.Drop.AbsoluteSize/2
v:PressMaterial("ORE_001",a,false,{});v:MovePointer(b);q.Clicks["material:ORE_001"]();slots(0,1)
v:ReleasePointer(b);q.Clicks["material:ORE_001"]();slots(1,2)
fresh();q.SetCount(2);local requests=#q.Requests;v:SubmitItem();task.wait()
check(#q.Requests==requests+1 and q.Requests[#q.Requests].Materials.ORE_001==2,"one exact existing Forge request")
check(not v.Merge.Interactable,"pending disables Merge")
q.Clicks["material:ORE_002"]();v:RemoveMaterial("ORE_001:1");v:Clear();slots(2)
v:SubmitItem();check(#q.Requests==requests+1,"pending prevents repeat submit")
q.State(normal,false);q.ForgeCompleted:Fire({Action="MergeOre"},{Success=false,Code="FixtureFailure"});task.wait();slots(2)
check(v.Merge.Interactable,"failure preserves selection")
local success=table.clone(normal);success.Journal={ResultId="NORMAL_01"};q.State(success,false)
q.ForgeCompleted:Fire({Action="MergeOre"},{Success=true,State=success});task.wait();slots(0,1)
fresh();q.SetCount(5);local reduced=table.clone(normal);reduced.Ores={ORE_001=1};q.State(reduced,false);slots(1,2);check(not v.Merge.Interactable,"ownership clamps selection")
local loading=table.clone(normal);loading.Loaded=false;q.State(loading,false);v:Clear();slots(0);q.SetCount(2);slots(2);check(not v.Merge.Interactable,"loading not executable")
fresh();q.SetCount(2);local saving=table.clone(normal);saving.Pending=true;q.State(saving,false);slots(2);check(not v.Merge.Interactable,"state pending")
fresh();q.SetCount(2);v:SetSellMode(true)
for _,x in v.Drop.Inputs:GetChildren()do if x.Name:find("OreEmptySlot")then check(not x.Visible,"no slots in sale")end end
check(v.Drop.DropTitle.Visible,"sale instruction retained")
v:SetSellMode(false);slots(2)
for _,tab in {"Item","Pet","Ore","Item","Ore"}do
 v:SelectTab(tab)
 if tab=="Ore"then slots(0,1)
 else for _,x in v.Drop.Inputs:GetChildren()do if x.Name:find("OreEmptySlot")then check(not x.Visible,"Ore slots excluded from "..tab)end end
 check(v.Drop.DropTitle.Visible and v.Drop.Inputs.ScrollingEnabled,"original empty "..tab.." path")
 end
end
for i=1,3 do v:Hide("Closed");for _,x in v.Drop.Inputs:GetChildren()do if x.Name:find("OreEmptySlot")then check(not x.Visible and not x:GetAttribute("NextRequired"),"hidden placeholder released")end end;v:Show();v:SelectTab("Ore");slots(0,1)end
check(#q.Requests==requests+1,"view operations add no requests")
return {Assertions=count,Kind="Synthetic input callbacks and isolated Forge state; native GUI objects"}
