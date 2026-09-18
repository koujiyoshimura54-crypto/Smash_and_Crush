-- Merge presentation only. Recipes and eligibility come from ItemMergeService.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local Master=require(RS.Config:WaitForChild("ItemMaster"))
local HUD=require(RS.Modules:WaitForChild("HUDLayout"))
local mergeRemote=RS.Remotes:WaitForChild("ItemMergeRequest")
local stateRemote=RS.Remotes:WaitForChild("ItemMergeState")
local inventory=player:WaitForChild("PlayerGui"):WaitForChild("StrengthGui"):WaitForChild("InventoryPanel")
local page=inventory.Content:WaitForChild("Merge")
local old=page:WaitForChild("MergePanel")
local template=script.Parent:WaitForChild("ItemCardTemplate")
old.Visible=false
-- Keep the legacy layout nodes for ResponsivePanels; the new flow owns only its sibling.
local root=Instance.new("Frame")
root.Name="MergeFlow"
root.BackgroundTransparency=1
root.ClipsDescendants=true
root.Parent=page
local scale=Instance.new("UIScale",root)
local elementOrder={Fire=1,Ice=2,Electric=3}
local typeOrder={}
for i,kind in ipairs(Master.Kinds) do typeOrder[kind]=i end
local icons={Fire="🔥",Ice="❄️",Electric="⚡"}
local colors={Fire=Color3.fromRGB(122,38,56),Ice=Color3.fromRGB(40,106,166),Electric=Color3.fromRGB(167,122,22)}
local names={Protein="Protein",Glove="Glove",TrainingBelt="Training Belt"}
local step,selectedId=1,nil
local recipes,byId,cards={},{},{}
local required=0
local loaded,fresh,pending,fetching=false,false,false,false
local revision=0
local status=""
local render,refresh,layout

local function make(class,name,parent)
 local x=Instance.new(class)
 x.Name=name
 x.BorderSizePixel=0
 x.BackgroundTransparency=1
 x.ZIndex=210
 x.Parent=parent
 return x
end
local function decorate(x,source)
 for _,v in ipairs(source:GetChildren()) do
  if v:IsA("UICorner") or v:IsA("UIStroke") or v:IsA("UIGradient") then v:Clone().Parent=x end
 end
 x.BackgroundColor3=source.BackgroundColor3
 x.BackgroundTransparency=source.BackgroundTransparency
end
local function label(name,parent,text,size)
 local x=make("TextLabel",name,parent)
 x.FontFace=template.ItemName.FontFace
 x.TextColor3=Color3.new(1,1,1)
 x.TextStrokeColor3=template.ItemName.TextStrokeColor3
 x.TextStrokeTransparency=template.ItemName.TextStrokeTransparency
 x.TextSize=size
 x.Text=text
 x.TextWrapped=true
 local outline=inventory.Tabs.Merge.Label:FindFirstChildOfClass("UIStroke")
 if outline then outline:Clone().Parent=x end
 return x
end
local function button(name,parent,text)
 local x=make("TextButton",name,parent)
 decorate(x,old.Footer.MergeButton)
 local gradient=inventory.Tabs.Merge:FindFirstChildOfClass("UIGradient")
 if gradient then gradient:Clone().Parent=x end
 x.FontFace=old.Footer.MergeButton.FontFace
 x.TextColor3=Color3.new(1,1,1)
 x.TextStrokeTransparency=old.Footer.MergeButton.TextStrokeTransparency
 x.TextStrokeColor3=old.Footer.MergeButton.TextStrokeColor3
 x.TextSize=24
 x.Text=text
 local outline=inventory.Tabs.Merge.Label:FindFirstChildOfClass("UIStroke")
 if outline then outline:Clone().Parent=x end
 return x
end
local function rect(x,a,b,w,h)
 x.AnchorPoint=Vector2.zero
 x.Position=UDim2.fromOffset(a,b)
 x.Size=UDim2.fromOffset(math.max(1,w),math.max(1,h))
end
local back=button("Back",root,"BACK")
local title=label("StepTitle",root,"SELECT 1 ITEM",24)
local start=make("Frame","Start",root)
local choose=button("ChooseItem",start,"SELECT ITEM")
choose.BackgroundColor3=Color3.fromRGB(232,171,35)
local startCount=label("Count",start,"0/3 ITEMS",24)
local startSocketArea=make("Frame","Sockets",start)
local startSockets={}
for i=1,3 do
 local socket=make("Frame","Socket"..i,startSocketArea)
 decorate(socket,old.MergeRecipe.Slots.Material1.Slot)
 local corner=socket:FindFirstChildOfClass("UICorner")
 if corner then corner.CornerRadius=UDim.new(1,0) end
 local missing=label("Missing",socket,"?",30)
 missing.Size=UDim2.fromScale(1,1)
 table.insert(startSockets,socket)
end
local intro=label("Instruction",start,"Merge 3 identical items to upgrade",20)
local selection=make("ScrollingFrame","Selection",root)
selection.ScrollBarThickness=6
selection.ScrollingDirection=Enum.ScrollingDirection.Y
selection.AutomaticCanvasSize=Enum.AutomaticSize.Y
selection.CanvasSize=UDim2.new()
local grid=Instance.new("UIGridLayout",selection)
grid.SortOrder=Enum.SortOrder.LayoutOrder
grid.CellPadding=UDim2.fromOffset(10,10)
local empty=label("Empty",root,"",22)
local execute=make("Frame","Execute",root)
local source=make("Frame","SelectedItem",execute)
decorate(source,template)
local sourceImage=make("ImageLabel","ItemImage",source)
sourceImage.ScaleType=Enum.ScaleType.Fit
local sourceName=label("ItemName",source,"",22)
local sourceMeta=label("Identity",source,"",18)
local socketArea=make("Frame","Sockets",execute)
local sockets={}
local resultText=label("Result",execute,"",18)
local footer=make("Frame","Footer",root)
local count=label("Count",footer,"",26)
local merge=button("Merge",footer,"MERGE")
local hint=label("Status",root,"",18)

local errors={
 NotEnoughItems="Not enough identical items",DataSaving="Saving. Please wait.",
 DataNotLoaded="Loading…",CountOverflow="Result item limit reached",
 InventorySavePending="Waiting for save…",RateLimited="Please wait…",
 NotMergeable="This item cannot be merged",InvalidItemId="Select another item",
}
local function visible() return inventory.Visible and page.Visible end
local function less(a,b)
 local aa,bb=Master.Get(a.ItemId),Master.Get(b.ItemId)
 local ae,be=elementOrder[aa.Element] or 99,elementOrder[bb.Element] or 99
 if ae~=be then return ae<be end
 local ar,br=Master.RarityRank[aa.Rarity] or 99,Master.RarityRank[bb.Rarity] or 99
 if ar~=br then return ar<br end
 local at,bt=typeOrder[aa.ItemType] or 99,typeOrder[bb.ItemType] or 99
 if at~=bt then return at<bt end
 return a.ItemId<b.ItemId
end
local function rebuildCards()
 for _,card in ipairs(cards) do card:Destroy() end
 cards={}
 for _,recipe in ipairs(recipes) do
  if recipe.Count>0 then
   local item=Master.Get(recipe.ItemId)
   local card=make("TextButton",recipe.ItemId,selection)
   decorate(card,template)
   card.Text=""
   card.LayoutOrder=#cards+1
   card:SetAttribute("ItemId",recipe.ItemId)
   local picture=make("ImageLabel","ItemImage",card)
   picture.Image=item.Image
   picture.ScaleType=Enum.ScaleType.Fit
   picture.BackgroundTransparency=0
   picture.BackgroundColor3=colors[item.Element]
   local corner=template.ItemImage:FindFirstChildOfClass("UICorner")
   if corner then corner:Clone().Parent=picture end
   label("ItemName",card,names[item.ItemType] or item.ItemType,21)
   label("Identity",card,(icons[item.Element] or "").." "..item.Element.." · "..item.Rarity,17)
   label("Owned",card,"Owned: "..tostring(recipe.Count),17)
   card.Activated:Connect(function()
    selectedId=recipe.ItemId
    step=3
    status=""
    render()
    task.spawn(refresh)
   end)
   table.insert(cards,card)
  end
 end
end
local function rebuildSockets()
 for _,x in ipairs(sockets) do x:Destroy() end
 sockets={}
 for i=1,required do
  local socket=make("Frame","Socket"..i,socketArea)
  decorate(socket,old.MergeRecipe.Slots.Material1.Slot)
  local c=socket:FindFirstChildOfClass("UICorner")
  if c then c.CornerRadius=UDim.new(1,0) end
  local pic=make("ImageLabel","Item",socket)
  pic.Size=UDim2.fromScale(.8,.8)
  pic.Position=UDim2.fromScale(.1,.1)
  pic.ScaleType=Enum.ScaleType.Fit
  local missing=label("Missing",socket,"?",32)
  missing.Size=UDim2.fromScale(1,1)
  table.insert(sockets,socket)
 end
end

layout=function()
 -- Cancel only this flow's inherited fit scale: text/tap targets use screen pixels.
 local s=HUD.GetScale(page)
 scale.Scale=1/math.max(s,.01)
 local w,h=page.AbsoluteSize.X,page.AbsoluteSize.Y
 root.Size=UDim2.fromOffset(w,h)
 local compact=h<330
 rect(back,0,0,100,44)
 rect(title,110,0,w-110,44)
 rect(start,0,0,w,h)
 local bw=math.min(w-16,520)
 local startTop=math.max(8,(h-250)/2)
 rect(choose,(w-bw)/2,startTop,bw,64)
 choose.TextSize=w<400 and 24 or 32
 rect(startCount,8,startTop+72,w-16,30)
 rect(startSocketArea,8,startTop+106,w-16,72)
 local startSide=math.min(64,startSocketArea.Size.Y.Offset)
 local startTotal=startSide*3+20
 for i,socket in ipairs(startSockets) do rect(socket,(startSocketArea.Size.X.Offset-startTotal)/2+(i-1)*(startSide+10),4,startSide,startSide) end
 rect(intro,8,startTop+182,w-16,42)
 rect(selection,2,52,w-4,h-54)
 rect(empty,8,60,w-16,h-68)
 local cols=math.max(1,math.floor((w+10)/240))
 local cw=(w-14-(cols-1)*10)/cols
 grid.FillDirectionMaxCells=cols
 grid.CellSize=UDim2.fromOffset(cw,150)
 for _,card in ipairs(cards) do
  rect(card.ItemImage,8,8,70,80)
  rect(card.ItemName,86,8,cw-94,48)
  rect(card.Identity,8,94,cw-16,24)
  rect(card.Owned,8,120,cw-16,22)
 end
 local footerHeight=compact and 50 or 66
 local hintHeight=compact and 24 or 36
 rect(footer,0,h-footerHeight,w,footerHeight)
 rect(count,0,0,w*.45,footerHeight)
 rect(merge,w*.46,0,w*.54,footerHeight-2)
 rect(hint,0,h-footerHeight-hintHeight,w,hintHeight)
 rect(execute,0,48,w,math.max(1,h-48-footerHeight-hintHeight-4))
 local eh=execute.Size.Y.Offset
 resultText.Visible=not compact
 if compact then
  local left=w*.43
  rect(source,0,0,left,eh)
  rect(sourceImage,4,28,32,math.min(36,eh-28))
  rect(sourceName,4,0,left-8,24)
  sourceName.TextSize=18
  rect(sourceMeta,40,25,left-44,eh-25)
  sourceMeta.TextSize=16
  local item=selectedId and Master.Get(selectedId)
  if item then sourceMeta.Text=(icons[item.Element] or "").." "..item.Element.."\n"..item.Rarity end
  rect(socketArea,left+8,0,w-left-8,eh)
  rect(resultText,left+4,eh-24,w-left-4,24)
  resultText.TextSize=16
 else
  local sw=math.min(w*.7,480)
  rect(source,(w-sw)/2,0,sw,80)
  rect(sourceImage,8,4,72,72)
  rect(sourceName,88,4,sw-96,36)
  rect(sourceMeta,88,40,sw-96,34)
  sourceName.TextSize=24
  sourceMeta.TextSize=20
  local item=selectedId and Master.Get(selectedId)
  if item then sourceMeta.Text=(icons[item.Element] or "").." "..item.Element.." · "..item.Rarity end
  rect(socketArea,0,92,w,math.max(1,eh-124))
  rect(resultText,0,eh-28,w,28)
  resultText.TextSize=20
 end
 local aw,ah=socketArea.Size.X.Offset,socketArea.Size.Y.Offset
 local side=math.min(112,ah,(aw-math.max(0,required-1)*10)/math.max(1,required))
 local total=side*required+math.max(0,required-1)*10
 for i,socket in ipairs(sockets) do rect(socket,(aw-total)/2+(i-1)*(side+10),(ah-side)/2,side,side) end
end

render=function()
 -- Every render starts from a fully hidden state, then enables only the active step.
 -- This prevents stale UI from a previous step or the legacy panel from overlapping.
 old.Visible=false
 for _,object in ipairs({start,selection,empty,execute,footer,hint,back,title}) do object.Visible=false end
 if step==1 then
  start.Visible=true
 elseif step==2 then
  back.Visible=true
  title.Visible=true
  selection.Visible=loaded and #cards>0
  empty.Visible=not loaded or #cards==0
 elseif step==3 then
  back.Visible=true
  execute.Visible=true
  footer.Visible=true
  hint.Visible=true
 end
 empty.Text=loaded and "NO ITEMS AVAILABLE" or "Loading…"
 if step==2 and not fresh and status~="" then empty.Text=status end
 root:SetAttribute("Step",step)
 local recipe=byId[selectedId]
 local item=selectedId and Master.Get(selectedId)
 local n=recipe and math.min(required,recipe.Count) or 0
 count.Text=("%d/%d ITEMS"):format(n,required)
 sourceImage.Image=item and item.Image or ""
 sourceName.Text=item and (names[item.ItemType] or item.ItemType) or ""
 sourceMeta.Text=item and ((icons[item.Element] or "").." "..item.Element.." · "..item.Rarity) or ""
 source.BackgroundColor3=item and colors[item.Element] or template.BackgroundColor3
 for i,socket in ipairs(sockets) do
  socket.Item.Image=item and item.Image or ""
  socket.Item.Visible=i<=n
  socket.Missing.Visible=i>n
  socket.BackgroundTransparency=i<=n and 0 or .5
 end
 local result=recipe and Master.Get(recipe.ResultItemId)
 resultText.Text=result and ("→ "..result.Rarity.." ×1") or ""
 local enabled=fresh and recipe~=nil and recipe.CanMerge==true and not pending
 merge.Active=enabled
 merge.Interactable=enabled
 merge.AutoButtonColor=enabled
 merge.BackgroundColor3=enabled and Color3.fromRGB(37,99,255) or Color3.fromRGB(75,69,67)
 merge.Text=pending and "MERGING…" or "MERGE"
 if pending then
  hint.Text="Merging…"
 elseif status~="" then
  hint.Text=status
 elseif recipe and n<required then
  hint.Text=errors.NotEnoughItems
 else
  hint.Text=""
 end
 layout()
end

refresh=function()
 if fetching then return end
 fetching=true
 local requestRevision=revision
 local ok,state=pcall(function() return stateRemote:InvokeServer() end)
 fetching=false
 if requestRevision~=revision then task.defer(refresh);return end
 fresh=ok and typeof(state)=="table" and state.Loaded==true
 if fresh then
  loaded=true
  recipes=state.Recipes
  byId={}
  for _,recipe in ipairs(recipes) do byId[recipe.ItemId]=recipe end
  table.sort(recipes,less)
  if required~=state.RequiredCount then required=state.RequiredCount;rebuildSockets() end
  local signature={}
  for _,r in ipairs(recipes) do table.insert(signature,r.ItemId..":"..r.Count) end
  signature=table.concat(signature,"|")
  if selection:GetAttribute("InventorySignature")~=signature then
   selection:SetAttribute("InventorySignature",signature)
   rebuildCards()
  end
  if status=="Checking connection…" then status="" end
 else
  status="Checking connection…"
 end
 render()
end
choose.Activated:Connect(function() step=2;status="";render();task.spawn(refresh) end)
back.Activated:Connect(function() step=math.max(1,step-1);status="";render() end)
merge.Activated:Connect(function()
 if not merge.Interactable or pending then return end
 pending=true
 fresh=false
 revision+=1
 status=""
 render()
 -- Only this explicit action can consume items. Server revalidates everything.
 mergeRemote:FireServer(selectedId)
end)
mergeRemote.OnClientEvent:Connect(function(result)
 pending=false
 fresh=false
 revision+=1
 if typeof(result)=="table" and result.Success then
  local item=Master.Get(result.ResultItemId)
  status=item and ("Merged "..(names[item.ItemType] or item.ItemType).." "..item.Rarity) or "Merge complete."
 else
  status=typeof(result)=="table" and errors[result.Code] or nil
  status=status or "Merge failed. Please try again."
 end
 render()
 task.spawn(refresh)
end)
local wasVisible=false
local function opened()
 local now=visible()
 if now and not wasVisible then
  step=1
  selectedId=nil
  status=""
  fresh=false
  revision+=1
  render()
  task.spawn(refresh)
 end
 wasVisible=now
end
page:GetPropertyChangedSignal("Visible"):Connect(opened)
inventory:GetPropertyChangedSignal("Visible"):Connect(opened)
page:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
for _,name in ipairs({"ItemPurchaseRequest","ItemRobuxPurchaseRequest","ItemEquipRequest"}) do
 RS.Remotes:WaitForChild(name).OnClientEvent:Connect(function()
  fresh=false
  revision+=1
  if visible() then render();task.spawn(refresh) end
 end)
end
-- Also covers drops/rewards and temporary save locks while this tab is open.
task.spawn(function()
 while root.Parent do
  task.wait(2)
  if visible() and not pending then refresh() end
 end
end)
render()
opened()
