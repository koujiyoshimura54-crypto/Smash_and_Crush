assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
local f=game.ServerStorage.BodyPrototype_20261114
local M=require(f.BodyPrototype)
local display=workspace:FindFirstChild("BodyPrototype_20261114") or Instance.new("Folder")
display.Name="BodyPrototype_20261114";display.Parent=workspace
for _,m in display:GetChildren() do assert(m:GetAttribute("BodyPrototypeRatio"),"Unrecognized preview; retain it");m:Destroy() end
local specs={
 {"LV1_Body30_OriginalHead",.3,3670737444,nil},
 {"LV1_Body40_OriginalHead",.4,3670737444,nil},
 {"LV1_Body40_Pastel",.4,398634295,nil},
 {"LV1_Body40_Pastel_DarkSkin",.4,398634295,Color3.fromRGB(111,78,55)},
 {"LV1_Body40_Pastel_LightSkin",.4,398634295,Color3.fromRGB(244,215,190)},
}
local out={}
for i,s in specs do
 local m=f.CurrentAvatarReference:Clone();m.Name=s[1];m.Parent=display
 M.Apply(m,s[2]);M.Clothes(m,f.Clothing[tostring(s[3])],f.Clothing["398633812"])
 if s[4] then M.Skin(m,s[4]) end
 m:PivotTo(CFrame.new(295+(i-1)*4.5,80+s[2]*4.973626,-125))
 m.Humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 for _,v in m:GetDescendants() do
  if v:IsA("BasePart") then v.CanCollide=false;v.CanTouch=false;v.CanQuery=false
  elseif v:IsA("BaseScript") then v:Destroy() end
 end
 m.HumanoidRootPart.Anchored=true
 m:SetAttribute("StaticPreviewOnly",true)
 table.insert(out,{path=m:GetFullName(),extents=tostring(m:GetExtentsSize()),bodyRatio=s[2],headSize=tostring(m.Head.Size)})
end
return out
