"""Build a fresh PlaceId=0 physics fixture; never run the connected copy.

The source allowlist uses the current Studio snapshot. Only the fixture gate is
adapted. Actual BodyPrototype, comparison ACKs, placement, TrainingManager,
StrengthManager and LevelProgression run. Persistence/external effects are
replaced at declared service boundaries, never in the original Studio.
"""
from pathlib import Path
import argparse, hashlib, json, re, sys, xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'tmp/World2Dumbbell3D';OUT.mkdir(parents=True,exist_ok=True)
sys.path.insert(0,str(ROOT/'tools'))
from dumbbell_model_xml import model_xml,property_xml
parser=argparse.ArgumentParser();parser.add_argument('--list-sources',action='store_true');parser.add_argument('--clients',type=int,default=1)
parser.add_argument('--variant',choices=['native','legacy_mesh','legacy_transition','serialized_mesh'],default='serialized_mesh')
parser.add_argument('--muscle-only',action='store_true')
parser.add_argument('--training-fixed',action='store_true')
parser.add_argument('--regression',action='store_true')
parser.add_argument('--lifecycle-only',action='store_true')
parser.add_argument('--training-only',action='store_true')
args=parser.parse_args()
names={
 'ReplicatedStorage.Config':['World1DumbbellVisualConfig','DumbbellItemMaster','DumbbellStandConfig','World2GameplayConfig','TreadmillConfig','SpeedConfig','LevelRequirements','RebirthConfig','TrainingConfig'],
 'ReplicatedStorage.Modules':['InventoryCounts','StrengthCalculation','LevelProgression'],
 'ServerScriptService.Services':['World1DumbbellVisuals','DumbbellService','TrainingLobbyAreaService','TrainingManager','StrengthManager','LobbySpawnService'],
 'ServerScriptService.Config':['MuscleScaleConfig'],
 'ServerScriptService.Systems.Controllers':['DumbbellDisplayController','MuscleCharacterService'],
 'StarterPlayer.StarterPlayerScripts.World':['LobbySpawnClient'],
 'ServerStorage.BodyPrototype_20261114':['PlayableBodyPrototype','PlayableShapeConfig','PlayableComparisonService','ComparisonClient'],
}
paths=[folder+'.'+name for folder,items in names.items() for name in items]+['ServerScriptService.Services.PlayerDataService']
if args.list_sources:print(json.dumps(paths));raise SystemExit
bank=json.loads((OUT/'SourceSnapshot.json').read_text(encoding='utf-8'))
sources={path:bank[path] for path in paths if not path.endswith('.PlayerDataService')}
if args.training_fixed:sources['ServerScriptService.Services.TrainingManager']=(ROOT/'src/ServerScriptService/Services/TrainingManager.luau').read_text(encoding='utf-8')
adapted=[]
for path,source in sources.items():
 if '126576845524886' in source:
  sources[path]=source.replace('game.PlaceId==126576845524886','game.PlaceId==0').replace('game.PlaceId~=126576845524886','game.PlaceId~=0')
  adapted.append(path)
memory=(ROOT/'tests/BodyDumbbellDiagnostics.memory.luau').read_text(encoding='utf-8')
original=bank['ServerScriptService.Services.PlayerDataService']
gain=original.split('function PlayerDataService.AddStrengthGain(player,gain)',1)[1].split('function PlayerDataService.ResetStrengthProgress',1)[0]
gain='function PlayerDataService.AddStrengthGain(player,gain)'+gain
sources['ServerScriptService.Services.PlayerDataService']=memory.replace('-- INSERT_PRODUCTION_ADD_STRENGTH_GAIN',gain)
sources['ServerScriptService.Services.FirstPlayAnalyticsService']='return {Strength=function()end,Placed=function()end}'
sources['ServerScriptService.Services.GamePassService']='return {AreEffectsEnabled=function()return false end,HasPremiumTreadmill=function()return false end,GetVIPStrengthMultiplier=function()return 1 end}'
sources['ServerScriptService.Services.ItemService']='return {GetBeltTreadmillBonus=function()return 0 end,GetProteinBonus=function()return 0 end}'
sources['ServerScriptService.Services.PotionService']='return {GetTrainingBonus=function()return 0 end,GetStrengthMultiplier=function()return 1 end}'
sources['ServerScriptService.Services.AuraService']='return {GetStrengthBonus=function()return 0 end}'
sources['ServerScriptService.Services.PetServer']='return {GetStrengthMultiplier=function()return 1 end}'
for side in ['server','client']:
 path='ServerScriptService.__BodyDumbbellFixture' if side=='server' else 'StarterPlayer.StarterPlayerScripts.__BodyDumbbellFixture'
 sources[path]=(ROOT/'tests'/f'BodyDumbbellDiagnostics.{side}.luau').read_text(encoding='utf-8')
forbidden=['DataStoreService','MarketplaceService','BadgeService','GetService("AnalyticsService")','game.AnalyticsService','MemoryStoreService','GetDataStore','GetOrderedDataStore','HttpService:Post','HttpService:Request','TeleportService']
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
prop(nodes[('Players',)],'CharacterAutoLoads','boolean',False)
prop(nodes[('Workspace',)],'StreamingEnabled','boolean',True)
prop(nodes[('Workspace',)],'StreamingMinRadius','number',64)
prop(nodes[('Workspace',)],'StreamingTargetRadius','number',1024)
for remote in ['StrengthGain','LobbySpawnReady']:node(['ReplicatedStorage','Remotes',remote],'RemoteEvent')
for path,source in sources.items():
 for token in forbidden:assert token not in source,(path,token)
 kind='LocalScript' if path.startswith('StarterPlayer') or path.endswith('.ComparisonClient') else 'Script' if '.Controllers.' in path or path.endswith('__BodyDumbbellFixture') else 'ModuleScript'
 prop(node(path.split('.'),kind),'Source','ProtectedString',source)
# W1 registered visual geometry, unchanged from the prior task; restore its
# native mesh metadata and PBR materials from approved registered Models below.
old=json.loads((ROOT/'tmp/Dumbbell3D/geometry.json').read_text(encoding='utf-8'))
for row in old:
 if row['Path'] not in ['ServerStorage.World1DumbbellModels','ServerStorage.Templates.DumbbellDisplayTemplate']:continue
 model_xml(node(row['Path'].split('.')[:-1]),row['Tree'])
geometry=json.loads((OUT/'geometry.json').read_text(encoding='utf-8'))
audit=json.loads((OUT/'NativeDonorAudit.json').read_text(encoding='utf-8'))
if args.variant=='serialized_mesh':
 def preserve_size(row):
  if row['Class']=='MeshPart':
   name=row['Properties']['Name']['V']
   row['Properties']['InitialSize']={'T':'Vector3','V':audit[name]['MeshSize']}
  for child in row['Children']:preserve_size(child)
 for row in geometry['Roots']:
  if row['Path'].endswith('PlayableSourceBody'):preserve_size(row['Tree'])
for row in geometry['Roots']:model_xml(node(row['Path'].split('.')[:-1]),row['Tree'])
def part(path,size,cf,kind='Part',collide=True):
 p=node(path.split('.'),kind);prop(p,'Size','Vector3',size);prop(p,'Anchored','boolean',True);prop(p,'CanCollide','boolean',collide)
 prop(p,'CFrame','CFrame',cf);return p
ident=[1,0,0,0,1,0,0,0,1];back=[-1,0,0,0,1,0,0,0,-1]
# Exact latest structural floor and lobby-marker geometry, audited in the copy.
part('Workspace.GeneratedMap.TrainingArea.Floor',[237,8,149],[274.5,0,10.5]+ident)
spawn=part('Workspace.GeneratedMap.TrainingArea.SpawnLocation',[20.05817222595215,1.0858172178268433,20.05817222595215],[287.861083984375,3.8983314037323,12.999991416931153]+back,'SpawnLocation',False)
prop(spawn,'Neutral','boolean',True);prop(spawn,'Transparency','number',1)
part('Workspace.World2Map.TrainingArea.Floor',[237,2,169],[14.620012283325196,1,1935.47998046875]+ident)
part('Workspace.World2Map.TrainingArea.World2LobbySpawn',[13,1,13],[27.981096267700197,2.5,1947.97998046875]+back,collide=False)
fixture=OUT/'BodyDiagnostics.rbxlx';ET.ElementTree(game).write(fixture,encoding='utf-8',xml_declaration=True)
native={r['Name']:r for r in geometry['NativeMeshes']}
for name,row in native.items():row['Mass']=audit[name]['Mass']
runner='''assert(game.PlaceId==0,"ISOLATION FAILED: cloud place")
assert(not game.RunService:IsRunning(),"ISOLATION FAILED: already playing")
assert(game.ServerScriptService:FindFirstChild("__BodyDumbbellFixture"),"Missing fixture marker")
local expected=game.HttpService:JSONDecode([==[EXPECTED_PATHS]==])
local actual=0
for _,s in game:GetDescendants()do if s:IsA("LuaSourceContainer")then
 assert(expected[s:GetFullName()],"ISOLATION FAILED: extra source "..s:GetFullName())
 assert(loadstring(s.Source),s:GetFullName())
 for _,word in game.HttpService:JSONDecode([==[FORBIDDEN]==])do assert(not s.Source:find(word,1,true),"ISOLATION FAILED: "..word)end
 actual+=1
end end
assert(actual==EXPECTED_COUNT,"ISOLATION FAILED: source count")
for _,model in game.ServerStorage.World1DumbbellModels:GetChildren()do
 local id=model:GetAttribute("SourceModelAssetId")
 if id then
  local package=game.InsertService:LoadAsset(id)
  local source=assert(package:FindFirstChildWhichIsA("MeshPart",true))
  local old=assert(model:FindFirstChildWhichIsA("MeshPart",true))
  local mesh=source:Clone();package:Destroy()
  for _,x in mesh:GetDescendants()do if not x:IsA("SurfaceAppearance")then x:Destroy()end end
  mesh.Name=old.Name;mesh.Size=old.Size;mesh.CFrame=old.CFrame;mesh.PivotOffset=old.PivotOffset
  mesh.Anchored=true;mesh.CanCollide=false;mesh.CanTouch=false;mesh.CanQuery=false;mesh.Massless=true
  mesh.Parent=old.Parent;old:Destroy()
 end
end
-- The accepted fixture serializes public MeshSize as XML InitialSize and checks
-- all 15 masses against Studio. Regeneration variants are diagnostic controls:
-- CreateMeshPartAsync/ApplyMesh changed mass despite identical IDs and Box mode.
local native=game.HttpService:JSONDecode([==[NATIVE]==])
local restoreDonor=VARIANT~="legacy_mesh" and VARIANT~="serialized_mesh"
for _,p in game.ServerStorage.BodyPrototype_20261114.PlayableSourceBody:GetDescendants()do if p:IsA("MeshPart")then
 local expected=assert(native[p.Name]);local size,cf,texture=p.Size,p.CFrame,p.TextureID
 if restoreDonor then
 local restored=game.AssetService:CreateMeshPartAsync(Content.fromUri(p.MeshId),{CollisionFidelity=Enum.CollisionFidelity[expected.Collision],RenderFidelity=Enum.RenderFidelity[expected.Render]})
 p:ApplyMesh(restored);restored:Destroy();p.Size=size;p.CFrame=cf;p.TextureID=texture
 assert((p.MeshSize-Vector3.new(unpack(expected.MeshSize))).Magnitude<.0001,"Native donor mismatch "..p.Name)
 end
 if VARIANT=="serialized_mesh" then
  assert((p.MeshSize-Vector3.new(unpack(expected.MeshSize))).Magnitude<.0001,"Serialized MeshSize mismatch "..p.Name)
  assert(math.abs(p:GetMass()-expected.Mass)<.0001,"Serialized mass mismatch "..p.Name)
 end
end end
game.ServerStorage.BodyPrototype_20261114:SetAttribute("Enabled",true)
game.ReplicatedStorage:SetAttribute("BodyDumbbellFixture",true)
game.ReplicatedStorage:SetAttribute("FixtureVariant",VARIANT)
game.ReplicatedStorage:SetAttribute("FixtureMuscleOnly",MUSCLE_ONLY)
game.ReplicatedStorage:SetAttribute("FixtureRegression",REGRESSION)
game.ReplicatedStorage:SetAttribute("FixtureLifecycleOnly",LIFECYCLE_ONLY)
game.ReplicatedStorage:SetAttribute("FixtureTrainingOnly",TRAINING_ONLY)
print("BODY_DIAGNOSTICS_ISOLATION_CONFIRMED",game.PlaceId,actual)
local ok,result=pcall(function()return game.StudioTestService:ExecuteMultiplayerTestAsync(CLIENTS,{Name="BodyDumbbellDiagnostics"})end)
local encoded=game.HttpService:JSONEncode({Success=ok,Result=result})
-- Studio truncates individual log messages at 100k; retain all raw samples.
print("BODY_DIAGNOSTICS_RESULT_BYTES",#encoded)
for first=1,#encoded,18000 do print("BODY_DIAGNOSTICS_CHUNK "..math.floor((first-1)/18000+1).." "..encoded:sub(first,first+17999))end
print("BODY_DIAGNOSTICS_EDIT_RETURNED",game.StudioTestService.EditModeActive)
'''
for k,v in {'EXPECTED_PATHS':json.dumps({p:True for p in sources}),'FORBIDDEN':json.dumps(forbidden),'EXPECTED_COUNT':str(len(sources)),'NATIVE':json.dumps(native),'CLIENTS':str(args.clients),'VARIANT':json.dumps(args.variant),'MUSCLE_ONLY':str(args.muscle_only).lower(),'REGRESSION':str(args.regression).lower(),'LIFECYCLE_ONLY':str(args.lifecycle_only).lower(),'TRAINING_ONLY':str(args.training_only).lower()}.items():runner=runner.replace(k,v)
(OUT/'RunBodyDiagnostics.luau').write_text(runner,encoding='utf-8')
(OUT/'BodyFixtureManifest.json').write_text(json.dumps({'PlaceId':0,'Variant':args.variant,'Clients':args.clients,'TrainingFixed':args.training_fixed,'Regression':args.regression,'LifecycleOnly':args.lifecycle_only,'Sources':{p:hashlib.sha256(s.encode()).hexdigest()for p,s in sources.items()},'GateAdaptedOnlyInFixture':adapted,'PrePlayMeshSizeAndMassAssertions':args.variant=='serialized_mesh','DonorRegenerated':args.variant in ['native','legacy_transition'],'AddStrengthGainSHA256':hashlib.sha256(gain.encode()).hexdigest(),'ForbiddenCalls':forbidden},indent=2),encoding='utf-8')
print(json.dumps({'Sources':len(sources),'Bytes':fixture.stat().st_size,'Fixture':str(fixture)}))
