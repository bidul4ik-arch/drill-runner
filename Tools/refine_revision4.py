"""Editable slide and reference sandstone; exports actual game assets."""
import bpy,os,sys
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0,ROOT+'/Tools')
from fix_cloth_factors import fix,FACTORS
FACTORS.update({'sand':[.78,.78,.78,1],'rock':[.38,.32,.27,1],'cave_rock':[.12,.24,.3,1]})
bpy.ops.wm.open_mainfile(filepath=ROOT+'/Art/Blender/reference_revision.blend')

for col in bpy.data.collections:col.hide_viewport=False
def enable(layer):
 layer.exclude=False;layer.hide_viewport=False
 for child in layer.children:enable(child)
enable(bpy.context.view_layer.layer_collection)
bpy.context.view_layer.update()
mat=bpy.data.materials['sand'];nodes=mat.node_tree.nodes
bs=next(n for n in nodes if n.type=='BSDF_PRINCIPLED')
tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(ROOT+'/Art/Textures/Reference/sandstone.png',check_existing=True);tex.image.pack()
mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
bs.inputs['Base Color'].default_value=(1,1,1,1)
uvnode=nodes.new('ShaderNodeUVMap');uvnode.uv_map='Revision4UV';mat.node_tree.links.new(uvnode.outputs['UV'],tex.inputs['Vector'])
for link in list(bs.inputs['Normal'].links):mat.node_tree.links.remove(link)
for name in ['gold','teal']:
 for node in bpy.data.materials[name].node_tree.nodes:
  if node.type=='NORMAL_MAP':node.inputs['Strength'].default_value=.07
for name in ['rock','cave_rock']:
 m=bpy.data.materials[name];ns=m.node_tree.nodes
 shader=next(n for n in ns if n.type=='BSDF_PRINCIPLED')
 t=ns.new('ShaderNodeTexImage');t.image=tex.image
 u=ns.new('ShaderNodeUVMap');u.uv_map='Revision4UV'
 m.node_tree.links.new(u.outputs['UV'],t.inputs['Vector']);m.node_tree.links.new(t.outputs['Color'],shader.inputs['Base Color'])
 for link in list(shader.inputs['Normal'].links):m.node_tree.links.remove(link)
for cname in ['track','crystal_track','industrial_track','home']:
 for ob in bpy.data.collections[cname].objects:
  if ob.type!='MESH':continue
  uv=ob.data.uv_layers.get('Revision4UV') or ob.data.uv_layers.new(name='Revision4UV')
  ob.data.uv_layers.active=uv
  for poly in ob.data.polygons:
   m=ob.data.materials[poly.material_index]
   if m and m.name in ['sand','rock','cave_rock'] and uv:
    for li in poly.loop_indices:
     v=ob.matrix_world@ob.data.vertices[ob.data.loops[li].vertex_index].co
     uv.data[li].uv=(v.x/5.5,v.y/5.5) if abs(poly.normal.z)>.5 else ((v.y/5,v.z/5) if abs(poly.normal.x)>.5 else (v.x/5,v.z/5))
   if m and m.name in ['rock','cave_rock']:poly.use_smooth=True
rig=next(o for o in bpy.data.collections['explorer'].objects if o.type=='ARMATURE')
for track in list(rig.animation_data.nla_tracks):
 if track.name=='slide':rig.animation_data.nla_tracks.remove(track)
old=bpy.data.actions.get('slide')
if old:old.name='slide_legacy'
a=bpy.data.actions.new('slide');rig.animation_data.action=a
for frame,weight in [(1,0),(5,1),(21,1),(25,0)]:
 for b in rig.pose.bones:
  b.rotation_mode='XYZ';b.rotation_euler=(0,0,0);b.location=(0,0,0)
  angle=0
  if b.name=='root':b.location=(0,-.68*weight,0);angle=.78*weight
  elif b.name.startswith('thigh'):angle=(.75 if b.name.endswith('L') else 1.2)*weight
  elif b.name.startswith('shin'):angle=(-.10 if b.name.endswith('L') else -1.1)*weight
  elif b.name.startswith('arm'):angle=-.6*weight
  elif b.name.startswith('fore'):angle=.9*weight
  b.rotation_euler.x=angle
  b.keyframe_insert('rotation_euler',frame=frame);b.keyframe_insert('location',frame=frame)
track=rig.animation_data.nla_tracks.new();track.name='slide';track.strips.new('slide',1,a);rig.animation_data.action=None
for name in ['explorer','track','crystal_track','industrial_track','home']:
 bpy.ops.object.select_all(action='DESELECT')
 for ob in bpy.data.collections[name].objects:ob.hide_viewport=False;ob.hide_set(False);ob.select_set(True)
 bpy.ops.export_scene.gltf(filepath=ROOT+'/Art/Models/'+name+'.glb',use_selection=True,export_format='GLB',export_animations=True)
 fix(ROOT+'/Art/Models/'+name+'.glb')
 for ob in bpy.data.collections[name].objects:ob.hide_set(True)
for ob in bpy.data.collections['explorer'].objects:ob.hide_set(False)
bpy.context.scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/Art/Blender/reference_revision.blend')
