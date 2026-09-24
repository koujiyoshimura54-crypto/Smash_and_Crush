Sound = script.Parent.Scream
Popup = script.Parent.Popup
Ready = true
function onTouch(hit)
local h = hit.Parent:FindFirstChild("Humanoid")
if h ~= nil and Ready == true then
Ready = false
local plyr = game.Players:FindFirstChild(h.Parent.Name)
local c = Popup:clone()
c.Parent = plyr.PlayerGui
script.Parent.Scream:play()
wait(2)
c:remove()
wait(1)
Ready = true
end
end

script.Parent.Touched:connect(onTouch)
