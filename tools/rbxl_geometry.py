"""Geometry helpers for measured, rigid transforms of authored facilities."""
import math
import struct
from rbxl_rows import vector, unvector, unf

BASE_PARTS = {'Part','MeshPart','UnionOperation','WedgePart','CornerWedgePart',
              'SpawnLocation','Seat','VehicleSeat','TrussPart'}


def matrix(rotation):
    if rotation[0] == 0:
        return list(struct.unpack('<9f', rotation[1:]))
    axes = [(1,0,0),(0,1,0),(0,0,1),(-1,0,0),(0,-1,0),(0,0,-1)]
    a,b = divmod(rotation[0]-1,6)
    right,up = axes[a],axes[b]
    back = (right[1]*up[2]-right[2]*up[1],right[2]*up[0]-right[0]*up[2],right[0]*up[1]-right[1]*up[0])
    assert sum(v*v for v in back)==1
    return [axis[row] for row in range(3) for axis in (right,up,back)]


def multiply(a,b):
    return [sum(a[row*3+k]*b[k*3+col] for k in range(3)) for row in range(3) for col in range(3)]


def point(m,p):
    return [sum(m[row*3+k]*p[k] for k in range(3)) for row in range(3)]


def yaw(degrees):
    angle=math.radians(degrees);c,s=round(math.cos(angle),12),round(math.sin(angle),12)
    return [c,0,s,0,1,0,-s,0,c]


def part_refs(editor,refs):
    return [r for r in refs if editor.doc.classes[editor.class_of[r]][0] in BASE_PARTS and r not in editor.removed]


def bounds(editor,refs,visible=False):
    low=[math.inf]*3;high=[-math.inf]*3
    parts=[]
    for ref in part_refs(editor,refs):
        cid=editor.class_of[ref]
        if visible and unf(editor.get(ref,'Transparency'))>=.99:continue
        rot,pos=editor.get(ref,'CFrame');pos=unvector(pos);m=matrix(rot);size=unvector(editor.get(ref,'size'))
        half=[sum(abs(m[j*3+k])*size[k]/2 for k in range(3))for j in range(3)]
        low=[min(a,b-h)for a,b,h in zip(low,pos,half)]
        high=[max(a,b+h)for a,b,h in zip(high,pos,half)]
        parts.append(ref)
    assert parts,'No measurable Parts'
    return dict(min=low,max=high,size=[b-a for a,b in zip(low,high)],center=[(a+b)/2 for a,b in zip(low,high)],parts=len(parts))


def transform(editor,refs,rotation,source,target):
    def cf(value):
        old_rot,old_pos,*tail=value
        p=point(rotation,[a-b for a,b in zip(unvector(old_pos),source)])
        result=(b'\0'+struct.pack('<9f',*multiply(rotation,matrix(old_rot))),vector(*[a+b for a,b in zip(p,target)]))
        return (*result,*tail)
    for ref in refs:
        cid=editor.class_of[ref];kind=editor.doc.classes[cid][0]
        if kind in BASE_PARTS:editor.set(ref,'CFrame',cf(editor.get(ref,'CFrame')))
        elif kind=='Model':
            value=editor.get(ref,'WorldPivotData')
            if value[2]==b'\1':editor.set(ref,'WorldPivotData',cf(value))


def horizontal_gap(a,b):
    return math.hypot(*[max(a['min'][axis]-b['max'][axis],b['min'][axis]-a['max'][axis],0)for axis in (0,2)])
