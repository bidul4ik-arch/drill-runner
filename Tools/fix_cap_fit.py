"""Keep full hair and cap-compatible hair as separate skinned meshes in Blender/GLB."""
import bpy,bmesh,os,math,sys,json
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
bpy.ops.wm.open_mainfile(filepath=ROOT+'/Art/Blender/hero_reference_final.blend')
col=bpy.data.collections['explorer'];head=bpy.data.objects['headMesh']
# Classify connected pieces, so eyebrows/eyelashes remain on the face.
mesh=head.data;neighbors={v.index:set() for v in mesh.vertices}
for e in mesh.edges:
 a,b=e.vertices;neighbors[a].add(b);neighbors[b].add(a)
seen=set();hair=set();goggles=set()
for v in mesh.vertices:
 if v.index in seen:continue
 stack=[v.index];group=set()
 while stack:
  i=stack.pop()
  if i in seen:continue
  seen.add(i);group.add(i);stack.extend(neighbors[i]-seen)
 faces=[p for p in mesh.polygons if p.vertices[0] in group]
 materials={mesh.materials[p.material_index].name for p in faces}
 top=max(mesh.vertices[i].co.z for i in group)
 if materials & {'hair','hair_light'} and top>2.015:hair.update(group)
 elif materials & {'leather','brass','lens'} and top>2.015:goggles.update(group)
def subset(name,keep):
 ob=head.copy();ob.data=head.data.copy();ob.name=name;col.objects.link(ob)
 bm=bmesh.new();bm.from_mesh(ob.data);bm.verts.ensure_lookup_table()
 bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.index not in keep],context='VERTS');bm.to_mesh(ob.data);bm.free()
 return ob
full=subset('HairOriginal',hair)
short=subset('HairUnderCap',hair)
eyewear=subset('GogglesAccessory',goggles)
# Clamp upper locks inside the inner ellipsoid of the separate cap crown.
base=1.74+(2.083-1.74)*.9;cy=-.015*.9;rx=.235*.9;ry=.218*.9;rz=.235*.9
for v in short.data.vertices:
 p=v.co
 if p.z<=base-.025:continue
 p.z=base+(p.z-base)*.32-.018
 if p.z>base:
  limit=math.sqrt(max(.01,1-((p.z-base)/rz)**2))*.91
 else:limit=.91
 radius=math.sqrt((p.x/rx)**2+((p.y-cy)/ry)**2)
 if radius>limit:p.x*=limit/radius;p.y=cy+(p.y-cy)*limit/radius
bm=bmesh.new();bm.from_mesh(head.data);bm.verts.ensure_lookup_table()
bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.index in hair or v.index in goggles],context='VERTS');bm.to_mesh(head.data);bm.free()
# Keep the cap physically separate, add thickness rather than scaling the entire head.
cap=bpy.data.objects['CapAccessory']
cap.hide_set(False);bpy.context.view_layer.objects.active=cap
thick=cap.modifiers.new('Cap fabric thickness','SOLIDIFY');thick.thickness=.008
bpy.ops.object.modifier_apply(modifier=thick.name)
bpy.ops.object.select_all(action='DESELECT')
for o in col.objects:o.hide_set(False);o.select_set(True)
bpy.ops.export_scene.gltf(filepath=ROOT+'/Art/Models/explorer.glb',use_selection=True,export_format='GLB',export_animations=True)
sys.path.insert(0,ROOT+'/Tools');from fix_cloth_factors import fix
fix(ROOT+'/Art/Models/explorer.glb')
full.hide_set(True);eyewear.hide_set(True)
bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/Art/Blender/hero_cap_fit.blend')
open(ROOT+'/Tests/Lobby/cap-fit.json','w').write(json.dumps({'hair_vertices':len(full.data.vertices),'cap_hair_vertices':len(short.data.vertices),'eyewear_vertices':len(eyewear.data.vertices),'cap_base':base},indent=2))
print('CAP_FIT_EXPORTED')
