-- Interactive Merge presentation. Inventory identities and transactions stay with their authorities.
return function(ctx)
 local RS,gui=ctx.RS,ctx.gui
 local Items=require(RS.Config.ItemMergeConfig)
 local PetMerge=require(RS.Modules.PetMerge)
 local Ore=require(RS.Config.OreConfig)
 local OreMerge=require(RS.Modules.OreMerge)
 local Bells=require(RS.Config.DumbbellItemMaster)
 local Forge=require(RS.Modules.ForgeClient)
 local Master,PetClient,Egg=ctx.Master,ctx.PetClient,ctx.Egg
 local font=Font.fromEnum(Enum.Font.GothamBlack)
 local cyan=Color3.fromRGB(0,224,245)
 local connections,materialCards,inputCards,candidateCards={},{},{},{}
 local dead=false
 local function connect(signal,callback)
  local c=signal:Connect(callback);table.insert(connections,c);return c
 end
 local function new(class,name,parent,props)
  local x=Instance.new(class);x.Name=name
  for key,value in pairs(props or {}) do x[key]=value end
  x.Parent=parent;return x
 end
 local function round(x,radius) return new('UICorner','Corner',x,{CornerRadius=UDim.new(0,radius)}) end
 local function stroke(x,color,size)
  return new('UIStroke','Outline',x,{Color=color,Thickness=size,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
 end
 local function rect(x,a,b,w,h)
  x.AnchorPoint=Vector2.zero;x.Position=UDim2.fromOffset(a,b);x.Size=UDim2.fromOffset(w,h)
 end
 local function clearLayout(x)
  for _,v in x:GetChildren() do
   if v:IsA('UIGridStyleLayout') or v:IsA('UIAspectRatioConstraint') or v:IsA('UISizeConstraint') or v:IsA('UIScale') or v:IsA('UIPadding') then v:Destroy() end
  end
 end
 local function clone(source,name,parent)
  local x=source:Clone();x.Name=name
  for _,v in x:GetDescendants() do
   if v:IsA('LuaSourceContainer') then v:Destroy() elseif v:IsA('GuiObject') then v.AutoLocalize=false end
  end
  if x:IsA('GuiObject') then x.AutoLocalize=false end
  x.Parent=parent;return x
 end
 local function label(name,parent,value,size,z)
  local x=new('TextLabel',name,parent,{BackgroundTransparency=1,BorderSizePixel=0,Text=value,
   FontFace=font,TextColor3=Color3.new(1,1,1),TextStrokeColor3=Color3.new(),TextStrokeTransparency=0,
   TextScaled=true,TextWrapped=true,TextSize=size or 36,AutoLocalize=false,ZIndex=z or 238})
  new('UITextSizeConstraint','TextLimit',x,{MinTextSize=1,MaxTextSize=size or 36})
  return x
 end
 local function surface(name,parent,color,z)
  local x=new('Frame',name,parent,{BorderSizePixel=0,BackgroundColor3=color,ZIndex=z or 214})
  round(x,15);return x
 end
 local source=gui:WaitForChild('ShopPanel')
 local donor=source.MainScrollingFrame.Holder.Card01_SecretPack.Owned
 local host=gui
 if gui:IsA('ScreenGui') then
  assert(not gui.Parent:FindFirstChild('MergeShopGui'),'Merge view already mounted')
  host=new('ScreenGui','MergeShopGui',gui.Parent,{ResetOnSpawn=false,DisplayOrder=40,
   IgnoreGuiInset=gui.IgnoreGuiInset,ScreenInsets=gui.ScreenInsets,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
  local function hatchOrder()
   host.DisplayOrder=gui.Parent:FindFirstChild('HatchGui') and 15 or 40
  end
  connect(gui.Parent.ChildAdded,function(x)if x.Name=='HatchGui' then hatchOrder() end end)
  connect(gui.Parent.ChildRemoved,function(x)if x.Name=='HatchGui' then hatchOrder() end end)
  hatchOrder()
 end
 local shop=surface('MergeShopPanel',host,Color3.fromRGB(10,23,28),210)
 shop.BackgroundTransparency=.1;shop.Visible=false;shop.ClipsDescendants=false
 stroke(shop,Color3.new(),7);shop:SetAttribute('ReferenceDesignSize',Vector2.new(1372,900))
 local fit=new('UIScale','MergeFit',shop)
 local top=clone(source.Top,'Top',shop);clearLayout(top)
 top.ZIndex=220
 for _,v in top:GetDescendants() do if v:IsA('GuiObject') then v.ZIndex=222 end end
 top.UIGradient.Color=ColorSequence.new(Color3.fromRGB(255,207,0),Color3.fromRGB(255,247,0))
 top.StudPattern.TileSize=UDim2.fromOffset(180,180)
 for _,name in {'ShopText1','ShopText2'} do
  local t=top[name];clearLayout(t);t.Text='Merge';t.FontFace=font;t.TextScaled=true;t.TextWrapped=true
  t.TextXAlignment=Enum.TextXAlignment.Left;t.ZIndex=name=='ShopText1' and 227 or 225
 end
 top.Close.Text='';top.Close.TextLabel.Text='×';top.Close.ZIndex=242;top.Close.TextLabel.ZIndex=244
 local body=new('Frame','Body',shop,{BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=211})
 local function button(name,parent,caption,style)
  local x=clone(donor,name,parent);clearLayout(x)
  x.Visible=true;x.Text='';x.ZIndex=240;x.Active=true;x.Interactable=true;x.AutoButtonColor=true
  for _,v in x:GetDescendants() do if v:IsA('GuiObject') then v.ZIndex=v:IsA('TextLabel') and 244 or 241 end end
  x.PriceTag.Text=caption;x.PriceTag.FontFace=font;x.PriceTag.TextScaled=true;x.PriceTag.TextWrapped=true
  x.PriceTag.TextColor3=Color3.new(1,1,1);x.PriceTag.TextStrokeTransparency=0;x.PriceTag.TextStrokeColor3=Color3.new()
  x.PriceTag.AnchorPoint=Vector2.new(.5,.5);x.PriceTag.Position=UDim2.fromScale(.5,.5);x.PriceTag.Size=UDim2.fromScale(.93,.82)
  x.StudPattern.TileSize=UDim2.fromOffset(180,180)
  if style=='red' then x.UIGradient.Color=ColorSequence.new(Color3.fromRGB(255,33,50),Color3.fromRGB(255,112,118))
  elseif style=='yellow' then x.UIGradient.Color=ColorSequence.new(Color3.fromRGB(255,204,0),Color3.fromRGB(255,247,20))
  else x.UIGradient.Color=ColorSequence.new(Color3.fromRGB(27,240,0),Color3.fromRGB(164,255,19)) end
  return x
 end
 local tabs={Item=button('Item',body,'Item'),Pet=button('Pet',body,'Pet'),Ore=button('Ore',body,'Ore')}
 local title=label('ListTitle',body,'Your Items',44);title.TextXAlignment=Enum.TextXAlignment.Left
 local sell=button('SellMode',body,'Sell','yellow')
 local function scroll(name,parent,z)
  return new('ScrollingFrame',name,parent,{BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),
   AutomaticCanvasSize=Enum.AutomaticSize.None,ScrollingDirection=Enum.ScrollingDirection.Y,
   ScrollBarThickness=12,ScrollBarImageColor3=Color3.fromRGB(156,170,178),ClipsDescendants=true,ZIndex=z or 220})
 end
 local list=scroll('Materials',body)
 local empty=label('Empty',list,'',30)
 local result=surface('Result',body,Color3.fromRGB(12,29,40));result.BackgroundTransparency=.2
 stroke(result,Color3.fromRGB(66,110,128),2)
 local resultTitle=label('ResultTitle',result,'Merge Result',44);resultTitle.TextXAlignment=Enum.TextXAlignment.Left
 local resultHint=label('ResultHint',result,'',38)
 local resultList=scroll('ResultItems',result,222)
 local drop=surface('DropArea',body,Color3.fromRGB(6,17,21));drop.BackgroundTransparency=.05
 local stud=clone(donor.StudPattern,'StudPattern',drop);stud.Size=UDim2.fromScale(1,1);stud.Position=UDim2.new();stud.AnchorPoint=Vector2.zero
 stud.ImageTransparency=.94;stud.ZIndex=215;stud.Active=false
 local dashes={}
 local inputList=scroll('Inputs',drop,220);inputList.ScrollingDirection=Enum.ScrollingDirection.X;inputList.ScrollBarThickness=6
 local dropTitle=label('DropTitle',drop,'Drag Items Here',52)
 local dropHint=label('DropHint',drop,'Select at least 2 Items',32)
 local totalLabel=label('Total',drop,'Total: 0 pt',46)
 local selectedLabel=label('Selected',body,'Selected: 0',36);selectedLabel.TextXAlignment=Enum.TextXAlignment.Left
 local clear=button('Clear',body,'Clear','red')
 local merge=button('Merge',body,'Merge')
 local creates=label('Creates',body,'Creates 1 Item',24)
 local status=label('Status',body,'',23);status.TextXAlignment=Enum.TextXAlignment.Left
 local saleIcon=new('ImageLabel','SaleIcon',result,{BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,ZIndex=225})
 local saleTitle=label('SaleTitle',result,'',32)
 local quantity=new('TextBox','SaleQuantity',result,{Text='0',FontFace=font,TextScaled=true,TextColor3=Color3.new(1,1,1),
  BackgroundColor3=Color3.fromRGB(24,42,50),ClearTextOnFocus=false,ZIndex=245});round(quantity,10)
 local minus=button('Less',result,'−','red');local plus=button('More',result,'+');local max=button('Max',result,'Max')
 local tab='Item'
 local petState,itemState,oreState=nil,nil,Forge.State
 local itemFresh,itemPending,petPending=false,false,false
 local itemSelected,petSelected,oreSelected,oreSale={},{},{},{}
 local completedItem,completedBell,activeOre=nil,nil,nil
 local sellMode=false
 local groups,byKey={},{}
 local render,layout,add,remove
 local view={Root=shop,Drop=drop,Tabs=tabs,List=list,Merge=merge,ClearButton=clear}
 local drag,blocked=nil,{}
 local function unlocked() return itemState and itemState.World2Unlocked==true end
 local function oreSelection() return sellMode and oreSale or oreSelected end
 local function petIds()
  local ids={};for id in pairs(petSelected) do table.insert(ids,id) end;table.sort(ids);return ids
 end
 local function itemPreview() return Items.Evaluate(itemSelected,itemState and itemState.OwnedItems or {},unlocked()) end
 local function petPreview() return PetMerge.Evaluate(petState,petIds()) end
 local function selectedCount()
  local n=0
  if tab=='Pet' then for _ in pairs(petSelected) do n+=1 end
  else for _,count in pairs(tab=='Ore' and oreSelection() or itemSelected) do n+=count end end
  return n
 end
 local function groupSelected(entry)
  if tab=='Item' then return itemSelected[entry.ItemId] or 0 end
  if tab=='Ore' then return oreSelection()[entry.Id] or 0 end
  local n=0;for _,id in entry.Ids do if petSelected[id] then n+=1 end end;return n
 end
 local function available(entry)
  if tab=='Item' then return not itemPending and (itemSelected[entry.ItemId] or 0)<entry.Count end
  if tab=='Ore' then return not Forge.IsPending() and groupSelected(entry)<entry.Count and (sellMode or selectedCount()<5) end
  return not petPending and not PetClient.busy() and groupSelected(entry)<#entry.Ids
 end
 local function rebuildGroups()
  groups={}
  if tab=='Item' then groups=Items.Groups(itemState and itemState.OwnedItems,unlocked())
  elseif tab=='Pet' then groups=PetMerge.Groups(petState)
  else for _,ore in ipairs(Ore.GetAvailable()) do
   local count=oreState and oreState.Ores and oreState.Ores[ore.Id] or 0
   if count>0 then table.insert(groups,{Key=ore.Id,Id=ore.Id,Name=ore.Name,Count=count,Points=ore.Points}) end
  end end
  byKey={};for _,entry in groups do byKey[entry.Key]=entry end
 end
 local function rankBand(parent,item)
  local rank=Items.GetRank(item)
  local band=surface('RarityStars',parent,Color3.fromRGB(0,43,92),230);band.Corner.CornerRadius=UDim.new(0,5)
  band:SetAttribute('Rank',rank)
  if rank>5 then
   local star=new('ImageLabel','BlueStar',band,{BackgroundTransparency=1,Image='rbxassetid://126441080731699',
    ImageColor3=Color3.fromRGB(65,229,255),ScaleType=Enum.ScaleType.Fit,Position=UDim2.fromScale(.18,.06),Size=UDim2.fromScale(.29,.88),ZIndex=232})
   local number=label('RankNumber',band,tostring(rank),46,233);number.Position=UDim2.fromScale(.48,0);number.Size=UDim2.fromScale(.38,1)
  else
   for i=1,5 do new('ImageLabel','Star'..i,band,{BackgroundTransparency=1,Image=i<=rank and 'rbxassetid://76134658177553' or 'rbxassetid://126441080731699',
    ScaleType=Enum.ScaleType.Fit,Position=UDim2.fromScale(.025+(i-1)*.19,.06),Size=UDim2.fromScale(.19,.88),ZIndex=232}) end
  end
  return band
 end
 local function pointsBadge(parent,points)
  local badge=surface('Points',parent,Color3.fromRGB(8,17,20),234);badge.BackgroundTransparency=.08;badge.Corner.CornerRadius=UDim.new(0,9)
  badge.Position=UDim2.fromScale(.025,.03);badge.Size=UDim2.fromScale(.61,.22)
  local number=label('Value',badge,tostring(points),38,235);number.Position=UDim2.fromScale(.03,0);number.Size=UDim2.fromScale(.73,1)
  local unit=label('Unit',badge,'pt',22,235);unit.Position=UDim2.fromScale(.75,.23);unit.Size=UDim2.fromScale(.23,.67)
  return badge
 end
 local function makeCard(entry,kind,parent,onClick,input)
  local tile,cleanup
  if kind=='Pet' then tile,cleanup=PetClient.createMaterialTile(entry.Ids[1] or entry.Key,entry.Name,1,parent,onClick)
  else
   tile=clone(RS.Assets.Templates.PetInventory,entry.Key,parent)
   local connection=tile.Button.Activated:Connect(onClick)
   cleanup=function() connection:Disconnect();tile:Destroy() end
  end
  assert(tile,'Merge material visual unavailable')
  tile.Name=entry.Key;tile.Visible=true;clearLayout(tile);tile.BackgroundTransparency=1;tile.ClipsDescendants=false;tile.ZIndex=222
  tile.Main.AnchorPoint=Vector2.zero;tile.Main.Position=UDim2.new();tile.Main.Size=UDim2.fromScale(1,1);tile.Main.ZIndex=224
  tile.Stroke.Visible=false;tile.Title.Visible=false;tile.Main.Checkmark.Visible=false
  local original=tile.Main:FindFirstChildOfClass('UIStroke');if original then original.Enabled=false end
  local border=stroke(tile.Main,Color3.fromRGB(12,19,23),2);border.Name='SelectionBorder'
  local icon=tile.Main.Icon;icon.ZIndex=226;icon.AnchorPoint=Vector2.zero;icon.ScaleType=Enum.ScaleType.Fit
  icon.Position=UDim2.fromScale(.025,kind=='Item' and .015 or .25);icon.Size=UDim2.fromScale(.95,kind=='Item' and .73 or .65)
  local inherited=icon:FindFirstChild('RarityStars');if inherited then inherited:Destroy() end
  tile.Button.AnchorPoint=Vector2.zero;tile.Button.Position=UDim2.new();tile.Button.Size=UDim2.fromScale(1,1)
  tile.Button.ZIndex=242;tile.Button.Text='';tile.Button.BackgroundTransparency=1;tile.Button.AutoButtonColor=false
  if kind=='Item' or kind=='Ore' then
   tile.Main.BackgroundColor3=Color3.new(1,1,1)
   tile.Main.UIGradient.Color=ColorSequence.new(Color3.fromRGB(250,250,250),Color3.fromRGB(162,172,181));tile.Main.UIGradient.Rotation=90
   icon.Image=kind=='Item' and Master.Get(entry.ItemId).Image or Ore.Get(entry.Id).Image
  end
  if kind=='Item' then local band=rankBand(tile,Master.Get(entry.ItemId));band.Position=UDim2.fromScale(0,.75);band.Size=UDim2.fromScale(1,.25)
  else pointsBadge(tile,entry.Points) end
  local owned=label('OwnedCount',tile,'×'..entry.Count,38,237)
  owned.Position=UDim2.fromScale(.50,kind=='Item' and .53 or .75);owned.Size=UDim2.fromScale(.47,.23);owned.TextXAlignment=Enum.TextXAlignment.Right;owned.Visible=not input
  local badge=surface('SelectedCount',tile,Color3.fromRGB(0,139,229),238);badge.Corner.CornerRadius=UDim.new(1,0)
  badge.AnchorPoint=Vector2.new(1,0);badge.Position=UDim2.fromScale(1.015,-.015);badge.Size=UDim2.fromScale(.29,.29);stroke(badge,cyan,5)
  local countLabel=label('Value',badge,'',36,239);countLabel.Size=UDim2.fromScale(1,1)
  local record={Root=tile,Destroy=cleanup,Entry=entry}
  function record:Update(nextEntry,n,enabled)
   self.Entry=nextEntry;owned.Text='×'..tostring(nextEntry.Count or 0)
   badge.Visible=n>0;countLabel.Text=tostring(n)
   border.Color=n>0 and cyan or Color3.fromRGB(12,19,23);border.Thickness=n>0 and 4 or 2
   tile.Button.Active=enabled;tile.Button.Interactable=enabled
   tile:SetAttribute('OwnedCount',nextEntry.Count or 0);tile:SetAttribute('SelectedCount',n)
   tile:SetAttribute('ItemId',nextEntry.ItemId);tile:SetAttribute('Rank',nextEntry.Rank);tile:SetAttribute('Points',nextEntry.Points)
  end
  return record
 end
 local function destroyCards(cards)
  for key,card in pairs(cards) do card.Destroy();cards[key]=nil end
 end
 local function reconcile(cards,parent,entries,input)
  local kept={}
  for index,entry in entries do
   local key=entry.Key;kept[key]=true
   local card=cards[key]
   if not card then
    card=makeCard(entry,tab,parent,function()
     if input then view:RemoveMaterial(key) else view:ActivateMaterial(key) end
    end,input);cards[key]=card
   end
   card.Root.LayoutOrder=index;card:Update(entry,input and (entry.InputCount or 1) or groupSelected(entry),input or available(entry))
  end
  for key,card in pairs(cards) do if not kept[key] then card.Destroy();cards[key]=nil end end
 end
 local function selectedEntries()
  local rows={}
  for _,entry in groups do
   local n=groupSelected(entry)
   if n>0 then
    if tab=='Ore' and not sellMode then
     for i=1,n do local row=table.clone(entry);row.Key=entry.Key..':'..i;row.SourceKey=entry.Key;row.InputCount=1;table.insert(rows,row) end
    else local row=table.clone(entry);row.InputCount=n;table.insert(rows,row) end
   end
  end
  return rows
 end
 local function endDrag()
  if drag and drag.Ghost then drag.Ghost:Destroy() end
  drag=nil;list.ScrollingEnabled=true
 end
 local function insideDrop(position)
  local a,b=drop.AbsolutePosition,drop.AbsolutePosition+drop.AbsoluteSize
  return position.X>=a.X and position.X<=b.X and position.Y>=a.Y and position.Y<=b.Y
 end
 local function point(input)
  -- InputObject.Position already uses the same inset-relative coordinates as AbsolutePosition.
  return Vector2.new(input.Position.X,input.Position.Y)
 end
 function view:PressMaterial(key,position,touch,input)
  if not shop.Visible or not byKey[key] or not available(byKey[key]) then return end
  endDrag();drag={Key=key,Start=position,Last=position,Touch=touch,Input=input,Started=os.clock()}
 end
 function view:MovePointer(position)
  if not drag then return end
  drag.Last=position;local delta=position-drag.Start
  if drag.Touch and not drag.Active and math.abs(delta.Y)>10 and math.abs(delta.Y)>math.abs(delta.X)*1.2 and os.clock()-drag.Start<.2 then drag.Scrolling=true;return end
  if drag.Scrolling then return end
  if not drag.Active and delta.Magnitude>10 then
   local card=materialCards[drag.Key];if not card then endDrag();return end
   drag.Active=true;list.ScrollingEnabled=false
   local ghost=clone(card.Root,'DraggingMaterial',shop);clearLayout(ghost)
   ghost.Size=UDim2.fromOffset(card.Root.Size.X.Offset,card.Root.Size.Y.Offset);ghost.AnchorPoint=Vector2.new(.5,.5);ghost.Rotation=-7
   for _,v in ghost:GetDescendants() do if v:IsA('GuiObject') then v.ZIndex+=60 end;if v:IsA('GuiButton') then v.Interactable=false;v.Active=false end end
   ghost.ZIndex=282;drag.Ghost=ghost
  end
  if drag.Ghost then
   local p=(position-shop.AbsolutePosition)/math.max(fit.Scale,.01);drag.Ghost.Position=UDim2.fromOffset(p.X,p.Y)
  end
 end
 function view:ReleasePointer(position)
  if not drag then return end
  local key,active,scrolling=drag.Key,drag.Active,drag.Scrolling
  if active or scrolling then blocked[key]=os.clock()+.5 end
  local addIt=active and insideDrop(position);endDrag()
  if addIt then add(key) end
 end
 add=function(key)
  local entry=byKey[key];if not entry or not available(entry) then return end
  if tab=='Item' then itemSelected[entry.ItemId]=(itemSelected[entry.ItemId] or 0)+1;completedItem=nil
  elseif tab=='Ore' then local selected=oreSelection();selected[entry.Id]=(selected[entry.Id] or 0)+1;activeOre=entry.Id;completedBell=nil
  else for _,id in entry.Ids do if not petSelected[id] then petSelected[id]=true;break end end end
  status.Text='';render()
 end
 remove=function(key)
  if tab=='Item' then
   if itemPending then return end
   local n=itemSelected[key] or 0;itemSelected[key]=n>1 and n-1 or nil;completedItem=nil
  elseif tab=='Ore' then
   if Forge.IsPending() then return end
   local id=key:match('^(.-):%d+$') or key;local selected=oreSelection();local n=selected[id] or 0;selected[id]=n>1 and n-1 or nil;completedBell=nil
  else
   if petPending then return end
   local group=byKey[key]
   if group then for i=#group.Ids,1,-1 do local id=group.Ids[i];if petSelected[id] then petSelected[id]=nil;break end end end
  end
  render()
 end
 function view:ActivateMaterial(key)
  if not shop.Visible or os.clock()<(blocked[key] or 0) or drag and (drag.Active or drag.Scrolling) then return end
  add(key)
 end
 function view:RemoveMaterial(key) remove(key) end
 local function candidate(outcome,index)
  local x=new('Frame','Candidate_'..index,resultList,{BackgroundTransparency=1,ZIndex=223})
  local card=surface('Card',x,Color3.fromRGB(242,244,246),224);card.Corner.CornerRadius=UDim.new(0,8)
  new('UIGradient','Shading',card,{Color=ColorSequence.new(Color3.fromRGB(255,255,255),Color3.fromRGB(173,181,190)),Rotation=90})
  local cleanup
  if outcome.Egg then
   card.BackgroundTransparency=1
   local ok,dispose,viewport=pcall(ctx.EggViewport.mountEgg,card,outcome.Egg)
   if ok and dispose then cleanup=dispose;viewport.Size=UDim2.fromScale(.94,.94);viewport.Position=UDim2.fromScale(.03,.03);viewport.ZIndex=226
   else
    new('ImageLabel','Icon',card,{BackgroundTransparency=1,Image=outcome.Image or '',Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Fit,ZIndex=226})
   end
  else
   new('ImageLabel','Icon',card,{BackgroundTransparency=1,Image=outcome.Image,Position=UDim2.fromScale(.03,.03),
    Size=UDim2.fromScale(.94,outcome.ItemId and .72 or .88),ScaleType=Enum.ScaleType.Fit,ZIndex=226})
  end
  if outcome.ItemId then
   local band=rankBand(card,Master.Get(outcome.ItemId));band.Position=UDim2.fromScale(0,.75);band.Size=UDim2.fromScale(1,.25)
  elseif outcome.Grade then
   local grade=label('Number',card,tostring(outcome.Grade),46,233);grade.Position=UDim2.fromScale(.03,.02);grade.Size=UDim2.fromScale(.35,.23);grade.TextXAlignment=Enum.TextXAlignment.Left
   local strength=label('Strength',card,'+'..outcome.Strength,46,233);strength.TextColor3=Color3.fromRGB(145,255,0)
   strength.Position=UDim2.fromScale(.32,.75);strength.Size=UDim2.fromScale(.65,.23);strength.TextXAlignment=Enum.TextXAlignment.Right
  end
  local percent=label('Percent',x,'',36,238)
  return {Root=x,Card=card,Percent=percent,Destroy=function()if cleanup then cleanup() end;x:Destroy()end}
 end
 local candidateSignature=''
 local function updateCandidates()
  local rows={};local hint=''
  if tab=='Item' then
   local preview,reason=itemPreview()
   if completedItem then local item=Master.Get(completedItem);rows={{ItemId=completedItem,Image=item.Image,Percent=100}}
   elseif preview then for _,o in preview.Outcomes do table.insert(rows,{ItemId=o.ItemId,Image=Master.Get(o.ItemId).Image,Percent=o.Percent}) end
   else hint=reason=='MixedWorldMaterials' and 'Use materials from one World' or 'Select at least 2 Items' end
  elseif tab=='Pet' then
   local preview=petPreview()
   if preview then for _,o in preview.Outcomes do table.insert(rows,{Egg=o.Egg,Image=Egg.NormalPools[o.Egg].Icon,Percent=o.Percent}) end
   else hint='Select at least 2 Pets' end
  elseif not sellMode then
   local preview=OreMerge.Evaluate(oreSelected,oreState and oreState.Ores)
   if completedBell then preview={Outcomes={{Id=completedBell,Probability=1}}} end
   if preview then for _,o in preview.Outcomes do local bell=Bells.Get(o.Id);table.insert(rows,{Id=o.Id,Image=bell.Image,Grade=bell.Grade,Strength=bell.StrengthBonus,Percent=o.Probability*100}) end
   else hint='Select 1–5 Ores' end
  end
  local keys={tab,tostring(sellMode)};for _,o in rows do table.insert(keys,o.ItemId or o.Id or o.Egg) end
  local signature=table.concat(keys,'|')
  if signature~=candidateSignature then
   destroyCards(candidateCards)
   for i,o in rows do candidateCards[i]=candidate(o,i) end
   candidateSignature=signature
  end
  for i,o in rows do
   local c=candidateCards[i];c.Percent.Text=string.format('%.2f',o.Percent):gsub('0+$',''):gsub('%.$','')..'%'
   c.Root:SetAttribute('Percent',o.Percent);c.Root:SetAttribute('ItemId',o.ItemId);c.Root:SetAttribute('ResultId',o.Id or o.Egg)
  end
  resultHint.Text=hint;resultHint.Visible=#rows==0 and not sellMode
 end
 local function enabled(button,value)
  button.Active=value;button.Interactable=value;button.AutoButtonColor=value
  button.UIGradient.Enabled=value;button.BackgroundColor3=value and Color3.new(1,1,1) or Color3.fromRGB(157,160,158)
 end
 render=function()
  if dead then return end
  rebuildGroups()
  local n=selectedCount()
  title.Text=tab=='Item' and 'Your Items' or tab=='Pet' and 'Your Pets' or 'Your Ores'
  resultTitle.Text=tab=='Pet' and 'Possible Eggs' or sellMode and 'Sell Ores' or 'Merge Result'
  selectedLabel.Text='Selected: '..n..(tab=='Ore' and not sellMode and '/5' or '');selectedLabel:SetAttribute('SelectedCount',n)
  creates.Text=tab=='Pet' and 'Creates 1 Egg' or tab=='Ore' and (sellMode and '' or 'Creates 1 Dumbbell') or 'Creates 1 Item'
  sell.Visible=tab=='Ore';sell.PriceTag.Text=sellMode and 'Back' or 'Sell'
  reconcile(materialCards,list,groups,false)
  local inputs=selectedEntries();reconcile(inputCards,inputList,sellMode and {} or inputs,true)
  inputList.Visible=n>0 and not sellMode
  dropTitle.Visible=n==0 or sellMode;dropHint.Visible=n==0 and tab=='Item' and not sellMode
  dropTitle.Text=sellMode and 'Select quantities above' or tab=='Pet' and 'Drag Pets Here' or tab=='Ore' and 'Drag Ores Here' or 'Drag Items Here'
  totalLabel.Visible=tab=='Ore' or tab=='Pet' and n>0
  if tab=='Ore' then
   local selection=OreMerge.Selection(oreSelection(),oreState and oreState.Ores,sellMode)
   totalLabel.Text='Total: '..tostring(selection and selection.Total or 0)..(sellMode and ' Win' or ' pt')
  elseif tab=='Pet' then
   local points=0;for id in pairs(petSelected) do local info=petState and Egg.mergePet(petState.Owned[id]);if info then points+=info.Points end end
   totalLabel.Text='Total: '..points..' pt'
  end
  for name,b in pairs(tabs) do
   b.BackgroundColor3=name==tab and Color3.new(1,1,1) or Color3.fromRGB(75,163,68)
   b.PriceTag.TextColor3=Color3.new(1,1,1)
  end
  local ready=tab=='Item' and itemFresh and not itemPending and itemState and not itemState.SavePending and itemPreview()~=nil
  if tab=='Pet' then ready=not petPending and not PetClient.busy() and petPreview()~=nil end
  if tab=='Ore' then ready=oreState and not oreState.Pending and not Forge.IsPending() and OreMerge.Selection(oreSelection(),oreState.Ores,sellMode)~=nil end
  enabled(merge,ready==true);merge:SetAttribute('ExecutionEnabled',ready==true);merge.PriceTag.Text=sellMode and 'Sell' or 'Merge'
  enabled(clear,not itemPending and not petPending and not Forge.IsPending())
  empty.Visible=#groups==0;empty.Text=(tab=='Item' and not itemState or tab=='Pet' and not petState or tab=='Ore' and not oreState) and 'Loading…' or 'No materials'
  for _,control in {saleIcon,saleTitle,quantity,minus,plus,max} do control.Visible=sellMode end
  if sellMode then
   local ore=activeOre and Ore.Get(activeOre);saleIcon.Image=ore and ore.Image or '';saleTitle.Text=ore and ore.Name or 'Select Ores'
   if not quantity:IsFocused() then quantity.Text=tostring(activeOre and oreSale[activeOre] or 0) end
   for _,b in {minus,plus,max} do enabled(b,ore~=nil and not Forge.IsPending()) end
  end
  if shop.Visible then updateCandidates() end
  layout()
 end
 local layingOut=false
 layout=function()
  if dead or layingOut then return end;layingOut=true
  local viewport=gui.AbsoluteSize
  local narrow=viewport.X<600 and viewport.Y>viewport.X
  local w,h=narrow and 700 or 1372,narrow and 1190 or 900
  local s=math.min(1,math.max(1,viewport.X-24)/w,math.max(1,viewport.Y-24)/h)
  fit.Scale=s;shop.Size=UDim2.fromOffset(w,h);shop.AnchorPoint=Vector2.new(.5,.5);shop.Position=UDim2.fromScale(.5,.5)
  rect(top,0,0,w,narrow and 108 or 148)
  rect(top.MainShopIcon,26,2,narrow and 110 or 164,narrow and 100 or 140)
  for _,name in {'ShopText1','ShopText2'} do rect(top[name],narrow and 150 or 212,10+(name=='ShopText2' and 4 or 0),narrow and 380 or 620,narrow and 86 or 125) end
  rect(top.Close,w-(narrow and 94 or 126),18,narrow and 76 or 108,narrow and 76 or 108)
  local lx,ly,lw,lh=22,284,520,592
  local rx,ry,rw,rh=566,164,784,398
  local dy,dh,fy=576,202,796
  if narrow then lx,ly,lw,lh=18,240,664,390;rx,ry,rw,rh=18,646,664,232;dy,dh,fy=892,178,1090 end
  local ty=narrow and 122 or 164;local tw=(lw-16)/3
  for i,name in {'Item','Pet','Ore'} do rect(tabs[name],lx+(i-1)*(tw+8),ty,tw,narrow and 62 or 68) end
  rect(title,lx,narrow and 194 or 236,lw-145,44);rect(sell,lx+lw-138,narrow and 194 or 236,138,44)
  if tab~='Ore' then title.Size=UDim2.fromOffset(lw,44) end
  rect(list,lx,ly,lw,lh);rect(empty,0,40,lw-12,50)
  local cell=(lw-(tab=='Item' and 52 or 28))/3
  local height=tab=='Item' and cell*.92 or cell
  local gap=tab=='Item' and 6 or 8
  for i,entry in groups do local card=materialCards[entry.Key];if card then rect(card.Root,((i-1)%3)*(cell+gap),math.floor((i-1)/3)*(height+gap),cell,height) end end
  list.CanvasSize=UDim2.fromOffset(0,math.ceil(#groups/3)*(height+gap))
  rect(result,rx,ry,rw,rh);rect(resultTitle,18,10,rw-36,50);rect(resultHint,14,rh*.43,rw-28,58)
  rect(resultList,14,70,rw-28,rh-82)
  local count=#candidateCards;local cols=math.min(3,math.max(1,count));local width=(rw-36)/cols
  local candidateH=math.min(rh-86,300);local cardSide=math.min(width-20,candidateH-40)
  for i,card in candidateCards do
   rect(card.Root,((i-1)%cols)*width+(width-cardSide)/2,math.floor((i-1)/cols)*(candidateH+12),cardSide,candidateH)
   rect(card.Card,0,0,cardSide,cardSide);rect(card.Percent,0,cardSide+1,cardSide,math.max(26,candidateH-cardSide))
  end
  resultList.CanvasSize=UDim2.fromOffset(0,math.ceil(count/cols)*(candidateH+12))
  rect(drop,rx,dy,rw,dh)
  local inputs=selectedEntries();local lower=totalLabel.Visible and 48 or 10
  rect(inputList,12,12,rw-24,dh-lower-16)
  local inputSide=math.min(dh-lower-22,(rw-48)/5)
  for i,entry in inputs do local card=inputCards[entry.Key];if card then rect(card.Root,(i-1)*(inputSide+8),2,inputSide,inputSide) end end
  inputList.CanvasSize=UDim2.fromOffset(#inputs*(inputSide+8),0)
  rect(totalLabel,12,dh-46,rw-24,42);rect(dropTitle,16,dh*.24,rw-32,dh*.36);rect(dropHint,16,dh*.65,rw-32,dh*.23)
  local k=0
  local function dash(a,b,c,d)
   k+=1;local line=dashes[k]
   if not line then line=surface('Dash'..k,drop,cyan,218);line.Corner.CornerRadius=UDim.new(1,0);dashes[k]=line end
   rect(line,a,b,c,d);line.Visible=true
  end
  for x=12,rw-24,32 do dash(x,0,19,5);dash(x,dh-5,19,5) end
  for y=14,dh-24,32 do dash(0,y,5,18);dash(rw-5,y,5,18) end
  for i=k+1,#dashes do dashes[i].Visible=false end
  rect(selectedLabel,rx,fy+22,rw*.30,42);rect(clear,rx+rw*.32,fy+10,rw*.22,66);rect(merge,rx+rw*.57,fy,rw*.43,82)
  rect(creates,rx+rw*.57,fy+84,rw*.43,22);rect(status,rx,fy-18,rw*.55,22)
  rect(saleIcon,20,70,rw*.35,rh-90);rect(saleTitle,rw*.38,74,rw*.59,48)
  local sy=math.min(rh-72,140);rect(minus,rw*.38,sy,60,58);rect(quantity,rw*.38+68,sy,110,58);rect(plus,rw*.38+186,sy,60,58);rect(max,rw*.38+254,sy,98,58)
  layingOut=false
 end
 function view:SetPetState(state)
  petState=state
  for id in pairs(petSelected) do if not PetMerge.Eligible(state,id) then petSelected[id]=nil end end
  if tab=='Pet' and shop.Visible then render() end
 end
 function view:SetItemState(state,fresh,pending,message)
  itemState=state;itemFresh=fresh==true;itemPending=pending==true
  for id,n in pairs(itemSelected) do
   local count=state and state.OwnedItems and state.OwnedItems[id] or 0
   if not Items.IsUnlocked(Master.Get(id),unlocked()) then count=0 end
   itemSelected[id]=math.min(n,count)>0 and math.min(n,count) or nil
  end
  if tab=='Item' then status.Text=message or '';if shop.Visible then render() end end
 end
 function view:SelectTab(name)
  if not tabs[name] then return end
  endDrag();destroyCards(materialCards);destroyCards(inputCards);destroyCards(candidateCards);candidateSignature=''
  tab=name;itemSelected={};petSelected={};oreSelected={};oreSale={};completedItem=nil;completedBell=nil;sellMode=false;activeOre=nil;status.Text=''
  shop:SetAttribute('SelectedTab',name);list.CanvasPosition=Vector2.zero;inputList.CanvasPosition=Vector2.zero
  render();if ctx.OnTab then ctx.OnTab(name) end
  if name=='Ore' then task.spawn(Forge.Refresh) end
 end
 function view:Clear()
  if itemPending and tab=='Item' or petPending and tab=='Pet' or tab=='Ore' and Forge.IsPending() then return end
  endDrag();itemSelected={};petSelected={};oreSelected={};oreSale={};completedItem=nil;completedBell=nil;status.Text='';render()
 end
 function view:IsPet() return tab=='Pet' end
 function view:IsItem() return tab=='Item' end
 function view:Show() shop.Visible=true;self:SelectTab('Item') end
 function view:Hide()
  shop.Visible=false;endDrag();itemSelected={};petSelected={};oreSelected={};oreSale={};completedItem=nil;completedBell=nil
  destroyCards(materialCards);destroyCards(inputCards);destroyCards(candidateCards);candidateSignature='';table.clear(blocked)
 end
 function view:Destroy()
  if dead then return end
  self:Hide();dead=true;for _,c in connections do c:Disconnect() end;if host~=gui then host:Destroy() else shop:Destroy() end
 end
 function view:SubmitItem()
  if not merge.Interactable then return end
  if tab=='Pet' then
   if petPending or PetClient.busy() or not petPreview() then return end
   local ids=petIds();petPending=true;render()
   task.spawn(function()
    local ok,why=PetClient.request('Merge',ids);petPending=false
    if ok then petSelected={} end
    petState=PetClient.state();status.Text=ok and 'Egg created' or tostring(why or 'Please wait')
    if not dead and tab=='Pet' and shop.Visible then render() end
   end)
  elseif tab=='Ore' then
   if not Forge.IsPending() then Forge.Request(sellMode and 'SellOre' or 'MergeOre',{Materials=table.clone(oreSelection())}) end
  else
   if itemPending or not itemFresh or not itemPreview() or itemState.SavePending then return end
   itemPending=true;itemFresh=false;render();ctx.OnMerge(table.clone(itemSelected))
  end
 end
 function view:CompleteItem(id) itemSelected={};completedItem=id;if tab=='Item' and shop.Visible then render() end end
 connect(merge.Activated,function()view:SubmitItem()end);connect(clear.Activated,function()view:Clear()end)
 connect(top.Close.Activated,function()view:Hide()end)
 for name,b in pairs(tabs) do connect(b.Activated,function()view:SelectTab(name)end) end
 function view:SetSellMode(value)
  if tab~='Ore' or Forge.IsPending() then return end
  sellMode=value==true;oreSale={};activeOre=nil;completedBell=nil;status.Text='';render()
 end
 connect(sell.Activated,function()view:SetSellMode(not sellMode)end)
 local function saleCount(n)
  if not activeOre or Forge.IsPending() then return end
  n=math.clamp(math.floor(tonumber(n) or 0),0,oreState.Ores[activeOre] or 0);oreSale[activeOre]=n>0 and n or nil;render()
 end
 connect(quantity.FocusLost,function()saleCount(quantity.Text)end)
 connect(minus.Activated,function()saleCount((oreSale[activeOre] or 0)-1)end)
 connect(plus.Activated,function()saleCount((oreSale[activeOre] or 0)+1)end)
 connect(max.Activated,function()saleCount(oreState and oreState.Ores[activeOre] or 0)end)
 connect(Forge.Changed,function(state)
  oreState=state
  for _,selection in {oreSelected,oreSale} do for id,n in pairs(selection) do local count=math.min(n,state and state.Ores and state.Ores[id] or 0);selection[id]=count>0 and count or nil end end
  if tab=='Ore' and shop.Visible then render() end
 end)
 connect(Forge.Completed,function(op,response)
  if op.Action~='MergeOre' and op.Action~='SellOre' then return end
  if response.Success then oreSelected={};oreSale={};completedBell=op.Action=='MergeOre' and response.State.Journal.ResultId or nil;status.Text=op.Action=='SellOre' and 'Sold' or 'Created'
  else status.Text=tostring(response.Code) end
  if tab=='Ore' and shop.Visible then render() end
 end)
 if ctx.Input then
  connect(ctx.Input.InputBegan,function(input)
   if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
   if not shop.Visible then return end
   local p=point(input)
   for key,card in pairs(materialCards) do
    local a,b=card.Root.AbsolutePosition,card.Root.AbsolutePosition+card.Root.AbsoluteSize
    local la,lb=list.AbsolutePosition,list.AbsolutePosition+list.AbsoluteSize
    if p.X>=a.X and p.X<=b.X and p.Y>=a.Y and p.Y<=b.Y and p.X>=la.X and p.X<=lb.X and p.Y>=la.Y and p.Y<=lb.Y then
     view:PressMaterial(key,p,input.UserInputType==Enum.UserInputType.Touch,input);break
    end
   end
  end)
  connect(ctx.Input.InputChanged,function(input)
   if drag and (input==drag.Input or not drag.Touch and input.UserInputType==Enum.UserInputType.MouseMovement) then view:MovePointer(point(input)) end
  end)
  connect(ctx.Input.InputEnded,function(input)
   if drag and (input==drag.Input or not drag.Touch and input.UserInputType==Enum.UserInputType.MouseButton1) then view:ReleasePointer(point(input)) end
  end)
  connect(ctx.Input.WindowFocusReleased,endDrag)
 end
 connect(gui:GetPropertyChangedSignal('AbsoluteSize'),layout)
 view:SelectTab('Item')
 return view
end
