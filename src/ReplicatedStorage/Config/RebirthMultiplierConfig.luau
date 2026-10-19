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

for count in pairs(Config.Multipliers) do Config.Multipliers[count]=1+count*.5 end

function Config.GetMultiplier(rebirthCount)
 local count=tonumber(rebirthCount)
 if not count or count~=count or count==math.huge or count==-math.huge then return 1 end
 return 1+math.max(0,math.floor(count))*.5
end
return Config
