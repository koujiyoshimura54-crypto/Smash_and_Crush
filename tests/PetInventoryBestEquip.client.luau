-- Temporary native Studio QA. Layout and SimFollow are explicitly simulated when rendering is inactive.

local RS=game.ReplicatedStorage
local p=game.Players.LocalPlayer
local Q=require(RS.__PetQAConnections)
local Pet=require(RS.Modules.Pet)
local PC=require(p.PlayerScripts.Services.PetClient)
local function panel() return p.PlayerGui:WaitForChild("ScreenGui").Menus.Inventory end
local function label(x)
 return {Text=x.Text,Font=x.FontFace.Family,Fits=x.TextFits,Size=tostring(x.AbsoluteSize),Position=tostring(x.AbsolutePosition),Localized=x.AutoLocalize,Visible=x.Visible}
end
local function followers()
 local out={}
 for _,m in ipairs(workspace:WaitForChild("Pets"):GetChildren()) do
  local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  out[#out+1]={Id=m:GetAttribute("PetInstanceId"),Name=m:GetAttribute("PetSpeciesId"),Side=m:GetAttribute("FormationSide"),Position=root and tostring(root.CFrame:PointToObjectSpace(m:GetPivot().Position))}
 end
 return out
end
local function snapshot()
 local root=panel();local main=root.Main;local rows={}
 for _,tile in ipairs(main.Items:GetChildren()) do
  if tile:IsA("GuiObject") and tile:FindFirstChild("StrengthMultiplier") then
   table.insert(rows,{Id=tile.Name,Order=tile.LayoutOrder,Percent=tile:GetAttribute("StrengthPercent"),Title=label(tile.Title),Multiplier=label(tile.StrengthMultiplier),Size=tostring(tile.AbsoluteSize),Position=tostring(tile.AbsolutePosition),Check=tile.Main.Checkmark.Visible})
  end
 end
 table.sort(rows,function(a,b)return a.Order<b.Order end)
 return {Info=label(main["2PetsEquipInfo"]),Best=label(main.PetBestEquip.Title),Rows=rows,State=PC.state(),Followers=followers(),HeaderBottom=main["2PetsEquipInfo"].AbsolutePosition.Y+main["2PetsEquipInfo"].AbsoluteSize.Y,ListTop=main.Items.AbsolutePosition.Y,Canvas=tostring(main.Items.CanvasSize),BestEnabled=main.PetBestEquip.Button.Active}
end
local function candidates()
 local out={}
 for _,sheet in ipairs(p.PlayerGui.ScreenGui:GetChildren()) do
  if sheet:IsA("BillboardGui") and sheet:FindFirstChild("Background") and sheet.Background:FindFirstChild("Pets") then
   local rows={}
   for _,x in ipairs(sheet.Background.Pets:GetChildren()) do
    if x:IsA("ImageLabel") and x.Visible then table.insert(rows,{Name=x:GetAttribute("PetSpeciesId"),Silhouette=x:GetAttribute("PetSilhouette"),Tint=tostring(x.ImageColor3)}) end
   end
   local buttons={}
   for _,x in ipairs(sheet:GetDescendants()) do if x:IsA("TextLabel") and x.Text:find("Win") then table.insert(buttons,label(x))end end
   out[sheet.Name]={Candidates=rows,Prices=buttons}
  end
 end
 return out
end
local originalSize
local clicks=0
game.SoundService.UI.Click.Played:Connect(function()clicks+=1 end)
local probe=Instance.new("BindableFunction");probe.Name="__PetQAClient";probe.Parent=p.PlayerScripts
probe.OnInvoke=function(action,arg)
 if action=="Layout" then
  PC.hideCard()
  local r=panel();originalSize=originalSize or r.Size
  r.Size=arg and UDim2.fromOffset(arg,460) or originalSize
  -- Isolated layout measurement only when this client's render loop is inactive.
  r:FindFirstChildOfClass("UIScale").Scale=1;r.Visible=true
  local width=r.Main.Items.AbsoluteSize.X
  PC.refresh();task.wait(.3)
  local result=snapshot()
  local function overlap(a,b)
   local p1,p2,s1,s2=a.AbsolutePosition,b.AbsolutePosition,a.AbsoluteSize,b.AbsoluteSize
   return p1.X<p2.X+s2.X and p2.X<p1.X+s1.X and p1.Y<p2.Y+s2.Y and p2.Y<p1.Y+s1.Y
  end
  assert(result.HeaderBottom<result.ListTop,"Header overlaps list")
  assert(result.Info.Fits and result.Best.Fits,"Header text does not fit")
  for _,tile in ipairs(r.Main.Items:GetChildren())do
   local text=tile:FindFirstChild("StrengthMultiplier")
   if text then
    assert(text.TextFits and tile.Title.TextFits,"Card text does not fit")
    assert(not overlap(text,tile.Title) and not overlap(text,tile.Main.Icon) and not overlap(text,tile.Main.Checkmark),"Multiplier overlaps content")
   end
  end
  result.AvailableWidth=width
  return result
 elseif action=="SimFollow" then
  assert(Q.FollowStep,"Native follower callback not captured")
  for i=1,120 do Q.FollowStep(1/60);task.wait(1/60) end
  return followers()
 elseif action=="SoundClicks" then return clicks
 elseif action=="Open" then
  PC.refresh();require(p.PlayerScripts.Services.MenuClient).open("Inventory");task.wait(.5);return snapshot()
 elseif action=="Snapshot" then return snapshot()
 elseif action=="ClickBest" then
  local count=Q.Fire(panel().Main.PetBestEquip.Button,"Activated");task.wait(1)
  return {Callbacks=count,Snapshot=snapshot()}
 elseif action=="Hover" then
  PC.showCard(arg,panel());task.wait(.2);local c=panel():FindFirstChild("PetHover")
  local rows={} if c then for _,x in ipairs(c:GetDescendants()) do if x:IsA("TextLabel") then table.insert(rows,label(x))end end end
  return rows
 elseif action=="HideHover" then PC.hideCard();return true
 elseif action=="Narrow" then
  PC.hideCard();local r=panel();originalSize=originalSize or r.Size
  r.Size=UDim2.fromOffset(390,460);task.wait(.5);return snapshot()
 elseif action=="Normal" then if originalSize then panel().Size=originalSize end;task.wait(.5);return snapshot()
 elseif action=="Scroll" then panel().Main.Items.CanvasPosition=Vector2.new(0,arg);task.wait(.2);return snapshot()
 elseif action=="Reopen" then
  require(p.PlayerScripts.Services.MenuClient).close();task.wait(.2);require(p.PlayerScripts.Services.MenuClient).open("Inventory");task.wait(.3);return snapshot()
 elseif action=="Followers" then return followers()
 elseif action=="Move" then
  require(p.PlayerScripts.Services.MenuClient).close();PC.hideCard()
  local root=p.Character.HumanoidRootPart
  p.Character.Humanoid:MoveTo(root.Position+Vector3.new(0,0,12))
  task.wait(2);return followers()
 elseif action=="Turn" then
  local root=p.Character.HumanoidRootPart;p.Character:PivotTo(root.CFrame*CFrame.Angles(0,math.rad(90),0))
  task.wait(1.5);return followers()
 elseif action=="Egg" then
  PC.hideCard();require(p.PlayerScripts.Services.MenuClient).close()
  local part=require(RS.Modules.Egg).part(arg or "Basic")
  p.Character:PivotTo(CFrame.new(part.Position+Vector3.new(0,0,9)));task.wait(1);return candidates()
 elseif action=="Candidates" then PC.refresh();task.wait(.3);return candidates()
 elseif action=="Material" then
  local mount=Instance.new("Frame");mount.Name="__PetQAMaterial";mount.Visible=false;mount.Parent=p.PlayerGui.ScreenGui
  local tile,cleanup=PC.createMaterialTile("probe","Ninja",1,mount,function()end)
  local result={HasMultiplier=tile:FindFirstChild("StrengthMultiplier")~=nil,Font=tile.Title.FontFace.Family}
  cleanup();mount:Destroy();return result
 end
end
