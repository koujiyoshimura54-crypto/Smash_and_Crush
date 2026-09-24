-- Manual, isolated presentation checks; no player data, purchase, or authored UI mutation.
local M={}
function M.Run()
 assert(game:GetService("RunService"):IsStudio(),"Studio only")
 local modules=game.ReplicatedStorage.Modules
 local results={}
 local function test(name,fn) local ok,err=pcall(fn);table.insert(results,{Name=name,Pass=ok,Error=not ok and tostring(err) or nil}) end
 test("Marketplace helpers before first request / fallback",function()
  local copy=modules.MarketplacePrice:Clone()
  local price=require(copy)
  assert(price.Format(nil)=="..." and price.Format(90)=="90" and price.Format(90," Robux")=="90 Robux")
  local amount,source=price.Get(0,Enum.InfoType.GamePass,99)
  local label=Instance.new("TextLabel");price.Apply(label,amount,source," Robux")
  assert(label.Text=="99 Robux" and label:GetAttribute("PriceSource")=="ConfigFallback")
  label:Destroy();copy:Destroy()
 end)
 test("Badge rendering preserves template geometry",function()
  local B=require(modules.BadgeRenderer)
  local template=Instance.new("Frame");template.Size=UDim2.fromOffset(23,24);template.Position=UDim2.fromOffset(8,9)
  local text=Instance.new("TextLabel");text.Name="TextLabel";text.Parent=template
  local parent=Instance.new("Frame")
  local badge=B.GetOrClone(template,parent,"Notification")
  assert(badge.Size==template.Size and badge.Position==template.Position and not badge.Visible)
  assert(B.GetOrClone(template,parent,"Notification")==badge)
  B.SetVisible(badge,true);B.SetText(badge,"!");assert(badge.Visible and badge.TextLabel.Text=="!")
  parent:Destroy();template:Destroy()
 end)
 test("Inventory presentation / button state",function()
  local P=require(modules.InventoryPresentation)
  local label=Instance.new("TextLabel");local icon=Instance.new("ImageLabel");local button=Instance.new("TextButton")
  local size,position=button.Size,button.Position
  P.SetIdentity(label,icon,"Example","rbxassetid://1");assert(label.Text=="Example" and icon.Image=="rbxassetid://1")
  P.SetButtonEnabled(button,false);assert(not button.Active and not button.AutoButtonColor)
  P.SetButtonEnabled(button,true);assert(button.Active and button.AutoButtonColor and button.Size==size and button.Position==position)
  label:Destroy();icon:Destroy();button:Destroy()
 end)
 test("Existing number and reward formats",function()
  local N=require(modules.NumberFormat);local R=require(modules.RewardDisplay)
  assert(N.Format(1500)=="1.5K" and N.Plain(1250)=="1250")
  assert(R.GetText({RewardType="Win",Amount=3})=="Win +3")
  assert(R.GetCommunityText({WinAmount=3,ItemAmount=1})=="Win +3 and Item ×1")
 end)
 return results
end
return M
