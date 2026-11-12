"""Blender 4.x: reusable bevelled block, exported as glTF. No external assets."""
import bpy, math, os
from mathutils import Vector
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
vertices=[]; faces=[]; normals=[]
# Dense smooth face grid preserves true painted displacement, even on planar faces.
N=48
for normal in [Vector((1,0,0)),Vector((-1,0,0)),Vector((0,1,0)),Vector((0,-1,0)),Vector((0,0,1)),Vector((0,0,-1))]:
    u=Vector((0,1,0)).cross(normal).normalized() if abs(normal.y)<.9 else Vector((1,0,0))
    v=normal.cross(u); base=len(vertices)
    for y in range(N+1):
        for x in range(N+1):
            p=normal+u*(x/N*2-1)+v*(y/N*2-1)
            p=Vector((p.x*1.7,p.y*1.7,p.z*.65))
            core=Vector((max(-1.35,min(1.35,p.x)),max(-1.35,min(1.35,p.y)),max(-.3,min(.3,p.z))))
            n=(p-core).normalized(); q=core+n*.35
            # Blender Z-up -> glTF Y-up: inverse rotation preserves Godot coordinates.
            vertices.append((q.x,-q.z,q.y)); normals.append((n.x,-n.z,n.y))
    for y in range(N):
        for x in range(N):
            a=base+y*(N+1)+x; faces.append((a,a+1,a+N+2,a+N+1))
mesh=bpy.data.meshes.new('Crystal rounded block'); mesh.from_pydata(vertices,[],faces); mesh.update()
obj=bpy.data.objects.new('CrystalBlock',mesh); bpy.context.collection.objects.link(obj)
for p in mesh.polygons:p.use_smooth=True
mesh.normals_split_custom_set_from_vertices(normals)
bpy.context.view_layer.objects.active=obj; obj.select_set(True)
root=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
bpy.ops.wm.save_as_mainfile(filepath=root+'/tools/source/crystal_block.blend')
bpy.ops.export_scene.gltf(filepath=root+'/assets/crystal_block.glb',export_format='GLB',use_selection=True,export_normals=True)
