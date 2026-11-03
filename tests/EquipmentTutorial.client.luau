-- Temporary native callbacks and observation, no physical/OS input.
local RS=game.ReplicatedStorage;local p=game.Players.LocalPlayer;local pg=p:WaitForChild("PlayerGui")
local gui=pg:WaitForChild("StrengthGui");local panel=gui:WaitForChild("InventoryPanel")
local history={},{};local replies={}
for _,name in {"ItemEquipRequest","DumbbellEquipRequest"} do RS.Remotes[name].OnClientEvent:Connect(function(r)table.insert(replies,{Remote=name,Success=r.Success,Code=r.Code})end)end
local function rect(x)return x and {X=x.AbsolutePosition.X,Y=x.AbsolutePosition.Y,W=x.AbsoluteSize.X,H=x.AbsoluteSize.Y}end
local function status()
 local result={Guides={},Buttons={},Replies=replies,Panel=rect(panel)}
 for _,kind in {"Item","Dumbbell"} do
  local o=pg[kind.."EquipTutorialGui"];local line=o.Canvas.Notification.Stack:FindFirstChild("PinnedLine")
  result.Guides[kind]={Step=o:GetAttribute("Step"),Target=o:GetAttribute("Target"),Focus=rect(o.Canvas.Highlight),Visible=o.Canvas.Highlight.Visible,
   Text=line and line.Message.Text,Fits=line and line.Message.TextFits,Outline=o.Canvas.Highlight.Outline.Thickness,Shadow=o.Canvas.Highlight.Shadow.Transparency}
  local eq=panel.Content[kind=="Item" and "Items" or "Dumbbells"].Equipped
  local b=kind=="Item" and eq:FindFirstChild("EquipmentHeader") and eq.EquipmentHeader:FindFirstChild("BestEquipButton") or eq:FindFirstChild("BestEquipButton")
  if b then local visual=b:FindFirstChild("PurchasedButtonVisual");local main=visual and visual.Main or b;local label=main:FindFirstChild("Amount") or b:FindFirstChild("Label")
   local texts={} for _,x in b:GetDescendants()do if (x:IsA("TextLabel")or x:IsA("TextButton"))and x.Visible and x.TextTransparency<1 and x.Text~="" then table.insert(texts,{Text=x.Text,Path=x:GetFullName(),Fits=x.TextFits,Rect=rect(x)})end end
   local gradient=main:FindFirstChildOfClass("UIGradient")
   result.Buttons[kind]={Rect=rect(b),Active=b.Active,Interactable=b.Interactable,Text=label and label.Text,Texts=texts,Gradient=gradient and tostring(gradient.Color)}
  end
 end
 result.Ore=pg.OreMergeTutorialGui:GetAttribute("Step");result.Egg=pg.EggPetTutorialGui:GetAttribute("Step")
 local bell=panel.Content.Dumbbells
 result.Bell={Badge=rect(bell.Equipped.EquippedBadge),Preview=rect(bell.Equipped.Preview),Effect=rect(bell.Equipped.Multiplier),Text=bell.Equipped.Multiplier.Text}
 return result
end
local probe=Instance.new("BindableFunction");probe.Name="__EquipQAClient";probe.Parent=RS
probe.OnInvoke=function(action,v)
 if action=="Open" then _G.__EquipQAOpen(v or "Dumbbells")
 elseif action=="Tab" then _G.__EquipQACallbacks[panel.Tabs[v]]()
 elseif action=="Close" then _G.__EquipQACallbacks[panel.CloseButton]()
 elseif action=="Best" then
  local b=v=="Item" and panel.Content.Items.Equipped.EquipmentHeader.BestEquipButton or panel.Content.Dumbbells.Equipped.BestEquipButton
  assert(b.Active and b.Interactable);_G.__EquipQACallbacks[b]()
 elseif action=="Item" then _G.__EquipQAItem(v)
 elseif action=="RawBell" then RS.Remotes.DumbbellEquipRequest:FireServer(v.Id,nil,v.Token)
 elseif action=="RawItem" then RS.Remotes.ItemEquipRequest:FireServer(v.Id,v.Action or "Equip",v.Token)
 elseif action=="Burst" then for i=1,5 do RS.Remotes.DumbbellEquipRequest:FireServer("__BestEquip",nil,p:GetAttribute("ForgeSessionToken"))end
 elseif action=="Narrow" then gui:SetAttribute("PanelReserveRight",gui.AbsoluteSize.X-650);require(RS.Modules.ResponsivePanels).Fit(panel,gui)
 elseif action=="Normal" then gui:SetAttribute("PanelReserveRight",0);require(RS.Modules.ResponsivePanels).Fit(panel,gui)
 elseif action=="Refresh" then _G.__EquipQAOpen(panel:GetAttribute("SelectedTab") or "Dumbbells")
 elseif action=="Notify" then require(p.PlayerScripts.Services.NotifyClient).push({{text="QA notification"}})
 elseif action=="Hit" then
  local eq=panel.Content[v=="Item" and "Items" or "Dumbbells"].Equipped;local b=v=="Item" and eq.EquipmentHeader.BestEquipButton or eq.BestEquipButton
  local point=b.AbsolutePosition+b.AbsoluteSize/2;local hits={}
  for _,x in pg:GetGuiObjectsAtPosition(point.X,point.Y) do if x.Active and x.Interactable then table.insert(hits,x:GetFullName())end end;return hits
 elseif action=="PetRefresh" then require(p.PlayerScripts.Services.PetClient).refresh()
 elseif action=="ShowMerge" then local view=assert(_G.__EquipQAMerge);view:Show();view:SelectTab("Ore");require(RS.Modules.ForgeClient).Refresh()
 elseif action=="AddOre" then _G.__EquipQAMerge:ActivateMaterial(v or "ORE_001")
 elseif action=="Merge" then _G.__EquipQAMerge:SubmitItem()
 elseif action=="HideMerge" then _G.__EquipQAMerge:Hide("Closed")
 elseif action=="MergeState" then local s=_G.__EquipQAMerge:GetOreTutorialState();s.MaterialTarget=s.MaterialTarget and s.MaterialTarget.Name;return s
 elseif action~="Status"then error(action)end
 task.wait(.35);return status()
end
print("[Equipment QA] native client ready")
