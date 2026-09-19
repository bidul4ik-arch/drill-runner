"""Reference-led assets. Blender Z-up; runner faces +Y. Metres. Deterministic build."""
import bpy, math, os, random
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rng=random.Random(26)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
# Linear RGB values kept subdued: lighting, rather than albedo, provides warmth.
colors={'teal':(.028,.105,.12,1),'gold':(.58,.255,.035,1),'dark':(.022,.028,.034,1),'skin':(.56,.27,.135,1),'cyan':(.015,.48,.68,1),'wood':(.18,.065,.019,1),'sand':(.32,.17,.075,1),'rock':(.115,.065,.037,1),'steel':(.09,.14,.155,1),'silver':(.30,.34,.35,1),'leather':(.055,.034,.022,1),'sole':(.43,.39,.30,1),'hair':(.032,.018,.012,1),'white':(.8,.72,.6,1),'purple':(.24,.035,.55,1),'lamp':(1,.53,.10,1),'coin':(.83,.43,.035,1)}
mats={};os.makedirs(ROOT+'/Art/Textures',exist_ok=True)
for n,c in colors.items():
 m=bpy.data.materials.new(n);m.diffuse_color=c;m.use_nodes=True;m.node_tree.nodes.clear()
 p=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled');out=m.node_tree.nodes.new('ShaderNodeOutputMaterial');m.node_tree.links.new(p.outputs['BSDF'],out.inputs['Surface']);p.inputs['Base Color'].default_value=c;p.inputs['Roughness'].default_value=.73
 if n in ['steel','silver','coin']:p.inputs['Metallic'].default_value=.65;p.inputs['Roughness'].default_value=.32
 if n in ['cyan','purple','lamp']:p.inputs['Emission Color'].default_value=c;p.inputs['Emission Strength'].default_value=1.2 if n=='lamp' else .3
 if n in ['wood','sand','rock']:
  # Embedded image texture; deterministic grain/mottling, UVs exported in GLB.
  size=128;img=bpy.data.images.new(n+'_surface',width=size,height=size);pix=[]
  for y in range(size):
   for x in range(size):
    v=.75+.12*math.sin(x*.37+math.sin(y*.06)*2)+rng.random()*.12 if n=='wood' else .82+.09*math.sin(x*.15)*math.sin(y*.19)+rng.random()*.14
    pix.extend([min(1,k*v)**(1/2.2) for k in c[:3]]+[1])
  img.colorspace_settings.name='Non-Color';img.pixels=pix;img.filepath_raw=ROOT+'/Art/Textures/'+n+'_surface.png';img.file_format='PNG';img.save();img.pack()
  tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=img;m.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color'])
 mats[n]=m
parts=[];assign={}
def finish(o,n,m,bone='root',smooth=False):
 o.name=n;o.data.materials.append(mats[m]);parts.append(o);assign[o.name]=bone
 if smooth:
  for face in o.data.polygons:face.use_smooth=True
 return o
def box(n,p,s,m,bone='root',bevel=.035):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.dimensions=s;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  mod=o.modifiers.new('Soft edges','BEVEL');mod.width=min(bevel,min(s)*.22);mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name)
 return finish(o,n,m,bone)
def ell(n,p,s,m,bone='root'):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=10,radius=1,location=p);o=bpy.context.object;o.scale=s;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return finish(o,n,m,bone,True)
def rod(n,a,b,r,m,bone='root',r2=None,verts=12):
 a,b=Vector(a),Vector(b);d=b-a
 bpy.ops.mesh.primitive_cone_add(vertices=verts,radius1=r,radius2=r if r2 is None else r2,depth=d.length,location=(a+b)/2);o=bpy.context.object;o.rotation_mode='QUATERNION';o.rotation_quaternion=d.to_track_quat('Z','Y');return finish(o,n,m,bone,True)
def hair_lock(a,b,c,width):
 verts=[];faces=[]
 for j in range(7):
  t=j/6;A,B,C=Vector(a),Vector(b),Vector(c);center=(1-t)**2*A+2*(1-t)*t*B+t*t*C
  tangent=((B-A)*(1-t)+(C-B)*t).normalized();axis=tangent.cross(Vector((0,1,0))).normalized();axis2=tangent.cross(axis)
  radius=width*(1-t)**.7*(.7+.5*math.sin(t*math.pi))+.001
  for i in range(8):
   v=center+radius*(math.cos(i*math.tau/8)*axis+math.sin(i*math.tau/8)*axis2*.6);verts.append(v)
 for j in range(6):
  for i in range(8):faces.append((j*8+i,j*8+(i+1)%8,(j+1)*8+(i+1)%8,(j+1)*8+i))
 mesh=bpy.data.meshes.new('Swept hair');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('HairLock',mesh);bpy.context.collection.objects.link(o);finish(o,'HairLock','hair',smooth=True)
def stone(n,p,s,m='rock'):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2 if n=='Wall' else 1,radius=1,location=p);o=bpy.context.object;o.scale=s;o.rotation_euler=(rng.random()*.4,rng.random()*.4,rng.random()*6);return finish(o,n,m)
def crystal(p,size=1):
 x,y,z=p;rod('Crystal',(x,y,z),(x+.14*size,y,z+size),.22*size,'cyan',r2=.16*size,verts=5);rod('CrystalTip',(x+.14*size,y,z+size),(x+.22*size,y,z+1.45*size),.16*size,'cyan',r2=0,verts=5)
def join_objects(objs,name):
 bpy.ops.object.select_all(action='DESELECT')
 for o in objs:o.select_set(True)
 bpy.context.view_layer.objects.active=objs[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR');return o
def export(n,rig=None):
 global parts
 if not rig:
  parts=[join_objects(parts,n)]
 col=bpy.data.collections.new(n);bpy.context.scene.collection.children.link(col)
 for o in parts:
  for old in list(o.users_collection):old.objects.unlink(o)
  col.objects.link(o)
 bpy.ops.object.select_all(action='DESELECT')
 for o in parts:o.select_set(True)
 bpy.ops.export_scene.gltf(filepath=ROOT+'/Art/Models/'+n+'.glb',use_selection=True,export_format='GLB',export_animations=True)
 for o in parts:o.hide_set(True)
 parts=[]
# Explorer: rounded torso, expressive head, layered cropped jacket and equipment.
ell('Torso',(0,0,1.33),(.27,.17,.32),'dark')
ell('JacketLeft',(-.19,0,1.37),(.145,.21,.31),'gold');ell('JacketRight',(.19,0,1.37),(.145,.21,.31),'gold')
box('JacketHem',(0,0,1.12),(.58,.39,.1),'gold')
for x in [-.17,.17]:
 o=box('Lapel',(x,.165,1.53),(.12,.075,.32),'gold');o.rotation_euler.y=(-.28 if x<0 else .28)
 box('ChestStitch',(x,.208,1.29),(.016,.016,.18),'sole',bevel=.003)
rod('Neck',(0,0,1.56),(0,0,1.72),.105,'skin')
ell('Head',(0,.005,1.87),(.235,.195,.28),'skin')

for x in [-.23,.23]:ell('Ear',(x,0,1.84),(.035,.045,.065),'skin')
ell('Nose',(0,.198,1.865),(.027,.031,.039),'skin')
for x in [-.085,.085]:
 ell('Eye',(x,.180,1.91),(.044,.012,.030),'white');ell('Iris',(x,.193,1.909),(.020,.008,.025),'hair');ell('Pupil',(x,.201,1.912),(.010,.004,.015),'dark')
 o=box('Eyebrow',(x,.191,1.975),(.087,.017,.017),'hair');o.rotation_euler.y=.15 if x<0 else -.15
rod('Smile',(-.046,.186,1.79),(0,.200,1.78),.005,'leather');rod('Smile',(0,.200,1.78),(.046,.186,1.79),.005,'leather')
ell('HairCap',(0,-.035,2.015),(.249,.215,.19),'hair');ell('HairNape',(0,-.13,1.88),(.20,.09,.18),'hair')
for i in range(9):
 a=i*math.tau/9;x=.17*math.cos(a);y=.13*math.sin(a)-.025
 hair_lock((x*.7,y*.7,2.09),(x*1.25,y*1.3,2.22),(x*1.45+.055,y*1.4,1.98),.085)
for i in range(4):
 x=-.14+i*.07
 hair_lock((x,0,2.13),(x+.1,.14,2.20),(x+.12,.21,1.98),.065)
rod('GoggleStrap',(-.245,-.005,2.035),(.245,-.005,2.035),.04,'leather')
for x in [-.11,.11]:
 ell('GoggleRim',(x,.15,2.045),(.108,.045,.077),'gold');ell('GoggleGlass',(x,.187,2.045),(.080,.022,.054),'cyan')
# Belt, buckles, backpack straps and drill.
ell('Hips',(0,0,.99),(.285,.18,.20),'teal');box('Belt',(0,0,1.09),(.56,.37,.08),'leather');box('Buckle',(0,.203,1.09),(.11,.03,.085),'gold');box('BuckleInset',(0,.222,1.09),(.070,.01,.047),'leather')
for x in [-.24,.24]:
 box('ShoulderStrap',(x,.19,1.4),(.067,.042,.46),'leather')
 box('StrapClip',(x,.22,1.45),(.077,.025,.077),'silver')
box('Pack',(0,-.265,1.39),(.48,.23,.58),'teal',bevel=.09)
box('PackPocket',(0,-.405,1.26),(.31,.07,.20),'gold')
for x in [-.16,.16]:
 box('PackBand',(x,-.398,1.4),(.055,.04,.54),'leather');box('PackBuckle',(x,-.428,1.35),(.075,.035,.07),'silver')
# Diamond mounted on rear of backpack.
o=stone('PackCrystal',(0,-.407,1.55),(.075,.035,.13),'cyan')
rod('DrillBody',(.31,-.28,1.12),(.37,-.28,1.66),.085,'steel');rod('DrillCollar',(.37,-.28,1.64),(.39,-.28,1.76),.11,'gold')
rod('DrillBit',(.39,-.28,1.76),(.46,-.28,2.08),.10,'silver',r2=0)
for i in range(4):
 z=1.77+i*.063;r=.10-i*.018
 rod('BitRing',(.39+(z-1.76)*.22,-.28,z),(.39+(z-1.76)*.22,-.28,z+.018),r,'dark',r2=r*.9)
bones={}
for side,sign in [('L',-1),('R',1)]:
 x=sign*.16;th='thigh'+side;sh='shin'+side;up='arm'+side;fore='fore'+side
 bones[th]=((x,0,1.02),(x,0,.58),'root');bones[sh]=((x,0,.58),(x,0,.16),th)
 bones[up]=((sign*.32,0,1.57),(sign*.43,0,1.27),'root');bones[fore]=((sign*.43,0,1.27),(sign*.48,.035,1.0),up)
 ell('TrouserThigh',(x,0,.81),(.155,.175,.28),'teal',th)
 ell('TrouserShin',(x,-.015,.40),(.12,.14,.25),'teal',sh)
 box('KneePad',(x,.15,.58),(.21,.07,.20),'dark',sh,bevel=.05)
 box('CargoPocket',(x+sign*.12,-.01,.85),(.095,.23,.18),'teal',th)
 ell('Sleeve',(sign*.37,0,1.43),(.14,.15,.23),'gold',up)
 rod('RolledCuff',(sign*.41,0,1.30),(sign*.44,0,1.23),.145,'gold',up)
 ell('Forearm',(sign*.46,.01,1.14),(.075,.085,.16),'skin',fore)
 box('Glove',(sign*.485,.035,1.0),(.16,.13,.17),'dark',fore,bevel=.045)
 ell('Thumb',(sign*.42,.085,1.0),(.035,.06,.055),'dark',fore)
 box('Boot',(x,.055,.13),(.26,.42,.23),'gold',sh,bevel=.07)
 box('BootSole',(x,.075,.035),(.29,.46,.07),'sole',sh,bevel=.025)
 box('ToeCap',(x,.23,.115),(.265,.12,.125),'dark',sh,bevel=.04)
 for j in range(3):box('Laces',(x,.19,.16+j*.024),(.15,.025,.012),'sole',sh,bevel=.003)
# Join by skin segment before binding: a single mesh per bone, rather than hundreds of nodes.
groups={}
for o in parts:groups.setdefault(assign[o.name],[]).append(o)
parts=[]
for b,objs in groups.items():
 o=join_objects(objs,b+'Mesh');parts.append(o);assign[o.name]=b
bpy.ops.object.armature_add();rig=bpy.context.object;rig.name='ExplorerRig'
bpy.ops.object.mode_set(mode='EDIT');r=rig.data.edit_bones[0];r.name='root';r.head=(0,0,1);r.tail=(0,0,1.6)
for n,(head,tail,parent) in bones.items():
 b=rig.data.edit_bones.new(n);b.head=head;b.tail=tail;b.parent=rig.data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
for o in parts:
 o.parent=rig;vg=o.vertex_groups.new(name=assign[o.name]);vg.add(list(range(len(o.data.vertices))),1,'REPLACE');mod=o.modifiers.new('Rig','ARMATURE');mod.object=rig
parts.append(rig)
for name,length in [('idle',48),('run',24),('jump',24),('slide',30),('hit',24),('land',12),('lane',12)]:
 rig.animation_data_create();rig.animation_data.action=bpy.data.actions.new(name)
 for f in range(1,length+1):
  t=(f-1)/(length-1);phase=t*math.tau
  for n in bones:
   b=rig.pose.bones[n];b.rotation_mode='XYZ';a=0;sg=1 if n.endswith('L') else -1
   if name=='run':
    if n.startswith('thigh'):a=math.sin(phase)*.7*sg
    elif n.startswith('shin'):a=-max(0,math.sin(phase)*sg)*1.15
    elif n.startswith('arm'):a=-math.sin(phase)*.6*sg
    elif n.startswith('fore'):a=.65
   elif name=='jump':a=-.5 if n.startswith('thigh') else (-.7 if n.startswith('shin') else .9)
   elif name=='slide':a=-1.3 if n.startswith('thigh') else (.1 if n.startswith('shin') else .5)
   elif name=='idle':a=.025*math.sin(phase)
   b.rotation_euler=(a,0,0);b.keyframe_insert('rotation_euler',frame=f)
  b=rig.pose.bones['root'];b.rotation_mode='XYZ';b.rotation_euler=(.8*t if name=='hit' else (.18 if name=='land' else -.10 if name=='run' else 0),0,.10*math.sin(t*math.pi) if name=='lane' else 0);b.keyframe_insert('rotation_euler',frame=f)
  b.location=(0,0,.02*math.sin(phase) if name=='idle' else .045*abs(math.sin(phase)) if name=='run' else 0);b.keyframe_insert('location',frame=f)
 track=rig.animation_data.nla_tracks.new();track.name=name;track.strips.new(name,1,rig.animation_data.action);rig.animation_data.action=None
export('explorer',rig)
# Mine walkway: slabs, paired rails, tall enclosing rock walls, bolted timber arches.
box('Foundation',(0,0,-.22),(8.5,24,.40),'rock')
for y in range(-12,12,2):
 for x in [-2.65,0,2.65]:box('StoneSlab',(x,y+1,-.035),(2.6,1.96,.15),'sand',bevel=.04)
 for x in [-3.6,-1.4,1.4,3.6]:
  box('RailTie',(x,y+.5,.055),(.35,.18,.08),'wood',bevel=.01)
for x in [-3.6,-1.4,1.4,3.6]:box('SteelRail',(x,0,.08),(.10,24,.10),'steel',bevel=.018)
for sign in [-1,1]:
 x=sign*4.8
 for y in [-10,-6,-2,2,6,10]:
  o=stone('Wall',(sign*6.5,y,4.2),(1.7,3.2,4.7));o.rotation_euler=(.05,.07,.08)
  stone('Rock',(sign*4.4,y+.7,.55),(.75,1.0,.9),'sand')
  for j in range(2):stone('Rubble',(sign*rng.uniform(3.95,4.35),y+rng.uniform(-1,1),.12),(.17,.22,.17),'sand')
 for y in [-8,3]:
  for j in range(3):crystal((sign*(4.15+j*.22),y+j*.28,.35),.65+j*.22)
 for y in [-6,6]:
  box('Timber',(sign*4.13,y,3.3),(.46,.55,6.6),'wood',bevel=.06)
  for z in [1.0,3.8,5.6]:
   box('BracePlate',(sign*4.13,y-.30,z),(.50,.09,.37),'steel')
   for dx in [-.16,.16]:ell('Bolt',(sign*4.13+dx,y-.365,z),(.04,.035,.04),'silver')
  # Lamp on cantilever, at eye level above running space.
  rod('LampBracket',(sign*4.0,y,3.4),(sign*3.58,y,3.4),.045,'steel')
  rod('LampChain',(sign*3.58,y,3.4),(sign*3.58,y,2.95),.025,'dark')
  rod('LanternGlass',(sign*3.58,y,2.45),(sign*3.58,y,2.9),.14,'lamp',verts=8)
  for z in [2.42,2.93]:rod('LanternRim',(sign*3.58,y,z-.04),(sign*3.58,y,z+.04),.20,'dark',verts=8)
  for dx,dy in [(-.15,0),(.15,0),(0,-.15),(0,.15)]:rod('Cage',(sign*3.58+dx,y+dy,2.43),(sign*3.58+dx,y+dy,2.94),.021,'steel')
 # Elevated side balcony and balustrades.
 box('SideGallery',(sign*4.75,0,4.5),(1.7,24,.20),'wood')
 for y in range(-12,13,3):rod('Balustrade',(sign*4.0,y,4.5),(sign*4.0,y,5.3),.045,'wood')
 rod('Handrail',(sign*4.0,-12,5.3),(sign*4.0,12,5.3),.05,'wood')
for y in [-6,6]:
 box('Arch',(0,y,6.35),(8.8,.5,.43),'wood')
 for sign in [-1,1]:rod('DiagonalBrace',(sign*4.1,y,4.9),(sign*2.8,y,6.3),.13,'wood',verts=4)
export('track')
# Jump crate: layered planks, corner plates and diagonals, matches existing collision size.
box('CrateCore',(0,0,.48),(1.5,1.04,.94),'wood')
for x in [-.55,-.18,.18,.55]:box('FrontPlank',(x,-.55,.48),(.34,.07,.87),'wood',bevel=.018)
for x in [-.69,.69]:box('CrateFrame',(x,-.61,.48),(.15,.12,1.02),'gold')
for z in [.075,.885]:box('CrateFrame',(0,-.61,z),(1.5,.12,.15),'wood')
rod('CrateDiagonal',(-.61,-.65,.13),(.61,-.65,.85),.09,'wood',verts=4)
for x in [-.65,.65]:
 for z in [.1,.86]:
  box('CornerPlate',(x,-.69,z),(.19,.045,.16),'steel');ell('Rivet',(x,-.725,z),(.045,.025,.045),'silver')
export('crate')
# Cart open top, plank side panels, crystals visible above rim.
box('CartBase',(0,0,.42),(1.6,1.55,.20),'steel')
for x in [-.76,.76]:box('CartSide',(x,0,1.15),(.14,1.5,1.3),'wood')
for y in [-.73,.73]:
 box('CartEnd',(0,y,1.15),(1.55,.14,1.3),'wood')
 rod('CrossBrace',(-.65,y*1.12,.60),(.65,y*1.12,1.67),.06,'steel',verts=4)
 rod('CrossBrace',(.65,y*1.12,.60),(-.65,y*1.12,1.67),.06,'steel',verts=4)
for x in [-.78,.78]:
 box('CartRim',(x,0,1.82),(.17,1.72,.14),'steel')
 for y in [-.57,.57]:rod('Wheel',(x-.09,y,.28),(x+.09,y,.28),.26,'dark',verts=16)
for y in [-.78,.78]:box('CartRim',(0,y,1.82),(1.65,.16,.14),'steel')
for i in range(6):crystal((rng.uniform(-.5,.5),rng.uniform(-.5,.5),1.55),rng.uniform(.25,.45))
export('cart')
for x in [-.93,.93]:
 box('PipeStand',(x,0,.73),(.16,.46,1.46),'steel')
 box('Foot',(x,0,.07),(.36,.60,.14),'dark')
rod('PressurePipe',(-.95,0,1.65),(.95,0,1.65),.25,'teal',verts=20)
for x in [-.90,.9]:
 rod('Flange',(x-.07,0,1.65),(x+.07,0,1.65),.34,'steel',verts=12)
 for a in range(6):
  y=.28*math.sin(a*math.tau/6);z=1.65+.28*math.cos(a*math.tau/6)
  rod('FlangeBolt',(x-.10,y,z),(x+.10,y,z),.035,'gold',verts=6)
export('pipe')
# Coins: octagonal raised border and embossed diamond, readable from the camera.
rod('Token',(0,-.06,0),(0,.06,0),.39,'coin',verts=8)
rod('Inset',(0,-.069,0),(0,-.075,0),.31,'gold',verts=8)
for y in [-.087,.087]:
 o=box('Diamond',(0,y,0),(.24,.035,.24),'coin',bevel=.02);o.rotation_euler.y=math.pi/4
export('coin')
for name,mat in [('shield','cyan'),('magnet','purple')]:
 stone(name,(0,0,0),(.3,.24,.43),mat)
 for z in [-.35,.35]:rod('BonusCap',(0,0,z-.04),(0,0,z+.04),.18,'silver',verts=8)
 export(name)
# Source library: collections separated; only hero visible on initial opening.
for c in bpy.data.collections:
 if c.name not in ['Collection','explorer']:c.hide_viewport=True
for o in bpy.data.collections['explorer'].objects:o.hide_set(False)
bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/Art/Blender/drilldrop.blend')
print('DRILLDROP V2 ASSETS COMPLETE')
