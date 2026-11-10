-- Private native UI callback driver; requires test-only view/pressed references.
local p=game.Players.LocalPlayer;local RS=game.ReplicatedStorage;local pg=p:WaitForChild('PlayerGui')
local gui=pg:WaitForChild('StrengthGui');local hatch=require(p.PlayerScripts.Services.HatchClient)
local function rect(x)return x and {X=x.AbsolutePosition.X,Y=x.AbsolutePosition.Y,W=x.AbsoluteSize.X,H=x.AbsoluteSize.Y}end
local function status()
 local o=pg.OreMergeTutorialGui;local line=o.Canvas.Notification.Stack:FindFirstChild('PinnedLine')
 local result={Step=o:GetAttribute('Step'),Kind=o:GetAttribute('GuideKind'),Target=o:GetAttribute('Target'),Focus=rect(o.Canvas.Highlight),
 Text=line and line.Message.Text,TextFits=line and line.Message.TextFits,Outline=o.Canvas.Highlight.Outline.Thickness,
 Hatch=hatch.__PhaseStage(),Equip=pg.DumbbellEquipTutorialGui:GetAttribute('Step'),Viewport=tostring(workspace.CurrentCamera.ViewportSize),Images={}}
 local g=pg:FindFirstChild('HatchGui');if g then for _,x in g:GetDescendants()do
  if x.Name=='DumbbellResult' then table.insert(result.Images,{Id=x:GetAttribute('DumbbellId'),Image=x.Image,Visible=x.Visible,Rect=rect(x)})
  elseif x:IsA('TextLabel') and x.Text~='' then table.insert(result.Images,{Text=x.Text,Fits=x.TextFits})end
 end end
 return result
end
local b=Instance.new('BindableFunction');b.Name='__PhaseOreClient';b.Parent=RS
b.OnInvoke=function(action,v)
 local view=assert(_G.__PhaseView)
 if action=='Open' then gui.TimeRewardsPanel.Visible=false;view:Show();view:SelectTab('Ore');require(RS.Modules.ForgeClient).Refresh()
 elseif action=='Add' then view:ActivateMaterial(v)
 elseif action=='Clear' then view:Clear()
 elseif action=='Merge' then view:SubmitItem()
 elseif action=='Close' then view:Hide('Closed')
 elseif action=='Press' then hatch.__PhasePress()
 elseif action=='Cancel' then hatch.cancelOre()
 elseif action=='Narrow' then gui:SetAttribute('PanelReserveRight',gui.AbsoluteSize.X-600);require(RS.Modules.ResponsivePanels).Fit(view.Root,gui)
 elseif action=='Normal' then gui:SetAttribute('PanelReserveRight',0);require(RS.Modules.ResponsivePanels).Fit(view.Root,gui)
 elseif action=='ReplayVisual' then local f=require(RS.Modules.ForgeClient);local s=f.State;return {hatch.playCommittedDumbbell({Action='MergeOre',Id=s.Journal.Id,Sequence=s.Journal.Sequence,Token=s.Token},{Success=true,State=s})}
 elseif action~='Status' then error(action)end
 task.wait(.35);return status()
end
