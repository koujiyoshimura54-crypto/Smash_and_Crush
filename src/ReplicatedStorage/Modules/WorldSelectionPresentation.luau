-- Geometry uses the measured 1672x941 reference; appearance lives in the placed GUI.
local RS=game:GetService("ReplicatedStorage")
local Font=require(RS.Config.StrengthHUDStyle).Font
local M={}
function M.Layout(gui)
 local modal=gui.Modal;local panel=modal.Card
 local width,height=modal.AbsoluteSize.X,modal.AbsoluteSize.Y
 local rw=panel:GetAttribute("ReferenceWidth") or 1312
 local rh=panel:GetAttribute("ReferenceHeight") or 844
 local narrow=width<700
 local w=narrow and width*.94 or math.min(width*.786,height*.9*rw/rh)
 local h=narrow and height*.9 or w*rh/rw
 local s=w/rw
 local pad=math.max(12,(panel:GetAttribute("SidePadding") or 36)*s)
 local header=math.max(58,(panel:GetAttribute("HeaderHeight") or 104)*s)
 local bottom=math.max(12,20*s)
 local gap=math.max(9,(panel:GetAttribute("CardGap") or 15)*s)
 local cardHeight=math.max(108,(panel:GetAttribute("CardHeight") or 234)*s)
 if narrow then h=math.min(h,header+cardHeight*3+gap*2+bottom) end
 panel.Size=UDim2.fromOffset(w,h)
 panel.Title.Position=UDim2.fromOffset(pad,0)
 panel.Title.Size=UDim2.new(1,-pad*2,0,header)
 panel.Title.TextSize=math.max(30,(panel:GetAttribute("TitleTextSize") or 100)*s)
 local close=math.max(42,106*s)
 panel.Close.Position=UDim2.new(1,3*s,0,-7*s);panel.Close.Size=UDim2.fromOffset(close,close*.92)
 panel.Close.Label.TextSize=math.max(34,(panel:GetAttribute("CloseTextSize") or 85)*s)
 local list=panel.WorldList
 list.Position=UDim2.fromOffset(pad,header)
 list.Size=UDim2.new(1,-pad*2,0,math.max(40,h-header-bottom))
 list.UIListLayout.Padding=UDim.new(0,gap)
 list.CanvasSize=UDim2.fromOffset(0,cardHeight*3+gap*2)
 list.ScrollBarThickness=narrow and 4 or 0
 for _,card in list:GetChildren() do if card:IsA("Frame") then
  card.Size=UDim2.new(1,-(narrow and 5 or 0),0,cardHeight)
  card.WorldName.Position=UDim2.fromOffset(math.max(12,24*s),cardHeight*.31)
  card.WorldName.Size=UDim2.new(.64,-12,0,cardHeight*.49)
  card.WorldName.TextSize=math.max(28,(panel:GetAttribute("WorldTextSize") or 106)*s)
  local button=card.Action
  local bw=math.max(126,338*s);local bh=math.max(40,99*s)
  button.Position=UDim2.new(1,-math.max(10,21*s),1,-math.max(10,21*s))
  button.Size=UDim2.fromOffset(math.min(bw,w-pad*2-24),bh)
  button.Label.TextSize=math.max(20,(panel:GetAttribute("ButtonTextSize") or 62)*s)
  if narrow then
   card.WorldName.Position=UDim2.fromOffset(14,4);card.WorldName.Size=UDim2.new(1,-28,0,46)
  end
  local locked=button:GetAttribute("Status")=="Locked"
  button.Label.Position=UDim2.fromScale(locked and .26 or .04,.06)
  button.Label.Size=UDim2.fromScale(locked and .70 or .92,.88)
  button.Lock.Size=UDim2.fromScale(.21,.74);button.Lock.Position=UDim2.fromScale(.04,.13)
 end end
 for _,x in panel:GetDescendants() do
  if x:IsA("TextLabel") or x:IsA("TextButton") then x.Font=Font end
  if x:IsA("UIStroke") and x:GetAttribute("ReferenceThickness") then
   x.Thickness=math.max(x:GetAttribute("MinimumThickness") or 2,x:GetAttribute("ReferenceThickness")*s)
  elseif x:IsA("UICorner") and x:GetAttribute("ReferenceRadius") then
   x.CornerRadius=UDim.new(0,math.max(8,x:GetAttribute("ReferenceRadius")*s))
  end
 end
end
function M.Render(gui,state,pending)
 if type(state)~="table" then return end
 for _,row in state.Worlds or {} do
  local card=gui.Modal.Card.WorldList:FindFirstChild("World"..tostring(row.Id))
  if card then
   local status=row.Status;local button=card.Action
   button:SetAttribute("Status",status)
   button.Label.Text=status;button.Lock.Visible=status=="Locked"
   button.Active=status=="Teleport" and not pending
   button.Interactable=button.Active;button.Selectable=button.Active
   button.UIGradient.Color=gui.Appearance[status].Color
   card.LockedShade.Visible=status=="Locked"
   card.LockedShade.BackgroundTransparency=card:GetAttribute("LockedBackgroundTransparency") or .12
   card.MapPreview.ImageColor3=status=="Locked" and Color3.fromRGB(135,135,135) or Color3.new(1,1,1)
  end
 end
 M.Layout(gui)
end
return M
