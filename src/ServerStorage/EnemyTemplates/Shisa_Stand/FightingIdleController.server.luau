local model=script.Parent
local humanoid=model:WaitForChild("Humanoid")
local animator=humanoid:FindFirstChildOfClass("Animator")or Instance.new("Animator")
animator.Parent=humanoid

for _,track in animator:GetPlayingAnimationTracks()do
 track:Stop(0)
end

local animation=model:WaitForChild("FightingIdle")
local track=animator:LoadAnimation(animation)
track.Priority=Enum.AnimationPriority.Action
track.Looped=true
track:Play(0.15,1,1)
