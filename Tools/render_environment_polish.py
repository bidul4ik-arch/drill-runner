"""Open the authored environment in Blender with a review camera and lighting."""
import bpy,os,math
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
bpy.ops.wm.open_mainfile(filepath=ROOT+'/Art/Blender/environment_polish.blend')
scene=bpy.context.scene
for o in bpy.data.objects:o.hide_set(o.name!='track');o.hide_render=o.name!='track'
review=bpy.data.collections.new('REVIEW - camera and lighting (not exported)');scene.collection.children.link(review)
track=bpy.data.objects['track']
for y in [24,48]:
 o=track.copy();o.data=track.data;review.objects.link(o);o.location.y=y;o.hide_set(False);o.hide_render=False
for y in [-6,6,18,30,42]:
 d=bpy.data.lights.new('Warm ceiling bounce','AREA');d.energy=750;d.size=5;d.color=(1,.76,.47)
 o=bpy.data.objects.new(d.name,d);review.objects.link(o);o.location=(0,y,6.7)
for side in [-1,1]:
 d=bpy.data.lights.new('Crystal bounce','AREA');d.energy=110;d.size=3;d.color=(.22,.72,1)
 o=bpy.data.objects.new(d.name,d);review.objects.link(o);o.location=(side*3.7,-5,2.3);o.rotation_euler=(Vector((0,2,1.4))-o.location).to_track_quat('-Z','Y').to_euler()
d=bpy.data.cameras.new('Environment review');cam=bpy.data.objects.new(d.name,d);review.objects.link(cam)
cam.location=(0,-10,3.6);cam.rotation_euler=(Vector((0,18,3))-cam.location).to_track_quat('-Z','Y').to_euler();d.lens=24;scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True;scene.cycles.max_bounces=4
scene.render.threads_mode='FIXED';scene.render.threads=8
scene.render.resolution_x=576;scene.render.resolution_y=864;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.filepath=ROOT+'/Art/Renders/environment-polish-blender.png'
scene.world.color=(.12,.12,.12)
bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/Art/Blender/environment_polish.blend')
bpy.ops.render.render(write_still=True)
