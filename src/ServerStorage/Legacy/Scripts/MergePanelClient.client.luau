-- Phase 7.4.3: responsive slot merge UI; server remains authoritative.
local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local Master=require(RS.Config:WaitForChild("ItemMaster"))
local remote=RS.Remotes:WaitForChild("ItemMergeRequest")
local stateRemote=RS.Remotes:WaitForChild("ItemInventoryState")
local gui=script.Parent
local menu=gui:WaitForChild("LeftMenu")
local panel=gui:WaitForChild("MergePanel")
local list=panel:WaitForChild("Items")
local scale=panel:WaitForChild("ResponsiveScale")
local nextRarity={Common="Uncommon",Uncommon="Rare",Rare="Epic",Epic="Legendary"}
local rarityRank={Common=1,Uncommon=2,Rare=3,Epic=4,Legendary=5}
local colors={Common=Color3.fromRGB(190,190,200),Uncommon=Color3.fromRGB(58,185,88),Rare=Color3.fromRGB(52,125,230),Epic=Color3.fromRGB(181,88,238),Legendary=Color3.fromRGB(245,190,45)}
local names={Protein="Protein",Glove="Glove",TrainingBelt="Training Belt"}
local elementIcons={Fire="🔥",Ice="❄️",Electric="⚡"}
local ownedCardStarImage="rbxassetid://113086940656766"
local pending
local owned={}
local entries={}
local nextEntrySerial=0
local selected={nil,nil,nil}
local renderedCards={}

local function corner(parent,radius)
 local value=Instance.new("UICorner");value.CornerRadius=UDim.new(0,radius or 10);value.Parent=parent;return value
end
local function stroke(parent,color,thickness)
 local value=Instance.new("UIStroke");value.Color=color or Color3.fromRGB(79,91,117);value.Thickness=thickness or 1;value.Parent=parent;return value
end
local function label(parent,name,text,position,size,textSize,color,alignment)
 local value=Instance.new("TextLabel")
 value.Name=name;value.Text=text;value.BackgroundTransparency=1;value.BorderSizePixel=0
 value.Position=position;value.Size=size;value.Font=Enum.Font.GothamBold;value.TextSize=textSize
 value.TextColor3=color or Color3.fromRGB(245,247,252);value.TextXAlignment=alignment or Enum.TextXAlignment.Left
 value.ZIndex=53;value.Parent=parent
 return value
end
local function itemImage(item)
 return item and typeof(item.Image)=="string" and item.Image or ""
end
local function findResult(item)
 local rarity=nextRarity[item.Rarity]
 if not rarity or item.Mergeable~=true then return nil end
 for id,candidate in pairs(Master.GetAll()) do
  if candidate.ItemType==item.ItemType and candidate.Element==item.Element and candidate.Rarity==rarity then return id,candidate end
 end
 return nil
end
local function newEntry(itemId)
 nextEntrySerial+=1
 return {ItemId=itemId,Serial=nextEntrySerial}
end
local function reconcileEntries()
 local remaining={}
 for id,count in pairs(owned) do
  if typeof(count)=="number" and count>0 and Master.Get(id) then remaining[id]=math.floor(count) end
 end
 local kept={}
 for _,entry in ipairs(entries) do
  local count=remaining[entry.ItemId] or 0
  if count>0 then table.insert(kept,entry);remaining[entry.ItemId]=count-1 end
 end
 local ids={}
 for id,count in pairs(remaining) do if count>0 then table.insert(ids,id) end end
 table.sort(ids)
 for _,id in ipairs(ids) do
  for _=1,remaining[id] do table.insert(kept,newEntry(id)) end
 end
 entries=kept
 local present={}
 for _,entry in ipairs(entries) do present[entry]=true end
 for index=1,3 do if selected[index] and not present[selected[index]] then selected[index]=nil end end
end
local function isSelected(entry)
 for index=1,3 do if selected[index]==entry then return true end end
 return false
end

local oldWorkspace=panel:FindFirstChild("SlotWorkspace")
if oldWorkspace then oldWorkspace:Destroy() end
for _,childName in ipairs({"MergeAction","InventoryTitle","OrganizeButton","OwnedSection"}) do
 local oldChild=panel:FindFirstChild(childName);if oldChild then oldChild:Destroy() end
end
panel.AnchorPoint=Vector2.new(.5,.5)
panel.Position=UDim2.fromScale(.5,.5)
scale.Scale=1
panel.Header.Title.Text="ITEM MERGE"
list.AutomaticCanvasSize=Enum.AutomaticSize.Y
list.CanvasSize=UDim2.new()
list.ScrollingDirection=Enum.ScrollingDirection.Y
list.ScrollBarThickness=7
list.ClipsDescendants=true
local oldLayout=list:FindFirstChildOfClass("UIListLayout")
if oldLayout then oldLayout:Destroy() end
local grid=Instance.new("UIGridLayout")
grid.Name="ItemGrid";grid.FillDirection=Enum.FillDirection.Horizontal;grid.FillDirectionMaxCells=5
grid.HorizontalAlignment=Enum.HorizontalAlignment.Left
grid.SortOrder=Enum.SortOrder.LayoutOrder;grid.StartCorner=Enum.StartCorner.TopLeft;grid.Parent=list
panel.EmptyLabel.Text="No items owned"
panel.Status.Text="Select three identical items"

local workspace=Instance.new("Frame")
workspace.Name="SlotWorkspace";workspace.BackgroundTransparency=1;workspace.ZIndex=51;workspace.Parent=panel
label(workspace,"MaterialTitle","MATERIALS",UDim2.fromScale(0,0),UDim2.fromScale(.68,.12),16,Color3.fromRGB(157,169,194))
label(workspace,"ResultTitle","RESULT",UDim2.fromScale(.75,0),UDim2.fromScale(.25,.12),16,Color3.fromRGB(157,169,194),Enum.TextXAlignment.Center)
local slotButtons={}
local function makeSlot(name,isResult)
 local button=Instance.new("TextButton")
 button.Name=name;button.Text="";button.AutoButtonColor=not isResult;button.Active=not isResult
 button.BackgroundColor3=Color3.fromRGB(24,30,43);button.BorderSizePixel=0;button.ZIndex=52;button.Parent=workspace
 corner(button,12);stroke(button,isResult and Color3.fromRGB(76,131,203) or Color3.fromRGB(72,82,105),2)
 local empty=label(button,"Empty",isResult and "?" or "+",UDim2.fromScale(0,0),UDim2.fromScale(1,1),46,Color3.fromRGB(91,104,132),Enum.TextXAlignment.Center)
 empty.TextYAlignment=Enum.TextYAlignment.Center
 local image=Instance.new("ImageLabel")
 image.Name="ItemImage";image.BackgroundTransparency=1;image.Position=UDim2.fromScale(.08,.04);image.Size=UDim2.fromScale(.84,.70)
 image.ScaleType=Enum.ScaleType.Fit;image.Visible=false;image.ZIndex=53;image.Parent=button
 local rarity=label(button,"Rarity","",UDim2.fromScale(.03,.76),UDim2.fromScale(.94,.21),isResult and 30 or 23,nil,Enum.TextXAlignment.Center)
 rarity.TextYAlignment=Enum.TextYAlignment.Center
 slotButtons[name]=button
 return button
end
for index=1,3 do
 local button=makeSlot("Slot"..index,false);button:SetAttribute("SlotIndex",index)
 button.Activated:Connect(function()
  if pending then return end
  selected[index]=nil;panel.Status.Text="Item removed";render()
 end)
end
local resultSlot=makeSlot("ResultSlot",true)
local arrow=label(workspace,"Arrow","→",UDim2.fromScale(.685,.43),UDim2.fromScale(.06,.24),40,Color3.fromRGB(116,174,247),Enum.TextXAlignment.Center)

local ownedSection=Instance.new("Frame")
ownedSection.Name="OwnedSection";ownedSection.BackgroundTransparency=1;ownedSection.ZIndex=51;ownedSection.Parent=panel
label(ownedSection,"InventoryTitle","OWNED ITEMS",UDim2.fromScale(0,0),UDim2.fromScale(.65,.11),18,Color3.fromRGB(157,169,194))
local organizeButton=Instance.new("TextButton")
organizeButton.Name="OrganizeButton";organizeButton.Text="整理";organizeButton.Font=Enum.Font.GothamBold;organizeButton.TextSize=17
organizeButton.TextColor3=Color3.fromRGB(240,244,252);organizeButton.BackgroundColor3=Color3.fromRGB(53,67,91)
organizeButton.BorderSizePixel=0;organizeButton.AnchorPoint=Vector2.new(1,0);organizeButton.Position=UDim2.fromScale(1,0)
organizeButton.Size=UDim2.fromScale(.13,.10);organizeButton.ZIndex=54;organizeButton.Parent=ownedSection;corner(organizeButton,8)

local mergeButton=Instance.new("TextButton")
mergeButton.Name="MergeAction";mergeButton.AnchorPoint=Vector2.new(.5,.5);mergeButton.Position=UDim2.fromScale(.5,.93)
mergeButton.Size=UDim2.fromScale(.33,.07);mergeButton.BorderSizePixel=0;mergeButton.Font=Enum.Font.GothamBold
mergeButton.TextSize=22;mergeButton.TextColor3=Color3.fromRGB(255,255,255);mergeButton.ZIndex=54;mergeButton.Parent=panel;corner(mergeButton,9)

local function setSlotVisual(button,item,isResult)
 local hasItem=item~=nil
 button.Empty.Visible=not hasItem;button.ItemImage.Visible=hasItem
 button.Rarity.Text=hasItem and (isResult and string.upper(item.Rarity) or item.Rarity) or ""
 if hasItem then
  button.ItemImage.Image=itemImage(item);button.Rarity.TextColor3=colors[item.Rarity] or Color3.new(1,1,1)
 end
end
local function validSelection()
 if pending or not selected[1] or not selected[2] or not selected[3] then return nil end
 local itemId=selected[1].ItemId
 if selected[2].ItemId~=itemId or selected[3].ItemId~=itemId then return nil end
 local item=Master.Get(itemId)
 if not item or (owned[itemId] or 0)<3 then return nil end
 local resultId,result=findResult(item)
 if not resultId then return nil end
 return itemId,resultId,result
end
local function styleCard(card,entry)
 local chosen=isSelected(entry)
 card.BackgroundColor3=chosen and Color3.fromRGB(18,22,31) or Color3.fromRGB(29,35,49)
 card.AutoButtonColor=not chosen and not pending
 card.Active=not chosen and not pending
 card.UIStroke.Color=chosen and Color3.fromRGB(73,126,196) or Color3.fromRGB(52,61,79)
 card.UIStroke.Thickness=chosen and 3 or 1
 card.SelectedShade.Visible=chosen
end
local function renderCards()
 for _,value in list:GetChildren() do if value:IsA("GuiButton") then value:Destroy() end end
 table.clear(renderedCards)
 panel.EmptyLabel.Visible=#entries==0
 for order,entry in ipairs(entries) do
  local item=Master.Get(entry.ItemId)
  local card=Instance.new("TextButton")
  card.Name=entry.ItemId.."__"..entry.Serial;card:SetAttribute("ItemId",entry.ItemId);card:SetAttribute("CopyIndex",entry.Serial)
  card:SetAttribute("RarityRank",rarityRank[item.Rarity] or 0);card:SetAttribute("Element",item.Element)
  card.LayoutOrder=order;card.Text="";card.BorderSizePixel=0;card.ZIndex=51;card.Parent=list;corner(card,10)
  local cardStroke=stroke(card,Color3.fromRGB(52,61,79),1);cardStroke.Name="UIStroke"
  local image=Instance.new("ImageLabel")
  image.Name="ItemImage";image.Image=itemImage(item);image.BackgroundTransparency=1;image.Position=UDim2.fromScale(.06,.03)
  image.Size=UDim2.fromScale(.88,.64);image.ScaleType=Enum.ScaleType.Fit;image.ZIndex=52;image.Parent=card
  local elementIcon=label(card,"ElementIcon",elementIcons[item.Element] or "",UDim2.fromScale(.72,.04),UDim2.fromScale(.24,.22),16,Color3.fromRGB(255,255,255),Enum.TextXAlignment.Center)
  elementIcon.TextScaled=true;local iconLimit=Instance.new("UITextSizeConstraint");iconLimit.MinTextSize=10;iconLimit.MaxTextSize=18;iconLimit.Parent=elementIcon
  local itemName=label(card,"ItemName",names[item.ItemType] or item.ItemType,UDim2.fromScale(.05,.67),UDim2.fromScale(.90,.15),18,nil,Enum.TextXAlignment.Center)
  itemName.TextScaled=true;local nameLimit=Instance.new("UITextSizeConstraint");nameLimit.MinTextSize=11;nameLimit.MaxTextSize=19;nameLimit.Parent=itemName
  local stars=Instance.new("Frame");stars.Name="RarityStars";stars.BackgroundTransparency=1;stars.Position=UDim2.fromScale(.05,.84)
  stars.Size=UDim2.fromScale(.90,.12);stars.ZIndex=52;stars.Parent=card
  local starsLayout=Instance.new("UIListLayout");starsLayout.FillDirection=Enum.FillDirection.Horizontal
  starsLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center;starsLayout.VerticalAlignment=Enum.VerticalAlignment.Center
  starsLayout.Padding=UDim.new(0,1);starsLayout.Parent=stars
  for starIndex=1,(rarityRank[item.Rarity] or 0) do
   local star=Instance.new("ImageLabel");star.Name="Star"..starIndex;star.Image=ownedCardStarImage
   star.BackgroundTransparency=1;star.Size=UDim2.fromScale(.16,1);star.ScaleType=Enum.ScaleType.Fit;star.ZIndex=52;star.Parent=stars
  end
  local shade=Instance.new("Frame");shade.Name="SelectedShade";shade.BackgroundColor3=Color3.fromRGB(5,8,13);shade.BackgroundTransparency=.45
  shade.BorderSizePixel=0;shade.Size=UDim2.fromScale(1,1);shade.ZIndex=53;shade.Visible=false;shade.Parent=card;corner(shade,10)
  card.Activated:Connect(function()
   if pending or isSelected(entry) then return end
   for index=1,3 do
    if not selected[index] then selected[index]=entry;panel.Status.Text="Item selected";render();return end
   end
  end)
  renderedCards[entry]=card;styleCard(card,entry)
 end
end
function render()
 for index=1,3 do
  local entry=selected[index];setSlotVisual(slotButtons["Slot"..index],entry and Master.Get(entry.ItemId) or nil,false)
 end
 local sourceId,resultId,result=validSelection();setSlotVisual(resultSlot,result,true)
 mergeButton.Active=sourceId~=nil;mergeButton.AutoButtonColor=mergeButton.Active
 mergeButton.BackgroundColor3=mergeButton.Active and Color3.fromRGB(45,122,221) or Color3.fromRGB(74,79,91)
 mergeButton.Text=pending and "MERGING..." or "MERGE"
 renderCards()
end
local function applyState(state)
 if typeof(state)~="table" or state.Loaded~=true or typeof(state.OwnedItems)~="table" then return false end
 owned=state.OwnedItems;reconcileEntries();render();return true
end
local function refresh()
 local ok,state=pcall(function() return stateRemote:InvokeServer() end)
 if not ok or not applyState(state) then panel.Status.Text="Player data is loading. Please reopen Merge." end
end
local function layout()
 local view=gui.AbsoluteSize
 if view.X<=0 or view.Y<=0 then return end
 panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5)
 panel.Size=UDim2.fromOffset(math.clamp(math.floor(view.X*.625),640,1250),math.clamp(math.floor(view.Y*.73),320,810))
 scale.Scale=1
 local width,height=panel.AbsoluteSize.X,panel.AbsoluteSize.Y
 local margin=math.floor(width*.04)
 panel.Header.Position=UDim2.fromOffset(0,0);panel.Header.Size=UDim2.fromScale(1,.10)
 workspace.Position=UDim2.fromOffset(margin,math.floor(height*.10))
 workspace.Size=UDim2.fromOffset(width-margin*2,math.floor(height*.31))
 local workW,workH=workspace.AbsoluteSize.X,workspace.AbsoluteSize.Y
 local materialsW=workW*.68
 local slotW=materialsW*.29
 local slotGap=(materialsW-slotW*3)/2
 local cardY=workH*.14
 local cardH=workH*.82
 for index=1,3 do
  slotButtons["Slot"..index].Position=UDim2.fromOffset((index-1)*(slotW+slotGap),cardY)
  slotButtons["Slot"..index].Size=UDim2.fromOffset(slotW,cardH)
 end
 resultSlot.Position=UDim2.fromOffset(workW*.75,cardY-cardH*.025)
 resultSlot.Size=UDim2.fromOffset(workW*.25,math.min(workH-cardY,cardH*1.10))
 ownedSection.Position=UDim2.fromOffset(margin,math.floor(height*.41))
 ownedSection.Size=UDim2.fromOffset(width-margin*2,math.floor(height*.45))
 list.Position=UDim2.fromOffset(margin,math.floor(height*.41)+math.floor(height*.05))
 list.Size=UDim2.fromOffset(width-margin*2,math.floor(height*.40))
 panel.EmptyLabel.Position=list.Position;panel.EmptyLabel.Size=list.Size
 panel.Status.Position=UDim2.fromOffset(margin,math.floor(height*.865));panel.Status.Size=UDim2.fromOffset(width-margin*2,math.floor(height*.035))
 mergeButton.Position=UDim2.fromScale(.5,.945);mergeButton.Size=UDim2.fromOffset(math.floor((width-margin*2)*.33),math.floor(height*.065))
 local gridW=math.max(1,list.AbsoluteSize.X-list.ScrollBarThickness-2)
 local gridH=math.max(1,list.AbsoluteSize.Y)
 local verticalPadding=math.max(6,math.floor(gridH*.025))
 local visibleRows=2.2
 local cellH=math.max(80,math.floor((gridH+verticalPadding)/visibleRows-verticalPadding))
 local cellW=cellH
 local horizontalPadding=math.max(4,math.floor(cellW*.06))
 local columns=math.max(1,math.floor((gridW+horizontalPadding)/(cellW+horizontalPadding)))
 grid.FillDirectionMaxCells=columns
 grid.CellPadding=UDim2.fromOffset(horizontalPadding,verticalPadding)
 grid.CellSize=UDim2.fromOffset(cellW,cellH)
end
organizeButton.Activated:Connect(function()
 local previous={}
 for index,entry in ipairs(entries) do previous[entry]=index end
 table.sort(entries,function(a,b)
  local aa,bb=Master.Get(a.ItemId),Master.Get(b.ItemId)
  local ar,br=rarityRank[aa.Rarity] or 0,rarityRank[bb.Rarity] or 0
  if ar~=br then return ar>br end
  return previous[a]<previous[b]
 end)
 panel.Status.Text="Sorted by rarity";render()
end)
mergeButton.Activated:Connect(function()
 local sourceId=validSelection();if not sourceId then return end
 pending=sourceId;panel.Status.Text="Merging...";render();remote:FireServer(sourceId)
end)
menu.MergeButton.Activated:Connect(function()
 panel.Visible=not panel.Visible;if not panel.Visible then return end
 for _,name in ipairs({"ShopPanel","InventoryPanel","RebirthPanel"}) do local other=gui:FindFirstChild(name);if other then other.Visible=false end end
 local skip=Players.LocalPlayer.PlayerGui:FindFirstChild("StageSkipGui");if skip and skip:FindFirstChild("Panel") then skip.Panel.Visible=false end
 panel.Status.Text=pending and "Merging..." or "Select three identical items";refresh();layout()
end)
for _,name in ipairs({"ShopButton","InventoryButton","RebirthButton","SkipButton"}) do menu[name].Activated:Connect(function() panel.Visible=false end) end
panel.Header.CloseButton.Activated:Connect(function() panel.Visible=false end)
local errors={NotEnoughItems="You need 3 identical items.",NotMergeable="This item cannot be merged.",InvalidItemId="Invalid item.",InvalidRequest="Invalid merge request.",DataSaving="Saving inventory. Please try again.",InventorySavePending="Saving inventory. Reopen after saving completes.",RateLimited="Please wait a moment."}
remote.OnClientEvent:Connect(function(result)
 pending=nil
 if typeof(result)~="table" then panel.Status.Text="Unable to merge. Please reopen Merge.";render();return end
 if result.Success then selected={nil,nil,nil} end
 if not applyState(result.State) then refresh() end
 if result.Success then
  local item=Master.Get(result.ResultItemId)
  panel.Status.Text=item and ("Merged: "..(names[item.ItemType] or item.ItemType).." "..item.Rarity.." / "..item.Element) or "Merge complete."
 else panel.Status.Text=errors[result.Code] or "Unable to merge this item." end
end)
for _,name in ipairs({"ItemPurchaseRequest","ItemRobuxPurchaseRequest","ItemEquipRequest"}) do
 RS.Remotes:WaitForChild(name).OnClientEvent:Connect(function(result) if panel.Visible and typeof(result)=="table" then applyState(result.State) end end)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() layout();render() end)
panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
render();layout()
