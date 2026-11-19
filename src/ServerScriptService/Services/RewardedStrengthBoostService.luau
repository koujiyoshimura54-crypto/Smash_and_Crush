local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Marketplace=game:GetService("MarketplaceService")
local Ads=game:GetService("AdService")
local Run=game:GetService("RunService")
local Config=require(RS.Config.RewardedStrengthBoostConfig)
local Data=require(script.Parent.PlayerDataService)
local Lobby=require(script.Parent.TrainingLobbyAreaService)
local controller=require(script.Parent.RewardedStrengthBoostController).New({
	Config=Config,Now=os.time,Monotonic=os.clock,IsStudio=function() return Run:IsStudio() end,
	Session=Data.Get,Player=function(id) return Players:GetPlayerByUserId(id) end,
	Safe=function(p) return p.Parent==Players and not p:GetAttribute("IsFighting") and Lobby.IsInTrainingLobby(p) end,
	CreateReward=function(id) return Ads:CreateAdRewardFromDevProductId(id) end,
	Show=function(p,reward,id) return Ads:ShowRewardedVideoAdAsync(p,reward,id) end,
	Purchase=function(p,id) Marketplace:PromptProductPurchase(p,id) end,
	Commit=Data.CommitStrengthBoostReceipt,
})
local M={ProcessReceipt=controller.Receipt}
local initialized=false
function M.Init()
	if initialized then return end
	initialized=true
	local folder=RS:WaitForChild("Remotes")
	local remote=folder:FindFirstChild("RewardedStrengthBoost")
	if not remote then remote=Instance.new("RemoteEvent");remote.Name="RewardedStrengthBoost";remote.Parent=folder end
	assert(remote:IsA("RemoteEvent"),"RewardedStrengthBoost remote class conflict")
	remote.OnServerEvent:Connect(function(p,action,requestId)
		if type(requestId)~="number" or requestId%1~=0 or requestId<0 or requestId>2147483647 then return end
		local code=controller.Request(p,action)
		if p.Parent==Players then remote:FireClient(p,requestId,code) end
	end)
	Players.PlayerRemoving:Connect(controller.Forget)
end
return M
