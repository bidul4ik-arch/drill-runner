"""Authored cloth surfaces and small features; executed inside the hero builder."""
base_loft = loft
base_plate = plate

def smooth_profile(rings, z):
 k = next((k for k in range(len(rings)-1) if rings[k+1][2] >= z), len(rings)-2)
 t = (z-rings[k][2]) / max(.00001, rings[k+1][2]-rings[k][2])
 a,b,c,d = [rings[max(0,min(len(rings)-1,k+i))] for i in [-1,0,1,2]]
 values = [.5*((2*b[i])+(-a[i]+c[i])*t+(2*a[i]-5*b[i]+4*c[i]-d[i])*t*t+(-a[i]+3*b[i]-3*c[i]+d[i])*t*t*t) for i in range(5)]
 values[2]=z
 return values

def loft(name,rings,mat,bone='root',sides=24,fold=0):
 if name not in ['Cargo thigh','Trouser gathered calf','Jacket articulated sleeve','Shirt','Tailored trousers seat','Forearm anatomy']:
  return base_loft(name,rings,mat,bone,sides,fold)
 vs=[];fs=[];rows=24;sides=32
 for j in range(rows):
  t=j/(rows-1);cx,cy,z,rx,ry=smooth_profile(rings,rings[0][2]+t*(rings[-1][2]-rings[0][2]))
  for i in range(sides):
   a=i*math.tau/sides
   ripple=0
   if name in ['Cargo thigh','Trouser gathered calf','Jacket articulated sleeve']:
    # Diagonal compressed ridges have a broad shoulder and narrow crease.
    envelope=math.sin(math.pi*t)**.65
    if name=='Cargo thigh':envelope*=.4+.6*(1-t)
    ridge=math.sin(t*math.tau*3.1+a*1.6)+.35*math.sin(t*math.tau*6-a*2)
    ripple=(.006 if name=="Jacket articulated sleeve" else .009)*envelope*ridge
   vs.append((cx+(rx+ripple)*math.cos(a),cy+(ry+ripple)*math.sin(a),z))
 for j in range(rows-1):
  for i in range(sides):fs.append((j*sides+i,j*sides+(i+1)%sides,(j+1)*sides+(i+1)%sides,(j+1)*sides+i))
 fs += [tuple(range(sides-1,-1,-1)),tuple((rows-1)*sides+i for i in range(sides))]
 return mesh_obj(name,vs,fs,mat,bone,True)

def plate(name,p,s,mat='paint',bone='root'):
 if name.startswith('Cargo pocket'):
  o=box(name,p,s,mat,bone,bevel=min(s)*.42)
  for face in o.data.polygons:face.use_smooth=True
  mod=o.modifiers.new('Pocket weighted normals','WEIGHTED_NORMAL');mod.keep_sharp=True
  bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
  return o
 return base_plate(name,p,s,mat,bone)

def finish_reference_details():
 # A packed face atlas supplies gentle cheek colour and fine, irregular freckles.
 size=1024; yy,xx=np.mgrid[0:size,0:size]
 u=xx/(size-1);v=yy/(size-1)
 px=u*.46-.23;pz=1.73+v*.44
 base=np.zeros((size,size,4),dtype=np.float32);base[:,:,:3]=np.array([.62,.315,.18])**(1/2.2);base[:,:,3]=1
 cheek=np.exp(-((abs(px)-.105)/.049)**2-((pz-1.89)/.043)**2)
 base[:,:,0]+=.028*cheek;base[:,:,1]-=.045*cheek;base[:,:,2]-=.025*cheek
 random=np.random.default_rng(519)
 for i in range(65):
  x=random.uniform(-.151,.151);z=random.uniform(1.878,1.925)
  if abs(x)<.05:continue
  r=random.uniform(.0007,.0015)
  spot=np.exp(-((px-x)/r)**2-((pz-z)/r)**2)*random.uniform(.12,.23)
  base[:,:,:3]*=(1-spot[:,:,None])
 atlas=bpy.data.images.new('Hero face painted atlas',width=size,height=size)
 atlas.pixels.foreach_set(np.clip(base,0,1).ravel());atlas.filepath_raw=ROOT+'/Art/Textures/hero_face_albedo.png';atlas.file_format='PNG';atlas.save();atlas.pack()
 face_mat=mats['skin'].copy();face_mat.name='Hero face skin'
 p=next(n for n in face_mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
 texture=face_mat.node_tree.nodes.new('ShaderNodeTexImage');texture.image=atlas
 face_mat.node_tree.links.new(texture.outputs['Color'],p.inputs['Base Color'])
 p.inputs['Roughness'].default_value=.65
 for ob in parts:
  if ob.name.startswith('Sculpted face'):
   ob.data.materials.clear();ob.data.materials.append(face_mat)
   uv=ob.data.uv_layers.active
   for loop in ob.data.loops:
    co=ob.data.vertices[loop.vertex_index].co
    uv.data[loop.index].uv=((co.x+.23)/.46,(co.z-1.73)/.44)
 # Lift goggles onto the crown to free the eyebrows, as on the approved sheet.
 for ob in list(parts):
  if ob.name.startswith(('Goggle','Blue glass','Lens')):ob.location.z+=.050;ob.location.y+=.035
  if ob.name.startswith(('Eye white','Amber iris','Pupil','Eye glint','Upper eyelash','Arched brow')):
   center_x = -.077 if (ob.matrix_world @ ob.data.vertices[0].co).x < 0 else .077
   for v in ob.data.vertices:
    world=ob.matrix_world@v.co
    world.x=center_x+(world.x-center_x)*1.16
    world.z=1.955+(world.z-1.955)*1.20
    world.y+=.004
    v.co=ob.matrix_world.inverted()@world
 # Lip opening / ivory upper teeth, instead of a single painted line.
 for name,mat,top,bottom in [('Smile opening','lip',.003,-.009),('Smile upper teeth','white',.002,-.002)]:
  vs=[];fs=[]
  for j in range(17):
   t=j/16;x=(t-.5)*.077;curve=1.833+.015*(2*t-1)**2
   for offset in [top,bottom]:vs.append((x,.171-.16*abs(x),curve+offset*math.sin(math.pi*t)))
  for j in range(16):fs.append((j*2,j*2+1,j*2+3,j*2+2))
  ob=mesh_obj(name,vs,fs,mat,smooth=True)
  if mat=='white':ob.location.y+=.001
 for sg in [-1,1]:
  for j in range(8):
   x=sg*(.076+(j%4)*.014);z=1.91-(j//4)*.012+(j%2)*.003
   ell('Freckle fine',(x,.163-(abs(x)-.076)*.30,z),(.0018,.0013,.0016),'blush')
  # Hip-to-knee tailoring, flaps and seam lines wrap the cloth instead of floating boxes.
  x=sg*.143;bone='thigh'+('L' if sg<0 else 'R')
  line('Pocket welt',[(x+sg*.152,.084,.915),(x+sg*.170,.055,.887),(x+sg*.176,-.071,.887)],.0035,'teal',bone)
  line('Front trouser seam',[(x-sg*.052,.151,1.01),(x-sg*.061,.157,.91),(x-sg*.05,.151,.73)],.0025,'teal',bone)
  line('Jacket shoulder stitching',[(sg*.14,.11,1.64),(sg*.235,.10,1.60),(sg*.29,.07,1.57)],.0025,'brass')
  # Small garment stitching uses curves, not oversized metal piping.
  for j in range(16):
   z=1.31+j*.016
   line('Jacket zip tooth',[(sg*.068,.190,z),(sg*.075,.190,z+.003)],.0015,'brass')
 # Hair is matte with a restrained sheen; neutral gloves and boot quarters.
 for name in ['hair','hair_light']:
  p=next(n for n in mats[name].node_tree.nodes if n.type=='BSDF_PRINCIPLED')
  p.inputs['Roughness'].default_value=.72
