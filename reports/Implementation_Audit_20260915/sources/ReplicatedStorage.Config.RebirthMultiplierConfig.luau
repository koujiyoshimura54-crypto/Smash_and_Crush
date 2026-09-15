local Config={}

-- Edit these values to tune the Strength multiplier for each Rebirth count.
Config.Multipliers={
 [0]=1.0,
 [1]=1.5,
 [2]=2.0,
 [3]=2.5,
 [4]=3.0,
 [5]=3.5,
 [6]=4.0,
 [7]=4.5,
 [8]=5.0,
 [9]=6.0,
 [10]=7.0,
 [11]=8.0,
 [12]=9.0,
 [13]=10.0,
 [14]=12.0,
 [15]=14.0,
 [16]=16.0,
 [17]=18.0,
 [18]=20.0,
 [19]=25.0,
 [20]=30.0,
 [21]=45.0,
 [22]=60.0,
 [23]=75.0,
 [24]=90.0,
 [25]=100.0,
 [26]=120.0,
 [27]=150.0,
 [28]=200.0,
 [29]=250.0,
 [30]=300.0,
}

local function validMultiplier(value)
 return typeof(value)=="number" and value==value and value>0
  and value~=math.huge and value~=-math.huge
end

function Config.GetMultiplier(rebirthCount)
 local count=math.max(0,math.floor(tonumber(rebirthCount) or 0))
 local exact=Config.Multipliers[count]
 if validMultiplier(exact) then return exact end
 local lastCount
 local lastValue
 for configuredCount,value in pairs(Config.Multipliers) do
  if typeof(configuredCount)=="number" and configuredCount>=0 and configuredCount%1==0
   and validMultiplier(value) and (lastCount==nil or configuredCount>lastCount) then
   lastCount=configuredCount
   lastValue=value
  end
 end
 return lastValue or 1
end

return Config

