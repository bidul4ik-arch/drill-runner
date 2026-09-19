"""DrillDrop reference revision: authored lofts, clothing, hard-surface assemblies.
Blender source and GLB use the same meshes/materials/animations, no render stand-ins.
Run Blender --background --python Tools/build_reference_assets.py.
"""
import os, math, random, json
import bpy, numpy as np
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
exec(open(ROOT+'/Tools/build_assets.py').read().split('# Explorer:')[0])
OUT=ROOT+'/Art'
# UV texture maps shared by the exported game materials, including roughness/normal.
def material(name, color, metal=0, rough=.65, emission=0, family='paint'):
 m=mats.get(name) or bpy.data.materials.new(name);mats[name]=m
 m.diffuse_color=(*color,1);m.use_nodes=True;n=m.node_tree.nodes;n.clear()
 p=n.new('ShaderNodeBsdfPrincipled');o=n.new('ShaderNodeOutputMaterial');m.node_tree.links.new(p.outputs['BSDF'],o.inputs['Surface'])
 p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 if emission:p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=emission
 if family is None:return m
 size=512;yy,xx=np.mgrid[0:size,0:size];r=np.random.default_rng(sum(map(ord,name))+73)
 noise=r.random((size,size));broad=(np.sin(xx*.032+np.sin(yy*.013)*2)+np.sin(yy*.045+xx*.011))*.5
 value=.84+.055*broad+.045*noise
 if family=='wood':
  grain=np.sin(xx*.38+np.sin(yy*.018)*3+np.sin(xx*.016)*7)
  value=.70+.18*grain+.09*noise+.08*broad
 elif family=='cloth':value=.91+.016*(np.sin(xx*2.3)+np.sin(yy*2.3))+.015*noise+.035*broad
 elif family=='rock':value=.84+.10*broad+.065*noise+.045*np.sin(xx*.13)*np.sin(yy*.17)
 elif family=='paint':
  scratches=(np.sin(xx*.51+np.sin(yy*.11))>.995)&(noise>.55)
  value=.88+.05*broad+.035*noise-scratches*.38
 def texture(suffix,rgb,noncolor=False):
  a=np.ones((size,size,4),dtype=np.float32);a[:,:,:3]=rgb if rgb.ndim==3 else rgb[:,:,None]
  img=bpy.data.images.new(name+'_'+suffix,width=size,height=size)
  if noncolor:img.colorspace_settings.name='Non-Color'
  img.pixels.foreach_set(a.ravel());img.filepath_raw=OUT+'/Textures/'+name+'_'+suffix+'.png';img.file_format='PNG';img.save();img.pack()
  node=n.new('ShaderNodeTexImage');node.image=img;return node
 if name in ['gold','teal']:
  tex=texture('albedo',np.clip(value,0,1))
  mult=n.new('ShaderNodeMixRGB');mult.blend_type='MULTIPLY';mult.inputs[0].default_value=1;mult.inputs[2].default_value=(*color,1)
  m.node_tree.links.new(tex.outputs['Color'],mult.inputs[1]);m.node_tree.links.new(mult.outputs[0],p.inputs['Base Color'])
 else:
  tint=np.array(color)**(1/2.2);rgb=np.clip(value[:,:,None]*tint,0,1)
  if name=='paint':
   wear=(np.sin(xx*.039+np.sin(yy*.022)*2)+np.sin(yy*.048+np.cos(xx*.051)))>1.70
   rgb[wear]=np.array([.29,.21,.12])*(.7+.3*noise[wear,None])
  tex=texture('albedo',rgb);m.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color'])
 p.inputs['Base Color'].default_value=(1,1,1,1)
 rt=texture('roughness',np.clip(rough+(noise-.5)*.1,0,1),True);m.node_tree.links.new(rt.outputs['Color'],p.inputs['Roughness'])
 dy,dx=np.gradient(value);normal=np.stack([-dx*.65,-dy*.65,np.ones_like(dx)],axis=-1);normal/=np.linalg.norm(normal,axis=-1)[:,:,None];normal=normal*.5+.5
 nt=texture('normal',normal,True);nm=n.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.32;m.node_tree.links.new(nt.outputs['Color'],nm.inputs['Color']);m.node_tree.links.new(nm.outputs['Normal'],p.inputs['Normal'])
 return m
material('gold',(.52,.235,.038),rough=.78,family='cloth')
material('teal',(.025,.09,.102),rough=.77,family='cloth')
material('paint',(.027,.125,.14),metal=.55,rough=.42)
material('edge',(.22,.235,.23),metal=.8,rough=.34,family=None)
material('steel',(.065,.085,.095),metal=.75,rough=.4)
material('silver',(.32,.35,.38),metal=.84,rough=.29)
material('brass',(.42,.235,.065),metal=.72,rough=.33)
material('wood',(.20,.082,.030),rough=.84,family='wood')
material('sand',(.39,.23,.12),rough=.92,family='rock')
material('rock',(.15,.10,.07),rough=.92,family='rock')
material('cave_rock',(.060,.085,.095),rough=.84,family='rock')
material('ancient',(.37,.27,.15),rough=.80,family='rock')
material('leather',(.045,.027,.018),rough=.74,family='cloth')
material('dark',(.018,.023,.028),rough=.67,family=None)
material('sole',(.43,.41,.34),rough=.82,family=None)
material('skin',(.62,.315,.18),rough=.6,family=None)
material('lip',(.34,.105,.065),rough=.65,family=None)
material('blush',(.47,.19,.11),rough=.68,family=None)
material('hair',(.033,.020,.016),rough=.55,family=None)
material('hair_light',(.065,.035,.02),rough=.56,family=None)
material('cyan',(.012,.43,.64),metal=.28,rough=.19,emission=.35,family=None)
material('crystal_dark',(.008,.20,.25),metal=.3,rough=.24,family=None)
material('crystal_light',(.065,.65,.74),metal=.22,rough=.17,emission=.22,family=None)
material('lens',(.035,.29,.36),metal=.6,rough=.14,family=None)
material('lamp',(1,.42,.045),rough=.25,emission=2.0,family=None)
material('white',(.78,.76,.65),rough=.35,family=None)
material('iris',(.105,.052,.022),rough=.4,family=None)
material('banner',(.19,.066,.03),rough=.88,family='cloth')
# Reusable modelling vocabulary: continuous lofts and profiles rather than stacked spheres.
def mesh_obj(n,vs,fs,mat,bone='root',smooth=False,uv=True):
 me=bpy.data.meshes.new(n);me.from_pydata(vs,[],fs);me.update();ob=bpy.data.objects.new(n,me);bpy.context.collection.objects.link(ob);finish(ob,n,mat,bone,smooth)
 if uv:
  layer=me.uv_layers.new(name='UVMap')
  for poly in me.polygons:
   for li in poly.loop_indices:
    co=me.vertices[me.loops[li].vertex_index].co;layer.data[li].uv=(co.x*.7+co.y*.23,co.z*.7+co.y*.31)
 return ob
def loft(n,rings,mat,bone='root',sides=24,fold=0):
 vs=[];fs=[]
 for j,(cx,cy,z,rx,ry) in enumerate(rings):
  for k in range(sides):
   a=k*math.tau/sides;f=1+fold*math.sin(a*5+j*.8)
   vs.append((cx+rx*math.cos(a)*f,cy+ry*math.sin(a)*f,z))
 for j in range(len(rings)-1):
  for k in range(sides):fs.append((j*sides+k,j*sides+(k+1)%sides,(j+1)*sides+(k+1)%sides,(j+1)*sides+k))
 fs+=[tuple(range(sides-1,-1,-1)),tuple((len(rings)-1)*sides+k for k in range(sides))]
 return mesh_obj(n,vs,fs,mat,bone,True)
def line(n,pts,r,mat,bone='root',sides=6):
 vs=[];fs=[]
 for j,p in enumerate(pts):
  v=Vector(p);t=Vector(pts[min(j+1,len(pts)-1)])-Vector(pts[max(j-1,0)]);t.normalize();ax=t.cross(Vector((0,1,0)))
  if ax.length<.1:ax=t.cross(Vector((1,0,0)))
  ax.normalize();ay=t.cross(ax)
  for k in range(sides):vs.append(v+r*(ax*math.cos(k*math.tau/sides)+ay*math.sin(k*math.tau/sides)))
 for j in range(len(pts)-1):
  for k in range(sides):fs.append((j*sides+k,j*sides+(k+1)%sides,(j+1)*sides+(k+1)%sides,(j+1)*sides+k))
 return mesh_obj(n,vs,fs,mat,bone,True)
def ring(n,center,radius,tube,mat,axis=(0,0,1),bone='root',segments=32):
 axis=Vector(axis).normalized();q=axis.to_track_quat('Z','Y');vs=[];fs=[]
 for i in range(segments):
  a=i*math.tau/segments
  for j in range(8):
   b=j*math.tau/8;v=Vector(((radius+tube*math.cos(b))*math.cos(a),(radius+tube*math.cos(b))*math.sin(a),tube*math.sin(b)));vs.append(Vector(center)+q@v)
 for i in range(segments):
  for j in range(8):fs.append((i*8+j,i*8+(j+1)%8,((i+1)%segments)*8+(j+1)%8,((i+1)%segments)*8+j))
 return mesh_obj(n,vs,fs,mat,bone,True)
def bolt(p,r=.045,axis=(0,-1,0),mat='brass',bone='root'):
 a=Vector(p);rod('Hex fastener',a,a+Vector(axis)*r*.45,r,mat,bone,verts=6)
def plate(n,p,s,m='paint',bone='root'):
 o=box(n,p,s,m,bone,bevel=0)
 if m in ['paint','steel','brass']:
  o.data.materials.append(mats['edge'])
 mod=o.modifiers.new('Machined edge bevel','BEVEL');mod.width=min(s)*.12;mod.segments=3
 if m in ['paint','steel','brass']:mod.material=1
 bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def shield_panel(n,p,w,h,d,mat,bone='root'):
 x,y,z=p;c=min(w,h)*.19
 outline=[(-w/2+c,-h/2),(w/2-c,-h/2),(w/2,-h/2+c),(w/2,h/2-c),(w/2-c,h/2),(-w/2+c,h/2),(-w/2,h/2-c),(-w/2,-h/2+c)]
 vs=[];fs=[]
 for yy,k in [(y-d/2,1),(y+d*.30,1),(y+d/2,.91)]:
  for xx,zz in outline:vs.append((x+xx*k,yy,z+zz*k))
 for j in range(2):
  for i in range(8):fs.append((j*8+i,j*8+(i+1)%8,(j+1)*8+(i+1)%8,(j+1)*8+i))
 fs.append(tuple(range(16,24)));fs.append(tuple(range(7,-1,-1)))
 return mesh_obj(n,vs,fs,mat,bone)
def crystal2(n,a,b,r,mat='cyan',bone='root'):
 a,b=Vector(a),Vector(b);d=b-a;q=d.to_track_quat('Z','Y');vs=[];fs=[]
 for z,rad in [(0,r*.65),(.16,r),( .72,r*.84)]:
  for i in range(6):vs.append(a+q@Vector((math.cos(i*math.tau/6)*rad,math.sin(i*math.tau/6)*rad,z*d.length)))
 vs.append(b)
 fs.append(tuple(range(5,-1,-1)))
 for j in range(2):
  for i in range(6):fs.append((j*6+i,j*6+(i+1)%6,(j+1)*6+(i+1)%6,(j+1)*6+i))
 for i in range(6):fs.append((12+i,12+(i+1)%6,18))
 detailed=[]
 for face in fs:
  if len(face)==4:
   center=sum((Vector(vs[i]) for i in face),Vector())/4
   normal=(Vector(vs[face[1]])-Vector(vs[face[0]])).cross(Vector(vs[face[2]])-Vector(vs[face[0]])).normalized()
   center+=normal*r*.07;ci=len(vs);vs.append(center)
   for j in range(4):detailed.append((face[j],face[(j+1)%4],ci))
  else:detailed.append(face)
 o=mesh_obj(n,vs,detailed,mat,bone)
 for key in ['crystal_dark','crystal_light']:o.data.materials.append(mats[key])
 for f in o.data.polygons:f.material_index=0 if f.index%4 else 1 if f.index%3 else 2
 return o
def drill_bit(n,a,b,r,mat='silver',bone='root',turns=4):
 a,b=Vector(a),Vector(b);axis=(b-a);length=axis.length;q=axis.to_track_quat('Z','Y')
 rod(n+' tapered core',a,b,r*.78,mat,bone,r2=.012,verts=32)
 vs=[];fs=[];steps=int(turns*48)
 for i in range(steps+1):
  t=i/steps;ang=t*turns*math.tau;rad=r*(1-t)*(.95+.08*math.sin(t*math.pi))+.008
  for rr,zz in [(rad*.76,-.022),(rad,-.008),(rad,.018),(rad*.76,.035)]:vs.append(a+q@Vector((rr*math.cos(ang),rr*math.sin(ang),length*t+zz)))
 for i in range(steps):
  for j in range(4):fs.append((i*4+j,i*4+(j+1)%4,(i+1)*4+(j+1)%4,(i+1)*4+j))
 return mesh_obj(n+' continuous helical cutting flight',vs,fs,mat,bone,False)
def buckle(n,p,w,h,bone='root'):
 x,y,z=p
 for dx in [-w/2,w/2]:box(n,(x+dx,y,z),(.013,.025,h),'brass',bone,.004)
 for dz in [-h/2,h/2]:box(n,(x,y,z+dz),(w,.025,.013),'brass',bone,.004)
 rod('Buckle tongue',(x,y+.018,z-h*.4),(x,y+.018,z+h*.25),.006,'silver',bone)
def seam(n,pts,bone='root',r=.003):return line(n,pts,r,'sole',bone)
def collapse(start,n,pivot=(0,0,0)):
 global parts
 o=join_objects(parts[start:],n);parts=parts[:start]+[o];bpy.context.view_layer.objects.active=o;bpy.ops.object.transform_apply(location=False,rotation=True,scale=True);o.rotation_mode='XYZ';bpy.context.scene.cursor.location=pivot;bpy.context.view_layer.objects.active=o;bpy.ops.object.origin_set(type='ORIGIN_CURSOR');return o
stats={}
def save_asset(n,rig=None):
 stats[n]={'vertices':sum(len(o.data.vertices) for o in parts if o.type=='MESH'),'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in parts if o.type=='MESH')}
 export(n,rig)
 import sys
 if ROOT+'/Tools' not in sys.path:sys.path.insert(0,ROOT+'/Tools')
 from fix_cloth_factors import fix
 fix(OUT+'/Models/'+n+'.glb')
# HERO: tailored silhouette, anatomical head, swept layered hair, attached equipment.
loft('Shirt',[(0,0,1.08,.22,.14),(0,0,1.19,.205,.14),(0,0,1.40,.255,.155),(0,0,1.56,.285,.14),(0,0,1.63,.24,.12)],'dark')
# Jacket panels follow a continuous torso profile, open along front centre.
for sign in [-1,1]:
 vs=[];fs=[];zs=[1.16,1.18,1.27,1.40,1.53,1.61,1.66];radii=[(.235,.17),(.24,.18),(.245,.18),(.265,.19),(.285,.18),(.29,.17),(.24,.14)]
 for j,z in enumerate(zs):
  rx,ry=radii[j]
  for k in range(17):
   a=-math.pi/2+(math.pi-.28)*k/16;vs.append((sign*rx*math.cos(a),ry*math.sin(a),z+.006*math.sin(k*1.3+j)))
 for j in range(len(zs)-1):
  for k in range(16):fs.append((j*17+k,j*17+k+1,(j+1)*17+k+1,(j+1)*17+k))
 ob=mesh_obj('Tailored cropped jacket',vs,fs,'gold',smooth=True);mod=ob.modifiers.new('Cloth thickness','SOLIDIFY');mod.thickness=.015;bpy.context.view_layer.objects.active=ob;bpy.ops.object.modifier_apply(modifier=mod.name)
 line('Jacket front piping',[(sign*.066,.175,1.18),(sign*.067,.19,1.35),(sign*.074,.17,1.52)],.009,'brass')
 # Upturned angular collar and lapel.
 v=[(sign*.08,.18,1.48),(sign*.18,.16,1.59),(sign*.185,.015,1.74),(sign*.105,.045,1.70),(sign*.085,.12,1.58)]
 ob=mesh_obj('Raised collar',v,[(0,1,2,3,4)],'gold');mod=ob.modifiers.new('Collar leather thickness','SOLIDIFY');mod.thickness=.022;bpy.context.view_layer.objects.active=ob;bpy.ops.object.modifier_apply(modifier=mod.name)
 seam('Collar stitch',[v[0],v[1],v[2]])
 line('Hem seam',[(sign*.07,.169,1.185),(sign*.17,.125,1.185),(sign*.228,0,1.185),(sign*.13,-.15,1.185)],.004,'brass')
rod('Neck',(0,0,1.59),(0,0,1.80),.088,'skin',verts=24)
# Chin/jaw/cheek/forehead profile: more adult proportions than the previous round toy head.
loft('Sculpted face',[(0,.025,1.746,.052,.061),(0,.032,1.77,.100,.094),(0,.018,1.81,.145,.133),(0,.006,1.88,.184,.166),(0,-.004,1.96,.193,.172),(0,-.014,2.04,.187,.166),(0,-.023,2.10,.155,.141),(0,-.027,2.135,.095,.082)],'skin',sides=40)
for sign in [-1,1]:
 x=sign*.185;ell('Ear helix',(x,-.007,1.91),(.037,.046,.065),'skin');ell('Ear fold',(x+sign*.01,.029,1.91),(.021,.013,.040),'blush')
 # Large almond eye rim, cream sclera and brown irises with catchlights.
 x=sign*.077
 line('Upper eyelash',[(x-.039,.163,1.958),(x-.025,.173,1.979),(x,.180,1.985),(x+.027,.171,1.974),(x+.041,.156,1.957)],.004,'hair')
 ell('Eye white',(x,.165,1.955),(.041,.009,.024),'white')
 ell('Amber iris',(x-sign*.006,.175,1.956),(.021,.004,.024),'iris')
 ell('Pupil',(x-sign*.006,.179,1.956),(.010,.002,.018),'dark')
 ell('Eye glint',(x-sign*.012,.181,1.965),(.005,.002,.006),'white')
 line('Arched brow',[(sign*.035,.166,2.01),(sign*.071,.172,2.026),(sign*.114,.157,2.021),(sign*.136,.145,2.01)],.012,'hair',sides=8)
 for j in range(3):ell('Freckle',(sign*(.098+j*.018),.162-j*.006,1.914-j%2*.011),(.004,.002,.003),'blush')
loft('Nose bridge',[(0,.151,1.90,.033,.021),(0,.183,1.925,.030,.035),(0,.174,1.975,.018,.020),(0,.158,2.005,.012,.008)],'skin',sides=16)
for x in [-.021,.021]:ell('Nostril',(x,.198,1.907),(.009,.004,.004),'lip')
line('Smile crease',[(-.048,.147,1.839),(-.026,.166,1.831),(0,.17,1.830),(.027,.163,1.84),(.049,.145,1.854)],.0045,'lip')
ell('Lower lip',(0,.165,1.822),(.035,.007,.009),'blush')
# Crown and sideburns are covered with overlapping curved locks, never a smooth helmet.
ell('Hair undercut',(0,-.046,2.055),(.196,.174,.122),'hair')
for i in range(14):
 a=i*math.tau/14;x=math.cos(a);y=math.sin(a)
 hair_lock((x*.10,y*.08-.025,2.09),(x*.19+.065,y*.15-.05,2.29+rng.uniform(-.02,.065)),(x*.22+.10,y*.19-.045,2.17+rng.uniform(-.05,.06)),.075)
for i in range(5):
 x=-.17+i*.067
 hair_lock((x,-.01,2.14),(x+.075,.15,2.24),(x+.07,.19,2.046+i%2*.035),.062)
ell('Hair nape',(0,-.145,1.97),(.169,.070,.144),'hair')
for i in range(7):
 x=-.145+i*.048
 hair_lock((x,-.14,2.04),(x+.015,-.23,1.96),(x+.022,-.20,1.84+(i%2)*.036),.038)
for sign in [-1,1]:
 for j in range(4):hair_lock((sign*.17,-.035-j*.027,2.05),(sign*.23,-.05-j*.025,1.98),(sign*.185,-.04-j*.03,1.87-j*.018),.032)
for sg in [-1,1]:
 ell('Temple hair volume',(sg*.164,-.013,2.026),(.048,.121,.097),'hair')
 for j in range(4):
  hair_lock((sg*.156,.074-j*.037,2.10),(sg*.235,.073-j*.033,2.06),(sg*.206,.008-j*.038,1.95-j%2*.032),.038)
# Forehead goggles: actual oval rims and lenses, continuous strap around head.
line('Goggle leather headband',[(.20*math.cos(a),-.025+.174*math.sin(a),2.066) for a in np.linspace(0,math.tau,49)],.025,'leather')
for sign in [-1,1]:
 x=sign*.10
 ell('Goggle padded backing',(x,.134,2.093),(.097,.043,.066),'leather')
 rim=ring('Goggle bronze rim',(x,.171,2.096),.066,.010,'brass',axis=(0,1,0));
 for vertex in rim.data.vertices:
  vertex.co.x=x+(vertex.co.x-x)*1.29;vertex.co.z=2.096+(vertex.co.z-2.096)*.77
 ell('Blue glass',(x,.171,2.096),(.079,.018,.048),'lens')
 line('Lens reflection',[(x-.034,.190,2.116),(x+.005,.191,2.130)],.004,'white')
 bolt((sign*.198,.14,2.084),.015,axis=(0,1,0))
rod('Goggle bridge',(-.022,.183,2.096),(.022,.183,2.096),.012,'brass')
# Pelvis, belt, webbing and rear hard-shell pack.
loft('Tailored trousers seat',[(0,0,.93,.23,.153),(0,0,1.02,.269,.179),(0,0,1.12,.238,.151)],'teal',fold=.016)
loft('Utility belt',[(0,0,1.103,.244,.167),(0,0,1.166,.232,.158)],'leather')
buckle('Belt buckle',(0,.172,1.135),.10,.065)
for sign in [-1,1]:
 for j in range(2):
  box('Belt pouch',(sign*(.13+j*.085),.14-j*.06,1.13),(.064,.065,.096),'dark',bevel=.014)
  box('Pouch flap',(sign*(.13+j*.085),.18-j*.06,1.17),(.068,.018,.024),'leather',bevel=.004)
  bolt((sign*(.13+j*.085),.195-j*.06,1.16),.010,axis=(0,1,0))
 line('Harness',[(sign*.21,.162,1.21),(sign*.234,.18,1.44),(sign*.225,.125,1.64),(sign*.20,-.04,1.68),(sign*.185,-.18,1.5)],.030,'leather',sides=8)
 buckle('Harness adjuster',(sign*.233,.208,1.47),.059,.072)
 seam('Harness stitching',[(sign*.25,.194,1.29),(sign*.251,.203,1.44),(sign*.24,.15,1.6)])
plate('Pack padded body',(0,-.268,1.416),(.435,.215,.57),'teal')
shield_panel('Pack rear armored panel',(0,-.387,1.435),.347,.45,.05,'paint')
for sign in [-1,1]:
 box('Pack leather edge',(sign*.205,-.35,1.41),(.04,.08,.53),'leather',bevel=.014)
 box('Pack side gusset',(sign*.243,-.266,1.29),(.077,.18,.22),'teal',bevel=.026)
 for z in [1.18,1.65]:plate('Pack reinforced corner',(sign*.157,-.419,z),(.094,.035,.070),'steel')
 box('Vertical pack webbing',(sign*.15,-.423,1.40),(.035,.018,.39),'leather',bevel=.005)
 buckle('Pack strap buckle',(sign*.15,-.44,1.39),.053,.070)
 for z in [1.185,1.645]:bolt((sign*.156,-.444,z),.015)
line('Pack carry handle',[(-.09,-.27,1.70),(-.08,-.27,1.745),(.08,-.27,1.745),(.09,-.27,1.70)],.018,'leather')
# Flat diamond emblem in an inset bezel, readable from behind.
for scale,yy,mat in [(1.22,-.426,'dark'),(1,-.448,'cyan')]:
 vs=[(-.052*scale,yy,1.48),(0,yy-.015,1.59),(.052*scale,yy,1.48),(0,yy-.013,1.37),(0,yy-.027,1.48)]
 mesh_obj('Pack diamond inset',vs,[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],mat)
for z in [1.28,1.58]:
 rod('Drill retention clamp',(.22,-.275,z),(.355,-.275,z),.033,'brass')
rod('Drill motor',(.30,-.27,1.16),(.345,-.27,1.64),.071,'steel',verts=24)
for z in [1.20,1.28,1.45,1.60]:ring('Drill grip rib',(.30+(z-1.16)*.094,-.27,z),.074,.012,'dark')
rod('Drill battery',(.303,-.27,1.13),(.31,-.27,1.27),.081,'paint',verts=16)
rod('Drill chuck',(.345,-.27,1.61),(.357,-.27,1.73),.092,'brass',verts=24)
drill_bit('Backpack drill',(.357,-.27,1.72),(.410,-.27,2.02),.087,turns=3.6)
line('Drill cable',[(.31,-.28,1.17),(.28,-.37,1.08),(.13,-.34,1.09),(.12,-.27,1.2)],.014,'dark')
bones={}
for side,sg in [('L',-1),('R',1)]:
 x=sg*.143;th='thigh'+side;sh='shin'+side;up='arm'+side;fore='fore'+side
 bones[th]=((x,0,1.02),(x,0,.57),'root');bones[sh]=((x,0,.57),(x,0,.15),th)
 bones[up]=((sg*.28,0,1.59),(sg*.38,0,1.31),'root');bones[fore]=((sg*.38,0,1.31),(sg*.45,.015,1.06),up)
 loft('Cargo thigh',[(x,0,.55,.105,.124),(x,0,.61,.118,.139),(x,-.005,.68,.128,.148),(x,-.009,.79,.142,.160),(x,0,.92,.151,.16),(x,0,1.03,.143,.154)],'teal',th,fold=.027)
 loft('Trouser gathered calf',[(x,.006,.15,.099,.097),(x,-.012,.20,.109,.123),(x,.0,.24,.13,.127),(x,-.012,.275,.112,.12),(x,-.017,.34,.116,.129),(x,-.021,.39,.117,.13),(x,-.012,.46,.108,.12),(x,0,.55,.115,.13),(x,0,.62,.106,.123)],'teal',sh,fold=.04)
 for z,rad in [(.23,.12),(.30,.111),(.42,.106)]:
  line('Trouser fold',[(x+rad*math.cos(a),-.01+.13*math.sin(a),z+.014*math.sin(a*2)) for a in np.linspace(math.pi,math.tau,12)],.007,'teal',sh)
 seam('Outside trouser seam',[(x+sg*.144,0,.97),(x+sg*.134,-.01,.79),(x+sg*.107,-.01,.61)],th)
 seam('Calf seam',[(x+sg*.108,0,.54),(x+sg*.115,-.018,.36),(x+sg*.10,-.012,.19)],sh)
 plate('Cargo pocket',(x+sg*.124,0,.83),(.068,.21,.19),'teal',th)
 plate('Cargo pocket flap',(x+sg*.159,.003,.91),(.014,.22,.065),'dark',th)
 bolt((x+sg*.17,0,.894),.011,axis=(sg,0,0),bone=th)
 shield_panel('Knee pad outer',(x,.139,.568),.198,.226,.055,'leather',sh)
 shield_panel('Knee armor',(x,.174,.577),.162,.179,.035,'steel',sh)
 for dx in [-.059,.059]:bolt((x+dx,.196,.585),.009,axis=(0,1,0),bone=sh)
 loft('Jacket articulated sleeve',[(sg*.39,0,1.29,.108,.12),(sg*.384,0,1.33,.126,.137),(sg*.36,0,1.39,.128,.142),(sg*.33,0,1.47,.131,.148),(sg*.30,0,1.55,.127,.135),(sg*.275,0,1.60,.10,.102)],'gold',up,fold=.03)
 for z in [1.30,1.325]:ring('Rolled sleeve hem',(sg*.39,0,z),.115,.014,'gold',bone=up)
 loft('Forearm anatomy',[(sg*.442,.013,1.075,.052,.057),(sg*.435,.009,1.13,.058,.064),(sg*.418,.002,1.21,.071,.072),(sg*.389,0,1.3,.084,.081)],'skin',fore,sides=24)
 box('Glove wrist strap',(sg*.445,.007,1.098),(.145,.144,.055),'leather',fore,.012)
 buckle('Wrist clasp',(sg*.445,.086,1.10),.052,.035,fore)
 loft('Gloved palm',[(sg*.458,.014,.984,.057,.049),(sg*.454,.014,1.055,.070,.051),(sg*.45,.012,1.087,.058,.053)],'dark',fore,sides=20)
 for j in range(4):
  xx=sg*.458+(j-1.5)*.03
  line('Individual glove finger',[(xx,.027,1.015),(xx,.050,.978),(xx,.064,.959),(xx,.077,.978)],.018,'dark',fore,sides=8)
 line('Glove thumb',[(sg*.407,.007,1.04),(sg*.386,.055,1.015),(sg*.399,.080,.992)],.023,'dark',fore,sides=10)
 plate('Glove knuckle guard',(sg*.455,-.044,1.038),(.103,.025,.055),'steel',fore)
 # Shaped hiking boot: separate outsole, welt, tongue, heel counter, toe and laces.
 loft('Sculpted rubber outsole',[(x,.065,.012,.108,.190),(x,.069,.029,.133,.216),(x,.069,.059,.132,.215)],'dark',sh,sides=28)
 loft('Rounded boot midsole',[(x,.069,.051,.132,.215),(x,.069,.095,.129,.211),(x,.065,.11,.120,.202)],'sole',sh,sides=28)
 loft('Shaped leather boot',[(x,.065,.097,.119,.200),(x,.062,.137,.120,.185),(x,.030,.184,.111,.156),(x,-.026,.230,.105,.111),(x,-.041,.290,.099,.092)],'leather',sh,sides=28)
 loft('Mustard ankle quarters',[(x,-.033,.198,.108,.114),(x,-.039,.25,.107,.104),(x,-.044,.298,.105,.096)],'gold',sh,sides=28)
 ell('Rubber toe cap',(x,.218,.134),(.113,.077,.053),'dark',sh)
 box('Padded boot tongue',(x,.102,.24),(.10,.047,.17),'dark',sh,.018)
 line('Boot toe stitching',[(x+.105*math.cos(a),.14+.110*math.sin(a),.173) for a in np.linspace(0,math.pi,14)],.003,'sole',sh)
 for j in range(4):
  z=.165+j*.032;y=.193-j*.018
  for sg2 in [-1,1]:ring('Boot eyelet',(x+sg2*.073,y,z),.009,.003,'brass',axis=(0,1,0),bone=sh,segments=12)
  line('Boot crossed lace',[(x-.073,y+.008,z),(x+.066,y-.010,z+.025)],.006,'sole',sh)
  line('Boot crossed lace',[(x+.073,y+.009,z),(x-.066,y-.010,z+.025)],.006,'sole',sh)
 for j in range(5):
  for sg2 in [-1,1]:box('Outsole tread',(x+sg2*.085,-.08+j*.074,.013),(.075,.043,.026),'dark',sh,.005)
# Existing animation contract retained; smooth clothing geometry follows the same named bones.
groups={}
for o in parts:groups.setdefault(assign[o.name],[]).append(o)
parts=[]
for bone,objs in groups.items():
 ob=join_objects(objs,bone+'Mesh');parts.append(ob);assign[ob.name]=bone
bpy.ops.object.armature_add();rig=bpy.context.object;rig.name='ExplorerRig'
bpy.ops.object.mode_set(mode='EDIT');r=rig.data.edit_bones[0];r.name='root';r.head=(0,0,1);r.tail=(0,0,1.6)
for n,(head,tail,parent) in bones.items():
 b=rig.data.edit_bones.new(n);b.head=head;b.tail=tail;b.parent=rig.data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
for o in parts:
 o.parent=rig;vg=o.vertex_groups.new(name=assign[o.name]);vg.add(list(range(len(o.data.vertices))),1,'REPLACE');mod=o.modifiers.new('Rig','ARMATURE');mod.object=rig
parts.append(rig)
# Reuse proven animation names/timing with the detailed mesh.
src=open(ROOT+'/Tools/build_assets.py').read();exec(src[src.index("for name,length in [('idle'"):src.index("export('explorer',rig)")])
save_asset('explorer',rig)
# ENVIRONMENTS: irregular stone paving, mineral seams and vertical mine architecture.
def lantern(x,y,z,scale=1):
 rod('Lantern warm glass',(x,y,z),(x,y,z+.49*scale),.16*scale,'lamp',verts=12)
 for dz,r in [(0,.21),(.49,.20),(.54,.14)]:rod('Lantern cap',(x,y,z+dz*scale-.03*scale),(x,y,z+dz*scale+.03*scale),r*scale,'steel',verts=16)
 for a in np.linspace(0,math.tau,7)[:-1]:
  dx,dy=.17*scale*math.cos(a),.17*scale*math.sin(a);rod('Lantern cage',(x+dx,y+dy,z),(x+dx,y+dy,z+.49*scale),.016*scale,'brass',verts=8)
 ring('Lantern handle',(x,y,z+.64*scale),.083*scale,.013*scale,'steel',axis=(0,1,0))
def beam(n,a,b,width=.25,depth=.24):
 a,b=Vector(a),Vector(b);o=box(n,(a+b)/2,(width,depth,(b-a).length),'wood',bevel=.025);o.rotation_mode='QUATERNION';o.rotation_quaternion=(b-a).to_track_quat('Z','Y');return o
def cliff(side,y,mat):
 # A tessellated, offset face with seams between sedimentary masses.
 for j in range(3):
  x=side*(6.15+j*.42);z=1.6+j*3.5
  ob=stone('Wall',(x,y+rng.uniform(-.4,.4),z),(1.5+rng.random()*.5,2.6,2.5),mat)
  for v in ob.data.vertices:v.co*=rng.uniform(.965,1.035)
 for j in range(3):
  stone('Weathered ledge',(side*(4.55+j*.27),y+.3,1+j*2.6),(.7,2.05,.33),mat)
def paving():
 box('Rock bed',(0,0,-.26),(8.5,24,.38),'rock')
 for y in np.arange(-12,12,1.65):
  for i,x in enumerate([-2.6,0,2.6]):
   w=1.285;h=.805;yy=y+h
   vs=[(x-w+.04,yy-h,.006),(x+w-.07,yy-h+.035,.012),(x+w,yy+h-.06,.007),(x+w-.16,yy+h,.014),(x-w+.10,yy+h-.025,.006),(x-w,yy+h-.13,.008)]
   o=mesh_obj('Irregular sandstone flagstone',vs,[tuple(range(6))],'sand');mod=o.modifiers.new('Stone thickness','SOLIDIFY');mod.thickness=.08;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
   if (int(y*10)+i)%3==0:line('Hairline stone fracture',[(x-.5,yy-.3,.020),(x-.2,yy-.12,.021),(x+.05,yy-.18,.021),(x+.4,yy+.12,.021)],.008,'rock',sides=4)
 for y in np.arange(-11.7,12,1.5):
  for x in [-3.7,-1.25,1.25,3.7]:
   box('Rail sleeper',(x,y,.018),(.42,.20,.045),'wood',bevel=.007)
   for xx in [x-.10,x+.10]:bolt((xx,y,.06),.025,axis=(0,0,1),mat='steel')
 for x in [-3.7,-1.25,1.25,3.7]:
  box('Rail web',(x,0,.043),(.046,24,.065),'steel',bevel=.008);box('Rail polished head',(x,0,.08),(.086,24,.037),'edge',bevel=.009)
  for y in [-8,0,8]:
   box('Rail fishplate',(x+.05,y,.045),(.015,.39,.045),'steel',bevel=.004)
   for yy in [y-.12,y+.12]:bolt((x+.059,yy,.049),.018,axis=(1,0,0),mat='brass')
def banner(x,y,z,length=2):
 vs=[];fs=[]
 for j in range(13):
  for k in range(5):vs.append((x+(k-2)*.16,y+math.sin(j*.48+k*.3)*.10,z-j*length/12-(.14 if j==12 and k%2 else 0)))
 for j in range(12):
  for k in range(4):fs.append((j*5+k,j*5+k+1,(j+1)*5+k+1,(j+1)*5+k))
 o=mesh_obj('Hanging miners banner',vs,fs,'teal',smooth=True);mod=o.modifiers.new('Banner thickness','SOLIDIFY');mod.thickness=.016;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 for sg in [-1,1]:rod('Crossed pick insignia',(x-sg*.18,y-.03,z-.60),(x+sg*.18,y-.03,z-1.02),.018,'brass',verts=6)
for name in ['track','crystal_track','industrial_track']:
 paving();cave=name=='crystal_track';factory=name=='industrial_track'
 for side in [-1,1]:
  for y in [-10,-5,0,5,10]:
   cliff(side,y,'cave_rock' if cave else 'rock')
   for j in range(3):
    p=(side*rng.uniform(4.05,4.65),y+rng.uniform(-1.3,1.3),rng.uniform(.1,.4));stone('Loose scree',p,(rng.uniform(.2,.55),rng.uniform(.25,.6),rng.uniform(.2,.55)))
   for j in range(5):stone('Chipped mineral debris',(side*rng.uniform(3.85,4.15),y+rng.uniform(-1.9,1.9),.035),(.075,.13,.066),'sand')
  for y in [-9,1,9]:
   for j in range(5 if cave else 3):
    x=side*(3.98+j*.12);z=.18;h=(1.25+j*.47)*(1.4 if cave else 1.2)
    crystal2('Turquoise mineral cluster',(x,y+j*.28,z),(x-side*(.20+j*.05),y+j*.28+.08,z+h),.24+j*.048)
   if cave:
    crystal2('Overhead crystal seam',(side*5.1,y,6.8),(side*4.1,y+.2,4.4),.37)
    for z in [2.3,4.2]:line('Luminous mineral vein',[(side*4.7,y,z),(side*4.68,y+.4,z+.25),(side*4.8,y+.8,z+.12)],.022,'cyan')
  if not factory:
   for y in [-6,6]:
    x=side*4.25;beam('Massive support post',(x,y,0),(x+side*.12,y,7.6),.48,.57)
    # Front face grooves interrupt the perfect box silhouette.
    for dx in [-.14,.02,.15]:line('Timber split',[(x+dx,y-.29,.3),(x+dx+.018,y-.296,2.7),(x+dx-.02,y-.297,5.8)],.009,'leather')
    for z in [.65,3.6,6.5]:
     box('Forged post strap',(x,y-.315,z),(.51,.085,.36),'steel')
     for dx in [-.17,.17]:
      for dz in [-.105,.105]:bolt((x+dx,y-.366,z+dz),.033)
    beam('Knee brace',(x,y,5.7),(side*2.85,y,7.3),.22,.24)
    rod('Lantern iron cantilever',(x-side*.14,y,3.8),(side*3.57,y,3.8),.027,'steel')
    rod('Lantern chain',(side*3.57,y,3.8),(side*3.57,y,3.28),.015,'steel')
    lantern(side*3.57,y,2.63,1.05)
   # Upper galleries, cross braces and a ladder give inhabited mine depth.
   for yy in np.arange(-11.8,12,.37):box('Gallery planking',(side*4.9,yy,5.6),(1.8,.35,.10),'wood',bevel=.012)
   for yy in np.arange(-12,12,3):
    beam('Gallery baluster',(side*4.04,yy,5.65),(side*4.04,yy,6.55),.11,.11)
    beam('Gallery corbel',(side*5.4,yy,4.5),(side*4.1,yy,5.5),.15,.15)
   beam('Gallery upper rail',(side*4.04,-12,6.52),(side*4.04,12,6.52),.12,.12)
   x=side*4.35
   for yy in [-.40,.40]:beam('Access ladder stringer',(x,yy,0),(x+side*.6,yy,5.55),.07,.07)
   for z in np.arange(.35,5.5,.35):rod('Ladder rung',(x+side*.6*z/5.55,-.40,z),(x+side*.6*z/5.55,.40,z),.032,'wood')
  else:
   for y in [-8,0,8]:
    x=side*4.42
    plate('Industrial arch column',(x,y,3.9),(.53,.7,7.8),'paint')
    for z in [1.0,3.5,6.0]:
     plate('Column bracket',(x-side*.30,y,z),(.09,.76,.42),'steel')
     for dy in [-.23,.23]:bolt((x-side*.36,y+dy,z),.065,axis=(-side,0,0))
    for z in [1.2,2.0]:
     rod('Pressure conduit',(side*4.02,y-4,z),(side*4.02,y+4,z),.16,'paint',verts=20)
     for yy in [y-3,y+2]:ring('Pipe coupling',(side*4.02,yy,z),.19,.046,'steel',axis=(0,1,0))
    plate('Machine casing',(side*5.0,y+2,2.7),(1.4,2.4,3.5),'paint')
    for zz in np.arange(1.4,3.5,.20):box('Vent louvers',(side*4.28,y+2,zz),(.035,1.7,.07),'dark')
    rod('Valve axle',(side*4.02,y,2),(side*3.8,y,2),.045,'silver');ring('Valve handwheel',(side*3.78,y,2),.25,.027,'brass',axis=(1,0,0))
    for a in [0,math.pi/2]:rod('Valve spoke',(side*3.78,y-math.cos(a)*.23,2-math.sin(a)*.23),(side*3.78,y+math.cos(a)*.23,2+math.sin(a)*.23),.015,'steel')
    lantern(side*3.65,y,3.7,1.15)
   box('Upper catwalk',(side*4.75,0,5.3),(1.3,24,.18),'steel')
   for y in np.arange(-12,12,2):
    rod('Guardrail upright',(side*4.1,y,5.3),(side*4.1,y,6.3),.035,'brass')
   rod('Guardrail',(side*4.1,-12,6.3),(side*4.1,12,6.3),.04,'brass')
  # High rugged skyline fills the previous empty background.
  for y in [-9,3]:stone('High cavern buttress',(side*7.0,y,11),(2.4,3.9,5.5),'cave_rock' if cave else 'rock')
 for y in [-6,6]:
  if not factory:beam('Overhead crossbeam',(-4.4,y,7.4),(4.4,y,7.4),.40,.46)
  else:
   box('Steel overhead girder',(0,y,7.5),(9,.55,.6),'paint')
   for x in [-3,-1,1,3]:plate('Girder joining plate',(x,y-.3,7.5),(.3,.04,.49),'steel')
 if not factory:banner(2.95,5.7,7.0,2.3)
 if cave:
  for x in [-2.9,3.0]:crystal2('Ceiling pendant',(x,9,9),(x+.3,9,6.6),.32)
 save_asset(name)
# BOSSES: reference silhouettes and real moving assemblies.
def hydraulic(a,b,r=.15):
 a,b=Vector(a),Vector(b);d=b-a
 rod('Hydraulic housing',a,a+d*.61,r,'steel',verts=20);rod('Hydraulic piston',a+d*.45,b,r*.57,'silver',verts=20)
 for t in [.05,.55]:ring('Cylinder collar',a+d*t,r*1.1,r*.12,'brass',axis=d)
def axle(p,r=.3,depth=.2,axis=(1,0,0)):
 p=Vector(p);a=Vector(axis)
 rod('Joint axle',p-a*depth/2,p+a*depth/2,r,'steel',verts=24)
 for sg in [-1,1]:
  q=p+a*(depth/2+.015)*sg;ring('Joint bronze bearing',q,r*.74,r*.09,'brass',axis=a)
  rod('Bearing cap',q,q+a*.02*sg,r*.40,'edge',verts=12)
def armor_ring(n,p,r,t,mat='paint',axis=(0,-1,0)):
 ring(n,p,r,t,mat,axis=axis,segments=40)
 for i in range(10):
  a=i*math.tau/10;bolt((p[0]+math.cos(a)*r,p[1]-.07,p[2]+math.sin(a)*r),.055)
def boss_animation(body,arms,extra=None,floating=False):
 objects=[body]+arms+(extra or [])
 for clip in ['idle','attack','hurt','defeat']:
  for index,obj in enumerate(objects):
   obj.animation_data_create();obj.animation_data.action=bpy.data.actions.new(clip);base=obj.location.copy();base_rot=obj.rotation_euler.copy()
   for f in [1,7,13,19,25]:
    t=(f-1)/24;obj.rotation_euler=base_rot;obj.location=base.copy();obj.scale=(1,1,1)
    if clip=='idle':obj.location.z+=(.12 if floating else .025)*math.sin(t*math.tau)
    if clip=='attack' and index in [1,2]:
     obj.rotation_euler.x=-.32*math.sin(t*math.pi);obj.rotation_euler.y=(1 if index==1 else -1)*.48*math.sin(t*math.pi)
    if clip=='hurt':obj.rotation_euler.x=.14*math.sin(t*math.pi);obj.location.y+=.15*math.sin(t*math.pi)
    if clip=='defeat':obj.rotation_euler.x=t*.85;obj.location.z-=t*.65
    obj.keyframe_insert('location',frame=f);obj.keyframe_insert('rotation_euler',frame=f)
   track=obj.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,1,obj.animation_data.action);obj.animation_data.action=None;obj.location=base;obj.rotation_euler=base_rot
# Mining robot: round pressure body, chest drill, ore hopper, articulated legs and timber fists.
rod('Robot round torso',(0,.3,2.55),(0,-.57,2.55),1.18,'paint',verts=40)
armor_ring('Armored torso rim',(0,-.61,2.55),1.03,.17)
armor_ring('Inner drill collar',(0,-.85,2.55),.72,.095,'steel')
ring('Amber reactor seam',(0,-.94,2.55),.59,.047,'lamp',axis=(0,1,0))
drill_bit('Robot golden chest drill',(0,-.96,2.55),(0,-2.02,2.55),.56,'brass',turns=3.3)
for sg in [-1,1]:
 for z in [1.9,3.15]:
  plate('Torso locking lug',(sg*.87,-.75,z),(.26,.14,.32),'steel');bolt((sg*.87,-.84,z),.067)
 ell('Headlamp housing',(sg*.70,-.79,3.35),(.22,.11,.22),'steel');ell('Amber headlamp',(sg*.70,-.88,3.35),(.13,.055,.13),'lamp')
 # Legs with actual bearings, knee armor and divided toes.
 axle((sg*.68,0,1.55),.31,.46)
 hydraulic((sg*.7,.14,1.6),(sg*.95,-.15,.59),.16)
 plate('Thigh shell',(sg*.87,-.15,1.16),(.57,.62,.62),'paint')
 axle((sg*.91,-.13,.83),.21,.64)
 plate('Foot armor',(sg*1.02,-.18,.31),(.85,1.03,.43),'paint')
 for dx in [-.22,0,.22]:plate('Separate armored toe',(sg*1.02+dx,-.73,.23),(.20,.33,.27),'steel')
 for y in [-.35,.15]:bolt((sg*1.45,y,.33),.055,axis=(sg,0,0))
 # Belly rods and shoulder bearings.
 axle((sg*1.31,0,2.95),.54,.48)
 ring('Shoulder cowling',(sg*1.42,0,2.95),.55,.15,'paint',axis=(1,0,0))
# Back hopper full of ore: the concept's characteristic silhouette.
for x in [-.70,.70]:plate('Ore hopper side',(x,.29,3.92),(.13,1.0,.64),'wood')
for y in [-.24,.78]:
 for x in [-.45,0,.45]:plate('Hopper plank',(x,y,3.92),(.42,.09,.63),'wood')
 box('Hopper rim',(0,y,4.24),(1.66,.15,.15),'paint')
 for x in [-.62,0,.62]:bolt((x,y-.09,4.23),.052)
for j in range(9):stone('Hopper ore',(rng.uniform(-.55,.55),rng.uniform(-.05,.58),4.23+rng.uniform(-.05,.15)),(.23,.28,.23),'rock')
plate('Identity brass badge',(0,-.77,3.57),(.28,.11,.30),'brass')
for z in [3.51,3.60]:box('Badge slot',(0,-.84,z),(.10,.025,.037),'lamp')
body=collapse(0,'Robot pressure body');arms=[]
for sg in [-1,1]:
 start=len(parts);hydraulic((sg*1.42,0,2.95),(sg*2.2,-.1,2.50),.22);axle((sg*2.18,-.1,2.50),.30,.45)
 hydraulic((sg*2.19,-.05,2.5),(sg*2.65,-.32,1.62),.24)
 plate('Elbow armor',(sg*2.25,-.22,2.40),(.6,.65,.45),'paint')
 # Oversized fist assembled from wood boards with forged metal bands.
 for dx in [-.32,0,.32]:box('Timber fist plank',(sg*2.78+dx,-.28,1.34),(.30,1.02,1.24),'wood',bevel=.035)
 for z in [.83,1.72]:
  box('Fist iron band',(sg*2.78,-.84,z),(1.13,.13,.25),'steel')
  for dx in [-.39,0,.39]:bolt((sg*2.78+dx,-.924,z),.060)
 for dx in [-.48,.48]:plate('Fist corner',(sg*2.78+dx,-.81,1.30),(.15,.16,1.05),'steel')
 for dx in [-.30,0,.30]:plate('Fist knuckle',(sg*2.78+dx,-.85,1.99),(.25,.23,.23),'steel')
 arms.append(collapse(start,'Robot left fist' if sg<0 else 'Robot right fist',(sg*1.4,0,2.95)))
boss_animation(body,arms);save_asset('mining_robot',True)
# Crystal guardian: floating ancient rings, radiant core and enormous shard pauldrons.
rod('Guardian stone breast',(0,.2,3.05),(0,-.3,3.05),1.06,'ancient',verts=12)
armor_ring('Ancient outer ring',(0,-.35,3.05),1.03,.15,'ancient')
armor_ring('Oxidized ring inlay',(0,-.49,3.05),.79,.07,'paint')
armor_ring('Inner stone iris',(0,-.52,3.05),.61,.13,'ancient')
stone('Golden heart',(0,-.66,3.05),(.48,.25,.48),'lamp')
for i in range(8):
 a=i*math.tau/8;x=math.cos(a);z=math.sin(a)
 o=plate('Ancient radial stone key',(x*.91,-.59,3.05+z*.91),(.27,.20,.38),'ancient');o.rotation_euler.y=-a+math.pi/2
 o=plate('Oxidized glyph tab',(x*.79,-.72,3.05+z*.79),(.095,.045,.20),'paint');o.rotation_euler.y=-a+math.pi/2
crystal2('Floating lower body',(0,0,2.25),(0,-.04,.70),.43)
ring('Waist fragment ring',(0,0,2.03),.50,.11,'ancient')
ring('Lower orbit',(0,0,1.61),.37,.085,'paint')
crystal2('Guardian face',(0,-.13,4.0),(0,-.16,4.69),.22)
for sg in [-1,1]:
 line('Mask crest',[(sg*.06,-.34,4.05),(sg*.23,-.26,4.28),(sg*.29,-.12,4.52)],.056,'ancient')
 crystal2('Crown shard',(sg*.22,0,4.60),(sg*.32,.03,5.18),.10)
 crystal2('Orbit shard',(sg*1.14,-.1,1.42),(sg*1.20,0,1.93),.10)
# Central upper spear floats above head.
crystal2('Floating crown',(0,.02,4.8),(0,.03,5.50),.17)
body=collapse(0,'Guardian floating core');arms=[]
for sg in [-1,1]:
 start=len(parts);center=(sg*1.56,0,3.60)
 ring('Shoulder carved arch',center,.82,.14,'ancient',axis=(0,1,0))
 ring('Shoulder oxidized arch',(sg*1.56,-.16,3.6),.68,.06,'paint',axis=(0,1,0))
 for j in range(5):
  a=(sg*(1.15+j*.23),.06+(j%2)*.13,3.25+j%2*.12);b=(sg*(1.75+j*.20),.08,4.35+(j%3)*.31)
  crystal2('Massive shoulder crystal',a,b,.26+j%2*.09)
 # Ancient engraved shoulder armor band.
 for i in range(5):
  a=i*math.pi/5;plate('Shoulder relief glyph',(sg*1.56+math.cos(a)*.72,-.26,3.60+math.sin(a)*.72),(.08,.035,.12),'brass')
 crystal2('Upper arm shard',(sg*1.83,0,3.23),(sg*2.12,-.02,2.57),.22)
 crystal2('Forearm shard',(sg*2.10,-.02,2.65),(sg*2.27,-.10,1.91),.27)
 for z,r in [(2.52,.36),(2.13,.37),(1.87,.32)]:
  ring('Carved forearm cuff',(sg*2.20,-.08,z),r,.10,'ancient')
  ring('Cuff teal inlay',(sg*2.20,-.08,z+.055),r+.024,.027,'paint')
 for j in range(3):
  x=sg*2.22+(j-1)*.22;crystal2('Long crystal finger',(x,-.10,1.91),(x+sg*.09,-.32,1.33-(j%2)*.15),.11)
 crystal2('Crystal thumb',(sg*2.04,-.04,1.95),(sg*1.85,-.30,1.51),.12)
 # Ragged rust cloth hangs behind crystalline arm.
 vs=[];fs=[]
 for j in range(9):
  for k in range(4):vs.append((sg*1.22+(k-1.5)*.13,.31+math.sin(j*.7+k)*.065,3.45-j*.26-(.18 if j==8 and k%2 else 0)))
 for j in range(8):
  for k in range(3):fs.append((j*4+k,j*4+k+1,(j+1)*4+k+1,(j+1)*4+k))
 o=mesh_obj('Tattered ancient sash',vs,fs,'banner',smooth=True);mod=o.modifiers.new('Woven thickness','SOLIDIFY');mod.thickness=.02;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
 arms.append(collapse(start,'Guardian left arm' if sg<0 else 'Guardian right arm',(sg*1.3,0,3.7)))
boss_animation(body,arms,floating=True);save_asset('crystal_guardian',True)
# Giant mining rig: continuous caterpillar tracks, wheels, engine, drill and manipulators.
plate('Heavy machine chassis',(0,.40,1.61),(3.85,3.5,1.64),'paint')
plate('Engine deck',(0,.9,2.65),(3.30,2.5,.8),'paint')
for sg in [-1,1]:
 x=sg*1.69
 def track_point(t):
  d=t*(5.2+math.tau*.72)
  if d<2.6:return (-1.3+d,1.45,0)
  d-=2.6
  if d<math.pi*.72:
   a=d/.72;return (1.3+.72*math.sin(a),.73+.72*math.cos(a),-a)
  d-=math.pi*.72
  if d<2.6:return (1.3-d,.01,-math.pi)
  a=math.pi+(d-2.6)/.72;return (-1.3+.72*math.sin(a),.73+.72*math.cos(a),-a)
 vs=[];fs=[]
 for xx in [x-.40,x+.40]:
  for i in range(40):
   yy,zz,ang=track_point(i/40);vs.append((xx,yy+.25,zz))
 for i in range(40):fs.append((i,(i+1)%40,40+(i+1)%40,40+i))
 fs.extend([tuple(range(39,-1,-1)),tuple(range(40,80))]);mesh_obj('Continuous caterpillar belt',vs,fs,'dark')
 for y in [-1.21,-.53,.15,.83,1.51]:
  axle((x+sg*.40,y,.73),.44,.10,axis=(1,0,0))
  for i in range(6):
   a=i*math.tau/6;bolt((x+sg*.475,y+math.cos(a)*.28,.73+math.sin(a)*.28),.041,axis=(sg,0,0))
 # Closed belt follows a capsule in the YZ plane.
 for i in range(40):
  yy,zz,angle=track_point(i/40);yy+=.25
  ob=plate('Individual track shoe',(x,yy,zz),(.92,.23,.15),'steel');ob.rotation_euler.x=angle
  for sx in [-.31,.31]:
   ob=box('Track shoe lug',(x+sx,yy-math.sin(angle)*.09,zz+math.cos(angle)*.09),(.10,.18,.04),'edge',bevel=.005);ob.rotation_euler.x=angle
 plate('Track upper guard',(x,.2,1.55),(1.03,3.85,.20),'paint')
 for y in [-1.3,-.7,0,.7,1.3]:bolt((x+sg*.50,y,1.55),.05,axis=(sg,0,0))
 for z in [2.0,2.16,2.32,2.48]:box('Engine ventilation',(sg*1.934,.90,z),(.018,1.85,.07),'dark')
 rod('Exhaust stack',(sg*.95,1.24,2.9),(sg*.95,1.24,4.00),.15,'steel',verts=24)
 for z in [3.03,3.67]:ring('Exhaust collar',(sg*.95,1.24,z),.17,.025,'brass')
 rod('Exhaust flared cap',(sg*.95,1.24,3.92),(sg*.95,1.24,4.04),.22,'steel',r2=.18,verts=24)
 lantern(sg*1.49,-1.12,2.48,1.4);lantern(sg*.80,-.40,3.17,.85)
 hydraulic((sg*1.61,0,2.7),(sg*2.0,-.1,3.45),.16)
 # Top handrails and access hatch.
 rod('Deck rail',(sg*1.40,.4,3.45),(sg*1.40,1.5,3.45),.026,'steel')
 for y in [.4,1.5]:rod('Deck rail post',(sg*1.4,y,3),(sg*1.4,y,3.45),.028,'steel')
for y in [-.70,.1,.9]:plate('Engine deck service panel',(0,y,3.05),(1.25,.64,.12),'steel')
rod('Main drill gearbox',(0,-.80,2.05),(0,-1.75,2.05),1.21,'paint',verts=40)
armor_ring('Main drill collar',(0,-1.72,2.05),1.15,.13,'steel')
ring('Main drill bearing',(0,-1.90,2.05),.98,.075,'brass',axis=(0,1,0))
drill_bit('Massive excavation auger',(0,-1.91,2.05),(0,-4.25,2.05),1.01,turns=5.4)
for j in range(6):
 a=j*math.tau/6;bolt((math.cos(a)*1.15,-1.87,2.05+math.sin(a)*1.15),.078)
body=collapse(0,'Giant drill body');arms=[]
for sg in [-1,1]:
 start=len(parts)
 axle((sg*1.65,-.1,3.10),.29,.42)
 a=Vector((sg*1.67,-.1,3.10));b=Vector((sg*2.56,-.25,3.56));c=Vector((sg*3.13,-.55,2.63))
 for aa,bb in [(a,b),(b,c)]:
  ob=plate('Manipulator box section',(aa+bb)/2,(.33,.45,(bb-aa).length),'paint');ob.rotation_mode='QUATERNION';ob.rotation_quaternion=(bb-aa).to_track_quat('Z','Y')
  hydraulic(aa+Vector((0,-.28,-.12)),bb+Vector((0,-.28,-.12)),.11)
 axle(b,.24,.51);axle(c,.21,.51)
 hydraulic(c,(sg*3.13,-.62,1.53),.19)
 plate('Massive hammer fist',(sg*3.13,-.62,1.34),(.81,.89,.69),'steel')
 plate('Hammer painted inset',(sg*3.13,-1.10,1.39),(.62,.04,.47),'brass')
 for dx in [-.30,.30]:
  for z in [1.08,1.62]:bolt((sg*3.13+dx,-1.14,z),.047)
 arms.append(collapse(start,'Drill left manipulator' if sg<0 else 'Drill right manipulator',(sg*1.65,-.1,3.10)))
boss_animation(body,arms);save_asset('giant_drill',True)
# Match the attack lance to the newly modelled spiral instead of stacked rings.
drill_bit('Attack auger',(0,.8,1.2),(0,-.9,1.2),.85,turns=4);save_asset('drill_attack')
# Shared mine props receive the same new surface library.
old_src=open(ROOT+'/Tools/build_assets.py').read()
prop_src=old_src[old_src.index('# Jump crate:'):old_src.index('# Coins:')]
prop_src=prop_src.replace("export(","save_asset(").replace("(.15,.12,1.02),'gold'","(.15,.12,1.02),'wood'")
exec(prop_src)
# Home workshop: plank floor, masoned walls, outfitter cabinet and an occupied workbench.
for x in np.arange(-4.8,5,.42):
 for y in [-3,-1,1,3]:box('Workshop floorboard',(x,y,-.055),(.405,1.98,.10),'wood',bevel=.007)
for z in np.arange(.22,4.5,.42):
 for x in np.arange(-5,5,.83):box('Workshop masonry',(x+(.4 if int(z*10)%2 else 0),3.8,z),(.81,.30,.40),'sand',bevel=.045)
for x in [-4.8,-1.4,1.4,4.8]:beam('Workshop timber frame',(x,3.52,0),(x,3.52,4.6),.20,.25)
beam('Workshop header',(-5,3.5,4.4),(5,3.5,4.4),.23,.28)
for sign in [-1,1]:
 beam('Workshop diagonal',(sign*4.8,3.48,3.0),(sign*3.4,3.48,4.4),.15,.15)
 lantern(sign*3.8,3.24,2.92,1.1)
for x in [-3.8,-1.3]:
 for y in [1.5,2.4]:beam('Workbench leg',(x,y,0),(x,y,1.18),.17,.17)
for y in [1.53,1.86,2.19,2.52]:box('Workbench slab',(-2.55,y,1.19),(2.9,.32,.14),'wood',bevel=.017)
box('Workbench low shelf',(-2.55,1.95,.33),(2.8,1.12,.10),'wood')
for x in [-3.38,-2.55,-1.72]:
 plate('Workbench drawer',(x,1.46,.91),(.77,.13,.35),'wood')
 line('Drawer pull',[(x-.12,1.35,.93),(x-.12,1.29,.90),(x+.12,1.29,.90),(x+.12,1.35,.93)],.019,'steel')
 for dx in [-.25,.25]:bolt((x+dx,1.375,.91),.019)
box('Tools pegboard',(-2.60,3.50,2.18),(2.6,.1,1.18),'wood')
for x in np.arange(-3.7,-1.4,.2):
 for z in np.arange(1.8,2.7,.2):rod('Pegboard hole',(x,3.44,z),(x,3.43,z),.018,'dark',verts=8)
for x in [-3.25,-2.7,-2.15]:
 beam('Pick wooden handle',(x,3.25,1.64),(x+.12,3.25,2.56),.045,.05)
 line('Forged pick head',[(x-.24,3.25,2.42),(x,3.25,2.57),(x+.14,3.25,2.58),(x+.37,3.25,2.47)],.053,'steel')
for j in range(3):crystal2('Workbench ore',(-3.2+j*.16,1.98,1.29),(-3.18+j*.18,1.99,1.66+j%2*.18),.10)
rod('Work drill grip',(-2.2,2.04,1.31),(-1.8,2.04,1.31),.065,'paint')
drill_bit('Workbench auger',(-1.8,2.04,1.31),(-1.38,2.04,1.31),.082,turns=3)
for x in [2.13,3.93]:box('Wardrobe side',(x,2.6,1.65),(.14,1.34,3.3),'wood')
for z in [.14,1.0,3.25]:box('Wardrobe shelf',(3.03,2.6,z),(1.92,1.4,.13),'wood')
box('Wardrobe backing',(3.03,3.24,1.65),(1.9,.14,3.25),'paint')
rod('Wardrobe hanger bar',(2.2,2.5,2.88),(3.85,2.5,2.88),.029,'steel')
for x in [2.50,3.01,3.52]:
 line('Clothes hanger',[(x,2.5,2.89),(x,2.5,2.74),(x-.19,2.5,2.60),(x+.19,2.5,2.60),(x,2.5,2.74)],.014,'brass')
 box('Folded work jacket',(x,2.60,2.16),(.44,.19,.92),'gold' if x<3.1 else 'teal',bevel=.047)
 line('Wardrobe jacket opening',[(x,2.49,2.57),(x,2.49,1.74)],.01,'leather')
for x in [2.45,3.02,3.59]:box('Equipment box',(x,2.5,.60),(.45,.85,.7),'teal',bevel=.03)
for x in [-1.35,1.35]:box('Workshop rug border',(x,0,.014),(.07,2.3,.015),'brass',bevel=.002)
box('Workshop rug',(0,0,.008),(2.7,2.3,.016),'teal',bevel=.008)
save_asset('home')
# Source library opens on hero; every asset remains in its labelled collection.
for col in bpy.data.collections:
 col.hide_viewport=col.name not in ['Collection','explorer']
 for ob in col.objects:ob.hide_set(col.name!='explorer')
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32
scene.world.color=(.15,.15,.15)
from prepare_art_library import prepare
prepare(ROOT)
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/Blender/reference_revision.blend')
open(OUT+'/Models/reference_revision_stats.json','w').write(json.dumps(stats,indent=2))
print('REFERENCE REVISION COMPLETE',json.dumps(stats))
