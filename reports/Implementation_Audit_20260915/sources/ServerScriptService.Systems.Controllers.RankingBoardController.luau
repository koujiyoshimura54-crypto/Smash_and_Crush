local Players=game:GetService("Players")
local Data=require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))
local UPDATE_INTERVAL=60
local nameCache={}
local updating=false
local initialized={}

local function shortNumber(value)
 local n=tonumber(value) or 0
 if n<0 then n=0 end
 local suffix={"","K","M","B","T","Qa","Qi"}
 local index=1
 while n>=1000 and index<#suffix do
  n=n/1000
  index+=1
 end
 if index==1 then return tostring(math.floor(n+0.5)) end
 local text
 if n>=100 then text=string.format("%.0f",n)
 elseif n>=10 then text=string.format("%.1f",n)
 else text=string.format("%.2f",n) end
 text=text:gsub("%.?0+$","")
 return text..suffix[index]
end

local function playerName(userId)
 local online=Players:GetPlayerByUserId(userId)
 if online then
  nameCache[userId]=online.Name
  return online.Name
 end
 if nameCache[userId] then return nameCache[userId] end
 local ok,result=pcall(function()
  return Players:GetNameFromUserIdAsync(userId)
 end)
 if ok and typeof(result)=="string" and result~="" then
  nameCache[userId]=result
  return result
 end
 local fallback="Player_"..tostring(userId)
 nameCache[userId]=fallback
 return fallback
end

local function labels(board)
 local legacyGui=board:FindFirstChild("RankingSurfaceGui",true)
 if legacyGui then
  local bg=legacyGui:FindFirstChild("Background")
  local frame=bg and bg:FindFirstChild("RankingFrame")
  if frame then return bg:FindFirstChild("UpdatedLabel"),frame end
  local scrolling=legacyGui:FindFirstChild("ScrollingFrame")
  if scrolling then return legacyGui:FindFirstChild("UpdatedLabel"),scrolling end
 end
 return nil,nil
end

local function rowObjects(frame,index)
 local row=frame:FindFirstChild(string.format("Row%02d",index))
 if not row then return nil end
 if row:IsA("TextLabel") then return row end
 local content=row:FindFirstChild("Frame") or row
 return row,content:FindFirstChild("Rank"),content:FindFirstChild("UserName"),content:FindFirstChild("Amount")
end

local function clearRow(frame,index)
 local row,rank,user,amount=rowObjects(frame,index)
 if not row then return end
 if row:IsA("TextLabel") then
  row.Text=""
 else
  if rank then rank.Text="" end
  if user then user.Text="" end
  if amount then amount.Text="" end
 end
end

local function writeRow(frame,index,name,value)
 local row,rank,user,amount=rowObjects(frame,index)
 if not row then return end
 if row:IsA("TextLabel") then
  row.Text=string.format("#%-2d  %-20s  %s",index,name,value)
 else
  if rank then rank.Text="#"..tostring(index) end
  if user then user.Text=name end
  if amount then amount.Text=value end
 end
end

local function statusRow(frame,text)
 local row,rank,user,amount=rowObjects(frame,1)
 if not row then return end
 if row:IsA("TextLabel") then
  row.Text=text
 else
  if rank then rank.Text="" end
  if user then user.Text=text end
  if amount then amount.Text="" end
 end
end

local function setRows(board,entries)
 local updated,frame=labels(board)
 if not frame then return false end
 for i=1,10 do clearRow(frame,i) end
 if #entries==0 then
  statusRow(frame,"No ranking data yet")
 else
  for i,entry in ipairs(entries) do
   if i>10 then break end
   local userId=tonumber(entry.UserId)
   local name=userId and playerName(userId) or "Unknown"
   writeRow(frame,i,name,shortNumber(entry.Value))
  end
 end
 if updated then updated.Text="Updated "..os.date("!%H:%M:%S",os.time()+9*60*60).." JST" end
 return true
end

local function markFailure(board,first)
 local updated,frame=labels(board)
 if first and frame then
  for i=1,10 do clearRow(frame,i) end
  statusRow(frame,"Unable to load ranking")
 end
 if updated then updated.Text="Retrying..." end
end

local function updateBoard(board,fetch)
 if not board or not board.Parent then return end
 local ok,result=pcall(fetch)
 if not ok or typeof(result)~="table" then
  markFailure(board,not initialized[board])
  return
 end
 initialized[board]=true
 setRows(board,result)
end

local function updateAll()
 if updating then return end
 updating=true
 local daily=workspace:FindFirstChild("DailyStrengthRankingBoard")
 local total=workspace:FindFirstChild("TotalStrengthRankingBoard")
 local today=Data.Today()
 updateBoard(daily,function()
  local data,err=Data.GetDailyStrengthTop(10,today)
  if not data then error(err or "daily ranking unavailable") end
  return data
 end)
 updateBoard(total,function()
  local data,err=Data.GetTotalStrengthTop(10)
  if not data then error(err or "total ranking unavailable") end
  return data
 end)
 updating=false
end

task.spawn(function()
 task.wait(2)
 while true do
  updateAll()
  task.wait(UPDATE_INTERVAL)
 end
end)

