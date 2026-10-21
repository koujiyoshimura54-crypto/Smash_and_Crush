"""Repair only Lobby perimeter barriers from the current floor and structural wall faces."""
import argparse
import functools
import hashlib
import json
import os
from collections import defaultdict
from pathlib import Path
from rbxl_rows import Editor, vector, unvector, s, f, i
from rbxl_geometry import bounds, matrix
from rbxl_referents import Document, canonicalize

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
REPORT = ROOT/'reports/LobbyPerimeterRepair_20261021'
EXPECTED = '1438016210d9d38e45c65a26d618959790043ef818022ef4fe184bf5d2e26112'
THICKNESS, INSET, TOP = 1, .05, 160


def perimeter(rects, entry, front):
    """Exact union edges of axis-aligned physical faces, including internal voids."""
    rects = [tuple(round(v,3) for v in r) for r in rects]
    xs = sorted({v for r in rects for v in r[:2]})
    zs = sorted({v for r in rects for v in r[2:]})
    xi, zi = {v:n for n,v in enumerate(xs)}, {v:n for n,v in enumerate(zs)}
    nx, nz = len(xs)-1, len(zs)-1
    cells = [bytearray(nx) for _ in range(nz)]
    for x0,x1,z0,z1 in rects:
        for z in range(zi[z0],zi[z1]):
            cells[z][xi[x0]:xi[x1]] = b'\1'*(xi[x1]-xi[x0])
    edges = defaultdict(list)
    for z in range(nz):
        for x in range(nx):
            if not cells[z][x]: continue
            if x==0 or not cells[z][x-1]: edges[0,xs[x],-1].append((zs[z],zs[z+1]))
            if x==nx-1 or not cells[z][x+1]: edges[0,xs[x+1],1].append((zs[z],zs[z+1]))
            if z==0 or not cells[z-1][x]: edges[2,zs[z],-1].append((xs[x],xs[x+1]))
            if z==nz-1 or not cells[z+1][x]: edges[2,zs[z+1],1].append((xs[x],xs[x+1]))
    result = []
    for (axis,line,sign), intervals in sorted(edges.items()):
        merged=[]
        for lo,hi in sorted(intervals):
            if merged and lo<=merged[-1][1]+.0001: merged[-1][1]=max(hi,merged[-1][1])
            else: merged.append([lo,hi])
        for lo,hi in merged:
            # Preserve the normal corridor entry from the Lobby floor onward.
            intervals=[(lo,hi)]
            if axis==0 and entry[0]<line<entry[1]:
                intervals=[(lo,min(hi,front))] if lo<front else []
            elif axis==2 and line>=front-.001:
                intervals=[(lo,min(hi,entry[0])),(max(lo,entry[1]),hi)]
            for a,b in intervals:
                if b-a>.0005:result.append(dict(axis=axis,line=line,sign=sign,lo=a,hi=b))
    return result


def geometry(edge,bottom):
    axis=edge['axis'];along=2 if axis==0 else 0
    pos=[0,(TOP+bottom)/2,0];size=[0,TOP-bottom,0]
    pos[axis]=edge['line']+edge['sign']*(THICKNESS/2-INSET)
    pos[along]=(edge['lo']+edge['hi'])/2
    size[axis]=THICKNESS;size[along]=edge['hi']-edge['lo']+.1
    return pos,size


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--write',action='store_true')
    args=parser.parse_args();raw=PLACE.read_bytes()
    assert hashlib.sha256(raw).hexdigest()==EXPECTED,'Unexpected local edit; inspect before writing'
    before,e=Editor(raw),Editor(raw);e.path=functools.lru_cache(None)(e.path)
    paths={e.path(r):r for r in e.parents};allowed=set();newrefs=set();report=[];worlds=[]
    for world,mapname in ((1,'GeneratedMap'),(2,'World2Map')):
        prefix='Workspace.'+mapname;floor=paths[prefix+'.TrainingArea.Floor'];fb=bounds(e,[floor])
        rects=[(fb['min'][0],fb['max'][0],fb['min'][2],fb['max'][2])];structural=[]
        for r in e.subtree(paths[prefix+'.TrainingArea.Borders']):
            if e.doc.classes[e.class_of[r]][0]!='Part' or e.names[r] not in ('Bottom','Upper'):continue
            if e.names.get(e.parents[r]) not in ('BlockRectangle','BlockSquare') or e.get(r,'CanCollide')!=b'\1':continue
            assert all(abs(v-round(v))<.0001 for v in matrix(e.get(r,'CFrame')[0]))
            b=bounds(e,[r]);rects.append((b['min'][0],b['max'][0],b['min'][2],b['max'][2]));structural.append(e.path(r))
        entry=(263.6,312.0) if world==1 else (-17.08,72.92)
        edges=perimeter(rects,entry,fb['max'][2]);bottom=fb['min'][1]-2
        folder=paths[prefix+'.WallTopExtensions']
        names=['Lobby_Wall_1','Lobby_Wall_2','Lobby_Wall_4'] if world==1 else ['Lobby_EastWall','Lobby_WestWall','Lobby_RearWall','Lobby_ExitLeft','Lobby_ExitRight','Lobby_EastExit_Junction']
        available=list(range(len(edges)));assignments=[]
        for name in names:
            ref=paths[prefix+'.WallTopExtensions.'+name];oldpos=unvector(e.get(ref,'CFrame')[1]);oldsize=unvector(e.get(ref,'size'))
            normal=0 if oldsize[0]<oldsize[2] else 2
            def distance(n):
                edge=edges[n];pos,_=geometry(edge,bottom)
                return (100000 if edge['axis']!=normal else 0)+sum((pos[a]-oldpos[a])**2 for a in (0,2))
            chosen=min(available,key=distance);available.remove(chosen);assignments.append((ref,name,edges[chosen],False))
        donor=assignments[0][0]
        for number,n in enumerate(available,1):
            name=f'Lobby_Perimeter_W{world}_{number:03d}'
            assert prefix+'.WallTopExtensions.'+name not in paths
            ref,_=e.clone(donor,folder,recursive=False);newrefs.add(ref);assignments.append((ref,name,edges[n],True))
        for ref,name,edge,isnew in assignments:
            pos,size=geometry(edge,bottom)
            old={'position':unvector(e.get(ref,'CFrame')[1]),'size':unvector(e.get(ref,'size'))} if not isnew else None
            props={'Name':s(name),'CFrame':(b'\x02',vector(*pos)),'size':vector(*size),
                   'Anchored':b'\1','Transparency':f(1),'CanCollide':b'\1','CanTouch':b'\0',
                   'CanQuery':b'\1','CastShadow':b'\0','CollisionGroup':s('Default'),'CollisionGroupId':i(0)}
            for key,value in props.items():
                if e.get(ref,key)!=value:e.set(ref,key,value);allowed.add((ref,key))
            report.append({'path':prefix+'.WallTopExtensions.'+name,'new':isnew,'before':old,
                           'position':pos,'size':size,'bottom':bottom,'top':TOP,'boundary':edge})
        worlds.append({'world':world,'floor':fb,'bottom':bottom,'top':TOP,'structuralFaces':len(structural),
                       'perimeterParts':len(assignments),'reused':len(names),'added':len(available),
                       'entryX':entry,'entryStartsZ':fb['max'][2]})
    result,repair=e.build();after=Editor(result)
    assert not e.removed and not e.final_mapping and after.parents==e.parents
    for ref,parent in before.parents.items():assert after.parents[ref]==parent
    for (cid,name),column in before.columns.items():
        if (cid,name) not in e.changed:
            assert before.doc.chunks[column[0]][1]==after.doc.chunks[after.columns[cid,name][0]][1]
        else:
            for ref,old in before.col(cid,name)[3].items():
                actual=after.get(ref,name)
                assert actual==e.get(ref,name)
                assert actual==old or (ref,name) in allowed,(ref,name)
    assert canonicalize(result)[0]==result;Document(result).assert_studio_bounds()
    record={'inputSha256':EXPECTED,'outputSha256':hashlib.sha256(result).hexdigest(),'worlds':worlds,
            'allUnrelatedExistingPropertiesSourcesParentsAndUniqueIdsPreserved':True,
            'collisionGroup':'Default; current SlapController disables only PlayerCharacters-to-itself collision',
            'binaryWriteIntegrity':repair,'written':False,'parts':report}
    if args.write:
        assert PLACE.read_bytes()==raw
        with PLACE.open('r+b') as stream:
            stream.write(result);stream.truncate();stream.flush();os.fsync(stream.fileno())
        assert PLACE.read_bytes()==result
        record['written']=True;REPORT.mkdir(exist_ok=True)
        (REPORT/'Writeback.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf8')
    print(json.dumps({k:v for k,v in record.items()if k not in ('parts','binaryWriteIntegrity')},indent=2))


if __name__=='__main__':main()
