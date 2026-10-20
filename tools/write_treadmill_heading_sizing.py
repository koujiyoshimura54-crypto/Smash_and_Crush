"""Write only measured treadmill title properties and their live updater Source."""
import functools,hashlib,json,os,subprocess,sys
from pathlib import Path
from rbxl_rows import Editor,string,s,udim2,vector,f,i,decode
from rbxl_referents import Document,canonicalize
ROOT=Path(__file__).resolve().parents[1]
PLACE=Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED='5b1ea2f95bc74c033bec33c2e9576ee93e1996ee0ef2878fcb5a7d0820e90942'
SCRIPT='StarterPlayer.StarterPlayerScripts.UI.TreadmillUIClient'
SOURCE=ROOT/'src/StarterPlayer/StarterPlayerScripts/UI/TreadmillUIClient.client.luau'
dest=ROOT/'reports/TreadmillHeadingSizing_20261020'
measurements=json.loads((dest/'Measurements.json').read_text())['captures']
raw=PLACE.read_bytes();assert hashlib.sha256(raw).hexdigest()==EXPECTED,'Canonical changed'
e=Editor(raw);e.path=functools.lru_cache(None)(e.path);paths={e.path(r):r for r in e.parents}
source=SOURCE.read_text(encoding='utf-8')
subprocess.run([str(Path.home()/'AppData/Local/Temp/luau-compile.exe'),str(SOURCE)],check=True,stdout=subprocess.DEVNULL)
allowed={};changes=[]
def put(path,prop,value):
 ref=paths[path];key=(e.class_of[ref],prop)
 if e.get(ref,prop)==value:return
 allowed.setdefault(key,{})[ref]=value;e.set(ref,prop,value);changes.append(path+'.'+prop)
put(SCRIPT,'Source',s(source))
for world in (1,2):
 row=next(m for m in measurements if m['Name']==f'W{world}_en_far')
 gui=row['Path'];label=gui+'.Name';icon=gui+'.Icon'
 put(gui,'Size',udim2(row['GuiSize'][0],0,7.5,0))
 put(gui,'StudsOffsetWorldSpace',vector(0,4,0));put(gui,'Adornee',paths[gui.rsplit('.',1)[0]])
 put(label,'Size',udim2(row['LabelSize'][0],0,.9,0))
 put(label,'TextWrapped',bytes([1]));put(label,'TextScaled',bytes([1]))
 put(icon,'Size',udim2(row['IconSize'][0],0,.9,0))
 put(gui+'.UIListLayout','Padding',f(row['Padding'])+i(0))
 put(gui+'.UIListLayout','HorizontalAlignment',(1).to_bytes(4,'big'))
 put(gui+'.UIListLayout','VerticalAlignment',(1).to_bytes(4,'big'))
result,repair=e.build();after=Editor(result)
assert e.parents==after.parents and e.classes==after.classes and e.doc.unique_ids==after.doc.unique_ids
for key,col in e.columns.items():
 old=e.doc.chunks[col[0]][1];new=after.doc.chunks[after.columns[key][0]][1]
 if key not in allowed:assert old==new,key
 else:
  original=dict(zip(e.doc.classes[key[0]][1],decode(old[col[2]:],col[1],len(e.doc.classes[key[0]][1]))))
  original.update(allowed[key]);assert original==after.col(*key)[3],key
assert canonicalize(result)[0]==result
for(kind,a,_,_),(kind2,b,_,_)in zip(e.doc.chunks,after.doc.chunks):
 assert kind==kind2 and(a==b or kind==b'PROP')
assert PLACE.read_bytes()==raw
with PLACE.open('r+b')as out:out.write(result);out.truncate();out.flush();os.fsync(out.fileno())
assert PLACE.read_bytes()==result
Document(PLACE.read_bytes()).assert_studio_bounds()
report={'inputSha256':EXPECTED,'outputSha256':hashlib.sha256(result).hexdigest(),'changes':changes,
 'path':str(PLACE),'syntax':'passed','reDecode':'passed','allOtherRowsUnchanged':True,
 'instancesParentsSharedStringsUniqueIdsUnchanged':True,'summary':after.doc.summary(),'written':True}
(dest/'FileValidation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report))
