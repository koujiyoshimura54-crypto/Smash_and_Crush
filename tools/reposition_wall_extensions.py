"""Move only the 75 existing wall extensions to the outside of their boundaries."""
import argparse
import copy
import functools
import hashlib
import json
import os
from pathlib import Path
from rbxl_rows import Editor, vector, unvector
from rbxl_referents import Document

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
REPORT = ROOT / 'reports/WallExtensionEdges_20261021'
EXPECTED = '885da7ec604d93e56af033221827166880b30e06488c115d729a4cc2e8782f9a'
LIP = .05


def extent(row, axis):
    return [row['position'][axis] - row['size'][axis]/2,
            row['position'][axis] + row['size'][axis]/2]


def span(row, axis, low, high):
    row['position'][axis] = (low + high)/2
    row['size'][axis] = high - low


def plan(spec):
    rows = copy.deepcopy(spec['parts'])
    by = {(r['world'], r['name']): r for r in rows}
    for row in rows:
        name = row['name']
        if row['kind'] == 'WallJunction':
            continue
        if row['kind'] == 'OpeningExtension':
            axis, sign = 2, 1  # +Z is normal progress in both authored corridors.
        elif row['world'] == 1 and name.startswith('Lobby_'):
            axis, sign = {'Lobby_Wall_1': (2,-1), 'Lobby_Wall_2': (0,1),
                          'Lobby_Wall_3': (2,1), 'Lobby_Wall_4': (0,-1)}[name]
        elif 'LeftSide' in name or name.endswith('LeftWall') or name == 'Lobby_WestWall':
            axis, sign = 0, -1
        elif 'RightSide' in name or name.endswith('RightWall') or name == 'Lobby_EastWall':
            axis, sign = 0, 1
        elif name == 'Lobby_RearWall':
            axis, sign = 2, -1
        else:
            assert name in ('Stage10_End', 'Stage10_EndWall', 'Lobby_ExitLeft', 'Lobby_ExitRight'), name
            axis, sign = 2, 1
        # Preserve thickness; put its inside face 0.05 stud inside the old outer edge.
        row['position'][axis] += sign * (row['size'][axis] - LIP)
        row['edgeAxis'], row['outwardSign'] = axis, sign

    # Extend endpoints to the newly offset perpendicular panels; no new Parts.
    west, east = by[1,'Lobby_Wall_4'], by[1,'Lobby_Wall_2']
    rear, front = by[1,'Lobby_Wall_1'], by[1,'Lobby_Wall_3']
    for row in (rear, front):
        span(row, 0, extent(west,0)[0]-.05, extent(east,0)[1]+.05)
    for row in (west, east):
        span(row, 2, extent(rear,2)[0]-.05, extent(front,2)[1]+.05)

    for world in (1,2):
        if world == 1:
            left = by[1,'Stage10_BossArea_LeftSide']
            right = by[1,'Stage10_BossArea_RightSide']
            end = by[1,'Stage10_End']
        else:
            left = by[2,'Stage01_10_LeftWall']
            right = by[2,'Stage01_10_RightWall']
            end = by[2,'Stage10_EndWall']
        span(end, 0, extent(left,0)[0]-.05, extent(right,0)[1]+.05)
        for row in (left, right):
            span(row, 2, extent(row,2)[0], extent(end,2)[1]+.05)
        for row in rows:
            if row['world'] != world or not row['name'].startswith('Stage') or row['kind'] != 'OpeningExtension':
                continue
            # Span all adjoining side-wall strips, including the World1 width step.
            if world == 1:
                previous = int(row['name'][5:7])
                following = previous + 1
                ls = [by[1,f'Stage{previous:02}_BossArea_LeftSide'], by[1,f'Stage{following:02}_Environment_LeftSide']]
                rs = [by[1,f'Stage{previous:02}_BossArea_RightSide'], by[1,f'Stage{following:02}_Environment_RightSide']]
            else:
                ls, rs = [left], [right]
            span(row, 0, min(extent(p,0)[0] for p in ls)-.05, max(extent(p,0)[1] for p in rs)+.05)

    west, east = by[2,'Lobby_WestWall'], by[2,'Lobby_EastWall']
    rear = by[2,'Lobby_RearWall']
    exit_left, exit_right = by[2,'Lobby_ExitLeft'], by[2,'Lobby_ExitRight']
    span(rear, 0, extent(west,0)[0]-.05, extent(east,0)[1]+.05)
    span(exit_left, 0, extent(west,0)[0]-.05, extent(exit_left,0)[1])
    span(exit_right, 0, extent(exit_right,0)[0], extent(east,0)[1]+.05)
    span(west, 2, extent(rear,2)[0]-.05, extent(exit_left,2)[1]+.05)
    span(east, 2, extent(rear,2)[0]-.05, extent(exit_right,2)[1]+.05)
    opening = by[2,'Lobby_To_Stage01_AboveOpening']
    opening['position'][2] = extent(exit_right,2)[0] + opening['size'][2]/2
    span(opening, 0, extent(exit_left,0)[1]-.1, extent(exit_right,0)[0]+.1)

    for name, wall, sign, end in (
        ('Lobby_EastExit_Junction', east, 1, exit_right),
        ('Stage10_EndLeft_Junction', by[2,'Stage01_10_LeftWall'], -1, by[2,'Stage10_EndWall']),
        ('Stage10_EndRight_Junction', by[2,'Stage01_10_RightWall'], 1, by[2,'Stage10_EndWall'])):
        row = by[2,name]
        inside = extent(wall,0)[0 if sign == 1 else 1]
        row['position'][0] = inside + sign*row['size'][0]/2
        row['position'][2] = extent(end,2)[0]
        row['edgeAxis'], row['outwardSign'] = 0, sign
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    raw = PLACE.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == EXPECTED, 'Unexpected edit: inspect before writing'
    spec = json.loads((ROOT/'reports/WallExtensions_20261021/Placement.json').read_text())
    rows = plan(spec)
    e = Editor(raw)
    e.path = functools.lru_cache(None)(e.path)
    paths = {e.path(ref): ref for ref in e.parents}
    changes, touched = [], set()
    for old, new in zip(spec['parts'], rows):
        path = spec['folders'][str(old['world'])] + '.' + old['name']
        ref = paths[path]
        cf, size = e.get(ref,'CFrame'), e.get(ref,'size')
        assert all(abs(a-b)<.001 for a,b in zip(unvector(cf[1]),old['position'])), path
        assert all(abs(a-b)<.001 for a,b in zip(unvector(size),old['size'])), path
        assert new['position'][1] == old['position'][1] and new['size'][1] == old['size'][1]
        e.set(ref,'CFrame',(cf[0],vector(*new['position'])))
        e.set(ref,'size',vector(*new['size']))
        touched.add(ref)
        changes.append({'path':path,'beforePosition':old['position'],'afterPosition':new['position'],
                        'beforeSize':old['size'],'afterSize':new['size']})
    result, _ = e.build()
    # File-edit integrity only: these two Part property chunks are the sole changed chunks.
    before, after = Editor(raw), Editor(result)
    changed_chunks = {e.columns[key][0] for key in e.changed}
    assert len(changed_chunks) == 2 and before.parents == after.parents
    for index,(a,b) in enumerate(zip(before.doc.chunks,after.doc.chunks)):
        assert a[0] == b[0]
        if index not in changed_chunks:
            assert a[1] == b[1], (index,a[0])
    for cid,name in e.changed:
        assert name in ('CFrame','size')
        for ref,value in before.col(cid,name)[3].items():
            assert after.get(ref,name) == (e.get(ref,name) if ref in touched else value)
    Document(result).assert_studio_bounds()
    record = {'inputSha256':EXPECTED,'outputSha256':hashlib.sha256(result).hexdigest(),
              'world1Parts':54,'world2Parts':21,'changedProperties':['CFrame','size'],
              'unchangedHeightAndFlags':True,'allOtherChunksByteIdentical':True,
              'noInstancesAddedRemovedOrReparented':True,'uniqueIdsUnchanged':True,
              'runtimeAndVisualTesting':'Not performed; user will verify','written':False,
              'changes':changes}
    if args.write:
        assert PLACE.read_bytes() == raw, 'Target changed during edit'
        with PLACE.open('r+b') as stream:
            stream.write(result);stream.truncate();stream.flush();os.fsync(stream.fileno())
        assert PLACE.read_bytes() == result
        record['written'] = True
        REPORT.mkdir(exist_ok=True)
        (REPORT/'Writeback.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf8')
    print(json.dumps({k:v for k,v in record.items() if k != 'changes'},indent=2))


if __name__ == '__main__':
    main()
