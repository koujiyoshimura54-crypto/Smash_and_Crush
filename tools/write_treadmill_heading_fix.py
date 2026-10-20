"""Scoped title-row property and Source patch; no extra place files."""
import functools,hashlib,json,os,subprocess,sys
from pathlib import Path
from rbxl_rows import Editor,string,s,udim2
from rbxl_referents import Document,canonicalize
ROOT=Path(__file__).resolve().parents[1]
PLACE=Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED='f2f93c1574d60da1f5963399805b3b0df8e963c6503ab136f9fa96faf1fd5da7'
SCRIPT='StarterPlayer.StarterPlayerScripts.UI.TreadmillUIClient'
SOURCE=ROOT/'src/StarterPlayer/StarterPlayerScripts/UI/TreadmillUIClient.client.luau'
HEADINGS=['Workspace.Treadmills.Billboard.BillboardGui',
 'Workspace.World2Map.TrainingArea.TreadmillDisplays.Billboard.BillboardGui']
raw=PLACE.read_bytes();assert hashlib.sha256(raw).hexdigest()==EXPECTED,'Canonical file changed'
assert not Path(str(PLACE)+'.lock').exists(),'Studio lock exists'
e=Editor(raw);e.path=functools.lru_cache(None)(e.path)
paths={e.path(r):r for r in e.parents}
before_source=string(e.get(paths[SCRIPT],'Source'),0)[0].decode()
assert 'set(label,"TextWrapped",true)end' in before_source
source=SOURCE.read_text(encoding='utf-8')
assert source.count('rbxassetid://106106287008236')==1
subprocess.run([str(Path.home()/'AppData/Local/Temp/luau-compile.exe'),str(SOURCE)],check=True,stdout=subprocess.DEVNULL)
changes=[];allowed={}
def put(path,prop,value):
 ref=paths[path];key=(e.class_of[ref],prop)
 if e.get(ref,prop)==value:return
 allowed.setdefault(key,{})[ref]=value
 e.set(ref,prop,value);changes.append(path+'.'+prop)
put(SCRIPT,'Source',s(source))
for gui in HEADINGS:
 label=gui+'.Name';icon=gui+'.Icon'
 put(label,'AutomaticSize',bytes(4));put(label,'Size',udim2(.76,0,.9,0))
 put(label,'TextScaled',bytes([1]));put(label,'TextWrapped',bytes([0]));put(label,'TextTruncate',bytes(4))
 put(icon,'Image',s('rbxassetid://106106287008236'))
 put(icon,'Size',udim2(.17,0,.9,0));put(icon,'ScaleType',(3).to_bytes(4,'big'))
result,repair=e.build();after=Editor(result)
assert e.parents==after.parents and e.classes==after.classes and e.doc.unique_ids==after.doc.unique_ids
for key in e.columns:
 old=e.doc.chunks[e.columns[key][0]][1];new=after.doc.chunks[after.columns[key][0]][1]
 if key not in allowed:assert old==new,key
 else:assert e.col(*key)[3]==after.col(*key)[3],key
assert canonicalize(result)[0]==result
for (kind,a,_,_),(kind2,b,_,_)in zip(e.doc.chunks,after.doc.chunks):
 assert kind==kind2 and(a==b or kind==b'PROP')
report={'path':str(PLACE),'inputSha256':EXPECTED,'outputSha256':hashlib.sha256(result).hexdigest(),
 'changes':changes,'otherObjectsAndPropertiesUnchanged':True,'syntax':'passed','reDecode':'passed',
 'referenceSummary':after.doc.summary(),'written':False,
 'nativeDisplayAndImageIsLoaded':'Unverified: no connected or running Studio; no launch for this short fix'}
if '--write'in sys.argv:
 assert PLACE.read_bytes()==raw
 with PLACE.open('r+b')as f:f.write(result);f.truncate();f.flush();os.fsync(f.fileno())
 assert PLACE.read_bytes()==result
 Document(PLACE.read_bytes()).assert_studio_bounds();report['written']=True
dest=ROOT/'reports/TreadmillHeading_20261020';dest.mkdir(exist_ok=True)
(dest/'FileValidation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
