local Players=game:GetService("Players")
local MarketplaceService=game:GetService("MarketplaceService")
local Config=require(game.ReplicatedStorage.Config:WaitForChild("WorldPassConfig"))

local M={}
local cache=setmetatable({}, {__mode="k"})

local function currentWorld()
	return Config.GetWorld(game.PlaceId)
end

function M.GetWorld()
	return currentWorld()
end

function M.IsWorld1()
	return currentWorld()=="World1"
end

function M.Refresh(player)
	local passId=Config.GetDoubleWinPassId(currentWorld())
	local owned=false

	if passId then
		local ok,result=pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId,passId)
		end)

		if ok then
			owned=(result==true)
		else
			warn("Game Pass ownership check failed for "..player.Name)
		end
	end

	cache[player]=owned
	player:SetAttribute("HasWorld1DoubleWin",owned)

	return owned
end

function M.HasWorld1DoubleWin(player)
	if currentWorld()~="World1" then
		return false
	end

	if cache[player]==nil then
		M.Refresh(player)
	end

	return cache[player]==true
end

function M.GetWinMultiplier(player)
	return M.HasWorld1DoubleWin(player) and 2 or 1
end

function M.GetWinReward(player,baseReward)
	return math.floor((tonumber(baseReward) or 0)*M.GetWinMultiplier(player))
end

function M.Prompt(player)
	if not M.IsWorld1() then
		return false,"Unavailable in this World"
	end

	if M.HasWorld1DoubleWin(player) then
		return false,"Already owned"
	end

	local passId=Config.GetDoubleWinPassId("World1")

	if not passId then
		return false,"Unavailable"
	end

	local ok=pcall(function()
		MarketplaceService:PromptGamePassPurchase(player,passId)
	end)

	return ok,ok and "Prompted" or "Purchase prompt unavailable"
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player,passId,purchased)
	local world=currentWorld()

	if world=="World1"
		and passId==Config.GetDoubleWinPassId("World1")
		and purchased then

		local ok,owned=pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId,passId)
		end)

		if ok and owned then
			cache[player]=true
			player:SetAttribute("HasWorld1DoubleWin",true)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	cache[player]=nil
end)

return M