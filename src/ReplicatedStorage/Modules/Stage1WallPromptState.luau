-- Client presentation state only; never changes combat, tutorial progress or saved data.
local M={}
M.__index=M
function M.new(owner,epoch,completed)
 return setmetatable({Owner=owner,Epoch=epoch or 0,Completed=completed==true,Sequence=0},M)
end
function M:Invalidate()
 self.Ready=false;self.Wall=nil;self.Fight=nil
end
function M:Reset(epoch)
 self.Epoch=epoch or 0;self.Completed=false;self:Invalidate()
end
function M:CurrentWall()
 local w=self.Wall
 if not self.Ready or self.Stage~=1 or not w or w.Skipped~=false
  or type(w.Current)~="number" or w.Current<1 or w.Current>4
  or type(w.Cleared)~="table" or w.Cleared[w.Current]==true
  or type(w.Gauges)~="table" or type(w.Gauges[w.Current])~="number" or w.Gauges[w.Current]<=0 then return nil end
 return w.Current
end
function M:InWallCombat()
 local index=self:CurrentWall();local f=self.Fight
 return index~=nil and f~=nil and f.Active==true and f.CombatType=="Wall" and f.Stage==1 and f.WallIndex==index
end
function M:Handle(d,character)
 if type(d)~="table" or d.OwnerUserId~=self.Owner or d.WorldId~=1
  or d.TutorialResetSequence~=self.Epoch or type(d.RunRevision)~="number"
  or type(d.MessageSequence)~="number" or d.MessageSequence<=self.Sequence then return false end
 if d.Type=="Initialize" then
  if (self.Run and d.RunRevision<self.Run) or d.Character~=character or character==nil then return false end
  self.Run=d.RunRevision;self.Ready=true;self.Stage=d.CurrentStage
  self.Wall=nil;self.Fight=d.ActiveCombat
 elseif not self.Ready or d.RunRevision~=self.Run then return false end
 self.Sequence=d.MessageSequence
 if d.Type=="WallInitialize" and type(d.State)=="table" and d.State.MajorStage==1 then
  self.Wall=d.State
 elseif d.Type=="Fighting" then
  self.Fight=d.Active==true and d or nil
 elseif d.Type=="CombatAttack" then
  -- This existing notification is emitted ONLY after accepted damage, before Carry
  -- clears/gauges. UI/input callbacks and automatic hits cannot complete this cue.
  if d.Manual==true and d.CombatType=="Wall" and d.Stage==1
   and d.WallIndex==self:CurrentWall() and self:InWallCombat() then
   self.Completed=true
  end
 elseif d.Type=="WallGauge" and d.MajorStage==1 and self.Wall then
  self.Wall.Gauges[d.Index]=d.Current
 elseif d.Type=="WallCleared" and d.MajorStage==1 then
  self.Wall=d.State;self.Fight=nil
 elseif (d.Type=="EnemyDefeated" or d.Type=="StageCleared") and d.Stage==1 then
  self.Stage=d.CurrentStage or 2;self.Wall=nil;self.Fight=nil
 end
 return true
end
function M:CanShow(c)
 return not self.Completed and c.GuideIndex==self:CurrentWall() and c.GuideIndex~=nil
  and self:InWallCombat() and c.TutorialCompleted==false and c.World==1 and c.Stage==1
  and c.AutoTap==false and c.Alive==true and c.Training~=true and c.Blocked~=true
  and c.TargetLoaded==true and c.Contact==true
end
function M.Label(preferred)
 if preferred=="Touch" then return "Tap" end
 if preferred=="KeyboardAndMouse" then return "Click" end
 return nil -- Do not advertise a mouse/touch action during gamepad-only use.
end
return M
