"""Lossless, fail-closed property-row editing for existing binary place classes.

Untouched chunks remain byte-identical. Supported columns must roundtrip before
editing. Final output always passes the repaired dense-referent validator.
Format reference: https://dom.rojo.space/binary.html
"""
import copy
import os
import struct
from rbxl_referents import Document, canonicalize, read_refs, write_refs, string, u32, zstd


def s(value):
    value = value.encode() if isinstance(value, str) else value
    return struct.pack('<I', len(value)) + value


def interleave(rows):
    return b''.join(bytes(row[j] for row in rows) for j in range(len(rows[0]))) if rows else b''


def uninterleave(data, n, width):
    assert len(data) == n * width
    return [bytes(data[i + j * n] for j in range(width)) for i in range(n)]


def f(value):
    bits = struct.unpack('<I', struct.pack('<f', value))[0]
    return ((bits << 1 & 0xffffffff) | (bits >> 31)).to_bytes(4, 'big')


def unf(data):
    bits = int.from_bytes(data, 'big')
    return struct.unpack('<f', ((bits >> 1) | (bits << 31 & 0xffffffff)).to_bytes(4, 'little'))[0]


def i(value):
    return ((value << 1) ^ (value >> 31)).to_bytes(4, 'big')


def uni(data):
    value = int.from_bytes(data, 'big')
    return (value >> 1) ^ -(value & 1)


def vector(*values):
    return b''.join(f(v) for v in values)


def unvector(data):
    return [unf(data[p:p + 4]) for p in range(0, len(data), 4)]


def udim2(x, xo, y, yo):
    return f(x) + f(y) + i(xo) + i(yo)


def decode(data, typ, n):
    if typ == 19:
        return read_refs(data, n)
    if typ in (3, 4, 11, 18, 28):
        return uninterleave(data, n, 4)
    if typ in (27, 33, 31):
        return uninterleave(data, n, 16 if typ == 31 else 8)
    if typ in (6, 7, 12, 13, 14, 24, 26):
        components = {6:2, 7:4, 12:3, 13:2, 14:3, 24:4, 26:3}[typ]
        width = 1 if typ == 26 else 4
        assert len(data) == n * width * components
        cols = [uninterleave(data[c*n*width:(c+1)*n*width], n, width) for c in range(components)]
        return [b''.join(col[r] for col in cols) for r in range(n)]
    if typ in (16, 30):
        p = 1 if typ == 30 else 0
        if typ == 30:
            assert data[0] == 16
        rotations = []
        for _ in range(n):
            size = 37 if data[p] == 0 else 1
            rotations.append(data[p:p+size]); p += size
        positions = decode(data[p:p+12*n], 14, n); p += 12*n
        if typ == 30:
            assert data[p] == 2 and len(data) == p + 1 + n
            return [(rotations[j], positions[j], data[p+1+j:p+2+j]) for j in range(n)]
        assert p == len(data)
        return list(zip(rotations, positions))
    rows, p = [], 0
    fixed = {2:1, 5:8, 9:1, 10:1, 20:6, 23:8}
    for _ in range(n):
        start = p
        if typ in (1, 29):
            _, p = string(data, p)
        elif typ in fixed:
            p += fixed[typ]
        elif typ in (21, 22):
            p += 4 + u32(data, p) * (12 if typ == 21 else 20)
        elif typ == 25:
            flags = data[p]; p += 1
            assert flags in (0, 1, 2, 3)
            if flags & 1:
                p += 24 if flags & 2 else 20
        elif typ == 32:
            _, p = string(data, p); p += 3; _, p = string(data, p)
        else:
            raise ValueError(('Unsupported property type for editing', typ))
        rows.append(data[start:p])
    assert p == len(data), (typ, n, p, len(data))
    return rows


def encode(rows, typ):
    if typ == 19:
        return write_refs(rows)
    if typ in (3, 4, 11, 18, 28, 27, 33, 31):
        return interleave(rows)
    if typ in (6, 7, 12, 13, 14, 24, 26):
        width = 1 if typ == 26 else 4
        return b''.join(interleave([r[p:p+width] for r in rows]) for p in range(0, len(rows[0]), width)) if rows else b''
    if typ in (16, 30):
        return ((b'\x10' if typ == 30 else b'') + b''.join(r[0] for r in rows)
                + encode([r[1] for r in rows], 14)
                + (b'\x02' + b''.join(r[2] for r in rows) if typ == 30 else b''))
    return b''.join(rows)


class Editor:
    def __init__(self, raw):
        self.doc = Document(raw)
        self.doc.assert_studio_bounds()
        self.classes = {cid:list(refs) for cid, (_, refs) in self.doc.classes.items()}
        self.class_of = {ref:cid for cid, refs in self.classes.items() for ref in refs}
        self.parents = dict(self.doc.parent_pairs)
        self.columns = {}
        self.changed = set()
        self.removed = set()
        self.next_ref = self.doc.count
        self.names = {}
        for ci, (kind, data, _, _) in enumerate(self.doc.chunks):
            if kind != b'PROP':
                continue
            cid = u32(data); name, p = string(data, 4)
            self.columns[cid, name.decode()] = [ci, data[p], p+1, None]
            if name == b'Name':
                self.names.update(zip(self.classes[cid], [string(v,0)[0].decode() for v in decode(data[p+1:], data[p], len(self.classes[cid]))]))

    def col(self, cid, name):
        col = self.columns[cid, name]
        if col[3] is None:
            data = self.doc.chunks[col[0]][1][col[2]:]
            rows = decode(data, col[1], len(self.doc.classes[cid][1]))
            assert encode(rows, col[1]) == data, ('Roundtrip failed', cid, name)
            col[3] = dict(zip(self.doc.classes[cid][1], rows))
        return col

    def get(self, ref, name):
        return self.col(self.class_of[ref], name)[3][ref]

    def set(self, ref, name, value):
        cid = self.class_of[ref]
        self.col(cid, name)[3][ref] = value
        self.changed.add((cid, name))
        if name == 'Name':
            self.names[ref] = string(value,0)[0].decode()

    def path(self, ref):
        return (self.path(self.parents[ref])+'.' if self.parents[ref] != -1 else '')+self.names[ref]

    def find(self, path):
        return next(ref for ref in self.parents if ref not in self.removed and self.path(ref) == path)

    def subtree(self, ref):
        children = {}
        for child, parent in self.parents.items():
            if child not in self.removed:
                children.setdefault(parent, []).append(child)
        result = []
        def walk(current):
            for child in children.get(current, []):
                walk(child)
            result.append(current)
        walk(ref)
        return result

    def remove(self, ref):
        self.removed.update(self.subtree(ref))

    def clone(self, ref, parent, recursive=True):
        original = self.subtree(ref) if recursive else [ref]
        mapping = {v:self.next_ref+j for j,v in enumerate(original)}
        self.next_ref += len(original)
        for old, new in mapping.items():
            cid = self.class_of[old]
            self.class_of[new] = cid
            self.classes[cid].append(new)
            self.parents[new] = parent if old == ref else mapping[self.parents[old]]
            self.names[new] = self.names[old]
            for (ccid, name) in self.columns:
                if ccid != cid:
                    continue
                col = self.col(cid, name)
                value = copy.deepcopy(col[3][old])
                if col[1] == 19:
                    value = mapping.get(value, value)
                if name in ('UniqueId', 'HistoryId'):
                    value = os.urandom(16)
                if name in ('AttributesSerialize', 'SerializedOverrides'):
                    value = s(b'')
                col[3][new] = value
                self.changed.add((cid, name))
        return mapping[ref], mapping

    def build(self):
        # Null references to removed exhibits, including references in other classes.
        for (cid, name), col in self.columns.items():
            if col[1] == 19:
                for ref, value in list(self.col(cid, name)[3].items()):
                    if ref not in self.removed and value in self.removed:
                        self.set(ref, name, -1)
        chunks = []
        alive = set(self.parents)-self.removed
        for kind, data, raw, reserved in self.doc.chunks:
            old = data
            if kind == b'INST':
                cid=u32(data); _, p=string(data,4); form=data[p]
                refs=[r for r in self.classes[cid] if r in alive]
                if refs != self.doc.classes[cid][1]:
                    assert form == 0
                    data=data[:p+1]+struct.pack('<I',len(refs))+write_refs(refs)
            elif kind == b'PROP':
                cid=u32(data); name,p=string(data,4); name=name.decode()
                refs=[r for r in self.classes[cid] if r in alive]
                if (cid,name) in self.changed or refs != self.doc.classes[cid][1]:
                    col=self.col(cid,name)
                    data=data[:p+1]+encode([col[3][r] for r in refs],col[1])
            elif kind == b'PRNT':
                # Preserve sibling order and parent children before their containers.
                children={}
                for child,parent in self.parents.items():
                    if child in alive:children.setdefault(parent,[]).append(child)
                order=[]
                def visit(ref):
                    for child in children.get(ref,[]):visit(child)
                    order.append(ref)
                for root in children[-1]:visit(root)
                data=b'\0'+struct.pack('<I',len(order))+write_refs(order)+write_refs([self.parents[r] for r in order])
            if data != old:
                payload=zstd.compress(data)
                raw=struct.pack('<4sIII',kind,len(payload),len(data),reserved)+payload
            chunks.append(raw)
        header=bytearray(self.doc.raw[:32]);struct.pack_into('<I',header,20,len(alive))
        self.final_mapping=dict(zip(sorted(r for r in alive if r>=len(alive)),sorted(set(range(len(alive)))-alive)))
        result, repair=canonicalize(bytes(header)+b''.join(chunks))
        Document(result).assert_studio_bounds()
        return result, repair
