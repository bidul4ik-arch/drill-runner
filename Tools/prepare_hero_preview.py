import bpy,os
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
bpy.ops.wm.open_mainfile(filepath=ROOT+'/Art/Blender/hero_motion.blend')
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
for track in rig.animation_data.nla_tracks:track.mute=track.name!='run'
bpy.context.scene.frame_start=1;bpy.context.scene.frame_end=25;bpy.context.scene.frame_set(8)
for screen in bpy.data.screens:
 for area in screen.areas:
  if area.type=='VIEW_3D':
   space=area.spaces.active;space.region_3d.view_location=Vector((0,0,1.15));space.region_3d.view_distance=3.8
   space.region_3d.view_rotation=(Vector((0,0,1.15))-Vector((2.8,-5,2.9))).to_track_quat('-Z','Y');space.shading.type='MATERIAL'
bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/Art/Blender/hero_motion.blend')
