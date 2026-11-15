assert(game.PlaceId==126576845524886 and game.GameId==10765181857 and game:GetService("RunService"):IsStudio())
local RS=game.ReplicatedStorage;local q=RS:WaitForChild("__ThreeFixQA");local p=game.Players.LocalPlayer
local Master=require(RS.Config.ItemMaster);local frames=0
game:GetService("RunService").RenderStepped:Connect(function()frames+=1 end)
local loaded={};local images={}
for _,item in Master.GetAll()do if not item.WorldId then table.insert(images,item.Image)end end
task.spawn(function()
 -- Instance-based preload selects the image content path. Raw-string preload returned false negatives in Studio.
 local probes={};for _,uri in images do local x=Instance.new("ImageLabel");x.Image=uri;table.insert(probes,x)end
 local ok,err=pcall(function()game:GetService("ContentProvider"):PreloadAsync(probes,function(id,status)loaded[id]=status.Name end)end)
 for _,x in probes do x:Destroy()end
 q:SetAttribute("ImageLoadsDone",true);q:SetAttribute("ImageLoadError",not ok and tostring(err)or nil)
end)
local call=Instance.new("BindableFunction");call.Name="Client";call.Parent=q
call.OnInvoke=function(action,value)
 local pg=p.PlayerGui
 if action=="Gallery"then
  local old=pg:FindFirstChild("__ThreeFixGallery");if old then old:Destroy()end
  if value then
   local g=Instance.new("ScreenGui");g.Name="__ThreeFixGallery";g.DisplayOrder=2000;g.IgnoreGuiInset=true;g.Parent=pg
   local f=Instance.new("Frame");f.Size=UDim2.fromScale(.9,.84);f.Position=UDim2.fromScale(.05,.08);f.BackgroundColor3=Color3.fromRGB(36,44,56);f.Parent=g
   local title=Instance.new("TextLabel");title.Size=UDim2.fromScale(1,.08);title.BackgroundTransparency=1;title.Text=value.." / 01 Common -> 05 Legendary";title.TextColor3=Color3.new(1,1,1);title.TextScaled=true;title.Parent=f
   for row,kind in {"Protein","Glove","TrainingBelt"}do for col,rarity in Master.Rarities do
    local item=Master.Get(Master.Id(kind,rarity,value))
    local icon=Instance.new("ImageLabel");icon.Name=kind..rarity;icon.Size=UDim2.fromScale(.19,.27);icon.Position=UDim2.fromScale((col-1)*.2,(row-1)*.30+.09)
    icon.BackgroundTransparency=1;icon.Image=item.Image;icon.ScaleType=Enum.ScaleType.Fit;icon.Parent=f
   end end
  end
 elseif action=="MoveShop"then
  local c=p.Character;local a=workspace.RestockShop.Area;c.Humanoid:MoveTo(Vector3.new(a.Position.X,c.HumanoidRootPart.Position.Y,a.Position.Z))
 elseif action=="Inventory"then pg.StrengthGui.InventoryPanel.Visible=true
 elseif action=="Close"then pg.StrengthGui.InventoryPanel.Visible=false;pg.StrengthGui.ShopPanel.Visible=false
 elseif action~="Inspect"then error("Unknown action")end
 local visible={}
 for _,o in pg:GetDescendants()do if o:IsA("ImageLabel")or o:IsA("ImageButton")then
  if o.Visible and table.find(images,o.Image)then
   local showing=true;local a=o.Parent
   while a and a~=pg do if a:IsA("GuiObject")and not a.Visible then showing=false;break end;if a:IsA("ScreenGui")and not a.Enabled then showing=false;break end;a=a.Parent end
   if showing then table.insert(visible,{Path=o:GetFullName(),Image=o.Image,Loaded=o.IsLoaded,Size=tostring(o.AbsoluteSize),Position=tostring(o.AbsolutePosition),ScaleType=o.ScaleType.Name})end
  end
 end end
 return {Frames=frames,Viewport=tostring(workspace.CurrentCamera.ViewportSize),ImageLoads=loaded,LoadDone=q:GetAttribute("ImageLoadsDone"),Error=q:GetAttribute("ImageLoadError"),Visible=visible}
end
