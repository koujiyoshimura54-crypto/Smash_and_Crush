-- Edit fixture only: native purchased GUI, isolated Forge/player/analytics boundaries.
assert(game.PlaceId==126576845524886)
assert(not _G.OreSlotsReview)
local RS,SG=game.ReplicatedStorage,game:GetService("StarterGui")
assert(not SG:FindFirstChild("MergeShopGui"),"Preserve an existing view")
local q={OriginalShow=SG.ShowDevelopmentGui,Requests={},ItemRequests={},Clicks={},Results={}}
local changed,completed=Instance.new("BindableEvent"),Instance.new("BindableEvent")
local forge={State={Loaded=true,Token="isolated",Generation=1,Sequence=0,World2Unlocked=false,Ores={ORE_001=7,ORE_002=3,ORE_003=2,ORE_004=1,ORE_005=1,ORE_006=1}},Changed=changed.Event,Completed=completed.Event}
local pending=false
function forge.IsPending()return pending end
function forge.Refresh()return forge.State end
function forge.Request(action,fields)
 if pending then return false end
 table.insert(q.Requests,{Action=action,Materials=table.clone(fields.Materials)})
 pending=true;changed:Fire(forge.State);return true
end
function q.State(nextState,isPending)forge.State=nextState;pending=isPending==true;changed:Fire(nextState);task.wait()end
q.Forge=forge;q.ForgeChanged=changed;q.ForgeCompleted=completed
local analytics={}
function analytics.BindOre(reader,event)q.AnalyticsReader=reader;q.AnalyticsConnection=event:Connect(function()q.AnalyticsSnapshot=reader()end)end
local pets={Owned={p1="Dog",p2="Dog",p3="Grey Cat"},Equipped={}}
local pet={}
function pet.state()return pets end
function pet.busy()return false end
function pet.request(action,ids)table.insert(q.Requests,{Action=action,PetIds=ids});return false,"FixtureFailure"end
function pet.createMaterialTile(id,name,count,parent,callback)
 local tile=RS.Assets.Templates.PetInventory:Clone();tile.Parent=parent
 local c=tile.Button.Activated:Connect(callback);q.Clicks[name]=callback
 return tile,function()c:Disconnect();tile:Destroy()end
end
local function isolatedRequire(m)
 if m==RS.Modules.ForgeClient then return forge
 elseif m==RS.Modules.FirstPlayAnalyticsClient then return analytics
 elseif m==RS.Modules.UIFeedback then return {Play=function()end}end
 return require(m)
end
local background=Instance.new("ScreenGui");background.Name="CodexOreBackdrop";background.IgnoreGuiInset=true;background.DisplayOrder=10000
local fill=Instance.new("Frame");fill.Size=UDim2.fromScale(1,1);fill.BackgroundColor3=Color3.fromRGB(40,47,57);fill.Parent=background;background.Parent=SG
local gui=Instance.new("ScreenGui");gui.Name="CodexOrePreview";gui.IgnoreGuiInset=SG.StrengthGui.IgnoreGuiInset;gui.ScreenInsets=SG.StrengthGui.ScreenInsets;gui.Parent=SG
local donor=SG.StrengthGui.ShopPanel:Clone()
for _,x in donor:GetDescendants()do if x:IsA("LuaSourceContainer")then x:Destroy()end end
donor.Visible=false;donor.Parent=gui
local source=RS.Modules.MergeShopView.Source
-- Record the original callbacks; calls to them in tests are synthetic, not physical input.
source=source:gsub("local connection=tile.Button.Activated:Connect%(onClick%)","ctx.Capture(entry.Key,input,onClick);local connection=tile.Button.Activated:Connect(onClick)")
local gameStub=setmetatable({Players={LocalPlayer={PlayerScripts={FindFirstChild=function()return nil end}}}},{__index=function(_,key)return game[key]end})
local build=assert(loadstring("return function(require,game)\n"..source.."\nend"))()(isolatedRequire,gameStub)
local view=build({RS=RS,gui=gui,Master=require(RS.Config.ItemMaster),Egg=require(RS.Modules.Egg),PetClient=pet,
 EggViewport=require(RS.Modules.LimitedPetViewport),
 Capture=function(key,input,callback)q.Clicks[(input and "input:" or "material:")..key]=callback end,
 OnMerge=function(materials)table.insert(q.ItemRequests,table.clone(materials))end})
SG.MergeShopGui.DisplayOrder=10001;SG.ShowDevelopmentGui=true
q.View=view;q.Gui=gui;q.Pet=pet;q.Require=isolatedRequire
function q.SetCount(n)view:Clear();for i=1,n do view:ActivateMaterial("ORE_001")end;task.wait()end
function q.Snapshot()
 local inputs=view.Drop.Inputs;local g=view:GetOreTutorialState();local rows={}
 for _,x in inputs:GetChildren()do if x:IsA("GuiObject")and x.Visible then table.insert(rows,{Name=x.Name,P={x.AbsolutePosition.X,x.AbsolutePosition.Y},S={x.AbsoluteSize.X,x.AbsoluteSize.Y},Next=x:GetAttribute("NextRequired")})end end
 table.sort(rows,function(a,b)return a.P[1]<b.P[1]end)
 return {Count=g.SelectedCount,Valid=g.Valid,Pending=g.Pending,Slots=rows,Merge=view.Merge.Interactable,Viewport=tostring(workspace.CurrentCamera.ViewportSize),Gui=tostring(gui.AbsoluteSize),Total=view.Drop.Total.Text}
end
function q.Stop()
 view:Destroy();if q.AnalyticsConnection then q.AnalyticsConnection:Disconnect()end
 changed:Destroy();completed:Destroy();gui:Destroy();background:Destroy();SG.ShowDevelopmentGui=q.OriginalShow;_G.OreSlotsReview=nil
end
q.View:Show();q.View:SelectTab("Ore");q.View:SetPetState(pets)
_G.OreSlotsReview=q
return game.HttpService:JSONEncode(q.Snapshot())
