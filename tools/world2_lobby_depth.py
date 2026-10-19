"""Extend the existing World2 lobby toward its treadmill row, without widening.

This is a scoped edit of the 2026-10-19 actual input, not a layout regeneration.
Dry-run by default; --write writes only the owner's same CurrentCloud file.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import struct

from rbxl_rows import Editor, s, vector, unvector, string
from rbxl_geometry import bounds, part_refs, matrix, transform, yaw
from rbxl_referents import canonicalize, Document

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
INPUT_SHA = 'a9d875ec82c7b043774f80402195b35fd1ca62c50fdf11fc3f1473389e9dc646'
A = 'Workspace.World2Map.TrainingArea'


def attributes(values):
    result = struct.pack('<I', len(values))
    for key, value in values.items():
        result += s(key)
        if isinstance(value, bool):
            result += b'\3' + bytes([value])
        elif isinstance(value, (int, float)):
            result += b'\6' + struct.pack('<d', value)
        else:
            result += b'\2' + s(value)
    return s(result)


def build(raw):
    assert hashlib.sha256(raw).hexdigest() == INPUT_SHA, 'Input changed; remeasure before editing'
    original, e = Editor(raw), Editor(raw)
    paths = {e.path(r): r for r in e.parents}
    get = lambda suffix: paths[A + '.' + suffix]
    cls = lambda r: e.doc.classes[e.class_of[r]][0]
    children = lambda parent: [r for r, p in e.parents.items() if p == parent and r not in e.removed]
    box = lambda root: bounds(e, e.subtree(root), True)
    allowed = set()
    rigid_pairs = []
    translations = []

    def move(root, delta, source_mapping=None):
        refs = e.subtree(root)
        allowed.update(refs)
        before = {r: e.get(r, 'CFrame') for r in part_refs(e, refs)}
        transform(e, refs, yaw(0), (0, 0, 0), delta)
        for r, cf in before.items():
            expected = [p + shift for p, shift in zip(unvector(cf[1]), delta)]
            assert max(abs(p - q) for p, q in zip(expected, unvector(e.get(r, 'CFrame')[1]))) < .0003
            assert max(abs(p - q) for p, q in zip(matrix(cf[0]), matrix(e.get(r, 'CFrame')[0]))) < 1e-6
            donor = source_mapping.get(r, r) if source_mapping else r
            rigid_pairs.append((donor, r))

    def clone(root, parent):
        obj, mapping = e.clone(root, parent)
        # The actual installed donor is already inert. Preserve its visual metadata.
        for old, new in mapping.items():
            e.set(new, 'AttributesSerialize', e.get(old, 'AttributesSerialize'))
        return obj, {new: old for old, new in mapping.items()}

    def set_interval(part, axis, lo, hi):
        assert hi > lo
        allowed.add(part)
        rotation, position = e.get(part, 'CFrame')
        before = bounds(e, [part])
        position, size = unvector(position), unvector(e.get(part, 'size'))
        orientation = matrix(rotation)
        local_axis = max(range(3), key=lambda j: abs(orientation[axis*3+j]))
        assert abs(abs(orientation[axis*3+local_axis])-1) < 1e-6
        position[axis], size[local_axis] = (lo + hi) / 2, hi - lo
        e.set(part, 'CFrame', (rotation, vector(*position)))
        e.set(part, 'size', vector(*size))
        after = bounds(e, [part])
        assert abs(after['min'][axis]-lo)<.001 and abs(after['max'][axis]-hi)<.001
        assert all(abs(after['size'][j]-before['size'][j])<.001 for j in range(3)if j!=axis)

    floor = get('Floor'); fb = box(floor)
    assert abs(fb['size'][0] - 237) < .001 and abs(fb['size'][2] - 149) < .001
    west, east = box(get('Borders.WestWall')), box(get('Borders.EastWall'))
    left, right = west['max'][0], east['min'][0]
    usable = right - left
    # Decorations are above the equipment and outside the side walls' inner faces.
    for root in children(get('Decorations')):
        b = box(root)
        assert b['min'][1] > 30
    tread = get('TreadmillDisplays')
    models = sorted([r for r in children(tread) if cls(r) == 'Model'], key=lambda r: e.names[r])
    assert [e.names[r] for r in models] == ['01', '02', '03', '04']
    donor_bounds = [box(r) for r in models]
    types = [1, 1, 2, 2, 3, 3, 4]
    slots = ['Normal01', 'Normal02', 'Iron01', 'Iron02', 'Gold01', 'Gold02', 'Diamond01']
    widths = [donor_bounds[n - 1]['size'][0] for n in types]
    body_width = sum(widths)
    gap = 6.0
    minimum_end = 8.0
    required_width = body_width + 6 * gap + 2 * minimum_end
    assert required_width <= usable, 'Width extension requires a newly measured plan'
    row_width = body_width + 6 * gap
    end_gap = (usable - row_width) / 2
    row_left = left + end_gap
    row_right = row_left + row_width

    dumbbells, eggs = get('DumbbellDisplays'), get('FacilityDisplays.EggDisplays')
    assert len([r for r in children(get('DumbbellDisplays.PerStepButtons')) if e.names[r].isdigit()]) == 12
    assert len([r for r in children(get('FacilityDisplays.EggDisplays.Visuals')) if cls(r) == 'MeshPart']) == 4
    db, eb = box(dumbbells), box(eggs)
    shell_clearance = 4.0
    dumbbell_dx = left + shell_clearance - db['min'][0]
    egg_dx = right - shell_clearance - eb['max'][0]
    obstacle_front = min(db['min'][2], *(box(r)['min'][2] for r in children(get('FacilityDisplays'))))
    apron, front_lane, rear_lane = 2.0, 12.0, 6.0
    row_front = obstacle_front - front_lane - apron
    row_back = row_front - max(b['size'][2] for b in donor_bounds)
    rear_roots = [get('Borders.RearWall%d' % n) for n in range(1, 6)]
    rear_inside = max(box(r)['max'][2] for r in rear_roots)
    rear_intrusion = rear_inside - fb['min'][2]
    required_depth = fb['max'][2] - (row_back - rear_lane - rear_intrusion)
    depth = math.ceil(required_depth)
    extension = depth - fb['size'][2]
    assert extension > 0
    report = dict(inputPath=str(PLACE), inputSha256=INPUT_SHA, scope='Existing World2 lobby depth/row/side-facility edit',
        direction=dict(stage='+Z',treadmill='-Z',imageRightDumbbells='-X',imageLeftEggs='+X'),
        beforeFloor=fb, effectiveWidth=dict(left=left,right=right,width=usable),
        widths=dict(bodyTotal=body_width,machineGap=gap,minimumEndGap=minimum_end,
                    requiredWidth=required_width,actualEndGap=end_gap,rowLeft=row_left,rowRight=row_right),
        adopted=dict(width=fb['size'][0],depth=depth,extension=extension,widthChanged=False,
                     requiredDepth=required_depth,frontApron=apron,frontLane=front_lane,
                     rearLane=row_back-(rear_inside-extension),floorTop=fb['max'][1]),
        facilityMoves=[], machines=[], shell=[], routes=[], sourceChanges=[])

    # Keep the Stage-facing edge and X/Y unchanged; extend only toward -Z.
    set_interval(floor, 2, fb['min'][2] - extension, fb['max'][2])
    for root in rear_roots:
        move(root, (0, 0, -extension))
        report['shell'].append(dict(path=e.path(root),delta=[0,0,-extension]))
    # Four intact native segments cover each longer side, without scaling parts.
    for side in ('WestWall', 'EastWall'):
        parent = get('Borders.' + side)
        segments = sorted(children(parent), key=lambda r: box(r)['center'][2])
        assert len(segments) == 3
        rear_center = box(segments[0])['center'][2] - extension
        front_center = box(segments[-1])['center'][2]
        added, mapping = clone(segments[0], parent)
        e.set(added, 'Name', s('DepthExtensionSegment'))
        ordered = [added, *segments]
        for index, root in enumerate(ordered):
            target_z = rear_center + (front_center - rear_center) * index / 3
            dz = target_z - box(root)['center'][2]
            move(root, (0, 0, dz), mapping if root == added else None)
        segment_boxes = sorted([box(r) for r in ordered], key=lambda b: b['min'][2])
        overlaps = [segment_boxes[j]['max'][2] - segment_boxes[j+1]['min'][2] for j in range(3)]
        assert min(overlaps) >= 0
        report['shell'].append(dict(path=e.path(parent),nativeSegments=4,segmentOverlaps=overlaps))
    for root in children(get('Decorations')):
        b = box(root)
        if 'East' in e.names[root] or 'West' in e.names[root]:
            z = fb['max'][2] + (b['center'][2] - fb['max'][2]) * depth / fb['size'][2]
            dz = z - b['center'][2]
        else:
            dz = -extension
        move(root, (0, 0, dz))

    # Rigid side-facility moves; extend the existing branches, anchored at the plaza.
    for root, dx, branch in ((dumbbells,dumbbell_dx,'WestBranch'),(eggs,egg_dx,'EastBranch')):
        before = box(root); move(root, (dx, 0, 0))
        report['facilityMoves'].append(dict(path=e.path(root),delta=[dx,0,0],before=before,after=box(root)))
        for part in part_refs(e, e.subtree(get('PathToRun.' + branch))):
            b = bounds(e,[part]); lo,hi = b['min'][0],b['max'][0]
            set_interval(part,0,lo+dx if dx<0 else lo,hi+dx if dx>0 else hi)
            report['routes'].append(dict(path=e.path(part),before=b,after=bounds(e,[part])))

    # Duplicate only the missing individual of each already installed 01/02/03.
    duplicates = [clone(root,tread) for root in models[:3]]
    arrangement = [(models[0],None), duplicates[0], (models[1],None), duplicates[1],
                   (models[2],None), duplicates[2], (models[3],None)]
    cursor = row_left
    for index, ((root,mapping),kind,slot) in enumerate(zip(arrangement,types,slots),1):
        b = box(root); source_path = original.path(models[kind-1])
        dx = cursor - b['min'][0]; dz = row_front - b['max'][2]
        move(root,(dx,0,dz),mapping); cursor += b['size'][0] + gap
        e.set(root,'Name',s('%02d'%index))
        e.set(root,'AttributesSerialize',attributes(dict(WorldId=2,DisplayOnly=True,StationIndex=index,
            VisualSource='Previous purchase Treadmill%02d'%kind,VisualType='Treadmill%02d'%kind,
            World1Slot=slot,OfferCategory='Robux'if kind==4 else'Undecided')))
        board = next(r for r in children(root) if e.names[r]=='StationBillboard')
        label = next(r for r in children(board) if e.names[r]=='Multiplier')
        # Visible type numbers reproduce image-left 04/03/03/02/02/01/01.
        e.set(label,'Text',s('%02d'%kind+('  Robux'if kind==4 else'')))
        report['machines'].append(dict(station=index,type=kind,world1Slot=slot,source=source_path,
            destination=e.path(root),added=mapping is not None,delta=[dx,0,dz],bounds=box(root)))
    sign = get('TreadmillDisplays.Billboard')
    sign_cf=e.get(sign,'CFrame');sign_pos=unvector(sign_cf[1])
    move(sign,((row_left+row_right)/2-sign_pos[0],0,(row_front+row_back)/2-sign_pos[2]))

    pad = get('PathToTreadmills.ThreadmillStand')
    old_pad = bounds(e,e.subtree(pad))
    lower = next(r for r in children(pad)if e.names[r]=='Lower')
    original_lower = bounds(e,[lower])
    pad_left,pad_right=row_left-4,row_right+4
    pad_back,pad_front=row_back-1,row_front+apron
    for part in part_refs(e,e.subtree(pad)):
        b=bounds(e,[part])
        left_inset=b['min'][0]-original_lower['min'][0]
        right_inset=original_lower['max'][0]-b['max'][0]
        back_inset=b['min'][2]-original_lower['min'][2]
        front_inset=original_lower['max'][2]-b['max'][2]
        set_interval(part,0,pad_left+left_inset,pad_right-right_inset)
        set_interval(part,2,pad_back+back_inset,pad_front-front_inset)
        report['routes'].append(dict(path=e.path(part),before=b,after=bounds(e,[part])))
    for part in children(get('PathToTreadmills')):
        if cls(part)!='Part':continue
        b=bounds(e,[part]); matching=next(r for r in children(pad)if e.names[r]==e.names[part])
        start=bounds(e,[matching])['max'][2]
        set_interval(part,2,start,b['max'][2])
        report['routes'].append(dict(path=e.path(part),before=b,after=bounds(e,[part])))

    # Scope assertions: no original Instance removed/reparented; no protected
    # equipment, Source, World1, Gate/Spawn or BattleCorridor property is changed.
    assert not e.removed
    assert all(e.parents[r]==p for r,p in original.parents.items())
    for cid,prop in e.changed:
        for r in original.classes[cid]:
            if r not in allowed:
                assert e.get(r,prop)==original.get(r,prop),(original.path(r),prop)
    for (cid,prop),col in e.columns.items():
        if prop=='Source':
            assert e.classes[cid]==original.classes[cid]
            assert all(e.get(r,prop)==original.get(r,prop)for r in original.classes[cid])
    for donor,new in rigid_pairs:
        assert e.get(new,'size')==original.get(donor,'size'),original.path(donor)
    unsafe_classes={'Script','LocalScript','ModuleScript','ProximityPrompt','ClickDetector','TouchTransmitter','RemoteEvent','RemoteFunction'}
    for root in (tread,dumbbells,eggs):
        for r in e.subtree(root):
            assert cls(r)not in unsafe_classes
            assert e.get(r,'Tags')==bytes(4)
            a=string(e.get(r,'AttributesSerialize'),0)[0]
            assert not any(key in a for key in (b'ItemId',b'ProductId',b'GamePassId',b'PriceWin',b'StrengthBonus',b'Multiplier'))
            if r in part_refs(e,[r]):
                assert e.get(r,'Anchored')==b'\1'and e.get(r,'CanTouch')==b'\0'
                assert unvector(e.get(r,'Velocity'))==[0,0,0]
    for first,second in zip(report['machines'],report['machines'][1:]):
        assert abs(second['bounds']['min'][0]-first['bounds']['max'][0]-gap)<.001
    assert max(abs(row['bounds']['max'][2]-row_front)for row in report['machines'])<.001
    assert abs(box(dumbbells)['min'][0]-left-shell_clearance)<.001
    assert abs(right-box(eggs)['max'][0]-shell_clearance)<.001
    assert abs(box(floor)['max'][2]-fb['max'][2])<.001
    report.update(afterFloor=box(floor),padBefore=old_pad,padAfter=bounds(e,e.subtree(pad)),
        originalInstancesRemoved=0,addedInstances=len(e.parents)-len(original.parents),
        rigidPartChecks=len(rigid_pairs),allOriginalSourcesUnchanged=True,
        protectedObjectsUnchanged=True,originalParentsUnchanged=True)
    result,repair=e.build();final=Editor(result)
    for (cid,prop),col in e.columns.items():
        if col[3]is None:continue
        for r in original.classes[cid]:
            value=e.get(r,prop);actual=final.get(e.final_mapping.get(r,r),prop)
            assert actual==(e.final_mapping.get(value,value)if col[1]==19 else value),(original.path(r),prop)
    strings=final.strings();indexes=0
    for (cid,prop),col in final.columns.items():
        if col[1]==28:
            for value in final.col(cid,prop)[3].values():
                assert int.from_bytes(value,'big')<len(strings);indexes+=1
    assert canonicalize(result)[0]==result
    report.update(outputSha256=hashlib.sha256(result).hexdigest(),binaryValidation=repair,
                  sharedStrings=dict(count=len(strings),validatedIndexes=indexes))
    return result,report


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--write',action='store_true')
    args=parser.parse_args();raw=PLACE.read_bytes();result,report=build(raw)
    if args.write:
        assert not Path(str(PLACE)+'.lock').exists(),'Studio must release the actual target before writing'
        assert PLACE.read_bytes()==raw
        with PLACE.open('r+b')as stream:stream.write(result);stream.truncate();stream.flush()
        assert PLACE.read_bytes()==result
        Document(PLACE.read_bytes()).assert_studio_bounds()
    report['writtenToSameInputFile']=args.write
    (ROOT/'reports/World2LobbyDepth_20261019.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({key:report[key]for key in ('writtenToSameInputFile','effectiveWidth','widths','adopted','addedInstances','rigidPartChecks','outputSha256')},indent=2))


if __name__=='__main__':main()
