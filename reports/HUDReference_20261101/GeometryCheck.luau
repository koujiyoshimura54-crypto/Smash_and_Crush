local gui=game.Players.LocalPlayer.PlayerGui.HUDReferenceRaster
local c=gui.Canvas local h=c.StrengthLevelHUD
local P=require(game.ReplicatedStorage.HUDReferenceRuntimeModules.StrengthHUDPresentation)
c.CapturePixelScale.Scale=1;c.Position=UDim2.new()
local cases={}
local function rect(x)local p,s=x.AbsolutePosition-c.AbsolutePosition,x.AbsoluteSize return {X=p.X,Y=p.Y,W=s.X,H=s.Y}end
local function overlap(a,b)return a.X<b.X+b.W-.1 and a.X+a.W>b.X+.1 and a.Y<b.Y+b.H-.1 and a.Y+a.H>b.Y+.1 end
for _,spec in {{Name="reference",W=1676,H=938},{Name="portrait",W=360,H=640},{Name="landscape",W=640,H=360},{Name="portrait-controls",W=360,H=640,Blocks={{X=0,Y=490,W=100,H=150},{X=260,Y=500,W=100,H=140}}}} do
 c.Size=UDim2.fromOffset(spec.W,spec.H)
 P.Layout(c,spec.W,spec.H,spec.Blocks)
 task.wait(.1)
 local auto=rect(h.LevelPanel.AutoTapButton)
 local pack=rect(h.StrengthPacks)
 assert(auto.X>=0 and auto.X+auto.W<=spec.W+.1,"Auto offscreen")
 assert(auto.Y>=0 and auto.Y+auto.H<=spec.H+.1,"Auto Y offscreen")
 assert(not overlap(auto,pack),"Auto overlaps pack row")
 if spec.Name~="reference" then assert(auto.W>=55.9 and auto.H>=55.9,"Auto touch size") end
 for _,block in spec.Blocks or {} do assert(not overlap(pack,block) and not overlap(auto,block),"Touch control overlap")end
 local clipped={}
 for _,x in {h.LevelPanel.StrengthProgressBar.Level,h.LevelPanel.StrengthProgressBar.Exp,h.PlayerHealth.Exp,h.StrengthValueContainer.Strength,h.StrengthValueContainer.StrengthUnit,h.LevelPanel.AutoTapButton.Title,h.LevelPanel.AutoTapButton.State} do
  if x.TextBounds.X>x.AbsoluteSize.X+2 or x.TextBounds.Y>x.AbsoluteSize.Y+2 then table.insert(clipped,x.Name)end
 end
 for _,card in h.StrengthPacks:GetChildren()do if card:IsA("Frame")then
  assert(card.Purchase.AbsoluteSize==card.AbsoluteSize,"Pack is not the full input")
  assert(card.Amount.TextBounds.X<=card.Amount.AbsoluteSize.X,"Pack text clips")
 end end
 assert(#clipped==0,"Clipped: "..table.concat(clipped,","))
 table.insert(cases,{Name=spec.Name,Canvas={spec.W,spec.H},Scale=h.ReferenceScale.Scale,HP=rect(h.PlayerHealth),Level=rect(h.LevelPanel),Packs=pack,Auto=auto,TextClipping=clipped})
end
h.StrengthValueContainer.Strength.Text="999Qi"
for _,card in h.StrengthPacks:GetChildren()do if card:IsA("Frame")then card.Amount.Text="+999Qi"end end
P.Layout(c,360,640);task.wait(.1)
assert(h.StrengthValueContainer.StrengthUnit.TextBounds.X<=h.StrengthValueContainer.StrengthUnit.AbsoluteSize.X+1,"Large Strength clips")
local large={Text=h.StrengthValueContainer.Strength.Text,Size=h.StrengthValueContainer.Strength.TextSize,PackSize=h.StrengthPacks["3724835102"].Amount.TextSize}
c.Size=UDim2.fromOffset(1676,938)
h.StrengthValueContainer.Strength.Text="0"
for id,text in {["3724835102"]="+240",["3724835678"]="+1.44K",["3724836170"]="+4.8K"}do h.StrengthPacks[id].Amount.Text=text end
h.LevelPanel.StrengthProgressBar.Level.Text="Lv.1";h.LevelPanel.StrengthProgressBar.Exp.Text="0/10"
P.SetFill(h.LevelPanel.StrengthProgressBar,0)
P.Layout(c,1676,938)
assert(not h.LevelPanel.StrengthProgressBar.FillClip.Visible,"Zero progress visible")
c.CapturePixelScale.Scale=1280/270
c.Position=UDim2.fromOffset(-400*c.CapturePixelScale.Scale,-610*c.CapturePixelScale.Scale)
return game.HttpService:JSONEncode({Cases=cases,LargeDigits=large,ZeroEmpty=true,NoPayment=true})
