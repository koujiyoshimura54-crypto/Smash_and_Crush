--This sound plays when it falls onto the ground, gets hit, or when someone touches it.
--SOOO easy.
function onTouched(hit)
	script.Parent.RAH:play()
end
script.Parent.Touched:connect(onTouched)