"""Run in a fresh background Blender, never in an existing .blend session.

Inputs remain untouched. Outputs preserve every triangle, UV and source PBR map.
The upload folder must separately be approved in Studio MCP permissions.
Example: blender --background --factory-startup --python this.py -- --root PATH
"""
from pathlib import Path
import argparse, hashlib, json, math, sys
import bpy
from mathutils import Matrix, Vector

parser=argparse.ArgumentParser()
parser.add_argument('--root',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
root=args.root.resolve()
rows=[]
for folder in sorted((root/'originals').iterdir()):
 if not folder.is_dir() or not folder.name.startswith('NORMAL_'):continue
 item=folder.name
 bpy.ops.wm.read_factory_settings(use_empty=True)
 fbx=next(folder.glob('*.fbx'))
 bpy.ops.import_scene.fbx(filepath=str(fbx))
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
 assert len(objects)==1,(item,'expected one mesh')
 obj=objects[0]
 obj.data.calc_loop_triangles()
 triangles=len(obj.data.loop_triangles)
 assert triangles<=20000
 # Apply only a rigid rotation/translation to a freshly imported working copy.
 # Source Blender Z-up becomes glTF/Roblox Y-up. All handles run along local X.
 vertices=[obj.matrix_world@v.co for v in obj.data.vertices]
 lo=Vector([min(v[i] for v in vertices) for i in range(3)])
 hi=Vector([max(v[i] for v in vertices) for i in range(3)])
 turn=Matrix.Rotation(-math.pi/2,4,'Z') if (hi-lo).y>(hi-lo).x else Matrix.Identity(4)
 vertices=[turn@v for v in vertices]
 lo=Vector([min(v[i] for v in vertices) for i in range(3)])
 hi=Vector([max(v[i] for v in vertices) for i in range(3)])
 middle=(lo.x+hi.x)/2
 grip_vertices=[v for v in vertices if abs(v.x-middle)<(hi.x-lo.x)*.06]
 assert grip_vertices
 grip=Vector((middle,(min(v.y for v in grip_vertices)+max(v.y for v in grip_vertices))/2,
  (min(v.z for v in grip_vertices)+max(v.z for v in grip_vertices))/2))
 for vertex,value in zip(obj.data.vertices,vertices):vertex.co=value-grip
 obj.matrix_world=Matrix.Identity(4)
 obj.name=item;obj.data.name=item+'_Mesh'
 maps={}
 for mat in obj.data.materials:
  mat.name=item+'_PBR'
  for node in mat.node_tree.nodes:
   if node.type!='TEX_IMAGE' or not node.image:continue
   path=Path(bpy.path.abspath(node.image.filepath))
   assert path.is_file(),path
   suffix=path.stem.rsplit('_',1)[-1]
   assert suffix in {'basecolor','normal','roughness','metallic'},suffix
   node.image.colorspace_settings.name='sRGB' if suffix=='basecolor' else 'Non-Color'
   maps[suffix]={'file':path.name,'size':list(node.image.size),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
  assert set(maps)=={'basecolor','normal','roughness','metallic'}
 obj.select_set(True);bpy.context.view_layer.objects.active=obj
 target=root/'exports'/f'{item}.glb';target.parent.mkdir(parents=True,exist_ok=True)
 bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,
  export_animations=False,export_cameras=False,export_lights=False,export_yup=True,
  export_materials='EXPORT',export_image_format='AUTO',export_apply=True)
 assert target.stat().st_size<=20*1024*1024,(item,'upload exceeds 20 MB')
 def rb(v):return [v.x,v.z,-v.y]
 center=(lo+hi)/2-grip
 extent=hi-lo
 rows.append({'ItemId':item,'SourceZip':fbx.stem+'.zip','SourceFBX':fbx.name,'Triangles':triangles,
  'SourceYawDegrees':-90 if turn!=Matrix.Identity(4) else 0,'GripInAlignedSource':list(grip),
  'MeshCenter':rb(center),'MeshSize':[extent.x,extent.z,extent.y],
  'SourceMetresPerUnit':1,'Maps':maps,'GLB':str(target),'GLBBytes':target.stat().st_size,
  'GLBSHA256':hashlib.sha256(target.read_bytes()).hexdigest()})
 print('EXPORTED',item,triangles,target.stat().st_size,flush=True)
(root/'PreparedManifest.json').write_text(json.dumps(rows,indent=2)+'\n',encoding='utf-8')
