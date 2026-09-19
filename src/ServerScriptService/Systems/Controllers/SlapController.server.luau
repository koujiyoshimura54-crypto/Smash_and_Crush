local MarketplaceService = game:GetService("MarketplaceService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Config:WaitForChild("SlapPassConfig"))
local GamePassService = require(game.ServerScriptService.Services:WaitForChild("GamePassService"))

if not PhysicsService:IsCollisionGroupRegistered(Config.PlayerCollisionGroup) then
	PhysicsService:RegisterCollisionGroup(Config.PlayerCollisionGroup)
end
PhysicsService:CollisionGroupSetCollidable(Config.PlayerCollisionGroup, Config.PlayerCollisionGroup, false)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local gameRemotes = remotes:FindFirstChild("GameRemotes") or Instance.new("Folder")
gameRemotes.Name = "GameRemotes"
gameRemotes.Parent = remotes
local slapRequest = gameRemotes:FindFirstChild("SlapRequest") or Instance.new("RemoteEvent")
slapRequest.Name = "SlapRequest"
slapRequest.Parent = gameRemotes

local lastSuccessfulSlap = setmetatable({}, { __mode = "k" })
local lastPrompt = setmetatable({}, { __mode = "k" })
local characterConnections = setmetatable({}, { __mode = "k" })

local function setPlayerCollisionGroup(instance)
	if instance:IsA("BasePart") then instance.CollisionGroup = Config.PlayerCollisionGroup end
end

local function configureCharacter(player, character)
	local oldConnection = characterConnections[player]
	if oldConnection then oldConnection:Disconnect() end
	for _, descendant in ipairs(character:GetDescendants()) do setPlayerCollisionGroup(descendant) end
	characterConnections[player] = character.DescendantAdded:Connect(setPlayerCollisionGroup)
end

local function destroySlapTools(player)
	for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and child.Name == Config.ToolName then child:Destroy() end
			end
		end
	end
end

local function hasSlapTool(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	return (player.Character and player.Character:FindFirstChild(Config.ToolName))
		or (backpack and backpack:FindFirstChild(Config.ToolName))
end

local function grantSlapTool(player)
	if player.Parent ~= Players or not GamePassService.CanUseSlapPass(player) or hasSlapTool(player) then return end
	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 5)
	if not backpack or hasSlapTool(player) then return end
	local tool = Instance.new("Tool")
	tool.Name = Config.ToolName
	tool.ToolTip = "Slap nearby players"
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool:SetAttribute("SlapPassTool", true)
	tool.Parent = backpack
end

local function aliveCharacter(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return nil end
	return character, root
end

local function isEquipped(player)
	local tool = player.Character and player.Character:FindFirstChild(Config.ToolName)
	return tool and tool:IsA("Tool") and tool:GetAttribute("SlapPassTool") == true
end

local function attemptSlap(attacker, target)
	if not GamePassService.CanUseSlapPass(attacker) or not isEquipped(attacker) then return end
	if typeof(target) ~= "Instance" or not target:IsA("Player") or target == attacker or target.Parent ~= Players then return end
	local _, attackerRoot = aliveCharacter(attacker)
	local _, targetRoot = aliveCharacter(target)
	if not attackerRoot or not targetRoot then return end
	local offset = targetRoot.Position - attackerRoot.Position
	local horizontal = Vector3.new(offset.X, 0, offset.Z)
	if offset.Magnitude > Config.SlapDistance or horizontal.Magnitude < 0.05 then return end
	local direction = horizontal.Unit
	local look = Vector3.new(attackerRoot.CFrame.LookVector.X, 0, attackerRoot.CFrame.LookVector.Z)
	if look.Magnitude > 0.05 and look.Unit:Dot(direction) < Config.MinimumFacingDot then return end
	local now = workspace:GetServerTimeNow()
	local previous = lastSuccessfulSlap[attacker]
	if previous and now - previous < Config.Cooldown then return end
	lastSuccessfulSlap[attacker] = now
	targetRoot:ApplyImpulse((direction * Config.HorizontalKnockback + Vector3.yAxis * Config.UpwardKnockback) * targetRoot.AssemblyMass)
end

local function initializePlayer(player)
	player.CharacterAdded:Connect(function(character)
		configureCharacter(player, character)
		task.defer(grantSlapTool, player)
	end)
	if player.Character then configureCharacter(player, player.Character) end
	player:GetAttributeChangedSignal("HasSlapPass"):Connect(function()
		if player:GetAttribute("HasSlapPass") then grantSlapTool(player) else destroySlapTools(player) end
	end)
	task.spawn(function()
		local owned = GamePassService.RefreshSlapPass(player)
		if owned then grantSlapTool(player) end
	end)
end

slapRequest.OnServerEvent:Connect(attemptSlap)
Players.PlayerAdded:Connect(initializePlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(initializePlayer, player) end

Players.PlayerRemoving:Connect(function(player)
	lastSuccessfulSlap[player] = nil
	lastPrompt[player] = nil
	local connection = characterConnections[player]
	if connection then connection:Disconnect() end
	characterConnections[player] = nil
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if passId ~= Config.GamePassId or not purchased then return end
	task.spawn(function()
		for attempt = 1, 5 do
			if player.Parent ~= Players then return end
			local owned = GamePassService.RefreshSlapPass(player)
			if owned then grantSlapTool(player); return end
			task.wait(attempt)
		end
	end)
end)

task.spawn(function()
	while true do
		local players = Players:GetPlayers()
		for _, player in ipairs(players) do
			if player:GetAttribute("HasSlapPass") == false then
				local _, root = aliveCharacter(player)
				if root then
					for _, other in ipairs(players) do
						if other ~= player then
							local _, otherRoot = aliveCharacter(other)
							if otherRoot and (otherRoot.Position - root.Position).Magnitude <= Config.PromptDistance then
								local now = workspace:GetServerTimeNow()
								if not lastPrompt[player] or now - lastPrompt[player] >= Config.PromptCooldown then
									local prompted = GamePassService.PromptSlapPass(player)
									if prompted then lastPrompt[player] = now end
								end
								break
							end
						end
					end
				end
			end
		end
		task.wait(Config.PromptScanInterval)
	end
end)
