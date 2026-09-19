"""Make the Blender delivery easy to inspect; reference boards never enter GLB."""
import os,bpy
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def prepare(root):
 guides=bpy.data.collections.get('Reference boards') or bpy.data.collections.new('Reference boards')
 if guides.name not in bpy.context.scene.collection.children:bpy.context.scene.collection.children.link(guides)
 if not len(guides.objects):
  for i,name in enumerate(['character-target','gameplay-target']):
   image=bpy.data.images.load(root+'/Art/References/'+name+'.png',check_existing=True);image.pack()
   o=bpy.data.objects.new(name,None);o.empty_display_type='IMAGE';o.data=image;o.empty_display_size=3.4;o.location=(-3.6 if i==0 else 3.7,1.1,1.8);o.rotation_euler=(1.5707963,0,0);o.hide_render=True;guides.objects.link(o)
 for screen in bpy.data.screens:
  for area in screen.areas:
   if area.type=='VIEW_3D':
    space=area.spaces.active;space.region_3d.view_location=Vector((0,0,1.15));space.region_3d.view_distance=3.8
    space.region_3d.view_rotation=(Vector((0,0,1.15))-Vector((2.8,5,2.9))).to_track_quat('-Z','Y')
    space.shading.type='MATERIAL'
if __name__=='__main__':
 bpy.ops.wm.open_mainfile(filepath=ROOT+'/Art/Blender/reference_revision.blend');prepare(ROOT);bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/Art/Blender/reference_revision.blend')
