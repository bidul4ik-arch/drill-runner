"""Reference-led organic face, tailored silhouette, soft pockets and wearable cap."""
import os,bpy,math
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
source=open(ROOT+'/Tools/build_hero_motion.py').read()
# Replace the original face loft with a continuous cheek / nose surface.
insert='''
original_loft=loft
def loft(name,rings,mat,bone='root',sides=24,fold=0):
 if name!='Sculpted face':return original_loft(name,rings,mat,bone,sides,fold)
 vs=[];fs=[];rows=45;segments=64
 for j in range(rows):
  z=1.752+j/(rows-1)*.386
  # Interpolate the anatomical reference profile instead of a spherical toy head.
  k=next((k for k in range(len(rings)-1) if rings[k+1][2]>=z),len(rings)-2)
  a,b=rings[k],rings[k+1];t=max(0,min(1,(z-a[2])/(b[2]-a[2])))
  cx,cy,_,rx,ry=[a[i]*(1-t)+b[i]*t for i in range(5)]
  rx*=.97
  for i in range(segments):
   angle=i*math.tau/segments;x=rx*math.cos(angle);y=cy+ry*math.sin(angle)
   front=max(0,math.sin(angle))**10
   nose=.039*math.exp(-(x/.029)**2-((z-1.916)/.032)**2)
   cheek=.012*(math.exp(-((x-.102)/.047)**2)+math.exp(-((x+.102)/.047)**2))*math.exp(-((z-1.891)/.051)**2)
   sockets=-.009*(math.exp(-((x-.078)/.040)**2)+math.exp(-((x+.078)/.040)**2))*math.exp(-((z-1.957)/.034)**2)
   y+=front*(nose+cheek+sockets)
   vs.append((x,y,z))
 for j in range(rows-1):
  for i in range(segments):fs.append((j*segments+i,j*segments+(i+1)%segments,(j+1)*segments+(i+1)%segments,(j+1)*segments+i))
 return mesh_obj(name,vs,fs,mat,bone,True)
'''
source=source.replace("hero=src[src.index('# HERO:')",insert+"\nhero=src[src.index('# HERO:')")
# Preserve the proven rig / clip library, change the authored meshes before skinning.
marker='exec(hero)'
changes='''
hero=hero.replace("(0,0,1.08,.22,.14)","(0,0,1.205,.179,.133)").replace("(0,0,1.19,.205,.14)","(0,0,1.24,.193,.14)")
hero=hero.replace("(.235,.17),(.24,.18),(.245,.18)","(.195,.155),(.205,.16),(.23,.175)")
hero=hero.replace("(0,0,1.12,.238,.151)","(0,0,1.12,.211,.146)")
hero=hero.replace("(.068,.21,.19)","(.068,.21,.22)")
hero=hero.replace(".088,'skin',verts=24",".076,'skin',verts=32")
hero='\\n'.join(line for line in hero.split('\\n') if not line.startswith("loft('Nose bridge'"))
exec(hero)
loft('Exposed midriff',[(0,0,1.11,.200,.139),(0,0,1.205,.170,.126),(0,0,1.25,.180,.130)],'skin')
'''
source=source.replace(marker,changes,1)

# The reference refinement is applied before weights and the shared rig are built.
source=source.replace("hero=src[src.index('# HERO:')", "exec(open(ROOT+'/Tools/hero_surface_details.py').read())\nhero=src[src.index('# HERO:')",1)
source=source.replace("exec(hero)\nloft('Exposed midriff'", "exec(hero)\nfinish_reference_details()\nloft('Exposed midriff'",1)
source=source.replace("zs=[1.16,1.18,1.27,1.40,1.53,1.61,1.66]", "zs=[1.29,1.30,1.36,1.43,1.53,1.61,1.66]")
# The quoted hero body is loaded later; edits belong in its runtime construction.
source=source.replace("hero=hero.replace(\"(0,0,1.08", "hero=hero.replace('zs=[1.16,1.18,1.27,1.40,1.53,1.61,1.66]','zs=[1.29,1.30,1.36,1.43,1.53,1.61,1.66]')\nhero=hero.replace(\"(0,0,1.08",1)
source=source.replace('hero=hero.replace("(0,0,1.08','hero=hero.replace("(sign*.066,.175,1.18)","(sign*.066,.175,1.30)")\nhero=hero.replace("(0,0,1.08',1)
new_hair = """
ell('Hair undercut',(0,-.035,2.055),(.205,.185,.155),'hair')
# Overlapping broad locks follow the skull, with swept fringe over the forehead.
for band in range(3):
 for j in range(14):
  a=j*math.tau/14+band*.19
  if band>0 and math.sin(a)>.25:continue
  r=.09+band*.043
  start=(math.cos(a)*r*.65,math.sin(a)*r*.60-.035,2.20-band*.045)
  middle=(math.cos(a)*(.20+band*.01)+.024,math.sin(a)*(.19+band*.012)-.035,2.20-band*.063)
  tip=(math.cos(a+.16)*(.235+band*.006)+.03,math.sin(a+.16)*(.21+band*.005)-.035,2.11-band*.083+(j%3)*.018)
  hair_lock(start,middle,tip,.045+(j%3)*.008)
for j in range(6):
 x=-.15+j*.043
 hair_lock((x-.035,-.025,2.17),(x+.04,-.015,2.38-(j%3)*.02),(x+.14,-.025,2.26-(j%2)*.025),.059)
for j in range(3):
 x=-.12+j*.067
 hair_lock((x-.035,.10,2.20),(x+.10,.20,2.19),(x+.09,.181,2.04+j*.021),.045)
"""
a=source.index('hair_code=');b=source.index('hero=hero[:hair_start]',a)
source=source[:a]+'hair_code='+repr(new_hair)+'\n'+source[b:]

source=source.replace("/Art/Blender/hero_motion.blend","/Art/Blender/hero_reference_final.blend")
source=source.replace(" assign[ob.name]=bone\n", " assign[ob.name]=bone\n if bone=='head':\n  for v in ob.data.vertices:\n   w=ob.matrix_world@v.co;w.x*=.90;w.y*=.90;w.z=1.74+(w.z-1.74)*.90;v.co=ob.matrix_world.inverted()@w\n",1)
exec(compile(source,__file__,'exec'))
# Cap is independently skinned to the head; hidden until equipped by Profile.
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
vs=[];fs=[];segments=40;rings=12
for j in range(rings):
 a=(j/(rings-1))*math.pi/2
 for i in range(segments):
  t=i*math.tau/segments
  vs.append((.235*math.cos(a)*math.cos(t),-.015+.218*math.cos(a)*math.sin(t),2.083+.235*math.sin(a)))
for j in range(rings-1):
 for i in range(segments):fs.append((j*segments+i,j*segments+(i+1)%segments,(j+1)*segments+(i+1)%segments,(j+1)*segments+i))
parts=[]
mesh_obj('Cap crown',vs,fs,'teal','head',True)
# Curved visor has thickness and a rounded gold seam.
vs=[];fs=[]
for row in range(5):
 for i in range(25):
  a=-1.2+i/24*2.4;r=.20+row/4*.19
  vs.append((math.sin(a)*r*.73,math.cos(a)*r,2.09-.035*(row/4)+.018*math.sin(a)**2))
for row in range(4):
 for i in range(24):fs.append((row*25+i,row*25+i+1,(row+1)*25+i+1,(row+1)*25+i))
ob=mesh_obj('Cap visor',vs,fs,'gold','head',True)
mod=ob.modifiers.new('Visor thickness','SOLIDIFY');mod.thickness=.015;bpy.context.view_layer.objects.active=ob;bpy.ops.object.modifier_apply(modifier=mod.name)
cap=join_objects(parts,'CapAccessory')
for v in cap.data.vertices:v.co.x*=.90;v.co.y*=.90;v.co.z=1.74+(v.co.z-1.74)*.90
cap.parent=rig;g=cap.vertex_groups.new(name='head');g.add(list(range(len(cap.data.vertices))),1,'REPLACE');mod=cap.modifiers.new('Follow animated head','ARMATURE');mod.object=rig
for col in list(cap.users_collection):col.objects.unlink(cap)
bpy.data.collections['explorer'].objects.link(cap)
bpy.ops.object.select_all(action='DESELECT')
for ob in bpy.data.collections['explorer'].objects:ob.hide_set(False);ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=ROOT+'/Art/Models/explorer.glb',use_selection=True,export_format='GLB',export_animations=True)
from fix_cloth_factors import fix
fix(ROOT+'/Art/Models/explorer.glb')
cap.hide_set(True)
img=bpy.data.images.load(ROOT+'/Art/References/HeroMotion/approved-final.png',check_existing=True);img.pack()
bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/Art/Blender/hero_reference_final.blend')
