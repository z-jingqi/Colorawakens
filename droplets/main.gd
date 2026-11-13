extends Node3D
# The surface is one smooth union, not intersecting separate sphere meshes.
var shapes: Array[MeshInstance3D] = []
var materials: Array[ShaderMaterial] = []
var elapsed := 0.0
var caption: Label
var active := -1
const RADIUS := 0.78
const BLEND := 0.30
const CORNERS = [Vector3(0,0,0),Vector3(1,0,0),Vector3(1,1,0),Vector3(0,1,0),Vector3(0,0,1),Vector3(1,0,1),Vector3(1,1,1),Vector3(0,1,1)]
const TETRA = [[0,5,1,6],[0,1,2,6],[0,2,3,6],[0,3,7,6],[0,7,4,6],[0,4,5,6]]

func field(p: Vector3, centers: Array) -> float:
 var d: float = p.distance_to(centers[0])-RADIUS
 for i in range(1,centers.size()):
  var b: float = p.distance_to(centers[i])-RADIUS
  var h: float = clampf(.5+.5*(b-d)/BLEND,0.,1.)
  d=lerpf(b,d,h)-BLEND*h*(1.-h)
 return d

func gradient(p: Vector3, centers: Array)->Vector3:
 var e:=.002
 return Vector3(field(p+Vector3(e,0,0),centers)-field(p-Vector3(e,0,0),centers),field(p+Vector3(0,e,0),centers)-field(p-Vector3(0,e,0),centers),field(p+Vector3(0,0,e),centers)-field(p-Vector3(0,0,e),centers)).normalized()

func edge(a:Vector3,b:Vector3,da:float,db:float)->Vector3:
 return a.lerp(b,clampf(da/(da-db),0.,1.))

func triangle(a:Vector3,b:Vector3,c:Vector3,centers:Array,vertices:PackedVector3Array,normals:PackedVector3Array)->void:
 var normal:=gradient((a+b+c)/3.,centers)
 # Godot uses clockwise front faces.
 if (b-a).cross(c-a).dot(normal)>0.:
  var tmp:=b
  b=c
  c=tmp
 for v in [a,b,c]:
  vertices.append(v)
  normals.append(gradient(v,centers))

func make_surface(centers:Array)->ArrayMesh:
 var vertices:=PackedVector3Array()
 var normals:=PackedVector3Array()
 var n:=40
 var lo:=Vector3(-1.65,-1.65,-1.0)
 var size:=Vector3(3.3,3.3,2.0)
 for z in range(n):
  for y in range(n):
   for x in range(n):
    var points:Array=[]
    var distances:Array=[]
    for corner in CORNERS:
     var p:Vector3=lo+(Vector3(x,y,z)+corner)*size/float(n)
     points.append(p)
     distances.append(field(p,centers))
    for tetra in TETRA:
     var inside:Array=[]
     var outside:Array=[]
     for id in tetra:
      if distances[id]<0.:inside.append(id)
      else:outside.append(id)
     if inside.size()==0 or inside.size()==4:continue
     var intersections:Array=[]
     for a in inside:
      for b in outside:
       intersections.append(edge(points[a],points[b],distances[a],distances[b]))
     if intersections.size()==3:
      triangle(intersections[0],intersections[1],intersections[2],centers,vertices,normals)
     else:
      triangle(intersections[0],intersections[1],intersections[2],centers,vertices,normals)
      triangle(intersections[1],intersections[3],intersections[2],centers,vertices,normals)
 var arrays:=[]
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=vertices
 arrays[Mesh.ARRAY_NORMAL]=normals
 var mesh:=ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 return mesh

func _ready()->void:
 get_viewport().msaa_3d=Viewport.MSAA_4X
 var camera:=Camera3D.new()
 camera.position=Vector3(0,0,6)
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=4.8
 add_child(camera)
 var bg:=MeshInstance3D.new()
 var quad:=QuadMesh.new()
 quad.size=Vector2(7,8)
 bg.mesh=quad
 bg.position.z=-2.
 var bm:=ShaderMaterial.new()
 bm.shader=load("res://droplets/backdrop.gdshader")
 bg.material_override=bm
 add_child(bg)
 var configs=[ [Vector3.ZERO], [Vector3(-.70,0,0),Vector3(.70,0,0)], [Vector3(-.70,-.42,0),Vector3(.70,-.42,0),Vector3(0,.80,0)] ]
 for i in range(3):
  var shape:=MeshInstance3D.new()
  shape.mesh=make_surface(configs[i])
  var m:=ShaderMaterial.new()
  m.shader=load("res://droplets/liquid.gdshader")
  m.set_shader_parameter("lobes",i+1)
  shape.material_override=m
  shape.visible=false
  add_child(shape)
  shapes.append(shape)
  materials.append(m)
 var ui:=CanvasLayer.new()
 add_child(ui)
 caption=Label.new()
 caption.position=Vector2(0,125)
 caption.size=Vector2(720,45)
 caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 caption.add_theme_font_size_override("font_size",22)
 caption.modulate=Color(.72,.82,.88)
 ui.add_child(caption)
 var label:=Label.new()
 label.text="SOFT LIQUID / SURFACE STUDY"
 label.position=Vector2(0,805)
 label.size=Vector2(720,45)
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label.add_theme_font_size_override("font_size",17)
 label.modulate=Color(.61,.72,.79)
 ui.add_child(label)
 if "--test-droplets" in OS.get_cmdline_user_args():
  assert(shapes.size()==3)
  for shape in shapes:assert(shape.mesh.get_surface_count()==1)
  assert(field(Vector3.ZERO,configs[1])<0.)
  assert(field(Vector3.ZERO,configs[2])<0.)
  assert(field(Vector3(1.6,1.6,0),configs[2])>0.)
  print("SOFT DROPLETS: 7 checks passed")
  get_tree().quit()

func _process(delta:float)->void:
 elapsed+=delta
 var index:=mini(int(elapsed/3.0),2)
 if index!=active:
  active=index
  for i in range(3):shapes[i].visible=i==active
  caption.text=["01 / ONE DROP", "02 / JOINED PAIR", "03 / THREE LOBES"][active]
 for i in range(3):
  materials[i].set_shader_parameter("phase",elapsed)
  shapes[i].position.y=sin(elapsed*1.2)*.035
  shapes[i].rotation.y=sin(elapsed*.8)*.08
 if "--capture-droplets" in OS.get_cmdline_user_args() and elapsed>=9.0:get_tree().quit()
