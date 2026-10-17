"""Independent format/geometry regressions for purchased visual imports; memory only."""
from pathlib import Path
import struct
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from rbxl_rows import decode,encode,s,i,interleave
from rbxl_referents import write_refs
from rbxl_geometry import matrix,yaw,point
from world2_lobby_facilities import union_tiles


class VisualRows(unittest.TestCase):
    def test_content_types_are_signed_transformed(self):
        raw=(b'\0'*12+b'\0\2\4\2'+struct.pack('<I',2)+s('one')+s('two')+
             struct.pack('<I',1)+write_refs([42])+bytes(4))
        rows=[(0,None),(1,s('one')),(2,42),(1,s('two'))]
        self.assertEqual(decode(raw,34,4),rows)
        self.assertEqual(encode(rows,34),raw)

    def test_content_object_stack_order(self):
        raw=interleave([i(2),i(2)])+bytes(4)+struct.pack('<I',2)+write_refs([7,42])+bytes(4)
        self.assertEqual(decode(raw,34,2),[(2,42),(2,7)])
        self.assertEqual(encode(decode(raw,34,2),34),raw)

    def test_actual_saved_cardinal_basis(self):
        self.assertEqual(matrix(b'\2'),[1,0,0,0,1,0,0,0,1])
        self.assertEqual(matrix(bytes([14])),[0,0,-1,0,1,0,1,0,0])
        self.assertEqual(point(yaw(-90),[1,0,0]),[0,0,1])

    def test_carpet_cross_has_no_coplanar_duplicate_rectangles(self):
        rectangles=[(-8,8,-2,2),(-2,2,-8,8)]
        tiles=union_tiles(rectangles)
        self.assertEqual(sum((b-a)*(d-c)for a,b,c,d in tiles),112)
        for j,(a,b,c,d)in enumerate(tiles):
            for e,f,g,h in tiles[j+1:]:
                self.assertFalse(min(b,f)>max(a,e)and min(d,h)>max(c,g))


if __name__=='__main__':unittest.main()
