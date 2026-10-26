-- Append temporarily to MergePanelClient_New so tests use its native LocalScript closure/cache.
local qa=Instance.new('BindableFunction');qa.Name='__MergeY01Client';qa.Parent=player.PlayerScripts
local narrow,narrowHost
local function snapshot(v)
 local root=v.Root;local body=root.Body;local rows={};local inputs={};local candidates={}
 local function bounds(x) return {x.AbsolutePosition.X,x.AbsolutePosition.Y,x.AbsoluteSize.X,x.AbsoluteSize.Y} end
 for _,x in body.Materials:GetChildren() do if x:IsA('GuiObject') and x.Name~='Empty' then
  table.insert(rows,{Key=x.Name,Order=x.LayoutOrder,Owned=x:GetAttribute('OwnedCount'),Selected=x:GetAttribute('SelectedCount'),Rank=x:GetAttribute('Rank'),Points=x:GetAttribute('Points'),Bounds=bounds(x),Enabled=x.Button.Interactable})
 end end
 table.sort(rows,function(a,b)return a.Order<b.Order end)
 for _,x in body.DropArea.Inputs:GetChildren() do if x:IsA('GuiObject') then table.insert(inputs,{Key=x.Name,Count=x:GetAttribute('SelectedCount'),Rank=x:GetAttribute('Rank'),Points=x:GetAttribute('Points')}) end end
 for _,x in body.Result.ResultItems:GetChildren() do if x:IsA('GuiObject') then table.insert(candidates,{ItemId=x:GetAttribute('ItemId'),Id=x:GetAttribute('ResultId'),Percent=x:GetAttribute('Percent')}) end end
 local tabs={};for _,name in {'Item','Pet','Ore'} do tabs[name]={Visible=body[name].Visible,Bounds=bounds(body[name])} end
 return {Tab=root:GetAttribute('SelectedTab'),Visible=root.Visible,Bounds=bounds(root),Rows=rows,Inputs=inputs,Candidates=candidates,Tabs=tabs,
  Selected=body.Selected.Text,Total=body.DropArea.Total.Text,Enabled=body.Merge.Interactable,Status=body.Status.Text,
  Canvas={body.Materials.CanvasPosition.Y,body.Materials.CanvasSize.Y.Offset},Footer={Clear=bounds(body.Clear),Merge=bounds(body.Merge)},
  ItemState=state,PetState=PetClient.state()}
end
qa.OnInvoke=function(op,arg)
 local v=narrow or view
 if op=='State' then return snapshot(v) end
 if op=='Show' then view:Show();refresh();view:SetPetState(PetClient.refresh() or PetClient.state());return snapshot(view) end
 if op=='Refresh' then refresh();PetClient.refresh();v:SetPetState(PetClient.state());return snapshot(v) end
 if op=='Tab' then v:SelectTab(arg);v:SetPetState(PetClient.state());return snapshot(v) end
 if op=='Clear' then v:Clear();return snapshot(v) end
 if op=='Add' then v:ActivateMaterial(arg);return snapshot(v) end
 if op=='Remove' then v:RemoveMaterial(arg);return snapshot(v) end
 if op=='Sell' then v:SetSellMode(arg);return snapshot(v) end
 if op=='Drag' then
  local row=v.List:FindFirstChild(arg);assert(row);local from=row.AbsolutePosition+row.AbsoluteSize/2
  local to=v.Drop.AbsolutePosition+v.Drop.AbsoluteSize/2
  v:PressMaterial(arg,from,false);v:MovePointer(to);v:ReleasePointer(to);return snapshot(v)
 end
 if op=='Submit' then v:SubmitItem();return true end
 if op=='Scroll' then v.List.CanvasPosition=Vector2.new(0,arg);return true end
 if op=='Travel' then RS.Remotes.WorldTravelRequest:FireServer(arg);return true end
 if op=='RejectPets' then
  local failures={}
  for _,case in {{'Duplicate',{'dog-eligible-1','dog-eligible-1'},'InvalidPetMaterials'},
   {'Unowned',{'not-owned','dog-eligible-1'},'PetNotMergeable'},
   {'Protected',{'dog-protected','dog-eligible-1'},'PetProtected'},
   {'Equipped',{'dog-equipped','dog-eligible-1'},'PetEquipped'}} do
   local before=RS.Remotes.PetRequest:InvokeServer('GetState')
   local response=RS.Remotes.PetRequest:InvokeServer('Merge',game:GetService('HttpService'):GenerateGUID(false),before.state.Revision,case[2],nil,before.generation)
   assert(not response.ok and response.reason==case[3],tostring(response.reason));failures[case[1]]=response.reason;task.wait(.8)
  end
  return failures
 end
 if op=='Narrow' then
  view:Hide();narrowHost=Instance.new('Frame');narrowHost.Name='__MergeNarrow';narrowHost.BackgroundTransparency=1
  narrowHost.Size=UDim2.fromOffset(arg.X,arg.Y);narrowHost.Position=UDim2.fromScale(.5,.5);narrowHost.AnchorPoint=Vector2.new(.5,.5);narrowHost.Parent=gui
  local donor=gui.ShopPanel:Clone();donor.Visible=false;donor.Parent=narrowHost
  for _,x in donor:GetDescendants() do if x:IsA('LuaSourceContainer') then x:Destroy() end end
  narrow=buildMergeShop({gui=narrowHost,RS=RS,PetClient=PetClient,Egg=Egg,Master=Master,ItemColors=colors,
   EggViewport=require(RS.Modules.LimitedPetViewport),Input=game:GetService('UserInputService'),GuiService=game:GetService('GuiService'),
   OnMerge=function()error('Narrow QA uses selection controls only')end})
  narrow:Show();narrow:SetItemState(state,true,false,'');narrow:SetPetState(PetClient.state());return snapshot(narrow)
 end
 if op=='EndNarrow' then narrow:Destroy();narrow=nil;narrowHost:Destroy();narrowHost=nil;view:Show();refresh();return true end
 error('Unknown QA operation '..op)
end
