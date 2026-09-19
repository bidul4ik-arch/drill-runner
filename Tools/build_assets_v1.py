import bpy, math, os
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
colors={'teal':(.025,.24,.27,1),'gold':(.95,.51,.08,1),'dark':(.025,.05,.07,1),'skin':(.65,.34,.17,1),'cyan':(.1,.85,.95,1),'wood':(.34,.16,.065,1),'sand':(.48,.29,.14,1),'coral':(.95,.18,.1,1),'purple':(.58,.19,.95,1)}
mats={}
for n,c in colors.items():
 m=bpy.data.materials.new(n); m.diffuse_color=c; m.use_nodes=True
 m.node_tree.nodes.clear();p=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled');out=m.node_tree.nodes.new('ShaderNodeOutputMaterial');m.node_tree.links.new(p.outputs['BSDF'],out.inputs['Surface']);p.inputs['Base Color'].default_value=c;p.inputs['Roughness'].default_value=.65
 if n in ['cyan','purple']: p.inputs['Emission Color'].default_value=c;p.inputs['Emission Strength'].default_value=.5
 mats[n]=m
parts=[]
def box(n,p,s,m):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.name=n;o.dimensions=s;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mats[m]);parts.append(o);return o
def gem(n,p,r,m):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=r,location=p);o=bpy.context.object;o.name=n;o.data.materials.append(mats[m]);parts.append(o);return o
def export(n):
 bpy.ops.object.select_all(action='DESELECT')
 for o in parts:o.select_set(True)
 bpy.ops.export_scene.gltf(filepath=ROOT+'/Art/Models/'+n+'.glb',use_selection=True,export_format='GLB',export_animations=True)
 for o in parts:o.hide_set(True)
 parts.clear()
# Coordinates Blender Z up, runner faces +Y (Godot -Z).
body=box('Jacket',(0,0,1.13),(.63,.4,.64),'gold');gem('Head',(0,0,1.72),.29,'skin');box('Hair',(0,-.025,1.92),(.47,.38,.13),'dark')
box('Goggles',(0,.255,1.78),(.46,.08,.13),'cyan');box('Backpack',(0,-.30,1.24),(.48,.24,.48),'teal')
bpy.ops.mesh.primitive_cone_add(vertices=8,radius1=.14,radius2=0,depth=.42,location=(.28,-.31,1.60));o=bpy.context.object;o.name='DrillTip';o.data.materials.append(mats['dark']);parts.append(o)
limbs={}
for side,x in [('L',-.22),('R',.22)]:
 limbs['leg'+side]=box('leg'+side,(x,0,.47),(.23,.28,.72),'teal');box('Boot'+side,(x,.1,.15),(.29,.48,.25),'dark')
 limbs['arm'+side]=box('arm'+side,(x*1.95,0,1.10),(.20,.25,.65),'gold')
bpy.ops.object.armature_add(location=(0,0,0));rig=bpy.context.object;rig.name='ExplorerRig';parts.append(rig)
bpy.ops.object.mode_set(mode='EDIT');root=rig.data.edit_bones[0];root.name='root';root.head=(0,0,0);root.tail=(0,0,1)
for n,o in limbs.items():
 b=rig.data.edit_bones.new(n); b.head=(o.location.x,0,.85 if n.startswith('leg') else 1.43);b.tail=(o.location.x,0,.2 if n.startswith('leg') else .8);b.parent=root
bpy.ops.object.mode_set(mode='OBJECT')
for o in parts[:]:
 if o.type!='MESH':continue
 bone=o.name if o.name in limbs else ('leg'+o.name[-1] if o.name.startswith('Boot') else 'root')
 o.parent=rig;vg=o.vertex_groups.new(name=bone);vg.add(list(range(len(o.data.vertices))),1,'REPLACE');mod=o.modifiers.new('Rig','ARMATURE');mod.object=rig
for name,length in [('idle',48),('run',24),('jump',24),('slide',30),('hit',24),('land',12),('lane',12)]:
 rig.animation_data_create();rig.animation_data.action=bpy.data.actions.new(name)
 for f in range(1,length+1,3):
  for n in limbs:
   b=rig.pose.bones[n];b.rotation_mode='XYZ';angle=0
   if name=='run':angle=math.sin((f-1)/length*math.tau)*.7*(1 if n.endswith('L') else -1)*(1 if n.startswith('leg') else -1)
   if name=='jump':angle=-.5 if n.startswith('leg') else -1.5
   if name=='slide':angle=-1.3 if n.startswith('leg') else .4
   b.rotation_euler=(angle,0,0);b.keyframe_insert('rotation_euler',frame=f)
  b=rig.pose.bones['root'];b.rotation_mode='XYZ';b.rotation_euler=(.8 if name=='hit' else (.18 if name=='land' else 0),0,.12*math.sin(f/length*math.pi) if name=='lane' else 0);b.keyframe_insert('rotation_euler',frame=f)
  b.location=(0,0,.035*math.sin(f/length*math.tau) if name=='idle' else 0);b.keyframe_insert('location',frame=f)
 track=rig.animation_data.nla_tracks.new();track.name=name;track.strips.new(name,1,rig.animation_data.action);rig.animation_data.action=None
export('explorer')
box('Walkway',(0,0,-.16),(8,24,.3),'sand')
for x in [-3.85,-1.25,1.25,3.85]:box('Rail',(x,0,.015),(.055,24,.035),'gold')
for y in range(-12,12,2):box('Sleeper',(0,y,-.005),(7.8,.08,.035),'wood')
for x in [-4.6,4.6]:
 box('Support',(x,0,2.6),(.5,.6,5.2),'wood')
 for y in [-9,-5,4,9]:
  o=gem('Rock',(x*1.25,y,.8),1.6,'sand');o.scale=(1,1,1.5)
  o=gem('Crystal',(x,y,.8),.65,'cyan');o.scale=(.6,.6,2.5)
box('Arch',(0,0,5.2),(9.5,.6,.45),'wood');export('track')
box('Crate',(0,0,.48),(1.55,1.1,.96),'wood')
for x in [-.68,.68]:box('Strap',(x,0,.49),(.12,1.14,1),'gold')
export('crate')
box('Cart',(0,0,1.0),(1.65,1.6,1.7),'teal')
for x in [-.78,.78]:
 for y in [-.6,.6]:gem('Wheel',(x,y,.25),.3,'dark')
box('Rim',(0,0,1.85),(1.8,1.7,.15),'gold');export('cart')
for x in [-.92,.92]:box('Post',(x,0,1.35),(.15,.4,2.7),'teal')
box('SlideBeam',(0,0,1.65),(1.95,.65,.55),'coral');export('pipe')
for name,mat in [('coin','gold'),('shield','cyan'),('magnet','purple')]:
 o=gem(name,(0,0,0),.37,mat)
 if name=='coin':o.scale=(1,.3,1)
 export(name)
os.makedirs(ROOT+'/Art/Textures',exist_ok=True)
img=bpy.data.images.new('DrillDrop Palette',width=9,height=1);img.pixels=[v for c in colors.values() for v in c];img.filepath_raw=ROOT+'/Art/Textures/palette.png';img.file_format='PNG';img.save()
# Keep source assets visible in collection; individual exports are origin-centered.
for o in bpy.context.scene.objects:o.hide_set(False)
bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/Art/Blender/drilldrop.blend')
