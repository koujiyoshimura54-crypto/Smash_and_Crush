"""Separate measured end-face conflicts in the user-marked World1 wall structure."""
import collections
import functools
import hashlib
import itertools
import json
import os
from pathlib import Path
from rbxl_rows import Editor, unvector, vector
from rbxl_geometry import matrix

PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
ROOT = Path(__file__).resolve().parents[1]
BASELINE = 'de92471ed68a20b20beff0fc34aaf76e0053a1a0cd7b16985c65689d7bc298fa'


def main():
    raw = PLACE.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == BASELINE, 'File changed since marker inspection'
    e = Editor(raw)
    e.path = functools.lru_cache(None)(e.path)
    markers = [r for r in e.parents if e.names.get(r) == 'BlockSquareX']
    assert len(markers) == 1
    marker_path = e.path(markers[0])
    suffix = '.Boundaries.Environment_RightSide.Cliff01.BorderPattern.'
    assert marker_path == 'Workspace.GeneratedMap.BattleCorridor.Stage01' + suffix + 'BlockSquareX'
    children = collections.defaultdict(list)
    for r, parent in e.parents.items():
        children[parent].append(r)
    changes = []
    stages = []
    for stage in range(1, 11):
        prefix = f'Workspace.GeneratedMap.BattleCorridor.Stage{stage:02}' + suffix
        parts = []
        for r in e.parents:
            if not e.path(r).startswith(prefix) or e.doc.classes[e.class_of[r]][0] != 'Part':
                continue
            assert int.from_bytes(e.get(r, 'shape'), 'big') == 1
            assert not any(e.doc.classes[e.class_of[c]][0].endswith('Mesh') for c in children[r])
            rot, pos = e.get(r, 'CFrame')
            m = matrix(rot)
            assert m == [0, 0, 1, 0, 1, 0, -1, 0, 0]
            pos, size = unvector(pos), unvector(e.get(r, 'size'))
            half = [size[2]/2, size[1]/2, size[0]/2]
            parts.append(dict(ref=r, path=e.path(r), pos=pos, size=size,
                              lo=[a-b for a,b in zip(pos,half)], hi=[a+b for a,b in zip(pos,half)]))
        # The reported forward-facing vertical end faces, not AABB intersections.
        pairs = []
        for a, b in itertools.combinations(parts, 2):
            if abs(a['hi'][2] - b['hi'][2]) < .0005 and all(
                    min(a['hi'][k],b['hi'][k])-max(a['lo'][k],b['lo'][k]) > .001 for k in (0,1)):
                pairs.append((a,b))
        incident = {p['ref'] for pair in pairs for p in pair}
        bottoms = sorted((p for p in parts if p['ref'] in incident and p['path'].endswith('.Bottom')),
                         key=lambda p: (p['pos'][0],p['pos'][1]))
        assert len(bottoms) == 3, f'Unexpected corresponding structure in Stage{stage:02}'
        # Match relative structure, including the renamed middle tier, without copying dimensions.
        assert [p['pos'][1] for p in bottoms] == [1.,14.,22.5]
        assert abs(bottoms[1]['pos'][0]-bottoms[0]['pos'][0]-4) < .001
        assert abs(bottoms[2]['pos'][0]-bottoms[1]['pos'][0]-7) < .001
        for index, p in enumerate(bottoms, 1):
            amount = .02 * index
            pos, size = p['pos'][:], p['size'][:]
            # Recess only the competing +Z face. Opposite end, X and Y stay fixed.
            pos[2] -= amount/2
            size[0] -= amount
            ref = p['ref']
            e.set(ref, 'CFrame', (e.get(ref, 'CFrame')[0], vector(*pos)))
            e.set(ref, 'size', vector(*size))
            changes.append(dict(stage=stage, ref=ref, path=p['path'], beforePosition=p['pos'],
                                beforeSize=p['size'], afterPosition=unvector(e.get(ref,'CFrame')[1]),
                                afterSize=unvector(e.get(ref,'size')), recessedPositiveZ=amount,
                                competingParts=[q['ref'] for a,b in pairs for q in ([b] if a is p else [a] if b is p else [])]))
        stages.append(dict(stage=stage, measuredCoplanarPairs=len(pairs), changedParts=len(bottoms)))
    result, _ = e.build()
    before, after = Editor(raw), Editor(result)
    changed_refs = {p['ref'] for p in changes}
    assert before.parents == after.parents
    for key, col in before.columns.items():
        if key not in e.changed:
            assert before.doc.chunks[col[0]][1] == after.doc.chunks[after.columns[key][0]][1]
        else:
            cid, name = key
            assert name in ('CFrame','size')
            for ref, value in before.col(cid,name)[3].items():
                assert after.get(ref,name) == (e.get(ref,name) if ref in changed_refs else value)
    assert PLACE.read_bytes() == raw, 'Concurrent file edit; refusing overwrite'
    with PLACE.open('r+b') as stream:
        stream.write(result)
        stream.truncate()
        stream.flush()
        os.fsync(stream.fileno())
    assert PLACE.read_bytes() == result
    record = dict(world=1, markerPath=marker_path, inputSha256=BASELINE,
                  outputSha256=hashlib.sha256(result).hexdigest(), stages=stages, changes=changes,
                  writtenAndReread=True, unrelatedPropertiesAndSourcesPreserved=True,
                  playTested=False, appearanceVerified=False, studioOpened=False)
    out = ROOT/'reports/MarkedStageWallFaces_20261021'
    out.mkdir(exist_ok=True)
    (out/'Writeback.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(dict(stages=stages, outputSha256=record['outputSha256'], writtenAndReread=True)))


if __name__ == '__main__':
    main()
