-- Manual presentation fixture for a disposable verification Studio only.
-- Never save this Edit session. No Play, player data, purchase or Remote writes.
assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning())
assert(game.PlaceId==0,"Use only the disposable local verification session")
local RS=game.ReplicatedStorage
local event=Instance.new("BindableEvent")
local P=require(RS.Modules.InventoryPresentation)
_G.UiPresentation=P
_G.UIReviewState={Loaded=true,Win=12345,OwnedDumbbells={NORMAL_01=true},EquippedDumbbell="NORMAL_01",OwnedItems={},EquippedItems={Protein="PROTEIN_COMMON_FIRE"},OwnedAuras={},EquippedAura="",OwnedSpeeds={},PremiumOwned=false,Recipes={},RequiredCount=3}
local master=require(RS.Config.ItemMaster)
for id,item in master.GetAll() do
 if item.Rarity==master.Rarities[1] then _G.UIReviewState.OwnedItems[id]=3 end
end
local remotes=setmetatable({},{__index=function(t,k)
 local remote={OnClientEvent=event.Event,InvokeServer=function()return _G.UIReviewState end,FireServer=function()error("Remote writes forbidden in Edit preview: "..k)end}
 rawset(t,k,remote) return remote
end})
remotes.WaitForChild=function(t,k)return t[k]end
local rsProxy=setmetatable({Remotes=remotes},{__index=function(_,k)return RS[k]end})
local player={UserId=0,GetAttribute=function(_,k)return k=="Win" and 12345 or nil end,GetAttributeChangedSignal=function()return event.Event end,WaitForChild=function(_,k)assert(k=="PlayerGui")return game.StarterGui end}
local proxy=setmetatable({GetService=function(_,name)
 if name=="Players" then return {LocalPlayer=player} end
 if name=="ReplicatedStorage" then return rsProxy end
 if name=="MarketplaceService" then return {PromptGamePassPurchaseFinished=event.Event,PromptGamePassPurchase=function()error("Purchase forbidden in Edit preview")end} end
 return game:GetService(name)
end},{__index=function(_,k)return game[k]end})
local function run(scriptObject,tail)
 local env=setmetatable({script=scriptObject,game=proxy,task=setmetatable({spawn=function()end},{__index=task}),require=function(m)
  if m.Name=="InventoryPresentation" then return P end
  if m.Name=="MarketplacePrice" then return {Get=function(_,_,fallback)return fallback,"fixture" end,Apply=function(label,v)label.Text=tostring(v)end} end
  if m.Name=="InventoryNotificationState" then return {Load=function()return true end,Changed=event.Event} end
  if m.Name=="AuraPurchaseNotifications" then return {Render=function()end,Changed=event.Event} end
  if m.Name=="InventoryNotificationExposure" then return {new=function()return {Update=function()end,HasTab=function()return false end,HasInventory=function()return false end}end} end
  return require(m)
 end},{__index=getfenv()})
 local fn=assert(loadstring(scriptObject.Source.."\n"..tail,"EditVisualFixture/"..scriptObject.Name))
 setfenv(fn,env) fn()
end
local gui=game.StarterGui.StrengthGui
run(gui.InventoryPanelClient,'_G.UIReviewDumbbells=function()applyState(_G.UIReviewState);selectCard("NORMAL_02");layout()end;_G.UIReviewDumbbells()')
run(gui.ItemInventoryTabClient,'_G.UIReviewItems=function(n)rarityIndex=n or 1;applyState(_G.UIReviewState)end;_G.UIReviewItems()')
run(gui.AuraInventoryClient,'_G.UIReviewAura=function()apply(_G.UIReviewState)end;_G.UIReviewAura()')
run(gui.SpeedInventoryClient,'_G.UIReviewSpeed=function()apply(_G.UIReviewState)end;_G.UIReviewSpeed()')
run(game.StarterGui.StrengthUI.MergePanel_New.MergePanelClient_New,'_G.UIReviewMerge=function(n)refresh();step=n or 1;render()end;_G.UIReviewMerge()')
_G.UIReviewTab=function(name)
 local panel=gui.InventoryPanel
 game.StarterGui.StageSkipGui.Enabled=false panel.Visible=true
 for _,v in panel.Content:GetChildren() do if v:IsA("GuiObject") then v.Visible=v.Name==name end end
 for _,b in panel.Tabs:GetChildren() do if b:IsA("GuiButton") then P.SetSelected(b,b.Name==name) end end
end
return "Presentation fixtures only; all Remote writes and purchase prompts forbidden"
