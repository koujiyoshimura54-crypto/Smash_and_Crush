local function seq(s) local r={} for _,k in ipairs(s.Keypoints)do table.insert(r,{Time=k.Time,Value=k.Value,Envelope=k.Envelope})end return r end
local list={} for _,root in ipairs({workspace,game:GetService("ReplicatedStorage").AuraVisualTemplates,game:GetService("ReplicatedStorage").TreadmillVisualTemplates})do for _,o in ipairs(root:GetDescendants())do if o:IsA("ParticleEmitter")or o:IsA("Beam")or o:IsA("Trail")or o:IsA("Light")or o:IsA("Highlight")then table.insert(list,o)end end end
table.sort(list,function(a,b)return a:GetFullName()<b:GetFullName()end)
local rows={} local bytes=0
for i=OFFSET+1,#list do
 local o=list[i] local r={Path=o:GetFullName(),Class=o.ClassName,Enabled=o.Enabled}
 if o:IsA("ParticleEmitter")then r.Rate=o.Rate r.Lifetime={o.Lifetime.Min,o.Lifetime.Max} r.Size=seq(o.Size) r.Transparency=seq(o.Transparency) r.Texture=o.Texture r.LightEmission=o.LightEmission r.LightInfluence=o.LightInfluence r.Speed={o.Speed.Min,o.Speed.Max} r.LockedToPart=o.LockedToPart r.TimeScale=o.TimeScale r.SpreadAngle={o.SpreadAngle.X,o.SpreadAngle.Y}
 elseif o:IsA("Beam")then r.Width0=o.Width0 r.Width1=o.Width1 r.Segments=o.Segments r.Texture=o.Texture r.Transparency=seq(o.Transparency) r.FaceCamera=o.FaceCamera
 elseif o:IsA("Trail")then r.Lifetime=o.Lifetime r.Texture=o.Texture r.Transparency=seq(o.Transparency)
 elseif o:IsA("Light")then r.Brightness=o.Brightness r.Shadows=o.Shadows local ok,v=pcall(function()return o.Range end)if ok then r.Range=v end
 elseif o:IsA("Highlight")then r.FillTransparency=o.FillTransparency r.OutlineTransparency=o.OutlineTransparency r.DepthMode=tostring(o.DepthMode)end
 local ok,cf=pcall(function()if o.Parent:IsA("Attachment")then return o.Parent.WorldCFrame elseif o.Parent:IsA("BasePart")then return o.Parent.CFrame end end)
 if ok and cf then r.Position={cf.X,cf.Y,cf.Z}end
 local n=#game:GetService("HttpService"):JSONEncode(r)if bytes+n>65000 and #rows>0 then break end bytes+=n table.insert(rows,r)
end
return game:GetService("HttpService"):JSONEncode({Offset=OFFSET,Total=#list,Records=rows})
