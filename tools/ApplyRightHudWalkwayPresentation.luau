-- Run in the target Edit DataModel after syncing the accompanying sources.
-- Does not save/publish, run gameplay, move models, or create test fixtures.
return function(loadModule)
 assert(game.PlaceId==126576845524886 and game.GameId==10765181857,"Wrong copy")
 assert(not game:GetService("RunService"):IsRunning(),"Edit only")
 loadModule=loadModule or require
 local RS=game.ReplicatedStorage
 local stands=loadModule(RS.Config.DumbbellStandConfig)
 local master=loadModule(RS.Config.DumbbellItemMaster)
 local labels=loadModule(RS.Modules.DumbbellStandPresentation)
 local format=loadModule(RS.Modules.NumberFormat)
 local result={Dumbbells={},Trophies={}}
 for world=1,2 do
  local folder=stands.GetFolder(world)
  if folder then for _,stand in folder:GetChildren() do
   local item=master.Get(stand:GetAttribute("ItemId") or stands.GetItemId(tonumber(stand.Name),world))
   local board=stand:FindFirstChild("BillboardGui")
   if item and board then labels.ApplyValue(board,item.StrengthBonus);table.insert(result.Dumbbells,{Path=board:GetFullName(),Text=board.Price.Text}) end
  end end
 end
 local template=RS:FindFirstChild("DumbbellStandBillboardTemplate")
 if template then
  local value=tonumber(template.Price.Text:match("[%d.]+"))
  labels.ApplyValue(template,value)
 end
 for _,mapName in {"GeneratedMap","World2Map"} do
  local map=workspace:FindFirstChild(mapName);local corridor=map and map:FindFirstChild("BattleCorridor")
  if corridor then for _,stage in corridor:GetChildren() do
   local button=stage:FindFirstChild("TrophyNormalButton")
   local amount=button and button:FindFirstChild("Amount",true)
   local raw=amount and amount.Text:match("^%+(%d+) Win$")
   if raw then amount.Text="+"..format.Format(tonumber(raw)).." Win";table.insert(result.Trophies,{Path=amount:GetFullName(),Text=amount.Text}) end
  end end
 end
 local gui=game.StarterGui.StrengthGui
 local oldScale=gui.LeftMenu.TimeRewardsButton.HUDScale.Scale
 -- Keep the pre-reduction scale for subsequent Edit reapplication.
 if not gui:GetAttribute("RightHUDOriginalScale") then gui:SetAttribute("RightHUDOriginalScale",oldScale) end
 loadModule(RS.Modules.RightHUDPresentation).Layout(gui,gui:GetAttribute("RightHUDOriginalScale"))
 return result
end
