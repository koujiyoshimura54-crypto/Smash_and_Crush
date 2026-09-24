local SettingsController = {}

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local ReplicationCon = require(script.Parent.ReplicationController)
local Frames = require(script.Parent.UiController.Frames)
local Packets = require(ReplicatedStorage.Utils.Packets)

local SettingsFrame = Frames.Settings

local MusicDrag = SettingsFrame.Main.Holder.Music.Bar.Dragger
local SfxDrag = SettingsFrame.Main.Holder.Sfx.Bar.Dragger

local MusicDetector = MusicDrag.UIDragDetector
local SfxDetector = SfxDrag.UIDragDetector

local MusicGroup = SoundService:WaitForChild("Music")
local SfxGroup = SoundService:WaitForChild("SFX")

local settings

local function RoundVolume(value: number): number
	local rounded = math.round(value * 10) / 10

	if rounded < 0.05 then
		return 0
	end

	return rounded
end

local function SetDragPosition(dragger: GuiObject, value: number)
	dragger.Position = UDim2.fromScale(
		RoundVolume(value),
		dragger.Position.Y.Scale
	)
end

local function GetDragValue(dragger: GuiObject): number
	return RoundVolume(dragger.Position.X.Scale)
end

local function ApplyVolumes()
	if not settings then
		return
	end

	MusicGroup.Volume = settings.Music or 0
	SfxGroup.Volume = settings.SFX or 0
end

local function UpdateSetting(settingName: string, value: number)
	settings[settingName] = value
	ApplyVolumes()
end

local function BindSlider(
	dragger: GuiObject,
	detector: UIDragDetector,
	settingName: string
)
	dragger:GetPropertyChangedSignal("Position"):Connect(function()
		UpdateSetting(settingName, GetDragValue(dragger))
	end)

	detector.DragEnd:Connect(function()
		Packets.Settings.UpdateSetting:Fire(
			settingName,
			GetDragValue(dragger)
		)
	end)
end

function SettingsController:init()
	settings = ReplicationCon.Subscribe(`{Player.UserId}_Settings`)

	SetDragPosition(MusicDrag, settings.Music or 0)
	SetDragPosition(SfxDrag, settings.SFX or 0)

	ApplyVolumes()
	
	ReplicationCon.GetSignal(`{Player.UserId}_Settings`):Connect(function(data)
		settings = data

		SetDragPosition(MusicDrag, settings.Music or 0)
		SetDragPosition(SfxDrag, settings.SFX or 0)

		ApplyVolumes()
	end)

	ApplyVolumes()

	BindSlider(MusicDrag, MusicDetector, "Music")
	BindSlider(SfxDrag, SfxDetector, "SFX")
end

return SettingsController