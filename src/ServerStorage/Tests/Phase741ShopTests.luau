-- Phase 7.4.1 UI regression: actual cloned GUI/client, simulated server replies.
-- Does not prompt purchases or touch player data.
local T={}
function T.Run()
 local gui=game.StarterGui.StrengthGui:Clone()
 gui.Name="Phase741UISandbox"
 for _,v in gui:GetDescendants() do if v:IsA("BaseScript") then v.Enabled=false end end
 gui.Parent=game.ServerStorage
 local results={}
 local function module(name,source) local m=Instance.new("ModuleScript"); m.Name=name; m.Source=source; m.Parent=gui; return m end
 local function replace(s,a,b) local i,j=s:find(a,1,true); assert(i,"Missing seam: "..a); return s:sub(1,i-1)..b..s:sub(j+1) end
 local ok,err=pcall(function()
  local R=require(module("TestRuntime",[==[
local R={Bindings={},Requests={},State={Loaded=true,OwnedItems={},EquippedItems={},Win=100}}
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
function R.Bind(card,kind,fn) R.Bindings[card]=R.Bindings[card] or {}; R.Bindings[card][kind]=fn end
function R.Reply(name,code,state)
 R.State=state
 remotes[name].OnClientEvent:Fire({Success=code=="Purchased" or code=="Equipped" or code=="PromptOpened",Code=code,State=state})
end
return R
]==]))
  local source=game.ServerStorage.Legacy.Scripts.ShopPanelClient.Source
  source=replace(source,'local RS=game:GetService("ReplicatedStorage")','local RS=require(script.Parent.TestRuntime)')
  module("TestMaster",game.ReplicatedStorage.Config.ItemMaster.Source)
  source=replace(source,'require(RS.Config:WaitForChild("ItemMaster"))','require(script.Parent.TestMaster)')
  for _,kind in ipairs({"WinBuyButton","RobuxBuyButton","EquipButton"}) do
   source=replace(source,'card.PurchaseOptions.'..kind..'.Activated:Connect(function()','RS.Bind(card,"'..kind..'",function()')
  end
  local client=require(module("TestClient",source..'\nreturn {Apply=applyState,Update=updateCard}'))
  local cards={}
  for _,card in gui.ShopPanel.Products:GetChildren() do if card:IsA("Frame") then cards[card:GetAttribute("ProductId")]=card end end
  local p=cards.Protein
  local function select(card,rarity,element)
   card:SetAttribute("SelectedRarity",rarity); card:SetAttribute("SelectedElement",element); client.Update(card)
   return card.PurchaseOptions
  end
  local function state(id,count,equipped)
   return {Loaded=true,OwnedItems=count>0 and {[id]=count} or {},EquippedItems=equipped and {Protein=id} or {},Win=100}
  end
  local function check(name,fn) fn(); table.insert(results,"PASS "..name) end
  check("Element selection immediately updates ItemMaster image for all product types",function()
   local expected={
    Protein={Fire="rbxassetid://88813844869136",Ice="rbxassetid://71899140469848",Electric="rbxassetid://99486749835983"},
    Glove={Fire="rbxassetid://112294938722512",Ice="rbxassetid://116331874339139",Electric="rbxassetid://87861483932138"},
    TrainingBelt={Fire="rbxassetid://123189885722060",Ice="rbxassetid://94400762055390",Electric="rbxassetid://102495913054361"},
   }
   for itemType,images in pairs(expected) do
    local card=cards[itemType]
    for element,image in pairs(images) do
     select(card,"Rare",element)
     assert(card.ImageBackground.ProductImage.Image==image,itemType.." "..element)
    end
   end
  end)
  check("Owned quantity 0/1/3 and zero hides EQUIP, never hides purchase",function()
   local id="PROTEIN_COMMON_FIRE"
   for _,n in ipairs({0,1,3}) do
    client.Apply(state(id,n))
    local controls=select(p,"Common","Fire")
    assert(controls.CountLabel.Text=="OWNED ×"..n)
    assert(controls.WinBuyButton.Visible and controls.WinBuyButton.Active and controls.WinBuyButton.BuyLabel.Text=="BUY")
    assert(controls.EquipButton.Visible==(n>0))
   end
  end)
  check("Win repeat purchase 2=>3=>4 instantly redraws count and keeps BUY available",function()
   local id="PROTEIN_COMMON_FIRE"
   client.Apply(state(id,2)); local controls=select(p,"Common","Fire")
   for n=3,4 do
    R.Bindings[p].WinBuyButton()
    assert(R.Requests[#R.Requests].Remote=="ItemPurchaseRequest" and R.Requests[#R.Requests].Id==id)
    assert(controls.WinBuyButton.BuyLabel.Text=="..." and not controls.WinBuyButton.Active)
    R.Reply("ItemPurchaseRequest","Purchased",state(id,n))
    assert(controls.CountLabel.Text=="OWNED ×"..n and controls.WinBuyButton.BuyLabel.Text=="BUY")
    assert(controls.EquipButton.Text=="EQUIP")
   end
  end)
  check("Dedicated EQUIP/EQUIPPED leaves owned quantity and purchase button unchanged",function()
   local id="PROTEIN_COMMON_FIRE"
   client.Apply(state(id,3)); local controls=select(p,"Common","Fire")
   R.Bindings[p].EquipButton()
   assert(R.Requests[#R.Requests].Remote=="ItemEquipRequest" and R.Requests[#R.Requests].Id==id)
   R.Reply("ItemEquipRequest","Equipped",state(id,3,true))
   assert(controls.CountLabel.Text=="OWNED ×3" and controls.EquipButton.Text=="EQUIPPED")
   assert(not controls.EquipButton.Active and controls.WinBuyButton.Active)
   R.Bindings[p].WinBuyButton()
   assert(R.Requests[#R.Requests].Remote=="ItemPurchaseRequest")
   R.Reply("ItemPurchaseRequest","Purchased",state(id,4,true))
   assert(controls.CountLabel.Text=="OWNED ×4" and controls.EquipButton.Text=="EQUIPPED")
  end)
  check("Owned Epic/Legendary can repurchase; PromptOpened never mistaken for +1 success",function()
   for _,rarity in ipairs({"Epic","Legendary"}) do
    local id="PROTEIN_"..rarity:upper().."_FIRE"
    client.Apply(state(id,2,true)); local controls=select(p,rarity,"Fire")
    assert(controls.RobuxBuyButton.Active and controls.RobuxBuyButton.Visible)
    assert(controls.RobuxBuyButton.PriceLabel.Text==(rarity=="Epic" and "25" or "50"))
    R.Bindings[p].RobuxBuyButton()
    assert(R.Requests[#R.Requests].Remote=="ItemRobuxPurchaseRequest" and R.Requests[#R.Requests].Id==id)
    R.Reply("ItemRobuxPurchaseRequest","PromptOpened",state(id,2,true))
    assert(controls.RobuxBuyButton.BuyLabel.Text=="..." and not controls.RobuxBuyButton.Active)
    R.Reply("ItemRobuxPurchaseRequest","AwaitingReceipt",state(id,2,true))
    assert(controls.CountLabel.Text=="OWNED ×2" and not controls.RobuxBuyButton.Active)
    R.Reply("ItemRobuxPurchaseRequest","Purchased",state(id,3,true))
    assert(controls.CountLabel.Text=="OWNED ×3" and controls.RobuxBuyButton.Active)
    assert(controls.EquipButton.Text=="EQUIPPED")
   end
  end)
  check("Selection changes do not overwrite pending purchase; cancellation/denial grants nothing",function()
   local id="PROTEIN_EPIC_FIRE"
   client.Apply(state(id,1)); select(p,"Epic","Fire")
   R.Bindings[p].RobuxBuyButton()
   local before=#R.Requests
   local controls=select(p,"Epic","Ice")
   R.Bindings[p].RobuxBuyButton()
   assert(#R.Requests==before)
   R.Reply("ItemRobuxPurchaseRequest","Cancelled",state(id,1))
   assert(controls.CountLabel.Text=="OWNED ×0" and controls.RobuxBuyButton.Active)
   client.Apply(state("PROTEIN_COMMON_FIRE",2)); controls=select(p,"Common","Fire")
   R.Bindings[p].WinBuyButton()
   R.Reply("ItemPurchaseRequest","NotEnoughWin",state("PROTEIN_COMMON_FIRE",2))
   assert(controls.CountLabel.Text=="OWNED ×2" and controls.WinBuyButton.Active)
  end)
  check("All 45 selections preserve prices, types, elements, rarity and quantity display",function()
   local prefixes={Protein="PROTEIN",Glove="GLOVE",TrainingBelt="TRAININGBELT"}
   for itemType,card in pairs(cards) do
    for _,rarity in ipairs({"Common","Uncommon","Rare","Epic","Legendary"}) do
     for _,element in ipairs({"Fire","Ice","Electric"}) do
      local id=prefixes[itemType].."_"..rarity:upper().."_"..element:upper()
      client.Apply({Loaded=true,OwnedItems={[id]=3},EquippedItems={}})
      local controls=select(card,rarity,element)
      assert(controls.CountLabel.Text=="OWNED ×3" and controls.EquipButton.Visible)
      local win=({Common=3,Uncommon=8,Rare=20})[rarity]
      if win then assert(controls.WinBuyButton.Visible and controls.WinBuyButton.PriceLabel.Text==win.." Win")
      else assert(controls.RobuxBuyButton.Visible and controls.RobuxBuyButton.RobuxIcon.Visible) end
     end
    end
   end
  end)
 end)
 gui:Destroy()
 if not ok then error(table.concat(results,"\n").."\nFAIL "..tostring(err)) end
 return table.concat(results,"\n")
end
return T
