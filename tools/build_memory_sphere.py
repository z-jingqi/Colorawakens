"""Reproducible Blender Cycles lighting reference, not the realtime game shader."""
import bpy, os, math
from mathutils import Vector
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
scene.render.engine='CYCLES'; scene.cycles.samples=512
scene.cycles.use_denoising=False
scene.cycles.max_bounces=12;scene.cycles.transmission_bounces=10
scene.render.resolution_x=720; scene.render.resolution_y=960; scene.render.resolution_percentage=100
scene.world.color=(.12,.14,.18)
scene.view_settings.view_transform='AgX'
# A real dielectric: light reflects and transmits at the same surface.
bpy.ops.mesh.primitive_uv_sphere_add(segments=128,ring_count=64,radius=1,location=(0,0,1.2))
orb=bpy.context.object;orb.name='MemorySphere'
for face in orb.data.polygons:face.use_smooth=True
mat=bpy.data.materials.new('Blue absorbing glass');mat.use_nodes=True
bs=mat.node_tree.nodes.get('Principled BSDF')
bs.inputs['Base Color'].default_value=(.8,.94,1,1)
bs.inputs['Roughness'].default_value=.055
bs.inputs['IOR'].default_value=1.46
bs.inputs['Transmission Weight'].default_value=1
volume=mat.node_tree.nodes.new('ShaderNodeVolumeAbsorption')
volume.inputs['Color'].default_value=(.015,.22,.85,1);volume.inputs['Density'].default_value=2.0
mat.node_tree.links.new(volume.outputs['Volume'],mat.node_tree.nodes.get('Material Output').inputs['Volume'])
orb.data.materials.append(mat)
bpy.ops.mesh.primitive_plane_add(size=200)
floor=bpy.context.object;floor.name='Matte studio floor'
fm=bpy.data.materials.new('Cool grey studio');fm.diffuse_color=(.18,.22,.29,1);fm.use_nodes=True
fm.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.18,.22,.29,1)
fm.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.75
floor.data.materials.append(fm)
def area(name,loc,power,size,color,shape='DISK'):
 data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape=shape;data.size=size;data.color=color
 obj=bpy.data.objects.new(name,data);scene.collection.objects.link(obj);obj.location=loc
 obj.rotation_euler=(Vector((0,0,1.2))-obj.location).to_track_quat('-Z','Y').to_euler()
 return obj
area('Large diffused key',(-3,-4,5),450,3,(.85,.93,1))
area('Cool edge',(3,1,3),250,2,(.58,.79,1))
area('Warm backlight',(-2,3,3),150,2.5,(1,.76,.5))
# No frontal fill disk: avoid a distracting circular reflection near the center.
bpy.ops.object.camera_add(location=(0,-7,3))
camera=bpy.context.object;camera.rotation_euler=(Vector((0,0,1.2))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='ORTHO';camera.data.ortho_scale=4.4;camera.data.lens=50;scene.camera=camera
root=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
bpy.ops.wm.save_as_mainfile(filepath=root+'/tools/source/memory_sphere.blend')
scene.render.filepath='/tmp/sphere-v3/Blender-memory-sphere.png';bpy.ops.render.render(write_still=True)
