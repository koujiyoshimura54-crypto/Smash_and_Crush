"""Measured World2 lobby expansion and inert purchased visual facilities.

Dry run by default; --write requires the inspected hash and no Studio lock.
Only the named CurrentCloud is written. The previous purchase reference is read
only, and contributes six visual subtrees, never Source or gameplay configuration.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import struct
from rbxl_rows import Editor,s,f,unf,vector,unvector,udim2,string,u32
from rbxl_referents import Document,canonicalize
from rbxl_geometry import bounds,part_refs,transform,yaw,horizontal_gap,matrix
from dumbbell_2d_displays import attributes

ROOT=Path(__file__).resolve().parents[1]
PLACE=Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
REFERENCE=Path(r'C:\Users\kouji\Smash_and_Crush_PreMerge_20261003.rbxl')
AREA='Workspace.World2Map.TrainingArea'


def finalize_numbers(e):
    """Use each authored number label inside its visible, scalable content row."""
    root=e.find(AREA+'.TreadmillDisplays')
    models=[r for r,p in e.parents.items()if p==root and e.doc.classes[e.class_of[r]][0]=='Model'and r not in e.removed]
    for model in models:
        index=int(e.names[model]);desc=e.subtree(model)
        guis=[r for r in desc if e.doc.classes[e.class_of[r]][0]=='BillboardGui']
        board=guis[0]
        labels=[r for r in e.subtree(board)if e.doc.classes[e.class_of[r]][0]=='TextLabel']
        label=next((r for r in labels if e.names[r]=='Multiplier'),labels[0])
        for r in labels:e.set(r,'Text',s(''))
        e.set(label,'Text',s('%02d'%index));e.set(label,'Visible',b'\1')
        # Studio loads TextWrapped after TextScaled; an authored false value can
        # turn scaling back off. Keep both flags consistent for imported assets.
        e.set(label,'TextWrapped',b'\1');e.set(label,'TextScaled',b'\1');e.set(label,'AutoLocalize',b'\0')
        e.set(label,'AnchorPoint',vector(.5,.5));e.set(label,'Position',udim2(.5,0,.5,0))
        e.set(label,'Size',udim2(.95,0,.9,0));e.set(label,'BackgroundTransparency',f(1))
        e.set(board,'Enabled',b'\1');e.set(board,'MaxDistance',f(200))
        anchor=e.get(board,'Adornee')
        top=bounds(e,e.subtree(model),True)['max'][1]
        rise=top-unvector(e.get(anchor,'CFrame')[1])[1]+3.5
        e.set(board,'StudsOffset',vector(0,0,0))
        e.set(board,'StudsOffsetWorldSpace',vector(0,rise,0))


def union_tiles(rectangles):
    """Disjoint rectangles for a carpet union; adjacent tops never overlap."""
    xs=sorted({r[j] for r in rectangles for j in (0,1)})
    zs=sorted({r[j] for r in rectangles for j in (2,3)})
    result=[];active={}
    for za,zb in zip(zs,zs[1:]):
        segments=[];start=None
        for xa,xb in zip(xs,xs[1:]):
            inside=any(a<=(xa+xb)/2<=b and c<=(za+zb)/2<=d for a,b,c,d in rectangles)
            if inside and start is None:start=xa
            if start is not None and (not inside or xb==xs[-1]):
                segments.append((start,xb if inside else xa));start=None
        next_active={}
        for segment in segments:
            if segment in active:
                tile=active[segment];tile[3]=zb
            else:
                tile=[segment[0],segment[1],za,zb];result.append(tile)
            next_active[segment]=tile
        active=next_active
    return result


def apply(raw):
    e=Editor(raw);before=Editor(raw);reference=Editor(REFERENCE.read_bytes())
    lookup={e.path(r):r for r in e.parents};get=lookup.__getitem__
    children=lambda r:[v for v,p in e.parents.items() if p==r and v not in e.removed]
    cls=lambda r:e.doc.classes[e.class_of[r]][0]
    report=dict(inputSha256=hashlib.sha256(raw).hexdigest(),referencePath=str(REFERENCE),
        referenceSha256=hashlib.sha256(reference.doc.raw).hexdigest(),equipment=[],boundaries=[],
        sourceChanges=[],excluded=[],registrationAudit={},carpets={})
    area=get(AREA);floor=get(AREA+'.Floor');oldfloor=bounds(e,[floor]);report['floorBefore']=oldfloor
    assert AREA+'.TreadmillDisplays' not in lookup and AREA+'.FacilityDisplays' not in lookup,'Facilities already installed; refuse duplicate build'
    assert abs(oldfloor['size'][0]-184.34)<.001 and abs(oldfloor['size'][2]-140.18)<.001,'Unexpected inspected floor'
    # Repeat the measured 48.28-stud rear pattern and 56.1-stud side pattern.
    width=unvector(e.get(floor,'size'))[0]+4*48.28
    depth=unvector(e.get(floor,'size'))[2]+2*56.1
    floorpos=unvector(e.get(floor,'CFrame')[1]);front=oldfloor['max'][2]
    floorpos[2]=front-depth/2
    e.set(floor,'size',vector(width,2,depth));e.set(floor,'CFrame',(b'\2',vector(*floorpos)))
    report['floorAfter']=bounds(e,[floor])

    def rigid(ref,offset):transform(e,e.subtree(ref),yaw(0),(0,0,0),offset)
    def sanitize(ref):
        for v in list(e.subtree(ref)):
            kind=cls(v);cid=e.class_of[v]
            if kind in {'Script','LocalScript','ModuleScript','ProximityPrompt','ClickDetector',
                        'TouchTransmitter','RemoteEvent','RemoteFunction','BodyVelocity','BodyGyro',
                        'BodyPosition','VectorForce','LinearVelocity','AngularVelocity','Torque'}:
                e.remove(v);continue
            if (cid,'AttributesSerialize')in e.columns:e.set(v,'AttributesSerialize',s(b''))
            if (cid,'SerializedOverrides')in e.columns:e.set(v,'SerializedOverrides',s(b''))
            if (cid,'Tags')in e.columns:e.set(v,'Tags',bytes(4))
            if kind in {'TextButton','ImageButton'}:
                e.set(v,'Visible',b'\0');e.set(v,'Active',b'\0')
                if (cid,'Interactable')in e.columns:e.set(v,'Interactable',b'\0')
            if kind=='Humanoid':
                e.set(v,'DisplayDistanceType',(2).to_bytes(4,'big'))
            if v in part_refs(e,[v]):
                e.set(v,'Anchored',b'\1');e.set(v,'CanTouch',b'\0')
                e.set(v,'Velocity',vector(0,0,0));e.set(v,'RotVelocity',vector(0,0,0))
                if e.names[v] in {'Area','TrainingZone','Trigger','InteractionZone'}:
                    e.set(v,'Name',s('DisplayBounds'));e.set(v,'CanCollide',b'\0');e.set(v,'CanQuery',b'\0');e.set(v,'Transparency',f(1))
        e.set(ref,'AttributesSerialize',attributes(dict(WorldId=2,DisplayOnly=True)))

    def container(name,parent):
        r,_=e.clone(area,parent,False);e.set(r,'Name',s(name));e.set(r,'PrimaryPart',-1)
        e.set(r,'WorldPivotData',(b'\2',vector(0,0,0),b'\0'));sanitize(r)
        return r

    def clone(ref,parent,name):
        result,_=e.clone(ref,parent);e.set(result,'Name',s(name));sanitize(result);return result

    def ground(ref,x,z,angle=0,ground_y=2):
        box=bounds(e,e.subtree(ref),True)
        transform(e,e.subtree(ref),yaw(angle),(box['center'][0],box['min'][1],box['center'][2]),(x,ground_y,z))
        return bounds(e,e.subtree(ref),True)

    def record(name,ref,source,count=1,entry='+Z'):
        row=dict(name=name,count=count,path=e.path(ref),source=source,bounds=bounds(e,e.subtree(ref),True),
                 entryDirection=entry,connection='Display only; no price/effect/product/input/registration')
        report['equipment'].append(row);return row

    border=get(AREA+'.Borders')
    for name,dx in [('WestWall',-96.56),('EastWall',96.56)]:
        side=get(AREA+'.Borders.'+name)
        segment=min(children(side),key=lambda r:bounds(e,e.subtree(r))['min'][2])
        for n in (1,2):
            piece,_=e.clone(segment,side);e.set(piece,'Name',s('Extension%02d'%n));rigid(piece,(dx,0,-56.1*n))
        # Existing segments move sideways; new extension segments already moved.
        original=[v for v in e.subtree(side) if v<e.doc.count]
        transform(e,original,yaw(0),(0,0,0),(dx,0,0))
        report['boundaries'].append(dict(path=e.path(side),bounds=bounds(e,e.subtree(side))))
    for n in range(1,5):rigid(get(AREA+'.Borders.RearWall%d'%n),(0,0,-112.2))
    for edge in ('Left','Right'):
        donor=get(AREA+'.Borders.RearWall'+('1'if edge=='Left'else'4'))
        for n in (1,2):
            piece,_=e.clone(donor,border);e.set(piece,'Name',s('RearExtension%s%d'%(edge,n)))
            rigid(piece,((-1 if edge=='Left'else 1)*48.28*n,0,0))
        donor=get(AREA+'.Borders.Exit'+edge)
        for n in (1,2):
            piece,_=e.clone(donor,border);e.set(piece,'Name',s('ExitExtension%s%d'%(edge,n)))
            rigid(piece,((-1 if edge=='Left'else 1)*48.28*n,0,0))
    decor=get(AREA+'.Decorations')
    originals=list(children(decor))
    for r in originals:
        name=e.names[r]
        if 'East'in name:rigid(r,(96.56,0,0))
        elif 'West'in name:rigid(r,(-96.56,0,0))
        else:rigid(r,(0,0,-112.2))
    # Repeat the existing cotton/chocolate rhythm along the longer side/rear walls.
    for side in ('East','West'):
        tree=next(r for r in originals if e.names[r]=='CottonTree'+side+'1')
        chocolate=next(r for r in originals if e.names[r]=='Chocolate'+side+'1')
        for n in (1,2):
            for source,label in [(tree,'Cotton'),(chocolate,'Chocolate')]:
                r,_=e.clone(source,decor);e.set(r,'Name',s('%s%sExtension%d'%(label,side,n)));rigid(r,(0,0,-56.1*n))
    for side,dx in [('West',-96.56),('East',96.56)]:
        source=next(r for r in originals if e.names[r]=='CottonTree'+side+'1')
        r,_=e.clone(source,decor);e.set(r,'Name',s('RearCotton'+side))
        box=bounds(e,e.subtree(r));rigid(r,(0,0,(1867-112.2)-box['center'][2]))

    # Keep the existing station assembly and its own-Press image links together.
    dumbbell=get(AREA+'.DumbbellDisplays');box=bounds(e,e.subtree(dumbbell))
    transform(e,e.subtree(dumbbell),yaw(-90),(box['center'][0],0,box['center'][2]),(-88,0,1838))
    record('Dumbbells',dumbbell,AREA+'.DumbbellDisplays (reused in place)',12)

    # Native purchased yellow/red stair faces for a walkable equipment entrance.
    body=get('Workspace.Ramp.Stand.Part');red=get('Workspace.World2Map.TrainingArea.PathToRun.RearUpper')
    gold=get('Workspace.World2Map.TrainingArea.PathToRun.RearLower')
    def block(donor,parent,name,center,size):
        r,_=e.clone(donor,parent,False);e.set(r,'Name',s(name));sanitize(r)
        e.set(r,'CFrame',(b'\2',vector(*center)));e.set(r,'size',vector(*size));return r
    def steps(parent,x,edge,width,rise,count):
        folder=container('EntranceSteps',parent)
        for j in range(count):
            height=(j+1)*rise/count
            z=edge+(count-j-.5)*2.6
            block(gold,folder,'Gold%02d'%j,(x,2+height/2,z),(width+.6,height,2.6))
            block(red,folder,'Carpet%02d'%j,(x,2+height+.035,z),(width,.07,2.6))
        return folder
    steps(dumbbell,-88,bounds(e,e.subtree(dumbbell))['max'][2],54,2.22,3)
    report['equipment'][0]['boundsWithEntranceSteps']=bounds(e,e.subtree(dumbbell),True)

    tread=container('TreadmillDisplays',area)
    positions=[(69,1797),(104,1797),(139,1797),(174,1797),(69,1865),(104,1865),
               (139,1865),(174,1865),(69,1930),(104,1930),(139,1930),(174,1930)]
    models=['Normal01','Normal02','Iron01','Iron02','Gold01','Diamond01']
    for index,(x,z) in enumerate(positions,1):
        if index<=6:
            source='Workspace.World2Treadmill.Treadmill%02d'%index
            obj,_=e.import_visual(reference,reference.find(source),tread)
            origin=str(REFERENCE)+' :: '+source
        else:
            source='Workspace.Treadmills.'+models[index-7]
            obj,_=e.clone(get(source),tread);origin=source
        e.set(obj,'Name',s('%02d'%index));sanitize(obj)
        e.set(obj,'AttributesSerialize',attributes(dict(WorldId=2,DisplayOnly=True,StationIndex=index,
            VisualFamily='Previous purchase'if index<=6 else'Purchased map')))
        ground(obj,x,z)
        # Replace only semantic performance/requirement text; keep authored UI artwork.
        guis=[r for r in e.subtree(obj)if cls(r)=='BillboardGui']
        if not guis:
            g,_=e.clone(get('Workspace.Treadmills.Normal01.BillboardGui'),obj);sanitize(g);guis=[g]
        primary=guis[0]
        for r in e.subtree(obj):
            if cls(r)=='TextLabel':e.set(r,'Text',s(''));e.set(r,'AutoLocalize',b'\0')
            if cls(r)=='Frame'and e.names[r]=='Rebirth':e.set(r,'Visible',b'\0')
            if cls(r)=='ImageLabel' and any(g in guis for g in [e.parents[r],e.parents.get(e.parents[r])]):e.set(r,'Visible',b'\0')
        label=next(r for r in e.subtree(primary)if cls(r)=='TextLabel')
        e.set(label,'Text',s('%02d'%index));e.set(label,'Visible',b'\1')
        anchor=max(part_refs(e,e.subtree(obj)),key=lambda r:unvector(e.get(r,'CFrame')[1])[1])
        e.set(primary,'Adornee',anchor);e.set(primary,'Size',udim2(6,0,2.4,0));e.set(primary,'StudsOffset',vector(0,3,0))
        row=record('Treadmill %02d'%index,obj,origin)
        row['stationIndex']=index
        belts=[r for r in part_refs(e,e.subtree(obj))if e.names[r]=='Conveyor']
        if belts:
            row['beltBounds']=bounds(e,[belts[0]])
            if index<=6:
                rise=row['beltBounds']['max'][1]-2-.05
                steps(obj,x,row['bounds']['max'][2],12,rise,3)
                row['boundsWithEntranceSteps']=bounds(e,e.subtree(obj),True)
    sign,_=e.clone(get('Workspace.Treadmills.Billboard'),tread);sanitize(sign)
    transform(e,e.subtree(sign),yaw(0),unvector(e.get(sign,'CFrame')[1]),(122,29,1950))

    facilities=container('FacilityDisplays',area)
    eggs=container('EggDisplays',facilities)
    egg_sources=['Workspace.Map.Spawn.PathToEggs.Stands','Workspace.Map.Spawn.PathToEggs.EggsStand','Workspace.Eggs']
    for source in egg_sources:
        obj,_=e.clone(get(source),eggs);sanitize(obj)
    # Use the actual shared stand/platform origin, not the off-centre label anchor.
    source_center=(342.824462890625,4,13.693077087402344)
    transform(e,e.subtree(eggs),yaw(90),source_center,(-100,2,1918))
    egg_roots=[r for r in children(eggs) if e.names[r]=='Eggs']
    for folder in egg_roots:
        e.set(folder,'Name',s('Visuals'))
        for obj in children(folder):
            if cls(obj)=='MeshPart':
                labels=[r for r in e.subtree(obj)if cls(r)=='TextLabel']
                for r in labels:e.set(r,'Text',s(e.names[obj]));e.set(r,'AutoLocalize',b'\0')
                for r in e.subtree(obj):
                    if cls(r)=='ImageLabel':e.set(r,'Visible',b'\0')
    record('Normal Eggs',eggs,' + '.join(egg_sources),4)

    plans=[('MergeDisplay','Workspace.RestockShop',-119,1991,130,'-Z'),
           ('UpgradesDisplay','Workspace.ShopStallTemplate',-70,1991,45,'-Z'),
           ('LimitedEggDisplay','Workspace.Chill Octopus',-45,1918,0,'+Z'),
           ('WinBoostDisplay','Workspace.Trophy',153,1995,0,'-Z'),
           ('TotalRankingDisplay','Workspace.TotalStrengthRankingBoard',80,1995,0,'-Z'),
           ('DailyRankingDisplay','Workspace.DailyStrengthRankingBoard',113,1995,0,'-Z')]
    for name,source,x,z,angle,entry in plans:
        obj=clone(get(source),facilities,name);ground(obj,x,z,angle)
        if name=='LimitedEggDisplay':
            for r in e.subtree(obj):
                if cls(r)=='TextLabel'and e.names[r]=='Price':e.set(r,'Text',s(''));e.set(r,'Visible',b'\0')
        if name=='WinBoostDisplay':
            for r in e.subtree(obj):
                if cls(r)=='TextLabel':e.set(r,'Text',s('Win Boost'if e.names[r]=='Text'else''))
        if 'Ranking'in name:
            # Retain title/board layout, blank every saved row/name/score/avatar.
            for r in e.subtree(obj):
                if cls(r)=='TextLabel':
                    txt=string(e.get(r,'Text'),0)[0].decode()
                    if not any(word in txt.lower()for word in ('strength','daily','ranking')):e.set(r,'Text',s(''))
                elif cls(r)=='ImageLabel':
                    image=string(e.get(r,'Image'),0)[0]
                    if b'rbxthumb' in image or b'Avatar' in image:e.set(r,'Visible',b'\0')
        record(name,obj,source,entry=entry)
    # Three same-named purchased mailboxes exist; select the real current-Lobby one.
    feedbacks=[r for r in children(get('Workspace.Mailboxes'))if cls(r)=='Model']
    donor=next(r for r in feedbacks if bounds(e,e.subtree(r))['center'][0]>150)
    obj=clone(donor,facilities,'FeedbackDisplay');ground(obj,-29,2000,0)
    row=record('Feedback',obj,'Workspace.Mailboxes.Feedback (current Lobby, original centre X277.48)',entry='-Z')

    report['excluded']=[
        dict(name='Aura',reason='No physical Aura facility exists in the current Lobby; inventory menu/effect libraries only.'),
        dict(name='Rebirth',reason='Screen menu only; no current Lobby building or stand to reuse.'),
        dict(name='Standalone Shop',reason='Shop is a screen-menu entrance. Existing physical RestockShop is already the Merge facility; do not duplicate it as an invented shop.'),
        dict(name='Gift/WinsGift/original Leaderboards',reason='These are outside the active GeneratedMap Lobby on the retired purchased map, not current Lobby facilities.')]

    # Rebuild only the World2 carpet surfaces using purchased red/gold donors.
    # Disjoint union avoids co-planar duplicate tops at branch intersections.
    lanes=[(27.92,1790,27.92,front,13),(-138,1963.4231,194,1963.4231,13),
           (-88,1878.5,-88,1963.4231,13),(-138,1941, -29,1941,13),
           (-100,1941,-100,1963.4231,13),(-133,1978,190,1978,13),
           (27.92,1835,194,1835,12),(27.92,1905,194,1905,13),
           (27.92,1950,194,1950,13),(27.92,1902,57.92,1902,13),
           (57.92,1891.73,57.92,1902,13)]
    def lane_rects(extra):
        result=[]
        for x1,z1,x2,z2,w in lanes:
            half=(w+extra)/2
            result.append((min(x1,x2)-(half if x1==x2 else 0),max(x1,x2)+(half if x1==x2 else 0),
                           min(z1,z2)-(half if z1==z2 else 0),max(z1,z2)+(half if z1==z2 else 0)))
        return result
    path=get(AREA+'.PathToRun')
    for r in children(path):e.remove(r)
    for layer,donor,height,thickness,extra in [('Gold',gold,2.1,.2,3),('Red',red,2.3,.2,0)]:
        tiles=union_tiles(lane_rects(extra));report['carpets'][layer]=tiles
        for j,(a,b,c,d)in enumerate(tiles,1):block(donor,path,'%s%03d'%(layer,j),((a+b)/2,height,(c+d)/2),(b-a,thickness,d-c))
    report['lanes']=[dict(fromXZ=[a,b],toXZ=[c,d],width=w)for a,b,c,d,w in lanes]
    # Correct the saved station image only if the obsolete URI remains.
    icon=get('Workspace.PerStepButtons.8.BillboardGui.ItemIcon')
    image=string(e.get(icon,'Image'),0)[0].decode()
    assert image in ('rbxassetid://11017141876908','rbxassetid://110171141876908')
    if image.endswith('11017141876908'):e.set(icon,'Image',s('rbxassetid://110171141876908'))
    master=string(e.get(get('ReplicatedStorage.Config.DumbbellItemMaster'),'Source'),0)[0].decode()
    assert 'ImageAssetId=110171141876908' in master
    report['world1ImageCorrection']=dict(sourceAlreadyCorrect=True,savedIconCorrected=image.endswith('11017141876908'),image='rbxassetid://110171141876908')
    finalize_numbers(e)

    # Prove no copied gameplay identity/metadata or unconfigured numeric offer remains.
    new_roots=[tread,facilities]
    for root in new_roots:
        for r in e.subtree(root):
            cid=e.class_of[r];kind=cls(r)
            assert kind not in {'Script','LocalScript','ModuleScript','ProximityPrompt','ClickDetector','RemoteEvent','RemoteFunction'}
            assert e.get(r,'Tags')==bytes(4)
            attrs=string(e.get(r,'AttributesSerialize'),0)[0]
            assert not any(v in attrs for v in (b'ItemId',b'ProductId',b'GamePass',b'Multiplier',b'StrengthBonus',b'PriceWin',b'RequiredRebirth'))
            if kind=='TextLabel':
                text=string(e.get(r,'Text'),0)[0].decode()
                assert not any(v in text.lower()for v in ('speed','strength +','robux','x100','149','premium','rebirth')),(e.path(r),text)

    # Source and World1 invariants are independent of referent-number canonicalization.
    for (cid,prop),col in e.columns.items():
        if prop=='Source':
            for r in before.classes[cid]:assert e.get(r,prop)==before.get(r,prop)
    for r in before.parents:
        p=before.path(r)
        if p.startswith('Workspace.World2Map.TrainingArea.') or p==AREA:continue
        if r==icon:continue
        for c,prop in e.changed:
            if c==before.class_of[r]:assert e.get(r,prop)==before.get(r,prop),(p,prop)
    result,repair=e.build();final=Editor(result)
    # Every original surviving row retains its exact owner/value, aside from planned
    # changes and reference-number translation; compare duplicate-name Parts by ID.
    for (cid,prop),col in e.columns.items():
        if col[3]is None:continue
        for r in before.classes[cid]:
            if r in e.removed:continue
            target=e.final_mapping.get(r,r);value=e.get(r,prop);actual=final.get(target,prop)
            assert actual==(e.final_mapping.get(value,value)if col[1]==19 else value),(before.path(r),prop)
    strings=final.strings();indexes=0
    for (cid,prop),col in final.columns.items():
        if col[1]==28:
            for value in final.col(cid,prop)[3].values():assert int.from_bytes(value,'big')<len(strings);indexes+=1
    assert canonicalize(result)[0]==result
    report.update(outputSha256=hashlib.sha256(result).hexdigest(),binaryValidation=repair,
        addedInstances=len(e.parents)-e.doc.count,removedInstances=len(e.removed),
        sharedStrings=dict(strings=len(strings),validIndexes=indexes),allSourcesUnchanged=True,
        world1ChangedObject='Workspace.PerStepButtons.8.BillboardGui.ItemIcon.Image',
        fixedBattleCorridorConnectorSpawnGate=True)
    return result,report,master


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write',action='store_true');parser.add_argument('--expected-sha256')
    args=parser.parse_args();raw=PLACE.read_bytes();result,report,master=apply(raw)
    if args.write:
        mirror=ROOT/'src/ReplicatedStorage/Config/DumbbellItemMaster.luau'
        current=mirror.read_text(encoding='utf-8')
        # Retain the owner's indentation on the already-correct NORMAL_08 row.
        assert [l.lstrip()for l in current.replace('11017141876908','110171141876908').splitlines()]==[l.lstrip()for l in master.splitlines()]
        assert hashlib.sha256(raw).hexdigest()==args.expected_sha256
        assert not Path(str(PLACE)+'.lock').exists(),'Studio still holds CurrentCloud'
        assert PLACE.read_bytes()==raw
        with PLACE.open('r+b')as stream:stream.write(result);stream.truncate()
        assert PLACE.read_bytes()==result;Document(PLACE.read_bytes()).assert_studio_bounds()
        mirror.write_text(master,encoding='utf-8',newline='\n')
        (ROOT/'reports/World2LobbyFacilities_20261017.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    else:
        # A JSON investigation artifact, never an alternate place or game snapshot.
        (ROOT/'reports/World2LobbyFacilitiesPlan_20261017.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in report.items()if k in ('floorBefore','floorAfter','addedInstances','removedInstances','allSourcesUnchanged','outputSha256','sharedStrings')},indent=2))


if __name__=='__main__':main()
