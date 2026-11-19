-- Bounded existing-board renderer. No clock, entitlement, purchase or award code.
local Style=require(game.ReplicatedStorage.Config.World1PremiumTreadmillEventStyle)
local M={}
local function set(o,k,v) if o[k]~=v then o[k]=v end end
local function stroke(label,thickness)
 local s=label:FindFirstChildOfClass("UIStroke")
 if not s then s=Instance.new("UIStroke");s.Parent=label end
 set(s,"StrokeSizingMode",Style.StrokeSizingMode)
 set(s,"Color",Style.StrokeColor);set(s,"Thickness",thickness)
 set(s,"Transparency",0);set(s,"Enabled",true)
 return s
end
local function labelStyle(label,size,color)
 set(label,"Font",Style.Font);set(label,"TextSize",size);set(label,"TextColor3",color)
 set(label,"TextScaled",false);set(label,"TextWrapped",false)
 set(label,"TextTransparency",0);set(label,"TextStrokeTransparency",1)
 set(label,"BackgroundTransparency",1);set(label,"RichText",false)
 set(label,"AutoLocalize",false);stroke(label,Style.StrokeThickness)
end
function M.BindBoard(model,createMissing)
 local board=model and model:FindFirstChild("Board")
 local frame=model and model:FindFirstChild("Part")
 local gui=board and board:FindFirstChild("SurfaceGui")
 local a=gui and gui:FindFirstChild("Event1")
 local b=gui and gui:FindFirstChild("Event2")
 local c=gui and gui:FindFirstChild("Event3")
 local layout=gui and gui:FindFirstChildOfClass("UIListLayout")
 if not (board and frame and gui and a and b and c and layout) then return nil end
 -- Clients wait for the authored descendants: creating them during partial
 -- streaming could duplicate a later replicated padding/stroke/label.
 if createMissing==false and (not gui:FindFirstChild("PremiumEventPadding")
  or not a:FindFirstChildOfClass("UIStroke") or not b:FindFirstChildOfClass("UIStroke")
  or not c:FindFirstChildOfClass("UIStroke")) then return nil end
 labelStyle(a,Style.TitleTextSize,Style.White);labelStyle(b,Style.FreeTextSize,Style.FreeColor)
 labelStyle(c,Style.TimeTextSize,Style.White)
 set(a,"Text","Premium Treadmill");set(b,"Text","Free");set(c,"Text","")
 for i,r in {{a,Style.TitleHeight},{b,Style.FreeHeight},{c,Style.TimeHeight}} do
  set(r[1],"Size",UDim2.fromScale(Style.RowWidth,r[2]));set(r[1],"LayoutOrder",i)
  set(r[1],"AnchorPoint",Vector2.zero)
 end
 set(layout,"SortOrder",Enum.SortOrder.LayoutOrder)
 set(layout,"HorizontalAlignment",Enum.HorizontalAlignment.Center)
 set(layout,"VerticalAlignment",Enum.VerticalAlignment.Top)
 set(layout,"Padding",UDim.new(Style.RowGap,0))
 local pad=gui:FindFirstChild("PremiumEventPadding")
 if not pad then pad=Instance.new("UIPadding");pad.Name="PremiumEventPadding";pad.Parent=gui end
 set(pad,"PaddingTop",UDim.new(Style.TopPadding,0))
 local texture=board:FindFirstChildOfClass("Texture")
 if texture then set(texture,"Transparency",1) end
 return {Model=model,Board=board,Frame=frame,Gui=gui,Title=a,Free=b,Time=c,
  TimeStroke=c:FindFirstChildOfClass("UIStroke")}
end
function M.DrawBoard(ref,p)
 if not ref then return end
 for _,part in {ref.Board,ref.Frame} do
  set(part,"Color",Style.BoardColor)
  set(part,"Transparency",p.BoardVisible and Style.BoardTransparency or 1)
 end
 set(ref.Gui,"Enabled",p.BoardVisible)
 set(ref.Title,"Visible",p.BoardVisible);set(ref.Free,"Visible",p.BoardVisible)
 set(ref.Time,"Visible",p.BoardVisible and p.TimeVisible)
 set(ref.Time,"Text",p.BoardTime)
 set(ref.Time,"TextColor3",p.Open and Style.OpenColor or Style.White)
 set(ref.TimeStroke,"Thickness",p.Open and Style.OpenStrokeThickness or Style.StrokeThickness)
end
function M.BindOverhead(model,createMissing)
 local area=model and model:FindFirstChild("Area")
 if not area or not area:IsA("BasePart") then return nil end
 local gui=area:FindFirstChild("PremiumEventCountdown")
 if createMissing==false and (not gui or not gui:FindFirstChild("Time")
  or not gui.Time:FindFirstChildOfClass("UIStroke")) then return nil end
 if not gui then gui=Instance.new("BillboardGui");gui.Name="PremiumEventCountdown";gui.Enabled=false;gui.Parent=area end
 set(gui,"Adornee",area);set(gui,"StudsOffset",Vector3.zero)
 set(gui,"StudsOffsetWorldSpace",Style.OverheadOffset)
 set(gui,"Size",UDim2.fromOffset(Style.OverheadSize.X,Style.OverheadSize.Y))
 set(gui,"MaxDistance",Style.OverheadMaxDistance);set(gui,"AlwaysOnTop",false);set(gui,"LightInfluence",0)
 local text=gui:FindFirstChild("Time")
 if not text then text=Instance.new("TextLabel");text.Name="Time";text.Parent=gui end
 labelStyle(text,Style.OverheadTextSize,Style.OpenColor)
 set(text,"Size",UDim2.fromScale(1,1));set(text,"Text","")
 return {Model=model,Area=area,Gui=gui,Time=text}
end
function M.DrawOverhead(ref,p)
 if not ref then return end
 set(ref.Time,"Text",p.OverheadTime)
 set(ref.Gui,"Enabled",p.Open)
end
return table.freeze(M)
