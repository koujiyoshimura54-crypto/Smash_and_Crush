"""Separate UI Play fixture; allowlisted view/config Sources and authored GUI donors.
No production server controller, remotes, persistence, purchase or analytics implementation.
"""
from pathlib import Path
import json,hashlib,sys,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'tmp/World2Dumbbell3D'
sys.path.insert(0,str(ROOT/'tools'))
from dumbbell_model_xml import property_xml,attributes
bank=json.loads((OUT/'UIExportFinal.json').read_text(encoding='utf-8'))
sources=bank['Sources']
sources['ReplicatedStorage.Modules.ForgeClient']='''
local changed=Instance.new('BindableEvent');local completed=Instance.new('BindableEvent')
local M={State={Ores={ORE_032=1,ORE_028=1},World2Unlocked=true,Pending=false},Changed=changed.Event,Completed=completed.Event}
function M.IsPending()return false end
function M.Refresh()changed:Fire(M.State)end
function M.Request()error('Transactions forbidden in UI fixture')end
function M.Complete()completed:Fire({Action='MergeOre'},{Success=true,State={Journal={ResultId='W2_NORMAL_08'}}})end
return M
'''
sources['ReplicatedStorage.Modules.FirstPlayAnalyticsClient']='return {BindOre=function()end}'
sources['ReplicatedStorage.Modules.UIFeedback']='return {Play=function()end,CanSound=function()return false end,Hover=function()end,Leave=function()end}'
sources['StarterPlayer.StarterPlayerScripts.__World2UIFixture']=(ROOT/'tests/World2DumbbellUI.client.luau').read_text(encoding='utf-8')
sources['ServerScriptService.__World2UIFixture']='''
assert(game.PlaceId==0 and game.ReplicatedStorage:GetAttribute('World2UIFixture'))
game.Players.CharacterAutoLoads=false
local e=Instance.new('RemoteEvent');e.Name='__World2UIResult';e.Parent=game.ReplicatedStorage
local f=Instance.new('RemoteFunction');f.Name='__World2UIFinish';f.Parent=game.ReplicatedStorage
local result
e.OnServerEvent:Connect(function(p,r)
 result=r;if not r.Passed then game.StudioTestService:EndTest(r)else print('UI_FIXTURE_READY',#r.Checks);task.delay(240,function()if result then game.StudioTestService:EndTest(result)end end)end
end)
f.OnServerInvoke=function()assert(result);local r=result;result=nil;task.delay(.2,function()game.StudioTestService:EndTest(r)end);return true end
task.delay(300,function()if not result then game.StudioTestService:EndTest({Passed=false,Error='UI fixture timeout'})end end)
'''
forbidden=['DataStoreService','MarketplaceService','MemoryStoreService','AnalyticsService','TeleportService','HttpService:Post','HttpService:Request','GetDataStore','SavePlace','Publish']
for path,s in sources.items():
 for token in forbidden:assert token not in s,(path,token)
game=ET.Element('roblox',version='4');nodes={():game}
def node(path,kind=None):
 path=tuple(path)
 if path in nodes:return nodes[path]
 if kind is None:kind=path[0]if len(path)==1 else 'ScreenGui'if len(path)==2 and path[0]=='StarterGui'else 'Frame'if path[0]=='StarterGui'else 'Folder'
 el=ET.SubElement(node(path[:-1]),'Item',{'class':kind,'referent':'F'+str(len(nodes))});ET.SubElement(ET.SubElement(el,'Properties'),'string',name='Name').text=path[-1];nodes[path]=el;return el
def prop(el,name,t,v):property_xml(el.find('Properties'),name,{'T':t,'V':v})
for service in ['Workspace','ReplicatedStorage','ServerScriptService','StarterPlayer','StarterGui','Players']:node([service],service)
node(['StarterPlayer','StarterPlayerScripts'],'StarterPlayerScripts');prop(node(['Players']),'CharacterAutoLoads','boolean',False)
for path,s in sources.items():
 kind='LocalScript'if path.startswith('StarterPlayer')else 'Script'if path.startswith('ServerScriptService')else 'ModuleScript'
 prop(node(path.split('.'),kind),'Source','ProtectedString',s)
def gui(parent,row):
 assert row['Class']not in ['Script','LocalScript','ModuleScript','PackageLink']
 e=ET.SubElement(parent,'Item',{'class':row['Class'],'referent':row['Id']});p=ET.SubElement(e,'Properties')
 for name,v in row['Properties'].items():
  if v['T']in ['ColorSequence','NumberSequence']:ET.SubElement(p,v['T'],name=name).text=' '.join(str(k)for point in v['V']for k in point)
  else:property_xml(p,name,v)
 if row['Attributes']:ET.SubElement(p,'BinaryString',name='AttributesSerialize').text=attributes(row['Attributes'])
 for c in row['Children']:gui(e,c)
 return e
for row in bank['Geometry']:gui(node(row['Path'].split('.')[:-1]),row['Tree'])
for name in ['StrengthGui','ScreenGui']:
 el=node(['StarterGui',name]);prop(el,'ResetOnSpawn','boolean',False);prop(el,'IgnoreGuiInset','boolean',True)
fixture=OUT/'World2UIFixture.rbxlx';ET.ElementTree(game).write(fixture,encoding='utf-8',xml_declaration=True)
runner='''
assert(game.PlaceId==0 and not game.RunService:IsRunning(),'Wrong place')
local allow=game.HttpService:JSONDecode([==[ALLOW]==]);local forbidden=game.HttpService:JSONDecode([==[FORBIDDEN]==]);local n=0
for _,x in game:GetDescendants()do if x:IsA('LuaSourceContainer')then
 assert(allow[x:GetFullName()],'Unexpected Source '..x:GetFullName());assert(loadstring(x.Source));for _,token in forbidden do assert(not string.find(x.Source,token,1,true),'Forbidden '..token)end;n+=1
end end
assert(n==COUNT,'Unexpected Source count');assert(#game.Players:GetPlayers()==0)
game.ReplicatedStorage:SetAttribute('World2UIFixture',true)
print('UI_ISOLATION_CONFIRMED',n)
local ok,r=pcall(function()return game.StudioTestService:ExecuteMultiplayerTestAsync(1,{Name='World2DumbbellUI'})end)
local complete=ok and typeof(r)=='table'and typeof(r.Passed)=='boolean'
print('WORLD2_UI_RESULT '..game.HttpService:JSONEncode({Success=complete,Result=r,Error=not complete and 'No completed UI result; not verified' or nil}))
'''.replace('ALLOW',json.dumps({p:True for p in sources})).replace('FORBIDDEN',json.dumps(forbidden)).replace('COUNT',str(len(sources)))
(OUT/'RunWorld2UIFixture.luau').write_text(runner,encoding='utf-8')
(OUT/'UIFixtureManifest.json').write_text(json.dumps({'PlaceId':0,'Sources':{k:hashlib.sha256(v.encode()).hexdigest()for k,v in sources.items()},'Adapters':['ForgeClient: Bindable UI state/completion, requests error','FirstPlayAnalyticsClient: no send','UIFeedback: no sound'],'ForbiddenTokens':forbidden,'Image':'112266643972428'},indent=2),encoding='utf-8')
print(json.dumps({'Sources':len(sources),'Fixture':str(fixture),'Bytes':fixture.stat().st_size}))
