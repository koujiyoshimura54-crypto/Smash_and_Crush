local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local Master=require(RS.Config:WaitForChild("ItemMaster"))
local stateRemote=RS.Remotes:WaitForChild("ItemInventoryState")
local equipRemote=RS.Remotes:WaitForChild("ItemEquipRequest")
local shell=script.Parent:WaitForChild("InventoryPanel")
local page=shell.Content.Items
local list=page.OwnedItems
local owned,equipped={},{}
local selectedId,pending
local names={Protein="Protein",Glove="Glove",TrainingBelt="Training Belt"}
local colors={Common=Color3.fromRGB(191,181,209),Uncommon=Color3.fromRGB(80,215,116),Rare=Color3.fromRGB(82,157,255),Epic=Color3.fromRGB(202,112,255),Legendary=Color3.fromRGB(255,205,68)}
local function text(parent,name,value,y,height)
 local l=Instance.new("TextLabel") l.Name=name l.Text=value l.BackgroundTransparency=1
 l.Position=UDim2.new(0,6,0,y) l.Size=UDim2.new(1,-12,0,height)
 l.Font=Enum.Font.GothamBold l.TextColor3=Color3.new(1,1,1) l.TextScaled=true l.ZIndex=34 l.Parent=parent
 return l
end
local function render()
 for _,c in list:GetChildren() do if c:GetAttribute("InventoryItemCard") then c:Destroy() end end
 local ids={}
 for id,count in pairs(owned) do if count>0 and Master.Get(id) then table.insert(ids,id) end end
 table.sort(ids)
 page.Empty.Visible=#ids==0
 for _,kind in ipairs({"Protein","Glove","TrainingBelt"}) do
  local item=Master.Get(equipped[kind])
  page.Equipped[kind].Text=names[kind].."\n"..(item and (item.Rarity.." / "..item.Element) or "None equipped")
 end
 for order,id in ipairs(ids) do
  local item=Master.Get(id)
  local card=Instance.new("TextButton") card.Name=id card:SetAttribute("InventoryItemCard",true)
  card.Text="" card.LayoutOrder=order card.BackgroundColor3=Color3.fromRGB(118,58,165) card.BorderSizePixel=0 card.ZIndex=32 card.Parent=list
  local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,12) c.Parent=card
  local s=Instance.new("UIStroke") s.Color=selectedId==id and Color3.new(1,1,1) or (colors[item.Rarity] or Color3.new(1,1,1)) s.Thickness=selectedId==id and 3 or 2 s.Parent=card
  local icon=Instance.new("ImageLabel") icon.Name="Icon" icon.Image=item.Image icon.BackgroundTransparency=1 icon.ScaleType=Enum.ScaleType.Fit
  icon.Position=UDim2.fromOffset(10,8) icon.Size=UDim2.new(1,-20,0,72) icon.ZIndex=33 icon.Parent=card
  text(card,"ItemName",names[item.ItemType] or item.ItemType,84,23)
  text(card,"Rarity",item.Rarity.." / "..item.Element,110,20)
  text(card,"Count","Owned ×"..tostring(owned[id]),134,18)
  local b=Instance.new("TextButton") b.Name="EquipButton" b.Position=UDim2.new(0,8,1,-32) b.Size=UDim2.new(1,-16,0,26)
  b.Font=Enum.Font.GothamBold b.TextColor3=Color3.new(1,1,1) b.TextSize=15 b.ZIndex=35 b.Parent=card
  local isEquipped=equipped[item.ItemType]==id
  b.Text=isEquipped and "EQUIPPED" or (pending==id and "..." or "EQUIP")
  b.Active=not isEquipped and not pending b.AutoButtonColor=b.Active
  b.BackgroundColor3=isEquipped and Color3.fromRGB(96,74,124) or Color3.fromRGB(46,155,89)
  local bc=Instance.new("UICorner") bc.CornerRadius=UDim.new(0,7) bc.Parent=b
  card.Activated:Connect(function() selectedId=id render() end)
  b.Activated:Connect(function()
   if pending or (owned[id] or 0)<1 or equipped[item.ItemType]==id then return end
   selectedId=id pending=id page.Status.Text="Equipping..."
   render()
   equipRemote:FireServer(id)
  end)
 end
end
local function applyState(state)
 if typeof(state)~="table" or state.Loaded~=true or typeof(state.OwnedItems)~="table" then return false end
 owned=state.OwnedItems equipped=typeof(state.EquippedItems)=="table" and state.EquippedItems or {}
 render() return true
end
local function refresh()
 local ok,state=pcall(function() return stateRemote:InvokeServer() end)
 if not ok or not applyState(state) then page.Status.Text="Inventory is loading. Please reopen."
 else page.Status.Text="" end
end
local function opened() if shell.Visible and page.Visible then refresh() end end
shell:GetPropertyChangedSignal("Visible"):Connect(opened)
page:GetPropertyChangedSignal("Visible"):Connect(opened)
equipRemote.OnClientEvent:Connect(function(result)
 pending=nil
 if typeof(result)~="table" or not applyState(result.State) then refresh() end
 page.Status.Text=typeof(result)=="table" and (result.Success and "Equipped" or ("Unable to equip: "..tostring(result.Code))) or "Please try again"
end)
for _,name in ipairs({"ItemPurchaseRequest","ItemRobuxPurchaseRequest","ItemMergeRequest"}) do
 RS.Remotes:WaitForChild(name).OnClientEvent:Connect(function(result)
  if typeof(result)=="table" and shell.Visible then if not applyState(result.State) then refresh() end end
 end)
end
render()
