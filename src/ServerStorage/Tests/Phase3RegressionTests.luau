-- Manual Studio integration regression. Uses only the isolated Studio player store.
local M={}
function M.Run()
 assert(game:GetService("RunService"):IsStudio(),"Studio only")
 local S=game.ServerScriptService local RS=game.ReplicatedStorage
 local D=require(S.Services.PlayerDataService) local Str=require(S.Services.StrengthManager)
 local T=require(S.Services.TrainingManager) local E=require(S.World.EnemyManager)
 local p=assert(game.Players:GetPlayers()[1],"Player required")
 local results={}
 local function test(name,fn) local ok,err=pcall(fn);results[#results+1]={Name=name,Pass=ok,Error=not ok and tostring(err) or nil} end
 local function ready() while not D.IsLoaded(p) do task.wait(.1) end D.WaitForSave(p,20) end
 ready()
 assert(require(S.Config.DataStoreConfig).GetName("PlayerData_v1")=="PlayerData_v1_Studio")
 T.StopTraining(p);E.StartRun(p,1)
 local root=p.Character.HumanoidRootPart local spawn=root.CFrame;root.Anchored=true
 assert(D.Reset(p));D.SetWin(p,10000);Str.SetStrength(p,0)
 test("Join / services / spawn",function() assert(E.IsReady() and #T.GetTreadmills()==10 and p.Character.Humanoid.Health>0);assert(workspace.GeneratedMap and workspace.Treadmill) end)
 test("Dumbbell",function() local m=require(S.Services.DumbbellService);local cfg=require(RS.Config.DumbbellItemMaster).Get("NORMAL_01");local win=p:GetAttribute("Win");assert(m.PurchaseDumbbell(p,cfg.ItemId));assert(m.EquipDumbbell(p,cfg.ItemId));assert(m.GetStrengthBonus(p)==cfg.StrengthBonus and p:GetAttribute("Win")==win-cfg.PriceWin) end)
 test("Aura",function() local m=require(S.Services.AuraService);local cfg=require(RS.Config.AuraConfig).Get("Pink");local win=p:GetAttribute("Win");assert(m.PurchaseAura(p,"Pink"));assert(m.EquipAura(p,"Pink"));assert(m.GetStrengthBonus(p)==cfg.StrengthBonus and p:GetAttribute("Win")==win-cfg.Price) end)
 test("Item / Merge",function() local m=require(S.Services.ItemService);assert(m.PurchaseItemWithWin(p,"PROTEIN_COMMON_FIRE"));assert(m.EquipItem(p,"PROTEIN_COMMON_FIRE"));assert(m.AddItem(p,"PROTEIN_COMMON_FIRE",2));assert(require(S.Services.ItemMergeService).MergeItem(p,"PROTEIN_COMMON_FIRE"));assert(m.GetItemCount(p,"PROTEIN_COMMON_FIRE")==0 and m.GetItemCount(p,"PROTEIN_UNCOMMON_FIRE")==1);assert(m.EquipItem(p,"PROTEIN_UNCOMMON_FIRE")) end)
 test("Speed",function() assert(require(S.Services.SpeedService).Purchase(p,"Speed1"));require(S.Services.SpeedService).Apply(p);assert(p.Character.Humanoid.WalkSpeed==require(RS.Config.SpeedConfig).Speed1.WalkSpeed) end)
 test("Training / Treadmill / Save / Level",function()
  local zone=workspace.Treadmill.Tredmill06.TrainingZone
  root.CFrame=zone.CFrame*CFrame.new(0,p.Character.Humanoid.HipHeight+root.Size.Y/2,0)
  assert(T.StartTraining(p,workspace.Treadmill.Tredmill06))
  local before=p:GetAttribute("Strength");local done=false
  task.spawn(function() D.Save(p);done=true end)
  task.wait(1.2);assert(p:GetAttribute("Strength")>before);while not done do task.wait() end
  assert(p:GetAttribute("Strength")>before and p:GetAttribute("Level")>1)
  T.StopTraining(p);root.CFrame=spawn
 end)
 test("Walk formula",function() local before=p:GetAttribute("Strength");Str.AddStrength(p,require(RS.Config.TrainingConfig).BaseGain,1);assert(p:GetAttribute("Strength")-before==26) end)
 test("Wall / progression",function() local w=require(S.World.Stage1WallManager);w.InitializePlayer(p);for i,hp in ipairs({7000,8750,10500,14000}) do assert(w.GetGaugeForStage(p,5,i)==hp);w.ApplyDamageForStage(p,5,hp) end assert(w.IsBossUnlockedForStage(p,5)) end)
 test("Boss / lottery losing route",function() local b=require(S.World.BossCombatService);b.Reset(p);Str.SetStrength(p,3500);local a=b.Begin(p,{},5);assert(a.MaxHP==17500 and a.Route=="LEVEL_DAMAGE");local result;for i=1,5 do result=b.Attack(p) end assert(result=="Win");b.Reset(p);Str.SetStrength(p,1750);a=b.Begin(p,{},5);assert(a.Route=="LOTTERY_MISS");for i=1,5 do result=b.Attack(p) end assert(result=="Lose");b.Reset(p) end)
 test("Trophy / Tutorial / Save",function()
  E.GetPlayerState(p).Defeated[1]=true
  local m=require(S.Services.TrophyRewardService);local win=p:GetAttribute("Win")
  local reward=require(S.Services.GamePassService).GetWinReward(p,require(RS.Config.TrophyRewardConfig).GetBaseReward(1))
  assert(m.Spawn(p,1));local box
  for _,v in workspace:GetDescendants() do if v.Name=="Trophy_"..p.UserId.."_Stage1" then box=v;break end end
  assert(box);root.CFrame=box.CFrame;task.wait(.4)
  assert(p:GetAttribute("Win")==win+reward and D.Get(p).Data.TutorialCompleted)
  ready();assert(D.Save(p));assert(p:GetAttribute("Win")==win+reward)
 end)
 test("Time Reward / Potion duplicate claims",function()
  ready();D.Get(p).Data.TimeRewards.ElapsedSeconds=3000
  local r=require(S.Services.TimeRewardService);local pot=require(S.Services.PotionService)
  for _,id in ipairs({"Reward01","Reward02"}) do
   local win=p:GetAttribute("Win");local before=pot.GetRemaining(p,"Training");local done,grants=0,0
   for i=1,12 do task.spawn(function() if r.Claim(p,id) then grants+=1 end done+=1 end) end
   while done<12 do task.wait() end assert(grants==1)
   if id=="Reward01" then assert(p:GetAttribute("Win")==win+1) else local dt=pot.GetRemaining(p,"Training")-before;assert(dt>59 and dt<=60) end
  end
 end)
 test("Daily",function() ready();local win=p:GetAttribute("Win");local r=require(S.Services.DailyRewardService);assert(r.Claim(p,1));assert(not r.Claim(p,1));assert(p:GetAttribute("Win")==win+1) end)
 test("Community",function() ready();local r=require(S.Services.CommunityRewardService);local state=r.GetState(p,true);if state.Status=="NotJoined" then assert(not r.Claim(p));return end local win=p:GetAttribute("Win");assert(r.Claim(p));assert(p:GetAttribute("Win")==win+3 and not r.Claim(p)) end)
 test("StageSkip / Stage progression",function()
  ready();root.CFrame=spawn;T.StopTraining(p);E.StartRun(p,1);task.wait(.1)
  local win=p:GetAttribute("Win");assert(require(S.Services.StageSkipService).BuyWithWin(p,2))
  assert(p:GetAttribute("CurrentStage")==2 and p:GetAttribute("Win")==win-1)
  E.StartRun(p,1);root.CFrame=spawn
 end)
 test("Respawn",function() root.Anchored=false;p:LoadCharacterAsync();task.wait(1);assert(p.Character.Humanoid.WalkSpeed==32);assert(D.Get(p).Data.EquippedDumbbell=="NORMAL_01") end)
 ready();Str.SetStrength(p,3500);assert(D.Save(p))
 return results
end
return M