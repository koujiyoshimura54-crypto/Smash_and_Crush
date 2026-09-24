script.Sound:play()
de = 0
repeat wait() de = de + 1 script.Parent.Parent.Size = script.Parent.Parent.Size + UDim2.new(0, 60, 0, 40) 
script.Parent.Parent.Position = script.Parent.Parent.Position + UDim2.new(0, -30, 0, -20) until de == 40


script.Parent.Parent.Static.Visible=true
script.Parent.Parent.Scream2:play()
wait(.1)
script.Sound:stop()
wait(.1)
script.Parent:remove()