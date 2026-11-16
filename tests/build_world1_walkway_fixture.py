"""Build a NEW local physics fixture. Never reads/writes a real .rbxl or Studio.

Only allowlisted movement sources and 15 measured floor/wall Parts are packaged.
PlayerData/GamePass are minimal in-memory fixtures; production persistence code
is never present. The runner refuses to start Play if the isolation audit fails.
"""
from pathlib import Path
import json, re, xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'tmp/World1Walkway'
OUT.mkdir(exist_ok=True,parents=True)
FILES={
 'ReplicatedStorage.Config.World1WalkwayConfig':'src/ReplicatedStorage/Config/World1WalkwayConfig.luau',
 'ReplicatedStorage.Config.SpeedConfig':'src/ReplicatedStorage/Config/SpeedConfig.luau',
 'ReplicatedStorage.Modules.World1WalkwayGeometry':'src/ReplicatedStorage/Modules/World1WalkwayGeometry.luau',
 'ReplicatedStorage.Modules.World1WalkwayLocomotion':'src/ReplicatedStorage/Modules/World1WalkwayLocomotion.luau',
 'ReplicatedStorage.Modules.FloorGuideRenderer':'src/ReplicatedStorage/Modules/FloorGuideRenderer.luau',
 'ServerScriptService.Services.World1WalkwayService':'src/ServerScriptService/Services/World1WalkwayService.luau',
 'ServerScriptService.Services.SpeedService':'src/ServerScriptService/Services/SpeedService.luau',
 'ServerScriptService.Systems.Controllers.World1WalkwayController':'src/ServerScriptService/Systems/Controllers/World1WalkwayController.server.luau',
 'StarterPlayer.StarterPlayerScripts.World.World1WalkwayClient':'src/StarterPlayer/StarterPlayerScripts/World/World1WalkwayClient.client.luau',
 'StarterPlayer.StarterPlayerScripts.Tutorial.World1FloorRouteClient':'src/StarterPlayer/StarterPlayerScripts/Tutorial/World1FloorRouteClient.client.luau',
 'StarterPlayer.StarterPlayerScripts.World.TreadmillRunClient':'src/StarterPlayer/StarterPlayerScripts/World/TreadmillRunClient.client.luau',
 'ServerScriptService.__WalkwayFixture':'tests/World1WalkwayFixture.server.luau',
 'StarterPlayer.StarterPlayerScripts.__WalkwayFixture':'tests/World1WalkwayFixture.client.luau',
}
STUBS={
 'ServerScriptService.Services.PlayerDataService':'''local states={} local M={}
function M.Get(p)
 if not states[p] then states[p]={Loaded=true,Data={OwnedSpeeds={},SpeedUpgradeStage=0,EquippedSpeed="Normal"}} end
 return states[p]
end
function M.IsLoaded(p) return true end
return M''',
 'ServerScriptService.Services.GamePassService':'''return {
 HasPremiumSpeed=function()return false end,
 GetPremiumSpeedOwnershipStatus=function()return "Fixture" end,
}''',
}
sources={p:(ROOT/f).read_text(encoding='utf-8') for p,f in FILES.items()}
sources.update(STUBS)
for p,s in sources.items():
 assert not re.search(r'GetService\s*\(\s*["\x27](DataStoreService|MarketplaceService|BadgeService|AnalyticsService|MemoryStoreService)',s),p
 assert 'GetDataStore' not in s and 'GetOrderedDataStore' not in s,p
game=ET.Element('roblox',{'version':'4'})
nodes={():game}
def prop(item,tag,name,text=None):
 properties=item.find('Properties')
 if properties is None: properties=ET.SubElement(item,'Properties')
 p=ET.SubElement(properties,tag,{'name':name})
 if text is not None: p.text=str(text).lower() if isinstance(text,bool) else str(text)
 return p
def node(path,kind='Folder'):
 path=tuple(path)
 if path in nodes:return nodes[path]
 parent=node(path[:-1])
 n=ET.SubElement(parent,'Item',{'class':kind,'referent':'RBX'+str(len(nodes))})
 prop(n,'string','Name',path[-1]);nodes[path]=n;return n
for service in ['Workspace','ReplicatedStorage','ServerScriptService','StarterPlayer','Players']:
 node([service],service)
node(['StarterPlayer','StarterPlayerScripts'],'StarterPlayerScripts')
node(['StarterPlayer','StarterCharacterScripts'],'StarterCharacterScripts')
prop(nodes[('StarterPlayer',)],'token','CharacterRigType',1)
prop(nodes[('Workspace',)],'bool','StreamingEnabled',False)
for p,s in sources.items():
 f=FILES.get(p,'')
 kind='LocalScript' if f.endswith('.client.luau') else 'Script' if f.endswith('.server.luau') else 'ModuleScript'
 n=node(p.split('.'),kind);prop(n,'ProtectedString','Source',s)
for p in json.loads((ROOT/'tests/World1WalkwayGeometry.json').read_text(encoding='utf-8')):
 n=node(['Workspace']+p['Path'],p['Class'])
 for name,value in [('Anchored',True),('CanCollide',p['CanCollide']),('CanQuery',p['CanQuery'])]:prop(n,'bool',name,value)
 prop(n,'float','Transparency',p['Transparency'])
 v=prop(n,'Vector3','size')
 for a,x in zip('XYZ',p['Size']):ET.SubElement(v,a).text=str(x)
 cf=prop(n,'CoordinateFrame','CFrame')
 for a,x in zip(['X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22'],p['CFrame']):ET.SubElement(cf,a).text=str(x)
 color=prop(n,'Color3','Color')
 for a,x in zip('RGB',p['Color']):ET.SubElement(color,a).text=str(x)
 if p['Class']=='SpawnLocation':prop(n,'bool','Neutral',True);prop(n,'float','Duration',0)
fixture=OUT/'WalkwayPhysicsFixture.rbxlx'
ET.ElementTree(game).write(fixture,encoding='utf-8',xml_declaration=True)
expected={p:len(s.encode('utf-8')) for p,s in sources.items()}
runner='''assert(game.PlaceId==0,"Refuse any saved/cloud place")
assert(game.ReplicatedStorage:FindFirstChild("Config") and game.ServerScriptService:FindFirstChild("__WalkwayFixture"))
local count=0
for _,s in game:GetDescendants() do if s:IsA("LuaSourceContainer") then
 assert(loadstring(s.Source),s:GetFullName())
 for _,name in {"DataStoreService","MarketplaceService","BadgeService","AnalyticsService","MemoryStoreService","GetDataStore","GetOrderedDataStore"} do
  assert(not s.Source:find(name,1,true),"ISOLATION FAILED: "..s:GetFullName().." "..name)
 end
 count+=1
end end
assert(count==15,"Unexpected fixture source count: "..count)
game.ReplicatedStorage:SetAttribute("WalkwayFixture",true)
print("WALKWAY_ISOLATION_CONFIRMED",game.PlaceId,count)
local ok,result=pcall(function()return game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2,{Name="World1Walkway"})end)
print("WALKWAY_RESULT "..game:GetService("HttpService"):JSONEncode({Success=ok,Result=result}))
print("WALKWAY_EDIT_RETURNED",game:GetService("StudioTestService").EditModeActive)
'''
(OUT/'RunFixture.luau').write_text(runner,encoding='utf-8')
(OUT/'FixtureManifest.json').write_text(json.dumps({'Fixture':str(fixture),'Sources':expected,'StoreCode':False},indent=2),encoding='utf-8')
print(json.dumps({'fixture':str(fixture),'sources':len(sources),'bytes':fixture.stat().st_size}))
