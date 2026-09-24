-- Run in Studio Edit: require(game.ServerStorage.Tests.Phase734ShopTests).Run()
-- Clone the actual GUI and client source; only Remote traffic is simulated.
local Tests={}
function Tests.Run()
 local gui=game.StarterGui.StrengthGui:Clone()
 gui.Name="Phase734ShopSandbox"
 for _,v in gui:GetDescendants() do if v:IsA("BaseScript") then v.Enabled=false end end
 gui.Parent=game.ServerStorage
 local results={}
 local function module(name,source)
  local m=Instance.new("ModuleScript"); m.Name=name; m.Source=source; m.Parent=gui; return m
 end
 local function replace(s,a,b)
  local i,j=s:find(a,1,true); assert(i,"Missing seam: "..a)
  return s:sub(1,i-1)..b..s:sub(j+1)
 end
 local ok,err=pcall(function()
  local runtime=module("TestRuntime",[==[
local R={Bindings={},RobuxBindings={},Requests={},State={Loaded=true,OwnedItems={},EquippedItems={},Win=100}}
local function signal()
 local s={Listeners={}}
 function s:Connect(fn) table.insert(self.Listeners,fn) end
 function s:Fire(v) for _,fn in ipairs(self.Listeners) do fn(v) end end
 return s
end
local remotes={}
for _,name in ipairs({"ItemPurchaseRequest","ItemEquipRequest","ItemInventoryState","ItemRobuxPurchaseRequest"}) do
 local remote={OnClientEvent=signal()}
 function remote:FireServer(id) table.insert(R.Requests,{Remote=name,Id=id}) end
 function remote:InvokeServer() return R.State end
 remotes[name]=remote
end
function R:WaitForChild(name) return assert(remotes[name]) end
function R.BindBuy(card,fn) R.Bindings[card]=fn end
function R.BindRobux(card,fn) R.RobuxBindings[card]=fn end
function R.Reply(name,state) R.State=state; remotes[name].OnClientEvent:Fire({Success=true,State=state}) end
return R
]==])
  local R=require(runtime)
  local source=game.ServerStorage.Legacy.Scripts.ShopPanelClient.Source
  source=replace(source,'local RS=game:GetService("ReplicatedStorage")','local RS=require(script.Parent.TestRuntime)')
  source=replace(source,'card.PurchaseOptions.WinBuyButton.Activated:Connect(function()','RS.BindBuy(card,function()')
  source=replace(source,'card.PurchaseOptions.RobuxBuyButton.Activated:Connect(function()','RS.BindRobux(card,function()')
  local client=require(module("TestClient",source..'\nreturn {Apply=applyState,Update=updateCard}'))
  local function check(name,fn) fn(); table.insert(results,"PASS "..name) end
  local cards={}
  for _,card in gui.ShopPanel.Products:GetChildren() do
   if card:IsA("Frame") then cards[card:GetAttribute("ProductId")]=card end
  end
  local p=assert(cards.Protein)
  local function select(card,rarity,element)
   card:SetAttribute("SelectedRarity",rarity)
   card:SetAttribute("SelectedElement",element)
   client.Update(card)
   return card.PurchaseOptions.WinBuyButton
  end
  check("BUY => EQUIP => EQUIPPED; purchase and equip use separate remotes",function()
   client.Apply(R.State)
   local button=select(p,"Common","Fire")
   assert(button.BuyLabel.Text=="BUY" and button.PriceLabel.Text=="3 Win")
   R.Bindings[p]()
   assert(R.Requests[1].Remote=="ItemPurchaseRequest" and R.Requests[1].Id=="PROTEIN_COMMON_FIRE")
   local state={Loaded=true,OwnedItems={PROTEIN_COMMON_FIRE=true},EquippedItems={},Win=97}
   R.Reply("ItemPurchaseRequest",state)
   assert(button.BuyLabel.Text=="EQUIP" and button.Active and button.PriceLabel.Text=="")
   R.Bindings[p]()
   assert(R.Requests[2].Remote=="ItemEquipRequest")
   state.EquippedItems.Protein="PROTEIN_COMMON_FIRE"
   R.Reply("ItemEquipRequest",state)
   assert(button.BuyLabel.Text=="EQUIPPED" and not button.Active)
   R.Bindings[p]()
   assert(#R.Requests==2)
  end)
  check("Same-type replacement and other cards retain EQUIPPED",function()
   local state={Loaded=true,OwnedItems={PROTEIN_COMMON_FIRE=true,PROTEIN_RARE_ICE=true,GLOVE_EPIC_ICE=true},EquippedItems={Protein="PROTEIN_COMMON_FIRE",Glove="GLOVE_EPIC_ICE"},Win=97}
   client.Apply(state)
   select(cards.Glove,"Epic","Ice")
   local button=select(p,"Rare","Ice")
   assert(button.BuyLabel.Text=="EQUIP")
   R.Bindings[p]()
   assert(R.Requests[#R.Requests].Id=="PROTEIN_RARE_ICE")
   state.EquippedItems.Protein="PROTEIN_RARE_ICE"
   R.Reply("ItemEquipRequest",state)
   assert(button.BuyLabel.Text=="EQUIPPED")
   assert(cards.Glove.PurchaseOptions.WinBuyButton.BuyLabel.Text=="EQUIPPED")
   select(p,"Common","Fire")
   assert(button.BuyLabel.Text=="EQUIP")
  end)

  check("Robux click captures selection; server receipt updates EQUIP then EQUIPPED",function()
   client.Apply({Loaded=true,OwnedItems={},EquippedItems={}})
   select(p,"Epic","Ice")
   local button=p.PurchaseOptions.RobuxBuyButton
   assert(button.PriceLabel.Text=="25" and button.Active)
   R.RobuxBindings[p]()
   assert(R.Requests[#R.Requests].Remote=="ItemRobuxPurchaseRequest" and R.Requests[#R.Requests].Id=="PROTEIN_EPIC_ICE")
   assert(button.BuyLabel.Text=="..." and not button.Active)
   local count=#R.Requests
   select(p,"Epic","Fire")
   R.RobuxBindings[p]()
   assert(#R.Requests==count,"selection change must not overwrite in-flight purchase")
   R:WaitForChild("ItemRobuxPurchaseRequest").OnClientEvent:Fire({Success=true,Code="PromptOpened",State={Loaded=true,OwnedItems={},EquippedItems={}}})
   assert(not button.Active)
   R:WaitForChild("ItemRobuxPurchaseRequest").OnClientEvent:Fire({Success=false,Code="AwaitingReceipt",State={Loaded=true,OwnedItems={},EquippedItems={}}})
   assert(not button.Active,"prompt close must not grant/unlock a paid pending purchase")
   R:WaitForChild("ItemRobuxPurchaseRequest").OnClientEvent:Fire({Success=true,Code="Purchased",State={Loaded=true,OwnedItems={PROTEIN_EPIC_ICE=true},EquippedItems={}}})
   local equip=select(p,"Epic","Ice")
   assert(equip.Visible and equip.BuyLabel.Text=="EQUIP")
   assert(not button.Visible)
   R.Bindings[p]()
   assert(R.Requests[#R.Requests].Remote=="ItemEquipRequest")
   R.Reply("ItemEquipRequest",{Loaded=true,OwnedItems={PROTEIN_EPIC_ICE=true},EquippedItems={Protein="PROTEIN_EPIC_ICE"}})
   assert(equip.BuyLabel.Text=="EQUIPPED")
  end)
  check("Legendary price 50; cancel/reject restores BUY without ownership",function()
   for _,code in ipairs({"Cancelled","PendingSaveFailed","InvalidItemId","PendingPurchaseExists"}) do
    client.Apply({Loaded=true,OwnedItems={},EquippedItems={}})
    select(p,"Legendary","Electric")
    local button=p.PurchaseOptions.RobuxBuyButton
    assert(button.PriceLabel.Text=="50" and button.Active)
    R.RobuxBindings[p]()
    assert(R.Requests[#R.Requests].Id=="PROTEIN_LEGENDARY_ELECTRIC")
    R:WaitForChild("ItemRobuxPurchaseRequest").OnClientEvent:Fire({Success=false,Code=code,State={Loaded=true,OwnedItems={},EquippedItems={}}})
    assert(button.Active and button.BuyLabel.Text=="BUY")
   end
  end)
  check("All 45 UI selections preserve rarity/element/price; owned Epic/Legendary equip",function()
   for _,card in pairs(cards) do
    for _,rarity in ipairs({"Common","Uncommon","Rare","Epic","Legendary"}) do
     for _,element in ipairs({"Fire","Ice","Electric"}) do
      client.Apply({Loaded=true,OwnedItems={},EquippedItems={}})
      local button=select(card,rarity,element)
      local win=({Common=3,Uncommon=8,Rare=20})[rarity]
      if win then assert(button.Visible and button.BuyLabel.Text=="BUY" and button.PriceLabel.Text==win.." Win")
      else
       assert(not button.Visible and card.PurchaseOptions.RobuxBuyButton.Visible and card.PurchaseOptions.RobuxBuyButton.Active)
      end
     end
    end
   end
   for _,rarity in ipairs({"Epic","Legendary"}) do
    local id="PROTEIN_"..rarity:upper().."_ELECTRIC"
    client.Apply({Loaded=true,OwnedItems={[id]=true},EquippedItems={}})
    local button=select(p,rarity,"Electric")
    assert(button.Visible and button.Active and button.BuyLabel.Text=="EQUIP")
    assert(not p.PurchaseOptions.RobuxBuyButton.Visible)
    R.Bindings[p]()
    assert(R.Requests[#R.Requests].Remote=="ItemEquipRequest" and R.Requests[#R.Requests].Id==id)
    R.Reply("ItemEquipRequest",{Loaded=true,OwnedItems={[id]=true},EquippedItems={Protein=id}})
    assert(button.BuyLabel.Text=="EQUIPPED")
   end
  end)
 end)
 gui:Destroy()
 if not ok then error(table.concat(results,"\n").."\nFAIL "..tostring(err)) end
 return table.concat(results,"\n")
end
return Tests
