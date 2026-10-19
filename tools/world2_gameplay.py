"""Connect the owner's existing World2 facilities without moving/rebuilding them.

No alternate place/backup. Dry-run by default; --write targets the same rbxl only.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import uuid

from rbxl_rows import Editor, s, vector, unvector, f, udim2, string, unf
from rbxl_geometry import bounds, part_refs
from rbxl_referents import Document, canonicalize
from world2_gameplay_sources import build as source_changes, ROOT, PLACE
from world2_workbook import load

INPUT_SHA='7ece6d8e887ea248dca746535529977bed45c3dc3c1b4c394777992b9b6f2b8b'
A='Workspace.World2Map.TrainingArea.'


def attrs(values):
    result=struct.pack('<I',len(values))
    for key,value in values.items():
        result+=s(key)
        if isinstance(value,bool):result+=b'\3'+bytes([value])
        elif isinstance(value,(float,int)):result+=b'\6'+struct.pack('<d',value)
        else:result+=b'\2'+s(value)
    return s(result)


def build(raw):
    assert hashlib.sha256(raw).hexdigest()==INPUT_SHA,'Actual input changed: re-audit before modifying'
    data,workbook=load()
    changes=source_changes(raw)
    editor=changes.editor
    original=Editor(raw)
    paths=changes.paths
    allowed=set()
    source_paths=[]
    for path,source in changes.sources.items():
        if source==changes.before[path]:continue
        ref=paths[path];editor.set(ref,'Source',s(source));allowed.add((ref,'Source'));source_paths.append(path)
    new_config,_=editor.clone(paths['ReplicatedStorage.Config.TrainingConfig'],paths['ReplicatedStorage.Config'],False)
    editor.set(new_config,'Name',s('World2GameplayConfig'))
    editor.set(new_config,'Source',s((ROOT/'src/ReplicatedStorage/Config/World2GameplayConfig.luau').read_text(encoding='utf-8')))
    editor.set(new_config,'ScriptGuid',s('{'+str(uuid.uuid4()).upper()+'}'))
    source_paths.append('ReplicatedStorage.Config.World2GameplayConfig')

    def setprop(ref,prop,value):
        editor.set(ref,prop,value);allowed.add((ref,prop))

    def setattrs(ref,**extra):
        # Explicit metadata is diagnostic, not authorization. Exact roots/Config
        # are validated by the existing services after their scoped changes.
        setprop(ref,'AttributesSerialize',attrs(extra))

    def clone_part(donor,parent,name):
        ref,_=editor.clone(donor,parent,False)
        editor.set(ref,'Name',s(name))
        for prop,value in [('Anchored',b'\1'),('CanCollide',b'\0'),('CanTouch',b'\0'),('CanQuery',b'\0'),('Transparency',f(1))]:
            editor.set(ref,prop,value)
        editor.set(ref,'Tags',bytes(4))
        return ref

    world1_tread=paths['Workspace.Treadmills.Normal01']
    tag_value=editor.get(world1_tread,'Tags')
    assert editor.strings()[int.from_bytes(tag_value,'big')][1]==b'TrainingTreadmill'
    area_donor=paths['Workspace.Treadmills.Normal01.Area']
    station_types=[1,1,2,2,3,3,4]
    setattrs(paths[A+'TreadmillDisplays'],WorldId=2,DisplayOnly=False)
    zones=[]
    for station,kind in enumerate(station_types,1):
        root=paths[A+'TreadmillDisplays.%02d'%station]
        assert not any(editor.names[r]=='Area' for r in editor.subtree(root))
        parts=part_refs(editor,editor.subtree(root))
        conveyor=[r for r in parts if editor.names[r]=='Conveyor']
        if conveyor:
            belt=conveyor
        else:
            body=bounds(editor,parts,True)
            strips=[r for r in parts if unvector(editor.get(r,'size'))[2]>.6*body['size'][2]
                    and unvector(editor.get(r,'size'))[1]<.25*body['size'][1]]
            smallest=min(unvector(editor.get(r,'size'))[1] for r in strips)
            belt=[r for r in strips if abs(unvector(editor.get(r,'size'))[1]-smallest)<.01]
        b=bounds(editor,belt)
        zone=clone_part(area_donor,root,'Area')
        editor.set(zone,'size',vector(b['size'][0],.8,b['size'][2]))
        editor.set(zone,'CFrame',(b'\x02',vector(b['center'][0],b['max'][1]+.15,b['center'][2])))
        setprop(root,'Tags',tag_value)
        setattrs(root,WorldId=2,DisplayOnly=kind==4,StationIndex=station,VisualType='Treadmill%02d'%kind)
        row=data['Treadmills'][kind-1]
        requirement='Robux - Unavailable' if kind==4 else ('Rebirth %d Required'%row['RequiredRebirth'] if row['RequiredRebirth'] else 'Available')
        label=paths[A+'TreadmillDisplays.%02d.StationBillboard.Multiplier'%station]
        setprop(label,'Text',s('%02d | %sx Strength\n%s'%(kind,row['Multiplier'],requirement)))
        zones.append(dict(path=editor.path(zone),sourceBeltParts=[editor.path(r)for r in belt],
                          size=unvector(editor.get(zone,'size')),position=unvector(editor.get(zone,'CFrame')[1]),type=kind))

    dumbbell_root=paths[A+'DumbbellDisplays']
    setattrs(dumbbell_root,WorldId=2,DisplayOnly=False)
    for index,row in enumerate(data['Dumbbells'],1):
        base=A+'DumbbellDisplays.PerStepButtons.'+str(index)
        model=paths[base];board=paths[base+'.BillboardGui']
        setattrs(model,WorldId=2,DisplayOnly=False,StandIndex=index,ItemId='W2_NORMAL_%02d'%index)
        setprop(board,'Size',udim2(9,0,12,0))
        for suffix,height,order in [('ItemIcon',.63,1),('StationNumber',.06,2),('Price',.10,3),('Amount',.11,4)]:
            ref=paths[base+'.BillboardGui.'+suffix]
            setprop(ref,'Size',udim2(1,0,height,0));setprop(ref,'Visible',b'\1')
            setprop(ref,'LayoutOrder',struct.pack('>I',order*2))
        setprop(paths[base+'.BillboardGui.Price'],'Text',s('+'+str(row['StrengthBonus'])+' Strength'))
        setprop(paths[base+'.BillboardGui.Amount.Main'],'Text',s(str(row['PriceWin'])))
        setprop(paths[base+'.BillboardGui.Amount.Main'],'Visible',b'\1')
        setprop(paths[base+'.BillboardGui.Amount.Icon'],'Visible',b'\1')
        actual_image=string(editor.get(paths[base+'.BillboardGui.ItemIcon'],'Image'),0)[0].decode()
        workbook_image='rbxassetid://'+str([117636801345125,87392597068250,90484814439233,92409856077185,76660708269544,73514550426804,86006626767728,101543601215487,70465860935084,89190858658364,135716155094439,116813512043021][index-1])
        assert actual_image==workbook_image,'Existing World2 image changed: preserve the actual display and reconcile Config'
        status,_=editor.clone(paths[base+'.BillboardGui.StationNumber'],board)
        editor.set(status,'Name',s('Status'));editor.set(status,'Text',s('Step to buy'))
        editor.set(status,'Size',udim2(1,0,.10,0));editor.set(status,'LayoutOrder',struct.pack('>I',10))

    # Reuse the authored Merge entry zone with the actual rigid visual translation.
    donor=paths['Workspace.RestockShop.Area'];target=paths[A+'FacilityDisplays.MergeDisplay']
    before=bounds(original,original.subtree(paths['Workspace.RestockShop']),True)
    after=bounds(original,original.subtree(target),True)
    delta=[b-a for a,b in zip(before['center'],after['center'])]
    merge_area=clone_part(donor,target,'Area')
    rot,pos=editor.get(donor,'CFrame')
    editor.set(merge_area,'CFrame',(rot,vector(*[a+b for a,b in zip(unvector(pos),delta)])))
    setattrs(target,WorldId=2,DisplayOnly=False)
    setattrs(paths[A+'FacilityDisplays.UpgradesDisplay'],WorldId=2,DisplayOnly=False)
    setattrs(paths[A+'FacilityDisplays.EggDisplays'],WorldId=2,DisplayOnly=False)
    for index,name in enumerate(['Basic','Rare','Legendary','Mythic'],1):
        root=paths[A+'FacilityDisplays.EggDisplays.Visuals.'+name]
        setattrs(root,WorldId=2,DisplayOnly=False,EggId='W2_'+name)
        info=paths[A+'FacilityDisplays.EggDisplays.Visuals.'+name+'.Prize.Info']
        setprop(info,'Text',s(str(data['Eggs'][index-1]['PriceWin'])+' Win'))
        setprop(info,'Visible',b'\1')
        icon=paths[A+'FacilityDisplays.EggDisplays.Visuals.'+name+'.Prize.Icon']
        setprop(icon,'Visible',b'\1')

    # Validate reused assets, without cloning or modifying any template/icon.
    import re
    sources=[['Dog','Grey Cat','Pink Bunny','Sheep','Bear','Camel','Slime'],['Cow','Giraffe','Lion','Lizard','Spider','Bat','Shroom'],['Elephant','Mammoth','Penguin','Crocodile','Octopus','Shark','Ninja'],['Turtle','Alien','Anglerfish','Dino','Scorpion','Evil Dragon','Chimpanzini Bananini']]
    asset_models={editor.names[r] for r in editor.subtree(paths['ReplicatedStorage.Assets.Pets']) if editor.doc.classes[editor.class_of[r]][0]=='Model'}
    for names in sources:
        for name in names:
            assert name in asset_models,('Missing reused Pet model',name)
            assert 'ReplicatedStorage.Assets.Icons.Pets.'+name in paths,('Missing reused Pet icon',name)
    for name in ['Pet_042','Pet_064','Pet_081','Pet_086','Pet_094','Pet_024','Pet_135']:
        assert 'ReplicatedStorage.Assets.LimitedEgg01Pets.'+name in paths

    result,repair=editor.build()
    decoded=Editor(result)
    assert not editor.final_mapping
    # All original opaque property payloads remain exact unless listed above.
    for key,col in original.columns.items():
        cid,prop=key
        refs=original.classes[cid]
        touched={r for r,p in allowed if p==prop and original.class_of.get(r)==cid}
        if not touched and decoded.classes[cid]==refs:
            assert original.doc.chunks[col[0]][1]==decoded.doc.chunks[decoded.columns[key][0]][1],key
        else:
            for ref in refs:
                if (ref,prop)not in allowed:assert original.get(ref,prop)==decoded.get(ref,prop),(original.path(ref),prop)
    assert all(decoded.parents[r]==p for r,p in original.parents.items())
    for r in part_refs(original,original.parents):
        for prop in ['CFrame','size','CanCollide']:
            assert original.get(r,prop)==decoded.get(r,prop),(original.path(r),prop)
    for path in ['ReplicatedStorage.Config.World1BossConfig','ReplicatedStorage.Config.LevelRequirements','ServerStorage.Templates.DumbbellDisplayTemplate']:
        ref=paths[path]
        assert all((ref,p)not in allowed for cc,p in original.columns if cc==original.class_of[ref])
    second,_=canonicalize(result);assert second==result
    shared=decoded.strings();indexes=0
    for (cid,prop),col in decoded.columns.items():
        if col[1]==28:
            for ref in decoded.classes[cid]:assert int.from_bytes(decoded.get(ref,prop),'big')<len(shared);indexes+=1
    report=dict(inputPath=str(PLACE),inputSha256=INPUT_SHA,outputSha256=hashlib.sha256(result).hexdigest(),
                workbookSha256=workbook['sha256'],changedSources=source_paths,
                changedOriginalProperties=[dict(path=original.path(r),property=p)for r,p in sorted(allowed)],
                addedInstances=len(decoded.parents)-len(original.parents),originalInstancesRemoved=0,
                originalParentsUnchanged=True,allOriginalPartTransformsSizesCollisionsUnchanged=True,
                sourceChangesBasedOnActualFile=True,zones=zones,mergeArea=decoded.path(merge_area),
                binaryValidation=repair,sharedStrings=dict(count=len(shared),validatedIndexes=indexes),
                canonicalizationIdempotent=True,noPlay=True,noStudioSavePublish=True,
                paidOffersDisabled=['World2 Treadmill04','World2 paid Aura','World2 Limited Egg'])
    return result,report


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--write',action='store_true')
    args=parser.parse_args();raw=PLACE.read_bytes();result,report=build(raw)
    if args.write:
        assert PLACE.read_bytes()==raw and not Path(str(PLACE)+'.lock').exists()
        PLACE.write_bytes(result);assert PLACE.read_bytes()==result
        Document(result).assert_studio_bounds();report['writtenToSameFile']=True
    (ROOT/'reports/World2Gameplay_20261020.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps({k:report[k]for k in ['outputSha256','addedInstances','allOriginalPartTransformsSizesCollisionsUnchanged']}))


if __name__=='__main__':main()
