local RS=game:GetService("ReplicatedStorage")
local v=RS:WaitForChild("World2BalanceAuditResult",30)
local out={ok=false}
if v then
 local F=require(RS.Modules.NumberFormat)
 out.attribute=v:GetAttribute("MaxHPProbe")
 out.display=F.Format(out.attribute)
 out.ok=out.attribute==25000000000 and out.display=="25B"
end
local r=Instance.new("StringValue") r.Name="World2BalanceAuditClientResult"
r.Value=game:GetService("HttpService"):JSONEncode(out) r.Parent=RS
