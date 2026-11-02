-- Local feedback for currently active, previously silent paths only.
-- Tokens are presentation-only; no save schema or receipt authority lives here.
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("SoundService")
local UIS=game:GetService("UserInputService")
local player=game:GetService("Players").LocalPlayer
local Config=require(RS.Config.UISoundConfig).Added
local M={}
local played,last,sounds={},{},{}
local buttons=setmetatable({},{__mode="k"})
local hovered=setmetatable({},{__mode="k"})
local pendingHover
local started=false
local progress,claims
local rejected={NotEnoughWin=true,InsufficientWin=true,NotEnoughItems=true,NotEnoughOres=true,
 NotEnoughDumbbells=true,NotOwned=true,TooManyOres=true,TooFewOres=true,InvalidAmount=true,
 InventoryFull=true,EquippedLastCopy=true,InvalidSale=true,WorldNotReached=true,LevelTooLow=true,DailyLocked=true,NotReady=true,
 RewardLocked=true,Locked=true,TooManyMaterials=true,NotEnoughMaterials=true,InvalidMaterials=true,InsufficientMaterials=true,MinimumNotMet=true}
local function generation() return tostring(player:GetAttribute("ForgeSessionToken") or "") end
function M.Play(kind,key)
 local setting=Config[kind]
 if not setting then return false end
 local token=key and generation()..":"..kind..":"..tostring(key)
 if token and played[token] then return false end
 if token then played[token]=true end
 local now=os.clock()
 if now-(last[kind] or -math.huge)<setting.Interval then return false end
 local source=SS:FindFirstChild("UI") and SS.UI:FindFirstChild(setting.Sound)
 if not source or not source:IsA("Sound") then return false end
 last[kind]=now
 if kind=="Hover" then
  -- All hover owners play the same live source: one volume/mute/group control.
  source:Stop();source.TimePosition=0;source:Play()
  return true
 end
 local sound=sounds[setting.Sound]
 if not sound then
  sound=source:Clone();sound.Name="AddedUIFeedback_"..setting.Sound
  sound:SetAttribute("AddedUIFeedback",true);sound.Looped=false;sound.PlayOnRemove=false
  sound.Parent=SS;sounds[setting.Sound]=sound
 end
 -- Read the source at playback so an existing mute setting is respected.
 sound.Volume=source.Volume*setting.Volume;sound.PlaybackSpeed=source.PlaybackSpeed*setting.Speed
 sound:Stop();sound.TimePosition=0;sound:Play()
 return true
end
function M.Denied(code,key)
 if rejected[code] or type(code)=="string" and (code:match("^NotEnough") or code:match("^SelectAtLeast") or code=="SelectMaterials") then return M.Play("Denied",key) end
 return false
end
local function usable(button)
 if not button.Parent or not button.Active or not button.Interactable then return false end
 local ancestor=button
 while ancestor and ancestor~=player.PlayerGui do
  if ancestor:IsA("GuiObject") and not ancestor.Visible then return false end
  if ancestor:IsA("ScreenGui") and not ancestor.Enabled then return false end
  ancestor=ancestor.Parent
 end
 return ancestor==player.PlayerGui
end
function M.CanInteract(button) return usable(button) end
function M.Hover(button)
 if not usable(button) or UIS:GetLastInputType()~=Enum.UserInputType.MouseMovement or hovered[button] then return false end
 hovered[button]=true
 if pendingHover then
  -- A parent card and its child purchase target can enter in the same frame.
  if button:IsDescendantOf(pendingHover) then pendingHover=button end
  return false
 end
 pendingHover=button
 task.defer(function()
  local target=pendingHover;pendingHover=nil
  if target and hovered[target] and usable(target) then M.Play("Hover") end
 end)
 return true
end
function M.Leave(button) hovered[button]=nil end
function M.Button(button,hover)
 if not usable(button) then return false end
 -- These buttons already call the shared hover entry from their existing owner.
 if button:GetAttribute(hover and "ExistingHoverSE" or "ExistingClickSE") then return false end
 if hover then return M.Hover(button) end
 return M.Play("Click")
end
function M.BindButton(button)
 if not button:IsA("GuiButton") or buttons[button] then return end
 -- This entire existing tree is already owned by ButtonClient.
 local screen=button:FindFirstAncestorWhichIsA("ScreenGui")
 if screen and screen.Name=="ScreenGui" then return end
 buttons[button]=true
 button.MouseEnter:Connect(function()M.Button(button,true)end)
 button.MouseLeave:Connect(function()M.Leave(button)end)
 button.Activated:Connect(function()M.Button(button,false)end)
end
function M.ObserveStrength(view)
 if type(view)~="table" or type(view.GrantedTotal)~="number" or type(view.SessionToken)~="string" then return end
 if not progress or progress.Session~=view.SessionToken then
  progress={Session=view.SessionToken,Total=view.GrantedTotal,Level=view.Level}
  return -- loading/rejoining/reset is a baseline, never a reward/level-up event
 end
 if view.GrantedTotal>progress.Total then
  progress.Total=view.GrantedTotal
  M.Play("Offline","grant:"..view.SessionToken..":"..view.GrantedTotal)
 end
end
function M.Level(value)
 if not progress or progress.Session~=generation() or type(value)~="number" then return end
 local previous=progress.Level;progress.Level=value
 if type(previous)=="number" and value>previous then M.Play("Level") end
end
function M.Rebirth(result)
 if type(result)~="table" then return end
 if result.Type=="Success" and type(result.RebirthCount)=="number" then
  return M.Play("Rebirth",result.RebirthCount)
 elseif result.Type=="Denied" then return M.Play("Denied") end
end
function M.Purchase(channel,result)
 if type(result)~="table" then return end
 if result.Success==false then return M.Denied(result.Code,result.FeedbackId) end
 if result.Success~=true then return end
 local key
 if channel=="Item" and result.Code=="Purchased" then key=result.FeedbackId
 elseif channel=="Dumbbell" and result.PurchaseConfirmed then key=result.FeedbackId
 elseif channel=="Aura" and result.Code=="Purchased" then key=result.State and result.State.EquippedAura
 elseif channel=="Speed" and result.Action=="Upgrade" and result.State then key=result.State.UpgradeStage
 elseif channel=="Capacity" then key=result.FeedbackId end
 if key~=nil and key~="" then return M.Play("Purchase",channel..":"..tostring(key)) end
end
function M.Forge(op,response)
 if type(op)~="table" or type(response)~="table" then return end
 if response.Success then
  if op.Action=="MergeOre" then return M.Play("Merge","ore:"..op.Id)
  elseif op.Action=="SellOre" or op.Action=="SellDumbbell" then return M.Play("Sale",op.Id) end
 else return M.Denied(response.Code,op.Id) end
end
function M.ItemMerge(result)
 if type(result)~="table" then return end
 if result.Success and result.ResultItemId then return M.Play("Merge","item:"..result.RequestId)
 elseif result.Success==false then return M.Denied(result.Code,result.RequestId) end
end
function M.Reward(group,result)
 if type(result)~="table" or type(result.State)~="table" or result.State.Loaded~=true then return end
 local state=result.State
 local session=generation()
 if not claims or claims.Session~=session then claims={Session=session} end
 local previous=claims[group]
 local states=state.States or {}
 local ids={}
 for id,status in pairs(states) do
  local explicit=result.Success==true and (result.RewardId==id or group=="Daily" and result.RewardId==nil and id=="Day"..tostring(state.ClaimedDays))
  if status=="Claimed" and ((previous and previous[id] and previous[id]~="Claimed") or (explicit and (not previous or previous[id]~="Claimed"))) then table.insert(ids,id) end
 end
 claims[group]=table.clone(states)
 if #ids>0 then
  table.sort(ids)
  local win=true
  for _,id in ipairs(ids) do
   local reward=group=="Time" and require(RS.Config.TimeRewardConfig).Get(id)
    or id~="VIP" and require(RS.Config.DailyRewardConfig).Get(tonumber(id:match("^Day(%d+)$")))
   if id~="VIP" and (not reward or reward.RewardType~="Win") then win=false end
  end
  return M.Play(win and "WinReward" or "Reward",group..":"..tostring(state.DateUTC or "")..":"..table.concat(ids,","))
 elseif result.Success==false then return M.Denied(result.Code) end
end
function M.Start()
 if started then return end
 started=true
 local pg=player:WaitForChild("PlayerGui")
 for _,o in pg:GetDescendants() do M.BindButton(o) end
 pg.DescendantAdded:Connect(M.BindButton)
 local remotes=RS:WaitForChild("Remotes")
 remotes:WaitForChild("RebirthRequest").OnClientEvent:Connect(M.Rebirth)
 for name,channel in pairs({ItemPurchaseRequest="Item",DumbbellPurchaseRequest="Dumbbell",
  AuraPurchaseRequest="Aura",SpeedPurchaseRequest="Speed"}) do
  remotes:WaitForChild(name).OnClientEvent:Connect(function(result)M.Purchase(channel,result)end)
 end
 remotes:WaitForChild("PurchaseInventoryCapacity").OnClientEvent:Connect(function(ok,code,id)
  M.Purchase("Capacity",{Success=ok,Code=code,FeedbackId=id})
 end)
 remotes:WaitForChild("TimeRewardClaim").OnClientEvent:Connect(function(result)M.Reward("Time",result)end)
 remotes:WaitForChild("DailyRewardClaim").OnClientEvent:Connect(function(result)M.Reward("Daily",result)end)
 require(RS.Modules.ForgeClient).Completed:Connect(M.Forge)
 player:GetAttributeChangedSignal("Level"):Connect(function()
  -- One final attribute value for a multi-level gain in the same update.
  task.defer(function()M.Level(player:GetAttribute("Level"))end)
 end)
end
return M
