"""Source-only patch of the latest user-saved canonical place; no backup/copy."""
import hashlib,json,os,sys,subprocess
from pathlib import Path
from rbxl_rows import Editor,string,s
from rbxl_referents import Document,canonicalize
ROOT=Path(__file__).resolve().parents[1]
PLACE=Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
FILES={
 'ReplicatedStorage.Modules.HUDLayout':'src/ReplicatedStorage/Modules/HUDLayout.luau',
 'ReplicatedStorage.Modules.ResponsivePanels':'src/ReplicatedStorage/Modules/ResponsivePanels.luau',
 'StarterGui.StrengthGui.EssentialStudShopClient':'src/StarterGui/StrengthGui/EssentialStudShopClient.client.luau',
 'StarterPlayer.StarterPlayerScripts.UI.TreadmillUIClient':'src/StarterPlayer/StarterPlayerScripts/UI/TreadmillUIClient.client.luau'}
EXPECTED='a3e0b8dab6eac7271e8fbe7497fc78f69dd9d3e551f85491f8f2e2c0d07a01fb'
raw=PLACE.read_bytes();assert hashlib.sha256(raw).hexdigest()==EXPECTED,'Canonical file changed'
assert not Path(str(PLACE)+'.lock').exists(),'Studio lock exists'
baseline={'StarterPlayer.StarterPlayerScripts.UI.TreadmillUIClient': '5b209f004c6d37c6a3cf30e7cf89e420265ffad058d2c3968bef22b8cc9bbcfe', 'ReplicatedStorage.Modules.HUDLayout': '90e96f4b737255319d3031bebadf2c82d19e5a3b8b919dab68aefe80b6a81903', 'StarterGui.StrengthGui.EssentialStudShopClient': 'ed006c164a8bc20c539291fde2b44f37d396a4a7c7872d4f23b26cfeaa2e783b', 'ReplicatedStorage.Modules.ResponsivePanels': '69610db08105037d4ac68d661a3559ba6802c6e3d2737416ca75d162cf3951f8'}
e=Editor(raw);allowed=set();changes=[]
for full,path in FILES.items():
 ref=e.find(full);old=string(e.get(ref,'Source'),0)[0].decode()
 assert hashlib.sha256(old.replace('\r\n','\n').encode()).hexdigest()==baseline[full],('Source changed',full)
 source=(ROOT/path).read_text(encoding='utf-8')
 assert '__UIFixStats'not in source and '__Perf'not in source
 subprocess.run([str(Path.home()/'AppData/Local/Temp/luau-compile.exe'),str(ROOT/path)],check=True,stdout=subprocess.DEVNULL)
 e.set(ref,'Source',s(source));allowed.add((e.class_of[ref],'Source'));changes.append(full+'.Source')
ref=e.find('StarterPlayer.StarterPlayerScripts.UI.TreadmillUIClient')
execution='Enabled'if(e.class_of[ref],'Enabled')in e.columns else 'Disabled'
e.set(ref,execution,b'\1'if execution=='Enabled'else b'\0');allowed.add((e.class_of[ref],execution))
result,repair=e.build();after=Editor(result)
assert e.parents==after.parents and e.classes==after.classes and e.doc.unique_ids==after.doc.unique_ids
for key in e.columns:
 if key in allowed:assert e.col(*key)[3]==after.col(*key)[3],key
 else:assert e.doc.chunks[e.columns[key][0]][1]==after.doc.chunks[after.columns[key][0]][1],key
for (kind,a,_,_), (kind2,b,_,_)in zip(e.doc.chunks,after.doc.chunks):
 assert kind==kind2 and (a==b or kind==b'PROP')
assert canonicalize(result)[0]==result
report={'path':str(PLACE),'inputSha256':EXPECTED,'outputSha256':hashlib.sha256(result).hexdigest(),'changes':changes+['StarterPlayer.StarterPlayerScripts.UI.TreadmillUIClient.Enabled'],'allOtherPropertiesAndSharedStringsUnchanged':True,'parentsAndUniqueIdsUnchanged':True,'syntax':'passed','reDecode':'passed','summary':after.doc.summary(),'written':False}
if '--write'in sys.argv:
 assert PLACE.read_bytes()==raw
 with PLACE.open('r+b')as f:f.write(result);f.truncate();f.flush();os.fsync(f.fileno())
 assert PLACE.read_bytes()==result;Document(PLACE.read_bytes()).assert_studio_bounds();report['written']=True
(ROOT/'reports/LobbyUIFix_20261020/FileValidation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report))
