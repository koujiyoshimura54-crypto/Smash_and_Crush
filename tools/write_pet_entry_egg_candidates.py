"""Persist only the reviewed Pets entry objects and Pet/Egg presentation Sources."""
import argparse, functools, hashlib, json, os, struct, subprocess
from pathlib import Path
from rbxl_rows import Editor, s, string, f, i, vector, udim2
from rbxl_referents import Document, canonicalize

ROOT=Path(__file__).resolve().parents[1]
PLACE=Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED='0d48d36f210b9562dcf61accf62da1ce9d637ccf0ac585da5dc9fd4aa8b525ed'
REPORT=ROOT/'reports/PetsEntryEggCandidates_20261021'
FILES={
    "ReplicatedStorage.Modules.HUDLayout": "src/ReplicatedStorage/Modules/HUDLayout.luau",
    "StarterPlayer.StarterPlayerScripts.Services.PetClient": "src/StarterPlayer/StarterPlayerScripts/Services/PetClient.luau",
    "StarterPlayer.StarterPlayerScripts.Services.EggClient": "src/StarterPlayer/StarterPlayerScripts/Services/EggClient.luau",
    "StarterGui.StrengthGui.LeftMenuClient": "src/StarterGui/StrengthGui/LeftMenuClient.client.luau"
}

def digest(raw): return hashlib.sha256(raw).hexdigest()

def attributes(values):
    rows=[]
    for name,value in values.items():
        assert value['type']=='Vector2'
        rows.append(s(name)+b'\x10'+struct.pack('<ff',*value['value']))
    return s(struct.pack('<I',len(rows))+b''.join(rows)) if rows else s(b'')

def apply(raw):
    assert digest(raw)==EXPECTED,'Unexpected local edit: inspect before writing'
    before,e=Editor(raw),Editor(raw)
    e.path=functools.lru_cache(None)(e.path)
    paths={e.path(ref):ref for ref in e.parents}
    allowed=set();moved=set();added=[]
    def setprop(ref,name,value):
        if e.get(ref,name)!=value:
            allowed.add((ref,name));e.set(ref,name,value)
    source_hashes={}
    for path,relative in FILES.items():
        ref=paths[path];old=string(e.get(ref,'Source'),0)[0]
        committed=subprocess.check_output(['git','show','ee26fa7:'+relative],cwd=ROOT).replace(b'\r\n',b'\n')
        assert old.replace(b'\r\n',b'\n')==committed,path
        new=(ROOT/relative).read_text(encoding='utf8').encode()
        subprocess.run([str(Path.home()/'AppData/Local/Temp/luau-compile.exe'),str(ROOT/relative)],
                       check=True,stdout=subprocess.DEVNULL)
        setprop(ref,'Source',s(new))
        source_hashes[path]={'before':digest(old),'after':digest(new)}
    steps=json.loads((REPORT/'ObjectChanges.json').read_text(encoding='utf8'))
    for step in steps:
        ref=paths[step['path']];op=step['op']
        if op=='move':
            parent=paths[step['parent']]
            target=step['parent']+'.'+step['name']
            assert target not in paths
            prefix=step['path']
            for path,r in list(paths.items()):
                if path==prefix or path.startswith(prefix+'.'):
                    del paths[path];paths[target+path[len(prefix):]]=r
            moved.add(ref);e.parents[ref]=parent;setprop(ref,'Name',s(step['name']))
        elif op=='clone':
            assert len(e.subtree(ref))==1,'Only the three leaf layout objects are added'
            new,_=e.clone(ref,paths[step['parent']],recursive=False)
            target=step['parent']+'.'+step['name'];assert target not in paths
            paths[target]=new;added.append(target)
            e.set(new,'Name',s(step['name']))
            e.set(new,'AttributesSerialize',attributes(step['attributes']))
        elif op=='copy':
            setprop(ref,step['property'],e.get(paths[step['from']],step['property']))
        elif op=='set':
            kind,value,name=step['type'],step['value'],step['property']
            typ=e.columns[e.class_of[ref],name][1]
            if kind=='UDim2':value=udim2(*value)
            elif kind=='Vector2':value=vector(*value)
            elif kind=='boolean':value=bytes([value])
            elif kind=='string':value=s(value)
            elif kind=='number':
                assert typ in (3,4),(name,typ)
                value=i(value) if typ==3 else f(value)
            else:raise ValueError(kind)
            setprop(ref,name,value)
        else:raise ValueError(op)
    result,repair=e.build();after=Editor(result)
    assert not e.removed and not e.final_mapping
    assert after.parents==e.parents
    for ref,parent in before.parents.items():
        assert ref in moved or parent==after.parents[ref]
    verified=0
    for (cid,name),column in before.columns.items():
        if (cid,name) not in e.changed:
            assert before.doc.chunks[column[0]][1]==after.doc.chunks[after.columns[cid,name][0]][1],(cid,name)
            verified+=len(before.classes[cid]);continue
        for ref,old in before.col(cid,name)[3].items():
            actual=after.col(cid,name)[3][ref]
            assert actual==e.get(ref,name),(ref,name)
            assert actual==old or (ref,name)in allowed,(ref,name,'unapproved')
            verified+=1
    assert canonicalize(result)[0]==result
    Document(result).assert_studio_bounds()
    return result,{'inputSha256':digest(raw),'outputSha256':digest(result),
        'changedSources':source_hashes,'addedLayoutObjects':added,'movedObjects':2,
        'removedInstances':0,'verifiedExistingProperties':verified,
        'allUnrelatedSourcesPropertiesParentsPreserved':True,
        'binaryValidation':repair,'written':False}

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--write',action='store_true');args=p.parse_args()
    raw=PLACE.read_bytes();result,report=apply(raw)
    if args.write:
        assert not Path(str(PLACE)+'.lock').exists(),'Target still open'
        assert PLACE.read_bytes()==raw,'Target changed during preparation'
        with PLACE.open('r+b')as stream:
            stream.write(result);stream.truncate();stream.flush();os.fsync(stream.fileno())
        assert PLACE.read_bytes()==result
        Document(PLACE.read_bytes()).assert_studio_bounds()
        report['written']=True
        (REPORT/'FileValidation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
    print(json.dumps({k:v for k,v in report.items()if k!='binaryValidation'},indent=2))

if __name__=='__main__':main()
