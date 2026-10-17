"""Reproduce the downloaded Cloud's actual World1 lobby at horizontal scale 1.0.

The owner's latest instruction is to copy the original layout first. No rejected
2026-10-17 layout or layout script is read or reused. Dry-run is the default.
The existing binary row/referent codecs are shared infrastructure only.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct

from rbxl_rows import Editor, s, f, unf, vector, unvector, udim2, string
from rbxl_geometry import bounds, part_refs, matrix, multiply, transform, yaw
from rbxl_referents import Document, canonicalize

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
REFERENCE = Path(r'C:\Users\kouji\Smash_and_Crush_PreMerge_20261003.rbxl')
INPUT_SHA = '448b3f16a929abcbc4db17b8d59fec570821fcbfcd2d874a29ddda4b4031aeb9'
AREA = 'Workspace.World2Map.TrainingArea'
W1 = 'Workspace.GeneratedMap.TrainingArea'
IMAGES = [117636801345125, 87392597068250, 90484814439233, 92409856077185,
          76660708269544, 73514550426804, 86006626767728, 101543601215487,
          70465860935084, 89190858658364, 135716155094439, 116813512043021]


def attrs(values):
    result = struct.pack('<I', len(values))
    for name, value in values.items():
        result += s(name)
        if isinstance(value, bool):
            result += b'\3' + bytes([value])
        elif isinstance(value, (float, int)):
            result += b'\6' + struct.pack('<d', value)
        else:
            result += b'\2' + s(value)
    return s(result)


def build(raw):
    assert hashlib.sha256(raw).hexdigest() == INPUT_SHA, 'Expected the newly downloaded Cloud input'
    e = Editor(raw)
    original = Editor(raw)
    reference_raw = REFERENCE.read_bytes()
    ref = Editor(reference_raw)
    paths = {e.path(r): r for r in e.parents}
    get = paths.__getitem__
    cls = lambda r: e.doc.classes[e.class_of[r]][0]
    children = lambda r: [v for v, p in e.parents.items() if p == r and v not in e.removed]
    area = get(AREA)
    for name in ('DumbbellDisplays', 'TreadmillDisplays', 'FacilityDisplays'):
        assert AREA + '.' + name not in paths, 'Input already has World2 facilities'
    w1floor = bounds(e, [get(W1 + '.Floor')])
    w2floor = bounds(e, [get(AREA + '.Floor')])
    assert w1floor['size'] == [237.0, 8.0, 149.0]
    assert abs(w2floor['size'][0] - 184.34) < .001
    entrance = get(W1 + '.EntranceCarpets.PathToRun.Upper')
    anchor1 = [unvector(e.get(entrance, 'CFrame')[1])[0], w1floor['max'][1], w1floor['max'][2]]
    connector = get('Workspace.World2Map.LobbyCorridorConnector.ConnectorFloor')
    cb = bounds(e, [connector])
    anchor2 = [cb['center'][0], w2floor['max'][1], cb['min'][2]]
    delta = [b - a for a, b in zip(anchor1, anchor2)]
    report = dict(inputPath=str(PLACE), inputSha256=INPUT_SHA, referencePath=str(REFERENCE),
                  referenceSha256=hashlib.sha256(reference_raw).hexdigest(),
                  design='Latest owner direction: first duplicate World1 at scale 1.0',
                  horizontalScale=1.0, world1Anchor=anchor1, world2Anchor=anchor2,
                  translation=delta, world1Floor=w1floor, world2FloorBefore=w2floor,
                  equipment=[], routes=[], boundaryChanges=[], comparisons={}, imageMapping=[])
    physical_pairs = []
    copied_roots = []

    def shift(root, offset=delta):
        transform(e, e.subtree(root), yaw(0), (0, 0, 0), offset)

    def sanitize(root):
        for r in list(e.subtree(root)):
            kind, cid = cls(r), e.class_of[r]
            if kind in {'Script', 'LocalScript', 'ModuleScript', 'ProximityPrompt', 'ClickDetector',
                        'TouchTransmitter', 'RemoteEvent', 'RemoteFunction', 'BodyVelocity', 'BodyGyro',
                        'BodyPosition', 'VectorForce', 'LinearVelocity', 'AngularVelocity', 'Torque'}:
                e.remove(r)
                continue
            for prop, empty in [('AttributesSerialize', s(b'')), ('SerializedOverrides', s(b'')), ('Tags', bytes(4))]:
                if (cid, prop) in e.columns:
                    e.set(r, prop, empty)
            if kind in {'TextButton', 'ImageButton'}:
                e.set(r, 'Visible', b'\0'); e.set(r, 'Active', b'\0')
                if (cid, 'Interactable') in e.columns:
                    e.set(r, 'Interactable', b'\0')
            if kind == 'Humanoid':
                e.set(r, 'DisplayDistanceType', (2).to_bytes(4, 'big'))
            if r in part_refs(e, [r]):
                e.set(r, 'Anchored', b'\1'); e.set(r, 'CanTouch', b'\0')
                e.set(r, 'Velocity', vector(0, 0, 0)); e.set(r, 'RotVelocity', vector(0, 0, 0))
                if e.names[r] in {'Area', 'TrainingZone', 'Trigger', 'InteractionZone'}:
                    e.set(r, 'Name', s('DisplayBounds'))
                    e.set(r, 'CanCollide', b'\0'); e.set(r, 'CanQuery', b'\0'); e.set(r, 'Transparency', f(1))
        e.set(root, 'AttributesSerialize', attrs(dict(WorldId=2, DisplayOnly=True)))

    def container(name, parent):
        obj, _ = e.clone(area, parent, False)
        e.set(obj, 'Name', s(name)); e.set(obj, 'PrimaryPart', -1)
        e.set(obj, 'WorldPivotData', (b'\2', vector(0, 0, 0), b'\0'))
        sanitize(obj)
        return obj

    def duplicate(source, parent, name=None, y_correction=0):
        obj, mapping = e.clone(source, parent)
        if name:
            e.set(obj, 'Name', s(name))
        sanitize(obj)
        offset = [delta[0], delta[1] + y_correction, delta[2]]
        shift(obj, offset)
        for old, new in mapping.items():
            if old in part_refs(e, [old]) and new not in e.removed:
                physical_pairs.append((old, new, offset))
        copied_roots.append(obj)
        return obj

    def record(label, sources, obj, count=1, direction='preserved', exception=None, source_refs=None):
        source_refs = source_refs or [get(p) for p in sources]
        old = bounds(original, [r for root in source_refs for r in original.subtree(root)], True)
        row = dict(name=label, count=count, sources=sources, destination=e.path(obj),
                   world1Bounds=old, world2Bounds=bounds(e, e.subtree(obj), True),
                   entranceDirection=direction, connection='Display only; no configured value or gameplay input')
        row['world1AnchorOffset'] = [old['center'][i] - anchor1[i] for i in (0, 2)]
        row['world2AnchorOffset'] = [row['world2Bounds']['center'][i] - anchor2[i] for i in (0, 2)]
        if exception:
            row['verticalOnlyAdjustment'] = exception
        report['equipment'].append(row)

    # The same World1 floor footprint, at the fixed World2 connector and Y2.
    floor = get(AREA + '.Floor')
    target_center = [w1floor['center'][0] + delta[0], 1, w1floor['center'][2] + delta[2]]
    e.set(floor, 'size', vector(237, 2, 149))
    e.set(floor, 'CFrame', (b'\2', vector(*target_center)))
    target_floor = bounds(e, [floor]); report['world2FloorAfter'] = target_floor
    dx_left = target_floor['min'][0] - w2floor['min'][0]
    dx_right = target_floor['max'][0] - w2floor['max'][0]
    dz_rear = target_floor['min'][2] - w2floor['min'][2]
    for side, dx in [('WestWall', dx_left), ('EastWall', dx_right)]:
        root = get(AREA + '.Borders.' + side)
        segments = sorted(children(root), key=lambda r: bounds(e, e.subtree(r))['center'][2])
        for j, obj in enumerate(segments):
            shift(obj, (dx, 0, dz_rear * (1 - j / (len(segments) - 1))))
        report['boundaryChanges'].append(dict(path=e.path(root),operation='Translate intact pink segments; no part scaling'))
    rear_roots = [get(AREA + '.Borders.RearWall%d' % j) for j in range(1, 5)]
    fifth, _ = e.clone(rear_roots[-1], get(AREA + '.Borders'))
    e.set(fifth, 'Name', s('RearWall5')); rear_roots.append(fifth)
    for j, obj in enumerate(rear_roots):
        b = bounds(e, e.subtree(obj))
        x = target_center[0] + (j - 2) * 48.28
        shift(obj, (x - b['center'][0], 0, dz_rear))
    extension, _ = e.clone(get(AREA + '.Borders.ExitLeft'), get(AREA + '.Borders'))
    e.set(extension, 'Name', s('ExitLeftOuter')); shift(extension, (-48.28, 0, 0))
    for obj in children(get(AREA + '.Decorations')):
        name = e.names[obj]; b = bounds(e, e.subtree(obj))
        if 'East' in name or 'West' in name:
            z = anchor2[2] + (b['center'][2] - anchor2[2]) * 149 / w2floor['size'][2]
            shift(obj, (dx_right if 'East' in name else dx_left, 0, z - b['center'][2]))
        else:
            x = target_center[0] + (b['center'][0] - w2floor['center'][0]) * 237 / w2floor['size'][0]
            shift(obj, (x - b['center'][0], 0, dz_rear))
    # Only the lobby shoulders extend; center connector/path and all Stages stay fixed.
    shoulders = []
    for name, lo, hi in [('ExitShoulderLeft', target_floor['min'][0], cb['min'][0]),
                         ('ExitShoulderRight', cb['max'][0], target_floor['max'][0])]:
        obj = get('Workspace.World2Map.LobbyCorridorConnector.' + name); shoulders.append(obj)
        pos = unvector(e.get(obj, 'CFrame')[1]); size = unvector(e.get(obj, 'size'))
        pos[0] = (lo + hi) / 2; size[0] = hi - lo
        e.set(obj, 'CFrame', (b'\2', vector(*pos))); e.set(obj, 'size', vector(*size))

    # Copy the exact four-way plaza and each branch. No grid or extra branch.
    path = get(AREA + '.PathToRun')
    for obj in children(path):
        e.remove(obj)
    for source in children(get(W1 + '.EntranceCarpets')):
        name = e.names[source]
        if name == 'Path':
            name = 'WestBranch' if bounds(e, e.subtree(source))['center'][0] < anchor1[0] else 'EastBranch'
        obj = duplicate(source, path, name)
        report['routes'].append(dict(source=e.path(source),destination=e.path(obj),exactTranslation=True))
    tread_path = duplicate(get(W1 + '.PathToTreadmills'), area, 'PathToTreadmills')
    report['routes'].append(dict(source=W1 + '.PathToTreadmills',destination=e.path(tread_path),exactTranslation=True))

    dumbbells = container('DumbbellDisplays', area)
    duplicate(get('Workspace.Ramp'), dumbbells)
    buttons = duplicate(get('Workspace.PerStepButtons'), dumbbells)
    for station in children(buttons):
        if not e.names[station].isdigit():
            continue
        index = int(e.names[station]); board = next(v for v in children(station) if cls(v) == 'BillboardGui')
        own = {e.names[v]:v for v in children(board)}
        press = next(v for v in children(station) if e.names[v] == 'Press')
        uri = 'rbxassetid://%d' % IMAGES[index - 1]
        e.set(station, 'AttributesSerialize', attrs(dict(WorldId=2, DisplayOnly=True, StandIndex=index,
                                                         ImageName='W2-%dD'%index, DisplayImage=uri)))
        e.set(board, 'Adornee', press); e.set(board, 'Size', udim2(9, 0, 9, 0))
        e.set(board, 'StudsOffset', vector(0, 6.5, 0))
        for name in ('Price', 'Amount'):
            e.set(own[name], 'Visible', b'\0')
            for v in e.subtree(own[name]):
                if cls(v) == 'TextLabel': e.set(v, 'Text', s(''))
        icon = own['ItemIcon']; e.set(icon, 'Image', s(uri)); e.set(icon, 'Visible', b'\1')
        e.set(icon, 'Size', udim2(1, 0, .84, 0)); e.set(icon, 'ScaleType', (3).to_bytes(4, 'big'))
        e.set(icon, 'ImageRectOffset', vector(0, 0)); e.set(icon, 'ImageRectSize', vector(0, 0))
        status = own['Status']; e.set(status, 'Name', s('StationNumber')); e.set(status, 'Text', s('%02d'%index))
        e.set(status, 'Visible', b'\1'); e.set(status, 'Size', udim2(1, 0, .12, 0))
        e.set(status, 'TextWrapped', b'\1'); e.set(status, 'TextScaled', b'\1')
        report['imageMapping'].append(dict(index=index,name='W2-%dD'%index,uri=uri,path=e.path(icon),adornee=e.path(press)))
    record('Dumbbells', ['Workspace.Ramp', 'Workspace.PerStepButtons'], dumbbells, 12, '+X')

    facilities = container('FacilityDisplays', area)
    eggs = container('EggDisplays', facilities)
    egg_sources = ['Workspace.Map.Spawn.PathToEggs.Stands', 'Workspace.Map.Spawn.PathToEggs.EggsStand', 'Workspace.Eggs']
    for source in egg_sources:
        duplicate(get(source), eggs, 'Visuals' if source == 'Workspace.Eggs' else None)
    visuals = next(v for v in children(eggs) if e.names[v] == 'Visuals')
    for egg in children(visuals):
        if cls(egg) != 'MeshPart': continue
        for v in e.subtree(egg):
            if cls(v) == 'TextLabel': e.set(v, 'Text', s(e.names[egg])); e.set(v, 'AutoLocalize', b'\0')
            if cls(v) == 'ImageLabel': e.set(v, 'Visible', b'\0')
    record('Normal Eggs', egg_sources, eggs, 4, '-X')
    plans = [('Merge', 'Workspace.RestockShop', 'MergeDisplay'),
             ('Upgrades', 'Workspace.ShopStallTemplate', 'UpgradesDisplay'),
             ('Limited Egg', 'Workspace.Chill Octopus', 'LimitedEggDisplay'),
             ('Win Boost', 'Workspace.Trophy', 'WinBoostDisplay'),
             ('Total ranking', 'Workspace.TotalStrengthRankingBoard', 'TotalRankingDisplay'),
             ('Daily ranking', 'Workspace.DailyStrengthRankingBoard', 'DailyRankingDisplay')]
    for label, source, name in plans:
        adjustment = 0
        if 'Ranking' in name:
            adjustment = anchor1[1] - bounds(e, e.subtree(get(source)), True)['min'][1]
        obj = duplicate(get(source), facilities, name, adjustment)
        for v in e.subtree(obj):
            kind = cls(v)
            if kind == 'TextLabel':
                if name == 'LimitedEggDisplay' and e.names[v] == 'Price':
                    e.set(v, 'Text', s('')); e.set(v, 'Visible', b'\0')
                elif name == 'WinBoostDisplay':
                    e.set(v, 'Text', s('Win Boost' if e.names[v] == 'Text' else ''))
                elif 'Ranking' in name:
                    text = string(e.get(v, 'Text'), 0)[0].decode().lower()
                    if not any(word in text for word in ('strength', 'daily', 'ranking')) and text not in ('rank', 'player'):
                        e.set(v, 'Text', s(''))
            elif kind == 'ImageLabel' and 'Ranking' in name:
                image = string(e.get(v, 'Image'), 0)[0]
                if b'rbxthumb' in image or b'Avatar' in image:
                    e.set(v, 'Visible', b'\0')
        record(label, [source], obj, exception=adjustment or None)
    mailbox = next(r for r in children(get('Workspace.Mailboxes'))
                   if cls(r) == 'Model' and bounds(e, e.subtree(r), True)['center'][0] > w1floor['min'][0])
    feedback = duplicate(mailbox, facilities, 'FeedbackDisplay')
    record('Feedback', [e.path(mailbox)], feedback, source_refs=[mailbox])

    # Replace seven World1 models with the four explicitly approved older models,
    # in the SAME one-row section. This is the only horizontal placement exception.
    tread = container('TreadmillDisplays', area)
    section = bounds(original, original.subtree(get(W1 + '.PathToTreadmills.ThreadmillStand')))
    source_models = [ref.find('Workspace.World2Treadmill.Treadmill%02d'%n) for n in range(1, 5)]
    sizes = [bounds(ref, ref.subtree(r), True)['size'] for r in source_models]
    gap = (section['size'][0] - sum(size[0] for size in sizes)) / 5
    assert gap >= 6, gap
    # Use the original row's available rear strip. Main route remains in front.
    rear = w1floor['min'][2] + 5.4
    cursor = section['min'][0] + gap
    report['treadmillSection'] = dict(world1Bounds=section, count=4, sequence=['01','02','03','04'],
        direction='+X',entranceDirection='+Z',equalSideGaps=gap,rearLineInWorld1=rear,
        policy='01-03 conditions undecided; 04 Robux category only, without price/product/multiplier')
    number_template = get('Workspace.Treadmills.Normal01.BillboardGui')
    for n, source in enumerate(source_models, 1):
        obj, _ = e.import_visual(ref, source, tread); e.set(obj, 'Name', s('%02d'%n)); sanitize(obj)
        b = bounds(e, e.subtree(obj), True)
        center_x = cursor + b['size'][0]/2; cursor += b['size'][0] + gap
        # Earlier model02 faces the opposite way; align its entrance with World1.
        angle = 180 if n == 2 else 0
        target = (center_x + delta[0], anchor2[1], rear + b['size'][2]/2 + delta[2])
        transform(e, e.subtree(obj), yaw(angle), (b['center'][0],b['min'][1],b['center'][2]), target)
        e.set(obj, 'AttributesSerialize', attrs(dict(WorldId=2,DisplayOnly=True,StationIndex=n,
            VisualSource='Previous purchase Treadmill%02d'%n,OfferCategory='Robux' if n==4 else 'Undecided')))
        for v in e.subtree(obj):
            if cls(v) == 'TextLabel': e.set(v, 'Text', s(''))
            if cls(v) == 'BillboardGui': e.set(v, 'Enabled', b'\0')
        board, _ = e.clone(number_template, obj); sanitize(board)
        e.set(board, 'Name', s('StationBillboard'))
        for v in e.subtree(board):
            if cls(v) == 'TextLabel': e.set(v, 'Text', s(''))
            if cls(v) == 'ImageLabel': e.set(v, 'Visible', b'\0')
            if cls(v) == 'Frame' and e.names[v] == 'Rebirth': e.set(v, 'Visible', b'\0')
        label = next(v for v in children(board) if cls(v)=='TextLabel' and e.names[v]=='Multiplier')
        e.set(label,'Text',s('%02d'%n + ('  Robux' if n==4 else '')))
        e.set(label,'Visible',b'\1');e.set(label,'TextWrapped',b'\1');e.set(label,'TextScaled',b'\1')
        e.set(label,'AutoLocalize',b'\0');e.set(label,'Size',udim2(1,0,1,0));e.set(label,'Position',udim2(0,0,0,0));e.set(label,'AnchorPoint',vector(0,0))
        anchor = max(part_refs(e,e.subtree(obj)),key=lambda r: unvector(e.get(r,'CFrame')[1])[1])
        top = bounds(e,e.subtree(obj),True)['max'][1]
        e.set(board,'Adornee',anchor);e.set(board,'Enabled',b'\1');e.set(board,'Size',udim2(10 if n==4 else 6,0,2.4,0))
        e.set(board,'StudsOffset',vector(0,0,0));e.set(board,'StudsOffsetWorldSpace',vector(0,top-unvector(e.get(anchor,'CFrame')[1])[1]+3.5,0))
        e.set(board,'MaxDistance',f(200))
        report['equipment'].append(dict(name='Treadmill %02d'%n,count=1,
            sources=[str(REFERENCE)+' :: '+ref.path(source)],destination=e.path(obj),
            referenceBounds=bounds(ref,ref.subtree(source),True),world2Bounds=bounds(e,e.subtree(obj),True),
            entranceDirection='+Z',sourceYawCorrection=angle,connection='Display only',offerCategory='Robux'if n==4 else'Undecided'))
    sign = duplicate(get('Workspace.Treadmills.Billboard'), tread)

    # Keep the source route graph; resize only the one equipment pad/its stem to
    # cover the different four-model footprints. All equipment remains in one row.
    new_front = max(row['world2Bounds']['max'][2] for row in report['equipment'] if row['name'].startswith('Treadmill '))
    new_back = rear + delta[2] - .2
    pad = next(r for r in children(tread_path) if e.names[r]=='ThreadmillStand')
    for v in children(pad):
        pos=unvector(e.get(v,'CFrame')[1]);size=unvector(e.get(v,'size'))
        pad_back = new_back + (1 if e.names[v]=='Upper' else 0)
        pad_front = new_front + (.5 if e.names[v]=='Upper' else 1)
        pos[2]=(pad_back+pad_front)/2;size[2]=pad_front-pad_back
        e.set(v,'CFrame',(b'\2',vector(*pos)));e.set(v,'size',vector(*size))
    for v in children(tread_path):
        if cls(v)!='Part':continue
        oldbox=bounds(e,[v]);pos=unvector(e.get(v,'CFrame')[1]);size=unvector(e.get(v,'size'))
        lo = new_front + (.5 if e.names[v]=='Upper' else 1)
        hi=oldbox['max'][2];pos[2]=(lo+hi)/2;size[2]=hi-lo
        e.set(v,'CFrame',(b'\2',vector(*pos)));e.set(v,'size',vector(*size))
    report['routes'][-1]['exactTranslation']=False
    report['routes'][-1]['exception']='Only existing treadmill pad depth and connecting stem length adapt to the four approved machine depths; branch graph and section axis unchanged.'
    modified_route_parts=set(part_refs(e,e.subtree(tread_path)))

    # Preserve the actual return Gate/Spawn objects, IDs, attributes and references.
    gate=get(AREA+'.World1ReturnGate');source_gate=get('Workspace.World2Gate')
    oldcf=e.get(gate,'WorldPivotData');sourcecf=e.get(source_gate,'WorldPivotData')
    rotation=multiply(matrix(sourcecf[0]),[matrix(oldcf[0])[j*3+i]for i in range(3)for j in range(3)])
    target=[a+b for a,b in zip(unvector(sourcecf[1]),delta)]
    transform(e,e.subtree(gate),rotation,unvector(oldcf[1]),target)
    spawn=get(AREA+'.World2LobbySpawn');w1spawn=get(W1+'.SpawnLocation')
    cf=e.get(w1spawn,'CFrame');position=unvector(cf[1]);position[0]+=delta[0];position[2]+=delta[2];position[1]=anchor2[1]+unvector(e.get(spawn,'size'))[1]/2
    e.set(spawn,'CFrame',(cf[0],vector(*position)))
    report['travel']=dict(gate=e.path(gate),gateReference='Workspace.World2Gate',gatePivot=target,
        spawn=e.path(spawn),spawnReference=W1+'.SpawnLocation',spawnPosition=position,
        sameInstancesAndAttributes=True,existingStageFacingServiceUnchanged=True)

    # Scope/shape assertions before encoding. Compare each actual donor Part,
    # including same-named Parts; preserve every internal part spacing and rotation.
    worst=0;parts_checked=0
    for old,new,offset in physical_pairs:
        if new in modified_route_parts:continue
        ocf,ncf=original.get(old,'CFrame'),e.get(new,'CFrame')
        expected=[a+b for a,b in zip(unvector(ocf[1]),offset)]
        error=max(abs(a-b)for a,b in zip(unvector(ncf[1]),expected));worst=max(worst,error)
        assert error<.0003,(original.path(old),error)
        assert max(abs(a-b)for a,b in zip(matrix(ocf[0]),matrix(ncf[0])))<1e-6
        assert e.get(new,'size')==original.get(old,'size')
        parts_checked+=1
    report['comparisons']=dict(exactTranslatedSourceParts=parts_checked,maxPositionError=worst,
        unchangedSourcePartSizesAndRotations=True,commonHorizontalScale=1.0,
        permittedExceptions=['Four approved treadmills within original one-row section; model02 entry rotation',
                             'Treadmill pad depth and stem length', 'Ranking-board vertical grounding only'])
    for (cid,prop)in e.columns:
        if prop=='Source':
            for r in original.classes[cid]:assert e.get(r,prop)==original.get(r,prop)
    for r in original.parents:
        if original.path(r).startswith(AREA+'.')or r==area or r in shoulders:continue
        assert r not in e.removed
        for c,prop in e.changed:
            if c==original.class_of[r]:assert e.get(r,prop)==original.get(r,prop),(original.path(r),prop)
    for root in (dumbbells,tread,facilities):
        for r in e.subtree(root):
            assert cls(r)not in {'Script','LocalScript','ModuleScript','ProximityPrompt','ClickDetector','RemoteEvent','RemoteFunction'}
            assert e.get(r,'Tags')==bytes(4)
            value=string(e.get(r,'AttributesSerialize'),0)[0]
            assert not any(key in value for key in (b'ItemId',b'ProductId',b'GamePassId',b'PriceWin',b'StrengthBonus',b'Multiplier'))
            if cls(r)in ('TextButton','ImageButton'):assert e.get(r,'Visible')==b'\0'and e.get(r,'Active')==b'\0'
    report['imageMapping'].sort(key=lambda row: row['index'])
    result,repair=e.build();final=Editor(result)
    for (cid,prop),col in e.columns.items():
        if col[3]is None:continue
        for r in original.classes[cid]:
            if r in e.removed:continue
            value=e.get(r,prop);actual=final.get(e.final_mapping.get(r,r),prop)
            assert actual==(e.final_mapping.get(value,value)if col[1]==19 else value),(original.path(r),prop)
    strings=final.strings();indexes=0
    for (cid,prop),col in final.columns.items():
        if col[1]==28:
            for value in final.col(cid,prop)[3].values():assert int.from_bytes(value,'big')<len(strings);indexes+=1
    assert canonicalize(result)[0]==result
    for row in report['equipment']:
        row['finalBounds']=bounds(final,final.subtree(final.find(row['destination'])),True)
    report.update(outputSha256=hashlib.sha256(result).hexdigest(),binaryValidation=repair,
        sharedStrings=dict(strings=len(strings),validIndexes=indexes),allExistingSourcesUnchanged=True,
        allWorld1ObjectsUnchanged=True,battleCorridorUnchanged=True,
        addedInstances=len(e.parents)-e.doc.count,removedInstances=len(e.removed))
    return result,report


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--write',action='store_true')
    args=parser.parse_args();raw=PLACE.read_bytes();result,report=build(raw)
    if args.write:
        assert not Path(str(PLACE)+'.lock').exists(),'Studio must release this file before writing'
        assert PLACE.read_bytes()==raw
        with PLACE.open('r+b')as stream:stream.write(result);stream.truncate();stream.flush()
        assert PLACE.read_bytes()==result
        Document(PLACE.read_bytes()).assert_studio_bounds()
    report['writtenToSameInputFile']=args.write
    destination=ROOT/'reports/World2LobbyReplica_20261018.json'
    destination.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:report[k]for k in ('writtenToSameInputFile','horizontalScale','world1Floor','world2FloorAfter','comparisons','addedInstances','removedInstances','outputSha256')},indent=2))


if __name__=='__main__':main()
