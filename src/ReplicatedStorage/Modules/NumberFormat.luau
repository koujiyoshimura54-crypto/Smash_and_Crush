local M={}
local suffixes={"","K","M","B","T","Qa","Qi","Sx","Sp","Oc","No","Dc"}
function M.Format(value)
 local n=tonumber(value) or 0
 local sign=n<0 and "-" or ""; n=math.abs(n)
 local idx=1
 while n>=1000 and idx<#suffixes do n/=1000; idx+=1 end
 local text
 if n>=100 or n%1==0 then text=string.format("%.0f",n)
 else text=string.format("%.1f",n):gsub("%.0$","") end
 return sign..text..suffixes[idx]
end
-- Exact, unabridged format for existing price/reward labels.
function M.Plain(value) return tostring(value) end
return M
