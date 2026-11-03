local RS=game.ReplicatedStorage;local D=require(game.ServerScriptService.Services.PlayerDataService);local M=require(RS.__PMQAMemory);local p=game.Players:GetPlayers()[1]
local store=M.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName("PlayerData_v1"))
local result={}
for _,eligible in {false,true} do
 game.ServerStorage.__PMQA:Invoke("Setup",{Names={"Dog","Grey Cat"},Equipped=1})
 assert(D.Save(p));local before=D.GetPetState(p)
 store:UpdateAsync("Player_"..p.UserId,function(raw)raw.PetMergeTutorial=nil;raw.EggPetTutorial.Eligible=eligible;return raw end)
 local g=D.Get(p).PetViewGeneration or 0;D.Release(p);assert(D.Load(p));D.Get(p).PetViewGeneration=g+1;p:SetAttribute("PetViewGeneration",g+1)
 local after=D.GetPetState(p);local t=D.Get(p).Data.PetMergeTutorial
 assert(t.Eligible==eligible and not t.Completed)
 assert(after.Owned["00000000-0000-0000-0000-000000000001"]=="Dog" and after.Equipped[1]==before.Equipped[1])
 table.insert(result,{Cohort=eligible,State=t,PetIdentityPreserved=true})
end
local v=Instance.new("StringValue");v.Name="__PMCohortResult";v.Value=game.HttpService:JSONEncode(result);v.Parent=game.ServerStorage;script:Destroy()
