"""Render the actual source meshes in Blender, with no separate presentation geometry."""
import bpy,os,math
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
bpy.ops.wm.open_mainfile(filepath=ROOT+'/Art/Blender/reference_revision.blend')
scene=bpy.context.scene
for col in bpy.data.collections:
 col.hide_viewport=False
 for o in col.objects:o.hide_set(False);o.hide_render=True
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.cycles.max_bounces=5;scene.render.threads_mode='FIXED';scene.render.threads=8
scene.render.resolution_x=1000;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.24,.28,.32,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.4
scene.view_settings.view_transform='AgX'
# Studio floor and broad light sources reveal silhouette, surface and joints.
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.06));floor=bpy.context.object;floor.name='Preview floor'
m=bpy.data.materials.new('Preview floor material');m.diffuse_color=(.25,.21,.16,1);m.use_nodes=True;m.node_tree.nodes.clear();p=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled');out=m.node_tree.nodes.new('ShaderNodeOutputMaterial');p.inputs['Base Color'].default_value=(.25,.21,.16,1);m.node_tree.links.new(p.outputs[0],out.inputs['Surface']);floor.data.materials.append(m)
def area(name,p,power,size,color):
 d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;d.color=color;o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=p;o.rotation_euler=(Vector((0,0,1.7))-o.location).to_track_quat('-Z','Y').to_euler()
area('Warm key',(-4,4,7),900,5,(1,.82,.63));area('Cool soft fill',(5,0,5),700,4,(.56,.80,1));area('Warm rim',(0,-5,6),1100,3,(1,.69,.34))
d=bpy.data.cameras.new('Preview camera');cam=bpy.data.objects.new('Preview camera',d);scene.collection.objects.link(cam);scene.camera=cam;d.lens=58
os.makedirs(ROOT+'/Art/Renders',exist_ok=True)
for name,pos,target in [('explorer',(2.7,4.7,2.6),(0,0,1.12)),('mining_robot',(7,-10,6.1),(0,0,2.1)),('crystal_guardian',(7,-11,6.3),(0,0,2.65)),('giant_drill',(8,-12,6.1),(0,-.4,2.0))]:
 col=bpy.data.collections[name]
 for o in col.objects:o.hide_render=False
 scene.frame_set(1)
 # Freeze all authored bones at the neutral idle pose for the model sheet.
 for o in col.objects:
  if o.type=='ARMATURE':
   if o.animation_data:
    for t in o.animation_data.nla_tracks:t.mute=True
   for b in o.pose.bones:b.rotation_euler=(0,0,0);b.location=(0,0,0)
 cam.location=pos;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
 scene.render.filepath=ROOT+'/Art/Renders/'+name+'-blender.png';bpy.ops.render.render(write_still=True)
 for o in col.objects:o.hide_render=True
print('BLENDER REVIEW RENDERS COMPLETE')
