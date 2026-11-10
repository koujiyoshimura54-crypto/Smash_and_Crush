-- Temporary native Play harness. Install only with the in-memory service adapter.
-- Name the LocalScript __PhaseHeadingsDriver, distinct from its BindableFunction.
-- Gallery clones the actual refreshed station children; it never modifies purchase/training code.
local P=game.Players.LocalPlayer
local Config=require(game.ReplicatedStorage.Config.TreadmillConfig)
local pg=P:WaitForChild("PlayerGui")
local api=Instance.new("BindableFunction");api.Name="__PhaseHeadings";api.Parent=pg
local function boards()
 local out={}
 for _,root in ipairs({workspace.Treadmills,workspace.World2Map.TrainingArea.TreadmillDisplays}) do
  for _,model in ipairs(root:GetChildren()) do
   local entry=Config.GetForModel(model)
   local board=model:FindFirstChild("BillboardGui") or model:FindFirstChild("StationBillboard")
   if entry and board then table.insert(out,{Model=model,Entry=entry,Board=board,World=Config.WorldForModel(model)}) end
  end
 end
 table.sort(out,function(a,b) return a.World==b.World and a.Model.Name<b.Model.Name or a.World<b.World end)
 assert(#out==14,"All 14 stations must be present")
 return out
end
api.OnInvoke=function(mode)
 local previous=pg:FindFirstChild("__PhaseHeadingsGallery");if previous then previous:Destroy() end
 if mode=="Close" then return true end
 local narrow=mode=="Narrow"
 local screen=Instance.new("ScreenGui");screen.Name="__PhaseHeadingsGallery";screen.DisplayOrder=999;screen.ResetOnSpawn=false;screen.Parent=pg
 local base=Instance.new("Frame");base.Name="Canvas";base.AnchorPoint=Vector2.new(.5,.5);base.Position=UDim2.fromScale(.5,.5)
 base.Size=UDim2.fromOffset(narrow and 440 or 1160,narrow and 630 or 590);base.BackgroundColor3=Color3.fromRGB(20,28,43);base.Parent=screen
 local title=Instance.new("TextLabel");title.BackgroundTransparency=1;title.Size=UDim2.new(1,0,0,28);title.TextColor3=Color3.new(1,1,1);title.TextSize=18
 title.Text="Actual station GUI children / "..mode;title.Parent=base
 local mounted={}
 for i,item in ipairs(boards()) do
  local source=item.Board;local entry=item.Entry
  assert(source.Multiplier.Text=="×"..entry.Multiplier.." Strength",source:GetFullName())
  local expected=not entry.RequiresPremium and (entry.RequiredRebirth or 0)>0
  if expected then assert(source.Rebirth.Amount.Text=="×"..entry.RequiredRebirth) end
  local cols=narrow and 2 or 4;local cellW=narrow and 214 or 286;local cellH=narrow and 84 or 135
  local cell=Instance.new("Frame");cell.Name="World"..item.World.."_"..item.Model.Name
  cell.BackgroundTransparency=1;cell.Size=UDim2.fromOffset(cellW,cellH);cell.Position=UDim2.fromOffset(8+(i-1)%cols*cellW,30+math.floor((i-1)/cols)*cellH);cell.Parent=base
  local heading=Instance.new("TextLabel");heading.BackgroundTransparency=1;heading.Size=UDim2.new(1,0,0,16);heading.TextColor3=Color3.fromRGB(160,185,210);heading.TextSize=12
  heading.Text="World"..item.World.." / "..item.Model.Name;heading.Parent=cell
  local render=Instance.new("Frame");render.Name="RenderedHeading";render.AnchorPoint=Vector2.new(.5,0);render.Position=UDim2.new(.5,0,0,17)
  local w=narrow and 170 or 244;render.Size=UDim2.fromOffset(w,w*source.Size.Y.Scale/source.Size.X.Scale);render.BackgroundTransparency=1;render.Parent=cell
  for _,child in ipairs(source:GetChildren()) do child:Clone().Parent=render end
  mounted[i]={Item=item,Frame=render}
 end
 task.wait(1)
 local results={Mode=mode,Count=#mounted,Rows={}}
 for _,mount in ipairs(mounted) do
  local item,frame=mount.Item,mount.Frame;local gain=frame.Multiplier;local group=frame:FindFirstChild("Rebirth")
  local out={Path=item.Board:GetFullName(),Gain=gain.Text,GainFits=gain.TextFits,GainHeight=gain.TextBounds.Y,Width=frame.AbsoluteSize.X}
  assert(gain.TextFits and gain.TextBounds.Y>=14,"Readable gain text: "..out.Path)
  if group and group.Visible then
   local icon,amount=group.Icon,group.Amount
   out.Requirement=amount.Text;out.RequirementFits=amount.TextFits;out.IconLoaded=icon.IsLoaded
   out.IconGap=amount.AbsolutePosition.X-icon.AbsolutePosition.X-icon.AbsoluteSize.X
   out.RowGap=gain.AbsolutePosition.Y-group.AbsolutePosition.Y-group.AbsoluteSize.Y
   assert(amount.TextFits and out.IconGap>=-1 and out.IconGap<12 and out.RowGap>0,"No overlapping rows or detached icon: "..out.Path)
  end
  table.insert(results.Rows,out)
 end
 return results
end
