"""Guarded same-file Source-only write; no extra place or backup is created."""
import hashlib,json,os,subprocess
from pathlib import Path
from rbxl_rows import Editor,s,string
from rbxl_referents import Document,canonicalize
from tutorial_arrow_patch import build,PLACE,FULL,ROOT

raw=PLACE.read_bytes()
assert hashlib.sha256(raw).hexdigest()=='08c9434ec97c3f705c7454744d5355eba6589bb118c88b24f9f8d1c525ee7766'
assert not Path(str(PLACE)+'.lock').exists(),'Studio still owns file'
original,source=build(raw)
mirror=ROOT/'src/StarterPlayer/StarterPlayerScripts/Tutorial/TutorialGuideClient.client.luau'
assert mirror.read_text(encoding='utf-8')==source
subprocess.run([str(Path.home()/'AppData/Local/Temp/luau-compile.exe'),str(mirror)],check=True,stdout=subprocess.DEVNULL)
old=Editor(raw);ref=old.find(FULL);old.set(ref,'Source',s(source));result,repair=old.build()
new=Editor(result)
assert old.parents==new.parents and old.classes==new.classes
assert old.doc.unique_ids==new.doc.unique_ids
changed=[]
for (kind,a,_,_), (kind2,b,_,_) in zip(old.doc.chunks,new.doc.chunks):
 assert kind==kind2
 if a!=b: changed.append(kind.decode())
 assert a==b or kind in (b'PROP',b'PRNT')
for key in old.columns:
 if key==(old.class_of[ref],'Source'):
  before=old.col(*key)[3];after=new.col(*key)[3]
  assert before==after # old editor contains exactly the intended Source change
 else:
  ci=old.columns[key][0];assert old.doc.chunks[ci][1]==new.doc.chunks[ci][1],key
assert canonicalize(result)[0]==result
assert string(new.get(ref,'Source'),0)[0].decode()==source
assert PLACE.read_bytes()==raw
with PLACE.open('r+b')as f:f.write(result);f.truncate();f.flush();os.fsync(f.fileno())
assert PLACE.read_bytes()==result
Document(PLACE.read_bytes()).assert_studio_bounds()
report={'path':str(PLACE),'beforeSha256':hashlib.sha256(raw).hexdigest(),'afterSha256':hashlib.sha256(result).hexdigest(),'sourcePath':FULL,'sourceSha256':hashlib.sha256(source.encode()).hexdigest(),'instances':len(new.parents),'changedChunks':changed,'parentMappingUnchanged':True,'uniqueIdsUnchanged':True,'otherPropertyChunksUnchanged':True,'reDecode':'passed','canonicalizationIdempotent':True,'summary':new.doc.summary(),'repair':repair}
(ROOT/'reports/TutorialArrows_UIAudit_20261020/FileValidation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report))
