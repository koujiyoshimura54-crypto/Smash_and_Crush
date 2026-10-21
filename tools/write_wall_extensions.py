"""Add the reviewed, saved vertical wall extensions without changing existing rows."""
import argparse
import functools
import hashlib
import json
import os
from pathlib import Path
from rbxl_rows import Editor, s, f, i, vector, unvector, unf
from rbxl_referents import Document, canonicalize

ROOT = Path(__file__).resolve().parents[1]
PLACE = Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
REPORT = ROOT / 'reports/WallExtensions_20261021'


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def apply(raw, spec):
    before, e = Editor(raw), Editor(raw)
    e.path = functools.lru_cache(None)(e.path)
    paths = {e.path(ref): ref for ref in e.parents}
    # A subsequent invocation is a no-op only when the previous written hash matches.
    previous = REPORT / 'FileValidation.json'
    if all(path in paths for path in spec['folders'].values()):
        assert previous.exists() and digest(raw) == json.loads(previous.read_text())['outputSha256']
        return raw, {'alreadyApplied': True, 'outputSha256': digest(raw)}
    assert digest(raw) == spec['inputSha256'], 'Unexpected local edit; inspect before writing'
    assert not any(path in paths for path in spec['folders'].values()), 'Partial existing extensions'
    assert e.strings()[0][1] == b''
    folders = {}
    for world, path in spec['folders'].items():
        parent, name = path.rsplit('.', 1)
        ref, _ = e.clone(paths['Workspace.ShoesModels'], paths[parent], recursive=False)
        e.set(ref, 'Name', s(name))
        e.set(ref, 'Tags', bytes(4))
        folders[int(world)] = ref
    donor = paths['Workspace.GeneratedMap.TrainingArea.Floor']
    added = []
    for row in spec['parts']:
        ref, _ = e.clone(donor, folders[row['world']], recursive=False)
        props = {'Name': s(row['name']), 'size': vector(*row['size']),
                 'CFrame': (b'\x02', vector(*row['position'])),
                 'PivotOffset': (b'\x02', vector(0, 0, 0)),
                 'Anchored': b'\x01', 'CanCollide': b'\x01', 'CanQuery': b'\x01',
                 'CanTouch': b'\x00', 'CastShadow': b'\x00', 'Transparency': f(1),
                 'CollisionGroup': s('Default'), 'CollisionGroupId': i(0),
                 'Color3uint8': bytes([163, 162, 165]), 'Tags': bytes(4),
                 'Material': (272).to_bytes(4, 'big'), 'MaterialVariantSerialized': s(''),
                 'CustomPhysicalProperties': b'\x00', 'Reflectance': f(0),
                 'Velocity': vector(0, 0, 0), 'RotVelocity': vector(0, 0, 0),
                 'Massless': b'\x00'}
        for side in ('Top', 'Bottom', 'Left', 'Right', 'Front', 'Back'):
            props[side + 'Surface'] = bytes(4)
        for key, value in props.items():
            e.set(ref, key, value)
        added.append((ref, row))
    result, repair = e.build()
    after = Editor(result)
    assert not e.removed and not e.final_mapping
    assert after.parents == e.parents
    verified = 0
    for ref, parent in before.parents.items():
        assert after.parents[ref] == parent
    for key, column in before.columns.items():
        cid, name = key
        if key not in e.changed:
            assert before.doc.chunks[column[0]][1] == after.doc.chunks[after.columns[key][0]][1]
            verified += len(before.classes[cid])
        else:
            for ref, old in before.col(cid, name)[3].items():
                assert after.col(cid, name)[3][ref] == old, (ref, name, 'Existing property changed')
                verified += 1
    for ref, row in added:
        assert all(abs(a-b) < .001 for a,b in zip(unvector(after.get(ref, 'size')), row['size']))
        assert all(abs(a-b) < .001 for a,b in zip(unvector(after.get(ref, 'CFrame')[1]), row['position']))
        assert unf(after.get(ref, 'Transparency')) == 1
        for key in ('Anchored', 'CanCollide', 'CanQuery'):
            assert after.get(ref, key) == b'\x01'
        for key in ('CanTouch', 'CastShadow'):
            assert after.get(ref, key) == b'\x00'
        assert after.get(ref, 'CollisionGroup') == s('Default')
    assert canonicalize(result)[0] == result
    Document(result).assert_studio_bounds()
    return result, {'inputSha256': digest(raw), 'outputSha256': digest(result),
                    'world1Parts': 54, 'world2Parts': 21, 'addedFolders': spec['folders'],
                    'topWorldY': 160, 'allExistingSourcesPropertiesParentsPreserved': True,
                    'verifiedExistingProperties': verified, 'binaryValidation': repair,
                    'allNewPartsTransparentAndCollidable': True, 'written': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    spec = json.loads((REPORT / 'Placement.json').read_text(encoding='utf8'))
    raw = PLACE.read_bytes()
    result, report = apply(raw, spec)
    if args.write and not report.get('alreadyApplied'):
        assert not Path(str(PLACE) + '.lock').exists(), 'Target is open'
        assert PLACE.read_bytes() == raw, 'Target changed during preparation'
        with PLACE.open('r+b') as stream:
            stream.write(result)
            stream.truncate()
            stream.flush()
            os.fsync(stream.fileno())
        assert PLACE.read_bytes() == result
        Document(PLACE.read_bytes()).assert_studio_bounds()
        report['written'] = True
        (REPORT / 'FileValidation.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf8')
    print(json.dumps({k:v for k,v in report.items() if k != 'binaryValidation'}, indent=2))


if __name__ == '__main__':
    main()
