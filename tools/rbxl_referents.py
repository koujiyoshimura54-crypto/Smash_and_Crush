"""Validate/canonicalize binary instance referents without editing any Instances.

Python 3.14 (compression.zstd). Read-only by default. --write repairs only the
specified existing file after a complete in-memory validation. No backup/place
copy is created. Native Studio EditFile loading is still a required separate check.
"""
from __future__ import annotations

import argparse
from collections import Counter
from compression import zstd
import hashlib
import json
import os
from pathlib import Path
import struct


def u32(data, offset=0):
    return struct.unpack_from('<I', data, offset)[0]


def string(data, offset):
    size = u32(data, offset)
    end = offset + 4 + size
    assert end <= len(data), 'Truncated string'
    return data[offset + 4:end], end


def read_refs(data, count):
    assert len(data) == 4 * count, 'Truncated referents'
    values, previous = [], 0
    for i in range(count):
        value = int.from_bytes(bytes(data[i + j * count] for j in range(4)), 'big')
        previous += (value >> 1) ^ -(value & 1)
        values.append(previous)
    return values


def write_refs(values):
    rows, previous = [], 0
    for value in values:
        delta = value - previous
        assert -(1 << 31) <= delta < (1 << 31)
        rows.append(((delta << 1) ^ (delta >> 31)).to_bytes(4, 'big'))
        previous = value
    return bytes(row[j] for j in range(4) for row in rows)


def lz4(data):
    result = bytearray()
    pos = 0
    def length(initial):
        nonlocal pos
        total = initial
        if initial == 15:
            while True:
                value = data[pos]; pos += 1; total += value
                if value != 255:
                    break
        return total
    while pos < len(data):
        token = data[pos]; pos += 1
        count = length(token >> 4)
        assert pos + count <= len(data)
        result.extend(data[pos:pos + count]); pos += count
        if pos == len(data):
            break
        distance = int.from_bytes(data[pos:pos + 2], 'little'); pos += 2
        assert 0 < distance <= len(result)
        count = length(token & 15) + 4
        for _ in range(count):
            result.append(result[-distance])
    return bytes(result)


class Document:
    def __init__(self, raw):
        assert raw[:14] == b'<roblox!\x89\xff\r\n\x1a\n' and raw[14:16] == b'\0\0'
        self.raw = raw
        self.count = u32(raw, 20)
        self.chunks, self.classes, self.ids, self.reference_regions = [], {}, set(), []
        self.parent_pairs = []
        self.unique_ids = []
        pos = 32
        while pos < len(raw):
            kind, compressed, size, reserved = struct.unpack_from('<4sIII', raw, pos)
            end = pos + 16 + (compressed or size)
            assert end <= len(raw), 'Truncated chunk'
            payload = raw[pos + 16:end]
            data = (zstd.decompress(payload) if payload[:4] == b'\x28\xb5\x2f\xfd'
                    else lz4(payload)) if compressed else payload
            assert len(data) == size
            self.chunks.append((kind, data, raw[pos:end], reserved))
            pos = end
        assert self.chunks[-1][0] == b'END\0', 'Missing END'
        for ci, (kind, data, _, _) in enumerate(self.chunks):
            if kind != b'INST':
                continue
            cid = u32(data); name, p = string(data, 4)
            assert cid not in self.classes, 'Duplicate class ID'
            form, count = data[p], u32(data, p + 1)
            start = p + 5; end = start + 4 * count
            assert form in (0, 1) and len(data) == end + (count if form else 0)
            values = read_refs(data[start:end], count)
            assert all(v >= 0 for v in values) and len(set(values)) == count, 'Duplicate/negative instance ID'
            assert not self.ids.intersection(values), 'Duplicate instance ID across classes'
            self.ids.update(values)
            self.classes[cid] = (name.decode(), values)
            self.reference_regions.append((ci, start, end, values, 'INST'))
        assert len(self.classes) == u32(raw, 16), 'Class count mismatch'
        assert len(self.ids) == self.count, 'Header/INST count mismatch'
        properties = set()
        parents_seen = False
        for ci, (kind, data, _, _) in enumerate(self.chunks):
            if kind == b'PROP':
                cid = u32(data); name, p = string(data, 4)
                assert cid in self.classes and (cid, name) not in properties
                properties.add((cid, name))
                typ = data[p]; p += 1; count = len(self.classes[cid][1])
                if typ == 19:
                    values = read_refs(data[p:], count)
                    self.reference_regions.append((ci, p, len(data), values, 'PROP.Ref'))
                elif typ == 34:
                    # Content: type column, URI strings, object refs, external refs.
                    p += 4 * count
                    uri_count = u32(data, p); p += 4
                    for _ in range(uri_count):
                        _, p = string(data, p)
                    object_count = u32(data, p); p += 4
                    end = p + 4 * object_count
                    values = read_refs(data[p:end], object_count)
                    self.reference_regions.append((ci, p, end, values, 'PROP.Content'))
                    p = end
                    external_count = u32(data, p); p += 4
                    assert external_count == 0 and p == len(data), 'Unsupported external Content refs'
                elif typ == 35:
                    # Fail closed on anything beyond this observed empty Terrain map.
                    assert self.classes[cid][0] == 'Terrain' and name == b'VoxelGridAssetContentMap'
                    assert count == 1 and data[p:] == b'\x02' + bytes(8), 'Nonempty ContentMap unsupported'
                else:
                    assert 1 <= typ <= 33, ('Unknown property type; refuse remapping', typ)
                if name == b'UniqueId':
                    assert typ == 31 and len(data) - p == 16 * count
                    self.unique_ids.extend(bytes(data[p + i + j * count] for j in range(16)) for i in range(count))
            elif kind == b'PRNT':
                assert not parents_seen and data[0] == 0
                parents_seen = True
                count = u32(data, 1)
                assert count == self.count and len(data) == 5 + 8 * count
                split = 5 + 4 * count
                children = read_refs(data[5:split], count)
                parents = read_refs(data[split:], count)
                assert len(set(children)) == count and set(children) == self.ids, 'PRNT coverage mismatch'
                self.parent_pairs = list(zip(children, parents))
                self.reference_regions += [(ci, 5, split, children, 'PRNT.Child'), (ci, split, len(data), parents, 'PRNT.Parent')]
            else:
                assert kind in (b'INST', b'META', b'SSTR', b'SIGN', b'END\0'), ('Unknown chunk', kind)
        assert parents_seen
        for _, _, _, values, label in self.reference_regions:
            assert all(v in self.ids or v == -1 and label != 'INST' for v in values), ('Dangling ref', label)
        parent_map = dict(self.parent_pairs)
        done = set()
        for child in parent_map:
            active = set(); current = child
            while current != -1 and current not in done:
                assert current not in active, 'Parent cycle'
                active.add(current); current = parent_map[current]
            done.update(active)
        assert len(self.unique_ids) == len(set(self.unique_ids)), 'Duplicate UniqueId'

    def assert_studio_bounds(self):
        assert self.ids == set(range(self.count)), 'INST IDs must cover 0..instanceCount-1 for Studio'
        for _, _, _, values, label in self.reference_regions:
            assert all(0 <= v < self.count or v == -1 and label != 'INST' for v in values), label

    def summary(self):
        bad = sorted(v for v in self.ids if v >= self.count)
        counts = Counter()
        for _, _, _, values, label in self.reference_regions:
            counts[label] += len(values)
        return dict(sha256=hashlib.sha256(self.raw).hexdigest(), instanceCount=self.count,
                    classCount=len(self.classes), minimumId=min(self.ids), maximumId=max(self.ids),
                    outOfBoundsCount=len(bad), missingInRangeCount=len(set(range(self.count)) - self.ids),
                    duplicateUniqueIds=0, referenceValuesByKind=dict(counts))


def canonicalize(raw):
    before = Document(raw)
    # Preserve every already-valid number; fill deleted holes with out-of-range IDs.
    holes = sorted(set(range(before.count)) - before.ids)
    outside = sorted(v for v in before.ids if v >= before.count)
    assert len(holes) == len(outside)
    mapping = dict(zip(outside, holes))
    mapped = lambda v: mapping.get(v, v)
    replacements = {}
    for ci, start, end, values, _ in before.reference_regions:
        encoded = write_refs([mapped(v) for v in values])
        if encoded != before.chunks[ci][1][start:end]:
            replacements.setdefault(ci, []).append((start, end, encoded))
    chunks = []
    for ci, (kind, data, encoded, reserved) in enumerate(before.chunks):
        if ci in replacements:
            for start, end, value in sorted(replacements[ci], reverse=True):
                data = data[:start] + value + data[end:]
            payload = zstd.compress(data)
            encoded = struct.pack('<4sIII', kind, len(payload), len(data), reserved) + payload
        chunks.append(encoded)
    result = raw[:32] + b''.join(chunks)
    after = Document(result)
    after.assert_studio_bounds()
    # Same rows in each class means every untouched property remains on its owner.
    assert after.raw[:32] == before.raw[:32]
    for cid, (name, values) in before.classes.items():
        assert after.classes[cid] == (name, [mapped(v) for v in values])
    assert after.parent_pairs == [(mapped(a), mapped(b)) for a, b in before.parent_pairs]
    assert len(before.reference_regions) == len(after.reference_regions)
    for a, b in zip(before.reference_regions, after.reference_regions):
        assert a[:3] == b[:3] and a[4] == b[4] and [mapped(v) for v in a[3]] == b[3]
    for ci, old in enumerate(before.chunks):
        if ci not in replacements:
            assert after.chunks[ci][2] == old[2]
        else:
            # Mask just the reference-array bytes; every other byte must match.
            a, b = bytearray(old[1]), bytearray(after.chunks[ci][1])
            for start, end, _ in replacements[ci]:
                a[start:end] = b[start:end] = bytes(end - start)
            assert a == b, ('Non-reference bytes changed', ci)
    return result, dict(before=before.summary(), after=after.summary(), renumberedInstances=len(mapping),
                       modifiedChunks=len(replacements), preservedInstanceCount=True,
                       allNonReferenceBytesUnchanged=True, hierarchyAndReferenceTargetsPreserved=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('path', type=Path)
    parser.add_argument('--write', action='store_true')
    parser.add_argument('--expected-sha256')
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    raw = args.path.read_bytes()
    repaired, report = canonicalize(raw)
    if args.write:
        assert args.expected_sha256 and report['before']['sha256'] == args.expected_sha256, 'Unexpected current file'
        assert not Path(str(args.path) + '.lock').exists(), 'Studio lock exists; do not operate it'
        assert args.path.read_bytes() == raw, 'File changed while checking'
        with args.path.open('r+b') as handle:
            handle.write(repaired); handle.truncate(); handle.flush()
            os.fsync(handle.fileno())
        reread = args.path.read_bytes()
        assert reread == repaired
        Document(reread).assert_studio_bounds()
    report['writtenToSameFile'] = args.write
    report['nativeStudioVerification'] = 'Required separately; this tool does not claim Studio load success.'
    if args.report:
        args.report.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
