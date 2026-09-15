-- Does not decide eligibility or change authored layout/style.
local M={}
function M.GetOrClone(template,parent,name)
 local badge=parent:FindFirstChild(name)
 if not badge then
  badge=template:Clone();badge.Name=name;badge.Visible=false;badge.Parent=parent
 end
 return badge
end
function M.SetVisible(badge,visible) badge.Visible=visible==true end
function M.SetText(badge,text)
 local label=badge:FindFirstChild("TextLabel")
 if label then label.Text=text end
end
return table.freeze(M)

