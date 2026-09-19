"""Reference hero, articulated 15-bone rig and complete in-place motion library."""
import bpy,os,math,sys,json
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0,ROOT+'/Tools')
src=open(ROOT+'/Tools/build_reference_assets.py').read()
exec(src[:src.index('# HERO:')])
def hair_lock(a,b,c,width):
 A,B,C=Vector(a),Vector(b),Vector(c);vs=[];fs=[];steps=13;sides=16
 ax=(B-A).cross(Vector((0,0,1)))
 if ax.length<.01:ax=Vector((1,0,0))
 ax.normalize()
 for j in range(steps):
  t=j/(steps-1);center=(1-t)**2*A+2*t*(1-t)*B+t*t*C
  tangent=((B-A)*(1-t)+(C-B)*t).normalized();ax=ax-tangent*ax.dot(tangent)
  ax.normalize();ay=tangent.cross(ax)
  w=width*(.62+.62*math.sin(t*math.pi))*(1-t)**.6+.0008
  for i in range(sides):
   u=i*math.tau/sides;ridge=1+.06*math.cos(u*4)
   vs.append(center+ax*math.cos(u)*w+ay*math.sin(u)*w*.34*ridge)
 for j in range(steps-1):
  for i in range(sides):fs.append((j*sides+i,j*sides+(i+1)%sides,(j+1)*sides+(i+1)%sides,(j+1)*sides+i))
 mesh_obj('Layered sculpted hair lock',vs,fs,'hair',smooth=True)
hero=src[src.index('# HERO:'):src.index('# Existing animation contract retained')]
hero=hero.replace('fold=.027','fold=.075').replace('fold=.04','fold=.095').replace('fold=.03','fold=.075')
hair_start=hero.index('# Crown and sideburns')
hair_end=hero.index('# Forehead goggles')
hair_code="""
ell('Hair undercut',(0,-.035,2.04),(.205,.18,.155),'hair')
for j in range(26):
 a=j*2.399963;radius=.09+.10*((j%5)/4)
 x=math.cos(a)*radius;y=math.sin(a)*radius-.035
 hair_lock((x*.45,y*.35,2.15),(x+.05,y-.04,2.30-(j%4)*.022),(x+.11,y-.03,2.12+(j%3)*.045),.060+(j%3)*.01)
for j in range(17):
 a=math.pi+(j/16)*math.pi
 x=math.cos(a)*.17;y=math.sin(a)*.15-.05
 hair_lock((x*.74,y*.65,2.15),(x+.03,y-.055,2.04),(x+.05,y-.025,1.88+(j%4)*.028),.055)
for sg in [-1,1]:
 for j in range(4):
  hair_lock((sg*.15,.065-j*.035,2.12),(sg*.23,.018-j*.03,2.075),(sg*.205,-.015-j*.033,1.94+j*.014),.052)
"""
hero=hero[:hair_start]+hair_code+hero[hair_end:]
hero=hero.replace(" box('Vertical pack webbing',(sign*.15,-.423,1.40),(.035,.018,.39),'leather',bevel=.005)","")
hero=hero.replace(" buckle('Pack strap buckle',(sign*.15,-.44,1.39),.053,.070)","")
hero=hero.replace("plate('Pack padded body',(0,-.268,1.416),(.435,.215,.57),'teal')","shield_panel('Pack padded body',(0,-.268,1.416),.435,.57,.215,'teal')")
exec(hero)
ell('Hair nape volume',(0,-.095,1.982),(.197,.15,.178),'hair')
for j in range(9):
 x=(j-4)*.037
 hair_lock((x-.045,-.16,2.08),(x+.01,-.27,2.025),(x+.055,-.21,1.845+(j%3)*.023),.047)
# Open standing collar wraps around the back of the neck.
vs=[];fs=[]
for z,rx,ry in [(1.635,.148,.126),(1.755,.178,.151),(1.777,.176,.148)]:
 for i in range(25):
  a=.24+((math.tau-.48)*i/24);vs.append((rx*math.sin(a),ry*math.cos(a)-.015,z))
for j in range(2):
 for i in range(24):fs.append((j*25+i,j*25+i+1,(j+1)*25+i+1,(j+1)*25+i))
collar=mesh_obj('Wrapped standing collar',vs,fs,'gold',smooth=True)
mod=collar.modifiers.new('Collar thickness','SOLIDIFY');mod.thickness=.014;bpy.context.view_layer.objects.active=collar;bpy.ops.object.modifier_apply(modifier=mod.name)
plate('Pack lower impact bumper',(0,-.449,1.19),(.255,.066,.10),'steel')
for sg in [-1,1]:
 plate('Pack ochre side armour',(sg*.195,-.400,1.37),(.06,.06,.30),'brass')
 for z in [1.23,1.49]:bolt((sg*.195,-.437,z),.010)
 line('Back jacket shoulder seam',[(sg*.10,-.12,1.64),(sg*.23,-.135,1.58),(sg*.31,-.115,1.48)],.0035,'brass')
# Smooth dense cloth surfaces with broad sculpted folds, still real exported meshes.
for ob in parts:
 if ob.name.startswith(('Cargo thigh','Trouser gathered calf','Jacket articulated sleeve','Tailored cropped jacket')):
  bpy.context.view_layer.objects.active=ob
  mod=ob.modifiers.new('Cloth surface refinement','SUBSURF');mod.levels=1
  bpy.ops.object.modifier_apply(modifier=mod.name)
# Independent torso, head, hands and feet; all actions share one deforming mesh.
bones['spine']=((0,0,1.18),(0,0,1.67),'root')
bones['head']=((0,0,1.74),(0,0,2.13),'spine')
for side,sg in [('L',-1),('R',1)]:
 h,t,_=bones['arm'+side];bones['arm'+side]=(h,t,'spine')
 bones['foot'+side]=((sg*.143,0,.15),(sg*.143,.22,.10),'shin'+side)
 bones['hand'+side]=((sg*.445,.01,1.09),(sg*.458,.03,.97),'fore'+side)
head_prefix=('Sculpted face','Ear','Upper eyelash','Eye','Amber iris','Pupil','Arched brow','Freckle','Nose','Nostril','Smile','Lower lip','Hair','Layered sculpted hair','Temple hair','Goggle','Blue glass','Lens')
boot_prefix=('Sculpted rubber','Rounded boot','Shaped leather boot','Mustard ankle','Rubber toe','Padded boot','Boot','Outsole')
for ob in parts:
 bone=assign[ob.name]
 center=ob.matrix_world@(sum((v.co for v in ob.data.vertices),Vector())/len(ob.data.vertices))
 if bone=='root':
  if ob.name.startswith(head_prefix) or (center.z>1.80 and not ob.name.startswith(('Drill','Backpack'))):bone='head'
  elif center.z>1.20:bone='spine'
 if bone.startswith('shin') and (ob.name.startswith(boot_prefix) or center.z<.155):bone='foot'+bone[-1]
 if bone.startswith('fore') and ob.name.startswith(('Glove','Gloved','Individual glove')):bone='hand'+bone[-1]
 assign[ob.name]=bone
 # Graded torso weights keep the jacket joined to the pelvis during twists.
 if ob.name.startswith(('Cargo thigh','Trouser gathered calf')):
  side=bone[-1];groups={n:ob.vertex_groups.new(name=n) for n in ['thigh'+side,'shin'+side]}
  for v in ob.data.vertices:
   z=(ob.matrix_world@v.co).z;w=max(0,min(1,(z-.51)/.14));w=w*w*(3-2*w)
   if w>0:groups['thigh'+side].add([v.index],w,'REPLACE')
   if w<1:groups['shin'+side].add([v.index],1-w,'REPLACE')
 elif ob.name.startswith(('Shirt','Tailored cropped jacket')):
  groups={n:ob.vertex_groups.new(name=n) for n in ['root','spine']}
  for v in ob.data.vertices:
   z=(ob.matrix_world@v.co).z;w=max(0,min(1,(z-1.13)/.25));w=w*w*(3-2*w)
   if w<1:groups['root'].add([v.index],1-w,'REPLACE')
   if w>0:groups['spine'].add([v.index],w,'REPLACE')
 else:
  g=ob.vertex_groups.new(name=bone);g.add(list(range(len(ob.data.vertices))),1,'REPLACE')
# Join by articulated region, retaining weights and editable materials.
groups={}
for ob in parts:groups.setdefault(assign[ob.name],[]).append(ob)
parts=[]
for bone,objects in groups.items():parts.append(join_objects(objects,bone+'Mesh'))
bpy.ops.object.armature_add();rig=bpy.context.object;rig.name='DrillDropHeroRig'
bpy.ops.object.mode_set(mode='EDIT');root=rig.data.edit_bones[0];root.name='root';root.head=(0,0,1.02);root.tail=(0,0,1.18)
# Parents must precede children, since spine was appended after arms.
for name,(h,t,parent) in bones.items():
 b=rig.data.edit_bones.new(name);b.head=h;b.tail=t
for name,(h,t,parent) in bones.items():rig.data.edit_bones[name].parent=rig.data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
for ob in parts:
 ob.parent=rig;mod=ob.modifiers.new('Smooth skeletal deformation','ARMATURE');mod.object=rig
parts.append(rig)
# All angular values are local bone radians; local root Y is world up.
FPS=30;bpy.context.scene.render.fps=FPS
clips={'idle':60,'run':24,'sprint':20,'jump':24,'fall':24,'land':8,'slide':24,'lane_left':8,'lane_right':8,'lane':8,'boost':18,'hit':30,'victory':60}
def pose(name,t):
 angles={n:[0.,0.,0.] for n in ['root']+list(bones)};loc=[0.,0.,0.]
 phase=t*math.tau
 if name in ['idle','victory']:
  angles['spine'][0]=.022*math.sin(phase);angles['head'][1]=.08*math.sin(phase)
  for side,sg in [('L',1),('R',-1)]:angles['arm'+side][2]=sg*.06
 if name in ['run','sprint','lane','lane_left','lane_right','boost']:
  fast=name=='sprint';stride=.78 if fast else .62
  angles['root'][0]=-.13 if fast else -.08
  loc[1]=-.075+.012*math.cos(phase*2)
  angles['spine'][1]=.10*math.sin(phase)
  angles['head'][1]=-.065*math.sin(phase)
  for side,sg in [('L',1),('R',-1)]:
   swing=math.sin(phase)*sg
   u=(t+(0 if side=='L' else .5))%1.0
   if u<.56:
    foot_y=.31-.62*u/.56;foot_z=.15
   else:
    swing_t=(u-.56)/.44;foot_y=-.31+.62*swing_t;foot_z=.15+.38*math.sin(math.pi*swing_t)
   dz=1.02+loc[1]-foot_z;distance=min(.868,max(.12,math.hypot(foot_y,dz)))
   hip=math.atan2(foot_y,dz)+math.acos(max(-1,min(1,(.45**2+distance**2-.42**2)/(2*.45*distance))))
   knee=-math.acos(max(-1,min(1,(distance**2-.45**2-.42**2)/(2*.45*.42))))
   angles['thigh'+side][0]=hip-angles['root'][0]
   angles['shin'+side][0]=knee
   angles['foot'+side][0]=-hip-knee
   angles['arm'+side][0]=-swing*.7
   angles['fore'+side][0]=1.05+.22*swing
   angles['hand'+side][0]=.12
  if name.startswith('lane'):
   direction=-1 if name=='lane_left' else 1
   angles['root'][2]=direction*.20*math.sin(t*math.pi)
   angles['spine'][2]=-direction*.10*math.sin(t*math.pi)
  if name=='boost':
   angles['root'][0]=-.42;angles['spine'][0]=-.15
   for side in ['L','R']:angles['arm'+side][0]=1.3;angles['fore'+side][0]=.75
 if name in ['jump','fall','land']:
  angles['root'][0]=-.16;angles['spine'][0]=-.10
  for side,sg in [('L',1),('R',-1)]:
   angles['thigh'+side][0]=.75 if name=='jump' else .30
   angles['shin'+side][0]=-1.05 if name=='jump' else -.4
   angles['arm'+side][0]=.75;angles['fore'+side][0]=.8
  if name=='land':
   w=math.sin(t*math.pi);loc[1]=-.13*w
   for side in ['L','R']:angles['thigh'+side][0]=.55*w;angles['shin'+side][0]=-1.05*w
 if name in ['slide','hit']:
  # Dive forward, chest low, legs trailing as in supplied prone reference.
  w=min(1,t/.17) if name=='hit' else min(1,t/.16,(1-t)/.14)
  w=max(0,w);w=w*w*(3-2*w)
  angles['root'][0]=-1.40*w;loc[1]=-.76*w
  angles['spine'][0]=-.08*w;angles['head'][0]=.20*w
  for side in ['L','R']:
   angles['thigh'+side][0]=.08*w;angles['shin'+side][0]=-.12*w
   angles['arm'+side][0]=(-3.00 if side=='L' else -2.40)*w
   angles['arm'+side][2]=(.10 if side=='L' else -.24)*w
   angles['fore'+side][0]=(-.10 if side=='L' else -1.20)*w
   angles['hand'+side][0]=.14*w
 if name=='victory':
  w=math.sin(min(1,t*2)*math.pi/2)
  angles['armL'][2]=1.8*w;angles['foreL'][0]=-.75*w
  angles['spine'][1]=.16*math.sin(phase);angles['head'][1]=-.16*math.sin(phase)
 return angles,loc
for name,frames in clips.items():
 rig.animation_data_create();action=bpy.data.actions.new(name);rig.animation_data.action=action
 for f in range(frames+1):
  angles,loc=pose(name,f/frames)
  for bone in rig.pose.bones:
   bone.rotation_mode='XYZ';bone.rotation_euler=angles[bone.name]
   bone.location=loc if bone.name=='root' else (0,0,0)
   bone.keyframe_insert('rotation_euler',frame=f+1);bone.keyframe_insert('location',frame=f+1)
 track=rig.animation_data.nla_tracks.new();track.name=name;track.strips.new(name,1,action);rig.animation_data.action=None
# Embedded reference boards stay out of game exports.
for n in ['gold','teal']:
 for node in mats[n].node_tree.nodes:
  if node.type=='NORMAL_MAP':node.inputs['Strength'].default_value=.07
save_asset('explorer',rig)
for ob in bpy.data.collections['explorer'].objects:ob.hide_set(False)
guides=bpy.data.collections.new('Motion references');bpy.context.scene.collection.children.link(guides)
for i,name in enumerate(['standing','running','prone-slide']):
 image=bpy.data.images.load(ROOT+'/Art/References/HeroMotion/'+name+'.png');image.pack()
 ob=bpy.data.objects.new(name,None);ob.empty_display_type='IMAGE';ob.data=image;ob.empty_display_size=2.8;ob.location=(-3.4+i*3.4,2,1.3);ob.rotation_euler=(math.pi/2,0,0);ob.hide_render=True;guides.objects.link(ob)
for b in rig.pose.bones:b.rotation_euler=(0,0,0);b.location=(0,0,0)
bpy.context.scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/Art/Blender/hero_motion.blend')
open(ROOT+'/Tests/HeroMotion/source-manifest.json','w').write(json.dumps({'bones':len(rig.data.bones),'clips':clips,'triangles':stats['explorer']['triangles']},indent=2))
