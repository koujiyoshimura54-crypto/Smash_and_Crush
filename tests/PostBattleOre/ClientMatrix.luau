-- Exact client observer with fake render/heartbeat, HUD, controls and GUI geometry.
return function(source)
 local checks=0
 local function check(ok,label)checks+=1;assert(ok,label)end
 local function signal()
  local s={Fns={}};function s:Connect(f)table.insert(self.Fns,f);return{Disconnect=function()end}end
  function s:Fire(...)for _,f in self.Fns do f(...)end end;return s
 end
 local function object(class,parent,children)
  local o=children or {};o.Parent=parent;o.Visible=true;o.Enabled=true;o.AbsolutePosition=Vector2.new(0,0);o.AbsoluteSize=Vector2.new(100,30);o.Text='1'
  function o:IsA(k)return k==class or k=='GuiObject'and(class=='Frame'or class=='TextLabel')end
  function o:FindFirstChild(k)return self[k]end
  return o
 end
 local function fixture()
  local f={Clock=0,Packets={},Guide=false,ReadError=false,GuideError=false}
  local remote={OnClientEvent=signal()};function remote:FireServer(action,v)table.insert(f.Packets,{Action=action,Value=table.clone(v)})end
  local pg=object('PlayerGui');local hudGui=object('ScreenGui',pg);pg.StrengthGui=hudGui
  local hud=object('Frame',hudGui);hudGui.StrengthLevelHUD=hud
  local panel=object('Frame',hud);hud.LevelPanel=panel
  local bar=object('Frame',panel);panel.StrengthProgressBar=bar
  bar.Level=object('TextLabel',bar);bar.Exp=object('TextLabel',bar)
  local total=object('Frame',hud);hud.StrengthValueContainer=total;total.Strength=object('TextLabel',total)
  local health=object('Frame',hud);hud.PlayerHealth=health;health.Exp=object('TextLabel',health)
  local auto=object('Frame',panel);panel.AutoTapButton=auto;auto.State=object('TextLabel',auto)
  local host=object('ScreenGui',pg);local shop=object('Frame',host);shop.AbsoluteSize=Vector2.new(500,400)
  local attrs={MTFSession='session',MTFDataLoaded=true,MTFNewFirstSession=true}
  local c={HumanoidRootPart={Anchored=false},Humanoid={Health=100},Attrs={LobbySpawnPlaced=true,SpawnEngineReady=true,MuscleScaleReady=true,SpawnPlacementRevision=1}}
  function c:FindFirstChild(k)return self[k]end;function c:FindFirstChildOfClass()return self.Humanoid end;function c:GetAttribute(k)return self.Attrs[k]end
  local controls={controlsEnabled=true,activeController={enabled=true}}
  local pm=object('Folder',nil,{ControlModule='controls'});local ps=object('Folder',nil,{PlayerModule=pm})
  local p={Character=c,PlayerGui=pg};function p:GetAttribute(k)return attrs[k]end
  function p:FindFirstChild(k)return k=='PlayerScripts'and ps or self[k]end
  local remotes={FirstPlayAnalytics=remote};function remotes:FindFirstChild(k)return self[k]end
  local rs={Remotes=remotes};function rs:FindFirstChild(k)return self[k]end
  local run={Heartbeat=signal(),RenderStepped=signal()}
  local service={Players={LocalPlayer=p},ReplicatedStorage=rs,RunService=run}
  local game={ReplicatedFirst={FindFirstChild=function()end},GetService=function(_,k)return service[k]end,IsLoaded=function()return true end}
  local env=setmetatable({game=game,workspace={CurrentCamera={ViewportSize=Vector2.new(960,540)}},os={clock=function()return f.Clock end},require=function()return controls end},{__index=getfenv()})
  local load=assert(loadstring(source));setfenv(load,env);f.M=load()
  f.View={Open=false,Panel=shop,Tab='Ore',Selling=false,Token='forge',Generation=0,CloseRevision=0,Materials={ORE_001=2}}
  f.M.BindOre(function()if f.ReadError then error('reader failure')end;return table.clone(f.View)end)
  f.Unbind=f.M.BindMergeGuide(function()if f.GuideError then error('guide failure')end;return f.Guide end)
  f.M.Start();f.M.Start()
  function f.Pulse(render)
   f.Clock+=.3;run.Heartbeat:Fire(.3);if render then run.RenderStepped:Fire(.3)end
  end
  function f.Ore()local rows={}for _,e in f.Packets do if e.Action=='OreView'then table.insert(rows,e.Value)end end;return rows end
  f.Attrs=attrs;f.Character=c;f.Player=p;f.Shop=shop;f.Host=host;f.Controls=controls;f.HUD=bar.Level;f.Run=run
  return f
 end
 local f=fixture();f.Guide=true;f.View.Open=true;f.Pulse(true)
 check(#f.Ore()==0,'Before outcome no Ore funnel observation')
 f.Attrs.MTFPostBattleToken='outcome';f.Pulse(false)
 check(#f.Ore()==0 and f.M.Snapshot()==nil,'Heartbeat/model state cannot claim a rendered view')
 f.Pulse(true);local v=f.Ore()[1]
 check(v and v.Ready==true and v.Open==true and v.GuideShown==true,'Rendered simultaneous facts observed together')
 check(v.PostBattleToken=='outcome'and v.Character==f.Character and v.Session=='session'and v.Rendered==true,'Current session/character/challenge attached')
 check(#f.Run.RenderStepped.Fns==1 and #f.Run.Heartbeat.Fns==1,'Repeated Start does not duplicate observers')
 check(f.M.Snapshot()~=nil,'Rendered current view can accompany ordinary merge')
 for _,cause in {'Item','Pet','Sale','Hidden','HostDisabled','Offscreen','ZeroSize'}do
  local q=fixture();q.Attrs.MTFPostBattleToken='outcome';q.View.Open=true
  if cause=='Item'or cause=='Pet'then q.View.Tab=cause elseif cause=='Sale'then q.View.Selling=true
  elseif cause=='Hidden'then q.Shop.Visible=false elseif cause=='HostDisabled'then q.Host.Enabled=false
  elseif cause=='Offscreen'then q.Shop.AbsolutePosition=Vector2.new(2000,2000)elseif cause=='ZeroSize'then q.Shop.AbsoluteSize=Vector2.zero end
  q.Pulse(true);check(q.Ore()[1].Open==false,cause..' is not rendered Ore merge view')
 end
 for _,cause in {'Dead','Anchored','DisabledControls','HUDHidden','NotPlaced'}do
  local q=fixture();q.Attrs.MTFPostBattleToken='outcome'
  if cause=='Dead'then q.Character.Humanoid.Health=0 elseif cause=='Anchored'then q.Character.HumanoidRootPart.Anchored=true
  elseif cause=='DisabledControls'then q.Controls.controlsEnabled=false elseif cause=='HUDHidden'then q.HUD.Visible=false
  elseif cause=='NotPlaced'then q.Character.Attrs.LobbySpawnPlaced=false end
  q.Pulse(true);check(q.Ore()[1].Ready==false,cause..' no post-return readiness')
 end
 for _,cause in {'Character','ForgeToken','Generation','CloseRevision','Session','OutcomeToken','NoRenderForOneSecond'}do
  local q=fixture();q.Attrs.MTFPostBattleToken='outcome';q.View.Open=true;q.Pulse(true)
  if cause=='Character'then q.Player.Character={}elseif cause=='ForgeToken'then q.View.Token='other'
  elseif cause=='Generation'then q.View.Generation=1 elseif cause=='CloseRevision'then q.View.CloseRevision=1
  elseif cause=='Session'then q.Attrs.MTFSession='other'elseif cause=='OutcomeToken'then q.Attrs.MTFPostBattleToken='other'
  else q.Clock+=2 end
  check(q.M.Snapshot()==nil,'Stale merge context rejected '..cause)
 end
 do local q=fixture();q.Attrs.MTFPostBattleToken='outcome';q.View.Open=true;q.Pulse(true)
  local first=q.M.Snapshot().ViewRevision;q.View.Open=false;q.View.CloseRevision+=1;q.Pulse(true);q.View.Open=true;q.Pulse(true)
  check(q.M.Snapshot().ViewRevision>first,'Reopened view gets new monotonic revision')
  q.Unbind();q.Pulse(true);check(q.Ore()[#q.Ore()].GuideShown==false,'Destroyed guide reader cannot report shown')end
 do local q=fixture();q.Attrs.MTFPostBattleToken='outcome';q.ReadError=true;q.Pulse(true);check(#q.Ore()==0,'Broken reader fails closed')
  q.ReadError=false;q.GuideError=true;q.Pulse(true);check(q.Ore()[1].GuideShown==false,'Broken guide reader never claims display')end
 do local q=fixture();q.Attrs.MTFPostBattleToken='outcome';for i=1,100 do q.Pulse(true)end
  check(#q.Ore()==5,'Stable observation retries bounded at five')end
 return{Passed=true,Assertions=checks,Kind='Exact client observer; fake render events, controls and GUI geometry; not physical UI'}
end
