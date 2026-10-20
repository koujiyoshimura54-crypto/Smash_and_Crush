"""Patch four live Sources only; preserve all objects and other property rows."""
import functools,hashlib,json,os,subprocess,sys
from pathlib import Path
from rbxl_rows import Editor,string,s
from rbxl_referents import Document,canonicalize

ROOT=Path(__file__).resolve().parents[1]
PLACE=Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED='f41cbd017387883102e58ffde93519f6a371323dedfce1aed9aa8057de2872c0'
FILES={
 'ServerScriptService.Services.PlayerDataService':'src/ServerScriptService/Services/PlayerDataService.luau',
 'ServerScriptService.Services.EggServer':'src/ServerScriptService/Services/EggServer.luau',
 'StarterPlayer.StarterPlayerScripts.Services.PetClient':'src/StarterPlayer/StarterPlayerScripts/Services/PetClient.luau',
 'StarterGui.StrengthUI.MergePanel_New.MergePanelClient_New':'src/StarterGui/StrengthUI/MergePanel_New/MergePanelClient_New.client.luau',
}
raw=PLACE.read_bytes()
assert hashlib.sha256(raw).hexdigest()==EXPECTED,'Canonical file changed; refusing stale write'
assert not Path(str(PLACE)+'.lock').exists(),'Studio lock exists'
baseline={'ServerScriptService.Services.PlayerDataService': '58a6178df609c2608355fa4212a7ebc8131c179e8f0659c5dea149082f43a581', 'ServerScriptService.Services.EggServer': 'c8c845b0793f30f37c0d2db926a36c62bb01b605faaa4e5499a5bf9442164530', 'StarterPlayer.StarterPlayerScripts.Services.PetClient': '103e37c08971a435be7d95829dbbf153ea1db207783c74b7a4e794ca63c7a439', 'StarterGui.StrengthUI.MergePanel_New.MergePanelClient_New': 'f2da3a2eabaa4a56bc79eaf84163ef5dc40e359e9c6cc9340e4e632f65f3d3b0'}
e=Editor(raw);e.path=functools.lru_cache(None)(e.path)
paths={e.path(r):r for r in e.parents}
changed_refs=set()
for full,path in FILES.items():
 ref=paths[full]
 current=string(e.get(ref,'Source'),0)[0].decode()
 assert hashlib.sha256(current.encode()).hexdigest()==baseline[full],('Live Source changed',full)
 source=(ROOT/path).read_text(encoding='utf-8')
 subprocess.run([str(Path.home()/'AppData/Local/Temp/luau-compile.exe'),str(ROOT/path)],check=True,stdout=subprocess.DEVNULL)
 e.set(ref,'Source',s(source));changed_refs.add(ref)
result,repair=e.build();after=Editor(result)
assert e.parents==after.parents and e.classes==after.classes
assert e.doc.unique_ids==after.doc.unique_ids
for key in e.columns:
 before_chunk=e.doc.chunks[e.columns[key][0]][1]
 after_chunk=after.doc.chunks[after.columns[key][0]][1]
 if key[1]=='Source':
  before_rows=Editor.col(e,*key)[3]
  after_rows=after.col(*key)[3]
  assert before_rows==after_rows,key
 else:assert before_chunk==after_chunk,key
for (kind,a,_,_),(kind2,b,_,_) in zip(e.doc.chunks,after.doc.chunks):
 assert kind==kind2 and(a==b or kind==b'PROP')
assert canonicalize(result)[0]==result
report={'path':str(PLACE),'inputSha256':EXPECTED,'outputSha256':hashlib.sha256(result).hexdigest(),
 'changedSources':list(FILES),'allOtherPropertiesUnchanged':True,
 'instancesParentsUniqueIdsSharedStringsUnchanged':True,'syntax':'passed','reDecode':'passed',
 'summary':after.doc.summary(),'written':False,'play':'Not run at user request',
 'studioReopen':'Not run; user handles runtime verification'}
if '--write' in sys.argv:
 assert PLACE.read_bytes()==raw
 with PLACE.open('r+b')as f:f.write(result);f.truncate();f.flush();os.fsync(f.fileno())
 assert PLACE.read_bytes()==result
 Document(PLACE.read_bytes()).assert_studio_bounds()
 report['written']=True
dest=ROOT/'reports/EggMergeRecovery_20261020';dest.mkdir(exist_ok=True)
(dest/'FileValidation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
