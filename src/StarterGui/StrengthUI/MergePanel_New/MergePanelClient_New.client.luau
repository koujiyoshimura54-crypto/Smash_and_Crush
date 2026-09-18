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
local colors={Fire=Color3.fromRGB(242,103,114),Ice=Color3.fromRGB(77,190,240),Electric=Color3.fromRGB(255,194,62)}
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
-- Merge-only palette: no changes to the Inventory shell or other tabs.
local palette={
 Background=Color3.fromRGB(168,78,226), BackgroundBottom=Color3.fromRGB(131,52,199),
 Card=Color3.fromRGB(182,108,242), CardBottom=Color3.fromRGB(132,64,210),
 Gold=Color3.fromRGB(255,211,64), Orange=Color3.fromRGB(255,146,35),
 Back=Color3.fromRGB(105,148,255), BackBottom=Color3.fromRGB(75,92,219),
 Socket=Color3.fromRGB(184,109,244), SocketEdge=Color3.fromRGB(231,190,255),
 Disabled=Color3.fromRGB(115,105,139), DisabledBottom=Color3.fromRGB(83,76,105),
 Ink=Color3.fromRGB(46,20,72),
}
local function paint(x,top,bottom,edge,radius)
 x.BackgroundTransparency=0
 x.BackgroundColor3=Color3.new(1,1,1)
 local gradient=x:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient",x)
 gradient.Color=ColorSequence.new(top,bottom or top)
 gradient.Rotation=90
 if x:IsA("TextLabel") or x:IsA("TextButton") then
  gradient.Enabled=false
  x.BackgroundColor3=top
 end
 local stroke
 for _,child in ipairs(x:GetChildren()) do
  if child:IsA("UIStroke") and child.ApplyStrokeMode==Enum.ApplyStrokeMode.Border then stroke=child;break end
 end
 if not stroke then stroke=Instance.new("UIStroke",x) end
 stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 stroke.Color=edge or palette.Ink
 stroke.Thickness=2
 stroke.Transparency=0
 local corner=x:FindFirstChildOfClass("UICorner") or Instance.new("UICorner",x)
 corner.CornerRadius=radius or UDim.new(0,14)
end
paint(root,palette.Background,palette.BackgroundBottom,palette.SocketEdge)
root.ZIndex=209
local function stars(item)
 return item and string.rep("★",Master.RarityRank[item.Rarity] or 0) or ""
end

local function label(name,parent,text,size)
 local x=make("TextLabel",name,parent)
 x.FontFace=template.ItemName.FontFace
 x.TextColor3=Color3.new(1,1,1)
 x.TextStrokeColor3=palette.Ink
 x.TextStrokeTransparency=.15
 x.TextSize=size
 x.Text=text
 x.TextWrapped=true
 local outline=inventory.Tabs.Merge.Label:FindFirstChildOfClass("UIStroke")
 if outline then outline:Clone().Parent=x end
 return x
end
local function button(name,parent,text)
 local x=make("TextButton",name,parent)
 paint(x,palette.Gold,palette.Orange)
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
paint(back,palette.Back,palette.BackBottom)
local title=label("StepTitle",root,"SELECT 1 ITEM",24)
local start=make("Frame","Start",root)
local choose=button("ChooseItem",start,"SELECT ITEM")
choose.TextSize=32
local startCount=label("Count",start,"0/3 ITEMS",24)
paint(startCount,palette.Card,palette.CardBottom,palette.SocketEdge,UDim.new(1,0))
local startSocketArea=make("Frame","Sockets",start)
local startSockets={}
for i=1,3 do
 local socket=make("Frame","Socket"..i,startSocketArea)
 paint(socket,palette.Socket,palette.CardBottom,palette.SocketEdge,UDim.new(1,0))
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
paint(source,palette.Gold,palette.Orange,palette.Gold)
local sourceImage=make("ImageLabel","ItemImage",source)
sourceImage.ScaleType=Enum.ScaleType.Fit
local sourceStars=label("RarityStars",source,"",26)
sourceStars.TextColor3=palette.Gold
sourceStars.TextScaled=true
sourceStars.TextWrapped=false
local socketArea=make("Frame","Sockets",execute)
local sockets={}
local upgrade=make("Frame","Upgrade",execute)
local fromStars=label("FromStars",upgrade,"",26)
local arrow=label("Arrow",upgrade,"→",32)
local toStars=label("ToStars",upgrade,"",26)
for _,x in ipairs({fromStars,toStars}) do
 paint(x,palette.Card,palette.CardBottom,palette.Gold)
 x.TextColor3=palette.Gold
 x.TextScaled=false
 x.TextWrapped=false
 local padding=Instance.new("UIPadding",x)
 padding.PaddingLeft=UDim.new(0,3)
 padding.PaddingRight=UDim.new(0,3)
end
local footer=make("Frame","Footer",root)
local count=label("Count",footer,"",26)
paint(count,palette.Card,palette.CardBottom,palette.SocketEdge,UDim.new(1,0))
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
   paint(card,palette.Card,palette.CardBottom,palette.SocketEdge)
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
  paint(socket,palette.Socket,palette.CardBottom,palette.SocketEdge,UDim.new(1,0))
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
 local compact=h<340
 rect(back,10,8,100,40)
 rect(title,120,8,w-132,40)
 rect(start,0,0,w,h)
 local factor=math.min(1,h/300)
 local bw=math.min(w-32,480)
 local startTop=math.max(10,(h-274*factor)/2)
 rect(choose,(w-bw)/2,startTop,bw,64*factor)
 choose.TextSize=math.max(22,32*factor)
 rect(startCount,(w-210)/2,startTop+78*factor,210,34*factor)
 startCount.TextSize=math.max(16,24*factor)
 rect(startSocketArea,8,startTop+126*factor,w-16,80*factor)
 local startSide=72*factor
 local startTotal=startSide*3+24
 for i,socket in ipairs(startSockets) do
  rect(socket,(w-16-startTotal)/2+(i-1)*(startSide+12),0,startSide,startSide)
 end
 rect(intro,12,startTop+222*factor,w-24,40*factor)
 intro.TextSize=math.max(16,20*factor)
 rect(selection,10,58,w-20,h-68)
 rect(empty,12,60,w-24,h-72)
 local cols=math.max(1,math.floor((w-10)/240))
 local cw=(w-30-(cols-1)*10)/cols
 grid.FillDirectionMaxCells=cols
 grid.CellSize=UDim2.fromOffset(cw,150)
 for _,card in ipairs(cards) do
  rect(card.ItemImage,8,8,70,80)
  rect(card.ItemName,86,8,cw-94,48)
  rect(card.Identity,8,94,cw-16,24)
  rect(card.Owned,8,120,cw-16,22)
 end
 rect(execute,0,0,w,h)
 local side,areaX,areaW,socketY,socketH
 if compact then
  -- Short landscape view: preserve readable controls beside the hero image.
  local hero=math.min(140,h-64,w*.36)
  local leftW=w*.42
  rect(source,(leftW-hero)/2,54,hero,hero)
  rect(upgrade,122,10,w-134,34)
  areaX,areaW=leftW+4,w-leftW-16
  socketY,socketH=56,math.max(32,h-174)
  rect(footer,areaX,h-106,areaW,98)
  rect(count,(areaW-math.min(190,areaW))/2,0,math.min(190,areaW),30)
  rect(merge,0,56,areaW,42)
  rect(hint,areaX,h-74,areaW,18)
  hint.TextSize=14
  merge.TextSize=26
 else
  local hero=math.min(154,h*.28)
  rect(source,(w-hero)/2,10,hero,hero)
  local upgradeW=math.min(350,w-40)
  rect(upgrade,(w-upgradeW)/2,20+hero,upgradeW,36)
  areaX,areaW=12,w-24
  socketY=66+hero
  socketH=math.max(40,h-socketY-142)
  local footerW=math.min(480,w-32)
  rect(footer,(w-footerW)/2,h-130,footerW,120)
  rect(count,(footerW-220)/2,0,220,32)
  rect(merge,0,64,footerW,56)
  rect(hint,12,h-94,w-24,24)
  hint.TextSize=17
  merge.TextSize=32
 end
 local heroW,heroH=source.Size.X.Offset,source.Size.Y.Offset
 rect(sourceImage,6,4,heroW-12,heroH*.73)
 rect(sourceStars,8,heroH*.74,heroW-16,heroH*.23)
 local uw,uh=upgrade.Size.X.Offset,upgrade.Size.Y.Offset
 rect(fromStars,0,0,uw*.43,uh)
 rect(arrow,uw*.43,0,uw*.14,uh)
 rect(toStars,uw*.57,0,uw*.43,uh)
 for _,x in ipairs({fromStars,toStars}) do
  x.TextSize=math.floor(math.min(26,uh*.68,(uw*.43-10)/math.max(1,utf8.len(x.Text))))
 end
 rect(socketArea,areaX,socketY,areaW,socketH)
 side=math.min(88,socketH-4,(areaW-math.max(0,required-1)*14)/math.max(1,required))
 local total=side*required+math.max(0,required-1)*14
 for i,socket in ipairs(sockets) do
  rect(socket,(areaW-total)/2+(i-1)*(side+14),(socketH-side)/2,side,side)
  socket.Missing.TextSize=math.max(26,side*.6)
 end
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
 sourceStars.Text=stars(item)
 for i,socket in ipairs(sockets) do
  socket.Item.Image=item and item.Image or ""
  socket.Item.Visible=i<=n
  socket.Missing.Visible=i>n
  paint(socket,i<=n and palette.Card or palette.Socket,palette.CardBottom,i<=n and palette.Gold or palette.SocketEdge,UDim.new(1,0))
 end
 local result=recipe and Master.Get(recipe.ResultItemId)
 fromStars.Text=stars(item)
 toStars.Text=stars(result)
 local enabled=fresh and recipe~=nil and recipe.CanMerge==true and not pending
 merge.Active=enabled
 merge.Interactable=enabled
 merge.AutoButtonColor=enabled
 paint(merge,enabled and palette.Gold or palette.Disabled,enabled and palette.Orange or palette.DisabledBottom)
 merge.TextColor3=enabled and Color3.new(1,1,1) or Color3.fromRGB(219,209,234)
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
 hint.Visible=step==3 and hint.Text~=""
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
  status="Merge complete."
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
