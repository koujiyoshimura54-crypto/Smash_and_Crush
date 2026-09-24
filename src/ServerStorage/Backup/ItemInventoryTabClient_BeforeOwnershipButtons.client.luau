local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local Master=require(RS.Config:WaitForChild("ItemMaster"))
local stateRemote=RS.Remotes:WaitForChild("ItemInventoryState")
local equipRemote=RS.Remotes:WaitForChild("ItemEquipRequest")
local winRemote=RS.Remotes:WaitForChild("ItemPurchaseRequest")
local robuxRemote=RS.Remotes:WaitForChild("ItemRobuxPurchaseRequest")
local shell=script.Parent:WaitForChild("InventoryPanel")
local page=shell.Content.Items
local list=page.OwnedItems
local owned,equipped={},{}
local selectedId,pending
local rarityIndex=1
local rarities={"Common","Uncommon","Rare","Epic","Legendary"}
local kinds={"Protein","Glove","TrainingBelt"}
local names={Protein="Protein",Glove="Glove",TrainingBelt="Belt"}
local slots,tabs={},{}
local categoryImages={
 Protein=Master.Get("PROTEIN_COMMON_FIRE").Image,
 Glove=Master.Get("GLOVE_COMMON_FIRE").Image,
 TrainingBelt=Master.Get("TRAININGBELT_COMMON_FIRE").Image,
}
local function style(o,color,radius)
 o.BackgroundColor3=color o.BorderSizePixel=0
 local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,radius or 12) c.Parent=o
 local s=Instance.new("UIStroke") s.Color=Color3.fromRGB(43,13,65) s.Thickness=2 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=o
 return s
end
local function label(parent,name,value,pos,size,z)
 local t=Instance.new("TextLabel") t.Name=name t.Text=value t.Position=pos t.Size=size
 t.BackgroundTransparency=1 t.Font=Enum.Font.GothamBlack t.TextColor3=Color3.new(1,1,1)
 t.TextScaled=true t.ZIndex=z or 35 t.Parent=parent
 local l=Instance.new("UITextSizeConstraint") l.MaxTextSize=30 l.MinTextSize=8 l.Parent=t
 return t
end
local function icon(parent,name,id,pos,size,z)
 local i=Instance.new("ImageLabel") i.Name=name i.Image=id i.Position=pos i.Size=size
 i.BackgroundTransparency=1 i.ScaleType=Enum.ScaleType.Fit i.ZIndex=z or 35 i.Parent=parent return i
end
page.Equipped.Size=UDim2.new(.44,0,1,0)
page.Owned.Position=UDim2.fromScale(.455,0) page.Owned.Size=UDim2.fromScale(.545,1)
page.Owned.Title.Text="Items"
page.Equipped.Hint.Visible=false
page.Equipped.Title.Text="Equip"
page.Empty.Visible=false
page.Status.Position=UDim2.new(.455,8,1,-22) page.Status.Size=UDim2.new(.545,-16,0,20)
page.Status.TextScaled=true
for n,kind in ipairs(kinds) do
 page.Equipped[kind].Visible=false
 local s=Instance.new("TextButton") s.Text="" s.Name=kind.."Socket" s.Position=UDim2.new(0,12,.14+(n-1)*.28,0)
 s.Size=UDim2.new(1,-24,.26,0) s.ZIndex=32 s.Parent=page.Equipped style(s,Color3.fromRGB(81,34,123))
 local studs=icon(s,"StudPattern","rbxassetid://111868739606818",UDim2.new(),UDim2.fromScale(1,1),32)
 studs.ScaleType=Enum.ScaleType.Tile studs.TileSize=UDim2.fromOffset(48,48) studs.ImageTransparency=.84
 local pic=icon(s,"EquippedImage",categoryImages[kind],UDim2.new(0,8,0,8),UDim2.new(.42,-12,1,-16),34)
 local none=label(s,"None","None",UDim2.new(.44,0,.1,0),UDim2.new(.56,-10,.8,0),35)
 none.TextWrapped=true
 none.TextXAlignment=Enum.TextXAlignment.Left
 none:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize=24
 local stars=label(s,"RarityStars","",UDim2.new(0,4,0,3),UDim2.new(.42,-4,.24,0),35)
 stars.TextColor3=Color3.fromRGB(255,220,65)
 stars:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize=24
 stars.Visible=false
 slots[kind]={image=pic,none=none,stars=stars,socket=s}
 s.Activated:Connect(function()
  if pending or not Master.Get(equipped[kind]) then return end
  pending=kind equipRemote:FireServer(kind,"Unequip")
 end)
end
local tabbar=Instance.new("Frame") tabbar.Name="RarityTabs" tabbar.BackgroundTransparency=1
tabbar.Position=UDim2.new(.455,10,0,52) tabbar.Size=UDim2.new(.545,-24,0,34) tabbar.ZIndex=35 tabbar.Parent=page
list.Position=UDim2.new(.455,10,0,96) list.Size=UDim2.new(.545,-24,1,-124)
list.ScrollingDirection=Enum.ScrollingDirection.Y list.AutomaticCanvasSize=Enum.AutomaticSize.Y
list.CanvasSize=UDim2.new() list.ScrollBarThickness=6 list.ScrollBarImageColor3=Color3.fromRGB(233,157,255)
local grid=list:FindFirstChildOfClass("UIGridLayout")
grid.CellPadding=UDim2.fromOffset(8,8) grid.FillDirectionMaxCells=3 grid.SortOrder=Enum.SortOrder.LayoutOrder
local function layout()
 local width=math.max(48,math.floor((list.AbsoluteSize.X-16-16)/3))
 grid.CellSize=UDim2.fromOffset(width,math.floor(width*1.12))
end
list:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
layout()
local render
local function request(remote,id)
 if pending then return end
 pending=id page.Status.Text="..." remote:FireServer(id)
end
local function priceButton(card,name,price,id,pos,size,color,remote,itemId)
 local b=Instance.new("TextButton") b.Name=name b.Text="" b.Position=pos b.Size=size b.ZIndex=35 b.Parent=card
 style(b,color,7)
 icon(b,"Currency",id,UDim2.new(0,3,0,3),UDim2.new(.31,0,1,-6),36)
 label(b,"Price",tostring(price),UDim2.fromScale(.34,.08),UDim2.fromScale(.62,.84),36)
 if not remote then
  b.Active=false b.Interactable=false b.AutoButtonColor=false
  b.BackgroundColor3=Color3.fromRGB(70,53,87)
  b.Currency.ImageTransparency=.5 b.Price.TextTransparency=.35
  return b
 end
 b.Activated:Connect(function()
  if (owned[itemId] or 0)>0 then
   local item=Master.Get(itemId)
   if equipped[item.ItemType]~=itemId then request(equipRemote,itemId) end
  else request(remote,itemId) end
 end)
 return b
end
render=function()
 for _,c in list:GetChildren() do if c:GetAttribute("InventoryItemCard") then c:Destroy() end end
 for kind,s in pairs(slots) do
  local item=Master.Get(equipped[kind])
  s.image.Image=item and item.Image or categoryImages[kind]
  s.image.Visible=true
  s.none.Visible=true
  s.none.Text=item and "Equipped" or "None"
  s.none.TextColor3=item and Color3.new(1,1,1) or Color3.fromRGB(178,178,188)
  s.image.ImageColor3=item and Color3.new(1,1,1) or Color3.fromRGB(145,145,155)
  s.image.ImageTransparency=item and 0 or .22
  s.socket.BackgroundColor3=item and Color3.fromRGB(81,34,123) or Color3.fromRGB(54,45,65)
  s.stars.Visible=item~=nil
  s.stars.Text=item and string.rep("★",table.find(rarities,item.Rarity) or 0) or ""
  s.image.Position=item and UDim2.new(0,8,.29,0) or UDim2.new(0,8,0,8)
  s.image.Size=item and UDim2.new(.42,-12,.71,-6) or UDim2.new(.42,-12,1,-16)
 end
 for n,t in ipairs(tabs) do
  t.BackgroundColor3=n==rarityIndex and Color3.fromRGB(177,72,250) or Color3.fromRGB(83,26,133)
  t.UIStroke.Color=n==rarityIndex and Color3.new(1,1,1) or Color3.fromRGB(43,13,65)
 end
 local ids={}
 for id,item in pairs(Master.GetAll()) do if item.Rarity==rarities[rarityIndex] then table.insert(ids,id) end end
 table.sort(ids,function(a,b)
  local x,y=Master.Get(a),Master.Get(b)
  local order={Protein=1,Glove=2,TrainingBelt=3}
  if x.ItemType~=y.ItemType then return (order[x.ItemType] or 99)<(order[y.ItemType] or 99) end
  return x.Element<y.Element
 end)
 for order,id in ipairs(ids) do
  local item=Master.Get(id)
  local c=Instance.new("TextButton") c.Name=id c.Text="" c.AutoButtonColor=false
  c.LayoutOrder=order c.ZIndex=32 c.Parent=list c:SetAttribute("InventoryItemCard",true)
  local stroke=style(c,Color3.fromRGB(103,32,160),12)
  stroke.Color=selectedId==id and Color3.new(1,1,1) or Color3.fromRGB(193,85,249) stroke.Thickness=3
  icon(c,"Icon",item.Image,UDim2.fromOffset(6,6),UDim2.new(1,-12,1,-44),33)
  c.Activated:Connect(function()
   selectedId=id
   if (owned[id] or 0)>0 and equipped[item.ItemType]~=id and not pending then request(equipRemote,id) end
   render()
  end)
  priceButton(c,"WinPurchase",rarityIndex<=3 and item.WinPrice or "—","rbxassetid://106494459783367",UDim2.new(0,3,1,-34),UDim2.new(.5,-4,0,31),Color3.fromRGB(235,184,36),rarityIndex<=3 and winRemote or nil,id)
  priceButton(c,"RobuxPurchase",rarityIndex>=4 and item.RobuxPrice or "—","rbxassetid://77577420970893",UDim2.new(.5,1,1,-34),UDim2.new(.5,-4,0,31),Color3.fromRGB(30,160,226),rarityIndex>=4 and robuxRemote or nil,id)
 end
end
for n=1,5 do
 local b=Instance.new("TextButton") b.Name="Star"..n b.Text="★"..n b.Font=Enum.Font.GothamBlack
 b.TextColor3=Color3.fromRGB(255,228,82) b.TextScaled=true b.Position=UDim2.new((n-1)/5,2,0,0)
 b.Size=UDim2.new(.2,-4,1,0) b.ZIndex=36 b.Parent=tabbar style(b,Color3.fromRGB(83,26,133),8)
 local stud=icon(b,"StudPattern","rbxassetid://111868739606818",UDim2.new(),UDim2.fromScale(1,1),36)
 stud.ScaleType=Enum.ScaleType.Tile stud.TileSize=UDim2.fromOffset(32,32) stud.ImageTransparency=.9
 tabs[n]=b b.Activated:Connect(function() rarityIndex=n list.CanvasPosition=Vector2.zero render() end)
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
local function opened() if shell.Visible and page.Visible then rarityIndex=1 list.CanvasPosition=Vector2.zero refresh() end end
shell:GetPropertyChangedSignal("Visible"):Connect(opened)
page:GetPropertyChangedSignal("Visible"):Connect(opened)
for _,remote in ipairs({equipRemote,winRemote,robuxRemote}) do
 remote.OnClientEvent:Connect(function(result)
  local code=typeof(result)=="table" and result.Code
  if code~="PromptOpened" and code~="AwaitingReceipt" then pending=nil end
  if typeof(result)~="table" or not applyState(result.State) then refresh() end
  page.Status.Text=typeof(result)=="table" and (result.Success and "" or (code=="Cancelled" and "" or tostring(code))) or "Please try again"
 end)
end
RS.Remotes:WaitForChild("ItemMergeRequest").OnClientEvent:Connect(function(result)
 if typeof(result)=="table" and shell.Visible then if not applyState(result.State) then refresh() end end
end)
render()
