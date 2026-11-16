local RunService=game:GetService("RunService")
if not RunService:IsStudio()or game.PlaceId~=126576845524886 then return end
local gui=script.Parent
if not gui:IsA("ScreenGui")or gui:GetAttribute("ComparisonEnabled")~=true then return end
local container=game.ReplicatedStorage:WaitForChild("BodyComparison",10)
if not container or container:GetAttribute("Enabled")~=true then return end
local remote=container:WaitForChild("Request",10)
if not remote then return end
local player=game.Players.LocalPlayer
local levels={1,2,4,8,16,32,50,70,90,115,140}
local values={Active=false,Body="Normal",Mode="Growth",Stage=0,Height=1,Thickness=1}
local pending=false;local serial=0;local requestId;local open=true
local zoom
local transition
local buttons={}
local colors={Panel=Color3.fromRGB(24,30,43),Button=Color3.fromRGB(52,65,83),Selected=Color3.fromRGB(39,132,121),Text=Color3.fromRGB(245,248,255)}
local function corner(o,r)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 7);c.Parent=o end
local panel=Instance.new("Frame");panel.Name="Panel";panel.AnchorPoint=Vector2.new(1,0);panel.Position=UDim2.new(1,-12,0,52);panel.Size=UDim2.fromOffset(300,470);panel.BackgroundColor3=colors.Panel;panel.Parent=gui;corner(panel,10)
local title=Instance.new("TextButton");title.Name="Toggle";title.Text="Body比較 · Studio  −";title.Font=Enum.Font.GothamBold;title.TextSize=16;title.AutoLocalize=false;title.TextColor3=colors.Text;title.BackgroundTransparency=1;title.Size=UDim2.new(1,-16,0,30);title.Position=UDim2.fromOffset(8,4);title.Parent=panel
local summary=Instance.new("TextLabel");summary.Name="Summary";summary.AutoLocalize=false;summary.TextColor3=colors.Text;summary.Font=Enum.Font.Gotham;summary.TextSize=13;summary.TextWrapped=true;summary.TextXAlignment=Enum.TextXAlignment.Left;summary.BackgroundTransparency=1;summary.Size=UDim2.new(1,-20,0,38);summary.Position=UDim2.fromOffset(10,34);summary.Parent=panel
local scroll=Instance.new("ScrollingFrame");scroll.Name="Controls";scroll.Position=UDim2.fromOffset(10,77);scroll.Size=UDim2.new(1,-20,1,-87);scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0;scroll.ScrollBarThickness=4;scroll.ScrollingDirection=Enum.ScrollingDirection.Y;scroll.CanvasSize=UDim2.new();scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroll.Parent=panel
local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,6);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=scroll
local order=0
local function row(height)
 order+=1;local r=Instance.new("Frame");r.Name="Row"..order;r.Size=UDim2.new(1,-6,0,height);r.BackgroundTransparency=1;r.LayoutOrder=order;r.Parent=scroll;return r
end
local function label(text)
 local r=row(20);local l=Instance.new("TextLabel");l.Text=text;l.AutoLocalize=false;l.TextSize=13;l.Font=Enum.Font.Gotham;l.TextColor3=colors.Text;l.BackgroundTransparency=1;l.Size=UDim2.fromScale(1,1);l.TextXAlignment=Enum.TextXAlignment.Left;l.Parent=r
end
local render
local function submit(nextValues,clear)
 if pending then return end
 serial+=1;requestId=serial;pending=true
 if render then render()end
 remote:FireServer({Id=serial,Action=clear and "Clear"or "Set",Settings=nextValues,Character=player.Character})
 local token=serial
 task.delay(5,function()
  if pending and requestId==token then pending=false;render("応答待ちが終了しました。再試行できます")end
 end)
end
local function change(fields)
 local nextValues=table.clone(values)
 for k,v in fields do nextValues[k]=v end
 nextValues.Active=true;submit(nextValues)
end
local function button(parent,name,text,index,count,callback,selected)
 local b=Instance.new("TextButton");b.Name=name;b.Text=text;b.AutoLocalize=false;b.TextSize=13;b.Font=Enum.Font.GothamBold;b.TextColor3=colors.Text;b.BackgroundColor3=colors.Button
 b.Size=UDim2.new(1/count,-4,1,0);b.Position=UDim2.new((index-1)/count,2,0,0);b.Parent=parent;corner(b)
 b.Activated:Connect(function()if not pending then callback()end end)
 table.insert(buttons,{Object=b,Selected=selected})
 return b
end
local r=row(33)
for i,kind in {"Normal","Muscle"}do button(r,kind,kind=="Normal"and "通常Body"or "筋肉Body",i,2,function()change({Body=kind})end,function()return values.Body==kind end)end
r=row(31)
for i,mode in {"Growth","Manual"}do button(r,mode,mode=="Growth"and "成長段階"or "手動倍率",i,2,function()change({Mode=mode})end,function()return values.Active and values.Mode==mode end)end
label("成長段階（実LV・Strengthは変更しません）")
r=row(31)
for i,stage in {0,5,10}do button(r,"LV"..levels[stage+1],"LV"..levels[stage+1],i,3,function()change({Mode="Growth",Stage=stage})end,function()return values.Active and values.Mode=="Growth"and values.Stage==stage end)end
for _,list in {{1,2,3,4},{6,7,8,9}}do
 r=row(29)
 for i,stage in list do button(r,"LV"..levels[stage+1],tostring(levels[stage+1]),i,4,function()change({Mode="Growth",Stage=stage})end,function()return values.Active and values.Mode=="Growth"and values.Stage==stage end)end
end
local entries={}
for _,spec in {{Key="Height",Text="身長",Max=10,Step=.01},{Key="Thickness",Text="太さ",Max=10,Step=.01}}do
 r=row(34)
 local l=Instance.new("TextLabel");l.Text=spec.Text;l.AutoLocalize=false;l.TextSize=13;l.Font=Enum.Font.Gotham;l.TextColor3=colors.Text;l.BackgroundTransparency=1;l.Size=UDim2.fromOffset(44,34);l.Parent=r
 local group=Instance.new("Frame");group.Size=UDim2.new(1,-46,1,0);group.Position=UDim2.fromOffset(46,0);group.BackgroundTransparency=1;group.Parent=r
 button(group,spec.Key.."Minus","−",1,3,function()change({Mode="Manual",[spec.Key]=math.clamp(math.round((values[spec.Key]-spec.Step)*100)/100,1,spec.Max)})end)
 local box=Instance.new("TextBox");box.Name=spec.Key;box.ClearTextOnFocus=false;box.Font=Enum.Font.GothamBold;box.TextSize=14;box.TextColor3=colors.Text;box.BackgroundColor3=Color3.fromRGB(36,44,59);box.Size=UDim2.new(1/3,-4,1,0);box.Position=UDim2.new(1/3,2,0,0);box.Parent=group;corner(box)
 entries[spec.Key]=box
 box.FocusLost:Connect(function()
  if pending then render();return end
  local n=tonumber((box.Text:gsub("[xX×]","")))
  if n and n==n and n>=1 and n<=spec.Max then change({Mode="Manual",[spec.Key]=math.round(n*100)/100})else render("身長・太さとも1～10で入力してください")end
 end)
 button(group,spec.Key.."Plus","＋",3,3,function()change({Mode="Manual",[spec.Key]=math.clamp(math.round((values[spec.Key]+spec.Step)*100)/100,1,spec.Max)})end)
end
label("プリセット：身長 × 太さ")
local presets={{1,1},{1.75,3},{2.75,5},{4,7},{5,10}}
for _,range in {{1,2,3},{4,5}}do
 r=row(31)
 for i,index in range do local preset=presets[index];button(r,"Preset"..index,string.format("%.2f × %d",preset[1],preset[2]),i,#range,function()change({Mode="Manual",Height=preset[1],Thickness=preset[2]})end)end
end
r=row(34);button(r,"Clear","比較解除・通常の表示へ",1,1,function()submit(nil,true)end)
local statusRow=row(36)
local status=Instance.new("TextLabel");status.Name="Status";status.AutoLocalize=false;status.TextColor3=Color3.fromRGB(190,223,207);status.Font=Enum.Font.Gotham;status.TextSize=12;status.TextWrapped=true;status.BackgroundTransparency=1;status.Size=UDim2.fromScale(1,1);status.Parent=statusRow
local function layoutPanel()
 local size=gui.AbsoluteSize
 panel.Size=UDim2.fromOffset(math.min(300,math.max(230,size.X-24)),open and math.min(486,math.max(170,size.Y-68))or 76)
 scroll.Visible=open;title.Text=open and "Body比較 · Studio  −"or "Body比較 · Studio  ＋"
end
local function updateZoom()
 if values.Active then
  if not zoom then zoom={Min=player.CameraMinZoomDistance,Max=player.CameraMaxZoomDistance}end
  player.CameraMaxZoomDistance=math.max(zoom.Max,220)
 elseif zoom then
  player.CameraMinZoomDistance=zoom.Min;player.CameraMaxZoomDistance=zoom.Max;zoom=nil
 end
end
render=function(message)
 local body=values.Body=="Muscle"and "筋肉Body"or "通常Body"
 summary.Text=not values.Active and "通常Body · 保存済みの表示設定"or(values.Mode=="Growth"and(body.." · LV"..levels[values.Stage+1].."相当")or string.format("%s · 身長 %.2f倍 / 太さ %.2f倍",body,values.Height,values.Thickness))
 for _,b in buttons do b.Object.Active=not pending;b.Object.AutoButtonColor=not pending;b.Object.BackgroundColor3=b.Selected and b.Selected()and colors.Selected or colors.Button;b.Object.TextTransparency=pending and .4 or 0 end
 for key,box in entries do if not box:IsFocused()then box.Text=string.format("%.2f",values[key])end;box.TextEditable=not pending end
 status.Text=message or(pending and "変更中…"or"表示のみ比較。ホイールで手動ズームできます")
 layoutPanel();updateZoom()
end
title.Activated:Connect(function()open=not open;layoutPanel()end)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutPanel)
remote.OnClientEvent:Connect(function(result)
 if typeof(result)~="table"or typeof(result.Settings)~="table"then return end
 if result.Code=="Prepare"then
  local c=result.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
  if c~=player.Character or not h or h.Health<=0 then return end
  if transition then return end
  local record={Token=result.Token,Character=c,Humanoid=h,Restore=result.RestoreNeck}
  transition=record;pending=true;requestId=result.RequestId
  h.RequiresNeck=false
  c.HumanoidRootPart.Anchored=true
  record.Connection=h:GetPropertyChangedSignal("RequiresNeck"):Connect(function()if transition==record and h.RequiresNeck then h.RequiresNeck=false end end)
  remote:FireServer({Action="Prepared",Token=result.Token,Character=c})
 elseif result.Code=="Commit"then
  local record=transition
  if not record or record.Token~=result.Token or record.Character~=result.Character then return end
  record.Revision=result.Revision
  task.spawn(function()
   local deadline=os.clock()+2.8;local stable=0;local c=record.Character
   while transition==record and record.Revision==result.Revision and player.Character==c and record.Humanoid.Health>0 and os.clock()<deadline do
    local ready=true;local count=0
    for _,name in {"UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot"}do
     local part=c:FindFirstChild(name)
     if not part or(part:GetAttribute("ComparisonPoseRevision")or 0)<result.Revision then ready=false else count+=1 end
    end
    local neck=c:FindFirstChild("Head")and c.Head:FindFirstChild("Neck")
    local linked,validNeck=pcall(function()return neck.Part0==c.UpperTorso and neck.Part1==c.Head end)
    ready=ready and count==14 and linked and validNeck
    stable=ready and stable+1 or 0
    if stable>=3 then remote:FireServer({Action="Ready",Token=record.Token,Character=c,Revision=result.Revision});return end
    RunService.Heartbeat:Wait()
   end
   if transition==record and record.Revision==result.Revision then remote:FireServer({Action="ClientFailed",Token=record.Token,Character=c})end
  end)
 elseif result.Code=="Release"then
  local record=transition
  if record and record.Token==result.Token then
   record.Connection:Disconnect();transition=nil
   if record.Humanoid.Parent and typeof(record.Restore)=="boolean"then record.Humanoid.RequiresNeck=record.Restore end
   if record.Character==player.Character and typeof(result.RestoreAnchor)=="boolean"then record.Character.HumanoidRootPart.Anchored=result.RestoreAnchor end
  end
  pending=false
 end
 values=result.Settings
 if result.RequestId==requestId and(result.Code=="Success"or result.Code=="Failed"or result.Code=="Invalid"or result.Code=="Unavailable"or result.Code=="Busy")then pending=false end
 if result.Code=="Success"then render("変更完了")
 elseif result.Code=="Failed"or result.Code=="Invalid"or result.Code=="Unavailable"or result.Code=="Busy"then render(result.Message)
 else render()end
end)
gui.Destroying:Connect(function()
 if transition then transition.Connection:Disconnect();if transition.Humanoid.Parent and typeof(transition.Restore)=="boolean"then transition.Humanoid.RequiresNeck=transition.Restore end;transition=nil end
 if zoom then player.CameraMinZoomDistance=zoom.Min;player.CameraMaxZoomDistance=zoom.Max end
end)
render()
remote:FireServer({Action="Get"})
