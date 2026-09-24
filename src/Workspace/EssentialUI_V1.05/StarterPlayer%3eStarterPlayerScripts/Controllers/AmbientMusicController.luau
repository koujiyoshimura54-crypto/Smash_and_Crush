local AmbientMusicController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local MusicSoundGroup = SoundService:FindFirstChild("Music")
local Config = ReplicatedStorage.Configuration
local GeneralConfig = require(Config.General)


function AmbientMusicController:start()
	local MusicFolder = Instance.new("Folder")
	MusicFolder.Name = "Music"
	for i, id in GeneralConfig.AmbientMusic do
		local track = Instance.new("Sound")
		track.SoundId = "rbxassetid://" .. id
		track.Name = i
		track.SoundGroup = MusicSoundGroup
		track.Parent = MusicFolder
	end
	
	MusicFolder.Parent = SoundService
	
	while true do
		for i = 1, #MusicFolder:GetChildren() do
			local track:Sound = MusicFolder:FindFirstChild(i)
			if not track then continue end
			track:Play()
			track.Ended:Wait()
		end
		task.wait()
	end
end

return AmbientMusicController
