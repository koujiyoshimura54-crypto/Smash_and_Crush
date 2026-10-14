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
-- Prices only; do not change the existing Strength/count/reward formatter.
function M.Price(value)
 local n=tonumber(value)
 if not n or n~=n or n==math.huge or n==-math.huge then return tostring(value or "...") end
 local unit,suffix=1,""
 if math.abs(n)>=1000000 then unit,suffix=1000000,"M" elseif math.abs(n)>=1000 then unit,suffix=1000,"K" end
 local text=unit==1 and tostring(n) or string.format(unit==1000 and "%.3f" or "%.6f",n/unit):gsub("0+$",""):gsub("%.$","")
 return text..suffix
end
function M.PriceText(value)
 if typeof(value)=="number" then return M.Price(value) end
 local text=tostring(value or "...")
 local digits,suffix=text:match("^(%d[%d,]*%.?%d*)(.*)$")
 if digits and (suffix=="" or suffix==" Win" or suffix==" Wins" or suffix==" Robux") then return M.Price((digits:gsub(",","")))..suffix end
 return text
end
return M
