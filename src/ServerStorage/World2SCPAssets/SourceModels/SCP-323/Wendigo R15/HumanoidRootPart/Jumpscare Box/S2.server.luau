
Popup = script.Parent.Popup
Ready = true
function onTouch(hit)
local h = hit.Parent:FindFirstChild("Humanoid")
if h ~= nil and Ready == true then
Ready = false
local plyr = game.Players:FindFirstChild(h.Parent.Name)
wait()
local c = Popup:clone()
c.Parent = plyr.PlayerGui
c.BackGround.Image.StuffScript.Disabled=false
h.Health=0
wait(1)
wait(.1)

c:remove()
wait(1)
Ready = true
end
end

script.Parent.Touched:connect(onTouch)
