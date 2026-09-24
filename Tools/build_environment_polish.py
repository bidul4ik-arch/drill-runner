"""Build the three game environments only. Blender 5.x, deterministic 24 m tiles.
Preserves hero, bosses and shared textures. Same geometry in .blend and GLB.
"""
import ast, os, math, random, json
import bpy
import numpy as np
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT=ROOT+'/Art'
rng=random.Random(2409);parts=[];assign={};mats={};stats={}
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
# Reuse modelling primitives without executing the old generators or writing textures.
for filename in ['build_assets.py','build_reference_assets.py']:
 tree=ast.parse(open(ROOT+'/Tools/'+filename).read())
 funcs=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name!='material']
 exec(compile(ast.Module(body=funcs,type_ignores=[]),filename,'exec'))
def material(name,color,metal=0,rough=.7,emission=0):
 m=bpy.data.materials.new('Environment / '+name);m.use_nodes=True;m.diffuse_color=(*color,1)
 m.node_tree.nodes.clear();p=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled');p.name='Surface';out=m.node_tree.nodes.new('ShaderNodeOutputMaterial');m.node_tree.links.new(p.outputs['BSDF'],out.inputs['Surface']);p.inputs['Base Color'].default_value=(*color,1)
 p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=emission
 mats[name]=m
for args in [
 ('wood',(.23,.083,.027)),('rock',(.23,.135,.085)),('cave_rock',(.055,.105,.14)),
 ('sand',(.48,.295,.145)),('steel',(.055,.083,.095),.5,.45),('edge',(.27,.32,.33),.65,.3),
 ('paint',(.025,.16,.185),.35,.4),('brass',(.56,.285,.07),.5,.38),('leather',(.065,.027,.012)),
 ('cyan',(.012,.52,.72),.18,.22,.15),('crystal_dark',(.008,.21,.32),.15,.3,.18),
 ('crystal_light',(.12,.78,.9),.12,.2,.12),('lamp',(1,.48,.09),0,.3,3),
 ('teal',(.028,.13,.16)),('dark',(.018,.025,.032)),('silver',(.32,.38,.4),.65,.28)]:material(*args)
for i, c in enumerate([(.45,.275,.14),(.49,.30,.16),(.46,.285,.15),(.51,.32,.17)]):material('paving'+str(i),c)

# Restrained grain uses existing authored texture; no changes to hero materials.
wood=mats['wood'];tex=wood.node_tree.nodes.new('ShaderNodeTexImage')
tex.image=bpy.data.images.load(OUT+'/Textures/wood_albedo.png');tex.image.pack()
wood.node_tree.links.new(tex.outputs['Color'],wood.node_tree.nodes.get('Surface').inputs['Base Color'])
# Gentle large-scale mineral mottling, shared by all road tiles.
size=256;yy,xx=np.mgrid[0:size,0:size]
v=.94+.035*np.sin(xx*.039+np.sin(yy*.024)*2)+.024*np.sin(yy*.066+xx*.02)
for i in range(4):
 m=mats['paving'+str(i)];p=m.node_tree.nodes.get('Surface')
 tint=np.array(p.inputs['Base Color'].default_value[:3])**(1/2.2)
 img=bpy.data.images.new('Sandstone '+str(i),width=size,height=size)
 a=np.ones((size,size,4),dtype=np.float32);a[:,:,:3]=np.clip(v[:,:,None]*tint,0,1)
 img.pixels.foreach_set(a.ravel());img.filepath_raw=OUT+'/Textures/environment_sandstone_'+str(i)+'.png';img.file_format='PNG';img.save();img.pack()
 t=m.node_tree.nodes.new('ShaderNodeTexImage');t.image=img
 m.node_tree.links.new(t.outputs['Color'],p.inputs['Base Color']);p.inputs['Base Color'].default_value=(1,1,1,1)

def cliff(side,y,mat):
 # Large asymmetrical stone faces, bevelled at the silhouette rather than cubic walls.
 for j in range(4):
  z=.9+j*2.4
  for k in range(2):
   cy=y+(k-.5)*2.55
   outline=[(-1.42,-.82),(-.78,-1.28),(.92,-1.18),(1.43,-.38),(1.26,.91),(.18,1.30),(-1.31,.78)]
   vs=[]
   for depth in [0,1.8]:
    for i,(dy,dz) in enumerate(outline):
     x=side*(4.52+depth+.16*math.sin(i*1.7+j+k))
     vs.append((x,cy+dy,z+dz))
   n=len(outline);faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
   for i in range(n):faces.append((i,(i+1)%n,(i+1)%n+n,i+n))
   o=mesh_obj('Hewn rock face',vs,faces,mat)
   bevel=o.modifiers.new('Rounded fractured edges','BEVEL');bevel.width=.12;bevel.segments=2
   bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=bevel.name)
   if j==1:box('Stratified rock shelf',(side*4.67,cy,z-1.0),(.64,2.4,.17),mat,bevel=.06)

def paving():
 box('Continuous road foundation',(0,0,-.20),(8.5,24,.36),'rock')
 for row in range(12):
  for i,x in enumerate([-2.5,0,2.5]):
   # Continuous clean lane surfaces, broad bevels and understated joints.
   box('Hewn sandstone road',(x,-11+row*2,-.045),(2.48,1.985,.13),'paving'+str((row*3+i)%4),bevel=.025)
 for x in [-3.76,-1.25,1.25,3.76]:
  box('Rail foundation',(x,0,.005),(.18,24,.045),'wood',bevel=.008)
  box('Continuous polished rail',(x,0,.043),(.075,24,.055),'edge',bevel=.012)
  for y in range(-11,12,2):
   box('Rail saddle',(x,y,.013),(.31,.20,.045),'steel',bevel=.014)
 for side in [-1,1]:
  for y in range(-11,12,2):
   box('Track curb',(side*4.05,y,.12),(.34,1.94,.29),'rock',bevel=.075)

def vault(cave,factory):
 mat='cave_rock' if cave else 'rock'
 # Continuous inward-facing upper shell; radius gives >8 m clearance over all lanes.
 vs=[];fs=[];segments=16
 for y in [-12,12]:
  for k in range(segments+1):
   a=math.pi*k/segments
   vs.append((5.8*math.cos(a),y,7.0+3.3*math.sin(a)))
 for k in range(segments):fs.append((k,k+1,segments+2+k,segments+1+k))
 mesh_obj('Continuous cavern vault',vs,fs,mat)
 for y in [-6,6]:
  points=[(5.65*math.cos(math.pi*k/8),y,7.0+3.12*math.sin(math.pi*k/8)) for k in range(9)]
  for a,b in zip(points,points[1:]):
   if factory:rod('Vault structural rib',a,b,.13,'paint',verts=8)
   else:beam('Vault timber rib',a,b,.22,.26)
 # Thin hanging service cables follow the motion direction, far above the runner.
 for side in [-1,1]:
  pts=[(side*3.4,-12+k*2,7.4-.32*math.sin(k*math.pi/12)) for k in range(13)]
  line('Suspended service cable',pts,.024,'dark')

source=open(ROOT+'/Tools/build_reference_assets.py').read()
block=source[source.index("for name in ['track','crystal_track','industrial_track']:"):source.index('# BOSSES:')]
block=block.replace(' save_asset(name)',' vault(cave,factory)\n save_asset(name)')
exec(block)
# Keep sources inspectable with a named collection per level, only first visible by default.
for o in bpy.data.objects:
 o.hide_set(o.name!='track');o.hide_render=o.name!='track'
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/Blender/environment_polish.blend')
open(ROOT+'/Tests/Environment/assets.json','w').write(json.dumps(stats,indent=2))
print('ENVIRONMENT_BUILD_OK',stats)
