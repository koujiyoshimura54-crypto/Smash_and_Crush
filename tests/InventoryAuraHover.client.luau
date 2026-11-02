local RS=game.ReplicatedStorage
local p=game.Players.LocalPlayer
local Q=require(RS.__UI4QAConnections)
local F=require(RS.Modules.UIFeedback)
local memory=require(RS.__UI4QAMemory)
local records,watched={},setmetatable({},{__mode="k"})
local function watch(s)
 if not s:IsA("Sound") or watched[s] then return end;watched[s]=true
 s.Played:Connect(function() records[#records+1]={Name=s.Name,Id=s.SoundId,Volume=s.Volume,Speed=s.PlaybackSpeed,Group=s.SoundGroup and s.SoundGroup:GetFullName() or "",Time=os.clock()}end)
end
for _,s in game.SoundService:GetDescendants()do watch(s)end
game.SoundService.DescendantAdded:Connect(watch)
local early={}
p.PlayerGui.DescendantAdded:Connect(function(o)
 if o:IsA("GuiButton") and o:GetAttribute("ItemId") then early[o.Name]=o.Visible end
end)
local function gui()return p.PlayerGui:WaitForChild("StrengthGui")end
local function open(page)
 local g=gui();local shell=g.InventoryPanel
 if not shell.Visible then Q.Fire(g.LeftMenu.InventoryButton,"Activated")end
 Q.Fire(shell.Tabs[page],"Activated");task.wait(.35)
 return shell
end
local function aura()
 local panel=gui().InventoryPanel.Content.Aura
 local rows={}
 for _,card in panel.AuraList:GetChildren()do if card:IsA("GuiObject") and card.Visible then
  local b=card.BuyButton;local visual=b:FindFirstChild("PurchasedButtonVisual")
  local function label(t)return {Path=t:GetFullName(),Text=t.Text,Family=t.FontFace.Family,Fits=t.TextFits,Size=tostring(t.AbsoluteSize),AutoLocalize=t.AutoLocalize}end
  rows[card.Name]={Name=label(card.AuraName),Effect=label(card.StrengthBonus),
   Button=label(visual and visual.Main.Amount or b.Label),Price=card.Price.Amount.Text,
   PriceVisible=card.Price.Visible,PriceActive=card.Price.Active,
   IconVisible=card.Price.CurrencyIcon.Visible,ButtonActive=b.Active,Position=tostring(card.AbsolutePosition)}
 end end
 return {Rows=rows,Viewport=tostring(gui().AbsoluteSize)}
end
local function dumbbells()
 local shell=gui().InventoryPanel;local page=shell.Content.Dumbbells
 local master=require(RS.Config.DumbbellItemMaster)
 local out={W1=0,W2=0,HiddenInteractive=0,Selected=page:GetAttribute("SelectedItemId"),Entries={},Early=early}
 for _,card in page.Items:GetChildren()do if card:IsA("GuiButton") and master.Get(card.Name)then
  local w=master.Get(card.Name).WorldId or 1
  if card.Visible then out[w==2 and "W2" or "W1"]+=1
  elseif card.Active or card.Interactable then out.HiddenInteractive+=1 end
  if w==2 then out.Entries[#out.Entries+1]={Id=card.Name,Visible=card.Visible,Active=card.Active,Count=card.OwnedCount.Text,Position=tostring(card.AbsolutePosition)}end
 end end
 return out
end
local function hover(button)
 local before=#records
 Q.Fire(button,"MouseLeave");task.wait(.12)
 local handlers=Q.Fire(button,"MouseEnter");task.wait(.03)
 Q.Fire(button,"MouseEnter");task.wait(.12)
 Q.Fire(button,"MouseLeave")
 local out={}for i=before+1,#records do out[#out+1]=records[i]end
 return {Events=out,Handlers=handlers}
end
local probe=Instance.new("BindableFunction");probe.Name="__UI4QAClient";probe.Parent=RS
probe.OnInvoke=function(action,value)
 if action=="Open"then open(value);return value=="Aura" and aura() or dumbbells()
 elseif action=="Aura"then return aura()
 elseif action=="Dumbbells"then return dumbbells()
 elseif action=="PriceReady"then memory.PriceReady=true;task.wait(.6);return aura()
 elseif action=="ClickAura"then Q.Fire(gui().InventoryPanel.Content.Aura.AuraList[value.."AuraCard"].BuyButton,"Activated");task.wait(.6);return aura()
 elseif action=="ClickDumbbell"then Q.Fire(gui().InventoryPanel.Content.Dumbbells.Items[value].BuyButton,"Activated");task.wait(.5);return dumbbells()
 elseif action=="Hover"then
  local g=gui();local b=g.InventoryPanel.Content.Aura.AuraList.PinkAuraCard.BuyButton
  local original=game.SoundService.UI.Hover.Volume;local out={}
  for _,volume in {original,.3,0}do
   game.SoundService.UI.Hover.Volume=volume
   out[#out+1]={Volume=volume,Purchase=hover(b),Menu=hover(g.LeftMenu.InventoryButton),Tab=hover(g.InventoryPanel.Tabs.Aura)}
  end
  game.SoundService.UI.Hover.Volume=original
  local before=#records;Q.Fire(b,"MouseLeave");task.wait(.12)
  local parent=Instance.new("TextButton");parent.Name="__UI4QAParent";parent.Size=UDim2.fromOffset(50,50);parent.Parent=g
  local child=Instance.new("TextButton");child.Name="Child";child.Size=UDim2.fromScale(1,1);child.Parent=parent
  F.BindButton(parent);F.BindButton(child);task.wait()
  Q.Fire(parent,"MouseEnter");Q.Fire(child,"MouseEnter");task.wait(.12)
  local nested=#records-before;parent:Destroy()
  Q.InputType=Enum.UserInputType.Touch
  before=#records;Q.Fire(b,"MouseEnter");task.wait(.12);Q.Fire(b,"MouseLeave")
  local touch=#records-before;Q.InputType=Enum.UserInputType.MouseMovement
  return {Rows=out,Nested=nested,Touch=touch,Restored=game.SoundService.UI.Hover.Volume}
 elseif action=="Disabled"then
  local g=gui();local b=g.InventoryPanel.Content.Aura.AuraList.PinkAuraCard.BuyButton
  local active,interactable=b.Active,b.Interactable;b.Active=false;b.Interactable=false
  Q.Fire(b,"MouseLeave");task.wait(.12);local before=#records
  Q.Fire(b,"MouseEnter");Q.Fire(b,"Activated");task.wait(.2);Q.Fire(b,"MouseLeave")
  local count=#records-before;b.Active=active;b.Interactable=interactable
  local parent=Instance.new("Frame");parent.Name="__UI4QALegacy";parent.Size=UDim2.fromOffset(40,40);parent.Parent=g
  local button=Instance.new("TextButton");button.Parent=parent;button.Size=UDim2.fromScale(1,1)
  local bag=require(RS.Packages.Janitor).new()
  require(p.PlayerScripts.Services.ButtonClient).attach(parent,bag)
  task.wait();local legacy=hover(button)
  button.Active=false;button.Interactable=false;before=#records
  Q.Fire(button,"MouseEnter");Q.Fire(button,"Activated");task.wait(.2)
  local legacyDisabled=#records-before;bag:Cleanup();parent:Destroy()
  return {DisabledEvents=count,Legacy=legacy,LegacyDisabledEvents=legacyDisabled}
 elseif action=="CloseOpen"then gui().InventoryPanel.Visible=false;open("Aura");return {Aura=aura(),Hover=hover(gui().InventoryPanel.Content.Aura.AuraList.PinkAuraCard.BuyButton)}
 elseif action=="Narrow"then
  local g=gui();g:SetAttribute("PanelReserveRight",g.AbsoluteSize.X-540)
  require(RS.Modules.ResponsivePanels).Fit(g.InventoryPanel,g);task.wait(.35);return aura()
 elseif action=="Normal"then local g=gui();g:SetAttribute("PanelReserveRight",nil);require(RS.Modules.ResponsivePanels).Fit(g.InventoryPanel,g);task.wait(.3);return aura()
 elseif action=="Scroll"then gui().InventoryPanel.Content.Aura.AuraList.CanvasPosition=Vector2.new(0,value);task.wait(.25);return aura()
 elseif action=="GlyphProbe"then
  local g=gui();local panel=Instance.new("Frame");panel.Name="__UI4QAGlyphProbe";panel.BackgroundColor3=Color3.new(0,0,0);panel.Size=UDim2.fromOffset(420,90);panel.Position=UDim2.new(.5,-210,1,-100);panel.ZIndex=250;panel.Parent=g
  for i,text in {"Fredoka One ABC 0123456789","あいうえお アイウエオ 強さ 装備"}do
   local l=Instance.new("TextLabel");l.Text=text;l.Font=require(RS.Config.StrengthHUDStyle).Font;l.Size=UDim2.new(1,0,0,40);l.Position=UDim2.fromOffset(0,(i-1)*40);l.TextSize=24;l.TextColor3=Color3.new(1,1,1);l.BackgroundTransparency=1;l.ZIndex=251;l.Parent=panel
  end
  return true
 elseif action=="RemoveProbe"then local q=gui():FindFirstChild("__UI4QAGlyphProbe");if q then q:Destroy()end return true
 end
end
