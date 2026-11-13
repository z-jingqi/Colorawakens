extends Node3D
# The surface is one smooth union, not intersecting separate sphere meshes.
var shape:MeshInstance3D
var material:ShaderMaterial
var camera:Camera3D
var preview:MeshInstance3D
var centers:Array=[]
var count:=0
var cluster:Node3D
var centroid:=Vector3.ZERO

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
 var lo:Vector3=centers[0]-Vector3.ONE*.9
 var hi:Vector3=centers[0]+Vector3.ONE*.9
 for c in centers:
  lo=lo.min(c-Vector3.ONE*.9)
  hi=hi.max(c+Vector3.ONE*.9)
 var size:=hi-lo
 var dims:=Vector3i(ceil(size.x/.085),ceil(size.y/.085),ceil(size.z/.085))
 for z in range(dims.z):
  for y in range(dims.y):
   for x in range(dims.x):
    var points:Array=[]
    var distances:Array=[]
    for corner in CORNERS:
     var p:Vector3=lo+(Vector3(x,y,z)+corner)*size/Vector3(dims)
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

func next_center(existing:Array)->Vector3:
 const GAP:=1.40
 if existing.is_empty():return Vector3(-.70,0,0)
 if existing.size()==1:return Vector3(.70,0,0)
 if existing.size()==2:return Vector3(0,sqrt(3.)*.70,0)
 # Intersections of three equal-distance spheres produce candidates touching three neighbors.
 var average:=Vector3.ZERO
 for c in existing:average+=c
 average/=existing.size()
 var best:=Vector3.ZERO
 var best_score:=INF
 for i in range(existing.size()-2):
  for j in range(i+1,existing.size()-1):
   for k in range(j+1,existing.size()):
    var a:Vector3=existing[i]
    var b:Vector3=existing[j]
    var c:Vector3=existing[k]
    var ex:Vector3=(b-a).normalized()
    var d:float=a.distance_to(b)
    var ix:float=ex.dot(c-a)
    var ey:Vector3=c-a-ex*ix
    if ey.length()<.001:continue
    ey=ey.normalized()
    var jy:float=ey.dot(c-a)
    var x:float=d*.5
    var y:float=(ix*ix+jy*jy-2.*ix*x)/(2.*jy)
    var z2:float=GAP*GAP-x*x-y*y
    if z2<0.:continue
    var base:Vector3=a+ex*x+ey*y
    var ez:Vector3=ex.cross(ey)
    for sign_value in [1.,-1.]:
     var candidate:Vector3=base+ez*sqrt(z2)*sign_value
     var valid:=true
     for old in existing:
      if candidate.distance_to(old)<GAP-.001:valid=false
     if not valid:continue
     # Smallest radius about the existing centroid favors compact clusters.
     var score:float=candidate.distance_squared_to(average)
     score-=candidate.z*.0001
     if score<best_score:
      best_score=score
      best=candidate
 assert(is_finite(best_score))
 return best

func configure_material(m:ShaderMaterial,cs:Array)->void:
 var packed:=PackedVector3Array()
 for i in range(8):packed.append(cs[i] if i<cs.size() else Vector3.ZERO)
 m.set_shader_parameter("lobes",cs.size())
 m.set_shader_parameter("centers",packed)

func add_ball()->void:
 if count>=8:return
 centers.append(next_center(centers))
 count=centers.size()
 shape.mesh=make_surface(centers)
 configure_material(material,centers)
 centroid=Vector3.ZERO
 for c in centers:centroid+=c
 centroid/=centers.size()
 shape.position=-centroid
 caption.text="%d BALLS / SPATIAL CLUSTER" % count

func _ready()->void:
 get_viewport().msaa_3d=Viewport.MSAA_4X
 camera=Camera3D.new()
 camera.position=Vector3(0,0,6)
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=5.8
 add_child(camera)
 var bg:=MeshInstance3D.new()
 var quad:=QuadMesh.new()
 quad.size=Vector2(14,16)
 bg.mesh=quad
 bg.position.z=-3.
 var bm:=ShaderMaterial.new()
 bm.shader=load("res://joined_glass/backdrop.gdshader")
 bg.material_override=bm
 add_child(bg)
 cluster=Node3D.new()
 add_child(cluster)
 shape=MeshInstance3D.new()
 material=ShaderMaterial.new()
 material.shader=load("res://spatial_glass/glass.gdshader")
 shape.material_override=material
 cluster.add_child(shape)
 preview=MeshInstance3D.new()
 var sphere:=SphereMesh.new()
 sphere.radius=RADIUS
 sphere.height=RADIUS*2.
 sphere.radial_segments=64
 sphere.rings=48
 preview.mesh=sphere
 var pm:=ShaderMaterial.new()
 pm.shader=load("res://spatial_glass/glass.gdshader")
 configure_material(pm,[Vector3.ZERO])
 preview.material_override=pm
 preview.visible=false
 cluster.add_child(preview)
 var ui:=CanvasLayer.new()
 add_child(ui)
 caption=Label.new()
 caption.position=Vector2(0,75)
 caption.size=Vector2(720,45)
 caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 caption.add_theme_font_size_override("font_size",22)
 caption.modulate=Color(.16,.24,.31)
 ui.add_child(caption)
 var label:=Label.new()
 label.text="3D SHAPE STUDY / GAMEPLAY UNCHANGED"
 label.position=Vector2(0,855)
 label.size=Vector2(720,45)
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label.add_theme_font_size_override("font_size",16)
 label.modulate=Color(.22,.31,.38)
 ui.add_child(label)
 add_ball()
 if "--test-spatial-glass" in OS.get_cmdline_user_args():
  var cs:Array=[]
  var checks:=0
  for i in range(8):
   var c:=next_center(cs)
   for previous in cs:
    assert(c.distance_to(previous)>=1.399)
    checks+=1
   cs.append(c)
   assert(field(c,cs)<0.)
   checks+=1
   if cs.size()>1:
    var nearest:Vector3=cs[0]
    for k in range(cs.size()-1):
     if c.distance_to(cs[k])<c.distance_to(nearest):nearest=cs[k]
    assert(field((c+nearest)*.5,cs)<0.)
    checks+=1
  assert(absf(cs[3].z)>1.)
  assert(cs[4].distance_to(cs[3])>=1.399)
  print("SPATIAL CENTERS: ",cs.slice(0,5))
  var lo:Vector3=cs[0]
  var hi:Vector3=cs[0]
  for c in cs.slice(0,5):
   lo=lo.min(c)
   hi=hi.max(c)
  assert((hi-lo).length()<3.1)
  checks+=3
  for target in range(2,6):add_ball()
  assert(count==5)
  assert(shape.mesh.get_surface_count()==1)
  checks+=2
  print("SPATIAL GLASS: ",checks," checks passed")
  get_tree().quit()

func _process(delta:float)->void:
 elapsed+=delta
 var target_count:=mini(1+int(elapsed/3.),5)
 if count<target_count:add_ball()
 preview.visible=count<5 and fmod(elapsed,3.)>2.
 if preview.visible:
  var target:=next_center(centers)
  var from:=target+(target-centroid).normalized()*2.1
  var t:=smoothstep(2.,3.,fmod(elapsed,3.))
  preview.position=from.lerp(target,t)-centroid
  var pm:=preview.material_override as ShaderMaterial
  pm.set_shader_parameter("color_offset",count)
 cluster.rotation.y=maxf(0.,elapsed-9.)*.32
 cluster.rotation.x=sin(maxf(0.,elapsed-9.)*.25)*.18
 if "--capture-spatial-glass" in OS.get_cmdline_user_args() and elapsed>=21.:get_tree().quit()
