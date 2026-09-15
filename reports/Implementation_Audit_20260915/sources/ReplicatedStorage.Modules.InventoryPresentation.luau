-- Rendering only: callers own purchase, ownership and equip decisions.
local M={}
function M.SetIdentity(nameLabel,imageLabel,name,image)
 if nameLabel then nameLabel.Text=name end
 if imageLabel then imageLabel.Image=image end
end
function M.SetButtonEnabled(button,enabled)
 button.Active=enabled==true
 button.AutoButtonColor=button.Active
end
return table.freeze(M)

