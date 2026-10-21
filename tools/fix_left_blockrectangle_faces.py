"""Recess only measured coplanar Bottom end faces in World1's left cliff blocks."""
import collections
import functools
import hashlib
import json
import os
from pathlib import Path

from rbxl_geometry import matrix
from rbxl_rows import Editor, unvector, vector

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
EXPECTED = '89ca93ff0a0bdd4d6afab4f9840cfb70ee7909f7145514580509c17d477b1323'
RECESS = 0.02


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def geometry(edit, ref):
    assert edit.doc.classes[edit.class_of[ref]][0] == 'Part'
    assert int.from_bytes(edit.get(ref, 'shape'), 'big') == 1
    rotation, position = edit.get(ref, 'CFrame')
    m = matrix(rotation)
    return dict(ref=ref, position=unvector(position), size=unvector(edit.get(ref, 'size')),
                basis=[[m[row * 3 + axis] for row in range(3)] for axis in range(3)])


def competing_faces(bottom, upper):
    # Measure in each actual Bottom's frame, never apply a fixed world-space offset.
    delta = [a - b for a, b in zip(upper['position'], bottom['position'])]
    center = [dot(delta, axis) for axis in bottom['basis']]
    half = [sum(abs(dot(axis, other)) * size / 2
                for other, size in zip(upper['basis'], upper['size'])) for axis in bottom['basis']]
    assert all(sum(abs(dot(a, b)) > .999999 for b in upper['basis']) == 1 for a in bottom['basis'])
    faces = []
    for axis in (0, 2):  # Vertical end faces only, not top-only decoration overlaps.
        other = [i for i in range(3) if i != axis]
        overlap = [min(bottom['size'][i] / 2, center[i] + half[i]) -
                   max(-bottom['size'][i] / 2, center[i] - half[i]) for i in other]
        for sign in (-1, 1):
            if abs(sign * bottom['size'][axis] / 2 - center[axis] - sign * half[axis]) < .0005 \
                    and min(overlap) > .001:
                faces.append(dict(axis=axis, sign=sign, overlap=overlap))
    return faces


def main():
    raw = PLACE.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == EXPECTED, 'Current file changed; inspect before writing'
    edit = Editor(raw)
    edit.path = functools.lru_cache(None)(edit.path)
    children = collections.defaultdict(list)
    for ref, parent in edit.parents.items():
        children[parent].append(ref)
    markers = [edit.path(r) for r, name in edit.names.items() if name == 'BlockRectanglex']
    changes = []
    for stage in range(1, 11):
        prefix = f'Workspace.GeneratedMap.BattleCorridor.Stage{stage:02}.Boundaries.Environment_LeftSide.Cliff01.'
        matches = []
        for model in edit.parents:
            if not edit.path(model).startswith(prefix) or edit.names[model] not in ('BlockRectangle', 'BlockRectanglex'):
                continue
            parts = {edit.names[r]: r for r in children[model]}
            if not {'Bottom', 'Upper'} <= parts.keys():
                continue
            assert not any(edit.doc.classes[edit.class_of[c]][0].endswith('Mesh')
                           for name in ('Bottom', 'Upper') for c in children[parts[name]])
            bottom, upper = (geometry(edit, parts[name]) for name in ('Bottom', 'Upper'))
            faces = competing_faces(bottom, upper)
            if faces:
                matches.append((model, bottom, upper, faces))
        assert len(matches) == 1, f'Ambiguous corresponding block in Stage{stage:02}'
        model, bottom, upper, faces = matches[0]
        assert len(faces) == 1
        # Corresponding short rectangular tier; the larger adjacent rectangle is excluded.
        assert abs(bottom['size'][1] - 26) < .001 and abs(upper['size'][1] - 3.75) < .001
        assert abs(upper['position'][1] - bottom['position'][1] - 14.5) < .001
        assert abs(upper['size'][0] - bottom['size'][0] - 1) < .001
        face = faces[0]
        axis, sign = face['axis'], face['sign']
        normal = [sign * v for v in bottom['basis'][axis]]
        position = [p - n * RECESS / 2 for p, n in zip(bottom['position'], normal)]
        size = bottom['size'][:]
        size[axis] -= RECESS
        ref = bottom['ref']
        edit.set(ref, 'CFrame', (edit.get(ref, 'CFrame')[0], vector(*position)))
        edit.set(ref, 'size', vector(*size))
        after = geometry(edit, ref)
        assert not competing_faces(after, upper)
        # Keep the opposite end fixed to float precision and the existing vertical overlap.
        old_opposite = dot(bottom['position'], normal) - bottom['size'][axis] / 2
        new_opposite = dot(after['position'], normal) - after['size'][axis] / 2
        assert abs(new_opposite - old_opposite) < .0002
        assert abs(face['overlap'][0] - .375) < .001
        changes.append(dict(stage=stage, modelRef=model, ref=ref, path=edit.path(ref),
                            upperRef=upper['ref'], upperPath=edit.path(upper['ref']),
                            beforePosition=bottom['position'], afterPosition=after['position'],
                            beforeSize=bottom['size'], afterSize=after['size'],
                            localAxis=axis, localSign=sign, worldFaceNormal=normal,
                            recess=RECESS, originalFaceOverlap=face['overlap']))
    result, _ = edit.build()
    before, after = Editor(raw), Editor(result)
    allowed = {(c['ref'], name) for c in changes for name in ('CFrame', 'size')}
    assert before.parents == after.parents and before.classes == after.classes
    for key, column in before.columns.items():
        if key not in edit.changed:
            assert before.doc.chunks[column[0]][1] == after.doc.chunks[after.columns[key][0]][1]
        else:
            cid, name = key
            for ref, value in before.col(cid, name)[3].items():
                assert after.get(ref, name) == (edit.get(ref, name) if (ref, name) in allowed else value)
    assert not Path(str(PLACE) + '.lock').exists(), 'User Studio lock exists; do not overwrite concurrently'
    assert PLACE.read_bytes() == raw, 'Concurrent edit; refusing overwrite'
    with PLACE.open('r+b') as stream:
        stream.write(result)
        stream.truncate()
        stream.flush()
        os.fsync(stream.fileno())
    saved = PLACE.read_bytes()
    assert saved == result
    reread = Editor(saved)
    for ref, name in allowed:
        assert reread.get(ref, name) == edit.get(ref, name)
    report = dict(inputSha256=EXPECTED, outputSha256=hashlib.sha256(saved).hexdigest(),
                  markerPaths=markers, markerAbsentUserAuthorizedGeometryMatching=True,
                  changes=changes, stages=10, changedParts=len(changes),
                  allOtherPropertiesHierarchySourcesAndNamesPreserved=True,
                  writtenAndReread=True, studioOpened=False, playTested=False, appearanceVerified=False)
    out = ROOT / 'reports/LeftBlockRectangleFaces_20261022'
    out.mkdir(exist_ok=True)
    (out / 'Writeback.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: report[k] for k in ('stages', 'changedParts', 'outputSha256', 'writtenAndReread')}))


if __name__ == '__main__':
    main()
