local gui=script.Parent
local nav=gui:WaitForChild("PreviewNavigation")
local tabs=nav:WaitForChild("Tabs")
local pageNames={"Right","Left","Notifications","Settings","Group","Shop","Wheel","DailyRewards","TimeRewards","Confirm","Gifting","Codes","Friends","PromptUi"}

local function revealUsefulContent(root)
 root.Visible=true
 if root.Name=="Notifications" then
  local template=root:FindFirstChild("Template",true)
  if template and template:IsA("GuiObject") then template.Visible=true end
 elseif root.Name=="DailyRewards" or root.Name=="TimeRewards" then
  for _,child in ipairs(root:GetDescendants()) do
   if child:IsA("GuiObject") and (child.Name=="Template" or child.Name:match("^%d+$")) then child.Visible=true end
  end
 elseif root.Name=="Shop" or root.Name=="Gifting" then
  for _,child in ipairs(root:GetDescendants()) do
   if child:IsA("GuiObject") and child.Name=="Template" then child.Visible=true end
  end
 end
end

local function show(targets,selected)
 for _,name in ipairs(pageNames) do
  local page=gui:FindFirstChild(name)
  if page and page:IsA("GuiObject") then page.Visible=false end
 end
 for target in string.gmatch(targets,"[^|]+") do
  local page=gui:FindFirstChild(target)
  if page and page:IsA("GuiObject") then revealUsefulContent(page) end
 end
 for _,button in ipairs(tabs:GetChildren()) do
  if button:IsA("TextButton") then
   button.BackgroundColor3=button==selected and Color3.fromRGB(205,151,26) or Color3.fromRGB(48,51,63)
  end
 end
end

for _,button in ipairs(tabs:GetChildren()) do
 if button:IsA("TextButton") then
  button.Activated:Connect(function()
   show(button:GetAttribute("Targets") or "",button)
  end)
 end
end

local first=tabs:FindFirstChild("Tab01")
if first then show(first:GetAttribute("Targets"),first) end
