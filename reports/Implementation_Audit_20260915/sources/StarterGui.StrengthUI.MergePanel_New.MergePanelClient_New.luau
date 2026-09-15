-- Phase 7.4.4: production client for the editable MergePanel_New GUI.
-- Inventory mutations and merge validation remain server-authoritative.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local Master=require(RS.Config:WaitForChild("ItemMaster"))
local stateRemote=RS.Remotes:WaitForChild("ItemInventoryState")
local mergeRemote=RS.Remotes:WaitForChild("ItemMergeRequest")
local screenGui=script.Parent
local inventory=player:WaitForChild("PlayerGui"):WaitForChild("StrengthGui"):WaitForChild("InventoryPanel")
local mergePage=inventory:WaitForChild("Content"):WaitForChild("Merge")
local panel=mergePage:WaitForChild("MergePanel")
local ownedArea=panel:WaitForChild("OwnedItemsArea")
local scroll=ownedArea:WaitForChild("OwnedItemsScroll")
local template=screenGui:WaitForChild("ItemCardTemplate")
local slotsRoot=panel.MergeRecipe.Slots
local materialGroups={slotsRoot.Material1,slotsRoot.Material2,slotsRoot.Material3}
local resultGroup=slotsRoot.Result
local mergeButton=panel.Footer.MergeButton
local playerGui=player:WaitForChild("PlayerGui")
local legacyGui=playerGui:WaitForChild("StrengthGui")
local menu=legacyGui:WaitForChild("LeftMenu")
local MergeConfig=require(RS.Config:WaitForChild("ItemMergeConfig"))
local nextRarity=Master.NextRarity
local rarityRank=Master.RarityRank
local elementIcons={Fire="🔥",Ice="❄️",Electric="⚡"}
local elementBackgrounds={
 Fire=Color3.fromRGB(122,38,56),
 Ice=Color3.fromRGB(40,106,166),
 Electric=Color3.fromRGB(167,122,22),
}
local displayNames={Protein="Protein",Glove="Glove",TrainingBelt="Training Belt"}
local owned={}
local entries={}
local selected={nil,nil,nil}
local nextSerial=0
local pending

local function newEntry(itemId)
 nextSerial+=1
 return {ItemId=itemId,Serial=nextSerial}
end
local function reconcileEntries()
 local remaining={}
 for id,count in pairs(owned) do
  if typeof(count)=="number" and count>0 and Master.Get(id) then remaining[id]=math.floor(count) end
 end
 local kept={}
 for _,entry in ipairs(entries) do
  if (remaining[entry.ItemId] or 0)>0 then
   table.insert(kept,entry)
   remaining[entry.ItemId]-=1
  end
 end
 local ids={}
 for id,count in pairs(remaining) do if count>0 then table.insert(ids,id) end end
 table.sort(ids)
 for _,id in ipairs(ids) do for _=1,remaining[id] do table.insert(kept,newEntry(id)) end end
 entries=kept
 local present={}
 for _,entry in ipairs(entries) do present[entry]=true end
 for index=1,MergeConfig.RequiredCount do if selected[index] and not present[selected[index]] then selected[index]=nil end end
end
local function isSelected(entry)
 for index=1,MergeConfig.RequiredCount do if selected[index]==entry then return true end end
 return false
end
local function setStars(container,rarity)
 local count=rarity and rarityRank[rarity] or 0
 for index=1,5 do container["Star"..index].Visible=index<=count end
end
local function setSlot(group,item)
 local slot=group.Slot
 local visible=item~=nil
 slot.ItemImage.ProductImage.Visible=visible
 slot.ElementIndicator.Text=visible and (elementIcons[item.Element] or "") or ""
 setStars(slot.RarityStars,visible and item.Rarity or nil)
 if visible then slot.ItemImage.ProductImage.Image=item.Image end
end
local function findResult(item)
 local rarity=nextRarity[item.Rarity]
 if not rarity or item.Mergeable~=true then return nil end
 for id,candidate in pairs(Master.GetAll()) do
  if candidate.ItemType==item.ItemType and candidate.Element==item.Element and candidate.Rarity==rarity then return id,candidate end
 end
 return nil
end
local function validSelection()
 if pending or not selected[1] then return nil end
 local itemId=selected[1].ItemId
 for index=1,MergeConfig.RequiredCount do
  if not selected[index] or selected[index].ItemId~=itemId then return nil end
 end
 local item=Master.Get(itemId)
 if not item or (owned[itemId] or 0)<MergeConfig.RequiredCount then return nil end
 local resultId,result=findResult(item)
 if not resultId then return nil end
 return itemId,resultId,result
end
local render
local function createCard(entry,order)
 local item=Master.Get(entry.ItemId)
 local card=template:Clone()
 card.Name=entry.ItemId.."__"..entry.Serial
 card:SetAttribute("ItemId",entry.ItemId)
 card:SetAttribute("CopySerial",entry.Serial)
 card:SetAttribute("RarityRank",rarityRank[item.Rarity] or 0)
 card.LayoutOrder=order
 card.Visible=true
 card.ItemImage.BackgroundColor3=elementBackgrounds[item.Element]
 card.ItemImage.ProductImage.Image=item.Image
 card.ItemImage.ElementIndicator.Text=elementIcons[item.Element] or ""
 card.ItemName.Text=displayNames[item.ItemType] or item.ItemType
 setStars(card.RarityStars,item.Rarity)
 local chosen=isSelected(entry)
 card.SelectedShade.Visible=chosen
 card.SelectButton.Active=not chosen and not pending
 card.SelectButton.AutoButtonColor=false
 card.SelectButton.Activated:Connect(function()
  if pending or isSelected(entry) then return end
  for index=1,MergeConfig.RequiredCount do
   if not selected[index] then selected[index]=entry;panel.Footer.Hint.Text="Item selected";render();return end
  end
 end)
 card.Parent=scroll
end
render=function()
 for _,child in scroll:GetChildren() do
  if child:GetAttribute("ProductionItemCard")==true or child:GetAttribute("MergePreviewCard")==true then child:Destroy() end
 end
 for order,entry in ipairs(entries) do
  local before=#scroll:GetChildren()
  createCard(entry,order)
  local card
  for _,candidate in scroll:GetChildren() do
   if candidate:GetAttribute("CopySerial")==entry.Serial then card=candidate;break end
  end
  if card then card:SetAttribute("ProductionItemCard",true) end
 end
 ownedArea.ItemCount.Text=tostring(#entries).." ITEMS"
 for index,group in ipairs(materialGroups) do
  local entry=selected[index]
  setSlot(group,entry and Master.Get(entry.ItemId) or nil)
 end
 local sourceId,resultId,result=validSelection()
 setSlot(resultGroup,result)
 mergeButton.Active=sourceId~=nil
 mergeButton.AutoButtonColor=mergeButton.Active
 mergeButton.BackgroundColor3=mergeButton.Active and Color3.fromRGB(37,99,255) or Color3.fromRGB(75,69,67)
 mergeButton.Text= pending and "MERGING..." or "MERGE  ›"
end
local function applyState(state)
 if typeof(state)~="table" or state.Loaded~=true or typeof(state.OwnedItems)~="table" then return false end
 owned=state.OwnedItems
 reconcileEntries()
 render()
 return true
end
local function refresh()
 local ok,state=pcall(function() return stateRemote:InvokeServer() end)
 if not ok or not applyState(state) then panel.Footer.Hint.Text="Player data is loading. Please reopen Merge." end
end
for index,group in ipairs(materialGroups) do
 group.Slot.RemoveButton.Activated:Connect(function()
  if pending then return end
  selected[index]=nil
  panel.Footer.Hint.Text="Item removed"
  render()
 end)
end
ownedArea.SortButton.Active=true
ownedArea.SortButton.AutoButtonColor=true
ownedArea.SortButton.Activated:Connect(function()
 local previous={}
 for index,entry in ipairs(entries) do previous[entry]=index end
 table.sort(entries,function(a,b)
  local aa,bb=Master.Get(a.ItemId),Master.Get(b.ItemId)
  local ar,br=rarityRank[aa.Rarity] or 0,rarityRank[bb.Rarity] or 0
  if ar~=br then return ar>br end
  return previous[a]<previous[b]
 end)
 panel.Footer.Hint.Text="Sorted by rarity"
 render()
end)
mergeButton.Activated:Connect(function()
 local sourceId=validSelection()
 if not sourceId then return end
 pending=sourceId
 panel.Footer.Hint.Text="Merging..."
 render()
 mergeRemote:FireServer(sourceId)
end)
local function openMerge()
 panel.Visible=true
 if inventory.Visible and mergePage.Visible then
  panel.Footer.Hint.Text=pending and "Merging..." or ("Select %d identical items from your collection"):format(MergeConfig.RequiredCount)
  refresh()
 end
end
mergePage:GetPropertyChangedSignal("Visible"):Connect(openMerge)
inventory:GetPropertyChangedSignal("Visible"):Connect(openMerge)
local errors={NotEnoughItems=("You need %d identical items."):format(MergeConfig.RequiredCount),NotMergeable="This item cannot be merged.",InvalidItemId="Invalid item.",InvalidRequest="Invalid merge request.",DataSaving="Saving inventory. Please try again.",InventorySavePending="Saving inventory. Reopen after saving completes.",RateLimited="Please wait a moment."}
mergeRemote.OnClientEvent:Connect(function(result)
 pending=nil
 if typeof(result)~="table" then panel.Footer.Hint.Text="Unable to merge. Please reopen Merge.";render();return end
 if result.Success then selected={nil,nil,nil} end
 if not applyState(result.State) then refresh() end
 if result.Success then
  local item=Master.Get(result.ResultItemId)
  panel.Footer.Hint.Text=item and ("Merged "..(displayNames[item.ItemType] or item.ItemType).." "..item.Rarity) or "Merge complete."
 else
  panel.Footer.Hint.Text=errors[result.Code] or "Unable to merge this item."
 end
end)
for _,name in ipairs({"ItemPurchaseRequest","ItemRobuxPurchaseRequest","ItemEquipRequest"}) do
 RS.Remotes:WaitForChild(name).OnClientEvent:Connect(function(result)
  if panel.Visible and typeof(result)=="table" then applyState(result.State) end
 end)
end
panel.Visible=true
render()

