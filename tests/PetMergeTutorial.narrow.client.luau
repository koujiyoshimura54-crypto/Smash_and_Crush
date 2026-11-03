local p=game.Players.LocalPlayer;local pg=p.PlayerGui;local RS=game.ReplicatedStorage
local old=pg.PetMergeTutorialGui;old.Enabled=false
_G.__PMView:Hide()
local host=Instance.new("ScreenGui");host.Name="__PMNarrow";host.DisplayOrder=60;host.IgnoreGuiInset=true;host.Parent=pg
local frame=Instance.new("Frame");frame.Name="Viewport";frame.Position=UDim2.fromOffset(330,6);frame.Size=UDim2.fromOffset(430,606);frame.BackgroundTransparency=1;frame.Parent=host
local donor=pg.StrengthGui.ShopPanel:Clone();donor.Visible=false;donor.Parent=frame
local pc=require(p.PlayerScripts.Services.PetClient)
local view=require(RS.Modules.MergeShopView)({gui=frame,RS=RS,PetClient=pc,Egg=require(RS.Modules.Egg),Master=require(RS.Config.ItemMaster),
 PurchasedInventory=game.StarterGui.ScreenGui.Menus.Inventory.Main,EggViewport=require(RS.Modules.LimitedPetViewport)})
view:SetPetState(pc.state());view:Show();view:SelectTab("Pet")
local overlay=game.StarterGui.PetMergeTutorialGui:Clone();overlay.Name="__PMNarrowOverlay";overlay.DisplayOrder=61;overlay.Parent=pg
local presentation=require(RS.Modules.OreMergeTutorialPresentation).Mount(overlay,view.Root.Top)
local function refresh()
 local s=view:GetPetTutorialState()
 presentation:Pin(overlay.Messages[s.Valid and "Merge" or "AddPets"].Value);presentation:Target(s.Valid and view.Merge or s.MaterialTarget or view.List)
end
local connection=view.Changed:Connect(refresh);refresh()
_G.__PMNarrow={View=view,Overlay=overlay,Presentation=presentation,Host=host,Connection=connection,Refresh=refresh}
local probe=Instance.new("BindableFunction");probe.Name="__PMNarrowProbe"
probe.OnInvoke=function(action)
 if action=="Select"then view:ActivateMaterial("Elephant");view:ActivateMaterial("Mammoth")
 elseif action=="Cleanup"then connection:Disconnect();presentation:Destroy();view:Destroy();host:Destroy();overlay:Destroy();old.Enabled=true;probe:Destroy();script:Destroy();return true end
 return {Width=frame.AbsoluteSize.X,Height=frame.AbsoluteSize.Y,Valid=view:GetPetTutorialState().Valid}
end
probe.Parent=p.PlayerScripts
