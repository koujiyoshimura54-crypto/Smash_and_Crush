-- Pass the pre-task MergeShopView Source to compare unaffected tabs in Edit.
return function(beforeSource)
local q=assert(_G.OreSlotsReview);local RS=game.ReplicatedStorage
local frame=Instance.new("Frame");frame.Name="CodexOreRegression";frame.Size=UDim2.fromScale(1,1);frame.BackgroundTransparency=1;frame.Parent=q.Gui
local donor=q.Gui.ShopPanel:Clone();donor.Visible=false;donor.Parent=frame
local function req(m)if m==RS.Modules.FirstPlayAnalyticsClient then return {BindOre=function()end}end return q.Require(m)end
local build=assert(loadstring("return function(require)\n"..beforeSource.."\nend"))()(req)
local oldRequests={}
local old=build({gui=frame,RS=RS,Master=require(RS.Config.ItemMaster),Egg=require(RS.Modules.Egg),PetClient=q.Pet,EggViewport=require(RS.Modules.LimitedPetViewport),OnMerge=function(m)table.insert(oldRequests,m)end})
q.RegressionOld=old;q.RegressionFrame=frame
local checks,objects=0,0
local function check(ok,label)assert(ok,label);checks+=1 end
local function shown(x)
 while x do if x:IsA("GuiObject")and not x.Visible or x:IsA("ScreenGui")and not x.Enabled then return false end x=x.Parent end return true
end
local function compare(a,b)
 if a:IsA("GuiObject")and shown(a)then
  objects+=1
  check(a.Visible==b.Visible,"visibility "..a.Name)
  check((a.AbsoluteSize-b.AbsoluteSize).Magnitude<.05,"size "..a.Name)
  check(((a.AbsolutePosition-old.Root.AbsolutePosition)-(b.AbsolutePosition-q.View.Root.AbsolutePosition)).Magnitude<.05,"position "..a.Name)
  check(a.BackgroundColor3==b.BackgroundColor3,"background "..a.Name)
  if a:IsA("GuiButton")then check(a.Interactable==b.Interactable and a.Active==b.Active,"input flags "..a.Name)end
  if a:IsA("TextLabel") or a:IsA("TextButton")then check(a.Text==b.Text and a.TextColor3==b.TextColor3,"text "..a.Name)end
  if a:IsA("ImageLabel")then check(a.Image==b.Image,"image "..a.Name)end
 end
 for _,x in a:GetChildren()do local other=b:FindFirstChild(x.Name);check(other~=nil,"retained child "..x.Name);if other then compare(x,other)end end
end
local id
for _,item in require(RS.Config.ItemMaster).GetAll()do if item.Rarity=="Common" and item.WorldId~=2 then id=item.ItemId;break end end
check(id~=nil,"common Item fixture")
local items={OwnedItems={[id]=3},World2Unlocked=false,World1Cleared=false,SavePending=false}
old:Show();q.View:Show()
for _,view in {old,q.View}do view:SetItemState(items,true,false,"")end
task.wait();compare(old.Root,q.View.Root)
for _,view in {old,q.View}do view:ActivateMaterial(id);view:ActivateMaterial(id)end
task.wait();compare(old.Root,q.View.Root)
check(old.Merge.Interactable and q.View.Merge.Interactable,"Item ready")
old:SubmitItem();q.View:SubmitItem();check(#oldRequests==1 and oldRequests[1][id]==2 and q.ItemRequests[#q.ItemRequests][id]==2,"same Item materials")
for _,view in {old,q.View}do view:CompleteItem(id);view:SetItemState(items,true,false,"");view:SelectTab("Pet");view:SetPetState(q.Pet.state())end
task.wait();compare(old.Root,q.View.Root)
for _,view in {old,q.View}do view:ActivateMaterial("Dog");view:ActivateMaterial("Dog")end
task.wait();compare(old.Root,q.View.Root)
check(old.Merge.Interactable and q.View.Merge.Interactable,"Pet ready")
old:SubmitItem();q.View:SubmitItem();task.wait();task.wait()
compare(old.Root,q.View.Root)
for _,view in {old,q.View}do view:SelectTab("Ore");view:SetSellMode(true);view:ActivateMaterial("ORE_001");view:ActivateMaterial("ORE_001")end
task.wait();compare(old.Root,q.View.Root)
old:Destroy();frame:Destroy();q.RegressionOld=nil;q.RegressionFrame=nil;q.View:SetSellMode(false);q.View:Clear()
return {Assertions=checks,ComparedGuiObjects=objects,Kind="Old/new native geometry/state with mocked Pet tile/request boundary; no gameplay merge"}
end
