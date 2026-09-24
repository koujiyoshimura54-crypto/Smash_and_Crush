-- Phase 7.4.3 UI regression: per-copy responsive grid with simulated server replies.
local T={}
function T.Run()
 local gui=game.StarterGui.StrengthGui:Clone();gui.Name="Phase743UISandbox"
 for _,v in gui:GetDescendants() do if v:IsA("BaseScript") then v.Enabled=false end end
 gui.Parent=game.ServerStorage
 local results={}
 local function module(name,source) local m=Instance.new("ModuleScript");m.Name=name;m.Source=source;m.Parent=gui;return m end
 local function replace(s,a,b)
  local i,j=s:find(a,1,true);assert(i,"Missing seam: "..a);return s:sub(1,i-1)..b..s:sub(j+1)
 end
 local ok,err=pcall(function()
  local R=require(module("TestRuntime",[==[
local R={Bindings={},Requests={},State={Loaded=true,OwnedItems={},EquippedItems={},Win=100}}
local function signal()
 local s={Listeners={}};function s:Connect(fn) table.insert(self.Listeners,fn) end
 function s:Fire(v) for _,fn in ipairs(self.Listeners) do fn(v) end end;return s
end
local remotes={}
for _,name in ipairs({"ItemPurchaseRequest","ItemEquipRequest","ItemInventoryState","ItemRobuxPurchaseRequest","ItemMergeRequest"}) do
 local remote={OnClientEvent=signal()}
 function remote:FireServer(id) table.insert(R.Requests,{Remote=name,Id=id}) end
 function remote:InvokeServer() return R.State end
 remotes[name]=remote
end
function R:WaitForChild(name) return assert(remotes[name]) end
function R.Bind(control,kind,fn) R.Bindings[control]=R.Bindings[control] or {};R.Bindings[control][kind]=fn end
function R.Reply(code,state,resultId)
 R.State=state;remotes.ItemMergeRequest.OnClientEvent:Fire({Success=code=="Merged",Code=code,ResultItemId=resultId,State=state})
end
return R
]==]))
  local source=game.ServerStorage.Legacy.Scripts.MergePanelClient.Source
  source=replace(source,'local RS=game:GetService("ReplicatedStorage")','local RS=require(script.Parent.TestRuntime)')
  source=replace(source,'local Players=game:GetService("Players")','local Players={LocalPlayer={PlayerGui=script.Parent}}')
  module("TestMaster",game.ReplicatedStorage.Config.ItemMaster.Source)
  source=replace(source,'require(RS.Config:WaitForChild("ItemMaster"))','require(script.Parent.TestMaster)')
  source=replace(source,'button.Activated:Connect(function()','RS.Bind(button,"Click",function()')
  source=replace(source,'card.Activated:Connect(function()','RS.Bind(card,"Click",function()')
  source=replace(source,'organizeButton.Activated:Connect(function()','RS.Bind(organizeButton,"Click",function()')
  source=replace(source,'mergeButton.Activated:Connect(function()','RS.Bind(mergeButton,"Click",function()')
  source=replace(source,'menu.MergeButton.Activated:Connect(function()','RS.Bind(menu.MergeButton,"Click",function()')
  local client=require(module("MergeTestClient",source..'\nreturn {Apply=applyState,Layout=layout}'))
  local panel=gui.MergePanel
  local function state(items) return {Loaded=true,OwnedItems=items,EquippedItems={},Win=100} end
  local function cardsFor(id)
   local found={}
   for _,card in panel.Items:GetChildren() do if card:IsA("TextButton") and card:GetAttribute("ItemId")==id then table.insert(found,card) end end
   table.sort(found,function(a,b) return a.LayoutOrder<b.LayoutOrder end);return found
  end
  local function allCards()
   local found={}
   for _,card in panel.Items:GetChildren() do if card:IsA("TextButton") then table.insert(found,card) end end
   table.sort(found,function(a,b) return a.LayoutOrder<b.LayoutOrder end);return found
  end
  local function check(name,fn) fn();table.insert(results,"PASS "..name) end
  check("quantity six renders six individual cards with no quantity label",function()
   client.Apply(state({PROTEIN_COMMON_FIRE=6}))
   local cards=cardsFor("PROTEIN_COMMON_FIRE");assert(#cards==6)
   for _,card in cards do
    assert(not card:FindFirstChild("OwnedCount") and not card:FindFirstChild("Details"))
    assert(card.ItemImage.Image=="rbxassetid://88813844869136")
    assert(card.ItemName.Text=="Protein" and card.ElementIcon.Text=="🔥")
    assert(#card.RarityStars:GetChildren()==2)
    assert(card.RarityStars.Star1.Image=="rbxassetid://113086940656766")
   end
  end)
  check("all rarities use one through five stars and element icons",function()
   client.Apply(state({
    PROTEIN_COMMON_FIRE=1,
    PROTEIN_UNCOMMON_ICE=1,
    GLOVE_RARE_ELECTRIC=1,
    GLOVE_EPIC_FIRE=1,
    TRAININGBELT_LEGENDARY_ICE=1,
   }))
   local expected={
    PROTEIN_COMMON_FIRE={1,"🔥"},
    PROTEIN_UNCOMMON_ICE={2,"❄️"},
    GLOVE_RARE_ELECTRIC={3,"⚡"},
    GLOVE_EPIC_FIRE={4,"🔥"},
    TRAININGBELT_LEGENDARY_ICE={5,"❄️"},
   }
   for id,values in pairs(expected) do
    local card=cardsFor(id)[1]
    local count=0
    for _,child in card.RarityStars:GetChildren() do
     if child:IsA("ImageLabel") then count+=1;assert(child.Image=="rbxassetid://113086940656766") end
    end
    assert(count==values[1] and card.ElementIcon.Text==values[2])
    assert(not card:FindFirstChild("Details") and not card:FindFirstChild("OwnedCount"))
   end
  end)
  check("three distinct cards select left-to-right, darken, and enable matching result",function()
   client.Apply(state({PROTEIN_COMMON_FIRE=6}))
   local cards=cardsFor("PROTEIN_COMMON_FIRE")
   R.Bindings[cards[1]].Click();cards=cardsFor("PROTEIN_COMMON_FIRE");R.Bindings[cards[2]].Click()
   cards=cardsFor("PROTEIN_COMMON_FIRE");R.Bindings[cards[3]].Click()
   cards=cardsFor("PROTEIN_COMMON_FIRE")
   assert(panel.SlotWorkspace.Slot1.ItemImage.Visible and panel.SlotWorkspace.Slot2.ItemImage.Visible and panel.SlotWorkspace.Slot3.ItemImage.Visible)
   local selectedCount=0 for _,card in cards do if card.SelectedShade.Visible then selectedCount+=1 end end
   assert(selectedCount==3 and panel.MergeAction.Active)
   assert(panel.SlotWorkspace.ResultSlot.Rarity.Text=="UNCOMMON")
   assert(panel.SlotWorkspace.ResultSlot.ItemImage.Image=="rbxassetid://88813844869136")
  end)
  check("merge consumes three copies, appends one result, and resets controls",function()
   R.Bindings[panel.MergeAction].Click();assert(#R.Requests==1 and R.Requests[1].Id=="PROTEIN_COMMON_FIRE")
   R.Reply("Merged",state({PROTEIN_COMMON_FIRE=3,PROTEIN_UNCOMMON_FIRE=1}),"PROTEIN_UNCOMMON_FIRE")
   assert(#cardsFor("PROTEIN_COMMON_FIRE")==3 and #cardsFor("PROTEIN_UNCOMMON_FIRE")==1)
   assert(panel.SlotWorkspace.Slot1.Empty.Visible and panel.SlotWorkspace.ResultSlot.Empty.Visible and not panel.MergeAction.Active)
  end)
  check("newly acquired copies append to the current display tail",function()
   local before=allCards();local oldTail=before[#before]:GetAttribute("CopyIndex")
   client.Apply(state({PROTEIN_COMMON_FIRE=4,PROTEIN_UNCOMMON_FIRE=1}))
   local after=allCards();assert(#after==5)
   assert(after[#after]:GetAttribute("ItemId")=="PROTEIN_COMMON_FIRE")
   assert(after[#after]:GetAttribute("CopyIndex")>oldTail)
  end)
  check("organize sorts only UI entries from Legendary down to Common",function()
   client.Apply(state({PROTEIN_COMMON_FIRE=1,GLOVE_LEGENDARY_ICE=1,TRAININGBELT_RARE_ELECTRIC=1,PROTEIN_EPIC_FIRE=1}))
   R.Bindings[panel.OwnedSection.OrganizeButton].Click()
   local cards=allCards()
   assert(cards[1]:GetAttribute("RarityRank")==5)
   assert(cards[2]:GetAttribute("RarityRank")==4)
   assert(cards[3]:GetAttribute("RarityRank")==3)
   assert(cards[4]:GetAttribute("RarityRank")==1)
  end)
  check("Legendary three copies never enable merge",function()
   client.Apply(state({GLOVE_LEGENDARY_ICE=3}))
   local cards=cardsFor("GLOVE_LEGENDARY_ICE")
   for index=1,3 do R.Bindings[cardsFor("GLOVE_LEGENDARY_ICE")[index]].Click() end
   assert(not panel.MergeAction.Active and panel.SlotWorkspace.ResultSlot.Empty.Visible)
  end)
 end)
 gui:Destroy()
 if not ok then error(table.concat(results,"\n").."\nFAIL "..tostring(err)) end
 return table.concat(results,"\n")
end
return T