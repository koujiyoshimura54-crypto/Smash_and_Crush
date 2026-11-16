-- Read-only geometry export for the isolated visual fixture; no Sources included.
assert(game.PlaceId==126576845524886 and not game.RunService:IsRunning())
local roots={game.ServerStorage.World2DumbbellModels,workspace.World2Map.TrainingArea.DumbbellDisplays}
local ids={};local sequence=0
for _,root in roots do
 for _,x in {root,unpack(root:GetDescendants())}do sequence+=1;ids[x]="W2G"..sequence end
end
local function typed(value)
 local kind=typeof(value)
 if kind=="Instance"then return {T="Ref",V=ids[value]or "null"}end
 if kind=="EnumItem"then return {T="token",V=value.Value}end
 if kind=="Vector3"then return {T=kind,V={value.X,value.Y,value.Z}}end
 if kind=="Vector2"then return {T=kind,V={value.X,value.Y}}end
 if kind=="Color3"then return {T=kind,V={value.R,value.G,value.B}}end
 if kind=="CFrame"then return {T=kind,V={value:GetComponents()}}end
 if kind=="UDim2"then return {T=kind,V={value.X.Scale,value.X.Offset,value.Y.Scale,value.Y.Offset}}end
 if kind=="UDim"then return {T=kind,V={value.Scale,value.Offset}}end
 if kind=="string"or kind=="number"or kind=="boolean"then return {T=kind,V=value}end
end
local common={"Name","Size","CFrame","PivotOffset","PrimaryPart","Anchored","CanCollide","CanTouch","CanQuery","Massless","Transparency","Reflectance","Color","Material","Shape","MeshId","TextureID","CollisionFidelity","RenderFidelity","ColorMap","NormalMap","RoughnessMap","MetalnessMap","AlphaMode","DoubleSided","Adornee","StudsOffset","StudsOffsetWorldSpace","AlwaysOnTop","MaxDistance","LightInfluence","Enabled","Visible","Position","AnchorPoint","BackgroundColor3","BackgroundTransparency","BorderSizePixel","ZIndex","LayoutOrder","ClipsDescendants","Text","TextColor3","TextSize","TextScaled","TextWrapped","TextTransparency","TextStrokeColor3","TextStrokeTransparency","Font","TextXAlignment","TextYAlignment","Image","ImageColor3","ImageTransparency","ScaleType","CornerRadius","Thickness","ApplyStrokeMode","VerticalAlignment","HorizontalAlignment","FillDirection","SortOrder","Padding","PaddingTop","PaddingBottom","PaddingLeft","PaddingRight"}
local function serialize(x)
 if x:IsA("LuaSourceContainer")or x:IsA("PackageLink")then return nil end
 -- Runtime owner recreates exhibits from native registered templates.
 if x.Name=="World2DumbbellExhibit"then return nil end
 local row={Class=x.ClassName,Id=ids[x],Properties={},Attributes={},Tags=game.CollectionService:GetTags(x),Children={}}
 for _,key in common do local ok,value=pcall(function()return x[key]end);if ok then local p=typed(value);if p then row.Properties[key]=p end end end
 if x:IsA("MeshPart")then row.Properties.InitialSize=typed(x.MeshSize)end
 for key,value in x:GetAttributes()do local p=typed(value);if p then row.Attributes[key]=p end end
 for _,child in x:GetChildren()do local c=serialize(child);if c then table.insert(row.Children,c)end end
 return row
end
local rows={}
for _,root in roots do table.insert(rows,{Path=root:GetFullName(),Tree=serialize(root)})end
_G.__W2VisualGeometry=game.HttpService:JSONEncode(rows)
return #_G.__W2VisualGeometry
