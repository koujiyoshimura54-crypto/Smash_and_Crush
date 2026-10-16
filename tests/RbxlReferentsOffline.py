"""Regression for the sparse-ID failure in 8fa05f6. No Studio or file mutation."""
from pathlib import Path
import struct
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from rbxl_referents import Document, canonicalize, read_refs, write_refs


def string(value):
    return struct.pack('<I', len(value)) + value


def chunk(kind, data):
    return struct.pack('<4sIII', kind, 0, len(data), 0) + data


def fixture(ids=(0, 2, 5, 8), parent=None, linked=None, count=4, content=True):
    # One root, one child model, two parts, plus explicit property references.
    parent = [-1, ids[0], ids[1], ids[1]] if parent is None else parent
    linked = [-1, ids[-1], ids[0], ids[2]] if linked is None else linked
    header = b'<roblox!\x89\xff\r\n\x1a\n\0\0' + struct.pack('<II', 1, count) + bytes(8)
    inst = struct.pack('<I', 0) + string(b'Model') + b'\0' + struct.pack('<I', len(ids)) + write_refs(ids)
    prop = lambda name, typ, payload: chunk(b'PROP', struct.pack('<I', 0) + string(name) + bytes([typ]) + payload)
    names = b''.join(string(s) for s in [b'Root', b'Child', b'PartA', b'PartB'])
    # Interleaved unique 16-byte rows; deliberately independent from referents.
    unique = bytes(row[j] for j in range(16) for row in [bytes([i]) * 16 for i in range(1, 5)])
    data = [header, chunk(b'INST', inst), prop(b'Name', 1, names),
            prop(b'UniqueId', 31, unique), prop(b'PrimaryPart', 19, write_refs(linked))]
    if content:
        # Types None/None/None/Object, zero URIs, one object, no externals.
        types = bytes(12) + b'\0\0\0\4'
        value = types + struct.pack('<II', 0, 1) + write_refs([ids[-1]]) + bytes(4)
        data.append(prop(b'Content', 34, value))
    data += [chunk(b'PRNT', b'\0' + struct.pack('<I', 4) + write_refs(ids) + write_refs(parent)), chunk(b'END\0', b'</roblox>')]
    return b''.join(data)


class ReferentTests(unittest.TestCase):
    def test_user_failure_is_rejected_by_bounds(self):
        doc = Document(fixture())
        self.assertEqual(doc.count, 4)
        self.assertEqual(doc.summary()['outOfBoundsCount'], 2)
        with self.assertRaisesRegex(AssertionError, '0..instanceCount'):
            doc.assert_studio_bounds()

    def test_fill_holes_preserves_rows_properties_and_graph(self):
        raw = fixture(); repaired, report = canonicalize(raw); after = Document(repaired)
        self.assertEqual(after.classes[0][1], [0, 2, 1, 3])
        self.assertEqual(after.parent_pairs, [(0, -1), (2, 0), (1, 2), (3, 2)])
        self.assertEqual(next(v for *_, v, label in after.reference_regions if label == 'PROP.Ref'), [-1, 3, 0, 1])
        self.assertEqual(next(v for *_, v, label in after.reference_regions if label == 'PROP.Content'), [3])
        self.assertEqual(Document(raw).chunks[2][2], after.chunks[2][2])
        self.assertEqual(Document(raw).unique_ids, after.unique_ids)
        self.assertEqual(report['renumberedInstances'], 2)

    def test_dense_file_is_byte_identical(self):
        repaired, _ = canonicalize(fixture())
        self.assertEqual(canonicalize(repaired)[0], repaired)

    def test_duplicate_instance_ids_refused(self):
        with self.assertRaisesRegex(AssertionError, 'Duplicate'):
            canonicalize(fixture(ids=(0, 2, 5, 5)))

    def test_missing_data_is_not_guessed(self):
        with self.assertRaisesRegex(AssertionError, 'count mismatch'):
            canonicalize(fixture(count=6))
        with self.assertRaisesRegex(AssertionError, 'Dangling'):
            canonicalize(fixture(linked=[-1, 99, 0, 5]))

    def test_parent_cycle_is_not_repaired_by_deleting(self):
        with self.assertRaisesRegex(AssertionError, 'Parent cycle'):
            canonicalize(fixture(parent=[2, 0, 2, 2]))

    def test_negative_null_and_large_delta(self):
        values = [179491, -1, 0, 179483, 3, -1]
        self.assertEqual(read_refs(write_refs(values), len(values)), values)


if __name__ == '__main__':
    unittest.main()
