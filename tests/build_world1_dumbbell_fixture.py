"""Fresh local PlaceId=0 fixture. Production persistence is NEVER packaged.

Requires the geometry-only Studio export at tmp/Dumbbell3D/geometry.json.
Run the generated runner only with this generated place. Its preflight must
succeed before ExecuteMultiplayerTestAsync can be called.
"""
from pathlib import Path
import sys,json,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from dumbbell_model_xml import model_xml,property_xml
OUT=ROOT/'tmp/Dumbbell3D';OUT.mkdir(parents=True,exist_ok=True)
game=ET.Element('roblox',version='4');nodes={():game}
def node(path,kind='Folder'):
    path=tuple(path)
    if path in nodes:return nodes[path]
    el=ET.SubElement(node(path[:-1]),'Item',{'class':kind,'referent':'F'+str(len(nodes))})
    ET.SubElement(ET.SubElement(el,'Properties'),'string',name='Name').text=path[-1]
    nodes[path]=el;return el
def prop(el,name,t,v):property_xml(el.find('Properties'),name,{'T':t,'V':v})
for s in ['Workspace','ReplicatedStorage','ServerStorage','ServerScriptService','StarterPlayer','Players']:node([s],s)
node(['StarterPlayer','StarterPlayerScripts'],'StarterPlayerScripts')
prop(nodes[('StarterPlayer',)],'CharacterRigType','token',1)
prop(nodes[('Workspace',)],'StreamingEnabled','boolean',False)
names={
 'ReplicatedStorage.Config':['World1DumbbellVisualConfig','DumbbellItemMaster','DumbbellStandConfig','World2GameplayConfig','TreadmillConfig'],
 'ReplicatedStorage.Modules':['InventoryCounts'],
 'ServerScriptService.Services':['World1DumbbellVisuals','DumbbellService','TrainingLobbyAreaService','DumbbellStandService','TrainingManager'],
 'ServerScriptService.Config':['MuscleScaleConfig'],
}
sources={}
for folder,items in names.items():
    for name in items:sources[folder+'.'+name]=(ROOT/'src'/folder.replace('.','/')/(name+'.luau')).read_text(encoding='utf-8')
for name in ['DumbbellDisplayController','World1DumbbellExhibitController']:
    sources['ServerScriptService.Systems.Controllers.'+name]=(ROOT/'src/ServerScriptService/Systems/Controllers'/(name+'.server.luau')).read_text(encoding='utf-8')
for name in ['PlayableBodyPrototype','PlayableShapeConfig']:
    sources['ServerStorage.BodyPrototype_20261114.'+name]=(ROOT/'prototypes/BodyPrototype_20261114'/(name+'.luau')).read_text(encoding='utf-8')
# Fixture-only gate: actual body sizing and existing held-controller branches.
# This substitution never goes back into the copy's Source.
for path in ['ServerStorage.BodyPrototype_20261114.PlayableBodyPrototype','ServerScriptService.Systems.Controllers.DumbbellDisplayController']:
    sources[path]=sources[path].replace('game.PlaceId==126576845524886','game.PlaceId==0').replace('game.PlaceId~=126576845524886','game.PlaceId~=0')
sources['ReplicatedStorage.Config.TrainingConfig']='return table.freeze({BaseGain=1,WalkInterval=0.5,TrainingInterval=0.5})'
sources['ServerScriptService.Services.PlayerDataService']='''local states={} local M={}
function M.Get(p)
 if not states[p] then local owned={} for i=1,12 do owned[string.format("NORMAL_%02d",i)]=1 end owned.W2_NORMAL_01=1
 states[p]={Loaded=true,Data={OwnedDumbbells=owned,EquippedDumbbell="",Strength=123,Win=456}} end return states[p]
end
function M.IsLoaded(p)return M.Get(p).Loaded end
function M.SetEquippedDumbbell(p,id) local s=M.Get(p) if not s.Loaded or (id~="" and not s.Data.OwnedDumbbells[id]) then return false end
 s.Data.EquippedDumbbell=id;p:SetAttribute("EquippedDumbbell",id);return true end
return M'''
sources['ServerScriptService.Services.StrengthManager']='return {AddStrength=function(p,g,n,m)p:SetAttribute("FixtureTicks",(p:GetAttribute("FixtureTicks") or 0)+1);p:SetAttribute("FixtureGain",g*n*m) end}'
sources['ServerScriptService.Services.GamePassService']='return {AreEffectsEnabled=function()return false end,HasPremiumTreadmill=function()return false end}'
sources['ServerScriptService.Services.ItemService']='return {GetBeltTreadmillBonus=function()return 0 end}'
sources['ServerScriptService.Services.PotionService']='return {GetTrainingBonus=function()return 0 end}'
for side in ['server','client']:
    path='ServerScriptService.__DumbbellFixture' if side=='server' else 'StarterPlayer.StarterPlayerScripts.__DumbbellFixture'
    sources[path]=(ROOT/'tests'/('World1DumbbellFixture.'+side+'.luau')).read_text(encoding='utf-8')
for path,source in sources.items():
    for token in ['DataStoreService','MarketplaceService','BadgeService','AnalyticsService','MemoryStoreService','GetDataStore','GetOrderedDataStore']:
        assert token not in source,(path,token)
    kind='LocalScript' if path.startswith('StarterPlayer') else 'Script' if '.Controllers.' in path or path.endswith('__DumbbellFixture') else 'ModuleScript'
    prop(node(path.split('.'),kind),'Source','ProtectedString',source)
geometry=json.loads((OUT/'geometry.json').read_text(encoding='utf-8'))
for row in geometry:
    if row['Path'].endswith('CurrentAvatarReference'):continue
    parent=node(row['Path'].split('.')[:-1]);model_xml(parent,row['Tree'])
def part(path,size,position,kind='Part'):
    p=node(path.split('.'),kind);prop(p,'Size','Vector3',size);prop(p,'Anchored','boolean',True)
    prop(p,'CFrame','CFrame',position+[1,0,0,0,1,0,0,0,1]);return p
part('Workspace.GeneratedMap.TrainingArea.Floor',[1000,1,1000],[0,-.5,0])
part('Workspace.World2Map.TrainingArea.Floor',[1000,1,1000],[2000,-.5,0])
spawn=part('Workspace.FixtureSpawn',[8,1,8],[0,-.5,0],'SpawnLocation');prop(spawn,'Neutral','boolean',True)
node('Workspace.Treadmills.Normal01'.split('.'),'Model')
part('Workspace.Treadmills.Normal01.Deck',[20,1,24],[50,.5,0])
area=part('Workspace.Treadmills.Normal01.Area',[20,.8,24],[50,1,0]);prop(area,'CanCollide','boolean',False);prop(area,'Transparency','number',1)
fixture=OUT/'DumbbellFixture.rbxlx';ET.ElementTree(game).write(fixture,encoding='utf-8',xml_declaration=True)
runner='''assert(game.PlaceId==0,"ISOLATION FAILED: cloud place")
assert(not game:GetService("RunService"):IsRunning(),"Already playing")
assert(game.ServerScriptService:FindFirstChild("__DumbbellFixture"),"Missing fixture marker")
local n=0
for _,s in game:GetDescendants()do if s:IsA("LuaSourceContainer")then
 assert(loadstring(s.Source),s:GetFullName())
 for _,t in {"DataStoreService","MarketplaceService","BadgeService","AnalyticsService","MemoryStoreService","GetDataStore","GetOrderedDataStore"}do assert(not s.Source:find(t,1,true),"ISOLATION FAILED: "..t)end
 n+=1
end end
assert(n==EXPECTED,"ISOLATION FAILED: unexpected sources "..n)
-- Restore compiled PBR data through the registered Model assets. Raw typed
-- XML covers geometry, but cannot export Roblox's private compiled TexturePack.
-- This is an ordinary authorized asset import before Play; any failure aborts.
for _,model in game.ServerStorage.World1DumbbellModels:GetChildren()do
 local id=model:GetAttribute("SourceModelAssetId")
 if id then
  local package=game:GetService("InsertService"):LoadAsset(id)
  local source=package:FindFirstChildWhichIsA("MeshPart",true)
  assert(source and source:FindFirstChildWhichIsA("SurfaceAppearance"),"Registered mesh/PBR material missing: "..model.Name)
  for _,container in {model,workspace.PerStepButtons[model.Name:sub(-2):gsub("^0","")].World1DumbbellExhibit}do
   local mesh=assert(container:FindFirstChildWhichIsA("MeshPart",true))
   -- Preserve native mesh-size metadata and compiled PBR assets together.
   local imported=source:Clone()
   for _,x in imported:GetDescendants()do if not x:IsA("SurfaceAppearance")then x:Destroy()end end
   imported.Name=mesh.Name;imported.Size=mesh.Size;imported.CFrame=mesh.CFrame;imported.PivotOffset=mesh.PivotOffset
   imported.Anchored=true;imported.CanCollide=false;imported.CanTouch=false;imported.CanQuery=false;imported.Massless=true
   imported.Parent=mesh.Parent;mesh:Destroy()
  end
  package:Destroy()
 end
end
local materials=0
for _,s in game.ServerStorage.World1DumbbellModels:GetDescendants()do if s:IsA("SurfaceAppearance")then
 for _,k in {"ColorMap","NormalMap","RoughnessMap","MetalnessMap"}do
  assert(s[k]~="" and s[k.."Content"].Uri==s[k],"Fixture material did not deserialize: "..s:GetFullName().." "..k)
 end
 materials+=1
end end
assert(materials==11,"Fixture must contain 11 PBR materials")
game.ServerStorage.BodyPrototype_20261114:SetAttribute("Enabled",true)
game.ReplicatedStorage:SetAttribute("DumbbellFixture",true)
print("DUMBBELL_ISOLATION_CONFIRMED",game.PlaceId,n)
local ok,result=pcall(function()return game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2,{Name="World1Dumbbell3D"})end)
print("DUMBBELL_RESULT "..game.HttpService:JSONEncode({Success=ok,Result=result}))
print("DUMBBELL_EDIT_RETURNED",game:GetService("StudioTestService").EditModeActive)
'''.replace('EXPECTED',str(len(sources)))
(OUT/'RunFixture.luau').write_text(runner,encoding='utf-8')
(OUT/'FixtureManifest.json').write_text(json.dumps({'Sources':{p:len(s) for p,s in sources.items()},'StoreCode':False,'PlaceId':0,'BodyGateOnlyAdapted':True},indent=2))
print(json.dumps({'Sources':len(sources),'Bytes':fixture.stat().st_size,'Fixture':str(fixture)}))
