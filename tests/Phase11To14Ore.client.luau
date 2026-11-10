-- Append temporarily to MergePanelClient_New to exercise its actual view.
local qa=Instance.new("BindableFunction");qa.Name="__PhaseOreClient";qa.Parent=player.PlayerScripts
local cues={}
player.PlayerGui.ChildAdded:Connect(function(g)
 if g.Name=="PersonalDropReward" then
  local row={At=os.clock(),Rarity=g:FindFirstChild("Rarity") and g.Rarity.Text,Points=g:FindFirstChild("Points") and g.Points.Text}
  table.insert(cues,row)
  g.Destroying:Connect(function()row.Seconds=os.clock()-row.At end)
 end
end)
qa.OnInvoke=function(action,value)
 if action=="Show" then openShop();view:SelectTab("Ore")
 elseif action=="Hide" then view:Hide("Closed")
 elseif action=="Sell" then view:SetSellMode(true);view:ActivateMaterial(value)
 elseif action=="Add" then view:ActivateMaterial(value)
 elseif action=="Scroll" then view.List.CanvasPosition=Vector2.new(0,value)
 elseif action=="Cues" then return cues
 elseif action=="Refresh" then require(RS.Modules.ForgeClient).Refresh()
 end
 task.wait(.2)
 local labels={}
 for _,x in view.Root:GetDescendants()do if x:IsA("TextLabel") and (x.Name=="Rarity" or x.Name=="SaleRarity")then
  table.insert(labels,{Path=x:GetFullName(),Text=x.Text,Color=tostring(x.TextColor3),Fits=x.TextFits})
 end end
 return {Visible=view.Root.Visible,Labels=labels}
end
