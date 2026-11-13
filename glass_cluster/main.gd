extends Node3D
var groups:Array[Node3D]=[]
var elapsed:=0.0
var caption:Label
var active:=-1
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
 bg.position.z=-3.
 var bm:=ShaderMaterial.new()
 bm.shader=load("res://glass_cluster/backdrop.gdshader")
 bg.material_override=bm
 add_child(bg)
 var r:=.70
 var configs=[[Vector3.ZERO],[Vector3(-r,0,0),Vector3(r,0,0)],[Vector3(-r,-.404,0),Vector3(r,-.404,0),Vector3(0,.808,0)]]
 var colors=[Vector3(.24,.70,.96),Vector3(.96,.38,.62),Vector3(.98,.78,.32)]
 for centers in configs:
  var group:=Node3D.new()
  add_child(group)
  groups.append(group)
  for i in centers.size():
   var ball:=MeshInstance3D.new()
   var mesh:=SphereMesh.new()
   mesh.radius=r
   mesh.height=r*2.
   mesh.radial_segments=96
   mesh.rings=64
   ball.mesh=mesh
   ball.position=centers[i]
   var mat:=ShaderMaterial.new()
   mat.shader=load("res://glass_cluster/glass.gdshader")
   mat.set_shader_parameter("tint",colors[i])
   ball.material_override=mat
   group.add_child(ball)
 var ui:=CanvasLayer.new()
 add_child(ui)
 caption=Label.new()
 caption.position=Vector2(0,125)
 caption.size=Vector2(720,45)
 caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 caption.add_theme_font_size_override("font_size",22)
 caption.modulate=Color(.75,.83,.86)
 ui.add_child(caption)
 var label:=Label.new()
 label.text="GLASS / INDEPENDENT SPHERES"
 label.position=Vector2(0,805)
 label.size=Vector2(720,45)
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label.add_theme_font_size_override("font_size",17)
 label.modulate=Color(.65,.77,.80)
 ui.add_child(label)
 if "--test-glass" in OS.get_cmdline_user_args():
  var checks:=0
  for j in groups.size():
   assert(groups[j].get_child_count()==j+1)
   checks+=1
   for ball in groups[j].get_children():
    assert(ball.mesh is SphereMesh)
    assert(is_equal_approx(ball.mesh.height,ball.mesh.radius*2.))
    checks+=2
  assert(is_equal_approx(configs[1][0].distance_to(configs[1][1]),r*2.))
  checks+=1
  print("GLASS CLUSTER: ",checks," checks passed")
  get_tree().quit()
func _process(delta:float)->void:
 elapsed+=delta
 var index:=mini(int(elapsed/3.),2)
 if active!=index:
  active=index
  for i in groups.size():groups[i].visible=i==active
  caption.text=["01 / ONE SPHERE","02 / TOUCHING PAIR","03 / THREE SPHERES"][active]
 for group in groups:group.position.y=sin(elapsed*.9)*.035
 if "--capture-glass" in OS.get_cmdline_user_args() and elapsed>=9.:get_tree().quit()
