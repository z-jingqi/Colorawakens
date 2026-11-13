"""Blender 4.x / Cycles reference: connected floating liquid droplets.
Run: SOFT_SAMPLES=256 blender -b -t 8 --python tools/build_soft_droplets.py
Outputs /tmp/soft-droplets/Blender-soft-droplets.png and editable blend.
"""
import bpy, math, os
from mathutils import Vector
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.engine='CYCLES'
scene.cycles.samples=int(os.environ.get('SOFT_SAMPLES','256'));scene.cycles.use_denoising=False
scene.cycles.max_bounces=12;scene.cycles.transmission_bounces=10
scene.render.resolution_x=900;scene.render.resolution_y=1200;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX';scene.view_settings.exposure=.6
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.35,.42,.55,1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.7
BLUE=(.13,.54,1,1);PINK=(1,.20,.39,1);GOLD=(1,.75,.18,1)
def liquid(name,count):
 m=bpy.data.materials.new(name);m.use_nodes=True;n=m.node_tree.nodes;links=m.node_tree.links
 bs=n['Principled BSDF'];bs.inputs['Roughness'].default_value=.035;bs.inputs['IOR'].default_value=1.333;bs.inputs['Transmission Weight'].default_value=1
 tex=n.new('ShaderNodeTexCoord');sep=n.new('ShaderNodeSeparateXYZ');links.new(tex.outputs['Generated'],sep.inputs[0])
 ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.interpolation='EASE'
 ramp.color_ramp.elements[0].position=.28;ramp.color_ramp.elements[0].color=BLUE
 ramp.color_ramp.elements[1].position=.72;ramp.color_ramp.elements[1].color=PINK if count>1 else BLUE
 links.new(sep.outputs['X'],ramp.inputs[0]);color=ramp.outputs[0]
 if count==3:
  rz=n.new('ShaderNodeMapRange');rz.inputs['From Min'].default_value=.40;rz.inputs['From Max'].default_value=.76
  links.new(sep.outputs['Z'],rz.inputs['Value'])
  mix=n.new('ShaderNodeMixRGB');links.new(rz.outputs[0],mix.inputs[0]);links.new(color,mix.inputs[1]);mix.inputs[2].default_value=GOLD;color=mix.outputs[0]
 # Keep clear surface; tint the transmitted body, not a metallic shell.
 base=n.new('ShaderNodeMixRGB');base.inputs[0].default_value=.72;base.inputs[1].default_value=(1,1,1,1);links.new(color,base.inputs[2]);links.new(base.outputs[0],bs.inputs['Base Color'])
 v=n.new('ShaderNodeVolumeAbsorption');links.new(color,v.inputs['Color']);v.inputs['Density'].default_value=.35;links.new(v.outputs[0],n['Material Output'].inputs['Volume'])
 return m

def droplet(name,centers,z):
 meta=bpy.data.metaballs.new(name);meta.resolution=.045;meta.render_resolution=.035;meta.threshold=.68
 ob=bpy.data.objects.new(name,meta);scene.collection.objects.link(ob);ob.location=(0,0,z)
 for i,co in enumerate(centers):
  e=meta.elements.new();e.co=co;e.radius=1.45;e.stiffness=2.
 bpy.context.view_layer.objects.active=ob;ob.select_set(True);bpy.ops.object.convert(target='MESH');ob=bpy.context.object
 for p in ob.data.polygons:p.use_smooth=True
 ob.data.materials.append(liquid(name+' water',len(centers)));ob.select_set(False)
 return ob
single=droplet('Single droplet',[(0,0,0)],3.25)
pair=droplet('Double droplet',[(-.84,0,-.02),(.84,.03,.02)],.30)
triple=droplet('Triple droplet',[(-.84,0,-.48),(.84,.025,-.48),(0,-.025,.98)],-2.85)
# Gentle asymmetry suggests yielding liquid without facets or seams.
for i,ob in enumerate([single,pair,triple]):
 for v in ob.data.vertices:
  p=v.co; p.x+=.018*math.sin(p.z*3.2+i);p.z+=.018*math.sin(p.x*3.8-i)
# Continuous low-contrast backdrop, no ground horizon reflected inside the droplets.
bpy.ops.mesh.primitive_plane_add(size=2,location=(0,3.3,.2),rotation=(math.pi/2,0,0));bg=bpy.context.object;bg.scale=(10,10,10)
m=bpy.data.materials.new('Quiet lavender backdrop');m.use_nodes=True;n=m.node_tree.nodes;n.clear();l=m.node_tree.links
out=n.new('ShaderNodeOutputMaterial');em=n.new('ShaderNodeEmission');em.inputs[1].default_value=.65
tex=n.new('ShaderNodeTexCoord');sep=n.new('ShaderNodeSeparateXYZ');r=n.new('ShaderNodeValToRGB');r.color_ramp.elements[0].position=.20;r.color_ramp.elements[0].color=(.23,.29,.38,1);r.color_ramp.elements[1].position=.8;r.color_ramp.elements[1].color=(.62,.54,.46,1)
l.new(tex.outputs['Generated'],sep.inputs[0]);l.new(sep.outputs['Y'],r.inputs[0]);l.new(r.outputs[0],em.inputs[0]);l.new(em.outputs[0],out.inputs[0]);bg.data.materials.append(m)
def area(name,loc,power,size,color,target=(0,0,.3)):
 d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;d.color=color
 o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
area('Large soft key',(-4,-5,6),850,5,(.90,.95,1))
area('Cool side reflection',(4,-1,1),400,4,(.65,.85,1))
area('Lower warm rim',(-3,2,-4),100,3,(1,.75,.5))
bpy.ops.object.camera_add(location=(0,-16,.2));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.2))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=10.5;scene.camera=cam
folder='/tmp/soft-droplets';os.makedirs(folder,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=folder+'/soft_droplets.blend');scene.render.filepath=folder+'/Blender-soft-droplets.png';bpy.ops.render.render(write_still=True)
