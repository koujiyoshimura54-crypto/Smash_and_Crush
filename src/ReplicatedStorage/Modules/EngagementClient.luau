-- No GUI creation or automatic prompt. A future approved existing-button callback
-- may call Invite() / NotifyMe() on the LOCAL client only, in response to user input.
local M={}
local mounted
local function mount()
	if mounted then return mounted end
	assert(game:GetService("RunService"):IsClient(),"ClientOnly")
	local player=game:GetService("Players").LocalPlayer
	local Social=game:GetService("SocialService")
	local Notifications=game:GetService("ExperienceNotificationService")
	local C=require(game.ReplicatedStorage.Config.EngagementConfig)
	local Prompt=require(script.Parent.EngagementPrompts)
	local invite=Prompt.new({
		Enabled=function() return C.Invite.Enabled and C.HasMessageId(C.Invite.FriendInviteMessageId) end,
		CanPrompt=function() return Social:CanSendGameInviteAsync(player) end,
		Prompt=function()
			local options=Instance.new("ExperienceInviteOptions")
			options.InviteMessageId=C.Invite.FriendInviteMessageId
			local ok=pcall(Social.PromptGameInvite,Social,player,options)
			options:Destroy()
			assert(ok,"InvitePromptFailed")
		end,
		Closed=Social.GameInvitePromptClosed,
	})
	local notify=Prompt.new({Enabled=C.OfflineConfigured,
		CanPrompt=function() return Notifications:CanPromptOptInAsync() end,
		Prompt=function() Notifications:PromptOptIn() end,
		Closed=Notifications.OptInPromptClosed})
	mounted={Invite=invite,Notify=notify}
	return mounted
end
function M.Invite() return mount().Invite.Click() end
function M.NotifyMe() return mount().Notify.Click() end
function M.Destroy()
	if mounted then mounted.Invite.Destroy();mounted.Notify.Destroy();mounted=nil end
end
return M
