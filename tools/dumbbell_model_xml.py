"""Encode the geometry-only Studio audit into Roblox XML (no source or upload).

Used to build a separate local physics fixture from the read-only typed export.
Native mesh metadata and PBR packs must be restored from registered Model assets
before Play; this XML property encoder is not a full native asset exporter.
"""
import base64, struct, xml.etree.ElementTree as ET

CONTENT = {'MeshId','TextureID','TextureId','ColorMap','NormalMap','RoughnessMap','MetalnessMap','Image','Texture','ShirtTemplate','PantsTemplate','Graphic'}
def attributes(values):
    if not values: return ''
    out=struct.pack('<I',len(values))
    def string(s):
        b=s.encode('utf-8');return struct.pack('<I',len(b))+b
    for name,p in values.items():
        t,v=p['T'],p['V'];out+=string(name)
        if t=='string':out+=b'\x02'+string(v)
        elif t=='boolean':out+=b'\x03'+bytes([v])
        elif t=='number':out+=b'\x06'+struct.pack('<d',v)
        elif t=='Vector3':out+=b'\x11'+struct.pack('<fff',*v)
        elif t=='Color3':out+=b'\x0f'+struct.pack('<fff',*v)
        else: raise ValueError((name,t))
    return base64.b64encode(out).decode()

def property_xml(parent,name,p):
    t,v=p['T'],p['V']
    if name in CONTENT and t=='string':
        el=ET.SubElement(parent,'Content',name=name)
        ET.SubElement(el,'url' if v else 'null').text=v or None
        return
    tag={'boolean':'bool','number':'double','CFrame':'CoordinateFrame'}.get(t,t)
    if name=='Size' and t=='Vector3':name='size'
    el=ET.SubElement(parent,tag,name=name)
    axes={'Vector3':['X','Y','Z'],'Vector2':['X','Y'],'Color3':['R','G','B'],
          'CFrame':['X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22'],
          'UDim2':['XS','XO','YS','YO'],'UDim':['S','O']}.get(t)
    if axes:
        for axis,value in zip(axes,v):ET.SubElement(el,axis).text=str(value)
    else:el.text=str(v).lower() if isinstance(v,bool) else str(v)

def model_xml(parent,row):
    assert row['Class'] not in ('Script','LocalScript','ModuleScript','PackageLink')
    el=ET.SubElement(parent,'Item',{'class':row['Class'],'referent':row['Id']})
    props=ET.SubElement(el,'Properties')
    for name,p in row['Properties'].items():property_xml(props,name,p)
    if row['Attributes']:ET.SubElement(props,'BinaryString',name='AttributesSerialize').text=attributes(row['Attributes'])
    if row['Tags']:ET.SubElement(props,'BinaryString',name='Tags').text=base64.b64encode('\0'.join(row['Tags']).encode()).decode()
    for child in row['Children']:model_xml(el,child)
    return el
