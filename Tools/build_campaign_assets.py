import os
source=open(os.path.join(os.path.dirname(__file__),'build_assets.py')).read().split('# Explorer:')[0]
exec(source)
# Environment modules compatible with the original eight-chunk belt.
for name in ['crystal_track','industrial_track']:
 box('Floor',(0,0,-.18),(8.5,24,.35),'sand' if name=='crystal_track' else 'steel')
 for x in [-3.7,-1.25,1.25,3.7]:box('Rail',(x,0,.025),(.09,24,.07),'gold')
 for side in [-1,1]:
  for y in [-9,-3,3,9]:
   if name=='crystal_track':
    o=stone('CaveWall',(side*6,y,4),(2,3.5,5));o.rotation_euler=(0,.05,.03)
    for j in range(4):crystal((side*(4.2+j*.3),y+j*.3,.2),.7+j*.55)
   else:
    box('MachineWall',(side*5.0,y,2.8),(1.8,5.7,5.6),'teal')
    for z in [.5,2,4.3]:rod('Conduit',(side*4.0,y-3,z),(side*4.0,y+3,z),.18,'silver')
    box('Pillar',(side*4.0,y,3.5),(.45,.6,7),'steel')
    box('Warning',(side*3.7,y,2.7),(.12,.65,.6),'gold')
    rod('Vent',(side*3.9,y,1.8),(side*3.65,y,1.8),.6,'dark',verts=16)
  if name=='industrial_track':
   for y in [-6,6]:box('Gantry',(0,y,6.5),(9,.6,.5),'steel')
 export(name)
# Additional hazard models (same collision envelopes as original hazards).
box('Void',(0,0,.025),(1.9,2.0,.04),'dark')
for x in [-.97,.97]:
 for y in [-.8,-.3,.3,.8]:stone('BrokenLip',(x,y,.12),(.17,.24,.13),'sand')
export('gap')
for p,s in [((0,0,.55),(.65,.5,.55)),((-.45,0,.35),(.4,.5,.4)),((.4,.1,1.1),(.35,.38,.5))]:stone('FallingRocks',p,s,'rock')
export('falling_rocks')
box('Base',(0,0,.1),(1.6,1.2,.2),'steel');box('Piston',(0,0,1),(1.55,.6,1.8),'teal')
for z in [.4,.8,1.2,1.6]:box('DangerStripe',(0,-.32,z),(1.5,.035,.1),'gold')
export('moving_gate')
# Crystal guardian attacks use crystal silhouettes rather than mining props.
for n,height in [('crystal_wave',.65),('crystal_wall',1.5)]:
 for x in [-.6,0,.6]:crystal((x,0,.05),height)
 export(n)
rod('CrystalBeam',(-.95,0,1.65),(.95,0,1.65),.26,'cyan',verts=6)
export('crystal_beam')
rod('DrillLance',(0,.8,1.2),(0,-.9,1.2),.95,'silver',r2=0,verts=12)
for i in range(4):rod('SpiralBand',(0,.65-i*.3,1.2),(0,.55-i*.3,1.2),.85-i*.17,'dark',verts=12)
export('drill_attack')
# Bosses have separately animated body / two arms, grouped to reduce draw calls.
def collapse_group(start,name,pivot):
 global parts
 subset=parts[start:];o=join_objects(subset,name);parts=parts[:start]+[o]
 bpy.context.scene.cursor.location=pivot;bpy.context.view_layer.objects.active=o;bpy.ops.object.origin_set(type='ORIGIN_CURSOR');return o
for name in ['mining_robot','crystal_guardian','giant_drill']:
 if name=='mining_robot':
  box('Torso',(0,0,2.4),(2.5,1.7,2.5),'teal',bevel=.2)
  box('Head',(0,0,4),(1.5,1.3,.9),'steel',bevel=.15)
  for x in [-.4,.4]:ell('Eye',(x,-.7,4.1),(.2,.1,.12),'lamp')
  for x in [-.85,.85]:box('Tread',(x,0,.5),(.8,2.5,.85),'dark')
 elif name=='crystal_guardian':
  stone('Body',(0,0,2.5),(1.5,1,1.8),'teal');stone('Head',(0,0,4.3),(.8,.6,.7),'cyan')
  for x in [-1,0,1]:crystal((x,.2,3.5),1.2)
  for x in [-.3,.3]:ell('Eye',(x,-.6,4.4),(.12,.08,.08),'lamp')
 else:
  box('Chassis',(0,0,1.7),(4.8,2.8,2.3),'teal',bevel=.2)
  for x in [-2.1,2.1]:box('Tread',(x,0,.55),(1.0,3.8,1),'dark')
  rod('MainDrill',(0,-1.4,2.2),(0,-4.3,2.2),1.0,'silver',r2=0,verts=16)
  for j in range(6):rod('Spiral',(0,-1.6-j*.37,2.2),(0,-1.7-j*.37,2.2),.92-j*.13,'dark',verts=12)
  for x in [-1.5,1.5]:ell('Headlight',(x,-1.45,3),(.25,.12,.18),'lamp')
 ell('Reactor',(0,-.95 if name!='giant_drill' else -1.5,2.7),(.45,.15,.45),'gold')
 body=collapse_group(0,'BossBody',(0,0,0));arms=[]
 for side in [-1,1]:
  start=len(parts);x=side*1.4
  if name=='crystal_guardian':
   for j in range(3):stone('ShardArm',(x+side*j*.5,0,3-j*.3),(.55,.55,.65),'cyan')
  else:
   rod('Hydraulic',(x,0,3.2),(side*2.8,0,2.4),.28,'steel')
   rod('Piston',(side*2.8,0,2.4),(side*3,-.5,1.3),.24,'silver')
   box('Claw',(side*3,-.5,1.2),(1.1,.9,.55),'gold')
  arms.append(collapse_group(start,'ArmLeft' if side<0 else 'ArmRight',(x,0,3.2)))
 # Native Blender actions survive as named GLB clips. Runtime also positions boss by battle state.
 for clip in ['idle','attack','hurt','defeat']:
  for index,obj in enumerate([body]+arms):
   obj.animation_data_create();obj.animation_data.action=bpy.data.actions.new(clip)
   base=obj.location.copy()
   for frame,t in [(1,0),(13,.5),(25,1)]:
    obj.rotation_euler=(0,0,0);obj.location=base.copy();obj.scale=(1,1,1)
    if clip=='idle':obj.location.z+=.1*math.sin(t*math.pi)
    if clip=='attack' and index>0:obj.rotation_euler.y=(1 if index==1 else -1)*.8*math.sin(t*math.pi)
    if clip=='hurt':obj.rotation_euler.x=.18*math.sin(t*math.pi)
    if clip=='defeat':obj.rotation_euler.x=t*1.2;obj.location.z-=t*.6
    obj.keyframe_insert('location',frame=frame);obj.keyframe_insert('rotation_euler',frame=frame)
   track=obj.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,1,obj.animation_data.action);obj.animation_data.action=None;obj.location=base;obj.rotation_euler=(0,0,0)
 export(name,rig=True)
# Cozy home, open front for camera; hero stands at origin.
box('Floor',(0,0,-.16),(10,9,.3),'wood')
box('BackWall',(0,3.8,2.3),(10,.3,4.6),'sand');box('LeftWall',(-4.8,0,2.3),(.3,8,4.6),'wood')
for x in [-4,0,4]:box('Beam',(x,3.5,2.3),(.25,.25,4.6),'wood')
box('Workbench',(-2.6,2,1.05),(2.8,1.3,.18),'wood')
for x in [-3.7,-1.5]:box('BenchLeg',(x,2,.5),(.18,.9,1),'steel')
crystal((-2.9,2,1.15),.5);rod('Tool',(-2,1.8,1.2),(-1.5,1.8,1.2),.1,'silver')
box('Wardrobe',(3,2.5,1.5),(2,1.3,3),'teal')
for x in [2.55,3.45]:box('Door',(x,1.8,1.5),(.82,.12,2.75),'wood');ell('Handle',(x,1.7,1.5),(.06,.04,.06),'gold')
box('Rug',(0,0,.02),(3.2,2.7,.035),'teal')
for x in [-3.8,3.8]:rod('Lamp',(x,3,2.7),(x,3,3.2),.2,'lamp')
export('home')
for col in bpy.data.collections:
 col.hide_viewport=False
 for o in col.objects:o.hide_set(False)
bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/Art/Blender/campaign.blend')
print('CAMPAIGN ASSETS READY')
