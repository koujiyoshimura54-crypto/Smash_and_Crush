-- Read-only donor export for a separate PlaceId=0 UI fixture.
assert(game.PlaceId==126576845524886 and game.GameId==10765181857 and not game.RunService:IsRunning())
local function find(path)local x=game;for name in path:gmatch('[^.]+')do x=x[name]end;return x end
local paths={
 'ReplicatedStorage.Assets.Templates.PetInventory',
 'StarterGui.StrengthGui.ShopPanel.Top',
 'StarterGui.StrengthGui.ShopPanel.MainScrollingFrame.Holder.Card01_SecretPack.Owned',
 'StarterGui.StrengthGui.ShopPanel.MainScrollingFrame.Holder.Card01_SecretPack.Sunburst',
 'StarterGui.StrengthGui.InventoryPanel.Content.Dumbbells',
 'StarterGui.StrengthGui.WinLabel.TrophyIcon',
 'StarterGui.ScreenGui.Menus.RestockShop.Main.Common.Buy',
}
local sources={}
local names={Config={'World2GameplayConfig','DumbbellItemMaster','ItemMaster','ItemMergeConfig','DeveloperProductConfig','EnemyDropConfig','OreConfig','StrengthHUDStyle','LimitedEggConfig'},
 Modules={'MergeShopView','DumbbellInventoryView','PetMerge','Egg','OreMerge','InventoryCounts','InventoryPresentation','NumberFormat','HUDLayout','StrengthHUDPresentation','EquipmentButtonStyle','Config'}}
for folder,list in names do for _,name in list do local x=game.ReplicatedStorage[folder][name];sources[x:GetFullName()]=x.Source end end
local sequence=0
local function typed(v)
 local t=typeof(v)
 if t=='EnumItem'then return {T='token',V=v.Value}
 elseif t=='Color3'then return {T=t,V={v.R,v.G,v.B}}
 elseif t=='Vector2'then return {T=t,V={v.X,v.Y}}
 elseif t=='UDim'then return {T=t,V={v.Scale,v.Offset}}
 elseif t=='UDim2'then return {T=t,V={v.X.Scale,v.X.Offset,v.Y.Scale,v.Y.Offset}}
 elseif t=='ColorSequence'or t=='NumberSequence'then local a={};for _,k in v.Keypoints do table.insert(a,t=='ColorSequence'and{k.Time,k.Value.R,k.Value.G,k.Value.B,0}or{k.Time,k.Value,k.Envelope})end;return {T=t,V=a}
 elseif t=='string'or t=='number'or t=='boolean'then return {T=t,V=v}end
end
local keys={'Name','Size','Position','AnchorPoint','BackgroundColor3','BackgroundTransparency','BorderSizePixel','ZIndex','LayoutOrder','Visible','ClipsDescendants','Rotation','Text','TextColor3','TextSize','TextScaled','TextWrapped','TextTransparency','TextStrokeColor3','TextStrokeTransparency','Font','TextXAlignment','TextYAlignment','Image','ImageColor3','ImageTransparency','ScaleType','TileSize','ImageRectOffset','ImageRectSize','SliceScale','CornerRadius','Thickness','ApplyStrokeMode','StrokeSizingMode','Enabled','Transparency','Color','Offset','MinTextSize','MaxTextSize','VerticalAlignment','HorizontalAlignment','FillDirection','SortOrder','Padding','PaddingTop','PaddingBottom','PaddingLeft','PaddingRight','CellSize','CellPadding','FillDirectionMaxCells','ScrollBarThickness','ScrollBarImageColor3','CanvasSize','AutomaticCanvasSize','ScrollingDirection','Scale','AspectRatio','Active','Interactable','AutoButtonColor','AutoLocalize'}
local function serialize(x)
 if x:IsA('LuaSourceContainer')or x:IsA('PackageLink')then return nil end
 sequence+=1;local row={Class=x.ClassName,Id='UI'..sequence,Properties={},Attributes={},Tags={},Children={}}
 for _,key in keys do local ok,v=pcall(function()return x[key]end);if ok then local p=typed(v);if p then row.Properties[key]=p end end end
 for k,v in x:GetAttributes()do local p=typed(v);if p and (p.T=='string'or p.T=='number'or p.T=='boolean')then row.Attributes[k]=p end end
 for _,c in x:GetChildren()do local child=serialize(c);if child then table.insert(row.Children,child)end end
 return row
end
local rows={};for _,path in paths do table.insert(rows,{Path=path,Tree=serialize(find(path))})end
_G.__W208UIExport=game.HttpService:JSONEncode({Sources=sources,Geometry=rows})
return #_G.__W208UIExport
