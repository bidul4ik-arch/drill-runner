"""Original Blender cap, extended mine obstacles, and rendered volumetric dust."""
import bpy,math,os,random
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Standalone authoring helpers (this does not rebuild or replace the hero).
exec(open(ROOT+'/Tools/build_assets.py').read().split('# Explorer:')[0])
for z in [-3.6,0,3.6]:
 box('Ore carriage',(0,z,.90),(1.80,3.45,1.55),'wood',bevel=.10)
 for x in [-.91,.91]:
  box('Steel side rail',(x,z,.9),(.12,3.48,1.5),'steel',bevel=.035)
  for zz in [-1.15,1.15]:rod('Mine train wheel',(x-.05,z+zz,.25),(x+.05,z+zz,.25),.28,'dark')
 for zz in [-1.55,1.55]:box('End brace',(0,z+zz,1.48),(1.95,.16,.16),'steel')
 for i in range(5):crystal((rng.uniform(-.65,.65),z+rng.uniform(-1,1),1.67),rng.uniform(.25,.5))
export('ore_train')
for x in [-.9,.9]:
 box('Conduit support',(x,0,.78),(.13,6,1.5),'steel')
 for z in [-2.6,0,2.6]:rod('Upper conduit',(-.97,z,1.5),(.97,z,1.5),.22,'teal')
for x in [-.75,.75]:box('Caution stripe',(x,0,1.8),(.11,6,.06),'gold')
export('long_conduit')
bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/Art/Blender/mobile_obstacles.blend')
# Dust is rendered from noisy volumetric ellipsoids in Blender, with transparent edges.
for ob in list(bpy.data.objects):bpy.data.objects.remove(ob,do_unlink=True)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24
scene.render.resolution_x=256;scene.render.resolution_y=256;scene.render.resolution_percentage=100;scene.render.film_transparent=True
scene.world.color=(.05,.05,.05)
material=bpy.data.materials.new('Volumetric limestone dust');material.use_nodes=True;n=material.node_tree.nodes;n.clear()
out=n.new('ShaderNodeOutputMaterial');volume=n.new('ShaderNodeVolumePrincipled');volume.inputs['Color'].default_value=(.7,.65,.55,1)
noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=3;noise.inputs['Detail'].default_value=4
mult=n.new('ShaderNodeMath');mult.operation='MULTIPLY';mult.inputs[1].default_value=2.8
material.node_tree.links.new(noise.outputs['Fac'],mult.inputs[0]);material.node_tree.links.new(mult.outputs[0],volume.inputs['Density']);material.node_tree.links.new(volume.outputs['Volume'],out.inputs['Volume'])
for i in range(12):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,location=(rng.uniform(-.65,.65),rng.uniform(-.3,.3),rng.uniform(-.6,.6)))
 ob=bpy.context.object;ob.scale=(rng.uniform(.3,.65),.32,rng.uniform(.25,.58));ob.data.materials.append(material)
bpy.ops.object.camera_add(location=(0,-5,0));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,0))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=3;scene.camera=cam
bpy.ops.object.light_add(type='AREA',location=(-2,-3,3));light=bpy.context.object;light.data.energy=500;light.data.shape='DISK';light.data.size=4;light.rotation_euler=(-light.location).to_track_quat('-Z','Y').to_euler()
scene.render.filepath=ROOT+'/Art/Textures/dust_puff.png';bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/Art/Blender/dust_particles.blend')
