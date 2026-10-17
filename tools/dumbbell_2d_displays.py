"""Apply the owner's 2026-10-17 display-only facility changes to CurrentCloud.

Read-only dry run by default. --write requires the exact inspected input hash
and no Studio lock. No backup/alternate place, Play, Save or Publish operation.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
from rbxl_referents import Document, string, u32
from rbxl_rows import Editor, s, f, i, vector, unvector, udim2

W1 = {6:92138447886967, 8:11017141876908, 9:129522181601539,
      10:92929093922544, 11:89748292939648, 12:121194224737958}
W2 = [117636801345125,87392597068250,90484814439233,92409856077185,
      76660708269544,73514550426804,86006626767728,101543601215487,
      70465860935084,89190858658364,135716155094439,116813512043021]
# The actual saved assembly's bounds center is (216.6690826,6.3885612,11.980938).
# Retain its orientation/scale and floor-relative height: W1 floor top4 -> W2 top2.
OFFSET = (-242.66908264160156, -2, 1905.0190620422363)
ROOT = Path(__file__).resolve().parents[1]


def attributes(values):
    out = struct.pack('<I', len(values))
    for name, value in values.items():
        out += s(name)
        if isinstance(value, bool):out += b'\x03' + bytes([value])
        elif isinstance(value, (int,float)):out += b'\x06' + struct.pack('<d',value)
        else:out += b'\x02' + s(value)
    return s(out)


def apply(raw):
    e = Editor(raw)
    lookup = {e.path(r):r for r in e.parents}
    get = lookup.__getitem__
    assert not any(p.startswith('Workspace.World2Map.TrainingArea.DumbbellDisplays') for p in lookup)
    master = get('ReplicatedStorage.Config.DumbbellItemMaster')
    source = string(e.get(master,'Source'),0)[0].decode()
    original_source = source
    for index,image in W1.items():
        source,count = re.subn(r'(ItemId="NORMAL_%02d"[^\n]*ImageAssetId=)\d+' % index,
                              lambda m:m[1]+str(image),source)
        assert count == 1
    e.set(master,'Source',s(source))
    items = {}
    for index,price,bonus,image in re.findall(r'ItemId="NORMAL_(\d+)"[^\n]*PriceWin=(\d+), StrengthBonus=(\d+), ImageAssetId=(\d+)',source):
        items[int(index)]=(int(price),int(bonus),int(image))
    assert len(items)==12 and items[5][2]==134662273184560

    def layout(board,w2=False):
        e.set(board,'Size',udim2(9,0,9,0))
        e.set(board,'StudsOffset',vector(0,6.5,0))
        e.set(board,'ClipsDescendants',b'\0')
        children={e.names[r]:r for r,p in e.parents.items() if p==board and r not in e.removed}
        icon=children['ItemIcon']
        e.set(icon,'Size',udim2(.96,0,.84 if w2 else .58,0))
        e.set(icon,'ScaleType',(3).to_bytes(4,'big')) # Enum.ScaleType.Fit
        e.set(icon,'ImageRectOffset',vector(0,0));e.set(icon,'ImageRectSize',vector(0,0))
        for name,width,height in [('Amount',.8,.14),('Price',.95,.12),('Status',.95,.10)]:
            e.set(children[name],'Size',udim2(width,0,height,0))
        return children

    removed=[]
    facilities=[]
    for index in range(1,13):
        path='Workspace.PerStepButtons.'+str(index)
        rows=layout(get(path+'.BillboardGui'))
        e.set(rows['ItemIcon'],'Image',s('rbxassetid://'+str(items[index][2])))
        exhibit=get('Workspace.ShoesModels.'+str(index));removed.append(e.path(exhibit));e.remove(exhibit)
        facilities.append(dict(worldId=1,index=index,itemId='NORMAL_%02d'%index,
            imageName=('W1-5DV2' if index==6 else 'W1-%dDV2'%index) if index in W1 else 'Existing (unchanged)',
            imageId=str(items[index][2]),image='rbxassetid://'+str(items[index][2]),path=path,
            iconPath=path+'.BillboardGui.ItemIcon',pressPosition=unvector(e.get(get(path+'.Press'),'CFrame')[1]),
            priceWin=items[index][0],strengthBonus=items[index][1]))

    area=get('Workspace.World2Map.TrainingArea')
    group,_=e.clone(area,area,recursive=False)
    e.set(group,'Name',s('DumbbellDisplays'))
    e.set(group,'PrimaryPart',-1)
    e.set(group,'WorldPivotData',(b'\x02',vector(0,0,0),b'\0'))
    e.set(group,'AttributesSerialize',attributes(dict(WorldId=2,DisplayOnly=True)))
    ramp,ramp_map=e.clone(get('Workspace.Ramp'),group)
    pads,pads_map=e.clone(get('Workspace.PerStepButtons'),group)
    mapping={**ramp_map,**pads_map}
    for old,new in mapping.items():
        cid=e.class_of[new]
        if (cid,'Tags') in e.columns:e.set(new,'Tags',bytes(4)) # existing empty SSTR entry0
        if (cid,'CFrame') in e.columns:
            rot,pos=e.get(new,'CFrame');pos=unvector(pos)
            e.set(new,'CFrame',(rot,vector(*[a+b for a,b in zip(pos,OFFSET)])))
        if (cid,'CanTouch') in e.columns:e.set(new,'CanTouch',b'\0')
        if (cid,'WorldPivotData') in e.columns:
            rot,pos,has=e.get(new,'WorldPivotData');pos=unvector(pos)
            if has==b'\x01':e.set(new,'WorldPivotData',(rot,vector(*[a+b for a,b in zip(pos,OFFSET)]),has))
    for index,image in enumerate(W2,1):
        old=get('Workspace.PerStepButtons.'+str(index));model=pads_map[old]
        e.set(model,'AttributesSerialize',attributes(dict(WorldId=2,StandIndex=index,DisplayOnly=True,
            ImageName='W2-%dD'%index,DisplayImage='rbxassetid://'+str(image))))
        rows=layout(pads_map[get('Workspace.PerStepButtons.%d.BillboardGui'%index)],True)
        e.set(rows['ItemIcon'],'Image',s('rbxassetid://'+str(image)))
        for name in ('Amount','Price'):e.set(rows[name],'Visible',b'\0')
        e.set(rows['Status'],'Name',s('StationNumber'))
        e.set(rows['Status'],'Text',s('%02d'%index))
        e.set(rows['Status'],'Size',udim2(.95,0,.12,0))
        path='Workspace.World2Map.TrainingArea.DumbbellDisplays.PerStepButtons.'+str(index)
        facilities.append(dict(worldId=2,index=index,imageName='W2-%dD'%index,imageId=str(image),
            image='rbxassetid://'+str(image),path=path,iconPath=path+'.BillboardGui.ItemIcon',
            pressPosition=unvector(e.get(pads_map[get('Workspace.PerStepButtons.%d.Press'%index)],'CFrame')[1]),
            displayOnly=True))

    # No gameplay/ownership/save Source is changed; no held/template content is touched.
    for r in e.parents:
        if r>=e.doc.count or r in e.removed:continue
        cid=e.class_of[r]
        if (cid,'Source') in e.columns and r!=master:
            assert e.get(r,'Source')==EditorSource(e.doc,r,cid)
    result,repair=e.build()
    final=Editor(result)
    final_paths={final.path(r):r for r in final.parents}
    # Exact surviving original property-row equality except specifically permitted edits
    # and reference-number canonicalization. Compare referent targets by final full path.
    before=Editor(raw)
    changed_original=[]
    for (cid,name),col in e.columns.items():
        if col[3] is None:continue
        for r in before.classes[cid]:
            if r in e.removed:continue
            v=before.get(r,name);expected=e.get(r,name)
            if v!=expected:changed_original.append(dict(path=before.path(r),property=name))
            target=e.final_mapping.get(r,r)
            actual=final.get(target,name)
            if col[1]==19:
                assert actual==e.final_mapping.get(expected,expected),(before.path(r),name,expected,actual)
            else:assert actual==expected,(before.path(r),name)
    assert len(final.subtree(final_paths['Workspace.ShoesModels']))==1
    for row in facilities:
        model=final_paths[row['path']];board=final_paths[row['path']+'.BillboardGui']
        assert string(final.get(final_paths[row['iconPath']],'Image'),0)[0].decode()==row['image']
        assert final.get(board,'Adornee')==final_paths[row['path']+'.Press']
        if row['worldId']==2:
            for r in final.subtree(model):
                cid=final.class_of[r]
                assert final.doc.classes[cid][0] not in ('Script','LocalScript','ModuleScript','ProximityPrompt','ClickDetector','RemoteEvent','RemoteFunction')
                assert b'ItemId' not in final.get(r,'AttributesSerialize')
    report=dict(inputSha256=hashlib.sha256(raw).hexdigest(),outputSha256=hashlib.sha256(result).hexdigest(),
        facilities=facilities,removedExhibits=removed,removedInstances=len(e.removed),addedInstances=len(e.parents)-e.doc.count,
        addedEquipmentRoot='Workspace.World2Map.TrainingArea.DumbbellDisplays',offset=list(OFFSET),
        world2PreviousFacilities=0,world1GeometryUnchanged=True,heldAndTemplateUnchanged=True,
        changedSourcePaths=['ReplicatedStorage.Config.DumbbellItemMaster'],changedOriginalProperties=changed_original,
        binaryValidation=repair)
    return result,report,source


def EditorSource(doc,ref,cid):
    for kind,data,_,_ in doc.chunks:
        if kind!=b'PROP' or u32(data)!=cid:continue
        name,p=string(data,4)
        if name!=b'Source':continue
        p+=1
        for r in doc.classes[cid][1]:
            start=p;_,p=string(data,p)
            if r==ref:return data[start:p]
    raise AssertionError('Missing Source')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('place',type=Path)
    parser.add_argument('--write',action='store_true')
    parser.add_argument('--expected-sha256')
    args=parser.parse_args()
    raw=args.place.read_bytes()
    result,report,source=apply(raw)
    if args.write:
        assert hashlib.sha256(raw).hexdigest()==args.expected_sha256,'Unexpected current file'
        assert not Path(str(args.place)+'.lock').exists(),'Studio still holds this file'
        assert args.place.read_bytes()==raw,'Place changed during preparation'
        with args.place.open('r+b') as stream:stream.write(result);stream.truncate()
        assert args.place.read_bytes()==result
        Document(args.place.read_bytes()).assert_studio_bounds()
        (ROOT/'src/ReplicatedStorage/Config/DumbbellItemMaster.luau').write_text(source,encoding='utf-8',newline='\n')
        (ROOT/'reports/Dumbbell2DDisplays_20261017.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in report.items() if k not in ('facilities','changedOriginalProperties')},indent=2))
    print('changed original property rows:',len(report['changedOriginalProperties']))


if __name__=='__main__':main()
