-- Client presentation only: record exposure now, persist acknowledgement on leaving.
local State=require(script.Parent:WaitForChild("InventoryNotificationState"))
local M={}
function M.IsVisible(gui,panel,page,list,target)
 if not gui.Enabled or not panel.Visible or not page.Visible or not list.Visible or not target or not target.Visible then return false end
 local p,s=target.AbsolutePosition,target.AbsoluteSize
 local screen=gui.AbsoluteSize
 local left,right,top,bottom=math.max(p.X,0),math.min(p.X+s.X,screen.X),math.max(p.Y,0),math.min(p.Y+s.Y,screen.Y)
 local ancestor=target.Parent
 while ancestor and ancestor~=gui do
  if ancestor:IsA("GuiObject") then
   if not ancestor.Visible then return false end
   if ancestor.ClipsDescendants or ancestor==list then
    local ap,az=ancestor.AbsolutePosition,ancestor.AbsoluteSize
    left=math.max(left,ap.X);right=math.min(right,ap.X+az.X)
    top=math.max(top,ap.Y);bottom=math.min(bottom,ap.Y+az.Y)
   end
  end
  ancestor=ancestor.Parent
 end
 return s.X>0 and s.Y>0 and right-left>=math.min(32,s.X*.35) and bottom-top>=math.min(24,s.Y*.35)
end
-- options: Gui, Panel, Page, List, Category, CardCategory?, TabPrefix?
-- Existing plain IDs remain valid; new stage keys share the existing saved set.
function M.new(options)
 local self={eligible={},targets={},legacy={},inventoryShown={},tabShown={},cardShown={},inventoryVisible=false,pageVisible=false}
 local connections={}
 local alive=true
 local function tabKey(id) return (options.TabPrefix or "")..id end
 local function inventoryKey(id) return "Inventory:"..id end
 function self:InventoryUnseen(id)
  return self.eligible[id]==true and not self.legacy[id] and not State.IsSeen(options.Category,inventoryKey(id))
 end
 function self:TabUnseen(id)
  return self.eligible[id]==true and not self.legacy[id] and not State.IsSeen(options.Category,tabKey(id))
 end
 function self:CardUnseen(id)
  return options.CardCategory~=nil and self.eligible[id]==true and not State.IsSeen(options.CardCategory,id)
 end
 function self:HasInventory()
  for id in pairs(self.eligible) do if self:InventoryUnseen(id) then return true end end
  return false
 end
 function self:HasTab()
  for id in pairs(self.eligible) do if self:TabUnseen(id) then return true end end
  return false
 end
 function self:Check()
  if not State.IsLoaded() then return end
  local inventoryVisible=options.Gui.Enabled and options.Panel.Visible
  local pageVisible=inventoryVisible and options.Page.Visible
  local leftPage=self.pageVisible and not pageVisible
  local leftInventory=self.inventoryVisible and not inventoryVisible
  -- Commit transitions before MarkSeen fires synchronous render listeners.
  self.inventoryVisible=inventoryVisible;self.pageVisible=pageVisible
  local writes={}
  local function queue(category,key)
   writes[category]=writes[category] or {}
   table.insert(writes[category],key)
  end
  if leftPage then
   for id in pairs(self.tabShown) do queue(options.Category,tabKey(id)) end
   for id in pairs(self.cardShown) do queue(options.CardCategory,id) end
   table.clear(self.tabShown);table.clear(self.cardShown)
  end
  if leftInventory then
   for id in pairs(self.inventoryShown) do queue(options.Category,inventoryKey(id)) end
   table.clear(self.inventoryShown)
  end
  for id in pairs(self.eligible) do
   -- Only old saves inherit legacy bulk acknowledgement. A new individual
   -- acknowledgement cannot clear an upper stage during this open session.
   if self.legacy[id]==nil then self.legacy[id]=State.IsSeen(options.Category,id)==true end
   if inventoryVisible and self:InventoryUnseen(id) then self.inventoryShown[id]=true end
   if pageVisible then
    if self:TabUnseen(id) then self.tabShown[id]=true end
    local target=self.targets[id]
    if self:CardUnseen(id) and M.IsVisible(options.Gui,options.Panel,options.Page,options.List,target) then
     self.cardShown[id]=true
    end
   end
  end
  for category,keys in pairs(writes) do State.MarkSeen(category,keys) end
 end
 function self:Update(eligible,targets)
  self.eligible=eligible;self.targets=targets or {}
  self:Check()
 end
 local function check() self:Check() end
 table.insert(connections,options.Panel:GetPropertyChangedSignal("Visible"):Connect(check))
 table.insert(connections,options.Page:GetPropertyChangedSignal("Visible"):Connect(check))
 table.insert(connections,options.Gui:GetPropertyChangedSignal("Enabled"):Connect(check))
 if options.List then
  for _,property in ipairs({"CanvasPosition","AbsolutePosition","AbsoluteSize"}) do
   table.insert(connections,options.List:GetPropertyChangedSignal(property):Connect(function() task.defer(check) end))
  end
 end
 table.insert(connections,options.Gui.Destroying:Connect(function()
  alive=false
  for _,connection in ipairs(connections) do connection:Disconnect() end
 end))
 task.spawn(function()
  while alive do
   task.wait(.2)
   if self.inventoryVisible or options.Panel.Visible then self:Check() end
  end
 end)
 return self
end
return M
