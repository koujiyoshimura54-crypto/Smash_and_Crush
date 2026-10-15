-- Purchased Merge Shop presentation. No Pet merge transaction or new recipe authority.
-- Reference coordinate system: Item image panel (150,63)-(1522,886), 1372 x 823.
-- BEGIN MERGE VIEW: the same factory is used by Edit-only previews with read-only adapters.
local function buildMergeShop(ctx)
 local gui,RS,PetClient,Egg,Master=ctx.gui,ctx.RS,ctx.PetClient,ctx.Egg,ctx.Master
 local ItemMergeConfig=require(RS.Config.ItemMergeConfig)
 -- Item Merge only; Inventory and the shared Shop/drop star renderer stay intact.
 local goldStar="rbxassetid://76134658177553"
 local greyStar="rbxassetid://126441080731699"
 local itemStarBand=44
 local function itemStars(parent,item)
  local row=Instance.new("Frame");row.Name="RarityStars";row.BackgroundTransparency=1
  row.BorderSizePixel=0;row.Active=false;row.ZIndex=227;row.Parent=parent
  local rank=Master.RarityRank[item.Rarity]
  for i=1,5 do
   local star=Instance.new("ImageLabel");star.Name="Star"..i
   star.Image=i<=rank and goldStar or greyStar;star.ImageColor3=Color3.new(1,1,1)
   star.BackgroundTransparency=1;star.ScaleType=Enum.ScaleType.Fit;star.Active=false
   star.ZIndex=228;star.Parent=row
  end
  return row
 end
 local function layoutItemStars(row,width,height)
  local side=math.floor(math.min((width-8)/5,height))
  local x=(width-5*side-8)/2
  for i=1,5 do
   row["Star"..i].Position=UDim2.fromOffset(x+(i-1)*(side+2),(height-side)/2)
   row["Star"..i].Size=UDim2.fromOffset(side,side)
  end
 end
 local UIS=ctx.Input
 local connections,cardCleanups,candidateCleanups={},{},{}
 local destroyed=false
 local function connect(signal,fn)
  local c=signal:Connect(fn);table.insert(connections,c);return c
 end
 local function clone(source,name,parent)
  local x=source:Clone();x.Name=name
  for _,d in x:GetDescendants() do
   if d:IsA("LuaSourceContainer") then d:Destroy()
   elseif d:IsA("GuiObject") then d.AutoLocalize=false end
  end
  if x:IsA("GuiObject") then x.AutoLocalize=false end
  x.Parent=parent
  return x
 end
 local function rect(x,a,b,w,h)
  x.AnchorPoint=Vector2.zero;x.Position=UDim2.fromOffset(a,b);x.Size=UDim2.fromOffset(w,h)
 end
 local function layer(x,z)
  if x:IsA("GuiObject") then x.ZIndex=z end
  for _,d in x:GetDescendants() do
   if d:IsA("GuiObject") then
    d.ZIndex=z+(d:IsA("TextLabel") and 3 or d.Name=="StudPattern" and 1 or 2)
   end
  end
 end
 local function clearLayout(x)
  for _,d in x:GetChildren() do
   if d:IsA("UIGridStyleLayout") or d:IsA("UIAspectRatioConstraint") or d:IsA("UISizeConstraint") or d:IsA("UIScale") or d:IsA("UIPadding") then d:Destroy() end
  end
 end
 local shopSource=gui:WaitForChild("ShopPanel")
 local buttonSource=shopSource.MainScrollingFrame.Holder.Card01_SecretPack.Owned
 local labelSource=shopSource.Top.ShopText1
 local panelSource=ctx.PurchasedInventory.Parent.Parent.RestockShop.Main.Background
 local shop=clone(shopSource,"MergeShopPanel",gui)
 shop.Visible=false;shop.ClipsDescendants=false;shop.ZIndex=210
 shop.BackgroundColor3=Color3.fromRGB(10,24,32);shop.BackgroundTransparency=.12
 if not shop:FindFirstChildOfClass("UICorner") then panelSource.UICorner:Clone().Parent=shop end
 shop:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0,20)
 clearLayout(shop)
 for _,child in shop:GetChildren() do
  if child:IsA("GuiObject") and child.Name~="Top" and child.Name~="MainScrollingFrame" then child:Destroy() end
 end
 shop:SetAttribute("ReferenceDesignSize",Vector2.new(1372,823))
 shop:SetAttribute("ResponsiveDesignSize",nil)
 local scale=Instance.new("UIScale");scale.Name="MergeFit";scale.Parent=shop
 local body=shop.MainScrollingFrame
 for _,child in body:GetChildren() do child:Destroy() end
 body.BackgroundTransparency=1;body.CanvasSize=UDim2.new();body.AutomaticCanvasSize=Enum.AutomaticSize.None
 body.ScrollingEnabled=false;body.ScrollBarThickness=0;body.ClipsDescendants=false;body.ZIndex=211
 local top=shop.Top;clearLayout(top);layer(top,220)
 if not top:FindFirstChildOfClass("UICorner") then panelSource.UICorner:Clone().Parent=top end
 top:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0,18)
 top.UIGradient.Color=ColorSequence.new(Color3.fromRGB(255,208,0),Color3.fromRGB(255,245,0))
 top.StudPattern.TileSize=UDim2.fromOffset(180,180)
 -- Bold face already used by the purchased HatchClient result labels (TEXT_FONT).
 local purchasedBold=Font.fromEnum(Enum.Font.GothamBlack)
 top.ShopText1.Text="Merge";top.ShopText2.Text="Merge"
 for _,name in {"ShopText1","ShopText2"} do
  top[name].TextXAlignment=Enum.TextXAlignment.Left
  top[name].TextWrapped=true;top[name].TextScaled=true;top[name].FontFace=purchasedBold
 end
 top.ShopText1.ZIndex=226;top.ShopText2.ZIndex=224
 top.Close.Text="";top.Close.TextLabel.Text="×"
 local function text(name,parent,value)
  local x=clone(labelSource,name,parent)
  clearLayout(x);x.Text=value;x.TextWrapped=true;x.TextScaled=true;x.FontFace=purchasedBold
  x.BackgroundTransparency=1;x.Visible=true;x.ZIndex=240;x.TextXAlignment=Enum.TextXAlignment.Center
  local limit=Instance.new("UITextSizeConstraint");limit.MinTextSize=12;limit.MaxTextSize=46;limit.Parent=x
  return x
 end
 local function panel(name,parent)
  local x=clone(panelSource,name,parent);clearLayout(x)
  for _,d in x:GetChildren() do if d:IsA("GuiObject") then d:Destroy() end end
  x.Visible=true;x.BackgroundColor3=Color3.fromRGB(13,28,38);x.BackgroundTransparency=.24
  x.UICorner.CornerRadius=UDim.new(0,18)
  x.ClipsDescendants=false;x.ZIndex=214
  local stroke=x:FindFirstChildOfClass("UIStroke")
  if stroke then
   stroke.Color=Color3.fromRGB(71,112,135);stroke.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize
   stroke.Thickness=2;stroke.Transparency=.2
  end
  return x
 end
 local function action(name,parent,value,red)
  local x=clone(buttonSource,name,parent);clearLayout(x)
  x.Text="";x.Visible=true;layer(x,240)
  x.PriceTag.Text=value;x.PriceTag.TextColor3=Color3.new(1,1,1)
  x.PriceTag.FontFace=purchasedBold;x.PriceTag.TextWrapped=true;x.PriceTag.TextScaled=true
  for _,s in x.PriceTag:GetChildren() do if s:IsA("UIStroke") then s.Color=Color3.new(0,0,0);s.Thickness=.07 end end
  x.StudPattern.TileSize=UDim2.fromOffset(180,180)
  x.UICorner.CornerRadius=UDim.new(0,14)
  x.PriceTag.TextXAlignment=Enum.TextXAlignment.Center
  x.PriceTag.Size=UDim2.fromScale(.91,.78);x.PriceTag.Position=UDim2.fromScale(.5,.5);x.PriceTag.AnchorPoint=Vector2.new(.5,.5)
  if red then
   -- Use the purchased red close-control gradient, not an invented button image.
   x.UIGradient.Color=ColorSequence.new(Color3.fromRGB(255,30,47),Color3.fromRGB(255,93,100))
   x.UIGradient.Rotation=shopSource.Top.Close.UIGradient.Rotation
  end
  return x
 end
 local tabs={Item=action("Item",body,"Item"),Pet=action("Pet",body,"Pet")}
 -- Owned is an inactive purchase-state donor; navigation must accept input.
 for _,button in pairs(tabs) do button.Active=true;button.Interactable=true end
 local listTitle=text("ListTitle",body,"Your Items");listTitle.TextXAlignment=Enum.TextXAlignment.Left
 local list=clone(ctx.PurchasedInventory.Items,"Materials",body);clearLayout(list)
 for _,d in list:GetChildren() do if d:IsA("GuiObject") then d:Destroy() end end
 list.BackgroundTransparency=1;list.Visible=true;list.ZIndex=220
 list.ClipsDescendants=true;list.ScrollingEnabled=true;list.ScrollingDirection=Enum.ScrollingDirection.Y
 list.AutomaticCanvasSize=Enum.AutomaticSize.None;list.CanvasSize=UDim2.new();list.ScrollBarThickness=10
 local empty=text("Empty",body,"");empty.TextWrapped=true
 local result=panel("Result",body)
 local resultTitle=text("ResultTitle",result,"Merge Result");resultTitle.TextXAlignment=Enum.TextXAlignment.Left
 local resultHint=text("ResultHint",result,"");resultHint.TextWrapped=true
 local resultItems=clone(ctx.PurchasedInventory.Items,"ResultItems",result);clearLayout(resultItems)
 for _,d in resultItems:GetChildren() do if d:IsA("GuiObject") then d:Destroy() end end
 resultItems.BackgroundTransparency=1;resultItems.ScrollBarThickness=6;resultItems.ScrollingDirection=Enum.ScrollingDirection.Y
 resultItems.AutomaticCanvasSize=Enum.AutomaticSize.None;resultItems.ScrollingEnabled=true;resultItems.ClipsDescendants=true;resultItems.ZIndex=222
 local drop=panel("DropArea",body)
 local dropStroke=drop:FindFirstChildOfClass("UIStroke")
 if dropStroke then dropStroke.Thickness=4;dropStroke.Transparency=0;dropStroke.Enabled=false end
 -- Dashed outline: resize repeated copies of the purchased rounded Stroke surface.
 -- No drawn/imported texture or replacement artwork.
 local dashes={}
 local function dash(index,x,y,w,h)
  local d=dashes[index]
  if not d then
   d=clone(RS.Assets.Templates.PetInventory.Stroke,"Dash"..index,drop)
   for _,c in d:GetChildren() do if not c:IsA("UICorner") then c:Destroy() end end
   d.UICorner.CornerRadius=UDim.new(1,0);d.ZIndex=216;d.Visible=true;d.Active=false
   dashes[index]=d
  end
  rect(d,x,y,w,h);d.BackgroundColor3=dropStroke and dropStroke.Color or Color3.fromRGB(0,218,242)
 end
 -- Reuse the actual purchased Stud surface. The donor border remains a real solid UIStroke.
 local dropStud=clone(buttonSource.StudPattern,"StudPattern",drop)
 dropStud.AnchorPoint=Vector2.zero;dropStud.Position=UDim2.new();dropStud.Size=UDim2.fromScale(1,1)
 dropStud.ImageTransparency=.9;dropStud.ZIndex=215;dropStud.Active=false
 local dropTitle=text("Added",drop,"Drag Items Here")
 local dropHint=text("DropHint",drop,"Select at least 2 Items")
 local selectedLabel=text("Selected",body,"Selected: 0");selectedLabel.TextXAlignment=Enum.TextXAlignment.Left
 local clear=action("Clear",body,"Clear",true)
 local merge=action("Merge",body,"Merge")
 local creates=text("Creates",body,"Creates 1 Item")
 local status=text("Status",body,"");status.TextWrapped=true
 local tab="Item"
 local petState,itemState=nil,nil
 local petSelected,itemSelected={},{ }
 local committedItemId=nil
 local itemFresh,itemPending=false,false
 local items,tiles={},{}
 local cardTints={}
 local listKey=""
 local candidateKey=""
 local candidates={}
 local cell=150
 local itemMinimum=ItemMergeConfig.MinimumCount
 local itemGroups,totalItemUnits={},0
 local compressedCanvas,materialCanvasHeight=false,0
 local drag=nil
 local blockedActivation={}
 local render,refreshList,layout
 local view={Root=shop,Drop=drop,Tabs=tabs,List=list,Merge=merge,ClearButton=clear}
 local function selectedCount()
  local n=0;for _ in pairs(tab=="Pet" and petSelected or itemSelected) do n+=1 end;return n
 end
 local function itemMaterials()
  local materials={}
  for _,entry in pairs(itemSelected) do materials[entry.ItemId]=(materials[entry.ItemId] or 0)+1 end
  return materials
 end
 local function itemPreview()
  return ItemMergeConfig.Evaluate(itemMaterials(),itemState and itemState.OwnedItems or {})
 end
 local function worn(id) return petState and table.find(petState.Equipped or {},id)~=nil end
 local function selectable(entry)
  if tab=="Pet" then
   return petState and petState.Owned[entry.Id]==entry.Name and not worn(entry.Id) and Egg.mergePet(entry.Name)~=nil
  end
  local count=itemState and itemState.OwnedItems and itemState.OwnedItems[entry.ItemId] or 0
  return not itemPending and ItemMergeConfig.GetPoints(Master.Get(entry.ItemId)) and count>=entry.Unit
 end
 local function selected(entry)
  return tab=="Pet" and petSelected[entry.Id]==true or tab=="Item" and itemSelected[entry.Key]~=nil
 end
 local function releaseCandidates()
  for _,fn in candidateCleanups do fn() end;table.clear(candidateCleanups)
  for _,x in candidates do x:Destroy() end;table.clear(candidates);candidateKey=""
 end
 local function endDrag()
  local old=drag;drag=nil
  if not old then return end
  if old.Ghost then old.Ghost:Destroy() end
  for object,props in pairs(old.Faded or {}) do
   if object.Parent then for key,value in pairs(props) do object[key]=value end end
  end
  if list.Parent then list.ScrollingEnabled=true end
  dropTitle.Visible=true;dropHint.Visible=true
 end
 local function releaseCards()
  endDrag()
  for _,fn in pairs(cardCleanups) do fn() end
  table.clear(cardCleanups);table.clear(tiles);table.clear(cardTints)
 end
 local function choose(entry,addOnly)
  if not selectable(entry) then return end
  if tab=="Pet" then
   if addOnly then petSelected[entry.Id]=true else petSelected[entry.Id]=not petSelected[entry.Id] or nil end
  else
   if not addOnly and itemSelected[entry.Key] then itemSelected[entry.Key]=nil else itemSelected[entry.Key]=entry end
   committedItemId=nil
  end
  status.Text="";render()
 end
 local function point(input)
  local v=Vector2.new(input.Position.X,input.Position.Y)
  local root=shop:FindFirstAncestorWhichIsA("ScreenGui")
  if root and not root.IgnoreGuiInset then v-=ctx.GuiService:GetGuiInset() end
  return v
 end
 local function overlapsDrop(p)
  if not drag or not drag.Ghost then return false end
  local ghost=drag.Ghost
  local s=ghost.AbsoluteSize
  if s.X<=0 or s.Y<=0 then s=Vector2.new(cell,cell)*scale.Scale end
  local angle=math.rad(ghost.AbsoluteRotation)
  local c,sine=math.abs(math.cos(angle)),math.abs(math.sin(angle))
  local half=Vector2.new(c*s.X+sine*s.Y,sine*s.X+c*s.Y)/2
  local a,b=drop.AbsolutePosition,drop.AbsolutePosition+drop.AbsoluteSize
  -- p is also the ghost's rendered centre; use screen pixels after UIScale/inset.
  return p.X+half.X>a.X and p.X-half.X<b.X and p.Y+half.Y>a.Y and p.Y-half.Y<b.Y
 end
 local function updateGhost(p)
  if not drag or not drag.Ghost then return end
  local v=(p-shop.AbsolutePosition)/math.max(scale.Scale,.01)
  drag.Ghost.Position=UDim2.fromOffset(v.X,v.Y)
  if dropStroke then dropStroke.Color=overlapsDrop(p) and Color3.fromRGB(0,229,255) or Color3.fromRGB(85,255,0) end
  for _,d in dashes do d.BackgroundColor3=dropStroke.Color end
 end
 local function startGhost()
  if not drag or not selectable(drag.Entry) then endDrag();return end
  drag.Active=true;list.ScrollingEnabled=false
  local tile=drag.Tile
  local ghost=clone(tile,"DraggingMaterial",shop)
  clearLayout(ghost);ghost.AnchorPoint=Vector2.new(.5,.5);ghost.Size=UDim2.fromOffset(cell,cell+(tab=="Item" and itemStarBand or 0))
  layer(ghost,280);ghost.Rotation=-8;ghost.Active=false
  for _,d in ghost:GetDescendants() do
   if d:IsA("GuiButton") then d.Visible=false;d.Interactable=false end
   if d.Name=="Checkmark" or d.Name=="Title" or d.Name=="StackCount" then d.Visible=false end
  end
  -- Explicit image order retains the material-only Sibling -> Global correction.
  ghost.Main.ZIndex=282;ghost.Main.Icon.ZIndex=284
  local stars=ghost:FindFirstChild("RarityStars")
  if stars then layer(stars,286) end
  drag.Ghost=ghost;drag.Faded={}
  dropTitle.Visible=false;dropHint.Visible=false
  for _,d in tile:GetDescendants() do
   if d:IsA("GuiObject") then
    local values={BackgroundTransparency=d.BackgroundTransparency}
    if d:IsA("ImageLabel") then values.ImageTransparency=d.ImageTransparency;d.ImageTransparency=math.max(.65,d.ImageTransparency) end
    if d:IsA("TextLabel") then values.TextTransparency=d.TextTransparency;d.TextTransparency=math.max(.65,d.TextTransparency) end
    drag.Faded[d]=values;d.BackgroundTransparency=math.max(.65,d.BackgroundTransparency)
   end
  end
  updateGhost(drag.Last)
 end
 local function attach(tile,entry)
  local localConnections={}
  table.insert(localConnections,tile.Button.InputBegan:Connect(function(input)
   local touch=input.UserInputType==Enum.UserInputType.Touch
   if not touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
   view:PressMaterial(entry.Key,point(input),touch,input)
  end))
  return function() for _,c in localConnections do c:Disconnect() end end
 end
 function view:PressMaterial(key,p,touch,input)
  if drag or not shop.Visible then return end
  local entry
  for _,candidate in items do if candidate.Key==key then entry=candidate;break end end
  if not entry or not tiles[key] or not selectable(entry) then return end
  drag={Input=input,Touch=touch,Start=p,Last=p,Tile=tiles[key],Entry=entry,Time=os.clock(),Active=false}
  -- Touch: movement before the hold remains native list scrolling, not a drop.
  if touch then
   local token=drag
   task.delay(.24,function() if drag==token and not token.Scrolling and (token.Last-token.Start).Magnitude<10 then startGhost() end end)
  end
 end
 function view:MovePointer(p)
  if not drag then return end
  drag.Last=p
  local delta=p-drag.Start
  if not drag.Active then
   if drag.Touch and not drag.Scrolling and delta.Magnitude>=10 then
    drag.Scrolling=true;blockedActivation[drag.Entry.Key]=os.clock()+.6
   elseif not drag.Touch and delta.Magnitude>=6 then startGhost() end
  end
  if drag and drag.Active then updateGhost(p) end
 end
 function view:ReleasePointer(p)
  if not drag then return end
  local old=drag
  if old.Active or old.Scrolling then blockedActivation[old.Entry.Key]=os.clock()+.4 end
  if old.Active then updateGhost(p) end
  local commit=old.Active and overlapsDrop(p) and shop.Visible
  endDrag()
  if commit then choose(old.Entry,true) end
  render()
 end
 if UIS then
  connect(UIS.InputChanged,function(input)
   if not drag then return end
   if drag.Touch and input~=drag.Input then return end
   if not drag.Touch and input.UserInputType~=Enum.UserInputType.MouseMovement then return end
   view:MovePointer(point(input))
  end)
  connect(UIS.InputEnded,function(input)
   if not drag then return end
   if drag.Touch and input~=drag.Input then return end
   if not drag.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
   view:ReleasePointer(point(input))
  end)
  connect(UIS.WindowFocusReleased,function() if drag then blockedActivation[drag.Entry.Key]=os.clock()+.4;endDrag();render() end end)
 end
 local function clicked(entry)
  if drag and drag.Entry.Key==entry.Key and (drag.Active or drag.Scrolling) then return end
  if os.clock()<(blockedActivation[entry.Key] or 0) then return end
  choose(entry,false)
 end
 function view:ActivateMaterial(key)
  if not shop.Visible then return end
  for _,entry in items do if entry.Key==key then clicked(entry);return end end
 end
 local function prepareTile(tile,entry)
  clearLayout(tile);tile.ClipsDescendants=false
  tile.Main.AnchorPoint=Vector2.zero;tile.Main.Position=UDim2.new();tile.Main.Size=UDim2.fromScale(1,1)
  if tab=="Item" then
   tile.Main.Size=UDim2.new(1,0,1,-itemStarBand)
   tile.Stroke.AnchorPoint=Vector2.zero;tile.Stroke.Position=UDim2.new();tile.Stroke.Size=UDim2.fromScale(1,1)
  end
  tile.Main.Icon.Size=UDim2.fromScale(.94,.94);tile.Main.Icon.Position=UDim2.fromScale(.5,.5)
  tile.Main.Icon.AnchorPoint=Vector2.new(.5,.5);tile.Main.Icon.ScaleType=Enum.ScaleType.Fit
  tile.Title.Visible=false
  local check=tile.Main.Checkmark
  check.AnchorPoint=Vector2.new(1,0);check.Position=UDim2.new(1,-2,0,2);check.Size=UDim2.fromScale(.27,.27)
  tile.Button.Text="";tile.Button.AutoButtonColor=false
  tile:SetAttribute("MaterialName",entry.Name)
  if not tile.Main:FindFirstChild("StudPattern") then
   local stud=clone(buttonSource.StudPattern,"StudPattern",tile.Main)
   stud.AnchorPoint=Vector2.zero;stud.Position=UDim2.new();stud.Size=UDim2.fromScale(1,1)
   stud.ZIndex=tile.Main.ZIndex;stud.ImageTransparency=.87;stud.Active=false
  end
  -- The selectable border is the purchased tile's own stroke; no overlay panel.
  local edge=tile.Main:FindFirstChildOfClass("UIStroke")
  if edge then tile:SetAttribute("OriginalEdgeColor",edge.Color) end
 end
 local function makeItemTile(entry,order)
  local tile=clone(RS.Assets.Templates.PetInventory,entry.Key,list)
  layer(tile,222);tile.Stroke.ZIndex=222;tile.Main.ZIndex=223;tile.Main.Icon.ZIndex=225
  tile.Main.Checkmark.ZIndex=226;tile.Title.ZIndex=227;tile.Button.ZIndex=228
  tile.Visible=true;tile.LayoutOrder=order;tile.Main.Icon.Image=Master.Get(entry.ItemId).Image
  local oldStars=tile.Main.Icon:FindFirstChild("RarityStars");if oldStars then oldStars:Destroy() end
  itemStars(tile,Master.Get(entry.ItemId))
  local palette=ctx.ItemColors[Master.Get(entry.ItemId).Rarity]
  if palette then tile.Main.UIGradient.Color=palette end
  local activation=tile.Button.Activated:Connect(function() view:ActivateMaterial(entry.Key) end)
  return tile,function() activation:Disconnect();tile:Destroy() end
 end
 local refreshingList=false
 local function materialAt(index)
  for _,g in ipairs(itemGroups) do
   if index>=g.Start and index<g.Start+g.Count then
    local unit=index-g.Start+1;local info=Master.Get(g.ItemId)
    return {ItemId=g.ItemId,Unit=unit,Key=g.ItemId..":"..string.format("%.0f",unit),
     Name=info.Rarity.." "..info.Element.." "..info.ItemType,VirtualIndex=index}
   end
  end
 end
 refreshList=function(force)
  if refreshingList then return end;refreshingList=true
  local nextItems={}
  if tab=="Pet" then
   for id,name in pairs(petState and petState.Owned or {}) do
    if Egg.mergePet(name) and not worn(id) then table.insert(nextItems,{Id=id,Key=id,Name=name}) end
   end
   table.sort(nextItems,function(a,b) return a.Name==b.Name and a.Id<b.Id or a.Name<b.Name end)
  else
   itemGroups={};totalItemUnits=0
   local ids={}
   for id,count in pairs(itemState and itemState.OwnedItems or {}) do
    if ItemMergeConfig.GetPoints(Master.Get(id)) and type(count)=="number" and count>0 and count%1==0 and count<=ItemMergeConfig.MaxInteger then table.insert(ids,id) end
   end
   table.sort(ids)
   for _,id in ipairs(ids) do
    local count=itemState.OwnedItems[id]
    count=math.min(count,ItemMergeConfig.MaxInteger-totalItemUnits)
    if count>0 then table.insert(itemGroups,{ItemId=id,Count=count,Start=totalItemUnits+1});totalItemUnits+=count end
   end
   local stride=cell+itemStarBand+8
   local rows=math.ceil(totalItemUnits/3)
   materialCanvasHeight=math.min(rows*stride,1000000)
   compressedCanvas=rows*stride>1000000
   local localHeight=list.AbsoluteSize.Y/math.max(scale.Scale,.01)
   local canvasY=list.CanvasPosition.Y/math.max(scale.Scale,.01)
   local visibleRows=math.max(1,math.ceil(localHeight/stride)+2)
   local firstRow
   if compressedCanvas then
    local range=math.max(1,list.AbsoluteCanvasSize.Y-list.AbsoluteSize.Y)
    local share=list.CanvasPosition.Y>=range-1 and 1 or math.clamp(list.CanvasPosition.Y/range,0,1)
    firstRow=math.floor(share*math.max(0,rows-visibleRows))
   else firstRow=math.max(0,math.floor(canvasY/stride)) end
   for index=firstRow*3+1,math.min(totalItemUnits,(firstRow+visibleRows)*3) do
    local entry=materialAt(index)
    if entry then entry.ViewY=compressedCanvas and canvasY+math.floor((index-firstRow*3-1)/3)*stride or math.floor((index-1)/3)*stride;table.insert(nextItems,entry) end
   end
  end
  local signature={tab}
  for _,entry in nextItems do table.insert(signature,entry.Key..":"..entry.Name) end
  local key=table.concat(signature,"|")
  if not force and key==listKey then
   items=nextItems;refreshingList=false;return
  end
  releaseCards();items=nextItems;listKey=key
  for index,entry in items do
   local tile,cleanup
   if tab=="Pet" then tile,cleanup=PetClient.createMaterialTile(entry.Id,entry.Name,index,list,function() view:ActivateMaterial(entry.Key) end)
   else tile,cleanup=makeItemTile(entry,index) end
   if tile then
    prepareTile(tile,entry)
    local unbind=attach(tile,entry)
    tiles[entry.Key]=tile
    cardCleanups[entry.Key]=function() unbind();cleanup() end
   end
  end
  refreshingList=false
  if layout then layout() end
 end
 local function candidate(name,image,percent,index,total,rarity,resultItemId)
  local x=clone(RS.Assets.Templates.OpenEgg.Background.Pets["1"],name,tab=="Item" and resultItems or result)
  clearLayout(x);x.AnchorPoint=Vector2.new(.5,0);x.Visible=true;x.Image="";x.BackgroundTransparency=1
  x.ZIndex=223;x.Button.Visible=false;x.Button.Active=false;x.Button.Interactable=false
  local label=percent and not rarity and action("Name",x,name) or text("Name",x,name)
  if percent and not rarity then
   label.Active=false;label.Interactable=false;label.Selectable=false;label.AutoButtonColor=false
   if ctx.ItemColors[name] and name~="Rare" then label.UIGradient.Color=ctx.ItemColors[name] end
  end
  label.AnchorPoint=Vector2.new(.5,1);label.Position=UDim2.fromScale(.5,percent and .87 or 1)
  if rarity then
   x.ClipsDescendants=false
   for _,limit in label:GetChildren() do if limit:IsA("UITextSizeConstraint") then limit.MinTextSize=6;limit.MaxTextSize=28 end end
  end
  label.Size=UDim2.fromScale(1,.15)
  x.Percent.AnchorPoint=Vector2.new(.5,1);x.Percent.Position=UDim2.fromScale(.5,1)
  x.Percent.Size=UDim2.fromScale(1,.13);x.Percent.ZIndex=240;x.Percent.AutoLocalize=false
  x.Percent.FontFace=purchasedBold;x.Percent.TextXAlignment=Enum.TextXAlignment.Center
  x.Percent.TextWrapped=true;x.Percent.TextScaled=true
  local percentStroke=labelSource:FindFirstChildOfClass("UIStroke")
  if percentStroke then
   for _,old in x.Percent:GetChildren() do if old:IsA("UIStroke") then old:Destroy() end end
   percentStroke:Clone().Parent=x.Percent
  end
  x.Percent.Text=percent and string.format("%.2f",percent):gsub("0+$",""):gsub("%.$","").."%" or "";x.Percent.Visible=percent~=nil
  x:SetAttribute("CandidateIndex",index);x:SetAttribute("CandidateCount",total)
  if image~="" then
   if rarity then
    local card=clone(RS.Assets.Templates.PetInventory.Main,"ResultCard",x)
    clearLayout(card)
    for _,d in card:GetChildren() do if d:IsA("GuiObject") then d:Destroy() end end
    card.AnchorPoint=Vector2.new(.5,0);card.Position=UDim2.fromScale(.5,0);card.Size=UDim2.fromScale(.82,.82);card.ZIndex=223
    card.UIGradient.Color=ctx.ItemColors[rarity] or card.UIGradient.Color
   end
   local pic=clone(RS.Assets.Templates.PetInventory.Main.Icon,"ActualImage",x)
   pic.Image=image;pic.ZIndex=225;pic.AnchorPoint=Vector2.zero;pic.Position=UDim2.new();pic.Size=UDim2.fromScale(1,rarity and .82 or .72)
   pic.ScaleType=Enum.ScaleType.Fit;pic.Visible=true;pic.ImageTransparency=0
   if resultItemId then
    local oldStars=pic:FindFirstChild("RarityStars");if oldStars then oldStars:Destroy() end
    itemStars(x,Master.Get(resultItemId))
   end
  else
   local ok,cleanup,viewport=pcall(ctx.EggViewport.mountEgg,x,name)
   if ok and cleanup then
    viewport.Position=UDim2.new();viewport.Size=UDim2.fromScale(1,.72);viewport.ZIndex=225
    table.insert(candidateCleanups,cleanup)
   else warn("[MergeShop] Actual Egg preview unavailable: "..name.." "..tostring(cleanup)) end
  end
  table.insert(candidates,x);return x
 end
 local function updateResults(n)
  if not shop.Visible then releaseCandidates();return end
  local outcomes={}
  if tab=="Pet" then
   local points=0
   for id in pairs(petSelected) do local meta=petState and Egg.mergePet(petState.Owned[id]);if meta then points+=meta.Points end end
   local preview=Egg.mergePreview(points,n)
   -- No agreed mixed-origin "maintained Egg" exists. Keep genuine outcomes/odds, without inventing a base or redistribution.
   if preview.Eligible then for _,o in preview.Outcomes do table.insert(outcomes,{Name=o.Egg,Percent=o.Percent,Image=Egg.NormalPools[o.Egg].Icon}) end end
   resultTitle.Text="Possible Eggs"
   resultHint.Text=n<2 and "Select at least 2 Pets" or ""
   result:SetAttribute("UpgradeBaselineUnresolved",true)
  else
   resultTitle.Text="Merge Result"
   local preview=itemPreview()
   if committedItemId then
    local completed=Master.Get(committedItemId)
    if completed then table.insert(outcomes,{Name=completed.Rarity.." "..completed.Element.." "..completed.ItemType,Image=completed.Image,Rarity=completed.Rarity,ItemId=completed.ItemId,Percent=100}) end
   elseif preview then
    for _,o in ipairs(preview.Outcomes) do
     local completed=Master.Get(o.ItemId)
     table.insert(outcomes,{Name=completed.Rarity.." "..completed.Element.." "..completed.ItemType,Image=completed.Image,Rarity=completed.Rarity,ItemId=o.ItemId,Percent=o.Percent})
    end
   end
   resultHint.Text=#outcomes==0 and ("Select at least "..itemMinimum.." Items") or ""
  end
  local keys={tab};for _,o in outcomes do table.insert(keys,o.Name..":"..o.Image) end
  local key=table.concat(keys,"|")
  if candidateKey~=key then
   releaseCandidates()
   for i,o in outcomes do candidate(o.Name,o.Image,o.Percent,i,#outcomes,o.Rarity,o.ItemId) end
   candidateKey=key
  end
  for i,o in outcomes do
   local x=candidates[i]
   if x then x.Percent.Text=o.Percent and string.format("%.2f",o.Percent):gsub("0+$",""):gsub("%.$","").."%" or "";x:SetAttribute("Percent",o.Percent) end
  end
 end
 local function paintButton(x,enabled)
  x.Active=enabled;x.Interactable=enabled;x.Selectable=enabled;x.AutoButtonColor=enabled
  x.BackgroundColor3=enabled and Color3.new(1,1,1) or Color3.fromRGB(145,145,145)
  x.UIGradient.Enabled=enabled
  x.PriceTag.TextColor3=enabled and Color3.new(1,1,1) or Color3.fromRGB(204,204,204)
 end
 local function tintSelected(tile,on)
  local originals=cardTints[tile]
  if not originals then
   originals={};cardTints[tile]=originals
  end
   local main=tile.Main
   local objects={main}
   for _,x in main:GetDescendants() do table.insert(objects,x) end
   for _,x in objects do
    if x~=main.Checkmark and not originals[x] then
     if x:IsA("ImageLabel") or x:IsA("ViewportFrame") then originals[x]={"ImageColor3",x.ImageColor3}
     elseif x==main then originals[x]={"BackgroundColor3",x.BackgroundColor3} end
    end
   end
  for x,property in pairs(originals) do
   if x.Parent then x[property[1]]=on and property[2]:Lerp(Color3.new(0,0,0),.58) or property[2] end
  end
  tile:SetAttribute("MaterialDimmed",on)
 end
 render=function()
  local n=selectedCount()
  listTitle.Text=tab=="Pet" and "Your Pets" or "Your Items"
  creates.Text=tab=="Pet" and "Creates 1 Egg" or "Creates 1 Item"
  selectedLabel.Text=string.format("Selected: %d",n)
  selectedLabel:SetAttribute("SelectedCount",n)
  dropTitle.Text=n==0 and (tab=="Pet" and "Drag Pets Here" or "Drag Items Here") or string.format("%d %s Added",n,tab=="Pet" and "Pets" or "Items")
  dropHint.Text=tab=="Pet" and (n>0 and "Drag more Pets here" or "") or (n<itemMinimum and "Select at least "..itemMinimum.." Items" or "Drag more Items here")
  if dropStroke and not (drag and drag.Active) then dropStroke.Color=n>0 and Color3.fromRGB(94,255,0) or Color3.fromRGB(0,218,242) end
  drop.BackgroundColor3=n>0 and Color3.fromRGB(7,53,31) or shopSource.BackgroundColor3
  for _,entry in items do
   local tile=tiles[entry.Key]
   if tile then
    if tab=="Pet" then PetClient.setMaterialSelection(tile,entry.Name,selected(entry),false) end
    tile.Title.Visible=false;tile.Main.Checkmark.Visible=selected(entry)
    tintSelected(tile,selected(entry))
    local edge=tile.Main:FindFirstChildOfClass("UIStroke")
    if edge then
     local g=edge:FindFirstChildOfClass("UIGradient");if g then g.Enabled=not selected(entry) end
     edge.Color=selected(entry) and Color3.fromRGB(119,255,0) or tile:GetAttribute("OriginalEdgeColor")
     edge.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize;edge.Thickness=selected(entry) and 4 or 2
    end
    tile.Button.Active=selectable(entry)==true;tile.Button.Interactable=tile.Button.Active
   end
  end
  for name,button in pairs(tabs) do
   button.BackgroundColor3=name==tab and Color3.new(1,1,1) or Color3.fromRGB(64,162,80)
   button.PriceTag.TextColor3=name==tab and Color3.new(1,1,1) or Color3.fromRGB(214,235,211)
  end
  local preview=tab=="Item" and itemPreview()
  local ready=tab=="Item" and preview~=nil and itemFresh and not itemPending and itemState and not itemState.SavePending
  paintButton(merge,ready);paintButton(clear,tab=="Pet" or not itemPending)
  merge:SetAttribute("ExecutionEnabled",ready)
  merge.PriceTag.Text="Merge"
  if tab=="Pet" then status.Text="Merge disabled" elseif itemPending then status.Text="Merging…" end
  empty.Visible=#items==0
  empty.Text=tab=="Pet" and (petState and "No available normal Pets" or "Pet inventory is loading") or (itemState and "No mergeable Items" or "Item inventory is loading")
  updateResults(n);layout()
 end
 layout=function()
  local viewport=gui.AbsoluteSize
  local portrait=viewport.X<600 and viewport.Y>viewport.X
  local width,height=portrait and 700 or 1372,portrait and 1190 or 823
  if portrait and tab=="Item" then height+=82 end
  local s=math.min(1,math.max(1,viewport.X-(portrait and 16 or 32))/width,math.max(1,viewport.Y-24)/height)
  if viewport.X>=1000 then s=math.min(s,viewport.X*.82/width,viewport.Y*.875/height) end
  scale.Scale=s;shop.Size=UDim2.fromOffset(width,height);shop.AnchorPoint=Vector2.new(.5,.5);shop.Position=UDim2.fromScale(.5,.5)
  rect(top,0,0,width,portrait and 108 or 140)
  rect(top.MainShopIcon,28,-6,portrait and 118 or 172,portrait and 118 or 152)
  for _,name in {"ShopText1","ShopText2"} do rect(top[name],portrait and 154 or 214,8+(name=="ShopText2" and 4 or 0),portrait and 390 or 600,portrait and 90 or 126) end
  rect(top.Close,width-(portrait and 94 or 124),18,portrait and 76 or 108,portrait and 76 or 108)
  rect(body,0,0,width,height)
  local lx,ly,lw,lh=22,312,484,480
  local rx,ry,rw,rh=540,158,808,326
  local dy,dh,fy=495,184,692
  if portrait then lx,ly,lw,lh=18,248,664,390;rx,ry,rw,rh=18,654,664,218;dy,dh,fy=886,152,1056 end
  if portrait and tab=="Item" then rh+=82;dy+=82;fy+=82 end
  local tabsY=portrait and 124 or 160
  rect(tabs.Item,18,tabsY,portrait and 324 or 244,portrait and 62 or 82)
  rect(tabs.Pet,portrait and 358 or 276,tabsY,portrait and 324 or 228,portrait and 62 or 82)
  rect(listTitle,24,portrait and 198 or 247,lw,portrait and 44 or 56)
  rect(list,lx,ly,lw,lh);rect(empty,lx,ly,lw,lh)
  cell=(lw-24)/3
  for index,entry in items do
   local tile=tiles[entry.Key]
    if tile then
     rect(tile,((index-1)%3)*(cell+8),tab=="Item" and entry.ViewY or math.floor((index-1)/3)*(cell+8),cell,cell+(tab=="Item" and itemStarBand or 0))
     local stars=tile:FindFirstChild("RarityStars")
     if tab=="Item" and stars then rect(stars,6,cell+2,cell-12,itemStarBand-4);layoutItemStars(stars,cell-12,itemStarBand-4) end
    end
  end
  list.CanvasSize=UDim2.fromOffset(0,tab=="Item" and materialCanvasHeight or math.ceil(#items/3)*(cell+8))
  rect(result,rx,ry,rw,rh)
  rect(resultTitle,20,8,rw-40,portrait and 38 or 52)
  rect(resultHint,18,rh*.5,rw-36,portrait and 34 or 44)
  resultItems.Visible=tab=="Item"
  rect(resultItems,12,portrait and 52 or 66,rw-24,rh-(portrait and 60 or 74))
  local resultCount=#candidates;local columns=resultCount<=1 and 1 or math.min(3,resultCount)
  local resultWidth=(rw-40)/columns;local resultHeight=tab=="Item" and 240 or (portrait and math.min(178,rh-66) or 218)
  resultItems.CanvasSize=UDim2.fromOffset(0,math.ceil(resultCount/columns)*(resultHeight+10))
  for _,x in candidates do
   local index,total=x:GetAttribute("CandidateIndex"),x:GetAttribute("CandidateCount")
   local h=rh-(portrait and 52 or 66)
   local w=math.min(h,rw/math.max(1,total)-36)
   x.AnchorPoint=Vector2.new(.5,0);x.Size=UDim2.fromOffset(w,h)
   x.Position=UDim2.fromOffset(rw*.5+(index-(total+1)*.5)*math.min(rw/math.max(1,total),330),portrait and 50 or 64)
   if tab=="Item" then
    x.Size=UDim2.fromOffset(math.min(resultWidth-12,resultHeight),resultHeight)
    x.Position=UDim2.fromOffset(((index-1)%columns+.5)*resultWidth,math.floor((index-1)/columns)*(resultHeight+10))
    local pic=x:FindFirstChild("ActualImage");local surface=x:FindFirstChild("ResultCard")
    if pic then pic.Size=UDim2.fromOffset(x.Size.X.Offset,128) end
    if surface then surface.Size=UDim2.fromOffset(x.Size.X.Offset*.82,128) end
   end
   local nameplate=x:FindFirstChild("Name")
   if nameplate and x.Percent.Visible then
    nameplate.Size=UDim2.fromScale(tab=="Item" and (resultWidth-14)/math.max(x.Size.X.Offset,1) or 1,portrait and .24 or .15)
    nameplate.Position=UDim2.fromScale(.5,portrait and .84 or .87)
    x.Percent.Size=UDim2.fromScale(1,portrait and .16 or .13)
    local viewport=x:FindFirstChild("NormalEggViewport")
    if viewport then viewport.Size=UDim2.fromScale(1,portrait and .59 or .72) end
   end
   if tab=="Item" then
    local stars=x:FindFirstChild("RarityStars")
    local starWidth=math.min(x.Size.X.Offset-8,218)
    if stars then rect(stars,(x.Size.X.Offset-starWidth)/2,130,starWidth,42);layoutItemStars(stars,starWidth,42) end
    if nameplate then nameplate.AnchorPoint=Vector2.new(.5,0);nameplate.Position=UDim2.new(.5,0,0,174);nameplate.Size=UDim2.fromOffset(resultWidth-14,38) end
    x.Percent.AnchorPoint=Vector2.new(.5,0);x.Percent.Position=UDim2.new(.5,0,0,214);x.Percent.Size=UDim2.fromOffset(x.Size.X.Offset,24)
   end
  end
  rect(drop,rx,dy,rw,dh)
  local dashIndex=0
  for x=12,rw-24,30 do
   dashIndex+=1;dash(dashIndex,x,0,18,5)
   dashIndex+=1;dash(dashIndex,x,dh-5,18,5)
  end
  for y=14,dh-25,30 do
   dashIndex+=1;dash(dashIndex,0,y,5,18)
   dashIndex+=1;dash(dashIndex,rw-5,y,5,18)
  end
  for i,d in dashes do d.Visible=i<=dashIndex end
  rect(dropTitle,18,dh*.23,rw-36,dh*.35)
  rect(dropHint,18,dh*.65,rw-36,dh*.21)
  rect(selectedLabel,rx,fy+25,rw*.295,42)
  rect(clear,rx+rw*.31,fy+18,rw*.22,64)
  rect(merge,rx+rw*.57,fy,rw*.43,88)
  rect(creates,rx+rw*.57,fy+92,rw*.43,24)
  rect(status,rx,dy+dh+3,rw*.54,portrait and 22 or 24)
 end
 function view:SetPetState(state)
  petState=state
  for id in pairs(petSelected) do
   if not state or not state.Owned[id] or worn(id) or not Egg.mergePet(state.Owned[id]) then petSelected[id]=nil end
  end
  if drag and not selectable(drag.Entry) then endDrag() end
  if tab=="Pet" then refreshList(false);render() end
 end
 function view:SetItemState(state,fresh,pending,message)
  itemState=state;itemFresh=fresh==true;itemPending=pending==true
  if state and type(state.MinimumCount)=="number" then itemMinimum=state.MinimumCount end
  for key,entry in pairs(itemSelected) do if not state or not state.OwnedItems or (state.OwnedItems[entry.ItemId] or 0)<entry.Unit then itemSelected[key]=nil end end
  if tab=="Item" then status.Text=message or "";refreshList(false);render() end
 end
 function view:SelectTab(name)
  if name~="Pet" and name~="Item" then return end
  endDrag();petSelected={};itemSelected={};committedItemId=nil;status.Text=""
  releaseCandidates();tab=name;shop:SetAttribute("SelectedTab",tab)
  list.CanvasPosition=Vector2.zero;refreshList(true);render()
  if ctx.OnTab then ctx.OnTab(name) end
 end
 function view:Clear()
  if itemPending and tab=="Item" then return end
  endDrag();petSelected={};itemSelected={};committedItemId=nil;status.Text="";render()
 end
 function view:IsPet() return tab=="Pet" end
 function view:Show()
  shop.Visible=true;self:SelectTab("Item");layout()
 end
 function view:Hide()
  shop.Visible=false;endDrag();petSelected={};itemSelected={};committedItemId=nil
  releaseCards();releaseCandidates();listKey="";table.clear(blockedActivation)
 end
 function view:Destroy()
  if destroyed then return end;destroyed=true
  self:Hide();for _,c in connections do c:Disconnect() end;shop:Destroy()
 end
 connect(clear.Activated,function() if clear.Interactable then view:Clear() end end)
 function view:SubmitItem()
  -- The sole Item send hook. Pet is refused even if a caller forcibly enables its visual control.
  if tab~="Item" or not merge.Interactable or itemPending then return end
  if not itemFresh or not itemPreview() or itemState.SavePending then return end
  itemPending=true;itemFresh=false;render()
  ctx.OnMerge(itemMaterials())
 end
 function view:CompleteItem(id)
  self:Clear();committedItemId=id;if tab=="Item" then render() end
 end
 connect(merge.Activated,function() view:SubmitItem() end)
 connect(top.Close.Activated,function() view:Hide() end)
 for name,button in pairs(tabs) do connect(button.Activated,function() view:SelectTab(name) end) end
 connect(gui:GetPropertyChangedSignal("AbsoluteSize"),layout)
 connect(list:GetPropertyChangedSignal("CanvasPosition"),function()if tab=="Item" then refreshList(false);render() end end)
 connect(list:GetPropertyChangedSignal("AbsoluteSize"),function()if tab=="Item" then refreshList(false);render() end end)
 connect(shop:GetPropertyChangedSignal("Visible"),function() if not shop.Visible then endDrag();releaseCandidates() end end)
 view:SelectTab("Item")
 return view
end
-- END MERGE VIEW

local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local gui=player:WaitForChild("PlayerGui"):WaitForChild("StrengthGui")
if gui:GetAttribute("MergeShopMounted") then return end
local Master=require(RS.Config:WaitForChild("ItemMaster"))
local PetClient=require(player:WaitForChild("PlayerScripts"):WaitForChild("Services"):WaitForChild("PetClient"))
local Egg=require(RS.Modules:WaitForChild("Egg"))
local mergeRemote=RS.Remotes:WaitForChild("ItemMergeRequest")
local stateRemote=RS.Remotes:WaitForChild("ItemMergeState")
local state,pending,fetching,fresh=nil,false,false,false
local pendingRequest
local deliveredResults={}
local consumeResult
local revision=0
local refresh,view
local status=""
local errors={NotEnoughItems="Select at least 2 owned Items",DataSaving="Saving. Please wait.",DataNotLoaded="Loading…",CountOverflow="Item count limit reached",InventorySavePending="Waiting for save…",RateLimited="Please wait…",InvalidAmount="Invalid material amount",InvalidItemId="Select another item",MergeSessionChanged="Reopen Merge and try again",MergeSequenceChanged="Inventory changed. Please retry",InvalidReplay="Please make a new selection"}
local colors={}
-- Rarity surfaces are the existing purchased Pet visual palettes; no new art or stats.
local Config=require(RS.Modules.Config)
local Pet=require(RS.Modules.Pet)
for _,name in {"Common","Uncommon","Rare","Epic","Legendary"} do
 local rarity=Config.Rarities and Config.Rarities[name]
 if rarity and rarity.Colors then colors[name]=Pet.sequence(rarity.Colors) end
end
local ok,built=pcall(buildMergeShop,{
 gui=gui,RS=RS,PetClient=PetClient,Egg=Egg,Master=Master,ItemColors=colors,
 PurchasedInventory=game.StarterGui.ScreenGui.Menus.Inventory.Main,
 EggViewport=require(RS.Modules.LimitedPetViewport),Input=game:GetService("UserInputService"),GuiService=game:GetService("GuiService"),
 OnMerge=function(materials)
  if pending then return end
  if not state or not state.SessionToken or not state.NextSequence then return end
  pendingRequest={RequestId=game:GetService("HttpService"):GenerateGUID(false),SessionToken=state.SessionToken,Sequence=state.NextSequence,Materials=materials}
  pending=true;fresh=false;revision+=1;status=""
  view:SetItemState(state,fresh,pending,status)
  mergeRemote:FireServer(pendingRequest)
 end,
 OnTab=function(name)
  if not view then return end
  if name=="Item" then task.spawn(refresh) else task.spawn(PetClient.refresh) end
 end,
})
if not ok then
 local failed=gui:FindFirstChild("MergeShopPanel");if failed then failed:Destroy() end
 warn("[MergeShop] Purchased UI mount failed; no substitute created: "..tostring(built));return
end
view=built;gui:SetAttribute("MergeShopMounted",true)
local shop=view.Root
gui.InventoryPanel.Content.Merge.Visible=false
refresh=function()
 if fetching then return end;fetching=true
 local requestRevision=revision
 local success,response=pcall(function() return stateRemote:InvokeServer() end)
 fetching=false
 if requestRevision~=revision then task.defer(refresh);return end
 fresh=success and typeof(response)=="table" and response.Loaded==true
 if fresh then state=response;if status=="Checking connection…" then status="" end else status="Checking connection…" end
 if fresh and pendingRequest and state.LastResult and state.LastResult.RequestId==pendingRequest.RequestId then consumeResult(state.LastResult) end
 view:SetItemState(state,fresh,pending,status)
end
consumeResult=function(result)
 if typeof(result)~="table" or not pendingRequest or result.RequestId~=pendingRequest.RequestId then return end
 if result.Code=="InventorySavePending" or result.Code=="MergeInProgress" then
  status="Waiting for save…";return
 end
 local id=pendingRequest.RequestId;pendingRequest=nil;pending=false;revision+=1
 if result.MergeState and result.MergeState.Loaded then state=result.MergeState;fresh=true end
 status=result.Success and "Merge complete." or errors[result.Code] or "Merge failed. Please retry."
 view:SetItemState(state,fresh,pending,status)
 if result.Success and result.ResultItemId and not deliveredResults[id] then
  deliveredResults[id]=true;view:CompleteItem(result.ResultItemId)
 end
end
mergeRemote.OnClientEvent:Connect(function(result)
 consumeResult(result);view:SetItemState(state,fresh,pending,status);task.spawn(refresh)
end)
for _,name in {"ItemPurchaseRequest","ItemRobuxPurchaseRequest","ItemEquipRequest"} do
 RS.Remotes:WaitForChild(name).OnClientEvent:Connect(function()
  fresh=false;revision+=1
  if shop.Visible then view:SetItemState(state,fresh,pending,status);task.spawn(refresh) end
 end)
end
local function openShop()
 for _,name in {"InventoryPanel","ShopPanel","RebirthPanel"} do local x=gui:FindFirstChild(name);if x then x.Visible=false end end
 local skip=gui.Parent:FindFirstChild("StageSkipGui");if skip and skip:FindFirstChild("Panel") then skip.Panel.Visible=false end
 view:Show();task.spawn(refresh)
end
local inside=false
local elapsed,petPoll,itemPoll=0,0,0
local beat=RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;petPoll+=dt;itemPoll+=dt
 if shop.Visible and petPoll>=.5 then petPoll=0;view:SetPetState(PetClient.state()) end
 if shop.Visible and not view:IsPet() and itemPoll>=2 then itemPoll=0;task.spawn(refresh) end
 if elapsed<.1 then return end;elapsed=0
 local model=workspace:FindFirstChild("RestockShop")
 local area=model and model:FindFirstChild("Area")
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local now=false
 if area and area:IsA("BasePart") and root and (player:GetAttribute("CurrentWorld") or 1)==1 then
  local point=area.CFrame:PointToObjectSpace(root.Position);local half=area.Size/2
  if area:IsA("Part") and area.Shape==Enum.PartType.Cylinder then
   local radius=math.min(half.Y,half.Z);now=math.abs(point.X)<=half.X and point.Y*point.Y+point.Z*point.Z<=radius*radius
  else now=math.abs(point.X)<=half.X and math.abs(point.Y)<=half.Y and math.abs(point.Z)<=half.Z end
 end
 if now~=inside then inside=now;if now then openShop() else view:Hide() end end
end)
for _,name in {"InventoryPanel","ShopPanel","RebirthPanel"} do
 local x=gui:FindFirstChild(name)
 if x then x:GetPropertyChangedSignal("Visible"):Connect(function() if x.Visible then view:Hide() end end) end
end
script.Destroying:Connect(function() beat:Disconnect();view:Destroy();gui:SetAttribute("MergeShopMounted",nil) end)
