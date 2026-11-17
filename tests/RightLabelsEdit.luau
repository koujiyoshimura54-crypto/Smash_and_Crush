-- Native labels/template, no gameplay startup or external calls.
return function(loadModule)
 local RS=game.ReplicatedStorage
 local mod=loadModule(RS.Modules.DumbbellStandPresentation)
 local format=loadModule(RS.Modules.NumberFormat)
 local template=RS.DumbbellStandBillboardTemplate
 local result={Assertions=0,Stands=0}
 local function check(v,m)result.Assertions+=1;assert(v,m)end
 for world=1,2 do local folder=loadModule(RS.Config.DumbbellStandConfig).GetFolder(world)
  for _,stand in folder:GetChildren()do
   local b=stand:FindFirstChild("BillboardGui")
   if b and tonumber(stand.Name) then
    check(not b.Amount.Visible,"hidden Win cost")
    check(b.Price.Font==Enum.Font.FredokaOne and b.Price.TextScaled,"numeric style")
    check(b.Price.Text:sub(1,1)=="+" and not b.Price.Text:find(" ") and not b.Price.Text:find("Strength"),"plus and number only")
    check(b.Status.Text=="" and not b.Status.Visible,"numeric-only stand")
    check(b.Price.NumericScale.Scale==1.5,"75 percent of previous double rendering")
    result.Stands+=1
   end
  end
 end
 local board=template:Clone()
 for _,status in {"Owned","Equipped","Step to buy"}do board.Status.Text=status;board.Status.Visible=true
  for _,value in {1,1000,1200,1000000,1e18}do mod.ApplyValue(board,value)
   check(board.Price.Text=="+"..format.Format(value),"prefix and common formatter")
   check(not board.Amount.Visible,"no cost restored")
   check(board.Status.Text=="" and not board.Status.Visible,"all status captions hidden")
  end
 end
 local count=#board:GetDescendants()
 for i=1,100 do mod.Apply(board);mod.ApplyValue(board,1200)end
 check(#board:GetDescendants()==count,"no style object growth")
 check(not board.Amount.Visible and board.Status.Text~="Step to buy","regenerated template hidden")
 result.Template=true;board:Destroy()
 local source=game.StarterPlayer.StarterPlayerScripts.Combat.CombatClient.Source
 check(source:find('NumberFormat.Format(reward).." Win"',1,true)~=nil and source:find('NumberFormat.Format(d.WinReward).." Win"',1,true)~=nil,"both worlds share formatted Trophy renderer")
 local rewards=game.ServerScriptService.Services.TrophyRewardService
 check(shared.RightHudWalkwayStrengthBaseline.sources[rewards].source==rewards.Source,"reward service unchanged")
 result.Formats={format.Format(1000),format.Format(1500),format.Format(1000000),format.Format(1750000)}
 return result
end
