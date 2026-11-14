-- Temporary client fixture, after memory isolation and native Play helpers.
assert(game:GetService('RunService'):IsStudio() and game.ReplicatedStorage:FindFirstChild('__FirstBattleMemory'))
local p=game.Players.LocalPlayer
local B=require(game.ReplicatedStorage.Modules.World1BossPresentation)
local q=game.ReplicatedStorage.__Stage2MotionQA
local f=Instance.new('BindableFunction');f.Name='Lifecycle';f.Parent=q
local function rig()local e=workspace.Enemies['Owner_'..p.UserId].Stage02_Enemy;return e,e.TralaleroTralalaRig end
local saved
f.OnInvoke=function(action)
 local e,r=rig()
 if action=='HideShow'then
  B.SetVisible(e,false);task.wait(.1)
  local hidden={Tracks=#r.AnimationController.Animator:GetPlayingAnimationTracks(),WeldY=r.RootPart.Stage02VisualRootWeld.C0.Y}
  B.SetVisible(e,true);task.wait(.4)
  return {Hidden=hidden,ShownTracks=#r.AnimationController.Animator:GetPlayingAnimationTracks()}
 elseif action=='Partial'then
  local foot=r.FakeRootPart['Arms.L.002'];local parent=foot.Parent;foot.Parent=nil;task.wait(.35)
  local missing=#r.AnimationController.Animator:GetPlayingAnimationTracks()
  foot.Parent=parent;task.wait(.4)
  return {MissingTracks=missing,RestoredTracks=#r.AnimationController.Animator:GetPlayingAnimationTracks(),FootReturned=foot.Parent==parent}
 elseif action=='Remember'then saved={Rig=r,Animator=r.AnimationController.Animator};return true
 elseif action=='Previous'then local ok,n=pcall(function()return #saved.Animator:GetPlayingAnimationTracks()end);return {PreviousParent=saved.Rig.Parent~=nil,PreviousTracks=ok and n or 'destroyed',CurrentTracks=#r.AnimationController.Animator:GetPlayingAnimationTracks(),SameRig=r==saved.Rig,OldAnimatorParent=saved.Animator.Parent~=nil,OldTracks=(function()local t={};for _,v in saved.Animator:GetPlayingAnimationTracks()do table.insert(t,{Name=v.Name,Playing=v.IsPlaying,Time=v.TimePosition,Weight=v.WeightCurrent,Parent=v.Parent~=nil})end;return t end)()}
 end
end
