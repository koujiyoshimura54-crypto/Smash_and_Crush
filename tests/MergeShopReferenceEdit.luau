-- Edit-only, isolated UI assertions. Requires the actual buildMergeShop factory mounted
-- into CodexMergeReferencePreview with synthetic owned/count projections and a NO-REMOTE
-- OnMerge counter. Never run against a PlayerGui or live player data.
local v=assert(_G.CodexMergeView)
assert(_G.CodexMergePreviewHost.Parent==game.StarterGui)
assert(_G.CodexMergePreviewHost.Name=="CodexMergeReferencePreview")
assert(not game:GetService("RunService"):IsRunning())
local n=0
local function eq(a,b,message) n+=1;assert(a==b,(message or "")..": "..tostring(a).." ~= "..tostring(b)) end
local function count() return v.Root.MainScrollingFrame.Selected:GetAttribute("SelectedCount") end
local function result() return v.Root.MainScrollingFrame.Result end
local function petState()
 return {Owned={a="Dog",b="Dog",c="Grey Cat",d="Bear",e="Bat",f="Cow",g="Elephant",h="Turtle",paid="Pet_042",worn="Sheep"},Equipped={"worn"}}
end
v:Show();v:SetPetState(petState());v:SelectTab("Pet")
eq(count(),0);eq(v.List:FindFirstChild("paid"),nil);eq(v.List:FindFirstChild("worn"),nil)
eq(result():FindFirstChild("Basic"),nil);eq(v.Merge.Interactable,false)
for _,id in {"a","c","d","e"} do
 local icon=v.List[id].Main.Icon
 eq(icon.Image,game.ReplicatedStorage.Assets.Icons.Pets[v.List[id]:GetAttribute("MaterialName")].Texture)
 eq(icon.Visible,true);eq(icon.ImageTransparency,0)
 n+=1;assert(icon.ZIndex>v.List[id].Main.ZIndex)
end
v:ActivateMaterial("a");v:ActivateMaterial("b")
eq(count(),2);eq(result().Basic.Percent.Text,"60%");eq(result().Rare.Percent.Text,"40%")
eq(v.Merge.Interactable,false);eq(v.List.a.Main.Checkmark.Visible,true);eq(v.List.b.Main.Checkmark.Visible,true)
local tile=v.List.c
local start=tile.AbsolutePosition+tile.AbsoluteSize/2
local drop=v.Drop.AbsolutePosition+v.Drop.AbsoluteSize/2
v:PressMaterial("c",start,false,nil);v:MovePointer(drop)
eq(v.Root:FindFirstChild("DraggingMaterial")~=nil,true)
n+=1;assert(tile.Main.Icon.ImageTransparency>.6)
eq(count(),2,"drag is uncommitted")
v:ReleasePointer(drop);v:ActivateMaterial("c")
eq(count(),3,"release and Activated cannot immediately deselect")
eq(v.Root:FindFirstChild("DraggingMaterial"),nil);eq(tile.Main.Icon.ImageTransparency,0)
v:PressMaterial("d",start,false,nil);v:MovePointer(Vector2.zero);v:ReleasePointer(Vector2.zero)
eq(count(),3,"outside drop cancelled")
v:PressMaterial("e",start,true,nil);v:MovePointer(start+Vector2.new(0,30));v:ReleasePointer(drop)
eq(count(),3,"touch scrolling does not select")
local state=petState();state.Owned.a=nil;state.Equipped={"b","worn"}
v:SetPetState(state);eq(count(),1);eq(v.List:FindFirstChild("a"),nil);eq(v.List:FindFirstChild("b"),nil)
v:Clear();eq(count(),0);eq(result():FindFirstChild("Basic"),nil)
state=petState();v:SetPetState(state)
v:ActivateMaterial("a");v:ActivateMaterial("f")
eq(result().Rare.Percent.Text,"92%");eq(result().Legendary.Percent.Text,"8%")
eq(result().Rare.NormalEggViewport.DisplayWorld.Rare.Name,"Rare")
eq(result().Legendary.NormalEggViewport.DisplayWorld.Legendary.Name,"Legendary")
v:Clear();v:ActivateMaterial("a");v:ActivateMaterial("h")
eq(result().Mythic.Percent.Text,"100%");eq(result().Mythic.NormalEggViewport.DisplayWorld.Mythic.Name,"Mythic")
v:SubmitItem();eq(_G.CodexMergePreviewSends,0,"Pet never submits")
v:SelectTab("Item");v:SelectTab("Pet");eq(count(),0)
v:Hide();eq(v.Root:FindFirstChild("DraggingMaterial"),nil)
v:Show();v:SelectTab("Pet");eq(count(),0)
v:SelectTab("Item")
local itemState={RequiredCount=3,Recipes={
 {ItemId="GLOVE_UNCOMMON_FIRE",ResultItemId="GLOVE_RARE_FIRE",Count=6,CanMerge=true},
 {ItemId="PROTEIN_COMMON_FIRE",ResultItemId="PROTEIN_UNCOMMON_FIRE",Count=2,CanMerge=false},
}}
v:SetItemState(itemState,true,false,"")
eq(#v.List:GetChildren(),5,"quantity projection, no persistent copy IDs")
eq(v.List["GLOVE_UNCOMMON_FIRE:3"].StackCount.Text,"+3 owned")
v:ActivateMaterial("GLOVE_UNCOMMON_FIRE:1");v:ActivateMaterial("PROTEIN_COMMON_FIRE:1")
eq(count(),1,"mixed recipe rejected")
v:ActivateMaterial("GLOVE_UNCOMMON_FIRE:2");v:ActivateMaterial("GLOVE_UNCOMMON_FIRE:3")
eq(count(),3);eq(result()["Rare Fire Glove"].ActualImage.Image,game.ReplicatedStorage.Config.ItemMaster and require(game.ReplicatedStorage.Config.ItemMaster).Get("GLOVE_RARE_FIRE").Image)
eq(v.Merge.Interactable,true)
v:SubmitItem();v:SubmitItem();eq(_G.CodexMergePreviewSends,1,"single stub request only, no real merge")
eq(v.Merge.Interactable,false)
itemState.Recipes[1].Count=2;itemState.Recipes[1].CanMerge=false
v:SetItemState(itemState,true,false,"");eq(count(),2);eq(v.Merge.Interactable,false)
eq(result():FindFirstChild("Rare Fire Glove"),nil)
v:Clear();eq(count(),0)
v:Hide();eq(#v.List:GetChildren(),0)
print("MERGE_REFERENCE_EDIT_PASS",n)
return n
