-- Name this temporary LocalScript __PhaseStandDriver; no physical input is used.
-- Parent it under PlayerScripts so the native callback survives character respawn.
local p=game.Players.LocalPlayer;local RS=game.ReplicatedStorage;local pg=p:WaitForChild("PlayerGui")
local gui=pg:WaitForChild("StrengthGui");local Master=require(RS.Config.DumbbellItemMaster)
local Stand=require(RS.Config.DumbbellStandConfig);local Hatch=require(p.PlayerScripts.Services.HatchClient)
local initialCamera=workspace.CurrentCamera.CFrame;local initialType=workspace.CurrentCamera.CameraType
local function labels(root)
 local out={};for _,v in root:GetDescendants() do if v:IsA("TextLabel") and v.Text~="" then table.insert(out,{Path=v:GetFullName(),Text=v.Text,Content=v.ContentText,AutoLocalize=v.AutoLocalize})end end;return out
end
local b=Instance.new("BindableFunction");b.Name="__PhaseStandClient";b.Parent=RS
b.OnInvoke=function(action,arg)
 if action=="Ore" then
  local view=assert(_G.__PhaseView);view:Show();view:SelectTab("Ore");require(RS.Modules.ForgeClient).Refresh();task.wait(.3);view:ActivateMaterial("ORE_003");view:ActivateMaterial("ORE_003");return view:GetOreTutorialState(20)
 elseif action=="Merge" then _G.__PhaseView:SubmitItem();task.wait(.5);return Hatch.__PhaseStage()
 elseif action=="Press" then Hatch.__PhasePress();task.wait(.3);return Hatch.__PhaseStage()
 elseif action=="Names" then
  local names={};for _,item in ipairs(Master.GetSorted())do assert(not item.Name:find("Normal",1,true) and not item.Name:find("通常",1,true));table.insert(names,{Id=item.ItemId,Name=item.Name})end
  local h=pg:FindFirstChild("HatchGui");return {Locale=p.LocaleId,Names=names,Hatch=h and labels(h),Equipped=labels(gui.InventoryPanel.Content.Dumbbells.Equipped)}
 elseif action=="Inventory" then
  gui.InventoryPanel.Visible=arg~=false;gui.InventoryPanel.Content.Dumbbells.Visible=true;task.wait(.4);return labels(gui.InventoryPanel.Content.Dumbbells.Equipped)
 elseif action=="Travel" then RS.Remotes.WorldTravelRequest:FireServer(arg);task.wait(1.2);return p:GetAttribute("CurrentWorld")
 elseif action=="Snapshot" then
  local out={};for world=1,2 do local folder=Stand.GetFolder(world);for _,item in ipairs(Master.GetSorted(world))do
   local model=assert(folder[tostring(item.Grade)]);local g=assert(model:FindFirstChild("BillboardGui"));local count=0;for _,v in model:GetChildren()do if v:IsA("BillboardGui") then count+=1 end end
   assert(count==1 and g.ItemIcon.Image==item.Image and g.Price.Text=="+"..item.StrengthBonus.." Strength")
   assert(g.Amount.Main.Text==require(RS.Modules.NumberFormat).Price(item.PriceWin))
   table.insert(out,{World=world,Id=item.ItemId,Path=g:GetFullName(),Name=item.Name,Image=g.ItemIcon.Image,Status=g.Status.Text,Price=g.Amount.Main.Text,Strength=g.Price.Text,Size=tostring(g.Size),Clip=g.ClipsDescendants,Fit=g.ItemIcon.ScaleType.Name,Offset=tostring(g.StudsOffset),Boards=count})
  end end;return out
 elseif action=="Regenerate" then
  for i=1,12 do local model=Stand.GetFolder(2)[tostring(i)];model.BillboardGui:Destroy()end;task.wait(.8);return true
 elseif action=="Camera" then
  local m=Stand.GetFolder(arg.World)[tostring(arg.Index or 1)];local center=m.Press.Position+Vector3.new(0,6.5,0)
  workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable
  workspace.CurrentCamera.CFrame=CFrame.lookAt(center+Vector3.new(arg.X or 0,arg.Y or 5,arg.Z or 26),center);return tostring(workspace.CurrentCamera.ViewportSize)
 elseif action=="Gallery" then
  local old=pg:FindFirstChild("__PhaseStandGallery");if old then old:Destroy()end
  local narrow=arg=="Narrow";local screen=Instance.new("ScreenGui");screen.Name="__PhaseStandGallery";screen.DisplayOrder=999;screen.Parent=pg
  local canvas=Instance.new("Frame");canvas.Size=UDim2.fromOffset(narrow and 450 or 880,narrow and 630 or 640);canvas.Position=UDim2.fromScale(.5,.5);canvas.AnchorPoint=Vector2.new(.5,.5);canvas.BackgroundColor3=Color3.fromRGB(25,31,45);canvas.Parent=screen
  local columns=narrow and 3 or 4;local cell=narrow and 145 or 215;local width=narrow and 128 or 180;local height=narrow and 146 or 200
  for i=1,12 do
   local source=Stand.GetFolder(2)[tostring(i)].BillboardGui
   local frame=Instance.new("Frame");frame.Name="W2_"..i;frame.Size=UDim2.fromOffset(width,width);frame.Position=UDim2.fromOffset(10+(i-1)%columns*cell,24+math.floor((i-1)/columns)*height);frame.BackgroundTransparency=1;frame.ClipsDescendants=source.ClipsDescendants;frame.Parent=canvas
   local title=Instance.new("TextLabel");title.Text="World 2 / "..i;title.Size=UDim2.new(1,0,0,16);title.Position=UDim2.fromOffset(0,-18);title.BackgroundTransparency=1;title.TextColor3=Color3.new(1,1,1);title.TextSize=12;title.Parent=frame
   for _,v in source:GetChildren()do v:Clone().Parent=frame end
   -- The fixture title is outside the cloned UIListLayout's ownership.
   title.Parent=canvas;title.Position=UDim2.fromOffset(frame.Position.X.Offset,frame.Position.Y.Offset-18);title.Size=UDim2.fromOffset(width,16)
  end
  task.wait(.5);return labels(canvas)
 elseif action=="ClearGallery" then local old=pg:FindFirstChild("__PhaseStandGallery");if old then old:Destroy()end;return true
 elseif action=="RestoreCamera" then workspace.CurrentCamera.CFrame=initialCamera;workspace.CurrentCamera.CameraType=initialType;return true
 else error(action)end
end
