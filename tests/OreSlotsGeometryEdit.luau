-- Edit-only device geometry; no physical input. Run OreSlotsPreviewEdit first.
local q=assert(_G.OreSlotsReview);local v=q.View
local svc=game:GetService("StudioDeviceSimulatorService")
local assertions,rows=0,{}
local function check(ok,label)assert(ok,label);assertions+=1 end
local function rect(x)local p,s=x.AbsolutePosition,x.AbsoluteSize;return {X=p.X,Y=p.Y,W=s.X,H=s.Y}end
local function within(a,b)return a.X>=b.X-.1 and a.Y>=b.Y-.1 and a.X+a.W<=b.X+b.W+.1 and a.Y+a.H<=b.Y+b.H+.1 end
local function overlap(a,b)return a.X<b.X+b.W and a.X+a.W>b.X and a.Y<b.Y+b.H and a.Y+a.H>b.Y end
for _,device in {"iphone_7","iphone_16_pro_max","ipad_pro_M5_13in","average_windows"}do
 svc:SetDeviceAsync(device);if device~="average_windows"then svc:SetOrientationAsync(Enum.ScreenOrientation.LandscapeLeft)end
 task.wait(.2)
 for _,amount in {0,1,2,5}do
  q.SetCount(amount);task.wait(.05)
  local snap=q.Snapshot();check(#snap.Slots==5,"five visible slots")
  local strip,total=rect(v.Drop.Inputs),rect(v.Drop.Total)
  local previous;local side
  for _,row in snap.Slots do
   local x=v.Drop.Inputs:FindFirstChild(row.Name);local r=rect(x);side=r.W
   check(within(r,strip),"slot not clipped")
   check(not overlap(r,total),"slot does not overlap total")
   if previous then check(not overlap(previous,r),"slots separated")end;previous=r
   local hit=x:FindFirstChild("Button")
   if hit then check((x.AbsoluteSize-hit.AbsoluteSize).Magnitude<.01 and (x.AbsolutePosition-hit.AbsolutePosition).Magnitude<.01,"input hit rectangle matches card")
   else check(not x.Active and not x.Interactable and not x.Plus.Active and not x.Plus.Interactable,"empty decoration does not capture input")end
  end
  local panel=rect(v.Root);local screen=rect(q.Gui)
  check(within(panel,screen),"panel fits safe viewport")
  local clear,merge=rect(v.ClearButton),rect(v.Merge)
  check(within(clear,panel)and within(merge,panel)and within(total,panel),"footer within panel")
  check(not overlap(total,clear)and not overlap(total,merge)and not overlap(clear,merge),"footer separated")
  check(v.Merge.Interactable==(amount>=2),"state shown correctly")
  table.insert(rows,{Device=device,Viewport=snap.Viewport,Count=amount,SlotPixels=side,ClearHeight=clear.H,MergeHeight=merge.H})
 end
end
return game.HttpService:JSONEncode({Assertions=assertions,Rows=rows})
