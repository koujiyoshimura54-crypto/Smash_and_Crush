local Bot = script.Parent
local myHuman = Bot.Humanoid
local anim = Bot.Humanoid:LoadAnimation(Bot.Stunned)

myHuman.WalkSpeed = 0
Bot.HumanoidRootPart.Anchored = true
local IsStunned = Instance.new("BoolValue")
IsStunned.Parent = script.Parent
IsStunned.Value = true
IsStunned.Name = "IsStunned"
Bot.HumanoidRootPart.PlayerKill.Disabled = true
anim:Play()
wait(20)
IsStunned:Destroy()
Bot.HumanoidRootPart.PlayerKill.Disabled = false
anim:Stop()
myHuman.WalkSpeed = 13
script.Disabled = true
Bot.HumanoidRootPart.Anchored = false